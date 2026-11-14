import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';

void main() {
  test('migration v1 → v2 : données conservées, nouvelles tables créées', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('cambuse_mig_');
    final file = File('${dir.path}/v1.sqlite');
    final v1 = File('test/fixtures/schema_v1.sql').readAsStringSync();
    try {
      // Base v1 telle que livrée en phase 1 (schéma relevé sur une vraie base).
      final db = AppDatabase(NativeDatabase(file, setup: (raw) {
        if (raw.userVersion == 0) {
          raw.execute(v1);
          raw.execute("INSERT INTO profiles (display_name, created_at) VALUES ('Mary Read', 1762900000)");
          raw.execute("INSERT INTO app_settings VALUES ('high_contrast', 'true')");
          raw.execute("INSERT INTO audit_entries (timestamp, category, action, outcome) "
              "VALUES (1762900000, 'application', 'Démarrage', 'info')");
          raw.userVersion = 1;
        }
      }));

      expect((await db.select(db.profiles).getSingle()).displayName, 'Mary Read');
      expect((await db.select(db.appSettingsTable).getSingle()).value, 'true');
      expect(await db.select(db.auditEntries).get(), hasLength(1));
      // Nouvelles tables utilisables.
      await db.into(db.lessonProgress).insert(LessonProgressCompanion.insert(
          moduleId: 'git', lessonId: 'pourquoi-git', startedAt: DateTime(2026)));
      expect(await db.select(db.lessonProgress).get(), hasLength(1));
      expect(await db.select(db.reviewCards).get(), isEmpty);
      expect(await db.select(db.projectProgress).get(), isEmpty);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 4);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('migration v2 → v3 : progression conservée, tables IA créées', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('cambuse_mig3_');
    final file = File('${dir.path}/v2.sqlite');
    final v2 = File('test/fixtures/schema_v2.sql').readAsStringSync();
    try {
      final db = AppDatabase(NativeDatabase(file, setup: (raw) {
        if (raw.userVersion == 0) {
          raw.execute(v2);
          raw.execute("INSERT INTO lesson_progress (module_id, lesson_id, started_at, exercise_done) "
              "VALUES ('git', 'pourquoi-git', 1762900000, 1)");
          raw.userVersion = 2;
        }
      }));
      final row = await db.select(db.lessonProgress).getSingle();
      expect(row.exerciseDone, isTrue);
      final id = await db.into(db.aiConversations).insert(AiConversationsCompanion.insert(
          title: 't', systemPrompt: 's', providerKind: 'anthropic', model: 'm', level: 'debutant',
          createdAt: DateTime(2026), updatedAt: DateTime(2026)));
      await db.into(db.aiMessages).insert(AiMessagesCompanion.insert(
          conversationId: id, role: 'user', contentJson: '[]', createdAt: DateTime(2026)));
      // Suppression en cascade des messages avec la conversation.
      await (db.delete(db.aiConversations)..where((t) => t.id.equals(id))).go();
      expect(await db.select(db.aiMessages).get(), isEmpty);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('migration v3 → v4 : conversations IA conservées, tables du Capitaine créées', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('cambuse_mig4_');
    final file = File('${dir.path}/v3.sqlite');
    final v3 = File('test/fixtures/schema_v3.sql').readAsStringSync();
    try {
      final db = AppDatabase(NativeDatabase(file, setup: (raw) {
        if (raw.userVersion == 0) {
          raw.execute(v3);
          raw.execute("INSERT INTO ai_conversations (title, system_prompt, provider_kind, model, level, created_at, updated_at) "
              "VALUES ('Branches', 's', 'anthropic', 'claude-opus-5-5', 'debutant', 1762900000, 1762900000)");
          raw.userVersion = 3;
        }
      }));
      expect((await db.select(db.aiConversations).getSingle()).title, 'Branches');
      await db.into(db.captainRuns).insert(CaptainRunsCompanion.insert(
          id: 'r1', missionId: 'depot-local', title: 't', projectPath: '/p', state: 'termine', snapshotJson: '{}',
          createdAt: DateTime(2026), updatedAt: DateTime(2026)));
      await db.into(db.captainEvents).insert(
          CaptainEventsCompanion.insert(runId: 'r1', at: DateTime(2026), kind: 'info', message: 'démarrée'));
      // Le journal disparaît avec sa mission.
      await (db.delete(db.captainRuns)..where((t) => t.id.equals('r1'))).go();
      expect(await db.select(db.captainEvents).get(), isEmpty);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 4);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
