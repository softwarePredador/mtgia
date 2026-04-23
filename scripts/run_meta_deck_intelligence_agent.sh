#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$ROOT_DIR/server/doc/META_DECK_INTELLIGENCE_AGENT_2026-04-23.md"

cd "$ROOT_DIR"
copilot --effort high -i "$(cat "$PROMPT_FILE")"
