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

API_PID=""
NATIVE_PID=""
API_LISTENER_PIDS=""
NATIVE_LISTENER_PIDS=""
PROCESS_STOP_OK=1
MUTATION_ARMED=0
VALIDATION_EMAIL=""
VALIDATION_USERNAME=""

usage() {
  cat <<'EOF'
Usage: scripts/manaloom_battle_product_gate.sh [--static|--isolated-e2e]

  --static        Run deterministic battle product contracts (default).
  --isolated-e2e  Start a native sidecar and mutable API on 127.0.0.1,
                  run the Battle product E2E with a unique identity, and
                  remove only its temporary identity and battle replays.
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

database_snapshot() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -qAt -v ON_ERROR_STOP=1 \
      -v validation_email="$VALIDATION_EMAIL" \
      -v validation_username="$VALIDATION_USERNAME" <<'SQL'
WITH target_users AS MATERIALIZED (
  SELECT id
  FROM users
  WHERE LOWER(email) = LOWER(:'validation_email')
    AND LOWER(username) = LOWER(:'validation_username')
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
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -qAt -v ON_ERROR_STOP=1 \
      -v validation_email="$VALIDATION_EMAIL" \
      -v validation_username="$VALIDATION_USERNAME" <<'SQL'
SELECT COUNT(*)
FROM users
WHERE LOWER(email) = LOWER(:'validation_email')
   OR LOWER(username) = LOWER(:'validation_username');
SQL
}

cleanup_battle_identity() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -qAt -v ON_ERROR_STOP=1 \
      -v validation_email="$VALIDATION_EMAIL" \
      -v validation_username="$VALIDATION_USERNAME" <<'SQL'
BEGIN;
CREATE TEMP TABLE manaloom_target_users ON COMMIT DROP AS
SELECT id
FROM users
WHERE LOWER(email) = LOWER(:'validation_email')
  AND LOWER(username) = LOWER(:'validation_username');

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
  if [[ "$MUTATION_ARMED" -eq 1 && -n "$VALIDATION_EMAIL" ]]; then
    cleanup_battle_identity >/dev/null 2>&1
  fi
  rm -f "${TEMP_FILES[@]}"
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
    observed["users"] == 1
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
    "schema_version": "manaloom_battle_product_mutation_audit_v1",
    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    "status": "pass" if passed else "fail",
    "run_token": run_token,
    "isolation": {
        "api_url": api_url,
        "native_sidecar_url": sidecar_url,
        "listener_policy": "ipv4_loopback_only",
        "identity_policy": "unique_per_run_no_reuse",
    },
    "runner_exit_code": int(runner_status),
    "database": {
        "precheck": before,
        "before_cleanup": observed,
        "deleted": deleted,
        "after_cleanup": after,
        "cleanup_pass": cleanup_pass,
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
        "telemetry_deleted": False,
        "policy": (
            "Cleanup is limited to the exact temporary battle_simulations rows "
            "and unique user identity graph; persistent AI telemetry is preserved."
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

  PYTHONWARNINGS=error::ResourceWarning python3 -m unittest \
    server.test.native_battle_worker_test \
    server.test.native_battle_sidecar_test \
    server.test.legacy_live_e2e_guard_test \
    server.test.manaloom_battle_product_e2e_audit_test \
    server.test.manaloom_ops_daemon_test

  PYTHONWARNINGS=error::ResourceWarning \
    python3 services/forge-sidecar/test_sidecar.py
  PYTHONWARNINGS=error::ResourceWarning \
    python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_battle_async_runner.py
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
    dart analyze \
      lib/ai/battle_engine_config.dart \
      lib/ai/battle_learning_evidence_support.dart \
      lib/ai/deck_battle_learning_evidence.dart \
      lib/ai/forge_battle_client.dart \
      lib/ai/native_battle_client.dart \
      lib/ai/xmage_battle_client.dart \
      lib/battle/battle_replay_read_service.dart \
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
      test/battle_replay_read_service_test.dart \
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
  require_postgres_write_approval "Battle product isolated mutating E2E"

  if [[ -n "${TEST_API_BASE_URL:-}" || -n "${API_BASE_URL:-}" ]]; then
    echo "BLOCKED: external or reused API URLs are forbidden for isolated Battle E2E." >&2
    return 2
  fi

  local required_tool
  for required_tool in curl dart dart_frog lsof pgrep psql python3 script; do
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

  local stamp nonce run_token run_dir audit_path
  local api_port native_port vm_port api_url sidecar_url jwt_secret
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  nonce="$(python3 -c 'import secrets; print(secrets.token_hex(6))')"
  run_token="${MANALOOM_BATTLE_E2E_RUN_TOKEN:-${stamp}_$$_${nonce}}"
  if [[ ! "$run_token" =~ ^[A-Za-z0-9_-]{12,96}$ ]]; then
    echo "BLOCKED: MANALOOM_BATTLE_E2E_RUN_TOKEN must match [A-Za-z0-9_-]{12,96}." >&2
    return 2
  fi
  run_dir="${MANALOOM_BATTLE_E2E_RUN_DIR:-/tmp/manaloom_battle_product_e2e/$run_token}"
  audit_path="$run_dir/mutation_audit.json"
  mkdir -p "$run_dir"

  VALIDATION_EMAIL="battle.product.e2e.${run_token}@example.invalid"
  VALIDATION_USERNAME="battle_product_e2e_${run_token}"
  api_port="$(select_free_loopback_port)"
  native_port="$(select_free_loopback_port)"
  while [[ "$native_port" == "$api_port" ]]; do
    native_port="$(select_free_loopback_port)"
  done
  vm_port="$(select_free_loopback_port)"
  while [[ "$vm_port" == "$api_port" || "$vm_port" == "$native_port" ]]; do
    vm_port="$(select_free_loopback_port)"
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
      python3 server/bin/native_battle_sidecar.py
  ) >"$run_dir/native-sidecar.log" 2>&1 &
  NATIVE_PID="$!"
  wait_for_json_contract \
    "$sidecar_url/health" "ok" "" "$NATIVE_PID" "$run_dir/native-sidecar.log"
  assert_loopback_listener "$native_port" "native sidecar"
  NATIVE_LISTENER_PIDS="$(capture_listener_pids "$native_port" | tr '\n' ' ')"
  if [[ -z "$NATIVE_LISTENER_PIDS" ]]; then
    echo "FAIL: could not capture the owned native sidecar listener PID." >&2
    return 1
  fi

  (
    cd "$SERVER_DIR"
    exec "$ROOT_DIR/server/bin/with_new_server_pg.sh" env \
      PORT="$api_port" \
      JWT_SECRET="$jwt_secret" \
      BATTLE_ENGINE=native \
      NATIVE_BATTLE_SIDECAR_URL="$sidecar_url" \
      script -q /dev/null dart_frog dev \
        --hostname 127.0.0.1 \
        --port "$api_port" \
        --dart-vm-service-port "$vm_port"
  ) >"$run_dir/api.log" 2>&1 &
  API_PID="$!"
  wait_for_json_contract \
    "$api_url/health/ready" "ready" "mtgia-server" "$API_PID" "$run_dir/api.log"
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
  ) 2>&1 | tee "$run_dir/battle-product-e2e.log"
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

  write_mutation_audit \
    "$audit_path" "$run_token" "$api_url" "$sidecar_url" \
    "$runner_status" "$precheck" "$observed" "$deleted" "$after" \
    "$listener_close_ok" "$PROCESS_STOP_OK" \
    "$API_LISTENER_PIDS $NATIVE_LISTENER_PIDS"
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
