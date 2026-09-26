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
| `BETTER_AUTH_URL` | adresse exacte ouverte dans le navigateur ; `https://…`, ou `http://localhost:<port>` | — |

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
| `VAULTIA_BIND_ADDRESS` | `127.0.0.1` | adresse de l'hôte où Vaultia est publié ; ne jamais mettre `0.0.0.0` sans HTTPS devant |
| `VAULTIA_PORT` | `3000` | port de l'hôte |
| `TRUSTED_PROXIES` | vide | adresse(s) IP/CIDR du reverse proxy, voir [reverse-proxy.md](reverse-proxy.md) |
| `HSTS_MAX_AGE` | vide | en-tête HSTS (secondes), HTTPS seulement |
| `VAULTIA_SUBNET` | `172.30.83.0/24` | sous-réseau interne ; à changer seulement en cas de conflit |

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
