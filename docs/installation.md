# Installation

## 1. Récupérer la distribution

    git clone https://github.com/multinet33/vaultia-selfhosted.git
    cd vaultia-selfhosted

Seul ce dépôt est nécessaire : l'application est tirée de GHCR par Docker (`compose.yaml`).

## 2. Configurer

    cp .env.example .env
    chmod 600 .env                        # Linux : secrets lisibles par vous seul

Dans `.env`, section **OBLIGATOIRE** :

| Variable | Valeur |
| --- | --- |
| `POSTGRES_PASSWORD` | sortie de `openssl rand -hex 24` |
| `BETTER_AUTH_SECRET` | sortie de `openssl rand -base64 32` |
| `BETTER_AUTH_URL` | `http://localhost:3000` pour un essai sur la machine elle-même ; `https://<nom>` derrière un reverse proxy |

Tant qu'une de ces valeurs est vide, `docker compose up` refuse de démarrer et nomme la variable
manquante. Les autres réglages ont des valeurs par défaut sûres ([configuration.md](configuration.md)).

## 3. Démarrer

    docker compose up -d

Premier démarrage : téléchargement de l'image (~600 Mio compressés), création de la base,
migrations, puis Vaultia démarre ; en parallèle, le modèle de la vision (90 Mio) s'installe.

    docker compose ps

| Service | État attendu |
| --- | --- |
| `postgres` | `Up … (healthy)` |
| `vaultia` | `Up … (healthy)` après 30 à 90 s |

## 4. Vérifier

    curl http://127.0.0.1:3000/api/health
    # {"status":"ok","database":"up","vision":"ready"}

`"vision":"provisioning"` : le modèle s'installe encore (voir `docker compose logs -f vaultia`).

    docker compose exec vaultia vaultia vision-status
    # … Vaultia Vision: READY

## 5. Premier compte

Ouvrir `BETTER_AUTH_URL` dans le navigateur et **créer un compte** : le premier compte de
l'instance est libre, il devient l'administrateur de son Espace. Ensuite l'inscription est fermée
(`VAULTIA_SIGNUP_POLICY=first-user`) : inviter les autres membres depuis l'application
(Réglages › Membres) ; chacun crée son compte depuis son lien d'invitation, avec l'adresse e-mail
invitée.

Pour utiliser la vision locale dans un Espace : **Réglages › Vaultia Vision › mode « Locale »** (désactivée
par défaut, décision de l'Espace).

## 6. Accès depuis le réseau

Voir [reverse-proxy.md](reverse-proxy.md). Sans reverse proxy, Vaultia reste accessible seulement
depuis la machine hôte (`127.0.0.1`).

## Arrêter, redémarrer

    docker compose stop           # arrêt
    docker compose start          # reprise
    docker compose restart        # redémarrage
    docker compose down           # suppression des conteneurs, volumes CONSERVÉS
    docker compose down -v        # ⚠ efface aussi base, fichiers et modèle

Vaultia redémarre seul après un redémarrage de l'hôte (`restart: unless-stopped`), si le service
Docker démarre au boot.
