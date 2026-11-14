# Bilan — Phase 11 : Stabilisation et livraison

Date : 2026-11-14. Toutes les commandes listées ont réellement été exécutées.

## 1. Audit global

### Sécurité
- **Historique Git entier analysé** : 389 versions de fichiers texte, avec le détecteur du projet.
  - **Aucun vrai secret.**
  - Les valeurs détectées sont des jetons factices de tests (`ghp_TESTTOKEN000…`, `AKIA…` (clé AWS factice), `sk-ant-test-000…`) et des exemples pédagogiques des labos (`ghp_exempleNonValide1234`, `motdepasse-2024`).
- **gitleaks en CI** (règles par défaut) sur tout l'historique : vert. L'exception est limitée aux dossiers `test/` et aux deux valeurs d'exemple précises, dans `.gitleaks.toml`.
- **Défaut corrigé : faux positifs bloquants.** La règle « mot de passe en clair » signalait du code ordinaire (`accessToken: _issueAccess(id)`, `keyPassword = keystoreProperties[…]`, `secretDetected = 'secret_detected'`). L'Atelier et le Capitaine auraient donc **bloqué des commits légitimes**. La règle tient désormais compte du type de fichier :
  - dans le code, elle exige une valeur littérale entre guillemets ;
  - dans les fichiers de configuration, elle accepte une valeur nue ;
  - elle ignore les identifiants de code.

  5 tests de non-régression ont été ajoutés. Le masquage des journaux garde la règle large.
- Politique de sécurité : [SECURITY.md](../SECURITY.md).

### Dépendances
- Dépendances directes : toutes à jour.
- 9 dépendances transitives mises à jour dans les contraintes, dont **sqlite3 3.5.2 → 3.9.1** (moteur SQLite natif embarqué). L'analyse, les tests et les deux builds ont été rejoués.
- Compagnon et protocole : « Found no outdated packages ».
- Aucun scanner de vulnérabilités (osv-scanner, trivy) n'est installé sur la machine. Le SBOM CycloneDX est livré pour permettre cette analyse ailleurs.

### CI — défauts réels découverts
- La CI avait **déjà tourné cinq fois** sur le dépôt public `stephaneG-frep/La-Cambuse-de--Git`, poussé par vous, et elle **avait échoué à chaque fois**. Les bilans 1 et 8 affirmaient à tort qu'elle n'avait « jamais été exécutée », faute d'avoir vérifié.
- Causes et corrections :
  1. L'analyse à la racine couvrait les sous-projets sans leurs dépendances : `pub get` des trois projets avant l'analyse, et analyse séparée de chacun.
  2. gitleaks signalait les jetons factices des tests : `.gitleaks.toml`.
  3. gitleaks-action échoue au premier push d'un dépôt neuf (commit racine sans parent) : ajout d'un lancement manuel `workflow_dispatch`, qui analyse tout l'historique.
  4. Le build de l'APK exigeait Java 17 (AGP 9.1), alors que le runner utilise Java 11 par défaut : `actions/setup-java` v6.1.0. **Le même défaut existait dans le modèle de CI Flutter que l'application génère pour les projets des utilisateurs** ; il est corrigé.
  5. Le script de livraison masquait la cause d'un échec : il affiche maintenant la fin du journal concerné.
- Actions mises à jour vers des versions Node 24, publiées depuis au moins trois semaines :
  - checkout v7.0.1, upload-artifact v7.0.2, flutter-action v2.23.0 ;
  - gitleaks-action v3.0.0, setup-node v7.1.0, setup-python v7.1.0, setup-java v6.1.0.

  Cela s'applique à la CI, aux modèles générés et aux labos de l'Académie. `setup-java` v6.3.0, publiée le jour même, a été volontairement écartée.
- **Résultat sur GitHub** (dépôt privé neuf `stephaneG-frep/la-cambuse-de-git-prive`, créé avec votre accord) : exécution `43637187905`, **les trois jobs sont verts**.

## 2. Fonctionnalités ajoutées
- **Guide de bord** : écran hors ligne (Paramètres → Guide de bord), qui manquait par rapport à la liste d'écrans de SPEC §9. La source unique est [docs/GUIDE_UTILISATEUR.md](GUIDE_UTILISATEUR.md), embarqué dans l'application, avec des sections repliables.
- **Guide développeur** : [docs/GUIDE_DEVELOPPEUR.md](GUIDE_DEVELOPPEUR.md).
- Le rendu Markdown du chat est devenu un widget réutilisable (`MarkdownLiteView`), sans lien cliquable.

## 3. UX et accessibilité
- Nouveaux tests, appliqués aux 7 écrans principaux (Pont, Académie, Atelier, Capitaine, Journal, Paramètres, Guide), sur téléphone et sur bureau :
  - cibles tactiles d'au moins 48 dp ;
  - boutons étiquetés pour les lecteurs d'écran ;
  - contraste du texte (règles officielles de Flutter).
- Test du texte agrandi à **200 %** sur téléphone : aucun débordement.
- Défaut corrigé : sur bureau, les paragraphes sélectionnables du guide étaient des cibles d'appui long de 40 px. Les paragraphes du guide ne sont plus sélectionnables ; les blocs de commandes le restent, avec une hauteur d'au moins 48 dp.

## 4. Performance (mesures réelles)

| Mesure | Résultat |
|---|---|
| Honor, démarrage à froid, mode **profile** (compilation anticipée, représentatif d'une release) | **628 à 709 ms** (3 mesures) |
| Honor, mémoire, profile | 213 Mo (PSS) |
| Honor, démarrage à froid, APK **debug** livré | 2,7 à 4,2 s (JIT, non représentatif) |
| Honor, mémoire, debug | 443 Mo (PSS) |
| APK profile / APK debug | 32 Mo / 130 Mo |
| Linux, release, apparition de la fenêtre | **228 ms** |
| Linux, release, mémoire | 154 Mo (RSS) |
| Bundle Linux / paquet `.deb` | 30 Mo / 11 Mo |

## 5. Tests et résultats exacts

| Commande | Résultat |
|---|---|
| `flutter test` | `+343: All tests passed!` |
| `cd companion && dart test` | `+58: All tests passed!` |
| `cd packages/cambuse_protocol && dart test` | `+39: All tests passed!` |
| `flutter analyze --fatal-infos` | `No issues found!` |
| `tool/package_release.sh --with-tests` | 4 artefacts, sommes vérifiées, tests intégrés au rapport |
| CI GitHub `43637187905`, puis `43639902180` (dernier commit, tout l'historique) | secrets ✓, analyse et tests ✓, livraison ✓ |

## 6. Essais réels
- **Honor** :
  - APK de livraison installé ;
  - écran « Guide de bord » chargé depuis l'asset embarqué ;
  - mesures de démarrage et de mémoire (téléphone revenu à l'accueil après chaque série, et application vérifiée au premier plan avant toute action).
- **Linux** : l'application release est lancée avec un dossier de données temporaire, pour ne pas toucher à vos données. La fenêtre de l'application seule a été capturée (pas le bureau). Le Pont s'affiche, sans écran blanc.
- **Paquet `.deb` installé** par vous avec `sudo apt install` : `dpkg --verify` propre ; l'application installée ouvre sa fenêtre en 226 ms ; le compagnon installé répond HTTP 200. Détails dans le rapport final, §6.

## 7. Limites
- Livraison avec un **APK debug** seulement, par votre choix : aucune signature release.
- Le dépôt public `La-Cambuse-de--Git` n'a **pas** été mis à jour : y pousser publierait ce travail, et votre accord portait sur un dépôt privé neuf. Il contient encore la version de la phase 10, dont la CI échoue.
- L'exécution locale de gitleaks via Docker a été refusée par les permissions de la session. La validation de gitleaks a été faite par la CI.
- Les mesures de performance portent sur un seul appareil (Honor MTN-NX1M) et un seul PC.
