#!/usr/bin/env python3
"""Resynthesize a profile-repair package after protected-anchor restores.

This read-only gate consumes
global_commander_profile_repair_candidate_model.py output. It can name a
candidate add package and a review-only cut package, but it never materializes a
deck, mutates SQLite/PostgreSQL, runs battles, or promotes candidates.
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
DEFAULT_CANDIDATE_MODEL_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260706_lorehold_land_floor_package_profile.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_repair_package_resynthesizer_20260706_lorehold_land_floor_package_profile"
)

READY_ADD_STATUSES = {
    "review_only_profile_repair_add_candidate",
    "review_only_named_land_candidate",
}
READY_CUT_STATUS = "review_only_profile_repair_cut_candidate"


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


def add_need_for_pool(pool: Mapping[str, Any]) -> int:
    if pool.get("repair_axis") == "lands":
        return max(1, as_int(pool.get("shortfall_to_min")))
    if pool.get("repair_axis") == "protected_profile_anchor":
        return 1
    return max(1, as_int(pool.get("shortfall_to_min")) or 1)


def ready_add_candidates(pool: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in pool.get("top_add_candidates") or []:
        if not isinstance(row, Mapping):
            continue
        if str(row.get("status") or "") not in READY_ADD_STATUSES:
            continue
        rows.append(dict(row))
    return rows


def selected_add_package(candidate_payload: Mapping[str, Any]) -> tuple[list[dict[str, Any]], list[str]]:
    selected: list[dict[str, Any]] = []
    blockers: list[str] = []
    for pool in candidate_payload.get("repair_axis_pools") or []:
        if not isinstance(pool, Mapping):
            continue
        axis = str(pool.get("repair_axis") or "")
        need = add_need_for_pool(pool)
        ready = ready_add_candidates(pool)
        if len(ready) < need:
            blockers.append(f"{axis}:insufficient_ready_add_candidates:{len(ready)}_of_{need}")
        for row in ready[:need]:
            selected.append(
                {
                    "card_name": row.get("card_name"),
                    "selected_for_axis": axis,
                    "source_pool_status": pool.get("status"),
                    "source_blocker": pool.get("blocker"),
                    "score": row.get("score"),
                    "status": "review_only_resynthesized_profile_repair_add",
                    "profile_roles": row.get("profile_roles") or [],
                    "fit_reasons": row.get("fit_reasons") or [],
                    "mutation_allowed": False,
                }
            )
    return selected, blockers


def ready_cut_candidates(candidate_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in candidate_payload.get("global_cut_review_pool") or []:
        if not isinstance(row, Mapping):
            continue
        if str(row.get("status") or "") != READY_CUT_STATUS:
            continue
        rows.append(dict(row))
    return rows


def selected_cut_package(candidate_payload: Mapping[str, Any], required_count: int) -> tuple[list[dict[str, Any]], list[str]]:
    ready = ready_cut_candidates(candidate_payload)
    blockers: list[str] = []
    if len(ready) < required_count:
        blockers.append(f"cut_pool:insufficient_ready_cuts:{len(ready)}_of_{required_count}")
    selected = [
        {
            "card_name": row.get("card_name"),
            "score": row.get("score"),
            "status": "review_only_resynthesized_profile_repair_cut",
            "profile_roles": row.get("profile_roles") or [],
            "core_roles": row.get("core_roles") or [],
            "cut_reasons": row.get("cut_reasons") or [],
            "mutation_allowed": False,
        }
        for row in ready[:required_count]
    ]
    return selected, blockers


def build_report(*, candidate_model_report: Path) -> dict[str, Any]:
    candidate_payload = load_json(candidate_model_report)
    summary = candidate_payload.get("summary") or {}
    adds, add_blockers = selected_add_package(candidate_payload)
    cuts, cut_blockers = selected_cut_package(candidate_payload, len(adds))
    source_blockers = [str(blocker) for blocker in candidate_payload.get("candidate_copy_blockers") or []]
    blockers = add_blockers + cut_blockers
    if not blockers:
        blockers.append("cut_pair_review_required_before_candidate_copy")
    status = (
        "profile_repair_package_resynthesis_ready_for_cut_pair_review"
        if blockers == ["cut_pair_review_required_before_candidate_copy"]
        else "profile_repair_package_resynthesis_blocks_candidate_copy"
    )
    next_gate = (
        "review_resynthesized_profile_repair_cut_pairs_before_candidate_copy"
        if status == "profile_repair_package_resynthesis_ready_for_cut_pair_review"
        else "expand_profile_repair_add_or_cut_source_lane"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_profile_repair_package_resynthesizer",
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
            "candidate_model_report": rel(candidate_model_report),
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "selected_add_count": len(adds),
            "selected_cut_count": len(cuts),
            "source_candidate_copy_blocker_count": len(source_blockers),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "source_candidate_copy_blockers": source_blockers,
        "selected_add_package": adds,
        "selected_cut_package": cuts,
        "candidate_copy_blockers": blockers,
        "policy": {
            "resynthesis_boundary": "This gate only resynthesizes review rows; it does not create a deck copy.",
            "protected_anchor_boundary": "Protected anchors may be restored as adds, but every replacement cut still needs pair review.",
            "battle_boundary": "No battle, promotion, or deck action opens from package resynthesis alone.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Repair Package Resynthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- selected_cut_count: `{summary['selected_cut_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Selected Adds",
        "",
        "| Axis | Card | Status | Roles |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["selected_add_package"]:
        lines.append(
            f"| `{row['selected_for_axis']}` | `{row['card_name']}` | `{row['status']}` | `{', '.join(row.get('profile_roles') or []) or '-'}` |"
        )
    if not payload["selected_add_package"]:
        lines.append("| none | none | none | - |")
    lines.extend(["", "## Selected Cuts", "", "| Card | Status | Roles | Reasons |", "| --- | --- | --- | --- |"])
    for row in payload["selected_cut_package"]:
        lines.append(
            f"| `{row['card_name']}` | `{row['status']}` | `{', '.join(row.get('profile_roles') or []) or '-'}` | `{', '.join(row.get('cut_reasons') or []) or '-'}` |"
        )
    if not payload["selected_cut_package"]:
        lines.append("| none | none | - | - |")
    lines.extend(["", "## Candidate-Copy Blockers", ""])
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
    parser.add_argument("--candidate-model-report", type=Path, default=DEFAULT_CANDIDATE_MODEL_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(candidate_model_report=args.candidate_model_report)
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
