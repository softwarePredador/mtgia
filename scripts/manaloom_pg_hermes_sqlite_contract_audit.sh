#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_PREFIX="${MANALOOM_PG_HERMES_SQLITE_CONTRACT_AUDIT_OUT_PREFIX:-/tmp/manaloom_pg_hermes_sqlite_contract_audit_$STAMP}"

cd "$ROOT_DIR"
require_live_mutation_approval "ManaLoom PostgreSQL Hermes SQLite runner"
require_postgres_write_approval "ManaLoom PostgreSQL Hermes SQLite runner"
"$ROOT_DIR/server/bin/with_new_server_pg.sh" --write-approved \
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py \
  --out-prefix "$OUT_PREFIX" \
  "$@"
