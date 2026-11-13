# Bilan — Phase 5 : Atelier Git local

Date : 2026-11-13. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Compagnon : nouvelles opérations typées

| Opération | Portée | Approbation | Rôle |
|---|---|---|---|
| `project.audit` | read | non | audit **en lecture seule** : secrets (contenu et noms de fichiers), fichiers > 10 Mo / > 100 Mo, artefacts compilés, `.gitignore` absent ou incomplet, licence, état Git |
| `git.branches` | read | non | liste des branches |
| `backup.list` | read | non | sauvegardes du projet |
| `project.backup` | git-write | non (non destructif) | archive tar.gz du projet (`.git` inclus, dossiers générés exclus) dans le dossier privé du compagnon |
| `git.branch.create`, `git.switch` | git-write | oui | branches (noms validés) |
| `git.restore` | git-write | oui | `--staged` non destructif ; sinon **sauvegarde automatique** des fichiers avant écrasement |
| `gitignore.update` | git-write | oui | ajoute seulement les lignes manquantes ; plan listant chaque ligne ; écriture atomique |
| `backup.restore` | git-write | oui | restauration **dans un nouveau dossier** frère du projet ; rien n'est écrasé |

Blocage des secrets : `git.add` analyse les fichiers (nom et contenu) et `git.commit` analyse le **contenu indexé** juste avant l'exécution (l'index a pu changer depuis la demande). La valeur du secret n'est jamais renvoyée, seulement le fichier, la ligne et le type.

Correction trouvée par les tests : la branche d'un dépôt sans commit apparaissait `null` (`rev-parse` échoue) → `symbolic-ref`.

### Application : onglet Atelier (« Chantier naval »)

- Sans compagnon : explication et accès à la configuration.
- Projets des dossiers autorisés (badge Git) → fiche projet en 4 onglets :
  - **Audit** : constats triés par gravité (icône + libellé, pas seulement la couleur), statistiques, **plan proposé** exécutable étape par étape (sauvegarde → init → .gitignore → commit ; bloqué tant qu'un problème bloquant subsiste) ;
  - **Changements** : état porcelaine, sélection, **visualiseur de diff** (numéros de ligne, +/−), indexer, désindexer, annuler (sauvegarde automatique), commit ;
  - **Historique** : branches, bascule, création, derniers commits ;
  - **Sauvegardes** : liste, sauvegarde immédiate, restauration dans un nouveau dossier.
- Chaque mutation passe par le panneau d'approbation (commande exacte) et est consignée au journal de bord.

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd companion && dart test` | `+39: All tests passed!` (dont 12 nouveaux sur de vrais dépôts jetables) |
| `flutter test` | `+174: All tests passed!` (analyseurs Git, 6 tests de widgets de l'Atelier, accessibilité) |
| `flutter analyze --fatal-infos` | `No issues found!` |

Preuves notables : **empreinte de l'arborescence identique avant et après l'audit** ; valeurs secrètes absentes des réponses ; commit refusé à l'exécution quand un secret a été indexé hors application (aucun commit créé) ; restauration d'une sauvegarde d'un autre projet ou d'un identifiant piégé (`../../etc`) refusée ; `.gitignore` lien symbolique vers l'extérieur refusé (fichier extérieur intact).

## 3. Essai réel sur le Honor (via `adb reverse`, projet de démonstration jetable `carnet`)

1. Audit : « fichier .env non ignoré », « mot de passe en clair probable (valeur masquée) .env:1 », « Pas de .gitignore ». Rien n'a été modifié.
2. Plan : sauvegarde (archive créée) → `git init --initial-branch=main` approuvé (`.git` créé) → `.gitignore` : 11 lignes listées puis ajoutées après approbation. Nouvel audit : `.env` passé en « info, déjà ignoré », plus aucun problème bloquant.
3. Changements : `git add -- .gitignore README.md lib/main.dart pubspec.yaml` approuvé → commit « Premier commit du carnet » approuvé → `1407401` sur le PC, copie de travail propre, `.env` jamais versionné.
4. Faux jeton GitHub ajouté sur le PC → indexation **bloquée** : « Secret probable détecté : opération bloquée. lib/cle.dart:1 — jeton GitHub » ; index vide sur le PC.
5. README modifié sur le PC → « Annuler les modifications » (panneau annonçant la sauvegarde automatique) → README revenu à la version validée → sauvegarde « Fichiers (1) — Avant git restore » → restauration dans `carnet-restauration-20261113-072420`, qui contient bien le travail annulé ; l'original n'a pas été touché.

## 4. Défauts trouvés et corrigés

1. Branche `null` sur un dépôt neuf (audit) : corrigé.
2. Diff périmé encore affiché après un commit : effacé après chaque mutation réussie.
3. Sur téléphone, le chemin du projet occupait 5 lignes d'en-tête : chemin abrégé sur une ligne, chemin complet annoncé aux lecteurs d'écran (vérifié sur le Honor).
4. « 0 Ko » pour un petit projet : affichage en octets sous 1 Ko.
5. L'appairage d'hier était invalide (fichier des appareils du compagnon supprimé par un nettoyage du dossier temporaire) : l'application a affiché « Jeton de rafraîchissement invalide ou révoqué », puis « Oublier » et un nouvel appairage ont fonctionné.

## 5. Limites

- Le scanner de secrets repose sur des motifs : faux positifs et faux négatifs possibles. Il n'y a pas d'exception manuelle pour l'instant (corriger le fichier ou l'ignorer).
- Pas de visualisation du contenu des fichiers non suivis dans le diff (indexer d'abord).
- Pas de fusion ni de résolution de conflits dans l'Atelier (enseignées dans l'Académie) ; pas de `revert`/`reset`.
- La sauvegarde complète est limitée à 500 Mo (hors dossiers générés).
- L'Atelier sur l'application Linux passe aussi par le compagnon (loopback). Il est testé par les tests de widgets, pas par une saisie réelle sur le bureau (pas d'outil d'automatisation du bureau).
