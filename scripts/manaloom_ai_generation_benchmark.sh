#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$SCRIPT_DIR/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom AI generation benchmark"
require_postgres_write_approval "ManaLoom AI generation benchmark direct cleanup"

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
  MANALOOM_AI_BENCHMARK_RUNS MANALOOM_API_BASE_URL \
  MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY \
  MANALOOM_POSTGRES_DB MANALOOM_POSTGRES_SERVICE MANALOOM_POSTGRES_USER

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
RUNS="${MANALOOM_AI_BENCHMARK_RUNS:-3}"

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
if [[ ! "$RUNS" =~ ^[1-9][0-9]*$ || "$RUNS" -gt 20 ]]; then
  echo "MANALOOM_AI_BENCHMARK_RUNS deve estar entre 1 e 20" >&2
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
EMAIL="codex-ai-benchmark-$TS@example.invalid"
USERNAME="codexaibench$TS"
PASSWORD="Benchmark-$TS"
USER_ID=""
USER_CREATED=0
CLEANUP_PROOF=""

cleanup_user() {
  local output rest deleted_ai deleted_users remaining
  if [[ "$USER_CREATED" != "1" ]]; then
    return 0
  fi
  if [[ ! "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ||
        ! "$EMAIL" =~ ^codex-ai-benchmark-[0-9]+@example\.invalid$ ]]; then
    echo "identidade benchmark invalida; cleanup recusado" >&2
    return 1
  fi
  # shellcheck disable=SC2087
  if ! output="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec -i \"\$cid\" psql -qAt -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1" <<SQL
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
    echo "cleanup remoto do benchmark falhou" >&2
    return 1
  fi
  output="${output//$'\r'/}"
  if [[ "$output" != *$'\n'* ]]; then
    echo "cleanup benchmark sem prova exata: ${output//$'\n'/,}" >&2
    return 1
  fi
  deleted_ai="${output%%$'\n'*}"
  rest="${output#*$'\n'}"
  if [[ "$rest" != *$'\n'* ]]; then
    echo "cleanup benchmark sem contagem de usuario e pos-checagem" >&2
    return 1
  fi
  deleted_users="${rest%%$'\n'*}"
  remaining="${rest#*$'\n'}"
  if [[ ! "$deleted_ai" =~ ^[0-9]+$ || "$deleted_users" != "1" ||
        "$remaining" != "0" || "$remaining" == *$'\n'* ]]; then
    echo "cleanup benchmark deixou usuario residual" >&2
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
  cleanup_user || cleanup_status=$?
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
token="$(printf '%s' "$registration_response" | jq -r '.token')"
USER_ID="$(printf '%s' "$registration_response" | jq -r '.user.id')"

if [[ "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; then
  USER_CREATED=1
else
  echo "registro benchmark nao retornou user id valido" >&2
  exit 1
fi
if [[ -z "$token" || "$token" == "null" ]]; then
  echo "registro nao retornou token" >&2
  exit 1
fi

prompt_for_run() {
  case "$1" in
    1) echo "mono red aggro with low curve burn creatures and haste threats" ;;
    2) echo "azorius control with board wipes card draw and planeswalkers" ;;
    *) echo "green white counters deck with efficient creatures protection and card advantage" ;;
  esac
}

results_file="$TMP_DIR/results.jsonl"

for run in $(seq 1 "$RUNS"); do
  prompt="$(prompt_for_run "$run")"
  body_file="$TMP_DIR/ai_generate_$run.json"
  metrics_file="$TMP_DIR/ai_generate_$run.metrics"
  payload="$(jq -n --arg prompt "$prompt" '{prompt:$prompt,format:"Standard"}')"

  curl -sS -o "$body_file" -w '%{http_code} %{time_namelookup} %{time_connect} %{time_starttransfer} %{time_total}' \
    -X POST "$BASE/ai/generate" \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    --data "$payload" >"$metrics_file"

  read -r http_code time_namelookup time_connect time_starttransfer time_total <"$metrics_file" || true

  jq -n \
    --argjson run "$run" \
    --arg prompt "$prompt" \
    --arg http_code "$http_code" \
    --arg time_namelookup "$time_namelookup" \
    --arg time_connect "$time_connect" \
    --arg time_starttransfer "$time_starttransfer" \
    --arg time_total "$time_total" \
    --slurpfile body "$body_file" '
      def card_count:
        ((($body[0].generated_deck.cards // []) | map(.quantity // 1) | add) // 0)
        + (if $body[0].generated_deck.commander then 1 else 0 end);
      {
        run: $run,
        prompt: $prompt,
        http_code: ($http_code | tonumber),
        time_namelookup_ms: (($time_namelookup | tonumber) * 1000 | round),
        time_connect_ms: (($time_connect | tonumber) * 1000 | round),
        time_starttransfer_ms: (($time_starttransfer | tonumber) * 1000 | round),
        time_total_ms: (($time_total | tonumber) * 1000 | round),
        is_mock: (
          if ($body[0] | has("is_mock")) then $body[0].is_mock
          elif (($body[0].generated_deck // {}) | has("is_mock"))
          then $body[0].generated_deck.is_mock
          else null
          end
        ),
        generation_mode: ($body[0].generation_mode // null),
        deckbuilding_contract_present: ($body[0].deckbuilding_contract != null),
        validation_is_valid: ($body[0].validation.is_valid == true),
        invalid_cards_count: (($body[0].validation.invalid_cards // []) | length),
        provider_repair_eligible: ($body[0].provider_repair.eligible == true),
        learning_eligible: (
          if ($body[0] | has("learning_eligible"))
          then $body[0].learning_eligible
          else null
          end
        ),
        generated_card_count: card_count,
        error: ($body[0].error // null)
      }
    ' >>"$results_file"
done

cleanup_user

jq -s \
  --arg api "$BASE" \
  --arg cleanup_proof "$CLEANUP_PROOF" '
  def sorted_times: map(.time_total_ms) | sort;
  def successful_runs:
    map(select(
      .http_code == 200 and
      .validation_is_valid == true and
      .deckbuilding_contract_present == true and
      .generated_card_count >= 60 and
      .is_mock == false and
      (.generation_mode != "mock_fallback")
    )) | length;
  def mock_response_count:
    map(select(.is_mock == true or .generation_mode == "mock_fallback"))
    | length;
  def percentile($p):
    sorted_times as $values
    | if ($values | length) == 0 then null
      else $values[([((($values | length) * $p / 100) | ceil) - 1, 0] | max)]
      end;
  {
    status: (
      if successful_runs == length and mock_response_count == 0
      then "pass"
      else "degraded"
      end
    ),
    api: $api,
    cleanup_proof: $cleanup_proof,
    runs: length,
    successful_runs: successful_runs,
    mock_response_count: mock_response_count,
    repaired_run_count: (map(select(.provider_repair_eligible == true)) | length),
    avg_total_ms: ((map(.time_total_ms) | add) / length | round),
    p50_total_ms: percentile(50),
    p95_total_ms: percentile(95),
    max_total_ms: (map(.time_total_ms) | max),
    results: .
  }
' "$results_file"
