#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$SCRIPT_DIR/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "ManaLoom product smoke"
require_postgres_write_approval "ManaLoom product smoke direct cleanup"

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
  MANALOOM_API_BASE_URL MANALOOM_EASYPANEL_SSH_HOST \
  MANALOOM_EASYPANEL_SSH_KEY MANALOOM_POSTGRES_DB \
  MANALOOM_POSTGRES_SERVICE MANALOOM_POSTGRES_USER \
  MANALOOM_WEB_PUBLIC_URL

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
WEB="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-${EASYPANEL_SSH_USER:-root}@${EASYPANEL_SERVER_IP:-}}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-}}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"

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

validate_manaloom_release_api_base_url "$BASE"
validate_manaloom_exact_coordinate \
  "web publica" "$WEB" "https://$MANALOOM_PRODUCTION_PUBLIC_HOST"
validate_manaloom_exact_coordinate \
  "destino SSH" "$SSH_HOST" "${MANALOOM_EXPECTED_SSH_TARGET:-}"
validate_manaloom_exact_coordinate \
  "servico PostgreSQL" "$POSTGRES_SERVICE" "evolution_manaloom-postgres"
validate_manaloom_exact_coordinate "usuario PostgreSQL" "$POSTGRES_USER" "postgres"
validate_manaloom_exact_coordinate "database PostgreSQL" "$POSTGRES_DB" "halder"

TMP_DIR="$(mktemp -d)"
TS="$(date +%s)$$"
EMAIL="codex-product-smoke-$TS@example.invalid"
USERNAME="codexproduct$TS"
PASSWORD="Product-$TS"
USER_ID=""
USER_CREATED=0
CLEANUP_PROOF=""

cleanup_user() {
  local output rest deleted_ai deleted_users remaining
  if [[ "$USER_CREATED" != "1" ]]; then
    return 0
  fi
  if [[ ! "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ||
        ! "$EMAIL" =~ ^codex-product-smoke-[0-9]+@example\.invalid$ ]]; then
    echo "identidade product smoke invalida; cleanup recusado" >&2
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
    echo "cleanup remoto do product smoke falhou" >&2
    return 1
  fi
  output="${output//$'\r'/}"
  if [[ "$output" != *$'\n'* ]]; then
    echo "cleanup product smoke sem prova exata: ${output//$'\n'/,}" >&2
    return 1
  fi
  deleted_ai="${output%%$'\n'*}"
  rest="${output#*$'\n'}"
  if [[ "$rest" != *$'\n'* ]]; then
    echo "cleanup product smoke sem contagem de usuario e pos-checagem" >&2
    return 1
  fi
  deleted_users="${rest%%$'\n'*}"
  remaining="${rest#*$'\n'}"
  if [[ ! "$deleted_ai" =~ ^[0-9]+$ || "$deleted_users" != "1" ||
        "$remaining" != "0" || "$remaining" == *$'\n'* ]]; then
    echo "cleanup product smoke deixou usuario residual" >&2
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

curl -fsS "$BASE/health" >"$TMP_DIR/health.json"
curl -fsS "$BASE/ready" >"$TMP_DIR/ready.json"
jq -e '
  .status == "ready" and
  .checks.battle_runtime.status == "healthy" and
  .checks.battle_runtime.mode == "auto" and
  .checks.battle_runtime.engines.xmage.status == "healthy" and
  .checks.battle_runtime.engines.forge.status == "healthy" and
  .checks.battle_runtime.engines.native.status == "healthy"
' "$TMP_DIR/ready.json" >/dev/null
curl -fsS "$WEB/sitemap.xml" >"$TMP_DIR/sitemap.xml"

REG="$(jq -n --arg username "$USERNAME" --arg email "$EMAIL" --arg password "$PASSWORD" '{username:$username,email:$email,password:$password}')"
REG_RESPONSE="$(curl -fsS -X POST "$BASE/auth/register" -H 'Content-Type: application/json' --data "$REG")"
TOKEN="$(printf '%s' "$REG_RESPONSE" | jq -r '.token')"
USER_ID="$(printf '%s' "$REG_RESPONSE" | jq -r '.user.id')"

if [[ "$USER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; then
  USER_CREATED=1
else
  echo "registro product smoke nao retornou user id valido" >&2
  exit 1
fi
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "registro product smoke nao retornou token" >&2
  exit 1
fi

PLAN_BEFORE="$(curl -fsS "$BASE/users/me/plan" -H "Authorization: Bearer $TOKEN")"
CHECKOUT_CODE="$(curl -sS -o "$TMP_DIR/checkout.json" -w '%{http_code}' -X POST "$BASE/users/me/plan/checkout" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"plan_name":"pro"}')"

DECK_PAYLOAD="$(jq -n '{name:"Codex product smoke deck",format:"commander",description:"Smoke temporario",is_public:true,cards:[]}')"
DECK_RESPONSE="$(curl -fsS -X POST "$BASE/decks" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$DECK_PAYLOAD")"
DECK_ID="$(printf '%s' "$DECK_RESPONSE" | jq -r '.id')"

NOTE_PAYLOAD="$(jq -n '{played_at:"2026-07-06T12:00:00.000Z",result:"win",notes:"Smoke temporario",tags:["mana"],performed_well:["Sol Ring"],underperformed:["Island"],issues:["draw"],next_actions:["Ajustar curva"]}')"
NOTE_CODE="$(curl -sS -o "$TMP_DIR/note.json" -w '%{http_code}' -X POST "$BASE/decks/$DECK_ID/post-game-notes" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$NOTE_PAYLOAD")"
TIMELINE_CODE="$(curl -sS -o "$TMP_DIR/timeline.json" -w '%{http_code}' "$BASE/decks/$DECK_ID/post-game-timeline" -H "Authorization: Bearer $TOKEN")"

REPORT_PAYLOAD="$(jq -n '{kind:"optimization",title:"Smoke report",summary:"Smoke temporario",before:{score:62},after:{score:74},recommendations:[{card:"Sol Ring",reason:"Smoke",impact:"mana"}]}')"
REPORT_RESPONSE="$(curl -fsS -X POST "$BASE/decks/$DECK_ID/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$REPORT_PAYLOAD")"
REPORT_ID="$(printf '%s' "$REPORT_RESPONSE" | jq -r '.report.id')"
PUBLIC_URL="$(printf '%s' "$REPORT_RESPONSE" | jq -r '.public_url')"
PUBLIC_API_CODE="$(curl -sS -o "$TMP_DIR/public_api.json" -w '%{http_code}' "$BASE/reports/$REPORT_ID")"
PUBLIC_WEB_CODE="$(curl -sS -o "$TMP_DIR/public_web.html" -w '%{http_code}' "$WEB/reports/$REPORT_ID")"
PUBLIC_DECK_CODE="$(curl -sS -o "$TMP_DIR/public_deck.json" -w '%{http_code}' "$BASE/community/decks/$DECK_ID")"
COMMENT_CODE="$(curl -sS -o "$TMP_DIR/comment.json" -w '%{http_code}' -X POST "$BASE/community/decks/$DECK_ID/comments" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"body":"Smoke de feedback publico."}')"
COMMENT_LIST_CODE="$(curl -sS -o "$TMP_DIR/comments.json" -w '%{http_code}' "$BASE/community/decks/$DECK_ID/comments")"
MODERATION_REPORT_CODE="$(curl -sS -o "$TMP_DIR/moderation_report.json" -w '%{http_code}' -X POST "$BASE/community/decks/$DECK_ID/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"reason":"other","details":"Smoke de moderacao."}')"
TRADE_MATCH_CODE="$(curl -sS -o "$TMP_DIR/trade_matches.json" -w '%{http_code}' "$BASE/community/trade-matches?deck_id=$DECK_ID" -H "Authorization: Bearer $TOKEN")"
DELETE_DECK_CODE="$(curl -sS -o "$TMP_DIR/delete.json" -w '%{http_code}' -X DELETE "$BASE/decks/$DECK_ID" -H "Authorization: Bearer $TOKEN")"

cleanup_user

jq -n \
  --arg api "$BASE" \
  --arg web "$WEB" \
  --arg checkout_code "$CHECKOUT_CODE" \
  --arg checkout_status "$(jq -r '.checkout_status // empty' "$TMP_DIR/checkout.json")" \
  --arg plan_before "$(printf '%s' "$PLAN_BEFORE" | jq -c '.plan')" \
  --arg note_code "$NOTE_CODE" \
  --arg timeline_code "$TIMELINE_CODE" \
  --arg report_id "$REPORT_ID" \
  --arg public_url "$PUBLIC_URL" \
  --arg public_api_code "$PUBLIC_API_CODE" \
  --arg public_web_code "$PUBLIC_WEB_CODE" \
  --arg public_deck_code "$PUBLIC_DECK_CODE" \
  --arg comment_code "$COMMENT_CODE" \
  --arg comment_list_code "$COMMENT_LIST_CODE" \
  --arg moderation_report_code "$MODERATION_REPORT_CODE" \
  --arg trade_match_code "$TRADE_MATCH_CODE" \
  --arg delete_deck_code "$DELETE_DECK_CODE" \
  --arg cleanup "$CLEANUP_PROOF" \
  '{
    status:"ok",
    api:$api,
    web:$web,
    plan_before:($plan_before | fromjson),
    checkout:{code:($checkout_code|tonumber), status:$checkout_status},
    note_code:($note_code|tonumber),
    timeline_code:($timeline_code|tonumber),
    report:{id:$report_id, public_url:$public_url, api_code:($public_api_code|tonumber), web_code:($public_web_code|tonumber)},
    community:{
      public_deck_code:($public_deck_code|tonumber),
      comment_code:($comment_code|tonumber),
      comment_list_code:($comment_list_code|tonumber),
      moderation_report_code:($moderation_report_code|tonumber),
      trade_match_code:($trade_match_code|tonumber)
    },
    delete_deck_code:($delete_deck_code|tonumber),
    cleanup:$cleanup
  }'
