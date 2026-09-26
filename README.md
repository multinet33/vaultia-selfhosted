# Vaultia — auto-hébergement (Docker Compose)

Vaultia est une application web d'inventaire personnel et familial : objets, pièces et
propriétés, véhicules, factures, garanties, documents, valeurs, collections, historique — avec une
**vision locale** (reconnaissance de codes-barres, de texte et d'objets en photo) qui tourne
entièrement sur votre serveur.

Ce dépôt contient **uniquement la distribution** : un fichier Docker Compose, un modèle de
configuration, des scripts de sauvegarde et la documentation. Vaultia lui-même est une image
publiée sur GitHub Container Registry ; rien n'est compilé chez vous.

> **PRÉ-VERSION (bêta, avant 1.0).** Cette distribution est un *candidat* de test : version
> `0.1.0-rc`, pas une version stable. Faites des sauvegardes, attendez-vous à des changements et
> signalez les problèmes. Aucune garantie de migration sans perte entre deux candidats n'est encore
> donnée — voir [docs/update.md](docs/update.md).

## Prérequis

- Linux `amd64` ou `arm64` (ou macOS / Windows avec Docker Desktop) ;
- Docker Engine 24+ avec le plugin Compose v2 (`docker compose version`) ;
- ~4 Gio de disque libre (image ~1,7 Gio, modèle 90 Mio, plus vos données) ; 2 Gio de RAM conseillés ;
- Internet au premier démarrage (image et modèle de la vision), ensuite facultatif ;
- `openssl` pour générer les secrets (présent sur Linux et macOS).

## Démarrage rapide

    git clone https://github.com/multinet33/vaultia-selfhosted.git
    cd vaultia-selfhosted
    cp .env.example .env

Remplir les deux secrets de `.env` :

    openssl rand -hex 24        # → POSTGRES_PASSWORD
    openssl rand -base64 32     # → BETTER_AUTH_SECRET

puis :

    docker compose up -d
    docker compose ps           # postgres et vaultia : « healthy » après ~1 minute

Ouvrir **http://localhost:3000** sur la machine qui héberge Vaultia et **créer le premier compte** :
il devient l'administrateur. L'inscription se ferme ensuite (les comptes suivants rejoignent
Vaultia par invitation) — voir [docs/configuration.md § Comptes](docs/configuration.md#comptes).

Pour y accéder depuis d'autres appareils du réseau, Vaultia exige **HTTPS** (mode hors ligne,
scanner, cookies sécurisés) : placez-le derrière votre reverse proxy — Caddy, nginx, Traefik,
Nginx Proxy Manager, Cloudflare Tunnel… — voir [docs/reverse-proxy.md](docs/reverse-proxy.md).

## Vision locale

Au premier démarrage, Vaultia installe le modèle de la vision (SigLIP 2, 90 Mio) dans le volume
`models`, **en arrière-plan** : l'application est utilisable immédiatement, la reconnaissance
d'objets en photo devient disponible quelques secondes à quelques minutes plus tard. Rien n'est
retéléchargé ensuite (redémarrage, mise à jour). Vérifier :

    docker compose logs vaultia | grep models     # progression de l'installation
    docker compose exec vaultia vaultia vision-status

La dernière ligne doit être **`Vaultia Vision: READY`**. Détail : [docs/vision.md](docs/vision.md).

## Adresses et ports

| Quoi | Où |
| --- | --- |
| Application | `http://localhost:3000` (publiée sur `127.0.0.1` de l'hôte uniquement) |
| Santé | `http://localhost:3000/api/health` → `{"status":"ok","database":"up","vision":"ready"}` |
| PostgreSQL | **non publié** : réseau interne des conteneurs seulement |

## Données persistantes

| Volume | Contenu | Sauvegardé par `scripts/backup.sh` |
| --- | --- | --- |
| `vaultia_postgres-data` | base de données (tout l'inventaire) | **oui** |
| `vaultia_media` | photos, documents, fichiers | **oui** |
| `vaultia_models` | modèle de la vision locale | non (retéléchargé s'il manque) |
| `.env` (fichier) | configuration et secrets | **à sauvegarder à part** |

`docker compose down` conserve les volumes ; **`docker compose down -v` les efface définitivement**
(base et fichiers compris). Détail : [docs/storage.md](docs/storage.md).

## Mise à jour, sauvegarde, restauration

    ./scripts/backup.sh                 # base + fichiers → ./backups/vaultia-<date>/
    git pull                            # nouvelle image candidate épinglée
    docker compose pull && docker compose up -d

Voir [docs/update.md](docs/update.md) et [docs/backup-restore.md](docs/backup-restore.md).

## Documentation

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

## Licence

Vaultia est un logiciel **à sources disponibles** (*source-available*), **pas** un logiciel
libre au sens de l'OSI. Usage non commercial : [PolyForm Noncommercial 1.0.0](LICENSE). Tout usage
commercial, professionnel, en service hébergé (SaaS) ou intégré à un produit exige une licence
commerciale : [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).

Composants tiers : l'image embarque ses avis de licence (`/app/THIRD-PARTY-NOTICES.md`). Le modèle
de vision est téléchargé par votre instance depuis sa source officielle : voir
[docs/vision.md § Licence du modèle](docs/vision.md#licence-du-modèle).
