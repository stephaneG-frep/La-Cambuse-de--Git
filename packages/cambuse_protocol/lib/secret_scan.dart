/// Détection de secrets probables et motifs `.gitignore`, partagée par le
/// compagnon (audit, blocage des commits) et ses tests.
library;

class SecretFinding {
  const SecretFinding(this.file, this.kind, {this.line});
  final String file;
  final String kind;
  final int? line;

  Map<String, dynamic> toJson() => {'file': file, 'kind': kind, 'line': ?line};
}

/// Motifs de contenu. Les valeurs trouvées ne sont jamais renvoyées.
final secretContentPatterns = <String, RegExp>{
  'jeton GitHub': RegExp(r'\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})'),
  'jeton GitLab': RegExp(r'\bglpat-[A-Za-z0-9_\-]{20,}'),
  'clé API (sk-)': RegExp(r'\bsk-[A-Za-z0-9_\-]{20,}'),
  'clé AWS': RegExp(r'\b(AKIA|ASIA)[A-Z0-9]{16}\b'),
  'clé Google': RegExp(r'\bAIza[0-9A-Za-z_\-]{35}\b'),
  'jeton Slack': RegExp(r'\bxox[abprs]-[A-Za-z0-9-]{10,}'),
  'clé privée': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
  'mot de passe en clair': RegExp(
    r'''(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*["']?[^\s"'$<{]{8,}''',
    caseSensitive: false,
  ),
};

/// Noms de fichiers typiquement sensibles.
final secretFilePatterns = <String, RegExp>{
  'fichier .env': RegExp(r'(^|/)\.env(\.[\w.-]+)?$'),
  'clé SSH': RegExp(r'(^|/)id_(rsa|dsa|ecdsa|ed25519)$'),
  'certificat ou clé': RegExp(r'\.(pem|p12|pfx|key)$', caseSensitive: false),
  'keystore Android': RegExp(r'\.(jks|keystore)$', caseSensitive: false),
  'signature Android': RegExp(r'(^|/)key\.properties$'),
  'identifiants cloud': RegExp(r'(^|/)(credentials|service[-_]account[\w-]*)\.json$', caseSensitive: false),
};

/// Fichiers d'exemple explicitement factices (ignorés par l'analyse de nom).
final _exampleFile = RegExp(r'\.(example|sample|template|dist)$|(^|/)\.env\.(example|sample)$');

String? sensitiveFileKind(String path) {
  if (_exampleFile.hasMatch(path)) return null;
  for (final e in secretFilePatterns.entries) {
    if (e.value.hasMatch(path)) return e.key;
  }
  return null;
}

/// Analyse un contenu texte ; renvoie au plus une alerte par ligne.
List<SecretFinding> scanContent(String path, String content, {int maxFindings = 20}) {
  final out = <SecretFinding>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length && out.length < maxFindings; i++) {
    final line = lines[i];
    if (line.length > 5000) continue; // lignes minifiées : ignorées
    for (final e in secretContentPatterns.entries) {
      if (e.value.hasMatch(line)) {
        out.add(SecretFinding(path, e.key, line: i + 1));
        break;
      }
    }
  }
  return out;
}

/// Masque les secrets probables d'un texte (journaux de conteneurs…).
String maskSecrets(String text) {
  var out = text;
  for (final re in secretContentPatterns.values) {
    out = out.replaceAll(re, '[SECRET MASQUÉ]');
  }
  return out;
}

/// Vrai si [bytes] ressemble à du binaire (octet nul dans les 8000 premiers).
bool looksBinary(List<int> bytes) {
  final n = bytes.length < 8000 ? bytes.length : 8000;
  for (var i = 0; i < n; i++) {
    if (bytes[i] == 0) return true;
  }
  return false;
}

/// Interprétation simplifiée d'un `.gitignore` racine : motifs de nom,
/// `*`/`?`, dossiers (`build/`), chemins ancrés (`/x`), commentaires et
/// négations (`!motif`, appliquées dans l'ordre).
class GitignoreMatcher {
  GitignoreMatcher(String content) {
    for (final raw in content.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final negate = line.startsWith('!');
      if (negate) line = line.substring(1);
      final dir = line.endsWith('/');
      if (dir) line = line.substring(0, line.length - 1);
      final anchored = line.startsWith('/') || line.contains('/');
      if (line.startsWith('/')) line = line.substring(1);
      _rules.add((negate, dir, anchored, _glob(line)));
    }
  }

  final _rules = <(bool, bool, bool, RegExp)>[];

  static RegExp _glob(String p) {
    final b = StringBuffer('^');
    for (var i = 0; i < p.length; i++) {
      final c = p[i];
      if (c == '*' && i + 1 < p.length && p[i + 1] == '*') {
        b.write('.*');
        i++;
      } else if (c == '*') {
        b.write('[^/]*');
      } else if (c == '?') {
        b.write('[^/]');
      } else {
        b.write(RegExp.escape(c));
      }
    }
    b.write(r'$');
    return RegExp(b.toString());
  }

  bool ignores(String path) {
    final parts = path.split('/');
    var ignored = false;
    for (final (negate, dir, anchored, re) in _rules) {
      var hit = false;
      // Un motif de dossier s'applique à tout chemin qui le traverse.
      for (var i = 0; i < parts.length && !hit; i++) {
        final isLast = i == parts.length - 1;
        if (dir && isLast) continue;
        final candidate = anchored ? parts.sublist(0, i + 1).join('/') : parts[i];
        hit = re.hasMatch(candidate);
      }
      if (hit) ignored = !negate;
    }
    return ignored;
  }
}
