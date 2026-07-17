#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom authenticated mobile QA"
require_postgres_write_approval "ManaLoom authenticated mobile QA direct cleanup"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool python3
if [[ ! -f "$ENV_FILE" ]]; then
  echo "arquivo de ambiente ausente: $ENV_FILE" >&2
  exit 2
fi

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
load_manaloom_env_keys "$ENV_FILE" \
  EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY EASYPANEL_SSH_USER \
  MANALOOM_API_BASE_URL MANALOOM_EASYPANEL_SSH_HOST \
  MANALOOM_EASYPANEL_SSH_KEY MANALOOM_MOBILE_QA_DEVICE_ID \
  MANALOOM_MOBILE_QA_OUT_DIR MANALOOM_POSTGRES_DB \
  MANALOOM_POSTGRES_SERVICE MANALOOM_POSTGRES_USER

API="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
DEVICE_ID="${MANALOOM_MOBILE_QA_DEVICE_ID:-}"
OUT_DIR="${MANALOOM_MOBILE_QA_OUT_DIR:-$ROOT_DIR/docs/qa/runtime}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$OUT_DIR/mobile-authenticated-qa-$STAMP"
LOG_FILE="$RUN_DIR/flutter_test.log"
SUMMARY_FILE="$RUN_DIR/summary.json"

require_tool flutter
require_tool jq
require_tool ssh

for key in SSH_HOST SSH_KEY; do
  if [[ -z "${!key:-}" ]]; then
    echo "variavel obrigatoria ausente: $key" >&2
    exit 2
  fi
done
if [[ ! -f "$SSH_KEY" ]]; then
  echo "chave SSH ausente: $SSH_KEY" >&2
  exit 2
fi

validate_manaloom_release_api_base_url "$API"
validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_exact_coordinate \
  "servico PostgreSQL" "$POSTGRES_SERVICE" "evolution_manaloom-postgres"
validate_manaloom_exact_coordinate "usuario PostgreSQL" "$POSTGRES_USER" "postgres"
validate_manaloom_exact_coordinate "database PostgreSQL" "$POSTGRES_DB" "halder"

QA_EMAIL=""
CLEANUP_COMPLETE=0
CLEANUP_PROOF=""

cleanup_user() {
  local output rest deleted_ai deleted_users remaining
  if [[ ! "$QA_EMAIL" =~ ^mobile-qa-[0-9a-f]+@example\.invalid$ ]]; then
    echo "email de QA invalido; cleanup remoto recusado" >&2
    return 1
  fi
  if ! output="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec -i \"\$cid\" psql -qAt -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1 -v qa_email='$QA_EMAIL'" <<'SQL'
BEGIN;
CREATE TEMP TABLE manaloom_cleanup_target (id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO manaloom_cleanup_target (id)
SELECT id FROM users WHERE email = :'qa_email';
WITH deleted_ai AS (
  DELETE FROM ai_logs USING manaloom_cleanup_target
  WHERE ai_logs.user_id = manaloom_cleanup_target.id
  RETURNING 1
)
SELECT COUNT(*) FROM deleted_ai;
WITH deleted_users AS (
  DELETE FROM users
  WHERE id IN (SELECT id FROM manaloom_cleanup_target)
  RETURNING 1
)
SELECT COUNT(*) FROM deleted_users;
SELECT COUNT(*) FROM users WHERE email = :'qa_email';
COMMIT;
SQL
  )"; then
    echo "cleanup remoto do usuario mobile QA falhou" >&2
    return 1
  fi
  output="${output//$'\r'/}"
  if [[ "$output" != *$'\n'* ]]; then
    echo "cleanup mobile QA sem prova exata: ${output//$'\n'/,}" >&2
    return 1
  fi
  deleted_ai="${output%%$'\n'*}"
  rest="${output#*$'\n'}"
  if [[ "$rest" != *$'\n'* ]]; then
    echo "cleanup mobile QA sem contagem de usuario e pos-checagem" >&2
    return 1
  fi
  deleted_users="${rest%%$'\n'*}"
  remaining="${rest#*$'\n'}"
  if [[ ! "$deleted_ai" =~ ^[0-9]+$ || "$deleted_users" != "1" ||
        "$remaining" != "0" || "$remaining" == *$'\n'* ]]; then
    echo "cleanup mobile QA deixou usuario residual" >&2
    return 1
  fi
  CLEANUP_COMPLETE=1
  CLEANUP_PROOF="deleted_ai_logs=$deleted_ai,deleted_users=1,remaining_users=0"
}

cleanup_on_exit() {
  local original_status=$?
  local cleanup_status=0
  trap - EXIT
  set +e
  if [[ -n "$QA_EMAIL" && "$CLEANUP_COMPLETE" != "1" ]]; then
    cleanup_user || cleanup_status=$?
  fi
  cleanup_manaloom_secure_ssh
  if (( cleanup_status != 0 )); then
    exit 1
  fi
  exit "$original_status"
}

initialize_manaloom_secure_ssh "$SSH_HOST"
trap cleanup_on_exit EXIT

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

QA_EMAIL="$(grep -Eo 'MOBILE_QA_USER_EMAIL=[^[:space:]]+' "$LOG_FILE" | tail -n 1 | cut -d= -f2- || true)"
cleanup_status="skipped"
if [ -n "$QA_EMAIL" ]; then
  if cleanup_user; then
    cleanup_status="ok"
  else
    cleanup_status="failed"
    status="fail"
  fi
elif [ "$test_code" -eq 0 ]; then
  cleanup_status="missing_identity"
  status="fail"
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
  --arg cleanup_proof "$CLEANUP_PROOF" \
  --argjson test_exit_code "$test_code" \
  '{
    status: $status,
    api: $api,
    device_id: $device_id,
    test_exit_code: $test_exit_code,
    cleanup_status: $cleanup_status,
    cleanup_proof: $cleanup_proof,
    artifacts_dir: $run_dir,
    log_file: $log_file
  }' | tee "$SUMMARY_FILE"

if [ "$status" != "pass" ]; then
  exit 1
fi
