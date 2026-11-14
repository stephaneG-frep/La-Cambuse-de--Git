/// Rapport de fin de mission et guide de retour arrière partiel.
library;

import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'engine.dart';
import 'mission.dart';

/// Une possibilité de retour arrière.
class RollbackItem {
  const RollbackItem(this.title, this.detail, {this.action, this.manual = const []});
  final String title;
  final String detail;

  /// Action exécutable via le compagnon (avec approbation), si elle existe.
  final OpRequest? action;

  /// Commandes à exécuter vous-même si vous le décidez (jamais automatiques).
  final List<String> manual;
}

/// Ce qui peut être défait, étape par étape, et comment.
List<RollbackItem> rollbackGuide(RunSnapshot run) {
  final items = <RollbackItem>[];
  final done = [
    for (var i = 0; i < run.steps.length; i++)
      if (run.steps[i].state == MissionStepState.reussie) (run.plan.steps[i], run.context),
  ];
  final modified = done.any((d) => d.$1.risk == StepRisk.modification);
  if (modified && run.checkpointId != null) {
    items.add(RollbackItem(
      'Restaurer le point de contrôle',
      'La sauvegarde ${run.checkpointId} est restaurée dans un NOUVEAU dossier à côté du projet : rien n\'est écrasé, '
          'vous comparez puis gardez la version voulue.',
      action: OpRequest(type: OpType.backupRestore.code, root: run.projectPath, params: {'id': run.checkpointId}),
    ));
  }
  for (final (s, ctx) in done) {
    switch (s.type) {
      case OpType.gitCommit:
        items.add(RollbackItem('Annuler le commit « ${s.params['message'] ?? ''} »',
            'Non automatique : réécrire l\'historique est une décision qui vous appartient.',
            manual: ['git reset --soft HEAD~1   # si le commit n\'a pas été publié (les modifications restent)', 'git revert HEAD          # s\'il a déjà été publié']));
      case OpType.gitAdd:
        items.add(const RollbackItem('Retirer des fichiers de l\'index', 'Les fichiers restent intacts sur le disque.',
            manual: ['git restore --staged -- <fichier>']));
      case OpType.gitignoreUpdate:
        items.add(const RollbackItem('Lignes ajoutées au .gitignore', 'Modifiez le fichier à la main ou restaurez le point de contrôle.'));
      case OpType.gitInit:
        items.add(const RollbackItem('Dépôt Git créé',
            'Supprimer le dossier .git effacerait tout l\'historique : préférez la restauration du point de contrôle.'));
      case OpType.ciScaffold:
      case OpType.dockerScaffold:
        final created = ((ctx.result(s.type)?['created'] as List?) ?? const []).join(', ');
        items.add(RollbackItem('Fichiers générés${created.isEmpty ? '' : ' : $created'}',
            'Aucun fichier existant n\'avait été écrasé : supprimer ces fichiers suffit.'));
      case OpType.gitBranchCreate:
        items.add(RollbackItem('Branche « ${s.params['name']} » créée', 'Supprimable si elle ne contient rien d\'utile.',
            manual: ['git branch -d ${s.params['name']}']));
      case OpType.gitSwitch:
        items.add(const RollbackItem('Changement de branche', 'Revenez à la branche précédente.', manual: ['git switch -']));
      case OpType.gitPush:
        items.add(const RollbackItem('Publication (push)',
            'NON annulable automatiquement : les commits sont sur le serveur et ont pu être récupérés par d\'autres. '
                'Créez un commit inverse puis publiez-le ; ne forcez jamais une branche partagée.',
            manual: ['git revert <sha>', 'git push']));
      case OpType.flutterBuildApkDebug:
      case OpType.flutterBuildLinux:
      case OpType.flutterTest:
      case OpType.flutterAnalyze:
        break; // Seuls des fichiers de build/ sont produits : rien à défaire dans le code source.
      default:
        break;
    }
  }
  return items;
}

String _d(Duration? d) {
  if (d == null) return '—';
  if (d.inSeconds < 60) return '${d.inSeconds} s';
  return '${d.inMinutes} min ${d.inSeconds % 60} s';
}

String _t(DateTime t) => t.toIso8601String().substring(0, 19).replaceFirst('T', ' ');

/// Rapport Markdown de la mission (aucun secret : le jeton n'est jamais journalisé).
String buildReport(RunSnapshot run, List<CaptainEvent> events) {
  final b = StringBuffer()
    ..writeln('# Rapport de mission — ${run.plan.title}')
    ..writeln()
    ..writeln('- Projet : `${run.projectPath}`')
    ..writeln('- Origine du plan : ${run.plan.source == PlanSource.ia ? 'proposé par le professeur IA, validé puis approuvé' : 'mission prédéfinie'}')
    ..writeln('- État : **${run.state.label}**${run.reason == null ? '' : ' — ${run.reason}'}')
    ..writeln('- Démarrée : ${_t(run.createdAt)} · durée d\'exécution : ${_d(run.elapsed)}')
    ..writeln('- Limites : ${run.plan.limits.maxSteps} étapes, ${run.plan.limits.maxMutations} modifications, '
        '${run.plan.limits.maxDuration.inMinutes} min au total')
    ..writeln('- Point de contrôle : ${run.checkpointId ?? 'aucun (aucune modification prévue ou non atteinte)'}')
    ..writeln()
    ..writeln('## Étapes')
    ..writeln()
    ..writeln('| # | Étape | Risque | État | Durée | Remarque |')
    ..writeln('|---|---|---|---|---|---|');
  for (var i = 0; i < run.plan.steps.length; i++) {
    final s = run.plan.steps[i];
    final r = run.steps[i];
    b.writeln('| ${i + 1} | ${s.title} (`${s.op}`) | ${s.risk.label} | ${r.state.label} | ${_d(r.duration)} | ${(r.note ?? '').replaceAll('|', '/')} |');
  }
  final decisions = events.where((e) => e.kind == 'decision').toList();
  b
    ..writeln()
    ..writeln('## Décisions (${decisions.length})')
    ..writeln();
  for (final e in decisions) {
    b.writeln('- ${_t(e.at)} — ${e.message}');
  }
  final rb = rollbackGuide(run);
  b
    ..writeln()
    ..writeln('## Retour arrière')
    ..writeln();
  if (rb.isEmpty) b.writeln('Aucune modification à défaire.');
  for (final r in rb) {
    b.writeln('- **${r.title}** : ${r.detail}${r.action == null ? '' : ' (action proposée dans l\'application, avec approbation)'}');
    for (final m in r.manual) {
      b.writeln('  - `$m`');
    }
  }
  b
    ..writeln()
    ..writeln('## Journal horodaté')
    ..writeln();
  for (final e in events) {
    b.writeln('- ${_t(e.at)} [${e.kind}]${e.step == null ? '' : ' étape ${e.step! + 1}'} — ${e.message}');
  }
  return b.toString();
}
