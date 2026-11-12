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

/// Progression par leçon (v2).
@DataClassName('LessonProgressRow')
class LessonProgress extends Table {
  TextColumn get moduleId => text()();
  TextColumn get lessonId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get bestScore => integer().withDefault(const Constant(0))();
  IntColumn get quizAttempts => integer().withDefault(const Constant(0))();
  BoolColumn get exerciseDone => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {moduleId, lessonId};
}

/// Carte de répétition espacée (système de Leitner, v2).
@DataClassName('ReviewCard')
class ReviewCards extends Table {
  TextColumn get questionId => text()();
  TextColumn get moduleId => text()();
  IntColumn get box => integer().withDefault(const Constant(1))();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {questionId};
}

/// Projet final d'un module et auto-évaluation (v2).
@DataClassName('ProjectProgressRow')
class ProjectProgress extends Table {
  TextColumn get moduleId => text()();
  DateTimeColumn get exerciseCompletedAt => dateTime().nullable()();
  TextColumn get rubricJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get submittedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {moduleId};
}

@DriftDatabase(tables: [
  Profiles,
  AppSettingsTable,
  AuditEntries,
  LessonProgress,
  ReviewCards,
  ProjectProgress,
])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Une étape par version, dans l'ordre. Chaque étape est testée dans
          // test/core/migration_test.dart à partir du schéma réel de la
          // version précédente.
          if (from < 2) {
            await m.createTable(lessonProgress);
            await m.createTable(reviewCards);
            await m.createTable(projectProgress);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
