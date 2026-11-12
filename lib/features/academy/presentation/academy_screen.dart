import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gauge_progress.dart';
import '../domain/catalog.dart';
import 'academy_providers.dart';

/// Carte des îles de compétences (écran signature n° 1 de DESIGN.md).
class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final due = ref.watch(dueCardsProvider).value?.length ?? 0;
    final wide = MediaQuery.sizeOf(context).width >= CambuseBreakpoints.rail;

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Semantics(
          header: true,
          child: Text(l.academyTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: p.gold)),
        ),
        const SizedBox(height: CambuseSpacing.xs),
        Text(l.academySubtitle, style: TextStyle(color: p.textSecondary)),
        if (Localizations.localeOf(context).languageCode != 'fr')
          Text(l.contentLanguageNote, style: TextStyle(color: p.gold)),
        const SizedBox(height: CambuseSpacing.md),
        Wrap(
          spacing: CambuseSpacing.sm,
          runSpacing: CambuseSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/academie/recherche'),
              icon: const Icon(Icons.search),
              label: Text(l.academySearch),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/academie/glossaire'),
              icon: const Icon(Icons.menu_book),
              label: Text(l.academyGlossary),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/academie/revisions'),
              icon: Badge(
                isLabelVisible: due > 0,
                label: Text('$due'),
                child: const Icon(Icons.replay),
              ),
              label: Text(l.academyReviews),
            ),
          ],
        ),
        const SizedBox(height: CambuseSpacing.md),
        Wrap(
          spacing: CambuseSpacing.md,
          runSpacing: CambuseSpacing.md,
          children: [
            for (final island in islands)
              SizedBox(
                width: wide ? 300 : double.infinity,
                child: _IslandCard(island: island),
              ),
          ],
        ),
      ],
    );
  }
}

class _IslandCard extends ConsumerWidget {
  const _IslandCard({required this.island});

  final Island island;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final stats = island.isAvailable ? ref.watch(moduleStatsProvider(island.id)) : null;
    final prereq = island.prerequisites.map((id) => islandById(id).title).join(', ');
    final color = island.isAvailable ? p.copper : p.textSecondary;

    final content = Padding(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(island.icon, color: color, size: 32),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(child: Text(island.title, style: Theme.of(context).textTheme.titleMedium)),
            if (island.isAvailable) Icon(Icons.chevron_right, color: p.turquoise),
          ]),
          if (prereq.isNotEmpty) ...[
            const SizedBox(height: CambuseSpacing.xs),
            Text('${l.modulePrerequisites} : $prereq', style: TextStyle(color: p.textSecondary)),
          ],
          const SizedBox(height: CambuseSpacing.sm),
          if (island.isAvailable) ...[
            Text(l.islandAvailable, style: TextStyle(color: p.turquoise)),
            const SizedBox(height: CambuseSpacing.sm),
            if (stats != null) GaugeProgress(value: stats.ratio, label: l.moduleProgress),
          ] else
            Row(children: [
              Icon(Icons.cloud_outlined, size: 18, color: p.textSecondary),
              const SizedBox(width: CambuseSpacing.xs),
              Expanded(
                child: Text(l.islandPlanned(island.availablePhase!),
                    style: TextStyle(color: p.textSecondary)),
              ),
            ]),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: island.isAvailable
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CambuseSpacing.radius),
              side: BorderSide(color: p.textSecondary.withValues(alpha: 0.5), width: p.borderWidth),
            ),
      child: island.isAvailable
          ? InkWell(onTap: () => context.go('/academie/${island.id}'), child: content)
          : content,
    );
  }
}
