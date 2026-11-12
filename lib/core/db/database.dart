import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Profil local de l'apprenant (un seul profil par appareil en phase 1).
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().withLength(min: 1, max: 40)();
  DateTimeColumn get createdAt => dateTime()();
}

/// Paramètres clé/valeur (jamais de secret ici : voir le coffre OS).
@DataClassName('SettingRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Journal de bord / historique d'audit local (SPEC §8).
@DataClassName('AuditEntry')
class AuditEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get category => text()();
  TextColumn get action => text()();
  TextColumn get details => text().withDefault(const Constant(''))();
  TextColumn get outcome => text()();
}

@DriftDatabase(tables: [Profiles, AppSettingsTable, AuditEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Base persistante dans le dossier de support privé de l'application
  /// (Linux : ~/.local/share/fr.lacambuse.la_cambuse ; Android : stockage
  /// interne). Jamais dans ~/Documents, qui appartient à l'utilisateur.
  factory AppDatabase.open() => AppDatabase(
        driftDatabase(
          name: 'cambuse',
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      );

  /// Version du schéma. Toute modification doit ajouter une étape de migration
  /// dans [migration] et un test dans `test/core/db/`.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Aucune migration en v1. Les étapes futures s'ajouteront ici, une par
          // version, de façon idempotente et testée.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
