#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDITOR="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_capability_alignment_audit.py"
TEST="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/test_external_engine_capability_alignment_audit.py"
SOURCE_CONTRACT_TEST="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/test_external_engine_source_contract.py"
OUTPUT_PREFIX="${MANALOOM_EXTERNAL_ENGINE_CAPABILITY_OUT:-/tmp/manaloom_external_engine_capability_alignment}"

args=(--output-prefix "$OUTPUT_PREFIX")
if [[ -n "${MANALOOM_XMAGE_SOURCE_ROOT:-}" ]]; then
  args+=(--xmage-root "$MANALOOM_XMAGE_SOURCE_ROOT")
fi
if [[ -n "${MANALOOM_FORGE_SOURCE_ROOT:-}" ]]; then
  args+=(--forge-root "$MANALOOM_FORGE_SOURCE_ROOT")
fi
if [[ "${MANALOOM_REQUIRE_EXTERNAL_ENGINE_SOURCES:-0}" == "1" ]]; then
  args+=(--require-sources)
fi

cd "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts"
PYTHONWARNINGS=error::ResourceWarning python3 "$TEST"
PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -q "$SOURCE_CONTRACT_TEST"
cd "$ROOT_DIR"
python3 "$AUDITOR" "${args[@]}"
