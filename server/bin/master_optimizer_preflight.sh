#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH= cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
SCRIPT_DIR="${MANALOOM_HERMES_SCRIPT_DIR:-$REPO_ROOT/docs/hermes-analysis/manaloom-knowledge/scripts}"
DEFAULT_ARTIFACT_DIR="$REPO_ROOT/server/test/artifacts/master_optimizer_preflight"
if [[ -d /data/manaloom-ops ]]; then
  DEFAULT_ARTIFACT_DIR="/data/manaloom-ops/artifacts/master-optimizer-preflight"
fi
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-$DEFAULT_ARTIFACT_DIR}"
DEFAULT_REPORT_DIR="$REPO_ROOT/docs/hermes-analysis/master_optimizer_reports"
if [[ -d /data/manaloom-ops ]]; then
  DEFAULT_REPORT_DIR="$ARTIFACT_DIR/master_optimizer_reports"
fi
REPORT_DIR="${MANALOOM_MASTER_OPTIMIZER_REPORT_DIR:-$DEFAULT_REPORT_DIR}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}}"
SQLITE_DB="${HERMES_KNOWLEDGE_DB:-$SCRIPT_DIR/knowledge.db}"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"
LOREHOLD_CANONICAL_OVERRIDE="${MANALOOM_LOREHOLD_CANONICAL_OVERRIDE:-0}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ -z "${HERMES_KNOWLEDGE_BACKUP_DIR:-}" ]]; then
  if [[ -d /data/manaloom-ops ]]; then
    export HERMES_KNOWLEDGE_BACKUP_DIR="/data/manaloom-ops/knowledge-backups"
  else
    export HERMES_KNOWLEDGE_BACKUP_DIR="$SCRIPT_DIR/knowledge-backups"
  fi
fi
export HERMES_KNOWLEDGE_BACKUP_KEEP="${HERMES_KNOWLEDGE_BACKUP_KEEP:-${MANALOOM_KNOWLEDGE_BACKUP_KEEP:-5}}"

mkdir -p "$REPORT_DIR" "$ARTIFACT_DIR"

if [[ -f "$SECRET_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRET_ENV"
  set +a
fi

export PGHOST="${PGHOST:-${DB_HOST:-}}"
export PGPORT="${PGPORT:-${DB_PORT:-5432}}"
export PGDATABASE="${PGDATABASE:-${DB_NAME:-}}"
export PGUSER="${PGUSER:-${DB_USER:-}}"
export PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}"

meta_decks_log="$ARTIFACT_DIR/meta_decks_sync_preflight_$(date -u +%Y%m%d_%H%M%S).log"
"$PYTHON_BIN" "$SCRIPT_DIR/sync_pg_meta_decks_to_hermes.py" \
  --sqlite-db "$SQLITE_DB" \
  --limit "${MANALOOM_META_DECK_SYNC_LIMIT:-120}" \
  --min-cards "${MANALOOM_META_DECK_SYNC_MIN_CARDS:-80}" \
  --apply | tee "$meta_decks_log"

target_deck_log="$ARTIFACT_DIR/target_deck_sync_preflight_$(date -u +%Y%m%d_%H%M%S).log"
"$PYTHON_BIN" "$SCRIPT_DIR/sync_pg_target_deck_to_hermes.py" \
  --sqlite-db "$SQLITE_DB" \
  --target-deck-id "$DECK_ID" \
  --apply | tee "$target_deck_log"

sync_report="$ARTIFACT_DIR/card_oracle_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
"$PYTHON_BIN" "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$SQLITE_DB" \
  --report "$sync_report"

battle_rules_pg_report="$ARTIFACT_DIR/card_battle_rules_pg_sync_$(date -u +%Y%m%d_%H%M%S).json"
if [[ "${MANALOOM_BATTLE_RULES_APPLY_PG:-0}" == "1" ]]; then
  "$PYTHON_BIN" "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
    --sqlite-db "$SQLITE_DB" \
    --apply-pg \
    --report "$battle_rules_pg_report"
else
  printf '{"apply_pg":false,"skipped":true,"reason":"MANALOOM_BATTLE_RULES_APPLY_PG not set to 1; PostgreSQL remains source of truth"}\n' \
    > "$battle_rules_pg_report"
fi

battle_rules_report="$ARTIFACT_DIR/battle_card_rules_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
"$PYTHON_BIN" "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SQLITE_DB" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report "$battle_rules_report"

pg_contract_report=""
if [[ -d /data/manaloom-ops ]]; then
  pg_contract_report="$ARTIFACT_DIR/pg_hermes_sqlite_contract_$(date -u +%Y%m%d_%H%M%S)"
  "$PYTHON_BIN" "$SCRIPT_DIR/pg_hermes_sqlite_contract_audit.py" \
    --sqlite-db "$SQLITE_DB" \
    --out-prefix "$pg_contract_report"
fi

if [[ "$DECK_ID" == "6" && "$LOREHOLD_CANONICAL_OVERRIDE" == "1" ]]; then
  canonical_log="$ARTIFACT_DIR/lorehold_canonical_preflight_$(date -u +%Y%m%d_%H%M%S).log"
  "$PYTHON_BIN" "$SCRIPT_DIR/lorehold_canonical_deck_snapshot.py" \
    --db "$SQLITE_DB" \
    --apply-local-sqlite | tee "$canonical_log"
fi

preflight_log="$ARTIFACT_DIR/master_optimizer_preflight_$(date -u +%Y%m%d_%H%M%S).log"
"$PYTHON_BIN" "$SCRIPT_DIR/master_optimizer_loop.py" \
  --db "$SQLITE_DB" \
  --preflight \
  --report | tee "$preflight_log"

latest_report="$(ls -1t "$REPORT_DIR"/master_optimizer_preflight_*.md 2>/dev/null | head -1 || true)"
if [[ -n "$latest_report" ]]; then
  cp "$latest_report" "$ARTIFACT_DIR/latest_master_optimizer_preflight.md"
fi

echo "master_optimizer_preflight=ok"
echo "meta_decks_log=$meta_decks_log"
echo "target_deck_log=$target_deck_log"
echo "sync_report=$sync_report"
echo "battle_rules_pg_report=$battle_rules_pg_report"
echo "battle_rules_report=$battle_rules_report"
echo "pg_contract_report=${pg_contract_report:-skipped_outside_manaloom_ops}"
echo "preflight_log=$preflight_log"
