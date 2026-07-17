#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
REPORT_DIR="${MANALOOM_DEEP_AI_REPORT_DIR:-/tmp/manaloom_deep_ai_alignment_reports}"
TS="$(date -u +%Y%m%d_%H%M%S)"
RUN_ID="deep_ai_alignment_${TS}"
SUMMARY_FILE="$REPORT_DIR/${RUN_ID}_summary.md"
FAILED_STEPS=()

mkdir -p "$REPORT_DIR"

write_summary_header() {
  cat >"$SUMMARY_FILE" <<EOF
# ManaLoom Deep AI Alignment Tester

- run_id: \`$RUN_ID\`
- generated_at_utc: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`
- repo: \`$ROOT_DIR\`

## Steps

EOF
}

run_step() {
  local label="$1"
  local command="$2"
  local slug
  slug="$(printf '%s' "$label" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')"
  local log_file="$REPORT_DIR/${RUN_ID}_${slug}.log"

  echo ""
  echo "============================================================"
  echo "$label"
  echo "============================================================"
  echo "\$ $command" | tee "$log_file"

  bash -o pipefail -c "$command" >>"$log_file" 2>&1
  local status=$?

  if [[ "$status" -eq 0 ]]; then
    echo "PASS: $label"
    printf -- "- PASS: %s ([log](%s))\n" "$label" "$(basename "$log_file")" >>"$SUMMARY_FILE"
  else
    echo "FAIL: $label (exit $status)"
    printf -- "- FAIL: %s, exit %s ([log](%s))\n" "$label" "$status" "$(basename "$log_file")" >>"$SUMMARY_FILE"
    FAILED_STEPS+=("$label")
  fi
}

run_pg_counts() {
  local sql
  sql="SELECT 'cards', count(*) FROM cards UNION ALL SELECT 'card_intelligence_snapshot', count(*) FROM card_intelligence_snapshot UNION ALL SELECT 'card_function_tags', count(*) FROM card_function_tags UNION ALL SELECT 'card_semantic_tags_v2', count(*) FROM card_semantic_tags_v2 UNION ALL SELECT 'card_battle_rules', count(*) FROM card_battle_rules UNION ALL SELECT 'commander_learned_decks', count(*) FROM commander_learned_decks UNION ALL SELECT 'commander_learning_snapshot', count(*) FROM commander_learning_snapshot ORDER BY 1;"
  run_step "New PostgreSQL data counts" "\"$ROOT_DIR/server/bin/with_new_server_pg.sh\" --read-only psql -X -A -t -F '|' -c \"$sql\""
}

run_auditors() {
  run_step "Deckbuilding contract surface audit" \
    "python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py\" --out-prefix \"$REPORT_DIR/deckbuilding_contract_surface_audit_${TS}_deep_ai_tester\""

  run_step "XMage strategy consistency audit" \
    "python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py\" --output-prefix \"$REPORT_DIR/xmage_strategy_consistency_audit_${TS}_deep_ai_tester\""

  run_step "XMage execution contract audit" \
    "python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py\" --output-prefix \"$REPORT_DIR/xmage_execution_contract_audit_${TS}_deep_ai_tester\""

  run_step "Operational surface alignment audit" \
    "python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py\" --out-prefix \"$REPORT_DIR/operational_surface_alignment_audit_${TS}_deep_ai_tester\""

  run_step "Legacy contamination audit" \
    "python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py\" --out-prefix \"$REPORT_DIR/legacy_contamination_audit_${TS}_deep_ai_tester\""

  run_step "PG Hermes SQLite contract audit through new PostgreSQL" \
    "\"$ROOT_DIR/server/bin/with_new_server_pg.sh\" --write-approved python3 \"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py\" --out-prefix \"$REPORT_DIR/pg_hermes_sqlite_contract_audit_${TS}_deep_ai_tester\""
}

write_final_summary() {
  {
    echo ""
    echo "## Result"
    echo ""
    if [[ "${#FAILED_STEPS[@]}" -eq 0 ]]; then
      echo "Status: PASS"
      echo ""
      echo "All deep AI alignment tester steps passed."
    else
      echo "Status: FAIL"
      echo ""
      echo "Failed steps:"
      for step in "${FAILED_STEPS[@]}"; do
        printf -- "- %s\n" "$step"
      done
    fi
  } >>"$SUMMARY_FILE"
}

main() {
  write_summary_header

  run_step "Dart analyze server" "cd \"$ROOT_DIR/server\" && dart pub get && dart analyze"
  run_step "Focused AI and data contract tests" "cd \"$ROOT_DIR/server\" && JWT_SECRET=local_deep_ai_alignment_${TS} dart test test/commander_ai_prompt_eval_suite_test.dart test/commander_deckbuilding_contract_support_test.dart test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/experimental_deck_ai_authorization_source_test.dart test/candidate_quality_data_support_test.dart test/data_model_migration_test.dart test/optimize_route_request_support_test.dart test/optimize_route_recommendation_context_support_test.dart test/optimization_quality_gate_test.dart test/ai_optimize_authorization_source_test.dart test/production_ai_mock_fallback_policy_test.dart test/openai_runtime_config_test.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_support_test.dart"
  run_step "PostgreSQL to Hermes sync contract tests" "cd \"$ROOT_DIR\" && python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_card_metadata_to_hermes.py && python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_target_deck_to_hermes.py"
  run_step "Commander AI prompt eval quality gate" "\"$ROOT_DIR/scripts/quality_gate.sh\" ai-eval"
  if [[ -x "$ROOT_DIR/scripts/manaloom_old_server_reference_audit.sh" ]]; then
    run_step "ManaLoom server target audit" "\"$ROOT_DIR/scripts/manaloom_old_server_reference_audit.sh\""
  fi
  require_live_mutation_approval "ManaLoom deep AI PostgreSQL runners" || exit $?
  require_postgres_write_approval "ManaLoom deep AI PostgreSQL runners" || exit $?
  run_step "New PostgreSQL migration status" "\"$ROOT_DIR/server/bin/with_new_server_pg.sh\" --write-approved bash -lc 'cd \"$ROOT_DIR/server\" && dart run bin/migrate.dart --status'"
  run_pg_counts
  run_auditors

  write_final_summary

  echo ""
  echo "Summary: $SUMMARY_FILE"
  if [[ "${#FAILED_STEPS[@]}" -eq 0 ]]; then
    exit 0
  fi
  exit 1
}

main "$@"
