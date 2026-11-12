
LA CAMBUSE DE GIT — ROADMAP.md
Version 1.0 — Développement incrémental et contrôlé
Règles transversales
Une phase = fonctionnalités réelles, tests, démonstration, documentation, commit dédié et bilan en français. Ne jamais déclarer « terminé » sans preuve. Ne pas inventer de sorties de tests ni de livrables. Prioriser un MVP vertical fonctionnel avant l'étendue du catalogue.
Phase 0 — Audit environnement et cadrage
Vérifier Flutter, Dart, Android SDK, Linux packaging, Git, CLI GitHub/GitLab, Docker et permissions. Définir architectures, menaces, contrats d'API, contraintes de signature, matrice OS et critères d'acceptation. Livrer diagnostic et décisions.
Phase 1 — Fondations et design
Créer projet Flutter, thèmes, navigation Android/Linux, composants, i18n FR, accessibilité, persistance locale et CI analyse/tests. Écran d'accueil et journal de bord fonctionnels.
Phase 2 — Académie Git complète (MVP pédagogique)
Leçons Git progressives, quiz, exercices guidés sûrs, corrections, progression persistante, reprise après redémarrage et mode hors ligne. Tests d'apprentissage.
Phase 3 — Agent IA pédagogique
Abstraction fournisseurs, configuration sécurisée, chat contextualisé, mode sans IA, limites de coûts, gestion erreurs et protections contre injection de prompt. Vérifier réponses et exercices.
Phase 4 — Compagnon Linux sécurisé
Service local, authentification/appairage Android, permissions par action, API versionnée, logs, timeouts, annulation et sandbox. Tests contractuels et de sécurité.
Phase 5 — Atelier Git local
Import dossier, analyse non destructive, diff, status, init, commit, branches, logs, sauvegardes, validations et restauration possible. Tests sur dépôts jetables.
Phase 6 — GitHub et GitLab
Connexion à portée minimale, création dépôts privés, push/pull, PR/MR, issues, gestion erreurs et secrets. Tests avec dépôts de démonstration et confirmation explicite.
Phase 7 — Docker et Compose
Cours, exercices isolés, analyse de Dockerfile, génération de configurations, inspection d'images/conteneurs, diagnostics et sécurité. Ne pas nécessiter Docker pour toutes les applications Flutter.
Phase 8 — CI/CD et builds Flutter
Génération de GitHub Actions et GitLab CI, tests/analyse, compilation APK debug, packaging .deb, rapports, checksums, vérification artefacts et gestion signature release séparée.
Phase 9 — Académie avancée
Modules Linux avancé, DevOps, réseaux, Kubernetes, Terraform/OpenTofu, Ansible, observabilité et sécurité ; laboratoires progressifs et projets de synthèse.
Phase 10 — Capitaine automatique
Planification multi-étapes, approbations, pause/reprise, diff, limites d'exécution, rollback partiel documenté et rapports de décisions. Scénarios de défaillance obligatoires.
Phase 11 — Stabilisation et livraison
Audit global, tests Android physique + Linux cible, sécurité, performance, UX, documentation, ZIP sources, APK, .deb, checksums et rapport final. Aucun artefact debug présenté comme release signée.
À chaque fin de phase
1. Liste des fichiers modifiés et fonctionnalités réellement testées.
2. Commandes de test et résultats exacts (ou mention explicite « non exécuté »).
3. Captures ou descriptions vérifiables des écrans et workflows.
4. Problèmes ouverts, risques et corrections proposées.
5. Mise à jour README, CHANGELOG et matrice d'acceptation.
6. Ne poursuivre que si les prérequis techniques de la phase suivante sont satisfaits ; sinon corriger d'abord.