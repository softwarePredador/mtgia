#!/usr/bin/env python3
"""Collect external Commander reference-corpus evidence for cut candidates.

This read-only gate consumes the external cut-source research plan and maps
current external corpus observations back to the named cut hypotheses. External
presence, absence, and bracket context are evidence lanes only; target-deck
usage and same-lane gates still decide whether a cut can move forward.
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
DEFAULT_RESEARCH_PLAN_REPORT = (
    REPORT_DIR / "global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_SAME_LANE_PROOF_REPORT = (
    REPORT_DIR / "global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
)


SOURCE_CORPUS_SNAPSHOT: list[dict[str, Any]] = [
    {
        "source_id": "edhrec_kaalia_current",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_public_usage",
        "commander_decks_observed": 37936,
        "commander_tags": ["Flying", "Angels", "Aggro", "Demons"],
        "evidence_use": "broad public Kaalia corpus for anchor/card presence and role hints",
        "limitation": "public popularity is not final deck truth or same-lane proof",
    },
    {
        "source_id": "edhrec_kaalia_expensive_midrange_2026_06_24",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/midrange/expensive",
        "observed_on": "2026-07-05",
        "source_type": "filtered_public_usage",
        "sample_decks_observed": 16,
        "commander_tags": ["Flying", "Angels", "Aggro", "Midrange"],
        "evidence_use": "small high-budget midrange comparison set for high-power anchors",
        "limitation": "small sample; useful only as corroborating evidence",
    },
    {
        "source_id": "edhrec_kaalia_hidden_gems_2026_03_26",
        "url": "https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast",
        "observed_on": "2026-07-05",
        "source_type": "commander_strategy_article",
        "strategy_signals": [
            "attack_to_cheat_angels_demons_dragons",
            "kill_on_sight_commander_needs_haste_or_protection",
            "recast_and_hardcast_recovery_matter_after_removal",
        ],
        "evidence_use": "protect attack-window, payoff-density, recast, and recovery lanes from generic cuts",
        "limitation": "qualitative strategy evidence, not a cut authorization",
    },
    {
        "source_id": "wizards_commander_brackets_2026_02_09",
        "url": "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026",
        "observed_on": "2026-07-05",
        "source_type": "official_commander_policy",
        "strategy_signals": ["brackets_active", "game_changers_active", "commander_policy_can_change"],
        "evidence_use": "bracket and Game Changer context for high-power staple risk",
        "limitation": "policy context only; not commander-specific fit evidence",
    },
    {
        "source_id": "wizards_commander_brackets_2025_10_21",
        "url": "https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025",
        "observed_on": "2026-07-05",
        "source_type": "official_commander_policy",
        "strategy_signals": [
            "bracket_3_strong_synergy_and_value_engines",
            "bracket_4_fast_mana_resource_engines_free_disruption_tutors",
        ],
        "evidence_use": "avoid treating optimized staples as generic over-target cut fodder",
        "limitation": "bracket intent is not same-lane replacement proof",
    },
]


CARD_CORPUS_SNAPSHOT: dict[str, dict[str, Any]] = {
    "Biotransference": {
        "source_support_level": "absent_from_checked_kaalia_sources",
        "observations": [
            {"source_id": "edhrec_kaalia_current", "present": False},
            {"source_id": "edhrec_kaalia_expensive_midrange_2026_06_24", "present": False},
        ],
        "corpus_meaning": "No checked Kaalia public corpus signal; still not cut-safe when target traces use it.",
    },
    "Maskwood Nexus": {
        "source_support_level": "absent_from_checked_kaalia_sources",
        "observations": [
            {"source_id": "edhrec_kaalia_current", "present": False},
            {"source_id": "edhrec_kaalia_expensive_midrange_2026_06_24", "present": False},
        ],
        "corpus_meaning": "No checked Kaalia public corpus signal; target usage blocks automatic removal.",
    },
    "Sigarda's Aid": {
        "source_support_level": "absent_from_checked_kaalia_sources",
        "observations": [
            {"source_id": "edhrec_kaalia_current", "present": False},
            {"source_id": "edhrec_kaalia_expensive_midrange_2026_06_24", "present": False},
        ],
        "corpus_meaning": "No checked Kaalia public corpus signal; equipment/support lanes still need negative trace or same-lane proof.",
    },
    "Necromancy": {
        "source_support_level": "commander_corpus_present",
        "observations": [
            {
                "source_id": "edhrec_kaalia_current",
                "present": True,
                "inclusion_percent": 6.1,
                "synergy_percent": 3,
            },
            {
                "source_id": "edhrec_kaalia_expensive_midrange_2026_06_24",
                "present": True,
                "inclusion_percent": 31,
                "synergy_percent": 28,
            },
        ],
        "corpus_meaning": "Reanimation support is externally present, especially in the filtered high-budget midrange sample.",
    },
    "Necropotence": {
        "source_support_level": "commander_corpus_present_high_power",
        "observations": [
            {
                "source_id": "edhrec_kaalia_current",
                "present": True,
                "inclusion_percent": 10,
                "synergy_percent": 5,
                "source_category": "Game Changers",
            },
            {
                "source_id": "edhrec_kaalia_expensive_midrange_2026_06_24",
                "present": True,
                "inclusion_percent": 50,
                "synergy_percent": 45,
                "source_category": "Game Changers",
            },
        ],
        "corpus_meaning": "High-power card-flow engine with bracket/Game Changer context; not generic draw cut fodder.",
    },
    "Trouble in Pairs": {
        "source_support_level": "commander_corpus_present",
        "observations": [
            {
                "source_id": "edhrec_kaalia_current",
                "present": True,
                "inclusion_percent": 6.2,
                "synergy_percent": 1,
            },
            {
                "source_id": "edhrec_kaalia_expensive_midrange_2026_06_24",
                "present": True,
                "inclusion_percent": 13,
                "synergy_percent": 7,
            },
        ],
        "corpus_meaning": "Card-flow/protection-adjacent public signal exists; seen-without-usage still requires negative review.",
    },
    "Puresteel Paladin": {
        "source_support_level": "absent_from_checked_kaalia_sources",
        "observations": [
            {"source_id": "edhrec_kaalia_current", "present": False},
            {"source_id": "edhrec_kaalia_expensive_midrange_2026_06_24", "present": False},
        ],
        "corpus_meaning": "No checked Kaalia public corpus signal; seen-without-usage still needs negative or force-access review.",
    },
    "Sram, Senior Edificer": {
        "source_support_level": "absent_from_checked_kaalia_sources",
        "observations": [
            {"source_id": "edhrec_kaalia_current", "present": False},
            {"source_id": "edhrec_kaalia_expensive_midrange_2026_06_24", "present": False},
        ],
        "corpus_meaning": "No checked Kaalia public corpus signal; target usage still blocks value-safe reclassification.",
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


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def trace_rows_by_card(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in payload.get("hypothesis_same_lane_rows") or []:
        if not isinstance(row, Mapping):
            continue
        name = str(row.get("cut_card") or "")
        if name:
            rows[name] = dict(row)
    return rows


def research_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in payload.get("hypothesis_external_research_rows") or []
        if isinstance(row, Mapping) and row.get("cut_card")
    ]


def corpus_observation_for(card: str) -> dict[str, Any]:
    return dict(
        CARD_CORPUS_SNAPSHOT.get(
            card,
            {
                "source_support_level": "not_collected",
                "observations": [],
                "corpus_meaning": "No external corpus snapshot has been collected for this card yet.",
            },
        )
    )


def classify_card_corpus(*, research_row: Mapping[str, Any], trace_row: Mapping[str, Any]) -> dict[str, Any]:
    card = str(research_row.get("cut_card") or trace_row.get("cut_card") or "")
    trace_group = str(research_row.get("trace_group") or trace_row.get("trace_group") or "")
    roles = as_list(research_row.get("cut_roles")) or as_list(trace_row.get("cut_roles"))
    corpus = corpus_observation_for(card)
    support = str(corpus.get("source_support_level") or "not_collected")
    if trace_group == "usage_blocked" and support.startswith("commander_corpus_present"):
        status = "external_corpus_supports_preserve_or_strict_same_lane_proof"
        decision = "do_not_cut_without_same_lane_or_equal_gate"
    elif trace_group == "usage_blocked":
        status = "external_absence_cannot_override_target_usage"
        decision = "do_not_cut_from_absence_only"
    elif trace_group == "seen_without_usage" and support.startswith("commander_corpus_present"):
        status = "external_presence_requires_negative_trace_before_cut"
        decision = "negative_trace_required_before_cut_consideration"
    elif trace_group == "seen_without_usage":
        status = "external_absence_plus_seen_without_usage_requires_negative_review"
        decision = "negative_or_force_access_required_before_cut_consideration"
    else:
        status = "external_corpus_requires_more_internal_trace"
        decision = "more_trace_required_before_cut_consideration"
    return {
        "cut_card": card,
        "trace_group": trace_group,
        "cut_roles": roles,
        "research_lane": research_row.get("research_lane"),
        "source_support_level": support,
        "corpus_status": status,
        "corpus_decision": decision,
        "observations": corpus.get("observations") or [],
        "corpus_meaning": corpus.get("corpus_meaning") or "",
        "external_cut_permission_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def build_report(*, research_plan_report: Path, same_lane_proof_report: Path) -> dict[str, Any]:
    research_payload = load_json(research_plan_report)
    same_lane_payload = load_json(same_lane_proof_report)
    research_summary = research_payload.get("summary") or {}
    trace_by_card = trace_rows_by_card(same_lane_payload)
    rows = [
        classify_card_corpus(
            research_row=row,
            trace_row=trace_by_card.get(str(row.get("cut_card") or ""), {}),
        )
        for row in research_rows(research_payload)
    ]
    support_counts: dict[str, int] = {}
    status_counts: dict[str, int] = {}
    for row in rows:
        support_counts[str(row["source_support_level"])] = support_counts.get(str(row["source_support_level"]), 0) + 1
        status_counts[str(row["corpus_status"])] = status_counts.get(str(row["corpus_status"]), 0) + 1
    return {
        "generated_at": utc_now(),
        "status": "external_reference_corpus_collected_no_cut_permission",
        "artifact_type": "global_commander_external_reference_corpus_collector",
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
            "research_plan_report": rel(research_plan_report),
            "same_lane_proof_report": rel(same_lane_proof_report),
        },
        "summary": {
            "deck_id": str(research_summary.get("deck_id") or ""),
            "commander": str(research_summary.get("commander") or ""),
            "hypothesis_count": len(rows),
            "source_count": len(SOURCE_CORPUS_SNAPSHOT),
            "commander_public_decks_observed": 37936,
            "filtered_midrange_sample_decks": 16,
            "corpus_present_count": sum(1 for row in rows if str(row["source_support_level"]).startswith("commander_corpus_present")),
            "corpus_absent_count": sum(1 for row in rows if row["source_support_level"] == "absent_from_checked_kaalia_sources"),
            "usage_blocked_count": sum(1 for row in rows if row["trace_group"] == "usage_blocked"),
            "seen_without_usage_count": sum(1 for row in rows if row["trace_group"] == "seen_without_usage"),
            "support_counts": support_counts,
            "corpus_status_counts": status_counts,
            "next_gate": "map_external_corpus_to_cut_policy_before_rerun_miner",
        },
        "source_corpus_snapshot": SOURCE_CORPUS_SNAPSHOT,
        "card_corpus_rows": rows,
        "candidate_copy_blockers": [
            "external_corpus_is_not_cut_permission",
            "used_cards_still_require_same_lane_or_equal_gate_proof",
            "seen_without_usage_cards_still_require_negative_or_force_access_review",
            "candidate_copy_closed_until_corpus_maps_to_internal_cut_policy_and_trace_evidence",
        ],
        "policy": {
            "source_boundary": "External corpus presence protects or routes review; absence is not proof that a used card is safe to cut.",
            "trace_boundary": "Target-deck usage remains stronger than public-corpus absence.",
            "bracket_boundary": "Game Changer and bracket context marks high-power staples as context-sensitive, not generic cuts.",
            "mutation_boundary": "This collector does not copy decks, mutate DBs, run battles, reclassify cuts, or promote a package.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Reference Corpus Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- source_count: `{summary['source_count']}`",
        f"- commander_public_decks_observed: `{summary['commander_public_decks_observed']}`",
        f"- filtered_midrange_sample_decks: `{summary['filtered_midrange_sample_decks']}`",
        f"- corpus_present_count: `{summary['corpus_present_count']}`",
        f"- corpus_absent_count: `{summary['corpus_absent_count']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Card Corpus Rows",
        "",
        "| Cut | Trace | Corpus Support | Corpus Status | Decision |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["card_corpus_rows"]:
        lines.append(
            "| `{card}` | `{trace}` | `{support}` | `{status}` | `{decision}` |".format(
                card=row.get("cut_card"),
                trace=row.get("trace_group"),
                support=row.get("source_support_level"),
                status=row.get("corpus_status"),
                decision=row.get("corpus_decision"),
            )
        )
    lines.extend(["", "## Source Corpus Snapshot", ""])
    for source in payload["source_corpus_snapshot"]:
        lines.append(f"- `{source['source_id']}`: {source['evidence_use']} ({source['url']})")
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
    parser.add_argument("--research-plan-report", type=Path, default=DEFAULT_RESEARCH_PLAN_REPORT)
    parser.add_argument("--same-lane-proof-report", type=Path, default=DEFAULT_SAME_LANE_PROOF_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        research_plan_report=args.research_plan_report,
        same_lane_proof_report=args.same_lane_proof_report,
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
