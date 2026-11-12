import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/domain/ai_models.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../profile/data/profile_repository.dart';
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
            const _ProfileCard(),
            Padding(
              padding: const EdgeInsets.only(bottom: CambuseSpacing.md),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(Icons.smart_toy_outlined, color: p.copper),
                  title: Text(l.aiSettingsTitle),
                  subtitle: Text(
                    switch (ref.watch(aiConfigProvider).value) {
                      final c? => '${c.kind == AiProviderKind.anthropic ? l.aiProviderAnthropic : l.aiProviderOpenAi} · ${c.model}',
                      null => '',
                    },
                    style: TextStyle(color: p.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right, color: p.turquoise),
                  onTap: () => context.push('/parametres/ia'),
                ),
              ),
            ),
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

/// Renommage du profil local (absent si aucun profil n'a encore été créé).
class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard();

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  TextEditingController? _controller;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).save(_controller!.text);
      setState(() => _error = null);
      messenger.showSnackBar(SnackBar(content: Text(l.settingsProfileSaved)));
    } on InvalidProfileName {
      setState(() => _error = l.createProfileInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    _controller ??= TextEditingController(text: profile.displayName);
    return Padding(
      padding: const EdgeInsets.only(bottom: CambuseSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(CambuseSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.settingsProfile, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: CambuseSpacing.sm),
              TextField(
                controller: _controller,
                maxLength: ProfileRepository.maxLength,
                decoration: InputDecoration(labelText: l.createProfileHint, errorText: _error),
                onSubmitted: (_) => _save(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.edit),
                  label: Text(l.settingsProfileRename),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
