#!/usr/bin/env python3
"""Expand external nonpayoff source candidates after reviewed seeds exhaust.

This read-only gate follows
``global_commander_external_nonpayoff_seed_exhaustion_recovery_router`` when it
routes to source expansion. It uses current external source snapshots plus the
local evaluation DB to create a broader review pool without recycling already
reviewed seeds. It does not create cut permission, copy a deck, mutate any DB,
run battle, reclassify value-safe cuts, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_external_nonpayoff_new_source_or_replacement_finder as finder
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RECOVERY_ROUTER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.json"
)
DEFAULT_PREVIOUS_REVIEWER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PREVIOUS_FINDER_REPORT = finder.DEFAULT_OUT_PREFIX.with_suffix(".json")
DEFAULT_SELECTED_DB = finder.DEFAULT_SELECTED_DB
FALLBACK_SELECTED_DB = finder.FALLBACK_SELECTED_DB
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources"
)

PREVIOUS_REPORT_RECYCLING_KEYS = (
    "new_external_source_rows",
    "ready_new_external_source_rows",
    "review_rows",
    "miner_source_seed_rows",
    "expanded_source_candidate_rows",
    "ready_expanded_source_candidate_rows",
)

COMMANDER_IDENTITY = finder.COMMANDER_IDENTITY

EXPANSION_SOURCE_SNAPSHOTS: tuple[dict[str, Any], ...] = (
    {
        "source_id": "edhrec_kaalia_default_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-06",
        "source_type": "commander_aggregate_card_page",
        "signal": "Default Kaalia aggregate highlights Swiftfoot Boots, Boros Charm, Teferi's Protection, Mother of Runes, and Fellwar Stone among high-usage support cards.",
        "guardrail": "aggregate popularity is a source lane only and cannot override local deck trace evidence",
    },
    {
        "source_id": "edhrec_kaalia_optimized_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/optimized",
        "observed_on": "2026-07-06",
        "source_type": "commander_optimized_card_page",
        "signal": "Optimized Kaalia aggregate broadens mana artifacts to Fellwar Stone, Chromatic Lantern, Lotus Petal, Chrome Mox, Mox Diamond, Mox Amber, Thought Vessel, and Mox Opal.",
        "guardrail": "optimized/high-power presence requires bracket and game-changer context before any add approval",
    },
    {
        "source_id": "edhrec_kaalia_expensive_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/expensive",
        "observed_on": "2026-07-06",
        "source_type": "commander_expensive_card_page",
        "signal": "Expensive Kaalia aggregate surfaces Mithril Coat, Wishclaw Talisman, and Whispersilk Cloak as additional support/access candidates.",
        "guardrail": "expensive-meta presence is not affordability, cut, or candidate-copy permission",
    },
    {
        "source_id": "wizards_commander_bans_2024_09_23",
        "url": "https://magic.wizards.com/en/news/announcements/commander-banned-and-restricted-announcement-september-23-2024",
        "observed_on": "2026-07-06",
        "source_type": "official_ban_announcement",
        "signal": "Dockside Extortionist, Jeweled Lotus, Mana Crypt, and Nadu were banned in Commander effective September 23, 2024.",
        "guardrail": "banned cards are blockers, not candidate seeds",
    },
    {
        "source_id": "mtgcommander_current_banned_list_2026_07_06",
        "url": "https://mtgcommander.net/index.php/banned-list/",
        "observed_on": "2026-07-06",
        "source_type": "official_commander_banned_list",
        "signal": "The Commander banned list is the current legality guardrail for candidate expansion.",
        "guardrail": "legality is necessary but not strategic proof",
    },
)

EXPANDED_SOURCE_CANDIDATES: tuple[dict[str, Any], ...] = (
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Swiftfoot Boots",
        "candidate_signal": "high-use haste/hexproof equipment not present in the current evaluation deck",
        "source_ids": ["edhrec_kaalia_default_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Boros Charm",
        "candidate_signal": "instant-speed permanent protection from the default aggregate",
        "source_ids": ["edhrec_kaalia_default_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Teferi's Protection",
        "candidate_signal": "high-power protection spell surfaced as a game-changer/default support card",
        "source_ids": ["edhrec_kaalia_default_2026_07_06", "edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Mother of Runes",
        "candidate_signal": "creature-based repeated protection from the default aggregate",
        "source_ids": ["edhrec_kaalia_default_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Mithril Coat",
        "candidate_signal": "flash indestructible equipment from expensive/indestructible Kaalia aggregates",
        "source_ids": ["edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Whispersilk Cloak",
        "candidate_signal": "equipment protection/evasion from expensive Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Kaya's Ghostform",
        "candidate_signal": "low-cost resilience enchantment from optimized Kaalia support pool",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Rising of the Day",
        "candidate_signal": "haste anthem from expensive Kaalia support pool",
        "source_ids": ["edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Fellwar Stone",
        "candidate_signal": "two-mana mana artifact from default/optimized Kaalia aggregates",
        "source_ids": ["edhrec_kaalia_default_2026_07_06", "edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Chromatic Lantern",
        "candidate_signal": "color-fixing mana artifact from optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Lotus Petal",
        "candidate_signal": "one-shot acceleration from optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Chrome Mox",
        "candidate_signal": "high-power zero-mana acceleration from optimized/expensive Kaalia aggregates",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06", "edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mox Diamond",
        "candidate_signal": "high-power zero-mana acceleration from optimized/expensive Kaalia aggregates",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06", "edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mox Amber",
        "candidate_signal": "conditional zero-mana legendary acceleration from optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Thought Vessel",
        "candidate_signal": "two-mana utility rock from optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mox Opal",
        "candidate_signal": "conditional metalcraft acceleration from optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mana Vault",
        "candidate_signal": "high-power mana artifact seen in optimized lists but already present in the current evaluation deck",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mana Crypt",
        "candidate_signal": "historical high-power acceleration that must be rejected by current Commander legality",
        "source_ids": ["wizards_commander_bans_2024_09_23", "mtgcommander_current_banned_list_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Jeweled Lotus",
        "candidate_signal": "historical commander-specific acceleration that must be rejected by current Commander legality",
        "source_ids": ["wizards_commander_bans_2024_09_23", "mtgcommander_current_banned_list_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Dockside Extortionist",
        "candidate_signal": "historical treasure acceleration that must be rejected by current Commander legality",
        "source_ids": ["wizards_commander_bans_2024_09_23", "mtgcommander_current_banned_list_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Wishclaw Talisman",
        "candidate_signal": "artifact tutor/access card from expensive Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Gamble",
        "candidate_signal": "red high-power tutor surfaced in optimized/stax Kaalia aggregates",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Imperial Seal",
        "candidate_signal": "high-power topdeck tutor from expensive optimized Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_expensive_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Imperial Recruiter",
        "candidate_signal": "narrow creature tutor that can access selected low-power support creatures",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Recruiter of the Guard",
        "candidate_signal": "narrow creature tutor that can access selected low-toughness support creatures",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Demonic Counsel",
        "candidate_signal": "conditional tutor from optimized Kaalia sorcery pool",
        "source_ids": ["edhrec_kaalia_optimized_2026_07_06"],
    },
)

EXTRA_ROLE_TERMS: dict[str, tuple[str, ...]] = {
    "haste_protection_silence": (
        "shroud",
        "protection from",
        "protection from everything",
        "protection from the color",
        "protection from each color",
        "can't be blocked",
        "cannot be blocked",
        "phased out",
        "choose new targets",
        "remove target attacking creature",
        "return that card to the battlefield",
        "permanents you control gain indestructible",
        "creatures you control have haste",
        "life total can't change",
        "your life total can't change",
    ),
    "mana_acceleration": (
        "add one mana",
        "add one mana of any color",
        "add {c}",
        "add {w}",
        "add {b}",
        "add {r}",
        "add {r}, {w}, or {b}",
        "add {c} for each charge",
        "create a treasure",
        "basic land card",
        "onto the battlefield tapped",
    ),
    "tutors_access": (
        "search your library",
        "search your library for a card",
        "search your library for a creature card",
        "search your library for an enchantment card",
        "search your library for an equipment card",
        "search your library for a land card",
        "artifact card with mana value",
        "artifact or dragon card",
        "put that card into your hand",
        "put that card into your graveyard",
        "put one into your hand",
    ),
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


def resolve_selected_db(path: Path) -> Path:
    if path.exists():
        return path
    if FALLBACK_SELECTED_DB.exists():
        return FALLBACK_SELECTED_DB
    return path


def row_names(payload: Mapping[str, Any], keys: Iterable[str]) -> set[str]:
    names: set[str] = set()
    for key in keys:
        for row in payload.get(key) or []:
            if isinstance(row, Mapping):
                names.add(finder.normalize_name(row.get("card_name")))
                names.add(finder.split_face_normalized(row.get("card_name")))
                names.add(finder.normalize_name(row.get("source_card_name")))
                names.add(finder.split_face_normalized(row.get("source_card_name")))
    return {name for name in names if name}


def previous_report_names(paths: Iterable[Path]) -> set[str]:
    names: set[str] = set()
    for path in paths:
        if path.exists():
            names.update(row_names(load_json(path), PREVIOUS_REPORT_RECYCLING_KEYS))
    return names


def role_terms(role: str, oracle_row: Mapping[str, Any] | None) -> list[str]:
    terms = list(finder.role_terms(role, oracle_row))
    if not oracle_row:
        return terms
    text = " ".join(
        [
            str(oracle_row.get("oracle_text") or ""),
            str(oracle_row.get("type_line") or ""),
            " ".join(finder.parse_json_list(oracle_row.get("keywords_json"))),
        ]
    ).lower()
    for term in EXTRA_ROLE_TERMS.get(role, ()):
        if term in text and term not in terms:
            terms.append(term)
    return terms


def legality_status(indexes: Mapping[str, Any], keys: set[str]) -> str:
    for key in keys:
        status = indexes.get("legalities", {}).get(key)
        if status:
            return str(status)
    return "unknown"


def seed_scope(role: str, card_name: str, oracle_row: Mapping[str, Any] | None) -> str:
    type_line = str((oracle_row or {}).get("type_line") or "").lower()
    oracle_text = str((oracle_row or {}).get("oracle_text") or "").lower()
    normalized = finder.normalize_name(card_name)
    if role == "tutors_access":
        if "creature card with power" in oracle_text or "creature card with toughness" in oracle_text:
            return "narrow_creature_tutor_seed_package_target_required"
        if normalized in {"imperial seal", "gamble", "wishclaw talisman"}:
            return "high_power_generic_tutor_seed_bracket_context_required"
        return "conditional_tutor_seed_context_required"
    if role == "mana_acceleration":
        if normalized.startswith("mox") or normalized in {"chrome mox", "lotus petal"}:
            return "zero_mana_or_conditional_acceleration_seed_bracket_context_required"
        if normalized == "chromatic lantern":
            return "color_fixing_rock_seed_curve_pressure_review"
        return "mana_rock_seed_curve_pressure_review"
    if role == "haste_protection_silence":
        if "equipment" in type_line:
            return "equipment_haste_protection_seed"
        if "creature" in type_line:
            return "repeatable_creature_protection_seed"
        if "enchantment" in type_line:
            return "enchantment_resilience_or_haste_seed"
        return "protection_spell_or_haste_seed"
    return "role_seed_context_required"


def candidate_keys(card_name: object, oracle_row: Mapping[str, Any] | None) -> set[str]:
    keys = {
        finder.normalize_name(card_name),
        finder.split_face_normalized(card_name),
    }
    if oracle_row:
        keys.add(finder.normalize_name(oracle_row.get("name")))
        keys.add(finder.split_face_normalized(oracle_row.get("name")))
        keys.add(finder.normalize_name(oracle_row.get("normalized_name")))
        keys.add(finder.split_face_normalized(oracle_row.get("normalized_name")))
    return {key for key in keys if key}


def classify_candidate(
    candidate: Mapping[str, Any],
    *,
    indexes: Mapping[str, Any],
    reviewed_names: set[str],
    finder_names: set[str],
) -> dict[str, Any]:
    role = str(candidate.get("target_cut_role") or "")
    source_name = str(candidate.get("card_name") or "")
    normalized = finder.normalize_name(source_name)
    base = finder.split_face_normalized(source_name)
    oracle_row = indexes.get("oracle", {}).get(normalized) or indexes.get("oracle", {}).get(base)
    canonical_name = str((oracle_row or {}).get("name") or source_name)
    keys = candidate_keys(source_name, oracle_row)
    in_deck = bool(keys & indexes.get("deck_names", set())) or bool(keys & indexes.get("deck_base_names", set()))
    recycled = bool(keys & reviewed_names) or bool(keys & finder_names)
    legality = legality_status(indexes, keys)
    commander_legal = finder.color_identity_legal(oracle_row)
    matched_terms = role_terms(role, oracle_row)
    is_land = finder.type_line_contains(oracle_row, "Land")
    if legality == "banned":
        status = "expanded_source_candidate_blocks_commander_banned"
        next_gate = "discard_banned_candidate"
    elif in_deck:
        status = "expanded_source_candidate_already_in_current_deck_blocked"
        next_gate = "target_deck_trace_or_negative_review_before_cut_consideration"
    elif recycled:
        status = "expanded_source_candidate_recycled_from_prior_seed_blocked"
        next_gate = "broaden_external_source_candidate_pool_without_recycling"
    elif not oracle_row:
        status = "expanded_source_candidate_needs_local_identity_resolution"
        next_gate = "resolve_local_identity_before_review"
    elif not commander_legal:
        status = "expanded_source_candidate_blocks_color_identity"
        next_gate = "discard_color_identity_mismatch"
    elif is_land:
        status = "expanded_source_candidate_land_lane_requires_mana_base_model"
        next_gate = "route_land_candidate_to_mana_base_lane"
    elif not matched_terms:
        status = "expanded_source_candidate_needs_stronger_role_text_evidence"
        next_gate = "collect_stronger_role_evidence_before_miner_seed"
    else:
        status = "expanded_external_source_candidate_ready_for_local_review"
        next_gate = "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner"
    ready = status == "expanded_external_source_candidate_ready_for_local_review"
    return {
        "target_cut_role": role,
        "card_name": canonical_name,
        "source_card_name": source_name,
        "candidate_signal": candidate.get("candidate_signal"),
        "source_ids": candidate.get("source_ids") or [],
        "status": status,
        "next_gate": next_gate,
        "current_deck_present": in_deck,
        "recycled_from_prior_external_seed": recycled,
        "local_identity_found": bool(oracle_row),
        "commander_identity_legal": commander_legal,
        "commander_legality_status": legality,
        "type_line": (oracle_row or {}).get("type_line"),
        "cmc": (oracle_row or {}).get("cmc"),
        "local_role_evidence_terms": matched_terms,
        "seed_scope": seed_scope(role, canonical_name, oracle_row) if ready else "blocked_not_a_seed",
        "miner_source_seed_allowed": ready,
        "card_level_cut_permission_now": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
    }


def count_by(rows: Iterable[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def choose_status_and_next_gate(ready_rows: list[Mapping[str, Any]], router_status: str) -> tuple[str, str]:
    if router_status != "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion":
        return (
            "external_nonpayoff_source_candidate_pool_expansion_blocked_by_prior_router",
            "resolve_prior_seed_exhaustion_router_gate",
        )
    if ready_rows:
        return (
            "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review",
            "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
        )
    return (
        "external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates",
        "broaden_external_nonpayoff_source_research_live",
    )


def build_report(
    *,
    recovery_router_report: Path,
    previous_reviewer_report: Path,
    previous_finder_report: Path,
    selected_db: Path,
    candidate_rows: Iterable[Mapping[str, Any]] = EXPANDED_SOURCE_CANDIDATES,
    previous_reports: Iterable[Path] | None = None,
) -> dict[str, Any]:
    router_payload = load_json(recovery_router_report)
    router_summary = router_payload.get("summary") or {}
    deck_id = str(router_summary.get("deck_id") or "")
    resolved_db = resolve_selected_db(selected_db)
    indexes = finder.db_indexes(resolved_db, deck_id)
    previous_paths = tuple(previous_reports) if previous_reports is not None else (
        previous_reviewer_report,
        previous_finder_report,
    )
    recycled_names = previous_report_names(previous_paths)
    expansion_rows = [
        classify_candidate(
            candidate,
            indexes=indexes,
            reviewed_names=recycled_names,
            finder_names=set(),
        )
        for candidate in candidate_rows
    ]
    ready_rows = [row for row in expansion_rows if row["miner_source_seed_allowed"]]
    status, next_gate = choose_status_and_next_gate(ready_rows, str(router_payload.get("status") or ""))
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_source_candidate_pool_expander",
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
            "recovery_router_report": rel(recovery_router_report),
            "previous_reviewer_report": rel(previous_reviewer_report),
            "previous_finder_report": rel(previous_finder_report),
            "previous_reports": [rel(path) for path in previous_paths],
            "selected_db": rel(resolved_db),
        },
        "source_snapshots": EXPANSION_SOURCE_SNAPSHOTS,
        "summary": {
            "deck_id": deck_id,
            "commander": str(router_summary.get("commander") or ""),
            "prior_router_status": str(router_payload.get("status") or ""),
            "previous_report_count": len(previous_paths),
            "cumulative_previous_candidate_name_count": len(recycled_names),
            "expanded_candidate_count": len(expansion_rows),
            "expanded_ready_for_review_count": len(ready_rows),
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
            "expanded_external_candidates_are_review_seeds_not_cut_permission",
            "prior_reviewed_seeds_remain_recycled_and_blocked",
            "current_deck_cards_need_trace_or_negative_review_before_cut_consideration",
            "banned_cards_are_discarded_before_strategy_review",
            "candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source",
        ],
        "policy": {
            "expansion_boundary": "External pool expansion only creates reviewed-source candidates for a later local review gate.",
            "recycling_boundary": "Candidates already reviewed or found in the prior seed pool are blocked, not reused.",
            "legality_boundary": "Current Commander banned cards are discarded even if they appear in historical/high-power context.",
            "deck_boundary": "Cards already present in the current deck cannot be used as fresh source seeds.",
            "mutation_boundary": "This expander does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Source Candidate Pool Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- prior_router_status: `{summary['prior_router_status']}`",
        f"- expanded_candidate_count: `{summary['expanded_candidate_count']}`",
        f"- expanded_ready_for_review_count: `{summary['expanded_ready_for_review_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Ready Expanded Source Candidates",
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
    lines.extend(["", "## All Expanded Candidates", ""])
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
    parser.add_argument("--recovery-router-report", type=Path, default=DEFAULT_RECOVERY_ROUTER_REPORT)
    parser.add_argument("--previous-reviewer-report", type=Path, default=DEFAULT_PREVIOUS_REVIEWER_REPORT)
    parser.add_argument("--previous-finder-report", type=Path, default=DEFAULT_PREVIOUS_FINDER_REPORT)
    parser.add_argument("--previous-report", type=Path, action="append")
    parser.add_argument("--selected-db", type=Path, default=DEFAULT_SELECTED_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    previous_reports = tuple(args.previous_report) if args.previous_report else None
    payload = build_report(
        recovery_router_report=args.recovery_router_report,
        previous_reviewer_report=args.previous_reviewer_report,
        previous_finder_report=args.previous_finder_report,
        selected_db=args.selected_db,
        previous_reports=previous_reports,
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
