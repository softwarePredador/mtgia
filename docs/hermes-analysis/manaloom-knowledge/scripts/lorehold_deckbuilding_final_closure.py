#!/usr/bin/env python3
"""Close Lorehold deckbuilding under the active 607 contract.

This read-only closure is the handoff artifact for agents and scripts. It says
that deck 607 remains the current best Lorehold deck under the active contract,
and it lists the exact conditions required to reopen deck changes.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CHAMPION_SNAPSHOT = (
    REPORT_DIR / "lorehold_current_champion_snapshot_20260630_goal_learning.json"
)
DEFAULT_CUT_EVIDENCE_EXPANDER = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260630_goal_learning.json"
)
DEFAULT_MICRO_PACKAGE_MODEL = (
    REPORT_DIR / "lorehold_trace_targeted_micro_package_model_20260630_goal_learning.json"
)
DEFAULT_PLANNER = (
    REPORT_DIR / "lorehold_next_action_planner_20260630_goal_learning_cut_evidence_exhausted.json"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def build_closure(
    *,
    champion_snapshot: Mapping[str, Any],
    cut_evidence_expander: Mapping[str, Any],
    micro_package_model: Mapping[str, Any],
    planner: Mapping[str, Any],
    champion_snapshot_path: Path,
    cut_evidence_expander_path: Path,
    micro_package_model_path: Path,
    planner_path: Path,
) -> dict[str, Any]:
    champion_summary = champion_snapshot.get("summary") or {}
    cut_summary = cut_evidence_expander.get("summary") or {}
    micro_summary = micro_package_model.get("summary") or {}
    planner_summary = planner.get("summary") or {}
    validation_errors: list[str] = []

    if champion_snapshot.get("status") != "current_champion_snapshot":
        validation_errors.append("champion snapshot is not current_champion_snapshot")
    if int(champion_summary.get("total_cards") or 0) != 100:
        validation_errors.append("champion snapshot is not a 100-card deck")
    if int(champion_summary.get("commander_count") or 0) != 1:
        validation_errors.append("champion snapshot does not have exactly one commander")
    if int(champion_summary.get("validation_error_count") or 0) != 0:
        validation_errors.append("champion snapshot contains validation errors")
    if str(cut_summary.get("recommended_next_action") or "") != (
        "no_cut_slot_to_expand_under_current_607_contract"
    ):
        validation_errors.append("cut evidence expander is not exhausted")
    if int(cut_summary.get("seed_safe_ready_count") or 0) != 0:
        validation_errors.append("cut evidence expander still has seed-safe cuts")
    if int(cut_summary.get("reviewable_evidence_gap_count") or 0) != 0:
        validation_errors.append("cut evidence expander still has reviewable gaps")
    if int(micro_summary.get("ready_micro_package_count") or 0) != 0:
        validation_errors.append("micro-package model still has ready packages")
    if str(planner_summary.get("recommended_next_action") or "") != (
        "no_cut_slot_to_expand_under_current_607_contract"
    ):
        validation_errors.append("planner is not pointing to the exhausted cut contract")

    status = "closed_current_607_champion" if not validation_errors else "blocked"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_deckbuilding_final_closure",
        "postgres_writes": False,
        "source_db_mutated": False,
        "status": status,
        "source_reports": {
            "champion_snapshot": rel(champion_snapshot_path),
            "cut_evidence_expander": rel(cut_evidence_expander_path),
            "micro_package_model": rel(micro_package_model_path),
            "planner": rel(planner_path),
        },
        "summary": {
            "deck_id": champion_summary.get("deck_id") or champion_snapshot.get("deck_id"),
            "final_state": status,
            "total_cards": champion_summary.get("total_cards"),
            "commander_count": champion_summary.get("commander_count"),
            "land_count": champion_summary.get("land_count"),
            "protected_anchor_count": champion_summary.get("protected_anchor_count"),
            "role_counts": champion_summary.get("role_counts") or {},
            "micro_package_ready_count": int(micro_summary.get("ready_micro_package_count") or 0),
            "seed_safe_ready_count": int(cut_summary.get("seed_safe_ready_count") or 0),
            "reviewable_evidence_gap_count": int(
                cut_summary.get("reviewable_evidence_gap_count") or 0
            ),
            "hard_blocked_count": int(cut_summary.get("hard_blocked_count") or 0),
            "same_lane_hard_blocked_count": int(
                cut_summary.get("same_lane_hard_blocked_count") or 0
            ),
            "planner_recommended_next_action": planner_summary.get("recommended_next_action"),
            "validation_error_count": len(validation_errors),
            "recommended_next_action": "keep_607_closed_until_reopen_condition",
        },
        "final_decision": {
            "decision": "keep_607_as_current_lorehold_champion_under_active_contract",
            "reason": (
                "All current from-scratch shells and one-for-one package routes are "
                "below or blocked against protected 607, and no seed-safe cut or "
                "reviewable cut-evidence gap remains."
            ),
            "reopen_conditions": [
                "new external/card evidence changes a cut-safety row",
                "the owner explicitly relaxes protected-cut rules for a named slot",
                "a new full-shell archetype is evaluated under a separate declared contract",
                "battle/runtime changes materially alter the current 607 evidence inputs",
            ],
            "forbidden_next_steps": [
                "do not run another one-for-one swap gate against 607",
                "do not cut Creative Technique or Bender's Waterskin as generic cuts",
                "do not treat forced-access signal as natural deck promotion",
                "do not replace 607 from structure-only or aggregate-only evidence",
            ],
        },
        "validation": {
            "status": "pass" if not validation_errors else "fail",
            "errors": validation_errors,
        },
        "handoff": {
            "current_deck_artifact": rel(champion_snapshot_path),
            "current_decklist_artifact": rel(
                champion_snapshot_path.with_suffix(".decklist.txt")
            ),
            "planner_final_artifact": rel(planner_path),
            "safe_next_work": [
                "use deck 607 as the Lorehold baseline for battle validation",
                "continue card-rule/runtime family work independently of deck swaps",
                "only reopen deckbuilding through one of the listed reopen conditions",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    decision = payload["final_decision"]
    validation = payload["validation"]
    lines = [
        "# Lorehold Deckbuilding Final Closure",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Deck id: `{summary['deck_id']}`",
        f"- Total cards: `{summary['total_cards']}`",
        f"- Commander count: `{summary['commander_count']}`",
        f"- Lands: `{summary['land_count']}`",
        f"- Micro-package ready count: `{summary['micro_package_ready_count']}`",
        f"- Seed-safe ready count: `{summary['seed_safe_ready_count']}`",
        f"- Reviewable evidence gaps: `{summary['reviewable_evidence_gap_count']}`",
        f"- Planner final action: `{summary['planner_recommended_next_action']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        "",
        "## Decision",
        "",
        f"- `{decision['decision']}`: {decision['reason']}",
        "",
        "## Reopen Conditions",
        "",
    ]
    for item in decision["reopen_conditions"]:
        lines.append(f"- {item}")
    lines.extend(["", "## Forbidden Next Steps", ""])
    for item in decision["forbidden_next_steps"]:
        lines.append(f"- {item}")
    lines.extend(["", "## Source Reports", ""])
    for key, value in payload["source_reports"].items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Validation", ""])
    if validation["errors"]:
        for error in validation["errors"]:
            lines.append(f"- ERROR: {error}")
    else:
        lines.append("- PASS: closure inputs are aligned and exhausted.")
    lines.extend(["", "## Safe Next Work", ""])
    for item in payload["handoff"]["safe_next_work"]:
        lines.append(f"- {item}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--champion-snapshot", type=Path, default=DEFAULT_CHAMPION_SNAPSHOT)
    parser.add_argument("--cut-evidence-expander", type=Path, default=DEFAULT_CUT_EVIDENCE_EXPANDER)
    parser.add_argument("--micro-package-model", type=Path, default=DEFAULT_MICRO_PACKAGE_MODEL)
    parser.add_argument("--planner", type=Path, default=DEFAULT_PLANNER)
    parser.add_argument("--stem", default="lorehold_deckbuilding_final_closure_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_closure(
        champion_snapshot=read_json(args.champion_snapshot),
        cut_evidence_expander=read_json(args.cut_evidence_expander),
        micro_package_model=read_json(args.micro_package_model),
        planner=read_json(args.planner),
        champion_snapshot_path=args.champion_snapshot,
        cut_evidence_expander_path=args.cut_evidence_expander,
        micro_package_model_path=args.micro_package_model,
        planner_path=args.planner,
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
    return 1 if payload["validation"]["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
