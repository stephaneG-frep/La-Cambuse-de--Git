import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/logging/redactor.dart';
import 'package:la_cambuse/features/logbook/data/logbook_repository.dart';
import 'package:la_cambuse/features/logbook/domain/audit_outcome.dart';

import '../helpers.dart';

void main() {
  late LogbookRepository repo;
  var t = DateTime(2026, 11, 12, 10);

  setUp(() {
    t = DateTime(2026, 11, 12, 10);
    repo = LogbookRepository(memoryDb(), clock: () => t = t.add(const Duration(seconds: 1)));
  });

  test('aucun secret ne parvient en base', () async {
    final token = 'ghp_${'s' * 36}';
    await repo.record(category: 'git', action: 'push $token', details: 'Bearer $token');
    final rows = await repo.watch().first;
    expect(rows.single.action, isNot(contains(token)));
    expect(rows.single.details, isNot(contains(token)));
    expect(rows.single.action, contains(Redactor.mask));
  });

  test('ordre antichronologique et filtre par catégorie', () async {
    await repo.record(category: 'a', action: '1');
    await repo.record(category: 'b', action: '2');
    await repo.record(category: 'a', action: '3');
    expect((await repo.watch().first).map((e) => e.action), ['3', '2', '1']);
    expect((await repo.watch(category: 'a').first).map((e) => e.action), ['3', '1']);
    expect(await repo.categories(), ['a', 'b']);
    expect(await repo.watchCount().first, 3);
  });

  test('export JSON valide et complet', () async {
    await repo.record(category: 'x', action: 'act', outcome: AuditOutcome.failure);
    final r = await repo.exportJson();
    final decoded = jsonDecode(r.json) as Map<String, dynamic>;
    expect(decoded['format'], 'la-cambuse-logbook');
    expect(r.count, 1);
    expect((decoded['entries'] as List).single['outcome'], 'failure');
  });

  test("l'effacement supprime tout puis consigne l'effacement", () async {
    for (var i = 0; i < 4; i++) {
      await repo.record(category: 'c', action: '$i');
    }
    expect(await repo.clear(), 4);
    final rows = await repo.watch().first;
    expect(rows.single.action, 'Journal effacé');
    expect(rows.single.details, contains('4 entrées'));
  });
}
