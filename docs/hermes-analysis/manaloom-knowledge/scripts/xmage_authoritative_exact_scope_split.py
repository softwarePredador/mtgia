#!/usr/bin/env python3
"""Split authoritative XMage queue rows into exact ManaLoom runtime scopes.

This is the bridge between "XMage source resolved" and "PostgreSQL executable
rule candidate". It deliberately accepts only narrow, runtime-backed spell
patterns. Broad review scopes stay blocked for a later subpattern mapper.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from battle_rule_registry import deck_role_from_effect, logical_rule_key


REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"

DRAW_UNIT = "draw_cards::xmage_draw_card_variant_review_v1"
DAMAGE_UNIT = "direct_damage::targeted_damage_variant_v1"
DESTROY_UNIT = "removal_destroy::targeted_destroy_variant_v1"
LIFE_UNIT = "life_gain::xmage_life_gain_variant_review_v1"
EXILE_UNIT = "removal_exile::targeted_exile_variant_v1"
RAMP_ARTIFACT_UNIT = "ramp_permanent::xmage_artifact_mana_source_variant_review_v1"
RAMP_CREATURE_UNIT = "ramp_permanent::xmage_creature_mana_source_variant_review_v1"
COUNTER_UNIT = "counter_spell::counter_target_stack_object_variant_v1"
BOUNCE_UNIT = "bounce::targeted_return_to_hand_variant_v1"
RECURSION_UNIT = "recursion::xmage_graveyard_return_variant_review_v1"
BOARD_WIPE_UNIT = "board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1"
ADD_COUNTERS_TARGET_UNIT = "add_counters::targeted_add_counters_variant_v1"
BOOST_TARGET_UNIT = (
    "xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::"
    "no_condition_class::targeting"
)
SUPPORTED_UNITS = {
    DRAW_UNIT,
    DAMAGE_UNIT,
    DESTROY_UNIT,
    LIFE_UNIT,
    EXILE_UNIT,
    RAMP_ARTIFACT_UNIT,
    RAMP_CREATURE_UNIT,
    COUNTER_UNIT,
    BOUNCE_UNIT,
    RECURSION_UNIT,
    BOARD_WIPE_UNIT,
    ADD_COUNTERS_TARGET_UNIT,
    BOOST_TARGET_UNIT,
}

DRAW_SCOPE = "xmage_fixed_source_controller_draw_spell_v1"
DAMAGE_SCOPE = "xmage_fixed_damage_target_spell_v1"
DESTROY_SCOPE = "xmage_destroy_target_spell_v1"
LIFE_SCOPE = "xmage_fixed_controller_gain_life_spell_v1"
EXILE_SCOPE = "xmage_exile_target_spell_v1"
MANA_SCOPE = "xmage_simple_tap_mana_source_permanent_v1"
COUNTER_SCOPE = "xmage_counter_target_spell_v1"
BOUNCE_SCOPE = "xmage_return_target_to_hand_spell_v1"
RECURSION_SCOPE = "xmage_return_target_graveyard_card_to_hand_spell_v1"
BOARD_WIPE_SCOPE = "xmage_destroy_all_matching_permanents_spell_v1"
DAMAGE_WIPE_SCOPE = "xmage_fixed_damage_all_matching_permanents_spell_v1"
ADD_COUNTERS_TARGET_SCOPE = "xmage_fixed_add_counters_target_creature_spell_v1"
BOOST_TARGET_SCOPE = "xmage_fixed_boost_target_creature_until_eot_spell_v1"
STATIC_KEYWORD_CREATURE_SCOPE = "xmage_static_self_combat_keyword_creature_v1"
ETB_LIFE_GAIN_CREATURE_SCOPE = "xmage_creature_etb_gain_life_v1"

SPELL_UNITS = {
    DRAW_UNIT,
    DAMAGE_UNIT,
    DESTROY_UNIT,
    LIFE_UNIT,
    EXILE_UNIT,
    COUNTER_UNIT,
    BOUNCE_UNIT,
    RECURSION_UNIT,
    BOARD_WIPE_UNIT,
    ADD_COUNTERS_TARGET_UNIT,
    BOOST_TARGET_UNIT,
}
RAMP_UNITS = {RAMP_ARTIFACT_UNIT, RAMP_CREATURE_UNIT}

SPELL_COMPLEXITY_TOKENS = {
    "additional cost",
    "choose one",
    "choose two",
    "one or both",
    "kicker",
    "buyback",
    "flashback",
    "convoke",
    "strive",
    "cycling",
    "cascade",
    "storm",
    "recover",
    "replicate",
    "unless",
    "instead",
    "if ",
    "when ",
    "whenever ",
}

SAFE_MANA_ABILITY_CLASSES = {
    "SimpleManaAbility",
    "AnyColorManaAbility",
    "ColorlessManaAbility",
    "WhiteManaAbility",
    "BlueManaAbility",
    "BlackManaAbility",
    "RedManaAbility",
    "GreenManaAbility",
}

UNSAFE_MANA_ABILITY_CLASSES = {
    "ConditionalAnyColorManaAbility",
    "ConditionalColoredManaAbility",
    "ConditionalColorlessManaAbility",
    "DynamicManaAbility",
    "LimitedTimesPerTurnActivatedManaAbility",
}

STATIC_SELF_KEYWORD_ABILITY_CLASSES = {
    "DeathtouchAbility": "deathtouch",
    "DefenderAbility": "defender",
    "DoubleStrikeAbility": "double_strike",
    "FirstStrikeAbility": "first_strike",
    "FlyingAbility": "flying",
    "HasteAbility": "haste",
    "HexproofAbility": "hexproof",
    "IndestructibleAbility": "indestructible",
    "LifelinkAbility": "lifelink",
    "MenaceAbility": "menace",
    "ReachAbility": "reach",
    "ShroudAbility": "shroud",
    "TrampleAbility": "trample",
    "VigilanceAbility": "vigilance",
}

STATIC_SELF_KEYWORD_ORDER = [
    "flying",
    "first_strike",
    "double_strike",
    "deathtouch",
    "lifelink",
    "menace",
    "reach",
    "trample",
    "vigilance",
    "haste",
    "defender",
    "hexproof",
    "shroud",
    "indestructible",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def md5_text(value: str) -> str:
    return hashlib.md5(str(value or "").encode("utf-8")).hexdigest()


def fetch_card_metadata_by_id() -> dict[str, dict[str, Any]]:
    from db_helper import connect

    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  id::text AS card_id,
                  name,
                  COALESCE(type_line, '') AS type_line,
                  COALESCE(oracle_text, '') AS oracle_text,
                  COALESCE(mana_cost, '') AS mana_cost,
                  md5(COALESCE(oracle_text, '')) AS oracle_hash
                FROM cards
                """
            )
            columns = [desc[0] for desc in cur.description]
            return {str(row[0]): dict(zip(columns, row)) for row in cur.fetchall()}


def default_source_reader(row: dict[str, Any]) -> str:
    path = Path(str(row.get("xmage_path") or ""))
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def java_constructor_int(source: str, class_name: str, *, default: int | None = None) -> int | None:
    match = re.search(rf"\b{re.escape(class_name)}\s*\(\s*(\d+)\b", source)
    if match:
        return int(match.group(1))
    return default


def has_additional_cost(source: str) -> bool:
    return bool(re.search(r"\.addCost\s*\(", source or ""))


def is_spell(metadata: dict[str, Any]) -> bool:
    type_line = str(metadata.get("type_line") or "").lower()
    return "instant" in type_line or "sorcery" in type_line


def spell_flags(metadata: dict[str, Any]) -> dict[str, bool]:
    type_line = str(metadata.get("type_line") or "").lower()
    return {
        "instant": "instant" in type_line,
        "sorcery": "sorcery" in type_line,
    }


def effect_classes(row: dict[str, Any]) -> set[str]:
    return {str(value) for value in (row.get("xmage_effect_classes") or []) if str(value)}


def ability_kind(row: dict[str, Any]) -> str:
    return str((row.get("effect_json") or {}).get("ability_kind") or "")


def ability_classes(row: dict[str, Any]) -> set[str]:
    return {str(value) for value in (row.get("xmage_ability_classes") or []) if str(value)}


def oracle_text(metadata: dict[str, Any]) -> str:
    return re.sub(r"\s+", " ", str(metadata.get("oracle_text") or "").strip()).lower()


def has_oracle_complexity(metadata: dict[str, Any], tokens: set[str] = SPELL_COMPLEXITY_TOKENS) -> bool:
    text = oracle_text(metadata)
    for token in tokens:
        if re.fullmatch(r"[a-z]+", token):
            if re.search(rf"\b{re.escape(token)}\b(?!['’]s\b)", text):
                return True
            continue
        if token in text:
            return True
    return False


def destroy_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = oracle_text(metadata)
    if "destroy target" not in text:
        return None
    if re.search(r"destroy target artifact or enchantment\b", text):
        return "remove_permanent", "artifact_or_enchantment"
    if re.search(r"destroy target artifact\b", text):
        return "remove_permanent", "artifact"
    if re.search(r"destroy target enchantment\b", text):
        return "remove_permanent", "enchantment"
    if re.search(r"destroy target nonland permanent\b", text):
        return "remove_permanent", "nonland_permanent"
    if re.search(r"destroy target creature, enchantment, or planeswalker\b", text):
        return "remove_permanent", "creature_enchantment_or_planeswalker"
    if re.search(r"destroy target creature or planeswalker\b", text):
        return "remove_permanent", "creature_or_planeswalker"
    if re.search(r"destroy target creature\b", text):
        return "remove_creature", "creature"
    if re.search(r"destroy target land\b", text):
        return "remove_permanent", "land"
    if re.search(r"destroy target permanent\b", text):
        return "remove_permanent", "permanent"
    return None


def exile_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, tuple[str, str]]] = [
        (r"^exile target artifact or enchantment\.?$", ("remove_permanent", "artifact_or_enchantment")),
        (r"^exile target creature or planeswalker\.?$", ("remove_permanent", "creature_or_planeswalker")),
        (r"^exile target creature or enchantment\.?$", ("remove_permanent", "creature_or_enchantment")),
        (r"^exile target nonland permanent\.?$", ("remove_permanent", "nonland_permanent")),
        (r"^exile target permanent\.?$", ("remove_permanent", "permanent")),
        (r"^exile target creature\.?$", ("remove_creature", "creature")),
        (r"^exile target artifact\.?$", ("remove_permanent", "artifact")),
        (r"^exile target enchantment\.?$", ("remove_permanent", "enchantment")),
        (r"^exile target land\.?$", ("remove_permanent", "land")),
    ]
    for pattern, result in patterns:
        if re.match(pattern, text):
            return result
    return None


def bounce_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, tuple[str, str]]] = [
        (
            r"^return target artifact or enchantment to its owner's hand\.?$",
            ("remove_permanent", "artifact_or_enchantment"),
        ),
        (
            r"^return target creature or enchantment to its owner's hand\.?$",
            ("remove_permanent", "creature_or_enchantment"),
        ),
        (
            r"^return target creature or planeswalker to its owner's hand\.?$",
            ("remove_permanent", "creature_or_planeswalker"),
        ),
        (
            r"^return target nonland permanent to its owner's hand\.?$",
            ("remove_permanent", "nonland_permanent"),
        ),
        (r"^return target permanent to its owner's hand\.?$", ("remove_permanent", "permanent")),
        (r"^return target creature to its owner's hand\.?$", ("remove_creature", "creature")),
        (r"^return target artifact to its owner's hand\.?$", ("remove_permanent", "artifact")),
        (r"^return target enchantment to its owner's hand\.?$", ("remove_permanent", "enchantment")),
        (r"^return target land to its owner's hand\.?$", ("remove_permanent", "land")),
    ]
    for pattern, result in patterns:
        if re.match(pattern, text):
            return result
    return None


def counter_target_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, str]] = [
        (r"^counter target artifact or enchantment spell\.?$", "artifact_or_enchantment_spell"),
        (r"^counter target instant or sorcery spell\.?$", "instant_or_sorcery_spell"),
        (r"^counter target noncreature spell\.?$", "noncreature_spell"),
        (r"^counter target creature spell\.?$", "creature_spell"),
        (r"^counter target artifact spell\.?$", "artifact_spell"),
        (r"^counter target enchantment spell\.?$", "enchantment_spell"),
        (r"^counter target instant spell\.?$", "instant_spell"),
        (r"^counter target sorcery spell\.?$", "sorcery_spell"),
        (r"^counter target blue spell\.?$", "blue_spell"),
        (r"^counter target white spell\.?$", "white_spell"),
        (r"^counter target black spell\.?$", "black_spell"),
        (r"^counter target red spell\.?$", "red_spell"),
        (r"^counter target green spell\.?$", "green_spell"),
        (r"^counter target spell\.?$", "spell"),
    ]
    for pattern, target in patterns:
        if re.match(pattern, text):
            return target
    return None


def counter_target_constraints_for(target: str) -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "stack", "stack_object": "spell"}
    if target == "artifact_or_enchantment_spell":
        constraints["card_types"] = ["artifact", "enchantment"]
    elif target == "instant_or_sorcery_spell":
        constraints["spell_types"] = ["instant", "sorcery"]
    elif target == "noncreature_spell":
        constraints["exclude_card_types"] = ["creature"]
    elif target in {"creature_spell", "artifact_spell", "enchantment_spell"}:
        constraints["card_types"] = [target.removesuffix("_spell")]
    elif target in {"instant_spell", "sorcery_spell"}:
        constraints["spell_types"] = [target.removesuffix("_spell")]
    elif target in {"blue_spell", "white_spell", "black_spell", "red_spell", "green_spell"}:
        color_symbols = {
            "blue_spell": "U",
            "white_spell": "W",
            "black_spell": "B",
            "red_spell": "R",
            "green_spell": "G",
        }
        constraints["spell_colors"] = [color_symbols[target]]
    return constraints


def recursion_target_constraints_for(target: str) -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "graveyard", "controller": "self"}
    if target == "any_card":
        constraints["scope"] = "any_card"
    elif target in {"creature", "artifact", "enchantment", "sorcery", "instant"}:
        constraints["card_types"] = [target]
    elif target == "instant_or_sorcery":
        constraints["card_types"] = ["instant", "sorcery"]
    elif target == "artifact_or_enchantment":
        constraints["card_types"] = ["artifact", "enchantment"]
    elif target == "permanent":
        constraints["card_types"] = ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"]
    else:
        constraints["target"] = target
    return constraints


def recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> tuple[str, int, bool] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, tuple[str, int, bool]]] = [
        (
            r"^return target instant or sorcery card from your graveyard to your hand\.?$",
            ("instant_or_sorcery", 1, False),
        ),
        (
            r"^return target artifact or enchantment card from your graveyard to your hand\.?$",
            ("artifact_or_enchantment", 1, False),
        ),
        (
            r"^return target permanent card from your graveyard to your hand\.?$",
            ("permanent", 1, False),
        ),
        (
            r"^return target creature card from your graveyard to your hand\.?$",
            ("creature", 1, False),
        ),
        (
            r"^return target artifact card from your graveyard to your hand\.?$",
            ("artifact", 1, False),
        ),
        (
            r"^return target enchantment card from your graveyard to your hand\.?$",
            ("enchantment", 1, False),
        ),
        (
            r"^return target instant card from your graveyard to your hand\.?$",
            ("instant", 1, False),
        ),
        (
            r"^return target sorcery card from your graveyard to your hand\.?$",
            ("sorcery", 1, False),
        ),
        (
            r"^return target card from your graveyard to your hand\.?$",
            ("any_card", 1, False),
        ),
        (
            r"^return up to two target creature cards from your graveyard to your hand\.?$",
            ("creature", 2, True),
        ),
        (
            r"^return up to two target permanent cards from your graveyard to your hand\.?$",
            ("permanent", 2, True),
        ),
    ]
    for pattern, result in patterns:
        if re.match(pattern, text):
            return result
    return None


def destroy_all_types_from_oracle(metadata: dict[str, Any]) -> list[str] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, list[str]]] = [
        (r"^destroy all creatures(?:\. they can't be regenerated\.)?\.?$", ["creature"]),
        (r"^destroy all artifacts\.?$", ["artifact"]),
        (r"^destroy all enchantments\.?$", ["enchantment"]),
        (r"^destroy all artifacts and enchantments\.?$", ["artifact", "enchantment"]),
        (r"^destroy all creatures and lands\.?$", ["creature", "land"]),
        (
            r"^destroy all artifacts, creatures, and enchantments\.?$",
            ["artifact", "creature", "enchantment"],
        ),
    ]
    for pattern, card_types in patterns:
        if re.match(pattern, text):
            return card_types
    return None


def damage_all_scope_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if re.match(r"^.+ deals? \d+ damage to each creature\.?$", text):
        return "each_creature"
    if re.match(r"^.+ deals? \d+ damage to each creature and each planeswalker\.?$", text):
        return "each_creature_and_planeswalker"
    if re.match(r"^.+ deals? \d+ damage to each creature your opponents control\.?$", text):
        return "each_creature_opponents_control"
    return None


COUNTER_WORD_NUMBERS = {
    "a": 1,
    "an": 1,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
}


def counter_count_from_text(value: str) -> int | None:
    token = str(value or "").strip().lower()
    if token.isdigit():
        return int(token)
    return COUNTER_WORD_NUMBERS.get(token)


def fixed_counter_target_from_source(source: str) -> tuple[str, int] | None:
    matches = re.findall(
        r"AddCountersTargetEffect\s*\(\s*CounterType\.(P1P1|M1M1)\.createInstance\s*\(\s*(\d*)\s*\)",
        source or "",
    )
    if len(matches) != 1:
        return None
    if len(re.findall(r"\.addTarget\s*\(\s*new\s+TargetCreaturePermanent\s*\(", source or "")) != 1:
        return None
    if not re.search(r"\.addTarget\s*\(\s*new\s+TargetCreaturePermanent\s*\(\s*\)\s*\)", source or ""):
        return None
    counter_class, raw_count = matches[0]
    counter_type = "+1/+1" if counter_class == "P1P1" else "-1/-1"
    return counter_type, int(raw_count or "1")


def fixed_counter_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, int] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^put (a|an|one|two|three|four|five|six|seven|eight|nine|ten|\d+) "
        r"(\+1/\+1|-1/-1) counters? on target creature\.?$",
        text,
    )
    if not match:
        return None
    count = counter_count_from_text(match.group(1))
    if count is None or count <= 0:
        return None
    return match.group(2), count


def fixed_boost_target_from_source(source: str) -> tuple[int, int] | None:
    matches = re.findall(
        r"new\s+BoostTargetEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*"
        r"(?:,\s*Duration\.EndOfTurn\s*)?\)",
        source or "",
    )
    if len(matches) != 1:
        return None
    if len(re.findall(r"new\s+TargetCreaturePermanent\s*\(", source or "")) != 1:
        return None
    if not re.search(r"new\s+TargetCreaturePermanent\s*\(\s*\)", source or ""):
        return None
    if "TargetPointer" in (source or "") or ".setTargetPointer" in (source or ""):
        return None
    return int(matches[0][0]), int(matches[0][1])


def strip_leading_parenthetical_reminders(text: str) -> str:
    cleaned = str(text or "").strip()
    while True:
        match = re.match(r"^\([^)]*\)\s*", cleaned)
        if not match:
            return cleaned
        cleaned = cleaned[match.end() :].strip()


def signed_int_from_oracle(value: str) -> int | None:
    token = str(value or "").strip()
    if not re.fullmatch(r"[+-]?\d+", token):
        return None
    return int(token)


def fixed_boost_target_from_oracle(metadata: dict[str, Any]) -> tuple[int, int] | None:
    text = strip_leading_parenthetical_reminders(oracle_text(metadata))
    match = re.match(
        r"^target creature gets ([+-]?\d+)/([+-]?\d+) until end of turn\.?$",
        text,
    )
    if not match:
        return None
    power = signed_int_from_oracle(match.group(1))
    toughness = signed_int_from_oracle(match.group(2))
    if power is None or toughness is None:
        return None
    return power, toughness


def is_creature_metadata(metadata: dict[str, Any]) -> bool:
    return "creature" in str(metadata.get("type_line") or "").lower()


def is_static_keyword_creature_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    return (
        bool(abilities)
        and not effect_classes(row)
        and not (row.get("xmage_signals") or [])
        and abilities.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
    )


def is_creature_etb_life_gain_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != LIFE_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"GainLifeEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []).issubset({"triggered_ability"})
    )


def keywords_from_ability_classes(row: dict[str, Any]) -> set[str]:
    return {
        STATIC_SELF_KEYWORD_ABILITY_CLASSES[ability]
        for ability in ability_classes(row)
        if ability in STATIC_SELF_KEYWORD_ABILITY_CLASSES
    }


def normalize_keyword_phrase(value: str) -> str:
    return re.sub(r"\s+", "_", str(value or "").strip().lower())


def ordered_keywords(keywords: set[str]) -> list[str]:
    return [keyword for keyword in STATIC_SELF_KEYWORD_ORDER if keyword in keywords]


def static_keywords_from_oracle(metadata: dict[str, Any]) -> set[str] | None:
    raw = str(metadata.get("oracle_text") or "").strip()
    if not raw:
        return None
    allowed = set(STATIC_SELF_KEYWORD_ABILITY_CLASSES.values())
    keywords: set[str] = set()
    for line in raw.splitlines():
        line = re.sub(r"\([^)]*\)", "", line).strip().rstrip(".")
        if not line:
            if keywords:
                break
            continue
        parts = [
            normalize_keyword_phrase(part)
            for part in re.split(r"[,;]", line)
            if str(part or "").strip()
        ]
        if not parts:
            if keywords:
                break
            continue
        if any(part not in allowed for part in parts):
            break
        keywords.update(parts)
    return keywords or None


def damage_target_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if "any target" in text:
        return "any_target"
    if re.search(r"target opponent\b", text):
        return "opponent"
    if re.search(r"target player\b", text):
        return "player"
    if re.search(r"target creature or planeswalker\b", text):
        return "creature_or_planeswalker"
    if re.search(r"target creature\b", text):
        return "creature"
    return None


def life_gain_amount_from_oracle(metadata: dict[str, Any]) -> int | None:
    match = re.match(r"^you gain (\d+) life\.?$", oracle_text(metadata))
    if not match:
        return None
    return int(match.group(1))


def etb_life_gain_amount_from_oracle(metadata: dict[str, Any]) -> int | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip()
    match = re.search(
        r"(?:when|whenever) [^.]* enters(?: the battlefield)?[, ]+you gain (\d+) life(?:\.|$)",
        text,
    )
    if not match:
        return None
    return int(match.group(1))


def simple_mana_source_from_oracle(metadata: dict[str, Any]) -> tuple[str, int] | None:
    text = oracle_text(metadata)
    if text == "{t}: add one mana of any color.":
        return "WUBRG", 1
    match = re.match(r"^\{t\}: add \{([wubrgc])\}\.?$", text)
    if match:
        return match.group(1).upper(), 1
    match = re.match(r"^\{t\}: add \{([wubrgc])\} or \{([wubrgc])\}\.?$", text)
    if match:
        produced = "".join(dict.fromkeys([match.group(1).upper(), match.group(2).upper()]))
        return produced, 1
    return None


def target_constraints_for(target: str) -> dict[str, Any]:
    if target == "any_target":
        return {"scope": "any_target"}
    if target == "creature":
        return {"card_types": ["creature"]}
    if target == "creature_or_planeswalker":
        return {"card_types": ["creature", "planeswalker"]}
    if target == "player":
        return {"scope": "player"}
    if target == "opponent":
        return {"scope": "opponent"}
    if target in {"artifact", "enchantment", "land", "permanent", "nonland_permanent"}:
        return {"card_types": [target]}
    if target == "artifact_or_enchantment":
        return {"card_types": ["artifact", "enchantment"]}
    if target == "creature_or_enchantment":
        return {"card_types": ["creature", "enchantment"]}
    if target == "creature_enchantment_or_planeswalker":
        return {"card_types": ["creature", "enchantment", "planeswalker"]}
    return {"target": target}


def proposal_notes(row: dict[str, Any], scope: str) -> str:
    scope_kind = "instant/sorcery spell"
    if str(row.get("adapter_work_unit") or "") in RAMP_UNITS:
        scope_kind = "activated mana-source permanent"
    return (
        "XMage authoritative exact-scope split: local class "
        f"{row.get('xmage_class')} translated into ManaLoom runtime scope {scope}. "
        "This row is package-ready only because the source signature is a narrow "
        f"{scope_kind} with focused runtime coverage."
    )


def build_proposal(
    row: dict[str, Any],
    metadata: dict[str, Any],
    effect_json: dict[str, Any],
    *,
    family_id: str,
) -> dict[str, Any]:
    normalized_name = normalize_name(str(metadata.get("name") or row.get("normalized_name") or row.get("card_name") or ""))
    card_name = str(metadata.get("name") or row.get("card_name") or "")
    deck_role_json = deck_role_from_effect(effect_json)
    rule = {"effect_json": effect_json, "deck_role_json": deck_role_json}
    logical_key = logical_rule_key(rule)
    return {
        "card_id": str(row.get("card_id") or ""),
        "card_name": card_name,
        "normalized_name": normalized_name,
        "family_id": family_id,
        "effect": effect_json.get("effect"),
        "battle_model_scope": effect_json.get("battle_model_scope"),
        "promotion_lane": "batch_metadata_candidate_requires_pg_precheck",
        "proposal_status": "batch_pg_candidate_after_precheck",
        "safe_for_batch_pg_package": True,
        "shadow_handling": "deprecate_nonmatching_rows",
        "oracle_hash": str(metadata.get("oracle_hash") or md5_text(str(metadata.get("oracle_text") or ""))),
        "oracle_hash_source": "postgres.cards.oracle_text_md5",
        "logical_rule_key": logical_key,
        "effect_json": effect_json,
        "deck_role_json": deck_role_json,
        "review_status": "verified",
        "execution_status": "auto",
        "source": "curated",
        "confidence": 0.96,
        "notes": proposal_notes(row, str(effect_json.get("battle_model_scope") or "")),
        "xmage_class": row.get("xmage_class"),
        "xmage_path": row.get("xmage_path"),
        "adapter_work_unit": row.get("adapter_work_unit"),
    }


def split_row(
    row: dict[str, Any],
    metadata: dict[str, Any],
    *,
    source_text: str,
) -> tuple[dict[str, Any] | None, str]:
    unit = str(row.get("adapter_work_unit") or "")
    keyword_creature_unit = is_static_keyword_creature_unit(row)
    etb_life_gain_creature_unit = is_creature_etb_life_gain_unit(row)
    if unit not in SUPPORTED_UNITS and not keyword_creature_unit and not etb_life_gain_creature_unit:
        return None, "unsupported_adapter_work_unit"
    if not metadata:
        return None, "postgres_card_metadata_missing"
    if not str(metadata.get("oracle_text") or "").strip():
        return None, "oracle_text_missing"

    if unit in SPELL_UNITS and not etb_life_gain_creature_unit:
        if not is_spell(metadata):
            return None, "not_instant_or_sorcery_spell"
        if ability_kind(row) != "one_shot":
            return None, "not_one_shot_spell_ability"
        if has_additional_cost(source_text) or "additional cost" in oracle_text(metadata):
            return None, "additional_cost_detected"

    flags = spell_flags(metadata)
    classes = effect_classes(row)

    if keyword_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "static_keyword_not_creature"
        keywords = keywords_from_ability_classes(row)
        oracle_keywords = static_keywords_from_oracle(metadata)
        if not keywords:
            return None, "static_keyword_ability_not_supported"
        if oracle_keywords is None:
            return None, "static_keyword_oracle_not_exact"
        if keywords != oracle_keywords:
            return None, "static_keyword_oracle_mismatch"
        keyword_list = ordered_keywords(keywords)
        effect_json = {
            "effect": "creature",
            "battle_model_scope": STATIC_KEYWORD_CREATURE_SCOPE,
            "keywords": keyword_list,
            "_keywords_are_self": True,
            "xmage_ability_classes": sorted(ability_classes(row)),
        }
        for keyword in keyword_list:
            effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_static_self_combat_keyword_creature",
        ), "selected_exact_scope"

    if etb_life_gain_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_life_gain_not_creature"
        amount = etb_life_gain_amount_from_oracle(metadata)
        constructor_amount = java_constructor_int(source_text, "GainLifeEffect")
        if amount is None or amount <= 0:
            return None, "etb_life_gain_amount_not_fixed"
        if constructor_amount is None:
            return None, "etb_life_gain_amount_source_not_fixed"
        if constructor_amount != amount:
            return None, "etb_life_gain_amount_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_LIFE_GAIN_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_life_gain_amount": amount,
            "xmage_effect_class": "GainLifeEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_gain_life",
        ), "selected_exact_scope"

    if unit == DRAW_UNIT:
        if classes != {"DrawCardSourceControllerEffect"}:
            return None, "draw_effect_class_not_pure"
        count = java_constructor_int(source_text, "DrawCardSourceControllerEffect", default=1)
        if count is None or count <= 0:
            return None, "draw_count_missing"
        effect_json = {
            "effect": "draw_cards",
            "battle_model_scope": DRAW_SCOPE,
            "count": count,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_draw_spell"), "selected_exact_scope"

    if unit == DAMAGE_UNIT:
        if classes != {"DamageTargetEffect"}:
            return None, "damage_effect_class_not_pure"
        amount = java_constructor_int(source_text, "DamageTargetEffect")
        if amount is None or amount <= 0:
            return None, "damage_amount_not_fixed"
        target = damage_target_from_oracle(metadata)
        if target is None:
            return None, "damage_target_not_supported"
        effect_json = {
            "effect": "direct_damage",
            "battle_model_scope": DAMAGE_SCOPE,
            "amount": amount,
            "damage": amount,
            "target": target,
            "target_constraints": target_constraints_for(target),
            "xmage_effect_class": "DamageTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_damage_spell"), "selected_exact_scope"

    if unit == DESTROY_UNIT:
        if classes != {"DestroyTargetEffect"}:
            return None, "destroy_effect_class_not_pure"
        target = destroy_target_from_oracle(metadata)
        if target is None:
            return None, "destroy_target_not_supported"
        effect, target_type = target
        effect_json = {
            "effect": effect,
            "battle_model_scope": DESTROY_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "xmage_effect_class": "DestroyTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_destroy_target_spell"), "selected_exact_scope"

    if unit == LIFE_UNIT:
        if classes != {"GainLifeEffect"}:
            return None, "life_gain_effect_class_not_pure"
        if has_oracle_complexity(metadata):
            return None, "life_gain_oracle_not_simple"
        amount = life_gain_amount_from_oracle(metadata)
        constructor_amount = java_constructor_int(source_text, "GainLifeEffect")
        if amount is None or amount <= 0:
            return None, "life_gain_amount_not_fixed"
        if constructor_amount is not None and constructor_amount != amount:
            return None, "life_gain_amount_source_oracle_mismatch"
        effect_json = {
            "effect": "life_total_change",
            "battle_model_scope": LIFE_SCOPE,
            "life_gain_amount": amount,
            "target": "self",
            "xmage_effect_class": "GainLifeEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_life_gain_spell"), "selected_exact_scope"

    if unit == EXILE_UNIT:
        if classes != {"ExileTargetEffect"}:
            return None, "exile_effect_class_not_pure"
        if has_oracle_complexity(metadata):
            return None, "exile_oracle_not_simple"
        target = exile_target_from_oracle(metadata)
        if target is None:
            return None, "exile_target_not_supported"
        effect, target_type = target
        effect_json = {
            "effect": effect,
            "battle_model_scope": EXILE_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints_for(target_type),
            "destination": "exile",
            "xmage_effect_class": "ExileTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_exile_target_spell"), "selected_exact_scope"

    if unit == COUNTER_UNIT:
        if classes != {"CounterTargetEffect"}:
            return None, "counter_effect_class_not_pure"
        if ability_classes(row):
            return None, "counter_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "counter_oracle_not_simple"
        target = counter_target_from_oracle(metadata)
        if target is None:
            return None, "counter_target_not_supported"
        effect_json = {
            "effect": "counter",
            "battle_model_scope": COUNTER_SCOPE,
            "target": target,
            "target_constraints": counter_target_constraints_for(target),
            "xmage_effect_class": "CounterTargetEffect",
            **flags,
        }
        if target == "blue_spell":
            effect_json["requires_blue_target"] = True
        return build_proposal(row, metadata, effect_json, family_id="xmage_counter_target_spell"), "selected_exact_scope"

    if unit == BOUNCE_UNIT:
        if classes != {"ReturnToHandTargetEffect"}:
            return None, "bounce_effect_class_not_pure"
        if ability_classes(row):
            return None, "bounce_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "bounce_oracle_not_simple"
        target = bounce_target_from_oracle(metadata)
        if target is None:
            return None, "bounce_target_not_supported"
        effect, target_type = target
        effect_json = {
            "effect": effect,
            "battle_model_scope": BOUNCE_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints_for(target_type),
            "destination": "hand",
            "xmage_effect_class": "ReturnToHandTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_return_target_to_hand_spell"), "selected_exact_scope"

    if unit == RECURSION_UNIT:
        if classes != {"ReturnFromGraveyardToHandTargetEffect"}:
            return None, "recursion_effect_class_not_pure"
        if ability_classes(row):
            return None, "recursion_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "recursion_oracle_not_simple"
        target = recursion_to_hand_from_oracle(metadata)
        if target is None:
            return None, "recursion_target_not_supported"
        target_type, count, up_to = target
        effect_json = {
            "effect": "recursion",
            "battle_model_scope": RECURSION_SCOPE,
            "target": target_type,
            "target_constraints": recursion_target_constraints_for(target_type),
            "count": count,
            "destination": "hand",
            "target_controller": "self",
            "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
            **flags,
        }
        if up_to:
            effect_json["up_to_count"] = True
        return build_proposal(row, metadata, effect_json, family_id="xmage_graveyard_to_hand_spell"), "selected_exact_scope"

    if unit == BOARD_WIPE_UNIT:
        if ability_classes(row):
            return None, "board_wipe_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "board_wipe_oracle_not_simple"
        if classes == {"DestroyAllEffect"}:
            destroy_card_types = destroy_all_types_from_oracle(metadata)
            if destroy_card_types is None:
                return None, "board_wipe_destroy_scope_not_supported"
            effect_json = {
                "effect": "board_wipe",
                "battle_model_scope": BOARD_WIPE_SCOPE,
                "destroy_card_types": destroy_card_types,
                "destination": "graveyard",
                "xmage_effect_class": "DestroyAllEffect",
                **flags,
            }
            return build_proposal(row, metadata, effect_json, family_id="xmage_destroy_all_spell"), "selected_exact_scope"
        if classes == {"DamageAllEffect"}:
            amount = java_constructor_int(source_text, "DamageAllEffect")
            if amount is None or amount <= 0:
                return None, "board_wipe_damage_amount_not_fixed"
            damage_scope = damage_all_scope_from_oracle(metadata)
            if damage_scope is None:
                return None, "board_wipe_damage_scope_not_supported"
            effect_json = {
                "effect": "damage_wipe",
                "battle_model_scope": DAMAGE_WIPE_SCOPE,
                "amount": amount,
                "damage": amount,
                "damage_scope": damage_scope,
                "xmage_effect_class": "DamageAllEffect",
                **flags,
            }
            return build_proposal(row, metadata, effect_json, family_id="xmage_damage_all_spell"), "selected_exact_scope"
        return None, "board_wipe_effect_class_not_supported"

    if unit == ADD_COUNTERS_TARGET_UNIT:
        if classes != {"AddCountersTargetEffect"}:
            return None, "add_counters_effect_class_not_pure"
        if ability_classes(row):
            return None, "add_counters_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "add_counters_oracle_not_simple"
        source_counter = fixed_counter_target_from_source(source_text)
        if source_counter is None:
            return None, "add_counters_counter_not_fixed"
        oracle_counter = fixed_counter_target_from_oracle(metadata)
        if oracle_counter is None:
            return None, "add_counters_target_not_supported"
        if source_counter != oracle_counter:
            return None, "add_counters_source_oracle_mismatch"
        counter_type, count = oracle_counter
        effect_json = {
            "effect": "add_counters",
            "battle_model_scope": ADD_COUNTERS_TARGET_SCOPE,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": counter_type,
            "counter_count": count,
            "count": count,
            "xmage_effect_class": "AddCountersTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_add_counters_target_creature_spell"), "selected_exact_scope"

    if unit == BOOST_TARGET_UNIT:
        if classes != {"BoostTargetEffect"}:
            return None, "boost_target_effect_class_not_pure"
        if ability_classes(row):
            return None, "boost_target_ability_class_not_simple"
        source_boost = fixed_boost_target_from_source(source_text)
        if source_boost is None:
            return None, "boost_target_source_not_single_fixed"
        oracle_boost = fixed_boost_target_from_oracle(metadata)
        if oracle_boost is None:
            return None, "boost_target_oracle_not_exact_fixed"
        if source_boost != oracle_boost:
            return None, "boost_target_source_oracle_mismatch"
        power_delta, toughness_delta = oracle_boost
        effect_json = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": BOOST_TARGET_SCOPE,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "power_delta": power_delta,
            "toughness_delta": toughness_delta,
            "power_boost": power_delta,
            "toughness_boost": toughness_delta,
            "duration": "until_end_of_turn",
            "xmage_effect_class": "BoostTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_boost_target_creature_until_eot_spell"), "selected_exact_scope"

    if unit in RAMP_UNITS:
        if is_spell(metadata):
            return None, "mana_source_spell_not_supported"
        mana_ability_classes = ability_classes(row)
        if mana_ability_classes.intersection(UNSAFE_MANA_ABILITY_CLASSES):
            return None, "mana_source_unsafe_ability_class"
        if not mana_ability_classes.intersection(SAFE_MANA_ABILITY_CLASSES):
            return None, "mana_source_safe_ability_missing"
        if classes - {"BasicManaEffect", "AddManaOfAnyColorEffect"}:
            return None, "mana_source_effect_class_not_simple"
        mana_source = simple_mana_source_from_oracle(metadata)
        if mana_source is None:
            return None, "mana_source_oracle_not_simple"
        produces, amount = mana_source
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_type = "creature" if "creature" in type_line else "artifact" if "artifact" in type_line else "permanent"
        effect_json = {
            "effect": "ramp_permanent",
            "battle_model_scope": MANA_SCOPE,
            "is_mana_source": True,
            "mana_produced": amount,
            "produces": produces,
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": permanent_type,
            "xmage_mana_ability_classes": sorted(mana_ability_classes),
            "xmage_effect_classes": sorted(classes),
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_simple_mana_source_permanent"), "selected_exact_scope"

    return None, "unsupported_adapter_work_unit"


def build_exact_split_report(
    queue_payload: dict[str, Any],
    *,
    card_metadata_by_id: dict[str, dict[str, Any]],
    source_reader: Callable[[dict[str, Any]], str] = default_source_reader,
    max_cards: int = 0,
) -> dict[str, Any]:
    proposals: list[dict[str, Any]] = []
    blocked_reason_counts: Counter[str] = Counter()
    blocked_samples: dict[str, list[str]] = {}
    considered = 0

    for row in queue_payload.get("queue") or []:
        if str(row.get("translation_lane") or "") != "xmage_authoritative_adapter_required":
            continue
        if str(row.get("adapter_work_unit") or "") not in SUPPORTED_UNITS and not is_static_keyword_creature_unit(row):
            continue
        considered += 1
        metadata = card_metadata_by_id.get(str(row.get("card_id") or ""), {})
        proposal, reason = split_row(row, metadata, source_text=source_reader(row))
        if proposal is None:
            blocked_reason_counts[reason] += 1
            blocked_samples.setdefault(reason, [])
            if len(blocked_samples[reason]) < 12:
                blocked_samples[reason].append(str(row.get("card_name") or ""))
            continue
        proposals.append(proposal)
        if max_cards > 0 and len(proposals) >= max_cards:
            break

    family_counts = Counter(str(proposal.get("family_id") or "") for proposal in proposals)
    scope_counts = Counter(str(proposal.get("battle_model_scope") or "") for proposal in proposals)
    unit_counts = Counter(str(proposal.get("adapter_work_unit") or "") for proposal in proposals)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "queue_generated_at": queue_payload.get("generated_at"),
            "queue_scope": (queue_payload.get("method") or {}).get("scope"),
            "input_queue_status": queue_payload.get("status"),
        },
        "method": {
            "xmage_is_authoritative_for_resolved_sources": True,
            "promotion_boundary": "exact runtime-backed spell/permanent scopes only",
            "supported_adapter_work_units": sorted(SUPPORTED_UNITS),
            "supported_dynamic_adapter_work_units": [
                "no-effect/no-signal static self keyword creature rows without ProtectionAbility or WardAbility",
                "life_gain::xmage_life_gain_variant_review_v1 rows with GainLifeEffect and EntersBattlefieldTriggeredAbility plus only static self keywords",
            ],
            "blocked_generic_review_scopes_from_pg": True,
            "max_cards": max_cards,
        },
        "summary": {
            "considered_supported_work_unit_rows": considered,
            "proposal_count": len(proposals),
            "safe_for_batch_pg_package_count": len(proposals),
            "proposal_status_counts": {"batch_pg_candidate_after_precheck": len(proposals)},
            "family_counts": dict(sorted(family_counts.items())),
            "scope_counts": dict(sorted(scope_counts.items())),
            "adapter_work_unit_counts": dict(sorted(unit_counts.items())),
            "blocked_reason_counts": dict(sorted(blocked_reason_counts.items())),
        },
        "blocked_samples": blocked_samples,
        "proposals": proposals,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Authoritative Exact Scope Split",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        "- Mutations performed: `[]`",
        "",
        "## Summary",
        "",
        f"`{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "## Selected Proposals",
        "",
        "| Card | Family | Scope | Effect | Logical rule key |",
        "| --- | --- | --- | --- | --- |",
    ]
    for proposal in report.get("proposals", [])[:300]:
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{proposal.get('card_name')}`",
                    f"`{proposal.get('family_id')}`",
                    f"`{proposal.get('battle_model_scope')}`",
                    f"`{proposal.get('effect')}`",
                    f"`{proposal.get('logical_rule_key')}`",
                ]
            )
            + " |"
        )
    if len(report.get("proposals", [])) > 300:
        lines.append(f"| ... | ... | ... | ... | `{len(report['proposals']) - 300} more` |")
    lines.extend(["", "## Blocked Samples", ""])
    for reason, samples in sorted((report.get("blocked_samples") or {}).items()):
        lines.append(f"- `{reason}`: `{json.dumps(samples, ensure_ascii=True)}`")
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_prefix: Path) -> tuple[Path, Path]:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = Path(f"{output_prefix}.json")
    md_path = Path(f"{output_prefix}.md")
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(markdown_report(report), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", required=True, help="XMage authoritative queue JSON")
    parser.add_argument("--output-prefix", help="Output path prefix")
    parser.add_argument("--max-cards", type=int, default=0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    queue_payload = load_json(Path(args.queue))
    report = build_exact_split_report(
        queue_payload,
        card_metadata_by_id=fetch_card_metadata_by_id(),
        max_cards=args.max_cards,
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_prefix = Path(
        args.output_prefix
        or REPORT_DIR / f"xmage_authoritative_exact_scope_split_{timestamp}"
    )
    json_path, md_path = write_report(report, output_prefix)
    print(f"json_report={json_path}")
    print(f"md_report={md_path}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
