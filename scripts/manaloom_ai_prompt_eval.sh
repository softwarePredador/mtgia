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
