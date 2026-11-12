import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/sandbox/git_sandbox.dart';
import 'package:la_cambuse/features/academy/domain/sandbox/shell_tokenizer.dart';

GitSandbox repo() => GitSandbox()
  ..runAll([
    'git init',
    'git config user.name "Anne"',
    'git config user.email anne@exemple.fr',
  ]);

void main() {
  group('tokenizer', () {
    test('guillemets et redirections', () {
      expect(tokenize('echo "a b" >> f.txt'), ['echo', 'a b', '>>', 'f.txt']);
      expect(tokenize("git commit -m 'msg ici'"), ['git', 'commit', '-m', 'msg ici']);
      expect(tokenize('echo x>f'), ['echo', 'x', '>', 'f']);
    });
    test('refuse enchaînement et substitution', () {
      for (final bad in ['ls; rm x', 'ls | cat', r'echo $HOME', 'echo `id`', 'a && b']) {
        expect(() => tokenize(bad), throwsFormatException, reason: bad);
      }
      expect(() => tokenize('echo "ouvert'), throwsFormatException);
    });
  });

  test('hors dépôt : erreur fatale de Git', () {
    final r = GitSandbox().run('git status');
    expect(r.ok, isFalse);
    expect(r.output, contains('not a git repository'));
  });

  test('chemins confinés au bac à sable', () {
    final s = repo();
    for (final p in ['../x', '/etc/passwd', 'a/../../b']) {
      final r = s.run('echo pirate > $p');
      expect(r.ok, isFalse, reason: p);
      expect(r.output, contains('Chemin refusé'));
    }
    expect(s.workTree, isEmpty);
  });

  test('commit sans identité refusé', () {
    final s = GitSandbox()..runAll(['git init', 'touch a']);
    s.run('git add a');
    final r = s.run('git commit -m "x"');
    expect(r.ok, isFalse);
    expect(r.output, contains('Author identity unknown'));
  });

  test('cycle untracked → staged → commit → clean', () {
    final s = repo();
    s.run('echo bonjour > a.txt');
    expect(s.untracked, ['a.txt']);
    expect(s.run('git status').output, contains('Untracked files'));
    s.run('git add a.txt');
    expect(s.stagedChanges, {'a.txt': 'new file'});
    expect(s.run('git status -s').output, 'A  a.txt');
    final c = s.run('git commit -m "Premier commit"');
    expect(c.ok, isTrue);
    expect(c.output, contains('(root-commit)'));
    expect(s.isClean, isTrue);
    expect(s.run('git status').output, contains('nothing to commit, working tree clean'));
  });

  test('commit sans changement refusé', () {
    final s = repo()..runAll(['touch a', 'git add a', 'git commit -m "a"']);
    expect(s.run('git commit -m "vide"').ok, isFalse);
  });

  test('diff non indexé puis indexé, et restore', () {
    final s = repo()..runAll(['echo v1 > f', 'git add f', 'git commit -m "v1"']);
    s.run('echo v2 > f');
    expect(s.run('git diff').output, allOf(contains('-v1'), contains('+v2')));
    expect(s.run('git diff --staged').output, isEmpty);
    s.run('git add f');
    expect(s.run('git diff --staged').output, contains('+v2'));
    s.run('git restore --staged f');
    expect(s.stagedChanges, isEmpty);
    expect(s.unstagedChanges, {'f': 'modified'});
    s.run('git restore f');
    expect(s.workTree['f'], 'v1\n');
    expect(s.isClean, isTrue);
  });

  test('log, décorations et show', () {
    final s = repo()
      ..runAll(['touch a', 'git add a', 'git commit -m "un"', 'echo x > a', 'git commit -am "deux"']);
    final log = s.run('git log --oneline').output.split('\n');
    expect(log, hasLength(2));
    expect(log.first, contains('(HEAD -> main) deux'));
    expect(s.run('git show').output, contains('+x'));
  });

  test('branches : création, bascule, fichiers propres à chaque branche', () {
    final s = repo()..runAll(['echo base > a', 'git add .', 'git commit -m "base"']);
    expect(s.run('git switch -c fonction').output, "Switched to a new branch 'fonction'");
    s.runAll(['echo neuf > b', 'git add b', 'git commit -m "b"']);
    s.run('git switch main');
    expect(s.workTree.containsKey('b'), isFalse);
    s.run('git checkout fonction');
    expect(s.workTree['b'], 'neuf\n');
    expect(s.run('git branch').output, '* fonction\n  main');
  });

  test('bascule refusée si elle écraserait des modifications', () {
    final s = repo()
      ..runAll(['echo 1 > a', 'git add a', 'git commit -m "1"', 'git switch -c b',
                'echo 2 > a', 'git commit -am "2"', 'git switch main', 'echo local > a']);
    final r = s.run('git switch b');
    expect(r.ok, isFalse);
    expect(r.output, contains('would be overwritten'));
    expect(s.workTree['a'], 'local\n');
  });

  test('fusion fast-forward', () {
    final s = repo()
      ..runAll(['touch a', 'git add a', 'git commit -m "a"', 'git switch -c f',
                'touch b', 'git add b', 'git commit -m "b"', 'git switch main']);
    final r = s.run('git merge f');
    expect(r.output, contains('Fast-forward'));
    expect(s.branches['main'], s.branches['f']);
    expect(s.workTree.containsKey('b'), isTrue);
    expect(s.run('git branch -d f').ok, isTrue);
  });

  test('fusion à trois voies sans conflit → commit de fusion', () {
    final s = repo()
      ..runAll(['touch a', 'git add a', 'git commit -m "a"', 'git switch -c f',
                'touch b', 'git add b', 'git commit -m "b"', 'git switch main',
                'touch c', 'git add c', 'git commit -m "c"']);
    final r = s.run('git merge f');
    expect(r.output, contains("Merge made by the 'ort' strategy"));
    expect(s.headCommit!.parents, hasLength(2));
    expect(s.workTree.keys, containsAll(['a', 'b', 'c']));
  });

  test('conflit : marqueurs, commit bloqué, résolution, commit de fusion', () {
    final s = repo()
      ..runAll(['echo base > f', 'git add f', 'git commit -m "base"', 'git switch -c x',
                'echo theirs > f', 'git commit -am "x"', 'git switch main',
                'echo ours > f', 'git commit -am "m"']);
    final r = s.run('git merge x');
    expect(r.ok, isTrue);
    expect(r.output, contains('CONFLICT (content): Merge conflict in f'));
    expect(s.workTree['f'], '<<<<<<< HEAD\nours\n=======\ntheirs\n>>>>>>> x\n');
    expect(s.run('git status').output, contains('both modified:   f'));
    expect(s.run('git commit -m "trop tôt"').ok, isFalse);
    s.runAll(['echo résolu > f', 'git add f']);
    final c = s.run('git commit');
    expect(c.ok, isTrue, reason: c.output);
    expect(s.headCommit!.message, "Merge branch 'x'");
    expect(s.isMerging, isFalse);
  });

  test('merge --abort restaure l\'état', () {
    final s = repo()
      ..runAll(['echo base > f', 'git add f', 'git commit -m "base"', 'git switch -c x',
                'echo t > f', 'git commit -am "x"', 'git switch main',
                'echo o > f', 'git commit -am "m"', 'git merge x']);
    expect(s.run('git merge --abort').ok, isTrue);
    expect(s.workTree['f'], 'o\n');
    expect(s.isMerging, isFalse);
  });

  test('suppression de branche non fusionnée refusée sans -D', () {
    final s = repo()
      ..runAll(['touch a', 'git add a', 'git commit -m "a"', 'git switch -c f',
                'touch b', 'git add b', 'git commit -m "b"', 'git switch main']);
    expect(s.run('git branch -d f').output, contains('not fully merged'));
    expect(s.run('git branch -D f').ok, isTrue);
  });

  test('.gitignore : fichiers ignorés exclus de status et add', () {
    final s = repo()..runAll(['echo "*.log" > .gitignore', 'echo "build/" >> .gitignore',
                               'touch app.log', 'touch build/out.apk', 'touch main.dart']);
    expect(s.untracked, ['.gitignore', 'main.dart']);
    s.run('git add .');
    expect(s.index.keys, unorderedEquals(['.gitignore', 'main.dart']));
    final r = s.run('git add app.log');
    expect(r.ok, isFalse);
    expect(r.output, contains('ignored by one of your .gitignore'));
    expect(s.run('git add -f app.log').ok, isTrue);
  });

  test('étiquettes légères et annotées', () {
    final s = repo()..runAll(['touch a', 'git add a', 'git commit -m "a"']);
    s.run('git tag v0.1.0');
    s.run('git tag -a v1.0.0 -m "Première version"');
    expect(s.run('git tag').output, 'v0.1.0\nv1.0.0');
    expect(s.tagMessages['v1.0.0'], 'Première version');
    expect(s.run('git log --oneline').output, contains('tag: v1.0.0'));
  });

  test('noms de branche invalides refusés', () {
    final s = repo()..runAll(['touch a', 'git add a', 'git commit -m "a"']);
    for (final n in ['a..b', 'fin.', 'x.lock', 'a//b']) {
      expect(s.run('git branch $n').ok, isFalse, reason: n);
    }
  });

  test('commandes non simulées : refus explicite', () {
    final r = repo().run('git push --force');
    expect(r.ok, isFalse);
    expect(r.output, contains('ne prend pas en charge'));
    expect(repo().run('sudo rm -rf /').output, contains('Commande inconnue'));
  });
}
