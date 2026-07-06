#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_PREFIX="${MANALOOM_APP_AI_BRIDGE_AUDIT_OUT_PREFIX:-$ROOT_DIR/docs/hermes-analysis/master_optimizer_reports/app_ai_knowledge_bridge_audit_$STAMP}"

cd "$ROOT_DIR"
python3 docs/hermes-analysis/manaloom-knowledge/scripts/app_ai_knowledge_bridge_audit.py \
  --out-prefix "$OUT_PREFIX"
