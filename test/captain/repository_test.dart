import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/captain/data/captain_repository.dart';
import 'package:la_cambuse/features/captain/domain/engine.dart';
import 'package:la_cambuse/features/captain/domain/missions.dart';

import '../helpers.dart';

void main() {
  test('instantané relu à l\'identique ; une mission « en cours » est relue comme interrompue', () async {
    final db = memoryDb();
    final repo = CaptainRepository(db);
    final plan = missionTemplates.first.build();
    final run = RunSnapshot(id: 'r1', plan: plan, projectPath: '/p', createdAt: DateTime(2026, 11, 14))
      ..state = RunState.enCours
      ..checkpointId = 'b1';
    run.steps.first.state = MissionStepState.reussie;
    await repo.save(run);
    final back = (await repo.load('r1'))!;
    expect(back.state, RunState.interrompu);
    expect(back.checkpointId, 'b1');
    expect(back.plan.steps.length, plan.steps.length);
    expect(back.steps.first.state, MissionStepState.reussie);
    expect(back.nextIndex, 1);
    await db.close();
  });

  test('journal : secrets masqués par défense en profondeur, suppression en cascade', () async {
    final db = memoryDb();
    final repo = CaptainRepository(db);
    await repo.save(RunSnapshot(id: 'r2', plan: missionTemplates.first.build(), projectPath: '/p', createdAt: DateTime(2026)));
    await repo.log('r2', CaptainEvent(DateTime(2026), 'info', 'jeton ghp_abcdefghijklmnopqrstuvwxyz0123456789 vu'));
    final ev = await repo.events('r2');
    expect(ev.single.message, isNot(contains('ghp_abcdefghijklmnopqrstuvwxyz0123456789')));
    await repo.delete('r2');
    expect(await repo.events('r2'), isEmpty);
    await db.close();
  });
}
