/// Modèle du Capitaine automatique : une mission est une suite d'étapes
/// typées (opérations du compagnon), jamais du shell. Fonctions pures, testées.
library;

import 'package:cambuse_protocol/cambuse_protocol.dart';

/// Niveau de risque d'une étape, affiché avec une icône ET un libellé.
enum StepRisk {
  /// Lecture seule.
  lecture('Lecture seule'),

  /// Point de contrôle (sauvegarde du projet dans le dossier privé du compagnon).
  controle('Point de contrôle'),

  /// Modifie le projet local (annulable grâce au point de contrôle).
  modification('Modifie le projet'),

  /// Exécute du code du projet sur le PC (tests, build).
  execution('Exécute du code'),

  /// Action externe (publication) : non annulable automatiquement.
  externe('Action externe');

  const StepRisk(this.label);
  final String label;

  static StepRisk of(OpType t) {
    if (t == OpType.projectBackup) return StepRisk.controle;
    if (t.scope == Scope.remote) return StepRisk.externe;
    if (t.scope == Scope.build) return StepRisk.execution;
    return t.mutating ? StepRisk.modification : StepRisk.lecture;
  }
}

/// Une étape de mission.
class StepSpec {
  const StepSpec({
    required this.id,
    required this.title,
    required this.why,
    required this.op,
    this.params = const {},
    this.bind = const {},
    this.when,
    this.requires = const [],
    this.review = false,
  });

  final String id;
  final String title;

  /// Explication pédagogique : pourquoi cette étape.
  final String why;

  /// Code d'[OpType].
  final String op;

  /// Paramètres fixes.
  final Map<String, dynamic> params;

  /// Paramètres calculés à l'exécution : nom → clé de résolveur connue.
  final Map<String, String> bind;

  /// Condition d'exécution (clé connue) : étape ignorée si elle est fausse.
  final String? when;

  /// Conditions vérifiées APRÈS l'étape : si l'une est fausse, la mission
  /// s'arrête proprement (prérequis non rempli).
  final List<String> requires;

  /// Pause de relecture humaine avant l'étape (diff et état affichés).
  final bool review;

  OpType get type => OpType.fromCode(op)!;
  StepRisk get risk => StepRisk.of(type);

  /// Une action externe exige toujours un consentement spécifique, en plus
  /// de l'approbation du compagnon.
  bool get needsSpecificConsent => risk == StepRisk.externe;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'why': why,
        'op': op,
        if (params.isNotEmpty) 'params': params,
        if (bind.isNotEmpty) 'bind': bind,
        'when': ?when,
        if (requires.isNotEmpty) 'requires': requires,
        if (review) 'review': true,
      };

  factory StepSpec.fromJson(Map<String, dynamic> j) => StepSpec(
        id: '${j['id']}',
        title: '${j['title']}',
        why: '${j['why'] ?? ''}',
        op: '${j['op']}',
        params: Map<String, dynamic>.of((j['params'] as Map?)?.cast<String, dynamic>() ?? const {}),
        bind: Map<String, String>.of((j['bind'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {}),
        when: j['when'] as String?,
        requires: ((j['requires'] as List?) ?? const []).map((e) => '$e').toList(),
        review: j['review'] == true,
      );
}

/// Limites d'exécution d'une mission.
class ExecutionLimits {
  const ExecutionLimits({
    this.maxSteps = 25,
    this.maxMutations = 12,
    this.maxDuration = const Duration(minutes: 60),
    this.opWait = const Duration(minutes: 6),
    this.buildWait = const Duration(minutes: 26),
  });

  final int maxSteps;
  final int maxMutations;
  final Duration maxDuration;

  /// Attente maximale d'une opération ordinaire / d'un build.
  final Duration opWait;
  final Duration buildWait;

  Duration waitFor(OpType t) => t.scope == Scope.build ? buildWait : opWait;

  Map<String, dynamic> toJson() => {
        'maxSteps': maxSteps,
        'maxMutations': maxMutations,
        'maxDurationMin': maxDuration.inMinutes,
        'opWaitMin': opWait.inMinutes,
        'buildWaitMin': buildWait.inMinutes,
      };

  factory ExecutionLimits.fromJson(Map<String, dynamic>? j) => j == null
      ? const ExecutionLimits()
      : ExecutionLimits(
          maxSteps: (j['maxSteps'] as int?) ?? 25,
          maxMutations: (j['maxMutations'] as int?) ?? 12,
          maxDuration: Duration(minutes: (j['maxDurationMin'] as int?) ?? 60),
          opWait: Duration(minutes: (j['opWaitMin'] as int?) ?? 6),
          buildWait: Duration(minutes: (j['buildWaitMin'] as int?) ?? 26),
        );
}

/// Origine d'un plan.
enum PlanSource { modele, ia }

class MissionPlan {
  const MissionPlan({
    required this.missionId,
    required this.title,
    required this.summary,
    required this.steps,
    this.source = PlanSource.modele,
    this.limits = const ExecutionLimits(),
  });

  final String missionId;
  final String title;
  final String summary;
  final List<StepSpec> steps;
  final PlanSource source;
  final ExecutionLimits limits;

  int get mutations => steps.where((s) => OpType.fromCode(s.op)?.mutating ?? false).length;
  Set<StepRisk> get risks => {for (final s in steps) if (OpType.fromCode(s.op) != null) s.risk};

  MissionPlan copyWith({List<StepSpec>? steps}) => MissionPlan(
      missionId: missionId, title: title, summary: summary, steps: steps ?? this.steps, source: source, limits: limits);

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'title': title,
        'summary': summary,
        'source': source.name,
        'limits': limits.toJson(),
        'steps': [for (final s in steps) s.toJson()],
      };

  factory MissionPlan.fromJson(Map<String, dynamic> j) => MissionPlan(
        missionId: '${j['missionId']}',
        title: '${j['title']}',
        summary: '${j['summary'] ?? ''}',
        source: PlanSource.values.firstWhere((s) => s.name == j['source'], orElse: () => PlanSource.modele),
        limits: ExecutionLimits.fromJson((j['limits'] as Map?)?.cast<String, dynamic>()),
        steps: [for (final s in (j['steps'] as List)) StepSpec.fromJson((s as Map).cast<String, dynamic>())],
      );
}

/// Opérations qu'un plan peut contenir. Exclues volontairement :
/// `git.restore` (jette des modifications), `backup.restore` (réservée au
/// retour arrière), `system.info` et `project.list` (hors projet),
/// `git.pull` (modifie depuis l'extérieur sans relecture).
const captainAllowedOps = <OpType>{
  OpType.projectDetect, OpType.projectAudit, OpType.gitStatus, OpType.gitLog, OpType.gitDiff, OpType.gitBranches,
  OpType.gitRemoteList, OpType.gitOutgoing, OpType.backupList, OpType.dockerLint, OpType.artifactsList,
  OpType.projectBackup, OpType.gitInit, OpType.gitAdd, OpType.gitCommit, OpType.gitBranchCreate, OpType.gitSwitch,
  OpType.gitignoreUpdate, OpType.dockerScaffold, OpType.ciScaffold, OpType.flutterAnalyze, OpType.flutterTest,
  OpType.flutterBuildApkDebug, OpType.flutterBuildLinux, OpType.gitPush,
};

/// Paramètres autorisés par opération : nom → type attendu.
const _paramSchema = <OpType, Map<String, String>>{
  OpType.gitLog: {'limit': 'int'},
  OpType.gitDiff: {'staged': 'bool', 'path': 'path'},
  OpType.gitInit: {'initialBranch': 'branch'},
  OpType.gitAdd: {'paths': 'paths'},
  OpType.gitCommit: {'message': 'message'},
  OpType.gitBranchCreate: {'name': 'branch'},
  OpType.gitSwitch: {'name': 'branch'},
  OpType.gitignoreUpdate: {'lines': 'lines'},
  OpType.gitOutgoing: {'remote': 'branch', 'branch': 'branch'},
  OpType.gitPush: {'remote': 'branch', 'branch': 'branch', 'token': 'secret'},
  OpType.dockerScaffold: {'template': 'word'},
  OpType.ciScaffold: {'kind': 'word', 'provider': 'word'},
};

/// Résolveurs connus : clé → type produit.
const captainResolvers = <String, String>{
  'audit.gitignoreMissing': 'lines',
  'status.files': 'paths',
  'status.branch': 'branch',
  'detect.ciKind': 'word',
  'forge.token': 'secret',
};

/// Conditions connues.
const captainConditions = <String>{
  'isRepo', 'notRepo', 'isFlutter', 'ciSupported', 'hasGitignoreMissing', 'hasChanges', 'hasOutgoing', 'noOutgoingSecrets',
};

final _id = RegExp(r'^[a-z0-9][a-z0-9-]{0,39}$');
final _branch = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}$');
final _word = RegExp(r'^[a-z][a-z0-9-]{0,30}$');

String? _checkValue(String type, Object? v) {
  bool okPath(String p) => p.isNotEmpty && p.length <= 300 && !p.startsWith('/') && !p.split('/').contains('..') &&
      !p.contains('*') && !p.contains('\u0000') && !p.contains('\n');
  switch (type) {
    case 'int':
      return v is int && v > 0 && v <= 200 ? null : 'entier entre 1 et 200 attendu';
    case 'bool':
      return v is bool ? null : 'booléen attendu';
    case 'path':
      return v is String && okPath(v) ? null : 'chemin relatif au projet attendu (sans .., *, ni chemin absolu)';
    case 'paths':
      return v is List && v.isNotEmpty && v.length <= 500 && v.every((p) => p is String && okPath(p))
          ? null
          : 'liste de 1 à 500 chemins relatifs attendue';
    case 'branch':
      return v is String && _branch.hasMatch(v) && !v.contains('..') ? null : 'nom de branche invalide';
    case 'message':
      return v is String && v.trim().isNotEmpty && v.length <= 2000 && !v.contains('\u0000') ? null : 'message vide ou trop long';
    case 'lines':
      return v is List && v.length <= 50 && v.every((l) => l is String && l.length <= 200 && !l.contains('\n'))
          ? null
          : 'liste de lignes courtes attendue';
    case 'word':
      return v is String && _word.hasMatch(v) ? null : 'mot simple attendu';
    case 'secret':
      return 'un secret ne peut jamais figurer dans un plan (il est lu dans le coffre à l\'exécution)';
  }
  return 'type inconnu';
}

/// Valide un plan avant toute exécution. Liste vide = plan acceptable.
List<String> validatePlan(MissionPlan plan) {
  final e = <String>[];
  if (plan.steps.isEmpty) e.add('Le plan ne contient aucune étape.');
  if (plan.steps.length > plan.limits.maxSteps) {
    e.add('Trop d\'étapes : ${plan.steps.length} (maximum ${plan.limits.maxSteps}).');
  }
  final ids = <String>{};
  for (final s in plan.steps) {
    final where = 'Étape « ${s.id} »';
    if (!_id.hasMatch(s.id)) e.add('$where : identifiant invalide.');
    if (!ids.add(s.id)) e.add('$where : identifiant en double.');
    if (s.title.trim().isEmpty || s.title.length > 120) e.add('$where : titre vide ou trop long.');
    final t = OpType.fromCode(s.op);
    if (t == null) {
      e.add('$where : opération inconnue « ${s.op} ».');
      continue;
    }
    if (!captainAllowedOps.contains(t)) {
      e.add('$where : « ${s.op} » n\'est pas autorisée dans une mission.');
      continue;
    }
    final schema = _paramSchema[t] ?? const {};
    s.params.forEach((k, v) {
      final type = schema[k];
      if (type == null) {
        e.add('$where : paramètre inconnu « $k ».');
      } else if (_checkValue(type, v) case final err?) {
        e.add('$where : $k — $err.');
      }
    });
    s.bind.forEach((k, r) {
      final type = schema[k];
      final produced = captainResolvers[r];
      if (type == null) {
        e.add('$where : paramètre inconnu « $k ».');
      } else if (produced == null) {
        e.add('$where : résolveur inconnu « $r ».');
      } else if (produced != type) {
        e.add('$where : « $r » ne convient pas au paramètre $k.');
      }
      if (s.params.containsKey(k)) e.add('$where : $k est à la fois fixe et calculé.');
    });
    if (s.when != null && !captainConditions.contains(s.when)) e.add('$where : condition inconnue « ${s.when} ».');
    for (final r in s.requires) {
      if (!captainConditions.contains(r)) e.add('$where : prérequis inconnu « $r ».');
    }
  }
  final mutations = plan.steps.where((s) => OpType.fromCode(s.op)?.mutating ?? false).length;
  if (mutations > plan.limits.maxMutations) {
    e.add('Trop de modifications : $mutations (maximum ${plan.limits.maxMutations}).');
  }
  return e;
}

/// Insère un point de contrôle (sauvegarde) avant la première étape qui
/// modifie le projet, s'il n'y en a pas déjà un.
MissionPlan withCheckpoint(MissionPlan plan) {
  // Robuste aux opérations inconnues : la validation les signalera ensuite.
  final first = plan.steps.indexWhere((s) => OpType.fromCode(s.op) != null && s.risk == StepRisk.modification);
  if (first < 0) return plan;
  if (plan.steps.take(first).any((s) => s.op == OpType.projectBackup.code)) return plan;
  final steps = [...plan.steps]..insert(
      first,
      const StepSpec(
        id: 'point-de-controle',
        title: 'Point de contrôle : sauvegarde du projet',
        why: 'Avant la première modification, le projet entier (historique Git compris) est archivé dans le dossier privé '
            'du compagnon. En cas de problème, il pourra être restauré dans un nouveau dossier.',
        op: 'project.backup',
      ));
  return plan.copyWith(steps: steps);
}
