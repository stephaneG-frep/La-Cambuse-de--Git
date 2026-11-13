# Bilan — Phase 8 : CI/CD, APK de test, paquet .deb

Date : 2026-11-13. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Modèles de CI (`packages/cambuse_protocol/lib/ci_templates.dart`)
- Flutter, Node et Python, chacun pour **GitHub Actions** et **GitLab CI**.
- Actions GitHub **épinglées par empreinte de commit** (checkout, upload-artifact, flutter-action, setup-node, setup-python, gitleaks).
- `permissions: contents: read`, délais, annulation des exécutions concurrentes, cache, `persist-credentials: false`.
- Analyse des secrets : gitleaks sur GitHub, modèle Secret-Detection sur GitLab.
- Flutter : l'APK est construit **en debug**, renommé `app-arm64-v8a-DEBUG-non-distribuable.apk`, accompagné de `SHA256SUMS`, et conservé 7 jours. Aucun secret n'est requis.

### Compagnon
- Nouvelle portée **`build`**, accordée à part : un build exécute du code du projet (scripts Gradle, plugins, tests).
- `ci.scaffold` (portée git-write, approbation) écrit le pipeline **sans jamais écraser** un fichier existant.
- `flutter.analyze`, `flutter.test`, `flutter.build.apk.debug` et `flutter.build.linux` :
  - commande exacte affichée et approbation obligatoire ;
  - environnement minimal et délai de 25 min ;
  - refus hors d'un projet Flutter.
- `artifacts.list` (lecture) couvre les APK, AAB, le bundle Linux et `dist/`. Il donne :
  - la taille et le SHA-256 ;
  - la **signature vérifiée par apksigner** : debug, release, invalide ou inconnue ;
  - les **ABI exécutables**, c'est-à-dire celles qui embarquent `libflutter.so`.
- Aucune opération de release signée, de publication ou de déploiement.

### Application
- Atelier → fiche projet → onglet **Builds** :
  - génération de CI (type et plateforme au choix) ;
  - analyse, tests, APK de test et build Linux, chacun approuvé ;
  - sortie (25 dernières lignes) et code de sortie, avec un rappel « un APK debug n'est jamais distribuable » ;
  - **Cale des artefacts** : taille, SHA-256 copiable, badge « DEBUG — non distribuable » ou « Signé (release) », certificat et ABI.
- Le panneau d'approbation a une formulation propre aux builds : « exécute du code du projet sur le PC ».
- L'aide d'appairage mentionne `--scopes …,build`.

### Livrables de La Cambuse elle-même
- **Signature release** depuis `android/key.properties`, jamais versionné. Sans ce fichier, Gradle **refuse** `assembleRelease` avec un message explicite, sans repli silencieux sur la clé debug.
- `tool/package_release.sh` produit dans `dist/` :
  - `la-cambuse-1.0.0-arm64-v8a-DEBUG-non-distribuable.apk` ;
  - `la-cambuse_1.0.0_amd64.deb` : application dans `/opt/la-cambuse`, `cambuse-companion`, raccourcis `/usr/bin`, entrée de menu, icône, exemple de service systemd. Les dépendances sont **calculées par `dpkg-shlibdeps`**, auxquelles s'ajoute `git` ;
  - `la-cambuse-1.0.0-sources.zip` (`git archive`) ;
  - `sbom.cdx.json` (CycloneDX 1.5, 165 composants pub de l'application et du compagnon) ;
  - `SHA256SUMS` et `BUILD_REPORT.md` (certificat APK, ABI, `dpkg-deb --info`, bibliothèques non résolues).
  - Le script **n'installe rien** et ne publie rien. Le mainteneur indiqué est générique.
- CI du dépôt (`.github/workflows/ci.yml`) :
  - actions épinglées ;
  - jobs secrets, analyse et tests (application, protocole, compagnon) ;
  - job **livraison** qui lance le script, vérifie les sommes et publie les artefacts (14 jours).

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd packages/cambuse_protocol && dart test` | `+21: All tests passed!` |
| `cd companion && dart test` | `+58: All tests passed!` (dont un vrai APK identifié « debug », ABI arm64-v8a) |
| `flutter test` | `+214: All tests passed!` (dont 4 tests de l'onglet Builds) |
| `flutter analyze --fatal-infos`, `dart analyze --fatal-infos` (compagnon, protocole) | `No issues found!` |
| `flutter build apk --release` sans `key.properties` | **échec voulu** : « Release refusée : android/key.properties est absent… » |
| `tool/package_release.sh` | 4 artefacts, `sha256sum -c SHA256SUMS` : tout OK |
| Contrôle du `.deb` | `dpkg-deb -x` puis `ldd` : 0 bibliothèque manquante ; le compagnon extrait répond à `--help` |

## 3. Essai réel sur le Honor (`adb reverse`, projet de démonstration jetable `vigie` créé par `flutter create`)

1. Appareil appairé **sans** `build` : « flutter test » → « Cet appareil n'a pas la portée « build »… ». Le compagnon a refusé, rien n'a été exécuté.
2. **Générer le pipeline** :
   - le panneau affiche « Créer .github/workflows/ci.yml (modèle flutter, GitHub Actions, Flutter 3.47.2) — 73 lignes » ;
   - après « Autoriser », le fichier est créé sur le PC avec les actions épinglées ;
   - une seconde demande renvoie « existe déjà : il ne sera pas écrasé ».
3. Révocation de l'ancien appareil, puis réappairage avec `read, git-write, remote, docker, build`.
4. **flutter test** approuvé : code de sortie 0, « +1: All tests passed! » affiché.
5. **APK de test (debug)** approuvé :
   - build réussi en 38 s ;
   - la cale montre `app-debug.apk · 73.6 Mo`, **« DEBUG — non distribuable »**, `C=US, O=Android, CN=Android Debug`, `ABI : arm64-v8a` ;
   - le SHA-256 est **identique** à celui calculé par `sha256sum` sur le PC.
6. **flutter analyze** approuvé : code 0, formulation « exécute du code du projet sur le PC », SnackBar de fin visible.

## 4. Défauts trouvés et corrigés

1. **ABI trompeuses** : l'APK contenait `armeabi-v7a` et `x86_64` (une bibliothèque de greffon seulement), sans moteur Flutter. Seules les ABI exécutables sont désormais annoncées ; les autres sont signalées à part dans le rapport.
2. Le panneau d'approbation disait « modifie le dépôt » pour un test ou un build. La formulation dédiée est maintenant vérifiée par un test.
3. Le résultat d'un build restait hors écran quand on avait fait défiler la page jusqu'aux boutons. Une SnackBar le signale désormais.
4. `.gitignore` : doublon `dist/` évité.

## 5. Limites

- La **CI du dépôt n'a pas encore tourné sur GitHub** : le dépôt n'y est pas publié. Seule la syntaxe YAML est validée localement. Les modèles générés n'ont pas non plus été exécutés sur un vrai runner.
- Le **`.deb` n'a pas été installé** : l'installation demande `sudo`, donc votre accord explicite. Il a été vérifié par extraction et `ldd`.
- Aucune release signée n'a été produite : pas de keystore, ce qui est voulu.
- Les builds via le compagnon couvrent Flutter seulement. Node et Python ont des modèles de CI, mais pas de build local.
- La sortie affichée est tronquée aux 25 dernières lignes, et l'opération entière est limitée à 25 min.
- Le SBOM ne couvre que les dépendances Dart (pas les bibliothèques système ni Gradle).
- Une exécution de la suite du compagnon a échoué **une fois** (sortie non conservée), juste après la suite de l'application ; 4 exécutions suivantes : `+58: All tests passed!`. Probable test sensible au minutage (tests réels Docker/apksigner) : à surveiller, non résolu.
