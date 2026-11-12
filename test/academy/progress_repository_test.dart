import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/data/progress_repository.dart';
import 'package:la_cambuse/features/logbook/data/logbook_repository.dart';

import '../helpers.dart';

void main() {
  late ProgressRepository repo;
  var now = DateTime(2026, 11, 12, 9);

  setUp(() {
    now = DateTime(2026, 11, 12, 9);
    final db = memoryDb();
    repo = ProgressRepository(db, LogbookRepository(db), clock: () => now);
  });

  Map<String, bool> answers(int correct, int total) =>
      {for (var i = 0; i < total; i++) 'q$i': i < correct};

  test('quiz réussi sans exercice requis → leçon validée', () async {
    final score = await repo.recordQuiz('git', 'rebase', answers: answers(4, 4), hasExercise: false);
    expect(score, 100);
    expect((await repo.lesson('git', 'rebase'))!.completedAt, isNotNull);
  });

  test('quiz réussi mais exercice manquant → leçon non validée, puis validée', () async {
    await repo.recordQuiz('git', 'branches', answers: answers(3, 4), hasExercise: true);
    var row = (await repo.lesson('git', 'branches'))!;
    expect(row.bestScore, 75);
    expect(row.completedAt, isNull);
    await repo.markExerciseDone('git', 'branches', hasExercise: true);
    row = (await repo.lesson('git', 'branches'))!;
    expect(row.completedAt, isNotNull);
  });

  test('quiz sous 70 % → non validée ; le meilleur score est conservé', () async {
    await repo.recordQuiz('git', 'x', answers: answers(3, 5), hasExercise: false);
    expect((await repo.lesson('git', 'x'))!.completedAt, isNull);
    await repo.recordQuiz('git', 'x', answers: answers(5, 5), hasExercise: false);
    await repo.recordQuiz('git', 'x', answers: answers(1, 5), hasExercise: false);
    final row = (await repo.lesson('git', 'x'))!;
    expect(row.bestScore, 100);
    expect(row.quizAttempts, 3);
    expect(row.completedAt, isNotNull);
  });

  test('Leitner : boîte suivante si juste, boîte 1 si faux, échéances', () async {
    await repo.recordReview('q', 'git', true);
    var due = await repo.watchDue(now.add(const Duration(days: 1))).first;
    expect(due.single.box, 1);
    await repo.recordReview('q', 'git', true);
    expect(await repo.watchDue(now.add(const Duration(days: 1))).first, isEmpty);
    due = await repo.watchDue(now.add(const Duration(days: 2))).first;
    expect(due.single.box, 2);
    await repo.recordReview('q', 'git', false);
    due = await repo.watchDue(now.add(const Duration(days: 1))).first;
    expect(due.single.box, 1);
    expect(due.single.wrongCount, 1);
    expect(due.single.correctCount, 2);
  });

  test('boîte plafonnée à 5 (16 jours)', () async {
    for (var i = 0; i < 8; i++) {
      await repo.recordReview('q', 'git', true);
    }
    final due = await repo.watchDue(now.add(const Duration(days: 16))).first;
    expect(due.single.box, 5);
  });

  test('reprise : dernière leçon ouverte mémorisée', () async {
    await repo.markStarted('git', 'pourquoi-git');
    await repo.markStarted('git', 'fusion');
    expect(await repo.watchLastLesson().first, ('git', 'fusion'));
  });

  test('projet final : exercice puis grille', () async {
    await repo.markProjectExercise('git');
    await repo.submitRubric('git', {'Messages de commit': 2});
    final p = (await repo.watchProject('git').first)!;
    expect(p.exerciseCompletedAt, isNotNull);
    expect(p.submittedAt, isNotNull);
    expect(ProgressRepository.decodeRubric(p.rubricJson), {'Messages de commit': 2});
    expect(ProgressRepository.decodeRubric('pas du json'), isEmpty);
  });
}
