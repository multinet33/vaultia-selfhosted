# Dépannage

Premier réflexe : `docker compose ps` puis `docker compose logs --tail=100 vaultia`.

## `docker compose up` refuse de démarrer : « … manquant dans .env »

Une valeur obligatoire est vide : `POSTGRES_PASSWORD`, `BETTER_AUTH_SECRET` ou `BETTER_AUTH_URL`.
Voir [installation.md § 2](installation.md#2-configurer).

## `vaultia` redémarre en boucle

| Journal | Cause | Action |
| --- | --- | --- |
| `[config] configuration invalide : …` | valeur refusée (secret trop court, URL en http vers un nom d'hôte ou une adresse publique, `TRUSTED_PROXIES` invalide…) | corriger `.env`, `docker compose up -d` |
| `ÉCHEC des migrations` | migration de base en échec | **ne rien forcer** ; [update.md § En cas d'échec](update.md#en-cas-déchec--limites-du-retour-arrière) |
| `password authentication failed` | `POSTGRES_PASSWORD` changé après l'installation | remettre l'ancien mot de passe (la base garde celui de sa création) |

Un problème de modèle de vision ne fait **jamais** redémarrer le conteneur.

## La vision n'est pas prête

    curl http://127.0.0.1:3000/api/health            # "vision": …
    docker compose logs vaultia | grep models
    docker compose exec vaultia vaultia vision-status

| `vision` | Sens | Action |
| --- | --- | --- |
| `provisioning` | téléchargement en cours | attendre ; progression dans les journaux |
| `failed` | dernier essai en échec (`source du modèle injoignable`, `HTTP 5xx`…) ; nouvel essai automatique | vérifier l'accès de l'hôte à `huggingface.co` (proxy, pare-feu, DNS), ou lancer `docker compose exec vaultia vaultia models-provision` |
| `missing` | modèle absent ou altéré, aucun essai en cours (`INTELLIGENCE_MODELS_PROVISION=off`, ou volume modifié) | `docker compose exec vaultia vaultia models-provision` |
| `disabled` | `INTELLIGENCE_PROVIDERS` ne contient pas `siglip2-vision` | remettre la valeur par défaut (vider la ligne) |

Un modèle altéré (`models-verify` → `ALTÉRÉ`) n'est jamais utilisé ; `models-provision` le remplace.
L'application reste utilisable dans tous les cas (saisie manuelle).

Dans l'application, l'analyse d'une photo est proposée seulement si l'Espace l'a activée :
**Réglages › Vaultia Vision › mode « Locale »**.

## Impossible de se connecter depuis un autre appareil

- Par défaut, Vaultia n'est publié que sur `127.0.0.1` de l'hôte : reverse proxy HTTPS
  ([reverse-proxy.md](reverse-proxy.md)), ou HTTP sur l'adresse privée du serveur
  (`VAULTIA_BIND_ADDRESS`, [configuration.md](configuration.md#http-sur-le-réseau-local)).
- `BETTER_AUTH_URL` doit être **exactement** l'adresse du navigateur (schéma, nom, port) ; sinon
  les formulaires sont refusés (contrôle d'origine).
- HTTPS est obligatoire, sauf pour `localhost` et une adresse IPv4 privée (10.x, 172.16-31.x,
  192.168.x). Un nom d'hôte en `http://` (`http://vaultia.lan`) est refusé.
- `cannot assign requested address` : `VAULTIA_BIND_ADDRESS` n'est pas une adresse de ce serveur.
- `ERR_UNSAFE_PORT` dans Chrome ou Edge : le port choisi fait partie de ceux que les navigateurs
  refusent (6000 par exemple). Choisissez un autre port (les guides utilisent 6080) et reportez-le
  dans `VAULTIA_PORT` **et** `BETTER_AUTH_URL`.
- En HTTP sur le réseau local, le mode hors ligne et la caméra du scanner sont indisponibles (pas
  de contexte sécurisé) : c'est attendu, passer en HTTPS pour les obtenir.

## « Inscription fermée »

Normal après le premier compte (`VAULTIA_SIGNUP_POLICY=first-user`) : inviter depuis
Réglages › Membres ; le compte se crée avec l'adresse invitée. Voir [configuration.md § Comptes](configuration.md#comptes).

## Mot de passe perdu

Pas de réinitialisation par e-mail dans cette version. Un autre propriétaire d'un Espace partagé
garde l'accès aux données ; sinon, seule une restauration de sauvegarde le contourne.

## Fichiers manquants ou altérés

    docker compose run --rm --no-deps vaultia storage-verify

Liste chaque fichier `manquant` ou `altéré` (SHA-256 différent de celui enregistré à l'envoi).
Restaurer depuis une sauvegarde ([backup-restore.md](backup-restore.md)).

## Contrôle des traitements locaux

    docker compose run --rm --no-deps vaultia runtime-smoke

HEIC, miniatures, codes-barres, PDF, OCR : `8/8 contrôles réussis`.

## Journaux sans gravité

- `The destination stream closed early` : un navigateur a interrompu une page. Sans conséquence.
