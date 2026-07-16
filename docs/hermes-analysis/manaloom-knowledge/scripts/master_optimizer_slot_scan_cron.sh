#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
source "$REPO/scripts/lib/manaloom_mutation_guard.sh"
BATTLE_RULES_APPLY_PG_REQUESTED="${MANALOOM_BATTLE_RULES_APPLY_PG:-0}"
if [[ "$BATTLE_RULES_APPLY_PG_REQUESTED" == "1" ]]; then
  require_postgres_write_approval "master optimizer slot-scan battle-rule PostgreSQL sync"
fi
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
LOCK_FILE="${MANALOOM_SLOT_SCAN_LOCK:-/tmp/manaloom-master-optimizer-slot-scan.lock}"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"
BASELINE_GAMES="${MANALOOM_SLOT_BASELINE_GAMES:-50}"
SLOT_GAMES="${MANALOOM_SLOT_GAMES:-10}"
SLOT_MAX_PER_CATEGORY="${MANALOOM_SLOT_MAX_PER_CATEGORY:-15}"
SLOT_CATEGORY="${MANALOOM_SLOT_CATEGORY:-}"
SLOT_PHASE="${MANALOOM_SLOT_PHASE:-phase1}"
LOREHOLD_CANONICAL_OVERRIDE="${MANALOOM_LOREHOLD_CANONICAL_OVERRIDE:-0}"

if [[ -z "${HERMES_KNOWLEDGE_BACKUP_DIR:-}" ]]; then
  if [[ -d /data/manaloom-ops ]]; then
    export HERMES_KNOWLEDGE_BACKUP_DIR="/data/manaloom-ops/knowledge-backups"
  else
    export HERMES_KNOWLEDGE_BACKUP_DIR="$SCRIPT_DIR/knowledge-backups"
  fi
fi
export HERMES_KNOWLEDGE_BACKUP_KEEP="${HERMES_KNOWLEDGE_BACKUP_KEEP:-${MANALOOM_KNOWLEDGE_BACKUP_KEEP:-5}}"

mkdir -p "$ARTIFACT_DIR"

if [[ -f "$LOCK_FILE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if (( age < 43200 )); then
    echo "slot_scan=locked age_seconds=$age"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true

# Keep operational optimizer code on canonical master. Runtime artifacts such as
# knowledge.db and generated reports must not require the memory docs branch.
git fetch --quiet origin master
git checkout master >/dev/null
git pull --ff-only origin master >/dev/null

if [[ -f "$SECRET_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRET_ENV"
  set +a
  export PGHOST="${PGHOST:-${DB_HOST:-}}"
  export PGPORT="${PGPORT:-${DB_PORT:-5432}}"
  export PGDATABASE="${PGDATABASE:-${DB_NAME:-}}"
  export PGUSER="${PGUSER:-${DB_USER:-}}"
  export PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}"
fi
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-$SCRIPT_DIR/knowledge.db}"

legalities_report="$ARTIFACT_DIR/legalities_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_legalities.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --report "$legalities_report"

sync_report="$ARTIFACT_DIR/card_oracle_cache_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --report "$sync_report"

battle_rules_pg_report="$ARTIFACT_DIR/card_battle_rules_pg_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
if [[ "$BATTLE_RULES_APPLY_PG_REQUESTED" == "1" ]]; then
  python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
    --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
    --apply-pg \
    --report "$battle_rules_pg_report"
else
  printf '{"apply_pg":false,"skipped":true,"reason":"MANALOOM_BATTLE_RULES_APPLY_PG not set to 1; PostgreSQL remains source of truth"}\n' \
    > "$battle_rules_pg_report"
fi

battle_rules_report="$ARTIFACT_DIR/battle_card_rules_cache_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report "$battle_rules_report"

contract_prefix="$ARTIFACT_DIR/pg_hermes_sqlite_contract_audit_slot_scan_$(date -u +%Y%m%d_%H%M%S)"
python3 "$SCRIPT_DIR/pg_hermes_sqlite_contract_audit.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --out-prefix "$contract_prefix"

if [[ "$DECK_ID" == "6" && "$LOREHOLD_CANONICAL_OVERRIDE" == "1" ]]; then
  canonical_log="$ARTIFACT_DIR/lorehold_canonical_slot_scan_$(date -u +%Y%m%d_%H%M%S).log"
  python3 "$SCRIPT_DIR/lorehold_canonical_deck_snapshot.py" \
    --db "$MANALOOM_KNOWLEDGE_DB" \
    --apply-local-sqlite | tee "$canonical_log"
fi

preflight_log="$ARTIFACT_DIR/master_optimizer_slot_scan_preflight_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/master_optimizer_loop.py" --preflight --report | tee "$preflight_log"

baseline_log="$ARTIFACT_DIR/master_optimizer_slot_scan_baseline_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/master_optimizer_baseline.py" \
  --deck-id "$DECK_ID" \
  --games "$BASELINE_GAMES" \
  --report | tee "$baseline_log"

slot_log="$ARTIFACT_DIR/master_optimizer_slot_scan_$(date -u +%Y%m%d_%H%M%S).log"
slot_args=(
  --deck-id "$DECK_ID"
  --games "$SLOT_GAMES"
  --max-per-category "$SLOT_MAX_PER_CATEGORY"
  --phase "$SLOT_PHASE"
  --reset-current-baseline
)
if [[ -n "$SLOT_CATEGORY" ]]; then
  slot_args+=(--category "$SLOT_CATEGORY")
fi
python3 "$SCRIPT_DIR/slot_optimizer.py" "${slot_args[@]}" | tee "$slot_log"
cp "$slot_log" "$ARTIFACT_DIR/latest_master_optimizer_slot_scan.log"

echo "slot_scan=ok"
echo "legalities_report=$legalities_report"
echo "sync_report=$sync_report"
echo "battle_rules_pg_report=$battle_rules_pg_report"
echo "battle_rules_report=$battle_rules_report"
echo "contract_report=$contract_prefix.json"
echo "preflight_log=$preflight_log"
echo "baseline_log=$baseline_log"
echo "slot_log=$slot_log"
