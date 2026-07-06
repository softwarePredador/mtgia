#!/usr/bin/env bash
set -euo pipefail

API="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
WEB="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
BENCHMARK_RUNS="${MANALOOM_AI_BENCHMARK_RUNS:-3}"
ALLOW_DEGRADED_AI="${MANALOOM_ALLOW_DEGRADED_AI:-1}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool curl
require_tool jq
require_tool ssh

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
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
  local tmp="$file.tmp"
  local attempt

  for attempt in 1 2 3; do
    if curl -fsS "$url" | jq '.' > "$tmp"; then
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
fetch_json "$API/health/commercial" "$commercial_file"
fetch_json "$API/health/ai-history?days=30&bucket=day" "$ai_history_file"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  'docker service ls --format "{{.Name}} {{.Image}} {{.Replicas}}" | grep evolution_cartinhas' \
  > "$service_file"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  'crontab -l 2>/dev/null | grep "manaloom-postgres-" || true' \
  > "$cron_file"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
  'latest="$(readlink -f /opt/manaloom/backups/postgres/latest.dump 2>/dev/null || true)"; if [ -n "$latest" ] && [ -f "$latest" ]; then bytes="$(wc -c < "$latest" | tr -d " ")"; printf "{\"latest\":\"%s\",\"bytes\":%s}\n" "$latest" "$bytes"; else printf "{\"latest\":null,\"bytes\":0}\n"; fi' \
  | write_json "$backup_file"

MANALOOM_API_BASE_URL="$API" MANALOOM_WEB_PUBLIC_URL="$WEB" \
  "$ROOT_DIR/scripts/manaloom_product_smoke.sh" \
  | write_json "$smoke_file"

MANALOOM_API_BASE_URL="$API" MANALOOM_AI_BENCHMARK_RUNS="$BENCHMARK_RUNS" \
  "$ROOT_DIR/scripts/manaloom_ai_generation_benchmark.sh" \
  | write_json "$benchmark_file"

health_status="$(jq -r '.status' "$health_file")"
ready_status="$(jq -r '.status' "$ready_file")"
git_sha="$(jq -r '.git_sha // ""' "$health_file")"
smoke_status="$(jq -r '.status' "$smoke_file")"
benchmark_status="$(jq -r '.status' "$benchmark_file")"
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
if [ "$service_replicas" != "1/1" ]; then
  status="fail"
  issues+=("service_not_converged")
fi
if [ "$smoke_status" != "ok" ]; then
  status="fail"
  issues+=("product_smoke_failed")
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
  --argjson successful_ai_runs "$successful_ai_runs" \
  --argjson mock_count "$mock_count" \
  --argjson ai_history_periods "$ai_history_periods" \
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
