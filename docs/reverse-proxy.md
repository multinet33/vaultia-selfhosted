# Reverse proxy et HTTPS

Vaultia ne termine pas TLS lui-même. Il **exige HTTPS** partout, sauf sur la machine hôte
(`http://localhost`) et sur une adresse IPv4 privée du réseau local
([configuration.md § HTTP sur le réseau local](configuration.md#http-sur-le-réseau-local)). HTTPS
reste recommandé : le mode hors ligne, la caméra du scanner et les cookies sécurisés en dépendent.
Pour l'ouvrir au réseau local avec toutes ses fonctions, ou à Internet, placez-le derrière
**votre** reverse proxy. Aucun proxy n'est imposé ni embarqué par cette distribution.

| Responsabilité | Qui |
| --- | --- |
| certificat, TLS, redirection HTTP → HTTPS | proxy |
| adresse du client dans `X-Forwarded-For` | proxy |
| taille maximale d'un envoi (≥ 2 100 Mio pour restaurer une sauvegarde d'Espace) | proxy |
| en-têtes de sécurité, HSTS (`HSTS_MAX_AGE`), limites de débit, contrôle d'origine, cookies | Vaultia |

WebSocket : non utilisé.

## Règles communes

1. `BETTER_AUTH_URL` = l'adresse **https** exacte servie par le proxy (ex.
   `https://vaultia.maison.lan`), puis `docker compose up -d`.
2. Relayer vers Vaultia en HTTP : `http://127.0.0.1:3000` (proxy installé sur l'hôte) ou
   `http://vaultia:3000` (proxy en conteneur dans le réseau `vaultia`).
3. Transmettre l'en-tête `Host` d'origine.
4. **Ajouter** l'adresse du client à `X-Forwarded-For` (ou la remplacer).
5. Taille d'envoi ≥ 2 100 Mio et délais de lecture/écriture longs (≥ 10 min).
6. `TRUSTED_PROXIES` = l'adresse sous laquelle **Vaultia voit le proxy** (voir plus bas).
7. Laisser `VAULTIA_BIND_ADDRESS=127.0.0.1` : seul le proxy doit joindre le port 3000.

## TRUSTED_PROXIES

Vaultia limite les tentatives de connexion par adresse IP et journalise l'adresse des sessions.
Il lit `X-Forwarded-For` en partant de la droite et écarte les adresses de `TRUSTED_PROXIES` : la
première restante est le client.

| Proxy | `TRUSTED_PROXIES` |
| --- | --- |
| en conteneur dans le réseau `vaultia`, adresse fixe (exemple Caddy ci-dessous) | `172.30.83.10` |
| installé sur l'hôte, vers `127.0.0.1:3000` (Linux) | passerelle du réseau Docker : `172.30.83.1` avec le sous-réseau par défaut — à confirmer (`docker network inspect vaultia_vaultia`) |
| plusieurs proxys (CDN puis proxy local) | chacun, adresses ou CIDR séparés par des virgules |
| aucun (accès `localhost` seulement) | vide |

**Jamais** `0.0.0.0/0`, `::/0` ou une plage contenant des clients : un client pourrait choisir
l'adresse sous laquelle il est compté. Une entrée invalide arrête le démarrage.

## Exemple : Caddy en conteneur

Configuration de référence de Vaultia (testée avec le dépôt source). Créer, à côté de
`compose.yaml`, un fichier `compose.override.yaml` — Docker Compose le charge **automatiquement**,
et `scripts/backup.sh` / `restore.sh` aussi :

```yaml
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    depends_on:
      vaultia:
        condition: service_healthy
    environment:
      VAULTIA_DOMAIN: vaultia.maison.lan      # hôte de BETTER_AUTH_URL
      CADDY_TLS: internal                     # ou une adresse e-mail (Let's Encrypt, domaine public)
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data                      # certificats et autorité locale : à sauvegarder
      - caddy-config:/config
    networks:
      vaultia:
        ipv4_address: 172.30.83.10

  vaultia:
    ports: !reset []                          # plus rien de publié : tout passe par Caddy

volumes:
  caddy-data:
  caddy-config:
```

et un `Caddyfile` :

```
{$VAULTIA_DOMAIN} {
	tls {$CADDY_TLS}
	request_body {
		max_size 2100MiB
	}
	reverse_proxy vaultia:3000 {
		transport http {
			read_timeout 10m
			write_timeout 10m
		}
	}
	encode zstd gzip
}
```

Dans `.env` : `BETTER_AUTH_URL=https://vaultia.maison.lan`, `TRUSTED_PROXIES=172.30.83.10`. Puis
`docker compose up -d`. Avec `CADDY_TLS=internal`, installer le certificat racine de Caddy comme
autorité de confiance sur chaque appareil :

    docker compose cp caddy:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt

`!reset` exige Docker Compose 2.24 ou plus récent.

## nginx (proxy sur l'hôte)

```nginx
server {
    listen 443 ssl;
    server_name vaultia.maison.lan;
    # ssl_certificate … ; ssl_certificate_key … ;
    client_max_body_size 2100m;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Traefik, Nginx Proxy Manager, Cloudflare Tunnel, proxy d'un NAS

Conviennent s'ils respectent les [règles communes](#règles-communes). Cloudflare Tunnel : le
connecteur `cloudflared` relaie vers `http://127.0.0.1:3000` (ou `http://vaultia:3000` s'il est dans
le réseau `vaultia`) ; `TRUSTED_PROXIES` = l'adresse sous laquelle Vaultia voit `cloudflared`.
Avant d'exposer Vaultia sur Internet, garder `VAULTIA_SIGNUP_POLICY=first-user` ou `invite`.

## État des tests

Pour cette bêta, seul l'accès direct `http://localhost` est validé par la distribution ; la
configuration Caddy ci-dessus est celle validée par le dépôt source (Step 18). nginx, Traefik,
Nginx Proxy Manager et Cloudflare Tunnel sont documentés d'après les mêmes règles, **non testés**.
