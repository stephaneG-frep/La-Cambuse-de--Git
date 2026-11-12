import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

class Harness {
  Harness._(this.server, this.tmp, this.root, this.outside, this.clock);

  final CompanionServer server;
  final Directory tmp;
  final Directory root;
  final Directory outside;
  final FakeClock clock;
  final client = HttpClient();

  static Future<Harness> start({OpRunner Function(RootGuard)? runner}) async {
    final tmp = await Directory.systemTemp.createTemp('cambuse_comp_');
    final root = Directory('${tmp.path}/projets')..createSync();
    final outside = Directory('${tmp.path}/secret')..createSync();
    File('${outside.path}/id_rsa').writeAsStringSync('CLE PRIVEE FACTICE');
    final clock = FakeClock();
    final config = CompanionConfig(dataDir: Directory('${tmp.path}/data'), roots: [root.path], port: 0);
    final server = CompanionServer(config,
        clock: clock.now, runner: runner?.call(RootGuard([root.path])));
    await server.start();
    return Harness._(server, tmp, root, outside, clock);
  }

  Future<void> stop() async {
    client.close(force: true);
    await server.stop();
    await tmp.delete(recursive: true);
  }

  Future<(int, Map<String, dynamic>)> call(String method, String path,
      {Object? body, String? token, String? admin, String? rawBody}) async {
    final req = await client.openUrl(method, Uri.parse('http://127.0.0.1:${server.port}$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('authorization', 'Bearer $token');
    if (admin != null) req.headers.set('x-cambuse-admin', admin);
    if (rawBody != null) {
      req.write(rawBody);
    } else if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return (res.statusCode, jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>);
  }

  Future<String> pairingCode([String scopes = 'read']) async {
    final (s, j) = await call('POST', '/v1/pair/start', body: {'scopes': scopes}, admin: server.adminToken);
    expect(s, 200, reason: '$j');
    return (j['data'] as Map)['code'] as String;
  }

  Future<PairResult> pair([String scopes = 'read']) async {
    final code = await pairingCode(scopes);
    final (s, j) = await call('POST', '/v1/pair/complete', body: {'code': code, 'deviceName': 'Honor'});
    expect(s, 200, reason: '$j');
    return PairResult.fromJson(j['data'] as Map<String, dynamic>);
  }

  Future<OpStatus> submit(String token, String type, {String? rootPath, Map<String, dynamic> params = const {}}) async {
    final (s, j) = await call('POST', '/v1/ops',
        token: token, body: OpRequest(type: type, root: rootPath, params: params).toJson());
    if (s != 201) throw ApiFailure(s, (j['error'] as Map)['code'] as String, '${(j['error'] as Map)['message']}');
    return OpStatus.fromJson(j['data'] as Map<String, dynamic>);
  }

  Future<OpStatus> wait(String token, String id) async {
    for (var i = 0; i < 200; i++) {
      final (_, j) = await call('GET', '/v1/ops/$id', token: token);
      final st = OpStatus.fromJson(j['data'] as Map<String, dynamic>);
      if (st.state.isFinal || st.state == OpState.awaitingApproval) return st;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('opération non terminée');
  }

  Future<OpStatus> approve(String token, String id) async {
    final (s, j) = await call('POST', '/v1/ops/$id/approve', token: token);
    expect(s, 200, reason: '$j');
    return wait(token, id);
  }

  Directory repo(String name) {
    final d = Directory('${root.path}/$name')..createSync();
    Process.runSync('git', ['init', '-q', '-b', 'main'], workingDirectory: d.path);
    Process.runSync('git', ['config', 'user.name', 'Test'], workingDirectory: d.path);
    Process.runSync('git', ['config', 'user.email', 'test@exemple.fr'], workingDirectory: d.path);
    return d;
  }
}

class ApiFailure implements Exception {
  ApiFailure(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => 'ApiFailure($status, $code): $message';
}

Matcher failsWith(int status, String code) =>
    throwsA(isA<ApiFailure>().having((e) => e.status, 'status', status).having((e) => e.code, 'code', code));

class FakeClock {
  DateTime t = DateTime(2026, 11, 12, 12);
  DateTime now() => t;
  void advance(Duration d) => t = t.add(d);
}

void main() {
  late Harness h;
  setUp(() async => h = await Harness.start());
  tearDown(() => h.stop());

  group('santé et routes', () {
    test('health sans authentification, version d\'API', () async {
      final (s, j) = await h.call('GET', '/v1/health');
      expect(s, 200);
      expect((j['data'] as Map)['apiVersion'], apiVersion);
    });
    test('route inconnue → 404 ; corps trop gros → 413 ; JSON invalide → 400', () async {
      expect((await h.call('GET', '/v2/x')).$1, 404);
      expect((await h.call('POST', '/v1/pair/complete', rawBody: 'x' * 70000)).$1, 413);
      expect((await h.call('POST', '/v1/pair/complete', rawBody: '{oups')).$1, 400);
    });
    test('écoute uniquement sur 127.0.0.1 par défaut', () async {
      expect(h.server.lanPort, isNull);
    });
  });

  group('appairage', () {
    test('démarrage réservé à l\'hôte (jeton administrateur)', () async {
      expect((await h.call('POST', '/v1/pair/start')).$1, 403);
      expect((await h.call('POST', '/v1/pair/start', admin: 'faux')).$1, 403);
    });
    test('code correct : jetons émis, code à usage unique', () async {
      final code = await h.pairingCode();
      final (s1, j1) = await h.call('POST', '/v1/pair/complete', body: {'code': code, 'deviceName': 'Honor'});
      expect(s1, 200);
      expect((j1['data'] as Map)['scopes'], ['read']);
      final (s2, _) = await h.call('POST', '/v1/pair/complete', body: {'code': code, 'deviceName': 'Intrus'});
      expect(s2, 401);
    });
    test('5 essais faux : code invalidé (anti force brute)', () async {
      final code = await h.pairingCode();
      final wrong = code == '123456' ? '654321' : '123456';
      for (var i = 0; i < 4; i++) {
        expect((await h.call('POST', '/v1/pair/complete', body: {'code': wrong})).$1, 401);
      }
      expect((await h.call('POST', '/v1/pair/complete', body: {'code': wrong})).$1, 429);
      expect((await h.call('POST', '/v1/pair/complete', body: {'code': code})).$1, 401);
    });
    test('code expiré après 2 minutes', () async {
      final code = await h.pairingCode();
      h.clock.advance(const Duration(minutes: 3));
      expect((await h.call('POST', '/v1/pair/complete', body: {'code': code})).$1, 401);
    });
  });

  group('jetons', () {
    test('sans jeton ou jeton faux → 401', () async {
      expect((await h.call('GET', '/v1/me')).$1, 401);
      expect((await h.call('GET', '/v1/me', token: 'nimporte')).$1, 401);
    });
    test('expiration à 15 min, rafraîchissement avec rotation', () async {
      final p = await h.pair();
      expect((await h.call('GET', '/v1/me', token: p.accessToken)).$1, 200);
      h.clock.advance(const Duration(minutes: 16));
      expect((await h.call('GET', '/v1/me', token: p.accessToken)).$1, 401);
      final (s, j) = await h.call('POST', '/v1/token/refresh', body: {'deviceId': p.deviceId, 'refreshToken': p.refreshToken});
      expect(s, 200);
      final next = PairResult.fromJson(j['data'] as Map<String, dynamic>);
      expect((await h.call('GET', '/v1/me', token: next.accessToken)).$1, 200);
      final (s2, _) = await h.call('POST', '/v1/token/refresh', body: {'deviceId': p.deviceId, 'refreshToken': p.refreshToken});
      expect(s2, 401, reason: 'ancien jeton de rafraîchissement invalidé');
    });
    test('révocation par l\'hôte : accès coupé immédiatement', () async {
      final p = await h.pair();
      final (s, _) = await h.call('DELETE', '/v1/devices/${p.deviceId}', admin: h.server.adminToken);
      expect(s, 200);
      expect((await h.call('GET', '/v1/me', token: p.accessToken)).$1, 401);
      expect((await h.call('POST', '/v1/token/refresh', body: {'deviceId': p.deviceId, 'refreshToken': p.refreshToken})).$1, 401);
    });
    test('stockage : fichier 600, aucun jeton en clair', () async {
      final p = await h.pair();
      final f = File('${h.tmp.path}/data/devices.json');
      expect(f.statSync().modeString(), 'rw-------');
      final content = f.readAsStringSync();
      expect(content, isNot(contains(p.refreshToken)));
      expect(content, isNot(contains(p.accessToken)));
      expect(Directory('${h.tmp.path}/data').statSync().modeString(), 'rwx------');
    });
  });

  group('portées et confinement', () {
    test('appareil en lecture seule : opérations mutantes refusées', () async {
      final p = await h.pair('read');
      final d = Directory('${h.root.path}/neuf')..createSync();
      await expectLater(h.submit(p.accessToken, 'git.init', rootPath: d.path), failsWith(403, ErrorCodes.forbiddenScope));
      expect(Directory('${d.path}/.git').existsSync(), isFalse);
    });
    test('opération inconnue (ex. shell) refusée', () async {
      final p = await h.pair('read,git-write');
      await expectLater(h.submit(p.accessToken, 'shell.exec', params: {'cmd': 'rm -rf /'}), failsWith(400, ErrorCodes.unknownOp));
    });
    test('dossier hors racine, relatif ou lien symbolique sortant → 403', () async {
      final p = await h.pair();
      await expectLater(h.submit(p.accessToken, 'git.status', rootPath: h.outside.path), failsWith(403, ErrorCodes.pathOutsideRoot));
      await expectLater(h.submit(p.accessToken, 'git.status', rootPath: 'projets'), failsWith(403, ErrorCodes.pathOutsideRoot));
      await expectLater(h.submit(p.accessToken, 'git.status', rootPath: '${h.root.path}/../secret'), failsWith(403, ErrorCodes.pathOutsideRoot));
      Link('${h.root.path}/raccourci').createSync(h.outside.path);
      await expectLater(h.submit(p.accessToken, 'git.status', rootPath: '${h.root.path}/raccourci'), failsWith(403, ErrorCodes.pathOutsideRoot));
    });
    test('fichiers : traversée, lien sortant et .git refusés', () async {
      final p = await h.pair('read,git-write');
      final r = h.repo('depot');
      Link('${r.path}/fuite').createSync('${h.outside.path}/id_rsa');
      await expectLater(h.submit(p.accessToken, 'git.diff', rootPath: r.path, params: {'path': '../secret/id_rsa'}),
          failsWith(403, ErrorCodes.pathOutsideRoot));
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['fuite']}),
          failsWith(403, ErrorCodes.pathOutsideRoot));
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['.git/config']}),
          failsWith(403, ErrorCodes.pathOutsideRoot));
    });
  });

  group('opérations Git réelles', () {
    test('lecture : git.status exécuté sans approbation', () async {
      final p = await h.pair();
      final r = h.repo('lecture');
      File('${r.path}/a.txt').writeAsStringSync('a');
      final op = await h.submit(p.accessToken, 'git.status', rootPath: r.path);
      final st = await h.wait(p.accessToken, op.id);
      expect(st.state, OpState.succeeded);
      expect(st.stdout, contains('## No commits yet on main'));
      expect(st.stdout, contains('?? a.txt'));
    });

    test('mutation : plan exact, rien avant approbation, puis exécution', () async {
      final p = await h.pair('read,git-write');
      final d = Directory('${h.root.path}/nouveau')..createSync();
      final op = await h.submit(p.accessToken, 'git.init', rootPath: d.path);
      expect(op.state, OpState.awaitingApproval);
      expect(op.plan, contains('Commande exacte : git init --initial-branch=main'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(Directory('${d.path}/.git').existsSync(), isFalse, reason: 'rien n\'est fait sans approbation');
      final st = await h.approve(p.accessToken, op.id);
      expect(st.state, OpState.succeeded);
      expect(Directory('${d.path}/.git').existsSync(), isTrue);
      await expectLater(h.submit(p.accessToken, 'git.init', rootPath: d.path), failsWith(409, ErrorCodes.conflict),
          reason: 'jamais d\'écrasement d\'un dépôt existant');
    });

    test('refus de l\'utilisateur : opération rejetée, rien exécuté', () async {
      final p = await h.pair('read,git-write');
      final d = Directory('${h.root.path}/refus')..createSync();
      final op = await h.submit(p.accessToken, 'git.init', rootPath: d.path);
      final (s, j) = await h.call('POST', '/v1/ops/${op.id}/reject', token: p.accessToken);
      expect(s, 200);
      expect((j['data'] as Map)['state'], 'rejected');
      expect((await h.call('POST', '/v1/ops/${op.id}/approve', token: p.accessToken)).$1, 409);
      expect(Directory('${d.path}/.git').existsSync(), isFalse);
    });

    test('add explicite + commit ; ajout global ou de dossier refusé', () async {
      final p = await h.pair('read,git-write');
      final r = h.repo('commit');
      File('${r.path}/README.md').writeAsStringSync('# Projet\n');
      Directory('${r.path}/src').createSync();
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['.']}),
          failsWith(400, ErrorCodes.invalidRequest));
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['src']}),
          failsWith(400, ErrorCodes.invalidRequest));
      var op = await h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['README.md']});
      expect((await h.approve(p.accessToken, op.id)).state, OpState.succeeded);
      op = await h.submit(p.accessToken, 'git.commit', rootPath: r.path, params: {'message': 'Ajoute le README'});
      expect(op.plan.join(), contains("git commit --no-verify -m 'Ajoute le README'"));
      final st = await h.approve(p.accessToken, op.id);
      expect(st.state, OpState.succeeded, reason: st.stderr);
      final log = Process.runSync('git', ['log', '--oneline'], workingDirectory: r.path).stdout as String;
      expect(log, contains('Ajoute le README'));
    });

    test('dépôt piégé : hooks et fsmonitor neutralisés, filtres bloquants', () async {
      final p = await h.pair('read,git-write');
      final r = h.repo('piege');
      final marker = File('${h.tmp.path}/pwned');
      final hook = File('${r.path}/.git/hooks/pre-commit')
        ..writeAsStringSync('#!/bin/sh\ntouch ${marker.path}\n');
      Process.runSync('chmod', ['+x', hook.path]);
      final fsmon = File('${h.tmp.path}/fsmon.sh')..writeAsStringSync('#!/bin/sh\ntouch ${marker.path}\n');
      Process.runSync('chmod', ['+x', fsmon.path]);
      Process.runSync('git', ['config', 'core.fsmonitor', fsmon.path], workingDirectory: r.path);
      File('${r.path}/a.txt').writeAsStringSync('a');
      final status = await h.wait(p.accessToken, (await h.submit(p.accessToken, 'git.status', rootPath: r.path)).id);
      expect(status.state, OpState.succeeded);
      expect(marker.existsSync(), isFalse, reason: 'core.fsmonitor ne doit pas s\'exécuter');
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['a.txt']}),
          failsWith(409, ErrorCodes.conflict), reason: 'configuration exécutable détectée');
      Process.runSync('git', ['config', '--unset', 'core.fsmonitor'], workingDirectory: r.path);
      var op = await h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['a.txt']});
      await h.approve(p.accessToken, op.id);
      op = await h.submit(p.accessToken, 'git.commit', rootPath: r.path, params: {'message': 'x'});
      expect((await h.approve(p.accessToken, op.id)).state, OpState.succeeded);
      expect(marker.existsSync(), isFalse, reason: 'le hook pre-commit ne doit pas s\'exécuter');
      Process.runSync('git', ['config', 'filter.x.clean', 'touch ${marker.path}'], workingDirectory: r.path);
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: r.path, params: {'paths': ['a.txt']}),
          failsWith(409, ErrorCodes.conflict));
    });

    test('isolation : un appareil ne voit pas les opérations d\'un autre', () async {
      final a = await h.pair();
      final b = await h.pair();
      final r = h.repo('iso');
      final op = await h.submit(a.accessToken, 'git.status', rootPath: r.path);
      expect((await h.call('GET', '/v1/ops/${op.id}', token: b.accessToken)).$1, 404);
      expect((await h.call('POST', '/v1/ops/${op.id}/cancel', token: b.accessToken)).$1, 404);
    });

    test('liste des projets : sous-dossiers, liens et dossiers cachés ignorés', () async {
      final p = await h.pair();
      h.repo('alpha');
      Directory('${h.root.path}/beta').createSync();
      Directory('${h.root.path}/.cache').createSync();
      Link('${h.root.path}/evasion').createSync(h.outside.path);
      final st = await h.wait(p.accessToken, (await h.submit(p.accessToken, 'project.list', rootPath: h.root.path)).id);
      final list = (st.result!['projects'] as List).cast<Map<String, dynamic>>();
      expect(list.map((e) => e['name']), ['alpha', 'beta']);
      expect(list.first['git'], isTrue);
      expect(list.last['git'], isFalse);
    });

    test('détection de projet (lecture seule)', () async {
      final p = await h.pair();
      final r = h.repo('flutter_app');
      File('${r.path}/pubspec.yaml').writeAsStringSync('name: x\nflutter:\n  uses-material-design: true\n');
      Directory('${r.path}/android').createSync();
      final st = await h.wait(p.accessToken, (await h.submit(p.accessToken, 'project.detect', rootPath: r.path)).id);
      expect(st.result!['kinds'], ['flutter']);
      expect(st.result!['platforms'], ['android']);
      expect(st.result!['git'], isTrue);
    });
  });

  group('audit', () {
    test('événements consignés, aucun jeton dans le journal', () async {
      final p = await h.pair('read,git-write');
      final d = Directory('${h.root.path}/audit')..createSync();
      final op = await h.submit(p.accessToken, 'git.init', rootPath: d.path);
      await h.approve(p.accessToken, op.id);
      await h.server.runner.idle();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final raw = h.server.audit.file.readAsStringSync();
      for (final e in ['pair.start', 'pair.complete', 'op.submitted', 'op.approved', 'op.finished']) {
        expect(raw, contains('"$e"'));
      }
      expect(raw, isNot(contains(p.accessToken)));
      expect(raw, isNot(contains(p.refreshToken)));
      expect(h.server.audit.file.statSync().modeString(), 'rw-------');
      final (s, j) = await h.call('GET', '/v1/audit', token: p.accessToken);
      expect(s, 200);
      expect((j['data'] as List).first['event'], 'op.finished');
    });
  });

  group('délais, annulation, plafond de sortie (git simulé)', () {
    late Harness hs;
    late File fakeGit;
    setUp(() async {
      await h.stop();
      final dir = await Directory.systemTemp.createTemp('fakegit_');
      fakeGit = File('${dir.path}/git')
        ..writeAsStringSync('#!/bin/sh\ncase "\$*" in *--porcelain*) exec sleep 5;; *log*) yes x | head -c 3000000;; esac\n');
      Process.runSync('chmod', ['+x', fakeGit.path]);
      hs = await Harness.start(runner: (g) => OpRunner(g,
          gitExecutable: fakeGit.path, opTimeout: const Duration(seconds: 1), maxOutputBytes: 1000));
      h = hs;
    });

    test('délai dépassé : processus tué', () async {
      final p = await hs.pair();
      final op = await hs.submit(p.accessToken, 'git.status', rootPath: hs.root.path);
      final st = await hs.wait(p.accessToken, op.id);
      expect(st.state, OpState.timedOut);
      expect(st.error, contains('Délai dépassé'));
    });

    test('annulation d\'une opération en cours', () async {
      final p = await hs.pair();
      final op = await hs.submit(p.accessToken, 'git.status', rootPath: hs.root.path);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await hs.call('POST', '/v1/ops/${op.id}/cancel', token: p.accessToken);
      expect((await hs.wait(p.accessToken, op.id)).state, OpState.cancelled);
    });

    test('sortie plafonnée', () async {
      final p = await hs.pair();
      final st = await hs.wait(p.accessToken, (await hs.submit(p.accessToken, 'git.log', rootPath: hs.root.path)).id);
      expect(st.stdout, contains('[sortie tronquée à 1000 octets]'));
      expect(st.stdout.length, lessThan(1100));
    });
  });
}
