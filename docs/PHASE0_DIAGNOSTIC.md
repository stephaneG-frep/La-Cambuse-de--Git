# Phase 0 — Diagnostic de l'environnement et cadrage

Date : 2026-11-12 — Machine de développement unique (hôte Linux).
Toutes les commandes ci-dessous ont **réellement été exécutées** ; aucune installation ni modification système n'a été faite.

## 1. Résultats du diagnostic

| Outil / ressource | Commande | Résultat exact | Statut |
|---|---|---|---|
| OS | `cat /etc/os-release`, `uname -m` | Ubuntu 22.04.5 LTS, x86_64, noyau 6.8.0-138, 4 cœurs, 15 Gio RAM, 189 Gio libres | OK |
| Flutter | `flutter --version` | 3.47.2 stable (snap), Dart 3.13.2, DevTools 2.60.0 | OK |
| Flutter doctor | `flutter doctor -v` | « No issues found! » | OK |
| Android SDK | doctor | `~/Android/Sdk`, platform android-37.0, build-tools 37.0.0, NDK 28.2, licences acceptées | OK |
| JDK | doctor | OpenJDK 21.0.10 embarqué Android Studio (`/opt/android-studio/jbr`) ; `java`/`JAVA_HOME` **absents du PATH** | OK pour Gradle via Flutter ; `keytool` à appeler par chemin complet |
| adb | `which -a adb` | **Deux binaires** (SDK + `/usr/lib/android-sdk`) — avertissement doctor | Risque mineur |
| Appareil Android | `adb devices` + `getprop` | 1 appareil physique `MTN-NX1M`, ABI **arm64-v8a**, API 36 | OK (tests réels possibles) |
| Toolchain Linux | doctor | clang 14, cmake 3.22.1, ninja 1.10.1, pkg-config 0.29.2 | OK |
| GTK / libsecret / sqlite | `dpkg -s` | libgtk-3-dev, libsecret-1-dev, libsqlite3-dev, liblzma-dev présents ; libjsoncpp-dev absent (non requis) | OK |
| Packaging .deb | `which` | dpkg-deb, fakeroot présents ; **lintian absent** | Partiel (vérif. lintian impossible sans installation) |
| Git | `git --version` | 2.34.1, identité globale configurée | OK |
| GitHub CLI | `gh auth status` | gh 2.101.0, connecté, portées `repo, workflow, gist, read:org` | OK (aucun appel distant effectué) |
| GitLab CLI | `which glab` | **absent** | Bloquant pour tests GitLab réels (phase 6) — API REST possible à la place |
| Docker | `docker info` | 29.1.3, daemon accessible sans sudo (groupe `docker`) | OK — attention : groupe docker ≈ root |
| Ollama | `which ollama` | absent | IA locale non testable pour l'instant |
| sqlite3 CLI | `which sqlite3` | absent | Non requis (bibliothèque embarquée) |

## 2. Décisions d'architecture (prudentes, documentées)

| # | Décision | Justification |
|---|---|---|
| D1 | Gestion d'état **Riverpod** (`flutter_riverpod`, sans génération de code) | Testable, injection de dépendances via `ProviderScope.overrides`, pas de dépendance au `BuildContext`. |
| D2 | Navigation **go_router** avec `StatefulShellRoute` | Déclaratif ; barre inférieure (téléphone) et rail latéral (bureau) sur le même arbre de routes. |
| D3 | Persistance **Drift** (SQLite) + `sqlite3_flutter_libs` | Migrations versionnées et testables en mémoire ; fonctionne Android et Linux. |
| D4 | Secrets via **flutter_secure_storage** (Keystore Android / libsecret Linux) | Coffre OS ; jamais en base ni dans les logs. |
| D5 | i18n via `flutter gen-l10n` (ARB) FR par défaut, EN préparé | Outil officiel. |
| D6 | Opérations Git sur Linux via `Process.run('git', [args])` **sans shell**, liste blanche d'opérations typées | Pas d'injection, pas de libgit2 natif à maintenir. |
| D7 | **Compagnon Linux** = exécutable Dart séparé (`companion/`), HTTP sur loopback par défaut ; LAN uniquement si activé explicitement, en TLS auto-signé avec épinglage d'empreinte affichée lors de l'appairage | Android ne lance jamais de commande hôte lui-même. |
| D8 | Contenu pédagogique embarqué en **JSON versionné dans les assets** | Hors ligne garanti, relisible, testable (validation de schéma). |
| D9 | Paquet `.deb` produit par script `dpkg-deb --root-owner-group` à partir de `flutter build linux --release` | Pas d'outil tiers ; reproductible. |
| D10 | APK : **debug** pour tests ; release uniquement si `key.properties` fourni par l'utilisateur (hors Git) | Conforme à la SPEC ; pas de fausse release. |
| D11 | Docker **non utilisé** pour construire l'app Flutter | Inutile ici : la toolchain native est complète. Réservé aux modules pédagogiques (phase 7). |
| D12 | Dépôt Git **local uniquement** pour le projet ; aucun remote ajouté sans validation | Règle « jamais publier sans validation ». |
| D13 | GitLab : via API REST + jeton à portée minimale (glab absent) | Évite une installation système. |

## 3. Architecture cible

```
la_cambuse/                  Application Flutter (Android + Linux)
  lib/
    app/                     bootstrap, routeur, thème (tokens), shell adaptatif
    core/                    journalisation, erreurs, sécurité (chemins, secrets), base Drift
    features/
      dashboard/             Pont du navire
      academy/               cours, quiz, progression (domaine / données / présentation)
      workshop/              Chantier naval (import, audit, git)
      captain/               Capitaine automatique
      logbook/               Journal de bord (audit)
      ai/                    fournisseurs IA, coffre de clés
      settings/              paramètres, accessibilité
      companion_link/        appairage agent Linux
  assets/courses/            contenu pédagogique JSON
  test/                      unitaires, widgets, migrations
companion/                   Agent compagnon Linux (Dart CLI, shelf)
tool/                        scripts de build (.deb, checksums)
docs/                        diagnostic, menaces, contrat API, guides
```

Couches par fonctionnalité : `domain/` (entités pures, règles), `data/` (Drift, fichiers, processus), `presentation/` (widgets, providers).

## 4. Modèle de menaces (résumé STRIDE)

| Menace | Exemple | Contre-mesure |
|---|---|---|
| Usurpation | Un appareil du LAN se fait passer pour le téléphone appairé | Code d'appairage à usage unique (6 chiffres, 2 min), jeton court (15 min) + jeton de rafraîchissement révocable, TLS épinglé |
| Altération | Réponse IA contenant `rm -rf` ou `; curl …` | Pas de shell ; l'IA ne produit que des **intentions** validées par schéma, mappées sur une liste blanche ; confirmation utilisateur |
| Traversée de chemins | `../../etc/passwd`, liens symboliques | Résolution canonique (`resolveSymbolicLinks`) + vérification de confinement dans la racine choisie |
| Fuite de secrets | Jeton dans un `.env` poussé, clé API dans un log | Scanner de secrets avant commit/push (bloquant), filtre de rédaction dans le logger, coffre OS |
| Répudiation | « Je n'ai pas autorisé ce push » | Journal d'audit local horodaté (action, paramètres, consentement, résultat) |
| Déni de service | Commande bloquée | Timeouts, annulation, quotas, file d'opérations unique |
| Élévation | Compagnon lancé en root, groupe docker | Refus de démarrer en root, avertissement groupe docker, pas de sudo |
| Injection de prompt | README d'un projet importé demandant à l'IA de pousser en public | Contenu du projet balisé comme donnée non fiable ; aucune action déclenchée sans validation humaine |

## 5. Contrat d'API du compagnon (v1, brouillon)

Base : `http://127.0.0.1:47820/v1` (loopback) ou `https://<hôte>:47821/v1` (LAN, opt-in). Toutes les réponses JSON `{ "ok": bool, "data"|"error": … }`.

| Méthode | Route | Auth | Rôle |
|---|---|---|---|
| GET | `/v1/health` | non | version, capacités détectées (git, flutter, docker) |
| POST | `/v1/pair/start` | locale (console hôte) | génère un code à usage unique affiché **côté hôte** |
| POST | `/v1/pair/complete` | code | échange code → jeton d'accès (15 min) + rafraîchissement |
| POST | `/v1/token/refresh` | refresh | nouveau jeton |
| POST | `/v1/ops` | Bearer | soumet une opération typée `{type, root, params, dryRun}` → plan + id |
| POST | `/v1/ops/{id}/approve` | Bearer | consentement explicite pour une opération |
| GET | `/v1/ops/{id}` | Bearer | état, sortie, code retour |
| POST | `/v1/ops/{id}/cancel` | Bearer | annulation |
| GET | `/v1/audit` | Bearer | journal d'audit |

Types d'opérations v1 (liste blanche) : `git.status`, `git.log`, `git.diff`, `git.init`, `git.add`, `git.commit`, `git.branch.create`, `git.checkout`, `project.detect`, `project.audit`, `flutter.analyze`, `flutter.test`, `flutter.build.apk.debug`, `flutter.build.linux`. Aucune opération « shell libre ».

## 6. Contraintes de signature

- APK debug : signé avec la clé debug locale → **non distribuable**, affiché comme tel.
- APK release : nécessite un keystore utilisateur + `android/key.properties` (ignoré par Git). Sans cela, la cible release est refusée avec un message explicite.
- `.deb` : non signé (pas de dépôt APT) ; checksums SHA-256 fournis.

## 7. Matrice OS

| Cible | Build | Test réel possible ici |
|---|---|---|
| Linux x86_64 (Ubuntu 22.04) | `flutter build linux` + dpkg-deb | Oui |
| Android arm64-v8a (API 36) | `flutter build apk --debug --target-platform android-arm64` | Oui (appareil MTN-NX1M branché) |
| Linux arm64 | non | Non (pas de machine) |
| Android x86_64 (émulateur) | possible | Émulateur présent, non testé |

## 8. Critères d'acceptation

Voir [ACCEPTANCE_MATRIX.md](ACCEPTANCE_MATRIX.md), tenue à jour à chaque phase.

## 9. Risques ouverts

1. Deux `adb` dans le PATH → préciser l'appareil avec `-s` et privilégier celui du SDK.
2. `lintian` absent → validation `.deb` limitée à `dpkg-deb --info/--contents` et installation de test (qui requiert sudo : **demandera confirmation**).
3. `glab` absent, Ollama absent → fonctionnalités testables seulement via API REST / fournisseur distant configuré par l'utilisateur.
4. Le compte gh a la portée `repo` complète : l'application ne réutilisera pas silencieusement ce jeton ; elle demandera un jeton dédié à portée minimale ou l'accord explicite.
