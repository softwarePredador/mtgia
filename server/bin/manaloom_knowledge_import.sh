#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="${MANALOOM_REPO:-$(CDPATH= cd -- "$SERVER_BIN_DIR/../.." && pwd)}"
SCRIPT_PATH="${MANALOOM_KNOWLEDGE_IMPORT_RUNNER:-$REPO_ROOT/docs/hermes-analysis/manaloom-knowledge/scripts/run_import.py}"
ARTIFACT_DIR="${MANALOOM_KNOWLEDGE_IMPORT_ARTIFACT_DIR:-${MANALOOM_OPS_ARTIFACT_DIR:-$REPO_ROOT/server/test/artifacts}/knowledge_import}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-${MTGIA_ENV_FILE:-$REPO_ROOT/server/.env}}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$ARTIFACT_DIR"

if [[ -f "$SECRET_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRET_ENV"
  set +a
fi

export PGHOST="${PGHOST:-${DB_HOST:-}}"
export PGPORT="${PGPORT:-${DB_PORT:-5432}}"
export PGDATABASE="${PGDATABASE:-${DB_NAME:-}}"
export PGUSER="${PGUSER:-${DB_USER:-}}"
export PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}"
export MANALOOM_REPO="$REPO_ROOT"
export MANALOOM_IMPORT_APPLY="${MANALOOM_IMPORT_APPLY:-1}"

log_path="$ARTIFACT_DIR/knowledge_import_$(date -u +%Y%m%d_%H%M%S).log"
"$PYTHON_BIN" "$SCRIPT_PATH" | tee "$log_path"
cp "$log_path" "$ARTIFACT_DIR/latest_knowledge_import.log"

echo "manaloom_knowledge_import=ok"
echo "knowledge_import_log=$log_path"
