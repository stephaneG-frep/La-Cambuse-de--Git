import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gauge_progress.dart';
import '../../../shared/widgets/state_views.dart';
import '../../companion_link/data/companion_client.dart';
import '../../workshop/presentation/op_helper.dart';
import '../domain/engine.dart';
import '../domain/report.dart';
import 'captain_providers.dart';
import 'captain_widgets.dart';

/// Mission enregistrée (hors exécution en cours) : instantané et rapport.
final _savedRunProvider = FutureProvider.autoDispose.family<(RunSnapshot?, String?), String>((ref, id) async {
  ref.watch(captainRunsProvider); // relu quand une mission change
  final repo = ref.read(captainRepositoryProvider);
  final run = await repo.load(id);
  final events = run == null ? const <CaptainEvent>[] : await repo.events(id);
  return (run, run == null ? null : buildReport(run, events));
});

/// Exécution d'une mission : progression, décisions, pause, arrêt d'urgence,
/// journal horodaté, rapport et retour arrière.
class RunScreen extends ConsumerWidget {
  const RunScreen({super.key, required this.runId});
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ui = ref.watch(captainControllerProvider);
    final live = ui.run?.id == runId ? ui.run : null;
    final saved = ref.watch(_savedRunProvider(runId));
    final run = live ?? saved.value?.$1;
    return Scaffold(
      appBar: AppBar(title: Text(l.cpRunTitle)),
      body: run == null
          ? (saved.isLoading ? const LoadingView() : Center(child: Text(l.cpPlanMissing)))
          : _RunBody(run: run, live: live != null, pending: live != null ? ui.pending : null, report: saved.value?.$2),
    );
  }
}

class _RunBody extends ConsumerWidget {
  const _RunBody({required this.run, required this.live, required this.pending, required this.report});
  final RunSnapshot run;
  final bool live;
  final PendingDecision? pending;
  final String? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final ctrl = ref.read(captainControllerProvider.notifier);
    final engine = live ? ctrl.engine : null;
    final events = ref.watch(captainEventsProvider(run.id));
    final done = run.steps.where((s) => s.state != MissionStepState.aFaire && s.state != MissionStepState.enCours).length;
    final h = Theme.of(context).textTheme.titleMedium?.copyWith(color: p.gold);
    final running = live && (run.state == RunState.enCours || run.state == RunState.enPause);

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Text(run.plan.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: p.gold)),
        Text(run.projectPath, style: TextStyle(fontFamily: 'monospace', color: p.textSecondary, fontSize: 12)),
        const SizedBox(height: CambuseSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text('${runStateLabel(l, run.state)}${run.reason == null ? '' : ' — ${run.reason}'}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: switch (run.state) {
                    RunState.termine => p.turquoise,
                    RunState.echoue => p.alert,
                    _ => p.gold,
                  })),
        ),
        const SizedBox(height: CambuseSpacing.sm),
        GaugeProgress(value: run.steps.isEmpty ? 0 : done / run.steps.length, label: l.cpProgress),
        const SizedBox(height: CambuseSpacing.sm),

        // --- Commandes ---
        Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
          if (running && run.state == RunState.enCours)
            OutlinedButton.icon(
              onPressed: engine?.pauseRequested ?? false ? null : ctrl.pause,
              icon: const Icon(Icons.pause),
              label: Text(engine?.pauseRequested ?? false ? l.cpPauseRequested : l.cpPause),
            ),
          if (run.state == RunState.enPause || run.state == RunState.interrompu)
            FilledButton.icon(
              onPressed: () async {
                try {
                  await ctrl.resumeRun(run.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Bad state: ', ''))));
                  }
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(l.cpResume),
            ),
          if (running || (live && run.state == RunState.interrompu))
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: p.alert, foregroundColor: Colors.white),
              onPressed: ctrl.emergencyStop,
              icon: const Icon(Icons.dangerous),
              label: Text(l.cpEmergencyStop),
            ),
        ]),

        // --- Décision attendue ---
        if (pending != null) _DecisionPanel(pending!),

        // --- Étapes ---
        const SizedBox(height: CambuseSpacing.md),
        Semantics(header: true, child: Text(l.cpSteps, style: h)),
        for (final (i, s) in run.plan.steps.indexed)
          Builder(builder: (context) {
            final rec = run.steps[i];
            final (icon, label) = stepStateView(l, rec.state);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon,
                  color: switch (rec.state) {
                    MissionStepState.reussie => p.turquoise,
                    MissionStepState.echouee || MissionStepState.refusee || MissionStepState.annulee => p.alert,
                    MissionStepState.enCours => p.gold,
                    _ => p.textSecondary,
                  },
                  semanticLabel: label),
              title: Text('${i + 1}. ${s.title}'),
              subtitle: Text([label, if (rec.note != null) rec.note!].join(' — '), style: TextStyle(color: p.textSecondary, fontSize: 12)),
              trailing: RiskBadge(s.risk),
            );
          }),

        // --- Rapport et retour arrière ---
        if (run.state.isFinal || run.state == RunState.interrompu) ...[
          const SizedBox(height: CambuseSpacing.md),
          Semantics(header: true, child: Text(l.cpRollback, style: h)),
          ...() {
            final items = rollbackGuide(run);
            if (items.isEmpty) return [Text(l.cpRollbackNone, style: TextStyle(color: p.textSecondary))];
            return [
              for (final r in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(CambuseSpacing.sm),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(r.detail),
                      for (final m in r.manual) SelectableText(m, style: TextStyle(fontFamily: 'monospace', color: p.gold, fontSize: 12)),
                      if (r.action != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.restore),
                            label: Text(l.cpRestoreCheckpoint),
                            onPressed: () async {
                              try {
                                final out = await runCompanionOp(context, ref, r.action!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(out.rejected
                                          ? l.compRejected
                                          : out.ok
                                              ? l.cpRestored('${out.status?.result?['restoredTo'] ?? ''}')
                                              : (out.status?.error ?? l.wsOpFailed(r.action!.type)))));
                                }
                              } on CompanionException catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            },
                          ),
                        ),
                    ]),
                  ),
                ),
            ];
          }(),
          if (report != null) ...[
            const SizedBox(height: CambuseSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l.cpCopyReport),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: report!));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cpReportCopied)));
                },
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.cpReport),
              children: [SelectableText(report!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))],
            ),
          ],
        ],

        // --- Journal horodaté ---
        const SizedBox(height: CambuseSpacing.md),
        Semantics(header: true, child: Text(l.cpJournal, style: h)),
        events.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in list.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${e.at.toLocal().toString().substring(11, 19)}  ${e.message}',
                    style: TextStyle(
                        fontSize: 12,
                        color: switch (e.kind) {
                          'echec' || 'arret' => p.alert,
                          'succes' => p.turquoise,
                          'decision' => p.gold,
                          _ => p.text,
                        })),
              ),
          ]),
        ),
      ],
    );
  }
}

class _DecisionPanel extends StatefulWidget {
  const _DecisionPanel(this.d);
  final PendingDecision d;
  @override
  State<_DecisionPanel> createState() => _DecisionPanelState();
}

class _DecisionPanelState extends State<_DecisionPanel> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final d = widget.d;
    final mono = TextStyle(fontFamily: 'monospace', fontSize: 12, color: p.text);
    final (title, okLabel) = switch (d.kind) {
      DecisionKind.approval => (l.cpDecApproval, l.compApprove),
      DecisionKind.review => (l.cpDecReview, l.cpDecContinue),
      DecisionKind.consent => (l.cpDecConsent, l.cpDecPublish),
    };
    final canOk = d.kind != DecisionKind.consent || _understood;
    return Card(
      margin: const EdgeInsets.only(top: CambuseSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CambuseSpacing.radius),
        side: BorderSide(color: d.kind == DecisionKind.consent ? p.alert : p.gold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(d.kind == DecisionKind.consent ? Icons.gpp_maybe : Icons.front_hand, color: d.kind == DecisionKind.consent ? p.alert : p.gold),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(child: Semantics(liveRegion: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium))),
          ]),
          const SizedBox(height: CambuseSpacing.xs),
          Text(d.step.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(d.step.why),
          const SizedBox(height: CambuseSpacing.sm),
          if (d.kind == DecisionKind.approval) for (final line in d.companionPlan) SelectableText(line, style: mono),
          if (d.kind == DecisionKind.review)
            Container(
              padding: const EdgeInsets.all(CambuseSpacing.sm),
              color: p.night,
              child: SelectableText(d.preview, style: mono),
            ),
          if (d.kind == DecisionKind.consent) ...[
            Text(l.cpDecConsentWarn, style: TextStyle(color: p.alert)),
            for (final e in d.params.entries) Text('${e.key} : ${e.value}', style: mono),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _understood,
              onChanged: (v) => setState(() => _understood = v ?? false),
              title: Text(l.cpDecUnderstood),
            ),
          ],
          const SizedBox(height: CambuseSpacing.sm),
          Wrap(spacing: CambuseSpacing.sm, children: [
            OutlinedButton(onPressed: () => d.answer(false), child: Text(l.compReject)),
            FilledButton(onPressed: canOk ? () => d.answer(true) : null, child: Text(okLabel)),
          ]),
        ]),
      ),
    );
  }
}
