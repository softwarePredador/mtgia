#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  echo "usage: $0 <adb-device-id> <flutter-runtime-log> <output.png>" >&2
  exit 2
fi

DEVICE_ID="$1"
RUNTIME_LOG="$2"
OUTPUT_FILE="$3"
MARKER="${MANALOOM_NATIVE_CAPTURE_MARKER:-NATIVE_SCREENSHOT_READY life_counter_initial}"
TIMEOUT_SECONDS="${MANALOOM_NATIVE_CAPTURE_TIMEOUT_SECONDS:-300}"
SETTLE_SECONDS="${MANALOOM_NATIVE_CAPTURE_SETTLE_SECONDS:-3}"

command -v adb >/dev/null 2>&1 || {
  echo "adb is required for the Android platform-view capture" >&2
  exit 2
}
command -v python3 >/dev/null 2>&1 || {
  echo "python3 is required to validate the PNG dimensions" >&2
  exit 2
}
[[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] && [[ "$TIMEOUT_SECONDS" -gt 0 ]] || {
  echo "MANALOOM_NATIVE_CAPTURE_TIMEOUT_SECONDS must be a positive integer" >&2
  exit 2
}
[[ "$SETTLE_SECONDS" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
  echo "MANALOOM_NATIVE_CAPTURE_SETTLE_SECONDS must be a non-negative number" >&2
  exit 2
}

mkdir -p "$(dirname -- "$OUTPUT_FILE")"
temporary_png="$(mktemp "${TMPDIR:-/tmp}/manaloom_native_capture.XXXXXX.png")"

cleanup() {
  rm -f "$temporary_png"
}
trap cleanup EXIT INT TERM

deadline=$((SECONDS + TIMEOUT_SECONDS))
while ! grep -Fq "$MARKER" "$RUNTIME_LOG" 2>/dev/null; do
  if (( SECONDS >= deadline )); then
    echo "timed out waiting for: $MARKER" >&2
    exit 1
  fi
  sleep 0.05
done

sleep "$SETTLE_SECONDS"
adb -s "$DEVICE_ID" get-state | grep -qx device || {
  echo "Android device is not ready: $DEVICE_ID" >&2
  exit 1
}
adb -s "$DEVICE_ID" exec-out screencap -p >"$temporary_png"

read -r width height byte_count < <(
  python3 - "$temporary_png" <<'PY'
import os
import struct
import sys

path = sys.argv[1]
with open(path, "rb") as image:
    header = image.read(24)
if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
    raise SystemExit("native capture is not a PNG")
width, height = struct.unpack(">II", header[16:24])
print(width, height, os.path.getsize(path))
PY
)

if [[ "$width" -le "$height" ]]; then
  echo "Life Counter native capture is not landscape: ${width}x${height}" >&2
  exit 1
fi
if [[ "$byte_count" -lt 50000 ]]; then
  echo "Life Counter native capture is suspiciously small: $byte_count bytes" >&2
  exit 1
fi

mv "$temporary_png" "$OUTPUT_FILE"
trap - EXIT INT TERM
printf 'native_capture=%s\n' "$OUTPUT_FILE"
printf 'dimensions=%sx%s\n' "$width" "$height"
printf 'bytes=%s\n' "$byte_count"
