#!/usr/bin/env bash
set -euo pipefail

SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
BACKUP_DIR="${MANALOOM_BACKUP_DIR:-$PWD/backups/manaloom-postgres}"
RESTORE_IMAGE="${MANALOOM_RESTORE_POSTGRES_IMAGE:-postgres:17}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$BACKUP_DIR/manaloom-postgres-$STAMP.dump"

mkdir -p "$BACKUP_DIR"

echo "[backup] host=$SSH_HOST service=$POSTGRES_SERVICE db=$POSTGRES_DB"
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec \"\$cid\" pg_dump -Fc -U '$POSTGRES_USER' '$POSTGRES_DB'" \
  > "$OUT_FILE"

chmod 600 "$OUT_FILE"
BYTES="$(wc -c < "$OUT_FILE" | tr -d ' ')"
if [ "$BYTES" -lt 1024 ]; then
  echo "[backup] arquivo pequeno demais: $BYTES bytes" >&2
  exit 1
fi

if ! pg_restore --list "$OUT_FILE" >/dev/null 2>&1; then
  BACKUP_ABS="$(cd "$(dirname "$OUT_FILE")" && pwd)/$(basename "$OUT_FILE")"
  if docker info >/dev/null 2>&1; then
    docker run --rm \
      -v "$(dirname "$BACKUP_ABS"):/backup:ro" \
      "$RESTORE_IMAGE" \
      pg_restore --list "/backup/$(basename "$BACKUP_ABS")" >/dev/null
  else
    MANALOOM_RESTORE_MODE=schema "$(dirname "$0")/manaloom_validate_restore.sh" "$BACKUP_ABS" >/dev/null
  fi
fi
echo "[backup] ok file=$OUT_FILE bytes=$BYTES"
