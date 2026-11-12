import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../features/logbook/data/logbook_repository.dart';
import '../features/logbook/domain/audit_outcome.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/app_settings.dart';

/// Base de données : surchargée dans `main()` (fichier) et dans les tests
/// (mémoire). Lever une erreur ici rend toute omission immédiatement visible.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider doit être surchargé'),
);

final logbookRepositoryProvider =
    Provider((ref) => LogbookRepository(ref.watch(databaseProvider)));

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(logbookRepositoryProvider),
  ),
);

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final currentProfileProvider = StreamProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).watchCurrent(),
);

final logbookCountProvider =
    StreamProvider<int>((ref) => ref.watch(logbookRepositoryProvider).watchCount());

final logbookEntriesProvider = StreamProvider.family<List<AuditEntry>, String?>(
  (ref, category) => ref.watch(logbookRepositoryProvider).watch(category: category),
);

class SettingsController extends AsyncNotifier<AppSettings> {
  /// Dernière valeur réellement enregistrée en base.
  AppSettings _persisted = AppSettings.defaults;

  @override
  Future<AppSettings> build() async {
    _persisted = await ref.read(settingsRepositoryProvider).load();
    return _persisted;
  }

  /// Aperçu immédiat sans persistance (ex. glissement d'un curseur).
  void preview(AppSettings next) => state = AsyncData(next);

  /// Applique et enregistre ; consigne la différence au journal.
  Future<void> apply(AppSettings next) async {
    final previous = _persisted;
    state = AsyncData(next);
    if (next == previous) return;
    await ref.read(settingsRepositoryProvider).save(next);
    _persisted = next;
    await ref.read(logbookRepositoryProvider).record(
          category: 'paramètres',
          action: 'Paramètres modifiés',
          details: _diff(previous, next),
          outcome: AuditOutcome.success,
        );
  }

  static String _diff(AppSettings a, AppSettings b) {
    final am = a.toMap(), bm = b.toMap();
    return [
      for (final k in bm.keys)
        if (am[k] != bm[k]) '$k : ${am[k]} → ${bm[k]}',
    ].join(', ');
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(SettingsController.new);
