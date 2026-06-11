#!/usr/bin/env bash
set -euo pipefail

REPO="${MANALOOM_WORKSPACE:-/opt/data/workspace/mtgia}"
STATE_DIR="${HERMES_STATE_DIR:-/opt/data/.hermes/data/manaloom}"
STATE_FILE="$STATE_DIR/master_last_sha"

mkdir -p "$STATE_DIR"
cd "$REPO"

git config --global --add safe.directory "$REPO" >/dev/null 2>&1 || true
git fetch --quiet --prune origin master codex/hermes-analysis-docs

current_sha="$(git rev-parse origin/master)"
if [[ ! -f "$STATE_FILE" ]]; then
  printf "%s" "$current_sha" > "$STATE_FILE"
  exit 0
fi

previous_sha="$(cat "$STATE_FILE" 2>/dev/null || true)"
if [[ "$current_sha" != "$previous_sha" ]]; then
  printf "%s" "$current_sha" > "$STATE_FILE"
  echo "ManaLoom origin/master changed: ${previous_sha:-unknown} -> $current_sha"
  echo "Run report-only validation: manaloom-hermes-report-only.sh $current_sha"
fi
