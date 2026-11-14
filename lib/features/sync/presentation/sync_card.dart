import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../companion_link/data/companion_client.dart';
import '../../companion_link/presentation/companion_screen.dart';
import '../../logbook/domain/audit_outcome.dart';
import '../data/sync_repository.dart';

final syncRepositoryProvider = Provider((ref) => SyncRepository(ref.watch(databaseProvider)));
final lastSyncProvider = FutureProvider.autoDispose<DateTime?>((ref) => ref.watch(syncRepositoryProvider).lastSync());

/// Synchronisation explicite de la progression entre appareils, via le compagnon.
class SyncCard extends ConsumerStatefulWidget {
  const SyncCard({super.key});
  @override
  ConsumerState<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends ConsumerState<SyncCard> {
  bool _busy = false;
  String? _message;
  bool _error = false;

  Future<void> _sync() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    final repo = ref.read(syncRepositoryProvider);
    final log = ref.read(logbookRepositoryProvider);
    try {
      final merged = await ref.read(companionClientProvider).sync(await repo.exportLocal());
      final r = await repo.apply(merged);
      await repo.markSynced(DateTime.now());
      await log.record(
          category: 'synchronisation',
          action: 'Progression synchronisée',
          details: '${r.lessons} leçon(s), ${r.reviews} carte(s), ${r.projects} projet(s) mis à jour',
          outcome: AuditOutcome.success);
      ref.invalidate(lastSyncProvider);
      if (mounted) {
        setState(() {
          _error = false;
          _message = r.total == 0 ? l.syncUpToDate : l.syncDone(r.lessons, r.reviews, r.projects);
        });
      }
    } on CompanionException catch (e) {
      await log.record(category: 'synchronisation', action: 'Échec de la synchronisation', details: e.code, outcome: AuditOutcome.failure);
      if (mounted) {
        setState(() {
          _error = true;
          _message = e.code == ErrorCodes.forbiddenScope ? l.syncScopeMissing : e.message;
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
    final link = ref.watch(companionLinkProvider).value;
    final last = ref.watch(lastSyncProvider).value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CambuseSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.sync, color: p.copper),
            const SizedBox(width: CambuseSpacing.sm),
            Expanded(child: Text(l.syncTitle, style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: CambuseSpacing.xs),
          Text(l.syncIntro, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: CambuseSpacing.sm),
          if (link == null)
            Text(l.syncNeedsCompanion, style: TextStyle(color: p.gold))
          else ...[
            FilledButton.icon(
              onPressed: _busy ? null : _sync,
              icon: const Icon(Icons.sync),
              label: Text(l.syncButton),
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: CambuseSpacing.sm), child: LinearProgressIndicator()),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: CambuseSpacing.sm),
              child: Semantics(liveRegion: true, child: Text(_message!, style: TextStyle(color: _error ? p.alert : p.turquoise))),
            ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: CambuseSpacing.xs),
              child: Text(l.syncLast(last.toLocal().toString().substring(0, 16)), style: TextStyle(color: p.textSecondary, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}
