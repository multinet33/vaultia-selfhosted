# Vaultia — Self-hosting / Auto-hébergement

**[English](#english) · [Français](#français)**

> **PRE-RELEASE (beta, before 1.0) / PRÉ-VERSION (bêta, avant 1.0).**
> This is a test *candidate* (`0.1.0-rc`), not a stable release. Keep backups and report issues.
> Ceci est un *candidat* de test (`0.1.0-rc`), pas une version stable. Faites des sauvegardes et
> signalez les problèmes.

- [Installation tutorial (English)](#installation-tutorial-english)
- [Tutoriel d'installation (français)](#tutoriel-dinstallation-français)

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

The first start downloads about 820 MB (application, database, Vision model).

**5. Check that everything is running**

    docker compose ps
    # postgres and vaultia: "Up … (healthy)" after about a minute

    curl http://127.0.0.1:3000/api/health
    # {"status":"ok","database":"up","vision":"ready"}

    docker compose exec vaultia vaultia vision-status
    # last line: Vaultia Vision: READY

`"vision":"provisioning"` means the Vision model is still downloading: Vaultia is already usable,
the photo recognition becomes available a moment later (`docker compose logs vaultia | grep models`).

**6. Create your account**

Open **<http://localhost:3000>** on the machine running Vaultia and create the first account: it
becomes the administrator. Sign-up then closes; invite other people from
*Settings › Members*. The interface follows the browser language (French or English).

To use the local Vision in a workspace: *Settings › Vaultia Vision*, mode **Local** (off by
default).

**7. Access from other devices (optional)**

Outside `localhost`, Vaultia requires **HTTPS**. Put it behind your own reverse proxy (Caddy,
nginx, Traefik, Nginx Proxy Manager, Cloudflare Tunnel…), then set `BETTER_AUTH_URL` to the
`https://` address: see [docs/reverse-proxy.md](docs/reverse-proxy.md).

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

Le premier démarrage télécharge environ 820 Mo (application, base de données, modèle de vision).

**5. Vérifier que tout fonctionne**

    docker compose ps
    # postgres et vaultia : « Up … (healthy) » après une minute environ

    curl http://127.0.0.1:3000/api/health
    # {"status":"ok","database":"up","vision":"ready"}

    docker compose exec vaultia vaultia vision-status
    # dernière ligne : Vaultia Vision: READY

`"vision":"provisioning"` : le modèle de vision se télécharge encore. Vaultia est déjà utilisable,
la reconnaissance en photo arrive un peu plus tard (`docker compose logs vaultia | grep models`).

**6. Créer votre compte**

Ouvrir **<http://localhost:3000>** sur la machine qui héberge Vaultia et créer le premier compte :
il devient l'administrateur. L'inscription se ferme ensuite ; invitez les autres personnes depuis
*Réglages › Membres*.

Pour utiliser la vision locale dans un Espace : *Réglages › Vaultia Vision*, mode **« Locale »**
(désactivée par défaut).

**7. Accès depuis d'autres appareils (facultatif)**

Hors de `localhost`, Vaultia exige **HTTPS**. Placez-le derrière votre reverse proxy (Caddy, nginx,
Traefik, Nginx Proxy Manager, Cloudflare Tunnel…), puis mettez l'adresse `https://` dans
`BETTER_AUTH_URL` : voir [docs/reverse-proxy.md](docs/reverse-proxy.md).

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
- ~4 GB of free disk space (image ~1.7 GB, model 90 MB, plus your data); 2 GB of RAM recommended;
- Internet on first start (image and Vision model), optional afterwards;
- `openssl` to generate the secrets.

### Local Vision

On first start, Vaultia installs the Vision model (SigLIP 2, 90 MB) into the `models` volume, **in
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
| `vaultia_models` | local Vision model | no (downloaded again if missing) |
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

### Documentation (French)

[installation](docs/installation.md) · [configuration](docs/configuration.md) ·
[storage](docs/storage.md) · [vision](docs/vision.md) · [reverse proxy](docs/reverse-proxy.md) ·
[update](docs/update.md) · [backup & restore](docs/backup-restore.md) ·
[troubleshooting](docs/troubleshooting.md) · [validation reports](docs/reports/)

### License

Vaultia is **source-available** software, **not** open source in the OSI sense. Non-commercial
use: [PolyForm Noncommercial 1.0.0](LICENSE). Any commercial, professional, hosted (SaaS) or
embedded use requires a commercial license: [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).

Third-party components: the image ships their notices (`/app/THIRD-PARTY-NOTICES.md`). The Vision
model is downloaded by your instance from its official source: see
[docs/vision.md](docs/vision.md#licence-du-modèle).

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
- ~4 Gio de disque libre (image ~1,7 Gio, modèle 90 Mio, plus vos données) ; 2 Gio de RAM conseillés ;
- Internet au premier démarrage (image et modèle de la vision), ensuite facultatif ;
- `openssl` pour générer les secrets.

### Vision locale

Au premier démarrage, Vaultia installe le modèle de la vision (SigLIP 2, 90 Mio) dans le volume
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

### Documentation

| Document | Contenu |
| --- | --- |
| [installation.md](docs/installation.md) | installation pas à pas, premier compte, vérifications |
| [configuration.md](docs/configuration.md) | toutes les variables de `.env`, comptes, santé |
| [storage.md](docs/storage.md) | volumes : quoi, où, que se passe-t-il s'ils disparaissent |
| [vision.md](docs/vision.md) | vision locale : modèle, installation, état, hors ligne |
| [reverse-proxy.md](docs/reverse-proxy.md) | HTTPS, proxys, `TRUSTED_PROXIES` |
| [update.md](docs/update.md) | mettre à jour, revenir en arrière (limites) |
| [backup-restore.md](docs/backup-restore.md) | sauvegarde, vérification, restauration |
| [troubleshooting.md](docs/troubleshooting.md) | problèmes courants |
| [reports/](docs/reports/) | rapports de validation de cette distribution |

### Licence

Vaultia est un logiciel **à sources disponibles** (*source-available*), **pas** un logiciel
libre au sens de l'OSI. Usage non commercial : [PolyForm Noncommercial 1.0.0](LICENSE). Tout usage
commercial, professionnel, en service hébergé (SaaS) ou intégré à un produit exige une licence
commerciale : [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).

Composants tiers : l'image embarque ses avis de licence (`/app/THIRD-PARTY-NOTICES.md`). Le modèle
de vision est téléchargé par votre instance depuis sa source officielle : voir
[docs/vision.md § Licence du modèle](docs/vision.md#licence-du-modèle).
