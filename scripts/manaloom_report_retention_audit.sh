#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT_PREFIX="${MANALOOM_REPORT_RETENTION_AUDIT_OUT_PREFIX:-/tmp/manaloom_report_retention_audit}"

cd "$ROOT_DIR"
python3 docs/hermes-analysis/manaloom-knowledge/scripts/report_retention_audit.py \
  --fail-on-ignored-local \
  --out-prefix "$OUT_PREFIX"
