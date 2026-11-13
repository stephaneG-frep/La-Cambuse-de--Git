import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cambuse_companion/cambuse_companion.dart';
import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

class Harness {
  Harness._(this.server, this.tmp, this.root, this.outside, this.clock);

  final CompanionServer server;
  final Directory tmp;
  final Directory root;
  final Directory outside;
  final FakeClock clock;
  final client = HttpClient();

  static Future<Harness> start({OpRunner Function(RootGuard)? runner}) async {
    final tmp = await Directory.systemTemp.createTemp('cambuse_comp_');
    final root = Directory('${tmp.path}/projets')..createSync();
    final outside = Directory('${tmp.path}/secret')..createSync();
    File('${outside.path}/id_rsa').writeAsStringSync('CLE PRIVEE FACTICE');
    final clock = FakeClock();
    final config = CompanionConfig(dataDir: Directory('${tmp.path}/data'), roots: [root.path], port: 0);
    final server = CompanionServer(config,
        clock: clock.now, runner: runner?.call(RootGuard([root.path])));
    await server.start();
    return Harness._(server, tmp, root, outside, clock);
  }

  Future<void> stop() async {
    client.close(force: true);
    await server.stop();
    await tmp.delete(recursive: true);
  }

  Future<(int, Map<String, dynamic>)> call(String method, String path,
      {Object? body, String? token, String? admin, String? rawBody}) async {
    final req = await client.openUrl(method, Uri.parse('http://127.0.0.1:${server.port}$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('authorization', 'Bearer $token');
    if (admin != null) req.headers.set('x-cambuse-admin', admin);
    if (rawBody != null) {
      req.write(rawBody);
    } else if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return (res.statusCode, jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>);
  }

  Future<String> pairingCode([String scopes = 'read']) async {
    final (s, j) = await call('POST', '/v1/pair/start', body: {'scopes': scopes}, admin: server.adminToken);
    expect(s, 200, reason: '$j');
    return (j['data'] as Map)['code'] as String;
  }

  Future<PairResult> pair([String scopes = 'read']) async {
    final code = await pairingCode(scopes);
    final (s, j) = await call('POST', '/v1/pair/complete', body: {'code': code, 'deviceName': 'Honor'});
    expect(s, 200, reason: '$j');
    return PairResult.fromJson(j['data'] as Map<String, dynamic>);
  }

  Future<OpStatus> submit(String token, String type, {String? rootPath, Map<String, dynamic> params = const {}}) async {
    final (s, j) = await call('POST', '/v1/ops',
        token: token, body: OpRequest(type: type, root: rootPath, params: params).toJson());
    if (s != 201) throw ApiFailure(s, (j['error'] as Map)['code'] as String, '${(j['error'] as Map)['message']}');
    return OpStatus.fromJson(j['data'] as Map<String, dynamic>);
  }

  Future<OpStatus> wait(String token, String id) async {
    for (var i = 0; i < 200; i++) {
      final (_, j) = await call('GET', '/v1/ops/$id', token: token);
      final st = OpStatus.fromJson(j['data'] as Map<String, dynamic>);
      if (st.state.isFinal || st.state == OpState.awaitingApproval) return st;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('opération non terminée');
  }

  Future<OpStatus> approve(String token, String id) async {
    final (s, j) = await call('POST', '/v1/ops/$id/approve', token: token);
    expect(s, 200, reason: '$j');
    return wait(token, id);
  }

  Directory repo(String name) {
    final d = Directory('${root.path}/$name')..createSync();
    Process.runSync('git', ['init', '-q', '-b', 'main'], workingDirectory: d.path);
    Process.runSync('git', ['config', 'user.name', 'Test'], workingDirectory: d.path);
    Process.runSync('git', ['config', 'user.email', 'test@exemple.fr'], workingDirectory: d.path);
    return d;
  }
}

class ApiFailure implements Exception {
  ApiFailure(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => 'ApiFailure($status, $code): $message';
}

Matcher failsWith(int status, String code) =>
    throwsA(isA<ApiFailure>().having((e) => e.status, 'status', status).having((e) => e.code, 'code', code));

class FakeClock {
  DateTime t = DateTime(2026, 11, 12, 12);
  DateTime now() => t;
  void advance(Duration d) => t = t.add(d);
}

