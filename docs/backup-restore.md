# Sauvegarde et restauration

Deux sauvegardes différentes coexistent :

| | Sauvegarde d'un Espace | Sauvegarde de l'instance |
| --- | --- | --- |
| Qui | un propriétaire ou administrateur d'Espace, dans l'application | l'administrateur du serveur |
| Où | Centre de migration › Sauvegarde (archive ZIP téléchargée) | `./scripts/backup.sh` sur le serveur |
| Contenu | un Espace : ses données et fichiers | **toute l'instance** : base PostgreSQL complète + tous les fichiers |
| Restauration | dans un nouvel Espace, sur n'importe quelle instance | sur une instance **neuve** (volumes vides) |

Ce document traite de la **sauvegarde de l'instance**. `scripts/backup.sh` et `scripts/restore.sh`
sont repris à l'identique de `deploy/backup.sh` / `deploy/restore.sh` du dépôt source de Vaultia
(seuls les chemins diffèrent) ; `storage-verify` est la commande de vérification de l'image.

## Quoi sauvegarder

| Élément | Où | Comment |
| --- | --- | --- |
| Base PostgreSQL | volume `vaultia_postgres-data` | `scripts/backup.sh` (`pg_dump`, format custom) |
| Fichiers | volume `vaultia_media` | `scripts/backup.sh` (`tar`) |
| **Configuration et secrets** | `.env` | **à part**, copie chiffrée hors du serveur |
| Personnalisations (proxy) | `compose.override.yaml`, `Caddyfile`, volume `caddy-data` | à part |
| Modèle de la vision | volume `vaultia_models` | **non** : retéléchargé et revérifié au démarrage |

## Faire une sauvegarde

    ./scripts/backup.sh                       # → ./backups/vaultia-<date UTC>/
    ./scripts/backup.sh /mnt/sauvegardes      # autre destination

Vaultia est **arrêté quelques secondes** pendant la copie (base et fichiers au même instant), puis
relancé. Avant la copie, `storage-verify` relit chaque fichier et compare son SHA-256 à la base.

    vaultia-20260926T120000Z/
      database.dump   base (pg_dump)
      media.tar       fichiers
      SHA256SUMS      empreintes des deux
      MANIFEST        date, version, migrations, nombre de fichiers, storage_verify=ok|anomalies

`storage_verify=anomalies` : des fichiers manquaient ou différaient **avant** la copie (la sauvegarde
est faite quand même) ; lire la sortie de `storage-verify`. Copiez ensuite le dossier **hors du
serveur**. Conservez plusieurs générations.

## Vérifier

    cd backups/vaultia-<date>
    sha256sum -c SHA256SUMS            # macOS : shasum -a 256 -c SHA256SUMS

Vérification des fichiers d'une instance en service, à tout moment (lecture seule) :

    docker compose run --rm --no-deps vaultia storage-verify

Code 0 : tout est présent et intègre ; code 1 : liste des fichiers `manquant` / `altéré`.

## Restaurer

Sur une instance **neuve** : même `.env` (au minimum le même `BETTER_AUTH_SECRET` et, s'il était
défini, `WEBHOOK_SECRET_KEY`), une image de Vaultia égale ou plus récente que celle de la
sauvegarde, volumes vides.

    git clone https://github.com/multinet33/vaultia-selfhosted.git && cd vaultia-selfhosted
    cp /chemin/sauvegarde/.env .env
    ./scripts/restore.sh /chemin/vaultia-<date>

Le script contrôle les SHA-256, **refuse** une base ou un stockage non vides (il n'écrase et ne
fusionne jamais rien), restaure la base et les fichiers, démarre Vaultia (migrations éventuelles)
puis exécute `storage-verify`. Le modèle de la vision se réinstalle seul au démarrage.

Pour restaurer sur la même machine après une perte : `docker compose down -v` **seulement** si
vous êtes certain que la sauvegarde est bonne (vérifiée ci-dessus) — cette commande efface la base
et les fichiers actuels.

### Vérification

Après restauration : `docker compose ps` (`healthy`), connexion, ouverture de quelques Espaces,
objets, photos et documents ; `docker compose exec vaultia vaultia vision-status`.
