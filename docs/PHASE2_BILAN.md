# Bilan — Phase 2 : Académie Git complète (MVP pédagogique)

Date : 2026-11-12. Toutes les commandes listées ont réellement été exécutées.

## 1. Fonctionnalités livrées

| Fonctionnalité | Détail | Vérification |
|---|---|---|
| Module Git complet | 14 leçons (objectifs, cours, code, astuces, avertissements), 60 questions avec correction expliquée, 12 exercices guidés, projet final en 6 étapes, grille d'évaluation à 6 critères × 3 niveaux, glossaire de 25 termes | `test/academy/content_test.dart` |
| Bac à sable Git simulé | init, config, status (-s), add (., -A, -f), rm, commit (-m, -a, -am), log (--oneline, -n), show, diff (--staged), restore (--staged), branch (-d/-D), switch/checkout (-c/-b), merge (fast-forward, 3 voies, conflits, --abort), tag (léger, annoté, -d), .gitignore ; ls, cat, touch, rm, echo > / >> | 20 scénarios dans `git_sandbox_test.dart` |
| Sécurité du bac à sable | aucun processus, aucun fichier réel ; refus de `;`, `|`, `&`, `$`, backquote ; chemins confinés (pas d'absolu, pas de `..`) ; commandes non simulées refusées explicitement (push, rebase, reset…) | tests dédiés |
| Exercices réalisables | **chaque solution de chaque étape est rejouée** dans le simulateur ; aucune étape n'est validée d'avance ni trop tôt | 13 tests de rejeu |
| Quiz | choix unique, choix multiples, saisie de commande (guillemets typographiques et `$ ` tolérés) ; correction immédiate | tests unitaires et de widgets |
| Validation d'une leçon | quiz ≥ 70 % **et** exercice réussi (quiz seul si pas d'exercice) ; meilleur score conservé | `progress_repository_test.dart` |
| Répétition espacée | Leitner 5 boîtes (1, 2, 4, 8, 16 jours) alimentée par chaque réponse ; écran « Révisions du jour » | tests unitaires et de widgets |
| Progression persistante et reprise | schéma v2, « Reprendre : … » sur le Pont, progression du module | widget (redémarrage simulé) **et appareil réel** |
| Migration v1 → v2 | testée sur le schéma v1 relevé sur une vraie base, **puis réellement sur le Honor** | `migration_test.dart` + lecture de la base du téléphone |
| Carte des îles | 10 modules ; Git disponible, 9 autres « en brume — phase N » sans contenu simulé | widget |
| Recherche et glossaire | leçons et termes, insensible aux accents | widget |
| Projet final | exercice puis grille d'auto-évaluation (verrouillée tant que le projet n'est pas réalisé) | widget |
| Renommage du profil | Paramètres → Profil (promis en fin de phase 1) | widget |
| Hors ligne | contenu embarqué dans les assets, aucun appel réseau | par construction |

## 2. Commandes et résultats exacts

| Commande | Résultat |
|---|---|
| `python3 tool/content/git_module.py` | `14 leçons, 60 questions, 12 exercices, 25 termes` |
| `flutter analyze --fatal-infos` | `No issues found!` |
| `flutter test` | `+118 ~1: All tests passed!` (le test ignoré — cohérence JSON/source — s'active une fois le fichier versionné ; relancé après commit, voir §6) |
| `flutter build apk --debug --target-platform android-arm64` | `✓ Built build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build linux --release` | `✓ Built build/linux/x64/release/bundle/la_cambuse` |
| `adb install -r` sur HONOR MTN-NX1M (données conservées) | `Success` |
| Sur le téléphone : Pont → Académie → Git → leçon 1 → Exercice, saisie de `git init` puis `git status` | sorties Git attendues, « Exercice réussi ! », onglet « Exercice ✓ » (captures vérifiées) |
| Lecture de la base du téléphone (`adb exec-out run-as … cat`) | `user_version 2`, profil « Matelot Test » conservé, `('git','pourquoi-git', exercise_done=1, completed_at=None)`, entrée « Exercice réussi » au journal |

## 3. Défauts trouvés et corrigés pendant la phase

1. **Quiz illisible sur téléphone** (≈ 400 × 880 dp, la taille du Honor) : en-tête, indication, onglets à icônes et pied de page ne laissaient qu'environ 150 px au quiz, et le bouton « Question suivante » sortait de l'écran. Corrigé : bouton d'action fixe, onglets texte seul sur téléphone, indication déplacée dans le quiz, lien « Leçon suivante » en fin de cours et sur l'écran de résultat.
2. Tests de widgets : finders ambigus à cause des branches masquées de l'`IndexedStack`, et `pump()` manquant après une saisie. Corrections dans les tests uniquement.

## 4. Limites connues (honnêtes)

- Le simulateur fusionne **au niveau du fichier entier** : un conflit englobe tout le fichier, là où Git ne marque que les blocs divergents. Le diff affiche un seul bloc `@@`.
- `rebase`, `reset`, `revert`, `stash`, remotes : expliqués dans le cours, **non simulés** (refus explicite). Ils seront pratiqués sur des dépôts jetables réels dans l'Atelier (phase 5).
- Pas d'éditeur : `git commit` sans `-m` n'est accepté que pour conclure une fusion.
- Contenu des cours **en français uniquement** ; l'interface reste disponible en anglais, avec une mention explicite.
- Sur téléphone, le clavier réduit la console à environ 300 px : c'est utilisable (vérifié sur le Honor) mais perfectible.
- Les règles d'accessibilité Flutter ont été vérifiées automatiquement ; pas de test manuel avec TalkBack.
- Leçon 1 sur le téléphone : l'exercice a été fait sur l'appareil, pas le quiz (les saisies par `adb` sont fragiles). Le quiz complet est couvert par les tests de widgets.

## 5. Fichiers principaux

- `lib/features/academy/domain/` : `course.dart` (modèle strict), `goals.dart` (objectifs, session d'exercice), `catalog.dart` (îles), `sandbox/` (simulateur, tokenizer, diff)
- `lib/features/academy/data/progress_repository.dart`
- `lib/features/academy/presentation/` : carte, module, leçon, révisions, recherche/glossaire, projet, widgets cours/exercice/quiz
- `lib/core/db/database.dart` : schéma v2 et migration
- `tool/content/git_module.py` → `assets/courses/git.json`
- Tests : `test/academy/*`, `test/core/migration_test.dart`, `test/widget/academy_test.dart`, `test/fixtures/schema_v1.sql`

## 6. Prérequis de la phase 3 (agent IA)

Contenu structuré disponible pour contextualiser l'IA (leçon courante, glossaire), journal avec masquage des secrets, `flutter_secure_storage` déjà en dépendance. **Une décision vous reviendra** : quel(s) fournisseur(s) configurer pour les tests réels (clé API ou Ollama sur l'hôte, absent pour l'instant).
