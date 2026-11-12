import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/companion_link/data/companion_client.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../helpers.dart';
import 'academy_test.dart' show tapVisible;
import 'widget_helpers.dart';

/// Client scripté : la logique d'interface est testée ici, le réseau réel dans
/// test/companion/companion_contract_test.dart.
class ScriptedClient extends CompanionClient {
  ScriptedClient(AppDatabase db) : super(db: db, secrets: MemorySecretStore());

  CompanionLink? paired;
  final calls = <String>[];

  @override
  Future<CompanionLink?> link() async => paired;

  @override
  Future<Map<String, dynamic>> health(String baseUrl, {String? fingerprint}) async => {'apiVersion': 1};

  @override
  Future<CompanionLink> pair({required String baseUrl, required String code, required String deviceName, String? fingerprint}) async {
    calls.add('pair $code');
    if (code != '123456') throw const CompanionException(ErrorCodes.invalidCode, 'Code incorrect.');
    return paired = CompanionLink(baseUrl: baseUrl, deviceId: 'dev1', scopes: {Scope.read, Scope.gitWrite});
  }

  OpStatus _st(String type, OpState s, {Map<String, dynamic>? result, String stdout = ''}) => OpStatus(
      id: 'op-$type', type: type, state: s, result: result, stdout: stdout,
      plan: ['Dossier : /home/moi/Projets/demo', 'Commande exacte : git init --initial-branch=main']);

  @override
  Future<OpStatus> submit(OpRequest req) async {
    calls.add('submit ${req.type}');
    return switch (req.type) {
      'system.info' => _st(req.type, OpState.queued),
      'git.init' => _st(req.type, OpState.awaitingApproval),
      _ => _st(req.type, OpState.queued),
    };
  }

  @override
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async {
    final type = id.substring(3);
    return switch (type) {
      'system.info' => _st(type, OpState.succeeded, result: {'roots': ['/home/moi/Projets'], 'git': 'git version 2.34.1'}),
      'project.list' => _st(type, OpState.succeeded, result: {'projects': [
            {'name': 'vitrine', 'path': '/home/moi/Projets/vitrine', 'git': true},
          ]}),
      'git.status' => _st(type, OpState.succeeded, stdout: '## main\n?? README.md'),
      _ => _st(type, OpState.succeeded),
    };
  }

  @override
  Future<OpStatus> approve(String id) async {
    calls.add('approve $id');
    return _st(id.substring(3), OpState.queued);
  }

  @override
  Future<OpStatus> reject(String id) async {
    calls.add('reject $id');
    return _st(id.substring(3), OpState.rejected);
  }
}

/// Touche puis avance quelques images (la barre de progression indéterminée
/// empêche pumpAndSettle de se stabiliser pendant une opération).
Future<void> tapPump(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<ScriptedClient> open(WidgetTester tester, {Size size = phone}) async {
  final db = memoryDb();
  final client = ScriptedClient(db);
  await pumpApp(tester, size: size, db: db, overrides: [companionClientProvider.overrideWithValue(client)]);
  await tester.tap(find.byTooltip('Paramètres'));
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('Compagnon Linux'));
  return client;
}

void main() {
  testWidgets('appairage : code faux puis correct, instructions hôte affichées', (tester) async {
    final c = await open(tester);
    expect(find.textContaining('cambuse-companion serve --root'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Code d\'appairage (6 chiffres)'), '000000');
    await tapPump(tester, find.text('Appairer'));
    expect(find.text('Code incorrect.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Code d\'appairage (6 chiffres)'), '123456');
    await tapPump(tester, find.text('Appairer'));
    expect(find.textContaining('Appairé avec'), findsOneWidget);
    expect(find.text('/home/moi/Projets'), findsWidgets, reason: 'dossiers autorisés lus via system.info');
    expect(c.calls, containsAllInOrder(['pair 000000', 'pair 123456', 'submit system.info', 'submit project.list']));
    await tapPump(tester, find.text('vitrine'));
    expect(find.widgetWithText(TextField, '/home/moi/Projets/vitrine'), findsOneWidget);
    await teardown(tester, c.db);
  });

  testWidgets('mutation : refus dans le panneau d\'approbation → rien d\'autorisé', (tester) async {
    final c = await open(tester, size: desktop);
    await tester.enterText(find.widgetWithText(TextField, 'Code d\'appairage (6 chiffres)'), '123456');
    await tapPump(tester, find.text('Appairer'));
    await tapPump(tester, find.textContaining('Initialiser Git'));
    expect(find.text('Autoriser cette opération ?'), findsOneWidget);
    expect(find.text('Commande exacte : git init --initial-branch=main'), findsWidgets);
    expect(find.textContaining('toujours', findRichText: true), findsNothing);
    await tapPump(tester, find.text('Refuser'));
    expect(c.calls.last, 'reject op-git.init');
    expect(c.calls.where((x) => x.startsWith('approve')), isEmpty);
    expect(find.text('Opération refusée : rien n\'a été modifié.'), findsOneWidget);
    await teardown(tester, c.db);
  });

  testWidgets('mutation autorisée puis lecture git.status affichée', (tester) async {
    final c = await open(tester, size: desktop);
    await tester.enterText(find.widgetWithText(TextField, 'Code d\'appairage (6 chiffres)'), '123456');
    await tapPump(tester, find.text('Appairer'));
    await tapPump(tester, find.textContaining('Initialiser Git'));
    await tapPump(tester, find.text('Autoriser'));
    expect(c.calls, contains('approve op-git.init'));
    await tapPump(tester, find.textContaining('État Git'));
    expect(find.textContaining('?? README.md'), findsOneWidget);
    final log = await dbRead(tester, () => c.db.select(c.db.auditEntries).get());
    expect(log.map((e) => e.action), containsAll(['Appairage réussi', 'Opération autorisée', 'Opération git.status']));
    await teardown(tester, c.db);
  });
}
