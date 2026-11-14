import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../domain/engine.dart';
import '../domain/missions.dart';
import 'captain_providers.dart';
import 'captain_widgets.dart';

/// Capitaine automatique : missions supervisées, plans IA facultatifs et
/// journal des missions.
class CaptainScreen extends ConsumerWidget {
  const CaptainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final link = ref.watch(companionLinkProvider);
    final ui = ref.watch(captainControllerProvider);
    final runs = ref.watch(captainRunsProvider);
    final h = Theme.of(context).textTheme.titleMedium?.copyWith(color: p.gold);

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Semantics(
          header: true,
          child: Text(l.cpTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: p.gold)),
        ),
        const SizedBox(height: CambuseSpacing.xs),
        Text(l.cpSubtitle, style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: CambuseSpacing.md),
        if (link.isLoading) const LoadingView(),
        if (!link.isLoading && link.value == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lan_outlined, color: p.copper, size: 40),
                const SizedBox(height: CambuseSpacing.sm),
                Text(l.cpNeedsCompanion),
                const SizedBox(height: CambuseSpacing.md),
                FilledButton.icon(
                  onPressed: () => context.push('/parametres/compagnon'),
                  icon: const Icon(Icons.settings),
                  label: Text(l.wsOpenCompanion),
                ),
              ]),
            ),
          ),
        if (ui.run != null && !ui.run!.state.isFinal)
          Card(
            color: p.surface,
            child: ListTile(
              leading: Icon(ui.pending != null ? Icons.front_hand : Icons.sailing, color: ui.pending != null ? p.gold : p.turquoise),
              title: Text(ui.run!.plan.title),
              subtitle: Text(ui.pending != null ? l.cpDecisionWaiting : runStateLabel(l, ui.run!.state)),
              trailing: Icon(Icons.chevron_right, color: p.turquoise),
              onTap: () => context.go('/capitaine/execution?id=${ui.run!.id}'),
            ),
          ),
        if (link.value != null) ...[
          const SizedBox(height: CambuseSpacing.sm),
          Semantics(header: true, child: Text(l.cpMissions, style: h)),
          const SizedBox(height: CambuseSpacing.xs),
          for (final m in missionTemplates)
            Card(
              margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
              child: ListTile(
                leading: Icon(Icons.map_outlined, color: p.copper),
                title: Text(m.title),
                subtitle: Text(m.summary, style: TextStyle(color: p.textSecondary)),
                trailing: Icon(Icons.chevron_right, color: p.turquoise),
                onTap: () => context.go('/capitaine/plan?mission=${m.id}'),
              ),
            ),
          Card(
            margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
            child: ListTile(
              leading: Icon(Icons.smart_toy_outlined, color: p.gold),
              title: Text(l.cpAiTitle),
              subtitle: Text(l.cpAiDesc, style: TextStyle(color: p.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: p.turquoise),
              onTap: () => context.go('/capitaine/ia'),
            ),
          ),
        ],
        const SizedBox(height: CambuseSpacing.md),
        Semantics(header: true, child: Text(l.cpHistory, style: h)),
        const SizedBox(height: CambuseSpacing.xs),
        runs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e', style: TextStyle(color: p.alert)),
          data: (list) => list.isEmpty
              ? Text(l.cpHistoryEmpty, style: TextStyle(color: p.textSecondary))
              : Column(children: [
                  for (final r in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        switch (RunState.values.firstWhere((s) => s.name == r.state, orElse: () => RunState.interrompu)) {
                          RunState.termine => Icons.check_circle,
                          RunState.echoue => Icons.error,
                          RunState.arrete => Icons.stop_circle,
                          _ => Icons.pause_circle,
                        },
                        color: p.copper,
                      ),
                      title: Text(r.title),
                      subtitle: Text(
                          '${runStateLabel(l, RunState.values.firstWhere((s) => s.name == r.state, orElse: () => RunState.interrompu))} · '
                          '${r.projectPath.split('/').last} · ${r.updatedAt.toLocal().toString().substring(0, 16)}',
                          style: TextStyle(color: p.textSecondary, fontSize: 12)),
                      onTap: () => context.go('/capitaine/execution?id=${r.id}'),
                    ),
                ]),
        ),
      ],
    );
  }
}
