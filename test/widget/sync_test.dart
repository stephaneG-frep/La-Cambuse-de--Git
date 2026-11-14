import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/companion_link/data/companion_client.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../helpers.dart';
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient;

/// Faux compagnon : renvoie la fusion avec une progression « d'un autre appareil ».
class SyncClient extends WorkshopClient {
  SyncClient(super.db, {this.scope = true});
  final bool scope;
  final sent = <ProgressSnapshot>[];
  static final other = ProgressSnapshot(lessons: [
    SyncLesson(moduleId: 'git', lessonId: 'pourquoi-git', startedAt: DateTime.utc(2026, 11, 13), completedAt: DateTime.utc(2026, 11, 13), bestScore: 4, exerciseDone: true),
  ]);

  @override
  Future<ProgressSnapshot> sync(ProgressSnapshot local) async {
    if (!scope) throw const CompanionException(ErrorCodes.forbiddenScope, 'portée manquante', status: 403);
    sent.add(local);
    return mergeProgress(local, other);
  }
}

Future<void> openSync(WidgetTester tester, SyncClient c) async {
  await pumpApp(tester, size: desktop, db: c.db, overrides: [companionClientProvider.overrideWithValue(c)]);
  await tester.tap(find.byTooltip('Paramètres'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Synchroniser maintenant'), 200, scrollable: find.byType(Scrollable).hitTestable().last);
}

void main() {
  testWidgets('synchroniser : la leçon terminée sur l\'autre appareil arrive, puis « déjà à jour »', (tester) async {
    final db = memoryDb();
    final c = SyncClient(db);
    await openSync(tester, c);
    await tester.tap(find.text('Synchroniser maintenant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Synchronisé : 1 leçon(s)'), findsOneWidget);
    final row = (await tester.runAsync(() => (db.select(db.lessonProgress)).getSingle()))!;
    expect(row.lessonId, 'pourquoi-git');
    expect(row.exerciseDone, isTrue);
    expect(find.textContaining('Dernière synchronisation'), findsOneWidget);
    await tester.tap(find.text('Synchroniser maintenant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Déjà à jour'), findsOneWidget);
    final log = (await tester.runAsync(() => db.select(db.auditEntries).get()))!;
    expect(log.where((e) => e.category == 'synchronisation'), hasLength(2));
    await teardown(tester, db);
  });

  testWidgets('portée « sync » absente : message explicite, rien n\'est modifié', (tester) async {
    final db = memoryDb();
    await openSync(tester, SyncClient(db, scope: false));
    await tester.tap(find.text('Synchroniser maintenant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('portée « sync »'), findsOneWidget);
    expect((await tester.runAsync(() => db.select(db.lessonProgress).get()))!, isEmpty);
    await teardown(tester, db);
  });
}
