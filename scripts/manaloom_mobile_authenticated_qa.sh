#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
API="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
DEVICE_ID="${MANALOOM_MOBILE_QA_DEVICE_ID:-}"
OUT_DIR="${MANALOOM_MOBILE_QA_OUT_DIR:-$ROOT_DIR/docs/qa/runtime}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$OUT_DIR/mobile-authenticated-qa-$STAMP"
LOG_FILE="$RUN_DIR/flutter_test.log"
SUMMARY_FILE="$RUN_DIR/summary.json"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool flutter
require_tool jq
require_tool ssh

mkdir -p "$RUN_DIR"

if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="$(
    flutter devices --machine |
      jq -r '.[] | select(.targetPlatform == "ios" and .emulator == true and (.name | test("iPhone"))) | .id' |
      head -n 1
  )"
fi

if [ -z "$DEVICE_ID" ]; then
  echo "nenhum simulador iOS encontrado; defina MANALOOM_MOBILE_QA_DEVICE_ID" >&2
  exit 2
fi

cleanup_user() {
  local email="$1"
  if [ -z "$email" ]; then
    return 0
  fi
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec -i \"\$cid\" psql -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1" <<SQL >/dev/null
WITH target AS (
  SELECT id FROM users WHERE email = '$email'
),
deleted_ai AS (
  DELETE FROM ai_logs USING target WHERE ai_logs.user_id = target.id RETURNING 1
),
deleted_users AS (
  DELETE FROM users WHERE id IN (SELECT id FROM target) RETURNING 1
)
SELECT
  (SELECT COUNT(*) FROM deleted_ai) AS deleted_ai_logs,
  (SELECT COUNT(*) FROM deleted_users) AS deleted_users;
SQL
}

status="pass"
set +e
(
  cd "$ROOT_DIR/app"
  flutter test integration_test/manaloom_authenticated_mobile_qa_test.dart \
    -d "$DEVICE_ID" \
    --no-version-check \
    --dart-define=API_BASE_URL="$API" \
    --dart-define=DISABLE_FIREBASE_STARTUP=true \
    --dart-define=DISABLE_PUSH_INIT=true \
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
    --reporter expanded
) >"$LOG_FILE" 2>&1
test_code="$?"
set -e

qa_email="$(grep -Eo 'MOBILE_QA_USER_EMAIL=[^[:space:]]+' "$LOG_FILE" | tail -n 1 | cut -d= -f2- || true)"
cleanup_status="skipped"
if [ -n "$qa_email" ]; then
  if cleanup_user "$qa_email"; then
    cleanup_status="ok"
  else
    cleanup_status="failed"
    status="fail"
  fi
fi

if [ "$test_code" -ne 0 ]; then
  status="fail"
fi

jq -n \
  --arg status "$status" \
  --arg api "$API" \
  --arg device_id "$DEVICE_ID" \
  --arg run_dir "$RUN_DIR" \
  --arg log_file "$LOG_FILE" \
  --arg cleanup_status "$cleanup_status" \
  --argjson test_exit_code "$test_code" \
  '{
    status: $status,
    api: $api,
    device_id: $device_id,
    test_exit_code: $test_exit_code,
    cleanup_status: $cleanup_status,
    artifacts_dir: $run_dir,
    log_file: $log_file
  }' | tee "$SUMMARY_FILE"

if [ "$status" != "pass" ]; then
  exit 1
fi
