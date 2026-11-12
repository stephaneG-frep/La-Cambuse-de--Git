import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/theme.dart';

class CambuseApp extends ConsumerStatefulWidget {
  const CambuseApp({super.key});

  @override
  ConsumerState<CambuseApp> createState() => _CambuseAppState();
}

class _CambuseAppState extends ConsumerState<CambuseApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tant que les paramètres chargent, on affiche les valeurs par défaut :
    // jamais d'écran blanc.
    final s = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildCambuseTheme(
        highContrast: s.highContrast,
        reduceMotion: s.reduceMotion,
      ),
      themeAnimationDuration:
          s.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      locale: Locale(s.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            // Multiplie l'échelle système par la préférence de l'utilisateur.
            textScaler: TextScaler.linear(mq.textScaler.scale(1) * s.textScale),
            disableAnimations: mq.disableAnimations || s.reduceMotion,
            highContrast: mq.highContrast || s.highContrast,
          ),
          child: child!,
        );
      },
    );
  }
}
