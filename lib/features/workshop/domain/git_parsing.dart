/// Analyse des sorties Git renvoyées par le compagnon (format porcelaine et
/// diff unifié). Fonctions pures, testées.
library;

class FileChange {
  const FileChange({required this.path, required this.index, required this.worktree, this.from});

  final String path;

  /// Code de la colonne index (`M`, `A`, `D`, `R`, `?`, espace).
  final String index;

  /// Code de la colonne copie de travail.
  final String worktree;

  /// Ancien nom (renommage).
  final String? from;

  bool get untracked => index == '?' && worktree == '?';
  bool get staged => !untracked && index != ' ';
  bool get unstaged => untracked || worktree != ' ';
  bool get conflicted => index == 'U' || worktree == 'U' || (index == 'A' && worktree == 'A') || (index == 'D' && worktree == 'D');
}

class RepoStatus {
  const RepoStatus({required this.branch, required this.changes, this.upstream, this.noCommits = false});

  final String? branch;
  final String? upstream;
  final bool noCommits;
  final List<FileChange> changes;

  bool get clean => changes.isEmpty;
}

/// `git status --porcelain=v1 --branch`.
RepoStatus parsePorcelain(String out) {
  String? branch, upstream;
  var noCommits = false;
  final changes = <FileChange>[];
  for (final line in out.split('\n')) {
    if (line.isEmpty) continue;
    if (line.startsWith('## ')) {
      var b = line.substring(3);
      if (b.startsWith('No commits yet on ')) {
        noCommits = true;
        b = b.substring('No commits yet on '.length);
      }
      final bracket = b.indexOf(' [');
      if (bracket >= 0) b = b.substring(0, bracket);
      final dots = b.indexOf('...');
      if (dots >= 0) {
        upstream = b.substring(dots + 3);
        b = b.substring(0, dots);
      }
      branch = b;
      continue;
    }
    if (line.length < 4) continue;
    final x = line[0], y = line[1];
    var path = line.substring(3);
    String? from;
    final arrow = path.indexOf(' -> ');
    if ((x == 'R' || x == 'C') && arrow >= 0) {
      from = path.substring(0, arrow);
      path = path.substring(arrow + 4);
    }
    if (path.startsWith('"') && path.endsWith('"')) path = path.substring(1, path.length - 1);
    changes.add(FileChange(path: path, index: x, worktree: y, from: from));
  }
  return RepoStatus(branch: branch, upstream: upstream, noCommits: noCommits, changes: changes);
}

enum DiffLineKind { header, hunk, added, removed, context }

class DiffLine {
  const DiffLine(this.kind, this.text, {this.oldNo, this.newNo});
  final DiffLineKind kind;
  final String text;
  final int? oldNo;
  final int? newNo;
}

class FileDiff {
  FileDiff(this.path);
  final String path;
  final lines = <DiffLine>[];
  bool binary = false;
  int get added => lines.where((l) => l.kind == DiffLineKind.added).length;
  int get removed => lines.where((l) => l.kind == DiffLineKind.removed).length;
}

final _hunkRe = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

/// Diff unifié (`git diff`) découpé par fichier, avec numéros de ligne.
List<FileDiff> parseUnifiedDiff(String out) {
  final files = <FileDiff>[];
  FileDiff? cur;
  var oldNo = 0, newNo = 0;
  for (final line in out.split('\n')) {
    if (line.startsWith('diff --git ')) {
      final m = RegExp(r'^diff --git a/(.+) b/(.+)$').firstMatch(line);
      cur = FileDiff(m?.group(2) ?? line.substring(11));
      files.add(cur);
      continue;
    }
    if (cur == null) continue;
    if (line.startsWith('Binary files')) {
      cur.binary = true;
    } else if (line.startsWith('@@')) {
      final m = _hunkRe.firstMatch(line);
      oldNo = int.tryParse(m?.group(1) ?? '') ?? 0;
      newNo = int.tryParse(m?.group(2) ?? '') ?? 0;
      cur.lines.add(DiffLine(DiffLineKind.hunk, line));
    } else if (line.startsWith('+++') || line.startsWith('---') || line.startsWith('index ') ||
        line.startsWith('new file') || line.startsWith('deleted file') || line.startsWith('similarity') ||
        line.startsWith('rename ') || line.startsWith('old mode') || line.startsWith('new mode')) {
      cur.lines.add(DiffLine(DiffLineKind.header, line));
    } else if (line.startsWith('+')) {
      cur.lines.add(DiffLine(DiffLineKind.added, line.substring(1), newNo: newNo++));
    } else if (line.startsWith('-')) {
      cur.lines.add(DiffLine(DiffLineKind.removed, line.substring(1), oldNo: oldNo++));
    } else if (line.startsWith(' ')) {
      cur.lines.add(DiffLine(DiffLineKind.context, line.substring(1), oldNo: oldNo++, newNo: newNo++));
    } else if (line.startsWith(r'\')) {
      cur.lines.add(DiffLine(DiffLineKind.header, line));
    }
  }
  return files;
}

class BranchInfo {
  const BranchInfo(this.name, this.current, this.sha, this.subject);
  final String name;
  final bool current;
  final String sha;
  final String subject;
}

/// Sortie de `git branch --format=%(HEAD)|%(refname:short)|%(objectname:short)|%(subject)`.
List<BranchInfo> parseBranches(String out) => [
      for (final l in out.split('\n'))
        if (l.contains('|'))
          () {
            final p = l.split('|');
            return BranchInfo(p[1], p[0] == '*', p.length > 2 ? p[2] : '', p.length > 3 ? p.sublist(3).join('|') : '');
          }(),
    ];

class CommitInfo {
  const CommitInfo(this.sha, this.refs, this.subject);
  final String sha;
  final String refs;
  final String subject;
}

/// Sortie de `git log --oneline --decorate`.
List<CommitInfo> parseOneline(String out) => [
      for (final l in out.split('\n'))
        if (l.trim().isNotEmpty)
          () {
            final sp = l.indexOf(' ');
            final sha = sp < 0 ? l : l.substring(0, sp);
            var rest = sp < 0 ? '' : l.substring(sp + 1);
            var refs = '';
            if (rest.startsWith('(')) {
              final close = rest.indexOf(') ');
              if (close > 0) {
                refs = rest.substring(1, close);
                rest = rest.substring(close + 2);
              }
            }
            return CommitInfo(sha, refs, rest);
          }(),
    ];
