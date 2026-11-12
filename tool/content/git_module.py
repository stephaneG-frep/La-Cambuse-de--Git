#!/usr/bin/env python3
"""Source du module Git de l'Académie.

Génère assets/courses/git.json. Usage :
    python3 tool/content/git_module.py

La validité pédagogique (exercices réalisables, réponses cohérentes) est
vérifiée par test/academy/content_test.dart, qui rejoue chaque solution dans le
bac à sable.
"""
import json
import pathlib

CFG = ['git init', 'git config user.name "Anne Bonny"', 'git config user.email anne@cambuse.example']


def t(body):
    return {"type": "text", "body": body}


def code(body, caption=None):
    d = {"type": "code", "body": body}
    if caption:
        d["caption"] = caption
    return d


def tip(body):
    return {"type": "tip", "body": body}


def warn(body):
    return {"type": "warning", "body": body}


def single(qid, prompt, choices, answer, explanation):
    return {"id": qid, "type": "single", "prompt": prompt, "choices": choices,
            "answer": [answer], "explanation": explanation}


def multiple(qid, prompt, choices, answers, explanation):
    return {"id": qid, "type": "multiple", "prompt": prompt, "choices": choices,
            "answer": answers, "explanation": explanation}


def command(qid, prompt, accepted, explanation):
    return {"id": qid, "type": "command", "prompt": prompt, "accepted": accepted,
            "explanation": explanation}


def step(instruction, hint, solution, *goals):
    return {"instruction": instruction, "hint": hint, "solution": solution, "goals": list(goals)}


def g(type_, **params):
    return {"type": type_, **params}


lessons = []

# ---------------------------------------------------------------- Leçon 1
lessons.append({
    "id": "pourquoi-git", "title": "Pourquoi Git ?", "minutes": 15,
    "objectives": [
        "Expliquer ce qu'est un système de gestion de versions",
        "Distinguer Git (l'outil) de GitHub et GitLab (les services)",
        "Créer son premier dépôt",
    ],
    "sections": [
        t("Sans gestion de versions, on finit avec des fichiers « rapport_final_v3_VRAIMENT_final.docx ». "
          "Un système de gestion de versions (VCS) enregistre l'historique d'un projet : chaque étape "
          "importante est un instantané que l'on peut consulter, comparer ou restaurer."),
        t("Git est un VCS distribué : chaque copie d'un dépôt contient tout l'historique. On peut donc "
          "travailler hors ligne, et aucun serveur unique n'est indispensable. GitHub et GitLab sont des "
          "services qui hébergent des dépôts Git et ajoutent la collaboration (revues de code, tickets, CI)."),
        t("Trois notions de base : le dépôt (le dossier caché .git qui contient l'historique), le commit "
          "(un instantané daté, signé par un auteur, avec un message) et la branche (une ligne de travail)."),
        code("git init\ngit status", "Créer un dépôt dans le dossier courant puis demander son état"),
        tip("git status est votre boussole : lancez-le avant et après chaque action pour comprendre ce qui se passe."),
    ],
    "exercise": {
        "intro": "Bienvenue dans la Salle des machines ! Ce terminal est un simulateur : il n'agit sur aucun vrai fichier.",
        "setup": [],
        "steps": [
            step("Créez un dépôt Git vide.", "La commande commence par git et se termine par init.",
                 ["git init"], g("initialized")),
            step("Demandez à Git l'état du dépôt.", "C'est la commande « boussole » vue dans le cours.",
                 ["git status"], g("commandUsed", prefix="git status")),
        ],
    },
    "quiz": [
        single("git-l1-q1", "Qu'est-ce qu'un commit ?",
               ["Un instantané enregistré de l'état du projet, avec auteur et message",
                "Une copie du dépôt envoyée sur un serveur",
                "Un fichier de configuration de Git",
                "Une branche distante"], 0,
               "Un commit est un instantané : Git enregistre l'état complet des fichiers suivis à ce moment, "
               "avec l'auteur, la date, le message et le lien vers le commit précédent."),
        single("git-l1-q2", "Que signifie « Git est distribué » ?",
               ["Chaque clone contient tout l'historique du projet",
                "Git ne fonctionne qu'avec un serveur central",
                "Les fichiers sont répartis sur plusieurs disques",
                "Git est distribué gratuitement"], 0,
               "Distribué signifie que chaque copie est un dépôt complet : on peut consulter l'historique, "
               "créer des commits et des branches sans réseau."),
        command("git-l1-q3", "Quelle commande crée un nouveau dépôt Git dans le dossier courant ?",
                ["git init"],
                "git init crée le dossier caché .git qui contiendra tout l'historique. Le dossier de travail, "
                "lui, n'est pas modifié."),
        multiple("git-l1-q4", "Quels bénéfices apporte un système de gestion de versions ? (plusieurs réponses)",
                 ["Revenir à une version antérieure",
                  "Travailler à plusieurs en parallèle",
                  "Savoir qui a changé quoi, et pourquoi",
                  "Rendre le programme plus rapide à l'exécution"], [0, 1, 2],
                 "Un VCS sert l'historique, la collaboration et la traçabilité. Il n'a aucun effet sur les "
                 "performances du programme."),
        single("git-l1-q5", "Quelle phrase décrit correctement Git et GitHub ?",
               ["Git est l'outil de versionnement ; GitHub est un service qui héberge des dépôts Git",
                "Ce sont deux noms du même logiciel",
                "GitHub est la nouvelle version de Git",
                "Git ne fonctionne qu'avec GitHub"], 0,
               "Git fonctionne seul, en local. GitHub, GitLab ou un serveur personnel hébergent des copies "
               "de dépôts et ajoutent des outils de collaboration."),
    ],
})

# ---------------------------------------------------------------- Leçon 2
lessons.append({
    "id": "configurer", "title": "Configurer son identité", "minutes": 12,
    "objectives": [
        "Déclarer son nom et son e-mail d'auteur",
        "Comprendre les niveaux de configuration système, global et local",
        "Lire une valeur de configuration",
    ],
    "sections": [
        t("Chaque commit enregistre un auteur. Avant le premier commit, Git doit donc connaître votre nom "
          "et votre e-mail ; sinon il refuse de valider avec « Author identity unknown »."),
        code('git config --global user.name "Anne Bonny"\n'
             'git config --global user.email anne@exemple.fr', "Identité pour tous vos dépôts"),
        t("Trois niveaux existent : --system (toute la machine), --global (votre compte utilisateur, "
          "fichier ~/.gitconfig) et --local (un seul dépôt, fichier .git/config). Le niveau le plus "
          "précis l'emporte : une valeur locale remplace la valeur globale."),
        code("git config user.name\ngit config --list", "Lire une valeur, ou tout afficher"),
        tip("Sur GitHub, utilisez l'adresse « noreply » fournie dans vos paramètres si vous ne voulez pas "
            "exposer votre e-mail personnel dans l'historique public."),
        t("D'autres réglages utiles : core.editor (l'éditeur ouvert pour les messages) et "
          "init.defaultBranch (le nom de la branche créée par git init, souvent main)."),
    ],
    "exercise": {
        "intro": "Un dépôt vient d'être créé. Présentez-vous à Git.",
        "setup": ["git init"],
        "steps": [
            step("Déclarez votre nom d'auteur (user.name).", 'git config user.name "Votre Nom"',
                 ['git config user.name "Anne Bonny"'], g("configSet", key="user.name")),
            step("Déclarez votre e-mail (user.email).", "Même principe avec la clé user.email.",
                 ["git config user.email anne@cambuse.example"], g("configSet", key="user.email")),
            step("Choisissez nano comme éditeur (core.editor).", "git config core.editor nano",
                 ["git config --global core.editor nano"], g("configSet", key="core.editor")),
        ],
    },
    "quiz": [
        single("git-l2-q1", "Que se passe-t-il si vous committez sans avoir configuré votre identité ?",
               ["Git refuse avec « Author identity unknown »",
                "Le commit est anonyme",
                "Git utilise automatiquement votre compte GitHub",
                "Le commit est créé mais pas sauvegardé"], 0,
               "Git exige un auteur pour chaque commit. Il affiche les deux commandes git config à lancer."),
        command("git-l2-q2", "Écrivez la commande qui définit, pour tous vos dépôts, l'e-mail moi@exemple.fr.",
                ["git config --global user.email moi@exemple.fr",
                 'git config --global user.email "moi@exemple.fr"'],
                "--global écrit dans ~/.gitconfig, donc pour tous les dépôts de votre compte. Sans --global, "
                "la valeur ne vaudrait que pour le dépôt courant."),
        single("git-l2-q3", "Une valeur est définie en --global ET en --local. Laquelle s'applique dans le dépôt ?",
               ["La valeur locale", "La valeur globale", "La première définie", "Git affiche une erreur"], 0,
               "Le niveau le plus précis gagne : local > global > système. C'est pratique pour utiliser un "
               "e-mail professionnel dans un seul dépôt."),
        single("git-l2-q4", "Quel réglage choisit le nom de la branche créée par git init ?",
               ["init.defaultBranch", "core.editor", "user.branch", "branch.default"], 0,
               "git config --global init.defaultBranch main fait de main la branche initiale de tous vos "
               "nouveaux dépôts."),
    ],
})

# ---------------------------------------------------------------- Leçon 3
lessons.append({
    "id": "etats-fichiers", "title": "Les états d'un fichier", "minutes": 18,
    "objectives": [
        "Nommer les états non suivi, modifié, indexé et validé",
        "Lire la sortie de git status, en version longue et courte",
        "Situer la copie de travail, l'index et le dépôt",
    ],
    "sections": [
        t("Git gère trois zones : la copie de travail (vos fichiers), l'index (la « zone de préparation » "
          "du prochain commit) et le dépôt (l'historique des commits)."),
        t("Un fichier est donc : non suivi (untracked, Git ne le connaît pas encore), modifié (différent du "
          "dernier commit, pas encore préparé), indexé (staged, prêt pour le prochain commit) ou validé "
          "(identique au dernier commit)."),
        code("git status\ngit status -s", "Version détaillée et version courte"),
        t("Dans la version courte, deux colonnes : la première pour l'index, la seconde pour la copie de "
          "travail. « ?? » = non suivi, « A  » = nouveau fichier indexé, « M  » = modification indexée, "
          "«  M » = modification non indexée."),
        tip("L'index permet de construire des commits cohérents : vous choisissez précisément ce qui part "
            "dans chaque commit, même si vous avez modifié beaucoup de fichiers."),
    ],
    "exercise": {
        "intro": "Observez un fichier passer d'un état à l'autre.",
        "setup": CFG,
        "steps": [
            step("Créez un fichier README.md contenant « La Cambuse ».", 'echo "La Cambuse" > README.md',
                 ['echo "La Cambuse" > README.md'], g("untracked", path="README.md")),
            step("Regardez l'état du dépôt : le fichier doit apparaître comme non suivi.", "git status",
                 ["git status"], g("commandUsed", prefix="git status")),
            step("Indexez README.md.", "git add suivi du nom du fichier.",
                 ["git add README.md"], g("staged", path="README.md")),
            step("Affichez l'état en version courte.", "Ajoutez -s à git status.",
                 ["git status -s"], g("commandUsed", prefix="git status -s")),
        ],
    },
    "quiz": [
        single("git-l3-q1", "Dans git status -s, que signifie « ?? » devant un fichier ?",
               ["Fichier non suivi", "Fichier en conflit", "Fichier supprimé", "Fichier ignoré"], 0,
               "« ?? » signale un fichier que Git ne suit pas encore. Il faut un git add pour qu'il entre "
               "dans l'index."),
        single("git-l3-q2", "À quoi sert l'index (staging area) ?",
               ["Préparer précisément le contenu du prochain commit",
                "Stocker une sauvegarde sur le serveur",
                "Lister les branches",
                "Accélérer Git"], 0,
               "L'index est une zone intermédiaire : seul ce qui y est placé entrera dans le prochain commit."),
        multiple("git-l3-q3", "Quels sont des états possibles d'un fichier dans Git ? (plusieurs réponses)",
                 ["Non suivi", "Modifié", "Indexé", "Compilé"], [0, 1, 2],
                 "Non suivi, modifié, indexé et validé sont les états du cycle de vie. « Compilé » n'a rien "
                 "à voir avec Git."),
        single("git-l3-q4", "Que signifie «  M » (espace puis M) dans git status -s ?",
               ["Modifié dans la copie de travail mais pas indexé",
                "Modifié et indexé",
                "Nouveau fichier",
                "Fichier fusionné"], 0,
               "La colonne de gauche concerne l'index, celle de droite la copie de travail. Un M à droite "
               "seulement = modification pas encore indexée."),
        command("git-l3-q5", "Quelle commande affiche l'état du dépôt en version courte ?",
                ["git status -s", "git status --short"],
                "-s (ou --short) affiche une ligne par fichier avec deux colonnes de statut."),
    ],
})

# ---------------------------------------------------------------- Leçon 4
lessons.append({
    "id": "add-commit", "title": "Indexer et valider", "minutes": 20,
    "objectives": [
        "Indexer des fichiers choisis avec git add",
        "Créer des commits avec un message clair",
        "Utiliser git commit -a à bon escient",
    ],
    "sections": [
        code("git add fichier.txt\ngit add .\ngit commit -m \"Ajoute la page d'accueil\"",
             "Indexer un fichier, tout indexer, valider"),
        t("Un bon message de commit décrit l'intention à l'impératif présent, en une ligne courte "
          "(≈ 50 caractères) : « Ajoute la validation du formulaire », « Corrige le calcul du total ». "
          "Évitez « modifs » ou « wip » : dans six mois, personne ne saura ce qu'ils contiennent."),
        t("Un commit = une idée. Si vous corrigez un bug et renommez une variable ailleurs, faites deux "
          "commits : l'historique sera lisible et chaque changement pourra être annulé séparément."),
        code('git commit -am "Corrige la faute de frappe"', "Indexer les fichiers déjà suivis et valider"),
        warn("git commit -a n'ajoute PAS les nouveaux fichiers (non suivis) : il ne prend que les fichiers "
             "déjà connus de Git. Et git add . ajoute tout : vérifiez git status avant pour ne pas "
             "embarquer un fichier secret."),
    ],
    "exercise": {
        "intro": "Deux fichiers attendent. Construisez des commits propres, une idée à la fois.",
        "setup": CFG + ['echo "<h1>Cambuse</h1>" > index.html', 'echo "body { color: navy; }" > style.css'],
        "steps": [
            step("Indexez uniquement index.html (pas style.css).", "git add index.html",
                 ["git add index.html"], g("staged", path="index.html"), g("untracked", path="style.css")),
            step("Validez avec le message « Ajoute la page d'accueil ».", 'git commit -m "..."',
                 ['git commit -m "Ajoute la page d\'accueil"'],
                 g("commitCount", min=1), g("fileCommitted", path="index.html")),
            step("Ajoutez et validez style.css dans un second commit.", "git add puis git commit -m.",
                 ["git add style.css", 'git commit -m "Ajoute la feuille de style"'],
                 g("commitCount", min=2), g("fileCommitted", path="style.css")),
            step("Ajoutez « <p>Bienvenue</p> » à la fin d'index.html, puis validez en une seule commande avec -a.",
                 'echo "..." >> index.html puis git commit -am "message".',
                 ['echo "<p>Bienvenue</p>" >> index.html', 'git commit -am "Ajoute un message de bienvenue"'],
                 g("commitCount", min=3), g("fileContains", path="index.html", text="Bienvenue"), g("clean")),
        ],
    },
    "quiz": [
        single("git-l4-q1", "Quel est le meilleur message de commit ?",
               ["Ajoute la validation de l'e-mail du formulaire", "modifs", "wip", "commit du 12/11"], 0,
               "Un message utile décrit l'intention, à l'impératif. « modifs » ou une date n'apprennent rien."),
        single("git-l4-q2", "git commit -a ajoute-t-il les fichiers non suivis ?",
               ["Non, seulement les fichiers déjà suivis",
                "Oui, tous les fichiers",
                "Oui, sauf les fichiers ignorés",
                "Seulement s'ils sont dans un sous-dossier"], 0,
               "-a indexe les modifications et suppressions des fichiers déjà suivis. Un nouveau fichier doit "
               "d'abord passer par git add."),
        command("git-l4-q3", "Écrivez la commande qui valide l'index avec le message « Corrige le total ».",
                ['git commit -m "Corrige le total"'],
                "-m fournit le message directement ; sans -m, Git ouvre l'éditeur configuré."),
        single("git-l4-q4", "Vous avez corrigé un bug ET reformaté un autre fichier. Que faire ?",
               ["Deux commits séparés, un par idée",
                "Un seul commit « divers »",
                "Ne rien committer",
                "Supprimer le reformatage"], 0,
               "Un commit par idée rend l'historique lisible et permet d'annuler un changement sans l'autre."),
        single("git-l4-q5", "Pourquoi relire git status avant git add . ?",
               ["Pour ne pas indexer par erreur un fichier sensible ou inutile",
                "Parce que git add . échoue sinon",
                "Pour accélérer le commit",
                "Ce n'est jamais utile"], 0,
               "git add . prend tout ce qui n'est pas ignoré : un .env ou un gros binaire peut partir dans "
               "l'historique, où il sera difficile à effacer."),
    ],
})

# ---------------------------------------------------------------- Leçon 5
lessons.append({
    "id": "historique", "title": "Explorer l'historique", "minutes": 15,
    "objectives": [
        "Lire l'historique avec git log",
        "Utiliser les formats compacts",
        "Inspecter un commit avec git show",
    ],
    "sections": [
        code("git log\ngit log --oneline\ngit log -n 3", "Historique complet, compact, limité"),
        t("Chaque commit est identifié par une empreinte (hash) de 40 caractères hexadécimaux, dont les 7 "
          "premiers suffisent généralement. Les décorations entre parenthèses indiquent où pointent HEAD, "
          "les branches et les étiquettes."),
        t("HEAD désigne « l'endroit où vous êtes » : la plupart du temps, le dernier commit de la branche "
          "courante. « HEAD -> main » se lit : HEAD pointe sur la branche main."),
        code("git show\ngit show a1b2c3d", "Détail du dernier commit, ou d'un commit précis"),
        tip("Sur un vrai dépôt, essayez git log --oneline --graph --all pour visualiser les branches."),
    ],
    "exercise": {
        "intro": "Un dépôt avec quelques commits existe déjà. Menez l'enquête.",
        "setup": CFG + ['echo "Jour 1 : départ" > journal.txt', "git add journal.txt", 'git commit -m "Commence le journal"',
                        'echo "Jour 2 : tempête" >> journal.txt', 'git commit -am "Raconte la tempête"',
                        'echo "Jour 3 : île en vue" >> journal.txt', 'git commit -am "Signale une île"'],
        "steps": [
            step("Affichez l'historique complet.", "git log", ["git log"], g("commandUsed", prefix="git log")),
            step("Affichez l'historique en une ligne par commit.", "Option --oneline.",
                 ["git log --oneline"], g("commandUsed", prefix="git log --oneline")),
            step("Affichez le détail du dernier commit.", "git show", ["git show"], g("commandUsed", prefix="git show")),
            step("Ajoutez « Jour 4 : trésor » au journal et validez-le.", "echo ... >> journal.txt puis commit -am.",
                 ['echo "Jour 4 : trésor" >> journal.txt', 'git commit -am "Note la découverte du trésor"'],
                 g("commitCount", min=4), g("clean")),
        ],
    },
    "quiz": [
        single("git-l5-q1", "Que désigne HEAD ?",
               ["La position courante, en général le dernier commit de la branche active",
                "Le premier commit du dépôt", "Le serveur distant", "Le fichier le plus récent"], 0,
               "HEAD est un pointeur vers ce que vous avez « en main » : la branche courante et donc son "
               "dernier commit."),
        command("git-l5-q2", "Quelle commande affiche l'historique avec une ligne par commit ?",
                ["git log --oneline"],
                "--oneline montre le hash abrégé, les décorations et la première ligne du message."),
        single("git-l5-q3", "Que montre git show sans argument ?",
               ["Le dernier commit et les modifications qu'il apporte",
                "La liste des branches", "L'état de l'index", "La configuration"], 0,
               "git show affiche les métadonnées de HEAD (auteur, message) suivies du diff qu'il introduit."),
        single("git-l5-q4", "Combien de caractères du hash suffisent généralement à désigner un commit ?",
               ["Environ 7", "Exactement 40, toujours", "2", "Aucun : on utilise le message"], 0,
               "Git accepte un préfixe tant qu'il est unique dans le dépôt ; 7 caractères suffisent presque "
               "toujours."),
    ],
})

# ---------------------------------------------------------------- Leçon 6
lessons.append({
    "id": "differences", "title": "Voir les différences", "minutes": 15,
    "objectives": [
        "Comparer la copie de travail et l'index avec git diff",
        "Comparer l'index et le dernier commit avec git diff --staged",
        "Lire un diff unifié",
    ],
    "sections": [
        code("git diff\ngit diff --staged", "Non indexé vs indexé"),
        t("git diff montre ce qui a changé mais n'est pas encore indexé. git diff --staged (synonyme "
          "--cached) montre ce qui partira dans le prochain commit. Une fois tout indexé, git diff est vide !"),
        t("Dans un diff, les lignes commençant par « - » sont retirées, celles commençant par « + » sont "
          "ajoutées. L'en-tête « @@ -1,3 +1,4 @@ » indique les lignes concernées dans l'ancienne et la "
          "nouvelle version."),
        tip("Relire git diff --staged avant chaque commit est la meilleure habitude pour éviter les "
            "surprises (fichiers de débogage, secrets, code commenté)."),
    ],
    "exercise": {
        "intro": "Une recette est versionnée. Modifiez-la et observez les deux sortes de diff.",
        "setup": CFG + ['echo "Rhum" > recette.txt', 'echo "Citron vert" >> recette.txt', "git add recette.txt",
                        'git commit -m "Ajoute la recette du grog"'],
        "steps": [
            step("Ajoutez « Cannelle » à la fin de recette.txt.", 'echo "Cannelle" >> recette.txt',
                 ['echo "Cannelle" >> recette.txt'], g("fileContains", path="recette.txt", text="Cannelle")),
            step("Affichez les modifications non indexées.", "git diff", ["git diff"], g("commandUsed", prefix="git diff")),
            step("Indexez recette.txt.", "git add recette.txt", ["git add recette.txt"], g("staged", path="recette.txt")),
            step("Affichez ce qui partira dans le prochain commit.", "git diff --staged",
                 ["git diff --staged"], g("commandUsed", prefix="git diff --staged")),
            step("Validez la modification.", 'git commit -m "Ajoute la cannelle"',
                 ['git commit -m "Ajoute la cannelle"'], g("clean"), g("commitCount", min=2)),
        ],
    },
    "quiz": [
        single("git-l6-q1", "Vous avez tout indexé. Que renvoie git diff (sans option) ?",
               ["Rien : il compare la copie de travail à l'index, qui sont identiques",
                "Toutes les modifications indexées", "L'historique", "Une erreur"], 0,
               "git diff compare la copie de travail à l'index. Pour voir ce qui est indexé : git diff --staged."),
        command("git-l6-q2", "Quelle commande montre les modifications indexées, prêtes à être validées ?",
                ["git diff --staged", "git diff --cached"],
                "--staged et --cached sont synonymes : comparaison entre l'index et le dernier commit."),
        single("git-l6-q3", "Dans un diff, que signifie une ligne qui commence par « + » ?",
               ["Une ligne ajoutée", "Une ligne supprimée", "Une ligne inchangée", "Un conflit"], 0,
               "« + » = ajout dans la nouvelle version ; « - » = retrait ; un espace = contexte inchangé."),
        single("git-l6-q4", "Pourquoi relire git diff --staged avant de valider ?",
               ["Pour vérifier exactement ce qui entrera dans le commit",
                "C'est obligatoire pour que git commit fonctionne",
                "Pour envoyer le diff au serveur", "Pour créer une branche"], 0,
               "C'est la dernière occasion de repérer un oubli, un fichier de débogage ou un secret avant qu'il "
               "n'entre dans l'historique."),
    ],
})

# ---------------------------------------------------------------- Leçon 7
lessons.append({
    "id": "annuler", "title": "Annuler proprement", "minutes": 20,
    "objectives": [
        "Abandonner une modification locale avec git restore",
        "Désindexer un fichier avec git restore --staged",
        "Connaître revert et reset et leurs risques",
    ],
    "sections": [
        code("git restore fichier.txt", "Revenir à la version de l'index (perd la modification locale)"),
        code("git restore --staged fichier.txt", "Retirer de l'index en gardant la modification"),
        warn("git restore sans --staged écrase vos modifications locales non indexées : elles sont perdues "
             "définitivement, car Git ne les a jamais enregistrées."),
        t("Pour annuler un commit déjà partagé, on utilise git revert <commit> : il crée un NOUVEAU commit "
          "qui inverse le premier. L'historique reste intact et vos collègues ne sont pas perturbés."),
        t("git reset déplace la branche vers un commit antérieur. Avec --hard, il écrase aussi la copie de "
          "travail. Utile en local, dangereux sur une branche déjà poussée : il réécrit l'histoire."),
        tip("Le simulateur pratique restore ; revert et reset se pratiqueront sur de vrais dépôts jetables "
            "dans l'Atelier, avec sauvegarde préalable."),
    ],
    "exercise": {
        "intro": "Une modification ratée et un fichier indexé trop vite : réparez sans rien perdre d'utile.",
        "setup": CFG + ['echo "Cap au nord" > notes.txt', 'echo "Acheter du rhum" > todo.txt', "git add .",
                        'git commit -m "Initialise les notes"', 'echo "brouillon raté" > notes.txt',
                        'echo "Réparer la voile" >> todo.txt', "git add todo.txt"],
        "steps": [
            step("Annulez la modification de notes.txt (revenez à la version validée).", "git restore notes.txt",
                 ["git restore notes.txt"], g("fileMatchesHead", path="notes.txt")),
            step("Retirez todo.txt de l'index SANS perdre la ligne « Réparer la voile ».", "git restore --staged ...",
                 ["git restore --staged todo.txt"], g("notStaged", path="todo.txt"),
                 g("fileContains", path="todo.txt", text="Réparer la voile")),
            step("Finalement, validez todo.txt.", "git add puis git commit -m.",
                 ["git add todo.txt", 'git commit -m "Ajoute la réparation de la voile"'],
                 g("commitCount", min=2), g("clean")),
        ],
    },
    "quiz": [
        command("git-l7-q1", "Quelle commande retire config.ini de l'index en conservant la modification ?",
                ["git restore --staged config.ini"],
                "--staged agit sur l'index uniquement ; la copie de travail garde votre modification."),
        single("git-l7-q2", "Que devient une modification non indexée après git restore fichier ?",
               ["Elle est perdue définitivement", "Elle est mise dans l'index",
                "Elle est sauvegardée dans un commit", "Elle part dans la corbeille"], 0,
               "Git n'a jamais enregistré cette modification : restore la remplace par la version de l'index, "
               "sans retour possible."),
        single("git-l7-q3", "Comment annuler un commit déjà partagé avec l'équipe ?",
               ["git revert, qui crée un commit inverse", "git reset --hard puis push --force",
                "Supprimer le dossier .git", "Modifier le fichier à la main sans commit"], 0,
               "revert préserve l'historique commun. reset + push --force réécrit l'histoire partagée et "
               "peut faire perdre le travail des autres."),
        single("git-l7-q4", "Pourquoi git reset --hard est-il dangereux ?",
               ["Il écrase la copie de travail et peut réécrire un historique partagé",
                "Il supprime Git de l'ordinateur", "Il publie le dépôt", "Il est très lent"], 0,
               "--hard rejette les modifications locales et déplace la branche : à réserver au travail local, "
               "après avoir vérifié qu'on ne perd rien."),
    ],
})

# ---------------------------------------------------------------- Leçon 8
lessons.append({
    "id": "branches", "title": "Les branches", "minutes": 20,
    "objectives": [
        "Créer, lister et changer de branche",
        "Comprendre qu'une branche est un simple pointeur",
        "Isoler un développement sans toucher main",
    ],
    "sections": [
        t("Une branche est un pointeur léger vers un commit. Créer une branche ne copie aucun fichier : "
          "c'est instantané. Chaque nouveau commit fait avancer la branche courante."),
        code("git branch\ngit branch fonction/menu\ngit switch fonction/menu\ngit switch -c correctif",
             "Lister, créer, basculer, créer et basculer"),
        t("git checkout (plus ancien) fait la même chose : git checkout -b nom crée et bascule. git switch, "
          "plus récent, est réservé aux branches et donc moins ambigu."),
        t("En changeant de branche, Git met à jour vos fichiers pour refléter cette branche. Si une "
          "modification locale risque d'être écrasée, Git refuse : validez (ou mettez de côté) d'abord."),
        tip("Nommez les branches selon leur but : fonction/panier, correctif/date-facture, doc/readme."),
    ],
    "exercise": {
        "intro": "Développez un menu sur une branche dédiée sans toucher main.",
        "setup": CFG + ['echo "Accueil" > site.txt', "git add site.txt", 'git commit -m "Crée le site"'],
        "steps": [
            step("Créez la branche fonction/menu (sans basculer).", "git branch <nom>",
                 ["git branch fonction/menu"], g("branchExists", name="fonction/menu")),
            step("Basculez sur fonction/menu.", "git switch <nom>",
                 ["git switch fonction/menu"], g("currentBranch", name="fonction/menu")),
            step("Créez menu.txt (« Grog, Biscuits ») et validez-le sur cette branche.", "echo, add, commit.",
                 ['echo "Grog, Biscuits" > menu.txt', "git add menu.txt", 'git commit -m "Ajoute le menu"'],
                 g("fileCommitted", path="menu.txt"), g("currentBranch", name="fonction/menu")),
            step("Revenez sur main : menu.txt doit disparaître de la copie de travail.", "git switch main",
                 ["git switch main"], g("currentBranch", name="main")),
        ],
    },
    "quiz": [
        single("git-l8-q1", "Qu'est-ce qu'une branche dans Git ?",
               ["Un pointeur mobile vers un commit", "Une copie complète du projet",
                "Un dossier séparé sur le disque", "Un serveur distant"], 0,
               "Une branche n'est qu'une référence vers un commit ; c'est pourquoi elle se crée instantanément."),
        command("git-l8-q2", "Quelle commande crée la branche correctif ET bascule dessus ?",
                ["git switch -c correctif", "git checkout -b correctif"],
                "git switch -c (ou l'ancien git checkout -b) combine création et bascule."),
        single("git-l8-q3", "Git refuse de changer de branche. Pourquoi, le plus souvent ?",
               ["Des modifications locales seraient écrasées",
                "La branche est trop ancienne", "Il faut être administrateur", "Le dépôt est plein"], 0,
               "Git protège votre travail : validez ou mettez de côté vos modifications avant de basculer."),
        single("git-l8-q4", "Que fait git branch sans argument ?",
               ["Liste les branches et marque la courante d'une étoile", "Crée une branche sans nom",
                "Supprime la branche courante", "Affiche l'historique"], 0,
               "La branche courante est précédée de « * »."),
    ],
})

# ---------------------------------------------------------------- Leçon 9
lessons.append({
    "id": "fusion", "title": "Fusionner des branches", "minutes": 22,
    "objectives": [
        "Fusionner une branche avec git merge",
        "Distinguer avance rapide (fast-forward) et commit de fusion",
        "Supprimer une branche fusionnée",
    ],
    "sections": [
        code("git switch main\ngit merge fonction/menu", "Ramener le travail d'une branche dans main"),
        t("Si main n'a pas bougé depuis la création de la branche, Git avance simplement le pointeur : "
          "c'est une fusion en avance rapide (fast-forward), sans nouveau commit."),
        t("Si les deux branches ont avancé, Git calcule l'ancêtre commun et combine les deux séries de "
          "changements dans un commit de fusion, qui a deux parents."),
        code("git branch -d fonction/menu", "Supprimer une branche déjà fusionnée"),
        tip("git branch -d refuse de supprimer une branche non fusionnée : c'est une sécurité. -D force la "
            "suppression ; à utiliser en sachant ce qu'on jette."),
    ],
    "exercise": {
        "intro": "Deux branches attendent d'être fusionnées : l'une en avance rapide, l'autre avec un commit de fusion.",
        "setup": CFG + ['echo "Cap" > carte.txt', "git add carte.txt", 'git commit -m "Trace la carte"',
                        "git switch -c fonction", 'echo "Boussole" > outils.txt', "git add outils.txt",
                        'git commit -m "Ajoute la boussole"', "git switch main"],
        "steps": [
            step("Fusionnez la branche fonction dans main.", "git merge fonction",
                 ["git merge fonction"], g("merged", branch="fonction"), g("fileExists", path="outils.txt")),
            step("Supprimez la branche fonction, désormais fusionnée.", "git branch -d fonction",
                 ["git branch -d fonction"], g("branchDeleted", name="fonction")),
            step("Créez la branche correctif, validez-y un fichier, revenez sur main, validez-y un autre "
                 "fichier, puis fusionnez correctif : un commit de fusion doit apparaître.",
                 "switch -c correctif → commit → switch main → commit → merge correctif.",
                 ["git switch -c correctif", 'echo "Rustine" > coque.txt', "git add coque.txt",
                  'git commit -m "Répare la coque"', "git switch main", 'echo "Voile" > voile.txt',
                  "git add voile.txt", 'git commit -m "Hisse la voile"', "git merge correctif"],
                 g("mergeCommitExists"), g("merged", branch="correctif")),
        ],
    },
    "quiz": [
        single("git-l9-q1", "Quand Git fait-il une fusion en avance rapide (fast-forward) ?",
               ["Quand la branche courante n'a pas avancé depuis la création de l'autre",
                "Toujours", "Quand il y a un conflit", "Quand la branche est distante"], 0,
               "Si main est un ancêtre direct de la branche fusionnée, il suffit d'avancer le pointeur."),
        single("git-l9-q2", "Combien de parents a un commit de fusion ?",
               ["Deux", "Un", "Zéro", "Autant que de fichiers modifiés"], 0,
               "Un commit de fusion relie les deux lignes d'historique : il a donc deux parents."),
        command("git-l9-q3", "Vous êtes sur main. Quelle commande fusionne la branche fonction ?",
                ["git merge fonction"],
                "git merge intègre la branche indiquée DANS la branche courante."),
        single("git-l9-q4", "Pourquoi git branch -d refuse-t-il parfois de supprimer une branche ?",
               ["Elle contient des commits non fusionnés", "Elle est trop récente",
                "Elle a un nom invalide", "Elle est vide"], 0,
               "C'est une protection contre la perte de travail ; -D force si vous êtes certain."),
    ],
})

# ---------------------------------------------------------------- Leçon 10
lessons.append({
    "id": "conflits", "title": "Résoudre un conflit", "minutes": 25,
    "objectives": [
        "Reconnaître un conflit de fusion",
        "Lire les marqueurs <<<<<<<, ======= et >>>>>>>",
        "Résoudre, marquer comme résolu et conclure la fusion",
    ],
    "sections": [
        t("Un conflit survient quand les deux branches ont modifié la même partie d'un même fichier. Git "
          "ne choisit pas à votre place : il insère des marqueurs et vous laisse décider."),
        code("<<<<<<< HEAD\nCap à l'est\n=======\nCap au sud\n>>>>>>> cap-sud",
             "Entre <<<<<<< et ======= : votre version ; entre ======= et >>>>>>> : celle de l'autre branche"),
        t("Pour résoudre : éditez le fichier pour obtenir le contenu final (en supprimant TOUS les "
          "marqueurs), puis git add fichier pour le marquer comme résolu, et enfin git commit."),
        code("git status\n# éditer le fichier\ngit add carte.txt\ngit commit", "Conclure une fusion"),
        tip("Perdu ? git merge --abort annule la fusion en cours et revient à l'état d'avant."),
        warn("Ne validez jamais un fichier qui contient encore des marqueurs de conflit : le programme ne "
             "compilerait plus, et l'erreur se propagerait à toute l'équipe."),
    ],
    "exercise": {
        "intro": "Deux navigateurs ont modifié le cap différemment. À vous d'arbitrer.",
        "setup": CFG + ['echo "Cap au nord" > carte.txt', "git add carte.txt", 'git commit -m "Fixe le cap"',
                        "git switch -c cap-sud", 'echo "Cap au sud" > carte.txt', 'git commit -am "Cap au sud"',
                        "git switch main", "echo \"Cap à l'est\" > carte.txt", "git commit -am \"Cap à l'est\""],
        "steps": [
            step("Fusionnez cap-sud dans main : un conflit doit apparaître.", "git merge cap-sud",
                 ["git merge cap-sud"], g("fileContains", path="carte.txt", text="<<<<<<<")),
            step("Inspectez le fichier en conflit.", "cat carte.txt",
                 ["cat carte.txt"], g("commandUsed", prefix="cat carte.txt")),
            step("Écrivez le contenu final « Cap au sud-est » dans carte.txt (sans marqueurs).",
                 'echo "Cap au sud-est" > carte.txt', ['echo "Cap au sud-est" > carte.txt'],
                 g("noMarkers", path="carte.txt"), g("fileContains", path="carte.txt", text="sud-est")),
            step("Marquez le conflit comme résolu et concluez la fusion.", "git add carte.txt puis git commit.",
                 ["git add carte.txt", "git commit"], g("noConflicts"), g("mergeCommitExists"), g("clean")),
        ],
    },
    "quiz": [
        single("git-l10-q1", "Dans un conflit, que contient la partie entre <<<<<<< HEAD et ======= ?",
               ["La version de la branche courante", "La version de l'autre branche",
                "La version de l'ancêtre commun", "Un message d'erreur"], 0,
               "HEAD = votre branche courante. La partie après ======= vient de la branche fusionnée."),
        single("git-l10-q2", "Après avoir édité le fichier en conflit, que faut-il faire ?",
               ["git add fichier puis git commit", "git push", "git branch -d", "Rien, Git le détecte seul"], 0,
               "git add marque le fichier comme résolu ; git commit crée le commit de fusion."),
        command("git-l10-q3", "Quelle commande annule une fusion en cours et revient à l'état précédent ?",
                ["git merge --abort"],
                "--abort restaure l'état d'avant la fusion. Utile si le conflit est plus complexe que prévu."),
        single("git-l10-q4", "Pourquoi un conflit apparaît-il ?",
               ["Les deux branches ont modifié la même zone d'un même fichier",
                "Un fichier est trop gros", "Les branches ont des noms proches",
                "L'auteur n'est pas configuré"], 0,
               "Git fusionne seul les changements indépendants. Il ne s'arrête que lorsque deux changements "
               "se chevauchent."),
        multiple("git-l10-q5", "Quels marqueurs doivent avoir disparu avant de valider ? (plusieurs réponses)",
                 ["<<<<<<<", "=======", ">>>>>>>", "#"], [0, 1, 2],
                 "Les trois marqueurs de conflit doivent être supprimés. « # » est un caractère ordinaire."),
    ],
})

# ---------------------------------------------------------------- Leçon 11
lessons.append({
    "id": "ignorer", "title": "Ignorer des fichiers", "minutes": 15,
    "objectives": [
        "Écrire un fichier .gitignore",
        "Utiliser motifs *.ext et dossiers/",
        "Protéger les secrets et les artefacts de build",
    ],
    "sections": [
        t("Certains fichiers n'ont rien à faire dans l'historique : journaux (*.log), dossiers de build, "
          "dépendances téléchargées, fichiers de l'IDE et surtout les secrets (.env, clés)."),
        code("# Journaux\n*.log\n# Artefacts\nbuild/\n# Secrets\n.env", ".gitignore à la racine du dépôt"),
        t("Un motif sans « / » s'applique au nom de fichier partout (*.log). Un motif finissant par « / » "
          "désigne un dossier (build/). Une ligne commençant par # est un commentaire."),
        warn(".gitignore n'agit que sur les fichiers NON suivis. Un secret déjà validé reste dans "
             "l'historique : il faut le retirer (git rm --cached) ET considérer le secret comme compromis "
             "(le révoquer et en générer un nouveau)."),
        tip("Pour Flutter, le .gitignore généré par flutter create exclut déjà build/ et .dart_tool/."),
    ],
    "exercise": {
        "intro": "Le dépôt contient des fichiers à ne surtout pas versionner.",
        "setup": CFG + ['echo "void main() {}" > main.dart', 'echo "erreur 42" > app.log',
                        'echo "binaire" > build/app.apk', 'echo "API_KEY=exemple-factice" > .env'],
        "steps": [
            step("Créez un .gitignore qui ignore tous les fichiers .log.", 'echo "*.log" > .gitignore',
                 ['echo "*.log" > .gitignore'], g("ignored", path="app.log")),
            step("Ajoutez une ligne pour ignorer le dossier build/.", 'echo "build/" >> .gitignore',
                 ['echo "build/" >> .gitignore'], g("ignored", path="build/app.apk")),
            step("Ajoutez une ligne pour ignorer le fichier .env.", 'echo ".env" >> .gitignore',
                 ['echo ".env" >> .gitignore'], g("ignored", path=".env")),
            step("Indexez tout avec git add . et validez : seuls .gitignore et main.dart doivent partir.",
                 "git add . puis git commit -m.", ["git add .", 'git commit -m "Ajoute le code et le .gitignore"'],
                 g("fileCommitted", path=".gitignore"), g("fileCommitted", path="main.dart"), g("clean")),
        ],
    },
    "quiz": [
        single("git-l11-q1", "Quel motif ignore tous les fichiers journaux ?",
               ["*.log", "log", "/log/", "!*.log"], 0,
               "* remplace n'importe quelle suite de caractères ; *.log vise tous les fichiers finissant par .log."),
        single("git-l11-q2", "Un fichier .env a déjà été validé. L'ajouter au .gitignore suffit-il ?",
               ["Non : il reste dans l'historique et le secret doit être révoqué",
                "Oui, Git l'efface de l'historique", "Oui, après un git status", "Non, il faut supprimer le dépôt"], 0,
               ".gitignore ne concerne que les fichiers non suivis. Il faut git rm --cached et surtout changer "
               "le secret, qui doit être considéré comme exposé."),
        single("git-l11-q3", "Que signifie la ligne « build/ » dans un .gitignore ?",
               ["Ignorer le dossier build et tout son contenu", "Ignorer un fichier nommé build",
                "Ne versionner que build", "Un commentaire"], 0,
               "Le « / » final désigne un dossier : tout ce qu'il contient est ignoré."),
        command("git-l11-q4", "Quelle commande retire config.env de l'index tout en gardant le fichier sur le disque ?",
                ["git rm --cached config.env"],
                "--cached retire le fichier du suivi sans le supprimer de la copie de travail."),
    ],
})

# ---------------------------------------------------------------- Leçon 12
lessons.append({
    "id": "etiquettes", "title": "Étiquettes et versions", "minutes": 15,
    "objectives": [
        "Créer des étiquettes légères et annotées",
        "Appliquer le versionnement sémantique",
        "Lister et supprimer des étiquettes",
    ],
    "sections": [
        t("Une étiquette (tag) marque un commit précis, généralement une version publiée. Contrairement "
          "à une branche, elle ne bouge pas."),
        code('git tag v0.9.0\ngit tag -a v1.0.0 -m "Première version stable"\ngit tag\ngit tag -d v0.9.0',
             "Légère, annotée, lister, supprimer"),
        t("Une étiquette annotée stocke un message, un auteur et une date : c'est le choix recommandé pour "
          "les versions publiées. Une étiquette légère est un simple pointeur, pratique pour un repère "
          "personnel."),
        t("Versionnement sémantique MAJEUR.MINEUR.CORRECTIF : on incrémente MAJEUR pour un changement "
          "incompatible, MINEUR pour une fonctionnalité compatible, CORRECTIF pour une correction."),
        tip("Sur un vrai serveur, les étiquettes ne sont pas envoyées par défaut : git push origin v1.0.0."),
    ],
    "exercise": {
        "intro": "La version 1.0 est prête. Marquez-la proprement.",
        "setup": CFG + ['echo "v1" > app.txt', "git add app.txt", 'git commit -m "Prépare la version 1"'],
        "steps": [
            step("Créez une étiquette légère v0.9.0.", "git tag v0.9.0", ["git tag v0.9.0"], g("tagExists", name="v0.9.0")),
            step("Créez une étiquette annotée v1.0.0 avec un message.", 'git tag -a v1.0.0 -m "..."',
                 ['git tag -a v1.0.0 -m "Première version stable"'], g("annotatedTag", name="v1.0.0")),
            step("Visualisez les étiquettes dans l'historique compact.", "git log --oneline",
                 ["git log --oneline"], g("commandUsed", prefix="git log --oneline")),
            step("Supprimez l'étiquette v0.9.0, devenue inutile.", "git tag -d v0.9.0",
                 ["git tag -d v0.9.0"], g("tagDeleted", name="v0.9.0"), g("tagExists", name="v1.0.0")),
        ],
    },
    "quiz": [
        single("git-l12-q1", "Quelle différence entre une branche et une étiquette ?",
               ["Une étiquette reste fixée sur un commit, une branche avance avec les nouveaux commits",
                "Aucune", "Une étiquette contient des fichiers", "Une branche ne peut pas être supprimée"], 0,
               "L'étiquette est un repère immobile, idéal pour marquer une version."),
        command("git-l12-q2", "Créez l'étiquette annotée v2.0.0 avec le message « Refonte ».",
                ['git tag -a v2.0.0 -m "Refonte"'],
                "-a crée une étiquette annotée, -m fournit son message."),
        single("git-l12-q3", "Selon le versionnement sémantique, une correction de bug fait passer 1.4.2 à…",
               ["1.4.3", "1.5.0", "2.0.0", "1.4.2.1"], 0,
               "Une correction compatible incrémente le CORRECTIF (troisième nombre)."),
        single("git-l12-q4", "Un changement incompatible avec l'API existante fait passer 1.4.2 à…",
               ["2.0.0", "1.5.0", "1.4.3", "1.4.2-final"], 0,
               "Un changement cassant incrémente le MAJEUR et remet les autres nombres à zéro."),
    ],
})

# ---------------------------------------------------------------- Leçon 13
lessons.append({
    "id": "rebase", "title": "Rebase : réécrire proprement", "minutes": 20,
    "objectives": [
        "Comprendre ce que fait git rebase",
        "Comparer rebase et merge",
        "Appliquer la règle d'or du rebase",
    ],
    "sections": [
        t("git rebase main, lancé depuis une branche, rejoue vos commits un par un au-dessus du dernier "
          "commit de main. Le résultat : un historique linéaire, comme si vous aviez commencé votre travail "
          "à partir de la version la plus récente."),
        code("git switch fonction\ngit rebase main", "Rejouer la branche fonction sur main"),
        t("Différence avec merge : merge conserve l'historique tel qu'il s'est produit (avec un commit de "
          "fusion) ; rebase le réécrit pour le rendre linéaire. Les commits rejoués ont de nouveaux "
          "identifiants."),
        warn("Règle d'or : ne jamais rebaser des commits déjà partagés (poussés sur une branche commune). "
             "Leur identifiant change : vos collègues se retrouveraient avec un historique divergent."),
        t("git rebase -i (interactif) permet de réordonner, fusionner (squash) ou reformuler des commits "
          "locaux avant de les partager : idéal pour présenter une série propre en revue de code."),
        tip("Le simulateur ne joue pas rebase. Vous le pratiquerez sur un dépôt jetable dans l'Atelier."),
    ],
    "exercise": None,
    "quiz": [
        single("git-l13-q1", "Que fait git rebase main depuis la branche fonction ?",
               ["Rejoue les commits de fonction au-dessus du dernier commit de main",
                "Fusionne main dans fonction avec un commit de fusion", "Supprime main", "Crée une étiquette"], 0,
               "Le rebase recopie vos commits sur une nouvelle base ; l'historique devient linéaire."),
        single("git-l13-q2", "Quelle est la règle d'or du rebase ?",
               ["Ne pas rebaser des commits déjà partagés", "Toujours rebaser avant chaque commit",
                "Ne rebaser que main", "Rebaser uniquement le vendredi"], 0,
               "Rebaser change les identifiants des commits : sur un historique partagé, cela crée des "
               "divergences pour toute l'équipe."),
        single("git-l13-q3", "Que deviennent les identifiants des commits rejoués par un rebase ?",
               ["Ils changent", "Ils restent identiques", "Ils sont supprimés", "Ils deviennent des étiquettes"], 0,
               "Un commit rejoué a un nouveau parent, donc un nouveau contenu et un nouveau hash."),
        multiple("git-l13-q4", "Que permet git rebase -i ? (plusieurs réponses)",
                 ["Réordonner des commits", "Fusionner plusieurs commits (squash)",
                  "Reformuler un message", "Publier sur GitHub"], [0, 1, 2],
                 "Le rebase interactif retravaille une série locale. Il ne publie rien."),
    ],
})

# ---------------------------------------------------------------- Leçon 14
lessons.append({
    "id": "hooks-pratiques", "title": "Hooks et bonnes pratiques", "minutes": 18,
    "objectives": [
        "Savoir ce qu'est un hook Git",
        "Écrire des messages de commit conventionnels",
        "Adopter les réflexes de sécurité",
    ],
    "sections": [
        t("Les hooks sont des scripts que Git exécute à certains moments : pre-commit (avant de créer le "
          "commit, par ex. lancer le formatage ou les tests), commit-msg (vérifier le message), pre-push "
          "(avant l'envoi). Ils vivent dans .git/hooks et ne sont pas versionnés par défaut."),
        code("#!/bin/sh\n# .git/hooks/pre-commit\ndart format --set-exit-if-changed lib test",
             "Exemple : refuser un commit mal formaté"),
        t("Conventional Commits propose un format lisible par les humains et les outils : "
          "« type(portée): description ». Types courants : feat (fonctionnalité), fix (correction), "
          "docs, refactor, test, chore."),
        code("feat(panier): ajoute la suppression d'un article\nfix(facture): corrige l'arrondi de la TVA",
             "Messages conventionnels"),
        warn("Réflexes de sécurité : jamais de secret dans un dépôt ; jamais de git push --force sur une "
             "branche partagée ; relire git diff --staged ; protéger la branche main côté serveur."),
        tip("Un scanner de secrets en pre-commit (comme celui que l'Atelier appliquera avant tout push) "
            "arrête la fuite avant qu'elle n'entre dans l'historique."),
    ],
    "exercise": None,
    "quiz": [
        single("git-l14-q1", "Quand s'exécute le hook pre-commit ?",
               ["Juste avant la création du commit", "Après l'envoi sur le serveur",
                "Au clonage", "À chaque git status"], 0,
               "pre-commit peut bloquer le commit (code de sortie non nul), par exemple si les tests échouent."),
        single("git-l14-q2", "Quel message suit la convention Conventional Commits ?",
               ["fix(api): corrige le délai d'expiration", "Correction", "FIX!!!", "maj 3"], 0,
               "Format type(portée): description, avec un type connu comme feat ou fix."),
        single("git-l14-q3", "Les hooks de .git/hooks sont-ils partagés automatiquement avec l'équipe ?",
               ["Non, le dossier .git/hooks n'est pas versionné", "Oui, à chaque push",
                "Oui, via le .gitignore", "Seulement sur GitHub"], 0,
               "Il faut un outil ou un dossier versionné (core.hooksPath) pour partager des hooks."),
        multiple("git-l14-q4", "Quelles pratiques sont recommandées ? (plusieurs réponses)",
                 ["Relire git diff --staged avant de valider", "Protéger la branche main sur le serveur",
                  "Utiliser push --force sur main pour aller plus vite", "Ne jamais versionner de secret"],
                 [0, 1, 3],
                 "push --force sur une branche partagée peut effacer le travail des autres : à proscrire."),
    ],
})

project = {
    "title": "Expédition Cambuse : versionner le journal de bord",
    "brief": "Mettez en œuvre tout le module sur un projet complet : initialisation, identité, .gitignore, "
             "commits atomiques, branche de fonctionnalité, conflit résolu et version étiquetée. "
             "Évaluez ensuite votre travail avec la grille.",
    "exercise": {
        "intro": "Dépôt vierge. Vous êtes seul maître à bord.",
        "setup": [],
        "steps": [
            step("Initialisez le dépôt et configurez votre nom et votre e-mail.",
                 "git init puis deux git config.",
                 ["git init", 'git config user.name "Anne Bonny"', "git config user.email anne@cambuse.example"],
                 g("initialized"), g("configSet", key="user.name"), g("configSet", key="user.email")),
            step("Créez journal.txt (« Départ de Nantes ») et un .gitignore qui exclut *.tmp, puis validez les deux.",
                 "echo, echo, git add ., git commit -m.",
                 ['echo "Départ de Nantes" > journal.txt', 'echo "*.tmp" > .gitignore', "git add .",
                  'git commit -m "Commence le journal de bord"'],
                 g("fileCommitted", path="journal.txt"), g("fileCommitted", path=".gitignore")),
            step("Sur une branche escale, ajoutez « Escale aux Açores » au journal et validez.",
                 "git switch -c escale, echo >>, commit -am.",
                 ["git switch -c escale", 'echo "Escale aux Açores" >> journal.txt', 'git commit -am "Ajoute l\'escale"'],
                 g("branchExists", name="escale"), g("currentBranch", name="escale"), g("commitCount", min=2)),
            step("Revenez sur main, ajoutez « Tempête au large » au journal, validez, puis fusionnez escale (conflit attendu).",
                 "switch main, echo >>, commit -am, merge escale.",
                 ["git switch main", 'echo "Tempête au large" >> journal.txt', 'git commit -am "Note la tempête"',
                  "git merge escale"],
                 g("fileContains", path="journal.txt", text="<<<<<<<")),
            step("Résolvez le conflit en gardant les trois lignes dans l'ordre, puis concluez la fusion.",
                 "Réécrivez le fichier avec echo > puis echo >>, git add, git commit.",
                 ['echo "Départ de Nantes" > journal.txt', 'echo "Tempête au large" >> journal.txt',
                  'echo "Escale aux Açores" >> journal.txt', "git add journal.txt", "git commit"],
                 g("noConflicts"), g("mergeCommitExists"), g("clean")),
            step("Étiquetez la version v1.0.0 (étiquette annotée) et supprimez la branche escale.",
                 'git tag -a v1.0.0 -m "..." puis git branch -d escale.',
                 ['git tag -a v1.0.0 -m "Journal complet"', "git branch -d escale"],
                 g("annotatedTag", name="v1.0.0"), g("branchDeleted", name="escale")),
        ],
    },
    "rubric": [
        {"criterion": "Messages de commit",
         "levels": ["Vagues ou absents de sens (« modifs »)", "Clairs mais irréguliers",
                    "Impératifs, précis, homogènes"]},
        {"criterion": "Granularité des commits",
         "levels": ["Un gros commit fourre-tout", "Commits séparés mais mélangés",
                    "Un commit par idée, chacun cohérent"]},
        {"criterion": "Usage des branches",
         "levels": ["Tout sur main", "Branche utilisée mais conservée après fusion",
                    "Branche dédiée, fusionnée puis supprimée"]},
        {"criterion": "Résolution du conflit",
         "levels": ["Marqueurs laissés ou contenu perdu", "Résolu mais sans vérification",
                    "Résolu, vérifié avec status/diff, aucun marqueur"]},
        {"criterion": "Hygiène du dépôt",
         "levels": ["Fichiers temporaires ou secrets versionnés", ".gitignore partiel",
                    ".gitignore adapté, aucun fichier indésirable"]},
        {"criterion": "Versionnement",
         "levels": ["Aucune étiquette", "Étiquette légère", "Étiquette annotée et nommée selon SemVer"]},
    ],
}

glossary = [
    ("Dépôt (repository)", "Dossier .git contenant tout l'historique d'un projet."),
    ("Commit", "Instantané enregistré de l'état des fichiers suivis, avec auteur, date et message."),
    ("Index (staging area)", "Zone de préparation du prochain commit, remplie avec git add."),
    ("Copie de travail", "Les fichiers tels qu'ils sont sur votre disque, que vous modifiez."),
    ("Branche", "Pointeur mobile vers un commit, qui avance à chaque nouveau commit."),
    ("HEAD", "Pointeur vers la position courante, en général la branche active."),
    ("Fusion (merge)", "Intégration des changements d'une branche dans une autre."),
    ("Avance rapide (fast-forward)", "Fusion sans nouveau commit : le pointeur avance simplement."),
    ("Conflit", "Situation où deux branches modifient la même zone : Git demande d'arbitrer."),
    ("Rebase", "Rejeu de commits au-dessus d'une autre base, pour un historique linéaire."),
    ("Étiquette (tag)", "Repère fixe sur un commit, généralement une version publiée."),
    ("Hash", "Empreinte unique (40 caractères hexadécimaux) identifiant un commit."),
    (".gitignore", "Fichier listant les motifs de fichiers que Git ne doit pas suivre."),
    ("Non suivi (untracked)", "Fichier présent sur le disque mais inconnu de Git."),
    ("Indexé (staged)", "Modification placée dans l'index, prête pour le prochain commit."),
    ("Dépôt distant (remote)", "Copie du dépôt hébergée ailleurs (GitHub, GitLab, serveur)."),
    ("Clone", "Copie complète d'un dépôt distant, historique compris."),
    ("Push", "Envoi de vos commits vers un dépôt distant."),
    ("Pull", "Récupération et intégration des commits d'un dépôt distant."),
    ("Revert", "Commit qui annule les effets d'un commit précédent sans réécrire l'historique."),
    ("Reset", "Déplacement d'une branche vers un autre commit ; peut écraser des modifications."),
    ("Hook", "Script exécuté automatiquement par Git à un moment précis (pre-commit, pre-push…)."),
    ("SemVer", "Versionnement sémantique MAJEUR.MINEUR.CORRECTIF."),
    ("Conventional Commits", "Convention de messages « type(portée): description »."),
    ("Ancêtre commun (merge base)", "Dernier commit partagé par deux branches, base d'une fusion."),
]

module = {
    "id": "git",
    "version": 1,
    "title": "Git, de zéro à autonome",
    "summary": "Versionner son travail, créer des branches, fusionner, résoudre des conflits et publier des "
               "versions propres.",
    "objectives": [
        "Comprendre le modèle de Git : copie de travail, index, dépôt",
        "Créer un historique propre de commits atomiques",
        "Travailler avec des branches, fusionner et résoudre des conflits",
        "Protéger son dépôt : .gitignore, secrets, bonnes pratiques",
        "Marquer des versions avec des étiquettes et SemVer",
    ],
    "prerequisites": [
        "Aucun prérequis Git",
        "Savoir ce qu'est un fichier et un dossier",
        "Recommandé : module Terminal Linux (livré en phase 9)",
    ],
    "lessons": [{k: v for k, v in l.items() if v is not None} for l in lessons],
    "project": project,
    "glossary": [{"term": a, "definition": b} for a, b in glossary],
}

out = pathlib.Path(__file__).resolve().parents[2] / "assets" / "courses" / "git.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(module, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print(f"{out} : {len(lessons)} leçons, {sum(len(l['quiz']) for l in lessons)} questions, "
      f"{sum(1 for l in lessons if l.get('exercise'))} exercices, {len(glossary)} termes")
