#!/usr/bin/env python3
"""Plan external cut-source research after internal hypotheses stay blocked.

This read-only gate records current external source lanes and converts the
cut-hypothesis same-lane blocker into the next research actions. It is not a web
scraper and does not treat external popularity as deck truth; it creates a
source-backed handoff for collecting commander reference corpus evidence.
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
DEFAULT_SAME_LANE_PROOF_REPORT = (
    REPORT_DIR / "global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1"
)

EXTERNAL_SOURCE_SNAPSHOTS: list[dict[str, Any]] = [
    {
        "source_id": "wizards_commander_brackets_2026_02_09",
        "url": "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026",
        "observed_on": "2026-07-05",
        "source_type": "official_commander_policy",
        "signal": "Commander brackets and Game Changers are still active, evolving pregame power-context signals.",
        "use_for_cut_research": "classify power/bracket risk before cutting high-power staples or Game Changers",
        "limitation": "policy context only; it does not prove a card belongs in a specific commander deck",
    },
    {
        "source_id": "wizards_commander_brackets_2025_10_21",
        "url": "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025",
        "observed_on": "2026-07-05",
        "source_type": "official_commander_policy",
        "signal": "Bracket 3/4 expectations separate strong synergy, tutors, fast mana, and efficient disruption by deck intent.",
        "use_for_cut_research": "avoid flattening optimized staples into generic over-target cut pressure",
        "limitation": "bracket intent is not a same-lane replacement proof",
    },
    {
        "source_id": "edhrec_kaalia_current",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_public_usage",
        "signal": "The public Kaalia page centers Flying, Angels, and Aggro and surfaces Angel/Demon/Dragon payoff cards as high-synergy anchors.",
        "use_for_cut_research": "build a commander-specific public corpus and separate payoff adds from unrelated cut lanes",
        "limitation": "EDHREC popularity is an evidence lane, not final deck truth or battle proof",
    },
    {
        "source_id": "edhrec_kaalia_expensive_midrange_2026_06_24",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/midrange/expensive",
        "observed_on": "2026-07-05",
        "source_type": "commander_public_usage_filtered",
        "signal": "The filtered expensive-midrange sample is small but highlights payoff anchors and high-power staples such as tutors, fast mana, and protection.",
        "use_for_cut_research": "treat small filtered samples as source-lane hints requiring local corroboration",
        "limitation": "sample-size constrained and not enough to authorize cuts by itself",
    },
    {
        "source_id": "edhrec_kaalia_hidden_gems_2026_03_26",
        "url": "https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_strategy_article",
        "signal": "Kaalia's plan depends on attacking to cheat Angels, Demons, or Dragons, and needs haste/protection plus ways to recover after removal.",
        "use_for_cut_research": "protect attack-window, recast, and payoff-density lanes from generic cuts",
        "limitation": "article recommendations are qualitative and must be validated against the target deck and battle traces",
    },
    {
        "source_id": "edhrec_commander_deckbuilding_guide",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "observed_on": "2026-07-05",
        "source_type": "general_deckbuilding_method",
        "signal": "General Commander construction starts from functional categories and then checks whether the list plays its intended way.",
        "use_for_cut_research": "keep ramp/draw/removal/protection categories as floors, not automatic cut permissions",
        "limitation": "generic categories must bend to commander intent and same-lane evidence",
    },
]


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


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def hypothesis_research_row(row: Mapping[str, Any]) -> dict[str, Any]:
    trace_group = str(row.get("trace_group") or "")
    roles = as_list(row.get("cut_roles"))
    if trace_group == "usage_blocked":
        research_status = "external_research_cannot_override_target_usage"
        required_evidence = [
            "current_commander_reference_corpus_for_cut_card",
            "same_lane_replacement_or_equal_gate_if_cut_remains_candidate",
            "target_replay_negative_or_battle_evidence_before_reclassification",
        ]
    elif trace_group == "seen_without_usage":
        research_status = "external_research_requires_negative_trace_review_first"
        required_evidence = [
            "manual_negative_trace_review_or_force_access",
            "external_corpus_check_for_current_commander_and_bracket",
            "do_not_use_seen_without_usage_as_cut_proof",
        ]
    else:
        research_status = "external_research_requires_more_trace_first"
        required_evidence = [
            "expand_replay_window_or_force_access",
            "external_corpus_check_after_trace_status_is_known",
        ]
    if not roles:
        lane = "off_profile_or_unclassified_cut_lane"
    elif "angels_demons_dragons_payoffs" in roles:
        lane = "payoff_lane"
    else:
        lane = ",".join(roles)
    return {
        "cut_card": row.get("cut_card"),
        "trace_group": trace_group,
        "cut_roles": roles,
        "research_lane": lane,
        "research_status": research_status,
        "same_lane_route_count": len(row.get("same_lane_replacement_routes") or []),
        "incidental_overlap_count": len(row.get("incidental_role_overlaps") or []),
        "external_cut_permission_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "required_evidence": required_evidence,
    }


def research_actions(*, package_axes: list[str], rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    lanes = sorted({row["research_lane"] for row in rows})
    return [
        {
            "priority": "P0",
            "action": "collect_external_commander_reference_corpus_for_cut_candidates",
            "status": "required_next",
            "reason": "Internal mined hypotheses either were used or lacked explicit same-lane replacement proof.",
            "target_lanes": lanes,
            "candidate_copy_allowed": False,
        },
        {
            "priority": "P1",
            "action": "separate_payoff_add_axis_from_cut_lane_research",
            "status": "required",
            "reason": "The package add axes are explicit payoff repairs and do not automatically replace draw, reanimation, equipment, or off-profile cuts.",
            "package_axes": package_axes,
            "candidate_copy_allowed": False,
        },
        {
            "priority": "P2",
            "action": "annotate_high_power_staples_with_bracket_and_game_changer_context",
            "status": "required_before_cut",
            "reason": "Official bracket policy makes tutors, fast mana, value engines, and efficient disruption bracket-context signals, not generic cut fodder.",
            "candidate_copy_allowed": False,
        },
        {
            "priority": "P3",
            "action": "rerun_internal_hypothesis_miner_after_external_annotations",
            "status": "blocked_until_corpus_collected",
            "reason": "No new deck action should occur until external corpus evidence is mapped back to named current-deck cards.",
            "candidate_copy_allowed": False,
        },
    ]


def build_report(*, same_lane_proof_report: Path, package_synthesis_report: Path) -> dict[str, Any]:
    same_lane_payload = load_json(same_lane_proof_report)
    package_payload = load_json(package_synthesis_report)
    same_lane_summary = same_lane_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    package_axes = as_list(same_lane_summary.get("package_explicit_add_axes"))
    if not package_axes:
        package_axes = sorted(
            {
                axis
                for row in package_payload.get("selected_add_package") or []
                if isinstance(row, Mapping)
                for axis in as_list(row.get("covered_axes"))
            }
        )
    rows = [
        hypothesis_research_row(row)
        for row in same_lane_payload.get("hypothesis_same_lane_rows") or []
        if isinstance(row, Mapping)
    ]
    actions = research_actions(package_axes=package_axes, rows=rows)
    return {
        "generated_at": utc_now(),
        "status": "external_cut_source_research_plan_ready_no_deck_action",
        "artifact_type": "global_commander_external_cut_source_research_plan",
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
        "external_cut_permission_now": False,
        "input_artifacts": {
            "same_lane_proof_report": rel(same_lane_proof_report),
            "package_synthesis_report": rel(package_synthesis_report),
        },
        "summary": {
            "deck_id": str(same_lane_summary.get("deck_id") or package_summary.get("deck_id") or ""),
            "commander": str(same_lane_summary.get("commander") or package_summary.get("commander") or ""),
            "hypothesis_count": len(rows),
            "usage_blocked_hypothesis_count": int(same_lane_summary.get("usage_blocked_hypothesis_count") or 0),
            "seen_without_usage_count": int(same_lane_summary.get("seen_without_usage_count") or 0),
            "explicit_same_lane_route_count": int(same_lane_summary.get("explicit_same_lane_route_count") or 0),
            "external_source_count": len(EXTERNAL_SOURCE_SNAPSHOTS),
            "package_explicit_add_axes": package_axes,
            "research_action_count": len(actions),
            "next_gate": "collect_external_commander_reference_corpus_for_cut_candidates",
        },
        "external_sources": EXTERNAL_SOURCE_SNAPSHOTS,
        "hypothesis_external_research_rows": rows,
        "research_actions": actions,
        "candidate_copy_blockers": [
            "external_research_is_not_cut_permission",
            "target_usage_or_seen_without_usage_still_blocks_value_safe_reclassification",
            "candidate_copy_closed_until_external_corpus_maps_to_negative_or_same_lane_evidence",
        ],
        "policy": {
            "source_boundary": "External usage and articles are evidence lanes, not final deck truth.",
            "same_lane_boundary": "A payoff add axis cannot replace draw, reanimation, equipment, or off-profile cuts without explicit proof.",
            "trace_boundary": "Target-deck usage remains stronger than external popularity for value-safe cut decisions.",
            "mutation_boundary": "This plan does not copy decks, mutate DBs, run battles, or promote a package.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Cut-Source Research Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- usage_blocked_hypothesis_count: `{summary['usage_blocked_hypothesis_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- explicit_same_lane_route_count: `{summary['explicit_same_lane_route_count']}`",
        f"- external_source_count: `{summary['external_source_count']}`",
        f"- package_explicit_add_axes: `{', '.join(summary['package_explicit_add_axes'])}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## External Sources",
        "",
        "| Source | Type | Use | Limitation |",
        "| --- | --- | --- | --- |",
    ]
    for source in payload["external_sources"]:
        lines.append(
            "| [{source_id}]({url}) | `{source_type}` | {use} | {limitation} |".format(
                source_id=source["source_id"],
                url=source["url"],
                source_type=source["source_type"],
                use=source["use_for_cut_research"],
                limitation=source["limitation"],
            )
        )
    lines.extend(
        [
            "",
            "## Hypothesis Research Rows",
            "",
            "| Cut | Trace Group | Lane | Research Status | External Cut Permission |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["hypothesis_external_research_rows"]:
        lines.append(
            "| `{cut}` | `{trace}` | `{lane}` | `{status}` | `{permission}` |".format(
                cut=row.get("cut_card"),
                trace=row.get("trace_group"),
                lane=row.get("research_lane"),
                status=row.get("research_status"),
                permission=str(row.get("external_cut_permission_now")).lower(),
            )
        )
    lines.extend(["", "## Research Actions", ""])
    for action in payload["research_actions"]:
        lines.append(f"- `{action['priority']}` `{action['action']}`: {action['reason']}")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--same-lane-proof-report", type=Path, default=DEFAULT_SAME_LANE_PROOF_REPORT)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        same_lane_proof_report=args.same_lane_proof_report,
        package_synthesis_report=args.package_synthesis_report,
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
