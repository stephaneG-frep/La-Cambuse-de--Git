#!/usr/bin/env python3
"""Module « Terminal Linux » : python3 tool/content/linux_module.py"""
from common import *

L = []

L.append(lesson("terminal", "Le terminal et le shell", 15,
  ["Comprendre ce qu'est un shell", "Se repérer dans l'arborescence avec des chemins absolus et relatifs"],
  [t("Le terminal est la fenêtre ; le shell (Bash le plus souvent) est le programme qui lit vos commandes, les interprète "
     "et lance les programmes. Une commande s'écrit : programme, options, arguments — par exemple ls -l /etc."),
   t("Tout part de la racine « / ». Un chemin absolu commence par / (/home/ana/projets), un chemin relatif part du dossier "
     "courant (projets/site). « . » désigne le dossier courant, « .. » le parent et « ~ » votre dossier personnel."),
   code("pwd\nls -la\ncd ~/projets\ncd ..\ncd -", "Où suis-je, que contient ce dossier, se déplacer, revenir au dossier précédent"),
   tip("Tab complète les noms de fichiers et de commandes ; flèche haut rappelle l'historique ; Ctrl+R le recherche."),
   tip("man ls ouvre le manuel d'une commande ; ls --help en donne un résumé. Lire le manuel est un réflexe de pro, pas un aveu.")],
  [single("lx-1-1", "Que désigne « .. » ?", ["Le dossier parent", "Le dossier courant", "Le dossier personnel", "La racine"], 0,
          "« . » est le dossier courant, « .. » son parent : cd .. remonte d'un niveau."),
   single("lx-1-2", "Lequel est un chemin absolu ?", ["/var/log/syslog", "log/syslog", "./syslog", "../syslog"], 0,
          "Un chemin absolu commence toujours par la racine « / »."),
   cmd("lx-1-3", "Affichez le dossier courant.", ["pwd"], "pwd signifie « print working directory »."),
   cmd("lx-1-4", "Listez tous les fichiers du dossier courant, cachés compris, en format long.", ["ls -la", "ls -al", "ls -l -a", "ls -a -l"],
       "-l pour le format long (droits, taille, date), -a pour inclure les fichiers cachés qui commencent par un point.")]))

L.append(lesson("fichiers", "Fichiers et dossiers", 18,
  ["Créer, copier, déplacer et supprimer sans surprise", "Trouver un fichier et lire son contenu"],
  [code("mkdir -p projets/site/css\ntouch projets/site/index.html\ncp -r projets/site projets/site-copie\nmv projets/site-copie /tmp/\nrm projets/site/index.html",
        "Créer une arborescence, un fichier, copier, déplacer, supprimer"),
   warn("rm ne passe pas par une corbeille : ce qui est supprimé est perdu. rm -r supprime récursivement un dossier entier. "
        "Relisez toujours la commande, surtout avec des jokers (*) ou des variables."),
   code("find . -name '*.log' -mtime +7\nless /var/log/syslog\nhead -n 20 fichier.txt\ntail -f /var/log/nginx/access.log",
        "Chercher des fichiers, lire page par page, début, suivi en direct"),
   tip("ls *.txt laisse le shell remplacer le joker avant d'exécuter la commande : echo rm *.txt montre ce qui serait supprimé.")],
  [single("lx-2-1", "Que fait mkdir -p a/b/c ?", ["Crée a, b et c si besoin, sans erreur s'ils existent", "Crée un fichier", "Supprime a/b/c", "Affiche le chemin"], 0,
          "-p crée les parents manquants et ne se plaint pas si le dossier existe déjà."),
   single("lx-2-2", "Que devient un fichier supprimé avec rm ?", ["Il est perdu (pas de corbeille)", "Il va dans la corbeille", "Il est compressé", "Il est caché"], 0,
          "Les sauvegardes et Git sont vos filets de sécurité, pas rm."),
   cmd("lx-2-3", "Suivez en direct la fin du fichier app.log.", ["tail -f app.log"], "tail -f affiche les nouvelles lignes au fur et à mesure (Ctrl+C pour quitter)."),
   cmd("lx-2-4", "Cherchez, depuis le dossier courant, les fichiers nommés *.log.", ["find . -name '*.log'", 'find . -name "*.log"'],
       "Les guillemets empêchent le shell de remplacer le joker avant que find ne le reçoive.")]))

L.append(lesson("permissions", "Permissions et propriétaires", 20,
  ["Lire rwx et la notation octale", "Appliquer le moindre privilège aux fichiers"],
  [t("ls -l affiche par exemple -rwxr-x--- : type, puis trois triplets pour le propriétaire, le groupe et les autres. "
     "r = lire (4), w = écrire (2), x = exécuter ou traverser un dossier (1)."),
   code("chmod 755 deploy.sh      # rwx r-x r-x\nchmod 644 index.html     # rw- r-- r--\nchmod 600 ~/.ssh/id_ed25519\nchown ana:web site/ -R",
        "Exécutable, fichier public, secret privé, changement de propriétaire"),
   warn("chmod 777 « répare » une erreur de droits en donnant tout à tout le monde : n'importe quel compte peut alors modifier "
        "le script… puis le faire exécuter par vous. Cherchez plutôt QUI doit accéder à QUOI."),
   tip("umask fixe les droits par défaut des nouveaux fichiers (022 → 644 pour un fichier, 755 pour un dossier).")],
  [single("lx-3-1", "Que vaut rw-r----- en octal ?", ["640", "644", "750", "600"], 0, "rw- = 6, r-- = 4, --- = 0."),
   single("lx-3-2", "Quels droits pour une clé SSH privée ?", ["600", "644", "755", "777"], 0, "Seul le propriétaire lit et écrit ; ssh refuse une clé trop ouverte."),
   single("lx-3-3", "Le droit x sur un dossier permet de…", ["Le traverser (y entrer)", "L'exécuter comme un programme", "Le supprimer", "Le compresser"], 0,
          "Sans x, on ne peut pas faire cd dedans ni accéder à ses fichiers."),
   cmd("lx-3-4", "Rendez deploy.sh exécutable pour tous, modifiable par son seul propriétaire (octal).", ["chmod 755 deploy.sh"], "7 = rwx pour le propriétaire, 5 = r-x pour le groupe et les autres.")],
  lab("shell", "Ce script d'installation « répare » les droits à la hache. Donnez le minimum nécessaire.",
      "#!/usr/bin/env bash\nset -euo pipefail\nmkdir -p /srv/app\ncp app.sh /srv/app/\nchmod -R 777 /srv/app\n",
      [no("SH006", "Plus de chmod 777"), has("chmod 755", "Le script reste exécutable (755)"), valid()],
      "Le script doit être exécutable par tous mais modifiable seulement par son propriétaire.",
      "#!/usr/bin/env bash\nset -euo pipefail\nmkdir -p /srv/app\ncp app.sh /srv/app/\nchmod 755 /srv/app/app.sh\n")))

L.append(lesson("utilisateurs", "Utilisateurs, groupes et sudo", 15,
  ["Distinguer root, comptes humains et comptes de service", "Utiliser sudo de façon traçable"],
  [t("root peut tout faire, y compris casser le système. On travaille avec un compte nominatif et on élève ses droits "
     "ponctuellement avec sudo, ce qui laisse une trace dans les journaux (qui a fait quoi)."),
   code("id\ngroups\nsudo apt update\nsudo -l\nsudo adduser deploy\nsudo usermod -aG web deploy",
        "Mon identité, mes groupes, une commande en root, ce que j'ai le droit de faire, créer un compte, l'ajouter à un groupe"),
   t("Les services (nginx, postgres) tournent sous des comptes dédiés sans shell de connexion : si le service est compromis, "
     "l'attaquant n'a que ses droits limités."),
   warn("usermod -G sans -a remplace TOUS les groupes de l'utilisateur ; ajoutez toujours -a pour « ajouter ».")],
  [single("lx-4-1", "Pourquoi éviter de travailler en root ?", ["Une erreur ou un programme malveillant a tous les droits", "C'est plus lent", "root n'a pas de dossier personnel", "root ne peut pas utiliser Bash"], 0,
          "Le moindre privilège limite les dégâts d'une erreur."),
   single("lx-4-2", "Avantage de sudo par rapport à une session root ?", ["Élévation ponctuelle et journalisée", "Aucun mot de passe", "Plus de droits que root", "Fonctionne hors ligne"], 0,
          "Chaque commande sudo est consignée avec son auteur."),
   cmd("lx-4-3", "Ajoutez l'utilisateur deploy au groupe web sans retirer ses autres groupes.", ["sudo usermod -aG web deploy", "sudo usermod -a -G web deploy"],
       "-a (append) est indispensable avec -G."),
   cmd("lx-4-4", "Affichez ce que sudo vous autorise à faire.", ["sudo -l"], "Utile pour vérifier une délégation avant de l'utiliser.")]))

L.append(lesson("processus", "Processus, services et journaux", 20,
  ["Observer et arrêter un processus", "Piloter un service systemd et lire ses journaux"],
  [code("ps aux | grep nginx\ntop\nkill 1234\nkill -9 1234", "Lister, observer, demander l'arrêt (SIGTERM), forcer (SIGKILL) en dernier recours"),
   t("kill envoie un signal. SIGTERM (par défaut) demande poliment de s'arrêter : le programme peut fermer ses fichiers. "
     "SIGKILL (-9) tue sans délai : à réserver aux processus bloqués."),
   code("systemctl status nginx\nsudo systemctl restart nginx\nsudo systemctl enable --now nginx\njournalctl -u nginx --since '1 hour ago'",
        "État, redémarrage, activation au démarrage, journaux d'un service"),
   tip("journalctl -f suit les journaux en direct ; -p err ne montre que les erreurs.")],
  [single("lx-5-1", "Quel signal laisse un programme se terminer proprement ?", ["SIGTERM", "SIGKILL", "SIGSTOP", "Aucun"], 0, "SIGTERM est intercepté par le programme pour fermer ses ressources."),
   single("lx-5-2", "Que fait systemctl enable --now nginx ?", ["Active au démarrage et lance immédiatement", "Supprime le service", "Affiche les journaux", "Redémarre la machine"], 0,
          "enable seul n'agit qu'au prochain démarrage ; --now démarre aussi tout de suite."),
   cmd("lx-5-3", "Affichez les journaux du service nginx.", ["journalctl -u nginx", "sudo journalctl -u nginx"], "-u filtre par unité systemd."),
   cmd("lx-5-4", "Affichez l'état du service ssh.", ["systemctl status ssh", "sudo systemctl status ssh"], "Montre s'il tourne, depuis quand et les dernières lignes de journal.")]))

L.append(lesson("flux", "Redirections, tubes et filtres", 18,
  ["Rediriger sortie et erreurs", "Composer des commandes avec des tubes"],
  [t("Chaque programme a trois flux : entrée (0), sortie (1) et erreurs (2). > écrase un fichier, >> ajoute à la fin, "
     "2> redirige les erreurs, 2>&1 envoie les erreurs au même endroit que la sortie."),
   code("ls /inexistant 2> erreurs.txt\n./build.sh > build.log 2>&1\ngrep -c ERROR app.log\ncut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head",
        "Erreurs dans un fichier, tout dans un journal, compter, top des adresses IP"),
   tip("Le tube | branche la sortie d'une commande sur l'entrée de la suivante : de petits outils combinés font de grandes choses."),
   warn("Dans un script, une erreur au milieu d'un tube est ignorée par défaut : set -o pipefail la fait remonter.")],
  [single("lx-6-1", "Différence entre > et >> ?", ["> écrase, >> ajoute à la fin", "Aucune", "> ajoute, >> écrase", ">> redirige les erreurs"], 0, "Attention : > vide le fichier avant d'écrire."),
   single("lx-6-2", "Que signifie 2>&1 ?", ["Envoyer les erreurs là où va la sortie", "Lancer deux fois", "Ignorer les erreurs", "Lire le fichier 1"], 0, "Ordre important : > fichier 2>&1."),
   cmd("lx-6-3", "Comptez les lignes contenant ERROR dans app.log.", ["grep -c ERROR app.log", "grep ERROR app.log | wc -l"], "grep -c compte directement."),
   cmd("lx-6-4", "Lancez ./build.sh en envoyant sortie et erreurs dans build.log.", ["./build.sh > build.log 2>&1", "./build.sh &> build.log"],
       "&> est un raccourci Bash équivalent.")]))

L.append(lesson("scripts-surs", "Écrire un script Bash sûr", 22,
  ["Démarrer chaque script par un shebang et le mode strict", "Comprendre ce que change set -euo pipefail"],
  [code("#!/usr/bin/env bash\nset -euo pipefail\n\necho \"Déploiement de $1\"", "Squelette minimal d'un script robuste"),
   t("-e arrête le script à la première commande en échec ; -u fait échouer l'usage d'une variable non définie (fini les "
     "rm -rf \"$DOSIER/\" mal orthographiés qui deviennent rm -rf /) ; -o pipefail fait échouer un tube si une de ses commandes échoue."),
   t("Le shebang (#!) indique quel interpréteur lancer : sans lui, le script dépend du shell de la personne qui l'exécute."),
   tip("shellcheck (paquet du même nom) analyse vos scripts bien plus finement que ce labo : adoptez-le dans la CI.")],
  [single("lx-7-1", "Que fait set -u ?", ["Échoue si une variable non définie est utilisée", "Passe en majuscules", "Désactive les erreurs", "Active le débogage"], 0, "Une faute de frappe dans un nom de variable devient une erreur visible."),
   single("lx-7-2", "Sans pipefail, que vaut le code de retour de « false | true » ?", ["0 (succès)", "1 (échec)", "Erreur de syntaxe", "Indéfini"], 0, "Seule la dernière commande compte… d'où pipefail."),
   single("lx-7-3", "Rôle du shebang ?", ["Choisir l'interpréteur du script", "Commenter", "Rendre exécutable", "Signer le script"], 0, "#!/usr/bin/env bash trouve bash dans le PATH."),
   cmd("lx-7-4", "Écrivez la ligne qui active le mode strict.", ["set -euo pipefail", "set -eu -o pipefail", "set -Eeuo pipefail"], "À placer juste après le shebang.")],
  lab("shell", "Ce script de déploiement continue même quand une étape échoue. Rendez-le robuste.",
      "cd /srv/app\ngit pull\nnpm ci\nsystemctl restart app\n",
      [no("SH001", "Shebang présent"), no("SH002", "Mode strict activé"), no("SH009", "Plus de cd non vérifié"), valid()],
      "Ajoutez le shebang puis set -euo pipefail : cd en échec arrêtera alors le script.",
      "#!/usr/bin/env bash\nset -euo pipefail\ncd /srv/app\ngit pull\nnpm ci\nsystemctl restart app\n")))

L.append(lesson("variables", "Variables, guillemets, conditions et boucles", 22,
  ["Toujours protéger les expansions de variables", "Écrire des conditions et des boucles lisibles"],
  [code("nom=\"mon fichier.txt\"\nrm $nom      # supprime « mon » et « fichier.txt » !\nrm \"$nom\"    # supprime le bon fichier", "Pourquoi les guillemets comptent"),
   code("if [[ -f \"$cible\" ]]; then\n  echo \"existe\"\nfi\nfor f in \"$@\"; do\n  echo \"traitement de $f\"\ndone",
        "Condition sur un fichier, boucle sur les arguments"),
   t("\"${VAR:?message}\" arrête le script si VAR est vide ou absente : indispensable avant toute commande destructrice."),
   warn("rm -rf \"$DOSSIER/\"* avec DOSSIER vide devient rm -rf /* : écrivez rm -rf -- \"${DOSSIER:?}/\"*."),
   tip("$(commande) capture la sortie d'une commande ; préférez-le aux accents graves `commande`.")],
  [single("lx-8-1", "Pourquoi écrire \"$fichier\" plutôt que $fichier ?", ["Pour qu'un nom avec espaces reste un seul argument", "Pour aller plus vite", "C'est obligatoire en Bash 5", "Pour masquer la valeur"], 0,
          "Sans guillemets, le shell découpe la valeur sur les espaces et interprète les jokers."),
   single("lx-8-2", "Que fait \"${CIBLE:?}\" si CIBLE est vide ?", ["Le script s'arrête avec une erreur", "Il vaut « / »", "Il vaut « . »", "Rien"], 0, "C'est le garde-fou des commandes destructrices."),
   single("lx-8-3", "Comment parcourir tous les arguments en respectant les espaces ?", ["for a in \"$@\"", "for a in $*", "for a in $@", "for a in \"$*\""], 0, "\"$@\" conserve chaque argument intact."),
   single("lx-8-4", "Quelle syntaxe de substitution de commande préférer ?", ["$(date +%F)", "`date +%F`", "${date +%F}", "$[date]"], 0, "$( ) s'imbrique et se lit mieux.")],
  lab("shell", "Ce script de nettoyage peut effacer bien plus que prévu. Sécurisez-le.",
      "#!/usr/bin/env bash\nset -euo pipefail\nCIBLE=$1\nfor f in $CIBLE/*.tmp; do\n  echo Suppression de $f\ndone\nrm -rf $CIBLE/cache\n",
      [no("SH004", "rm -rf protégé contre une variable vide"), no("SH003", "Toutes les variables entre guillemets"), clean()],
      "Entourez chaque $… de guillemets et utilisez \"${CIBLE:?}\" dans le rm.",
      "#!/usr/bin/env bash\nset -euo pipefail\nCIBLE=\"${1:?dossier requis}\"\nfor f in \"$CIBLE\"/*.tmp; do\n  echo \"Suppression de $f\"\ndone\nrm -rf -- \"${CIBLE:?}/cache\"\n")))

L.append(lesson("paquets-secrets", "Paquets, téléchargements et secrets", 18,
  ["Installer des logiciels depuis une source de confiance", "Ne jamais écrire un secret dans un script"],
  [code("sudo apt update\nsudo apt install --no-install-recommends jq\napt list --upgradable\nsudo apt full-upgrade", "Gestionnaire de paquets Debian/Ubuntu"),
   warn("curl https://… | sh exécute un script distant sans que vous l'ayez lu ni vérifié : si le serveur est compromis, "
        "vous exécutez le code de l'attaquant avec vos droits."),
   code("curl -fsSLo outil.tar.gz https://exemple.org/outil-1.4.2.tar.gz\necho \"<sha256 publié>  outil.tar.gz\" | sha256sum -c -",
        "Télécharger, puis vérifier l'empreinte publiée avant d'utiliser"),
   t("Un mot de passe ou un jeton écrit dans un script finit dans Git, dans les sauvegardes et dans l'historique du shell. "
     "Lisez-le depuis l'environnement ou un fichier en 600, et faites échouer le script s'il manque.")],
  [single("lx-9-1", "Pourquoi éviter curl … | sh ?", ["Le code distant s'exécute sans lecture ni vérification", "C'est lent", "curl ne gère pas HTTPS", "sh n'existe pas"], 0, "Téléchargez, vérifiez, puis exécutez."),
   single("lx-9-2", "Où ranger un jeton utilisé par un script ?", ["Variable d'environnement ou fichier protégé en 600", "En clair dans le script", "Dans le nom du fichier", "Dans un commentaire"], 0, "Le script échoue proprement s'il est absent."),
   cmd("lx-9-3", "Vérifiez l'empreinte SHA-256 décrite dans le fichier SHA256SUMS.", ["sha256sum -c SHA256SUMS"], "Chaque ligne « empreinte  fichier » est comparée au fichier réel."),
   cmd("lx-9-4", "Mettez à jour la liste des paquets disponibles.", ["sudo apt update"], "À faire avant install ou upgrade.")],
  lab("shell", "Ce script d'installation exécute un script distant et contient un jeton en clair. Corrigez les deux problèmes.",
      "#!/usr/bin/env bash\nset -euo pipefail\nAPI_TOKEN=ghp_exempleNonValide1234\ncurl -fsSL https://exemple.org/install.sh | bash\n",
      [no("SH005", "Plus de curl | bash"), no("SH010", "Plus de secret en dur"), has("sha256sum -c", "Empreinte vérifiée"), clean()],
      "Lisez le jeton avec : \"${API_TOKEN:?}\" ; téléchargez install.sh dans un fichier et vérifiez-le avec sha256sum -c.",
      "#!/usr/bin/env bash\nset -euo pipefail\n: \"${API_TOKEN:?variable API_TOKEN requise}\"\ncurl -fsSLo install.sh https://exemple.org/install.sh\nsha256sum -c install.sh.sha256\nbash install.sh\n")))

L.append(lesson("ssh", "SSH : clés et durcissement du serveur", 25,
  ["Se connecter avec une clé plutôt qu'un mot de passe", "Durcir la configuration d'un serveur SSH"],
  [code("ssh-keygen -t ed25519 -C \"ana@portable\"\nssh-copy-id deploy@serveur\nssh deploy@serveur", "Créer une paire de clés, installer la clé publique, se connecter"),
   t("La clé privée reste sur votre machine (protégée par une phrase de passe) ; seule la clé publique est copiée sur le "
     "serveur dans ~/.ssh/authorized_keys. Une clé ne se devine pas, contrairement à un mot de passe."),
   code("PermitRootLogin no\nPasswordAuthentication no\nKbdInteractiveAuthentication no\nAllowUsers deploy\nMaxAuthTries 3",
        "Extrait d'un /etc/ssh/sshd_config durci"),
   warn("Avant de désactiver les mots de passe, vérifiez dans une SECONDE session que la connexion par clé fonctionne : "
        "sinon vous vous enfermez dehors. Testez la configuration avec sudo sshd -t avant de recharger."),
   tip("~/.ssh/config évite de retaper les options : Host prod / HostName 203.0.113.10 / User deploy.")],
  [single("lx-10-1", "Que copie-t-on sur le serveur ?", ["La clé publique", "La clé privée", "Les deux", "La phrase de passe"], 0, "La clé privée ne quitte jamais votre machine."),
   single("lx-10-2", "Quel type de clé recommander aujourd'hui ?", ["ed25519", "dsa", "rsa 1024", "Aucune, le mot de passe suffit"], 0, "Courte, rapide et sûre."),
   single("lx-10-3", "Avant de recharger sshd après modification, il faut…", ["Tester la syntaxe (sshd -t) et garder une session ouverte", "Redémarrer la machine", "Supprimer authorized_keys", "Désactiver le pare-feu"], 0,
          "Une erreur de configuration peut couper l'accès distant."),
   cmd("lx-10-4", "Générez une clé ed25519.", ["ssh-keygen -t ed25519"], "Ajoutez -C pour un commentaire identifiant la machine.")],
  lab("sshd", "Ce serveur accepte root et les mots de passe. Durcissez sa configuration.",
      "Port 22\nPermitRootLogin yes\nPasswordAuthentication yes\nPermitEmptyPasswords yes\nX11Forwarding yes\nMaxAuthTries 10\n",
      [no("SS001", "root ne peut plus se connecter"), no("SS002", "Mots de passe désactivés"), no("SS003", "Pas de mot de passe vide"),
       no("SS005", "Essais limités"), no("SS006", "Utilisateurs autorisés listés"), valid()],
      "Passez les directives à no, MaxAuthTries à 3 et ajoutez AllowUsers deploy.",
      "Port 22\nPermitRootLogin no\nPasswordAuthentication no\nPermitEmptyPasswords no\nX11Forwarding no\nMaxAuthTries 3\nAllowUsers deploy\n")))

project = {"title": "Script de sauvegarde digne de la production",
  "brief": "Écrivez le script qui archive chaque nuit un dossier d'application : robuste aux erreurs, sans secret, sans suppression dangereuse.",
  "lab": lab("shell", "Objectif : aucun problème bloquant ni avertissement, mode strict, garde-fous sur les variables.",
      "SOURCE=$1\nDEST=/sauvegardes\ncd $DEST\nPASSWORD=s3cretSauvegarde\ntar -czf sauvegarde.tar.gz $SOURCE\nrm -rf $DEST/ancienne\nchmod 777 sauvegarde.tar.gz\n",
      [clean(), nowarn(), has("set -euo pipefail", "Mode strict"), has(":?", "Variables obligatoires vérifiées"), has("chmod 600", "Archive privée (600)")],
      "Reprenez les labos du module : shebang, mode strict, guillemets, ${VAR:?}, secret lu depuis l'environnement, droits minimaux.",
      "#!/usr/bin/env bash\nset -euo pipefail\nSOURCE=\"${1:?dossier source requis}\"\nDEST=\"${DEST:-/sauvegardes}\"\n: \"${PASSWORD:?variable PASSWORD requise}\"\n"
      "archive=\"$DEST/sauvegarde-$(date +%F).tar.gz\"\ntar -czf \"$archive\" -C \"$SOURCE\" .\nchmod 600 \"$archive\"\nrm -rf -- \"${DEST:?}/ancienne\"\n"),
  "rubric": rubric(
    ("Robustesse", "Continue après une erreur", "set -euo pipefail", "Mode strict et codes de retour vérifiés, messages clairs"),
    ("Variables", "Expansions non protégées", "Guillemets partout", "Guillemets et ${VAR:?} avant toute action destructrice"),
    ("Secrets", "Secret dans le script", "Lu depuis l'environnement", "Lu depuis l'environnement ou un fichier 600, absent des journaux"),
    ("Droits", "chmod 777", "Droits adaptés", "Moindre privilège (600 pour les archives) et compte dédié"),
    ("Exploitation", "Aucune trace", "Journal de sortie", "Journal, rotation des archives et test de restauration documenté"))}

glossary = [
  ("Shell", "Programme qui interprète les commandes (Bash, Zsh)."), ("Chemin absolu", "Chemin qui commence à la racine « / »."),
  ("Permissions", "Droits lecture (r), écriture (w), exécution (x) pour propriétaire, groupe, autres."),
  ("root", "Super-utilisateur qui a tous les droits."), ("sudo", "Exécute une commande avec d'autres droits, de façon journalisée."),
  ("Processus", "Programme en cours d'exécution, identifié par un PID."), ("Signal", "Message envoyé à un processus (SIGTERM, SIGKILL)."),
  ("systemd", "Gestionnaire de services et de démarrage de la plupart des distributions."),
  ("Tube (pipe)", "Branchement de la sortie d'une commande sur l'entrée d'une autre."), ("Mode strict", "set -euo pipefail en tête de script."),
  ("Shebang", "Première ligne #! qui choisit l'interpréteur."), ("Clé SSH", "Paire publique/privée pour s'authentifier sans mot de passe."),
  ("sshd_config", "Fichier de configuration du serveur SSH."),
]

write_module("linux", "Terminal Linux, la salle des cartes",
  "Se repérer dans le terminal, gérer fichiers, droits, processus et services, écrire des scripts Bash sûrs et durcir SSH.",
  ["Naviguer et manipuler les fichiers sans risque", "Appliquer le moindre privilège (droits, sudo)",
   "Observer processus, services et journaux", "Écrire des scripts Bash robustes", "Accéder à un serveur par clé SSH et durcir sshd"],
  [], L, project, glossary)
