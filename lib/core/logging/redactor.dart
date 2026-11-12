/// Masque les secrets probables avant toute écriture dans un journal, un export
/// ou un prompt IA (SPEC §6 et §8).
///
/// Approche conservatrice : mieux vaut masquer un faux positif que laisser
/// fuiter un jeton.
class Redactor {
  const Redactor();

  static const mask = '[SECRET MASQUÉ]';

  static final List<RegExp> _patterns = [
    // Jetons GitHub (classiques, fine-grained, OAuth, app).
    RegExp(r'\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})'),
    // Jetons GitLab.
    RegExp(r'\bglpat-[A-Za-z0-9_\-]{20,}'),
    // Clés de type « sk-… » (OpenAI, Anthropic, etc.).
    RegExp(r'\bsk-[A-Za-z0-9_\-]{16,}'),
    // Clés d'accès AWS.
    RegExp(r'\b(AKIA|ASIA)[A-Z0-9]{16}\b'),
    // Clés Google API.
    RegExp(r'\bAIza[0-9A-Za-z_\-]{35}\b'),
    // Slack.
    RegExp(r'\bxox[abprs]-[A-Za-z0-9-]{10,}'),
    // Blocs de clé privée.
    RegExp(
      r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----',
    ),
  ];

  /// En-têtes et affectations dont la valeur doit être masquée.
  static final RegExp _bearer =
      RegExp(r'(Bearer|token|Basic)\s+[A-Za-z0-9._~+/=\-]{8,}', caseSensitive: false);
  static final RegExp _assignment = RegExp(
    r'''((?:api[_-]?key|secret|password|passwd|token|access[_-]?key)\s*[:=]\s*)(["']?)[^\s"']{4,}\2''',
    caseSensitive: false,
  );
  /// Identifiants dans une URL : https://user:motdepasse@hôte
  static final RegExp _urlCredentials = RegExp(r'(https?://)[^/\s:@]+:[^/\s@]+@');

  String redact(String input) {
    var out = input;
    for (final p in _patterns) {
      out = out.replaceAll(p, mask);
    }
    out = out.replaceAllMapped(_bearer, (m) => '${m.group(1)} $mask');
    out = out.replaceAllMapped(_assignment, (m) => '${m.group(1)}$mask');
    out = out.replaceAllMapped(_urlCredentials, (m) => '${m.group(1)}$mask@');
    return out;
  }

  /// Vrai si [input] contient au moins un secret probable.
  bool containsSecret(String input) => redact(input) != input;
}
