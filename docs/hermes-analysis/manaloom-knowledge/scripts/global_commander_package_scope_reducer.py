#!/usr/bin/env python3
"""Reduce a Commander repair package when value-safe cuts are insufficient.

This read-only gate consumes a synthesized package plus the expanded cut lane.
When the full package cannot be copied because there are not enough value-safe
cuts, it selects the strongest smaller package that can be paired now. It does
not mutate decks, run battles, or authorize promotion.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_stage2.json"
)
DEFAULT_CUT_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_stage2.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def selected_adds(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in package_payload.get("selected_add_package") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def selected_value_safe_cuts(cut_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in cut_payload.get("selected_value_safe_cuts") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def axis_requirements(package_payload: Mapping[str, Any]) -> dict[str, int]:
    summary = package_payload.get("summary") or {}
    requirements = summary.get("initial_axis_requirements") or {}
    return {str(axis): max(0, int(value or 0)) for axis, value in requirements.items()}


def covered_axes(row: Mapping[str, Any]) -> list[str]:
    axes = [str(axis) for axis in row.get("covered_axes") or [] if axis]
    if axes:
        return axes
    axis = str(row.get("selected_for_axis") or row.get("axis") or "")
    return [axis] if axis else []


def score_add_for_reduced_scope(
    row: Mapping[str, Any],
    *,
    requirements: Mapping[str, int],
    available_cut_count: int,
) -> tuple[int, int, int, str]:
    axes = covered_axes(row)
    closes_axis = any(0 < int(requirements.get(axis) or 0) <= available_cut_count for axis in axes)
    covers_any_required_axis = any(int(requirements.get(axis) or 0) > 0 for axis in axes)
    return (
        1 if closes_axis else 0,
        1 if covers_any_required_axis else 0,
        int(row.get("score") or 0),
        str(row.get("card_name") or ""),
    )


def choose_reduced_adds(
    adds: list[dict[str, Any]],
    *,
    requirements: Mapping[str, int],
    available_cut_count: int,
) -> list[dict[str, Any]]:
    seen: set[str] = set()
    unique = []
    for row in adds:
        name = str(row.get("card_name") or "")
        key = normalize_name(name)
        if not name or key in seen:
            continue
        seen.add(key)
        unique.append(row)
    unique.sort(
        key=lambda row: score_add_for_reduced_scope(
            row,
            requirements=requirements,
            available_cut_count=available_cut_count,
        ),
        reverse=True,
    )
    return unique[:available_cut_count]


def pair_rows(adds: list[dict[str, Any]], cuts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    pairs = []
    for index, (add, cut) in enumerate(zip(adds, cuts), start=1):
        pairs.append(
            {
                "pair_index": index,
                "add": add.get("card_name"),
                "cut": cut.get("card_name"),
                "add_axis": add.get("selected_for_axis") or add.get("axis"),
                "add_covered_axes": covered_axes(add),
                "add_score": add.get("score") or 0,
                "cut_primary_role": cut.get("primary_cut_role"),
                "cut_matching_over_target_roles": cut.get("matching_over_target_roles") or [],
                "cut_score": cut.get("score") or 0,
                "status": "review_only_reduced_scope_pair",
            }
        )
    return pairs


def remaining_requirements_after_pairs(
    requirements: Mapping[str, int],
    pairs: list[dict[str, Any]],
) -> dict[str, int]:
    remaining = {str(axis): int(value or 0) for axis, value in requirements.items()}
    for pair in pairs:
        for axis in pair.get("add_covered_axes") or []:
            if axis in remaining:
                remaining[axis] = max(0, remaining[axis] - 1)
    return remaining


def source_db_from_cut_payload(cut_payload: Mapping[str, Any]) -> str:
    db_resolution = cut_payload.get("db_resolution") or {}
    selected = str(db_resolution.get("selected_db") or "")
    if selected:
        return selected
    input_artifacts = cut_payload.get("input_artifacts") or {}
    return str(input_artifacts.get("selected_db") or "")


def build_report(
    *,
    package_synthesis_report: Path,
    cut_source_lane_report: Path,
) -> dict[str, Any]:
    package_payload = load_json(package_synthesis_report)
    cut_payload = load_json(cut_source_lane_report)
    package_summary = package_payload.get("summary") or {}
    cut_summary = cut_payload.get("summary") or {}
    adds = selected_adds(package_payload)
    cuts = selected_value_safe_cuts(cut_payload)
    requirements = axis_requirements(package_payload)
    chosen_adds = choose_reduced_adds(adds, requirements=requirements, available_cut_count=len(cuts))
    scoped_pairs = pair_rows(chosen_adds, cuts)
    paired_add_names = {normalize_name(str(row.get("add") or "")) for row in scoped_pairs}
    dropped_adds = [row for row in adds if normalize_name(str(row.get("card_name") or "")) not in paired_add_names]
    remaining = remaining_requirements_after_pairs(requirements, scoped_pairs)
    ready = bool(scoped_pairs)
    original_blockers = list(package_payload.get("candidate_copy_blockers") or [])
    cut_blockers = list(cut_payload.get("candidate_copy_blockers") or [])
    blockers = [*original_blockers, *cut_blockers]
    if dropped_adds:
        blockers.append(f"reduced_scope_dropped_adds:{len(dropped_adds)}")
    if not scoped_pairs:
        blockers.append("no_value_safe_reduced_scope_pair_ready")
    source_db = source_db_from_cut_payload(cut_payload)
    return {
        "generated_at": utc_now(),
        "status": (
            "commander_package_scope_reduced_ready_for_candidate_copy"
            if ready
            else "commander_package_scope_reduction_blocks_candidate_copy"
        ),
        "artifact_type": "global_commander_package_scope_reducer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": ready,
        "reduced_scope_candidate_copy_allowed_now": ready,
        "full_package_candidate_copy_allowed_now": False,
        "source_db": source_db,
        "input_artifacts": {
            "package_synthesis_report": rel(package_synthesis_report),
            "cut_source_lane_report": rel(cut_source_lane_report),
        },
        "summary": {
            "deck_id": str(package_summary.get("deck_id") or cut_summary.get("deck_id") or ""),
            "commander": str(package_summary.get("commander") or cut_summary.get("commander") or ""),
            "original_add_count": len(adds),
            "value_safe_cut_count": len(cuts),
            "scoped_pair_count": len(scoped_pairs),
            "dropped_add_count": len(dropped_adds),
            "initial_axis_requirements": requirements,
            "remaining_axis_requirements": remaining,
            "closed_axis_count": sum(
                1
                for axis, value in requirements.items()
                if int(value or 0) > 0 and int(remaining.get(axis) or 0) == 0
            ),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": (
                "materialize_reduced_scope_candidate_copy"
                if ready
                else "backfill_value_safe_cuts_or_reduce_package_scope"
            ),
        },
        "candidate_copy_blockers": blockers,
        "scoped_pairs": scoped_pairs,
        "dropped_adds": dropped_adds,
        "selected_value_safe_cuts": cuts,
        "policy": {
            "scope_boundary": "Only the reduced paired scope may move to copied-DB materialization.",
            "full_package_boundary": "The original package remains blocked until every add has a value-safe cut.",
            "selection_policy": "Prefer closing a whole blocker axis when scarce cuts cannot support the full package.",
            "battle_boundary": "Battle and promotion remain closed until candidate copy, strategy matrix, and replay gates pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Package Scope Reducer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- original_add_count: `{summary['original_add_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- scoped_pair_count: `{summary['scoped_pair_count']}`",
        f"- dropped_add_count: `{summary['dropped_add_count']}`",
        f"- reduced_scope_candidate_copy_allowed_now: `{str(payload['reduced_scope_candidate_copy_allowed_now']).lower()}`",
        f"- full_package_candidate_copy_allowed_now: `{str(payload['full_package_candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Requirements",
        "",
        "| Axis | Initial | Remaining |",
        "| --- | ---: | ---: |",
    ]
    for axis, initial in summary["initial_axis_requirements"].items():
        lines.append(f"| `{axis}` | {initial} | {summary['remaining_axis_requirements'].get(axis, 0)} |")
    lines.extend(["", "## Scoped Pairs", "", "| Step | Add | Cut | Covers |", "| ---: | --- | --- | --- |"])
    for row in payload["scoped_pairs"]:
        lines.append(
            "| {step} | `{add}` | `{cut}` | `{axes}` |".format(
                step=row["pair_index"],
                add=row["add"],
                cut=row["cut"],
                axes=", ".join(row.get("add_covered_axes") or []),
            )
        )
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    if payload["dropped_adds"]:
        lines.extend(["", "## Dropped Adds", ""])
        for row in payload["dropped_adds"]:
            lines.append(f"- `{row.get('card_name')}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--cut-source-lane-report", type=Path, default=DEFAULT_CUT_SOURCE_LANE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        package_synthesis_report=args.package_synthesis_report,
        cut_source_lane_report=args.cut_source_lane_report,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
