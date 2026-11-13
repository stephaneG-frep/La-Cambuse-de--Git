import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_header.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../domain/git_parsing.dart';
import 'op_helper.dart';
import 'widgets/diff_view.dart';

String _size(int bytes) => bytes >= 1048576
    ? '${(bytes / 1048576).toStringAsFixed(1)} Mo'
    : bytes >= 1024
        ? '${(bytes / 1024).toStringAsFixed(0)} Ko'
        : '$bytes octets';

/// Chemin abrégé aux deux derniers dossiers (le chemin complet reste
/// annoncé aux lecteurs d'écran).
String shortPath(String path) {
  final parts = path.split('/').where((s) => s.isNotEmpty).toList();
  return parts.length <= 2 ? path : '…/${parts.sublist(parts.length - 2).join('/')}';
}

/// Fiche d'un projet de l'Atelier.
class WorkshopProjectScreen extends StatelessWidget {
  const WorkshopProjectScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= CambuseBreakpoints.rail;
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: path,
            child: PageHeader(title: path.split('/').last, subtitle: shortPath(path), subtitleMaxLines: 1),
          ),
          TabBar(
            isScrollable: !wide,
            tabAlignment: wide ? null : TabAlignment.start,
            labelColor: p.gold,
            unselectedLabelColor: p.textSecondary,
            indicatorColor: p.copper,
            tabs: [
              Tab(text: l.wsTabAudit),
              Tab(text: l.wsTabChanges),
              Tab(text: l.wsTabHistory),
              Tab(text: l.wsTabBackups),
            ],
          ),
          Expanded(
            child: TabBarView(children: [
              _AuditTab(path: path),
              _ChangesTab(path: path),
              _HistoryTab(path: path),
              _BackupsTab(path: path),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Base commune : exécution d'opérations, état occupé, message d'erreur.
mixin _OpsState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? message;
  bool error = false;

  String get projectPath;

  CompanionClient get client => ref.read(companionClientProvider);

  Future<OpStatus?> read(OpType type, [Map<String, dynamic> params = const {}]) async {
    final st = await client.waitFor((await client.submit(OpRequest(type: type.code, root: projectPath, params: params))).id);
    if (st.state != OpState.succeeded) {
      throw CompanionException('op_failed', [st.error, st.stderr.trim()].whereType<String>().where((s) => s.isNotEmpty).join('\n'));
    }
    return st;
  }

  Future<void> guard(Future<void> Function() f) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await f();
    } on CompanionException catch (e) {
      if (mounted) {
        setState(() {
          message = e.message;
          error = true;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Opération avec approbation éventuelle ; renvoie vrai si réussie.
  Future<bool> mutate(OpType type, [Map<String, dynamic> params = const {}]) async {
    final l = AppLocalizations.of(context);
    var ok = false;
    await guard(() async {
      final out = await runCompanionOp(context, ref, OpRequest(type: type.code, root: projectPath, params: params));
      if (out.rejected) {
        setState(() {
          message = l.compRejected;
          error = false;
        });
        return;
      }
      final st = out.status!;
      ok = out.ok;
      setState(() {
        error = !ok;
        message = ok
            ? [l.wsOpDone(type.code), if (st.result?['restoredTo'] != null) l.wsRestoredTo('${st.result!['restoredTo']}')].join('\n')
            : [l.wsOpFailed(type.code), st.error, st.stderr.trim()].whereType<String>().where((s) => s.isNotEmpty).join('\n');
      });
    });
    return ok;
  }

  Widget feedback(BuildContext context) {
    final p = CambuseTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (busy) const Padding(padding: EdgeInsets.symmetric(vertical: CambuseSpacing.sm), child: LinearProgressIndicator()),
      if (message != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
          child: SelectableText(message!, style: TextStyle(color: error ? p.alert : p.turquoise)),
        ),
    ]);
  }
}

// ------------------------------------------------------------------ Audit

class _AuditTab extends ConsumerStatefulWidget {
  const _AuditTab({required this.path});
  final String path;
  @override
  ConsumerState<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<_AuditTab> with _OpsState {
  Map<String, dynamic>? _audit;
  bool _backedUp = false;

  @override
  String get projectPath => widget.path;

  Future<void> _run() => guard(() async {
        final st = await read(OpType.projectAudit);
        if (mounted) setState(() => _audit = st!.result);
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final a = _audit;
    final findings = ((a?['findings'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final blocking = (a?['blocking'] as int?) ?? 0;
    final missing = ((a?['gitignoreMissing'] as List?) ?? const []).cast<String>();
    final hasGit = a?['git'] == true;
    final gitInfo = a?['gitInfo'] as Map<String, dynamic>?;
    final stats = a?['stats'] as Map<String, dynamic>?;

    Widget step(String label, {required bool done, VoidCallback? action}) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? p.turquoise : p.textSecondary),
          title: Text(label),
          trailing: done
              ? Text(l.wsDone, style: TextStyle(color: p.turquoise))
              : action == null
                  ? null
                  : FilledButton(onPressed: busy ? null : action, child: Text(l.wsDo)),
        );

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Text(l.wsAuditIntro, style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: CambuseSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(onPressed: busy ? null : _run, icon: const Icon(Icons.search), label: Text(l.wsRunAudit)),
        ),
        feedback(context),
        if (a != null) ...[
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.xs, children: [
            for (final k in (a['kinds'] as List)) Chip(label: Text('$k')),
            for (final k in (a['platforms'] as List)) Chip(avatar: const Icon(Icons.devices, size: 16), label: Text('$k')),
            Chip(
              avatar: Icon(hasGit ? Icons.account_tree : Icons.block, size: 16),
              label: Text(hasGit ? '${l.wsGitRepo} · ${gitInfo?['branch'] ?? ''}' : l.wsNoGit),
            ),
          ]),
          if (stats != null)
            Text(l.wsFilesCount(stats['files'] as int, _size(stats['bytes'] as int)), style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: CambuseSpacing.md),
          if (findings.isEmpty) Text(l.wsNoFindings, style: TextStyle(color: p.turquoise)),
          for (final f in findings)
            Card(
              margin: const EdgeInsets.only(bottom: CambuseSpacing.xs),
              child: ListTile(
                dense: true,
                leading: Icon(
                  switch (f['severity']) {
                    'blocking' => Icons.dangerous,
                    'warning' => Icons.warning_amber,
                    _ => Icons.info_outline,
                  },
                  color: switch (f['severity']) {
                    'blocking' => p.alert,
                    'warning' => p.gold,
                    _ => p.textSecondary,
                  },
                  semanticLabel: switch (f['severity']) {
                    'blocking' => l.wsBlocking,
                    'warning' => l.wsWarning,
                    _ => l.wsInfo,
                  },
                ),
                title: Text('${f['message']}'),
                subtitle: f['file'] == null
                    ? null
                    : Text('${f['file']}${f['line'] == null ? '' : ':${f['line']}'}',
                        style: TextStyle(fontFamily: 'monospace', color: p.textSecondary)),
              ),
            ),
          const SizedBox(height: CambuseSpacing.md),
          Text(l.wsPlan, style: Theme.of(context).textTheme.titleMedium),
          step(l.wsStepBackup, done: _backedUp, action: () async {
            if (await mutate(OpType.projectBackup)) setState(() => _backedUp = true);
          }),
          step(l.wsStepInit, done: hasGit, action: () async {
            if (await mutate(OpType.gitInit)) await _run();
          }),
          step(l.wsStepGitignore(missing.length), done: missing.isEmpty, action: () async {
            if (await mutate(OpType.gitignoreUpdate, {'lines': missing})) await _run();
          }),
          if (blocking > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: CambuseSpacing.sm),
              child: Text(l.wsStepFixBlocking(blocking), style: TextStyle(color: p.alert)),
            )
          else
            step(l.wsStepCommit, done: hasGit && (gitInfo?['commits'] as int? ?? 0) > 0 && (gitInfo?['changes'] as int? ?? 0) == 0),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- Changements

class _ChangesTab extends ConsumerStatefulWidget {
  const _ChangesTab({required this.path});
  final String path;
  @override
  ConsumerState<_ChangesTab> createState() => _ChangesTabState();
}

class _ChangesTabState extends ConsumerState<_ChangesTab> with _OpsState {
  RepoStatus? _status;
  final _selected = <String>{};
  final _message = TextEditingController();
  String? _diffPath;
  List<FileDiff>? _diff;

  @override
  String get projectPath => widget.path;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() => guard(() async {
        final st = await read(OpType.gitStatus);
        if (!mounted) return;
        setState(() {
          _status = parsePorcelain(st!.stdout);
          _selected.removeWhere((p) => !_status!.changes.any((c) => c.path == p));
        });
      });

  Future<void> _showDiff(FileChange c) => guard(() async {
        if (c.untracked) {
          setState(() {
            _diffPath = c.path;
            _diff = const [];
          });
          return;
        }
        final unstaged = (await read(OpType.gitDiff, {'path': c.path}))!.stdout;
        final staged = (await read(OpType.gitDiff, {'path': c.path, 'staged': true}))!.stdout;
        if (mounted) {
          setState(() {
            _diffPath = c.path;
            _diff = [...parseUnifiedDiff(staged), ...parseUnifiedDiff(unstaged)];
          });
        }
      });

  Future<void> _after(bool ok) async {
    if (ok) {
      _selected.clear();
      // Le diff affiché est périmé après une modification.
      _diffPath = null;
      _diff = null;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final s = _status;
    final sel = _selected.toList()..sort();
    final selChanges = s?.changes.where((c) => _selected.contains(c.path)).toList() ?? const [];
    final hasStaged = s?.changes.any((c) => c.staged) ?? false;

    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Row(children: [
          Expanded(child: Text(s?.branch == null ? '' : l.wsBranchLabel(s!.branch!), style: Theme.of(context).textTheme.titleMedium)),
          IconButton(tooltip: l.wsRefresh, onPressed: busy ? null : _load, icon: const Icon(Icons.refresh)),
        ]),
        feedback(context),
        if (s != null && s.clean) Text(l.wsClean, style: TextStyle(color: p.turquoise)),
        if (s != null && !s.clean) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.wsSelectAll),
            value: _selected.length == s.changes.length,
            onChanged: (v) => setState(() {
              _selected.clear();
              if (v == true) _selected.addAll(s.changes.map((c) => c.path));
            }),
          ),
          for (final c in s.changes)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selected.contains(c.path),
              onChanged: (v) => setState(() => v == true ? _selected.add(c.path) : _selected.remove(c.path)),
              title: Text(c.path, style: const TextStyle(fontFamily: 'monospace')),
              subtitle: Text(
                [
                  if (c.untracked) l.wsUntracked,
                  if (c.staged) '${l.wsStaged} (${c.index})',
                  if (!c.untracked && c.worktree != ' ') '${l.wsUnstagedLabel} (${c.worktree})',
                ].join(' · '),
                style: TextStyle(color: c.untracked ? p.gold : c.staged ? p.turquoise : p.textSecondary),
              ),
              secondary: IconButton(
                tooltip: 'Diff',
                icon: const Icon(Icons.difference_outlined),
                onPressed: busy ? null : () => _showDiff(c),
              ),
            ),
          Wrap(spacing: CambuseSpacing.sm, runSpacing: CambuseSpacing.sm, children: [
            FilledButton.icon(
              onPressed: busy || sel.isEmpty ? null : () async => _after(await mutate(OpType.gitAdd, {'paths': sel})),
              icon: const Icon(Icons.add_task),
              label: Text(l.wsStage),
            ),
            OutlinedButton.icon(
              onPressed: busy || !selChanges.any((c) => c.staged)
                  ? null
                  : () async => _after(await mutate(OpType.gitRestore,
                      {'paths': [for (final c in selChanges) if (c.staged) c.path], 'staged': true})),
              icon: const Icon(Icons.remove_done),
              label: Text(l.wsUnstage),
            ),
            OutlinedButton.icon(
              onPressed: busy || !selChanges.any((c) => !c.untracked && c.worktree != ' ')
                  ? null
                  : () async => _after(await mutate(OpType.gitRestore,
                      {'paths': [for (final c in selChanges) if (!c.untracked && c.worktree != ' ') c.path]})),
              icon: Icon(Icons.undo, color: p.alert),
              label: Text(l.wsDiscard),
            ),
          ]),
          Text(l.wsDiscardHint, style: TextStyle(color: p.textSecondary, fontSize: 12)),
          const SizedBox(height: CambuseSpacing.md),
          TextField(
            controller: _message,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.wsCommitMessage),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: CambuseSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: busy || !hasStaged || _message.text.trim().isEmpty
                  ? null
                  : () async {
                      final ok = await mutate(OpType.gitCommit, {'message': _message.text.trim()});
                      if (ok) _message.clear();
                      await _after(ok);
                    },
              icon: const Icon(Icons.check),
              label: Text(l.wsCommit),
            ),
          ),
        ],
        if (_diffPath != null) ...[
          const SizedBox(height: CambuseSpacing.lg),
          Text(_diffPath!, style: TextStyle(fontFamily: 'monospace', color: p.gold)),
          const SizedBox(height: CambuseSpacing.sm),
          DiffView(
            files: _diff ?? const [],
            emptyLabel: (s?.changes.any((c) => c.path == _diffPath && c.untracked) ?? false) ? l.wsDiffUntracked : l.wsNoDiff,
          ),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- Historique

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.path});
  final String path;
  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> with _OpsState {
  List<BranchInfo> _branches = const [];
  List<CommitInfo> _commits = const [];
  final _name = TextEditingController();

  @override
  String get projectPath => widget.path;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() => guard(() async {
        final b = await read(OpType.gitBranches);
        List<CommitInfo> commits = const [];
        try {
          commits = parseOneline((await read(OpType.gitLog, {'limit': 50}))!.stdout);
        } on CompanionException {
          // Dépôt sans commit : git log échoue, la liste reste vide.
        }
        if (mounted) {
          setState(() {
            _branches = parseBranches(b!.stdout);
            _commits = commits;
          });
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Row(children: [
          Expanded(child: Text(l.wsBranches, style: Theme.of(context).textTheme.titleMedium)),
          IconButton(tooltip: l.wsRefresh, onPressed: busy ? null : _load, icon: const Icon(Icons.refresh)),
        ]),
        feedback(context),
        for (final b in _branches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(b.current ? Icons.radio_button_checked : Icons.call_split, color: b.current ? p.turquoise : p.copper),
            title: Text(b.name, style: const TextStyle(fontFamily: 'monospace')),
            subtitle: Text('${b.sha} ${b.subject}', style: TextStyle(color: p.textSecondary)),
            trailing: b.current
                ? null
                : OutlinedButton(
                    onPressed: busy ? null : () async {
                      if (await mutate(OpType.gitSwitch, {'name': b.name})) await _load();
                    },
                    child: Text(l.wsSwitch),
                  ),
          ),
        Row(children: [
          Expanded(child: TextField(controller: _name, decoration: InputDecoration(labelText: l.wsNewBranch), autocorrect: false)),
          const SizedBox(width: CambuseSpacing.sm),
          FilledButton(
            onPressed: busy ? null : () async {
              if (await mutate(OpType.gitBranchCreate, {'name': _name.text.trim()})) {
                _name.clear();
                await _load();
              }
            },
            child: Text(l.wsCreateBranch),
          ),
        ]),
        const SizedBox(height: CambuseSpacing.lg),
        Text(l.wsCommits, style: Theme.of(context).textTheme.titleMedium),
        if (_commits.isEmpty) Text(l.wsNoCommits, style: TextStyle(color: p.textSecondary)),
        for (final c in _commits)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text(c.sha, style: TextStyle(fontFamily: 'monospace', color: p.gold)),
            title: Text(c.subject),
            subtitle: c.refs.isEmpty ? null : Text(c.refs, style: TextStyle(color: p.turquoise, fontSize: 12)),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- Sauvegardes

class _BackupsTab extends ConsumerStatefulWidget {
  const _BackupsTab({required this.path});
  final String path;
  @override
  ConsumerState<_BackupsTab> createState() => _BackupsTabState();
}

class _BackupsTabState extends ConsumerState<_BackupsTab> with _OpsState {
  List<Map<String, dynamic>> _backups = const [];

  @override
  String get projectPath => widget.path;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() => guard(() async {
        final st = await read(OpType.backupList);
        if (mounted) setState(() => _backups = ((st!.result?['backups'] as List?) ?? const []).cast<Map<String, dynamic>>());
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(CambuseSpacing.md),
      children: [
        Wrap(spacing: CambuseSpacing.sm, children: [
          FilledButton.icon(
            onPressed: busy ? null : () async {
              if (await mutate(OpType.projectBackup)) await _load();
            },
            icon: const Icon(Icons.save_alt),
            label: Text(l.wsBackupNow),
          ),
          IconButton(tooltip: l.wsRefresh, onPressed: busy ? null : _load, icon: const Icon(Icons.refresh)),
        ]),
        feedback(context),
        if (_backups.isEmpty) Text(l.wsNoBackups, style: TextStyle(color: p.textSecondary)),
        for (final b in _backups)
          Card(
            margin: const EdgeInsets.only(bottom: CambuseSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(CambuseSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(b['kind'] == 'project' ? Icons.inventory_2 : Icons.description_outlined, color: p.copper),
                  const SizedBox(width: CambuseSpacing.sm),
                  Expanded(
                    child: Text(b['kind'] == 'project'
                        ? l.wsBackupProject
                        : l.wsBackupFiles((b['files'] as List?)?.length ?? 0)),
                  ),
                ]),
                Text('${b['createdAt']} · ${b['reason']}', style: TextStyle(color: p.textSecondary, fontSize: 12)),
                if (b['files'] != null)
                  Text((b['files'] as List).join(', '), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => mutate(OpType.backupRestore, {'id': b['id']}),
                    icon: const Icon(Icons.restore),
                    label: Text(l.wsRestore),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
