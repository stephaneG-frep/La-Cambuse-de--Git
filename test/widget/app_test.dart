import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/settings/presentation/settings_screen.dart';

import '../helpers.dart';
import 'widget_helpers.dart';

void main() {
  testWidgets('démarrage sans écran blanc : le pont et le formulaire de profil',
      (tester) async {
    final db = await pumpApp(tester, size: phone);
    expect(find.text('Le pont du navire'), findsOneWidget);
    expect(find.text('Créez votre profil de matelot'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await teardown(tester, db);
  });

  testWidgets('création de profil : validation puis bienvenue et entrée au journal',
      (tester) async {
    final db = await pumpApp(tester, size: phone);
    await tester.tap(find.text('Embarquer'));
    await tester.pumpAndSettle();
    expect(find.text('Entre 1 et 40 caractères.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Capitaine Test');
    await tester.tap(find.text('Embarquer'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue à bord, Capitaine Test !'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.text('Profil créé'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('bureau : rail latéral et raccourcis Ctrl+2 / Ctrl+5 / Ctrl+,',
      (tester) async {
    final db = await pumpApp(tester, size: desktop);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Carte des îles'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Journal de bord'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Compagnon Linux'), findsOneWidget, reason: 'écran des paramètres ouvert');
    await teardown(tester, db);
  });

  testWidgets('les cartes du pont ouvrent la section correspondante', (tester) async {
    final db = await pumpApp(tester, size: desktop);
    await tester.tap(find.text('Atelier').last);
    await tester.pumpAndSettle();
    expect(find.text('Chantier naval'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('paramètres : contraste et langue persistés et consignés', (tester) async {
    final db = await pumpApp(tester, size: phone);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Contraste renforcé'), 200,
        scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(find.text('Contraste renforcé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contraste renforcé'));
    await tester.pumpAndSettle();
    // Écran plus long que le téléphone : défilement jusqu'au choix de langue.
    await tester.scrollUntilVisible(find.text('English'), 200,
        scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('High contrast'), findsOneWidget);

    final rows = (await tester.runAsync(() => db.select(db.appSettingsTable).get()))!;
    final map = {for (final r in rows) r.key: r.value};
    expect(map['high_contrast'], 'true');
    expect(map['language'], 'en');
    final audit = (await tester.runAsync(() => db.select(db.auditEntries).get()))!;
    expect(audit.where((e) => e.category == 'paramètres'), hasLength(2));
    await teardown(tester, db);
  });

  testWidgets('journal : effacement uniquement après confirmation', (tester) async {
    final db = memoryDb();
    await db.into(db.auditEntries).insert(AuditEntriesCompanion.insert(
        timestamp: DateTime(2026), category: 'test', action: 'Entrée A', outcome: 'info'));
    await pumpApp(tester, size: phone, db: db);
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.text('Entrée A'), findsOneWidget);

    await tester.tap(find.text('Effacer le journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Entrée A'), findsOneWidget);

    await tester.tap(find.text('Effacer le journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer définitivement'));
    await tester.pumpAndSettle();
    expect(find.text('Entrée A'), findsNothing);
    expect(find.text('Journal effacé'), findsOneWidget);
    await teardown(tester, db);
  });

  group('accessibilité', () {
    for (final (name, size) in [('téléphone', phone), ('bureau', desktop)]) {
      testWidgets('règles Flutter ($name) : cibles tactiles, libellés, contraste',
          (tester) async {
        final handle = tester.ensureSemantics();
        final db = await pumpApp(tester, size: size);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
        await teardown(tester, db);
      });
    }

    testWidgets('texte agrandi à 200 % : pas de débordement sur téléphone',
        (tester) async {
      final db = memoryDb();
      await db.into(db.appSettingsTable).insert(
          AppSettingsTableCompanion.insert(key: 'text_scale', value: '2.00'));
      await pumpApp(tester, size: phone, db: db);
      expect(tester.takeException(), isNull);
      expect(find.text('Le pont du navire'), findsOneWidget);
      await teardown(tester, db);
    });
  });

  testWidgets('téléphone en paysage : rail sans débordement, toutes les destinations accessibles', (tester) async {
    // Honor MTN-NX1M en paysage : ~880 × 400 points, moins barres d'état et système.
    final db = await pumpApp(tester, size: const Size(880, 340));
    expect(tester.takeException(), isNull, reason: 'aucun débordement de mise en page');
    for (final label in ['Académie', 'Atelier', 'Capitaine', 'Journal']) {
      final dest = find.byIcon(switch (label) {
        'Académie' => Icons.map_outlined,
        'Atelier' => Icons.construction_outlined,
        'Capitaine' => Icons.explore_outlined,
        _ => Icons.menu_book_outlined,
      });
      if (dest.evaluate().isNotEmpty) {
        await tester.ensureVisible(dest.first);
        await tester.tap(dest.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
      }
    }
    await teardown(tester, db);
  });
}
