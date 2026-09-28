# HTTPS

Vaultia fonctionne en HTTP sur votre réseau local, mais certaines fonctions du navigateur exigent
HTTPS. Trois façons d'installer Vaultia, au choix :

| Scénario | Adresse | Pour qui | Ce qu'il faut |
| --- | --- | --- | --- |
| **A. HTTP sur le réseau local** | `http://192.168.1.100:6080` | essai, usage simple | rien de plus ([configuration.md](configuration.md#http-sur-le-réseau-local)) |
| **B. HTTPS local avec Caddy** (ci-dessous) | `https://vaultia.home.arpa` | la maison, sans domaine Internet | un DNS local, installer une autorité sur chaque appareil |
| **C. HTTPS avec votre domaine ou votre reverse proxy** | `https://vaultia.example.com` | vous avez déjà un proxy, un domaine, un tunnel | [reverse-proxy.md](reverse-proxy.md) |

Aucun des trois ne demande d'ouvrir un port sur votre box, ni de compte externe. Le scénario A reste
celui par défaut ; B et C s'ajoutent sans rien casser.

## Pourquoi HTTPS

En HTTP sur une adresse du réseau local, le navigateur ne considère pas la page comme un *contexte
sécurisé*. Vérifié avec Vaultia :

- **caméra du scanner** de codes-barres : `navigator.mediaDevices` n'existe qu'en contexte sécurisé ;
  en HTTP, saisie manuelle d'un code et analyse d'une photo envoyée restent possibles ;
- **mode hors ligne** : il repose sur un *service worker*, réservé aux contextes sécurisés ;
- **cookies de session `Secure`** (nom `__Secure-…`) : envoyés seulement en HTTPS ;
- **chiffrement** : en HTTP, mots de passe et données circulent en clair sur votre réseau.

`http://localhost` est une exception des navigateurs (contexte sécurisé sur la machine elle-même) :
elle ne vaut pas pour les autres appareils.

## B. HTTPS local avec Caddy

Caddy, un reverse proxy libre, se place devant Vaultia sur votre serveur. Il termine TLS avec **sa
propre autorité de certification locale** (`tls internal`) : aucun domaine Internet, aucun
Let's Encrypt, aucun appel extérieur. Vaultia ne gère aucun certificat.

    appareil → https://vaultia.home.arpa → DNS local → serveur : Caddy (port 443)
             → réseau Docker interne → Vaultia (port 3000, non publié)

Fichiers de ce dépôt : [`compose.https.yaml`](../compose.https.yaml) (surcouche Compose : service
`caddy`, volumes `caddy-data` et `caddy-config`, Vaultia n'est plus publié sur l'hôte) et
[`https.Caddyfile`](../https.Caddyfile).

Deux façons de l'activer, selon la manière dont vous gérez Vaultia :

| Vous utilisez | Activation | Détail |
| --- | --- | --- |
| **Docker Compose en ligne de commande** | `COMPOSE_FILE=compose.yaml:compose.https.yaml` dans `.env` | étapes 3 et 4 ci-dessous |
| **une pile Portainer** (*Repository*) | Compose path **`compose.portainer-https.yaml`** : fichier autonome, identique à la fusion des deux fichiers (vérifié par la CI) | [portainer.md § 13](portainer.md#13-https-local-avec-portainer-caddy) |

`COMPOSE_FILE` n'a **aucun effet** dans une pile Portainer : Portainer passe toujours le Compose
path avec `-f`, ce qui fait ignorer `COMPOSE_FILE` à Compose. Les étapes 1, 2 et 5 à 8 sont
communes aux deux modes.

### 1. Choisir le nom

Utilisez un nom sous **`home.arpa`**, le domaine réservé aux réseaux domestiques (RFC 8375), par
exemple `vaultia.home.arpa`. Évitez `.local` (réservé à mDNS/Bonjour, résolu autrement selon les
appareils) et tout nom d'un vrai domaine qui ne vous appartient pas.

### 2. Configurer le DNS local

Le nom doit pointer vers l'**adresse IPv4 privée de votre serveur** (ici l'exemple `192.168.1.100` :
remplacez-la par la vôtre, `ip -4 addr` sous Linux). Créez cette entrée dans le DNS de votre réseau :
routeur/box (« DNS local », « nom d'hôte statique »), AdGuard Home, Pi-hole, Unbound, dnsmasq…

Exemple avec AdGuard Home (facultatif) : *Filtres › Réécritures DNS › Ajouter*, domaine
`vaultia.home.arpa`, réponse `192.168.1.100`.

Les appareils doivent **utiliser ce DNS** (réglage DHCP de votre routeur, ou réglage DNS de
l'appareil). Vérifier depuis un appareil : `nslookup vaultia.home.arpa` doit répondre
`192.168.1.100`. Sans DNS local, un appareil isolé peut aussi utiliser son fichier `hosts`.

### 3. Configurer `.env` (ligne de commande)

Avec Portainer, sautez les étapes 3 et 4 : [portainer.md § 13](portainer.md#13-https-local-avec-portainer-caddy).

Dans `.env`, décommentez la section **HTTPS LOCAL** de [`.env.example`](../.env.example) et
modifiez trois lignes existantes :

    COMPOSE_FILE=compose.yaml:compose.https.yaml
    VAULTIA_DOMAIN=vaultia.home.arpa
    BETTER_AUTH_URL=https://vaultia.home.arpa
    TRUSTED_PROXIES=172.30.83.10
    VAULTIA_BIND_ADDRESS=192.168.1.100

- `BETTER_AUTH_URL` et `VAULTIA_DOMAIN` portent **le même nom**. Si le port 443 est déjà pris sur le
  serveur : `CADDY_HTTPS_PORT=8443` et `BETTER_AUTH_URL=https://vaultia.home.arpa:8443`.
- `TRUSTED_PROXIES` est l'adresse fixe de Caddy dans le réseau interne : Vaultia lit l'adresse réelle
  des visiteurs dans ce que Caddy lui transmet, et **seulement** de lui. Caddy remplace tout
  `X-Forwarded-For` envoyé par un client (vérifié : une connexion avec un faux en-tête est
  enregistrée sous l'adresse réelle).
- `VAULTIA_BIND_ADDRESS` : l'adresse du serveur où Caddy publie le port HTTPS (`127.0.0.1` le
  limiterait au serveur lui-même).

### 4. Démarrer (ligne de commande)

    docker compose up -d
    docker compose ps          # postgres, vaultia (healthy), caddy

`COMPOSE_FILE` dans `.env` suffit : les commandes habituelles (`docker compose logs`, `ps`,
`scripts/backup.sh`) prennent automatiquement la surcouche.

### 5. Récupérer le certificat racine PUBLIC

    ./scripts/export-ca.sh                 # écrit vaultia-local-ca.crt

Le script fonctionne dans les deux modes, sans lire les fichiers Compose : il retrouve le conteneur
Caddy du projet (`vaultia` par défaut ; pile Portainer d'un autre nom :
`COMPOSE_PROJECT_NAME=<pile> ./scripts/export-ca.sh`). Avec Portainer, lancez-le depuis un clone de ce
dépôt sur le serveur ; aucun `.env` n'est nécessaire.

Le script copie **uniquement** le certificat public de l'autorité (`root.crt`) et affiche son
empreinte SHA-256, à comparer sur les appareils. La **clé privée** de l'autorité (`root.key`) ne quitte
jamais le volume `caddy-data` : ne la copiez jamais, ne la partagez jamais. Le fichier `.crt` n'est
pas un secret, mais il est exclu de Git (`.gitignore`) comme toute personnalisation locale.

### 6. Installer l'autorité sur chaque appareil

Transférez `vaultia-local-ca.crt` sur l'appareil (AirDrop, clé USB, message à vous-même), puis :

| Système | Installation | Confiance |
| --- | --- | --- |
| **macOS** | double-cliquer le fichier : *Trousseaux d'accès* l'ajoute (trousseau « Système » ou « Session ») | ouvrir le certificat « Caddy Local Authority… », section **Se fier**, « Lors de l'utilisation de ce certificat » : **Toujours approuver** |
| **iOS / iPadOS** | ouvrir le fichier, puis *Réglages › Profil téléchargé › Installer* | **étape indispensable** : *Réglages › Général › Informations › Réglages des certificats*, activer la confiance totale pour ce certificat racine ([Apple](https://support.apple.com/102390)) |
| **Windows** | double-cliquer le fichier › *Installer le certificat* › *Ordinateur local* | magasin **Autorités de certification racines de confiance** |
| **Android** | *Paramètres › Sécurité (et confidentialité) › (Plus de paramètres de sécurité) › Chiffrement et identifiants › Installer un certificat › Certificat CA* | les chemins varient selon la version et le fabricant ([Google](https://support.google.com/pixelphone/answer/2844832)) ; Chrome reconnaît les autorités ajoutées ainsi, pas toutes les applications |

Firefox (ordinateur) utilise son propre magasin sur certains systèmes : *Paramètres › Vie privée et
sécurité › Certificats › Afficher les certificats › Autorités › Importer*, cocher « identifier des
sites web ».

### 7. Ouvrir Vaultia

Ouvrez **`https://vaultia.home.arpa`**. Le cadenas doit s'afficher sans avertissement ; le détail du
certificat indique l'émetteur « Caddy Local Authority ». Connectez-vous : le premier compte se crée
comme d'habitude.

Un appareil qui **n'a pas** installé l'autorité reçoit une erreur de certificat normale
(`NET::ERR_CERT_AUTHORITY_INVALID`, « Cette connexion n'est pas privée ») : c'est voulu. N'ajoutez pas
d'exception « continuer quand même » : installez l'autorité.

### 8. Vérifier

    curl --cacert vaultia-local-ca.crt https://vaultia.home.arpa/api/health
    # {"status":"ok","database":"up","vision":"ready"}

Dans le navigateur : connexion, caméra du scanner (autorisation demandée), `/api/docs`.

## HTTP et HTTPS ensemble

- La surcouche **ne publie pas le port 80** : aucune redirection HTTP → HTTPS n'est imposée, et un
  appareil qui n'a pas encore l'autorité n'est pas bloqué par une redirection.
- Vaultia n'est plus joignable directement en HTTP : `BETTER_AUTH_URL` est en HTTPS, un seul point
  d'entrée. Pour revenir au scénario A en ligne de commande, recommentez `COMPOSE_FILE`, remettez
  `BETTER_AUTH_URL` en `http://…` et `TRUSTED_PROXIES` vide, puis
  `docker compose up -d --remove-orphans` (arrête Caddy ; les données ne bougent pas, les volumes de
  Caddy restent pour un retour ultérieur). Avec Portainer :
  [portainer.md § 13.3](portainer.md#133-revenir-de-https-à-http).
- **HSTS** : laissez `HSTS_MAX_AGE` vide avec une autorité locale. HSTS force le navigateur à refuser
  toute erreur de certificat pendant la durée indiquée : si l'autorité change (volume `caddy-data`
  perdu, réinstallation), les appareils ne pourraient plus ouvrir Vaultia avant l'expiration. Si
  vous l'activez malgré tout, commencez court (`HSTS_MAX_AGE=300`). Vaultia ne le pose jamais en HTTP.

## Persistance et sauvegarde

L'autorité locale, ses certificats et l'état de Caddy sont dans les volumes `caddy-data` et
`caddy-config`. Redémarrer Caddy ou Vaultia, `docker compose down` puis `up` (**sans `-v`**) : même
autorité, rien à réinstaller sur les appareils (vérifié : empreinte identique après chaque étape).

Caddy renouvelle seul ses certificats de serveur ; la racine est valable 10 ans. Sauvegardez le volume
`caddy-data` avec votre configuration ([backup-restore.md](backup-restore.md)) : le perdre crée une
nouvelle autorité, à réinstaller sur chaque appareil. Ses clés privées sont lisibles par `root`
seulement dans le conteneur ; traitez la sauvegarde de ce volume comme un secret.

## Sécurité

- Rien n'est exposé à Internet : ne redirigez aucun port de votre box vers le serveur.
- Aucune clé privée dans Git, dans ce dépôt ou dans un export : seul `root.crt` sort du volume.
- Les protections de Vaultia ne sont pas assouplies pour Caddy : contrôle de l'origine sur
  `BETTER_AUTH_URL`, cookies `Secure`, proxys de confiance limités à `TRUSTED_PROXIES`.
