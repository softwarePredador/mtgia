#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "smoke Sentry mobile em device"
readonly LIVE_MUTATION_APPROVED=1
: "$LIVE_MUTATION_APPROVED"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo de ambiente nao encontrado: $ENV_FILE" >&2
  exit 1
fi

CALLER_FLUTTER_BIN="${MANALOOM_FLUTTER_BIN_RESOLVED:-}"
CALLER_EXPECTED_RELEASE="${MANALOOM_EXPECTED_SENTRY_RELEASE:-}"
CALLER_INSTALL_SESSION="${MANALOOM_OBSERVABILITY_SESSION_ID:-}"

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  API_BASE_URL SENTRY_DSN SENTRY_ENVIRONMENT SENTRY_MOBILE_DSN \
  SENTRY_TRACES_SAMPLE_RATE

MANALOOM_FLUTTER_BIN_RESOLVED="$CALLER_FLUTTER_BIN"
MANALOOM_EXPECTED_SENTRY_RELEASE="$CALLER_EXPECTED_RELEASE"
MANALOOM_OBSERVABILITY_SESSION_ID="$CALLER_INSTALL_SESSION"
readonly MANALOOM_FLUTTER_BIN_RESOLVED
readonly MANALOOM_EXPECTED_SENTRY_RELEASE
readonly MANALOOM_OBSERVABILITY_SESSION_ID
export MANALOOM_FLUTTER_BIN_RESOLVED
export MANALOOM_EXPECTED_SENTRY_RELEASE
export MANALOOM_OBSERVABILITY_SESSION_ID

: "${MANALOOM_FLUTTER_BIN_RESOLVED:?MANALOOM_FLUTTER_BIN_RESOLVED ausente}"
: "${MANALOOM_EXPECTED_SENTRY_RELEASE:?MANALOOM_EXPECTED_SENTRY_RELEASE ausente}"
: "${MANALOOM_OBSERVABILITY_SESSION_ID:?MANALOOM_OBSERVABILITY_SESSION_ID ausente}"
if [[ ! -f "$MANALOOM_FLUTTER_BIN_RESOLVED" || ! -x "$MANALOOM_FLUTTER_BIN_RESOLVED" ]]; then
  echo "Flutter validado ausente: $MANALOOM_FLUTTER_BIN_RESOLVED" >&2
  exit 2
fi

timeout_seconds="${MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS:-120}"
tmp_output="$(mktemp)"
trap 'rm -f "$tmp_output"' EXIT

cd "$ROOT_DIR/app"

"$MANALOOM_FLUTTER_BIN_RESOLVED" test integration_test/mobile_sentry_smoke_test.dart \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8080}" \
  --dart-define=SENTRY_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}" \
  --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-development}" \
  --dart-define=SENTRY_RELEASE="$MANALOOM_EXPECTED_SENTRY_RELEASE" \
  --dart-define=MANALOOM_OBSERVABILITY_SESSION_ID="$MANALOOM_OBSERVABILITY_SESSION_ID" \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE="${SENTRY_TRACES_SAMPLE_RATE:-0.0}" \
  --no-pub \
  "$@" \
  >"$tmp_output" 2>&1 &

test_pid=$!
test_pgid="$(ps -o pgid= "$test_pid" | tr -d ' ' || true)"
start_ts="$(date +%s)"

while kill -0 "$test_pid" 2>/dev/null; do
  if grep -q 'SENTRY_MOBILE_EVENT_ID=' "$tmp_output"; then
    break
  fi

  now_ts="$(date +%s)"
  elapsed="$((now_ts - start_ts))"
  if (( elapsed >= timeout_seconds )); then
    if [[ -n "$test_pgid" ]]; then
      kill -TERM -- "-$test_pgid" 2>/dev/null || true
      sleep 2
      kill -KILL -- "-$test_pgid" 2>/dev/null || true
    fi
    kill "$test_pid" 2>/dev/null || true
    wait "$test_pid" 2>/dev/null || true
    cat "$tmp_output"
    echo "SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1" >&2
    echo "SENTRY_MOBILE_TIMEOUT_SECONDS=$timeout_seconds" >&2
    echo "Build/test nao concluiu dentro do tempo esperado; validar toolchain/device." >&2
    exit 124
  fi

  sleep 2
done

set +e
wait "$test_pid"
test_exit_code=$?
set -e
cat "$tmp_output"
if [[ "$test_exit_code" -ne 0 ]]; then
  exit "$test_exit_code"
fi
