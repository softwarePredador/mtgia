#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"

PORT="${PORT:-8080}"
REQUESTED_API_BASE_URL="${API_BASE_URL:-}"
API_BASE_URL=""
SERVER_START_TIMEOUT="${SERVER_START_TIMEOUT:-60}"
SERVER_BUILD_LOG=""
VALIDATION_CORPUS_PATH="${VALIDATION_CORPUS_PATH:-test/fixtures/optimization_resolution_corpus.json}"
VALIDATION_SELECTION_MODE="${VALIDATION_SELECTION_MODE:-corpus}"
REQUESTED_VALIDATION_LIMIT="${VALIDATION_LIMIT:-}"
VALIDATION_CORPUS_OFFSET="${VALIDATION_CORPUS_OFFSET:-0}"
RUN_STAMP="$(date -u +%Y%m%d%H%M%S)"
RUN_NONCE="$(python3 -c 'import secrets; print(secrets.token_hex(6))')"
RUN_TOKEN="${MANALOOM_RESOLUTION_RUN_TOKEN:-${RUN_STAMP}_$$_${RUN_NONCE}}"
VALIDATION_RUN_DIR="${VALIDATION_RUN_DIR:-/tmp/manaloom_resolution_corpus/${RUN_TOKEN}}"
VALIDATION_ARTIFACT_DIR="${VALIDATION_ARTIFACT_DIR:-${VALIDATION_RUN_DIR}/decks}"
VALIDATION_SUMMARY_JSON_PATH="${VALIDATION_SUMMARY_JSON_PATH:-${VALIDATION_RUN_DIR}/summary.json}"
VALIDATION_SUMMARY_MD_PATH="${VALIDATION_SUMMARY_MD_PATH:-${VALIDATION_RUN_DIR}/summary.md}"
MUTATION_AUDIT_PATH="${MUTATION_AUDIT_PATH:-${VALIDATION_RUN_DIR}/mutation_audit.json}"
BACKEND_TEST_JWT_SECRET="${JWT_SECRET:-local_resolution_gate_jwt_secret_not_for_production_${RUN_TOKEN}}"
VALIDATION_USER_EMAIL="${VALIDATION_USER_EMAIL:-optimization.validation.bot.${RUN_TOKEN}@example.invalid}"
VALIDATION_USERNAME="${VALIDATION_USERNAME:-optimization_validation_bot_${RUN_TOKEN}}"
VALIDATION_USER_PASSWORD="${VALIDATION_USER_PASSWORD:-OptimizationPass123!${RUN_NONCE}}"

SERVER_PID=""
SERVER_LISTENER_PIDS=""
SERVER_STOP_OK=1
STARTED_BY_SCRIPT=0
MUTATION_ARMED=0
DB_RUN_STARTED_AT=""
TELEMETRY_CLEANUP_JSON='{}'

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

api_ready() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  local headers_file body_file
  headers_file="$(mktemp)"
  body_file="$(mktemp)"

  cleanup_probe_files() {
    rm -f "$headers_file" "$body_file"
  }

  local probe_url="${API_BASE_URL%/}/health/ready"
  curl -sS -m 5 -D "$headers_file" -o "$body_file" "$probe_url" >/dev/null 2>&1 || true

  local content_type status
  content_type="$(awk -F': ' 'tolower($1)=="content-type"{print tolower($2)}' "$headers_file" | tr -d '\r' | tail -n1)"
  status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END{print code}' "$headers_file")"

  local valid=0
  if [[ "$status" == "200" && "$content_type" == application/json* ]] && \
    python3 - "$body_file" <<'PY'
import json
import sys
from pathlib import Path

try:
    payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except (OSError, ValueError):
    raise SystemExit(1)

if (
    payload.get("status") != "ready"
    or payload.get("service") != "mtgia-server"
    or payload.get("e2e_isolated_runtime") is not True
):
    raise SystemExit(1)
PY
  then
    valid=1
  fi

  cleanup_probe_files
  [[ "$valid" -eq 1 ]]
}

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
    return
  fi

  if command -v nc >/dev/null 2>&1; then
    nc -z localhost "$port" >/dev/null 2>&1
    return
  fi

  return 1
}

select_free_local_port() {
  local from_port="$1"
  local max_tries="${2:-20}"
  local p

  for ((offset = 0; offset <= max_tries; offset++)); do
    p=$((from_port + offset))
    if ! port_in_use "$p"; then
      echo "$p"
      return 0
    fi
  done

  return 1
}

assert_loopback_listener() {
  local port="$1"
  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi

  local listeners
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -F n 2>/dev/null | sed -n 's/^n//p')"
  if [[ -z "$listeners" ]]; then
    echo "❌ Nenhum listener encontrado para a API isolada na porta ${port}." >&2
    return 1
  fi
  if printf '%s\n' "$listeners" | grep -Ev "^127[.]0[.]0[.]1:${port}$" >/dev/null; then
    echo "❌ A API mutável abriu listener fora do loopback IPv4:" >&2
    printf '   %s\n' "$listeners" >&2
    return 1
  fi
}

assert_listener_closed() {
  local port="$1"
  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi

  local _attempt
  for _attempt in $(seq 1 20); do
    if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  echo "❌ O launcher deixou listener órfão na porta ${port}." >&2
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

stop_local_server() {
  local process_tree=""
  if [[ "$STARTED_BY_SCRIPT" -eq 1 ]]; then
    print_header "Encerrando API local"
    if [[ -n "$SERVER_PID" ]]; then
      process_tree="$(collect_process_tree_pids "$SERVER_PID")"
    fi
    if ! terminate_owned_processes \
      "$process_tree" \
      "$SERVER_PID" \
      "$SERVER_LISTENER_PIDS"; then
      SERVER_STOP_OK=0
    fi
    if [[ -n "$SERVER_PID" ]]; then
      wait "$SERVER_PID" 2>/dev/null || true
    fi
  fi
  STARTED_BY_SCRIPT=0
  SERVER_PID=""
  return 0
}

cleanup_validation_identity() {
  if [[ "$MUTATION_ARMED" -ne 1 ]]; then
    return 0
  fi

  local cleanup_result
  if cleanup_result="$("$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -q -t -A -v ON_ERROR_STOP=1 \
      -v validation_email="$VALIDATION_USER_EMAIL" \
      -v validation_username="$VALIDATION_USERNAME" \
      -v validation_run_token="$RUN_TOKEN" \
      -v run_started_at="$DB_RUN_STARTED_AT" <<'SQL'
BEGIN;

CREATE TEMP TABLE manaloom_validation_context ON COMMIT DROP AS
SELECT
  :'run_started_at'::timestamptz AS run_started_at,
  :'validation_run_token'::text AS run_token;

CREATE TEMP TABLE manaloom_validation_user_ids ON COMMIT DROP AS
SELECT id
FROM users
WHERE LOWER(email) = LOWER(:'validation_email')
  AND LOWER(username) = LOWER(:'validation_username');

CREATE TEMP TABLE manaloom_validation_deck_ids ON COMMIT DROP AS
SELECT id
FROM decks
WHERE user_id IN (SELECT id FROM manaloom_validation_user_ids);

CREATE TEMP TABLE manaloom_cleanup_counts (
  table_name TEXT PRIMARY KEY,
  rows_deleted INTEGER NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE manaloom_validation_usage_adjustments ON COMMIT DROP AS
WITH event_cards AS (
  SELECT DISTINCT
    event.id AS event_id,
    LOWER(REGEXP_REPLACE(
      TRIM(REPLACE(REPLACE(COALESCE(event.commander_name, ''), CHR(8216), CHR(39)), CHR(8217), CHR(39))),
      '\s+', ' ', 'g'
    )) AS commander_name_normalized,
    LOWER(REGEXP_REPLACE(
      TRIM(REPLACE(REPLACE(card->>'name', CHR(8216), CHR(39)), CHR(8217), CHR(39))),
      '\s+', ' ', 'g'
    )) AS card_name_normalized
  FROM deck_learning_events event
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE
      WHEN jsonb_typeof(event.event_data->'cards') = 'array'
        THEN event.event_data->'cards'
      ELSE '[]'::jsonb
    END
  ) card
  WHERE event.created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND event.deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    AND COALESCE((card->>'is_commander')::boolean, FALSE) = FALSE
    AND NULLIF(TRIM(card->>'name'), '') IS NOT NULL
)
SELECT
  commander_name_normalized,
  card_name_normalized,
  COUNT(*)::int AS usage_count
FROM event_cards
WHERE commander_name_normalized <> ''
  AND card_name_normalized <> ''
  AND commander_name_normalized <> card_name_normalized
GROUP BY commander_name_normalized, card_name_normalized;

CREATE TEMP TABLE manaloom_nonvalidation_usage_last ON COMMIT DROP AS
WITH event_cards AS (
  SELECT DISTINCT
    event.id AS event_id,
    event.created_at,
    LOWER(REGEXP_REPLACE(
      TRIM(REPLACE(REPLACE(COALESCE(event.commander_name, ''), CHR(8216), CHR(39)), CHR(8217), CHR(39))),
      '\s+', ' ', 'g'
    )) AS commander_name_normalized,
    LOWER(REGEXP_REPLACE(
      TRIM(REPLACE(REPLACE(card->>'name', CHR(8216), CHR(39)), CHR(8217), CHR(39))),
      '\s+', ' ', 'g'
    )) AS card_name_normalized
  FROM deck_learning_events event
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE
      WHEN jsonb_typeof(event.event_data->'cards') = 'array'
        THEN event.event_data->'cards'
      ELSE '[]'::jsonb
    END
  ) card
  WHERE event.source = 'user_created'
    AND event.deck_id NOT IN (SELECT id FROM manaloom_validation_deck_ids)
    AND COALESCE((card->>'is_commander')::boolean, FALSE) = FALSE
    AND NULLIF(TRIM(card->>'name'), '') IS NOT NULL
)
SELECT
  commander_name_normalized,
  card_name_normalized,
  MAX(created_at) AS last_used_at
FROM event_cards
WHERE commander_name_normalized <> ''
  AND card_name_normalized <> ''
  AND commander_name_normalized <> card_name_normalized
GROUP BY commander_name_normalized, card_name_normalized;

DO $usage_precheck$
DECLARE
  unsafe_rows INTEGER;
BEGIN
  SELECT COUNT(*) INTO unsafe_rows
  FROM manaloom_validation_usage_adjustments adjustment
  LEFT JOIN commander_card_usage usage
    ON usage.commander_name_normalized = adjustment.commander_name_normalized
   AND usage.card_name_normalized = adjustment.card_name_normalized
  WHERE usage.usage_count IS NULL
     OR usage.usage_count < adjustment.usage_count;
  IF unsafe_rows <> 0 THEN
    RAISE EXCEPTION 'validation commander usage cleanup is unsafe: % row(s)', unsafe_rows;
  END IF;
END
$usage_precheck$;

WITH updated AS (
  UPDATE commander_card_usage usage
  SET
    usage_count = usage.usage_count - adjustment.usage_count,
    last_used_at = COALESCE(
      real_usage.last_used_at,
      LEAST(
        usage.last_used_at,
        (SELECT run_started_at FROM manaloom_validation_context) - INTERVAL '1 microsecond'
      )
    )
  FROM manaloom_validation_usage_adjustments adjustment
  LEFT JOIN manaloom_nonvalidation_usage_last real_usage
    ON real_usage.commander_name_normalized = adjustment.commander_name_normalized
   AND real_usage.card_name_normalized = adjustment.card_name_normalized
  WHERE usage.commander_name_normalized = adjustment.commander_name_normalized
    AND usage.card_name_normalized = adjustment.card_name_normalized
    AND usage.usage_count > adjustment.usage_count
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'commander_card_usage_updated', COUNT(*)::int FROM updated;

WITH deleted AS (
  DELETE FROM commander_card_usage usage
  USING manaloom_validation_usage_adjustments adjustment
  WHERE usage.commander_name_normalized = adjustment.commander_name_normalized
    AND usage.card_name_normalized = adjustment.card_name_normalized
    AND usage.usage_count = adjustment.usage_count
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'commander_card_usage_deleted', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM ai_logs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'ai_logs', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM ai_optimize_cache
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'ai_optimize_cache', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM ai_optimize_fallback_telemetry
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'ai_optimize_fallback_telemetry', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM ml_prompt_feedback
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'ml_prompt_feedback', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM optimization_analysis_logs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      decisions_reasoning->>'validation_run_token' = (
        SELECT run_token FROM manaloom_validation_context
      )
      OR decisions_reasoning->>'deck_id' IN (
        SELECT id::text FROM manaloom_validation_deck_ids
      )
      OR decisions_reasoning->>'user_id' IN (
        SELECT id::text FROM manaloom_validation_user_ids
      )
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'optimization_analysis_logs', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM rate_limit_events
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND identifier IN (
      SELECT id::text FROM manaloom_validation_user_ids
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'rate_limit_events', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM deck_learning_events
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND deck_id IN (
      SELECT id FROM manaloom_validation_deck_ids
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'deck_learning_events', COUNT(*)::int FROM deleted;

WITH deleted AS (
  DELETE FROM ai_optimize_jobs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND deck_id IN (
      SELECT id FROM manaloom_validation_deck_ids
    )
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'ai_optimize_jobs', COUNT(*)::int FROM deleted;

DO $telemetry_postcheck$
DECLARE
  remaining INTEGER;
BEGIN
  SELECT COUNT(*) INTO remaining
  FROM ai_logs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    );
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned ai_logs remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM ai_optimize_cache
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    );
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned ai_optimize_cache rows remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM ai_optimize_fallback_telemetry
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    );
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned fallback rows remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM ml_prompt_feedback
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      user_id IN (SELECT id FROM manaloom_validation_user_ids)
      OR deck_id IN (SELECT id FROM manaloom_validation_deck_ids)
    );
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned feedback rows remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM optimization_analysis_logs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND (
      decisions_reasoning->>'validation_run_token' = (
        SELECT run_token FROM manaloom_validation_context
      )
      OR decisions_reasoning->>'deck_id' IN (
        SELECT id::text FROM manaloom_validation_deck_ids
      )
      OR decisions_reasoning->>'user_id' IN (
        SELECT id::text FROM manaloom_validation_user_ids
      )
    );
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned analysis rows remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM rate_limit_events
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND identifier IN (SELECT id::text FROM manaloom_validation_user_ids);
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned rate-limit rows remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM deck_learning_events
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND deck_id IN (SELECT id FROM manaloom_validation_deck_ids);
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned learning events remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM ai_optimize_jobs
  WHERE created_at >= (
      SELECT run_started_at FROM manaloom_validation_context
    )
    AND deck_id IN (SELECT id FROM manaloom_validation_deck_ids);
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation-owned optimize jobs remain: %', remaining;
  END IF;

END
$telemetry_postcheck$;

WITH deleted AS (
  DELETE FROM users
  WHERE LOWER(email) = LOWER(:'validation_email')
    AND LOWER(username) = LOWER(:'validation_username')
  RETURNING 1
)
INSERT INTO manaloom_cleanup_counts
SELECT 'users', COUNT(*)::int FROM deleted;

DO $identity_postcheck$
DECLARE
  remaining INTEGER;
BEGIN
  SELECT COUNT(*) INTO remaining
  FROM users
  WHERE id IN (SELECT id FROM manaloom_validation_user_ids);
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation users remain: %', remaining;
  END IF;

  SELECT COUNT(*) INTO remaining
  FROM decks
  WHERE id IN (SELECT id FROM manaloom_validation_deck_ids);
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'validation decks remain: %', remaining;
  END IF;
END
$identity_postcheck$;

SELECT jsonb_build_object(
  'scope', 'validation_identity_and_run_token',
  'postcheck_passed', true,
  'run_token', :'validation_run_token',
  'rows_deleted', jsonb_object_agg(table_name, rows_deleted ORDER BY table_name)
)::text
FROM manaloom_cleanup_counts;

COMMIT;
SQL
  )"; then
    TELEMETRY_CLEANUP_JSON="$(printf '%s\n' "$cleanup_result" | tail -n 1)"
    MUTATION_ARMED=0
    return 0
  fi

  return 1
}

cleanup() {
  set +e
  stop_local_server
  cleanup_validation_identity
}

trap cleanup EXIT INT TERM

resolve_server_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$SERVER_DIR" "$path"
  fi
}

validation_identity_count() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -q -t -A -v ON_ERROR_STOP=1 \
      -v validation_email="$VALIDATION_USER_EMAIL" \
      -v validation_username="$VALIDATION_USERNAME" <<'SQL'
SELECT COUNT(*)
FROM users
WHERE LOWER(email) = LOWER(:'validation_email')
   OR LOWER(username) = LOWER(:'validation_username');
SQL
}

generated_deck_count() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -q -t -A -v ON_ERROR_STOP=1 \
      -v validation_run_token="$RUN_TOKEN" <<'SQL'
SELECT COUNT(*)
FROM decks
WHERE (
  name LIKE 'Optimization Validation - %'
  OR name LIKE 'Resolution Validation - %'
  OR name LIKE 'Rebuild Draft - %'
  OR name LIKE 'Rebuild Preview - %'
)
AND POSITION(:'validation_run_token' IN name) > 0;
SQL
}

database_clock() {
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -q -t -A -v ON_ERROR_STOP=1 \
      -c "SELECT clock_timestamp()::text;"
}

persistent_telemetry_snapshot() {
  local started_at="$1"
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    psql -X -q -t -A -v ON_ERROR_STOP=1 \
      -v run_started_at="$started_at" <<'SQL'
WITH params AS (
  SELECT :'run_started_at'::timestamptz AS run_started_at
)
SELECT jsonb_build_object(
  'captured_at', clock_timestamp(),
  'window_started_at', (SELECT run_started_at FROM params),
  'tables', jsonb_build_object(
    'ai_optimize_cache', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM ai_optimize_cache),
      'created_since_start', (SELECT COUNT(*) FROM ai_optimize_cache, params WHERE created_at >= params.run_started_at)
    ),
    'ai_optimize_fallback_telemetry', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM ai_optimize_fallback_telemetry),
      'created_since_start', (SELECT COUNT(*) FROM ai_optimize_fallback_telemetry, params WHERE created_at >= params.run_started_at)
    ),
    'ml_prompt_feedback', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM ml_prompt_feedback),
      'created_since_start', (SELECT COUNT(*) FROM ml_prompt_feedback, params WHERE created_at >= params.run_started_at)
    ),
    'optimization_analysis_logs', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM optimization_analysis_logs),
      'created_since_start', (SELECT COUNT(*) FROM optimization_analysis_logs, params WHERE created_at >= params.run_started_at)
    ),
    'ai_logs', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM ai_logs),
      'created_since_start', (SELECT COUNT(*) FROM ai_logs, params WHERE created_at >= params.run_started_at)
    ),
    'rate_limit_events', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM rate_limit_events),
      'created_since_start', (SELECT COUNT(*) FROM rate_limit_events, params WHERE created_at >= params.run_started_at)
    ),
    'deck_learning_events', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM deck_learning_events),
      'created_since_start', (SELECT COUNT(*) FROM deck_learning_events, params WHERE created_at >= params.run_started_at)
    ),
    'ai_optimize_jobs', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM ai_optimize_jobs),
      'created_since_start', (SELECT COUNT(*) FROM ai_optimize_jobs, params WHERE created_at >= params.run_started_at)
    ),
    'commander_card_usage', jsonb_build_object(
      'total', (SELECT COALESCE(SUM(usage_count), 0) FROM commander_card_usage),
      'created_since_start', 0,
      'measurement', 'sum_usage_count'
    )
  )
)::text;
SQL
}

write_mutation_audit() {
  local before_json="$1"
  local after_json="$2"
  local runner_status="$3"
  local users_remaining="$4"
  local deck_baseline="$5"
  local deck_after="$6"
  local cleanup_ok="$7"
  local listener_close_ok="$8"
  local process_stop_ok="$9"
  local listener_pids="${10}"
  local observed_json="${11}"
  local telemetry_cleanup_json="${12}"

  python3 - \
    "$MUTATION_AUDIT_PATH" \
    "$RUN_TOKEN" \
    "$API_BASE_URL" \
    "$runner_status" \
    "$users_remaining" \
    "$deck_baseline" \
    "$deck_after" \
    "$cleanup_ok" \
    "$listener_close_ok" \
    "$process_stop_ok" \
    "$listener_pids" \
    "$observed_json" \
    "$telemetry_cleanup_json" \
    "$before_json" \
    "$after_json" <<'PY'
import json
import sys
from pathlib import Path

(
    output_path,
    run_token,
    api_base_url,
    runner_status,
    users_remaining,
    deck_baseline,
    deck_after,
    cleanup_ok,
    listener_close_ok,
    process_stop_ok,
    listener_pids,
    observed_raw,
    telemetry_cleanup_raw,
    before_raw,
    after_raw,
) = sys.argv[1:]

before = json.loads(before_raw)
observed = json.loads(observed_raw)
after = json.loads(after_raw)
telemetry_cleanup = json.loads(telemetry_cleanup_raw or "{}")
table_names = sorted(
    set(before["tables"]) | set(observed["tables"]) | set(after["tables"])
)
telemetry = {}
for table_name in table_names:
    before_row = before["tables"].get(table_name, {})
    observed_row = observed["tables"].get(table_name, {})
    after_row = after["tables"].get(table_name, {})
    before_total = int(before_row.get("total") or 0)
    observed_total = int(observed_row.get("total") or 0)
    after_total = int(after_row.get("total") or 0)
    telemetry[table_name] = {
        "before_total": before_total,
        "observed_before_cleanup_total": observed_total,
        "after_total": after_total,
        "delta_total": after_total - before_total,
        "gross_delta_before_cleanup": observed_total - before_total,
        "rows_created_in_window_before_cleanup": int(
            observed_row.get("created_since_start") or 0
        ),
        "rows_created_in_window": int(
            after_row.get("created_since_start") or 0
        ),
    }

payload = {
    "schema_version": 2,
    "run_token": run_token,
    "api_base_url": api_base_url,
    "db_started_at": before.get("window_started_at"),
    "db_finished_at": after.get("captured_at"),
    "runner_exit_code": int(runner_status),
    "cleanup": {
        "users_or_usernames_remaining": int(users_remaining),
        "generated_decks_before": int(deck_baseline),
        "generated_decks_after": int(deck_after),
        "pass": cleanup_ok == "1",
        "telemetry": telemetry_cleanup,
    },
    "runtime_cleanup": {
        "captured_listener_pids": [
            int(value) for value in listener_pids.split() if value.isdigit()
        ],
        "owned_processes_stopped": process_stop_ok == "1",
        "listener_closed": listener_close_ok == "1",
        "pass": process_stop_ok == "1" and listener_close_ok == "1",
    },
    "persistent_telemetry": {
        "measurement_scope": (
            "row-count deltas before and after exact validation-owned cleanup, "
            "plus rows whose created_at is at or after the database run-start "
            "timestamp"
        ),
        "limitation": (
            "shared-database counts are not attributable to this run when "
            "other writers are active; cleanup is therefore restricted to "
            "the exact validation user/decks and validation_run_token, within "
            "the run window"
        ),
        "tables": telemetry,
    },
    "learning_write_guard": {
        "policy": "isolated runtime must not write product learning",
        "pass": (
            telemetry.get("commander_card_usage", {}).get(
                "gross_delta_before_cleanup", 0
            ) == 0
            and telemetry.get("deck_learning_events", {}).get(
                "gross_delta_before_cleanup", 0
            ) == 0
            and telemetry.get("ml_prompt_feedback", {}).get(
                "gross_delta_before_cleanup", 0
            ) == 0
        ),
        "commander_card_usage_delta": telemetry.get(
            "commander_card_usage", {}
        ).get("gross_delta_before_cleanup", 0),
        "deck_learning_events_delta": telemetry.get(
            "deck_learning_events", {}
        ).get("gross_delta_before_cleanup", 0),
        "ml_prompt_feedback_delta": telemetry.get(
            "ml_prompt_feedback", {}
        ).get("gross_delta_before_cleanup", 0),
    },
    "e2e_isolated_runtime": True,
    "telemetry_deleted": cleanup_ok == "1",
}

path = Path(output_path)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

resolve_corpus_count() {
  python3 - "$SERVER_DIR/$VALIDATION_CORPUS_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))

if isinstance(obj, list):
    decks = obj
elif isinstance(obj, dict):
    decks = obj.get("decks") or obj.get("entries") or []
else:
    decks = []

print(len(decks))
PY
}

print_usage() {
  cat <<EOF
Uso:
  ./scripts/quality_gate_resolution_corpus.sh

Variaveis uteis:
  PORT                        primeira porta local candidata (default: 8080)
  VALIDATION_CORPUS_PATH      corpus a usar (default: test/fixtures/optimization_resolution_corpus.json)
  VALIDATION_LIMIT            quantidade a executar (default: corpus inteiro; intervalo 1..tamanho do corpus)
  VALIDATION_CORPUS_OFFSET    indice zero-based da primeira entrada (default: 0)
  VALIDATION_ARTIFACT_DIR     pasta de artefatos (default isolado em /tmp)
  VALIDATION_SUMMARY_JSON_PATH resumo JSON final
  VALIDATION_SUMMARY_MD_PATH   resumo Markdown final
  VALIDATION_PREFLIGHT_ONLY    use 1/true/yes para validar o corpus sem subir API nem criar dados

Este gate:
  1. sobe uma API local propria, vinculada somente a 127.0.0.1, em porta livre
  2. conta automaticamente o corpus estavel
  3. roda o runner oficial de resolucao com VALIDATION_LIMIT do corpus
  4. remove identidade, decks e telemetria pertencentes exatamente a esta validacao
  5. falha se houver unresolved, failed, total inconsistente ou residuo temporario
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "$SERVER_DIR/$VALIDATION_CORPUS_PATH" ]]; then
  echo "❌ Corpus não encontrado: $SERVER_DIR/$VALIDATION_CORPUS_PATH"
  exit 1
fi

CORPUS_COUNT="$(resolve_corpus_count)"
if [[ -z "$CORPUS_COUNT" || "$CORPUS_COUNT" -le 0 ]]; then
  echo "❌ Não foi possível resolver a quantidade de decks do corpus."
  exit 1
fi

if [[ -z "$REQUESTED_VALIDATION_LIMIT" ]]; then
  VALIDATION_LIMIT="$CORPUS_COUNT"
elif [[ ! "$REQUESTED_VALIDATION_LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "❌ VALIDATION_LIMIT deve ser um inteiro entre 1 e ${CORPUS_COUNT}." >&2
  exit 2
elif (( REQUESTED_VALIDATION_LIMIT > CORPUS_COUNT )); then
  echo "❌ VALIDATION_LIMIT=${REQUESTED_VALIDATION_LIMIT} excede o corpus (${CORPUS_COUNT})." >&2
  exit 2
else
  VALIDATION_LIMIT="$REQUESTED_VALIDATION_LIMIT"
fi

if [[ ! "$VALIDATION_CORPUS_OFFSET" =~ ^[0-9]+$ ]]; then
  echo "❌ VALIDATION_CORPUS_OFFSET deve ser um inteiro maior ou igual a zero." >&2
  exit 2
elif (( VALIDATION_CORPUS_OFFSET + VALIDATION_LIMIT > CORPUS_COUNT )); then
  echo "❌ OFFSET=${VALIDATION_CORPUS_OFFSET} + LIMIT=${VALIDATION_LIMIT} excede o corpus (${CORPUS_COUNT})." >&2
  exit 2
fi

print_header "Quality Gate - Resolution Corpus"
echo "API_MODE=isolated-local"
echo "PORT_HINT=${PORT}"
echo "RUN_TOKEN=${RUN_TOKEN}"
echo "VALIDATION_CORPUS_PATH=${VALIDATION_CORPUS_PATH}"
echo "CORPUS_COUNT=${CORPUS_COUNT}"
echo "VALIDATION_LIMIT=${VALIDATION_LIMIT}"
echo "VALIDATION_CORPUS_OFFSET=${VALIDATION_CORPUS_OFFSET}"
echo "VALIDATION_ARTIFACT_DIR=${VALIDATION_ARTIFACT_DIR}"

print_header "Preflight read-only do corpus"
(
  cd "$SERVER_DIR"
  VALIDATION_PREFLIGHT_ONLY=1 \
  VALIDATION_LIMIT="$VALIDATION_LIMIT" \
  VALIDATION_CORPUS_OFFSET="$VALIDATION_CORPUS_OFFSET" \
  VALIDATION_SELECTION_MODE="$VALIDATION_SELECTION_MODE" \
  VALIDATION_CORPUS_PATH="$VALIDATION_CORPUS_PATH" \
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    dart run bin/run_three_commander_resolution_validation.dart
)

case "${VALIDATION_PREFLIGHT_ONLY:-0}" in
  1|true|TRUE|yes|YES)
    print_header "Quality gate de resolução concluído em modo read-only"
    echo "✅ Corpus validado sem subir API, autenticar ou criar dados no PostgreSQL."
    exit 0
    ;;
esac

require_postgres_write_approval "Commander resolution corpus mutating E2E"

for required_tool in dart_frog lsof perl pgrep; do
  if ! command -v "$required_tool" >/dev/null 2>&1; then
    echo "BLOCKED: o launcher isolado requer o utilitário '${required_tool}'." >&2
    exit 2
  fi
done

if [[ -n "$REQUESTED_API_BASE_URL" ]]; then
  echo "BLOCKED: API_BASE_URL externo/reutilizado não é aceito no E2E mutável isolado." >&2
  echo "Use PORT como sugestão; o gate iniciará sua própria API loopback." >&2
  exit 2
fi

PORT="$(select_free_local_port "$PORT" 30 || true)"
if [[ -z "$PORT" ]]; then
  echo "❌ Nenhuma porta loopback livre encontrada para a API isolada."
  exit 1
fi
API_BASE_URL="http://127.0.0.1:${PORT}"
mkdir -p "$VALIDATION_RUN_DIR"
SERVER_BUILD_LOG="${VALIDATION_RUN_DIR}/server_build.log"
VALIDATION_SUMMARY_JSON_ABS="$(resolve_server_path "$VALIDATION_SUMMARY_JSON_PATH")"

IDENTITY_BEFORE="$(validation_identity_count | tr -d '[:space:]')"
if [[ "$IDENTITY_BEFORE" != "0" ]]; then
  echo "BLOCKED: identidade de validação já existe; gere um novo RUN_TOKEN." >&2
  exit 2
fi
GENERATED_DECK_BASELINE="$(generated_deck_count | tr -d '[:space:]')"

echo "ℹ️ Gerando build imutável do Dart Frog para o E2E..."
(
  cd "$SERVER_DIR"
  dart_frog build
) >"$SERVER_BUILD_LOG" 2>&1
perl -0pi -e \
  's/final address = InternetAddress[.]anyIPv6;/final address = InternetAddress.loopbackIPv4;/' \
  "$SERVER_DIR/build/bin/server.dart"
if ! grep -Fq \
  'final address = InternetAddress.loopbackIPv4;' \
  "$SERVER_DIR/build/bin/server.dart"; then
  echo "❌ O build de produção não pôde ser restringido ao loopback IPv4." >&2
  exit 1
fi

echo "ℹ️ Iniciando API isolada e sem hot reload em ${API_BASE_URL}..."
(
  cd "$SERVER_DIR"
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" env \
    PORT="$PORT" \
    JWT_SECRET="$BACKEND_TEST_JWT_SECRET" \
    RATE_LIMIT_DISTRIBUTED=false \
    MANALOOM_E2E_ISOLATED_RUNTIME=1 \
    MANALOOM_E2E_VALIDATION_RUN_TOKEN="$RUN_TOKEN" \
    dart run build/bin/server.dart
) >"${VALIDATION_RUN_DIR}/server.log" 2>&1 &

SERVER_PID="$!"
STARTED_BY_SCRIPT=1

for ((i = 1; i <= SERVER_START_TIMEOUT; i++)); do
  if api_ready; then
    assert_loopback_listener "$PORT"
    SERVER_LISTENER_PIDS="$(capture_listener_pids "$PORT" | tr '\n' ' ')"
    if [[ -z "$SERVER_LISTENER_PIDS" ]]; then
      echo "❌ Não foi possível capturar o PID do listener isolado." >&2
      exit 1
    fi
    echo "✅ API isolada pronta em ${API_BASE_URL} (t=${i}s)."
    break
  fi

  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "❌ O processo do servidor encerrou antes de ficar pronto."
    echo "   Verifique ${VALIDATION_RUN_DIR}/server.log"
    exit 1
  fi

  sleep 1

  if [[ "$i" -eq "$SERVER_START_TIMEOUT" ]]; then
    echo "❌ Timeout aguardando API isolada em ${API_BASE_URL}."
    echo "   Verifique ${VALIDATION_RUN_DIR}/server.log"
    exit 1
  fi
done

DB_RUN_STARTED_AT="$(database_clock | tr -d '\r\n')"
TELEMETRY_BEFORE="$(persistent_telemetry_snapshot "$DB_RUN_STARTED_AT" | tr -d '\r\n')"
MUTATION_ARMED=1

print_header "Executando runner oficial de resolução"
set +e
(
  cd "$SERVER_DIR"
  TEST_API_BASE_URL="$API_BASE_URL" \
  VALIDATION_LIMIT="$VALIDATION_LIMIT" \
  VALIDATION_CORPUS_OFFSET="$VALIDATION_CORPUS_OFFSET" \
  VALIDATION_SELECTION_MODE="$VALIDATION_SELECTION_MODE" \
  VALIDATION_CORPUS_PATH="$VALIDATION_CORPUS_PATH" \
  VALIDATION_ARTIFACT_DIR="$VALIDATION_ARTIFACT_DIR" \
  VALIDATION_SUMMARY_JSON_PATH="$VALIDATION_SUMMARY_JSON_PATH" \
  VALIDATION_SUMMARY_MD_PATH="$VALIDATION_SUMMARY_MD_PATH" \
  VALIDATION_USER_EMAIL="$VALIDATION_USER_EMAIL" \
  VALIDATION_USERNAME="$VALIDATION_USERNAME" \
  VALIDATION_USER_PASSWORD="$VALIDATION_USER_PASSWORD" \
  VALIDATION_RUN_TOKEN="$RUN_TOKEN" \
  VALIDATION_DEFER_CLEANUP_TO_HARNESS=1 \
  JWT_SECRET="$BACKEND_TEST_JWT_SECRET" \
  "$ROOT_DIR/server/bin/with_new_server_pg.sh" \
    dart run bin/run_three_commander_resolution_validation.dart
)
RUNNER_STATUS="$?"
set -e

stop_local_server
LISTENER_CLOSE_OK=1
if ! assert_listener_closed "$PORT"; then
  LISTENER_CLOSE_OK=0
fi

TELEMETRY_OBSERVED="$(persistent_telemetry_snapshot "$DB_RUN_STARTED_AT" | tr -d '\r\n')"
CLEANUP_OK=1
if ! cleanup_validation_identity; then
  CLEANUP_OK=0
fi

IDENTITY_AFTER="$(validation_identity_count | tr -d '[:space:]')"
GENERATED_DECK_AFTER="$(generated_deck_count | tr -d '[:space:]')"
TELEMETRY_AFTER="$(persistent_telemetry_snapshot "$DB_RUN_STARTED_AT" | tr -d '\r\n')"

if [[ "$IDENTITY_AFTER" != "0" || "$GENERATED_DECK_AFTER" != "$GENERATED_DECK_BASELINE" ]]; then
  CLEANUP_OK=0
fi

write_mutation_audit \
  "$TELEMETRY_BEFORE" \
  "$TELEMETRY_AFTER" \
  "$RUNNER_STATUS" \
  "$IDENTITY_AFTER" \
  "$GENERATED_DECK_BASELINE" \
  "$GENERATED_DECK_AFTER" \
  "$CLEANUP_OK" \
  "$LISTENER_CLOSE_OK" \
  "$SERVER_STOP_OK" \
  "$SERVER_LISTENER_PIDS" \
  "$TELEMETRY_OBSERVED" \
  "$TELEMETRY_CLEANUP_JSON"

echo "📊 Auditoria de mutação: $MUTATION_AUDIT_PATH"

LEARNING_WRITE_GUARD_OK="$(python3 - "$MUTATION_AUDIT_PATH" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("1" if payload.get("learning_write_guard", {}).get("pass") is True else "0")
PY
)"

if [[ "$CLEANUP_OK" -ne 1 ]]; then
  echo "❌ Cleanup incompleto: identidade ou decks temporários permaneceram." >&2
  exit 2
fi

if [[ "$LISTENER_CLOSE_OK" -ne 1 || "$SERVER_STOP_OK" -ne 1 ]]; then
  echo "❌ Encerramento incompleto da API isolada; cleanup e auditoria já foram concluídos." >&2
  exit 2
fi

if [[ "$LEARNING_WRITE_GUARD_OK" -ne 1 ]]; then
  echo "❌ O runtime E2E alterou aprendizado global do produto; gate bloqueado." >&2
  exit 2
fi

if [[ "$RUNNER_STATUS" -ne 0 ]]; then
  echo "❌ Runner de resolução falhou com exit ${RUNNER_STATUS}; cleanup foi auditado." >&2
  exit "$RUNNER_STATUS"
fi

python3 - "$VALIDATION_SUMMARY_JSON_ABS" "$VALIDATION_LIMIT" "$CORPUS_COUNT" <<'PY'
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
expected_total = int(sys.argv[2])
corpus_total = int(sys.argv[3])

if not summary_path.exists():
    print(f"❌ Resumo não encontrado: {summary_path}")
    sys.exit(2)

summary = json.loads(summary_path.read_text(encoding="utf-8"))
total = int(summary.get("total") or 0)
passed = int(summary.get("passed") or 0)
failed = int(summary.get("failed") or 0)
unresolved = int(summary.get("unresolved") or 0)
direct_optimizations = int(summary.get("direct_optimizations") or 0)
outcomes = summary.get("optimize_outcome_summary")

if not isinstance(outcomes, dict):
    print("❌ Gate de resolução falhou: optimize_outcome_summary ausente ou inválido.")
    sys.exit(2)

contract_accepted = int(outcomes.get("contract_accepted_http_200") or 0)
contract_rejected = int(outcomes.get("contract_rejected_http_200") or 0)
mock_responses = int(outcomes.get("mock_responses") or 0)
mock_non_actionable = int(outcomes.get("mock_non_actionable_outcomes") or 0)
actionable_swap_pairs = int(outcomes.get("actionable_swap_pairs") or 0)
candidate_swap_pairs = int(outcomes.get("candidate_swap_pairs") or 0)
rejected_candidate_swap_pairs = int(
    outcomes.get("rejected_candidate_swap_pairs") or 0
)
provider = summary.get("provider_evidence_summary")

if not isinstance(provider, dict):
    print("❌ Gate de resolução falhou: provider_evidence_summary ausente ou inválido.")
    sys.exit(2)

provider_calls = int(provider.get("call_count") or 0)
provider_successful_calls = int(provider.get("successful_calls") or 0)
runtime_provenance = summary.get("runtime_provenance_summary")

if not isinstance(runtime_provenance, dict):
    print("❌ Gate de resolução falhou: runtime_provenance_summary ausente ou inválido.")
    sys.exit(2)

known_origin_results = int(runtime_provenance.get("known_results") or 0)
unknown_origin_results = int(runtime_provenance.get("unknown_results") or 0)
runtime_origins = runtime_provenance.get("origins")
if not isinstance(runtime_origins, dict):
    print("❌ Gate de resolução falhou: origins de proveniência ausente ou inválido.")
    sys.exit(2)
runtime_origin_total = sum(int(value or 0) for value in runtime_origins.values())

if total != expected_total:
    print(
        f"❌ Gate de resolução falhou: total={total}, esperado={expected_total}."
    )
    sys.exit(2)

if failed > 0 or unresolved > 0 or passed != total:
    print(
        "❌ Gate de resolução falhou: "
        f"passed={passed}, failed={failed}, unresolved={unresolved}, total={total}."
    )
    sys.exit(2)

outcome_errors = []
if mock_responses != 0:
    outcome_errors.append(f"mock_responses={mock_responses}, esperado=0")
if mock_non_actionable != 0:
    outcome_errors.append(
        f"mock_non_actionable_outcomes={mock_non_actionable}, esperado=0"
    )
if contract_rejected != 0:
    outcome_errors.append(
        f"contract_rejected_http_200={contract_rejected}, esperado=0"
    )
if expected_total == corpus_total and direct_optimizations <= 0:
    outcome_errors.append(
        f"direct_optimizations={direct_optimizations}, esperado>0"
    )
if expected_total == corpus_total and actionable_swap_pairs <= 0:
    outcome_errors.append(
        f"actionable_swap_pairs={actionable_swap_pairs}, esperado>0"
    )
if contract_accepted != direct_optimizations:
    outcome_errors.append(
        "contract_accepted_http_200="
        f"{contract_accepted}, direct_optimizations={direct_optimizations}"
    )
if unknown_origin_results != 0:
    outcome_errors.append(
        f"unknown_origin_results={unknown_origin_results}, esperado=0"
    )
if known_origin_results != total or runtime_origin_total != total:
    outcome_errors.append(
        "proveniência runtime inconsistente: "
        f"known={known_origin_results}, origins_total={runtime_origin_total}, total={total}"
    )
if provider_successful_calls > provider_calls:
    outcome_errors.append(
        f"provider_successful_calls={provider_successful_calls} maior que "
        f"provider_calls={provider_calls}"
    )
if candidate_swap_pairs < actionable_swap_pairs:
    outcome_errors.append(
        f"candidate_swap_pairs={candidate_swap_pairs} menor que "
        f"actionable_swap_pairs={actionable_swap_pairs}"
    )
if rejected_candidate_swap_pairs > candidate_swap_pairs:
    outcome_errors.append(
        f"rejected_candidate_swap_pairs={rejected_candidate_swap_pairs} maior que "
        f"candidate_swap_pairs={candidate_swap_pairs}"
    )

if outcome_errors:
    print(
        "❌ Gate de resolução falhou no contrato runtime do otimizador: "
        + "; ".join(outcome_errors)
    )
    sys.exit(2)

print(
    "✅ Resumo do corpus validado: "
    f"passed={passed}, failed={failed}, unresolved={unresolved}, total={total}, "
    f"direct_optimizations={direct_optimizations}, "
    f"contract_accepted_http_200={contract_accepted}, "
    f"candidate_swap_pairs={candidate_swap_pairs}, "
    f"rejected_candidate_swap_pairs={rejected_candidate_swap_pairs}, "
    f"actionable_swap_pairs={actionable_swap_pairs}, "
    f"runtime_origins={runtime_origins}, "
    f"provider_successful_calls={provider_successful_calls}, mock_responses=0."
)
PY

print_header "Quality gate de resolução concluído"
echo "✅ Gate recorrente do corpus executado com sucesso."
echo "📦 Resumo JSON: $VALIDATION_SUMMARY_JSON_ABS"
echo "📊 Telemetria persistente medida (não apagada): $MUTATION_AUDIT_PATH"
