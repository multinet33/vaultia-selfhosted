#!/usr/bin/env bash
# Distribution auto-hébergée : reprise à l'identique de `deploy/restore.sh` du dépôt source de Vaultia
# (commit 150c5a6) — même mécanisme, seuls les chemins changent (lancé depuis la racine de ce dépôt).
# Ce n'est pas une seconde implémentation : toute correction se fait d'abord dans la source.
# Restauration d'une sauvegarde d'INFRASTRUCTURE (scripts/backup.sh) sur une instance VIDE
# (docs/backup-restore.md) : base PostgreSQL et fichiers des médias.
#
#     ./scripts/restore.sh <dossier de sauvegarde>
#
# Prérequis : .env de l'instance d'origine (au minimum BETTER_AUTH_SECRET et, s'il était
# défini, WEBHOOK_SECRET_KEY : sans eux, les liens de partage ne se réaffichent plus et les secrets
# de webhooks sont illisibles), une version de Vaultia égale ou plus récente que celle de la
# sauvegarde, et des volumes neufs. La restauration refuse une base ou un stockage non vides :
# elle n'écrase et ne fusionne jamais rien.
set -euo pipefail

cd "$(dirname "$0")/.."
read -r -a compose <<< "${COMPOSE:-docker compose}"
source_dir="${1:-}"
if [ -z "$source_dir" ] || [ ! -f "$source_dir/MANIFEST" ]; then
  echo "Usage : $0 <dossier de sauvegarde contenant MANIFEST, SHA256SUMS, database.dump, media.tar>" >&2
  exit 2
fi
source_dir="$(cd "$source_dir" && pwd)"

echo "[restore] contrôle des sommes SHA-256"
(
  cd "$source_dir"
  if command -v sha256sum >/dev/null 2>&1; then sha256sum -c SHA256SUMS; else shasum -a 256 -c SHA256SUMS; fi
)
cat "$source_dir/MANIFEST"

echo "[restore] PostgreSQL doit être démarré"
"${compose[@]}" up -d --wait postgres >/dev/null

tables="$("${compose[@]}" exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "select count(*) from information_schema.tables where table_schema = '"'"'public'"'"'"')"
if [ "$tables" != "0" ]; then
  echo "[restore] REFUS : la base contient déjà ${tables} table(s). Restaurer sur une instance neuve (volumes vides), jamais par-dessus." >&2
  exit 1
fi
existing="$("${compose[@]}" run --rm --no-deps -T --entrypoint sh vaultia -c 'ls -A /var/lib/vaultia/media | wc -l')"
if [ "$existing" != "0" ]; then
  echo "[restore] REFUS : le stockage des médias n'est pas vide. Restaurer sur un volume neuf." >&2
  exit 1
fi

# Contrôles passés seulement : une restauration refusée ne touche pas à une instance en service.
echo "[restore] arrêt de Vaultia pendant la restauration"
"${compose[@]}" stop vaultia >/dev/null 2>&1 || true

echo "[restore] base : pg_restore"
"${compose[@]}" exec -T postgres sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --exit-on-error' < "$source_dir/database.dump"

echo "[restore] médias : extraction dans le volume"
"${compose[@]}" run --rm --no-deps -T --entrypoint tar vaultia -C /var/lib/vaultia/media -xf - < "$source_dir/media.tar"

echo "[restore] démarrage de Vaultia (migrations éventuelles de la version installée)"
"${compose[@]}" up -d --wait

# Night Run LOT 4 : la base restaurée et les fichiers restaurés doivent se correspondre, fichier par
# fichier (SHA-256 de chaque média contre l'empreinte enregistrée à l'envoi).
echo "[restore] vérification des fichiers contre la base (storage-verify)"
if ! "${compose[@]}" run --rm --no-deps -T vaultia storage-verify; then
  if grep -q '^storage_verify=anomalies' "$source_dir/MANIFEST"; then
    echo "[restore] ATTENTION : anomalies de fichiers, déjà présentes à la sauvegarde (MANIFEST : storage_verify=anomalies)." >&2
  else
    echo "[restore] ÉCHEC de la vérification : des fichiers restaurés manquent ou diffèrent de la base. Ne pas mettre en service ; reprendre une autre sauvegarde." >&2
  fi
  exit 1
fi
echo "[restore] terminé. Vérifier : connexion, Espaces, objets, photos et documents (docs/backup-restore.md § Vérification)."
