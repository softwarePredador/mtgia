#!/usr/bin/env bash
# Wrapper para auto-sync de decks aprendidos Hermes -> PG.
# Regras: Lorehold → PULA; outros → automatico.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "${SCRIPT_DIR}/auto_sync_learned_decks.py" "$@"
