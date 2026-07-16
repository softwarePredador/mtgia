#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$SCRIPT_DIR/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom AI paywall E2E"
require_postgres_write_approval "ManaLoom AI paywall seed and cleanup"

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
SEED_COUNT="${MANALOOM_PAYWALL_SEED_COUNT:-120}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool curl
require_tool jq
require_tool ssh

TMP_DIR="$(mktemp -d)"
TS="$(date +%s)"
EMAIL="codex-ai-paywall-$TS@example.invalid"
USERNAME="codexaipaywall$TS"
PASSWORD="Paywall-$TS"
USER_ID=""

remote_psql() {
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec -i \"\$cid\" psql -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1"
}

cleanup_remote_user() {
  if [ -n "$USER_ID" ]; then
    remote_psql <<SQL >/dev/null 2>&1 || true
DELETE FROM ai_logs WHERE user_id = '$USER_ID'::uuid;
DELETE FROM users WHERE id = '$USER_ID'::uuid AND email = '$EMAIL';
SQL
    USER_ID=""
  fi
}

cleanup() {
  cleanup_remote_user
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

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

if [[ -z "$TOKEN" || "$TOKEN" == "null" || -z "$USER_ID" || "$USER_ID" == "null" ]]; then
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
  --argjson plan_used "$PLAN_USED" \
  --argjson plan_remaining "$PLAN_REMAINING" \
  '. as $rows | {
    status: $status,
    api: $api,
    plan_after_seed: {
      ai_requests_used: $plan_used,
      ai_requests_remaining: $plan_remaining
    },
    endpoints: $rows,
    all_blocked: ($rows | all(.blocked == true))
  }' "$results_file"
