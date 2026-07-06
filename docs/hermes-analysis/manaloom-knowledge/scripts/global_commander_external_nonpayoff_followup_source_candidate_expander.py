#!/usr/bin/env python3
"""Expand follow-up external nonpayoff candidates with cumulative recycling.

This read-only gate follows a current-deck negative review that still blocks a
candidate after the first expanded source pass. It builds a fresh follow-up
source pool while treating every prior finder, reviewer, and expander report as
exhausted evidence. It emits the same candidate row shape as the expanded
source reviewer expects, but it does not create cut permission, copy a deck,
mutate any DB, run battles, reclassify value-safe cuts, or promote a package.
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
DEFAULT_NEGATIVE_REVIEW_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.json"
)
DEFAULT_PREVIOUS_REPORTS: tuple[Path, ...] = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.json",
    REPORT_DIR
    / "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.json",
)
DEFAULT_SELECTED_DB = expander.DEFAULT_SELECTED_DB
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault"
)


FOLLOWUP_SOURCE_SNAPSHOTS: tuple[dict[str, Any], ...] = (
    {
        "source_id": "edhrec_kaalia_default_followup_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast",
        "observed_on": "2026-07-06",
        "source_type": "commander_aggregate_card_page",
        "signal": "The current Kaalia aggregate surfaces additional nonpayoff support after the first pools, including Darksteel Plate, Brotherhood Regalia, Dragon Tempest, Reconnaissance, Commander's Sphere, Mardu Banner, and Diabolic Tutor.",
        "guardrail": "aggregate popularity is source-lane evidence only and cannot override local deck trace evidence",
    },
    {
        "source_id": "edhrec_kaalia_flying_followup_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/flying",
        "observed_on": "2026-07-06",
        "source_type": "commander_filtered_aggregate_card_page",
        "signal": "The flying-filtered Kaalia aggregate surfaces Deflecting Swat, Akroma's Will, Dawn's Truce, and Flare of Fortitude as protection or interaction support.",
        "guardrail": "filtered aggregate context is a seed source, not add approval",
    },
    {
        "source_id": "edhrec_kaalia_expensive_followup_2026_07_06",
        "url": "https://edhrec.com/commanders/kaalia-of-the-vast/expensive",
        "observed_on": "2026-07-06",
        "source_type": "commander_expensive_card_page",
        "signal": "The expensive Kaalia aggregate keeps high-power protection and tutor context visible, including Akroma's Will and Entomb.",
        "guardrail": "expensive/high-power context requires bracket and target-trace review before any deck action",
    },
    {
        "source_id": "wizards_current_banned_restricted_2026_06_29",
        "url": "https://magic.wizards.com/en/news/announcements/banned-and-restricted-june-29-2026",
        "observed_on": "2026-07-06",
        "source_type": "official_banned_restricted_update",
        "signal": "The June 29, 2026 banned and restricted update points players to the current format lists and keeps legality as a live precondition.",
        "guardrail": "legality is necessary but still not strategy proof or cut permission",
    },
)


FOLLOWUP_SOURCE_CANDIDATES: tuple[dict[str, Any], ...] = (
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Darksteel Plate",
        "candidate_signal": "equipment protection card from current Kaalia utility artifact aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Brotherhood Regalia",
        "candidate_signal": "ward/evasion equipment from current Kaalia utility artifact aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Dragon Tempest",
        "candidate_signal": "flying-creature haste enchantment from current Kaalia enchantment aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Reconnaissance",
        "candidate_signal": "attack-step protection/reset enchantment from current Kaalia enchantment aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Giver of Runes",
        "candidate_signal": "repeatable protection creature from current Kaalia creature aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Akroma's Will",
        "candidate_signal": "high-power board protection spell from current Kaalia and expensive/flying aggregates",
        "source_ids": [
            "edhrec_kaalia_default_followup_2026_07_06",
            "edhrec_kaalia_flying_followup_2026_07_06",
            "edhrec_kaalia_expensive_followup_2026_07_06",
        ],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Deflecting Swat",
        "candidate_signal": "free commander-protection redirection spell from current Kaalia/flying aggregates",
        "source_ids": [
            "edhrec_kaalia_default_followup_2026_07_06",
            "edhrec_kaalia_flying_followup_2026_07_06",
        ],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Dawn's Truce",
        "candidate_signal": "hexproof/protection instant from the flying-filtered Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_flying_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Flare of Fortitude",
        "candidate_signal": "free/alternate-cost protection instant from the flying-filtered Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_flying_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Sejiri Shelter",
        "candidate_signal": "modal protection spell from current Kaalia instant aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Blacksmith's Skill",
        "candidate_signal": "low-cost hexproof/indestructible protection spell for commander or equipment packages",
        "source_ids": ["edhrec_kaalia_flying_followup_2026_07_06"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Commander's Plate",
        "candidate_signal": "commander-focused protection equipment for combat-centric shells",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Commander's Sphere",
        "candidate_signal": "three-mana color-fixing rock from current Kaalia mana artifact aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Wayfarer's Bauble",
        "candidate_signal": "land-ramp artifact from current Kaalia utility artifact aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mardu Banner",
        "candidate_signal": "Mardu color-fixing rock from current Kaalia mana artifact aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Darksteel Ingot",
        "candidate_signal": "indestructible three-mana fixing rock as a lower-power resilience comparator",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Prismatic Lens",
        "candidate_signal": "two-mana color-filtering rock for curve-pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Marble Diamond",
        "candidate_signal": "two-mana white source rock for color-source pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Charcoal Diamond",
        "candidate_signal": "two-mana black source rock for color-source pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Fire Diamond",
        "candidate_signal": "two-mana red source rock for color-source pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Worn Powerstone",
        "candidate_signal": "three-mana colorless burst rock for curve-pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Everflowing Chalice",
        "candidate_signal": "scalable mana artifact for low/high curve pressure comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Entomb",
        "candidate_signal": "graveyard tutor/access card from expensive Kaalia aggregate",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Diabolic Tutor",
        "candidate_signal": "generic budget tutor from current Kaalia sorcery aggregate",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Final Parting",
        "candidate_signal": "split hand/graveyard tutor for reanimation-capable Kaalia shells",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Buried Alive",
        "candidate_signal": "creature graveyard tutor for reanimation-capable Kaalia shells",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Unmarked Grave",
        "candidate_signal": "nonlegendary graveyard tutor for reanimation-capable Kaalia shells",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Profane Tutor",
        "candidate_signal": "suspended generic tutor for bracket/context comparison",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Beseech the Queen",
        "candidate_signal": "conditional generic tutor for lands-count threshold comparison",
        "source_ids": ["edhrec_kaalia_expensive_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Idyllic Tutor",
        "candidate_signal": "enchantment tutor for haste/protection enchantment packages",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Fighter Class",
        "candidate_signal": "equipment tutor and equipment-cost support for combat-package comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Oswald Fiddlebender",
        "candidate_signal": "artifact-chain tutor for equipment/artifact package comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Magda, Brazen Outlaw",
        "candidate_signal": "Treasure engine and artifact/Dragon tutor for package comparison",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Weathered Wayfarer",
        "candidate_signal": "land tutor that must route differently if mana-base modeling is needed",
        "source_ids": ["edhrec_kaalia_default_followup_2026_07_06"],
    },
)


FOLLOWUP_EXTRA_ROLE_TERMS: dict[str, tuple[str, ...]] = {
    "haste_protection_silence": (
        "choose new targets",
        "remove target attacking creature",
        "protection from the color",
        "protection from each color",
        "life total can't change",
        "your life total can't change",
    ),
    "mana_acceleration": (
        "basic land card",
        "onto the battlefield tapped",
        "add {r}, {w}, or {b}",
        "add {c} for each charge",
    ),
    "tutors_access": (
        "put that card into your graveyard",
        "put one into your hand",
        "artifact card with mana value",
        "artifact or dragon card",
        "search your library for a land card",
        "search your library for an enchantment card",
        "search your library for an equipment card",
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


def count_by(rows: Iterable[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def collect_report_names(payload: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    keys = (
        "new_external_source_rows",
        "ready_new_external_source_rows",
        "review_rows",
        "miner_source_seed_rows",
        "expanded_source_candidate_rows",
        "ready_expanded_source_candidate_rows",
        "current_deck_replacement_review_rows",
    )
    for key in keys:
        for row in payload.get(key) or []:
            if not isinstance(row, Mapping):
                continue
            for name_key in ("card_name", "source_card_name"):
                name = row.get(name_key)
                names.add(expander.finder.normalize_name(name))
                names.add(expander.finder.split_face_normalized(name))
    return {name for name in names if name}


def cumulative_previous_names(paths: Iterable[Path]) -> set[str]:
    names: set[str] = set()
    for path in paths:
        if path.exists():
            names.update(collect_report_names(load_json(path)))
    return names


def role_terms(role: str, oracle_row: Mapping[str, Any] | None) -> list[str]:
    terms = list(expander.role_terms(role, oracle_row))
    if not oracle_row:
        return terms
    text = " ".join(
        [
            str(oracle_row.get("oracle_text") or ""),
            str(oracle_row.get("type_line") or ""),
            " ".join(expander.finder.parse_json_list(oracle_row.get("keywords_json"))),
        ]
    ).lower()
    for term in FOLLOWUP_EXTRA_ROLE_TERMS.get(role, ()):
        if term in text and term not in terms:
            terms.append(term)
    return terms


def seed_scope(role: str, card_name: str, oracle_row: Mapping[str, Any] | None) -> str:
    normalized = expander.finder.normalize_name(card_name)
    type_line = str((oracle_row or {}).get("type_line") or "").lower()
    oracle_text = str((oracle_row or {}).get("oracle_text") or "").lower()
    if role == "tutors_access":
        if "graveyard" in oracle_text:
            return "graveyard_tutor_seed_reanimation_context_required"
        if "enchantment card" in oracle_text:
            return "enchantment_tutor_seed_package_target_required"
        if "equipment card" in oracle_text:
            return "equipment_tutor_seed_package_target_required"
        if "artifact card" in oracle_text or "artifact or dragon card" in oracle_text:
            return "artifact_or_dragon_tutor_seed_package_target_required"
        if normalized in {"diabolic tutor", "profane tutor", "beseech the queen"}:
            return "generic_tutor_seed_bracket_context_required"
        return "conditional_tutor_seed_context_required"
    if role == "mana_acceleration":
        if "enters tapped" in oracle_text:
            return "tapped_mana_rock_seed_curve_pressure_review"
        if "basic land card" in oracle_text:
            return "land_ramp_artifact_seed_mana_base_context_required"
        if "mana of any color" in oracle_text:
            return "color_fixing_rock_seed_curve_pressure_review"
        return "mana_rock_seed_curve_pressure_review"
    if role == "haste_protection_silence":
        if "equipment" in type_line:
            return "equipment_haste_protection_seed"
        if "creature" in type_line:
            return "repeatable_creature_protection_seed"
        if "enchantment" in type_line:
            return "enchantment_resilience_or_haste_seed"
        if "without paying its mana cost" in oracle_text or "rather than pay" in oracle_text:
            return "free_protection_spell_seed_bracket_context_required"
        return "protection_spell_or_haste_seed"
    return "role_seed_context_required"


def classify_candidate(
    candidate: Mapping[str, Any],
    *,
    indexes: Mapping[str, Any],
    previous_names: set[str],
) -> dict[str, Any]:
    role = str(candidate.get("target_cut_role") or "")
    source_name = str(candidate.get("card_name") or "")
    normalized = expander.finder.normalize_name(source_name)
    base = expander.finder.split_face_normalized(source_name)
    oracle_row = indexes.get("oracle", {}).get(normalized) or indexes.get("oracle", {}).get(base)
    canonical_name = str((oracle_row or {}).get("name") or source_name)
    keys = expander.candidate_keys(source_name, oracle_row)
    in_deck = bool(keys & indexes.get("deck_names", set())) or bool(keys & indexes.get("deck_base_names", set()))
    recycled = bool(keys & previous_names)
    legality = expander.legality_status(indexes, keys)
    commander_legal = expander.finder.color_identity_legal(oracle_row)
    matched_terms = role_terms(role, oracle_row)
    is_land = expander.finder.type_line_contains(oracle_row, "Land")
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


def choose_status_and_next_gate(ready_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if ready_rows:
        return (
            "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
            "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
        )
    return (
        "external_nonpayoff_followup_source_candidate_pool_found_no_ready_candidates",
        "broaden_external_nonpayoff_source_research_live",
    )


def build_report(
    *,
    negative_review_report: Path,
    previous_reports: Iterable[Path],
    selected_db: Path,
    candidate_rows: Iterable[Mapping[str, Any]] = FOLLOWUP_SOURCE_CANDIDATES,
) -> dict[str, Any]:
    negative_payload = load_json(negative_review_report)
    negative_summary = negative_payload.get("summary") or {}
    deck_id = str(negative_summary.get("deck_id") or "")
    resolved_db = expander.resolve_selected_db(selected_db)
    indexes = expander.finder.db_indexes(resolved_db, deck_id)
    previous_paths = tuple(previous_reports)
    previous_names = cumulative_previous_names(previous_paths)
    expansion_rows = [
        classify_candidate(candidate, indexes=indexes, previous_names=previous_names)
        for candidate in candidate_rows
    ]
    ready_rows = [row for row in expansion_rows if row["miner_source_seed_allowed"]]
    status, next_gate = choose_status_and_next_gate(ready_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_followup_source_candidate_expander",
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
            "negative_review_report": rel(negative_review_report),
            "previous_reports": [rel(path) for path in previous_paths],
            "selected_db": rel(resolved_db),
        },
        "source_snapshots": FOLLOWUP_SOURCE_SNAPSHOTS,
        "summary": {
            "deck_id": deck_id,
            "commander": str(negative_summary.get("commander") or ""),
            "prior_negative_review_status": str(negative_payload.get("status") or ""),
            "previous_report_count": len(previous_paths),
            "cumulative_previous_candidate_name_count": len(previous_names),
            "followup_candidate_count": len(expansion_rows),
            "followup_ready_for_review_count": len(ready_rows),
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
            "followup_external_candidates_are_review_seeds_not_cut_permission",
            "all_prior_finder_reviewer_and_expander_candidates_are_recycled_and_blocked",
            "current_deck_cards_need_trace_or_negative_review_before_cut_consideration",
            "candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source",
        ],
        "policy": {
            "followup_boundary": "Follow-up source expansion is cumulative; a card seen in any previous source report is recycled and blocked.",
            "source_boundary": "Ready follow-up rows are local-review candidates only, not add approval.",
            "legality_boundary": "Current Commander legality and color identity are checked before strategy review.",
            "mutation_boundary": "This expander does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Followup Source Candidate Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- prior_negative_review_status: `{summary['prior_negative_review_status']}`",
        f"- previous_report_count: `{summary['previous_report_count']}`",
        f"- cumulative_previous_candidate_name_count: `{summary['cumulative_previous_candidate_name_count']}`",
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
    parser.add_argument("--negative-review-report", type=Path, default=DEFAULT_NEGATIVE_REVIEW_REPORT)
    parser.add_argument("--previous-report", type=Path, action="append")
    parser.add_argument("--selected-db", type=Path, default=DEFAULT_SELECTED_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    previous_reports = tuple(args.previous_report) if args.previous_report else DEFAULT_PREVIOUS_REPORTS
    payload = build_report(
        negative_review_report=args.negative_review_report,
        previous_reports=previous_reports,
        selected_db=args.selected_db,
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
