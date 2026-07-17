#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)"
# This smoke authenticates against production and may create telemetry/AI work.
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "smoke de recomendacoes na API de producao"
readonly LIVE_MUTATION_APPROVED=1
: "$LIVE_MUTATION_APPROVED"

API="${MANALOOM_RECO_SMOKE_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
if [[ "$API" != "https://evolution-cartinhas.2ta7qx.easypanel.host" ]]; then
  echo "API do smoke de recomendacoes deve ser a origem HTTPS aprovada" >&2
  exit 2
fi
: "${MANALOOM_RECO_SMOKE_QA_EMAIL:?MANALOOM_RECO_SMOKE_QA_EMAIL ausente}"
: "${MANALOOM_RECO_SMOKE_QA_PASSWORD:?MANALOOM_RECO_SMOKE_QA_PASSWORD ausente}"
for tool in curl jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

login_payload="$(jq -cn \
  --arg email "$MANALOOM_RECO_SMOKE_QA_EMAIL" \
  --arg password "$MANALOOM_RECO_SMOKE_QA_PASSWORD" \
  '{email:$email,password:$password}')"
login_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  --data "$login_payload" \
  "$API/auth/login")"
token="$(jq -er '.token | select(type == "string" and length > 20)' <<<"$login_response")"

decks_json="$(curl -fsS --max-time 20 \
  -H "Authorization: Bearer $token" \
  "$API/decks")"
deck_id="$(jq -er \
  '(.decks // .) | map(select((.card_count // 0) > 0)) | first | .id' \
  <<<"$decks_json")"

recommendation="$(curl -fsS --max-time 30 -X POST \
  -H "Authorization: Bearer $token" \
  -H 'Content-Type: application/json' \
  "$API/decks/$deck_id/recommendations")"
jq -e 'type == "object" or type == "array"' <<<"$recommendation" >/dev/null
printf '{"status":"passed","deck_id":"%s","token_redacted":true}\n' "$deck_id"
