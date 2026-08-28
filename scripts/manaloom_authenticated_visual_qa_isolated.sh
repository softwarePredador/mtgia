#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST-127.0.0.1}"
DB_PORT="${DB_PORT-5432}"
DB_USER_SET="${DB_USER+x}"
DB_USER_VALUE="${DB_USER-}"
DB_PASS="${DB_PASS-}"
DB_ADMIN="${DB_ADMIN-${MANALOOM_S1_PG_ADMIN_DB-postgres}}"
export -n DB_HOST DB_PORT DB_USER DB_PASS DB_ADMIN MANALOOM_S1_PG_ADMIN_DB
unset MANALOOM_S1_PG_ADMIN_DB

if [[ "$DB_HOST" != "127.0.0.1" ]]; then
  echo "BLOCKED: a fixture visual aceita somente DB_HOST loopback literal" >&2
  exit 2
fi
if [[ ! "$DB_PORT" =~ ^[0-9]+$ || ${#DB_PORT} -gt 5 ]]; then
  echo "BLOCKED: DB_PORT deve ser uma porta numérica válida" >&2
  exit 2
fi
DB_PORT_NUMBER=$((10#$DB_PORT))
if ((DB_PORT_NUMBER < 1 || DB_PORT_NUMBER > 65535)); then
  echo "BLOCKED: DB_PORT deve estar entre 1 e 65535" >&2
  exit 2
fi
if [[ "$DB_USER_SET" == "x" ]]; then
  DB_USER="$DB_USER_VALUE"
else
  DB_USER="$(id -un)"
fi
unset DB_USER_SET DB_USER_VALUE
if [[ ! "$DB_USER" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
  echo "BLOCKED: DB_USER local inválido" >&2
  exit 2
fi
if [[ ! "$DB_ADMIN" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
  echo "BLOCKED: banco administrativo local inválido" >&2
  exit 2
fi
readonly DB_HOST DB_PORT DB_PORT_NUMBER DB_USER DB_PASS DB_ADMIN

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
GLOBAL_CLEANUP_RECEIPT="$RUN_DIR/global-cleanup-receipt.json"
WEB_BUILD_DIR="$RUN_DIR/web-build"
ISOLATED_CAPABILITIES_FILE="$RUN_DIR/release-capabilities.visual-fixture.json"
ISOLATED_CAPABILITIES_DIGEST=""
BACKEND_PID=""
BACKEND_PGID=""
WEB_PID=""
WEB_PGID=""
BACKEND_RUN_ID=""
BACKEND_PARENT_VISUAL_RUN_ID=""
BACKEND_RUN_DIR=""
BACKEND_CLEANUP_RECEIPT=""
BACKEND_CLEANUP_RECEIPT_SHA256=""
BACKEND_API_PORT=""
BACKEND_EMAIL_PORT=""
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
readonly CHROMEDRIVER_PORT=4444
CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
OWNED_GROUP_REMAINING="unknown"
BACKEND_GROUP_REMAINING="unknown"
WEB_GROUP_REMAINING="unknown"
DATABASE_REMAINING="unknown"
API_LISTENERS="unknown"
WEB_LISTENERS="unknown"
CHROMEDRIVER_LISTENERS="unknown"
CHROMEDRIVER_PROCESSES="unknown"
BACKEND_RECEIPT_STATUS="not_checked"
CREDENTIALS_FILE_REMOVED="false"
CAPABILITY_POLICY_FILE_REMOVED="false"
WEB_BUILD_REMAINING="unknown"
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

for tool in awk curl htpasswd jq lsof pgrep pg_isready ps psql python3 \
  shasum tr; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done
if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter configurado não é executável: $FLUTTER_BIN" >&2
  exit 2
fi

run_configured_pg() (
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export PGPASSWORD="$DB_PASS"
  exec "$@"
)

configured_pg_isready() {
  run_configured_pg pg_isready \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_ADMIN" -t 3
}

configured_psql() {
  run_configured_pg psql -X -w \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"
}

if ! configured_pg_isready >/dev/null 2>&1; then
  echo "PostgreSQL loopback configurado indisponível" >&2
  exit 2
fi
postgres_identity=""
if ! postgres_identity="$(
  configured_psql -d "$DB_ADMIN" -At -F '|' \
    -c 'SELECT current_user, current_database()' 2>/dev/null
)" || [[ "$postgres_identity" != "$DB_USER|$DB_ADMIN" ]]; then
  echo "PostgreSQL loopback configurado recusou a identidade informada" >&2
  exit 2
fi

mkdir -p "$RUN_DIR"

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

listener_count() {
  local port="$1"
  local output=""
  local status=0
  if [[ -z "$port" ]]; then
    printf '0'
    return 0
  fi
  output="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null)" || status="$?"
  if [[ "$status" != "0" && "$status" != "1" ]]; then
    return "$status"
  fi
  awk 'NR > 1 {count++} END {print count + 0}' <<<"$output"
}

# BEGIN MANALOOM_VISUAL_CLEANUP_CONTRACT
record_visual_cleanup_failure() {
  local reason="$1"
  CLEANUP_FAILURE_COUNT=$((CLEANUP_FAILURE_COUNT + 1))
  if [[ -z "$CLEANUP_FAILURES" ]]; then
    CLEANUP_FAILURES="$reason"
  else
    CLEANUP_FAILURES="$CLEANUP_FAILURES,$reason"
  fi
  printf 'cleanup_failure=%s\n' "$reason" >&2
}

process_group_count() {
  local pgid="$1"
  if [[ -z "$pgid" ]]; then
    printf '0'
    return 0
  fi
  ps -axo state=,pgid= | awk -v expected="$pgid" \
    '$1 !~ /^Z/ && $2 == expected {count++} END {print count + 0}'
}

capture_owned_process_group() {
  local pid="$1"
  local pgid=""
  local shell_pgid=""
  pgid="$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
  shell_pgid="$(ps -o pgid= -p "$$" 2>/dev/null | tr -d '[:space:]')"
  if [[ ! "$pgid" =~ ^[0-9]+$ || "$pgid" != "$pid" ||
        "$pgid" == "$shell_pgid" ]]; then
    return 1
  fi
  printf '%s' "$pgid"
}

send_visual_owned_signal() {
  local signal="$1"
  local pgid="$2"
  kill -"$signal" -- "-$pgid"
}

wait_visual_owned_process() {
  wait "$1"
}

terminate_visual_owned_process_group() {
  local label="$1"
  local pid="$2"
  local pgid="$3"
  local remaining="0"
  local wait_status=0
  local term_wait_iterations=200

  if [[ "$label" == "backend" ]]; then
    term_wait_iterations=900
  fi

  if [[ -z "$pid" ]]; then
    OWNED_GROUP_REMAINING="0"
    return 0
  fi
  if [[ ! "$pid" =~ ^[0-9]+$ || ! "$pgid" =~ ^[0-9]+$ ||
        "$pid" != "$pgid" ]]; then
    record_visual_cleanup_failure "${label}_ownership_invalid"
    OWNED_GROUP_REMAINING="unknown"
    return 1
  fi
  remaining="$(process_group_count "$pgid")" || {
    record_visual_cleanup_failure "${label}_group_probe_failed"
    OWNED_GROUP_REMAINING="unknown"
    return 1
  }
  if [[ "$remaining" != "0" ]]; then
    if ! send_visual_owned_signal TERM "$pgid" >/dev/null 2>&1; then
      record_visual_cleanup_failure "${label}_term_failed"
    fi
    for _ in $(seq 1 "$term_wait_iterations"); do
      remaining="$(process_group_count "$pgid")" || {
        remaining="unknown"
        break
      }
      [[ "$remaining" == "0" ]] && break
      sleep 0.1
    done
    if [[ "$remaining" != "0" ]]; then
      record_visual_cleanup_failure "${label}_term_timeout"
      if ! send_visual_owned_signal KILL "$pgid" >/dev/null 2>&1; then
        record_visual_cleanup_failure "${label}_kill_failed"
      fi
      for _ in $(seq 1 50); do
        remaining="$(process_group_count "$pgid")" || {
          remaining="unknown"
          break
        }
        [[ "$remaining" == "0" ]] && break
        sleep 0.1
      done
    fi
  fi
  wait_visual_owned_process "$pid" >/dev/null 2>&1
  wait_status="$?"
  if [[ "$wait_status" == "127" ]]; then
    record_visual_cleanup_failure "${label}_wait_failed"
  fi
  remaining="$(process_group_count "$pgid")" || remaining="unknown"
  if [[ "$remaining" != "0" ]]; then
    record_visual_cleanup_failure "${label}_group_residual"
  fi
  OWNED_GROUP_REMAINING="$remaining"
  [[ "$remaining" == "0" && "$wait_status" != "127" ]]
}

validate_backend_cleanup_receipt() {
  local receipt="$1"
  local expected_run_id="$2"
  local expected_parent_run_id="$3"
  local expected_run_dir="$4"
  local expected_database="$5"
  local expected_api_port="$6"
  local expected_email_port="$7"

  [[ -f "$receipt" && ! -L "$receipt" ]] || return 1
  [[ "$receipt" == "$expected_run_dir/backend-cleanup-receipt.json" ]] ||
    return 1
  jq -e \
    --arg run_id "$expected_run_id" \
    --arg parent_run_id "$expected_parent_run_id" \
    --arg run_dir "$expected_run_dir" \
    --arg database "$expected_database" \
    --argjson api_port "$expected_api_port" \
    --argjson email_port "$expected_email_port" \
    '.schema == "manaloom.server_contract_e2e_cleanup_receipt.v1"
      and .status == "PASS_CLEANUP"
      and .run_id == $run_id
      and .parent_visual_run_id == $parent_run_id
      and .run_dir == $run_dir
      and .database == $database
      and .api_port == $api_port
      and .email_port == $email_port
      and .checks.database_remaining == 0
      and .checks.api_listeners == 0
      and .checks.email_listeners == 0
      and .checks.server_process_group_remaining == 0
      and .checks.email_process_group_remaining == 0
      and .checks.build_remaining == 0
      and .checks.dart_frog_remaining == 0
      and .checks.governed_temp_remaining == 0
      and .cleanup_invocations == 1
      and .idempotent == true' \
    "$receipt" >/dev/null
}

probe_database_absence() {
  local probe=""
  local probe_status=0
  if [[ -z "$DATABASE" ]]; then
    DATABASE_REMAINING="not_reported"
    record_visual_cleanup_failure "database_not_reported"
    return 1
  fi
  DATABASE_REMAINING="unknown"
  for _ in $(seq 1 200); do
    probe="$(
      configured_psql -d "$DB_ADMIN" \
        -Atc "SELECT 1 FROM pg_database WHERE datname = '$DATABASE'" \
        2>/dev/null
    )"
    probe_status="$?"
    if [[ "$probe_status" != "0" ]]; then
      DATABASE_REMAINING="probe_failed"
      break
    fi
    if [[ -z "$probe" ]]; then
      DATABASE_REMAINING="0"
      break
    fi
    if [[ "$probe" != "1" ]]; then
      DATABASE_REMAINING="probe_invalid"
      break
    fi
    DATABASE_REMAINING="1"
    sleep 0.1
  done
  if [[ "$DATABASE_REMAINING" != "0" ]]; then
    record_visual_cleanup_failure "database_residual"
    return 1
  fi
}

probe_visual_boundaries() {
  API_LISTENERS="$(listener_count "$BACKEND_API_PORT")" ||
    API_LISTENERS="probe_failed"
  WEB_LISTENERS="$(listener_count "$WEB_PORT")" ||
    WEB_LISTENERS="probe_failed"
  CHROMEDRIVER_LISTENERS="$(listener_count "$CHROMEDRIVER_PORT")" ||
    CHROMEDRIVER_LISTENERS="probe_failed"
  CHROMEDRIVER_PROCESSES="$(pgrep -x chromedriver 2>/dev/null | awk 'END {print NR + 0}')"
  [[ "$API_LISTENERS" == "0" ]] ||
    record_visual_cleanup_failure "api_listener_residual"
  [[ "$WEB_LISTENERS" == "0" ]] ||
    record_visual_cleanup_failure "web_listener_residual"
  [[ "$CHROMEDRIVER_LISTENERS" == "0" ]] ||
    record_visual_cleanup_failure "chromedriver_listener_residual"
  [[ "$CHROMEDRIVER_PROCESSES" == "0" ]] ||
    record_visual_cleanup_failure "chromedriver_process_residual"
}

remove_visual_artifacts_and_prove_absent() {
  if ! rm -f "$CREDENTIALS_FILE"; then
    record_visual_cleanup_failure "credentials_remove_failed"
  fi
  if ! rm -f "$ISOLATED_CAPABILITIES_FILE"; then
    record_visual_cleanup_failure "capability_policy_remove_failed"
  fi
  if [[ -e "$WEB_BUILD_DIR" || -L "$WEB_BUILD_DIR" ]]; then
    if [[ -L "$WEB_BUILD_DIR" ]]; then
      record_visual_cleanup_failure "web_build_symlink"
    elif ! rm -rf "$WEB_BUILD_DIR"; then
      record_visual_cleanup_failure "web_build_remove_failed"
    fi
  fi
  if [[ -e "$CREDENTIALS_FILE" || -L "$CREDENTIALS_FILE" ]]; then
    CREDENTIALS_FILE_REMOVED="false"
    record_visual_cleanup_failure "credentials_residual"
  else
    CREDENTIALS_FILE_REMOVED="true"
  fi
  if [[ -e "$ISOLATED_CAPABILITIES_FILE" ||
        -L "$ISOLATED_CAPABILITIES_FILE" ]]; then
    CAPABILITY_POLICY_FILE_REMOVED="false"
    record_visual_cleanup_failure "capability_policy_residual"
  else
    CAPABILITY_POLICY_FILE_REMOVED="true"
  fi
  if [[ -e "$WEB_BUILD_DIR" || -L "$WEB_BUILD_DIR" ]]; then
    WEB_BUILD_REMAINING="1"
    record_visual_cleanup_failure "web_build_residual"
  else
    WEB_BUILD_REMAINING="0"
  fi
}

write_visual_cleanup_summary() {
  local original_status="$1"
  local final_status="$2"
  local temp_file="$SUMMARY_FILE.tmp.$$"
  rm -f "$temp_file"
  jq -n \
    --arg schema "manaloom.authenticated_visual_cleanup_summary.v1" \
    --arg run_id "$RUN_ID" \
    --arg run_dir "$RUN_DIR" \
    --arg database "$DATABASE" \
    --arg backend_receipt "$BACKEND_CLEANUP_RECEIPT" \
    --arg backend_receipt_status "$BACKEND_RECEIPT_STATUS" \
    --arg database_remaining "$DATABASE_REMAINING" \
    --arg api_listeners "$API_LISTENERS" \
    --arg web_listeners "$WEB_LISTENERS" \
    --arg chromedriver_listeners "$CHROMEDRIVER_LISTENERS" \
    --arg chromedriver_processes "$CHROMEDRIVER_PROCESSES" \
    --arg backend_group_remaining "$BACKEND_GROUP_REMAINING" \
    --arg web_group_remaining "$WEB_GROUP_REMAINING" \
    --arg web_build_remaining "$WEB_BUILD_REMAINING" \
    --arg credentials_removed "$CREDENTIALS_FILE_REMOVED" \
    --arg capability_policy_removed "$CAPABILITY_POLICY_FILE_REMOVED" \
    --arg failures "$CLEANUP_FAILURES" \
    --argjson original_exit_code "$original_status" \
    --argjson final_exit_code "$final_status" \
    --argjson failure_count "$CLEANUP_FAILURE_COUNT" \
    '{
      schema: $schema,
      status: (if $failure_count == 0 then "PASS_CLEANUP" else "NON_PASS_CLEANUP" end),
      run_id: $run_id,
      run_dir: $run_dir,
      database: $database,
      original_exit_code: $original_exit_code,
      final_exit_code: $final_exit_code,
      failure_count: $failure_count,
      failures: ($failures | if length == 0 then [] else split(",") end),
      backend_cleanup_receipt: $backend_receipt,
      backend_receipt_status: $backend_receipt_status,
      checks: {
        database_remaining: ($database_remaining | tonumber? // $database_remaining),
        api_listeners: ($api_listeners | tonumber? // $api_listeners),
        web_listeners: ($web_listeners | tonumber? // $web_listeners),
        chromedriver_listeners: ($chromedriver_listeners | tonumber? // $chromedriver_listeners),
        chromedriver_processes: ($chromedriver_processes | tonumber? // $chromedriver_processes),
        backend_process_group_remaining: ($backend_group_remaining | tonumber? // $backend_group_remaining),
        web_process_group_remaining: ($web_group_remaining | tonumber? // $web_group_remaining),
        web_build_remaining: ($web_build_remaining | tonumber? // $web_build_remaining),
        credentials_file_removed: ($credentials_removed == "true"),
        capability_policy_file_removed: ($capability_policy_removed == "true")
      },
      idempotent: true
    }' >"$temp_file" || {
      rm -f "$temp_file"
      return 1
    }
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }
  mv "$temp_file" "$SUMMARY_FILE"
}

write_global_cleanup_receipt() {
  local original_status="$1"
  local temp_file="$GLOBAL_CLEANUP_RECEIPT.tmp.$$"
  local completed_at=""
  completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rm -f "$temp_file"
  jq -n \
    --arg schema "manaloom.authenticated_visual_cleanup_receipt.v1" \
    --arg run_id "$RUN_ID" \
    --arg run_dir "$RUN_DIR" \
    --arg database "$DATABASE" \
    --arg backend_run_id "$BACKEND_RUN_ID" \
    --arg backend_receipt "$BACKEND_CLEANUP_RECEIPT" \
    --arg backend_receipt_sha256 "$BACKEND_CLEANUP_RECEIPT_SHA256" \
    --arg completed_at_utc "$completed_at" \
    --argjson original_exit_code "$original_status" \
    '{
      schema: $schema,
      status: "PASS_CLEANUP",
      run_id: $run_id,
      run_dir: $run_dir,
      database: $database,
      original_exit_code: $original_exit_code,
      backend: {
        run_id: $backend_run_id,
        cleanup_receipt: $backend_receipt,
        cleanup_receipt_sha256: $backend_receipt_sha256
      },
      checks: {
        database_remaining: 0,
        api_listeners: 0,
        web_listeners: 0,
        chromedriver_listeners: 0,
        chromedriver_processes: 0,
        backend_process_group_remaining: 0,
        web_process_group_remaining: 0,
        web_build_remaining: 0,
        credentials_file_removed: true,
        capability_policy_file_removed: true
      },
      cleanup_invocations: 1,
      idempotent: true,
      completed_at_utc: $completed_at_utc
    }' >"$temp_file" || {
      rm -f "$temp_file"
      return 1
    }
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }
  mv "$temp_file" "$GLOBAL_CLEANUP_RECEIPT" || {
    rm -f "$temp_file"
    return 1
  }
  jq -e '.status == "PASS_CLEANUP"' "$GLOBAL_CLEANUP_RECEIPT" >/dev/null
}

perform_visual_cleanup_once() {
  local original_status="$1"
  local final_status="$original_status"

  if [[ "$CLEANUP_STATE" == "complete" ]]; then
    return "$CLEANUP_FINAL_STATUS"
  fi
  if [[ "$CLEANUP_STATE" == "running" ]]; then
    record_visual_cleanup_failure "cleanup_reentered"
    return 1
  fi
  CLEANUP_STATE="running"
  set +e

  terminate_visual_owned_process_group \
    "backend" "$BACKEND_PID" "$BACKEND_PGID"
  BACKEND_GROUP_REMAINING="$OWNED_GROUP_REMAINING"
  if validate_backend_cleanup_receipt \
    "$BACKEND_CLEANUP_RECEIPT" \
    "$BACKEND_RUN_ID" \
    "$RUN_ID" \
    "$BACKEND_RUN_DIR" \
    "$DATABASE" \
    "$BACKEND_API_PORT" \
    "$BACKEND_EMAIL_PORT"; then
    BACKEND_RECEIPT_STATUS="valid"
    BACKEND_CLEANUP_RECEIPT_SHA256="$(
      shasum -a 256 "$BACKEND_CLEANUP_RECEIPT" | awk '{print $1}'
    )"
  else
    BACKEND_RECEIPT_STATUS="invalid_or_missing"
    record_visual_cleanup_failure "backend_cleanup_receipt_invalid"
  fi
  terminate_visual_owned_process_group "web" "$WEB_PID" "$WEB_PGID"
  WEB_GROUP_REMAINING="$OWNED_GROUP_REMAINING"
  probe_database_absence
  probe_visual_boundaries
  remove_visual_artifacts_and_prove_absent

  if [[ "$CLEANUP_FAILURE_COUNT" != "0" ]]; then
    final_status=1
  fi
  if ! write_visual_cleanup_summary "$original_status" "$final_status"; then
    record_visual_cleanup_failure "cleanup_summary_write_failed"
    final_status=1
  fi
  if [[ "$CLEANUP_FAILURE_COUNT" == "0" ]]; then
    if ! write_global_cleanup_receipt "$original_status"; then
      record_visual_cleanup_failure "global_cleanup_receipt_write_failed"
      final_status=1
      rm -f "$GLOBAL_CLEANUP_RECEIPT"
      write_visual_cleanup_summary "$original_status" "$final_status" ||
        record_visual_cleanup_failure "cleanup_summary_rewrite_failed"
    fi
  else
    rm -f "$GLOBAL_CLEANUP_RECEIPT"
  fi
  if [[ "$CLEANUP_FAILURE_COUNT" != "0" ]]; then
    final_status=1
  fi

  CLEANUP_FINAL_STATUS="$final_status"
  CLEANUP_STATE="complete"
  return "$CLEANUP_FINAL_STATUS"
}

on_visual_exit() {
  local original_status="$?"
  local final_status=1
  trap - EXIT INT TERM
  perform_visual_cleanup_once "$original_status"
  final_status="$?"
  printf 'cleanup_summary=%s\n' "$SUMMARY_FILE"
  if [[ -f "$GLOBAL_CLEANUP_RECEIPT" && ! -L "$GLOBAL_CLEANUP_RECEIPT" ]]; then
    printf 'global_cleanup_receipt=%s\n' "$GLOBAL_CLEANUP_RECEIPT"
    printf 'global_cleanup_receipt_sha256=%s\n' \
      "$(shasum -a 256 "$GLOBAL_CLEANUP_RECEIPT" | awk '{print $1}')"
  else
    echo "cleanup incompleto na fixture visual" >&2
  fi
  exit "$final_status"
}
# END MANALOOM_VISUAL_CLEANUP_CONTRACT

trap on_visual_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

run_backend_fixture() (
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export DB_HOST DB_PORT DB_USER DB_PASS
  export MANALOOM_S1_PG_ADMIN_DB="$DB_ADMIN"
  export MANALOOM_HOLD_FOR_BROWSER_QA=1
  export MANALOOM_PARENT_VISUAL_RUN_ID="$RUN_ID"
  export MANALOOM_ALLOW_DEV_ORIGINS=true
  export MANALOOM_E2E_ISOLATED_RUNTIME=1
  export MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="$ISOLATED_CAPABILITIES_FILE"
  export MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY
  export MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  export MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  exec "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh"
)

set -m
run_backend_fixture \
  >"$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!
set +m
if ! BACKEND_PGID="$(capture_owned_process_group "$BACKEND_PID")"; then
  emergency_kill_status=0
  emergency_wait_status=0
  kill -TERM "$BACKEND_PID" >/dev/null 2>&1 || emergency_kill_status="$?"
  wait "$BACKEND_PID" >/dev/null 2>&1 || emergency_wait_status="$?"
  BACKEND_PID=""
  echo "fixture backend não iniciou em process group próprio" >&2
  printf 'emergency_kill_status=%s emergency_wait_status=%s\n' \
    "$emergency_kill_status" "$emergency_wait_status" >&2
  exit 1
fi

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

read_unique_backend_value() {
  local key="$1"
  local values=""
  local count="0"
  values="$(sed -n "s/^${key}=//p" "$BACKEND_LOG")"
  count="$(awk 'NF {count++} END {print count + 0}' <<<"$values")"
  [[ "$count" == "1" ]] || return 1
  printf '%s' "$values"
}

API_BASE_URL="$(read_unique_backend_value api_base_url)"
DATABASE="$(read_unique_backend_value database)"
BACKEND_RUN_ID="$(read_unique_backend_value backend_run_id)"
BACKEND_PARENT_VISUAL_RUN_ID="$(
  read_unique_backend_value parent_visual_run_id
)"
BACKEND_RUN_DIR="$(read_unique_backend_value backend_run_dir)"
BACKEND_CLEANUP_RECEIPT="$(read_unique_backend_value cleanup_receipt)"
BACKEND_API_PORT="$(read_unique_backend_value api_port)"
BACKEND_EMAIL_PORT="$(read_unique_backend_value email_port)"
if [[ ! "$API_BASE_URL" =~ ^http://127\.0\.0\.1:[0-9]+$ ||
      ! "$DATABASE" =~ ^manaloom_s1_api_[A-Za-z0-9_]+$ ||
      ! "$BACKEND_RUN_ID" =~ ^[A-Za-z0-9_.-]+$ ||
      "$BACKEND_PARENT_VISUAL_RUN_ID" != "$RUN_ID" ||
      ! "$BACKEND_API_PORT" =~ ^[0-9]+$ ||
      ! "$BACKEND_EMAIL_PORT" =~ ^[0-9]+$ ||
      "$API_BASE_URL" != "http://127.0.0.1:$BACKEND_API_PORT" ||
      "$BACKEND_CLEANUP_RECEIPT" != "$BACKEND_RUN_DIR/backend-cleanup-receipt.json" ]]; then
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
  configured_psql -v ON_ERROR_STOP=1 -d "$DATABASE" \
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
configured_psql -v ON_ERROR_STOP=1 -d "$DATABASE" \
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

set -m
python3 "$APP_DIR/tool/serve_flutter_web_app.py" \
  --host 127.0.0.1 \
  --port "$WEB_PORT" \
  --build-dir "$WEB_BUILD_DIR" \
  --api-upstream "$API_BASE_URL" \
  --allow-loopback-http-api \
  >"$WEB_LOG" 2>&1 &
WEB_PID=$!
set +m
if ! WEB_PGID="$(capture_owned_process_group "$WEB_PID")"; then
  emergency_kill_status=0
  emergency_wait_status=0
  kill -TERM "$WEB_PID" >/dev/null 2>&1 || emergency_kill_status="$?"
  wait "$WEB_PID" >/dev/null 2>&1 || emergency_wait_status="$?"
  WEB_PID=""
  echo "servidor Web visual não iniciou em process group próprio" >&2
  printf 'emergency_kill_status=%s emergency_wait_status=%s\n' \
    "$emergency_kill_status" "$emergency_wait_status" >&2
  exit 1
fi
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
    cleanup: {
      status: "canonical_receipt_pending",
      global_receipt: ($run_dir + "/global-cleanup-receipt.json"),
      chromedriver_port: 4444
    }
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
printf 'global_cleanup_receipt=%s\n' "$GLOBAL_CLEANUP_RECEIPT"
printf 'Press Ctrl+C to stop and prove cleanup.\n'

while kill -0 "$WEB_PID" >/dev/null 2>&1 &&
      kill -0 "$BACKEND_PID" >/dev/null 2>&1; do
  sleep 1
done

echo "fixture visual encerrou inesperadamente" >&2
exit 1
