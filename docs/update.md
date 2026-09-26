# Mise à jour

## Versions distribuées

| Candidat | Source Vaultia | Digest (index multi-architecture) | Nouveautés |
| --- | --- | --- | --- |
| **`0.1.0-rc.2`** (actuel) | `5ca5ffc101fd89204ef533d3b9bf807b64d41a2a` | `sha256:948841a00563434e5ed1a744adb0a58c9d4227af13033b2c683344cf65ccdee8` | `BETTER_AUTH_URL` en `http://` accepté sur une adresse IPv4 privée du réseau local ([configuration.md](configuration.md#http-sur-le-réseau-local)) ; aucune migration de base |
| `0.1.0-rc.1` | `150c5a6678c6065c04e4adfd7d426e003ed11361` | `sha256:61b4d5945735edfdeb0a65577cc40d0f3f68eda372190775095b16df0b3ef0cb` | premier candidat |

## De 0.1.0-rc.1 à 0.1.0-rc.2

1. **Sauvegarder d'abord** : `./scripts/backup.sh` (vérifier `storage_verify=ok` dans le
   `MANIFEST` et les `SHA256SUMS`) ; garder aussi une copie de `.env`.
2. `git pull` (nouvelle ligne `image:` de `compose.yaml`).
3. `docker compose pull && docker compose up -d`.
4. Vérifier : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health` →
   `"vision":"ready"`, `docker compose exec vaultia vaultia vision-status` → `Vaultia Vision: READY`.

**Ne jamais lancer `docker compose down -v`** : `-v` efface les volumes. Une mise à jour
**conserve** les trois volumes, `postgres-data` (base), `media` (fichiers) et `models` (modèle de
vision, non retéléchargé). Aucune variable n'est à ajouter : le HTTP sur le réseau local est
facultatif.

**Validé réellement** avant publication sur une installation `0.1.0-rc.1` existante et
représentative : 3 comptes, 3 Espaces complets et un membre invité, objets, véhicules, documents
du coffre Espace et PERSONAL, 30 médias, valorisations. Sauvegarde ALL faite avant la mise à jour
(`storage_verify=ok`), 54 migrations et aucune en attente. Après la mise à jour, puis après
`restart` et `down`/`up` : les 82 tables sont identiques, fichiers intacts (SHA-256), modèle
conservé, Vision READY, droits Espace et PERSONAL inchangés (un membre ne voit pas les documents
personnels d'un autre, un tiers n'entre pas dans l'Espace).

## Principe

L'image de Vaultia est **épinglée** dans `compose.yaml` par son tag candidat **et** son empreinte
(`ghcr.io/multinet33/vaultia:<version>-rc.<N>@sha256:…`) : l'image lancée est exactement celle
publiée pour le code source indiqué, même si un tag était déplacé. Il n'y a pas de `latest`.

Une mise à jour = une nouvelle ligne `image:` dans ce dépôt. Chaque image candidate porte :

| Référence | Nature |
| --- | --- |
| `sha-<SHA complet du code source>` | immuable : un commit source = une image |
| `<version>-rc.<N>` | immuable, jamais republié |
| `rc` | mobile : dernier candidat (pour information ; `compose.yaml` ne l'utilise pas) |
| étiquette `org.opencontainers.image.revision` | SHA complet du code source |

Vérifier l'image lancée :

    docker compose images vaultia
    docker inspect --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$(docker compose ps -q vaultia)"

## Procédure

1. **Lire** l'historique de ce dépôt (`git log`) : nouvelle image, variables ajoutées.
2. **Sauvegarder** : `./scripts/backup.sh` — noter le dossier créé, c'est le point de retour.
3. **Récupérer la distribution** : `git pull` (votre `.env` n'est pas versionné, il est conservé ;
   comparer avec `.env.example` pour d'éventuelles nouvelles variables).
4. **Tirer et relancer** :

       docker compose pull
       docker compose up -d

   Le nouveau conteneur contrôle la configuration, **applique les migrations de base**
   (`docker compose logs vaultia` : `migrations : prisma migrate deploy`), puis démarre. Le modèle
   de la vision est conservé (volume `models`) : il n'est pas retéléchargé, sauf si la nouvelle
   version en exige un autre.
5. **Vérifier** : `docker compose ps` (`healthy`), `curl http://127.0.0.1:3000/api/health`,
   `docker compose exec vaultia vaultia vision-status`, puis connexion et ouverture de quelques
   objets, photos et documents.

Le navigateur reçoit la nouvelle version au chargement suivant (le mode hors ligne se met à jour
seul).

## En cas d'échec — limites du retour arrière

**Ne jamais** lancer `prisma migrate reset`, `db push` ou modifier la base à la main.

- **Migration en échec** : le conteneur s'arrête (`ÉCHEC des migrations`) et Docker le relance.
  Revenir à la sauvegarde de l'étape 2 : restaurer sur des volumes neufs **avec l'ancienne image**
  ([backup-restore.md](backup-restore.md)).
- **Démarre, mais la version pose problème** :
  - *revenir à l'ancienne image seule* (`git checkout <commit précédent> -- compose.yaml`, puis
    `docker compose up -d`) n'est sûr **que** si les migrations de la nouvelle version sont de
    simples ajouts. Ce n'est pas garanti en général ;
  - *revenir par les données* est toujours possible : restaurer la sauvegarde de l'étape 2 avec
    l'ancienne image. Les modifications faites depuis la mise à jour sont perdues.
- Prisma n'annule jamais une migration : il n'existe pas de retour arrière automatique.

Pendant la bêta, un candidat peut introduire des migrations ; aucune compatibilité descendante
n'est promise entre candidats.

## PostgreSQL

`compose.yaml` fixe PostgreSQL 18 : `docker compose pull` applique les correctifs mineurs. Un
changement de version **majeure** passe par une sauvegarde et une restauration sur des volumes
neufs (procédure non testée pendant la bêta).
