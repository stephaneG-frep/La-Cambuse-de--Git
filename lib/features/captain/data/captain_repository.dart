import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/redactor.dart';
import '../domain/engine.dart';

/// Persistance des missions du Capitaine : instantané après chaque étape et
/// journal horodaté. Les messages passent par le [Redactor] (défense en
/// profondeur : le moteur ne journalise déjà jamais de jeton).
class CaptainRepository implements CaptainStore {
  CaptainRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _redactor = Redactor();

  @override
  Future<void> save(RunSnapshot run) => _db.into(_db.captainRuns).insertOnConflictUpdate(CaptainRunsCompanion.insert(
        id: run.id,
        missionId: run.plan.missionId,
        title: run.plan.title,
        projectPath: run.projectPath,
        state: run.state.name,
        snapshotJson: jsonEncode(run.toJson()),
        createdAt: run.createdAt,
        updatedAt: _clock(),
      ));

  @override
  Future<void> log(String runId, CaptainEvent e) => _db.into(_db.captainEvents).insert(CaptainEventsCompanion.insert(
        runId: runId,
        at: e.at,
        kind: e.kind,
        message: _redactor.redact(e.message),
        step: Value(e.step),
      ));

  Future<void> saveReport(String runId, String report) => (_db.update(_db.captainRuns)..where((t) => t.id.equals(runId)))
      .write(CaptainRunsCompanion(reportMd: Value(_redactor.redact(report))));

  Future<RunSnapshot?> load(String id) async {
    final row = await (_db.select(_db.captainRuns)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : RunSnapshot.fromJson(jsonDecode(row.snapshotJson) as Map<String, dynamic>);
  }

  Future<List<CaptainEvent>> events(String runId) async => [
        for (final r in await (_db.select(_db.captainEvents)
              ..where((t) => t.runId.equals(runId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get())
          CaptainEvent(r.at, r.kind, r.message, step: r.step),
      ];

  Stream<List<CaptainEventRow>> watchEvents(String runId) => (_db.select(_db.captainEvents)
        ..where((t) => t.runId.equals(runId))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .watch();

  Stream<List<CaptainRunRow>> watchRuns() =>
      (_db.select(_db.captainRuns)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])..limit(30)).watch();

  Future<void> delete(String id) => (_db.delete(_db.captainRuns)..where((t) => t.id.equals(id))).go();
}
