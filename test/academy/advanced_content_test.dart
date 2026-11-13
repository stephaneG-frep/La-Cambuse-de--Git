import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';

import 'docker_content_test.dart' show checkLab;

/// Modules de l'Académie avancée (phase 9) : structure complète, labos
/// réalisables (départ refusé, solution acceptée) et JSON à jour.
const advancedModules = {
  'linux': 'linux_module.py',
  'github': 'forges_modules.py',
  'gitlab': 'forges_modules.py',
  'devops': 'devops_module.py',
  'reseaux': 'reseaux_module.py',
  'kubernetes': 'kubernetes_module.py',
  'iac': 'iac_module.py',
  'sre': 'sre_module.py',
};

void main() {
  final ids = <String>{};
  for (final id in advancedModules.keys) {
    final file = File('assets/courses/$id.json');
    if (!file.existsSync()) continue;
    group('module $id', () {
      final module = CourseModule.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);

      test('8 à 15 leçons, 4 questions et 3 sections minimum, projet, grille, glossaire', () {
        expect(module.id, id);
        expect(module.lessons.length, inInclusiveRange(8, 15));
        for (final l in module.lessons) {
          expect(l.quiz.length, greaterThanOrEqualTo(4), reason: l.id);
          expect(l.sections.length, greaterThanOrEqualTo(3), reason: l.id);
          expect(l.objectives, isNotEmpty, reason: l.id);
        }
        expect(module.project.lab, isNotNull);
        expect(module.project.rubric.length, greaterThanOrEqualTo(4));
        expect(module.glossary.length, greaterThanOrEqualTo(10));
      });

      test('au moins 5 labos', () {
        expect(module.lessons.where((l) => l.lab != null).length, greaterThanOrEqualTo(5));
      });

      test('identifiants uniques', () {
        expect(module.lessons.map((l) => l.id).toSet().length, module.lessons.length);
        final q = module.lessons.expand((l) => l.quiz).map((q) => q.id).toList();
        expect(q.toSet().length, q.length);
        for (final other in ids) {
          expect(q.any((x) => x.startsWith('$other-')), isFalse);
        }
      });

      for (final l in module.lessons.where((l) => l.lab != null)) {
        test('labo réalisable : ${l.id}', () => checkLab(l.lab!, '$id/${l.id}'));
      }
      test('projet final réalisable', () => checkLab(module.project.lab!, '$id/projet'));

      test('questions à commande : réponses acceptées', () {
        for (final q in module.lessons.expand((l) => l.quiz).where((q) => q.kind == QuestionKind.command)) {
          for (final a in q.accepted) {
            expect(q.isCorrectCommand(a), isTrue, reason: q.id);
          }
        }
      });
    });
  }

  test('les JSON avancés sont à jour avec leur source Python', () {
    for (final script in advancedModules.values.toSet()) {
      if (!File('tool/content/$script').existsSync()) continue;
      final r = Process.runSync('python3', ['tool/content/$script']);
      expect(r.exitCode, 0, reason: '$script\n${r.stderr}');
    }
    final paths = [for (final id in advancedModules.keys) 'assets/courses/$id.json'];
    final diff = Process.runSync('git', ['status', '--porcelain', '--', ...paths]);
    expect(diff.stdout.toString().trim().split('\n').where((l) => l.startsWith(' M')), isEmpty,
        reason: 'relancer les générateurs et committer');
  });
}
