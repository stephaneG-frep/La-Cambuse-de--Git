#!/usr/bin/env python3
"""Module « Kubernetes » : python3 tool/content/kubernetes_module.py"""
from common import *


def deploy(image="ghcr.io/exemple/api:1.4.0", replicas=2, pod_sec=True, sec=True, res=True, probes=True, env="", extra_container=""):
    """Manifeste Deployment ; chaque option retire une bonne pratique."""
    y = ("apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: api\nspec:\n"
         f"  replicas: {replicas}\n  selector:\n    matchLabels:\n      app: api\n  template:\n    metadata:\n      labels:\n        app: api\n    spec:\n")
    if pod_sec:
        y += "      securityContext:\n        runAsNonRoot: true\n        runAsUser: 10001\n"
    y += f"      containers:\n        - name: api\n          image: {image}\n          ports:\n            - containerPort: 8080\n"
    if env:
        y += env
    if res:
        y += "          resources:\n            requests:\n              cpu: 100m\n              memory: 128Mi\n            limits:\n              memory: 256Mi\n"
    if sec:
        y += "          securityContext:\n            allowPrivilegeEscalation: false\n            readOnlyRootFilesystem: true\n"
    y += extra_container
    if probes:
        y += ("          readinessProbe:\n            httpGet:\n              path: /sante\n              port: 8080\n"
              "          livenessProbe:\n            httpGet:\n              path: /sante\n              port: 8080\n")
    return y


SERVICE = "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: api\nspec:\n  selector:\n    app: api\n  ports:\n    - port: 80\n      targetPort: 8080\n"

K = []

K.append(lesson("pourquoi-k8s", "Pourquoi (et quand) Kubernetes ?", 15,
  ["Comprendre ce qu'apporte un orchestrateur", "Savoir quand Kubernetes est disproportionné"],
  [t("Kubernetes fait tourner des conteneurs sur un ensemble de machines (nœuds) : il les place, les redémarre s'ils "
     "tombent, les répartit, les met à jour progressivement et les relie entre eux. Vous décrivez l'état voulu ; il le maintient."),
   t("Ce modèle déclaratif est central : on n'exécute pas « démarre 3 conteneurs », on déclare « je veux 3 répliques » et les "
     "contrôleurs corrigent sans cesse l'écart entre l'état réel et l'état voulu."),
   warn("Kubernetes a un coût d'apprentissage et d'exploitation élevé. Pour une petite application, un serveur avec Docker "
        "Compose ou une plateforme gérée (PaaS) est souvent plus raisonnable."),
   code("kubectl version\nkubectl get nodes\nkubectl get pods -A", "Premiers contacts avec un cluster (kind, minikube ou k3d en local)")],
  [single("k8-1-1", "Que signifie « déclaratif » dans Kubernetes ?", ["On décrit l'état voulu, le système le maintient", "On écrit des scripts impératifs", "On déclare des variables", "On déclare des pare-feu"], 0, "Les contrôleurs réconcilient en continu."),
   single("k8-1-2", "Quand Kubernetes est-il souvent disproportionné ?", ["Pour une petite application sur un seul serveur", "Pour des centaines de services", "Pour une forte disponibilité", "Jamais"], 0, "Compose ou un PaaS suffisent souvent."),
   single("k8-1-3", "Qu'est-ce qu'un nœud ?", ["Une machine qui exécute des pods", "Un conteneur", "Un fichier YAML", "Un namespace"], 0, "Le cluster est un ensemble de nœuds."),
   cmd("k8-1-4", "Listez les nœuds du cluster.", ["kubectl get nodes"], "Affiche leur état (Ready) et leur version.")]))

K.append(lesson("pods", "Pods et kubectl", 20,
  ["Décrire un pod", "Inspecter un pod avec kubectl"],
  [t("Un pod est la plus petite unité déployable : un ou plusieurs conteneurs qui partagent réseau et volumes. On ne crée "
     "presque jamais de pod à la main : un Deployment s'en charge."),
   code("kubectl apply -f pod.yaml\nkubectl get pods -o wide\nkubectl describe pod web\nkubectl logs web\nkubectl exec -it web -- sh", "Créer, lister, détailler, journaux, shell"),
   t("describe montre les événements : ImagePullBackOff (image introuvable), CrashLoopBackOff (le conteneur plante en boucle), "
     "Pending (pas de nœud capable de l'accueillir)."),
   warn("image: nginx (donc latest) ne garantit pas que deux nœuds exécutent la même version : épinglez toujours.")],
  [single("k8-2-1", "Un pod est…", ["Un ou plusieurs conteneurs partageant réseau et volumes", "Un nœud", "Un cluster", "Une image"], 0, "La plus petite unité déployable."),
   single("k8-2-2", "Que signifie CrashLoopBackOff ?", ["Le conteneur plante et redémarre en boucle", "L'image est introuvable", "Pas de nœud disponible", "Tout va bien"], 0, "Regardez kubectl logs --previous."),
   cmd("k8-2-3", "Affichez les journaux du pod web.", ["kubectl logs web"], "--previous montre ceux du conteneur précédent après un plantage."),
   cmd("k8-2-4", "Affichez le détail et les événements du pod web.", ["kubectl describe pod web", "kubectl describe pods web"], "Les événements en bas expliquent souvent le problème.")],
  lab("k8s", "Ce pod utilise une image non épinglée. Fixez sa version.",
      "apiVersion: v1\nkind: Pod\nmetadata:\n  name: web\nspec:\n  containers:\n    - name: web\n      image: nginx\n",
      [no("K8001", "Image épinglée"), valid()], "Utilisez une version précise, ex. nginx:1.27.3.",
      "apiVersion: v1\nkind: Pod\nmetadata:\n  name: web\nspec:\n  containers:\n    - name: web\n      image: nginx:1.27.3\n")))

K.append(lesson("deployments", "Deployments et mises à jour progressives", 22,
  ["Déclarer un Deployment", "Mettre à jour puis revenir en arrière"],
  [t("Un Deployment gère des répliques identiques via un ReplicaSet. Changer l'image déclenche une mise à jour progressive "
     "(rolling update) : les nouveaux pods remplacent les anciens petit à petit, sans interruption."),
   code("kubectl apply -f deployment.yaml\nkubectl rollout status deployment/api\nkubectl rollout history deployment/api\nkubectl rollout undo deployment/api",
        "Appliquer, suivre, historique, retour arrière"),
   t("Une seule réplique signifie une interruption à chaque mise à jour ou panne de nœud : visez au moins deux répliques "
     "pour un service important."),
   tip("Le selector doit correspondre aux labels du template : c'est ainsi que le Deployment retrouve ses pods.")],
  [single("k8-3-1", "Que fait un rolling update ?", ["Remplace les pods progressivement sans interruption", "Supprime tout puis recrée", "Redémarre le cluster", "Change de namespace"], 0, "Paramétrable par maxSurge et maxUnavailable."),
   cmd("k8-3-2", "Annulez la dernière mise à jour du Deployment api.", ["kubectl rollout undo deployment/api", "kubectl rollout undo deploy/api"], "Revient à la révision précédente."),
   single("k8-3-3", "Pourquoi au moins deux répliques ?", ["Tolérer une panne ou une mise à jour sans interruption", "Obligatoire", "Moins de mémoire", "Plus de logs"], 0, "Une réplique unique est un point de défaillance."),
   single("k8-3-4", "Comment le Deployment retrouve-t-il ses pods ?", ["Par son selector et les labels du template", "Par leur nom", "Par leur IP", "Par hasard"], 0, "Les labels sont le lien.")],
  lab("k8s", "Ce Deployment n'a qu'une réplique et une image mobile. Corrigez.",
      deploy(image="ghcr.io/exemple/api:latest", replicas=1),
      [no("K8001", "Image épinglée"), no("K8013", "Au moins deux répliques"), valid()],
      "Passez replicas à 2 et l'image à ghcr.io/exemple/api:1.4.0.",
      deploy())))

K.append(lesson("services", "Services et découverte", 20,
  ["Exposer des pods avec un Service", "Choisir entre ClusterIP, NodePort et LoadBalancer"],
  [t("Les pods sont éphémères et changent d'adresse. Un Service fournit une adresse et un nom DNS stables (api.default.svc) "
     "et répartit le trafic entre les pods qui portent les bons labels."),
   t("ClusterIP (par défaut) : joignable seulement depuis le cluster. NodePort : ouvert sur un port de chaque nœud. "
     "LoadBalancer : demande un répartiteur public au fournisseur cloud (et une facture)."),
   code(SERVICE.replace("---\n", ""), "Service ClusterIP devant les pods app: api"),
   tip("Pour exposer du HTTP, un seul Ingress (ou Gateway) devant des Services ClusterIP vaut mieux qu'un LoadBalancer par service.")],
  [single("k8-4-1", "Type de Service par défaut ?", ["ClusterIP", "NodePort", "LoadBalancer", "ExternalName"], 0, "Accessible uniquement depuis le cluster."),
   single("k8-4-2", "Pourquoi un Service plutôt que l'IP d'un pod ?", ["Les pods changent d'adresse, le Service reste stable", "Les pods n'ont pas d'IP", "Pour le chiffrement", "Obligatoire pour les logs"], 0, "Nom DNS et IP stables."),
   single("k8-4-3", "Inconvénient d'un LoadBalancer par service ?", ["Exposition publique et coût pour chacun", "Aucun", "Pas de DNS", "Plus lent que ClusterIP"], 0, "Un Ingress mutualise l'entrée HTTP."),
   cmd("k8-4-4", "Listez les Services du namespace courant.", ["kubectl get services", "kubectl get svc"], "svc est l'abréviation.")],
  lab("k8s", "Ce Service interne est exposé publiquement par un LoadBalancer. Ramenez-le dans le cluster.",
      "apiVersion: v1\nkind: Service\nmetadata:\n  name: base-interne\nspec:\n  type: LoadBalancer\n  selector:\n    app: base\n  ports:\n    - port: 5432\n",
      [no("K8012", "Service non exposé hors du cluster"), valid()], "Retirez type: LoadBalancer (ClusterIP par défaut).",
      "apiVersion: v1\nkind: Service\nmetadata:\n  name: base-interne\nspec:\n  type: ClusterIP\n  selector:\n    app: base\n  ports:\n    - port: 5432\n")))

K.append(lesson("ingress", "Ingress, TLS et Gateway", 18,
  ["Router le trafic HTTP vers des Services", "Automatiser les certificats"],
  [code("apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  name: site\n  annotations:\n    cert-manager.io/cluster-issuer: letsencrypt\nspec:\n  tls:\n    - hosts: [exemple.org]\n      secretName: site-tls\n  rules:\n    - host: exemple.org\n      http:\n        paths:\n          - path: /\n            pathType: Prefix\n            backend:\n              service:\n                name: api\n                port:\n                  number: 80",
        "Ingress avec TLS géré par cert-manager"),
   t("Un Ingress ne fait rien seul : il faut un contrôleur (ingress-nginx, Traefik…) installé dans le cluster. "
     "L'API Gateway, plus récente, sépare mieux les rôles (équipe plateforme / équipe applicative)."),
   t("cert-manager obtient et renouvelle les certificats Let's Encrypt et les range dans un Secret de type TLS."),
   tip("kubectl describe ingress site montre les règles reconnues et les adresses attribuées.")],
  [single("k8-5-1", "Que faut-il pour qu'un Ingress fonctionne ?", ["Un contrôleur d'Ingress installé", "Rien de plus", "Un LoadBalancer par service", "Un nœud par domaine"], 0, "L'Ingress n'est qu'une description."),
   single("k8-5-2", "Rôle de cert-manager ?", ["Obtenir et renouveler les certificats", "Gérer les nœuds", "Remplacer DNS", "Chiffrer etcd"], 0, "Les certificats sont stockés en Secret TLS."),
   single("k8-5-3", "Vers quoi un Ingress route-t-il le trafic ?", ["Des Services", "Des nœuds", "Des images", "Des namespaces"], 0, "Le Service répartit ensuite vers les pods."),
   single("k8-5-4", "Atout de l'API Gateway ?", ["Meilleure séparation des rôles et plus d'expressivité", "Supprime TLS", "Pas besoin de Services", "Moins sûr"], 0, "Successeur progressif d'Ingress.")]))

K.append(lesson("config-secrets", "ConfigMaps et Secrets", 20,
  ["Sortir la configuration de l'image", "Injecter un secret sans l'écrire dans le manifeste"],
  [t("Une ConfigMap contient de la configuration non sensible ; un Secret, des données sensibles. Les deux s'injectent en "
     "variables d'environnement ou en fichiers montés."),
   code("env:\n  - name: DB_PASSWORD\n    valueFrom:\n      secretKeyRef:\n        name: api-secrets\n        key: db-password", "Lire une variable depuis un Secret"),
   warn("Les Secrets sont seulement encodés en base64, pas chiffrés : un manifeste de Secret versionné dans Git est une fuite. "
        "Créez-les hors Git (kubectl create secret) ou utilisez Sealed Secrets / External Secrets, et activez le chiffrement d'etcd."),
   code("kubectl create secret generic api-secrets --from-literal=db-password=\"$DB_PASSWORD\"", "Créer le Secret depuis une variable locale, sans fichier")],
  [single("k8-6-1", "Un Secret Kubernetes est-il chiffré par défaut ?", ["Non, seulement encodé en base64", "Oui, en AES", "Oui, par Git", "Seulement sur GitHub"], 0, "Le chiffrement au repos d'etcd doit être activé."),
   single("k8-6-2", "Comment injecter un mot de passe dans un conteneur ?", ["valueFrom.secretKeyRef", "value: en clair", "Dans l'image", "Dans le nom du pod"], 0, "Le manifeste ne contient que la référence."),
   single("k8-6-3", "Différence ConfigMap / Secret ?", ["La ConfigMap est pour le non-sensible", "Aucune", "La ConfigMap est chiffrée", "Le Secret est public"], 0, "Et des droits RBAC distincts."),
   cmd("k8-6-4", "Créez le Secret générique api-secrets avec la clé db-password tirée de $DB_PASSWORD.",
       ["kubectl create secret generic api-secrets --from-literal=db-password=\"$DB_PASSWORD\"", "kubectl create secret generic api-secrets --from-literal=db-password=$DB_PASSWORD"],
       "La valeur vient de votre environnement, pas d'un fichier versionné.")],
  lab("k8s", "Le mot de passe de la base est écrit en clair dans le manifeste. Lisez-le depuis un Secret.",
      deploy(env="          env:\n            - name: DB_PASSWORD\n              value: \"motdepasse-prod-42\"\n"),
      [no("K8008", "Plus de secret en clair"), has("secretKeyRef", "Lecture depuis un Secret"), valid()],
      "Remplacez value: par valueFrom: { secretKeyRef: { name: api-secrets, key: db-password } }.",
      deploy(env="          env:\n            - name: DB_PASSWORD\n              valueFrom:\n                secretKeyRef:\n                  name: api-secrets\n                  key: db-password\n"))))

K.append(lesson("ressources", "Ressources : requests et limits", 20,
  ["Réserver ce dont un conteneur a besoin", "Empêcher un conteneur d'affamer le nœud"],
  [t("requests = ce qui est réservé et sert au placement des pods ; limits = le maximum autorisé. Au-delà de sa limite "
     "mémoire, un conteneur est tué (OOMKilled) ; au-delà de sa limite CPU, il est ralenti."),
   code("resources:\n  requests:\n    cpu: 100m\n    memory: 128Mi\n  limits:\n    memory: 256Mi", "100m = un dixième de cœur"),
   t("Sans requests, l'ordonnanceur entasse les pods ; sans limite mémoire, une fuite peut faire tomber tout le nœud."),
   tip("Mesurez la consommation réelle (kubectl top pod) avant de fixer des valeurs, puis ajustez.")],
  [single("k8-7-1", "À quoi servent les requests ?", ["Réserver des ressources et placer les pods", "Limiter au maximum", "Chiffrer", "Exposer"], 0, "L'ordonnanceur les utilise."),
   single("k8-7-2", "Que se passe-t-il au-delà de la limite mémoire ?", ["Le conteneur est tué (OOMKilled)", "Il est ralenti", "Rien", "Il change de nœud"], 0, "La mémoire ne se « ralentit » pas."),
   single("k8-7-3", "Que signifie cpu: 250m ?", ["Un quart de cœur", "250 cœurs", "250 Mo", "250 ms"], 0, "m signifie millicœur : 1000m = un cœur."),
   cmd("k8-7-4", "Affichez la consommation des pods.", ["kubectl top pod", "kubectl top pods"], "Nécessite metrics-server.")],
  lab("k8s", "Ce conteneur n'a ni réservation ni limite. Ajoutez-les.",
      deploy(res=False),
      [no("K8002", "requests et limits définis"), valid()], "Ajoutez resources: requests (cpu, memory) et limits (memory).",
      deploy())))

K.append(lesson("sondes", "Sondes de santé", 18,
  ["Distinguer readiness, liveness et startup", "Éviter d'envoyer du trafic à un pod qui n'est pas prêt"],
  [t("readinessProbe : le pod est-il prêt à recevoir du trafic ? S'il échoue, il est retiré du Service sans être redémarré. "
     "livenessProbe : le processus est-il bloqué ? S'il échoue, le conteneur est redémarré."),
   t("startupProbe laisse le temps à une application lente de démarrer avant que la liveness ne s'en mêle."),
   code("readinessProbe:\n  httpGet:\n    path: /sante\n    port: 8080\n  periodSeconds: 5\nlivenessProbe:\n  httpGet:\n    path: /sante\n    port: 8080\n  failureThreshold: 3", "Deux sondes HTTP"),
   warn("Une liveness qui dépend de la base de données redémarre tous les pods quand la base tombe : gardez-la sur l'état du processus lui-même.")],
  [single("k8-8-1", "Si la readinessProbe échoue…", ["Le pod est retiré du Service, sans redémarrage", "Le pod est supprimé", "Le nœud redémarre", "Rien"], 0, "Il revient dès qu'il est prêt."),
   single("k8-8-2", "Si la livenessProbe échoue…", ["Le conteneur est redémarré", "Le pod est seulement retiré du Service", "Le Service est supprimé", "Rien"], 0, "Pour débloquer un processus figé."),
   single("k8-8-3", "Rôle de la startupProbe ?", ["Laisser démarrer une application lente", "Démarrer le cluster", "Remplacer la readiness", "Créer le pod"], 0, "La liveness attend sa réussite."),
   single("k8-8-4", "Pourquoi une liveness ne doit pas dépendre de la base ?", ["Une panne de base redémarrerait tous les pods inutilement", "C'est plus lent", "C'est interdit", "La base n'a pas d'API"], 0, "Ce serait une panne en cascade.")],
  lab("k8s", "Ce Deployment n'a aucune sonde : du trafic arrive avant que l'application soit prête. Ajoutez-les.",
      deploy(probes=False),
      [no("K8006", "readinessProbe"), no("K8007", "livenessProbe"), valid()], "Ajoutez readinessProbe et livenessProbe HTTP sur /sante, port 8080.",
      deploy())))

K.append(lesson("securite-pods", "Sécurité des pods", 22,
  ["Faire tourner les conteneurs sans privilèges", "Appliquer les Pod Security Standards"],
  [t("Par défaut, un conteneur peut tourner en root et élever ses privilèges. Le securityContext impose : utilisateur non root, "
     "pas d'élévation, système de fichiers en lecture seule, capacités retirées."),
   code("securityContext:\n  runAsNonRoot: true\n  runAsUser: 10001\ncontainers:\n  - securityContext:\n      allowPrivilegeEscalation: false\n      readOnlyRootFilesystem: true\n      capabilities:\n        drop: [ALL]",
        "Profil « restricted »"),
   t("Pod Security Admission applique des niveaux par namespace : privileged, baseline, restricted. Visez restricted pour les applications."),
   warn("privileged: true, hostNetwork, hostPID ou un volume hostPath donnent un accès au nœud lui-même : à réserver aux composants système audités.")],
  [single("k8-9-1", "Que fait runAsNonRoot: true ?", ["Refuse de démarrer un conteneur qui tournerait en root", "Supprime root du nœud", "Chiffre le pod", "Ralentit le pod"], 0, "L'image doit définir un utilisateur non root."),
   single("k8-9-2", "Niveau Pod Security visé pour une application ?", ["restricted", "privileged", "baseline uniquement", "aucun"], 0, "C'est le niveau le plus strict."),
   single("k8-9-3", "Risque de privileged: true ?", ["Accès quasi total au nœud", "Plus de mémoire", "Pas de réseau", "Aucun"], 0, "Une évasion du conteneur devient triviale."),
   single("k8-9-4", "readOnlyRootFilesystem: true…", ["Empêche d'écrire dans le système de fichiers du conteneur", "Empêche de lire les fichiers", "Rend le pod privé", "Supprime les volumes"], 0, "Un attaquant ne peut pas déposer d'outils.")],
  lab("k8s", "Ce conteneur est privilégié et peut tourner en root. Appliquez un profil restreint.",
      deploy(pod_sec=False, sec=False, extra_container="          securityContext:\n            privileged: true\n"),
      [no("K8004", "Plus de conteneur privilégié"), no("K8003", "Non root"), no("K8005", "Pas d'élévation de privilèges"), no("K8011", "Racine en lecture seule"), clean()],
      "Retirez privileged, ajoutez runAsNonRoot au pod, puis allowPrivilegeEscalation: false et readOnlyRootFilesystem: true au conteneur.",
      deploy())))

K.append(lesson("rbac", "RBAC et comptes de service", 18,
  ["Donner à chacun les seuls droits nécessaires", "Comprendre les comptes de service des pods"],
  [t("RBAC : un Role (dans un namespace) ou ClusterRole (tout le cluster) liste des verbes autorisés sur des ressources ; "
     "un RoleBinding l'attribue à un utilisateur, un groupe ou un ServiceAccount."),
   code("apiVersion: rbac.authorization.k8s.io/v1\nkind: Role\nmetadata:\n  name: lecture-pods\n  namespace: equipe-a\nrules:\n  - apiGroups: [\"\"]\n    resources: [pods, pods/log]\n    verbs: [get, list, watch]",
        "Rôle en lecture seule sur les pods d'un namespace"),
   t("Chaque pod reçoit un jeton de ServiceAccount. Une application qui n'appelle pas l'API Kubernetes n'en a pas besoin : "
     "automountServiceAccountToken: false."),
   warn("cluster-admin pour « débloquer » une CI donne à quiconque contrôle la CI les clés de tout le cluster.")],
  [single("k8-10-1", "Différence Role / ClusterRole ?", ["Le Role est limité à un namespace", "Aucune", "Le ClusterRole est en lecture seule", "Le Role est global"], 0, "Le ClusterRole couvre tout le cluster."),
   single("k8-10-2", "Que lie un RoleBinding ?", ["Un rôle à un utilisateur, groupe ou ServiceAccount", "Deux pods", "Un Service à un Ingress", "Un nœud à un namespace"], 0, "C'est l'attribution des droits."),
   cmd("k8-10-3", "Vérifiez si vous pouvez supprimer des pods dans le namespace courant.", ["kubectl auth can-i delete pods"], "Pratique pour tester des droits."),
   single("k8-10-4", "Pod qui n'appelle jamais l'API Kubernetes ?", ["automountServiceAccountToken: false", "Lui donner cluster-admin", "Rien à faire", "Supprimer son namespace"], 0, "Pas de jeton inutile à voler.")]))

K.append(lesson("helm", "Helm et empaquetage", 18,
  ["Comprendre charts, valeurs et releases", "Installer et mettre à jour une application avec Helm"],
  [t("Helm empaquette des manifestes paramétrables (un chart) : values.yaml contient les réglages, chaque installation est "
     "une release versionnée qu'on peut mettre à jour ou annuler."),
   code("helm repo add bitnami https://charts.bitnami.com/bitnami\nhelm install cache bitnami/redis --version 20.6.0 -f valeurs.yaml\nhelm upgrade cache bitnami/redis --version 20.6.1 -f valeurs.yaml\nhelm rollback cache 1\nhelm template . | less",
        "Ajouter un dépôt, installer une version précise, mettre à jour, annuler, prévisualiser"),
   t("helm template rend les manifestes sans rien installer : idéal pour les relire ou les analyser en CI."),
   warn("Épinglez la version du chart (--version) : sinon une mise à jour du dépôt change ce qui est installé.")],
  [single("k8-11-1", "Qu'est-ce qu'un chart Helm ?", ["Un paquet de manifestes paramétrables", "Un nœud", "Une image", "Un namespace"], 0, "Avec un fichier values.yaml."),
   cmd("k8-11-2", "Revenez à la révision 1 de la release cache.", ["helm rollback cache 1"], "Helm garde l'historique des révisions."),
   single("k8-11-3", "Intérêt de helm template ?", ["Voir les manifestes produits sans rien installer", "Créer un cluster", "Chiffrer les valeurs", "Accélérer kubectl"], 0, "Relecture et analyse en CI."),
   single("k8-11-4", "Pourquoi --version à l'installation ?", ["Installer une version précise et reproductible", "Afficher la version de Helm", "Obligatoire", "Pour le DNS"], 0, "Comme pour les images.")]))

project = {"title": "Déployer une API proprement sur Kubernetes",
  "brief": "Rédigez le Deployment et le Service d'une API : image épinglée, répliques, ressources, sondes, secret externe, profil de sécurité restreint, exposition interne.",
  "lab": lab("k8s", "Objectif : aucun problème bloquant ni avertissement, sondes et secret externe.",
      deploy(image="ghcr.io/exemple/api", replicas=1, pod_sec=False, sec=False, res=False, probes=False,
             env="          env:\n            - name: API_KEY\n              value: \"cle-prod-123456\"\n",
             extra_container="          securityContext:\n            privileged: true\n")
      + SERVICE.replace("spec:\n  selector", "spec:\n  type: LoadBalancer\n  selector"),
      [clean(), nowarn(), has("readinessProbe", "Sonde de disponibilité"), has("secretKeyRef", "Secret externe"), no("K8012", "Service interne")],
      "Reprenez chaque labo du module : version, répliques, ressources, sondes, secretKeyRef, securityContext, ClusterIP.",
      deploy(env="          env:\n            - name: API_KEY\n              valueFrom:\n                secretKeyRef:\n                  name: api-secrets\n                  key: api-key\n") + SERVICE),
  "rubric": rubric(
    ("Reproductibilité", "Images latest", "Images épinglées", "Images épinglées par digest, charts versionnés"),
    ("Disponibilité", "Une réplique, sans sondes", "Répliques et sondes", "Répliques, sondes adaptées, PodDisruptionBudget, mise à jour progressive"),
    ("Ressources", "Aucune limite", "requests et limits", "Valeurs mesurées et revues, quotas par namespace"),
    ("Sécurité", "Privilégié, root", "Non root, sans élévation", "Profil restricted, capacités retirées, RBAC minimal, pas de jeton inutile"),
    ("Secrets et exposition", "Secrets en clair, LoadBalancer", "secretKeyRef, ClusterIP", "Secrets externes chiffrés, Ingress TLS unique"))}

glossary = [
  ("Cluster", "Ensemble de nœuds pilotés par Kubernetes."), ("Nœud", "Machine qui exécute des pods."),
  ("Pod", "Un ou plusieurs conteneurs partageant réseau et volumes."), ("Deployment", "Gère des répliques et leurs mises à jour."),
  ("Service", "Adresse et nom stables devant un ensemble de pods."), ("Ingress", "Règles de routage HTTP vers des Services."),
  ("ConfigMap", "Configuration non sensible injectée dans les pods."), ("Secret", "Donnée sensible, encodée en base64 (non chiffrée par défaut)."),
  ("requests / limits", "Ressources réservées / maximum autorisé."), ("Sonde", "Vérification de santé (readiness, liveness, startup)."),
  ("securityContext", "Réglages de sécurité d'un pod ou conteneur."), ("RBAC", "Contrôle d'accès par rôles."),
  ("ServiceAccount", "Identité d'un pod auprès de l'API Kubernetes."), ("Helm", "Gestionnaire de paquets (charts) pour Kubernetes."),
]

write_module("kubernetes", "Kubernetes, l'armada",
  "Pods, Deployments, Services, Ingress, configuration et secrets, ressources, sondes, sécurité des pods, RBAC et Helm.",
  ["Décrire et déployer une application de façon déclarative", "Exposer des services proprement",
   "Garantir disponibilité et maîtrise des ressources", "Appliquer le moindre privilège (pods, RBAC, secrets)"],
  ["Module Docker Compose", "Module Réseaux"], K, project, glossary)
