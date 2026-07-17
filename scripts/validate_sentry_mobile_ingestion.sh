#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "validacao de ingestao Sentry mobile"
readonly LIVE_MUTATION_APPROVED=1
: "$LIVE_MUTATION_APPROVED"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo de ambiente nao encontrado: $ENV_FILE" >&2
  exit 1
fi

CALLER_FLUTTER_BIN="${MANALOOM_FLUTTER_BIN_RESOLVED:-}"
CALLER_EXPECTED_RELEASE="${MANALOOM_EXPECTED_SENTRY_RELEASE:-}"
CALLER_INSTALL_SESSION="${MANALOOM_OBSERVABILITY_SESSION_ID:-}"

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_env_keys "$ENV_FILE" \
  SENTRY_AUTH_TOKEN SENTRY_MOBILE_PROJECT_SLUG SENTRY_ORG_SLUG

MANALOOM_FLUTTER_BIN_RESOLVED="$CALLER_FLUTTER_BIN"
MANALOOM_EXPECTED_SENTRY_RELEASE="$CALLER_EXPECTED_RELEASE"
MANALOOM_OBSERVABILITY_SESSION_ID="$CALLER_INSTALL_SESSION"
readonly MANALOOM_FLUTTER_BIN_RESOLVED
readonly MANALOOM_EXPECTED_SENTRY_RELEASE
readonly MANALOOM_OBSERVABILITY_SESSION_ID
export MANALOOM_FLUTTER_BIN_RESOLVED
export MANALOOM_EXPECTED_SENTRY_RELEASE
export MANALOOM_OBSERVABILITY_SESSION_ID

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN ausente no ambiente}"
: "${SENTRY_ORG_SLUG:?SENTRY_ORG_SLUG ausente no ambiente}"
: "${SENTRY_MOBILE_PROJECT_SLUG:?SENTRY_MOBILE_PROJECT_SLUG ausente no ambiente}"
: "${MANALOOM_EXPECTED_SENTRY_RELEASE:?MANALOOM_EXPECTED_SENTRY_RELEASE ausente}"
: "${MANALOOM_OBSERVABILITY_SESSION_ID:?MANALOOM_OBSERVABILITY_SESSION_ID ausente}"

tmp_output="$(mktemp)"
response_file="$(mktemp)"
trap 'rm -f "$tmp_output" "$response_file"' EXIT

set +e
"$ROOT_DIR/scripts/validate_sentry_mobile_local.sh" "$@" | tee "$tmp_output"
local_exit_code=${PIPESTATUS[0]}
set -e

if [[ "$local_exit_code" -ne 0 ]]; then
  if grep -q 'SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1' "$tmp_output"; then
    echo "Validacao mobile bloqueada por toolchain/build antes da ingestao no Sentry." >&2
  fi
  exit "$local_exit_code"
fi

event_line="$(grep -o 'SENTRY_MOBILE_EVENT_ID=[^[:space:]]*' "$tmp_output" | tail -n1 || true)"
smoke_line="$(grep -o 'SENTRY_MOBILE_SMOKE_TAG=smoke_id:[^[:space:]]*' "$tmp_output" | tail -n1 || true)"
release_line="$(grep -o 'SENTRY_MOBILE_RELEASE=[^[:space:]]*' "$tmp_output" | tail -n1 || true)"
session_line="$(grep -o 'SENTRY_MOBILE_INSTALL_SESSION=[^[:space:]]*' "$tmp_output" | tail -n1 || true)"

if [[ -z "$event_line" ]]; then
  echo "Nao foi possivel extrair o event_id do teste mobile." >&2
  exit 1
fi

if [[ -z "$smoke_line" ]]; then
  echo "Nao foi possivel extrair o smoke_id do teste mobile." >&2
  exit 1
fi

if [[ "$release_line" != "SENTRY_MOBILE_RELEASE=$MANALOOM_EXPECTED_SENTRY_RELEASE" ||
      "$session_line" != "SENTRY_MOBILE_INSTALL_SESSION=$MANALOOM_OBSERVABILITY_SESSION_ID" ]]; then
  echo "Teste Sentry nao preservou release/session esperados" >&2
  exit 1
fi

event_id="${event_line#SENTRY_MOBILE_EVENT_ID=}"
smoke_id="${smoke_line#SENTRY_MOBILE_SMOKE_TAG=smoke_id:}"
query_url="https://sentry.io/api/0/projects/${SENTRY_ORG_SLUG}/${SENTRY_MOBILE_PROJECT_SLUG}/events/${event_id}/"

echo "Consultando Sentry para event_id:${event_id}..."

for _attempt in {1..12}; do
  http_code="$(curl -sS \
    -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
    "$query_url" \
    -o "$response_file" \
    -w '%{http_code}' || true)"

  if [[ "$http_code" == "200" ]]; then
    if python3 - "$event_id" "$smoke_id" "$MANALOOM_EXPECTED_SENTRY_RELEASE" "$MANALOOM_OBSERVABILITY_SESSION_ID" "$response_file" <<'PY'
import json
import sys

event_id = sys.argv[1]
smoke_id = sys.argv[2]
expected_release = sys.argv[3]
install_session_id = sys.argv[4]
response_file = sys.argv[5]

with open(response_file, 'r', encoding='utf-8') as fh:
    payload = json.load(fh)

text = json.dumps(payload)
tags = payload.get('tags') or []
tag_map = {
    str(tag.get('key')): str(tag.get('value'))
    for tag in tags
    if isinstance(tag, dict)
}
release = str(payload.get('release') or tag_map.get('release') or '')
valid = (
    event_id in text
    and smoke_id in text
    and release == expected_release
    and tag_map.get('install_session_id') == install_session_id
)
raise SystemExit(0 if valid else 1)
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
      echo "SENTRY_MOBILE_RELEASE=${MANALOOM_EXPECTED_SENTRY_RELEASE}"
      echo "SENTRY_MOBILE_INSTALL_SESSION=${MANALOOM_OBSERVABILITY_SESSION_ID}"
      exit 0
    fi
  fi

  sleep 5
done

echo "Nao foi encontrado evento no Sentry para event_id:${event_id}." >&2
exit 1
