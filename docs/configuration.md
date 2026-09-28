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
| une adresse IPv4 **privée** (RFC 1918) : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | `http://192.168.1.100:6080` | **réseau local uniquement** |

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

**HTTPS reste recommandé** pour bénéficier de toutes les fonctions : HTTPS local avec Caddy, sans
domaine ([https.md](https.md)), ou votre reverse proxy ([reverse-proxy.md](reverse-proxy.md)).

### Exemple : réseau local

L'adresse `192.168.1.100` n'est qu'un **exemple** : utilisez l'adresse IPv4 privée de **votre**
serveur (`ip -4 addr` sous Linux). Vaultia n'a aucune adresse ni aucun port par défaut de ce genre.

    BETTER_AUTH_URL=http://192.168.1.100:6080
    VAULTIA_BIND_ADDRESS=192.168.1.100
    VAULTIA_PORT=6080

plus les deux secrets obligatoires (`POSTGRES_PASSWORD`, `BETTER_AUTH_SECRET`). Vaultia s'ouvre
alors sur `http://192.168.1.100:6080` depuis les appareils du réseau local. Les trois valeurs
doivent concorder : même adresse, même port.

`VAULTIA_BIND_ADDRESS` doit être une adresse de la machine qui exécute Docker ; sinon le conteneur
ne démarre pas (`cannot assign requested address`).

**Port** : évitez 6000 et les autres ports que les navigateurs refusent (Chrome, Edge et les
navigateurs Chromium affichent `ERR_UNSAFE_PORT`) ; les guides utilisent 6080.

Pas à pas complets : [docker.md](docker.md) (ligne de commande) et [portainer.md](portainer.md)
(pile Portainer, variables dans l'interface, sauvegarde depuis le serveur).

## Vision et analyses

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `INTELLIGENCE_PROVIDERS` | `zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts` | moteurs **installés**, voir [vision.md](vision.md). Installé ne veut pas dire autorisé : chaque Espace reste « désactivé » tant qu'il n'en décide pas. `open-facts` (bases produit ouvertes, **Internet**) n'est appelé que pour un Espace en mode « externe ». **Vide** (comme dans `.env.example`) : la liste par défaut. Pour installer moins de moteurs, donner une liste réduite |
| `INTELLIGENCE_MODELS_PROVISION` | `auto` | `auto` : modèles installés au démarrage (SigLIP 2 ~90 Mio, E5 ~130 Mio) ; `off` : installation manuelle, voir [vision.md](vision.md) |
| `INTELLIGENCE_CONTACT` | vide | contact envoyé aux bases produit ouvertes (avec `open-facts` seulement) |
| `DOCUMENT_INDEXER` | `inline` | lecture du texte des documents pour la recherche dans leur contenu ; `off` : ce conteneur n'indexe rien |
| `TESSERACT_LANGS` | `fra+eng` | langues de la reconnaissance de texte ; l'image contient `fra` et `eng` |

## Divers

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `MEDIA_MAX_UPLOAD_BYTES` | `10000000` | taille maximale d'un fichier envoyé (1000 à 50000000 octets) |
| `NOTIFICATIONS_CRON_SECRET` | vide | active `POST /api/notifications/refresh` pour une tâche planifiée externe |
| `WEBHOOK_ALLOW_PRIVATE_NETWORKS` | `false` | autorise les webhooks vers le réseau local |
| `WEBHOOK_SECRET_KEY` | dérivée | clé des secrets de webhooks (≥ 32 caractères) |
| `VAULTIA_IMAGE` | image épinglée de `compose.yaml` | autre image (tests, ou canal `…:rc` / `…:stable` suivi par Watchtower : [update.md](update.md#mises-à-jour-automatiques-watchtower-facultatif)) |
| `POSTGRES_USER`, `POSTGRES_DB` | `vaultia` | à ne pas changer après l'installation |

Aucune télémétrie : ni Vaultia, ni Next.js, ni Prisma, ni ONNX Runtime n'envoient de données.

## Référence complète des variables

Chaque variable, son défaut dans cette distribution, son format, ce qui se passe si elle manque ou
est invalide, et comment appliquer un changement. Section générée depuis le catalogue des variables
de Vaultia, contrôlé contre le code.

<!-- env-reference:start — généré par scripts/env-reference.ts depuis lib/config/env-catalog.ts ; ne pas modifier à la main -->

### Récapitulatif

| Variable | Obligatoire | Défaut de la distribution | Lue par |
| --- | --- | --- | --- |
| `DATABASE_URL` | oui | composée par `compose.yaml` depuis `POSTGRES_USER`, `POSTGRES_PASSWORD` et `POSTGRES_DB` | Vaultia |
| `POSTGRES_PASSWORD` | oui | vide dans `.env.example` : à générer | Compose |
| `POSTGRES_USER` | non | `vaultia` | Compose |
| `POSTGRES_DB` | non | `vaultia` | Compose |
| `BETTER_AUTH_SECRET` | oui | vide : à générer (`openssl rand -base64 32`) | Vaultia |
| `BETTER_AUTH_URL` | oui | `http://localhost:3000` dans `.env.example` | Vaultia |
| `VAULTIA_SIGNUP_POLICY` | non | `first-user` | Vaultia |
| `WEBHOOK_SECRET_KEY` | non | dérivée de `BETTER_AUTH_SECRET` | Vaultia |
| `TRUSTED_PROXIES` | non | vide (accès direct) | Vaultia |
| `HSTS_MAX_AGE` | non | vide : aucun en-tête HSTS | Vaultia |
| `VAULTIA_BIND_ADDRESS` | non | `127.0.0.1` | Compose |
| `VAULTIA_PORT` | non | `3000` | Compose |
| `VAULTIA_SUBNET` | non | `172.30.83.0/24` | Compose |
| `VAULTIA_DOMAIN` | non | vide ; exemple de `.env.example` : `vaultia.home.arpa` (HTTPS local, `compose.https.yaml`) | Compose |
| `CADDY_HTTPS_PORT` | non | `443` | Compose |
| `CADDY_IPV4_ADDRESS` | non | `172.30.83.10` | Compose |
| `MEDIA_MAX_UPLOAD_BYTES` | non | `10000000` (10 Mo) | Vaultia |
| `MEDIA_STORAGE_DIR` | non | `/var/lib/vaultia/media` (volume `media`) | Vaultia |
| `INTELLIGENCE_PROVIDERS` | non | `zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts` | Vaultia |
| `INTELLIGENCE_MODELS_PROVISION` | non | `auto` | démarrage de l'image |
| `INTELLIGENCE_CONTACT` | non | vide | Vaultia |
| `TESSERACT_LANGS` | non | `fra+eng` | Vaultia |
| `TESSERACT_PATH` | non | `/usr/bin/tesseract` | Vaultia |
| `TESSDATA_PREFIX` | non | vide : dossier par défaut de Tesseract | Vaultia |
| `INTELLIGENCE_MODELS_DIR` | non | `/var/lib/vaultia/models` (volume `models`) | Vaultia |
| `DOCUMENT_INDEXER` | non | `inline` | Vaultia |
| `WEBHOOK_ALLOW_PRIVATE_NETWORKS` | non | `false` | Vaultia |
| `NOTIFICATIONS_CRON_SECRET` | non | vide : route désactivée (404) | Vaultia |
| `VAULTIA_IMAGE` | non | image publique épinglée (version immuable et empreinte `sha256`) de la distribution | Compose |
| `COMPOSE_FILE` | non | vide : `compose.yaml` seul | Compose |
| `COMPOSE` | non | `docker compose` | scripts de l'hôte |

### Base de données

#### `DATABASE_URL`

- **Obligatoire** : oui — **secret** ; lue par : Vaultia.
- **Défaut de l'application** : aucun (erreur).
- **Défaut de la distribution** : composée par `compose.yaml` depuis `POSTGRES_USER`, `POSTGRES_PASSWORD` et `POSTGRES_DB`.
- **Valeurs, format** : URL `postgresql://` (ou `postgres://`).
- **Rôle** : connexion à PostgreSQL (application et migrations au démarrage).
- **Si absente** : « DATABASE_URL n'est pas définie » : Vaultia ne démarre pas.
- **Si invalide** : « n'est pas une URL valide » ou « doit utiliser le protocole postgresql:// » : Vaultia ne démarre pas. Le message ne cite jamais l'URL (mot de passe).
- **Pourquoi la modifier** : seulement hors Docker (base existante, développement).
- **Pourquoi ne pas la modifier** : en Docker, elle est composée à partir de `POSTGRES_*` : l'écrire à la main désynchronise l'application et la base.
- **Sécurité** : contient le mot de passe de la base.
- **Réseau** : hôte `postgres` sur le réseau interne de Compose ; PostgreSQL n'est pas publié sur l'hôte.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `postgresql://vaultia:0123abcd@postgres:5432/vaultia`

#### `POSTGRES_PASSWORD`

- **Obligatoire** : oui — **secret** ; lue par : Compose.
- **Défaut de l'application** : aucun : Compose refuse de démarrer (`:?`).
- **Défaut de la distribution** : vide dans `.env.example` : à générer.
- **Valeurs, format** : chaîne ; hexadécimal recommandé (`openssl rand -hex 24`) : elle est insérée sans encodage dans `DATABASE_URL`.
- **Rôle** : mot de passe de PostgreSQL, fixé **à la création du volume**, puis utilisé dans `DATABASE_URL`.
- **Si absente** : Compose refuse de démarrer.
- **Si invalide** : un caractère spécial d'URL (`@`, `/`, `:`…) casse `DATABASE_URL` : la connexion échoue.
- **Pourquoi la modifier** : à la première installation seulement.
- **Pourquoi ne pas la modifier** : après la création du volume, la changer ne change pas le mot de passe en base : Vaultia ne se connecte plus.
- **Sécurité** : secret ; `.env` en droits `600`, sauvegardé à part des données.
- **Prise en compte** : sans effet sur une base existante (voir « Pourquoi ne pas la modifier »).
- **Exemple (fictif)** : `0123456789abcdef0123456789abcdef0123456789abcdef`

#### `POSTGRES_USER`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `vaultia`.
- **Valeurs, format** : nom d'utilisateur PostgreSQL.
- **Rôle** : utilisateur PostgreSQL créé avec le volume ; utilisé dans `DATABASE_URL` et par les scripts de sauvegarde.
- **Si absente** : `vaultia`.
- **Si invalide** : refusé par PostgreSQL à la création du volume.
- **Pourquoi la modifier** : rarement : convention locale.
- **Pourquoi ne pas la modifier** : ne s'applique qu'à la création du volume.
- **Prise en compte** : à la création du volume seulement.
- **Exemple (fictif)** : `vaultia`

#### `POSTGRES_DB`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `vaultia`.
- **Valeurs, format** : nom de base PostgreSQL.
- **Rôle** : base créée avec le volume ; utilisée dans `DATABASE_URL` et par les scripts de sauvegarde.
- **Si absente** : `vaultia`.
- **Si invalide** : refusé par PostgreSQL à la création du volume.
- **Pourquoi la modifier** : rarement : convention locale.
- **Pourquoi ne pas la modifier** : ne s'applique qu'à la création du volume.
- **Prise en compte** : à la création du volume seulement.
- **Exemple (fictif)** : `vaultia`

### Comptes, sessions et secrets

#### `BETTER_AUTH_SECRET`

- **Obligatoire** : oui — **secret** ; lue par : Vaultia.
- **Défaut de l'application** : aucun (erreur).
- **Défaut de la distribution** : vide : à générer (`openssl rand -base64 32`).
- **Valeurs, format** : au moins 32 caractères ; la valeur d'exemple est refusée en production.
- **Rôle** : signature des sessions ; matériau des clés dérivées : liens et accès aux partages protégés, observations de marché et, sans `WEBHOOK_SECRET_KEY`, secrets de webhooks.
- **Si absente** : « BETTER_AUTH_SECRET n'est pas définie » : Vaultia ne démarre pas.
- **Si invalide** : « doit contenir au moins 32 caractères » ou « contient encore la valeur d'exemple » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : compromission présumée (rotation).
- **Pourquoi ne pas la modifier** : la changer déconnecte tout le monde, invalide les liens de partage et, sans `WEBHOOK_SECRET_KEY`, rend illisibles les secrets de webhooks (à recréer).
- **Sécurité** : secret maître. Vaultia refuse `BETTER_AUTH_SECRETS` (que la bibliothèque d'authentification ferait passer avant lui).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `k3N0t4R3alS3cr3t-ExampleOnly-0000000000=`

#### `BETTER_AUTH_URL`

- **Obligatoire** : oui ; lue par : Vaultia.
- **Défaut de l'application** : aucun (erreur).
- **Défaut de la distribution** : `http://localhost:3000` dans `.env.example`.
- **Valeurs, format** : URL `https://…` ; `http://` accepté en production seulement vers `localhost`, `127.0.0.1`, `[::1]` ou une adresse IPv4 privée (RFC 1918). Seule l'origine est gardée (le chemin est ignoré).
- **Rôle** : adresse exacte ouverte dans le navigateur : origine de confiance (contrôle d'origine et CSRF), attribut `Secure` des cookies (en https), origine des liens absolus (partages, QR codes, invitations, rapports).
- **Si absente** : « BETTER_AUTH_URL n'est pas définie » : Vaultia ne démarre pas.
- **Si invalide** : « n'est pas une URL valide », « doit utiliser http ou https » ou « doit utiliser https en production » : Vaultia ne démarre pas. Une URL valide mais différente de celle du navigateur fait refuser la connexion (403 `INVALID_ORIGIN`).
- **Pourquoi la modifier** : changement d'adresse, de port, passage en HTTPS.
- **Pourquoi ne pas la modifier** : toute différence avec l'adresse réellement ouverte bloque la connexion et les envois.
- **Sécurité** : en `http://`, cookies non `Secure`, HSTS refusé, pas de contexte sécurisé du navigateur (hors ligne et caméra indisponibles).
- **Réseau** : doit correspondre à ce que le navigateur tape : nom (HTTPS via proxy) ou `http://IP:port` (réseau local).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `https://vaultia.example.lan` ou `http://192.168.1.100:6080`

#### `VAULTIA_SIGNUP_POLICY`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `first-user` en production, `open` en développement.
- **Défaut de la distribution** : `first-user`.
- **Valeurs, format** : `first-user`, `invite` ou `open` (casse et espaces ignorés).
- **Rôle** : qui peut créer un compte : `first-user` (le premier compte, puis invitations), `invite` (invitations seulement), `open` (inscription publique).
- **Si absente** : `first-user` en production.
- **Si invalide** : « VAULTIA_SIGNUP_POLICY doit valoir first-user, invite, open » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : `open` pour une instance hébergée pour d'autres.
- **Pourquoi ne pas la modifier** : `open` ouvre l'inscription à quiconque joint l'instance (avertissement au démarrage) ; `invite` sur une instance vide ne permet de créer aucun compte.
- **Sécurité** : contrôlé côté serveur dans la transaction d'inscription.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `first-user`

#### `WEBHOOK_SECRET_KEY`

- **Obligatoire** : non — **secret** ; lue par : Vaultia.
- **Défaut de l'application** : dérivée de `BETTER_AUTH_SECRET`.
- **Valeurs, format** : au moins 32 caractères.
- **Rôle** : clé qui chiffre les secrets de signature des webhooks enregistrés en base.
- **Si absente** : clé dérivée de `BETTER_AUTH_SECRET` (usage distinct).
- **Si invalide** : « WEBHOOK_SECRET_KEY doit contenir au moins 32 caractères » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : séparer la rotation de `BETTER_AUTH_SECRET` de celle des webhooks.
- **Pourquoi ne pas la modifier** : la changer (ou l'ajouter) rend illisibles les secrets existants : chaque webhook doit recevoir un nouveau secret.
- **Sécurité** : secret.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `Wbk-Example-Key-Not-Real-0000000000000`

### Réseau, proxy et HTTPS

#### `TRUSTED_PROXIES`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : vide (accès direct).
- **Valeurs, format** : adresses IP (v4, v6) ou plages CIDR séparées par des virgules ; `0.0.0.0/0` et `::/0` refusés.
- **Rôle** : adresse(s) sous laquelle Vaultia voit le ou les reverse proxys. Vide : l'adresse de la connexion identifie le client (un `X-Forwarded-For` envoyé par le client est ignoré). Défini : `X-Forwarded-For` est lu de droite à gauche en sautant ces seules adresses ; la première autre est le client. Sert aux limites de connexion, de déverrouillage des partages et de l'API publique, et au journal des sessions.
- **Si absente** : accès direct ; avertissement au démarrage en production (utile seulement derrière un proxy).
- **Si invalide** : « adresse IP ou plage CIDR invalide » ou « plage universelle refusée » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : derrière un reverse proxy (Caddy, autre) : sans elle, tous les clients sont vus sous l'adresse du proxy et partagent un seul compteur.
- **Pourquoi ne pas la modifier** : une plage qui contiendrait des clients leur permettrait de choisir l'adresse sous laquelle ils sont comptés.
- **Sécurité** : déclarer exactement le proxy, rien de plus large.
- **Réseau** : avec la surcouche Caddy de la distribution : `172.30.83.10`.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `172.30.83.10` ou `172.30.83.10,203.0.113.0/24`

#### `HSTS_MAX_AGE`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : vide : aucun en-tête HSTS.
- **Valeurs, format** : entier, secondes, de 0 à 63072000 (2 ans) ; en-tête `max-age=<n>` sans `includeSubDomains` ni `preload`.
- **Rôle** : en-tête `Strict-Transport-Security` sur les réponses de Vaultia.
- **Si absente** : aucun HSTS.
- **Si invalide** : « HSTS_MAX_AGE doit être un nombre de secondes entre 0 et 63072000 » ou « exige une BETTER_AUTH_URL en https » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : instance servie **uniquement** en HTTPS, certificat de confiance sur tous les appareils.
- **Pourquoi ne pas la modifier** : un navigateur qui a reçu HSTS refuse ensuite tout accès en http à ce nom : ne jamais l'activer tant que l'accès http reste utilisé, ni avec un certificat pas encore approuvé partout.
- **Sécurité** : HSTS n'est jamais envoyé en http (refusé au démarrage).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `31536000`

#### `VAULTIA_BIND_ADDRESS`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `127.0.0.1`.
- **Valeurs, format** : adresse IP de l'hôte.
- **Rôle** : adresse de l'hôte où le port de Vaultia est publié. `127.0.0.1` : cette machine seulement ; l'adresse LAN de l'hôte : tout le réseau local ; `0.0.0.0` : toutes les interfaces.
- **Si absente** : `127.0.0.1`.
- **Si invalide** : adresse absente de l'hôte : « cannot assign requested address », le conteneur ne démarre pas.
- **Pourquoi la modifier** : accès depuis les autres appareils du réseau local (HTTP LAN).
- **Pourquoi ne pas la modifier** : `0.0.0.0` sur une machine exposée à Internet publie Vaultia sur Internet.
- **Réseau** : ignorée avec une surcouche de proxy qui ne publie aucun port de Vaultia.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `192.168.1.100`

#### `VAULTIA_PORT`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `3000`.
- **Valeurs, format** : port TCP de l'hôte.
- **Rôle** : port de l'hôte correspondant (le conteneur écoute toujours sur 3000).
- **Si absente** : `3000`.
- **Si invalide** : port occupé : le conteneur ne démarre pas.
- **Pourquoi la modifier** : port déjà utilisé, convention locale (`6080`).
- **Pourquoi ne pas la modifier** : certains ports sont refusés par les navigateurs (6000 : `ERR_UNSAFE_PORT` sous Chromium) ; `BETTER_AUTH_URL` doit suivre.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `6080`

#### `VAULTIA_SUBNET`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `172.30.83.0/24`.
- **Valeurs, format** : plage IPv4 CIDR.
- **Rôle** : sous-réseau interne du réseau Compose de Vaultia.
- **Si absente** : `172.30.83.0/24`.
- **Si invalide** : chevauchement avec un réseau existant : Compose refuse de créer le réseau.
- **Pourquoi la modifier** : conflit avec un réseau existant de l'hôte ou du LAN.
- **Pourquoi ne pas la modifier** : l'adresse du proxy (`CADDY_IPV4_ADDRESS`) et `TRUSTED_PROXIES` doivent suivre.
- **Prise en compte** : `docker compose down` puis `up -d` (le réseau est recréé ; les volumes restent).
- **Exemple (fictif)** : `172.31.99.0/24`

#### `VAULTIA_DOMAIN`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : aucun : obligatoire avec la surcouche Caddy.
- **Défaut de la distribution** : vide ; exemple de `.env.example` : `vaultia.home.arpa` (HTTPS local, `compose.https.yaml`).
- **Valeurs, format** : nom d'hôte.
- **Rôle** : nom servi par Caddy ; doit être l'hôte de `BETTER_AUTH_URL`.
- **Si absente** : sans surcouche Caddy : sans effet ; avec : Compose refuse de démarrer.
- **Si invalide** : nom différent de `BETTER_AUTH_URL` : connexion refusée (origine).
- **Pourquoi la modifier** : mise en place de HTTPS par Caddy.
- **Pourquoi ne pas la modifier** : changer le nom exige de changer `BETTER_AUTH_URL` et, en local, le DNS et la confiance des appareils.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `vaultia.home.arpa`

#### `CADDY_HTTPS_PORT`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `443`.
- **Valeurs, format** : port TCP de l'hôte.
- **Rôle** : port HTTPS publié par Caddy.
- **Si absente** : `443`.
- **Si invalide** : port occupé : Caddy ne démarre pas.
- **Pourquoi la modifier** : port 443 déjà utilisé.
- **Pourquoi ne pas la modifier** : un autre port doit figurer dans `BETTER_AUTH_URL` (`https://nom:8443`).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `8443`

#### `CADDY_IPV4_ADDRESS`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : `172.30.83.10`.
- **Valeurs, format** : adresse IPv4 dans `VAULTIA_SUBNET`.
- **Rôle** : adresse fixe de Caddy sur le réseau interne : celle que Vaultia voit, donc celle de `TRUSTED_PROXIES`.
- **Si absente** : `172.30.83.10`.
- **Si invalide** : hors du sous-réseau : Compose refuse de démarrer.
- **Pourquoi la modifier** : avec `VAULTIA_SUBNET`.
- **Pourquoi ne pas la modifier** : `TRUSTED_PROXIES` doit suivre, sinon tous les clients partagent l'adresse du proxy.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `172.31.99.10`

#### `COMPOSE_FILE`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : vide : `compose.yaml` seul.
- **Valeurs, format** : fichiers Compose séparés par `:`.
- **Rôle** : active la surcouche HTTPS local (`compose.yaml:compose.https.yaml`) : Caddy, autorité locale, Vaultia joignable seulement par Caddy. Lue par Compose (et donc par `scripts/backup.sh`) depuis `.env`.
- **Si absente** : installation standard : HTTP (boucle locale ou réseau local) ou reverse proxy existant.
- **Si invalide** : fichier introuvable : Compose refuse de démarrer.
- **Pourquoi la modifier** : HTTPS sur le réseau local sans domaine ni Internet (caméra du scanner, mode hors ligne, cookies `Secure`).
- **Pourquoi ne pas la modifier** : exige un DNS local et l'installation du certificat racine public de Caddy sur chaque appareil.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `compose.yaml:compose.https.yaml`

### Fichiers et envois

#### `MEDIA_MAX_UPLOAD_BYTES`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `10000000` (10 Mo).
- **Valeurs, format** : entier, octets, de 1000 à 50000000.
- **Rôle** : taille maximale d'un fichier envoyé (photos, documents, justificatifs, avatar).
- **Si absente** : 10 Mo.
- **Si invalide** : « MEDIA_MAX_UPLOAD_BYTES doit être un nombre d'octets entre 1000 et 50000000 » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : documents numérisés plus lourds.
- **Pourquoi ne pas la modifier** : un fichier est lu en mémoire avant contrôle : une limite haute augmente la mémoire nécessaire. Les archives de restauration ont leur propre limite.
- **Réseau** : un proxy devant Vaultia doit accepter au moins cette taille de requête.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `20000000`

#### `MEDIA_STORAGE_DIR`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `storage/media` (relatif au dossier de l'application).
- **Défaut de la distribution** : `/var/lib/vaultia/media` (volume `media`).
- **Fixée par l'image** : Compose ne la transmet pas ; une valeur dans `.env` est ignorée.
- **Valeurs, format** : chemin ; jamais sous `public/`.
- **Rôle** : dossier des fichiers (photos, documents).
- **Si absente** : chemin par défaut.
- **Si invalide** : « ne doit pas être dans public/ » ou « n'est pas accessible en écriture » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : hors Docker seulement.
- **Pourquoi ne pas la modifier** : dans l'image, c'est le point de montage du volume `media` ; Compose ne la transmet pas.
- **Sécurité** : jamais servi directement : chaque fichier passe par un contrôle d'accès.
- **Prise en compte** : hors Docker : redémarrer (et déplacer les fichiers).
- **Exemple (fictif)** : `/var/lib/vaultia/media`

### Vaultia Vision (analyse locale et externe)

#### `INTELLIGENCE_PROVIDERS`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : vide : aucun moteur (capacités « À venir »).
- **Défaut de la distribution** : `zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts`.
- **Valeurs, format** : liste ordonnée (préférence) parmi `zxing-barcode`, `tesseract-ocr`, `siglip2-vision`, `e5-embeddings`, `document-rules`, `open-facts` ; doublons ignorés.
- **Rôle** : moteurs **installés**. Installé ne veut pas dire autorisé : chaque Espace choisit son mode (désactivé par défaut, local, externe). `open-facts` (Internet) n'est appelé qu'en mode externe, jamais en mode local.
- **Si absente** : absente **ou vide** (`INTELLIGENCE_PROVIDERS=` de `.env.example`) : liste par défaut de la distribution. Aucun traitement n'a lieu tant qu'un Espace ne l'autorise : le mode de chaque Espace est « désactivé » par défaut. Pour ne rien installer, donner une liste réduite (voir l'exemple).
- **Si invalide** : « INTELLIGENCE_PROVIDERS : moteur inconnu » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : retirer un moteur (pas de téléchargement du modèle de vision, pas de service externe possible).
- **Pourquoi ne pas la modifier** : retirer `siglip2-vision` supprime l'identification visuelle ; retirer `e5-embeddings`, la recherche par le sens (la recherche lexicale reste).
- **Réseau** : `siglip2-vision` et `e5-embeddings` : téléchargement unique de leur modèle (~90 Mio et ~130 Mio) au premier démarrage ; `open-facts` : Internet, en mode externe seulement (seul le code EAN/UPC/GTIN est transmis).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `zxing-barcode,tesseract-ocr,document-rules`

#### `INTELLIGENCE_MODELS_PROVISION`

- **Obligatoire** : non ; lue par : démarrage de l'image.
- **Défaut de l'application** : `auto`.
- **Valeurs, format** : `auto` ou `off`.
- **Rôle** : `auto` : les modèles manquants sont installés en arrière-plan au démarrage (nouvel essai espacé en cas d'échec). `off` : rien n'est téléchargé ; installation manuelle `vaultia models-provision`.
- **Si absente** : `auto`.
- **Si invalide** : « INTELLIGENCE_MODELS_PROVISION doit valoir auto ou off » : Vaultia ne démarre pas (contrôlé aussi par `check-config`).
- **Pourquoi la modifier** : `off` sur une machine sans Internet (modèle copié à la main dans le volume `models`).
- **Pourquoi ne pas la modifier** : `off` sans modèle installé : identification visuelle « Mal configurée ».
- **Réseau** : `auto` télécharge depuis Hugging Face (une fois, puis vérifie l'empreinte).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `off`

#### `INTELLIGENCE_CONTACT`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : vide.
- **Valeurs, format** : texte libre (adresse e-mail ou URL de contact).
- **Rôle** : contact ajouté à l'identification (`User-Agent`) des requêtes vers Open Products Facts / Open Food Facts, comme ces bases le demandent.
- **Si absente** : requêtes identifiées sans contact.
- **Si invalide** : aucune validation.
- **Pourquoi la modifier** : usage régulier de la recherche produit externe.
- **Pourquoi ne pas la modifier** : la valeur part vers un tiers sur Internet : n'y mettre rien de privé.
- **Sécurité** : transmise à un service externe.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `admin@example.org`

#### `TESSERACT_LANGS`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `fra+eng`.
- **Valeurs, format** : codes de langues Tesseract joints par `+`.
- **Rôle** : langues de la reconnaissance de texte (étiquettes, justificatifs).
- **Si absente** : `fra+eng`.
- **Si invalide** : format refusé au démarrage. Une langue bien formée mais **non installée** n'est pas détectée au démarrage : l'étape de lecture du texte échoue à l'usage. L'image contient `fra` et `eng`.
- **Pourquoi la modifier** : hors Docker, avec d'autres langues installées.
- **Pourquoi ne pas la modifier** : dans l'image, seules `fra` et `eng` sont présentes.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `fra+eng`

#### `TESSERACT_PATH`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `tesseract` (cherché dans le PATH).
- **Défaut de la distribution** : `/usr/bin/tesseract`.
- **Fixée par l'image** : Compose ne la transmet pas ; une valeur dans `.env` est ignorée.
- **Valeurs, format** : nom ou chemin d'exécutable (lettres, chiffres, `_./-`) ; jamais une commande.
- **Rôle** : exécutable Tesseract 5, lancé avec des arguments fixes.
- **Si absente** : `tesseract`.
- **Si invalide** : format refusé au démarrage ; un chemin inexistant rend la reconnaissance de texte « Mal configurée ».
- **Pourquoi la modifier** : hors Docker seulement.
- **Pourquoi ne pas la modifier** : fixée par l'image ; Compose ne la transmet pas.
- **Prise en compte** : hors Docker : redémarrer.
- **Exemple (fictif)** : `/usr/bin/tesseract`

#### `TESSDATA_PREFIX`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : vide : dossier par défaut de Tesseract.
- **Fixée par l'image** : Compose ne la transmet pas ; une valeur dans `.env` est ignorée.
- **Valeurs, format** : chemin du dossier des langues Tesseract.
- **Rôle** : transmise telle quelle à Tesseract.
- **Si absente** : dossier par défaut de Tesseract.
- **Si invalide** : aucune validation : Tesseract échoue à l'usage.
- **Pourquoi la modifier** : hors Docker, langues installées ailleurs.
- **Pourquoi ne pas la modifier** : inutile dans l'image.
- **Prise en compte** : hors Docker : redémarrer.
- **Exemple (fictif)** : `/usr/share/tesseract-ocr/5/tessdata`

#### `INTELLIGENCE_MODELS_DIR`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `storage/models`.
- **Défaut de la distribution** : `/var/lib/vaultia/models` (volume `models`).
- **Fixée par l'image** : Compose ne la transmet pas ; une valeur dans `.env` est ignorée.
- **Valeurs, format** : chemin ; jamais sous `public/`.
- **Rôle** : dossier des modèles téléchargés (SigLIP 2, E5).
- **Si absente** : chemin par défaut.
- **Si invalide** : « ne doit pas être dans public/ » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : hors Docker seulement.
- **Pourquoi ne pas la modifier** : dans l'image, point de montage du volume `models` ; Compose ne la transmet pas.
- **Prise en compte** : hors Docker : redémarrer.
- **Exemple (fictif)** : `/var/lib/vaultia/models`

### Recherche dans les documents

#### `DOCUMENT_INDEXER`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `inline`.
- **Valeurs, format** : `inline` ou `off`.
- **Rôle** : indexation du texte des documents (recherche dans le contenu) par le processus web.
- **Si absente** : `inline`.
- **Si invalide** : « DOCUMENT_INDEXER doit valoir inline ou off » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : `off` : machine très modeste, recherche dans le contenu non souhaitée.
- **Pourquoi ne pas la modifier** : `off` : le contenu des nouveaux documents n'est plus cherchable (l'image ne fournit aucun autre indexeur).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `inline`

### Webhooks

#### `WEBHOOK_ALLOW_PRIVATE_NETWORKS`

- **Obligatoire** : non ; lue par : Vaultia.
- **Défaut de l'application** : `false`.
- **Valeurs, format** : `true`/`false` (ou `1`/`0`, casse ignorée).
- **Rôle** : autorise les webhooks vers le réseau local (RFC 1918, CGNAT, IPv6 ULA) : Home Assistant, n8n… Boucle locale, lien local et métadonnées cloud restent interdits.
- **Si absente** : réseau local interdit.
- **Si invalide** : « WEBHOOK_ALLOW_PRIVATE_NETWORKS doit valoir true ou false » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : automatisations locales.
- **Pourquoi ne pas la modifier** : un membre administrateur d'un Espace pourrait alors faire appeler des services internes du LAN.
- **Sécurité** : décision de l'administrateur du serveur, pas d'un Espace (protection SSRF).
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : `true`

### Notifications planifiées

#### `NOTIFICATIONS_CRON_SECRET`

- **Obligatoire** : non — **secret** ; lue par : Vaultia.
- **Défaut de l'application** : vide : route désactivée (404).
- **Valeurs, format** : au moins 32 caractères ; la valeur d'exemple est refusée.
- **Rôle** : ouvre `POST /api/notifications/refresh` (en-tête `Authorization: Bearer <secret>`) pour un balayage planifié des échéances de tous les Espaces.
- **Si absente** : route fermée (les notifications restent calculées à l'usage).
- **Si invalide** : « doit contenir au moins 32 caractères » ou « contient encore la valeur d'exemple » : Vaultia ne démarre pas.
- **Pourquoi la modifier** : tâche planifiée externe (cron).
- **Pourquoi ne pas la modifier** : inutile sans tâche planifiée.
- **Sécurité** : secret ; comparaison en temps constant.
- **Prise en compte** : recréer le conteneur (`docker compose up -d`).
- **Exemple (fictif)** : 64 caractères hexadécimaux (`openssl rand -hex 32`)

### Distribution Docker (Compose, Caddy, image)

#### `VAULTIA_IMAGE`

- **Obligatoire** : non ; lue par : Compose.
- **Défaut de l'application** : image publique épinglée (version immuable et empreinte `sha256`) de la distribution.
- **Valeurs, format** : référence d'image OCI (`ghcr.io/multinet33/vaultia:<version>@sha256:<empreinte>`).
- **Rôle** : image lancée par la distribution publique `vaultia-selfhosted`.
- **Si absente** : l'image épinglée par la distribution.
- **Si invalide** : `docker compose pull` échoue.
- **Pourquoi la modifier** : canal `rc` / `stable` (mises à jour automatiques), ou version précise.
- **Pourquoi ne pas la modifier** : un canal mobile applique les migrations d'une nouvelle version sans intervention : faire une sauvegarde avant.
- **Prise en compte** : `docker compose pull` puis `up -d`.
- **Exemple (fictif)** : `ghcr.io/multinet33/vaultia:rc`

### Scripts de sauvegarde

#### `COMPOSE`

- **Obligatoire** : non ; lue par : scripts de l'hôte.
- **Défaut de l'application** : `docker compose`.
- **Valeurs, format** : commande Compose (fichiers `-f`, projet `-p`).
- **Rôle** : commande utilisée par `backup.sh` et `restore.sh` (variable du shell de l'hôte, pas du `.env`).
- **Si absente** : `docker compose`.
- **Si invalide** : les scripts échouent.
- **Pourquoi la modifier** : surcouche (`-f compose.override.yaml`) ou nom de projet (`-p`).
- **Pourquoi ne pas la modifier** : doit viser les mêmes fichiers et le même projet que l'installation.
- **Prise en compte** : au prochain lancement du script.
- **Exemple (fictif)** : `COMPOSE="docker compose -f compose.yaml -f compose.override.yaml"`

### Variables internes (ne pas régler)

Lues par le code, mais fixées par l'image, réservées à la construction, au développement ou aux tests.

- `NODE_ENV` : `production` dans l'image : https exigé, secret d'exemple refusé, `DEV_LAN_ORIGIN` refusée, inscription `first-user` par défaut. Ne pas modifier.
- `PORT` : 3000 dans l'image (écoute du serveur de l'image et HEALTHCHECK). Le port publié se règle par `VAULTIA_PORT`.
- `HOSTNAME` : `0.0.0.0` dans l'image (écoute de toutes les interfaces du conteneur).
- `NEXT_RUNTIME` : posée par Next.js.
- `NEXT_TELEMETRY_DISABLED` : `1` dans l'image (télémétrie Next.js coupée).
- `CHECKPOINT_DISABLE` : `1` dans l'image (télémétrie Prisma coupée).
- `ORT_DISABLE_TELEMETRY` : `1` dans l'image (télémétrie ONNX Runtime coupée).
- `OMP_THREAD_LIMIT` : imposée à `1` pour le sous-processus Tesseract ; la valeur de l'hôte n'est jamais lue.
- `PATH` : transmis au sous-processus Tesseract.
- `EVENT_WORKER` : `inline` (défaut). `external` n'est pas pris en charge par l'image (aucun processus de traitement fourni).
- `INTELLIGENCE_WORKER` : `inline` (défaut). `external` n'est pas pris en charge par l'image.
- `DEV_LAN_ORIGIN` : développement seulement (origine LAN de `next dev`) ; refusée en production.
- `VAULTIA_RELEASE` : argument de construction de l'image officielle (version publiée) ; contrôlé avec le changelog.
- `VAULTIA_RELEASE_VERSION` : figée à la construction ; sans effet au lancement du conteneur.
- `VAULTIA_REVISION` : argument de construction (label OCI).
- `VAULTIA_SOURCE` : argument de construction (label OCI).
- `VAULTIA_CREATED` : argument de construction (label OCI).
- `NODE_IMAGE` : argument de construction (image Node de base).
- `TEST_DATABASE_URL` : tests d'intégration (base dont le nom finit par `_test`).
- `E2E_PORT` : tests de bout en bout.
- `CI` : tests.
- `IMAGE_SERVER_REQUIRED` : tests : exige le build de production pour le test du serveur de l'image.
- `VISION_MODEL_REQUIRED` : tests : exige le modèle de vision.
- `DEPLOY_URL` : tests de déploiement.
- `DEPLOY_HOST_RESOLVER` : tests de déploiement.
- `DEPLOY_IGNORE_HTTPS_ERRORS` : tests de déploiement.
- `SEED_DEMO_PASSWORD` : données de démonstration (développement).
- `VAULTIA_ALLOW_DEV_SEED` : données de démonstration (développement) ; refusées en production.
- `POSTGRES_PORT` : PostgreSQL de développement (`docker-compose.yml`).

### Variables sans effet sur Vaultia

- `TZ` : non lue par Vaultia : le fuseau horaire se règle par Espace (Réglages).
- `COMPOSE_PROJECT_NAME` : lue par Docker Compose (nom du projet, prioritaire sur `name:`), jamais par Vaultia. Utile pour installer deux instances sur une même machine.

### Variables refusées au démarrage

Lues d'elles-mêmes par la bibliothèque d'authentification, elles contourneraient les contrôles de Vaultia : leur présence arrête le démarrage.

- `BETTER_AUTH_TRUSTED_ORIGINS` : ajouterait des origines de confiance hors de `BETTER_AUTH_URL` (contrôle d'origine et CSRF).
- `BETTER_AUTH_SECRETS` : remplacerait `BETTER_AUTH_SECRET` pour la signature des sessions, sans ses contrôles.

<!-- env-reference:end -->

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
