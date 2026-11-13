import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:la_cambuse/features/forge/data/forge_client.dart';

const tok = 'github_pat_TEST000000000000000000000000';

void main() {
  late List<http.Request> seen;
  MockClient mock(http.Response Function(http.Request r) handler) => MockClient((r) async {
        seen.add(r);
        return handler(r);
      });
  setUp(() => seen = []);

  test('GitHub : en-têtes, dépôt privé, PR, tickets (PR exclues)', () async {
    final f = GitHubForge(token: () async => tok, client: mock((r) {
      switch ('${r.method} ${r.url.path}') {
        case 'GET /repos/moi/depot':
          return http.Response(jsonEncode({'full_name': 'moi/depot', 'private': true, 'default_branch': 'main',
              'html_url': 'https://github.com/moi/depot', 'clone_url': 'https://github.com/moi/depot.git'}), 200);
        case 'POST /repos/moi/depot/pulls':
          final b = jsonDecode(r.body) as Map;
          expect(b, {'head': 'fonction', 'base': 'main', 'title': 'Ajoute', 'body': ''});
          return http.Response(jsonEncode({'number': 1, 'title': 'Ajoute', 'html_url': 'https://github.com/moi/depot/pull/1'}), 201);
        case 'GET /repos/moi/depot/issues':
          return http.Response(jsonEncode([
            {'number': 2, 'title': 'Bogue', 'html_url': 'u2'},
            {'number': 1, 'title': 'PR', 'html_url': 'u1', 'pull_request': {}},
          ]), 200);
        default:
          return http.Response('{}', 404);
      }
    }));
    final repo = await f.repo('moi/depot');
    expect(repo.private, isTrue);
    expect(seen.first.headers['authorization'], 'Bearer $tok');
    expect(seen.first.headers['x-github-api-version'], '2022-11-28');
    expect(seen.first.url.toString(), isNot(contains(tok)), reason: 'jamais de jeton dans l\'URL');
    expect((await f.createChangeRequest('moi/depot', head: 'fonction', base: 'main', title: 'Ajoute')).number, 1);
    expect((await f.openIssues('moi/depot')).map((i) => i.title), ['Bogue']);
  });

  test('GitHub : création de dépôt toujours privée', () async {
    final f = GitHubForge(token: () async => tok, client: mock((r) {
      expect(jsonDecode(r.body)['private'], isTrue);
      return http.Response(jsonEncode({'full_name': 'moi/neuf', 'private': true, 'default_branch': 'main',
          'html_url': 'h', 'clone_url': 'c'}), 201);
    }));
    expect((await f.createPrivateRepo('neuf')).private, isTrue);
  });

  test('erreurs : 401, 403 droits, 403 limite, 404, 422 détaillée, sans jeton', () async {
    Future<ForgeErrorKind> kindFor(int status, {String body = '{"message":"x"}', Map<String, String> headers = const {}}) async {
      final f = GitHubForge(token: () async => tok, client: mock((_) => http.Response(body, status, headers: headers)));
      try {
        await f.repo('moi/depot');
      } on ForgeException catch (e) {
        return e.kind;
      }
      throw StateError('pas d\'erreur');
    }
    expect(await kindFor(401), ForgeErrorKind.authentication);
    expect(await kindFor(403), ForgeErrorKind.forbidden);
    expect(await kindFor(403, headers: {'x-ratelimit-remaining': '0'}), ForgeErrorKind.rateLimited);
    expect(await kindFor(404), ForgeErrorKind.notFound);
    final f = GitHubForge(token: () async => tok, client: mock((_) => http.Response(
        jsonEncode({'message': 'Validation Failed', 'errors': [{'message': 'No commits between main and main'}]}), 422)));
    await expectLater(f.createChangeRequest('moi/depot', head: 'main', base: 'main', title: 't'),
        throwsA(isA<ForgeException>().having((e) => e.message, 'm', contains('No commits between main and main'))));
    final none = GitHubForge(token: () async => null, client: mock((_) => http.Response('{}', 200)));
    await expectLater(none.repo('moi/depot'), throwsA(isA<ForgeException>().having((e) => e.kind, 'k', ForgeErrorKind.noToken)));
    expect(seen.where((r) => r.headers['authorization'] == null), isEmpty);
    await expectLater(GitHubForge(token: () async => tok, client: mock((_) => http.Response('{}', 200))).repo('pas un nom'),
        throwsA(isA<ForgeException>()));
  });

  test('message d\'erreur contenant un jeton : masqué', () async {
    final f = GitHubForge(token: () async => tok, client: mock((_) =>
        http.Response(jsonEncode({'message': 'bad credentials ghp_${'Q' * 36}'}), 401)));
    await expectLater(f.repo('moi/depot'),
        throwsA(isA<ForgeException>().having((e) => e.message, 'm', isNot(contains('Q' * 36)))));
  });

  test('GitLab : projet encodé, visibilité, MR, création privée', () async {
    final f = GitLabForge(token: () async => 'glpat-xxxxxxxxxxxxxxxxxxxx', client: mock((r) {
      if (r.method == 'GET' && r.url.path == '/api/v4/projects/groupe%2Fsous%2Fdepot') {
        return http.Response(jsonEncode({'path_with_namespace': 'groupe/sous/depot', 'visibility': 'private',
            'default_branch': 'main', 'web_url': 'w', 'http_url_to_repo': 'h'}), 200);
      }
      if (r.method == 'POST' && r.url.path.endsWith('/merge_requests')) {
        expect(jsonDecode(r.body)['source_branch'], 'fonction');
        return http.Response(jsonEncode({'iid': 3, 'title': 'MR', 'web_url': 'w3'}), 201);
      }
      if (r.method == 'POST' && r.url.path == '/api/v4/projects') {
        expect(jsonDecode(r.body)['visibility'], 'private');
        return http.Response(jsonEncode({'path_with_namespace': 'moi/neuf', 'visibility': 'private',
            'default_branch': 'main', 'web_url': 'w', 'http_url_to_repo': 'h'}), 201);
      }
      return http.Response('{}', 404);
    }));
    expect((await f.repo('groupe/sous/depot')).private, isTrue);
    expect((await f.createChangeRequest('groupe/sous/depot', head: 'fonction', base: 'main', title: 'MR')).number, 3);
    expect((await f.createPrivateRepo('neuf')).private, isTrue);
  });

  test('analyse des URL de remote', () {
    final g = RemoteRef.parse('https://github.com/moi/depot.git')!;
    expect([g.kind, g.fullName], [ForgeKind.github, 'moi/depot']);
    final l = RemoteRef.parse('https://gitlab.com/groupe/sous/depot.git')!;
    expect([l.kind, l.fullName], [ForgeKind.gitlab, 'groupe/sous/depot']);
    expect(RemoteRef.parse('https://moi:secret@github.com/moi/depot.git'), isNull);
    expect(RemoteRef.parse('git@github.com:moi/depot.git'), isNull);
    expect(RemoteRef.parse('/chemin/local'), isNull);
  });
}
