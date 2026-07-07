#!/usr/bin/env python3
"""Global all-card Oracle/battle readiness audit for ManaLoom.

This is a read-only routing audit. It starts from every PostgreSQL `cards` row
known by ManaLoom. Registered deck usage is retained as an internal QA seed,
not as a market-demand proxy. The audit identifies which Oracle/legalities gaps
should be fixed in bulk and which battle gaps should be batched by semantic
family. It does not promote `card_battle_rules`, mutate PostgreSQL, mutate
Hermes SQLite, or claim that broad XMage extraction is executable ManaLoom
truth.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import (
    REPO_ROOT,
    classify_deck,
    rel,
    validate_commander_shape,
    _fetch_pg_rows,
)

import xmage_local_rule_indexer as xmage_indexer


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
XMAGE_FLOW = REPO_ROOT / "docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md"
DEFAULT_XMAGE_ROOT = Path("/Users/desenvolvimentomobile/Downloads/mage-master")

PRODUCT_SCOPES = {"user_product", "registered_pg_variant"}
FIXTURE_SCOPES = {"test_or_fixture"}
TRUSTED_RULE_REVIEW_STATUS = {"verified", "active"}
TRUSTED_RULE_EXECUTION_STATUS = {"auto"}
LOW_PRIORITY_RULE_FAMILIES = {
    "generic_basic_land_or_simple_mana",
    "generic_vanilla_or_keyword_creature",
    "oracle_gap",
}
OFFICIAL_ORACLE_ID_UNAVAILABLE_NORMALIZED_NAMES = {
    "a-alrund's epiphany",
    "a-omnath, locus of creation",
    "a-unholy heat",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def compact_text(value: str, *, limit: int = 180) -> str:
    text = re.sub(r"\s+", " ", str(value or "").strip())
    return text if len(text) <= limit else text[: limit - 3] + "..."


def card_family(type_line: str, oracle_text: str) -> str:
    type_lower = str(type_line or "").lower()
    oracle_lower = str(oracle_text or "").lower()
    oracle_words = re.sub(r"[^a-z0-9{}+/-]+", " ", oracle_lower)

    if not oracle_lower.strip():
        if "land" in type_lower:
            return "generic_basic_land_or_simple_mana"
        if "creature" in type_lower:
            return "generic_vanilla_or_keyword_creature"
        return "oracle_gap"
    if "search your library" in oracle_lower:
        return "tutor_search_library"
    if "counter target" in oracle_lower:
        return "counterspell_or_stack_interaction"
    if "copy target" in oracle_lower or "copy that spell" in oracle_lower or "copy it" in oracle_lower:
        return "copy_spell_or_permanent"
    if "create" in oracle_words and "token" in oracle_words:
        return "token_creation"
    if "treasure token" in oracle_lower:
        return "mana_generation_or_ritual"
    if "add " in oracle_lower and ("mana" in oracle_lower or "{" in oracle_lower):
        return "mana_generation_or_ritual"
    if "draw" in oracle_lower or "scry" in oracle_lower or "surveil" in oracle_lower:
        return "draw_selection_topdeck"
    if "exile target" in oracle_lower or "destroy target" in oracle_lower:
        return "targeted_removal"
    if "damage" in oracle_lower or "deals" in oracle_lower:
        return "damage_or_life_total_change"
    if "return target" in oracle_lower and ("graveyard" in oracle_lower or "owner's hand" in oracle_lower):
        return "recursion_or_bounce"
    if "graveyard" in oracle_lower or "flashback" in oracle_lower or "escape" in oracle_lower:
        return "graveyard_recursion"
    if "prevent" in oracle_lower or "protection" in oracle_lower or "hexproof" in oracle_lower or "indestructible" in oracle_lower:
        return "protection_prevention"
    if "whenever" in oracle_lower or "at the beginning" in oracle_lower:
        return "triggered_or_static_ability"
    if "you may cast" in oracle_lower or "without paying" in oracle_lower or "rather than pay" in oracle_lower:
        return "alternate_or_free_cast"
    if "choose" in oracle_lower:
        return "modal_or_choice_effect"
    return "manual_model_review"


def card_rule_requirement(family: str, type_line: str, oracle_text: str) -> str:
    if family in LOW_PRIORITY_RULE_FAMILIES:
        return "generic_or_data_gate"
    if not str(oracle_text or "").strip():
        return "oracle_required_before_rule"
    if "instant" in str(type_line or "").lower() or "sorcery" in str(type_line or "").lower():
        return "card_specific_rule_required"
    return "card_specific_or_family_rule_required"


def unique_nonempty_face_values(card_faces: Any, key: str) -> list[str]:
    if not isinstance(card_faces, list):
        return []
    values: list[str] = []
    seen: set[str] = set()
    for face in card_faces:
        if not isinstance(face, dict):
            continue
        value = str(face.get(key) or "").strip()
        if not value or value in seen:
            continue
        values.append(value)
        seen.add(value)
    return values


def face_derived_field(card_faces: Any, key: str) -> str:
    values = unique_nonempty_face_values(card_faces, key)
    if not values:
        return ""
    if key == "oracle_id" and len(values) > 1:
        return ""
    return values[0] if len(values) == 1 else "\n//\n".join(values)


def official_oracle_id_unavailable(card: dict[str, Any]) -> bool:
    return (
        normalize_name(str(card.get("name") or "")) in OFFICIAL_ORACLE_ID_UNAVAILABLE_NORMALIZED_NAMES
        and not bool(card.get("oracle_id_present"))
        and bool(card.get("oracle_text_present"))
        and bool(card.get("type_line_present"))
        and int(card.get("legality_format_count") or 0) > 0
    )


def lane_for_card(card: dict[str, Any]) -> list[str]:
    lanes: list[str] = []
    oracle_identity_exception = official_oracle_id_unavailable(card)
    oracle_text_blocks_data = (
        not card["oracle_text_present"]
        and card["runtime_requirement"] != "generic_or_data_gate"
    )
    if (not card["oracle_id_present"] and not oracle_identity_exception) or not card["type_line_present"] or oracle_text_blocks_data:
        lanes.append("oracle_data_sync")
    if oracle_identity_exception:
        lanes.append("official_oracle_identity_unavailable")
    if int(card["legality_format_count"] or 0) == 0:
        if int(card["oracle_identity_legality_format_count"] or 0) > 0:
            lanes.append("oracle_identity_legalities_copy_candidate")
        else:
            lanes.append("legalities_sync")
    elif card["commander_legality_status"] == "":
        lanes.append("commander_legality_sync")
    elif card["commander_legality_status"] not in {"legal", "restricted"}:
        lanes.append("commander_illegal_block")
    if card["trusted_rule_count"] == 0:
        if card["runtime_requirement"] == "generic_or_data_gate":
            lanes.append("generic_runtime_or_no_card_rule")
        elif oracle_identity_exception and card["commander_legality_status"] not in {"legal", "restricted"}:
            lanes.append("digital_non_commander_rule_exception")
        elif int(card["oracle_identity_trusted_rule_count"] or 0) > 0:
            lanes.append("oracle_identity_rule_link_or_copy")
        elif "oracle_data_sync" not in lanes:
            lanes.append("battle_family_mapper_required")
    if card["trusted_rule_count"] > 0 and card["trusted_missing_hash_count"] > 0:
        lanes.append("trusted_rule_oracle_hash_backfill")
    if not lanes:
        lanes.append("battle_and_oracle_ready")
    return lanes


def fetch_deck_scope() -> dict[str, dict[str, Any]]:
    scope: dict[str, dict[str, Any]] = {}
    for row in _fetch_pg_rows():
        deck_scope = classify_deck(row)
        deck_status, issues = validate_commander_shape(row)
        scope[row.deck_id] = {
            "scope": deck_scope,
            "status": deck_status,
            "issues": issues,
            "name": row.name,
            "commander_names": list(row.commander_names),
        }
    return scope


def ready_product_deck_ids(deck_scope: dict[str, dict[str, Any]]) -> list[str]:
    return [
        deck_id
        for deck_id, row in deck_scope.items()
        if row.get("scope") in PRODUCT_SCOPES and row.get("status") == "structure_ready"
    ]


def fixture_deck_ids(deck_scope: dict[str, dict[str, Any]]) -> list[str]:
    return [
        deck_id
        for deck_id, row in deck_scope.items()
        if row.get("scope") in FIXTURE_SCOPES
    ]


def fetch_all_card_inventory() -> dict[str, Any]:
    from db_helper import connect

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  count(*)::int AS total_cards,
                  count(*) FILTER (WHERE c.oracle_id IS NULL OR btrim(c.oracle_id::text) = '')::int AS missing_oracle_id,
                  count(*) FILTER (WHERE c.oracle_text IS NULL OR btrim(c.oracle_text) = '')::int AS missing_oracle_text,
                  count(*) FILTER (WHERE c.type_line IS NULL OR btrim(c.type_line) = '')::int AS missing_type_line,
                  count(*) FILTER (WHERE c.name IS NULL OR btrim(c.name) = '')::int AS missing_name,
                  count(*) FILTER (WHERE any_legality.card_id IS NULL)::int AS missing_all_legalities,
                  count(*) FILTER (WHERE commander_cl.card_id IS NULL)::int AS missing_commander_legality,
                  count(*) FILTER (
                    WHERE commander_cl.status IS NOT NULL
                      AND commander_cl.status NOT IN ('legal', 'restricted')
                  )::int AS not_commander_legal
                FROM cards c
                LEFT JOIN (SELECT DISTINCT card_id FROM card_legalities) any_legality
                  ON any_legality.card_id = c.id
                LEFT JOIN card_legalities commander_cl
                  ON commander_cl.card_id = c.id AND lower(commander_cl.format) = 'commander'
                """
            )
            columns = [desc[0] for desc in cur.description]
            cards = dict(zip(columns, cur.fetchone()))
            cur.execute(
                """
                SELECT
                  count(*)::int AS total_snapshot_cards,
                  count(*) FILTER (WHERE legalities IS NULL OR NOT (legalities ? 'commander'))::int AS snapshot_missing_commander_legality,
                  count(*) FILTER (WHERE battle_rule_count > 0)::int AS snapshot_has_any_rule,
                  count(*) FILTER (WHERE verified_battle_rule_count > 0)::int AS snapshot_has_verified_rule
                FROM card_intelligence_snapshot
                """
            )
            columns = [desc[0] for desc in cur.description]
            snapshot = dict(zip(columns, cur.fetchone()))
    return {"cards": cards, "card_intelligence_snapshot": snapshot}


def fetch_all_card_rows(deck_scope: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    from db_helper import connect

    ready_ids = ready_product_deck_ids(deck_scope)
    fixture_ids = fixture_deck_ids(deck_scope)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                WITH rule_counts AS (
                  SELECT
                    card_id,
                    count(*) FILTER (WHERE execution_status <> 'disabled')::int AS active_rule_count,
                    count(*) FILTER (
                      WHERE execution_status = ANY(%s)
                        AND review_status = ANY(%s)
                    )::int AS trusted_rule_count,
                    count(*) FILTER (
                      WHERE execution_status = 'review_only'
                         OR review_status = 'needs_review'
                    )::int AS review_or_shadow_rule_count,
                    count(*) FILTER (
                      WHERE execution_status = ANY(%s)
                        AND review_status = ANY(%s)
                        AND (oracle_hash IS NULL OR btrim(oracle_hash) = '')
                    )::int AS trusted_missing_hash_count
                  FROM card_battle_rules
                  GROUP BY card_id
                ), name_rule_counts AS (
                  SELECT
                    lower(normalized_name) AS normalized_name,
                    count(*) FILTER (WHERE execution_status <> 'disabled')::int AS active_rule_count,
                    count(*) FILTER (
                      WHERE execution_status = ANY(%s)
                        AND review_status = ANY(%s)
                    )::int AS trusted_rule_count
                  FROM card_battle_rules
                  WHERE normalized_name IS NOT NULL AND btrim(normalized_name) <> ''
                  GROUP BY lower(normalized_name)
                ), oracle_rule_counts AS (
                  SELECT
                    c.oracle_id::text AS oracle_id,
                    COALESCE(sum(rc.trusted_rule_count), 0)::int AS oracle_identity_trusted_rule_count,
                    COALESCE(sum(rc.active_rule_count), 0)::int AS oracle_identity_active_rule_count
                  FROM cards c
                  JOIN rule_counts rc ON rc.card_id = c.id
                  WHERE c.oracle_id IS NOT NULL
                  GROUP BY c.oracle_id
                ), deck_usage AS (
                  SELECT
                    dc.card_id,
                    count(DISTINCT d.id)::int AS deck_count,
                    COALESCE(sum(dc.quantity), 0)::int AS total_quantity,
                    count(*) FILTER (WHERE dc.is_commander)::int AS commander_slot_count,
                    count(DISTINCT d.id) FILTER (WHERE d.id::text = ANY(%s))::int AS ready_product_deck_count,
                    count(DISTINCT d.id) FILTER (WHERE d.id::text = ANY(%s))::int AS fixture_deck_count
                  FROM deck_cards dc
                  JOIN decks d ON d.id = dc.deck_id
                  WHERE d.deleted_at IS NULL
                    AND dc.card_id IS NOT NULL
                  GROUP BY dc.card_id
                ), legality_counts AS (
                  SELECT
                    card_id,
                    count(*)::int AS legality_format_count
                  FROM card_legalities
                  GROUP BY card_id
                ), oracle_legality_counts AS (
                  SELECT
                    c.oracle_id::text AS oracle_id,
                    count(cl.*)::int AS oracle_identity_legality_format_count
                  FROM cards c
                  JOIN card_legalities cl ON cl.card_id = c.id
                  WHERE c.oracle_id IS NOT NULL
                  GROUP BY c.oracle_id
                )
                SELECT
                  c.id::text AS card_id,
                  c.name,
                  COALESCE(c.oracle_id::text, '') AS oracle_id,
                  COALESCE(c.oracle_text, '') AS oracle_text,
                  COALESCE(c.type_line, '') AS type_line,
                  COALESCE(c.mana_cost, '') AS mana_cost,
                  c.card_faces_json,
                  COALESCE(c.set_code, '') AS set_code,
                  COALESCE(cl.status, '') AS commander_legality_status,
                  COALESCE(lc.legality_format_count, 0)::int AS legality_format_count,
                  COALESCE(olc.oracle_identity_legality_format_count, 0)::int AS oracle_identity_legality_format_count,
                  COALESCE(rc.active_rule_count, 0)::int AS card_id_active_rule_count,
                  COALESCE(rc.trusted_rule_count, 0)::int AS card_id_trusted_rule_count,
                  COALESCE(nrc.active_rule_count, 0)::int AS normalized_name_active_rule_count,
                  COALESCE(nrc.trusted_rule_count, 0)::int AS normalized_name_trusted_rule_count,
                  GREATEST(COALESCE(rc.active_rule_count, 0), COALESCE(nrc.active_rule_count, 0))::int AS active_rule_count,
                  GREATEST(COALESCE(rc.trusted_rule_count, 0), COALESCE(nrc.trusted_rule_count, 0))::int AS trusted_rule_count,
                  COALESCE(orc.oracle_identity_active_rule_count, 0)::int AS oracle_identity_active_rule_count,
                  COALESCE(orc.oracle_identity_trusted_rule_count, 0)::int AS oracle_identity_trusted_rule_count,
                  COALESCE(rc.review_or_shadow_rule_count, 0)::int AS review_or_shadow_rule_count,
                  COALESCE(rc.trusted_missing_hash_count, 0)::int AS trusted_missing_hash_count,
                  COALESCE(du.deck_count, 0)::int AS deck_count,
                  COALESCE(du.total_quantity, 0)::int AS total_quantity,
                  COALESCE(du.commander_slot_count, 0)::int AS commander_slot_count,
                  COALESCE(du.ready_product_deck_count, 0)::int AS ready_product_deck_count,
                  COALESCE(du.fixture_deck_count, 0)::int AS fixture_deck_count
                FROM cards c
                LEFT JOIN card_legalities cl ON cl.card_id = c.id AND lower(cl.format) = 'commander'
                LEFT JOIN legality_counts lc ON lc.card_id = c.id
                LEFT JOIN oracle_legality_counts olc ON olc.oracle_id = c.oracle_id::text
                LEFT JOIN rule_counts rc ON rc.card_id = c.id
                LEFT JOIN name_rule_counts nrc ON nrc.normalized_name = lower(c.name)
                LEFT JOIN oracle_rule_counts orc ON orc.oracle_id = c.oracle_id::text
                LEFT JOIN deck_usage du ON du.card_id = c.id
                ORDER BY lower(c.name), c.id
                """,
                (
                    list(TRUSTED_RULE_EXECUTION_STATUS),
                    list(TRUSTED_RULE_REVIEW_STATUS),
                    list(TRUSTED_RULE_EXECUTION_STATUS),
                    list(TRUSTED_RULE_REVIEW_STATUS),
                    list(TRUSTED_RULE_EXECUTION_STATUS),
                    list(TRUSTED_RULE_REVIEW_STATUS),
                    ready_ids,
                    fixture_ids,
                ),
            )
            columns = [desc[0] for desc in cur.description]
            return [dict(zip(columns, raw)) for raw in cur.fetchall()]


def build_card_inventory(rows: list[dict[str, Any]], *, xmage_root: Path, xmage_limit: int) -> list[dict[str, Any]]:
    cards: list[dict[str, Any]] = []
    for row in rows:
        card_faces = row.get("card_faces_json")
        oracle_id = str(row["oracle_id"] or "") or face_derived_field(card_faces, "oracle_id")
        oracle_text = str(row["oracle_text"] or "") or face_derived_field(card_faces, "oracle_text")
        type_line = str(row["type_line"] or "") or face_derived_field(card_faces, "type_line")
        mana_cost = str(row["mana_cost"] or "") or face_derived_field(card_faces, "mana_cost")
        oracle_text_excerpt = compact_text(oracle_text)
        family = card_family(type_line, oracle_text)
        runtime_requirement = card_rule_requirement(family, type_line, oracle_text)
        card = {
            "card_id": str(row["card_id"]),
            "name": row["name"],
            "normalized_name": normalize_name(row["name"]),
            "oracle_id": oracle_id,
            "oracle_id_present": bool(oracle_id),
            "oracle_text_present": bool(oracle_text.strip()),
            "oracle_text_analysis": oracle_text,
            "type_line_present": bool(type_line.strip()),
            "type_line": type_line,
            "oracle_text_excerpt": oracle_text_excerpt,
            "mana_cost": mana_cost,
            "set_codes": [row["set_code"]] if row["set_code"] else [],
            "commander_legality_status": row["commander_legality_status"],
            "legality_format_count": int(row["legality_format_count"] or 0),
            "oracle_identity_legality_format_count": int(row["oracle_identity_legality_format_count"] or 0),
            "active_rule_count": int(row["active_rule_count"]),
            "trusted_rule_count": int(row["trusted_rule_count"]),
            "card_id_trusted_rule_count": int(row["card_id_trusted_rule_count"] or 0),
            "normalized_name_trusted_rule_count": int(row["normalized_name_trusted_rule_count"] or 0),
            "oracle_identity_active_rule_count": int(row["oracle_identity_active_rule_count"] or 0),
            "oracle_identity_trusted_rule_count": int(row["oracle_identity_trusted_rule_count"] or 0),
            "review_or_shadow_rule_count": int(row["review_or_shadow_rule_count"]),
            "trusted_missing_hash_count": int(row["trusted_missing_hash_count"]),
            "deck_count": int(row["deck_count"] or 0),
            "total_quantity": int(row["total_quantity"] or 0),
            "ready_product_deck_count": int(row["ready_product_deck_count"] or 0),
            "fixture_deck_count": int(row["fixture_deck_count"] or 0),
            "commander_slot_count": int(row["commander_slot_count"] or 0),
            "family": family,
            "runtime_requirement": runtime_requirement,
            "empty_oracle_text_generic_candidate": (
                not bool(oracle_text.strip())
                and runtime_requirement == "generic_or_data_gate"
            ),
        }
        card["lanes"] = lane_for_card(card)
        card["priority_score"] = priority_score(card)
        cards.append(card)

    cards.sort(key=lambda card: (-card["priority_score"], card["name"].lower(), card["card_id"]))
    attach_xmage_availability(cards, xmage_root=xmage_root, limit=xmage_limit)
    return cards


def priority_score(card: dict[str, Any]) -> int:
    score = 0
    if "oracle_data_sync" in card["lanes"]:
        score += 1200
    if "legalities_sync" in card["lanes"]:
        score += 800
    if "oracle_identity_legalities_copy_candidate" in card["lanes"]:
        score += 700
    if "commander_legality_sync" in card["lanes"]:
        score += 300
    if "oracle_identity_rule_link_or_copy" in card["lanes"]:
        score += 450
    if "battle_family_mapper_required" in card["lanes"]:
        score += 200
    if str(card.get("commander_legality_status") or "") in {"legal", "restricted"}:
        score += 50
    return score


def attach_xmage_availability(cards: list[dict[str, Any]], *, xmage_root: Path, limit: int) -> None:
    targets = [card for card in cards if "battle_family_mapper_required" in card["lanes"]]
    if limit > 0:
        targets = targets[:limit]
    if not targets:
        return
    class_index = xmage_indexer.build_card_class_index(xmage_root) if xmage_root.exists() else {}
    for card in targets:
        resolved = (
            xmage_indexer.resolve_card_source(xmage_root, str(card["name"]), class_index=class_index)
            if class_index
            else None
        )
        card["xmage_source"] = {
            "checked": True,
            "available": resolved is not None,
            "class_name": resolved.class_name if resolved else None,
            "path": str(resolved.path) if resolved else None,
            "resolution": resolved.resolution if resolved else None,
        }
    for card in cards:
        card.setdefault("xmage_source", {"checked": False, "available": None})


def summarize(card_inventory: list[dict[str, Any]], all_card_inventory: dict[str, Any]) -> dict[str, Any]:
    lane_counts = Counter(lane for card in card_inventory for lane in card["lanes"])
    family_counts = Counter(card["family"] for card in card_inventory if "battle_family_mapper_required" in card["lanes"])
    xmage_counts = Counter(
        "available" if card["xmage_source"].get("available") else "missing"
        for card in card_inventory
        if card["xmage_source"].get("checked")
    )
    product_cards = [card for card in card_inventory if int(card["ready_product_deck_count"]) > 0]
    product_lane_counts = Counter(lane for card in product_cards for lane in card["lanes"])
    registered_qa_cards = [card for card in card_inventory if int(card["deck_count"]) > 0]
    return {
        "all_card_inventory": all_card_inventory,
        "routing_adjustments": {
            "empty_oracle_text_generic_candidates": sum(
                1 for card in card_inventory if card.get("empty_oracle_text_generic_candidate")
            ),
            "oracle_text_empty_but_not_oracle_data_sync": sum(
                1
                for card in card_inventory
                if card.get("empty_oracle_text_generic_candidate")
                and "oracle_data_sync" not in card["lanes"]
            ),
        },
        "all_known_cards": len(card_inventory),
        "ready_product_qa_unique_cards": len(product_cards),
        "current_registered_deck_qa_unique_cards": len(registered_qa_cards),
        "lane_counts": dict(sorted(lane_counts.items())),
        "ready_product_qa_lane_counts": dict(sorted(product_lane_counts.items())),
        "battle_gap_family_counts": dict(family_counts.most_common()),
        "xmage_source_checked_counts": dict(sorted(xmage_counts.items())),
        "top_actionable_cards": [
            compact_card(card)
            for card in card_inventory
            if card["lanes"] != ["battle_and_oracle_ready"]
        ][:100],
        "recommended_batches": recommended_batches(card_inventory),
    }


def compact_card(card: dict[str, Any]) -> dict[str, Any]:
    return {
        "name": card["name"],
        "priority_score": card["priority_score"],
        "lanes": card["lanes"],
        "family": card["family"],
        "runtime_requirement": card["runtime_requirement"],
        "ready_product_deck_count": card["ready_product_deck_count"],
        "deck_count": card["deck_count"],
        "total_quantity": card["total_quantity"],
        "commander_legality_status": card["commander_legality_status"],
        "legality_format_count": card["legality_format_count"],
        "oracle_identity_legality_format_count": card["oracle_identity_legality_format_count"],
        "set_codes": card["set_codes"],
        "trusted_rule_count": card["trusted_rule_count"],
        "card_id_trusted_rule_count": card["card_id_trusted_rule_count"],
        "normalized_name_trusted_rule_count": card["normalized_name_trusted_rule_count"],
        "oracle_identity_trusted_rule_count": card["oracle_identity_trusted_rule_count"],
        "xmage_source": card["xmage_source"],
    }


def recommended_batches(card_inventory: list[dict[str, Any]]) -> list[dict[str, Any]]:
    batches: list[dict[str, Any]] = []
    oracle_cards = [card for card in card_inventory if "oracle_data_sync" in card["lanes"]]
    legality_cards = [card for card in card_inventory if "legalities_sync" in card["lanes"]]
    oracle_legality_copy_cards = [
        card for card in card_inventory if "oracle_identity_legalities_copy_candidate" in card["lanes"]
    ]
    commander_legality_cards = [card for card in card_inventory if "commander_legality_sync" in card["lanes"]]
    oracle_rule_copy_cards = [
        card for card in card_inventory if "oracle_identity_rule_link_or_copy" in card["lanes"]
    ]
    if oracle_cards:
        batches.append(
            {
                "batch": "oracle_bulk_backfill",
                "method": "Scryfall bulk/default-cards or targeted exact lookup; update cards only after exact identity match",
                "card_count": len(oracle_cards),
                "top_cards": [card["name"] for card in oracle_cards[:20]],
            }
        )
    if legality_cards:
        set_codes = sorted({code for card in legality_cards for code in card["set_codes"] if code})
        batches.append(
            {
                "batch": "all_format_legalities_sync",
                "method": "Scryfall collection/bulk by oracle_id or set_code; upsert card_legalities only",
                "card_count": len(legality_cards),
                "set_codes": set_codes,
                "top_cards": [card["name"] for card in legality_cards[:20]],
            }
        )
    if oracle_legality_copy_cards:
        batches.append(
            {
                "batch": "oracle_identity_legalities_copy_candidate",
                "method": "candidate local propagation from another printing with same oracle_id; requires precheck against digital/acorn exceptions before apply",
                "card_count": len(oracle_legality_copy_cards),
                "top_cards": [card["name"] for card in oracle_legality_copy_cards[:20]],
            }
        )
    if commander_legality_cards:
        set_codes = sorted({code for card in commander_legality_cards for code in card["set_codes"] if code})
        batches.append(
            {
                "batch": "commander_legality_gap_sync",
                "method": "Scryfall legalities by oracle_id/set_code; fill missing commander status without changing decklists",
                "card_count": len(commander_legality_cards),
                "set_codes": set_codes,
                "top_cards": [card["name"] for card in commander_legality_cards[:20]],
            }
        )
    if oracle_rule_copy_cards:
        batches.append(
            {
                "batch": "oracle_identity_rule_link_or_copy",
                "method": "candidate copy/link from trusted rule on same oracle_id; requires oracle_hash check and focused runtime smoke before PG package",
                "card_count": len(oracle_rule_copy_cards),
                "top_cards": [card["name"] for card in oracle_rule_copy_cards[:20]],
            }
        )

    by_family: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for card in card_inventory:
        if "battle_family_mapper_required" in card["lanes"]:
            by_family[card["family"]].append(card)
    for family, cards in sorted(by_family.items(), key=lambda item: (-len(item[1]), item[0])):
        batches.append(
            {
                "batch": f"battle_family::{family}",
                "method": "XMage source review -> exact ManaLoom scope -> focused tests -> PG package -> Hermes sync",
                "card_count": len(cards),
                "xmage_available_checked": sum(1 for card in cards if card["xmage_source"].get("available") is True),
                "top_cards": [card["name"] for card in cards[:20]],
            }
        )
    return batches[:40]


def build_payload(*, xmage_root: Path, xmage_limit: int) -> dict[str, Any]:
    deck_scope = fetch_deck_scope()
    all_card_inventory = fetch_all_card_inventory()
    card_rows = fetch_all_card_rows(deck_scope)
    card_inventory = build_card_inventory(card_rows, xmage_root=xmage_root, xmage_limit=xmage_limit)
    summary = summarize(card_inventory, all_card_inventory)
    return {
        "generated_at": utc_now(),
        "status": "action_required" if summary["recommended_batches"] else "pass",
        "contract": rel(XMAGE_FLOW),
        "method": {
            "read_only": True,
            "postgres_cards_table_is_base_scope": True,
            "postgres_is_product_truth": True,
            "registered_deck_usage_is_qa_only": True,
            "oracle_sources": [
                "Scryfall bulk data for Oracle/card data freshness",
                "MTGJSON as secondary bulk/reference lane",
            ],
            "battle_sources": [
                "local XMage as primary rules-engine reference",
                "Forge only for ambiguous high-risk cross-checks",
            ],
            "promotion_boundary": "broad extraction routes family lanes only; executable truth still needs focused tests and PG package",
            "xmage_root": str(xmage_root),
            "xmage_source_check_limit": xmage_limit,
        },
        "summary": summary,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    summary = payload["summary"]
    lines = [
        "# Global All-Card Oracle Battle Readiness",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        f"- All known cards: `{summary['all_known_cards']}`",
        f"- Current registered-deck QA unique cards: `{summary['current_registered_deck_qa_unique_cards']}`",
        f"- Ready-product QA unique cards: `{summary['ready_product_qa_unique_cards']}`",
        "",
        "## All Card Inventory",
        "",
        "| Source | Metric | Value |",
        "| --- | --- | ---: |",
    ]
    for source, metrics in summary["all_card_inventory"].items():
        for metric, value in metrics.items():
            lines.append(f"| `{source}` | `{metric}` | {value} |")

    lines.extend(["", "## Routing Adjustments", "", "| Metric | Value |", "| --- | ---: |"])
    for metric, value in summary["routing_adjustments"].items():
        lines.append(f"| `{metric}` | {value} |")

    lines.extend(["", "## Lane Counts", "", "| Lane | All Known Cards | Ready Product QA Cards |", "| --- | ---: | ---: |"])
    product_counts = summary["ready_product_qa_lane_counts"]
    for lane, count in summary["lane_counts"].items():
        lines.append(f"| `{lane}` | {count} | {product_counts.get(lane, 0)} |")

    lines.extend(["", "## Battle Gap Families", "", "| Family | Cards |", "| --- | ---: |"])
    for family, count in summary["battle_gap_family_counts"].items():
        lines.append(f"| `{family}` | {count} |")

    lines.extend(["", "## Recommended Batches", "", "| Batch | Cards | Method | Top Cards |", "| --- | ---: | --- | --- |"])
    for batch in summary["recommended_batches"]:
        top_cards = ", ".join(f"`{name}`" for name in batch.get("top_cards", [])[:10])
        lines.append(f"| `{batch['batch']}` | {batch['card_count']} | {batch['method']} | {top_cards} |")

    lines.extend(["", "## Top Actionable Cards", "", "| Card | Priority | Lanes | Family | Ready Product QA Decks | Registered QA Decks | XMage |", "| --- | ---: | --- | --- | ---: | ---: | --- |"])
    for card in summary["top_actionable_cards"][:60]:
        xmage = card["xmage_source"]
        xmage_status = "unchecked"
        if xmage.get("checked"):
            xmage_status = "available" if xmage.get("available") else "missing"
        lines.append(
            "| `{name}` | {priority} | `{lanes}` | `{family}` | {ready} | {decks} | `{xmage}` |".format(
                name=str(card["name"]).replace("|", "/"),
                priority=card["priority_score"],
                lanes=", ".join(card["lanes"]),
                family=card["family"],
                ready=card["ready_product_deck_count"],
                decks=card["deck_count"],
                xmage=xmage_status,
            )
        )

    lines.extend(
        [
            "",
            "## Method Notes",
            "",
            "- Scope is every PostgreSQL `cards` row, not only Lorehold or saved decks.",
            "- Current registered deck usage is an internal QA seed only; it is not a user-demand or launch-priority signal.",
            "- Oracle and legalities gaps should be handled in bulk before battle-family work.",
            "- Battle work should be pulled by `battle_family::*` batches, not card-by-card.",
            "- Broad XMage availability is routing evidence only; it is not executable PostgreSQL truth.",
            "- Cards classified as generic runtime/no card rule are not automatically blockers.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--xmage-limit", type=int, default=250)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_card_oracle_battle_readiness_20260701",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_payload(xmage_root=args.xmage_root, xmage_limit=args.xmage_limit)
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
