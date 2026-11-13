import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/academy/domain/course.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../helpers.dart';
import 'academy_test.dart' show openAcademy, tapVisible;
import 'companion_screen_test.dart' show tapPump;
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient, openProject, tab;

final docker = CourseModule.fromJson(
    jsonDecode(File('assets/courses/docker.json').readAsStringSync()) as Map<String, dynamic>);

class DockerClient extends WorkshopClient {
  DockerClient(super.db, {this.scope = true});
  final bool scope;
  final _mine = <String, OpStatus>{};

  @override
  Future<OpStatus> submit(OpRequest req) async {
    if (!req.type.startsWith('docker.')) return super.submit(req);
    requests.add(req);
    if (!scope && req.type != 'docker.lint' && req.type != 'docker.scaffold') {
      throw const CompanionExceptionForTest();
    }
    final result = switch (req.type) {
      'docker.info' => {
          'available': true, 'server': '29.1.3', 'rootless': false, 'containers': 2, 'running': 1, 'images': 3,
          'notes': [{'severity': 'warning', 'message': 'Votre compte est dans le groupe « docker » : cela équivaut à des droits root.'}],
        },
      'docker.images' => {'images': [{'Repository': 'node', 'Tag': '22-slim', 'Size': '329MB'}]},
      'docker.containers' => {'containers': [{'ID': 'c1', 'Names': 'web', 'Image': 'nginx:1.27', 'State': 'running', 'Status': 'Up 2 hours'}]},
      'docker.logs' => {'logs': '2026-11-13 démarrage [SECRET MASQUÉ]'},
      'docker.lint' => {
          'files': [{'path': 'Dockerfile', 'kind': 'dockerfile', 'findings': [lintDockerfile('FROM node\nCMD node a.js\n').first.toJson()]}],
          'kinds': ['node'], 'hasDockerignore': false, 'suggestedTemplate': 'node',
        },
      _ => null,
    };
    final st = OpStatus(id: 'd${requests.length}', type: req.type,
        state: req.type == 'docker.scaffold' ? OpState.awaitingApproval : OpState.succeeded,
        plan: ['Créer dans … (modèle node) :', '+ Dockerfile (20 lignes)', '+ .dockerignore (10 lignes)'], result: result);
    _mine[st.id] = st;
    return st;
  }

  @override
  Future<OpStatus> approve(String id) async {
    if (!_mine.containsKey(id)) return super.approve(id);
    approved.add(id);
    return _mine[id] = OpStatus(id: id, type: _mine[id]!.type, state: OpState.succeeded, plan: const [], result: {'created': ['Dockerfile']});
  }

  @override
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async => _mine[id] ?? super.waitFor(id);
}

class CompanionExceptionForTest implements Exception {
  const CompanionExceptionForTest();
}

void main() {
  testWidgets('labo Dockerfile : départ refusé, solution acceptée, exercice validé', (tester) async {
    final db = await pumpApp(tester, size: desktop);
    await openAcademy(tester);
    await tapVisible(tester, find.text('Docker'));
    final lesson = docker.lessons.firstWhere((l) => l.id == 'non-root');
    await tapVisible(tester, find.text(lesson.title));
    await tester.tap(find.text('Exercice'));
    await tester.pumpAndSettle();
    expect(find.textContaining('aucun conteneur n\'est lancé'), findsOneWidget);
    await tapVisible(tester, find.text('Analyser'));
    expect(find.textContaining('DF002'), findsOneWidget);
    expect(find.textContaining('DF015'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, lesson.lab!.solution);
    await tester.pump();
    await tapVisible(tester, find.text('Analyser'));
    expect(find.textContaining('Labo réussi'), findsOneWidget);
    final row = await dbRead(tester, () => db.select(db.lessonProgress).getSingle());
    expect(row.exerciseDone, isTrue);
    await teardown(tester, db);
  });

  testWidgets('salle des machines : diagnostic, conteneurs, images, journaux masqués', (tester) async {
    final db = memoryDb();
    final c = DockerClient(db);
    await pumpApp(tester, size: desktop, db: db, overrides: [companionClientProvider.overrideWithValue(c)]);
    await tester.tap(find.text('Atelier').last);
    await tester.pumpAndSettle();
    await tapPump(tester, find.text('Salle des machines Docker').last);
    await tester.pumpAndSettle();
    expect(find.text('Docker 29.1.3'), findsOneWidget);
    expect(find.textContaining('groupe « docker »'), findsOneWidget);
    expect(find.text('web'), findsOneWidget);
    expect(find.text('node:22-slim'), findsOneWidget);
    await tapPump(tester, find.byTooltip('Journal de web'));
    await tester.pumpAndSettle();
    expect(find.textContaining('[SECRET MASQUÉ]'), findsOneWidget);
    expect(c.requests.map((r) => r.type), isNot(contains(anyOf('docker.run', 'docker.rm', 'docker.stop'))));
    await teardown(tester, db);
  });

  testWidgets('onglet Docker du projet : constats et génération approuvée', (tester) async {
    final db = memoryDb();
    final c = DockerClient(db);
    await pumpApp(tester, size: desktop, db: db, overrides: [companionClientProvider.overrideWithValue(c)]);
    await tester.tap(find.text('Atelier').last);
    await tester.pumpAndSettle();
    await openProject(tester);
    await tab(tester, 'Docker');
    await tapPump(tester, find.text('Analyser les fichiers Docker'));
    expect(find.textContaining('DF001'), findsOneWidget);
    expect(find.textContaining('Pas de .dockerignore'), findsOneWidget);
    expect(find.text('Générer un Dockerfile (node)'), findsNothing, reason: 'un Dockerfile existe déjà');
    await teardown(tester, db);
  });
}
