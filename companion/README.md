# cambuse-companion

Compagnon Linux de La Cambuse de Git. Il expose une **API locale versionnée** (`/v1`) qui permet à l'application (Linux ou Android) de demander des opérations Git **typées** sur des dossiers explicitement autorisés. L'application n'exécute jamais de commande hôte elle-même.

## Construction et lancement

```bash
dart compile exe companion/bin/cambuse_companion.dart -o build/companion/cambuse-companion
build/companion/cambuse-companion serve --root ~/Projets          # 127.0.0.1:47820 uniquement
build/companion/cambuse-companion pair --scopes read,git-write    # code à 6 chiffres, 2 min, usage unique
build/companion/cambuse-companion devices | revoke ID | audit
```

- `--lan` ajoute une écoute réseau local **en TLS uniquement** (certificat auto-signé généré par `openssl`, empreinte SHA-256 affichée par `pair` et épinglée par l'application).
- Depuis un téléphone branché en USB, sans rien exposer au réseau : `adb reverse tcp:47820 tcp:47820`, puis l'adresse `http://127.0.0.1:47820` dans l'application.
- Service utilisateur : voir `systemd/cambuse-companion.service` (modèle, à installer manuellement).

## Sécurité

| Mesure | Détail |
|---|---|
| Écoute | 127.0.0.1 par défaut ; réseau local seulement en TLS (`--lan`) |
| Appairage | code à 6 chiffres généré sur l'hôte (jeton administrateur local), 2 min, usage unique, 5 essais max |
| Jetons | accès 15 min (mémoire), rafraîchissement avec rotation, stockés hachés (SHA-256), révocables |
| Portées | `read` (par défaut), `git-write` et `remote` (push/pull) accordées explicitement sur l'hôte |
| Réseau | push sans `--force`, pull `--ff-only`, HTTPS vers hôtes autorisés (`--remote-host`), jeton transmis par opération via l'environnement, helpers d'identifiants désactivés, secrets de l'historique envoyé bloquants |
| Opérations | liste blanche typée : lecture `system.info`, `project.list/detect/audit`, `git.status/log/diff/branches`, `backup.list` ; écriture `project.backup`, `git.init/add/commit/branch.create/switch/restore`, `gitignore.update`, `backup.restore` ; aucun shell |
| Secrets | `git.add` et `git.commit` (contenu indexé, re-vérifié à l'exécution) bloqués si un secret probable est détecté ; valeurs jamais renvoyées |
| Sauvegardes | automatique avant `git.restore` ; restauration toujours dans un nouveau dossier, jamais par écrasement |
| Consentement | toute opération mutante attend une approbation explicite (`/approve`) ; refus possible |
| Chemins | confinés aux `--root`, liens symboliques résolus, `..` et `.git` refusés ; ajout global ou de dossier refusé |
| Dépôts piégés | `core.hooksPath=/dev/null`, `core.fsmonitor=false`, pas de diff externe ni de textconv, `--no-verify` ; opérations mutantes refusées si `.git/config` déclare filtres, pagers, alias, etc. |
| Exécution | `Process.start` sans shell, environnement minimal, délai (30 s), sortie plafonnée (1 Mo), annulation, une opération à la fois |
| Fichiers | dossier de données 0700, fichiers 0600, écriture atomique ; journal d'audit en ajout seul, sans secrets |
| Privilèges | refuse de démarrer en root |

## Limites connues

- Les filtres définis dans `.gitattributes` avec un pilote déclaré **hors** de `.git/config` (configuration globale de l'utilisateur) ne sont pas détectés : n'autorisez que des dossiers de confiance.
- L'opérateur de l'hôte reste maître : quiconque a accès au compte Linux peut lire `admin.token`.
