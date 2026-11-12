import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';
import 'features/logbook/domain/audit_outcome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );

  // Consigne le démarrage ; un échec ici ne doit pas empêcher l'app de s'ouvrir.
  container
      .read(logbookRepositoryProvider)
      .record(
        category: 'application',
        action: 'Démarrage de l\'application',
        outcome: AuditOutcome.info,
      )
      .catchError((Object e) {
    debugPrint('Journal indisponible au démarrage : $e');
    return -1;
  });

  runApp(UncontrolledProviderScope(container: container, child: const CambuseApp()));
}
