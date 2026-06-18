#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
WORKSPACE_ROOT="${HERMES_WORKSPACE_ROOT:-$HERMES_HOME/workspace}"
REPO_DIR="${HERMES_REPO_DIR:-$WORKSPACE_ROOT/mtgia}"
REPO_URL="${HERMES_REPO_URL:-https://github.com/softwarePredador/mtgia.git}"
REPO_REF="${HERMES_REPO_REF:-master}"
REPO_AUTO_SYNC="${HERMES_REPO_AUTO_SYNC:-0}"
FLUTTER_BIN="/opt/tools/flutter/bin"
DART_BIN="/opt/tools/flutter/bin/cache/dart-sdk/bin"
PUB_CACHE_BIN="/root/.pub-cache/bin"
HERMES_BIN="/opt/hermes/bin"
HERMES_VENV_BIN="/opt/hermes/.venv/bin"
HERMES_PROVIDER="${HERMES_PROVIDER:-openai-api}"
HERMES_STATE_ROOT="${HERMES_STATE_ROOT:-$HERMES_HOME}"
HERMES_CRON_SCRIPTS_DIR="${HERMES_CRON_SCRIPTS_DIR:-$HERMES_STATE_ROOT/scripts}"
HERMES_CRON_JOBS_JSON="${HERMES_CRON_JOBS_JSON:-$HERMES_STATE_ROOT/cron/jobs.json}"
LOG_DIR="${HERMES_LAB_LOG_DIR:-$HERMES_HOME/logs}"
RUNTIME_ARTIFACT_DIR="${HERMES_LAB_RUNTIME_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_lab_runtime}"
BOOTSTRAP_REPORT_DIR="${HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_cron_bootstrap}"
BOOTSTRAP_REPORT_PATH="$BOOTSTRAP_REPORT_DIR/latest_bootstrap_report.json"
BOOTSTRAP_LOG_PATH="$LOG_DIR/hermes_lab_bootstrap.log"
STARTUP_STATUS_PATH="${HERMES_LAB_STARTUP_STATUS_FILE:-$RUNTIME_ARTIFACT_DIR/startup_status.json}"

mkdir -p \
  "$HERMES_HOME" \
  "$WORKSPACE_ROOT" \
  "$HERMES_HOME/.config" \
  "$LOG_DIR" \
  "$RUNTIME_ARTIFACT_DIR" \
  "$HERMES_CRON_SCRIPTS_DIR" \
  "$(dirname "$HERMES_CRON_JOBS_JSON")"

write_runtime_status() {
  local phase="$1"
  local status="$2"
  local message="${3:-}"
  python3 - "$STARTUP_STATUS_PATH" "$phase" "$status" "$message" "$REPO_DIR" "$REPO_REF" "$BOOTSTRAP_REPORT_PATH" "$BOOTSTRAP_LOG_PATH" <<'PY'
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

status_path = Path(sys.argv[1])
payload = {
    "generated_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "phase": sys.argv[2],
    "status": sys.argv[3],
    "message": sys.argv[4],
    "repo_dir": sys.argv[5],
    "repo_ref": sys.argv[6],
    "bootstrap_report_path": sys.argv[7],
    "bootstrap_log_path": sys.argv[8],
}
status_path.parent.mkdir(parents=True, exist_ok=True)
status_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
print("HERMES_LAB_RUNTIME_STATUS", json.dumps(payload, sort_keys=True))
PY
}

write_runtime_status "entrypoint" "starting" "initializing hermes-lab runtime"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  git clone --branch "$REPO_REF" --single-branch "$REPO_URL" "$REPO_DIR"
else
  git -C "$REPO_DIR" fetch --all --prune || true
  if [[ "$REPO_AUTO_SYNC" == "1" ]]; then
    git -C "$REPO_DIR" checkout "$REPO_REF"
    git -C "$REPO_DIR" pull --ff-only origin "$REPO_REF"
  fi
fi

write_runtime_status "workspace" "ready" "repository prepared"

cat > "$HERMES_HOME/.profile" <<EOF
export PATH=$HERMES_BIN:$HERMES_VENV_BIN:$FLUTTER_BIN:$DART_BIN:$PUB_CACHE_BIN:\$PATH
export HERMES_HOME=$HERMES_HOME
export MANALOOM_WORKSPACE=$REPO_DIR
export HERMES_REPO_DIR=$REPO_DIR
export HERMES_STATE_ROOT=$HERMES_STATE_ROOT
export HERMES_CRON_SCRIPTS_DIR=$HERMES_CRON_SCRIPTS_DIR
export HERMES_CRON_JOBS_JSON=$HERMES_CRON_JOBS_JSON
export HERMES_PROVIDER=$HERMES_PROVIDER
EOF

touch "$HERMES_HOME/.env"

upsert_env_file() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    return 0
  fi
  python3 - "$HERMES_HOME/.env" "$key" "$value" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
lines = path.read_text().splitlines() if path.exists() else []
prefix = f"{key}="
updated = False
out = []
for line in lines:
    if line.startswith(prefix):
        out.append(f"{key}={value}")
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(f"{key}={value}")
path.write_text("\n".join(out).rstrip() + "\n")
PY
}

upsert_env_file "OPENAI_API_KEY" "${OPENAI_API_KEY:-}"
upsert_env_file "API_SERVER_KEY" "${API_SERVER_KEY:-}"

export HOME="$HERMES_HOME"
export PATH="$HERMES_BIN:$HERMES_VENV_BIN:$FLUTTER_BIN:$DART_BIN:$PUB_CACHE_BIN:$PATH"
export MANALOOM_REPO="$REPO_DIR"
export HERMES_STATE_ROOT
export HERMES_CRON_SCRIPTS_DIR
export HERMES_CRON_JOBS_JSON
export HERMES_PROVIDER
unset HERMES_INFERENCE_PROVIDER

cd "$HERMES_HOME"

if [[ -n "${HERMES_MODEL:-}" ]]; then
  hermes config set model.default "$HERMES_MODEL" >/dev/null 2>&1 || true
fi
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  hermes config set model.provider "$HERMES_PROVIDER" >/dev/null 2>&1 || true
  hermes config set model.base_url "${OPENAI_BASE_URL:-https://api.openai.com/v1}" >/dev/null 2>&1 || true
fi

if [[ "${HERMES_CRON_BOOTSTRAP:-1}" == "1" ]]; then
  write_runtime_status "bootstrap" "starting" "running hermes cron bootstrap"
  if ! python3 /opt/bootstrap/hermes_lab_cron_bootstrap.py 2>&1 | tee -a "$BOOTSTRAP_LOG_PATH"; then
    failure_message="hermes cron bootstrap failed; see $BOOTSTRAP_LOG_PATH"
    if [[ -f "$BOOTSTRAP_REPORT_PATH" ]]; then
      failure_message="$failure_message and $BOOTSTRAP_REPORT_PATH"
    fi
    write_runtime_status "bootstrap" "failed" "$failure_message"
    if [[ "${HERMES_CRON_BOOTSTRAP_REQUIRED:-1}" == "1" ]]; then
      echo "hermes_lab_cron_bootstrap failed and HERMES_CRON_BOOTSTRAP_REQUIRED=1" >&2
      exit 1
    fi
  else
    success_message="hermes cron bootstrap succeeded"
    if [[ -f "$BOOTSTRAP_REPORT_PATH" ]]; then
      success_message="$success_message; report=$BOOTSTRAP_REPORT_PATH"
    fi
    write_runtime_status "bootstrap" "succeeded" "$success_message"
  fi
fi

write_runtime_status "gateway" "starting" "launching hermes gateway run"

# This wrapper already runs under the image's /init entrypoint. Calling back
# into the Docker wrapper chain again makes startup harder to reason about and
# can reintroduce upstream main-wrapper environment quirks. Launch the gateway
# directly so HERMES_HOME, PATH and workspace bootstrap stay intact.
exec hermes gateway run
