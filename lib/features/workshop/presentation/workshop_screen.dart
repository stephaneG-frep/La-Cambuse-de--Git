import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';

/// Projets visibles via le compagnon : dossiers autorisés et sous-dossiers.
final workshopProjectsProvider = FutureProvider.autoDispose<List<(String, List<Map<String, dynamic>>)>>((ref) async {
  final link = await ref.watch(companionLinkProvider.future);
  if (link == null) return const [];
  final client = ref.read(companionClientProvider);
  final info = await client.waitFor((await client.submit(OpRequest(type: OpType.systemInfo.code))).id);
  final roots = ((info.result?['roots'] as List?) ?? const []).cast<String>();
  return [
    for (final r in roots)
      (
        r,
        (((await client.waitFor((await client.submit(OpRequest(type: OpType.projectList.code, root: r))).id))
                    .result?['projects'] as List?) ??
                const [])
            .cast<Map<String, dynamic>>(),
      ),
  ];
});

/// Chantier naval : liste des projets (écran signature n° 3 de DESIGN.md).
class WorkshopScreen extends ConsumerWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final link = ref.watch(companionLinkProvider);
    final header = [
      Semantics(
        header: true,
        child: Text(l.wsTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: p.gold)),
      ),
      const SizedBox(height: CambuseSpacing.xs),
      Text(l.wsSubtitle, style: TextStyle(color: p.textSecondary)),
      const SizedBox(height: CambuseSpacing.md),
    ];
    if (link.isLoading) return const LoadingView();
    if (link.value == null) {
      return ListView(padding: const EdgeInsets.all(CambuseSpacing.md), children: [
        ...header,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lan_outlined, color: p.copper, size: 40),
              const SizedBox(height: CambuseSpacing.sm),
              Text(l.wsNotPaired),
              const SizedBox(height: CambuseSpacing.md),
              FilledButton.icon(
                onPressed: () => context.push('/parametres/compagnon'),
                icon: const Icon(Icons.settings),
                label: Text(l.wsOpenCompanion),
              ),
            ]),
          ),
        ),
      ]);
    }
    final projects = ref.watch(workshopProjectsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(workshopProjectsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        children: [
          ...header,
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => ref.invalidate(workshopProjectsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l.wsRefresh),
            ),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          projects.when(
            loading: () => const Padding(padding: EdgeInsets.all(CambuseSpacing.lg), child: LoadingView()),
            error: (e, _) => Text(e is CompanionException ? e.message : '$e', style: TextStyle(color: p.alert)),
            data: (roots) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (root, list) in roots) ...[
                Text(root, style: TextStyle(fontFamily: 'monospace', color: p.textSecondary, fontSize: 12)),
                const SizedBox(height: CambuseSpacing.xs),
                if (list.isEmpty) Text(l.wsNoProjects),
                for (final pr in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: Icon(pr['git'] == true ? Icons.account_tree : Icons.folder_outlined,
                          color: pr['git'] == true ? p.turquoise : p.copper),
                      title: Text(pr['name'] as String),
                      subtitle: Text(pr['git'] == true ? l.wsGitRepo : l.wsNoGit,
                          style: TextStyle(color: p.textSecondary)),
                      trailing: Icon(Icons.chevron_right, color: p.turquoise),
                      onTap: () => context.go(Uri(path: '/atelier/projet', queryParameters: {'chemin': pr['path']}).toString()),
                    ),
                  ),
                const SizedBox(height: CambuseSpacing.md),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
