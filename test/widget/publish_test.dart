import 'dart:convert';

import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';
import 'package:la_cambuse/features/forge/data/forge_client.dart';
import 'package:la_cambuse/features/forge/presentation/forge_providers.dart';

import '../helpers.dart';
import 'companion_screen_test.dart' show tapPump;
import 'widget_helpers.dart';
import 'workshop_test.dart' show WorkshopClient, openProject, tab;

const token = 'github_pat_WIDGETTEST00000000000000000';

class PublishClient extends WorkshopClient {
  PublishClient(super.db, {this.hasRemote = true, this.secret = false});
  bool hasRemote;
  final bool secret;
  final submittedParams = <String, Map<String, dynamic>>{};
  final _mine = <String, OpStatus>{};

  @override
  Future<OpStatus> submit(OpRequest req) async {
    if (!['git.remote.list', 'git.outgoing', 'git.push', 'git.remote.add', 'git.status'].contains(req.type)) return super.submit(req);
    requests.add(req);
    submittedParams[req.type] = req.params;
    final mutating = OpType.fromCode(req.type)!.mutating;
    final st = OpStatus(
      id: 'p${requests.length}-${req.type}',
      type: req.type,
      state: mutating ? OpState.awaitingApproval : OpState.succeeded,
      plan: [
        'Commande exacte : git ${req.type == 'git.push' ? 'push --porcelain origin refs/heads/fonction:refs/heads/fonction' : 'remote add origin ${req.params['url']}'}',
        'Jamais de --force : l\'historique distant n\'est pas réécrit.',
      ],
      stdout: switch (req.type) {
        'git.remote.list' => hasRemote ? 'origin\thttps://github.com/moi/depot.git (fetch)\norigin\thttps://github.com/moi/depot.git (push)\n' : '',
        'git.status' => '## fonction\n',
        _ => '',
      },
      result: req.type == 'git.outgoing'
          ? {
              'remoteBranchExists': false,
              'commits': [{'sha': 'abc1234', 'subject': 'Ajoute le menu'}],
              'files': ['lib/menu.dart'],
              'secrets': secret ? [{'file': 'lib/cle.dart', 'line': 1, 'kind': 'jeton GitHub'}] : [],
              'largeFiles': [],
            }
          : null,
    );
    _mine[st.id] = st;
    return st;
  }

  @override
  Future<OpStatus> approve(String id) async {
    if (!_mine.containsKey(id)) return super.approve(id);
    approved.add(id);
    final s = _mine[id]!;
    if (s.type == 'git.remote.add') hasRemote = true;
    return _mine[id] = OpStatus(id: id, type: s.type, state: OpState.succeeded, plan: s.plan,
        result: s.type == 'git.push' ? {'pushedCommits': 1} : null);
  }

  @override
  Future<OpStatus> reject(String id) async {
    if (!_mine.containsKey(id)) return super.reject(id);
    rejected.add(id);
    return _mine[id]!;
  }

  @override
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async => _mine[id] ?? super.waitFor(id);
}

/// Forge GitHub simulée au niveau HTTP.
GitHubForge fakeGitHub(List<http.Request> seen, {bool private = true}) => GitHubForge(
      token: () async => token,
      client: MockClient((r) async {
        seen.add(r);
        final key = '${r.method} ${r.url.path}';
        if (key == 'GET /repos/moi/depot') {
          return http.Response(jsonEncode({'full_name': 'moi/depot', 'private': private, 'default_branch': 'main',
              'html_url': 'https://github.com/moi/depot', 'clone_url': 'https://github.com/moi/depot.git'}), 200);
        }
        if (key.endsWith('/pulls') && r.method == 'GET') return http.Response('[]', 200);
        if (key.endsWith('/issues') && r.method == 'GET') return http.Response('[]', 200);
        if (key == 'POST /repos/moi/depot/pulls') {
          return http.Response(jsonEncode({'number': 7, 'title': 'Menu', 'html_url': 'https://github.com/moi/depot/pull/7'}), 201);
        }
        return http.Response('{"message":"Not Found"}', 404);
      }),
    );

Future<PublishClient> openPublish(WidgetTester tester, {bool hasRemote = true, bool secret = false, bool private = true, List<http.Request>? seen}) async {
  final db = memoryDb();
  final c = PublishClient(db, hasRemote: hasRemote, secret: secret);
  final secrets = MemorySecretStore()..values[forgeTokenKey(ForgeKind.github)] = token;
  final requests = seen ?? <http.Request>[];
  await pumpApp(tester, size: desktop, db: db, secrets: secrets, overrides: [
    companionClientProvider.overrideWithValue(c),
    forgeFactoryProvider.overrideWithValue((ForgeKind k, {String? host}) => fakeGitHub(requests, private: private)),
  ]);
  await tester.tap(find.text('Atelier').last);
  await tester.pumpAndSettle();
  await openProject(tester);
  await tab(tester, 'Publication');
  return c;
}

void main() {
  testWidgets('sans remote : association à https://github.com/moi/depot.git après approbation', (tester) async {
    final c = await openPublish(tester, hasRemote: false);
    expect(find.text('Ce projet n\'a pas encore de dépôt distant.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Dépôt distant (propriétaire/nom)'), 'moi/depot');
    await tester.pump();
    await tapPump(tester, find.text('Associer comme origin'));
    expect(find.text('Autoriser cette opération ?'), findsOneWidget);
    await tapPump(tester, find.text('Autoriser'));
    expect(c.submittedParams['git.remote.add'], {'name': 'origin', 'url': 'https://github.com/moi/depot.git'});
    await teardown(tester, c.db);
  });

  testWidgets('publication : panneau complet, jeton transmis au compagnon mais jamais journalisé', (tester) async {
    final seen = <http.Request>[];
    final c = await openPublish(tester, seen: seen);
    expect(find.text('PRIVÉ'), findsOneWidget);
    await tapPump(tester, find.text('Publier (push)'));
    expect(find.text('Publier sur moi/depot ?'), findsOneWidget);
    expect(find.textContaining('abc1234  Ajoute le menu'), findsOneWidget);
    expect(find.textContaining('aucun secret détecté'), findsOneWidget);
    expect(find.textContaining('elle sera créée'), findsOneWidget);
    await tapPump(tester, find.text('Publier'));
    expect(c.submittedParams['git.push']!['token'], token);
    expect(c.approved.last, endsWith('git.push'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Publié : 1 commit(s) envoyé(s).'), findsWidgets, reason: 'notification et message en ligne');
    final log = await dbRead(tester, () => c.db.select(c.db.auditEntries).get());
    expect(log.map((e) => '${e.action} ${e.details}').join(), isNot(contains('WIDGETTEST')));
    expect(seen.every((r) => !r.url.toString().contains(token)), isTrue);
    await teardown(tester, c.db);
  });

  testWidgets('secret dans l\'historique : pas de bouton Publier, opération rejetée', (tester) async {
    final c = await openPublish(tester, secret: true);
    await tapPump(tester, find.text('Publier (push)'));
    expect(find.textContaining('publication bloquée'), findsOneWidget);
    expect(find.textContaining('lib/cle.dart:1 — jeton GitHub'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Publier'), findsNothing);
    await tapPump(tester, find.text('Annuler'));
    expect(c.rejected.last, endsWith('git.push'));
    expect(c.approved.where((a) => a.endsWith('git.push')), isEmpty);
    await teardown(tester, c.db);
  });

  testWidgets('dépôt public : avertissement dans le panneau', (tester) async {
    final c = await openPublish(tester, private: false);
    expect(find.text('PUBLIC'), findsOneWidget);
    await tapPump(tester, find.text('Publier (push)'));
    expect(find.textContaining('ce dépôt est PUBLIC'), findsOneWidget);
    await tapPump(tester, find.text('Refuser'));
    await teardown(tester, c.db);
  });

  testWidgets('demande de fusion fonction → main via l\'API', (tester) async {
    final seen = <http.Request>[];
    final c = await openPublish(tester, seen: seen);
    expect(find.text('Nouvelle demande de fusion (fonction → main)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Titre').first, 'Menu');
    await tester.pump();
    await tapPump(tester, find.text('Ouvrir'));
    final post = seen.firstWhere((r) => r.method == 'POST' && r.url.path.endsWith('/pulls'));
    expect(jsonDecode(post.body), {'head': 'fonction', 'base': 'main', 'title': 'Menu', 'body': ''});
    expect(find.textContaining('Créé : https://github.com/moi/depot/pull/7'), findsWidgets);
    expect(find.text('#7'), findsOneWidget, reason: 'ajoutée à la liste même si le listage de l\'API est en retard');
    await teardown(tester, c.db);
  });
}
