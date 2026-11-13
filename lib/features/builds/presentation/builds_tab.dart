import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../workshop/presentation/op_helper.dart';

/// Taille lisible (octets → Ko/Mo/Go, base 1024).
String formatBytes(int b) {
  const units = ['o', 'Ko', 'Mo', 'Go'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '$b o' : '${v.toStringAsFixed(1)} ${units[i]}';
}

/// Onglet Builds d'un projet : génération de CI, analyse/tests/builds Flutter
/// approuvés, et « Cale des artefacts » (tailles, SHA-256, signature, ABI).
class BuildsTab extends ConsumerStatefulWidget {
  const BuildsTab({super.key, required this.path});
  final String path;
  @override
  ConsumerState<BuildsTab> createState() => _BuildsTabState();
}

class _BuildsTabState extends ConsumerState<BuildsTab> {
  String _kind = 'flutter';
  String _provider = 'github';
  bool _busy = false;
  String? _message;
  bool _error = false;
  OpStatus? _last;
  Map<String, dynamic>? _hold;

  void _fail(Object e) {
    final l = AppLocalizations.of(context);
    setState(() {
      _error = true;
      _message = e is CompanionException
          ? (e.code == ErrorCodes.forbiddenScope ? l.bdScopeMissing : e.message)
          : '$e';
    });
  }

  Future<void> _op(OpRequest req, {Duration max = const Duration(minutes: 6)}) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
      _last = null;
    });
    try {
      final out = await runCompanionOp(context, ref, req, max: max);
      if (!mounted) return;
      setState(() {
        _last = out.status;
        _error = !out.ok && !out.rejected;
        _message = out.rejected
            ? l.compRejected
            : out.ok
                ? l.wsOpDone(req.type)
                : (out.status?.error ?? l.wsOpFailed(req.type));
      });
      // Le résultat s'affiche en haut de l'onglet : on le signale aussi en bas
      // d'écran, l'utilisateur ayant souvent fait défiler jusqu'aux boutons.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message!)));
      if (out.ok && req.type != OpType.ciScaffold.code) await _inspect(quiet: true);
    } catch (e) {
      if (mounted) _fail(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _inspect({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _busy = true;
        _message = null;
      });
    }
    try {
      final client = ref.read(companionClientProvider);
      final st = await client.waitFor(
          (await client.submit(OpRequest(type: OpType.artifactsList.code, root: widget.path))).id,
          max: const Duration(minutes: 2));
      if (!mounted) return;
      setState(() {
        if (st.state == OpState.succeeded) {
          _hold = st.result;
        } else {
          _error = true;
          _message = st.error;
        }
      });
    } catch (e) {
      if (mounted) _fail(e);
    } finally {
      if (mounted && !quiet) setState(() => _busy = false);
    }
  }

  String _tail(String s, [int n = 25]) {
    final lines = s.trimRight().split('\n');
    return lines.length <= n ? lines.join('\n') : '…\n${lines.sublist(lines.length - n).join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final h = Theme.of(context).textTheme.titleMedium?.copyWith(color: p.gold);
    final last = _last;
    final artifacts = ((_hold?['artifacts'] as List?) ?? const []).cast<Map<String, dynamic>>();
    const build = Duration(minutes: 26);

    Widget runButton(OpType t, String label, IconData icon, {Duration max = build}) => OutlinedButton.icon(
          onPressed: _busy ? null : () => _op(OpRequest(type: t.code, root: widget.path), max: max),
          icon: Icon(icon),
          label: Text(label),
        );

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Text(l.bdIntro, style: TextStyle(color: p.textSecondary)),
        if (_busy) ...[
          const SizedBox(height: CambuseSpacing.sm),
          const LinearProgressIndicator(),
          Text(l.bdRunning, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ],
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
            child: SelectableText(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise)),
          ),
        if (last != null && last.exitCode != null) ...[
          Text(l.bdResult(last.type, '${last.exitCode}'),
              style: TextStyle(color: last.exitCode == 0 ? p.turquoise : p.alert, fontWeight: FontWeight.w600)),
          if ('${last.stdout}${last.stderr}'.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: CambuseSpacing.xs, bottom: CambuseSpacing.sm),
              padding: const EdgeInsets.all(CambuseSpacing.sm),
              decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(CambuseSpacing.radius)),
              child: SelectableText(_tail('${last.stdout}\n${last.stderr}'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
        ],

        // --- Intégration continue ---
        const SizedBox(height: CambuseSpacing.md),
        Semantics(header: true, child: Text(l.bdCiTitle, style: h)),
        Text(l.bdCiIntro, style: TextStyle(color: p.textSecondary, fontSize: 13)),
        const SizedBox(height: CambuseSpacing.sm),
        Wrap(spacing: CambuseSpacing.md, runSpacing: CambuseSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownMenu<String>(
            initialSelection: _kind,
            label: Text(l.bdCiKind),
            onSelected: (v) => setState(() => _kind = v ?? _kind),
            dropdownMenuEntries: [for (final k in ciTemplateKinds) DropdownMenuEntry(value: k, label: k)],
          ),
          DropdownMenu<String>(
            initialSelection: _provider,
            label: Text(l.bdCiProvider),
            onSelected: (v) => setState(() => _provider = v ?? _provider),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'github', label: 'GitHub Actions'),
              DropdownMenuEntry(value: 'gitlab', label: 'GitLab CI'),
            ],
          ),
        ]),
        const SizedBox(height: CambuseSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _op(OpRequest(
                    type: OpType.ciScaffold.code, root: widget.path, params: {'kind': _kind, 'provider': _provider})),
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(l.bdCiGenerate),
          ),
        ),
        Text(ciFileName(_provider), style: TextStyle(fontFamily: 'monospace', color: p.textSecondary, fontSize: 12)),

        // --- Builds ---
        const SizedBox(height: CambuseSpacing.lg),
        Semantics(header: true, child: Text(l.bdRunTitle, style: h)),
        const SizedBox(height: CambuseSpacing.sm),
        Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
          runButton(OpType.flutterAnalyze, l.bdAnalyze, Icons.fact_check_outlined, max: const Duration(minutes: 10)),
          runButton(OpType.flutterTest, l.bdTest, Icons.science_outlined),
          runButton(OpType.flutterBuildApkDebug, l.bdApkDebug, Icons.android),
          runButton(OpType.flutterBuildLinux, l.bdLinux, Icons.computer),
        ]),
        const SizedBox(height: CambuseSpacing.xs),
        Text(l.bdApkDebugNote, style: TextStyle(color: p.gold, fontSize: 12)),

        // --- Cale des artefacts ---
        const SizedBox(height: CambuseSpacing.lg),
        Semantics(header: true, child: Text(l.bdHoldTitle, style: h)),
        Text(l.bdHoldIntro, style: TextStyle(color: p.textSecondary, fontSize: 13)),
        const SizedBox(height: CambuseSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _inspect, icon: const Icon(Icons.inventory_2_outlined), label: Text(l.bdHoldRefresh)),
        ),
        if (_hold != null && artifacts.isEmpty)
          Padding(padding: const EdgeInsets.only(top: CambuseSpacing.sm), child: Text(l.bdHoldEmpty)),
        for (final a in artifacts) _ArtifactCard(a),
      ],
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  const _ArtifactCard(this.a);
  final Map<String, dynamic> a;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final sig = (a['signature'] as Map?)?.cast<String, dynamic>();
    final abis = ((a['abis'] as List?) ?? const []).cast<String>();
    final sha = '${a['sha256']}';
    final (sigLabel, sigColor, sigIcon) = switch (sig?['status']) {
      'debug' => (l.bdSigDebug, p.gold, Icons.warning_amber),
      'release' => (l.bdSigRelease, p.turquoise, Icons.verified_outlined),
      'invalide' => (l.bdSigInvalid, p.alert, Icons.dangerous),
      _ => (l.bdSigUnknown, p.textSecondary, Icons.help_outline),
    };
    return Card(
      margin: const EdgeInsets.only(top: CambuseSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${a['path']}', style: TextStyle(fontFamily: 'monospace', color: p.gold, fontSize: 13)),
          const SizedBox(height: CambuseSpacing.xs),
          Text('${a['kind']} · ${formatBytes(a['bytes'] as int)}', style: TextStyle(color: p.textSecondary)),
          if (a['kind'] == 'apk') ...[
            const SizedBox(height: CambuseSpacing.xs),
            Row(children: [
              Icon(sigIcon, color: sigColor, size: 18),
              const SizedBox(width: CambuseSpacing.xs),
              Flexible(child: Text(sigLabel, style: TextStyle(color: sigColor, fontWeight: FontWeight.w600))),
            ]),
            if ('${sig?['certificate'] ?? ''}'.isNotEmpty)
              Text('${sig!['certificate']}', style: TextStyle(color: p.textSecondary, fontSize: 12)),
            if (abis.isNotEmpty) Text(l.bdAbis(abis.join(', ')), style: TextStyle(color: p.textSecondary, fontSize: 12)),
          ],
          Row(children: [
            Expanded(
              child: SelectableText('SHA-256 $sha', style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
            ),
            IconButton(
              tooltip: l.bdCopySha,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sha));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.bdCopied)));
                }
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
