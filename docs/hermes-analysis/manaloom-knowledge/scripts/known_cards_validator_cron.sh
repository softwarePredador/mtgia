#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
LOCK_FILE="${KC_VALIDATOR_LOCK:-/tmp/kc_validator.lock}"

mkdir -p "$ARTIFACT_DIR"

if [[ -f "$LOCK_FILE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if (( age < 7200 )); then
    echo "known_cards_validator=locked age_seconds=$age"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true
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

export MANALOOM_HERMES_SCRIPT_DIR="$SCRIPT_DIR"
export MANALOOM_KNOWLEDGE_DB="${MANALOOM_KNOWLEDGE_DB:-$SCRIPT_DIR/knowledge.db}"
export MANALOOM_KNOWN_CARDS_OUT="${MANALOOM_KNOWN_CARDS_OUT:-$SCRIPT_DIR/known_cards_generated.json}"

sync_report="$ARTIFACT_DIR/card_metadata_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --report "$sync_report"
cp "$sync_report" "$ARTIFACT_DIR/latest_card_metadata_sync.json"

log="$ARTIFACT_DIR/known_cards_validator_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/kc_validator.py" | tee "$log"
cp "$log" "$ARTIFACT_DIR/latest_known_cards_validator.log"

echo "known_cards_validator=ok"
echo "known_cards_validator_log=$log"
