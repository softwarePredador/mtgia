#!/bin/bash
# Copy the wrapped prototype into the app container and relaunch the host (no rebuild needed).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/tools/wrap.py" >/dev/null
C="$(xcrun simctl get_app_container booted com.mtgia.mtgApp data)"
mkdir -p "$C/Documents"
cp "$ROOT/serve/index.html" "$C/Documents/mesa.html"
xcrun simctl terminate booted com.mtgia.mtgApp >/dev/null 2>&1 || true
# "push_sim.sh fresh" also throws away what the web view remembered, for a first-run proof
if [ "${1:-}" = "fresh" ]; then rm -rf "$C/Library/WebKit" "$C/Library/HTTPStorages"; fi
xcrun simctl launch booted com.mtgia.mtgApp >/dev/null
echo "pushed $(wc -c < "$C/Documents/mesa.html") bytes and relaunched"
