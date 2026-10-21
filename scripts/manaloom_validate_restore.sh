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
IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17.10-alpine3.23@sha256:8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4}"
CONTAINER="manaloom-restore-validate-$(date -u +%Y%m%d%H%M%S)-$$"
DB_NAME="${MANALOOM_RESTORE_DB:-manaloom_restore_check}"
BACKUP_ABS="$(cd "$(dirname "$BACKUP_FILE")" && pwd)/$(basename "$BACKUP_FILE")"

if pg_restore --list "$BACKUP_ABS" >/dev/null 2>&1; then
  :
elif docker info >/dev/null 2>&1; then
  docker run --rm \
    -v "$(dirname "$BACKUP_ABS"):/backup:ro" \
    "$IMAGE" \
    pg_restore --list "/backup/$(basename "$BACKUP_ABS")" >/dev/null
else
  echo "[restore] recusado: pg_restore local incompativel e Docker local indisponivel; nenhum fallback remoto e permitido." >&2
  exit 2
fi

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-restore-validate.XXXXXX")"
CID_FILE="$RUN_DIR/container-id"
cleanup() {
  local status=$? cid remaining
  trap - EXIT
  trap '' INT TERM
  # Only Docker's ID from this private run directory may be removed.
  if [[ -s "$CID_FILE" ]]; then
    cid="$(cat "$CID_FILE")"
    if [[ "$cid" =~ ^[0-9a-f]{64}$ ]]; then
      if ! docker rm -f -v "$cid" >/dev/null 2>&1; then
        if ! remaining="$(docker ps -aq --no-trunc --filter "id=$cid")" || [[ -n "$remaining" ]]; then
          echo "[restore] falha ao limpar container temporario e volumes: $cid" >&2
          if [[ "$status" == "0" ]]; then status=1; fi
        fi
      fi
    else
      echo "[restore] ID temporario invalido; nenhum container removido" >&2
      if [[ "$status" == "0" ]]; then status=1; fi
    fi
  fi
  rm -rf -- "$RUN_DIR" || status=1
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

docker run -d --rm --cidfile "$CID_FILE" --name "$CONTAINER" --network none \
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
