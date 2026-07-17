#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH='' cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}}"
LOCAL_HOST="127.0.0.1"
REMOTE_HOST="${MANALOOM_NEW_SERVER_PG_REMOTE_HOST:-127.0.0.1}"
REMOTE_PORT="${MANALOOM_NEW_SERVER_PG_REMOTE_PORT:-15432}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
MODE=""
SSH_PID=""
SSH_KNOWN_HOSTS=""
SSH_SCAN_FILE=""

usage() {
  cat >&2 <<'EOF'
Uso:
  with_new_server_pg.sh --read-only psql [argumentos]
  with_new_server_pg.sh --write-approved comando [argumentos]

O modo read-only aceita apenas psql e injeta default_transaction_read_only=on.
O modo write-approved exige as duas aprovacoes canonicas no processo chamador.
EOF
}

case "${1:-}" in
  --read-only) MODE="read-only"; shift ;;
  --write-approved) MODE="write-approved"; shift ;;
  *) usage; exit 2 ;;
esac

if (( $# == 0 )); then
  usage
  exit 2
fi

# Aprovação vem exclusivamente do processo chamador e é conferida antes
# da leitura do arquivo persistente de ambiente.
if [[ "$MODE" == "write-approved" ]]; then
  # shellcheck source=scripts/lib/manaloom_mutation_guard.sh
  source "$REPO_ROOT/scripts/lib/manaloom_mutation_guard.sh"
  require_live_mutation_approval "acesso de escrita ao PostgreSQL ManaLoom"
  require_postgres_write_approval "acesso de escrita ao PostgreSQL ManaLoom"
  readonly MANALOOM_PG_WRITE_APPROVED=1
else
  if [[ "$(basename -- "$1")" != "psql" ]]; then
    echo "with_new_server_pg: modo read-only aceita somente o cliente psql" >&2
    exit 2
  fi
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "with_new_server_pg: env file not found: $ENV_FILE" >&2
  exit 2
fi

# O .env é dado, não programa shell. Somente chaves necessárias entram no
# processo e nenhuma expansão/comando contido no arquivo é executado.
# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$REPO_ROOT/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  EASYPANEL_SERVER_IP EASYPANEL_SSH_USER EASYPANEL_SSH_KEY \
  DB_NAME DB_USER DB_PASS

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
EASYPANEL_SSH_KEY="$(python3 - "$REPO_ROOT" "$EASYPANEL_SSH_KEY" <<'PY'
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
candidate = Path(sys.argv[2]).expanduser()
if not candidate.is_absolute():
    candidate = repo_root / candidate
print(candidate.resolve())
PY
)"
if [[ ! -f "$EASYPANEL_SSH_KEY" ]]; then
  echo "with_new_server_pg: EASYPANEL_SSH_KEY file is not readable" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$REPO_ROOT/scripts/lib/manaloom_release_runtime_contract.sh"
SSH_TARGET="${EASYPANEL_SSH_USER}@${EASYPANEL_SERVER_IP}"
validate_manaloom_ssh_target_syntax "$SSH_TARGET"
validate_manaloom_exact_coordinate postgres_remote_host "$REMOTE_HOST" 127.0.0.1
validate_manaloom_exact_coordinate postgres_remote_port "$REMOTE_PORT" 15432
validate_manaloom_exact_coordinate postgres_database "$DB_NAME" halder
validate_manaloom_exact_coordinate postgres_user "$DB_USER" postgres

cleanup() {
  if [[ -n "$SSH_PID" ]] && kill -0 "$SSH_PID" 2>/dev/null; then
    kill "$SSH_PID" 2>/dev/null || true
    wait "$SSH_PID" 2>/dev/null || true
  fi
  if [[ -n "$SSH_SCAN_FILE" ]]; then
    rm -f "$SSH_SCAN_FILE"
  fi
  if [[ -n "$SSH_KNOWN_HOSTS" ]]; then
    rm -f "$SSH_KNOWN_HOSTS"
  fi
}
trap cleanup EXIT INT TERM

for tool in "$PYTHON_BIN" ssh ssh-keyscan ssh-keygen lsof nc pg_isready; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "with_new_server_pg: ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

# O fingerprint é uma âncora independente do .env; sem ele não enviamos
# chave, usuário ou senha a um host selecionado pelo próprio arquivo.
EXPECTED_HOST_KEY="${MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256:-}"
if [[ ! "$EXPECTED_HOST_KEY" =~ ^SHA256:[A-Za-z0-9+/]{43}$ ]]; then
  echo "with_new_server_pg: defina MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 com o fingerprint aprovado" >&2
  exit 2
fi
SSH_KNOWN_HOSTS="$(mktemp /tmp/manaloom-pg-known-hosts.XXXXXX)"
SSH_SCAN_FILE="$(mktemp /tmp/manaloom-pg-ssh-scan.XXXXXX)"
chmod 600 "$SSH_KNOWN_HOSTS" "$SSH_SCAN_FILE"
ssh-keyscan -T 10 "$EASYPANEL_SERVER_IP" >"$SSH_SCAN_FILE" 2>/dev/null || true
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  [[ "$line" == \#* ]] && continue
  fingerprint="$(printf '%s\n' "$line" | ssh-keygen -lf - -E sha256 2>/dev/null | awk '{print $2}')"
  if [[ "$fingerprint" == "$EXPECTED_HOST_KEY" ]]; then
    printf '%s\n' "$line" >>"$SSH_KNOWN_HOSTS"
  fi
done <"$SSH_SCAN_FILE"
rm -f "$SSH_SCAN_FILE"
SSH_SCAN_FILE=""
if [[ ! -s "$SSH_KNOWN_HOSTS" ]]; then
  echo "with_new_server_pg: host SSH nao apresentou chave" >&2
  exit 1
fi

# Reserva uma porta efêmera e inicia um túnel pertencente a este processo. O
# helper nunca reutiliza um listener local encontrado apenas com nc.
LOCAL_PORT="$($PYTHON_BIN - <<'PY'
import socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

ssh \
  -i "$EASYPANEL_SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o "UserKnownHostsFile=$SSH_KNOWN_HOSTS" \
  -o ExitOnForwardFailure=yes \
  -N \
  -L "${LOCAL_HOST}:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" \
  "$SSH_TARGET" &
SSH_PID=$!

ready=0
for _attempt in $(seq 1 40); do
  if ! kill -0 "$SSH_PID" 2>/dev/null; then
    break
  fi
  if nc -z "$LOCAL_HOST" "$LOCAL_PORT" >/dev/null 2>&1 &&
     lsof -nP -a -p "$SSH_PID" -iTCP@"$LOCAL_HOST":"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.25
done
if [[ "$ready" != "1" ]]; then
  echo "with_new_server_pg: tunnel SSH proprio nao ficou pronto" >&2
  exit 1
fi

export DB_HOST="$LOCAL_HOST"
export DB_PORT="$LOCAL_PORT"
export PGHOST="$LOCAL_HOST"
export PGPORT="$LOCAL_PORT"
export PGDATABASE="$DB_NAME"
export PGUSER="$DB_USER"
export PGPASSWORD="$DB_PASS"
export PGAPPNAME="manaloom-${MODE}"
MANALOOM_PG_WRAPPER_MODE="$MODE"
readonly MANALOOM_PG_WRAPPER_MODE
export MANALOOM_PG_WRAPPER_MODE
if [[ "$MODE" == "read-only" ]]; then
  export PGOPTIONS="-c default_transaction_read_only=on -c statement_timeout=120000"
fi
DATABASE_URL="$($PYTHON_BIN - <<'PY'
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
export DATABASE_URL

if ! pg_isready -h "$PGHOST" -p "$PGPORT" -d "$PGDATABASE" -U "$PGUSER" >/dev/null 2>&1; then
  echo "with_new_server_pg: PostgreSQL tunnel is not ready" >&2
  exit 1
fi

if [[ "$MODE" == "write-approved" && "${MANALOOM_PG_WRITE_APPROVED:-0}" != "1" ]]; then
  echo "with_new_server_pg: aprovacao de escrita nao foi preservada" >&2
  exit 2
fi

"$@"
