#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
REPORT_DIR="$REPO/docs/hermes-analysis/master_optimizer_reports"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"

META_DECK_LIMIT="${MANALOOM_META_DECK_SYNC_LIMIT:-120}"
META_DECK_MIN_CARDS="${MANALOOM_META_DECK_SYNC_MIN_CARDS:-80}"
BASELINE_GAMES="${MANALOOM_AUTO_BASELINE_GAMES:-50}"
SLOT_GAMES="${MANALOOM_AUTO_SLOT_GAMES:-10}"
SLOT_MAX_PER_CATEGORY="${MANALOOM_AUTO_SLOT_MAX_PER_CATEGORY:-12}"
SLOT_CATEGORY="${MANALOOM_AUTO_SLOT_CATEGORY:-}"
SLOT_PHASE="${MANALOOM_AUTO_SLOT_PHASE:-phase1}"
CONFIRM_GAMES="${MANALOOM_AUTO_CONFIRM_GAMES:-15}"
CONFIRM_RUN_LIMIT="${MANALOOM_AUTO_CONFIRM_RUN_LIMIT:-4}"
CONFIRM_CANDIDATE_LIMIT="${MANALOOM_AUTO_CONFIRM_CANDIDATE_LIMIT:-20}"
CONFIRM_MIN_SCAN_DELTA="${MANALOOM_AUTO_CONFIRM_MIN_SCAN_DELTA:-0.0}"
FULL_CONFIRM_GAMES="${MANALOOM_AUTO_FULL_CONFIRM_GAMES:-50}"
FULL_CONFIRM_RUN_LIMIT="${MANALOOM_AUTO_FULL_CONFIRM_RUN_LIMIT:-2}"
FULL_CONFIRM_CANDIDATE_LIMIT="${MANALOOM_AUTO_FULL_CONFIRM_CANDIDATE_LIMIT:-10}"
FULL_CONFIRM_MIN_SCAN_DELTA="${MANALOOM_AUTO_FULL_CONFIRM_MIN_SCAN_DELTA:-0.5}"
APPLY_MIN_DELTA="${MANALOOM_AUTO_APPLY_MIN_DELTA:-1.0}"
POST_APPLY_MIN_DELTA="${MANALOOM_AUTO_POST_APPLY_MIN_DELTA:-0.0}"
LOCK_FILE="${MANALOOM_AUTO_CYCLE_LOCK:-/tmp/manaloom-master-optimizer-auto-cycle.lock}"
RUN_STAMP="$(date -u +%Y%m%d_%H%M%S)"
ENGINE_METRICS_DIR="${MANALOOM_ENGINE_METRICS_DIR:-$ARTIFACT_DIR/engine_metrics/$RUN_STAMP}"

mkdir -p "$REPORT_DIR" "$ARTIFACT_DIR"

if [[ -f "$LOCK_FILE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if (( age < 43200 )); then
    echo "master_optimizer_auto_cycle=locked age_seconds=$age"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true
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

export MANALOOM_HERMES_SCRIPT_DIR="$SCRIPT_DIR"
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-$SCRIPT_DIR/knowledge.db}"
export MANALOOM_KNOWN_CARDS_OUT="${MANALOOM_KNOWN_CARDS_OUT:-$SCRIPT_DIR/known_cards_generated.json}"
export MANALOOM_SLOT_SCAN_LOCK="${MANALOOM_SLOT_SCAN_LOCK:-/tmp/manaloom-master-optimizer-auto-cycle-slot.lock}"
export MANALOOM_ENGINE_METRICS_DIR="$ENGINE_METRICS_DIR"
mkdir -p "$MANALOOM_ENGINE_METRICS_DIR"

log="$ARTIFACT_DIR/master_optimizer_auto_cycle_${RUN_STAMP}.log"
apply_out="$(mktemp)"

{
  echo "== auto cycle config =="
  echo "deck_id=$DECK_ID"
  echo "meta_deck_limit=$META_DECK_LIMIT"
  echo "meta_deck_min_cards=$META_DECK_MIN_CARDS"
  echo "baseline_games=$BASELINE_GAMES"
  echo "slot_games=$SLOT_GAMES"
  echo "slot_max_per_category=$SLOT_MAX_PER_CATEGORY"
  echo "slot_category=${SLOT_CATEGORY:-all}"
  echo "confirm_games=$CONFIRM_GAMES"
  echo "full_confirm_games=$FULL_CONFIRM_GAMES"
  echo "apply_min_delta=$APPLY_MIN_DELTA"
  echo "post_apply_min_delta=$POST_APPLY_MIN_DELTA"
  echo "engine_metrics_dir=$MANALOOM_ENGINE_METRICS_DIR"

  echo "== pg meta decks sync =="
  python3 "$SCRIPT_DIR/sync_pg_meta_decks_to_hermes.py" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --limit "$META_DECK_LIMIT" \
    --min-cards "$META_DECK_MIN_CARDS" \
    --apply

  echo "== metadata sync =="
  python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --report "$ARTIFACT_DIR/card_oracle_cache_sync_auto_cycle_$(date -u +%Y%m%d_%H%M%S).json"

  echo "== battle card rules sync =="
  python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --apply-pg \
    --report "$ARTIFACT_DIR/card_battle_rules_pg_sync_auto_cycle_$(date -u +%Y%m%d_%H%M%S).json"

  python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --apply-sqlite-from-pg \
    --include-needs-review \
    --report "$ARTIFACT_DIR/battle_card_rules_cache_sync_auto_cycle_$(date -u +%Y%m%d_%H%M%S).json"

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

  echo "== replay audit before apply =="
  python3 "$SCRIPT_DIR/replay_decision_auditor.py" \
    --deck-id "$DECK_ID" \
    --report

  echo "== battle effect coverage audit before apply =="
  python3 "$SCRIPT_DIR/battle_effect_coverage_audit.py" \
    --deck-id "$DECK_ID" \
    --sqlite-db "$SCRIPT_DIR/knowledge.db" \
    --opponent-limit "${MANALOOM_BATTLE_REAL_OPPONENT_LIMIT:-12}" \
    --seed "${MANALOOM_BATTLE_REAL_OPPONENT_SEED:-auto-cycle}" \
    --report

  echo "== handoff before apply =="
  python3 "$SCRIPT_DIR/master_optimizer_handoff.py" \
    --deck-id "$DECK_ID" \
    --report

  echo "== safe Hermes-local apply =="
  set +e
  python3 "$SCRIPT_DIR/master_optimizer_apply.py" \
    --deck-id "$DECK_ID" \
    --min-delta "$APPLY_MIN_DELTA" \
    --report >"$apply_out" 2>&1
  apply_code=$?
  set -e
  cat "$apply_out"
  if (( apply_code == 0 )); then
    echo "auto_cycle_apply=applied"
    echo "== post-apply baseline =="
    python3 "$SCRIPT_DIR/master_optimizer_baseline.py" \
      --deck-id "$DECK_ID" \
      --games "$BASELINE_GAMES" \
      --report
    echo "== post-apply gate =="
    set +e
    python3 "$SCRIPT_DIR/master_optimizer_post_apply_gate.py" \
      --deck-id "$DECK_ID" \
      --min-post-delta "$POST_APPLY_MIN_DELTA" \
      --rollback-on-fail \
      --report
    post_gate_code=$?
    set -e
    if (( post_gate_code == 20 )); then
      echo "auto_cycle_post_apply=rolled_back"
      echo "== post-rollback baseline =="
      python3 "$SCRIPT_DIR/master_optimizer_baseline.py" \
        --deck-id "$DECK_ID" \
        --games "$BASELINE_GAMES" \
        --report
    else
      echo "auto_cycle_post_apply=kept"
      echo "== post-apply replay audit =="
      python3 "$SCRIPT_DIR/replay_decision_auditor.py" \
        --deck-id "$DECK_ID" \
        --report
      echo "== product handoff =="
      python3 "$SCRIPT_DIR/master_optimizer_product_handoff.py" \
        --deck-id "$DECK_ID" \
        --report
    fi
  else
    echo "auto_cycle_apply=no_candidate_or_blocked"
  fi

  echo "== engine metrics aggregate =="
  metrics_report="$ARTIFACT_DIR/engine_metrics_report_${RUN_STAMP}.json"
  python3 "$SCRIPT_DIR/engine_metrics_report.py" \
    --input-dir "$MANALOOM_ENGINE_METRICS_DIR" \
    --output "$metrics_report"
  cp "$metrics_report" "$ARTIFACT_DIR/latest_engine_metrics_report.json"
  echo "engine_metrics_report=$metrics_report"

  echo "master_optimizer_auto_cycle=ok"
} | tee "$log"

rm -f "$apply_out"
cp "$log" "$ARTIFACT_DIR/latest_master_optimizer_auto_cycle.log"
echo "auto_cycle_log=$log"
