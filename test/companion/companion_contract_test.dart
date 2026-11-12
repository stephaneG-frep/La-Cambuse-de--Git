import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/companion_link/data/companion_client.dart';

import '../helpers.dart';

/// Contrat client (application) ↔ serveur (compagnon réel, en processus).
void main() {
  late Directory tmp;
  late Directory root;
  late CompanionServer server;
  late AppDatabase db;
  late MemorySecretStore secrets;
  late CompanionClient client;
  var now = DateTime(2026, 11, 12, 12);

  Future<String> code(String scopes) async =>
      server.store.startPairing(Scope.parseList(scopes));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cambuse_contract_');
    root = Directory('${tmp.path}/projets')..createSync();
    now = DateTime(2026, 11, 12, 12);
    server = CompanionServer(
      CompanionConfig(dataDir: Directory('${tmp.path}/data'), roots: [root.path], port: 0, lan: true, lanPort: 0),
      clock: () => now,
    );
    await server.start();
    db = memoryDb();
    secrets = MemorySecretStore();
    client = CompanionClient(db: db, secrets: secrets);
  });

  tearDown(() async {
    await server.stop();
    await db.close();
    await tmp.delete(recursive: true);
  });

  String loopbackUrl() => 'http://127.0.0.1:${server.port}';
  String lanUrl() => 'https://127.0.0.1:${server.lanPort}';

  test('appairage loopback, persistance, jeton dans le coffre seulement', () async {
    final l = await client.pair(baseUrl: loopbackUrl(), code: await code('read'), deviceName: 'Honor');
    expect(l.scopes, {Scope.read});
    expect((await client.link())!.deviceId, l.deviceId);
    expect(secrets.values[CompanionClient.refreshKey], isNotNull);
    final rows = await db.select(db.appSettingsTable).get();
    expect(rows.map((r) => r.value).join(), isNot(contains(secrets.values[CompanionClient.refreshKey]!)));
  });

  test('opération de lecture de bout en bout (git.status sur vrai dépôt)', () async {
    final repo = Directory('${root.path}/demo')..createSync();
    Process.runSync('git', ['init', '-q', '-b', 'main'], workingDirectory: repo.path);
    File('${repo.path}/README.md').writeAsStringSync('x');
    await client.pair(baseUrl: loopbackUrl(), code: await code('read'), deviceName: 'Honor');
    final op = await client.submit(OpRequest(type: OpType.gitStatus.code, root: repo.path));
    final st = await client.waitFor(op.id);
    expect(st.state, OpState.succeeded);
    expect(st.stdout, contains('?? README.md'));
    final info = await client.waitFor((await client.submit(const OpRequest(type: 'system.info'))).id);
    expect(info.result!['roots'], [root.resolveSymbolicLinksSync()]);
  });

  test('approbation explicite d\'une mutation', () async {
    final d = Directory('${root.path}/neuf')..createSync();
    await client.pair(baseUrl: loopbackUrl(), code: await code('read,git-write'), deviceName: 'Honor');
    final op = await client.submit(OpRequest(type: OpType.gitInit.code, root: d.path));
    expect(op.state, OpState.awaitingApproval);
    expect(Directory('${d.path}/.git').existsSync(), isFalse);
    await client.approve(op.id);
    expect((await client.waitFor(op.id)).state, OpState.succeeded);
    expect(Directory('${d.path}/.git').existsSync(), isTrue);
  });

  test('jeton d\'accès expiré : rafraîchi automatiquement (rotation enregistrée)', () async {
    await client.pair(baseUrl: loopbackUrl(), code: await code('read'), deviceName: 'Honor');
    final firstRefresh = secrets.values[CompanionClient.refreshKey];
    now = now.add(const Duration(minutes: 20));
    final info = await client.waitFor((await client.submit(const OpRequest(type: 'system.info'))).id);
    expect(info.state, OpState.succeeded);
    expect(secrets.values[CompanionClient.refreshKey], isNot(firstRefresh));
  });

  test('erreurs typées : portée, chemin hors racine, code faux', () async {
    await client.pair(baseUrl: loopbackUrl(), code: await code('read'), deviceName: 'Honor');
    await expectLater(client.submit(OpRequest(type: OpType.gitInit.code, root: root.path)),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', ErrorCodes.forbiddenScope)));
    await expectLater(client.submit(OpRequest(type: OpType.gitStatus.code, root: tmp.path)),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', ErrorCodes.pathOutsideRoot)));
    await code('read');
    await expectLater(client.pair(baseUrl: loopbackUrl(), code: '000000', deviceName: 'x'),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', ErrorCodes.invalidCode)));
  });

  test('TLS : empreinte correcte acceptée, empreinte fausse refusée, HTTP distant interdit', () async {
    final fp = server.tlsFingerprint!;
    expect((await client.health(lanUrl(), fingerprint: fp))['tls'], isTrue);
    final wrong = fp.replaceRange(0, 2, fp.startsWith('00') ? '11' : '00');
    await expectLater(client.health(lanUrl(), fingerprint: wrong),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'fingerprint_mismatch')));
    await expectLater(client.health(lanUrl()),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'fingerprint_required')));
    expect(() => CompanionClient.validateBaseUrl('http://192.168.1.20:47821'),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'tls_required')));
    final l = await client.pair(baseUrl: lanUrl(), code: await code('read'), deviceName: 'Honor', fingerprint: fp);
    expect(l.fingerprint, fp);
    final st = await client.waitFor((await client.submit(const OpRequest(type: 'system.info'))).id);
    expect(st.state, OpState.succeeded);
  });

  test('compagnon arrêté : erreur claire « injoignable »', () async {
    final url = loopbackUrl();
    await server.stop();
    await expectLater(client.health(url),
        throwsA(isA<CompanionException>().having((e) => e.code, 'code', 'unreachable')));
    server = CompanionServer(CompanionConfig(dataDir: Directory('${tmp.path}/data2'), roots: [root.path], port: 0));
    await server.start();
  });

  test('oubli local : liens et jeton supprimés', () async {
    await client.pair(baseUrl: loopbackUrl(), code: await code('read'), deviceName: 'Honor');
    await client.forget();
    expect(await client.link(), isNull);
    expect(secrets.values, isEmpty);
  });
}
