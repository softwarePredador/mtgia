#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
OUTPUT="${MANALOOM_ENGINE_DELTA_OUTPUT:-/tmp/manaloom_external_engine_upstream_delta_audit.json}"

exec python3 \
  "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_upstream_delta_audit.py" \
  --json-output "$OUTPUT" \
  "$@"
