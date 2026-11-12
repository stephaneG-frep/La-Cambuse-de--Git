import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../logbook/data/logbook_repository.dart';
import '../../logbook/domain/audit_outcome.dart';

/// Progression de l'Académie : leçons, quiz, exercices, révisions espacées et
/// projet final. Tout est local et survit au redémarrage.
class ProgressRepository {
  ProgressRepository(this._db, this._logbook, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final LogbookRepository _logbook;
  final DateTime Function() _clock;

  /// Score minimal (en %) pour valider le quiz d'une leçon.
  static const passScore = 70;

  /// Intervalles de Leitner, en jours, pour les boîtes 1 à 5.
  static const leitnerDays = [1, 2, 4, 8, 16];
  static const lastLessonKey = 'academy.last_lesson';

  // ------------------------------------------------------------- Leçons

  Stream<Map<String, LessonProgressRow>> watchModule(String moduleId) =>
      (_db.select(_db.lessonProgress)..where((t) => t.moduleId.equals(moduleId)))
          .watch()
          .map((rows) => {for (final r in rows) r.lessonId: r});

  Future<LessonProgressRow?> lesson(String moduleId, String lessonId) =>
      (_db.select(_db.lessonProgress)
            ..where((t) => t.moduleId.equals(moduleId) & t.lessonId.equals(lessonId)))
          .getSingleOrNull();

  /// Ouvre une leçon : crée sa progression si besoin et mémorise la reprise.
  Future<void> markStarted(String moduleId, String lessonId) async {
    await _db.transaction(() async {
      await _db.into(_db.lessonProgress).insert(
            LessonProgressCompanion.insert(
              moduleId: moduleId,
              lessonId: lessonId,
              startedAt: _clock(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _db.into(_db.appSettingsTable).insertOnConflictUpdate(
            AppSettingsTableCompanion.insert(key: lastLessonKey, value: '$moduleId/$lessonId'),
          );
    });
  }

  /// Leçon à reprendre, au format (module, leçon).
  Stream<(String, String)?> watchLastLesson() =>
      (_db.select(_db.appSettingsTable)..where((t) => t.key.equals(lastLessonKey)))
          .watchSingleOrNull()
          .map((r) {
        final parts = r?.value.split('/');
        return parts == null || parts.length != 2 ? null : (parts[0], parts[1]);
      });

  Future<void> markExerciseDone(String moduleId, String lessonId,
      {required bool hasExercise}) async {
    await markStarted(moduleId, lessonId);
    await (_db.update(_db.lessonProgress)
          ..where((t) => t.moduleId.equals(moduleId) & t.lessonId.equals(lessonId)))
        .write(const LessonProgressCompanion(exerciseDone: Value(true)));
    await _logbook.record(
      category: 'académie',
      action: 'Exercice réussi',
      details: '$moduleId / $lessonId',
      outcome: AuditOutcome.success,
    );
    await _completeIfEligible(moduleId, lessonId, hasExercise: hasExercise);
  }

  /// Enregistre un passage de quiz. [answers] : identifiant de question →
  /// réponse correcte ou non (alimente aussi les cartes de révision).
  Future<int> recordQuiz(
    String moduleId,
    String lessonId, {
    required Map<String, bool> answers,
    required bool hasExercise,
  }) async {
    final total = answers.length;
    final correct = answers.values.where((v) => v).length;
    final score = total == 0 ? 0 : (correct * 100 / total).round();
    await markStarted(moduleId, lessonId);
    await _db.transaction(() async {
      final row = (await lesson(moduleId, lessonId))!;
      await (_db.update(_db.lessonProgress)
            ..where((t) => t.moduleId.equals(moduleId) & t.lessonId.equals(lessonId)))
          .write(LessonProgressCompanion(
        bestScore: Value(score > row.bestScore ? score : row.bestScore),
        quizAttempts: Value(row.quizAttempts + 1),
      ));
      for (final e in answers.entries) {
        await _review(e.key, moduleId, e.value);
      }
    });
    await _logbook.record(
      category: 'académie',
      action: 'Quiz terminé',
      details: '$moduleId / $lessonId : $correct/$total ($score %)',
      outcome: score >= passScore ? AuditOutcome.success : AuditOutcome.failure,
    );
    await _completeIfEligible(moduleId, lessonId, hasExercise: hasExercise);
    return score;
  }

  Future<void> _completeIfEligible(String moduleId, String lessonId,
      {required bool hasExercise}) async {
    final row = await lesson(moduleId, lessonId);
    if (row == null || row.completedAt != null) return;
    if (row.bestScore >= passScore && (row.exerciseDone || !hasExercise)) {
      await (_db.update(_db.lessonProgress)
            ..where((t) => t.moduleId.equals(moduleId) & t.lessonId.equals(lessonId)))
          .write(LessonProgressCompanion(completedAt: Value(_clock())));
      await _logbook.record(
        category: 'académie',
        action: 'Leçon validée',
        details: '$moduleId / $lessonId',
        outcome: AuditOutcome.success,
      );
    }
  }

  // ---------------------------------------------------------- Révisions

  /// Système de Leitner : bonne réponse → boîte suivante (intervalle doublé),
  /// mauvaise réponse → retour en boîte 1.
  Future<void> _review(String questionId, String moduleId, bool correct) async {
    final now = _clock();
    final existing = await (_db.select(_db.reviewCards)
          ..where((t) => t.questionId.equals(questionId)))
        .getSingleOrNull();
    final box = correct ? ((existing?.box ?? 0) + 1).clamp(1, 5) : 1;
    await _db.into(_db.reviewCards).insertOnConflictUpdate(ReviewCardsCompanion.insert(
          questionId: questionId,
          moduleId: moduleId,
          box: Value(box),
          dueAt: now.add(Duration(days: leitnerDays[box - 1])),
          correctCount: Value((existing?.correctCount ?? 0) + (correct ? 1 : 0)),
          wrongCount: Value((existing?.wrongCount ?? 0) + (correct ? 0 : 1)),
        ));
  }

  Future<void> recordReview(String questionId, String moduleId, bool correct) =>
      _review(questionId, moduleId, correct);

  /// Cartes dont l'échéance est passée à l'instant [at].
  Stream<List<ReviewCard>> watchDue(DateTime at) => (_db.select(_db.reviewCards)
        ..where((t) => t.dueAt.isSmallerOrEqualValue(at))
        ..orderBy([(t) => OrderingTerm.asc(t.box), (t) => OrderingTerm.asc(t.dueAt)]))
      .watch();

  // ------------------------------------------------------- Projet final

  Stream<ProjectProgressRow?> watchProject(String moduleId) =>
      (_db.select(_db.projectProgress)..where((t) => t.moduleId.equals(moduleId)))
          .watchSingleOrNull();

  Future<void> markProjectExercise(String moduleId) async {
    await _db.into(_db.projectProgress).insert(
          ProjectProgressCompanion.insert(
            moduleId: moduleId,
            exerciseCompletedAt: Value(_clock()),
          ),
          onConflict: DoUpdate(
            (_) => ProjectProgressCompanion(exerciseCompletedAt: Value(_clock())),
          ),
        );
    await _logbook.record(
      category: 'académie',
      action: 'Projet final réalisé',
      details: moduleId,
      outcome: AuditOutcome.success,
    );
  }

  /// Auto-évaluation : critère → index du niveau choisi.
  Future<void> submitRubric(String moduleId, Map<String, int> levels) async {
    await _db.into(_db.projectProgress).insert(
          ProjectProgressCompanion.insert(
            moduleId: moduleId,
            rubricJson: Value(jsonEncode(levels)),
            submittedAt: Value(_clock()),
          ),
          onConflict: DoUpdate(
            (_) => ProjectProgressCompanion(
              rubricJson: Value(jsonEncode(levels)),
              submittedAt: Value(_clock()),
            ),
          ),
        );
    await _logbook.record(
      category: 'académie',
      action: 'Grille d\'évaluation enregistrée',
      details: moduleId,
      outcome: AuditOutcome.success,
    );
  }

  static Map<String, int> decodeRubric(String json) {
    try {
      return (jsonDecode(json) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return const {};
    }
  }
}
