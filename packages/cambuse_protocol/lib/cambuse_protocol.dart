/// Contrat d'API v1 entre l'application et le compagnon Linux.
///
/// Ce fichier est la source unique des types d'opérations, des portées et des
/// formats JSON : l'application et le compagnon l'importent tous les deux.
library;

export 'ci_templates.dart';
export 'docker_lint.dart';
export 'docker_templates.dart';
export 'secret_scan.dart';

const apiVersion = 1;
const defaultLoopbackPort = 47820;
const defaultLanPort = 47821;

/// Portées accordées à un appareil lors de l'appairage (décidées sur l'hôte).
enum Scope {
  /// Lecture seule : état, journal, différences, détection de projet.
  read('read'),

  /// Modifications Git locales (init, add, commit, branches).
  gitWrite('git-write'),

  /// Échanges réseau avec un dépôt distant (push, pull). Accordée à part.
  remote('remote'),

  /// Inspection du démon Docker de l'hôte (lecture seule). Accordée à part :
  /// l'accès au socket Docker équivaut à des droits root.
  docker('docker'),

  /// Analyse, tests et builds : exécutent du code du projet. Accordée à part.
  build('build');

  const Scope(this.code);
  final String code;

  static Scope? fromCode(String c) => values.where((s) => s.code == c).firstOrNull;

  static Set<Scope> parseList(String csv) =>
      csv.split(',').map((s) => fromCode(s.trim())).whereType<Scope>().toSet();
}

/// Opérations typées autorisées. Aucune opération « shell libre » n'existe.
enum OpType {
  systemInfo('system.info', Scope.read, mutating: false),
  projectList('project.list', Scope.read, mutating: false),
  projectAudit('project.audit', Scope.read, mutating: false),
  gitBranches('git.branches', Scope.read, mutating: false),
  backupList('backup.list', Scope.read, mutating: false),
  gitRemoteList('git.remote.list', Scope.read, mutating: false),
  gitOutgoing('git.outgoing', Scope.read, mutating: false),
  dockerLint('docker.lint', Scope.read, mutating: false),
  dockerInfo('docker.info', Scope.docker, mutating: false),
  dockerImages('docker.images', Scope.docker, mutating: false),
  dockerContainers('docker.containers', Scope.docker, mutating: false),
  dockerLogs('docker.logs', Scope.docker, mutating: false),
  artifactsList('artifacts.list', Scope.read, mutating: false),
  projectBackup('project.backup', Scope.gitWrite, mutating: false),
  projectDetect('project.detect', Scope.read, mutating: false),
  gitStatus('git.status', Scope.read, mutating: false),
  gitLog('git.log', Scope.read, mutating: false),
  gitDiff('git.diff', Scope.read, mutating: false),
  gitInit('git.init', Scope.gitWrite, mutating: true),
  gitAdd('git.add', Scope.gitWrite, mutating: true),
  gitCommit('git.commit', Scope.gitWrite, mutating: true),
  gitBranchCreate('git.branch.create', Scope.gitWrite, mutating: true),
  gitSwitch('git.switch', Scope.gitWrite, mutating: true),
  gitRestore('git.restore', Scope.gitWrite, mutating: true),
  gitignoreUpdate('gitignore.update', Scope.gitWrite, mutating: true),
  backupRestore('backup.restore', Scope.gitWrite, mutating: true),
  gitRemoteAdd('git.remote.add', Scope.gitWrite, mutating: true),
  gitPush('git.push', Scope.remote, mutating: true),
  gitPull('git.pull', Scope.remote, mutating: true),
  dockerScaffold('docker.scaffold', Scope.gitWrite, mutating: true),
  ciScaffold('ci.scaffold', Scope.gitWrite, mutating: true),
  flutterAnalyze('flutter.analyze', Scope.build, mutating: true),
  flutterTest('flutter.test', Scope.build, mutating: true),
  flutterBuildApkDebug('flutter.build.apk.debug', Scope.build, mutating: true),
  flutterBuildLinux('flutter.build.linux', Scope.build, mutating: true);

  const OpType(this.code, this.scope, {required this.mutating});

  final String code;
  final Scope scope;

  /// Une opération mutante exige une approbation explicite avant exécution.
  final bool mutating;

  static OpType? fromCode(String c) => values.where((t) => t.code == c).firstOrNull;
}

enum OpState {
  awaitingApproval('awaiting_approval'),
  queued('queued'),
  running('running'),
  succeeded('succeeded'),
  failed('failed'),
  rejected('rejected'),
  cancelled('cancelled'),
  timedOut('timed_out');

  const OpState(this.code);
  final String code;

  bool get isFinal => switch (this) {
        succeeded || failed || rejected || cancelled || timedOut => true,
        _ => false,
      };

  static OpState fromCode(String c) =>
      values.firstWhere((s) => s.code == c, orElse: () => failed);
}

/// Codes d'erreur stables de l'API.
abstract final class ErrorCodes {
  static const unauthorized = 'unauthorized';
  static const forbiddenScope = 'forbidden_scope';
  static const invalidCode = 'invalid_pairing_code';
  static const pairingLocked = 'pairing_locked';
  static const pathOutsideRoot = 'path_outside_root';
  static const invalidRequest = 'invalid_request';
  static const unknownOp = 'unknown_operation';
  static const notFound = 'not_found';
  static const conflict = 'conflict';
  static const tooLarge = 'request_too_large';
  static const localOnly = 'local_only';
  static const secretDetected = 'secret_detected';
}

/// Paramètres secrets : transmis pour une seule opération, jamais stockés,
/// renvoyés, journalisés ni affichés dans un plan.
const secretParams = {'token'};

class OpRequest {
  const OpRequest({required this.type, this.root, this.params = const {}});

  factory OpRequest.fromJson(Map<String, dynamic> j) => OpRequest(
        type: j['type'] as String,
        root: j['root'] as String?,
        params: Map<String, dynamic>.of((j['params'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  final String type;
  final String? root;
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() => {
        'type': type,
        if (root != null) 'root': root,
        'params': params,
      };
}

class OpStatus {
  const OpStatus({
    required this.id,
    required this.type,
    required this.state,
    required this.plan,
    this.root,
    this.exitCode,
    this.stdout = '',
    this.stderr = '',
    this.error,
    this.result,
  });

  factory OpStatus.fromJson(Map<String, dynamic> j) => OpStatus(
        id: j['id'] as String,
        type: j['type'] as String,
        state: OpState.fromCode(j['state'] as String),
        plan: (j['plan'] as List).cast<String>(),
        root: j['root'] as String?,
        exitCode: j['exitCode'] as int?,
        stdout: j['stdout'] as String? ?? '',
        stderr: j['stderr'] as String? ?? '',
        error: j['error'] as String?,
        result: (j['result'] as Map?)?.cast<String, dynamic>(),
      );

  final String id;
  final String type;
  final OpState state;

  /// Description lisible de ce qui sera exécuté (commande exacte incluse).
  final List<String> plan;
  final String? root;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final String? error;
  final Map<String, dynamic>? result;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'state': state.code,
        'plan': plan,
        if (root != null) 'root': root,
        if (exitCode != null) 'exitCode': exitCode,
        'stdout': stdout,
        'stderr': stderr,
        if (error != null) 'error': error,
        if (result != null) 'result': result,
      };
}

class PairResult {
  const PairResult({
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresInSeconds,
    required this.scopes,
  });

  factory PairResult.fromJson(Map<String, dynamic> j) => PairResult(
        deviceId: j['deviceId'] as String,
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        accessExpiresInSeconds: j['accessExpiresIn'] as int,
        scopes: Scope.parseList((j['scopes'] as List).join(',')),
      );

  final String deviceId;
  final String accessToken;
  final String refreshToken;
  final int accessExpiresInSeconds;
  final Set<Scope> scopes;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessExpiresIn': accessExpiresInSeconds,
        'scopes': [for (final s in scopes) s.code],
      };
}

/// Enveloppe de réponse : `{ok: true, data: …}` ou `{ok: false, error: {code, message}}`.
Map<String, dynamic> okEnvelope(Object? data) => {'ok': true, 'data': data};

Map<String, dynamic> errorEnvelope(String code, String message) => {
      'ok': false,
      'error': {'code': code, 'message': message},
    };
