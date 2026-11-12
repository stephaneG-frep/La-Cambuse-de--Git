# Bilan — Phase 4 : compagnon Linux sécurisé

Date : 2026-11-12. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

| Élément | Détail |
|---|---|
| `packages/cambuse_protocol` | contrat d'API v1 partagé : portées, opérations typées, états, formats JSON, codes d'erreur |
| `companion/` | exécutable Dart autonome (`dart compile exe`, 7,6 Mo) : `serve`, `pair`, `devices`, `revoke`, `audit` ; voir [companion/README.md](../companion/README.md) |
| API | `health`, `pair/start` (hôte uniquement), `pair/complete`, `token/refresh`, `devices` (hôte), `me`, `ops` (+ `approve`, `reject`, `cancel`), `audit` |
| Opérations | `system.info`, `project.list`, `project.detect`, `git.status`, `git.log`, `git.diff` (lecture) ; `git.init`, `git.add`, `git.commit` (mutantes, approbation obligatoire) |
| Sécurité | voir le tableau du README du compagnon (loopback par défaut, TLS épinglé pour le LAN, jetons hachés et tournants, portées, confinement par résolution des liens, durcissement contre les dépôts piégés, sans shell, délais, plafonds, audit, refus de root) |
| Application | client avec épinglage TLS vérifié à chaque réponse, rafraîchissement automatique, jeton dans le coffre ; écran Paramètres → Compagnon Linux (appairage, dossiers autorisés et projets sélectionnables, opérations, **panneau d'approbation** avec la commande exacte, journal, oubli) ; actions consignées au journal de bord |
| Service | modèle d'unité systemd utilisateur durcie (non installé) |

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd companion && dart test` | `+27: All tests passed!` (suite stable sur 3 exécutions consécutives) |
| `flutter test` (application) | `+163: All tests passed!` (dont 8 tests de contrat contre le vrai compagnon et 3 tests de l'écran), relancé juste avant le commit |
| `flutter analyze --fatal-infos` | `No issues found!` |
| `dart compile exe companion/bin/cambuse_companion.dart` | binaire généré |

Tests contractuels et de sécurité notables :
- appairage : code à usage unique, expiration à 2 min, blocage après 5 essais ;
- jetons : expiration à 15 min, rotation, révocation immédiate ;
- fichiers 0600, aucun jeton en clair ;
- portées : refus d'une mutation par un appareil en lecture seule, refus d'une opération inconnue (`shell.exec`) ;
- chemins : hors racine, relatif, `..`, lien symbolique de dossier ou de fichier sortant, `.git` ;
- dépôt piégé : hook `pre-commit` et `core.fsmonitor` **non exécutés** (fichier témoin absent), filtre `clean` bloquant ;
- délais, annulation et plafond de sortie (git simulé) ; isolation entre appareils ; audit sans jetons ;
- côté application, contrat réel client ↔ compagnon, dont le TLS avec un vrai certificat openssl : empreinte correcte acceptée, fausse refusée, absente refusée ; HTTP vers une adresse distante interdit.

## 3. Essai réel sur le Honor (via `adb reverse`, rien d'exposé au réseau)

Dossier autorisé : un dossier de démonstration jetable (aucun projet de l'utilisateur).

1. `cambuse-companion pair --scopes read,git-write` → code saisi sur le téléphone → « Appairé avec http://127.0.0.1:47820 — Portées : read, git-write — Git : git version 2.34.1 ».
2. Projet `vitrine` choisi dans la liste → **État Git** → `## main` / `?? notes.txt` (conforme au dépôt).
3. Projet `nouveau` → **Initialiser Git** → panneau « Autoriser cette opération ? » avec la commande exacte `git init --initial-branch=main`. **Aucun `.git` avant l'accord.**
4. « Autoriser » → `.git` créé sur le PC, branche `refs/heads/main` ; audit : `op.submitted git.init` → `op.approved git.init` → `op.finished succeeded 0`.

## 4. Défauts trouvés et corrigés

1. **Saisie d'un chemin long sur téléphone** : échec réel lors de l'essai (l'opération est partie sur le mauvais dossier, avec un message d'erreur exact). Ajout de l'opération `project.list` et de puces de sélection.
2. Sous-titre « Contexte » perdu en rouvrant une conversation IA : corrigé.
3. Tests : attentes asynchrones non attendues (course entre tests), port lu après arrêt du serveur, `pumpAndSettle` bloqué par la barre de progression ; corrigés dans les tests.

## 5. Limites

- **Accès réseau local (`--lan`) non essayé depuis le téléphone** : cela ouvrirait un port sur votre réseau, ce qui demande votre accord. Le TLS épinglé est testé en local avec un vrai certificat.
- Filtres Git déclarés dans la configuration **globale** de l'utilisateur : non détectés (le README le signale).
- Le service systemd est fourni comme modèle, non installé (installation système exclue sans confirmation).
- Les messages d'erreur du compagnon sont en français, y compris quand l'interface est en anglais.
- L'atelier complet (audit, diff, commits guidés, sauvegardes) arrive en phase 5, sur cette base.
