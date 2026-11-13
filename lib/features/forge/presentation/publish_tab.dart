import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/presentation/ai_providers.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../../workshop/domain/git_parsing.dart';
import '../../workshop/presentation/op_helper.dart';
import '../data/forge_client.dart';
import 'forge_providers.dart';

/// Onglet Publication : dépôt distant, push/pull via le compagnon, demandes de
/// fusion et tickets via l'API de la forge.
class PublishTab extends ConsumerStatefulWidget {
  const PublishTab({super.key, required this.path});
  final String path;
  @override
  ConsumerState<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends ConsumerState<PublishTab> {
  RemoteRef? _remote;
  bool _hasRemote = false;
  String? _branch;
  ForgeRepo? _repo;
  List<ForgeItem> _prs = const [];
  List<ForgeItem> _issues = const [];
  ForgeKind _kind = ForgeKind.github;
  final _repoName = TextEditingController();
  final _prTitle = TextEditingController();
  final _prBody = TextEditingController();
  final _issueTitle = TextEditingController();
  final _issueBody = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _error = false;

  CompanionClient get _client => ref.read(companionClientProvider);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    for (final c in [_repoName, _prTitle, _prBody, _issueTitle, _issueBody]) {
      c.dispose();
    }
    super.dispose();
  }

  Forge _forge(ForgeKind k) => ref.read(forgeFactoryProvider)(k, host: _remote?.kind == k ? _remote!.host : null);

  Future<OpStatus> _read(OpType t, [Map<String, dynamic> params = const {}]) async {
    final st = await _client.waitFor((await _client.submit(OpRequest(type: t.code, root: widget.path, params: params))).id);
    if (st.state != OpState.succeeded) {
      throw CompanionException('op_failed', [st.error, st.stderr.trim()].whereType<String>().where((s) => s.isNotEmpty).join('\n'));
    }
    return st;
  }

  /// [clearMessage] à faux : un rechargement ne doit pas effacer le message
  /// de confirmation de l'action qui vient de réussir.
  Future<void> _guard(Future<void> Function() f, {bool clearMessage = true}) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      if (clearMessage) _message = null;
    });
    try {
      await f();
    } on CompanionException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.code == ErrorCodes.forbiddenScope ? l.pbScopeMissing : e.message;
          _error = true;
        });
      }
    } on ForgeException catch (e) {
      if (mounted) {
        setState(() {
          _message = describeForgeError(l, e, _remote?.kind ?? _kind);
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Confirmation : message en ligne et notification (visible même si la
  /// liste a défilé loin du message).
  void _ok(String m) {
    setState(() {
      _message = m;
      _error = false;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() => _guard(() async {
        final remotes = (await _read(OpType.gitRemoteList)).stdout;
        final status = parsePorcelain((await _read(OpType.gitStatus)).stdout);
        final origin = remotes.split('\n').where((l) => l.startsWith('origin\t')).firstOrNull;
        final url = origin?.split('\t')[1].split(' ').first;
        setState(() {
          _hasRemote = origin != null;
          _remote = url == null ? null : RemoteRef.parse(url);
          _branch = status.branch;
          if (_remote != null) _kind = _remote!.kind;
        });
        if (_remote != null && (await ref.read(forgeTokenPresentProvider(_remote!.kind).future))) {
          final f = _forge(_remote!.kind);
          final repo = await f.repo(_remote!.fullName);
          final prs = await f.openChangeRequests(_remote!.fullName);
          final issues = await f.openIssues(_remote!.fullName);
          if (mounted) {
            setState(() {
              _repo = repo;
              _prs = prs;
              _issues = issues;
            });
          }
        }
      }, clearMessage: false);

  Future<String> _cloneUrl(String fullName) async {
    if (_kind == ForgeKind.github) return 'https://github.com/$fullName.git';
    final host = Uri.parse(await ref.read(gitlabUrlProvider.future)).host;
    return 'https://$host/$fullName.git';
  }

  Future<void> _link(String url) async {
    final out = await runCompanionOp(context, ref, OpRequest(type: OpType.gitRemoteAdd.code, root: widget.path, params: {'name': 'origin', 'url': url}));
    if (out.ok) await _load();
  }

  Future<void> _createPrivate() async {
    final l = AppLocalizations.of(context);
    final name = _repoName.text.trim().split('/').last;
    if (name.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pbCreateConfirmTitle),
        content: Text(l.pbCreateConfirmBody(name, _kind.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.pbCreate)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _guard(() async {
      final host = _kind == ForgeKind.gitlab ? Uri.parse(await ref.read(gitlabUrlProvider.future)).host : null;
      final repo = await ref.read(forgeFactoryProvider)(_kind, host: host).createPrivateRepo(name);
      await ref.read(logbookRepositoryProvider).record(
          category: 'forge', action: 'Dépôt privé créé', details: '${_kind.label} : ${repo.fullName}', outcome: AuditOutcome.success);
      if (mounted) await _link(repo.cloneUrl);
    });
  }

  Future<void> _push() async {
    final l = AppLocalizations.of(context);
    final branch = _branch;
    final remote = _remote;
    if (branch == null || remote == null) return;
    await _guard(() async {
      final out = (await _read(OpType.gitOutgoing, {'remote': 'origin', 'branch': branch})).result!;
      if (!mounted) return;
      final token = await ref.read(secretStoreProvider).read(forgeTokenKey(remote.kind));
      final st = await _client.submit(OpRequest(
        type: OpType.gitPush.code,
        root: widget.path,
        params: {'remote': 'origin', 'branch': branch, 'token': ?token},
      ));
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PushPanel(repo: _repo, remote: remote, branch: branch, outgoing: out, plan: st.plan),
      );
      final log = ref.read(logbookRepositoryProvider);
      if (confirmed != true) {
        await _client.reject(st.id);
        await log.record(category: 'forge', action: 'Publication refusée', details: '${remote.fullName} $branch', outcome: AuditOutcome.cancelled);
        _ok(l.compRejected);
        return;
      }
      await _client.approve(st.id);
      final done = await _client.waitFor(st.id, max: const Duration(minutes: 4));
      await log.record(
        category: 'forge',
        action: 'Publication (push)',
        details: '${remote.fullName} $branch → ${done.state.code}',
        outcome: done.state == OpState.succeeded ? AuditOutcome.success : AuditOutcome.failure,
      );
      if (done.state == OpState.succeeded) {
        _ok(l.pbPushed((done.result?['pushedCommits'] as int?) ?? 0));
        await _load();
      } else {
        setState(() {
          _message = [done.error, done.stderr.trim()].whereType<String>().where((s) => s.isNotEmpty).join('\n');
          _error = true;
        });
      }
    });
  }

  Future<void> _pull() async {
    final branch = _branch;
    final remote = _remote;
    if (branch == null || remote == null) return;
    await _guard(() async {
      final token = await ref.read(secretStoreProvider).read(forgeTokenKey(remote.kind));
      if (!mounted) return;
      final out = await runCompanionOp(context, ref,
          OpRequest(type: OpType.gitPull.code, root: widget.path, params: {'remote': 'origin', 'branch': branch, 'token': ?token}));
      if (out.status != null && mounted) {
        setState(() {
          _error = !out.ok;
          _message = [out.status!.stdout.trim(), out.status!.stderr.trim(), out.status!.error]
              .whereType<String>().where((s) => s.isNotEmpty).join('\n');
        });
      }
    });
  }

  Future<void> _createPr() => _guard(() async {
        final l = AppLocalizations.of(context);
        final item = await _forge(_remote!.kind).createChangeRequest(_remote!.fullName,
            head: _branch!, base: _repo!.defaultBranch, title: _prTitle.text.trim(), body: _prBody.text.trim());
        await ref.read(logbookRepositoryProvider).record(
            category: 'forge', action: 'Demande de fusion créée', details: item.url, outcome: AuditOutcome.success);
        _prTitle.clear();
        _prBody.clear();
        _ok(l.pbCreated(item.url));
        await _load();
        // Le listage de l'API peut ne pas encore voir l'élément créé.
        if (mounted && !_prs.any((p) => p.number == item.number)) setState(() => _prs = [item, ..._prs]);
      });

  Future<void> _createIssue() => _guard(() async {
        final l = AppLocalizations.of(context);
        final item = await _forge(_remote!.kind).createIssue(_remote!.fullName, title: _issueTitle.text.trim(), body: _issueBody.text.trim());
        await ref.read(logbookRepositoryProvider).record(
            category: 'forge', action: 'Ticket créé', details: item.url, outcome: AuditOutcome.success);
        _issueTitle.clear();
        _issueBody.clear();
        _ok(l.pbCreated(item.url));
        await _load();
        if (mounted && !_issues.any((i) => i.number == item.number)) setState(() => _issues = [item, ..._issues]);
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final text = Theme.of(context).textTheme;
    final tokenOk = ref.watch(forgeTokenPresentProvider(_remote?.kind ?? _kind)).value ?? false;
    final repo = _repo;
    final feedback = _message == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
            child: SelectableText(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise)),
          );

    Widget items(String title, List<ForgeItem> list, String empty) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleMedium),
            if (list.isEmpty) Text(empty, style: TextStyle(color: p.textSecondary)),
            for (final i in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('#${i.number}', style: TextStyle(color: p.gold, fontFamily: 'monospace')),
                title: Text(i.title),
                subtitle: SelectableText(i.url, style: TextStyle(color: p.textSecondary, fontSize: 12)),
              ),
          ],
        );

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        if (!tokenOk) ...[
          Text(l.pbNoToken((_remote?.kind ?? _kind).label), style: TextStyle(color: p.gold)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await context.push('/parametres/forges');
                ref.invalidate(forgeTokenPresentProvider);
                await _load();
              },
              icon: const Icon(Icons.key),
              label: Text(l.pbOpenForges),
            ),
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (!_hasRemote || _remote == null) feedback,
        if (!_hasRemote) ...[
          Text(l.pbNoRemote),
          const SizedBox(height: CambuseSpacing.sm),
          SegmentedButton<ForgeKind>(
            segments: [for (final k in ForgeKind.values) ButtonSegment(value: k, label: Text(k.label))],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          TextField(
            controller: _repoName,
            decoration: InputDecoration(labelText: l.pbRepoName),
            autocorrect: false,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
            FilledButton.icon(
              onPressed: _busy || !_repoName.text.trim().contains('/')
                  ? null
                  : () async => _link(await _cloneUrl(_repoName.text.trim())),
              icon: const Icon(Icons.link),
              label: Text(l.pbLink),
            ),
            OutlinedButton.icon(
              onPressed: _busy || !tokenOk ? null : _createPrivate,
              icon: const Icon(Icons.lock_outline),
              label: Text(l.pbCreatePrivate),
            ),
          ]),
        ],
        if (_hasRemote && _remote != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${_remote!.kind.label} · ${_remote!.fullName}', style: text.titleMedium)),
                  if (repo != null)
                    Chip(
                      avatar: Icon(repo.private ? Icons.lock : Icons.public, size: 16, color: repo.private ? p.turquoise : p.alert),
                      label: Text(repo.private ? l.pbPrivate : l.pbPublic),
                    ),
                ]),
                if (repo != null) ...[
                  Text(l.pbDefaultBranch(repo.defaultBranch), style: TextStyle(color: p.textSecondary)),
                  SelectableText(repo.webUrl, style: TextStyle(color: p.textSecondary, fontSize: 12)),
                ],
                if (_branch != null) Text(l.wsBranchLabel(_branch!)),
              ]),
            ),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
            FilledButton.icon(onPressed: _busy || !tokenOk ? null : _push, icon: const Icon(Icons.cloud_upload), label: Text(l.pbPush)),
            OutlinedButton.icon(onPressed: _busy || !tokenOk ? null : _pull, icon: const Icon(Icons.cloud_download), label: Text(l.pbPull)),
            IconButton(tooltip: l.wsRefresh, onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ]),
          feedback,
          if (repo != null) ...[
            const SizedBox(height: CambuseSpacing.lg),
            items(l.pbChangeRequests, _prs, l.pbNoChangeRequests),
            if (_branch != null && _branch != repo.defaultBranch) ...[
              const SizedBox(height: CambuseSpacing.sm),
              Text(l.pbNewChangeRequest(_branch!, repo.defaultBranch), style: text.titleSmall),
              TextField(controller: _prTitle, decoration: InputDecoration(labelText: l.pbTitleField), onChanged: (_) => setState(() {})),
              const SizedBox(height: CambuseSpacing.xs),
              TextField(controller: _prBody, decoration: InputDecoration(labelText: l.pbBodyField), maxLines: 3, minLines: 1),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _busy || _prTitle.text.trim().isEmpty ? null : _createPr,
                  child: Text(l.pbOpen),
                ),
              ),
            ],
            const SizedBox(height: CambuseSpacing.lg),
            items(l.pbIssues, _issues, l.pbNoIssues),
            const SizedBox(height: CambuseSpacing.sm),
            Text(l.pbNewIssue, style: text.titleSmall),
            TextField(controller: _issueTitle, decoration: InputDecoration(labelText: l.pbTitleField), onChanged: (_) => setState(() {})),
            const SizedBox(height: CambuseSpacing.xs),
            TextField(controller: _issueBody, decoration: InputDecoration(labelText: l.pbBodyField), maxLines: 3, minLines: 1),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _busy || _issueTitle.text.trim().isEmpty ? null : _createIssue,
                child: Text(l.pbCreate),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Panneau de publication (DESIGN « Interactions sensibles ») : dépôt,
/// visibilité, branche, commits, fichiers, détection de secrets, action exacte.
class _PushPanel extends StatelessWidget {
  const _PushPanel({required this.repo, required this.remote, required this.branch, required this.outgoing, required this.plan});

  final ForgeRepo? repo;
  final RemoteRef remote;
  final String branch;
  final Map<String, dynamic> outgoing;
  final List<String> plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final commits = (outgoing['commits'] as List).cast<Map<String, dynamic>>();
    final files = (outgoing['files'] as List).cast<String>();
    final secrets = (outgoing['secrets'] as List).cast<Map<String, dynamic>>();
    final blocked = secrets.isNotEmpty || (outgoing['largeFiles'] as List).isNotEmpty;
    final nothing = commits.isEmpty;
    final public = repo != null && !repo!.private;
    return AlertDialog(
      icon: Icon(blocked ? Icons.dangerous : Icons.cloud_upload, color: blocked ? p.alert : p.gold, size: 36),
      title: Text(l.pbPanelTitle(remote.fullName)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (repo != null)
            Chip(
              avatar: Icon(repo!.private ? Icons.lock : Icons.public, size: 16),
              label: Text(repo!.private ? l.pbPrivate : l.pbPublic),
            ),
          if (public) Text(l.pbPanelPublicWarning, style: TextStyle(color: p.alert, fontWeight: FontWeight.w700)),
          Text(l.pbPanelBranch(branch)),
          if (outgoing['remoteBranchExists'] != true) Text(l.pbPanelNewBranch, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: CambuseSpacing.sm),
          if (nothing) Text(l.pbPanelNothing),
          if (!nothing) ...[
            Text(l.pbPanelCommits(commits.length), style: const TextStyle(fontWeight: FontWeight.w700)),
            for (final c in commits.take(10)) Text('${c['sha']}  ${c['subject']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: CambuseSpacing.xs),
            Text(l.pbPanelFiles(files.length), style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(files.take(15).join(', '), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
          const SizedBox(height: CambuseSpacing.sm),
          Text(blocked ? l.pbPanelSecretsKo : l.pbPanelSecretsOk, style: TextStyle(color: blocked ? p.alert : p.turquoise)),
          for (final s in secrets.take(5))
            Text('${s['file']}${s['line'] == null ? '' : ':${s['line']}'} — ${s['kind']}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: p.alert)),
          const SizedBox(height: CambuseSpacing.sm),
          for (final line in plan.where((l) => l.startsWith('Commande exacte') || l.startsWith('Jamais')))
            SelectableText(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(blocked || nothing ? l.cancel : l.compReject)),
        if (!blocked && !nothing) FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.pbPublish)),
      ],
    );
  }
}
