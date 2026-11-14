# Guide de bord — La Cambuse de Git

Ce guide est aussi disponible hors ligne dans l'application : Paramètres → Guide de bord.

## Premiers pas

- Au premier lancement, choisissez un nom de profil : il reste sur votre appareil, aucun compte en ligne n'est créé.
- Le **Pont** résume votre progression et donne accès aux trois espaces : Académie, Atelier et Capitaine.
- Le **Journal** garde la trace de ce qui s'est passé : leçons, opérations, décisions, erreurs. Aucun secret n'y est écrit.
- Paramètres : taille du texte, contraste élevé, réduction des animations et langue.

## Académie

- **11 modules** disponibles hors ligne, du terminal Linux au SRE : Git, GitHub, GitLab, Docker, Docker Compose, DevOps, réseaux et cloud, Kubernetes, Terraform/OpenTofu/Ansible, observabilité et sécurité.
- Chaque leçon comporte un cours, un exercice et un quiz. Une leçon est validée quand l'exercice et le quiz sont réussis.
- Les **labos** se font de deux façons :
  - le **bac à sable Git** est un simulateur pédagogique qui n'exécute aucune vraie commande ;
  - les **labos fichier** (Dockerfile, script, manifeste Kubernetes, Terraform…) analysent votre fichier sans rien exécuter.
- Les **révisions** reviennent selon la répétition espacée. La **recherche** et le **glossaire** couvrent tous les modules.
- Les prérequis affichés sont des conseils : aucun module n'est verrouillé.

## Professeur IA (facultatif)

- L'application fonctionne entièrement sans IA. Le professeur est un plus.
- Paramètres → Professeur IA : choisissez Anthropic (Claude) ou un service compatible OpenAI, puis saisissez votre clé. Elle est rangée dans le coffre du système (Keystore sur Android, trousseau sur Linux), jamais dans un fichier ni dans le journal.
- Un **budget quotidien** de jetons limite la consommation, et le coût estimé de chaque réponse est noté au journal.
- Les secrets repérés dans vos questions (jetons, clés) sont **masqués avant l'envoi**.
- Les réponses de l'IA peuvent se tromper : vérifiez avant d'agir.

## Le compagnon Linux

Le téléphone ne lance jamais de commande sur votre PC par lui-même. Il passe par le **compagnon**, un petit service sécurisé qui tourne sur le PC.

```
cambuse-companion serve --root ~/Projets
cambuse-companion pair --scopes read,git-write,remote,docker,build
```

- `serve` n'autorise que les dossiers indiqués par `--root` et n'écoute que sur la machine (127.0.0.1). Avec `--lan`, il écoute aussi sur le réseau local, en TLS uniquement.
- `pair` affiche un code à 6 chiffres, valable 2 minutes et utilisable une seule fois. Saisissez-le dans Paramètres → Compagnon Linux.
- Les **portées** se donnent séparément :
  - `read` : lecture seule ;
  - `git-write` : modifications locales ;
  - `remote` : push et pull ;
  - `docker` : inspection Docker, ce qui équivaut à des droits root ;
  - `build` : analyse, tests et builds, qui exécutent du code du projet.
- Téléphone relié en USB pour le développement : `adb reverse tcp:47820 tcp:47820`, puis l'adresse `http://127.0.0.1:47820`.
- Pour révoquer un appareil : `cambuse-companion revoke <identifiant>`.

## Atelier

- La liste des projets vient des dossiers autorisés par le compagnon.
- **Audit** en lecture seule : secrets, gros fichiers, artefacts, `.gitignore`, licence.
- **Changements** : diff, ajout fichier par fichier, commit. L'ajout ou le commit est refusé si un secret est détecté.
- **Historique** et **branches** ; **Sauvegardes** : une sauvegarde se restaure toujours dans un **nouveau** dossier, rien n'est écrasé.
- **Publication** : dépôt distant, push sans force, pull en avance rapide, demandes de fusion et tickets GitHub ou GitLab. Les jetons se règlent dans Paramètres → GitHub et GitLab, avec une portée minimale.
- **Docker** : analyse des Dockerfile et des fichiers compose, et génération d'un modèle sans jamais écraser un fichier existant. La Salle des machines inspecte Docker en lecture seule.
- **Builds** : génération de CI, puis `flutter analyze`, `flutter test`, APK de test et build Linux. La **Cale des artefacts** indique taille, SHA-256, signature et ABI.
- Chaque modification ouvre un **panneau d'approbation** qui montre la commande exacte. Rien ne se fait sans « Autoriser ».

## Capitaine automatique

- Une **mission** enchaîne plusieurs opérations à votre place, sous votre supervision :
  - mettre un projet sous Git ;
  - contrôle qualité Flutter ;
  - mise en place de la CI ;
  - publication.
- La **Table de navigation** montre le plan avant le lancement : étapes, niveau de risque (lecture, point de contrôle, modification, exécution de code, action externe), relectures, conditions et limites.
- Pendant la mission :
  - une **sauvegarde** (point de contrôle) est faite avant la première modification ;
  - chaque modification est approuvée ;
  - une publication demande un **consentement spécifique**, avec une case à cocher.
- **Pause** : elle prend effet à la fin de l'étape en cours. **Arrêt d'urgence** : il annule l'opération en cours et n'exécute plus rien.
- Une mission interrompue (compagnon injoignable, application fermée) se **reprend** depuis le journal des missions. Une opération déjà lancée n'est jamais relancée à l'aveugle : son état est relu.
- En fin de mission, le **rapport** est copiable et le **retour arrière** est proposé : restauration du point de contrôle dans un nouveau dossier, et commandes expliquées pour le reste.
- Le professeur IA peut **proposer** une mission. Son plan est vérifié strictement : opérations autorisées seulement, aucun secret ni chemin hors du projet. Il ne s'exécute qu'après votre approbation.

## Ce que l'application ne fait jamais

- Lancer une commande shell libre, ni exécuter une commande écrite par l'IA.
- Faire un `git push --force`, supprimer un dépôt, publier en public ou changer des permissions sans votre accord explicite.
- Écrire un secret dans Git, dans le journal, dans un rapport ou dans un message envoyé à l'IA.
- Présenter un APK debug comme une version signée : il est nommé « DEBUG-non-distribuable ».

## Dépannage

- « Compagnon injoignable » : vérifiez que `cambuse-companion serve` tourne, que l'adresse est la bonne et, en USB, que `adb reverse` est actif.
- « Cet appareil n'a pas la portée … » : appairez de nouveau avec la portée indiquée dans `--scopes`.
- « Commit bloqué : secret détecté » : retirez la valeur du fichier, mettez-la dans une variable d'environnement ou un fichier ignoré par Git, puis révoquez le secret s'il a déjà été publié.
- « Aucun jeton GitHub » : Paramètres → GitHub et GitLab.
- Budget IA atteint : modifiable dans Paramètres → Professeur IA.

## Raccourcis clavier (Linux)

- `Ctrl+1` à `Ctrl+5` : Pont, Académie, Atelier, Capitaine, Journal.
- `Ctrl+,` : Paramètres.
