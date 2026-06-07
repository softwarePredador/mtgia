#!/usr/bin/env python3
"""Back off Hermes scheduler jobs that are failing because of provider limits.

This does not try to "fix" quota. It prevents noisy repeated failures by
pausing agent jobs whose last error indicates HTTP 429, rate limit, quota, or
provider overload. Script/no-agent operational jobs are left untouched.
"""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import REPORT_DIR, write_report


DEFAULT_JOBS = Path("/opt/data/cron/jobs.json")
RATE_LIMIT_PATTERNS = (
    "429",
    "rate limit",
    "ratelimit",
    "too many requests",
    "quota",
    "overloaded",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_jobs(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict) or not isinstance(raw.get("jobs"), list):
        raise RuntimeError(f"Unsupported jobs.json shape at {path}")
    return raw, raw["jobs"]


def error_text(job: dict[str, Any]) -> str:
    return " ".join(
        str(job.get(key) or "")
        for key in (
            "last_error",
            "last_delivery_error",
            "last_status",
        )
    ).lower()


def is_provider_limited(job: dict[str, Any]) -> bool:
    if job.get("no_agent"):
        return False
    text = error_text(job)
    return any(pattern in text for pattern in RATE_LIMIT_PATTERNS)


def render_report(changed: list[dict[str, Any]], candidates: list[dict[str, Any]], apply: bool, jobs_path: Path, backup: Path | None) -> str:
    lines = [
        "# Hermes Provider Backoff Report",
        "",
        f"- jobs_path: `{jobs_path}`",
        f"- mode: {'apply' if apply else 'dry-run'}",
        f"- candidates: {len(candidates)}",
        f"- changed: {len(changed)}",
        f"- backup: `{backup}`" if backup else "- backup: none",
        "",
        "## Jobs",
        "",
        "| Status | Name | Enabled | State | Last Status | Reason |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    rows = changed if apply else candidates
    if rows:
        for job in rows:
            lines.append(
                "| {status} | {name} | {enabled} | {state} | {last_status} | {reason} |".format(
                    status="paused" if apply else "candidate",
                    name=job.get("name") or job.get("id"),
                    enabled=job.get("enabled"),
                    state=job.get("state"),
                    last_status=job.get("last_status"),
                    reason=str(job.get("paused_reason") or job.get("last_error") or job.get("last_delivery_error") or "")[:180].replace("|", "\\|"),
                )
            )
    else:
        lines.append("| info | none | - | - | - | No provider-limited jobs found. |")

    lines.extend(
        [
            "",
            "## Policy",
            "",
            "- Operational no-agent jobs are not paused by this script.",
            "- Provider-limited agent jobs should be resumed only after quota/backoff is resolved.",
            "- Resume manually by setting `enabled=true`, `state=scheduled`, and clearing `paused_reason`.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jobs", type=Path, default=DEFAULT_JOBS)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    raw, jobs = load_jobs(args.jobs)
    candidates = [job for job in jobs if is_provider_limited(job)]
    changed: list[dict[str, Any]] = []
    backup: Path | None = None

    if args.apply and candidates:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        backup = args.jobs.with_name(f"{args.jobs.name}.bak_provider_backoff_{stamp}")
        shutil.copy2(args.jobs, backup)
        for job in candidates:
            job["enabled"] = False
            job["state"] = "paused"
            job["paused_at"] = utc_now()
            job["paused_reason"] = "provider_429_backoff: paused by hermes_provider_backoff.py"
            job.setdefault("provider_backoff", {})
            job["provider_backoff"].update(
                {
                    "applied_at": utc_now(),
                    "previous_last_status": job.get("last_status"),
                    "previous_last_error": job.get("last_error"),
                    "previous_last_delivery_error": job.get("last_delivery_error"),
                }
            )
            changed.append(dict(job))
        raw["updated_at"] = utc_now()
        args.jobs.write_text(json.dumps(raw, indent=2, ensure_ascii=True, sort_keys=True), encoding="utf-8")

    markdown = render_report(changed, candidates, args.apply, args.jobs, backup)
    print(markdown)
    if args.report:
        REPORT_DIR.mkdir(parents=True, exist_ok=True)
        path = write_report("hermes_provider_backoff", markdown)
        print(f"Report written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
