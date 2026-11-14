# Guide développeur — La Cambuse de Git

## Prérequis

- Flutter 3.47.2 (Dart 3.13.2), canal stable.
- Linux : `ninja-build`, `libgtk-3-dev`, `libsecret-1-dev`, `liblzma-dev` ; pour les paquets : `dpkg-dev`, `python3-yaml`.
- Android : SDK, build-tools (pour `apksigner`), un appareil arm64 ou un émulateur.
- Facultatif : Docker (inspection et labos), `gh` (publication).

## Organisation du dépôt

```
lib/                      application Flutter (Android et Linux)
  app/                    routeur, thème, coque adaptative, fournisseurs
  core/db/                base Drift (schéma v4 et migrations)
  core/logging/           masquage des secrets (Redactor)
  features/<espace>/      domain/ (Dart pur, testé), data/, presentation/
companion/                compagnon Linux (exécutable Dart, API v1)
packages/cambuse_protocol/  contrat partagé : opérations, portées, analyseurs, modèles
assets/courses/           modules de l'Académie (JSON générés)
tool/content/             générateurs Python des modules (source de vérité)
tool/package_release.sh   livraison : APK de test, .deb, sources, SBOM, sommes, rapport
docs/                     bilans de phase, guides, matrice d'acceptation, rapport final
test/                     tests de l'application (unitaires, widgets, migrations)
```

## Commandes courantes

```
flutter pub get
(cd companion && dart pub get)
(cd packages/cambuse_protocol && dart pub get)
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
(cd companion && dart test)
(cd packages/cambuse_protocol && dart test)
flutter run -d linux
tool/package_release.sh --with-tests
```

- Récupérez les dépendances des **trois** projets avant `flutter analyze` : l'analyse à la racine couvre aussi `companion/` et `packages/`.
- Après toute modification d'un générateur de `tool/content/`, relancez-le. Le test `advanced_content_test.dart` vérifie que les JSON commités sont identiques à leur source.

## Principes non négociables

- **Aucun shell libre.** Toute action sur une machine passe par une opération typée (`OpType`) du compagnon, avec arguments validés, délai et journal d'audit.
- **Mutation = approbation.** Une opération `mutating` attend l'accord explicite de l'utilisateur, qui voit la commande exacte.
- **Secrets** : jamais en base, dans les journaux, dans les rapports, dans les messages envoyés à l'IA ni dans Git. Le `Redactor` et `maskSecrets` sont des filets de sécurité, pas une excuse pour journaliser des valeurs.
- **Sortie IA non fiable** : validation de schéma, liste blanche d'opérations, confinement des chemins (voir `captain/domain/ai_plan.dart`).
- **Honnêteté** : pas de bouton factice, pas de résultat inventé. Une fonction non livrée n'apparaît pas.

## Ajouter une opération au compagnon

1. Déclarez-la dans `OpType` (`packages/cambuse_protocol/lib/cambuse_protocol.dart`), avec sa portée (`Scope`) et son caractère `mutating`.
2. Implémentez sa préparation dans `companion/lib/src/ops.dart`. Elle doit fournir :
   - la validation des paramètres ;
   - le confinement des chemins (`RootGuard`) ;
   - un plan lisible ;
   - les arguments exacts ;
   - un délai.
3. Ajoutez des tests dans `companion/test/` : refus des entrées piégées, absence d'effet sans approbation, audit.
4. Pour l'utiliser dans le Capitaine : ajoutez-la à `captainAllowedOps` et décrivez ses paramètres dans `_paramSchema` (`lib/features/captain/domain/mission.dart`), avec des tests de validation.

## Ajouter un module à l'Académie

1. Écrivez `tool/content/<module>_module.py` avec les fonctions de `common.py` : leçons, quiz, labos, projet et grille.
2. Lancez-le pour produire `assets/courses/<id>.json`, puis ajoutez l'île dans `lib/features/academy/domain/catalog.dart`.
3. Les labos « fichier » s'appuient sur les analyseurs de `infra_lint.dart` et `docker_lint.dart`. Chaque labo doit échouer avec son fichier de départ et réussir avec sa solution : `advanced_content_test.dart` le vérifie.

## Base de données

- Schéma Drift `lib/core/db/database.dart`, version 4.
- Toute évolution comprend :
  - une étape dans `onUpgrade` ;
  - le schéma de la version précédente relevé sur une vraie base (`test/fixtures/schema_vN.sql`) ;
  - un test dans `test/core/migration_test.dart`.

## Tests et CI

- Tests unitaires du domaine, tests widgets, migrations, scénarios de défaillance du Capitaine, accessibilité (cibles, libellés, contraste, texte à 200 %).
- CI : `.github/workflows/ci.yml`.
  - Les actions sont épinglées par empreinte de commit.
  - Elle comprend trois jobs : analyse des secrets (gitleaks, exception limitée aux dossiers `test/`), analyse et tests des trois projets, livraison des artefacts.
- Les tests simulés ne remplacent pas les essais réels : chaque bilan de phase (`docs/PHASEn_BILAN.md`) documente les essais sur appareil.

## Essais sur téléphone

- Compagnon : `cambuse-companion serve --root <dossier de démo>`, puis `adb reverse tcp:47820 tcp:47820`, et appairage avec le code de `cambuse-companion pair --scopes …`.
- Faites vos essais sur des projets de démonstration jetables, jamais sur de vrais projets.

## Livraison

- `tool/package_release.sh --with-tests` produit dans `dist/` :
  - l'APK de **test** (clé debug), nommé `…-DEBUG-non-distribuable.apk` ;
  - le `.deb` ;
  - le ZIP des sources ;
  - le SBOM CycloneDX ;
  - `SHA256SUMS` et `BUILD_REPORT.md`.
- Une release Android signée exige `android/key.properties`, que vous fournissez et qui n'est jamais versionné. Sans ce fichier, Gradle refuse la release.
