import '../../../core/db/database.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.appSettingsTable).get();
    return AppSettings.fromMap({for (final r in rows) r.key: r.value});
  }

  /// Sauvegarde atomique : toutes les clés dans une seule transaction.
  Future<void> save(AppSettings settings) => _db.transaction(() async {
        for (final e in settings.toMap().entries) {
          await _db.into(_db.appSettingsTable).insertOnConflictUpdate(
                AppSettingsTableCompanion.insert(key: e.key, value: e.value),
              );
        }
      });
}
