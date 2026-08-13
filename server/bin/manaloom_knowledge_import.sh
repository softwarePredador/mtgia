#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH='' cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
SCRIPT_PATH="${MANALOOM_KNOWLEDGE_IMPORT_RUNNER:-$REPO_ROOT/docs/hermes-analysis/manaloom-knowledge/scripts/run_import.py}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

usage() {
  cat <<'EOF'
Usage: ./server/bin/manaloom_knowledge_import.sh [--dry-run|--report-only]

Scans the versioned Markdown/Hermes knowledge corpus and prints a local,
read-only candidate report. PostgreSQL import is intentionally disabled until
BT-AI-014 defines versioned schema, provenance, idempotency and promotion gates.

--apply is recognized only to fail closed. MANALOOM_IMPORT_APPLY=1 is treated
the same way.
EOF
}

apply_requested=0
case "${MANALOOM_IMPORT_APPLY:-0}" in
  0|false|FALSE|no|NO|'') ;;
  1|true|TRUE|yes|YES) apply_requested=1 ;;
  *)
    echo "BLOCKED_BT_AI_014: MANALOOM_IMPORT_APPLY must be 0 or 1; knowledge import remains report-only." >&2
    exit 2
    ;;
esac

while (($# > 0)); do
  case "$1" in
    --dry-run|--report-only)
      ;;
    --apply)
      apply_requested=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ((apply_requested == 1)); then
  echo "BLOCKED_BT_AI_014: Markdown/Hermes -> PostgreSQL apply is disabled." >&2
  echo "A future apply path must use scripts/lib/manaloom_mutation_guard.sh and require versioned schema, provenance, idempotency and an approved promotion receipt." >&2
  exit 2
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Knowledge import auditor not found: $SCRIPT_PATH" >&2
  exit 2
fi

# The operations daemon already captures stdout. Do not load server/.env, pass
# PostgreSQL credentials, or create a second mutable artifact tree here. This
# invocation is a local corpus audit, not a database dry-run.
env \
  -u PGHOST \
  -u PGPORT \
  -u PGDATABASE \
  -u PGUSER \
  -u PGPASSWORD \
  -u DB_HOST \
  -u DB_PORT \
  -u DB_NAME \
  -u DB_USER \
  -u DB_PASS \
  MANALOOM_REPO="$REPO_ROOT" \
  MANALOOM_IMPORT_APPLY=0 \
  "$PYTHON_BIN" "$SCRIPT_PATH" --report-only

echo "manaloom_knowledge_import=ok"
echo "knowledge_import_mode=report_only"
echo "knowledge_import_postgresql=not_contacted"
