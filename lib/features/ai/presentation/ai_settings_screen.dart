import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/ai_config.dart';
import '../domain/ai_models.dart';
import 'ai_providers.dart';

/// Paramètres → Professeur IA : fournisseur, modèle, clé (coffre du système),
/// effort, budget quotidien et test de connexion réel.
class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aiSettingsTitle)),
      body: ref.watch(aiConfigProvider).when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e),
            data: (c) => _AiSettingsForm(initial: c),
          ),
    );
  }
}

class _AiSettingsForm extends ConsumerStatefulWidget {
  const _AiSettingsForm({required this.initial});

  final AiConfig initial;

  @override
  ConsumerState<_AiSettingsForm> createState() => _AiSettingsFormState();
}

class _AiSettingsFormState extends ConsumerState<_AiSettingsForm> {
  late AiConfig _c = widget.initial;
  late final _model = TextEditingController(text: widget.initial.model);
  late final _baseUrl = TextEditingController(text: widget.initial.baseUrl);
  late final _budget = TextEditingController(text: '${widget.initial.dailyTokenBudget}');
  final _key = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void dispose() {
    _model.dispose();
    _baseUrl.dispose();
    _budget.dispose();
    _key.dispose();
    super.dispose();
  }

  AiConfig get _current => _c.copyWith(
        model: _model.text.trim().isEmpty ? AiConfig.defaults.model : _model.text.trim(),
        baseUrl: _baseUrl.text.trim(),
        dailyTokenBudget: int.tryParse(_budget.text.trim()) ?? _c.dailyTokenBudget,
      );

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(aiConfigProvider.notifier).save(_current);
    messenger.showSnackBar(SnackBar(content: Text(l.aiSettingsSaved)));
  }

  Future<void> _saveKey() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final key = _key.text.trim();
    if (key.isEmpty) return;
    try {
      await ref.read(secretStoreProvider).write(secretKeyFor(_c.kind), key);
      _key.clear();
      ref.invalidate(storedKeyHintProvider(_c.kind));
      messenger.showSnackBar(SnackBar(content: Text(l.aiKeySaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.aiKeyStorageError('$e'))));
    }
  }

  Future<void> _deleteKey() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(secretStoreProvider).delete(secretKeyFor(_c.kind));
    ref.invalidate(storedKeyHintProvider(_c.kind));
    messenger.showSnackBar(SnackBar(content: Text(l.aiKeyDeleted)));
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    final c = _current;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      await ref.read(aiProviderFactoryProvider)(c).checkConnection(c.model);
      setState(() {
        _testOk = true;
        _testResult = l.aiTestOk(c.model);
      });
    } on AiException catch (e) {
      setState(() {
        _testOk = false;
        _testResult = describeAiError(l, e);
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final hint = ref.watch(storedKeyHintProvider(_c.kind));
    final anthropic = _c.kind == AiProviderKind.anthropic;

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: CambuseSpacing.md),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: CambuseSpacing.sm),
                  ...children,
                ],
              ),
            ),
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(CambuseSpacing.md),
          children: [
            section(l.aiProvider, [
              // Libellés longs : boutons radio verticaux plutôt que segments.
              RadioGroup<AiProviderKind>(
                groupValue: _c.kind,
                onChanged: (k) => setState(() {
                  _c = _c.copyWith(kind: k);
                  if (k == AiProviderKind.anthropic &&
                      !anthropicModels.any((m) => m.id == _model.text)) {
                    _model.text = AiConfig.defaults.model;
                  }
                }),
                child: Column(children: [
                  RadioListTile(
                    value: AiProviderKind.anthropic,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.aiProviderAnthropic),
                  ),
                  RadioListTile(
                    value: AiProviderKind.openAiCompatible,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.aiProviderOpenAi),
                  ),
                ]),
              ),
              const SizedBox(height: CambuseSpacing.md),
              if (anthropic)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: anthropicModels.any((m) => m.id == _model.text)
                      ? _model.text
                      : AiConfig.defaults.model,
                  decoration: InputDecoration(labelText: l.aiModel),
                  items: [
                    for (final m in anthropicModels)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.label} — ${m.inputPerMillion} / ${m.outputPerMillion} \$ par M',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _model.text = v!),
                )
              else ...[
                TextField(controller: _baseUrl, decoration: InputDecoration(labelText: l.aiBaseUrl)),
                const SizedBox(height: CambuseSpacing.sm),
                TextField(controller: _model, decoration: InputDecoration(labelText: l.aiModelCustom)),
              ],
            ]),
            section(l.aiApiKey, [
              Text(
                hint.value == null ? l.aiKeyNone : l.aiKeyStored(hint.value!),
                style: TextStyle(color: hint.value == null ? p.gold : p.turquoise),
              ),
              const SizedBox(height: CambuseSpacing.sm),
              TextField(
                controller: _key,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l.aiApiKey,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Afficher' : 'Masquer',
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _saveKey(),
              ),
              const SizedBox(height: CambuseSpacing.sm),
              Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
                FilledButton.icon(
                  onPressed: _saveKey,
                  icon: const Icon(Icons.lock),
                  label: Text(l.aiKeySave),
                ),
                if (hint.value != null)
                  OutlinedButton.icon(
                    onPressed: _deleteKey,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.aiKeyDelete),
                  ),
              ]),
            ]),
            if (anthropic)
              section(l.aiEffort, [
                Text(l.aiEffortDesc, style: TextStyle(color: p.textSecondary)),
                const SizedBox(height: CambuseSpacing.sm),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'low', label: Text(l.aiEffortLow)),
                    ButtonSegment(value: 'medium', label: Text(l.aiEffortMedium)),
                    ButtonSegment(value: 'high', label: Text(l.aiEffortHigh)),
                  ],
                  selected: {_c.effort},
                  onSelectionChanged: (s) => setState(() => _c = _c.copyWith(effort: s.first)),
                ),
              ]),
            section(l.aiBudget, [
              TextField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.aiBudget),
              ),
              const SizedBox(height: CambuseSpacing.sm),
              Text(l.aiPricesNote, style: TextStyle(color: p.textSecondary)),
            ]),
            Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(l.aiSaveSettings)),
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering),
                label: Text(l.aiTest),
              ),
            ]),
            if (_testResult != null) ...[
              const SizedBox(height: CambuseSpacing.sm),
              Text(_testResult!, style: TextStyle(color: _testOk ? p.turquoise : p.alert)),
            ],
          ],
        ),
      ),
    );
  }
}
