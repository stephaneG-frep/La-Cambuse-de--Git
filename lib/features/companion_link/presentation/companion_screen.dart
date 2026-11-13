import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../data/companion_client.dart';

final companionClientProvider = Provider(
  (ref) => CompanionClient(db: ref.watch(databaseProvider), secrets: ref.watch(secretStoreProvider)),
);

final companionLinkProvider = FutureProvider<CompanionLink?>(
  (ref) => ref.watch(companionClientProvider).link(),
);

/// Paramètres → Compagnon Linux : appairage, informations, opérations
/// typées avec approbation explicite, journal du compagnon.
class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.compTitle)),
      body: ref.watch(companionLinkProvider).when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e),
            data: (link) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: link == null ? const _PairForm() : _PairedView(link: link),
              ),
            ),
          ),
    );
  }
}

class _PairForm extends ConsumerStatefulWidget {
  const _PairForm();

  @override
  ConsumerState<_PairForm> createState() => _PairFormState();
}

class _PairFormState extends ConsumerState<_PairForm> {
  final _address = TextEditingController(text: 'http://127.0.0.1:$defaultLoopbackPort');
  final _fingerprint = TextEditingController();
  final _name = TextEditingController(text: Platform.isAndroid ? 'Téléphone Android' : 'Application Linux');
  final _code = TextEditingController();
  String? _message;
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_address, _fingerprint, _name, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _fp => _fingerprint.text.trim().isEmpty ? null : _fingerprint.text.trim();

  Future<void> _run(Future<String> Function() f) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final m = await f();
      setState(() {
        _message = m;
        _error = false;
      });
    } on CompanionException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final client = ref.read(companionClientProvider);
    final https = _address.text.trim().startsWith('https');
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(CambuseSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.compIntro),
              const SizedBox(height: CambuseSpacing.md),
              Text(l.compHostSteps, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: CambuseSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CambuseSpacing.sm),
                color: p.night,
                child: SelectableText(
                  'cambuse-companion serve --root ~/Projets\ncambuse-companion pair --scopes read,git-write,remote,docker,build',
                  style: TextStyle(fontFamily: 'monospace', color: p.turquoise),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: CambuseSpacing.md),
        TextField(
          controller: _address,
          decoration: InputDecoration(labelText: l.compAddress),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
        ),
        if (https) ...[
          const SizedBox(height: CambuseSpacing.sm),
          TextField(
            controller: _fingerprint,
            decoration: InputDecoration(labelText: l.compFingerprint),
            autocorrect: false,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
        const SizedBox(height: CambuseSpacing.sm),
        TextField(controller: _name, decoration: InputDecoration(labelText: l.compDeviceName)),
        const SizedBox(height: CambuseSpacing.sm),
        TextField(
          controller: _code,
          decoration: InputDecoration(labelText: l.compCode),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final h = await client.health(_address.text, fingerprint: _fp);
                      return l.compReachable('${h['apiVersion']}');
                    }),
            icon: const Icon(Icons.wifi_tethering),
            label: Text(l.compCheck),
          ),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final link = await client.pair(
                        baseUrl: _address.text,
                        code: _code.text,
                        deviceName: _name.text,
                        fingerprint: _fp,
                      );
                      await ref.read(logbookRepositoryProvider).record(
                            category: 'compagnon',
                            action: 'Appairage réussi',
                            details: '${link.baseUrl} — portées ${link.scopes.map((s) => s.code).join(', ')}',
                            outcome: AuditOutcome.success,
                          );
                      ref.invalidate(companionLinkProvider);
                      return l.compPairedOk;
                    }),
            icon: const Icon(Icons.link),
            label: Text(l.compPair),
          ),
        ]),
        if (_message != null) ...[
          const SizedBox(height: CambuseSpacing.sm),
          Text(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise)),
        ],
      ],
    );
  }
}

class _PairedView extends ConsumerStatefulWidget {
  const _PairedView({required this.link});

  final CompanionLink link;

  @override
  ConsumerState<_PairedView> createState() => _PairedViewState();
}

class _PairedViewState extends ConsumerState<_PairedView> {
  final _folder = TextEditingController();
  List<String> _roots = const [];
  List<Map<String, dynamic>> _projects = const [];
  String? _git;
  OpStatus? _result;
  List<Map<String, dynamic>>? _audit;
  String? _message;
  bool _error = false;
  bool _busy = false;

  CompanionClient get _client => ref.read(companionClientProvider);

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInfo);
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await f();
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

  Future<void> _loadInfo() => _guard(() async {
        final st = await _client.waitFor((await _client.submit(OpRequest(type: OpType.systemInfo.code))).id);
        final roots = ((st.result?['roots'] as List?) ?? const []).cast<String>();
        setState(() {
          _roots = roots;
          _git = st.result?['git'] as String?;
          if (_folder.text.isEmpty && roots.isNotEmpty) _folder.text = roots.first;
          _message = null;
        });
        if (roots.isNotEmpty) await _listProjects(roots.first);
      });

  /// Liste les sous-dossiers d'un dossier autorisé : évite de taper des
  /// chemins sur un téléphone.
  Future<void> _listProjects(String root) async {
    final st = await _client.waitFor((await _client.submit(OpRequest(type: OpType.projectList.code, root: root))).id);
    if (!mounted) return;
    setState(() => _projects = ((st.result?['projects'] as List?) ?? const []).cast<Map<String, dynamic>>());
  }

  Future<void> _op(OpType type) => _guard(() async {
        final log = ref.read(logbookRepositoryProvider);
        var st = await _client.submit(OpRequest(type: type.code, root: _folder.text.trim()));
        if (st.state == OpState.awaitingApproval) {
          if (!mounted) return;
          final ok = await showApprovalDialog(context, st);
          if (ok != true) {
            st = await _client.reject(st.id);
            await log.record(category: 'compagnon', action: 'Opération refusée', details: '${type.code} — ${_folder.text}', outcome: AuditOutcome.cancelled);
            if (mounted) {
              setState(() {
                _result = st;
                _message = AppLocalizations.of(context).compRejected;
                _error = false;
              });
            }
            return;
          }
          await _client.approve(st.id);
          await log.record(category: 'compagnon', action: 'Opération autorisée', details: '${type.code} — ${_folder.text}', outcome: AuditOutcome.info);
        }
        st = await _client.waitFor(st.id);
        await log.record(
          category: 'compagnon',
          action: 'Opération ${type.code}',
          details: '${_folder.text} → ${st.state.code}',
          outcome: st.state == OpState.succeeded ? AuditOutcome.success : AuditOutcome.failure,
        );
        if (mounted) setState(() => _result = st);
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final link = widget.link;
    final canWrite = link.scopes.contains(Scope.gitWrite);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.link, color: p.turquoise),
            title: Text(l.compPaired(link.baseUrl)),
            subtitle: Text(
              [l.compScopes(link.scopes.map((s) => s.code).join(', ')), if (_git != null) l.compGit(_git!)].join('\n'),
              style: TextStyle(color: p.textSecondary),
            ),
            isThreeLine: _git != null,
          ),
        ),
        const SizedBox(height: CambuseSpacing.md),
        Text(l.compRoots, style: text.titleMedium),
        for (final r in _roots)
          ListTile(
            dense: true,
            leading: Icon(Icons.folder_outlined, color: p.copper),
            title: Text(r, style: const TextStyle(fontFamily: 'monospace')),
            onTap: () {
              setState(() => _folder.text = r);
              _guard(() => _listProjects(r));
            },
          ),
        if (_projects.isNotEmpty)
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
            for (final pr in _projects)
              ChoiceChip(
                avatar: Icon(pr['git'] == true ? Icons.account_tree : Icons.folder_outlined, size: 18),
                label: Text(pr['name'] as String),
                selected: _folder.text == pr['path'],
                onSelected: (_) => setState(() => _folder.text = pr['path'] as String),
              ),
          ]),
        const SizedBox(height: CambuseSpacing.sm),
        TextField(
          controller: _folder,
          decoration: InputDecoration(labelText: l.compFolder),
          style: const TextStyle(fontFamily: 'monospace'),
          autocorrect: false,
        ),
        const SizedBox(height: CambuseSpacing.sm),
        Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _op(OpType.gitStatus),
            icon: const Icon(Icons.visibility_outlined),
            label: Text('${l.compGitStatus} · ${l.compReadOnly}'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _op(OpType.projectDetect),
            icon: const Icon(Icons.travel_explore),
            label: Text('${l.compDetect} · ${l.compReadOnly}'),
          ),
          if (canWrite)
            FilledButton.icon(
              onPressed: _busy ? null : () => _op(OpType.gitInit),
              icon: const Icon(Icons.add_box_outlined),
              label: Text('${l.compGitInit} · ${l.compMutating}'),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _loadInfo,
            icon: const Icon(Icons.refresh),
            label: Text(l.compCheck),
          ),
        ]),
        if (_busy) const Padding(padding: EdgeInsets.all(CambuseSpacing.sm), child: LinearProgressIndicator()),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: CambuseSpacing.sm),
            child: Text(_message!, style: TextStyle(color: _error ? p.alert : p.gold)),
          ),
        if (_result != null) ...[
          const SizedBox(height: CambuseSpacing.md),
          _ResultCard(status: _result!),
        ],
        const SizedBox(height: CambuseSpacing.lg),
        Row(children: [
          Expanded(child: Text(l.compAudit, style: text.titleMedium)),
          IconButton(
            tooltip: l.compAudit,
            icon: const Icon(Icons.history),
            onPressed: _busy ? null : () => _guard(() async {
              final a = await _client.audit();
              if (mounted) setState(() => _audit = a);
            }),
          ),
        ]),
        if (_audit != null && _audit!.isEmpty) Text(l.compAuditEmpty),
        for (final e in _audit ?? const <Map<String, dynamic>>[])
          Text('${e['ts']}  ${e['event']}  ${e['type'] ?? e['state'] ?? ''}',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: p.textSecondary)),
        const SizedBox(height: CambuseSpacing.lg),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l.compForget),
                content: SelectableText(l.compForgetBody(link.deviceId)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.compForget)),
                ],
              ),
            );
            if (ok == true) {
              await _client.forget();
              await ref.read(logbookRepositoryProvider).record(
                  category: 'compagnon', action: 'Compagnon oublié', details: link.baseUrl, outcome: AuditOutcome.info);
              ref.invalidate(companionLinkProvider);
            }
          },
          icon: const Icon(Icons.link_off),
          label: Text(l.compForget),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.status});

  final OpStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final ok = status.state == OpState.succeeded;
    final body = [
      if (status.stdout.isNotEmpty) status.stdout.trimRight(),
      if (status.stderr.isNotEmpty) status.stderr.trimRight(),
      if (status.result != null) status.result!.entries.map((e) => '${e.key} : ${e.value}').join('\n'),
      if (status.error != null) status.error!,
    ].join('\n');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ok ? Icons.check_circle : Icons.info_outline, color: ok ? p.turquoise : p.gold),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(child: Text('${l.compResult} — ${status.type} · ${l.compState(status.state.code)}')),
          ]),
          const SizedBox(height: CambuseSpacing.xs),
          for (final line in status.plan) Text(line, style: TextStyle(color: p.textSecondary, fontSize: 12)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: CambuseSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CambuseSpacing.sm),
              color: p.night,
              child: SelectableText(body, style: TextStyle(fontFamily: 'monospace', color: p.text, fontSize: 13)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Panneau de consentement : dossier, commande exacte, conséquences. Aucune
/// option « toujours autoriser ».
Future<bool?> showApprovalDialog(BuildContext context, OpStatus st) {
  final l = AppLocalizations.of(context);
  final p = CambuseTheme.of(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.gpp_maybe, color: p.gold, size: 36),
      title: Text(l.compApproveTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(st.type, style: TextStyle(color: p.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: CambuseSpacing.sm),
          for (final line in st.plan)
            Padding(
              padding: const EdgeInsets.only(bottom: CambuseSpacing.xs),
              child: SelectableText(line, style: const TextStyle(fontFamily: 'monospace')),
            ),
          const SizedBox(height: CambuseSpacing.sm),
          Text(OpType.fromCode(st.type)?.scope == Scope.build ? l.compApproveWarningBuild : l.compApproveWarning,
              style: TextStyle(color: p.alert)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.compReject)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.compApprove)),
      ],
    ),
  );
}
