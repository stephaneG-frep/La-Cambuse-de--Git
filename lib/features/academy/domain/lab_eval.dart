import 'package:cambuse_protocol/cambuse_protocol.dart';

import 'course.dart';

/// Résultat d'analyse d'un labo : constats + objectifs atteints.
class LabResult {
  const LabResult(this.findings, this.goalsMet);
  final List<LintFinding> findings;
  final List<bool> goalsMet;
  bool get complete => goalsMet.every((g) => g);
}

LabResult evaluateLab(FileLab lab, String content) {
  final findings = lab.kind == 'dockerfile' ? lintDockerfile(content) : lintCompose(content);
  final rules = findings.map((f) => f.rule).toSet();
  bool met(LabGoal g) => switch (g.type) {
        'noRule' => !rules.contains(g.params['rule']),
        'noSeverity' => !findings.any((f) => f.severity.name == g.params['severity']),
        'contains' => content.contains(g.params['text'] as String),
        'notContains' => !content.contains(g.params['text'] as String),
        'instruction' => lab.kind == 'dockerfile' &&
            parseDockerfile(content).any((i) => i.keyword == (g.params['keyword'] as String).toUpperCase()),
        'stages' => lab.kind == 'dockerfile' &&
            parseDockerfile(content).where((i) => i.keyword == 'FROM').length >= (g.params['min'] as int),
        'valid' => !rules.contains('DF000') && !rules.contains('DC000'),
        _ => false,
      };
  return LabResult(findings, [for (final g in lab.goals) met(g)]);
}
