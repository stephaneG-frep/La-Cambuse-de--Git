# Rapport final — La Cambuse de Git 1.0.0

Date : 2026-11-14. Projet mené en 12 phases (0 à 11), une phase validée à la fois. Chaque bilan de phase (`docs/PHASEn_BILAN.md`) détaille les commandes réellement exécutées et les essais sur appareil.

## 1. Ce qui est livré

**Application Flutter** pour Android et Linux, interface en français et en anglais :

- **Académie** : 11 modules hors ligne, du terminal Linux au SRE.
  - 111 leçons, 448 questions ;
  - 61 labos fichier et 12 exercices de bac à sable, tous rejoués automatiquement ;
  - 11 projets finaux avec grille d'évaluation ;
  - répétition espacée, recherche, glossaire.
- **Professeur IA facultatif** :
  - fournisseurs Anthropic et compatible OpenAI ;
  - clé rangée dans le coffre du système ;
  - budget quotidien, coût affiché, masquage des secrets avant envoi.
- **Compagnon Linux** (`cambuse-companion`) :
  - API v1, appairage par code ;
  - portées séparées, opérations typées et approuvées ;
  - journal d'audit, TLS sur le réseau local.
- **Atelier** :
  - audit, diff, commits fichier par fichier, branches, sauvegardes ;
  - publication GitHub/GitLab (push sans force, PR/MR, tickets) ;
  - Docker en lecture seule et génération sans écrasement ;
  - CI générée, builds approuvés, Cale des artefacts.
- **Capitaine automatique** : missions supervisées avec point de contrôle, approbations, consentement spécifique, limites, pause, arrêt d'urgence, reprise, rapport et retour arrière. Un plan peut être proposé par l'IA ; il est alors validé comme non fiable.
- **Guide de bord** hors ligne.

### Couverture des écrans demandés (SPEC §9)

Tous les écrans listés existent et fonctionnent :

| Écran demandé | Réalisation |
|---|---|
| Accueil | Pont |
| Carte des apprentissages | Carte des îles |
| Fiche de cours, laboratoire, quiz | Leçons de l'Académie |
| Progression | Jauges et révisions |
| Chat professeur IA | Professeur IA |
| Atelier projets, analyse du projet | Atelier : liste des projets et audit |
| Plan d'exécution | Table de navigation du Capitaine |
| Visualiseur diff | Onglet Changements |
| GitHub/GitLab | Onglet Publication et Paramètres → GitHub et GitLab |
| Docker | Salle des machines et onglet Docker |
| CI/CD, builds et artefacts | Onglet Builds et Cale des artefacts |
| Historique/audit | Journal, journal des missions, Historique Git |
| Paramètres/fournisseurs IA | Paramètres → Professeur IA |
| Aide/guide | Guide de bord |
| Connexion agent Linux | Paramètres → Compagnon Linux |

## 2. Critères d'acceptation MVP (SPEC §12)

| Critère | État | Preuve |
|---|---|---|
| APK debug installé sur appareil, `.deb` sur Linux, démarrage sans écran blanc | voir §6 | APK installé et démarré sur Honor MTN-NX1M (phases 1 à 11) ; application Linux release démarrée en 228 ms |
| Profil local, un module Git complet, progression conservée | ✅ | Phase 2, base relue après redémarrage sur le Honor |
| Chat IA avec fournisseur ; contenu consultable sans fournisseur | ✅ | Phase 3, claude-opus-5-5 en réel |
| Import d'un projet Flutter, audit, diff et plan sans mutation non consentie | ✅ | Phases 5 et 10 |
| Git local, dépôt privé de test avec consentement, push, rapport | ✅ | Phase 6 : push, PR #1, ticket #2 ; phase 11 : dépôt privé et CI |
| Pipeline analyse/tests et APK de test, limites de signature affichées | ✅ | Phase 8 (pipeline généré et builds) ; phase 11 : CI du projet **verte sur GitHub** |
| Journaux, erreurs, artefacts, historique ; interruption propre et récupération | ✅ | Phases 8 et 10 : arrêt d'urgence réel, reprise après redémarrage |

## 3. Livrables (SPEC §13)

| Livrable | Emplacement |
|---|---|
| ZIP des sources | `dist/la-cambuse-1.0.0-sources.zip` (`git archive` du commit) |
| APK avec ABI identifiée | `dist/la-cambuse-1.0.0-arm64-v8a-DEBUG-non-distribuable.apk`. **APK de test** signé avec la clé debug (`CN=Android Debug`), ABI exécutable arm64-v8a |
| `.deb` compatible avec la cible | `dist/la-cambuse_1.0.0_amd64.deb` (application et compagnon) ; dépendances calculées par `dpkg-shlibdeps` |
| Configuration et scripts | `tool/package_release.sh`, `.github/workflows/ci.yml`, `.gitleaks.toml`, `companion/systemd/` |
| README, guides | [README.md](../README.md), [GUIDE_UTILISATEUR.md](GUIDE_UTILISATEUR.md), [GUIDE_DEVELOPPEUR.md](GUIDE_DEVELOPPEUR.md), [SECURITY.md](../SECURITY.md) |
| SPEC, DESIGN, ROADMAP | à la racine |
| Rapports de tests | bilans de phase, `dist/BUILD_REPORT.md`, exécutions de la CI |
| SBOM | `dist/sbom.cdx.json` (CycloneDX 1.5) |
| Sommes SHA-256 | `dist/SHA256SUMS` |
| Changelog et limites connues | [CHANGELOG.md](../CHANGELOG.md), §7 ci-dessous |

## 4. Tests

| Suite | Résultat |
|---|---|
| Application (`flutter test`) | **343** tests réussis : domaine, widgets, accessibilité, migrations v1 → v4, scénarios de défaillance du Capitaine, labos rejoués |
| Compagnon (`dart test`) | **58** réussis : sécurité de l'API, confinement, appairage, audit, opérations réelles sur dépôts de test |
| Protocole (`dart test`) | **39** réussis : analyseurs, détection de secrets, modèles de CI |
| Analyse statique | aucun problème sur les trois projets |
| CI GitHub | exécution `43637187905` : secrets ✓, analyse et tests ✓, livraison ✓ |

Les essais réels, documentés phase par phase, ont porté sur le Honor MTN-NX1M (Android, arm64) et sur un PC Ubuntu 22.04 (x86_64) :
- installation, apprentissage et IA réelle ;
- compagnon et Atelier ;
- push GitHub réel ;
- Docker en lecture seule ;
- builds ;
- missions du Capitaine, y compris un arrêt d'urgence pendant un build.

## 5. Sécurité

- Modèle de sécurité : [SECURITY.md](../SECURITY.md). Il couvre l'absence de shell libre, les opérations typées, l'approbation des mutations, l'absence de push forcé, le coffre de secrets, le compagnon confiné et la sortie IA non fiable.
- Audit de la phase 11 : aucun vrai secret dans l'historique ; gitleaks vert en CI ; actions épinglées par empreinte de commit ; dépendances à jour ; SBOM livré.

## 6. Installation du paquet `.deb`

*(Complété après l'installation sur ce PC, voir la fin de ce document.)*

## 7. Limites connues

- **APK debug uniquement** : aucune release signée, par choix. La procédure de signature est documentée (`android/key.properties`, avec refus explicite sans ce fichier).
- **GitLab** : client testé sur serveur simulé, pas sur un vrai GitLab.
- **Compagnon en réseau local (TLS)** : testé automatiquement, **jamais essayé depuis le téléphone**. Les essais réels sont passés par `adb reverse`.
- **Moteur IA local (Ollama)** : couvert par le fournisseur « compatible OpenAI », testé sur serveur simulé seulement.
- **Synchronisation entre appareils** (SPEC §10, « si activée ») : **non implémentée**. Toutes les données restent locales à chaque appareil.
- **Contenu des modules avancés** (phase 9) : rédigé par l'IA, vérifié par tests et labos réalisables, **non relu par un expert humain**.
- Les labos sont statiques : aucun conteneur, cluster ni script n'est exécuté.
- Guide de bord et cours en français uniquement ; interface en français et en anglais.
- Pas d'illustrations du personnage Capitaine Commit, et pas de panneaux redimensionnables sur Linux (prévus par DESIGN.md).
- Capitaine : mission CI et restauration du point de contrôle non rejouées en réel depuis le Capitaine ; aucun push réel par une mission.
- Un échec isolé de la suite du compagnon a été observé une fois en phase 8, sans être reproduit depuis.
- Le dépôt public `La-Cambuse-de--Git` contient la version de la phase 10, dont la CI échoue. Les corrections sont sur le dépôt privé et en local ; il reste à les pousser si vous le décidez.
