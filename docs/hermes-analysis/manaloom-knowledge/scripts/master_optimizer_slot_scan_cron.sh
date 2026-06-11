#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
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
git fetch --quiet origin master || true
git checkout master >/dev/null 2>&1 || true
git pull --ff-only origin master >/dev/null 2>&1 || true

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

sync_report="$ARTIFACT_DIR/card_oracle_cache_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --report "$sync_report"

battle_rules_pg_report="$ARTIFACT_DIR/card_battle_rules_pg_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --apply-pg \
  --report "$battle_rules_pg_report"

battle_rules_report="$ARTIFACT_DIR/battle_card_rules_cache_sync_slot_scan_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report "$battle_rules_report"

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
echo "sync_report=$sync_report"
echo "battle_rules_pg_report=$battle_rules_pg_report"
echo "battle_rules_report=$battle_rules_report"
echo "preflight_log=$preflight_log"
echo "baseline_log=$baseline_log"
echo "slot_log=$slot_log"
