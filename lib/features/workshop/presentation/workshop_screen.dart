import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

/// Section livrée en phase 5 (ROADMAP.md). Affichée comme telle, sans simulation.
class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlannedSectionView(
      title: l.navWorkshop,
      description: l.sectionWorkshopDesc,
      phase: 5,
      icon: Icons.construction,
    );
  }
}
