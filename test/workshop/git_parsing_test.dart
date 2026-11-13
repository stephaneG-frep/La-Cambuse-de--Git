import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/workshop/domain/git_parsing.dart';
import 'package:la_cambuse/features/workshop/presentation/project_screen.dart' show shortPath;

void main() {
  test('porcelaine : branche, amont, états, renommage, guillemets', () {
    final s = parsePorcelain('## main...origin/main [ahead 1]\n M lib/a.dart\nA  lib/b.dart\n?? notes.txt\nR  old.txt -> new.txt\nMM both.dart\n?? "avec espace.txt"\n');
    expect(s.branch, 'main');
    expect(s.upstream, 'origin/main');
    expect(s.changes.map((c) => c.path), ['lib/a.dart', 'lib/b.dart', 'notes.txt', 'new.txt', 'both.dart', 'avec espace.txt']);
    final a = s.changes[0], b = s.changes[1], n = s.changes[2], r = s.changes[3], mm = s.changes[4];
    expect([a.staged, a.unstaged], [false, true]);
    expect([b.staged, b.unstaged], [true, false]);
    expect([n.untracked, n.staged, n.unstaged], [true, false, true]);
    expect(r.from, 'old.txt');
    expect([mm.staged, mm.unstaged], [true, true]);
  });

  test('porcelaine : dépôt sans commit', () {
    final s = parsePorcelain('## No commits yet on main\n?? README.md\n');
    expect(s.noCommits, isTrue);
    expect(s.branch, 'main');
    expect(s.clean, isFalse);
  });

  test('diff unifié : fichiers, hunks, numéros de ligne, binaire', () {
    final files = parseUnifiedDiff('''diff --git a/lib/a.dart b/lib/a.dart
index 111..222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -3,3 +3,4 @@ class A
 ligne3
-ancienne
+nouvelle
+ajout
 ligne5
diff --git a/img.png b/img.png
Binary files a/img.png and b/img.png differ''');
    expect(files.map((f) => f.path), ['lib/a.dart', 'img.png']);
    final a = files.first;
    expect([a.added, a.removed], [2, 1]);
    final removed = a.lines.firstWhere((l) => l.kind == DiffLineKind.removed);
    expect([removed.text, removed.oldNo], ['ancienne', 4]);
    final added = a.lines.where((l) => l.kind == DiffLineKind.added).toList();
    expect(added.map((l) => l.newNo), [4, 5]);
    expect(files.last.binary, isTrue);
  });

  test('branches et journal', () {
    final b = parseBranches('*|main|abc1234|Premier commit\n |fonction/menu|def5678|Ajoute | le menu\n');
    expect(b.first.current, isTrue);
    expect(b.last.subject, 'Ajoute | le menu');
    final log = parseOneline('abc1234 (HEAD -> main, tag: v1) Message un\ndef5678 Message deux\n');
    expect(log.first.refs, 'HEAD -> main, tag: v1');
    expect(log.first.subject, 'Message un');
    expect(log.last.refs, '');
  });

  test('chemin abrégé', () {
    expect(shortPath('/home/moi/Projets/vitrine'), '…/Projets/vitrine');
    expect(shortPath('/vitrine'), '/vitrine');
  });
}
