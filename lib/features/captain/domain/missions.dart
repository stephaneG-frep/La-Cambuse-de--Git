/// Missions prêtes à l'emploi et résolution des paramètres calculés. Aucune
/// IA n'est nécessaire : le Capitaine fonctionne hors fournisseur.
library;

import 'package:cambuse_protocol/cambuse_protocol.dart';

import '../../forge/data/forge_client.dart';
import '../../workshop/domain/git_parsing.dart';
import 'mission.dart';

/// Résultats des étapes déjà exécutées, indexés par opération (le dernier gagne).
class MissionContext {
  final _byOp = <String, OpStatus>{};

  void record(OpStatus st) => _byOp[st.type] = st;
  OpStatus? status(OpType t) => _byOp[t.code];
  Map<String, dynamic>? result(OpType t) => _byOp[t.code]?.result;

  Map<String, dynamic> toJson() => {for (final e in _byOp.entries) e.key: _statusJson(e.value)};

  static MissionContext fromJson(Map<String, dynamic>? j) {
    final c = MissionContext();
    j?.forEach((k, v) => c.record(OpStatus.fromJson((v as Map).cast<String, dynamic>())));
    return c;
  }

  static Map<String, dynamic> _statusJson(OpStatus s) => {
        'id': s.id,
        'type': s.type,
        'state': s.state.code,
        'plan': s.plan,
        'exitCode': ?s.exitCode,
        // Sorties tronquées : le contexte sert aux résolveurs, pas d'archive.
        'stdout': s.stdout.length > 20000 ? s.stdout.substring(0, 20000) : s.stdout,
        'result': ?s.result,
      };
}

/// Donnée manquante pour résoudre un paramètre ou une condition.
class ResolutionError implements Exception {
  const ResolutionError(this.message);
  final String message;
  @override
  String toString() => message;
}

List<String> _statusFiles(MissionContext c) {
  final st = c.status(OpType.gitStatus);
  if (st == null) throw const ResolutionError('« git status » doit être exécuté avant cette étape.');
  return [
    for (final ch in parsePorcelain(st.stdout).changes)
      if (!ch.conflicted && ch.worktree != 'D' && (ch.untracked || ch.unstaged)) ch.path,
  ].take(500).toList();
}

Map<String, dynamic> _need(MissionContext c, OpType t, String what) =>
    c.result(t) ?? (throw ResolutionError('« ${t.code} » doit être exécuté avant $what.'));

String? _ciKind(MissionContext c) {
  final kinds = ((_need(c, OpType.projectDetect, 'le choix du modèle de CI')['kinds'] as List?) ?? const []).cast<String>();
  for (final k in ['flutter', 'node', 'python']) {
    if (kinds.contains(k)) return k;
  }
  return null;
}

/// Valeur d'un résolveur (hors secrets, résolus par le moteur).
Object resolveValue(String key, MissionContext c) {
  switch (key) {
    case 'audit.gitignoreMissing':
      return ((_need(c, OpType.projectAudit, 'la mise à jour du .gitignore')['gitignoreMissing'] as List?) ?? const [])
          .cast<String>();
    case 'status.files':
      return _statusFiles(c);
    case 'status.branch':
      final st = c.status(OpType.gitStatus) ?? (throw const ResolutionError('« git status » doit être exécuté avant.'));
      return parsePorcelain(st.stdout).branch ?? (throw const ResolutionError('Branche courante introuvable (HEAD détachée ?).'));
    case 'detect.ciKind':
      return _ciKind(c) ?? (throw const ResolutionError('Aucun modèle de CI pour ce type de projet (flutter, node ou python).'));
  }
  throw ResolutionError('Résolveur inconnu : $key');
}

/// Forge du dépôt distant (pour lire le bon jeton dans le coffre).
ForgeKind forgeKindFor(MissionContext c) {
  final url = c.result(OpType.gitOutgoing)?['remoteUrl'] as String?;
  final ref = url == null ? null : RemoteRef.parse(url);
  if (ref == null) throw const ResolutionError('Dépôt distant HTTPS GitHub/GitLab introuvable (« git.outgoing » requis).');
  return ref.kind;
}

/// Évalue une condition. Lève [ResolutionError] si la donnée manque.
bool evalCondition(String key, MissionContext c) {
  switch (key) {
    case 'isRepo':
    case 'notRepo':
      final git = c.result(OpType.projectDetect)?['git'] as bool? ??
          (c.status(OpType.gitStatus)?.state == OpState.succeeded ? true : null) ??
          (throw const ResolutionError('Détection du projet requise pour savoir s\'il s\'agit d\'un dépôt Git.'));
      return key == 'isRepo' ? git : !git;
    case 'isFlutter':
      return ((_need(c, OpType.projectDetect, 'cette vérification')['kinds'] as List?) ?? const []).contains('flutter');
    case 'ciSupported':
      return _ciKind(c) != null;
    case 'hasGitignoreMissing':
      return (resolveValue('audit.gitignoreMissing', c) as List).isNotEmpty;
    case 'hasChanges':
      return _statusFiles(c).isNotEmpty;
    case 'hasOutgoing':
      return ((_need(c, OpType.gitOutgoing, 'cette vérification')['commits'] as List?) ?? const []).isNotEmpty;
    case 'noOutgoingSecrets':
      return ((_need(c, OpType.gitOutgoing, 'cette vérification')['secrets'] as List?) ?? const []).isEmpty;
  }
  throw ResolutionError('Condition inconnue : $key');
}

/// Explication lisible d'une condition (journal, rapport).
String conditionLabel(String key) => switch (key) {
      'isRepo' => 'le projet est un dépôt Git',
      'notRepo' => 'le projet n\'est pas encore un dépôt Git',
      'isFlutter' => 'le projet est une application Flutter',
      'ciSupported' => 'un modèle de CI existe pour ce type de projet',
      'hasGitignoreMissing' => 'des lignes recommandées manquent au .gitignore',
      'hasChanges' => 'des fichiers sont à ajouter',
      'hasOutgoing' => 'des commits sont à publier',
      'noOutgoingSecrets' => 'aucun secret dans ce qui serait publié',
      _ => key,
    };

/// Modèle de mission proposé à l'utilisateur.
class MissionTemplate {
  const MissionTemplate({required this.id, required this.title, required this.summary, required this.build, this.providerChoice = false});
  final String id;
  final String title;
  final String summary;

  /// La mission demande de choisir GitHub ou GitLab.
  final bool providerChoice;
  final MissionPlan Function({String provider}) build;
}

MissionPlan _depotLocal({String provider = 'github'}) => withCheckpoint(const MissionPlan(
      missionId: 'depot-local',
      title: 'Mettre le projet sous Git',
      summary: 'Audit, .gitignore complété, dépôt initialisé si besoin, puis premier commit des fichiers sûrs.',
      steps: [
        StepSpec(id: 'detection', title: 'Détecter le projet', op: 'project.detect',
            why: 'Identifier les langages, les plateformes et savoir si le dossier est déjà un dépôt Git.'),
        StepSpec(id: 'audit', title: 'Auditer le projet (lecture seule)', op: 'project.audit',
            why: 'Repérer secrets, gros fichiers et lignes manquantes du .gitignore avant tout commit.'),
        StepSpec(id: 'gitignore', title: 'Compléter le .gitignore', op: 'gitignore.update', bind: {'lines': 'audit.gitignoreMissing'},
            when: 'hasGitignoreMissing', why: 'Empêcher que build/, .env ou les fichiers d\'IDE n\'entrent dans l\'historique.'),
        StepSpec(id: 'init', title: 'Initialiser le dépôt Git', op: 'git.init', params: {'initialBranch': 'main'}, when: 'notRepo',
            why: 'Créer le dépôt local (dossier .git) avec la branche main.'),
        StepSpec(id: 'etat', title: 'Lire l\'état Git', op: 'git.status', why: 'Lister précisément les fichiers à ajouter.'),
        StepSpec(id: 'ajout', title: 'Ajouter les fichiers un par un', op: 'git.add', bind: {'paths': 'status.files'}, when: 'hasChanges',
            review: true, why: 'Chaque fichier est listé explicitement ; le compagnon bloque l\'ajout si un secret est détecté.'),
        StepSpec(id: 'commit', title: 'Créer le premier commit', op: 'git.commit', when: 'hasChanges',
            params: {'message': 'chore: état du projet suivi par Git (mission du Capitaine)'},
            why: 'Enregistrer cet état dans l\'historique ; le contenu indexé est de nouveau analysé.'),
      ],
    ));

MissionPlan _qualiteFlutter({String provider = 'github'}) => const MissionPlan(
      missionId: 'qualite-flutter',
      title: 'Contrôle qualité Flutter',
      summary: 'Analyse statique, tests, APK de test (debug) puis inventaire des artefacts. Arrêt au premier échec.',
      steps: [
        StepSpec(id: 'detection', title: 'Vérifier qu\'il s\'agit d\'un projet Flutter', op: 'project.detect', requires: ['isFlutter'],
            why: 'Les étapes suivantes n\'ont de sens que pour une application Flutter.'),
        StepSpec(id: 'analyse', title: 'flutter analyze', op: 'flutter.analyze', why: 'Détecter erreurs et mauvaises pratiques sans exécuter l\'application.'),
        StepSpec(id: 'tests', title: 'flutter test', op: 'flutter.test', why: 'Vérifier que le comportement attendu est toujours respecté.'),
        StepSpec(id: 'apk', title: 'APK de test (debug)', op: 'flutter.build.apk.debug',
            why: 'Produire un APK pour essayer sur un appareil. Il est signé avec la clé debug : jamais distribuable.'),
        StepSpec(id: 'cale', title: 'Inspecter la cale des artefacts', op: 'artifacts.list',
            why: 'Vérifier taille, empreinte SHA-256 et signature réelle de ce qui a été produit.'),
      ],
    );

MissionPlan _ci({String provider = 'github'}) => withCheckpoint(MissionPlan(
      missionId: 'ci-$provider',
      title: 'Mettre en place l\'intégration continue (${provider == 'github' ? 'GitHub Actions' : 'GitLab CI'})',
      summary: 'Pipeline sûr généré (actions épinglées, permissions minimales, analyse des secrets), relu puis commité.',
      steps: [
        const StepSpec(id: 'detection', title: 'Détecter le projet', op: 'project.detect', requires: ['isRepo', 'ciSupported'],
            why: 'Choisir le modèle de pipeline adapté et vérifier que le projet est un dépôt Git.'),
        StepSpec(id: 'pipeline', title: 'Générer ${ciFileName(provider)}', op: 'ci.scaffold', params: {'provider': provider},
            bind: const {'kind': 'detect.ciKind'}, why: 'Écrire le pipeline sans jamais écraser un fichier existant.'),
        const StepSpec(id: 'etat', title: 'Lire l\'état Git', op: 'git.status', why: 'Vérifier ce qui a été créé.'),
        StepSpec(id: 'ajout', title: 'Ajouter le pipeline', op: 'git.add', params: {'paths': [ciFileName(provider)]}, review: true,
            why: 'Seul le fichier de pipeline est ajouté.'),
        const StepSpec(id: 'commit', title: 'Commiter le pipeline', op: 'git.commit',
            params: {'message': 'ci: ajoute le pipeline d\'intégration continue (mission du Capitaine)'},
            why: 'Le pipeline s\'exécutera au prochain push.'),
      ],
    ));

MissionPlan _publication({String provider = 'github'}) => const MissionPlan(
      missionId: 'publication',
      title: 'Publier la branche courante',
      summary: 'Vérifier ce qui partirait (commits, fichiers, secrets) puis pousser sans force, avec un consentement spécifique.',
      steps: [
        StepSpec(id: 'etat', title: 'Lire l\'état Git', op: 'git.status', requires: ['isRepo'], why: 'Connaître la branche courante.'),
        StepSpec(id: 'sortant', title: 'Analyser ce qui serait publié', op: 'git.outgoing', params: {'remote': 'origin'},
            bind: {'branch': 'status.branch'}, requires: ['hasOutgoing', 'noOutgoingSecrets'],
            why: 'Lister commits et fichiers qui partiraient ; la mission s\'arrête si un secret s\'y trouve.'),
        StepSpec(id: 'push', title: 'Pousser vers origin (sans force)', op: 'git.push', params: {'remote': 'origin'},
            bind: {'branch': 'status.branch', 'token': 'forge.token'}, review: true,
            why: 'Publier les commits. Action externe : elle ne peut pas être annulée automatiquement.'),
      ],
    );

final missionTemplates = <MissionTemplate>[
  MissionTemplate(id: 'depot-local', title: 'Mettre le projet sous Git', build: _depotLocal,
      summary: 'Audit, .gitignore, initialisation et premier commit, avec point de contrôle.'),
  MissionTemplate(id: 'qualite-flutter', title: 'Contrôle qualité Flutter', build: _qualiteFlutter,
      summary: 'analyze, test, APK de test et cale des artefacts.'),
  MissionTemplate(id: 'ci', title: 'Mettre en place la CI', build: _ci, providerChoice: true,
      summary: 'Pipeline sûr généré, relu et commité.'),
  MissionTemplate(id: 'publication', title: 'Publier la branche courante', build: _publication,
      summary: 'Vérification de ce qui part, puis push sans force (consentement spécifique).'),
];
