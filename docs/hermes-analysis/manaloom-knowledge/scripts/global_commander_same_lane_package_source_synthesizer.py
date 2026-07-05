#!/usr/bin/env python3
"""Synthesize a review-only same-lane Commander add package from source lanes.

This gate consumes same-lane add source lanes and selects a bounded, balanced
add package proposal. It intentionally does not pair cuts, copy a deck, mutate
SQLite/PostgreSQL, run battle, or promote a package.
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
DEFAULT_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1"
)
DEFAULT_PACKAGE_SIZE_LIMIT = 8


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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def candidate_key(row: Mapping[str, Any]) -> str:
    return normalize_name(str(row.get("card_name") or ""))


def candidate_sort_key(row: Mapping[str, Any]) -> tuple[int, str]:
    return (-as_int(row.get("score")), str(row.get("card_name") or ""))


def ready_source_lanes(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    lanes = []
    for lane in payload.get("source_lanes") or []:
        if not isinstance(lane, Mapping):
            continue
        candidates = [
            dict(row)
            for row in lane.get("top_candidates") or []
            if isinstance(row, Mapping) and row.get("card_name")
        ]
        candidates.sort(key=candidate_sort_key)
        lanes.append(
            {
                "required_add_axis": str(lane.get("required_add_axis") or ""),
                "cut_role": str(lane.get("cut_role") or ""),
                "target_cut_count": as_int(lane.get("target_cut_count")),
                "ready_candidate_count": as_int(lane.get("ready_candidate_count")),
                "status": str(lane.get("status") or ""),
                "top_candidates": candidates,
            }
        )
    return lanes


def select_balanced_package(lanes: list[dict[str, Any]], package_size_limit: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    selected: list[dict[str, Any]] = []
    held: list[dict[str, Any]] = []
    seen: set[str] = set()

    def add_candidate(lane: Mapping[str, Any], candidate: Mapping[str, Any]) -> bool:
        key = candidate_key(candidate)
        if not key or key in seen or len(selected) >= package_size_limit:
            return False
        seen.add(key)
        selected.append(
            {
                "card_name": candidate.get("card_name"),
                "selected_for_axis": lane.get("required_add_axis"),
                "replaces_cut_role": lane.get("cut_role"),
                "score": as_int(candidate.get("score")),
                "source_lanes": candidate.get("source_lanes") or [],
                "profile_roles": candidate.get("profile_roles") or [],
                "fit_reasons": candidate.get("fit_reasons") or [],
                "commander_legality": candidate.get("commander_legality") or "",
                "color_identity": candidate.get("color_identity") or [],
                "cmc": candidate.get("cmc"),
                "type_line": candidate.get("type_line") or "",
                "status": "review_only_same_lane_package_add",
                "mutation_allowed": False,
                "candidate_copy_allowed": False,
                "required_gates": [
                    "value_safe_same_lane_cut_pairing",
                    "package_scope_reducer",
                    "isolated_candidate_copy",
                    "commander_strategy_matrix",
                    "battle_gate_with_added_card_exercised",
                ],
            }
        )
        return True

    active_lanes = [
        lane
        for lane in lanes
        if lane["required_add_axis"] and lane["ready_candidate_count"] > 0 and lane["top_candidates"]
    ]
    for lane in active_lanes:
        add_candidate(lane, lane["top_candidates"][0])

    remaining = []
    for lane in active_lanes:
        quota = max(1, min(as_int(lane.get("target_cut_count")), package_size_limit))
        already = sum(1 for row in selected if row["selected_for_axis"] == lane["required_add_axis"])
        for candidate in lane["top_candidates"][1:]:
            remaining.append((lane, candidate, quota, already))
    remaining.sort(key=lambda item: candidate_sort_key(item[1]))
    per_axis_selected: dict[str, int] = {}
    for row in selected:
        axis = str(row["selected_for_axis"])
        per_axis_selected[axis] = per_axis_selected.get(axis, 0) + 1
    for lane, candidate, quota, _already in remaining:
        axis = str(lane["required_add_axis"])
        if len(selected) >= package_size_limit:
            break
        if per_axis_selected.get(axis, 0) >= quota:
            continue
        if add_candidate(lane, candidate):
            per_axis_selected[axis] = per_axis_selected.get(axis, 0) + 1

    for lane in active_lanes:
        for candidate in lane["top_candidates"]:
            if candidate_key(candidate) not in seen:
                held.append(
                    {
                        "card_name": candidate.get("card_name"),
                        "axis": lane.get("required_add_axis"),
                        "score": as_int(candidate.get("score")),
                        "status": "held_same_lane_source_candidate_not_in_bounded_package",
                    }
                )
            if len(held) >= 20:
                break
        if len(held) >= 20:
            break
    return selected, held


def build_report(
    *,
    source_lane_report: Path,
    package_size_limit: int = DEFAULT_PACKAGE_SIZE_LIMIT,
) -> dict[str, Any]:
    payload = load_json(source_lane_report)
    summary = payload.get("summary") or {}
    lanes = ready_source_lanes(payload)
    missing = [lane["required_add_axis"] for lane in lanes if lane["ready_candidate_count"] <= 0]
    selected, held = select_balanced_package(lanes, package_size_limit)
    axes_covered = sorted({str(row["selected_for_axis"]) for row in selected})
    all_ready = bool(lanes) and not missing
    status = (
        "same_lane_source_package_synthesized_no_cut_pairs"
        if all_ready and selected
        else "same_lane_source_package_synthesis_blocks_on_missing_axes"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_package_source_synthesizer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "source_lane_report": rel(source_lane_report),
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "package_size_limit": package_size_limit,
            "source_lane_count": len(lanes),
            "ready_source_lane_count": len(lanes) - len(missing),
            "missing_axis_count": len(missing),
            "missing_axes": missing,
            "selected_add_count": len(selected),
            "axes_covered_count": len(axes_covered),
            "axes_covered": axes_covered,
            "unpaired_add_count": len(selected),
            "ready_pair_count": 0,
            "next_gate": (
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package"
                if status == "same_lane_source_package_synthesized_no_cut_pairs"
                else "external_same_lane_source_research_for_missing_axes"
            ),
        },
        "selected_add_package": selected,
        "held_source_candidate_sample": held,
        "source_lane_diagnostics": [
            {
                "required_add_axis": lane["required_add_axis"],
                "cut_role": lane["cut_role"],
                "target_cut_count": lane["target_cut_count"],
                "ready_candidate_count": lane["ready_candidate_count"],
                "selected_add_count": sum(
                    1 for row in selected if row["selected_for_axis"] == lane["required_add_axis"]
                ),
                "status": (
                    "source_lane_contributed_to_package"
                    if any(row["selected_for_axis"] == lane["required_add_axis"] for row in selected)
                    else "source_lane_missing_or_not_selected"
                ),
            }
            for lane in lanes
        ],
        "candidate_copy_blockers": [
            "selected_adds_are_unpaired",
            "value_safe_same_lane_cut_pairs_missing",
            "candidate_copy_closed_until_scope_reducer_pairs_adds_and_cuts",
        ],
        "policy": {
            "package_boundary": "This report chooses review-only adds from source lanes; it does not pair cuts.",
            "same_lane_boundary": "Every selected add carries an explicit required add axis tied to a target cut role.",
            "cut_boundary": "No cut is value-safe until a later cut-pairing gate proves it.",
            "battle_boundary": "No battle or promotion opens before cut pairing, candidate copy, strategy matrix, and replay evidence.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Package Source Synthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- package_size_limit: `{summary['package_size_limit']}`",
        f"- source_lane_count: `{summary['source_lane_count']}`",
        f"- ready_source_lane_count: `{summary['ready_source_lane_count']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- axes_covered_count: `{summary['axes_covered_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Selected Add Package",
        "",
        "| Add | Axis | Replaces Cut Role | Score | Roles |",
        "| --- | --- | --- | ---: | --- |",
    ]
    for row in payload["selected_add_package"]:
        lines.append(
            "| `{card}` | `{axis}` | `{role}` | {score} | `{roles}` |".format(
                card=row.get("card_name"),
                axis=row.get("selected_for_axis"),
                role=row.get("replaces_cut_role"),
                score=row.get("score"),
                roles=", ".join(row.get("profile_roles") or []),
            )
        )
    lines.extend(["", "## Source Lane Diagnostics", ""])
    for row in payload["source_lane_diagnostics"]:
        lines.append(
            "- `{axis}`: ready `{ready}`, selected `{selected}`, cut_role `{role}`".format(
                axis=row.get("required_add_axis"),
                ready=row.get("ready_candidate_count"),
                selected=row.get("selected_add_count"),
                role=row.get("cut_role"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--source-lane-report", type=Path, default=DEFAULT_SOURCE_LANE_REPORT)
    parser.add_argument("--package-size-limit", type=int, default=DEFAULT_PACKAGE_SIZE_LIMIT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        source_lane_report=args.source_lane_report,
        package_size_limit=args.package_size_limit,
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
