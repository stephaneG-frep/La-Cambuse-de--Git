# Bilan — Phase 9 : Académie avancée

Date : 2026-11-13. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Huit nouveaux modules, hors ligne

Le parcours de SPEC §5 est désormais complet : 11 îles, toutes disponibles.

| Module | Leçons | Questions | Labos | Projet final (labo vérifié + grille) |
|---|---|---|---|---|
| Terminal Linux | 10 | 40 | 5 | Script de sauvegarde digne de la production |
| GitHub | 10 | 40 | 5 | Workflow de CI prêt pour un projet ouvert |
| GitLab | 9 | 36 | 5 | Pipeline GitLab de bout en bout |
| DevOps et CI/CD | 9 | 36 | 6 | Chaîne CI/CD complète |
| Réseaux, serveurs, cloud | 10 | 40 | 6 | Mise en production d'un site sous nginx |
| Kubernetes | 11 | 44 | 7 | Déployer une API proprement |
| Terraform, OpenTofu, Ansible | 10 | 40 | 8 | Infrastructure d'un service web avec OpenTofu |
| Observabilité, sécurité, SRE | 10 | 40 | 6 | Alertes de production pour une API |
| **Total** | **79** | **316** | **48** | **8 projets, 8 grilles de 5 critères** |

Chaque module comprend :
- des objectifs et des prérequis ;
- un glossaire de 13 à 14 termes (110 au total) ;
- des leçons avec objectifs, au moins 3 sections et 4 questions (choix unique, choix multiples, commandes) ;
- des explications pour chaque réponse.

Les prérequis sont indiqués à titre de conseil, sans verrouiller l'accès.

Le contenu est généré par des scripts Python versionnés : `tool/content/*_module.py` et `common.py`. Ces scripts valident le contenu avant d'écrire le JSON :
- longueur des explications ;
- indices des réponses ;
- nombre de sections.

### Neuf nouveaux analyseurs statiques (`packages/cambuse_protocol/lib/infra_lint.dart`)

Les labos « fichier » couvrent maintenant 11 types de fichiers. Chaque analyseur repère :

- **Bash** (SH001–SH011) : shebang, mode strict, variables non citées, `rm -r` sur une variable non protégée, `curl | sh`, `chmod 777`, `eval`, `cd` non vérifié, secret en dur, `sudo`.
- **sshd_config** (SS) : connexion root, mots de passe, mots de passe vides, X11, MaxAuthTries, absence d'AllowUsers.
- **nginx** (NG) : version annoncée, TLS obsolète, absence de HSTS, port 80 sans redirection, nosniff, autoindex.
- **GitHub Actions** (GH) : actions non épinglées, permissions absentes ou write-all, `pull_request_target` avec checkout, injection `${{ github.event… }}`, secret affiché, timeout, persist-credentials.
- **GitLab CI** (GL) : images non épinglées, secret en clair, production sans validation manuelle (la recette peut se déployer seule), artefacts sans `expire_in`, `curl | sh`.
- **Kubernetes** (K8), sur des fichiers multi-documents :
  - image, ressources, utilisateur non root, privilégié, élévation de privilèges, racine en lecture seule ;
  - sondes, secret en clair, hostNetwork/hostPath ;
  - Service exposé publiquement, réplique unique, Secret versionné.
- **Terraform/OpenTofu** (TF) :
  - versions de l'outil et des fournisseurs, secret en dur ;
  - SSH/RDP ouvert à 0.0.0.0/0, analysé **règle d'entrée par règle d'entrée** ;
  - variable sensible non marquée, état local, stockage public, variable sans type.
- **Ansible** (AN) : tâches sans nom, shell au lieu du module dédié, secret en clair, `no_log` absent, `state: latest`, `ignore_errors`, commande toujours « changed ».
- **Règles d'alerte Prometheus** (PR) : `for`, sévérité, résumé, runbook, expression.

Garanties :
- Aucune valeur secrète n'est recopiée dans les messages, ce qui est vérifié par test.
- Rien n'est exécuté.
- Ce sont des heuristiques pédagogiques ; elles ne remplacent pas shellcheck, kube-linter, tflint ou ansible-lint.

### Application
- Catalogue : les 11 îles sont disponibles. Ajout de l'île « Observabilité, sécurité, SRE ». Le sous-titre de la carte n'annonce plus d'« îles en brume ».
- Les labos acceptent les 11 types de fichiers, avec un nom de fichier propre à chaque type.
- Le bandeau de labo indique : « rien n'est exécuté (aucun conteneur, script ni cluster) ».

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd packages/cambuse_protocol && dart test` | `+35: All tests passed!` (dont 14 tests des nouveaux analyseurs) |
| `cd companion && dart test` | `+58: All tests passed!` |
| `flutter test` | `+307: All tests passed!` |
| `flutter analyze --fatal-infos`, `dart analyze --fatal-infos` (protocole) | `No issues found!` |

Preuves notables :
- **Les 48 labos et les 8 projets échouent avec leur fichier de départ et réussissent avec leur solution** (`test/academy/advanced_content_test.dart`, 89 tests).
- Le même test vérifie la structure de chaque module et l'unicité des identifiants. Il vérifie aussi que les JSON sont identiques à leur source Python.
- Trois labos sont joués de bout en bout dans l'interface : Kubernetes, sshd et Terraform. Le départ est refusé, la solution saisie est acceptée et l'exercice est enregistré en base.
- Chaque île du catalogue a un module embarqué valide.
- **Les modèles de CI que La Cambuse génère (phase 8) passent l'analyseur GitHub Actions sans avertissement.**
- La recette peut se déployer automatiquement ; seule la production est signalée par GL003.

## 3. Essai réel sur le Honor

1. La carte des îles affiche les 11 modules « Disponible hors ligne », avec leurs prérequis, et le nouveau sous-titre.
2. Parcours Kubernetes → leçon 2 « Pods et kubectl » → Exercice.
   - « Analyser » sur le fichier de départ : K8001 (image sans version), K8002, K8003, K8005, K8011, K8006.
   - Correction **tapée sur le téléphone** (`nginx` → `nginx:1.27.3`), puis nouvelle analyse : « Labo réussi ! ». Les autres constats restent affichés à titre pédagogique.
3. Terraform → leçon 3 → Exercice → « Analyser » :
   - « Bloquant · TF003 · Secret écrit en dur dans password (**valeur masquée**) » à la ligne 24 ;
   - TF005 à la ligne 15 ; TF006 en information.

## 4. Défauts trouvés et corrigés

1. sshd : une directive contenant un chiffre (`X11Forwarding`) était jugée invalide. La regex est corrigée.
2. TF004 jugeait la ressource entière : une règle 443 publique déclenchait l'alerte SSH. L'analyse se fait désormais règle d'entrée par règle d'entrée, avec un test de non-régression.
3. GL003 exigeait une validation manuelle pour la recette elle-même. Seule la production est visée désormais.
4. SH003 manquait `/chemin/$VAR`.
5. Kubernetes : tous les constats pointaient vers la ligne `kind` (« ligne 2 »). Ils indiquent maintenant la ligne du conteneur concerné. Le fichier s'appelle `manifeste.yaml`, et non plus `deployment.yaml` pour un Pod.
6. Le sous-titre de la carte annonçait des « îles en brume » qui n'existent plus.
7. Les îles GitHub, GitLab et DevOps annonçaient des phases (6 et 8) déjà passées sans contenu : cette affirmation était fausse. Les modules sont maintenant livrés.
8. Le cache Python des générateurs est ignoré par Git.

## 5. Limites

- **Contenu rédigé par l'IA**, vérifié par des tests de structure et des labos réalisables, mais **non relu par un expert humain** de chaque domaine. Une relecture est recommandée avant un usage pédagogique large.
- Certains éléments datent vite et seront à réviser régulièrement :
  - versions d'images et de fournisseurs ;
  - empreintes d'actions (épinglées au 2026-11-13) ;
  - options comme `use_lockfile` (verrouillage S3 natif des versions récentes).
- Les labos sont **statiques** : aucun cluster, conteneur, script ni playbook n'est exécuté. C'est un choix de sécurité. La pratique réelle demande un environnement personnel (kind, minikube, une VM).
- Les questions « commande » n'acceptent qu'une liste finie de variantes.
- Le professeur IA n'a **pas été réessayé** sur les nouveaux modules. Le bouton « Demander au professeur » est présent sur leurs leçons et reçoit le contexte de la leçon comme pour les modules existants, mais aucun appel réel n'a été fait dans cette phase.
- Il n'y a pas de projet de synthèse transversal à plusieurs modules. Chaque module a son projet final.
- Saisir un fichier long sur téléphone reste peu pratique : l'application Linux est plus confortable pour les gros labos.
