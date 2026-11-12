import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/app/app.dart';
import 'package:la_cambuse/app/providers.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/academy/presentation/academy_providers.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/ai/presentation/ai_providers.dart';

import '../helpers.dart';

const phone = Size(400, 860);
const desktop = Size(1280, 800);

Future<AppDatabase> pumpApp(WidgetTester tester,
    {required Size size, AppDatabase? db, List overrides = const [], SecretStore? secrets}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final database = db ?? memoryDb();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      // Lecture synchrone du vrai fichier de contenu (même JSON que l'app).
      courseLoaderProvider.overrideWithValue(
          (id) async => File('assets/courses/$id.json').readAsStringSync()),
      // Jamais le vrai trousseau du système dans les tests.
      secretStoreProvider.overrideWithValue(secrets ?? MemorySecretStore()),
      ...overrides,
    ],
    child: const CambuseApp(),
  ));
  await tester.pumpAndSettle();
  return database;
}

/// Démonte l'application (fin des flux Drift) sans fermer la base.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

/// Démonte puis ferme la base hors du temps simulé.
Future<void> teardown(WidgetTester tester, AppDatabase db) async {
  await unmount(tester);
  await tester.runAsync(db.close);
}

Future<T> dbRead<T>(WidgetTester tester, Future<T> Function() f) async =>
    (await tester.runAsync(f)) as T;
