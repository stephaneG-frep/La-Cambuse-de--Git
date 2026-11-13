import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

Set<String> rules(String kind, String content) => lintLabFile(kind, content).map((f) => f.rule).toSet();

void main() {
  test('chaque type de labo a un nom de fichier et un analyseur', () {
    for (final k in labFileNames.keys) {
      expect(() => lintLabFile(k, ''), returnsNormally, reason: k);
    }
    expect(rules('inconnu', 'x'), {'XX000'});
  });

  test('contenu invalide → règle « 000 » bloquante', () {
    for (final (k, c) in [
      ('shell', ''), ('sshd', 'PermitRootLogin'), ('nginx', 'server {'), ('workflow', 'a: ['), ('gitlabci', 'x'),
      ('k8s', 'a: ['), ('terraform', 'resource "x" "y" {'), ('ansible', 'hosts: web'), ('alerts', 'x: 1'),
    ]) {
      expect(lintInvalid(lintLabFile(k, c)), isTrue, reason: k);
    }
  });

  group('Bash', () {
    test('détecte mode strict, guillemets, rm dangereux, curl | sh, secret', () {
      final r = rules('shell', 'D=\$1\nrm -rf \$D/cache\ncurl -fsSL https://x.org/i.sh | bash\nchmod 777 f\nTOKEN=abcd1234efgh\n');
      expect(r, containsAll(['SH001', 'SH002', 'SH003', 'SH004', 'SH005', 'SH006', 'SH010']));
    });
    test('script propre : aucun constat', () {
      expect(rules('shell', '#!/usr/bin/env bash\nset -euo pipefail\nD="\${1:?}"\nrm -rf -- "\${D:?}/cache"\necho "fin \$D"\n'), isEmpty);
    });
    test('la valeur du secret n\'est jamais recopiée', () {
      final f = lintLabFile('shell', '#!/bin/bash\nset -euo pipefail\nAPI_TOKEN=tresSecret999\n');
      expect(f.map((x) => '${x.message} ${x.fix}').join(), isNot(contains('tresSecret999')));
    });
  });

  test('sshd : root, mots de passe, directives avec chiffres', () {
    expect(rules('sshd', 'PermitRootLogin yes\nX11Forwarding yes\n'), containsAll(['SS001', 'SS002', 'SS004']));
    expect(rules('sshd', 'PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nAllowUsers deploy\n'), isEmpty);
  });

  test('nginx : TLS obsolète, HSTS, redirection, listage', () {
    final bad = 'server { listen 80; autoindex on; }\nserver { listen 443 ssl; ssl_protocols TLSv1 TLSv1.2; }\n';
    expect(rules('nginx', bad), containsAll(['NG001', 'NG002', 'NG003', 'NG004', 'NG006']));
    const good = 'server { listen 80; server_tokens off; return 301 https://\$host\$request_uri; }\n'
        'server { listen 443 ssl; server_tokens off; ssl_protocols TLSv1.2 TLSv1.3;\n'
        ' add_header Strict-Transport-Security "max-age=31536000" always;\n add_header X-Content-Type-Options nosniff always; }\n';
    expect(rules('nginx', good), isEmpty);
  });

  group('GitHub Actions', () {
    test('détecte étiquettes mobiles, injection, pull_request_target, secret affiché', () {
      const bad = 'on:\n  pull_request_target:\npermissions: write-all\njobs:\n  t:\n    runs-on: x\n    steps:\n      - uses: actions/checkout@v4\n'
          '      - run: echo "\${{ github.event.issue.title }}"\n      - run: echo \${{ secrets.T }}\n';
      expect(rules('workflow', bad), containsAll(['GH001', 'GH003', 'GH004', 'GH005', 'GH006', 'GH007', 'GH008']));
    });
    test('les modèles CI générés par La Cambuse passent sans avertissement', () {
      for (final kind in ciTemplateKinds) {
        final f = lintLabFile('workflow', ciTemplate(kind, 'github')!);
        expect(f.where((x) => x.severity != LintSeverity.info), isEmpty, reason: '$kind : ${f.map((x) => x.rule)}');
      }
    });
  });

  test('GitLab CI : la recette peut se déployer seule, pas la production', () {
    const ci = 'deploy_staging:\n  image: alpine:3.20\n  environment:\n    name: staging\n  script: [./d.sh]\n'
        'deploy_prod:\n  image: alpine:3.20\n  environment:\n    name: production\n  script: [./d.sh]\n';
    final f = lintLabFile('gitlabci', ci).where((x) => x.rule == 'GL003').toList();
    expect(f, hasLength(1));
    expect(f.single.message, startsWith('deploy_prod'));
  });

  test('Kubernetes : documents multiples, Secret versionné, LoadBalancer', () {
    const y = 'apiVersion: v1\nkind: Secret\nmetadata: {name: s}\nstringData: {a: b}\n---\n'
        'apiVersion: v1\nkind: Service\nmetadata: {name: s}\nspec: {type: LoadBalancer}\n---\n'
        'apiVersion: v1\nkind: Pod\nmetadata: {name: p}\nspec:\n  hostNetwork: true\n  containers:\n    - name: c\n      image: nginx\n      securityContext: {privileged: true}\n'
        '      env:\n        - name: DB_PASSWORD\n          value: "abcdef123"\n';
    expect(rules('k8s', y), containsAll(['K8001', 'K8002', 'K8003', 'K8004', 'K8008', 'K8009', 'K8012', 'K8014']));
  });

  test('Terraform : SSH ouvert seulement si la règle 22 est publique', () {
    String sg(String cidr22) => 'resource "aws_security_group" "w" {\n  ingress {\n    from_port = 22\n    cidr_blocks = ["$cidr22"]\n  }\n'
        '  ingress {\n    from_port = 443\n    cidr_blocks = ["0.0.0.0/0"]\n  }\n}\n';
    expect(rules('terraform', sg('0.0.0.0/0')), contains('TF004'));
    expect(rules('terraform', sg('203.0.113.10/32')), isNot(contains('TF004')));
    expect(rules('terraform', 'variable "db_password" {\n  type = string\n}\nresource "x" "y" {\n  password = "abcdefgh"\n}\n'),
        containsAll(['TF001', 'TF003', 'TF005', 'TF006']));
  });

  test('Ansible : shell au lieu du module, secrets, ignore_errors', () {
    const p = '- hosts: web\n  vars:\n    db_password: "abcdef123"\n  tasks:\n    - ansible.builtin.shell: apt-get install -y nginx\n'
        '    - name: u\n      ansible.builtin.user:\n        name: app\n        password: "{{ x }}"\n      ignore_errors: true\n';
    expect(rules('ansible', p), containsAll(['AN001', 'AN002', 'AN003', 'AN004', 'AN006']));
  });

  test('Alertes Prometheus : for, sévérité, résumé, runbook', () {
    const a = 'groups:\n  - name: g\n    rules:\n      - record: x\n        expr: up\n      - alert: A\n        expr: up == 0\n';
    expect(rules('alerts', a), {'PR001', 'PR002', 'PR003', 'PR004'});
  });
}
