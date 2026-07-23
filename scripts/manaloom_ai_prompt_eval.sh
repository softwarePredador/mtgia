#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_PREFIX="${MANALOOM_AI_PROMPT_EVAL_OUT_PREFIX:-/tmp/manaloom_ai_prompt_eval_$STAMP}"
FIXTURES="${MANALOOM_AI_PROMPT_EVAL_FIXTURES:-test/fixtures/commander_ai_prompt_eval_cases.json}"

cd "$ROOT_DIR/server"
dart run bin/commander_ai_prompt_eval.dart \
  --fixtures "$FIXTURES" \
  --out-prefix "$OUT_PREFIX"

dart test \
  test/commander_ai_prompt_eval_suite_test.dart \
  test/commander_ai_live_eval_support_test.dart \
  test/generated_deck_validation_service_test.dart \
  test/goldfish_simulator_test.dart \
  test/optimization_quality_gate_test.dart \
  test/optimize_route_outcome_support_test.dart \
  test/optimize_route_response_support_test.dart \
  test/ai_job_lifecycle_test.dart \
  test/openai_runtime_config_test.dart \
  test/production_ai_mock_fallback_policy_test.dart
