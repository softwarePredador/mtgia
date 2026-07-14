#!/usr/bin/env bash
set -u

request_file="${1:-}"
output_file="${2:-}"
runs="${3:-20}"
timeout_ms="${4:-30000}"

if [[ -z "$request_file" || -z "$output_file" ]]; then
  echo "usage: $0 REQUEST_JSON OUTPUT_TSV [RUNS] [TIMEOUT_MS]" >&2
  exit 2
fi
if [[ ! -f "$request_file" ]]; then
  echo "request file not found: $request_file" >&2
  exit 2
fi
if ! [[ "$runs" =~ ^[1-9][0-9]*$ && "$timeout_ms" =~ ^[1-9][0-9]*$ ]]; then
  echo "RUNS and TIMEOUT_MS must be positive integers" >&2
  exit 2
fi

sidecar_url="${XMAGE_SIDECAR_URL:-http://127.0.0.1:8080}"
curl_timeout=$((timeout_ms / 1000 + 10))
tmp_request="$(mktemp)"
tmp_result="$(mktemp)"
trap 'rm -f "$tmp_request" "$tmp_result"' EXIT

printf 'seed\thttp_code\tstatus\tduration_ms\tturns\tevents\tsnapshots\terrors\twinner_deck_id\n' > "$output_file"
for seed in $(seq 1 "$runs"); do
  jq \
    --arg request_id "benchmark-$seed" \
    --argjson seed "$seed" \
    --argjson timeout_ms "$timeout_ms" \
    '.request_id=$request_id | .seed=$seed | .timeout_ms=$timeout_ms' \
    "$request_file" > "$tmp_request"

  : > "$tmp_result"
  http_code="$(curl \
    --silent \
    --show-error \
    --max-time "$curl_timeout" \
    --output "$tmp_result" \
    --write-out '%{http_code}' \
    --header 'Content-Type: application/json' \
    --data-binary "@$tmp_request" \
    "$sidecar_url/simulate")"
  if ! jq empty "$tmp_result" >/dev/null 2>&1; then
    printf '%s\t%s\tclient_error\t0\t0\t0\t0\t0\t\n' "$seed" "$http_code" >> "$output_file"
    continue
  fi
  jq -r \
    --arg seed "$seed" \
    --arg http_code "$http_code" \
    '[
      $seed,
      $http_code,
      (.status // .error),
      (.duration_ms // 0),
      (.turns // 0),
      ((.events // []) | length),
      ((.visual_snapshots // []) | length),
      (.metrics.total_errors // 0),
      (.winner_deck_id // "")
    ] | @tsv' "$tmp_result" >> "$output_file"
done

awk -F '\t' '
  NR > 1 {
    total++
    if ($3 == "completed") {
      completed++
      duration += $4
    } else {
      failed++
    }
  }
  END {
    average = completed ? duration / completed : 0
    printf "runs=%d completed=%d failed=%d average_completed_ms=%.0f\n", total, completed, failed, average
    if (completed == 0) exit 1
  }
' "$output_file"
