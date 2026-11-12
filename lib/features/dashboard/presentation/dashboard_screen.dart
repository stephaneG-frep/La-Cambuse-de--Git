import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../profile/presentation/profile_form.dart';

/// Le pont du navire : accueil et tableau de bord.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (p) => _DashboardBody(profile: p),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pal = CambuseTheme.of(context);
    final text = Theme.of(context).textTheme;
    final count = ref.watch(logbookCountProvider).value;
    final wide = MediaQuery.sizeOf(context).width >= CambuseBreakpoints.rail;

    void goBranch(int i) => StatefulNavigationShell.of(context).goBranch(i);

    final sections = [
      (Icons.map, l.navAcademy, l.sectionAcademyDesc, 1),
      (Icons.construction, l.navWorkshop, l.sectionWorkshopDesc, 2),
      (Icons.explore, l.navCaptain, l.sectionCaptainDesc, 3),
    ];

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Semantics(
          header: true,
          child: Text(l.bridgeTitle, style: text.headlineMedium?.copyWith(color: pal.gold)),
        ),
        const SizedBox(height: CambuseSpacing.md),
        if (profile == null)
          const ProfileForm()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.person_pin, size: 40, color: pal.turquoise),
                  const SizedBox(width: CambuseSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.bridgeWelcome(profile!.displayName),
                            style: text.titleLarge),
                        if (count != null)
                          Text(l.bridgeLogbookCount(count),
                              style: TextStyle(color: pal.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: CambuseSpacing.md),
        Wrap(
          spacing: CambuseSpacing.md,
          runSpacing: CambuseSpacing.md,
          children: [
            for (final (icon, title, desc, branch) in sections)
              SizedBox(
                width: wide ? 320 : double.infinity,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => goBranch(branch),
                    child: Padding(
                      padding: const EdgeInsets.all(CambuseSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(icon, color: pal.copper),
                            const SizedBox(width: CambuseSpacing.sm),
                            Expanded(child: Text(title, style: text.titleMedium)),
                            Icon(Icons.chevron_right, color: pal.turquoise),
                          ]),
                          const SizedBox(height: CambuseSpacing.sm),
                          Text(desc, style: TextStyle(color: pal.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (wide) ...[
          const SizedBox(height: CambuseSpacing.lg),
          Text(l.shortcutsHint, style: TextStyle(color: pal.textSecondary)),
        ],
      ],
    );
  }
}
