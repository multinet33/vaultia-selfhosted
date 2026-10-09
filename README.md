# Vaultia — Self-hosting / Auto-hébergement

**[English](#english) · [Français](#français)**

> **PRE-RELEASE (beta, before 1.0) / PRÉ-VERSION (bêta, avant 1.0).**
> This is a test *candidate* (`0.1.0-rc.15`), not a stable release. Keep backups and report issues.
> Ceci est un *candidat* de test (`0.1.0-rc.15`), pas une version stable. Faites des sauvegardes et
> signalez les problèmes.

- [Installation tutorial (English)](#installation-tutorial-english)
- [Tutoriel d'installation (français)](#tutoriel-dinstallation-français)

**Complete step-by-step guides / Guides pas à pas complets**:

| Guide | English | Français |
| --- | --- | --- |
| Docker Compose (command line / ligne de commande) | [docs/docker_EN.md](docs/docker_EN.md) | [docs/docker.md](docs/docker.md) |
| Portainer (stack from this repository / pile depuis ce dépôt) | [docs/portainer_EN.md](docs/portainer_EN.md) | [docs/portainer.md](docs/portainer.md) |

**More / Plus** : [installation](docs/installation.md) · [update & Watchtower / mise à jour](docs/update.md) ·
[API](docs/api.md) · [webhooks](docs/webhooks.md) (French / français). Every instance also serves its
own interactive API documentation at `/api/docs` / Chaque instance sert aussi sa documentation
interactive de l'API à l'adresse `/api/docs`.

---

## Installation tutorial (English)

About 10 minutes on a machine that already has Docker.

**1. Check the prerequisites**

    docker --version            # Docker Engine 24 or newer
    docker compose version      # Compose v2
    openssl version             # used to generate the secrets

No Docker yet? Install it first: <https://docs.docker.com/engine/install/> (Linux) or Docker
Desktop (macOS, Windows). Linux `amd64` and `arm64` are supported.

**2. Download the distribution**

    git clone https://github.com/multinet33/vaultia-selfhosted.git
    cd vaultia-selfhosted

**3. Create your configuration**

    cp .env.example .env

Fill in the two secrets. Either generate them yourself (`openssl rand -hex 24` for
`POSTGRES_PASSWORD`, `openssl rand -base64 32` for `BETTER_AUTH_SECRET`) and paste them into
`.env` with any text editor, or run the one-liner for your system:

    # Linux
    sed -i -e "s#^POSTGRES_PASSWORD=\$#POSTGRES_PASSWORD=$(openssl rand -hex 24)#" \
           -e "s#^BETTER_AUTH_SECRET=\$#BETTER_AUTH_SECRET=$(openssl rand -base64 32)#" .env

    # macOS
    sed -i '' -e "s#^POSTGRES_PASSWORD=\$#POSTGRES_PASSWORD=$(openssl rand -hex 24)#" \
              -e "s#^BETTER_AUTH_SECRET=\$#BETTER_AUTH_SECRET=$(openssl rand -base64 32)#" .env

    chmod 600 .env              # the file contains secrets: readable by you only

Keep a copy of `.env` somewhere safe: without it, backups cannot be fully restored.

**4. Start Vaultia**

    docker compose up -d

The first start downloads about 1 GB (application ≈ 650 MB, database ≈ 120 MB, the two local Vision models ≈ 230 MB).

**5. Check that everything is running**

    docker compose ps
    # postgres and vaultia: "Up … (healthy)" after about a minute

    curl http://127.0.0.1:3000/api/health
    # {"status":"ok","database":"up","vision":"ready"}

    docker compose exec vaultia vaultia vision-status
    # last line: Vaultia Vision: READY

`"vision":"provisioning"` means the Vision models are still downloading: Vaultia is already usable,
the photo recognition becomes available a moment later (`docker compose logs vaultia | grep models`).

**6. Create your account**

Open **<http://localhost:3000>** on the machine running Vaultia and create the first account: it
becomes the administrator. Sign-up then closes; invite other people from
*Settings › Members*. The interface follows the browser language (French or English).

To use the local Vision in a workspace: *Settings › Vaultia Vision*, mode **Local** (off by
default).

**7. Access from other devices (optional)**

Two options:

- **HTTPS on your home network, no domain needed (all features)**: the optional Caddy overlay of
  this repository with its own local certificate authority (`https://vaultia.home.arpa`): see
  [docs/https.md](docs/https.md) (French). Portainer stack: Compose path
  `compose.portainer-https.yaml` ([docs/portainer_EN.md § 13](docs/portainer_EN.md#13-local-https-with-portainer-caddy)),
  not `COMPOSE_FILE`.
- **HTTPS behind your own reverse proxy or domain (all features)**: (Caddy, nginx, Traefik, Nginx
  Proxy Manager, Cloudflare Tunnel…), set `BETTER_AUTH_URL` to the `https://` address: see
  [docs/reverse-proxy.md](docs/reverse-proxy.md).
- **Plain HTTP on your local network only**: use the server's private IPv4 address (10.x,
  172.16–31.x, 192.168.x). For example, if your server is `192.168.1.100` (an example, use yours):

      BETTER_AUTH_URL=http://192.168.1.100:6080
      VAULTIA_BIND_ADDRESS=192.168.1.100
      VAULTIA_PORT=6080

  Nothing is encrypted, and browser features that need a secure context are unavailable, notably
  **offline mode** and the **barcode scanner camera**. Never expose this port to the Internet.
  Avoid port 6000: Chromium-based browsers refuse it (`ERR_UNSAFE_PORT`).
  Any other `http://` address (hostname, public IP) is refused: HTTPS is required there.
  Details, including Portainer: [docs/configuration.md](docs/configuration.md#http-sur-le-réseau-local).

**Everyday commands**

    docker compose stop / start / restart     # data is kept
    ./scripts/backup.sh                       # database + files → ./backups/
    git pull && docker compose pull && docker compose up -d   # update (back up first)

⚠ `docker compose down -v` **deletes** the database, files and model.

---

## Tutoriel d'installation (français)

Environ 10 minutes sur une machine où Docker est déjà installé.

**1. Vérifier les prérequis**

    docker --version            # Docker Engine 24 ou plus récent
    docker compose version      # Compose v2
    openssl version             # sert à générer les secrets

Pas encore de Docker ? L'installer d'abord : <https://docs.docker.com/engine/install/> (Linux) ou
Docker Desktop (macOS, Windows). Linux `amd64` et `arm64` sont pris en charge.

**2. Récupérer la distribution**

    git clone https://github.com/multinet33/vaultia-selfhosted.git
    cd vaultia-selfhosted

**3. Créer la configuration**

    cp .env.example .env

Remplir les deux secrets : soit les générer (`openssl rand -hex 24` pour `POSTGRES_PASSWORD`,
`openssl rand -base64 32` pour `BETTER_AUTH_SECRET`) et les coller dans `.env` avec un éditeur de
texte, soit lancer la commande de votre système :

    # Linux
    sed -i -e "s#^POSTGRES_PASSWORD=\$#POSTGRES_PASSWORD=$(openssl rand -hex 24)#" \
           -e "s#^BETTER_AUTH_SECRET=\$#BETTER_AUTH_SECRET=$(openssl rand -base64 32)#" .env

    # macOS
    sed -i '' -e "s#^POSTGRES_PASSWORD=\$#POSTGRES_PASSWORD=$(openssl rand -hex 24)#" \
              -e "s#^BETTER_AUTH_SECRET=\$#BETTER_AUTH_SECRET=$(openssl rand -base64 32)#" .env

    chmod 600 .env              # le fichier contient des secrets : lisible par vous seul

Gardez une copie de `.env` en lieu sûr : sans lui, une sauvegarde ne se restaure pas entièrement.

**4. Démarrer Vaultia**

    docker compose up -d

Le premier démarrage télécharge environ 1 Go (application ≈ 650 Mo, base de données ≈ 120 Mo, les deux modèles de la vision locale ≈ 230 Mo).

**5. Vérifier que tout fonctionne**

    docker compose ps
    # postgres et vaultia : « Up … (healthy) » après une minute environ

    curl http://127.0.0.1:3000/api/health
    # {"status":"ok","database":"up","vision":"ready"}

    docker compose exec vaultia vaultia vision-status
    # dernière ligne : Vaultia Vision: READY

`"vision":"provisioning"` : les modèles de vision se téléchargent encore. Vaultia est déjà utilisable,
la reconnaissance en photo arrive un peu plus tard (`docker compose logs vaultia | grep models`).

**6. Créer votre compte**

Ouvrir **<http://localhost:3000>** sur la machine qui héberge Vaultia et créer le premier compte :
il devient l'administrateur. L'inscription se ferme ensuite ; invitez les autres personnes depuis
*Réglages › Membres*.

Pour utiliser la vision locale dans un Espace : *Réglages › Vaultia Vision*, mode **« Locale »**
(désactivée par défaut).

**7. Accès depuis d'autres appareils (facultatif)**

Deux possibilités :

- **HTTPS à la maison, sans domaine (toutes les fonctions)** : la surcouche Caddy facultative de
  ce dépôt, avec son autorité de certification locale (`https://vaultia.home.arpa`) : voir
  [docs/https.md](docs/https.md). Pile Portainer : Compose path `compose.portainer-https.yaml`
  ([docs/portainer.md § 13](docs/portainer.md#13-https-local-avec-portainer-caddy)), pas `COMPOSE_FILE`.
- **HTTPS derrière votre reverse proxy ou votre domaine (toutes les fonctions)** : (Caddy, nginx,
  Traefik, Nginx Proxy Manager, Cloudflare Tunnel…), mettez l'adresse `https://` dans
  `BETTER_AUTH_URL` : voir [docs/reverse-proxy.md](docs/reverse-proxy.md).
- **HTTP simple, sur le réseau local seulement** : l'adresse IPv4 privée du serveur (10.x,
  172.16-31.x, 192.168.x). Par exemple, si votre serveur est `192.168.1.100` (un exemple, mettez
  la vôtre) :

      BETTER_AUTH_URL=http://192.168.1.100:6080
      VAULTIA_BIND_ADDRESS=192.168.1.100
      VAULTIA_PORT=6080

  Rien n'est chiffré, et les fonctions du navigateur qui exigent un contexte sécurisé sont
  indisponibles, notamment le **mode hors ligne** et la **caméra du scanner**. N'exposez jamais ce
  port à Internet. Évitez le port 6000 : les navigateurs Chromium le refusent (`ERR_UNSAFE_PORT`). Toute autre adresse en `http://` (nom d'hôte, IP publique) est refusée : HTTPS y
  est obligatoire. Détail, Portainer compris : [docs/configuration.md](docs/configuration.md#http-sur-le-réseau-local).

**Commandes courantes**

    docker compose stop / start / restart     # données conservées
    ./scripts/backup.sh                       # base + fichiers → ./backups/
    git pull && docker compose pull && docker compose up -d   # mise à jour (sauvegarder avant)

⚠ `docker compose down -v` **efface** la base, les fichiers et le modèle.

---

## English

### What is Vaultia?

Vaultia is a web application for personal and family inventory: items, rooms and properties,
vehicles, invoices, warranties, documents, values, collections and history — with a **local
Vision** (barcodes, text recognition, object recognition in photos) that runs entirely on your
server.

This repository contains **only the distribution**: a Docker Compose file, a configuration
template, backup scripts and documentation. Vaultia itself is an image published on GitHub
Container Registry; nothing is compiled on your machine.

The user interface is available in French and English. The detailed documentation in `docs/` is
in French for now.

### Requirements

- Linux `amd64` or `arm64` (or macOS / Windows with Docker Desktop);
- Docker Engine 24+ with Compose v2;
- ~4 GB of free disk space (image ~1.7 GB, Vision models ~230 MB, plus your data); 2 GB of RAM recommended;
- Internet on first start (images and Vision models), optional afterwards;
- `openssl` to generate the secrets.

### Local Vision

On first start, Vaultia installs the Vision models (SigLIP 2, 90 MB; E5, 130 MB) into the `models` volume, **in
the background**: the application is usable right away. The model is checked (size and SHA-256)
and never downloaded again (restart, update). Once installed, all analyses run **offline**; no
photo or document is sent to an external service. Details: [docs/vision.md](docs/vision.md).

| Capability | Engine | Where |
| --- | --- | --- |
| Object recognition, colour, material | SigLIP 2 (ONNX Runtime, CPU) | model in the `models` volume |
| Text recognition (French, English) | Tesseract 5 | in the image |
| Barcodes, QR codes | ZXing | in the image |
| Invoice and receipt extraction | deterministic rules | in the image |

### Addresses and ports

| What | Where |
| --- | --- |
| Application | `http://localhost:3000` (published on the host's `127.0.0.1` only) |
| Health | `http://localhost:3000/api/health` |
| PostgreSQL | **not published**: internal container network only |

### Persistent data

| Volume | Content | Backed up by `scripts/backup.sh` |
| --- | --- | --- |
| `vaultia_postgres-data` | database (the whole inventory) | **yes** |
| `vaultia_media` | photos, documents, files | **yes** |
| `vaultia_models` | local Vision models | no (downloaded again if missing) |
| `.env` (file) | configuration and secrets | **back it up separately** |

Details: [docs/storage.md](docs/storage.md).

### Update, backup, restore

The image is pinned in `compose.yaml` by tag **and** digest; there is no `latest`. An update is a
new line in this repository:

    ./scripts/backup.sh
    git pull
    docker compose pull && docker compose up -d

Database migrations run automatically at start. See [docs/update.md](docs/update.md) (rollback
limits) and [docs/backup-restore.md](docs/backup-restore.md).

**Optional automatic updates (Watchtower)**: the pinned image stays the default. An administrator
may instead choose a moving channel, in `.env` or as a Portainer stack variable:
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc` (release candidates) or
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable` (stable releases, not published yet during the
beta; never `latest`). The two channels are independent. With a separate Watchtower run with
`--scope vaultia` (only the Vaultia container is labelled, PostgreSQL is excluded), new versions of
the chosen channel, and their database migrations, are applied automatically, with no backup taken
for you. Details and risks:
[docs/update.md](docs/update.md#mises-à-jour-automatiques-watchtower-facultatif).

### Documentation (French)

Step-by-step installation, in English: [Docker Compose](docs/docker_EN.md) ·
[Portainer](docs/portainer_EN.md). In French: [Docker Compose](docs/docker.md) · [Portainer](docs/portainer.md) ·
[installation](docs/installation.md) · [configuration](docs/configuration.md) ·
[storage](docs/storage.md) · [vision](docs/vision.md) · [web product search](docs/web-product-search_EN.md) · [reverse proxy](docs/reverse-proxy.md) ·
[update & Watchtower](docs/update.md) · [backup & restore](docs/backup-restore.md) ·
[API](docs/api.md) · [webhooks](docs/webhooks.md) ·
[troubleshooting](docs/troubleshooting.md) · [validation reports](docs/reports/)

**API**: every instance serves its interactive API documentation at `/api/docs` (for example
`https://vaultia.example/api/docs`) and the OpenAPI 3.1 contract at `/api/v1/openapi.json`; tokens
are created in Settings › API access. Rules, scopes and examples: [docs/api.md](docs/api.md).

### License

Vaultia is **source-available** software, **not** open source in the OSI sense. Non-commercial
use: [PolyForm Noncommercial 1.0.0](LICENSE). Any commercial, professional, hosted (SaaS) or
embedded use requires a commercial license: [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).

Third-party components: the image ships their notices (`/app/THIRD-PARTY-NOTICES.md`). The Vision
models are downloaded by your instance from their official sources: see
[docs/vision.md](docs/vision.md#licences-des-modèles).

---

## Français

### Qu'est-ce que Vaultia ?

Vaultia est une application web d'inventaire personnel et familial : objets, pièces et
propriétés, véhicules, factures, garanties, documents, valeurs, collections, historique — avec une
**vision locale** (codes-barres, reconnaissance de texte, reconnaissance d'objets en photo) qui
tourne entièrement sur votre serveur.

Ce dépôt contient **uniquement la distribution** : un fichier Docker Compose, un modèle de
configuration, des scripts de sauvegarde et la documentation. Vaultia lui-même est une image
publiée sur GitHub Container Registry ; rien n'est compilé chez vous.

### Prérequis

- Linux `amd64` ou `arm64` (ou macOS / Windows avec Docker Desktop) ;
- Docker Engine 24+ avec Compose v2 ;
- ~4 Gio de disque libre (image ~1,7 Gio, modèles de vision ~230 Mio, plus vos données) ; 2 Gio de RAM conseillés ;
- Internet au premier démarrage (image et modèle de la vision), ensuite facultatif ;
- `openssl` pour générer les secrets.

### Vision locale

Au premier démarrage, Vaultia installe les modèles de la vision (SigLIP 2, 90 Mio ; E5, 130 Mio) dans le volume
`models`, **en arrière-plan** : l'application est utilisable immédiatement. Le modèle est vérifié
(taille et SHA-256) et n'est jamais retéléchargé (redémarrage, mise à jour). Une fois installé,
toutes les analyses fonctionnent **hors ligne** ; aucune photo ni aucun document n'est envoyé à un
service externe. Détail : [docs/vision.md](docs/vision.md).

| Capacité | Moteur | Où |
| --- | --- | --- |
| Reconnaissance d'objets, couleur, matière | SigLIP 2 (ONNX Runtime, CPU) | modèle dans le volume `models` |
| Reconnaissance de texte (français, anglais) | Tesseract 5 | dans l'image |
| Codes-barres, QR codes | ZXing | dans l'image |
| Extraction des factures et tickets | règles déterministes | dans l'image |

### Adresses et ports

| Quoi | Où |
| --- | --- |
| Application | `http://localhost:3000` (publiée sur `127.0.0.1` de l'hôte uniquement) |
| Santé | `http://localhost:3000/api/health` |
| PostgreSQL | **non publié** : réseau interne des conteneurs seulement |

### Données persistantes

| Volume | Contenu | Sauvegardé par `scripts/backup.sh` |
| --- | --- | --- |
| `vaultia_postgres-data` | base de données (tout l'inventaire) | **oui** |
| `vaultia_media` | photos, documents, fichiers | **oui** |
| `vaultia_models` | modèle de la vision locale | non (retéléchargé s'il manque) |
| `.env` (fichier) | configuration et secrets | **à sauvegarder à part** |

Détail : [docs/storage.md](docs/storage.md).

### Mise à jour, sauvegarde, restauration

L'image est épinglée dans `compose.yaml` par son tag **et** son empreinte ; il n'y a pas de
`latest`. Une mise à jour est une nouvelle ligne dans ce dépôt :

    ./scripts/backup.sh
    git pull
    docker compose pull && docker compose up -d

Les migrations de base s'appliquent seules au démarrage. Voir [docs/update.md](docs/update.md)
(limites du retour arrière) et [docs/backup-restore.md](docs/backup-restore.md).

**Mises à jour automatiques facultatives (Watchtower)** : l'image épinglée reste le défaut. Un
administrateur peut choisir un canal mobile, dans `.env` ou en variable de pile Portainer :
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc` (candidats) ou
`VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:stable` (versions stables, pas encore publié pendant la
bêta ; jamais `latest`). Les deux canaux sont indépendants. Avec un Watchtower séparé lancé avec
`--scope vaultia` (seul le conteneur Vaultia est étiqueté, PostgreSQL est exclu), chaque nouvelle
version du canal choisi, migrations de base comprises, s'applique alors seule, sans sauvegarde
préalable. Détail et risques :
[docs/update.md](docs/update.md#mises-à-jour-automatiques-watchtower-facultatif).

### Documentation

| Document | Contenu |
| --- | --- |
| [docker.md](docs/docker.md) | **installation complète en ligne de commande** (Docker Compose), réseau local |
| [portainer.md](docs/portainer.md) | **installation complète avec Portainer** (pile depuis ce dépôt), réseau local ; HTTPS local (§ 13) |
| [https.md](docs/https.md) | HTTPS local avec Caddy, sans domaine : ligne de commande et Portainer |
| [installation.md](docs/installation.md) | installation rapide, premier compte, vérifications |
| [configuration.md](docs/configuration.md) | toutes les variables de `.env`, comptes, santé |
| [storage.md](docs/storage.md) | volumes : quoi, où, que se passe-t-il s'ils disparaissent |
| [vision.md](docs/vision.md) | vision locale : modèle, installation, état, hors ligne |
| [web-product-search.md](docs/web-product-search.md) | recherche Web de codes produit (facultative) : SearXNG auto-hébergé ou Brave Search |
| [reverse-proxy.md](docs/reverse-proxy.md) | HTTPS, proxys, `TRUSTED_PROXIES` |
| [update.md](docs/update.md) | mettre à jour, revenir en arrière (limites), mises à jour automatiques (Watchtower) |
| [api.md](docs/api.md) | API v1 : jetons, portées, erreurs, limites ; documentation interactive `/api/docs` de chaque instance |
| [webhooks.md](docs/webhooks.md) | webhooks sortants : événements, signature, réseau local, exemple Home Assistant |
| [backup-restore.md](docs/backup-restore.md) | sauvegarde, vérification, restauration |
| [troubleshooting.md](docs/troubleshooting.md) | problèmes courants |
| [reports/](docs/reports/) | rapports de validation de cette distribution |

### Licence

Vaultia est un logiciel **à sources disponibles** (*source-available*), **pas** un logiciel
libre au sens de l'OSI. Usage non commercial : [PolyForm Noncommercial 1.0.0](LICENSE). Tout usage
commercial, professionnel, en service hébergé (SaaS) ou intégré à un produit exige une licence
commerciale : [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).

Composants tiers : l'image embarque ses avis de licence (`/app/THIRD-PARTY-NOTICES.md`). Les modèles
de vision sont téléchargés par votre instance depuis leur source officielle : voir
[docs/vision.md § Licences des modèles](docs/vision.md#licences-des-modèles).
