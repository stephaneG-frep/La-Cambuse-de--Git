import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/builds/presentation/builds_tab.dart';
import 'package:la_cambuse/features/companion_link/data/companion_client.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../helpers.dart';
import 'companion_screen_test.dart' show tapPump;
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient, openProject, tab;

/// Faux compagnon pour l'onglet Builds : les mutations attendent l'approbation.
class BuildsClient extends WorkshopClient {
  BuildsClient(super.db, {this.buildScope = true});
  final bool buildScope;
  final _mine = <String, OpStatus>{};

  static const _sha = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

  @override
  Future<OpStatus> submit(OpRequest req) async {
    final t = OpType.fromCode(req.type);
    if (t == null || !(t.scope == Scope.build || t == OpType.ciScaffold || t == OpType.artifactsList)) {
      return super.submit(req);
    }
    requests.add(req);
    if (!buildScope && t.scope == Scope.build) {
      throw const CompanionException(ErrorCodes.forbiddenScope, 'portée manquante');
    }
    final st = OpStatus(
      id: 'b${requests.length}',
      type: req.type,
      state: t.mutating ? OpState.awaitingApproval : OpState.succeeded,
      plan: ['Commande exacte : flutter build apk --debug --target-platform android-arm64'],
      result: t == OpType.artifactsList
          ? {
              'apksigner': true,
              'artifacts': [
                {
                  'path': 'build/app/outputs/flutter-apk/app-debug.apk', 'kind': 'apk', 'bytes': 142000000, 'sha256': _sha,
                  'signature': {'status': 'debug', 'certificate': 'C=US, O=Android, CN=Android Debug'},
                  'abis': ['arm64-v8a'],
                },
                {'path': 'build/linux/x64/release/bundle/carnet', 'kind': 'linux-bundle', 'bytes': 24000, 'sha256': _sha},
              ],
            }
          : null,
    );
    return _mine[st.id] = st;
  }

  @override
  Future<OpStatus> approve(String id) async {
    if (!_mine.containsKey(id)) return super.approve(id);
    approved.add(id);
    final t = _mine[id]!.type;
    return _mine[id] = OpStatus(
      id: id, type: t, state: OpState.succeeded, plan: const [],
      exitCode: t == OpType.ciScaffold.code ? null : 0,
      stdout: t == OpType.ciScaffold.code ? '' : '✓ Built build/app/outputs/flutter-apk/app-debug.apk',
      result: t == OpType.ciScaffold.code ? {'created': ['.github/workflows/ci.yml']} : null,
    );
  }

  @override
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async => _mine[id] ?? super.waitFor(id);
}

Future<BuildsClient> openBuilds(WidgetTester tester, {bool buildScope = true}) async {
  final db = memoryDb();
  final c = BuildsClient(db, buildScope: buildScope);
  await pumpApp(tester, size: desktop, db: db, overrides: [companionClientProvider.overrideWithValue(c)]);
  await tester.tap(find.text('Atelier').last);
  await tester.pumpAndSettle();
  await openProject(tester);
  await tab(tester, 'Builds');
  return c;
}

void main() {
  test('formatBytes', () {
    expect(formatBytes(512), '512 o');
    expect(formatBytes(2048), '2.0 Ko');
    expect(formatBytes(142000000), '135.4 Mo');
  });

  testWidgets('génération de CI : approbation, puis fichier annoncé', (tester) async {
    final c = await openBuilds(tester);
    expect(find.text('.github/workflows/ci.yml'), findsOneWidget);
    await tapPump(tester, find.text('Générer le pipeline'));
    expect(find.text('Autoriser cette opération ?'), findsOneWidget);
    await tapPump(tester, find.text('Autoriser'));
    await tester.pumpAndSettle();
    final req = c.requests.singleWhere((r) => r.type == 'ci.scaffold');
    expect(req.type, 'ci.scaffold');
    expect(req.params, {'kind': 'flutter', 'provider': 'github'});
    expect(c.approved, hasLength(1));
    expect(find.textContaining('ci.scaffold'), findsWidgets);
    await teardown(tester, c.db);
  });

  testWidgets('APK de test : refus sans exécution, puis build approuvé et cale « DEBUG »', (tester) async {
    final c = await openBuilds(tester);
    expect(find.textContaining('jamais distribuable'), findsOneWidget);
    await tapPump(tester, find.text('APK de test (debug)'));
    expect(find.textContaining('exécute du code du projet sur le PC'), findsOneWidget);
    expect(find.textContaining('modifie le dépôt'), findsNothing);
    await tapPump(tester, find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(c.approved, isEmpty);
    expect(find.textContaining('code de sortie'), findsNothing);

    await tapPump(tester, find.text('APK de test (debug)'));
    await tapPump(tester, find.text('Autoriser'));
    await tester.pumpAndSettle();
    expect(find.text('flutter.build.apk.debug : code de sortie 0'), findsOneWidget);
    expect(find.textContaining('Built build/app/outputs'), findsOneWidget);
    // La cale est inspectée automatiquement après un build réussi.
    expect(c.requests.map((r) => r.type), contains('artifacts.list'));
    await tester.scrollUntilVisible(find.text('DEBUG — non distribuable'), 200,
        scrollable: find.descendant(of: find.byType(BuildsTab), matching: find.byType(Scrollable)).first);
    expect(find.text('DEBUG — non distribuable'), findsOneWidget);
    expect(find.text('ABI : arm64-v8a'), findsOneWidget);
    expect(find.textContaining('135.4 Mo'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('linux-bundle'), 200,
        scrollable: find.descendant(of: find.byType(BuildsTab), matching: find.byType(Scrollable)).first);
    expect(find.textContaining('linux-bundle'), findsOneWidget);
    await teardown(tester, c.db);
  });

  testWidgets('portée « build » absente : message explicite', (tester) async {
    final c = await openBuilds(tester, buildScope: false);
    await tapPump(tester, find.text('flutter test'));
    await tester.pumpAndSettle();
    expect(find.textContaining('portée « build »'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await teardown(tester, c.db);
  });
}
