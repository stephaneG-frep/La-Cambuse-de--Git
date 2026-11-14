#!/usr/bin/env python3
"""Module « Observabilité, sécurité et SRE » : python3 tool/content/sre_module.py"""
from common import *

CO = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
LEAKS = "gitleaks/gitleaks-action@e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e # v3.0.0"

EXPR_5XX = "sum(rate(http_requests_total{code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) > 0.05"


def rule(name, expr=EXPR_5XX, for_="10m", severity="page", summary=True, runbook=True):
    y = f"      - alert: {name}\n        expr: {expr}\n"
    if for_:
        y += f"        for: {for_}\n"
    if severity:
        y += f"        labels:\n          severity: {severity}\n"
    ann = []
    if summary:
        ann.append(f"          summary: \"{name} : seuil dépassé\"\n")
    if runbook:
        ann.append(f"          runbook_url: https://wiki.exemple.org/runbooks/{name.lower()}\n")
    if ann:
        y += "        annotations:\n" + "".join(ann)
    return y


def rules(*r): return "groups:\n  - name: api\n    rules:\n" + "".join(r)


S = []

S.append(lesson("observabilite", "Observabilité : métriques, journaux, traces", 18,
  ["Distinguer les trois signaux", "Comprendre la différence entre surveiller et observer"],
  [t("Les métriques sont des nombres dans le temps (requêtes par seconde, latence, mémoire) : peu coûteuses, idéales pour "
     "alerter. Les journaux racontent des événements précis. Les traces suivent une requête à travers plusieurs services."),
   t("Surveiller, c'est vérifier des problèmes connus d'avance. Observer, c'est pouvoir répondre à des questions qu'on ne "
     "s'était pas posées, en croisant les signaux pendant un incident."),
   t("OpenTelemetry est le standard ouvert pour produire ces trois signaux depuis le code, quel que soit l'outil de stockage "
     "(Prometheus, Loki, Tempo, Jaeger, services commerciaux)."),
   tip("Commencez par les « signaux dorés » : latence, trafic, erreurs, saturation.")],
  [single("sr-1-1", "Signal le plus adapté pour déclencher une alerte ?", ["Les métriques", "Les traces uniquement", "Les captures d'écran", "Les tickets"], 0, "Peu coûteuses et agrégeables."),
   single("sr-1-2", "À quoi sert une trace distribuée ?", ["Suivre une requête à travers plusieurs services", "Compter les requêtes", "Stocker les mots de passe", "Remplacer les tests"], 0, "Elle montre où le temps est passé."),
   single("sr-1-3", "Quels sont les signaux dorés ?", ["Latence, trafic, erreurs, saturation", "CPU, RAM, disque, réseau uniquement", "Commits, PR, tickets, releases", "Aucun"], 0, "Point de départ d'un tableau de bord utile."),
   single("sr-1-4", "OpenTelemetry est…", ["Un standard ouvert pour produire métriques, journaux et traces", "Une base de données", "Un fournisseur cloud", "Un langage"], 0, "Il évite d'être lié à un outil.")]))

S.append(lesson("prometheus", "Métriques avec Prometheus", 22,
  ["Connaître les types de métriques", "Écrire des requêtes PromQL simples"],
  [t("Prometheus collecte (scrape) régulièrement les métriques exposées en texte par chaque service sur /metrics. Types : "
     "counter (ne fait qu'augmenter), gauge (monte et descend), histogram (répartition, ex. latences)."),
   code("rate(http_requests_total[5m])\nsum by (code) (rate(http_requests_total[5m]))\nhistogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))",
        "Débit, débit par code, latence au 95e centile"),
   t("Méthode RED pour un service : Rate (débit), Errors (erreurs), Duration (durée). Méthode USE pour une ressource : "
     "Utilisation, Saturation, Erreurs."),
   warn("Un label à forte cardinalité (identifiant d'utilisateur, URL complète) multiplie les séries et peut faire tomber Prometheus.")],
  [single("sr-2-1", "Type de métrique qui ne fait qu'augmenter ?", ["Counter", "Gauge", "Histogram", "Summary"], 0, "On en calcule le taux avec rate()."),
   single("sr-2-2", "Que calcule rate(x[5m]) ?", ["Le taux moyen par seconde sur 5 minutes", "La valeur maximale", "Le total depuis le démarrage", "La médiane"], 0, "À appliquer aux counters."),
   single("sr-2-3", "Pourquoi éviter un label user_id ?", ["Il crée une série par utilisateur (cardinalité explosive)", "Il est illégal", "Il est lent à écrire", "Aucun problème"], 0, "Les identifiants vont dans les journaux ou traces."),
   single("sr-2-4", "La méthode RED mesure…", ["Débit, erreurs, durée", "RAM, ethernet, disque", "Release, environnement, déploiement", "Rien"], 0, "Pour les services orientés requêtes.")]))

S.append(lesson("alertes", "Alerter sur les symptômes", 20,
  ["Écrire une règle d'alerte utile", "Réduire le bruit avec la durée et la sévérité"],
  [t("Une bonne alerte signale un symptôme ressenti par les utilisateurs (erreurs, lenteur), est actionnable et urgente. "
     "Le reste (CPU à 80 % sans impact) va dans un tableau de bord ou un ticket."),
   code(rules(rule("ApiErreurs5xx")), "Règle d'alerte Prometheus complète"),
   t("for: 10m exige que la condition dure 10 minutes avant d'alerter : une pointe passagère ne réveille personne. "
     "labels.severity permet à Alertmanager de router (page la nuit, ticket le jour)."),
   warn("Une équipe noyée sous les alertes finit par toutes les ignorer, y compris la bonne.")],
  [single("sr-3-1", "Une bonne alerte est…", ["Basée sur un symptôme, actionnable et urgente", "Déclenchée à chaque pointe de CPU", "Envoyée à tout le monde", "Silencieuse"], 0, "Sinon, tableau de bord ou ticket."),
   single("sr-3-2", "Rôle de for: 10m ?", ["N'alerter que si la condition dure 10 minutes", "Répéter 10 fois", "Attendre 10 minutes après résolution", "Limiter à 10 alertes"], 0, "Filtre les faux positifs."),
   single("sr-3-3", "À quoi sert labels.severity ?", ["Router l'alerte (astreinte, ticket…)", "Chiffrer l'alerte", "Changer la couleur", "Rien"], 0, "Alertmanager s'appuie dessus."),
   single("sr-3-4", "Risque de trop d'alertes ?", ["Elles finissent toutes ignorées", "Aucun", "Prometheus s'arrête", "Les métriques disparaissent"], 0, "La fatigue d'alerte est dangereuse.")],
  lab("alerts", "Cette alerte se déclenche à la moindre pointe et ne peut pas être routée. Corrigez-la.",
      rules(rule("ApiErreurs5xx", for_=None, severity=None)),
      [no("PR001", "Durée minimale (for)"), no("PR002", "Sévérité définie"), valid()],
      "Ajoutez for: 10m et labels: { severity: page }.",
      rules(rule("ApiErreurs5xx")))))

S.append(lesson("astreinte", "Runbooks et astreinte", 18,
  ["Rédiger un runbook utile", "Organiser une astreinte soutenable"],
  [t("Un runbook dit à la personne réveillée à 3 h ce que signifie l'alerte, comment vérifier l'impact, quelles actions "
     "tenter et qui appeler. Chaque alerte pointe vers le sien (annotation runbook_url)."),
   code("## ApiErreurs5xx\nImpact : les clients voient des erreurs.\nVérifier : tableau de bord API, derniers déploiements.\nActions : 1) rollback si déploiement < 1 h  2) …\nEscalade : équipe base de données si erreurs de connexion.",
        "Squelette de runbook"),
   t("Une astreinte soutenable : rotations courtes, relais clair, temps de récupération après une nuit agitée, et chaque "
     "alerte inutile supprimée ou corrigée."),
   tip("Si une action du runbook est toujours la même, automatisez-la.")],
  [single("sr-4-1", "Que doit contenir un runbook ?", ["Signification, vérifications, actions, escalade", "Le code source", "Les mots de passe", "L'historique Git"], 0, "Ce dont on a besoin en pleine nuit."),
   single("sr-4-2", "Comment relier une alerte à son runbook ?", ["Annotation runbook_url", "Un commentaire YAML", "Le nom du fichier", "Impossible"], 0, "Le lien apparaît dans la notification."),
   single("sr-4-3", "Une alerte qui réveille sans action possible…", ["Doit être corrigée ou supprimée", "Est normale", "Doit être doublée", "Doit être ignorée"], 0, "Une alerte inutile use l'équipe d'astreinte."),
   single("sr-4-4", "Action de runbook toujours identique ?", ["L'automatiser", "La garder manuelle", "La supprimer", "La cacher"], 0, "Moins d'interventions humaines.")],
  lab("alerts", "Ces alertes ne disent rien à la personne d'astreinte. Ajoutez résumé et runbook.",
      rules(rule("ApiLente", expr="histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 1", summary=False, runbook=False)),
      [no("PR003", "Résumé présent"), no("PR004", "Runbook lié"), valid()],
      "Ajoutez annotations: summary et runbook_url.",
      rules(rule("ApiLente", expr="histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 1")))))

S.append(lesson("journaux-traces", "Journaux structurés et traces", 18,
  ["Écrire des journaux exploitables", "Relier journaux et traces"],
  [code("{\"ts\":\"2026-11-13T10:42:01Z\",\"niveau\":\"error\",\"message\":\"paiement refusé\",\"commande\":\"C-1842\",\"trace_id\":\"4bf92f3577b34da6\"}",
        "Journal structuré (JSON) avec identifiant de trace"),
   t("Des journaux structurés se filtrent et s'agrègent (toutes les erreurs de paiement de la dernière heure) ; du texte libre se lit, "
     "mais se requête mal. Le trace_id relie un journal à la trace complète de la requête."),
   warn("Jamais de mot de passe, jeton, numéro de carte ou donnée personnelle superflue dans les journaux : ils sont copiés, "
        "conservés et consultés largement."),
   tip("Fixez une durée de conservation : des journaux gardés indéfiniment coûtent cher et augmentent le risque en cas de fuite.")],
  [single("sr-5-1", "Avantage d'un journal structuré ?", ["Il se filtre et s'agrège facilement", "Il est plus joli", "Il est chiffré", "Il est plus court"], 0, "Champs nommés plutôt que phrases."),
   single("sr-5-2", "À quoi sert le trace_id dans un journal ?", ["Relier le journal à la trace complète de la requête", "Chiffrer le journal", "Compter les lignes", "Identifier l'utilisateur"], 0, "Corrélation des signaux."),
   single("sr-5-3", "Que ne jamais écrire dans un journal ?", ["Mots de passe, jetons, numéros de carte", "Le niveau", "L'horodatage", "Le nom du service"], 0, "Les journaux circulent largement."),
   single("sr-5-4", "Pourquoi limiter la conservation des journaux ?", ["Coût et risque en cas de fuite", "Obligatoire pour JSON", "Accélérer l'application", "Aucune raison"], 0, "Et le RGPD impose la minimisation.")]))

S.append(lesson("slo", "SLI, SLO et budget d'erreur", 22,
  ["Définir un objectif de fiabilité mesurable", "Utiliser le budget d'erreur pour arbitrer"],
  [t("SLI : un indicateur mesuré (part des requêtes réussies en moins de 300 ms). SLO : l'objectif (99,9 % sur 30 jours). "
     "SLA : l'engagement contractuel, plus faible que le SLO."),
   t("99,9 % sur 30 jours laisse environ 43 minutes d'indisponibilité : c'est le budget d'erreur. Tant qu'il reste du budget, "
     "on livre ; s'il est épuisé, on privilégie la fiabilité."),
   code("# Taux de consommation du budget sur 1 h, alerte si > 14,4 (budget mensuel épuisé en ~2 jours)\n(sum(rate(http_requests_total{code=~\"5..\"}[1h])) / sum(rate(http_requests_total[1h]))) / 0.001 > 14.4",
        "Alerte sur le taux de consommation du budget"),
   tip("100 % n'est pas un objectif : il interdit tout changement et coûte infiniment cher.")],
  [single("sr-6-1", "Différence SLO / SLA ?", ["Le SLO est l'objectif interne, le SLA l'engagement contractuel", "Aucune", "Le SLA est plus strict", "Le SLO est un indicateur"], 0, "Le SLA laisse une marge."),
   single("sr-6-2", "Budget d'erreur de 99,9 % sur 30 jours ?", ["Environ 43 minutes", "Environ 4 heures", "Environ 4 secondes", "Aucun"], 0, "0,1 % de 43 200 minutes."),
   single("sr-6-3", "Budget épuisé : que faire ?", ["Prioriser la fiabilité avant les nouveautés", "Livrer plus", "Supprimer le SLO", "Rien"], 0, "C'est l'outil d'arbitrage."),
   single("sr-6-4", "Pourquoi ne pas viser 100 % ?", ["Coût infini et aucun changement possible", "C'est trop facile", "Prometheus ne le gère pas", "C'est la norme"], 0, "Les utilisateurs ne perçoivent pas la différence.")],
  lab("alerts", "Cette alerte de SLO n'a pas d'expression. Écrivez une alerte de consommation du budget d'erreur.",
      rules("      - alert: BudgetErreurRapide\n        expr: \"\"\n        for: 5m\n        labels:\n          severity: page\n        annotations:\n          summary: \"Le budget d'erreur se consomme trop vite\"\n          runbook_url: https://wiki.exemple.org/runbooks/budget\n"),
      [no("PR005", "Expression présente"), has("rate(", "Taux calculé sur les requêtes"), valid()],
      "Utilisez le ratio d'erreurs sur 1 h divisé par 0.001 (SLO 99,9 %), comparé à 14.4.",
      rules("      - alert: BudgetErreurRapide\n        expr: (sum(rate(http_requests_total{code=~\"5..\"}[1h])) / sum(rate(http_requests_total[1h]))) / 0.001 > 14.4\n        for: 5m\n        labels:\n          severity: page\n        annotations:\n          summary: \"Le budget d'erreur se consomme trop vite\"\n          runbook_url: https://wiki.exemple.org/runbooks/budget\n"))))

S.append(lesson("incidents", "Incidents et post-mortems sans blâme", 18,
  ["Conduire un incident avec des rôles clairs", "Apprendre d'un incident sans chercher de coupable"],
  [t("Pendant un incident : un responsable coordonne (il ne débogue pas), une personne communique, les autres enquêtent. "
     "Priorité : restaurer le service (rollback, bascule), comprendre ensuite."),
   t("Le post-mortem raconte la chronologie, l'impact, les causes (souvent plusieurs), ce qui a bien marché et des actions "
     "concrètes avec un responsable et une date."),
   t("« Sans blâme » ne veut pas dire sans responsabilité : on cherche pourquoi le système a permis l'erreur, car une personne "
     "punie cache la prochaine erreur au lieu de la signaler."),
   tip("Notez les horodatages au fil de l'eau pendant l'incident : la chronologie sera bien plus fiable.")],
  [single("sr-7-1", "Priorité pendant un incident ?", ["Restaurer le service", "Trouver le coupable", "Écrire le post-mortem", "Réécrire le code"], 0, "Comprendre vient après."),
   single("sr-7-2", "Rôle du responsable d'incident ?", ["Coordonner, pas déboguer", "Corriger seul le bug", "Communiquer à la presse", "Attendre"], 0, "Il garde la vue d'ensemble."),
   single("sr-7-3", "Pourquoi « sans blâme » ?", ["Pour que les erreurs soient signalées et corrigées dans le système", "Pour éviter de documenter", "Pour aller plus vite", "Par politesse"], 0, "La peur cache les problèmes."),
   single("sr-7-4", "Une action de post-mortem doit avoir…", ["Un responsable et une échéance", "Un coupable", "Un emoji", "Aucun suivi"], 0, "Sinon elle n'arrive jamais.")]))

S.append(lesson("supply-chain", "Chaîne d'approvisionnement logicielle", 22,
  ["Identifier les maillons à risque", "Épingler, inventorier et vérifier ses dépendances"],
  [t("Votre logiciel embarque des centaines de dépendances, des images de base, des actions de CI et des outils de build. "
     "Un seul maillon compromis (paquet piégé, compte de mainteneur volé) touche tous ses utilisateurs."),
   t("Défenses : épingler (fichiers de verrouillage, versions, empreintes), inventorier (SBOM CycloneDX ou SPDX), analyser "
     "(osv-scanner, trivy, Dependabot), vérifier l'origine (signatures Sigstore/cosign, attestations SLSA)."),
   code("osv-scanner --lockfile=package-lock.json\ntrivy image ghcr.io/exemple/api:1.4.0\ncosign verify ghcr.io/exemple/api:1.4.0 --certificate-identity-regexp '.*' --certificate-oidc-issuer https://token.actions.githubusercontent.com",
        "Analyser les dépendances, une image, vérifier une signature"),
   warn("Une image de base non épinglée (node:latest) change sous vos pieds : vous livrez du code que vous n'avez jamais testé.")],
  [single("sr-8-1", "Qu'est-ce qu'un SBOM ?", ["L'inventaire des composants d'un logiciel", "Un pare-feu", "Un test unitaire", "Un certificat TLS"], 0, "CycloneDX et SPDX sont les formats courants."),
   single("sr-8-2", "À quoi sert cosign ?", ["Signer et vérifier des images ou artefacts", "Compresser des images", "Scanner des ports", "Gérer des secrets"], 0, "cosign fait partie du projet Sigstore."),
   single("sr-8-3", "Pourquoi versionner les fichiers de verrouillage ?", ["Installer exactement les mêmes versions partout", "Pour la licence", "Pour le style", "Ce n'est pas utile"], 0, "Première défense contre les surprises."),
   single("sr-8-4", "Un mainteneur de dépendance se fait voler son compte. Risque ?", ["Une version piégée touche tous les utilisateurs non épinglés", "Aucun", "Seulement pour lui", "Le dépôt devient privé"], 0, "D'où épinglage et vérification.")],
  lab("dockerfile", "Cette image part d'une base mobile et tourne en root. Épinglez la base et passez en utilisateur non privilégié.",
      "FROM node:latest\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci --omit=dev\nCOPY . .\nCMD [\"node\", \"server.js\"]\n",
      [no("DF001", "Image de base épinglée"), no("DF002", "Utilisateur non root"), valid()],
      "Utilisez node:22.11-slim (ou un digest @sha256:… obtenu avec docker buildx imagetools inspect) et ajoutez USER node.",
      "FROM node:22.11-slim\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci --omit=dev\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n")))

S.append(lesson("ci-securisee", "Sécuriser la CI elle-même", 20,
  ["Traiter la CI comme une cible", "Ajouter une analyse de secrets à chaque PR"],
  [t("La CI détient des secrets de déploiement et peut publier des artefacts : c'est une cible de choix. Moindre privilège, "
     "actions épinglées, aucune donnée tierce injectée, secrets réservés aux environnements protégés."),
   t("Une analyse de secrets (gitleaks, détection de secrets GitLab) sur chaque PR attrape un jeton avant qu'il n'atteigne "
     "la branche principale."),
   code(f"secrets:\n  runs-on: ubuntu-24.04\n  timeout-minutes: 10\n  steps:\n    - uses: {CO}\n      with:\n        fetch-depth: 0\n        persist-credentials: false\n    - uses: {LEAKS}", "Job d'analyse de secrets épinglé"),
   tip("Activez aussi la protection contre le push de secrets proposée par la forge (push protection).")],
  [single("sr-9-1", "Pourquoi la CI est-elle une cible ?", ["Elle détient des secrets et publie des artefacts", "Elle est lente", "Elle est publique", "Elle n'a pas de mot de passe"], 0, "La compromettre, c'est compromettre la production."),
   single("sr-9-2", "Quand analyser les secrets ?", ["À chaque PR, avant la fusion", "Une fois par an", "Après la release", "Jamais"], 0, "Le plus tôt possible."),
   single("sr-9-3", "Pourquoi fetch-depth: 0 pour gitleaks ?", ["Analyser tout l'historique, pas seulement le dernier commit", "Accélérer", "Réduire la taille", "Obligatoire pour checkout"], 0, "Un secret peut être dans un commit antérieur."),
   single("sr-9-4", "La push protection…", ["Bloque un push contenant un secret reconnu", "Bloque tous les push", "Chiffre le dépôt", "Remplace la CI"], 0, "Un filet de plus côté forge.")],
  lab("workflow", "Ce workflow d'analyse de secrets a lui-même des failles : actions mobiles et droits totaux. Corrigez-le.",
      "name: Secrets\non:\n  pull_request:\npermissions: write-all\njobs:\n  secrets:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: actions/checkout@v4\n        with:\n          fetch-depth: 0\n          persist-credentials: false\n      - uses: gitleaks/gitleaks-action@v2\n",
      [no("GH001", "Actions épinglées par empreinte"), no("GH003", "Plus de write-all"), valid()],
      "permissions: contents: read ; checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 ; gitleaks-action@e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e.",
      f"name: Secrets\non:\n  pull_request:\npermissions:\n  contents: read\njobs:\n  secrets:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    steps:\n      - uses: {CO}\n        with:\n          fetch-depth: 0\n          persist-credentials: false\n      - uses: {LEAKS}\n")))

S.append(lesson("vulnerabilites", "Vulnérabilités et correctifs", 18,
  ["Prioriser les vulnérabilités", "Mettre à jour régulièrement et sans douleur"],
  [t("Toutes les CVE ne se valent pas : regardez si le composant vulnérable est réellement utilisé, exposé, et si une "
     "exploitation est connue (catalogue KEV). Le score CVSS seul ne suffit pas."),
   t("Mettre à jour souvent, par petites étapes (Dependabot, Renovate), coûte bien moins qu'un saut de trois versions majeures "
     "en urgence le jour d'une faille critique."),
   code("apiVersion: apps/v1\nkind: Deployment\n…\n        image: ghcr.io/exemple/api:1.4.1   # correctif de sécurité, version explicite", "Déployer un correctif par une version explicite"),
   warn("Mettre à jour vers « latest » n'est pas corriger : c'est perdre la maîtrise de ce qui tourne.")],
  [single("sr-10-1", "Pour prioriser une CVE, on regarde…", ["Usage réel, exposition et exploitation connue", "Seulement le score CVSS", "La date de publication", "Le nom de la faille"], 0, "Le contexte compte plus que le score seul."),
   single("sr-10-2", "Pourquoi des mises à jour fréquentes ?", ["Petites étapes faciles plutôt qu'un saut risqué en urgence", "Pour avoir plus de commits", "Obligatoire", "Aucun intérêt"], 0, "Renovate et Dependabot aident."),
   single("sr-10-3", "Que contient le catalogue KEV ?", ["Les vulnérabilités activement exploitées", "Toutes les licences", "Les mots de passe faibles", "Les images Docker"], 0, "Ce catalogue est publié par la CISA."),
   single("sr-10-4", "Corriger en passant l'image à latest…", ["Fait perdre la maîtrise de la version déployée", "Est la bonne pratique", "Est obligatoire", "Est plus sûr"], 0, "Utilisez une version explicite.")],
  lab("k8s", "Pour « corriger » une faille, ce Deployment est passé à latest. Déployez plutôt le correctif par sa version.",
      "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: api\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: api\n  template:\n    metadata:\n      labels:\n        app: api\n    spec:\n      containers:\n        - name: api\n          image: ghcr.io/exemple/api:latest\n",
      [no("K8001", "Version explicite"), has("1.4.1", "Version corrigée 1.4.1"), valid()],
      "image: ghcr.io/exemple/api:1.4.1",
      "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: api\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: api\n  template:\n    metadata:\n      labels:\n        app: api\n    spec:\n      containers:\n        - name: api\n          image: ghcr.io/exemple/api:1.4.1\n")))

project = {"title": "Alertes de production pour une API",
  "brief": "Rédigez les règles d'alerte d'une API : erreurs, latence et budget d'erreur, chacune avec durée, sévérité, résumé et runbook.",
  "lab": lab("alerts", "Objectif : aucun problème bloquant ni avertissement, et des runbooks partout.",
      rules(rule("ApiErreurs5xx", for_=None, severity=None, summary=False, runbook=False),
            rule("ApiLente", expr="histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 1", severity=None, runbook=False),
            "      - alert: BudgetErreurRapide\n        expr: \"\"\n"),
      [clean(), nowarn(), has("runbook_url", "Runbooks liés"), no("PR003", "Résumés présents"), no("PR004", "Un runbook par alerte")],
      "Reprenez les labos : expr, for, labels.severity, annotations summary et runbook_url pour chaque alerte.",
      rules(rule("ApiErreurs5xx"),
            rule("ApiLente", expr="histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 1", severity="ticket"),
            rule("BudgetErreurRapide", expr="(sum(rate(http_requests_total{code=~\"5..\"}[1h])) / sum(rate(http_requests_total[1h]))) / 0.001 > 14.4", for_="5m"))),
  "rubric": rubric(
    ("Pertinence", "Alertes sur des causes (CPU)", "Alertes sur des symptômes", "Symptômes liés aux SLO, alertes de consommation du budget"),
    ("Bruit", "Pointes déclenchent des alertes", "for: et sévérités", "Routage par sévérité, revue régulière des alertes inutiles"),
    ("Actionnabilité", "Aucune information", "Résumé", "Résumé, runbook à jour et escalade"),
    ("Chaîne logicielle", "Dépendances libres", "Épinglées et analysées", "Épinglées, SBOM, signatures vérifiées, mises à jour régulières"),
    ("Apprentissage", "Aucun retour d'incident", "Post-mortem", "Post-mortems sans blâme suivis d'actions datées"))}

glossary = [
  ("Observabilité", "Capacité à comprendre l'état d'un système à partir de ses signaux."), ("Métrique", "Valeur numérique mesurée dans le temps."),
  ("Trace", "Parcours d'une requête à travers les services."), ("OpenTelemetry", "Standard ouvert de production de télémétrie."),
  ("PromQL", "Langage de requête de Prometheus."), ("Cardinalité", "Nombre de séries distinctes créées par des labels."),
  ("SLI", "Indicateur de niveau de service mesuré."), ("SLO", "Objectif chiffré pour un SLI."), ("Budget d'erreur", "Marge d'indisponibilité autorisée par le SLO."),
  ("Runbook", "Procédure d'intervention liée à une alerte."), ("Post-mortem", "Analyse d'incident sans blâme suivie d'actions."),
  ("SBOM", "Inventaire des composants d'un logiciel."), ("Sigstore / cosign", "Signature et vérification d'artefacts."),
  ("CVE", "Identifiant public d'une vulnérabilité."),
]

write_module("sre", "Observabilité, sécurité et SRE, la vigie",
  "Métriques, journaux et traces, alertes utiles, runbooks, SLO et budget d'erreur, incidents, chaîne d'approvisionnement et vulnérabilités.",
  ["Instrumenter et observer un service", "Écrire des alertes actionnables liées aux SLO",
   "Conduire un incident et en tirer des leçons", "Sécuriser la chaîne d'approvisionnement et la CI"],
  ["Module Terraform et Ansible"], S, project, glossary)
