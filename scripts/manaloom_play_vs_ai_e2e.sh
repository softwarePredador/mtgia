#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
SIDECAR_DIR="$ROOT_DIR/services/xmage-sidecar"
BOOTSTRAP="$SIDECAR_DIR/bin/bootstrap_pinned_xmage_runtime.sh"

BROWSER_QA_MODE="${MANALOOM_PLAY_VS_AI_BROWSER_QA:-0}"
case "$BROWSER_QA_MODE" in
  0 | 1) ;;
  *)
    echo "MANALOOM_PLAY_VS_AI_BROWSER_QA must be 0 or 1" >&2
    exit 2
    ;;
esac

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_postgres_write_approval \
  "Play vs AI E2E in disposable loopback PostgreSQL"
require_live_mutation_approval \
  "Play vs AI E2E through a disposable loopback API"

PINNED_FLUTTER_ROOT="${MANALOOM_PLAY_VS_AI_FLUTTER_ROOT:-${HOME:?HOME is required}/.manaloom/toolchains/flutter-3.44.6}"
PINNED_DART_BIN="$PINNED_FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart"
if [[ ! -x "$PINNED_DART_BIN" || ! -x "$PINNED_FLUTTER_ROOT/bin/flutter" ]]; then
  echo "Pinned Flutter 3.44.6 / Dart toolchain is unavailable" >&2
  exit 2
fi
pinned_dart_dir="$(dirname -- "$PINNED_DART_BIN")"
export PATH="$pinned_dart_dir:$PINNED_FLUTTER_ROOT/bin:$PATH"

for tool in curl dart dart_frog find git initdb java jq lsof mvn perl pg_ctl pg_isready psql python3 shasum unzip; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Required tool is missing: $tool" >&2
    exit 2
  }
done
dart_version="$(dart --version 2>&1)"
if [[ "$dart_version" != *'3.12.2'* ]]; then
  echo "Play vs AI E2E requires pinned Dart 3.12.2: $dart_version" >&2
  exit 2
fi
dart_frog_version="$(dart_frog --version 2>&1 | sed -n '1p')"
[[ -x "$BOOTSTRAP" ]] || {
  echo "Pinned XMage runtime bootstrap is not executable: $BOOTSTRAP" >&2
  exit 2
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  resolved_java17="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  if [[ -z "$resolved_java17" ]]; then
    echo "Play vs AI E2E requires an installed Java 17 JDK" >&2
    exit 2
  fi
  export JAVA_HOME="$resolved_java17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
java_version="$(java -version 2>&1 | sed -n '1p')"
if [[ "$java_version" != *'17.'* ]]; then
  echo "Play vs AI E2E requires Java 17: $java_version" >&2
  exit 2
fi
java_spec_version="$(
  java -XshowSettings:properties -version 2>&1 |
    sed -n 's/^[[:space:]]*java[.]specification[.]version = //p' |
    sed -n '1p'
)"
if [[ "$java_spec_version" != "17" ]]; then
  echo "Play vs AI E2E requires java.specification.version=17" >&2
  exit 2
fi
maven_version="$(mvn -version 2>&1)"
if ! printf '%s\n' "$maven_version" | grep -Eq '^Java version: 17([.]|,|$)'; then
  maven_java_version="$(
    printf '%s\n' "$maven_version" |
      sed -n 's/^Java version: /Java version: /p' |
      sed -n '1p'
  )"
  echo "Play vs AI E2E requires Maven on Java 17: ${maven_java_version:-unknown}" >&2
  exit 2
fi
maven_java_version="$(
  printf '%s\n' "$maven_version" |
    sed -n 's/^Java version: /Java version: /p' |
    sed -n '1p'
)"

POSTGRES_MODE="${MANALOOM_PLAY_VS_AI_POSTGRES_MODE:-owned_disposable}"
case "$POSTGRES_MODE" in
  owned_disposable)
    DB_HOST=127.0.0.1
    DB_PORT=""
    DB_USER="$(id -un)"
    DB_PASS=""
    ;;
  existing_loopback)
    # Load only credentials through the repository's non-eval parser.
    # shellcheck source=scripts/lib/manaloom_safe_env.sh
    # shellcheck disable=SC1091
    source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
    if [[ -f "$ROOT_DIR/server/.env" ]]; then
      [[ -n "${DB_USER:-}" ]] || \
        load_manaloom_env_key "$ROOT_DIR/server/.env" DB_USER
      [[ -n "${DB_PASS:-}" ]] || \
        load_manaloom_env_key "$ROOT_DIR/server/.env" DB_PASS
    fi
    DB_HOST="${DB_HOST:-127.0.0.1}"
    DB_PORT="${DB_PORT:-5432}"
    DB_USER="${DB_USER:-$(id -un)}"
    DB_PASS="${DB_PASS:-}"
    case "$DB_HOST" in
      127.0.0.1 | localhost | ::1) ;;
      *)
        echo "BLOCKED: Play vs AI E2E accepts only loopback PostgreSQL" >&2
        exit 2
        ;;
    esac
    pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1 || {
      echo "Loopback PostgreSQL is unavailable at $DB_HOST:$DB_PORT" >&2
      exit 2
    }
    PGPASSWORD="$DB_PASS" psql -X -A -t \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres \
      -c 'SELECT 1' >/dev/null 2>&1 || {
      echo "Loopback PostgreSQL credentials are not usable" >&2
      exit 2
    }
    ;;
  *)
    echo "MANALOOM_PLAY_VS_AI_POSTGRES_MODE must be owned_disposable or existing_loopback" >&2
    exit 2
    ;;
esac

XMAGE_COMMIT="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_COMMIT")"
XMAGE_PATCH_COMMIT="$(tr -d '[:space:]' <"$SIDECAR_DIR/XMAGE_PATCH_COMMIT")"
XMAGE_VERSION="1.4.60"
EXPECTED_XMAGE_COMMIT="2c43ec8cdb5cd475d47e6b555a4077151f476a3b"
EXPECTED_XMAGE_PATCH_COMMIT="991948742f840cd88493a4ea8cb3f4ed192e4742"
EXPECTED_BUILD="xmage-sidecar-v2@$EXPECTED_XMAGE_COMMIT+patch.$EXPECTED_XMAGE_PATCH_COMMIT"
if [[ "$XMAGE_COMMIT" != "$EXPECTED_XMAGE_COMMIT" ||
      "$XMAGE_PATCH_COMMIT" != "$EXPECTED_XMAGE_PATCH_COMMIT" ]]; then
  echo "BLOCKED: repository XMage pins differ from the reviewed E2E contract" >&2
  exit 2
fi

case "$(uname -s)" in
  Darwin)
    DEFAULT_REPORT_ROOT="${HOME:?HOME is required}/Library/Application Support/ManaLoom/e2e/play-vs-ai"
    ;;
  *)
    DEFAULT_REPORT_ROOT="${XDG_STATE_HOME:-${HOME:?HOME is required}/.local/state}/manaloom/e2e/play-vs-ai"
    ;;
esac
REPORT_ROOT="${MANALOOM_PLAY_VS_AI_E2E_REPORT_ROOT:-$DEFAULT_REPORT_ROOT}"
case "$REPORT_ROOT" in
  /*) ;;
  *)
    echo "MANALOOM_PLAY_VS_AI_E2E_REPORT_ROOT must be absolute" >&2
    exit 2
    ;;
esac

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$_${RANDOM}"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"
RUN_DIR="$(mktemp -d "$TMP_ROOT/manaloom-play-vs-ai-e2e.XXXXXX")"
REPORT_DIR="$REPORT_ROOT/$RUN_ID"
REPORT_JSON="$REPORT_DIR/report.json"
REPORT_MARKDOWN="$REPORT_DIR/report.md"
CHILD_RECEIPT_DIR="$RUN_DIR/server-contract-receipts"
BROWSER_CHILD_RECEIPT_DIR="$RUN_DIR/browser-server-contract-receipts"
BROWSER_CAPTURE_RELATIVE="docs/qa/ui-live/current/play-vs-ai-web-real"
BROWSER_CAPTURE_DIR="$ROOT_DIR/$BROWSER_CAPTURE_RELATIVE"
mkdir -p "$REPORT_DIR" "$CHILD_RECEIPT_DIR"
if [[ "$BROWSER_QA_MODE" == "1" ]]; then
  if [[ -e "$BROWSER_CAPTURE_DIR" || -L "$BROWSER_CAPTURE_DIR" ]]; then
    echo "Play vs AI browser evidence directory already exists: $BROWSER_CAPTURE_DIR" >&2
    echo "Review and archive the existing evidence before recapturing." >&2
    exit 2
  fi
  mkdir -p "$BROWSER_CHILD_RECEIPT_DIR" "$BROWSER_CAPTURE_DIR"
fi

BOOTSTRAP_LOG="$RUN_DIR/xmage-bootstrap.log"
SERVER_LOG="$RUN_DIR/xmage-server.log"
SPIKE_LOG="$RUN_DIR/natural-runtime-spike.log"
SIDECAR_BUILD_LOG="$RUN_DIR/sidecar-build.log"
BATCH_LOG="$RUN_DIR/xmage-batch-sidecar.log"
INTERACTIVE_LOG="$RUN_DIR/xmage-interactive-sidecar.log"
CONTRACT_LOG="$RUN_DIR/server-contract-e2e.log"
BATCH_HEALTH="$RUN_DIR/batch-health.json"
INTERACTIVE_HEALTH="$RUN_DIR/interactive-health.json"
CAPABILITY_POLICY="$RUN_DIR/release-capabilities.play-vs-ai-e2e.json"
GOVERNED_PATCH_AUDIT="$RUN_DIR/xmage-governed-patch-audit.json"
RUNTIME_DIR="$RUN_DIR/xmage-runtime"
POSTGRES_DATA_DIR="$RUN_DIR/postgres-data"
POSTGRES_LOG="$RUN_DIR/postgres.log"
POSTGRES_SERVER_LOG="$RUN_DIR/postgres-server.log"
BROWSER_CONTRACT_LOG="$RUN_DIR/browser-server-contract.log"
BROWSER_BUILD_LOG="$RUN_DIR/flutter-web-build.log"
BROWSER_WEB_LOG="$RUN_DIR/flutter-web.log"
BROWSER_READY_MANIFEST="$RUN_DIR/browser-ready.json"
BROWSER_CREDENTIALS_FILE="$RUN_DIR/browser-credentials.env"
BROWSER_DONE_FILE="$RUN_DIR/browser-qa-complete.json"
BROWSER_RELEASE_FILE="$RUN_DIR/browser-api-release.txt"
BROWSER_WEB_BUILD_DIR="$RUN_DIR/flutter-web-build"
BROWSER_SCREENSHOT_DIGESTS="$RUN_DIR/browser-screenshot-digests.json"
BROWSER_RUNTIME_LOG="$RUN_DIR/browser-runtime.log"
BROWSER_CAPTURE_MANIFEST="$BROWSER_CAPTURE_DIR/capture-manifest.json"
BROWSER_VISUAL_REVIEW="$BROWSER_CAPTURE_DIR/visual-review.json"

FAILURE_STAGE="initialize"
WORKFLOW_PASS=0
CLEANUP_OK=1
FORCED_KILL=0
SERVER_PID=""
BATCH_PID=""
INTERACTIVE_PID=""
CONTRACT_PID=""
WEB_PID=""
POSTGRES_OWNED=0
XMAGE_PORT=""
XMAGE_SECONDARY_PORT=""
BATCH_PORT=""
INTERACTIVE_PORT=""
SELECTED_POSTGRES_PORT=""
BROWSER_WEB_PORT=""
BROWSER_WEB_URL=""
BROWSER_API_BASE_URL=""
BROWSER_DATABASE=""
BROWSER_CHILD_RUN_DIR=""
BROWSER_CHILD_SUMMARY="$BROWSER_CHILD_RECEIPT_DIR/summary.txt"
BROWSER_CHILD_CLEANUP="$BROWSER_CHILD_RECEIPT_DIR/cleanup.txt"
BROWSER_CHILD_CLEANUP_RESULT="not_requested"
BROWSER_QA_RESULT="not_requested"
BROWSER_BUNDLE_SHA=""
BROWSER_UI_SOURCE_DIGEST=""
BROWSER_EVIDENCE_JSON="{}"
CHILD_SUMMARY="$CHILD_RECEIPT_DIR/summary.txt"
CHILD_CLEANUP="$CHILD_RECEIPT_DIR/cleanup.txt"
CHILD_RUN_DIR=""
CHILD_CLEANUP_RESULT="not_run"
RUNTIME_ZIP=""
RUNTIME_ZIP_SHA=""
SIDECAR_JAR=""
SIDECAR_JAR_SHA=""
CAPABILITY_POLICY_SHA=""
PLAY_EVIDENCE_JSON="{}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_HEAD="$(git -C "$ROOT_DIR" rev-parse HEAD)"
WORKTREE_STATUS_SHA="$(
  git -C "$ROOT_DIR" status --porcelain=v1 -uall |
    shasum -a 256 | awk '{print $1}'
)"
if [[ "$BROWSER_QA_MODE" == "1" ]]; then
  BROWSER_UI_SOURCE_DIGEST="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  [[ "$BROWSER_UI_SOURCE_DIGEST" =~ ^[0-9a-f]{64}$ ]]
fi

copy_artifact() {
  local source_path="$1"
  local output_name="$2"
  if [[ -f "$source_path" ]]; then
    cp "$source_path" "$REPORT_DIR/$output_name"
  fi
}

terminate_owned_pid() {
  local process_id="$1"
  [[ -n "$process_id" ]] || return 0
  if ! kill -0 "$process_id" >/dev/null 2>&1; then
    wait "$process_id" >/dev/null 2>&1 || true
    return 0
  fi
  kill -TERM "$process_id" >/dev/null 2>&1 || true
  for _ in $(seq 1 200); do
    if ! kill -0 "$process_id" >/dev/null 2>&1; then
      wait "$process_id" >/dev/null 2>&1 || true
      return 0
    fi
    sleep 0.1
  done
  FORCED_KILL=1
  kill -KILL "$process_id" >/dev/null 2>&1 || true
  wait "$process_id" >/dev/null 2>&1 || true
  if kill -0 "$process_id" >/dev/null 2>&1; then
    CLEANUP_OK=0
    return 1
  fi
}

listener_count() {
  local port="$1"
  if [[ -z "$port" ]]; then
    printf '0\n'
    return
  fi
  lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null |
    awk 'NR > 1 {count++} END {print count + 0}'
}

cleanup_runtime() {
  set +e
  terminate_owned_pid "$WEB_PID" || CLEANUP_OK=0
  if [[ -n "$CONTRACT_PID" ]] && kill -0 "$CONTRACT_PID" >/dev/null 2>&1; then
    terminate_owned_pid "$CONTRACT_PID" || CLEANUP_OK=0
  fi
  terminate_owned_pid "$INTERACTIVE_PID" || CLEANUP_OK=0
  terminate_owned_pid "$BATCH_PID" || CLEANUP_OK=0
  terminate_owned_pid "$SERVER_PID" || CLEANUP_OK=0
  for port in "$XMAGE_PORT" "$XMAGE_SECONDARY_PORT" "$BATCH_PORT" "$INTERACTIVE_PORT"; do
    if [[ -n "$port" && "$(listener_count "$port")" != "0" ]]; then
      CLEANUP_OK=0
    fi
  done
  if [[ -n "$BROWSER_WEB_PORT" &&
        "$(listener_count "$BROWSER_WEB_PORT")" != "0" ]]; then
    CLEANUP_OK=0
  fi
  if [[ "$POSTGRES_OWNED" == "1" ]]; then
    if pg_ctl -D "$POSTGRES_DATA_DIR" status >/dev/null 2>&1; then
      pg_ctl -D "$POSTGRES_DATA_DIR" -m fast -w stop \
        >>"$POSTGRES_LOG" 2>&1 || CLEANUP_OK=0
    fi
    if pg_ctl -D "$POSTGRES_DATA_DIR" status >/dev/null 2>&1; then
      CLEANUP_OK=0
    fi
    if [[ -n "$DB_PORT" && "$(listener_count "$DB_PORT")" != "0" ]]; then
      CLEANUP_OK=0
    fi
  fi
}

write_report() {
  local final_result="$1"
  local final_status="$2"
  local finished_at
  finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  copy_artifact "$BOOTSTRAP_LOG" "xmage-bootstrap.log"
  copy_artifact "$SERVER_LOG" "xmage-server.log"
  copy_artifact "$SPIKE_LOG" "natural-runtime-spike.log"
  copy_artifact "$SIDECAR_BUILD_LOG" "sidecar-build.log"
  copy_artifact "$BATCH_LOG" "xmage-batch-sidecar.log"
  copy_artifact "$INTERACTIVE_LOG" "xmage-interactive-sidecar.log"
  copy_artifact "$CONTRACT_LOG" "server-contract-e2e.log"
  copy_artifact "$BATCH_HEALTH" "batch-health.json"
  copy_artifact "$INTERACTIVE_HEALTH" "interactive-health.json"
  copy_artifact "$CHILD_SUMMARY" "server-contract-summary.txt"
  copy_artifact "$CHILD_CLEANUP" "server-contract-cleanup.txt"
  copy_artifact "$GOVERNED_PATCH_AUDIT" "xmage-governed-patch-audit.json"
  copy_artifact "$POSTGRES_LOG" "postgres.log"
  copy_artifact "$POSTGRES_SERVER_LOG" "postgres-server.log"
  copy_artifact "$BROWSER_CONTRACT_LOG" "browser-server-contract.log"
  copy_artifact "$BROWSER_BUILD_LOG" "flutter-web-build.log"
  copy_artifact "$BROWSER_WEB_LOG" "flutter-web.log"
  copy_artifact "$BROWSER_RUNTIME_LOG" "browser-runtime.log"
  copy_artifact "$BROWSER_READY_MANIFEST" "browser-ready.json"
  copy_artifact "$BROWSER_CAPTURE_MANIFEST" "browser-capture-manifest.json"
  copy_artifact "$BROWSER_VISUAL_REVIEW" "browser-visual-review.json"
  copy_artifact "$BROWSER_CHILD_SUMMARY" "browser-server-contract-summary.txt"
  copy_artifact "$BROWSER_CHILD_CLEANUP" "browser-server-contract-cleanup.txt"
  copy_artifact "$BROWSER_SCREENSHOT_DIGESTS" "browser-screenshot-digests.json"

  jq -n \
    --arg schema_version "play_vs_ai_e2e_report_v1" \
    --arg result "$final_result" \
    --arg failure_stage "$FAILURE_STAGE" \
    --arg started_at "$STARTED_AT" \
    --arg finished_at "$finished_at" \
    --arg git_head "$GIT_HEAD" \
    --arg worktree_status_sha256 "$WORKTREE_STATUS_SHA" \
    --arg xmage_version "$XMAGE_VERSION" \
    --arg xmage_commit "$XMAGE_COMMIT" \
    --arg xmage_patch_commit "$XMAGE_PATCH_COMMIT" \
    --arg runtime_zip_sha256 "$RUNTIME_ZIP_SHA" \
    --arg sidecar_jar_sha256 "$SIDECAR_JAR_SHA" \
    --arg sidecar_build "$EXPECTED_BUILD" \
    --arg capability_policy_sha256 "$CAPABILITY_POLICY_SHA" \
    --arg java_version "$java_version" \
    --arg java_specification_version "$java_spec_version" \
    --arg maven_java_version "$maven_java_version" \
    --arg dart_version "$dart_version" \
    --arg dart_frog_version "$dart_frog_version" \
    --arg postgres_mode "$POSTGRES_MODE" \
    --arg child_cleanup_result "$CHILD_CLEANUP_RESULT" \
    --arg browser_qa_result "$BROWSER_QA_RESULT" \
    --arg browser_child_cleanup_result "$BROWSER_CHILD_CLEANUP_RESULT" \
    --arg browser_bundle_sha256 "$BROWSER_BUNDLE_SHA" \
    --arg browser_ui_source_digest "$BROWSER_UI_SOURCE_DIGEST" \
    --arg report_dir "$REPORT_DIR" \
    --argjson exit_code "$final_status" \
    --argjson cleanup_ok "$CLEANUP_OK" \
    --argjson forced_kill "$FORCED_KILL" \
    --argjson play_evidence "$PLAY_EVIDENCE_JSON" \
    --argjson browser_evidence "$BROWSER_EVIDENCE_JSON" \
    '{
      schema_version: $schema_version,
      result: $result,
      exit_code: $exit_code,
      failure_stage: $failure_stage,
      started_at: $started_at,
      finished_at: $finished_at,
      scope: "disposable_loopback_postgresql_api_and_pinned_xmage",
      source: {
        git_head: $git_head,
        worktree_status_sha256: $worktree_status_sha256
      },
      toolchain: {
        java: $java_version,
        java_specification_version: $java_specification_version,
        maven_java: $maven_java_version,
        dart: $dart_version,
        dart_frog: $dart_frog_version
      },
      engine: {
        name: "xmage",
        version: $xmage_version,
        upstream_commit: $xmage_commit,
        governed_patch_commit: $xmage_patch_commit,
        build_identity: $sidecar_build,
        runtime_zip_sha256: $runtime_zip_sha256,
        sidecar_jar_sha256: $sidecar_jar_sha256
      },
      topology: {
        address: "127.0.0.1",
        postgresql: $postgres_mode,
        batch_and_interactive_processes_distinct: true,
        h2_bind_address: "127.0.0.1",
        xmage_primary_and_secondary_explicit: true,
        non_loopback_listener_policy: "fail_closed"
      },
      isolated_capabilities: {
        policy_sha256: $capability_policy_sha256,
        enabled_only: [
          "account_registration",
          "decks_private",
          "battle_batch",
          "battle_coach"
        ],
        committed_policy_modified: false
      },
      evidence: {
        natural_full_match_spike: "natural-runtime-spike.log",
        real_api_engine_test: "server-contract-e2e.log",
        server_contract_summary: "server-contract-summary.txt",
        server_contract_cleanup: "server-contract-cleanup.txt",
        child_cleanup_result: $child_cleanup_result,
        play_vs_ai: $play_evidence,
        browser_qa: {
          requested: ($browser_qa_result != "not_requested"),
          result: $browser_qa_result,
          child_cleanup_result: $browser_child_cleanup_result,
          bundle_sha256: (
            if $browser_bundle_sha256 == "" then null
            else $browser_bundle_sha256 end
          ),
          ui_source_digest: (
            if $browser_ui_source_digest == "" then null
            else $browser_ui_source_digest end
          ),
          runtime: $browser_evidence
        }
      },
      cleanup: {
        success: ($cleanup_ok == 1),
        forced_kill_used: ($forced_kill == 1),
        owned_runtime_processes_remaining: ($cleanup_ok == 0)
      },
      strategy_superiority_proven: false,
      release_ready: false,
      committed_capability_state: "off",
      report_dir: $report_dir
    }' >"$REPORT_JSON"

  {
    printf '# Play vs AI isolated E2E\n\n'
    printf -- '- Result: %s\n' "$final_result"
    printf -- '- Failure stage: %s\n' "$FAILURE_STAGE"
    printf -- '- Engine: XMage %s at %s + patch %s\n' \
      "$XMAGE_VERSION" "$XMAGE_COMMIT" "$XMAGE_PATCH_COMMIT"
    printf -- '- Scope: disposable loopback API/PostgreSQL/XMage only\n'
    printf -- '- Strategy superiority proven: false\n'
    printf -- '- Release ready: false\n'
    printf -- '- Cleanup: %s\n' "$CHILD_CLEANUP_RESULT"
    printf -- '- Browser QA: %s\n' "$BROWSER_QA_RESULT"
    printf -- '- Browser fixture cleanup: %s\n' \
      "$BROWSER_CHILD_CLEANUP_RESULT"
  } >"$REPORT_MARKDOWN"

  local latest_tmp
  latest_tmp="$REPORT_ROOT/.latest.json.$$"
  cp "$REPORT_JSON" "$latest_tmp"
  mv -f "$latest_tmp" "$REPORT_ROOT/latest.json"
}

on_exit() {
  local original_status="$?"
  local final_status="$original_status"
  local final_result="fail"
  trap - EXIT INT TERM
  set +e
  cleanup_runtime
  local browser_success=0
  if [[ "$BROWSER_QA_MODE" == "0" &&
        "$BROWSER_QA_RESULT" == "not_requested" ]]; then
    browser_success=1
  elif [[ "$BROWSER_QA_MODE" == "1" &&
          "$BROWSER_QA_RESULT" == "pass" &&
          "$BROWSER_CHILD_CLEANUP_RESULT" == "pass" ]]; then
    browser_success=1
  fi
  if [[ "$original_status" == 0 && "$WORKFLOW_PASS" == 1 &&
        "$CLEANUP_OK" == 1 && "$CHILD_CLEANUP_RESULT" == "pass" &&
        "$browser_success" == "1" ]]; then
    final_status=0
    final_result="pass"
  else
    [[ "$final_status" != 0 ]] || final_status=1
  fi
  write_report "$final_result" "$final_status"
  if [[ -n "$CHILD_RUN_DIR" ]]; then
    case "$CHILD_RUN_DIR" in
      "$TMP_ROOT"/manaloom_server_contract_e2e_*)
        find "$CHILD_RUN_DIR" -depth -delete 2>/dev/null || true
        ;;
    esac
  fi
  if [[ -n "$BROWSER_CHILD_RUN_DIR" ]]; then
    case "$BROWSER_CHILD_RUN_DIR" in
      "$TMP_ROOT"/manaloom_server_contract_e2e_*)
        find "$BROWSER_CHILD_RUN_DIR" -depth -delete 2>/dev/null || true
        ;;
    esac
  fi
  find "$RUN_DIR" -depth -delete 2>/dev/null || true
  if [[ "$final_result" == "pass" ]]; then
    printf 'PASS: Play vs AI real XMage E2E\n'
  else
    printf 'FAIL: Play vs AI real XMage E2E at stage=%s\n' "$FAILURE_STAGE" >&2
  fi
  printf 'report=%s\n' "$REPORT_JSON"
  exit "$final_status"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

select_ports() {
  python3 - <<'PY'
import socket

sockets = []
try:
    for _ in range(6):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.bind(("127.0.0.1", 0))
        sockets.append(sock)
    print(" ".join(str(sock.getsockname()[1]) for sock in sockets))
finally:
    for sock in sockets:
        sock.close()
PY
}

wait_for_listener() {
  local process_id="$1"
  local port="$2"
  local label="$3"
  for _ in $(seq 1 600); do
    if lsof -nP -a -p "$process_id" -iTCP:"$port" -sTCP:LISTEN \
      2>/dev/null | awk 'NR > 1 {found=1} END {exit found ? 0 : 1}'; then
      return 0
    fi
    if ! kill -0 "$process_id" >/dev/null 2>&1; then
      echo "$label exited before opening port $port" >&2
      return 1
    fi
    sleep 0.1
  done
  echo "Timed out waiting for $label on 127.0.0.1:$port" >&2
  return 1
}

assert_pid_loopback_listeners() {
  local process_id="$1"
  local label="$2"
  local listeners
  listeners="$(lsof -nP -a -p "$process_id" -iTCP -sTCP:LISTEN || true)"
  if [[ -z "$listeners" ]] || printf '%s\n' "$listeners" |
    awk 'NR > 1 && $9 !~ /^127[.]0[.]0[.]1:/ {bad=1} END {exit bad ? 0 : 1}'; then
    echo "BLOCKED: $label opened a listener outside IPv4 loopback" >&2
    printf '%s\n' "$listeners" >&2
    return 1
  fi
}

assert_port_loopback_listeners() {
  local port="$1"
  local label="$2"
  local listeners
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -z "$listeners" ]] || printf '%s\n' "$listeners" |
    awk 'NR > 1 && $9 !~ /^127[.]0[.]0[.]1:/ {bad=1} END {exit bad ? 0 : 1}'; then
    echo "BLOCKED: $label opened a listener outside IPv4 loopback" >&2
    printf '%s\n' "$listeners" >&2
    return 1
  fi
}

wait_for_health() {
  local process_id="$1"
  local port="$2"
  local output="$3"
  local label="$4"
  for _ in $(seq 1 600); do
    if curl -fsS "http://127.0.0.1:$port/health" >"$output" 2>/dev/null; then
      return 0
    fi
    if ! kill -0 "$process_id" >/dev/null 2>&1; then
      echo "$label exited before health became ready" >&2
      return 1
    fi
    sleep 0.1
  done
  echo "Timed out waiting for $label health" >&2
  return 1
}

run_browser_qa() {
  local browser_ready_path=""
  local browser_seed_suffix=""
  local browser_email=""
  local browser_username=""
  local browser_password=""
  local browser_login_url=""
  local browser_token=""
  local browser_human_deck_response=""
  local browser_ai_deck_response=""
  local browser_human_deck_id=""
  local browser_ai_deck_id=""
  local browser_human_deck_name=""
  local browser_ai_deck_name=""
  local browser_session_id=""
  local browser_session_response=""
  local browser_replay_id=""
  local browser_replay_response=""
  local browser_record_counts=""
  local browser_action_records=""
  local browser_prompt_records=""
  local browser_record_total=""
  local browser_session_requests=""
  local browser_replay_requests=""
  local browser_replay_evidence=""
  local browser_done_attestation=""
  local browser_required_checkpoints_json=""
  local browser_capture_manifest_sha=""
  local browser_visual_review_sha=""
  local browser_qa_deadline=0
  local screenshot_name=""
  local screenshot_path=""
  local browser_child_cleanup_status=""
  local browser_contract_status=""
  local current_ui_source_digest=""
  local required_screenshots=(
    "01-opponent-picker.png"
    "02-private-hand-mulligan.png"
    "03-land-played.png"
    "04-commander-cast.png"
    "05-combat-damage.png"
    "06-reconnected-session.png"
    "07-terminal-replay-rematch.png"
    "08-replay.png"
    "09-rematch-picker.png"
  )

  BROWSER_QA_RESULT="fail"
  BROWSER_CHILD_CLEANUP_RESULT="pending"

  FAILURE_STAGE="start_browser_qa_api_fixture"
  env \
    DB_HOST="$DB_HOST" \
    DB_PORT="$DB_PORT" \
    DB_USER="$DB_USER" \
    DB_PASS="$DB_PASS" \
    INTERACTIVE_BATTLE_ENABLED=true \
    XMAGE_SIDECAR_URL="http://127.0.0.1:$BATCH_PORT" \
    XMAGE_INTERACTIVE_SIDECAR_URL="http://127.0.0.1:$INTERACTIVE_PORT" \
    XMAGE_EXPECTED_COMMIT="$XMAGE_COMMIT" \
    XMAGE_EXPECTED_PATCH_COMMIT="$XMAGE_PATCH_COMMIT" \
    XMAGE_EXPECTED_VERSION="$XMAGE_VERSION" \
    MANALOOM_HOLD_FOR_BROWSER_QA=1 \
    MANALOOM_E2E_ISOLATED_RUNTIME=1 \
    MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="$CAPABILITY_POLICY" \
    MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY \
    MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
    MANALOOM_ISOLATED_E2E_RECEIPT_DIR="$BROWSER_CHILD_RECEIPT_DIR" \
    MANALOOM_BROWSER_QA_COMPLETION_FILE="$BROWSER_RELEASE_FILE" \
    "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh" \
      >"$BROWSER_CONTRACT_LOG" 2>&1 &
  CONTRACT_PID=$!

  for _ in $(seq 1 2400); do
    if grep -q '^READY: isolated browser QA fixture$' \
      "$BROWSER_CONTRACT_LOG" 2>/dev/null; then
      break
    fi
    if ! kill -0 "$CONTRACT_PID" >/dev/null 2>&1; then
      echo "Browser QA API fixture exited before readiness" >&2
      tail -120 "$BROWSER_CONTRACT_LOG" >&2 || true
      return 1
    fi
    sleep 0.25
  done
  grep -Fq 'READY: isolated browser QA fixture' "$BROWSER_CONTRACT_LOG"

  BROWSER_API_BASE_URL="$(
    sed -n 's/^api_base_url=//p' "$BROWSER_CONTRACT_LOG" | tail -n 1
  )"
  BROWSER_DATABASE="$(
    sed -n 's/^database=//p' "$BROWSER_CONTRACT_LOG" | tail -n 1
  )"
  browser_ready_path="$(
    sed -n 's/^ready_manifest=//p' "$BROWSER_CONTRACT_LOG" | tail -n 1
  )"
  case "$browser_ready_path" in
    "$TMP_ROOT"/manaloom_server_contract_e2e_*/browser-ready.env) ;;
    *)
      echo "Browser QA child did not publish a valid readiness manifest" >&2
      return 1
      ;;
  esac
  BROWSER_CHILD_RUN_DIR="$(dirname -- "$browser_ready_path")"
  if [[ ! "$BROWSER_API_BASE_URL" =~ ^http://127[.]0[.]0[.]1:[0-9]+$ ||
        ! "$BROWSER_DATABASE" =~ ^manaloom_s1_api_[A-Za-z0-9_]+$ ]]; then
    echo "Browser QA child published invalid loopback coordinates" >&2
    return 1
  fi
  assert_port_loopback_listeners "${BROWSER_API_BASE_URL##*:}" \
    "browser QA API"

  FAILURE_STAGE="seed_browser_qa_player_and_decks"
  browser_seed_suffix="$(
    printf '%s' "$RUN_ID" | shasum -a 256 | awk '{print substr($1, 1, 12)}'
  )"
  browser_email="play-vs-ai-browser-$browser_seed_suffix@example.invalid"
  browser_username="play_vs_ai_browser_$browser_seed_suffix"
  browser_password="BrowserQA!$browser_seed_suffix"

  curl -fsS --max-time 30 \
    -H 'Content-Type: application/json' \
    -d "$(jq -cn \
      --arg email "$browser_email" \
      --arg username "$browser_username" \
      --arg password "$browser_password" \
      '{email: $email, username: $username, password: $password}')" \
    "$BROWSER_API_BASE_URL/auth/register" >/dev/null
  browser_token="$(
    curl -fsS --max-time 30 \
      -H 'Content-Type: application/json' \
      -d "$(jq -cn \
        --arg email "$browser_email" \
        --arg password "$browser_password" \
        '{email: $email, password: $password}')" \
      "$BROWSER_API_BASE_URL/auth/login" | jq -er '.token'
  )"
  [[ -n "$browser_token" ]]

  browser_human_deck_name="QA Web Isamaru $browser_seed_suffix"
  browser_ai_deck_name="QA Web Krenko $browser_seed_suffix"
  browser_human_deck_response="$(
    curl -fsS --max-time 30 \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $browser_token" \
      -d "$(jq -cn \
        --arg name "$browser_human_deck_name" \
        '{
          name: $name,
          format: "commander",
          is_public: false,
          cards: [
            {name: "Isamaru, Hound of Konda", quantity: 1, is_commander: true},
            {name: "Plains", quantity: 99, is_commander: false}
          ]
        }')" \
      "$BROWSER_API_BASE_URL/decks"
  )"
  browser_ai_deck_response="$(
    curl -fsS --max-time 30 \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $browser_token" \
      -d "$(jq -cn \
        --arg name "$browser_ai_deck_name" \
        '{
          name: $name,
          format: "commander",
          is_public: false,
          cards: [
            {name: "Krenko, Mob Boss", quantity: 1, is_commander: true},
            {name: "Mountain", quantity: 99, is_commander: false}
          ]
        }')" \
      "$BROWSER_API_BASE_URL/decks"
  )"
  jq -e '.deck_state == "validated" and .requires_review == false' \
    <<<"$browser_human_deck_response" >/dev/null
  jq -e '.deck_state == "validated" and .requires_review == false' \
    <<<"$browser_ai_deck_response" >/dev/null
  browser_human_deck_id="$(jq -er '.id' <<<"$browser_human_deck_response")"
  browser_ai_deck_id="$(jq -er '.id' <<<"$browser_ai_deck_response")"
  [[ "$browser_human_deck_id" =~ ^[0-9a-f-]{36}$ ]]
  [[ "$browser_ai_deck_id" =~ ^[0-9a-f-]{36}$ ]]

  FAILURE_STAGE="build_browser_qa_flutter_web"
  (
    cd "$APP_DIR"
    "$PINNED_FLUTTER_ROOT/bin/flutter" build web --release --no-pub \
      --base-href /app/ \
      --no-web-resources-cdn \
      --output "$BROWSER_WEB_BUILD_DIR" \
      --dart-define=API_BASE_URL=/api \
      --dart-define=PUBLIC_API_BASE_URL=/api \
      --dart-define=MANALOOM_VISUAL_FIXTURE_MODE=true \
      --dart-define=ENABLE_INTERACTIVE_BATTLE=true \
      --dart-define=DISABLE_FIREBASE_STARTUP=true \
      --dart-define=DISABLE_PUSH_INIT=true \
      --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true
  ) >"$BROWSER_BUILD_LOG" 2>&1
  [[ -s "$BROWSER_WEB_BUILD_DIR/main.dart.js" ]]
  BROWSER_BUNDLE_SHA="$(
    shasum -a 256 "$BROWSER_WEB_BUILD_DIR/main.dart.js" | awk '{print $1}'
  )"

  FAILURE_STAGE="serve_browser_qa_flutter_web"
  python3 "$APP_DIR/tool/serve_flutter_web_app.py" \
    --host 127.0.0.1 \
    --port "$BROWSER_WEB_PORT" \
    --build-dir "$BROWSER_WEB_BUILD_DIR" \
    --api-upstream "$BROWSER_API_BASE_URL" \
    --allow-loopback-http-api \
    >"$BROWSER_WEB_LOG" 2>&1 &
  WEB_PID=$!
  BROWSER_WEB_URL="http://127.0.0.1:$BROWSER_WEB_PORT/app/"
  browser_login_url="${BROWSER_WEB_URL}#/login?redirect=%2Fdecks%2F${browser_human_deck_id}%2Fplay-vs-ai"
  for _ in $(seq 1 160); do
    if curl -fsS --max-time 2 "$BROWSER_WEB_URL" >/dev/null 2>&1; then
      break
    fi
    if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
      echo "Flutter Web QA server exited before readiness" >&2
      tail -100 "$BROWSER_WEB_LOG" >&2 || true
      return 1
    fi
    sleep 0.25
  done
  curl -fsS --max-time 5 "$BROWSER_WEB_URL" >/dev/null
  assert_port_loopback_listeners "$BROWSER_WEB_PORT" "browser QA Web"

  browser_required_checkpoints_json="$(
    printf '%s\n' "${required_screenshots[@]}" |
      sed 's/[.]png$//' | jq -R . | jq -s .
  )"
  printf 'VISUAL_PROOF_CONTEXT %s\n' "$(
    jq -cn \
      --arg source_digest "$BROWSER_UI_SOURCE_DIGEST" \
      --argjson required_checkpoints "$browser_required_checkpoints_json" \
      '{
        schema_version: "manaloom_ui_runtime_context_v1",
        source_digest: $source_digest,
        surface: "play_vs_ai",
        profile: "web_play_vs_ai_1440x900",
        runtime: "flutter_web_release_loopback_api_pinned_xmage",
        target: "web_real_build",
        device_contract: "Codex in-app Chromium browser real Web build 1440x900",
        required_checkpoints: $required_checkpoints
      }'
  )" >"$BROWSER_RUNTIME_LOG"

  {
    printf 'MANALOOM_BROWSER_EMAIL=%q\n' "$browser_email"
    printf 'MANALOOM_BROWSER_PASSWORD=%q\n' "$browser_password"
  } >"$BROWSER_CREDENTIALS_FILE"
  chmod 600 "$BROWSER_CREDENTIALS_FILE"

  jq -n \
    --arg status "ready" \
    --arg scope "disposable_loopback_postgresql_api_pinned_xmage_flutter_web" \
    --arg web_url "$BROWSER_WEB_URL" \
    --arg login_url "$browser_login_url" \
    --arg credentials_file "$BROWSER_CREDENTIALS_FILE" \
    --arg subject_deck_id "$browser_human_deck_id" \
    --arg opponent_deck_id "$browser_ai_deck_id" \
    --arg subject_deck_name "$browser_human_deck_name" \
    --arg opponent_deck_name "$browser_ai_deck_name" \
    --arg capture_dir "$BROWSER_CAPTURE_DIR" \
    --arg completion_file "$BROWSER_DONE_FILE" \
    --arg capture_relative "$BROWSER_CAPTURE_RELATIVE" \
    --arg capture_manifest "$BROWSER_CAPTURE_MANIFEST" \
    --arg visual_review "$BROWSER_VISUAL_REVIEW" \
    --arg bundle_sha256 "$BROWSER_BUNDLE_SHA" \
    --arg ui_source_digest "$BROWSER_UI_SOURCE_DIGEST" \
    --arg engine_commit "$XMAGE_COMMIT" \
    --arg engine_patch_commit "$XMAGE_PATCH_COMMIT" \
    --argjson required_screenshots "$(printf '%s\n' "${required_screenshots[@]}" | jq -R . | jq -s .)" \
    '{
      status: $status,
      scope: $scope,
      production_coordinates_allowed: false,
      committed_capabilities_modified: false,
      web_url: $web_url,
      login_url: $login_url,
      credentials_file: $credentials_file,
      subject_deck_id: $subject_deck_id,
      opponent_deck_id: $opponent_deck_id,
      subject_deck_name: $subject_deck_name,
      opponent_deck_name: $opponent_deck_name,
      capture_dir: $capture_dir,
      capture_relative: $capture_relative,
      capture_manifest: $capture_manifest,
      visual_review: $visual_review,
      completion_file: $completion_file,
      required_screenshots: $required_screenshots,
      bundle_sha256: $bundle_sha256,
      ui_source_digest: $ui_source_digest,
      engine_commit: $engine_commit,
      engine_patch_commit: $engine_patch_commit,
      cleanup: "trap_registered"
    }' >"$BROWSER_READY_MANIFEST"

  printf 'READY: Play vs AI browser QA\n'
  printf 'browser_ready_manifest=%s\n' "$BROWSER_READY_MANIFEST"
  printf 'browser_web_url=%s\n' "$BROWSER_WEB_URL"
  printf 'browser_capture_dir=%s\n' "$BROWSER_CAPTURE_DIR"
  printf 'browser_completion_file=%s\n' "$BROWSER_DONE_FILE"

  FAILURE_STAGE="await_browser_qa_completion"
  browser_qa_deadline=$((SECONDS + 3600))
  while [[ ! -f "$BROWSER_DONE_FILE" ]]; do
    if ((SECONDS >= browser_qa_deadline)); then
      echo "Timed out after one hour awaiting browser QA completion" >&2
      return 1
    fi
    if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
      echo "Flutter Web QA server exited while awaiting browser proof" >&2
      return 1
    fi
    if ! kill -0 "$CONTRACT_PID" >/dev/null 2>&1; then
      echo "Browser QA API fixture exited while awaiting browser proof" >&2
      return 1
    fi
    sleep 0.25
  done

  FAILURE_STAGE="validate_browser_qa_attestation"
  jq -e \
    --arg source_digest "$BROWSER_UI_SOURCE_DIGEST" \
    '
    .status == "capture_complete"
    and .runtime_capture_complete == true
    and .reconnected_session == true
    and .replay_opened == true
    and .rematch_picker_opened == true
    and (.session_id | type == "string")
    and .source_digest == $source_digest
    and .viewport.width == 1440
    and .viewport.height == 900
    and .browser.name == "Codex in-app Chromium"
    and .browser.console_forbidden_entries == 0
    and .reviewer.kind == "agent"
    and (.reviewer.name | type == "string" and length > 0)
    and (.reviewed_at | type == "string" and test("T.*Z$"))
    and (.visual_thesis | type == "string" and length > 20)
    and (.content_plan | type == "string" and length > 20)
    and (.interaction_thesis | type == "string" and length > 20)
    and (.blocking_findings | type == "array" and length == 0)
    and (
      .criteria | keys | sort
    ) == ([
      "accessibility_visual",
      "attractiveness",
      "brand_and_mtg_identity",
      "color_and_contrast",
      "interaction_clarity",
      "responsive_fit",
      "spacing_and_density",
      "state_coverage",
      "typography",
      "visual_hierarchy"
    ] | sort)
    and all(
      .criteria[];
      .status == "pass"
      and (.note | type == "string" and length > 20)
    )
  ' "$BROWSER_DONE_FILE" >/dev/null
  browser_done_attestation="$(jq -c '{
    status,
    runtime_capture_complete,
    reconnected_session,
    replay_opened,
    rematch_picker_opened,
    session_id,
    source_digest,
    viewport,
    browser,
    reviewer,
    reviewed_at
  }' "$BROWSER_DONE_FILE")"

  for screenshot_name in "${required_screenshots[@]}"; do
    screenshot_path="$BROWSER_CAPTURE_DIR/$screenshot_name"
    if [[ ! -s "$screenshot_path" ]]; then
      echo "Required browser screenshot is missing: $screenshot_name" >&2
      return 1
    fi
  done

  FAILURE_STAGE="index_browser_qa_runtime_evidence"
  current_ui_source_digest="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"
  if [[ "$current_ui_source_digest" != "$BROWSER_UI_SOURCE_DIGEST" ]]; then
    echo "UI source changed while browser evidence was being captured" >&2
    return 1
  fi
  printf 'BROWSER_RUNTIME_ATTESTATION %s\n' "$browser_done_attestation" \
    >>"$BROWSER_RUNTIME_LOG"
  (
    cd "$APP_DIR"
    "$PINNED_DART_BIN" run tool/ui_runtime_evidence.dart \
      validate-directory \
      --screenshots "$BROWSER_CAPTURE_DIR"
    "$PINNED_DART_BIN" run tool/ui_runtime_evidence.dart \
      index-directory \
      --repo-root "$ROOT_DIR" \
      --screenshots "$BROWSER_CAPTURE_RELATIVE" \
      --log "$BROWSER_RUNTIME_LOG" \
      --manifest "$BROWSER_CAPTURE_RELATIVE/capture-manifest.json" \
      --source-digest "$BROWSER_UI_SOURCE_DIGEST" \
      --surface play_vs_ai \
      --profile web_play_vs_ai_1440x900 \
      --runtime flutter_web_release_loopback_api_pinned_xmage \
      --target web_real_build \
      --device-contract \
        "Codex in-app Chromium browser real Web build 1440x900"
  ) >"$RUN_DIR/browser-runtime-evidence.log" 2>&1
  jq -e \
    --arg source_digest "$BROWSER_UI_SOURCE_DIGEST" \
    '.status == "PASS_RUNTIME"
      and .source_digest == $source_digest
      and .checkpoint_count == 9
      and (.screenshots | length == 9)
      and all(.screenshots[]; .width == 1440 and .height == 900)
      and (([.screenshots[].sha256] | unique | length) == 9)' \
    "$BROWSER_CAPTURE_MANIFEST" >/dev/null
  jq '.screenshots' "$BROWSER_CAPTURE_MANIFEST" \
    >"$BROWSER_SCREENSHOT_DIGESTS"
  browser_capture_manifest_sha="$(
    shasum -a 256 "$BROWSER_CAPTURE_MANIFEST" | awk '{print $1}'
  )"

  jq -n \
    --slurpfile capture "$BROWSER_CAPTURE_MANIFEST" \
    --slurpfile attestation "$BROWSER_DONE_FILE" \
    --arg capture_manifest_sha256 "$browser_capture_manifest_sha" \
    '($capture[0]) as $capture
    | ($attestation[0]) as $attestation
    | {
        schema_version: "manaloom_ui_surface_visual_review_v1",
        status: "PASS_VISUAL_REVIEWED",
        scope: "focal_play_vs_ai_real_xmage",
        source_digest: $capture.source_digest,
        surface: $capture.surface,
        profile: $capture.profile,
        reviewed_at: $attestation.reviewed_at,
        reviewer: $attestation.reviewer,
        visual_thesis: $attestation.visual_thesis,
        content_plan: $attestation.content_plan,
        interaction_thesis: $attestation.interaction_thesis,
        criteria: $attestation.criteria,
        reviewed_capture_manifest_sha256: $capture_manifest_sha256,
        reviewed_screenshot_count: $capture.checkpoint_count,
        reviewed_checkpoints: $capture.required_checkpoints,
        reviewed_screenshot_sha256: [$capture.screenshots[].sha256],
        blocking_findings: $attestation.blocking_findings,
        release_scope: {
          overall_ui_proof_claimed: false,
          committed_capability_promoted: false,
          talkback_human_credit: false,
          hardware_keyboard_credit: false
        }
      }' >"$BROWSER_VISUAL_REVIEW"
  browser_visual_review_sha="$(
    shasum -a 256 "$BROWSER_VISUAL_REVIEW" | awk '{print $1}'
  )"
  jq -e \
    --arg source_digest "$BROWSER_UI_SOURCE_DIGEST" \
    --arg manifest_sha "$browser_capture_manifest_sha" \
    '.status == "PASS_VISUAL_REVIEWED"
      and .source_digest == $source_digest
      and .reviewed_capture_manifest_sha256 == $manifest_sha
      and .reviewed_screenshot_count == 9
      and (.reviewed_checkpoints | length == 9)
      and (.reviewed_screenshot_sha256 | length == 9)
      and (.blocking_findings | length == 0)
      and .release_scope.overall_ui_proof_claimed == false' \
    "$BROWSER_VISUAL_REVIEW" >/dev/null

  FAILURE_STAGE="validate_browser_qa_real_session"
  browser_session_id="$(
    PGPASSWORD="$DB_PASS" psql -X -A -t \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$BROWSER_DATABASE" \
      -c "SELECT id FROM interactive_battle_sessions
          WHERE deck_a_id = '$browser_human_deck_id'::uuid
          ORDER BY created_at DESC, id DESC LIMIT 1" |
      tr -d '[:space:]'
  )"
  [[ "$browser_session_id" =~ ^[0-9a-f-]{36}$ ]]
  [[ "$(jq -r '.session_id' "$BROWSER_DONE_FILE")" == "$browser_session_id" ]]

  browser_session_response="$(
    curl -fsS --max-time 30 \
      -H "Authorization: Bearer $browser_token" \
      "$BROWSER_API_BASE_URL/ai/battle/sessions/$browser_session_id"
  )"
  jq -e \
    --arg commit "$XMAGE_COMMIT" \
    --arg build "$EXPECTED_BUILD" \
    '.id != null
      and .status == "conceded"
      and .terminal == true
      and .terminal_reason == "user_conceded"
      and .engine == "xmage"
      and .engine_commit == $commit
      and .engine_build == $build
      and (.replay_id | type == "string")' \
    <<<"$browser_session_response" >/dev/null
  browser_replay_id="$(jq -er '.replay_id' <<<"$browser_session_response")"
  browser_replay_response="$(
    curl -fsS --max-time 30 \
      -H "Authorization: Bearer $browser_token" \
      "$BROWSER_API_BASE_URL/decks/$browser_human_deck_id/battle-replays/$browser_replay_id"
  )"
  browser_replay_evidence="$(
    jq -c \
      --arg commit "$XMAGE_COMMIT" \
      --arg patch "$XMAGE_PATCH_COMMIT" \
      --arg build "$EXPECTED_BUILD" \
      '{
        engine_identity: (
          .replay.engine == "xmage"
          and .replay.engine_commit == $commit
          and .replay.engine_patch_commit == $patch
          and .replay.engine_build == $build
        ),
        canonical_rules_execution: (
          .replay.simulation_contract.canonical_rules_execution == true
        ),
        plains_entered: any(
          .replay.events[]?;
          .action == "battlefield_entry" and .card_name == "Plains"
        ),
        plains_tapped: any(
          .replay.events[]?;
          .action == "tap_change"
          and .card_name == "Plains"
          and .to == true
        ),
        isamaru_cast: any(
          .replay.events[]?;
          .action == "stack_entry"
          and .card_name == "Isamaru, Hound of Konda"
        ),
        isamaru_entered: any(
          .replay.events[]?;
          .action == "battlefield_entry"
          and .card_name == "Isamaru, Hound of Konda"
        ),
        isamaru_attacked: any(
          .replay.events[]?;
          .action == "attacker_declared"
          and .card_name == "Isamaru, Hound of Konda"
        ),
        combat_damage: any(.replay.events[]?; .action == "life_change"),
        decision_kinds: ([.replay.decision_trace[]?.decision_type] | unique)
      }' <<<"$browser_replay_response"
  )"
  jq -e '
    .engine_identity == true
    and .canonical_rules_execution == true
    and .plains_entered == true
    and .plains_tapped == true
    and .isamaru_cast == true
    and .isamaru_entered == true
    and .isamaru_attacked == true
    and .combat_damage == true
    and (.decision_kinds | index("mulligan") != null)
    and (.decision_kinds | index("main_action") != null)
    and (.decision_kinds | index("mana") != null)
  ' <<<"$browser_replay_evidence" >/dev/null

  browser_record_counts="$(
    PGPASSWORD="$DB_PASS" psql -X -A -t -F '|' \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$BROWSER_DATABASE" \
      -c "SELECT
            COUNT(*) FILTER (WHERE record_kind = 'action_submitted'),
            COUNT(*) FILTER (WHERE record_kind = 'prompt_opened'),
            COUNT(*)
          FROM interactive_battle_records
          WHERE session_id = '$browser_session_id'::uuid" |
      tr -d '[:space:]'
  )"
  IFS='|' read -r browser_action_records browser_prompt_records \
    browser_record_total <<<"$browser_record_counts"
  [[ "$browser_action_records" =~ ^[0-9]+$ ]]
  [[ "$browser_prompt_records" =~ ^[0-9]+$ ]]
  [[ "$browser_record_total" =~ ^[0-9]+$ ]]
  ((browser_action_records >= 8))
  ((browser_prompt_records >= 8))

  browser_session_requests="$(
    grep -c "/api/ai/battle/sessions/$browser_session_id" \
      "$BROWSER_WEB_LOG" 2>/dev/null || true
  )"
  browser_replay_requests="$(
    grep -c "/api/decks/$browser_human_deck_id/battle-replays/$browser_replay_id" \
      "$BROWSER_WEB_LOG" 2>/dev/null || true
  )"
  ((browser_session_requests >= 2))
  ((browser_replay_requests >= 1))

  BROWSER_EVIDENCE_JSON="$(
    jq -n \
      --arg schema_version "play_vs_ai_browser_qa_evidence_v1" \
      --arg session_id "$browser_session_id" \
      --arg replay_id "$browser_replay_id" \
      --arg route "/decks/$browser_human_deck_id/play-vs-ai/$browser_session_id" \
      --arg bundle_sha256 "$BROWSER_BUNDLE_SHA" \
      --arg ui_source_digest "$BROWSER_UI_SOURCE_DIGEST" \
      --arg capture_manifest "$BROWSER_CAPTURE_RELATIVE/capture-manifest.json" \
      --arg capture_manifest_sha256 "$browser_capture_manifest_sha" \
      --arg visual_review "$BROWSER_CAPTURE_RELATIVE/visual-review.json" \
      --arg visual_review_sha256 "$browser_visual_review_sha" \
      --argjson action_records "$browser_action_records" \
      --argjson prompt_records "$browser_prompt_records" \
      --argjson record_total "$browser_record_total" \
      --argjson session_requests "$browser_session_requests" \
      --argjson replay_requests "$browser_replay_requests" \
      --argjson screenshots "$(cat "$BROWSER_SCREENSHOT_DIGESTS")" \
      --argjson replay_evidence "$browser_replay_evidence" \
      --argjson manual_attestation "$browser_done_attestation" \
      '{
        schema_version: $schema_version,
        session_id: $session_id,
        replay_id: $replay_id,
        route: $route,
        bundle_sha256: $bundle_sha256,
        ui_source_digest: $ui_source_digest,
        evidence_levels: [
          "PASS_AUTOMATED",
          "PASS_RUNTIME",
          "PASS_VISUAL_REVIEWED"
        ],
        capture_manifest: {
          path: $capture_manifest,
          sha256: $capture_manifest_sha256
        },
        visual_review: {
          path: $visual_review,
          sha256: $visual_review_sha256,
          scope: "focal_play_vs_ai_real_xmage"
        },
        browser_session_request_count: $session_requests,
        browser_replay_request_count: $replay_requests,
        database: {
          action_submitted_records: $action_records,
          prompt_opened_records: $prompt_records,
          total_records: $record_total
        },
        replay: $replay_evidence,
        screenshots: $screenshots,
        manual_runtime_attestation: $manual_attestation,
        real_flutter_web_build: true,
        real_loopback_api: true,
        real_disposable_postgresql: true,
        real_pinned_xmage: true,
        production_mutated: false,
        overall_ui_proof_claimed: false
      }'
  )"

  FAILURE_STAGE="cleanup_browser_qa_fixture"
  terminate_owned_pid "$WEB_PID"
  WEB_PID=""
  printf 'complete\n' >"$BROWSER_RELEASE_FILE"
  set +e
  wait "$CONTRACT_PID"
  browser_contract_status=$?
  set -e
  CONTRACT_PID=""
  if [[ "$browser_contract_status" != "0" ]]; then
    echo "Browser QA API fixture did not finish through its completion contract" >&2
    return 1
  fi
  grep -Fq 'PASS: isolated browser QA fixture completed' \
    "$BROWSER_CONTRACT_LOG"
  grep -Fq 'result=pass' "$BROWSER_CHILD_SUMMARY"
  grep -Fq 'browser_completion=pass' "$BROWSER_CHILD_SUMMARY"
  browser_child_cleanup_status="$(
    sed -n 's/^result=//p' "$BROWSER_CHILD_CLEANUP" 2>/dev/null | tail -n 1
  )"
  if [[ "$browser_child_cleanup_status" != "pass" ]]; then
    echo "Browser QA API fixture did not prove clean shutdown" >&2
    return 1
  fi
  grep -Fq 'database_remaining=0' "$BROWSER_CHILD_CLEANUP"
  grep -Fq 'api_listeners=0' "$BROWSER_CHILD_CLEANUP"
  grep -Fq 'email_fixture_listeners=0' "$BROWSER_CHILD_CLEANUP"
  grep -Fq 'forced_kill_used=0' "$BROWSER_CHILD_CLEANUP"
  [[ "$(listener_count "$BROWSER_WEB_PORT")" == "0" ]]
  BROWSER_CHILD_CLEANUP_RESULT="pass"
  BROWSER_QA_RESULT="pass"
}

FAILURE_STAGE="select_loopback_ports"
read -r XMAGE_PORT XMAGE_SECONDARY_PORT BATCH_PORT INTERACTIVE_PORT \
  SELECTED_POSTGRES_PORT BROWSER_WEB_PORT \
  < <(select_ports)

if [[ "$POSTGRES_MODE" == "owned_disposable" ]]; then
  FAILURE_STAGE="start_owned_disposable_postgresql"
  DB_PORT="$SELECTED_POSTGRES_PORT"
  initdb \
    --pgdata="$POSTGRES_DATA_DIR" \
    --username="$DB_USER" \
    --auth-local=trust \
    --auth-host=trust \
    --encoding=UTF8 \
    --no-locale >>"$POSTGRES_LOG" 2>&1
  POSTGRES_OWNED=1
  pg_ctl \
    -D "$POSTGRES_DATA_DIR" \
    -l "$POSTGRES_SERVER_LOG" \
    -o "-h 127.0.0.1 -p $DB_PORT -k /tmp" \
    -w start >>"$POSTGRES_LOG" 2>&1
fi
pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1 || {
  echo "Disposable loopback PostgreSQL is not ready" >&2
  exit 1
}
PGPASSWORD="$DB_PASS" psql -X -A -t \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres \
  -c 'SELECT 1' >/dev/null
assert_port_loopback_listeners "$DB_PORT" "disposable PostgreSQL"

FAILURE_STAGE="audit_governed_xmage_patch"
python3 \
  "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts/xmage_governed_patch_audit.py" \
  --repo-root "$ROOT_DIR" \
  --require-deployable \
  --output "$GOVERNED_PATCH_AUDIT" >/dev/null
jq -e '.status == "pass" and .deployment_allowed == true' \
  "$GOVERNED_PATCH_AUDIT" >/dev/null

FAILURE_STAGE="bootstrap_pinned_xmage"
if ! RUNTIME_ZIP="$("$BOOTSTRAP" 2>"$BOOTSTRAP_LOG")"; then
  tail -100 "$BOOTSTRAP_LOG" >&2 || true
  exit 1
fi
[[ -s "$RUNTIME_ZIP" ]] || {
  echo "Pinned XMage bootstrap did not return an assembly ZIP" >&2
  exit 1
}
RUNTIME_ZIP_SHA="$(shasum -a 256 "$RUNTIME_ZIP" | awk '{print $1}')"
unzip -tq "$RUNTIME_ZIP" >/dev/null
mkdir -p "$RUNTIME_DIR"
unzip -q "$RUNTIME_ZIP" -d "$RUNTIME_DIR"

FAILURE_STAGE="configure_loopback_xmage"
perl -0pi -e \
  "s/serverAddress=\"[^\"]*\"/serverAddress=\"127.0.0.1\"/; s/port=\"[0-9]*\"/port=\"$XMAGE_PORT\"/; s/secondaryBindPort=\"-?[0-9]*\"/secondaryBindPort=\"$XMAGE_SECONDARY_PORT\"/" \
  "$RUNTIME_DIR/config/config.xml"
grep -Fq 'serverAddress="127.0.0.1"' "$RUNTIME_DIR/config/config.xml"
grep -Fq "port=\"$XMAGE_PORT\"" "$RUNTIME_DIR/config/config.xml"
grep -Fq "secondaryBindPort=\"$XMAGE_SECONDARY_PORT\"" \
  "$RUNTIME_DIR/config/config.xml"

FAILURE_STAGE="start_pinned_xmage_server"
(
  cd "$RUNTIME_DIR"
  exec java \
    --add-opens java.base/java.io=ALL-UNNAMED \
    -Dh2.bindAddress=127.0.0.1 \
    -Djava.awt.headless=true \
    -Djava.net.preferIPv4Stack=true \
    -Dxmage.testMode=true \
    -Xms256m -Xmx2g \
    -jar "lib/mage-server-$XMAGE_VERSION.jar"
) >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
wait_for_listener "$SERVER_PID" "$XMAGE_PORT" "XMage server"
wait_for_listener "$SERVER_PID" "$XMAGE_SECONDARY_PORT" \
  "XMage secondary transport"
assert_pid_loopback_listeners "$SERVER_PID" "XMage server/JBoss/H2"

FAILURE_STAGE="natural_full_match_spike"
(
  cd "$SIDECAR_DIR"
  XMAGE_SERVER_HOST=127.0.0.1 \
  XMAGE_SERVER_PORT="$XMAGE_PORT" \
  BL7_RUNTIME_RUNS=1 \
  BL7_RUNTIME_TIMEOUT_PROBE=false \
  BL7_MATCH_TIMEOUT_MS=240000 \
    "$SIDECAR_DIR/bin/human_vs_ai_runtime_spike.sh"
) >"$SPIKE_LOG" 2>&1
grep -Fq 'BL7_RUNTIME_RUNS_COMPLETED=1' "$SPIKE_LOG"
grep -Fq 'BL7_RUNTIME_RUN_PASS=1' "$SPIKE_LOG"
grep -Fq 'BL7_RUNTIME_HUMAN_MATCH_COMPLETED=true' "$SPIKE_LOG"
grep -Fq 'BL7_RUNTIME_HIDDEN_INFORMATION_LEAK=false' "$SPIKE_LOG"
grep -Fq 'BL7_RUNTIME_DEADLOCKS=0' "$SPIKE_LOG"
grep -Fq 'BL7_RUNTIME_SPIKE_STATUS=PASS' "$SPIKE_LOG"
assert_pid_loopback_listeners "$SERVER_PID" "XMage server after natural match"

FAILURE_STAGE="build_current_sidecar"
(
  cd "$SIDECAR_DIR"
  mvn -B -Dstyle.color=never -DskipTests package
) >"$SIDECAR_BUILD_LOG" 2>&1
SIDECAR_JAR="$SIDECAR_DIR/target/xmage-sidecar.jar"
[[ -s "$SIDECAR_JAR" ]]
SIDECAR_JAR_SHA="$(shasum -a 256 "$SIDECAR_JAR" | awk '{print $1}')"

FAILURE_STAGE="start_distinct_sidecars"
(
  cd "$RUNTIME_DIR"
  exec env \
    PORT="$BATCH_PORT" \
    XMAGE_SIDECAR_HTTP_HOST=127.0.0.1 \
    XMAGE_SERVER_HOST=127.0.0.1 \
    XMAGE_SERVER_PORT="$XMAGE_PORT" \
    XMAGE_RUNTIME_MODE=batch \
    java \
      --add-opens java.base/java.io=ALL-UNNAMED \
      -Dh2.bindAddress=127.0.0.1 \
      -Djava.awt.headless=true \
      -Djava.net.preferIPv4Stack=true \
      -Xms128m -Xmx1g \
      -jar "$SIDECAR_JAR"
) >"$BATCH_LOG" 2>&1 &
BATCH_PID=$!
wait_for_health "$BATCH_PID" "$BATCH_PORT" "$BATCH_HEALTH" \
  "XMage batch sidecar"

(
  cd "$RUNTIME_DIR"
  exec env \
    PORT="$INTERACTIVE_PORT" \
    XMAGE_SIDECAR_HTTP_HOST=127.0.0.1 \
    XMAGE_SERVER_HOST=127.0.0.1 \
    XMAGE_SERVER_PORT="$XMAGE_PORT" \
    XMAGE_RUNTIME_MODE=interactive \
    XMAGE_INTERACTIVE_MAX_ACTIVE=4 \
    java \
      --add-opens java.base/java.io=ALL-UNNAMED \
      -Dh2.bindAddress=127.0.0.1 \
      -Djava.awt.headless=true \
      -Djava.net.preferIPv4Stack=true \
      -Xms128m -Xmx1g \
      -jar "$SIDECAR_JAR"
) >"$INTERACTIVE_LOG" 2>&1 &
INTERACTIVE_PID=$!
wait_for_health "$INTERACTIVE_PID" "$INTERACTIVE_PORT" \
  "$INTERACTIVE_HEALTH" "XMage interactive sidecar"

jq -e \
  --arg commit "$XMAGE_COMMIT" \
  --arg patch "$XMAGE_PATCH_COMMIT" \
  --arg version "$XMAGE_VERSION" \
  --arg build "$EXPECTED_BUILD" \
  --argjson xmage_port "$XMAGE_PORT" \
  '.status == "ok"
    and .engine == "xmage"
    and .engine_version == $version
    and .engine_commit == $commit
    and .engine_patch_commit == $patch
    and .sidecar_build_identity == $build
    and .http_bind_host == "127.0.0.1"
    and .xmage_host == "127.0.0.1"
    and .xmage_port == $xmage_port
    and .catalog_ready == true
    and .indexed_names > 0
    and .runtime_mode == "batch"
    and .batch_simulation_available == true' \
  "$BATCH_HEALTH" >/dev/null
jq -e \
  --arg commit "$XMAGE_COMMIT" \
  --arg patch "$XMAGE_PATCH_COMMIT" \
  --arg version "$XMAGE_VERSION" \
  --arg build "$EXPECTED_BUILD" \
  --argjson xmage_port "$XMAGE_PORT" \
  '.status == "ok"
    and .engine == "xmage"
    and .engine_version == $version
    and .engine_commit == $commit
    and .engine_patch_commit == $patch
    and .sidecar_build_identity == $build
    and .http_bind_host == "127.0.0.1"
    and .xmage_host == "127.0.0.1"
    and .xmage_port == $xmage_port
    and .catalog_ready == true
    and .indexed_names > 0
    and .runtime_mode == "interactive"
    and .batch_simulation_available == false
    and .interactive_battle.maximum_active == 4
    and .interactive_battle.active == 0' \
  "$INTERACTIVE_HEALTH" >/dev/null
[[ "$(jq -r '.sidecar_process_id' "$BATCH_HEALTH")" != \
   "$(jq -r '.sidecar_process_id' "$INTERACTIVE_HEALTH")" ]]
assert_pid_loopback_listeners "$BATCH_PID" "XMage batch sidecar/H2"
assert_pid_loopback_listeners "$INTERACTIVE_PID" \
  "XMage interactive sidecar/H2"
assert_pid_loopback_listeners "$SERVER_PID" "XMage server/JBoss/H2"

FAILURE_STAGE="create_disposable_capability_policy"
jq '
  .policy_version = (.policy_version + ".isolated_play_vs_ai_e2e")
  | .implementation_status = "experimental_guarded"
  | .live_verified_as_of = null
  | .capabilities |= with_entries(
      .key as $key
      | if ([
          "account_registration",
          "decks_private",
          "battle_batch",
          "battle_coach"
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
' "$ROOT_DIR/server/config/release_capabilities.json" >"$CAPABILITY_POLICY"
CAPABILITY_POLICY_SHA="$(
  shasum -a 256 "$CAPABILITY_POLICY" | awk '{print $1}'
)"

FAILURE_STAGE="real_api_postgresql_xmage_contract"
env \
  DB_HOST="$DB_HOST" \
  DB_PORT="$DB_PORT" \
  DB_USER="$DB_USER" \
  DB_PASS="$DB_PASS" \
  INTERACTIVE_BATTLE_ENABLED=true \
  XMAGE_SIDECAR_URL="http://127.0.0.1:$BATCH_PORT" \
  XMAGE_INTERACTIVE_SIDECAR_URL="http://127.0.0.1:$INTERACTIVE_PORT" \
  XMAGE_EXPECTED_COMMIT="$XMAGE_COMMIT" \
  XMAGE_EXPECTED_PATCH_COMMIT="$XMAGE_PATCH_COMMIT" \
  XMAGE_EXPECTED_VERSION="$XMAGE_VERSION" \
  MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE="$CAPABILITY_POLICY" \
  MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY \
  MANALOOM_CONFIRM_POSTGRES_WRITES="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
  MANALOOM_CONFIRM_LIVE_MUTATIONS="$MANALOOM_EXPLICIT_APPROVAL_PHRASE" \
  MANALOOM_PLAY_VS_AI_REAL_XMAGE_E2E=1 \
  MANALOOM_ISOLATED_E2E_RECEIPT_DIR="$CHILD_RECEIPT_DIR" \
  "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh" \
    test/play_vs_ai_real_xmage_e2e_test.dart \
    >"$CONTRACT_LOG" 2>&1 &
CONTRACT_PID=$!
set +e
wait "$CONTRACT_PID"
contract_status=$?
set -e
CONTRACT_PID=""
if [[ "$contract_status" != 0 ]]; then
  tail -160 "$CONTRACT_LOG" >&2 || true
  exit "$contract_status"
fi
grep -Fq 'PASS: isolated server contract E2E' "$CONTRACT_LOG"
FAILURE_STAGE="validate_play_vs_ai_machine_evidence"
evidence_count="$(grep -c '^PLAY_VS_AI_E2E_EVIDENCE=' "$CONTRACT_LOG")"
if [[ "$evidence_count" != "1" ]]; then
  echo "Expected exactly one Play vs AI evidence record; got $evidence_count" >&2
  exit 1
fi
PLAY_EVIDENCE_JSON="$(
  sed -n 's/^PLAY_VS_AI_E2E_EVIDENCE=//p' "$CONTRACT_LOG"
)"
jq -e \
  --arg commit "$XMAGE_COMMIT" \
  --arg patch "$XMAGE_PATCH_COMMIT" \
  '.schema_version == "play_vs_ai_e2e_evidence_v1"
    and .engine_commit == $commit
    and .engine_patch_commit == $patch
    and .ai_profile == "computer_mad"
    and .private_hand_visible == true
    and .opponent_hand_protected == true
    and .ai_land_played == true
    and .card_first_options == true
    and .land_played == true
    and .mana_source_tapped == true
    and .commander_cast == true
    and .pass_priority == true
    and .combat_damage == true
    and .canonical_replay == true
    and .idempotent_action_submission_count == 1' \
  <<<"$PLAY_EVIDENCE_JSON" >/dev/null

FAILURE_STAGE="validate_server_contract_cleanup_receipts"
published_child_summary="$(
  sed -n 's/^summary=//p' "$CONTRACT_LOG" | tail -n 1
)"
case "$published_child_summary" in
  "$TMP_ROOT"/manaloom_server_contract_e2e_*/summary.txt) ;;
  *)
    echo "Child E2E did not publish a valid isolated summary path" >&2
    exit 1
    ;;
esac
CHILD_RUN_DIR="$(dirname -- "$published_child_summary")"
if [[ ! -s "$CHILD_SUMMARY" || ! -s "$CHILD_CLEANUP" ]]; then
  echo "Child E2E did not copy both cleanup receipts" >&2
  exit 1
fi
published_summary_sha="$(
  sed -n 's/^summary_sha256=//p' "$CONTRACT_LOG" | tail -n 1
)"
receipt_summary_sha="$(
  shasum -a 256 "$CHILD_SUMMARY" | awk '{print $1}'
)"
if [[ ! "$published_summary_sha" =~ ^[0-9a-f]{64}$ ||
      "$receipt_summary_sha" != "$published_summary_sha" ]]; then
  echo "Child E2E summary receipt digest does not match" >&2
  exit 1
fi
grep -Fq 'result=pass' "$CHILD_SUMMARY"
grep -Fq 'result=pass' "$CHILD_CLEANUP"
grep -Fq 'database_remaining=0' "$CHILD_CLEANUP"
grep -Fq 'api_listeners=0' "$CHILD_CLEANUP"
grep -Fq 'email_fixture_listeners=0' "$CHILD_CLEANUP"
grep -Fq 'forced_kill_used=0' "$CHILD_CLEANUP"
CHILD_CLEANUP_RESULT="pass"

if [[ "$BROWSER_QA_MODE" == "1" ]]; then
  run_browser_qa
fi

FAILURE_STAGE="final_runtime_containment"
assert_pid_loopback_listeners "$BATCH_PID" "XMage batch sidecar/H2"
assert_pid_loopback_listeners "$INTERACTIVE_PID" \
  "XMage interactive sidecar/H2"
assert_pid_loopback_listeners "$SERVER_PID" "XMage server/JBoss/H2"

FAILURE_STAGE="complete"
WORKFLOW_PASS=1
