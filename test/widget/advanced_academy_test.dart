import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/catalog.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';

import 'academy_test.dart' show openAcademy, tapVisible;
import 'widget_helpers.dart';

CourseModule load(String id) =>
    CourseModule.fromJson(jsonDecode(File('assets/courses/$id.json').readAsStringSync()) as Map<String, dynamic>);

/// Labo avancé de bout en bout dans l'interface : départ refusé, solution
/// acceptée, exercice de la leçon validé en base.
Future<void> runLab(WidgetTester tester, String island, String lessonId, String expectedRule) async {
  final module = load(islands.firstWhere((i) => i.title == island).id);
  final lesson = module.lessons.firstWhere((l) => l.id == lessonId);
  final db = await pumpApp(tester, size: desktop);
  await openAcademy(tester);
  await tester.scrollUntilVisible(find.text(island), 300, scrollable: find.byType(Scrollable).hitTestable().first);
  await tapVisible(tester, find.text(island));
  await tester.scrollUntilVisible(find.text(lesson.title), 300, scrollable: find.byType(Scrollable).hitTestable().first);
  await tapVisible(tester, find.text(lesson.title));
  await tester.tap(find.text('Exercice'));
  await tester.pumpAndSettle();
  expect(find.text(lesson.lab!.fileName), findsOneWidget);
  expect(find.textContaining('rien n\'est exécuté'), findsOneWidget);
  // La liste du labo, figée (les éléments hors écran sont détruits au défilement).
  final lab = tester.state<ScrollableState>(find.ancestor(of: find.textContaining('rien n\'est exécuté'), matching: find.byType(Scrollable)).first);
  final labList = find.byElementPredicate((e) => e == lab.context);
  Future<void> reveal(Finder target) async {
    lab.position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 150, scrollable: labList);
  }

  await reveal(find.text('Analyser'));
  await tester.tap(find.text('Analyser'));
  await tester.pumpAndSettle();
  await reveal(find.textContaining(expectedRule));
  expect(find.textContaining(expectedRule), findsWidgets);
  await reveal(find.byType(TextField).first);
  expect(find.textContaining('Labo réussi'), findsNothing);
  await tester.enterText(find.byType(TextField).first, lesson.lab!.solution);
  await tester.pump();
  await reveal(find.text('Analyser'));
  await tester.tap(find.text('Analyser'));
  await tester.pumpAndSettle();
  await reveal(find.textContaining('Labo réussi'));
  expect(find.textContaining('Labo réussi'), findsOneWidget);
  final row = await dbRead(tester, () => db.select(db.lessonProgress).getSingle());
  expect(row.lessonId, lessonId);
  expect(row.exerciseDone, isTrue);
  await teardown(tester, db);
}

void main() {
  test('chaque île du catalogue a un module embarqué valide', () {
    for (final i in islands) {
      expect(i.isAvailable, isTrue, reason: i.id);
      final m = load(i.id);
      expect(m.id, i.id);
      expect(m.lessons.length, greaterThanOrEqualTo(8), reason: i.id);
    }
  });

  testWidgets('labo Kubernetes : sondes manquantes détectées puis corrigées', (tester) async {
    await runLab(tester, 'Kubernetes', 'sondes', 'K8006');
  });

  testWidgets('labo Terminal Linux : sshd durci', (tester) async {
    await runLab(tester, 'Terminal Linux', 'ssh', 'SS001');
  });

  testWidgets('labo Terraform : secret en dur retiré', (tester) async {
    await runLab(tester, 'Terraform, OpenTofu, Ansible', 'variables-secrets', 'TF003');
  });
}
