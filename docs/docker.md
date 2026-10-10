# Installer Vaultia avec Docker Compose

Guide complet en ligne de commande, de zéro à un Vaultia en service sur votre réseau local.
Équivalent avec une interface web : [portainer.md](portainer.md).

> **Pré-version (bêta, avant 1.0)** : Vaultia `0.1.0-rc.21`. Faites des sauvegardes.

Dans tout ce guide, **`192.168.1.100` est un exemple** : remplacez-le par l'adresse IPv4 privée
de **votre** serveur. Vaultia n'a aucune adresse par défaut de ce genre.

## 1. Prérequis

| Besoin | Détail | Vérifier |
| --- | --- | --- |
| Machine | Linux `amd64` ou `arm64` (macOS et Windows avec Docker Desktop pour un essai) | `uname -m` → `x86_64` ou `aarch64` |
| Docker | Docker Engine 24 ou plus récent | `docker --version` |
| Compose | Docker Compose **v2** (commande `docker compose`, sans tiret) | `docker compose version` |
| Git | pour récupérer la distribution et ses mises à jour | `git --version` |
| OpenSSL | pour générer les secrets | `openssl version` |
| Adresse du serveur | une adresse IPv4 **privée et stable** (réservation DHCP ou adresse fixe), par exemple `192.168.1.100` | `ip -4 addr` |
| Disque | au moins **4 Gio libres** : ≈ 2,2 Go occupés avant vos données (image 1,7 Go, PostgreSQL 0,3 Go, modèles de vision ≈ 230 Mio) | `df -h` |
| Mémoire | 2 Gio conseillés | `free -h` |
| Internet | au premier démarrage (≈ 1 Go : images et les deux modèles de vision), ensuite facultatif | — |

Docker non installé : <https://docs.docker.com/engine/install/>.

## 2. Récupérer la distribution

    git clone https://github.com/multinet33/vaultia-selfhosted.git
    cd vaultia-selfhosted

Toutes les commandes suivantes se lancent depuis ce dossier. Il ne contient que la distribution
(`compose.yaml`, modèle de configuration, scripts de sauvegarde, documentation) : l'application est
une image publiée sur GHCR, rien n'est compilé chez vous.

## 3. Créer le fichier de configuration

    cp .env.example .env
    chmod 600 .env

Générez les deux secrets :

    openssl rand -hex 24         # → POSTGRES_PASSWORD
    openssl rand -base64 32      # → BETTER_AUTH_SECRET

Ouvrez `.env` avec un éditeur (`nano .env`) et collez chaque valeur après le `=` de sa ligne.

| Valeur | À quoi elle sert |
| --- | --- |
| `POSTGRES_PASSWORD` | mot de passe de la base. Fixé **à la création de la base** : le changer ensuite empêche Vaultia de s'y connecter |
| `BETTER_AUTH_SECRET` | signe les sessions de connexion et les liens de partage. Le changer déconnecte tout le monde et invalide les liens de partage |

Ces secrets doivent rester **secrets** (ne publiez jamais `.env`), être **conservés** (gestionnaire
de mots de passe, copie de `.env` hors du serveur : ils sont nécessaires pour restaurer une
sauvegarde) et ne **jamais être régénérés** lors d'une mise à jour.

## 4. Variables

`.env.example` contient toutes les variables de la distribution, commentées. Pour une
installation standard sur le réseau local, renseignez celles-ci.

### Exemple complet de `.env` (réseau local, port 6080)

    # --- Obligatoire
    POSTGRES_PASSWORD=<valeur générée par openssl rand -hex 24>
    BETTER_AUTH_SECRET=<valeur générée par openssl rand -base64 32>
    BETTER_AUTH_URL=http://192.168.1.100:6080

    # --- Installation standard
    VAULTIA_SIGNUP_POLICY=first-user
    VAULTIA_BIND_ADDRESS=192.168.1.100
    VAULTIA_PORT=6080
    POSTGRES_USER=vaultia
    POSTGRES_DB=vaultia
    VAULTIA_SUBNET=172.30.83.0/24

    # --- Facultatif : laisser vide
    TRUSTED_PROXIES=
    HSTS_MAX_AGE=
    VAULTIA_IMAGE=
    INTELLIGENCE_PROVIDERS=
    INTELLIGENCE_MODELS_PROVISION=
    INTELLIGENCE_CONTACT=
    MEDIA_MAX_UPLOAD_BYTES=
    NOTIFICATIONS_CRON_SECRET=
    WEBHOOK_ALLOW_PRIVATE_NETWORKS=
    WEBHOOK_SECRET_KEY=

Les `<…>` sont à remplacer par vos secrets ; `192.168.1.100` par l'adresse de votre serveur. En
partant de `.env.example`, il suffit de modifier `POSTGRES_PASSWORD`, `BETTER_AUTH_SECRET`,
`BETTER_AUTH_URL`, `VAULTIA_BIND_ADDRESS` et `VAULTIA_PORT` : les autres lignes ont déjà ces valeurs.

### Les trois valeurs qui doivent concorder

    BETTER_AUTH_URL=http://IP_DU_SERVEUR:6080
    VAULTIA_BIND_ADDRESS=IP_DU_SERVEUR
    VAULTIA_PORT=6080

- `BETTER_AUTH_URL` : l'adresse **exacte** tapée dans le navigateur (schéma, adresse, port) ; si
  elle diffère, les formulaires, connexion comprise, sont refusés (contrôle d'origine).
- `VAULTIA_BIND_ADDRESS` : adresse de la machine où Docker publie Vaultia ; elle doit appartenir
  au serveur (sinon `cannot assign requested address`).
- `VAULTIA_PORT` : port publié, celui de `BETTER_AUTH_URL`.

### Pourquoi le port 6080

Ces guides utilisent **6080**. Les navigateurs refusent certains ports réservés à d'autres
protocoles, dont **6000** : Docker le publie sans erreur, mais Chrome, Edge et les autres
navigateurs Chromium affichent `ERR_UNSAFE_PORT`. N'utilisez pas 6000 pour Vaultia.

### Référence : toutes les variables

Obligatoires :

| Variable | Rôle | Défaut | À modifier ? |
| --- | --- | --- | --- |
| `POSTGRES_PASSWORD` | mot de passe de la base | aucun : `docker compose` refuse de démarrer sans lui | **oui** : secret (§ 3) |
| `BETTER_AUTH_SECRET` | signature des sessions et liens de partage ; ≥ 32 caractères | aucun | **oui** : secret (§ 3) |
| `BETTER_AUTH_URL` | adresse exacte ouverte dans le navigateur ; `http://` seulement pour `localhost` ou une IPv4 privée, sinon `https://` (§ 12) | `http://localhost:3000` dans `.env.example` | **oui** |

Installation standard :

| Variable | Rôle | Défaut | À modifier ? |
| --- | --- | --- | --- |
| `VAULTIA_SIGNUP_POLICY` | qui peut créer un compte : `first-user`, `invite`, `open` (§ 8) | `first-user` | non, sauf décision délibérée |
| `VAULTIA_BIND_ADDRESS` | adresse de l'hôte où Vaultia est publié | `127.0.0.1` (le serveur seul) | **oui** : IPv4 privée du serveur |
| `VAULTIA_PORT` | port publié | `3000` | **oui** : `6080` |
| `POSTGRES_USER` | utilisateur PostgreSQL | `vaultia` | non ; jamais après l'installation |
| `POSTGRES_DB` | nom de la base | `vaultia` | non ; jamais après l'installation |
| `VAULTIA_SUBNET` | sous-réseau interne des conteneurs | `172.30.83.0/24` | seulement en cas de conflit |

Facultatives (laisser vides) :

| Variable | Rôle | Défaut |
| --- | --- | --- |
| `TRUSTED_PROXIES` | adresse(s) du reverse proxy, derrière HTTPS ([reverse-proxy.md](reverse-proxy.md)) | aucun proxy |
| `HSTS_MAX_AGE` | en-tête HSTS en secondes (HTTPS seulement) | aucun |
| `VAULTIA_IMAGE` | autre image que celle épinglée (tests, ou canal `…:rc` / `…:stable` suivi par Watchtower : [update.md](update.md#mises-à-jour-automatiques-watchtower-facultatif)) | image épinglée de `compose.yaml` |
| `INTELLIGENCE_PROVIDERS` | moteurs d'analyse installés | vision locale complète, recherche par le sens et `open-facts` (Internet, seulement pour un Espace en mode « externe ») ; voir [vision.md](vision.md) |
| `COMPOSE_PROFILES`, `WEB_PRODUCT_SEARCH_*`, `SEARXNG_SECRET` | recherche Web de codes produit (facultative) | désactivée ; voir [web-product-search.md](web-product-search.md) |
| `INTELLIGENCE_MODELS_PROVISION` | installation automatique des modèles de vision : `auto` ou `off` | `auto` |
| `INTELLIGENCE_CONTACT` | contact envoyé aux bases produit ouvertes (avec `open-facts`) | vide |
| `MEDIA_MAX_UPLOAD_BYTES` | taille maximale d'un envoi (1000 à 50000000 octets) | 10000000 |
| `NOTIFICATIONS_CRON_SECRET` | active la route de rafraîchissement planifié des notifications (`openssl rand -hex 32`) | désactivée |
| `WEBHOOK_ALLOW_PRIVATE_NETWORKS` | autorise les webhooks vers le réseau local (`true`) | refusé |
| `WEBHOOK_SECRET_KEY` | clé des secrets de webhooks (≥ 32 caractères) | dérivée de `BETTER_AUTH_SECRET` |

Détail : [configuration.md](configuration.md).

## 5. Valider la configuration avant de démarrer

    docker compose config --quiet

Aucune sortie : la configuration est complète et valide. Sinon, le message nomme la variable en
cause (par exemple `required variable BETTER_AUTH_SECRET is missing a value`).

Pour voir l'image qui sera lancée :

    docker compose config --images
    # postgres:18-alpine
    # ghcr.io/multinet33/vaultia:0.1.0-rc.21@sha256:e0c89743…

⚠ `docker compose config` **sans** option affiche toute la configuration **avec les secrets en
clair** : ne collez jamais sa sortie dans un forum, un ticket ou un rapport public.

## 6. Premier démarrage

    docker compose pull
    docker compose up -d

`pull` télécharge PostgreSQL et l'image Vaultia épinglée (≈ 610 Mio compressés). `up -d` crée le
réseau et les trois volumes, démarre PostgreSQL (création de la base), puis Vaultia, qui contrôle
sa configuration, applique les migrations de la base et démarre le serveur web. En parallèle,
Vaultia installe les modèles de vision (SigLIP 2 90 Mio, E5 130 Mio, vérifiés par taille et SHA-256) : l'application est
utilisable avant la fin de cette installation.

## 7. Vérifier

    docker compose ps

| Service | État attendu |
| --- | --- |
| `postgres` | `Up … (healthy)` |
| `vaultia` | `Up … (healthy)` (après le premier contrôle de santé, ≈ 30 s) |

Santé de l'application (votre adresse) :

    curl http://192.168.1.100:6080/api/health
    # {"status":"ok","database":"up","vision":"ready"}

`"vision":"provisioning"` : le modèle s'installe encore ; `"failed"` : échec du téléchargement,
nouvel essai automatique (vérifier l'accès Internet du serveur).

Journaux de Vaultia :

    docker compose logs vaultia | grep -E '\[vaultia\]|\[config\]|migrations'

| Message | Sens |
| --- | --- |
| `[config] configuration valide` | configuration acceptée |
| `[config] BETTER_AUTH_URL en http sur une adresse privée …` | rappel normal en HTTP sur le réseau local (§ 12) |
| `[config] TRUSTED_PROXIES n'est pas défini …` | avertissement normal sans reverse proxy ; à renseigner seulement derrière un proxy HTTPS |
| `All migrations have been successfully applied.` / `No pending migrations to apply.` | base créée / base à jour |
| `[vaultia] démarrage de Vaultia 0.1.0` | serveur web démarré |
| `[vaultia][models] … Vaultia Vision prête` / `… déjà présent et intègre` | modèle installé / déjà présent, non retéléchargé |

Vision (modèle, moteurs locaux et inférence réelle) :

    docker compose exec vaultia vaultia vision-status
    # dernière ligne : Vaultia Vision: READY

Traitements locaux (photos HEIC, miniatures, codes-barres, PDF, OCR) :

    docker compose run --rm --no-deps vaultia runtime-smoke
    # 8/8 contrôles réussis.

Fichiers stockés contre la base (utile après une restauration ou un incident) :

    docker compose run --rm --no-deps vaultia storage-verify

## 8. Premier accès

Ouvrez **`http://192.168.1.100:6080`** (votre adresse) depuis un appareil du réseau local.

Avec `VAULTIA_SIGNUP_POLICY=first-user` :

- le **premier** compte créé est libre : créez-le tout de suite, il devient l'administrateur de
  son Espace ;
- ensuite l'inscription libre est **fermée** : les autres personnes sont invitées depuis
  *Réglages › Membres* et créent leur compte depuis leur lien d'invitation, avec l'adresse e-mail
  invitée ;
- `invite` ferme l'inscription dès le départ ; `open` l'ouvre à tous, à ne choisir que
  délibérément ([configuration.md § Comptes](configuration.md#comptes)).

Pour la reconnaissance d'objets en photo : *Réglages › Vaultia Vision*, mode **Locale** (désactivé
par défaut dans chaque Espace).

## 9. Persistance

`compose.yaml` définit trois volumes nommés, préfixés par le nom du projet `vaultia` :

| Volume | Contenu | Si on le supprime |
| --- | --- | --- |
| `vaultia_postgres-data` | la base PostgreSQL : tout l'inventaire | **perte de toutes les données** (sauf sauvegarde) |
| `vaultia_media` | photos, documents, fichiers | **perte de tous les fichiers** (sauf sauvegarde) |
| `vaultia_models` | modèle de la vision locale | aucune donnée perdue : retéléchargé au démarrage suivant |

| Commande | Effet sur les volumes |
| --- | --- |
| `docker compose stop` / `start` / `restart` | conservés |
| `docker compose down` puis `up -d` | conservés (seuls les conteneurs et le réseau sont supprimés) |
| `docker compose pull` + `up -d` (mise à jour) | conservés |
| **`docker compose down -v`** | **DESTRUCTIF : efface la base, les fichiers et le modèle** |

N'utilisez **jamais** `docker compose down -v` pour mettre à jour ou « réparer » Vaultia. Détail :
[storage.md](storage.md).

## 10. Sauvegarde (Backup ALL)

Sauvegarde officielle, depuis le dossier de la distribution :

    ./scripts/backup.sh                    # → ./backups/vaultia-<date UTC>/
    ./scripts/backup.sh /mnt/sauvegardes   # ou un autre dossier

Le script vérifie chaque fichier contre la base (`storage-verify`), arrête Vaultia quelques
secondes, copie la base (`pg_dump`) et les fichiers, puis relance Vaultia. Le modèle de vision
n'est pas sauvegardé (retéléchargeable). Vérifiez la sauvegarde :

    cd backups/vaultia-<date>
    sha256sum -c SHA256SUMS                # macOS : shasum -a 256 -c SHA256SUMS
    cat MANIFEST                           # storage_verify=ok attendu

Copiez ensuite le dossier **hors du serveur**, avec une copie de `.env` (secrets) conservée à
part. La restauration (`scripts/restore.sh`) se fait sur une installation **neuve**, uniquement
selon [backup-restore.md](backup-restore.md).

## 11. Mettre à jour

    ./scripts/backup.sh                    # 1. Backup ALL, puis vérification (§ 10)
    git pull                               # 2. nouvelle version de la distribution
    git log -p -1 -- compose.yaml          # 3. voir la nouvelle image épinglée
    docker compose config --quiet          # 4. configuration toujours valide
    docker compose pull                    # 5. télécharger la nouvelle image
    docker compose up -d                   # 6. remplacer les conteneurs

Au redémarrage, Vaultia applique seul les migrations de la base
(`docker compose logs vaultia | grep migrations`). Ensuite :

    docker compose ps                                  # healthy
    curl http://192.168.1.100:6080/api/health          # status ok, vision ready
    docker compose exec vaultia vaultia vision-status  # Vaultia Vision: READY
    docker compose run --rm --no-deps vaultia storage-verify

`.env` n'est pas modifié par `git pull` : vos secrets et votre configuration sont conservés ; ne
régénérez jamais les secrets. Comparez `.env` avec `.env.example` si une nouvelle version ajoute
une variable. Les trois volumes sont conservés ; **jamais** `docker compose down -v`. Notes de
version, limites du retour arrière : [update.md](update.md).

## 12. HTTP ou HTTPS

Règles du produit pour `BETTER_AUTH_URL` :

| Adresse | Accepté ? |
| --- | --- |
| `http://localhost:…`, `http://127.0.0.1:…` | oui |
| `http://` + IPv4 privée : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | oui, **réseau local uniquement** |
| `http://` + nom d'hôte (`http://vaultia.lan`) ou adresse publique | **non** : Vaultia refuse de démarrer |
| `https://…` | oui, partout (recommandé) |

En HTTP sur le réseau local : **rien n'est chiffré** ; la **caméra du scanner** et le **mode hors
ligne** sont indisponibles (ils exigent un contexte sécurisé du navigateur) ; les cookies ne sont
pas marqués `Secure`. Ne rendez **jamais** ce port joignable depuis Internet.

Pour toutes les fonctions du navigateur et pour tout accès extérieur, utilisez **HTTPS** avec un
reverse proxy : [reverse-proxy.md](reverse-proxy.md).
