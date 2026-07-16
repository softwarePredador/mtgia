#!/usr/bin/env python3
"""Build a deck-level Lorehold strategy matrix.

This script is intentionally read-only. It compares the registered Lorehold
decks as strategy hypotheses instead of treating the queue as isolated card
swaps. The output is used to decide which deck structure deserves the next
equal battle gate and which strategy gaps need runtime/rule work first.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from lorehold_strategy_profile import (
    ACTIVE_ANCHOR_BONUS,
    COMMANDER_INTENT_MODEL,
    PACKAGE_MINIMUMS,
    STRATEGY_VERSION,
    commander_intent_alignment,
    strategy_tags_for_card,
)
from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_CANDIDATE = (
    REPORT_DIR / "lorehold_generated_candidate_20260626_pg243_strategy_first_v7.json"
)
DEFAULT_DECK_IDS = (6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616)

FUNCTION_ROLE_MINIMUMS = {
    "land": 33,
    "ramp": 14,
    "draw": 12,
    "removal": 8,
    "protection": 10,
    "recursion": 4,
    "board_wipe": 2,
    "tutor": 4,
    "wincon": 6,
}

STRATEGY_PACKAGE_LABELS = {
    "early_plan": "early setup/mana",
    "topdeck_miracle_setup": "topdeck and miracle setup",
    "hand_filter": "hand filtering",
    "spell_chain_conversion": "spell-chain conversion",
    "protection_window": "protection window",
    "pressure_absorber": "combat pressure absorber",
    "graveyard_recursion": "graveyard recursion",
    "deterministic_finisher": "deterministic finisher",
}

EXTERNAL_METHOD_SOURCES = [
    {
        "label": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "use": "commander-specific comparison lane for Lorehold package expectations and recurring card choices",
    },
    {
        "label": "EDHREC spellslinger Commander guide",
        "url": "https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander",
        "use": "method source for instant/sorcery-heavy shells: card flow, cheap spells, protection, recursion, and payoffs",
    },
    {
        "label": "EDHREC Commander deckbuilding guide",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "use": "baseline deck-structure guardrails for lands, ramp, draw, removal, and focused packages",
    },
    {
        "label": "Archidekt Lorehold corpus",
        "url": "https://archidekt.com/commanders/Lorehold%2C%20the%20Historian",
        "use": "external corpus lane for comparing user-built Lorehold shells and recurring package choices",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


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


def parse_deck_ids(raw: str | None) -> list[int]:
    if not raw:
        return list(DEFAULT_DECK_IDS)
    return [int(part.strip()) for part in raw.split(",") if part.strip()]


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    return (
        conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            (table,),
        ).fetchone()
        is not None
    )


def role_from_value(value: object) -> str:
    role = normalize_name(value).replace(" ", "_")
    aliases = {
        "attack_limit": "protection",
        "attack_tax": "protection",
        "boardwipe": "board_wipe",
        "card_advantage": "draw",
        "copy": "engine",
        "copy_spell": "engine",
        "copy_spell_engine": "engine",
        "damage_wipe": "board_wipe",
        "draw_cards": "draw",
        "draw_engine": "draw",
        "finisher": "wincon",
        "graveyard": "recursion",
        "graveyard_to_battlefield": "recursion",
        "life_drain_engine": "wincon",
        "mill_spell": "wincon",
        "ramp_engine": "ramp",
        "ramp_permanent": "ramp",
        "ramp_ritual": "ramp",
        "remove_creature": "removal",
        "remove_permanent": "removal",
        "removal_destroy": "removal",
        "silence_opponents": "protection",
        "spell_copy": "engine",
        "static_cost_reducer": "ramp",
        "static_cost_reduction": "ramp",
        "topdeck_manipulation": "draw",
        "treasure_maker": "ramp",
        "tutor_to_hand": "tutor",
        "wipe": "board_wipe",
    }
    return aliases.get(role, role)


def roles_for_card(card: Mapping[str, Any]) -> set[str]:
    roles: set[str] = set()
    type_line = str(card.get("type_line") or "")
    if "Land" in type_line or card.get("is_land"):
        roles.add("land")
    if card.get("functional_tag"):
        roles.add(role_from_value(card.get("functional_tag")))
    for role in card.get("roles") or []:
        roles.add(role_from_value(role))
    for value in json_list(card.get("functional_tags_json")):
        if isinstance(value, dict):
            value = value.get("tag") or value.get("role") or value.get("category")
        roles.add(role_from_value(value))
    return {role for role in roles if role and role != "unknown"}


def load_deck_metadata(conn: sqlite3.Connection, deck_ids: Iterable[int]) -> dict[str, dict[str, Any]]:
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT id, deck_name, archetype, total_cards, notes
        FROM decks
        WHERE id IN ({placeholders})
        ORDER BY id
        """,
        tuple(deck_ids),
    ).fetchall()
    return {
        f"deck_{row['id']}": {
            "deck_key": f"deck_{row['id']}",
            "deck_id": int(row["id"]),
            "deck_name": row["deck_name"],
            "archetype": row["archetype"] or "unknown",
            "total_cards_declared": int(row["total_cards"] or 0),
            "notes": row["notes"] or "",
            "source": "hermes_decks",
        }
        for row in rows
    }


def load_deck_cards(conn: sqlite3.Connection, deck_ids: Iterable[int]) -> dict[str, list[dict[str, Any]]]:
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
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        card = dict(row)
        card["roles"] = sorted(roles_for_card(card))
        card["is_land"] = "land" in card["roles"]
        card["normalized_name"] = normalize_name(card.get("card_name"))
        grouped[f"deck_{int(row['deck_id'])}"].append(card)
    return dict(grouped)


def load_battle_ready_names(conn: sqlite3.Connection) -> set[str]:
    if not table_exists(conn, "battle_card_rules"):
        return set()
    rows = conn.execute(
        """
        SELECT DISTINCT normalized_name
        FROM battle_card_rules
        WHERE execution_status != 'disabled'
          AND review_status IN ('verified', 'active', 'needs_review')
        """
    ).fetchall()
    return {normalize_name(row["normalized_name"]) for row in rows}


def load_candidate_cards(path: Path) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
    if not path.exists():
        return None, []
    payload = json.loads(path.read_text(encoding="utf-8"))
    cards: list[dict[str, Any]] = []
    for raw in payload.get("final_deck") or []:
        card = dict(raw)
        card["quantity"] = int(card.get("quantity") or 1)
        card["roles"] = [role_from_value(role) for role in card.get("roles") or []]
        card["is_land"] = bool(card.get("is_land") or "land" in set(card["roles"]))
        card["functional_tag"] = None
        card["functional_tags_json"] = json.dumps(card["roles"])
        card["normalized_name"] = normalize_name(card.get("card_name"))
        cards.append(card)
    candidate_key = str(payload.get("candidate_key") or "candidate_v7")
    candidate_name = str(payload.get("candidate_name") or "Lorehold strategy-first candidate v7")
    candidate_archetype = str(payload.get("candidate_archetype") or "strategy-first-candidate")
    metadata = {
        "deck_key": candidate_key,
        "deck_id": None,
        "deck_name": candidate_name,
        "archetype": candidate_archetype,
        "total_cards_declared": len(cards),
        "notes": f"candidate_hash={payload.get('candidate_hash')}",
        "source": str(path),
        "candidate_hash": payload.get("candidate_hash"),
        "strategy_version": payload.get("strategy_version"),
    }
    return metadata, cards


def weighted_role_counts(cards: list[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for card in cards:
        quantity = int(card.get("quantity") or 1)
        roles = roles_for_card(card) or set(card.get("roles") or [])
        for role in roles:
            counts[role] += quantity
    return counts


def strategy_package_counts(cards: list[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for card in cards:
        for tag in strategy_tags_for_card(card):
            counts[tag] += 1
    return counts


def strategy_health(counts: Mapping[str, int]) -> dict[str, dict[str, Any]]:
    health: dict[str, dict[str, Any]] = {}
    for package, minimum in PACKAGE_MINIMUMS.items():
        actual = int(counts.get(package, 0))
        ratio = actual / minimum if minimum else 1.0
        health[package] = {
            "label": STRATEGY_PACKAGE_LABELS.get(package, package),
            "actual": actual,
            "minimum": minimum,
            "ratio": round(ratio, 3),
            "status": "pass" if actual >= minimum else "shortfall",
            "gap": max(0, minimum - actual),
        }
    return health


def role_health(counts: Mapping[str, int]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for role, minimum in FUNCTION_ROLE_MINIMUMS.items():
        actual = int(counts.get(role, 0))
        result[role] = {
            "actual": actual,
            "minimum": minimum,
            "status": "pass" if actual >= minimum else "shortfall",
            "gap": max(0, minimum - actual),
        }
    return result


def rank_key_cards(cards: list[Mapping[str, Any]], package: str | None = None) -> list[str]:
    ranked: list[tuple[float, str]] = []
    for card in cards:
        name = str(card.get("card_name") or card.get("name") or "")
        normalized = normalize_name(name)
        tags = strategy_tags_for_card(card)
        roles = set(card.get("roles") or [])
        if package and package not in tags:
            continue
        score = float(ACTIVE_ANCHOR_BONUS.get(normalized, 0))
        score += 6.0 if "wincon" in roles or "deterministic_finisher" in tags else 0.0
        score += 4.0 if "topdeck_miracle_setup" in tags else 0.0
        score += 3.0 if "protection_window" in tags or "pressure_absorber" in tags else 0.0
        score += 1.0 if tags else 0.0
        if score > 0:
            ranked.append((score, name))
    ranked.sort(key=lambda item: (-item[0], item[1]))
    return [name for _, name in ranked[:10]]


def infer_objective(
    metadata: Mapping[str, Any],
    package_counts: Mapping[str, int],
    role_counts: Mapping[str, int],
    key_cards: list[str],
) -> dict[str, Any]:
    archetype = normalize_name(metadata.get("archetype"))
    if "artifact-control" in archetype:
        objective = "Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines."
    elif "lifegain-storm" in archetype:
        objective = "Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers."
    elif "burn-dragon-control" in archetype:
        objective = "Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers."
    elif "spell-copy-combo" in archetype:
        objective = "Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins."
    elif "spell-copy-control" in archetype:
        objective = "Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win."
    elif "big-spells" in archetype:
        objective = "Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve."
    elif "strategy-first-candidate" in archetype:
        objective = "Strategy-first miracle spellslinger control/combo shell that preserves the active core while tuning lands and package balance."
    elif package_counts.get("topdeck_miracle_setup", 0) >= PACKAGE_MINIMUMS["topdeck_miracle_setup"]:
        objective = "Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains."
    else:
        objective = "General Lorehold spellslinger shell; current evidence is not specific enough to prove one dominant plan."

    proof = []
    if package_counts.get("spell_chain_conversion", 0):
        proof.append(f"spell_chain_conversion={package_counts.get('spell_chain_conversion', 0)}")
    if package_counts.get("topdeck_miracle_setup", 0):
        proof.append(f"topdeck_miracle_setup={package_counts.get('topdeck_miracle_setup', 0)}")
    if package_counts.get("pressure_absorber", 0):
        proof.append(f"pressure_absorber={package_counts.get('pressure_absorber', 0)}")
    if role_counts.get("wincon", 0):
        proof.append(f"wincon_roles={role_counts.get('wincon', 0)}")
    if key_cards:
        proof.append("key_cards=" + ", ".join(key_cards[:4]))
    return {"objective": objective, "evidence": proof}


def deck_strengths(
    package_status: Mapping[str, Mapping[str, Any]],
    role_status: Mapping[str, Mapping[str, Any]],
    key_cards: list[str],
) -> list[str]:
    strengths: list[str] = []
    for package, status in sorted(package_status.items(), key=lambda item: (-item[1]["ratio"], item[0])):
        if status["status"] == "pass" and len(strengths) < 4:
            strengths.append(
                f"{status['label']} passes ({status['actual']}/{status['minimum']})"
            )
    for role, status in sorted(role_status.items(), key=lambda item: (-item[1]["actual"], item[0])):
        if status["status"] == "pass" and role not in {"land"} and len(strengths) < 6:
            strengths.append(f"{role} density passes ({status['actual']}/{status['minimum']})")
    if key_cards and len(strengths) < 7:
        strengths.append("anchors present: " + ", ".join(key_cards[:5]))
    return strengths[:7]


def deck_weaknesses(
    package_status: Mapping[str, Mapping[str, Any]],
    role_status: Mapping[str, Mapping[str, Any]],
    land_count: int,
    battle_ready_ratio: float,
) -> list[str]:
    weaknesses: list[str] = []
    for package, status in sorted(package_status.items(), key=lambda item: (-item[1]["gap"], item[0])):
        if status["status"] == "shortfall":
            weaknesses.append(
                f"{status['label']} shortfall ({status['actual']}/{status['minimum']}, gap {status['gap']})"
            )
    for role, status in sorted(role_status.items(), key=lambda item: (-item[1]["gap"], item[0])):
        if status["status"] == "shortfall":
            weaknesses.append(f"{role} role shortfall ({status['actual']}/{status['minimum']})")
    if land_count < 31:
        weaknesses.append(f"low land count for Commander baseline ({land_count})")
    if land_count > 37:
        weaknesses.append(f"high land count can crowd nonland engine slots ({land_count})")
    if battle_ready_ratio < 0.9:
        weaknesses.append(f"battle-rule readiness below 90% ({battle_ready_ratio:.1%})")
    return weaknesses[:10]


def next_validation_steps(deck: Mapping[str, Any]) -> list[str]:
    steps = [
        "run equal battle gate against the same opponent set and seed window",
        "inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind",
    ]
    shortfalls = deck.get("strategy_package_shortfalls") or []
    if "topdeck_miracle_setup" in shortfalls:
        steps.append("test topdeck/miracle setup additions before judging expensive spell slots")
    if "pressure_absorber" in shortfalls:
        steps.append("test combat-pressure package because table pressure can kill the spell-chain plan before it starts")
    if "deterministic_finisher" in shortfalls:
        steps.append("verify that win lines are deterministic enough instead of only value-positive")
    if deck.get("battle_rule_ready_ratio", 1.0) < 0.9:
        steps.append("close missing battle-rule/runtime gaps before trusting battle outcomes")
    return steps


def primary_risks(deck: Mapping[str, Any]) -> list[str]:
    risks = list(deck.get("strategy_package_shortfalls") or [])
    role_health_map = deck.get("role_health") or {}
    for role, status in role_health_map.items():
        if status.get("status") == "shortfall":
            risks.append(f"{role}_role")
    if deck.get("battle_rule_ready_ratio", 1.0) < 0.9:
        risks.append("battle_rule_readiness")
    land_count = int(deck.get("land_count") or 0)
    if land_count < 31:
        risks.append("low_land_count")
    elif land_count > 37:
        risks.append("high_land_count")
    return risks[:8]


def summarize_deck(
    metadata: Mapping[str, Any],
    cards: list[dict[str, Any]],
    battle_ready_names: set[str],
) -> dict[str, Any]:
    role_counts = weighted_role_counts(cards)
    package_counts = strategy_package_counts(cards)
    package_status = strategy_health(package_counts)
    role_status = role_health(role_counts)
    intent_alignment = commander_intent_alignment(cards)
    key_cards = rank_key_cards(cards)
    unique_names = {normalize_name(card.get("card_name")) for card in cards}
    ready_names = {name for name in unique_names if name in battle_ready_names}
    battle_ready_ratio = len(ready_names) / len(unique_names) if unique_names else 0.0
    land_count = int(role_counts.get("land", 0))
    objective = infer_objective(metadata, package_counts, role_counts, key_cards)
    shortfalls = [
        package
        for package, status in package_status.items()
        if status["status"] == "shortfall"
    ]

    result = {
        **dict(metadata),
        "card_rows": len(cards),
        "unique_cards": len(unique_names),
        "quantity_total": sum(int(card.get("quantity") or 1) for card in cards),
        "land_count": land_count,
        "nonland_count": sum(int(card.get("quantity") or 1) for card in cards) - land_count,
        "role_counts": dict(sorted(role_counts.items())),
        "role_health": role_status,
        "strategy_package_counts": dict(sorted(package_counts.items())),
        "strategy_package_health": package_status,
        "strategy_package_shortfalls": shortfalls,
        "commander_intent_alignment": intent_alignment,
        "commander_intent_score": intent_alignment["score"],
        "commander_intent_status": intent_alignment["status"],
        "commander_intent_risks": intent_alignment["risks"],
        "battle_rule_ready_unique_cards": len(ready_names),
        "battle_rule_total_unique_cards": len(unique_names),
        "battle_rule_ready_ratio": round(battle_ready_ratio, 4),
        "objective": objective["objective"],
        "objective_evidence": objective["evidence"],
        "key_cards": key_cards,
        "key_cards_by_package": {
            package: rank_key_cards(cards, package)
            for package in PACKAGE_MINIMUMS
        },
        "strengths": deck_strengths(package_status, role_status, key_cards),
        "weaknesses": deck_weaknesses(package_status, role_status, land_count, battle_ready_ratio),
    }
    result["next_validation_steps"] = next_validation_steps(result)
    result["primary_risks"] = primary_risks(result)
    return result


def strategy_score(deck: Mapping[str, Any]) -> float:
    package_health = deck.get("strategy_package_health") or {}
    role = deck.get("role_health") or {}
    package_points = 0.0
    for status in package_health.values():
        package_points += min(1.25, float(status.get("ratio") or 0)) * 10.0
    role_points = 0.0
    for status in role.values():
        role_points += min(1.15, float(status.get("actual") or 0) / max(1, float(status.get("minimum") or 1))) * 3.0
    readiness_points = float(deck.get("battle_rule_ready_ratio") or 0) * 12.0
    land_penalty = 0.0
    land_count = int(deck.get("land_count") or 0)
    if land_count < 31:
        land_penalty = (31 - land_count) * 2.0
    elif land_count > 37:
        land_penalty = (land_count - 37) * 1.5
    shortfall_penalty = len(deck.get("strategy_package_shortfalls") or []) * 3.0
    intent_score = float(deck.get("commander_intent_score") or 0)
    intent_risks = deck.get("commander_intent_risks") or []
    intent_penalty = min(16.0, len(intent_risks) * 1.5)
    legacy_score = package_points + role_points + readiness_points - land_penalty - shortfall_penalty
    return round((legacy_score * 0.45) + (intent_score * 0.8) - intent_penalty, 3)


def build_matrix(
    conn: sqlite3.Connection,
    *,
    deck_ids: list[int],
    candidate_path: Path | None = DEFAULT_CANDIDATE,
    source_db: Path | str = DEFAULT_DB,
) -> dict[str, Any]:
    conn.row_factory = sqlite3.Row
    metadata = load_deck_metadata(conn, deck_ids)
    cards_by_deck = load_deck_cards(conn, deck_ids)
    battle_ready_names = load_battle_ready_names(conn)

    if candidate_path:
        candidate_metadata, candidate_cards = load_candidate_cards(candidate_path)
        if candidate_metadata and candidate_cards:
            metadata[candidate_metadata["deck_key"]] = candidate_metadata
            cards_by_deck[candidate_metadata["deck_key"]] = candidate_cards

    decks = []
    def deck_sort_key(key: str) -> tuple[int, str]:
        if key.startswith("deck_"):
            try:
                return (int(key.split("_", 1)[1]), key)
            except (IndexError, ValueError):
                return (999998, key)
        return (999999, key)

    for deck_key in sorted(metadata, key=deck_sort_key):
        summary = summarize_deck(metadata[deck_key], cards_by_deck.get(deck_key, []), battle_ready_names)
        summary["strategy_score"] = strategy_score(summary)
        decks.append(summary)

    ranked = sorted(decks, key=lambda deck: (-float(deck["strategy_score"]), str(deck["deck_key"])))
    source_db_path = Path(source_db).resolve()
    source_db_sha256 = (
        hashlib.sha256(source_db_path.read_bytes()).hexdigest()
        if source_db_path.is_file()
        else None
    )
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "strategy_version": STRATEGY_VERSION,
        "source_db": str(source_db_path),
        "source_db_sha256": source_db_sha256,
        "deck_ids": deck_ids,
        "candidate_path": str(candidate_path) if candidate_path else None,
        "external_method_sources": EXTERNAL_METHOD_SOURCES,
        "method": {
            "unit_of_analysis": "one registered Lorehold deck or candidate deck",
            "primary_question": "Which deck structure best supports Lorehold's commander plan under battle pressure?",
            "commander_intent_model": COMMANDER_INTENT_MODEL,
            "score_components": [
                "strategy package health against Lorehold-specific minimums",
                "commander intent package and role ranges with overfill penalties",
                "functional role health against Commander/Lorehold minimums",
                "battle-rule readiness ratio",
                "mana base land-count guardrail",
                "explicit penalty for strategy package shortfalls",
            ],
            "battle_status": "structural matrix only; equal battle gate is the next validation step",
        },
        "ranked_deck_keys": [deck["deck_key"] for deck in ranked],
        "decks": decks,
        "best_structural_deck": ranked[0]["deck_key"] if ranked else None,
    }


def write_markdown(payload: Mapping[str, Any], path: Path) -> None:
    ranked = {key: idx + 1 for idx, key in enumerate(payload.get("ranked_deck_keys") or [])}
    lines = [
        "# Lorehold Variant Strategy Matrix",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Strategy profile: `{payload['strategy_version']}`",
        f"- Scope: decks `{', '.join(str(deck_id) for deck_id in payload['deck_ids'])}` plus candidate v7 when available.",
        f"- Best structural deck before equal battle gate: `{payload.get('best_structural_deck')}`",
        f"- Commander intent: {COMMANDER_INTENT_MODEL['objective']}",
        "",
        "## Validation Frame",
        "",
        "This matrix treats each Lorehold deck as a strategic hypothesis. A deck is not considered better just because it has individually strong cards; it must show a coherent plan, enough package density to execute that plan, avoid overfilled generic packages, keep enough battle-rule readiness for simulations to be meaningful, and produce a fair battle result in the next gate.",
        "",
        "External method sources used as criteria inputs:",
    ]
    for source in payload.get("external_method_sources") or []:
        lines.append(f"- [{source['label']}]({source['url']}): {source['use']}.")
    lines.extend(
        [
            "",
            "## Ranked Structural Read",
            "",
            "| Rank | Deck | Archetype | Score | Intent | Lands | Rule Ready | Objective | Main Risks |",
            "| ---: | --- | --- | ---: | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for deck in sorted(payload.get("decks") or [], key=lambda item: ranked.get(item["deck_key"], 999)):
        risks = ", ".join(deck.get("primary_risks") or []) or "none"
        objective = str(deck.get("objective") or "").replace("|", "\\|")
        lines.append(
            f"| {ranked.get(deck['deck_key'], 999)} | {deck['deck_name']} (`{deck['deck_key']}`) | {deck['archetype']} | {deck['strategy_score']:.1f} | {deck['commander_intent_score']:.1f} | {deck['land_count']} | {deck['battle_rule_ready_ratio']:.1%} | {objective} | {risks} |"
        )

    for deck in sorted(payload.get("decks") or [], key=lambda item: ranked.get(item["deck_key"], 999)):
        lines.extend(
            [
                "",
                f"## {ranked.get(deck['deck_key'], 999)}. {deck['deck_name']} (`{deck['deck_key']}`)",
                "",
                f"**Objective:** {deck['objective']}",
                "",
                f"**Commander intent alignment:** score `{deck['commander_intent_score']:.1f}`, status `{deck['commander_intent_status']}`.",
                "",
                "**Intent risks:** " + (", ".join(deck.get("commander_intent_risks") or []) or "none"),
                "",
                "**Evidence:** " + ("; ".join(deck.get("objective_evidence") or []) or "no direct objective evidence captured"),
                "",
                "**Strengths:**",
            ]
        )
        for item in deck.get("strengths") or ["none captured"]:
            lines.append(f"- {item}")
        lines.append("")
        lines.append("**Weaknesses / Risk:**")
        for item in deck.get("weaknesses") or ["none captured"]:
            lines.append(f"- {item}")
        lines.append("")
        lines.append("**Next Validation:**")
        for item in deck.get("next_validation_steps") or []:
            lines.append(f"- {item}")
        lines.append("")
        lines.append("**Key Cards:** " + (", ".join(deck.get("key_cards") or []) or "none captured"))

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-ids", default=None)
    parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract",
    )
    args = parser.parse_args()

    deck_ids = parse_deck_ids(args.deck_ids)
    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    payload = build_matrix(
        conn,
        deck_ids=deck_ids,
        candidate_path=args.candidate,
        source_db=args.db,
    )

    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"json": str(json_path), "markdown": str(md_path), "status": payload["status"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
