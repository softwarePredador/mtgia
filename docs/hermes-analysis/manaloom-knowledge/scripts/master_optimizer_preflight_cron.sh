#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
REPORT_DIR="$REPO/docs/hermes-analysis/master_optimizer_reports"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"

mkdir -p "$REPORT_DIR" "$ARTIFACT_DIR"

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true

# Keep code fresh when the workspace is clean enough; do not force-reset a dirty
# Hermes workspace because knowledge.db and cron reports are runtime artifacts.
git fetch --quiet origin codex/hermes-analysis-docs || true
git checkout codex/hermes-analysis-docs >/dev/null 2>&1 || true
git pull --ff-only origin codex/hermes-analysis-docs >/dev/null 2>&1 || true

if [[ -f "$SECRET_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRET_ENV"
  set +a
  export PGHOST="${PGHOST:-${DB_HOST:-}}"
  export PGPORT="${PGPORT:-${DB_PORT:-5432}}"
  export PGDATABASE="${PGDATABASE:-${DB_NAME:-}}"
  export PGUSER="${PGUSER:-${DB_USER:-}}"
  export PGPASSWORD="${PGPASSWORD:-${DB_PASS:-}}"
fi

sync_report="$ARTIFACT_DIR/card_oracle_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --report "$sync_report"

preflight_log="$ARTIFACT_DIR/master_optimizer_preflight_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/master_optimizer_loop.py" --preflight --report | tee "$preflight_log"

latest_report="$(ls -1t "$REPORT_DIR"/master_optimizer_preflight_*.md 2>/dev/null | head -1 || true)"
if [[ -n "$latest_report" ]]; then
  cp "$latest_report" "$ARTIFACT_DIR/latest_master_optimizer_preflight.md"
fi

echo "master_optimizer_preflight=ok"
echo "sync_report=$sync_report"
echo "preflight_log=$preflight_log"
