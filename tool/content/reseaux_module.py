#!/usr/bin/env python3
"""Module « Réseaux, serveurs, cloud » : python3 tool/content/reseaux_module.py"""
from common import *

R = []

R.append(lesson("bases-reseau", "Adresses, ports et protocoles", 18,
  ["Lire une adresse IP et un port", "Distinguer TCP et UDP", "Voir quels services écoutent sur une machine"],
  [t("Une adresse IP identifie une machine sur un réseau (IPv4 : 192.0.2.10 ; IPv6 : 2001:db8::10). Un port (0–65535) "
     "identifie un service sur cette machine : 22 pour SSH, 80 pour HTTP, 443 pour HTTPS, 5432 pour PostgreSQL."),
   t("TCP établit une connexion fiable et ordonnée (web, SSH, bases de données). UDP envoie des messages sans garantie, "
     "plus léger (DNS, visioconférence, jeux)."),
   code("ip a\nss -tlnp\nping -c 3 exemple.org\ntraceroute exemple.org", "Mes adresses, services en écoute, joignabilité, chemin réseau"),
   warn("Un service qui écoute sur 0.0.0.0 accepte les connexions de toutes les interfaces ; sur 127.0.0.1, seulement de la machine elle-même.")],
  [single("rs-1-1", "Port standard de HTTPS ?", ["443", "80", "22", "8080"], 0, "80 est HTTP en clair, 443 HTTPS chiffré."),
   single("rs-1-2", "Protocole sans connexion ni garantie de livraison ?", ["UDP", "TCP", "HTTP", "SSH"], 0, "UDP est utilisé par DNS et la voix sur IP."),
   single("rs-1-3", "Un service écoute sur 127.0.0.1:5432. Qui peut s'y connecter ?", ["Seulement la machine elle-même", "Tout Internet", "Le réseau local", "Personne"], 0, "C'est l'interface de bouclage locale."),
   cmd("rs-1-4", "Listez les ports TCP en écoute avec les processus associés.", ["ss -tlnp", "sudo ss -tlnp", "ss -ltnp"], "t = TCP, l = écoute, n = numérique, p = processus.")]))

R.append(lesson("sous-reseaux", "Sous-réseaux, NAT et adresses privées", 18,
  ["Lire une notation CIDR", "Reconnaître les plages privées et le rôle du NAT"],
  [t("La notation CIDR 10.0.1.0/24 signifie : les 24 premiers bits désignent le réseau, il reste 8 bits pour les machines "
     "(256 adresses, dont 254 utilisables). /16 = 65 536 adresses, /32 = une seule adresse."),
   t("Plages privées (non routées sur Internet) : 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16. Votre box traduit ces adresses "
     "vers son adresse publique : c'est le NAT."),
   code("ip route\nip -4 addr show", "Table de routage (passerelle par défaut) et adresses IPv4"),
   tip("0.0.0.0/0 signifie « toutes les adresses » : dans une règle de pare-feu, c'est tout Internet.")],
  [single("rs-2-1", "Combien d'adresses dans un /24 ?", ["256", "24", "65 536", "1"], 0, "2 puissance 8 = 256 (254 utilisables pour des machines)."),
   single("rs-2-2", "Laquelle est une adresse privée ?", ["192.168.1.20", "8.8.8.8", "203.0.113.5", "1.1.1.1"], 0, "192.168.0.0/16 est une plage privée."),
   single("rs-2-3", "Que représente 0.0.0.0/0 dans une règle d'accès ?", ["Toutes les adresses", "Aucune adresse", "La machine locale", "Le réseau privé"], 0, "Ouvrir à 0.0.0.0/0, c'est ouvrir à tout Internet."),
   single("rs-2-4", "Rôle du NAT de votre box ?", ["Traduire les adresses privées vers l'adresse publique", "Chiffrer le trafic", "Résoudre les noms", "Bloquer les virus"], 0, "Plusieurs machines partagent une adresse publique.")]))

R.append(lesson("dns", "DNS : l'annuaire d'Internet", 18,
  ["Comprendre la résolution de noms", "Lire les enregistrements A, AAAA, CNAME, MX et TXT"],
  [t("Le DNS traduit exemple.org en adresse IP. Un résolveur interroge la racine, puis le serveur de .org, puis le serveur "
     "faisant autorité pour exemple.org. Les réponses sont mises en cache pendant leur TTL."),
   code("dig exemple.org A +short\ndig exemple.org MX\ndig www.exemple.org CNAME\ndig exemple.org TXT", "Interroger différents types d'enregistrements"),
   t("A = IPv4, AAAA = IPv6, CNAME = alias vers un autre nom, MX = serveurs de courrier, TXT = texte libre (vérifications, SPF)."),
   warn("Avant une migration, baissez le TTL quelques jours à l'avance : sinon les anciens résultats restent en cache des heures.")],
  [single("rs-3-1", "Enregistrement qui donne une adresse IPv4 ?", ["A", "AAAA", "MX", "TXT"], 0, "AAAA est son équivalent IPv6."),
   single("rs-3-2", "Que contrôle le TTL ?", ["La durée de mise en cache d'une réponse", "La vitesse du réseau", "Le chiffrement", "Le nombre de serveurs"], 0, "Un TTL court accélère la propagation des changements."),
   cmd("rs-3-3", "Affichez seulement l'adresse IPv4 de exemple.org avec dig.", ["dig exemple.org A +short", "dig +short exemple.org A", "dig +short exemple.org"], "+short n'affiche que la réponse."),
   single("rs-3-4", "Un CNAME est…", ["Un alias vers un autre nom", "Une adresse IPv6", "Un serveur de courrier", "Un certificat"], 0, "www.exemple.org peut pointer vers exemple.org.")]))

R.append(lesson("http", "HTTP : requêtes, réponses et en-têtes", 20,
  ["Lire une requête et une réponse HTTP", "Interpréter les codes de statut", "Poser des en-têtes de sécurité de base"],
  [code("curl -I https://exemple.org\ncurl -sS -X POST -H 'Content-Type: application/json' -d '{\"nom\":\"Ana\"}' https://api.exemple.org/clients",
        "En-têtes d'une réponse, requête POST JSON"),
   t("Méthodes : GET (lire), POST (créer), PUT/PATCH (modifier), DELETE (supprimer). Codes : 2xx succès, 3xx redirection, "
     "4xx erreur du client (404 introuvable, 401 non authentifié, 403 interdit), 5xx erreur du serveur."),
   t("Quelques en-têtes de sécurité simples : ne pas annoncer la version du serveur, X-Content-Type-Options: nosniff (le "
     "navigateur respecte le type annoncé), Content-Security-Policy (sources autorisées)."),
   tip("Un 502 Bad Gateway vient souvent du proxy qui n'arrive pas à joindre l'application derrière lui.")],
  [single("rs-4-1", "Un code 503 indique…", ["Une erreur côté serveur (service indisponible)", "Une page introuvable", "Une redirection", "Un succès"], 0, "Les 5xx sont des erreurs du serveur."),
   single("rs-4-2", "Différence entre 401 et 403 ?", ["401 : non authentifié ; 403 : authentifié mais interdit", "Aucune", "401 : interdit ; 403 : introuvable", "403 : succès"], 0, "On se connecte pour un 401, pas pour un 403."),
   cmd("rs-4-3", "Affichez uniquement les en-têtes de la réponse de https://exemple.org.", ["curl -I https://exemple.org", "curl --head https://exemple.org"], "-I envoie une requête HEAD."),
   single("rs-4-4", "Pourquoi masquer la version du serveur ?", ["Ne pas aider un attaquant à cibler une faille connue", "Accélérer les pages", "Économiser de la bande passante", "Obligation légale"], 0, "C'est une réduction d'exposition, pas une protection suffisante.")],
  lab("nginx", "Ce serveur annonce sa version et n'envoie aucun en-tête de sécurité. Corrigez sa configuration.",
      "server {\n    listen 80;\n    server_name exemple.org;\n    root /var/www/site;\n}\n",
      [no("NG001", "Version masquée"), no("NG005", "En-tête X-Content-Type-Options"), valid()],
      "Ajoutez server_tokens off; et add_header X-Content-Type-Options nosniff always; dans le bloc server.",
      "server {\n    listen 80;\n    server_name exemple.org;\n    server_tokens off;\n    add_header X-Content-Type-Options nosniff always;\n    root /var/www/site;\n}\n")))

R.append(lesson("tls", "TLS et certificats", 22,
  ["Comprendre ce que garantit HTTPS", "Obtenir et renouveler un certificat", "Refuser les protocoles obsolètes"],
  [t("TLS chiffre la connexion et prouve l'identité du serveur grâce à un certificat signé par une autorité reconnue. Il ne "
     "garantit pas que le site est honnête, seulement que vous parlez bien au détenteur du nom."),
   code("sudo certbot --nginx -d exemple.org -d www.exemple.org\nsudo certbot renew --dry-run\nopenssl s_client -connect exemple.org:443 -servername exemple.org </dev/null | openssl x509 -noout -dates",
        "Let's Encrypt avec certbot, test du renouvellement, dates d'expiration"),
   t("SSLv3, TLS 1.0 et 1.1 sont obsolètes et vulnérables : n'autorisez que TLS 1.2 et 1.3."),
   warn("La clé privée du certificat (privkey.pem) ne sort jamais du serveur et n'entre jamais dans Git.")],
  [single("rs-5-1", "Que garantit un certificat valide ?", ["Que vous parlez au détenteur du nom de domaine", "Que le site est honnête", "Que le site est rapide", "Que le site n'a pas de bug"], 0, "Identité et chiffrement, pas honnêteté."),
   single("rs-5-2", "Versions de TLS à autoriser aujourd'hui ?", ["TLS 1.2 et 1.3", "SSLv3 et TLS 1.0", "Toutes", "Aucune"], 0, "Les versions antérieures sont obsolètes."),
   cmd("rs-5-3", "Testez le renouvellement des certificats certbot sans rien changer.", ["sudo certbot renew --dry-run", "certbot renew --dry-run"], "Le renouvellement automatique doit être vérifié."),
   single("rs-5-4", "Où doit rester la clé privée du certificat ?", ["Sur le serveur, jamais dans Git", "Dans le dépôt", "Dans le README", "Chez tous les développeurs"], 0, "Sa fuite permet d'usurper le site.")],
  lab("nginx", "Ce serveur HTTPS accepte encore TLS 1.0 et 1.1. N'autorisez que les versions sûres.",
      "server {\n    listen 443 ssl;\n    server_name exemple.org;\n    server_tokens off;\n    ssl_certificate /etc/letsencrypt/live/exemple.org/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/exemple.org/privkey.pem;\n    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n    root /var/www/site;\n}\n",
      [no("NG002", "Protocoles obsolètes refusés"), valid()], "ssl_protocols TLSv1.2 TLSv1.3;",
      "server {\n    listen 443 ssl;\n    server_name exemple.org;\n    server_tokens off;\n    ssl_certificate /etc/letsencrypt/live/exemple.org/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/exemple.org/privkey.pem;\n    ssl_protocols TLSv1.2 TLSv1.3;\n    root /var/www/site;\n}\n")))

R.append(lesson("reverse-proxy", "Reverse proxy et HTTPS partout", 22,
  ["Placer un reverse proxy devant une application", "Rediriger HTTP vers HTTPS et activer HSTS"],
  [t("Un reverse proxy (nginx, Caddy, Traefik) reçoit les requêtes, termine TLS et les transmet à l'application qui écoute en "
     "local (127.0.0.1:3000). L'application n'est jamais exposée directement."),
   code("location / {\n    proxy_pass http://127.0.0.1:3000;\n    proxy_set_header Host $host;\n    proxy_set_header X-Forwarded-Proto $scheme;\n}",
        "Transmission vers l'application locale"),
   t("Le port 80 ne doit servir qu'à rediriger vers HTTPS (return 301). HSTS indique ensuite au navigateur de ne plus jamais "
     "tenter HTTP pour ce domaine."),
   warn("Activez HSTS seulement quand HTTPS fonctionne pour tous les sous-domaines concernés : le navigateur s'en souviendra des mois.")],
  [single("rs-6-1", "Rôle d'un reverse proxy ?", ["Recevoir les requêtes et les transmettre à l'application locale", "Résoudre les noms", "Remplacer la base de données", "Compiler l'application"], 0, "Il termine aussi souvent TLS."),
   single("rs-6-2", "Que doit faire le serveur sur le port 80 ?", ["Rediriger vers HTTPS", "Servir le site", "Rien", "Servir l'API"], 0, "return 301 https://$host$request_uri;"),
   single("rs-6-3", "Effet de HSTS ?", ["Le navigateur n'utilise plus que HTTPS pour ce domaine", "Accélère HTTP", "Chiffre la base", "Masque la version"], 0, "Empêche le déclassement vers HTTP."),
   single("rs-6-4", "Sur quelle interface l'application derrière le proxy doit-elle écouter ?", ["127.0.0.1", "0.0.0.0", "L'IP publique", "Peu importe"], 0, "Seul le proxy doit pouvoir la joindre.")],
  lab("nginx", "Le port 80 sert le site en clair et HTTPS n'a pas de HSTS. Corrigez les deux.",
      "server {\n    listen 80;\n    server_name exemple.org;\n    server_tokens off;\n    root /var/www/site;\n}\nserver {\n    listen 443 ssl;\n    server_name exemple.org;\n    server_tokens off;\n    ssl_protocols TLSv1.2 TLSv1.3;\n    location / {\n        proxy_pass http://127.0.0.1:3000;\n    }\n}\n",
      [no("NG003", "HSTS activé"), no("NG004", "Le port 80 redirige vers HTTPS"), valid()],
      "Dans le server du port 80 : return 301 https://$host$request_uri; ; dans celui du 443 : add_header Strict-Transport-Security \"max-age=31536000\" always;",
      "server {\n    listen 80;\n    server_name exemple.org;\n    server_tokens off;\n    return 301 https://$host$request_uri;\n}\nserver {\n    listen 443 ssl;\n    server_name exemple.org;\n    server_tokens off;\n    ssl_protocols TLSv1.2 TLSv1.3;\n    add_header Strict-Transport-Security \"max-age=31536000\" always;\n    location / {\n        proxy_pass http://127.0.0.1:3000;\n    }\n}\n")))

R.append(lesson("fichiers-statiques", "Servir des fichiers sans tout exposer", 15,
  ["Servir des fichiers statiques proprement", "Éviter les fuites par listage de dossiers et fichiers cachés"],
  [t("autoindex on transforme un dossier en page listant tous ses fichiers : sauvegardes, exports et fichiers oubliés deviennent "
     "visibles de tous."),
   code("location ~ /\\. {\n    deny all;\n}\nlocation /telechargements/ {\n    autoindex off;\n}", "Refuser les fichiers cachés (.git, .env) et désactiver le listage"),
   t("Un dossier .git servi par erreur permet de reconstituer tout le code source, secrets compris."),
   tip("Placez la racine du site (root) sur un dossier de publication dédié, jamais à la racine du projet.")],
  [single("rs-7-1", "Risque de autoindex on ?", ["Tous les fichiers du dossier deviennent listés publiquement", "Le site est plus lent", "TLS est désactivé", "Aucun"], 0, "Des fichiers oubliés peuvent fuiter."),
   single("rs-7-2", "Pourquoi bloquer les chemins commençant par un point ?", ["Protéger .git, .env et autres fichiers cachés", "Accélérer le cache", "Bloquer les images", "Bloquer HTTPS"], 0, "Un .git exposé révèle le code."),
   single("rs-7-3", "Où pointer root ?", ["Un dossier de publication dédié", "La racine du projet", "Le dossier personnel", "/"], 0, "Seuls les fichiers à publier y figurent."),
   single("rs-7-4", "Un .git exposé permet…", ["De reconstituer le code source et son historique", "Rien", "D'accélérer le site", "De changer le DNS"], 0, "Des outils automatisent cette extraction.")],
  lab("nginx", "Ce dossier de téléchargements liste son contenu publiquement. Corrigez-le.",
      "server {\n    listen 80;\n    server_name fichiers.exemple.org;\n    server_tokens off;\n    root /var/www/fichiers;\n    location /telechargements/ {\n        autoindex on;\n    }\n}\n",
      [no("NG006", "Plus de listage de dossier"), valid()], "Passez autoindex à off (et ajoutez un refus des fichiers cachés).",
      "server {\n    listen 80;\n    server_name fichiers.exemple.org;\n    server_tokens off;\n    root /var/www/fichiers;\n    location ~ /\\. {\n        deny all;\n    }\n    location /telechargements/ {\n        autoindex off;\n    }\n}\n")))

R.append(lesson("pare-feu", "Pare-feu et exposition minimale", 20,
  ["N'ouvrir que les ports nécessaires", "Restreindre l'administration à des adresses connues"],
  [code("sudo ufw default deny incoming\nsudo ufw allow from 203.0.113.10 to any port 22 proto tcp\nsudo ufw allow 443/tcp\nsudo ufw enable\nsudo ufw status verbose",
        "Tout refuser, puis ouvrir SSH à une adresse et HTTPS à tous"),
   t("Dans le cloud, les groupes de sécurité jouent le même rôle. SSH (22) ou RDP (3389) ouverts à 0.0.0.0/0 sont scannés "
     "en permanence par des robots."),
   warn("Ajoutez la règle SSH AVANT d'activer le pare-feu, sinon vous coupez votre propre session."),
   tip("Un bastion ou un VPN (WireGuard) évite d'exposer SSH sur Internet.")],
  [single("rs-8-1", "Politique par défaut recommandée pour les connexions entrantes ?", ["Tout refuser, ouvrir au cas par cas", "Tout accepter", "Refuser seulement le 80", "Aucune"], 0, "Liste blanche explicite."),
   single("rs-8-2", "Pourquoi éviter SSH ouvert à 0.0.0.0/0 ?", ["Des robots le scannent et l'attaquent en permanence", "SSH est lent", "C'est interdit par la loi", "Cela casse HTTPS"], 0, "Restreignez à vos adresses ou passez par un VPN."),
   cmd("rs-8-3", "Autorisez HTTPS entrant avec ufw.", ["sudo ufw allow 443/tcp", "ufw allow 443/tcp", "sudo ufw allow https"], "443/tcp suffit pour HTTPS."),
   single("rs-8-4", "Avant ufw enable sur un serveur distant…", ["Autoriser SSH pour ne pas se couper", "Redémarrer", "Supprimer les clés", "Désactiver le DNS"], 0, "Sinon la session tombe.")],
  lab("terraform", "Ce groupe de sécurité ouvre SSH à tout Internet. Restreignez-le à une adresse d'administration.",
      "resource \"aws_security_group\" \"web\" {\n  name = \"web\"\n\n  ingress {\n    from_port   = 22\n    to_port     = 22\n    protocol    = \"tcp\"\n    cidr_blocks = [\"0.0.0.0/0\"]\n  }\n\n  ingress {\n    from_port   = 443\n    to_port     = 443\n    protocol    = \"tcp\"\n    cidr_blocks = [\"0.0.0.0/0\"]\n  }\n}\n",
      [no("TF004", "SSH n'est plus ouvert à tout Internet"), has("443", "HTTPS reste public"), valid()],
      "Remplacez le cidr_blocks de la règle 22 par votre adresse, ex. [\"203.0.113.10/32\"].",
      "resource \"aws_security_group\" \"web\" {\n  name = \"web\"\n\n  ingress {\n    from_port   = 22\n    to_port     = 22\n    protocol    = \"tcp\"\n    cidr_blocks = [\"203.0.113.10/32\"]\n  }\n\n  ingress {\n    from_port   = 443\n    to_port     = 443\n    protocol    = \"tcp\"\n    cidr_blocks = [\"0.0.0.0/0\"]\n  }\n}\n")))

R.append(lesson("cloud-couts", "Serveurs, cloud et coûts", 20,
  ["Distinguer IaaS, PaaS et SaaS", "Connaître la responsabilité partagée", "Éviter les mauvaises surprises de facture"],
  [t("IaaS : vous louez des machines virtuelles et gérez le système. PaaS : vous déployez votre application, le fournisseur "
     "gère le reste. SaaS : vous utilisez un logiciel prêt. Plus on monte, moins on administre… et moins on contrôle."),
   t("Responsabilité partagée : le fournisseur sécurise l'infrastructure physique ; vous restez responsable de vos données, "
     "accès, configurations et mises à jour."),
   t("Coûts typiques oubliés : trafic sortant (egress), disques et instantanés orphelins, adresses IP réservées, journaux "
     "conservés indéfiniment, machines de test jamais éteintes."),
   warn("Un stockage objet public expose les données à tous — et la bande passante consommée par d'autres vous est facturée."),
   tip("Activez des alertes de budget dès le premier jour et étiquetez chaque ressource (projet, environnement, responsable).")],
  [single("rs-9-1", "Dans un IaaS, qui met à jour le système d'exploitation ?", ["Vous", "Le fournisseur", "Personne", "Le navigateur"], 0, "Vous gérez tout au-dessus de la machine virtuelle."),
   single("rs-9-2", "Coût souvent oublié ?", ["Le trafic sortant (egress)", "Le trafic entrant", "Le nom de domaine en .fr", "Les commits"], 0, "Le trafic sortant est généralement facturé."),
   single("rs-9-3", "Première précaution financière ?", ["Alertes de budget et étiquettes sur les ressources", "Aucune", "Désactiver la facturation", "Tout supprimer chaque soir"], 0, "On voit vite ce qui coûte."),
   single("rs-9-4", "Un bucket public peut coûter cher car…", ["La bande passante utilisée par d'autres vous est facturée", "Il est chiffré", "Il est lent", "Il est gratuit"], 0, "Et les données fuient.")],
  lab("terraform", "Ce stockage d'exports clients est lisible publiquement. Rendez-le privé.",
      "resource \"aws_s3_bucket\" \"exports\" {\n  bucket = \"exemple-exports-clients\"\n}\n\nresource \"aws_s3_bucket_acl\" \"exports\" {\n  bucket = aws_s3_bucket.exports.id\n  acl    = \"public-read\"\n}\n",
      [no("TF007", "Stockage privé"), has("block_public_acls", "Accès public bloqué"), valid()],
      "Passez l'ACL à private et ajoutez une ressource aws_s3_bucket_public_access_block avec les quatre options à true.",
      "resource \"aws_s3_bucket\" \"exports\" {\n  bucket = \"exemple-exports-clients\"\n}\n\nresource \"aws_s3_bucket_acl\" \"exports\" {\n  bucket = aws_s3_bucket.exports.id\n  acl    = \"private\"\n}\n\nresource \"aws_s3_bucket_public_access_block\" \"exports\" {\n  bucket                  = aws_s3_bucket.exports.id\n  block_public_acls       = true\n  block_public_policy     = true\n  ignore_public_acls      = true\n  restrict_public_buckets = true\n}\n")))

R.append(lesson("diagnostic", "Diagnostiquer un problème réseau", 18,
  ["Suivre une démarche couche par couche", "Lire les journaux d'accès et d'erreurs"],
  [t("Démarche : le nom se résout-il (dig) ? La machine répond-elle (ping, traceroute) ? Le port est-il ouvert (nc -zv, ss) ? "
     "Le service répond-il (curl -v) ? Que disent les journaux ?"),
   code("dig +short api.exemple.org\nnc -zv api.exemple.org 443\ncurl -v https://api.exemple.org/sante\nsudo tail -f /var/log/nginx/error.log",
        "Du nom jusqu'aux journaux"),
   t("Les journaux d'accès donnent statut, durée et taille de chaque requête : une hausse des 5xx ou de la latence est souvent "
     "le premier signal d'un incident."),
   tip("Changez une seule chose à la fois et notez ce que vous observez : le diagnostic devient reproductible.")],
  [single("rs-10-1", "Premier contrôle si « le site ne marche pas » ?", ["Le nom se résout-il ?", "Réinstaller le serveur", "Changer de fournisseur", "Supprimer le cache navigateur uniquement"], 0, "On remonte les couches dans l'ordre."),
   cmd("rs-10-2", "Testez si le port 443 de api.exemple.org est joignable avec nc.", ["nc -zv api.exemple.org 443"], "-z teste sans envoyer de données, -v affiche le résultat."),
   single("rs-10-3", "Que montre curl -v ?", ["Le détail de la connexion, de TLS et des en-têtes", "Seulement le corps", "Le DNS uniquement", "Rien de plus"], 0, "Idéal pour voir où ça coince."),
   single("rs-10-4", "Signal précoce d'incident dans les journaux d'accès ?", ["Hausse des 5xx ou de la latence", "Hausse des 200", "Moins de 404", "Aucun"], 0, "À surveiller avec des alertes.")]))

project = {"title": "Mise en production d'un site sous nginx",
  "brief": "Écrivez la configuration nginx d'un site en production : HTTP redirigé, TLS moderne, HSTS, en-têtes de sécurité, aucune fuite de fichiers.",
  "lab": lab("nginx", "Objectif : aucun problème bloquant ni avertissement.",
      "server {\n    listen 80;\n    server_name exemple.org;\n    root /srv/projet;\n    autoindex on;\n}\nserver {\n    listen 443 ssl;\n    server_name exemple.org;\n    ssl_protocols SSLv3 TLSv1 TLSv1.2;\n    root /srv/projet;\n}\n",
      [clean(), nowarn(), has("return 301 https", "HTTP redirigé"), has("Strict-Transport-Security", "HSTS"), has("X-Content-Type-Options", "En-tête nosniff")],
      "Reprenez les labos : redirection 301, TLS 1.2/1.3, HSTS, server_tokens off, autoindex off, refus des fichiers cachés.",
      "server {\n    listen 80;\n    server_name exemple.org;\n    server_tokens off;\n    return 301 https://$host$request_uri;\n}\nserver {\n    listen 443 ssl;\n    server_name exemple.org;\n    server_tokens off;\n    ssl_protocols TLSv1.2 TLSv1.3;\n"
      "    add_header Strict-Transport-Security \"max-age=31536000\" always;\n    add_header X-Content-Type-Options nosniff always;\n    root /srv/publication;\n    location ~ /\\. {\n        deny all;\n    }\n}\n"),
  "rubric": rubric(
    ("Chiffrement", "HTTP ou protocoles obsolètes", "TLS 1.2+", "TLS 1.2/1.3, HSTS, renouvellement automatique vérifié"),
    ("Exposition", "Tout ouvert", "Ports utiles seulement", "Pare-feu en liste blanche, administration via VPN ou adresses fixes"),
    ("Fuites", "Listage, .git servi", "Listage désactivé", "Racine dédiée, fichiers cachés refusés, version masquée"),
    ("Diagnostic", "Aucun journal exploité", "Journaux consultés", "Démarche couche par couche, alertes sur 5xx et latence"),
    ("Coûts", "Ressources publiques et non étiquetées", "Ressources privées", "Étiquettes, alertes de budget, rien d'orphelin"))}

glossary = [
  ("Adresse IP", "Identifiant d'une machine sur un réseau (IPv4, IPv6)."), ("Port", "Numéro identifiant un service sur une machine."),
  ("CIDR", "Notation d'une plage d'adresses (10.0.0.0/24)."), ("NAT", "Traduction d'adresses privées vers une adresse publique."),
  ("DNS", "Système qui traduit les noms en adresses."), ("TTL", "Durée de mise en cache d'une réponse DNS."),
  ("HTTP", "Protocole du web (méthodes, codes, en-têtes)."), ("TLS", "Chiffrement et authentification des connexions."),
  ("Certificat", "Preuve signée qu'une clé appartient à un nom de domaine."), ("HSTS", "En-tête imposant HTTPS au navigateur."),
  ("Reverse proxy", "Serveur frontal qui transmet les requêtes à l'application."), ("Pare-feu", "Filtre des connexions réseau."),
  ("Egress", "Trafic sortant, généralement facturé dans le cloud."), ("Responsabilité partagée", "Répartition de la sécurité entre fournisseur et client."),
]

write_module("reseaux", "Réseaux, serveurs et cloud, la haute mer",
  "Adresses, ports, DNS, HTTP, TLS, reverse proxy, pare-feu, cloud et coûts, et une démarche de diagnostic réseau.",
  ["Comprendre adresses, ports, DNS et HTTP", "Servir un site en HTTPS moderne derrière un reverse proxy",
   "Limiter l'exposition réseau", "Maîtriser les risques et les coûts du cloud", "Diagnostiquer couche par couche"],
  ["Module Terminal Linux"], R, project, glossary)
