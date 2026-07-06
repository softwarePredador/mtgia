#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:-}"
if [ -z "$BACKUP_FILE" ]; then
  echo "uso: $0 /caminho/backup.dump" >&2
  exit 2
fi
if [ ! -f "$BACKUP_FILE" ]; then
  echo "backup nao encontrado: $BACKUP_FILE" >&2
  exit 2
fi

MODE="${MANALOOM_RESTORE_MODE:-schema}"
IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17}"
CONTAINER="manaloom-restore-validate-$(date -u +%Y%m%d%H%M%S)"
DB_NAME="${MANALOOM_RESTORE_DB:-manaloom_restore_check}"
BACKUP_ABS="$(cd "$(dirname "$BACKUP_FILE")" && pwd)/$(basename "$BACKUP_FILE")"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"

if pg_restore --list "$BACKUP_ABS" >/dev/null 2>&1; then
  :
elif docker info >/dev/null 2>&1; then
  docker run --rm \
    -v "$(dirname "$BACKUP_ABS"):/backup:ro" \
    "$IMAGE" \
    pg_restore --list "/backup/$(basename "$BACKUP_ABS")" >/dev/null
else
  echo "[restore] pg_restore local incompativel e Docker local indisponivel; usando runner remoto isolado."
fi

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! docker info >/dev/null 2>&1; then
  REMOTE_TMP="/tmp/manaloom-restore-$(date -u +%Y%m%d%H%M%S).dump"
  scp -q -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" \
    "$BACKUP_ABS" "$SSH_HOST:$REMOTE_TMP"
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "set -euo pipefail
     container='$CONTAINER'
     cleanup() { docker rm -f \"\$container\" >/dev/null 2>&1 || true; rm -f '$REMOTE_TMP'; }
     trap cleanup EXIT
     docker run -d --name \"\$container\" -e POSTGRES_PASSWORD=restore_check '$IMAGE' >/dev/null
     for i in \$(seq 1 60); do
       if docker exec \"\$container\" pg_isready -U postgres >/dev/null 2>&1; then break; fi
       sleep 1
     done
     docker exec \"\$container\" createdb -U postgres '$DB_NAME'
     docker cp '$REMOTE_TMP' \"\$container:/tmp/backup.dump\"
     if [ '$MODE' = 'full' ]; then
       docker exec \"\$container\" pg_restore -U postgres -d '$DB_NAME' --no-owner --no-privileges /tmp/backup.dump
     else
       docker exec \"\$container\" pg_restore -U postgres -d '$DB_NAME' --schema-only --no-owner --no-privileges /tmp/backup.dump
     fi
     docker exec \"\$container\" psql -U postgres -d '$DB_NAME' -v ON_ERROR_STOP=1 -c \"SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';\""
  echo "[restore] ok mode=$MODE runner=remote backup=$BACKUP_ABS"
  exit 0
fi

docker run -d --name "$CONTAINER" \
  -e POSTGRES_PASSWORD=restore_check \
  "$IMAGE" >/dev/null

for _ in $(seq 1 60); do
  if docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker exec "$CONTAINER" createdb -U postgres "$DB_NAME"
docker cp "$BACKUP_ABS" "$CONTAINER:/tmp/backup.dump"

if [ "$MODE" = "full" ]; then
  docker exec "$CONTAINER" pg_restore -U postgres -d "$DB_NAME" --no-owner --no-privileges /tmp/backup.dump
else
  docker exec "$CONTAINER" pg_restore -U postgres -d "$DB_NAME" --schema-only --no-owner --no-privileges /tmp/backup.dump
fi

docker exec "$CONTAINER" psql -U postgres -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -c "SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';"

echo "[restore] ok mode=$MODE backup=$BACKUP_ABS"
