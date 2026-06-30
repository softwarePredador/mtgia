#!/usr/bin/env python3
"""Classify whether Lorehold 607 has any cut slot left to expand.

This read-only checkpoint runs after the current champion snapshot. It turns the
seed-safe cut synthesis into a concrete cut-evidence work queue: seed-safe cuts,
reviewable evidence gaps, same-lane-only slots, and hard-blocked slots.
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
DEFAULT_SEED_SAFE_CUT = (
    REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260630_goal_learning.json"
)
DEFAULT_CHAMPION_SNAPSHOT = (
    REPORT_DIR / "lorehold_current_champion_snapshot_20260630_goal_learning.json"
)
DEFAULT_MICRO_PACKAGE_MODEL = (
    REPORT_DIR / "lorehold_trace_targeted_micro_package_model_20260630_goal_learning.json"
)

ABSOLUTE_BLOCKERS = {
    "commander_never_cut",
    "cut_is_early_mana_floor_support",
    "cut_is_miracle_core_big_spell",
    "cut_is_protection_shell",
    "early_mana_floor_support",
    "mana_base_never_cut",
    "measured_high_cut_exposure",
    "miracle_or_finisher_core",
    "never_cut_lane",
    "never_cut_or_mana_base",
    "prior_rejected_cut",
    "prior_rejected_cut_slot",
    "protected_cut",
    "protection_shell",
    "structural_dependency",
}
EVIDENCE_GAP_BLOCKERS = {
    "cut_not_flex_decision",
    "cut_safety_not_seed_safe",
    "manual_review_cut_safety_block",
    "manual_status_not_seed_safe",
    "missing_cut_safety_row",
    "missing_manual_cut_evidence",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def classify_cut_slot(row: Mapping[str, Any]) -> dict[str, Any]:
    blockers = {str(item) for item in row.get("blockers") or []}
    absolute = sorted(blockers & ABSOLUTE_BLOCKERS)
    evidence_gaps = sorted(blockers & EVIDENCE_GAP_BLOCKERS)
    unknown = sorted(blockers - ABSOLUTE_BLOCKERS - EVIDENCE_GAP_BLOCKERS)
    if str(row.get("status") or "") == "seed_safe_cut_ready":
        actionability = "seed_safe_ready"
        next_action = "build_package_from_seed_safe_cut"
    elif str(row.get("status") or "") == "same_lane_only_not_seed_safe":
        actionability = "same_lane_hard_blocked"
        next_action = "do_not_use_until_concrete_same_lane_add_and_new_evidence"
    elif absolute:
        actionability = "hard_blocked"
        next_action = "do_not_use_as_cut_under_current_contract"
    elif evidence_gaps or unknown:
        actionability = "reviewable_evidence_gap"
        next_action = "review_cut_safety_row_before_any_package"
    else:
        actionability = "reviewable_no_blocker_recorded"
        next_action = "review_missing_blocker_context_before_any_package"
    return {
        "card_name": row.get("card_name"),
        "lane": row.get("lane"),
        "status": row.get("status"),
        "score": row.get("score"),
        "actionability": actionability,
        "recommended_action": next_action,
        "absolute_blockers": absolute,
        "evidence_gap_blockers": evidence_gaps,
        "unknown_blockers": unknown,
        "all_blockers": sorted(blockers),
        "unique_exposure_count": row.get("unique_exposure_count"),
        "manual_status": row.get("manual_status"),
        "cut_safety_status": row.get("cut_safety_status"),
        "cut_safety_decision": row.get("cut_safety_decision"),
    }


def build_report(
    *,
    seed_safe_cut: Mapping[str, Any],
    champion_snapshot: Mapping[str, Any],
    micro_package_model: Mapping[str, Any],
    seed_safe_cut_path: Path,
    champion_snapshot_path: Path,
    micro_package_model_path: Path,
) -> dict[str, Any]:
    rows = [classify_cut_slot(row) for row in seed_safe_cut.get("cut_slots") or []]
    rows.sort(
        key=lambda row: (
            {
                "seed_safe_ready": 0,
                "reviewable_evidence_gap": 1,
                "reviewable_no_blocker_recorded": 2,
                "same_lane_hard_blocked": 3,
                "hard_blocked": 4,
            }.get(str(row.get("actionability")), 9),
            len(row.get("absolute_blockers") or []),
            len(row.get("all_blockers") or []),
            -int(row.get("score") or 0),
            str(row.get("card_name") or ""),
        )
    )
    actionability_counts = Counter(str(row.get("actionability") or "") for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in row.get("all_blockers") or [])
    lane_counts = Counter(str(row.get("lane") or "") for row in rows)
    ready = [row for row in rows if row["actionability"] == "seed_safe_ready"]
    reviewable = [
        row
        for row in rows
        if row["actionability"] in {"reviewable_evidence_gap", "reviewable_no_blocker_recorded"}
    ]
    same_lane = [row for row in rows if row["actionability"] == "same_lane_hard_blocked"]
    if ready:
        recommended = "build_package_from_seed_safe_cut"
    elif reviewable:
        recommended = "review_cut_safety_rows_for_evidence_gap_slots"
    else:
        recommended = "no_cut_slot_to_expand_under_current_607_contract"
    return {
        "generated_at": utc_now(),
        "artifact_type": "trace_cut_evidence_expansion_queue",
        "postgres_writes": False,
        "source_db_mutated": False,
        "seed_safe_cut_report": rel(seed_safe_cut_path),
        "current_champion_snapshot": rel(champion_snapshot_path),
        "micro_package_model_report": rel(micro_package_model_path),
        "summary": {
            "cut_slot_count": len(rows),
            "seed_safe_ready_count": len(ready),
            "reviewable_evidence_gap_count": len(reviewable),
            "same_lane_hard_blocked_count": len(same_lane),
            "hard_blocked_count": actionability_counts.get("hard_blocked", 0),
            "actionability_counts": dict(sorted(actionability_counts.items())),
            "lane_counts": dict(sorted(lane_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "top_reviewable_cut_cards": [row["card_name"] for row in reviewable[:12]],
            "top_same_lane_cut_cards": [row["card_name"] for row in same_lane[:12]],
            "top_near_miss_cut_cards": [row["card_name"] for row in rows[:12]],
            "champion_status": champion_snapshot.get("status"),
            "micro_package_ready_count": int(
                ((micro_package_model.get("summary") or {}).get("ready_micro_package_count"))
                or 0
            ),
            "recommended_next_action": recommended,
        },
        "seed_safe_cut_queue": ready,
        "reviewable_evidence_gap_queue": reviewable,
        "same_lane_hard_blocked_queue": same_lane,
        "hard_blocked_queue": [row for row in rows if row["actionability"] == "hard_blocked"],
        "all_cut_slots": rows,
        "method_notes": [
            "This report does not make blocked cuts safe.",
            "A reviewable evidence gap must be reclassified by cut-safety evidence before any package gate.",
            "If reviewable_evidence_gap_count is zero, the current 607 one-for-one cut contract is exhausted.",
            "PostgreSQL and SQLite are not mutated by this script.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Trace Cut Evidence Expansion Queue",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Seed-safe cut report: `{payload['seed_safe_cut_report']}`",
        f"- Current champion snapshot: `{payload['current_champion_snapshot']}`",
        f"- Micro-package model: `{payload['micro_package_model_report']}`",
        f"- Cut slots: `{summary['cut_slot_count']}`",
        f"- Seed-safe ready: `{summary['seed_safe_ready_count']}`",
        f"- Reviewable evidence gaps: `{summary['reviewable_evidence_gap_count']}`",
        f"- Same-lane hard blocked: `{summary['same_lane_hard_blocked_count']}`",
        f"- Hard blocked: `{summary['hard_blocked_count']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Actionability counts: `{json.dumps(summary['actionability_counts'], sort_keys=True)}`",
        "",
        "## Reviewable Evidence Gaps",
        "",
    ]
    reviewable = payload.get("reviewable_evidence_gap_queue") or []
    if not reviewable:
        lines.append("- None.")
    else:
        for row in reviewable[:20]:
            lines.append(
                f"- `{row['card_name']}` lane `{row['lane']}` blockers "
                f"`{', '.join(row.get('all_blockers') or [])}`."
            )
    lines.extend(["", "## Same-Lane Hard Blocked", ""])
    same_lane = payload.get("same_lane_hard_blocked_queue") or []
    if not same_lane:
        lines.append("- None.")
    else:
        for row in same_lane[:20]:
            lines.append(
                f"- `{row['card_name']}` lane `{row['lane']}` absolute blockers "
                f"`{', '.join(row.get('absolute_blockers') or [])}`."
            )
    lines.extend(["", "## Top Near Misses", ""])
    for row in (payload.get("all_cut_slots") or [])[:20]:
        lines.append(
            f"- `{row['card_name']}` actionability `{row['actionability']}` lane "
            f"`{row['lane']}` blockers `{', '.join(row.get('all_blockers') or [])}`."
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed-safe-cut", type=Path, default=DEFAULT_SEED_SAFE_CUT)
    parser.add_argument("--champion-snapshot", type=Path, default=DEFAULT_CHAMPION_SNAPSHOT)
    parser.add_argument("--micro-package-model", type=Path, default=DEFAULT_MICRO_PACKAGE_MODEL)
    parser.add_argument("--stem", default="lorehold_trace_cut_evidence_expander_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        seed_safe_cut=read_json(args.seed_safe_cut),
        champion_snapshot=read_json(args.champion_snapshot),
        micro_package_model=read_json(args.micro_package_model),
        seed_safe_cut_path=args.seed_safe_cut,
        champion_snapshot_path=args.champion_snapshot,
        micro_package_model_path=args.micro_package_model,
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
