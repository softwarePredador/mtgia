#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST-127.0.0.1}"
DB_PORT="${DB_PORT-5432}"
DB_USER_SET="${DB_USER+x}"
DB_USER_VALUE="${DB_USER-}"
DB_PASS="${DB_PASS-}"
DB_ADMIN="${MANALOOM_S1_PG_ADMIN_DB:-postgres}"
export -n DB_HOST DB_PORT DB_USER DB_PASS DB_ADMIN MANALOOM_S1_PG_ADMIN_DB PGPASSWORD
unset MANALOOM_S1_PG_ADMIN_DB PGPASSWORD

case "$DB_HOST" in
  localhost|127.0.0.1|::1) ;;
  *) echo "BLOCKED: harness aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac
if [[ ! "$DB_PORT" =~ ^[0-9]+$ || ${#DB_PORT} -gt 5 ]]; then
  echo "BLOCKED: DB_PORT deve ser uma porta numérica válida" >&2
  exit 2
fi
DB_PORT_NUMBER=$((10#$DB_PORT))
if ((DB_PORT_NUMBER < 1 || DB_PORT_NUMBER > 65535)); then
  echo "BLOCKED: DB_PORT deve estar entre 1 e 65535" >&2
  exit 2
fi
if [[ "$DB_USER_SET" == "x" && -n "$DB_USER_VALUE" ]]; then
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

PARENT_VISUAL_RUN_ID="${MANALOOM_PARENT_VISUAL_RUN_ID:-standalone}"
if [[ ! "$PARENT_VISUAL_RUN_ID" =~ ^[A-Za-z0-9_.-]+$ ]]; then
  echo "BLOCKED: identidade da fixture visual pai invalida" >&2
  exit 2
fi
readonly PARENT_VISUAL_RUN_ID

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval "E2E de contrato da API em PostgreSQL descartável"
require_live_mutation_approval "E2E de contrato da API em PostgreSQL descartável"

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"

for tool in awk createdb curl dropdb find head jq lsof ps psql python3 sed \
  shasum sort tr xargs; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done

ISOLATED_ENVIRONMENT="${MANALOOM_ISOLATED_SERVER_ENVIRONMENT:-development}"
if [[ -z "${INTERACTIVE_BATTLE_ENABLED+x}" ]]; then
  INTERACTIVE_BATTLE_ENABLED=false
fi

case "$ISOLATED_ENVIRONMENT" in
  development|test|staging|production) ;;
  *) echo "ambiente isolado inválido: $ISOLATED_ENVIRONMENT" >&2; exit 2 ;;
esac
case "$INTERACTIVE_BATTLE_ENABLED" in
  true|false) ;;
  *) echo "INTERACTIVE_BATTLE_ENABLED deve ser true ou false" >&2; exit 2 ;;
esac

EGRESS_POLICY="deny_non_loopback"
EGRESS_GUARD_KIND=""
EGRESS_SANDBOX_PROFILE=""
EGRESS_GUARD=()
case "$(uname -s)" in
  Darwin)
    command -v sandbox-exec >/dev/null 2>&1 || {
      echo "BLOCKED: sandbox-exec é obrigatório para o harness sem egress" >&2
      exit 2
    }
    EGRESS_GUARD_KIND="macos_sandbox_exec_loopback_only"
    EGRESS_SANDBOX_PROFILE='(version 1)
(allow default)
(deny network*)
(allow network-outbound (remote ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))'
    EGRESS_GUARD=(sandbox-exec -p "$EGRESS_SANDBOX_PROFILE")
    ;;
  *)
    echo "BLOCKED: não há guard de egress loopback-only suportado neste sistema" >&2
    exit 2
    ;;
esac

run_no_egress() {
  "${EGRESS_GUARD[@]}" "$@"
}

run_postgres_no_egress() (
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export PGPASSWORD="$DB_PASS"
  exec "${EGRESS_GUARD[@]}" "$@"
)

if run_no_egress python3 -c \
  'import socket; socket.socket(socket.AF_INET, socket.SOCK_DGRAM).connect(("1.1.1.1", 53))' \
  >/dev/null 2>&1; then
  echo "BLOCKED: o guard de egress permitiu conexão não-loopback" >&2
  exit 2
fi
EGRESS_GUARD_SELF_TEST="pass"

if [[ "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}" == "1" ]]; then
  echo "BLOCKED: catálogo remoto é incompatível com o harness sem egress" >&2
  exit 2
fi

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$"
OPS_KEY="manaloom-isolated-ops-${RUN_ID}-key-material"
ISOLATED_JWT_SECRET="manaloom-isolated-contract-${RUN_ID}-not-production"
ISOLATED_OPTIMIZATION_SIGNING_SECRET="$(
  run_no_egress python3 -c \
    'import secrets; print("manaloom-isolated-optimization-" + secrets.token_hex(32))'
)"
DATABASE="manaloom_s1_api_${RUN_ID}"
RUN_DIR="${TMPDIR:-/tmp}/manaloom_server_contract_e2e_${RUN_ID}"
SERVER_LOG="$RUN_DIR/server.log"
EMAIL_FIXTURE_LOG="$RUN_DIR/email-delivery-evidence.jsonl"
TEST_LOG="$RUN_DIR/tests.log"
SUMMARY="$RUN_DIR/summary.txt"
BACKEND_CLEANUP_DIAGNOSTIC="$RUN_DIR/backend-cleanup-diagnostic.json"
BACKEND_CLEANUP_RECEIPT="$RUN_DIR/backend-cleanup-receipt.json"
mkdir -p "$RUN_DIR"
touch "$EMAIL_FIXTURE_LOG"

PORT="$(python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)"
EMAIL_FIXTURE_PORT="$(python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)"
SERVER_PID=""
SERVER_PGID=""
EMAIL_FIXTURE_PID=""
EMAIL_FIXTURE_PGID=""
BUILD_OWNED=0
BUILD_DIGEST=""
BUILD_PREEXISTED=0
DART_FROG_PREEXISTED=0
ADAPTER_STARTED=0
CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
DATABASE_REMAINING="unknown"
API_LISTENERS="unknown"
EMAIL_LISTENERS="unknown"
SERVER_GROUP_REMAINING="unknown"
EMAIL_GROUP_REMAINING="unknown"
BUILD_REMAINING="unknown"
DART_FROG_REMAINING="unknown"
GOVERNED_TEMP_REMAINING="unknown"
OWNED_GROUP_REMAINING="unknown"
NORMAL_RUN_COMPLETED=0
NORMAL_SUMMARY_SHA=""

if [[ -e "$SERVER_DIR/build" || -L "$SERVER_DIR/build" ]]; then
  BUILD_PREEXISTED=1
fi
if [[ -e "$SERVER_DIR/.dart_frog" || -L "$SERVER_DIR/.dart_frog" ]]; then
  DART_FROG_PREEXISTED=1
fi

build_tree_digest() {
  {
    find "$SERVER_DIR/build" -type f -print |
      sed "s#^$SERVER_DIR/build/##" |
      LC_ALL=C sort |
      while IFS= read -r relative_path; do
        printf '%s\0%s\0' \
          "$relative_path" \
          "$(shasum -a 256 "$SERVER_DIR/build/$relative_path" | awk '{print $1}')"
      done
  } | shasum -a 256 | awk '{print $1}'
}

# BEGIN MANALOOM_BACKEND_CLEANUP_CONTRACT
record_cleanup_failure() {
  local reason="$1"
  CLEANUP_FAILURE_COUNT=$((CLEANUP_FAILURE_COUNT + 1))
  if [[ -z "$CLEANUP_FAILURES" ]]; then
    CLEANUP_FAILURES="$reason"
  else
    CLEANUP_FAILURES="$CLEANUP_FAILURES,$reason"
  fi
  printf 'cleanup_failure=%s\n' "$reason" >&2
}

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

send_owned_signal() {
  local signal="$1"
  local pgid="$2"
  kill -"$signal" -- "-$pgid"
}

wait_owned_process() {
  wait "$1"
}

remove_owned_tree() {
  rm -rf "$1"
}

terminate_owned_process_group() {
  local label="$1"
  local pid="$2"
  local pgid="$3"
  local remaining="0"
  local wait_status=0

  if [[ -z "$pid" ]]; then
    OWNED_GROUP_REMAINING="0"
    return 0
  fi
  if [[ ! "$pid" =~ ^[0-9]+$ || ! "$pgid" =~ ^[0-9]+$ ||
        "$pid" != "$pgid" ]]; then
    record_cleanup_failure "${label}_ownership_invalid"
    OWNED_GROUP_REMAINING="unknown"
    return 1
  fi

  remaining="$(process_group_count "$pgid")" || {
    record_cleanup_failure "${label}_group_probe_failed"
    OWNED_GROUP_REMAINING="unknown"
    return 1
  }
  if [[ "$remaining" != "0" ]]; then
    if ! send_owned_signal TERM "$pgid" >/dev/null 2>&1; then
      record_cleanup_failure "${label}_term_failed"
    fi
    for _ in $(seq 1 200); do
      remaining="$(process_group_count "$pgid")" || {
        remaining="unknown"
        break
      }
      [[ "$remaining" == "0" ]] && break
      sleep 0.1
    done
    if [[ "$remaining" != "0" ]]; then
      record_cleanup_failure "${label}_term_timeout"
      if ! send_owned_signal KILL "$pgid" >/dev/null 2>&1; then
        record_cleanup_failure "${label}_kill_failed"
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

  wait_owned_process "$pid" >/dev/null 2>&1
  wait_status="$?"
  if [[ "$wait_status" == "127" ]]; then
    record_cleanup_failure "${label}_wait_failed"
  fi
  remaining="$(process_group_count "$pgid")" || remaining="unknown"
  if [[ "$remaining" != "0" ]]; then
    record_cleanup_failure "${label}_group_residual"
  fi
  OWNED_GROUP_REMAINING="$remaining"
  [[ "$remaining" == "0" && "$wait_status" != "127" ]]
}

drop_owned_database_and_prove_absent() {
  local probe=""
  local probe_status=0

  if ! run_postgres_no_egress dropdb --if-exists --force \
    --maintenance-db="$DB_ADMIN" \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DATABASE" \
    >/dev/null 2>&1; then
    record_cleanup_failure "dropdb_failed"
  fi
  DATABASE_REMAINING="unknown"
  for _ in $(seq 1 200); do
    probe="$(
      run_postgres_no_egress psql -X -A -t \
        -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_ADMIN" \
        -c "SELECT 1 FROM pg_database WHERE datname = '$DATABASE'" \
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
    record_cleanup_failure "database_residual"
    return 1
  fi
}

remove_backend_artifacts_and_prove_absent() {
  local current_build_digest=""
  local atomic_cards="$RUN_DIR/AtomicCards.json"

  if [[ -e "$SERVER_DIR/build" || -L "$SERVER_DIR/build" ]]; then
    if [[ "$BUILD_PREEXISTED" == "1" || -L "$SERVER_DIR/build" ]]; then
      record_cleanup_failure "build_not_owned"
    elif [[ "$BUILD_OWNED" == "1" ]]; then
      current_build_digest="$(build_tree_digest 2>/dev/null)" || {
        record_cleanup_failure "build_digest_failed"
        current_build_digest=""
      }
      if [[ -n "$BUILD_DIGEST" && "$current_build_digest" != "$BUILD_DIGEST" ]]; then
        record_cleanup_failure "build_digest_mismatch"
      elif ! remove_owned_tree "$SERVER_DIR/build"; then
        record_cleanup_failure "build_remove_failed"
      fi
    elif [[ "$ADAPTER_STARTED" == "1" ]]; then
      if ! remove_owned_tree "$SERVER_DIR/build"; then
        record_cleanup_failure "partial_build_remove_failed"
      fi
    else
      record_cleanup_failure "build_ownership_unknown"
    fi
  fi
  [[ ! -e "$SERVER_DIR/build" && ! -L "$SERVER_DIR/build" ]] ||
    record_cleanup_failure "build_residual"
  if [[ -e "$SERVER_DIR/.dart_frog" || -L "$SERVER_DIR/.dart_frog" ]]; then
    if [[ "$DART_FROG_PREEXISTED" == "1" || -L "$SERVER_DIR/.dart_frog" ||
          "$ADAPTER_STARTED" != "1" ]]; then
      record_cleanup_failure "dart_frog_not_owned"
    elif ! remove_owned_tree "$SERVER_DIR/.dart_frog"; then
      record_cleanup_failure "dart_frog_remove_failed"
    fi
  fi
  [[ ! -e "$SERVER_DIR/.dart_frog" && ! -L "$SERVER_DIR/.dart_frog" ]] ||
    record_cleanup_failure "dart_frog_residual"
  if ! rm -f "$atomic_cards"; then
    record_cleanup_failure "governed_temp_remove_failed"
  fi
  [[ ! -e "$atomic_cards" && ! -L "$atomic_cards" ]] ||
    record_cleanup_failure "governed_temp_residual"

  if [[ -e "$SERVER_DIR/build" || -L "$SERVER_DIR/build" ]]; then
    BUILD_REMAINING="1"
  else
    BUILD_REMAINING="0"
  fi
  if [[ -e "$SERVER_DIR/.dart_frog" || -L "$SERVER_DIR/.dart_frog" ]]; then
    DART_FROG_REMAINING="1"
  else
    DART_FROG_REMAINING="0"
  fi
  if [[ -e "$atomic_cards" || -L "$atomic_cards" ]]; then
    GOVERNED_TEMP_REMAINING="1"
  else
    GOVERNED_TEMP_REMAINING="0"
  fi
}

write_backend_cleanup_diagnostic() {
  local original_status="$1"
  local final_status="$2"
  local completed_at=""
  local temp_file="$BACKEND_CLEANUP_DIAGNOSTIC.tmp.$$"
  completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rm -f "$temp_file"
  if ! jq -n \
    --arg schema "manaloom.server_contract_e2e_cleanup_diagnostic.v1" \
    --arg run_id "$RUN_ID" \
    --arg parent_visual_run_id "$PARENT_VISUAL_RUN_ID" \
    --arg run_dir "$RUN_DIR" \
    --arg database "$DATABASE" \
    --arg api_port "$PORT" \
    --arg email_port "$EMAIL_FIXTURE_PORT" \
    --arg database_remaining "$DATABASE_REMAINING" \
    --arg api_listeners "$API_LISTENERS" \
    --arg email_listeners "$EMAIL_LISTENERS" \
    --arg server_group_remaining "$SERVER_GROUP_REMAINING" \
    --arg email_group_remaining "$EMAIL_GROUP_REMAINING" \
    --arg build_remaining "$BUILD_REMAINING" \
    --arg dart_frog_remaining "$DART_FROG_REMAINING" \
    --arg governed_temp_remaining "$GOVERNED_TEMP_REMAINING" \
    --arg failures "$CLEANUP_FAILURES" \
    --arg completed_at_utc "$completed_at" \
    --argjson original_exit_code "$original_status" \
    --argjson final_exit_code "$final_status" \
    --argjson failure_count "$CLEANUP_FAILURE_COUNT" \
    '{
      schema: $schema,
      status: (if $failure_count == 0 then "PASS_CLEANUP" else "NON_PASS_CLEANUP" end),
      run_id: $run_id,
      parent_visual_run_id: $parent_visual_run_id,
      run_dir: $run_dir,
      database: $database,
      api_port: ($api_port | tonumber),
      email_port: ($email_port | tonumber),
      original_exit_code: $original_exit_code,
      final_exit_code: $final_exit_code,
      failure_count: $failure_count,
      failures: ($failures | if length == 0 then [] else split(",") end),
      checks: {
        database_remaining: ($database_remaining | tonumber? // $database_remaining),
        api_listeners: ($api_listeners | tonumber? // $api_listeners),
        email_listeners: ($email_listeners | tonumber? // $email_listeners),
        server_process_group_remaining: ($server_group_remaining | tonumber? // $server_group_remaining),
        email_process_group_remaining: ($email_group_remaining | tonumber? // $email_group_remaining),
        build_remaining: ($build_remaining | tonumber? // $build_remaining),
        dart_frog_remaining: ($dart_frog_remaining | tonumber? // $dart_frog_remaining),
        governed_temp_remaining: ($governed_temp_remaining | tonumber? // $governed_temp_remaining)
      },
      idempotent: true,
      completed_at_utc: $completed_at_utc
    }' >"$temp_file"; then
    rm -f "$temp_file"
    return 1
  fi
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }
  mv "$temp_file" "$BACKEND_CLEANUP_DIAGNOSTIC"
}

write_backend_cleanup_receipt() {
  local original_status="$1"
  local completed_at=""
  local temp_file="$BACKEND_CLEANUP_RECEIPT.tmp.$$"
  completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rm -f "$temp_file"
  jq -n \
    --arg schema "manaloom.server_contract_e2e_cleanup_receipt.v1" \
    --arg run_id "$RUN_ID" \
    --arg parent_visual_run_id "$PARENT_VISUAL_RUN_ID" \
    --arg run_dir "$RUN_DIR" \
    --arg database "$DATABASE" \
    --arg api_port "$PORT" \
    --arg email_port "$EMAIL_FIXTURE_PORT" \
    --arg completed_at_utc "$completed_at" \
    --arg summary_sha256 "$NORMAL_SUMMARY_SHA" \
    --argjson original_exit_code "$original_status" \
    '{
      schema: $schema,
      status: "PASS_CLEANUP",
      run_id: $run_id,
      parent_visual_run_id: $parent_visual_run_id,
      run_dir: $run_dir,
      database: $database,
      api_port: ($api_port | tonumber),
      email_port: ($email_port | tonumber),
      original_exit_code: $original_exit_code,
      checks: {
        database_remaining: 0,
        api_listeners: 0,
        email_listeners: 0,
        server_process_group_remaining: 0,
        email_process_group_remaining: 0,
        build_remaining: 0,
        dart_frog_remaining: 0,
        governed_temp_remaining: 0
      },
      normal_summary_sha256: (if $summary_sha256 == "" then null else $summary_sha256 end),
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
  mv "$temp_file" "$BACKEND_CLEANUP_RECEIPT" || {
    rm -f "$temp_file"
    return 1
  }
  jq -e '.status == "PASS_CLEANUP"' "$BACKEND_CLEANUP_RECEIPT" >/dev/null
}

perform_backend_cleanup_once() {
  local original_status="$1"
  local final_status="$original_status"

  if [[ "$CLEANUP_STATE" == "complete" ]]; then
    return "$CLEANUP_FINAL_STATUS"
  fi
  if [[ "$CLEANUP_STATE" == "running" ]]; then
    record_cleanup_failure "cleanup_reentered"
    return 1
  fi
  CLEANUP_STATE="running"
  set +e

  terminate_owned_process_group "server" "$SERVER_PID" "$SERVER_PGID"
  SERVER_GROUP_REMAINING="$OWNED_GROUP_REMAINING"
  terminate_owned_process_group \
    "email_fixture" "$EMAIL_FIXTURE_PID" "$EMAIL_FIXTURE_PGID"
  EMAIL_GROUP_REMAINING="$OWNED_GROUP_REMAINING"
  drop_owned_database_and_prove_absent
  API_LISTENERS="$(listener_count "$PORT")" || API_LISTENERS="probe_failed"
  EMAIL_LISTENERS="$(listener_count "$EMAIL_FIXTURE_PORT")" ||
    EMAIL_LISTENERS="probe_failed"
  [[ "$API_LISTENERS" == "0" ]] || record_cleanup_failure "api_listener_residual"
  [[ "$EMAIL_LISTENERS" == "0" ]] ||
    record_cleanup_failure "email_listener_residual"
  remove_backend_artifacts_and_prove_absent

  if [[ "$CLEANUP_FAILURE_COUNT" == "0" ]]; then
    if ! write_backend_cleanup_receipt "$original_status"; then
      record_cleanup_failure "cleanup_receipt_write_failed"
      final_status=1
      rm -f "$BACKEND_CLEANUP_RECEIPT"
    fi
  fi
  if [[ "$CLEANUP_FAILURE_COUNT" != "0" ]]; then
    final_status=1
    rm -f "$BACKEND_CLEANUP_RECEIPT"
    if ! write_backend_cleanup_diagnostic "$original_status" "$final_status"; then
      record_cleanup_failure "cleanup_diagnostic_write_failed"
    fi
  fi

  CLEANUP_FINAL_STATUS="$final_status"
  CLEANUP_STATE="complete"
  return "$CLEANUP_FINAL_STATUS"
}

on_backend_exit() {
  local original_status="$?"
  local final_status=1
  trap - EXIT INT TERM
  perform_backend_cleanup_once "$original_status"
  final_status="$?"
  if [[ -f "$BACKEND_CLEANUP_RECEIPT" && ! -L "$BACKEND_CLEANUP_RECEIPT" ]]; then
    printf 'cleanup_receipt=%s\n' "$BACKEND_CLEANUP_RECEIPT"
    printf 'cleanup_receipt_sha256=%s\n' \
      "$(shasum -a 256 "$BACKEND_CLEANUP_RECEIPT" | awk '{print $1}')"
  else
    printf 'cleanup_diagnostic=%s\n' "$BACKEND_CLEANUP_DIAGNOSTIC" >&2
  fi
  if [[ "$NORMAL_RUN_COMPLETED" == "1" && "$original_status" == "0" &&
        "$final_status" == "0" ]]; then
    printf 'PASS: isolated server contract E2E\n'
    printf 'summary=%s\n' "$SUMMARY"
    printf 'summary_sha256=%s\n' "$NORMAL_SUMMARY_SHA"
  fi
  exit "$final_status"
}
# END MANALOOM_BACKEND_CLEANUP_CONTRACT

trap on_backend_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# O adapter e o unico proprietario do sandbox deny-all durante o build.
# Nao envolver esta chamada no guard loopback-only do harness: no macOS isso
# criaria uma composicao de sandbox que o kernel recusa.
ADAPTER_STARTED=1
"$ROOT_DIR/scripts/manaloom_dart_frog_offline_build.sh" build \
  >"$RUN_DIR/build.log" 2>&1
BUILD_OWNED=1
BUILD_DIGEST="$(build_tree_digest)"
BUILD_ADAPTER_SUMMARY="$(head -n 1 "$RUN_DIR/build.log")"
if ! jq -e '.classification == "PASS_OFFLINE_BUILD_ADAPTER"' \
  <<<"$BUILD_ADAPTER_SUMMARY" >/dev/null; then
  echo "adapter offline não produziu atestado PASS" >&2
  exit 1
fi
resolve_manaloom_flutter_root
DART_BIN="$MANALOOM_FLUTTER_ROOT_RESOLVED/bin/cache/dart-sdk/bin/dart"

set -m
run_no_egress env \
  MANALOOM_EMAIL_FIXTURE_PORT="$EMAIL_FIXTURE_PORT" \
  MANALOOM_EMAIL_FIXTURE_LOG="$EMAIL_FIXTURE_LOG" \
  python3 "$ROOT_DIR/scripts/testing/manaloom_email_webhook_fixture.py" \
  >"$RUN_DIR/email-fixture.log" 2>&1 &
EMAIL_FIXTURE_PID=$!
set +m
if ! EMAIL_FIXTURE_PGID="$(capture_owned_process_group "$EMAIL_FIXTURE_PID")"; then
  emergency_kill_status=0
  emergency_wait_status=0
  kill -TERM "$EMAIL_FIXTURE_PID" >/dev/null 2>&1 || emergency_kill_status="$?"
  wait "$EMAIL_FIXTURE_PID" >/dev/null 2>&1 || emergency_wait_status="$?"
  EMAIL_FIXTURE_PID=""
  echo "fixture de email não iniciou em process group próprio" >&2
  printf 'emergency_kill_status=%s emergency_wait_status=%s\n' \
    "$emergency_kill_status" "$emergency_wait_status" >&2
  exit 1
fi
for _ in $(seq 1 40); do
  if run_no_egress curl -fsS \
    "http://127.0.0.1:$EMAIL_FIXTURE_PORT/health" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$EMAIL_FIXTURE_PID" >/dev/null 2>&1; then
    echo "fixture de email encerrou antes do healthcheck" >&2
    exit 1
  fi
  sleep 0.1
done

run_postgres_no_egress createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  --maintenance-db="$DB_ADMIN" "$DATABASE"
run_postgres_no_egress psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -f "$SERVER_DIR/database_setup.sql" >"$RUN_DIR/bootstrap.log" 2>&1

run_migration_consumer() (
  cd "$SERVER_DIR"
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export DB_HOST DB_PORT DB_USER DB_PASS
  export DB_NAME="$DATABASE"
  export MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  export MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" run bin/migrate.dart
)

run_migration_consumer >"$RUN_DIR/migrate.log" 2>&1

FULL_CARD_COUNT=0

# Deterministic product fixture used by card, deck, community and trade flows.
# It exists only in the disposable database and is removed with that database.
run_postgres_no_egress psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -c "
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd,
      collector_number, foil, cmc
    ) VALUES
    (
      '00000000-0000-4000-8000-000000000001'::uuid,
      '00000000-0000-4000-8000-000000000002'::uuid,
      'Sol Ring', '{1}', 'Artifact',
      '{T}: Add {C}{C}.', ARRAY[]::text[], ARRAY[]::text[],
      'TST', 'uncommon', 1.50, '001', FALSE, 1
    ),
    (
      '00000000-0000-4000-8000-000000000007'::uuid,
      '00000000-0000-4000-8000-000000000002'::uuid,
      'Sol Ring', '{1}', 'Artifact',
      '{T}: Add {C}{C}.', ARRAY[]::text[], ARRAY[]::text[],
      'T2S', 'rare', 2.50, '777', TRUE, 1
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, 'commander', 'legal' FROM cards WHERE name = 'Sol Ring'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd, cmc
    ) VALUES (
      '00000000-0000-4000-8000-000000000003'::uuid,
      '00000000-0000-4000-8000-000000000004'::uuid,
      'Plains', NULL, 'Basic Land — Plains',
      '({T}: Add {W}.)', ARRAY[]::text[], ARRAY['W']::text[],
      'TST', 'common', 0.10, 0
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, format, 'legal'
    FROM cards
    CROSS JOIN (VALUES ('standard'), ('modern'), ('commander')) AS formats(format)
    WHERE name = 'Plains'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, set_code, rarity, price_usd, cmc
    ) VALUES (
      '00000000-0000-4000-8000-000000000005'::uuid,
      '00000000-0000-4000-8000-000000000006'::uuid,
      'Island', NULL, 'Basic Land — Island',
      '({T}: Add {U}.)', ARRAY[]::text[], ARRAY['U']::text[],
      'TST', 'common', 0.10, 0
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, format, 'legal'
    FROM cards
    CROSS JOIN (VALUES ('standard'), ('modern'), ('commander')) AS formats(format)
    WHERE name = 'Island'
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, power, toughness, set_code, rarity,
      price_usd, collector_number, foil, layout, cmc
    ) VALUES
    (
      '10000000-0000-4000-8000-000000000001'::uuid,
      '10000000-0000-4000-8000-000000000010'::uuid,
      'Talrand, Sky Summoner', '{2}{U}{U}',
      'Legendary Creature — Merfolk Wizard',
      'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
      ARRAY['U']::text[], ARRAY['U']::text[], '2', '2',
      'M13', 'rare', 0.50, '72', FALSE, 'normal', 4
    ),
    (
      '10000000-0000-4000-8000-000000000002'::uuid,
      '10000000-0000-4000-8000-000000000010'::uuid,
      'Talrand, Sky Summoner', '{2}{U}{U}',
      'Legendary Creature — Merfolk Wizard',
      'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
      ARRAY['U']::text[], ARRAY['U']::text[], '2', '2',
      'CMM', 'rare', 0.75, '125', TRUE, 'normal', 4
    ),
    (
      '10000000-0000-4000-8000-000000000003'::uuid,
      '10000000-0000-4000-8000-000000000011'::uuid,
      'Lightning Bolt', '{R}', 'Instant',
      'Lightning Bolt deals 3 damage to any target.',
      ARRAY['R']::text[], ARRAY['R']::text[], NULL, NULL,
      'M11', 'common', 1.00, '149', FALSE, 'normal', 1
    ),
    (
      '10000000-0000-4000-8000-000000000004'::uuid,
      '10000000-0000-4000-8000-000000000012'::uuid,
      'Wastes', NULL, 'Basic Land — Wastes',
      '{T}: Add {C}.',
      ARRAY[]::text[], ARRAY[]::text[], NULL, NULL,
      'OGW', 'common', 0.25, '184', FALSE, 'normal', 0
    ),
    (
      '10000000-0000-4000-8000-000000000005'::uuid,
      '10000000-0000-4000-8000-000000000013'::uuid,
      'Lorehold, the Historian', '{3}{R}{W}',
      'Legendary Creature — Elder Dragon',
      'Flying, haste. Lorehold, the Historian can be your commander.',
      ARRAY['R','W']::text[], ARRAY['R','W']::text[], '4', '4',
      'SOS', 'mythic', 3.00, '201', FALSE, 'normal', 5
    ),
    (
      '10000000-0000-4000-8000-000000000006'::uuid,
      '10000000-0000-4000-8000-000000000013'::uuid,
      'Lorehold, the Historian', '{3}{R}{W}',
      'Legendary Creature — Elder Dragon',
      'Flying, haste. Lorehold, the Historian can be your commander.',
      ARRAY['R','W']::text[], ARRAY['R','W']::text[], '4', '4',
      'PSOS', 'mythic', 5.00, '201p', TRUE, 'normal', 5
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, 'commander', 'legal'
    FROM cards
    WHERE name IN (
      'Talrand, Sky Summoner',
      'Lightning Bolt',
      'Wastes',
      'Lorehold, the Historian'
    )
    ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
  " >"$RUN_DIR/fixture.log" 2>&1

CARD_CATALOG_COUNT="$(
  run_postgres_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM cards'
)"

run_server_consumer() (
  cd "$SERVER_DIR"
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export DB_HOST DB_PORT DB_USER DB_PASS
  export DB_NAME="$DATABASE"
  export JWT_SECRET="$ISOLATED_JWT_SECRET"
  export OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET"
  export OPENAI_API_KEY=""
  export OPENAI_BASE_URL=""
  export OPENAI_PROFILE="isolated_no_provider"
  export OPTIMIZE_COMPLETE_DISABLE_OPENAI=1
  export MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED=""
  export HTTP_PROXY="" HTTPS_PROXY="" ALL_PROXY=""
  export NO_PROXY="localhost,127.0.0.1,::1"
  export AI_GENERATE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT"
  export AI_OPTIMIZE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT"
  export MANALOOM_PASSWORD_RESET_TEST_RESPONSE="I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY"
  export MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE="I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY"
  export PASSWORD_RESET_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver"
  export PASSWORD_RESET_WEBHOOK_TOKEN="isolated-fixture"
  export PASSWORD_RESET_APP_URL="http://127.0.0.1:$PORT/app/#/reset-password"
  export EMAIL_VERIFICATION_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver"
  export EMAIL_VERIFICATION_WEBHOOK_TOKEN="isolated-fixture"
  export EMAIL_VERIFICATION_APP_URL="http://127.0.0.1:$PORT/app/#/verify-email"
  export MANALOOM_OPS_API_KEY="$OPS_KEY"
  export MANALOOM_E2E_ISOLATED_RUNTIME=1
  export MANALOOM_ALLOW_DEV_ORIGINS="${MANALOOM_ALLOW_DEV_ORIGINS:-false}"
  export MANALOOM_REQUIRE_LEGAL_ACCEPTANCE="${MANALOOM_REQUIRE_LEGAL_ACCEPTANCE:-false}"
  export MANALOOM_REQUIRE_VERIFIED_EMAIL="${MANALOOM_REQUIRE_VERIFIED_EMAIL:-false}"
  export BATTLE_JOB_WORKER_ENABLED=false
  export INTERACTIVE_BATTLE_ENABLED="${INTERACTIVE_BATTLE_ENABLED:-false}"
  export XMAGE_SIDECAR_URL="${XMAGE_SIDECAR_URL:-}"
  export XMAGE_INTERACTIVE_SIDECAR_URL="${XMAGE_INTERACTIVE_SIDECAR_URL:-}"
  export FORGE_SIDECAR_URL=""
  export NATIVE_BATTLE_SIDECAR_URL=""
  export XMAGE_EXPECTED_COMMIT="${XMAGE_EXPECTED_COMMIT:-}"
  export XMAGE_EXPECTED_PATCH_COMMIT="${XMAGE_EXPECTED_PATCH_COMMIT:-}"
  export XMAGE_EXPECTED_VERSION="${XMAGE_EXPECTED_VERSION:-}"
  export BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY="${BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY:-false}"
  export ENVIRONMENT="$ISOLATED_ENVIRONMENT" PORT="$PORT"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" \
    --packages="$SERVER_DIR/build/.dart_tool/package_config.json" \
    "$SERVER_DIR/build/bin/server.dart"
)

set -m
run_server_consumer >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
set +m
if ! SERVER_PGID="$(capture_owned_process_group "$SERVER_PID")"; then
  emergency_kill_status=0
  emergency_wait_status=0
  kill -TERM "$SERVER_PID" >/dev/null 2>&1 || emergency_kill_status="$?"
  wait "$SERVER_PID" >/dev/null 2>&1 || emergency_wait_status="$?"
  SERVER_PID=""
  echo "servidor não iniciou em process group próprio" >&2
  printf 'emergency_kill_status=%s emergency_wait_status=%s\n' \
    "$emergency_kill_status" "$emergency_wait_status" >&2
  exit 1
fi

ready=0
for _ in $(seq 1 80); do
  if run_no_egress curl -fsS \
    "http://127.0.0.1:$PORT/health/live" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "servidor encerrou antes do healthcheck" >&2
    tail -80 "$SERVER_LOG" >&2 || true
    exit 1
  fi
  sleep 0.25
done
if [[ "$ready" != 1 ]]; then
  echo "timeout aguardando /health/live" >&2
  tail -80 "$SERVER_LOG" >&2 || true
  exit 1
fi

# Optional browser-QA mode. It keeps the same disposable PostgreSQL/API/email
# fixture alive until the caller interrupts this process; the existing trap
# still owns and proves cleanup. No production coordinate is ever accepted.
if [[ "${MANALOOM_HOLD_FOR_BROWSER_QA:-0}" == "1" ]]; then
  BROWSER_READY="$RUN_DIR/browser-ready.env"
  {
    printf 'scope=browser_qa_isolated_loopback\n'
    printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
    printf 'database=%s\n' "$DATABASE"
    printf 'run_dir=%s\n' "$RUN_DIR"
    printf 'backend_run_id=%s\n' "$RUN_ID"
    printf 'parent_visual_run_id=%s\n' "$PARENT_VISUAL_RUN_ID"
    printf 'cleanup_receipt=%s\n' "$BACKEND_CLEANUP_RECEIPT"
    printf 'api_port=%s\n' "$PORT"
    printf 'email_port=%s\n' "$EMAIL_FIXTURE_PORT"
    printf 'egress_policy=%s\n' "$EGRESS_POLICY"
    printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
    printf 'egress_guard_self_test=%s\n' "$EGRESS_GUARD_SELF_TEST"
    printf 'cleanup=trap_registered\n'
  } >"$BROWSER_READY"
  printf 'READY: isolated browser QA fixture\n'
  printf 'ready_manifest=%s\n' "$BROWSER_READY"
  printf 'backend_run_id=%s\n' "$RUN_ID"
  printf 'parent_visual_run_id=%s\n' "$PARENT_VISUAL_RUN_ID"
  printf 'backend_run_dir=%s\n' "$RUN_DIR"
  printf 'cleanup_receipt=%s\n' "$BACKEND_CLEANUP_RECEIPT"
  printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
  printf 'api_port=%s\n' "$PORT"
  printf 'email_port=%s\n' "$EMAIL_FIXTURE_PORT"
  printf 'database=%s\n' "$DATABASE"
  while kill -0 "$SERVER_PID" >/dev/null 2>&1; do
    sleep 1
  done
  echo "servidor browser QA encerrou inesperadamente" >&2
  exit 1
fi

if (($# > 0)); then
  tests=("$@")
else
  tests=("test/error_contract_test.dart")
fi
run_test_consumer() (
  cd "$SERVER_DIR"
  unset PGHOST PGHOSTADDR PGPORT PGUSER PGDATABASE PGSERVICE PGSERVICEFILE
  unset PGPASSFILE PGPASSWORD
  export DB_HOST DB_PORT DB_USER DB_PASS
  export DB_NAME="$DATABASE"
  export OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET"
  export OPENAI_API_KEY=""
  export OPTIMIZE_COMPLETE_DISABLE_OPENAI=1
  export MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED=""
  export HTTP_PROXY="" HTTPS_PROXY="" ALL_PROXY=""
  export NO_PROXY="localhost,127.0.0.1,::1"
  export RUN_INTEGRATION_TESTS=1
  export MANALOOM_ISOLATED_CONTRACT_E2E=1
  export MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  export MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  export MANALOOM_TEST_OPS_API_KEY="$OPS_KEY"
  export TEST_API_BASE_URL="http://127.0.0.1:$PORT"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" test -j 1 "${tests[@]}"
)

run_test_consumer 2>&1 | tee "$TEST_LOG"

migration_count="$(
  run_postgres_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM schema_migrations'
)"
latest_migration="$(
  run_postgres_no_egress psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COALESCE(MAX(version), '\''none'\'') FROM schema_migrations'
)"
email_delivery_count="$(
  (wc -l <"$EMAIL_FIXTURE_LOG" 2>/dev/null || printf '0') | tr -d '[:space:]'
)"
email_delivery_templates="$(
  run_no_egress python3 - "$EMAIL_FIXTURE_LOG" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
templates = set()
if path.exists():
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            templates.add(json.loads(line)["template"])
print(",".join(sorted(templates)))
PY
)"
battle_sidecars_enabled=0
if [[ "$INTERACTIVE_BATTLE_ENABLED" == "true" ]]; then
  battle_sidecars_enabled=1
fi
if [[ -n "${MANALOOM_EXPECT_EMAIL_TEMPLATES:-}" ]]; then
  IFS=',' read -r -a expected_templates <<<"$MANALOOM_EXPECT_EMAIL_TEMPLATES"
  for template in "${expected_templates[@]}"; do
    if [[ ",$email_delivery_templates," != *",$template,"* ]]; then
      echo "template de email esperado não foi entregue: $template" >&2
      exit 1
    fi
  done
fi
{
  printf 'result=pass\n'
  printf 'scope=server_contract_e2e_isolated_loopback\n'
  printf 'tests=%s\n' "${tests[*]}"
  printf 'migration_count=%s\n' "$migration_count"
  printf 'card_catalog_count=%s\n' "$CARD_CATALOG_COUNT"
  printf 'server_environment=%s\n' "$ISOLATED_ENVIRONMENT"
  printf 'egress_policy=%s\n' "$EGRESS_POLICY"
  printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
  printf 'egress_guard_self_test=%s\n' "$EGRESS_GUARD_SELF_TEST"
  printf 'openai_profile=isolated_no_provider\n'
  printf 'openai_provider_enabled=0\n'
  printf 'edhrec_collection_enabled=0\n'
  printf 'battle_sidecars_enabled=%s\n' "$battle_sidecars_enabled"
  printf 'optimization_apply_signing=isolated_ephemeral\n'
  printf 'full_card_catalog_enabled=%s\n' "${MANALOOM_ISOLATED_FULL_CARD_CATALOG:-0}"
  printf 'latest_migration=%s\n' "$latest_migration"
  printf 'email_delivery_count=%s\n' "$email_delivery_count"
  printf 'email_delivery_templates=%s\n' "$email_delivery_templates"
  printf 'email_delivery_log=sanitized_without_links_or_tokens\n'
  printf 'database_cleanup=canonical_receipt_pending\n'
  printf 'server_cleanup=canonical_receipt_pending\n'
  printf 'build_adapter=PASS_OFFLINE_BUILD_ADAPTER\n'
  printf 'build_adapter_tree_sha256=%s\n' "$BUILD_DIGEST"
  printf 'build_adapter_cleanup=owned_digest_guard_registered\n'
} >"$SUMMARY"

NORMAL_SUMMARY_SHA="$(shasum -a 256 "$SUMMARY" | awk '{print $1}')"
NORMAL_RUN_COMPLETED=1
