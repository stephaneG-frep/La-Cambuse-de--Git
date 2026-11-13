import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/logging/redactor.dart';

enum ForgeKind {
  github('github', 'GitHub'),
  gitlab('gitlab', 'GitLab');

  const ForgeKind(this.code, this.label);
  final String code;
  final String label;
}

enum ForgeErrorKind { noToken, authentication, forbidden, rateLimited, notFound, validation, network, unknown }

class ForgeException implements Exception {
  const ForgeException(this.kind, this.message, {this.status});
  final ForgeErrorKind kind;
  final String message;
  final int? status;
  @override
  String toString() => 'ForgeException($kind, $status): $message';
}

class ForgeRepo {
  const ForgeRepo({
    required this.fullName,
    required this.private,
    required this.defaultBranch,
    required this.webUrl,
    required this.cloneUrl,
  });
  final String fullName;
  final bool private;
  final String defaultBranch;
  final String webUrl;
  final String cloneUrl;
}

class ForgeItem {
  const ForgeItem(this.number, this.title, this.url, {this.state = 'open'});
  final int number;
  final String title;
  final String url;
  final String state;
}

/// Dépôt distant déduit d'une URL HTTPS de remote.
class RemoteRef {
  const RemoteRef(this.kind, this.host, this.fullName);
  final ForgeKind kind;
  final String host;
  final String fullName;

  static RemoteRef? parse(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null || u.scheme != 'https' || u.userInfo.isNotEmpty) return null;
    final segs = u.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length < 2) return null;
    var name = segs.join('/');
    if (name.endsWith('.git')) name = name.substring(0, name.length - 4);
    final kind = u.host.contains('gitlab') ? ForgeKind.gitlab : ForgeKind.github;
    if (kind == ForgeKind.github && segs.length != 2) return null;
    return RemoteRef(kind, u.host, name);
  }
}

/// Interface commune GitHub / GitLab (API REST, jeton à portée minimale).
abstract class Forge {
  Forge({required this.token, http.Client? client}) : client = client ?? http.Client();

  final Future<String?> Function() token;
  final http.Client client;
  static const _redactor = Redactor();

  ForgeKind get kind;
  Uri api(String path, [Map<String, String>? query]);
  Map<String, String> authHeaders(String token);

  Future<String> currentUser();
  Future<ForgeRepo> repo(String fullName);
  Future<ForgeRepo> createPrivateRepo(String name, {String description = ''});
  Future<List<ForgeItem>> openChangeRequests(String fullName);
  Future<ForgeItem> createChangeRequest(String fullName,
      {required String head, required String base, required String title, String body = ''});
  Future<List<ForgeItem>> openIssues(String fullName);
  Future<ForgeItem> createIssue(String fullName, {required String title, String body = ''});

  Future<dynamic> send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final t = (await token())?.trim();
    if (t == null || t.isEmpty) {
      throw ForgeException(ForgeErrorKind.noToken, 'Aucun jeton ${kind.label} enregistré.');
    }
    final req = http.Request(method, api(path, query))
      ..headers.addAll({...authHeaders(t), 'content-type': 'application/json', 'user-agent': 'la-cambuse-de-git'});
    if (body != null) req.body = jsonEncode(body);
    final http.Response res;
    try {
      res = await http.Response.fromStream(await client.send(req).timeout(const Duration(seconds: 20)));
    } on TimeoutException {
      throw ForgeException(ForgeErrorKind.network, '${kind.label} ne répond pas.');
    } on http.ClientException catch (e) {
      throw ForgeException(ForgeErrorKind.network, 'Réseau indisponible : ${e.message}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    var msg = 'HTTP ${res.statusCode}';
    try {
      final j = jsonDecode(res.body);
      if (j is Map) {
        msg = '${j['message'] ?? j['error'] ?? msg}';
        final errs = j['errors'];
        if (errs is List && errs.isNotEmpty) {
          msg += ' — ${errs.map((e) => e is Map ? (e['message'] ?? e['code'] ?? e) : e).join(', ')}';
        }
      }
    } catch (_) {}
    msg = _redactor.redact(msg);
    final limited = res.headers['x-ratelimit-remaining'] == '0' || res.statusCode == 429;
    throw ForgeException(
      switch (res.statusCode) {
        401 => ForgeErrorKind.authentication,
        403 when limited => ForgeErrorKind.rateLimited,
        429 => ForgeErrorKind.rateLimited,
        403 => ForgeErrorKind.forbidden,
        404 => ForgeErrorKind.notFound,
        409 || 422 || 400 => ForgeErrorKind.validation,
        _ => ForgeErrorKind.unknown,
      },
      msg,
      status: res.statusCode,
    );
  }
}

class GitHubForge extends Forge {
  GitHubForge({required super.token, super.client, this.apiBase = 'https://api.github.com'});

  final String apiBase;

  @override
  ForgeKind get kind => ForgeKind.github;

  @override
  Uri api(String path, [Map<String, String>? query]) => Uri.parse('$apiBase$path').replace(queryParameters: query);

  @override
  Map<String, String> authHeaders(String token) => {
        'authorization': 'Bearer $token',
        'accept': 'application/vnd.github+json',
        'x-github-api-version': '2022-11-28',
      };

  ForgeRepo _repo(Map j) => ForgeRepo(
        fullName: j['full_name'] as String,
        private: j['private'] == true,
        defaultBranch: (j['default_branch'] as String?) ?? 'main',
        webUrl: j['html_url'] as String,
        cloneUrl: j['clone_url'] as String,
      );

  static String _path(String fullName) {
    if (!RegExp(r'^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$').hasMatch(fullName)) {
      throw const ForgeException(ForgeErrorKind.validation, 'Nom de dépôt attendu : propriétaire/nom.');
    }
    return fullName;
  }

  @override
  Future<String> currentUser() async => (await send('GET', '/user') as Map)['login'] as String;

  @override
  Future<ForgeRepo> repo(String fullName) async => _repo(await send('GET', '/repos/${_path(fullName)}') as Map);

  @override
  Future<ForgeRepo> createPrivateRepo(String name, {String description = ''}) async =>
      _repo(await send('POST', '/user/repos', body: {'name': name, 'private': true, 'description': description}) as Map);

  @override
  Future<List<ForgeItem>> openChangeRequests(String fullName) async => [
        for (final p in await send('GET', '/repos/${_path(fullName)}/pulls', query: {'state': 'open'}) as List)
          ForgeItem(p['number'] as int, p['title'] as String, p['html_url'] as String),
      ];

  @override
  Future<ForgeItem> createChangeRequest(String fullName,
      {required String head, required String base, required String title, String body = ''}) async {
    final p = await send('POST', '/repos/${_path(fullName)}/pulls',
        body: {'head': head, 'base': base, 'title': title, 'body': body}) as Map;
    return ForgeItem(p['number'] as int, p['title'] as String, p['html_url'] as String);
  }

  @override
  Future<List<ForgeItem>> openIssues(String fullName) async => [
        for (final i in await send('GET', '/repos/${_path(fullName)}/issues', query: {'state': 'open'}) as List)
          // L'API GitHub mélange tickets et PR : on écarte les PR.
          if ((i as Map)['pull_request'] == null) ForgeItem(i['number'] as int, i['title'] as String, i['html_url'] as String),
      ];

  @override
  Future<ForgeItem> createIssue(String fullName, {required String title, String body = ''}) async {
    final i = await send('POST', '/repos/${_path(fullName)}/issues', body: {'title': title, 'body': body}) as Map;
    return ForgeItem(i['number'] as int, i['title'] as String, i['html_url'] as String);
  }
}

class GitLabForge extends Forge {
  GitLabForge({required super.token, super.client, this.baseUrl = 'https://gitlab.com'});

  final String baseUrl;

  @override
  ForgeKind get kind => ForgeKind.gitlab;

  @override
  Uri api(String path, [Map<String, String>? query]) =>
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v4$path').replace(queryParameters: query);

  @override
  Map<String, String> authHeaders(String token) => {'authorization': 'Bearer $token'};

  static String _id(String fullName) => Uri.encodeComponent(fullName);

  ForgeRepo _repo(Map j) => ForgeRepo(
        fullName: j['path_with_namespace'] as String,
        private: j['visibility'] == 'private',
        defaultBranch: (j['default_branch'] as String?) ?? 'main',
        webUrl: j['web_url'] as String,
        cloneUrl: j['http_url_to_repo'] as String,
      );

  @override
  Future<String> currentUser() async => (await send('GET', '/user') as Map)['username'] as String;

  @override
  Future<ForgeRepo> repo(String fullName) async => _repo(await send('GET', '/projects/${_id(fullName)}') as Map);

  @override
  Future<ForgeRepo> createPrivateRepo(String name, {String description = ''}) async =>
      _repo(await send('POST', '/projects', body: {'name': name, 'visibility': 'private', 'description': description}) as Map);

  @override
  Future<List<ForgeItem>> openChangeRequests(String fullName) async => [
        for (final m in await send('GET', '/projects/${_id(fullName)}/merge_requests', query: {'state': 'opened'}) as List)
          ForgeItem(m['iid'] as int, m['title'] as String, m['web_url'] as String),
      ];

  @override
  Future<ForgeItem> createChangeRequest(String fullName,
      {required String head, required String base, required String title, String body = ''}) async {
    final m = await send('POST', '/projects/${_id(fullName)}/merge_requests',
        body: {'source_branch': head, 'target_branch': base, 'title': title, 'description': body}) as Map;
    return ForgeItem(m['iid'] as int, m['title'] as String, m['web_url'] as String);
  }

  @override
  Future<List<ForgeItem>> openIssues(String fullName) async => [
        for (final i in await send('GET', '/projects/${_id(fullName)}/issues', query: {'state': 'opened'}) as List)
          ForgeItem(i['iid'] as int, i['title'] as String, i['web_url'] as String),
      ];

  @override
  Future<ForgeItem> createIssue(String fullName, {required String title, String body = ''}) async {
    final i = await send('POST', '/projects/${_id(fullName)}/issues', body: {'title': title, 'description': body}) as Map;
    return ForgeItem(i['iid'] as int, i['title'] as String, i['web_url'] as String);
  }
}
