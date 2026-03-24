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

BASE_URL="${API_BASE_URL:-${PUBLIC_API_BASE_URL:-}}"
if [[ -z "$BASE_URL" && -n "${EASYPANEL_DOMAIN:-}" ]]; then
  BASE_URL="https://${EASYPANEL_DOMAIN}"
fi
if [[ -z "$BASE_URL" ]]; then
  echo "API_BASE_URL/PUBLIC_API_BASE_URL/EASYPANEL_DOMAIN ausente no ambiente." >&2
  exit 1
fi

BASE_URL="${BASE_URL%/}"
REQUEST_ID="${REQUEST_ID_OVERRIDE:-manual-req-$(date +%Y%m%d%H%M%S)}"

echo "READY_VALIDATION_BASE_URL=$BASE_URL"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_check() {
  local path="$1"
  local target="$BASE_URL$path"
  local output_file="$tmp_dir$(echo "$path" | tr '/' '_').txt"

  curl -sS -i \
    -H "x-request-id: $REQUEST_ID" \
    "$target" \
    >"$output_file"

  local status_line
  status_line="$(head -n1 "$output_file" | tr -d '\r')"
  local status_code
  status_code="$(printf '%s' "$status_line" | awk '{print $2}')"
  local echoed_request_id
  echoed_request_id="$(
    grep -i '^x-request-id:' "$output_file" \
      | tail -n1 \
      | tr -d '\r' \
      | cut -d':' -f2- \
      | xargs || true
  )"

  if [[ "$status_code" != "200" ]]; then
    echo "Falha em $path: status $status_code" >&2
    cat "$output_file" >&2
    exit 1
  fi

  if [[ "$echoed_request_id" != "$REQUEST_ID" ]]; then
    echo "Falha em $path: x-request-id nao foi ecoado corretamente" >&2
    echo "Esperado: $REQUEST_ID" >&2
    echo "Recebido: $echoed_request_id" >&2
    cat "$output_file" >&2
    exit 1
  fi

  echo "READY_CHECK_PATH=$path"
  echo "READY_CHECK_STATUS=$status_code"
  echo "READY_CHECK_REQUEST_ID=$echoed_request_id"
}

run_check "/health"
run_check "/health/ready"
run_check "/ready"

echo "READY_VALIDATION_OK=1"
