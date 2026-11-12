import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/audit_outcome.dart';

final _categoriesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  // Recalculé quand le nombre d'entrées change.
  ref.watch(logbookCountProvider);
  return ref.watch(logbookRepositoryProvider).categories();
});

/// Journal de bord : historique d'audit local, filtrable, exportable, effaçable.
class LogbookScreen extends ConsumerStatefulWidget {
  const LogbookScreen({super.key});

  @override
  ConsumerState<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends ConsumerState<LogbookScreen> {
  String? _category;

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(logbookRepositoryProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: result.json));
    messenger.showSnackBar(SnackBar(content: Text(l.logbookExported(result.count))));
  }

  Future<void> _clear(int count) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logbookClearConfirmTitle),
        content: Text(l.logbookClearConfirmBody(count)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CambuseTheme.of(ctx).alert,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirmDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final n = await ref.read(logbookRepositoryProvider).clear();
    setState(() => _category = null);
    messenger.showSnackBar(SnackBar(content: Text(l.logbookCleared(n))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = ref.watch(logbookEntriesProvider(_category));
    final categories = ref.watch(_categoriesProvider).value ?? const [];
    final count = ref.watch(logbookCountProvider).value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              CambuseSpacing.md, CambuseSpacing.md, CambuseSpacing.md, 0),
          child: Wrap(
            spacing: CambuseSpacing.sm,
            runSpacing: CambuseSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(l.logbookTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(width: CambuseSpacing.md),
              OutlinedButton.icon(
                onPressed: count == 0 ? null : _export,
                icon: const Icon(Icons.copy_all),
                label: Text(l.logbookExport),
              ),
              OutlinedButton.icon(
                onPressed: count == 0 ? null : () => _clear(count),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.logbookClear),
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(CambuseSpacing.md),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l.logbookFilterAll),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in categories) ...[
                  const SizedBox(width: CambuseSpacing.sm),
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: entries.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(error: e),
            data: (rows) => rows.isEmpty
                ? EmptyView(message: l.logbookEmpty, icon: Icons.menu_book_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: CambuseSpacing.md),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _EntryTile(entry: rows[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = CambuseTheme.of(context);
    final outcome = AuditOutcome.fromCode(entry.outcome);
    final (icon, color, label) = switch (outcome) {
      AuditOutcome.success => (Icons.check_circle_outline, p.turquoise, l.outcomeSuccess),
      AuditOutcome.failure => (Icons.cancel_outlined, p.alert, l.outcomeFailure),
      AuditOutcome.cancelled => (Icons.block, p.gold, l.outcomeCancelled),
      AuditOutcome.info => (Icons.info_outline, p.textSecondary, l.outcomeInfo),
    };
    final when = DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hms()
        .format(entry.timestamp);
    return ListTile(
      leading: Tooltip(message: label, child: Icon(icon, color: color, semanticLabel: label)),
      title: Text(entry.action),
      subtitle: Text(
        [
          '$when · ${entry.category}',
          if (entry.details.isNotEmpty) entry.details,
        ].join('\n'),
        style: TextStyle(color: p.textSecondary),
      ),
      isThreeLine: entry.details.isNotEmpty,
    );
  }
}
