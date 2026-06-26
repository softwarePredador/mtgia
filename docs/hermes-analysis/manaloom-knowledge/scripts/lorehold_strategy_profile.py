#!/usr/bin/env python3
"""Strategy-first scoring helpers for Lorehold candidate generation.

This module is intentionally local to the Lorehold workflow. It converts
card-level roles and Oracle text into the strategic packages the deck actually
needs under battle pressure: early plan, miracle/topdeck setup, protection,
pressure absorption, spell-chain conversion, recursion, and finishers.
"""

from __future__ import annotations

import re
from collections import Counter
from typing import Any, Mapping


STRATEGY_VERSION = "lorehold_strategy_profile_v2_2026_06_26"

COMMANDER_INTENT_MODEL = {
    "commander": "Lorehold, the Historian",
    "objective": (
        "Use topdeck setup, hand filtering, and Lorehold's commander discount to "
        "cast high-impact instant/sorcery spells ahead of curve, then convert that "
        "window into a deterministic finisher while surviving fast combat pressure."
    ),
    "plan_a": [
        "Set up the top of the library and hand before the expensive spell turn.",
        "Use Lorehold discount/cost reducers to chain impactful instants and sorceries.",
        "Protect the conversion window instead of filling the deck with generic value pieces.",
    ],
    "validation_rule": (
        "A candidate is not accepted from structure alone. It must tie or beat the "
        "protected deck_607 baseline on the same real-opponent battle gate and must "
        "not regress the Winota pressure matchup."
    ),
}

PACKAGE_MINIMUMS = {
    "early_plan": 18,
    "topdeck_miracle_setup": 6,
    "hand_filter": 7,
    "spell_chain_conversion": 12,
    "protection_window": 10,
    "pressure_absorber": 4,
    "graveyard_recursion": 5,
    "deterministic_finisher": 6,
}

PACKAGE_WEIGHTS = {
    "early_plan": 4.0,
    "topdeck_miracle_setup": 7.0,
    "hand_filter": 5.0,
    "spell_chain_conversion": 6.0,
    "protection_window": 7.0,
    "pressure_absorber": 9.0,
    "graveyard_recursion": 6.0,
    "deterministic_finisher": 8.0,
}

INTENT_PACKAGE_RANGES = {
    "early_plan": {"minimum": 24, "maximum": 45, "weight": 9.0},
    "topdeck_miracle_setup": {"minimum": 8, "maximum": 14, "weight": 13.0},
    "hand_filter": {"minimum": 10, "maximum": 18, "weight": 10.0},
    "spell_chain_conversion": {"minimum": 32, "maximum": 46, "weight": 13.0},
    "protection_window": {"minimum": 12, "maximum": 20, "weight": 10.0},
    "pressure_absorber": {"minimum": 12, "maximum": 20, "weight": 11.0},
    "graveyard_recursion": {"minimum": 5, "maximum": 10, "weight": 7.0},
    "deterministic_finisher": {"minimum": 8, "maximum": 12, "weight": 10.0},
}

INTENT_ROLE_RANGES = {
    "land": {"minimum": 33, "maximum": 36, "weight": 8.0},
    "ramp": {"minimum": 12, "maximum": 22, "weight": 7.0},
    "draw": {"minimum": 10, "maximum": 18, "weight": 6.0},
    "removal": {"minimum": 8, "maximum": 14, "weight": 5.0},
    "board_wipe": {"minimum": 2, "maximum": 7, "weight": 4.0},
    "protection": {"minimum": 8, "maximum": 14, "weight": 5.0},
    "wincon": {"minimum": 7, "maximum": 12, "weight": 5.0},
    "tutor": {"minimum": 1, "maximum": 6, "weight": 3.0},
}

ACTIVE_ANCHOR_BONUS = {
    "aetherflux reservoir": 26.0,
    "arcane signet": 8.0,
    "birgi, god of storytelling // harnfel, horn of bounty": 18.0,
    "boros signet": 9.0,
    "brainstone": 6.0,
    "crawlspace": 15.0,
    "drannith magistrate": 22.0,
    "fellwar stone": 8.0,
    "flawless maneuver": 18.0,
    "get lost": 14.0,
    "ghostly prison": 12.0,
    "lotus petal": 10.0,
    "giver of runes": 12.0,
    "magus of the moat": 24.0,
    "mana vault": 10.0,
    "mother of runes": 14.0,
    "mox amber": 10.0,
    "ruby medallion": 8.0,
    "seething song": 8.0,
    "silent arbiter": 15.0,
    "sphere of safety": 24.0,
    "talisman of conviction": 9.0,
    "wheel of fortune": 12.0,
    "wheel of misfortune": 16.0,
    "windborn muse": 22.0,
}

FORCE_KEEP_ACTIVE_ANCHORS = set(ACTIVE_ANCHOR_BONUS)

NAME_TAGS = {
    "aetherflux reservoir": {"deterministic_finisher", "spell_chain_conversion"},
    "approach of the second sun": {"deterministic_finisher", "spell_chain_conversion"},
    "arcane signet": {"early_plan"},
    "birgi, god of storytelling // harnfel, horn of bounty": {
        "early_plan",
        "hand_filter",
        "spell_chain_conversion",
    },
    "boros signet": {"early_plan"},
    "brainstone": {"early_plan", "topdeck_miracle_setup", "hand_filter"},
    "crawlspace": {"pressure_absorber", "protection_window"},
    "dualcaster mage": {"deterministic_finisher", "spell_chain_conversion"},
    "drannith magistrate": {"protection_window", "pressure_absorber"},
    "fellwar stone": {"early_plan"},
    "flawless maneuver": {"pressure_absorber", "protection_window", "spell_chain_conversion"},
    "get lost": {"early_plan", "pressure_absorber", "spell_chain_conversion"},
    "giver of runes": {"early_plan", "protection_window"},
    "ghostly prison": {"pressure_absorber", "protection_window"},
    "grand abolisher": {"protection_window", "spell_chain_conversion"},
    "hall of heliod's generosity": {"graveyard_recursion"},
    "heat shimmer": {"deterministic_finisher", "spell_chain_conversion"},
    "land tax": {"early_plan", "topdeck_miracle_setup", "hand_filter"},
    "lotus petal": {"early_plan", "spell_chain_conversion"},
    "magus of the moat": {"pressure_absorber", "protection_window"},
    "mana vault": {"early_plan", "spell_chain_conversion"},
    "mizzix's mastery": {"graveyard_recursion", "deterministic_finisher", "spell_chain_conversion"},
    "molten duplication": {"deterministic_finisher", "spell_chain_conversion"},
    "mother of runes": {"early_plan", "protection_window"},
    "mox amber": {"early_plan", "spell_chain_conversion"},
    "orim's chant": {"protection_window", "spell_chain_conversion"},
    "past in flames": {"graveyard_recursion", "spell_chain_conversion"},
    "ranger-captain of eos": {"protection_window", "spell_chain_conversion"},
    "reiterate": {"spell_chain_conversion", "deterministic_finisher"},
    "reverberate": {"spell_chain_conversion"},
    "rite of flame": {"early_plan", "spell_chain_conversion"},
    "ruby medallion": {"early_plan", "spell_chain_conversion"},
    "scroll rack": {"topdeck_miracle_setup", "hand_filter", "early_plan"},
    "seething song": {"early_plan", "spell_chain_conversion"},
    "sensei's divining top": {"topdeck_miracle_setup", "hand_filter", "early_plan"},
    "silence": {"protection_window", "spell_chain_conversion"},
    "silent arbiter": {"pressure_absorber", "protection_window"},
    "sphere of safety": {"pressure_absorber", "protection_window"},
    "talisman of conviction": {"early_plan"},
    "the biblioplex": {"topdeck_miracle_setup", "hand_filter"},
    "twinflame": {"deterministic_finisher", "spell_chain_conversion"},
    "underworld breach": {"graveyard_recursion", "spell_chain_conversion"},
    "wheel of fortune": {"hand_filter", "spell_chain_conversion"},
    "wheel of misfortune": {"hand_filter", "spell_chain_conversion"},
    "windborn muse": {"pressure_absorber", "protection_window"},
    "worldfire": {"deterministic_finisher"},
}

TEXT_TAG_PATTERNS = (
    (re.compile(r"\bcopy target (?:instant|sorcery|spell)\b", re.I), "spell_chain_conversion"),
    (re.compile(r"\bcopy .* creature\b", re.I), "spell_chain_conversion"),
    (re.compile(r"\bcast .* from your graveyard\b|\bflashback\b", re.I), "graveyard_recursion"),
    (re.compile(r"\bgraveyard\b", re.I), "graveyard_recursion"),
    (re.compile(r"\btop card\b|\btop .* library\b|\bfirst card you draw\b", re.I), "topdeck_miracle_setup"),
    (re.compile(r"\bdiscard .* draw\b|\bdraw .* discard\b|\bwheel\b", re.I), "hand_filter"),
    (re.compile(r"\bcan't cast spells\b|\bcan't be countered\b|\bcounter target\b", re.I), "protection_window"),
    (re.compile(r"\bindestructible\b|\bphase out\b|\bprotection from\b", re.I), "protection_window"),
    (re.compile(r"\bcan't attack you\b|\bcan't attack\b|\bmore than one creature\b", re.I), "pressure_absorber"),
    (re.compile(r"\bwin the game\b|\bloses? the game\b", re.I), "deterministic_finisher"),
)

ROLE_TAGS = {
    "board_wipe": {"pressure_absorber"},
    "copy": {"spell_chain_conversion"},
    "copy_spell": {"spell_chain_conversion"},
    "copy_spell_engine": {"spell_chain_conversion"},
    "draw": {"hand_filter"},
    "engine": {"spell_chain_conversion"},
    "protection": {"protection_window"},
    "ramp": {"early_plan"},
    "recursion": {"graveyard_recursion"},
    "removal": {"pressure_absorber"},
    "stax": {"pressure_absorber", "protection_window"},
    "tutor": {"spell_chain_conversion"},
    "wincon": {"deterministic_finisher"},
}


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def _roles(card: Mapping[str, Any]) -> set[str]:
    return {normalize_name(role).replace(" ", "_") for role in card.get("roles") or [] if role}


def _cmc(card: Mapping[str, Any]) -> float:
    try:
        return float(card.get("cmc") or 0)
    except Exception:
        return 0.0


def strategy_tags_for_card(card: Mapping[str, Any]) -> set[str]:
    name = normalize_name(card.get("card_name") or card.get("name"))
    text = f"{card.get('type_line') or ''}\n{card.get('oracle_text') or ''}"
    tags = set(NAME_TAGS.get(name, set()))

    for role in _roles(card):
        tags.update(ROLE_TAGS.get(role, set()))

    for pattern, tag in TEXT_TAG_PATTERNS:
        if pattern.search(text):
            tags.add(tag)

    type_line = str(card.get("type_line") or "")
    if _cmc(card) <= 2 and not card.get("is_land"):
        if tags.intersection(
            {
                "hand_filter",
                "protection_window",
                "spell_chain_conversion",
                "topdeck_miracle_setup",
            }
        ) or _roles(card).intersection({"ramp", "removal", "draw", "stax"}):
            tags.add("early_plan")
    if "Instant" in type_line or "Sorcery" in type_line:
        tags.add("spell_chain_conversion")

    return tags


def strategy_counts(cards: list[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for card in cards:
        for tag in strategy_tags_for_card(card):
            counts[tag] += 1
    return counts


def strategy_shortfalls(cards: list[Mapping[str, Any]]) -> dict[str, dict[str, int]]:
    counts = strategy_counts(cards)
    return {
        package: {"actual": counts[package], "minimum": minimum}
        for package, minimum in PACKAGE_MINIMUMS.items()
        if counts[package] < minimum
    }


def _weighted_role_counts(cards: list[Mapping[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for card in cards:
        quantity = int(card.get("quantity") or 1)
        roles = set(_roles(card))
        type_line = str(card.get("type_line") or "")
        if card.get("is_land") or "Land" in type_line:
            roles.add("land")
        for role in roles:
            counts[role] += quantity
    return counts


def _range_score(actual: int, spec: Mapping[str, float]) -> dict[str, Any]:
    minimum = int(spec["minimum"])
    maximum = int(spec["maximum"])
    weight = float(spec["weight"])
    if actual < minimum:
        ratio = actual / max(1, minimum)
        score = weight * ratio
        status = "shortfall"
        gap = minimum - actual
        overage = 0
    elif actual > maximum:
        overage = actual - maximum
        penalty = min(weight * 0.72, overage * max(0.2, weight / max(1, maximum)))
        score = max(0.0, weight - penalty)
        status = "overfilled"
        gap = 0
    else:
        score = weight
        status = "aligned"
        gap = 0
        overage = 0
    return {
        "actual": actual,
        "minimum": minimum,
        "maximum": maximum,
        "status": status,
        "gap": gap,
        "overage": overage,
        "score": round(score, 3),
        "weight": weight,
    }


def commander_intent_alignment(cards: list[Mapping[str, Any]]) -> dict[str, Any]:
    package_counts = strategy_counts(cards)
    role_counts = _weighted_role_counts(cards)
    package_ranges = {
        package: _range_score(int(package_counts.get(package, 0)), spec)
        for package, spec in INTENT_PACKAGE_RANGES.items()
    }
    role_ranges = {
        role: _range_score(int(role_counts.get(role, 0)), spec)
        for role, spec in INTENT_ROLE_RANGES.items()
    }
    off_plan_cards = []
    for card in cards:
        if card.get("is_land"):
            continue
        tags = strategy_tags_for_card(card)
        roles = _roles(card)
        if not tags and not roles.intersection({"land", "ramp", "draw", "removal", "board_wipe", "protection", "wincon"}):
            off_plan_cards.append(str(card.get("card_name") or card.get("name") or "?"))

    total_weight = sum(float(spec["weight"]) for spec in INTENT_PACKAGE_RANGES.values()) + sum(
        float(spec["weight"]) for spec in INTENT_ROLE_RANGES.values()
    )
    raw_score = sum(item["score"] for item in package_ranges.values()) + sum(
        item["score"] for item in role_ranges.values()
    )
    off_plan_penalty = min(8.0, len(off_plan_cards) * 1.25)
    score = max(0.0, min(100.0, (raw_score / total_weight * 100.0) - off_plan_penalty))
    risks = [
        f"package_{package}_{status['status']}"
        for package, status in package_ranges.items()
        if status["status"] != "aligned"
    ]
    risks.extend(
        f"role_{role}_{status['status']}"
        for role, status in role_ranges.items()
        if status["status"] != "aligned"
    )
    if off_plan_cards:
        risks.append("off_plan_cards")
    return {
        "model": COMMANDER_INTENT_MODEL,
        "score": round(score, 3),
        "status": "aligned" if score >= 82 and not risks else "needs_battle_proof",
        "package_ranges": package_ranges,
        "role_ranges": role_ranges,
        "off_plan_cards": off_plan_cards[:12],
        "risks": risks[:16],
    }


def strategy_score_breakdown(
    card: Mapping[str, Any],
    *,
    current_counts: Counter[str] | None = None,
    in_active_deck: bool | None = None,
) -> dict[str, float]:
    name = normalize_name(card.get("card_name") or card.get("name"))
    tags = strategy_tags_for_card(card)
    active = bool(card.get("in_active_deck")) if in_active_deck is None else bool(in_active_deck)
    breakdown: dict[str, float] = {}

    tag_value = sum(PACKAGE_WEIGHTS.get(tag, 0.0) for tag in tags)
    if tag_value:
        breakdown["strategy_package_tags"] = min(18.0, tag_value)

    if active and name in ACTIVE_ANCHOR_BONUS:
        breakdown["active_strategy_anchor"] = ACTIVE_ANCHOR_BONUS[name]

    if current_counts is not None:
        gap_bonus = 0.0
        for package, minimum in PACKAGE_MINIMUMS.items():
            if package in tags and current_counts[package] < minimum:
                gap_bonus += min(6.0, 2.0 + (minimum - current_counts[package]) * 0.5)
        if gap_bonus:
            breakdown["strategy_gap_fill"] = min(18.0, gap_bonus)

    if (
        not active
        and _cmc(card) >= 4
        and tags == {"spell_chain_conversion"}
        and "Instant" not in str(card.get("type_line") or "")
        and "Sorcery" not in str(card.get("type_line") or "")
    ):
        breakdown["generic_engine_drag"] = -4.0

    return breakdown


def strategy_score(
    card: Mapping[str, Any],
    *,
    current_counts: Counter[str] | None = None,
    in_active_deck: bool | None = None,
) -> float:
    return round(
        sum(strategy_score_breakdown(card, current_counts=current_counts, in_active_deck=in_active_deck).values()),
        3,
    )


def force_keep_active_anchor(card: Mapping[str, Any]) -> bool:
    return bool(card.get("in_active_deck")) and normalize_name(
        card.get("card_name") or card.get("name")
    ) in FORCE_KEEP_ACTIVE_ANCHORS
