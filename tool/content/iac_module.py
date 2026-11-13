#!/usr/bin/env python3
"""Module « Terraform/OpenTofu et Ansible » : python3 tool/content/iac_module.py"""
from common import *

TF_HEAD = ("terraform {\n  required_version = \">= 1.6, < 2.0\"\n  required_providers {\n    aws = {\n      source  = \"hashicorp/aws\"\n"
           "      version = \"~> 5.80\"\n    }\n  }\n}\n\nprovider \"aws\" {\n  region = \"eu-west-3\"\n}\n")
BACKEND = ("  backend \"s3\" {\n    bucket       = \"exemple-etat-terraform\"\n    key          = \"prod/terraform.tfstate\"\n    region       = \"eu-west-3\"\n"
           "    use_lockfile = true\n  }\n")
TF_HEAD_BACKEND = TF_HEAD.replace("  required_providers {", BACKEND + "  required_providers {")

I = []

I.append(lesson("pourquoi-iac", "L'infrastructure comme du code", 15,
  ["Comprendre les bénéfices de l'IaC", "Distinguer provisionnement et configuration"],
  [t("Décrire l'infrastructure dans des fichiers versionnés permet de la relire en PR, de la reproduire à l'identique, de "
     "savoir qui a changé quoi et de reconstruire après un sinistre. Les clics dans une console ne laissent pas cette trace."),
   t("Terraform (ou son fork libre OpenTofu, compatible) provisionne : réseaux, machines, bases, DNS. Ansible configure : "
     "paquets, fichiers, services sur des machines existantes. Les deux se complètent."),
   t("Les deux sont déclaratifs et idempotents : on décrit l'état voulu, et relancer ne change rien si l'état est déjà atteint."),
   warn("Mélanger modifications manuelles et IaC crée une « dérive » : le prochain apply peut écraser ou détruire ce qui a été fait à la main.")],
  [single("ic-1-1", "Avantage principal de l'IaC ?", ["Infrastructure relue, versionnée et reproductible", "Plus de clics", "Pas besoin de Git", "Gratuit"], 0, "Le code d'infrastructure suit le même cycle que le code applicatif."),
   single("ic-1-2", "Terraform/OpenTofu sert surtout à…", ["Provisionner des ressources (réseaux, machines, DNS)", "Configurer des fichiers sur un serveur", "Écrire des tests", "Compiler du code"], 0, "Ansible prend le relais pour la configuration."),
   single("ic-1-3", "Que signifie idempotent ?", ["Relancer ne change rien si l'état voulu est atteint", "S'exécute une seule fois", "Ne peut pas échouer", "S'exécute en parallèle"], 0, "Propriété clé pour relancer sans crainte."),
   single("ic-1-4", "Qu'est-ce que la dérive ?", ["Un écart entre le code et l'infrastructure réelle", "Une panne réseau", "Une version de Terraform", "Une sauvegarde"], 0, "Souvent causée par des changements manuels.")]))

I.append(lesson("terraform-bases", "Terraform/OpenTofu : providers, ressources, plan", 22,
  ["Écrire une première configuration", "Lire un plan avant de l'appliquer", "Épingler les versions"],
  [code(TF_HEAD + "\nresource \"aws_instance\" \"web\" {\n  ami           = \"ami-0abcdef1234567890\"\n  instance_type = \"t3.micro\"\n}", "Versions épinglées, fournisseur, ressource"),
   code("tofu init     # ou terraform init\ntofu fmt -check\ntofu validate\ntofu plan -out=plan.tfplan\ntofu apply plan.tfplan", "Le cycle de travail"),
   t("Le plan annonce + (création), ~ (modification), - (destruction) et -/+ (remplacement). On le lit TOUJOURS, en particulier les destructions."),
   warn("Sans contrainte de version, un nouveau fournisseur majeur peut changer le comportement d'une ressource. Le fichier "
        ".terraform.lock.hcl fixe les versions exactes : versionnez-le.")],
  [single("ic-2-1", "Que signifie -/+ dans un plan ?", ["La ressource sera détruite puis recréée", "Aucun changement", "Une création", "Une lecture"], 0, "Attention aux données qu'elle contient."),
   cmd("ic-2-2", "Enregistrez le plan dans plan.tfplan avec OpenTofu.", ["tofu plan -out=plan.tfplan", "tofu plan -out plan.tfplan", "terraform plan -out=plan.tfplan"], "On applique ensuite exactement ce plan relu."),
   single("ic-2-3", "Faut-il versionner .terraform.lock.hcl ?", ["Oui, il fixe les versions exactes des fournisseurs", "Non, jamais", "Seulement en local", "Il contient des secrets"], 0, "Comme un fichier de verrouillage npm."),
   single("ic-2-4", "OpenTofu est…", ["Un fork libre de Terraform, compatible", "Un fournisseur cloud", "Un module Ansible", "Un langage différent"], 0, "Né après le changement de licence de Terraform.")],
  lab("terraform", "Cette configuration n'épingle ni Terraform/OpenTofu ni le fournisseur. Corrigez.",
      "provider \"aws\" {\n  region = \"eu-west-3\"\n}\n\nresource \"aws_instance\" \"web\" {\n  ami           = \"ami-0abcdef1234567890\"\n  instance_type = \"t3.micro\"\n}\n",
      [no("TF001", "Version de l'outil contrainte"), no("TF002", "Fournisseur épinglé"), valid()],
      "Ajoutez un bloc terraform { required_version = \">= 1.6, < 2.0\" ; required_providers { aws = { source = …, version = \"~> 5.80\" } } }.",
      TF_HEAD + "\nresource \"aws_instance\" \"web\" {\n  ami           = \"ami-0abcdef1234567890\"\n  instance_type = \"t3.micro\"\n}\n")))

I.append(lesson("variables-secrets", "Variables, sorties et secrets", 20,
  ["Paramétrer une configuration", "Ne jamais écrire un secret dans le code"],
  [code("variable \"db_password\" {\n  type      = string\n  sensitive = true\n}\n\nresource \"aws_db_instance\" \"base\" {\n  password = var.db_password\n}",
        "Variable sensible, fournie de l'extérieur"),
   t("La valeur vient de TF_VAR_db_password, d'un fichier .tfvars non versionné ou, mieux, d'un gestionnaire de secrets "
     "(data source Vault, Secrets Manager). sensitive = true la masque dans les plans et sorties."),
   warn("Un secret passé à une ressource se retrouve en clair dans le fichier d'état : protégez l'état (backend chiffré, accès restreint)."),
   tip("Les outputs exposent des valeurs utiles (adresse d'un équilibreur) aux autres configurations ; marquez-les sensibles si nécessaire.")],
  [single("ic-3-1", "Effet de sensitive = true ?", ["La valeur est masquée dans les plans et sorties", "La valeur est chiffrée dans l'état", "La variable devient obligatoire", "Aucun"], 0, "Elle reste présente dans l'état."),
   single("ic-3-2", "Comment fournir une variable sans fichier versionné ?", ["Variable d'environnement TF_VAR_nom", "En dur dans main.tf", "Dans le README", "Dans un commentaire"], 0, "Ou via un gestionnaire de secrets."),
   single("ic-3-3", "Où un secret finit-il toujours ?", ["Dans le fichier d'état", "Nulle part", "Dans le plan affiché", "Dans Git automatiquement"], 0, "D'où la protection de l'état."),
   single("ic-3-4", "À quoi servent les outputs ?", ["Exposer des valeurs utiles à d'autres", "Supprimer des ressources", "Installer des fournisseurs", "Chiffrer l'état"], 0, "Par exemple une adresse IP ou un nom DNS.")],
  lab("terraform", "Le mot de passe de la base est écrit en dur. Passez par une variable sensible sans valeur par défaut.",
      TF_HEAD + "\nvariable \"db_password\" {\n  type    = string\n  default = \"Sup3rSecret-prod\"\n}\n\nresource \"aws_db_instance\" \"base\" {\n  engine         = \"postgres\"\n  instance_class = \"db.t4g.micro\"\n  username       = \"app\"\n  password       = \"Sup3rSecret-prod\"\n}\n",
      [no("TF003", "Plus de secret en dur"), no("TF005", "Variable marquée sensible"), hasnt("Sup3rSecret", "Le mot de passe a disparu du code"), clean()],
      "Supprimez default, ajoutez sensitive = true et utilisez password = var.db_password.",
      TF_HEAD + "\nvariable \"db_password\" {\n  type      = string\n  sensitive = true\n}\n\nresource \"aws_db_instance\" \"base\" {\n  engine         = \"postgres\"\n  instance_class = \"db.t4g.micro\"\n  username       = \"app\"\n  password       = var.db_password\n}\n")))

I.append(lesson("etat", "L'état et le backend distant", 20,
  ["Comprendre le rôle du fichier d'état", "Partager l'état en équipe avec verrouillage"],
  [t("L'état (terraform.tfstate) relie chaque ressource du code à l'objet réel. Sans lui, l'outil ne sait plus ce qu'il gère. "
     "Il contient des identifiants… et des secrets en clair."),
   t("En local, l'état ne se partage pas et deux personnes peuvent appliquer en même temps et le corrompre. Un backend distant "
     "(S3, GCS, HTTP, Terraform Cloud…) le centralise, le chiffre et le verrouille pendant un apply."),
   code("terraform {\n" + BACKEND + "}", "Backend S3 avec verrouillage natif (versions récentes ; sinon table DynamoDB)"),
   warn("Ne versionnez jamais terraform.tfstate ni ses sauvegardes (*.tfstate.backup) : ajoutez-les au .gitignore.")],
  [single("ic-4-1", "Que contient l'état ?", ["La correspondance code ↔ ressources réelles, secrets compris", "Le code source", "Les journaux", "Rien d'important"], 0, "À protéger comme un secret."),
   single("ic-4-2", "Pourquoi un verrou sur l'état ?", ["Empêcher deux apply simultanés", "Accélérer le plan", "Chiffrer les variables", "Rendre l'état public"], 0, "Deux écritures concurrentes le corrompraient."),
   single("ic-4-3", "Faut-il committer terraform.tfstate ?", ["Non, jamais", "Oui, toujours", "Seulement en production", "Seulement compressé"], 0, "Il contient des secrets."),
   cmd("ic-4-4", "Listez les ressources présentes dans l'état avec OpenTofu.", ["tofu state list", "terraform state list"], "Pratique pour comprendre ce qui est géré.")],
  lab("terraform", "L'état est local : impossible de travailler en équipe en sécurité. Configurez un backend distant verrouillé.",
      TF_HEAD + "\nresource \"aws_s3_bucket\" \"site\" {\n  bucket = \"exemple-site\"\n}\n",
      [no("TF006", "Backend distant configuré"), has("use_lockfile", "Verrouillage activé"), valid()],
      "Dans le bloc terraform, ajoutez backend \"s3\" { bucket, key, region, use_lockfile = true }.",
      TF_HEAD_BACKEND + "\nresource \"aws_s3_bucket\" \"site\" {\n  bucket = \"exemple-site\"\n}\n")))

I.append(lesson("modules", "Modules et environnements", 18,
  ["Factoriser avec des modules", "Séparer recette et production"],
  [code("module \"reseau\" {\n  source   = \"./modules/reseau\"\n  cidr     = \"10.20.0.0/16\"\n  nom      = \"prod\"\n}", "Appel d'un module local"),
   t("Un module regroupe des ressources réutilisables avec des variables d'entrée (typées et documentées) et des sorties. "
     "Les modules publics doivent être épinglés à une version comme les fournisseurs."),
   t("Recette et production : un dossier (ou espace d'état) par environnement, chacun avec son propre état et ses propres "
     "droits. Une erreur en recette ne touche jamais la production."),
   tip("Des variables typées (type = number, list(string)) et documentées (description) font de votre module une API claire.")],
  [single("ic-5-1", "Intérêt d'un module ?", ["Réutiliser un ensemble de ressources paramétrable", "Remplacer l'état", "Chiffrer les variables", "Accélérer apply"], 0, "Un module joue le rôle d'une fonction réutilisable."),
   single("ic-5-2", "Comment isoler recette et production ?", ["États et droits séparés par environnement", "Un seul état partagé", "Des commentaires", "Des branches Git uniquement"], 0, "Un incident ne déborde pas."),
   single("ic-5-3", "Un module public doit être…", ["Épinglé à une version", "Toujours sur main", "Copié sans version", "Évité"], 0, "La version épinglée garantit un résultat reproductible."),
   single("ic-5-4", "Pourquoi typer les variables ?", ["Détecter les erreurs d'entrée tôt et documenter", "Obligatoire pour l'état", "Accélérer", "Chiffrer"], 0, "Le plan échoue proprement sur une mauvaise valeur.")],
  lab("terraform", "Les variables de ce module ne sont ni typées ni documentées. Faites-en une API claire.",
      "variable \"cidr\" {\n  default = \"10.20.0.0/16\"\n}\n\nvariable \"zones\" {\n  default = [\"eu-west-3a\", \"eu-west-3b\"]\n}\n\nresource \"aws_vpc\" \"principal\" {\n  cidr_block = var.cidr\n}\n",
      [no("TF008", "Variables typées"), has("description", "Variables documentées"), valid()],
      "Ajoutez type = string pour cidr, type = list(string) pour zones, et une description à chacune.",
      "variable \"cidr\" {\n  type        = string\n  description = \"Plage d'adresses du réseau principal\"\n  default     = \"10.20.0.0/16\"\n}\n\nvariable \"zones\" {\n  type        = list(string)\n  description = \"Zones de disponibilité utilisées\"\n  default     = [\"eu-west-3a\", \"eu-west-3b\"]\n}\n\nresource \"aws_vpc\" \"principal\" {\n  cidr_block = var.cidr\n}\n")))

I.append(lesson("iac-ci", "Plan en CI et revue", 18,
  ["Automatiser fmt, validate et plan sur chaque PR", "Appliquer seulement un plan relu"],
  [t("Chaque PR d'infrastructure déclenche fmt -check, validate, un analyseur (tflint, checkov, trivy config) et un plan publié "
     "en commentaire. Les relecteurs voient exactement ce qui va changer."),
   t("L'apply se fait depuis la branche principale, avec le plan validé, par un compte de déploiement aux droits limités et des "
     "identifiants temporaires (OIDC)."),
   code("tofu fmt -check -recursive\ntofu validate\ntofu plan -out=plan.tfplan -input=false\ntofu show -no-color plan.tfplan > plan.txt", "Étapes typiques en CI"),
   warn("Un plan qui annonce une destruction inattendue doit bloquer la fusion jusqu'à explication.")],
  [single("ic-6-1", "Pourquoi publier le plan dans la PR ?", ["Les relecteurs voient précisément les changements", "Pour accélérer apply", "Pour chiffrer l'état", "Obligatoire"], 0, "Relire un plan vaut mieux que relire du HCL seul."),
   single("ic-6-2", "D'où lancer l'apply ?", ["De la branche principale, avec le plan relu", "Du poste d'un développeur", "D'une branche quelconque", "Jamais"], 0, "Traçable et reproductible."),
   cmd("ic-6-3", "Vérifiez le formatage de tous les fichiers sans les modifier (OpenTofu).", ["tofu fmt -check -recursive", "tofu fmt -recursive -check", "terraform fmt -check -recursive"], "Échoue si un fichier n'est pas formaté."),
   single("ic-6-4", "Une destruction inattendue dans le plan…", ["Bloque la fusion jusqu'à explication", "Est normale", "Se corrige après", "Est ignorée"], 0, "Prudence avec les données.")]))

I.append(lesson("ansible-bases", "Ansible : inventaire, modules, idempotence", 20,
  ["Décrire un inventaire", "Utiliser les modules plutôt que des commandes shell"],
  [code("[web]\nweb1.exemple.org\nweb2.exemple.org\n\n[web:vars]\nansible_user=deploy", "Inventaire au format INI"),
   code("ansible web -m ansible.builtin.ping\nansible-playbook -i inventaire.ini site.yml --check --diff", "Tester la connexion, simuler un playbook"),
   t("Ansible se connecte en SSH, sans agent. Un module (apt, copy, template, systemd, user) décrit un état et ne change "
     "rien s'il est déjà atteint ; shell: apt-get install … refait le travail et signale « changed » à chaque fois."),
   tip("Les noms complets (ansible.builtin.apt) évitent les ambiguïtés entre collections.")],
  [single("ic-7-1", "Comment Ansible se connecte-t-il aux machines ?", ["En SSH, sans agent", "Avec un agent installé", "Par FTP", "Par HTTP uniquement"], 0, "Il suffit de Python côté cible."),
   single("ic-7-2", "Pourquoi préférer ansible.builtin.apt à shell: apt-get ?", ["Le module est idempotent et décrit un état", "shell est interdit", "apt est plus rapide", "Aucune différence"], 0, "Relancer ne change rien si tout est en place."),
   cmd("ic-7-3", "Testez la connexion à tous les hôtes du groupe web.", ["ansible web -m ansible.builtin.ping", "ansible web -m ping"], "Ce n'est pas un ping ICMP mais un test Ansible complet."),
   single("ic-7-4", "Que fait --check --diff ?", ["Simule et montre les changements sans les appliquer", "Applique deux fois", "Supprime l'inventaire", "Chiffre le playbook"], 0, "Idéal avant un premier passage.")],
  lab("ansible", "Ce playbook utilise des commandes shell là où des modules existent. Rendez-le idempotent.",
      "- hosts: web\n  become: true\n  tasks:\n    - name: Installer nginx\n      ansible.builtin.shell: apt-get install -y nginx\n    - name: Démarrer nginx\n      ansible.builtin.command: systemctl start nginx\n",
      [no("AN002", "Modules dédiés utilisés"), valid()], "Utilisez ansible.builtin.apt (name, state: present) et ansible.builtin.systemd (name, state: started, enabled: true).",
      "- hosts: web\n  become: true\n  tasks:\n    - name: Installer nginx\n      ansible.builtin.apt:\n        name: nginx\n        state: present\n        update_cache: true\n    - name: Démarrer nginx\n      ansible.builtin.systemd:\n        name: nginx\n        state: started\n        enabled: true\n")))

I.append(lesson("playbooks", "Playbooks, handlers et rôles", 20,
  ["Structurer un playbook lisible", "Redémarrer un service seulement si nécessaire"],
  [code("tasks:\n  - name: Déployer la configuration nginx\n    ansible.builtin.template:\n      src: nginx.conf.j2\n      dest: /etc/nginx/nginx.conf\n    notify: Recharger nginx\nhandlers:\n  - name: Recharger nginx\n    ansible.builtin.service:\n      name: nginx\n      state: reloaded",
        "Le handler ne s'exécute que si la configuration a changé"),
   t("Chaque tâche porte un nom explicite : le journal d'exécution devient un compte rendu lisible."),
   t("state: latest met à jour le paquet à chaque passage, sans contrôle : préférez present (et une version précise si besoin), "
     "et planifiez les mises à jour."),
   tip("Les rôles (roles/nginx/tasks, templates, handlers, defaults) rendent la configuration réutilisable entre projets.")],
  [single("ic-8-1", "Quand un handler s'exécute-t-il ?", ["Quand une tâche qui le notifie a changé quelque chose", "À chaque tâche", "Jamais", "Au début du playbook"], 0, "Et une seule fois en fin de play."),
   single("ic-8-2", "Pourquoi nommer chaque tâche ?", ["Rendre le journal d'exécution lisible", "Obligatoire pour SSH", "Accélérer", "Chiffrer"], 0, "Le nom apparaît dans la sortie."),
   single("ic-8-3", "Problème de state: latest ?", ["Mise à jour non contrôlée à chaque exécution", "Le paquet est supprimé", "Plus lent", "Aucun"], 0, "Les mises à jour se planifient."),
   single("ic-8-4", "Intérêt des rôles ?", ["Réutiliser une configuration structurée", "Remplacer l'inventaire", "Chiffrer les variables", "Supprimer SSH"], 0, "Partageables via Ansible Galaxy.")],
  lab("ansible", "Ces tâches sont anonymes et mettent à jour sans contrôle. Corrigez.",
      "- hosts: web\n  become: true\n  tasks:\n    - ansible.builtin.apt:\n        name: nginx\n        state: latest\n    - ansible.builtin.template:\n        src: nginx.conf.j2\n        dest: /etc/nginx/nginx.conf\n      notify: Recharger nginx\n"
      "  handlers:\n    - name: Recharger nginx\n      ansible.builtin.service:\n        name: nginx\n        state: reloaded\n",
      [no("AN001", "Toutes les tâches sont nommées"), no("AN005", "Plus de state: latest"), valid()],
      "Ajoutez name: à chaque tâche et remplacez latest par present.",
      "- hosts: web\n  become: true\n  tasks:\n    - name: Installer nginx\n      ansible.builtin.apt:\n        name: nginx\n        state: present\n    - name: Déployer la configuration nginx\n      ansible.builtin.template:\n        src: nginx.conf.j2\n        dest: /etc/nginx/nginx.conf\n      notify: Recharger nginx\n"
      "  handlers:\n    - name: Recharger nginx\n      ansible.builtin.service:\n        name: nginx\n        state: reloaded\n")))

I.append(lesson("vault", "Secrets avec ansible-vault et no_log", 20,
  ["Chiffrer les variables sensibles", "Empêcher l'affichage des secrets dans les journaux"],
  [code("ansible-vault create group_vars/prod/secrets.yml\nansible-vault edit group_vars/prod/secrets.yml\nansible-playbook site.yml --ask-vault-pass", "Créer, modifier, utiliser un fichier chiffré"),
   t("Le fichier chiffré peut être versionné ; le mot de passe du coffre, lui, reste hors du dépôt (gestionnaire de mots de "
     "passe, variable de la CI)."),
   code("- name: Créer l'utilisateur applicatif\n  ansible.builtin.user:\n    name: app\n    password: \"{{ app_password | password_hash('sha512') }}\"\n  no_log: true", "no_log empêche l'affichage des arguments"),
   warn("Sans no_log, un échec ou le mode -v affiche les arguments de la tâche, mot de passe compris.")],
  [single("ic-9-1", "Peut-on versionner un fichier chiffré par ansible-vault ?", ["Oui, mais pas le mot de passe du coffre", "Non, jamais", "Oui, avec son mot de passe", "Seulement en privé"], 0, "Le mot de passe reste hors du dépôt."),
   single("ic-9-2", "Rôle de no_log: true ?", ["Empêcher l'affichage des arguments de la tâche", "Désactiver la tâche", "Chiffrer le fichier", "Accélérer"], 0, "Indispensable pour les secrets."),
   cmd("ic-9-3", "Créez un fichier chiffré group_vars/prod/secrets.yml.", ["ansible-vault create group_vars/prod/secrets.yml"], "L'éditeur s'ouvre et le fichier est chiffré à l'enregistrement."),
   single("ic-9-4", "Où ranger le mot de passe du coffre ?", ["Gestionnaire de mots de passe ou variable protégée de la CI", "Dans le dépôt", "Dans le playbook", "Dans le README"], 0, "Jamais avec le fichier chiffré.")],
  lab("ansible", "Le mot de passe est en clair dans le playbook et la tâche l'afficherait dans les journaux. Corrigez.",
      "- hosts: web\n  become: true\n  vars:\n    app_password: \"Sup3rSecret-prod\"\n  tasks:\n    - name: Créer l'utilisateur applicatif\n      ansible.builtin.user:\n        name: app\n        password: \"{{ app_password | password_hash('sha512') }}\"\n",
      [no("AN003", "Plus de secret en clair"), no("AN004", "no_log activé"), clean()],
      "Déplacez app_password dans un fichier chiffré (vars_files) et ajoutez no_log: true à la tâche.",
      "- hosts: web\n  become: true\n  vars_files:\n    - group_vars/prod/secrets.yml\n  tasks:\n    - name: Créer l'utilisateur applicatif\n      ansible.builtin.user:\n        name: app\n        password: \"{{ app_password | password_hash('sha512') }}\"\n      no_log: true\n")))

I.append(lesson("executer-sans-casser", "Exécuter sans casser", 18,
  ["Limiter la portée d'une exécution", "Traiter les erreurs au lieu de les ignorer"],
  [code("ansible-playbook site.yml --check --diff\nansible-playbook site.yml --limit web1.exemple.org\nansible-playbook site.yml --tags nginx", "Simuler, cibler une machine, cibler des tâches"),
   t("serial: 1 applique un play machine par machine : si la première échoue, les autres restent intactes."),
   t("ignore_errors: true masque tous les échecs. Pour une commande dont certains codes de retour sont normaux, décrivez-les "
     "avec failed_when et changed_when."),
   code("- name: Appliquer les migrations\n  ansible.builtin.command: /srv/app/bin/migrer\n  register: migration\n  changed_when: \"'appliquée' in migration.stdout\"", "La tâche ne signale « changed » que si une migration a eu lieu")],
  [single("ic-10-1", "Que fait --limit web1 ?", ["Restreint l'exécution à cette machine", "Limite la durée", "Limite la mémoire", "Rien"], 0, "Idéal pour un premier essai."),
   single("ic-10-2", "Intérêt de serial: 1 ?", ["Appliquer machine par machine pour limiter les dégâts", "Accélérer", "Chiffrer", "Paralléliser"], 0, "Déploiement progressif."),
   single("ic-10-3", "Alternative à ignore_errors ?", ["failed_when / changed_when ou block/rescue", "Supprimer la tâche", "Mode verbeux", "Aucune"], 0, "On décrit précisément ce qui est normal."),
   single("ic-10-4", "Pourquoi changed_when sur une commande ?", ["Qu'elle ne signale un changement que lorsqu'il a eu lieu", "Pour l'accélérer", "Pour la chiffrer", "Pour la rendre obligatoire"], 0, "Le compte rendu reste fiable.")],
  lab("ansible", "Cette tâche ignore tous ses échecs et se dit toujours « changed ». Rendez-la honnête.",
      "- hosts: web\n  tasks:\n    - name: Appliquer les migrations\n      ansible.builtin.command: /srv/app/bin/migrer\n      ignore_errors: true\n",
      [no("AN006", "Plus d'ignore_errors"), no("AN007", "Changement détecté honnêtement"), valid()],
      "Retirez ignore_errors, ajoutez register: migration et changed_when: \"'appliquée' in migration.stdout\".",
      "- hosts: web\n  tasks:\n    - name: Appliquer les migrations\n      ansible.builtin.command: /srv/app/bin/migrer\n      register: migration\n      changed_when: \"'appliquée' in migration.stdout\"\n")))

project = {"title": "Infrastructure d'un service web avec OpenTofu",
  "brief": "Écrivez la configuration d'un service web : versions épinglées, état partagé et verrouillé, aucun secret dans le code, réseau minimal, stockage privé.",
  "lab": lab("terraform", "Objectif : aucun problème bloquant ni avertissement, backend distant et variable sensible.",
      "provider \"aws\" {\n  region = \"eu-west-3\"\n}\n\nvariable \"api_token\" {\n  default = \"tok-prod-123456\"\n}\n\nresource \"aws_security_group\" \"web\" {\n  ingress {\n    from_port   = 22\n    to_port     = 22\n    protocol    = \"tcp\"\n    cidr_blocks = [\"0.0.0.0/0\"]\n  }\n}\n\n"
      "resource \"aws_s3_bucket_acl\" \"medias\" {\n  bucket = \"exemple-medias\"\n  acl    = \"public-read\"\n}\n\nresource \"aws_db_instance\" \"base\" {\n  engine   = \"postgres\"\n  password = \"Sup3rSecret-prod\"\n}\n",
      [clean(), nowarn(), has("backend \"s3\"", "Backend distant"), has("sensitive", "Variables sensibles"), hasnt("0.0.0.0/0", "Rien d'ouvert à tout Internet")],
      "Reprenez les labos : bloc terraform complet avec backend, variables typées et sensibles, SSH restreint, ACL privée, mot de passe en variable.",
      TF_HEAD_BACKEND + "\nvariable \"api_token\" {\n  type        = string\n  description = \"Jeton de l'API, fourni par TF_VAR_api_token\"\n  sensitive   = true\n}\n\nvariable \"db_password\" {\n  type        = string\n  description = \"Mot de passe de la base\"\n  sensitive   = true\n}\n\n"
      "resource \"aws_security_group\" \"web\" {\n  ingress {\n    from_port   = 22\n    to_port     = 22\n    protocol    = \"tcp\"\n    cidr_blocks = [\"203.0.113.10/32\"]\n  }\n}\n\nresource \"aws_s3_bucket_acl\" \"medias\" {\n  bucket = \"exemple-medias\"\n  acl    = \"private\"\n}\n\n"
      "resource \"aws_db_instance\" \"base\" {\n  engine   = \"postgres\"\n  password = var.db_password\n}\n"),
  "rubric": rubric(
    ("Reproductibilité", "Versions libres", "Outil et fournisseurs épinglés", "Épinglage, fichier de verrouillage versionné, modules versionnés"),
    ("État", "Local", "Backend distant", "Backend chiffré, verrouillé, accès restreint, un état par environnement"),
    ("Secrets", "En dur dans le code", "Variables sensibles", "Gestionnaire de secrets, rien dans le code ni les journaux"),
    ("Exposition", "0.0.0.0/0, stockage public", "Accès restreints", "Moindre exposition vérifiée par un analyseur en CI"),
    ("Processus", "Apply depuis un poste", "Plan relu en PR", "Plan en PR, apply depuis main avec identités temporaires"))}

glossary = [
  ("IaC", "Infrastructure décrite dans du code versionné."), ("OpenTofu", "Fork libre de Terraform, compatible."),
  ("Provider", "Extension qui sait piloter une plateforme (aws, google, kubernetes)."), ("Plan", "Aperçu des changements avant application."),
  ("État (state)", "Correspondance entre le code et les ressources réelles."), ("Backend", "Lieu de stockage partagé et verrouillé de l'état."),
  ("Module", "Ensemble réutilisable de ressources paramétrées."), ("Dérive", "Écart entre le code et la réalité."),
  ("Inventaire", "Liste des machines gérées par Ansible."), ("Module Ansible", "Unité idempotente décrivant un état (apt, copy, user…)."),
  ("Playbook", "Fichier YAML décrivant des plays et des tâches."), ("Handler", "Tâche exécutée seulement si une autre a changé quelque chose."),
  ("ansible-vault", "Chiffrement de fichiers de variables."), ("Idempotence", "Relancer ne change rien si l'état est déjà atteint."),
]

write_module("iac", "Terraform, OpenTofu et Ansible, le chantier naval",
  "Provisionner avec Terraform/OpenTofu (versions, variables, état, modules, CI) et configurer avec Ansible (modules, handlers, vault, exécution prudente).",
  ["Écrire une configuration Terraform/OpenTofu reproductible", "Protéger l'état et les secrets",
   "Configurer des serveurs de façon idempotente avec Ansible", "Intégrer plan et revue dans la CI"],
  ["Module Kubernetes", "Module DevOps"], I, project, glossary)
