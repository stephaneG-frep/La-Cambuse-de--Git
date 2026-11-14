/// Plan de mission proposé par le professeur IA. La réponse du modèle est
/// NON FIABLE : JSON strict, schéma validé, opérations autorisées seulement,
/// aucun secret, point de contrôle inséré d'office. Rien ne s'exécute sans
/// l'approbation de l'utilisateur.
library;

import 'dart:convert';

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'mission.dart';

const _opHelp = <String, String>{
  'project.detect': 'détecter langages, plateformes, dépôt Git (lecture)',
  'project.audit': 'audit sécurité et hygiène, lignes manquantes du .gitignore (lecture)',
  'git.status': 'état Git (lecture)',
  'git.log': 'historique, params {limit: entier}',
  'git.diff': 'différences, params {staged: booléen, path: chemin}',
  'git.branches': 'branches (lecture)',
  'git.remote.list': 'dépôts distants (lecture)',
  'git.outgoing': 'ce que contiendrait un push, params {remote, branch}',
  'docker.lint': 'analyse des Dockerfile et compose (lecture)',
  'artifacts.list': 'artefacts produits, signature, SHA-256 (lecture)',
  'project.backup': 'point de contrôle (sauvegarde)',
  'git.init': 'créer le dépôt, params {initialBranch}',
  'git.add': 'ajouter des fichiers explicites, params {paths: [chemins]}',
  'git.commit': 'commit, params {message}',
  'git.branch.create': 'créer une branche, params {name}',
  'git.switch': 'changer de branche, params {name}',
  'gitignore.update': 'ajouter des lignes au .gitignore, params {lines: [lignes]}',
  'docker.scaffold': 'générer un Dockerfile sans écraser, params {template: node|python|dart|go}',
  'ci.scaffold': 'générer la CI sans écraser, params {kind: flutter|node|python, provider: github|gitlab}',
  'flutter.analyze': 'flutter analyze',
  'flutter.test': 'flutter test',
  'flutter.build.apk.debug': 'APK de test (debug)',
  'flutter.build.linux': 'build Linux release',
  'git.push': 'publier sans force (action externe), params {remote, branch} ; le jeton est ajouté par l\'application',
};

/// Consigne système du planificateur.
String captainPlannerPrompt() => '''
Tu es le planificateur du « Capitaine automatique » de La Cambuse de Git. Tu proposes un plan ; un humain le relit et approuve chaque modification. Tu n'exécutes rien.

Règles impératives :
- Réponds UNIQUEMENT par un objet JSON, sans texte autour.
- N'utilise QUE ces opérations (champ "op") :
${_opHelp.entries.map((e) => '  - ${e.key} : ${e.value}').join('\n')}
- Jamais de commande shell, jamais de secret ni de jeton, jamais de chemin absolu ni de « .. ».
- Paramètres calculés possibles (champ "bind", nom → résolveur) : ${captainResolvers.keys.where((k) => k != 'forge.token').join(', ')}, et forge.token uniquement pour le paramètre token de git.push.
- Conditions possibles ("when" : étape ignorée si fausse ; "requires" : mission arrêtée si fausse après l'étape) : ${captainConditions.join(', ')}.
- "review": true demande une relecture humaine avant l'étape (à utiliser avant git.add, git.commit et git.push).
- 12 étapes au maximum, 6 modifications au maximum. Commence par une étape de lecture (project.detect ou git.status).

Format :
{"title": "…", "summary": "…", "steps": [{"id": "minuscules-et-tirets", "title": "…", "why": "explication pédagogique", "op": "…", "params": {}, "bind": {}, "when": null, "requires": [], "review": false}]}
''';

/// Résultat d'analyse d'une proposition IA.
class AiPlanResult {
  const AiPlanResult({this.plan, this.errors = const []});
  final MissionPlan? plan;
  final List<String> errors;
  bool get ok => plan != null && errors.isEmpty;
}

/// Extrait et valide le plan JSON d'une réponse du modèle.
AiPlanResult parseAiPlan(String text) {
  var raw = text.trim();
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
  if (fence != null) raw = fence.group(1)!.trim();
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return const AiPlanResult(errors: ['La réponse ne contient pas d\'objet JSON.']);
  final Object? decoded;
  try {
    decoded = jsonDecode(raw.substring(start, end + 1));
  } on FormatException catch (e) {
    return AiPlanResult(errors: ['JSON invalide : ${e.message}']);
  }
  if (decoded is! Map || decoded['steps'] is! List) {
    return const AiPlanResult(errors: ['Structure inattendue : champ « steps » absent.']);
  }
  final errors = <String>[];
  const allowedStepKeys = {'id', 'title', 'why', 'op', 'params', 'bind', 'when', 'requires', 'review'};
  final steps = <StepSpec>[];
  for (final (i, s) in (decoded['steps'] as List).indexed) {
    if (s is! Map) {
      errors.add('Étape ${i + 1} : objet attendu.');
      continue;
    }
    final extra = s.keys.map((k) => '$k').where((k) => !allowedStepKeys.contains(k)).toList();
    if (extra.isNotEmpty) errors.add('Étape ${i + 1} : champs inconnus ${extra.join(', ')}.');
    if (s['params'] != null && s['params'] is! Map || s['bind'] != null && s['bind'] is! Map || s['requires'] != null && s['requires'] is! List) {
      errors.add('Étape ${i + 1} : params, bind ou requires mal formés.');
      continue;
    }
    // forge.token n'est accepté que pour le jeton de git.push.
    final bind = (s['bind'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const <String, String>{};
    if (bind.entries.any((e) => e.value == 'forge.token' && !(s['op'] == OpType.gitPush.code && e.key == 'token'))) {
      errors.add('Étape ${i + 1} : forge.token n\'est utilisable que pour le jeton de git.push.');
    }
    steps.add(StepSpec.fromJson(Map<String, dynamic>.from(s.map((k, v) => MapEntry('$k', v)))
      ..removeWhere((k, v) => k == 'when' && v == null)));
  }
  final plan = withCheckpoint(MissionPlan(
    missionId: 'ia',
    title: '${decoded['title'] ?? 'Mission proposée'}'.trim(),
    summary: '${decoded['summary'] ?? ''}'.trim(),
    steps: steps,
    source: PlanSource.ia,
    limits: const ExecutionLimits(maxSteps: 13, maxMutations: 6),
  ));
  errors.addAll(validatePlan(plan));
  if (plan.title.isEmpty || plan.title.length > 120) errors.add('Titre de mission vide ou trop long.');
  return AiPlanResult(plan: plan, errors: errors);
}

/// Demande de l'utilisateur, accompagnée d'un résumé factuel du projet.
String plannerRequest(String goal, Map<String, dynamic>? detected) => '''
Objectif de l'utilisateur : ${goal.trim()}

Projet détecté : ${detected == null ? 'inconnu (commence par project.detect)' : jsonEncode({
          'kinds': detected['kinds'],
          'git': detected['git'],
          'platforms': detected['platforms'],
          'ci': detected['ci'],
          'gitignore': detected['gitignore'],
        })}
''';
