
LA CAMBUSE DE GIT — SPEC.md
Version 1.0 — Cahier des charges
1. Vision
Application Flutter Android et Linux pour apprendre Git, GitHub, GitLab, Linux, Docker, DevOps et l'infrastructure de zéro à expert, et pour accompagner des opérations réelles sur des projets existants. Deux usages indissociables : académie pédagogique et atelier de production, plus un mode d'automatisation supervisée.
2. Public et objectifs
Débutants sans expérience, autodidactes, développeurs Flutter, candidats à l'emploi et professionnels. Français par défaut, architecture de localisation FR/EN. Accessibilité : lecteurs d'écran, navigation clavier, contraste, tailles de police, réduction des animations.
3. Plateformes et architecture
- Flutter/Dart : UI Android APK (arm64-v8a prioritaire) et Linux desktop (.deb).
- Architecture modulaire par fonctionnalités, séparation présentation/domaine/infrastructure ; gestion d'état Riverpod ou équivalent argumenté ; navigation déclarative ; injection de dépendances ; journalisation structurée.
- Base locale SQLite ou Drift pour progression, cours, exercices, projets et historique. Export/import chiffré optionnel ; sauvegardes atomiques, migrations testées.
- Le client Android ne lance PAS Docker ou les commandes hôtes sur le téléphone : il pilote un agent compagnon Linux sécurisé ou des API distantes autorisées. L'application Linux peut communiquer avec cet agent via loopback ; privilèges minimaux.
- Agent compagnon Linux : service local documenté, API versionnée, liaison explicite avec code à usage unique, authentification mutuelle ou jetons à durée courte, TLS pour accès réseau, restrictions réseau, commandes autorisées, journal d'audit. Ne jamais exposer un terminal arbitraire sur Internet.
- Exécution d'outils réels uniquement après vérification de disponibilité, des droits et de l'environnement. Fournir des alternatives lorsque l'outil manque.
4. Trois modes
Académie
Cours structurés, démonstrations, glossaire, cartes de connaissances, exercices progressifs, quiz, projets pratiques, corrections explicatives, suivi des acquis, prérequis, répétition espacée. Leçons essentielles et quiz disponibles hors ligne. Les appels IA et laboratoires distants nécessitent connectivité ou moteur local configuré.
Atelier
Choisir un dossier, détecter les langages et plateformes, analyser structure et dépendances, expliquer le plan, proposer modifications et exécuter seulement les actions autorisées. Prévisualisation des différences, sauvegardes et annulation quand possible.
Capitaine automatique
Orchestration par étapes avec plan d'exécution affiché, points de contrôle, journal horodaté, pause/reprise, rapport de fin et arrêt d'urgence. Aucune action irréversible ou externe sans consentement spécifique.
5. Parcours pédagogique de zéro à expert
Chaque module comporte objectifs, prérequis, 8 à 15 leçons minimum lors de sa livraison complète, exercices, quiz, laboratoire guidé, projet final et grille d'évaluation. Ne pas prétendre que tous les modules sont complets si seuls des écrans existent.
1. Terminal Linux, fichiers, permissions, processus, Bash, SSH.
2. Git : init, status, add, commit, log, diff, restore, branches, merge, rebase, conflits, tags, hooks.
3. GitHub : authentification sécurisée, dépôts, PR, Issues, releases, permissions, Actions.
4. GitLab : projets, merge requests, issues, runners, pipelines CI/CD.
5. Docker : architecture, images, conteneurs, registres, Dockerfile, volumes, réseaux, logs, sécurité.
6. Docker Compose : services, réseaux, variables, healthchecks, dépendances, environnements.
7. DevOps : CI/CD, tests, qualité, artefacts, versionnement, secrets, livraison, rollback.
8. Réseaux, serveurs, cloud, DNS, HTTP, TLS, observabilité, coûts.
9. Kubernetes : pods, deployments, services, ingress, config, secrets, Helm, RBAC.
10. Terraform/OpenTofu, Ansible, monitoring, supply-chain security, SRE, projets de synthèse.
    Des bacs à sable pédagogiques doivent être isolés et ne jamais lancer de commandes destructrices sur les vrais projets.
6. Agent IA pédagogique
Chat contextualisé au cours, explications à plusieurs niveaux, quiz adaptés, débogage de commandes, analyse de logs, recommandations d'exercices et correction argumentée. Fournisseurs configurables (API compatibles quand disponibles) et moteur local Ollama sur hôte accessible. Clés API stockées dans coffre sécurisé OS, jamais dans Git, logs, exports ou prompts de diagnostic. Les sorties IA sont non fiables : validation de schéma, vérification des chemins, inspection des commandes et autorisations avant exécution. L'application doit rester utilisable sans IA.
7. Chantier naval — import de projets
Parcours utilisateur : choisir dossier → détecter projet → audit non destructif → afficher plan → choisir GitHub/GitLab et visibilité → créer dépôt après confirmation → préparer .gitignore et fichiers CI → prévisualiser diff → lancer tests → construire artefacts → produire rapport.
- Flutter : flutter doctor, analyse statique, tests, dépendances, configurations Android/Linux ; ne pas modifier automatiquement les versions sans plan.
- Détecter secrets, fichiers volumineux, binaires et licences avant toute publication ; bloquer le push en cas de fuite probable.
- Initialiser Git sans écraser un dépôt existant ; préserver branches, remotes et historique ; ne jamais forcer un push par défaut.
- Créer un dépôt privé par défaut ; rendre public uniquement après validation explicite.
- GitHub/GitLab : authentification via OAuth/CLI ou jeton à portée minimale ; jamais de jeton dans les URLs, les logs ou les fichiers du projet.
- Docker facultatif, avec justification de sa pertinence ; ne pas conteneuriser Flutter pour le principe.
- Générer workflows GitHub Actions et .gitlab-ci.yml avec versions épinglées quand possible, permissions minimales, secrets CI, caches sûrs, limites de temps, vérifications de sécurité et artefacts.
- Construire Android APK debug pour tests ; release uniquement avec signature de production configurée et validée. Ne jamais présenter un APK debug comme prêt pour distribution.
- Linux .deb : compilation sur environnement Linux compatible, dépendances déclarées, métadonnées du paquet, vérification installation/désinstallation ; livrer ZIP source reproductible.
- Produire manifestes, checksums SHA-256, rapport de tests, limitations connues et liens d'artefacts.
8. Sécurité, confidentialité et consentement
- Permissions par opération, pas d'autorisation globale « tout faire » ; confirmation avant suppression, publication, changement de visibilité, création cloud payante, push, écrasement ou installation système.
- Dry-run par défaut ; diff lisible ; chemins confinés aux dossiers explicitement choisis ; protection contre traversée de chemins et liens symboliques.
- Commandes via arguments typés, jamais de concaténation shell issue d'une réponse IA ; listes d'actions autorisées ; timeout, quotas CPU/mémoire et annulation.
- Aucune exécution arbitraire de code distant ; sandbox dédiée pour exercices potentiellement dangereux ; avertissements de coûts et droits.
- Historique d'audit local, effacement/export contrôlé ; chiffrement des secrets ; collecte télémétrique désactivée par défaut.
9. Écrans
Accueil/tableau de bord, carte des apprentissages, fiche de cours, laboratoire, quiz, progression, chat professeur IA, atelier projets, analyse du projet, plan d'exécution, visualiseur diff, GitHub/GitLab, Docker, CI/CD, builds et artefacts, historique/audit, paramètres/fournisseurs IA, aide/guide, connexion agent Linux.
10. Fonctionnement hors ligne
Cours embarqués, quiz, progression et projets enregistrés disponibles hors ligne. Synchronisation explicite et résolution de conflits si activée. Opérations Git locales possibles sur Linux ; appels GitHub/GitLab, CI cloud et IA distante impossibles sans réseau ; états d'erreur pédagogiques clairs.
11. Qualité et tests
Tests unitaires (domaine, parcours, sécurité), widgets (accessibilité, navigation), intégration (stockage, authentification simulée, erreurs réseau), tests contractuels agent Linux, end-to-end sur environnement de test, tests de migration, analyse Flutter, vérification de builds Android/Linux, scans de dépendances et secrets. CI obligatoire. Les tests simulés ne remplacent pas les essais réels documentés. Rapports et preuves associés à chaque phase.
12. Critères d'acceptation MVP
- Installer APK debug sur appareil compatible et paquet .deb sur Linux cible ; démarrer sans écran blanc.
- Créer un profil local, suivre 1 module Git réellement complet, quitter/revenir sans perdre sa progression.
- Utiliser le chat IA avec fournisseur configuré, et consulter le contenu sans fournisseur.
- Importer un projet Flutter Linux, afficher audit, diff et plan sans mutation non consentie.
- Initialiser Git local, créer un dépôt privé de test GitHub ou GitLab avec consentement, puis push et rapport.
- Générer et valider un pipeline qui exécute analyse/tests et construit un APK de test ; présenter explicitement les limites de signature.
- Afficher logs, erreurs, artefacts et historique ; interruption propre et récupération après échec.
13. Livrables et définition de « terminé »
Sources ZIP, APK avec ABI identifiée, .deb compatible cible, fichiers de configuration et scripts, README, guide utilisateur, guide développeur, SPEC/DESIGN/ROADMAP, rapports de tests, SBOM si possible, sommes SHA-256, changelog et limites connues. Une phase est terminée seulement lorsque ses critères sont démontrés ; aucun faux bouton, écran vide ou simulation présentée comme fonctionnalité réelle.