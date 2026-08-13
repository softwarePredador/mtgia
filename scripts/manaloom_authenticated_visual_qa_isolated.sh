#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$_${RANDOM}"
RUN_DIR="${MANALOOM_VISUAL_QA_ROOT:-${TMPDIR:-/tmp}/manaloom_visual_qa}/$RUN_ID"
BACKEND_LOG="$RUN_DIR/backend-fixture.log"
WEB_LOG="$RUN_DIR/web.log"
BUILD_LOG="$RUN_DIR/flutter-build.log"
READY_MANIFEST="$RUN_DIR/ready.json"
CREDENTIALS_FILE="$RUN_DIR/visual-credentials.env"
SUMMARY_FILE="$RUN_DIR/cleanup-summary.json"
WEB_BUILD_DIR="$RUN_DIR/web-build"
ISOLATED_CAPABILITIES_FILE="$RUN_DIR/release-capabilities.visual-fixture.json"
ISOLATED_CAPABILITIES_DIGEST=""
BACKEND_PID=""
WEB_PID=""
DATABASE=""
API_BASE_URL=""
WEB_PORT=""
WEB_URL=""
SEED_EMAIL=""
SEED_USER_ID=""
EMPTY_EMAIL=""
EMPTY_USER_ID=""
SEED_PEER_USER_ID=""
SEED_PEER_USERNAME=""
SEED_CARD_ID=""
SEED_BASIC_LAND_CARD_ID=""
SEED_COMMANDER_CARD_ID=""
SEED_DECK_ID=""
SEED_BINDER_ITEM_ID=""
SEED_PEER_BINDER_ITEM_ID=""
SEED_TRADE_ID=""
readonly SEED_PASSWORD='VisualQA!2026-Deck'

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_flutter_root
FLUTTER_BIN="$MANALOOM_FLUTTER_ROOT_RESOLVED/bin/flutter"

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_legal_policy_versions "$ROOT_DIR"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval \
  "S3-07 visual QA in disposable loopback PostgreSQL"
require_live_mutation_approval \
  "S3-07 visual QA in disposable loopback API"

for tool in curl htpasswd jq pg_isready psql python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done
if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter configurado não é executável: $FLUTTER_BIN" >&2
  exit 2
fi
if ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
  echo "PostgreSQL loopback indisponível em 127.0.0.1:5432" >&2
  exit 2
fi

mkdir -p "$RUN_DIR"

jq '
  .policy_version = (.policy_version + ".isolated_visual_fixture")
  | .implementation_status = "isolated_visual_fixture"
  | .live_verified_as_of = null
  | .capabilities |= with_entries(
      .key as $key
      | if ([
          "account_registration",
          "catalog_private",
          "decks_private",
          "collection_private",
          "life_counter_local",
          "ai_analyze_optimize_advisory",
          "ai_generate_rebuild",
          "battle_batch",
          "battle_live",
          "battle_coach",
          "scanner",
          "gallery_public",
          "profiles_public",
          "comments",
          "follows",
          "user_search",
          "direct_messages",
          "social_push",
          "binder_public",
          "trades",
          "marketplace",
          "learning_reads",
          "legacy_ai_routes",
          "deck_replace_all"
        ] | index($key)) != null
        then .value.implementation_status = "isolated_visual_fixture"
          | .value.release_capability = "on"
          | .value.allowed = true
          | .value.live_verified_as_of = null
        else .value.release_capability = "off"
          | .value.allowed = false
          | .value.live_verified_as_of = null
        end
    )
' "$ROOT_DIR/server/config/release_capabilities.json" \
  >"$ISOLATED_CAPABILITIES_FILE"
ISOLATED_CAPABILITIES_DIGEST="$(
  shasum -a 256 "$ISOLATED_CAPABILITIES_FILE" | awk '{print $1}'
)"

listener_count() {
  local port="$1"
  if [[ -z "$port" ]]; then
    printf '0'
    return
  fi
  lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR > 1 {count++} END {print count + 0}'
}

cleanup() {
  local original_status="$?"
  local database_remaining="unknown"
  local web_listeners="unknown"
  local api_listeners="unknown"
  trap - EXIT INT TERM
  set +e

  if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" >/dev/null 2>&1; then
    kill -TERM "$WEB_PID" >/dev/null 2>&1
    wait "$WEB_PID" >/dev/null 2>&1
  fi
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill -TERM "$BACKEND_PID" >/dev/null 2>&1
    wait "$BACKEND_PID" >/dev/null 2>&1
  fi

  for _ in $(seq 1 200); do
    if [[ -z "$DATABASE" ]] || ! psql -X -h 127.0.0.1 -p 5432 -d postgres \
      -Atc "SELECT 1 FROM pg_database WHERE datname = '$DATABASE'" 2>/dev/null |
      grep -qx 1; then
      database_remaining="0"
      break
    fi
    sleep 0.1
  done
  if [[ "$database_remaining" != "0" && -n "$DATABASE" ]]; then
    database_remaining="1"
  fi

  # The Dart Frog child can release its socket a few milliseconds after its
  # owning shell has completed. Prove convergence instead of sampling once.
  for _ in $(seq 1 200); do
    web_listeners="$(listener_count "$WEB_PORT")"
    if [[ -n "$API_BASE_URL" ]]; then
      api_listeners="$(listener_count "${API_BASE_URL##*:}")"
    else
      api_listeners="0"
    fi
    if [[ "$web_listeners" == "0" && "$api_listeners" == "0" ]]; then
      break
    fi
    sleep 0.1
  done
  web_listeners="$(listener_count "$WEB_PORT")"
  if [[ -n "$API_BASE_URL" ]]; then
    api_listeners="$(listener_count "${API_BASE_URL##*:}")"
  fi

  jq -n \
    --arg scope "disposable_loopback_postgresql_api" \
    --arg run_dir "$RUN_DIR" \
    --arg database "$DATABASE" \
    --arg database_remaining "$database_remaining" \
    --arg web_listeners "$web_listeners" \
    --arg api_listeners "$api_listeners" \
    --argjson original_exit_code "$original_status" \
    '{
      scope: $scope,
      run_dir: $run_dir,
      database: $database,
      database_remaining: ($database_remaining | tonumber? // $database_remaining),
      web_listeners: ($web_listeners | tonumber? // $web_listeners),
      api_listeners: ($api_listeners | tonumber? // $api_listeners),
      original_exit_code: $original_exit_code,
      credentials_file_removed: true,
      capability_policy_file_removed: true
    }' >"$SUMMARY_FILE"
  rm -f "$CREDENTIALS_FILE"
  rm -f "$ISOLATED_CAPABILITIES_FILE"
  printf 'cleanup_summary=%s\n' "$SUMMARY_FILE"

  if [[ "$database_remaining" != "0" || "$web_listeners" != "0" ||
        "$api_listeners" != "0" ]]; then
    echo "cleanup incompleto na fixture visual" >&2
    exit 1
  fi
  exit "$original_status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

MANALOOM_HOLD_FOR_BROWSER_QA=1 \
MANALOOM_ALLOW_DEV_ORIGINS=true \
MANALOOM_E2E_ISOLATED_RUNTIME=1 \
MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="$ISOLATED_CAPABILITIES_FILE" \
MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY \
MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
  "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh" \
  >"$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!

# A cold Dart Frog build can take several minutes on the governed local
# toolchain. Keep the fixture fail-closed, but allow up to ten minutes for its
# READY contract instead of rejecting a healthy first build after 90 seconds.
for _ in $(seq 1 2400); do
  if grep -q '^READY: isolated browser QA fixture$' "$BACKEND_LOG" 2>/dev/null; then
    break
  fi
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    echo "fixture backend encerrou antes de ficar pronta" >&2
    tail -100 "$BACKEND_LOG" >&2 || true
    exit 1
  fi
  sleep 0.25
done

API_BASE_URL="$(sed -n 's/^api_base_url=//p' "$BACKEND_LOG" | tail -n 1)"
DATABASE="$(sed -n 's/^database=//p' "$BACKEND_LOG" | tail -n 1)"
if [[ ! "$API_BASE_URL" =~ ^http://127\.0\.0\.1:[0-9]+$ ||
      ! "$DATABASE" =~ ^manaloom_s1_api_[A-Za-z0-9_]+$ ]]; then
  echo "fixture backend não forneceu coordenadas loopback válidas" >&2
  exit 1
fi

seed_suffix="$(date -u +%s)_$$"
SEED_EMAIL="visual-s307-$seed_suffix@example.invalid"
seed_username="visuals307${seed_suffix//_/}"
EMPTY_EMAIL="visual-empty-$seed_suffix@example.invalid"
empty_username="visualempty${seed_suffix//_/}"
SEED_PEER_USERNAME="visualpeer${seed_suffix//_/}"
peer_email="visual-peer-$seed_suffix@example.invalid"
visual_password_hash="$(
  htpasswd -bnBC 10 '' "$SEED_PASSWORD" | tr -d ':\n'
)"
seeded_users="$(
  psql -X -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 5432 -d "$DATABASE" \
    -At -F '|' \
    -v seed_username="$seed_username" \
    -v seed_email="$SEED_EMAIL" \
    -v empty_username="$empty_username" \
    -v empty_email="$EMPTY_EMAIL" \
    -v peer_username="$SEED_PEER_USERNAME" \
    -v peer_email="$peer_email" \
    -v password_hash="$visual_password_hash" \
    -v terms_version="$MANALOOM_CURRENT_TERMS_VERSION" \
    -v privacy_version="$MANALOOM_CURRENT_PRIVACY_VERSION" <<'SQL'
WITH inserted AS (
  INSERT INTO users (
    username, email, password_hash,
    terms_version, terms_accepted_at,
    privacy_version, privacy_accepted_at
  ) VALUES
    (:'seed_username', :'seed_email', :'password_hash',
     :'terms_version', CURRENT_TIMESTAMP,
     :'privacy_version', CURRENT_TIMESTAMP),
    (:'empty_username', :'empty_email', :'password_hash',
     :'terms_version', CURRENT_TIMESTAMP,
     :'privacy_version', CURRENT_TIMESTAMP),
    (:'peer_username', :'peer_email', :'password_hash',
     :'terms_version', CURRENT_TIMESTAMP,
     :'privacy_version', CURRENT_TIMESTAMP)
  RETURNING id, email
), plans AS (
  INSERT INTO user_plans (user_id, plan_name, status)
  SELECT id, 'free', 'active' FROM inserted
  RETURNING user_id
)
SELECT email, id FROM inserted ORDER BY email;
SQL
)"
SEED_USER_ID="$(awk -F '|' -v email="$SEED_EMAIL" '$1 == email {print $2}' <<<"$seeded_users")"
EMPTY_USER_ID="$(awk -F '|' -v email="$EMPTY_EMAIL" '$1 == email {print $2}' <<<"$seeded_users")"
SEED_PEER_USER_ID="$(awk -F '|' -v email="$peer_email" '$1 == email {print $2}' <<<"$seeded_users")"
for required_user_id in "$SEED_USER_ID" "$EMPTY_USER_ID" "$SEED_PEER_USER_ID"; do
  [[ "$required_user_id" =~ ^[0-9a-f-]{36}$ ]] || {
    echo "direct disposable user seed did not return a UUID" >&2
    exit 1
  }
done

login_fixture_user() {
  local email="$1"
  curl -fsS --max-time 20 \
    -H 'Content-Type: application/json' \
    -d "$(jq -cn --arg email "$email" --arg password "$SEED_PASSWORD" \
      '{email: $email, password: $password}')" \
    "$API_BASE_URL/auth/login"
}
seed_token="$(login_fixture_user "$SEED_EMAIL" | jq -er '.token')"
empty_token="$(login_fixture_user "$EMPTY_EMAIL" | jq -er '.token')"
peer_token="$(login_fixture_user "$peer_email" | jq -er '.token')"

empty_decks_response="$(curl -fsS --max-time 20 \
  -H "Authorization: Bearer $empty_token" \
  "$API_BASE_URL/decks")"
jq -e 'type == "array" and length == 0' \
  <<<"$empty_decks_response" >/dev/null

card_response="$(curl -fsS --max-time 20 \
  -H "Authorization: Bearer $seed_token" \
  "$API_BASE_URL/cards?name=Sol%20Ring&limit=10&dedupe=false")"
SEED_CARD_ID="$(jq -er \
  'first(.data[] | select(.scryfall_id == "00000000-0000-4000-8000-000000000001") | .id)' \
  <<<"$card_response")"
basic_land_response="$(curl -fsS --max-time 20 \
  -H "Authorization: Bearer $seed_token" \
  "$API_BASE_URL/cards?name=Wastes&limit=10")"
SEED_BASIC_LAND_CARD_ID="$(jq -er \
  'first(.data[] | select(.name == "Wastes") | .id)' \
  <<<"$basic_land_response")"
commander_response="$(curl -fsS --max-time 20 \
  -H "Authorization: Bearer $seed_token" \
  "$API_BASE_URL/cards?name=Talrand%2C%20Sky%20Summoner&limit=10")"
SEED_COMMANDER_CARD_ID="$(jq -er \
  'first(.data[] | select(.name == "Talrand, Sky Summoner") | .id)' \
  <<<"$commander_response")"

deck_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $seed_token" \
  -d "$(jq -cn --arg card_id "$SEED_CARD_ID" '{
    name: "S3-07 Visual Fixture",
    format: "commander",
    description: "Disposable authenticated visual regression fixture",
    is_public: true,
    cards: [{card_id: $card_id, quantity: 1, is_commander: false}]
  }')" \
  "$API_BASE_URL/decks")"
SEED_DECK_ID="$(jq -er '.id' <<<"$deck_response")"

peer_deck_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $peer_token" \
  -d "$(jq -cn --arg card_id "$SEED_CARD_ID" '{
    name: "Battle Coach Public Rival",
    format: "commander",
    description: "Disposable public opponent for live interaction proof",
    is_public: true,
    cards: [{card_id: $card_id, quantity: 1, is_commander: false}]
  }')" \
  "$API_BASE_URL/decks")"
SEED_PEER_DECK_ID="$(jq -er '.id' <<<"$peer_deck_response")"

WEB_PORT="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

# The visual baseline must not depend on Scryfall/CDN availability. Point the
# disposable card at a same-origin asset that ships inside the real Web build.
fixture_image_url="http://127.0.0.1:$WEB_PORT/app/assets/assets/branding/visual_fixture_arcane_ring.webp"
psql -X -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 5432 -d "$DATABASE" \
  -v card_id="$SEED_CARD_ID" \
  -v basic_land_card_id="$SEED_BASIC_LAND_CARD_ID" \
  -v commander_card_id="$SEED_COMMANDER_CARD_ID" \
  -v deck_id="$SEED_DECK_ID" \
  -v peer_deck_id="$SEED_PEER_DECK_ID" \
  -v image_url="$fixture_image_url" \
  >"$RUN_DIR/card-image-fixture.log" 2>&1 <<'SQL'
INSERT INTO sets (
  code,
  name,
  release_date,
  type,
  is_online_only,
  is_foreign_only
)
VALUES
  ('TST', 'S3-07 Visual Fixture Set', DATE '2026-07-21', 'expansion', FALSE, FALSE),
  ('T2S', 'S3-07 Foil Archive', DATE '2025-02-03', 'special', FALSE, FALSE)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  release_date = EXCLUDED.release_date,
  type = EXCLUDED.type,
  is_online_only = EXCLUDED.is_online_only,
  is_foreign_only = EXCLUDED.is_foreign_only;

UPDATE cards
SET image_url = :'image_url';

UPDATE cards
SET set_code = 'TST'
WHERE id IN (
  :'card_id'::uuid,
  :'basic_land_card_id'::uuid,
  :'commander_card_id'::uuid
);

DELETE FROM deck_cards
WHERE deck_id IN (:'deck_id'::uuid, :'peer_deck_id'::uuid);

INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
VALUES
  (:'deck_id'::uuid, :'basic_land_card_id'::uuid, 99, FALSE),
  (:'deck_id'::uuid, :'commander_card_id'::uuid, 1, TRUE),
  (:'peer_deck_id'::uuid, :'basic_land_card_id'::uuid, 99, FALSE),
  (:'peer_deck_id'::uuid, :'commander_card_id'::uuid, 1, TRUE)
ON CONFLICT (deck_id, card_id) DO UPDATE SET
  quantity = EXCLUDED.quantity,
  is_commander = EXCLUDED.is_commander;
SQL

deck_validation_response="$(curl -fsS --max-time 20 \
  -X POST \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $seed_token" \
  -d '{}' \
  "$API_BASE_URL/decks/$SEED_DECK_ID/validate")"
peer_deck_validation_response="$(curl -fsS --max-time 20 \
  -X POST \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $peer_token" \
  -d '{}' \
  "$API_BASE_URL/decks/$SEED_PEER_DECK_ID/validate")"
jq -e '.ok == true or .is_valid == true or .valid == true' \
  <<<"$deck_validation_response" >/dev/null
jq -e '.ok == true or .is_valid == true or .valid == true' \
  <<<"$peer_deck_validation_response" >/dev/null

seed_binder_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $seed_token" \
  -d "$(jq -cn --arg card_id "$SEED_CARD_ID" '{
    card_id: $card_id,
    quantity: 3,
    condition: "NM",
    is_foil: false,
    for_trade: true,
    for_sale: false,
    price: 24.5,
    language: "pt-br",
    list_type: "have"
  }')" \
  "$API_BASE_URL/binder")"
SEED_BINDER_ITEM_ID="$(jq -er '.id' <<<"$seed_binder_response")"

peer_binder_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $peer_token" \
  -d "$(jq -cn --arg card_id "$SEED_CARD_ID" '{
    card_id: $card_id,
    quantity: 3,
    condition: "LP",
    is_foil: true,
    for_trade: true,
    for_sale: true,
    price: 32.5,
    language: "ja",
    list_type: "have"
  }')" \
  "$API_BASE_URL/binder")"
SEED_PEER_BINDER_ITEM_ID="$(jq -er '.id' <<<"$peer_binder_response")"

trade_response="$(curl -fsS --max-time 20 \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $seed_token" \
  -d "$(jq -cn \
    --arg receiver_id "$SEED_PEER_USER_ID" \
    --arg my_item_id "$SEED_BINDER_ITEM_ID" \
    --arg requested_item_id "$SEED_PEER_BINDER_ITEM_ID" '{
      receiver_id: $receiver_id,
      type: "trade",
      my_items: [{binder_item_id: $my_item_id, quantity: 1, agreed_price: 24.5}],
      requested_items: [{binder_item_id: $requested_item_id, quantity: 1, agreed_price: 32.5}],
      message: "Fixture visual descartável de identidade física"
    }')" \
  "$API_BASE_URL/trades")"
SEED_TRADE_ID="$(jq -er '.id' <<<"$trade_response")"

(
  cd "$APP_DIR"
  "$FLUTTER_BIN" build web --release --no-pub \
    --base-href /app/ \
    --no-web-resources-cdn \
    --output "$WEB_BUILD_DIR" \
    --dart-define=API_BASE_URL=/api \
    --dart-define=MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES=true \
    --dart-define=MANALOOM_VISUAL_FIXTURE_MODE=true \
    --dart-define=ENABLE_INTERACTIVE_BATTLE=true \
    --dart-define=DISABLE_FIREBASE_STARTUP=true \
    --dart-define=DISABLE_PUSH_INIT=true \
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
) >"$BUILD_LOG" 2>&1

python3 "$APP_DIR/tool/serve_flutter_web_app.py" \
  --host 127.0.0.1 \
  --port "$WEB_PORT" \
  --build-dir "$WEB_BUILD_DIR" \
  --api-upstream "$API_BASE_URL" \
  --allow-loopback-http-api \
  >"$WEB_LOG" 2>&1 &
WEB_PID=$!
WEB_URL="http://127.0.0.1:$WEB_PORT/app/"

for _ in $(seq 1 80); do
  if curl -fsS --max-time 2 "$WEB_URL" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    echo "servidor Web visual encerrou antes de ficar pronto" >&2
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 0.25
done
curl -fsS --max-time 5 "$WEB_URL" >/dev/null

umask 077
{
  printf 'MANALOOM_VISUAL_EMAIL=%q\n' "$SEED_EMAIL"
  printf 'MANALOOM_VISUAL_PASSWORD=%q\n' "$SEED_PASSWORD"
  printf 'MANALOOM_VISUAL_EMPTY_EMAIL=%q\n' "$EMPTY_EMAIL"
  printf 'MANALOOM_VISUAL_EMPTY_PASSWORD=%q\n' "$SEED_PASSWORD"
} >"$CREDENTIALS_FILE"

bundle_sha256="$(shasum -a 256 "$WEB_BUILD_DIR/main.dart.js" | awk '{print $1}')"
jq -n \
  --arg scope "disposable_loopback_postgresql_api" \
  --arg web_url "$WEB_URL" \
  --arg api_base_url "$API_BASE_URL" \
  --arg database "$DATABASE" \
  --arg run_dir "$RUN_DIR" \
  --arg credentials_file "$CREDENTIALS_FILE" \
  --arg seed_user_id "$SEED_USER_ID" \
  --arg empty_user_id "$EMPTY_USER_ID" \
  --arg seed_peer_user_id "$SEED_PEER_USER_ID" \
  --arg seed_peer_username "$SEED_PEER_USERNAME" \
  --arg seed_card_id "$SEED_CARD_ID" \
  --arg seed_basic_land_card_id "$SEED_BASIC_LAND_CARD_ID" \
  --arg seed_commander_card_id "$SEED_COMMANDER_CARD_ID" \
  --arg seed_deck_id "$SEED_DECK_ID" \
  --arg seed_peer_deck_id "$SEED_PEER_DECK_ID" \
  --arg seed_binder_item_id "$SEED_BINDER_ITEM_ID" \
  --arg seed_peer_binder_item_id "$SEED_PEER_BINDER_ITEM_ID" \
  --arg seed_trade_id "$SEED_TRADE_ID" \
  --arg fixture_image_url "$fixture_image_url" \
  --arg bundle_sha256 "$bundle_sha256" \
  --arg capability_policy_digest_sha256 "$ISOLATED_CAPABILITIES_DIGEST" \
  '{
    status: "ready",
    scope: $scope,
    production_coordinates_allowed: false,
    capture_flow_contains_signup: false,
    web_url: $web_url,
    api_base_url: $api_base_url,
    database: $database,
    run_dir: $run_dir,
    credentials_file: $credentials_file,
    seed_user_id: $seed_user_id,
    empty_user_id: $empty_user_id,
    empty_user_has_decks: false,
    seed_peer_user_id: $seed_peer_user_id,
    seed_peer_username: $seed_peer_username,
    seed_card_id: $seed_card_id,
    seed_basic_land_card_id: $seed_basic_land_card_id,
    seed_commander_card_id: $seed_commander_card_id,
    seed_deck_id: $seed_deck_id,
    seed_peer_deck_id: $seed_peer_deck_id,
    seed_binder_item_id: $seed_binder_item_id,
    seed_peer_binder_item_id: $seed_peer_binder_item_id,
    seed_trade_id: $seed_trade_id,
    fixture_image_url: $fixture_image_url,
    bundle_sha256: $bundle_sha256,
    capability_policy: {
      scope: "isolated_visual_fixture",
      digest_sha256: $capability_policy_digest_sha256,
      account_registration: "ui_route_enabled_no_signup_submission",
      learning_writes: false,
      commerce: false
    },
    cleanup: "trap_registered"
  }' >"$READY_MANIFEST"

printf 'READY: S3-07 authenticated visual QA\n'
printf 'ready_manifest=%s\n' "$READY_MANIFEST"
printf 'web_url=%s\n' "$WEB_URL"
printf 'credentials_file=%s\n' "$CREDENTIALS_FILE"
printf 'seed_deck_id=%s\n' "$SEED_DECK_ID"
printf 'seed_card_id=%s\n' "$SEED_CARD_ID"
printf 'empty_user_id=%s\n' "$EMPTY_USER_ID"
printf 'seed_peer_user_id=%s\n' "$SEED_PEER_USER_ID"
printf 'seed_peer_deck_id=%s\n' "$SEED_PEER_DECK_ID"
printf 'seed_binder_item_id=%s\n' "$SEED_BINDER_ITEM_ID"
printf 'seed_peer_binder_item_id=%s\n' "$SEED_PEER_BINDER_ITEM_ID"
printf 'seed_trade_id=%s\n' "$SEED_TRADE_ID"
printf 'bundle_sha256=%s\n' "$bundle_sha256"
printf 'Press Ctrl+C to stop and prove cleanup.\n'

while kill -0 "$WEB_PID" >/dev/null 2>&1 &&
      kill -0 "$BACKEND_PID" >/dev/null 2>&1; do
  sleep 1
done

echo "fixture visual encerrou inesperadamente" >&2
exit 1
