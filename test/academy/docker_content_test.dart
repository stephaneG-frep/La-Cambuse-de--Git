import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';
import 'package:la_cambuse/features/academy/domain/lab_eval.dart';

/// Validation des modules Docker et Compose : chaque labo doit échouer au
/// départ et réussir avec sa solution.
void checkLab(FileLab lab, String ctx) {
  final start = evaluateLab(lab, lab.starter);
  expect(start.complete, isFalse, reason: '$ctx : le fichier de départ remplit déjà tous les objectifs');
  final end = evaluateLab(lab, lab.solution);
  for (final (i, g) in lab.goals.indexed) {
    expect(end.goalsMet[i], isTrue, reason: '$ctx : la solution ne remplit pas « ${g.label} »\n${end.findings.map((f) => '${f.rule} ${f.message}').join('\n')}');
  }
}

void main() {
  for (final id in ['docker', 'compose']) {
    group('module $id', () {
      final file = File('assets/courses/$id.json');
      final module = CourseModule.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);

      test('8 à 15 leçons, 4 questions minimum, projet et grille', () {
        expect(module.lessons.length, inInclusiveRange(8, 15));
        for (final l in module.lessons) {
          expect(l.quiz.length, greaterThanOrEqualTo(4), reason: l.id);
          expect(l.sections.length, greaterThanOrEqualTo(3), reason: l.id);
        }
        expect(module.project.lab, isNotNull);
        expect(module.project.rubric.length, greaterThanOrEqualTo(4));
        expect(module.glossary.length, greaterThanOrEqualTo(10));
      });

      test('au moins 5 labos', () {
        expect(module.lessons.where((l) => l.lab != null).length, greaterThanOrEqualTo(5));
      });

      for (final l in module.lessons.where((l) => l.lab != null)) {
        test('labo réalisable : ${l.id}', () => checkLab(l.lab!, l.id));
      }
      test('projet final réalisable', () => checkLab(module.project.lab!, 'projet'));

      test('questions à commande : réponses acceptées', () {
        for (final q in module.lessons.expand((l) => l.quiz).where((q) => q.kind == QuestionKind.command)) {
          for (final a in q.accepted) {
            expect(q.isCorrectCommand(a), isTrue, reason: q.id);
          }
        }
      });
    });
  }

  test('les JSON Docker et Compose sont à jour avec leur source Python', () {
    final r = Process.runSync('python3', ['tool/content/docker_modules.py']);
    expect(r.exitCode, 0, reason: r.stderr.toString());
    final diff = Process.runSync('git', ['diff', '--stat', '--', 'assets/courses/docker.json', 'assets/courses/compose.json']);
    expect(diff.stdout.toString().trim(), isEmpty, reason: 'relancer le générateur et committer');
  }, skip: Process.runSync('git', ['ls-files', 'assets/courses/docker.json']).stdout.toString().isEmpty ? 'pas encore versionné' : false);
}
