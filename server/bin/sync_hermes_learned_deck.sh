#!/usr/bin/env bash
# Wrapper: exporta learned deck do SQLite Hermes e importa no PG via dart.
#
# Uso:
#   ./sync_hermes_learned_deck.sh [--commander <name>] [--learned-id <id>] [--apply]
#
# Sem --apply, faz apenas dry-run do export + anlise local.
# Com --apply, aplica no PG via dart run bin/commander_learned_deck.dart --apply.
#
# Requer:
#   - python3 no Hermes (para exportar do SQLite)
#   - dart no server (para importar no PG)
#   - .env com credenciais PG configuradas

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQLITE_DB="/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
EXPORT_SCRIPT="${SCRIPT_DIR}/export_hermes_learned_deck.py"
ARTIFACT_DIR="${SCRIPT_DIR}/../test/artifacts/hermes_sync"
TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
COMMANDER_FILTER=""
LEARNED_ID=""
APPLY=false
DRY_RUN=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --commander)
            COMMANDER_FILTER="$2"; shift 2 ;;
        --learned-id)
            LEARNED_ID="$2"; shift 2 ;;
        --apply)
            APPLY=true; DRY_RUN=false; shift ;;
        *)
            echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

mkdir -p "$ARTIFACT_DIR"

EXPORT_ARGS=(--db "$SQLITE_DB")
if [ -n "$LEARNED_ID" ]; then
    EXPORT_ARGS+=(--learned-id "$LEARNED_ID")
elif [ -n "$COMMANDER_FILTER" ]; then
    EXPORT_ARGS+=(--commander "$COMMANDER_FILTER")
fi

EXPORT_JSON="${ARTIFACT_DIR}/hermes_export_${TIMESTAMP}.json"
SUMMARY_JSON="${ARTIFACT_DIR}/hermes_sync_summary_${TIMESTAMP}.json"

echo "=== Exporting from Hermes SQLite ==="
python3 "$EXPORT_SCRIPT" "${EXPORT_ARGS[@]}" --out "$EXPORT_JSON"

echo "=== Card list preview ==="
head -5 "$EXPORT_JSON" 2>/dev/null || true
python3 -c "
import json
data=json.load(open('$EXPORT_JSON'))
print(f\"commander: {data.get('commander_name')}\")
print(f\"deck: {data.get('deck_name')}\")
print(f\"source_ref: {data.get('source_ref')}\")
print(f\"card_count: {data.get('card_count')}\")
print(f\"score: {data.get('score')}\")
"

echo ""
if $APPLY; then
    echo "=== Importing to PG (--apply) ==="
    dart run bin/commander_learned_deck.dart --input-json="$EXPORT_JSON" --apply --artifact-dir="$ARTIFACT_DIR"
    echo "{}" > "$SUMMARY_JSON"
    echo "Sync complete. Artifacts: $ARTIFACT_DIR"
else
    echo "=== Dry-run only (use --apply to import to PG) ==="
    dart run bin/commander_learned_deck.dart --input-json="$EXPORT_JSON" --dry-run --artifact-dir="$ARTIFACT_DIR"
    echo "{}" > "$SUMMARY_JSON"
    echo "Dry-run complete. Artifacts: $ARTIFACT_DIR"
fi
