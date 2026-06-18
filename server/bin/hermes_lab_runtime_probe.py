#!/usr/bin/env python3
"""Materialize a small runtime probe for hermes-lab startup."""

from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _env_path(key: str, default: str) -> Path:
    return Path(os.environ.get(key, default)).resolve()


HERMES_HOME = _env_path("HERMES_HOME", "/opt/data")
REPO_DIR = _env_path("MANALOOM_WORKSPACE", str(HERMES_HOME / "workspace" / "mtgia"))
JOBS_JSON = _env_path("HERMES_CRON_JOBS_JSON", str(HERMES_HOME / "cron" / "jobs.json"))
ARTIFACT_DIR = _env_path(
    "HERMES_LAB_RUNTIME_ARTIFACT_DIR",
    str(HERMES_HOME / "artifacts" / "hermes_lab_runtime"),
)
PROBE_PATH = _env_path(
    "HERMES_LAB_RUNTIME_PROBE_FILE",
    str(ARTIFACT_DIR / "runtime_probe.json"),
)
EXPECTED_PROVIDER = os.environ.get("HERMES_PROVIDER")
EXPECTED_MODEL = os.environ.get("HERMES_MODEL")
HERMES_CLI = os.environ.get("HERMES_CLI", "/opt/hermes/bin/hermes")
EXPECTED_JOB_NAMES = (
    "manaloom-docs-branch-sync",
    "manaloom-commander-knowledge-deep",
    "manaloom-gamechanger-research",
    "manaloom-knowledge-synthesis",
    "mtg-rules-auditor",
)


def _git(args: list[str]) -> str | None:
    if not (REPO_DIR / ".git").exists():
        return None
    try:
        return subprocess.check_output(
            ["git", "-C", str(REPO_DIR), *args],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return None


def _hermes_config_get(key: str) -> str | None:
    try:
        value = subprocess.check_output(
            [HERMES_CLI, "config", "get", key],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return None
    return value or None


def _load_jobs() -> list[dict[str, object]]:
    if not JOBS_JSON.exists():
        return []
    try:
        payload = json.loads(JOBS_JSON.read_text(encoding="utf-8"))
    except Exception:
        return []
    jobs = payload.get("jobs", payload) if isinstance(payload, dict) else payload
    if not isinstance(jobs, list):
        return []
    return [job for job in jobs if isinstance(job, dict)]


def main() -> int:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    jobs = _load_jobs()
    active_names = sorted(
        {
            str(job.get("name", "")).strip()
            for job in jobs
            if str(job.get("state") or "").lower() != "paused"
            and bool(job.get("enabled", True))
        }
    )

    resolved_provider = _hermes_config_get("model.provider")
    resolved_model = _hermes_config_get("model.default")

    payload = {
        "generated_at_utc": _utc_now(),
        "repo_dir": str(REPO_DIR),
        "repo_exists": REPO_DIR.exists(),
        "repo_head": _git(["rev-parse", "HEAD"]),
        "repo_branch": _git(["rev-parse", "--abbrev-ref", "HEAD"]),
        "jobs_json": str(JOBS_JSON),
        "jobs_json_exists": JOBS_JSON.exists(),
        "jobs_count": len(jobs),
        "active_job_names": active_names,
        "expected_job_names": list(EXPECTED_JOB_NAMES),
        "expected_jobs_present": all(name in active_names for name in EXPECTED_JOB_NAMES),
        "expected_provider": EXPECTED_PROVIDER,
        "expected_model": EXPECTED_MODEL,
        "resolved_provider": resolved_provider,
        "resolved_model": resolved_model,
        "provider_matches_expected": (
            True if not EXPECTED_PROVIDER else resolved_provider == EXPECTED_PROVIDER
        ),
        "model_matches_expected": (
            True if not EXPECTED_MODEL else resolved_model == EXPECTED_MODEL
        ),
        "openai_api_key_present": bool(os.environ.get("OPENAI_API_KEY")),
        "api_server_key_present": bool(os.environ.get("API_SERVER_KEY")),
    }

    PROBE_PATH.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print("HERMES_LAB_RUNTIME_PROBE", json.dumps(payload, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
