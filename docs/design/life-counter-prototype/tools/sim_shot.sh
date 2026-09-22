#!/bin/bash
# Capture the booted simulator, turn it upright (landscape), keep the full file as proof and a small copy for review.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; OUT="$ROOT/proofs/ios/$1.png"
xcrun simctl io booted screenshot "$OUT" >/dev/null 2>&1
W=$(sips -g pixelWidth "$OUT" | tail -1 | awk '{print $2}'); H=$(sips -g pixelHeight "$OUT" | tail -1 | awk '{print $2}')
if [ "$H" -gt "$W" ]; then sips -r 270 "$OUT" >/dev/null 2>&1; fi
sips -Z 1000 "$OUT" --out "$ROOT/_view.png" >/dev/null 2>&1
echo "saved $1"
