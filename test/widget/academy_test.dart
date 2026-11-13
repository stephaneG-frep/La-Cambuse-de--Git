import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';

import '../helpers.dart';
import 'widget_helpers.dart';

final module = CourseModule.fromJson(
    jsonDecode(File('assets/courses/git.json').readAsStringSync()) as Map<String, dynamic>);

/// Fait défiler jusqu'au widget puis le touche (les branches masquées de
/// l'IndexedStack sont ignorées).
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Future<void> openAcademy(WidgetTester tester) async {
  await tester.tap(find.text('Académie').last);
  await tester.pumpAndSettle();
}

Future<void> runCommand(WidgetTester tester, String cmd) async {
  await tester.enterText(find.widgetWithText(TextField, 'Tapez une commande (ex. git status)'), cmd);
  await tester.tap(find.byTooltip('Exécuter'));
  await tester.pumpAndSettle();
}

/// Répond à toutes les questions d'une leçon ; [wrong] = indices à rater.
Future<void> answerQuiz(WidgetTester tester, Lesson lesson, {Set<int> wrong = const {}}) async {
  for (final (i, q) in lesson.quiz.indexed) {
    final fail = wrong.contains(i);
    if (q.kind == QuestionKind.command) {
      await tester.enterText(find.widgetWithText(TextField, 'Saisissez la commande'), fail ? 'git nimporte' : q.accepted.first);
      await tester.pump();
    } else {
      final picks = fail
          ? {List.generate(q.choices.length, (k) => k).firstWhere((k) => !q.answers.contains(k))}
          : q.answers;
      for (final k in picks) {
        await tapVisible(tester, find.text(q.choices[k]));
      }
    }
    await tapVisible(tester, find.text('Valider'));
    expect(find.text(fail ? 'Pas tout à fait.' : 'Bonne réponse !'), findsOneWidget, reason: q.id);
    expect(find.text(q.explanation), findsOneWidget, reason: 'correction expliquée ${q.id}');
    final next = i + 1 < lesson.quiz.length ? 'Question suivante' : 'Voir le résultat';
    await tapVisible(tester, find.text(next));
  }
}

void main() {
  testWidgets('carte des îles : les 11 modules du parcours sont disponibles hors ligne',
      (tester) async {
    final db = await pumpApp(tester, size: desktop);
    await openAcademy(tester);
    expect(find.text('Carte des îles'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Observabilité, sécurité, SRE'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('En brume — prévu en phase'), findsNothing);
    await teardown(tester, db);
  });

  testWidgets('leçon 1 complète : exercice + quiz → validée, persistée et reprise après redémarrage',
      (tester) async {
    final db = memoryDb();
    await pumpApp(tester, size: desktop, db: db);
    await openAcademy(tester);
    await tester.tap(find.text('Git'));
    await tester.pumpAndSettle();
    expect(find.text(module.title), findsOneWidget);
    final lesson = module.lessons.first;
    await tapVisible(tester, find.text(lesson.title));

    // Exercice dans le bac à sable.
    await tester.tap(find.text('Exercice'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Simulateur pédagogique'), findsOneWidget);
    await runCommand(tester, 'git status');
    expect(find.textContaining('not a git repository'), findsOneWidget);
    await runCommand(tester, 'git init');
    await runCommand(tester, 'git status');
    expect(find.text('Exercice réussi ! Mousse Byte est fier de vous.'), findsOneWidget);

    // Quiz parfait.
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();
    await answerQuiz(tester, lesson);
    expect(find.text('Score : 100 %'), findsOneWidget);
    expect(find.text('Quiz réussi.'), findsOneWidget);
    expect(find.text('Leçon validée'), findsOneWidget);

    final row = await dbRead(tester, () => (db.select(db.lessonProgress)).getSingle());
    expect(row.completedAt, isNotNull);
    expect(row.exerciseDone, isTrue);
    expect(row.bestScore, 100);

    // « Redémarrage » : nouvelle instance de l'application sur la même base.
    await unmount(tester);
    await pumpApp(tester, size: desktop, db: db);
    expect(find.text('Reprendre : ${lesson.title}'), findsOneWidget);
    expect(find.text('Git, de zéro à autonome — 1/14 leçons'), findsOneWidget);
    await tester.tap(find.text('Reprendre : ${lesson.title}'));
    await tester.pumpAndSettle();
    expect(find.text('Leçon validée'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('quiz sous 70 % : leçon non validée, question ratée programmée en révision',
      (tester) async {
    final db = await pumpApp(tester, size: phone);
    await openAcademy(tester);
    await tester.tap(find.text('Git'));
    await tester.pumpAndSettle();
    final lesson = module.lessons.firstWhere((l) => l.id == 'rebase');
    await tapVisible(tester, find.text(lesson.title));
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();
    await answerQuiz(tester, lesson, wrong: {0, 1});
    expect(find.text('Score : 50 %'), findsOneWidget);
    expect(find.textContaining('Il faut 70 %'), findsOneWidget);
    expect(find.text('Leçon validée'), findsNothing);
    final cards = await dbRead(tester, () => db.select(db.reviewCards).get());
    expect(cards, hasLength(lesson.quiz.length));
    expect(cards.where((c) => c.wrongCount == 1), hasLength(2));
    await teardown(tester, db);
  });

  testWidgets('révisions : les cartes échues sont proposées puis replanifiées', (tester) async {
    final db = memoryDb();
    final q = module.lessons.first.quiz.first;
    await tester.runAsync(() => db.into(db.reviewCards).insert(ReviewCardsCompanion.insert(
        questionId: q.id, moduleId: 'git', dueAt: DateTime(2020))));
    await pumpApp(tester, size: phone, db: db);
    await openAcademy(tester);
    await tester.tap(find.text('Révisions'));
    await tester.pumpAndSettle();
    expect(find.text(q.prompt), findsOneWidget);
    await tapVisible(tester, find.text(q.choices[q.answers.first]));
    await tapVisible(tester, find.text('Valider'));
    await tapVisible(tester, find.text('Voir le résultat'));
    final card = await dbRead(tester, () => db.select(db.reviewCards).getSingle());
    expect(card.box, 2);
    expect(card.dueAt.isAfter(DateTime.now()), isTrue);
    await teardown(tester, db);
  });

  testWidgets('glossaire et recherche (insensible aux accents)', (tester) async {
    final db = await pumpApp(tester, size: phone);
    await openAcademy(tester);
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'etiquette');
    await tester.pumpAndSettle();
    expect(find.text('Étiquettes et versions'), findsOneWidget);
    expect(find.text('Étiquette (tag)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun résultat.'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('projet final : grille verrouillée tant que le projet n\'est pas réalisé',
      (tester) async {
    final db = await pumpApp(tester, size: desktop);
    await openAcademy(tester);
    await tester.tap(find.text('Git'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.textContaining('Projet final —'));
    await tester.tap(find.text("Grille d'auto-évaluation"));
    await tester.pumpAndSettle();
    expect(find.textContaining('Réalisez d\'abord le projet'), findsOneWidget);
    await teardown(tester, db);
  });

  testWidgets('paramètres : renommer le profil', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => db.into(db.profiles)
        .insert(ProfilesCompanion.insert(displayName: 'Matelot Test', createdAt: DateTime(2026))));
    await pumpApp(tester, size: phone, db: db);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Matelot Test'), 'Anne');
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    expect(find.text('Profil renommé.'), findsOneWidget);
    final p = await dbRead(tester, () => db.select(db.profiles).getSingle());
    expect(p.displayName, 'Anne');
    await teardown(tester, db);
  });

  group('accessibilité Académie', () {
    for (final (name, size) in [('téléphone', phone), ('bureau', desktop)]) {
      testWidgets('leçon et quiz ($name)', (tester) async {
        final handle = tester.ensureSemantics();
        final db = await pumpApp(tester, size: size);
        await openAcademy(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.tap(find.text('Git'));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text(module.lessons[3].title));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.tap(find.text('Quiz'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
        await teardown(tester, db);
      });
    }
  });
}
