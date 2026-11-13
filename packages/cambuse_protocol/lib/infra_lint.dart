/// Analyseurs statiques hors ligne pour les labos de l'Académie avancée :
/// scripts Bash, sshd_config, nginx, GitHub Actions, GitLab CI, manifestes
/// Kubernetes, Terraform/OpenTofu, playbooks Ansible et règles d'alerte
/// Prometheus. Heuristiques pédagogiques : elles ne remplacent ni shellcheck,
/// ni kube-linter, ni tflint, ni ansible-lint. Rien n'est exécuté.
library;

import 'package:yaml/yaml.dart';

import 'docker_lint.dart';

/// Types de fichiers de labo et nom de fichier affiché.
const labFileNames = <String, String>{
  'dockerfile': 'Dockerfile',
  'compose': 'compose.yaml',
  'shell': 'script.sh',
  'sshd': 'sshd_config',
  'nginx': 'nginx.conf',
  'workflow': '.github/workflows/ci.yml',
  'gitlabci': '.gitlab-ci.yml',
  'k8s': 'manifeste.yaml',
  'terraform': 'main.tf',
  'ansible': 'playbook.yml',
  'alerts': 'alertes.yml',
};

/// Analyse un fichier de labo selon son type.
List<LintFinding> lintLabFile(String kind, String content) {
  final f = switch (kind) {
    'dockerfile' => lintDockerfile(content),
    'compose' => lintCompose(content),
    'shell' => lintShell(content),
    'sshd' => lintSshd(content),
    'nginx' => lintNginx(content),
    'workflow' => lintWorkflow(content),
    'gitlabci' => lintGitlabCi(content),
    'k8s' => lintKubernetes(content),
    'terraform' => lintTerraform(content),
    'ansible' => lintAnsible(content),
    'alerts' => lintAlertRules(content),
    _ => [LintFinding('XX000', LintSeverity.blocking, 'Type de fichier inconnu : $kind')],
  };
  return f..sort((a, b) => a.severity.index.compareTo(b.severity.index));
}

/// Vrai si l'analyse a jugé le fichier invalide (règle « …000 »).
bool lintInvalid(List<LintFinding> f) => f.any((x) => x.rule.endsWith('000'));

final _secretKey = RegExp(r'(pass(word|wd)?|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credentials?)', caseSensitive: false);

bool _literalSecret(Object? key, Object? value) {
  if (!_secretKey.hasMatch('$key') || value == null) return false;
  final v = '$value'.trim();
  if (v.isEmpty || v.length < 4) return false;
  return !(v.startsWith(r'$') || v.contains('{{') || v.contains(r'${') || v.startsWith('!vault') || v.startsWith('<'));
}

LintFinding _yamlError(String rule, YamlException e) =>
    LintFinding(rule, LintSeverity.blocking, 'YAML invalide : ${e.message}', line: e.span == null ? null : e.span!.start.line + 1);

int? _line(Object? node) => node is YamlNode ? node.span.start.line + 1 : null;

// ============================================================== Bash (SH)

final _curlPipe = RegExp(r'(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b');

List<LintFinding> lintShell(String content) {
  final f = <LintFinding>[];
  final lines = content.split('\n');
  if (content.trim().isEmpty) return [const LintFinding('SH000', LintSeverity.blocking, 'Script vide.')];
  if (!lines.first.startsWith('#!')) {
    f.add(const LintFinding('SH001', LintSeverity.warning, 'Pas de shebang : l\'interpréteur dépend de qui lance le script.',
        line: 1, fix: 'Première ligne : #!/usr/bin/env bash'));
  }
  final strict = lines.any((l) {
    final m = RegExp(r'^\s*set\s+-([a-zA-Z]+)').firstMatch(l);
    final flags = m?.group(1) ?? '';
    final long = l.contains('errexit') && l.contains('nounset');
    return ((flags.contains('e') && flags.contains('u')) || long) && l.contains('pipefail');
  });
  if (!strict) {
    f.add(const LintFinding('SH002', LintSeverity.warning,
        'Mode strict absent : une commande qui échoue n\'arrête pas le script, une variable vide passe inaperçue.',
        fix: 'Ajoutez « set -euo pipefail » après le shebang.'));
  }
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final l = raw.trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    final n = i + 1;
    // Retire les chaînes entre guillemets pour repérer les expansions non protégées.
    final unquoted = l.replaceAll(RegExp(r'"(\\.|[^"\\])*"'), '""').replaceAll(RegExp(r"'[^']*'"), "''");
    final rmVar = RegExp(r'\brm\s+-[a-zA-Z]*r[a-zA-Z]*\s+.*\$').hasMatch(l) && !l.contains(':?');
    if (rmVar) {
      f.add(LintFinding('SH004', LintSeverity.blocking, 'rm -r sur une variable non protégée : si elle est vide, la cible devient « / » ou le dossier courant.',
          line: n, fix: 'Écrivez rm -rf -- "\${DOSSIER:?}/…" : le script s\'arrête si la variable est vide.'));
    }
    final isAssignment = RegExp(r'^(local\s+|export\s+|readonly\s+)?[A-Za-z_][A-Za-z0-9_]*=\S*$').hasMatch(l);
    final inTest = unquoted.contains('[[');
    if (!isAssignment && !inTest && RegExp(r'(^|[\s=(/:])\$(\{?[A-Za-z_@*][A-Za-z0-9_]*\}?|[0-9])').hasMatch(unquoted) &&
        !unquoted.contains(r'$((')) {
      f.add(LintFinding('SH003', LintSeverity.warning, 'Variable non entourée de guillemets : un espace ou un joker la découpe en plusieurs arguments.',
          line: n, fix: 'Écrivez "\$variable" entre guillemets doubles.'));
    }
    if (_curlPipe.hasMatch(l)) {
      f.add(LintFinding('SH005', LintSeverity.blocking, 'Script distant exécuté directement (curl | sh), sans vérification.',
          line: n, fix: 'Téléchargez dans un fichier, vérifiez sa somme SHA-256, puis exécutez-le.'));
    }
    if (RegExp(r'\bchmod\s+(-R\s+)?0?777\b').hasMatch(l)) {
      f.add(LintFinding('SH006', LintSeverity.warning, 'chmod 777 : tout le monde peut modifier (et exécuter) ces fichiers.',
          line: n, fix: 'Donnez le minimum : 755 pour un exécutable, 644 pour un fichier, 600 pour un secret.'));
    }
    if (RegExp(r'(^|[;&|]\s*)eval\s').hasMatch(l)) {
      f.add(LintFinding('SH007', LintSeverity.warning, 'eval exécute du texte comme du code : injection possible.',
          line: n, fix: 'Utilisez un tableau ("\${args[@]}") ou un case.'));
    }
    if (unquoted.contains('`')) {
      f.add(LintFinding('SH008', LintSeverity.info, 'Accents graves obsolètes pour la substitution de commande.',
          line: n, fix: 'Préférez \$(commande), imbriquable et lisible.'));
    }
    if (!strict && RegExp(r'^cd\s').hasMatch(l) && !l.contains('||')) {
      f.add(LintFinding('SH009', LintSeverity.warning, 'cd sans vérification : en cas d\'échec, la suite s\'exécute dans le mauvais dossier.',
          line: n, fix: 'cd "\$dossier" || exit 1 (ou activez set -e).'));
    }
    final secret = RegExp(r'''^(export\s+)?([A-Za-z_]*(PASS|PASSWORD|TOKEN|SECRET|API_KEY)[A-Za-z_]*)=["']?([^"'\s$][^"'\s]{3,})''', caseSensitive: false)
        .firstMatch(l);
    if (secret != null) {
      f.add(LintFinding('SH010', LintSeverity.blocking, 'Secret écrit en dur dans ${secret.group(2)} (valeur masquée).',
          line: n, fix: 'Lisez-le depuis l\'environnement : : "\${${secret.group(2)}:?variable requise}".'));
    }
    if (RegExp(r'(^|[;&|]\s*)sudo\s').hasMatch(l)) {
      f.add(LintFinding('SH011', LintSeverity.info, 'sudo dans un script : il demandera un mot de passe ou élèvera tout le script.',
          line: n, fix: 'Lancez le script avec les droits nécessaires, ou limitez sudo à une commande précise documentée.'));
    }
  }
  return f;
}

// ======================================================= sshd_config (SS)

List<LintFinding> lintSshd(String content) {
  final f = <LintFinding>[];
  final values = <String, (String, int)>{};
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    if (RegExp(r'^Match\s', caseSensitive: false).hasMatch(l)) break; // seuls les réglages globaux
    final m = RegExp(r'^([A-Za-z][A-Za-z0-9]*)\s+(.+)$').firstMatch(l);
    if (m == null) {
      f.add(LintFinding('SS000', LintSeverity.blocking, 'Ligne invalide : « $l » (attendu : Directive valeur).', line: i + 1));
      continue;
    }
    values.putIfAbsent(m.group(1)!.toLowerCase(), () => (m.group(2)!.trim().toLowerCase(), i + 1));
  }
  (String, int)? v(String k) => values[k.toLowerCase()];
  if (v('PermitRootLogin')?.$1 == 'yes') {
    f.add(LintFinding('SS001', LintSeverity.blocking, 'Connexion root autorisée.', line: v('PermitRootLogin')!.$2,
        fix: 'PermitRootLogin no (connectez-vous avec un compte nominatif puis sudo).'));
  }
  final pwd = v('PasswordAuthentication');
  if (pwd == null || pwd.$1 == 'yes') {
    f.add(LintFinding('SS002', LintSeverity.warning, 'Authentification par mot de passe active${pwd == null ? ' (valeur par défaut)' : ''} : exposée au bourrage d\'identifiants.',
        line: pwd?.$2, fix: 'PasswordAuthentication no, après avoir installé votre clé publique.'));
  }
  if (v('PermitEmptyPasswords')?.$1 == 'yes') {
    f.add(LintFinding('SS003', LintSeverity.blocking, 'Mots de passe vides acceptés.', line: v('PermitEmptyPasswords')!.$2, fix: 'PermitEmptyPasswords no'));
  }
  if (v('X11Forwarding')?.$1 == 'yes') {
    f.add(LintFinding('SS004', LintSeverity.info, 'Redirection X11 active : inutile sur un serveur.', line: v('X11Forwarding')!.$2, fix: 'X11Forwarding no'));
  }
  final tries = int.tryParse(v('MaxAuthTries')?.$1 ?? '');
  if (tries != null && tries > 4) {
    f.add(LintFinding('SS005', LintSeverity.warning, 'MaxAuthTries $tries : trop d\'essais par connexion.', line: v('MaxAuthTries')!.$2, fix: 'MaxAuthTries 3'));
  }
  if (v('AllowUsers') == null && v('AllowGroups') == null) {
    f.add(const LintFinding('SS006', LintSeverity.info, 'Aucune liste d\'utilisateurs autorisés.', fix: 'AllowUsers deploy (ou AllowGroups ssh-users).'));
  }
  for (final k in ['KbdInteractiveAuthentication', 'ChallengeResponseAuthentication']) {
    if (v(k)?.$1 == 'yes') {
      f.add(LintFinding('SS007', LintSeverity.warning, '$k active : contourne la désactivation des mots de passe.', line: v(k)!.$2, fix: '$k no'));
    }
  }
  return f;
}

// ============================================================= nginx (NG)

List<LintFinding> lintNginx(String content) {
  final f = <LintFinding>[];
  final code = content.split('\n').map((l) => l.contains('#') ? l.substring(0, l.indexOf('#')) : l).join('\n');
  if ('{'.allMatches(code).length != '}'.allMatches(code).length) {
    return [const LintFinding('NG000', LintSeverity.blocking, 'Accolades déséquilibrées : configuration invalide.')];
  }
  int? lineOf(Pattern p) {
    final idx = code.indexOf(p);
    return idx < 0 ? null : '\n'.allMatches(code.substring(0, idx)).length + 1;
  }
  if (!RegExp(r'server_tokens\s+off\s*;').hasMatch(code)) {
    f.add(const LintFinding('NG001', LintSeverity.warning, 'La version de nginx est annoncée dans les en-têtes et pages d\'erreur.', fix: 'server_tokens off;'));
  }
  final protocols = RegExp(r'ssl_protocols\s+([^;]+);').firstMatch(code);
  if (protocols != null && RegExp(r'\b(SSLv2|SSLv3|TLSv1|TLSv1\.1)\b').hasMatch(protocols.group(1)!.replaceAll(RegExp(r'TLSv1\.[23]'), ''))) {
    f.add(LintFinding('NG002', LintSeverity.blocking, 'Protocoles obsolètes autorisés : ${protocols.group(1)!.trim()}.',
        line: lineOf('ssl_protocols'), fix: 'ssl_protocols TLSv1.2 TLSv1.3;'));
  }
  final https = RegExp(r'listen\s+[^;]*443[^;]*ssl').hasMatch(code);
  if (https && !code.contains('Strict-Transport-Security')) {
    f.add(const LintFinding('NG003', LintSeverity.warning, 'HTTPS sans HSTS : un attaquant peut forcer un premier accès en HTTP.',
        fix: 'add_header Strict-Transport-Security "max-age=31536000" always;'));
  }
  if (https && RegExp(r'listen\s+(\[::\]:)?80\b').hasMatch(code) && !RegExp(r'return\s+301\s+https').hasMatch(code)) {
    f.add(LintFinding('NG004', LintSeverity.warning, 'Le port 80 sert du contenu au lieu de rediriger vers HTTPS.',
        line: lineOf(RegExp(r'listen\s+(\[::\]:)?80\b')), fix: 'Dans le server du port 80 : return 301 https://\$host\$request_uri;'));
  }
  if (!code.contains('X-Content-Type-Options')) {
    f.add(const LintFinding('NG005', LintSeverity.info, 'En-tête X-Content-Type-Options absent.', fix: 'add_header X-Content-Type-Options nosniff always;'));
  }
  if (RegExp(r'autoindex\s+on').hasMatch(code)) {
    f.add(LintFinding('NG006', LintSeverity.warning, 'autoindex on : le contenu des dossiers est listé publiquement.', line: lineOf('autoindex'), fix: 'autoindex off;'));
  }
  return f;
}

// ==================================================== GitHub Actions (GH)

final _sha = RegExp(r'@[0-9a-f]{40}$');

List<LintFinding> lintWorkflow(String content) {
  final YamlNode doc;
  try {
    doc = loadYamlNode(content);
  } on YamlException catch (e) {
    return [_yamlError('GH000', e)];
  }
  if (doc is! YamlMap || doc['jobs'] is! YamlMap) {
    return [const LintFinding('GH000', LintSeverity.blocking, 'Aucune section « jobs » : workflow incomplet.')];
  }
  final f = <LintFinding>[];
  final on = doc['on'] ?? doc[true]; // « on » est lu comme booléen par certains analyseurs YAML 1.1
  final triggers = on is Map ? on.keys.map((k) => '$k').toSet() : on is List ? on.map((e) => '$e').toSet() : {'$on'};
  final perms = doc['permissions'];
  if (perms == 'write-all') {
    f.add(LintFinding('GH003', LintSeverity.blocking, 'permissions: write-all donne tous les droits au jeton du workflow.',
        line: _line(doc.nodes['permissions']), fix: 'permissions: { contents: read } puis élargissez job par job.'));
  }
  final jobs = doc['jobs'] as YamlMap;
  if (perms == null && jobs.values.any((j) => j is Map && j['permissions'] == null)) {
    f.add(const LintFinding('GH002', LintSeverity.warning, 'Aucune permission déclarée : le jeton reçoit les droits par défaut du dépôt.',
        fix: 'Ajoutez en tête : permissions: { contents: read }'));
  }
  var checkout = false;
  for (final entry in jobs.nodes.entries) {
    final name = '${(entry.key as YamlNode).value}';
    final job = entry.value;
    if (job is! YamlMap) continue;
    final jl = _line(entry.key);
    if (job['permissions'] == 'write-all') {
      f.add(LintFinding('GH003', LintSeverity.blocking, '$name : permissions: write-all.', line: jl, fix: 'Listez seulement les droits utiles.'));
    }
    if (job['timeout-minutes'] == null && job['uses'] == null) {
      f.add(LintFinding('GH006', LintSeverity.info, '$name : pas de timeout-minutes (6 h par défaut).', line: jl, fix: 'timeout-minutes: 15'));
    }
    final steps = job.nodes['steps'];
    if (steps is! YamlList) continue;
    for (final s in steps.nodes) {
      if (s is! YamlMap) continue;
      final sl = _line(s);
      final uses = s['uses'];
      if (uses is String) {
        if (!uses.startsWith('./') && !uses.startsWith('docker://') && !_sha.hasMatch(uses.split(' ').first)) {
          f.add(LintFinding('GH001', LintSeverity.warning, '$name : action « $uses » référencée par une étiquette mobile.',
              line: sl, fix: 'Épinglez par empreinte de commit : action@<sha40> # vX.Y.Z'));
        }
        if (uses.startsWith('actions/checkout')) {
          checkout = true;
          final w = s['with'];
          if (w is! Map || w['persist-credentials'] != false) {
            f.add(LintFinding('GH007', LintSeverity.info, '$name : checkout conserve le jeton dans .git/config.',
                line: sl, fix: 'with: { persist-credentials: false }'));
          }
        }
      }
      final run = s['run'];
      if (run is String) {
        if (RegExp(r'\$\{\{\s*github\.(event\.(issue|pull_request|comment|review|head_commit|commits)|head_ref)').hasMatch(run)) {
          f.add(LintFinding('GH005', LintSeverity.blocking,
              '$name : donnée contrôlée par un tiers (titre, branche, message) insérée dans run : injection de commandes.',
              line: sl, fix: 'Passez-la par env: (TITRE: \${{ github.event.issue.title }}) puis utilisez "\$TITRE".'));
        }
        if (RegExp(r'\b(echo|printf)\b[^\n]*\$\{\{\s*secrets\.').hasMatch(run)) {
          f.add(LintFinding('GH008', LintSeverity.blocking, '$name : un secret est affiché dans les journaux.',
              line: sl, fix: 'N\'affichez jamais un secret ; passez-le par env: au seul outil qui en a besoin.'));
        }
      }
    }
  }
  if (triggers.contains('pull_request_target') && checkout) {
    f.add(const LintFinding('GH004', LintSeverity.blocking,
        'pull_request_target avec checkout : le code d\'une PR externe s\'exécute avec les secrets du dépôt.',
        fix: 'Utilisez pull_request (sans secrets) pour construire et tester le code des contributeurs.'));
  }
  return f;
}

// ========================================================= GitLab CI (GL)

const _gitlabKeywords = {'stages', 'variables', 'default', 'include', 'workflow', 'image', 'services', 'cache', 'before_script', 'after_script'};

List<LintFinding> lintGitlabCi(String content) {
  final YamlNode doc;
  try {
    doc = loadYamlNode(content);
  } on YamlException catch (e) {
    return [_yamlError('GL000', e)];
  }
  if (doc is! YamlMap) return [const LintFinding('GL000', LintSeverity.blocking, 'Fichier vide ou non structuré.')];
  final f = <LintFinding>[];
  void image(Object? img, String where, int? line) {
    final s = img is Map ? '${img['name']}' : img is String ? img : null;
    if (s == null) return;
    final tag = s.contains(':') ? s.substring(s.lastIndexOf(':') + 1) : null;
    if (!s.contains('@sha256:') && (tag == null || tag == 'latest')) {
      f.add(LintFinding('GL001', LintSeverity.warning, '$where : image « $s » sans version fixe.', line: line, fix: 'Épinglez, ex. node:22.11-slim.'));
    }
  }
  void variables(Object? vars, String where, int? line) {
    if (vars is! Map) return;
    vars.forEach((k, v) {
      final value = v is Map ? v['value'] : v;
      if (_literalSecret(k, value)) {
        f.add(LintFinding('GL002', LintSeverity.blocking, '$where : secret en clair dans $k (valeur masquée).',
            line: line, fix: 'Déclarez-le dans Paramètres → CI/CD → Variables, masqué et protégé.'));
      }
    });
  }
  image(doc['image'], 'global', _line(doc.nodes['image']));
  variables(doc['variables'], 'global', _line(doc.nodes['variables']));
  if (doc['default'] is Map) image((doc['default'] as Map)['image'], 'default', _line(doc.nodes['default']));
  var jobs = 0;
  for (final entry in doc.nodes.entries) {
    final name = '${(entry.key as YamlNode).value}';
    if (_gitlabKeywords.contains(name) || name.startsWith('.')) continue;
    final job = entry.value;
    if (job is! YamlMap) continue;
    jobs++;
    final jl = _line(entry.key);
    image(job['image'], name, jl);
    variables(job['variables'], name, jl);
    final env = job['environment'];
    final target = '$name ${env is Map ? env['name'] : env ?? ''}';
    // La recette (staging) peut se déployer automatiquement ; la production non.
    final deploy = RegExp(r'prod|live|release', caseSensitive: false).hasMatch(target);
    final rules = '${job['rules'] ?? ''}';
    if (deploy && job['when'] != 'manual' && !rules.contains('manual')) {
      f.add(LintFinding('GL003', LintSeverity.warning, '$name : déploiement lancé automatiquement, sans validation humaine.',
          line: jl, fix: 'Ajoutez when: manual (ou rules: avec when: manual) et un environment protégé.'));
    }
    final art = job['artifacts'];
    if (art is Map && art['expire_in'] == null) {
      f.add(LintFinding('GL004', LintSeverity.info, '$name : artefacts conservés indéfiniment.', line: jl, fix: 'expire_in: 1 week'));
    }
    final script = job['script'];
    final lines = script is List ? script.map((e) => '$e') : [if (script != null) '$script'];
    if (lines.any(_curlPipe.hasMatch)) {
      f.add(LintFinding('GL005', LintSeverity.blocking, '$name : script distant exécuté sans vérification (curl | sh).',
          line: jl, fix: 'Téléchargez, vérifiez la somme SHA-256, puis exécutez.'));
    }
    if (script == null && job['trigger'] == null && job['extends'] == null) {
      f.add(LintFinding('GL000', LintSeverity.blocking, '$name : job sans script.', line: jl));
    }
  }
  if (jobs == 0) f.add(const LintFinding('GL000', LintSeverity.blocking, 'Aucun job défini.'));
  return f;
}

// ======================================================== Kubernetes (K8)

const _workloads = {'Deployment', 'StatefulSet', 'DaemonSet', 'ReplicaSet', 'Job', 'CronJob', 'Pod'};

List<LintFinding> lintKubernetes(String content) {
  final List<YamlDocument> docs;
  try {
    docs = loadYamlDocuments(content);
  } on YamlException catch (e) {
    return [_yamlError('K8000', e)];
  }
  final f = <LintFinding>[];
  var seen = 0;
  for (final d in docs) {
    final m = d.contents;
    if (m is! YamlMap) continue;
    final kind = m['kind'];
    if (kind is! String || m['apiVersion'] == null) {
      f.add(LintFinding('K8000', LintSeverity.blocking, 'Document sans apiVersion ou kind.', line: _line(m)));
      continue;
    }
    seen++;
    final name = '${(m['metadata'] as Map?)?['name'] ?? kind}';
    final line = _line(m.nodes['kind']);
    if (kind == 'Secret' && (m['data'] != null || m['stringData'] != null)) {
      f.add(LintFinding('K8014', LintSeverity.warning, '$name : Secret en clair dans le manifeste (base64 n\'est pas un chiffrement).',
          line: line, fix: 'Ne versionnez pas ce fichier : kubectl create secret, Sealed Secrets ou External Secrets.'));
    }
    if (kind == 'Service' && ['LoadBalancer', 'NodePort'].contains((m['spec'] as Map?)?['type'])) {
      f.add(LintFinding('K8012', LintSeverity.info, '$name : Service ${(m['spec'] as Map)['type']} exposé hors du cluster.',
          line: line, fix: 'Préférez ClusterIP derrière un Ingress, sauf besoin explicite.'));
    }
    if (!_workloads.contains(kind)) continue;
    Map? spec = m['spec'] as Map?;
    if (kind == 'Deployment' || kind == 'StatefulSet') {
      final replicas = spec?['replicas'];
      if (replicas is int && replicas < 2) {
        f.add(LintFinding('K8013', LintSeverity.info, '$name : une seule réplique, aucune tolérance à la panne.', line: line, fix: 'replicas: 2 (ou plus) et un PodDisruptionBudget.'));
      }
    }
    if (kind == 'CronJob') spec = ((spec?['jobTemplate'] as Map?)?['spec'] as Map?);
    final pod = kind == 'Pod' ? spec : ((spec?['template'] as Map?)?['spec'] as Map?);
    if (pod == null) {
      f.add(LintFinding('K8000', LintSeverity.blocking, '$name : spécification de pod introuvable.', line: line));
      continue;
    }
    final podSec = (pod['securityContext'] as Map?) ?? const {};
    if (pod['hostNetwork'] == true || pod['hostPID'] == true || pod['hostIPC'] == true) {
      f.add(LintFinding('K8009', LintSeverity.blocking, '$name : partage du réseau ou des processus de l\'hôte.', line: line, fix: 'Retirez hostNetwork, hostPID et hostIPC.'));
    }
    for (final v in (pod['volumes'] as List?) ?? const []) {
      if (v is Map && v['hostPath'] != null) {
        f.add(LintFinding('K8010', LintSeverity.warning, '$name : volume hostPath « ${v['name']} » : accès au disque du nœud.', line: line, fix: 'Utilisez un PersistentVolumeClaim ou emptyDir.'));
      }
    }
    for (final c in (pod['containers'] as List?) ?? const []) {
      if (c is! Map) continue;
      final cn = '$name/${c['name']}';
      final line = _line(c) ?? _line(m.nodes['kind']); // ligne du conteneur concerné
      final image = '${c['image'] ?? ''}';
      final tag = image.contains(':') ? image.substring(image.lastIndexOf(':') + 1) : null;
      if (!image.contains('@sha256:') && (tag == null || tag == 'latest')) {
        f.add(LintFinding('K8001', LintSeverity.warning, '$cn : image « $image » sans version fixe.', line: line, fix: 'Épinglez une version (ou un digest).'));
      }
      final res = c['resources'] as Map?;
      if (res?['limits'] == null || res?['requests'] == null) {
        f.add(LintFinding('K8002', LintSeverity.warning, '$cn : requests/limits absents : le conteneur peut affamer le nœud.',
            line: line, fix: 'resources: { requests: { cpu: 100m, memory: 128Mi }, limits: { memory: 256Mi } }'));
      }
      final sec = (c['securityContext'] as Map?) ?? const {};
      if (sec['runAsNonRoot'] != true && podSec['runAsNonRoot'] != true) {
        f.add(LintFinding('K8003', LintSeverity.warning, '$cn : peut tourner en root.', line: line, fix: 'securityContext: { runAsNonRoot: true, runAsUser: 10001 }'));
      }
      if (sec['privileged'] == true) {
        f.add(LintFinding('K8004', LintSeverity.blocking, '$cn : conteneur privilégié (accès total au nœud).', line: line, fix: 'Retirez privileged: true.'));
      }
      if (sec['allowPrivilegeEscalation'] != false) {
        f.add(LintFinding('K8005', LintSeverity.warning, '$cn : élévation de privilèges non interdite.', line: line, fix: 'allowPrivilegeEscalation: false'));
      }
      if (sec['readOnlyRootFilesystem'] != true) {
        f.add(LintFinding('K8011', LintSeverity.info, '$cn : système de fichiers racine modifiable.', line: line, fix: 'readOnlyRootFilesystem: true (+ emptyDir pour /tmp).'));
      }
      if (kind != 'Job' && kind != 'CronJob') {
        if (c['readinessProbe'] == null) {
          f.add(LintFinding('K8006', LintSeverity.info, '$cn : pas de readinessProbe : du trafic arrive avant que l\'application soit prête.',
              line: line, fix: 'readinessProbe: { httpGet: { path: /sante, port: 8080 } }'));
        }
        if (c['livenessProbe'] == null) {
          f.add(LintFinding('K8007', LintSeverity.info, '$cn : pas de livenessProbe : un processus bloqué n\'est pas redémarré.', line: line));
        }
      }
      for (final e in (c['env'] as List?) ?? const []) {
        if (e is Map && _literalSecret(e['name'], e['value'])) {
          f.add(LintFinding('K8008', LintSeverity.blocking, '$cn : secret en clair dans la variable ${e['name']} (valeur masquée).',
              line: line, fix: 'valueFrom: { secretKeyRef: { name: …, key: … } }'));
        }
      }
    }
  }
  if (seen == 0 && f.isEmpty) f.add(const LintFinding('K8000', LintSeverity.blocking, 'Aucun objet Kubernetes trouvé.'));
  return f;
}

// =================================================== Terraform/OpenTofu (TF)

/// Blocs de premier niveau : (en-tête, corps, ligne).
List<(String, String, int)> _hclBlocks(String code) {
  final out = <(String, String, int)>[];
  var depth = 0;
  var start = -1;
  var header = '';
  for (var i = 0; i < code.length; i++) {
    final ch = code[i];
    if (ch == '{') {
      if (depth == 0) {
        final ls = code.lastIndexOf('\n', i) + 1;
        header = code.substring(ls, i).trim();
        start = i;
      }
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0 && start >= 0) {
        out.add((header, code.substring(start + 1, i), '\n'.allMatches(code.substring(0, start)).length + 1));
        start = -1;
      }
    }
  }
  return out;
}

List<LintFinding> lintTerraform(String content) {
  final code = content.split('\n').map((l) {
    final t = l.trimLeft();
    return t.startsWith('#') || t.startsWith('//') ? '' : l;
  }).join('\n');
  if ('{'.allMatches(code).length != '}'.allMatches(code).length) {
    return [const LintFinding('TF000', LintSeverity.blocking, 'Accolades déséquilibrées : configuration invalide.')];
  }
  final blocks = _hclBlocks(code);
  if (blocks.isEmpty) return [const LintFinding('TF000', LintSeverity.blocking, 'Aucun bloc Terraform.')];
  final f = <LintFinding>[];
  final tf = blocks.where((b) => b.$1 == 'terraform').firstOrNull;
  if (tf == null || !tf.$2.contains('required_version')) {
    f.add(LintFinding('TF001', LintSeverity.warning, 'Version de Terraform/OpenTofu non contrainte.', line: tf?.$3,
        fix: 'terraform { required_version = ">= 1.6, < 2.0" }'));
  }
  final providers = blocks.where((b) => b.$1.startsWith('provider ')).toList();
  final rp = tf == null ? null : RegExp(r'required_providers\s*\{([\s\S]*)\}').firstMatch(tf.$2)?.group(1);
  if (providers.isNotEmpty && rp == null) {
    f.add(LintFinding('TF002', LintSeverity.warning, 'Fournisseurs utilisés sans required_providers : version imprévisible.',
        line: providers.first.$3, fix: 'required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }'));
  } else if (rp != null) {
    for (final m in RegExp(r'(\w+)\s*=\s*\{([^}]*)\}').allMatches(rp)) {
      if (!m.group(2)!.contains('version')) {
        f.add(LintFinding('TF002', LintSeverity.warning, 'Fournisseur « ${m.group(1)} » sans contrainte de version.', line: tf!.$3,
            fix: 'Ajoutez version = "~> X.Y".'));
      }
    }
  }
  final lines = code.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final m = RegExp(r'^\s*(\w*(password|secret|token|access_key|secret_key|api_key)\w*)\s*=\s*"([^"]*)"', caseSensitive: false).firstMatch(lines[i]);
    if (m != null && m.group(3)!.length >= 4 && !m.group(3)!.contains(r'${')) {
      f.add(LintFinding('TF003', LintSeverity.blocking, 'Secret écrit en dur dans ${m.group(1)} (valeur masquée) : il finira dans Git et dans l\'état.',
          line: i + 1, fix: 'Variable sensible (sensitive = true) alimentée par TF_VAR_… ou un gestionnaire de secrets.'));
    }
  }
  for (final b in blocks) {
    // Chaque règle d'entrée séparément : un bloc ingress, ou la ressource elle-même
    // pour les ressources « règle » à plat (aws_security_group_rule…).
    final ingress = _hclBlocks(b.$2).where((n) => n.$1.startsWith('ingress')).map((n) => n.$2).toList();
    final rules = ingress.isEmpty ? [b.$2] : ingress;
    if (b.$1.startsWith('resource ') &&
        rules.any((r) => RegExp(r'0\.0\.0\.0/0|"::/0"').hasMatch(r) && RegExp(r'(from_port|port)\s*=\s*(22|3389)\b').hasMatch(r))) {
      f.add(LintFinding('TF004', LintSeverity.blocking, '${b.$1} : SSH/RDP ouvert à tout Internet (0.0.0.0/0).',
          line: b.$3, fix: 'Restreignez cidr_blocks à votre adresse ou passez par un bastion/VPN.'));
    }
    if (RegExp(r'acl\s*=\s*"public-read(-write)?"').hasMatch(b.$2)) {
      f.add(LintFinding('TF007', LintSeverity.warning, '${b.$1} : stockage lisible publiquement.', line: b.$3, fix: 'acl = "private" et bloquez l\'accès public.'));
    }
    final v = RegExp(r'^variable\s+"(\w+)"').firstMatch(b.$1);
    if (v != null) {
      if (_secretKey.hasMatch(v.group(1)!) && !RegExp(r'sensitive\s*=\s*true').hasMatch(b.$2)) {
        f.add(LintFinding('TF005', LintSeverity.warning, 'Variable « ${v.group(1)} » non marquée sensible : sa valeur s\'affiche dans les plans.',
            line: b.$3, fix: 'sensitive = true'));
      }
      if (!b.$2.contains('type')) {
        f.add(LintFinding('TF008', LintSeverity.info, 'Variable « ${v.group(1)} » sans type.', line: b.$3, fix: 'type = string (ou number, list(string)…)'));
      }
    }
  }
  if (tf == null || !tf.$2.contains('backend ')) {
    f.add(const LintFinding('TF006', LintSeverity.info, 'État local : impossible à partager et sans verrouillage en équipe.',
        fix: 'Configurez un backend distant avec verrouillage (s3 avec use_lockfile, gcs, http…).'));
  }
  return f;
}

// =========================================================== Ansible (AN)

const _taskKeywords = {
  'name', 'when', 'become', 'become_user', 'register', 'loop', 'with_items', 'notify', 'tags', 'vars', 'no_log', 'ignore_errors',
  'changed_when', 'failed_when', 'until', 'retries', 'delay', 'environment', 'args', 'delegate_to', 'run_once', 'block', 'rescue',
  'always', 'listen', 'check_mode', 'diff', 'timeout', 'loop_control',
};
const _shellModules = {'shell', 'command', 'ansible.builtin.shell', 'ansible.builtin.command', 'raw', 'ansible.builtin.raw'};

List<LintFinding> lintAnsible(String content) {
  final YamlNode doc;
  try {
    doc = loadYamlNode(content);
  } on YamlException catch (e) {
    return [_yamlError('AN000', e)];
  }
  if (doc is! YamlList || doc.nodes.isEmpty) {
    return [const LintFinding('AN000', LintSeverity.blocking, 'Un playbook est une liste de plays (commençant par « - hosts: … »).')];
  }
  final f = <LintFinding>[];
  void vars(Object? v, int? line) {
    if (v is! Map) return;
    v.forEach((k, val) {
      if (_literalSecret(k, val)) {
        f.add(LintFinding('AN003', LintSeverity.blocking, 'Secret en clair dans la variable $k (valeur masquée).',
            line: line, fix: 'Chiffrez-le avec ansible-vault (ou lisez-le depuis un gestionnaire de secrets).'));
      }
    });
  }
  void tasks(Object? list) {
    if (list is! YamlList) return;
    for (final t in list.nodes) {
      if (t is! YamlMap) continue;
      final line = _line(t);
      final label = t['name'] == null ? 'tâche ligne $line' : '« ${t['name']} »';
      for (final nested in ['block', 'rescue', 'always']) {
        tasks(t.nodes[nested]);
      }
      if (t['block'] != null) continue;
      if (t['name'] == null) {
        f.add(LintFinding('AN001', LintSeverity.info, 'Tâche sans nom : le journal d\'exécution sera illisible.', line: line, fix: 'name: Installer nginx'));
      }
      vars(t['vars'], line);
      final module = t.keys.map((k) => '$k').where((k) => !_taskKeywords.contains(k)).firstOrNull;
      if (module == null) continue;
      final args = t[module];
      if (_shellModules.contains(module)) {
        final cmd = args is Map ? '${args['cmd'] ?? args['_raw_params'] ?? ''}' : '$args';
        final first = cmd.trim().split(RegExp(r'\s+')).first;
        final alt = const {
          'apt': 'ansible.builtin.apt', 'apt-get': 'ansible.builtin.apt', 'yum': 'ansible.builtin.dnf', 'dnf': 'ansible.builtin.dnf',
          'systemctl': 'ansible.builtin.systemd', 'service': 'ansible.builtin.service', 'mkdir': 'ansible.builtin.file',
          'chmod': 'ansible.builtin.file', 'chown': 'ansible.builtin.file', 'cp': 'ansible.builtin.copy', 'useradd': 'ansible.builtin.user',
        }[first];
        if (alt != null) {
          f.add(LintFinding('AN002', LintSeverity.warning, '$label : « $first » via $module au lieu du module dédié (non idempotent).',
              line: line, fix: 'Utilisez $alt.'));
        } else if (t['changed_when'] == null && !(args is Map && (args['creates'] != null || args['removes'] != null)) &&
            !(t['args'] is Map && ((t['args'] as Map)['creates'] != null || (t['args'] as Map)['removes'] != null))) {
          f.add(LintFinding('AN007', LintSeverity.info, '$label : commande toujours signalée « changed ».',
              line: line, fix: 'Ajoutez creates:/removes: ou changed_when:.'));
        }
      }
      if (args is Map) {
        if (args['state'] == 'latest') {
          f.add(LintFinding('AN005', LintSeverity.warning, '$label : state: latest met à jour sans contrôle à chaque exécution.',
              line: line, fix: 'state: present (et une version précise si nécessaire).'));
        }
        final secretArg = args.entries.where((e) => _secretKey.hasMatch('${e.key}')).firstOrNull;
        if (secretArg != null) {
          if (_literalSecret(secretArg.key, secretArg.value)) {
            f.add(LintFinding('AN003', LintSeverity.blocking, '$label : secret en clair dans ${secretArg.key} (valeur masquée).',
                line: line, fix: 'Utilisez une variable chiffrée par ansible-vault.'));
          }
          if (t['no_log'] != true) {
            f.add(LintFinding('AN004', LintSeverity.warning, '$label : manipule un secret sans no_log: true (il s\'affichera dans les journaux).',
                line: line, fix: 'no_log: true'));
          }
        }
      }
      if (t['ignore_errors'] == true) {
        f.add(LintFinding('AN006', LintSeverity.warning, '$label : ignore_errors masque les échecs.', line: line,
            fix: 'Traitez l\'erreur attendue avec failed_when: ou block/rescue.'));
      }
    }
  }
  for (final play in doc.nodes) {
    if (play is! YamlMap || play['hosts'] == null) {
      f.add(LintFinding('AN000', LintSeverity.blocking, 'Play sans « hosts ».', line: _line(play)));
      continue;
    }
    vars(play['vars'], _line(play.nodes['vars']));
    for (final k in ['pre_tasks', 'tasks', 'post_tasks', 'handlers']) {
      tasks(play.nodes[k]);
    }
  }
  return f;
}

// ============================================= Règles d'alerte Prometheus (PR)

List<LintFinding> lintAlertRules(String content) {
  final YamlNode doc;
  try {
    doc = loadYamlNode(content);
  } on YamlException catch (e) {
    return [_yamlError('PR000', e)];
  }
  if (doc is! YamlMap || doc['groups'] is! YamlList) {
    return [const LintFinding('PR000', LintSeverity.blocking, 'Section « groups » absente.')];
  }
  final f = <LintFinding>[];
  for (final g in (doc.nodes['groups'] as YamlList).nodes) {
    if (g is! YamlMap || g.nodes['rules'] is! YamlList) {
      f.add(LintFinding('PR000', LintSeverity.blocking, 'Groupe sans « rules ».', line: _line(g)));
      continue;
    }
    for (final r in (g.nodes['rules'] as YamlList).nodes) {
      if (r is! YamlMap || r['alert'] == null) continue; // règles d'enregistrement : hors périmètre
      final name = '${r['alert']}';
      final line = _line(r);
      if ('${r['expr'] ?? ''}'.trim().isEmpty) {
        f.add(LintFinding('PR005', LintSeverity.blocking, '$name : aucune expression.', line: line));
      }
      if (r['for'] == null) {
        f.add(LintFinding('PR001', LintSeverity.warning, '$name : pas de « for » : la moindre pointe déclenche une alerte (bruit).',
            line: line, fix: 'for: 5m'));
      }
      final labels = r['labels'];
      if (labels is! Map || labels['severity'] == null) {
        f.add(LintFinding('PR002', LintSeverity.warning, '$name : pas de labels.severity : impossible de router (page ou ticket).',
            line: line, fix: 'labels: { severity: page }'));
      }
      final ann = r['annotations'];
      if (ann is! Map || (ann['summary'] == null && ann['description'] == null)) {
        f.add(LintFinding('PR003', LintSeverity.info, '$name : pas de résumé pour la personne d\'astreinte.', line: line,
            fix: 'annotations: { summary: "…" }'));
      }
      if (ann is! Map || ann['runbook_url'] == null) {
        f.add(LintFinding('PR004', LintSeverity.info, '$name : pas de runbook : que doit faire l\'astreinte ?', line: line,
            fix: 'annotations: { runbook_url: https://… }'));
      }
    }
  }
  return f;
}
