# La Cambuse de Git

Application Flutter **Android** et **Linux** : académie Git / GitHub / GitLab / Docker / DevOps de zéro à expert, atelier d'opérations réelles sur projets et capitaine automatique supervisé.

> État actuel : **fin de phase 4** (Académie Git hors ligne, professeur IA facultatif, compagnon Linux sécurisé). Voir [docs/ACCEPTANCE_MATRIX.md](docs/ACCEPTANCE_MATRIX.md) pour l'état réel de chaque fonctionnalité. L'Atelier et le Capitaine affichent honnêtement la phase où ils seront livrés. Le bac à sable de l'Académie est un **simulateur pédagogique** clairement signalé : il n'exécute aucune commande réelle.

## Documents de référence

- [SPEC.md](SPEC.md) — cahier des charges
- [DESIGN.md](DESIGN.md) — direction artistique et UX
- [ROADMAP.md](ROADMAP.md) — phases
- [docs/PHASE0_DIAGNOSTIC.md](docs/PHASE0_DIAGNOSTIC.md) — environnement, décisions, menaces, contrat API
- [docs/PHASE1_BILAN.md](docs/PHASE1_BILAN.md) — bilan de la phase 1
- [docs/PHASE2_BILAN.md](docs/PHASE2_BILAN.md) — bilan de la phase 2
- [docs/PHASE3_BILAN.md](docs/PHASE3_BILAN.md) — bilan de la phase 3
- [docs/PHASE4_BILAN.md](docs/PHASE4_BILAN.md) — bilan de la phase 4
- [companion/README.md](companion/README.md) — compagnon Linux (installation, sécurité)
- [CHANGELOG.md](CHANGELOG.md)

## Prérequis développeur

- Flutter 3.47.2 stable (Dart 3.13.2)
- Linux : clang, cmake, ninja, pkg-config, `libgtk-3-dev`, `libsecret-1-dev`
- Android : SDK (platform 37), JDK 21 (celui d'Android Studio convient)

## Commandes

```bash
flutter pub get
python3 tool/content/git_module.py                          # régénère assets/courses/git.json
dart run build_runner build --delete-conflicting-outputs   # code Drift
flutter analyze --fatal-infos
flutter test
flutter run -d linux

flutter build linux --release                                  # bundle Linux
flutter build apk --debug --target-platform android-arm64      # APK de TEST
(cd companion && dart test)                                    # tests du compagnon
dart compile exe companion/bin/cambuse_companion.dart -o build/companion/cambuse-companion
```

L'APK produit ainsi est signé avec la **clé debug** : il sert aux tests et **n'est pas distribuable**. Une release signée nécessitera votre propre keystore (`android/key.properties`, jamais versionné) — prévu en phase 8.

## Données et confidentialité

- Base SQLite locale : Linux `~/.local/share/fr.lacambuse.la_cambuse/cambuse.sqlite`, Android stockage interne de l'app.
- Aucune télémétrie. Seul le professeur IA, facultatif, envoie vos questions au fournisseur que vous configurez.
- Clé API stockée dans le coffre du système (Keystore Android, libsecret Linux), jamais en base ni dans les journaux.
- Le journal de bord masque automatiquement les secrets probables (jetons GitHub/GitLab, clés API, en-têtes Bearer, identifiants dans les URL, clés privées).

## Architecture

```
lib/
  app/        bootstrap, routeur go_router, thème (tokens), coque adaptative, providers Riverpod
  core/       base Drift, journalisation (Redactor)
  features/   dashboard, profile, logbook, settings, academy, workshop, captain
  shared/     widgets réutilisables (états, jauge)
  l10n/       ARB FR (référence) et EN
test/         unitaires, base de données, widgets et accessibilité
```
