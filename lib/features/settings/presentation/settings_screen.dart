import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (s) => _SettingsBody(settings: s),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final ctrl = ref.read(settingsProvider.notifier);
    final percent = '${(settings.textScale * 100).round()} %';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(CambuseSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(CambuseSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l.settingsTextScale} : $percent',
                        style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: settings.textScale,
                      min: AppSettings.minTextScale,
                      max: AppSettings.maxTextScale,
                      divisions: 23,
                      label: percent,
                      semanticFormatterCallback: (v) => '${(v * 100).round()} %',
                      onChanged: (v) => ctrl.preview(settings.copyWith(textScale: v)),
                      onChangeEnd: (v) => ctrl.apply(settings.copyWith(textScale: v)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CambuseSpacing.md),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l.settingsReduceMotion),
                    subtitle: Text(l.settingsReduceMotionDesc,
                        style: TextStyle(color: p.textSecondary)),
                    value: settings.reduceMotion,
                    onChanged: (v) => ctrl.apply(settings.copyWith(reduceMotion: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l.settingsHighContrast),
                    subtitle: Text(l.settingsHighContrastDesc,
                        style: TextStyle(color: p.textSecondary)),
                    value: settings.highContrast,
                    onChanged: (v) => ctrl.apply(settings.copyWith(highContrast: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CambuseSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(CambuseSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsLanguage, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: CambuseSpacing.sm),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'fr', label: Text(l.languageFrench)),
                        ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
                      ],
                      selected: {settings.languageCode},
                      onSelectionChanged: (s) =>
                          ctrl.apply(settings.copyWith(languageCode: s.first)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
