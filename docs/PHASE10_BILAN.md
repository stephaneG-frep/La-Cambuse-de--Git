# Bilan — Phase 10 : Capitaine automatique

Date : 2026-11-14. Toutes les commandes listées ont réellement été exécutées.

## 1. Livré

### Moteur (`lib/features/captain/domain/`, Dart pur, testé)

- **Missions = étapes typées** : uniquement des opérations du compagnon, jamais de shell. Une liste blanche limite ce qu'une mission peut contenir. En sont exclues :
  - `git.restore`, qui jette des modifications ;
  - `backup.restore`, réservée au retour arrière ;
  - `git.pull` ;
  - les opérations hors projet.
- **Niveau de risque par étape** : lecture, point de contrôle, modification, exécution de code, action externe. Il est toujours affiché avec une icône et un texte, jamais par la couleur seule.
- **Validation stricte de tout plan** avant exécution :
  - schéma des paramètres par opération, champs inconnus refusés ;
  - chemins relatifs uniquement, sans `..`, sans joker ni chemin absolu ;
  - **aucun secret dans un plan** ;
  - résolveurs et conditions limités à une liste connue ;
  - identifiants uniques ;
  - limites de taille.
- **Point de contrôle automatique** : une sauvegarde complète du projet est insérée avant la première modification.
- **Paramètres calculés à l'exécution** par des résolveurs purs : lignes manquantes du `.gitignore`, fichiers à ajouter, branche courante, modèle de CI. Le **jeton de forge** est lu dans le coffre au dernier moment. Il est transmis au compagnon, et jamais affiché, journalisé ni enregistré.
- **Conditions** (`when`, étape ignorée et expliquée) et **prérequis** (`requires`, arrêt propre sans rien modifier de plus).
- **Garde-fous humains** :
  - relecture avant les étapes sensibles ;
  - approbation du compagnon pour chaque modification ;
  - **consentement spécifique** pour toute action externe, avec une case « je comprends » obligatoire.
- **Limites d'exécution** :
  - nombre d'étapes et de modifications ;
  - durée totale ;
  - délai par opération (6 min, et 26 min pour un build) ; une opération qui dépasse son délai est annulée sur le compagnon.
- **Pause** coopérative entre deux étapes ; **reprise**.
- **Arrêt d'urgence** :
  - il annule l'opération en cours sur le compagnon ;
  - il attend jusqu'à 15 s la confirmation, le temps que le compagnon tue le processus ;
  - il rejette une demande d'approbation en attente ;
  - il n'exécute plus rien ensuite.
- **Persistance après chaque étape** (base v4, tables `captain_runs` et `captain_events`) :
  - une mission « en cours » au moment d'un redémarrage est relue comme **interrompue** ;
  - à la reprise, l'état d'une opération déjà lancée est **relu**, jamais relancé à l'aveugle.
- **Journal horodaté** de chaque événement et décision.
- **Rapport de fin** en Markdown : étapes, risques, durées, décisions, point de contrôle, journal. Il est conservé et copiable.
- **Retour arrière partiel documenté** :
  - restauration du point de contrôle **dans un nouveau dossier**, exécutable depuis l'application avec approbation ;
  - commandes manuelles expliquées pour le reste : `git reset --soft HEAD~1` ou `git revert`, `git restore --staged` ;
  - mention explicite qu'une publication n'est **pas annulable automatiquement**.

### Missions prédéfinies, sans IA
1. **Mettre le projet sous Git** : détection, audit, point de contrôle, `.gitignore`, `git init` si besoin, état, ajout fichier par fichier après relecture, commit.
2. **Contrôle qualité Flutter** : `flutter analyze`, `flutter test`, APK de test (debug), cale des artefacts. Arrêt au premier échec ; refus propre si le projet n'est pas un projet Flutter.
3. **Mettre en place la CI**, sur GitHub Actions ou GitLab CI : pipeline généré sans écrasement, relu et commité.
4. **Publier la branche courante** : analyse de ce qui partirait, arrêt si un secret s'y trouve, relecture, consentement spécifique, push sans force.

### Plan proposé par le professeur IA (facultatif)
- Consigne qui énumère les seules opérations autorisées.
- Réponse traitée comme **non fiable** : JSON strict, champs inconnus refusés, même validation que ci-dessus, point de contrôle inséré d'office, limites réduites (6 modifications au plus).
- Le service de conversation existant est réutilisé : budget quotidien, masquage des secrets, coût journalisé. Le coût est affiché.
- Le plan passe ensuite par la même Table de navigation et la même approbation.

### Interface
- Onglet **Capitaine** : missions, proposition IA, mission en cours (avec « Une décision vous attend »), journal des missions.
- **Table de navigation** (écran signature n° 4 de DESIGN.md) : étapes, risques, relectures, consentements, conditions, prérequis, limites, coût IA. Le lancement exige un projet choisi et un plan valide.
- **Écran d'exécution** :
  - jauge d'avancement ;
  - Pause, Reprendre et Arrêt d'urgence ;
  - panneau de décision intégré : approbation avec la commande exacte, relecture avec la liste des fichiers ou des commits, consentement ;
  - journal horodaté ;
  - retour arrière et rapport.

### Correctif hors périmètre trouvé pendant l'essai
- **Navigation en paysage sur téléphone** : la barre latérale débordait de 75 px (« RenderFlex overflowed »), alors que DESIGN.md exige le mode paysage.
- Le rail défile désormais et n'affiche que le libellé de la destination active quand la hauteur est faible.
- Un test reproduit le débordement sans la correction et passe avec.

## 2. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `flutter test` | `+339: All tests passed!` |
| `flutter test test/captain/engine_test.dart` | `+20` (scénarios de défaillance) |
| `flutter test test/captain/ai_plan_test.dart` | `+4` |
| `flutter test test/captain/repository_test.dart` | `+2` |
| `flutter test test/widget/captain_test.dart` | `+4` (parcours dans l'interface) |
| `cd companion && dart test` | `+58: All tests passed!` |
| `cd packages/cambuse_protocol && dart test` | `+35: All tests passed!` |
| `flutter analyze --fatal-infos` | `No issues found!` |

**Scénarios de défaillance testés**, chacun avec la preuve que rien d'autre n'est soumis au compagnon :

| Scénario | Résultat attendu et vérifié |
|---|---|
| Refus dans le panneau du compagnon | Mission arrêtée, opération rejetée |
| Relecture refusée | L'opération concernée n'est jamais soumise |
| Échec d'une opération (secret détecté au commit) | Mission échouée, motif affiché, restauration proposée |
| Délai dépassé | Opération annulée sur le compagnon |
| Arrêt d'urgence pendant un build | Annulation envoyée, aucune étape suivante |
| Arrêt d'urgence avec un processus lent à tuer | État final « annulée » confirmé |
| Arrêt d'urgence pendant une demande d'approbation | Demande rejetée, étape « annulée » |
| Pause et reprise | La pause prend effet entre deux étapes, état enregistré |
| Compagnon injoignable pendant l'approbation ou pendant le suivi | Mission interrompue, puis **reprise après redémarrage** sans resoumettre |
| Prérequis non rempli | Arrêt avant tout build |
| Limite de durée | Mission échouée avec le motif |
| Publication sans jeton | Échec clair, rien n'est poussé |
| Publication, consentement refusé | Aucun push |
| Publication avec secret dans ce qui partirait | Arrêt avant le push |
| Push consenti | Jeton transmis au compagnon, absent du journal, de l'état enregistré et du rapport |

- Plans invalides refusés : opération inconnue (`shell.exec`), `git.restore`, chemin `../../etc/passwd`, jeton écrit dans le plan, résolveur et condition inconnus, doublons, trop de modifications.
- Réponses IA hostiles refusées : texte libre, JSON cassé, `shell.run`, jeton volé, `forge.token` détourné, champ `exec`.
- Migration **v3 → v4** testée à partir du schéma v3 réel relevé (`test/fixtures/schema_v3.sql`), avec suppression en cascade du journal.

## 3. Essai réel sur le Honor (`adb reverse`, projet jetable `escale` créé par `flutter create`, avec un `.env`)

1. **« Mettre le projet sous Git »** :
   - plan affiché ;
   - approbation du `.gitignore` (`+ .env`, `+ build/`, `+ android/key.properties`) ;
   - point de contrôle `20261114-075706-VRT-Zw` ;
   - approbation de `git init --initial-branch=main` ;
   - relecture de **37 fichiers, sans `.env`** ;
   - approbation de `git add` puis du commit ;
   - mission **Terminée**.

   Vérifié sur le PC : `008363d chore: état du projet suivi par Git (mission du Capitaine)`, `.env` ignoré par `.gitignore:49`.
2. **« Contrôle qualité Flutter »** menée au bout en réel : analyse, tests, APK en 45 s, cale des artefacts.
3. **Arrêt d'urgence pendant le build de l'APK** :
   - annulation reçue par le compagnon 3 s après l'approbation ;
   - processus terminé `cancelled`, code -9, 13 s plus tard ;
   - étape « Annulée » avec un état confirmé, étape 5 jamais lancée ;
   - aucun build restant sur le PC.
4. **« Publier la branche courante »** vers un dépôt distant fictif :
   - relecture montrant `1 commit 008363d`, branche `main`, sans jeton affiché ;
   - « Publier » **désactivé** tant que la case n'est pas cochée (`enabled=false`) ;
   - refus, mission arrêtée ;
   - **aucune demande de push** dans le journal d'audit du compagnon.
5. **Plan IA réel** (claude-opus-5-5) pour « créer une branche de travail feat/accueil puis commiter mes changements » :
   - plan **valide** de 8 étapes (lecture, audit, diff, point de contrôle, branche, bascule, ajout, commit) ;
   - 1 249 jetons en entrée, 1 666 en sortie, coût estimé ≈ 0,038 $ ;
   - affiché dans la Table de navigation, non exécuté.
6. Mode paysage forcé brièvement, puis réglages de rotation restaurés à l'identique : barre latérale compacte, sans débordement.

Précaution : l'alarme du téléphone a sonné pendant l'essai. Aucune action n'a été faite tant qu'elle était affichée ou en répétition, et chaque série d'actions vérifiait d'abord que La Cambuse était au premier plan.

## 4. Défauts trouvés et corrigés

1. **Crash** sur un plan contenant une opération inconnue : l'insertion du point de contrôle lisait le type avant la validation. Corrigé et testé.
2. **Mission figée en silence** au démarrage : le journal était écrit avant l'enregistrement de la mission, ce qui violait une clé étrangère. La mission est désormais enregistrée d'abord, et toute erreur interne la marque « interrompue » au lieu de la figer.
3. **Approbation perdue en route** (réseau) : l'opération aurait pu être relancée à l'aveugle. Elle est maintenant marquée « état inconnu », et son état est relu à la reprise.
4. **Arrêt d'urgence trop pessimiste** : il déclarait « état inconnu » après 0,4 s, alors que le compagnon met jusqu'à environ 13 s à tuer un build. Il attend maintenant la confirmation, jusqu'à 15 s (constaté en réel).
5. **Arrêt pendant une demande d'approbation** : l'étape restait « En cours ». Elle est désormais « Annulée : rien n'a été lancé » (constaté en réel).
6. Conflit de nom avec `StepState` de Flutter : renommé `MissionStepState`.
7. Débordement du rail de navigation en paysage, décrit plus haut.

## 5. Limites

- Pas d'**annulation automatique** des commits ni des publications : c'est un choix, la réécriture d'historique reste une décision humaine documentée. Le retour arrière automatique se limite à la restauration non destructive du point de contrôle.
- La pause est **coopérative** : elle n'interrompt pas une opération lancée. Seul l'arrêt d'urgence le fait.
- Une seule mission à la fois.
- La restauration du point de contrôle a été testée en phase 5 et par test unitaire ici, mais **pas rejouée en réel** depuis l'écran du Capitaine.
- La mission « Mettre en place la CI » est couverte par les tests (plan, validation) mais **n'a pas été exécutée en réel** dans cette phase. La génération de CI elle-même a été essayée en réel en phase 8.
- **Aucun push réel** n'a été fait : seul le refus a été essayé, volontairement sans destination réelle. Le push consenti est vérifié par test simulé.
- Le plan IA a été validé et affiché, mais **pas exécuté**.
- Les missions prédéfinies sont en français seulement, comme les cours. L'interface du Capitaine est traduite en anglais.
