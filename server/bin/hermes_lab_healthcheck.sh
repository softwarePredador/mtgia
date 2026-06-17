#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
RUNTIME_ARTIFACT_DIR="${HERMES_LAB_RUNTIME_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_lab_runtime}"
STATUS_PATH="${HERMES_LAB_STARTUP_STATUS_FILE:-$RUNTIME_ARTIFACT_DIR/startup_status.json}"
BOOTSTRAP_REPORT_DIR="${HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_cron_bootstrap}"
BOOTSTRAP_REPORT_PATH="$BOOTSTRAP_REPORT_DIR/latest_bootstrap_report.json"
BOOTSTRAP_REQUIRED="${HERMES_CRON_BOOTSTRAP_REQUIRED:-1}"
BOOTSTRAP_ENABLED="${HERMES_CRON_BOOTSTRAP:-1}"

if [[ ! -f "$STATUS_PATH" ]]; then
  echo "hermes-lab healthcheck: missing startup status file: $STATUS_PATH" >&2
  exit 1
fi

python3 - "$STATUS_PATH" "$BOOTSTRAP_ENABLED" "$BOOTSTRAP_REQUIRED" "$BOOTSTRAP_REPORT_PATH" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

status_path = Path(sys.argv[1])
bootstrap_enabled = sys.argv[2] == "1"
bootstrap_required = sys.argv[3] == "1"
bootstrap_report_path = Path(sys.argv[4])

payload = json.loads(status_path.read_text())
phase = payload.get("phase")
status = payload.get("status")
message = payload.get("message") or ""

if status == "failed":
    print(
        f"hermes-lab healthcheck: startup failed at phase={phase}: {message}",
        file=sys.stderr,
    )
    raise SystemExit(1)

if bootstrap_enabled and bootstrap_required and not bootstrap_report_path.exists():
    print(
        "hermes-lab healthcheck: bootstrap report missing even though bootstrap is required: "
        f"{bootstrap_report_path}",
        file=sys.stderr,
    )
    raise SystemExit(1)

print(
    json.dumps(
        {
            "phase": phase,
            "status": status,
            "message": message,
            "bootstrap_report_present": bootstrap_report_path.exists(),
        },
        sort_keys=True,
    )
)
PY
