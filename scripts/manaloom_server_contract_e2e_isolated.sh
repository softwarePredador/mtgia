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
SERVER_DIR="$ROOT_DIR/server"

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval "E2E de contrato da API em PostgreSQL descartável"
require_live_mutation_approval "E2E de contrato da API em PostgreSQL descartável"

for tool in cp createdb curl dropdb git lsof perl ps psql python3 shasum sort; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatória ausente: $tool" >&2
    exit 2
  }
done

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-$(id -un)}"
DB_ADMIN="${MANALOOM_S1_PG_ADMIN_DB:-postgres}"
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

case "$DB_HOST" in
  127.0.0.1) ;;
  *) echo "BLOCKED: harness aceita somente PostgreSQL loopback" >&2; exit 2 ;;
esac
if [[ ! "$DB_PORT" =~ ^[0-9]{1,5}$ ]] ||
   ((10#$DB_PORT < 1 || 10#$DB_PORT > 65535)); then
  echo "BLOCKED: porta PostgreSQL inválida" >&2
  exit 2
fi
if [[ ! "$DB_ADMIN" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "BLOCKED: admin database inválido" >&2
  exit 2
fi

# Use the project-locked CLI, never the independently activated global CLI.
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

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

run_pg() (
  export PGPASSWORD="$FIXTURE_DB_PASSWORD"
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
E2E_VALIDATION_RUN_TOKEN="server-contract-$RUN_ID"
OPS_KEY="manaloom-isolated-ops-${RUN_ID}-key-material"
ISOLATED_JWT_SECRET="manaloom-isolated-contract-${RUN_ID}-not-production"
ISOLATED_OPTIMIZATION_SIGNING_SECRET="$(
  run_no_egress python3 -c \
    'import secrets; print("manaloom-isolated-optimization-" + secrets.token_hex(32))'
)"
DATABASE="manaloom_s1_api_${RUN_ID}"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"
RUN_DIR="$TMP_ROOT/manaloom_server_contract_e2e_${RUN_ID}"
SERVER_LOG="$RUN_DIR/server.log"
EMAIL_FIXTURE_LOG="$RUN_DIR/email-delivery-evidence.jsonl"
TEST_LOG="$RUN_DIR/tests.log"
SUMMARY="$RUN_DIR/summary.txt"
CLEANUP_SUMMARY="$RUN_DIR/cleanup.txt"

RECEIPT_DIR="${MANALOOM_ISOLATED_E2E_RECEIPT_DIR:-}"
RECEIPT_SUMMARY=""
RECEIPT_CLEANUP=""
if [[ -n "$RECEIPT_DIR" ]]; then
  case "$RECEIPT_DIR" in
    /*) ;;
    *)
      echo "MANALOOM_ISOLATED_E2E_RECEIPT_DIR must be absolute" >&2
      exit 2
      ;;
  esac
  if [[ ! -d "$RECEIPT_DIR" || -L "$RECEIPT_DIR" ]]; then
    echo "MANALOOM_ISOLATED_E2E_RECEIPT_DIR must be a real directory" >&2
    exit 2
  fi
  receipt_real="$(CDPATH='' cd -- "$RECEIPT_DIR" && pwd -P)"
  tmp_real="$(CDPATH='' cd -- "$TMP_ROOT" && pwd -P)"
  case "$receipt_real" in
    "$tmp_real"/*) ;;
    *)
      echo "MANALOOM_ISOLATED_E2E_RECEIPT_DIR must stay under TMPDIR" >&2
      exit 2
      ;;
  esac
  RECEIPT_DIR="$receipt_real"
  RECEIPT_SUMMARY="$RECEIPT_DIR/summary.txt"
  RECEIPT_CLEANUP="$RECEIPT_DIR/cleanup.txt"
fi

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
BOOTSTRAP_PID=""
EMAIL_FIXTURE_PID=""
EMAIL_FIXTURE_RUNTIME_PID=""
FORCED_CLEANUP_USED=0
RUN_OWNED=0
DATABASE_ATTEMPTED=0
BUILD_SAVED=()
BUILD_MANAGED=()

run_bootstrap_phase() {
  local phase_log="$1"
  local phase_exit=0
  shift
  # Bash job control gives this owned child and all its workers one group.
  # wait is interruptible; cleanup can stop the group before restoring PRE.
  set -m
  (cd "$SERVER_DIR" && exec "$@") >"$phase_log" 2>&1 &
  BOOTSTRAP_PID=$!
  set +m
  wait "$BOOTSTRAP_PID" || phase_exit=$?
  if kill -0 -- "-$BOOTSTRAP_PID" >/dev/null 2>&1; then
    echo "BLOCKED: bootstrap left an owned process group" >&2
    return 1
  fi
  BOOTSTRAP_PID=""
  return "$phase_exit"
}

terminate_bootstrap_group() {
  local child_exit=0
  [[ -n "$BOOTSTRAP_PID" ]] || return 0
  if kill -0 -- "-$BOOTSTRAP_PID" >/dev/null 2>&1; then
    kill -TERM -- "-$BOOTSTRAP_PID" >/dev/null 2>&1 || return 1
    for _ in $(seq 1 100); do
      kill -0 -- "-$BOOTSTRAP_PID" >/dev/null 2>&1 || break
      sleep 0.1
    done
    if kill -0 -- "-$BOOTSTRAP_PID" >/dev/null 2>&1; then
      FORCED_CLEANUP_USED=1
      kill -KILL -- "-$BOOTSTRAP_PID" >/dev/null 2>&1 || return 1
      wait "$BOOTSTRAP_PID" >/dev/null 2>&1 || true
      return 1
    fi
  fi
  wait "$BOOTSTRAP_PID" >/dev/null 2>&1 || child_exit=$?
  [[ "$child_exit" != 127 ]] || return 1
  ! kill -0 -- "-$BOOTSTRAP_PID" >/dev/null 2>&1 || return 1
  BOOTSTRAP_PID=""
}

terminate_fixture_pid() {
  local process_id="$1"
  local child_exit=0
  [[ -n "$process_id" ]] || return 0
  if kill -0 "$process_id" >/dev/null 2>&1; then
    kill -TERM "$process_id" >/dev/null 2>&1 || return 1
    for _ in $(seq 1 100); do
      kill -0 "$process_id" >/dev/null 2>&1 || break
      sleep 0.1
    done
    if kill -0 "$process_id" >/dev/null 2>&1; then
      FORCED_CLEANUP_USED=1
      kill -KILL "$process_id" >/dev/null 2>&1 || return 1
      wait "$process_id" >/dev/null 2>&1 || true
      return 1
    fi
  fi
  wait "$process_id" >/dev/null 2>&1 || child_exit=$?
  case "$child_exit" in 0|130|143) ;; *) return 1 ;; esac
  ! kill -0 "$process_id" >/dev/null 2>&1
}

restore_build_outputs() {
  local output
  for output in ${BUILD_MANAGED[@]+"${BUILD_MANAGED[@]}"}; do
    # Only these ignored outputs were handed to this run, after saving PRE.
    [[ ! -L "$SERVER_DIR/$output" ]] || return 1
    git -C "$ROOT_DIR" check-ignore -q "server/$output/" || return 1
    rm -rf -- "$SERVER_DIR/$output" || return 1
    [[ ! -e "$SERVER_DIR/$output" ]] || return 1
  done
  for output in ${BUILD_SAVED[@]+"${BUILD_SAVED[@]}"}; do
    [[ ! -e "$SERVER_DIR/$output" && ! -L "$SERVER_DIR/$output" ]] || return 1
    mv -- "$RUN_DIR/pre-$output" "$SERVER_DIR/$output" || return 1
  done
  BUILD_MANAGED=()
  BUILD_SAVED=()
}

backend_listener_count() {
  local port="$1"
  local listeners=""
  local lookup_exit=0
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>"$RUN_DIR/listener-check.log")" ||
    lookup_exit=$?
  if [[ -s "$RUN_DIR/listener-check.log" || "$lookup_exit" -gt 1 ]]; then
    printf 'unknown'
    return 1
  fi
  printf '%s\n' "$listeners" | awk 'NR > 1 {count++} END {print count + 0}'
}

cleanup() {
  local original_status="$?"
  local cleanup_status=0
  local database_remaining=0
  local api_listeners=0
  local email_fixture_listeners=0
  trap - EXIT HUP INT TERM
  set +e
  [[ "$RUN_OWNED" == 1 ]] || exit "$original_status"
  terminate_bootstrap_group || cleanup_status=1
  terminate_fixture_pid "$SERVER_PID" || cleanup_status=1
  terminate_fixture_pid "$EMAIL_FIXTURE_PID" || cleanup_status=1
  if [[ "$DATABASE_ATTEMPTED" == 1 ]]; then
    run_pg dropdb --if-exists --force \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
      --maintenance-db="$DB_ADMIN" "$DATABASE" \
      >"$RUN_DIR/dropdb.log" 2>&1 || cleanup_status=1
    if ! database_remaining="$(
      run_pg psql -X -A -t \
        -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_ADMIN" \
        -c "SELECT COUNT(*) FROM pg_database WHERE datname = '$DATABASE'" \
        2>"$RUN_DIR/database-cleanup-check.log" | tr -d '[:space:]'
    )"; then
      database_remaining=unknown
      cleanup_status=1
    fi
  fi
  api_listeners="$(backend_listener_count "$PORT")" || cleanup_status=1
  email_fixture_listeners="$(backend_listener_count "$EMAIL_FIXTURE_PORT")" || cleanup_status=1
  if [[ "$database_remaining" != 0 || "$api_listeners" != 0 ||
        "$email_fixture_listeners" != 0 ]]; then
    cleanup_status=1
  fi
  # Never remove or restore code under a live API process.
  if [[ "$cleanup_status" == 0 ]]; then
    restore_build_outputs || cleanup_status=1
  fi
  rm -f -- "$RUN_DIR/AtomicCards.json" || cleanup_status=1
  if [[ -n "$RECEIPT_SUMMARY" && -f "$SUMMARY" ]]; then
    cp "$SUMMARY" "$RECEIPT_SUMMARY" || cleanup_status=1
  fi
  {
    printf 'result=%s\n' "$([[ "$cleanup_status" == 0 ]] && printf pass || printf fail)"
    printf 'run_id=%s\n' "$RUN_ID"
    printf 'database=%s\n' "$DATABASE"
    printf 'database_remaining=%s\n' "$database_remaining"
    printf 'api_port=%s\n' "$PORT"
    printf 'api_listeners=%s\n' "$api_listeners"
    printf 'email_fixture_port=%s\n' "$EMAIL_FIXTURE_PORT"
    printf 'email_fixture_listeners=%s\n' "$email_fixture_listeners"
    printf 'forced_kill_used=%s\n' "$FORCED_CLEANUP_USED"
    printf 'build_baseline_restored=%s\n' "$([[ "$cleanup_status" == 0 ]] && printf true || printf false)"
    printf 'original_exit_code=%s\n' "$original_status"
  } >"$CLEANUP_SUMMARY" || cleanup_status=1
  if [[ -n "$RECEIPT_CLEANUP" ]]; then
    cp "$CLEANUP_SUMMARY" "$RECEIPT_CLEANUP" || cleanup_status=1
  fi
  if [[ "$original_status" == 0 && "$cleanup_status" != 0 ]]; then
    original_status=1
  fi
  exit "$original_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -m 700 "$RUN_DIR"
RUN_OWNED=1
touch "$EMAIL_FIXTURE_LOG"

# Dependency/bootstrap work is separate from guarded runtime: no database,
# email fixture or API exists yet. Resolve the project-pinned CLI, not global.
for output in build .dart_frog; do
  [[ ! -L "$SERVER_DIR/$output" ]] || {
    echo "BLOCKED: symbolic build output: $output" >&2; exit 2;
  }
  git -C "$ROOT_DIR" check-ignore -q "server/$output/" || exit 2
  if [[ -e "$SERVER_DIR/$output" ]]; then
    [[ -d "$SERVER_DIR/$output" ]] || exit 2
    build_consumers="$(lsof -t +D "$SERVER_DIR/$output" 2>"$RUN_DIR/build-consumers.log")" || {
      [[ $? == 1 && ! -s "$RUN_DIR/build-consumers.log" ]] || exit 2
    }
    [[ -z "$build_consumers" ]] || {
      echo "BLOCKED: build output has a consumer" >&2; exit 2;
    }
    mv -- "$SERVER_DIR/$output" "$RUN_DIR/pre-$output"
    BUILD_SAVED+=("$output")
  fi
  BUILD_MANAGED+=("$output")
done
run_bootstrap_phase "$RUN_DIR/pub-offline.log" \
  "$DART_BIN" pub get --offline --enforce-lockfile --no-precompile
run_bootstrap_phase "$RUN_DIR/build.log" \
  "$DART_BIN" run dart_frog_cli:dart_frog build
perl -0pi -e \
  's/final address = InternetAddress[.]anyIPv6;/final address = InternetAddress.loopbackIPv4;/' \
  "$SERVER_DIR/build/bin/server.dart"
if ! grep -Fq 'final address = InternetAddress.loopbackIPv4;' \
  "$SERVER_DIR/build/bin/server.dart"; then
  echo "BLOCKED: build isolado da API não pôde ser restrito ao loopback IPv4" >&2
  exit 1
fi

(
  export MANALOOM_EMAIL_FIXTURE_PORT="$EMAIL_FIXTURE_PORT"
  export MANALOOM_EMAIL_FIXTURE_LOG="$EMAIL_FIXTURE_LOG"
  exec "${EGRESS_GUARD[@]}" python3 \
    "$ROOT_DIR/scripts/testing/manaloom_email_webhook_fixture.py"
) >"$RUN_DIR/email-fixture.log" 2>&1 &
EMAIL_FIXTURE_PID=$!
email_fixture_ready=0
for _ in $(seq 1 40); do
  if run_no_egress curl -fsS \
    "http://127.0.0.1:$EMAIL_FIXTURE_PORT/health" >/dev/null 2>&1; then
    email_fixture_ready=1
    break
  fi
  if ! kill -0 "$EMAIL_FIXTURE_PID" >/dev/null 2>&1; then
    echo "fixture de email encerrou antes do healthcheck" >&2
    exit 1
  fi
  sleep 0.1
done
if [[ "$email_fixture_ready" != "1" ]]; then
  echo "timeout aguardando fixture de email" >&2
  exit 1
fi
email_fixture_listener_pids="$(
  lsof -nP -t -iTCP:"$EMAIL_FIXTURE_PORT" -sTCP:LISTEN 2>/dev/null |
    sort -u
)"
email_fixture_listener_count="$(
  printf '%s\n' "$email_fixture_listener_pids" |
    awk 'NF {count++} END {print count + 0}'
)"
if [[ "$email_fixture_listener_count" != "1" ]]; then
  echo "fixture de email deve possuir exatamente um listener" >&2
  exit 1
fi
EMAIL_FIXTURE_RUNTIME_PID="$email_fixture_listener_pids"
if [[ "$EMAIL_FIXTURE_RUNTIME_PID" != "$EMAIL_FIXTURE_PID" ]]; then
  echo "fixture de email perdeu ownership do processo" >&2
  exit 1
fi
case "$EMAIL_FIXTURE_RUNTIME_PID" in
  '' | *[!0-9]*)
    echo "PID de runtime da fixture de email é inválido" >&2
    exit 1
    ;;
esac
email_fixture_command="$(
  ps -p "$EMAIL_FIXTURE_RUNTIME_PID" -o command=
)"
if [[ "$email_fixture_command" != *"manaloom_email_webhook_fixture.py"* ]]; then
  echo "listener da fixture de email não pertence ao processo esperado" >&2
  exit 1
fi

DATABASE_ATTEMPTED=1
run_pg createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  --maintenance-db="$DB_ADMIN" "$DATABASE"
run_pg psql -X -v ON_ERROR_STOP=1 \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" \
  -f "$SERVER_DIR/database_setup.sql" >"$RUN_DIR/bootstrap.log" 2>&1

(
  cd "$SERVER_DIR"
  export \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$FIXTURE_DB_PASSWORD" DB_NAME="$DATABASE" \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" run bin/migrate.dart
) >"$RUN_DIR/migrate.log" 2>&1

# Deterministic product fixture used by card, deck, community and trade flows.
# It exists only in the disposable database and is removed with that database.
run_pg psql -X -v ON_ERROR_STOP=1 \
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
    UPDATE cards
    SET set_code = 'HOB', collector_number = '194'
    WHERE scryfall_id = '00000000-0000-4000-8000-000000000003'::uuid;
    INSERT INTO cards (
      scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
      colors, color_identity, power, toughness, set_code, rarity,
      price_usd, collector_number, foil, layout, cmc
    ) VALUES
    (
      '20000000-0000-4000-8000-000000000001'::uuid,
      '20000000-0000-4000-8000-000000000010'::uuid,
      'Mountain', NULL, 'Basic Land — Mountain',
      '({T}: Add {R}.)', ARRAY[]::text[], ARRAY['R']::text[], NULL, NULL,
      'HOB', 'common', 0.10, '197', FALSE, 'normal', 0
    ),
    (
      '20000000-0000-4000-8000-000000000002'::uuid,
      '20000000-0000-4000-8000-000000000011'::uuid,
      'Isamaru, Hound of Konda', '{W}',
      'Legendary Creature — Dog',
      NULL, ARRAY['W']::text[], ARRAY['W']::text[], '2', '2',
      'CHK', 'rare', 1.00, '19', FALSE, 'normal', 1
    ),
    (
      '20000000-0000-4000-8000-000000000003'::uuid,
      '20000000-0000-4000-8000-000000000012'::uuid,
      'Krenko, Mob Boss', '{2}{R}{R}',
      'Legendary Creature — Goblin Warrior',
      '{T}: Create X 1/1 red Goblin creature tokens, where X is the number of Goblins you control.',
      ARRAY['R']::text[], ARRAY['R']::text[], '3', '3',
      'FDN', 'rare', 1.00, '204', FALSE, 'normal', 4
    )
    ON CONFLICT (scryfall_id) DO NOTHING;
    INSERT INTO card_legalities (card_id, format, status)
    SELECT id, 'commander', 'legal'
    FROM cards
    WHERE name IN ('Mountain', 'Isamaru, Hound of Konda', 'Krenko, Mob Boss')
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
  run_pg psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM cards'
)"

(
  cd "$SERVER_DIR"
  export \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$FIXTURE_DB_PASSWORD" DB_NAME="$DATABASE" \
    JWT_SECRET="$ISOLATED_JWT_SECRET" \
    OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET" \
    OPENAI_API_KEY= \
    OPENAI_BASE_URL= \
    OPENAI_PROFILE="isolated_no_provider" \
    OPTIMIZE_COMPLETE_DISABLE_OPENAI=1 \
    MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED= \
    HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= \
    NO_PROXY="localhost,127.0.0.1,::1" \
    AI_GENERATE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT" \
    AI_OPTIMIZE_INTERNAL_BASE_URL="http://127.0.0.1:$PORT" \
    MANALOOM_PASSWORD_RESET_TEST_RESPONSE="I_UNDERSTAND_RESET_TOKENS_ARE_TEST_ONLY" \
    MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE="I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY" \
    PASSWORD_RESET_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    PASSWORD_RESET_WEBHOOK_TOKEN="isolated-fixture" \
    PASSWORD_RESET_APP_URL="http://127.0.0.1:$PORT/app/#/reset-password" \
    EMAIL_VERIFICATION_WEBHOOK_URL="http://127.0.0.1:$EMAIL_FIXTURE_PORT/deliver" \
    EMAIL_VERIFICATION_WEBHOOK_TOKEN="isolated-fixture" \
    EMAIL_VERIFICATION_APP_URL="http://127.0.0.1:$PORT/app/#/verify-email" \
    MANALOOM_OPS_API_KEY="$OPS_KEY" \
    MANALOOM_E2E_ISOLATED_RUNTIME=1 \
    MANALOOM_E2E_VALIDATION_RUN_TOKEN="$E2E_VALIDATION_RUN_TOKEN" \
    MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="${MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE:-}" \
    MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES="${MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES:-}" \
    MANALOOM_ALLOW_DEV_ORIGINS="${MANALOOM_ALLOW_DEV_ORIGINS:-false}" \
    MANALOOM_REQUIRE_LEGAL_ACCEPTANCE="${MANALOOM_REQUIRE_LEGAL_ACCEPTANCE:-false}" \
    MANALOOM_REQUIRE_VERIFIED_EMAIL="${MANALOOM_REQUIRE_VERIFIED_EMAIL:-false}" \
    BATTLE_JOB_WORKER_ENABLED=false \
    INTERACTIVE_BATTLE_ENABLED="${INTERACTIVE_BATTLE_ENABLED:-false}" \
    XMAGE_SIDECAR_URL="${XMAGE_SIDECAR_URL:-}" \
    XMAGE_INTERACTIVE_SIDECAR_URL="${XMAGE_INTERACTIVE_SIDECAR_URL:-}" \
    FORGE_SIDECAR_URL= \
    NATIVE_BATTLE_SIDECAR_URL= \
    XMAGE_EXPECTED_COMMIT="${XMAGE_EXPECTED_COMMIT:-}" \
    XMAGE_EXPECTED_PATCH_COMMIT="${XMAGE_EXPECTED_PATCH_COMMIT:-}" \
    XMAGE_EXPECTED_VERSION="${XMAGE_EXPECTED_VERSION:-}" \
    BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY="${BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY:-false}" \
    ENVIRONMENT="$ISOLATED_ENVIRONMENT" PORT="$PORT"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" build/bin/server.dart
) >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

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
API_LISTENERS="$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN || true)"
if [[ -z "$API_LISTENERS" ]] || printf '%s\n' "$API_LISTENERS" | \
  awk 'NR > 1 && $9 !~ /^127[.]0[.]0[.]1:/ { bad=1 } END { exit bad ? 0 : 1 }'; then
  echo "BLOCKED: API isolada abriu listener fora do loopback IPv4" >&2
  printf '%s\n' "$API_LISTENERS" >&2
  exit 1
fi

# Optional browser-QA mode. It keeps the same disposable PostgreSQL/API/email
# fixture alive until the caller interrupts this process; the existing trap
# still owns and proves cleanup. No production coordinate is ever accepted.
if [[ "${MANALOOM_HOLD_FOR_BROWSER_QA:-0}" == "1" ]]; then
  BROWSER_QA_COMPLETION_FILE="${MANALOOM_BROWSER_QA_COMPLETION_FILE:-}"
  if [[ -n "$BROWSER_QA_COMPLETION_FILE" ]]; then
    case "$BROWSER_QA_COMPLETION_FILE" in
      /*) ;;
      *)
        echo "MANALOOM_BROWSER_QA_COMPLETION_FILE must be absolute" >&2
        exit 2
        ;;
    esac
    browser_completion_parent="$(dirname -- "$BROWSER_QA_COMPLETION_FILE")"
    if [[ ! -d "$browser_completion_parent" ||
          -L "$browser_completion_parent" ]]; then
      echo "Browser QA completion parent must be a real directory" >&2
      exit 2
    fi
    browser_completion_parent_real="$(
      CDPATH='' cd -- "$browser_completion_parent" && pwd -P
    )"
    tmp_real="$(CDPATH='' cd -- "$TMP_ROOT" && pwd -P)"
    case "$browser_completion_parent_real" in
      "$tmp_real"/*) ;;
      *)
        echo "Browser QA completion file must stay under TMPDIR" >&2
        exit 2
        ;;
    esac
    BROWSER_QA_COMPLETION_FILE="$browser_completion_parent_real/$(
      basename -- "$BROWSER_QA_COMPLETION_FILE"
    )"
    if [[ -e "$BROWSER_QA_COMPLETION_FILE" ||
          -L "$BROWSER_QA_COMPLETION_FILE" ]]; then
      echo "Browser QA completion file must not exist before readiness" >&2
      exit 2
    fi
  fi
  BROWSER_READY="$RUN_DIR/browser-ready.env"
  {
    printf 'scope=browser_qa_isolated_loopback\n'
    printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
    printf 'database=%s\n' "$DATABASE"
    printf 'run_dir=%s\n' "$RUN_DIR"
    printf 'egress_policy=%s\n' "$EGRESS_POLICY"
    printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
    printf 'egress_guard_self_test=%s\n' "$EGRESS_GUARD_SELF_TEST"
    printf 'completion_file=%s\n' "$BROWSER_QA_COMPLETION_FILE"
    printf 'cleanup=trap_registered\n'
  } >"$BROWSER_READY"
  printf 'READY: isolated browser QA fixture\n'
  printf 'ready_manifest=%s\n' "$BROWSER_READY"
  printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
  printf 'database=%s\n' "$DATABASE"
  while kill -0 "$SERVER_PID" >/dev/null 2>&1; do
    if [[ -n "$BROWSER_QA_COMPLETION_FILE" &&
          -f "$BROWSER_QA_COMPLETION_FILE" &&
          ! -L "$BROWSER_QA_COMPLETION_FILE" ]]; then
      browser_completion_value="$(
        tr -d '\r\n' <"$BROWSER_QA_COMPLETION_FILE"
      )"
      if [[ "$browser_completion_value" != "complete" ]]; then
        echo "Browser QA completion file has invalid content" >&2
        exit 1
      fi
      {
        printf 'result=pass\n'
        printf 'scope=browser_qa_isolated_loopback\n'
        printf 'database=%s\n' "$DATABASE"
        printf 'api_base_url=http://127.0.0.1:%s\n' "$PORT"
        printf 'card_catalog_count=%s\n' "$CARD_CATALOG_COUNT"
        printf 'egress_policy=%s\n' "$EGRESS_POLICY"
        printf 'egress_guard=%s\n' "$EGRESS_GUARD_KIND"
        printf 'browser_completion=pass\n'
      } >"$SUMMARY"
      printf 'PASS: isolated browser QA fixture completed\n'
      printf 'summary=%s\n' "$SUMMARY"
      printf 'summary_sha256=%s\n' "$(
        shasum -a 256 "$SUMMARY" | awk '{print $1}'
      )"
      exit 0
    fi
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
(
  cd "$SERVER_DIR"
  export \
    DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_USER="$DB_USER" \
    DB_PASS="$FIXTURE_DB_PASSWORD" DB_NAME="$DATABASE" \
    OPTIMIZATION_APPLY_SIGNING_SECRET="$ISOLATED_OPTIMIZATION_SIGNING_SECRET" \
    OPENAI_API_KEY= \
    OPTIMIZE_COMPLETE_DISABLE_OPENAI=1 \
    MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED= \
    HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= \
    NO_PROXY="localhost,127.0.0.1,::1" \
    RUN_INTEGRATION_TESTS=1 \
    MANALOOM_ISOLATED_CONTRACT_E2E=1 \
    MANALOOM_PLAY_VS_AI_REAL_XMAGE_E2E="${MANALOOM_PLAY_VS_AI_REAL_XMAGE_E2E:-0}" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_TEST_OPS_API_KEY="$OPS_KEY" \
    TEST_API_BASE_URL="http://127.0.0.1:$PORT"
  exec "${EGRESS_GUARD[@]}" "$DART_BIN" test -j 1 "${tests[@]}"
) 2>&1 | tee "$TEST_LOG"

migration_count="$(
  run_pg psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DATABASE" -c 'SELECT COUNT(*) FROM schema_migrations'
)"
latest_migration="$(
  run_pg psql -X -A -t -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
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
  printf 'database_cleanup=trap_registered\n'
  printf 'server_cleanup=trap_registered\n'
} >"$SUMMARY"

SUMMARY_SHA="$(shasum -a 256 "$SUMMARY" | awk '{print $1}')"
printf 'PASS: isolated server contract E2E\n'
printf 'summary=%s\n' "$SUMMARY"
printf 'summary_sha256=%s\n' "$SUMMARY_SHA"
