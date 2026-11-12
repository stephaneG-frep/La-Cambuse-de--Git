# Changelog

Format inspiré de « Keep a Changelog ». Versions non publiées.

## [Non publié] — Phase 1 : fondations et design (2026-11-12)

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
