import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:drift/drift.dart';

import '../../../core/db/database.dart';

/// Résultat d'une synchronisation : lignes ajoutées ou mises à jour localement.
class SyncResult {
  const SyncResult({this.lessons = 0, this.reviews = 0, this.projects = 0});
  final int lessons;
  final int reviews;
  final int projects;
  int get total => lessons + reviews + projects;
}

/// Passerelle entre la base locale et l'instantané de progression partagé.
class SyncRepository {
  SyncRepository(this._db);
  final AppDatabase _db;

  static const _lastKey = 'sync.last';

  Future<DateTime?> lastSync() async {
    final row = await (_db.select(_db.appSettingsTable)..where((t) => t.key.equals(_lastKey))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value);
  }

  Future<void> markSynced(DateTime at) => _db
      .into(_db.appSettingsTable)
      .insertOnConflictUpdate(AppSettingsTableCompanion.insert(key: _lastKey, value: at.toIso8601String()));

  Future<ProgressSnapshot> exportLocal() async => ProgressSnapshot(
        lessons: [
          for (final r in await _db.select(_db.lessonProgress).get())
            SyncLesson(
              moduleId: r.moduleId,
              lessonId: r.lessonId,
              startedAt: r.startedAt,
              completedAt: r.completedAt,
              bestScore: r.bestScore,
              quizAttempts: r.quizAttempts,
              exerciseDone: r.exerciseDone,
            ),
        ],
        reviews: [
          for (final r in await _db.select(_db.reviewCards).get())
            SyncReview(
              questionId: r.questionId,
              moduleId: r.moduleId,
              box: r.box,
              dueAt: r.dueAt,
              correctCount: r.correctCount,
              wrongCount: r.wrongCount,
            ),
        ],
        projects: [
          for (final r in await _db.select(_db.projectProgress).get())
            SyncProject(
              moduleId: r.moduleId,
              exerciseCompletedAt: r.exerciseCompletedAt,
              rubricJson: r.rubricJson,
              submittedAt: r.submittedAt,
            ),
        ],
      );

  /// Applique la progression reçue : fusion avec l'état local du moment (rien
  /// de ce qui a changé entre-temps n'est perdu), dans une transaction.
  Future<SyncResult> apply(ProgressSnapshot remote) => _db.transaction(() async {
        final local = await exportLocal();
        final merged = mergeProgress(local, remote);
        final lessonsBefore = {for (final l in local.lessons) l.key: l.toJson().toString()};
        final reviewsBefore = {for (final r in local.reviews) r.questionId: r.toJson().toString()};
        final projectsBefore = {for (final p in local.projects) p.moduleId: p.toJson().toString()};
        var nl = 0, nr = 0, np = 0;
        for (final l in merged.lessons) {
          if (lessonsBefore[l.key] == l.toJson().toString()) continue;
          nl++;
          await _db.into(_db.lessonProgress).insertOnConflictUpdate(LessonProgressCompanion.insert(
                moduleId: l.moduleId,
                lessonId: l.lessonId,
                startedAt: l.startedAt.toLocal(),
                completedAt: Value(l.completedAt?.toLocal()),
                bestScore: Value(l.bestScore),
                quizAttempts: Value(l.quizAttempts),
                exerciseDone: Value(l.exerciseDone),
              ));
        }
        for (final r in merged.reviews) {
          if (reviewsBefore[r.questionId] == r.toJson().toString()) continue;
          nr++;
          await _db.into(_db.reviewCards).insertOnConflictUpdate(ReviewCardsCompanion.insert(
                questionId: r.questionId,
                moduleId: r.moduleId,
                box: Value(r.box),
                dueAt: r.dueAt.toLocal(),
                correctCount: Value(r.correctCount),
                wrongCount: Value(r.wrongCount),
              ));
        }
        for (final p in merged.projects) {
          if (projectsBefore[p.moduleId] == p.toJson().toString()) continue;
          np++;
          await _db.into(_db.projectProgress).insertOnConflictUpdate(ProjectProgressCompanion.insert(
                moduleId: p.moduleId,
                exerciseCompletedAt: Value(p.exerciseCompletedAt?.toLocal()),
                rubricJson: Value(p.rubricJson),
                submittedAt: Value(p.submittedAt?.toLocal()),
              ));
        }
        return SyncResult(lessons: nl, reviews: nr, projects: np);
      });
}
