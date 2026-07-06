#!/usr/bin/env python3
"""Reorder profile-repair add/cut pairs after cut-pair review blocks.

This read-only gate consumes the profile-repair package resynthesis plus the
candidate model cut pool. It reassigns cuts so protected-anchor restores get
same-lane cuts before any land-floor cut review. It does not materialize a
candidate copy, mutate SQLite/PostgreSQL, run battles, or promote decks.
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
DEFAULT_PACKAGE_RESYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_package_resynthesizer_20260706_lorehold_land_floor_package_profile.json"
)
DEFAULT_CANDIDATE_MODEL_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260706_lorehold_land_floor_package_profile.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_repair_cut_pair_reorderer_20260706_lorehold_land_floor_package_profile"
)

PROTECTED_ANCHOR_AXIS = "protected_profile_anchor"
LAND_AXIS = "lands"


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


def roles(row: Mapping[str, Any]) -> set[str]:
    return {str(role) for role in row.get("profile_roles") or [] if str(role or "").strip()}


def card_name(row: Mapping[str, Any]) -> str:
    return str(row.get("card_name") or row.get("add") or row.get("cut") or "")


def cut_pool(candidate_payload: Mapping[str, Any], package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    source = candidate_payload.get("global_cut_review_pool") or package_payload.get("selected_cut_package") or []
    rows = [dict(row) for row in source if isinstance(row, Mapping) and card_name(row)]
    rows.sort(key=lambda row: (-int(row.get("score") or 0), card_name(row)))
    return rows


def selected_adds(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in package_payload.get("selected_add_package") or []
        if isinstance(row, Mapping) and card_name(row)
    ]


def best_same_lane_cut(add: Mapping[str, Any], cuts: list[dict[str, Any]], used: set[str]) -> dict[str, Any] | None:
    add_roles = roles(add)
    candidates = []
    for row in cuts:
        name = card_name(row)
        if name in used:
            continue
        shared = add_roles & roles(row)
        if not shared:
            continue
        candidates.append((len(shared), int(row.get("score") or 0), name, row))
    if not candidates:
        return None
    candidates.sort(key=lambda item: (-item[0], -item[1], item[2]))
    return dict(candidates[0][3])


def best_non_overlapping_cut(add: Mapping[str, Any], cuts: list[dict[str, Any]], used: set[str]) -> dict[str, Any] | None:
    add_roles = roles(add)
    candidates = []
    for row in cuts:
        name = card_name(row)
        if name in used:
            continue
        if add_roles & roles(row):
            continue
        candidates.append((int(row.get("score") or 0), name, row))
    if not candidates:
        return None
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return dict(candidates[0][2])


def next_unused_cut(cuts: list[dict[str, Any]], used: set[str]) -> dict[str, Any] | None:
    for row in cuts:
        name = card_name(row)
        if name not in used:
            return dict(row)
    return None


def pair_row(index: int, add: Mapping[str, Any], cut: Mapping[str, Any] | None) -> dict[str, Any]:
    axis = str(add.get("selected_for_axis") or "")
    add_roles = roles(add)
    cut_roles = roles(cut or {})
    shared = sorted(add_roles & cut_roles)
    blockers: list[str] = []
    reasons: list[str] = []
    if cut is None:
        status = "pair_blocked_missing_cut"
        blockers.append("missing_cut_for_add")
        reasons.append("missing_cut_for_add")
    elif axis == LAND_AXIS:
        status = "reordered_land_floor_pair_needs_curve_review"
        blockers.append("land_floor_pair_needs_curve_and_role_loss_review")
        reasons.append("land_floor_repair_uses_nonland_cut")
    elif axis == PROTECTED_ANCHOR_AXIS and shared:
        status = "reordered_protected_anchor_same_lane_pair"
        reasons.append("protected_anchor_same_lane_overlap_after_reorder")
    elif axis == PROTECTED_ANCHOR_AXIS:
        status = "reordered_protected_anchor_pair_still_blocked"
        blockers.append("protected_anchor_pair_lacks_same_lane_overlap")
        reasons.append("no_same_lane_cut_available_for_protected_anchor")
    elif shared:
        status = "reordered_same_lane_profile_repair_pair"
        reasons.append("same_lane_role_overlap_after_reorder")
    else:
        status = "reordered_profile_floor_repair_pair"
        reasons.append("profile_floor_repair_uses_over_target_cut_after_reorder")
    return {
        "index": index,
        "add": card_name(add),
        "cut": card_name(cut or {}) or None,
        "add_axis": axis,
        "status": status,
        "shared_profile_roles": shared,
        "add_profile_roles": sorted(add_roles),
        "cut_profile_roles": sorted(cut_roles),
        "reasons": reasons,
        "blockers": blockers,
        "candidate_copy_allowed": False,
    }


def reorder_pairs(adds: list[dict[str, Any]], cuts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    used: set[str] = set()
    assignments: dict[str, dict[str, Any] | None] = {}
    protected_adds = [row for row in adds if str(row.get("selected_for_axis") or "") == PROTECTED_ANCHOR_AXIS]
    nonland_adds = [
        row
        for row in adds
        if str(row.get("selected_for_axis") or "") not in {PROTECTED_ANCHOR_AXIS, LAND_AXIS}
    ]
    for add in protected_adds:
        cut = best_same_lane_cut(add, cuts, used)
        if cut is None:
            cut = next_unused_cut(cuts, used)
        assignments[card_name(add)] = cut
        if cut:
            used.add(card_name(cut))
    for add in nonland_adds:
        cut = best_non_overlapping_cut(add, cuts, used)
        if cut is None:
            cut = best_same_lane_cut(add, cuts, used)
        if cut is None:
            cut = next_unused_cut(cuts, used)
        assignments[card_name(add)] = cut
        if cut:
            used.add(card_name(cut))
    for add in adds:
        name = card_name(add)
        if name in assignments:
            continue
        cut = next_unused_cut(cuts, used)
        assignments[name] = cut
        if cut:
            used.add(card_name(cut))
    return [pair_row(index, add, assignments.get(card_name(add))) for index, add in enumerate(adds, start=1)]


def build_report(*, package_resynthesis_report: Path, candidate_model_report: Path) -> dict[str, Any]:
    package_payload = load_json(package_resynthesis_report)
    candidate_payload = load_json(candidate_model_report)
    package_summary = package_payload.get("summary") or {}
    candidate_summary = candidate_payload.get("summary") or {}
    adds = selected_adds(package_payload)
    cuts = cut_pool(candidate_payload, package_payload)
    pairs = reorder_pairs(adds, cuts)
    blockers = []
    for row in pairs:
        blockers.extend(str(blocker) for blocker in row.get("blockers") or [])
    ready_pair_count = sum(1 for row in pairs if not row.get("blockers"))
    protected_ready = sum(
        1
        for row in pairs
        if row.get("add_axis") == PROTECTED_ANCHOR_AXIS and not row.get("blockers")
    )
    land_review = sum(
        1
        for row in pairs
        if row.get("add_axis") == LAND_AXIS and "land_floor_pair_needs_curve_and_role_loss_review" in row.get("blockers", [])
    )
    protected_total = sum(1 for row in pairs if row.get("add_axis") == PROTECTED_ANCHOR_AXIS)
    protected_clean = protected_ready == protected_total
    if not blockers:
        status = "profile_repair_cut_pair_reorder_ready_for_candidate_copy"
    elif protected_clean and land_review > 0 and set(blockers) == {"land_floor_pair_needs_curve_and_role_loss_review"}:
        status = "profile_repair_cut_pair_reorder_ready_for_land_curve_review"
    else:
        status = "profile_repair_cut_pair_reorder_blocks_candidate_copy"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_profile_repair_cut_pair_reorderer",
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
        "input_artifacts": {
            "package_resynthesis_report": rel(package_resynthesis_report),
            "candidate_model_report": rel(candidate_model_report),
        },
        "summary": {
            "deck_id": str(package_summary.get("deck_id") or candidate_summary.get("deck_id") or ""),
            "commander": str(package_summary.get("commander") or candidate_summary.get("commander") or ""),
            "pair_count": len(pairs),
            "ready_pair_count": ready_pair_count,
            "protected_anchor_ready_pair_count": protected_ready,
            "land_pair_review_count": land_review,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": (
                "review_land_floor_cut_role_loss_before_candidate_copy"
                if status == "profile_repair_cut_pair_reorder_ready_for_land_curve_review"
                else (
                    "materialize_profile_repair_candidate_copy"
                    if status == "profile_repair_cut_pair_reorder_ready_for_candidate_copy"
                    else "expand_profile_repair_cut_source_lane_before_candidate_copy"
                )
            ),
        },
        "reordered_pairs": pairs,
        "candidate_copy_blockers": sorted(set(blockers)),
        "policy": {
            "reorder_boundary": "This gate reorders review rows only; it does not copy or mutate a deck.",
            "protected_anchor_boundary": "Protected anchors must consume same-lane cuts before land repairs consume any remaining cut pool.",
            "land_floor_boundary": "Land-floor pairs stay closed until curve and role-loss review accepts the nonland cuts.",
            "battle_boundary": "No battle or promotion opens from pair reordering.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Repair Cut Pair Reorderer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- protected_anchor_ready_pair_count: `{summary['protected_anchor_ready_pair_count']}`",
        f"- land_pair_review_count: `{summary['land_pair_review_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Reordered Pairs",
        "",
        "| # | Add | Cut | Status | Shared Roles | Blockers |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    for row in payload["reordered_pairs"]:
        lines.append(
            f"| {row['index']} | `{row['add']}` | `{row['cut']}` | `{row['status']}` | `{', '.join(row.get('shared_profile_roles') or []) or '-'}` | `{', '.join(row.get('blockers') or []) or '-'}` |"
        )
    lines.extend(["", "## Candidate-Copy Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
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
    parser.add_argument("--package-resynthesis-report", type=Path, default=DEFAULT_PACKAGE_RESYNTHESIS_REPORT)
    parser.add_argument("--candidate-model-report", type=Path, default=DEFAULT_CANDIDATE_MODEL_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        package_resynthesis_report=args.package_resynthesis_report,
        candidate_model_report=args.candidate_model_report,
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
