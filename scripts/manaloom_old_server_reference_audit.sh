#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_PREFIX="${MANALOOM_OLD_SERVER_AUDIT_OUT_PREFIX:-/tmp/manaloom_old_server_reference_audit_$STAMP}"

cd "$ROOT_DIR"
python3 docs/hermes-analysis/manaloom-knowledge/scripts/old_server_reference_audit.py \
  --out-prefix "$OUT_PREFIX"
