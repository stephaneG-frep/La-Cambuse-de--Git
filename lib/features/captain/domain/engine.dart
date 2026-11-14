/// Moteur du Capitaine automatique : exécute une mission étape par étape,
/// sous supervision. Aucune décision humaine n'est contournée : chaque
/// modification passe par l'approbation du compagnon, chaque action externe
/// par un consentement spécifique, et l'arrêt d'urgence annule l'opération en
/// cours. L'état est enregistré après chaque étape (reprise possible).
library;

import 'dart:async';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import '../../forge/data/forge_client.dart';
import 'mission.dart';
import 'missions.dart';

/// État d'une exécution.
enum RunState {
  pret('Prête'),
  enCours('En cours'),
  enPause('En pause'),
  termine('Terminée'),
  echoue('Échouée'),
  arrete('Arrêtée'),
  interrompu('Interrompue');

  const RunState(this.label);
  final String label;

  bool get isFinal => this == termine || this == echoue || this == arrete;
  bool get resumable => this == enPause || this == interrompu || this == pret;
}

/// État d'une étape.
enum MissionStepState {
  aFaire('À faire'),
  enCours('En cours'),
  reussie('Réussie'),
  ignoree('Ignorée'),
  echouee('Échouée'),
  refusee('Refusée'),
  annulee('Annulée'),
  inconnue('État inconnu');

  const MissionStepState(this.label);
  final String label;
}

class StepRecord {
  StepRecord({this.state = MissionStepState.aFaire, this.opId, this.note, this.startedAt, this.endedAt, this.exitCode});

  MissionStepState state;
  String? opId;
  String? note;
  DateTime? startedAt;
  DateTime? endedAt;
  int? exitCode;

  Duration? get duration => startedAt == null || endedAt == null ? null : endedAt!.difference(startedAt!);

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'opId': ?opId,
        'note': ?note,
        'startedAt': ?startedAt?.toIso8601String(),
        'endedAt': ?endedAt?.toIso8601String(),
        'exitCode': ?exitCode,
      };

  factory StepRecord.fromJson(Map<String, dynamic> j) => StepRecord(
        state: MissionStepState.values.firstWhere((s) => s.name == j['state'], orElse: () => MissionStepState.aFaire),
        opId: j['opId'] as String?,
        note: j['note'] as String?,
        startedAt: j['startedAt'] == null ? null : DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt'] as String),
        exitCode: j['exitCode'] as int?,
      );
}

/// Entrée horodatée du journal d'une mission.
class CaptainEvent {
  const CaptainEvent(this.at, this.kind, this.message, {this.step});
  final DateTime at;

  /// info, decision, succes, echec, alerte, arret.
  final String kind;
  final String message;
  final int? step;
}

/// Instantané persistant d'une exécution.
class RunSnapshot {
  RunSnapshot({
    required this.id,
    required this.plan,
    required this.projectPath,
    required this.createdAt,
    List<StepRecord>? steps,
    MissionContext? context,
    this.state = RunState.pret,
    this.checkpointId,
    this.elapsed = Duration.zero,
    this.reason,
  })  : steps = steps ?? [for (final _ in plan.steps) StepRecord()],
        context = context ?? MissionContext();

  final String id;
  final MissionPlan plan;
  final String projectPath;
  final DateTime createdAt;
  final List<StepRecord> steps;
  final MissionContext context;
  RunState state;

  /// Identifiant de la sauvegarde du point de contrôle (compagnon).
  String? checkpointId;

  /// Temps d'exécution cumulé (hors pauses).
  Duration elapsed;

  /// Motif de fin (échec, arrêt, prérequis).
  String? reason;

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan': plan.toJson(),
        'projectPath': projectPath,
        'createdAt': createdAt.toIso8601String(),
        'steps': [for (final s in steps) s.toJson()],
        'context': context.toJson(),
        'state': state.name,
        'checkpointId': ?checkpointId,
        'elapsedMs': elapsed.inMilliseconds,
        'reason': ?reason,
      };

  /// Relit un instantané. Une exécution « en cours » au moment de l'arrêt de
  /// l'application est relue comme interrompue (reprise explicite requise).
  factory RunSnapshot.fromJson(Map<String, dynamic> j) {
    final state = RunState.values.firstWhere((s) => s.name == j['state'], orElse: () => RunState.interrompu);
    return RunSnapshot(
      id: '${j['id']}',
      plan: MissionPlan.fromJson((j['plan'] as Map).cast<String, dynamic>()),
      projectPath: '${j['projectPath']}',
      createdAt: DateTime.parse('${j['createdAt']}'),
      steps: [for (final s in (j['steps'] as List)) StepRecord.fromJson((s as Map).cast<String, dynamic>())],
      context: MissionContext.fromJson((j['context'] as Map?)?.cast<String, dynamic>()),
      state: state == RunState.enCours ? RunState.interrompu : state,
      checkpointId: j['checkpointId'] as String?,
      elapsed: Duration(milliseconds: (j['elapsedMs'] as int?) ?? 0),
      reason: j['reason'] as String?,
    );
  }

  int get nextIndex {
    final i = steps.indexWhere((s) => s.state == MissionStepState.aFaire || s.state == MissionStepState.enCours || s.state == MissionStepState.inconnue);
    return i < 0 ? steps.length : i;
  }

  int get mutationsDone => [
        for (var i = 0; i < steps.length; i++)
          if (steps[i].state == MissionStepState.reussie && plan.steps[i].type.mutating) i,
      ].length;
}

/// Accès au compagnon et au coffre (surchargeable dans les tests).
abstract interface class CaptainBackend {
  Future<OpStatus> submit(OpRequest req);
  Future<OpStatus> status(String id);
  Future<OpStatus> approve(String id);
  Future<OpStatus> reject(String id);
  Future<OpStatus> cancel(String id);
  Future<String?> forgeToken(ForgeKind kind);
}

/// Décisions humaines (interface utilisateur).
abstract interface class CaptainPilot {
  /// Panneau d'approbation du compagnon (commande exacte).
  Future<bool> approveOp(StepSpec step, OpStatus pending);

  /// Consentement spécifique avant une action externe.
  Future<bool> specificConsent(StepSpec step, Map<String, dynamic> params);

  /// Relecture humaine avant une étape : [preview] = état ou diff.
  Future<bool> review(StepSpec step, String preview);
}

/// Persistance de l'exécution et du journal.
abstract interface class CaptainStore {
  Future<void> save(RunSnapshot run);
  Future<void> log(String runId, CaptainEvent event);
}

class CaptainEngine {
  CaptainEngine({
    required this.run,
    required this.backend,
    required this.pilot,
    required this.store,
    DateTime Function()? clock,
    this.pollInterval = const Duration(milliseconds: 400),
    this.cancelConfirmation = const Duration(seconds: 15),
  }) : _now = clock ?? DateTime.now;

  final RunSnapshot run;
  final CaptainBackend backend;
  final CaptainPilot pilot;
  final CaptainStore store;
  final Duration pollInterval;

  /// Attente maximale de la confirmation d'une annulation (arrêt d'urgence).
  final Duration cancelConfirmation;
  final DateTime Function() _now;

  final _changes = StreamController<RunSnapshot>.broadcast();
  Stream<RunSnapshot> get changes => _changes.stream;

  bool _pauseRequested = false;
  bool _stopRequested = false;
  Completer<void>? _resumeSignal;
  String? _inflight;
  bool _running = false;

  bool get pauseRequested => _pauseRequested;
  bool get stopRequested => _stopRequested;

  /// Pause après l'étape en cours (une opération lancée n'est pas coupée).
  Future<void> requestPause() async {
    if (run.state != RunState.enCours || _pauseRequested) return;
    _pauseRequested = true;
    await _log('decision', 'Pause demandée : elle prendra effet à la fin de l\'étape en cours.');
    _emit();
  }

  /// Reprise après une pause.
  Future<void> resume() async {
    if (run.state != RunState.enPause) return;
    _pauseRequested = false;
    await _log('decision', 'Reprise demandée.');
    _resumeSignal?.complete();
  }

  /// Arrêt d'urgence : annule l'opération en cours sur le compagnon et
  /// n'exécute plus aucune étape.
  Future<void> emergencyStop() async {
    if (run.state.isFinal || _stopRequested) return;
    _stopRequested = true;
    await _log('arret', 'ARRÊT D\'URGENCE demandé.');
    final id = _inflight;
    if (id != null) {
      try {
        await backend.cancel(id);
        await _log('arret', 'Annulation de l\'opération en cours envoyée au compagnon.');
      } catch (e) {
        await _log('alerte', 'Annulation non confirmée par le compagnon : $e');
      }
    }
    if (!_running) {
      // Mission en pause ou interrompue : l'arrêt est immédiat.
      await _finish(RunState.arrete, 'Arrêt d\'urgence.');
    }
    _resumeSignal?.complete();
    _emit();
  }

  /// Exécute (ou reprend) la mission jusqu'à sa fin, sa pause ou son arrêt.
  Future<RunSnapshot> start() async {
    if (_running || run.state.isFinal) return run;
    // La mission existe en stockage avant toute entrée de journal.
    await store.save(run);
    final errors = validatePlan(run.plan);
    if (errors.isNotEmpty) {
      await _log('echec', 'Plan refusé : ${errors.join(' ; ')}');
      return _finish(RunState.echoue, 'Plan invalide.');
    }
    _running = true;
    final resuming = run.state != RunState.pret;
    run.state = RunState.enCours;
    run.reason = null;
    await _log('info', resuming ? 'Reprise de la mission « ${run.plan.title} ».' : 'Mission « ${run.plan.title} » démarrée sur ${run.projectPath}.');
    var tick = _now();
    void account() {
      final n = _now();
      run.elapsed += n.difference(tick);
      tick = n;
    }

    try {
      for (var i = run.nextIndex; i < run.plan.steps.length; i++) {
        if (_stopRequested) return await _finish(RunState.arrete, 'Arrêt d\'urgence.');
        if (_pauseRequested) {
          account();
          run.state = RunState.enPause;
          await _log('decision', 'Mission en pause avant l\'étape ${i + 1}.', step: i);
          await _save();
          _resumeSignal = Completer<void>();
          await _resumeSignal!.future;
          _resumeSignal = null;
          tick = _now();
          if (_stopRequested) return await _finish(RunState.arrete, 'Arrêt d\'urgence pendant la pause.');
          run.state = RunState.enCours;
          _emit();
        }
        account();
        if (run.elapsed > run.plan.limits.maxDuration) {
          return await _finish(RunState.echoue, 'Limite de durée atteinte (${run.plan.limits.maxDuration.inMinutes} min).');
        }
        final step = run.plan.steps[i];
        if (step.type.mutating && run.mutationsDone >= run.plan.limits.maxMutations) {
          return await _finish(RunState.echoue, 'Limite de modifications atteinte (${run.plan.limits.maxMutations}).');
        }
        final outcome = await _runStep(i);
        account();
        await _save();
        if (outcome != null) return await _finish(outcome.$1, outcome.$2);
      }
      return await _finish(RunState.termine, null);
    } finally {
      _running = false;
      _inflight = null;
    }
  }

  /// Exécute une étape. Retourne null pour continuer, sinon l'état final.
  Future<(RunState, String)?> _runStep(int i) async {
    final step = run.plan.steps[i];
    final rec = run.steps[i];
    final label = 'Étape ${i + 1} « ${step.title} »';

    // Reprise d'une étape dont l'opération avait déjà été lancée.
    if (rec.opId != null && (rec.state == MissionStepState.enCours || rec.state == MissionStepState.inconnue)) {
      try {
        final st = await backend.status(rec.opId!);
        if (st.state.isFinal) return await _conclude(i, st);
        if (st.state == OpState.awaitingApproval) {
          await backend.reject(st.id);
          await _log('alerte', '$label : ancienne demande d\'approbation abandonnée, l\'étape est relancée.', step: i);
        } else {
          return await _await(i, st.id);
        }
      } catch (e) {
        rec.state = MissionStepState.inconnue;
        rec.note = 'L\'opération ${rec.opId} ne peut plus être suivie ($e). Vérifiez l\'état du projet avant de relancer.';
        await _log('alerte', '$label : ${rec.note}', step: i);
        return (RunState.interrompu, 'État d\'une opération inconnu.');
      }
      rec.opId = null;
    }

    rec
      ..state = MissionStepState.enCours
      ..startedAt = _now()
      ..endedAt = null
      ..note = null;
    _emit();

    // 1. Condition.
    if (step.when != null) {
      try {
        if (!evalCondition(step.when!, run.context)) {
          rec
            ..state = MissionStepState.ignoree
            ..note = 'Condition non remplie : ${conditionLabel(step.when!)}.'
            ..endedAt = _now();
          await _log('info', '$label ignorée : ${conditionLabel(step.when!)} — faux.', step: i);
          return null;
        }
      } on ResolutionError catch (e) {
        return await _fail(i, 'Condition impossible à évaluer : ${e.message}');
      }
    }

    // 2. Paramètres calculés (le jeton n'est jamais journalisé ni enregistré).
    final params = Map<String, dynamic>.of(step.params);
    try {
      for (final b in step.bind.entries) {
        if (b.value == 'forge.token') {
          final kind = forgeKindFor(run.context);
          final token = await backend.forgeToken(kind);
          if (token == null || token.isEmpty) {
            return await _fail(i, 'Aucun jeton ${kind.label} dans le coffre : ajoutez-le dans Paramètres → GitHub et GitLab.');
          }
          params[b.key] = token;
        } else {
          params[b.key] = resolveValue(b.value, run.context);
        }
      }
    } on ResolutionError catch (e) {
      return await _fail(i, e.message);
    }

    // 3. Relecture humaine.
    if (step.review) {
      final preview = await _preview(step, params);
      await _log('info', '$label : relecture demandée.', step: i);
      final ok = await pilot.review(step, preview);
      if (_stopRequested) return _stoppedBefore(i);
      if (!ok) return await _refuse(i, 'Relecture refusée par l\'utilisateur.');
      await _log('decision', '$label : relecture validée par l\'utilisateur.', step: i);
    }

    // 4. Consentement spécifique (action externe).
    if (step.needsSpecificConsent) {
      final ok = await pilot.specificConsent(step, {for (final e in params.entries) if (e.key != 'token') e.key: e.value});
      if (_stopRequested) return _stoppedBefore(i);
      if (!ok) return await _refuse(i, 'Consentement spécifique refusé pour une action externe.');
      await _log('decision', '$label : consentement spécifique donné pour une action externe non annulable.', step: i);
    }

    // 5. Soumission au compagnon, approbation, attente.
    OpStatus st;
    try {
      st = await backend.submit(OpRequest(type: step.op, root: run.projectPath, params: params));
    } catch (e) {
      return await _fail(i, 'Refus ou erreur du compagnon : ${_msg(e)}', interrupted: _isNetwork(e));
    }
    rec.opId = st.id;
    await _save();
    if (st.state == OpState.awaitingApproval) {
      final ok = await pilot.approveOp(step, st);
      if (_stopRequested || !ok) {
        try {
          await backend.reject(st.id);
        } catch (_) {}
        if (_stopRequested) return _stoppedBefore(i);
        return await _refuse(i, 'Opération refusée dans le panneau d\'approbation du compagnon.');
      }
      try {
        await backend.approve(st.id);
      } catch (e) {
        // L'approbation a pu atteindre le compagnon : on ne relance pas à
        // l'aveugle, l'état de l'opération sera relu à la reprise.
        rec
          ..state = MissionStepState.inconnue
          ..note = 'Confirmation de l\'approbation perdue (${_msg(e)}) : état relu à la reprise.';
        await _log('alerte', '$label : ${rec.note}', step: i);
        return (RunState.interrompu, 'Compagnon injoignable pendant l\'approbation.');
      }
      await _log('decision', '$label : opération approuvée par l\'utilisateur.', step: i);
    }
    return await _await(i, st.id);
  }

  Future<(RunState, String)?> _await(int i, String id) async {
    final step = run.plan.steps[i];
    _inflight = id;
    final deadline = _now().add(run.plan.limits.waitFor(step.type));
    try {
      while (true) {
        final st = await backend.status(id);
        if (st.state.isFinal) return await _conclude(i, st);
        if (_stopRequested) {
          // L'annulation a été envoyée par emergencyStop ; le compagnon peut
          // mettre quelques secondes à arrêter le processus (SIGTERM puis SIGKILL).
          final until = _now().add(cancelConfirmation);
          while (!_now().isAfter(until)) {
            await Future<void>.delayed(pollInterval);
            final after = await backend.status(id);
            if (after.state.isFinal) return await _conclude(i, after);
          }
          run.steps[i]
            ..state = MissionStepState.inconnue
            ..note = 'Arrêt demandé pendant l\'opération ; son état final n\'est pas confirmé.';
          return (RunState.arrete, 'Arrêt d\'urgence.');
        }
        if (_now().isAfter(deadline)) {
          try {
            await backend.cancel(id);
          } catch (_) {}
          return await _fail(i, 'Délai dépassé (${run.plan.limits.waitFor(step.type).inMinutes} min) : opération annulée.');
        }
        await Future<void>.delayed(pollInterval);
      }
    } catch (e) {
      run.steps[i]
        ..state = MissionStepState.inconnue
        ..note = 'Suivi interrompu : ${_msg(e)}';
      await _log('alerte', 'Étape ${i + 1} : suivi interrompu (${_msg(e)}). La mission pourra être reprise.', step: i);
      return (RunState.interrompu, 'Compagnon injoignable pendant une opération.');
    } finally {
      _inflight = null;
    }
  }

  Future<(RunState, String)?> _conclude(int i, OpStatus st) async {
    final step = run.plan.steps[i];
    final rec = run.steps[i]
      ..endedAt = _now()
      ..exitCode = st.exitCode;
    run.context.record(st);
    final label = 'Étape ${i + 1} « ${step.title} »';
    switch (st.state) {
      case OpState.succeeded:
        rec.state = MissionStepState.reussie;
        if (step.type == OpType.projectBackup) {
          run.checkpointId = st.result?['id'] as String?;
          await _log('succes', '$label : point de contrôle créé (${run.checkpointId ?? 'identifiant inconnu'}).', step: i);
        } else {
          await _log('succes', '$label réussie${st.exitCode == null ? '' : ' (code ${st.exitCode})'}.', step: i);
        }
        for (final r in step.requires) {
          try {
            if (!evalCondition(r, run.context)) {
              rec.note = 'Prérequis non rempli : ${conditionLabel(r)}.';
              await _log('alerte', '$label : prérequis non rempli — ${conditionLabel(r)}. Mission arrêtée sans rien modifier de plus.', step: i);
              return (RunState.arrete, 'Prérequis non rempli : ${conditionLabel(r)}.');
            }
          } on ResolutionError catch (e) {
            return await _fail(i, 'Prérequis impossible à vérifier : ${e.message}');
          }
        }
        return null;
      case OpState.cancelled:
        rec
          ..state = MissionStepState.annulee
          ..note = 'Opération annulée.';
        await _log('arret', '$label : opération annulée.', step: i);
        return _stopRequested
            ? (RunState.arrete, 'Arrêt d\'urgence : opération en cours annulée.')
            : (RunState.echoue, 'Opération annulée.');
      case OpState.rejected:
        return await _refuse(i, 'Opération refusée.');
      default:
        final detail = (st.error ?? (st.stderr.trim().isEmpty ? st.stdout : st.stderr)).trim().split('\n').take(3).join(' / ');
        return await _fail(i, '${st.state == OpState.timedOut ? 'Délai dépassé côté compagnon' : 'Échec'}${st.exitCode == null ? '' : ' (code ${st.exitCode})'} : $detail');
    }
  }

  Future<String> _preview(StepSpec step, Map<String, dynamic> params) async {
    final lines = <String>['Opération : ${step.op}'];
    params.forEach((k, v) {
      if (k == 'token') return;
      lines.add(v is List ? '$k (${v.length}) :\n${v.map((e) => '  • $e').join('\n')}' : '$k : $v');
    });
    final status = run.context.status(OpType.gitStatus);
    if (status != null && status.stdout.trim().isNotEmpty) {
      lines.add('\nÉtat Git avant l\'étape :\n${status.stdout.trim().split('\n').take(40).join('\n')}');
    }
    final outgoing = run.context.result(OpType.gitOutgoing);
    if (outgoing != null) {
      final commits = (outgoing['commits'] as List? ?? const []).cast<Map>();
      lines.add('\nCommits qui seraient publiés (${commits.length}) :\n${commits.take(20).map((c) => '  ${c['sha']} ${c['subject']}').join('\n')}');
    }
    return lines.join('\n');
  }

  /// Arrêt d'urgence avant que l'étape ne soit exécutée.
  (RunState, String) _stoppedBefore(int i) {
    run.steps[i]
      ..state = MissionStepState.annulee
      ..note = 'Arrêt d\'urgence avant l\'exécution : rien n\'a été lancé pour cette étape.'
      ..endedAt = _now();
    return (RunState.arrete, 'Arrêt d\'urgence.');
  }

  Future<(RunState, String)> _fail(int i, String message, {bool interrupted = false}) async {
    run.steps[i]
      ..state = interrupted ? MissionStepState.aFaire : MissionStepState.echouee
      ..note = message
      ..endedAt = _now();
    if (interrupted) run.steps[i].opId = null;
    await _log('echec', 'Étape ${i + 1} « ${run.plan.steps[i].title} » : $message', step: i);
    return (interrupted ? RunState.interrompu : RunState.echoue, message);
  }

  Future<(RunState, String)> _refuse(int i, String message) async {
    run.steps[i]
      ..state = MissionStepState.refusee
      ..note = message
      ..endedAt = _now();
    await _log('decision', 'Étape ${i + 1} « ${run.plan.steps[i].title} » : $message', step: i);
    return (RunState.arrete, message);
  }

  Future<RunSnapshot> _finish(RunState state, String? reason) async {
    run
      ..state = state
      ..reason = reason;
    await _log(
      state == RunState.termine ? 'succes' : state == RunState.echoue ? 'echec' : 'arret',
      switch (state) {
        RunState.termine => 'Mission terminée avec succès.',
        RunState.interrompu => 'Mission interrompue : $reason Elle peut être reprise.',
        _ => 'Mission ${state.label.toLowerCase()} : $reason',
      },
    );
    await _save();
    return run;
  }

  Future<void> _save() async {
    await store.save(run);
    _emit();
  }

  Future<void> _log(String kind, String message, {int? step}) => store.log(run.id, CaptainEvent(_now(), kind, message, step: step));

  void _emit() {
    if (!_changes.isClosed) _changes.add(run);
  }

  static bool _isNetwork(Object e) {
    final s = '$e'.toLowerCase();
    return s.contains('socket') || s.contains('connection') || s.contains('injoignable') || s.contains('network') || s.contains('timeout');
  }

  static String _msg(Object e) {
    try {
      return (e as dynamic).message as String;
    } catch (_) {
      return '$e';
    }
  }

  Future<void> dispose() => _changes.close();
}
