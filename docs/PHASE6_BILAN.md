# Bilan — Phase 6 : GitHub et GitLab

Date : 2026-11-13. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Compagnon
| Opération | Portée | Approbation | Détail |
|---|---|---|---|
| `git.remote.list` | read | non | `git remote -v` |
| `git.outgoing` | read | non | ce que contiendrait un push : commits **absents de tout le dépôt distant**, fichiers, secrets et fichiers ≥ 100 Mo sur **tout l'historique** concerné |
| `git.remote.add` | git-write | oui | HTTPS vers un hôte autorisé uniquement (github.com, gitlab.com, `--remote-host`) ; URL avec identifiants refusée ; remote existant préservé |
| `git.push` | **remote** (nouvelle portée) | oui | `git push --porcelain <remote> refs/heads/b:refs/heads/b` ; **aucun `--force` possible** ; analyse des secrets de l'historique envoyé juste avant l'exécution |
| `git.pull` | remote | oui | `--ff-only --no-rebase` |

Jeton : paramètre secret transmis pour une seule opération. Il n'est jamais stocké, renvoyé, journalisé ni mis dans le plan ou l'URL. Il est fourni à Git par l'environnement (`GIT_CONFIG_*`, en-tête HTTP), avec `credential.helper=` vide pour ne **pas** réutiliser les identifiants du PC (par exemple le jeton `gh` aux droits complets), puis masqué dans toutes les sorties.

### Application
- Client des forges `GitHubForge` / `GitLabForge` (API REST) : utilisateur, dépôt (visibilité, branche par défaut), **création de dépôt toujours privée**, PR/MR, tickets ; erreurs typées (401, 403 droits ou limite de débit, 404, 422 détaillée, réseau) ; messages expurgés.
- Paramètres → GitHub et GitLab : jetons dans le coffre du système, URL d'instance GitLab, test de connexion.
- Atelier → onglet **Publication** :
  - association de `origin` (approbation) ou création d'un dépôt privé (confirmation explicite) ;
  - fiche du dépôt avec badge PRIVÉ ou PUBLIC ;
  - **panneau de publication** : dépôt, visibilité, avertissement si public, branche (nouvelle ou non), commits, fichiers, résultat de l'analyse des secrets, commande exacte. Bouton « Publier » absent en cas de secret ou s'il n'y a rien à envoyer ;
  - pull en avance rapide ; demandes de fusion et tickets (liste et création).
- Pas de changement de visibilité dans l'application (décision volontairement laissée à la forge).

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `cd companion && dart test` | `+47: All tests passed!` |
| `flutter test` | `+185: All tests passed!` |
| `flutter analyze --fatal-infos` | `No issues found!` |

Preuves notables :
- push réel vers un dépôt nu local ;
- **secret ajouté puis supprimé dans un commit ultérieur → push bloqué, rien publié** ;
- branche nouvelle : seuls les commits réellement nouveaux comptent ;
- jeton absent → refus ;
- avec un faux `git` qui affiche son environnement : jeton et en-tête masqués dans les sorties, helpers désactivés, rien dans l'audit ;
- URL refusées : identifiants, `http://`, hôte inconnu, SSH, `ext::` ;
- client des forges : en-têtes, création forcée en privé, PR exclues de la liste des tickets, erreurs, message contenant un jeton masqué, projets GitLab imbriqués.

## 3. Essai réel (Honor + GitHub)

Dépôt **privé** `stephaneG-frep/cambuse-depot-test`, créé via `gh` avec l'accord explicite de l'utilisateur. Jeton fine-grained limité à ce seul dépôt (Contents, Pull requests, Issues), saisi par l'utilisateur dans l'application ; test : « Connecté à GitHub en tant que stephaneG-frep ».

1. Association : `git remote add origin https://github.com/stephaneG-frep/cambuse-depot-test.git` approuvé ; API GitHub : badge **PRIVÉ**.
2. Panneau de publication de `main` : branche nouvelle, 1 commit, 4 fichiers (le `.env` ignoré n'y figure pas), aucun secret, commande exacte → « Publier » → commit `bb3c18d` présent sur GitHub (vérifié par `gh api`).
3. Depuis le téléphone :
   - branche `fonction/notes` créée puis basculée ;
   - `NOTES.md` indexé et validé (`1c03ff0`) ;
   - branche publiée → GitHub : branches `fonction/notes` et `main`.
4. **PR #1 « Notes du projet » [fonction/notes → main]** et **ticket #2** créés via l'API, vérifiés par `gh pr list` / `gh issue list`.
5. Aucune trace du jeton dans les fichiers du compagnon (`grep` : aucune).

## 4. Défauts trouvés et corrigés

1. **Comptage des commits d'une branche nouvelle** (vu pendant l'essai : 2 au lieu de 1) : les commits déjà présents sur le dépôt distant sont désormais exclus (`--not --remotes`), ce qui affine aussi l'analyse des secrets.
2. **PR/ticket créés mais absents de la liste** juste après la création (listage de l'API GitHub en léger retard) : l'élément créé est ajouté directement.
3. **Confirmation de publication invisible** quand la liste avait défilé : notification en bas d'écran et message sous les boutons d'action.
4. Barre d'onglets de la fiche projet : le 5e onglet est hors écran sur téléphone (barre défilante) ; c'est fonctionnel, mais à surveiller.

## 5. Limites

- **GitLab non testé en réel** (pas de compte ni de jeton fournis) : seulement contre un serveur HTTP simulé.
- La création de dépôt par l'application n'a pas été testée en réel (le jeton limité ne le permet pas, par choix de sécurité) ; le dépôt de test a été créé via `gh`.
- `git.outgoing` se fonde sur l'état local des branches distantes (pas de `fetch` préalable).
- Le clavier du téléphone a autocorrigé les titres et messages saisis (« Ajouté », accents) : comportement du clavier, laissé à l'utilisateur.
- Le dépôt de test, la PR #1 et le ticket #2 existent toujours sur GitHub (privés). Le jeton expire de lui-même sous 7 jours.
