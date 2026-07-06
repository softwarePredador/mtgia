#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH= cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}}"
LOCAL_HOST="${MANALOOM_NEW_SERVER_PG_LOCAL_HOST:-127.0.0.1}"
LOCAL_PORT="${MANALOOM_NEW_SERVER_PG_LOCAL_PORT:-15432}"
REMOTE_HOST="${MANALOOM_NEW_SERVER_PG_REMOTE_HOST:-127.0.0.1}"
REMOTE_PORT="${MANALOOM_NEW_SERVER_PG_REMOTE_PORT:-15432}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "with_new_server_pg: env file not found: $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

required=(
  EASYPANEL_SERVER_IP
  EASYPANEL_SSH_USER
  EASYPANEL_SSH_KEY
  DB_NAME
  DB_USER
  DB_PASS
)
missing=()
for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    missing+=("$key")
  fi
done
if (( ${#missing[@]} )); then
  echo "with_new_server_pg: missing env keys: ${missing[*]}" >&2
  exit 2
fi
if [[ ! -f "$EASYPANEL_SSH_KEY" ]]; then
  echo "with_new_server_pg: EASYPANEL_SSH_KEY file is not readable" >&2
  exit 2
fi

port_open() {
  nc -z "$LOCAL_HOST" "$LOCAL_PORT" >/dev/null 2>&1
}

if ! port_open; then
  ssh \
    -i "$EASYPANEL_SSH_KEY" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ExitOnForwardFailure=yes \
    -fN \
    -L "${LOCAL_HOST}:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" \
    "${EASYPANEL_SSH_USER}@${EASYPANEL_SERVER_IP}"
fi

export DB_HOST="$LOCAL_HOST"
export DB_PORT="$LOCAL_PORT"
export PGHOST="$LOCAL_HOST"
export PGPORT="$LOCAL_PORT"
export PGDATABASE="$DB_NAME"
export PGUSER="$DB_USER"
export PGPASSWORD="$DB_PASS"
export DATABASE_URL="$(
  "$PYTHON_BIN" - <<'PY'
import os
from urllib.parse import quote

user = quote(os.environ["DB_USER"], safe="")
password = quote(os.environ["DB_PASS"], safe="")
host = os.environ["DB_HOST"]
port = os.environ["DB_PORT"]
db = quote(os.environ["DB_NAME"], safe="")
print(f"postgresql://{user}:{password}@{host}:{port}/{db}?sslmode=disable")
PY
)"

if ! pg_isready -h "$PGHOST" -p "$PGPORT" -d "$PGDATABASE" -U "$PGUSER" >/dev/null 2>&1; then
  echo "with_new_server_pg: PostgreSQL tunnel is not ready at ${PGHOST}:${PGPORT}/${PGDATABASE}" >&2
  exit 1
fi

if (( $# == 0 )); then
  psql -X -v ON_ERROR_STOP=1 -At -c "select current_database(), count(*) from cards;"
  exit 0
fi

exec "$@"
