import 'dart:convert';
import 'dart:math';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

final _r = Random(42);
DateTime _d() => DateTime.utc(2026, 1 + _r.nextInt(10), 1 + _r.nextInt(27), _r.nextInt(23));

/// Instantané aléatoire sur un petit univers de clés (beaucoup de collisions).
ProgressSnapshot randomSnapshot() => ProgressSnapshot(
      lessons: [
        for (var i = 0; i < 6; i++)
          SyncLesson(
            moduleId: 'git',
            lessonId: 'l${_r.nextInt(5)}',
            startedAt: _d(),
            completedAt: _r.nextBool() ? _d() : null,
            bestScore: _r.nextInt(5),
            quizAttempts: _r.nextInt(4),
            exerciseDone: _r.nextBool(),
          ),
      ],
      reviews: [
        for (var i = 0; i < 6; i++)
          SyncReview(questionId: 'q${_r.nextInt(5)}', moduleId: 'git', box: 1 + _r.nextInt(5), dueAt: _d(),
              correctCount: _r.nextInt(4), wrongCount: _r.nextInt(3)),
      ],
      projects: [
        for (var i = 0; i < 3; i++)
          SyncProject(moduleId: 'm${_r.nextInt(3)}', exerciseCompletedAt: _r.nextBool() ? _d() : null,
              rubricJson: '{"n":${_r.nextInt(3)}}', submittedAt: _r.nextBool() ? _d() : null),
      ],
    );

String canon(ProgressSnapshot s) => jsonEncode(s.toJson());

void main() {
  test('fusion commutative, associative et idempotente (200 tirages aléatoires)', () {
    for (var i = 0; i < 200; i++) {
      final a = randomSnapshot(), b = randomSnapshot(), c = randomSnapshot();
      expect(canon(mergeProgress(a, b)), canon(mergeProgress(b, a)), reason: 'commutativité');
      expect(canon(mergeProgress(mergeProgress(a, b), c)), canon(mergeProgress(a, mergeProgress(b, c))), reason: 'associativité');
      final ab = mergeProgress(a, b);
      expect(canon(mergeProgress(ab, ab)), canon(ab), reason: 'idempotence');
      expect(canon(mergeProgress(ab, a)), canon(ab), reason: 'rien n\'est perdu en refusionnant');
    }
  });

  test('leçon : terminée le reste, meilleur score et exercice conservés', () {
    final t = DateTime.utc(2026, 11, 14);
    final telephone = SyncLesson(moduleId: 'git', lessonId: 'commit', startedAt: t, completedAt: t, bestScore: 3, exerciseDone: true);
    final pc = SyncLesson(moduleId: 'git', lessonId: 'commit', startedAt: t.subtract(const Duration(days: 1)), bestScore: 4);
    final m = telephone.merge(pc);
    expect(m.completedAt, t);
    expect(m.startedAt, t.subtract(const Duration(days: 1)));
    expect(m.bestScore, 4);
    expect(m.exerciseDone, isTrue);
  });

  test('révision : la carte la plus révisée l\'emporte', () {
    final a = SyncReview(questionId: 'q', moduleId: 'git', box: 2, dueAt: DateTime.utc(2026, 11, 20), correctCount: 3, wrongCount: 1);
    final b = SyncReview(questionId: 'q', moduleId: 'git', box: 5, dueAt: DateTime.utc(2026, 12, 1), correctCount: 1);
    expect(a.merge(b).box, 2);
    expect(b.merge(a).box, 2);
  });

  test('aller-retour JSON fidèle ; instantané invalide refusé en bloc', () {
    final s = randomSnapshot();
    expect(canon(ProgressSnapshot.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>)), canon(s));
    expect(() => ProgressSnapshot.fromJson({'lessons': [{'moduleId': 'git'}]}), throwsA(isA<FormatException>()));
    expect(() => ProgressSnapshot.fromJson({'reviews': 'x'}), throwsA(isA<FormatException>()));
  });

  test('la portée sync existe et se lit', () {
    expect(Scope.fromCode('sync'), Scope.sync);
  });
}
