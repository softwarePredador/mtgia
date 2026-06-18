#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
LOCK_FILE="${MANALOOM_KNOWN_CARDS_GENERATOR_LOCK:-/tmp/manaloom-known-cards-generator.lock}"

mkdir -p "$ARTIFACT_DIR"

if [[ -f "$LOCK_FILE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if (( age < 7200 )); then
    echo "known_cards_generator=locked age_seconds=$age"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true
git fetch --quiet origin master
git checkout master >/dev/null
git pull --ff-only origin master >/dev/null

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
export MANALOOM_CANONICAL_KNOWN_CARDS_JSON="${MANALOOM_CANONICAL_KNOWN_CARDS_JSON:-$SCRIPT_DIR/known_cards_canonical_snapshot.json}"

sync_report="$ARTIFACT_DIR/card_metadata_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --report "$sync_report"
cp "$sync_report" "$ARTIFACT_DIR/latest_card_metadata_sync.json"

battle_rules_report="$ARTIFACT_DIR/battle_card_rules_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$MANALOOM_KNOWLEDGE_DB" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --export-canonical-fallback-json "$MANALOOM_CANONICAL_KNOWN_CARDS_JSON" \
  --report "$battle_rules_report"
cp "$battle_rules_report" "$ARTIFACT_DIR/latest_battle_card_rules_cache_sync.json"

log="$ARTIFACT_DIR/known_cards_generator_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/generate_known_cards.py" | tee "$log"
cp "$log" "$ARTIFACT_DIR/latest_known_cards_generator.log"

echo "known_cards_generator=ok"
echo "battle_rules_report=$battle_rules_report"
echo "known_cards_log=$log"
