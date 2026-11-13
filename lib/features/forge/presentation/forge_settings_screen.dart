import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../data/forge_client.dart';
import 'forge_providers.dart';

/// Paramètres → GitHub et GitLab : jetons (coffre du système) et test.
class ForgeSettingsScreen extends ConsumerWidget {
  const ForgeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.fgTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              Text(l.fgTokenHelp, style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: CambuseSpacing.md),
              for (final k in ForgeKind.values) _ForgeCard(kind: k),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgeCard extends ConsumerStatefulWidget {
  const _ForgeCard({required this.kind});
  final ForgeKind kind;
  @override
  ConsumerState<_ForgeCard> createState() => _ForgeCardState();
}

class _ForgeCardState extends ConsumerState<_ForgeCard> {
  final _token = TextEditingController();
  final _url = TextEditingController();
  String? _message;
  bool _error = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.kind == ForgeKind.gitlab) {
      Future.microtask(() async => _url.text = await ref.read(gitlabUrlProvider.future));
    }
  }

  @override
  void dispose() {
    _token.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final k = widget.kind;
    if (_token.text.trim().isNotEmpty) {
      await ref.read(secretStoreProvider).write(forgeTokenKey(k), _token.text.trim());
      _token.clear();
    }
    if (k == ForgeKind.gitlab && _url.text.trim().startsWith('https://')) {
      final db = ref.read(databaseProvider);
      await db.into(db.appSettingsTable).insertOnConflictUpdate(
          AppSettingsTableCompanion.insert(key: gitlabUrlKey, value: _url.text.trim().replaceAll(RegExp(r'/$'), '')));
      ref.invalidate(gitlabUrlProvider);
    }
    ref.invalidate(forgeTokenPresentProvider(k));
    await ref.read(logbookRepositoryProvider).record(
        category: 'forge', action: 'Jeton ${k.label} enregistré', details: 'coffre du système', outcome: AuditOutcome.success);
    setState(() {
      _message = l.aiKeySaved;
      _error = false;
    });
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    final k = widget.kind;
    setState(() => _busy = true);
    try {
      final host = k == ForgeKind.gitlab ? Uri.tryParse(await ref.read(gitlabUrlProvider.future))?.host : null;
      final user = await ref.read(forgeFactoryProvider)(k, host: host).currentUser();
      setState(() {
        _message = l.fgConnectedAs(k.label, user);
        _error = false;
      });
    } on ForgeException catch (e) {
      setState(() {
        _message = describeForgeError(l, e, k);
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    await ref.read(secretStoreProvider).delete(forgeTokenKey(widget.kind));
    ref.invalidate(forgeTokenPresentProvider(widget.kind));
    setState(() {
      _message = l.aiKeyDeleted;
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final k = widget.kind;
    final present = ref.watch(forgeTokenPresentProvider(k)).value ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: CambuseSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(k.label, style: Theme.of(context).textTheme.titleMedium),
          Text(present ? l.aiKeyStored('••••') : l.aiKeyNone, style: TextStyle(color: present ? p.turquoise : p.gold)),
          const SizedBox(height: CambuseSpacing.sm),
          if (k == ForgeKind.gitlab) ...[
            TextField(controller: _url, decoration: InputDecoration(labelText: l.fgGitlabUrl), keyboardType: TextInputType.url),
            const SizedBox(height: CambuseSpacing.sm),
          ],
          TextField(
            controller: _token,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l.fgToken(k.label)),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.lock), label: Text(l.aiKeySave)),
            OutlinedButton.icon(
              onPressed: _busy || !present ? null : _test,
              icon: const Icon(Icons.wifi_tethering),
              label: Text(l.fgTest),
            ),
            if (present)
              OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline), label: Text(l.aiKeyDelete)),
          ]),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: CambuseSpacing.sm),
              child: Text(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise)),
            ),
        ]),
      ),
    );
  }
}
