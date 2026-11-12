/// Bac à sable Git **simulé en mémoire** pour l'Académie.
///
/// Il n'exécute aucune commande système, n'accède à aucun fichier réel et ne
/// touche aucun dépôt : tout vit dans des structures Dart. Il reproduit le
/// comportement de Git pour les commandes enseignées (sorties inspirées de Git
/// en anglais, comme dans un terminal réel) et refuse explicitement les autres.
library;

import 'line_diff.dart';
import 'shell_tokenizer.dart';

class SandboxCommit {
  SandboxCommit({
    required this.id,
    required this.message,
    required this.parents,
    required this.tree,
    required this.author,
    required this.seq,
  });

  final String id;
  final String message;
  final List<String> parents;
  final Map<String, String> tree;
  final String author;
  final int seq;

  String get shortId => id.substring(0, 7);
}

class SandboxResult {
  const SandboxResult(this.output, {this.ok = true, this.clearScreen = false});

  final String output;
  final bool ok;
  final bool clearScreen;
}

class _MergeState {
  _MergeState(this.theirsName, this.theirsCommit, this.conflicts);

  final String theirsName;
  final String theirsCommit;
  final Set<String> conflicts;
}

class _Fail implements Exception {
  _Fail(this.message);
  final String message;
}

class GitSandbox {
  GitSandbox();

  static const repoPath = '/bac-a-sable';
  static const unsupported = {
    'rebase', 'reset', 'push', 'pull', 'fetch', 'clone', 'remote', 'stash',
    'revert', 'cherry-pick', 'bisect', 'submodule', 'worktree', 'gc', 'reflog',
  };

  final Map<String, String> workTree = {};
  final Map<String, String> index = {};
  final Map<String, SandboxCommit> commits = {};
  final Map<String, String?> branches = {};
  final Map<String, String> tags = {};
  final Map<String, String> tagMessages = {};
  final Map<String, String> config = {};
  final List<String> history = [];

  bool initialized = false;
  String head = 'main';
  _MergeState? _merge;
  int _seq = 0;

  // ---------------------------------------------------------------- Requêtes

  String? get headCommitId => initialized ? branches[head] : null;
  SandboxCommit? get headCommit =>
      headCommitId == null ? null : commits[headCommitId];
  Map<String, String> get headTree => headCommit?.tree ?? const {};
  bool get isMerging => _merge != null;
  Set<String> get conflicts => _merge?.conflicts ?? const {};

  /// Ancêtres (inclus) d'un commit.
  Set<String> ancestors(String? id) {
    final out = <String>{};
    final stack = [?id];
    while (stack.isNotEmpty) {
      final c = stack.removeLast();
      if (out.add(c)) stack.addAll(commits[c]!.parents);
    }
    return out;
  }

  bool isAncestor(String? maybeAncestor, String? of) =>
      maybeAncestor != null && ancestors(of).contains(maybeAncestor);

  List<SandboxCommit> logFrom(String? id) {
    final list = ancestors(id).map((c) => commits[c]!).toList()
      ..sort((a, b) => b.seq.compareTo(a.seq));
    return list;
  }

  Map<String, String> get stagedChanges => _changes(headTree, index);
  Map<String, String> get unstagedChanges {
    final out = <String, String>{};
    for (final p in index.keys) {
      if (!workTree.containsKey(p)) {
        out[p] = 'deleted';
      } else if (workTree[p] != index[p]) {
        out[p] = 'modified';
      }
    }
    return out;
  }

  List<String> get untracked => (workTree.keys
          .where((p) => !index.containsKey(p) && !isIgnored(p))
          .toList())
    ..sort();

  bool get isClean =>
      stagedChanges.isEmpty && unstagedChanges.isEmpty && untracked.isEmpty;

  /// Vrai si [path] correspond à un motif du `.gitignore` (racine).
  bool isIgnored(String path) {
    final gi = workTree['.gitignore'];
    if (gi == null) return false;
    final name = path.split('/').last;
    for (final raw in gi.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.endsWith('/')) {
        final dir = line.substring(0, line.length - 1).replaceFirst(RegExp('^/'), '');
        if (path.startsWith('$dir/') || path.contains('/$dir/')) return true;
        continue;
      }
      final re = _glob(line.replaceFirst(RegExp('^/'), ''));
      if (line.contains('/') ? re.hasMatch(path) : re.hasMatch(name)) return true;
    }
    return false;
  }

  static RegExp _glob(String pattern) {
    final b = StringBuffer('^');
    for (final ch in pattern.split('')) {
      b.write(switch (ch) {
        '*' => '[^/]*',
        '?' => '[^/]',
        _ => RegExp.escape(ch),
      });
    }
    b.write(r'$');
    return RegExp(b.toString());
  }

  static Map<String, String> _changes(Map<String, String> from, Map<String, String> to) {
    final out = <String, String>{};
    for (final p in {...from.keys, ...to.keys}) {
      if (!from.containsKey(p)) {
        out[p] = 'new file';
      } else if (!to.containsKey(p)) {
        out[p] = 'deleted';
      } else if (from[p] != to[p]) {
        out[p] = 'modified';
      }
    }
    return out;
  }

  // -------------------------------------------------------------- Exécution

  /// Exécute une ligne de commande dans le bac à sable.
  SandboxResult run(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const SandboxResult('');
    history.add(trimmed);
    final List<String> args;
    try {
      args = tokenize(trimmed);
    } on FormatException catch (e) {
      return SandboxResult('erreur de syntaxe : ${e.message}', ok: false);
    }
    try {
      return SandboxResult(_dispatch(args));
    } on _Fail catch (f) {
      return SandboxResult(f.message, ok: false);
    }
  }

  /// Exécute une suite de commandes (préparation d'exercice). Lève une
  /// [StateError] si l'une échoue : le contenu pédagogique est alors invalide.
  void runAll(Iterable<String> lines) {
    for (final l in lines) {
      final r = run(l);
      if (!r.ok) throw StateError('Préparation invalide « $l » : ${r.output}');
    }
    history.clear();
  }

  String _dispatch(List<String> a) {
    switch (a.first) {
      case 'aide' || 'help':
        return _help;
      case 'clear':
        return '';
      case 'ls':
        return (workTree.keys.toList()..sort()).join('\n');
      case 'pwd':
        return repoPath;
      case 'cat':
        if (a.length < 2) throw _Fail('cat : fichier manquant');
        final p = _path(a[1]);
        return _strip(workTree[p] ?? (throw _Fail('cat: $p: No such file or directory')));
      case 'touch':
        if (a.length < 2) throw _Fail('touch : fichier manquant');
        for (final f in a.skip(1)) {
          workTree.putIfAbsent(_path(f), () => '');
        }
        return '';
      case 'rm':
        if (a.length < 2) throw _Fail('rm : fichier manquant');
        final p = _path(a[1]);
        if (workTree.remove(p) == null) {
          throw _Fail("rm: cannot remove '$p': No such file or directory");
        }
        return '';
      case 'echo':
        return _echo(a.skip(1).toList());
      case 'git':
        if (a.length < 2) return _help;
        return _git(a[1], a.skip(2).toList());
      default:
        throw _Fail(
          'Commande inconnue dans le bac à sable : « ${a.first} ». '
          'Tapez « aide » pour la liste des commandes disponibles.',
        );
    }
  }

  static const _help = '''Commandes du bac à sable (simulé, aucune action réelle) :
  ls, cat FICHIER, touch FICHIER, rm FICHIER, pwd, clear
  echo "texte" > FICHIER   (remplace)    echo "texte" >> FICHIER   (ajoute)
  git init | config | status [-s] | add | commit -m | log [--oneline]
  git show | diff [--staged] | restore [--staged] | rm
  git branch [-d] | switch [-c] | checkout [-b] | merge [--abort] | tag [-a -m]''';

  String _strip(String s) => s.endsWith('\n') ? s.substring(0, s.length - 1) : s;

  /// Chemin confiné au bac à sable : pas d'absolu, pas de « .. ».
  String _path(String raw) {
    final p = raw.startsWith('./') ? raw.substring(2) : raw;
    if (p.isEmpty ||
        p.startsWith('/') ||
        p.split('/').any((s) => s == '..' || s.isEmpty || s == '.')) {
      throw _Fail('Chemin refusé : « $raw » sort du bac à sable ou est invalide.');
    }
    return p;
  }

  String _echo(List<String> a) {
    final i = a.indexWhere((t) => t == '>' || t == '>>');
    if (i == -1) return a.join(' ');
    if (i + 1 >= a.length) throw _Fail('echo : fichier de destination manquant');
    final text = '${a.sublist(0, i).join(' ')}\n';
    final p = _path(a[i + 1]);
    workTree[p] = a[i] == '>' ? text : (workTree[p] ?? '') + text;
    return '';
  }

  void _requireRepo() {
    if (!initialized) {
      throw _Fail('fatal: not a git repository (or any of the parent directories): .git');
    }
  }

  String _git(String cmd, List<String> a) {
    if (cmd == 'init') return _init();
    if (cmd == 'config') return _config(a);
    if (cmd == '--version' || cmd == 'version') return 'git version 2.x (simulateur pédagogique)';
    if (unsupported.contains(cmd)) {
      throw _Fail(
        'Le simulateur ne prend pas en charge « git $cmd ». Cette commande est '
        'expliquée dans le cours et se pratique sur un vrai dépôt dans l\'Atelier.',
      );
    }
    _requireRepo();
    return switch (cmd) {
      'status' => _status(short: a.contains('-s') || a.contains('--short')),
      'add' => _add(a),
      'rm' => _gitRm(a),
      'commit' => _commit(a),
      'log' => _log(a),
      'show' => _show(a),
      'diff' => _diff(a),
      'restore' => _restore(a),
      'branch' => _branch(a),
      'switch' => _switch(a, createFlag: '-c'),
      'checkout' => _switch(a, createFlag: '-b'),
      'merge' => _mergeCmd(a),
      'tag' => _tag(a),
      _ => throw _Fail("git: '$cmd' is not a git command. See 'git --help'."),
    };
  }

  String _init() {
    if (initialized) return 'Reinitialized existing Git repository in $repoPath/.git/';
    initialized = true;
    branches['main'] = null;
    head = 'main';
    return 'Initialized empty Git repository in $repoPath/.git/';
  }

  String _config(List<String> a) {
    final args = a.where((t) => t != '--global' && t != '--local').toList();
    if (args.isEmpty) throw _Fail('usage: git config [--global] <clé> [<valeur>]');
    final key = args[0];
    if (!RegExp(r'^[a-z]+\.[a-zA-Z]+$').hasMatch(key)) {
      throw _Fail('error: key does not contain a section: $key');
    }
    if (args.length == 1) return config[key] ?? (throw _Fail(''));
    config[key] = args.sublist(1).join(' ');
    return '';
  }

  // ------------------------------------------------------------------ status

  String _status({required bool short}) {
    final staged = stagedChanges;
    final unstaged = unstagedChanges;
    final untr = untracked;
    final conf = conflicts;
    if (short) {
      final lines = <String>[];
      for (final p in {...staged.keys, ...unstaged.keys, ...conf}.toList()..sort()) {
        if (conf.contains(p)) {
          lines.add('UU $p');
          continue;
        }
        String code(String? k) => switch (k) {
              'new file' => 'A',
              'modified' => 'M',
              'deleted' => 'D',
              _ => ' ',
            };
        lines.add('${code(staged[p])}${code(unstaged[p])} $p');
      }
      lines.addAll(untr.map((p) => '?? $p'));
      return lines.join('\n');
    }
    final b = StringBuffer('On branch $head\n');
    if (headCommitId == null) b.write('\nNo commits yet\n');
    if (conf.isNotEmpty) {
      b.write('You have unmerged paths.\n  (fix conflicts and run "git commit")\n'
          '  (use "git merge --abort" to abort the merge)\n\nUnmerged paths:\n');
      for (final p in conf.toList()..sort()) {
        b.write('\tboth modified:   $p\n');
      }
    } else if (isMerging) {
      b.write('All conflicts fixed but you are still merging.\n'
          '  (use "git commit" to conclude merge)\n');
    }
    final stagedShown = {...staged}..removeWhere((p, _) => conf.contains(p));
    if (stagedShown.isNotEmpty) {
      b.write('\nChanges to be committed:\n  (use "git restore --staged <file>..." to unstage)\n');
      for (final p in stagedShown.keys.toList()..sort()) {
        b.write('\t${'${stagedShown[p]}:'.padRight(12)}$p\n');
      }
    }
    final unstagedShown = {...unstaged}..removeWhere((p, _) => conf.contains(p));
    if (unstagedShown.isNotEmpty) {
      b.write('\nChanges not staged for commit:\n'
          '  (use "git add <file>..." to update what will be committed)\n'
          '  (use "git restore <file>..." to discard changes in working directory)\n');
      for (final p in unstagedShown.keys.toList()..sort()) {
        b.write('\t${'${unstagedShown[p]}:'.padRight(12)}$p\n');
      }
    }
    if (untr.isNotEmpty) {
      b.write('\nUntracked files:\n  (use "git add <file>..." to include in what will be committed)\n');
      for (final p in untr) {
        b.write('\t$p\n');
      }
    }
    if (stagedShown.isEmpty && unstagedShown.isEmpty && untr.isEmpty && conf.isEmpty) {
      b.write(headCommitId == null && workTree.isEmpty
          ? '\nnothing to commit (create/copy files and use "git add" to track)'
          : '\nnothing to commit, working tree clean');
    } else if (stagedShown.isEmpty && conf.isEmpty && !isMerging) {
      b.write(untr.isNotEmpty && unstagedShown.isEmpty
          ? '\nnothing added to commit but untracked files present (use "git add" to track)'
          : '\nno changes added to commit (use "git add" and/or "git commit -a")');
    }
    return _strip(b.toString().trimRight());
  }

  // --------------------------------------------------------------- add / rm

  String _add(List<String> a) {
    final force = a.contains('-f') || a.contains('--force');
    final paths = a.where((t) => !t.startsWith('-') || t == '-A').toList();
    if (paths.isEmpty) {
      throw _Fail('Nothing specified, nothing added.\nhint: Maybe you wanted to say \'git add .\'?');
    }
    final ignoredHits = <String>[];
    for (final raw in paths) {
      if (raw == '.' || raw == '-A' || raw == '--all') {
        for (final p in workTree.keys) {
          if (index.containsKey(p) || !isIgnored(p) || force) _stage(p);
        }
        for (final p in index.keys.where((p) => !workTree.containsKey(p)).toList()) {
          index.remove(p);
          _merge?.conflicts.remove(p);
        }
        continue;
      }
      final p = _path(raw);
      if (workTree.containsKey(p)) {
        if (!index.containsKey(p) && isIgnored(p) && !force) {
          ignoredHits.add(p);
          continue;
        }
        _stage(p);
      } else if (index.containsKey(p)) {
        index.remove(p);
        _merge?.conflicts.remove(p);
      } else {
        throw _Fail("fatal: pathspec '$p' did not match any files");
      }
    }
    if (ignoredHits.isNotEmpty) {
      throw _Fail('The following paths are ignored by one of your .gitignore files:\n'
          '${ignoredHits.join('\n')}\nhint: Use -f if you really want to add them.');
    }
    return '';
  }

  void _stage(String p) {
    index[p] = workTree[p]!;
    _merge?.conflicts.remove(p);
  }

  String _gitRm(List<String> a) {
    final paths = a.where((t) => !t.startsWith('-')).toList();
    final cached = a.contains('--cached');
    if (paths.isEmpty) throw _Fail('usage: git rm [--cached] <file>...');
    for (final raw in paths) {
      final p = _path(raw);
      if (!index.containsKey(p)) throw _Fail("fatal: pathspec '$p' did not match any files");
      index.remove(p);
      if (!cached) workTree.remove(p);
    }
    return paths.map((p) => "rm '$p'").join('\n');
  }

  // ------------------------------------------------------------------ commit

  String _commit(List<String> a) {
    final name = config['user.name'];
    final email = config['user.email'];
    if (name == null || email == null) {
      throw _Fail('Author identity unknown\n\n*** Please tell me who you are.\n\nRun\n\n'
          '  git config --global user.email "you@example.com"\n'
          '  git config --global user.name "Your Name"');
    }
    if (conflicts.isNotEmpty) {
      throw _Fail('error: Committing is not possible because you have unmerged files.\n'
          'hint: Fix them up in the work tree, and then use \'git add <file>\'\n'
          'hint: as appropriate to mark resolution and make a commit.');
    }
    var message = _option(a, const ['-m', '--message']);
    final all = a.contains('-a') || a.contains('--all') || a.contains('-am');
    if (a.contains('-am')) message ??= _after(a, '-am');
    if (message == null && isMerging) message = "Merge branch '${_merge!.theirsName}'";
    if (message == null) {
      throw _Fail('Le simulateur n\'ouvre pas d\'éditeur : utilisez git commit -m "message".');
    }
    if (message.trim().isEmpty) throw _Fail('Aborting commit due to empty commit message.');
    if (all) {
      for (final p in index.keys.toList()) {
        if (!workTree.containsKey(p)) {
          index.remove(p);
        } else {
          index[p] = workTree[p]!;
        }
      }
    }
    final changes = stagedChanges;
    if (changes.isEmpty && !isMerging) {
      throw _Fail(_status(short: false));
    }
    final parents = [
      ?headCommitId,
      if (isMerging) _merge!.theirsCommit,
    ];
    final id = _hash('$_seq|$message|${parents.join(',')}|${index.entries.join(';')}');
    _seq++;
    commits[id] = SandboxCommit(
      id: id,
      message: message,
      parents: parents,
      tree: Map.of(index),
      author: '$name <$email>',
      seq: _seq,
    );
    final root = headCommitId == null;
    branches[head] = id;
    _merge = null;
    final n = changes.length;
    return '[$head${root ? ' (root-commit)' : ''} ${id.substring(0, 7)}] $message\n'
        ' $n file${n == 1 ? '' : 's'} changed';
  }

  static String? _option(List<String> a, List<String> names) {
    for (final n in names) {
      final v = _after(a, n);
      if (v != null) return v;
    }
    return null;
  }

  static String? _after(List<String> a, String flag) {
    final i = a.indexOf(flag);
    return i >= 0 && i + 1 < a.length ? a[i + 1] : null;
  }

  /// Empreinte déterministe de 40 caractères hexadécimaux (FNV-1a 32 bits ×5).
  static String _hash(String input) {
    final b = StringBuffer();
    for (var salt = 0; salt < 5; salt++) {
      var h = 0x811c9dc5 ^ salt;
      for (final c in '$salt$input'.codeUnits) {
        h ^= c;
        h = (h * 0x01000193) & 0xffffffff;
      }
      b.write(h.toRadixString(16).padLeft(8, '0'));
    }
    return b.toString();
  }

  // -------------------------------------------------------------- log / show

  String _decorations(String id) {
    final d = <String>[];
    branches.forEach((n, c) {
      if (c == id) d.add(n == head ? 'HEAD -> $n' : n);
    });
    d.sort((x, y) => x.startsWith('HEAD') ? -1 : (y.startsWith('HEAD') ? 1 : x.compareTo(y)));
    tags.forEach((n, c) {
      if (c == id) d.add('tag: $n');
    });
    return d.isEmpty ? '' : ' (${d.join(', ')})';
  }

  String? _resolve(String ref) {
    if (ref == 'HEAD') return headCommitId;
    if (branches.containsKey(ref)) return branches[ref];
    if (tags.containsKey(ref)) return tags[ref];
    if (ref.length >= 4) {
      final m = commits.keys.where((k) => k.startsWith(ref)).toList();
      if (m.length == 1) return m.first;
    }
    return null;
  }

  String _log(List<String> a) {
    final oneline = a.contains('--oneline');
    final n = int.tryParse(_after(a, '-n') ?? '');
    final refs = a.where((t) => !t.startsWith('-') && int.tryParse(t) == null).toList();
    final start = refs.isEmpty ? headCommitId : _resolve(refs.first);
    if (refs.isNotEmpty && start == null) {
      throw _Fail("fatal: ambiguous argument '${refs.first}': unknown revision");
    }
    if (start == null) {
      throw _Fail("fatal: your current branch '$head' does not have any commits yet");
    }
    var list = logFrom(start);
    if (n != null) list = list.take(n).toList();
    if (oneline) {
      return list.map((c) => '${c.shortId}${_decorations(c.id)} ${c.message}').join('\n');
    }
    return list.map((c) {
      final merge = c.parents.length > 1
          ? 'Merge: ${c.parents.map((p) => p.substring(0, 7)).join(' ')}\n'
          : '';
      return 'commit ${c.id}${_decorations(c.id)}\n${merge}Author: ${c.author}\n\n    ${c.message}';
    }).join('\n\n');
  }

  String _show(List<String> a) {
    final ref = a.where((t) => !t.startsWith('-')).firstOrNull ?? 'HEAD';
    final id = _resolve(ref) ??
        (throw _Fail("fatal: ambiguous argument '$ref': unknown revision"));
    final c = commits[id]!;
    final parentTree = c.parents.isEmpty ? <String, String>{} : commits[c.parents.first]!.tree;
    final header = 'commit ${c.id}${_decorations(c.id)}\nAuthor: ${c.author}\n\n    ${c.message}';
    final d = _treeDiff(parentTree, c.tree);
    return d.isEmpty ? header : '$header\n\n$d';
  }

  // ------------------------------------------------------------------- diff

  String _diff(List<String> a) {
    final staged = a.contains('--staged') || a.contains('--cached');
    final only = a.where((t) => !t.startsWith('-')).map(_path).toSet();
    Map<String, String> from, to;
    if (staged) {
      from = headTree;
      to = index;
    } else {
      from = index;
      to = {
        for (final p in index.keys)
          if (workTree.containsKey(p)) p: workTree[p]!,
      };
    }
    return _treeDiff(from, to, only: only.isEmpty ? null : only);
  }

  String _treeDiff(Map<String, String> from, Map<String, String> to, {Set<String>? only}) {
    final out = <String>[];
    for (final p in ({...from.keys, ...to.keys}.toList()..sort())) {
      if (only != null && !only.contains(p)) continue;
      if (from[p] == to[p]) continue;
      out.add(unifiedDiff(p, from[p], to[p]));
    }
    return out.join('\n');
  }

  // ---------------------------------------------------------------- restore

  String _restore(List<String> a) {
    final staged = a.contains('--staged') || a.contains('-S');
    final paths = a.where((t) => !t.startsWith('-')).toList();
    if (paths.isEmpty) throw _Fail('fatal: you must specify path(s) to restore');
    for (final raw in paths) {
      if (raw == '.') {
        if (staged) {
          index
            ..clear()
            ..addAll(headTree);
        } else {
          index.forEach((p, c) => workTree[p] = c);
        }
        continue;
      }
      final p = _path(raw);
      if (staged) {
        if (!index.containsKey(p) && !headTree.containsKey(p)) {
          throw _Fail("error: pathspec '$p' did not match any file(s) known to git");
        }
        if (headTree.containsKey(p)) {
          index[p] = headTree[p]!;
        } else {
          index.remove(p);
        }
      } else {
        if (!index.containsKey(p)) {
          throw _Fail("error: pathspec '$p' did not match any file(s) known to git");
        }
        workTree[p] = index[p]!;
      }
    }
    return '';
  }

  // ---------------------------------------------------------------- branches

  static final _validName = RegExp(r'^(?!-)(?!.*\.\.)(?!.*//)[A-Za-z0-9._/\-]+(?<![./])$');

  void _checkName(String n) {
    if (!_validName.hasMatch(n) || n.endsWith('.lock')) {
      throw _Fail("fatal: '$n' is not a valid branch name");
    }
  }

  String _branch(List<String> a) {
    final del = a.contains('-d') || a.contains('-D') || a.contains('--delete');
    final force = a.contains('-D');
    final names = a.where((t) => !t.startsWith('-')).toList();
    if (names.isEmpty && !del) {
      final all = {...branches.keys}.toList()..sort();
      return all
          .where((b) => branches[b] != null || b == head)
          .map((b) => b == head ? '* $b' : '  $b')
          .join('\n');
    }
    if (del) {
      if (names.isEmpty) throw _Fail('fatal: branch name required');
      final out = <String>[];
      for (final n in names) {
        if (!branches.containsKey(n)) throw _Fail("error: branch '$n' not found");
        if (n == head) {
          throw _Fail("error: cannot delete branch '$n' used by worktree at '$repoPath'");
        }
        final id = branches[n];
        if (!force && id != null && !isAncestor(id, headCommitId)) {
          throw _Fail("error: the branch '$n' is not fully merged.\n"
              "hint: If you are sure you want to delete it, run 'git branch -D $n'");
        }
        branches.remove(n);
        out.add('Deleted branch $n (was ${id?.substring(0, 7)}).');
      }
      return out.join('\n');
    }
    final n = names.first;
    _checkName(n);
    if (branches.containsKey(n)) throw _Fail("fatal: a branch named '$n' already exists");
    if (headCommitId == null) throw _Fail("fatal: not a valid object name: '$head'");
    branches[n] = headCommitId;
    return '';
  }

  String _switch(List<String> a, {required String createFlag}) {
    if (isMerging) throw _Fail('error: you need to resolve your current merge first');
    final create = a.contains(createFlag);
    final names = a.where((t) => !t.startsWith('-')).toList();
    if (names.isEmpty) throw _Fail('fatal: missing branch name');
    final n = names.first;
    if (create) {
      _checkName(n);
      if (branches.containsKey(n)) throw _Fail("fatal: a branch named '$n' already exists");
      branches[n] = headCommitId;
      head = n;
      return "Switched to a new branch '$n'";
    }
    if (!branches.containsKey(n)) {
      throw _Fail("fatal: invalid reference: $n");
    }
    if (n == head) return "Already on '$n'";
    _moveTo(branches[n]);
    head = n;
    return "Switched to branch '$n'";
  }

  /// Met à jour index et copie de travail vers [target] en conservant les
  /// modifications locales non concernées ; refuse d'écraser du travail.
  void _moveTo(String? target) {
    final oldTree = headTree;
    final newTree = target == null ? const <String, String>{} : commits[target]!.tree;
    final blocked = <String>[];
    for (final p in {...oldTree.keys, ...newTree.keys}) {
      if (oldTree[p] == newTree[p]) continue;
      final dirty = workTree[p] != oldTree[p] || index[p] != oldTree[p];
      if (dirty) blocked.add(p);
    }
    if (blocked.isNotEmpty) {
      throw _Fail('error: Your local changes to the following files would be overwritten:\n\t'
          '${(blocked..sort()).join('\n\t')}\n'
          'Please commit your changes or stash them before you switch branches.\nAborting');
    }
    for (final p in {...oldTree.keys, ...newTree.keys}) {
      if (oldTree[p] == newTree[p]) continue;
      if (newTree.containsKey(p)) {
        workTree[p] = newTree[p]!;
        index[p] = newTree[p]!;
      } else {
        workTree.remove(p);
        index.remove(p);
      }
    }
  }

  // ------------------------------------------------------------------- merge

  String? mergeBase(String a, String b) {
    final common = ancestors(a).intersection(ancestors(b));
    if (common.isEmpty) return null;
    return common.reduce((x, y) => commits[x]!.seq > commits[y]!.seq ? x : y);
  }

  String _mergeCmd(List<String> a) {
    if (a.contains('--abort')) {
      if (!isMerging) throw _Fail('fatal: There is no merge to abort (MERGE_HEAD missing).');
      index
        ..clear()
        ..addAll(headTree);
      for (final p in workTree.keys.toList()) {
        if (!headTree.containsKey(p) && !untracked.contains(p)) workTree.remove(p);
      }
      workTree.addAll(headTree);
      _merge = null;
      return '';
    }
    if (isMerging) {
      throw _Fail('error: Merging is not possible because you have unmerged files.');
    }
    final names = a.where((t) => !t.startsWith('-')).toList();
    if (names.isEmpty) throw _Fail('fatal: No remote for the current branch.');
    final name = names.first;
    final theirs = _resolve(name) ?? (throw _Fail('merge: $name - not something we can merge'));
    final ours = headCommitId;
    if (ours == null) throw _Fail("fatal: your current branch '$head' does not have any commits yet");
    if (isAncestor(theirs, ours)) return 'Already up to date.';
    final noFf = a.contains('--no-ff');
    if (isAncestor(ours, theirs) && !noFf) {
      final before = headTree;
      _moveTo(theirs);
      branches[head] = theirs;
      final changed = _changes(before, headTree).keys.toList()..sort();
      return 'Updating ${ours.substring(0, 7)}..${theirs.substring(0, 7)}\nFast-forward\n'
          '${changed.map((p) => ' $p').join('\n')}\n'
          ' ${changed.length} file${changed.length == 1 ? '' : 's'} changed';
    }
    if (stagedChanges.isNotEmpty || unstagedChanges.isNotEmpty) {
      throw _Fail('error: Your local changes would be overwritten by merge.\n'
          'Please commit your changes or stash them before you merge.\nAborting');
    }
    final base = mergeBase(ours, theirs);
    final bt = base == null ? const <String, String>{} : commits[base]!.tree;
    final ot = headTree;
    final tt = commits[theirs]!.tree;
    final merged = <String, String>{};
    final conflicts = <String>{};
    final log = <String>[];
    for (final p in {...bt.keys, ...ot.keys, ...tt.keys}) {
      final b = bt[p], o = ot[p], t = tt[p];
      String? result;
      if (o == t || t == b) {
        result = o;
      } else if (o == b) {
        result = t;
      } else {
        conflicts.add(p);
        log.add('Auto-merging $p\nCONFLICT (content): Merge conflict in $p');
        result = '<<<<<<< HEAD\n${o ?? ''}=======\n${t ?? ''}>>>>>>> $name\n';
      }
      if (result != null) merged[p] = result;
    }
    for (final p in {...ot.keys, ...merged.keys}) {
      if (merged.containsKey(p)) {
        workTree[p] = merged[p]!;
        if (!conflicts.contains(p)) index[p] = merged[p]!;
      } else {
        workTree.remove(p);
        index.remove(p);
      }
    }
    _merge = _MergeState(name, theirs, conflicts);
    if (conflicts.isNotEmpty) {
      return '${log.join('\n')}\nAutomatic merge failed; fix conflicts and then commit the result.';
    }
    final msg = _commit(['-m', "Merge branch '$name'"]);
    return "Merge made by the 'ort' strategy.\n${msg.split('\n').last}";
  }

  // --------------------------------------------------------------------- tag

  String _tag(List<String> a) {
    final del = a.contains('-d');
    final annotated = a.contains('-a');
    final msg = _after(a, '-m');
    final names = <String>[];
    for (var i = 0; i < a.length; i++) {
      if (a[i] == '-m') {
        i++;
        continue;
      }
      if (!a[i].startsWith('-')) names.add(a[i]);
    }
    if (names.isEmpty) return (tags.keys.toList()..sort()).join('\n');
    final n = names.first;
    if (del) {
      final id = tags.remove(n) ?? (throw _Fail("error: tag '$n' not found."));
      tagMessages.remove(n);
      return "Deleted tag '$n' (was ${id.substring(0, 7)})";
    }
    _checkName(n);
    if (tags.containsKey(n)) throw _Fail("fatal: tag '$n' already exists");
    if (annotated && msg == null) {
      throw _Fail('Le simulateur n\'ouvre pas d\'éditeur : utilisez git tag -a $n -m "message".');
    }
    final target = names.length > 1 ? _resolve(names[1]) : headCommitId;
    if (target == null) throw _Fail("fatal: Failed to resolve 'HEAD' as a valid ref.");
    tags[n] = target;
    if (msg != null) tagMessages[n] = msg;
    return '';
  }
}
