import 'package:cambuse_protocol/cambuse_protocol.dart';
import 'package:test/test.dart';

Set<String> rules(List<LintFinding> f) => f.map((x) => x.rule).toSet();

void main() {
  group('Dockerfile', () {
    test('mauvais Dockerfile : toutes les règles attendues', () {
      final f = lintDockerfile('''
# commentaire
FROM node
WORKDIR app
ENV API_KEY=abcdef123456 DEBUG=1
ADD https://exemple.com/outil.sh /tmp/
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl
RUN curl -fsSL https://get.exemple.com | sh
COPY . .
RUN npm install && npm run build \\
    && chmod -R 777 /app
EXPOSE 22 3000
CMD node server.js
''');
      expect(rules(f), containsAll(['DF001', 'DF002', 'DF003', 'DF004', 'DF005', 'DF006', 'DF007', 'DF008', 'DF009', 'DF010', 'DF011', 'DF013', 'DF014', 'DF015']));
      expect(f.first.severity, LintSeverity.blocking, reason: 'tri par gravité');
      expect(f.map((x) => x.message).join(), isNot(contains('abcdef123456')), reason: 'valeur jamais recopiée');
      expect(f.firstWhere((x) => x.rule == 'DF015').line, 9, reason: 'ligne de début de l\'instruction continuée');
    });

    test('bon Dockerfile multi-étapes : seulement des infos éventuelles', () {
      final f = lintDockerfile('''
FROM node:22.11-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22.11-slim
WORKDIR /app
RUN useradd --create-home appli
COPY --from=build --chown=appli /app/dist ./dist
USER appli
HEALTHCHECK CMD node dist/health.js
CMD ["node", "dist/server.js"]
''');
      expect(f.where((x) => x.severity != LintSeverity.info), isEmpty, reason: f.map((x) => x.rule).join(','));
      expect(rules(f), isNot(contains('DF010')), reason: 'multi-étapes');
      expect(rules(f), isNot(contains('DF001')), reason: 'étape « build » référencée par son nom');
    });

    test('USER root en dernier, digest accepté, ARG secret par référence accepté', () {
      final f = lintDockerfile('FROM alpine@sha256:abc\nARG TOKEN=\$CI_TOKEN\nUSER appli\nUSER root\nCMD ["sh"]\n');
      expect(rules(f), contains('DF002'));
      expect(rules(f), isNot(contains('DF001')));
      expect(rules(f), isNot(contains('DF003')));
    });

    test('curl | sh détecté, mais pas la vérification « | sha256sum »', () {
      expect(rules(lintDockerfile('FROM a:1\nRUN curl -fsSL https://x | sh\nUSER u\n')), contains('DF009'));
      expect(rules(lintDockerfile('FROM a:1\nRUN wget -qO- https://x | sudo bash\nUSER u\n')), contains('DF009'));
      expect(rules(lintDockerfile('FROM a:1\nRUN curl -o /t/i.sh https://x && echo "abc  /t/i.sh" | sha256sum -c && sh /t/i.sh\nUSER u\n')),
          isNot(contains('DF009')));
    });

    test('jeton dans un RUN : bloquant ; fichier vide : invalide', () {
      expect(rules(lintDockerfile('FROM alpine:3.20\nRUN echo ghp_${'x' * 36} > /t\nUSER a\n')), contains('DF003'));
      expect(lintDockerfile('# rien').single.rule, 'DF000');
    });
  });

  group('Compose', () {
    test('mauvais fichier : règles attendues, valeurs masquées', () {
      final f = lintCompose('''
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    privileged: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      DB_PASSWORD: motdepasse-en-clair
    depends_on:
      - db
    network_mode: host
    cap_add: [ALL]
  db:
    image: postgres:latest
    healthcheck:
      test: ["CMD", "pg_isready"]
''');
      expect(rules(f), containsAll(['DC001', 'DC002', 'DC003', 'DC004', 'DC005', 'DC006', 'DC007', 'DC008', 'DC009']));
      expect(f.map((x) => x.message).join(), isNot(contains('motdepasse-en-clair')));
      expect(f.firstWhere((x) => x.rule == 'DC002').line, 2, reason: 'ligne du service');
    });

    test('bon fichier : seulement des infos', () {
      final f = lintCompose('''
services:
  web:
    build: .
    ports: ["127.0.0.1:8080:80"]
    environment:
      DB_PASSWORD: \${DB_PASSWORD}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
  db:
    image: postgres:17.2-alpine
    env_file: .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
''');
      expect(f, isEmpty, reason: f.map((x) => '${x.rule} ${x.message}').join('\n'));
    });

    test('YAML invalide ou sans services', () {
      expect(lintCompose('services: [oups').single.rule, 'DC000');
      expect(lintCompose('version: "3"').single.rule, 'DC000');
    });
  });

  group('modèles', () {
    for (final k in dockerTemplateKinds) {
      test('modèle $k : aucun avertissement ni blocage', () {
        final t = dockerTemplate(k)!;
        final f = lintDockerfile(t['Dockerfile']!);
        expect(f.where((x) => x.severity != LintSeverity.info), isEmpty, reason: f.map((x) => '${x.rule} ${x.message}').join('\n'));
        expect(t['.dockerignore'], contains('.env'));
      });
    }
    test('pas de modèle Flutter', () => expect(dockerTemplate('flutter'), isNull));
  });

  test('masquage des secrets dans un journal', () {
    final out = maskSecrets('connexion avec ghp_${'k' * 36} ok');
    expect(out, 'connexion avec [SECRET MASQUÉ] ok');
  });
}
