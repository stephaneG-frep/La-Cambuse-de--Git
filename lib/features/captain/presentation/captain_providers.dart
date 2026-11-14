import 'dart:async';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../ai/data/chat_service.dart';
import '../../ai/data/secret_store.dart';
import '../../ai/domain/ai_config.dart';
import '../../ai/domain/ai_models.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../forge/data/forge_client.dart';
import '../../forge/presentation/forge_providers.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../data/captain_repository.dart';
import '../domain/ai_plan.dart';
import '../domain/engine.dart';
import '../domain/mission.dart';
import '../domain/report.dart';

final captainRepositoryProvider = Provider((ref) => CaptainRepository(ref.watch(databaseProvider)));

final captainRunsProvider = StreamProvider<List<CaptainRunRow>>((ref) => ref.watch(captainRepositoryProvider).watchRuns());

final captainEventsProvider =
    StreamProvider.family<List<CaptainEventRow>, String>((ref, id) => ref.watch(captainRepositoryProvider).watchEvents(id));

/// Accès réel au compagnon et au coffre des jetons de forge.
class CompanionCaptainBackend implements CaptainBackend {
  CompanionCaptainBackend(this._client, this._secrets);
  final CompanionClient _client;
  final SecretStore _secrets;

  @override
  Future<OpStatus> submit(OpRequest req) => _client.submit(req);
  @override
  Future<OpStatus> status(String id) => _client.status(id);
  @override
  Future<OpStatus> approve(String id) => _client.approve(id);
  @override
  Future<OpStatus> reject(String id) => _client.reject(id);
  @override
  Future<OpStatus> cancel(String id) => _client.cancel(id);
  @override
  Future<String?> forgeToken(ForgeKind kind) => _secrets.read(forgeTokenKey(kind));
}

final captainBackendProvider = Provider<CaptainBackend>(
    (ref) => CompanionCaptainBackend(ref.watch(companionClientProvider), ref.watch(secretStoreProvider)));

enum DecisionKind { approval, review, consent }

/// Décision humaine attendue par le moteur, affichée dans la table de navigation.
class PendingDecision {
  PendingDecision(this.kind, this.step, {this.companionPlan = const [], this.preview = '', this.params = const {}});
  final DecisionKind kind;
  final StepSpec step;
  final List<String> companionPlan;
  final String preview;
  final Map<String, dynamic> params;
  final _done = Completer<bool>();
  Future<bool> get future => _done.future;
  void answer(bool ok) {
    if (!_done.isCompleted) _done.complete(ok);
  }
}

class CaptainUi {
  const CaptainUi({this.run, this.pending, this.draft, this.version = 0});
  final RunSnapshot? run;
  final PendingDecision? pending;

  /// Plan en préparation (mission prédéfinie ou proposition IA validée).
  final MissionPlan? draft;
  final int version;

  bool get busy => run != null && !run!.state.isFinal && run!.state != RunState.interrompu;

  CaptainUi copy({RunSnapshot? run, PendingDecision? pending, bool clearPending = false, MissionPlan? draft, bool clearDraft = false}) =>
      CaptainUi(
        run: run ?? this.run,
        pending: clearPending ? null : (pending ?? this.pending),
        draft: clearDraft ? null : (draft ?? this.draft),
        version: version + 1,
      );
}

/// Résultat d'une demande de plan au professeur IA.
class AiProposal {
  const AiProposal(this.result, {this.usage, this.cost, this.model});
  final AiPlanResult result;
  final AiUsage? usage;
  final double? cost;
  final String? model;
}

class CaptainController extends Notifier<CaptainUi> implements CaptainPilot {
  CaptainEngine? _engine;
  StreamSubscription<RunSnapshot>? _sub;

  @override
  CaptainUi build() {
    ref.onDispose(() => _sub?.cancel());
    return const CaptainUi();
  }

  CaptainEngine? get engine => _engine;

  void setDraft(MissionPlan plan) => state = state.copy(draft: plan);

  /// Lance une mission approuvée par l'utilisateur. Retourne l'identifiant.
  Future<String> launch(MissionPlan plan, String projectPath) async {
    if (state.busy) throw StateError('Une mission est déjà en cours : terminez-la ou arrêtez-la d\'abord.');
    final run = RunSnapshot(
        id: 'mission-${DateTime.now().millisecondsSinceEpoch}', plan: plan, projectPath: projectPath, createdAt: DateTime.now());
    await ref.read(logbookRepositoryProvider).record(
        category: 'capitaine', action: 'Mission approuvée', details: '${plan.title} — $projectPath (${plan.steps.length} étapes)');
    await _drive(run);
    return run.id;
  }

  /// Reprend une mission en pause, interrompue ou relue après redémarrage.
  Future<void> resumeRun(String id) async {
    if (_engine != null && state.run?.id == id && state.run?.state == RunState.enPause) {
      await _engine!.resume();
      return;
    }
    if (state.busy) throw StateError('Une autre mission est en cours.');
    final run = await ref.read(captainRepositoryProvider).load(id);
    if (run == null || run.state.isFinal) return;
    await _drive(run);
  }

  Future<void> _drive(RunSnapshot run) async {
    await _sub?.cancel();
    final engine = CaptainEngine(run: run, backend: ref.read(captainBackendProvider), pilot: this, store: ref.read(captainRepositoryProvider));
    _engine = engine;
    _sub = engine.changes.listen((r) => state = state.copy(run: r));
    state = state.copy(run: run, clearPending: true);
    unawaited(engine.start().then(_finished, onError: (Object e, StackTrace _) async {
      // Erreur inattendue : la mission est marquée interrompue (reprise possible), jamais figée en silence.
      run
        ..state = RunState.interrompu
        ..reason = 'Erreur interne : $e';
      try {
        await ref.read(captainRepositoryProvider).save(run);
      } catch (_) {}
      await _finished(run);
    }));
  }

  Future<void> _finished(RunSnapshot run) async {
    final repo = ref.read(captainRepositoryProvider);
    final report = buildReport(run, await repo.events(run.id));
    await repo.saveReport(run.id, report);
    await ref.read(logbookRepositoryProvider).record(
          category: 'capitaine',
          action: 'Mission ${run.state.label.toLowerCase()}',
          details: '${run.plan.title} — ${run.projectPath}${run.reason == null ? '' : ' : ${run.reason}'}',
          outcome: switch (run.state) {
            RunState.termine => AuditOutcome.success,
            RunState.echoue => AuditOutcome.failure,
            _ => AuditOutcome.cancelled,
          },
        );
    state = state.copy(run: run, clearPending: true);
  }

  Future<void> pause() async => _engine?.requestPause();
  Future<void> resume() async => _engine?.resume();

  Future<void> emergencyStop() async {
    state.pending?.answer(false);
    await _engine?.emergencyStop();
  }

  Future<bool> _ask(PendingDecision d) async {
    state = state.copy(pending: d);
    final ok = await d.future;
    state = state.copy(clearPending: true);
    return ok;
  }

  @override
  Future<bool> approveOp(StepSpec step, OpStatus pending) =>
      _ask(PendingDecision(DecisionKind.approval, step, companionPlan: pending.plan));

  @override
  Future<bool> review(StepSpec step, String preview) => _ask(PendingDecision(DecisionKind.review, step, preview: preview));

  @override
  Future<bool> specificConsent(StepSpec step, Map<String, dynamic> params) =>
      _ask(PendingDecision(DecisionKind.consent, step, params: params));

  /// Demande un plan au professeur IA (facultatif). La réponse est analysée
  /// strictement ; elle n'est jamais exécutée sans relecture ni approbation.
  Future<AiProposal> proposeWithAi(String goal, String projectPath) async {
    final config = await ref.read(aiConfigProvider.future);
    final key = await ref.read(secretStoreProvider).read(secretKeyFor(config.kind));
    if (key == null || key.isEmpty) {
      throw const AiException(AiErrorKind.noKey, 'Aucune clé de professeur IA : configurez-la dans Paramètres → Professeur IA.');
    }
    // Résumé factuel du projet (lecture seule).
    Map<String, dynamic>? detected;
    try {
      final client = ref.read(companionClientProvider);
      detected = (await client.waitFor((await client.submit(OpRequest(type: OpType.projectDetect.code, root: projectPath))).id)).result;
    } catch (_) {}
    final convs = ref.read(conversationRepositoryProvider);
    final id = await convs.create(
        title: 'Capitaine : plan de mission', systemPrompt: captainPlannerPrompt(), kind: config.kind, model: config.model, level: 'intermediaire');
    final chat = ChatService(
      provider: ref.read(aiProviderFactoryProvider)(config),
      conversations: convs,
      logbook: ref.read(logbookRepositoryProvider),
      config: config,
    );
    final outcome = await chat.send(id, plannerRequest(goal, detected), onEvent: (_) {});
    final messages = await convs.messages(id);
    final text = messages.lastWhere((m) => m.role == 'assistant', orElse: () => const AiMessage(role: 'assistant', content: [])).text;
    final result = parseAiPlan(text);
    await ref.read(logbookRepositoryProvider).record(
          category: 'capitaine',
          action: result.ok ? 'Plan IA proposé' : 'Plan IA refusé par la validation',
          details: result.ok ? result.plan!.title : result.errors.take(3).join(' ; '),
          outcome: result.ok ? AuditOutcome.info : AuditOutcome.failure,
        );
    return AiProposal(result,
        usage: outcome.usage,
        model: outcome.model,
        cost: outcome.usage == null ? null : AiConfig.estimateCost(outcome.model ?? config.model, outcome.usage!));
  }
}

final captainControllerProvider = NotifierProvider<CaptainController, CaptainUi>(CaptainController.new);
