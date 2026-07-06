#!/usr/bin/env python3
"""Broaden live external nonpayoff research after manual trace review blocks.

This read-only gate follows
``global_commander_external_nonpayoff_manual_negative_trace_reviewer``. It
continues the live source-research lane without recycling already exhausted
cards, and emits only review seeds. It does not create cut permission, copy a
deck, mutate any DB, run battles, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_external_nonpayoff_live_source_research_expander as live
import global_commander_external_nonpayoff_source_candidate_pool_expander as expander
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXHAUSTED_EXPANDER_REPORT = live.DEFAULT_EXHAUSTED_EXPANDER_REPORT
DEFAULT_MANUAL_NEGATIVE_TRACE_REVIEWER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_manual_negative_trace_reviewer_20260706_kaalia_value_safe_stage1_live_research.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_followup_live_source_research_expander_20260706_kaalia_value_safe_stage1_after_manual_trace"
)

PREVIOUS_LIVE_REPORTS: tuple[Path, ...] = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_live_source_research_expander_20260706_kaalia_value_safe_stage1_repair_scope1.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_live_research.json",
    REPORT_DIR
    / "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_live_research.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_live_research.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_live_research.json",
)

FOLLOWUP_SOURCE_SNAPSHOTS: tuple[dict[str, Any], ...] = (
    {
        "source_id": "edhrec_kaalia_default_followup_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-06",
        "source_type": "commander_aggregate_card_page",
        "signal": "The current Kaalia aggregate still surfaces lower-share support cards such as Black Market Connections while already-reviewed staples remain recycled.",
        "guardrail": "aggregate presence is source evidence only and cannot authorize add/cut actions",
    },
    {
        "source_id": "edhrec_black_market_connections_card_2026_07_06",
        "url": "https://edhrec.com/cards/black-market-connections",
        "observed_on": "2026-07-06",
        "source_type": "card_aggregate_page",
        "signal": "Black Market Connections appears in Kaalia decks as a card-advantage and Treasure source.",
        "guardrail": "card-page usage does not prove it beats current target-deck ramp or draw slots",
    },
    {
        "source_id": "mtgsalvation_dolmen_gate_kaalia_context_2012_08_08",
        "url": "https://www.mtgsalvation.com/forums/the-game/commander-edh/201424-scd-dolmen-gate",
        "observed_on": "2026-07-06",
        "source_type": "historical_commander_card_discussion",
        "signal": "Dolmen Gate and Reconnaissance are discussed as Kaalia attack-combat protection methods.",
        "guardrail": "historical discussion is weak source evidence and requires local review plus battle gates",
    },
    {
        "source_id": "edhtop16_kaalia_followup_2026_07_06",
        "url": "https://edhtop16.com/commander/Kaalia%20of%20the%20Vast",
        "observed_on": "2026-07-06",
        "source_type": "cedh_results_commander_page",
        "signal": "High-power Kaalia context favors low-cost protection, mana, and tutor access but is sparse and must not override target traces.",
        "guardrail": "tournament presence is bracket context only, not package promotion proof",
    },
    {
        "source_id": "local_oracle_followup_functional_terms_2026_07_06",
        "url": "local:card_oracle_cache",
        "observed_on": "2026-07-06",
        "source_type": "local_oracle_text_crosscheck",
        "signal": "Local Oracle text resolves fresh protection, Treasure, and tutor/access candidates before any review seed is emitted.",
        "guardrail": "local role text is necessary but not card-level cut permission",
    },
)

FOLLOWUP_LIVE_SOURCE_CANDIDATES: tuple[dict[str, Any], ...] = (
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Deflecting Swat",
        "candidate_signal": "free commander protection used as a recycle check after earlier source passes",
        "source_ids": ["edhtop16_kaalia_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Akroma's Will",
        "candidate_signal": "commander-enabled protection and alpha-strike spell used as a recycle check",
        "source_ids": ["edhtop16_kaalia_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Dolmen Gate",
        "candidate_signal": "combat-damage prevention for attacking Kaalia lines",
        "source_ids": [
            "mtgsalvation_dolmen_gate_kaalia_context_2012_08_08",
            "local_oracle_followup_functional_terms_2026_07_06",
        ],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Alseid of Life's Bounty",
        "candidate_signal": "one-mana sacrifice protection source from local functional search",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Benevolent Bodyguard",
        "candidate_signal": "one-mana creature protection source from local functional search",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Gods Willing",
        "candidate_signal": "one-mana protection spell from local functional search",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Black Market Connections",
        "candidate_signal": "Treasure and card flow source surfaced by EDHREC Kaalia/card pages",
        "source_ids": [
            "edhrec_kaalia_default_followup_2026_07_06",
            "edhrec_black_market_connections_card_2026_07_06",
        ],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Curse of Opulence",
        "candidate_signal": "one-mana Treasure pressure source from local functional search",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Culling the Weak",
        "candidate_signal": "burst black acceleration requiring sacrifice context",
        "source_ids": ["edhtop16_kaalia_followup_2026_07_06", "local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Insatiable Avarice",
        "candidate_signal": "low-cost conditional tutor/card-flow spell from local functional search",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Tainted Pact",
        "candidate_signal": "instant-speed high-power singleton tutor/access spell requiring bracket context",
        "source_ids": ["edhtop16_kaalia_followup_2026_07_06", "local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Demonic Consultation",
        "candidate_signal": "one-mana high-risk tutor/access spell requiring combo/bracket review",
        "source_ids": ["edhtop16_kaalia_followup_2026_07_06", "local_oracle_followup_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Moonsilver Key",
        "candidate_signal": "artifact access for mana-rock/package targets",
        "source_ids": ["local_oracle_followup_functional_terms_2026_07_06"],
    },
)


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


def count_by(rows: Iterable[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def previous_report_paths(
    *,
    exhausted_payload: Mapping[str, Any],
    exhausted_expander_report: Path,
    manual_negative_trace_reviewer_report: Path,
) -> tuple[Path, ...]:
    paths = list(live.cumulative_previous_report_paths(exhausted_payload, exhausted_expander_report))
    paths.extend(PREVIOUS_LIVE_REPORTS)
    paths.append(manual_negative_trace_reviewer_report)
    deduped: list[Path] = []
    seen: set[str] = set()
    for path in paths:
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(path)
    return tuple(deduped)


def choose_status_and_next_gate(ready_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if ready_rows:
        return (
            "external_nonpayoff_followup_live_source_research_expanded_ready_for_local_review",
            "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
        )
    return (
        "external_nonpayoff_followup_live_source_research_found_no_ready_candidates",
        "broaden_external_nonpayoff_source_research_with_new_source_types",
    )


def build_report(
    *,
    exhausted_expander_report: Path,
    manual_negative_trace_reviewer_report: Path,
    candidate_rows: Iterable[Mapping[str, Any]] = FOLLOWUP_LIVE_SOURCE_CANDIDATES,
) -> dict[str, Any]:
    exhausted_payload = load_json(exhausted_expander_report)
    manual_payload = load_json(manual_negative_trace_reviewer_report)
    exhausted_summary = exhausted_payload.get("summary") or {}
    manual_summary = manual_payload.get("summary") or {}
    deck_id = str(exhausted_summary.get("deck_id") or manual_summary.get("deck_id") or "")
    selected_db = expander.resolve_selected_db(live.selected_db_from_payload(exhausted_payload))
    indexes = expander.finder.db_indexes(selected_db, deck_id)
    previous_reports = previous_report_paths(
        exhausted_payload=exhausted_payload,
        exhausted_expander_report=exhausted_expander_report,
        manual_negative_trace_reviewer_report=manual_negative_trace_reviewer_report,
    )
    recycled_names = expander.previous_report_names(previous_reports)
    expansion_rows = [
        expander.classify_candidate(
            candidate,
            indexes=indexes,
            reviewed_names=recycled_names,
            finder_names=set(),
        )
        for candidate in candidate_rows
    ]
    ready_rows = [row for row in expansion_rows if row["miner_source_seed_allowed"]]
    status, next_gate = choose_status_and_next_gate(ready_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_followup_live_source_research_expander",
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
        "card_level_cut_permission_now": False,
        "input_artifacts": {
            "exhausted_expander_report": rel(exhausted_expander_report),
            "manual_negative_trace_reviewer_report": rel(manual_negative_trace_reviewer_report),
            "previous_reports": [rel(path) for path in previous_reports],
            "selected_db": rel(selected_db),
        },
        "source_snapshots": FOLLOWUP_SOURCE_SNAPSHOTS,
        "summary": {
            "deck_id": deck_id,
            "commander": str(exhausted_summary.get("commander") or manual_summary.get("commander") or ""),
            "manual_trace_review_status": str(manual_payload.get("status") or ""),
            "manual_negative_review_cleared_count": int(
                (manual_summary.get("manual_negative_review_cleared_count") or 0)
            ),
            "previous_report_count": len(previous_reports),
            "cumulative_previous_candidate_name_count": len(recycled_names),
            "followup_source_count": len(FOLLOWUP_SOURCE_SNAPSHOTS),
            "followup_candidate_count": len(expansion_rows),
            "followup_ready_for_review_count": len(ready_rows),
            "ready_count_by_role": count_by(ready_rows, "target_cut_role"),
            "status_counts": count_by(expansion_rows, "status"),
            "seed_scope_counts": count_by(ready_rows, "seed_scope"),
            "candidate_copy_allowed_count": 0,
            "card_level_cut_permission_count": 0,
            "next_gate": next_gate,
        },
        "expanded_source_candidate_rows": expansion_rows,
        "ready_expanded_source_candidate_rows": ready_rows,
        "candidate_copy_blockers": [
            "manual_negative_trace_review_did_not_clear_current_deck_cuts",
            "followup_live_candidates_are_review_seeds_not_cut_permission",
            "cumulative_previous_candidates_remain_recycled_and_blocked",
            "card_level_cut_permission_requires_seeded_miner_trace_and_equal_gate",
            "candidate_copy_closed_until_reviewed_seed_finds_traceable_current_deck_cut_source",
        ],
        "policy": {
            "manual_trace_boundary": "Manual trace review can block weak negative evidence but does not authorize cuts.",
            "followup_research_boundary": "Follow-up live research broadens source lanes only; it does not authorize adds or cuts.",
            "recycling_boundary": "Any card seen in prior source, review, miner, router, or manual reports remains recycled and blocked.",
            "local_identity_boundary": "Candidates must resolve locally and match role text before becoming review seeds.",
            "mutation_boundary": "This expander does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Followup Live Source Research Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- manual_trace_review_status: `{summary['manual_trace_review_status']}`",
        f"- manual_negative_review_cleared_count: `{summary['manual_negative_review_cleared_count']}`",
        f"- previous_report_count: `{summary['previous_report_count']}`",
        f"- cumulative_previous_candidate_name_count: `{summary['cumulative_previous_candidate_name_count']}`",
        f"- followup_source_count: `{summary['followup_source_count']}`",
        f"- followup_candidate_count: `{summary['followup_candidate_count']}`",
        f"- followup_ready_for_review_count: `{summary['followup_ready_for_review_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Ready Followup Source Candidates",
        "",
        "| Role | Card | Scope | Evidence Terms | Sources |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["ready_expanded_source_candidate_rows"]:
        terms = ", ".join(row.get("local_role_evidence_terms") or [])
        sources = ", ".join(row.get("source_ids") or [])
        lines.append(
            f"| `{row['target_cut_role']}` | `{row['card_name']}` | `{row['seed_scope']}` | `{terms}` | `{sources}` |"
        )
    lines.extend(["", "## All Followup Candidates", ""])
    lines.append("| Role | Card | Status | In Deck | Legal | Recycled |")
    lines.append("| --- | --- | --- | ---: | ---: | ---: |")
    for row in payload["expanded_source_candidate_rows"]:
        lines.append(
            "| `{role}` | `{card}` | `{status}` | {deck} | `{legal}` | {recycled} |".format(
                role=row.get("target_cut_role"),
                card=row.get("card_name"),
                status=row.get("status"),
                deck=str(row.get("current_deck_present")).lower(),
                legal=row.get("commander_legality_status"),
                recycled=str(row.get("recycled_from_prior_external_seed")).lower(),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## External Sources", ""])
    for source in payload["source_snapshots"]:
        lines.append(f"- `{source['source_id']}`: {source['url']}")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exhausted-expander-report", type=Path, default=DEFAULT_EXHAUSTED_EXPANDER_REPORT)
    parser.add_argument(
        "--manual-negative-trace-reviewer-report",
        type=Path,
        default=DEFAULT_MANUAL_NEGATIVE_TRACE_REVIEWER_REPORT,
    )
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        exhausted_expander_report=args.exhausted_expander_report,
        manual_negative_trace_reviewer_report=args.manual_negative_trace_reviewer_report,
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
