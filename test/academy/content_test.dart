import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';
import 'package:la_cambuse/features/academy/domain/goals.dart';

CourseModule loadGit() => CourseModule.fromJson(
    jsonDecode(File('assets/courses/git.json').readAsStringSync()) as Map<String, dynamic>);

/// Rejoue la solution de chaque étape et vérifie que l'étape (et seulement
/// elle) se valide. Garantit que chaque exercice est réalisable.
void replay(Exercise ex, String ctx) {
  final s = ExerciseSession(ex);
  for (final g in ex.steps.expand((s) => s.goals)) {
    expect(knownGoalTypes, contains(g.type), reason: '$ctx : objectif inconnu');
  }
  expect(s.completedSteps, 0, reason: '$ctx : la 1re étape est déjà validée par la préparation');
  for (final (i, step) in ex.steps.indexed) {
    expect(s.completedSteps, i, reason: '$ctx étape ${i + 1} : validée trop tôt');
    for (final cmd in step.solution) {
      final r = s.submit(cmd);
      expect(r.ok, isTrue, reason: '$ctx étape ${i + 1} « $cmd » : ${r.output}');
    }
    expect(s.completedSteps, greaterThan(i),
        reason: '$ctx étape ${i + 1} : objectifs non atteints après la solution');
  }
  expect(s.isComplete, isTrue);
}

void main() {
  final module = loadGit();

  test('module Git : 8 à 15 leçons (SPEC §5)', () {
    expect(module.lessons.length, inInclusiveRange(8, 15));
  });

  test('chaque leçon a objectifs, contenu et au moins 4 questions', () {
    for (final l in module.lessons) {
      expect(l.objectives, isNotEmpty, reason: l.id);
      expect(l.sections.length, greaterThanOrEqualTo(3), reason: l.id);
      expect(l.quiz.length, greaterThanOrEqualTo(4), reason: l.id);
    }
  });

  test('objectifs, prérequis, projet final, grille et glossaire présents', () {
    expect(module.objectives, isNotEmpty);
    expect(module.prerequisites, isNotEmpty);
    expect(module.project.rubric.length, greaterThanOrEqualTo(4));
    expect(module.glossary.length, greaterThanOrEqualTo(20));
  });

  test('au moins 10 exercices guidés', () {
    expect(module.lessons.where((l) => l.exercise != null).length, greaterThanOrEqualTo(10));
  });

  for (final l in module.lessons.where((l) => l.exercise != null)) {
    test('exercice réalisable : ${l.id}', () => replay(l.exercise!, l.id));
  }

  test('projet final réalisable', () => replay(module.project.exercise!, 'projet'));

  test('chaque question à commande accepte sa propre réponse normalisée', () {
    for (final q in module.lessons.expand((l) => l.quiz)) {
      if (q.kind != QuestionKind.command) continue;
      for (final a in q.accepted) {
        expect(q.isCorrectCommand('  $a  '), isTrue, reason: q.id);
      }
    }
  });

  test('normalisation des commandes saisies', () {
    final q = module.question('git-l4-q3')!;
    expect(q.isCorrectCommand('git commit -m «Corrige le total»'), isTrue); // clavier mobile
    expect(q.isCorrectCommand('git   commit -m "Corrige le total"'), isTrue);
    expect(q.isCorrectCommand("git commit -m 'Corrige le total'"), isTrue);
    expect(q.isCorrectCommand(r'$ git commit -m "Corrige le total"'), isTrue);
    expect(q.isCorrectCommand('git commit'), isFalse);
  });

  test('contenu invalide refusé avec un message explicite', () {
    expect(
      () => CourseModule.fromJson({'id': 'x', 'lessons': [{'id': 'a'}]}),
      throwsA(isA<FormatException>()),
    );
  });

  test('le JSON est à jour avec sa source Python', () {
    final r = Process.runSync('python3', ['tool/content/git_module.py']);
    expect(r.exitCode, 0, reason: r.stderr.toString());
    final diff = Process.runSync('git', ['diff', '--stat', '--', 'assets/courses/git.json']);
    expect(diff.stdout.toString().trim(), isEmpty,
        reason: 'git.json diffère de la source : relancer le générateur et committer');
  }, skip: !File('.git/HEAD').existsSync() || Process.runSync('git', ['ls-files', 'assets/courses/git.json']).stdout.toString().isEmpty
      ? 'git.json pas encore versionné'
      : false);
}
