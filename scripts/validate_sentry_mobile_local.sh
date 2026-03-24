#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo de ambiente nao encontrado: $ENV_FILE" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

timeout_seconds="${MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS:-120}"
tmp_output="$(mktemp)"
trap 'rm -f "$tmp_output"' EXIT

cd "$ROOT_DIR/app"

flutter test integration_test/mobile_sentry_smoke_test.dart \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://evolution-cartinhas.8ktevp.easypanel.host}" \
  --dart-define=SENTRY_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}" \
  --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-development}" \
  --dart-define=SENTRY_RELEASE="${SENTRY_RELEASE:-manaloom@local}" \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE="${SENTRY_TRACES_SAMPLE_RATE:-0.0}" \
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
