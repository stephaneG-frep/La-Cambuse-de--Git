import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:la_cambuse/core/db/database.dart';

/// Base SQLite en mémoire, isolée pour chaque test.
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
