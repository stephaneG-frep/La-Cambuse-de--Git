import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../workshop/presentation/op_helper.dart';

/// Onglet Docker d'un projet : analyse statique et génération de modèle.
class DockerTab extends ConsumerStatefulWidget {
  const DockerTab({super.key, required this.path});
  final String path;
  @override
  ConsumerState<DockerTab> createState() => _DockerTabState();
}

class _DockerTabState extends ConsumerState<DockerTab> {
  Map<String, dynamic>? _lint;
  bool _busy = false;
  String? _message;
  bool _error = false;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final client = ref.read(companionClientProvider);
      final st = await client.waitFor((await client.submit(OpRequest(type: OpType.dockerLint.code, root: widget.path))).id);
      if (!mounted) return;
      setState(() => _lint = st.result);
    } on CompanionException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate(String template) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final out = await runCompanionOp(context, ref,
          OpRequest(type: OpType.dockerScaffold.code, root: widget.path, params: {'template': template}));
      if (!mounted) return;
      setState(() {
        _error = !out.ok && !out.rejected;
        _message = out.rejected ? l.compRejected : out.ok ? l.wsOpDone('docker.scaffold') : (out.status?.error ?? l.wsOpFailed('docker.scaffold'));
      });
      if (out.ok) await _run();
    } on CompanionException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final lint = _lint;
    final files = ((lint?['files'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final template = lint?['suggestedTemplate'] as String?;
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Text(l.dkLintIntro, style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: CambuseSpacing.sm),
        Align(alignment: Alignment.centerLeft,
            child: FilledButton.icon(onPressed: _busy ? null : _run, icon: const Icon(Icons.fact_check), label: Text(l.dkRunLint))),
        if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: CambuseSpacing.sm), child: LinearProgressIndicator()),
        if (_message != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
          child: SelectableText(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise)),
        ),
        if (lint != null) ...[
          if (lint['flutterNote'] != null)
            Card(child: ListTile(leading: Icon(Icons.flutter_dash, color: p.turquoise), title: Text('${lint['flutterNote']}'))),
          if (files.isEmpty) Text(l.dkNoFiles),
          if (lint['hasDockerignore'] != true && files.isNotEmpty) Text(l.dkNoDockerignore, style: TextStyle(color: p.gold)),
          for (final f in files) ...[
            const SizedBox(height: CambuseSpacing.sm),
            Text('${f['path']}', style: TextStyle(fontFamily: 'monospace', color: p.gold)),
            if ((f['findings'] as List).isEmpty) Text(l.labNoFinding, style: TextStyle(color: p.turquoise)),
            for (final x in (f['findings'] as List).cast<Map<String, dynamic>>().map(LintFinding.fromJson))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (x.severity) { LintSeverity.blocking => Icons.dangerous, LintSeverity.warning => Icons.warning_amber, LintSeverity.info => Icons.info_outline },
                  color: switch (x.severity) { LintSeverity.blocking => p.alert, LintSeverity.warning => p.gold, LintSeverity.info => p.textSecondary },
                  semanticLabel: switch (x.severity) { LintSeverity.blocking => l.wsBlocking, LintSeverity.warning => l.wsWarning, LintSeverity.info => l.wsInfo },
                ),
                title: Text('${x.rule} · ${x.message}'),
                subtitle: Text([if (x.line != null) l.labLine(x.line!), if (x.fix != null) l.labFix(x.fix!)].join(' — '),
                    style: TextStyle(color: p.textSecondary, fontSize: 12)),
              ),
          ],
          if (template != null && !files.any((f) => f['kind'] == 'dockerfile')) ...[
            const SizedBox(height: CambuseSpacing.md),
            Align(alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(onPressed: _busy ? null : () => _generate(template), icon: const Icon(Icons.note_add_outlined),
                    label: Text(l.dkGenerate(template)))),
          ],
        ],
      ],
    );
  }
}
