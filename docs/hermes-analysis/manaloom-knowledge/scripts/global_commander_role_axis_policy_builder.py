#!/usr/bin/env python3
"""Build role-axis policy before repeating blocked same-deck loops.

This read-only gate follows
``global_commander_cross_commander_role_axis_learning_pivot``. It turns a
cross-commander role axis, such as global ``engine`` saturation, into explicit
policy boundaries for later candidate/cut modeling. It does not choose cards,
copy decks, run battles, mutate databases, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
DEFAULT_PIVOT_REPORT = (
    REPORT_DIR / "global_commander_cross_commander_role_axis_learning_pivot_20260706_engine_axis_exhaustion_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_role_axis_policy_builder_20260706_post_engine_axis_exhaustion_current"

CAPACITY_ROLES = {"engine", "ramp", "draw", "tutor", "board_wipe", "recursion", "protection"}
FOUNDATION_FLOOR_ROLES = {"land", "removal", "wincon"}
SOURCE_CYCLE_STATUS = "cross_commander_role_axis_blocks_same_deck_source_cycle"
ENGINE_AXIS_SUPPRESSED_STATUS = "cross_commander_role_axis_suppressed_engine_axis_exhausted"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def cycle_deck_ids(axis_rows: list[Mapping[str, Any]]) -> list[str]:
    ids: list[str] = []
    for row in axis_rows:
        for deck_id in row.get("source_cycle_blocked_decks") or []:
            if deck_id and deck_id not in ids:
                ids.append(str(deck_id))
    return ids


def engine_axis_exhausted_deck_ids(axis_rows: list[Mapping[str, Any]]) -> list[str]:
    ids: list[str] = []
    for row in axis_rows:
        for deck_id in row.get("engine_axis_exhausted_decks") or []:
            if deck_id and deck_id not in ids:
                ids.append(str(deck_id))
    return ids


def role_axis_exhausted_deck_ids(axis_rows: list[Mapping[str, Any]]) -> list[str]:
    ids: list[str] = []
    for row in axis_rows:
        for deck_id in row.get("role_axis_exhausted_decks") or []:
            if deck_id and deck_id not in ids:
                ids.append(str(deck_id))
    return ids


def evidence_for_deck(axis_rows: list[Mapping[str, Any]], deck_id: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for axis in axis_rows:
        for evidence in axis.get("evidence_rows") or []:
            if str(evidence.get("deck_id") or "") == deck_id:
                rows.append(
                    {
                        "role": axis.get("role"),
                        "direction": evidence.get("direction"),
                        "count": evidence.get("count"),
                        "min": evidence.get("min"),
                        "max": evidence.get("max"),
                        "commander": evidence.get("commander"),
                        "deck_name": evidence.get("deck_name"),
                        "source_cycle_blocks_same_deck_search": bool(
                            evidence.get("source_cycle_blocks_same_deck_search")
                        ),
                        "deck_engine_axis_exhausted_requires_global_pivot": bool(
                            evidence.get("deck_engine_axis_exhausted_requires_global_pivot")
                        ),
                        "engine_axis_exhaustion_blocks_this_axis": bool(
                            evidence.get("engine_axis_exhaustion_blocks_this_axis")
                        ),
                        "deck_role_axis_exhausted_requires_global_pivot": bool(
                            evidence.get("deck_role_axis_exhausted_requires_global_pivot")
                        ),
                        "role_axis_exhaustion_blocks_this_axis": bool(
                            evidence.get("role_axis_exhaustion_blocks_this_axis")
                        ),
                    }
                )
    rows.sort(key=lambda row: (row["direction"] != "below_floor", str(row["role"])))
    return rows


def pressure_class(axis: Mapping[str, Any]) -> str:
    role = str(axis.get("role") or "")
    below = int(axis.get("below_floor_deck_count") or 0)
    above = int(axis.get("above_range_deck_count") or 0)
    if role in FOUNDATION_FLOOR_ROLES and below and below >= above:
        return "floor_repair_axis"
    if role in CAPACITY_ROLES and above and above >= below:
        return "ceiling_saturation_axis"
    if below and above:
        return "mixed_floor_and_ceiling_axis"
    if below:
        return "floor_repair_axis"
    if above:
        return "ceiling_saturation_axis"
    return "needs_axis_input_review"


def axis_policy_status(axis: Mapping[str, Any], cls: str) -> str:
    if axis.get("axis_suppressed_by_role_axis_exhaustion"):
        return "role_axis_policy_holds_exhausted_role_axis"
    if (
        axis.get("status") == ENGINE_AXIS_SUPPRESSED_STATUS
        or axis.get("axis_suppressed_by_engine_axis_exhaustion")
    ):
        return "role_axis_policy_holds_exhausted_engine_axis"
    if int(axis.get("source_cycle_blocked_deck_count") or 0):
        return "role_axis_policy_blocks_same_deck_source_cycle"
    if cls == "ceiling_saturation_axis":
        return "role_axis_policy_ready_for_ceiling_calibration"
    if cls == "floor_repair_axis":
        return "role_axis_policy_ready_for_floor_calibration"
    return "role_axis_policy_ready_for_mixed_calibration"


def policy_actions(axis: Mapping[str, Any], cls: str) -> list[str]:
    role = str(axis.get("role") or "")
    actions: list[str] = []
    if axis.get("axis_suppressed_by_role_axis_exhaustion"):
        actions.extend(
            [
                f"hold_{role}_axis_after_current_cut_lane_exhaustion",
                "choose_next_non_exhausted_role_axis_policy",
                f"require_new_card_level_usage_or_same_lane_evidence_before_{role}_reentry",
            ]
        )
    elif role == "engine" and (
        axis.get("status") == ENGINE_AXIS_SUPPRESSED_STATUS
        or axis.get("axis_suppressed_by_engine_axis_exhaustion")
    ):
        actions.extend(
            [
                "hold_engine_axis_after_biotransference_protection_exhaustion",
                "choose_next_non_exhausted_role_axis_policy",
                "require_new_card_level_usage_or_same_lane_evidence_before_engine_reentry",
            ]
        )
    elif role == "engine":
        actions.extend(
            [
                "treat_engine_as_capacity_ceiling_not_missing_role",
                "split_engine_cards_by_primary_function_before_cut_selection",
                "protect_engine_cards_that_also_cover_missing_floor_roles_or_commander_plan",
                "prefer_engine_only_or_overlapping_excess_role_cards_as_cut_pressure",
            ]
        )
    elif cls == "ceiling_saturation_axis":
        actions.extend(
            [
                f"treat_{role}_above_range_as_cut_pressure_not_add_lane",
                f"protect_{role}_cards_that_cover_missing_floor_roles",
            ]
        )
    elif cls == "floor_repair_axis":
        actions.extend(
            [
                f"treat_{role}_below_floor_as_add_or_source_lane_requirement",
                f"do_not_cut_cards_covering_{role}_until_floor_is_repaired",
            ]
        )
    else:
        actions.append(f"split_{role}_floor_and_ceiling_cases_before_candidate_copy")
    if int(axis.get("source_cycle_blocked_deck_count") or 0):
        actions.append("block_more_same_deck_source_expansion_until_axis_policy_is_applied")
    return actions


def next_gate_for_axis(axis: Mapping[str, Any], cls: str) -> str:
    role = str(axis.get("role") or "")
    if axis.get("axis_suppressed_by_role_axis_exhaustion"):
        return f"choose_next_non_exhausted_role_axis_after_{role}_axis_exhaustion"
    if role == "engine" and (
        axis.get("status") == ENGINE_AXIS_SUPPRESSED_STATUS
        or axis.get("axis_suppressed_by_engine_axis_exhaustion")
    ):
        return "choose_next_non_exhausted_role_axis_after_engine_axis_exhaustion"
    if int(axis.get("source_cycle_blocked_deck_count") or 0):
        if role == "engine":
            return "apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion"
        return f"apply_{role}_axis_policy_before_more_same_deck_source_expansion"
    if cls == "ceiling_saturation_axis":
        return f"calibrate_{role}_ceiling_policy_before_strategy_matrix"
    if cls == "floor_repair_axis":
        return f"calibrate_{role}_floor_policy_before_candidate_copy"
    return f"calibrate_{role}_mixed_axis_policy_before_candidate_copy"


def build_axis_policy_rows(axis_rows: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for axis in axis_rows:
        cls = pressure_class(axis)
        row = {
            "role": axis.get("role"),
            "status": axis_policy_status(axis, cls),
            "pressure_class": cls,
            "priority_score": int(axis.get("priority_score") or 0),
            "actionable_deck_count": int(axis.get("actionable_deck_count") or 0),
            "commander_count": int(axis.get("commander_count") or 0),
            "below_floor_deck_count": int(axis.get("below_floor_deck_count") or 0),
            "above_range_deck_count": int(axis.get("above_range_deck_count") or 0),
            "source_cycle_blocked_deck_count": int(axis.get("source_cycle_blocked_deck_count") or 0),
            "source_cycle_blocked_decks": list(axis.get("source_cycle_blocked_decks") or []),
            "engine_axis_exhausted_deck_count": int(axis.get("engine_axis_exhausted_deck_count") or 0),
            "engine_axis_exhausted_decks": list(axis.get("engine_axis_exhausted_decks") or []),
            "role_axis_exhausted_deck_count": int(axis.get("role_axis_exhausted_deck_count") or 0),
            "role_axis_exhausted_decks": list(axis.get("role_axis_exhausted_decks") or []),
            "role_axis_exhausted_role": axis.get("role_axis_exhausted_role"),
            "axis_suppressed_by_engine_axis_exhaustion": bool(
                axis.get("axis_suppressed_by_engine_axis_exhaustion")
            ),
            "axis_suppressed_by_role_axis_exhaustion": bool(
                axis.get("axis_suppressed_by_role_axis_exhaustion")
            ),
            "policy_actions": policy_actions(axis, cls),
            "next_gate": next_gate_for_axis(axis, cls),
            "deck_action_allowed": False,
            "candidate_copy_allowed": False,
            "battle_gate_allowed": False,
            "promotion_allowed": False,
        }
        rows.append(row)
    rows.sort(key=lambda row: (-row["priority_score"], row["role"]))
    return rows


def choose_status(policy_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not policy_rows:
        return ("role_axis_policy_builder_blocks_no_axis", "recheck_cross_commander_role_axis_pivot")
    if any(row.get("status") == "role_axis_policy_holds_exhausted_role_axis" for row in policy_rows):
        if any(row.get("status") == "role_axis_policy_blocks_same_deck_source_cycle" for row in policy_rows):
            return (
                "role_axis_policy_ready_after_role_axis_exhaustion_blocks_same_deck_source_cycle",
                str(policy_rows[0].get("next_gate") or ""),
            )
        return (
            "role_axis_policy_ready_after_role_axis_exhaustion_no_deck_action",
            str(policy_rows[0].get("next_gate") or ""),
        )
    if any(row.get("status") == "role_axis_policy_holds_exhausted_engine_axis" for row in policy_rows):
        if any(row.get("status") == "role_axis_policy_blocks_same_deck_source_cycle" for row in policy_rows):
            return (
                "role_axis_policy_ready_after_engine_axis_exhaustion_blocks_same_deck_source_cycle",
                str(policy_rows[0].get("next_gate") or ""),
            )
        return (
            "role_axis_policy_ready_after_engine_axis_exhaustion_no_deck_action",
            str(policy_rows[0].get("next_gate") or ""),
        )
    if any(row.get("status") == "role_axis_policy_blocks_same_deck_source_cycle" for row in policy_rows):
        return ("role_axis_policy_ready_blocks_same_deck_source_cycle", str(policy_rows[0].get("next_gate") or ""))
    return ("role_axis_policy_ready_no_deck_action", str(policy_rows[0].get("next_gate") or ""))


def build_report(*, pivot_report: Path) -> dict[str, Any]:
    pivot_payload = load_json(pivot_report)
    axis_rows = [
        dict(row)
        for row in pivot_payload.get("axis_rows") or []
        if isinstance(row, Mapping)
    ]
    policy_rows = build_axis_policy_rows(axis_rows)
    status, next_gate = choose_status(policy_rows)
    cycle_ids = cycle_deck_ids(axis_rows)
    engine_axis_ids = engine_axis_exhausted_deck_ids(axis_rows)
    role_axis_ids = role_axis_exhausted_deck_ids(axis_rows)
    cycle_evidence = {deck_id: evidence_for_deck(axis_rows, deck_id) for deck_id in cycle_ids}
    engine_axis_evidence = {
        deck_id: evidence_for_deck(axis_rows, deck_id) for deck_id in engine_axis_ids
    }
    role_axis_evidence = {
        deck_id: evidence_for_deck(axis_rows, deck_id) for deck_id in role_axis_ids
    }
    policy_status_counts = Counter(str(row.get("status") or "unknown") for row in policy_rows)
    pressure_counts = Counter(str(row.get("pressure_class") or "unknown") for row in policy_rows)
    top = policy_rows[0] if policy_rows else {}
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_role_axis_policy_builder",
        "contract": rel(COMMANDER_CONTRACT),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {"cross_commander_role_axis_pivot": artifact_rel(pivot_report)},
        "summary": {
            "policy_axis_count": len(policy_rows),
            "top_policy_role": top.get("role", ""),
            "top_policy_status": top.get("status", ""),
            "top_pressure_class": top.get("pressure_class", ""),
            "source_cycle_deck_count": len(cycle_ids),
            "engine_axis_exhausted_deck_count": len(engine_axis_ids),
            "role_axis_exhausted_deck_count": len(role_axis_ids),
            "held_engine_axis_count": sum(
                1 for row in policy_rows if row.get("status") == "role_axis_policy_holds_exhausted_engine_axis"
            ),
            "held_role_axis_count": sum(
                1 for row in policy_rows if row.get("status") == "role_axis_policy_holds_exhausted_role_axis"
            ),
            "candidate_copy_allowed_count": 0,
            "battle_gate_allowed_count": 0,
            "policy_status_counts": dict(sorted(policy_status_counts.items())),
            "pressure_class_counts": dict(sorted(pressure_counts.items())),
            "next_gate": next_gate,
        },
        "axis_policy_rows": policy_rows,
        "source_cycle_deck_role_pressure": cycle_evidence,
        "engine_axis_exhausted_deck_role_pressure": engine_axis_evidence,
        "role_axis_exhausted_deck_role_pressure": role_axis_evidence,
        "candidate_copy_blockers": [
            "role_axis_policy_is_not_card_level_cut_permission",
            "engine_saturation_policy_must_be_applied_before_more_same_deck_source_expansion",
            "source_cycle_decks_need_axis_policy_applied_to_cut_model",
            "exhausted_engine_axis_cannot_reenter_without_new_card_level_evidence",
            "exhausted_role_axis_cannot_reenter_without_new_card_level_evidence",
            "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
        ],
        "policy": {
            "engine_boundary": "Engine is a capacity/ceiling role when globally above range; it is not a missing-role add lane by itself.",
            "engine_axis_exhaustion_boundary": "A protected and exhausted engine axis is held as evidence, not chosen again as the top policy axis without new proof.",
            "role_axis_exhaustion_boundary": "Any exhausted role axis is held as evidence, not chosen again as the top policy axis without new proof.",
            "cut_boundary": "Cut pressure may target engine-only or excess-overlap cards only after protecting cards that cover missing floors or commander plan.",
            "cycle_boundary": "A source-cycle deck cannot repeat same-deck source expansion until the axis policy is applied to its cut model.",
            "mutation_boundary": "This builder does not choose cards, copy decks, run battles, mutate DBs, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Role Axis Policy Builder",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- policy_axis_count: `{summary['policy_axis_count']}`",
        f"- top_policy_role: `{summary['top_policy_role']}`",
        f"- top_policy_status: `{summary['top_policy_status']}`",
        f"- top_pressure_class: `{summary['top_pressure_class']}`",
        f"- source_cycle_deck_count: `{summary['source_cycle_deck_count']}`",
        f"- engine_axis_exhausted_deck_count: `{summary['engine_axis_exhausted_deck_count']}`",
        f"- role_axis_exhausted_deck_count: `{summary['role_axis_exhausted_deck_count']}`",
        f"- held_engine_axis_count: `{summary['held_engine_axis_count']}`",
        f"- held_role_axis_count: `{summary['held_role_axis_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Axis Policy Queue",
        "",
        "| Role | Status | Class | Decks | Commanders | Below | Above | Cycle Decks | Engine Exhausted Decks | Role Axis Exhausted Decks | Next Gate |",
        "| --- | --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- |",
    ]
    for row in payload["axis_policy_rows"]:
        cycle = ", ".join(row.get("source_cycle_blocked_decks") or []) or "-"
        engine_exhausted = ", ".join(row.get("engine_axis_exhausted_decks") or []) or "-"
        role_exhausted = ", ".join(row.get("role_axis_exhausted_decks") or []) or "-"
        lines.append(
            "| `{role}` | `{status}` | `{cls}` | {decks} | {commanders} | {below} | {above} | `{cycle}` | `{engine}` | `{role_exhausted}` | `{next}` |".format(
                role=row.get("role"),
                status=row.get("status"),
                cls=row.get("pressure_class"),
                decks=row.get("actionable_deck_count"),
                commanders=row.get("commander_count"),
                below=row.get("below_floor_deck_count"),
                above=row.get("above_range_deck_count"),
                cycle=cycle,
                engine=engine_exhausted,
                role_exhausted=role_exhausted,
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Top Policy Actions", ""])
    top = payload["axis_policy_rows"][0] if payload["axis_policy_rows"] else None
    if top:
        for action in top.get("policy_actions") or []:
            lines.append(f"- `{action}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Source-Cycle Deck Role Pressure", ""])
    for deck_id, rows in payload["source_cycle_deck_role_pressure"].items():
        lines.append(f"### Deck `{deck_id}`")
        lines.append("")
        lines.append("| Role | Direction | Count | Target | Commander |")
        lines.append("| --- | --- | ---: | --- | --- |")
        for row in rows:
            target = f"{row.get('min')}-{row.get('max')}"
            lines.append(
                "| `{role}` | `{direction}` | {count} | `{target}` | `{commander}` |".format(
                    role=row.get("role"),
                    direction=row.get("direction"),
                    count=row.get("count"),
                    target=target,
                    commander=str(row.get("commander") or "").replace("|", "/"),
                )
            )
        lines.append("")
    lines.extend(["## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pivot-report", type=Path, default=DEFAULT_PIVOT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(pivot_report=args.pivot_report)
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
