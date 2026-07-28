#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts"
AUDITOR="$SCRIPTS_DIR/xmage_pin_transition_audit.py"
OUTPUT_PREFIX="${MANALOOM_XMAGE_PIN_TRANSITION_OUT:-/tmp/manaloom_xmage_pin_transition_audit}"

cd "$SCRIPTS_DIR"
PYTHONWARNINGS=error::ResourceWarning python3 -m unittest \
  test_xmage_pin_transition_audit.py \
  test_xmage_test_scenario_miner.py

cd "$ROOT_DIR"
python3 "$AUDITOR" --output-prefix "$OUTPUT_PREFIX" "$@"
