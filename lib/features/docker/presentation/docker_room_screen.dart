import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';

/// Salle des machines : inspection du démon Docker de l'hôte, en lecture
/// seule (diagnostic, images, conteneurs, journaux masqués).
class DockerRoomScreen extends ConsumerStatefulWidget {
  const DockerRoomScreen({super.key});
  @override
  ConsumerState<DockerRoomScreen> createState() => _DockerRoomScreenState();
}

class _DockerRoomScreenState extends ConsumerState<DockerRoomScreen> {
  Map<String, dynamic>? _info;
  List<Map<String, dynamic>> _images = const [];
  List<Map<String, dynamic>> _containers = const [];
  bool _busy = false;
  String? _error;

  CompanionClient get _client => ref.read(companionClientProvider);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<Map<String, dynamic>> _read(OpType t, [Map<String, dynamic> params = const {}]) async {
    final st = await _client.waitFor((await _client.submit(OpRequest(type: t.code, params: params))).id);
    if (st.state != OpState.succeeded) throw CompanionException('op_failed', st.error ?? st.stderr);
    return st.result ?? const {};
  }

  Future<void> _load() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await _read(OpType.dockerInfo);
      final images = info['available'] == true ? await _read(OpType.dockerImages) : const <String, dynamic>{};
      final containers = info['available'] == true ? await _read(OpType.dockerContainers) : const <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _info = info;
        _images = ((images['images'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _containers = ((containers['containers'] as List?) ?? const []).cast<Map<String, dynamic>>();
      });
    } on CompanionException catch (e) {
      if (mounted) setState(() => _error = e.code == ErrorCodes.forbiddenScope ? l.dkScopeMissing : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logs(Map<String, dynamic> c) async {
    final l = AppLocalizations.of(context);
    final name = '${c['Names'] ?? c['ID']}';
    try {
      final r = await _read(OpType.dockerLogs, {'container': '${c['ID']}', 'tail': 200});
      if (!mounted) return;
      final p = CambuseTheme.of(context);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              Text(l.dkLogs(name), style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: CambuseSpacing.sm),
              SelectableText('${r['logs']}', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: p.text)),
            ],
          ),
        ),
      );
    } on CompanionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final i = _info;
    final notes = ((i?['notes'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l.dkRoom,
          subtitle: l.dkRoomSubtitle,
          trailing: IconButton(tooltip: l.wsRefresh, onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            children: [
              Text(l.dkReadOnly, style: TextStyle(color: p.textSecondary)),
              if (_error != null) Padding(
                padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
                child: Text(_error!, style: TextStyle(color: p.alert)),
              ),
              if (i != null) Card(
                child: Padding(
                  padding: const EdgeInsets.all(CambuseSpacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(i['available'] == true ? Icons.check_circle : Icons.cloud_off,
                          color: i['available'] == true ? p.turquoise : p.gold),
                      const SizedBox(width: CambuseSpacing.sm),
                      Expanded(child: Text(i['available'] == true ? l.dkServer('${i['server']}') : l.dkUnavailable,
                          style: Theme.of(context).textTheme.titleMedium)),
                      if (i['rootless'] == true) Chip(label: Text(l.dkRootless)),
                    ]),
                    if (i['available'] == true)
                      Text(l.dkCounts('${i['containers']}', '${i['running']}', '${i['images']}'), style: TextStyle(color: p.textSecondary)),
                    for (final n in notes)
                      Padding(
                        padding: const EdgeInsets.only(top: CambuseSpacing.xs),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(n['severity'] == 'warning' ? Icons.warning_amber : Icons.info_outline, size: 18,
                              color: n['severity'] == 'warning' ? p.gold : p.textSecondary),
                          const SizedBox(width: CambuseSpacing.xs),
                          Expanded(child: Text('${n['message']}')),
                        ]),
                      ),
                  ]),
                ),
              ),
              if (_containers.isNotEmpty) ...[
                const SizedBox(height: CambuseSpacing.md),
                Text(l.dkContainers, style: Theme.of(context).textTheme.titleMedium),
                for (final c in _containers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(c['State'] == 'running' ? Icons.play_circle : Icons.stop_circle,
                        color: c['State'] == 'running' ? p.turquoise : p.textSecondary, semanticLabel: '${c['State']}'),
                    title: Text('${c['Names']}', style: const TextStyle(fontFamily: 'monospace')),
                    subtitle: Text('${c['Image']} · ${c['Status']}', style: TextStyle(color: p.textSecondary)),
                    trailing: IconButton(tooltip: l.dkLogs('${c['Names']}'), icon: const Icon(Icons.article_outlined), onPressed: () => _logs(c)),
                  ),
              ],
              if (_images.isNotEmpty) ...[
                const SizedBox(height: CambuseSpacing.md),
                Text(l.dkImages, style: Theme.of(context).textTheme.titleMedium),
                for (final img in _images)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.inventory_2_outlined, color: p.copper),
                    title: Text('${img['Repository']}:${img['Tag']}', style: const TextStyle(fontFamily: 'monospace')),
                    trailing: Text('${img['Size']}', style: TextStyle(color: p.textSecondary)),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
