import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'audit.dart';
import 'ops.dart';
import 'paths.dart';
import 'store.dart';
import 'tls.dart';

const companionVersion = '0.1.0';

class CompanionConfig {
  CompanionConfig({
    required this.dataDir,
    required this.roots,
    this.port = defaultLoopbackPort,
    this.lan = false,
    this.lanPort = defaultLanPort,
  });

  final Directory dataDir;
  final List<String> roots;
  final int port;
  final bool lan;
  final int lanPort;
}

class _ApiError implements Exception {
  _ApiError(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
}

/// Serveur HTTP du compagnon. Toujours sur 127.0.0.1 ; réseau local seulement
/// en TLS et sur demande explicite (`--lan`).
class CompanionServer {
  CompanionServer(this.config, {DateTime Function()? clock, OpRunner? runner})
      : store = DeviceStore(config.dataDir, clock: clock),
        audit = AuditLog(config.dataDir, clock: clock),
        runner = runner ?? OpRunner(RootGuard(config.roots));

  final CompanionConfig config;
  final DeviceStore store;
  final AuditLog audit;
  final OpRunner runner;
  late final String adminToken;
  HttpServer? _loopback;
  HttpServer? _lan;
  String? tlsFingerprint;

  static const maxBody = 64 * 1024;

  int get port => _loopback!.port;
  int? get lanPort => _lan?.port;

  File get adminTokenFile => File('${config.dataDir.path}/admin.token');

  Future<void> start() async {
    config.dataDir.createSync(recursive: true);
    Process.runSync('chmod', ['700', config.dataDir.path]);
    adminToken = randomToken();
    adminTokenFile.writeAsStringSync(adminToken, flush: true);
    setOwnerOnly(adminTokenFile.path);
    _loopback = await HttpServer.bind(InternetAddress.loopbackIPv4, config.port);
    _loopback!.listen((r) => _handle(r, local: true));
    if (config.lan) {
      final tls = await TlsMaterial.ensure(config.dataDir);
      tlsFingerprint = tls.fingerprint();
      _lan = await HttpServer.bindSecure(InternetAddress.anyIPv4, config.lanPort, tls.context());
      _lan!.listen((r) => _handle(r, local: false));
    }
    audit.record('server.start', details: {
      'port': port,
      'lan': config.lan,
      'roots': runner.guard.roots,
    });
  }

  Future<void> stop() async {
    await _loopback?.close(force: true);
    await _lan?.close(force: true);
    if (adminTokenFile.existsSync()) adminTokenFile.deleteSync();
    audit.record('server.stop');
  }

  Future<void> _handle(HttpRequest req, {required bool local}) async {
    final res = req.response;
    res.headers
      ..contentType = ContentType.json
      ..set('cache-control', 'no-store')
      ..set('x-content-type-options', 'nosniff');
    try {
      final data = await _route(req, local: local);
      res.statusCode = data.$1;
      res.write(jsonEncode(okEnvelope(data.$2)));
    } on _ApiError catch (e) {
      res.statusCode = e.status;
      res.write(jsonEncode(errorEnvelope(e.code, e.message)));
    } on PathViolation catch (e) {
      res.statusCode = 403;
      res.write(jsonEncode(errorEnvelope(e.code, e.message)));
    } on OpValidationError catch (e) {
      res.statusCode = e.code == ErrorCodes.conflict ? 409 : 400;
      res.write(jsonEncode(errorEnvelope(e.code, e.message)));
    } catch (e) {
      res.statusCode = 500;
      res.write(jsonEncode(errorEnvelope('internal', 'Erreur interne du compagnon.')));
      audit.record('error', details: {'error': '$e'});
    } finally {
      await res.close();
    }
  }

  Future<Map<String, dynamic>> _body(HttpRequest req) async {
    final chunks = <int>[];
    await for (final c in req) {
      chunks.addAll(c);
      if (chunks.length > maxBody) throw _ApiError(413, ErrorCodes.tooLarge, 'Requête trop volumineuse.');
    }
    if (chunks.isEmpty) return {};
    try {
      return jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
    } catch (_) {
      throw _ApiError(400, ErrorCodes.invalidRequest, 'JSON invalide.');
    }
  }

  void _requireAdmin(HttpRequest req, bool local) {
    final given = req.headers.value('x-cambuse-admin') ?? '';
    if (!local || !constantTimeEquals(given, adminToken)) {
      throw _ApiError(403, ErrorCodes.localOnly,
          'Action réservée à l\'hôte (console locale avec jeton administrateur).');
    }
  }

  Device _requireDevice(HttpRequest req) {
    final auth = req.headers.value(HttpHeaders.authorizationHeader);
    final token = auth != null && auth.startsWith('Bearer ') ? auth.substring(7) : null;
    final dev = store.authenticate(token);
    if (dev == null) throw _ApiError(401, ErrorCodes.unauthorized, 'Jeton absent, invalide ou expiré.');
    return dev;
  }

  OpRecord _ownOp(Device dev, String id) {
    final rec = runner.get(id);
    if (rec == null || rec.deviceId != dev.id) {
      throw _ApiError(404, ErrorCodes.notFound, 'Opération introuvable.');
    }
    return rec;
  }

  Future<(int, Object?)> _route(HttpRequest req, {required bool local}) async {
    final seg = req.uri.pathSegments;
    final m = req.method;
    if (seg.isEmpty || seg.first != 'v1') throw _ApiError(404, ErrorCodes.notFound, 'Route inconnue.');
    final path = seg.skip(1).join('/');

    if (m == 'GET' && path == 'health') {
      return (200, {
        'name': 'cambuse-companion',
        'version': companionVersion,
        'apiVersion': apiVersion,
        'tls': !local,
      });
    }
    if (m == 'POST' && path == 'pair/start') {
      _requireAdmin(req, local);
      final body = await _body(req);
      final scopes = Scope.parseList((body['scopes'] as String?) ?? 'read');
      final code = store.startPairing(scopes);
      audit.record('pair.start', details: {'scopes': [for (final s in scopes) s.code]});
      return (200, {
        'code': code,
        'expiresIn': DeviceStore.codeTtl.inSeconds,
        'fingerprint': ?tlsFingerprint,
      });
    }
    if (m == 'POST' && path == 'pair/complete') {
      final body = await _body(req);
      try {
        final r = store.completePairing('${body['code'] ?? ''}', '${body['deviceName'] ?? ''}');
        audit.record('pair.complete', deviceId: r.deviceId,
            details: {'scopes': [for (final s in r.scopes) s.code], 'via': local ? 'loopback' : 'lan'});
        return (200, r.toJson());
      } on PairingError catch (e) {
        audit.record('pair.failed', details: {'reason': e.code});
        throw _ApiError(e.code == ErrorCodes.pairingLocked ? 429 : 401, e.code, e.message);
      }
    }
    if (m == 'POST' && path == 'token/refresh') {
      final body = await _body(req);
      final r = store.refresh('${body['deviceId'] ?? ''}', '${body['refreshToken'] ?? ''}');
      if (r == null) throw _ApiError(401, ErrorCodes.unauthorized, 'Jeton de rafraîchissement invalide ou révoqué.');
      return (200, r.toJson());
    }
    if (path == 'devices' && m == 'GET') {
      _requireAdmin(req, local);
      return (200, [
        for (final d in store.devices)
          {'id': d.id, 'name': d.name, 'scopes': [for (final s in d.scopes) s.code],
           'createdAt': d.createdAt.toIso8601String(), 'lastSeen': d.lastSeen?.toIso8601String()},
      ]);
    }
    if (seg.length == 3 && seg[1] == 'devices' && m == 'DELETE') {
      _requireAdmin(req, local);
      if (!store.revoke(seg[2])) throw _ApiError(404, ErrorCodes.notFound, 'Appareil inconnu.');
      audit.record('device.revoked', deviceId: seg[2]);
      return (200, {'revoked': seg[2]});
    }

    // ---- Routes authentifiées par appareil.
    final dev = _requireDevice(req);
    if (m == 'GET' && path == 'me') {
      return (200, {'deviceId': dev.id, 'name': dev.name, 'scopes': [for (final s in dev.scopes) s.code]});
    }
    if (m == 'GET' && path == 'audit') {
      final n = int.tryParse(req.uri.queryParameters['limit'] ?? '') ?? 50;
      return (200, audit.tail(1000).where((e) => e['device'] == dev.id).toList().reversed.take(n.clamp(1, 200)).toList());
    }
    if (m == 'POST' && path == 'ops') {
      final opReq = OpRequest.fromJson(await _body(req));
      final type = OpType.fromCode(opReq.type);
      if (type == null) throw _ApiError(400, ErrorCodes.unknownOp, 'Opération inconnue : ${opReq.type}');
      if (!dev.scopes.contains(type.scope)) {
        audit.record('op.forbidden', deviceId: dev.id, details: {'type': type.code});
        throw _ApiError(403, ErrorCodes.forbiddenScope,
            'Cet appareil n\'a pas la portée « ${type.scope.code} » (à accorder sur l\'hôte lors de l\'appairage).');
      }
      final prepared = runner.prepare(opReq);
      final rec = runner.submit(dev.id, prepared);
      audit.record('op.submitted', deviceId: dev.id,
          details: {'op': rec.id, 'type': type.code, 'root': prepared.root, 'plan': prepared.plan});
      return (201, rec.toStatus().toJson());
    }
    if (seg.length >= 3 && seg[1] == 'ops') {
      final rec = _ownOp(dev, seg[2]);
      final action = seg.length == 4 ? seg[3] : null;
      if (m == 'GET' && action == null) return (200, rec.toStatus().toJson());
      if (m == 'POST' && action == 'approve') {
        runner.approve(rec);
        audit.record('op.approved', deviceId: dev.id, details: {'op': rec.id, 'type': rec.prepared.type.code});
        unawaited(runner.idle().then((_) => audit.record('op.finished', deviceId: dev.id,
            details: {'op': rec.id, 'state': rec.state.code, 'exitCode': rec.exitCode})));
        return (200, rec.toStatus().toJson());
      }
      if (m == 'POST' && action == 'reject') {
        runner.reject(rec);
        audit.record('op.rejected', deviceId: dev.id, details: {'op': rec.id});
        return (200, rec.toStatus().toJson());
      }
      if (m == 'POST' && action == 'cancel') {
        runner.cancel(rec);
        audit.record('op.cancel', deviceId: dev.id, details: {'op': rec.id});
        return (200, rec.toStatus().toJson());
      }
    }
    throw _ApiError(404, ErrorCodes.notFound, 'Route inconnue.');
  }
}
