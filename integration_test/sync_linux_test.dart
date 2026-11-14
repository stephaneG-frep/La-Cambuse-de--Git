// Essai de bout en bout sur la cible Linux : la vraie application, le vrai
// compagnon (http://127.0.0.1:47820), une base temporaire (données de
// l'utilisateur intactes). Lancement :
//   flutter test integration_test/sync_linux_test.dart -d linux \
//     --dart-define=ADMIN_TOKEN_FILE=<dossier du compagnon>/admin.token
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:la_cambuse/app/app.dart';
import 'package:la_cambuse/app/providers.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/ai/presentation/ai_providers.dart';

const adminTokenFile = String.fromEnvironment('ADMIN_TOKEN_FILE');

/// Code d'appairage demandé au compagnon local (action réservée à l'hôte).
Future<String> pairingCode() async {
  final token = File(adminTokenFile).readAsStringSync().trim();
  final http = HttpClient();
  final req = await http.postUrl(Uri.parse('http://127.0.0.1:47820/v1/pair/start'));
  req.headers.contentType = ContentType.json;
  req.headers.set('x-cambuse-admin', token);
  req.write(jsonEncode({'scopes': 'read,sync'}));
  final res = await req.close();
  final body = jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>;
  http.close();
  return (body['data'] as Map)['code'] as String;
}

Future<void> settle(WidgetTester t, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Linux : appairage réel puis synchronisation avec la progression du téléphone', (tester) async {
    expect(adminTokenFile, isNotEmpty, reason: 'passer --dart-define=ADMIN_TOKEN_FILE=…');
    final dir = await Directory.systemTemp.createTemp('cambuse_sync_linux_');
    final db = AppDatabase(NativeDatabase(File('${dir.path}/cambuse.sqlite')));
    // Progression propre au PC : la première leçon Git terminée.
    await db.into(db.lessonProgress).insert(LessonProgressCompanion.insert(
        moduleId: 'git', lessonId: 'pourquoi-git', startedAt: DateTime(2026, 11, 14, 9),
        completedAt: Value(DateTime(2026, 11, 14, 9, 20)), bestScore: const Value(4), quizAttempts: const Value(1), exerciseDone: const Value(true)));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), secretStoreProvider.overrideWithValue(MemorySecretStore())],
      child: const CambuseApp(),
    ));
    await settle(tester);

    // Appairage par l'écran du compagnon.
    await tester.tap(find.byTooltip('Paramètres'));
    await settle(tester);
    await tester.tap(find.text('Compagnon Linux'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Code d\'appairage (6 chiffres)'), await pairingCode());
    await tester.tap(find.text('Appairer'));
    await settle(tester, 30);
    expect(find.textContaining('Appairé avec http://127.0.0.1:47820'), findsOneWidget);
    expect(find.textContaining('sync'), findsWidgets);

    // Synchronisation.
    await tester.tap(find.byTooltip('Retour').first);
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Synchroniser maintenant'), 200, scrollable: find.byType(Scrollable).hitTestable().last);
    await tester.tap(find.text('Synchroniser maintenant'));
    await settle(tester, 30);
    expect(find.textContaining('Synchronisé :'), findsOneWidget);

    final rows = await db.select(db.lessonProgress).get();
    final keys = {for (final r in rows) '${r.moduleId}/${r.lessonId}': r};
    // Progression venue du téléphone (labos réussis en phases 9 et 10).
    expect(keys['kubernetes/pods']?.exerciseDone, isTrue, reason: 'labo Kubernetes réussi sur le Honor');
    expect(keys.containsKey('docker/non-root'), isTrue);
    // Progression du PC conservée (terminée, meilleur score).
    expect(keys['git/pourquoi-git']?.completedAt, isNotNull);
    expect(keys['git/pourquoi-git']?.bestScore, 4);
    // ignore: avoid_print
    print('LIGNES APRÈS SYNCHRONISATION : ${keys.keys.toList()..sort()}');

    await tester.pumpWidget(const SizedBox());
    await db.close();
    await dir.delete(recursive: true);
  });
}
