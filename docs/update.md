# Mise à jour

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
