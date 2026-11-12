import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

/// Section livrée en phase 10 (ROADMAP.md). Affichée comme telle, sans simulation.
class CaptainScreen extends StatelessWidget {
  const CaptainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlannedSectionView(
      title: l.navCaptain,
      description: l.sectionCaptainDesc,
      phase: 10,
      icon: Icons.explore,
    );
  }
}
