#!/usr/bin/env bash
set -euo pipefail

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
RESTORE_MODE="${MANALOOM_RESTORE_VALIDATE_MODE:-schema}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool ssh

ssh_base=(
  ssh
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
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
RESTORE_IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17}"
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

mv "$tmp_file" "$out_file"
ln -sfn "$out_file" "$BACKUP_DIR/latest.dump"

find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump' -mtime +"$RETENTION_DAYS" -delete

backup_count="$(find "$BACKUP_DIR" -type f -name 'manaloom-postgres-*.dump' | wc -l | tr -d ' ')"
echo "{\"status\":\"ok\",\"file\":\"$out_file\",\"bytes\":$bytes,\"backup_count\":$backup_count,\"retention_days\":$RETENTION_DAYS,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
REMOTE_BACKUP_SCRIPT

"${ssh_base[@]}" "cat > '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'" <<'REMOTE_RESTORE_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${MANALOOM_BACKUP_DIR:-/opt/manaloom/backups/postgres}"
RESTORE_IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17}"
RESTORE_MODE="${MANALOOM_RESTORE_VALIDATE_MODE:-schema}"
DB_NAME="${MANALOOM_RESTORE_DB:-manaloom_restore_check}"
LOCK_FILE="${MANALOOM_RESTORE_LOCK_FILE:-/tmp/manaloom-postgres-restore-check.lock}"
container="manaloom-restore-check-$(date -u +%Y%m%d%H%M%S)"

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

cleanup() {
  docker rm -f "$container" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "$container" -e POSTGRES_PASSWORD=restore_check "$RESTORE_IMAGE" >/dev/null

for _ in $(seq 1 60); do
  if docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker exec "$container" createdb -U postgres "$DB_NAME"
docker cp "$backup_file" "$container:/tmp/backup.dump"

if [ "$RESTORE_MODE" = "full" ]; then
  docker exec "$container" pg_restore -U postgres -d "$DB_NAME" --no-owner --no-privileges /tmp/backup.dump
else
  docker exec "$container" pg_restore -U postgres -d "$DB_NAME" --schema-only --no-owner --no-privileges /tmp/backup.dump
fi

table_count="$(docker exec "$container" psql -U postgres -d "$DB_NAME" -tA -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d '[:space:]')"

if [ "${table_count:-0}" -lt 1 ]; then
  echo "{\"status\":\"error\",\"reason\":\"restore_table_count_zero\",\"backup\":\"$backup_file\",\"mode\":\"$RESTORE_MODE\"}" >&2
  exit 1
fi

bytes="$(wc -c < "$backup_file" | tr -d ' ')"
echo "{\"status\":\"ok\",\"backup\":\"$backup_file\",\"mode\":\"$RESTORE_MODE\",\"table_count\":$table_count,\"bytes\":$bytes,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
REMOTE_RESTORE_SCRIPT

"${ssh_base[@]}" "chmod 700 '$REMOTE_ROOT/scripts/postgres_backup.sh' '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'"

backup_cron="$BACKUP_SCHEDULE MANALOOM_POSTGRES_SERVICE=$POSTGRES_SERVICE MANALOOM_POSTGRES_USER=$POSTGRES_USER MANALOOM_POSTGRES_DB=$POSTGRES_DB MANALOOM_BACKUP_DIR=$REMOTE_BACKUP_DIR MANALOOM_BACKUP_RETENTION_DAYS=$RETENTION_DAYS $REMOTE_ROOT/scripts/postgres_backup.sh >> $REMOTE_LOG_DIR/postgres_backup.log 2>&1 # manaloom-postgres-backup"
restore_cron="$RESTORE_SCHEDULE MANALOOM_BACKUP_DIR=$REMOTE_BACKUP_DIR MANALOOM_RESTORE_VALIDATE_MODE=$RESTORE_MODE $REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh >> $REMOTE_LOG_DIR/postgres_restore_check.log 2>&1 # manaloom-postgres-restore-check"

"${ssh_base[@]}" "tmp=\$(mktemp); (crontab -l 2>/dev/null | grep -v '# manaloom-postgres-backup' | grep -v '# manaloom-postgres-restore-check' || true; printf '%s\n' '$backup_cron'; printf '%s\n' '$restore_cron') > \"\$tmp\"; crontab \"\$tmp\"; rm -f \"\$tmp\""

if [ "${MANALOOM_RUN_BACKUP_NOW:-1}" = "1" ]; then
  echo "[install] running first backup now"
  "${ssh_base[@]}" "MANALOOM_POSTGRES_SERVICE='$POSTGRES_SERVICE' MANALOOM_POSTGRES_USER='$POSTGRES_USER' MANALOOM_POSTGRES_DB='$POSTGRES_DB' MANALOOM_BACKUP_DIR='$REMOTE_BACKUP_DIR' MANALOOM_BACKUP_RETENTION_DAYS='$RETENTION_DAYS' '$REMOTE_ROOT/scripts/postgres_backup.sh'"
fi

if [ "${MANALOOM_RUN_RESTORE_CHECK_NOW:-1}" = "1" ]; then
  echo "[install] running first restore check now"
  "${ssh_base[@]}" "MANALOOM_BACKUP_DIR='$REMOTE_BACKUP_DIR' MANALOOM_RESTORE_VALIDATE_MODE='$RESTORE_MODE' '$REMOTE_ROOT/scripts/postgres_restore_validate_latest.sh'"
fi

echo "[install] installed cron:"
"${ssh_base[@]}" "crontab -l | grep 'manaloom-postgres-'"
