import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// États standardisés (DESIGN : chargement / vide / erreur / succès).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: AppLocalizations.of(context).loading,
          child: const CircularProgressIndicator(),
        ),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: p.textSecondary),
            const SizedBox(height: CambuseSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: p.alert),
            const SizedBox(height: CambuseSpacing.md),
            Text(
              AppLocalizations.of(context).errorGeneric('$error'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section prévue dans une phase ultérieure : affichée honnêtement comme telle,
/// sans bouton ni fonctionnalité simulée.
class PlannedSectionView extends StatelessWidget {
  const PlannedSectionView({
    super.key,
    required this.title,
    required this.description,
    required this.phase,
    required this.icon,
  });

  final String title;
  final String description;
  final int phase;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(CambuseSpacing.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: p.copper),
                  const SizedBox(height: CambuseSpacing.md),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: CambuseSpacing.sm),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: CambuseSpacing.lg),
                  Chip(
                    avatar: Icon(Icons.construction, color: p.gold),
                    label: Text(l.plannedPhaseTitle),
                  ),
                  const SizedBox(height: CambuseSpacing.sm),
                  Text(
                    l.plannedPhaseBody(phase),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
