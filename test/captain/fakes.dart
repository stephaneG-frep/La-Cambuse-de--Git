import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:la_cambuse/features/captain/domain/engine.dart';
import 'package:la_cambuse/features/forge/data/forge_client.dart';

const token = 'ghp_jetonDeTestTresSecret123456';

/// Faux compagnon programmable : résultats par opération, opérations qui ne
/// finissent jamais, pannes réseau, approbations et annulations tracées.
class FakeBackend implements CaptainBackend {
  FakeBackend({Map<String, Map<String, dynamic>>? results}) : results = results ?? {};

  final Map<String, Map<String, dynamic>> results;
  final submitted = <OpRequest>[];
  final approved = <String>[];
  final rejected = <String>[];
  final cancelled = <String>[];
  final neverFinish = <String>{};
  final networkDown = <String>{};

  /// Nombre de lectures d'état avant qu'une annulation prenne effet.
  int cancelDelayPolls = 0;
  final _ops = <String, (OpRequest, bool)>{}; // id → (requête, approuvée)
  String? storedToken = token;
  var _n = 0;

  OpRequest req(String id) => _ops[id]!.$1;
  List<String> get submittedOps => [for (final r in submitted) r.type];

  @override
  Future<OpStatus> submit(OpRequest r) async {
    submitted.add(r);
    final id = 'op${++_n}';
    final mutating = OpType.fromCode(r.type)!.mutating;
    _ops[id] = (r, !mutating);
    return OpStatus(id: id, type: r.type, state: mutating ? OpState.awaitingApproval : OpState.queued, plan: ['plan ${r.type}']);
  }

  @override
  Future<OpStatus> status(String id) async {
    final (r, ok) = _ops[id] ?? (throw Exception('introuvable'));
    if (networkDown.contains(r.type)) throw Exception('connection refused');
    OpStatus st(OpState s, {Map<String, dynamic>? result, String stdout = '', int? exit, String? error}) =>
        OpStatus(id: id, type: r.type, state: s, plan: const [], result: result, stdout: stdout, exitCode: exit, error: error);
    if (cancelled.contains(id)) {
      if (cancelDelayPolls > 0) {
        cancelDelayPolls--;
        return st(OpState.running);
      }
      return st(OpState.cancelled, exit: -9);
    }
    if (rejected.contains(id)) return st(OpState.rejected);
    if (!ok) return st(OpState.awaitingApproval);
    if (neverFinish.contains(r.type)) return st(OpState.running);
    final c = results[r.type] ?? const {};
    return st(OpState.fromCode((c['state'] as String?) ?? 'succeeded'),
        result: (c['result'] as Map?)?.cast<String, dynamic>(), stdout: (c['stdout'] as String?) ?? '', exit: c['exit'] as int?, error: c['error'] as String?);
  }

  @override
  Future<OpStatus> approve(String id) async {
    approved.add(id);
    _ops[id] = (_ops[id]!.$1, true);
    return status(id);
  }

  @override
  Future<OpStatus> reject(String id) async {
    rejected.add(id);
    return status(id);
  }

  @override
  Future<OpStatus> cancel(String id) async {
    cancelled.add(id);
    return status(id);
  }

  @override
  Future<String?> forgeToken(ForgeKind kind) async => storedToken;
}

/// Projet neuf : pas de dépôt, .gitignore incomplet, deux fichiers à suivre.
Map<String, Map<String, dynamic>> nouveauProjet() => {
      'project.detect': {'result': {'kinds': ['flutter'], 'git': false}},
      'project.audit': {'result': {'gitignoreMissing': ['build/', '.env']}},
      'project.backup': {'result': {'id': 'sauvegarde-42'}},
      'git.status': {'stdout': '## No commits yet on main\n?? lib/main.dart\n?? pubspec.yaml\n'},
      'gitignore.update': {'result': {}},
    };

