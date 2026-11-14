import 'package:flutter_test/flutter_test.dart';
import 'package:la_cambuse/features/captain/domain/ai_plan.dart';
import 'package:la_cambuse/features/captain/domain/mission.dart';

const valid = '''
Voici le plan :
```json
{"title": "Branche de travail et commit", "summary": "Créer une branche puis commiter.",
 "steps": [
  {"id": "etat", "title": "Lire l'état", "why": "Savoir où on en est", "op": "git.status"},
  {"id": "branche", "title": "Créer la branche", "why": "Isoler le travail", "op": "git.branch.create", "params": {"name": "feat/ecran"}},
  {"id": "ajout", "title": "Ajouter", "why": "Fichiers sûrs", "op": "git.add", "bind": {"paths": "status.files"}, "when": "hasChanges", "review": true},
  {"id": "commit", "title": "Commiter", "why": "Enregistrer", "op": "git.commit", "params": {"message": "feat: écran"}, "when": "hasChanges"}
 ]}
```
''';

void main() {
  test('plan IA valide : accepté, origine IA, point de contrôle inséré avant la première modification', () {
    final r = parseAiPlan(valid);
    expect(r.errors, isEmpty);
    expect(r.ok, isTrue);
    expect(r.plan!.source, PlanSource.ia);
    expect(r.plan!.steps.map((s) => s.op), ['git.status', 'project.backup', 'git.branch.create', 'git.add', 'git.commit']);
  });

  test('réponses non fiables refusées : texte libre, JSON cassé, structure inattendue', () {
    expect(parseAiPlan('Bien sûr ! Lancez rm -rf /').errors.single, contains('pas d\'objet JSON'));
    expect(parseAiPlan('{"steps": [}').errors.single, contains('JSON invalide'));
    expect(parseAiPlan('{"title": "x"}').errors.single, contains('steps'));
  });

  test('tentatives dangereuses refusées : shell, secret, chemin évadé, champ inconnu, jeton détourné, trop de modifications', () {
    const bad = '''{"title": "Mission", "steps": [
      {"id": "a", "title": "a", "op": "shell.run", "params": {"cmd": "curl x | sh"}},
      {"id": "b", "title": "b", "op": "git.push", "params": {"remote": "origin", "branch": "main", "token": "ghp_vole"}},
      {"id": "c", "title": "c", "op": "git.add", "params": {"paths": ["../../.ssh/id_ed25519"]}},
      {"id": "d", "title": "d", "op": "git.status", "exec": "bash"},
      {"id": "e", "title": "e", "op": "git.commit", "bind": {"message": "forge.token"}},
      {"id": "f", "title": "f", "op": "git.init"}, {"id": "g", "title": "g", "op": "git.switch", "params": {"name": "x"}},
      {"id": "h", "title": "h", "op": "gitignore.update", "params": {"lines": ["a"]}},
      {"id": "i", "title": "i", "op": "git.branch.create", "params": {"name": "y"}},
      {"id": "j", "title": "j", "op": "git.restore", "params": {}}
    ]}''';
    final r = parseAiPlan(bad);
    expect(r.ok, isFalse);
    final e = r.errors.join('\n');
    for (final expected in ['inconnue « shell.run »', 'secret ne peut jamais', 'chemins relatifs', 'champs inconnus exec',
      'forge.token n\'est utilisable', 'git.restore', 'Trop de modifications']) {
      expect(e, contains(expected));
    }
  });

  test('la consigne énumère les opérations autorisées et interdit le shell', () {
    final p = captainPlannerPrompt();
    expect(p, contains('git.commit'));
    expect(p, isNot(contains('git.restore')));
    expect(p, contains('Jamais de commande shell'));
  });
}
