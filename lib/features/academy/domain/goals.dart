import 'course.dart';
import 'sandbox/git_sandbox.dart';

/// Types d'objectifs reconnus. Tout autre type est une erreur de contenu.
const knownGoalTypes = {
  'initialized', 'configSet', 'fileExists', 'fileContains', 'tracked', 'staged',
  'notStaged', 'clean', 'commitCount', 'lastCommitMessageContains', 'branchExists',
  'branchDeleted', 'currentBranch', 'merged', 'mergeCommitExists', 'noConflicts',
  'tagExists', 'annotatedTag', 'ignored', 'fileCommitted', 'commandUsed',
  'fileMatchesHead', 'untracked', 'noMarkers', 'tagDeleted',
};

/// Évalue un objectif sur l'état courant du bac à sable.
bool goalMet(Goal g, GitSandbox s) {
  switch (g.type) {
    case 'initialized':
      return s.initialized;
    case 'configSet':
      return (s.config[g.param('key')] ?? '').trim().isNotEmpty;
    case 'fileExists':
      return s.workTree.containsKey(g.param('path'));
    case 'fileContains':
      return s.workTree[g.param('path')]?.contains(g.param('text')) ?? false;
    case 'tracked':
      return s.index.containsKey(g.param('path'));
    case 'untracked':
      return s.untracked.contains(g.param('path'));
    case 'staged':
      return s.stagedChanges.containsKey(g.param('path'));
    case 'notStaged':
      return !s.stagedChanges.containsKey(g.param('path'));
    case 'clean':
      return s.initialized && s.isClean && !s.isMerging;
    case 'commitCount':
      return s.logFrom(s.headCommitId).length >= (g.params['min'] as int);
    case 'lastCommitMessageContains':
      return s.headCommit?.message.toLowerCase().contains(g.param('text').toLowerCase()) ??
          false;
    case 'branchExists':
      return s.branches.containsKey(g.param('name')) && s.branches[g.param('name')] != null;
    case 'branchDeleted':
      return !s.branches.containsKey(g.param('name'));
    case 'currentBranch':
      return s.initialized && s.head == g.param('name');
    case 'merged':
      final id = s.branches[g.param('branch')] ?? s.tags[g.param('branch')];
      return s.isAncestor(id, s.headCommitId) || _mergedDeleted(s, g.param('branch'));
    case 'mergeCommitExists':
      return s.logFrom(s.headCommitId).any((c) => c.parents.length > 1);
    case 'noConflicts':
      return !s.isMerging && !s.workTree.values.any((c) => c.contains('<<<<<<<'));
    case 'noMarkers':
      final c = s.workTree[g.param('path')];
      return c != null && !c.contains('<<<<<<<') && !c.contains('>>>>>>>') && !c.contains('=======');
    case 'tagDeleted':
      return !s.tags.containsKey(g.param('name'));
    case 'tagExists':
      return s.tags.containsKey(g.param('name'));
    case 'annotatedTag':
      return s.tagMessages.containsKey(g.param('name'));
    case 'ignored':
      final p = g.param('path');
      return s.workTree.containsKey(p) && s.isIgnored(p) && !s.index.containsKey(p);
    case 'fileCommitted':
      return s.headTree.containsKey(g.param('path'));
    case 'fileMatchesHead':
      final p = g.param('path');
      return s.workTree[p] == s.headTree[p] && s.index[p] == s.headTree[p];
    case 'commandUsed':
      final prefix = g.param('prefix');
      return s.history.any((h) => h == prefix || h.startsWith('$prefix '));
    default:
      throw FormatException('Objectif inconnu : ${g.type}');
  }
}

/// Une branche fusionnée puis supprimée : on retrouve un commit de fusion qui
/// la nomme dans l'historique.
bool _mergedDeleted(GitSandbox s, String branch) =>
    !s.branches.containsKey(branch) &&
    s.logFrom(s.headCommitId).any((c) => c.message.contains("'$branch'"));

/// Progression d'un exercice : une étape validée le reste (même si l'état
/// évolue ensuite), et les étapes se valident dans l'ordre.
class ExerciseSession {
  ExerciseSession(this.exercise) : sandbox = GitSandbox() {
    sandbox.runAll(exercise.setup);
  }

  final Exercise exercise;
  final GitSandbox sandbox;
  int completedSteps = 0;

  bool get isComplete => completedSteps >= exercise.steps.length;

  ExerciseStep? get currentStep =>
      isComplete ? null : exercise.steps[completedSteps];

  /// Exécute une commande puis valide autant d'étapes que possible.
  SandboxResult submit(String command) {
    final r = sandbox.run(command);
    refresh();
    return r;
  }

  void refresh() {
    while (!isComplete && currentStep!.goals.every((g) => goalMet(g, sandbox))) {
      completedSteps++;
    }
  }
}
