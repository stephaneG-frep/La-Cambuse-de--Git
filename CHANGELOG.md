# Changelog

Format inspiré de « Keep a Changelog ». Versions non publiées.

## [Non publié] — compléments après 1.0.0 (2026-11-14)

### Ajouté
- Synchronisation explicite de la progression entre appareils via le compagnon (portée `sync`, fusion sans perte).
- Test d'intégration sur la cible Linux (`integration_test/sync_linux_test.dart`).

### Vérifié
- Compagnon en réseau local (TLS) depuis le téléphone : appairage sans câble, refus d'une empreinte fausse.
- GitLab réel depuis le téléphone : projet privé, push sans force, merge request et ticket.

## [1.0.0] — Phase 11 : stabilisation et livraison (2026-11-14)

### Ajouté
- Guide de bord hors ligne (Paramètres → Guide de bord), guide développeur, politique de sécurité.
- Tests d'accessibilité (cibles, libellés, contraste) et texte à 200 % sur les écrans principaux.
- CI : lancement manuel, configuration gitleaks auditable, Java 17 pour le build Android.

### Corrigé
- Détection de secrets : faux positifs qui auraient bloqué des commits de code ordinaire.
- CI du dépôt (en échec depuis la phase 4) : dépendances avant l'analyse, jetons factices des tests, Java 17.
- Modèle de CI Flutter généré : Java 17 manquant pour le build de l'APK.
- Guide : cibles d'appui long trop petites sur bureau.

### Modifié
- Actions GitHub mises à jour (Node 24) dans la CI, les modèles et les labos ; dépendances transitives (dont sqlite3 3.9.1).

## Phase 10 : Capitaine automatique (2026-11-14)

### Ajouté
- Moteur de missions supervisées : étapes typées (opérations du compagnon), validation stricte des plans, point de contrôle automatique, relecture, approbation, consentement spécifique pour les actions externes, limites, pause, arrêt d'urgence, reprise après interruption, journal horodaté, rapport de fin, guide de retour arrière.
- Missions : mettre un projet sous Git, contrôle qualité Flutter, mise en place de la CI, publication.
- Plan proposé par le professeur IA (facultatif), traité comme non fiable et validé avant affichage.
- Écrans : accueil du Capitaine, Table de navigation, exécution ; base de données v4.

### Corrigé
- Barre latérale de navigation qui débordait en paysage sur téléphone.

## Phase 9 : Académie avancée (2026-11-13)

### Ajouté
- Modules Terminal Linux, GitHub, GitLab, DevOps et CI/CD, Réseaux/serveurs/cloud, Kubernetes, Terraform/OpenTofu/Ansible, Observabilité/sécurité/SRE : 79 leçons, 316 questions, 48 labos, 8 projets avec grille.
- Analyseurs hors ligne : Bash, sshd_config, nginx, GitHub Actions, GitLab CI, Kubernetes, Terraform/OpenTofu, Ansible, alertes Prometheus.
- Les 11 îles du parcours sont disponibles ; nouvelle île « Observabilité, sécurité, SRE ».

### Corrigé
- Îles GitHub/GitLab/DevOps annoncées pour des phases déjà passées ; sous-titre de la carte obsolète.
- Analyseurs : directives sshd avec chiffres, TF004 par règle d'entrée, GL003 limité à la production, lignes Kubernetes par conteneur.

## Phase 8 : CI/CD, APK de test, .deb (2026-11-13)

### Ajouté
- Modèles de CI (Flutter, Node, Python × GitHub Actions, GitLab CI) : actions épinglées par empreinte, permissions minimales, analyse des secrets, artefacts avec SHA-256.
- Compagnon : portée `build`, `ci.scaffold` (sans écrasement), `flutter.analyze/test/build.apk.debug/build.linux` approuvés, `artifacts.list` (signature APK vérifiée, ABI exécutables).
- Atelier : onglet Builds et « Cale des artefacts ».
- `tool/package_release.sh` : APK DEBUG nommé explicitement, `.deb` (application + compagnon), ZIP des sources, SBOM CycloneDX, `SHA256SUMS`, `BUILD_REPORT.md`.
- Signature release Android depuis `android/key.properties`, refus explicite en son absence ; CI du projet avec job de livraison.

### Corrigé
- Panneau d'approbation : formulation spécifique aux opérations de build ; résultat signalé par SnackBar.
- ABI : seules celles qui embarquent le moteur Flutter sont annoncées.

## Phase 7 : Docker et Compose (2026-11-13)

### Ajouté
- Analyseurs Dockerfile et Compose partagés, modèles Dockerfile sûrs, masquage des secrets des journaux.
- Compagnon : portée `docker`, diagnostic, images, conteneurs, journaux (lecture seule), analyse de projet, génération sans écrasement.
- Académie : modules Docker et Docker Compose avec « labos fichier » ; Atelier : Salle des machines et onglet Docker.

### Corrigé
- Faux positif `curl | sh` sur `| sha256sum` ; démarrage du compagnon sur un port occupé.

## Phase 6 : GitHub et GitLab (2026-11-13)

### Ajouté
- Compagnon : remotes (HTTPS, sans identifiants), analyse de ce qui serait envoyé, push sans force et pull en avance rapide (portée `remote`), jeton transmis par l'environnement et masqué.
- Clients GitHub et GitLab (dépôt, création privée, PR/MR, tickets) ; écran des jetons ; onglet Publication avec panneau de publication.

### Corrigé
- Comptage des commits d'une branche nouvelle ; liste PR/tickets après création ; confirmation invisible après défilement.

## Phase 5 : Atelier Git local (2026-11-13)

### Ajouté
- Compagnon : audit non destructif, branches, restore avec sauvegarde automatique, mise à jour du .gitignore, sauvegardes et restauration dans un nouveau dossier ; blocage des secrets à l'ajout et au commit.
- Onglet Atelier : projets, audit et plan proposé, changements et diff, historique et branches, sauvegardes.

### Corrigé
- Branche inconnue sur un dépôt sans commit ; diff périmé après commit ; en-tête trop haut sur téléphone ; affichage « 0 Ko ».

## Phase 4 : compagnon Linux (2026-11-12)

### Ajouté
- Paquet partagé `cambuse_protocol` (contrat d'API v1) et exécutable `cambuse-companion` (serve, pair, devices, revoke, audit).
- Appairage par code à usage unique, jetons courts tournants et hachés, portées, révocation, audit.
- Opérations typées sans shell, confinées aux dossiers autorisés ; mutations soumises à approbation explicite.
- Durcissement contre les dépôts piégés (hooks, fsmonitor, filtres, pagers).
- Écran Paramètres → Compagnon Linux avec panneau d'approbation ; épinglage TLS côté application.

### Corrigé
- Contexte de leçon perdu en rouvrant une conversation IA.

## Phase 3 : professeur IA (2026-11-12)

### Ajouté
- Professeur IA « Capitaine Commit » : chat contextualisé à la leçon, niveaux débutant/intermédiaire/expert, historique, arrêt en cours de réponse.
- Adaptateurs Anthropic (API Messages, flux SSE, repli serveur, refus) et compatible OpenAI.
- Clé API dans le coffre du système ; masquage des secrets avant envoi ; budget quotidien de jetons ; coût estimé par réponse.
- Paramètres → Professeur IA : fournisseur, modèle, clé, effort, budget, test de connexion sans coût de génération.
- Rendu Markdown simplifié et sûr ; base v3 (conversations) et migration v2 → v3.

### Corrigé
- Permission INTERNET ajoutée au manifeste Android principal (absente hors debug).

## Phase 2 : Académie Git (2026-11-12)

### Ajouté
- Module Git : 14 leçons, 60 questions avec corrections expliquées, 12 exercices guidés, projet final et grille d'évaluation, glossaire (25 termes). Source : `tool/content/git_module.py`.
- Bac à sable Git simulé en mémoire (aucune exécution réelle, chemins confinés, enchaînements refusés).
- Validation des leçons (quiz ≥ 70 % + exercice), meilleur score, tentatives.
- Répétition espacée (Leitner 1-2-4-8-16 jours) et écran Révisions.
- Carte des îles (10 modules, 9 annoncés « en brume » avec leur phase), recherche, glossaire.
- Reprise de la dernière leçon et progression sur le Pont ; renommage du profil.
- Schéma de base v2 et migration v1 → v2 testée.

### Corrigé
- Écran de leçon trop chargé sur téléphone : bouton d'action du quiz fixe, onglets compacts, lien « Leçon suivante » déplacé.

## Phase 1 : fondations et design (2026-11-12)

### Ajouté
- Projet Flutter Android + Linux (`fr.lacambuse.la_cambuse`).
- Thème pirate-steampunk à jetons centralisés, mode contraste renforcé ; palette vérifiée WCAG AA par tests.
- Navigation adaptative go_router : barre inférieure (< 600 px), rail latéral (≥ 600 px), rail étendu (≥ 1000 px).
- Raccourcis clavier : Ctrl+1…5 (sections), Ctrl+, (paramètres).
- Localisation FR (référence) et EN pour l'interface.
- Base Drift v1 : profils, paramètres, journal d'audit ; stockage dans le dossier de support privé.
- Profil local (création, validation, renommage consigné).
- Journal de bord : liste antichronologique, filtre par catégorie, export JSON (presse-papiers), effacement après confirmation explicite.
- Paramètres : taille du texte (85–200 %), réduction des animations, contraste renforcé, langue.
- Redactor : masquage des secrets avant écriture au journal.
- CI GitHub Actions : génération Drift vérifiée, analyse `--fatal-infos`, tests.

### Corrigé pendant la phase
- La base était créée par défaut dans `~/Documents` (comportement de `drift_flutter`) : déplacée vers le dossier de support applicatif.
- Le curseur de taille de texte écrivait en base et au journal à chaque mouvement : aperçu sans persistance, enregistrement au relâchement.

## Phase 0 — Diagnostic (2026-11-12)
- Diagnostic de l'environnement, décisions d'architecture, modèle de menaces, contrat d'API du compagnon.
