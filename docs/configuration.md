# Configuration

Toute la configuration tient dans `.env` (modèle commenté : [`.env.example`](../.env.example)),
lu par `compose.yaml`. Après une modification : `docker compose up -d` (recrée le conteneur
concerné). Une valeur invalide arrête Vaultia au démarrage avec un message explicite
(`docker compose logs vaultia`) ; aucun secret n'est affiché.

## Obligatoire

| Variable | Rôle | Générer |
| --- | --- | --- |
| `POSTGRES_PASSWORD` | mot de passe de la base (réseau interne seulement) | `openssl rand -hex 24` |
| `BETTER_AUTH_SECRET` | signature des sessions et des liens de partage (≥ 32 caractères) | `openssl rand -base64 32` |
| `BETTER_AUTH_URL` | adresse exacte ouverte dans le navigateur ; `https://…`, `http://localhost:<port>`, ou `http://<IPv4 privée>:<port>` sur le réseau local ([HTTP sur le réseau local](#http-sur-le-réseau-local)) | — |

Ne changez pas `BETTER_AUTH_SECRET` après l'installation : tout le monde est déconnecté, les liens
de partage deviennent invalides et les secrets de webhooks illisibles.

## Comptes

`VAULTIA_SIGNUP_POLICY` décide qui peut **créer un compte** sur l'instance (l'appartenance à un
Espace se gère ensuite dans l'application) :

| Valeur | Effet |
| --- | --- |
| `first-user` (**défaut**) | le premier compte se crée librement ; ensuite, seulement avec une invitation valide |
| `invite` | uniquement avec une invitation valide (même le premier : à réserver à une instance déjà initialisée) |
| `open` | inscription publique — n'importe qui pouvant joindre l'adresse peut créer un compte |

Pour changer : modifier la ligne dans `.env`, puis `docker compose up -d`. Passer à `open` est une
décision délibérée de l'administrateur ; ne jamais l'utiliser sur une instance joignable depuis
Internet sans en mesurer les conséquences.

Il n'y a **pas** de réinitialisation de mot de passe par e-mail dans cette version.

## Réseau

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `VAULTIA_BIND_ADDRESS` | `127.0.0.1` | adresse de l'hôte où Vaultia est publié ; en HTTP sur le réseau local, l'adresse IPv4 privée du serveur ; ne jamais mettre `0.0.0.0` sans HTTPS devant |
| `VAULTIA_PORT` | `3000` | port de l'hôte |
| `TRUSTED_PROXIES` | vide | adresse(s) IP/CIDR du reverse proxy, voir [reverse-proxy.md](reverse-proxy.md) |
| `HSTS_MAX_AGE` | vide | en-tête HSTS (secondes), HTTPS seulement |
| `VAULTIA_SUBNET` | `172.30.83.0/24` | sous-réseau interne ; à changer seulement en cas de conflit |

## HTTP sur le réseau local

Depuis `0.1.0-rc.2`, `BETTER_AUTH_URL` peut être en `http://` pour :

| Destination | Exemple | Usage |
| --- | --- | --- |
| la machine elle-même | `http://localhost:3000`, `http://127.0.0.1:3000` | essai, accès depuis le serveur |
| une adresse IPv4 **privée** (RFC 1918) : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | `http://192.168.1.240:6000` | **réseau local uniquement** |

**Partout ailleurs, HTTPS est obligatoire** : un nom d'hôte (`http://vaultia.lan`), une adresse
publique ou une autre plage arrêtent Vaultia au démarrage (`configuration invalide`). Aucune option
ne lève cette règle.

En HTTP sur le réseau local :

- **rien n'est chiffré** : mots de passe et données circulent en clair sur votre réseau ;
- le navigateur n'accorde pas de *contexte sécurisé* : certaines fonctions sont **indisponibles**,
  notamment le **mode hors ligne** et la **caméra du scanner** de codes-barres (la saisie manuelle
  d'un code et l'analyse d'une photo envoyée restent possibles) ;
- les cookies de session ne sont pas marqués `Secure`, et `HSTS_MAX_AGE` reste refusé ;
- ne **jamais** rendre ce port joignable depuis Internet (aucune redirection de port sur la box) ;
- Vaultia l'affiche au démarrage : `[config] BETTER_AUTH_URL en http sur une adresse privée …`.

**HTTPS reste recommandé** pour bénéficier de toutes les fonctions ([reverse-proxy.md](reverse-proxy.md)).

### Exemple : réseau local, Portainer

L'adresse `192.168.1.240` n'est qu'un **exemple** : utilisez l'adresse IPv4 privée de **votre**
serveur (`ip -4 addr` sous Linux). Vaultia n'a aucune adresse ni aucun port par défaut de ce genre.

    BETTER_AUTH_URL=http://192.168.1.240:6000
    VAULTIA_BIND_ADDRESS=192.168.1.240
    VAULTIA_PORT=6000

plus les deux secrets obligatoires (`POSTGRES_PASSWORD`, `BETTER_AUTH_SECRET`). Vaultia s'ouvre
alors sur `http://192.168.1.240:6000` depuis les appareils du réseau local.

- **Docker Compose** : ces lignes dans `.env`, puis `docker compose up -d`.
- **Portainer** (*Stacks › Add stack*) : dépôt Git `https://github.com/multinet33/vaultia-selfhosted`,
  fichier `compose.yaml`, et ces variables dans *Environment variables* (un `.env` n'est pas lu
  depuis le dépôt). Le nom de la pile préfixe les volumes (`<pile>_postgres-data`, `<pile>_media`,
  `<pile>_models`) : ne le changez pas après l'installation. Les commandes de ce dépôt
  (`scripts/backup.sh`, `vaultia vision-status`) se lancent depuis un terminal sur le serveur.
  Cette utilisation par Portainer n'a pas été testée pendant la bêta.

`VAULTIA_BIND_ADDRESS` doit être une adresse de la machine qui exécute Docker ; sinon le conteneur
ne démarre pas (`cannot assign requested address`).

## Vision et analyses

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `INTELLIGENCE_PROVIDERS` | `zxing-barcode,tesseract-ocr,siglip2-vision,document-rules` | moteurs installés. Tous **locaux**. `open-facts` (bases produit ouvertes, **Internet**) peut être ajouté délibérément ; chaque Espace doit ensuite l'autoriser |
| `INTELLIGENCE_MODELS_PROVISION` | `auto` | `auto` : modèle installé au démarrage ; `off` : installation manuelle, voir [vision.md](vision.md) |
| `INTELLIGENCE_CONTACT` | vide | contact envoyé aux bases produit ouvertes (avec `open-facts` seulement) |

La bêta installe **toute** la vision locale ; il n'existe pas de variante allégée.

## Divers

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `MEDIA_MAX_UPLOAD_BYTES` | `10000000` | taille maximale d'un fichier envoyé (1000 à 50000000 octets) |
| `NOTIFICATIONS_CRON_SECRET` | vide | active `POST /api/notifications/refresh` pour une tâche planifiée externe |
| `WEBHOOK_ALLOW_PRIVATE_NETWORKS` | `false` | autorise les webhooks vers le réseau local |
| `WEBHOOK_SECRET_KEY` | dérivée | clé des secrets de webhooks (≥ 32 caractères) |
| `VAULTIA_IMAGE` | image épinglée de `compose.yaml` | autre image (tests seulement) |
| `POSTGRES_USER`, `POSTGRES_DB` | `vaultia` | à ne pas changer après l'installation |

Aucune télémétrie : ni Vaultia, ni Next.js, ni Prisma, ni ONNX Runtime n'envoient de données.

## Santé

Trois niveaux, à ne pas confondre :

| Niveau | Signe | Sens |
| --- | --- | --- |
| Conteneur démarré | `docker compose ps` : `Up` | le processus tourne |
| Application saine | `docker compose ps` : `(healthy)` ; `GET /api/health` → `200`, `"status":"ok"` | Vaultia répond et joint PostgreSQL : utilisable |
| Vision prête | `/api/health` → `"vision":"ready"` ; `docker compose exec vaultia vaultia vision-status` → `Vaultia Vision: READY` | le modèle est présent, intègre, et une inférence réelle réussit |

`vision` vaut `ready`, `provisioning` (installation en cours), `failed` (dernier essai en échec,
nouvel essai automatique), `missing` (absent ou altéré) ou `disabled` (aucun moteur à modèle).
Il ne change **jamais** le statut HTTP : un modèle en cours de téléchargement ne rend pas Vaultia
`unhealthy` et ne le fait jamais redémarrer en boucle.
