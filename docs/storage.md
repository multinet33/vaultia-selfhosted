# Stockage persistant

Le conteneur `vaultia` est jetable : il ne contient aucune donnée. Tout ce qui compte vit dans trois
volumes Docker et un fichier.

| Donnée | Volume (projet `vaultia`) | Monté sur | Sauvegarde | Si elle est supprimée |
| --- | --- | --- | --- | --- |
| Base PostgreSQL : comptes, Espaces, propriétés, objets, véhicules, documents (métadonnées), valeurs, historique | `vaultia_postgres-data` | `/var/lib/postgresql` (postgres) | **oui** — `scripts/backup.sh` (`pg_dump`) | **perte de tout l'inventaire** ; seule une sauvegarde le rend |
| Fichiers : photos, documents, miniatures, avatars, archives | `vaultia_media` | `/var/lib/vaultia/media` (vaultia) | **oui** — `scripts/backup.sh` (`tar`, vérifié par `storage-verify`) | **perte de tous les fichiers** ; la base les référence encore, `storage-verify` les signale manquants |
| Modèle de la vision locale (SigLIP 2, 90 Mio) | `vaultia_models` | `/var/lib/vaultia/models` (vaultia) | **non** : artefact d'exécution | aucune donnée perdue : il est retéléchargé et revérifié au démarrage suivant (Internet requis une fois) |
| Configuration et secrets | fichier `.env` | — | **à part** (voir [backup-restore.md](backup-restore.md)) | sans `BETTER_AUTH_SECRET`, les sauvegardes restent restaurables mais sessions, liens de partage et secrets de webhooks sont perdus |

Emplacement d'un volume sur le disque de l'hôte (Linux) :

    docker volume inspect vaultia_media --format '{{ .Mountpoint }}'

Ne copiez pas les dossiers de PostgreSQL à chaud : ce n'est pas une sauvegarde fiable. Utilisez
`scripts/backup.sh`.

## Ce qui efface des données

| Commande | Effet |
| --- | --- |
| `docker compose restart`, `stop`, `start`, `down`, `up -d` | aucun : volumes conservés |
| `docker compose pull` + `up -d` (mise à jour) | aucun : volumes conservés, migrations appliquées |
| `docker compose down -v` | **efface les trois volumes** : base, fichiers et modèle |
| `docker volume rm vaultia_…`, `docker system prune --volumes` | **efface le volume visé** |

Le nom de projet `vaultia` (ligne `name:` de `compose.yaml`) préfixe les volumes : ne le changez
pas après l'installation, sinon Docker crée des volumes neufs et vides.
