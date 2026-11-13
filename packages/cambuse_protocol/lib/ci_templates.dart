/// Modèles de pipelines CI (GitHub Actions, GitLab CI) : actions épinglées par
/// empreinte de commit, permissions minimales, délais, cache, analyse des
/// secrets, artefacts avec sommes SHA-256. Aucun secret n'y figure.
library;

/// Actions GitHub épinglées (empreintes résolues le 2026-11-13).
abstract final class PinnedActions {
  static const checkout = 'actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2';
  static const uploadArtifact = 'actions/upload-artifact@b4b15b8c7c6ac21ea08fcf65892d2ee8f75cf882 # v4.4.3';
  static const flutter = 'subosito/flutter-action@44ac965b96f18d999802d4b807e3256d5a3f9fa1 # v2.16.0';
  static const setupNode = 'actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0';
  static const setupPython = 'actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b # v5.3.0';
  static const gitleaks = 'gitleaks/gitleaks-action@83373cf2f8c4db6e24b41c1a9b086bb9619e9cd3 # v2.3.7';
}

const ciTemplateKinds = ['flutter', 'node', 'python'];
const ciProviders = ['github', 'gitlab'];

/// Fichier à écrire pour un fournisseur donné.
String ciFileName(String provider) => provider == 'github' ? '.github/workflows/ci.yml' : '.gitlab-ci.yml';

String _secretScanJob() => '''
  secrets:
    name: Analyse des secrets
    runs-on: ubuntu-22.04
    timeout-minutes: 10
    steps:
      - uses: ${PinnedActions.checkout}
        with:
          fetch-depth: 0
          persist-credentials: false
      - uses: ${PinnedActions.gitleaks}
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
''';

const _header = '''# Généré par La Cambuse de Git — à relire avant de committer.
# Actions épinglées par empreinte de commit ; permissions minimales.
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ci-\${{ github.ref }}
  cancel-in-progress: true

jobs:
''';

/// Modèle de pipeline, ou null si la combinaison n'existe pas.
String? ciTemplate(String kind, String provider, {String flutterVersion = '3.27.1'}) {
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(flutterVersion)) flutterVersion = '3.27.1';
  return switch ((kind, provider)) {
    ('flutter', 'github') => '''$_header${_secretScanJob()}
  analyze-test:
    name: Analyse et tests
    runs-on: ubuntu-22.04
    timeout-minutes: 20
    steps:
      - uses: ${PinnedActions.checkout}
        with:
          persist-credentials: false
      - uses: ${PinnedActions.flutter}
        with:
          flutter-version: $flutterVersion
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  apk-debug:
    name: APK de test (debug, non distribuable)
    needs: analyze-test
    runs-on: ubuntu-22.04
    timeout-minutes: 30
    steps:
      - uses: ${PinnedActions.checkout}
        with:
          persist-credentials: false
      - uses: ${PinnedActions.flutter}
        with:
          flutter-version: $flutterVersion
          channel: stable
          cache: true
      - run: flutter build apk --debug --target-platform android-arm64
      - name: Renommage explicite et somme SHA-256
        run: |
          mkdir -p dist
          cp build/app/outputs/flutter-apk/app-debug.apk dist/app-arm64-v8a-DEBUG-non-distribuable.apk
          cd dist && sha256sum *.apk > SHA256SUMS
      - uses: ${PinnedActions.uploadArtifact}
        with:
          name: apk-debug
          path: dist/
          retention-days: 7
''',
    ('flutter', 'gitlab') => '''# Généré par La Cambuse de Git — à relire avant de committer.
stages: [verify, build]

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

default:
  image: ghcr.io/cirruslabs/flutter:$flutterVersion
  interruptible: true
  timeout: 30m
  cache:
    key:
      files: [pubspec.lock]
    paths: [.pub-cache/]

variables:
  PUB_CACHE: \$CI_PROJECT_DIR/.pub-cache

secret_detection:
  stage: verify

analyze_test:
  stage: verify
  script:
    - flutter pub get
    - flutter analyze
    - flutter test

apk_debug:
  stage: build
  needs: [analyze_test]
  script:
    - flutter build apk --debug --target-platform android-arm64
    - mkdir -p dist
    - cp build/app/outputs/flutter-apk/app-debug.apk dist/app-arm64-v8a-DEBUG-non-distribuable.apk
    - cd dist && sha256sum *.apk > SHA256SUMS
  artifacts:
    name: apk-debug
    paths: [dist/]
    expire_in: 1 week
''',
    ('node', 'github') => '''$_header${_secretScanJob()}
  test:
    name: Installation, tests, build
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    steps:
      - uses: ${PinnedActions.checkout}
        with:
          persist-credentials: false
      - uses: ${PinnedActions.setupNode}
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm test --if-present
      - run: npm run build --if-present
''',
    ('node', 'gitlab') => '''# Généré par La Cambuse de Git — à relire avant de committer.
stages: [verify]

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

default:
  image: node:22.11-slim
  interruptible: true
  timeout: 15m
  cache:
    key:
      files: [package-lock.json]
    paths: [.npm/]

secret_detection:
  stage: verify

test:
  stage: verify
  script:
    - npm ci --cache .npm --prefer-offline
    - npm test --if-present
    - npm run build --if-present
''',
    ('python', 'github') => '''$_header${_secretScanJob()}
  test:
    name: Installation et tests
    runs-on: ubuntu-22.04
    timeout-minutes: 15
    steps:
      - uses: ${PinnedActions.checkout}
        with:
          persist-credentials: false
      - uses: ${PinnedActions.setupPython}
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install -r requirements.txt
      - run: python -m pytest
''',
    ('python', 'gitlab') => '''# Généré par La Cambuse de Git — à relire avant de committer.
stages: [verify]

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

default:
  image: python:3.12.7-slim
  interruptible: true
  timeout: 15m
  cache:
    paths: [.cache/pip]

variables:
  PIP_CACHE_DIR: \$CI_PROJECT_DIR/.cache/pip

secret_detection:
  stage: verify

test:
  stage: verify
  script:
    - pip install -r requirements.txt
    - python -m pytest
''',
    _ => null,
  };
}
