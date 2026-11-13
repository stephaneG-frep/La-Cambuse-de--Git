import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late File calls;

  Future<OpStatus> run(PairResult p, String type, {String? root, Map<String, dynamic> params = const {}}) async {
    final op = await h.submit(p.accessToken, type, rootPath: root, params: params);
    final st = await h.wait(p.accessToken, op.id);
    return st.state == OpState.awaitingApproval ? h.approve(p.accessToken, op.id) : st;
  }

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('fakedocker_');
    calls = File('${dir.path}/appels.log');
    // Faux docker : consigne chaque appel et renvoie des sorties JSON réalistes.
    final fake = File('${dir.path}/docker')
      ..writeAsStringSync('#!/bin/sh\necho "\$*" >> ${calls.path}\n'
          'case "\$1" in\n'
          '  version) echo \'{"Client":{"Version":"29.1.3"},"Server":{"Version":"29.1.3"}}\';;\n'
          '  info) echo \'{"Containers":3,"ContainersRunning":1,"Images":7,"SecurityOptions":["name=seccomp"]}\';;\n'
          '  system) echo \'{"Type":"Images","Size":"12GB","Reclaimable":"5.2GB (43%)"}\';;\n'
          '  image) echo \'{"Repository":"node","Tag":"22-slim","ID":"abc","Size":"329MB"}\';;\n'
          '  ps) echo \'{"ID":"c1","Names":"web","Image":"nginx:1.27","State":"running","Status":"Up 2 hours"}\';;\n'
          '  logs) echo "2026-11-13T10:00:00Z démarrage avec ghp_\$(printf "x%.0s" \$(seq 36))"; echo "erreur" >&2;;\n'
          'esac\n');
    Process.runSync('chmod', ['+x', fake.path]);
    h = await Harness.start(runner: (g) => OpRunner(g, dockerExecutable: fake.path));
  });
  tearDown(() => h.stop());

  test('portée docker requise pour l\'inspection', () async {
    final p = await h.pair('read,git-write');
    await expectLater(h.submit(p.accessToken, 'docker.info'), failsWith(403, ErrorCodes.forbiddenScope));
  });

  test('diagnostic, images, conteneurs, journaux masqués ; aucune commande destructrice', () async {
    final p = await h.pair('read,docker');
    final info = (await run(p, 'docker.info')).result!;
    expect(info['available'], isTrue);
    expect(info['server'], '29.1.3');
    expect((info['notes'] as List).map((n) => n['message']).join(), contains('récupérable'));
    expect(((await run(p, 'docker.images')).result!['images'] as List).single['Repository'], 'node');
    expect(((await run(p, 'docker.containers')).result!['containers'] as List).single['Names'], 'web');
    final logs = (await run(p, 'docker.logs', params: {'container': 'web', 'tail': 50})).result!['logs'] as String;
    expect(logs, contains('[SECRET MASQUÉ]'));
    expect(logs, isNot(contains('ghp_xxxx')));
    expect(logs, contains('erreur'), reason: 'stderr inclus');
    await expectLater(h.submit(p.accessToken, 'docker.logs', params: {'container': '-f; rm -rf /'}),
        failsWith(400, ErrorCodes.invalidRequest));
    final invoked = calls.readAsStringSync();
    expect(invoked, contains('logs --tail 50 --timestamps -- web'));
    for (final verb in ['run ', 'rm ', 'stop ', 'kill ', 'pull ', 'exec ', 'prune']) {
      expect(invoked, isNot(contains(verb)), reason: verb);
    }
  });

  test('analyse des fichiers Docker d\'un projet ; note Flutter', () async {
    final p = await h.pair('read');
    final d = Directory('${h.root.path}/api')..createSync();
    File('${d.path}/Dockerfile').writeAsStringSync('FROM node\nCMD node index.js\n');
    File('${d.path}/compose.yaml').writeAsStringSync('services:\n  web:\n    build: .\n    privileged: true\n');
    File('${d.path}/package.json').writeAsStringSync('{}');
    final r = (await run(p, 'docker.lint', root: d.path)).result!;
    final files = (r['files'] as List).cast<Map<String, dynamic>>();
    expect(files.map((f) => f['path']), ['Dockerfile', 'compose.yaml']);
    expect((files.first['findings'] as List).map((x) => x['rule']), containsAll(['DF001', 'DF002', 'DF014']));
    expect((files.last['findings'] as List).map((x) => x['rule']), contains('DC002'));
    expect(r['suggestedTemplate'], 'node');
    final f = Directory('${h.root.path}/appli')..createSync();
    File('${f.path}/pubspec.yaml').writeAsStringSync('name: a\nflutter:\n  uses-material-design: true\n');
    expect((await run(p, 'docker.lint', root: f.path)).result!['flutterNote'], contains('ne tourne pas'));
  });

  test('génération : approbation, jamais d\'écrasement, refus pour Flutter', () async {
    final p = await h.pair('read,git-write');
    final d = Directory('${h.root.path}/service')..createSync();
    final op = await h.submit(p.accessToken, 'docker.scaffold', rootPath: d.path, params: {'template': 'node'});
    expect(op.plan, containsAll([contains('+ Dockerfile'), contains('+ .dockerignore')]));
    expect(File('${d.path}/Dockerfile').existsSync(), isFalse, reason: 'rien avant approbation');
    final st = await h.approve(p.accessToken, op.id);
    expect(st.state, OpState.succeeded, reason: st.error);
    expect(File('${d.path}/Dockerfile').readAsStringSync(), contains('USER node'));
    expect(lintDockerfile(File('${d.path}/Dockerfile').readAsStringSync()).where((x) => x.severity != LintSeverity.info), isEmpty);
    await expectLater(h.submit(p.accessToken, 'docker.scaffold', rootPath: d.path, params: {'template': 'node'}),
        failsWith(409, ErrorCodes.conflict));
    final fl = Directory('${h.root.path}/flutter')..createSync();
    await expectLater(h.submit(p.accessToken, 'docker.scaffold', rootPath: fl.path, params: {'template': 'flutter'}),
        failsWith(400, ErrorCodes.invalidRequest));
  });

  test('Docker absent : diagnostic explicite, pas d\'erreur', () async {
    await h.stop();
    h = await Harness.start(runner: (g) => OpRunner(g, dockerExecutable: '/chemin/inexistant/docker'));
    final p = await h.pair('read,docker');
    final info = (await run(p, 'docker.info')).result!;
    expect(info['available'], isFalse);
    expect((info['notes'] as List).single['message'], contains('facultatif'));
  });

  test('démon réel (lecture seule) : diagnostic cohérent', () async {
    await h.stop();
    h = await Harness.start(runner: (g) => OpRunner(g));
    final p = await h.pair('read,docker');
    final info = (await run(p, 'docker.info')).result!;
    expect(info['available'], isTrue);
    expect(info['server'], isNotNull);
    expect(info['images'], isA<int>());
  }, skip: Process.runSync('sh', ['-c', 'docker info >/dev/null 2>&1']).exitCode == 0 ? false : 'Docker indisponible');
}
