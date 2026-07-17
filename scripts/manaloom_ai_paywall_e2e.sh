#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$SCRIPT_DIR/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom AI paywall E2E"
require_postgres_write_approval "ManaLoom AI paywall seed and cleanup"

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
source "$SCRIPT_DIR/lib/manaloom_safe_env.sh"
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$SCRIPT_DIR/lib/manaloom_release_runtime_contract.sh"
load_manaloom_env_keys "$ENV_FILE" \
  EASYPANEL_SERVER_IP EASYPANEL_SSH_KEY EASYPANEL_SSH_USER \
  MANALOOM_API_BASE_URL MANALOOM_EASYPANEL_SSH_HOST \
  MANALOOM_EASYPANEL_SSH_KEY MANALOOM_PAYWALL_SEED_COUNT \
  MANALOOM_POSTGRES_DB MANALOOM_POSTGRES_SERVICE MANALOOM_POSTGRES_USER

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
SEED_COUNT="${MANALOOM_PAYWALL_SEED_COUNT:-120}"

require_tool curl
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
if [[ ! "$SEED_COUNT" =~ ^[1-9][0-9]*$ || "$SEED_COUNT" -gt 10000 ]]; then
  echo "MANALOOM_PAYWALL_SEED_COUNT deve estar entre 1 e 10000" >&2
  exit 2
fi

validate_manaloom_release_api_base_url "$BASE"
validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_exact_coordinate \
  "servico PostgreSQL" "$POSTGRES_SERVICE" "evolution_manaloom-postgres"
validate_manaloom_exact_coordinate "usuario PostgreSQL" "$POSTGRES_USER" "postgres"
validate_manaloom_exact_coordinate "database PostgreSQL" "$POSTGRES_DB" "halder"

TMP_DIR="$(mktemp -d)"
TS="$(date +%s)$$"
EMAIL="codex-ai-paywall-$TS@example.invalid"
USERNAME="codexaipaywall$TS"
PASSWORD="Paywall-$TS"
USER_ID=""
USER_CREATED=0
EXPECTED_AI_LOGS=0
CLEANUP_PROOF=""

remote_psql() {
  ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec -i \"\$cid\" psql -qAt -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1"
}

cleanup_remote_user() {
  local output rest deleted_ai deleted_users remaining
  if [[ "$USER_CREATED" != "1" ]]; then
    return 0
  fi
  if [[ ! "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ||
        ! "$EMAIL" =~ ^codex-ai-paywall-[0-9]+@example\.invalid$ ]]; then
    echo "identidade paywall invalida; cleanup recusado" >&2
    return 1
  fi
  if ! output="$(remote_psql <<SQL
BEGIN;
CREATE TEMP TABLE manaloom_cleanup_target (id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO manaloom_cleanup_target (id)
SELECT id FROM users WHERE id = '$USER_ID'::uuid AND email = '$EMAIL';
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
SELECT COUNT(*) FROM users WHERE id = '$USER_ID'::uuid OR email = '$EMAIL';
COMMIT;
SQL
  )"; then
    echo "cleanup remoto do usuario paywall falhou" >&2
    return 1
  fi
  output="${output//$'\r'/}"
  if [[ "$output" != *$'\n'* ]]; then
    echo "cleanup paywall sem prova exata: ${output//$'\n'/,}" >&2
    return 1
  fi
  deleted_ai="${output%%$'\n'*}"
  rest="${output#*$'\n'}"
  if [[ "$rest" != *$'\n'* ]]; then
    echo "cleanup paywall sem contagem de usuario e pos-checagem" >&2
    return 1
  fi
  deleted_users="${rest%%$'\n'*}"
  remaining="${rest#*$'\n'}"
  if [[ ! "$deleted_ai" =~ ^[0-9]+$ || "$deleted_users" != "1" ||
        "$remaining" != "0" || "$remaining" == *$'\n'* ]] ||
     (( deleted_ai < EXPECTED_AI_LOGS )); then
    echo "cleanup paywall deixou residuos ou apagou menos logs que o esperado" >&2
    return 1
  fi
  USER_CREATED=0
  CLEANUP_PROOF="deleted_ai_logs=$deleted_ai,deleted_users=1,remaining_users=0"
}

cleanup_on_exit() {
  local original_status=$?
  local cleanup_status=0
  trap - EXIT
  set +e
  cleanup_remote_user || cleanup_status=$?
  rm -rf "$TMP_DIR"
  cleanup_manaloom_secure_ssh
  if (( cleanup_status != 0 )); then
    exit 1
  fi
  exit "$original_status"
}
initialize_manaloom_secure_ssh "$SSH_HOST"
trap cleanup_on_exit EXIT

curl -fsS "$BASE/health" >/dev/null
curl -fsS "$BASE/ready" >/dev/null

registration_payload="$(jq -n \
  --arg username "$USERNAME" \
  --arg email "$EMAIL" \
  --arg password "$PASSWORD" \
  '{username:$username,email:$email,password:$password}')"
registration_response="$(curl -fsS -X POST "$BASE/auth/register" \
  -H 'Content-Type: application/json' \
  --data "$registration_payload")"
TOKEN="$(printf '%s' "$registration_response" | jq -r '.token')"
USER_ID="$(printf '%s' "$registration_response" | jq -r '.user.id')"

if [[ "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; then
  USER_CREATED=1
else
  echo "registro nao retornou user id valido" >&2
  exit 1
fi
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "registro nao retornou token/user id" >&2
  exit 1
fi

remote_psql <<SQL >/dev/null
INSERT INTO ai_logs (
  user_id,
  endpoint,
  model,
  prompt_summary,
  response_summary,
  latency_ms,
  input_tokens,
  output_tokens,
  success,
  created_at
)
SELECT
  '$USER_ID'::uuid,
  'paywall_e2e_seed',
  'qa',
  'paywall_e2e_seed',
  'seed',
  1,
  0,
  0,
  true,
  NOW()
FROM generate_series(1, $SEED_COUNT);
SQL
EXPECTED_AI_LOGS="$SEED_COUNT"

PLAN_AFTER="$(curl -fsS "$BASE/users/me/plan" -H "Authorization: Bearer $TOKEN")"
PLAN_REMAINING="$(printf '%s' "$PLAN_AFTER" | jq -r '.plan.ai_requests_remaining // -1')"
PLAN_USED="$(printf '%s' "$PLAN_AFTER" | jq -r '.plan.ai_requests_used // -1')"

results_file="$TMP_DIR/results.jsonl"

check_endpoint() {
  local name="$1"
  local path="$2"
  local payload="$3"
  local body_file="$TMP_DIR/$name.json"
  local code
  code="$(curl -sS -o "$body_file" -w '%{http_code}' \
    -X POST "$BASE$path" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$payload")"

  jq -n \
    --arg endpoint "$name" \
    --arg path "$path" \
    --argjson http_code "$code" \
    --slurpfile body "$body_file" \
    '{
      endpoint: $endpoint,
      path: $path,
      http_code: $http_code,
      blocked: ($http_code == 402),
      error: ($body[0].error // null),
      message: ($body[0].message // null),
      plan_name: ($body[0].plan_name // null),
      ai_requests_remaining: ($body[0].ai_requests_remaining // null)
    }' >>"$results_file"
}

check_endpoint generate /ai/generate '{"prompt":"paywall qa","format":"Commander"}'
check_endpoint optimize /ai/optimize '{"deck_id":"00000000-0000-0000-0000-000000000000","archetype":"control"}'
check_endpoint rebuild /ai/rebuild '{"deck_id":"00000000-0000-0000-0000-000000000000","archetype":"control","bracket":2}'
check_endpoint explain /ai/explain '{"card_name":"Sol Ring","context":"paywall qa"}'

status="pass"
if [ "$PLAN_REMAINING" != "0" ]; then
  status="fail"
fi
if jq -e 'select(.blocked != true)' "$results_file" >/dev/null; then
  status="fail"
fi

cleanup_remote_user

jq -s \
  --arg status "$status" \
  --arg api "$BASE" \
  --arg cleanup_proof "$CLEANUP_PROOF" \
  --argjson plan_used "$PLAN_USED" \
  --argjson plan_remaining "$PLAN_REMAINING" \
  '. as $rows | {
    status: $status,
    api: $api,
    plan_after_seed: {
      ai_requests_used: $plan_used,
      ai_requests_remaining: $plan_remaining
    },
    cleanup_proof: $cleanup_proof,
    endpoints: $rows,
    all_blocked: ($rows | all(.blocked == true))
  }' "$results_file"

if [[ "$status" != "pass" ]]; then
  exit 1
fi
