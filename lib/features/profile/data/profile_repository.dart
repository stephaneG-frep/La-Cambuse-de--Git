import '../../../core/db/database.dart';
import '../../logbook/data/logbook_repository.dart';
import '../../logbook/domain/audit_outcome.dart';

class InvalidProfileName implements Exception {
  const InvalidProfileName();
}

/// Profil local unique (SPEC §12 : « Créer un profil local »).
class ProfileRepository {
  ProfileRepository(this._db, this._logbook, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final LogbookRepository _logbook;
  final DateTime Function() _clock;

  static const maxLength = 40;

  /// Normalise et valide un nom ; lève [InvalidProfileName] si invalide.
  static String validate(String raw) {
    final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || name.length > maxLength) throw const InvalidProfileName();
    return name;
  }

  Stream<Profile?> watchCurrent() =>
      (_db.select(_db.profiles)..limit(1)).watchSingleOrNull();

  Future<Profile?> current() => (_db.select(_db.profiles)..limit(1)).getSingleOrNull();

  /// Crée le profil, ou renomme le profil existant.
  Future<Profile> save(String rawName) async {
    final name = validate(rawName);
    final existing = await current();
    if (existing == null) {
      final id = await _db.into(_db.profiles).insert(
            ProfilesCompanion.insert(displayName: name, createdAt: _clock()),
          );
      await _logbook.record(
        category: 'profil',
        action: 'Profil créé',
        details: 'Nom : $name',
        outcome: AuditOutcome.success,
      );
      return (await (_db.select(_db.profiles)..where((t) => t.id.equals(id)))
          .getSingle());
    }
    final updated = existing.copyWith(displayName: name);
    await _db.update(_db.profiles).replace(updated);
    await _logbook.record(
      category: 'profil',
      action: 'Profil renommé',
      details: '${existing.displayName} → $name',
      outcome: AuditOutcome.success,
    );
    return updated;
  }
}
