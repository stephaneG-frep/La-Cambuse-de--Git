import 'package:flutter/material.dart';

/// Jeton de couleurs centralisés (DESIGN.md — « Palette proposée »).
///
/// Toute couleur de l'interface doit provenir d'ici : aucun code couleur en dur
/// dans les widgets.
@immutable
class CambusePalette {
  const CambusePalette({
    required this.night,
    required this.surface,
    required this.copper,
    required this.turquoise,
    required this.gold,
    required this.alert,
    required this.text,
    required this.textSecondary,
    required this.borderWidth,
  });

  final Color night;
  final Color surface;
  final Color copper;
  final Color turquoise;
  final Color gold;
  final Color alert;
  final Color text;
  final Color textSecondary;
  final double borderWidth;

  /// Palette standard (valeurs exactes de DESIGN.md).
  static const standard = CambusePalette(
    night: Color(0xFF101927),
    surface: Color(0xFF1B2B3B),
    copper: Color(0xFFD58B45),
    turquoise: Color(0xFF42D8C9),
    gold: Color(0xFFF4C66A),
    alert: Color(0xFFEF6A62),
    text: Color(0xFFF3F6F7),
    textSecondary: Color(0xFFB9C7D0),
    borderWidth: 1.5,
  );

  /// Mode contraste renforcé.
  static const highContrast = CambusePalette(
    night: Color(0xFF05080D),
    surface: Color(0xFF0E1620),
    copper: Color(0xFFF3AA62),
    turquoise: Color(0xFF6BF0E2),
    gold: Color(0xFFFFD98A),
    alert: Color(0xFFFF8C85),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE2EAEF),
    borderWidth: 2.5,
  );

  /// Couleurs de premier plan qui doivent être lisibles sur [night] et [surface].
  List<(String, Color)> get foregrounds => [
        ('texte', text),
        ('texte secondaire', textSecondary),
        ('cuivre', copper),
        ('turquoise', turquoise),
        ('or', gold),
        ('alerte', alert),
      ];
}

/// Rapport de contraste WCAG 2.x entre deux couleurs opaques.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Espacements et rayons.
abstract final class CambuseSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 14.0;

  /// Cible tactile minimale (DESIGN.md : ≥ 48 dp).
  static const minTouchTarget = 48.0;
}

/// Points de rupture de la mise en page adaptative.
abstract final class CambuseBreakpoints {
  static const rail = 600.0;
  static const extendedRail = 1000.0;
}
