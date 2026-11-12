import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

/// Barre de progression façon jauge de cuivre. Le pourcentage est toujours
/// affiché en texte : l'information ne repose pas uniquement sur la couleur.
class GaugeProgress extends StatelessWidget {
  const GaugeProgress({super.key, required this.value, required this.label});

  /// Entre 0 et 1.
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = CambuseTheme.of(context);
    final v = value.clamp(0.0, 1.0);
    final percent = '${(v * 100).round()} %';
    return Semantics(
      label: label,
      value: percent,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: p.copper, width: p.borderWidth),
                  color: p.night,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(colors: [p.copper, p.gold]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: CambuseSpacing.sm),
            Text(percent, style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
