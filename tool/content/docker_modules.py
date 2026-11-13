#!/usr/bin/env python3
"""Source des modules Docker et Docker Compose de l'Académie.

Génère assets/courses/docker.json et assets/courses/compose.json :
    python3 tool/content/docker_modules.py

Les labos sont vérifiés par test/academy/docker_content_test.dart (le fichier de
départ échoue, la solution réussit, avec l'analyseur partagé).
"""
import json
import pathlib


def t(b): return {"type": "text", "body": b}
def code(b, c=None):
    d = {"type": "code", "body": b}
    if c: d["caption"] = c
    return d
def tip(b): return {"type": "tip", "body": b}
def warn(b): return {"type": "warning", "body": b}
def single(i, p, ch, a, e): return {"id": i, "type": "single", "prompt": p, "choices": ch, "answer": [a], "explanation": e}
def multi(i, p, ch, a, e): return {"id": i, "type": "multiple", "prompt": p, "choices": ch, "answer": a, "explanation": e}
def cmd(i, p, acc, e): return {"id": i, "type": "command", "prompt": p, "accepted": acc, "explanation": e}
def goal(type_, label, **kw): return {"type": type_, "label": label, **kw}
def lab(kind, intro, starter, goals, hint, solution):
    return {"kind": kind, "intro": intro, "starter": starter, "goals": goals, "hint": hint, "solution": solution}


# ====================================================================== DOCKER
D = []

D.append({"id": "pourquoi-conteneurs", "title": "Pourquoi les conteneurs ?", "minutes": 15,
  "objectives": ["Distinguer image, conteneur et machine virtuelle", "Savoir quand Docker est utile… et quand il ne l'est pas"],
  "sections": [
    t("Un conteneur exécute un programme isolé avec ses dépendances, en partageant le noyau de la machine hôte. "
      "Il démarre en une fraction de seconde et consomme bien moins qu'une machine virtuelle, qui embarque tout un système."),
    t("Une image est un modèle en lecture seule (le « plan du navire »), un conteneur est une instance en cours "
      "d'exécution de cette image. Une même image peut lancer des dizaines de conteneurs."),
    code("docker run --rm hello-world\ndocker ps -a", "Lancer un conteneur de démonstration, puis lister les conteneurs"),
    warn("Docker n'est pas magique : une application Flutter mobile ou de bureau se distribue en APK ou en paquet .deb, "
         "elle ne tourne pas dans un conteneur. Docker sert plutôt aux serveurs, API, bases de données et outils de CI."),
    tip("L'accès au démon Docker équivaut à des droits root sur la machine : le mode « rootless » limite ce risque."),
  ],
  "quiz": [
    single("dk-1-1", "Quelle différence entre une image et un conteneur ?",
           ["L'image est un modèle en lecture seule, le conteneur une instance qui s'exécute", "Ce sont des synonymes",
            "Le conteneur est stocké sur Docker Hub, l'image sur le PC", "L'image tourne, le conteneur dort"], 0,
           "On construit une image une fois, puis on lance autant de conteneurs que nécessaire à partir d'elle."),
    single("dk-1-2", "Pourquoi un conteneur est-il plus léger qu'une machine virtuelle ?",
           ["Il partage le noyau de l'hôte au lieu d'embarquer un système complet", "Il est compressé", "Il n'a pas de fichiers", "Il tourne sur le GPU"], 0,
           "Pas de système invité à démarrer : seul le processus isolé et ses bibliothèques sont présents."),
    single("dk-1-3", "Faut-il conteneuriser une application Flutter Android pour la distribuer ?",
           ["Non : elle se distribue en APK, Docker peut servir à la CI ou à un backend", "Oui, toujours", "Oui, sinon elle ne compile pas", "Seulement sur iOS"], 0,
           "Conteneuriser pour le principe ajoute de la complexité sans bénéfice : on choisit Docker pour un besoin réel."),
    single("dk-1-4", "Pourquoi l'appartenance au groupe « docker » est-elle sensible ?",
           ["Elle équivaut à des droits root sur la machine", "Elle ralentit Docker", "Elle empêche le réseau", "Elle supprime les images"], 0,
           "Le démon Docker tourne en root : qui le pilote peut monter n'importe quel dossier de l'hôte dans un conteneur."),
  ]})

D.append({"id": "images-registres", "title": "Images, tags et registres", "minutes": 18,
  "objectives": ["Lire un nom d'image complet", "Épingler une version pour des builds reproductibles"],
  "sections": [
    t("Un nom d'image se lit registre/espace/nom:tag, par exemple docker.io/library/node:22.11-slim. Sans registre, "
      "Docker Hub est utilisé ; sans tag, c'est « latest »."),
    warn("« latest » n'est qu'une étiquette mobile, pas la « dernière version stable » : votre build peut changer du jour au "
         "lendemain sans que vous ayez modifié une ligne."),
    t("Pour une reproductibilité totale, on peut référencer le digest : node@sha256:… désigne un contenu exact et immuable."),
    code("docker pull node:22.11-slim\ndocker image ls\ndocker image inspect node:22.11-slim", "Télécharger, lister et inspecter une image"),
    tip("Les variantes -slim et -alpine sont plus légères ; alpine utilise musl, ce qui peut gêner certaines bibliothèques natives."),
  ],
  "lab": lab("dockerfile", "Ce Dockerfile utilise une image non épinglée. Rendez le build reproductible.",
    "FROM node\nWORKDIR /app\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n",
    [goal("noRule", "Image de base épinglée (pas de latest)", rule="DF001"), goal("valid", "Dockerfile valide")],
    "Ajoutez une version précise après le nom : node:22.11-slim.",
    "FROM node:22.11-slim\nWORKDIR /app\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n"),
  "quiz": [
    single("dk-2-1", "Que désigne une image sans tag, comme « node » ?",
           ["node:latest, une étiquette mobile", "La version la plus stable", "La version installée sur le PC", "Une erreur"], 0,
           "Sans tag, Docker utilise latest, qui peut pointer vers n'importe quelle version au fil du temps."),
    single("dk-2-2", "Quelle référence garantit un contenu strictement identique ?",
           ["node@sha256:…", "node:latest", "node:lts", "node"], 0,
           "Le digest est l'empreinte du contenu : il ne peut pas changer."),
    cmd("dk-2-3", "Quelle commande liste les images présentes localement ?", ["docker image ls", "docker images"],
        "docker image ls (ou l'alias docker images) affiche dépôt, tag, identifiant et taille."),
    single("dk-2-4", "Sans registre indiqué, d'où vient l'image ?", ["Docker Hub", "GitHub", "Le dossier courant", "Nulle part"], 0,
           "docker.io (Docker Hub) est le registre par défaut ; d'autres existent (ghcr.io, registry.gitlab.com…)."),
  ]})

D.append({"id": "premier-dockerfile", "title": "Écrire son premier Dockerfile", "minutes": 20,
  "objectives": ["Connaître FROM, WORKDIR, COPY, RUN, CMD", "Utiliser la forme JSON de CMD"],
  "sections": [
    code("FROM python:3.12.7-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY . .\nCMD [\"python\", \"-m\", \"app\"]",
         "Un Dockerfile minimal"),
    t("FROM choisit l'image de base, WORKDIR fixe le répertoire de travail (chemin absolu), COPY copie des fichiers, RUN exécute "
      "une commande pendant le build, CMD indique le programme lancé au démarrage du conteneur."),
    t("La forme JSON (CMD [\"python\", \"-m\", \"app\"]) lance le programme directement : il reçoit les signaux d'arrêt et "
      "s'arrête proprement. La forme « shell » passe par /bin/sh, qui ne relaie pas toujours ces signaux."),
    code("docker build -t mon-appli:1.0 .\ndocker run --rm -p 8000:8000 mon-appli:1.0", "Construire puis lancer"),
    tip("« cd » dans un RUN ne persiste pas : utilisez WORKDIR."),
  ],
  "lab": lab("dockerfile", "Corrigez le répertoire de travail et la commande de démarrage.",
    "FROM python:3.12.7-slim\nWORKDIR app\nCOPY . .\nRUN pip install --no-cache-dir -r requirements.txt\nUSER nobody\nCMD python -m app\n",
    [goal("noRule", "WORKDIR absolu", rule="DF013"), goal("noRule", "CMD en forme JSON", rule="DF014"), goal("instruction", "Une instruction CMD est présente", keyword="CMD")],
    "WORKDIR /app et CMD [\"python\", \"-m\", \"app\"].",
    "FROM python:3.12.7-slim\nWORKDIR /app\nCOPY . .\nRUN pip install --no-cache-dir -r requirements.txt\nUSER nobody\nCMD [\"python\", \"-m\", \"app\"]\n"),
  "quiz": [
    single("dk-3-1", "Quelle instruction s'exécute au démarrage du conteneur (et non pendant le build) ?", ["CMD", "RUN", "COPY", "FROM"], 0,
           "RUN agit pendant la construction de l'image ; CMD définit ce qui est lancé à chaque démarrage."),
    single("dk-3-2", "Pourquoi préférer CMD [\"node\", \"app.js\"] à CMD node app.js ?",
           ["Le processus reçoit directement les signaux d'arrêt", "C'est plus court", "Pour éviter le réseau", "Pour activer le cache"], 0,
           "La forme JSON évite un shell intermédiaire : docker stop arrête l'application proprement."),
    cmd("dk-3-3", "Construisez l'image du dossier courant avec le nom mon-appli et le tag 1.0.", ["docker build -t mon-appli:1.0 ."],
        "-t donne le nom et le tag ; le point final désigne le contexte de build (dossier courant)."),
    single("dk-3-4", "Comment changer durablement de répertoire dans un Dockerfile ?", ["WORKDIR /chemin", "RUN cd /chemin", "ENV PWD=/chemin", "COPY /chemin"], 0,
           "Chaque RUN démarre un nouveau shell ; WORKDIR s'applique à toutes les instructions suivantes."),
  ]})

D.append({"id": "cycle-de-vie", "title": "Le cycle de vie d'un conteneur", "minutes": 18,
  "objectives": ["Lancer, observer, arrêter et supprimer un conteneur", "Lire les journaux et entrer dans un conteneur"],
  "sections": [
    code("docker run -d --name web -p 127.0.0.1:8080:80 nginx:1.27\ndocker ps\ndocker logs --tail 50 web\ndocker exec -it web sh\ndocker stop web\ndocker rm web",
         "Lancer en arrière-plan, lister, lire les journaux, ouvrir un shell, arrêter, supprimer"),
    t("-d détache le conteneur, --name lui donne un nom, -p publie un port (hôte:conteneur). --rm supprime automatiquement le "
      "conteneur à l'arrêt : pratique pour les essais."),
    warn("docker rm supprime le conteneur et ses données non persistées ; docker system prune supprime en masse : à utiliser en "
         "sachant ce que l'on jette. La Cambuse ne lance jamais ces commandes à votre place."),
    tip("L'écran « Salle des machines » de l'Atelier liste vos conteneurs et affiche leurs journaux en lecture seule."),
  ],
  "quiz": [
    cmd("dk-4-1", "Affichez les 50 dernières lignes du journal du conteneur « web ».", ["docker logs --tail 50 web", "docker logs -n 50 web"],
        "--tail (ou -n) limite le nombre de lignes ; ajoutez -f pour suivre en direct."),
    single("dk-4-2", "Que fait l'option --rm de docker run ?", ["Supprime le conteneur quand il s'arrête", "Supprime l'image", "Redémarre le conteneur", "Retire le réseau"], 0,
           "Idéal pour les commandes ponctuelles : pas de conteneurs arrêtés qui s'accumulent."),
    single("dk-4-3", "-p 127.0.0.1:8080:80 signifie :", ["Le port 80 du conteneur est joignable sur le port 8080 de l'hôte, en local uniquement",
           "Le port 8080 du conteneur est publié sur le 80", "Tous les ports sont ouverts", "Le conteneur n'a pas de réseau"], 0,
           "Format hôte:conteneur ; préfixer par 127.0.0.1 évite d'exposer le service au réseau local."),
    cmd("dk-4-4", "Listez tous les conteneurs, y compris arrêtés.", ["docker ps -a", "docker ps --all", "docker container ls -a"],
        "Sans -a, seuls les conteneurs en cours d'exécution apparaissent."),
  ]})

D.append({"id": "couches-cache", "title": "Couches et cache de build", "minutes": 18,
  "objectives": ["Comprendre les couches d'une image", "Ordonner les instructions pour profiter du cache"],
  "sections": [
    t("Chaque instruction crée une couche. Si une instruction et son contexte n'ont pas changé, Docker réutilise la couche en cache. "
      "Dès qu'une couche change, toutes les suivantes sont reconstruites."),
    t("On copie donc d'abord ce qui change rarement (le fichier des dépendances), on installe, puis on copie le code qui change souvent."),
    code("COPY package.json package-lock.json ./\nRUN npm ci\nCOPY . .", "Bon ordre : les dépendances restent en cache tant que package.json ne change pas"),
    tip("Un fichier .dockerignore (node_modules, .git, .env…) réduit le contexte envoyé et évite d'invalider le cache inutilement."),
  ],
  "lab": lab("dockerfile", "Ce Dockerfile réinstalle les dépendances à chaque modification du code. Réordonnez-le.",
    "FROM node:22.11-slim\nWORKDIR /app\nCOPY . .\nRUN npm ci\nUSER node\nCMD [\"node\", \"server.js\"]\n",
    [goal("noRule", "Dépendances installées avant la copie du code", rule="DF007"), goal("contains", "package.json copié à part", text="COPY package")],
    "Copiez d'abord package.json et package-lock.json, lancez npm ci, puis copiez le reste.",
    "FROM node:22.11-slim\nWORKDIR /app\nCOPY package.json package-lock.json ./\nRUN npm ci\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n"),
  "quiz": [
    single("dk-5-1", "Une couche change. Que devient le cache des instructions suivantes ?", ["Il est invalidé : elles sont reconstruites", "Il est conservé", "Il est supprimé du disque", "Il passe en lecture seule"], 0,
           "Le cache est séquentiel : tout ce qui suit une couche modifiée est refait."),
    single("dk-5-2", "Pourquoi copier package.json avant le reste du code ?", ["Pour garder npm ci en cache tant que les dépendances ne changent pas",
           "Pour que l'image soit plus jolie", "Parce que COPY . . est interdit", "Pour exécuter les tests"], 0,
           "Modifier le code ne touche plus la couche des dépendances : builds bien plus rapides."),
    single("dk-5-3", "À quoi sert .dockerignore ?", ["Exclure des fichiers du contexte de build", "Ignorer des erreurs", "Masquer des conteneurs", "Désactiver le cache"], 0,
           "Il évite d'envoyer node_modules, .git ou des secrets au démon, et de les copier par erreur."),
    multi("dk-5-4", "Que mettre dans un .dockerignore ? (plusieurs réponses)", [".git", ".env", "node_modules", "Le code source principal"], [0, 1, 2],
          "On exclut l'historique, les secrets et les dépendances locales ; le code, lui, doit être copié."),
  ]})

D.append({"id": "multi-etapes", "title": "Builds multi-étapes", "minutes": 20,
  "objectives": ["Séparer construction et exécution", "Réduire la taille et la surface d'attaque de l'image finale"],
  "sections": [
    t("Un build multi-étapes utilise plusieurs FROM : une étape lourde compile, une étape légère n'emporte que le résultat. "
      "Les outils de compilation ne se retrouvent pas dans l'image finale."),
    code("FROM golang:1.23.3 AS build\nWORKDIR /src\nCOPY . .\nRUN CGO_ENABLED=0 go build -o /out/appli\n\nFROM gcr.io/distroless/static-debian12:nonroot\nCOPY --from=build /out/appli /appli\nUSER nonroot\nCMD [\"/appli\"]",
         "Compilation dans golang, exécution dans une image minimale"),
    tip("COPY --from=build reprend des fichiers d'une étape précédente nommée avec AS."),
  ],
  "lab": lab("dockerfile", "Ce Dockerfile embarque Node et les outils de build dans l'image finale. Passez en multi-étapes.",
    "FROM node:22.11-slim\nWORKDIR /app\nCOPY package.json package-lock.json ./\nRUN npm ci\nCOPY . .\nRUN npm run build\nUSER node\nCMD [\"node\", \"dist/server.js\"]\n",
    [goal("stages", "Au moins deux étapes (FROM … AS build)", min=2), goal("noRule", "Build et exécution séparés", rule="DF010"), goal("contains", "Résultat copié depuis l'étape de build", text="--from=build")],
    "Nommez la première étape « AS build », puis ajoutez un second FROM et COPY --from=build /app/dist ./dist.",
    "FROM node:22.11-slim AS build\nWORKDIR /app\nCOPY package.json package-lock.json ./\nRUN npm ci\nCOPY . .\nRUN npm run build\n\nFROM node:22.11-slim\nWORKDIR /app\nCOPY --from=build /app/dist ./dist\nUSER node\nCMD [\"node\", \"dist/server.js\"]\n"),
  "quiz": [
    single("dk-6-1", "Quel est l'intérêt principal d'un build multi-étapes ?", ["Une image finale sans les outils de compilation", "Un build plus lent mais plus sûr", "Plusieurs conteneurs à la fois", "Éviter Docker Hub"], 0,
           "Moins de fichiers = image plus légère et moins de logiciels exploitables par un attaquant."),
    cmd("dk-6-2", "Écrivez l'instruction qui copie /out/appli depuis l'étape nommée build vers /appli.", ["COPY --from=build /out/appli /appli"],
        "--from accepte le nom donné avec AS (ou l'index de l'étape)."),
    single("dk-6-3", "Comment nomme-t-on une étape ?", ["FROM image AS nom", "STAGE nom", "LABEL stage=nom", "ARG nom"], 0,
           "Le nom permet ensuite de la référencer dans COPY --from=nom."),
    single("dk-6-4", "Une image « distroless » contient :", ["L'application et ses bibliothèques, sans shell ni gestionnaire de paquets", "Tout Debian", "Uniquement un shell", "Aucun fichier"], 0,
           "Sans shell, un attaquant a beaucoup moins d'outils ; en contrepartie, le débogage se fait autrement."),
  ]})

D.append({"id": "non-root", "title": "Utilisateur non root et permissions", "minutes": 16,
  "objectives": ["Exécuter le conteneur avec un utilisateur dédié", "Éviter les permissions trop larges"],
  "sections": [
    t("Par défaut, un conteneur s'exécute en root. Si l'application est compromise, l'attaquant a tous les droits dans le conteneur, "
      "et une faille d'isolation pourrait lui ouvrir l'hôte."),
    code("RUN useradd --create-home --uid 10001 appli\nCOPY --chown=appli . /app\nUSER appli", "Créer un utilisateur, lui donner les fichiers, basculer dessus"),
    warn("chmod 777 donne à tout le monde le droit de modifier : on attribue plutôt la propriété (chown) et des droits minimaux."),
    tip("Beaucoup d'images officielles fournissent déjà un utilisateur : node, nobody, nonroot (distroless)."),
  ],
  "lab": lab("dockerfile", "Ce conteneur tourne en root avec des permissions trop larges. Sécurisez-le.",
    "FROM python:3.12.7-slim\nWORKDIR /app\nCOPY . .\nRUN chmod -R 777 /app\nCMD [\"python\", \"-m\", \"app\"]\n",
    [goal("noRule", "Utilisateur non root", rule="DF002"), goal("noRule", "Pas de chmod 777", rule="DF015")],
    "Remplacez le chmod par useradd + COPY --chown, puis USER appli avant CMD.",
    "FROM python:3.12.7-slim\nWORKDIR /app\nRUN useradd --create-home --uid 10001 appli\nCOPY --chown=appli . .\nUSER appli\nCMD [\"python\", \"-m\", \"app\"]\n"),
  "quiz": [
    single("dk-7-1", "Pourquoi ne pas laisser un conteneur tourner en root ?", ["Une compromission donnerait tous les droits dans le conteneur", "C'est plus lent", "Docker l'interdit", "Pour économiser la mémoire"], 0,
           "Le principe du moindre privilège limite les dégâts en cas de faille."),
    cmd("dk-7-2", "Écrivez l'instruction qui bascule sur l'utilisateur « appli ».", ["USER appli"],
        "Toutes les instructions suivantes et le processus principal s'exécutent alors sous cet utilisateur."),
    single("dk-7-3", "Quelle alternative à chmod 777 ?", ["chown vers l'utilisateur dédié et droits minimaux", "chmod 666", "sudo", "Lancer en root"], 0,
           "On donne la propriété au bon utilisateur, pas les droits à tout le monde."),
    single("dk-7-4", "Où placer USER dans un Dockerfile ?", ["Après les installations qui nécessitent root, avant CMD", "Tout en haut, avant FROM", "Nulle part", "Après CMD"], 0,
           "Les installations système se font en root ; on bascule ensuite pour l'exécution."),
  ]})

D.append({"id": "secrets-config", "title": "Secrets et configuration", "minutes": 18,
  "objectives": ["Ne jamais graver de secret dans une image", "Fournir la configuration à l'exécution"],
  "sections": [
    t("Tout ce qui est écrit dans un Dockerfile (ENV, ARG, fichiers copiés) reste lisible dans les couches de l'image, même si on le "
      "supprime plus tard. Quiconque récupère l'image récupère le secret."),
    code("docker run -e DB_PASSWORD -p 127.0.0.1:8000:8000 mon-appli:1.0", "Le secret est fourni à l'exécution, depuis votre environnement"),
    code("RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci", "Secret de build (BuildKit) : disponible pendant RUN, absent de l'image"),
    warn("Un secret publié par erreur doit être considéré comme compromis : révoquez-le, même après l'avoir retiré."),
  ],
  "lab": lab("dockerfile", "Une clé est écrite en clair dans l'image. Retirez-la : elle sera fournie à l'exécution.",
    "FROM node:22.11-slim\nWORKDIR /app\nENV NODE_ENV=production\nENV API_KEY=cle-secrete-de-prod-123\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n",
    [goal("noRule", "Aucun secret dans le Dockerfile", rule="DF003"), goal("noSeverity", "Aucun problème bloquant", severity="blocking"), goal("notContains", "La valeur a disparu", text="cle-secrete")],
    "Supprimez la ligne ENV API_KEY : la clé sera passée avec docker run -e API_KEY.",
    "FROM node:22.11-slim\nWORKDIR /app\nENV NODE_ENV=production\nCOPY . .\nUSER node\nCMD [\"node\", \"server.js\"]\n"),
  "quiz": [
    single("dk-8-1", "Un secret mis dans ENV puis supprimé dans une couche suivante est-il protégé ?", ["Non, il reste lisible dans la couche où il a été écrit", "Oui", "Oui si l'image est privée", "Oui après docker rmi"], 0,
           "Les couches sont empilées, pas effacées : l'historique de l'image contient toujours la valeur."),
    single("dk-8-2", "Comment fournir un mot de passe à un conteneur ?", ["À l'exécution (variable d'environnement, secret Compose ou orchestrateur)", "Dans le Dockerfile", "Dans le nom de l'image", "Dans un tag"], 0,
           "L'image reste générique et partageable ; le secret vit hors de l'image."),
    single("dk-8-3", "À quoi sert RUN --mount=type=secret ?", ["Utiliser un secret pendant le build sans l'inscrire dans l'image", "Monter un volume persistant", "Chiffrer l'image", "Ouvrir un port"], 0,
           "Le fichier n'est visible que pendant l'instruction RUN concernée."),
    single("dk-8-4", "Un jeton a été publié dans une image. Que faire en premier ?", ["Le révoquer et en créer un nouveau", "Supprimer le tag", "Renommer l'image", "Attendre"], 0,
           "Supprimer l'image ne suffit pas : des copies ont pu être tirées. Seule la révocation protège."),
  ]})

D.append({"id": "volumes-reseaux", "title": "Volumes et réseaux", "minutes": 18,
  "objectives": ["Persister des données avec les volumes", "Faire communiquer des conteneurs sur un réseau"],
  "sections": [
    t("Le système de fichiers d'un conteneur disparaît avec lui. Pour garder des données (base de données…), on utilise un volume nommé, "
      "géré par Docker, ou un montage de dossier de l'hôte (bind mount)."),
    code("docker volume create donnees\ndocker run -d --name pg -v donnees:/var/lib/postgresql/data postgres:17.2-alpine", "Volume nommé pour une base de données"),
    t("Sur un réseau défini par l'utilisateur, les conteneurs se joignent par leur nom : l'application contacte « pg » au lieu d'une adresse IP."),
    code("docker network create cambuse\ndocker run -d --network cambuse --name pg postgres:17.2-alpine", "Réseau dédié avec résolution des noms"),
    warn("Monter /var/run/docker.sock dans un conteneur lui donne le contrôle total de l'hôte."),
  ],
  "quiz": [
    single("dk-9-1", "Que deviennent les fichiers écrits dans un conteneur supprimé, hors volume ?", ["Ils sont perdus", "Ils sont conservés dans l'image", "Ils vont dans /tmp de l'hôte", "Ils sont envoyés au registre"], 0,
           "La couche d'écriture du conteneur disparaît avec lui : les données à garder vont dans un volume."),
    cmd("dk-9-2", "Créez un volume nommé « donnees ».", ["docker volume create donnees"], "Il pourra être monté avec -v donnees:/chemin/dans/le/conteneur."),
    single("dk-9-3", "Sur un réseau Docker défini par l'utilisateur, comment l'appli joint-elle la base « pg » ?", ["Par son nom : pg", "Par l'IP de l'hôte", "Par localhost", "Impossible"], 0,
           "Docker fournit un DNS interne qui résout le nom des conteneurs du même réseau."),
    single("dk-9-4", "Pourquoi ne pas monter /var/run/docker.sock dans un conteneur applicatif ?", ["Il pourrait contrôler tout Docker, donc l'hôte", "C'est lent", "Le fichier est vide", "Cela supprime les volumes"], 0,
           "Le socket donne l'accès complet au démon : c'est l'équivalent d'un accès root."),
  ]})

D.append({"id": "sante-securite", "title": "Santé, journaux et chaîne d'approvisionnement", "minutes": 20,
  "objectives": ["Déclarer un HEALTHCHECK", "Éviter curl | sh et alléger les installations système"],
  "sections": [
    code("HEALTHCHECK --interval=30s --timeout=3s CMD [\"curl\", \"-fsS\", \"http://127.0.0.1:8080/health\"]", "Docker sait si l'application répond"),
    t("Un conteneur « Up » n'est pas forcément en bonne santé. HEALTHCHECK permet à Docker (et à Compose) de distinguer « démarré » et "
      "« prêt », et de redémarrer un service bloqué."),
    warn("curl … | sh exécute un script téléchargé sans vérification : si le serveur est compromis, votre image aussi. Téléchargez, "
         "vérifiez la somme SHA-256, puis exécutez."),
    code("RUN apt-get update \\\n    && apt-get install -y --no-install-recommends curl \\\n    && rm -rf /var/lib/apt/lists/*", "Installation système légère"),
  ],
  "lab": lab("dockerfile", "Ajoutez un contrôle de santé, supprimez le curl | sh et allégez l'installation apt.",
    "FROM debian:12.8-slim\nRUN apt-get update && apt-get install -y curl\nRUN curl -fsSL https://outil.exemple.com/install.sh | sh\nUSER nobody\nCMD [\"/usr/local/bin/outil\"]\n",
    [goal("noRule", "HEALTHCHECK présent", rule="DF008"), goal("noRule", "Pas de curl | sh", rule="DF009"), goal("noRule", "apt allégé et nettoyé", rule="DF005")],
    "Téléchargez le script dans un fichier, vérifiez-le, ajoutez --no-install-recommends et rm -rf /var/lib/apt/lists/*, puis HEALTHCHECK.",
    "FROM debian:12.8-slim\nRUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*\n"
    "RUN curl -fsSL -o /tmp/install.sh https://outil.exemple.com/install.sh && echo \"<sha256>  /tmp/install.sh\" | sha256sum -c && sh /tmp/install.sh\n"
    "USER nobody\nHEALTHCHECK CMD [\"/usr/local/bin/outil\", \"--version\"]\nCMD [\"/usr/local/bin/outil\"]\n"),
  "quiz": [
    single("dk-10-1", "Que permet HEALTHCHECK ?", ["Savoir si l'application répond vraiment", "Accélérer le build", "Chiffrer le trafic", "Limiter la mémoire"], 0,
           "L'état passe à healthy ou unhealthy ; Compose peut attendre qu'un service soit healthy."),
    single("dk-10-2", "Pourquoi éviter curl … | sh dans un Dockerfile ?", ["Le script n'est pas vérifié : une compromission du serveur infecte l'image", "C'est trop lent", "curl est interdit", "sh n'existe pas"], 0,
           "On vérifie l'intégrité (somme SHA-256, signature) avant d'exécuter."),
    multi("dk-10-3", "Bonnes pratiques apt dans un Dockerfile : (plusieurs réponses)", ["--no-install-recommends", "rm -rf /var/lib/apt/lists/* dans le même RUN", "apt-get upgrade à chaque build", "Regrouper update et install"], [0, 1, 3],
          "upgrade rend le build non reproductible : on met plutôt à jour l'image de base épinglée."),
    single("dk-10-4", "Un conteneur « Up » est-il forcément en bonne santé ?", ["Non : le processus tourne mais l'appli peut être bloquée", "Oui", "Oui s'il a un port", "Oui s'il a un nom"], 0,
           "D'où l'intérêt du HEALTHCHECK, qui interroge réellement l'application."),
  ]})

docker_project = {"title": "Radoub complet d'un Dockerfile",
  "brief": "Un Dockerfile hérité cumule les mauvaises pratiques. Rendez-le reproductible, léger, sans secret, non root, multi-étapes et surveillé.",
  "lab": lab("dockerfile", "Objectif : plus aucun problème bloquant ni avertissement, deux étapes, un HEALTHCHECK.",
    "FROM node\nWORKDIR app\nENV DB_PASSWORD=motdepasse123\nRUN apt-get update && apt-get upgrade -y\nCOPY . .\nRUN npm install && npm run build && chmod -R 777 /app\nEXPOSE 3000\nCMD npm start\n",
    [goal("noSeverity", "Aucun problème bloquant", severity="blocking"), goal("noSeverity", "Aucun avertissement", severity="warning"),
     goal("stages", "Build multi-étapes", min=2), goal("instruction", "HEALTHCHECK déclaré", keyword="HEALTHCHECK"), goal("noRule", "CMD en forme JSON", rule="DF014")],
    "Partez du modèle de la leçon multi-étapes et appliquez une à une les corrections des leçons précédentes.",
    "FROM node:22.11-slim AS build\nWORKDIR /app\nCOPY package.json package-lock.json ./\nRUN npm ci\nCOPY . .\nRUN npm run build\n\n"
    "FROM node:22.11-slim\nWORKDIR /app\nENV NODE_ENV=production\nCOPY package.json package-lock.json ./\nRUN npm ci --omit=dev\nCOPY --from=build /app/dist ./dist\n"
    "USER node\nEXPOSE 3000\nHEALTHCHECK CMD [\"node\", \"dist/health.js\"]\nCMD [\"node\", \"dist/server.js\"]\n"),
  "rubric": [
    {"criterion": "Reproductibilité", "levels": ["Images latest, upgrade", "Versions épinglées", "Versions épinglées et build déterministe (npm ci, verrous)"]},
    {"criterion": "Sécurité", "levels": ["Root et secrets en clair", "Non root ou sans secret", "Non root, sans secret, permissions minimales"]},
    {"criterion": "Taille de l'image", "levels": ["Outils de build embarqués", "Variante slim", "Multi-étapes, seulement le nécessaire"]},
    {"criterion": "Cache de build", "levels": ["Tout recopié avant les dépendances", "Ordre partiellement optimisé", "Dépendances isolées, .dockerignore"]},
    {"criterion": "Exploitation", "levels": ["Ni santé ni arrêt propre", "HEALTHCHECK ou CMD JSON", "HEALTHCHECK et CMD JSON"]},
  ]}

docker_glossary = [
  ("Image", "Modèle en lecture seule composé de couches, à partir duquel on lance des conteneurs."),
  ("Conteneur", "Processus isolé lancé à partir d'une image, avec sa propre couche d'écriture."),
  ("Dockerfile", "Recette textuelle décrivant la construction d'une image."),
  ("Couche", "Résultat d'une instruction du Dockerfile, mise en cache et partagée entre images."),
  ("Tag", "Étiquette lisible d'une image (ex. 22.11-slim) ; latest est une étiquette mobile."),
  ("Digest", "Empreinte SHA-256 identifiant un contenu d'image exact et immuable."),
  ("Registre", "Serveur stockant des images (Docker Hub, ghcr.io, registry.gitlab.com)."),
  ("Build multi-étapes", "Dockerfile à plusieurs FROM séparant compilation et exécution."),
  ("Volume", "Stockage persistant géré par Docker, indépendant du cycle de vie des conteneurs."),
  ("Bind mount", "Montage d'un dossier de l'hôte dans un conteneur."),
  ("HEALTHCHECK", "Commande indiquant à Docker si l'application répond."),
  ("Rootless", "Mode où le démon Docker tourne sans privilèges root."),
  (".dockerignore", "Liste des fichiers exclus du contexte de build."),
  ("Distroless", "Image minimale sans shell ni gestionnaire de paquets."),
]

docker_module = {
  "id": "docker", "version": 1, "title": "Docker, du conteneur à l'image propre",
  "summary": "Comprendre les conteneurs, écrire des Dockerfile reproductibles, légers et sûrs, et les exploiter sereinement.",
  "objectives": ["Expliquer images, conteneurs, couches et registres", "Écrire un Dockerfile multi-étapes non root et sans secret",
                 "Exploiter un conteneur : journaux, volumes, réseaux, santé", "Reconnaître quand Docker n'est pas utile (apps Flutter)"],
  "prerequisites": ["Module Git", "Notions de ligne de commande (module Terminal Linux recommandé, phase 9)"],
  "lessons": D, "project": docker_project,
  "glossary": [{"term": a, "definition": b} for a, b in docker_glossary],
}

# ===================================================================== COMPOSE
C = []

C.append({"id": "pourquoi-compose", "title": "Pourquoi Docker Compose ?", "minutes": 14,
  "objectives": ["Décrire une application multi-services dans un fichier", "Connaître up, down, ps, logs"],
  "sections": [
    t("Une application réelle combine souvent plusieurs conteneurs : une API, une base de données, un cache. Compose les décrit dans un "
      "seul fichier compose.yaml et les démarre ensemble, sur un réseau commun."),
    code("services:\n  api:\n    build: .\n    ports: [\"127.0.0.1:8000:8000\"]\n  db:\n    image: postgres:17.2-alpine", "Deux services"),
    code("docker compose up -d\ndocker compose ps\ndocker compose logs -f api\ndocker compose down", "Démarrer, lister, suivre les journaux, arrêter"),
    tip("docker compose down conserve les volumes nommés ; down -v les supprime (données perdues)."),
  ],
  "quiz": [
    single("dc-1-1", "Quel est le rôle de Docker Compose ?", ["Décrire et lancer ensemble plusieurs services", "Construire des APK", "Remplacer Git", "Héberger des images"], 0,
           "Le fichier compose.yaml décrit services, réseaux et volumes ; une commande démarre le tout."),
    cmd("dc-1-2", "Démarrez les services en arrière-plan.", ["docker compose up -d"], "-d détache ; sans lui, les journaux s'affichent dans le terminal."),
    single("dc-1-3", "docker compose down supprime-t-il les volumes nommés ?", ["Non, sauf avec -v", "Oui, toujours", "Seulement le dimanche", "Il supprime les images"], 0,
           "Par sécurité, les données persistent ; -v les supprime explicitement."),
    cmd("dc-1-4", "Suivez en direct les journaux du service « api ».", ["docker compose logs -f api"], "-f suit le flux (follow), comme tail -f."),
  ]})

C.append({"id": "services-images", "title": "Services, images et build", "minutes": 16,
  "objectives": ["Choisir entre image et build", "Épingler les versions des services"],
  "sections": [
    t("Un service utilise soit une image existante (image: postgres:17.2-alpine), soit un Dockerfile local (build: .). On peut combiner "
      "les deux pour nommer l'image construite."),
    warn("Comme dans un Dockerfile, image: redis sans tag signifie latest : la base peut changer de version majeure sans prévenir."),
    code("services:\n  cache:\n    image: redis:7.4.1-alpine\n  api:\n    build:\n      context: .\n      dockerfile: Dockerfile", "Image épinglée et build local"),
  ],
  "lab": lab("compose", "Épinglez les versions des images.",
    "services:\n  cache:\n    image: redis\n    restart: unless-stopped\n  db:\n    image: postgres:latest\n    restart: unless-stopped\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\"]\n",
    [goal("noRule", "Images épinglées", rule="DC001"), goal("valid", "Fichier Compose valide")],
    "Ajoutez une version précise : redis:7.4.1-alpine, postgres:17.2-alpine.",
    "services:\n  cache:\n    image: redis:7.4.1-alpine\n    restart: unless-stopped\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\"]\n"),
  "quiz": [
    single("dc-2-1", "image: redis signifie :", ["redis:latest", "La version installée", "Une erreur", "redis:stable"], 0, "Sans tag, latest est utilisé, avec les mêmes risques que dans un Dockerfile."),
    single("dc-2-2", "Comment utiliser un Dockerfile local pour un service ?", ["build: .", "image: .", "dockerfile: true", "local: yes"], 0, "build indique le contexte (et éventuellement le Dockerfile)."),
    single("dc-2-3", "Pourquoi épingler la version d'une base de données ?", ["Éviter une montée de version majeure non maîtrisée", "Pour le style", "Pour réduire la taille", "Ce n'est pas utile"], 0,
           "Une base de données change parfois son format de stockage entre versions majeures."),
    cmd("dc-2-4", "Reconstruisez les images des services qui ont un build.", ["docker compose build"], "Utile après une modification du Dockerfile ; up --build fait build puis up."),
  ]})

C.append({"id": "ports-reseaux", "title": "Ports et réseaux", "minutes": 16,
  "objectives": ["Publier un port seulement en local", "Utiliser le nom des services comme adresse"],
  "sections": [
    t("Compose crée un réseau par projet : les services se joignent par leur nom (l'API contacte db:5432). Il n'est pas nécessaire de "
      "publier le port de la base pour que l'API y accède."),
    warn("\"8080:80\" publie le port sur toutes les interfaces : votre service devient joignable depuis le réseau local (café, salon…). "
         "Pour le développement, préférez \"127.0.0.1:8080:80\"."),
    code("services:\n  web:\n    image: nginx:1.27.3\n    ports:\n      - \"127.0.0.1:8080:80\"", "Port publié en local uniquement"),
  ],
  "lab": lab("compose", "Le site est exposé à tout le réseau local. Limitez-le à votre machine.",
    "services:\n  web:\n    image: nginx:1.27.3\n    restart: unless-stopped\n    ports:\n      - \"8080:80\"\n",
    [goal("noRule", "Port publié sur 127.0.0.1 uniquement", rule="DC007")],
    "Préfixez le port : \"127.0.0.1:8080:80\".",
    "services:\n  web:\n    image: nginx:1.27.3\n    restart: unless-stopped\n    ports:\n      - \"127.0.0.1:8080:80\"\n"),
  "quiz": [
    single("dc-3-1", "Dans Compose, comment l'API joint-elle le service db ?", ["Par le nom db", "Par localhost", "Par l'IP du PC", "Impossible sans ports"], 0, "Le réseau du projet fournit la résolution des noms de services."),
    single("dc-3-2", "\"8080:80\" rend le service joignable :", ["Depuis le réseau local aussi", "Uniquement en local", "Uniquement dans le conteneur", "Nulle part"], 0,
           "Sans adresse, Docker écoute sur toutes les interfaces de l'hôte."),
    single("dc-3-3", "Faut-il publier le port de la base pour que l'API s'y connecte ?", ["Non, ils partagent le réseau Compose", "Oui, toujours", "Oui, en 0.0.0.0", "Seulement en production"], 0,
           "Publier un port sert à l'accès depuis l'hôte ; entre services, le réseau interne suffit."),
    single("dc-3-4", "Quelle écriture limite l'accès à votre machine ?", ["\"127.0.0.1:8080:80\"", "\"8080:80\"", "\"0.0.0.0:8080:80\"", "\"80\""], 0, "L'adresse 127.0.0.1 (loopback) n'est pas joignable depuis le réseau."),
  ]})

C.append({"id": "variables-secrets", "title": "Variables et secrets", "minutes": 18,
  "objectives": ["Sortir les secrets du fichier Compose", "Utiliser env_file et l'interpolation ${VAR}"],
  "sections": [
    t("compose.yaml est versionné : il ne doit contenir aucun secret. On utilise des variables ${DB_PASSWORD} lues depuis l'environnement "
      "ou un fichier .env (ignoré par Git), ou les secrets Compose montés comme fichiers."),
    code("services:\n  db:\n    image: postgres:17.2-alpine\n    environment:\n      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}", "Valeur fournie par l'environnement ou .env"),
    code("services:\n  db:\n    image: postgres:17.2-alpine\n    environment:\n      POSTGRES_PASSWORD_FILE: /run/secrets/pg\n    secrets: [pg]\nsecrets:\n  pg:\n    file: ./secrets/pg.txt", "Secret monté comme fichier"),
    warn("Vérifiez que .env et le dossier des secrets sont dans .gitignore avant tout commit."),
  ],
  "lab": lab("compose", "Le mot de passe de la base est en clair. Sortez-le du fichier.",
    "services:\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n    environment:\n      POSTGRES_PASSWORD: super-secret-2024\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\"]\n",
    [goal("noRule", "Aucun secret en clair", rule="DC006"), goal("notContains", "La valeur a disparu", text="super-secret")],
    "Remplacez la valeur par ${POSTGRES_PASSWORD} (défini dans un .env ignoré par Git).",
    "services:\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n    environment:\n      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\"]\n"),
  "quiz": [
    single("dc-4-1", "Où mettre un mot de passe utilisé par Compose ?", ["Dans un .env ignoré par Git ou un secret Compose", "Directement dans compose.yaml", "Dans le nom du service", "Dans le README"], 0,
           "compose.yaml est versionné et partagé : il ne doit référencer que des variables."),
    single("dc-4-2", "Que signifie ${POSTGRES_PASSWORD} dans compose.yaml ?", ["La valeur est lue depuis l'environnement ou le fichier .env", "Un texte littéral", "Une commande", "Un secret chiffré"], 0,
           "Compose remplace la variable au moment du lancement."),
    single("dc-4-3", "Comment Compose expose-t-il un secret déclaré dans « secrets » ?", ["Comme un fichier dans /run/secrets/", "Comme un port", "Dans les journaux", "Dans le nom de l'image"], 0,
           "Beaucoup d'images officielles acceptent une variable *_FILE pointant vers ce fichier."),
    single("dc-4-4", "Que vérifier avant de committer un projet Compose ?", [".env et les secrets sont ignorés par Git", "Que les ports sont en 0.0.0.0", "Que les images sont en latest", "Rien"], 0,
           "Un .env versionné publie tous les mots de passe du projet."),
  ]})

C.append({"id": "volumes-persistance", "title": "Volumes et persistance", "minutes": 16,
  "objectives": ["Déclarer des volumes nommés", "Éviter les montages dangereux"],
  "sections": [
    code("services:\n  db:\n    image: postgres:17.2-alpine\n    volumes:\n      - donnees:/var/lib/postgresql/data\nvolumes:\n  donnees:", "Volume nommé déclaré au niveau du projet"),
    t("Un volume nommé survit à docker compose down et aux recréations de conteneurs. Un bind mount (./src:/app) est pratique en "
      "développement pour voir ses modifications en direct."),
    warn("Monter /var/run/docker.sock donne au conteneur le contrôle de Docker, donc de l'hôte : à réserver à des outils "
         "d'administration de confiance."),
  ],
  "lab": lab("compose", "Ce service monte le socket Docker sans raison. Remplacez par un volume de données.",
    "services:\n  app:\n    image: nginx:1.27.3\n    restart: unless-stopped\n    volumes:\n      - /var/run/docker.sock:/var/run/docker.sock\n",
    [goal("noRule", "Socket Docker non monté", rule="DC005"), goal("contains", "Un volume nommé est déclaré", text="volumes:\n  ")],
    "Supprimez le montage du socket ; déclarez un volume nommé « contenu » monté sur /usr/share/nginx/html.",
    "services:\n  app:\n    image: nginx:1.27.3\n    restart: unless-stopped\n    volumes:\n      - contenu:/usr/share/nginx/html\nvolumes:\n  contenu:\n"),
  "quiz": [
    single("dc-5-1", "Un volume nommé survit-il à docker compose down ?", ["Oui (sauf down -v)", "Non", "Seulement en production", "Il est copié dans l'image"], 0, "Les données persistent tant qu'on ne supprime pas explicitement le volume."),
    single("dc-5-2", "Quel montage donne le contrôle de l'hôte au conteneur ?", ["/var/run/docker.sock", "./src:/app", "donnees:/data", "/tmp"], 0, "Le socket du démon permet de lancer n'importe quel conteneur privilégié."),
    single("dc-5-3", "À quoi sert un bind mount comme ./src:/app en développement ?", ["Voir ses modifications sans reconstruire l'image", "Chiffrer le code", "Publier un port", "Accélérer le réseau"], 0,
           "Les fichiers de l'hôte sont visibles directement dans le conteneur."),
    cmd("dc-5-4", "Arrêtez le projet ET supprimez ses volumes (données perdues).", ["docker compose down -v"], "À réserver aux remises à zéro volontaires."),
  ]})

C.append({"id": "sante-dependances", "title": "Santé et dépendances", "minutes": 18,
  "objectives": ["Déclarer un healthcheck", "Attendre qu'un service soit prêt avec depends_on: condition"],
  "sections": [
    t("depends_on simple n'attend que le démarrage du conteneur, pas que la base accepte des connexions. Avec un healthcheck et "
      "condition: service_healthy, l'API attend que la base soit vraiment prête."),
    code("services:\n  api:\n    build: .\n    depends_on:\n      db:\n        condition: service_healthy\n  db:\n    image: postgres:17.2-alpine\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U postgres\"]\n      interval: 5s\n      retries: 10",
         "L'API démarre quand la base est healthy"),
    tip("docker compose ps affiche l'état de santé de chaque service (healthy, starting, unhealthy)."),
  ],
  "lab": lab("compose", "L'API démarre avant que la base soit prête. Faites-la attendre.",
    "services:\n  api:\n    build: .\n    restart: unless-stopped\n    depends_on:\n      - db\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n",
    [goal("noRule", "La base a un healthcheck", rule="DC010"), goal("contains", "L'API attend service_healthy", text="service_healthy")],
    "Ajoutez un healthcheck pg_isready à db, puis depends_on: { db: { condition: service_healthy } } dans api.",
    "services:\n  api:\n    build: .\n    restart: unless-stopped\n    depends_on:\n      db:\n        condition: service_healthy\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U postgres\"]\n"),
  "quiz": [
    single("dc-6-1", "depends_on: [db] garantit-il que la base accepte des connexions ?", ["Non, seulement que son conteneur a démarré", "Oui", "Oui si le port est publié", "Oui après 1 seconde"], 0,
           "D'où condition: service_healthy, couplé à un healthcheck."),
    single("dc-6-2", "Quelle commande teste la disponibilité de PostgreSQL ?", ["pg_isready", "psql --start", "postgres --ping", "docker ps"], 0, "pg_isready renvoie 0 quand le serveur accepte des connexions."),
    single("dc-6-3", "Quelle condition attend qu'un service soit prêt ?", ["service_healthy", "service_started", "service_running", "service_ok"], 0, "service_started est le comportement par défaut, insuffisant pour une base."),
    single("dc-6-4", "Que se passe-t-il si le healthcheck échoue en permanence ?", ["Le service reste unhealthy et les dépendants n'attendent pas indéfiniment sans erreur visible", "Docker supprime l'image", "Le PC redémarre", "Rien n'est visible"], 0,
           "docker compose ps affiche l'état ; les journaux du service expliquent généralement pourquoi."),
  ]})

C.append({"id": "securite-redemarrage", "title": "Redémarrage et privilèges", "minutes": 16,
  "objectives": ["Choisir une politique de redémarrage", "Refuser privileged, network_mode host et cap_add larges"],
  "sections": [
    t("restart: unless-stopped relance un service après un plantage ou un redémarrage de la machine, sauf si vous l'avez arrêté vous-même."),
    warn("privileged: true, network_mode: host et cap_add: [ALL] suppriment presque toute l'isolation. Si un outil le demande, cherchez "
         "la capacité précise nécessaire (ex. NET_ADMIN) et justifiez-la."),
    code("services:\n  outil:\n    image: exemple/outil:2.1.0\n    restart: on-failure\n    cap_drop: [ALL]\n    cap_add: [NET_BIND_SERVICE]\n    read_only: true", "Durcissement d'un service"),
  ],
  "lab": lab("compose", "Ce service a tous les privilèges. Durcissez-le et ajoutez une politique de redémarrage.",
    "services:\n  outil:\n    image: exemple/outil:2.1.0\n    privileged: true\n    network_mode: host\n    cap_add: [ALL]\n",
    [goal("noRule", "Pas de privileged", rule="DC002"), goal("noRule", "Pas de capacités larges", rule="DC003"),
     goal("noRule", "Pas de network_mode host", rule="DC004"), goal("noRule", "Politique de redémarrage", rule="DC009")],
    "Retirez privileged et network_mode, remplacez cap_add par la capacité utile et ajoutez restart: on-failure.",
    "services:\n  outil:\n    image: exemple/outil:2.1.0\n    restart: on-failure\n    cap_drop: [ALL]\n    cap_add: [NET_BIND_SERVICE]\n"),
  "quiz": [
    single("dc-7-1", "Que fait restart: unless-stopped ?", ["Relance le service sauf s'il a été arrêté manuellement", "Ne relance jamais", "Relance en boucle même arrêté", "Arrête le service"], 0,
           "C'est la politique la plus courante pour des services de développement durables."),
    single("dc-7-2", "Pourquoi éviter privileged: true ?", ["Le conteneur obtient un accès quasi total à l'hôte", "C'est plus lent", "Il ne démarre pas", "Il supprime les volumes"], 0,
           "Il donne accès aux périphériques et désactive la plupart des protections."),
    single("dc-7-3", "Quelle approche pour les capacités Linux ?", ["cap_drop: [ALL] puis ajouter seulement le nécessaire", "cap_add: [ALL]", "privileged: true", "Ne rien faire"], 0, "Le moindre privilège s'applique aussi aux capacités."),
    single("dc-7-4", "network_mode: host :", ["Supprime l'isolation réseau du conteneur", "Accélère le DNS", "Crée un réseau privé", "Bloque Internet"], 0,
           "Le conteneur partage directement la pile réseau de l'hôte."),
  ]})

C.append({"id": "environnements", "title": "Environnements et fichiers multiples", "minutes": 15,
  "objectives": ["Superposer des fichiers Compose", "Activer des services optionnels avec les profils"],
  "sections": [
    t("compose.override.yaml est lu automatiquement en plus de compose.yaml : idéal pour les réglages de développement (bind mounts, "
      "ports supplémentaires). Pour la production, on passe un autre fichier avec -f."),
    code("docker compose -f compose.yaml -f compose.prod.yaml up -d", "Superposition explicite"),
    code("services:\n  adminer:\n    image: adminer:4.8.1\n    profiles: [outils]", "Service démarré seulement avec --profile outils"),
    tip("docker compose config affiche la configuration finale fusionnée : pratique pour vérifier ce qui sera réellement lancé."),
  ],
  "quiz": [
    single("dc-8-1", "Quel fichier Compose est lu automatiquement en plus de compose.yaml ?", ["compose.override.yaml", "compose.dev.yaml", "docker.yaml", ".compose"], 0, "Il sert habituellement aux réglages de développement."),
    cmd("dc-8-2", "Affichez la configuration finale fusionnée.", ["docker compose config"], "Elle montre les variables remplacées et les fichiers combinés."),
    single("dc-8-3", "À quoi servent les profiles ?", ["Démarrer certains services seulement sur demande", "Gérer les utilisateurs", "Chiffrer les volumes", "Limiter la mémoire"], 0,
           "docker compose --profile outils up active les services du profil."),
    cmd("dc-8-4", "Lancez avec compose.yaml et compose.prod.yaml superposés, en arrière-plan.", ["docker compose -f compose.yaml -f compose.prod.yaml up -d"],
        "L'ordre compte : le dernier fichier l'emporte sur les précédents."),
  ]})

compose_project = {"title": "Mise en sécurité d'une pile Compose",
  "brief": "Une pile API + base + cache a été écrite à la hâte. Rendez-la reproductible, sans secret, sans privilège et robuste au démarrage.",
  "lab": lab("compose", "Objectif : plus aucun problème bloquant ni avertissement, healthcheck et dépendance prête.",
    "services:\n  api:\n    build: .\n    ports:\n      - \"8000:8000\"\n    environment:\n      DB_PASSWORD: motdepasse-2024\n    depends_on:\n      - db\n    privileged: true\n"
    "  db:\n    image: postgres\n    volumes:\n      - /var/run/docker.sock:/var/run/docker.sock\n  cache:\n    image: redis:latest\n",
    [goal("noSeverity", "Aucun problème bloquant", severity="blocking"), goal("noSeverity", "Aucun avertissement", severity="warning"),
     goal("contains", "L'API attend une base prête", text="service_healthy"), goal("noRule", "La base a un healthcheck", rule="DC010"),
     goal("noRule", "Ports limités à la machine", rule="DC007")],
    "Reprenez les labos du module un par un : versions, secrets, privilèges, ports, healthcheck, dépendances.",
    "services:\n  api:\n    build: .\n    restart: unless-stopped\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    environment:\n      DB_PASSWORD: ${DB_PASSWORD}\n"
    "    depends_on:\n      db:\n        condition: service_healthy\n  db:\n    image: postgres:17.2-alpine\n    restart: unless-stopped\n    environment:\n      POSTGRES_PASSWORD: ${DB_PASSWORD}\n"
    "    volumes:\n      - donnees:/var/lib/postgresql/data\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U postgres\"]\n  cache:\n    image: redis:7.4.1-alpine\n    restart: unless-stopped\n"
    "    healthcheck:\n      test: [\"CMD\", \"redis-cli\", \"ping\"]\nvolumes:\n  donnees:\n"),
  "rubric": [
    {"criterion": "Reproductibilité", "levels": ["Images latest", "Versions épinglées", "Versions épinglées et configuration vérifiée (compose config)"]},
    {"criterion": "Secrets", "levels": ["Mots de passe en clair", "Variables ${…}", "Variables ou secrets Compose, .env ignoré par Git"]},
    {"criterion": "Isolation", "levels": ["privileged ou socket Docker", "Privilèges retirés", "Privilèges retirés, capacités minimales"]},
    {"criterion": "Exposition réseau", "levels": ["Ports sur toutes les interfaces", "Ports limités", "Seuls les ports nécessaires, en local"]},
    {"criterion": "Robustesse", "levels": ["Démarrage sans attente", "Healthchecks", "Healthchecks, depends_on healthy, restart"]},
  ]}

compose_glossary = [
  ("compose.yaml", "Fichier décrivant les services, réseaux, volumes et secrets d'un projet."),
  ("Service", "Conteneur (ou groupe de conteneurs identiques) décrit dans compose.yaml."),
  ("depends_on", "Ordre de démarrage entre services ; avec condition: service_healthy, attend qu'un service soit prêt."),
  ("healthcheck", "Commande indiquant si un service est prêt."),
  ("env_file", "Fichier de variables d'environnement chargé pour un service."),
  ("Interpolation", "Remplacement de ${VAR} par une valeur de l'environnement ou du .env."),
  ("Secrets Compose", "Fichiers sensibles montés dans /run/secrets/ plutôt que passés en variables."),
  ("Volume nommé", "Stockage persistant déclaré dans la section volumes du projet."),
  ("Profil", "Groupe de services démarrés seulement sur demande (--profile)."),
  ("compose.override.yaml", "Fichier superposé automatiquement à compose.yaml."),
  ("restart", "Politique de redémarrage (no, on-failure, unless-stopped, always)."),
  ("cap_add / cap_drop", "Ajout ou retrait de capacités Linux d'un conteneur."),
]

compose_module = {
  "id": "compose", "version": 1, "title": "Docker Compose, la flotte de conteneurs",
  "summary": "Décrire une application multi-services sûre et robuste : versions, secrets, réseaux, volumes, santé et environnements.",
  "objectives": ["Écrire un compose.yaml lisible et reproductible", "Sortir les secrets et limiter l'exposition réseau",
                 "Garantir un démarrage fiable avec healthchecks et dépendances", "Durcir les services (privilèges, capacités)"],
  "prerequisites": ["Module Docker"],
  "lessons": C, "project": compose_project,
  "glossary": [{"term": a, "definition": b} for a, b in compose_glossary],
}

root = pathlib.Path(__file__).resolve().parents[2] / "assets" / "courses"
for m in (docker_module, compose_module):
    (root / f"{m['id']}.json").write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    labs = sum(1 for l in m["lessons"] if l.get("lab"))
    print(f"{m['id']} : {len(m['lessons'])} leçons, {sum(len(l['quiz']) for l in m['lessons'])} questions, {labs} labos")
