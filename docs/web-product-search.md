# Recherche Web de codes produit (facultative)

[English](web-product-search_EN.md)

> Disponible avec Vaultia `0.1.0-rc.7`. **Désactivée par défaut** : sans configuration, Vaultia
> fonctionne exactement comme avant.

## Ce que fait la fonction

Quand vous scannez un code EAN/UPC (ou qu'« Analyser un objet » en lit un sur une photo) et que
personne ne le connaît, Vaultia peut chercher **le code exact** sur le Web, rapprocher les résultats
de plusieurs sites et vous **proposer** une fiche (nom, marque, code, sources). Rien n'est enregistré
sans votre validation ; aucun prix vu sur le Web ne devient un prix d'achat.

Ordre de résolution, toujours le même (scanner et analyse d'objet) :

1. **Vaultia** : le code est déjà dans l'inventaire de l'Espace → ses exemplaires, rien ne part ;
2. **Open Products Facts / Open Food Facts** (`open-facts`) ;
3. **Recherche Web** (`web-product-search`), seulement si les bases ouvertes n'ont rien ;
4. **Saisie manuelle**, code prérempli.

**Traitement externe** : même avec SearXNG hébergé chez vous, la recherche interroge Internet. Elle
n'a lieu que pour un Espace en mode **« externe »** (Réglages › Vaultia Vision) ; en mode local ou
désactivé, aucun code ne quitte le serveur. Seul le code (chiffres) est transmis.

Deux moteurs au choix :

| | SearXNG (recommandé) | Brave Search |
| --- | --- | --- |
| Où | conteneur de cette distribution, réseau interne | service distant (Brave) |
| Clé | aucune | clé d'API Brave, secrète |
| Conteneur en plus | oui (`searxng`) | non |

Google n'est jamais interrogé directement : aucune page de Google n'est lue, aucune protection n'est
contournée. SearXNG utilise ses moteurs habituels.

## Activer SearXNG

Dans `.env` (ligne de commande) ou dans les **variables de la pile** Portainer :

```ini
# 1. installer le moteur : GARDER la liste existante et ajouter web-product-search à la fin
INTELLIGENCE_PROVIDERS=zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts,web-product-search
# 2. démarrer le conteneur SearXNG
COMPOSE_PROFILES=web-search
SEARXNG_SECRET=<openssl rand -hex 32>
# 3. brancher Vaultia sur SearXNG (adresse interne fixe, port 8080)
WEB_PRODUCT_SEARCH_BACKEND=searxng
WEB_PRODUCT_SEARCH_URL=http://172.30.83.11:8080
WEB_PRODUCT_SEARCH_API_KEY=
```

Puis `docker compose up -d` — avec Portainer, « Update the stack » / « Pull and redeploy ».

- Si `INTELLIGENCE_PROVIDERS` était vide chez vous, la liste par défaut est celle de l'exemple
  ci-dessus sans `web-product-search` : recopiez-la et ajoutez le moteur.
- **Adresse fixe** : Vaultia `0.1.0-rc.7` n'accepte une URL `http://` que vers une IPv4 privée,
  jamais un nom d'hôte ; SearXNG a donc l'adresse `172.30.83.11` dans le réseau interne. Si vous
  avez changé `VAULTIA_SUBNET`, choisissez une adresse de ce sous-réseau dans
  `SEARXNG_IPV4_ADDRESS` et reportez-la dans `WEB_PRODUCT_SEARCH_URL`.
- SearXNG ne publie **aucun port** : il n'est joignable que par Vaultia.
- Image : `searxng/searxng:2026.9.25-12f8b6515` (image officielle, empreinte figée dans les fichiers
  Compose). Réglages embarqués (`configs`) : défauts du projet, **API JSON activée** (lue par
  Vaultia), limiteur désactivé (instance privée). Cache : volume `searxng-cache`.
- Sans `SEARXNG_SECRET`, le conteneur SearXNG refuse de démarrer (message dans ses journaux) ;
  Vaultia, lui, continue de fonctionner.

## Activer Brave Search

```ini
INTELLIGENCE_PROVIDERS=zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts,web-product-search
WEB_PRODUCT_SEARCH_BACKEND=brave
WEB_PRODUCT_SEARCH_API_KEY=<votre clé Brave Search>
WEB_PRODUCT_SEARCH_URL=
```

Pas de `COMPOSE_PROFILES`, pas de SearXNG. La clé reste sur le serveur (jamais envoyée au
navigateur, jamais dans Git). Clé absente ou invalide : Vaultia refuse de démarrer avec
« WEB_PRODUCT_SEARCH_API_KEY doit contenir la clé de l'API Brave Search ».

## Variables

| Variable | Valeur | Obligatoire | Secret |
| --- | --- | --- | --- |
| `INTELLIGENCE_PROVIDERS` | liste existante + `web-product-search` (après `open-facts`) | pour activer | non |
| `WEB_PRODUCT_SEARCH_BACKEND` | `searxng` ou `brave` ; vide : non configurée | pour activer | non |
| `WEB_PRODUCT_SEARCH_URL` | SearXNG : `http://172.30.83.11:8080` | avec `searxng` | non |
| `WEB_PRODUCT_SEARCH_API_KEY` | clé Brave | avec `brave` | **oui** |
| `COMPOSE_PROFILES` | `web-search` : démarre SearXNG | avec `searxng` | non |
| `SEARXNG_SECRET` | `openssl rand -hex 32` | avec `searxng` | **oui** |
| `SEARXNG_IPV4_ADDRESS` | adresse de SearXNG ; vide : `172.30.83.11` | non | non |

## Vérifier que c'est actif

- `docker compose ps` : `searxng` et `vaultia` sont `healthy` (SearXNG).
- **Réglages › Vaultia Vision** : « Données produit » est « Prête » en mode externe.
- Scanner un code inconnu d'Open Products Facts : la revue propose une fiche marquée « Proposé par :
  Base produit », avec ses sites sources (« D'après « site.example +2 » », « Fiches produit
  consultées ») — l'écran ne distingue pas la base ouverte de la recherche Web.
- **Journaux** (la preuve qui compte) : `docker compose logs vaultia | grep -A6 PRODUCT_LOOKUP`
  montre `open-facts`, puis `providerId: 'web-product-search'` (`SUCCEEDED`). Sans moteur Web, la
  cascade s'arrête sur `NO_PROVIDER`.
- Limite de `0.1.0-rc.7` : une fiche Open Products Facts **vide** (code connu, sans nom) compte comme
  trouvée ; la recherche Web n'est alors pas lancée pour ce code.

## Désactiver

Retirer `web-product-search` de `INTELLIGENCE_PROVIDERS`, vider `WEB_PRODUCT_SEARCH_BACKEND` et
`COMPOSE_PROFILES`, puis redéployer. Le conteneur SearXNG s'arrête avec
`docker compose --profile web-search down searxng` (ses données ne sont qu'un cache).
