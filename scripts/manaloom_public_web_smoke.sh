#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
WEB_DIR="$ROOT_DIR/web-public"
# shellcheck source=scripts/lib/manaloom_public_web_surface_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_public_web_surface_contract.sh"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${STAMP}_$$_${RANDOM}${RANDOM}"
RUN_DIR="${MANALOOM_PUBLIC_WEB_SMOKE_ROOT:-/tmp/manaloom_public_web_smoke}/$RUN_ID"
WORK_DIR="$RUN_DIR/workspace"
SERVER_DIR="$RUN_DIR/server"
SERVER_LOG="$RUN_DIR/server.log"
PORT="${MANALOOM_PUBLIC_WEB_SMOKE_PORT:-}"
SERVER_PID=""
FIXTURE_API_PORT=""
FIXTURE_API_PID=""
FIXTURE_API_LOG="$RUN_DIR/fixture-api.log"
REPORT_FIXTURE_ID="${MANALOOM_PUBLIC_WEB_REPORT_FIXTURE_ID:-public-web-smoke-report}"

stop_process() {
  local pid="$1"
  local label="$2"

  if [[ -z "$pid" ]]; then
    return 0
  fi
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill -TERM "$pid" >/dev/null 2>&1 || true
    for ((attempt = 1; attempt <= 50; attempt++)); do
      if ! kill -0 "$pid" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    if kill -0 "$pid" >/dev/null 2>&1; then
      echo "$label did not stop after SIGTERM; forcing cleanup." >&2
      kill -KILL "$pid" >/dev/null 2>&1 || true
      wait "$pid" 2>/dev/null || true
      return 1
    fi
  fi
  wait "$pid" 2>/dev/null || true
}

cleanup() {
  local status="$?"
  trap - EXIT INT TERM
  if ! stop_process "$SERVER_PID" "Public web server" &&
     [[ "$status" -eq 0 ]]; then
    status=1
  fi
  if ! stop_process "$FIXTURE_API_PID" "Public report fixture API" &&
     [[ "$status" -eq 0 ]]; then
    status=1
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
manaloom_public_web_validate_report_fixture_id "$REPORT_FIXTURE_ID"

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

FIXTURE_API_PORT="$(python3 - "$PORT" <<'PY'
import socket
import sys

excluded = int(sys.argv[1])
while True:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        candidate = sock.getsockname()[1]
    if candidate != excluded:
        print(candidate)
        break
PY
)"

python3 - "$FIXTURE_API_PORT" "$REPORT_FIXTURE_ID" \
  >"$FIXTURE_API_LOG" 2>&1 <<'PY' &
import json
import signal
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import quote, urlparse

port = int(sys.argv[1])
report_id = sys.argv[2]
report_path = f"/reports/{quote(report_id, safe='')}"
signal.signal(signal.SIGTERM, lambda *_args: sys.exit(0))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if urlparse(self.path).path != report_path:
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        body = json.dumps(
            {
                "id": report_id,
                "title": "Public Web Smoke Report",
                "description": "Local fixture for the explicitly shared report surface.",
                "payload": {
                    "type": "deck_snapshot",
                    "deck_name": "Smoke Deck",
                    "stats": {"total_cards": 100},
                },
            }
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format, *_args):
        return


ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
PY
FIXTURE_API_PID=$!
FIXTURE_API_BASE_URL="http://127.0.0.1:$FIXTURE_API_PORT"
for ((attempt = 1; attempt <= 40; attempt++)); do
  if curl --silent --show-error --fail --max-time 1 \
      "$FIXTURE_API_BASE_URL/reports/$REPORT_FIXTURE_ID" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$FIXTURE_API_PID" >/dev/null 2>&1; then
    echo "Public report fixture API exited before readiness." >&2
    cat "$FIXTURE_API_LOG" >&2
    exit 1
  fi
  sleep 0.1
done
if ! curl --silent --show-error --fail --max-time 2 \
    "$FIXTURE_API_BASE_URL/reports/$REPORT_FIXTURE_ID" >/dev/null; then
  echo "Public report fixture API did not become ready." >&2
  cat "$FIXTURE_API_LOG" >&2
  exit 1
fi

cd "$WORK_DIR"
npm ci --no-fund --no-audit
npm run lint
NEXT_PUBLIC_MANALOOM_API_BASE_URL="$FIXTURE_API_BASE_URL" npm run build
# The standalone artifact contains production dependencies only. Lint tooling
# is still installed and executed above, but it is not shipped in the image.
npm audit --omit=dev --audit-level=moderate

mkdir -p "$SERVER_DIR/.next"
cp -R .next/standalone/. "$SERVER_DIR/"
cp -R .next/static "$SERVER_DIR/.next/static"
cp -R public "$SERVER_DIR/public"

(
  cd "$SERVER_DIR"
  # Replace the helper shell with Node so SERVER_PID always identifies the
  # actual listener. Killing only the helper used to orphan next-server after
  # an otherwise successful smoke run.
  exec env HOSTNAME=127.0.0.1 PORT="$PORT" \
    NEXT_PUBLIC_MANALOOM_API_BASE_URL="$FIXTURE_API_BASE_URL" node server.js
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

while IFS= read -r route; do
  slug="$(printf '%s' "$route" | tr '/?' '__')"
  status="$(curl --silent --show-error --max-time 15 \
    --output "$RUN_DIR/${slug:-root}.body" \
    --write-out '%{http_code}' \
    "$BASE_URL$route")"
  if [[ "$status" != "200" ]]; then
    echo "Unexpected HTTP $status for $route" >&2
    exit 1
  fi
done < <(manaloom_public_web_required_routes)

while IFS= read -r route; do
  slug="$(printf '%s' "$route" | tr '/?' '__')"
  status="$(curl --silent --show-error --max-time 15 \
    --dump-header "$RUN_DIR/${slug}.headers" \
    --output "$RUN_DIR/${slug}.body" \
    --write-out '%{http_code}' \
    "$BASE_URL$route")"
  location="$(awk '
    tolower($1) == "location:" {
      $1 = ""
      sub(/^[[:space:]]+/, "")
      sub(/\r$/, "")
      print
      exit
    }
  ' "$RUN_DIR/${slug}.headers")"
  manaloom_public_web_assert_removed_response \
    "$route" "$status" "$location" "$BASE_URL"
done < <(manaloom_public_web_removed_routes)

REPORT_ROUTE="/reports/$REPORT_FIXTURE_ID"
REPORT_STATUS="$(curl --silent --show-error --max-time 15 \
  --output "$RUN_DIR/report-fixture.body" \
  --write-out '%{http_code}' \
  "$BASE_URL$REPORT_ROUTE")"
if [[ "$REPORT_STATUS" != "200" ]] ||
   ! grep -Fq 'Public Web Smoke Report' "$RUN_DIR/report-fixture.body"; then
  echo "Explicitly shared report fixture failed: HTTP $REPORT_STATUS" >&2
  exit 1
fi

MISSING_REPORT_ROUTE="/reports/public-web-smoke-missing"
MISSING_REPORT_STATUS="$(curl --silent --show-error --max-time 15 \
  --dump-header "$RUN_DIR/report-missing.headers" \
  --output "$RUN_DIR/report-missing.body" \
  --write-out '%{http_code}' \
  "$BASE_URL$MISSING_REPORT_ROUTE")"
if [[ "$MISSING_REPORT_STATUS" != "404" ]] ||
   grep -Eqi '^location:' "$RUN_DIR/report-missing.headers"; then
  echo "Missing shared report did not fail closed: HTTP $MISSING_REPORT_STATUS" >&2
  exit 1
fi

curl --silent --show-error --fail --max-time 15 \
  --dump-header "$RUN_DIR/root.headers" \
  --output "$RUN_DIR/root.body" \
  "$BASE_URL/"

grep -Fq 'BrewTact' "$RUN_DIR/root.body"
if grep -Fq 'ManaLoom' "$RUN_DIR/root.body"; then
  echo "Legacy public brand is still visible on the landing page." >&2
  exit 1
fi
manaloom_public_web_assert_free_beta_files \
  "$RUN_DIR/root.body" "$RUN_DIR/_pricing.body"
manaloom_public_web_assert_sitemap_file "$RUN_DIR/_sitemap.xml.body"
grep -Eqi '^x-content-type-options:[[:space:]]*nosniff' "$RUN_DIR/root.headers"
grep -Eqi '^x-frame-options:[[:space:]]*SAMEORIGIN' "$RUN_DIR/root.headers"
grep -Eqi '^referrer-policy:[[:space:]]*strict-origin-when-cross-origin' "$RUN_DIR/root.headers"
grep -Eqi '^permissions-policy:' "$RUN_DIR/root.headers"
grep -Eqi '^strict-transport-security:' "$RUN_DIR/root.headers"

if grep -Eqi '^x-powered-by:' "$RUN_DIR/root.headers"; then
  echo "Next.js implementation header is exposed." >&2
  exit 1
fi

for rendered_access_surface in \
  "$RUN_DIR/root.body" \
  "$RUN_DIR/_pricing.body" \
  "$RUN_DIR/report-fixture.body"; do
  grep -Fq 'Acesso ainda não liberado' "$rendered_access_surface"
  if grep -Eqi "href=[\"']/app([/#?\"']|[[:space:]])" \
      "$rendered_access_surface"; then
    echo "Public web rendered an actionable /app link while access is disabled." >&2
    exit 1
  fi
done

echo "Public web smoke passed. Evidence: $RUN_DIR"
