# Changelog

Format inspiré de « Keep a Changelog ». Versions non publiées.

## [Non publié] — Phase 3 : professeur IA (2026-11-12)

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
