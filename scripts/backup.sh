#!/usr/bin/env bash
# Distribution auto-hébergée : reprise à l'identique de `deploy/backup.sh` du dépôt source de Vaultia
# (commit 150c5a6) — même mécanisme, seuls les chemins changent (lancé depuis la racine de ce dépôt).
# Ce n'est pas une seconde implémentation : toute correction se fait d'abord dans la source.
# Sauvegarde d'INFRASTRUCTURE de l'instance (docs/backup-restore.md) : base PostgreSQL
# complète et fichiers des médias, pour reconstruire l'instance entière après une perte du serveur.
# Ce n'est PAS la sauvegarde Vaultia d'un Espace (archive ZIP téléchargée dans l'application).
#
#     ./scripts/backup.sh [dossier de destination]          défaut : ./backups
#
# Vaultia est arrêté pendant la copie (base et fichiers au même instant), puis relancé : une courte
# interruption, de quelques secondes à quelques minutes selon le volume des médias.
# La configuration (.env : secrets) n'est PAS copiée : elle se sauvegarde à part.
#
# Autre fichier Compose ou autre projet : COMPOSE="docker compose -f compose.yaml -f compose.override.yaml" ./scripts/backup.sh
set -euo pipefail

cd "$(dirname "$0")/.."
read -r -a compose <<< "${COMPOSE:-docker compose}"
destination_root="${1:-./backups}"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
destination="${destination_root%/}/vaultia-${stamp}"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

restart_vaultia() {
  echo "[backup] redémarrage de Vaultia (attente de son état sain)"
  "${compose[@]}" up -d --wait vaultia >/dev/null
}

umask 077
mkdir -p "$destination"

echo "[backup] PostgreSQL doit être démarré"
"${compose[@]}" up -d --wait postgres >/dev/null

echo "[backup] arrêt de Vaultia (cohérence base / fichiers)"
"${compose[@]}" stop vaultia >/dev/null
trap restart_vaultia EXIT

# Night Run LOT 4 : chaque fichier référencé est relu et comparé à la base avant la copie (SHA-256 des
# médias). Une anomalie n'empêche pas la sauvegarde (elle est d'autant plus utile), elle est notée
# dans MANIFEST et signalée.
echo "[backup] vérification des fichiers contre la base (storage-verify)"
if "${compose[@]}" run --rm --no-deps -T vaultia storage-verify; then storage_verify="ok"; else storage_verify="anomalies"; fi

echo "[backup] base : pg_dump (format custom)"
"${compose[@]}" exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner' > "$destination/database.dump"

echo "[backup] médias : archive tar du volume"
# Dossiers de travail exclus (.tmp : écritures en cours ; .work : archives temporaires).
"${compose[@]}" run --rm --no-deps -T --entrypoint tar vaultia -C /var/lib/vaultia/media --exclude=./.tmp --exclude=./.work -cf - . > "$destination/media.tar"

migrations="$("${compose[@]}" exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "select count(*) from _prisma_migrations where finished_at is not null"')"
postgres_version="$("${compose[@]}" exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "show server_version"')"
vaultia_version="$("${compose[@]}" run --rm --no-deps -T --entrypoint node vaultia -p "require('./package.json').version")"

(
  cd "$destination"
  sha256 database.dump media.tar > SHA256SUMS
  {
    echo "created_at=${stamp}"
    echo "vaultia_version=${vaultia_version}"
    echo "postgres_version=${postgres_version}"
    echo "applied_migrations=${migrations}"
    echo "media_files=$(tar -tf media.tar | grep -vc '/$')"
    echo "storage_verify=${storage_verify}"
  } > MANIFEST
)

trap - EXIT
restart_vaultia
echo "[backup] terminé : ${destination}"
cat "$destination/MANIFEST"
if [ "$storage_verify" != "ok" ]; then
  echo "[backup] ATTENTION : des fichiers manquaient ou différaient de leur empreinte avant la copie (voir la sortie de storage-verify ci-dessus)." >&2
fi
echo "[backup] À copier hors du serveur. Sauvegarder aussi .env à part (secrets)."
