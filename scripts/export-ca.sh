#!/usr/bin/env bash
# Exporte le certificat racine PUBLIC de l'autorité locale de Caddy (HTTPS local, docs/https.md),
# à installer sur les appareils clients. Ne copie JAMAIS la clé privée (root.key reste dans le
# volume caddy-data).
#
#     ./scripts/export-ca.sh [fichier]        défaut : vaultia-local-ca.crt
set -euo pipefail

cd "$(dirname "$0")/.."
read -r -a compose <<< "${COMPOSE:-docker compose}"
destination="${1:-vaultia-local-ca.crt}"

"${compose[@]}" exec -T caddy cat /data/caddy/pki/authorities/local/root.crt > "$destination"
if ! grep -q "BEGIN CERTIFICATE" "$destination" || grep -q "PRIVATE KEY" "$destination"; then
  rm -f "$destination"
  echo "[export-ca] certificat introuvable : Caddy a-t-il déjà démarré avec compose.https.yaml ?" >&2
  exit 1
fi
echo "[export-ca] certificat racine public : $destination"
if command -v openssl >/dev/null 2>&1; then
  openssl x509 -in "$destination" -noout -subject -enddate -fingerprint -sha256
fi
echo "[export-ca] à installer comme autorité de confiance sur chaque appareil (docs/https.md)."
