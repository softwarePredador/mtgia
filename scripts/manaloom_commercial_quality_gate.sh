#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$SCRIPT_DIR/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom commercial quality gate"
require_postgres_write_approval "ManaLoom commercial quality gate cleanup"

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
  MANALOOM_AI_BENCHMARK_RUNS MANALOOM_ALLOW_DEGRADED_AI \
  MANALOOM_API_BASE_URL MANALOOM_BACKEND_SERVICE \
  MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY \
  MANALOOM_OPS_API_KEY MANALOOM_QUALITY_GATE_OUT_DIR \
  MANALOOM_WEB_PUBLIC_URL

API="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
WEB="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
BACKEND_SERVICE="${MANALOOM_BACKEND_SERVICE:-evolution_cartinhas}"
BENCHMARK_RUNS="${MANALOOM_AI_BENCHMARK_RUNS:-3}"
ALLOW_DEGRADED_AI="${MANALOOM_ALLOW_DEGRADED_AI:-0}"

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
if [[ ! "$BENCHMARK_RUNS" =~ ^[1-9][0-9]*$ || "$BENCHMARK_RUNS" -gt 20 ]]; then
  echo "MANALOOM_AI_BENCHMARK_RUNS deve estar entre 1 e 20" >&2
  exit 2
fi
if [[ "$ALLOW_DEGRADED_AI" != "0" && "$ALLOW_DEGRADED_AI" != "1" ]]; then
  echo "MANALOOM_ALLOW_DEGRADED_AI deve ser 0 ou 1" >&2
  exit 2
fi

validate_manaloom_release_api_base_url "$API"
validate_manaloom_exact_coordinate \
  "web publica" "$WEB" "https://$MANALOOM_PRODUCTION_PUBLIC_HOST"
validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_exact_coordinate \
  "servico backend" "$BACKEND_SERVICE" "evolution_cartinhas"

cleanup_on_exit() {
  local original_status=$?
  trap - EXIT
  cleanup_manaloom_secure_ssh
  exit "$original_status"
}

initialize_manaloom_secure_ssh "$SSH_HOST"
trap cleanup_on_exit EXIT

OPS_API_KEY="${MANALOOM_OPS_API_KEY:-}"
if [ "${#OPS_API_KEY}" -lt 32 ]; then
  OPS_API_KEY="$(ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
    "docker service inspect '$BACKEND_SERVICE' --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | sed -n 's/^MANALOOM_OPS_API_KEY=//p' | head -n 1")"
fi
if [ "${#OPS_API_KEY}" -lt 32 ]; then
  echo "MANALOOM_OPS_API_KEY operacional ausente ou invalida" >&2
  exit 2
fi

OUT_DIR="${MANALOOM_QUALITY_GATE_OUT_DIR:-$ROOT_DIR/docs/qa/runtime}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$OUT_DIR/manaloom-commercial-quality-gate-$STAMP"
mkdir -p "$RUN_DIR"

write_json() {
  local file="$1"
  jq '.' > "$file"
}

fetch_json() {
  local url="$1"
  local file="$2"
  local ops_key="${3:-}"
  local tmp="$file.tmp"
  local attempt
  local curl_command=(curl -fsS)

  if [ -n "$ops_key" ]; then
    curl_command+=(-H "X-ManaLoom-Ops-Key: $ops_key")
  fi

  for attempt in 1 2 3; do
    if "${curl_command[@]}" "$url" | jq '.' > "$tmp"; then
      mv "$tmp" "$file"
      return 0
    fi
    sleep "$((attempt * 2))"
  done

  rm -f "$tmp"
  echo "{\"status\":\"error\",\"url\":\"$url\",\"error\":\"request_failed_after_retries\"}" > "$file"
  return 1
}

health_file="$RUN_DIR/health.json"
ready_file="$RUN_DIR/ready.json"
commercial_file="$RUN_DIR/commercial.json"
ai_history_file="$RUN_DIR/ai_history.json"
service_file="$RUN_DIR/service.txt"
cron_file="$RUN_DIR/remote_cron.txt"
backup_file="$RUN_DIR/remote_backup_latest.json"
smoke_file="$RUN_DIR/product_smoke.json"
benchmark_file="$RUN_DIR/ai_generation_benchmark.json"
summary_file="$RUN_DIR/summary.json"

fetch_json "$API/health" "$health_file"
fetch_json "$API/ready" "$ready_file"
fetch_json "$API/health/commercial" "$commercial_file" "$OPS_API_KEY"
fetch_json "$API/health/ai-history?days=30&bucket=day" "$ai_history_file" "$OPS_API_KEY"
public_metrics_code="$(curl -sS -o /dev/null -w '%{http_code}' "$API/health/metrics")"

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  'docker service ls --format "{{.Name}} {{.Image}} {{.Replicas}}" | grep evolution_cartinhas' \
  > "$service_file"

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  'crontab -l 2>/dev/null | grep "manaloom-postgres-" || true' \
  > "$cron_file"

ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" \
  'latest="$(readlink -f /opt/manaloom/backups/postgres/latest.dump 2>/dev/null || true)"; if [ -n "$latest" ] && [ -f "$latest" ]; then bytes="$(wc -c < "$latest" | tr -d " ")"; printf "{\"latest\":\"%s\",\"bytes\":%s}\n" "$latest" "$bytes"; else printf "{\"latest\":null,\"bytes\":0}\n"; fi' \
  | write_json "$backup_file"

MANALOOM_NEW_SERVER_ENV="$ENV_FILE" \
  MANALOOM_API_BASE_URL="$API" MANALOOM_WEB_PUBLIC_URL="$WEB" \
  "$ROOT_DIR/scripts/manaloom_product_smoke.sh" \
  | write_json "$smoke_file"

MANALOOM_NEW_SERVER_ENV="$ENV_FILE" \
  MANALOOM_API_BASE_URL="$API" MANALOOM_AI_BENCHMARK_RUNS="$BENCHMARK_RUNS" \
  "$ROOT_DIR/scripts/manaloom_ai_generation_benchmark.sh" \
  | write_json "$benchmark_file"

health_status="$(jq -r '.status' "$health_file")"
ready_status="$(jq -r '.status' "$ready_file")"
ai_runtime_status="$(jq -r '.checks.ai_runtime.status // "missing"' "$ready_file")"
ai_provider_configured="$(jq -r '.checks.ai_runtime.provider_configured // false' "$ready_file")"
ai_mock_fallbacks="$(jq -r '
  if (.checks.ai_runtime | has("mock_fallbacks_allowed"))
  then .checks.ai_runtime.mock_fallbacks_allowed
  else true
  end
' "$ready_file")"
battle_runtime_status="$(jq -r '.checks.battle_runtime.status // "missing"' "$ready_file")"
battle_runtime_mode="$(jq -r '.checks.battle_runtime.mode // "missing"' "$ready_file")"
battle_healthy_engines="$(jq -r '[.checks.battle_runtime.engines[]? | select(.status == "healthy")] | length' "$ready_file")"
git_sha="$(jq -r '.git_sha // ""' "$health_file")"
smoke_status="$(jq -r '.status' "$smoke_file")"
benchmark_status="$(jq -r '.status' "$benchmark_file")"
smoke_cleanup_proof="$(jq -r '.cleanup // ""' "$smoke_file")"
benchmark_cleanup_proof="$(jq -r '.cleanup_proof // ""' "$benchmark_file")"
ai_history_status="$(jq -r '.status' "$ai_history_file")"
ai_history_periods="$(jq -r '.period_count // 0' "$ai_history_file")"
mock_count="$(jq -r '.mock_response_count // 0' "$benchmark_file")"
successful_ai_runs="$(jq -r '.successful_runs // 0' "$benchmark_file")"
backup_bytes="$(jq -r '.bytes // 0' "$backup_file")"
cron_lines="$(wc -l < "$cron_file" | tr -d ' ')"
service_replicas="$(awk '{print $NF}' "$service_file" | tail -n 1)"

status="pass"
issues=()

if [ "$health_status" != "healthy" ]; then
  status="fail"
  issues+=("health_not_healthy")
fi
if [ "$ready_status" != "ready" ]; then
  status="fail"
  issues+=("ready_not_ready")
fi
if [ "$ai_runtime_status" != "healthy" ] ||
   [ "$ai_provider_configured" != "true" ] ||
   [ "$ai_mock_fallbacks" != "false" ]; then
  status="fail"
  issues+=("ai_runtime_not_production_ready")
fi
if [ "$battle_runtime_status" != "healthy" ] ||
   [ "$battle_runtime_mode" != "auto" ] ||
   [ "$battle_healthy_engines" != "3" ]; then
  status="fail"
  issues+=("battle_runtime_not_production_ready")
fi
if [ "$public_metrics_code" != "401" ]; then
  status="fail"
  issues+=("operational_metrics_not_protected")
fi
if [ "$service_replicas" != "1/1" ]; then
  status="fail"
  issues+=("service_not_converged")
fi
if [ "$smoke_status" != "ok" ]; then
  status="fail"
  issues+=("product_smoke_failed")
fi
if [[ "$smoke_cleanup_proof" != *"deleted_users=1,remaining_users=0"* ]]; then
  status="fail"
  issues+=("product_smoke_cleanup_unproven")
fi
if [[ "$benchmark_cleanup_proof" != *"deleted_users=1,remaining_users=0"* ]]; then
  status="fail"
  issues+=("ai_benchmark_cleanup_unproven")
fi
if [ "$mock_count" != "0" ]; then
  status="fail"
  issues+=("ai_mock_response_detected")
fi
if [ "$benchmark_status" != "pass" ]; then
  if [ "$ALLOW_DEGRADED_AI" = "1" ]; then
    [ "$status" = "pass" ] && status="degraded"
    issues+=("ai_generation_degraded")
  else
    status="fail"
    issues+=("ai_generation_degraded")
  fi
fi
if [ "$ai_history_status" != "ok" ]; then
  status="fail"
  issues+=("ai_history_dashboard_unavailable")
fi
if [ "$backup_bytes" -lt 1024 ]; then
  status="fail"
  issues+=("backup_missing_or_too_small")
fi
if [ "$cron_lines" -lt 2 ]; then
  status="fail"
  issues+=("backup_cron_missing")
fi

issues_json="$(printf '%s\n' "${issues[@]:-}" | jq -R 'select(length > 0)' | jq -s '.')"

jq -n \
  --arg status "$status" \
  --arg api "$API" \
  --arg web "$WEB" \
  --arg git_sha "$git_sha" \
  --arg run_dir "$RUN_DIR" \
  --arg service_replicas "$service_replicas" \
  --arg benchmark_status "$benchmark_status" \
  --arg ai_history_status "$ai_history_status" \
  --arg ai_runtime_status "$ai_runtime_status" \
  --arg battle_runtime_status "$battle_runtime_status" \
  --arg battle_runtime_mode "$battle_runtime_mode" \
  --arg public_metrics_code "$public_metrics_code" \
  --argjson successful_ai_runs "$successful_ai_runs" \
  --argjson mock_count "$mock_count" \
  --argjson ai_history_periods "$ai_history_periods" \
  --argjson battle_healthy_engines "$battle_healthy_engines" \
  --argjson backup_bytes "$backup_bytes" \
  --argjson cron_lines "$cron_lines" \
  --argjson issues "$issues_json" \
  '{
    status: $status,
    api: $api,
    web: $web,
    git_sha: $git_sha,
    service_replicas: $service_replicas,
    ai_generation: {
      status: $benchmark_status,
      successful_runs: $successful_ai_runs,
      mock_response_count: $mock_count
    },
    ai_runtime: {
      status: $ai_runtime_status,
      unauthenticated_metrics_code: ($public_metrics_code | tonumber)
    },
    battle_runtime: {
      status: $battle_runtime_status,
      mode: $battle_runtime_mode,
      healthy_engines: $battle_healthy_engines
    },
    ai_history: {
      status: $ai_history_status,
      period_count: $ai_history_periods
    },
    backup: {
      latest_bytes: $backup_bytes,
      cron_lines: $cron_lines
    },
    issues: $issues,
    artifacts_dir: $run_dir
  }' | tee "$summary_file"

if [ "$status" = "fail" ]; then
  exit 1
fi
