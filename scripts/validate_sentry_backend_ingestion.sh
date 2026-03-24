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
: "${SENTRY_BACKEND_PROJECT_SLUG:?SENTRY_BACKEND_PROJECT_SLUG ausente no ambiente}"

output="$(cd "$ROOT_DIR/server" && dart run bin/sentry_smoke.dart)"
echo "$output"

event_line="$(printf '%s\n' "$output" | grep -o 'SENTRY_SMOKE_EVENT_ID=[^[:space:]]*' | tail -n1 || true)"
smoke_line="$(printf '%s\n' "$output" | grep -o 'SENTRY_SMOKE_TAG=smoke_id:[^[:space:]]*' | tail -n1 || true)"

if [[ -z "$event_line" ]]; then
  echo "Nao foi possivel extrair o event_id do backend." >&2
  exit 1
fi

if [[ -z "$smoke_line" ]]; then
  echo "Nao foi possivel extrair o smoke_id do backend." >&2
  exit 1
fi

event_id="${event_line#SENTRY_SMOKE_EVENT_ID=}"
smoke_id="${smoke_line#SENTRY_SMOKE_TAG=smoke_id:}"
query_url="https://sentry.io/api/0/projects/${SENTRY_ORG_SLUG}/${SENTRY_BACKEND_PROJECT_SLUG}/events/${event_id}/"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

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
      echo "SENTRY_BACKEND_GROUP_ID=${group_id}"
      echo "SENTRY_BACKEND_EVENT_ID=${event_id}"
      echo "SENTRY_BACKEND_SMOKE_TAG=smoke_id:${smoke_id}"
      exit 0
    fi
  fi

  sleep 5
done

echo "Nao foi encontrado evento no Sentry para event_id:${event_id}." >&2
exit 1
