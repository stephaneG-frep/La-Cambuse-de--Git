import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide JsonKey;

import '../../../core/db/database.dart';
import '../../ai/data/secret_store.dart';

class CompanionException implements Exception {
  const CompanionException(this.code, this.message, {this.status});
  final String code;
  final String message;
  final int? status;

  @override
  String toString() => 'CompanionException($code${status == null ? '' : ', $status'}): $message';
}

/// Informations d'appairage persistées (hors secrets).
class CompanionLink {
  const CompanionLink({required this.baseUrl, required this.deviceId, this.fingerprint, this.scopes = const {}});

  final String baseUrl;
  final String deviceId;
  final String? fingerprint;
  final Set<Scope> scopes;
}

String formatFingerprint(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');

String normalizeFingerprint(String f) => f.replaceAll(RegExp('[^0-9A-Fa-f]'), '').toUpperCase();

/// Client HTTP du compagnon. En HTTPS, l'empreinte SHA-256 du certificat est
/// **épinglée** : vérifiée à chaque réponse, pas seulement en cas d'erreur de
/// validation. Le jeton de rafraîchissement vit dans le coffre du système.
class CompanionClient {
  CompanionClient({
    required this.db,
    required this.secrets,
    HttpClient Function()? httpFactory,
    this.timeout = const Duration(seconds: 15),
  }) : _httpFactory = httpFactory ?? HttpClient.new;

  final AppDatabase db;
  final SecretStore secrets;
  final HttpClient Function() _httpFactory;
  final Duration timeout;
  String? _accessToken;

  static const refreshKey = 'companion.refresh_token';

  // ------------------------------------------------------------ Persistance

  Future<CompanionLink?> link() async {
    final rows = await (db.select(db.appSettingsTable)..where((t) => t.key.like('companion.%'))).get();
    final m = {for (final r in rows) r.key: r.value};
    if (m['companion.base_url'] == null || m['companion.device_id'] == null) return null;
    return CompanionLink(
      baseUrl: m['companion.base_url']!,
      deviceId: m['companion.device_id']!,
      fingerprint: (m['companion.fingerprint'] ?? '').isEmpty ? null : m['companion.fingerprint'],
      scopes: Scope.parseList(m['companion.scopes'] ?? ''),
    );
  }

  Future<void> _saveLink(CompanionLink l) => db.transaction(() async {
        for (final e in {
          'companion.base_url': l.baseUrl,
          'companion.device_id': l.deviceId,
          'companion.fingerprint': l.fingerprint ?? '',
          'companion.scopes': l.scopes.map((s) => s.code).join(','),
        }.entries) {
          await db.into(db.appSettingsTable).insertOnConflictUpdate(
              AppSettingsTableCompanion.insert(key: e.key, value: e.value));
        }
      });

  /// Oubli local (la révocation se fait sur l'hôte : `cambuse-companion revoke`).
  Future<void> forget() async {
    _accessToken = null;
    await secrets.delete(refreshKey);
    await (db.delete(db.appSettingsTable)..where((t) => t.key.like('companion.%'))).go();
  }

  // ---------------------------------------------------------------- Transport

  static Uri validateBaseUrl(String raw) {
    final u = Uri.tryParse(raw.trim());
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      throw const CompanionException('invalid_url', 'Adresse invalide (ex. http://127.0.0.1:47820).');
    }
    final loopback = u.host == '127.0.0.1' || u.host == 'localhost' || u.host == '::1';
    if (u.scheme == 'http' && !loopback) {
      throw const CompanionException('tls_required',
          'Hors de cet appareil, la connexion doit être en HTTPS (option --lan du compagnon).');
    }
    return u;
  }

  Future<Map<String, dynamic>> _request(String baseUrl, String? fingerprint, String method, String path,
      {Object? body, String? token}) async {
    final base = validateBaseUrl(baseUrl);
    final pinned = fingerprint == null ? null : normalizeFingerprint(fingerprint);
    if (base.scheme == 'https' && (pinned == null || pinned.length != 64)) {
      throw const CompanionException('fingerprint_required',
          'Empreinte TLS requise : recopiez celle affichée par « cambuse-companion pair ».');
    }
    final http = _httpFactory()
      ..connectionTimeout = timeout
      ..badCertificateCallback = (cert, host, port) =>
          pinned != null && normalizeFingerprint(formatFingerprint(sha256.convert(cert.der).bytes)) == pinned;
    try {
      final req = await http.openUrl(method, base.resolve(path)).timeout(timeout);
      req.headers.contentType = ContentType.json;
      if (token != null) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) req.write(jsonEncode(body));
      final res = await req.close().timeout(timeout);
      if (base.scheme == 'https') {
        final cert = res.certificate;
        final got = cert == null ? '' : normalizeFingerprint(formatFingerprint(sha256.convert(cert.der).bytes));
        if (got != pinned) {
          throw const CompanionException('fingerprint_mismatch',
              'Empreinte TLS différente de celle attendue : connexion refusée (possible usurpation).');
        }
      }
      final text = await utf8.decodeStream(res).timeout(timeout);
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(text) as Map<String, dynamic>;
      } on FormatException {
        throw CompanionException('bad_response', 'Réponse inattendue (HTTP ${res.statusCode}).', status: res.statusCode);
      }
      if (json['ok'] != true) {
        final err = (json['error'] as Map?) ?? const {};
        throw CompanionException('${err['code'] ?? 'error'}', '${err['message'] ?? 'Erreur'}', status: res.statusCode);
      }
      return {'data': json['data']};
    } on HandshakeException {
      throw const CompanionException('fingerprint_mismatch',
          'Certificat TLS refusé : empreinte différente de celle attendue.');
    } on SocketException catch (e) {
      throw CompanionException('unreachable', 'Compagnon injoignable (${e.message}). Est-il démarré ?');
    } on TimeoutException {
      throw const CompanionException('timeout', 'Le compagnon ne répond pas.');
    } finally {
      http.close(force: true);
    }
  }

  Future<dynamic> _authed(String method, String path, {Object? body}) async {
    final l = await link();
    if (l == null) throw const CompanionException('not_paired', 'Aucun compagnon appairé.');
    _accessToken ??= await _refresh(l);
    try {
      return (await _request(l.baseUrl, l.fingerprint, method, path, body: body, token: _accessToken))['data'];
    } on CompanionException catch (e) {
      if (e.status != 401) rethrow;
      _accessToken = await _refresh(l);
      return (await _request(l.baseUrl, l.fingerprint, method, path, body: body, token: _accessToken))['data'];
    }
  }

  Future<String> _refresh(CompanionLink l) async {
    final rt = await secrets.read(refreshKey);
    if (rt == null) throw const CompanionException('not_paired', 'Jeton absent : appairez à nouveau.');
    final r = await _request(l.baseUrl, l.fingerprint, 'POST', '/v1/token/refresh',
        body: {'deviceId': l.deviceId, 'refreshToken': rt});
    final pr = PairResult.fromJson(r['data'] as Map<String, dynamic>);
    await secrets.write(refreshKey, pr.refreshToken);
    return pr.accessToken;
  }

  // -------------------------------------------------------------------- API

  Future<Map<String, dynamic>> health(String baseUrl, {String? fingerprint}) async =>
      (await _request(baseUrl, fingerprint, 'GET', '/v1/health'))['data'] as Map<String, dynamic>;

  Future<CompanionLink> pair({
    required String baseUrl,
    required String code,
    required String deviceName,
    String? fingerprint,
  }) async {
    final r = await _request(baseUrl, fingerprint, 'POST', '/v1/pair/complete',
        body: {'code': code.trim(), 'deviceName': deviceName});
    final pr = PairResult.fromJson(r['data'] as Map<String, dynamic>);
    await secrets.write(refreshKey, pr.refreshToken);
    _accessToken = pr.accessToken;
    final l = CompanionLink(
      baseUrl: validateBaseUrl(baseUrl).toString().replaceAll(RegExp(r'/$'), ''),
      deviceId: pr.deviceId,
      fingerprint: fingerprint == null || fingerprint.trim().isEmpty ? null : fingerprint.trim(),
      scopes: pr.scopes,
    );
    await _saveLink(l);
    return l;
  }

  Future<OpStatus> submit(OpRequest req) async =>
      OpStatus.fromJson(await _authed('POST', '/v1/ops', body: req.toJson()) as Map<String, dynamic>);

  Future<OpStatus> status(String id) async =>
      OpStatus.fromJson(await _authed('GET', '/v1/ops/$id') as Map<String, dynamic>);

  Future<OpStatus> approve(String id) async =>
      OpStatus.fromJson(await _authed('POST', '/v1/ops/$id/approve') as Map<String, dynamic>);

  Future<OpStatus> reject(String id) async =>
      OpStatus.fromJson(await _authed('POST', '/v1/ops/$id/reject') as Map<String, dynamic>);

  Future<OpStatus> cancel(String id) async =>
      OpStatus.fromJson(await _authed('POST', '/v1/ops/$id/cancel') as Map<String, dynamic>);

  Future<List<Map<String, dynamic>>> audit({int limit = 50}) async =>
      ((await _authed('GET', '/v1/audit?limit=$limit')) as List).cast<Map<String, dynamic>>();

  /// Attend l'état final (ou l'attente d'approbation).
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(max);
    while (true) {
      final st = await status(id);
      if (st.state.isFinal || st.state == OpState.awaitingApproval) return st;
      if (DateTime.now().isAfter(end)) {
        throw const CompanionException('timeout', 'Opération toujours en cours.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}
