#!/usr/bin/env python3
"""Aggregate sanitized battle engine metrics snapshots.

Input snapshots are produced by battle_analyst_v9.py when
MANALOOM_ENGINE_METRICS_OUT is set. This report intentionally avoids decklists,
card payloads, credentials and raw replay events.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "battle_engine_metrics_report_v1"
SNAPSHOT_SCHEMA = "battle_engine_metrics_v1"
COUNTERS = (
    "cast_announcements",
    "illegal_casts",
    "player_eliminations",
    "stack_pushes",
    "stack_resolutions",
    "priority_rounds",
    "sba_iterations",
    "replacement_events",
    "sba_permanent_moves",
)


def _safe_text(value: Any, limit: int = 160) -> str:
    text = str(value or "")
    return text[:limit]


def load_snapshot(path: Path) -> dict[str, Any] | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if data.get("schema_version") != SNAPSHOT_SCHEMA:
        return None
    return data


def iter_snapshot_paths(input_dir: Path) -> list[Path]:
    if input_dir.is_file():
        return [input_dir]
    return sorted(path for path in input_dir.rglob("*.json") if path.is_file())


def aggregate_snapshots(input_dir: Path) -> dict[str, Any]:
    totals = {key: 0 for key in COUNTERS}
    event_counts: dict[str, int] = {}
    warning_samples: list[str] = []
    processed = 0
    skipped = 0
    max_stack_depth = 0

    for path in iter_snapshot_paths(input_dir):
        snapshot = load_snapshot(path)
        if snapshot is None:
            skipped += 1
            continue
        processed += 1
        counters = snapshot.get("counters") or snapshot
        for key in COUNTERS:
            totals[key] += int(counters.get(key) or 0)
        max_stack_depth = max(max_stack_depth, int(snapshot.get("max_stack_depth") or 0))
        for event, count in (snapshot.get("event_counts") or {}).items():
            event_counts[str(event)] = event_counts.get(str(event), 0) + int(count or 0)
        for warning in snapshot.get("warnings") or []:
            if len(warning_samples) < 10:
                warning_samples.append(_safe_text(warning))

    return {
        "schema_version": SCHEMA_VERSION,
        "files_processed": processed,
        "files_skipped": skipped,
        "totals": totals,
        "max_stack_depth": max_stack_depth,
        "event_counts": dict(sorted(event_counts.items())),
        "warning_samples": warning_samples,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    report = aggregate_snapshots(args.input_dir)
    text = json.dumps(report, ensure_ascii=True, sort_keys=True, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
