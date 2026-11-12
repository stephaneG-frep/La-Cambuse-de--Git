import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/logbook/data/logbook_repository.dart';
import 'package:la_cambuse/features/profile/data/profile_repository.dart';
import 'package:la_cambuse/features/settings/data/settings_repository.dart';
import 'package:la_cambuse/features/settings/domain/app_settings.dart';

import '../helpers.dart';

void main() {
  test('schéma v1 : création de toutes les tables', () async {
    final db = memoryDb();
    expect(db.schemaVersion, 1);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['profiles', 'app_settings', 'audit_entries']));
    await db.close();
  });

  test('persistance sur fichier : les données survivent à une fermeture/réouverture',
      () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await Directory.systemTemp.createTemp('cambuse_db_');
    final file = File('${dir.path}/cambuse.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      final logbook = LogbookRepository(db);
      await ProfileRepository(db, logbook).save('Anne Bonny');
      await SettingsRepository(db)
          .save(const AppSettings(textScale: 1.4, highContrast: true));
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final profile = await ProfileRepository(db, LogbookRepository(db)).current();
      expect(profile?.displayName, 'Anne Bonny');
      final settings = await SettingsRepository(db).load();
      expect(settings.textScale, 1.4);
      expect(settings.highContrast, isTrue);
      final rows = await db.select(db.auditEntries).get();
      expect(rows.map((r) => r.action), contains('Profil créé'));
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('sauvegarde des paramètres atomique (transaction annulée = rien écrit)',
      () async {
    final db = memoryDb();
    await expectLater(
      db.transaction(() async {
        await SettingsRepository(db).save(const AppSettings(textScale: 1.8));
        throw StateError('panne simulée');
      }),
      throwsStateError,
    );
    expect(await SettingsRepository(db).load(), AppSettings.defaults);
    await db.close();
  });
}
