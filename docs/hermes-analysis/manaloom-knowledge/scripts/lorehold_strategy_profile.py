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


STRATEGY_VERSION = "lorehold_strategy_profile_v1_2026_06_26"

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
