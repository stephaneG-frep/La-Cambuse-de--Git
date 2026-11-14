# Sécurité — La Cambuse de Git

## Signaler une vulnérabilité

Ne la décrivez pas dans un ticket public. Utilisez le signalement privé de GitHub (onglet Security → « Report a vulnerability ») ou contactez le mainteneur en privé. Joignez si possible les étapes pour reproduire et la version concernée.

## Modèle de sécurité (résumé)

- **Le téléphone ne lance aucune commande hôte.** Il pilote le compagnon Linux, qui n'exécute que des opérations typées, jamais de shell libre.
- **Compagnon** :
  - écoute par défaut sur 127.0.0.1 seulement ; sur le réseau local, uniquement en TLS, avec une empreinte épinglée ;
  - appairage par code à 6 chiffres (2 minutes, usage unique, 5 essais au maximum) ;
  - jetons hachés et renouvelés, fichiers en 0600, dossier en 0700 ;
  - refuse de tourner en root ;
  - dossiers autorisés confinés (liens symboliques résolus, `..` refusé) ;
  - Git durci : hooks désactivés, `fsmonitor` désactivé ;
  - journal d'audit JSONL.
- **Portées** accordées séparément : `read`, `git-write`, `remote`, `docker` (équivaut à root), `build` (exécute du code du projet), `sync` (progression d'apprentissage uniquement ; jamais de conversations IA, de journal ni de secrets).
- **Mutations** : approbation explicite, avec la commande exacte affichée. Pas de `push --force`. Sauvegarde avant toute opération qui écrase.
- **Secrets** :
  - clés et jetons rangés dans le coffre du système (Keystore Android, libsecret Linux) ;
  - jamais en base, dans les journaux, les rapports, les messages à l'IA ni dans Git ;
  - les commits contenant un secret détecté sont bloqués ;
  - un jeton de forge passe par l'environnement du processus Git et il est masqué dans toutes les sorties.
- **IA** : facultative ; ses réponses sont non fiables (validation de schéma, liste blanche d'opérations, confinement des chemins), et rien ne s'exécute sans approbation.
- **Chaîne d'approvisionnement** : actions CI épinglées par empreinte de commit, fichiers de verrouillage versionnés, SBOM CycloneDX livré, analyse gitleaks en CI.

## Limites connues

- La détection de secrets repose sur des heuristiques : elle réduit le risque, sans le supprimer.
- L'APK livré est signé avec la **clé debug** : il est réservé aux tests.
- L'accès au démon Docker (portée `docker`) équivaut à des droits root sur la machine hôte : accordez-le en connaissance de cause.
