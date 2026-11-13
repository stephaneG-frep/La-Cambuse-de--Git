# Bilan — Phase 7 : Docker et Compose

Date : 2026-11-13. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Analyseurs partagés (`packages/cambuse_protocol`, pur Dart, hors ligne)
- **Dockerfile** (`lintDockerfile`), règles DF001–DF015 : image non épinglée, conteneur final en root, secret dans ENV/ARG/RUN (valeur jamais recopiée), ADD distant, apt non allégé, `apt-get upgrade`, ordre du cache, absence de HEALTHCHECK, `curl | sh`, build mono-étape avec compilation, port SSH, `sudo`, `cd`/WORKDIR relatif, CMD en forme shell, `chmod 777`. Gestion des continuations, commentaires et étapes nommées.
- **Compose** (`lintCompose`), règles DC001–DC010 : image non épinglée, `privileged`, capacités larges, `network_mode: host`, socket Docker monté, secret en clair, port publié sur toutes les interfaces, `depends_on` sans attente de santé, pas de politique de redémarrage, base de données sans healthcheck. Ligne du service indiquée.
- **Modèles** `node`, `python`, `dart` (serveur), `go` : multi-étapes, versions épinglées, non root, forme JSON. Chacun passe l'analyseur sans avertissement (vérifié par test). **Pas de modèle Flutter**, avec une note explicative.
- `maskSecrets` pour les journaux.

### Compagnon
- Nouvelle portée **`docker`**, accordée à part, car l'accès au démon équivaut à des droits root.
- Lecture seule : `docker.info` (diagnostic : démon, version, rootless, **avertissement groupe docker**, espace récupérable), `docker.images`, `docker.containers`, `docker.logs` (identifiant validé, 500 lignes max, **secrets masqués**).
- `docker.lint` (portée read) : analyse des Dockerfile et des fichiers compose d'un projet, note Flutter, modèle suggéré.
- `docker.scaffold` (approbation) : écrit le modèle **sans jamais écraser** un fichier existant ; refusé pour Flutter.
- **Aucune** opération `run`, `stop`, `rm`, `pull`, `exec` ou `prune` n'existe.
- La CLI affiche un message clair si le port est occupé, et `admin.token` n'est écrit qu'après l'ouverture du port.

### Application
- Académie : îles **Docker** (10 leçons, 40 questions, 7 labos, projet final) et **Docker Compose** (8 leçons, 32 questions, 6 labos, projet final) disponibles hors ligne, avec glossaires.
- Nouveau type d'exercice **« labo fichier »** : éditeur, analyse, objectifs vérifiés, indice et solution. Il valide l'exercice de la leçon et le projet final.
- Atelier : **Salle des machines Docker** (diagnostic, conteneurs, images, journaux) et onglet **Docker** de la fiche projet (constats, absence de `.dockerignore`, génération approuvée, note Flutter).

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd packages/cambuse_protocol && dart test` | `+14: All tests passed!` |
| `cd companion && dart test` | `+53: All tests passed!` (dont un diagnostic **réel en lecture seule** sur le démon Docker du PC) |
| `flutter test` | `+209 ~1: All tests passed!` (le test ignoré : cohérence JSON/source Docker, actif une fois les fichiers versionnés) |
| `flutter analyze --fatal-infos` | `No issues found!` |

Preuves notables :
- chaque labo **échoue avec son fichier de départ et réussit avec sa solution** (13 labos et 2 projets) ;
- le faux `docker` n'a reçu aucune commande destructrice ;
- un jeton dans les journaux est masqué ;
- un identifiant de conteneur piégé (`-f; rm -rf /`) est refusé ;
- la génération n'écrase jamais rien ;
- Docker absent → diagnostic explicite.

## 3. Essai réel sur le Honor (`adb reverse`, projets de démonstration)

1. Appairage avec `read, git-write, remote, docker`.
2. **Salle des machines** sur le vrai Docker du PC : « Docker 29.1.3 — 2 conteneur(s) dont 2 en marche · 57 image(s) », avertissement « groupe docker = droits root », « 1,119 Go récupérable », liste des conteneurs, journal ouvert en lecture seule. Aucun conteneur ni image de l'utilisateur n'a été modifié.
3. Projet `api-notes` (Node) : « Aucun Dockerfile » → « Générer un Dockerfile (node) » → panneau listant `+ Dockerfile (19 lignes)` et `+ .dockerignore (12 lignes)` → « Autoriser » → fichiers créés sur le PC → nouvelle analyse : « Aucun constat : bravo ».
4. Projet `carnet` (Flutter) : explication « une application Flutter… ne tourne pas dans un conteneur », sans bouton de génération.
5. Académie → Docker → leçon 7 → labo : analyse hors ligne du fichier de départ (DF002, DF015 ligne 4, DF008 avec corrections).

## 4. Défauts trouvés et corrigés

1. **Faux positif `curl | sh`** déclenché par `| sha256sum` (la vérification même que la règle recommande) : limite de mot ajoutée, avec un test de non-régression.
2. Ligne d'un service Compose pointant sur son contenu et non sur sa clé : corrigé.
3. **Démarrage sur un port occupé** : pile d'appels brute et `admin.token` orphelin → message clair et jeton écrit après l'ouverture du port.
4. Une leçon Compose ne contenait que 2 sections : complétée.

## 5. Limites

- Analyse statique uniquement : pas de lancement de conteneur ni d'exercice sur un vrai démon dans l'Académie (choix de sécurité). La pratique réelle passe par vos propres commandes.
- Les règles sont des heuristiques (pas un remplacement d'outils comme hadolint, absent de la machine).
- Pas d'inspection d'image détaillée (couches, vulnérabilités) : envisageable en phase 8 (CI, scans).
- Sur le téléphone, saisir un Dockerfile complet reste peu pratique ; le labo est plus confortable sur l'application Linux.
- Les modèles sont des points de départ à adapter (scripts de build, ports, points de santé).
