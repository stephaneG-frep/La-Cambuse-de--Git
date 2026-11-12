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
      expect(version.read<int>('user_version'), 2);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
