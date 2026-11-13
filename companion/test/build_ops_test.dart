import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

import 'harness.dart';

final realApk = File('../build/app/outputs/flutter-apk/app-debug.apk');

void main() {
  late Harness h;
  late File calls;

  Future<OpStatus> run(PairResult p, String type, Directory d, [Map<String, dynamic> params = const {}]) async {
    final op = await h.submit(p.accessToken, type, rootPath: d.path, params: params);
    final st = await h.wait(p.accessToken, op.id);
    return st.state == OpState.awaitingApproval ? h.approve(p.accessToken, op.id) : st;
  }

  Directory flutterProject(String name) {
    final d = Directory('${h.root.path}/$name')..createSync();
    File('${d.path}/pubspec.yaml').writeAsStringSync('name: $name\nflutter:\n  uses-material-design: true\n');
    return d;
  }

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('fakeflutter_');
    calls = File('${dir.path}/appels.log');
    final fake = File('${dir.path}/flutter')
      ..writeAsStringSync('#!/bin/sh\necho "\$PWD|\$*" >> ${calls.path}\n'
          'case "\$*" in\n'
          '  "--version --machine") echo \'{"frameworkVersion":"3.47.2"}\';;\n'
          '  "test --reporter expanded") echo "00:01 +3: All tests passed!";;\n'
          '  analyze) echo "No issues found!";;\n'
          '  build*) echo "✓ Built build/app/outputs/flutter-apk/app-debug.apk"; exit 0;;\n'
          'esac\n');
    Process.runSync('chmod', ['+x', fake.path]);
    h = await Harness.start(runner: (g) => OpRunner(g, flutterExecutable: fake.path));
  });
  tearDown(() => h.stop());

  test('portée build requise ; refus hors projet Flutter', () async {
    final ro = await h.pair('read,git-write');
    final d = flutterProject('appli');
    await expectLater(h.submit(ro.accessToken, 'flutter.test', rootPath: d.path), failsWith(403, ErrorCodes.forbiddenScope));
    final p = await h.pair('read,build');
    final notFlutter = Directory('${h.root.path}/node')..createSync();
    File('${notFlutter.path}/package.json').writeAsStringSync('{}');
    await expectLater(h.submit(p.accessToken, 'flutter.test', rootPath: notFlutter.path), failsWith(400, ErrorCodes.invalidRequest));
  });

  test('analyse, tests et APK debug : approbation, commande exacte, dossier du projet', () async {
    final p = await h.pair('read,build');
    final d = flutterProject('appli');
    final op = await h.submit(p.accessToken, 'flutter.build.apk.debug', rootPath: d.path);
    expect(op.state, OpState.awaitingApproval, reason: 'un build exécute du code du projet');
    expect(op.plan, contains('Commande exacte : flutter build apk --debug --target-platform android-arm64'));
    expect(op.plan.join(), contains('jamais pour la distribution'));
    expect((await h.approve(p.accessToken, op.id)).stdout, contains('Built'));
    expect((await run(p, 'flutter.analyze', d)).stdout, contains('No issues found!'));
    expect((await run(p, 'flutter.test', d)).stdout, contains('All tests passed!'));
    final log = calls.readAsStringSync();
    expect(log, contains('${d.resolveSymbolicLinksSync()}|build apk --debug --target-platform android-arm64'));
    expect(log, isNot(contains('--release')));
  });

  test('génération de CI GitHub et GitLab, version Flutter détectée, jamais d\'écrasement', () async {
    final p = await h.pair('read,git-write');
    final d = flutterProject('ci');
    final op = await h.submit(p.accessToken, 'ci.scaffold', rootPath: d.path, params: {'kind': 'flutter', 'provider': 'github'});
    expect(op.plan.first, contains('Flutter 3.47.2'));
    await h.approve(p.accessToken, op.id);
    final yml = File('${d.path}/.github/workflows/ci.yml').readAsStringSync();
    expect(yml, contains('flutter-version: 3.47.2'));
    expect(yml, contains('permissions:\n  contents: read'));
    await expectLater(h.submit(p.accessToken, 'ci.scaffold', rootPath: d.path, params: {'kind': 'flutter', 'provider': 'github'}),
        failsWith(409, ErrorCodes.conflict));
    expect((await run(p, 'ci.scaffold', d, {'kind': 'flutter', 'provider': 'gitlab'})).state, OpState.succeeded);
    expect(File('${d.path}/.gitlab-ci.yml').readAsStringSync(), contains('Secret-Detection'));
    await expectLater(h.submit(p.accessToken, 'ci.scaffold', rootPath: d.path, params: {'kind': 'cobol', 'provider': 'github'}),
        failsWith(400, ErrorCodes.invalidRequest));
  });

  test('cale des artefacts : tailles, SHA-256, paquets de dist', () async {
    final p = await h.pair('read');
    final d = flutterProject('cale');
    Directory('${d.path}/dist').createSync();
    File('${d.path}/dist/appli_1.0.0_amd64.deb').writeAsStringSync('paquet');
    File('${d.path}/dist/SHA256SUMS').writeAsStringSync('x');
    final r = (await run(p, 'artifacts.list', d)).result!;
    final list = (r['artifacts'] as List).cast<Map<String, dynamic>>();
    final deb = list.firstWhere((a) => a['kind'] == 'deb');
    expect((deb['sha256'] as String).length, 64);
    expect(deb['bytes'], 6);
  });

  test('vrai APK debug de La Cambuse : signature « debug », ABI arm64-v8a', () async {
    final tools = ApkTools.detect();
    final dir = await Directory.systemTemp.createTemp('cale_');
    Directory('${dir.path}/build/app/outputs/flutter-apk').createSync(recursive: true);
    Link('${dir.path}/build/app/outputs/flutter-apk/app-debug.apk').createSync(realApk.absolute.path);
    final r = await listArtifacts(dir.path, tools: tools);
    final apk = (r['artifacts'] as List).single as Map<String, dynamic>;
    expect((apk['signature'] as Map)['status'], 'debug');
    expect((apk['signature'] as Map)['certificate'], contains('CN=Android Debug'));
    expect(apk['abis'], contains('arm64-v8a'));
    expect(apk['sha256'], await sha256OfFile(realApk));
    await dir.delete(recursive: true);
  }, skip: realApk.existsSync() && ApkTools.detect().apksigner != null ? false : 'APK ou apksigner absent');
}
