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

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN ausente no ambiente}"
: "${SENTRY_ORG_SLUG:?SENTRY_ORG_SLUG ausente no ambiente}"
: "${SENTRY_MOBILE_PROJECT_SLUG:?SENTRY_MOBILE_PROJECT_SLUG ausente no ambiente}"

tmp_output="$(mktemp)"
response_file="$(mktemp)"
trap 'rm -f "$tmp_output" "$response_file"' EXIT

local_exit_code=0
if ! "$ROOT_DIR/scripts/validate_sentry_mobile_local.sh" "$@" | tee "$tmp_output"; then
  local_exit_code=$?
fi

if [[ "$local_exit_code" -ne 0 ]]; then
  if grep -q 'SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1' "$tmp_output"; then
    echo "Validacao mobile bloqueada por toolchain/build antes da ingestao no Sentry." >&2
  fi
  exit "$local_exit_code"
fi

event_line="$(grep -o 'SENTRY_MOBILE_EVENT_ID=[^[:space:]]*' "$tmp_output" | tail -n1 || true)"
smoke_line="$(grep -o 'SENTRY_MOBILE_SMOKE_TAG=smoke_id:[^[:space:]]*' "$tmp_output" | tail -n1 || true)"

if [[ -z "$event_line" ]]; then
  echo "Nao foi possivel extrair o event_id do teste mobile." >&2
  exit 1
fi

if [[ -z "$smoke_line" ]]; then
  echo "Nao foi possivel extrair o smoke_id do teste mobile." >&2
  exit 1
fi

event_id="${event_line#SENTRY_MOBILE_EVENT_ID=}"
smoke_id="${smoke_line#SENTRY_MOBILE_SMOKE_TAG=smoke_id:}"
query_url="https://sentry.io/api/0/projects/${SENTRY_ORG_SLUG}/${SENTRY_MOBILE_PROJECT_SLUG}/events/${event_id}/"

echo "Consultando Sentry para event_id:${event_id}..."

for attempt in {1..12}; do
  http_code="$(curl -sS \
    -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
    "$query_url" \
    -o "$response_file" \
    -w '%{http_code}' || true)"

  if [[ "$http_code" == "200" ]]; then
    if python3 - "$event_id" "$smoke_id" "$response_file" <<'PY'
import json
import sys

event_id = sys.argv[1]
smoke_id = sys.argv[2]
response_file = sys.argv[3]

with open(response_file, 'r', encoding='utf-8') as fh:
    payload = json.load(fh)

text = json.dumps(payload)
raise SystemExit(0 if event_id in text and smoke_id in text else 1)
PY
    then
      group_id="$(python3 - "$response_file" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    payload = json.load(fh)

print(payload.get('groupID') or '')
PY
)"
      echo "SENTRY_MOBILE_GROUP_ID=${group_id}"
      echo "SENTRY_MOBILE_EVENT_ID=${event_id}"
      echo "SENTRY_MOBILE_SMOKE_TAG=smoke_id:${smoke_id}"
      exit 0
    fi
  fi

  sleep 5
done

echo "Nao foi encontrado evento no Sentry para event_id:${event_id}." >&2
exit 1
