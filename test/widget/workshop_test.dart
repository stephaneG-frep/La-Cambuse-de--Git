import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/core/db/database.dart';
import 'package:la_cambuse/features/ai/data/secret_store.dart';
import 'package:la_cambuse/features/companion_link/data/companion_client.dart';
import 'package:la_cambuse/features/companion_link/presentation/companion_screen.dart';

import '../helpers.dart';
import 'companion_screen_test.dart' show tapPump;
import 'widget_helpers.dart';

const proj = '/home/moi/Projets/vitrine';

/// Client scripté : sorties Git réalistes ; la vraie exécution est couverte
/// par les tests du compagnon et le test de contrat.
class WorkshopClient extends CompanionClient {
  WorkshopClient(AppDatabase db, {this.paired = true}) : super(db: db, secrets: MemorySecretStore());

  final bool paired;
  final requests = <OpRequest>[];
  final approved = <String>[];
  final rejected = <String>[];
  var statusOut = '## main\n M lib/main.dart\n?? notes.txt\n';

  @override
  Future<CompanionLink?> link() async =>
      paired ? const CompanionLink(baseUrl: 'http://127.0.0.1:47820', deviceId: 'd', scopes: {Scope.read, Scope.gitWrite}) : null;

  OpStatus _st(OpRequest r, OpState s, {String stdout = '', Map<String, dynamic>? result, String? error}) => OpStatus(
        id: '${requests.length}-${r.type}',
        type: r.type,
        state: s,
        stdout: stdout,
        result: result,
        error: error,
        plan: [
          'Dossier : ${r.root}',
          'Commande exacte : git ${r.type.split('.').last} ${(r.params['paths'] as List?)?.join(' ') ?? ''}',
          if (r.type == 'git.restore' && r.params['staged'] != true) 'Sauvegarde automatique de ces fichiers avant écrasement (restaurable).',
        ],
      );

  final _byId = <String, OpStatus>{};

  @override
  Future<OpStatus> submit(OpRequest req) async {
    requests.add(req);
    final type = OpType.fromCode(req.type)!;
    final st = _st(req, type.mutating ? OpState.awaitingApproval : OpState.succeeded,
        stdout: switch (req.type) {
          'git.status' => statusOut,
          'git.diff' => req.params['staged'] == true
              ? ''
              : 'diff --git a/lib/main.dart b/lib/main.dart\n--- a/lib/main.dart\n+++ b/lib/main.dart\n@@ -1,1 +1,1 @@\n-void main() {}\n+void main() { runApp(); }\n',
          'git.branches' => '*|main|abc1234|Premier commit\n |fonction/menu|def5678|Ajoute le menu\n',
          'git.log' => 'abc1234 (HEAD -> main) Premier commit\n',
          _ => '',
        },
        result: switch (req.type) {
          'system.info' => {'roots': ['/home/moi/Projets']},
          'project.list' => {'projects': [{'name': 'vitrine', 'path': proj, 'git': true}]},
          'project.audit' => {
              'kinds': ['flutter'],
              'platforms': ['android'],
              'git': true,
              'gitInfo': {'branch': 'main', 'commits': 1, 'changes': 2, 'remotes': []},
              'findings': [
                {'severity': 'blocking', 'code': 'secret_file', 'message': 'fichier .env non ignoré : il serait publié avec le dépôt.', 'file': '.env'},
                {'severity': 'info', 'code': 'no_license', 'message': 'Aucune licence.'},
              ],
              'gitignoreMissing': ['.env', 'build/'],
              'stats': {'files': 12, 'bytes': 40960, 'truncated': false, 'skipped': ['build']},
              'blocking': 1,
            },
          'backup.list' => {'backups': [
              {'id': 'b1', 'kind': 'files', 'createdAt': '2026-11-13T10:00:00', 'reason': 'Avant git restore', 'files': ['lib/main.dart'], 'project': proj},
            ]},
          _ => null,
        });
    _byId[st.id] = st;
    return st;
  }

  @override
  Future<OpStatus> approve(String id) async {
    approved.add(id);
    final s = _byId[id]!;
    _byId[id] = OpStatus(id: id, type: s.type, state: OpState.succeeded, plan: s.plan,
        result: s.type == 'backup.restore' ? {'restoredTo': '/home/moi/Projets/vitrine-restauration-20261113'} : null);
    if (s.type == 'git.add') statusOut = '## main\nM  lib/main.dart\n?? notes.txt\n';
    if (s.type == 'git.commit') statusOut = '## main\n?? notes.txt\n';
    return _byId[id]!;
  }

  @override
  Future<OpStatus> reject(String id) async {
    rejected.add(id);
    return _byId[id]!;
  }

  @override
  Future<OpStatus> waitFor(String id, {Duration max = const Duration(seconds: 60)}) async => _byId[id]!;
}

Future<WorkshopClient> openWorkshop(WidgetTester tester, {bool paired = true, Size size = desktop}) async {
  final db = memoryDb();
  final c = WorkshopClient(db, paired: paired);
  await pumpApp(tester, size: size, db: db, overrides: [companionClientProvider.overrideWithValue(c)]);
  await tester.tap(find.text('Atelier').last);
  await tester.pumpAndSettle();
  return c;
}

Future<void> openProject(WidgetTester tester) async {
  await tapPump(tester, find.text('vitrine'));
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(Tab, label));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('sans compagnon : explication et accès à la configuration', (tester) async {
    final c = await openWorkshop(tester, paired: false);
    expect(find.textContaining('passe par le compagnon Linux'), findsOneWidget);
    expect(find.text('Configurer le compagnon'), findsOneWidget);
    expect(c.requests, isEmpty);
    await teardown(tester, c.db);
  });

  testWidgets('audit : constats triés, plan, .gitignore complété après approbation', (tester) async {
    final c = await openWorkshop(tester);
    await openProject(tester);
    await tapPump(tester, find.text('Lancer l\'audit (lecture seule)'));
    expect(find.text('fichier .env non ignoré : il serait publié avec le dépôt.'), findsOneWidget);
    expect(find.textContaining('12 fichiers analysés'), findsOneWidget);
    expect(find.textContaining('Corrigez d\'abord les 1 problème(s) bloquant(s)'), findsOneWidget);
    expect(find.text('2. Initialiser Git (branche main)'), findsOneWidget);
    await tapPump(tester, find.widgetWithText(FilledButton, 'Exécuter').at(1));
    expect(find.text('Autoriser cette opération ?'), findsOneWidget);
    await tapPump(tester, find.text('Autoriser'));
    final gi = c.requests.firstWhere((r) => r.type == 'gitignore.update');
    expect(gi.params['lines'], ['.env', 'build/']);
    expect(c.approved.single, endsWith('gitignore.update'));
    await teardown(tester, c.db);
  });

  testWidgets('changements : diff, indexation et commit après approbation', (tester) async {
    final c = await openWorkshop(tester);
    await openProject(tester);
    await tab(tester, 'Changements');
    expect(find.text('lib/main.dart'), findsOneWidget);
    expect(find.text('notes.txt'), findsOneWidget);
    await tapPump(tester, find.byTooltip('Diff').first);
    expect(find.textContaining('+ void main() { runApp(); }'), findsOneWidget);
    expect(find.textContaining('− void main() {}'), findsOneWidget);
    await tapPump(tester, find.text('lib/main.dart'));
    await tapPump(tester, find.text('Indexer'));
    await tapPump(tester, find.text('Autoriser'));
    expect(c.requests.firstWhere((r) => r.type == 'git.add').params['paths'], ['lib/main.dart']);
    await tester.enterText(find.widgetWithText(TextField, 'Message de commit (impératif, ex. « Ajoute l\'écran d\'accueil »)'), 'Lance l\'application');
    await tester.pump();
    await tapPump(tester, find.text('Valider (commit)'));
    await tapPump(tester, find.text('Autoriser'));
    expect(c.requests.firstWhere((r) => r.type == 'git.commit').params['message'], 'Lance l\'application');
    expect(find.text('lib/main.dart'), findsNothing, reason: 'liste rafraîchie après le commit');
    await teardown(tester, c.db);
  });

  testWidgets('annuler des modifications : panneau annonçant la sauvegarde, refus respecté', (tester) async {
    final c = await openWorkshop(tester);
    await openProject(tester);
    await tab(tester, 'Changements');
    await tapPump(tester, find.text('lib/main.dart'));
    await tapPump(tester, find.text('Annuler les modifications'));
    expect(find.textContaining('Sauvegarde automatique'), findsWidgets);
    await tapPump(tester, find.text('Refuser'));
    expect(c.rejected.single, endsWith('git.restore'));
    expect(c.approved, isEmpty);
    expect(find.text('Opération refusée : rien n\'a été modifié.'), findsOneWidget);
    await teardown(tester, c.db);
  });

  testWidgets('historique et sauvegardes : branches, bascule, restauration dans un nouveau dossier', (tester) async {
    final c = await openWorkshop(tester);
    await openProject(tester);
    await tab(tester, 'Historique');
    expect(find.text('fonction/menu'), findsOneWidget);
    expect(find.text('Premier commit'), findsOneWidget);
    await tapPump(tester, find.text('Basculer'));
    await tapPump(tester, find.text('Autoriser'));
    expect(c.requests.firstWhere((r) => r.type == 'git.switch').params['name'], 'fonction/menu');
    await tab(tester, 'Sauvegardes');
    expect(find.text('lib/main.dart'), findsOneWidget);
    await tapPump(tester, find.text('Restaurer dans un nouveau dossier'));
    await tapPump(tester, find.text('Autoriser'));
    expect(find.textContaining('Restauré dans : /home/moi/Projets/vitrine-restauration-20261113'), findsOneWidget);
    final log = await dbRead(tester, () => c.db.select(c.db.auditEntries).get());
    expect(log.where((e) => e.category == 'atelier').map((e) => e.action), containsAll(['Opération autorisée', 'Opération backup.restore']));
    await teardown(tester, c.db);
  });

  testWidgets('accessibilité de la fiche projet (téléphone)', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await openWorkshop(tester, size: phone);
    await openProject(tester);
    await tapPump(tester, find.text('Lancer l\'audit (lecture seule)'));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await tab(tester, 'Changements');
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
    await teardown(tester, c.db);
  });
}
