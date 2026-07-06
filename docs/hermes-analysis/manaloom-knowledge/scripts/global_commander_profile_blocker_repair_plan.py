#!/usr/bin/env python3
"""Turn Commander package strategy blockers into a repair plan.

This is a read-only follow-up gate for
global_commander_candidate_package_strategy_matrix.py. It does not create a
deck, run battles, mutate SQLite/PostgreSQL, or promote candidates. Its job is
to make blockers actionable before another candidate copy is materialized.
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
DEFAULT_STRATEGY_MATRIX = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5"
)

ROLE_TO_PACKAGE = {
    "angels_demons_dragons_payoffs": "angels_demons_dragons_payoffs",
    "spot_interaction": "interaction_and_resets",
    "haste_protection_silence": "commander_attack_enablers",
    "reanimation_plan_b": "reanimation_plan_b",
}

ROLE_SOURCE_LANES = {
    "lands": [
        "global_commander_mana_base_profile",
        "global_commander_named_land_candidate_pool",
        "same_lane_land_cut_review",
    ],
    "angels_demons_dragons_payoffs": [
        "commander_reference_profile_expected_packages",
        "oracle_type_identity_legal_filter",
        "source_lane_payoff_density_review",
    ],
    "spot_interaction": [
        "commander_reference_profile_interaction_package",
        "oracle_targeted_interaction_filter",
        "same_lane_nonprotected_cut_review",
    ],
    "haste_protection_silence": [
        "commander_attack_enabler_package",
        "protection_silence_source_lane_review",
        "same_lane_attack_window_cut_review",
    ],
    "board_wipes_resets": [
        "commander_reference_profile_interaction_package",
        "oracle_reset_filter",
        "same_lane_reset_cut_review",
    ],
    "card_draw_selection": [
        "card_flow_source_lane_review",
        "same_lane_draw_cut_review",
    ],
    "tutors_access": [
        "tutor_access_source_lane_review",
        "same_lane_tutor_cut_review",
    ],
    "reanimation_plan_b": [
        "commander_reference_profile_reanimation_package",
        "oracle_reanimation_filter",
        "same_lane_plan_b_cut_review",
    ],
    "dedicated_win_conditions": [
        "commander_win_plan_source_lane_review",
        "same_lane_wincon_cut_review",
    ],
}

CORE_ROLE_MINIMUMS = {
    "land": 34,
    "ramp": 8,
    "draw": 8,
    "removal": 6,
    "board_wipe": 2,
    "protection": 3,
    "recursion": 1,
    "wincon": 3,
    "engine": 4,
}

CORE_ROLE_REPAIR_SOURCE_LANES = {
    "removal": ROLE_SOURCE_LANES["spot_interaction"],
    "land": ROLE_SOURCE_LANES["lands"],
    "draw": ROLE_SOURCE_LANES["card_draw_selection"],
    "board_wipe": ROLE_SOURCE_LANES["board_wipes_resets"],
    "protection": ROLE_SOURCE_LANES["haste_protection_silence"],
    "recursion": ROLE_SOURCE_LANES["reanimation_plan_b"],
    "wincon": ROLE_SOURCE_LANES["dedicated_win_conditions"],
}

CORE_ROLE_TO_PACKAGE_ROLE = {
    "removal": "spot_interaction",
    "land": "lands",
    "draw": "card_draw_selection",
    "board_wipe": "board_wipes_resets",
    "protection": "haste_protection_silence",
    "recursion": "reanimation_plan_b",
    "wincon": "dedicated_win_conditions",
}


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


def repo_path(path: str | Path) -> Path:
    candidate = Path(path)
    return candidate if candidate.is_absolute() else REPO_ROOT / candidate


def package_chain_payload(strategy_matrix: Mapping[str, Any]) -> dict[str, Any]:
    input_artifacts = strategy_matrix.get("input_artifacts") or {}
    package_chain_report = input_artifacts.get("package_chain_report")
    if not package_chain_report:
        return {}
    path = repo_path(str(package_chain_report))
    if not path.exists():
        return {}
    return load_json(path)


def target_by_role(strategy_matrix: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    result = {}
    for row in strategy_matrix.get("target_evaluations") or []:
        if isinstance(row, dict) and row.get("role"):
            result[str(row["role"])] = dict(row)
    return result


def missing_expected_cards(strategy_matrix: Mapping[str, Any], role: str) -> list[str]:
    package = ROLE_TO_PACKAGE.get(role)
    if not package:
        return []
    packages = strategy_matrix.get("candidate_expected_package_presence") or {}
    payload = packages.get(package) if isinstance(packages, dict) else None
    if not isinstance(payload, dict):
        return []
    return [str(card) for card in payload.get("missing_cards") or []]


def over_target_rows(strategy_matrix: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in strategy_matrix.get("target_evaluations") or []:
        if isinstance(row, dict) and row.get("candidate_status") == "above_target_review":
            rows.append(
                {
                    "role": row.get("role"),
                    "candidate_count": row.get("candidate_count"),
                    "max": row.get("max"),
                    "overage": int(row.get("candidate_count") or 0) - int(row.get("max") or 0),
                    "cut_policy": "review only; never cut cards carrying blocker roles or attack-window risk",
                }
            )
    return rows


def attack_window_cut_rows(strategy_matrix: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in strategy_matrix.get("package_delta") or []:
        if not isinstance(row, dict):
            continue
        if row.get("action") != "cut":
            continue
        risk_flags = [str(flag) for flag in row.get("risk_flags") or []]
        if "attack_window_or_extra_combat_cut" in risk_flags:
            rows.append(
                {
                    "card": row.get("card"),
                    "risk_flags": risk_flags,
                    "repair_policy": "restore this lane or add same-lane attack enabler before replay",
                }
            )
    return rows


def package_delta_card_row(strategy_matrix: Mapping[str, Any], card_name: str) -> dict[str, Any]:
    for row in strategy_matrix.get("package_delta") or []:
        if not isinstance(row, dict):
            continue
        if str(row.get("card") or "") == card_name:
            return dict(row)
    return {}


def role_repair_action(strategy_matrix: Mapping[str, Any], role: str, target_row: Mapping[str, Any]) -> dict[str, Any]:
    shortfall = max(0, int(target_row.get("min") or 0) - int(target_row.get("candidate_count") or 0))
    return {
        "blocker": f"profile_{role}_below_target",
        "repair_axis": role,
        "candidate_count": int(target_row.get("candidate_count") or 0),
        "target_min": int(target_row.get("min") or 0),
        "target_max": int(target_row.get("max") or 0),
        "shortfall_to_min": shortfall,
        "source_lanes": ROLE_SOURCE_LANES.get(role, ["commander_profile_source_lane_review"]),
        "missing_expected_package_cards": missing_expected_cards(strategy_matrix, role),
        "battle_policy": "repair and rerun package strategy matrix before any equal battle probe",
        "cut_policy": "use same-lane or proven excess cuts only; do not cut attack-window, hard-floor, or source-anchor cards",
    }


def protected_anchor_repair_action(strategy_matrix: Mapping[str, Any], blocker: str) -> dict[str, Any]:
    card_name = blocker.removeprefix("protected_profile_anchor_cut:")
    delta_row = package_delta_card_row(strategy_matrix, card_name)
    return {
        "blocker": blocker,
        "repair_axis": "protected_profile_anchor",
        "protected_card": card_name,
        "affected_profile_roles": [str(role) for role in delta_row.get("profile_roles") or []],
        "risk_flags": [str(flag) for flag in delta_row.get("risk_flags") or []],
        "source_lanes": [
            "restore_protected_anchor_to_candidate_package",
            "same_lane_replacement_proof_for_protected_anchor",
            "commander_expected_package_anchor_review",
        ],
        "missing_expected_package_cards": [card_name],
        "battle_policy": "restore the protected anchor or prove a same-lane replacement before rerunning strategy matrix",
        "cut_policy": "do not materialize, battle, or promote a package that leaves protected commander anchors cut",
    }


def attack_window_repair_action(strategy_matrix: Mapping[str, Any]) -> dict[str, Any]:
    missing_attack_enablers = missing_expected_cards_for_package(strategy_matrix, "commander_attack_enablers")
    return {
        "blocker": "attack_window_cut_without_replacement",
        "repair_axis": "commander_attack_window",
        "cut_cards": attack_window_cut_rows(strategy_matrix),
        "source_lanes": ROLE_SOURCE_LANES["haste_protection_silence"],
        "missing_expected_package_cards": missing_attack_enablers,
        "battle_policy": "restore or replace attack-window function before replay",
        "cut_policy": "interaction upgrades cannot hide extra-combat, equipment, haste, or attack-trigger cuts",
    }


def missing_expected_cards_for_package(strategy_matrix: Mapping[str, Any], package: str) -> list[str]:
    packages = strategy_matrix.get("candidate_expected_package_presence") or {}
    payload = packages.get(package) if isinstance(packages, dict) else None
    if not isinstance(payload, dict):
        return []
    return [str(card) for card in payload.get("missing_cards") or []]


def package_core_floor_repair_actions(
    strategy_matrix: Mapping[str, Any],
    package_chain: Mapping[str, Any],
) -> list[dict[str, Any]]:
    summary = package_chain.get("summary") or {}
    role_counts = summary.get("final_role_counts") or {}
    role_statuses = summary.get("final_role_statuses") or {}
    actions = []
    for role, status in sorted(role_statuses.items()):
        if status != "below_floor":
            continue
        count = int(role_counts.get(role) or 0)
        target_min = int(CORE_ROLE_MINIMUMS.get(str(role), 0))
        package_role = CORE_ROLE_TO_PACKAGE_ROLE.get(str(role), str(role))
        actions.append(
            {
                "blocker": "package_core_floor_not_repaired",
                "repair_axis": f"core_{role}_floor",
                "core_role": role,
                "candidate_count": count,
                "target_min": target_min,
                "target_max": "-",
                "shortfall_to_min": max(0, target_min - count),
                "source_lanes": CORE_ROLE_REPAIR_SOURCE_LANES.get(
                    str(role),
                    ["manual_core_floor_source_lane_review"],
                ),
                "missing_expected_package_cards": missing_expected_cards(strategy_matrix, package_role),
                "battle_policy": "repair core role floor and rerun package strategy matrix before any equal battle probe",
                "cut_policy": "use same-lane or proven excess cuts only; do not cut hard-floor, attack-window, or source-anchor cards",
            }
        )
    return actions


def repair_sequence(actions: list[dict[str, Any]]) -> list[str]:
    blockers = {str(action.get("blocker")) for action in actions}
    sequence = []
    if any(
        action.get("blocker") == "package_core_floor_not_repaired"
        and action.get("repair_axis") == "core_removal_floor"
        for action in actions
    ):
        sequence.append("repair_core_removal_floor_with_spot_interaction_source_lane")
    if "attack_window_cut_without_replacement" in blockers:
        sequence.append("repair_or_restore_commander_attack_window_before_more_interaction")
    if "profile_lands_below_target" in blockers:
        sequence.append("repair_mana_base_to_commander_land_floor")
    if "profile_angels_demons_dragons_payoffs_below_target" in blockers:
        sequence.append("repair_commander_payoff_density_with_legal_source_lanes")
    if "profile_spot_interaction_below_target" in blockers:
        sequence.append("finish_spot_interaction_floor_with_same_lane_cut")
    protected_anchor_cards = [
        str(action.get("protected_card"))
        for action in actions
        if str(action.get("blocker")).startswith("protected_profile_anchor_cut:")
    ]
    for card in protected_anchor_cards:
        sequence.append(f"restore_or_same_lane_replace_protected_anchor:{card}")
    remaining = [
        str(action.get("repair_axis"))
        for action in actions
        if str(action.get("blocker"))
        not in {
            "attack_window_cut_without_replacement",
            "package_core_floor_not_repaired",
            "profile_lands_below_target",
            "profile_angels_demons_dragons_payoffs_below_target",
            "profile_spot_interaction_below_target",
        }
        and not str(action.get("blocker")).startswith("protected_profile_anchor_cut:")
    ]
    sequence.extend(f"repair_{role}" for role in remaining)
    if actions:
        sequence.append("rerun_global_commander_candidate_package_strategy_matrix")
    else:
        sequence.append("run_equal_battle_probe_with_replay_exposure")
    return sequence


def build_report(*, strategy_matrix_report: Path) -> dict[str, Any]:
    strategy_matrix = load_json(strategy_matrix_report)
    package_chain = package_chain_payload(strategy_matrix)
    blockers = [str(blocker) for blocker in strategy_matrix.get("blocker_reasons") or []]
    targets = target_by_role(strategy_matrix)
    actions: list[dict[str, Any]] = []
    for blocker in blockers:
        if blocker.startswith("profile_") and blocker.endswith("_below_target"):
            role = blocker.removeprefix("profile_").removesuffix("_below_target")
            target_row = targets.get(role)
            if target_row:
                actions.append(role_repair_action(strategy_matrix, role, target_row))
            else:
                actions.append(
                    {
                        "blocker": blocker,
                        "repair_axis": role,
                        "source_lanes": ["commander_profile_source_lane_review"],
                        "battle_policy": "rerun strategy matrix after target evidence is restored",
                        "cut_policy": "do not materialize blind cuts",
                    }
                )
        elif blocker == "attack_window_cut_without_replacement":
            actions.append(attack_window_repair_action(strategy_matrix))
        elif blocker.startswith("protected_profile_anchor_cut:"):
            actions.append(protected_anchor_repair_action(strategy_matrix, blocker))
        elif blocker == "package_core_floor_not_repaired":
            core_actions = package_core_floor_repair_actions(strategy_matrix, package_chain)
            if core_actions:
                actions.extend(core_actions)
            else:
                actions.append(
                    {
                        "blocker": blocker,
                        "repair_axis": "unclassified_core_floor_blocker",
                        "source_lanes": ["manual_core_floor_source_lane_review"],
                        "battle_policy": "resolve core floor blocker before battle",
                        "cut_policy": "do not promote or battle unclassified core-floor blockers",
                    }
                )
        else:
            actions.append(
                {
                    "blocker": blocker,
                    "repair_axis": "unclassified_profile_blocker",
                    "source_lanes": ["manual_commander_source_lane_review"],
                    "battle_policy": "resolve blocker before battle",
                    "cut_policy": "do not promote or battle unclassified package blockers",
                }
            )
    repair_needed = bool(actions)
    return {
        "generated_at": utc_now(),
        "status": "profile_blocker_repair_plan_ready" if repair_needed else "profile_strategy_ready_no_repair_needed",
        "artifact_type": "global_commander_profile_blocker_repair_plan",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False if repair_needed else bool(strategy_matrix.get("battle_gate_allowed_now")),
        "input_artifacts": {"strategy_matrix_report": rel(strategy_matrix_report)},
        "summary": {
            "deck_id": (strategy_matrix.get("summary") or {}).get("deck_id"),
            "commander": (strategy_matrix.get("summary") or {}).get("commander"),
            "source_strategy_status": strategy_matrix.get("status"),
            "blocker_count": len(blockers),
            "repair_action_count": len(actions),
            "next_gate": (
                "materialize_profile_repair_candidate_copy"
                if repair_needed
                else "run_equal_battle_probe_with_replay_exposure"
            ),
        },
        "source_blockers": blockers,
        "repair_actions": actions,
        "over_target_review_roles": over_target_rows(strategy_matrix),
        "recommended_repair_sequence": repair_sequence(actions),
        "policy": {
            "repair_boundary": "This plan names repair lanes only; it never mutates decks or opens promotion.",
            "battle_boundary": "Any blocker keeps equal battle probes closed until the strategy matrix is rerun clean.",
            "cut_boundary": "Above-target roles are candidate review pressure, not automatic cut authorization.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Blocker Repair Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- source_strategy_status: `{summary['source_strategy_status']}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- blocker_count: `{summary['blocker_count']}`",
        f"- repair_action_count: `{summary['repair_action_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Repair Actions",
        "",
        "| Blocker | Axis | Count | Target | Shortfall | Source Lanes |",
        "| --- | --- | ---: | --- | ---: | --- |",
    ]
    for action in payload["repair_actions"]:
        count = action.get("candidate_count", "-")
        target_min = action.get("target_min", "-")
        target_max = action.get("target_max", "-")
        target = "-" if target_min == "-" and target_max == "-" else f"{target_min}-{target_max}"
        shortfall = action.get("shortfall_to_min", "-")
        lanes = ", ".join(action.get("source_lanes") or [])
        lines.append(
            f"| `{action['blocker']}` | `{action['repair_axis']}` | {count} | `{target}` | {shortfall} | `{lanes}` |"
        )
    if not payload["repair_actions"]:
        lines.append("| none | none | 0 | `-` | 0 | `-` |")
    lines.extend(["", "## Repair Sequence", ""])
    for index, step in enumerate(payload["recommended_repair_sequence"], start=1):
        lines.append(f"{index}. `{step}`")
    lines.extend(["", "## Over-Target Review Roles", ""])
    if payload["over_target_review_roles"]:
        for row in payload["over_target_review_roles"]:
            lines.append(
                f"- `{row['role']}` candidate `{row['candidate_count']}` max `{row['max']}` overage `{row['overage']}`"
            )
    else:
        lines.append("- none")
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
    parser.add_argument("--strategy-matrix-report", type=Path, default=DEFAULT_STRATEGY_MATRIX)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(strategy_matrix_report=args.strategy_matrix_report)
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
