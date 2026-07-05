#!/usr/bin/env python3
"""Split a synthesized Commander package into value-safe candidate stages.

This read-only gate consumes the synthesized add package and the expanded
value-safe cut lane. It forms candidate-copy stages no larger than the package
limit, keeps the full package blocked when adds are unpaired, and opens only the
next isolated stage-copy gate. It does not mutate SQLite/PostgreSQL, run
battles, or promote decks.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_CUT_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5"
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


def package_size_limit(package_payload: Mapping[str, Any], cut_payload: Mapping[str, Any]) -> int:
    package_summary = package_payload.get("summary") or {}
    cut_summary = cut_payload.get("summary") or {}
    return int(package_summary.get("package_size_limit") or cut_summary.get("package_size_limit") or 8)


def selected_adds(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in package_payload.get("selected_add_package") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def selected_cuts(cut_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in cut_payload.get("selected_value_safe_cuts") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def pair_rows(adds: list[dict[str, Any]], cuts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    pairs = []
    for index, (add, cut) in enumerate(zip(adds, cuts), start=1):
        pairs.append(
            {
                "pair_index": index,
                "add": add.get("card_name"),
                "cut": cut.get("card_name"),
                "add_axis": add.get("selected_for_axis") or add.get("axis"),
                "add_covered_axes": add.get("covered_axes") or [],
                "add_score": add.get("score") or 0,
                "cut_primary_role": cut.get("primary_cut_role"),
                "cut_matching_over_target_roles": cut.get("matching_over_target_roles") or [],
                "cut_score": cut.get("score") or 0,
                "status": "review_only_value_safe_stage_pair",
            }
        )
    return pairs


def split_stages(pairs: list[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
    stages = []
    for start in range(0, len(pairs), limit):
        stage_pairs = pairs[start : start + limit]
        stage_number = len(stages) + 1
        stages.append(
            {
                "stage": stage_number,
                "status": "stage_ready_for_candidate_copy",
                "pair_count": len(stage_pairs),
                "pairs": stage_pairs,
                "add_cards": [row["add"] for row in stage_pairs],
                "cut_cards": [row["cut"] for row in stage_pairs],
                "candidate_copy_allowed_now": True,
                "battle_gate_allowed_now": False,
                "promotion_allowed": False,
                "next_gate": f"materialize_value_safe_stage_{stage_number}_candidate_copy",
            }
        )
    return stages


def blockers(*, pair_count: int, add_count: int, stage_count: int) -> list[str]:
    out = []
    if pair_count < add_count:
        out.append(f"full_package_unpaired_adds:required_{add_count}_paired_{pair_count}")
    if stage_count == 0:
        out.append("no_value_safe_stage_ready")
    return out


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
    cuts = selected_cuts(cut_payload)
    limit = package_size_limit(package_payload, cut_payload)
    pairs = pair_rows(adds, cuts)
    stages = split_stages(pairs, limit)
    blocker_rows = blockers(pair_count=len(pairs), add_count=len(adds), stage_count=len(stages))
    stage_ready = bool(stages)
    full_package_ready = not blocker_rows and bool(pairs)
    return {
        "generated_at": utc_now(),
        "status": (
            "commander_value_safe_stage_split_ready_for_stage_candidate_copy"
            if stage_ready
            else "commander_value_safe_stage_split_blocks_candidate_copy"
        ),
        "artifact_type": "global_commander_value_safe_stage_splitter",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": stage_ready,
        "stage_candidate_copy_allowed_now": stage_ready,
        "full_package_candidate_copy_allowed_now": full_package_ready,
        "input_artifacts": {
            "package_synthesis_report": rel(package_synthesis_report),
            "cut_source_lane_report": rel(cut_source_lane_report),
        },
        "summary": {
            "deck_id": str(package_summary.get("deck_id") or cut_summary.get("deck_id") or ""),
            "commander": str(package_summary.get("commander") or cut_summary.get("commander") or ""),
            "selected_add_count": len(adds),
            "value_safe_cut_count": len(cuts),
            "paired_swap_count": len(pairs),
            "unpaired_add_count": max(0, len(adds) - len(pairs)),
            "stage_count": len(stages),
            "ready_stage_count": len(stages),
            "package_size_limit": limit,
            "full_package_candidate_copy_allowed_now": full_package_ready,
            "candidate_copy_blocker_count": len(blocker_rows),
            "next_gate": stages[0]["next_gate"] if stages else "backfill_value_safe_cuts_before_stage_copy",
        },
        "candidate_copy_blockers": blocker_rows,
        "stages": stages,
        "unpaired_adds": adds[len(pairs) :],
        "policy": {
            "stage_boundary": "A ready stage authorizes only an isolated candidate-copy stage, not full package mutation.",
            "full_package_boundary": "The full package remains blocked until every add has a value-safe cut.",
            "battle_boundary": "No battle or promotion opens until a stage copy passes strategy matrix and replay gates.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Value-Safe Stage Splitter",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- paired_swap_count: `{summary['paired_swap_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- stage_count: `{summary['stage_count']}`",
        f"- package_size_limit: `{summary['package_size_limit']}`",
        f"- stage_candidate_copy_allowed_now: `{str(payload['stage_candidate_copy_allowed_now']).lower()}`",
        f"- full_package_candidate_copy_allowed_now: `{str(payload['full_package_candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Blockers",
        "",
    ]
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Stages", ""])
    for stage in payload["stages"]:
        lines.extend(
            [
                f"### Stage {stage['stage']}",
                "",
                f"- status: `{stage['status']}`",
                f"- pair_count: `{stage['pair_count']}`",
                f"- candidate_copy_allowed_now: `{str(stage['candidate_copy_allowed_now']).lower()}`",
                f"- next_gate: `{stage['next_gate']}`",
                "",
                "| Step | Add | Cut | Add Axis | Cut Role |",
                "| ---: | --- | --- | --- | --- |",
            ]
        )
        for row in stage["pairs"]:
            lines.append(
                "| {step} | `{add}` | `{cut}` | `{axis}` | `{role}` |".format(
                    step=row["pair_index"],
                    add=row["add"],
                    cut=row["cut"],
                    axis=row.get("add_axis") or "",
                    role=row.get("cut_primary_role") or "",
                )
            )
        lines.append("")
    if payload["unpaired_adds"]:
        lines.extend(["## Unpaired Adds", ""])
        for row in payload["unpaired_adds"]:
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
