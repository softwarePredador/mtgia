#!/usr/bin/env bash
set -euo pipefail

BASE="${MANALOOM_API_BASE_URL:-https://evolution-cartinhas.2ta7qx.easypanel.host}"
WEB="${MANALOOM_WEB_PUBLIC_URL:-https://evolution-manaloom-web-public.2ta7qx.easypanel.host}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}"
POSTGRES_SERVICE="${MANALOOM_POSTGRES_SERVICE:-evolution_manaloom-postgres}"
POSTGRES_USER="${MANALOOM_POSTGRES_USER:-postgres}"
POSTGRES_DB="${MANALOOM_POSTGRES_DB:-halder}"

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $1" >&2
    exit 2
  }
}

require_tool curl
require_tool jq
require_tool ssh

TS="$(date +%s)"
EMAIL="codex-product-smoke-$TS@example.invalid"
USERNAME="codexproduct$TS"
PASSWORD="Product-$TS"

cleanup_user() {
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_HOST" \
    "cid=\$(docker ps --filter label=com.docker.swarm.service.name=$POSTGRES_SERVICE --format '{{.ID}}' | head -n 1); test -n \"\$cid\"; docker exec \"\$cid\" psql -U '$POSTGRES_USER' -d '$POSTGRES_DB' -v ON_ERROR_STOP=1 -c \"DELETE FROM users WHERE email = '$EMAIL';\"" \
    >/tmp/manaloom_product_smoke_cleanup.out 2>/tmp/manaloom_product_smoke_cleanup.err || true
}
trap cleanup_user EXIT

curl -fsS "$BASE/health" >/tmp/manaloom_product_smoke_health.json
curl -fsS "$BASE/ready" >/tmp/manaloom_product_smoke_ready.json
curl -fsS "$BASE/health/commercial" >/tmp/manaloom_product_smoke_commercial.json
curl -fsS "$WEB/sitemap.xml" >/tmp/manaloom_product_smoke_sitemap.xml

REG="$(jq -n --arg username "$USERNAME" --arg email "$EMAIL" --arg password "$PASSWORD" '{username:$username,email:$email,password:$password}')"
REG_RESPONSE="$(curl -fsS -X POST "$BASE/auth/register" -H 'Content-Type: application/json' --data "$REG")"
TOKEN="$(printf '%s' "$REG_RESPONSE" | jq -r '.token')"

PLAN_BEFORE="$(curl -fsS "$BASE/users/me/plan" -H "Authorization: Bearer $TOKEN")"
CHECKOUT_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_checkout.json -w '%{http_code}' -X POST "$BASE/users/me/plan/checkout" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"plan_name":"pro"}')"

DECK_PAYLOAD="$(jq -n '{name:"Codex product smoke deck",format:"commander",description:"Smoke temporario",is_public:true,cards:[]}')"
DECK_RESPONSE="$(curl -fsS -X POST "$BASE/decks" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$DECK_PAYLOAD")"
DECK_ID="$(printf '%s' "$DECK_RESPONSE" | jq -r '.id')"

NOTE_PAYLOAD="$(jq -n '{played_at:"2026-07-06T12:00:00.000Z",result:"win",notes:"Smoke temporario",tags:["mana"],performed_well:["Sol Ring"],underperformed:["Island"],issues:["draw"],next_actions:["Ajustar curva"]}')"
NOTE_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_note.json -w '%{http_code}' -X POST "$BASE/decks/$DECK_ID/post-game-notes" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$NOTE_PAYLOAD")"
TIMELINE_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_timeline.json -w '%{http_code}' "$BASE/decks/$DECK_ID/post-game-timeline" -H "Authorization: Bearer $TOKEN")"

REPORT_PAYLOAD="$(jq -n '{kind:"optimization",title:"Smoke report",summary:"Smoke temporario",before:{score:62},after:{score:74},recommendations:[{card:"Sol Ring",reason:"Smoke",impact:"mana"}]}')"
REPORT_RESPONSE="$(curl -fsS -X POST "$BASE/decks/$DECK_ID/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data "$REPORT_PAYLOAD")"
REPORT_ID="$(printf '%s' "$REPORT_RESPONSE" | jq -r '.report.id')"
PUBLIC_URL="$(printf '%s' "$REPORT_RESPONSE" | jq -r '.public_url')"
PUBLIC_API_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_public_api.json -w '%{http_code}' "$BASE/reports/$REPORT_ID")"
PUBLIC_WEB_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_public_web.html -w '%{http_code}' "$WEB/reports/$REPORT_ID")"
PUBLIC_DECK_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_public_deck.json -w '%{http_code}' "$BASE/community/decks/$DECK_ID")"
COMMENT_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_comment.json -w '%{http_code}' -X POST "$BASE/community/decks/$DECK_ID/comments" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"body":"Smoke de feedback publico."}')"
COMMENT_LIST_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_comments.json -w '%{http_code}' "$BASE/community/decks/$DECK_ID/comments")"
MODERATION_REPORT_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_moderation_report.json -w '%{http_code}' -X POST "$BASE/community/decks/$DECK_ID/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data '{"reason":"other","details":"Smoke de moderacao."}')"
TRADE_MATCH_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_trade_matches.json -w '%{http_code}' "$BASE/community/trade-matches?deck_id=$DECK_ID" -H "Authorization: Bearer $TOKEN")"
DELETE_DECK_CODE="$(curl -sS -o /tmp/manaloom_product_smoke_delete.json -w '%{http_code}' -X DELETE "$BASE/decks/$DECK_ID" -H "Authorization: Bearer $TOKEN")"

cleanup_user
trap - EXIT

jq -n \
  --arg api "$BASE" \
  --arg web "$WEB" \
  --arg checkout_code "$CHECKOUT_CODE" \
  --arg checkout_status "$(jq -r '.checkout_status // empty' /tmp/manaloom_product_smoke_checkout.json)" \
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
  --arg cleanup "$(cat /tmp/manaloom_product_smoke_cleanup.out)" \
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
