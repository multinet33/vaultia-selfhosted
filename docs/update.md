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
| `rc` | mobile : dernier candidat (`compose.yaml` ne l'utilise pas par défaut ; voir [Suivi automatique](#suivi-automatique-des-candidats-watchtower-facultatif)) |
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

## Suivi automatique des candidats (Watchtower, facultatif)

Deux modes, au choix de l'administrateur. **Le mode A est le défaut et reste recommandé.**

| | A — épinglé (défaut) | B — suivi automatique `:rc` |
| --- | --- | --- |
| `VAULTIA_IMAGE` | vide (non défini) | `ghcr.io/multinet33/vaultia:rc` |
| Image lancée | version + digest épinglés dans `compose.yaml` | dernier candidat publié, quel qu'il soit |
| Quand elle change | quand ce dépôt change sa ligne `image:` **et** que vous redéployez | dès que le tag `rc` est déplacé, au prochain passage de Watchtower |
| Sauvegarde avant mise à jour | faite par vous (§ Procédure) | **aucune** : Watchtower n'en fait pas |
| Caractère | sûr, reproductible, contrôlé par l'administrateur | pratique pour suivre la bêta, moins prudent |

### Ce que fait `compose.yaml`

Le seul service `vaultia` porte deux étiquettes :

    com.centurylinklabs.watchtower.enable=true
    com.centurylinklabs.watchtower.scope=vaultia

**Elles n'activent rien à elles seules** : il faut qu'un administrateur fasse tourner un Watchtower
compatible, lancé avec le filtrage par étiquette (`WATCHTOWER_LABEL_ENABLE=true`) et la portée
`vaultia` (`--scope vaultia`). En mode A, l'image est désignée par son digest : il n'existe aucune
image plus récente pour cette référence, le conteneur ne bouge pas.

**PostgreSQL n'est volontairement pas étiqueté** : il reste hors de la portée `vaultia`, et un
changement de version majeure de PostgreSQL ne doit jamais se faire automatiquement
([§ PostgreSQL](#postgresql)). Aucun accès au socket Docker n'est donné à la pile Vaultia : seul le
conteneur Watchtower, exploité à part, en a besoin.

### Activer le mode B

1. Sauvegarde ALL vérifiée (`./scripts/backup.sh`, `storage_verify=ok`) et copie de `.env`.
2. Dans `.env` : `VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc`, puis
   `docker compose pull && docker compose up -d`. Vérifier : `docker compose images vaultia`.
3. Lancer un Watchtower **séparé** (autre dossier ou autre pile Portainer), par exemple :

       services:
         watchtower-vaultia:
           image: containrrr/watchtower:latest
           container_name: watchtower-vaultia
           restart: unless-stopped
           volumes:
             - /var/run/docker.sock:/var/run/docker.sock
           environment:
             TZ: Europe/Paris
             WATCHTOWER_LABEL_ENABLE: "true"
             WATCHTOWER_CLEANUP: "true"
           command:
             - "--schedule"
             - "0 0 * * * *"
             - "--scope"
             - "vaultia"

   `--schedule` prend une expression cron **à six champs, secondes comprises**
   (`secondes minutes heures jour mois jour-de-semaine`) : `0 0 * * * *` = une vérification par
   heure, à la minute 00 (et non « à minuit », comme le lirait un cron à cinq champs).
   `--scope vaultia` et `WATCHTOWER_LABEL_ENABLE` limitent ce Watchtower au seul conteneur
   Vaultia ; il ne touche ni PostgreSQL ni vos autres conteneurs.

Quand la publication de Vaultia déplace `rc` vers un nouveau candidat (image immuable), Watchtower
voit le digest changer, tire l'image et **recrée uniquement le conteneur Vaultia**, avec la même
configuration et les mêmes volumes. PostgreSQL continue de tourner.

Pour revenir au mode A : vider `VAULTIA_IMAGE` et redéployer. Attention : si le candidat suivi
est plus récent que l'image épinglée et a appliqué des migrations, revenir à l'image épinglée n'est
pas sûr (voir ci-dessous) ; attendre que ce dépôt épingle une version au moins aussi récente.

### Sécurité des mises à jour en mode B — à lire avant d'activer

- Un nouveau candidat est **tiré et démarré automatiquement**, sans vous, à n'importe quelle heure
  du planning.
- Au démarrage, Vaultia **applique les migrations de base** : une mise à jour automatique peut donc
  modifier le schéma de la base.
- Watchtower **ne fait aucune Sauvegarde ALL** avant de mettre à jour, et **n'offre aucun retour
  arrière de la base**. Les sauvegardes restent **votre responsabilité** : planifier
  `./scripts/backup.sh` régulièrement (et garder `.env`) est indispensable.
- Après une migration, relancer l'image précédente ne suffit pas forcément : le retour arrière peut
  exiger la **restauration d'une Sauvegarde ALL antérieure à la mise à jour**, avec l'ancienne
  image ([§ En cas d'échec](#en-cas-déchec--limites-du-retour-arrière),
  [backup-restore.md](backup-restore.md)). Les modifications faites depuis sont alors perdues.
- Les volumes persistants ne doivent **jamais** être supprimés lors d'une mise à jour ; **ne jamais
  utiliser `docker compose down -v`** comme procédure de mise à jour.
- PostgreSQL ne doit pas être mis à jour par ce Watchtower : ne lui ajoutez pas ces étiquettes.

### Pile Portainer depuis Git

Une pile Portainer peut être déployée directement depuis
`https://github.com/multinet33/vaultia-selfhosted.git` ([portainer.md](portainer.md)). Pour le
mode B, **ne modifiez pas `compose.yaml`** : gardez le fichier contrôlé par Git et ajoutez
simplement, dans les variables d'environnement de la pile :

    VAULTIA_IMAGE=ghcr.io/multinet33/vaultia:rc

puis **Update the stack** (avec **Re-pull image**). Le Watchtower ci-dessus vit de préférence dans
**une autre pile** (pile de maintenance), pas dans celle de Vaultia :

- pile `vaultia` → Vaultia + PostgreSQL (ce dépôt, sans socket Docker) ;
- pile de maintenance → Watchtower (seul à monter `/var/run/docker.sock`).

Watchtower recrée le conteneur Vaultia hors de Portainer ; Portainer continue de l'afficher dans la
pile. Un **Pull and redeploy** ultérieur de la pile garde la variable `VAULTIA_IMAGE` et reste sur
`:rc`.

## PostgreSQL

`compose.yaml` fixe PostgreSQL 18 : `docker compose pull` applique les correctifs mineurs. Un
changement de version **majeure** passe par une sauvegarde et une restauration sur des volumes
neufs (procédure non testée pendant la bêta).
