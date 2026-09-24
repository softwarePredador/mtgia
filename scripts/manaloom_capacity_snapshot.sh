#!/usr/bin/env bash
# BT-CAP-001 (D-14): leitura SÓ DE LEITURA da capacidade do host de produção e
# do PostgreSQL, com procedência. Quem roda na produção é a coordenação.
#
# Uso:
#   scripts/manaloom_capacity_snapshot.sh                  descreve a leitura, sem conectar
#   scripts/manaloom_capacity_snapshot.sh --execute --out <snapshot.json>
#
# Exige MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 (a âncora de host do deploy) e a
# chave SSH do deploy (MANALOOM_EASYPANEL_SSH_KEY). No host roda só as leituras
# de REMOTE_READ_ONLY; no PostgreSQL, server/sql/readonly/capacity_postgres.sql
# pelo wrapper em modo leitura. O JSON sai com a procedência (alvo SSH,
# fingerprint do host, SHA da ferramenta) e é validado antes de gravar.
# Depois: scripts/manaloom_capacity_policy.py preflight --snapshot <arquivo>.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POLICY_TOOL="$ROOT_DIR/scripts/manaloom_capacity_policy.py"
PG_QUERY="$ROOT_DIR/server/sql/readonly/capacity_postgres.sql"
EXECUTE=0
OUT=""

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --out) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Só leituras: /proc, uname, df e docker stats/service ls/service inspect.
# O contrato (server/test/capacity_policy_test.py) confere linha a linha.
REMOTE_READ_ONLY="$(cat <<'REMOTE'
echo '### date'
date -u +%Y-%m-%dT%H:%M:%SZ
echo '### nproc'
nproc
echo '### meminfo'
cat /proc/meminfo
echo '### loadavg'
cat /proc/loadavg
echo '### uptime'
cat /proc/uptime
echo '### kernel'
uname -r
echo '### df'
df -P -B1 /
echo '### docker_stats'
docker stats --no-stream --format '{{json .}}'
echo '### docker_services'
docker service ls --format '{{json .}}'
echo '### docker_resources'
docker service inspect --format '{{.Spec.Name}}{{"\t"}}{{json .Spec.TaskTemplate.Resources}}' $(docker service ls -q)
echo '### end'
REMOTE
)"

if [[ "$EXECUTE" != "1" ]]; then
  python3 - "$SSH_HOST" "$REMOTE_READ_ONLY" <<'PY'
import json
import sys

print(json.dumps({
    "status": "dry_run",
    "ssh_target": sys.argv[1],
    "remote_read_only": sys.argv[2].splitlines(),
    "postgres": "server/sql/readonly/capacity_postgres.sql (with_new_server_pg.sh --read-only psql)",
    "execute": "--execute --out <snapshot.json>",
}, ensure_ascii=False, indent=2))
PY
  exit 0
fi

if [[ -z "$OUT" ]]; then
  echo "--execute exige --out <snapshot.json>" >&2
  exit 2
fi
if [[ ! -f "$SSH_KEY" ]]; then
  echo "chave SSH do deploy não encontrada: $SSH_KEY" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
initialize_manaloom_secure_ssh "$SSH_HOST"
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-capacity.XXXXXX")"
cleanup() {
  cleanup_manaloom_secure_ssh
  rm -rf "$RUN_DIR"
}
trap cleanup EXIT

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "$REMOTE_READ_ONLY" \
  >"$RUN_DIR/host.txt"
"$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only psql \
  -X -q -v ON_ERROR_STOP=1 -A -t -F $'\t' -f "$PG_QUERY" >"$RUN_DIR/postgres.tsv"

tree_clean=false
if [[ -z "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  tree_clean=true
fi
python3 "$POLICY_TOOL" snapshot \
  --host-raw "$RUN_DIR/host.txt" \
  --postgres-raw "$RUN_DIR/postgres.tsv" \
  --ssh-target "$SSH_HOST" \
  --host-key "$MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256" \
  --git-sha "$(git -C "$ROOT_DIR" rev-parse HEAD)" \
  --tree-clean "$tree_clean" \
  --out "$OUT"
python3 "$POLICY_TOOL" validate-snapshot "$OUT"
