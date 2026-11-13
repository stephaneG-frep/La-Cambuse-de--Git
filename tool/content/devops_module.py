#!/usr/bin/env python3
"""Module « DevOps et CI/CD » : python3 tool/content/devops_module.py"""
from common import *

CO = "actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2"
NODE = "actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0"
UP = "actions/upload-artifact@b4b15b8c7c6ac21ea08fcf65892d2ee8f75cf882 # v4.4.3"

D = []

D.append(lesson("culture", "La culture DevOps", 15,
  ["Comprendre ce que DevOps change réellement", "Raisonner en boucles de retour rapides"],
  [t("DevOps n'est ni un outil ni un poste : c'est une façon de travailler où ceux qui écrivent le code et ceux qui l'exploitent "
     "partagent les mêmes objectifs — livrer souvent, sans casse, et réparer vite."),
   t("Le principe central est la boucle de retour : plus vite on apprend qu'un changement pose problème (tests, revue, "
     "métriques en production), moins il coûte à corriger."),
   t("Petits changements fréquents plutôt que grosses livraisons rares : un petit changement se relit, se teste et s'annule facilement."),
   tip("Automatiser ce qui est répétitif libère du temps pour ce qui demande du jugement : relire, concevoir, enquêter.")],
  [single("do-1-1", "DevOps, c'est avant tout…", ["Une façon de travailler partagée entre développement et exploitation", "Un logiciel", "Un poste unique", "Un langage"], 0, "Les outils servent la pratique, pas l'inverse."),
   single("do-1-2", "Pourquoi préférer de petits changements fréquents ?", ["Plus faciles à relire, tester et annuler", "Moins de commits", "Moins de tests", "Plus de réunions"], 0, "Le risque par livraison diminue."),
   single("do-1-3", "Qu'est-ce qu'une boucle de retour ?", ["Le délai entre un changement et l'information sur ses effets", "Une boucle for", "Un rollback", "Une réunion hebdomadaire"], 0, "On cherche à la raccourcir."),
   single("do-1-4", "Que faut-il automatiser en priorité ?", ["Les tâches répétitives et sujettes à erreur", "Les décisions d'architecture", "Les revues de code", "Rien"], 0, "Build, tests, déploiement, vérifications.")]))

D.append(lesson("integration-continue", "Intégration continue", 18,
  ["Tester automatiquement chaque changement", "Rendre la CI bloquante pour la fusion"],
  [t("L'intégration continue (CI) construit et teste chaque commit et chaque PR. Une PR dont la CI échoue ne se fusionne pas."),
   t("Une CI utile est rapide (quelques minutes), fiable (pas de tests qui échouent au hasard) et identique pour tout le monde."),
   code("on:\n  pull_request:\njobs:\n  test:\n    steps:\n      - run: npm ci\n      - run: npm test", "Le minimum : installer à l'identique (npm ci) et tester"),
   warn("Un test instable (« flaky ») qu'on relance jusqu'au vert habitue l'équipe à ignorer la CI : corrigez-le ou mettez-le en quarantaine visible.")],
  [single("do-2-1", "Différence npm ci / npm install en CI ?", ["npm ci installe exactement le fichier de verrouillage", "Aucune", "npm ci est plus lent et moins sûr", "npm ci ignore les tests"], 0, "Reproductibilité des dépendances."),
   single("do-2-2", "Que faire d'un test instable ?", ["Le corriger ou l'isoler de façon visible", "Relancer jusqu'au vert", "Supprimer la CI", "L'ignorer"], 0, "Sinon la CI perd sa crédibilité."),
   single("do-2-3", "Quand la CI doit-elle s'exécuter ?", ["À chaque PR et sur la branche principale", "Une fois par mois", "Seulement avant une release", "Jamais en PR"], 0, "Le plus tôt possible."),
   single("do-2-4", "Durée visée pour une CI de PR ?", ["Quelques minutes", "Plusieurs heures", "Une journée", "Peu importe"], 0, "Une CI lente est contournée.")],
  lab("workflow", "Cette CI construit le projet mais ne le teste pas, et laisse au jeton ses droits par défaut. Corrigez-la.",
      f"name: CI\non:\n  pull_request:\njobs:\n  build:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: npm ci\n      - run: npm run build\n",
      [has("npm test", "Les tests sont exécutés"), no("GH002", "Permissions déclarées"), valid()],
      "Ajoutez une étape « run: npm test » et « permissions: contents: read » en tête.",
      f"name: CI\non:\n  pull_request:\npermissions:\n  contents: read\njobs:\n  build:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - run: npm ci\n      - run: npm test\n      - run: npm run build\n")))

D.append(lesson("qualite", "Qualité : tests, analyse et revue", 18,
  ["Construire une pyramide de tests équilibrée", "Ajouter analyse statique et formatage automatiques"],
  [t("Pyramide de tests : beaucoup de tests unitaires (rapides), moins de tests d'intégration, quelques tests de bout en bout "
     "(lents, fragiles). Chaque bug corrigé mérite un test qui l'aurait détecté."),
   t("L'analyse statique (linters, typage) et le formatage automatique éliminent les débats de style et attrapent des bugs avant les tests."),
   code("npm run lint\nnpm run format -- --check\nnpm test -- --coverage", "Trois vérifications typiques en CI"),
   tip("La couverture mesure ce qui est exécuté, pas ce qui est vérifié : 100 % de couverture sans assertions ne prouve rien.")],
  [single("do-3-1", "Quels tests doivent être les plus nombreux ?", ["Unitaires", "De bout en bout", "Manuels", "De charge"], 0, "Ils sont rapides, précis et peu coûteux."),
   single("do-3-2", "Que prouve une couverture de 100 % ?", ["Que tout le code est exécuté par les tests, pas qu'il est correct", "Qu'il n'y a aucun bug", "Que le code est sûr", "Rien du tout"], 0, "Il faut aussi des assertions pertinentes."),
   single("do-3-3", "Après la correction d'un bug, on ajoute…", ["Un test qui aurait détecté ce bug", "Un commentaire", "Une issue", "Rien"], 0, "Test de non-régression."),
   single("do-3-4", "Intérêt du formatage automatique en CI ?", ["Supprimer les débats de style en revue", "Accélérer l'exécution", "Chiffrer le code", "Remplacer les tests"], 0, "La revue se concentre sur le fond.")]))

D.append(lesson("artefacts", "Construire une fois, promouvoir partout", 18,
  ["Produire un artefact versionné et vérifiable", "Déployer le même artefact de la recette à la production"],
  [t("On construit l'artefact UNE fois (image, paquet, binaire), on lui donne une version, on calcule son empreinte, puis on "
     "déploie ce même fichier en recette puis en production. Reconstruire pour la production, c'est déployer autre chose que ce qu'on a testé."),
   code("build:\n  script:\n    - npm ci && npm run build\n    - sha256sum dist/* > dist/SHA256SUMS\n  artifacts:\n    paths: [dist/]\n    expire_in: 1 week\n\ndeploy_staging:\n  needs: [build]\n  script: [./deploy.sh staging]",
        "L'artefact passe du job de build au job de déploiement"),
   t("Versionnez avec le tag Git (v1.4.0) ou l'empreinte du commit : on sait toujours quel code tourne où."),
   tip("Un registre (paquets, conteneurs) conserve les artefacts publiés plus longtemps que les artefacts de pipeline.")],
  [single("do-4-1", "Pourquoi ne pas reconstruire pour la production ?", ["On déploierait autre chose que ce qui a été testé", "C'est plus lent", "C'est interdit", "Le cache serait perdu"], 0, "Même artefact, même comportement."),
   single("do-4-2", "Comment identifier ce qui tourne en production ?", ["Version ou empreinte de commit attachée à l'artefact", "La date du jour", "Le nom du développeur", "Impossible"], 0, "On sait toujours quel code tourne où."),
   single("do-4-3", "Rôle de SHA256SUMS ?", ["Vérifier que l'artefact n'a pas changé", "Compresser", "Signer juridiquement", "Accélérer"], 0, "Intégrité de bout en bout."),
   single("do-4-4", "Où conserver durablement les artefacts publiés ?", ["Un registre de paquets ou de conteneurs", "Le cache CI", "Le README", "Un ticket"], 0, "Les artefacts de pipeline expirent.")],
  lab("gitlabci", "Le déploiement reconstruit le projet et les artefacts ne sont ni vérifiables ni limités dans le temps. Corrigez.",
      "build:\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm run build\n  artifacts:\n    paths: [dist/]\n\ndeploy_staging:\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm run build\n    - ./deploy.sh staging\n",
      [has("sha256sum", "Empreintes calculées"), no("GL004", "Durée de conservation fixée"), has("needs: [build]", "Le déploiement réutilise l'artefact"), valid()],
      "Calculez les empreintes dans build, ajoutez expire_in, et faites dépendre deploy_staging de build (needs: [build]) sans reconstruire.",
      "build:\n  image: node:22.11-slim\n  script:\n    - npm ci\n    - npm run build\n    - sha256sum dist/* > dist/SHA256SUMS\n  artifacts:\n    paths: [dist/]\n    expire_in: 1 week\n\ndeploy_staging:\n  image: node:22.11-slim\n  needs: [build]\n  script:\n    - ./deploy.sh staging\n")))

D.append(lesson("secrets-ci", "Secrets dans la chaîne de livraison", 18,
  ["Savoir où vivent les secrets", "Réduire la durée et la portée des identifiants"],
  [t("Un secret n'a rien à faire dans le code, les fichiers de pipeline, les images ou les journaux. Il vit dans le coffre de "
     "la forge (variables protégées), un gestionnaire de secrets (Vault, coffres des clouds) ou le trousseau du système."),
   t("Mieux qu'un secret bien rangé : pas de secret du tout. Les identités fédérées (OIDC) permettent à une pipeline d'obtenir "
     "un accès temporaire au cloud sans clé permanente."),
   code(": \"${DEPLOY_TOKEN:?variable DEPLOY_TOKEN requise}\"\ncurl -fsS -H \"Authorization: Bearer $DEPLOY_TOKEN\" https://deploiement.exemple/api",
        "Le script exige le secret depuis l'environnement et ne l'affiche pas"),
   warn("Un secret commité doit être considéré comme compromis : révoquez-le, même si le commit a été réécrit.")],
  [single("do-5-1", "Où ne doit JAMAIS se trouver un secret ?", ["Dans le dépôt ou les journaux", "Dans un gestionnaire de secrets", "Dans une variable protégée", "Dans le trousseau"], 0, "Le dépôt est copié partout."),
   single("do-5-2", "Intérêt d'OIDC pour une pipeline ?", ["Obtenir un accès temporaire sans clé permanente", "Chiffrer le code", "Accélérer les tests", "Remplacer Git"], 0, "Rien à voler sur la durée."),
   single("do-5-3", "Un secret a été commité puis le commit supprimé. Que faire ?", ["Le révoquer et en créer un nouveau", "Rien", "Rendre le dépôt privé", "Le renommer"], 0, "Il a pu être copié entre-temps."),
   single("do-5-4", "Que fait : \"${TOKEN:?}\" dans un script ?", ["Arrête le script si TOKEN est absent", "Affiche TOKEN", "Supprime TOKEN", "Chiffre TOKEN"], 0, "Échec clair plutôt qu'un appel sans authentification.")],
  lab("shell", "Ce script de déploiement contient le jeton en clair. Lisez-le depuis l'environnement.",
      "#!/usr/bin/env bash\nset -euo pipefail\nDEPLOY_TOKEN=dpl_exempleNonValide987\ncurl -fsS -H \"Authorization: Bearer $DEPLOY_TOKEN\" https://deploiement.exemple/api\n",
      [no("SH010", "Plus de secret en dur"), has(":?", "Le script échoue si le jeton manque"), clean()],
      "Remplacez l'affectation par : \"${DEPLOY_TOKEN:?variable DEPLOY_TOKEN requise}\".",
      "#!/usr/bin/env bash\nset -euo pipefail\n: \"${DEPLOY_TOKEN:?variable DEPLOY_TOKEN requise}\"\ncurl -fsS -H \"Authorization: Bearer $DEPLOY_TOKEN\" https://deploiement.exemple/api\n")))

D.append(lesson("livraison", "Livraison continue et stratégies de déploiement", 20,
  ["Distinguer livraison et déploiement continus", "Choisir entre blue/green, canary et feature flags"],
  [t("Livraison continue : chaque version validée PEUT partir en production sur décision humaine. Déploiement continu : elle "
     "part automatiquement. Beaucoup d'équipes déploient automatiquement en recette et manuellement en production."),
   t("Blue/green : deux environnements, on bascule le trafic d'un coup (retour immédiat possible). Canary : on envoie d'abord "
     "5 % du trafic à la nouvelle version et on surveille. Feature flags : le code est déployé mais la fonction est activée plus tard."),
   code("deploy_staging:\n  environment: staging\n  script: [./deploy.sh staging]\n\ndeploy_production:\n  environment: production\n  when: manual\n  script: [./deploy.sh production]",
        "Recette automatique, production sur clic"),
   tip("Séparer « déployer » (mettre le code en place) et « publier » (l'activer pour les utilisateurs) réduit fortement le risque.")],
  [single("do-6-1", "Livraison continue signifie…", ["Chaque version validée peut partir en production sur décision", "Tout part automatiquement en production", "Pas de tests", "Une release par an"], 0, "Le déploiement continu va plus loin."),
   single("do-6-2", "Stratégie canary ?", ["Envoyer d'abord une petite part du trafic à la nouvelle version", "Tout basculer d'un coup", "Déployer la nuit", "Ne jamais déployer"], 0, "On surveille avant d'élargir."),
   single("do-6-3", "Atout du blue/green ?", ["Retour immédiat en rebasculant le trafic", "Moins de serveurs", "Pas besoin de tests", "Pas de base de données"], 0, "L'ancienne version reste prête."),
   single("do-6-4", "Un feature flag permet de…", ["Déployer le code sans activer la fonctionnalité", "Supprimer une branche", "Chiffrer une variable", "Accélérer la CI"], 0, "Déployer le code n'est pas encore le publier.")],
  lab("gitlabci", "Recette et production se déploient automatiquement. Gardez la recette automatique mais exigez un clic pour la production.",
      "deploy_staging:\n  image: alpine:3.20\n  environment:\n    name: staging\n  script:\n    - ./deploy.sh staging\n\ndeploy_production:\n  image: alpine:3.20\n  environment:\n    name: production\n  script:\n    - ./deploy.sh production\n",
      [no("GL003", "Production déclenchée manuellement"), has("staging", "La recette est toujours déployée"), valid()],
      "Ajoutez when: manual au seul job deploy_production.",
      "deploy_staging:\n  image: alpine:3.20\n  environment:\n    name: staging\n  script:\n    - ./deploy.sh staging\n\ndeploy_production:\n  image: alpine:3.20\n  environment:\n    name: production\n  when: manual\n  script:\n    - ./deploy.sh production\n")))

D.append(lesson("rollback", "Revenir en arrière sans paniquer", 20,
  ["Préparer un retour arrière rapide", "Gérer les migrations de base de données compatibles"],
  [t("Un déploiement sûr se prépare à échouer : chaque version est installée dans son propre dossier (releases/v1.4.0) et un "
     "lien symbolique « current » pointe vers la version active. Revenir en arrière = repointer le lien, en une seconde."),
   code("ln -sfn /srv/releases/v1.4.0 /srv/app/current\nsystemctl restart app", "Bascule atomique du lien symbolique"),
   t("Les migrations de base suivent le schéma « étendre puis contracter » : on ajoute la nouvelle colonne (compatible avec "
     "l'ancienne version), on déploie, puis on retire l'ancienne colonne plus tard. Ainsi l'ancienne version reste déployable."),
   warn("Supprimer l'ancienne version avant d'avoir validé la nouvelle, c'est se priver de retour arrière.")],
  [single("do-7-1", "Pourquoi un lien symbolique « current » ?", ["Basculer ou revenir en arrière instantanément", "Économiser de l'espace", "Chiffrer l'application", "Accélérer Git"], 0, "ln -sfn remplace le lien de façon atomique."),
   single("do-7-2", "Schéma de migration compatible ?", ["Étendre, déployer, puis contracter", "Supprimer d'abord", "Tout changer en une fois", "Ne jamais migrer"], 0, "L'ancienne version continue de fonctionner."),
   single("do-7-3", "Quand supprimer l'ancienne version ?", ["Après validation de la nouvelle", "Avant le déploiement", "Jamais", "Pendant le déploiement"], 0, "Gardez un filet de sécurité."),
   cmd("do-7-4", "Faites pointer le lien /srv/app/current vers /srv/releases/v1.4.0.", ["ln -sfn /srv/releases/v1.4.0 /srv/app/current"], "-s symbolique, -f remplace, -n traite le lien existant comme un fichier.")],
  lab("shell", "Ce script écrase la version en place : impossible de revenir en arrière, et la variable n'est pas protégée.",
      "#!/usr/bin/env bash\nset -euo pipefail\nRELEASE=$1\nrm -rf /srv/app/current\ncp -r /srv/releases/$RELEASE /srv/app/current\nsystemctl restart app\n",
      [has("ln -sfn", "Bascule par lien symbolique"), hasnt("rm -rf /srv/app/current", "La version précédente n'est plus détruite"), no("SH003", "Variables entre guillemets"),
       has(":?", "Version obligatoire"), clean()],
      "Exigez la version avec ${1:?…}, vérifiez que le dossier existe, puis ln -sfn vers /srv/app/current.",
      "#!/usr/bin/env bash\nset -euo pipefail\nRELEASE=\"${1:?version requise}\"\ncible=\"/srv/releases/$RELEASE\"\ntest -d \"$cible\"\nln -sfn \"$cible\" /srv/app/current\nsystemctl restart app\n")))

D.append(lesson("conteneurs-ci", "Conteneurs dans la chaîne", 18,
  ["Produire une image légère et non root en CI", "Séparer l'environnement de build de l'image finale"],
  [t("Le build multi-étapes compile dans une image complète (compilateur, outils) puis copie seulement le binaire dans une image "
     "minimale. Résultat : image plus petite, moins de failles, rien d'inutile en production."),
   code("FROM golang:1.23.4 AS build\nWORKDIR /src\nCOPY . .\nRUN go build -o /out/app ./cmd/app\n\nFROM gcr.io/distroless/static-debian12:nonroot\nCOPY --from=build /out/app /app\nUSER nonroot\nENTRYPOINT [\"/app\"]",
        "Compilation puis image finale minimale et non root"),
   t("En CI, on construit l'image, on l'analyse (vulnérabilités), on la tague avec la version et l'empreinte du commit, puis on la pousse."),
   tip("Docker n'est pas toujours la bonne réponse : une application Flutter mobile se livre en APK, pas en conteneur.")],
  [single("do-8-1", "Intérêt du build multi-étapes ?", ["Image finale sans compilateur ni outils", "Build plus long exprès", "Plusieurs applications", "Pas besoin de Dockerfile"], 0, "Moins de surface d'attaque."),
   single("do-8-2", "Comment taguer une image en CI ?", ["Version et empreinte du commit", "latest uniquement", "La date", "Aucun tag"], 0, "On relie chaque image au code exact qui l'a produite."),
   single("do-8-3", "Pourquoi USER nonroot ?", ["Limiter l'impact d'une faille dans l'application", "Accélérer", "Obligatoire pour Go", "Pour les journaux"], 0, "C'est le principe du moindre privilège."),
   single("do-8-4", "Une application Flutter Android se livre…", ["En APK ou AAB", "En image Docker", "En paquet npm", "En Helm chart"], 0, "Docker sert au backend ou à la CI.")],
  lab("dockerfile", "Cette image embarque le compilateur et tourne en root. Passez en multi-étapes non root.",
      "FROM golang:1.23.4\nWORKDIR /src\nCOPY . .\nRUN go build -o /usr/local/bin/app ./cmd/app\nCMD [\"app\"]\n",
      [goal("stages", "Au moins deux étapes", min=2), no("DF002", "Image finale non root"), no("DF010", "Compilation hors de l'image finale"), valid()],
      "Nommez la première étape AS build, puis repartez de gcr.io/distroless/static-debian12:nonroot avec COPY --from=build et USER nonroot.",
      "FROM golang:1.23.4 AS build\nWORKDIR /src\nCOPY . .\nRUN go build -o /out/app ./cmd/app\n\nFROM gcr.io/distroless/static-debian12:nonroot\nCOPY --from=build /out/app /app\nUSER nonroot\nENTRYPOINT [\"/app\"]\n")))

D.append(lesson("mesurer", "Mesurer la performance de livraison", 15,
  ["Connaître les quatre indicateurs DORA", "Utiliser les mesures pour s'améliorer, pas pour juger"],
  [t("Les indicateurs DORA mesurent la capacité de livraison : fréquence de déploiement, délai entre commit et production, "
     "taux d'échec des changements, temps de restauration du service."),
   t("Vitesse et stabilité ne s'opposent pas : les équipes qui déploient souvent ont généralement moins d'incidents, car "
     "chaque changement est petit et l'automatisation fiable."),
   t("Ces chiffres servent à repérer les goulets d'étranglement (revue lente, tests longs, déploiement manuel) — pas à "
     "classer des personnes."),
   tip("Commencez simple : notez chaque déploiement et chaque incident ; les tendances apparaissent vite.")],
  [single("do-9-1", "Lequel est un indicateur DORA ?", ["Taux d'échec des changements", "Nombre de lignes écrites", "Nombre de réunions", "Taille du README"], 0, "Avec fréquence, délai et temps de restauration."),
   single("do-9-2", "Vitesse et stabilité…", ["Progressent souvent ensemble", "S'opposent toujours", "Sont sans rapport", "Se mesurent à la main uniquement"], 0, "Petits changements, automatisation fiable."),
   single("do-9-3", "Usage approprié des indicateurs ?", ["Trouver les goulets d'étranglement", "Classer les développeurs", "Punir les erreurs", "Remplacer la revue"], 0, "Amélioration continue."),
   single("do-9-4", "Le « temps de restauration » mesure…", ["Le délai pour rétablir le service après un incident", "La durée d'un backup", "Le temps de build", "La durée d'un sprint"], 0, "Réparer vite compte autant que ne pas casser.")]))

project = {"title": "Chaîne CI/CD complète",
  "brief": "Transformez un workflow fourre-tout en chaîne propre : tests, build vérifiable, déploiement en production protégé, moindre privilège et dépendances épinglées.",
  "lab": lab("workflow", "Objectif : aucun problème bloquant ni avertissement, jobs enchaînés, production protégée.",
      "name: Tout\non:\n  push:\n  pull_request:\njobs:\n  tout:\n    runs-on: ubuntu-24.04\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n      - run: npm ci && npm run build\n"
      "      - run: echo \"Déploiement avec ${{ secrets.DEPLOY_TOKEN }}\"\n      - run: ./deploy.sh production\n",
      [clean(), nowarn(), has("needs:", "Jobs enchaînés"), has("environment: production", "Production protégée par un environment"), has("npm test", "Tests exécutés")],
      "Découpez en jobs test → build → deploy (needs:), ajoutez permissions, empreintes, timeouts, et protégez deploy par environment: production.",
      f"name: CI/CD\non:\n  push:\n    branches: [main]\n  pull_request:\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - uses: {NODE}\n      - run: npm ci && npm test\n"
      f"  build:\n    needs: test\n    runs-on: ubuntu-24.04\n    timeout-minutes: 15\n    steps:\n      - uses: {CO}\n        with:\n          persist-credentials: false\n      - uses: {NODE}\n      - run: npm ci && npm run build && sha256sum dist/* > dist/SHA256SUMS\n      - uses: {UP}\n        with:\n          name: dist\n          path: dist/\n          retention-days: 7\n"
      "  deploy:\n    needs: build\n    if: github.ref == 'refs/heads/main'\n    environment: production\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - run: ./deploy.sh production\n        env:\n          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}\n"),
  "rubric": rubric(
    ("Intégration", "Pas de tests", "Tests à chaque PR", "Tests rapides, fiables et bloquants pour la fusion"),
    ("Artefacts", "Reconstruit à chaque étape", "Construit une fois", "Construit une fois, versionné, empreintes publiées"),
    ("Déploiement", "Automatique en production sans garde", "Production protégée", "Recette automatique, production approuvée, stratégie progressive"),
    ("Retour arrière", "Impossible", "Procédure documentée", "Bascule instantanée testée, migrations compatibles"),
    ("Sécurité", "Secrets affichés, droits larges", "Secrets en variables, droits lecture", "Identités temporaires (OIDC), épinglage, moindre privilège"))}

glossary = [
  ("CI", "Intégration continue : construire et tester chaque changement."), ("CD", "Livraison ou déploiement continus."),
  ("Artefact", "Résultat versionné d'un build (paquet, image, binaire)."), ("Promotion", "Déployer le même artefact d'un environnement au suivant."),
  ("Blue/green", "Deux environnements, bascule instantanée du trafic."), ("Canary", "Nouvelle version exposée d'abord à une petite part du trafic."),
  ("Feature flag", "Interrupteur qui active une fonctionnalité déjà déployée."), ("Rollback", "Retour à la version précédente."),
  ("Expand/contract", "Migration en deux temps compatible avec l'ancienne version."), ("DORA", "Quatre indicateurs de performance de livraison."),
  ("Test instable", "Test qui échoue de façon aléatoire (flaky)."), ("OIDC", "Fédération d'identité donnant des accès temporaires sans clé permanente."),
  ("Multi-étapes", "Dockerfile séparant compilation et image finale."),
]

write_module("devops", "DevOps et CI/CD, la ligne de production",
  "Intégration continue, qualité, artefacts, secrets, livraison progressive, retour arrière et mesure de la performance de livraison.",
  ["Mettre en place une CI rapide et bloquante", "Construire une fois et promouvoir un artefact vérifiable",
   "Déployer progressivement avec une garde humaine en production", "Préparer et tester le retour arrière"],
  ["Module Git", "Module Docker"], D, project, glossary)
