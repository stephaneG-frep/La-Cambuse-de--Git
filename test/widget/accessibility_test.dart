import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';
import 'package:la_cambuse/features/settings/presentation/help_screen.dart';

import '../helpers.dart';
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient;

Future<void> settle(WidgetTester tester, String where) async {
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  } catch (_) {
    final spinners = find.byWidgetPredicate((w) => w is ProgressIndicator).evaluate().length;
    // ignore: avoid_print
    print('INSTABLE sur $where : $spinners indicateur(s) de progression ; textes : '
        '${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(25).join(' | ')}');
    rethrow;
  }
}

/// Ouvre chaque écran principal (onglets, paramètres, guide) et exécute [check].
Future<void> eachScreen(WidgetTester tester, Size size, Future<void> Function(String) check) async {
  final db = memoryDb();
  await pumpApp(tester, size: size, db: db, overrides: [
    companionClientProvider.overrideWithValue(WorkshopClient(db)),
    // Même fichier que l'asset, lu directement (le chargement d'asset n'avance pas en temps simulé).
    userGuideProvider.overrideWith((ref) async => File('docs/GUIDE_UTILISATEUR.md').readAsStringSync()),
  ]);
  await check('Pont');
  for (final tab in ['Académie', 'Atelier', 'Capitaine', 'Journal']) {
    await tester.tap(find.text(tab).last);
    await settle(tester, tab);
    await check(tab);
  }
  await tester.tap(find.byTooltip('Paramètres'));
  await tester.pumpAndSettle();
  await check('Paramètres');
  await tester.scrollUntilVisible(find.text('Guide de bord'), 300, scrollable: find.byType(Scrollable).hitTestable().last);
  await tester.tap(find.text('Guide de bord'));
  await tester.pumpAndSettle();
  await check('Guide de bord');
  await teardown(tester, db);
}

void main() {
  for (final (name, size) in [('téléphone', phone), ('bureau', desktop)]) {
    testWidgets('accessibilité ($name) : cibles ≥ 48 dp, boutons étiquetés, contraste du texte', (tester) async {
      final handle = tester.ensureSemantics();
      await eachScreen(tester, size, (screen) async {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: '$screen : cible tactile trop petite');
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: '$screen : bouton sans libellé');
        await expectLater(tester, meetsGuideline(textContrastGuideline), reason: '$screen : contraste insuffisant');
      });
      handle.dispose();
    });
  }

  testWidgets('texte agrandi à 200 % sur téléphone : aucun débordement sur les écrans principaux', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await eachScreen(tester, phone, (screen) async {
      expect(tester.takeException(), isNull, reason: '$screen : débordement de mise en page');
    });
  });

  test('le guide embarqué couvre chaque espace de l\'application', () async {
    final md = File('docs/GUIDE_UTILISATEUR.md').readAsStringSync();
    final titles = guideSections(md).map((s) => s.$1).toList();
    for (final t in ['Premiers pas', 'Académie', 'Professeur IA (facultatif)', 'Le compagnon Linux', 'Atelier', 'Capitaine automatique',
      'Ce que l\'application ne fait jamais', 'Dépannage']) {
      expect(titles, contains(t));
    }
    expect(guideSections(md).every((s) => s.$2.isNotEmpty), isTrue);
  });
}
