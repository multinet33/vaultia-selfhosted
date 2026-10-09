# Installer Vaultia avec Portainer

Guide complet, de zéro à un Vaultia en service sur votre réseau local, avec une pile (*stack*)
Portainer construite depuis ce dépôt. Équivalent en ligne de commande : [docker.md](docker.md).

> **Pré-version (bêta, avant 1.0)** : Vaultia `0.1.0-rc.19`. Faites des sauvegardes.

Dans tout ce guide, **`192.168.1.100` est un exemple** : remplacez-le par l'adresse IPv4 privée
de **votre** serveur. Vaultia n'a aucune adresse par défaut de ce genre.

## 1. Prérequis

| Besoin | Détail |
| --- | --- |
| Machine | Linux `amd64` ou `arm64` (l'image existe pour les deux) |
| Docker | Docker Engine 24 ou plus récent, avec Compose v2 |
| Portainer | Portainer (CE ou BE) qui gère ce Docker, avec l'accès aux *Stacks* |
| Adresse du serveur | une adresse IPv4 **privée et stable** (réservation DHCP sur la box, ou adresse fixe), par exemple `192.168.1.100` |
| Disque | au moins **4 Gio libres** : ≈ 2,2 Go occupés avant vos données (image Vaultia 1,7 Go, PostgreSQL 0,3 Go, modèles de vision ≈ 230 Mio), puis vos photos et documents |
| Mémoire | 2 Gio conseillés (Vaultia ≈ 260 Mio au repos, ≈ 530 Mio pendant une analyse d'image) |
| Internet | au premier démarrage (images et les deux modèles de vision, ≈ 1 Go) ; ensuite facultatif |
| Un terminal sur le serveur | pour générer les secrets (ou sur n'importe quel poste avec `openssl`) et pour les sauvegardes |

L'adresse doit rester la même : elle est inscrite dans la configuration (`BETTER_AUTH_URL`,
`VAULTIA_BIND_ADDRESS`). Si elle change, Vaultia ne démarre plus sur l'ancienne.

## 2. Générer les deux secrets (avant d'ouvrir Portainer)

Sur le serveur ou sur votre poste :

    openssl rand -hex 24         # → POSTGRES_PASSWORD
    openssl rand -base64 32      # → BETTER_AUTH_SECRET

| Valeur | À quoi elle sert |
| --- | --- |
| `POSTGRES_PASSWORD` | mot de passe de la base PostgreSQL de Vaultia. Il est fixé **à la création de la base** : le changer ensuite empêche Vaultia de s'y connecter |
| `BETTER_AUTH_SECRET` | clé qui signe les sessions de connexion et les liens de partage. La changer déconnecte tout le monde et invalide les liens de partage |

Ces deux valeurs :

- sont **secrètes** : ne les publiez nulle part (ni capture d'écran, ni dépôt Git, ni forum) ;
- doivent être **conservées** dans un gestionnaire de mots de passe : elles sont nécessaires
  pour restaurer une sauvegarde et pour les sauvegardes elles-mêmes (§ 12) ;
- ne doivent **jamais être régénérées** lors d'une mise à jour : on garde les mêmes pour toute la
  vie de l'installation.

## 3. Créer la pile

Dans Portainer : **Stacks › Add stack**.

| Champ | Valeur |
| --- | --- |
| Name | `vaultia` (minuscules ; ce nom préfixe les volumes, ne le changez plus ensuite) |
| Build method | **Repository** |
| Authentication | **désactivée** (dépôt public) |
| Repository URL | `https://github.com/multinet33/vaultia-selfhosted.git` |
| Repository reference | `refs/heads/main` |
| Compose path | `compose.yaml` |
| GitOps updates | **désactivées** : les mises à jour restent une action explicite de votre part (§ 11) |

HTTPS local avec Caddy (facultatif) : Compose path `compose.portainer-https.yaml` et quelques
variables de plus, voir le § 13. Ce choix se fait à la création de la pile ; pour une pile
existante, § 13.2.

La pile tire l'image **épinglée** dans `compose.yaml`
(`ghcr.io/multinet33/vaultia:0.1.0-rc.19@sha256:108c89eb…`) : aucune construction sur le serveur,
aucun `latest`.

## 4. Variables d'environnement

Dans la section **Environment variables** de la pile, ajoutez les variables ci-dessous (bouton
*Add an environment variable*, ou *Advanced mode* pour coller des lignes `NOM=valeur` selon votre
version de Portainer). Le fichier `.env` du dépôt n'est **pas** utilisé par Portainer : c'est
cette liste qui fait foi.

### Exemple complet pour le réseau local (à adapter)

    POSTGRES_USER=vaultia
    POSTGRES_DB=vaultia
    POSTGRES_PASSWORD=<valeur générée par openssl rand -hex 24>

    BETTER_AUTH_SECRET=<valeur générée par openssl rand -base64 32>
    BETTER_AUTH_URL=http://192.168.1.100:6080

    VAULTIA_SIGNUP_POLICY=first-user

    VAULTIA_BIND_ADDRESS=192.168.1.100
    VAULTIA_PORT=6080

    VAULTIA_SUBNET=172.30.83.0/24

`192.168.1.100` : **exemple**, à remplacer par l'adresse de votre serveur.

### Les trois valeurs qui doivent concorder

    BETTER_AUTH_URL=http://IP_DU_SERVEUR:6080
    VAULTIA_BIND_ADDRESS=IP_DU_SERVEUR
    VAULTIA_PORT=6080

- `BETTER_AUTH_URL` est l'adresse **exacte** tapée dans le navigateur (schéma, adresse, port). Si
  elle diffère de l'adresse réellement utilisée, les formulaires (connexion comprise) sont
  refusés par le contrôle d'origine.
- `VAULTIA_BIND_ADDRESS` est l'adresse de la machine sur laquelle Docker publie Vaultia. Elle doit
  appartenir au serveur, sinon le conteneur ne démarre pas (`cannot assign requested address`).
- `VAULTIA_PORT` est le port publié ; il doit être celui écrit dans `BETTER_AUTH_URL`.

### Pourquoi le port 6080

Ces guides utilisent **6080**. N'importe quel port libre fonctionne pour Docker, mais les
navigateurs refusent certains ports réservés à d'autres protocoles. C'est le cas de **6000** :
Docker le publie sans erreur, mais Chrome, Edge et les autres navigateurs Chromium affichent
`ERR_UNSAFE_PORT` et n'ouvrent pas la page. N'utilisez pas 6000 pour Vaultia.

### Référence : toutes les variables de la distribution

Obligatoires :

| Variable | Rôle | Valeur par défaut | À modifier ? |
| --- | --- | --- | --- |
| `POSTGRES_PASSWORD` | mot de passe de la base | aucune (Portainer refuse de déployer sans elle) | **oui** : secret généré (§ 2) |
| `BETTER_AUTH_SECRET` | signature des sessions et des liens de partage ; ≥ 32 caractères | aucune | **oui** : secret généré (§ 2) |
| `BETTER_AUTH_URL` | adresse exacte ouverte dans le navigateur ; `http://` accepté seulement pour `localhost` et une IPv4 privée, sinon `https://` (§ 9) | aucune | **oui** |

Installation standard (recommandées, avec les valeurs ci-dessus) :

| Variable | Rôle | Valeur par défaut | À modifier ? |
| --- | --- | --- | --- |
| `POSTGRES_USER` | utilisateur PostgreSQL | `vaultia` | non ; jamais après l'installation |
| `POSTGRES_DB` | nom de la base | `vaultia` | non ; jamais après l'installation |
| `VAULTIA_SIGNUP_POLICY` | qui peut créer un compte : `first-user`, `invite`, `open` (§ 8) | `first-user` | non, sauf décision délibérée |
| `VAULTIA_BIND_ADDRESS` | adresse de l'hôte où Vaultia est publié | `127.0.0.1` (le serveur lui-même seulement) | **oui** : l'IPv4 privée du serveur |
| `VAULTIA_PORT` | port publié | `3000` | **oui** : `6080` dans ce guide |
| `VAULTIA_SUBNET` | sous-réseau interne des conteneurs | `172.30.83.0/24` | seulement s'il entre en conflit avec un réseau existant |

Facultatives, à **laisser absentes** pour une installation standard :

| Variable | Rôle | Valeur par défaut |
| --- | --- | --- |
| `TRUSTED_PROXIES` | adresse(s) du reverse proxy, derrière HTTPS ([reverse-proxy.md](reverse-proxy.md)) | vide |
| `HSTS_MAX_AGE` | en-tête HSTS, en secondes (HTTPS seulement) | vide (aucun) |
| `VAULTIA_IMAGE` | autre image que celle épinglée (tests, ou canal `…:rc` / `…:stable` suivi par Watchtower : [update.md](update.md#mises-à-jour-automatiques-watchtower-facultatif)) | image épinglée de `compose.yaml` |
| `INTELLIGENCE_PROVIDERS` | moteurs d'analyse installés | vision locale complète, recherche par le sens et `open-facts` (Internet, seulement pour un Espace en mode « externe ») ; voir [vision.md](vision.md) |
| `COMPOSE_PROFILES`, `WEB_PRODUCT_SEARCH_*`, `SEARXNG_SECRET` | recherche Web de codes produit (facultative) | désactivée ; `COMPOSE_PROFILES=web-search` démarre SearXNG dans la pile ; voir [web-product-search.md](web-product-search.md) |
| `INTELLIGENCE_MODELS_PROVISION` | installation automatique des modèles de vision : `auto` ou `off` | `auto` |
| `INTELLIGENCE_CONTACT` | contact envoyé aux bases produit ouvertes (seulement avec `open-facts`) | vide |
| `MEDIA_MAX_UPLOAD_BYTES` | taille maximale d'un fichier envoyé (1000 à 50000000 octets) | 10000000 |
| `NOTIFICATIONS_CRON_SECRET` | active la route de rafraîchissement planifié des notifications | vide (désactivée) |
| `WEBHOOK_ALLOW_PRIVATE_NETWORKS` | autorise les webhooks vers le réseau local | vide (refusé) |
| `WEBHOOK_SECRET_KEY` | clé des secrets de webhooks (≥ 32 caractères) | dérivée de `BETTER_AUTH_SECRET` |

Détail de chaque variable : [configuration.md](configuration.md).

## 5. Déployer

Cliquez sur **Deploy the stack**. Portainer :

1. récupère `compose.yaml` depuis le dépôt ;
2. tire les images (`postgres:18-alpine`, puis l'image Vaultia épinglée, ≈ 610 Mio compressés) ;
3. crée le réseau `vaultia_vaultia` et les trois volumes `vaultia_postgres-data`,
   `vaultia_media`, `vaultia_models` (préfixe = nom de la pile) ;
4. démarre **PostgreSQL**, qui crée la base au premier démarrage, et attend qu'il soit sain ;
5. démarre **Vaultia**, qui contrôle sa configuration, applique les **migrations** de la base,
   puis démarre le serveur web ;
6. en parallèle, Vaultia installe les **modèles de vision** (SigLIP 2 90 Mio, E5 130 Mio) dans le volume `models`, vérifié
   par taille et SHA-256. L'application est utilisable avant la fin de cette installation ;
7. Docker exécute ensuite le **contrôle de santé** de l'image (toutes les 30 s) : le conteneur passe
   à *healthy*.

Le premier déploiement prend d'une à quelques minutes, selon votre connexion.

## 6. Si le déploiement échoue

| Message | Cause |
| --- | --- |
| `required variable … is missing a value` | une variable obligatoire est absente ou vide (§ 4) |
| `cannot assign requested address` | `VAULTIA_BIND_ADDRESS` n'est pas une adresse du serveur |
| `address already in use` / `port is already allocated` | `VAULTIA_PORT` est déjà utilisé : choisissez-en un autre, et reportez-le dans `BETTER_AUTH_URL` |
| `Pool overlaps with other one on this address space` | `VAULTIA_SUBNET` est déjà utilisé : choisissez un autre `/24` privé (ex. `172.30.84.0/24`) |

Autres cas : [troubleshooting.md](troubleshooting.md).

## 7. Vérifier dans Portainer

**Containers** (filtrez sur la pile) :

| Conteneur | État attendu |
| --- | --- |
| `vaultia-postgres-1` | *running*, *healthy* |
| `vaultia-vaultia-1` | *running*, *healthy* (après le premier contrôle de santé, ≈ 30 s) |

**Logs** du conteneur `vaultia-vaultia-1` (icône *Logs*), messages attendus :

| Message | Sens |
| --- | --- |
| `[config] configuration valide` | la configuration est acceptée |
| `[config] BETTER_AUTH_URL en http sur une adresse privée : usage sur le réseau local uniquement …` | rappel normal en HTTP sur le réseau local (§ 9) |
| `[config] TRUSTED_PROXIES n'est pas défini …` | avertissement normal sans reverse proxy ; à renseigner seulement derrière un proxy HTTPS |
| `All migrations have been successfully applied.` | premier démarrage : base créée |
| `No pending migrations to apply.` | démarrages suivants : base à jour |
| `[vaultia] démarrage de Vaultia 0.1.0` | le serveur web démarre |
| `[vaultia][models] … installé et vérifié` puis `… Vaultia Vision prête` | premier démarrage : modèle de vision installé |
| `[vaultia][models] … déjà présent et intègre` | démarrages suivants : rien n'est retéléchargé |

**Santé** : ouvrez `http://192.168.1.100:6080/api/health` (votre adresse). Réponse attendue :

    {"status":"ok","database":"up","vision":"ready"}

`"vision":"provisioning"` : le modèle s'installe encore ; `"failed"` : échec du téléchargement,
nouvel essai automatique (vérifier l'accès Internet du serveur).

**Vision** : sur le conteneur `vaultia-vaultia-1`, ouvrez **Console** (*Exec*, commande
`/bin/sh`, **Connect**), puis tapez :

    vaultia vision-status

La dernière ligne doit être `Vaultia Vision: READY` (modèle intègre, moteurs locaux prêts,
inférence réelle réussie).

## 8. Premier accès

Ouvrez **`http://192.168.1.100:6080`** (votre adresse) depuis un appareil du réseau local.

Avec `VAULTIA_SIGNUP_POLICY=first-user` :

- le **premier** compte créé est libre : créez-le tout de suite, il devient l'administrateur de
  son Espace ;
- ensuite l'inscription libre est **fermée** : les autres personnes sont invitées depuis
  *Réglages › Membres* et créent leur compte depuis leur lien d'invitation, avec l'adresse e-mail
  invitée ;
- `invite` ferme l'inscription dès le départ ; `open` l'ouvre à tous — à ne choisir que
  délibérément ([configuration.md § Comptes](configuration.md#comptes)).

Pour la reconnaissance d'objets en photo : *Réglages › Vaultia Vision*, mode **Locale** (désactivé
par défaut dans chaque Espace).

## 9. HTTP sur le réseau local : ce qu'il faut savoir

Règles du produit pour `BETTER_AUTH_URL` :

| Adresse | Accepté ? |
| --- | --- |
| `http://localhost:…`, `http://127.0.0.1:…` | oui |
| `http://` + IPv4 privée : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | oui, **réseau local uniquement** |
| `http://` + nom d'hôte (`http://vaultia.lan`) ou adresse publique | **non** : Vaultia refuse de démarrer |
| `https://…` | oui, partout (recommandé) |

En HTTP sur le réseau local :

- **rien n'est chiffré** : mots de passe et données circulent en clair sur votre réseau ;
- les fonctions du navigateur qui exigent un *contexte sécurisé* sont **indisponibles** : la
  **caméra du scanner** de codes-barres et le **mode hors ligne** (la saisie manuelle d'un code et
  l'analyse d'une photo envoyée restent possibles) ;
- les cookies de session ne sont pas marqués `Secure` ;
- ne rendez **jamais** ce port joignable depuis Internet (aucune redirection de port sur la box).

**HTTPS est recommandé** pour toutes les fonctions et obligatoire pour tout accès hors du réseau
local : [reverse-proxy.md](reverse-proxy.md).

## 10. Persistance

`compose.yaml` définit trois volumes nommés (préfixés par le nom de la pile) :

| Volume | Contenu | Si on le supprime |
| --- | --- | --- |
| `vaultia_postgres-data` | la base PostgreSQL : tout l'inventaire | **perte de toutes les données** (sauf sauvegarde) |
| `vaultia_media` | photos, documents, fichiers | **perte de tous les fichiers** (sauf sauvegarde) |
| `vaultia_models` | modèle de la vision locale | aucune donnée perdue : il est retéléchargé au démarrage suivant |

Arrêter, redémarrer, mettre à jour ou supprimer la pile **sans** cocher la suppression des volumes
les conserve. Ne supprimez jamais ces volumes (menu *Volumes*, ou option de suppression des
volumes) sans une sauvegarde vérifiée. Détail : [storage.md](storage.md).

## 11. Mettre à jour

1. **Sauvegarde ALL d'abord** (§ 12), et vérifiez-la.
2. Lisez les notes de la nouvelle version : [update.md](update.md).
3. Dans Portainer, ouvrez la pile, puis **Pull and redeploy** : Portainer récupère la dernière
   version de `compose.yaml` (nouvelle image épinglée) ; activez **Re-pull image** si l'option est
   proposée.
4. **Gardez toutes les variables d'environnement telles quelles**, secrets compris : ne les
   régénérez jamais.
5. Au redémarrage, Vaultia applique seul les migrations de la base ; vérifiez ensuite comme au
   § 7 (santé, logs, `vaultia vision-status`).

Les trois volumes sont conservés. Ne supprimez **jamais** les volumes pour « repartir propre » :
l'équivalent de `docker compose down -v` efface la base et les fichiers. Limites du retour arrière
et détail des versions : [update.md](update.md).

**Mises à jour automatiques (facultatif)** : avec la variable de pile
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc` (candidats) ou, une fois publié,
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable` (versions stables), sans modifier
`compose.yaml`, et un Watchtower dans une autre pile, Vaultia suit seul le canal choisi, migrations
comprises, sans sauvegarde préalable. Moins prudent que la procédure ci-dessus : lire d'abord
[update.md § Mises à jour automatiques](update.md#mises-à-jour-automatiques-watchtower-facultatif).

## 12. Sauvegarde (Backup ALL)

La sauvegarde officielle est le script `scripts/backup.sh` de ce dépôt : base PostgreSQL complète
(`pg_dump`) + tous les fichiers, vérifiés par `storage-verify`, avec empreintes SHA-256 et
`MANIFEST`. Vaultia est arrêté quelques secondes pendant la copie. Les modèles de vision ne sont pas
sauvegardés (retéléchargeables).

Il se lance depuis un terminal sur le serveur, à partir d'un clone de ce dépôt qui pilote **la
pile Portainer** :

    git clone https://github.com/multinet33/vaultia-selfhosted.git ~/vaultia-admin
    cd ~/vaultia-admin
    nano .env              # mêmes variables que la pile, une par ligne : NOM=valeur
    chmod 600 .env
    COMPOSE="docker compose -p vaultia" ./scripts/backup.sh

- `-p vaultia` : le **nom de votre pile** Portainer.
- Le `.env` doit contenir **exactement les mêmes variables et valeurs** que la pile (§ 4). Avec des
  valeurs différentes, le script redémarrerait Vaultia avec une autre configuration.
- La sauvegarde est écrite dans `~/vaultia-admin/backups/vaultia-<date>/` ; vérifiez-la :

      cd backups/vaultia-<date> && sha256sum -c SHA256SUMS && cat MANIFEST

  (`storage_verify=ok` attendu). Copiez-la **hors du serveur**, et conservez les deux secrets à
  part.

Vérification, restauration et fréquence : [backup-restore.md](backup-restore.md). Une restauration
se fait sur une installation **neuve** (volumes vides), selon cette procédure uniquement.

Cette procédure (pile lancée sans `.env`, sauvegarde par un clone avec les mêmes valeurs et
`-p <pile>`) a été vérifiée : sauvegarde complète, conteneurs de la pile non recréés. Pile en
HTTPS (`compose.portainer-https.yaml`) : ajoutez `-f compose.portainer-https.yaml` (§ 13.5).

## 13. HTTPS local avec Portainer (Caddy)

HTTPS sur votre réseau local, sans domaine Internet : Caddy et sa propre autorité de certification
locale se placent devant Vaultia. Principe, DNS local, installation du certificat sur les
appareils : [https.md](https.md). Cette section ne décrit que la partie Portainer.

> **Ne mettez pas `COMPOSE_FILE` dans les variables de la pile.** C'est la méthode de la ligne de
> commande (`.env`) ; Portainer l'ignore. Il déploie une pile Git avec
> `docker compose -f <Compose path> --env-file stack.env --project-name <pile> up -d`, et un `-f`
> explicite fait ignorer `COMPOSE_FILE` : la pile garde postgres + vaultia en HTTP, sans Caddy.
> Le champ *Additional paths* ne convient pas non plus : la surcouche monte `./https.Caddyfile`,
> que Docker chercherait sur l'hôte dans le dossier interne de Portainer (`/data/compose/<n>/`), où
> il n'existe pas.

Pour Portainer, le dépôt fournit donc un **fichier autonome**, `compose.portainer-https.yaml` :
PostgreSQL, Vaultia et Caddy, Caddyfile embarqué, sans `COMPOSE_FILE`. Il est identique à la fusion
`compose.yaml` + `compose.https.yaml` (mêmes services, mêmes volumes, même réseau ; vérifié par la
CI à chaque modification) : **seul le Compose path change**.

Vérifié avec Portainer CE 2.21.5 (pile *Repository*) : installation, migration d'une pile HTTP
existante, *Pull and redeploy*, sauvegarde, retour en HTTP puis de nouveau en HTTPS, sans perte de
données ni changement d'autorité.

### 13.1 Nouvelle installation en HTTPS

Préparez d'abord le nom et le DNS local ([https.md § 1 et 2](https.md#1-choisir-le-nom)), puis
**Stacks › Add stack** comme au § 3, avec un seul champ différent :

| Champ | Valeur |
| --- | --- |
| Name | `vaultia` |
| Build method | **Repository** |
| Repository URL | `https://github.com/multinet33/vaultia-selfhosted.git` |
| Repository reference | `refs/heads/main` |
| Compose path | **`compose.portainer-https.yaml`** |
| Additional paths | aucun |
| GitOps updates | désactivées |

Variables d'environnement (exemple : `192.168.1.100` est l'adresse de **votre** serveur) :

    POSTGRES_USER=vaultia
    POSTGRES_DB=vaultia
    POSTGRES_PASSWORD=<valeur générée par openssl rand -hex 24>

    BETTER_AUTH_SECRET=<valeur générée par openssl rand -base64 32>
    BETTER_AUTH_URL=https://vaultia.home.arpa

    VAULTIA_SIGNUP_POLICY=first-user
    VAULTIA_SUBNET=172.30.83.0/24

    VAULTIA_BIND_ADDRESS=192.168.1.100
    VAULTIA_DOMAIN=vaultia.home.arpa
    TRUSTED_PROXIES=172.30.83.10

- `VAULTIA_DOMAIN` et l'hôte de `BETTER_AUTH_URL` sont **le même nom**.
- `VAULTIA_BIND_ADDRESS` : l'adresse du serveur où Caddy publie le port 443.
- `TRUSTED_PROXIES=172.30.83.10` : l'adresse fixe de Caddy dans le réseau interne, et rien d'autre.
- Port 443 déjà pris sur le serveur : `CADDY_HTTPS_PORT=8443` et
  `BETTER_AUTH_URL=https://vaultia.home.arpa:8443`.
- `VAULTIA_PORT` est sans effet dans ce mode (Vaultia n'est publié que par Caddy) ; `COMPOSE_FILE`
  n'est **pas** nécessaire.
- Les variables facultatives du § 4 (`VAULTIA_IMAGE`, `INTELLIGENCE_…`, `WEBHOOK_…`…) s'appliquent à
  l'identique.

**Deploy the stack**, puis vérifiez :

| Conteneur | État attendu |
| --- | --- |
| `vaultia-postgres-1` | *healthy*, aucun port publié |
| `vaultia-vaultia-1` | *healthy*, **aucun port publié** |
| `vaultia-caddy-1` | *running*, `192.168.1.100:443→443` seulement (les ports 80, 2019 et 443/udp affichés sans adresse sont seulement *exposés* par l'image, pas publiés) |

Récupérez ensuite le certificat racine public (§ 13.6), installez-le sur chaque appareil
([https.md § 6](https.md#6-installer-lautorité-sur-chaque-appareil)) et ouvrez
`https://vaultia.home.arpa`.

### 13.2 Passer une pile HTTP existante en HTTPS

Portainer ne permet pas de modifier le Compose path d'une pile Git après sa création : on
**supprime la pile** (pas ses volumes) puis on la **recrée sous le même nom** avec l'autre fichier.
Les volumes d'une pile s'appellent `<nom de la pile>_postgres-data`, `<nom>_media`,
`<nom>_models` : recréée sous le même nom, la pile retrouve exactement les mêmes. Supprimer une pile
Compose dans Portainer arrête et retire ses conteneurs et son réseau, pas ses volumes nommés :
Portainer exécute l'équivalent de `docker compose down --remove-orphans`, sans `-v` (vérifié avec
Portainer CE 2.21.5 : volumes intacts, données retrouvées).

1. **Sauvegarde ALL** (§ 12), vérifiée, copiée hors du serveur.
2. **Relevez les variables** de la pile : ouvrez-la, section *Environment variables*, *Advanced
   mode*, copiez tout dans votre gestionnaire de mots de passe (secrets compris). Notez aussi le
   **nom exact** de la pile (ici `vaultia`).
3. Préparez le DNS local ([https.md § 2](https.md#2-configurer-le-dns-local)).
4. **Stacks › `vaultia` › Delete this stack**. Vaultia est indisponible jusqu'à l'étape 6.
5. **Volumes** : vérifiez que `vaultia_postgres-data`, `vaultia_media` et `vaultia_models` sont
   toujours là. N'en supprimez **aucun**.
6. **Stacks › Add stack** : même **Name** (`vaultia`, à l'identique), Build method *Repository*,
   même dépôt, Compose path **`compose.portainer-https.yaml`**. Collez les variables relevées, puis
   modifiez-les :

       BETTER_AUTH_URL=https://vaultia.home.arpa          (était http://192.168.1.100:6080)
       VAULTIA_DOMAIN=vaultia.home.arpa                   (nouvelle)
       TRUSTED_PROXIES=172.30.83.10                       (nouvelle ou modifiée)
       VAULTIA_BIND_ADDRESS=192.168.1.100                 (inchangée)

   `POSTGRES_PASSWORD`, `BETTER_AUTH_SECRET`, `POSTGRES_USER`, `POSTGRES_DB` et `VAULTIA_SUBNET`
   restent **strictement identiques**. Supprimez `COMPOSE_FILE` si vous l'aviez ajoutée ;
   `VAULTIA_PORT` peut rester (sans effet).
7. **Deploy the stack**. Vérifiez comme au § 13.1, puis :
   - **Volumes** : `vaultia_postgres-data`, `vaultia_media`, `vaultia_models` sont *in use* (mêmes
     volumes, même date de création qu'avant), plus deux nouveaux, `vaultia_caddy-data` et
     `vaultia_caddy-config` ;
   - connectez-vous sur `https://vaultia.home.arpa` avec votre **compte existant** : vos objets,
     photos et documents sont là ;
   - `http://192.168.1.100:6080` ne répond plus : c'est voulu, tout passe par Caddy.

Si Vaultia affiche une instance vide (création du premier compte proposée), la pile n'a pas été
recréée sous le même nom : **ne créez aucun compte**, supprimez cette pile, vérifiez le nom et
recommencez l'étape 6 ; vos volumes d'origine n'ont pas été touchés.

### 13.3 Revenir de HTTPS à HTTP

Même principe, dans l'autre sens :

1. Sauvegarde ALL (§ 12, variante HTTPS).
2. Relevez les variables ; **Delete this stack** ; vérifiez les volumes (§ 13.2, étapes 2, 4, 5).
3. **Add stack**, même nom, Compose path **`compose.yaml`**, variables du § 4 :

       BETTER_AUTH_URL=http://192.168.1.100:6080
       VAULTIA_BIND_ADDRESS=192.168.1.100
       VAULTIA_PORT=6080

   `TRUSTED_PROXIES` : supprimée (ou vide). `VAULTIA_DOMAIN` peut rester, sans effet.
4. **Deploy the stack** : postgres + vaultia, Vaultia de nouveau publié sur le port 6080, mêmes
   données. Le conteneur Caddy a disparu avec l'ancienne pile.

Les volumes `vaultia_caddy-data` et `vaultia_caddy-config` restent : ne les supprimez pas si vous
comptez revenir en HTTPS. Au retour, Caddy retrouve **la même autorité** : rien à réinstaller sur les
appareils (vérifié : empreinte identique).

### 13.4 Mettre à jour une pile HTTPS

Exactement comme au § 11 : **Pull and redeploy** (avec *Re-pull image*), variables inchangées. Le
Compose path reste `compose.portainer-https.yaml` : il suit la nouvelle version du dépôt (image
épinglée, Caddyfile). L'autorité locale, dans `vaultia_caddy-data`, est conservée. Watchtower
(facultatif) fonctionne comme en HTTP : seul le conteneur Vaultia porte les étiquettes
([update.md](update.md#pile-portainer-depuis-git)).

### 13.5 Sauvegarde d'une pile HTTPS

Même procédure qu'au § 12, en désignant **le fichier de la pile** :

    COMPOSE="docker compose -p vaultia -f compose.portainer-https.yaml" ./scripts/backup.sh

Le `.env` du clone contient les mêmes variables que la pile (HTTPS comprises). Sans
`-f compose.portainer-https.yaml`, le script relancerait Vaultia d'après `compose.yaml`, donc
publié en HTTP à côté de Caddy. Vérifié : sauvegarde complète (`storage_verify=ok`), aucun conteneur
recréé, Vaultia toujours sans port publié. Sauvegardez aussi le volume `vaultia_caddy-data`
([https.md § Persistance](https.md#persistance-et-sauvegarde)).

### 13.6 Certificat racine public

Depuis un terminal sur le serveur, dans un clone de ce dépôt (le `.env` n'est pas nécessaire) :

    ./scripts/export-ca.sh                              # pile nommée vaultia
    COMPOSE_PROJECT_NAME=<nom de la pile> ./scripts/export-ca.sh    # autre nom

Le script retrouve le conteneur Caddy de la pile et n'exporte que le certificat **public**
(`root.crt`) dans `vaultia-local-ca.crt`, avec son empreinte SHA-256 ; la clé privée ne quitte
jamais le volume. Installation sur les appareils : [https.md § 6](https.md#6-installer-lautorité-sur-chaque-appareil).
