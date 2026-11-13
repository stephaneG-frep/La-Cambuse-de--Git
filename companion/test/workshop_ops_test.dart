import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

import 'harness.dart';

/// Empreinte de l'arborescence (chemins + tailles + dates) pour prouver qu'une
/// opération en lecture n'a rien modifié.
String fingerprintTree(Directory d) {
  final entries = d.listSync(recursive: true, followLinks: false).map((e) {
    final st = e.statSync();
    return '${e.path}|${st.size}|${st.modified.microsecondsSinceEpoch}';
  }).toList()
    ..sort();
  return entries.join('\n');
}

void main() {
  late Harness h;
  late PairResult p;
  setUp(() async {
    h = await Harness.start();
    p = await h.pair('read,git-write');
  });
  tearDown(() => h.stop());

  Future<OpStatus> run(String type, Directory d, [Map<String, dynamic> params = const {}]) async {
    final op = await h.submit(p.accessToken, type, rootPath: d.path, params: params);
    final st = await h.wait(p.accessToken, op.id);
    return st.state == OpState.awaitingApproval ? h.approve(p.accessToken, op.id) : st;
  }

  Directory flutterProject(String name, {bool git = false}) {
    final d = git ? h.repo(name) : (Directory('${h.root.path}/$name')..createSync());
    File('${d.path}/pubspec.yaml').writeAsStringSync('name: $name\nflutter:\n  uses-material-design: true\n');
    Directory('${d.path}/lib').createSync();
    File('${d.path}/lib/main.dart').writeAsStringSync('void main() {}\n');
    return d;
  }

  group('audit non destructif', () {
    test('secrets, gros fichiers, artefacts, .gitignore, licence ; aucune écriture', () async {
      final d = flutterProject('appli');
      File('${d.path}/.env').writeAsStringSync('DB_PASSWORD=motdepasse-tres-long\n');
      File('${d.path}/lib/config.dart').writeAsStringSync("const token = 'ghp_${'A' * 36}';\n");
      File('${d.path}/android-key.jks').writeAsBytesSync([0, 1, 2]);
      File('${d.path}/app-release.apk').writeAsBytesSync(List.filled(1000, 0));
      File('${d.path}/video.mp4').writeAsBytesSync(List.filled(11 * 1024 * 1024, 7));
      Directory('${d.path}/build').createSync();
      File('${d.path}/build/sortie.bin').writeAsStringSync('ignoré par le parcours');
      final before = fingerprintTree(d);

      final st = await run('project.audit', d);
      expect(st.state, OpState.succeeded, reason: st.error);
      expect(fingerprintTree(d), before, reason: 'l\'audit ne doit rien modifier');
      final r = st.result!;
      final codes = (r['findings'] as List).map((f) => '${f['code']}:${f['file'] ?? ''}').toList();
      expect(codes, containsAll([
        'secret_file:.env',
        'secret_content:lib/config.dart',
        'secret_file:android-key.jks',
        'build_artifact:app-release.apk',
        'large_file:video.mp4',
        'no_gitignore:',
        'no_license:',
      ]));
      expect(r['blocking'], greaterThanOrEqualTo(3));
      expect((r['findings'] as List).first['severity'], 'blocking', reason: 'tri par gravité');
      expect(r['gitignoreMissing'], containsAll(['.dart_tool/', 'build/', '.env', '*.jks']));
      expect((r['stats'] as Map)['skipped'], contains('build'));
      final raw = st.toJson().toString();
      expect(raw, isNot(contains('A' * 36)), reason: 'la valeur du secret n\'est jamais renvoyée');
      expect(raw, isNot(contains('motdepasse-tres-long')));
    });

    test('fichiers sensibles ignorés : signalés en info seulement', () async {
      final d = flutterProject('propre', git: true);
      File('${d.path}/.gitignore').writeAsStringSync('.env\n*.jks\n');
      File('${d.path}/.env').writeAsStringSync('API_KEY=valeur-secrete-longue\n');
      final r = (await run('project.audit', d)).result!;
      final env = (r['findings'] as List).where((f) => f['file'] == '.env').toList();
      expect(env.single['code'], 'secret_file_ignored');
      expect(env.single['severity'], 'info');
      expect((r['gitInfo'] as Map)['branch'], 'main', reason: 'dépôt sans commit : branche quand même connue');
      expect((r['gitInfo'] as Map)['commits'], 0);
    });
  });

  group('blocage des secrets', () {
    test('git.add refuse un fichier sensible ou un contenu secret', () async {
      final d = flutterProject('fuite', git: true);
      File('${d.path}/.env').writeAsStringSync('X=1\n');
      File('${d.path}/lib/cle.dart').writeAsStringSync("final k = 'glpat-${'b' * 20}';\n");
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: d.path, params: {'paths': ['.env']}),
          failsWith(422, ErrorCodes.secretDetected));
      await expectLater(h.submit(p.accessToken, 'git.add', rootPath: d.path, params: {'paths': ['lib/cle.dart']}),
          failsWith(422, ErrorCodes.secretDetected));
    });

    test('git.commit re-vérifie l\'index à l\'exécution (secret indexé hors application)', () async {
      final d = flutterProject('index', git: true);
      File('${d.path}/secrets.txt').writeAsStringSync('aws = AKIAABCDEFGHIJKLMNOP\n');
      Process.runSync('git', ['add', 'secrets.txt'], workingDirectory: d.path);
      final op = await h.submit(p.accessToken, 'git.commit', rootPath: d.path, params: {'message': 'oups'});
      final st = await h.approve(p.accessToken, op.id);
      expect(st.state, OpState.failed);
      expect(st.error, contains('Secret probable détecté'));
      expect(st.error, contains('secrets.txt:1'));
      expect(st.error, isNot(contains('AKIAABCDEFGHIJKLMNOP')));
      final log = Process.runSync('git', ['log', '--oneline'], workingDirectory: d.path);
      expect(log.exitCode, isNot(0), reason: 'aucun commit créé');
    });
  });

  group('branches', () {
    test('liste, création, bascule ; noms invalides refusés', () async {
      final d = flutterProject('branches', git: true);
      Process.runSync('git', ['add', '.'], workingDirectory: d.path);
      Process.runSync('git', ['commit', '-qm', 'init'], workingDirectory: d.path);
      expect((await run('git.branch.create', d, {'name': 'fonction/menu'})).state, OpState.succeeded);
      expect((await run('git.switch', d, {'name': 'fonction/menu'})).state, OpState.succeeded);
      final list = await run('git.branches', d);
      expect(list.stdout, contains('*|fonction/menu|'));
      expect(list.stdout, contains(' |main|'));
      for (final bad in ['-x', 'a..b', 'fin/', 'x.lock', '']) {
        await expectLater(h.submit(p.accessToken, 'git.branch.create', rootPath: d.path, params: {'name': bad}),
            failsWith(400, ErrorCodes.invalidRequest), reason: bad);
      }
    });
  });

  group('restauration et sauvegardes', () {
    test('restore --staged : non destructif ; restore : sauvegarde automatique puis restaurable', () async {
      final d = flutterProject('travail', git: true);
      Process.runSync('git', ['add', '.'], workingDirectory: d.path);
      Process.runSync('git', ['commit', '-qm', 'init'], workingDirectory: d.path);
      File('${d.path}/lib/main.dart').writeAsStringSync('void main() { print("travail précieux"); }\n');
      Process.runSync('git', ['add', 'lib/main.dart'], workingDirectory: d.path);
      expect((await run('git.restore', d, {'paths': ['lib/main.dart'], 'staged': true})).state, OpState.succeeded);
      expect(File('${d.path}/lib/main.dart').readAsStringSync(), contains('travail précieux'));

      final op = await h.submit(p.accessToken, 'git.restore', rootPath: d.path, params: {'paths': ['lib/main.dart']});
      expect(op.plan.join('\n'), contains('Sauvegarde automatique'));
      final st = await h.approve(p.accessToken, op.id);
      expect(st.state, OpState.succeeded, reason: st.error);
      expect(File('${d.path}/lib/main.dart').readAsStringSync(), 'void main() {}\n');
      final backupId = (st.result!['backup'] as Map)['id'] as String;

      final list = (await run('backup.list', d)).result!['backups'] as List;
      expect(list.single['id'], backupId);
      expect(list.single['files'], ['lib/main.dart']);

      final restored = await run('backup.restore', d, {'id': backupId});
      expect(restored.state, OpState.succeeded, reason: restored.error);
      final target = restored.result!['restoredTo'] as String;
      expect(target, startsWith('${h.root.resolveSymbolicLinksSync()}/travail-restauration-'));
      expect(File('$target/lib/main.dart').readAsStringSync(), contains('travail précieux'));
      expect(File('${d.path}/lib/main.dart').readAsStringSync(), 'void main() {}\n', reason: 'rien n\'est écrasé');
    });

    test('sauvegarde complète du projet (.git inclus, build exclu) et restauration', () async {
      final d = flutterProject('complet', git: true);
      Process.runSync('git', ['add', '.'], workingDirectory: d.path);
      Process.runSync('git', ['commit', '-qm', 'init'], workingDirectory: d.path);
      Directory('${d.path}/build').createSync();
      File('${d.path}/build/lourd.bin').writeAsStringSync('x' * 1000);
      final b = await run('project.backup', d);
      expect(b.state, OpState.succeeded, reason: b.error);
      final id = b.result!['id'] as String;
      final r = await run('backup.restore', d, {'id': id});
      final target = r.result!['restoredTo'] as String;
      expect(File('$target/lib/main.dart').existsSync(), isTrue);
      expect(Directory('$target/.git').existsSync(), isTrue);
      expect(Directory('$target/build').existsSync(), isFalse);
      final log = Process.runSync('git', ['log', '--oneline'], workingDirectory: target).stdout as String;
      expect(log, contains('init'));
    });

    test('restauration d\'une sauvegarde d\'un autre projet refusée ; identifiant piégé refusé', () async {
      final a = flutterProject('a', git: true);
      final b = flutterProject('b', git: true);
      final id = (await run('project.backup', a)).result!['id'] as String;
      await expectLater(h.submit(p.accessToken, 'backup.restore', rootPath: b.path, params: {'id': id}),
          failsWith(400, ErrorCodes.invalidRequest));
      await expectLater(h.submit(p.accessToken, 'backup.restore', rootPath: a.path, params: {'id': '../../etc'}),
          failsWith(404, ErrorCodes.notFound));
    });

    test('restauration refusée si elle sortirait des dossiers autorisés', () async {
      await expectLater(h.submit(p.accessToken, 'backup.restore', rootPath: h.root.path, params: {'id': 'x'}),
          throwsA(isA<ApiFailure>()));
    });
  });

  group('.gitignore', () {
    test('ajoute seulement les lignes manquantes, plan explicite', () async {
      final d = flutterProject('gi');
      File('${d.path}/.gitignore').writeAsStringSync('build/');
      final op = await h.submit(p.accessToken, 'gitignore.update', rootPath: d.path,
          params: {'lines': ['build/', '.dart_tool/', '.env']});
      expect(op.plan, containsAll(['+ .dart_tool/', '+ .env']));
      expect(op.plan, isNot(contains('+ build/')));
      expect(File('${d.path}/.gitignore').readAsStringSync(), 'build/', reason: 'rien avant approbation');
      await h.approve(p.accessToken, op.id);
      expect(File('${d.path}/.gitignore').readAsStringSync(), 'build/\n.dart_tool/\n.env\n');
      await expectLater(h.submit(p.accessToken, 'gitignore.update', rootPath: d.path, params: {'lines': ['.env']}),
          failsWith(409, ErrorCodes.conflict));
    });

    test('.gitignore lien symbolique vers l\'extérieur refusé', () async {
      final d = flutterProject('lien');
      Link('${d.path}/.gitignore').createSync('${h.outside.path}/id_rsa');
      await expectLater(h.submit(p.accessToken, 'gitignore.update', rootPath: d.path, params: {'lines': ['.env']}),
          failsWith(403, ErrorCodes.pathOutsideRoot));
      expect(File('${h.outside.path}/id_rsa').readAsStringSync(), 'CLE PRIVEE FACTICE');
    });
  });

  test('GitignoreMatcher : motifs, dossiers, négations, ancrage', () {
    final m = GitignoreMatcher('# commentaire\n*.log\nbuild/\n/secret.txt\n!important.log\ndocs/**/*.tmp\n');
    expect(m.ignores('app.log'), isTrue);
    expect(m.ignores('src/app.log'), isTrue);
    expect(m.ignores('important.log'), isFalse);
    expect(m.ignores('build/out.apk'), isTrue);
    expect(m.ignores('build'), isFalse, reason: 'motif de dossier : pas un fichier nommé build');
    expect(m.ignores('secret.txt'), isTrue);
    expect(m.ignores('src/secret.txt'), isFalse);
    expect(m.ignores('docs/a/b/x.tmp'), isTrue);
  });
}
