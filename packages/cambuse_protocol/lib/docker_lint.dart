/// Analyse statique de Dockerfile et de fichiers Compose (hors ligne, sans
/// Docker). Partagée par l'application (labos de l'Académie) et le compagnon
/// (analyse des projets).
library;

import 'package:yaml/yaml.dart';

import 'secret_scan.dart';

enum LintSeverity { blocking, warning, info }

class LintFinding {
  const LintFinding(this.rule, this.severity, this.message, {this.line, this.fix});

  final String rule;
  final LintSeverity severity;
  final String message;
  final int? line;

  /// Correction suggérée (texte court).
  final String? fix;

  Map<String, dynamic> toJson() => {
        'rule': rule,
        'severity': severity.name,
        'message': message,
        'line': ?line,
        'fix': ?fix,
      };

  static LintFinding fromJson(Map<String, dynamic> j) => LintFinding(
        j['rule'] as String,
        LintSeverity.values.byName(j['severity'] as String),
        j['message'] as String,
        line: j['line'] as int?,
        fix: j['fix'] as String?,
      );
}

/// Instruction Dockerfile (après jonction des lignes continuées).
class DockerInstruction {
  const DockerInstruction(this.keyword, this.args, this.line);
  final String keyword;
  final String args;
  final int line;
}

/// Découpe un Dockerfile : commentaires, continuations `\`, mots-clés.
List<DockerInstruction> parseDockerfile(String content) {
  final out = <DockerInstruction>[];
  final lines = content.split('\n');
  var buffer = StringBuffer();
  int? start;
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i].replaceAll('\r', '');
    final trimmed = raw.trim();
    if (start == null && (trimmed.isEmpty || trimmed.startsWith('#'))) continue;
    if (start != null && trimmed.startsWith('#')) continue; // commentaire au milieu d'une continuation
    start ??= i + 1;
    if (trimmed.endsWith(r'\')) {
      buffer.write('${trimmed.substring(0, trimmed.length - 1)} ');
      continue;
    }
    buffer.write(trimmed);
    final text = buffer.toString().trim();
    final sp = text.indexOf(RegExp(r'\s'));
    out.add(DockerInstruction(
      (sp < 0 ? text : text.substring(0, sp)).toUpperCase(),
      sp < 0 ? '' : text.substring(sp + 1).trim(),
      start,
    ));
    buffer = StringBuffer();
    start = null;
  }
  return out;
}

final _secretName = RegExp(r'(PASSWORD|PASSWD|SECRET|TOKEN|API_?KEY|PRIVATE_?KEY|ACCESS_?KEY)', caseSensitive: false);
final _buildCmd = RegExp(r'(npm run build|yarn build|flutter build|go build|mvn (package|install)|gradle(w)? build|cargo build|dart compile)');

/// Analyse un Dockerfile. Les valeurs secrètes ne sont jamais recopiées.
List<LintFinding> lintDockerfile(String content) {
  final ins = parseDockerfile(content);
  final f = <LintFinding>[];
  if (ins.isEmpty || !ins.any((i) => i.keyword == 'FROM')) {
    return [const LintFinding('DF000', LintSeverity.blocking, 'Aucune instruction FROM : ce n\'est pas un Dockerfile valide.')];
  }
  final stages = <String>{};
  final froms = ins.where((i) => i.keyword == 'FROM').toList();
  for (final i in froms) {
    final parts = i.args.split(RegExp(r'\s+')).where((p) => !p.startsWith('--')).toList();
    final image = parts.isEmpty ? '' : parts.first;
    if (parts.length >= 3 && parts[1].toUpperCase() == 'AS') stages.add(parts[2].toLowerCase());
    if (stages.contains(image.toLowerCase()) || image == 'scratch') continue;
    final hasDigest = image.contains('@sha256:');
    final tag = image.contains(':') ? image.substring(image.lastIndexOf(':') + 1) : null;
    if (!hasDigest && (tag == null || tag == 'latest')) {
      f.add(LintFinding('DF001', LintSeverity.warning,
          'Image de base « $image » sans version fixe : le build peut changer du jour au lendemain.',
          line: i.line, fix: 'Épinglez une version précise, ex. node:22.11-slim (ou un digest @sha256).'));
    }
  }
  final users = ins.where((i) => i.keyword == 'USER').toList();
  final lastStageStart = ins.lastIndexOf(froms.last);
  final finalUsers = users.where((u) => ins.indexOf(u) > lastStageStart).toList();
  if (finalUsers.isEmpty || RegExp(r'^(root|0)(:|$)').hasMatch(finalUsers.last.args.trim())) {
    f.add(LintFinding('DF002', LintSeverity.warning,
        'Le conteneur final s\'exécute en root : une faille dans l\'application donne tous les droits dans le conteneur.',
        line: finalUsers.isEmpty ? null : finalUsers.last.line,
        fix: 'Ajoutez un utilisateur dédié puis « USER appli » avant CMD.'));
  }
  var hasHealthcheck = false;
  var installedDeps = false;
  for (var idx = 0; idx < ins.length; idx++) {
    final i = ins[idx];
    final a = i.args;
    switch (i.keyword) {
      case 'ENV' || 'ARG':
        final assignments = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)(?:=|\s+)("[^"]*"|\S+)?').allMatches(a);
        for (final m in assignments) {
          final name = m.group(1)!;
          final value = m.group(2);
          if (_secretName.hasMatch(name) && value != null && value.isNotEmpty && !value.startsWith(r'$')) {
            f.add(LintFinding('DF003', LintSeverity.blocking,
                'Secret probable écrit en clair dans $name (valeur masquée) : il reste lisible dans les couches de l\'image.',
                line: i.line, fix: 'Utilisez un secret de build (RUN --mount=type=secret) ou une variable fournie à l\'exécution.'));
          }
        }
      case 'ADD':
        if (RegExp(r'https?://').hasMatch(a)) {
          f.add(LintFinding('DF004', LintSeverity.warning,
              'ADD télécharge un fichier distant sans vérification d\'intégrité.',
              line: i.line, fix: 'Téléchargez avec RUN curl … puis vérifiez la somme SHA-256.'));
        } else if (!RegExp(r'\.(tar|tgz|tar\.gz|tar\.xz|tar\.bz2)(\s|$)').hasMatch(a)) {
          f.add(LintFinding('DF004', LintSeverity.info, 'ADD utilisé pour copier des fichiers locaux.',
              line: i.line, fix: 'Préférez COPY, plus prévisible.'));
        }
      case 'RUN':
        // Limite de mot : « | sha256sum » (vérification) ne doit pas déclencher la règle.
        if (RegExp(r'(curl|wget)[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b').hasMatch(a)) {
          f.add(LintFinding('DF009', LintSeverity.warning,
              'Script téléchargé puis exécuté directement (curl | sh) : chaîne d\'approvisionnement non vérifiée.',
              line: i.line, fix: 'Téléchargez, vérifiez la somme de contrôle, puis exécutez.'));
        }
        if (RegExp(r'apt-get\s+(dist-)?upgrade').hasMatch(a)) {
          f.add(LintFinding('DF006', LintSeverity.warning, 'apt-get upgrade rend le build non reproductible.',
              line: i.line, fix: 'Mettez plutôt à jour l\'image de base (nouvelle version épinglée).'));
        }
        if (RegExp(r'apt-get\s+install').hasMatch(a)) {
          if (!a.contains('--no-install-recommends')) {
            f.add(LintFinding('DF005', LintSeverity.info, 'apt-get install sans --no-install-recommends : image plus lourde.',
                line: i.line, fix: 'Ajoutez --no-install-recommends.'));
          }
          if (!a.contains('/var/lib/apt/lists')) {
            f.add(LintFinding('DF005', LintSeverity.info, 'Cache apt laissé dans l\'image.',
                line: i.line, fix: 'Terminez par && rm -rf /var/lib/apt/lists/* dans le même RUN.'));
          }
        }
        if (RegExp(r'chmod\s+(-R\s+)?777').hasMatch(a)) {
          f.add(LintFinding('DF015', LintSeverity.warning, 'chmod 777 : tout le monde peut modifier ces fichiers.',
              line: i.line, fix: 'Donnez les droits minimaux (ex. chown appli puis chmod 755).'));
        }
        if (RegExp(r'(^|\s|&&|;)sudo\s').hasMatch(a)) {
          f.add(LintFinding('DF012', LintSeverity.warning, 'sudo est inutile et dangereux dans un Dockerfile.',
              line: i.line, fix: 'Passez par USER root le temps de l\'installation, puis revenez à l\'utilisateur dédié.'));
        }
        if (RegExp(r'(^|&&|;)\s*cd\s').hasMatch(a)) {
          f.add(LintFinding('DF013', LintSeverity.info, '« cd » dans RUN : le répertoire ne persiste pas d\'une instruction à l\'autre.',
              line: i.line, fix: 'Utilisez WORKDIR.'));
        }
        if (RegExp(r'(npm (ci|install)|pip install|pub get|go mod download|bundle install|composer install)').hasMatch(a)) {
          installedDeps = true;
        }
        for (final s in scanContent('Dockerfile', a, maxFindings: 1)) {
          f.add(LintFinding('DF003', LintSeverity.blocking, '${s.kind} probable dans une commande RUN (valeur masquée).',
              line: i.line, fix: 'Ne mettez jamais de secret dans le Dockerfile.'));
        }
      case 'COPY':
        if (!installedDeps && RegExp(r'^\.\s+\.?/?\S*$').hasMatch(a.trim()) &&
            ins.skip(idx + 1).any((n) => n.keyword == 'RUN' && RegExp(r'(npm (ci|install)|pip install|pub get|go mod download)').hasMatch(n.args))) {
          f.add(LintFinding('DF007', LintSeverity.info,
              'Tout le projet est copié avant l\'installation des dépendances : le cache est invalidé à chaque modification.',
              line: i.line, fix: 'Copiez d\'abord le fichier de dépendances (package.json, pubspec.yaml…), installez, puis copiez le reste.'));
        }
      case 'EXPOSE':
        if (RegExp(r'(^|\s)22(/tcp)?(\s|$)').hasMatch(a)) {
          f.add(LintFinding('DF011', LintSeverity.warning, 'Port SSH exposé : un conteneur ne devrait pas embarquer de serveur SSH.',
              line: i.line, fix: 'Utilisez docker exec pour le débogage.'));
        }
      case 'HEALTHCHECK':
        hasHealthcheck = !a.toUpperCase().startsWith('NONE');
      case 'CMD' || 'ENTRYPOINT':
        if (!a.trimLeft().startsWith('[')) {
          f.add(LintFinding('DF014', LintSeverity.info,
              '${i.keyword} en forme « shell » : le processus ne reçoit pas les signaux d\'arrêt.',
              line: i.line, fix: 'Utilisez la forme JSON, ex. CMD ["node", "server.js"].'));
        }
      case 'WORKDIR':
        if (!a.startsWith('/') && !a.startsWith(r'$')) {
          f.add(LintFinding('DF013', LintSeverity.info, 'WORKDIR relatif : dépend du répertoire précédent.',
              line: i.line, fix: 'Utilisez un chemin absolu, ex. /app.'));
        }
    }
  }
  if (froms.length == 1 && ins.any((i) => i.keyword == 'RUN' && _buildCmd.hasMatch(i.args))) {
    f.add(const LintFinding('DF010', LintSeverity.info,
        'Compilation et exécution dans la même image : les outils de build alourdissent l\'image finale.',
        fix: 'Utilisez un build multi-étapes (FROM … AS build, puis COPY --from=build).'));
  }
  if (!hasHealthcheck) {
    f.add(const LintFinding('DF008', LintSeverity.info, 'Aucun HEALTHCHECK : Docker ne sait pas si l\'application répond.',
        fix: 'Ajoutez HEALTHCHECK CMD … (ou un healthcheck dans compose.yaml).'));
  }
  f.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return f;
}

/// Analyse un fichier Compose (YAML).
List<LintFinding> lintCompose(String content) {
  final Object? doc;
  try {
    doc = loadYaml(content);
  } on YamlException catch (e) {
    return [LintFinding('DC000', LintSeverity.blocking, 'YAML invalide : ${e.message}', line: e.span == null ? null : e.span!.start.line + 1)];
  }
  if (doc is! Map || doc['services'] is! Map) {
    return [const LintFinding('DC000', LintSeverity.blocking, 'Aucune section « services » : fichier Compose incomplet.')];
  }
  final services = doc['services'] as Map;
  final f = <LintFinding>[];
  int? lineOf(Object? node) => node is YamlNode ? node.span.start.line + 1 : null;
  final yamlServices = (doc as YamlMap).nodes['services'];
  // Ligne de la clé du service (« web: »), plus parlante que celle de son contenu.
  YamlNode? serviceNode(String name) => yamlServices is YamlMap
      ? yamlServices.nodes.keys.whereType<YamlNode>().where((k) => k.value == name).firstOrNull
      : null;

  final withHealth = <String>{
    for (final e in services.entries)
      if (e.value is Map && (e.value as Map)['healthcheck'] != null) '${e.key}',
  };

  for (final e in services.entries) {
    final name = '${e.key}';
    final s = e.value;
    if (s is! Map) continue;
    final line = lineOf(serviceNode(name));
    final image = s['image'];
    if (image is String && s['build'] == null) {
      final tag = image.contains(':') ? image.substring(image.lastIndexOf(':') + 1) : null;
      if (!image.contains('@sha256:') && (tag == null || tag == 'latest')) {
        f.add(LintFinding('DC001', LintSeverity.warning, '$name : image « $image » sans version fixe.',
            line: line, fix: 'Épinglez une version, ex. postgres:17.2-alpine.'));
      }
    }
    if (s['privileged'] == true) {
      f.add(LintFinding('DC002', LintSeverity.blocking, '$name : privileged donne un accès quasi total à la machine hôte.',
          line: line, fix: 'Retirez privileged ; ajoutez seulement les capacités nécessaires (cap_add).'));
    }
    final caps = s['cap_add'];
    if (caps is List && caps.any((c) => '$c'.toUpperCase() == 'ALL' || '$c'.toUpperCase() == 'SYS_ADMIN')) {
      f.add(LintFinding('DC003', LintSeverity.warning, '$name : capacités Linux très larges (ALL ou SYS_ADMIN).',
          line: line, fix: 'Listez uniquement les capacités indispensables.'));
    }
    if (s['network_mode'] == 'host') {
      f.add(LintFinding('DC004', LintSeverity.warning, '$name : network_mode host supprime l\'isolation réseau.',
          line: line, fix: 'Utilisez un réseau Compose et publiez seulement les ports utiles.'));
    }
    final volumes = s['volumes'];
    if (volumes is List) {
      for (final v in volumes) {
        final src = v is Map ? '${v['source']}' : '$v'.split(':').first;
        if (src.contains('docker.sock')) {
          f.add(LintFinding('DC005', LintSeverity.blocking,
              '$name : le socket Docker est monté, ce qui donne au conteneur le contrôle de l\'hôte (équivalent root).',
              line: line, fix: 'Ne montez jamais /var/run/docker.sock sauf outil d\'administration de confiance.'));
        }
      }
    }
    final env = s['environment'];
    final pairs = <String, String?>{};
    if (env is Map) {
      env.forEach((k, v) => pairs['$k'] = v?.toString());
    } else if (env is List) {
      for (final item in env) {
        final str = '$item';
        final eq = str.indexOf('=');
        pairs[eq < 0 ? str : str.substring(0, eq)] = eq < 0 ? null : str.substring(eq + 1);
      }
    }
    pairs.forEach((k, v) {
      if (_secretName.hasMatch(k) && v != null && v.isNotEmpty && !v.startsWith(r'$')) {
        f.add(LintFinding('DC006', LintSeverity.blocking, '$name : secret en clair dans $k (valeur masquée).',
            line: line, fix: 'Utilisez env_file (ignoré par Git), des variables \${…} ou les secrets Compose.'));
      }
    });
    final ports = s['ports'];
    if (ports is List) {
      for (final p in ports) {
        final str = p is Map ? '${p['published'] ?? ''}:${p['target'] ?? ''}' : '$p';
        final segments = str.split(':');
        final bound = segments.length >= 3 || (p is Map && p['host_ip'] != null);
        if (segments.length == 2 && !bound) {
          f.add(LintFinding('DC007', LintSeverity.info,
              '$name : port $str publié sur toutes les interfaces (visible depuis le réseau local).',
              line: line, fix: 'Pour le développement, préférez "127.0.0.1:$str".'));
        }
      }
    }
    final deps = s['depends_on'];
    if (deps is List) {
      for (final d in deps) {
        if (withHealth.contains('$d')) {
          f.add(LintFinding('DC008', LintSeverity.info,
              '$name : depends_on n\'attend que le démarrage de $d, pas qu\'il soit prêt.',
              line: line, fix: 'Utilisez depends_on: { $d: { condition: service_healthy } }.'));
        }
      }
    }
    if (s['restart'] == null) {
      f.add(LintFinding('DC009', LintSeverity.info, '$name : aucune politique de redémarrage.',
          line: line, fix: 'Ajoutez restart: unless-stopped (ou on-failure).'));
    }
    final img = '${s['image'] ?? ''}';
    if (s['healthcheck'] == null && RegExp(r'(postgres|mysql|mariadb|redis|mongo)').hasMatch(img)) {
      f.add(LintFinding('DC010', LintSeverity.info, '$name : base de données sans healthcheck.',
          line: line, fix: 'Ajoutez un healthcheck (ex. pg_isready) pour que les autres services attendent qu\'elle soit prête.'));
    }
  }
  f.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return f;
}
