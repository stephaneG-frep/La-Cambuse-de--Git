/// Modèles Dockerfile sûrs par technologie : versions épinglées, multi-étapes,
/// utilisateur non root, HEALTHCHECK, forme JSON. Ils passent l'analyseur sans
/// avertissement (vérifié par les tests).
library;

const dockerTemplateKinds = ['node', 'python', 'dart', 'go'];

/// Raison pour laquelle on ne conteneurise pas une application Flutter.
const flutterDockerNote =
    'Une application Flutter (Android, Linux) se distribue en APK ou en paquet .deb : elle ne tourne pas '
    'dans un conteneur. Docker peut servir à une API ou un backend associé, ou à figer l\'outillage de CI, '
    'mais conteneuriser l\'application elle-même n\'apporte rien.';

const _ignoreCommon = '.git\n.gitignore\n.env\n.env.*\n*.log\n.dockerignore\nDockerfile\ncompose.yaml\n';

Map<String, String>? dockerTemplate(String kind) => switch (kind) {
      'node' => {
          'Dockerfile': '''# Généré par La Cambuse de Git — à adapter à votre projet.
FROM node:22.11-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22.11-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
HEALTHCHECK CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
CMD ["node", "dist/server.js"]
''',
          '.dockerignore': '${_ignoreCommon}node_modules\ndist\ncoverage\n',
        },
      'python' => {
          'Dockerfile': '''# Généré par La Cambuse de Git — à adapter à votre projet.
FROM python:3.12.7-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN useradd --create-home --uid 10001 appli
USER appli
EXPOSE 8000
HEALTHCHECK CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else 1)"]
CMD ["python", "-m", "app"]
''',
          '.dockerignore': '${_ignoreCommon}__pycache__\n.venv\n*.pyc\n',
        },
      'dart' => {
          'Dockerfile': '''# Généré par La Cambuse de Git — serveur Dart (pas une application Flutter).
FROM dart:3.5.4 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o /app/server

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
USER nonroot
EXPOSE 8080
HEALTHCHECK NONE
CMD ["/app/server"]
''',
          '.dockerignore': '$_ignoreCommon.dart_tool\nbuild\n',
        },
      'go' => {
          'Dockerfile': '''# Généré par La Cambuse de Git — à adapter à votre projet.
FROM golang:1.23.3 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /out/appli ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/appli /appli
USER nonroot
EXPOSE 8080
HEALTHCHECK NONE
CMD ["/appli"]
''',
          '.dockerignore': '${_ignoreCommon}bin\n',
        },
      _ => null,
    };
