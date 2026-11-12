import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

/// Section livrée en phase 2 (ROADMAP.md). Affichée comme telle, sans simulation.
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlannedSectionView(
      title: l.navAcademy,
      description: l.sectionAcademyDesc,
      phase: 2,
      icon: Icons.map,
    );
  }
}
