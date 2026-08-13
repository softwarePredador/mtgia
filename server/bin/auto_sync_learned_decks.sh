#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PYTHON_BIN="${PYTHON_BIN:-python3}"

for arg in "$@"; do
  if [ "$arg" = "--apply" ]; then
    echo "BLOCKED_DCK_P0_05: automatic learned-deck PostgreSQL sync is disabled." >&2
    exit 2
  fi
done

exec "$PYTHON_BIN" "$SCRIPT_DIR/auto_sync_learned_decks.py" --dry-run "$@"
