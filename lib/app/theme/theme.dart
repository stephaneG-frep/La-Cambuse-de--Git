import 'package:flutter/material.dart';

import 'tokens.dart';

/// Extension de thème donnant accès à la palette Cambuse depuis le contexte.
@immutable
class CambuseTheme extends ThemeExtension<CambuseTheme> {
  const CambuseTheme(this.palette);

  final CambusePalette palette;

  static CambusePalette of(BuildContext context) =>
      Theme.of(context).extension<CambuseTheme>()!.palette;

  @override
  CambuseTheme copyWith({CambusePalette? palette}) =>
      CambuseTheme(palette ?? this.palette);

  @override
  CambuseTheme lerp(CambuseTheme? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

ThemeData buildCambuseTheme({
  required bool highContrast,
  required bool reduceMotion,
}) {
  final p = highContrast ? CambusePalette.highContrast : CambusePalette.standard;

  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: p.copper,
    onPrimary: p.night,
    secondary: p.turquoise,
    onSecondary: p.night,
    tertiary: p.gold,
    onTertiary: p.night,
    error: p.alert,
    onError: p.night,
    surface: p.night,
    onSurface: p.text,
    onSurfaceVariant: p.textSecondary,
    surfaceContainerLowest: p.night,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surface,
    outline: p.copper,
    outlineVariant: p.textSecondary,
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(CambuseSpacing.radius),
    side: BorderSide(color: p.copper, width: p.borderWidth),
  );

  const noTransitions = PageTransitionsTheme(builders: {
    TargetPlatform.android: _NoTransitionsBuilder(),
    TargetPlatform.linux: _NoTransitionsBuilder(),
  });

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.night,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    extensions: [CambuseTheme(p)],
    pageTransitionsTheme: reduceMotion ? noTransitions : base.pageTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: p.night,
      foregroundColor: p.text,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: p.gold,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      shape: shape,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.copper,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.night : p.textSecondary,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            color: s.contains(WidgetState.selected) ? p.gold : p.textSecondary,
            fontWeight:
                s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.copper,
      selectedIconTheme: IconThemeData(color: p.night),
      unselectedIconTheme: IconThemeData(color: p.textSecondary),
      selectedLabelTextStyle: TextStyle(color: p.gold, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: p.textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.copper,
        foregroundColor: p.night,
        minimumSize: const Size(CambuseSpacing.minTouchTarget, CambuseSpacing.minTouchTarget),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.turquoise,
        side: BorderSide(color: p.turquoise, width: p.borderWidth),
        minimumSize: const Size(CambuseSpacing.minTouchTarget, CambuseSpacing.minTouchTarget),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.turquoise,
        minimumSize: const Size(CambuseSpacing.minTouchTarget, CambuseSpacing.minTouchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.night,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CambuseSpacing.radius),
        borderSide: BorderSide(color: p.textSecondary, width: p.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CambuseSpacing.radius),
        borderSide: BorderSide(color: p.textSecondary, width: p.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CambuseSpacing.radius),
        borderSide: BorderSide(color: p.turquoise, width: p.borderWidth + 1),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.copper.withValues(alpha: 0.4)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface,
      contentTextStyle: TextStyle(color: p.text),
      actionTextColor: p.turquoise,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
