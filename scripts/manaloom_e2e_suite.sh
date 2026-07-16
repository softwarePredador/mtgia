#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_ROOT="${MANALOOM_E2E_REPORT_ROOT:-/tmp/manaloom_e2e_suite_reports}"
RUN_DIR="${MANALOOM_E2E_RUN_DIR:-$REPORT_ROOT/manaloom_e2e_suite_$STAMP}"
SUMMARY_FILE="$RUN_DIR/summary.md"
SUMMARY_JSON_FILE="$RUN_DIR/summary.json"
STEP_MANIFEST_FILE="$RUN_DIR/steps.tsv"
FAILED_STEPS=()
SKIPPED_STEPS=()
BLOCKED_STEPS=()
FINAL_STATUS=""

mkdir -p "$RUN_DIR"
: >"$STEP_MANIFEST_FILE"

derive_profile() {
  local live_requested=0
  local isolated_requested=0
  if [[ "${MANALOOM_RUN_FLUTTER_RUNTIME_E2E:-0}" == "1" ||
        "${MANALOOM_RUN_SERVER_LIVE_E2E:-0}" == "1" ||
        "${MANALOOM_RUN_LIVE_PRODUCT_E2E:-0}" == "1" ]]; then
    live_requested=1
  fi
  if [[ "${MANALOOM_RUN_MUTATING_RESOLUTION_E2E:-0}" == "1" ||
        "${MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E:-0}" == "1" ]]; then
    isolated_requested=1
  fi

  if [[ "$live_requested" -eq 1 && "$isolated_requested" -eq 1 ]]; then
    echo "live-smoke+isolated-mutating"
  elif [[ "$live_requested" -eq 1 ]]; then
    echo "live-smoke"
  elif [[ "$isolated_requested" -eq 1 ]]; then
    echo "isolated-mutating"
  else
    echo "deterministic-read-only"
  fi
}

E2E_PROFILE="$(derive_profile)"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//'
}

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

write_summary_header() {
  cat >"$SUMMARY_FILE" <<EOF
# ManaLoom E2E Suite

- run_id: \`manaloom_e2e_suite_$STAMP\`
- generated_at_utc: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`
- repo: \`$ROOT_DIR\`
- logs: \`$RUN_DIR\`
- requested_profile: \`$E2E_PROFILE\`

## Steps

EOF
}

record_step() {
  local status="$1"
  local label="$2"
  local exit_code="$3"
  local log_file="$4"
  local reason="$5"

  label="${label//$'\t'/ }"
  label="${label//$'\n'/ }"
  log_file="${log_file//$'\t'/ }"
  reason="${reason//$'\t'/ }"
  reason="${reason//$'\n'/ }"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$status" "$label" "$exit_code" "$log_file" "$reason" >>"$STEP_MANIFEST_FILE"
}

run_step() {
  local label="$1"
  local command="$2"
  local slug
  slug="$(slugify "$label")"
  local log_file="$RUN_DIR/${slug}.log"

  print_header "$label"
  echo "$ $command" | tee "$log_file"

  bash -o pipefail -c "$command" >>"$log_file" 2>&1
  local status=$?

  if [[ "$status" -eq 0 ]]; then
    echo "PASS: $label"
    printf -- "- PASS: %s ([log](%s))\n" "$label" "$(basename "$log_file")" >>"$SUMMARY_FILE"
    record_step "PASS" "$label" "$status" "$(basename "$log_file")" ""
  else
    echo "FAIL: $label (exit $status)"
    printf -- "- FAIL: %s, exit %s ([log](%s))\n" "$label" "$status" "$(basename "$log_file")" >>"$SUMMARY_FILE"
    FAILED_STEPS+=("$label")
    record_step "FAIL" "$label" "$status" "$(basename "$log_file")" "command_failed"
  fi
}

skip_step() {
  local label="$1"
  local reason="$2"
  print_header "$label"
  echo "SKIP: $reason"
  printf -- "- SKIP: %s - %s\n" "$label" "$reason" >>"$SUMMARY_FILE"
  SKIPPED_STEPS+=("$label")
  record_step "SKIP" "$label" "" "" "$reason"
}

block_step() {
  local label="$1"
  local reason="$2"
  print_header "$label"
  echo "BLOCKED: $reason"
  printf -- "- BLOCKED: %s - %s\n" "$label" "$reason" >>"$SUMMARY_FILE"
  BLOCKED_STEPS+=("$label")
  record_step "BLOCKED" "$label" "2" "" "$reason"
}

run_optional_flutter_runtime_e2e() {
  if [[ "${MANALOOM_RUN_FLUTTER_RUNTIME_E2E:-0}" != "1" ]]; then
    skip_step \
      "Flutter live runtime integration E2E" \
      "set MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 with a ready API/device target to run integration_test flows"
    return
  fi

  if ! manaloom_has_live_mutation_approval; then
    block_step \
      "Flutter live runtime integration E2E" \
      "requested live flow can mutate API data; set MANALOOM_CONFIRM_LIVE_MUTATIONS=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit approval"
    return
  fi

  run_step "Flutter live runtime deck generate E2E" \
    "cd \"$ROOT_DIR/app\" && flutter test integration_test/deck_generate_async_runtime_test.dart --no-version-check --reporter compact"
  run_step "Flutter live runtime learned deck E2E" \
    "cd \"$ROOT_DIR/app\" && flutter test integration_test/commander_learned_deck_runtime_test.dart --no-version-check --reporter compact"
  run_step "Flutter live runtime functional tags E2E" \
    "cd \"$ROOT_DIR/app\" && flutter test integration_test/deck_functional_tags_runtime_test.dart --no-version-check --reporter compact"
}

run_optional_server_live_e2e() {
  if [[ "${MANALOOM_RUN_SERVER_LIVE_E2E:-0}" != "1" ]]; then
    skip_step \
      "Server live API E2E" \
      "set MANALOOM_RUN_SERVER_LIVE_E2E=1 with TEST_API_BASE_URL/API_BASE_URL pointing to a ready backend to run live server integration tests"
    return
  fi

  if ! manaloom_has_live_mutation_approval; then
    block_step \
      "Server live API E2E" \
      "requested backend integration can create users/decks; set MANALOOM_CONFIRM_LIVE_MUTATIONS=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit approval"
    return
  fi

  local live_api_base="${TEST_API_BASE_URL:-${API_BASE_URL:-http://127.0.0.1:8082}}"
  run_step "Server live AI generate optimize telemetry E2E" \
    "cd \"$ROOT_DIR/server\" && RUN_INTEGRATION_TESTS=1 TEST_API_BASE_URL=\"$live_api_base\" JWT_SECRET=local_manaloom_live_e2e_$STAMP dart test -j 1 test/ai_generate_create_optimize_flow_test.dart test/ai_optimize_flow_test.dart test/ai_optimize_telemetry_contract_test.dart"
}

run_optional_live_product_e2e() {
  if [[ "${MANALOOM_RUN_LIVE_PRODUCT_E2E:-0}" != "1" ]]; then
    skip_step \
      "Live product/API E2E" \
      "set MANALOOM_RUN_LIVE_PRODUCT_E2E=1 to run product smoke, AI paywall and AI generation benchmark against the configured API"
    return
  fi

  if ! manaloom_has_live_mutation_approval; then
    block_step \
      "Live product/API E2E" \
      "product smoke, paywall and benchmark create and delete live data; set MANALOOM_CONFIRM_LIVE_MUTATIONS=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit approval"
    return
  fi
  if ! manaloom_has_postgres_write_approval; then
    block_step \
      "Live product/API E2E" \
      "live scripts seed or clean PostgreSQL directly; set MANALOOM_CONFIRM_POSTGRES_WRITES=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit PostgreSQL approval"
    return
  fi

  run_step "Live product smoke E2E" "\"$ROOT_DIR/scripts/manaloom_product_smoke.sh\""
  run_step "Live AI paywall E2E" "\"$ROOT_DIR/scripts/manaloom_ai_paywall_e2e.sh\""
  run_step "Live AI generation benchmark" "\"$ROOT_DIR/scripts/manaloom_ai_generation_benchmark.sh\""
}

run_resolution_corpus_e2e() {
  if [[ "${MANALOOM_RUN_MUTATING_RESOLUTION_E2E:-0}" == "1" ]]; then
    if ! manaloom_has_postgres_write_approval; then
      block_step \
        "Commander resolution corpus mutating E2E" \
        "requested flow creates validation users/decks; set MANALOOM_CONFIRM_POSTGRES_WRITES=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit PostgreSQL approval"
      return
    fi
    run_step "Commander resolution corpus E2E" \
      "\"$ROOT_DIR/scripts/quality_gate.sh\" resolution"
    return
  fi

  run_step "Commander resolution corpus read-only preflight" \
    "VALIDATION_PREFLIGHT_ONLY=1 \"$ROOT_DIR/scripts/quality_gate.sh\" resolution"
  skip_step \
    "Commander resolution corpus mutating E2E" \
    "set MANALOOM_RUN_MUTATING_RESOLUTION_E2E=1 plus the textual PostgreSQL approval token only after explicit approval"
}

run_battle_product_e2e() {
  if [[ "$E2E_PROFILE" == *"isolated-mutating"* ]]; then
    if ! manaloom_has_postgres_write_approval; then
      block_step \
        "Battle product isolated mutating E2E" \
        "requested flow creates a unique validation user, decks and battle replay; set MANALOOM_CONFIRM_POSTGRES_WRITES=$MANALOOM_EXPLICIT_APPROVAL_PHRASE only after explicit PostgreSQL approval"
      return
    fi
    run_step "Battle product isolated mutating E2E" \
      "\"$ROOT_DIR/scripts/manaloom_battle_product_gate.sh\" --isolated-e2e"
    return
  fi

  skip_step \
    "Battle product isolated mutating E2E" \
    "set MANALOOM_RUN_MUTATING_BATTLE_PRODUCT_E2E=1 plus the textual PostgreSQL approval token to run against a harness-owned IPv4-loopback API"
}

write_final_summary() {
  if [[ "${#FAILED_STEPS[@]}" -gt 0 ]]; then
    FINAL_STATUS="FAIL"
  elif [[ "${#BLOCKED_STEPS[@]}" -gt 0 ]]; then
    FINAL_STATUS="BLOCKED"
  elif [[ "${#SKIPPED_STEPS[@]}" -gt 0 ]]; then
    FINAL_STATUS="PARTIAL"
  else
    FINAL_STATUS="PASS"
  fi

  {
    echo ""
    echo "## Result"
    echo ""
    echo "Status: $FINAL_STATUS"
    if [[ "${#FAILED_STEPS[@]}" -gt 0 ]]; then
      echo ""
      echo "Failed steps:"
      for step in "${FAILED_STEPS[@]}"; do
        printf -- "- %s\n" "$step"
      done
    fi

    if [[ "${#BLOCKED_STEPS[@]}" -gt 0 ]]; then
      echo ""
      echo "Blocked requested steps:"
      for step in "${BLOCKED_STEPS[@]}"; do
        printf -- "- %s\n" "$step"
      done
    fi

    if [[ "${#SKIPPED_STEPS[@]}" -gt 0 ]]; then
      echo ""
      echo "Skipped optional steps:"
      for step in "${SKIPPED_STEPS[@]}"; do
        printf -- "- %s\n" "$step"
      done
    fi
  } >>"$SUMMARY_FILE"
}

write_summary_json() {
  python3 - \
    "$STEP_MANIFEST_FILE" \
    "$SUMMARY_JSON_FILE" \
    "$FINAL_STATUS" \
    "$E2E_PROFILE" \
    "$RUN_DIR" \
    "$STAMP" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
summary_path = Path(sys.argv[2])
result = sys.argv[3]
profile = sys.argv[4]
run_dir = sys.argv[5]
stamp = sys.argv[6]

steps = []
counts = {"PASS": 0, "FAIL": 0, "SKIP": 0, "BLOCKED": 0}
for raw_line in manifest_path.read_text(encoding="utf-8").splitlines():
    fields = raw_line.split("\t", 4)
    if len(fields) != 5:
        continue
    status, label, exit_code, log_file, reason = fields
    counts[status] = counts.get(status, 0) + 1
    steps.append(
        {
            "label": label,
            "status": status.lower(),
            "exit_code": int(exit_code) if exit_code else None,
            "log": log_file or None,
            "reason": reason or None,
        }
    )

payload = {
    "schema_version": 1,
    "run_id": f"manaloom_e2e_suite_{stamp}",
    "requested_profile": profile,
    "result": result.lower(),
    "run_dir": run_dir,
    "summary": {
        "step_count": len(steps),
        "passed": counts.get("PASS", 0),
        "failed": counts.get("FAIL", 0),
        "skipped": counts.get("SKIP", 0),
        "blocked": counts.get("BLOCKED", 0),
    },
    "steps": steps,
}
summary_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

main() {
  write_summary_header

  run_step "Patrol product E2E local" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" patrol-smoke"

  run_step "Flutter deckbuilder E2E and deck UI contracts" \
    "cd \"$ROOT_DIR/app\" && flutter test test/features/decks --no-version-check --reporter compact"

  run_step "Flutter commercial retention trade contracts" \
    "cd \"$ROOT_DIR/app\" && flutter test test/features/commercial test/features/retention test/features/growth test/features/trades --no-version-check --reporter compact"

  run_step "Flutter app logs and observability contracts" \
    "cd \"$ROOT_DIR/app\" && flutter test test/core/utils/logger_test.dart test/core/observability/app_observability_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart --no-version-check --reporter compact"

  run_step "Server AI deckbuilder battle route contracts" \
    "cd \"$ROOT_DIR/server\" && RUN_INTEGRATION_TESTS=0 JWT_SECRET=local_manaloom_e2e_$STAMP dart test test/ai_generate_learning_boundary_test.dart test/deck_simulate_route_adapter_test.dart test/deck_recommendations_route_adapter_test.dart test/deck_recommendations_route_support_test.dart test/deck_recommendations_power_level_support_test.dart test/commander_deckbuilding_contract_support_test.dart test/commander_ai_prompt_eval_suite_test.dart test/commander_learned_deck_support_test.dart test/deck_learning_event_support_test.dart test/ai_generate_performance_support_test.dart test/generated_deck_validation_service_test.dart test/production_ai_mock_fallback_policy_test.dart"

  run_step "Canonical battle product gate" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" battle"

  run_battle_product_e2e

  run_step "Battle runtime pytest suite" \
    "cd \"$ROOT_DIR\" && \"$ROOT_DIR/server/bin/with_new_server_pg.sh\" env PYTHONPATH=\"$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts:\${PYTHONPATH:-}\" python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_*.py"

  run_step "Report retention governance" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" report-retention"

  run_resolution_corpus_e2e

  run_step "App AI bridge and Commander prompt eval" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" ai-bridge"

  run_step "PostgreSQL Hermes SQLite contract" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" pg-contract"

  run_step "Deep AI alignment with deckbuilder battle logs" \
    "\"$ROOT_DIR/scripts/quality_gate.sh\" deep-ai"

  run_optional_flutter_runtime_e2e
  run_optional_server_live_e2e
  run_optional_live_product_e2e

  write_final_summary
  write_summary_json

  echo ""
  echo "Summary: $SUMMARY_FILE"
  echo "Summary JSON: $SUMMARY_JSON_FILE"
  echo "Logs: $RUN_DIR"

  case "$FINAL_STATUS" in
    PASS|PARTIAL) exit 0 ;;
    BLOCKED) exit 2 ;;
    *) exit 1 ;;
  esac
}

main "$@"
