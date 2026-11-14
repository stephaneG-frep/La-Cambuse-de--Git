import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/sync/data/sync_repository.dart';

import '../helpers.dart';

void main() {
  test('export, puis fusion avec un autre appareil : rien n\'est perdu, comptes exacts, idempotent', () async {
    final db = memoryDb();
    final repo = SyncRepository(db);
    // État local : leçon commencée, carte peu révisée.
    await db.into(db.lessonProgress).insert(LessonProgressCompanion.insert(
        moduleId: 'git', lessonId: 'commit', startedAt: DateTime(2026, 11, 10), bestScore: const Value(2)));
    await db.into(db.reviewCards).insert(ReviewCardsCompanion.insert(
        questionId: 'git-1-1', moduleId: 'git', dueAt: DateTime(2026, 11, 15), correctCount: const Value(1)));
    final local = await repo.exportLocal();
    expect(local.lessons.single.bestScore, 2);

    // Autre appareil : même leçon terminée avec meilleur score, nouvelle leçon, carte plus révisée.
    final remote = ProgressSnapshot(
      lessons: [
        SyncLesson(moduleId: 'git', lessonId: 'commit', startedAt: DateTime.utc(2026, 11, 12), completedAt: DateTime.utc(2026, 11, 13), bestScore: 4, exerciseDone: true),
        SyncLesson(moduleId: 'docker', lessonId: 'images', startedAt: DateTime.utc(2026, 11, 13)),
      ],
      reviews: [SyncReview(questionId: 'git-1-1', moduleId: 'git', box: 3, dueAt: DateTime.utc(2026, 11, 25), correctCount: 3)],
      projects: [SyncProject(moduleId: 'git', exerciseCompletedAt: DateTime.utc(2026, 11, 13))],
    );
    final r = await repo.apply(mergeProgress(local, remote));
    expect((r.lessons, r.reviews, r.projects), (2, 1, 1));
    final commit = await (db.select(db.lessonProgress)..where((t) => t.lessonId.equals('commit'))).getSingle();
    expect(commit.bestScore, 4);
    expect(commit.exerciseDone, isTrue);
    expect(commit.completedAt, isNotNull);
    expect(commit.startedAt, DateTime(2026, 11, 10), reason: 'le début le plus ancien est conservé');
    expect((await db.select(db.reviewCards).getSingle()).box, 3);

    // Rejouer la même synchronisation ne change rien.
    expect((await repo.apply(remote)).total, 0);
    await db.close();
  });

  test('date de dernière synchronisation mémorisée', () async {
    final db = memoryDb();
    final repo = SyncRepository(db);
    expect(await repo.lastSync(), isNull);
    await repo.markSynced(DateTime(2026, 11, 14, 22, 30));
    expect(await repo.lastSync(), DateTime(2026, 11, 14, 22, 30));
    await db.close();
  });
}
