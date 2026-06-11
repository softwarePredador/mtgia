#!/usr/bin/env python3
"""Generate a deterministic Hermes cron health report.

This script intentionally avoids LLM/provider calls. It reads Hermes scheduler
state and recent job outputs, then emits a compact Markdown report that can run
as a cron while the Hermes AWS instance still exists.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_JOBS_JSON = "/opt/data/cron/jobs.json"
DEFAULT_OUTPUT_DIR = "/opt/data/cron/output"
DEFAULT_SCRIPTS_DIR = "/opt/data/scripts"

ERROR_MARKERS = (
    "HTTP 429",
    "RuntimeError:",
    "Traceback",
    "(FAILED)",
    "script failed",
    "permission denied",
    "readonly database",
)


@dataclass(frozen=True)
class CronEvidence:
    latest_output: Path | None
    latest_size: int | None
    latest_excerpt: str
    markers: tuple[str, ...]


def _load_jobs(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text())
    if isinstance(data, list):
        return [j for j in data if isinstance(j, dict)]
    if isinstance(data, dict):
        jobs = data.get("jobs", [])
        return [j for j in jobs if isinstance(j, dict)]
    raise ValueError(f"Unsupported jobs JSON shape: {type(data).__name__}")


def _latest_output(output_dir: Path, job_id: str) -> Path | None:
    job_dir = output_dir / job_id
    if not job_dir.is_dir():
        return None
    files = sorted(
        (p for p in job_dir.glob("*.md") if p.is_file()),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return files[0] if files else None


def _read_evidence(output_dir: Path, job_id: str) -> CronEvidence:
    latest = _latest_output(output_dir, job_id)
    if latest is None:
        return CronEvidence(None, None, "", ())
    text = latest.read_text(errors="replace")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    excerpt = " | ".join(lines[:6])[:500]
    markers = _failure_markers(text)
    return CronEvidence(latest, latest.stat().st_size, excerpt, markers)


def _failure_markers(text: str) -> tuple[str, ...]:
    """Return markers only for actual cron failure blocks, not historical prose."""
    lower = text.lower()
    header = "\n".join(text.splitlines()[:8]).lower()
    has_failure_block = "(failed)" in header or "\n## error" in lower or "script exited with code" in lower
    if not has_failure_block:
        return ()
    return tuple(marker for marker in ERROR_MARKERS if marker.lower() in lower)


def _script_state(scripts_dir: Path, script_name: str | None) -> str:
    if not script_name:
        return "agent"
    path = scripts_dir / script_name
    if not path.exists():
        return "missing"
    if path.suffix == ".py":
        return "ok"
    if not os.access(path, os.X_OK):
        return "not_executable"
    return "ok"


def _risk_for(job: dict[str, Any], evidence: CronEvidence, script_state: str) -> str:
    enabled = bool(job.get("enabled"))
    provider = job.get("provider")
    script = job.get("script")
    last_status = job.get("last_status")
    if script_state in {"missing", "not_executable"}:
        return "P0" if enabled else "P3"
    if enabled and evidence.markers:
        return "P1"
    if enabled and last_status in {"error", "failed"}:
        return "P1"
    if enabled and provider and not script:
        return "P2"
    if not enabled and evidence.markers:
        return "P3"
    return "OK"


def _migration_target(job: dict[str, Any]) -> str:
    name = str(job.get("name") or "")
    script = job.get("script")
    provider = job.get("provider")
    if script and name in {
        "manaloom-pull-learning-events",
        "manaloom-auto-sync-learned-decks",
        "manaloom-auto-promote-learned",
        "manaloom-knowledge-import",
    }:
        return "server_job"
    if script and "optimizer" in name:
        return "server_worker_or_manual"
    if script:
        return "ci_or_observability"
    if provider:
        return "replace_with_deterministic_report"
    return "manual_only"


def build_report(jobs: list[dict[str, Any]], output_dir: Path, scripts_dir: Path) -> str:
    rows: list[dict[str, Any]] = []
    for job in jobs:
        evidence = _read_evidence(output_dir, str(job.get("id") or ""))
        script_state = _script_state(scripts_dir, job.get("script"))
        rows.append(
            {
                "job": job,
                "evidence": evidence,
                "script_state": script_state,
                "risk": _risk_for(job, evidence, script_state),
                "target": _migration_target(job),
            }
        )

    enabled = [r for r in rows if r["job"].get("enabled")]
    paused = [r for r in rows if not r["job"].get("enabled")]
    provider_enabled = [r for r in enabled if r["job"].get("provider")]
    flagged = [r for r in rows if r["risk"] != "OK"]

    lines = [
        "# Hermes Cron Governor Report",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        "## Summary",
        "",
        f"- jobs_total: {len(rows)}",
        f"- enabled: {len(enabled)}",
        f"- paused: {len(paused)}",
        f"- enabled_provider_dependent: {len(provider_enabled)}",
        f"- flagged: {len(flagged)}",
        "",
        "## Enabled Jobs",
        "",
        "| Risk | Job | Schedule | Script/Provider | Last status | Migration target | Evidence |",
        "|---|---|---|---|---|---|---|",
    ]
    for row in enabled:
        job = row["job"]
        evidence = row["evidence"]
        actor = job.get("script") or f"{job.get('provider')}/{job.get('model')}"
        marker = ", ".join(evidence.markers) if evidence.markers else "-"
        lines.append(
            "| {risk} | `{name}` | {schedule} | `{actor}` ({script_state}) | {status} | {target} | {marker} |".format(
                risk=row["risk"],
                name=job.get("name"),
                schedule=job.get("schedule_display") or job.get("schedule"),
                actor=actor,
                script_state=row["script_state"],
                status=job.get("last_status"),
                target=row["target"],
                marker=marker,
            )
        )

    lines.extend(
        [
            "",
            "## Paused Jobs",
            "",
            "| Risk | Job | Last status | Reason |",
            "|---|---|---|---|",
        ]
    )
    for row in paused:
        job = row["job"]
        reason = str(job.get("paused_reason") or "-").replace("\n", " ")[:140]
        lines.append(
            f"| {row['risk']} | `{job.get('name')}` | {job.get('last_status')} | {reason} |"
        )

    if flagged:
        lines.extend(["", "## Required Attention", ""])
        for row in flagged:
            job = row["job"]
            evidence = row["evidence"]
            details = ", ".join(evidence.markers) or row["script_state"]
            lines.append(f"- {row['risk']} `{job.get('name')}`: {details}.")
    else:
        lines.extend(["", "## Required Attention", "", "- None."])

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs-json", default=os.environ.get("HERMES_CRON_JOBS_JSON", DEFAULT_JOBS_JSON))
    parser.add_argument("--output-dir", default=os.environ.get("HERMES_CRON_OUTPUT_DIR", DEFAULT_OUTPUT_DIR))
    parser.add_argument("--scripts-dir", default=os.environ.get("HERMES_SCRIPTS_DIR", DEFAULT_SCRIPTS_DIR))
    args = parser.parse_args(argv)

    jobs = _load_jobs(Path(args.jobs_json))
    report = build_report(jobs, Path(args.output_dir), Path(args.scripts_dir))
    print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
