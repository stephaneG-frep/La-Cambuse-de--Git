import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late PairResult p;
  late Directory remote;

  setUp(() async {
    h = await Harness.start(runner: (g) => OpRunner(g, allowFileRemotes: true));
    p = await h.pair('read,git-write,remote');
    remote = Directory('${h.root.path}/distant.git')..createSync();
    Process.runSync('git', ['init', '-q', '--bare', '-b', 'main', remote.path]);
  });
  tearDown(() => h.stop());

  Future<OpStatus> run(String type, Directory d, [Map<String, dynamic> params = const {}]) async {
    final op = await h.submit(p.accessToken, type, rootPath: d.path, params: params);
    final st = await h.wait(p.accessToken, op.id);
    return st.state == OpState.awaitingApproval ? h.approve(p.accessToken, op.id) : st;
  }

  Directory committedRepo(String name) {
    final d = h.repo(name);
    File('${d.path}/README.md').writeAsStringSync('# $name\n');
    Process.runSync('git', ['add', '.'], workingDirectory: d.path);
    Process.runSync('git', ['commit', '-qm', 'Premier commit'], workingDirectory: d.path);
    return d;
  }

  group('remotes', () {
    test('ajout, liste ; remote existant préservé', () async {
      final d = committedRepo('r1');
      expect((await run('git.remote.add', d, {'name': 'origin', 'url': remote.path})).state, OpState.succeeded);
      expect((await run('git.remote.list', d)).stdout, contains('origin\t${remote.path}'));
      await expectLater(h.submit(p.accessToken, 'git.remote.add', rootPath: d.path, params: {'name': 'origin', 'url': remote.path}),
          failsWith(409, ErrorCodes.conflict));
    });

    test('URL refusées : identifiants, http, hôte inconnu, incomplète', () async {
      final d = committedRepo('r2');
      final strict = OpRunner(RootGuard([h.root.path]));
      for (final bad in [
        'https://moi:ghp_xxxxxxxxxxxxxxxxxxxxxxxx@github.com/moi/p.git',
        'http://github.com/moi/p.git',
        'https://evil.example.com/moi/p.git',
        'https://github.com/moi',
        'git@github.com:moi/p.git',
        'ext::sh -c touch% /tmp/pwned',
      ]) {
        expect(() => strict.prepare(OpRequest(type: 'git.remote.add', root: d.path, params: {'name': 'x', 'url': bad})),
            throwsA(isA<OpValidationError>()), reason: bad);
      }
      expect(strict.prepare(OpRequest(type: 'git.remote.add', root: d.path,
          params: {'name': 'origin', 'url': 'https://github.com/moi/projet.git'})).plan.join(),
          contains('git remote add origin https://github.com/moi/projet.git'));
    });
  });

  group('push et pull', () {
    test('outgoing puis push réel vers un dépôt nu ; plan sans --force', () async {
      final d = committedRepo('pousse');
      await run('git.remote.add', d, {'name': 'origin', 'url': remote.path});
      final out = await run('git.outgoing', d, {'remote': 'origin', 'branch': 'main'});
      expect(out.result!['remoteBranchExists'], isFalse);
      expect((out.result!['commits'] as List).single['subject'], 'Premier commit');
      expect(out.result!['files'], ['README.md']);
      expect(out.result!['secrets'], isEmpty);

      final op = await h.submit(p.accessToken, 'git.push', rootPath: d.path, params: {'remote': 'origin', 'branch': 'main'});
      expect(op.state, OpState.awaitingApproval);
      final plan = op.plan.join('\n');
      expect(plan, contains('git push --porcelain origin refs/heads/main:refs/heads/main'));
      expect(op.plan.firstWhere((l) => l.startsWith('Commande exacte')), isNot(contains('--force')));
      final st = await h.approve(p.accessToken, op.id);
      expect(st.state, OpState.succeeded, reason: '${st.error} ${st.stderr}');
      expect(st.result!['pushedCommits'], 1);
      final remoteLog = Process.runSync('git', ['log', '--oneline', 'main'], workingDirectory: remote.path).stdout as String;
      expect(remoteLog, contains('Premier commit'));
      final again = await run('git.outgoing', d, {'remote': 'origin', 'branch': 'main'});
      expect(again.result!['commits'], isEmpty, reason: 'plus rien à envoyer');
    });

    test('secret supprimé dans un commit ultérieur : push quand même bloqué (historique)', () async {
      final d = committedRepo('histoire');
      File('${d.path}/config.txt').writeAsStringSync('token = ghp_${'Z' * 36}\n');
      Process.runSync('git', ['add', 'config.txt'], workingDirectory: d.path);
      Process.runSync('git', ['commit', '-qm', 'oups'], workingDirectory: d.path);
      File('${d.path}/config.txt').deleteSync();
      Process.runSync('git', ['commit', '-qam', 'retire le secret'], workingDirectory: d.path);
      await run('git.remote.add', d, {'name': 'origin', 'url': remote.path});
      final out = await run('git.outgoing', d, {'remote': 'origin', 'branch': 'main'});
      expect((out.result!['secrets'] as List).single['file'], 'config.txt');
      final st = await run('git.push', d, {'remote': 'origin', 'branch': 'main'});
      expect(st.state, OpState.failed);
      expect(st.error, contains('Secret probable détecté'));
      expect(st.error, isNot(contains('Z' * 36)));
      final remoteRefs = Process.runSync('git', ['show-ref'], workingDirectory: remote.path).stdout as String;
      expect(remoteRefs.trim(), isEmpty, reason: 'rien n\'a été publié');
    });

    test('branche nouvelle : seuls les commits absents du dépôt distant comptent', () async {
      final d = committedRepo('branche');
      await run('git.remote.add', d, {'name': 'origin', 'url': remote.path});
      await run('git.push', d, {'remote': 'origin', 'branch': 'main'});
      Process.runSync('git', ['switch', '-q', '-c', 'fonction'], workingDirectory: d.path);
      File('${d.path}/NOTES.md').writeAsStringSync('notes\n');
      Process.runSync('git', ['add', 'NOTES.md'], workingDirectory: d.path);
      Process.runSync('git', ['commit', '-qm', 'Ajoute les notes'], workingDirectory: d.path);
      final out = await run('git.outgoing', d, {'remote': 'origin', 'branch': 'fonction'});
      expect(out.result!['remoteBranchExists'], isFalse);
      expect((out.result!['commits'] as List).map((c) => c['subject']), ['Ajoute les notes']);
      expect(out.result!['files'], ['NOTES.md']);
      final st = await run('git.push', d, {'remote': 'origin', 'branch': 'fonction'});
      expect(st.result!['pushedCommits'], 1);
    });

    test('pull en avance rapide uniquement', () async {
      final a = committedRepo('a');
      await run('git.remote.add', a, {'name': 'origin', 'url': remote.path});
      await run('git.push', a, {'remote': 'origin', 'branch': 'main'});
      final b = Directory('${h.root.path}/b');
      Process.runSync('git', ['clone', '-q', remote.path, b.path]);
      Process.runSync('git', ['config', 'user.name', 'B'], workingDirectory: b.path);
      Process.runSync('git', ['config', 'user.email', 'b@exemple.fr'], workingDirectory: b.path);
      File('${b.path}/NOTES.md').writeAsStringSync('notes\n');
      Process.runSync('git', ['add', '.'], workingDirectory: b.path);
      Process.runSync('git', ['commit', '-qm', 'Ajoute des notes'], workingDirectory: b.path);
      Process.runSync('git', ['push', '-q', 'origin', 'main'], workingDirectory: b.path);
      final st = await run('git.pull', a, {'remote': 'origin', 'branch': 'main'});
      expect(st.state, OpState.succeeded, reason: st.stderr);
      expect(File('${a.path}/NOTES.md').existsSync(), isTrue);
      expect(st.plan.join(), contains('--ff-only'));
    });

    test('portée remote requise', () async {
      final ro = await h.pair('read,git-write');
      final d = committedRepo('scope');
      await run('git.remote.add', d, {'name': 'origin', 'url': remote.path});
      await expectLater(h.submit(ro.accessToken, 'git.push', rootPath: d.path, params: {'remote': 'origin', 'branch': 'main'}),
          failsWith(403, ErrorCodes.forbiddenScope));
    });
  });

  group('jeton', () {
    test('HTTPS : jeton requis, jamais dans le plan, l\'audit ni l\'URL ; masqué dans les sorties', () async {
      await h.stop();
      final dir = await Directory.systemTemp.createTemp('fakegit2_');
      // Faux git : affiche l'en-tête d'authentification reçu par l'environnement
      // et le jeton, pour vérifier qu'ils sont masqués.
      final fake = File('${dir.path}/git')
        ..writeAsStringSync('#!/bin/sh\n'
            'case "\$*" in *"remote get-url"*) echo https://github.com/moi/projet.git; exit 0;; esac\n'
            'case "\$*" in *"rev-parse --verify"*) exit 1;; *"rev-list"*|*"log"*|*"diff-tree"*) exit 0;; esac\n'
            'echo "entete=\$GIT_CONFIG_VALUE_0" >&2; echo "helper=\$(echo "\$*" | grep -o "credential.helper=")" >&2; echo "ghp_TESTTOKEN0000000000000000000000000000"\n');
      Process.runSync('chmod', ['+x', fake.path]);
      h = await Harness.start(runner: (g) => OpRunner(g, gitExecutable: fake.path));
      p = await h.pair('read,git-write,remote');
      final d = Directory('${h.root.path}/https')..createSync();
      Directory('${d.path}/.git').createSync();
      await expectLater(h.submit(p.accessToken, 'git.push', rootPath: d.path, params: {'remote': 'origin', 'branch': 'main'}),
          failsWith(400, ErrorCodes.invalidRequest), reason: 'jeton manquant');
      const token = 'ghp_TESTTOKEN0000000000000000000000000000';
      final op = await h.submit(p.accessToken, 'git.push', rootPath: d.path,
          params: {'remote': 'origin', 'branch': 'main', 'token': token});
      expect(op.plan.join(), isNot(contains(token)));
      expect(op.plan.join(), contains('jamais stocké, affiché ni journalisé'));
      final st = await h.approve(p.accessToken, op.id);
      expect(st.stdout, isNot(contains(token)));
      expect(st.stdout, contains('[SECRET MASQUÉ]'));
      expect(st.stderr, contains('entete=AUTHORIZATION: basic [SECRET MASQUÉ]'), reason: 'en-tête transmis par l\'environnement, masqué');
      expect(st.stderr, contains('helper=credential.helper='), reason: 'helpers d\'identifiants désactivés');
      await h.server.runner.idle();
      final audit = h.server.audit.file.readAsStringSync();
      expect(audit, isNot(contains(token)));
      expect(audit, isNot(contains('TESTTOKEN')));
    });
  });
}
