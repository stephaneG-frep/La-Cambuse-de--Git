import 'package:flutter/foundation.dart';

/// Préférences d'affichage et d'accessibilité (SPEC §2, DESIGN « Accessibilité »).
@immutable
class AppSettings {
  const AppSettings({
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.highContrast = false,
    this.languageCode = 'fr',
  });

  static const defaults = AppSettings();
  static const minTextScale = 0.85;
  static const maxTextScale = 2.0;
  static const supportedLanguages = ['fr', 'en'];

  /// Multiplicateur appliqué à l'échelle de texte du système.
  final double textScale;
  final bool reduceMotion;
  final bool highContrast;
  final String languageCode;

  AppSettings copyWith({
    double? textScale,
    bool? reduceMotion,
    bool? highContrast,
    String? languageCode,
  }) =>
      AppSettings(
        textScale: (textScale ?? this.textScale).clamp(minTextScale, maxTextScale),
        reduceMotion: reduceMotion ?? this.reduceMotion,
        highContrast: highContrast ?? this.highContrast,
        languageCode: languageCode ?? this.languageCode,
      );

  Map<String, String> toMap() => {
        'text_scale': textScale.toStringAsFixed(2),
        'reduce_motion': '$reduceMotion',
        'high_contrast': '$highContrast',
        'language': languageCode,
      };

  /// Lecture tolérante : toute valeur corrompue retombe sur la valeur par défaut.
  factory AppSettings.fromMap(Map<String, String> m) {
    final scale = double.tryParse(m['text_scale'] ?? '') ?? defaults.textScale;
    final lang = m['language'];
    return AppSettings(
      textScale: scale.isFinite
          ? scale.clamp(minTextScale, maxTextScale)
          : defaults.textScale,
      reduceMotion: m['reduce_motion'] == 'true',
      highContrast: m['high_contrast'] == 'true',
      languageCode:
          supportedLanguages.contains(lang) ? lang! : defaults.languageCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.textScale == textScale &&
      other.reduceMotion == reduceMotion &&
      other.highContrast == highContrast &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(textScale, reduceMotion, highContrast, languageCode);
}
