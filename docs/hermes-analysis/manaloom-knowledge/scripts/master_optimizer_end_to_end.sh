#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"
BASELINE_GAMES="${MANALOOM_BASELINE_GAMES:-50}"
SLOT_GAMES="${MANALOOM_SLOT_GAMES:-10}"
SLOT_MAX_PER_CATEGORY="${MANALOOM_SLOT_MAX_PER_CATEGORY:-15}"
SLOT_PHASE="${MANALOOM_SLOT_PHASE:-phase1}"
SLOT_CATEGORY="${MANALOOM_SLOT_CATEGORY:-}"
CONFIRM_GAMES="${MANALOOM_CONFIRM_GAMES:-10}"
CONFIRM_RUN_LIMIT="${MANALOOM_CONFIRM_RUN_LIMIT:-3}"
CONFIRM_CANDIDATE_LIMIT="${MANALOOM_CONFIRM_CANDIDATE_LIMIT:-25}"
CONFIRM_MIN_SCAN_DELTA="${MANALOOM_CONFIRM_MIN_SCAN_DELTA:--2.0}"
FULL_CONFIRM_GAMES="${MANALOOM_FULL_CONFIRM_GAMES:-50}"
FULL_CONFIRM_RUN_LIMIT="${MANALOOM_FULL_CONFIRM_RUN_LIMIT:-3}"
FULL_CONFIRM_CANDIDATE_LIMIT="${MANALOOM_FULL_CONFIRM_CANDIDATE_LIMIT:-25}"
FULL_CONFIRM_MIN_SCAN_DELTA="${MANALOOM_FULL_CONFIRM_MIN_SCAN_DELTA:-0.5}"
LOCK_FILE="${MANALOOM_END_TO_END_LOCK:-/tmp/manaloom-master-optimizer-end-to-end.lock}"

mkdir -p "$ARTIFACT_DIR"

if [[ -f "$LOCK_FILE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if (( age < 43200 )); then
    echo "master_optimizer_end_to_end=locked age_seconds=$age"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true

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

log="$ARTIFACT_DIR/master_optimizer_end_to_end_$(date -u +%Y%m%d_%H%M%S).log"

{
  echo "== metadata sync =="
  python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --report "$ARTIFACT_DIR/card_oracle_cache_sync_e2e_$(date -u +%Y%m%d_%H%M%S).json"

  echo "== preflight =="
  python3 "$SCRIPT_DIR/master_optimizer_loop.py" --preflight --report

  echo "== baseline =="
  python3 "$SCRIPT_DIR/master_optimizer_baseline.py" \
    --deck-id "$DECK_ID" \
    --games "$BASELINE_GAMES" \
    --report

  echo "== slot scan =="
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
  python3 "$SCRIPT_DIR/slot_optimizer.py" "${slot_args[@]}"

  echo "== quality gate =="
  python3 "$SCRIPT_DIR/master_optimizer_quality_gate.py" \
    --deck-id "$DECK_ID" \
    --limit "$CONFIRM_CANDIDATE_LIMIT" \
    --report

  echo "== confirmation =="
  python3 "$SCRIPT_DIR/master_optimizer_confirmation.py" \
    --deck-id "$DECK_ID" \
    --candidate-limit "$CONFIRM_CANDIDATE_LIMIT" \
    --run-limit "$CONFIRM_RUN_LIMIT" \
    --games "$CONFIRM_GAMES" \
    --min-scan-delta "$CONFIRM_MIN_SCAN_DELTA" \
    --phase confirmation \
    --report

  echo "== full confirmation =="
  python3 "$SCRIPT_DIR/master_optimizer_confirmation.py" \
    --deck-id "$DECK_ID" \
    --candidate-limit "$FULL_CONFIRM_CANDIDATE_LIMIT" \
    --run-limit "$FULL_CONFIRM_RUN_LIMIT" \
    --games "$FULL_CONFIRM_GAMES" \
    --min-scan-delta "$FULL_CONFIRM_MIN_SCAN_DELTA" \
    --phase full_confirmation \
    --report

  echo "== replay audit =="
  python3 "$SCRIPT_DIR/replay_decision_auditor.py" \
    --deck-id "$DECK_ID" \
    --report

  echo "== handoff =="
  python3 "$SCRIPT_DIR/master_optimizer_handoff.py" \
    --deck-id "$DECK_ID" \
    --report

  echo "master_optimizer_end_to_end=ok"
} | tee "$log"

cp "$log" "$ARTIFACT_DIR/latest_master_optimizer_end_to_end.log"
echo "end_to_end_log=$log"
