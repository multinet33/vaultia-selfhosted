#!/usr/bin/env bash
# Exporte le certificat racine PUBLIC de l'autorité locale de Caddy (HTTPS local, docs/https.md),
# à installer sur les appareils clients. Ne copie JAMAIS la clé privée (root.key reste dans le
# volume caddy-data).
#
#     ./scripts/export-ca.sh [fichier]        défaut : vaultia-local-ca.crt
#
# Deux modes, même résultat : surcouche en ligne de commande (compose.https.yaml) ou pile Portainer
# (compose.portainer-https.yaml). Le conteneur Caddy est retrouvé par son projet Compose, sans lire
# les fichiers Compose ni .env (inutile pour une pile Portainer). Projet : COMPOSE_PROJECT_NAME,
# sinon celui de .env, sinon `vaultia`. Pile Portainer d'un autre nom : COMPOSE_PROJECT_NAME=<pile>.
set -euo pipefail

destination="${1:-vaultia-local-ca.crt}"
case "$destination" in /*) ;; *) destination="$PWD/$destination" ;; esac
cd "$(dirname "$0")/.."

project="${COMPOSE_PROJECT_NAME:-}"
if [ -z "$project" ] && [ -f .env ]; then
  project="$(sed -n 's/^[[:space:]]*COMPOSE_PROJECT_NAME=//p' .env | tail -1 | tr -d "\"' \r")"
fi
project="${project:-vaultia}"

caddy="$(docker ps -q --filter "label=com.docker.compose.project=${project}" --filter "label=com.docker.compose.service=caddy")"
if [ -z "$caddy" ] || [ "$(printf '%s\n' "$caddy" | wc -l | tr -d ' ')" != "1" ]; then
  echo "[export-ca] aucun conteneur Caddy en service dans le projet « ${project} » : HTTPS local démarré ? Pile d'un autre nom : COMPOSE_PROJECT_NAME=<pile> $0" >&2
  exit 1
fi

partial="${destination}.partial"
trap 'rm -f "$partial"' EXIT
docker exec "$caddy" cat /data/caddy/pki/authorities/local/root.crt > "$partial" || true
if ! grep -q "BEGIN CERTIFICATE" "$partial" || grep -q "PRIVATE KEY" "$partial"; then
  echo "[export-ca] certificat introuvable dans le conteneur Caddy du projet « ${project} » (autorité pas encore créée ?)." >&2
  exit 1
fi
mv "$partial" "$destination"
echo "[export-ca] certificat racine public (projet ${project}) : $destination"
if command -v openssl >/dev/null 2>&1; then
  openssl x509 -in "$destination" -noout -subject -enddate -fingerprint -sha256
fi
echo "[export-ca] à installer comme autorité de confiance sur chaque appareil (docs/https.md)."
