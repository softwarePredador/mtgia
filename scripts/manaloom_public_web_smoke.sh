#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
WEB_DIR="$ROOT_DIR/web-public"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${STAMP}_$$_${RANDOM}${RANDOM}"
RUN_DIR="${MANALOOM_PUBLIC_WEB_SMOKE_ROOT:-/tmp/manaloom_public_web_smoke}/$RUN_ID"
WORK_DIR="$RUN_DIR/workspace"
SERVER_DIR="$RUN_DIR/server"
SERVER_LOG="$RUN_DIR/server.log"
PORT="${MANALOOM_PUBLIC_WEB_SMOKE_PORT:-}"
SERVER_PID=""

cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill -TERM "$SERVER_PID" >/dev/null 2>&1 || true
    for ((attempt = 1; attempt <= 50; attempt++)); do
      if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
      echo "Public web server did not stop after SIGTERM; forcing cleanup." >&2
      kill -KILL "$SERVER_PID" >/dev/null 2>&1 || true
      if [[ "$status" -eq 0 ]]; then
        status=1
      fi
    fi
  fi
  if [[ -n "$SERVER_PID" ]]; then
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$SERVER_DIR" "$WORK_DIR"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for command_name in npm node curl python3; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing command: $command_name" >&2
    exit 1
  fi
done

if ! node -e '
  const [major, minor] = process.versions.node.split(".").map(Number);
  process.exit(
    major >= 24 || major === 22 && minor >= 13 || major === 20 && minor >= 19
      ? 0
      : 1,
  );
'; then
  echo "Unsupported Node $(node --version): use ^20.19, ^22.13 or >=24." >&2
  exit 2
fi

mkdir -p "$RUN_DIR"

python3 - "$WEB_DIR" "$WORK_DIR" <<'PY'
import shutil
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
shutil.copytree(
    source,
    destination,
    ignore=shutil.ignore_patterns("node_modules", ".next"),
)
PY

if [[ -z "$PORT" ]]; then
  PORT="$(python3 - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
fi

cd "$WORK_DIR"
npm ci --no-fund --no-audit
npm run lint
npm run build
npm audit --audit-level=moderate

mkdir -p "$SERVER_DIR/.next"
cp -R .next/standalone/. "$SERVER_DIR/"
cp -R .next/static "$SERVER_DIR/.next/static"
cp -R public "$SERVER_DIR/public"

(
  cd "$SERVER_DIR"
  # Replace the helper shell with Node so SERVER_PID always identifies the
  # actual listener. Killing only the helper used to orphan next-server after
  # an otherwise successful smoke run.
  exec env HOSTNAME=127.0.0.1 PORT="$PORT" node server.js
) >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

BASE_URL="http://127.0.0.1:$PORT"
for ((attempt = 1; attempt <= 60; attempt++)); do
  if curl --silent --show-error --fail --max-time 2 "$BASE_URL/" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "Public web server exited before readiness." >&2
    cat "$SERVER_LOG" >&2
    exit 1
  fi
  sleep 0.25
done

if ! curl --silent --show-error --fail --max-time 5 "$BASE_URL/" >/dev/null; then
  echo "Public web server did not become ready." >&2
  cat "$SERVER_LOG" >&2
  exit 1
fi

for route in / /pricing /marketplace /blog /legal/privacy /legal/terms /legal/disclaimer /robots.txt /sitemap.xml; do
  slug="$(printf '%s' "$route" | tr '/?' '__')"
  status="$(curl --silent --show-error --max-time 15 \
    --output "$RUN_DIR/${slug:-root}.body" \
    --write-out '%{http_code}' \
    "$BASE_URL$route")"
  if [[ "$status" != "200" ]]; then
    echo "Unexpected HTTP $status for $route" >&2
    exit 1
  fi
done

curl --silent --show-error --fail --max-time 15 \
  --dump-header "$RUN_DIR/root.headers" \
  --output "$RUN_DIR/root.body" \
  "$BASE_URL/"

grep -Fq 'ManaLoom' "$RUN_DIR/root.body"
grep -Eqi '^x-content-type-options:[[:space:]]*nosniff' "$RUN_DIR/root.headers"
grep -Eqi '^x-frame-options:[[:space:]]*SAMEORIGIN' "$RUN_DIR/root.headers"
grep -Eqi '^referrer-policy:[[:space:]]*strict-origin-when-cross-origin' "$RUN_DIR/root.headers"
grep -Eqi '^permissions-policy:' "$RUN_DIR/root.headers"
grep -Eqi '^strict-transport-security:' "$RUN_DIR/root.headers"

if grep -Eqi '^x-powered-by:' "$RUN_DIR/root.headers"; then
  echo "Next.js implementation header is exposed." >&2
  exit 1
fi

grep -Fq 'crossesIntoFlutterApp' "$WORK_DIR/src/components/ui.tsx"
grep -Fq '<a href={href}' "$WORK_DIR/src/components/ui.tsx"

echo "Public web smoke passed. Evidence: $RUN_DIR"
