#!/usr/bin/env bash
set -euo pipefail

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"
RUNS="${MANALOOM_AI_BENCHMARK_RUNS:-3}"

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
EMAIL="codex-ai-benchmark-$TS@example.invalid"
USERNAME="codexaibench$TS"
PASSWORD="Benchmark-$TS"

cleanup() {
  rm -rf "$TMP_DIR"
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec \"\$cid\" psql -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1 -c \"DELETE FROM users WHERE email = '$EMAIL';\"" \
    >/dev/null 2>&1 || true
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
token="$(printf '%s' "$registration_response" | jq -r '.token')"

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
        is_mock: ($body[0].is_mock // $body[0].generated_deck.is_mock // null),
        generation_mode: ($body[0].generation_mode // null),
        deckbuilding_contract_present: ($body[0].deckbuilding_contract != null),
        generated_card_count: card_count,
        error: ($body[0].error // null)
      }
    ' >>"$results_file"
done

jq -s '
  def sorted_times: map(.time_total_ms) | sort;
  def percentile($p):
    sorted_times as $values
    | if ($values | length) == 0 then null
      else $values[((($values | length) - 1) * $p / 100) | floor]
      end;
  {
    status: "ok",
    api: "'"$BASE"'",
    runs: length,
    successful_runs: map(select(.http_code == 200)) | length,
    avg_total_ms: ((map(.time_total_ms) | add) / length | round),
    p50_total_ms: percentile(50),
    p95_total_ms: percentile(95),
    max_total_ms: (map(.time_total_ms) | max),
    results: .
  }
' "$results_file"
