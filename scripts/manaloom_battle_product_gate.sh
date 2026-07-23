#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"
# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"

MODE="${1:---static}"
AUDIT_OUT="$(mktemp -t manaloom-battle-product-audit.XXXXXX.json)"
MANIFEST_OUT="$(mktemp -t manaloom-battle-runtime-manifest.XXXXXX.json)"
PIN_AUDIT_OUT="$(mktemp -t manaloom-engine-pin-audit.XXXXXX.json)"
TEMP_FILES=("$AUDIT_OUT" "$MANIFEST_OUT" "$PIN_AUDIT_OUT")
STATIC_AUDIT_DIR="$(mktemp -d -t manaloom-battle-static-audits.XXXXXX)"

API_PID=""
NATIVE_PID=""
API_LISTENER_PIDS=""
NATIVE_LISTENER_PIDS=""
POSTGRES_LISTENER_PIDS=""
PROCESS_STOP_OK=1
MUTATION_ARMED=0
VALIDATION_EMAIL=""
VALIDATION_USERNAME=""
VALIDATION_INTRUDER_EMAIL=""
VALIDATION_INTRUDER_USERNAME=""
RUN_DIR=""
POSTGRES_DATA_DIR=""
POSTGRES_SOCKET_DIR=""
POSTGRES_PORT=""
POSTGRES_STARTED=0
KEEP_E2E_ARTIFACTS="${MANALOOM_KEEP_BATTLE_E2E_ARTIFACTS:-0}"

usage() {
  cat <<'EOF'
Usage: scripts/manaloom_battle_product_gate.sh [--static|--isolated-e2e]

  --static        Run deterministic battle product contracts (default).
  --isolated-e2e  Start a disposable PostgreSQL cluster, native sidecar and
                  mutable API on 127.0.0.1, run the Battle product E2E with
                  unique identities, then remove every temporary process,
                  listener and database file.
EOF
}

stop_isolated_processes() {
  local api_tree="" native_tree=""
  if [[ -n "$API_PID" ]]; then
    api_tree="$(collect_process_tree_pids "$API_PID")"
  fi
  if [[ -n "$NATIVE_PID" ]]; then
    native_tree="$(collect_process_tree_pids "$NATIVE_PID")"
  fi
  if ! terminate_owned_processes \
    "$api_tree" \
    "$native_tree" \
    "$API_PID" \
    "$NATIVE_PID" \
    "$API_LISTENER_PIDS" \
    "$NATIVE_LISTENER_PIDS"; then
    PROCESS_STOP_OK=0
  fi
  if [[ -n "$API_PID" ]]; then
    wait "$API_PID" 2>/dev/null || true
  fi
  if [[ -n "$NATIVE_PID" ]]; then
    wait "$NATIVE_PID" 2>/dev/null || true
  fi
  API_PID=""
  NATIVE_PID=""
  return 0
}

stop_disposable_postgres() {
  if [[ "$POSTGRES_STARTED" -ne 1 || -z "$POSTGRES_DATA_DIR" ]]; then
    return 0
  fi
  if ! pg_ctl -D "$POSTGRES_DATA_DIR" -m fast stop >/dev/null 2>&1; then
    PROCESS_STOP_OK=0
  fi
  POSTGRES_STARTED=0
  return 0
}

e2e_psql() {
  PGPASSWORD="${DB_PASS:-}" psql -X -qAt -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" "$@"
}

database_snapshot() {
  e2e_psql \
    -v validation_email="$VALIDATION_EMAIL" \
    -v validation_username="$VALIDATION_USERNAME" \
    -v intruder_email="$VALIDATION_INTRUDER_EMAIL" \
    -v intruder_username="$VALIDATION_INTRUDER_USERNAME" <<'SQL'
WITH target_users AS MATERIALIZED (
  SELECT id
  FROM users
  WHERE (LOWER(email) = LOWER(:'validation_email')
    AND LOWER(username) = LOWER(:'validation_username'))
     OR (LOWER(email) = LOWER(:'intruder_email')
    AND LOWER(username) = LOWER(:'intruder_username'))
),
target_decks AS MATERIALIZED (
  SELECT id FROM decks WHERE user_id IN (SELECT id FROM target_users)
),
target_simulations AS MATERIALIZED (
  SELECT id
  FROM battle_simulations
  WHERE deck_a_id IN (SELECT id FROM target_decks)
     OR deck_b_id IN (SELECT id FROM target_decks)
     OR winner_deck_id IN (SELECT id FROM target_decks)
)
SELECT jsonb_build_object(
  'users', (SELECT COUNT(*) FROM target_users),
  'decks', (SELECT COUNT(*) FROM target_decks),
  'deck_cards', (
    SELECT COUNT(*) FROM deck_cards WHERE deck_id IN (SELECT id FROM target_decks)
  ),
  'battle_simulations', (SELECT COUNT(*) FROM target_simulations)
)::text;
SQL
}

identity_collision_count() {
  e2e_psql \
    -v validation_email="$VALIDATION_EMAIL" \
    -v validation_username="$VALIDATION_USERNAME" \
    -v intruder_email="$VALIDATION_INTRUDER_EMAIL" \
    -v intruder_username="$VALIDATION_INTRUDER_USERNAME" <<'SQL'
SELECT COUNT(*)
FROM users
WHERE LOWER(email) = LOWER(:'validation_email')
   OR LOWER(username) = LOWER(:'validation_username')
   OR LOWER(email) = LOWER(:'intruder_email')
   OR LOWER(username) = LOWER(:'intruder_username');
SQL
}

cleanup_battle_identity() {
  e2e_psql \
    -v validation_email="$VALIDATION_EMAIL" \
    -v validation_username="$VALIDATION_USERNAME" \
    -v intruder_email="$VALIDATION_INTRUDER_EMAIL" \
    -v intruder_username="$VALIDATION_INTRUDER_USERNAME" <<'SQL'
BEGIN;
CREATE TEMP TABLE manaloom_target_users ON COMMIT DROP AS
SELECT id
FROM users
WHERE (LOWER(email) = LOWER(:'validation_email')
  AND LOWER(username) = LOWER(:'validation_username'))
   OR (LOWER(email) = LOWER(:'intruder_email')
  AND LOWER(username) = LOWER(:'intruder_username'));

CREATE TEMP TABLE manaloom_target_decks ON COMMIT DROP AS
SELECT id FROM decks WHERE user_id IN (SELECT id FROM manaloom_target_users);

WITH deleted AS (
  DELETE FROM battle_simulations
  WHERE deck_a_id IN (SELECT id FROM manaloom_target_decks)
     OR deck_b_id IN (SELECT id FROM manaloom_target_decks)
     OR winner_deck_id IN (SELECT id FROM manaloom_target_decks)
  RETURNING id
)
SELECT COUNT(*) AS deleted_simulations FROM deleted \gset

WITH deleted AS (
  DELETE FROM users WHERE id IN (SELECT id FROM manaloom_target_users)
  RETURNING id
)
SELECT COUNT(*) AS deleted_users FROM deleted \gset

SELECT jsonb_build_object(
  'battle_simulations', :deleted_simulations::integer,
  'users', :deleted_users::integer
)::text;
COMMIT;
SQL
}

cleanup_on_exit() {
  local status="$?"
  set +e
  stop_isolated_processes
  if [[ "$MUTATION_ARMED" -eq 1 && "$POSTGRES_STARTED" -eq 1 && -n "$VALIDATION_EMAIL" ]]; then
    cleanup_battle_identity >/dev/null 2>&1
  fi
  stop_disposable_postgres
  rm -f "${TEMP_FILES[@]}"
  rm -rf "$STATIC_AUDIT_DIR"
  if [[ -n "$RUN_DIR" && "$KEEP_E2E_ARTIFACTS" != "1" ]]; then
    rm -rf "$RUN_DIR"
  fi
  return "$status"
}
trap cleanup_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

select_free_loopback_port() {
  python3 - <<'PY'
import socket

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
}

build_battle_fixture_json() {
  local knowledge_db="$1"
  local deck_file="$2"
  local output="$3"
  python3 - "$knowledge_db" "$deck_file" "$output" <<'PY'
import hashlib
import json
import re
import sqlite3
import sys
import uuid
from pathlib import Path

knowledge_db, deck_file, output = map(Path, sys.argv[1:])
requested = []
for line in deck_file.read_text(encoding="utf-8").splitlines():
    match = re.match(r"^\d+\s+(.+)$", line.strip())
    if not match:
        continue
    name = match.group(1)
    if name == "Needleverge Pathway":
        name = "Turbulent Steppe"
    requested.append(name)
requested.append("A Good Day to Pie")

normalized = {" ".join(name.lower().split()): name for name in requested}
placeholders = ",".join("?" for _ in normalized)
with sqlite3.connect(knowledge_db) as connection:
    connection.row_factory = sqlite3.Row
    rows = connection.execute(
        f"""
        SELECT normalized_name, name, mana_cost, colors_json,
               color_identity_json, type_line, oracle_text, cmc, power,
               toughness, keywords_json, scryfall_id
        FROM card_oracle_cache
        WHERE normalized_name IN ({placeholders})
        """,
        sorted(normalized),
    ).fetchall()

by_name = {str(row["normalized_name"]): row for row in rows}
missing = sorted(set(normalized) - set(by_name))
if missing:
    raise SystemExit(f"Battle E2E Oracle fixture is incomplete: {missing}")

fixture = []
for index, key in enumerate(sorted(normalized), start=1):
    row = by_name[key]
    scryfall_id = str(row["scryfall_id"] or "").strip()
    if not scryfall_id:
        scryfall_id = str(uuid.UUID(hashlib.md5(f"scryfall:{key}".encode()).hexdigest()))
    fixture.append(
        {
            "scryfall_id": scryfall_id,
            "oracle_id": str(uuid.UUID(hashlib.md5(f"oracle:{key}".encode()).hexdigest())),
            "name": str(row["name"]),
            "mana_cost": row["mana_cost"],
            "type_line": row["type_line"],
            "oracle_text": row["oracle_text"],
            "colors": json.loads(row["colors_json"] or "[]"),
            "color_identity": json.loads(row["color_identity_json"] or "[]"),
            "cmc": row["cmc"] or 0,
            "power": row["power"],
            "toughness": row["toughness"],
            "keywords": json.loads(row["keywords_json"] or "[]"),
            "collector_number": str(index),
        }
    )
output.write_text(json.dumps(fixture, separators=(",", ":")), encoding="utf-8")
PY
}

start_disposable_postgres() {
  local run_dir="$1"
  local knowledge_db="$2"
  local deck_file="$3"
  local fixture_json="$run_dir/battle-card-fixture.json"

  POSTGRES_DATA_DIR="$run_dir/pgdata"
  # PostgreSQL socket paths are platform-limited; keep this independent from
  # the descriptive run directory and remove it with the harness cleanup.
  POSTGRES_SOCKET_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mlbpgsock.XXXXXX")"
  POSTGRES_PORT="$(select_free_loopback_port)"
  mkdir -p "$POSTGRES_SOCKET_DIR"

  initdb \
    -D "$POSTGRES_DATA_DIR" \
    -U postgres \
    --auth=trust \
    --no-locale \
    --encoding=UTF8 >"$run_dir/initdb.log" 2>&1
  if ! pg_ctl \
    -D "$POSTGRES_DATA_DIR" \
    -l "$run_dir/postgres.log" \
    -o "-F -p $POSTGRES_PORT -h 127.0.0.1 -k $POSTGRES_SOCKET_DIR" \
    start >/dev/null; then
    echo "FAIL: disposable PostgreSQL could not start:" >&2
    tail -80 "$run_dir/postgres.log" >&2 || true
    return 1
  fi
  POSTGRES_STARTED=1

  local ready=0
  for _attempt in $(seq 1 60); do
    if pg_isready -h 127.0.0.1 -p "$POSTGRES_PORT" -U postgres >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 0.1
  done
  if [[ "$ready" != "1" ]]; then
    echo "FAIL: disposable PostgreSQL did not become ready." >&2
    return 1
  fi
  assert_loopback_listener "$POSTGRES_PORT" "disposable PostgreSQL"
  POSTGRES_LISTENER_PIDS="$(capture_listener_pids "$POSTGRES_PORT" | tr '\n' ' ')"
  if [[ -z "$POSTGRES_LISTENER_PIDS" ]]; then
    echo "FAIL: could not capture the disposable PostgreSQL listener PID." >&2
    return 1
  fi

  export DB_HOST=127.0.0.1
  export DB_PORT="$POSTGRES_PORT"
  export DB_USER=postgres
  export DB_PASS=''
  export DB_NAME=manaloom_battle_e2e
  export PGHOST="$DB_HOST"
  export PGPORT="$DB_PORT"
  export PGUSER="$DB_USER"
  export PGPASSWORD="$DB_PASS"
  export PGDATABASE="$DB_NAME"

  createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
  e2e_psql -f "$SERVER_DIR/database_setup.sql" >"$run_dir/bootstrap.log" 2>&1
  (
    cd "$SERVER_DIR"
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    ENVIRONMENT=development \
      dart run bin/migrate.dart
  ) >"$run_dir/migrate.log" 2>&1

  build_battle_fixture_json "$knowledge_db" "$deck_file" "$fixture_json"
  e2e_psql -v fixture_json="$(<"$fixture_json")" \
    >"$run_dir/fixture.log" 2>&1 <<'SQL'
WITH fixture AS (
  SELECT *
  FROM jsonb_to_recordset(:'fixture_json'::jsonb) AS row(
    scryfall_id uuid,
    oracle_id uuid,
    name text,
    mana_cost text,
    type_line text,
    oracle_text text,
    colors jsonb,
    color_identity jsonb,
    cmc numeric,
    power text,
    toughness text,
    keywords jsonb,
    collector_number text
  )
)
INSERT INTO cards (
  scryfall_id, oracle_id, name, mana_cost, type_line, oracle_text,
  colors, color_identity, cmc, power, toughness, keywords,
  set_code, rarity, collector_number
)
SELECT
  scryfall_id,
  oracle_id,
  name,
  mana_cost,
  type_line,
  oracle_text,
  ARRAY(SELECT jsonb_array_elements_text(colors)),
  ARRAY(SELECT jsonb_array_elements_text(color_identity)),
  cmc,
  power,
  toughness,
  ARRAY(SELECT jsonb_array_elements_text(keywords)),
  'E2E',
  'special',
  collector_number
FROM fixture
ON CONFLICT (scryfall_id) DO NOTHING;

INSERT INTO card_legalities (card_id, format, status)
SELECT id, 'commander', 'legal'
FROM cards
WHERE set_code = 'E2E'
ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
SQL
}

assert_loopback_listener() {
  local port="$1"
  local label="$2"
  if ! command -v lsof >/dev/null 2>&1; then
    echo "BLOCKED: lsof is required to audit the isolated ${label} listener." >&2
    return 2
  fi

  local listeners
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -F n 2>/dev/null | sed -n 's/^n//p')"
  if [[ -z "$listeners" ]]; then
    echo "FAIL: no ${label} listener found on 127.0.0.1:${port}." >&2
    return 1
  fi
  if printf '%s\n' "$listeners" | grep -Ev "^127[.]0[.]0[.]1:${port}$" >/dev/null; then
    echo "FAIL: mutable ${label} listener escaped IPv4 loopback:" >&2
    printf '%s\n' "$listeners" >&2
    return 1
  fi
}

assert_listener_closed() {
  local port="$1"
  local label="$2"
  local _attempt
  for _attempt in $(seq 1 20); do
    if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  echo "FAIL: ${label} left an orphan listener on TCP port ${port}." >&2
  lsof -nP -iTCP:"$port" -sTCP:LISTEN >&2 || true
  return 1
}

capture_listener_pids() {
  local port="$1"
  lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | sort -u
}

collect_process_tree_pids() {
  local root_pid="$1"
  [[ "$root_pid" =~ ^[0-9]+$ ]] || return 0

  local current child
  local -a queue=("$root_pid")
  while (( ${#queue[@]} > 0 )); do
    current="${queue[0]}"
    queue=("${queue[@]:1}")
    printf '%s\n' "$current"
    while IFS= read -r child; do
      [[ "$child" =~ ^[0-9]+$ ]] || continue
      queue+=("$child")
    done < <(pgrep -P "$current" 2>/dev/null || true)
  done
}

pid_is_running() {
  local pid="$1" state
  kill -0 "$pid" >/dev/null 2>&1 || return 1
  state="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
  [[ -n "$state" && "$state" != Z* ]]
}

terminate_owned_processes() {
  local raw_pid pid normalized=""
  for raw_pid in "$@"; do
    for pid in $raw_pid; do
      [[ "$pid" =~ ^[0-9]+$ ]] || continue
      [[ "$pid" != "$$" && "$pid" != "$PPID" ]] || continue
      case " $normalized " in
        *" $pid "*) ;;
        *) normalized="${normalized:+$normalized }$pid" ;;
      esac
    done
  done

  [[ -n "$normalized" ]] || return 0
  for pid in $normalized; do
    kill -TERM "$pid" >/dev/null 2>&1 || true
  done

  local _attempt alive
  for _attempt in $(seq 1 20); do
    alive=0
    for pid in $normalized; do
      if pid_is_running "$pid"; then
        alive=1
      fi
    done
    [[ "$alive" -eq 0 ]] && break
    sleep 0.25
  done

  for pid in $normalized; do
    if pid_is_running "$pid"; then
      kill -KILL "$pid" >/dev/null 2>&1 || true
    fi
  done

  for _attempt in $(seq 1 20); do
    alive=0
    for pid in $normalized; do
      if pid_is_running "$pid"; then
        alive=1
      fi
    done
    [[ "$alive" -eq 0 ]] && return 0
    sleep 0.25
  done
  return 1
}

wait_for_json_contract() {
  local url="$1"
  local expected_status="$2"
  local expected_service="$3"
  local pid="$4"
  local log_path="$5"
  local body
  body="$(mktemp -t manaloom-battle-health.XXXXXX.json)"
  TEMP_FILES+=("$body")

  for _attempt in $(seq 1 90); do
    if curl -fsS --max-time 3 "$url" -o "$body" >/dev/null 2>&1 && \
      python3 - "$body" "$expected_status" "$expected_service" <<'PY'
import json
import sys
from pathlib import Path

try:
    payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except (OSError, ValueError):
    raise SystemExit(1)
if payload.get("status") != sys.argv[2]:
    raise SystemExit(1)
if sys.argv[3] and payload.get("service") != sys.argv[3]:
    raise SystemExit(1)
PY
    then
      return 0
    fi
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      echo "FAIL: isolated process exited before readiness; see $log_path" >&2
      return 1
    fi
    sleep 1
  done

  echo "FAIL: timeout waiting for $url; see $log_path" >&2
  return 1
}

assert_empty_precheck() {
  python3 - "$1" <<'PY'
import json
import sys

snapshot = json.loads(sys.argv[1])
if any(int(value) != 0 for value in snapshot.values()):
    print(f"BLOCKED: isolated Battle identity already exists: {snapshot}", file=sys.stderr)
    raise SystemExit(2)
PY
}

write_mutation_audit() {
  local audit_path="$1"
  local run_token="$2"
  local api_url="$3"
  local sidecar_url="$4"
  local runner_status="$5"
  local before="$6"
  local observed="$7"
  local deleted="$8"
  local after="$9"
  local listener_close_ok="${10}"
  local process_stop_ok="${11}"
  local listener_pids="${12}"

  python3 - \
    "$audit_path" "$run_token" "$api_url" "$sidecar_url" \
    "$runner_status" "$before" "$observed" "$deleted" "$after" \
    "$listener_close_ok" "$process_stop_ok" "$listener_pids" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    audit_path,
    run_token,
    api_url,
    sidecar_url,
    runner_status,
    before_raw,
    observed_raw,
    deleted_raw,
    after_raw,
    listener_close_ok,
    process_stop_ok,
    listener_pids,
) = sys.argv[1:]
before = json.loads(before_raw)
observed = json.loads(observed_raw)
deleted = json.loads(deleted_raw)
after = json.loads(after_raw)
expected_activity = (
    observed["users"] == 2
    and observed["decks"] == 2
    and observed["deck_cards"] > 0
    and observed["battle_simulations"] >= 1
)
cleanup_pass = (
    all(value == 0 for value in after.values())
    and deleted["users"] == observed["users"]
    and deleted["battle_simulations"] == observed["battle_simulations"]
)
runtime_cleanup_pass = listener_close_ok == "1" and process_stop_ok == "1"
passed = (
    int(runner_status) == 0
    and expected_activity
    and cleanup_pass
    and runtime_cleanup_pass
)
payload = {
    "schema_version": "manaloom_battle_product_mutation_audit_v2",
    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    "status": "pass" if passed else "fail",
    "run_token": run_token,
    "isolation": {
        "api_url": api_url,
        "native_sidecar_url": sidecar_url,
        "listener_policy": "ipv4_loopback_only",
        "identity_policy": "unique_owner_and_intruder_per_run_no_reuse",
        "database_policy": "fresh_local_cluster_destroyed_after_run",
    },
    "runner_exit_code": int(runner_status),
    "database": {
        "precheck": before,
        "before_cleanup": observed,
        "deleted": deleted,
        "after_cleanup": after,
        "cleanup_pass": cleanup_pass,
        "cluster_destroyed": True,
    },
    "runtime_cleanup": {
        "captured_listener_pids": [
            int(value) for value in listener_pids.split() if value.isdigit()
        ],
        "owned_processes_stopped": process_stop_ok == "1",
        "listener_closed": listener_close_ok == "1",
        "pass": runtime_cleanup_pass,
    },
    "telemetry": {
        "product_learning_writes_suppressed": True,
        "telemetry_deleted_with_disposable_cluster": True,
        "policy": (
            "The isolated API suppresses product-learning writes; exact QA rows "
            "are audited before the entire disposable PostgreSQL cluster is destroyed."
        ),
    },
    "expected_activity_pass": expected_activity,
}
path = Path(audit_path)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(json.dumps({"status": payload["status"], "audit": str(path)}, separators=(",", ":")))
raise SystemExit(0 if passed else 1)
PY
}

run_static_gate() {
  cd "$ROOT_DIR"

  # Mandatory and network-free: runtime/build identity must match canonical pins.
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_upstream_delta_audit.py \
    --local-only \
    --json-output "$PIN_AUDIT_OUT"
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_capability_alignment_audit.py \
    --output-prefix "$STATIC_AUDIT_DIR/external_engine_capability_alignment"
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py \
    --output-prefix "$STATIC_AUDIT_DIR/xmage_execution_contract"
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
    --output-prefix "$STATIC_AUDIT_DIR/xmage_strategy_consistency"
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
    --out-prefix "$STATIC_AUDIT_DIR/operational_surface_alignment"
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
    --out-prefix "$STATIC_AUDIT_DIR/deckbuilding_contract_surface"

  PYTHONWARNINGS=error::ResourceWarning python3 -m unittest \
    server.test.native_battle_worker_test \
    server.test.native_battle_sidecar_test \
    server.test.legacy_live_e2e_guard_test \
    server.test.manaloom_battle_product_e2e_audit_test \
    server.test.manaloom_ops_daemon_test \
    server.test.release_sbom_scope_test

  PYTHONWARNINGS=error::ResourceWarning \
    python3 services/forge-sidecar/test_sidecar.py
  PYTHONWARNINGS=error::ResourceWarning \
    python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_battle_async_runner.py
  PYTHONWARNINGS=error::ResourceWarning \
    python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_engine_capability_alignment_audit.py
  PYTHONWARNINGS=error::ResourceWarning \
    python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_adaptation_queue.py
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py \
    --json-output "$MANIFEST_OUT" \
    --fail-on-unclassified

  (
    cd services/xmage-sidecar
    if [[ -n "${MAVEN_REPO_LOCAL:-}" ]]; then
      mvn -q -Dmaven.repo.local="$MAVEN_REPO_LOCAL" test
    else
      mvn -q test
    fi
  )

  python3 server/bin/manaloom_battle_product_e2e_audit.py --out "$AUDIT_OUT"

  (
    cd server
    dart pub get --enforce-lockfile
    dart analyze \
      lib/ai/battle_engine_config.dart \
      lib/ai/battle_learning_evidence_support.dart \
      lib/ai/deck_battle_learning_evidence.dart \
      lib/ai/forge_battle_client.dart \
      lib/ai/native_battle_client.dart \
      lib/ai/xmage_battle_client.dart \
      lib/battle/battle_replay_payload_sanitizer.dart \
      lib/battle/battle_replay_read_service.dart \
      lib/battle/battle_simulation_persistence_service.dart \
      lib/deck_card_name_resolution_support.dart \
      routes/ai/simulate/index.dart \
      'routes/decks/[id]/analysis/index.dart' \
      'routes/decks/[id]/battle-replays/index.dart' \
      'routes/decks/[id]/battle-replays/[replayId]/index.dart' \
      routes/decks/index.dart
    dart test --reporter compact \
      test/native_battle_client_test.dart \
      test/xmage_battle_client_test.dart \
      test/forge_battle_client_test.dart \
      test/battle_engine_config_test.dart \
      test/battle_learning_evidence_support_test.dart \
      test/deck_battle_learning_evidence_test.dart \
      test/card_resolution_support_test.dart \
      test/ai_simulate_persistence_service_test.dart \
      test/battle_replay_read_service_test.dart \
      test/battle_replay_routes_security_test.dart \
      test/ops_sidecar_digest_release_contract_test.dart \
      test/experimental_deck_ai_authorization_source_test.dart
  )

  bash -n \
    scripts/manaloom_deploy_ops_image.sh \
    scripts/manaloom_deploy_backend_image.sh \
    scripts/manaloom_deploy_battle_sidecars.sh \
    services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh

  python3 - "$AUDIT_OUT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    audit = json.load(handle)
print(json.dumps({
    "status": "pass",
    "gate": "manaloom_battle_product_gate_v1",
    "contract": audit["contract"],
    "checks": audit["summary"]["checks"],
}, separators=(",", ":")))
PY
}

run_isolated_e2e() {
  require_live_mutation_approval "Battle product isolated mutating E2E"
  require_postgres_write_approval "Battle product isolated mutating E2E"

  if [[ -n "${TEST_API_BASE_URL:-}" || -n "${API_BASE_URL:-}" ]]; then
    echo "BLOCKED: external or reused API URLs are forbidden for isolated Battle E2E." >&2
    return 2
  fi

  local required_tool
  for required_tool in \
    createdb curl dart dart_frog git initdb lsof perl pg_ctl pg_isready pgrep \
    psql python3; do
    if ! command -v "$required_tool" >/dev/null 2>&1; then
      echo "BLOCKED: required tool is unavailable: $required_tool" >&2
      return 2
    fi
  done

  local knowledge_db="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
  if [[ ! -f "$knowledge_db" ]]; then
    echo "BLOCKED: reviewed native knowledge DB is missing: $knowledge_db" >&2
    return 2
  fi
  local deck_file="$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/import_queue/lorehold/lorehold_best_of_learned_no_premium_mox_20260602.txt"
  if [[ ! -f "$deck_file" ]]; then
    echo "BLOCKED: Battle E2E deck fixture is missing: $deck_file" >&2
    return 2
  fi

  local stamp nonce run_token audit_path
  local api_port native_port api_url sidecar_url jwt_secret
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  nonce="$(python3 -c 'import secrets; print(secrets.token_hex(6))')"
  run_token="${MANALOOM_BATTLE_E2E_RUN_TOKEN:-${stamp}_$$_${nonce}}"
  if [[ ! "$run_token" =~ ^[A-Za-z0-9_-]{12,96}$ ]]; then
    echo "BLOCKED: MANALOOM_BATTLE_E2E_RUN_TOKEN must match [A-Za-z0-9_-]{12,96}." >&2
    return 2
  fi
  RUN_DIR="${MANALOOM_BATTLE_E2E_RUN_DIR:-${TMPDIR:-/tmp}/manaloom_battle_product_e2e/$run_token}"
  audit_path="$RUN_DIR/mutation_audit.json"
  mkdir -p "$RUN_DIR"

  VALIDATION_EMAIL="battle.product.e2e.${run_token}@example.invalid"
  VALIDATION_USERNAME="battle_product_e2e_${run_token}"
  VALIDATION_INTRUDER_EMAIL="battle.product.e2e.intruder.${run_token}@example.invalid"
  VALIDATION_INTRUDER_USERNAME="battle_product_e2e_intruder_${run_token}"
  start_disposable_postgres "$RUN_DIR" "$knowledge_db" "$deck_file"
  api_port="$(select_free_loopback_port)"
  native_port="$(select_free_loopback_port)"
  while [[ "$native_port" == "$api_port" ]]; do
    native_port="$(select_free_loopback_port)"
  done
  api_url="http://127.0.0.1:${api_port}"
  sidecar_url="http://127.0.0.1:${native_port}"
  jwt_secret="local_battle_product_e2e_${run_token}_${nonce}"

  local collision_count precheck observed deleted after runner_status
  local listener_close_ok=1
  collision_count="$(identity_collision_count | tr -d '[:space:]')"
  if [[ "$collision_count" != "0" ]]; then
    echo "BLOCKED: Battle validation email or username already exists; use a new run token." >&2
    return 2
  fi
  precheck="$(database_snapshot | tr -d '\r\n')"
  assert_empty_precheck "$precheck"
  MUTATION_ARMED=1

  (
    cd "$ROOT_DIR"
    exec env \
      MANALOOM_NATIVE_BATTLE_HOST=127.0.0.1 \
      MANALOOM_NATIVE_BATTLE_PORT="$native_port" \
      MANALOOM_KNOWLEDGE_DB="$knowledge_db" \
      GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD)" \
      python3 server/bin/native_battle_sidecar.py
  ) >"$RUN_DIR/native-sidecar.log" 2>&1 &
  NATIVE_PID="$!"
  wait_for_json_contract \
    "$sidecar_url/health" "ok" "" "$NATIVE_PID" "$RUN_DIR/native-sidecar.log"
  assert_loopback_listener "$native_port" "native sidecar"
  NATIVE_LISTENER_PIDS="$(capture_listener_pids "$native_port" | tr '\n' ' ')"
  if [[ -z "$NATIVE_LISTENER_PIDS" ]]; then
    echo "FAIL: could not capture the owned native sidecar listener PID." >&2
    return 1
  fi

  (
    cd "$SERVER_DIR"
    dart_frog build
  ) >"$RUN_DIR/server-build.log" 2>&1
  perl -0pi -e \
    's/final address = InternetAddress[.]anyIPv6;/final address = InternetAddress.loopbackIPv4;/' \
    "$SERVER_DIR/build/bin/server.dart"
  if ! grep -Fq \
    'final address = InternetAddress.loopbackIPv4;' \
    "$SERVER_DIR/build/bin/server.dart"; then
    echo "FAIL: immutable Battle API build could not be restricted to IPv4 loopback." >&2
    return 1
  fi

  (
    cd "$SERVER_DIR"
    exec env \
      DB_HOST="$DB_HOST" \
      DB_PORT="$DB_PORT" \
      DB_USER="$DB_USER" \
      DB_PASS="$DB_PASS" \
      DB_NAME="$DB_NAME" \
      PORT="$api_port" \
      JWT_SECRET="$jwt_secret" \
      BATTLE_ENGINE=native \
      NATIVE_BATTLE_SIDECAR_URL="$sidecar_url" \
      MANALOOM_E2E_ISOLATED_RUNTIME=1 \
      MANALOOM_E2E_VALIDATION_RUN_TOKEN="$run_token" \
      dart run build/bin/server.dart
  ) >"$RUN_DIR/api.log" 2>&1 &
  API_PID="$!"
  wait_for_json_contract \
    "$api_url/health/ready" "ready" "mtgia-server" "$API_PID" "$RUN_DIR/api.log"
  assert_loopback_listener "$api_port" "mutable API"
  API_LISTENER_PIDS="$(capture_listener_pids "$api_port" | tr '\n' ' ')"
  if [[ -z "$API_LISTENER_PIDS" ]]; then
    echo "FAIL: could not capture the owned mutable API listener PID." >&2
    return 1
  fi

  set +e
  (
    cd "$SERVER_DIR"
    env \
      RUN_BATTLE_PRODUCT_E2E=1 \
      BATTLE_E2E_RUN_TOKEN="$run_token" \
      BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS=1 \
      TEST_API_BASE_URL="$api_url" \
      dart test --reporter compact -j 1 test/battle_product_e2e_test.dart
  ) 2>&1 | tee "$RUN_DIR/battle-product-e2e.log"
  runner_status="${PIPESTATUS[0]}"
  set -e

  observed="$(database_snapshot | tr -d '\r\n')"
  stop_isolated_processes
  if ! assert_listener_closed "$api_port" "mutable API"; then
    listener_close_ok=0
  fi
  if ! assert_listener_closed "$native_port" "native sidecar"; then
    listener_close_ok=0
  fi
  deleted="$(cleanup_battle_identity | tr -d '\r\n')"
  after="$(database_snapshot | tr -d '\r\n')"
  MUTATION_ARMED=0
  stop_disposable_postgres
  if ! assert_listener_closed "$POSTGRES_PORT" "disposable PostgreSQL"; then
    listener_close_ok=0
  fi
  rm -rf "$POSTGRES_DATA_DIR" "$POSTGRES_SOCKET_DIR"
  if [[ -e "$POSTGRES_DATA_DIR" || -e "$POSTGRES_SOCKET_DIR" ]]; then
    echo "FAIL: disposable PostgreSQL files remain after cleanup." >&2
    return 1
  fi

  write_mutation_audit \
    "$audit_path" "$run_token" "$api_url" "$sidecar_url" \
    "$runner_status" "$precheck" "$observed" "$deleted" "$after" \
    "$listener_close_ok" "$PROCESS_STOP_OK" \
    "$API_LISTENER_PIDS $NATIVE_LISTENER_PIDS $POSTGRES_LISTENER_PIDS"
  if [[ -n "${MANALOOM_BATTLE_E2E_AUDIT_OUT:-}" ]]; then
    mkdir -p "$(dirname -- "$MANALOOM_BATTLE_E2E_AUDIT_OUT")"
    cp "$audit_path" "$MANALOOM_BATTLE_E2E_AUDIT_OUT"
  fi
}

case "$MODE" in
  --static|static)
    run_static_gate
    ;;
  --isolated-e2e|isolated-e2e)
    run_isolated_e2e
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
