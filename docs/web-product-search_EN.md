# Web product code search (optional)

[Français](web-product-search.md)

> Available with Vaultia `0.1.0-rc.7`. **Off by default**: without configuration, Vaultia works
> exactly as before.

## What it does

When you scan an EAN/UPC code (or "Analyze an item" reads one on a photo) and nobody knows it,
Vaultia can search the web for **the exact code**, match results from several sites and **suggest**
a product (name, brand, code, sources). Nothing is saved until you confirm; no price seen on the web
ever becomes a purchase price.

Resolution order, always the same (scanner and item analysis):

1. **Vaultia**: the code is already in the workspace inventory → its units, nothing leaves;
2. **Open Products Facts / Open Food Facts** (`open-facts`);
3. **Web search** (`web-product-search`), only if the open databases have nothing;
4. **Manual entry**, code prefilled.

**External processing**: even with SearXNG hosted at home, the search queries the Internet. It only
runs for a workspace in **"external"** mode (Settings › Vaultia Vision); in local or disabled mode,
no code leaves the server. Only the code (digits) is sent.

Two engines to choose from:

| | SearXNG (recommended) | Brave Search |
| --- | --- | --- |
| Where | container of this distribution, internal network | remote service (Brave) |
| Key | none | Brave API key, secret |
| Extra container | yes (`searxng`) | no |

Google is never queried directly: no Google page is read, no protection is bypassed. SearXNG uses
its usual engines.

## Enable SearXNG

In `.env` (command line) or in the Portainer **stack variables**:

```ini
# 1. install the engine: KEEP your existing list and add web-product-search at the end
INTELLIGENCE_PROVIDERS=zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts,web-product-search
# 2. start the SearXNG container
COMPOSE_PROFILES=web-search
SEARXNG_SECRET=<openssl rand -hex 32>
# 3. point Vaultia to SearXNG (fixed internal address, port 8080)
WEB_PRODUCT_SEARCH_BACKEND=searxng
WEB_PRODUCT_SEARCH_URL=http://172.30.83.11:8080
WEB_PRODUCT_SEARCH_API_KEY=
```

Then `docker compose up -d` — with Portainer, "Update the stack" / "Pull and redeploy".

- If your `INTELLIGENCE_PROVIDERS` was empty, the default list is the one above without
  `web-product-search`: copy it and add the engine.
- **Fixed address**: Vaultia `0.1.0-rc.7` only accepts an `http://` URL to a private IPv4, never a
  host name; SearXNG therefore gets `172.30.83.11` on the internal network. If you changed
  `VAULTIA_SUBNET`, pick an address of that subnet for `SEARXNG_IPV4_ADDRESS` and use it in
  `WEB_PRODUCT_SEARCH_URL`.
- SearXNG publishes **no port**: only Vaultia can reach it.
- Image: `searxng/searxng:2026.9.25-12f8b6515` (official image, digest pinned in the Compose files).
  Embedded settings (`configs`): project defaults, **JSON API enabled** (read by Vaultia), limiter
  off (private instance). Cache: `searxng-cache` volume.
- Without `SEARXNG_SECRET`, the SearXNG container refuses to start (message in its logs); Vaultia
  keeps working.

## Enable Brave Search

```ini
INTELLIGENCE_PROVIDERS=zxing-barcode,tesseract-ocr,siglip2-vision,e5-embeddings,document-rules,open-facts,web-product-search
WEB_PRODUCT_SEARCH_BACKEND=brave
WEB_PRODUCT_SEARCH_API_KEY=<your Brave Search key>
WEB_PRODUCT_SEARCH_URL=
```

No `COMPOSE_PROFILES`, no SearXNG. The key stays on the server (never sent to the browser, never in
Git). Missing or invalid key: Vaultia refuses to start with
"WEB_PRODUCT_SEARCH_API_KEY doit contenir la clé de l'API Brave Search".

## Variables

| Variable | Value | Required | Secret |
| --- | --- | --- | --- |
| `INTELLIGENCE_PROVIDERS` | existing list + `web-product-search` (after `open-facts`) | to enable | no |
| `WEB_PRODUCT_SEARCH_BACKEND` | `searxng` or `brave`; empty: not configured | to enable | no |
| `WEB_PRODUCT_SEARCH_URL` | SearXNG: `http://172.30.83.11:8080` | with `searxng` | no |
| `WEB_PRODUCT_SEARCH_API_KEY` | Brave key | with `brave` | **yes** |
| `COMPOSE_PROFILES` | `web-search`: starts SearXNG | with `searxng` | no |
| `SEARXNG_SECRET` | `openssl rand -hex 32` | with `searxng` | **yes** |
| `SEARXNG_IPV4_ADDRESS` | SearXNG address; empty: `172.30.83.11` | no | no |

## Check that it is active

- `docker compose ps`: `searxng` and `vaultia` are `healthy` (SearXNG).
- **Settings › Vaultia Vision**: "Product data" is "Ready" in external mode.
- Scan a code unknown to Open Products Facts: the review suggests a product whose provenance is
  "Recherche Web (SearXNG)" or "Recherche Web (Brave Search)", with its source sites.
- Logs: `docker compose logs vaultia | grep -A6 PRODUCT_LOOKUP` shows `open-facts`, then
  `web-product-search` (`SUCCEEDED`). Without a web engine, the cascade stops on `NO_PROVIDER`.

## Turn it off

Remove `web-product-search` from `INTELLIGENCE_PROVIDERS`, clear `WEB_PRODUCT_SEARCH_BACKEND` and
`COMPOSE_PROFILES`, then redeploy. Stop the SearXNG container with
`docker compose --profile web-search down searxng` (its data is only a cache).
