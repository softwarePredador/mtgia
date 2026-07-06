#!/usr/bin/env python3
"""Broaden external nonpayoff source research after cumulative pools exhaust.

This read-only gate follows
``global_commander_external_nonpayoff_source_candidate_pool_expander`` when a
cumulative rerun finds no ready candidates. It records live external research
lanes, maps newly observed nonpayoff support cards into the existing expanded
source-candidate row shape, and keeps all deck actions closed.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_external_nonpayoff_source_candidate_pool_expander as expander
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXHAUSTED_EXPANDER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_followup_cumulative.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_live_source_research_expander_20260706_kaalia_value_safe_stage1_repair_scope1"
)


LIVE_SOURCE_SNAPSHOTS: tuple[dict[str, Any], ...] = (
    {
        "source_id": "edhrec_kaalia_hidden_gems_2026_03_26",
        "url": "https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast",
        "observed_on": "2026-07-06",
        "source_type": "commander_strategy_article",
        "signal": "Kaalia needs haste/protection windows and can use Sword of the Animist, Simian Spirit Guide, and Dihada as underplayed support lanes.",
        "guardrail": "article recommendations are source lanes only and do not authorize add/cut actions",
    },
    {
        "source_id": "draftsim_kaalia_guide_2026_07_06",
        "url": "https://draftsim.com/kaalia-of-the-vast-edh-deck/",
        "observed_on": "2026-07-06",
        "source_type": "commander_deck_guide",
        "signal": "The guide highlights reanimation/ramp redundancy, Fable of the Mirror-Breaker, Collector's Vault, and haste lands as Kaalia support.",
        "guardrail": "guide context must be rechecked against current deck presence, role text, and Commander legality",
    },
    {
        "source_id": "commanders_herald_silence_abolisher_2023_12_20",
        "url": "https://commandersherald.com/5-more-silences-and-grand-abolishers-for-cedh/",
        "observed_on": "2026-07-06",
        "source_type": "role_strategy_article",
        "signal": "Silence, Grand Abolisher, and Orim's Chant represent white turn-protection effects that can defend a decisive turn.",
        "guardrail": "cEDH silence context is role evidence, not proof the card belongs in this target list",
    },
    {
        "source_id": "local_scryfall_oracle_cache_functional_terms_2026_07_06",
        "url": "local:card_oracle_cache",
        "observed_on": "2026-07-06",
        "source_type": "local_oracle_text_crosscheck",
        "signal": "Local Oracle text resolves additional Mardu protection and mana sources before any review seed is emitted.",
        "guardrail": "local identity and role text are necessary but still not cut permission",
    },
)


LIVE_SOURCE_CANDIDATES: tuple[dict[str, Any], ...] = (
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Loran's Escape",
        "candidate_signal": "cheap hexproof/indestructible protection from local Oracle search",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Rebuff the Wicked",
        "candidate_signal": "one-mana counterspell for spells targeting a permanent you control",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Malakir Rebirth",
        "candidate_signal": "modal creature death protection for commander or payoff recovery",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Clever Concealment",
        "candidate_signal": "board-wide phase-out protection from local Oracle search",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Flawless Maneuver",
        "candidate_signal": "commander-enabled free indestructible protection spell",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Galadriel's Dismissal",
        "candidate_signal": "single-target or kicked board phase-out protection",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Unbreakable Formation",
        "candidate_signal": "board indestructible and combat pressure protection",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Orim's Chant",
        "candidate_signal": "one-mana silence effect surfaced by broader silence role research",
        "source_ids": ["commanders_herald_silence_abolisher_2023_12_20"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Grand Abolisher",
        "candidate_signal": "turn-protection creature from silence role research, expected to be blocked if already in deck",
        "source_ids": ["commanders_herald_silence_abolisher_2023_12_20"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Silence",
        "candidate_signal": "premier white silence effect, expected to be blocked if already in deck",
        "source_ids": ["commanders_herald_silence_abolisher_2023_12_20"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Sword of the Animist",
        "candidate_signal": "Kaalia attack-trigger basic-land ramp from EDHREC hidden gems",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Simian Spirit Guide",
        "candidate_signal": "burst acceleration to cast Kaalia earlier from EDHREC hidden gems",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Dihada, Binder of Wills",
        "candidate_signal": "legendary protection and Treasure support from EDHREC hidden gems",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Fable of the Mirror-Breaker",
        "candidate_signal": "looting plus Treasure ramp support from Draftsim Kaalia guide",
        "source_ids": ["draftsim_kaalia_guide_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Collector's Vault",
        "candidate_signal": "loot plus Treasure generation support from Draftsim Kaalia guide",
        "source_ids": ["draftsim_kaalia_guide_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mind Stone",
        "candidate_signal": "generic two-mana rock baseline for curve-pressure comparison",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Conviction",
        "candidate_signal": "Mardu two-mana color rock baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Indulgence",
        "candidate_signal": "Mardu two-mana color rock baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Hierarchy",
        "candidate_signal": "Mardu two-mana color rock baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Boros Signet",
        "candidate_signal": "Mardu two-mana signet baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Rakdos Signet",
        "candidate_signal": "Mardu two-mana signet baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Orzhov Signet",
        "candidate_signal": "Mardu two-mana signet baseline",
        "source_ids": ["local_scryfall_oracle_cache_functional_terms_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Hall of the Bandit Lord",
        "candidate_signal": "haste land from EDHREC hidden gems, expected to route to land lane",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Arena of Glory",
        "candidate_signal": "haste land from Draftsim guide, expected to block if already in current deck",
        "source_ids": ["draftsim_kaalia_guide_2026_07_06"],
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


def selected_db_from_payload(payload: Mapping[str, Any]) -> Path:
    inputs = payload.get("input_artifacts") or {}
    raw = str(inputs.get("selected_db") or "").strip()
    if raw:
        candidate = Path(raw)
        return candidate if candidate.is_absolute() else REPO_ROOT / candidate
    return expander.resolve_selected_db(expander.DEFAULT_SELECTED_DB)


def cumulative_previous_report_paths(payload: Mapping[str, Any], exhausted_report: Path) -> tuple[Path, ...]:
    inputs = payload.get("input_artifacts") or {}
    paths: list[Path] = [exhausted_report]
    for raw in inputs.get("previous_reports") or []:
        path = Path(str(raw))
        paths.append(path if path.is_absolute() else REPO_ROOT / path)
    return tuple(paths)


def choose_status_and_next_gate(ready_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if ready_rows:
        return (
            "external_nonpayoff_live_source_research_expanded_ready_for_local_review",
            "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
        )
    return (
        "external_nonpayoff_live_source_research_found_no_ready_candidates",
        "broaden_external_nonpayoff_source_research_with_new_source_types",
    )


def build_report(
    *,
    exhausted_expander_report: Path,
    candidate_rows: Iterable[Mapping[str, Any]] = LIVE_SOURCE_CANDIDATES,
) -> dict[str, Any]:
    exhausted_payload = load_json(exhausted_expander_report)
    summary = exhausted_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    selected_db = expander.resolve_selected_db(selected_db_from_payload(exhausted_payload))
    indexes = expander.finder.db_indexes(selected_db, deck_id)
    previous_reports = cumulative_previous_report_paths(exhausted_payload, exhausted_expander_report)
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
        "artifact_type": "global_commander_external_nonpayoff_live_source_research_expander",
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
            "previous_reports": [rel(path) for path in previous_reports],
            "selected_db": rel(selected_db),
        },
        "source_snapshots": LIVE_SOURCE_SNAPSHOTS,
        "summary": {
            "deck_id": deck_id,
            "commander": str(summary.get("commander") or ""),
            "prior_expander_status": str(exhausted_payload.get("status") or ""),
            "previous_report_count": len(previous_reports),
            "cumulative_previous_candidate_name_count": len(recycled_names),
            "live_source_count": len(LIVE_SOURCE_SNAPSHOTS),
            "live_candidate_count": len(expansion_rows),
            "live_ready_for_review_count": len(ready_rows),
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
            "live_external_candidates_are_review_seeds_not_cut_permission",
            "cumulative_previous_candidates_remain_recycled_and_blocked",
            "current_deck_cards_need_trace_or_negative_review_before_cut_consideration",
            "land_lane_candidates_route_to_mana_base_model",
            "candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source",
        ],
        "policy": {
            "live_research_boundary": "Live external research broadens evidence lanes only; it does not authorize adds or cuts.",
            "recycling_boundary": "Any card seen in prior source reports remains recycled and blocked.",
            "local_identity_boundary": "Candidates must resolve in the local Oracle cache before becoming review seeds.",
            "mutation_boundary": "This expander does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Live Source Research Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- prior_expander_status: `{summary['prior_expander_status']}`",
        f"- previous_report_count: `{summary['previous_report_count']}`",
        f"- cumulative_previous_candidate_name_count: `{summary['cumulative_previous_candidate_name_count']}`",
        f"- live_source_count: `{summary['live_source_count']}`",
        f"- live_candidate_count: `{summary['live_candidate_count']}`",
        f"- live_ready_for_review_count: `{summary['live_ready_for_review_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Ready Live Source Candidates",
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
    lines.extend(["", "## All Live Candidates", ""])
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
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exhausted-expander-report", type=Path, default=DEFAULT_EXHAUSTED_EXPANDER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(exhausted_expander_report=args.exhausted_expander_report)
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
