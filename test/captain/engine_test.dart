import 'dart:async';
import 'dart:convert';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/captain/domain/engine.dart';
import 'package:la_cambuse/features/captain/domain/mission.dart';
import 'package:la_cambuse/features/captain/domain/missions.dart';
import 'package:la_cambuse/features/captain/domain/report.dart';
import 'fakes.dart';

class FakePilot implements CaptainPilot {
  bool approve = true, reviewOk = true, consent = true;
  final approvals = <String>[], reviews = <String>[], consents = <Map<String, dynamic>>[];
  FutureOr<void> Function(StepSpec)? onApprove;

  @override
  Future<bool> approveOp(StepSpec step, OpStatus pending) async {
    approvals.add(step.op);
    await onApprove?.call(step);
    return approve;
  }

  @override
  Future<bool> review(StepSpec step, String preview) async {
    reviews.add(preview);
    return reviewOk;
  }

  @override
  Future<bool> specificConsent(StepSpec step, Map<String, dynamic> params) async {
    consents.add(params);
    return consent;
  }
}

class MemStore implements CaptainStore {
  final events = <CaptainEvent>[];
  final saves = <String>[];
  @override
  Future<void> save(RunSnapshot run) async => saves.add(jsonEncode(run.toJson()));
  @override
  Future<void> log(String runId, CaptainEvent event) async => events.add(event);
  String get journal => events.map((e) => e.message).join('\n');
}

var _clock = DateTime(2026, 11, 14, 9);

({CaptainEngine engine, FakeBackend backend, FakePilot pilot, MemStore store}) setup(MissionPlan plan,
    {Map<String, Map<String, dynamic>>? results, RunSnapshot? snapshot, FakeBackend? backend, DateTime Function()? clock}) {
  final b = backend ?? FakeBackend(results: results);
  final p = FakePilot();
  final s = MemStore();
  final run = snapshot ?? RunSnapshot(id: 'r1', plan: plan, projectPath: '/srv/projets/vigie', createdAt: DateTime(2026, 11, 14, 9));
  return (
    engine: CaptainEngine(run: run, backend: b, pilot: p, store: s, pollInterval: Duration.zero, clock: clock ?? () => _clock),
    backend: b,
    pilot: p,
    store: s,
  );
}

MissionPlan mission(String id, {String provider = 'github'}) => missionTemplates.firstWhere((m) => m.id == id).build(provider: provider);

Future<void> until(bool Function() cond) async {
  for (var i = 0; i < 2000 && !cond(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(cond(), isTrue, reason: 'condition jamais atteinte');
}

void main() {
  group('plans', () {
    test('les missions prédéfinies sont valides ; point de contrôle avant la première modification', () {
      for (final t in missionTemplates) {
        for (final provider in t.providerChoice ? ['github', 'gitlab'] : ['github']) {
          final p = t.build(provider: provider);
          expect(validatePlan(p), isEmpty, reason: p.missionId);
          final firstMut = p.steps.indexWhere((s) => s.risk == StepRisk.modification);
          if (firstMut >= 0) {
            expect(p.steps.take(firstMut).any((s) => s.op == 'project.backup'), isTrue, reason: p.missionId);
          }
        }
      }
    });

    test('plans refusés : opération inconnue ou interdite, chemin évadé, secret, résolveur ou condition inconnus, doublons', () {
      const bad = MissionPlan(missionId: 'x', title: 'x', summary: '', limits: ExecutionLimits(maxMutations: 1), steps: [
        StepSpec(id: 'a', title: 'a', why: '', op: 'shell.exec'),
        StepSpec(id: 'b', title: 'b', why: '', op: 'git.restore'),
        StepSpec(id: 'c', title: 'c', why: '', op: 'git.add', params: {'paths': ['../../etc/passwd']}),
        StepSpec(id: 'd', title: 'd', why: '', op: 'git.push', params: {'token': 'ghp_x'}),
        StepSpec(id: 'e', title: 'e', why: '', op: 'git.commit', bind: {'message': 'ia.libre'}, when: 'toujours'),
        StepSpec(id: 'e', title: 'e2', why: '', op: 'git.add', params: {'paths': ['*'], 'force': true}),
      ]);
      final e = validatePlan(bad).join('\n');
      for (final expected in ['inconnue « shell.exec »', 'git.restore', 'chemins relatifs', 'secret ne peut jamais', 'résolveur inconnu',
        'condition inconnue', 'en double', 'paramètre inconnu « force »', 'Trop de modifications']) {
        expect(e, contains(expected));
      }
    });
  });

  test('mission nominale « Mettre le projet sous Git » : contrôle, relecture, approbations, rapport', () async {
    final f = setup(mission('depot-local'), results: nouveauProjet());
    final run = await f.engine.start();
    expect(run.state, RunState.termine);
    expect(f.backend.submittedOps,
        ['project.detect', 'project.audit', 'project.backup', 'gitignore.update', 'git.init', 'git.status', 'git.add', 'git.commit']);
    expect(f.pilot.approvals, ['gitignore.update', 'git.init', 'git.add', 'git.commit'], reason: 'chaque modification est approuvée');
    expect(f.backend.submitted.firstWhere((r) => r.type == 'gitignore.update').params['lines'], ['build/', '.env']);
    expect(f.backend.submitted.firstWhere((r) => r.type == 'git.add').params['paths'], ['lib/main.dart', 'pubspec.yaml']);
    expect(f.pilot.reviews.single, contains('lib/main.dart'));
    expect(run.checkpointId, 'sauvegarde-42');
    final report = buildReport(run, f.store.events);
    expect(report, contains('Terminée'));
    expect(report, contains('sauvegarde-42'));
    expect(report, contains('git reset --soft HEAD~1'));
    final restore = rollbackGuide(run).firstWhere((r) => r.action != null);
    expect(restore.action!.type, 'backup.restore');
    expect(restore.action!.params['id'], 'sauvegarde-42');
    expect(f.store.saves.length, greaterThanOrEqualTo(8), reason: 'état enregistré après chaque étape');
  });

  test('conditions : dépôt existant et .gitignore complet → étapes ignorées et expliquées', () async {
    final r = nouveauProjet()
      ..['project.detect'] = {'result': {'kinds': ['node'], 'git': true}}
      ..['project.audit'] = {'result': {'gitignoreMissing': []}};
    final f = setup(mission('depot-local'), results: r);
    final run = await f.engine.start();
    expect(run.state, RunState.termine);
    expect(f.backend.submittedOps, isNot(contains('git.init')));
    expect(f.backend.submittedOps, isNot(contains('gitignore.update')));
    expect(run.steps.where((s) => s.state == MissionStepState.ignoree), hasLength(2));
    expect(f.store.journal, contains('ignorée'));
  });

  test('défaillance : refus dans le panneau du compagnon → arrêt, rien d\'autre n\'est soumis', () async {
    final f = setup(mission('depot-local'), results: nouveauProjet());
    f.pilot.approve = false;
    final run = await f.engine.start();
    expect(run.state, RunState.arrete);
    expect(f.backend.submittedOps.last, 'gitignore.update');
    expect(f.backend.rejected, hasLength(1));
    expect(run.steps.where((s) => s.state == MissionStepState.refusee), hasLength(1));
  });

  test('défaillance : relecture refusée → l\'ajout n\'est jamais soumis', () async {
    final f = setup(mission('depot-local'), results: nouveauProjet());
    f.pilot.reviewOk = false;
    final run = await f.engine.start();
    expect(run.state, RunState.arrete);
    expect(f.backend.submittedOps, isNot(contains('git.add')));
  });

  test('défaillance : échec d\'une opération (secret au commit) → mission échouée, retour arrière proposé', () async {
    final r = nouveauProjet()..['git.commit'] = {'state': 'failed', 'error': 'Commit bloqué : secret détecté dans config.json'};
    final f = setup(mission('depot-local'), results: r);
    final run = await f.engine.start();
    expect(run.state, RunState.echoue);
    expect(run.reason, contains('secret détecté'));
    expect(run.steps.last.state, MissionStepState.echouee);
    expect(rollbackGuide(run).first.action?.type, 'backup.restore');
  });

  test('défaillance : délai dépassé → opération annulée sur le compagnon', () async {
    var t = DateTime(2026, 11, 14, 9);
    final b = FakeBackend(results: {'project.detect': {'result': {'kinds': ['flutter'], 'git': true}}})..neverFinish.add('flutter.analyze');
    final f = setup(mission('qualite-flutter'), backend: b, clock: () => t = t.add(const Duration(minutes: 1)));
    final run = await f.engine.start();
    expect(run.state, RunState.echoue);
    expect(run.reason, contains('Délai dépassé'));
    expect(b.cancelled, hasLength(1));
    expect(b.submittedOps, isNot(contains('flutter.test')));
  });

  test('défaillance : arrêt d\'urgence pendant un build → annulation envoyée, aucune étape suivante', () async {
    final b = FakeBackend(results: {'project.detect': {'result': {'kinds': ['flutter'], 'git': true}}})..neverFinish.add('flutter.test');
    final f = setup(mission('qualite-flutter'), backend: b);
    final done = f.engine.start();
    await until(() => b.submittedOps.contains('flutter.test') && b.approved.length == 2);
    await f.engine.emergencyStop();
    final run = await done;
    expect(run.state, RunState.arrete);
    expect(b.cancelled, ['op3'], reason: 'l\'opération en cours (flutter test) est annulée');
    expect(b.submittedOps, isNot(contains('flutter.build.apk.debug')));
    expect(f.store.journal, contains('ARRÊT D\'URGENCE'));
  });

  test('arrêt d\'urgence avec annulation lente (processus long à tuer) : état final confirmé, pas « inconnu »', () async {
    final b = FakeBackend(results: {'project.detect': {'result': {'kinds': ['flutter'], 'git': true}}})
      ..neverFinish.add('flutter.test')
      ..cancelDelayPolls = 5;
    final f = setup(mission('qualite-flutter'), backend: b);
    final done = f.engine.start();
    await until(() => b.submittedOps.contains('flutter.test') && b.approved.length == 2);
    await f.engine.emergencyStop();
    final run = await done;
    expect(run.state, RunState.arrete);
    expect(run.steps[2].state, MissionStepState.annulee);
    expect(run.steps[2].exitCode, -9);
  });

  test('arrêt d\'urgence pendant une demande d\'approbation : demande rejetée, étape « annulée », rien d\'exécuté', () async {
    final f = setup(mission('qualite-flutter'), results: {'project.detect': {'result': {'kinds': ['flutter'], 'git': true}}});
    f.pilot.onApprove = (s) async {
      if (s.op == 'flutter.test') await f.engine.emergencyStop();
    };
    final run = await f.engine.start();
    expect(run.state, RunState.arrete);
    expect(run.steps[2].state, MissionStepState.annulee);
    expect(run.steps[2].note, contains('rien n\'a été lancé'));
    expect(f.backend.rejected, hasLength(1));
    expect(f.backend.approved, hasLength(1), reason: 'seul flutter analyze a été approuvé');
  });

  test('pause puis reprise : la pause prend effet entre deux étapes et l\'état est enregistré', () async {
    final f = setup(mission('depot-local'), results: nouveauProjet());
    f.pilot.onApprove = (s) async {
      if (s.op == 'gitignore.update') await f.engine.requestPause();
    };
    final done = f.engine.start();
    await until(() => f.engine.run.state == RunState.enPause);
    expect(f.backend.submittedOps.last, 'gitignore.update', reason: 'l\'étape en cours se termine');
    expect(jsonDecode(f.store.saves.last)['state'], 'enPause');
    await f.engine.resume();
    final run = await done;
    expect(run.state, RunState.termine);
  });

  test('défaillance : compagnon injoignable puis reprise après redémarrage de l\'application', () async {
    final b = FakeBackend(results: nouveauProjet())..networkDown.add('git.commit');
    final f = setup(mission('depot-local'), backend: b);
    final run1 = await f.engine.start();
    expect(run1.state, RunState.interrompu);
    expect(run1.steps.last.state, MissionStepState.inconnue);

    // « Redémarrage » : l'instantané est relu depuis le stockage.
    final relu = RunSnapshot.fromJson(jsonDecode(f.store.saves.last) as Map<String, dynamic>);
    expect(relu.state, RunState.interrompu);
    expect(relu.steps.last.opId, isNotNull);
    b.networkDown.clear();
    final f2 = setup(relu.plan, snapshot: relu, backend: b);
    final run2 = await f2.engine.start();
    expect(run2.state, RunState.termine);
    expect(b.submittedOps.where((o) => o == 'git.commit'), hasLength(1), reason: 'le commit n\'est pas relancé : son état est relu');
  });

  test('défaillance : panne pendant le suivi d\'une lecture → interrompue, reprise sans resoumettre', () async {
    final b = FakeBackend(results: nouveauProjet())..networkDown.add('project.audit');
    final f = setup(mission('depot-local'), backend: b);
    final run1 = await f.engine.start();
    expect(run1.state, RunState.interrompu);
    expect(run1.steps[1].state, MissionStepState.inconnue);
    b.networkDown.clear();
    final relu = RunSnapshot.fromJson(jsonDecode(f.store.saves.last) as Map<String, dynamic>);
    final run2 = await setup(relu.plan, snapshot: relu, backend: b).engine.start();
    expect(run2.state, RunState.termine);
    expect(b.submittedOps.where((o) => o == 'project.audit'), hasLength(1));
  });

  test('défaillance : prérequis non rempli (projet non Flutter) → arrêt avant tout build', () async {
    final f = setup(mission('qualite-flutter'), results: {'project.detect': {'result': {'kinds': ['node'], 'git': true}}});
    final run = await f.engine.start();
    expect(run.state, RunState.arrete);
    expect(run.reason, contains('Flutter'));
    expect(f.backend.submittedOps, ['project.detect']);
  });

  test('défaillance : limite de durée dépassée', () async {
    var t = DateTime(2026, 11, 14, 9);
    final f = setup(mission('depot-local'), results: nouveauProjet(), clock: () => t = t.add(const Duration(minutes: 9)));
    final run = await f.engine.start();
    expect(run.state, RunState.echoue);
    expect(run.reason, contains('Limite de durée'));
  });

  group('publication (action externe)', () {
    Map<String, Map<String, dynamic>> depot({List secrets = const []}) => {
          'git.status': {'stdout': '## main...origin/main [ahead 1]\n'},
          'git.outgoing': {
            'result': {'remoteUrl': 'https://github.com/ana/vigie.git', 'commits': [{'sha': 'a1b2c3d', 'subject': 'feat: écran'}], 'secrets': secrets},
          },
        };

    test('sans jeton dans le coffre → échec clair, rien n\'est poussé', () async {
      final f = setup(mission('publication'), results: depot());
      f.backend.storedToken = null;
      final run = await f.engine.start();
      expect(run.state, RunState.echoue);
      expect(run.reason, contains('Aucun jeton GitHub'));
      expect(f.backend.submittedOps, isNot(contains('git.push')));
    });

    test('consentement spécifique refusé → aucun push', () async {
      final f = setup(mission('publication'), results: depot());
      f.pilot.consent = false;
      final run = await f.engine.start();
      expect(run.state, RunState.arrete);
      expect(f.backend.submittedOps, isNot(contains('git.push')));
      expect(f.pilot.consents.single, {'remote': 'origin', 'branch': 'main'}, reason: 'le jeton n\'est pas montré');
    });

    test('push consenti : jeton transmis au compagnon, absent du journal, de l\'état et du rapport', () async {
      final f = setup(mission('publication'), results: depot());
      final run = await f.engine.start();
      expect(run.state, RunState.termine);
      expect(f.backend.submitted.last.params['token'], token);
      expect(f.store.journal, isNot(contains(token)));
      expect(f.store.saves.join(), isNot(contains(token)));
      expect(buildReport(run, f.store.events), isNot(contains(token)));
      expect(buildReport(run, f.store.events), contains('NON annulable automatiquement'));
    });

    test('secret dans ce qui serait publié → arrêt avant le push', () async {
      final f = setup(mission('publication'), results: depot(secrets: [{'file': 'config.json', 'kind': 'github-token'}]));
      final run = await f.engine.start();
      expect(run.state, RunState.arrete);
      expect(run.reason, contains('aucun secret'));
      expect(f.backend.submittedOps, isNot(contains('git.push')));
    });
  });
}
