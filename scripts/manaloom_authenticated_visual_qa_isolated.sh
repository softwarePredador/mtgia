#!/usr/bin/env bash
set +x
set -euo pipefail

# Capture inherited credentials before invoking any non-database child.
FIXTURE_DB_PASSWORD="${DB_PASS:-}"
export -n FIXTURE_DB_PASSWORD
unset DB_PASS PGPASSWORD
# libpq service/hostaddr may otherwise override explicit loopback coordinates.
unset PGHOSTADDR PGSERVICE PGSERVICEFILE PGSYSCONFDIR PGPASSFILE
export PGCONNECT_TIMEOUT=5

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
INACTIVE_BATCH_PORT=""
INACTIVE_INTERACTIVE_PORT=""
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
resolve_manaloom_dart
FLUTTER_BIN="$MANALOOM_FLUTTER_ROOT_RESOLVED/bin/flutter"
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"
export MANALOOM_DART_BIN="$DART_BIN"
dart_bin_dir="$(dirname "$DART_BIN")"
export PATH="$dart_bin_dir:$MANALOOM_FLUTTER_ROOT_RESOLVED/bin:$PATH"

# shellcheck source=scripts/lib/manaloom_safe_env.sh
source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
load_manaloom_legal_policy_versions "$ROOT_DIR"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval \
  "S3-07 visual QA in disposable loopback PostgreSQL"
require_live_mutation_approval \
  "S3-07 visual QA in disposable loopback API"

for tool in curl htpasswd jq lsof pg_isready psql python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$(id -un)}"
DB_ADMIN="${MANALOOM_S1_PG_ADMIN_DB:-postgres}"
case "$DB_HOST" in
  127.0.0.1) ;;
  *) echo "fixture visual aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac
if [[ ! "$DB_PORT" =~ ^[0-9]{1,5}$ ]] ||
   ((10#$DB_PORT < 1 || 10#$DB_PORT > 65535)); then
  echo "porta PostgreSQL inválida" >&2
  exit 2
fi
if [[ ! "$DB_ADMIN" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "admin database inválido" >&2
  exit 2
fi
export DB_HOST DB_PORT DB_USER
export MANALOOM_S1_PG_ADMIN_DB="$DB_ADMIN"
run_visual_pg() (
  export PGPASSWORD="$FIXTURE_DB_PASSWORD"
  exec "$@"
)

verify_empty_session_list() {
  local session_count http_status
  # Listing nonempty rows may expire/reconcile sessions. A globally empty
  # disposable table is mandatory BEFORE sending even this authenticated GET.
  session_count="$(run_visual_pg psql -X -A -t \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
    -c 'SELECT COUNT(*) FROM interactive_battle_sessions' | tr -d '[:space:]')" || return 1
  [[ "$session_count" == 0 ]] || return 1
  [[ "$(listener_count "$INACTIVE_BATCH_PORT")" == 0 ]] || return 1
  [[ "$(listener_count "$INACTIVE_INTERACTIVE_PORT")" == 0 ]] || return 1
  http_status="$(curl -sS --max-time 20 \
    -H "Authorization: Bearer $seed_token" \
    -o "$RUN_DIR/empty-session-list.json" -w '%{http_code}' \
    "$API_BASE_URL/ai/battle/sessions?deck_id=$SEED_DECK_ID&limit=20")" || return 1
  [[ "$http_status" == 200 ]] || return 1
  jq -e '.schema_version == "interactive_battle_session_list_v1" and .sessions == []' \
    "$RUN_DIR/empty-session-list.json" >/dev/null || return 1
}
if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter configurado não é executável: $FLUTTER_BIN" >&2
  exit 2
fi
if ! run_visual_pg pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  >/dev/null 2>&1; then
  echo "PostgreSQL loopback indisponível em $DB_HOST:$DB_PORT" >&2
  exit 2
fi

RUN_OWNED=0
VISUAL_READY=0
BACKEND_RECEIPT_DIR="$RUN_DIR/backend-receipts"
BACKEND_COMPLETION_FILE="$RUN_DIR/backend-complete"
COMPLETION_FILE="$RUN_DIR/complete"

listener_count() {
  local port="$1"
  local listeners=""
  local lookup_exit=0
  [[ -n "$port" ]] || { printf '0'; return; }
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>"$RUN_DIR/listener-check.log")" ||
    lookup_exit=$?
  if [[ -s "$RUN_DIR/listener-check.log" || "$lookup_exit" -gt 1 ]]; then
    printf 'unknown'
    return 1
  fi
  printf '%s\n' "$listeners" | awk 'NR > 1 {count++} END {print count + 0}'
}

stop_visual_child() {
  local child="$1"
  local child_exit=0
  local wait_ticks=100
  [[ -n "$child" ]] || return 0
  [[ "$child" != "$BACKEND_PID" ]] || wait_ticks=600
  if kill -0 "$child" >/dev/null 2>&1; then
    kill -TERM "$child" >/dev/null 2>&1 || return 1
    for _ in $(seq 1 "$wait_ticks"); do
      kill -0 "$child" >/dev/null 2>&1 || break
      sleep 0.1
    done
    if kill -0 "$child" >/dev/null 2>&1; then
      # The backend owns bootstrap descendants and PRE restoration. Never
      # KILL that owner; retain its run/backup and report cleanup failure.
      [[ "$child" != "$BACKEND_PID" ]] || return 1
      kill -KILL "$child" >/dev/null 2>&1
      wait "$child" >/dev/null 2>&1
      return 1
    fi
  fi
  wait "$child" >/dev/null 2>&1 || child_exit=$?
  case "$child_exit" in 0|130|143) ;; *) return 1 ;; esac
  ! kill -0 "$child" >/dev/null 2>&1
}

cleanup() {
  local original_status="$?"
  local cleanup_status=0
  local database_remaining=0
  local web_listeners=0
  local api_listeners=0
  local backend_exit=0
  local backend_cleanup=not_started
  trap - EXIT HUP INT TERM
  set +e
  [[ "$RUN_OWNED" == 1 ]] || exit "$original_status"

  stop_visual_child "$WEB_PID" || cleanup_status=1
  if [[ -n "$BACKEND_PID" ]]; then
    if [[ "$VISUAL_READY" == 1 ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      printf 'complete\n' >"$BACKEND_COMPLETION_FILE" || cleanup_status=1
      for _ in $(seq 1 300); do
        kill -0 "$BACKEND_PID" >/dev/null 2>&1 || break
        sleep 0.1
      done
      if kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
        stop_visual_child "$BACKEND_PID"
        cleanup_status=1
      else
        wait "$BACKEND_PID" >/dev/null 2>&1 || backend_exit=$?
        [[ "$backend_exit" == 0 ]] || cleanup_status=1
      fi
    else
      stop_visual_child "$BACKEND_PID" || cleanup_status=1
    fi
    # Receipt must belong to this child run and is consumed only after wait.
    local child_receipt="$BACKEND_RECEIPT_DIR/cleanup.txt"
    local receipt_database=""
    local receipt_run_id=""
    if [[ -f "$child_receipt" && ! -L "$child_receipt" ]]; then
      receipt_database="$(sed -n 's/^database=//p' "$child_receipt")"
      receipt_run_id="$(sed -n 's/^run_id=//p' "$child_receipt")"
      if [[ "$receipt_run_id" =~ ^[0-9]{8}T[0-9]{6}Z_${BACKEND_PID}$ &&
            "$receipt_database" == "manaloom_s1_api_$receipt_run_id" &&
            ( -z "$DATABASE" || "$DATABASE" == "$receipt_database" ) ]] &&
         awk -F= 'NF != 2 || seen[$1]++ {bad=1} END {exit bad}' "$child_receipt" &&
         grep -qx 'result=pass' "$child_receipt" &&
         grep -qx 'database_remaining=0' "$child_receipt" &&
         grep -qx 'api_listeners=0' "$child_receipt" &&
         grep -qx 'email_fixture_listeners=0' "$child_receipt" &&
         grep -qx 'forced_kill_used=0' "$child_receipt" &&
         grep -qx 'build_baseline_restored=true' "$child_receipt"; then
        DATABASE="$receipt_database"
        backend_cleanup=pass
      else
        backend_cleanup=fail
        cleanup_status=1
      fi
    else
      backend_cleanup=missing
      cleanup_status=1
    fi
  fi
  # A failed query is unknown, never an empty database.
  if [[ -n "$DATABASE" ]]; then
    if ! database_remaining="$(
      run_visual_pg psql -X -A -t \
        -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_ADMIN" \
        -c "SELECT COUNT(*) FROM pg_database WHERE datname = '$DATABASE'" \
        2>"$RUN_DIR/database-cleanup-check.log" | tr -d '[:space:]'
    )"; then
      database_remaining=unknown
      cleanup_status=1
    fi
  fi
  web_listeners="$(listener_count "$WEB_PORT")" || cleanup_status=1
  if [[ -n "$API_BASE_URL" ]]; then
    api_listeners="$(listener_count "${API_BASE_URL##*:}")" || cleanup_status=1
  fi
  [[ "$database_remaining" == 0 && "$web_listeners" == 0 &&
     "$api_listeners" == 0 ]] || cleanup_status=1

  rm -f -- "$CREDENTIALS_FILE" "$ISOLATED_CAPABILITIES_FILE" || cleanup_status=1
  [[ ! -e "$CREDENTIALS_FILE" && ! -L "$CREDENTIALS_FILE" &&
     ! -e "$ISOLATED_CAPABILITIES_FILE" && ! -L "$ISOLATED_CAPABILITIES_FILE" ]] ||
    cleanup_status=1
  if [[ "$web_listeners" == 0 && "$cleanup_status" == 0 ]]; then
    rm -rf -- "$WEB_BUILD_DIR" || cleanup_status=1
  fi

  jq -n \
    --arg result "$([[ "$cleanup_status" == 0 ]] && printf pass || printf fail)" \
    --arg scope "disposable_loopback_postgresql_api" \
    --arg run_id "$RUN_ID" --arg run_dir "$RUN_DIR" \
    --arg backend_cleanup "$backend_cleanup" \
    --arg database "$DATABASE" --arg database_remaining "$database_remaining" \
    --arg web_listeners "$web_listeners" --arg api_listeners "$api_listeners" \
    --argjson credentials_removed "$([[ ! -e "$CREDENTIALS_FILE" && ! -L "$CREDENTIALS_FILE" ]] && printf true || printf false)" \
    --argjson policy_removed "$([[ ! -e "$ISOLATED_CAPABILITIES_FILE" && ! -L "$ISOLATED_CAPABILITIES_FILE" ]] && printf true || printf false)" \
    --argjson original_exit_code "$original_status" \
    '{
      result: $result, scope: $scope, run_id: $run_id, run_dir: $run_dir,
      backend_cleanup: $backend_cleanup,
      database: $database,
      database_remaining: ($database_remaining | tonumber? // $database_remaining),
      web_listeners: ($web_listeners | tonumber? // $web_listeners),
      api_listeners: ($api_listeners | tonumber? // $api_listeners),
      original_exit_code: $original_exit_code,
      credentials_file_removed: $credentials_removed,
      capability_policy_file_removed: $policy_removed
    }' >"$SUMMARY_FILE" || cleanup_status=1
  printf 'cleanup_summary=%s\n' "$SUMMARY_FILE"
  if [[ "$cleanup_status" != 0 ]]; then
    echo "cleanup incompleto na fixture visual" >&2
    [[ "$original_status" != 0 ]] || original_status=1
  fi
  exit "$original_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$(dirname -- "$RUN_DIR")"
mkdir -m 700 "$RUN_DIR"
RUN_OWNED=1
mkdir -m 700 "$BACKEND_RECEIPT_DIR"

jq '
  .policy_version = (.policy_version + ".isolated_visual_fixture")
  | .implementation_status = "experimental_guarded"
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
        then .value.implementation_status = "experimental_guarded"
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

# These are deliberately INACTIVE destinations, not XMage instances. The
# welcome proof reads an empty PG list only; it must never create a session.
read -r INACTIVE_BATCH_PORT INACTIVE_INTERACTIVE_PORT <<<"$(python3 - <<'PY'
import socket
with socket.socket() as batch, socket.socket() as interactive:
    batch.bind(('127.0.0.1', 0))
    interactive.bind(('127.0.0.1', 0))
    print(batch.getsockname()[1], interactive.getsockname()[1])
PY
)"
[[ "$INACTIVE_BATCH_PORT" =~ ^[0-9]+$ && "$INACTIVE_INTERACTIVE_PORT" =~ ^[0-9]+$ ]]
[[ "$INACTIVE_BATCH_PORT" != "$INACTIVE_INTERACTIVE_PORT" ]]
[[ "$(listener_count "$INACTIVE_BATCH_PORT")" == 0 ]]
[[ "$(listener_count "$INACTIVE_INTERACTIVE_PORT")" == 0 ]]

(
  export DB_PASS="$FIXTURE_DB_PASSWORD"
  export INTERACTIVE_BATTLE_ENABLED=true \
    XMAGE_SIDECAR_URL="http://127.0.0.1:$INACTIVE_BATCH_PORT" \
    XMAGE_INTERACTIVE_SIDECAR_URL="http://127.0.0.1:$INACTIVE_INTERACTIVE_PORT"
  export MANALOOM_HOLD_FOR_BROWSER_QA=1 \
    MANALOOM_BROWSER_QA_COMPLETION_FILE="$BACKEND_COMPLETION_FILE" \
    MANALOOM_ISOLATED_E2E_RECEIPT_DIR="$BACKEND_RECEIPT_DIR" \
    MANALOOM_ALLOW_DEV_ORIGINS=true \
    MANALOOM_E2E_ISOLATED_RUNTIME=1 \
    MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="$ISOLATED_CAPABILITIES_FILE" \
    MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  exec "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh"
) >"$BACKEND_LOG" 2>&1 &
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
  run_visual_pg psql -X -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
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
    name: "Play vs AI Opponent",
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
run_visual_pg psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
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

verify_empty_session_list || {
  echo "welcome fixture requires inactive loopback destinations and a real empty session list" >&2
  exit 1
}

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
  --arg completion_file "$COMPLETION_FILE" \
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
  --arg inactive_batch_url "http://127.0.0.1:$INACTIVE_BATCH_PORT" \
  --arg inactive_interactive_url "http://127.0.0.1:$INACTIVE_INTERACTIVE_PORT" \
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
    completion_file: $completion_file,
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
    interactive_welcome_fixture: {
      scope: "empty session list from disposable PostgreSQL",
      session_count: 0,
      engine: "NOT_STARTED",
      readiness: "NOT_PROVEN",
      inactive_batch_url: $inactive_batch_url,
      inactive_interactive_url: $inactive_interactive_url,
      sidecar_listeners: 0
    },
    capability_policy: {
      scope: "isolated_visual_fixture",
      digest_sha256: $capability_policy_digest_sha256,
      account_registration: "ui_route_enabled_no_signup_submission",
      learning_writes: false,
      commerce: false
    },
    cleanup: "trap_registered"
  }' >"$READY_MANIFEST"

VISUAL_READY=1
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
  if [[ -f "$COMPLETION_FILE" && ! -L "$COMPLETION_FILE" ]]; then
    [[ "$(tr -d '\r\n' <"$COMPLETION_FILE")" == complete ]] || exit 1
    exit 0
  fi
  sleep 1
done

echo "fixture visual encerrou inesperadamente" >&2
exit 1
