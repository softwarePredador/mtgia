#!/usr/bin/env python3
"""Build Lorehold challenger decks from the registered Lorehold corpus.

This is not a swap generator. It treats decks 607-616 as a card corpus, builds
complete 100-card shells by the frozen Commander deckbuilding contract, and
emits isolated candidate DBs that can be battle-gated against protected 607.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from lorehold_strategy_profile import (
    ACTIVE_ANCHOR_BONUS,
    INTENT_PACKAGE_RANGES,
    INTENT_ROLE_RANGES,
    STRATEGY_VERSION,
    commander_intent_alignment,
    strategy_tags_for_card,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SOURCE_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_CORPUS_DECK_IDS = tuple(range(607, 617))
DEFAULT_CANDIDATE_DECK_ID = 6
PROTECTED_BASELINE_DECK_ID = 607

LAND_PRIORITY = (
    "Command Tower",
    "Sacred Foundry",
    "Elegant Parlor",
    "Spectator Seating",
    "Arid Mesa",
    "Marsh Flats",
    "Flooded Strand",
    "Windswept Heath",
    "Wooded Foothills",
    "Bloodstained Mire",
    "Scalding Tarn",
    "Prismatic Vista",
    "Ancient Tomb",
    "Command Beacon",
    "Urza's Saga",
    "Plateau",
    "Clifftop Retreat",
    "Sunbillow Verge",
    "Radiant Summit",
    "Battlefield Forge",
    "Sunbaked Canyon",
    "Reliquary Tower",
    "Boseiju, Who Shelters All",
    "Cavern of Souls",
)

CHALLENGER_PLANS: dict[str, dict[str, Any]] = {
    "miracle_topdeck_control": {
        "mode": "from_scratch",
        "candidate_key": "challenger_lorehold_miracle_topdeck_control_v1",
        "candidate_name": "Lorehold From-Scratch Miracle Topdeck Control v1",
        "candidate_archetype": "from-scratch-miracle-topdeck-control",
        "intent": (
            "Maximize Lorehold's first-draw/miracle timing with topdeck setup, "
            "discard-to-top replacement, opponent-turn mana, and enough pressure "
            "absorption to survive until the discounted high-impact spell turn."
        ),
        "required_cards": [
            "Sensei's Divining Top",
            "Scroll Rack",
            "Library of Leng",
            "Land Tax",
            "Bender's Waterskin",
            "Victory Chimes",
            "Molecule Man",
            "The Scarlet Witch",
            "Mizzix's Mastery",
            "Approach of the Second Sun",
        ],
        "package_weights": {
            "topdeck_miracle_setup": 10.0,
            "hand_filter": 7.0,
            "protection_window": 7.0,
            "pressure_absorber": 8.0,
            "spell_chain_conversion": 7.0,
            "deterministic_finisher": 6.0,
            "early_plan": 5.0,
            "graveyard_recursion": 4.0,
        },
        "role_targets": {
            "land": 34,
            "ramp": 16,
            "draw": 15,
            "removal": 9,
            "protection": 12,
            "board_wipe": 4,
            "tutor": 4,
            "wincon": 8,
            "recursion": 5,
        },
        "land_target": 34,
        "min_basics": 6,
        "mountain_bias": 0.55,
    },
    "spellchain_big_sorcery": {
        "mode": "from_scratch",
        "candidate_key": "challenger_lorehold_spellchain_big_sorcery_v1",
        "candidate_name": "Lorehold From-Scratch Spellchain Big Sorcery v1",
        "candidate_archetype": "from-scratch-spellchain-big-sorcery",
        "intent": (
            "Treat Lorehold as a burst spell-chain commander: early rocks and "
            "rituals build ahead of curve, copy engines multiply the decisive "
            "instant/sorcery, and compact finishers convert one big turn into a win."
        ),
        "required_cards": [
            "Sol Ring",
            "Arcane Signet",
            "Mana Vault",
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Storm-Kiln Artist",
            "Mizzix's Mastery",
            "Aetherflux Reservoir",
            "Reiterate",
            "Twinflame",
            "Heat Shimmer",
            "Dualcaster Mage",
            "Jeska's Will",
        ],
        "package_weights": {
            "spell_chain_conversion": 11.0,
            "early_plan": 8.0,
            "deterministic_finisher": 8.0,
            "graveyard_recursion": 7.0,
            "hand_filter": 6.0,
            "protection_window": 6.0,
            "topdeck_miracle_setup": 5.0,
            "pressure_absorber": 4.0,
        },
        "role_targets": {
            "land": 33,
            "ramp": 18,
            "draw": 13,
            "removal": 8,
            "protection": 10,
            "board_wipe": 3,
            "tutor": 5,
            "wincon": 9,
            "recursion": 5,
        },
        "land_target": 33,
        "min_basics": 5,
        "mountain_bias": 0.7,
    },
    "recursion_discard_engine": {
        "mode": "from_scratch",
        "candidate_key": "challenger_lorehold_recursion_discard_engine_v1",
        "candidate_name": "Lorehold From-Scratch Recursion Discard Engine v1",
        "candidate_archetype": "from-scratch-recursion-discard-engine",
        "intent": (
            "Exploit Lorehold rummage as an engine instead of a cost: repeatable "
            "discard fodder, wheels, graveyard recasting, and topdeck replacement "
            "turn the commander's upkeep into card selection and spell recursion."
        ),
        "required_cards": [
            "Squee, Goblin Nabob",
            "Library of Leng",
            "Monument to Endurance",
            "Faithless Looting",
            "Wheel of Fortune",
            "Wheel of Misfortune",
            "Underworld Breach",
            "Past in Flames",
            "Mizzix's Mastery",
            "Reforge the Soul",
            "Sensei's Divining Top",
            "Scroll Rack",
        ],
        "package_weights": {
            "graveyard_recursion": 11.0,
            "hand_filter": 10.0,
            "spell_chain_conversion": 8.0,
            "topdeck_miracle_setup": 7.0,
            "deterministic_finisher": 7.0,
            "early_plan": 6.0,
            "protection_window": 5.0,
            "pressure_absorber": 4.0,
        },
        "role_targets": {
            "land": 34,
            "ramp": 15,
            "draw": 17,
            "removal": 8,
            "protection": 10,
            "board_wipe": 3,
            "tutor": 4,
            "wincon": 8,
            "recursion": 7,
        },
        "land_target": 34,
        "min_basics": 6,
        "mountain_bias": 0.65,
    },
    "recursion_discard_pressure_repair": {
        "mode": "from_scratch",
        "candidate_key": "challenger_lorehold_recursion_discard_pressure_repair_v1",
        "candidate_name": "Lorehold From-Scratch Recursion Discard Pressure Repair v1",
        "candidate_archetype": "from-scratch-recursion-discard-pressure-repair",
        "intent": (
            "Keep the observed Squee/recursion discard engine, but repair the "
            "confirmed pressure failure by preserving the 607 miracle/topdeck "
            "anchors and forcing a denser interaction, protection, and board-wipe "
            "package before battle."
        ),
        "required_cards": [
            "Squee, Goblin Nabob",
            "Library of Leng",
            "Monument to Endurance",
            "Faithless Looting",
            "Wheel of Fortune",
            "Underworld Breach",
            "Past in Flames",
            "Mizzix's Mastery",
            "Reforge the Soul",
            "Sensei's Divining Top",
            "Scroll Rack",
            "Bender's Waterskin",
            "Molecule Man",
            "The Scarlet Witch",
            "Swords to Plowshares",
            "Path to Exile",
            "Stroke of Midnight",
            "Winds of Abandon",
            "Generous Gift",
            "Blasphemous Act",
            "Farewell",
            "Promise of Loyalty",
            "Teferi's Protection",
            "Deflecting Swat",
            "Flawless Maneuver",
            "Dawn's Truce",
        ],
        "package_weights": {
            "graveyard_recursion": 10.0,
            "hand_filter": 9.0,
            "topdeck_miracle_setup": 9.0,
            "pressure_absorber": 9.0,
            "protection_window": 8.0,
            "spell_chain_conversion": 7.0,
            "deterministic_finisher": 7.0,
            "early_plan": 6.0,
        },
        "role_targets": {
            "land": 34,
            "ramp": 17,
            "draw": 16,
            "removal": 13,
            "protection": 13,
            "board_wipe": 4,
            "tutor": 4,
            "wincon": 8,
            "recursion": 7,
        },
        "land_target": 34,
        "min_basics": 6,
        "mountain_bias": 0.62,
    },
    "access_density_control": {
        "mode": "from_scratch",
        "candidate_key": "challenger_lorehold_access_density_control_v1",
        "candidate_name": "Lorehold From-Scratch Access Density Control v1",
        "candidate_archetype": "from-scratch-access-density-control",
        "intent": (
            "Repair the weak-seed access problem without cutting the protected 607 "
            "miracle shell: keep Top/Rack/Library/Squee/Land Tax plus the pressure "
            "package, then add both Enlightened Tutor and Gamble so the deck can "
            "find its first-draw setup or decisive spell-chain engine more often."
        ),
        "required_cards": [
            "Enlightened Tutor",
            "Gamble",
            "Land Tax",
            "Sensei's Divining Top",
            "Scroll Rack",
            "Library of Leng",
            "Squee, Goblin Nabob",
            "Bender's Waterskin",
            "Victory Chimes",
            "Molecule Man",
            "The Scarlet Witch",
            "Approach of the Second Sun",
            "Mizzix's Mastery",
            "Reforge the Soul",
            "Wheel of Fortune",
            "Faithless Looting",
            "Underworld Breach",
            "Teferi's Protection",
            "Deflecting Swat",
            "Flawless Maneuver",
            "Dawn's Truce",
            "Swords to Plowshares",
            "Path to Exile",
            "Stroke of Midnight",
            "Generous Gift",
            "Winds of Abandon",
            "High Noon",
            "Blasphemous Act",
            "Farewell",
            "Promise of Loyalty",
        ],
        "package_weights": {
            "topdeck_miracle_setup": 11.0,
            "hand_filter": 9.0,
            "protection_window": 9.0,
            "pressure_absorber": 9.0,
            "spell_chain_conversion": 8.0,
            "graveyard_recursion": 8.0,
            "deterministic_finisher": 7.0,
            "early_plan": 6.0,
        },
        "role_targets": {
            "land": 34,
            "ramp": 16,
            "draw": 16,
            "removal": 12,
            "protection": 13,
            "board_wipe": 4,
            "tutor": 6,
            "wincon": 8,
            "recursion": 7,
        },
        "land_target": 34,
        "min_basics": 6,
        "mountain_bias": 0.62,
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def parse_deck_ids(raw: str | None) -> list[int]:
    if not raw:
        return list(DEFAULT_CORPUS_DECK_IDS)
    return [int(part.strip()) for part in raw.split(",") if part.strip()]


def parse_plans(raw: str | None) -> list[str]:
    if not raw or raw == "all":
        return list(CHALLENGER_PLANS)
    plans = [part.strip() for part in raw.split(",") if part.strip()]
    unknown = [plan for plan in plans if plan not in CHALLENGER_PLANS]
    if unknown:
        raise ValueError(f"unknown challenger plans: {unknown}")
    return plans


def json_list(value: object) -> list[Any]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def card_roles(row: Mapping[str, Any]) -> set[str]:
    roles: set[str] = set()
    for item in json_list(row.get("functional_tags_json")):
        if isinstance(item, Mapping):
            value = item.get("tag") or item.get("role") or item.get("category")
        else:
            value = item
        if value:
            roles.add(normalize_name(value).replace(" ", "_"))
    if row.get("functional_tag"):
        roles.add(normalize_name(row["functional_tag"]).replace(" ", "_"))
    if row.get("is_land") or "Land" in str(row.get("type_line") or ""):
        roles.add("land")
    return {role for role in roles if role and role != "unknown"}


def card_payload(row: Mapping[str, Any]) -> dict[str, Any]:
    roles = sorted(card_roles(row))
    return {
        "card_name": row.get("card_name"),
        "name": row.get("card_name"),
        "quantity": int(row.get("quantity") or 1),
        "roles": roles,
        "is_commander": bool(row.get("is_commander")),
        "is_land": "land" in roles or "Land" in str(row.get("type_line") or ""),
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "oracle_text": row.get("oracle_text") or "",
    }


def row_quality(row: Mapping[str, Any]) -> tuple[int, int, int]:
    return (
        len(card_roles(row)),
        len(str(row.get("oracle_text") or "")),
        -int(row.get("deck_id") or 999999),
    )


def load_corpus(conn: sqlite3.Connection, deck_ids: Iterable[int]) -> dict[str, dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    deck_ids = list(deck_ids)
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT *
        FROM deck_cards
        WHERE deck_id IN ({placeholders})
        ORDER BY deck_id, is_commander DESC, card_name
        """,
        tuple(deck_ids),
    ).fetchall()
    grouped: dict[str, dict[str, Any]] = {}
    for sqlite_row in rows:
        row = dict(sqlite_row)
        key = normalize_name(row.get("card_name"))
        if not key:
            continue
        entry = grouped.setdefault(
            key,
            {
                "representative": row,
                "source_deck_ids": [],
                "source_rows": [],
            },
        )
        entry["source_deck_ids"].append(int(row["deck_id"]))
        entry["source_rows"].append(row)
        if row_quality(row) > row_quality(entry["representative"]):
            entry["representative"] = row
    for entry in grouped.values():
        entry["source_deck_ids"] = sorted(set(entry["source_deck_ids"]))
        representative = dict(entry["representative"])
        representative["source_deck_ids"] = entry["source_deck_ids"]
        representative["appearance_count"] = len(entry["source_deck_ids"])
        representative["roles"] = sorted(card_roles(representative))
        entry["representative"] = representative
    return grouped


def weighted_role_counts(rows: Iterable[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for row in rows:
        quantity = int(row.get("quantity") or 1)
        for role in card_roles(row):
            counts[role] += quantity
    return counts


def strategy_counts(rows: Iterable[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for row in rows:
        payload = card_payload(row)
        for tag in strategy_tags_for_card(payload):
            counts[tag] += int(row.get("quantity") or 1)
    return counts


def cmc(row: Mapping[str, Any]) -> float:
    try:
        return float(row.get("cmc") or 0)
    except Exception:
        return 0.0


def score_card(
    row: Mapping[str, Any],
    plan: Mapping[str, Any],
    *,
    role_counts: Counter[str],
    package_counts: Counter[str],
) -> float:
    name = normalize_name(row.get("card_name"))
    roles = card_roles(row)
    tags = strategy_tags_for_card(card_payload(row))
    score = float(row.get("appearance_count") or 1) * 2.4
    score += float(ACTIVE_ANCHOR_BONUS.get(name, 0)) * 0.55
    for tag in tags:
        tag_weight = float((plan.get("package_weights") or {}).get(tag, 0.0))
        package_spec = INTENT_PACKAGE_RANGES.get(tag)
        if package_spec:
            minimum = int(package_spec["minimum"])
            maximum = int(package_spec["maximum"])
            current = int(package_counts[tag])
            if current < minimum:
                score += tag_weight + 3.5
            elif current >= maximum:
                score -= (tag_weight * 0.85) + ((current - maximum + 1) * 1.5)
            else:
                score += tag_weight * 0.35
        else:
            score += tag_weight
    for role in roles:
        role_spec = INTENT_ROLE_RANGES.get(role)
        if role_spec:
            maximum = int(role_spec["maximum"])
            current = int(role_counts[role])
            if current >= maximum:
                score -= 5.0 + ((current - maximum + 1) * 1.25)
                continue
        target = int((plan.get("role_targets") or {}).get(role, 0))
        if target and role_counts[role] < target:
            score += min(6.0, 2.0 + (target - role_counts[role]) * 0.25)
        elif target and role_counts[role] >= target:
            score -= 1.5
    if cmc(row) <= 2 and roles.intersection({"ramp", "draw", "removal", "protection", "tutor"}):
        score += 4.0
    if "Instant" in str(row.get("type_line") or "") or "Sorcery" in str(row.get("type_line") or ""):
        score += float((plan.get("package_weights") or {}).get("spell_chain_conversion", 0.0)) * 0.35
    if not roles and not tags:
        score -= 8.0
    if "manual_review" in roles:
        score -= 4.0
    return round(score, 3)


def clone_row(row: Mapping[str, Any], *, quantity: int | None = None, deck_id: int | None = None) -> dict[str, Any]:
    result = dict(row)
    result.pop("id", None)
    if quantity is not None:
        result["quantity"] = quantity
    if deck_id is not None:
        result["deck_id"] = deck_id
    return result


def add_named_card(
    selected: dict[str, dict[str, Any]],
    pool: Mapping[str, Mapping[str, Any]],
    card_name: str,
    *,
    missing: list[str],
) -> None:
    key = normalize_name(card_name)
    if key in selected:
        return
    entry = pool.get(key)
    if not entry:
        missing.append(card_name)
        return
    selected[key] = clone_row(entry["representative"], quantity=1)


def build_lands(
    pool: Mapping[str, Mapping[str, Any]],
    plan: Mapping[str, Any],
    *,
    deck_id: int,
) -> list[dict[str, Any]]:
    land_target = int(plan.get("land_target") or 34)
    min_basics = int(plan.get("min_basics") or 6)
    nonbasic_target = max(0, land_target - min_basics)
    selected: dict[str, dict[str, Any]] = {}
    missing: list[str] = []

    for name in LAND_PRIORITY:
        if len(selected) >= nonbasic_target:
            break
        add_named_card(selected, pool, name, missing=missing)

    role_counts: Counter[str] = Counter({"land": len(selected)})
    package_counts: Counter[str] = Counter()
    land_candidates = [
        entry["representative"]
        for key, entry in pool.items()
        if key not in selected and "land" in card_roles(entry["representative"])
    ]
    land_candidates.sort(
        key=lambda row: (
            -score_card(row, plan, role_counts=role_counts, package_counts=package_counts),
            str(row.get("card_name") or ""),
        )
    )
    for row in land_candidates:
        if len(selected) >= nonbasic_target:
            break
        name = str(row.get("card_name") or "")
        if normalize_name(name) in {"mountain // mountain", "plains // plains"}:
            continue
        selected[normalize_name(name)] = clone_row(row, quantity=1)

    current_land_qty = len(selected)
    basic_qty = max(0, land_target - current_land_qty)
    mountain_qty = int(round(basic_qty * float(plan.get("mountain_bias") or 0.6)))
    mountain_qty = max(0, min(basic_qty, mountain_qty))
    plains_qty = basic_qty - mountain_qty

    rows = [clone_row(row, quantity=1, deck_id=deck_id) for row in selected.values()]
    for name, qty in (("Mountain // Mountain", mountain_qty), ("Plains // Plains", plains_qty)):
        if qty <= 0:
            continue
        entry = pool.get(normalize_name(name))
        if not entry:
            continue
        rows.append(clone_row(entry["representative"], quantity=qty, deck_id=deck_id))
    return rows


def build_nonlands(
    pool: Mapping[str, Mapping[str, Any]],
    plan: Mapping[str, Any],
    *,
    deck_id: int,
    target_count: int,
) -> tuple[list[dict[str, Any]], list[str]]:
    selected: dict[str, dict[str, Any]] = {}
    missing: list[str] = []
    for card_name in plan.get("required_cards") or []:
        add_named_card(selected, pool, str(card_name), missing=missing)

    while len(selected) < target_count:
        role_counts = weighted_role_counts(selected.values())
        package_counts = strategy_counts(selected.values())
        candidates = [
            entry["representative"]
            for key, entry in pool.items()
            if key not in selected
            and not bool(entry["representative"].get("is_commander"))
            and "land" not in card_roles(entry["representative"])
        ]
        if not candidates:
            break
        candidates.sort(
            key=lambda row: (
                -score_card(row, plan, role_counts=role_counts, package_counts=package_counts),
                str(row.get("card_name") or ""),
            )
        )
        selected[normalize_name(candidates[0].get("card_name"))] = clone_row(candidates[0], quantity=1)

    return [clone_row(row, quantity=1, deck_id=deck_id) for row in selected.values()], missing


def build_candidate_rows(
    pool: Mapping[str, Mapping[str, Any]],
    plan_key: str,
    *,
    deck_id: int,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    plan = CHALLENGER_PLANS[plan_key]
    commander_entry = pool.get(normalize_name("Lorehold, the Historian"))
    if not commander_entry:
        raise RuntimeError("Lorehold commander not found in corpus")
    commander = clone_row(commander_entry["representative"], quantity=1, deck_id=deck_id)
    commander["is_commander"] = 1

    land_rows = build_lands(pool, plan, deck_id=deck_id)
    land_quantity = sum(int(row.get("quantity") or 1) for row in land_rows)
    nonland_target = 99 - land_quantity
    nonland_rows, missing = build_nonlands(
        pool,
        plan,
        deck_id=deck_id,
        target_count=nonland_target,
    )
    rows = [commander] + sorted(nonland_rows, key=lambda row: str(row.get("card_name") or "")) + sorted(
        land_rows,
        key=lambda row: str(row.get("card_name") or ""),
    )
    quantity_total = sum(int(row.get("quantity") or 1) for row in rows)
    if quantity_total != 100:
        raise RuntimeError(f"{plan_key} quantity_total={quantity_total}, expected 100")
    metadata = {
        "plan_key": plan_key,
        "mode": plan["mode"],
        "protected_baseline_deck_id": PROTECTED_BASELINE_DECK_ID,
        "candidate_deck_id": deck_id,
        "missing_required_cards": missing,
        "row_count": len(rows),
        "quantity_total": quantity_total,
        "land_quantity": land_quantity,
        "nonland_quantity": 99 - land_quantity,
    }
    return rows, metadata


def insert_deck_rows(conn: sqlite3.Connection, rows: list[dict[str, Any]], *, deck_id: int) -> None:
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)") if row[1] != "id"]
    placeholders = ",".join("?" for _ in columns)
    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
    for source in rows:
        values = dict(source)
        values["deck_id"] = deck_id
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            [values.get(column) for column in columns],
        )


def summarize_rows(rows: list[Mapping[str, Any]], plan: Mapping[str, Any]) -> dict[str, Any]:
    final_deck = [card_payload(row) for row in rows]
    names = [
        f"{int(card.get('quantity') or 1)} {card.get('card_name')}"
        for card in final_deck
    ]
    return {
        "candidate_hash": hashlib.sha256("\n".join(sorted(names)).encode("utf-8")).hexdigest(),
        "role_counts": dict(sorted(weighted_role_counts(rows).items())),
        "strategy_package_counts": dict(sorted(strategy_counts(rows).items())),
        "commander_intent_alignment": commander_intent_alignment(final_deck),
        "final_deck": final_deck,
        "required_cards": list(plan.get("required_cards") or []),
    }


def display_card_name(card_name: Any) -> str:
    name = str(card_name or "")
    parts = [part.strip() for part in name.split(" // ")]
    if len(parts) == 2 and parts[0] == parts[1]:
        return parts[0]
    return name


def render_decklist_text(report: Mapping[str, Any]) -> str:
    cards = list(report.get("final_deck") or [])
    commander = [card for card in cards if card.get("is_commander")]
    nonlands = [card for card in cards if not card.get("is_commander") and not card.get("is_land")]
    lands = [card for card in cards if not card.get("is_commander") and card.get("is_land")]
    ordered = (
        sorted(commander, key=lambda card: str(card.get("card_name") or "").lower())
        + sorted(nonlands, key=lambda card: str(card.get("card_name") or "").lower())
        + sorted(lands, key=lambda card: str(card.get("card_name") or "").lower())
    )
    return "\n".join(
        f"{int(card.get('quantity') or 1)} {display_card_name(card.get('card_name'))}"
        for card in ordered
    ) + "\n"


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        f"# {report['candidate_name']}",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- mode: `{report['mode']}`",
        f"- candidate_key: `{report['candidate_key']}`",
        f"- candidate_db: `{report['candidate_db']}`",
        f"- candidate_hash: `{report['candidate_hash']}`",
        f"- protected_baseline_deck_id: `{report['protected_baseline_deck_id']}`",
        f"- fixed_opponent_deck_id_for_gate: `{report['fixed_opponent_deck_id_for_gate']}`",
        f"- commander_intent_score: `{report['commander_intent_alignment']['score']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Intent",
        "",
        str(report["intent"]),
        "",
        "## Required Anchors",
        "",
    ]
    for card in report.get("required_cards") or []:
        lines.append(f"- {card}")
    if report.get("missing_required_cards"):
        lines.extend(["", "## Missing Required Cards", ""])
        for card in report["missing_required_cards"]:
            lines.append(f"- {card}")
    lines.extend(
        [
            "",
            "## Counts",
            "",
            f"- row_count: `{report['row_count']}`",
            f"- quantity_total: `{report['quantity_total']}`",
            f"- land_quantity: `{report['land_quantity']}`",
            f"- nonland_quantity: `{report['nonland_quantity']}`",
            "",
            "### Strategy Packages",
            "",
        ]
    )
    for key, value in report["strategy_package_counts"].items():
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "### Roles", ""])
    for key, value in report["role_counts"].items():
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "## Validation Commands", "", "```bash"])
    lines.append(" ".join(report["matrix_command"]))
    lines.append(" ".join(report["battle_gate_command"]))
    lines.extend(["```", "", "## Decklist", "", "```text", render_decklist_text(report).rstrip(), "```"])
    return "\n".join(lines) + "\n"


def build_plan(
    *,
    source_db: Path,
    pool: Mapping[str, Mapping[str, Any]],
    plan_key: str,
    out_dir: Path,
    stem: str,
    corpus_deck_ids: list[int],
    opponent_limit: int,
    games: int,
    game_timeout_seconds: float,
) -> dict[str, Any]:
    plan = CHALLENGER_PLANS[plan_key]
    plan_dir = out_dir / plan_key
    plan_dir.mkdir(parents=True, exist_ok=True)
    candidate_db = plan_dir / "knowledge_candidate.db"
    shutil.copy2(source_db, candidate_db)
    rows, metadata = build_candidate_rows(pool, plan_key, deck_id=DEFAULT_CANDIDATE_DECK_ID)

    conn = sqlite3.connect(candidate_db)
    insert_deck_rows(conn, rows, deck_id=DEFAULT_CANDIDATE_DECK_ID)
    conn.execute(
        """
        INSERT INTO decks (id, deck_name, archetype, total_cards, notes)
        VALUES (?, ?, ?, 100, ?)
        ON CONFLICT(id) DO UPDATE SET
          deck_name=excluded.deck_name,
          archetype=excluded.archetype,
          total_cards=excluded.total_cards,
          notes=excluded.notes
        """,
        (
            DEFAULT_CANDIDATE_DECK_ID,
            plan["candidate_name"],
            plan["candidate_archetype"],
            "isolated from-scratch challenger generated by lorehold_from_scratch_challenger_builder.py",
        ),
    )
    conn.commit()
    conn.close()

    report_stem = f"{stem}_{plan_key}"
    json_path = REPORT_DIR / f"{report_stem}.json"
    md_path = REPORT_DIR / f"{report_stem}.md"
    decklist_path = REPORT_DIR / f"{report_stem}.decklist.txt"
    matrix_prefix = REPORT_DIR / f"{report_stem}_matrix"
    battle_stem = f"{report_stem}_fixed607_gate"
    matrix_command = [
        "python3",
        str(SCRIPT_DIR / "lorehold_variant_strategy_matrix.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        ",".join(str(item) for item in corpus_deck_ids),
        "--candidate",
        str(json_path),
        "--out-prefix",
        str(matrix_prefix),
    ]
    battle_gate_command = [
        "python3",
        str(SCRIPT_DIR / "lorehold_variant_battle_gate.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        str(PROTECTED_BASELINE_DECK_ID),
        "--candidate-db",
        str(candidate_db),
        "--candidate-key",
        str(plan["candidate_key"]),
        "--candidate-name",
        str(plan["candidate_name"]),
        "--candidate-archetype",
        str(plan["candidate_archetype"]),
        "--candidate-deck-id",
        str(DEFAULT_CANDIDATE_DECK_ID),
        "--matrix",
        str(matrix_prefix.with_suffix(".json")),
        "--fixed-opponent-deck-ids",
        str(PROTECTED_BASELINE_DECK_ID),
        "--opponent-limit",
        str(opponent_limit),
        "--games",
        str(games),
        "--game-timeout-seconds",
        str(game_timeout_seconds),
        "--isolate-deck-process",
        "--stem",
        battle_stem,
    ]
    report = {
        "generated_at": utc_now(),
        "status": "generated_from_scratch_challenger",
        "strategy_version": STRATEGY_VERSION,
        "source_db": str(source_db),
        "candidate_db": str(candidate_db),
        "candidate_key": plan["candidate_key"],
        "candidate_name": plan["candidate_name"],
        "candidate_archetype": plan["candidate_archetype"],
        "intent": plan["intent"],
        "corpus_deck_ids": corpus_deck_ids,
        "fixed_opponent_deck_id_for_gate": PROTECTED_BASELINE_DECK_ID,
        "matrix_command": matrix_command,
        "matrix_json": str(matrix_prefix.with_suffix(".json")),
        "matrix_markdown": str(matrix_prefix.with_suffix(".md")),
        "battle_gate_command": battle_gate_command,
        "battle_gate_json": str(REPORT_DIR / f"{battle_stem}.json"),
        "battle_gate_markdown": str(REPORT_DIR / f"{battle_stem}.md"),
        "postgres_writes": False,
        "source_db_mutated": False,
        **metadata,
        **summarize_rows(rows, plan),
    }
    json_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(report), encoding="utf-8")
    decklist_path.write_text(render_decklist_text(report), encoding="utf-8")
    report["json"] = str(json_path)
    report["markdown"] = str(md_path)
    report["decklist"] = str(decklist_path)
    return report


def render_summary_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold From-Scratch Challenger Builder",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- source_db: `{report['source_db']}`",
        f"- corpus_deck_ids: `{', '.join(str(item) for item in report['corpus_deck_ids'])}`",
        f"- protected_baseline_deck_id: `{report['protected_baseline_deck_id']}`",
        "- from_scratch_policy: `607 may be a corpus source and fixed opponent, but no candidate is generated as a 607 swap list`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Challengers",
        "",
        "| Candidate | Intent Score | Lands | Ramp | Draw | Protection | Wincon | Missing Required | Battle Gate |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for candidate in report.get("candidates") or []:
        roles = candidate.get("role_counts") or {}
        lines.append(
            f"| [{candidate['candidate_name']}]({candidate['markdown']}) | "
            f"{candidate['commander_intent_alignment']['score']} | "
            f"{roles.get('land', 0)} | {roles.get('ramp', 0)} | {roles.get('draw', 0)} | "
            f"{roles.get('protection', 0)} | {roles.get('wincon', 0)} | "
            f"{', '.join(candidate.get('missing_required_cards') or []) or 'none'} | "
            f"`{candidate['battle_gate_json']}` |"
        )
    lines.extend(
        [
            "",
            "## Next Gate",
            "",
            "Run each emitted battle command. The fixed opponent deck id is `607`, and the protected baseline `607` also remains the only registered deck in `--deck-ids`, so the same run compares the challenger to baseline behavior and to a table that always includes deck 607 as one opponent.",
        ]
    )
    return "\n".join(lines) + "\n"


def build_all(
    *,
    source_db: Path,
    plan_keys: list[str],
    corpus_deck_ids: list[int],
    out_dir: Path,
    stem: str,
    opponent_limit: int,
    games: int,
    game_timeout_seconds: float,
) -> dict[str, Any]:
    conn = sqlite3.connect(source_db)
    pool = load_corpus(conn, corpus_deck_ids)
    conn.close()
    candidates = [
        build_plan(
            source_db=source_db,
            pool=pool,
            plan_key=plan_key,
            out_dir=out_dir,
            stem=stem,
            corpus_deck_ids=corpus_deck_ids,
            opponent_limit=opponent_limit,
            games=games,
            game_timeout_seconds=game_timeout_seconds,
        )
        for plan_key in plan_keys
    ]
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "source_db": str(source_db),
        "corpus_deck_ids": corpus_deck_ids,
        "protected_baseline_deck_id": PROTECTED_BASELINE_DECK_ID,
        "fixed_opponent_deck_id_for_gate": PROTECTED_BASELINE_DECK_ID,
        "postgres_writes": False,
        "source_db_mutated": False,
        "candidates": candidates,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--corpus-deck-ids", default=None)
    parser.add_argument("--plans", default="all")
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=REPORT_DIR / "lorehold_from_scratch_challengers_20260630",
    )
    parser.add_argument("--stem", default="lorehold_from_scratch_challengers_20260630")
    parser.add_argument("--opponent-limit", type=int, default=4)
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--game-timeout-seconds", type=float, default=30.0)
    args = parser.parse_args()

    plan_keys = parse_plans(args.plans)
    corpus_deck_ids = parse_deck_ids(args.corpus_deck_ids)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    report = build_all(
        source_db=args.source_db,
        plan_keys=plan_keys,
        corpus_deck_ids=corpus_deck_ids,
        out_dir=args.out_dir,
        stem=args.stem,
        opponent_limit=max(1, args.opponent_limit),
        games=max(1, args.games),
        game_timeout_seconds=max(0.0, float(args.game_timeout_seconds or 0)),
    )
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_summary_markdown(report), encoding="utf-8")
    print(json.dumps({"status": "ready", "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
