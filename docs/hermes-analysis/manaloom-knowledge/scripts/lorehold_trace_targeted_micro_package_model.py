#!/usr/bin/env python3
"""Evaluate trace-targeted Lorehold micro-package readiness.

This read-only model starts after closing-window mining. It checks whether the
trace hypotheses can become a concrete package under the current cut contract.
If no seed-safe cuts exist, it emits a blocked model instead of inventing a
deck swap.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CLOSING_WINDOW_TRACE = (
    REPORT_DIR / "lorehold_closing_window_trace_miner_20260630_goal_learning.json"
)
DEFAULT_SEED_SAFE_CUT = (
    REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260630_goal_learning.json"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def build_model(
    *,
    closing_window_trace: Mapping[str, Any],
    seed_safe_cut: Mapping[str, Any],
    closing_window_path: Path,
    seed_safe_cut_path: Path,
) -> dict[str, Any]:
    hypotheses = list(closing_window_trace.get("hypothesis_queue") or [])
    ready_cuts = list(seed_safe_cut.get("seed_safe_cut_candidates") or [])
    same_lane_only = list(seed_safe_cut.get("same_lane_only_cut_slots") or [])
    cut_summary = seed_safe_cut.get("summary") or {}
    trace_summary = closing_window_trace.get("summary") or {}
    blocked_hypotheses = []
    blocker_counts: Counter[str] = Counter()
    for hypothesis in hypotheses:
        blockers = [
            "seed_safe_cut_ready_count_zero",
            "607_anchor_cards_must_be_preserved",
            "micro_package_requires_named_add_and_safe_cut_before_gate",
        ]
        if same_lane_only:
            blockers.append("same_lane_only_slots_are_not_seed_safe")
        for blocker in blockers:
            blocker_counts[blocker] += 1
        blocked_hypotheses.append(
            {
                "hypothesis_key": hypothesis.get("hypothesis_key"),
                "status": "blocked_no_seed_safe_cut",
                "target_gap_tags": hypothesis.get("target_gap_tags") or [],
                "requirements": hypothesis.get("requirements") or [],
                "blockers": blockers,
                "same_lane_only_cut_cards": [
                    row.get("card_name") for row in same_lane_only if row.get("card_name")
                ],
            }
        )
    ready_packages: list[dict[str, Any]] = []
    recommended = (
        "build_trace_targeted_micro_package_gate_manifest"
        if ready_packages
        else "freeze_607_current_champion_snapshot_until_new_cut_evidence"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "trace_targeted_micro_package_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "closing_window_trace_report": rel(closing_window_path),
        "seed_safe_cut_report": rel(seed_safe_cut_path),
        "ready_packages": ready_packages,
        "blocked_hypotheses": blocked_hypotheses,
        "protected_anchor_evidence": {
            "top_anchor_card_deficits": trace_summary.get("top_anchor_card_deficits") or [],
            "top_strategic_deficits": trace_summary.get("top_strategic_deficits") or [],
            "gap_counts": trace_summary.get("gap_counts") or {},
        },
        "summary": {
            "trace_hypothesis_count": len(hypotheses),
            "ready_micro_package_count": len(ready_packages),
            "blocked_hypothesis_count": len(blocked_hypotheses),
            "seed_safe_cut_ready_count": int(cut_summary.get("seed_safe_cut_ready_count") or 0),
            "same_lane_only_count": int(cut_summary.get("same_lane_only_count") or 0),
            "same_lane_only_cut_cards": cut_summary.get("same_lane_only_cut_cards") or [],
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "recommended_next_action": recommended,
            "next_steps": [
                "Snapshot protected deck_607 as the current champion candidate.",
                "Do not run another deck gate without a named add/cut package and seed-safe cut.",
                "Expand cut-safety only when new trace evidence can justify a specific cut slot.",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Trace-Targeted Micro-Package Model",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Closing-window trace: `{payload['closing_window_trace_report']}`",
        f"- Seed-safe cut report: `{payload['seed_safe_cut_report']}`",
        f"- Ready micro-packages: `{summary['ready_micro_package_count']}`",
        f"- Blocked hypotheses: `{summary['blocked_hypothesis_count']}`",
        f"- Seed-safe cut ready count: `{summary['seed_safe_cut_ready_count']}`",
        f"- Same-lane-only cuts: `{', '.join(summary['same_lane_only_cut_cards']) or '-'}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Blocker counts: `{json.dumps(summary['blocker_counts'], sort_keys=True)}`",
        "",
        "## Blocked Hypotheses",
        "",
    ]
    for row in payload.get("blocked_hypotheses") or []:
        lines.append(f"### {row.get('hypothesis_key')}")
        lines.append("")
        lines.append(f"- Status: `{row.get('status')}`")
        lines.append(f"- Target gaps: `{', '.join(row.get('target_gap_tags') or [])}`")
        for blocker in row.get("blockers") or []:
            lines.append(f"- Blocker: {blocker}")
        for requirement in row.get("requirements") or []:
            lines.append(f"- Requirement: {requirement}")
        lines.append("")
    lines.extend(["## Next Steps", ""])
    for step in summary.get("next_steps") or []:
        lines.append(f"- {step}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--closing-window-trace", type=Path, default=DEFAULT_CLOSING_WINDOW_TRACE)
    parser.add_argument("--seed-safe-cut", type=Path, default=DEFAULT_SEED_SAFE_CUT)
    parser.add_argument("--stem", default="lorehold_trace_targeted_micro_package_model_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_model(
        closing_window_trace=read_json(args.closing_window_trace),
        seed_safe_cut=read_json(args.seed_safe_cut),
        closing_window_path=args.closing_window_trace,
        seed_safe_cut_path=args.seed_safe_cut,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
