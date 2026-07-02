#!/usr/bin/env bash
set -euo pipefail

ROOT="${MTGIA_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

SETS="${MANALOOM_SYNC_LEGALITIES_SETS:-}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

args=(
  "server/bin/sync_card_legalities_from_scryfall.py"
  "--sets" "$SETS"
)

if [[ "${MANALOOM_SYNC_CARD_LEGALITIES_APPLY:-0}" == "1" ]]; then
  args+=("--apply")
fi

if [[ -n "${MANALOOM_SYNC_CARD_LEGALITIES_LIMIT:-}" ]]; then
  args+=("--limit" "$MANALOOM_SYNC_CARD_LEGALITIES_LIMIT")
fi

if [[ -n "${MANALOOM_SYNC_CARD_LEGALITIES_OUTPUT_DIR:-}" ]]; then
  args+=("--output-dir" "$MANALOOM_SYNC_CARD_LEGALITIES_OUTPUT_DIR")
fi

exec "$PYTHON_BIN" "${args[@]}"
