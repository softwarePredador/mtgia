#!/usr/bin/env python3
"""Synthesize a Commander payoff repair package before candidate materialization.

This read-only gate consumes the profile repair candidate model and the broader
payoff source-lane expansion. It selects a balanced package that would repair
the current commander profile blockers, estimates cut coverage, and keeps deck
mutation/battle closed unless the package is small, fully covered, and ready for
the existing isolated materializer chain.
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
DEFAULT_REPAIR_CANDIDATE_MODEL_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_PAYOFF_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5"
)

PAYOFF_AXIS = "angels_demons_dragons_payoffs"
SPELL_PAYOFF_AXIS = "spell_payoffs_copy_engines"
SUPPORTED_PAYOFF_AXES = (PAYOFF_AXIS, SPELL_PAYOFF_AXIS)
ATTACK_AXIS = "commander_attack_window"
LAND_AXIS = "lands"
SPOT_AXIS = "spot_interaction"
REANIMATION_AXIS = "reanimation_plan_b"
DEFAULT_AXIS_ORDER = (ATTACK_AXIS, LAND_AXIS, SPOT_AXIS, PAYOFF_AXIS, REANIMATION_AXIS)
READY_ADD_STATUSES = {
    "review_only_profile_repair_add_candidate",
    "review_only_named_land_candidate",
    "review_only_commander_payoff_source_candidate",
}
READY_CUT_STATUS = "review_only_profile_repair_cut_candidate"
MAX_PACKAGE_SWAPS_FOR_COPY = 8


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


def ready_add(row: Mapping[str, Any]) -> bool:
    return str(row.get("status") or "") in READY_ADD_STATUSES


def unique_by_name(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[str] = set()
    out: list[dict[str, Any]] = []
    for row in rows:
        name = str(row.get("card_name") or "")
        key = normalize_name(name)
        if not name or key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def axis_pool(profile_payload: Mapping[str, Any], axis: str) -> dict[str, Any]:
    for pool in profile_payload.get("repair_axis_pools") or []:
        if isinstance(pool, Mapping) and pool.get("repair_axis") == axis:
            return dict(pool)
    return {}


def payoff_axis(*, profile_payload: Mapping[str, Any], payoff_payload: Mapping[str, Any]) -> str:
    summary = payoff_payload.get("summary") or {}
    reported_axis = str(summary.get("repair_axis") or "")
    if reported_axis in SUPPORTED_PAYOFF_AXES:
        return reported_axis
    for pool in profile_payload.get("repair_axis_pools") or []:
        if isinstance(pool, Mapping) and pool.get("repair_axis") in SUPPORTED_PAYOFF_AXES:
            return str(pool.get("repair_axis"))
    return PAYOFF_AXIS


def axis_order_for(selected_payoff_axis: str) -> tuple[str, ...]:
    return (ATTACK_AXIS, LAND_AXIS, SPOT_AXIS, selected_payoff_axis, REANIMATION_AXIS)


def axis_candidates(profile_payload: Mapping[str, Any], axis: str) -> list[dict[str, Any]]:
    pool = axis_pool(profile_payload, axis)
    rows = [dict(row) for row in pool.get("top_add_candidates") or [] if isinstance(row, Mapping)]
    rows = [row for row in rows if ready_add(row)]
    rows.sort(key=lambda row: (-int(row.get("score") or 0), str(row.get("card_name") or "")))
    return unique_by_name(rows)


def payoff_candidates(payoff_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in payoff_payload.get("top_payoff_candidates") or []
        if isinstance(row, Mapping) and ready_add(row)
    ]
    rows.sort(key=lambda row: (-int(row.get("score") or 0), str(row.get("card_name") or "")))
    return unique_by_name(rows)


def ready_cut_candidates(profile_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in profile_payload.get("global_cut_review_pool") or []
        if isinstance(row, Mapping) and str(row.get("status") or READY_CUT_STATUS) == READY_CUT_STATUS
    ]
    rows.sort(key=lambda row: (-int(row.get("score") or 0), str(row.get("card_name") or "")))
    return unique_by_name(rows)


def initial_requirements(profile_payload: Mapping[str, Any], *, selected_payoff_axis: str) -> dict[str, int]:
    axis_order = axis_order_for(selected_payoff_axis)
    requirements = {axis: 0 for axis in axis_order}
    for axis in (LAND_AXIS, SPOT_AXIS, selected_payoff_axis, REANIMATION_AXIS):
        pool = axis_pool(profile_payload, axis)
        requirements[axis] = max(0, int(pool.get("shortfall_to_min") or 0))
    attack_pool = axis_pool(profile_payload, ATTACK_AXIS)
    if attack_pool and str(attack_pool.get("blocker") or "") == "attack_window_cut_without_replacement":
        requirements[ATTACK_AXIS] = 1
    return requirements


def candidate_roles(row: Mapping[str, Any]) -> set[str]:
    return {str(role) for role in row.get("profile_roles") or [] if role}


def cut_roles(row: Mapping[str, Any]) -> set[str]:
    roles = set(candidate_roles(row))
    roles.update(str(role) for role in row.get("core_roles") or [] if role)
    roles.update(str(role) for role in row.get("matching_over_target_roles") or [] if role)
    return roles


def covered_axes(
    *,
    row: Mapping[str, Any],
    selected_axis: str,
    remaining: Mapping[str, int],
    selected_payoff_axis: str,
) -> list[str]:
    roles = candidate_roles(row)
    covered: list[str] = []
    if selected_axis == ATTACK_AXIS and int(remaining.get(ATTACK_AXIS) or 0) > 0:
        covered.append(ATTACK_AXIS)
    if LAND_AXIS in roles and int(remaining.get(LAND_AXIS) or 0) > 0:
        covered.append(LAND_AXIS)
    if SPOT_AXIS in roles and int(remaining.get(SPOT_AXIS) or 0) > 0:
        covered.append(SPOT_AXIS)
    if selected_payoff_axis in roles and int(remaining.get(selected_payoff_axis) or 0) > 0:
        covered.append(selected_payoff_axis)
    if REANIMATION_AXIS in roles and int(remaining.get(REANIMATION_AXIS) or 0) > 0:
        covered.append(REANIMATION_AXIS)
    if selected_axis == LAND_AXIS and int(remaining.get(LAND_AXIS) or 0) > 0 and LAND_AXIS not in covered:
        covered.append(LAND_AXIS)
    if selected_axis == SPOT_AXIS and int(remaining.get(SPOT_AXIS) or 0) > 0 and SPOT_AXIS not in covered:
        covered.append(SPOT_AXIS)
    if (
        selected_axis == selected_payoff_axis
        and int(remaining.get(selected_payoff_axis) or 0) > 0
        and selected_payoff_axis not in covered
    ):
        covered.append(selected_payoff_axis)
    if (
        selected_axis == REANIMATION_AXIS
        and int(remaining.get(REANIMATION_AXIS) or 0) > 0
        and REANIMATION_AXIS not in covered
    ):
        covered.append(REANIMATION_AXIS)
    return covered


def select_add_package(
    *,
    profile_payload: Mapping[str, Any],
    payoff_payload: Mapping[str, Any],
    requirements: Mapping[str, int],
    selected_payoff_axis: str,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    axis_order = axis_order_for(selected_payoff_axis)
    remaining = {axis: int(requirements.get(axis) or 0) for axis in axis_order}
    selected: list[dict[str, Any]] = []
    seen: set[str] = set()
    candidates_by_axis = {
        ATTACK_AXIS: axis_candidates(profile_payload, ATTACK_AXIS),
        LAND_AXIS: axis_candidates(profile_payload, LAND_AXIS),
        SPOT_AXIS: axis_candidates(profile_payload, SPOT_AXIS),
        selected_payoff_axis: payoff_candidates(payoff_payload),
        REANIMATION_AXIS: axis_candidates(profile_payload, REANIMATION_AXIS),
    }
    for axis in axis_order:
        while remaining.get(axis, 0) > 0:
            picked: dict[str, Any] | None = None
            picked_coverage: list[str] = []
            for candidate in candidates_by_axis[axis]:
                name = str(candidate.get("card_name") or "")
                key = normalize_name(name)
                if not name or key in seen:
                    continue
                coverage = covered_axes(
                    row=candidate,
                    selected_axis=axis,
                    remaining=remaining,
                    selected_payoff_axis=selected_payoff_axis,
                )
                if not coverage:
                    continue
                picked = candidate
                picked_coverage = coverage
                break
            if picked is None:
                break
            name = str(picked.get("card_name") or "")
            seen.add(normalize_name(name))
            selected_row = dict(picked)
            selected_row["selected_for_axis"] = axis
            selected_row["covered_axes"] = picked_coverage
            selected_row["status"] = "review_only_synthesized_package_add"
            selected_row["mutation_allowed"] = False
            selected.append(selected_row)
            for covered in picked_coverage:
                remaining[covered] = max(0, int(remaining.get(covered) or 0) - 1)
    return selected, remaining


def select_cuts(
    profile_payload: Mapping[str, Any],
    add_count: int,
    *,
    protected_axes: set[str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    cuts = ready_cut_candidates(profile_payload)
    safe_cuts = [row for row in cuts if not (cut_roles(row) & protected_axes)]
    selected = []
    for row in safe_cuts[:add_count]:
        selected_row = dict(row)
        selected_row["status"] = "review_only_synthesized_package_cut"
        selected_row["mutation_allowed"] = False
        selected.append(selected_row)
    selected_keys = {normalize_name(str(row.get("card_name") or "")) for row in selected}
    remaining = [row for row in cuts if normalize_name(str(row.get("card_name") or "")) not in selected_keys]
    return selected, remaining


def pair_adds_and_cuts(adds: list[dict[str, Any]], cuts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    pairs = []
    for index, (add, cut) in enumerate(zip(adds, cuts), start=1):
        pairs.append(
            {
                "step": index,
                "add": add.get("card_name"),
                "cut": cut.get("card_name"),
                "add_axes": add.get("covered_axes") or [],
                "cut_reasons": cut.get("cut_reasons") or [],
                "cut_matching_over_target_roles": cut.get("matching_over_target_roles") or [],
                "status": "review_only_synthesized_add_cut_pair",
            }
        )
    return pairs


def blockers(
    *,
    remaining_requirements: Mapping[str, int],
    selected_add_count: int,
    selected_cut_count: int,
    payoff_payload: Mapping[str, Any],
) -> list[str]:
    out = []
    for axis, remaining in remaining_requirements.items():
        if int(remaining) > 0:
            out.append(f"{axis}:remaining_add_requirement_{remaining}")
    if selected_cut_count < selected_add_count:
        out.append(f"insufficient_reviewable_cuts_for_full_profile_package:required_{selected_add_count}_ready_{selected_cut_count}")
    if selected_add_count > MAX_PACKAGE_SWAPS_FOR_COPY:
        out.append(f"package_size_exceeds_materializer_review_limit:required_{selected_add_count}_limit_{MAX_PACKAGE_SWAPS_FOR_COPY}")
    if payoff_payload.get("status") != "commander_payoff_source_lane_expanded":
        out.append("payoff_source_lane_not_expanded")
    return out


def next_gate_for(blocker_rows: list[str]) -> str:
    if not blocker_rows:
        return "materialize_synthesized_commander_package_chain_copy"
    if any(row.startswith("insufficient_reviewable_cuts") for row in blocker_rows):
        return "expand_commander_cut_source_lane_for_full_profile_package"
    if any(row.startswith("package_size_exceeds") for row in blocker_rows):
        return "split_synthesized_package_into_smaller_strategy_stages"
    return "backfill_missing_profile_axis_source_lane_before_candidate_copy"


def build_report(
    *,
    repair_candidate_model_report: Path,
    payoff_source_lane_report: Path,
) -> dict[str, Any]:
    profile_payload = load_json(repair_candidate_model_report)
    payoff_payload = load_json(payoff_source_lane_report)
    profile_summary = profile_payload.get("summary") or {}
    payoff_summary = payoff_payload.get("summary") or {}
    selected_payoff_axis = payoff_axis(profile_payload=profile_payload, payoff_payload=payoff_payload)
    axis_order = axis_order_for(selected_payoff_axis)
    requirements = initial_requirements(profile_payload, selected_payoff_axis=selected_payoff_axis)
    selected_adds, remaining = select_add_package(
        profile_payload=profile_payload,
        payoff_payload=payoff_payload,
        requirements=requirements,
        selected_payoff_axis=selected_payoff_axis,
    )
    protected_axes = {axis for axis, required in requirements.items() if int(required or 0) > 0}
    selected_cuts, remaining_cuts = select_cuts(
        profile_payload,
        len(selected_adds),
        protected_axes=protected_axes,
    )
    blocker_rows = blockers(
        remaining_requirements=remaining,
        selected_add_count=len(selected_adds),
        selected_cut_count=len(selected_cuts),
        payoff_payload=payoff_payload,
    )
    candidate_copy_allowed = not blocker_rows and bool(selected_adds)
    return {
        "generated_at": utc_now(),
        "status": (
            "commander_payoff_package_synthesis_ready_for_candidate_copy"
            if candidate_copy_allowed
            else "commander_payoff_package_synthesis_blocks_candidate_copy"
        ),
        "artifact_type": "global_commander_payoff_package_synthesizer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": candidate_copy_allowed,
        "input_artifacts": {
            "repair_candidate_model_report": rel(repair_candidate_model_report),
            "payoff_source_lane_report": rel(payoff_source_lane_report),
        },
        "summary": {
            "deck_id": str(profile_summary.get("deck_id") or payoff_summary.get("deck_id") or ""),
            "commander": str(profile_summary.get("commander") or payoff_summary.get("commander") or ""),
            "commander_color_identity": profile_summary.get("commander_color_identity")
            or payoff_summary.get("commander_color_identity")
            or [],
            "payoff_axis": selected_payoff_axis,
            "axis_order": list(axis_order),
            "protected_cut_axes": sorted(protected_axes),
            "initial_axis_requirements": requirements,
            "remaining_axis_requirements": remaining,
            "selected_add_count": len(selected_adds),
            "selected_cut_count": len(selected_cuts),
            "unpaired_add_count": max(0, len(selected_adds) - len(selected_cuts)),
            "remaining_cut_candidate_count": len(remaining_cuts),
            "package_size_limit": MAX_PACKAGE_SWAPS_FOR_COPY,
            "candidate_copy_blocker_count": len(blocker_rows),
            "next_gate": next_gate_for(blocker_rows),
        },
        "candidate_copy_blockers": blocker_rows,
        "selected_add_package": selected_adds,
        "selected_cut_package": selected_cuts,
        "tentative_add_cut_pairs": pair_adds_and_cuts(selected_adds, selected_cuts),
        "unpaired_adds": selected_adds[len(selected_cuts) :],
        "remaining_cut_review_pool": remaining_cuts[:20],
        "policy": {
            "package_boundary": "A synthesized package is planning evidence, not a deck mutation.",
            "cut_boundary": "Every add needs a reviewed cut before candidate-copy materialization.",
            "size_boundary": f"Packages over {MAX_PACKAGE_SWAPS_FOR_COPY} swaps must be split or re-sourced before materialization.",
            "battle_boundary": "Battle and promotion remain closed until candidate copy, strategy matrix, and replay gates pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Payoff Package Synthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- selected_cut_count: `{summary['selected_cut_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- package_size_limit: `{summary['package_size_limit']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Requirements",
        "",
        "| Axis | Initial | Remaining |",
        "| --- | ---: | ---: |",
    ]
    for axis in summary.get("axis_order") or DEFAULT_AXIS_ORDER:
        lines.append(
            f"| `{axis}` | {summary['initial_axis_requirements'].get(axis, 0)} | {summary['remaining_axis_requirements'].get(axis, 0)} |"
        )
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Selected Adds", "", "| Add | Axis | Covers | Score | Roles |", "| --- | --- | --- | ---: | --- |"])
    for row in payload["selected_add_package"]:
        lines.append(
            "| `{name}` | `{axis}` | `{covered}` | {score} | `{roles}` |".format(
                name=row.get("card_name"),
                axis=row.get("selected_for_axis"),
                covered=", ".join(row.get("covered_axes") or []),
                score=row.get("score") or 0,
                roles=", ".join(row.get("profile_roles") or []) or "-",
            )
        )
    lines.extend(["", "## Tentative Add/Cut Pairs", "", "| Step | Add | Cut | Cut Rationale |", "| ---: | --- | --- | --- |"])
    for row in payload["tentative_add_cut_pairs"]:
        lines.append(
            "| {step} | `{add}` | `{cut}` | {why} |".format(
                step=row["step"],
                add=row["add"],
                cut=row["cut"],
                why=", ".join(row.get("cut_reasons") or row.get("cut_matching_over_target_roles") or []),
            )
        )
    if payload["unpaired_adds"]:
        lines.extend(["", "## Unpaired Adds", ""])
        for row in payload["unpaired_adds"]:
            lines.append(f"- `{row.get('card_name')}`: covers `{', '.join(row.get('covered_axes') or [])}`")
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
    parser.add_argument("--repair-candidate-model-report", type=Path, default=DEFAULT_REPAIR_CANDIDATE_MODEL_REPORT)
    parser.add_argument("--payoff-source-lane-report", type=Path, default=DEFAULT_PAYOFF_SOURCE_LANE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        repair_candidate_model_report=args.repair_candidate_model_report,
        payoff_source_lane_report=args.payoff_source_lane_report,
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
