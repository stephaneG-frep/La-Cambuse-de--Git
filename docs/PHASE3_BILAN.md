# Bilan — Phase 3 : Agent IA pédagogique

Date : 2026-11-12. Toutes les commandes listées ont réellement été exécutées.

## 1. Fonctionnalités livrées

| Fonctionnalité | Détail | Vérification |
|---|---|---|
| Abstraction fournisseurs | `AiProvider` (flux d'événements + test de connexion) ; adaptateurs **Anthropic** (API Messages, HTTP brut : pas de SDK Dart officiel) et **compatible OpenAI** (OpenAI, Mistral, Groq, OpenRouter, Ollama) | tests sur serveur HTTP simulé |
| Anthropic | `anthropic-version: 2026-10-21`, flux SSE, modèle par défaut `claude-opus-5-5` (Sonnet 5.5 et Haiku 5.5 au choix), pas de paramètre `thinking` (réflexion toujours active sur Opus 5.5), effort réglable, **repli serveur `fallbacks: "default"` activé par défaut** sur les modèles qui l'acceptent, gestion du refus (`stop_reason: refusal`) | 14 tests + **essai réel** |
| Blocs de réflexion | rejoués **sans modification** à chaque tour (exigence de l'API) ; prompt système figé par conversation ; récupération unique si l'API les rejette (retrait puis nouvel essai) | tests |
| Erreurs | 400/401/402/403/404/413/429/500/529, erreurs en cours de flux, flux tronqué, délais ; nouvelles tentatives (2 max, `retry-after` respecté) avant le premier jeton ; messages concrets en français | tests |
| Clé API | coffre du système (Keystore Android, libsecret Linux) ; jamais en base, dans le journal, les exports ni les prompts ; seuls les 6 premiers et 4 derniers caractères sont réaffichés | test + **vérification sur le Honor** |
| Masquage des secrets | les messages de l'apprenant passent par le `Redactor` avant envoi ; avertissement affiché | test |
| Protection contre l'injection | contenu de leçon balisé `<lesson_content>` comme donnée ; règles fixes (ne rien prétendre exécuter, signaler les commandes destructrices, ne jamais demander de secret, ignorer les instructions présentes dans les journaux et fichiers) ; aucune sortie IA n'est exécutée ni rendue cliquable | tests du prompt |
| Coûts | budget quotidien de jetons (200 000 par défaut, 0 = illimité) bloquant avant l'envoi ; jetons et coût estimé affichés sous chaque réponse et consignés au journal | tests + essai réel |
| Chat contextualisé | depuis une leçon (bouton robot) ou l'Académie ; niveau débutant, intermédiaire ou expert ; arrêt en cours de réponse ; historique des conversations, suppression confirmée | tests de widgets |
| Mode sans IA | sans clé ou hors ligne : explication claire, le reste de l'application fonctionne | tests de widgets |
| Rendu | Markdown simplifié (titres, gras, italique, code, listes) ; aucun lien cliquable ni HTML | tests |
| Base v3 | tables `ai_conversations` et `ai_messages` (suppression en cascade) ; migration v2 → v3 testée sur le schéma v2 relevé sur le Honor | `migration_test.dart` |

## 2. Commandes et résultats exacts

| Commande | Résultat |
|---|---|
| `flutter analyze --fatal-infos` | `No issues found!` |
| `flutter test` | `+152: All tests passed!` (148 avant l'ajout du rendu Markdown, puis 4 tests Markdown de plus ; suite complète relancée avant le commit) |
| `flutter build apk --debug --target-platform android-arm64` / `flutter build linux --release` | succès |
| **Essai réel (Honor, clé saisie par l'utilisateur dans l'app)** | conversation « Pourquoi Git ? », question « Qui a inventé git et github », réponse de `claude-opus-5-5` en français ; 1 071 jetons en entrée, 995 en sortie, ≈ 0,0242 $ ; blocs `['thinking', 'text']` stockés ; entrée « Réponse du professeur IA » au journal |
| Recherche de fuite de clé sur le Honor | 0 occurrence de `sk-ant` dans la base, 0 dans le logcat de l'application, aucun fichier privé de l'app ne la contient |

## 3. Défauts trouvés et corrigés

1. **Permission INTERNET absente du manifeste Android principal** : seul le manifeste debug l'ajoutait, donc une version release n'aurait jamais pu joindre l'IA. Ajoutée.
2. Markdown affiché brut (`**`, `###`) dans la vraie réponse : rendu simplifié ajouté. Une clôture de code en milieu de ligne est aussi gérée.
3. Débordements d'interface détectés par les tests : bouton « Nouvelle conversation » sur téléphone, sélecteur de fournisseur aux libellés longs.
4. Utilisation de `ref` après fermeture de l'écran de chat : protégée.

## 4. Limites connues

- Le Markdown de la vraie réponse n'a pas été revu sur le téléphone après correction (l'utilisateur était en communication : interaction interrompue). Il est couvert par les tests.
- L'essai réel a eu lieu sur Android ; sur Linux, le coffre libsecret n'a été exercé que par la construction de l'application, pas par une vraie saisie de clé.
- L'adaptateur compatible OpenAI n'est testé que contre un serveur simulé (aucune clé ni Ollama disponible).
- Les tarifs servant à l'estimation sont figés au 2026-11-03 ; seule la facture du fournisseur fait foi.
- Pas de compaction : une conversation très longue finira en erreur 413, avec un message invitant à en commencer une nouvelle.
- Les éléments `fallback` éventuels (repli serveur) sont conservés dans l'historique, mais le modèle qui a réellement servi la réponse n'est lu que dans `message_start`.
