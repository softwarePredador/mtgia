#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "instalacao do backup remoto ManaLoom"
readonly LIVE_MUTATION_APPROVED=1

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
REMOTE_ROOT="${MANALOOM_REMOTE_BACKUP_ROOT:-/opt/manaloom}"
REMOTE_BACKUP_DIR="${MANALOOM_REMOTE_BACKUP_DIR:-$REMOTE_ROOT/backups/postgres}"
REMOTE_LOG_DIR="${MANALOOM_REMOTE_LOG_DIR:-$REMOTE_ROOT/logs}"
RETENTION_DAYS="${MANALOOM_BACKUP_RETENTION_DAYS:-14}"
BACKUP_SCHEDULE="${MANALOOM_BACKUP_CRON:-17 2 * * *}"
RESTORE_SCHEDULE="${MANALOOM_RESTORE_CHECK_CRON:-47 3 * * 0}"
RESTORE_MODE="${MANALOOM_RESTORE_VALIDATE_MODE:-full}"
RESTORE_IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4}"
RESTORE_MIN_TABLES="${MANALOOM_RESTORE_MIN_TABLES:-80}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool ssh

# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
validate_manaloom_exact_coordinate postgres_service "$POSTGRES_SERVICE" \
  evolution_manaloom-postgres
validate_manaloom_exact_coordinate postgres_user "$POSTGRES_USER" postgres
validate_manaloom_exact_coordinate postgres_db "$POSTGRES_DB" halder
validate_manaloom_exact_coordinate remote_backup_root "$REMOTE_ROOT" \
  /opt/manaloom
validate_manaloom_exact_coordinate remote_backup_dir "$REMOTE_BACKUP_DIR" \
  /opt/manaloom/backups/postgres
validate_manaloom_exact_coordinate remote_log_dir "$REMOTE_LOG_DIR" \
  /opt/manaloom/logs
validate_manaloom_exact_coordinate restore_image "$RESTORE_IMAGE" \
  postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4
if [[ "$RESTORE_MODE" != "full" ]]; then
  echo "instalacao recusada: o cron de recuperacao deve executar restore full" >&2
  exit 2
fi
if [[ ! "$RESTORE_MIN_TABLES" =~ ^[1-9][0-9]*$ ]]; then
  echo "MANALOOM_RESTORE_MIN_TABLES deve ser inteiro positivo" >&2
  exit 2
fi
initialize_manaloom_secure_ssh "$SSH_HOST"
cleanup() {
  cleanup_manaloom_secure_ssh
}
trap cleanup EXIT

if [[ "$LIVE_MUTATION_APPROVED" != "1" ]]; then
  echo "instalacao recusada: aprovacao live nao foi preservada" >&2
  exit 2
fi

ssh_base=(
  ssh
  -o BatchMode=yes
  -i "$SSH_KEY"
  "$SSH_HOST"
)

echo "[install] host=$SSH_HOST backup_dir=$REMOTE_BACKUP_DIR retention_days=$RETENTION_DAYS"

"${ssh_base[@]}" "mkdir -p '$REMOTE_ROOT/scripts' '$REMOTE_BACKUP_DIR' '$REMOTE_LOG_DIR'"

"${ssh_base[@]}" "cat > '$REMOTE_ROOT/scripts/postgres_backup.sh'" <<'REMOTE_BACKUP_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
BACKUP_DIR="${MANALOOM_BACKUP_DIR:-/opt/manaloom/backups/postgres}"
RETENTION_DAYS="${MANALOOM_BACKUP_RETENTION_DAYS:-14}"
LOCK_FILE="${MANALOOM_BACKUP_LOCK_FILE:-/tmp/manaloom-postgres-backup.lock}"

mkdir -p "$BACKUP_DIR"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "{\"status\":\"skipped\",\"reason\":\"lock_held\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  exit 0
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
tmp_file="$BACKUP_DIR/.manaloom-postgres-$stamp.dump.tmp"
out_file="$BACKUP_DIR/manaloom-postgres-$stamp.dump"
tmp_checksum="$out_file.sha256.tmp"
checksum_file="$out_file.sha256"

cleanup() {
  rm -f "$tmp_file" "$tmp_checksum"
}
trap cleanup EXIT

cid="$(docker ps --filter "label=com.docker.swarm.service.name=$POSTGRES_SERVICE" --format '{{.ID}}' | head -n 1)"
if [ -z "$cid" ]; then
  echo "{\"status\":\"error\",\"reason\":\"postgres_container_not_found\",\"service\":\"$POSTGRES_SERVICE\"}" >&2
  exit 1
fi

docker exec "$cid" pg_dump -Fc -U "$POSTGRES_USER" "$POSTGRES_DB" > "$tmp_file"
chmod 600 "$tmp_file"

bytes="$(wc -c < "$tmp_file" | tr -d ' ')"
if [ "$bytes" -lt 1024 ]; then
  rm -f "$tmp_file"
  echo "{\"status\":\"error\",\"reason\":\"backup_too_small\",\"bytes\":$bytes}" >&2
  exit 1
fi

if ! docker exec -i "$cid" pg_restore --list < "$tmp_file" >/dev/null; then
  rm -f "$tmp_file"
  echo "{\"status\":\"error\",\"reason\":\"pg_restore_list_failed\"}" >&2
  exit 1
fi

sha256="$(sha256sum "$tmp_file" | awk '{print $1}')"
printf '%s  %s\n' "$sha256" "$(basename "$out_file")" > "$tmp_checksum"
chmod 600 "$tmp_checksum"
mv "$tmp_file" "$out_file"
mv "$tmp_checksum" "$checksum_file"
ln -sfn "$out_file" "$BACKUP_DIR/latest.dump"
ln -sfn "$checksum_file" "$BACKUP_DIR/latest.dump.sha256"

find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump' -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump.sha256' -mtime +"$RETENTION_DAYS" -delete

backup_count="$(find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump' | wc -l | tr -d ' ')"
echo "{\"status\":\"ok\",\"file\":\"$out_file\",\"bytes\":$bytes,\"sha256\":\"$sha256\",\"checksum_file\":\"$checksum_file\",\"backup_count\":$backup_count,\"retention_days\":$RETENTION_DAYS,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
REMOTE_BACKUP_SCRIPT

"${ssh_base[@]}" "cat > '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'" <<'REMOTE_RESTORE_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${MANALOOM_BACKUP_DIR:-/opt/manaloom/backups/postgres}"
RESTORE_IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4}"
APPROVED_RESTORE_IMAGE="postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4"
RESTORE_MODE="${MANALOOM_RESTORE_VALIDATE_MODE:-full}"
MIN_TABLES="${MANALOOM_RESTORE_MIN_TABLES:-80}"
DB_NAME="${MANALOOM_RESTORE_DB:-manaloom_restore_check}"
LOCK_FILE="${MANALOOM_RESTORE_LOCK_FILE:-/tmp/manaloom-postgres-restore-check.lock}"
container="manaloom-restore-check-$(date -u +%Y%m%d%H%M%S)"

if [ "$RESTORE_IMAGE" != "$APPROVED_RESTORE_IMAGE" ]; then
  echo '{"status":"error","reason":"restore_image_not_approved"}' >&2
  exit 2
fi
if [ "$RESTORE_MODE" != "full" ]; then
  echo '{"status":"error","reason":"restore_mode_not_full"}' >&2
  exit 2
fi
if [[ ! "$MIN_TABLES" =~ ^[1-9][0-9]*$ ]]; then
  echo '{"status":"error","reason":"restore_min_tables_invalid"}' >&2
  exit 2
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "{\"status\":\"skipped\",\"reason\":\"lock_held\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  exit 0
fi

backup_file="$BACKUP_DIR/latest.dump"
if [ ! -f "$backup_file" ]; then
  backup_file="$(find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump' -print | sort | tail -n 1)"
fi
if [ -z "${backup_file:-}" ] || [ ! -f "$backup_file" ]; then
  echo "{\"status\":\"error\",\"reason\":\"backup_not_found\",\"backup_dir\":\"$BACKUP_DIR\"}" >&2
  exit 1
fi
backup_file="$(readlink -f "$backup_file")"
checksum_file="$backup_file.sha256"
if [ ! -f "$checksum_file" ]; then
  echo "{\"status\":\"error\",\"reason\":\"backup_checksum_not_found\",\"backup\":\"$backup_file\"}" >&2
  exit 1
fi
(
  cd "$(dirname "$backup_file")"
  sha256sum --check --status "$(basename "$checksum_file")"
) || {
  echo "{\"status\":\"error\",\"reason\":\"backup_checksum_mismatch\",\"backup\":\"$backup_file\"}" >&2
  exit 1
}
backup_sha256="$(awk 'NR == 1 {print $1}' "$checksum_file")"
started_epoch="$(date +%s)"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cleanup() {
  docker rm -f "$container" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "$container" --network none \
  -e POSTGRES_PASSWORD=restore_check "$RESTORE_IMAGE" >/dev/null

ready=0
for _ in $(seq 1 60); do
  if docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" != "1" ]; then
  echo '{"status":"error","reason":"restore_postgres_not_ready"}' >&2
  exit 1
fi

docker exec "$container" createdb -U postgres "$DB_NAME"
docker cp "$backup_file" "$container:/tmp/backup.dump"

docker exec "$container" pg_restore -U postgres -d "$DB_NAME" \
  --exit-on-error --no-owner --no-privileges /tmp/backup.dump

table_count="$(docker exec "$container" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" | tr -d '[:space:]')"

if [ "${table_count:-0}" -lt "$MIN_TABLES" ]; then
  echo "{\"status\":\"error\",\"reason\":\"restore_table_count_below_minimum\",\"backup\":\"$backup_file\",\"mode\":\"$RESTORE_MODE\",\"table_count\":${table_count:-0},\"min_tables\":$MIN_TABLES}" >&2
  exit 1
fi

docker exec "$container" psql -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -c 'BEGIN; SET CONSTRAINTS ALL IMMEDIATE; COMMIT;' >/dev/null
foreign_key_count="$(docker exec "$container" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c "SELECT COUNT(*) FROM pg_constraint WHERE contype = 'f';" | tr -d '[:space:]')"
database_bytes="$(docker exec "$container" psql -U postgres -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c "SELECT pg_database_size(current_database());" | tr -d '[:space:]')"
bytes="$(wc -c < "$backup_file" | tr -d ' ')"
completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
duration_seconds="$(( $(date +%s) - started_epoch ))"
echo "{\"status\":\"ok\",\"backup\":\"$backup_file\",\"mode\":\"$RESTORE_MODE\",\"table_count\":$table_count,\"min_tables\":$MIN_TABLES,\"foreign_key_count\":$foreign_key_count,\"database_bytes\":$database_bytes,\"bytes\":$bytes,\"sha256\":\"$backup_sha256\",\"started_at\":\"$started_at\",\"completed_at\":\"$completed_at\",\"rto_seconds\":$duration_seconds,\"network\":\"none\"}"
REMOTE_RESTORE_SCRIPT

"${ssh_base[@]}" "chmod 700 '$REMOTE_ROOT/scripts/postgres_backup.sh' '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'"

backup_cron="$BACKUP_SCHEDULE MANALOOM_POSTGRES_SERVICE=$POSTGRES_SERVICE MANALOOM_POSTGRES_USER=$POSTGRES_USER MANALOOM_POSTGRES_DB=$POSTGRES_DB MANALOOM_BACKUP_DIR=$REMOTE_BACKUP_DIR MANALOOM_BACKUP_RETENTION_DAYS=$RETENTION_DAYS $REMOTE_ROOT/scripts/postgres_backup.sh >> $REMOTE_LOG_DIR/postgres_backup.log 2>&1 # manaloom-postgres-backup"
restore_cron="$RESTORE_SCHEDULE MANALOOM_BACKUP_DIR=$REMOTE_BACKUP_DIR MANALOOM_RESTORE_VALIDATE_MODE=$RESTORE_MODE MANALOOM_RESTORE_POSTGRES_IMAGE=$RESTORE_IMAGE MANALOOM_RESTORE_MIN_TABLES=$RESTORE_MIN_TABLES $REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh >> $REMOTE_LOG_DIR/postgres_restore_check.log 2>&1 # manaloom-postgres-restore-check"

"${ssh_base[@]}" "tmp=\$(mktemp); (crontab -l 2>/dev/null | grep -v '# manaloom-postgres-backup' | grep -v '# manaloom-postgres-restore-check' || true; printf '%s\n' '$backup_cron'; printf '%s\n' '$restore_cron') > \"\$tmp\"; crontab \"\$tmp\"; rm -f \"\$tmp\""

if [ "${MANALOOM_RUN_BACKUP_NOW:-0}" = "1" ]; then
  echo "[install] running first backup now"
  "${ssh_base[@]}" "MANALOOM_POSTGRES_SERVICE='$POSTGRES_SERVICE' MANALOOM_POSTGRES_USER='$POSTGRES_USER' MANALOOM_POSTGRES_DB='$POSTGRES_DB' MANALOOM_BACKUP_DIR='$REMOTE_BACKUP_DIR' MANALOOM_BACKUP_RETENTION_DAYS='$RETENTION_DAYS' '$REMOTE_ROOT/scripts/postgres_backup.sh'"
fi

if [ "${MANALOOM_RUN_RESTORE_CHECK_NOW:-0}" = "1" ]; then
  echo "[install] running first restore check now"
  "${ssh_base[@]}" "MANALOOM_BACKUP_DIR='$REMOTE_BACKUP_DIR' MANALOOM_RESTORE_VALIDATE_MODE='$RESTORE_MODE' MANALOOM_RESTORE_POSTGRES_IMAGE='$RESTORE_IMAGE' MANALOOM_RESTORE_MIN_TABLES='$RESTORE_MIN_TABLES' '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'"
fi

echo "[install] installed cron:"
"${ssh_base[@]}" "crontab -l | grep 'manaloom-postgres-'"
