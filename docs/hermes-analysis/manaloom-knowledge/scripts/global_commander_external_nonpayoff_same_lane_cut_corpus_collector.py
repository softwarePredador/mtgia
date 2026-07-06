#!/usr/bin/env python3
"""Collect external nonpayoff same-lane corpus for exhausted cut roles.

This read-only gate consumes the same-lane cut-axis broadening plan and the
same-lane new cut source miner. It records role-level external corpus signals
for exhausted nonpayoff cut lanes. External corpus is evidence for the next
policy/source-discovery pass only; it does not authorize cuts, candidate copy,
battle, value-safe reclassification, or promotion.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_AXIS_BROADENING_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_NEW_CUT_SOURCE_MINER_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
)

SOURCE_CORPUS_SNAPSHOT: list[dict[str, Any]] = [
    {
        "source_id": "edhrec_kaalia_current_2026_07_05",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_public_usage",
        "observed_signal": "37,936 Kaalia commander decks; public page exposes Top Cards, Game Changers, Utility Artifacts, Mana Artifacts, Instants, and Lands sections.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration", "tutors_access"],
        "evidence_use": "role-level popularity and section presence for nonpayoff support lanes",
        "limitation": "public inclusion and synergy are not target-deck trace proof or cut permission",
    },
    {
        "source_id": "edhrec_kaalia_combos_2026_07_05",
        "url": "https://edhrec.com/combos/kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_combo_corpus",
        "observed_signal": "1,141 Kaalia combo rows, including attack/combat, tutor, mana, and payoff dependency contexts.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration", "tutors_access"],
        "evidence_use": "detect support cards that are combo enablers or prerequisites before treating a same-lane card as cuttable",
        "limitation": "combo presence can protect or require review; it does not create a value-safe cut",
    },
    {
        "source_id": "commander_spellbook_combo_search_2026_07_05",
        "url": "https://commanderspellbook.com/",
        "observed_on": "2026-07-05",
        "source_type": "commander_combo_search_engine",
        "observed_signal": "Commander Spellbook is a Commander combo search engine with advanced search and most-popular combo surfaces.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration", "tutors_access"],
        "evidence_use": "future dependency lookup for nonpayoff support cards before source-policy mapping",
        "limitation": "search-engine availability is a lane, not card-level evidence until named queries are collected",
    },
    {
        "source_id": "wizards_commander_brackets_2026_02_09",
        "url": "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026",
        "observed_on": "2026-07-05",
        "source_type": "official_commander_policy",
        "observed_signal": "Wizards confirms Commander Brackets and Game Changers remain active policy surfaces in 2026.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration", "tutors_access"],
        "evidence_use": "power-context guardrail for fast mana, tutors, and high-impact protection/silence effects",
        "limitation": "policy context cannot override target-deck trace or same-lane proof",
    },
    {
        "source_id": "scryfall_game_changer_surface_via_playgroup_2026_07_05",
        "url": "https://playgroup.gg/commander/game-changers",
        "observed_on": "2026-07-05",
        "source_type": "scryfall_synced_game_changer_index",
        "observed_signal": "53 Game Changer cards synced from Scryfall is:gamechanger on 2026-07-05.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration", "tutors_access"],
        "evidence_use": "identify high-power staples that need bracket context instead of generic cut treatment",
        "limitation": "supporting synced index; official/Scryfall flags still need local card mapping before policy use",
    },
    {
        "source_id": "draftsim_kaalia_deck_guide_2025",
        "url": "https://draftsim.com/kaalia-of-the-vast-edh-deck/",
        "observed_on": "2026-07-05",
        "source_type": "commander_strategy_article",
        "observed_signal": "Kaalia is described as targeted because her mana advantage depends on surviving and attacking.",
        "covered_roles": ["haste_protection_silence", "mana_acceleration"],
        "evidence_use": "strategy context for protecting attack windows and acceleration lanes",
        "limitation": "strategy article only; not card-level cut evidence",
    },
]

ROLE_CORPUS_RULES: dict[str, dict[str, Any]] = {
    "haste_protection_silence": {
        "role_label": "haste/protection/silence attack-window support",
        "nonpayoff_requirement": "research nonpayoff support slots only; exclude commander, lands, Angels/Demons/Dragons payoffs, expected attack enablers, and already traced cards",
        "source_signal_requirements": [
            "commander_public_usage_presence_or_absence",
            "combo_dependency_check",
            "strategy_article_attack_window_context",
            "game_changer_or_bracket_context",
        ],
    },
    "mana_acceleration": {
        "role_label": "nonland ramp, rocks, fast mana, treasure support",
        "nonpayoff_requirement": "research nonland, nonpayoff mana sources only; exclude lands, payoff creatures, structural fast-mana anchors, and already traced cards",
        "source_signal_requirements": [
            "mana_artifacts_or_ramp_section_context",
            "combo_dependency_check",
            "game_changer_or_bracket_context",
            "target_deck_usage_override_check",
        ],
    },
    "tutors_access": {
        "role_label": "tutor and library-access support",
        "nonpayoff_requirement": "research nonpayoff tutor/access slots only; exclude payoff bodies, expected package anchors, structural tutors, and already traced cards",
        "source_signal_requirements": [
            "public_usage_tutor_context",
            "combo_dependency_check",
            "game_changer_or_bracket_context",
            "target_deck_usage_override_check",
        ],
    },
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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def role_pressure_rows(axis_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in axis_payload.get("role_pressure_rows") or []
        if isinstance(row, Mapping) and row.get("target_cut_role")
    ]
    rows.sort(key=lambda row: str(row.get("target_cut_role") or ""))
    return rows


def selected_add_count_by_role(package_payload: Mapping[str, Any]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in package_payload.get("selected_add_package") or []:
        if not isinstance(row, Mapping):
            continue
        role = str(row.get("replaces_cut_role") or "")
        if role:
            counts[role] += 1
    return dict(counts)


def source_rows_for_role(role: str) -> list[dict[str, Any]]:
    return [
        {
            "source_id": source["source_id"],
            "source_type": source["source_type"],
            "url": source["url"],
            "evidence_use": source["evidence_use"],
            "limitation": source["limitation"],
        }
        for source in SOURCE_CORPUS_SNAPSHOT
        if role in source.get("covered_roles", [])
    ]


def classify_role_corpus(
    *,
    pressure_row: Mapping[str, Any],
    selected_add_count: int,
) -> dict[str, Any]:
    role = str(pressure_row.get("target_cut_role") or "")
    rules = ROLE_CORPUS_RULES.get(
        role,
        {
            "role_label": role or "unknown",
            "nonpayoff_requirement": "research explicit nonpayoff same-lane source context before policy mapping",
            "source_signal_requirements": ["commander_public_usage_presence_or_absence"],
        },
    )
    fresh = as_int(pressure_row.get("fresh_source_count"))
    recycled = as_int(pressure_row.get("blocked_recycled_source_count"))
    blocked_new = as_int(pressure_row.get("blocked_new_source_count"))
    if fresh:
        status = "external_nonpayoff_corpus_blocked_fresh_sources_need_trace"
        next_evidence = "collect_trace_for_new_same_lane_cut_source_hypotheses"
    elif recycled or blocked_new:
        status = "external_nonpayoff_corpus_collected_for_exhausted_same_lane_role"
        next_evidence = "map_external_nonpayoff_same_lane_corpus_to_cut_policy"
    else:
        status = "external_nonpayoff_corpus_needs_source_lane_discovery"
        next_evidence = "discover_same_lane_source_candidates_before_policy_mapping"
    sources = source_rows_for_role(role)
    return {
        "target_cut_role": role,
        "role_label": rules["role_label"],
        "selected_add_count": selected_add_count,
        "fresh_source_count": fresh,
        "blocked_recycled_source_count": recycled,
        "blocked_new_source_count": blocked_new,
        "scanned_source_count": as_int(pressure_row.get("scanned_source_count")),
        "source_count": len(sources),
        "source_ids": [row["source_id"] for row in sources],
        "source_signal_requirements": rules["source_signal_requirements"],
        "nonpayoff_requirement": rules["nonpayoff_requirement"],
        "status": status,
        "next_evidence": next_evidence,
        "external_cut_permission_now": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
    }


def choose_status_and_next_gate(rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if any(row["status"] == "external_nonpayoff_corpus_blocked_fresh_sources_need_trace" for row in rows):
        return (
            "external_nonpayoff_same_lane_corpus_blocked_fresh_sources_need_trace",
            "collect_trace_for_new_same_lane_cut_source_hypotheses",
        )
    if any(row["status"] == "external_nonpayoff_corpus_needs_source_lane_discovery" for row in rows):
        return (
            "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
            "discover_same_lane_source_candidates_before_policy_mapping",
        )
    return (
        "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
        "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
    )


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def build_report(
    *,
    axis_broadening_report: Path,
    new_cut_source_miner_report: Path,
    package_source_report: Path,
) -> dict[str, Any]:
    axis_payload = load_json(axis_broadening_report)
    miner_payload = load_json(new_cut_source_miner_report)
    package_payload = load_json(package_source_report)
    axis_summary = axis_payload.get("summary") or {}
    miner_summary = miner_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    add_counts = selected_add_count_by_role(package_payload)
    role_rows = [
        classify_role_corpus(
            pressure_row=row,
            selected_add_count=add_counts.get(str(row.get("target_cut_role") or ""), 0),
        )
        for row in role_pressure_rows(axis_payload)
    ]
    status, next_gate = choose_status_and_next_gate(role_rows)
    exhausted_roles = [
        row
        for row in role_rows
        if row["status"] == "external_nonpayoff_corpus_collected_for_exhausted_same_lane_role"
    ]
    blockers = [
        "external_corpus_is_not_cut_permission",
        "target_deck_usage_and_stage_evidence_still_override_external_absence",
        "candidate_copy_closed_until_policy_maps_external_corpus_to_new_source_candidates",
        "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
    ]
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_same_lane_cut_corpus_collector",
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
            "axis_broadening_report": rel(axis_broadening_report),
            "new_cut_source_miner_report": rel(new_cut_source_miner_report),
            "package_source_report": rel(package_source_report),
        },
        "summary": {
            "deck_id": str(
                axis_summary.get("deck_id")
                or miner_summary.get("deck_id")
                or package_summary.get("deck_id")
                or ""
            ),
            "commander": str(
                axis_summary.get("commander")
                or miner_summary.get("commander")
                or package_summary.get("commander")
                or ""
            ),
            "target_role_count": len(role_rows),
            "external_source_count": len(SOURCE_CORPUS_SNAPSHOT),
            "role_corpus_count": len(role_rows),
            "exhausted_role_count": len(exhausted_roles),
            "fresh_same_lane_cut_source_count": as_int(miner_summary.get("fresh_same_lane_cut_source_count")),
            "blocked_recycled_cut_source_count": as_int(miner_summary.get("blocked_recycled_cut_source_count")),
            "ready_pair_count": as_int(axis_summary.get("ready_pair_count")),
            "unpaired_add_count": as_int(axis_summary.get("unpaired_add_count")),
            "role_status_counts": count_by(role_rows, "status"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "source_corpus_snapshot": SOURCE_CORPUS_SNAPSHOT,
        "role_corpus_rows": role_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "external_boundary": "External corpus can create source-policy lanes, but cannot authorize cutting used or stage-only cards.",
            "nonpayoff_boundary": "This pass is constrained to nonpayoff same-lane support; lands, commander, and payoff bodies remain excluded.",
            "trace_boundary": "Target-deck trace and card-level usage evidence remain stronger than external absence or popularity.",
            "battle_boundary": "No battle gate opens until candidate copy exists and the relevant added/cut cards are exercised.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Same-Lane Cut Corpus Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- target_role_count: `{summary['target_role_count']}`",
        f"- external_source_count: `{summary['external_source_count']}`",
        f"- role_corpus_count: `{summary['role_corpus_count']}`",
        f"- exhausted_role_count: `{summary['exhausted_role_count']}`",
        f"- fresh_same_lane_cut_source_count: `{summary['fresh_same_lane_cut_source_count']}`",
        f"- blocked_recycled_cut_source_count: `{summary['blocked_recycled_cut_source_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- external_cut_permission_now: `{str(payload['external_cut_permission_now']).lower()}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Role Corpus Rows",
        "",
        "| Role | Adds | Sources | Fresh | Recycled | Status | Next Evidence |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for row in payload["role_corpus_rows"]:
        lines.append(
            "| `{role}` | {adds} | {sources} | {fresh} | {recycled} | `{status}` | `{next}` |".format(
                role=row.get("target_cut_role"),
                adds=row.get("selected_add_count"),
                sources=row.get("source_count"),
                fresh=row.get("fresh_source_count"),
                recycled=row.get("blocked_recycled_source_count"),
                status=row.get("status"),
                next=row.get("next_evidence"),
            )
        )
    lines.extend(["", "## Source Corpus Snapshot", ""])
    for source in payload["source_corpus_snapshot"]:
        lines.append(
            "- `{source_id}` ({source_type}): {signal} ({url})".format(
                source_id=source["source_id"],
                source_type=source["source_type"],
                signal=source["observed_signal"],
                url=source["url"],
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
    parser.add_argument("--axis-broadening-report", type=Path, default=DEFAULT_AXIS_BROADENING_REPORT)
    parser.add_argument("--new-cut-source-miner-report", type=Path, default=DEFAULT_NEW_CUT_SOURCE_MINER_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        axis_broadening_report=args.axis_broadening_report,
        new_cut_source_miner_report=args.new_cut_source_miner_report,
        package_source_report=args.package_source_report,
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
