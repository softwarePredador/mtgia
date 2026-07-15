#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${MANALOOM_BATTLE_STRATEGY_BASE_DIR:-${MANALOOM_OPS_DATA_DIR:-/data/manaloom-ops}}"
REPO_DIR="${MANALOOM_REPO_DIR:-${MTGIA_HOME:-/app}}"
STATE_DIR="${MANALOOM_BATTLE_STRATEGY_STATE_DIR:-$BASE_DIR/state}"
LOG_DIR="${MANALOOM_BATTLE_STRATEGY_LOG_DIR:-$BASE_DIR/logs}"
ARTIFACT_ROOT="${MANALOOM_BATTLE_STRATEGY_ARTIFACT_ROOT:-$BASE_DIR/artifacts/battle-strategy-audit}"
LOCK_FILE="${MANALOOM_BATTLE_STRATEGY_LOCK_FILE:-$STATE_DIR/manaloom-battle-strategy-audit.lock}"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$ARTIFACT_ROOT"

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') another battle strategy audit run is active"
    exit 0
  fi
else
  LOCK_DIR="${LOCK_FILE}.d"
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') another battle strategy audit run is active"
    exit 0
  fi
  trap 'rm -rf "$LOCK_DIR"' EXIT
fi

if [[ "${MANALOOM_BATTLE_STRATEGY_LOG_TO_STDOUT:-1}" == "1" ]]; then
  exec > >(tee -a "$LOG_DIR/battle-strategy-audit.log") 2>&1
else
  exec >> "$LOG_DIR/battle-strategy-audit.log" 2>&1
fi

timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
DRY_RUN=0
ORIGINAL_ARGC="$#"
if [[ -n "${MANALOOM_BATTLE_STRATEGY_SEEDS:-}" ]]; then
  SEEDS_SOURCE="env"
else
  SEEDS_SOURCE="default"
fi
SEEDS="${MANALOOM_BATTLE_STRATEGY_SEEDS:-16}"
if [[ -n "${MANALOOM_BATTLE_STRATEGY_START_SEED:-}" ]]; then
  START_SEED_SOURCE="env"
else
  START_SEED_SOURCE="generated"
fi
START_SEED="${MANALOOM_BATTLE_STRATEGY_START_SEED:-}"
REAL_OPPONENT_SEED="${MANALOOM_BATTLE_REAL_OPPONENT_SEED:-2026061512}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --seeds)
      SEEDS="${2:-}"
      SEEDS_SOURCE="cli"
      shift 2
      ;;
    --start-seed)
      START_SEED="${2:-}"
      START_SEED_SOURCE="cli"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 2
      ;;
  esac
done

if [[ ! "$SEEDS" =~ ^[0-9]+$ || "$SEEDS" -lt 1 ]]; then
  echo "Invalid --seeds value: $SEEDS"
  exit 2
fi
if [[ -z "$START_SEED" ]]; then
  seed_slot="$(date -u '+%j%H%M')"
  START_SEED=$((61500000 + 10#$seed_slot))
fi
if [[ ! "$START_SEED" =~ ^[0-9]+$ ]]; then
  echo "Invalid --start-seed value: $START_SEED"
  exit 2
fi
if [[ "$SEEDS" -eq 1 ]]; then
  RUN_SCOPE="focused_seed"
  RUN_PROFILE="${MANALOOM_BATTLE_STRATEGY_RUN_PROFILE:-focused_single_seed}"
elif [[ "$SEEDS" -eq 16 ]]; then
  RUN_SCOPE="recurring_full"
  RUN_PROFILE="${MANALOOM_BATTLE_STRATEGY_RUN_PROFILE:-recurring_16_seed}"
else
  RUN_SCOPE="custom_multi_seed"
  RUN_PROFILE="${MANALOOM_BATTLE_STRATEGY_RUN_PROFILE:-custom_${SEEDS}_seed}"
fi
if [[ -n "${MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND:-}" ]]; then
  INVOCATION_KIND="$MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND"
elif [[ "$ORIGINAL_ARGC" -gt 0 ]]; then
  INVOCATION_KIND="manual_cli"
elif [[ "$SEEDS_SOURCE" == "env" || "$START_SEED_SOURCE" == "env" ]]; then
  INVOCATION_KIND="environment_configured"
else
  INVOCATION_KIND="default_or_scheduled"
fi

echo "[$timestamp] battle strategy audit start dry_run=$DRY_RUN seeds=$SEEDS start_seed=$START_SEED run_profile=$RUN_PROFILE run_scope=$RUN_SCOPE invocation_kind=$INVOCATION_KIND"

if [[ ! -d "$REPO_DIR" ]]; then
  echo "Repository not found: $REPO_DIR"
  exit 1
fi

SCRIPTS_DIR="$REPO_DIR/docs/hermes-analysis/manaloom-knowledge/scripts"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
  echo "Battle scripts directory not found: $SCRIPTS_DIR"
  exit 1
fi
KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-${HERMES_KNOWLEDGE_DB:-$SCRIPTS_DIR/knowledge.db}}"
if [[ ! -f "$KNOWLEDGE_DB" ]]; then
  echo "Knowledge DB not found: $KNOWLEDGE_DB"
  exit 1
fi

required=(
  "$SCRIPTS_DIR/battle_replay_v10_3.py"
  "$SCRIPTS_DIR/battle_action_critic.py"
  "$SCRIPTS_DIR/battle_decision_strategy_auditor.py"
  "$SCRIPTS_DIR/battle_decision_trace_taxonomy_audit.py"
  "$SCRIPTS_DIR/battle_decision_research_review.py"
  "$SCRIPTS_DIR/battle_event_contract_static_audit.py"
  "$SCRIPTS_DIR/battle_effect_coverage_audit.py"
  "$SCRIPTS_DIR/battle_effect_coverage_residual_audit.py"
  "$SCRIPTS_DIR/battle_focused_template_dispatch_audit.py"
  "$SCRIPTS_DIR/battle_forensic_audit.py"
  "$SCRIPTS_DIR/battle_runtime_surface_manifest.py"
  "$SCRIPTS_DIR/battle_table_intent_audit.py"
  "$SCRIPTS_DIR/battle_target_pressure_audit.py"
  "$SCRIPTS_DIR/battle_unknown_template_backlog_audit.py"
  "$SCRIPTS_DIR/replay_decision_auditor.py"
  "$SCRIPTS_DIR/test_battle_analyst_v10_3.py"
  "$SCRIPTS_DIR/test_battle_action_critic.py"
  "$SCRIPTS_DIR/test_battle_decision_strategy_auditor.py"
  "$SCRIPTS_DIR/test_battle_decision_trace_taxonomy_audit.py"
  "$SCRIPTS_DIR/test_battle_decision_research_review.py"
  "$SCRIPTS_DIR/test_battle_event_contract_static_audit.py"
  "$SCRIPTS_DIR/test_battle_replay_v10_3_renderer.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_known_cards.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_residual_audit.py"
  "$SCRIPTS_DIR/test_battle_focused_template_dispatch_audit.py"
  "$SCRIPTS_DIR/test_battle_rule_registry_runtime_safe.py"
  "$SCRIPTS_DIR/test_battle_script_entrypoint_symbols.py"
  "$SCRIPTS_DIR/test_battle_forensic_audit_supported_effects.py"
  "$SCRIPTS_DIR/test_replay_decision_auditor_scope.py"
  "$SCRIPTS_DIR/test_battle_runtime_surface_manifest.py"
  "$SCRIPTS_DIR/test_battle_table_intent_audit.py"
  "$SCRIPTS_DIR/test_battle_target_pressure_audit.py"
  "$SCRIPTS_DIR/test_battle_unknown_template_backlog_audit.py"
)
for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Required file missing: $file"
    exit 1
  fi
done

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run complete. Would run $SEEDS battle strategy replay(s)."
  exit 0
fi

run_id="$(date -u '+%Y%m%d_%H%M%S')"
run_dir="$ARTIFACT_ROOT/$run_id"
mkdir -p "$run_dir"

# Keep runtime writes under the persistent operational data root.
cd "$BASE_DIR"

TEST_RESULTS_JSONL="$run_dir/test_results.jsonl"
: > "$TEST_RESULTS_JSONL"

run_logged_check() {
  local name="$1"
  shift
  local log_path="$run_dir/${name}.log"
  local stdout_path="$run_dir/${name}.stdout.log"
  local stderr_path="$run_dir/${name}.stderr.log"
  local start_iso
  local end_iso
  local start_epoch
  local end_epoch
  local duration_seconds
  local exit_code
  local stdout_bytes
  local stderr_bytes
  local log_bytes
  local stdout_lines
  local stderr_lines
  local log_lines

  start_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  start_epoch="$(date +%s)"
  set +e
  "$@" > "$stdout_path" 2> "$stderr_path"
  exit_code=$?
  set -e
  end_epoch="$(date +%s)"
  end_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  duration_seconds=$((end_epoch - start_epoch))
  cat "$stdout_path" "$stderr_path" > "$log_path"

  stdout_bytes="$(wc -c < "$stdout_path" | tr -d '[:space:]')"
  stderr_bytes="$(wc -c < "$stderr_path" | tr -d '[:space:]')"
  log_bytes="$(wc -c < "$log_path" | tr -d '[:space:]')"
  stdout_lines="$(wc -l < "$stdout_path" | tr -d '[:space:]')"
  stderr_lines="$(wc -l < "$stderr_path" | tr -d '[:space:]')"
  log_lines="$(wc -l < "$log_path" | tr -d '[:space:]')"

  python3 - "$TEST_RESULTS_JSONL" "$name" "$exit_code" "$log_path" "$stdout_path" "$stderr_path" "$log_bytes" "$stdout_bytes" "$stderr_bytes" "$log_lines" "$stdout_lines" "$stderr_lines" "$duration_seconds" "$start_iso" "$end_iso" "$@" <<'PY'
import json
import shlex
import sys

(
    jsonl_path,
    name,
    exit_code_raw,
    log_path,
    stdout_path,
    stderr_path,
    log_bytes_raw,
    stdout_bytes_raw,
    stderr_bytes_raw,
    log_lines_raw,
    stdout_lines_raw,
    stderr_lines_raw,
    duration_seconds_raw,
    start_iso,
    end_iso,
    *command,
) = sys.argv[1:]
exit_code = int(exit_code_raw)
record = {
    "name": name,
    "kind": "py_compile" if name == "py_compile" else "test",
    "status": "pass" if exit_code == 0 else "failed",
    "exit_code": exit_code,
    "command": command,
    "command_display": " ".join(shlex.quote(part) for part in command),
    "log_path": log_path,
    "stdout_path": stdout_path,
    "stderr_path": stderr_path,
    "log_bytes": int(log_bytes_raw),
    "stdout_bytes": int(stdout_bytes_raw),
    "stderr_bytes": int(stderr_bytes_raw),
    "log_lines": int(log_lines_raw),
    "stdout_lines": int(stdout_lines_raw),
    "stderr_lines": int(stderr_lines_raw),
    "stdout_stderr_combined_log": True,
    "duration_seconds": int(duration_seconds_raw),
    "started_at_utc": start_iso,
    "finished_at_utc": end_iso,
}
with open(jsonl_path, "a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, sort_keys=True) + "\n")
PY

  if [[ "$exit_code" -ne 0 ]]; then
    echo "Check failed: $name exit_code=$exit_code log=$log_path"
    exit "$exit_code"
  fi
}

compile_targets=(
  "$SCRIPTS_DIR/battle_analyst_v9.py"
  "$SCRIPTS_DIR/battle_action_critic.py"
  "$SCRIPTS_DIR/battle_decision_strategy_auditor.py"
  "$SCRIPTS_DIR/battle_decision_trace_taxonomy_audit.py"
  "$SCRIPTS_DIR/battle_decision_research_review.py"
  "$SCRIPTS_DIR/battle_event_contract_static_audit.py"
  "$SCRIPTS_DIR/battle_effect_coverage_audit.py"
  "$SCRIPTS_DIR/battle_effect_coverage_residual_audit.py"
  "$SCRIPTS_DIR/battle_focused_template_dispatch_audit.py"
  "$SCRIPTS_DIR/battle_forensic_audit.py"
  "$SCRIPTS_DIR/battle_runtime_surface_manifest.py"
  "$SCRIPTS_DIR/battle_table_intent_audit.py"
  "$SCRIPTS_DIR/battle_target_pressure_audit.py"
  "$SCRIPTS_DIR/battle_unknown_template_backlog_audit.py"
  "$SCRIPTS_DIR/replay_decision_auditor.py"
  "$SCRIPTS_DIR/test_battle_action_critic.py"
  "$SCRIPTS_DIR/test_battle_decision_strategy_auditor.py"
  "$SCRIPTS_DIR/test_battle_decision_trace_taxonomy_audit.py"
  "$SCRIPTS_DIR/test_battle_decision_research_review.py"
  "$SCRIPTS_DIR/test_battle_event_contract_static_audit.py"
  "$SCRIPTS_DIR/test_battle_replay_v10_3_renderer.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_known_cards.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_residual_audit.py"
  "$SCRIPTS_DIR/test_battle_focused_template_dispatch_audit.py"
  "$SCRIPTS_DIR/test_battle_rule_registry_runtime_safe.py"
  "$SCRIPTS_DIR/test_battle_script_entrypoint_symbols.py"
  "$SCRIPTS_DIR/test_battle_forensic_audit_supported_effects.py"
  "$SCRIPTS_DIR/test_replay_decision_auditor_scope.py"
  "$SCRIPTS_DIR/test_battle_runtime_surface_manifest.py"
  "$SCRIPTS_DIR/test_battle_table_intent_audit.py"
  "$SCRIPTS_DIR/test_battle_target_pressure_audit.py"
  "$SCRIPTS_DIR/test_battle_unknown_template_backlog_audit.py"
)
run_logged_check py_compile python3 -m py_compile "${compile_targets[@]}"

test_scripts=(
  "$SCRIPTS_DIR/test_battle_analyst_v10_3.py"
  "$SCRIPTS_DIR/test_battle_action_critic.py"
  "$SCRIPTS_DIR/test_battle_decision_strategy_auditor.py"
  "$SCRIPTS_DIR/test_battle_decision_trace_taxonomy_audit.py"
  "$SCRIPTS_DIR/test_battle_decision_research_review.py"
  "$SCRIPTS_DIR/test_battle_event_contract_static_audit.py"
  "$SCRIPTS_DIR/test_battle_replay_v10_3_renderer.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_known_cards.py"
  "$SCRIPTS_DIR/test_battle_effect_coverage_residual_audit.py"
  "$SCRIPTS_DIR/test_battle_focused_template_dispatch_audit.py"
  "$SCRIPTS_DIR/test_battle_rule_registry_runtime_safe.py"
  "$SCRIPTS_DIR/test_battle_script_entrypoint_symbols.py"
  "$SCRIPTS_DIR/test_battle_forensic_audit_supported_effects.py"
  "$SCRIPTS_DIR/test_replay_decision_auditor_scope.py"
  "$SCRIPTS_DIR/test_battle_runtime_surface_manifest.py"
  "$SCRIPTS_DIR/test_battle_table_intent_audit.py"
  "$SCRIPTS_DIR/test_battle_target_pressure_audit.py"
  "$SCRIPTS_DIR/test_battle_unknown_template_backlog_audit.py"
)
for test_script in "${test_scripts[@]}"; do
  run_logged_check "$(basename "$test_script" .py)" python3 "$test_script"
done

for ((i=0; i<SEEDS; i++)); do
  seed=$((START_SEED + i))
  seed_dir="$run_dir/seed_$seed"
  mkdir -p "$seed_dir"
  MANALOOM_KNOWLEDGE_DB="$KNOWLEDGE_DB" \
  MANALOOM_KNOWLEDGE_DIR="$REPO_DIR/docs/hermes-analysis/manaloom-knowledge" \
  MANALOOM_BATTLE_REAL_OPPONENT_SEED="$REAL_OPPONENT_SEED" \
  MANALOOM_BATTLE_EVALUATION_MODE="${MANALOOM_BATTLE_EVALUATION_MODE:-table_intent}" \
  MANALOOM_BATTLE_EVALUATION_TARGET_PLAYER="Lorehold" \
  REPLAY_SEED="$seed" \
  REPLAY_OUT="$seed_dir/replay.txt" \
  REPLAY_EVENTS_OUT="$seed_dir/replay.events.jsonl" \
  DECISION_TRACE_OUT="$seed_dir/replay.decision_trace.jsonl" \
  REPLAY_DECK_PROVENANCE_OUT="$seed_dir/deck_provenance.json" \
  python3 "$SCRIPTS_DIR/battle_replay_v10_3.py" > "$seed_dir/replay.log"

  python3 "$SCRIPTS_DIR/battle_action_critic.py" \
    --events "$seed_dir/replay.events.jsonl" \
    --decision-trace "$seed_dir/replay.decision_trace.jsonl" \
    --output "$seed_dir/action_critic.md" \
    --json-output "$seed_dir/action_critic.json" > "$seed_dir/action_critic.log"

  python3 "$SCRIPTS_DIR/battle_target_pressure_audit.py" \
    --events "$seed_dir/replay.events.jsonl" \
    --target Lorehold \
    --output "$seed_dir/target_pressure.md" \
    --json-output "$seed_dir/target_pressure.json" > "$seed_dir/target_pressure.log"

  python3 "$SCRIPTS_DIR/battle_table_intent_audit.py" \
    --events "$seed_dir/replay.events.jsonl" \
    --target Lorehold \
    --require-table-intent \
    --output "$seed_dir/table_intent.md" \
    --json-output "$seed_dir/table_intent.json" > "$seed_dir/table_intent.log"

  python3 "$SCRIPTS_DIR/battle_decision_strategy_auditor.py" \
    --events "$seed_dir/replay.events.jsonl" \
    --decision-trace "$seed_dir/replay.decision_trace.jsonl" \
    --output "$seed_dir/strategy_audit.md" \
    --json-output "$seed_dir/strategy_audit.json" > "$seed_dir/strategy_audit.log"

  python3 "$SCRIPTS_DIR/replay_decision_auditor.py" \
    --skip-baseline \
    --events "$seed_dir/replay.events.jsonl" \
    --decision-trace "$seed_dir/replay.decision_trace.jsonl" \
    --require-decision-trace \
    --json-output "$seed_dir/replay_decision_audit.json" > "$seed_dir/replay_decision_audit.md"

  python3 "$SCRIPTS_DIR/battle_forensic_audit.py" \
    --events "$seed_dir/replay.events.jsonl" \
    --json-report "$seed_dir/forensic_audit.json" > "$seed_dir/forensic_audit.md"
done

python3 "$SCRIPTS_DIR/battle_decision_research_review.py" \
  --input-dir "$run_dir" \
  --output "$run_dir/research_review.md" \
  --json-output "$run_dir/research_review.json" > "$run_dir/research_review.log"

python3 "$SCRIPTS_DIR/battle_effect_coverage_audit.py" \
  --sqlite-db "$KNOWLEDGE_DB" \
  --output "$run_dir/effect_coverage.md" \
  --json-output "$run_dir/effect_coverage.json" > "$run_dir/effect_coverage.log"

python3 "$SCRIPTS_DIR/battle_effect_coverage_residual_audit.py" \
  --coverage-json "$run_dir/effect_coverage.json" \
  --output "$run_dir/effect_coverage_residual.md" \
  --json-output "$run_dir/effect_coverage_residual.json" > "$run_dir/effect_coverage_residual.log"

python3 "$SCRIPTS_DIR/battle_focused_template_dispatch_audit.py" \
  --coverage-json "$run_dir/effect_coverage.json" \
  --evidence-output-dir "$run_dir/focused_template_dispatch_artifacts" \
  --output "$run_dir/focused_template_dispatch.md" \
  --json-output "$run_dir/focused_template_dispatch.json" > "$run_dir/focused_template_dispatch.log"

python3 "$SCRIPTS_DIR/battle_unknown_template_backlog_audit.py" \
  --coverage-json "$run_dir/effect_coverage.json" \
  --output "$run_dir/unknown_template_backlog.md" \
  --json-output "$run_dir/unknown_template_backlog.json" > "$run_dir/unknown_template_backlog.log"

python3 "$SCRIPTS_DIR/battle_decision_trace_taxonomy_audit.py" \
  --input-dir "$run_dir" \
  --output "$run_dir/decision_trace_taxonomy.md" \
  --json-output "$run_dir/decision_trace_taxonomy.json" > "$run_dir/decision_trace_taxonomy.log"

python3 "$SCRIPTS_DIR/battle_event_contract_static_audit.py" \
  --input-dir "$run_dir" \
  --output "$run_dir/event_contract_static.md" \
  --json-output "$run_dir/event_contract_static.json" > "$run_dir/event_contract_static.log"

python3 "$SCRIPTS_DIR/battle_runtime_surface_manifest.py" \
  --repo-root "$REPO_DIR" \
  --output "$run_dir/runtime_surface_manifest.md" \
  --json-output "$run_dir/runtime_surface_manifest.json" \
  --fail-on-unclassified > "$run_dir/runtime_surface_manifest.log"

python3 - "$run_dir" "$SEEDS" "$START_SEED" "$timestamp" "$SCRIPTS_DIR" "$KNOWLEDGE_DB" "$RUN_PROFILE" "$RUN_SCOPE" "$INVOCATION_KIND" "$SEEDS_SOURCE" "$START_SEED_SOURCE" <<'PY'
import json
import sqlite3
import sys
from collections import Counter
from pathlib import Path

run_dir = Path(sys.argv[1])
seeds = int(sys.argv[2])
start_seed = int(sys.argv[3])
timestamp = sys.argv[4]
scripts_dir = Path(sys.argv[5])
knowledge_db = Path(sys.argv[6])
run_profile = sys.argv[7]
run_scope = sys.argv[8]
invocation_kind = sys.argv[9]
seeds_source = sys.argv[10]
start_seed_source = sys.argv[11]
sys.path.insert(0, str(scripts_dir))
from battle_decision_strategy_auditor import (
    compute_global_learning_eligibility,
    summarize_learned_opponent_provenance,
)

def load_learned_deck_source_lookup(path):
    if not path.exists():
        return {}, "missing_db"
    conn = None
    try:
        conn = sqlite3.connect(path)
        conn.row_factory = sqlite3.Row
        columns = {row[1] for row in conn.execute("PRAGMA table_info(learned_decks)")}
        required = {"id", "source", "source_url", "commander", "deck_name"}
        if not required.issubset(columns):
            return {}, "missing_columns"
        rows = conn.execute(
            "SELECT id, source, source_url, commander, deck_name FROM learned_decks"
        ).fetchall()
        return {
            f"learned_deck:{row['id']}": {
                "local_cache_source": row["source"],
                "source_url": row["source_url"],
                "commander": row["commander"],
                "deck_name": row["deck_name"],
            }
            for row in rows
        }, "loaded"
    except sqlite3.Error as exc:
        return {}, f"sqlite_error:{exc}"
    finally:
        try:
            if conn is not None:
                conn.close()
        except Exception:
            pass

learned_deck_source_lookup, learned_deck_source_lookup_status = load_learned_deck_source_lookup(knowledge_db)

summary = {
    "timestamp_utc": timestamp,
    "run_dir": str(run_dir),
    "run_profile": run_profile,
    "run_scope": run_scope,
    "invocation_kind": invocation_kind,
    "seeds_source": seeds_source,
    "start_seed_source": start_seed_source,
    "run_scope_contract": "run_scope=focused_seed is single-seed evidence; recurring readiness requires run_scope=recurring_full and expected seed completion.",
    "seeds_requested": seeds,
    "start_seed": start_seed,
    "test_results_jsonl": str(run_dir / "test_results.jsonl"),
    "test_results": [],
    "test_results_total": 0,
    "test_results_status_counts": {},
    "test_logs": [],
    "test_log_empty_successes": [],
    "test_log_empty_failures": [],
    "test_result_failures": [],
    "tests": [],
    "py_compile": None,
    "seeds_completed": 0,
    "events": 0,
    "decisions": 0,
    "human_replay_resolve_ability_kind_unknown_lines": 0,
    "human_replay_damage_cause_unknown_lines": 0,
    "human_replay_unknown_lines": 0,
    "human_replay_placeholder_lines": 0,
    "human_replay_placeholder_samples": [],
    "action_findings": 0,
    "action_events_total": 0,
    "action_event_types_total": 0,
    "action_event_types_total_semantics": "legacy_seed_sum_across_seed_action_critics",
    "action_event_types_seed_sum": 0,
    "action_event_types_distinct_total": 0,
    "action_event_contract_class_counts": Counter(),
    "action_event_type_class_counts": Counter(),
    "action_event_type_class_seed_sum": Counter(),
    "action_event_type_class_distinct_counts": {},
    "action_events_unclassified": 0,
    "action_event_types_unclassified": Counter(),
    "strategy_findings": 0,
    "strategy_review_required_findings": 0,
    "strategy_low_confidence_findings": 0,
    "decision_audit_turn_findings": 0,
    "decision_audit_decision_findings": 0,
    "decision_audit_statuses": Counter(),
    "decision_audit_status_scope": None,
    "decision_audit_human_replay_complete": None,
    "decision_audit_rules_interaction_trusted": None,
    "forensic_rule_findings": 0,
    "forensic_turn_findings": 0,
    "target_pressure_statuses": Counter(),
    "target_pressure_findings": 0,
    "target_pressure_opponent_combat_total": 0,
    "target_pressure_opponent_combat_to_target": 0,
    "target_pressure_opponent_combat_to_other": 0,
    "target_pressure_opponent_multi_defender_attack": 0,
    "table_intent_statuses": Counter(),
    "table_intent_findings": 0,
    "table_intent_combat_total": 0,
    "table_intent_scored_combat_total": 0,
    "table_intent_missing_scores": 0,
    "table_intent_opponent_cast_illegal": 0,
    "table_intent_opponent_commander_cast": 0,
    "table_intent_opponent_creature_cast": 0,
    "table_intent_opponent_spell_cast": 0,
    "table_intent_opponent_spell_resolved": 0,
    "table_intent_opponent_interaction_events": 0,
    "table_intent_opponent_trigger_interaction_events": 0,
    "table_intent_opponent_wins": 0,
    "table_intent_target_wins": 0,
    "table_intent_opponent_blockers_total": 0,
    "table_intent_target_blockers_total": 0,
    "forensic_card_event_count": 0,
    "forensic_card_id_present": 0,
    "forensic_card_id_missing": 0,
    "forensic_card_id_missing_accepted": 0,
    "forensic_card_id_missing_unaccepted": 0,
    "forensic_semantic_hash_present": 0,
    "forensic_semantic_hash_missing": 0,
    "forensic_semantic_hash_missing_accepted": 0,
    "forensic_semantic_hash_missing_unaccepted": 0,
    "forensic_rule_logical_key_present": 0,
    "forensic_rule_logical_key_missing": 0,
    "forensic_rule_logical_key_missing_accepted": 0,
    "forensic_rule_logical_key_missing_unaccepted": 0,
    "forensic_lineage_missing_waiver_reasons": Counter(),
    "forensic_lineage_unaccepted_missing_samples": [],
    "forensic_lineage_status": None,
    "deck_provenance_files": [],
    "deck_metrics_policy": None,
    "deck_cached_metadata_used_for_replay_metrics": None,
    "deck_blocker_domain_policy": None,
    "lorehold_deck_source_kind": None,
    "lorehold_deck_source_ref": None,
    "lorehold_deck_metrics_basis": None,
    "lorehold_deck_cached_metadata_used_for_metrics": None,
    "lorehold_deck_lands": None,
    "lorehold_deck_avg_cmc_nonlands": None,
    "lorehold_deck_curve": {},
    "deck_source_blocker_domains": Counter(),
    "learned_deck_opponents": [],
    "opponent_deck_provenance": {},
    "learned_opponent_source_counts": {},
    "learned_deck_source_lookup_db": str(knowledge_db),
    "learned_deck_source_lookup_status": learned_deck_source_lookup_status,
    "learned_deck_source_lookup_rows": len(learned_deck_source_lookup),
    "action_verdict_counts": Counter(),
    "strategy_severity_counts": Counter(),
    "strategy_code_counts": Counter(),
    "strategy_learning_confidence_counts": Counter(),
    "strategy_low_confidence_seeds": [],
    "strategy_high_confidence_learning_seeds": [],
    "strategy_not_learning_eligible_seeds": [],
    "global_learning_eligibility_policy": None,
    "global_learning_eligible_seeds": [],
    "global_not_learning_eligible_seeds": [],
    "global_learning_eligibility_reasons": {},
    "decision_audit_severity_counts": Counter(),
    "forensic_severity_counts": Counter(),
    "research_statuses": {},
    "effect_coverage_report": None,
    "effect_coverage_json": None,
    "effect_coverage_effect_totals": {},
    "effect_coverage_effect_totals_unknown": 0,
    "effect_coverage_unknown_effect_cards": [],
    "effect_coverage_unknown_effect_source_counts": {},
    "effect_coverage_unknown_effect_status_counts": {},
    "needs_review_unknown_effect_count": 0,
    "needs_review_unknown_effect_cards": [],
    "focused_template_ready_effect_totals": {},
    "focused_template_effect_scope_totals": {},
    "focused_template_ready_unknown_effect_count": 0,
    "focused_template_ready_known_effect_count": 0,
    "focused_template_ready_unknown_effect_cards": [],
    "focused_template_ready_unknown_effect_scope_cards": [],
    "effect_coverage_residual_report": None,
    "effect_coverage_residual_json": None,
    "effect_coverage_residual_status": None,
    "effect_coverage_residual_raw_flag_total": 0,
    "effect_coverage_residual_unique_flagged_cards": 0,
    "effect_coverage_residual_card_flag_rows": 0,
    "effect_coverage_residual_accepted_card_flag_rows": 0,
    "effect_coverage_residual_unaccepted_card_flag_rows": 0,
    "effect_coverage_residual_accepted_flag_totals": {},
    "effect_coverage_residual_accepted_owner_totals": {},
    "effect_coverage_residual_raw_unaccepted_flags": [],
    "effect_coverage_residual_unaccepted_cards": [],
    "unknown_template_backlog_report": None,
    "unknown_template_backlog_json": None,
    "unknown_template_backlog_status": None,
    "unknown_template_backlog_cards": 0,
    "unknown_template_with_current_inferred_family": 0,
    "unknown_template_without_current_inferred_family": 0,
    "unknown_template_with_reviewed_family": 0,
    "unknown_template_without_reviewed_family": 0,
    "unknown_template_with_focused_template_match": 0,
    "unknown_template_without_focused_template_match": 0,
    "unknown_template_with_plan_or_waiver": 0,
    "unknown_template_without_plan_or_waiver": 0,
    "unknown_template_plan_status_counts": {},
    "unknown_template_reviewed_family_counts": {},
    "unknown_template_unknowns_without_plan_or_waiver": [],
    "unknown_template_unknowns_without_reviewed_family": [],
    "focused_template_dispatch_report": None,
    "focused_template_dispatch_json": None,
    "focused_template_dispatch_status": None,
    "focused_template_cards": 0,
    "focused_template_predicate_match": 0,
    "focused_template_without_predicate_match": 0,
    "focused_template_evidence_dispatch_ready": 0,
    "focused_template_without_evidence_dispatch": 0,
    "focused_template_evidence_ready": 0,
    "focused_template_evidence_not_ready_unwaived": 0,
    "focused_template_accepted_waivers": 0,
    "focused_template_evidence_runner_status_counts": {},
    "focused_template_risk_flag_counts": {},
    "focused_template_supports_template_count": 0,
    "focused_template_evaluate_dispatch_template_count": 0,
    "focused_template_build_evidence_function_count": 0,
    "focused_template_cards_without_dispatch": [],
    "focused_template_cards_without_predicate": [],
    "focused_template_cards_not_ready_unwaived": [],
    "decision_trace_taxonomy_report": None,
    "decision_trace_taxonomy_json": None,
    "decision_trace_taxonomy_status": None,
    "decision_trace_taxonomy_rows": 0,
    "decision_trace_kinds_total": 0,
    "decision_trace_kinds_observed": 0,
    "decision_trace_kinds_uncovered": 0,
    "decision_trace_contract_findings": 0,
    "decision_trace_missing_required_fields": 0,
    "decision_trace_static_without_contract": 0,
    "decision_trace_observed_without_contract": 0,
    "decision_trace_kinds_without_specific_contract": 0,
    "decision_trace_observed_without_specific_contract": 0,
    "decision_trace_accepted_waivers": [],
    "decision_trace_observed_counts": {},
    "decision_trace_static_uncovered_types": [],
    "decision_trace_observed_without_specific_contract_types": [],
    "event_contract_static_report": None,
    "event_contract_static_json": None,
    "event_contract_static_status": None,
    "event_contract_static_events_observed_total": 0,
    "event_contract_static_observed_event_types_total": 0,
    "event_contract_static_static_event_types_total": 0,
    "event_contract_static_all_event_types_total": 0,
    "event_contract_static_observed_unclassified_total": 0,
    "event_contract_static_static_unclassified_total": 0,
    "event_contract_static_observed_missing_required_fields": 0,
    "event_contract_static_observed_not_static_literal": [],
    "event_contract_static_fixture_or_waiver_counts": {},
    "event_contract_static_fixture_accepted_waiver_total": 0,
    "event_contract_static_waiver_until_forced_fixture": 0,
    "event_contract_static_fixture_accepted_waiver_reasons": {},
    "event_contract_static_fixture_unaccepted_types": [],
    "event_contract_static_static_class_counts": {},
    "event_contract_static_observed_type_class_counts": {},
    "event_contract_static_observed_event_class_counts": {},
    "event_contract_static_observed_unclassified_types": [],
    "event_contract_static_static_unclassified_types": [],
    "runtime_surface_manifest_report": None,
    "runtime_surface_manifest_json": None,
    "runtime_surface_manifest_total_files": 0,
    "runtime_surface_manifest_unclassified_files": [],
    "runtime_surface_manifest_category_counts": {},
    "runtime_surface_manifest_automation_coverage_counts": {},
    "runtime_surface_manifest_gate_expected_counts": {},
    "runtime_surface_manifest_status": None,
    "runtime_surface_manifest_recurring_categories": [],
    "runtime_surface_manifest_outside_recurring_categories": [],
    "mandatory_gates_required_for_final_status": [
        "action_critic",
        "strategy_audit",
        "replay_decision_audit",
        "forensic_audit",
        "target_pressure",
        "table_intent",
        "effect_coverage",
        "focused_template_dispatch",
        "unknown_template_backlog",
        "decision_trace_taxonomy",
        "event_contract_static",
    ],
    "mandatory_gate_statuses": {},
    "mandatory_gate_divergences": [],
    "battle_replay_final_status": None,
    "battle_replay_final_status_reason": None,
    "effect_coverage_unknowns": 0,
    "heuristic_effects": 0,
    "trigger_not_explicit": 0,
    "cast_permission_not_explicit": 0,
    "land_utility_ability_not_modeled": 0,
    "active_or_review_rule_names": 0,
    "non_runtime_safe_rule_names": 0,
    "needs_review_rule_names": 0,
    "runtime_safe_rule_names": 0,
    "review_only_rule_names": 0,
    "annotation_only_rule_names": 0,
    "non_runtime_other_rule_names": 0,
    "review_status_counts": {},
    "execution_status_counts": {},
    "review_only_rule_instances": 0,
    "seeds_with_high_or_critical_action_findings": [],
    "seeds_with_strategy_blockers": [],
    "seeds_with_high_or_critical_decision_audit_findings": [],
    "seeds_with_high_or_critical_forensic_findings": [],
    "seeds_with_target_pressure_violations": [],
    "seeds_with_table_intent_violations": [],
}
global_learning_seed_rows = []
learned_opponent_provenance_rows = []

test_results_path = run_dir / "test_results.jsonl"
if test_results_path.exists():
    test_results = [
        json.loads(line)
        for line in test_results_path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    test_status_counts = Counter(result.get("status") or "unknown" for result in test_results)
    summary["test_results"] = test_results
    summary["test_results_total"] = len(test_results)
    summary["test_results_status_counts"] = dict(sorted(test_status_counts.items()))
    summary["tests"] = [
        result.get("name")
        for result in test_results
        if result.get("kind") == "test"
    ]
    summary["test_logs"] = [
        {
            "name": result.get("name"),
            "kind": result.get("kind"),
            "status": result.get("status"),
            "exit_code": result.get("exit_code"),
            "log_path": result.get("log_path"),
            "log_bytes": result.get("log_bytes"),
            "log_lines": result.get("log_lines"),
            "stdout_bytes": result.get("stdout_bytes"),
            "stderr_bytes": result.get("stderr_bytes"),
            "stdout_lines": result.get("stdout_lines"),
            "stderr_lines": result.get("stderr_lines"),
        }
        for result in test_results
    ]
    summary["test_log_empty_successes"] = [
        result.get("name")
        for result in test_results
        if result.get("kind") == "test"
        and result.get("status") == "pass"
        and int(result.get("log_bytes") or 0) == 0
    ]
    summary["test_log_empty_failures"] = [
        result.get("name")
        for result in test_results
        if result.get("kind") == "test"
        and result.get("status") != "pass"
        and int(result.get("log_bytes") or 0) == 0
    ]
    summary["test_result_failures"] = [
        result
        for result in test_results
        if result.get("status") != "pass"
    ]
    for result in test_results:
        if result.get("kind") == "py_compile":
            summary["py_compile"] = result
            break

for seed_dir in sorted(run_dir.glob("seed_*")):
    action_path = seed_dir / "action_critic.json"
    strategy_path = seed_dir / "strategy_audit.json"
    replay_decision_path = seed_dir / "replay_decision_audit.json"
    forensic_path = seed_dir / "forensic_audit.json"
    target_pressure_path = seed_dir / "target_pressure.json"
    table_intent_path = seed_dir / "table_intent.json"
    deck_provenance_path = seed_dir / "deck_provenance.json"
    replay_txt_path = seed_dir / "replay.txt"
    events_path = seed_dir / "replay.events.jsonl"
    decisions_path = seed_dir / "replay.decision_trace.jsonl"
    if not action_path.exists() or not strategy_path.exists():
        continue
    action = json.loads(action_path.read_text())
    strategy = json.loads(strategy_path.read_text())
    replay_decision = json.loads(replay_decision_path.read_text()) if replay_decision_path.exists() else {}
    forensic = json.loads(forensic_path.read_text()) if forensic_path.exists() else {}
    target_pressure = json.loads(target_pressure_path.read_text()) if target_pressure_path.exists() else {}
    table_intent = json.loads(table_intent_path.read_text()) if table_intent_path.exists() else {}
    seed_name = seed_dir.name.replace("seed_", "")
    summary["seeds_completed"] += 1
    summary["events"] += sum(1 for _ in events_path.open()) if events_path.exists() else 0
    summary["decisions"] += sum(1 for _ in decisions_path.open()) if decisions_path.exists() else 0
    if replay_txt_path.exists():
        for line_number, line in enumerate(replay_txt_path.read_text(encoding="utf-8").splitlines(), 1):
            matched_placeholder = False
            if "RESOLVE ABILITY" in line and "kind=?" in line:
                summary["human_replay_resolve_ability_kind_unknown_lines"] += 1
                matched_placeholder = True
            if "DAMAGE" in line and "cause=?" in line:
                summary["human_replay_damage_cause_unknown_lines"] += 1
                matched_placeholder = True
            if "UNKNOWN" in line:
                summary["human_replay_unknown_lines"] += 1
                matched_placeholder = True
            if "PLACEHOLDER" in line:
                summary["human_replay_placeholder_lines"] += 1
                matched_placeholder = True
            if matched_placeholder and len(summary["human_replay_placeholder_samples"]) < 40:
                summary["human_replay_placeholder_samples"].append(
                    {
                        "seed": seed_name,
                        "line": line_number,
                        "text": line[:240],
                    }
                )
    action_findings = int(action["summary"].get("findings", 0))
    summary["action_findings"] += action_findings
    action_event_contract = action["summary"].get("event_contract") or {}
    action_event_types_for_seed = int(action_event_contract.get("event_types_total") or 0)
    summary["action_events_total"] += int(action_event_contract.get("events_total") or 0)
    summary["action_event_types_total"] += action_event_types_for_seed
    summary["action_event_types_seed_sum"] += action_event_types_for_seed
    summary["action_event_contract_class_counts"].update(
        action_event_contract.get("event_class_counts") or {}
    )
    action_event_type_class_counts = action_event_contract.get("event_type_class_counts") or {}
    summary["action_event_type_class_counts"].update(action_event_type_class_counts)
    summary["action_event_type_class_seed_sum"].update(action_event_type_class_counts)
    summary["action_events_unclassified"] += int(action_event_contract.get("events_unclassified") or 0)
    summary["action_event_types_unclassified"].update(
        action_event_contract.get("event_types_unclassified") or []
    )
    strategy_findings = int(strategy["summary"].get("findings", 0))
    strategy_low_confidence_findings = int(
        strategy["summary"].get("low_confidence_learning_findings") or 0
    )
    strategy_review_required_findings = int(
        strategy["summary"].get(
            "review_required_findings",
            max(0, strategy_findings - strategy_low_confidence_findings),
        )
        or 0
    )
    summary["strategy_findings"] += strategy_findings
    summary["strategy_review_required_findings"] += strategy_review_required_findings
    summary["strategy_low_confidence_findings"] += strategy_low_confidence_findings
    summary["action_verdict_counts"].update(action["summary"].get("verdict_counts", {}))
    summary["strategy_severity_counts"].update(strategy["summary"].get("severity_counts", {}))
    summary["strategy_code_counts"].update(strategy["summary"].get("code_counts", {}))
    strategy_confidence = strategy["summary"].get("learning_confidence") or "unknown"
    summary["strategy_learning_confidence_counts"].update([strategy_confidence])
    if strategy_confidence == "low_confidence_replay":
        summary["strategy_low_confidence_seeds"].append(seed_name)
    elif strategy_confidence == "high_confidence_replay":
        summary["strategy_high_confidence_learning_seeds"].append(seed_name)
    elif strategy_confidence == "not_learning_eligible":
        summary["strategy_not_learning_eligible_seeds"].append(seed_name)
    replay_decision_summary = replay_decision.get("summary") or {}
    decision_turn_findings = int(replay_decision_summary.get("turn_findings") or 0)
    decision_decision_findings = int(replay_decision_summary.get("decision_findings") or 0)
    summary["decision_audit_turn_findings"] += decision_turn_findings
    summary["decision_audit_decision_findings"] += decision_decision_findings
    summary["decision_audit_severity_counts"].update(replay_decision_summary.get("severity_counts", {}))
    if replay_decision_summary.get("status"):
        summary["decision_audit_statuses"].update([replay_decision_summary.get("status")])
    summary["decision_audit_status_scope"] = replay_decision_summary.get("status_scope") or summary["decision_audit_status_scope"]
    summary["decision_audit_human_replay_complete"] = replay_decision_summary.get("human_replay_complete") or summary["decision_audit_human_replay_complete"]
    summary["decision_audit_rules_interaction_trusted"] = replay_decision_summary.get("rules_interaction_trusted") or summary["decision_audit_rules_interaction_trusted"]
    forensic_rule_findings = forensic.get("rule_findings") or []
    forensic_turn_findings = forensic.get("turn_findings") or []
    forensic_summary = forensic.get("summary") or {}
    summary["forensic_rule_findings"] += len(forensic_rule_findings)
    summary["forensic_turn_findings"] += len(forensic_turn_findings)
    summary["forensic_card_event_count"] += int(forensic_summary.get("card_event_count") or 0)
    summary["forensic_card_id_present"] += int(forensic_summary.get("card_id_present") or 0)
    summary["forensic_card_id_missing"] += int(forensic_summary.get("card_id_missing") or 0)
    summary["forensic_card_id_missing_accepted"] += int(forensic_summary.get("card_id_missing_accepted") or 0)
    summary["forensic_card_id_missing_unaccepted"] += int(forensic_summary.get("card_id_missing_unaccepted") or 0)
    summary["forensic_semantic_hash_present"] += int(forensic_summary.get("semantic_hash_present") or 0)
    summary["forensic_semantic_hash_missing"] += int(forensic_summary.get("semantic_hash_missing") or 0)
    summary["forensic_semantic_hash_missing_accepted"] += int(forensic_summary.get("semantic_hash_missing_accepted") or 0)
    summary["forensic_semantic_hash_missing_unaccepted"] += int(forensic_summary.get("semantic_hash_missing_unaccepted") or 0)
    summary["forensic_rule_logical_key_present"] += int(forensic_summary.get("rule_logical_key_present") or 0)
    summary["forensic_rule_logical_key_missing"] += int(forensic_summary.get("rule_logical_key_missing") or 0)
    summary["forensic_rule_logical_key_missing_accepted"] += int(forensic_summary.get("rule_logical_key_missing_accepted") or 0)
    summary["forensic_rule_logical_key_missing_unaccepted"] += int(forensic_summary.get("rule_logical_key_missing_unaccepted") or 0)
    summary["forensic_lineage_missing_waiver_reasons"].update(
        forensic_summary.get("lineage_missing_waiver_reasons") or {}
    )
    for sample in forensic_summary.get("lineage_unaccepted_missing_samples") or []:
        if len(summary["forensic_lineage_unaccepted_missing_samples"]) >= 40:
            break
        enriched = dict(sample)
        enriched.setdefault("seed", seed_name)
        summary["forensic_lineage_unaccepted_missing_samples"].append(enriched)
    for finding in forensic_rule_findings + forensic_turn_findings:
        summary["forensic_severity_counts"].update([finding.get("severity") or "low"])
    target_pressure_summary = target_pressure.get("summary") or {}
    target_pressure_status = target_pressure_summary.get("status") or "missing"
    summary["target_pressure_statuses"].update([target_pressure_status])
    summary["target_pressure_findings"] += int(target_pressure_summary.get("findings") or 0)
    summary["target_pressure_opponent_combat_total"] += int(
        target_pressure_summary.get("opponent_combat_total") or 0
    )
    summary["target_pressure_opponent_combat_to_target"] += int(
        target_pressure_summary.get("opponent_combat_to_target") or 0
    )
    summary["target_pressure_opponent_combat_to_other"] += int(
        target_pressure_summary.get("opponent_combat_to_other") or 0
    )
    summary["target_pressure_opponent_multi_defender_attack"] += int(
        target_pressure_summary.get("opponent_multi_defender_attack") or 0
    )
    if target_pressure_status != "pass":
        summary["seeds_with_target_pressure_violations"].append(seed_name)
    table_intent_summary = table_intent.get("summary") or {}
    table_intent_status = table_intent_summary.get("status") or "missing"
    table_intent_findings = table_intent_summary.get("findings") or []
    summary["table_intent_statuses"].update([table_intent_status])
    summary["table_intent_findings"] += (
        len(table_intent_findings)
        if isinstance(table_intent_findings, list)
        else int(table_intent_findings or 0)
    )
    summary["table_intent_combat_total"] += int(table_intent_summary.get("combat_total") or 0)
    summary["table_intent_scored_combat_total"] += int(table_intent_summary.get("table_intent_combat_total") or 0)
    summary["table_intent_missing_scores"] += int(table_intent_summary.get("table_intent_missing_scores") or 0)
    summary["table_intent_opponent_cast_illegal"] += int(table_intent_summary.get("opponent_cast_illegal") or 0)
    summary["table_intent_opponent_commander_cast"] += int(table_intent_summary.get("opponent_commander_cast") or 0)
    summary["table_intent_opponent_creature_cast"] += int(table_intent_summary.get("opponent_creature_cast") or 0)
    summary["table_intent_opponent_spell_cast"] += int(table_intent_summary.get("opponent_spell_cast") or 0)
    summary["table_intent_opponent_spell_resolved"] += int(table_intent_summary.get("opponent_spell_resolved") or 0)
    summary["table_intent_opponent_interaction_events"] += int(table_intent_summary.get("opponent_interaction_events") or 0)
    summary["table_intent_opponent_trigger_interaction_events"] += int(table_intent_summary.get("opponent_trigger_interaction_events") or 0)
    summary["table_intent_opponent_wins"] += int(table_intent_summary.get("opponent_wins") or 0)
    summary["table_intent_target_wins"] += int(table_intent_summary.get("target_wins") or 0)
    summary["table_intent_opponent_blockers_total"] += int(table_intent_summary.get("opponent_blockers_total") or 0)
    summary["table_intent_target_blockers_total"] += int(table_intent_summary.get("target_blockers_total") or 0)
    if table_intent_status != "pass":
        summary["seeds_with_table_intent_violations"].append(seed_name)
    action_counts = action["summary"].get("verdict_counts", {})
    if action_counts.get("high", 0) or action_counts.get("critical", 0):
        summary["seeds_with_high_or_critical_action_findings"].append(seed_name)
    if strategy["summary"].get("verdict") == "blocked":
        summary["seeds_with_strategy_blockers"].append(seed_name)
    decision_counts = replay_decision_summary.get("severity_counts", {})
    if decision_counts.get("high", 0) or decision_counts.get("critical", 0):
        summary["seeds_with_high_or_critical_decision_audit_findings"].append(seed_name)
    forensic_counts = Counter()
    for finding in forensic_rule_findings + forensic_turn_findings:
        forensic_counts.update([finding.get("severity") or "low"])
    if forensic_counts.get("high", 0) or forensic_counts.get("critical", 0):
        summary["seeds_with_high_or_critical_forensic_findings"].append(seed_name)
    global_learning_seed_rows.append({
        "seed": seed_name,
        "strategy_confidence": strategy_confidence,
        "action_findings": action_findings,
        "action_high_or_critical": bool(action_counts.get("high", 0) or action_counts.get("critical", 0)),
        "strategy_review_required_findings": strategy_review_required_findings,
        "strategy_blocked": strategy["summary"].get("verdict") == "blocked",
        "decision_turn_findings": decision_turn_findings,
        "decision_decision_findings": decision_decision_findings,
        "decision_high_or_critical": bool(decision_counts.get("high", 0) or decision_counts.get("critical", 0)),
        "forensic_rule_findings": len(forensic_rule_findings),
        "forensic_turn_findings": len(forensic_turn_findings),
        "forensic_high_or_critical": bool(forensic_counts.get("high", 0) or forensic_counts.get("critical", 0)),
        "target_pressure_status": target_pressure_status,
        "target_pressure_findings": int(target_pressure_summary.get("findings") or 0),
        "table_intent_status": table_intent_status,
        "table_intent_findings": (
            len(table_intent_findings)
            if isinstance(table_intent_findings, list)
            else int(table_intent_findings or 0)
        ),
    })
    if deck_provenance_path.exists():
        deck_provenance = json.loads(deck_provenance_path.read_text())
        summary["deck_provenance_files"].append(str(deck_provenance_path))
        summary["deck_metrics_policy"] = (
            deck_provenance.get("metrics_policy") or summary["deck_metrics_policy"]
        )
        if deck_provenance.get("cached_metadata_used_for_replay_metrics") is not None:
            summary["deck_cached_metadata_used_for_replay_metrics"] = deck_provenance.get(
                "cached_metadata_used_for_replay_metrics"
            )
        summary["deck_blocker_domain_policy"] = (
            deck_provenance.get("blocker_domain_policy")
            or summary["deck_blocker_domain_policy"]
        )
        for deck_item in deck_provenance.get("decks") or []:
            summary["deck_source_blocker_domains"].update(
                [deck_item.get("blocker_domain") or "none"]
            )
            if deck_item.get("source_kind") == "learned_decks" or str(deck_item.get("source_ref") or "").startswith("learned_deck:"):
                learned_row = dict(deck_item)
                learned_row.update(learned_deck_source_lookup.get(str(deck_item.get("source_ref") or ""), {}))
                learned_row["seed"] = seed_name
                learned_opponent_provenance_rows.append(learned_row)
            if deck_item.get("name") == "Lorehold":
                metrics = deck_item.get("metrics") or {}
                summary["lorehold_deck_source_kind"] = deck_item.get("source_kind")
                summary["lorehold_deck_source_ref"] = deck_item.get("source_ref")
                summary["lorehold_deck_metrics_basis"] = deck_item.get("metrics_basis")
                if deck_item.get("cached_metadata_used_for_metrics") is not None:
                    summary["lorehold_deck_cached_metadata_used_for_metrics"] = deck_item.get(
                        "cached_metadata_used_for_metrics"
                    )
                summary["lorehold_deck_lands"] = metrics.get("lands")
                summary["lorehold_deck_avg_cmc_nonlands"] = metrics.get(
                    "avg_cmc_nonlands"
                )
                summary["lorehold_deck_curve"] = dict(metrics.get("curve") or {})

research_path = run_dir / "research_review.json"
if research_path.exists():
    research = json.loads(research_path.read_text())
    summary["research_statuses"] = {
        key: value.get("status")
        for key, value in sorted((research.get("categories") or {}).items())
    }

coverage_path = run_dir / "effect_coverage.json"
coverage_md_path = run_dir / "effect_coverage.md"
if coverage_path.exists():
    coverage = json.loads(coverage_path.read_text())
    flags = coverage.get("flag_totals") or {}
    effect_totals = coverage.get("effect_totals") or {}
    focused_template_coverage_cards = coverage.get("focused_template_cards") or []
    focused_template_effect_totals = Counter(
        (card.get("effect") or "unknown")
        for card in focused_template_coverage_cards
    )
    focused_template_unknown_effect_cards = sorted(
        {
            card.get("name")
            for card in focused_template_coverage_cards
            if (card.get("effect") or "unknown") == "unknown" and card.get("name")
        }
    )
    summary["effect_coverage_report"] = str(coverage_md_path)
    summary["effect_coverage_json"] = str(coverage_path)
    summary["effect_coverage_effect_totals"] = dict(effect_totals)
    summary["effect_coverage_effect_totals_unknown"] = int(effect_totals.get("unknown") or 0)
    summary["effect_coverage_unknown_effect_cards"] = list(
        coverage.get("unknown_effect_cards") or []
    )
    summary["effect_coverage_unknown_effect_source_counts"] = dict(
        coverage.get("unknown_effect_source_counts") or {}
    )
    summary["effect_coverage_unknown_effect_status_counts"] = dict(
        coverage.get("unknown_effect_status_counts") or {}
    )
    needs_review_unknown_effect_cards = list(
        coverage.get("needs_review_unknown_effect_cards") or []
    )
    summary["needs_review_unknown_effect_count"] = len(needs_review_unknown_effect_cards)
    summary["needs_review_unknown_effect_cards"] = needs_review_unknown_effect_cards
    summary["focused_template_ready_effect_totals"] = dict(focused_template_effect_totals)
    summary["focused_template_effect_scope_totals"] = dict(coverage.get("focused_template_effect_scope_totals") or {})
    summary["focused_template_ready_unknown_effect_count"] = len(focused_template_unknown_effect_cards)
    summary["focused_template_ready_known_effect_count"] = max(
        0,
        len(focused_template_coverage_cards) - len(focused_template_unknown_effect_cards),
    )
    summary["focused_template_ready_unknown_effect_cards"] = focused_template_unknown_effect_cards
    summary["focused_template_ready_unknown_effect_scope_cards"] = list(
        coverage.get("focused_template_unknown_effect_scope_cards") or []
    )
    summary["effect_coverage_unknowns"] = int(flags.get("unknown_effect") or 0)
    summary["heuristic_effects"] = int(flags.get("heuristic_effect") or 0)
    summary["trigger_not_explicit"] = int(flags.get("trigger_not_explicit") or 0)
    summary["cast_permission_not_explicit"] = int(flags.get("cast_permission_not_explicit") or 0)
    summary["land_utility_ability_not_modeled"] = int(flags.get("land_utility_ability_not_modeled") or 0)
    summary["active_or_review_rule_names"] = int(coverage.get("active_or_review_rule_names") or 0)
    summary["non_runtime_safe_rule_names"] = int(coverage.get("non_runtime_safe_rule_names") or 0)
    summary["needs_review_rule_names"] = int(coverage.get("needs_review_rule_names") or 0)
    summary["runtime_safe_rule_names"] = int(coverage.get("runtime_safe_rule_names") or 0)
    summary["review_only_rule_names"] = int(coverage.get("review_only_rule_names") or 0)
    summary["annotation_only_rule_names"] = int(coverage.get("annotation_only_rule_names") or 0)
    summary["non_runtime_other_rule_names"] = int(coverage.get("non_runtime_other_rule_names") or 0)
    summary["review_status_counts"] = dict(coverage.get("review_status_counts") or {})
    summary["execution_status_counts"] = dict(coverage.get("execution_status_counts") or {})
    summary["review_only_rule_instances"] = int(flags.get("review_only_rule") or 0)

residual_path = run_dir / "effect_coverage_residual.json"
residual_md_path = run_dir / "effect_coverage_residual.md"
if residual_path.exists():
    residual = json.loads(residual_path.read_text())
    residual_summary = residual.get("summary") or {}
    summary["effect_coverage_residual_report"] = str(residual_md_path)
    summary["effect_coverage_residual_json"] = str(residual_path)
    summary["effect_coverage_residual_status"] = residual_summary.get("status")
    summary["effect_coverage_residual_raw_flag_total"] = int(residual_summary.get("raw_flag_total") or 0)
    summary["effect_coverage_residual_unique_flagged_cards"] = int(residual_summary.get("unique_flagged_cards") or 0)
    summary["effect_coverage_residual_card_flag_rows"] = int(residual_summary.get("card_flag_rows") or 0)
    summary["effect_coverage_residual_accepted_card_flag_rows"] = int(residual_summary.get("accepted_card_flag_rows") or 0)
    summary["effect_coverage_residual_unaccepted_card_flag_rows"] = int(residual_summary.get("unaccepted_card_flag_rows") or 0)
    summary["effect_coverage_residual_accepted_flag_totals"] = dict(residual_summary.get("accepted_flag_totals") or {})
    summary["effect_coverage_residual_accepted_owner_totals"] = dict(residual_summary.get("accepted_owner_totals") or {})
    summary["effect_coverage_residual_raw_unaccepted_flags"] = list(residual_summary.get("raw_unaccepted_flags") or [])
    summary["effect_coverage_residual_unaccepted_cards"] = list(residual_summary.get("unaccepted_cards") or [])

focused_dispatch_path = run_dir / "focused_template_dispatch.json"
focused_dispatch_md_path = run_dir / "focused_template_dispatch.md"
if focused_dispatch_path.exists():
    focused_dispatch = json.loads(focused_dispatch_path.read_text())
    focused_dispatch_summary = focused_dispatch.get("summary") or {}
    summary["focused_template_dispatch_report"] = str(focused_dispatch_md_path)
    summary["focused_template_dispatch_json"] = str(focused_dispatch_path)
    summary["focused_template_dispatch_status"] = focused_dispatch_summary.get("status")
    summary["focused_template_cards"] = int(focused_dispatch_summary.get("focused_template_cards") or 0)
    summary["focused_template_predicate_match"] = int(focused_dispatch_summary.get("template_predicate_match") or 0)
    summary["focused_template_without_predicate_match"] = int(focused_dispatch_summary.get("without_template_predicate_match") or 0)
    summary["focused_template_evidence_dispatch_ready"] = int(focused_dispatch_summary.get("evidence_dispatch_ready") or 0)
    summary["focused_template_without_evidence_dispatch"] = int(focused_dispatch_summary.get("without_evidence_dispatch") or 0)
    summary["focused_template_evidence_ready"] = int(focused_dispatch_summary.get("focused_evidence_ready") or 0)
    summary["focused_template_evidence_not_ready_unwaived"] = int(focused_dispatch_summary.get("focused_evidence_not_ready_unwaived") or 0)
    summary["focused_template_accepted_waivers"] = int(focused_dispatch_summary.get("accepted_waivers") or 0)
    summary["focused_template_evidence_runner_status_counts"] = dict(focused_dispatch_summary.get("evidence_runner_status_counts") or {})
    summary["focused_template_risk_flag_counts"] = dict(focused_dispatch_summary.get("risk_flag_counts") or {})
    summary["focused_template_supports_template_count"] = int(focused_dispatch_summary.get("supports_template_count") or 0)
    summary["focused_template_evaluate_dispatch_template_count"] = int(focused_dispatch_summary.get("evaluate_dispatch_template_count") or 0)
    summary["focused_template_build_evidence_function_count"] = int(focused_dispatch_summary.get("build_evidence_function_count") or 0)
    summary["focused_template_cards_without_dispatch"] = list(focused_dispatch_summary.get("focused_template_cards_without_dispatch") or [])
    summary["focused_template_cards_without_predicate"] = list(focused_dispatch_summary.get("focused_template_cards_without_predicate") or [])
    summary["focused_template_cards_not_ready_unwaived"] = list(focused_dispatch_summary.get("focused_template_cards_not_ready_unwaived") or [])

unknown_template_path = run_dir / "unknown_template_backlog.json"
unknown_template_md_path = run_dir / "unknown_template_backlog.md"
if unknown_template_path.exists():
    unknown_template = json.loads(unknown_template_path.read_text())
    unknown_template_summary = unknown_template.get("summary") or {}
    summary["unknown_template_backlog_report"] = str(unknown_template_md_path)
    summary["unknown_template_backlog_json"] = str(unknown_template_path)
    summary["unknown_template_backlog_status"] = unknown_template_summary.get("status")
    summary["unknown_template_backlog_cards"] = int(unknown_template_summary.get("unknown_cards") or 0)
    summary["unknown_template_with_current_inferred_family"] = int(unknown_template_summary.get("with_current_inferred_family") or 0)
    summary["unknown_template_without_current_inferred_family"] = int(unknown_template_summary.get("without_current_inferred_family") or 0)
    summary["unknown_template_with_reviewed_family"] = int(unknown_template_summary.get("with_reviewed_family") or 0)
    summary["unknown_template_without_reviewed_family"] = int(unknown_template_summary.get("without_reviewed_family") or 0)
    summary["unknown_template_with_focused_template_match"] = int(unknown_template_summary.get("with_focused_template_match") or 0)
    summary["unknown_template_without_focused_template_match"] = int(unknown_template_summary.get("without_focused_template_match") or 0)
    summary["unknown_template_with_plan_or_waiver"] = int(unknown_template_summary.get("with_plan_or_waiver") or 0)
    summary["unknown_template_without_plan_or_waiver"] = int(unknown_template_summary.get("without_plan_or_waiver") or 0)
    summary["unknown_template_plan_status_counts"] = dict(unknown_template_summary.get("plan_status_counts") or {})
    summary["unknown_template_reviewed_family_counts"] = dict(unknown_template_summary.get("reviewed_family_counts") or {})
    summary["unknown_template_unknowns_without_plan_or_waiver"] = list(unknown_template_summary.get("unknowns_without_plan_or_waiver") or [])
    summary["unknown_template_unknowns_without_reviewed_family"] = list(unknown_template_summary.get("unknowns_without_reviewed_family") or [])

decision_trace_taxonomy_path = run_dir / "decision_trace_taxonomy.json"
decision_trace_taxonomy_md_path = run_dir / "decision_trace_taxonomy.md"
if decision_trace_taxonomy_path.exists():
    decision_trace_taxonomy = json.loads(decision_trace_taxonomy_path.read_text())
    decision_trace_taxonomy_summary = decision_trace_taxonomy.get("summary") or {}
    summary["decision_trace_taxonomy_report"] = str(decision_trace_taxonomy_md_path)
    summary["decision_trace_taxonomy_json"] = str(decision_trace_taxonomy_path)
    summary["decision_trace_taxonomy_status"] = decision_trace_taxonomy_summary.get("status")
    summary["decision_trace_taxonomy_rows"] = int(decision_trace_taxonomy_summary.get("decision_trace_rows") or 0)
    summary["decision_trace_kinds_total"] = int(decision_trace_taxonomy_summary.get("decision_trace_kinds_total") or 0)
    summary["decision_trace_kinds_observed"] = int(decision_trace_taxonomy_summary.get("decision_trace_kinds_observed") or 0)
    summary["decision_trace_kinds_uncovered"] = int(decision_trace_taxonomy_summary.get("decision_trace_kinds_uncovered") or 0)
    summary["decision_trace_contract_findings"] = int(decision_trace_taxonomy_summary.get("decision_trace_contract_findings") or 0)
    summary["decision_trace_missing_required_fields"] = int(decision_trace_taxonomy_summary.get("decision_trace_missing_required_fields") or 0)
    summary["decision_trace_static_without_contract"] = int(decision_trace_taxonomy_summary.get("decision_trace_static_without_contract") or 0)
    summary["decision_trace_observed_without_contract"] = int(decision_trace_taxonomy_summary.get("decision_trace_observed_without_contract") or 0)
    summary["decision_trace_kinds_without_specific_contract"] = int(decision_trace_taxonomy_summary.get("decision_trace_kinds_without_specific_contract") or 0)
    summary["decision_trace_observed_without_specific_contract"] = int(decision_trace_taxonomy_summary.get("decision_trace_observed_without_specific_contract") or 0)
    summary["decision_trace_accepted_waivers"] = list(decision_trace_taxonomy_summary.get("accepted_waivers") or [])
    summary["decision_trace_observed_counts"] = dict(decision_trace_taxonomy_summary.get("observed_counts") or {})
    summary["decision_trace_static_uncovered_types"] = list(decision_trace_taxonomy_summary.get("static_uncovered_types") or [])
    summary["decision_trace_observed_without_specific_contract_types"] = list(
        decision_trace_taxonomy_summary.get("observed_without_specific_contract_types") or []
    )

event_contract_static_path = run_dir / "event_contract_static.json"
event_contract_static_md_path = run_dir / "event_contract_static.md"
if event_contract_static_path.exists():
    event_contract_static = json.loads(event_contract_static_path.read_text())
    event_contract_static_summary = event_contract_static.get("summary") or {}
    summary["event_contract_static_report"] = str(event_contract_static_md_path)
    summary["event_contract_static_json"] = str(event_contract_static_path)
    summary["event_contract_static_status"] = event_contract_static_summary.get("status")
    summary["event_contract_static_events_observed_total"] = int(event_contract_static_summary.get("events_observed_total") or 0)
    summary["event_contract_static_observed_event_types_total"] = int(event_contract_static_summary.get("observed_event_types_total") or 0)
    summary["event_contract_static_static_event_types_total"] = int(event_contract_static_summary.get("static_event_types_total") or 0)
    summary["event_contract_static_all_event_types_total"] = int(event_contract_static_summary.get("all_event_types_total") or 0)
    summary["event_contract_static_observed_unclassified_total"] = int(event_contract_static_summary.get("observed_unclassified_total") or 0)
    summary["event_contract_static_static_unclassified_total"] = int(event_contract_static_summary.get("static_unclassified_total") or 0)
    summary["event_contract_static_observed_missing_required_fields"] = int(event_contract_static_summary.get("observed_missing_required_fields") or 0)
    summary["event_contract_static_observed_not_static_literal"] = list(event_contract_static_summary.get("observed_not_static_literal") or [])
    summary["event_contract_static_fixture_or_waiver_counts"] = dict(event_contract_static_summary.get("fixture_or_waiver_counts") or {})
    summary["event_contract_static_fixture_accepted_waiver_total"] = int(event_contract_static_summary.get("static_fixture_accepted_waiver_total") or 0)
    summary["event_contract_static_waiver_until_forced_fixture"] = int(event_contract_static_summary.get("static_contract_waiver_until_forced_fixture") or 0)
    summary["event_contract_static_fixture_accepted_waiver_reasons"] = dict(event_contract_static_summary.get("static_fixture_accepted_waiver_reasons") or {})
    summary["event_contract_static_fixture_unaccepted_types"] = list(event_contract_static_summary.get("static_fixture_unaccepted_types") or [])
    summary["event_contract_static_static_class_counts"] = dict(event_contract_static_summary.get("static_class_counts") or {})
    summary["event_contract_static_observed_type_class_counts"] = dict(event_contract_static_summary.get("observed_type_class_counts") or {})
    summary["event_contract_static_observed_event_class_counts"] = dict(event_contract_static_summary.get("observed_event_class_counts") or {})
    summary["event_contract_static_observed_unclassified_types"] = list(event_contract_static_summary.get("observed_unclassified_types") or [])
    summary["action_event_types_distinct_total"] = summary["event_contract_static_observed_event_types_total"]
    summary["action_event_type_class_distinct_counts"] = dict(summary["event_contract_static_observed_type_class_counts"])
    summary["event_contract_static_static_unclassified_types"] = list(event_contract_static_summary.get("static_unclassified_types") or [])

manifest_path = run_dir / "runtime_surface_manifest.json"
manifest_md_path = run_dir / "runtime_surface_manifest.md"
if manifest_path.exists():
    runtime_manifest = json.loads(manifest_path.read_text())
    runtime_manifest_summary = runtime_manifest.get("summary") or {}
    summary["runtime_surface_manifest_report"] = str(manifest_md_path)
    summary["runtime_surface_manifest_json"] = str(manifest_path)
    summary["runtime_surface_manifest_total_files"] = int(runtime_manifest_summary.get("total_files") or 0)
    summary["runtime_surface_manifest_unclassified_files"] = list(
        runtime_manifest_summary.get("unclassified_files") or []
    )
    summary["runtime_surface_manifest_category_counts"] = dict(
        runtime_manifest_summary.get("category_counts") or {}
    )
    summary["runtime_surface_manifest_automation_coverage_counts"] = dict(
        runtime_manifest_summary.get("automation_coverage_counts") or {}
    )
    summary["runtime_surface_manifest_gate_expected_counts"] = dict(
        runtime_manifest_summary.get("gate_expected_counts") or {}
    )
    summary["runtime_surface_manifest_status"] = (
        "runtime_surface_manifest_ready"
        if not summary["runtime_surface_manifest_unclassified_files"]
        and summary["runtime_surface_manifest_total_files"]
        else "runtime_surface_manifest_review_required"
    )
    summary["runtime_surface_manifest_recurring_categories"] = list(
        runtime_manifest_summary.get("recurring_categories") or []
    )
    summary["runtime_surface_manifest_outside_recurring_categories"] = list(
        runtime_manifest_summary.get("outside_recurring_categories") or []
    )

action_blocking = bool(summary["seeds_with_high_or_critical_action_findings"])
strategy_blocking = bool(summary["seeds_with_strategy_blockers"])
decision_blocking = bool(summary["seeds_with_high_or_critical_decision_audit_findings"])
forensic_blocking = bool(summary["seeds_with_high_or_critical_forensic_findings"])
target_pressure_blocking = bool(summary["seeds_with_target_pressure_violations"])
table_intent_blocking = bool(summary["seeds_with_table_intent_violations"])

gate_statuses = {
    "action_critic": {
        "status": "blocked" if action_blocking else ("review_required" if summary["action_findings"] else "pass"),
        "findings": summary["action_findings"],
        "blocking_seeds": summary["seeds_with_high_or_critical_action_findings"],
    },
    "strategy_audit": {
        "status": "blocked" if strategy_blocking else (
            "review_required" if summary["strategy_review_required_findings"] else "pass"
        ),
        "findings": summary["strategy_findings"],
        "review_required_findings": summary["strategy_review_required_findings"],
        "low_confidence_findings": summary["strategy_low_confidence_findings"],
        "blocking_seeds": summary["seeds_with_strategy_blockers"],
    },
    "replay_decision_audit": {
        "status": (
            "blocked"
            if decision_blocking
            else (
                "review_required"
                if summary["decision_audit_turn_findings"] or summary["decision_audit_decision_findings"]
                else "pass"
            )
        ),
        "turn_findings": summary["decision_audit_turn_findings"],
        "decision_findings": summary["decision_audit_decision_findings"],
        "blocking_seeds": summary["seeds_with_high_or_critical_decision_audit_findings"],
    },
    "forensic_audit": {
        "status": (
            "blocked"
            if forensic_blocking
            else (
                "review_required"
                if summary["forensic_rule_findings"] or summary["forensic_turn_findings"]
                else "pass"
            )
        ),
        "rule_findings": summary["forensic_rule_findings"],
        "turn_findings": summary["forensic_turn_findings"],
        "blocking_seeds": summary["seeds_with_high_or_critical_forensic_findings"],
    },
    "target_pressure": {
        "status": (
            "blocked"
            if target_pressure_blocking
            else (
                "review_required"
                if summary["target_pressure_opponent_combat_total"] == 0
                else "pass"
            )
        ),
        "findings": summary["target_pressure_findings"],
        "statuses": dict(sorted(summary["target_pressure_statuses"].items())),
        "opponent_combat_total": summary["target_pressure_opponent_combat_total"],
        "opponent_combat_to_target": summary["target_pressure_opponent_combat_to_target"],
        "opponent_combat_to_other": summary["target_pressure_opponent_combat_to_other"],
        "opponent_multi_defender_attack": summary[
            "target_pressure_opponent_multi_defender_attack"
        ],
        "blocking_seeds": summary["seeds_with_target_pressure_violations"],
    },
    "table_intent": {
        "status": (
            "blocked"
            if table_intent_blocking
            else (
                "review_required"
                if summary["table_intent_combat_total"] == 0
                else "pass"
            )
        ),
        "findings": summary["table_intent_findings"],
        "statuses": dict(sorted(summary["table_intent_statuses"].items())),
        "combat_total": summary["table_intent_combat_total"],
        "scored_combat_total": summary["table_intent_scored_combat_total"],
        "missing_scores": summary["table_intent_missing_scores"],
        "opponent_cast_illegal": summary["table_intent_opponent_cast_illegal"],
        "opponent_commander_cast": summary["table_intent_opponent_commander_cast"],
        "opponent_creature_cast": summary["table_intent_opponent_creature_cast"],
        "opponent_spell_cast": summary["table_intent_opponent_spell_cast"],
        "opponent_spell_resolved": summary["table_intent_opponent_spell_resolved"],
        "opponent_interaction_events": summary["table_intent_opponent_interaction_events"],
        "opponent_trigger_interaction_events": summary["table_intent_opponent_trigger_interaction_events"],
        "opponent_wins": summary["table_intent_opponent_wins"],
        "target_wins": summary["table_intent_target_wins"],
        "opponent_blockers_total": summary["table_intent_opponent_blockers_total"],
        "target_blockers_total": summary["table_intent_target_blockers_total"],
        "blocking_seeds": summary["seeds_with_table_intent_violations"],
    },
    "effect_coverage": {
        "status": (
            "review_required"
            if summary["effect_coverage_unknowns"]
            or summary["effect_coverage_residual_status"] != "effect_coverage_residual_accepted"
            or summary["effect_coverage_residual_unaccepted_card_flag_rows"]
            or summary["effect_coverage_residual_raw_unaccepted_flags"]
            else "pass"
        ),
        "unknown_effects": summary["effect_coverage_unknowns"],
        "heuristic_effects": summary["heuristic_effects"],
        "trigger_not_explicit": summary["trigger_not_explicit"],
        "cast_permission_not_explicit": summary["cast_permission_not_explicit"],
        "land_utility_ability_not_modeled": summary["land_utility_ability_not_modeled"],
        "review_only_rule_instances": summary["review_only_rule_instances"],
        "needs_review_rule_names": summary["needs_review_rule_names"],
        "residual_status": summary["effect_coverage_residual_status"],
        "residual_unaccepted_card_flag_rows": summary["effect_coverage_residual_unaccepted_card_flag_rows"],
        "residual_raw_unaccepted_flags": summary["effect_coverage_residual_raw_unaccepted_flags"],
    },
    "focused_template_dispatch": {
        "status": (
            "review_required"
            if summary["focused_template_dispatch_status"] != "focused_template_dispatch_ready"
            or summary["focused_template_without_predicate_match"]
            or summary["focused_template_without_evidence_dispatch"]
            or summary["focused_template_evidence_not_ready_unwaived"]
            else "pass"
        ),
        "status_detail": summary["focused_template_dispatch_status"],
        "focused_template_cards": summary["focused_template_cards"],
        "template_predicate_match": summary["focused_template_predicate_match"],
        "without_template_predicate_match": summary["focused_template_without_predicate_match"],
        "evidence_dispatch_ready": summary["focused_template_evidence_dispatch_ready"],
        "without_evidence_dispatch": summary["focused_template_without_evidence_dispatch"],
        "focused_evidence_ready": summary["focused_template_evidence_ready"],
        "focused_evidence_not_ready_unwaived": summary["focused_template_evidence_not_ready_unwaived"],
        "accepted_waivers": summary["focused_template_accepted_waivers"],
        "evidence_runner_status_counts": summary["focused_template_evidence_runner_status_counts"],
    },
    "unknown_template_backlog": {
        "status": (
            "review_required"
            if summary["unknown_template_without_plan_or_waiver"]
            or summary["unknown_template_without_reviewed_family"]
            or summary["unknown_template_without_focused_template_match"]
            or summary["unknown_template_backlog_status"] != "focused_template_backlog_ready"
            else "pass"
        ),
        "unknown_cards": summary["unknown_template_backlog_cards"],
        "without_current_inferred_family": summary["unknown_template_without_current_inferred_family"],
        "without_reviewed_family": summary["unknown_template_without_reviewed_family"],
        "without_focused_template_match": summary["unknown_template_without_focused_template_match"],
        "without_plan_or_waiver": summary["unknown_template_without_plan_or_waiver"],
        "status_detail": summary["unknown_template_backlog_status"],
    },
    "decision_trace_taxonomy": {
        "status": (
            "review_required"
            if summary["decision_trace_taxonomy_status"] != "decision_trace_taxonomy_ready"
            or summary["decision_trace_contract_findings"]
            or summary["decision_trace_static_without_contract"]
            or summary["decision_trace_observed_without_contract"]
            or summary["decision_trace_kinds_without_specific_contract"]
            or summary["decision_trace_observed_without_specific_contract"]
            else "pass"
        ),
        "status_detail": summary["decision_trace_taxonomy_status"],
        "rows": summary["decision_trace_taxonomy_rows"],
        "kinds_total": summary["decision_trace_kinds_total"],
        "kinds_observed": summary["decision_trace_kinds_observed"],
        "contract_findings": summary["decision_trace_contract_findings"],
        "missing_required_fields": summary["decision_trace_missing_required_fields"],
        "static_without_contract": summary["decision_trace_static_without_contract"],
        "observed_without_contract": summary["decision_trace_observed_without_contract"],
        "kinds_without_specific_contract": summary["decision_trace_kinds_without_specific_contract"],
        "observed_without_specific_contract": summary["decision_trace_observed_without_specific_contract"],
    },
    "event_contract_static": {
        "status": (
            "review_required"
            if summary["event_contract_static_status"] != "event_contract_static_ready"
            or summary["event_contract_static_observed_unclassified_total"]
            or summary["event_contract_static_static_unclassified_total"]
            or summary["event_contract_static_observed_missing_required_fields"]
            or summary["event_contract_static_waiver_until_forced_fixture"]
            else "pass"
        ),
        "status_detail": summary["event_contract_static_status"],
        "events_observed_total": summary["event_contract_static_events_observed_total"],
        "observed_event_types_total": summary["event_contract_static_observed_event_types_total"],
        "static_event_types_total": summary["event_contract_static_static_event_types_total"],
        "observed_unclassified_total": summary["event_contract_static_observed_unclassified_total"],
        "static_unclassified_total": summary["event_contract_static_static_unclassified_total"],
        "observed_missing_required_fields": summary["event_contract_static_observed_missing_required_fields"],
        "waiver_until_forced_fixture": summary["event_contract_static_waiver_until_forced_fixture"],
        "accepted_fixture_waivers": summary["event_contract_static_fixture_accepted_waiver_total"],
    },
}

summary["mandatory_gate_statuses"] = gate_statuses
status_values = {gate["status"] for gate in gate_statuses.values()}
summary["mandatory_gate_divergences"] = [
    f"{name}={gate['status']}"
    for name, gate in sorted(gate_statuses.items())
    if gate["status"] != "pass"
]
if any(gate["status"] == "blocked" for gate in gate_statuses.values()):
    summary["battle_replay_final_status"] = "blocked"
    summary["battle_replay_final_status_reason"] = "one_or_more_mandatory_gates_blocked"
elif any(gate["status"] == "review_required" for gate in gate_statuses.values()):
    summary["battle_replay_final_status"] = "review_required"
    summary["battle_replay_final_status_reason"] = "one_or_more_mandatory_gates_require_review"
else:
    summary["battle_replay_final_status"] = "trusted_for_strategy_learning"
    summary["battle_replay_final_status_reason"] = "all_mandatory_gates_pass"

summary.update(compute_global_learning_eligibility(
    global_learning_seed_rows,
    final_status=summary["battle_replay_final_status"],
    mandatory_gate_divergences=summary["mandatory_gate_divergences"],
))
summary.update(summarize_learned_opponent_provenance(learned_opponent_provenance_rows))

if (
    summary["forensic_card_id_missing_unaccepted"]
    or summary["forensic_semantic_hash_missing_unaccepted"]
    or summary["forensic_rule_logical_key_missing_unaccepted"]
):
    summary["forensic_lineage_status"] = "incomplete"
else:
    summary["forensic_lineage_status"] = "complete"

summary["action_verdict_counts"] = dict(sorted(summary["action_verdict_counts"].items()))
summary["action_event_contract_class_counts"] = dict(sorted(summary["action_event_contract_class_counts"].items()))
summary["action_event_type_class_counts"] = dict(sorted(summary["action_event_type_class_counts"].items()))
summary["action_event_type_class_seed_sum"] = dict(sorted(summary["action_event_type_class_seed_sum"].items()))
summary["action_event_type_class_distinct_counts"] = dict(sorted(summary["action_event_type_class_distinct_counts"].items()))
summary["action_event_types_unclassified"] = dict(sorted(summary["action_event_types_unclassified"].items()))
summary["strategy_severity_counts"] = dict(sorted(summary["strategy_severity_counts"].items()))
summary["strategy_code_counts"] = dict(sorted(summary["strategy_code_counts"].items()))
summary["strategy_learning_confidence_counts"] = dict(sorted(summary["strategy_learning_confidence_counts"].items()))
summary["decision_audit_statuses"] = dict(sorted(summary["decision_audit_statuses"].items()))
summary["decision_audit_severity_counts"] = dict(sorted(summary["decision_audit_severity_counts"].items()))
summary["forensic_severity_counts"] = dict(sorted(summary["forensic_severity_counts"].items()))
summary["forensic_lineage_missing_waiver_reasons"] = dict(sorted(summary["forensic_lineage_missing_waiver_reasons"].items()))
summary["target_pressure_statuses"] = dict(sorted(summary["target_pressure_statuses"].items()))
summary["table_intent_statuses"] = dict(sorted(summary["table_intent_statuses"].items()))
summary["deck_source_blocker_domains"] = dict(sorted(summary["deck_source_blocker_domains"].items()))

summary_path = run_dir / "summary.json"
summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

lines = [
    "# ManaLoom Battle Strategy Audit",
    "",
    f"- Timestamp UTC: `{summary['timestamp_utc']}`",
    f"- Run profile: `{summary['run_profile']}`",
    f"- Run scope: `{summary['run_scope']}`",
    f"- Invocation kind: `{summary['invocation_kind']}`",
    f"- Seeds source: `{summary['seeds_source']}`",
    f"- Start seed source: `{summary['start_seed_source']}`",
    f"- Run scope contract: `{summary['run_scope_contract']}`",
    f"- Seeds completed: `{summary['seeds_completed']}/{summary['seeds_requested']}`",
    f"- Test results total: `{summary['test_results_total']}`",
    f"- Test result status counts: `{json.dumps(summary['test_results_status_counts'], sort_keys=True)}`",
    f"- Py compile status: `{(summary['py_compile'] or {}).get('status')}`",
    f"- Py compile log: `{(summary['py_compile'] or {}).get('log_path')}`",
    f"- Tests recorded: `{summary['tests']}`",
    f"- Test logs: `{json.dumps(summary['test_logs'], sort_keys=True)}`",
    f"- Test empty-log successes: `{summary['test_log_empty_successes']}`",
    f"- Test empty-log failures: `{summary['test_log_empty_failures']}`",
    f"- Test result failures: `{summary['test_result_failures']}`",
    f"- Test results JSONL: `{summary['test_results_jsonl']}`",
    f"- Events: `{summary['events']}`",
    f"- Decisions: `{summary['decisions']}`",
    f"- Human replay RESOLVE ABILITY kind=? lines: `{summary['human_replay_resolve_ability_kind_unknown_lines']}`",
    f"- Human replay DAMAGE cause=? lines: `{summary['human_replay_damage_cause_unknown_lines']}`",
    f"- Human replay UNKNOWN lines: `{summary['human_replay_unknown_lines']}`",
    f"- Human replay PLACEHOLDER lines: `{summary['human_replay_placeholder_lines']}`",
    f"- Human replay placeholder samples: `{json.dumps(summary['human_replay_placeholder_samples'][:10], sort_keys=True)}`",
    f"- Action findings: `{summary['action_findings']}`",
    f"- Action events total: `{summary['action_events_total']}`",
    f"- Action event types total: `{summary['action_event_types_total']}`",
    f"- Action event types total semantics: `{summary['action_event_types_total_semantics']}`",
    f"- Action event types seed-sum: `{summary['action_event_types_seed_sum']}`",
    f"- Action event types distinct global: `{summary['action_event_types_distinct_total']}`",
    f"- Action event contract class counts: `{json.dumps(summary['action_event_contract_class_counts'], sort_keys=True)}`",
    f"- Action event type class counts: `{json.dumps(summary['action_event_type_class_counts'], sort_keys=True)}`",
    f"- Action event type class seed-sum: `{json.dumps(summary['action_event_type_class_seed_sum'], sort_keys=True)}`",
    f"- Action event type class distinct global: `{json.dumps(summary['action_event_type_class_distinct_counts'], sort_keys=True)}`",
    f"- Action events unclassified: `{summary['action_events_unclassified']}`",
    f"- Action event types unclassified: `{json.dumps(summary['action_event_types_unclassified'], sort_keys=True)}`",
    f"- Strategy findings: `{summary['strategy_findings']}`",
    f"- Strategy review-required findings: `{summary['strategy_review_required_findings']}`",
    f"- Strategy low-confidence findings: `{summary['strategy_low_confidence_findings']}`",
    f"- Replay decision turn findings: `{summary['decision_audit_turn_findings']}`",
    f"- Replay decision decision findings: `{summary['decision_audit_decision_findings']}`",
    f"- Replay decision statuses: `{json.dumps(summary['decision_audit_statuses'], sort_keys=True)}`",
    f"- Replay decision status scope: `{summary['decision_audit_status_scope']}`",
    f"- Replay decision human replay complete: `{summary['decision_audit_human_replay_complete']}`",
    f"- Replay decision rules interaction trusted: `{summary['decision_audit_rules_interaction_trusted']}`",
    f"- Forensic rule findings: `{summary['forensic_rule_findings']}`",
    f"- Forensic turn findings: `{summary['forensic_turn_findings']}`",
    f"- Target pressure statuses: `{json.dumps(dict(sorted(summary['target_pressure_statuses'].items())), sort_keys=True)}`",
    f"- Target pressure findings: `{summary['target_pressure_findings']}`",
    f"- Target pressure opponent combat total: `{summary['target_pressure_opponent_combat_total']}`",
    f"- Target pressure opponent combat to target: `{summary['target_pressure_opponent_combat_to_target']}`",
    f"- Target pressure opponent combat to other: `{summary['target_pressure_opponent_combat_to_other']}`",
    f"- Target pressure opponent multi-defender attacks: `{summary['target_pressure_opponent_multi_defender_attack']}`",
    f"- Table intent statuses: `{json.dumps(dict(sorted(summary['table_intent_statuses'].items())), sort_keys=True)}`",
    f"- Table intent findings: `{summary['table_intent_findings']}`",
    f"- Table intent combat total/scored/missing: `{summary['table_intent_combat_total']}/{summary['table_intent_scored_combat_total']}/{summary['table_intent_missing_scores']}`",
    f"- Table intent opponent cast illegal: `{summary['table_intent_opponent_cast_illegal']}`",
    f"- Table intent opponent commander/creature/spell casts: `{summary['table_intent_opponent_commander_cast']}/{summary['table_intent_opponent_creature_cast']}/{summary['table_intent_opponent_spell_cast']}`",
    f"- Table intent opponent resolved/interactions/trigger interactions: `{summary['table_intent_opponent_spell_resolved']}/{summary['table_intent_opponent_interaction_events']}/{summary['table_intent_opponent_trigger_interaction_events']}`",
    f"- Table intent wins target/opponents: `{summary['table_intent_target_wins']}/{summary['table_intent_opponent_wins']}`",
    f"- Table intent blockers target/opponents: `{summary['table_intent_target_blockers_total']}/{summary['table_intent_opponent_blockers_total']}`",
    f"- Forensic card event count: `{summary['forensic_card_event_count']}`",
    f"- Forensic card_id present/missing: `{summary['forensic_card_id_present']}/{summary['forensic_card_id_missing']}`",
    f"- Forensic card_id missing accepted/unaccepted: `{summary['forensic_card_id_missing_accepted']}/{summary['forensic_card_id_missing_unaccepted']}`",
    f"- Forensic semantic_hash present/missing: `{summary['forensic_semantic_hash_present']}/{summary['forensic_semantic_hash_missing']}`",
    f"- Forensic semantic_hash missing accepted/unaccepted: `{summary['forensic_semantic_hash_missing_accepted']}/{summary['forensic_semantic_hash_missing_unaccepted']}`",
    f"- Forensic rule_logical_key present/missing: `{summary['forensic_rule_logical_key_present']}/{summary['forensic_rule_logical_key_missing']}`",
    f"- Forensic rule_logical_key missing accepted/unaccepted: `{summary['forensic_rule_logical_key_missing_accepted']}/{summary['forensic_rule_logical_key_missing_unaccepted']}`",
    f"- Forensic lineage waiver reasons: `{json.dumps(summary['forensic_lineage_missing_waiver_reasons'], sort_keys=True)}`",
    f"- Forensic lineage unaccepted missing samples: `{json.dumps(summary['forensic_lineage_unaccepted_missing_samples'][:10], sort_keys=True)}`",
    f"- Forensic lineage status: `{summary['forensic_lineage_status']}`",
    f"- Deck provenance files: `{summary['deck_provenance_files']}`",
    f"- Deck metrics policy: `{summary['deck_metrics_policy']}`",
    f"- Deck cached metadata used for replay metrics: `{summary['deck_cached_metadata_used_for_replay_metrics']}`",
    f"- Deck blocker domain policy: `{summary['deck_blocker_domain_policy']}`",
    f"- Lorehold deck source: `{summary['lorehold_deck_source_kind']} {summary['lorehold_deck_source_ref']}`",
    f"- Lorehold deck metrics basis: `{summary['lorehold_deck_metrics_basis']}`",
    f"- Lorehold deck cached metadata used for metrics: `{summary['lorehold_deck_cached_metadata_used_for_metrics']}`",
    f"- Lorehold deck lands: `{summary['lorehold_deck_lands']}`",
    f"- Lorehold deck avg CMC nonlands: `{summary['lorehold_deck_avg_cmc_nonlands']}`",
    f"- Lorehold deck curve: `{json.dumps(summary['lorehold_deck_curve'], sort_keys=True)}`",
    f"- Deck source blocker domains: `{json.dumps(summary['deck_source_blocker_domains'], sort_keys=True)}`",
    f"- Learned deck source lookup: `{summary['learned_deck_source_lookup_status']} rows={summary['learned_deck_source_lookup_rows']} db={summary['learned_deck_source_lookup_db']}`",
    f"- Learned opponent source counts: `{json.dumps(summary['learned_opponent_source_counts'], sort_keys=True)}`",
    f"- Opponent deck provenance: `{json.dumps(summary['opponent_deck_provenance'], sort_keys=True)}`",
    f"- Learned deck opponents: `{json.dumps(summary['learned_deck_opponents'], sort_keys=True)}`",
    f"- Action verdict counts: `{json.dumps(summary['action_verdict_counts'], sort_keys=True)}`",
    f"- Strategy severity counts: `{json.dumps(summary['strategy_severity_counts'], sort_keys=True)}`",
    f"- Strategy code counts: `{json.dumps(summary['strategy_code_counts'], sort_keys=True)}`",
    f"- Strategy learning confidence counts: `{json.dumps(summary['strategy_learning_confidence_counts'], sort_keys=True)}`",
    f"- Strategy low-confidence seeds: `{summary['strategy_low_confidence_seeds']}`",
    f"- Strategy high-confidence learning seeds: `{summary['strategy_high_confidence_learning_seeds']}`",
    f"- Strategy not-learning-eligible seeds: `{summary['strategy_not_learning_eligible_seeds']}`",
    f"- Global learning eligibility policy: `{summary['global_learning_eligibility_policy']}`",
    f"- Global learning eligible seeds: `{summary['global_learning_eligible_seeds']}`",
    f"- Global not-learning-eligible seeds: `{summary['global_not_learning_eligible_seeds']}`",
    f"- Global learning eligibility reasons: `{json.dumps(summary['global_learning_eligibility_reasons'], sort_keys=True)}`",
    f"- Replay decision severity counts: `{json.dumps(summary['decision_audit_severity_counts'], sort_keys=True)}`",
    f"- Forensic severity counts: `{json.dumps(summary['forensic_severity_counts'], sort_keys=True)}`",
    f"- Research statuses: `{json.dumps(summary['research_statuses'], sort_keys=True)}`",
    f"- Effect coverage unknowns: `{summary['effect_coverage_unknowns']}`",
    f"- Effect coverage effect totals unknown: `{summary['effect_coverage_effect_totals_unknown']}`",
    f"- Effect coverage unknown effect source counts: `{json.dumps(summary['effect_coverage_unknown_effect_source_counts'], sort_keys=True)}`",
    f"- Effect coverage unknown effect status counts: `{json.dumps(summary['effect_coverage_unknown_effect_status_counts'], sort_keys=True)}`",
    f"- Needs-review unknown effect cards: `{summary['needs_review_unknown_effect_count']}`",
    f"- Focused template ready effect totals: `{json.dumps(summary['focused_template_ready_effect_totals'], sort_keys=True)}`",
    f"- Focused template effect scope totals: `{json.dumps(summary['focused_template_effect_scope_totals'], sort_keys=True)}`",
    f"- Focused template ready known/unknown effect cards: `{summary['focused_template_ready_known_effect_count']}/{summary['focused_template_ready_unknown_effect_count']}`",
    f"- Focused template ready unknown effect cards: `{summary['focused_template_ready_unknown_effect_cards']}`",
    f"- Focused template ready unknown effect scope cards: `{json.dumps(summary['focused_template_ready_unknown_effect_scope_cards'], sort_keys=True)}`",
    f"- Heuristic effects: `{summary['heuristic_effects']}`",
    f"- Trigger not explicit: `{summary['trigger_not_explicit']}`",
    f"- Cast permission not explicit: `{summary['cast_permission_not_explicit']}`",
    f"- Land utility ability not modeled: `{summary['land_utility_ability_not_modeled']}`",
    f"- Active-or-review rule names: `{summary['active_or_review_rule_names']}`",
    f"- Non-runtime-safe rule names: `{summary['non_runtime_safe_rule_names']}`",
    f"- Needs-review rule names: `{summary['needs_review_rule_names']}`",
    f"- Runtime-safe rule names: `{summary['runtime_safe_rule_names']}`",
    f"- Review-only rule names: `{summary['review_only_rule_names']}`",
    f"- Annotation-only rule names: `{summary['annotation_only_rule_names']}`",
    f"- Non-runtime other rule names: `{summary['non_runtime_other_rule_names']}`",
    f"- Review status counts: `{json.dumps(summary['review_status_counts'], sort_keys=True)}`",
    f"- Execution status counts: `{json.dumps(summary['execution_status_counts'], sort_keys=True)}`",
    f"- Review-only rule instances: `{summary['review_only_rule_instances']}`",
    f"- Effect coverage report: `{summary['effect_coverage_report']}`",
    f"- Effect coverage residual status: `{summary['effect_coverage_residual_status']}`",
    f"- Effect coverage residual card-flag accepted/unaccepted: `{summary['effect_coverage_residual_accepted_card_flag_rows']}/{summary['effect_coverage_residual_unaccepted_card_flag_rows']}`",
    f"- Effect coverage residual raw unaccepted flags: `{summary['effect_coverage_residual_raw_unaccepted_flags']}`",
    f"- Effect coverage residual accepted owners: `{json.dumps(summary['effect_coverage_residual_accepted_owner_totals'], sort_keys=True)}`",
    f"- Effect coverage residual report: `{summary['effect_coverage_residual_report']}`",
    f"- Focused template dispatch status: `{summary['focused_template_dispatch_status']}`",
    f"- Focused template cards: `{summary['focused_template_cards']}`",
    f"- Focused template predicate match/missing: `{summary['focused_template_predicate_match']}/{summary['focused_template_without_predicate_match']}`",
    f"- Focused template evidence dispatch ready/missing: `{summary['focused_template_evidence_dispatch_ready']}/{summary['focused_template_without_evidence_dispatch']}`",
    f"- Focused template evidence ready/not-ready-unwaived: `{summary['focused_template_evidence_ready']}/{summary['focused_template_evidence_not_ready_unwaived']}`",
    f"- Focused template accepted waivers: `{summary['focused_template_accepted_waivers']}`",
    f"- Focused template evidence runner statuses: `{json.dumps(summary['focused_template_evidence_runner_status_counts'], sort_keys=True)}`",
    f"- Focused template cards without dispatch: `{summary['focused_template_cards_without_dispatch']}`",
    f"- Focused template dispatch report: `{summary['focused_template_dispatch_report']}`",
    f"- Unknown template backlog status: `{summary['unknown_template_backlog_status']}`",
    f"- Unknown template cards: `{summary['unknown_template_backlog_cards']}`",
    f"- Unknown template current inferred family present/missing: `{summary['unknown_template_with_current_inferred_family']}/{summary['unknown_template_without_current_inferred_family']}`",
    f"- Unknown template reviewed family present/missing: `{summary['unknown_template_with_reviewed_family']}/{summary['unknown_template_without_reviewed_family']}`",
    f"- Unknown template focused template present/missing: `{summary['unknown_template_with_focused_template_match']}/{summary['unknown_template_without_focused_template_match']}`",
    f"- Unknown template plan-or-waiver present/missing: `{summary['unknown_template_with_plan_or_waiver']}/{summary['unknown_template_without_plan_or_waiver']}`",
    f"- Unknown template plan status counts: `{json.dumps(summary['unknown_template_plan_status_counts'], sort_keys=True)}`",
    f"- Unknown template reviewed family counts: `{json.dumps(summary['unknown_template_reviewed_family_counts'], sort_keys=True)}`",
    f"- Unknown template without plan or waiver: `{summary['unknown_template_unknowns_without_plan_or_waiver']}`",
    f"- Unknown template report: `{summary['unknown_template_backlog_report']}`",
    f"- Decision trace taxonomy status: `{summary['decision_trace_taxonomy_status']}`",
    f"- Decision trace taxonomy rows: `{summary['decision_trace_taxonomy_rows']}`",
    f"- Decision trace kinds total/observed/uncovered: `{summary['decision_trace_kinds_total']}/{summary['decision_trace_kinds_observed']}/{summary['decision_trace_kinds_uncovered']}`",
    f"- Decision trace contract findings: `{summary['decision_trace_contract_findings']}`",
    f"- Decision trace missing required fields: `{summary['decision_trace_missing_required_fields']}`",
    f"- Decision trace without static/observed contract: `{summary['decision_trace_static_without_contract']}/{summary['decision_trace_observed_without_contract']}`",
    f"- Decision trace without specific static/observed contract: `{summary['decision_trace_kinds_without_specific_contract']}/{summary['decision_trace_observed_without_specific_contract']}`",
    f"- Decision trace accepted waivers: `{summary['decision_trace_accepted_waivers']}`",
    f"- Decision trace observed counts: `{json.dumps(summary['decision_trace_observed_counts'], sort_keys=True)}`",
    f"- Decision trace observed without specific contract: `{summary['decision_trace_observed_without_specific_contract_types']}`",
    f"- Decision trace taxonomy report: `{summary['decision_trace_taxonomy_report']}`",
    f"- Event contract static status: `{summary['event_contract_static_status']}`",
    f"- Event contract observed events/types: `{summary['event_contract_static_events_observed_total']}/{summary['event_contract_static_observed_event_types_total']}`",
    f"- Event contract static/all event types: `{summary['event_contract_static_static_event_types_total']}/{summary['event_contract_static_all_event_types_total']}`",
    f"- Event contract observed/static unclassified: `{summary['event_contract_static_observed_unclassified_total']}/{summary['event_contract_static_static_unclassified_total']}`",
    f"- Event contract observed missing required fields: `{summary['event_contract_static_observed_missing_required_fields']}`",
    f"- Event contract observed not static literal: `{summary['event_contract_static_observed_not_static_literal']}`",
    f"- Event contract fixture/waiver counts: `{json.dumps(summary['event_contract_static_fixture_or_waiver_counts'], sort_keys=True)}`",
    f"- Event contract accepted fixture waivers: `{summary['event_contract_static_fixture_accepted_waiver_total']}`",
    f"- Event contract waiver until forced fixture: `{summary['event_contract_static_waiver_until_forced_fixture']}`",
    f"- Event contract accepted fixture waiver reasons: `{json.dumps(summary['event_contract_static_fixture_accepted_waiver_reasons'], sort_keys=True)}`",
    f"- Event contract fixture unaccepted types: `{json.dumps(summary['event_contract_static_fixture_unaccepted_types'], sort_keys=True)}`",
    f"- Event contract static class counts: `{json.dumps(summary['event_contract_static_static_class_counts'], sort_keys=True)}`",
    f"- Event contract observed type class counts: `{json.dumps(summary['event_contract_static_observed_type_class_counts'], sort_keys=True)}`",
    f"- Event contract observed event class counts: `{json.dumps(summary['event_contract_static_observed_event_class_counts'], sort_keys=True)}`",
    f"- Event contract static report: `{summary['event_contract_static_report']}`",
    f"- Runtime surface manifest files: `{summary['runtime_surface_manifest_total_files']}`",
    f"- Runtime surface unclassified files: `{summary['runtime_surface_manifest_unclassified_files']}`",
    f"- Runtime surface category counts: `{json.dumps(summary['runtime_surface_manifest_category_counts'], sort_keys=True)}`",
    f"- Runtime surface automation coverage counts: `{json.dumps(summary['runtime_surface_manifest_automation_coverage_counts'], sort_keys=True)}`",
    f"- Runtime surface gate expected counts: `{json.dumps(summary['runtime_surface_manifest_gate_expected_counts'], sort_keys=True)}`",
    f"- Runtime surface manifest status: `{summary['runtime_surface_manifest_status']}`",
    f"- Runtime surface recurring categories: `{summary['runtime_surface_manifest_recurring_categories']}`",
    f"- Runtime surface outside-recurring categories: `{summary['runtime_surface_manifest_outside_recurring_categories']}`",
    f"- Runtime surface manifest report: `{summary['runtime_surface_manifest_report']}`",
    f"- Mandatory gate statuses: `{json.dumps(summary['mandatory_gate_statuses'], sort_keys=True)}`",
    f"- Mandatory gate divergences: `{summary['mandatory_gate_divergences']}`",
    f"- Battle replay final status: `{summary['battle_replay_final_status']}`",
    f"- Battle replay final status reason: `{summary['battle_replay_final_status_reason']}`",
    f"- Action high/critical seeds: `{summary['seeds_with_high_or_critical_action_findings']}`",
    f"- Strategy blocked seeds: `{summary['seeds_with_strategy_blockers']}`",
    f"- Replay decision high/critical seeds: `{summary['seeds_with_high_or_critical_decision_audit_findings']}`",
    f"- Forensic high/critical seeds: `{summary['seeds_with_high_or_critical_forensic_findings']}`",
    f"- Target pressure violation seeds: `{summary['seeds_with_target_pressure_violations']}`",
    f"- Table intent violation seeds: `{summary['seeds_with_table_intent_violations']}`",
    "",
    "## Interpretation",
    "",
    "- High/critical action findings block trusting the replay as training data.",
    "- Strategy blockers mean the play may be legal but should not teach deck decisions yet.",
    "- High/critical replay decision or forensic findings block trusting the replay as complete battle evidence.",
    "- Low/medium findings are backlog unless they repeat across many seeds.",
    "",
]
(run_dir / "summary.md").write_text("\n".join(lines), encoding="utf-8")
print(json.dumps(summary, sort_keys=True))
PY

latest_link="$ARTIFACT_ROOT/latest"
rm -f "$latest_link"
ln -s "$run_dir" "$latest_link"

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] battle strategy audit finished run_dir=$run_dir"
cat "$run_dir/summary.json"

python3 - "$run_dir/summary.json" "$LOG_DIR/battle-strategy-alerts.log" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

summary_path = Path(sys.argv[1])
alert_log_path = Path(sys.argv[2])
summary = json.loads(summary_path.read_text(encoding="utf-8"))


def as_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def applescript_quote(value):
    text = str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")
    return f'"{text}"'


action_counts = summary.get("action_verdict_counts") or {}
action_high = as_int(action_counts.get("high"))
action_critical = as_int(action_counts.get("critical"))
action_seeds = summary.get("seeds_with_high_or_critical_action_findings") or []
strategy_blockers = summary.get("seeds_with_strategy_blockers") or []
decision_audit_seeds = summary.get("seeds_with_high_or_critical_decision_audit_findings") or []
forensic_seeds = summary.get("seeds_with_high_or_critical_forensic_findings") or []
coverage_unknowns = as_int(summary.get("effect_coverage_unknowns"))
coverage_threshold_raw = os.environ.get("MANALOOM_BATTLE_EFFECT_COVERAGE_UNKNOWN_ALERT_THRESHOLD", "")
coverage_threshold = None
if coverage_threshold_raw:
    try:
        coverage_threshold = int(coverage_threshold_raw)
    except ValueError:
        coverage_threshold = None
coverage_alert = coverage_threshold is not None and coverage_unknowns > coverage_threshold

if (
    action_high
    or action_critical
    or action_seeds
    or strategy_blockers
    or decision_audit_seeds
    or forensic_seeds
    or coverage_alert
):
    seed_preview = ", ".join(map(str, action_seeds[:8]))
    if len(action_seeds) > 8:
        seed_preview += ", ..."
    blocker_preview = ", ".join(map(str, strategy_blockers[:8]))
    if len(strategy_blockers) > 8:
        blocker_preview += ", ..."
    decision_preview = ", ".join(map(str, decision_audit_seeds[:8]))
    if len(decision_audit_seeds) > 8:
        decision_preview += ", ..."
    forensic_preview = ", ".join(map(str, forensic_seeds[:8]))
    if len(forensic_seeds) > 8:
        forensic_preview += ", ..."

    parts = []
    if action_high or action_critical:
        parts.append(f"action high={action_high} critical={action_critical}")
    if action_seeds:
        parts.append(f"action seeds={seed_preview}")
    if strategy_blockers:
        parts.append(f"strategy blockers={len(strategy_blockers)} seeds [{blocker_preview}]")
    if decision_audit_seeds:
        parts.append(f"replay decision high/critical seeds={len(decision_audit_seeds)} [{decision_preview}]")
    if forensic_seeds:
        parts.append(f"forensic high/critical seeds={len(forensic_seeds)} [{forensic_preview}]")
    if coverage_alert:
        parts.append(f"effect coverage unknowns={coverage_unknowns} threshold={coverage_threshold}")

    alert = {
        "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "summary_path": str(summary_path),
        "action_high": action_high,
        "action_critical": action_critical,
        "action_seeds": action_seeds,
        "strategy_blocker_seeds": strategy_blockers,
        "decision_audit_seeds": decision_audit_seeds,
        "forensic_seeds": forensic_seeds,
        "effect_coverage_unknowns": coverage_unknowns,
        "effect_coverage_unknown_threshold": coverage_threshold,
        "message": "; ".join(parts),
    }
    alert_log_path.parent.mkdir(parents=True, exist_ok=True)
    with alert_log_path.open("a", encoding="utf-8") as alert_log:
        alert_log.write(json.dumps(alert, sort_keys=True) + "\n")

    osascript = Path("/usr/bin/osascript")
    desktop_notifications = os.environ.get(
        "MANALOOM_BATTLE_STRATEGY_DESKTOP_NOTIFICATIONS", "0"
    ) == "1"
    if desktop_notifications and osascript.is_file():
        title = "ManaLoom Battle Strategy Audit"
        subtitle = "High/critical findings"
        message = f"{alert['message']}. summary.json: {summary_path}"
        script = (
            f"display notification {applescript_quote(message)} "
            f"with title {applescript_quote(title)} "
            f"subtitle {applescript_quote(subtitle)}"
        )
        result = subprocess.run(
            [str(osascript), "-e", script],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if result.returncode != 0:
            alert["notification_error"] = result.stderr.strip()
            with alert_log_path.open("a", encoding="utf-8") as alert_log:
                alert_log.write(json.dumps(alert, sort_keys=True) + "\n")
    print("MANALOOM_BATTLE_STRATEGY_ALERT " + json.dumps(alert, sort_keys=True))
PY
