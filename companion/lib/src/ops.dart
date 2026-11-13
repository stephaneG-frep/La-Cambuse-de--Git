import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'backups.dart';
import 'paths.dart';
import 'project_audit.dart';
import 'store.dart';

class OpValidationError implements Exception {
  OpValidationError(this.code, this.message);
  final String code;
  final String message;
}

/// Commande préparée : arguments typés pour `git` (jamais de shell) ou
/// calcul interne en Dart.
class PreparedOp {
  PreparedOp({
    required this.type,
    required this.root,
    required this.plan,
    this.gitArgs,
    this.internal,
    this.before,
    this.timeout = const Duration(seconds: 30),
  });

  /// Étape exécutée juste avant la commande (sauvegarde automatique,
  /// re-vérification des secrets). Peut lever une [OpValidationError].
  final Future<Map<String, dynamic>?> Function()? before;

  final OpType type;
  final String? root;
  final List<String> plan;
  final List<String>? gitArgs;
  final Future<Map<String, dynamic>> Function()? internal;
  final Duration timeout;
}

class OpRecord {
  OpRecord(this.id, this.deviceId, this.prepared)
      : state = prepared.type.mutating ? OpState.awaitingApproval : OpState.queued;

  final String id;
  final String deviceId;
  final PreparedOp prepared;
  OpState state;
  int? exitCode;
  String stdout = '';
  String stderr = '';
  String? error;
  Map<String, dynamic>? result;
  Process? process;
  bool cancelRequested = false;
  final created = DateTime.now();

  OpStatus toStatus() => OpStatus(
        id: id,
        type: prepared.type.code,
        state: state,
        plan: prepared.plan,
        root: prepared.root,
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        error: error,
        result: result,
      );
}

/// Options `-c` appliquées à chaque appel : neutralisent les mécanismes par
/// lesquels un dépôt piégé pourrait faire exécuter du code à Git.
const hardenedGitConfig = [
  '-c', 'core.hooksPath=/dev/null',
  '-c', 'core.fsmonitor=false',
  '-c', 'core.pager=cat',
  '-c', 'core.sshCommand=false',
  '-c', 'protocol.ext.allow=never',
  '-c', 'color.ui=false',
];

/// Motifs de `.git/config` qui déclarent des commandes exécutables. Leur
/// présence bloque les opérations mutantes (refus explicite, pas de contournement).
final _dangerousConfig = RegExp(
  r'^\s*(\[filter\b|\[diff\s+"|\[merge\s+"|fsmonitor\s*=|hookspath\s*=|sshcommand\s*=|textconv\s*=|\[credential\b|askpass\s*=|editor\s*=|pager\s*=|\[alias\b)',
  caseSensitive: false,
  multiLine: true,
);

class OpRunner {
  OpRunner(
    this.guard, {
    this.maxOutputBytes = 1 << 20,
    this.gitExecutable = 'git',
    this.opTimeout = const Duration(seconds: 30),
    this.backups,
  });

  /// Sauvegardes (absentes = opérations de sauvegarde indisponibles).
  final BackupManager? backups;

  /// Délai maximal d'une commande git.
  final Duration opTimeout;

  final RootGuard guard;
  final int maxOutputBytes;
  final String gitExecutable;
  final _ops = <String, OpRecord>{};
  Future<void> _queue = Future.value();

  OpRecord? get(String id) => _ops[id];

  // ------------------------------------------------------------ Préparation

  PreparedOp prepare(OpRequest req) {
    final type = OpType.fromCode(req.type) ??
        (throw OpValidationError(ErrorCodes.unknownOp, 'Opération inconnue : ${req.type}'));
    if (type == OpType.systemInfo) {
      return PreparedOp(type: type, root: null, plan: ['Lire les informations du compagnon'], internal: _systemInfo);
    }
    final root = guard.resolveProject(req.root);
    final p = req.params;
    switch (type) {
      case OpType.projectList:
        return PreparedOp(type: type, root: root, plan: ['Lister (lecture seule) les dossiers de $root'],
            internal: () async => listProjects(root));
      case OpType.projectDetect:
        return PreparedOp(type: type, root: root, plan: ['Analyser (lecture seule) $root'],
            internal: () async => detectProject(root));
      case OpType.gitStatus:
        return _git(type, root, ['status', '--porcelain=v1', '--branch', '--untracked-files=all']);
      case OpType.gitLog:
        final n = (p['limit'] as int? ?? 20).clamp(1, 200);
        return _git(type, root, ['log', '--oneline', '--decorate', '--no-color', '-n', '$n']);
      case OpType.gitDiff:
        final args = ['diff', '--no-ext-diff', '--no-textconv', '--no-color'];
        if (p['staged'] == true) args.add('--staged');
        final path = p['path'] as String?;
        if (path != null) args.addAll(['--', RootGuard.resolveInProject(root, path)]);
        return _git(type, root, args);
      case OpType.gitInit:
        if (FileSystemEntity.typeSync('$root/.git', followLinks: false) != FileSystemEntityType.notFound) {
          throw OpValidationError(ErrorCodes.conflict,
              'Un dépôt Git existe déjà ici : il ne sera pas réinitialisé ni écrasé.');
        }
        final branch = p['initialBranch'] as String? ?? 'main';
        if (!RegExp(r'^[A-Za-z0-9._/-]{1,100}$').hasMatch(branch) || branch.contains('..')) {
          throw OpValidationError(ErrorCodes.invalidRequest, 'Nom de branche invalide.');
        }
        return _git(type, root, ['init', '--initial-branch=$branch']);
      case OpType.gitAdd:
        _checkRepoConfig(root);
        final paths = (p['paths'] as List?)?.cast<String>() ?? const [];
        if (paths.isEmpty || paths.length > 500) {
          throw OpValidationError(ErrorCodes.invalidRequest, 'Indiquez entre 1 et 500 fichiers explicites.');
        }
        if (paths.any((x) =>
            x.contains('*') ||
            x.split('/').every((s) => s == '.' || s.isEmpty) ||
            FileSystemEntity.isDirectorySync('$root/$x'))) {
          throw OpValidationError(ErrorCodes.invalidRequest,
              'Ajout global ou de dossier refusé : listez les fichiers un par un (protection contre l\'ajout de secrets).');
        }
        final files = [for (final x in paths) RootGuard.resolveInProject(root, x)];
        _blockSecrets(_scanWorktree(root, files));
        final op = _git(type, root, ['add', '--', ...files]);
        return PreparedOp(type: type, root: root, gitArgs: op.gitArgs, plan: op.plan, timeout: opTimeout,
            before: () async {
              _blockSecrets(_scanWorktree(root, files));
              return null;
            });
      case OpType.gitCommit:
        _checkRepoConfig(root);
        final msg = (p['message'] as String? ?? '').trim();
        if (msg.isEmpty || msg.length > 5000 || msg.contains('\u0000')) {
          throw OpValidationError(ErrorCodes.invalidRequest, 'Message de commit vide ou invalide.');
        }
        final op = _git(type, root, ['commit', '--no-verify', '-m', msg]);
        return PreparedOp(
          type: type,
          root: root,
          gitArgs: op.gitArgs,
          timeout: opTimeout,
          plan: [...op.plan, 'Contenu indexé analysé : commit bloqué si un secret est détecté.'],
          before: () async {
            _blockSecrets(await _scanStaged(root));
            return null;
          },
        );
      case OpType.projectAudit:
        return PreparedOp(
          type: type,
          root: root,
          plan: ['Audit en lecture seule de $root (aucune écriture)'],
          timeout: const Duration(minutes: 2),
          internal: () => auditProject(root, git: (a) => gitRead(root, a)),
        );
      case OpType.gitBranches:
        return _git(type, root, ['branch', '--list', '--no-color', '--format=%(HEAD)|%(refname:short)|%(objectname:short)|%(subject)']);
      case OpType.backupList:
        final b = _requireBackups();
        return PreparedOp(type: type, root: root, plan: ['Lister les sauvegardes de $root'],
            internal: () async => {'backups': b.list(project: root)});
      case OpType.projectBackup:
        final b = _requireBackups();
        return PreparedOp(
          type: type,
          root: root,
          plan: ['Archiver $root (dossiers générés exclus, .git inclus) dans le dossier privé du compagnon', 'Le projet n\'est pas modifié.'],
          timeout: const Duration(minutes: 5),
          internal: () => b.backupProject(root),
        );
      case OpType.gitBranchCreate:
        _requireRepo(root);
        final name = _branchName(p['name']);
        return _git(type, root, ['branch', name]);
      case OpType.gitSwitch:
        _requireRepo(root);
        _checkRepoConfig(root);
        final name = _branchName(p['name']);
        return _git(type, root, ['switch', name]);
      case OpType.gitRestore:
        _requireRepo(root);
        _checkRepoConfig(root);
        final paths = _explicitFiles(root, p['paths']);
        if (p['staged'] == true) {
          return _git(type, root, ['restore', '--staged', '--', ...paths]);
        }
        final b = _requireBackups();
        final op = _git(type, root, ['restore', '--', ...paths]);
        return PreparedOp(
          type: type,
          root: root,
          gitArgs: op.gitArgs,
          timeout: opTimeout,
          plan: [
            ...op.plan,
            'Écrase les modifications locales de ${paths.length} fichier(s).',
            'Sauvegarde automatique de ces fichiers avant écrasement (restaurable).',
          ],
          before: () async => {'backup': b.backupFiles(root, paths, reason: 'Avant git restore')},
        );
      case OpType.gitignoreUpdate:
        final lines = ((p['lines'] as List?) ?? const []).map((e) => '$e'.trim()).toList();
        if (lines.isEmpty || lines.length > 100 ||
            lines.any((l) => l.isEmpty || l.length > 200 || l.contains('\n') || l.contains('\u0000'))) {
          throw OpValidationError(ErrorCodes.invalidRequest, 'Lignes .gitignore invalides.');
        }
        RootGuard.resolveInProject(root, '.gitignore');
        final file = File('$root/.gitignore');
        final current = file.existsSync() ? file.readAsStringSync() : '';
        final present = current.split('\n').map((l) => l.trim()).toSet();
        final add = [for (final l in lines.toSet()) if (!present.contains(l)) l];
        if (add.isEmpty) {
          throw OpValidationError(ErrorCodes.conflict, 'Toutes ces lignes sont déjà dans le .gitignore.');
        }
        return PreparedOp(
          type: type,
          root: root,
          plan: [
            'Fichier : $root/.gitignore${file.existsSync() ? '' : ' (création)'}',
            'Lignes ajoutées :',
            for (final l in add) '+ $l',
            'Modifie le projet : approbation requise.',
          ],
          internal: () async {
            final base = file.existsSync() ? file.readAsStringSync() : '';
            final sep = base.isEmpty || base.endsWith('\n') ? '' : '\n';
            final tmp = File('$root/.gitignore.cambuse-tmp');
            tmp.writeAsStringSync('$base$sep${add.join('\n')}\n', flush: true);
            tmp.renameSync(file.path);
            return {'added': add};
          },
        );
      case OpType.backupRestore:
        final b = _requireBackups();
        final id = '${p['id'] ?? ''}';
        final Map<String, dynamic> meta;
        try {
          meta = b.get(id);
        } on ArgumentError catch (e) {
          throw OpValidationError(ErrorCodes.notFound, '${e.message}');
        }
        if (meta['project'] != root) {
          throw OpValidationError(ErrorCodes.invalidRequest, 'Cette sauvegarde appartient à un autre projet.');
        }
        final parent = File(root).parent.path;
        if (!guard.roots.any((r) => parent == r || parent.startsWith('$r/'))) {
          throw OpValidationError(ErrorCodes.pathOutsideRoot,
              'La restauration créerait un dossier hors des dossiers autorisés ($parent).');
        }
        return PreparedOp(
          type: type,
          root: root,
          timeout: const Duration(minutes: 5),
          plan: [
            'Sauvegarde : $id (${meta['kind']}, ${meta['createdAt']})',
            'Restauration dans un NOUVEAU dossier à côté de $root : rien n\'est écrasé.',
            'Crée des fichiers : approbation requise.',
          ],
          internal: () async => {'restoredTo': await b.restoreToNewFolder(id)},
        );
      case OpType.systemInfo:
        throw StateError('inatteignable');
    }
  }

  PreparedOp _git(OpType type, String root, List<String> args) => PreparedOp(
        type: type,
        root: root,
        gitArgs: args,
        timeout: opTimeout,
        plan: [
          'Dossier : $root',
          'Commande exacte : git ${args.map(_quote).join(' ')}',
          if (type.mutating) 'Modifie le dépôt : approbation requise.' else 'Lecture seule.',
        ],
      );

  static String _quote(String a) =>
      RegExp(r'^[A-Za-z0-9._/=:@,+-]+$').hasMatch(a) ? a : "'${a.replaceAll("'", r"'\''")}'";


  BackupManager _requireBackups() =>
      backups ?? (throw OpValidationError(ErrorCodes.invalidRequest, 'Sauvegardes indisponibles sur ce compagnon.'));

  void _requireRepo(String root) {
    if (FileSystemEntity.typeSync('$root/.git', followLinks: false) == FileSystemEntityType.notFound) {
      throw OpValidationError(ErrorCodes.conflict, 'Ce dossier n\'est pas un dépôt Git.');
    }
  }

  static String _branchName(Object? raw) {
    final n = '${raw ?? ''}'.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}$').hasMatch(n) ||
        n.contains('..') || n.contains('//') || n.endsWith('/') || n.endsWith('.') || n.endsWith('.lock')) {
      throw OpValidationError(ErrorCodes.invalidRequest, 'Nom de branche invalide : « $n ».');
    }
    return n;
  }

  static List<String> _explicitFiles(String root, Object? raw) {
    final paths = ((raw as List?) ?? const []).map((e) => '$e').toList();
    if (paths.isEmpty || paths.length > 500) {
      throw OpValidationError(ErrorCodes.invalidRequest, 'Indiquez entre 1 et 500 fichiers explicites.');
    }
    if (paths.any((x) => x.contains('*') || x.split('/').every((s) => s == '.' || s.isEmpty) ||
        FileSystemEntity.isDirectorySync('$root/$x'))) {
      throw OpValidationError(ErrorCodes.invalidRequest, 'Listez les fichiers un par un (pas de dossier ni de motif).');
    }
    return [for (final x in paths) RootGuard.resolveInProject(root, x)];
  }

  static void _blockSecrets(List<SecretFinding> found) {
    if (found.isEmpty) return;
    final lines = found.take(10).map((f) => '${f.file}${f.line == null ? '' : ':${f.line}'} — ${f.kind}').join('\n');
    throw OpValidationError(ErrorCodes.secretDetected,
        'Secret probable détecté : opération bloquée.\n$lines\n'
        'Retirez-le (et révoquez-le s\'il a fuité), ou ignorez le fichier via .gitignore.');
  }

  static List<SecretFinding> _scanWorktree(String root, List<String> files) {
    final out = <SecretFinding>[];
    for (final f in files) {
      final kind = sensitiveFileKind(f);
      if (kind != null) out.add(SecretFinding(f, kind));
      final file = File('$root/$f');
      if (!file.existsSync() || file.lengthSync() > 1024 * 1024) continue;
      final raw = file.readAsBytesSync();
      if (!looksBinary(raw)) out.addAll(scanContent(f, utf8.decode(raw, allowMalformed: true), maxFindings: 3));
    }
    return out;
  }

  Future<List<SecretFinding>> _scanStaged(String root) async {
    final names = await gitRead(root, ['diff', '--cached', '--name-only', '-z', '--no-renames', '--diff-filter=ACM']);
    final out = <SecretFinding>[];
    for (final f in (names.stdout as String).split('\u0000').where((x) => x.isNotEmpty)) {
      final kind = sensitiveFileKind(f);
      if (kind != null) out.add(SecretFinding(f, kind));
      final blob = await gitRead(root, ['cat-file', 'blob', ':$f'], binary: true);
      if (blob.exitCode != 0) continue;
      final bytes = blob.stdout as List<int>;
      if (bytes.length > 1024 * 1024 || looksBinary(bytes)) continue;
      out.addAll(scanContent(f, utf8.decode(bytes, allowMalformed: true), maxFindings: 3));
    }
    return out;
  }

  Map<String, String> get _gitEnv => {
        'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
        'HOME': Platform.environment['HOME'] ?? '/tmp',
        'LANG': 'C.UTF-8',
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_PAGER': 'cat',
        'GIT_EDITOR': 'true',
        'GIT_ASKPASS': 'true',
        'GIT_OPTIONAL_LOCKS': '0',
      };

  /// Appel git en lecture (audit, contrôles), même durcissement que les opérations.
  Future<ProcessResult> gitRead(String root, List<String> args, {bool binary = false}) => Process.run(
        gitExecutable,
        [...hardenedGitConfig, ...args],
        workingDirectory: root,
        includeParentEnvironment: false,
        environment: _gitEnv,
        stdoutEncoding: binary ? null : utf8,
      ).timeout(opTimeout);

  void _checkRepoConfig(String root) {
    final cfg = File('$root/.git/config');
    if (cfg.existsSync() && _dangerousConfig.hasMatch(cfg.readAsStringSync())) {
      throw OpValidationError(ErrorCodes.conflict,
          'La configuration de ce dépôt (.git/config) déclare des commandes exécutables '
          '(filtres, hooks, pagers, alias…). Opération refusée par sécurité.');
    }
  }

  Future<Map<String, dynamic>> _systemInfo() async {
    String? gitVersion;
    try {
      final r = await Process.run(gitExecutable, ['--version']);
      gitVersion = (r.stdout as String).trim();
    } catch (_) {}
    return {
      'apiVersion': apiVersion,
      'roots': guard.roots,
      'git': gitVersion,
      'os': Platform.operatingSystemVersion,
      'ops': [for (final t in OpType.values) {'type': t.code, 'scope': t.scope.code, 'mutating': t.mutating}],
    };
  }

  // -------------------------------------------------------------- Cycle de vie

  OpRecord submit(String deviceId, PreparedOp prepared) {
    final rec = OpRecord(randomToken(9), deviceId, prepared);
    _ops[rec.id] = rec;
    _prune();
    if (rec.state == OpState.queued) _enqueue(rec);
    return rec;
  }

  void approve(OpRecord rec) {
    if (rec.state != OpState.awaitingApproval) {
      throw OpValidationError(ErrorCodes.conflict, 'Opération non en attente d\'approbation.');
    }
    rec.state = OpState.queued;
    _enqueue(rec);
  }

  void reject(OpRecord rec) {
    if (rec.state != OpState.awaitingApproval) {
      throw OpValidationError(ErrorCodes.conflict, 'Opération non en attente d\'approbation.');
    }
    rec.state = OpState.rejected;
  }

  void cancel(OpRecord rec) {
    if (rec.state.isFinal) return;
    rec.cancelRequested = true;
    if (rec.state == OpState.awaitingApproval || rec.state == OpState.queued) {
      rec.state = OpState.cancelled;
    } else {
      rec.process?.kill(ProcessSignal.sigkill);
    }
  }

  /// Exécution séquentielle (une opération à la fois).
  void _enqueue(OpRecord rec) {
    _queue = _queue.then((_) => _run(rec)).catchError((Object _) {});
  }

  /// Attend la fin de toutes les opérations en file (utile aux tests).
  Future<void> idle() => _queue;

  Future<void> _run(OpRecord rec) async {
    if (rec.state != OpState.queued) return;
    rec.state = OpState.running;
    final p = rec.prepared;
    try {
      if (p.before != null) {
        final extra = await p.before!();
        if (extra != null) rec.result = {...?rec.result, ...extra};
      }
      if (p.internal != null) {
        rec.result = {...?rec.result, ...await p.internal!().timeout(p.timeout)};
        rec.state = OpState.succeeded;
        return;
      }
      final proc = await Process.start(
        gitExecutable,
        [...hardenedGitConfig, ...p.gitArgs!],
        workingDirectory: p.root,
        includeParentEnvironment: false,
        environment: _gitEnv,
      );
      rec.process = proc;
      final out = _collect(proc.stdout);
      final err = _collect(proc.stderr);
      final code = await proc.exitCode.timeout(p.timeout, onTimeout: () {
        proc.kill(ProcessSignal.sigkill);
        return -999;
      });
      rec.stdout = await out;
      rec.stderr = await err;
      rec.exitCode = code == -999 ? null : code;
      if (code == -999) {
        rec.state = OpState.timedOut;
        rec.error = 'Délai dépassé (${p.timeout.inSeconds} s) : processus arrêté.';
      } else if (rec.cancelRequested) {
        rec.state = OpState.cancelled;
      } else {
        rec.state = code == 0 ? OpState.succeeded : OpState.failed;
      }
    } on OpValidationError catch (e) {
      rec.state = OpState.failed;
      rec.error = e.message;
    } on ProcessException catch (e) {
      rec.state = OpState.failed;
      rec.error = 'Impossible de lancer git : ${e.message}';
    } on TimeoutException {
      rec.state = OpState.timedOut;
      rec.error = 'Délai dépassé.';
    } catch (e) {
      rec.state = OpState.failed;
      rec.error = '$e';
    } finally {
      rec.process = null;
    }
  }

  Future<String> _collect(Stream<List<int>> s) async {
    final b = BytesBuilder(copy: false);
    var truncated = false;
    await for (final chunk in s) {
      final room = maxOutputBytes - b.length;
      if (room <= 0) {
        truncated = true;
        continue;
      }
      b.add(chunk.length > room ? chunk.sublist(0, room) : chunk);
    }
    final text = utf8.decode(b.takeBytes(), allowMalformed: true);
    return truncated ? '$text\n[sortie tronquée à $maxOutputBytes octets]' : text;
  }

  void _prune() {
    if (_ops.length <= 200) return;
    final finals = _ops.values.where((o) => o.state.isFinal).toList()
      ..sort((a, b) => a.created.compareTo(b.created));
    for (final o in finals.take(_ops.length - 200)) {
      _ops.remove(o.id);
    }
  }
}

/// Détection non destructive (lecture du premier niveau et de quelques fichiers).
Map<String, dynamic> detectProject(String root) {
  bool has(String p) => FileSystemEntity.typeSync('$root/$p', followLinks: false) != FileSystemEntityType.notFound;
  final kinds = <String>[];
  if (has('pubspec.yaml')) {
    final pub = File('$root/pubspec.yaml').readAsStringSync();
    kinds.add(RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(pub) ? 'flutter' : 'dart');
  }
  if (has('package.json')) kinds.add('node');
  if (has('pyproject.toml') || has('requirements.txt')) kinds.add('python');
  if (has('go.mod')) kinds.add('go');
  if (has('Cargo.toml')) kinds.add('rust');
  if (has('pom.xml') || has('build.gradle') || has('build.gradle.kts')) kinds.add('jvm');
  if (has('Dockerfile') || has('compose.yaml') || has('docker-compose.yml')) kinds.add('docker');
  return {
    'kinds': kinds,
    'git': has('.git'),
    'platforms': [for (final p in ['android', 'linux', 'ios', 'web', 'windows', 'macos']) if (has(p)) p],
    'ci': [if (has('.github/workflows')) 'github-actions', if (has('.gitlab-ci.yml')) 'gitlab-ci'],
    'gitignore': has('.gitignore'),
  };
}

/// Sous-dossiers directs (les liens symboliques sont ignorés : pas d'évasion).
Map<String, dynamic> listProjects(String root) {
  final entries = Directory(root)
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((d) => !d.path.split('/').last.startsWith('.'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return {
    'projects': [
      for (final d in entries.take(200))
        {
          'name': d.path.split('/').last,
          'path': d.path,
          'git': FileSystemEntity.typeSync('${d.path}/.git', followLinks: false) != FileSystemEntityType.notFound,
        },
    ],
    'truncated': entries.length > 200,
  };
}
