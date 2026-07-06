#!/usr/bin/env python3
"""Review resynthesized profile-repair add/cut pairs before candidate copy.

This read-only gate consumes
global_commander_profile_repair_package_resynthesizer.py output. It checks
whether selected adds and cuts are coherent enough to allow a later candidate
copy materializer. It does not mutate a deck, run battle, or promote anything.
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
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_repair_cut_pair_reviewer_20260706_lorehold_land_floor_package_profile"
)

PROTECTED_ANCHOR_AXIS = "protected_profile_anchor"


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


def pair_status(add: Mapping[str, Any], cut: Mapping[str, Any]) -> tuple[str, list[str], list[str]]:
    add_axis = str(add.get("selected_for_axis") or "")
    add_roles = roles(add)
    cut_roles = roles(cut)
    shared_roles = sorted(add_roles & cut_roles)
    reasons: list[str] = []
    blockers: list[str] = []
    if add_axis == "lands":
        reasons.append("land_floor_repair_uses_nonland_cut")
        blockers.append("land_floor_pair_needs_curve_and_role_loss_review")
        return "pair_needs_manual_land_curve_review", reasons, blockers
    if add_axis == PROTECTED_ANCHOR_AXIS and shared_roles:
        reasons.append("protected_anchor_same_lane_overlap")
        return "review_only_protected_anchor_same_lane_pair", reasons, blockers
    if add_axis == PROTECTED_ANCHOR_AXIS:
        reasons.append("protected_anchor_cross_lane_cut")
        blockers.append("protected_anchor_pair_lacks_same_lane_overlap")
        return "pair_blocked_cross_lane_protected_anchor_cut", reasons, blockers
    if shared_roles:
        reasons.append("same_lane_role_overlap")
        return "review_only_same_lane_profile_repair_pair", reasons, blockers
    reasons.append("cross_lane_pair")
    blockers.append("pair_lacks_same_lane_overlap")
    return "pair_blocked_cross_lane_cut", reasons, blockers


def build_pairs(adds: list[Mapping[str, Any]], cuts: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    pairs = []
    for index, add in enumerate(adds):
        cut = cuts[index] if index < len(cuts) else {}
        if not cut:
            pairs.append(
                {
                    "index": index + 1,
                    "add": add.get("card_name"),
                    "cut": None,
                    "status": "pair_blocked_missing_cut",
                    "shared_profile_roles": [],
                    "reasons": ["missing_cut_for_add"],
                    "blockers": ["missing_cut_for_add"],
                    "candidate_copy_allowed": False,
                }
            )
            continue
        status, reasons, blockers = pair_status(add, cut)
        pairs.append(
            {
                "index": index + 1,
                "add": add.get("card_name"),
                "cut": cut.get("card_name"),
                "add_axis": add.get("selected_for_axis"),
                "status": status,
                "shared_profile_roles": sorted(roles(add) & roles(cut)),
                "add_profile_roles": sorted(roles(add)),
                "cut_profile_roles": sorted(roles(cut)),
                "reasons": reasons,
                "blockers": blockers,
                "candidate_copy_allowed": False,
            }
        )
    return pairs


def build_report(*, package_resynthesis_report: Path) -> dict[str, Any]:
    payload = load_json(package_resynthesis_report)
    summary = payload.get("summary") or {}
    adds = [dict(row) for row in payload.get("selected_add_package") or [] if isinstance(row, Mapping)]
    cuts = [dict(row) for row in payload.get("selected_cut_package") or [] if isinstance(row, Mapping)]
    pairs = build_pairs(adds, cuts)
    blockers = []
    for pair in pairs:
        blockers.extend(str(blocker) for blocker in pair.get("blockers") or [])
    if len(cuts) > len(adds):
        blockers.append("extra_cut_rows_not_pair_reviewed")
    ready_pair_count = sum(1 for pair in pairs if not pair.get("blockers"))
    status = (
        "profile_repair_cut_pair_review_ready_for_candidate_copy"
        if pairs and not blockers
        else "profile_repair_cut_pair_review_blocks_candidate_copy"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_profile_repair_cut_pair_reviewer",
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
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "pair_count": len(pairs),
            "ready_pair_count": ready_pair_count,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": (
                "materialize_profile_repair_candidate_copy"
                if status == "profile_repair_cut_pair_review_ready_for_candidate_copy"
                else "reorder_or_expand_profile_repair_cut_pairs_before_candidate_copy"
            ),
        },
        "reviewed_pairs": pairs,
        "candidate_copy_blockers": sorted(set(blockers)),
        "policy": {
            "pair_review_boundary": "Pair review never mutates decks; it only decides whether a later candidate copy may open.",
            "land_floor_boundary": "Land repairs need explicit curve and role-loss review before consuming high-function nonlands.",
            "protected_anchor_boundary": "Protected-anchor restores require same-lane cut overlap or a separate proof lane.",
            "battle_boundary": "No battle or promotion opens from pair review.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Repair Cut Pair Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Reviewed Pairs",
        "",
        "| # | Add | Cut | Status | Shared Roles | Blockers |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    for row in payload["reviewed_pairs"]:
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
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(package_resynthesis_report=args.package_resynthesis_report)
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
