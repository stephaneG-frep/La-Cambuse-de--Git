import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

import 'harness.dart';

Map<String, dynamic> snap({String lesson = 'commit', int score = 3, bool done = false, int reviews = 1}) => {
      'snapshot': ProgressSnapshot(
        lessons: [
          SyncLesson(moduleId: 'git', lessonId: lesson, startedAt: DateTime.utc(2026, 11, 14), bestScore: score, exerciseDone: done),
        ],
        reviews: [
          SyncReview(questionId: 'git-1-1', moduleId: 'git', box: 1 + reviews, dueAt: DateTime.utc(2026, 11, 20), correctCount: reviews),
        ],
      ).toJson(),
    };

void main() {
  late Harness h;
  setUp(() async => h = await Harness.start());
  tearDown(() => h.stop());

  test('sans portée « sync » : refusé et audité', () async {
    final p = await h.pair('read');
    final (s, j) = await h.call('POST', '/v1/sync', token: p.accessToken, body: snap());
    expect(s, 403);
    expect((j['error'] as Map)['code'], ErrorCodes.forbiddenScope);
    expect(h.server.audit.tail(10).any((e) => e['event'] == 'sync.forbidden'), isTrue);
  });

  test('deux appareils : chacun reçoit la fusion des progressions, stockée en 0600', () async {
    final telephone = await h.pair('read,sync');
    final pc = await h.pair('read,sync');
    var (s, j) = await h.call('POST', '/v1/sync', token: telephone.accessToken, body: snap(lesson: 'commit', done: true));
    expect(s, 200, reason: '$j');
    (s, j) = await h.call('POST', '/v1/sync', token: pc.accessToken, body: snap(lesson: 'branches', score: 4, reviews: 3));
    expect(s, 200);
    final merged = ProgressSnapshot.fromJson(((j['data'] as Map)['snapshot'] as Map).cast<String, dynamic>());
    expect(merged.lessons.map((l) => l.lessonId), ['branches', 'commit']);
    expect(merged.lessons.firstWhere((l) => l.lessonId == 'commit').exerciseDone, isTrue);
    expect(merged.reviews.single.correctCount, 3, reason: 'la carte la plus révisée l\'emporte');
    final f = File('${h.tmp.path}/data/sync.json');
    expect(f.existsSync(), isTrue);
    expect((f.statSync().mode & 0x1FF).toRadixString(8), '600');
    final audit = h.server.audit.tail(20).where((e) => e['event'] == 'sync').toList();
    expect(audit, hasLength(2));
    expect(jsonEncode(audit), isNot(contains('git-1-1')), reason: 'le journal ne garde que des comptes');
  });

  test('progression invalide refusée sans altérer le coffre ; jeton absent refusé', () async {
    final p = await h.pair('sync');
    await h.call('POST', '/v1/sync', token: p.accessToken, body: snap());
    final before = File('${h.tmp.path}/data/sync.json').readAsStringSync();
    final (s, _) = await h.call('POST', '/v1/sync', token: p.accessToken, body: {'snapshot': {'lessons': [{'moduleId': 'git'}]}});
    expect(s, 400);
    expect(File('${h.tmp.path}/data/sync.json').readAsStringSync(), before);
    final (s2, _) = await h.call('POST', '/v1/sync', body: snap());
    expect(s2, 401);
  });

  test('une progression de taille réelle (500 cartes) dépasse 64 Ko et passe', () async {
    final p = await h.pair('sync');
    final big = ProgressSnapshot(reviews: [
      for (var i = 0; i < 500; i++)
        SyncReview(questionId: 'module-$i-question', moduleId: 'kubernetes', box: 2, dueAt: DateTime.utc(2026, 12, 1), correctCount: 1),
    ]);
    expect(jsonEncode({'snapshot': big.toJson()}).length, greaterThan(64 * 1024));
    final (s, _) = await h.call('POST', '/v1/sync', token: p.accessToken, body: {'snapshot': big.toJson()});
    expect(s, 200);
  });
}
