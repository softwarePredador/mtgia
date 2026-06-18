#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
RUNTIME_ARTIFACT_DIR="${HERMES_LAB_RUNTIME_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_lab_runtime}"
STATUS_PATH="${HERMES_LAB_STARTUP_STATUS_FILE:-$RUNTIME_ARTIFACT_DIR/startup_status.json}"
BOOTSTRAP_REPORT_DIR="${HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR:-$HERMES_HOME/artifacts/hermes_cron_bootstrap}"
BOOTSTRAP_REPORT_PATH="$BOOTSTRAP_REPORT_DIR/latest_bootstrap_report.json"
BOOTSTRAP_REQUIRED="${HERMES_CRON_BOOTSTRAP_REQUIRED:-1}"
BOOTSTRAP_ENABLED="${HERMES_CRON_BOOTSTRAP:-1}"
JOBS_JSON="${HERMES_CRON_JOBS_JSON:-$HERMES_HOME/cron/jobs.json}"
PROBE_PATH="${HERMES_LAB_RUNTIME_PROBE_FILE:-$RUNTIME_ARTIFACT_DIR/runtime_probe.json}"
GATEWAY_HEALTH_URL="${HERMES_LAB_GATEWAY_HEALTH_URL:-http://127.0.0.1:8642/health}"

if [[ ! -f "$STATUS_PATH" ]]; then
  echo "hermes-lab healthcheck: missing startup status file: $STATUS_PATH" >&2
  exit 1
fi

python3 - "$STATUS_PATH" "$BOOTSTRAP_ENABLED" "$BOOTSTRAP_REQUIRED" "$BOOTSTRAP_REPORT_PATH" "$JOBS_JSON" "$PROBE_PATH" "$GATEWAY_HEALTH_URL" <<'PY'
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

status_path = Path(sys.argv[1])
bootstrap_enabled = sys.argv[2] == "1"
bootstrap_required = sys.argv[3] == "1"
bootstrap_report_path = Path(sys.argv[4])
jobs_json_path = Path(sys.argv[5])
probe_path = Path(sys.argv[6])
gateway_health_url = sys.argv[7]

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

jobs_count = None
if jobs_json_path.exists():
    try:
        jobs_payload = json.loads(jobs_json_path.read_text())
        jobs = jobs_payload.get("jobs", jobs_payload) if isinstance(jobs_payload, dict) else jobs_payload
        if isinstance(jobs, list):
            jobs_count = len(jobs)
    except Exception:
        jobs_count = None

if bootstrap_enabled and bootstrap_required and jobs_count == 0:
    print(
        f"hermes-lab healthcheck: jobs.json has zero jobs after required bootstrap: {jobs_json_path}",
        file=sys.stderr,
    )
    raise SystemExit(1)

probe_payload = None
if probe_path.exists():
    try:
        probe_payload = json.loads(probe_path.read_text())
    except Exception:
        probe_payload = None

try:
    with urllib.request.urlopen(gateway_health_url, timeout=5) as response:
        gateway_health = json.loads(response.read().decode("utf-8", "replace"))
except (urllib.error.URLError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
    print(
        f"hermes-lab healthcheck: gateway health probe failed at {gateway_health_url}: {exc}",
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
            "jobs_count": jobs_count,
            "runtime_probe_present": probe_path.exists(),
            "runtime_probe": probe_payload,
            "gateway_health": gateway_health,
        },
        sort_keys=True,
    )
)
PY
