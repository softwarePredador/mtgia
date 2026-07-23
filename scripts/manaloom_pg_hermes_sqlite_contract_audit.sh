#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_PREFIX="${MANALOOM_PG_HERMES_SQLITE_CONTRACT_AUDIT_OUT_PREFIX:-/tmp/manaloom_pg_hermes_sqlite_contract_audit_$STAMP}"

cd "$ROOT_DIR"
"$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \
  python3 "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py" \
  --out-prefix "$OUT_PREFIX" \
  "$@"
