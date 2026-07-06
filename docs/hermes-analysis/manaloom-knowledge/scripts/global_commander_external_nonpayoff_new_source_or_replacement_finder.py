#!/usr/bin/env python3
"""Find fresh external nonpayoff sources after current-deck review blocks cuts.

This read-only gate follows
``global_commander_external_nonpayoff_current_deck_negative_review_collector``.
It separates three cases:

* current-deck external candidates that target traces already used;
* explicit same-lane replacement proof, if present;
* genuinely fresh outside-deck external source candidates that can seed a later
  miner/review pass.

No row in this report is card-level cut permission.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_NEGATIVE_REVIEW_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PREVIOUS_REVIEWER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_SELECTED_DB = (
    REPORT_DIR
    / "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1_candidate"
    / "knowledge_candidate.db"
)
FALLBACK_SELECTED_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1"
)

COMMANDER_IDENTITY = {"B", "R", "W"}

SOURCE_SNAPSHOTS: tuple[dict[str, Any], ...] = (
    {
        "source_id": "edhrec_kaalia_hidden_gems_2026_03_26",
        "url": "https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast",
        "observed_on": "2026-07-06",
        "source_type": "commander_strategy_article",
        "signal": "Kaalia needs immediate attack windows, mana to recast, and redundant support when opponents remove her.",
        "guardrail": "hidden-gem/article presence is source-lane evidence only, not cut permission",
    },
    {
        "source_id": "draftsim_kaalia_deck_guide_2026_02_12",
        "url": "https://draftsim.com/kaalia-of-the-vast-edh-deck/",
        "observed_on": "2026-07-06",
        "source_type": "commander_deck_guide_and_list",
        "signal": "The guide lists redundant protection, haste, mana rocks, reanimation, and Kaalia payoff support.",
        "guardrail": "a public list can suggest source candidates but cannot override target-deck usage",
    },
    {
        "source_id": "wizards_banned_restricted_commander_2026_07_06",
        "url": "https://magic.wizards.com/en/banned-restricted-list",
        "observed_on": "2026-07-06",
        "source_type": "official_format_legality",
        "signal": "Commander legality and banned-card status must be checked before treating a card as a live candidate.",
        "guardrail": "legality is required but still not strategy proof",
    },
    {
        "source_id": "draftsim_equipment_tutors_2025_11_06",
        "url": "https://draftsim.com/equipment-tutor-mtg/",
        "observed_on": "2026-07-06",
        "source_type": "general_equipment_tutor_article",
        "signal": "Equipment tutors are an access lane for finding equipment cards, including haste/protection equipment packages.",
        "guardrail": "equipment access is narrower than unrestricted tutor access and must map to a real package need",
    },
    {
        "source_id": "edhrec_game_changer_alternatives_2026_07_06",
        "url": "https://edhrec.com/articles/top-10-game-changer-alternatives",
        "observed_on": "2026-07-06",
        "source_type": "high_power_commander_staple_context",
        "signal": "High-power tutor alternatives such as Grim Tutor are bracket/context signals, not automatic upgrades.",
        "guardrail": "generic high-power tutor context cannot override commander fit or target trace evidence",
    },
)

NEW_EXTERNAL_SOURCE_CANDIDATES: tuple[dict[str, Any], ...] = (
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Lavaspur Boots",
        "candidate_signal": "low-cost haste/ward equipment from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Flawless Maneuver",
        "candidate_signal": "free protection spell from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Loran's Escape",
        "candidate_signal": "one-mana hexproof/indestructible protection from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Malakir Rebirth",
        "candidate_signal": "commander recast/resilience spell from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Rebuff the Wicked",
        "candidate_signal": "one-mana anti-removal protection from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Clever Concealment",
        "candidate_signal": "board-protection phase-out spell from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Galadriel's Dismissal",
        "candidate_signal": "phase-out protection spell from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Mass Hysteria",
        "candidate_signal": "global haste source from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Hall of the Bandit Lord",
        "candidate_signal": "haste land from Kaalia hidden-gems article",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "haste_protection_silence",
        "card_name": "Redirect Lightning",
        "candidate_signal": "redundant targeted-removal redirection from Kaalia hidden-gems article",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Boros Signet",
        "candidate_signal": "two-mana color-fixing rock from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Orzhov Signet",
        "candidate_signal": "two-mana color-fixing rock from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Rakdos Signet",
        "candidate_signal": "two-mana color-fixing rock from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Mind Stone",
        "candidate_signal": "two-mana rock from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Conviction",
        "candidate_signal": "two-mana color-fixing talisman from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Hierarchy",
        "candidate_signal": "two-mana color-fixing talisman from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "mana_acceleration",
        "card_name": "Talisman of Indulgence",
        "candidate_signal": "two-mana color-fixing talisman from a current Kaalia guide list",
        "source_ids": ["draftsim_kaalia_deck_guide_2026_02_12"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Grim Tutor",
        "candidate_signal": "generic tutor alternative surfaced in current high-power Commander staple context",
        "source_ids": ["edhrec_game_changer_alternatives_2026_07_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Open the Armory",
        "candidate_signal": "equipment/aura tutor that can access haste or protection equipment packages",
        "source_ids": ["draftsim_equipment_tutors_2025_11_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Steelshaper's Gift",
        "candidate_signal": "low-cost equipment tutor that can access haste or protection equipment packages",
        "source_ids": ["draftsim_equipment_tutors_2025_11_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Stoneforge Mystic",
        "candidate_signal": "creature-based equipment tutor that can access haste or protection equipment packages",
        "source_ids": ["draftsim_equipment_tutors_2025_11_06"],
    },
    {
        "target_cut_role": "tutors_access",
        "card_name": "Maelstrom of the Spirit Dragon",
        "candidate_signal": "Dragon tutor utility land from Kaalia hidden-gems article",
        "source_ids": ["edhrec_kaalia_hidden_gems_2026_03_26"],
    },
)

ROLE_EVIDENCE_TERMS: dict[str, tuple[str, ...]] = {
    "haste_protection_silence": (
        "haste",
        "ward",
        "hexproof",
        "indestructible",
        "phase out",
        "phases out",
        "counter target spell that targets",
        "change the target",
        "return it to the battlefield",
    ),
    "mana_acceleration": (
        "add {",
        "add one mana",
        "mana of any color",
        "mana rock",
        "treasure",
        "draw a card",
    ),
    "tutors_access": (
        "search your library",
        "reveal it",
        "put it into your hand",
    ),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return " ".join(str(value or "").strip().lower().split())


def split_face_normalized(value: object) -> str:
    return normalize_name(str(value or "").split("//", 1)[0])


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


def parse_json_list(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str) and value.strip():
        try:
            parsed = json.loads(value)
        except Exception:
            return [value]
        if isinstance(parsed, list):
            return [str(item) for item in parsed]
    return []


def db_indexes(selected_db: Path, deck_id: str) -> dict[str, Any]:
    indexes: dict[str, Any] = {
        "deck_names": set(),
        "deck_base_names": set(),
        "oracle": {},
        "legalities": {},
    }
    if not selected_db.exists():
        return indexes
    con = sqlite3.connect(selected_db)
    con.row_factory = sqlite3.Row
    try:
        for row in con.execute("select card_name from deck_cards where cast(deck_id as text) = ?", (str(deck_id),)):
            indexes["deck_names"].add(normalize_name(row["card_name"]))
            indexes["deck_base_names"].add(split_face_normalized(row["card_name"]))
        for row in con.execute(
            """
            select normalized_name, name, type_line, oracle_text, cmc,
                   color_identity_json, keywords_json, scryfall_id, card_id
            from card_oracle_cache
            """
        ):
            oracle_row = dict(row)
            key = normalize_name(row["normalized_name"])
            indexes["oracle"][key] = oracle_row
            indexes["oracle"].setdefault(split_face_normalized(row["name"]), oracle_row)
        for row in con.execute("select card_name, format, status from card_legalities where format = 'commander'"):
            indexes["legalities"][normalize_name(row["card_name"])] = str(row["status"] or "")
            indexes["legalities"][split_face_normalized(row["card_name"])] = str(row["status"] or "")
    finally:
        con.close()
    return indexes


def selected_add_names(package_payload: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    for row in package_payload.get("selected_add_package") or []:
        if isinstance(row, Mapping):
            names.add(normalize_name(row.get("card_name")))
            names.add(split_face_normalized(row.get("card_name")))
    return {name for name in names if name}


def previous_candidate_names(previous_payload: Mapping[str, Any]) -> set[str]:
    names: set[str] = set()
    for collection_name in ("review_rows", "miner_source_seed_rows"):
        for row in previous_payload.get(collection_name) or []:
            if isinstance(row, Mapping):
                names.add(normalize_name(row.get("card_name")))
                names.add(split_face_normalized(row.get("card_name")))
    return {name for name in names if name}


def negative_review_by_card(negative_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in negative_payload.get("review_rows") or []:
        if not isinstance(row, Mapping):
            continue
        name = row.get("card_name")
        if name:
            rows[normalize_name(name)] = dict(row)
            rows[split_face_normalized(name)] = dict(row)
    return rows


def color_identity_legal(oracle_row: Mapping[str, Any] | None) -> bool:
    if not oracle_row:
        return False
    identity = set(parse_json_list(oracle_row.get("color_identity_json")))
    return identity.issubset(COMMANDER_IDENTITY)


def role_terms(role: str, oracle_row: Mapping[str, Any] | None) -> list[str]:
    if not oracle_row:
        return []
    text = " ".join(
        [
            str(oracle_row.get("oracle_text") or ""),
            str(oracle_row.get("type_line") or ""),
            " ".join(parse_json_list(oracle_row.get("keywords_json"))),
        ]
    ).lower()
    return [term for term in ROLE_EVIDENCE_TERMS.get(role, ()) if term in text]


def type_line_contains(oracle_row: Mapping[str, Any] | None, needle: str) -> bool:
    return needle.lower() in str((oracle_row or {}).get("type_line") or "").lower()


def replacement_row_for_current_card(row: Mapping[str, Any]) -> dict[str, Any]:
    status = str(row.get("status") or "")
    if status == "external_current_deck_candidate_used_by_target_blocks_negative_review":
        replacement_status = "current_deck_candidate_used_by_target_blocks_replacement_proof"
    elif status == "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review":
        replacement_status = "current_deck_candidate_seen_without_usage_needs_manual_review"
    else:
        replacement_status = "current_deck_candidate_needs_more_trace_before_replacement_proof"
    return {
        "card_name": row.get("card_name"),
        "target_cut_role": row.get("target_cut_role"),
        "prior_status": row.get("status"),
        "usage_event_count": row.get("usage_event_count", 0),
        "decision_trace_count": row.get("decision_trace_count", 0),
        "replacement_status": replacement_status,
        "explicit_same_lane_replacement_proof_now": False,
        "candidate_copy_allowed": False,
        "value_safe_reclassification_allowed": False,
        "required_evidence": [
            "fresh_outside_deck_same_lane_source_candidate",
            "same_lane_value_safe_cut_pair_or_equal_gate",
            "target_trace_negative_review_if_card_remains_cut_candidate",
        ],
    }


def classify_source_candidate(
    candidate: Mapping[str, Any],
    *,
    indexes: Mapping[str, Any],
    selected_adds: set[str],
    previous_names: set[str],
    negative_rows: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    role = str(candidate.get("target_cut_role") or "")
    card_name = str(candidate.get("card_name") or "")
    normalized = normalize_name(card_name)
    base = split_face_normalized(card_name)
    oracle_row = indexes["oracle"].get(normalized) or indexes["oracle"].get(base)
    canonical_name = str((oracle_row or {}).get("name") or card_name)
    canonical_normalized = normalize_name(canonical_name)
    canonical_base = split_face_normalized(canonical_name)
    all_keys = {normalized, base, canonical_normalized, canonical_base}
    in_deck = bool(all_keys & indexes["deck_names"]) or bool(all_keys & indexes["deck_base_names"])
    held_add = bool(all_keys & selected_adds)
    recycled = bool(all_keys & previous_names)
    negative_row = next((negative_rows[key] for key in all_keys if key in negative_rows), None)
    legality = indexes["legalities"].get(canonical_normalized) or indexes["legalities"].get(canonical_base) or "unknown"
    commander_legal = color_identity_legal(oracle_row)
    terms = role_terms(role, oracle_row)
    is_land = type_line_contains(oracle_row, "Land")

    if negative_row:
        status = "new_source_candidate_is_current_deck_negative_review_blocked"
        next_gate = "find_fresh_outside_deck_source_or_equal_gate"
    elif in_deck:
        status = "new_source_candidate_already_in_current_deck_blocked"
        next_gate = "target_deck_trace_or_negative_review_before_cut_consideration"
    elif held_add:
        status = "new_source_candidate_already_held_package_add_blocked"
        next_gate = "same_lane_value_safe_pair_before_candidate_copy"
    elif recycled:
        status = "new_source_candidate_recycled_from_exhausted_seed_blocked"
        next_gate = "broaden_external_source_candidate_pool_without_recycling"
    elif legality == "banned":
        status = "new_source_candidate_blocks_commander_banned"
        next_gate = "discard_banned_candidate"
    elif not oracle_row:
        status = "new_source_candidate_needs_local_identity_resolution"
        next_gate = "resolve_local_identity_before_review"
    elif not commander_legal:
        status = "new_source_candidate_blocks_color_identity"
        next_gate = "discard_color_identity_mismatch"
    elif is_land:
        status = "new_source_candidate_land_lane_requires_mana_base_model"
        next_gate = "route_land_candidate_to_mana_base_lane"
    elif not terms:
        status = "new_source_candidate_needs_stronger_role_text_evidence"
        next_gate = "collect_stronger_role_evidence_before_miner_seed"
    else:
        status = "new_external_source_candidate_ready_for_local_miner_review"
        next_gate = "review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner"

    ready = status == "new_external_source_candidate_ready_for_local_miner_review"
    return {
        "target_cut_role": role,
        "card_name": canonical_name,
        "source_card_name": card_name,
        "candidate_signal": candidate.get("candidate_signal"),
        "source_ids": candidate.get("source_ids") or [],
        "status": status,
        "next_gate": next_gate,
        "current_deck_present": in_deck,
        "held_package_add": held_add,
        "recycled_from_prior_external_seed": recycled,
        "local_identity_found": bool(oracle_row),
        "commander_identity_legal": commander_legal,
        "commander_legality_status": legality,
        "type_line": (oracle_row or {}).get("type_line"),
        "cmc": (oracle_row or {}).get("cmc"),
        "local_role_evidence_terms": terms,
        "miner_source_seed_allowed": ready,
        "explicit_same_lane_replacement_proof_now": False,
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


def build_report(
    *,
    negative_review_report: Path,
    previous_reviewer_report: Path,
    package_source_report: Path,
    selected_db: Path,
    candidate_rows: Iterable[Mapping[str, Any]] = NEW_EXTERNAL_SOURCE_CANDIDATES,
) -> dict[str, Any]:
    negative_payload = load_json(negative_review_report)
    previous_payload = load_json(previous_reviewer_report)
    package_payload = load_json(package_source_report)
    negative_summary = negative_payload.get("summary") or {}
    deck_id = str(negative_summary.get("deck_id") or "")
    resolved_db = resolve_selected_db(selected_db)
    indexes = db_indexes(resolved_db, deck_id)
    selected_adds = selected_add_names(package_payload)
    previous_names = previous_candidate_names(previous_payload)
    negative_rows = negative_review_by_card(negative_payload)
    replacement_rows = [
        replacement_row_for_current_card(row)
        for row in negative_payload.get("review_rows") or []
        if isinstance(row, Mapping)
    ]
    source_rows = [
        classify_source_candidate(
            candidate,
            indexes=indexes,
            selected_adds=selected_adds,
            previous_names=previous_names,
            negative_rows=negative_rows,
        )
        for candidate in candidate_rows
    ]
    ready_rows = [row for row in source_rows if row["miner_source_seed_allowed"]]
    role_ready_counts = count_by(ready_rows, "target_cut_role")
    tutors_ready = role_ready_counts.get("tutors_access", 0)
    if ready_rows and tutors_ready:
        status = "new_external_source_candidates_ready_for_local_review"
        next_gate = "review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner"
    elif ready_rows:
        status = "new_external_source_candidates_partial_roles_ready_tutors_still_blocked"
        next_gate = "review_ready_new_sources_and_broaden_tutors_access_source_research"
    else:
        status = "new_external_source_or_replacement_proof_not_found"
        next_gate = "broaden_external_nonpayoff_source_research_live"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_new_source_or_replacement_finder",
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
        "explicit_same_lane_replacement_proof_now": False,
        "input_artifacts": {
            "negative_review_report": rel(negative_review_report),
            "previous_reviewer_report": rel(previous_reviewer_report),
            "package_source_report": rel(package_source_report),
            "selected_db": rel(resolved_db),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": str(negative_summary.get("commander") or ""),
            "current_deck_negative_review_candidate_count": len(replacement_rows),
            "current_deck_usage_blocked_count": sum(
                1
                for row in replacement_rows
                if row["replacement_status"] == "current_deck_candidate_used_by_target_blocks_replacement_proof"
            ),
            "manual_negative_review_required_count": sum(
                1
                for row in replacement_rows
                if row["replacement_status"] == "current_deck_candidate_seen_without_usage_needs_manual_review"
            ),
            "explicit_same_lane_replacement_proof_count": sum(
                1 for row in replacement_rows if row["explicit_same_lane_replacement_proof_now"]
            ),
            "new_external_candidate_count": len(source_rows),
            "new_external_ready_for_review_count": len(ready_rows),
            "ready_count_by_role": role_ready_counts,
            "status_counts": count_by(source_rows, "status"),
            "next_gate": next_gate,
        },
        "source_snapshots": SOURCE_SNAPSHOTS,
        "current_deck_replacement_review_rows": replacement_rows,
        "new_external_source_rows": source_rows,
        "ready_new_external_source_rows": ready_rows,
        "candidate_copy_blockers": [
            "current_deck_usage_blocks_replacement_proof",
            "fresh_external_source_candidates_are_miner_seeds_not_cut_permission",
            "held_package_adds_still_need_value_safe_pairs",
            "partial_role_coverage_cannot_open_candidate_copy_or_battle",
        ],
        "policy": {
            "replacement_boundary": "A current-deck card used by the target is not cuttable without explicit same-lane replacement proof or equal-gate evidence.",
            "source_boundary": "New external candidates can seed later mining/review only; they are not deck actions.",
            "land_boundary": "Land candidates route to mana-base modeling, not nonland same-lane replacement.",
            "legality_boundary": "Official/current Commander legality blocks banned or color-identity-invalid candidates before strategy review.",
            "mutation_boundary": "This finder does not copy decks, mutate DBs, run battles, or promote a package.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff New Source Or Replacement Finder",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- current_deck_negative_review_candidate_count: `{summary['current_deck_negative_review_candidate_count']}`",
        f"- current_deck_usage_blocked_count: `{summary['current_deck_usage_blocked_count']}`",
        f"- manual_negative_review_required_count: `{summary['manual_negative_review_required_count']}`",
        f"- explicit_same_lane_replacement_proof_count: `{summary['explicit_same_lane_replacement_proof_count']}`",
        f"- new_external_candidate_count: `{summary['new_external_candidate_count']}`",
        f"- new_external_ready_for_review_count: `{summary['new_external_ready_for_review_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Ready New External Sources",
        "",
        "| Card | Role | Status | Evidence Terms | Sources |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["ready_new_external_source_rows"]:
        terms = ", ".join(row.get("local_role_evidence_terms") or [])
        sources = ", ".join(row.get("source_ids") or [])
        lines.append(
            f"| `{row['card_name']}` | `{row['target_cut_role']}` | `{row['status']}` | {terms} | {sources} |"
        )
    lines.extend(
        [
            "",
            "## Replacement Review",
            "",
            "| Card | Role | Status | Usage | Decisions |",
            "| --- | --- | --- | ---: | ---: |",
        ]
    )
    for row in payload["current_deck_replacement_review_rows"]:
        lines.append(
            "| `{card}` | `{role}` | `{status}` | {usage} | {decisions} |".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                status=row.get("replacement_status"),
                usage=row.get("usage_event_count", 0),
                decisions=row.get("decision_trace_count", 0),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--negative-review-report", type=Path, default=DEFAULT_NEGATIVE_REVIEW_REPORT)
    parser.add_argument("--previous-reviewer-report", type=Path, default=DEFAULT_PREVIOUS_REVIEWER_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--selected-db", type=Path, default=DEFAULT_SELECTED_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        negative_review_report=args.negative_review_report,
        previous_reviewer_report=args.previous_reviewer_report,
        package_source_report=args.package_source_report,
        selected_db=args.selected_db,
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
