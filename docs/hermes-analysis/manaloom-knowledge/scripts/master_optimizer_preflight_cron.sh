#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_REPO:-/opt/data/workspace/mtgia}"
SCRIPT_DIR="$REPO/docs/hermes-analysis/manaloom-knowledge/scripts"
REPORT_DIR="$REPO/docs/hermes-analysis/master_optimizer_reports"
ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-/opt/data/artifacts/hermes_master_optimizer}"
SECRET_ENV="${MANALOOM_POSTGRES_ENV:-/opt/data/secrets/manaloom-postgres.env}"
DECK_ID="${MANALOOM_OPTIMIZER_DECK_ID:-6}"
LOREHOLD_CANONICAL_OVERRIDE="${MANALOOM_LOREHOLD_CANONICAL_OVERRIDE:-1}"

mkdir -p "$REPORT_DIR" "$ARTIFACT_DIR"

cd "$REPO"
git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true

# Operational optimizer code must run from canonical master. Memory/report
# crons may use codex/hermes-analysis-docs, but preflight must not execute stale
# branch docs scripts.
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

meta_decks_log="$ARTIFACT_DIR/meta_decks_sync_preflight_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/sync_pg_meta_decks_to_hermes.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --limit "${MANALOOM_META_DECK_SYNC_LIMIT:-120}" \
  --min-cards "${MANALOOM_META_DECK_SYNC_MIN_CARDS:-80}" \
  --apply | tee "$meta_decks_log"

target_deck_log="$ARTIFACT_DIR/target_deck_sync_preflight_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/sync_pg_target_deck_to_hermes.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --target-deck-id "$DECK_ID" \
  --apply | tee "$target_deck_log"

if [[ "$DECK_ID" == "6" && "$LOREHOLD_CANONICAL_OVERRIDE" == "1" ]]; then
  canonical_log="$ARTIFACT_DIR/lorehold_canonical_preflight_$(date -u +%Y%m%d_%H%M%S).log"
  python3 "$SCRIPT_DIR/lorehold_canonical_deck_snapshot.py" \
    --db "$SCRIPT_DIR/knowledge.db" \
    --apply-local-sqlite | tee "$canonical_log"
fi

sync_report="$ARTIFACT_DIR/card_oracle_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_pg_card_metadata_to_hermes.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --report "$sync_report"

battle_rules_pg_report="$ARTIFACT_DIR/card_battle_rules_pg_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --apply-pg \
  --report "$battle_rules_pg_report"

battle_rules_report="$ARTIFACT_DIR/battle_card_rules_cache_sync_$(date -u +%Y%m%d_%H%M%S).json"
python3 "$SCRIPT_DIR/sync_battle_card_rules_pg.py" \
  --sqlite-db "$SCRIPT_DIR/knowledge.db" \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report "$battle_rules_report"

preflight_log="$ARTIFACT_DIR/master_optimizer_preflight_$(date -u +%Y%m%d_%H%M%S).log"
python3 "$SCRIPT_DIR/master_optimizer_loop.py" \
  --db "$SCRIPT_DIR/knowledge.db" \
  --preflight \
  --report | tee "$preflight_log"

latest_report="$(ls -1t "$REPORT_DIR"/master_optimizer_preflight_*.md 2>/dev/null | head -1 || true)"
if [[ -n "$latest_report" ]]; then
  cp "$latest_report" "$ARTIFACT_DIR/latest_master_optimizer_preflight.md"
fi

echo "master_optimizer_preflight=ok"
echo "meta_decks_log=$meta_decks_log"
echo "target_deck_log=$target_deck_log"
echo "sync_report=$sync_report"
echo "battle_rules_pg_report=$battle_rules_pg_report"
echo "battle_rules_report=$battle_rules_report"
echo "preflight_log=$preflight_log"
