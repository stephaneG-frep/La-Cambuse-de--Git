import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/captain/presentation/captain_providers.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../captain/fakes.dart';
import '../helpers.dart';
import 'companion_screen_test.dart' show tapPump;
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient;

/// Zone défilante de la page (ni le rail de navigation, ni un champ de saisie).
Finder pageScroll() => find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;

Future<void> pumpUntil(WidgetTester tester, Finder f, {int max = 200}) async {
  for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (f.evaluate().isEmpty) {
    // ignore: avoid_print
    print('ÉCRAN : ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().join(' | ')}');
  }
  expect(f, findsWidgets, reason: 'jamais affiché : $f');
}

/// Ouvre le Capitaine avec un faux compagnon (projets) et un faux moteur.
Future<(FakeBackend, dynamic)> openCaptain(WidgetTester tester, Map<String, Map<String, dynamic>> results) async {
  final db = memoryDb();
  final backend = FakeBackend(results: results);
  await pumpApp(tester, size: desktop, db: db, overrides: [
    companionClientProvider.overrideWithValue(WorkshopClient(db)),
    captainBackendProvider.overrideWithValue(backend),
  ]);
  await tester.tap(find.text('Capitaine').last);
  await tester.pumpAndSettle();
  return (backend, db);
}

Future<void> chooseProjectAndLaunch(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownMenu<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('vitrine').last);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Approuver le plan et lancer'), 300, scrollable: pageScroll());
  await tester.ensureVisible(find.text('Approuver le plan et lancer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Approuver le plan et lancer'));
  await tester.pump();
}

/// Répond au panneau de décision de l'étape [step] (attend qu'il s'affiche).
Future<void> decide(WidgetTester tester, String panelTitle, String button, String step) async {
  final panel = find.ancestor(of: find.text(panelTitle), matching: find.byType(Card));
  final forStep = find.descendant(of: panel, matching: find.text(step));
  for (var i = 0; i < 100 && forStep.evaluate().isEmpty; i++) {
    // Le panneau est en haut de la liste : on y remonte s'il est hors de vue.
    if (find.byType(ListView).evaluate().isNotEmpty) await tester.drag(pageScroll(), const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await pumpUntil(tester, forStep);
  final b = find.descendant(of: panel, matching: find.text(button));
  await tester.ensureVisible(b);
  await tester.pumpAndSettle();
  await tester.tap(b);
  await tester.pump();
}

void main() {
  testWidgets('accueil : missions prédéfinies, plan IA facultatif, journal vide', (tester) async {
    final (_, db) = await openCaptain(tester, {});
    expect(find.text('Le Capitaine automatique'), findsOneWidget);
    expect(find.text('Mettre le projet sous Git'), findsOneWidget);
    expect(find.text('Contrôle qualité Flutter'), findsOneWidget);
    expect(find.text('Proposer une mission avec le professeur IA'), findsOneWidget);
    expect(find.text('Aucune mission pour l\'instant.'), findsOneWidget);
    expect(find.textContaining('prévu en phase'), findsNothing);
    await teardown(tester, db);
  });

  testWidgets('mission complète : table de navigation, approbations, relecture, rapport et retour arrière', (tester) async {
    final (backend, db) = await openCaptain(tester, nouveauProjet());
    await tapPump(tester, find.text('Mettre le projet sous Git'));
    await tester.pumpAndSettle();
    expect(find.text('Table de navigation'), findsOneWidget);
    expect(find.text('3. Point de contrôle : sauvegarde du projet'), findsOneWidget);
    expect(find.textContaining('Coût IA : aucun'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choisissez un projet'), 300, scrollable: pageScroll());
    expect(find.text('Relecture humaine'), findsOneWidget);
    expect(find.text('Approuver le plan et lancer'), findsNothing, reason: 'aucun projet choisi');
    await tester.scrollUntilVisible(find.byType(DropdownMenu<String>), -300, scrollable: pageScroll());

    await chooseProjectAndLaunch(tester);
    await decide(tester, 'Le compagnon demande votre accord', 'Autoriser', 'Compléter le .gitignore');
    await decide(tester, 'Le compagnon demande votre accord', 'Autoriser', 'Initialiser le dépôt Git');
    await pumpUntil(tester, find.text('Relisez avant de continuer'));
    expect(find.textContaining('lib/main.dart'), findsWidgets);
    await decide(tester, 'Relisez avant de continuer', 'Continuer', 'Ajouter les fichiers un par un');
    await decide(tester, 'Le compagnon demande votre accord', 'Autoriser', 'Ajouter les fichiers un par un');
    await decide(tester, 'Le compagnon demande votre accord', 'Autoriser', 'Créer le premier commit');
    await pumpUntil(tester, find.text('Restaurer dans un nouveau dossier'));
    expect(backend.submittedOps.last, 'git.commit');
    await tester.scrollUntilVisible(find.text('Copier le rapport'), 200, scrollable: pageScroll());
    expect(find.text('Copier le rapport'), findsOneWidget);
    await tester.drag(pageScroll(), const Offset(0, 4000));
    await tester.pump();
    expect(find.text('Terminée'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('arrêt d\'urgence depuis l\'interface pendant un build', (tester) async {
    final (backend, db) = await openCaptain(tester, {'project.detect': {'result': {'kinds': ['flutter'], 'git': true}}});
    backend.neverFinish.add('flutter.analyze');
    await tapPump(tester, find.text('Contrôle qualité Flutter'));
    await tester.pumpAndSettle();
    await chooseProjectAndLaunch(tester);
    await decide(tester, 'Le compagnon demande votre accord', 'Autoriser', 'flutter analyze');
    await pumpUntil(tester, find.text('Arrêt d\'urgence'));
    await tester.tap(find.text('Arrêt d\'urgence'));
    await pumpUntil(tester, find.text('Arrêtée — Arrêt d\'urgence : opération en cours annulée.'));
    expect(backend.cancelled, hasLength(1));
    expect(backend.submittedOps, isNot(contains('flutter.test')));
    await teardown(tester, db);
  });

  testWidgets('action externe : « Publier » bloqué tant que le consentement n\'est pas coché ; refus → rien n\'est poussé',
      (tester) async {
    final (backend, db) = await openCaptain(tester, {
      'git.status': {'stdout': '## main...origin/main [ahead 1]\n'},
      'git.outgoing': {
        'result': {'remoteUrl': 'https://github.com/ana/vitrine.git', 'commits': [{'sha': 'a1b2c3d', 'subject': 'feat'}], 'secrets': []},
      },
    });
    await tapPump(tester, find.text('Publier la branche courante'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Consentement spécifique'), 300, scrollable: pageScroll());
    await tester.scrollUntilVisible(find.byType(DropdownMenu<String>), -300, scrollable: pageScroll());
    await chooseProjectAndLaunch(tester);
    await decide(tester, 'Relisez avant de continuer', 'Continuer', 'Pousser vers origin (sans force)');
    await pumpUntil(tester, find.text('Action externe : consentement spécifique'));
    final publish = find.widgetWithText(FilledButton, 'Publier');
    expect(tester.widget<FilledButton>(publish).onPressed, isNull, reason: 'case non cochée');
    expect(find.textContaining(token), findsNothing, reason: 'le jeton n\'est jamais affiché');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(publish).onPressed, isNotNull);
    await tester.tap(find.text('Refuser').last);
    await pumpUntil(tester, find.textContaining('Consentement spécifique refusé'));
    expect(backend.submittedOps, isNot(contains('git.push')));
    await teardown(tester, db);
  });
}
