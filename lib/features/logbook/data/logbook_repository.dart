import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/redactor.dart';
import '../domain/audit_outcome.dart';

/// Écrit et lit le journal de bord. Tous les détails passent par le [Redactor]
/// avant d'être stockés : aucun secret ne doit atteindre la base.
class LogbookRepository {
  LogbookRepository(
    this._db, {
    this._redactor = const Redactor(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Redactor _redactor;
  final DateTime Function() _clock;

  Future<int> record({
    required String category,
    required String action,
    String details = '',
    AuditOutcome outcome = AuditOutcome.info,
  }) {
    return _db.into(_db.auditEntries).insert(
          AuditEntriesCompanion.insert(
            timestamp: _clock(),
            category: category,
            action: _redactor.redact(action),
            details: Value(_redactor.redact(details)),
            outcome: outcome.code,
          ),
        );
  }

  /// Entrées les plus récentes d'abord, éventuellement filtrées par catégorie.
  Stream<List<AuditEntry>> watch({String? category, int limit = 500}) {
    final q = _db.select(_db.auditEntries)
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit);
    if (category != null) q.where((t) => t.category.equals(category));
    return q.watch();
  }

  Stream<int> watchCount() {
    final c = _db.auditEntries.id.count();
    final q = _db.selectOnly(_db.auditEntries)..addColumns([c]);
    return q.map((r) => r.read(c) ?? 0).watchSingle();
  }

  Future<List<String>> categories() async {
    final q = _db.selectOnly(_db.auditEntries, distinct: true)
      ..addColumns([_db.auditEntries.category])
      ..orderBy([OrderingTerm.asc(_db.auditEntries.category)]);
    return (await q.get()).map((r) => r.read(_db.auditEntries.category)!).toList();
  }

  /// Export contrôlé (JSON lisible). Les détails sont déjà expurgés.
  Future<({String json, int count})> exportJson() async {
    final rows = await (_db.select(_db.auditEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final list = [
      for (final r in rows)
        {
          'id': r.id,
          'timestamp': r.timestamp.toIso8601String(),
          'category': r.category,
          'action': r.action,
          'details': r.details,
          'outcome': r.outcome,
        },
    ];
    return (
      json: const JsonEncoder.withIndent('  ').convert({
        'format': 'la-cambuse-logbook',
        'version': 1,
        'entries': list,
      }),
      count: list.length,
    );
  }

  /// Effacement contrôlé : supprime toutes les entrées puis consigne
  /// l'effacement lui-même. Retourne le nombre d'entrées supprimées.
  Future<int> clear() async {
    return _db.transaction(() async {
      final n = await _db.delete(_db.auditEntries).go();
      await record(
        category: 'journal',
        action: 'Journal effacé',
        details: '$n entrées supprimées à la demande de l\'utilisateur',
        outcome: AuditOutcome.success,
      );
      return n;
    });
  }
}
