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
DRAW_ENGINE_UNIT = "draw_engine::xmage_draw_card_variant_review_v1"
DAMAGE_UNIT = "direct_damage::targeted_damage_variant_v1"
DESTROY_UNIT = "removal_destroy::targeted_destroy_variant_v1"
LIFE_UNIT = "life_gain::xmage_life_gain_variant_review_v1"
EXILE_UNIT = "removal_exile::targeted_exile_variant_v1"
RAMP_ARTIFACT_UNIT = "ramp_permanent::xmage_artifact_mana_source_variant_review_v1"
RAMP_CREATURE_UNIT = "ramp_permanent::xmage_creature_mana_source_variant_review_v1"
COUNTER_UNIT = "counter_spell::counter_target_stack_object_variant_v1"
BOUNCE_UNIT = "bounce::targeted_return_to_hand_variant_v1"
RECURSION_UNIT = "recursion::xmage_graveyard_return_variant_review_v1"
TUTOR_UNIT = "tutor::xmage_library_search_variant_review_v1"
BOARD_WIPE_UNIT = "board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1"
ADD_COUNTERS_TARGET_UNIT = "add_counters::targeted_add_counters_variant_v1"
BOOST_TARGET_UNIT = (
    "xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::"
    "no_condition_class::targeting"
)
BOOST_CONTROLLED_SPELL_UNIT = (
    "xmage_signature::BoostControlledEffect::no_ability_class::"
    "no_target_class::no_condition_class::no_signal"
)
SELF_BOOST_ACTIVATED_UNIT = (
    "xmage_signature::BoostSourceEffect::SimpleActivatedAbility::"
    "no_target_class::no_condition_class::activated_ability"
)
TARGET_BOOST_ACTIVATED_UNIT = (
    "xmage_signature::BoostTargetEffect::SimpleActivatedAbility::"
    "TargetCreaturePermanent::no_condition_class::targeting,activated_ability"
)
STATIC_CONTROLLED_PT_UNIT = (
    "xmage_signature::BoostControlledEffect::SimpleStaticAbility::"
    "no_target_class::no_condition_class::static_ability"
)
BOOST_KEYWORD_UNIT = "grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1"
TOKEN_SPELL_UNIT = (
    "token_maker::xmage_signature::CreateTokenEffect::no_ability_class::"
    "no_target_class::no_condition_class::token"
)
ETB_TOKEN_CREATURE_UNIT = (
    "token_maker::xmage_signature::CreateTokenEffect::EntersBattlefieldTriggeredAbility::"
    "no_target_class::no_condition_class::token,triggered_ability"
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
    TUTOR_UNIT,
    BOARD_WIPE_UNIT,
    ADD_COUNTERS_TARGET_UNIT,
    BOOST_TARGET_UNIT,
    BOOST_CONTROLLED_SPELL_UNIT,
    STATIC_CONTROLLED_PT_UNIT,
    TOKEN_SPELL_UNIT,
}

DRAW_SCOPE = "xmage_fixed_source_controller_draw_spell_v1"
DAMAGE_SCOPE = "xmage_fixed_damage_target_spell_v1"
DAMAGE_GAIN_LIFE_SCOPE = "xmage_fixed_damage_target_and_controller_gain_life_spell_v1"
DESTROY_GAIN_LIFE_SCOPE = "xmage_destroy_target_and_controller_gain_life_spell_v1"
CREATURE_TAP_DAMAGE_SCOPE = "xmage_creature_tap_fixed_damage_target_activated_v1"
TAP_DAMAGE_ACTIVATED_SCOPE = "xmage_tap_fixed_damage_target_activated_ability_v1"
PERMANENT_ACTIVATED_DAMAGE_SCOPE = "xmage_permanent_simple_activated_damage_v1"
PERMANENT_ACTIVATED_DESTROY_SCOPE = "xmage_permanent_simple_activated_destroy_target_v1"
PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE = "xmage_permanent_simple_activated_graveyard_to_hand_v1"
PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE = "xmage_permanent_simple_activated_graveyard_to_battlefield_v1"
PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE = "xmage_permanent_simple_activated_exile_graveyard_card_v1"
PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE = "xmage_permanent_simple_activated_life_gain_v1"
GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE = "xmage_graveyard_simple_activated_self_return_to_hand_v1"
GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE = (
    "xmage_graveyard_simple_activated_self_return_to_battlefield_v1"
)
DESTROY_SCOPE = "xmage_destroy_target_spell_v1"
LIFE_SCOPE = "xmage_fixed_controller_gain_life_spell_v1"
LIFE_GAIN_DRAW_SCOPE = "xmage_fixed_controller_gain_life_draw_card_spell_v1"
SCRY_SCOPE = "xmage_fixed_scry_spell_v1"
SCRY_DRAW_SCOPE = "xmage_fixed_scry_and_draw_cards_spell_v1"
DAMAGE_SCRY_SCOPE = "xmage_fixed_damage_target_and_scry_spell_v1"
DESTROY_SCRY_SCOPE = "xmage_destroy_target_and_scry_spell_v1"
EXILE_SCRY_SCOPE = "xmage_exile_target_and_scry_spell_v1"
BOUNCE_SCRY_SCOPE = "xmage_return_target_to_hand_and_scry_spell_v1"
DAMAGE_DRAW_SCOPE = "xmage_fixed_damage_target_and_draw_card_spell_v1"
BOOST_DRAW_SCOPE = "xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1"
DESTROY_DRAW_SCOPE = "xmage_destroy_target_and_draw_card_spell_v1"
BOUNCE_DRAW_SCOPE = "xmage_return_target_to_hand_and_draw_card_spell_v1"
EXILE_SCOPE = "xmage_exile_target_spell_v1"
MANA_SCOPE = "xmage_simple_tap_mana_source_permanent_v1"
COUNTER_SCOPE = "xmage_counter_target_spell_v1"
COUNTER_DRAW_SCOPE = "xmage_counter_target_and_draw_card_spell_v1"
BOUNCE_SCOPE = "xmage_return_target_to_hand_spell_v1"
RECURSION_SCOPE = "xmage_return_target_graveyard_card_to_hand_spell_v1"
RECURSION_MILL_RETURN_SCOPE = "xmage_mill_then_return_graveyard_card_to_hand_spell_v1"
RECURSION_BATTLEFIELD_SCOPE = "xmage_return_target_graveyard_card_to_battlefield_spell_v1"
RECURSION_BATTLEFIELD_ALL_SCOPE = "xmage_return_all_matching_graveyard_cards_to_battlefield_spell_v1"
GRAVEYARD_EXILE_SPELL_SCOPE = "xmage_exile_target_graveyard_card_spell_v1"
RECURSION_BATTLEFIELD_COUNTER_SCOPE = (
    "xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1"
)
GRAVEYARD_TO_LIBRARY_SPELL_SCOPE = "xmage_put_target_graveyard_card_on_library_spell_v1"
LIBRARY_PICK_SPELL_SCOPE = "xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1"
PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE = (
    "xmage_permanent_simple_activated_graveyard_to_library_v1"
)
TUTOR_BATTLEFIELD_SCOPE = "xmage_library_search_to_battlefield_spell_v1"
TUTOR_TOP_SCOPE = "xmage_library_search_to_library_top_spell_v1"
BOARD_WIPE_SCOPE = "xmage_destroy_all_matching_permanents_spell_v1"
DAMAGE_WIPE_SCOPE = "xmage_fixed_damage_all_matching_permanents_spell_v1"
ADD_COUNTERS_TARGET_SCOPE = "xmage_fixed_add_counters_target_creature_spell_v1"
BOOST_TARGET_SCOPE = "xmage_fixed_boost_target_creature_until_eot_spell_v1"
BOOST_CONTROLLED_SPELL_SCOPE = "xmage_fixed_boost_controlled_creatures_until_eot_spell_v1"
BOOST_KEYWORD_SCOPE = "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1"
SELF_BOOST_ACTIVATED_SCOPE = "xmage_permanent_simple_activated_self_boost_until_eot_v1"
TARGET_BOOST_ACTIVATED_SCOPE = "xmage_permanent_simple_activated_target_boost_until_eot_v1"
TARGET_KEYWORD_ACTIVATED_SCOPE = "xmage_permanent_simple_activated_target_keyword_until_eot_v1"
STATIC_KEYWORD_CREATURE_SCOPE = "xmage_static_self_combat_keyword_creature_v1"
STATIC_CONTROLLED_PT_SCOPE = "xmage_static_controlled_power_toughness_boost_v1"
STATIC_GRAVEYARD_COUNT_PT_SCOPE = "xmage_static_source_power_toughness_equal_graveyard_count_v1"
STATIC_GRAVEYARD_THRESHOLD_BOOST_SCOPE = "xmage_static_source_boost_if_graveyard_threshold_v1"
STATIC_GRAVEYARD_COUNT_BOOST_SCOPE = "xmage_static_source_boost_equal_graveyard_count_v1"
PERMANENT_ACTIVATED_DRAW_SCOPE = "xmage_permanent_simple_activated_draw_v1"
PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE = "xmage_permanent_simple_activated_draw_discard_v1"
SPELL_CAST_DRAW_ENGINE_SCOPE = "xmage_spell_cast_draw_engine_v1"
ETB_LIFE_GAIN_CREATURE_SCOPE = "xmage_creature_etb_gain_life_v1"
ETB_DRAW_CREATURE_SCOPE = "xmage_creature_etb_draw_cards_v1"
ETB_DAMAGE_CREATURE_SCOPE = "xmage_creature_etb_fixed_damage_target_v1"
ETB_DESTROY_CREATURE_SCOPE = "xmage_creature_etb_destroy_target_v1"
ETB_RECURSION_CREATURE_SCOPE = "xmage_creature_etb_return_graveyard_card_to_hand_v1"
ETB_MILL_RECURSION_CREATURE_SCOPE = "xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1"
ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE = "xmage_creature_etb_put_graveyard_card_on_library_v1"
ETB_LIBRARY_PICK_CREATURE_SCOPE = "xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1"
DIES_DRAW_CREATURE_SCOPE = "xmage_creature_dies_draw_cards_v1"
DIES_RECURSION_CREATURE_SCOPE = "xmage_creature_dies_return_graveyard_card_to_hand_v1"
TOKEN_SPELL_SCOPE = "xmage_fixed_create_creature_tokens_spell_v1"
ETB_TOKEN_CREATURE_SCOPE = "xmage_creature_etb_create_tokens_v1"
ETB_ADD_COUNTERS_CREATURE_SCOPE = "xmage_creature_etb_add_counters_target_creature_v1"

SPELL_UNITS = {
    DRAW_UNIT,
    DAMAGE_UNIT,
    DESTROY_UNIT,
    LIFE_UNIT,
    EXILE_UNIT,
    COUNTER_UNIT,
    BOUNCE_UNIT,
    RECURSION_UNIT,
    TUTOR_UNIT,
    BOARD_WIPE_UNIT,
    ADD_COUNTERS_TARGET_UNIT,
    BOOST_TARGET_UNIT,
    BOOST_CONTROLLED_SPELL_UNIT,
    TOKEN_SPELL_UNIT,
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

AUXILIARY_RECURSION_SPELL_ABILITY_CLASSES = {
    "FlashbackAbility",
    "CyclingAbility",
}

ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES = {
    "FlashbackAbility",
    "ForetellAbility",
}

NUMBER_WORDS = {
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

ALLOWED_TOKEN_ABILITY_KEYWORDS = {
    "DeathtouchAbility": "deathtouch",
    "DoubleStrikeAbility": "double_strike",
    "FirstStrikeAbility": "first_strike",
    "FlyingAbility": "flying",
    "HasteAbility": "haste",
    "HexproofAbility": "hexproof",
    "IndestructibleAbility": "indestructible",
    "LifelinkAbility": "lifelink",
    "MenaceAbility": "menace",
    "ReachAbility": "reach",
    "TrampleAbility": "trample",
    "VigilanceAbility": "vigilance",
}

TOKEN_DESCRIPTION_KEYWORDS = {
    "deathtouch": "deathtouch",
    "double strike": "double_strike",
    "first strike": "first_strike",
    "flying": "flying",
    "haste": "haste",
    "hexproof": "hexproof",
    "indestructible": "indestructible",
    "lifelink": "lifelink",
    "menace": "menace",
    "reach": "reach",
    "trample": "trample",
    "vigilance": "vigilance",
}

TOKEN_COLOR_SETTERS = {
    "White": "W",
    "Blue": "U",
    "Black": "B",
    "Red": "R",
    "Green": "G",
}

TOKEN_COLOR_WORDS = {
    "white": "W",
    "blue": "U",
    "black": "B",
    "red": "R",
    "green": "G",
}

UNSUPPORTED_TOKEN_DESCRIPTION_MARKERS = {
    "when ",
    "whenever ",
    "infect",
    "prowess",
    "toxic",
    "sacrifice",
    "mountainwalk",
    "banding",
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
TARGET_GRANT_KEYWORD_ABILITY_CLASSES = {
    key: value
    for key, value in STATIC_SELF_KEYWORD_ABILITY_CLASSES.items()
    if value
    in {
        "deathtouch",
        "double_strike",
        "first_strike",
        "flying",
        "haste",
        "hexproof",
        "indestructible",
        "lifelink",
        "menace",
        "reach",
        "trample",
        "vigilance",
    }
}
TARGET_GRANT_KEYWORD_ORACLE_WORDS = {
    "deathtouch": "deathtouch",
    "double strike": "double_strike",
    "first strike": "first_strike",
    "flying": "flying",
    "haste": "haste",
    "hexproof": "hexproof",
    "indestructible": "indestructible",
    "lifelink": "lifelink",
    "menace": "menace",
    "reach": "reach",
    "trample": "trample",
    "vigilance": "vigilance",
}


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


def java_constructor_int_or_noarg_default(
    source: str,
    class_name: str,
    *,
    noarg_default: int,
) -> int | None:
    amount = java_constructor_int(source, class_name)
    if amount is not None:
        return amount
    if re.search(rf"\b{re.escape(class_name)}\s*\(\s*\)", source or ""):
        return noarg_default
    return None


def has_additional_cost(source: str) -> bool:
    return bool(re.search(r"\.addCost\s*\(", source or ""))


def source_xmage_root(row: dict[str, Any]) -> Path | None:
    path = Path(str(row.get("xmage_path") or ""))
    parts = path.parts
    for marker in ("Mage.Sets", "Mage"):
        if marker in parts:
            index = parts.index(marker)
            if index > 0:
                return Path(*parts[:index])
    return None


def fixed_create_token_effect_from_source(source: str) -> tuple[str, int] | str:
    text = source or ""
    if len(re.findall(r"new\s+CreateTokenEffect\s*\(", text)) != 1:
        return "token_source_not_single_create_token_effect"
    if ".withAdditionalTokens" in text:
        return "token_source_additional_tokens_not_supported"
    if ".entersWithCounters" in text:
        return "token_source_counters_not_supported"
    if ".setText" in text:
        return "token_source_custom_text_not_supported"
    match = re.search(
        r"new\s+CreateTokenEffect\s*\(\s*new\s+(\w+)\s*\([^)]*\)\s*"
        r"(?:,\s*(\d+))?\s*\)",
        text,
        re.S,
    )
    if not match:
        return "token_source_create_token_not_fixed"
    token_class = match.group(1)
    count = int(match.group(2) or "1")
    if count <= 0:
        return "token_source_count_not_positive"
    return token_class, count


def token_class_source(row: dict[str, Any], source_text: str, token_class: str) -> str:
    if re.search(rf"\bclass\s+{re.escape(token_class)}\b", source_text or ""):
        return source_text
    root = source_xmage_root(row)
    if root is None:
        return ""
    direct = root / "Mage" / "src" / "main" / "java" / "mage" / "game" / "permanent" / "token" / f"{token_class}.java"
    if direct.is_file():
        return direct.read_text(encoding="utf-8", errors="replace")
    for base in (
        root / "Mage" / "src" / "main" / "java",
        root / "Mage.Sets" / "src" / "mage" / "cards",
    ):
        if not base.is_dir():
            continue
        for candidate in base.rglob(f"{token_class}.java"):
            return candidate.read_text(encoding="utf-8", errors="replace")
    return ""


def title_subtype(value: str) -> str:
    return " ".join(part.capitalize() for part in str(value or "").split("_") if part)


def token_colors_from_description(description: str) -> list[str]:
    lower = str(description or "").lower()
    if "colorless" in lower:
        return []
    return [
        symbol
        for color_word, symbol in TOKEN_COLOR_WORDS.items()
        if re.search(rf"\b{re.escape(color_word)}\b", lower)
    ]


def parse_simple_token_class(token_source: str, token_class: str) -> tuple[dict[str, Any], str | None]:
    if not token_source:
        return {}, "token_source_missing"
    if "TokenImpl" not in token_source:
        return {}, "token_source_not_token_impl"
    constructor_match = re.search(
        rf"public\s+{re.escape(token_class)}\s*\(\s*\)\s*\{{(?P<body>.*?)\n\s*\}}",
        token_source,
        re.S,
    )
    if not constructor_match:
        return {}, "token_noarg_constructor_missing"
    constructor_source = constructor_match.group("body")
    description_match = re.search(r'super\("([^"]+)",\s*"([^"]+)"\)', constructor_source)
    if not description_match:
        return {}, "token_literal_description_missing"
    token_name = description_match.group(1)
    description = description_match.group(2)
    lower_description = description.lower()
    if "creature token" not in lower_description:
        return {}, "token_description_not_creature_token"
    unsupported_markers = [
        marker
        for marker in sorted(UNSUPPORTED_TOKEN_DESCRIPTION_MARKERS)
        if marker in lower_description
    ]
    if unsupported_markers:
        return {}, "token_description_keyword_not_supported"
    description_keywords: list[str] = []
    with_match = re.search(r"\bwith (?P<keywords>.+)$", lower_description)
    if with_match:
        raw_keywords = with_match.group("keywords")
        keyword_parts = [
            part.strip().rstrip(".")
            for part in re.split(r",| and ", raw_keywords)
            if part.strip()
        ]
        for keyword_part in keyword_parts:
            normalized_keyword = TOKEN_DESCRIPTION_KEYWORDS.get(keyword_part)
            if normalized_keyword is None:
                return {}, "token_description_keyword_not_supported"
            description_keywords.append(normalized_keyword)
    power_match = re.search(r"power\s*=\s*new\s+MageInt\s*\(\s*(\d+)\s*\)", constructor_source)
    toughness_match = re.search(r"toughness\s*=\s*new\s+MageInt\s*\(\s*(\d+)\s*\)", constructor_source)
    if not power_match or not toughness_match:
        return {}, "token_power_toughness_not_fixed"
    ability_classes = set(re.findall(r"addAbility\s*\(\s*([A-Za-z]+Ability)", constructor_source))
    unsupported_abilities = ability_classes - set(ALLOWED_TOKEN_ABILITY_KEYWORDS)
    if unsupported_abilities:
        return {}, "token_ability_not_supported"
    colors = [
        symbol
        for color_name, symbol in TOKEN_COLOR_SETTERS.items()
        if re.search(rf"color\.set{color_name}\s*\(\s*true\s*\)", constructor_source)
    ]
    object_color_matches = re.findall(r"color\.setColor\s*\(\s*ObjectColor\.([A-Z]+)\s*\)", constructor_source)
    object_color_symbols = {
        "WHITE": "W",
        "BLUE": "U",
        "BLACK": "B",
        "RED": "R",
        "GREEN": "G",
    }
    for match in object_color_matches:
        symbol = object_color_symbols.get(match)
        if symbol and symbol not in colors:
            colors.append(symbol)
    if not colors:
        colors = token_colors_from_description(description)
    subtypes = [title_subtype(value) for value in re.findall(r"subtype\.add\s*\(\s*SubType\.([A-Z0-9_]+)\s*\)", constructor_source)]
    token_keywords = [
        keyword
        for ability_class, keyword in ALLOWED_TOKEN_ABILITY_KEYWORDS.items()
        if ability_class in ability_classes
    ]
    for keyword in description_keywords:
        if keyword not in token_keywords:
            token_keywords.append(keyword)
    artifact = bool(
        "artifact creature token" in lower_description
        or re.search(r"cardType\.add\s*\(\s*CardType\.ARTIFACT\s*\)", constructor_source)
    )
    token_data: dict[str, Any] = {
        "xmage_token_class": token_class,
        "token_name": token_name,
        "token_power": int(power_match.group(1)),
        "token_toughness": int(toughness_match.group(1)),
        "token_description": description,
    }
    if subtypes:
        token_data["token_subtype"] = " ".join(subtypes)
    if colors:
        token_data["token_colors"] = colors
    if token_keywords:
        token_data["token_keywords"] = token_keywords
    if "flying" in token_keywords:
        token_data["token_flying"] = True
    if "haste" in token_keywords:
        token_data["token_haste"] = True
    if artifact:
        token_data["artifact_tokens"] = True
    return token_data, None


def is_spell(metadata: dict[str, Any]) -> bool:
    type_line = str(metadata.get("type_line") or "").lower()
    return "instant" in type_line or "sorcery" in type_line


def is_permanent_metadata(metadata: dict[str, Any]) -> bool:
    type_line = str(metadata.get("type_line") or "").lower()
    return any(
        card_type in type_line
        for card_type in ("artifact", "creature", "enchantment", "planeswalker", "battle", "land")
    )


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
    restricted = restricted_battlefield_target_from_oracle(metadata, "destroy")
    if restricted is not None:
        return ("remove_creature" if restricted_target_base(restricted) == "creature" else "remove_permanent"), restricted
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


def simple_destroy_gain_life_from_source(source: str) -> tuple[str, int] | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    if len(re.findall(r"new\s+DestroyTargetEffect\s*\(\s*\)", text, re.S)) != 1:
        return None
    life_matches = re.findall(r"new\s+GainLifeEffect\s*\(\s*(\d+)\s*\)", text, re.S)
    if len(life_matches) != 1:
        return None
    target_classes = re.findall(r"new\s+(Target\w+)\s*\(", text)
    if len(target_classes) != 1:
        return None
    target_patterns = [
        (
            "artifact_or_enchantment",
            r"new\s+TargetPermanent\s*\(\s*StaticFilters\.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT\s*\)",
        ),
        (
            "artifact_or_creature",
            r"new\s+TargetPermanent\s*\(\s*StaticFilters\.FILTER_PERMANENT_ARTIFACT_OR_CREATURE\s*\)",
        ),
        ("artifact", r"new\s+TargetArtifactPermanent\s*\(\s*\)"),
        ("enchantment", r"new\s+TargetEnchantmentPermanent\s*\(\s*\)"),
        ("creature", r"new\s+TargetCreaturePermanent\s*\(\s*\)"),
        ("land", r"new\s+TargetLandPermanent\s*\(\s*\)"),
    ]
    matched_targets = [
        target
        for target, pattern in target_patterns
        if re.search(pattern, text, re.S)
    ]
    if len(matched_targets) != 1:
        return None
    return matched_targets[0], int(life_matches[0])


def simple_destroy_gain_life_from_oracle(metadata: dict[str, Any]) -> tuple[str, int] | None:
    text = oracle_text(metadata)
    target_patterns = [
        ("artifact_or_enchantment", r"artifact or enchantment"),
        ("artifact_or_creature", r"artifact or creature"),
        ("artifact", r"artifact"),
        ("enchantment", r"enchantment"),
        ("creature", r"creature"),
        ("land", r"land"),
    ]
    for target, target_phrase in target_patterns:
        match = re.match(
            rf"^destroy target {target_phrase}\. you gain (\d+) life\.?$",
            text,
        )
        if match:
            return target, int(match.group(1))
    return None


def fixed_destroy_draw_from_oracle(metadata: dict[str, Any]) -> tuple[str, str, int] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^(destroy target .+?)(\. it can't be regenerated)?\. (?:then )?draw a card\.?$",
        text,
    )
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group(1)}{match.group(2) or ''}."
    parsed = destroy_target_from_oracle(simple_metadata)
    if parsed is None:
        return None
    effect, target = parsed
    return effect, target, 1


def fixed_destroy_draw_from_source(source: str) -> int | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    destroy_matches = list(re.finditer(r"new\s+DestroyTargetEffect\s*\(\s*\)", text, re.S))
    if len(destroy_matches) != 1:
        return None
    draw_matches = list(re.finditer(r"new\s+DrawCardSourceControllerEffect\s*\(", text))
    if len(draw_matches) != 1:
        return None
    draw_count = java_constructor_int_or_noarg_default(
        text,
        "DrawCardSourceControllerEffect",
        noarg_default=1,
    )
    if draw_count != 1:
        return None
    if destroy_matches[0].start() > draw_matches[0].start():
        return None
    return draw_count


def fixed_bounce_draw_from_oracle(metadata: dict[str, Any]) -> tuple[str, str, int] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^(return target .+? to its owner's hand)\. (?:then )?draw a card\.?$",
        text,
    )
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group(1)}."
    parsed = bounce_target_from_oracle(simple_metadata)
    if parsed is None:
        return None
    effect, target = parsed
    return effect, target, 1


def fixed_bounce_draw_from_source(source: str) -> int | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    if "TargetAdjuster" in text or ".setTargetAdjuster" in text:
        return None
    bounce_matches = list(re.finditer(r"new\s+ReturnToHandTargetEffect\s*\(\s*\)", text, re.S))
    if len(bounce_matches) != 1:
        return None
    draw_matches = list(re.finditer(r"new\s+DrawCardSourceControllerEffect\s*\(", text))
    if len(draw_matches) != 1:
        return None
    draw_count = java_constructor_int_or_noarg_default(
        text,
        "DrawCardSourceControllerEffect",
        noarg_default=1,
    )
    if draw_count != 1:
        return None
    if bounce_matches[0].start() > draw_matches[0].start():
        return None
    return draw_count


def word_or_int(value: str) -> int:
    token = str(value or "").strip().lower()
    if token == "a":
        return 1
    if token.isdigit():
        return int(token)
    return NUMBER_WORDS[token]


def fixed_scry_draw_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, str] | None:
    text = oracle_text(metadata)
    text_without_reminder = re.sub(r"\([^)]*\)", "", text)
    text_without_reminder = re.sub(r"\s+", " ", text_without_reminder).strip()
    scry_first = re.match(
        r"^scry (\d+)(?:, then|\.) draw (a|\d+|one|two|three|four|five) cards?\.?"
        r"(?: (?:flashback|foretell) .*)?$",
        text_without_reminder,
    )
    if scry_first:
        return int(scry_first.group(1)), word_or_int(scry_first.group(2)), "scry_then_draw"
    draw_first = re.match(
        r"^draw (a|\d+|one|two|three|four|five) cards?\. scry (\d+)\.?"
        r"(?: (?:flashback|foretell) .*)?$",
        text_without_reminder,
    )
    if draw_first:
        return int(draw_first.group(2)), word_or_int(draw_first.group(1)), "draw_then_scry"
    return None


def fixed_scry_draw_from_source(source: str) -> tuple[int, int, str] | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    scry_matches = list(
        re.finditer(r"new\s+ScryEffect\s*\(\s*(\d+)\s*(?:,\s*false\s*)?\)", text, re.S)
    )
    draw_matches = list(re.finditer(r"new\s+DrawCardSourceControllerEffect\s*\(", text))
    if len(scry_matches) != 1 or len(draw_matches) != 1:
        return None
    draw_count = java_constructor_int_or_noarg_default(
        text,
        "DrawCardSourceControllerEffect",
        noarg_default=1,
    )
    if draw_count is None or draw_count <= 0:
        return None
    order = "scry_then_draw" if scry_matches[0].start() < draw_matches[0].start() else "draw_then_scry"
    return int(scry_matches[0].group(1)), draw_count, order


def fixed_scry_count_match_from_source(source: str) -> tuple[int, int] | None:
    matches = list(
        re.finditer(r"new\s+ScryEffect\s*\(\s*(\d+)\s*(?:,\s*false\s*)?\)", source or "", re.S)
    )
    if len(matches) != 1:
        return None
    return int(matches[0].group(1)), matches[0].start()


def fixed_damage_scry_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, str] | None:
    text = strip_parenthetical_reminders(oracle_text(metadata))
    text = re.sub(r"\s+", " ", text).strip()
    match = re.match(r"^(?P<damage>.+ deals (?P<amount>\d+) damage to .+?)\. scry (?P<scry>\d+)\.?$", text)
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group('damage')}."
    target = damage_target_from_oracle(simple_metadata)
    if target is None:
        return None
    return int(match.group("amount")), int(match.group("scry")), target


def fixed_damage_scry_from_source(source: str) -> tuple[int, int] | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    damage_matches = list(re.finditer(r"new\s+DamageTargetEffect\s*\(\s*(\d+)\s*(?:,[^)]*)?\)", text, re.S))
    scry_match = fixed_scry_count_match_from_source(text)
    if len(damage_matches) != 1 or scry_match is None:
        return None
    scry_count, scry_index = scry_match
    if damage_matches[0].start() > scry_index:
        return None
    return int(damage_matches[0].group(1)), scry_count


def fixed_destroy_scry_from_oracle(metadata: dict[str, Any]) -> tuple[str, str, int] | None:
    text = strip_parenthetical_reminders(oracle_text(metadata))
    text = re.sub(r"\s+", " ", text).strip()
    match = re.match(r"^(destroy target .+?)(\. it can't be regenerated)?\. scry (?P<scry>\d+)\.?$", text)
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group(1)}{match.group(2) or ''}."
    parsed = destroy_target_from_oracle(simple_metadata)
    if parsed is None:
        return None
    effect, target = parsed
    return effect, target, int(match.group("scry"))


def fixed_destroy_scry_from_source(source: str) -> int | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    destroy_matches = list(re.finditer(r"new\s+DestroyTargetEffect\s*\(\s*\)", text, re.S))
    scry_match = fixed_scry_count_match_from_source(text)
    if len(destroy_matches) != 1 or scry_match is None:
        return None
    scry_count, scry_index = scry_match
    if destroy_matches[0].start() > scry_index:
        return None
    return scry_count


def fixed_exile_scry_from_oracle(metadata: dict[str, Any]) -> tuple[str, str, int] | None:
    text = strip_parenthetical_reminders(oracle_text(metadata))
    text = re.sub(r"\s+", " ", text).strip()
    match = re.match(r"^(exile target .+?)\. scry (?P<scry>\d+)\.?$", text)
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group(1)}."
    parsed = exile_target_from_oracle(simple_metadata)
    if parsed is None:
        return None
    effect, target = parsed
    return effect, target, int(match.group("scry"))


def fixed_exile_scry_from_source(source: str) -> int | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    exile_matches = list(re.finditer(r"new\s+ExileTargetEffect\s*\(\s*\)", text, re.S))
    scry_match = fixed_scry_count_match_from_source(text)
    if len(exile_matches) != 1 or scry_match is None:
        return None
    scry_count, scry_index = scry_match
    if exile_matches[0].start() > scry_index:
        return None
    return scry_count


def fixed_bounce_scry_from_oracle(metadata: dict[str, Any]) -> tuple[str, str, int] | None:
    text = strip_parenthetical_reminders(oracle_text(metadata))
    text = re.sub(r"\s+", " ", text).strip()
    match = re.match(r"^(return target .+? to its owner's hand)\. scry (?P<scry>\d+)\.?$", text)
    if not match:
        return None
    simple_metadata = dict(metadata)
    simple_metadata["oracle_text"] = f"{match.group(1)}."
    parsed = bounce_target_from_oracle(simple_metadata)
    if parsed is None:
        return None
    effect, target = parsed
    return effect, target, int(match.group("scry"))


def fixed_bounce_scry_from_source(source: str) -> int | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    if "TargetAdjuster" in text or ".setTargetAdjuster" in text:
        return None
    bounce_matches = list(re.finditer(r"new\s+ReturnToHandTargetEffect\s*\(\s*\)", text, re.S))
    scry_match = fixed_scry_count_match_from_source(text)
    if len(bounce_matches) != 1 or scry_match is None:
        return None
    scry_count, scry_index = scry_match
    if bounce_matches[0].start() > scry_index:
        return None
    return scry_count


def fixed_damage_draw_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, str] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^.+ deals (\d+) damage to "
        r"(any target|target opponent|target player|target creature or planeswalker|target creature)"
        r"\. draw a card\.?$",
        text,
    )
    if not match:
        return None
    target_map = {
        "any target": "any_target",
        "target opponent": "opponent",
        "target player": "player",
        "target creature": "creature",
        "target creature or planeswalker": "creature_or_planeswalker",
    }
    return int(match.group(1)), 1, target_map[match.group(2)]


def fixed_damage_draw_from_source(source: str) -> tuple[int, int] | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    damage_matches = list(re.finditer(r"new\s+DamageTargetEffect\s*\(\s*(\d+)\s*\)", text, re.S))
    draw_matches = list(re.finditer(r"new\s+DrawCardSourceControllerEffect\s*\(", text))
    if len(damage_matches) != 1 or len(draw_matches) != 1:
        return None
    draw_count = java_constructor_int_or_noarg_default(
        text,
        "DrawCardSourceControllerEffect",
        noarg_default=1,
    )
    if draw_count != 1:
        return None
    if damage_matches[0].start() > draw_matches[0].start():
        return None
    return int(damage_matches[0].group(1)), draw_count


def source_matches_bounce_target(source: str, target: str) -> bool:
    if target in {"tapped_creature", "untapped_creature"}:
        return source_matches_target_constraint(source, target)
    text = source or ""
    if target == "creature":
        return "TargetCreaturePermanent" in text or "FilterCreaturePermanent" in text
    if target == "nonland_permanent":
        return "TargetNonlandPermanent" in text or "FilterNonlandPermanent" in text or "nonland permanent" in text
    if target == "permanent":
        return "TargetPermanent" in text or "FilterPermanent" in text
    if target == "artifact":
        return "TargetArtifactPermanent" in text or "FilterArtifactPermanent" in text or "artifact" in text
    if target == "enchantment":
        return "TargetEnchantmentPermanent" in text or "FilterEnchantmentPermanent" in text or "enchantment" in text
    if target == "land":
        return "TargetLandPermanent" in text or "FilterLandPermanent" in text or "land" in text
    return source_matches_target_constraint(source, target)


def exile_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = oracle_text(metadata)
    restricted = restricted_battlefield_target_from_oracle(metadata, "exile")
    if restricted is not None:
        return ("remove_creature" if restricted_target_base(restricted) == "creature" else "remove_permanent"), restricted
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
        (r"^return target tapped creature to its owner's hand\.?$", ("remove_creature", "tapped_creature")),
        (r"^return target untapped creature to its owner's hand\.?$", ("remove_creature", "untapped_creature")),
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


def counter_draw_target_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if not text.endswith(" draw a card."):
        return None
    return counter_target_from_oracle({"oracle_text": text.removesuffix(" draw a card.").strip()})


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


def recursion_target_constraints_for(
    target: str,
    *,
    controller: str = "self",
    mana_value_max: int | None = None,
    mana_value_max_from_x: bool = False,
    total_mana_value_max: int | None = None,
    requires_different_names: bool = False,
    graveyard_from_battlefield_this_turn: bool = False,
) -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "graveyard", "controller": controller}
    color_creature_targets = {
        "white_creature": "W",
        "blue_creature": "U",
        "black_creature": "B",
        "red_creature": "R",
        "green_creature": "G",
    }
    if target == "any_card":
        constraints["scope"] = "any_card"
    elif target in color_creature_targets:
        constraints["card_types"] = ["creature"]
        constraints["colors"] = [color_creature_targets[target]]
    elif target == "green_card":
        constraints["colors"] = ["G"]
    elif target == "multicolored_card":
        constraints["min_colors"] = 2
    elif target == "goblin_card":
        constraints["subtypes"] = ["goblin"]
    elif target == "zombie_card":
        constraints["subtypes"] = ["zombie"]
    elif target == "pirate_card":
        constraints["subtypes"] = ["pirate"]
    elif target == "knight_card":
        constraints["subtypes"] = ["knight"]
    elif target == "mercenary_card":
        constraints["subtypes"] = ["mercenary"]
    elif target == "elf_card":
        constraints["subtypes"] = ["elf"]
    elif target == "mount_card":
        constraints["subtypes"] = ["mount"]
    elif target == "vehicle_card":
        constraints["subtypes"] = ["vehicle"]
    elif target == "creature_no_abilities":
        constraints["card_types"] = ["creature"]
        constraints["requires_no_abilities"] = True
    elif target == "ally_creature":
        constraints["card_types"] = ["creature"]
        constraints["subtypes"] = ["ally"]
    elif target == "outlaw_creature":
        constraints["card_types"] = ["creature"]
        constraints["subtype_group"] = "outlaw"
        constraints["subtypes"] = ["assassin", "mercenary", "pirate", "rogue", "warlock"]
    elif target == "shared_creature_type":
        constraints["card_types"] = ["creature"]
        constraints["shared_subtype_group"] = "creature_type"
    elif target in {"creature", "artifact", "enchantment", "sorcery", "instant", "land"}:
        constraints["card_types"] = [target]
    elif target == "planeswalker":
        constraints["card_types"] = ["planeswalker"]
    elif target == "noncreature_permanent":
        constraints["card_types"] = ["artifact", "enchantment", "planeswalker", "battle", "land"]
        constraints["exclude_card_types"] = ["creature"]
    elif target == "nonland_permanent":
        constraints["card_types"] = ["artifact", "creature", "enchantment", "planeswalker", "battle"]
        constraints["exclude_card_types"] = ["land"]
    elif target == "rebel_permanent":
        constraints["card_types"] = ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"]
        constraints["subtypes"] = ["rebel"]
    elif target == "aura_card":
        constraints["subtypes"] = ["aura"]
    elif target == "human_creature":
        constraints["card_types"] = ["creature"]
        constraints["subtypes"] = ["human"]
    elif target == "non_human_creature":
        constraints["card_types"] = ["creature"]
        constraints["exclude_subtypes"] = ["human"]
    elif target == "basic_land":
        constraints["card_types"] = ["land"]
        constraints["supertypes"] = ["basic"]
    elif target == "instant_or_sorcery":
        constraints["card_types"] = ["instant", "sorcery"]
    elif target == "spirit_instant_or_sorcery":
        constraints["any_of"] = [
            {"subtypes": ["spirit"]},
            {"card_types": ["instant"]},
            {"card_types": ["sorcery"]},
        ]
    elif target == "artifact_or_enchantment":
        constraints["card_types"] = ["artifact", "enchantment"]
    elif target == "artifact_or_creature":
        constraints["card_types"] = ["artifact", "creature"]
    elif target == "artifact_or_enchantment_or_planeswalker":
        constraints["card_types"] = ["artifact", "enchantment", "planeswalker"]
    elif target == "creature_or_land":
        constraints["card_types"] = ["creature", "land"]
    elif target == "creature_or_enchantment":
        constraints["card_types"] = ["creature", "enchantment"]
    elif target == "creature_or_food":
        constraints["any_of"] = [
            {"card_types": ["creature"]},
            {"subtypes": ["food"]},
        ]
    elif target == "artifact_creature":
        constraints["card_types"] = ["artifact", "creature"]
        constraints["all_card_types_required"] = True
    elif target == "noncreature_nonland":
        constraints["exclude_card_types"] = ["creature", "land"]
    elif target == "permanent":
        constraints["card_types"] = ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"]
    else:
        constraints["target"] = target
    if mana_value_max is not None:
        constraints["mana_value_max"] = mana_value_max
    if mana_value_max_from_x:
        constraints["mana_value_max_source"] = "x_value"
    if target == "nonland_permanent" and mana_value_max_from_x:
        constraints["mana_value_max_source"] = "x_value"
    if total_mana_value_max is not None:
        constraints["total_mana_value_max"] = total_mana_value_max
    if requires_different_names:
        constraints["requires_different_names"] = True
    if graveyard_from_battlefield_this_turn:
        constraints["graveyard_from_battlefield_this_turn"] = True
    return constraints


def with_graveyard_permanent_count_mana_value_constraint(constraints: dict[str, Any]) -> dict[str, Any]:
    updated = dict(constraints)
    updated["mana_value_max_source"] = "graveyard_permanent_count"
    return updated


def library_pick_target_constraints_for(target: str) -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "library", "controller": "self"}
    if target == "any_card":
        constraints["scope"] = "any_card"
    elif target in {"creature", "land", "enchantment", "artifact", "instant", "sorcery"}:
        constraints["card_types"] = [target]
    elif target == "creature_or_land":
        constraints["card_types"] = ["creature", "land"]
    elif target == "creature_or_enchantment":
        constraints["card_types"] = ["creature", "enchantment"]
    elif target == "instant_or_sorcery":
        constraints["card_types"] = ["instant", "sorcery"]
    elif target == "snow_permanent":
        constraints["card_types"] = ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"]
        constraints["supertypes"] = ["snow"]
    else:
        constraints["target"] = target
    return constraints


def recursion_component(target: str, count: int = 1) -> dict[str, Any]:
    return {
        "target": target,
        "target_constraints": recursion_target_constraints_for(target),
        "count": count,
        "destination": "hand",
        "target_controller": "self",
    }


def recursion_choose_one_or_both_from_text(text: str) -> list[dict[str, Any]] | None:
    text = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if not text.startswith("choose one or both"):
        return None
    target_map = {
        "artifact": "artifact",
        "creature": "creature",
        "enchantment": "enchantment",
        "human creature": "human_creature",
        "land": "land",
        "non-human creature": "non_human_creature",
        "planeswalker": "planeswalker",
    }
    matches = re.findall(
        r"return target ([a-z-]+(?: [a-z-]+)?) card from your graveyard to your hand",
        text,
    )
    components: list[dict[str, Any]] = []
    for phrase in matches:
        target = target_map.get(phrase.strip())
        if target is None:
            return None
        components.append(recursion_component(target))
    if len(components) != 2:
        return None
    return components


def recursion_battlefield_component(target: str, count: int = 1) -> dict[str, Any]:
    return {
        "target": target,
        "target_constraints": recursion_target_constraints_for(target),
        "count": count,
        "destination": "battlefield",
        "target_controller": "self",
        "target_graveyard_controller": "self",
        "battlefield_controller": "self",
    }


def recursion_battlefield_choose_one_or_both_from_text(text: str) -> list[dict[str, Any]] | None:
    normalized = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if not normalized.startswith("choose one or both"):
        return None
    components: list[dict[str, Any]] = []
    if "return target creature card from your graveyard to the battlefield" in normalized:
        components.append(recursion_battlefield_component("creature"))
    if "return target aura card from your graveyard to the battlefield" in normalized:
        components.append(recursion_battlefield_component("aura_card"))
    if len(components) != 2:
        return None
    return components


def source_supports_battlefield_choose_one_or_both_recursion(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "getModes().setMinModes(1)" in text
        and "getModes().setMaxModes(2)" in text
        and text.count("ReturnFromGraveyardToBattlefieldTargetEffect") >= 2
        and "FILTER_CARD_CREATURE_YOUR_GRAVEYARD" in text
        and "SubType.AURA.getPredicate" in text
    )


def recursion_component_up_to_one(target: str) -> dict[str, Any]:
    component = recursion_component(target, 1)
    component["up_to_count"] = True
    return component


def recursion_for_each_color_creature_components_from_text(text: str) -> list[dict[str, Any]] | None:
    normalized = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if normalized != (
        "for each color, return up to one target creature card of that color "
        "from your graveyard to your hand."
    ):
        return None
    return [
        recursion_component_up_to_one("white_creature"),
        recursion_component_up_to_one("blue_creature"),
        recursion_component_up_to_one("black_creature"),
        recursion_component_up_to_one("red_creature"),
        recursion_component_up_to_one("green_creature"),
    ]


def recursion_for_each_color_creature_components_from_oracle(
    metadata: dict[str, Any],
) -> list[dict[str, Any]] | None:
    return recursion_for_each_color_creature_components_from_text(oracle_text(metadata))


def source_supports_for_each_color_creature_recursion(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "ReturnFromGraveyardToHandTargetEffect" in text
        and "ColorAssignment" in text
        and "TargetCardInYourGraveyard" in text
        and "FilterCreatureCard" in text
        and "ColorlessPredicate" in text
    )


def recursion_up_to_one_multi_target_components_from_text(text: str) -> list[dict[str, Any]] | None:
    normalized = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if normalized == (
        "return up to one target creature card, up to one target mount card, "
        "up to one target vehicle card, and up to one target creature card with "
        "no abilities from your graveyard to your hand."
    ):
        return [
            recursion_component_up_to_one("creature"),
            recursion_component_up_to_one("mount_card"),
            recursion_component_up_to_one("vehicle_card"),
            recursion_component_up_to_one("creature_no_abilities"),
        ]
    return None


def recursion_up_to_one_multi_target_components_from_oracle(
    metadata: dict[str, Any],
) -> list[dict[str, Any]] | None:
    return recursion_up_to_one_multi_target_components_from_text(oracle_text(metadata))


def source_supports_up_to_one_multi_target_recursion(
    source_text: str,
    components: list[dict[str, Any]],
) -> bool:
    text = str(source_text or "")
    if (
        "ReturnFromGraveyardToHandTargetEffect" not in text
        or "EachTargetPointer" not in text
        or text.count("TargetCardInYourGraveyard") < len(components)
    ):
        return False
    required_by_target = {
        "creature": ("StaticFilters.FILTER_CARD_CREATURE",),
        "mount_card": ("SubType.MOUNT",),
        "vehicle_card": ("SubType.VEHICLE",),
        "creature_no_abilities": ("NoAbilityPredicate",),
    }
    return all(
        any(needle in text for needle in required_by_target.get(str(component.get("target")), ()))
        for component in components
    )


def recursion_exile_self_components_from_text(text: str) -> list[dict[str, Any]] | None:
    text = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if not text.startswith("return up to one target "):
        return None
    if not text.endswith(" from your graveyard to your hand."):
        return None
    body = text.removesuffix(" from your graveyard to your hand.")
    phrases = re.findall(r"up to one target ([a-z ]+?) card", body)
    target_map = {
        "artifact": "artifact",
        "enchantment": "enchantment",
        "instant": "instant",
        "sorcery": "sorcery",
        "planeswalker": "planeswalker",
        "creature": "creature",
        "noncreature permanent": "noncreature_permanent",
    }
    targets = [target_map.get(phrase.strip()) for phrase in phrases]
    if any(target is None for target in targets):
        return None
    if targets == ["artifact", "enchantment", "instant", "sorcery", "planeswalker"]:
        return [recursion_component_up_to_one(str(target)) for target in targets]
    if targets == ["creature", "noncreature_permanent"]:
        return [recursion_component_up_to_one(str(target)) for target in targets]
    return None


def recursion_to_hand_exile_self_components_from_oracle(
    metadata: dict[str, Any],
) -> list[dict[str, Any]] | None:
    text = oracle_text_without_trailing_self_exile(metadata)
    if text is None:
        return None
    return recursion_exile_self_components_from_text(text)


def source_supports_exile_self_recursion_target(source_text: str, target: str) -> bool:
    text = str(source_text or "")
    if target == "any_card":
        return (
            "TargetCardInYourGraveyard" in text
            and (
                "FILTER_CARD_FROM_YOUR_GRAVEYARD" in text
                or "new TargetCardInYourGraveyard()" in text
                or re.search(r"TargetCardInYourGraveyard\s*\(\s*\d+\s*,", text, re.S)
            )
        )
    if target == "multicolored_card":
        return "MulticoloredPredicate" in text
    if target == "noncreature_permanent":
        return "FilterPermanentCard" in text and "Predicates.not(CardType.CREATURE.getPredicate())" in text
    checks = {
        "artifact": ("FilterArtifactCard", "FILTER_CARD_ARTIFACT"),
        "enchantment": ("FilterEnchantmentCard", "FilterEnchantmentCard"),
        "instant": ("CardType.INSTANT", "instant card"),
        "sorcery": ("CardType.SORCERY", "sorcery card"),
        "instant_or_sorcery": ("FilterInstantOrSorceryCard", "instant and/or sorcery", "instant or sorcery"),
        "planeswalker": ("FilterPlaneswalkerCard", "planeswalker card"),
        "creature": ("FILTER_CARD_CREATURE", "FilterCreatureCard"),
    }
    return any(needle in text for needle in checks.get(target, ()))


def source_supports_exile_self_recursion_components(
    source_text: str,
    components: list[dict[str, Any]],
) -> bool:
    text = str(source_text or "")
    if "ExileSpellEffect" not in text or "ReturnFromGraveyardToHandTargetEffect" not in text:
        return False
    if "EachTargetPointer" not in text:
        return False
    targets = [str(component.get("target") or "") for component in components]
    return all(source_supports_exile_self_recursion_target(text, target) for target in targets)


def recursion_choose_one_from_text(text: str) -> list[dict[str, Any]] | None:
    text = re.sub(r"\s+", " ", str(text or "").strip().lower())
    if not text.startswith("choose one") or text.startswith("choose one or both"):
        return None
    if "return target creature card from your graveyard to your hand" not in text:
        return None
    subtype_patterns = {
        "zombie": "zombie_card",
        "pirate": "pirate_card",
    }
    for subtype, target in subtype_patterns.items():
        if f"return two target {subtype} cards from your graveyard to your hand" in text:
            return [
                recursion_component("creature"),
                recursion_component(target, 2),
            ]
    if "return two target creature cards that share a creature type from your graveyard to your hand" in text:
        component = recursion_component("shared_creature_type", 2)
        component["shared_subtype_group"] = "creature_type"
        return [
            recursion_component("creature"),
            component,
        ]
    return None


def source_supports_choose_one_or_both_recursion(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "getModes().setMinModes(1)" in text
        and "getModes().setMaxModes(2)" in text
        and text.count("ReturnFromGraveyardToHandTargetEffect") >= 2
    )


def source_supports_choose_one_recursion(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "addMode" in text
        and text.count("ReturnFromGraveyardToHandTargetEffect") >= 2
    )


def recursion_to_hand_from_text(text: str) -> tuple[str, int, bool] | None:
    text = re.sub(r"\s+", " ", str(text or "").strip().lower())
    patterns: list[tuple[str, tuple[str, int, bool]]] = [
        (
            r"^return two target cards from your graveyard to your hand\.?$",
            ("any_card", 2, False),
        ),
        (
            r"^return two target creature cards from your graveyard to your hand\.?$",
            ("creature", 2, False),
        ),
        (
            r"^return target green card from your graveyard to your hand\.?$",
            ("green_card", 1, False),
        ),
        (
            r"^return target multicolored card from your graveyard to your hand\.?$",
            ("multicolored_card", 1, False),
        ),
        (
            r"^return up to three target multicolor(?:ed)? cards from your graveyard to your hand\.?$",
            ("multicolored_card", 3, True),
        ),
        (
            r"^return target goblin card from your graveyard to your hand\.?$",
            ("goblin_card", 1, False),
        ),
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
            r"^return another target creature card from your graveyard to your hand\.?$",
            ("creature", 1, False),
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
            r"^return target artifact creature card from your graveyard to your hand\.?$",
            ("artifact_creature", 1, False),
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
            r"^return target basic land card from your graveyard to your hand\.?$",
            ("basic_land", 1, False),
        ),
        (
            r"^return up to three target creature cards from your graveyard to your hand\.?$",
            ("creature", 3, True),
        ),
        (
            r"^return up to three target creature cards of the creature type of your choice from your graveyard to your hand\.?$",
            ("shared_creature_type", 3, True),
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


def recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> tuple[str, int, bool] | None:
    return recursion_to_hand_from_text(oracle_text(metadata))


def recursion_to_hand_x_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    match = re.match(r"^return x target creature cards from your graveyard to your hand\.?$", text)
    if not match:
        return None
    return {
        "target": "creature",
        "count": 0,
        "count_from_x": True,
        "up_to_count": False,
    }


def mill_then_return_target_from_phrase(phrase: str) -> str | None:
    normalized = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    mapping = {
        "creature or land": "creature_or_land",
        "permanent": "permanent",
        "creature": "creature",
        "land": "land",
    }
    return mapping.get(normalized)


def mill_then_return_from_text(text: str) -> dict[str, Any] | None:
    normalized = re.sub(r"\s+", " ", str(text or "").strip().lower())
    normalized = re.sub(r"\s*\([^)]*\)", "", normalized).strip()
    normalized = re.sub(
        r"^when (?:this creature|[^,]+?) enters(?: the battlefield)?,\s*",
        "",
        normalized,
    )
    match = re.match(
        r"^(?:put the top (?P<put_count>\w+|\d+) cards? of your library into your graveyard|"
        r"mill (?P<mill_count>\w+|\d+) cards?), then you may return "
        r"(?:a|an|one) (?P<phrase>.+?) card from your graveyard to your hand\.?$",
        normalized,
    )
    if not match:
        return None
    count_raw = match.group("put_count") or match.group("mill_count")
    mill_count = word_count_value(count_raw)
    target = mill_then_return_target_from_phrase(match.group("phrase"))
    if mill_count is None or target is None:
        return None
    return {
        "mill_count": mill_count,
        "target": target,
        "count": 1,
        "up_to_count": True,
    }


def mill_then_return_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    return mill_then_return_from_text(oracle_text(metadata))


def source_mill_then_return_target(source_text: str) -> str | None:
    text = str(source_text or "")
    if "FilterPermanentCard" in text:
        return "permanent"
    if "FILTER_CARD_LAND_FROM_YOUR_GRAVEYARD" in text:
        return "land"
    if "FILTER_CARD_CREATURE_YOUR_GRAVEYARD" in text or "FILTER_CARD_CREATURES_YOUR_GRAVEYARD" in text:
        return "creature"
    if "CardType.CREATURE.getPredicate()" in text and "CardType.LAND.getPredicate()" in text:
        return "creature_or_land"
    return None


def mill_then_return_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    mill_matches = re.findall(r"MillCardsControllerEffect\s*\(\s*(\d+)\s*\)", text)
    if len(mill_matches) != 1:
        return "mill_return_source_mill_count_not_supported"
    return_effect_matches = re.findall(r"ReturnCardChosenFromGraveyardEffect\s*\(", text)
    if len(return_effect_matches) != 1:
        return "mill_return_source_return_effect_count_not_supported"
    mill_index = text.find("MillCardsControllerEffect")
    return_index = text.find("ReturnCardChosenFromGraveyardEffect")
    if mill_index < 0 or return_index < 0 or mill_index > return_index:
        return "mill_return_source_effect_order_not_supported"
    if "PutCards.HAND" not in text:
        return "mill_return_source_destination_not_supported"
    target = source_mill_then_return_target(text)
    if target is None:
        return "mill_return_source_target_not_supported"
    return {
        "mill_count": int(mill_matches[0]),
        "target": target,
        "count": 1,
        "up_to_count": "ReturnCardChosenFromGraveyardEffect(true" in text,
    }


def oracle_text_without_trailing_self_exile(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    card_name = re.sub(r"\s+", " ", str(metadata.get("name") or "").strip().lower())
    if not card_name:
        return None
    match = re.fullmatch(rf"(?P<body>.+?)\.?\s+exile {re.escape(card_name)}\.?", text)
    if not match:
        return None
    return match.group("body").strip() + "."


def recursion_to_hand_exile_self_from_oracle(metadata: dict[str, Any]) -> tuple[str, int, bool] | None:
    text = oracle_text_without_trailing_self_exile(metadata)
    if text is None:
        return None
    return recursion_to_hand_from_text(text)


def recursion_to_hand_exile_self_x_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_without_trailing_self_exile(metadata)
    if text is None:
        return None
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^return x target cards from your graveyard to your hand\.?$",
            {"target": "any_card", "up_to_count": False},
        ),
        (
            r"^return up to x target instant and/or sorcery cards from your graveyard to your hand\.?$",
            {"target": "instant_or_sorcery", "up_to_count": True},
        ),
    ]
    for pattern, spec in patterns:
        if re.match(pattern, text):
            return {
                "target": spec["target"],
                "count": 0,
                "count_from_x": True,
                "up_to_count": bool(spec["up_to_count"]),
            }
    return None


def recursion_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^(?:fathomless descent — )?return to the battlefield target nonland permanent card in your graveyard "
            r"with mana value less than or equal to the number of permanent cards in your graveyard\.?$",
            {
                "target": "nonland_permanent",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "mana_value_max_from_graveyard_permanent_count": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^choose target creature card in your graveyard that was put there from the battlefield this turn\. "
            r"return it to the battlefield tapped\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "enters_tapped": True,
                "graveyard_from_battlefield_this_turn": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^return target rebel permanent card with mana value (?P<mana_value_max>\d+) or less from your graveyard to the battlefield\.?$",
            {
                "target": "rebel_permanent",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
            },
        ),
        (
            r"^return up to six target creature cards with different names from your graveyard to the battlefield\.?$",
            {
                "target": "creature",
                "count": 6,
                "up_to_count": True,
                "requires_different_names": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^return up to three target creature cards with total mana value (?P<total_mana_value_max>\d+) or less from your graveyard to the battlefield\.?$",
            {
                "target": "creature",
                "count": 3,
                "up_to_count": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^return any number of target ally creature cards with total mana value (?P<total_mana_value_max>\d+) or less from your graveyard to the battlefield\.?$",
            {
                "target": "ally_creature",
                "count": 99,
                "up_to_count": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^choose up to two target permanent cards in your graveyard that were put there from the battlefield this turn\. return them to the battlefield tapped\.?$",
            {
                "target": "permanent",
                "count": 2,
                "up_to_count": True,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "enters_tapped": True,
                "graveyard_from_battlefield_this_turn": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^choose up to four target creature cards in your graveyard that were put there from the battlefield this turn\. return them to the battlefield\.?$",
            {
                "target": "creature",
                "count": 4,
                "up_to_count": True,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "graveyard_from_battlefield_this_turn": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^choose target creature card in a graveyard that was put there from the battlefield this turn\. put that card onto the battlefield under your control\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "any_player",
                "battlefield_controller": "self",
                "graveyard_from_battlefield_this_turn": True,
                "oracle_complexity_supported": True,
            },
        ),
        (
            r"^return target permanent card from your graveyard to the battlefield\.?$",
            {"target": "permanent", "count": 1},
        ),
        (
            r"^return target artifact card from your graveyard to the battlefield\.?$",
            {"target": "artifact", "count": 1},
        ),
        (
            r"^return target enchantment card from your graveyard to the battlefield\.?$",
            {"target": "enchantment", "count": 1},
        ),
        (
            r"^return target creature card from your graveyard to the battlefield\.?$",
            {"target": "creature", "count": 1},
        ),
        (
            r"^return target creature card with mana value (?P<mana_value_max>\d+) or less from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
            },
        ),
        (
            r"^return target creature card with mana value x or less from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "mana_value_max_from_x": True,
            },
        ),
        (
            r"^return x target outlaw creature cards from your graveyard to the battlefield\.?(?: \([^)]*\))?$",
            {
                "target": "outlaw_creature",
                "count": 0,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "count_from_x": True,
            },
        ),
        (
            r"^put target creature card from an opponent's graveyard onto the battlefield under your control\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "opponent",
                "battlefield_controller": "self",
            },
        ),
        (
            r"^put target creature card from a graveyard onto the battlefield under your control\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "any_player",
                "battlefield_controller": "self",
            },
        ),
    ]
    for pattern, spec in patterns:
        match = re.match(pattern, text)
        if not match:
            continue
        result = {
            "target": spec["target"],
            "count": spec["count"],
            "target_graveyard_controller": spec.get("target_graveyard_controller", "self"),
            "battlefield_controller": spec.get("battlefield_controller", "self"),
            "enters_tapped": bool(spec.get("enters_tapped") or match.groupdict().get("tapped")),
        }
        if match.groupdict().get("mana_value_max"):
            result["mana_value_max"] = int(match.group("mana_value_max"))
        if spec.get("mana_value_max_from_x"):
            result["mana_value_max_from_x"] = True
        if spec.get("mana_value_max_from_graveyard_permanent_count"):
            result["mana_value_max_from_graveyard_permanent_count"] = True
        if match.groupdict().get("total_mana_value_max"):
            result["recursion_total_mana_value_max"] = int(match.group("total_mana_value_max"))
        for flag in (
            "up_to_count",
            "count_from_x",
            "requires_different_names",
            "graveyard_from_battlefield_this_turn",
            "oracle_complexity_supported",
        ):
            if spec.get(flag):
                result[flag] = True
        return result
    return None


def recursion_all_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^return all enchantment cards from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {"target": "enchantment"},
        ),
        (
            r"^return all creature cards with mana value (?P<mana_value_max>\d+) or less from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {"target": "creature"},
        ),
        (
            r"^return all artifact and enchantment cards from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {"target": "artifact_or_enchantment"},
        ),
        (
            r"^return all artifact, enchantment, and planeswalker cards from your graveyard to the battlefield(?P<tapped> tapped)?\.?$",
            {"target": "artifact_or_enchantment_or_planeswalker"},
        ),
    ]
    for pattern, spec in patterns:
        match = re.match(pattern, text)
        if not match:
            continue
        result = {
            "target": spec["target"],
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "return_all_matching": True,
            "enters_tapped": bool(match.groupdict().get("tapped")),
        }
        if match.groupdict().get("mana_value_max"):
            result["mana_value_max"] = int(match.group("mana_value_max"))
        return result
    if re.match(
        r"^return each artifact and creature card with mana value x from your graveyard to the battlefield\.?$",
        text,
    ):
        return {
            "target": "artifact_or_creature",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "return_all_matching": True,
            "mana_value_exact_from_x": True,
        }
    return None


def recursion_all_to_battlefield_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    constructors = re.findall(r"new\s+ReturnFromYourGraveyardToBattlefieldAllEffect\s*\(", text)
    if len(constructors) != 1:
        return "recursion_battlefield_all_source_not_single_effect"
    if has_additional_cost(text):
        return "recursion_battlefield_all_source_additional_cost_not_supported"
    if "PayVariableLifeCost" in text:
        return "recursion_battlefield_all_source_variable_life_cost_not_supported"
    enters_tapped = bool(
        re.search(r"ReturnFromYourGraveyardToBattlefieldAllEffect\s*\([^;]*,\s*true\s*\)", text, re.S)
    )
    target: str | None = None
    mana_value_max: int | None = None
    mana_value_exact_from_x = False
    lowered = text.lower()
    if (
        "FILTER_CARD_ENCHANTMENTS" in text
        or "FILTER_CARD_ENCHANTMENT" in text
        or "FilterEnchantmentCard" in text
        or "enchantment cards" in lowered
    ):
        target = "enchantment"
    if "FilterCreatureCard" in text or "FILTER_CARD_CREATURE" in text or "creature cards" in lowered:
        if target is not None:
            return "recursion_battlefield_all_source_target_not_supported"
        target = "creature"
    if "FilterArtifactOrEnchantmentCard" in text or "artifact and enchantment cards" in lowered:
        target = "artifact_or_enchantment"
    if (
        "CardType.ARTIFACT.getPredicate" in text
        and "CardType.ENCHANTMENT.getPredicate" in text
        and "CardType.PLANESWALKER.getPredicate" in text
    ):
        target = "artifact_or_enchantment_or_planeswalker"
    if (
        "CardType.ARTIFACT.getPredicate" in text
        and "CardType.CREATURE.getPredicate" in text
        and "GetXValue.instance" in text
        and "getManaValue() ==" in text
    ):
        target = "artifact_or_creature"
        mana_value_exact_from_x = True
    mana_value_match = re.search(
        r"ManaValuePredicate\s*\(\s*ComparisonType\.FEWER_THAN\s*,\s*(\d+)\s*\)",
        text,
    )
    if mana_value_match:
        mana_value_max = int(mana_value_match.group(1)) - 1
    if target is None:
        return "recursion_battlefield_all_source_target_not_supported"
    result = {
        "target": target,
        "target_graveyard_controller": "self",
        "battlefield_controller": "self",
        "return_all_matching": True,
        "enters_tapped": enters_tapped,
    }
    if mana_value_max is not None:
        result["mana_value_max"] = mana_value_max
    if mana_value_exact_from_x:
        result["mana_value_exact_from_x"] = True
    return result


def recursion_to_battlefield_with_counter_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^return target creature card from your graveyard to the battlefield "
            r"with two additional \+1/\+1 counters on it\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "counter_type": "+1/+1",
                "counter_amount": 2,
                "additional_counter": True,
            },
        ),
        (
            r"^return target creature card from your graveyard to the battlefield "
            r"with a lifelink counter on it\.?$",
            {
                "target": "creature",
                "count": 1,
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "counter_type": "lifelink",
                "counter_amount": 1,
                "keywords": ["lifelink"],
            },
        ),
        (
            r"^put one, two, or three target creature cards from graveyards onto the battlefield "
            r"under your control\. each of them enters with an additional -1/-1 counter on it\.?$",
            {
                "target": "creature",
                "count": 3,
                "target_count_min": 1,
                "target_graveyard_controller": "any_player",
                "battlefield_controller": "self",
                "counter_type": "-1/-1",
                "counter_amount": 1,
                "additional_counter": True,
            },
        ),
    ]
    for pattern, spec in patterns:
        if re.match(pattern, text):
            return dict(spec)
    return None


def recursion_battlefield_counter_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    effect_constructors = re.findall(
        r"new\s+ReturnFromGraveyardToBattlefieldWithCounterTargetEffect\s*\(",
        text,
    )
    if len(effect_constructors) != 1:
        return "recursion_battlefield_counter_source_not_single_effect"
    if "TargetCardInYourGraveyard" in text:
        target_graveyard_controller = "self"
    elif "TargetCardInGraveyard" in text and "TargetCardInYourGraveyard" not in text:
        target_graveyard_controller = "any_player"
    else:
        return "recursion_battlefield_counter_source_target_not_supported"
    if "FILTER_CARD_CREATURE" not in text and "FilterCreatureCard" not in text:
        return "recursion_battlefield_counter_source_target_not_supported"

    counter_matches = re.findall(
        r"CounterType\.(P1P1|M1M1|LIFELINK)\.createInstance\s*\(\s*(\d*)\s*\)",
        text,
    )
    if len(counter_matches) != 1:
        return "recursion_battlefield_counter_source_counter_not_supported"
    counter_symbol, raw_count = counter_matches[0]
    counter_type = {
        "P1P1": "+1/+1",
        "M1M1": "-1/-1",
        "LIFELINK": "lifelink",
    }[counter_symbol]
    counter_amount = int(raw_count or "1")

    count = 1
    target_count_min: int | None = None
    count_match = re.search(r"TargetCardInGraveyard\s*\(\s*(\d+)\s*,\s*(\d+)\s*,", text, re.S)
    if count_match:
        target_count_min = int(count_match.group(1))
        count = int(count_match.group(2))
    elif re.search(r"TargetCardInYourGraveyard\s*\(\s*0\s*,\s*(\d+)\s*,", text, re.S):
        return "recursion_battlefield_counter_source_target_not_supported"

    return {
        "target": "creature",
        "count": count,
        "target_count_min": target_count_min,
        "target_graveyard_controller": target_graveyard_controller,
        "battlefield_controller": "self",
        "counter_type": counter_type,
        "counter_amount": counter_amount,
    }


def source_supports_battlefield_recursion_target(source_text: str, target_graveyard_controller: str) -> bool:
    text = str(source_text or "")
    controller = str(target_graveyard_controller or "self")
    if controller == "self":
        return "TargetCardInYourGraveyard" in text
    if controller == "opponent":
        return "TargetCardInOpponentsGraveyard" in text
    if controller in {"any", "any_player"}:
        return "TargetCardInGraveyard" in text and "TargetCardInYourGraveyard" not in text
    return False


def source_supports_battlefield_recursion_target_type(source_text: str, target_type: str) -> bool:
    text = str(source_text or "")
    lowered = text.lower()
    target = str(target_type or "")
    if target == "creature":
        return (
            "FILTER_CARD_CREATURE" in text
            or "FilterCreatureCard" in text
            or "creature card" in lowered
        )
    if target == "artifact":
        return "FILTER_CARD_ARTIFACT" in text or "FilterArtifactCard" in text or "artifact card" in lowered
    if target == "ally_creature":
        return "FilterCreatureCard" in text and "SubType.ALLY.getPredicate" in text
    if target == "outlaw_creature":
        return "FilterCreatureCard" in text and "OutlawPredicate" in text
    if target == "rebel_permanent":
        return "FilterPermanentCard" in text and "SubType.REBEL.getPredicate" in text
    if target == "aura_card":
        return "SubType.AURA.getPredicate" in text or "Aura card" in text
    if target == "nonland_permanent":
        return "FilterNonlandCard" in text and "PermanentPredicate" in text
    if target == "enchantment":
        return (
            "FILTER_CARD_ENCHANTMENT" in text
            or "FilterEnchantmentCard" in text
            or "enchantment card" in lowered
        )
    if target == "permanent":
        return "FilterPermanentCard" in text or "permanent card" in lowered
    return False


def source_supports_battlefield_recursion_mana_value(source_text: str, mana_value_max: int | None) -> bool:
    if mana_value_max is None:
        return True
    expected_exclusive = int(mana_value_max) + 1
    pattern = (
        r"ManaValuePredicate\s*\(\s*ComparisonType\.FEWER_THAN\s*,\s*"
        rf"{expected_exclusive}\s*\)"
    )
    return bool(re.search(pattern, source_text or ""))


def source_supports_battlefield_recursion_graveyard_permanent_count_mana_value(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "PermanentPredicate.instance" in text
        and "FilterNonlandCard" in text
        and "count(StaticFilters.FILTER_CARD_PERMANENT" in text
        and "getManaValue()" in text
    )


def source_supports_battlefield_recursion_x_mana_value(source_text: str) -> bool:
    text = str(source_text or "")
    return (
        "XManaValueTargetAdjuster" in text
        and "ComparisonType.OR_LESS" in text
    )


def source_supports_recursion_x_target_count(source_text: str) -> bool:
    text = str(source_text or "")
    return "XTargetsCountAdjuster" in text or (
        "TargetsCountAdjuster" in text and "GetXValue.instance" in text
    )


def source_supports_battlefield_recursion_total_mana_value(
    source_text: str,
    total_mana_value_max: int | None,
) -> bool:
    if total_mana_value_max is None:
        return True
    text = str(source_text or "")
    return (
        "checkCanTargetTotalValueLimit" in text
        and "checkPossibleTargetsTotalValueLimit" in text
        and "MageObject::getManaValue" in text
        and re.search(rf"\b{int(total_mana_value_max)}\s*,\s*game", text) is not None
    )


def source_supports_battlefield_recursion_different_names(source_text: str, required: bool) -> bool:
    if not required:
        return True
    text = str(source_text or "")
    lowered = text.lower()
    return (
        "different names" in lowered
        and "getTargets().contains" in text
        and "Collectors.toSet" in text
    )


def source_supports_battlefield_recursion_this_turn(source_text: str, required: bool) -> bool:
    if not required:
        return True
    text = str(source_text or "")
    return (
        "PutIntoGraveFromBattlefieldThisTurnPredicate" in text
        and "CardsPutIntoGraveyardWatcher" in text
    )


def recursion_effect_text_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if not text:
        return None
    for sentence in re.split(r"(?<=\.)\s+", text):
        candidate = sentence.strip()
        if not candidate:
            continue
        if not candidate.endswith("."):
            candidate = candidate + "."
        if (
            candidate.startswith(("return ", "put "))
            and "from your graveyard" in candidate
            and "flashback" not in candidate
            and "cycling" not in candidate
        ):
            return candidate
    return None


def auxiliary_cost_from_oracle(metadata: dict[str, Any], keyword: str) -> str | None:
    match = re.search(
        rf"\b{re.escape(keyword.lower())}\s+(?P<cost>(?:\{{[0-9wubrg]+\}})+)",
        oracle_text(metadata),
    )
    if not match:
        return None
    cost = canonical_mana_cost_text(match.group("cost"))
    return cost if parse_mana_cost_text(cost) is not None else None


def parse_flashback_cost_from_source(source_text: str) -> str | None:
    text = str(source_text or "")
    match = re.search(
        r"new\s+FlashbackAbility\s*\(\s*this\s*,\s*new\s+ManaCostsImpl<[^>]*>\s*\(\s*"
        r'"(?P<cost>[^"]+)"\s*\)\s*\)',
        text,
        re.S,
    )
    if not match:
        return None
    cost = canonical_mana_cost_text(match.group("cost"))
    return cost if parse_mana_cost_text(cost) is not None else None


def parse_cycling_cost_from_source(source_text: str) -> str | None:
    text = str(source_text or "")
    mana_match = re.search(
        r"new\s+CyclingAbility\s*\(\s*new\s+ManaCostsImpl<[^>]*>\s*\(\s*"
        r'"(?P<cost>[^"]+)"\s*\)\s*\)',
        text,
        re.S,
    )
    if mana_match:
        cost = canonical_mana_cost_text(mana_match.group("cost"))
        return cost if parse_mana_cost_text(cost) is not None else None
    generic_match = re.search(
        r"new\s+CyclingAbility\s*\(\s*new\s+GenericManaCost\s*\(\s*(?P<generic>\d+)\s*\)\s*\)",
        text,
        re.S,
    )
    if generic_match:
        return "{" + generic_match.group("generic") + "}"
    return None


def auxiliary_recursion_spell_fields_from_source(
    metadata: dict[str, Any],
    source_text: str,
    abilities: set[str],
) -> dict[str, Any] | str:
    if not is_spell(metadata):
        return "recursion_auxiliary_not_spell"
    if not abilities:
        return {}
    unsupported = abilities - AUXILIARY_RECURSION_SPELL_ABILITY_CLASSES
    if unsupported:
        return "recursion_auxiliary_ability_class_not_supported"

    fields: dict[str, Any] = {
        "xmage_auxiliary_ability_classes": sorted(abilities),
    }
    if "FlashbackAbility" in abilities:
        source_cost = parse_flashback_cost_from_source(source_text)
        oracle_cost = auxiliary_cost_from_oracle(metadata, "flashback")
        if not source_cost or not oracle_cost:
            return "recursion_auxiliary_flashback_cost_not_supported"
        if source_cost != oracle_cost:
            return "recursion_auxiliary_flashback_cost_mismatch"
        fields["flashback_cost"] = source_cost
        fields["flashback_status"] = "runtime_executor_v1"
    if "CyclingAbility" in abilities:
        source_cost = parse_cycling_cost_from_source(source_text)
        oracle_cost = auxiliary_cost_from_oracle(metadata, "cycling")
        if not source_cost or not oracle_cost:
            return "recursion_auxiliary_cycling_cost_not_supported"
        if source_cost != oracle_cost:
            return "recursion_auxiliary_cycling_cost_mismatch"
        fields["cycling_cost"] = source_cost
        fields["cycling_status"] = "runtime_executor_v1"
    return fields


def _count_word_to_int(value: str) -> int | None:
    text = str(value or "").strip().lower()
    if text.isdigit():
        return int(text)
    return NUMBER_WORDS.get(text)


def primary_graveyard_exile_text_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    if not text:
        return None
    for sentence in re.split(r"(?<=\.)\s+", text):
        candidate = sentence.strip()
        if not candidate:
            continue
        if not candidate.endswith("."):
            candidate = candidate + "."
        if candidate.startswith("exile ") and "graveyard" in candidate:
            return candidate
    return None


def graveyard_exile_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = primary_graveyard_exile_text_from_oracle(metadata)
    if text is None:
        return "graveyard_exile_oracle_not_simple"
    if re.match(r"^exile target card from a graveyard\.?$", text):
        return {
            "target": "any_card",
            "count": 1,
            "target_controller": "any",
            "single_graveyard": False,
            "up_to_count": False,
            "target_count_from_x": False,
        }
    match = re.match(
        r"^exile up to (?P<count>[a-z0-9]+) target cards from a single graveyard\.?$",
        text,
    )
    if match:
        count = _count_word_to_int(match.group("count"))
        if count is None:
            return "graveyard_exile_oracle_count_not_supported"
        return {
            "target": "any_card",
            "count": count,
            "target_controller": "any",
            "single_graveyard": True,
            "up_to_count": True,
            "target_count_from_x": False,
        }
    if re.match(r"^exile x target cards from a single graveyard\.?$", text):
        return {
            "target": "any_card",
            "count": 1,
            "target_controller": "any",
            "single_graveyard": True,
            "up_to_count": False,
            "target_count_from_x": True,
        }
    return "graveyard_exile_oracle_not_simple"


def graveyard_exile_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    if len(re.findall(r"new\s+ExileTargetEffect\s*\(", text)) != 1:
        return "graveyard_exile_source_not_single_effect"
    if "TargetCardInASingleGraveyard" in text:
        match = re.search(
            r"TargetCardInASingleGraveyard\s*\(\s*(?P<min>\d+)\s*,\s*(?P<max>\d+)\s*,",
            text,
            re.S,
        )
        if not match:
            return "graveyard_exile_source_target_not_supported"
        min_count = int(match.group("min"))
        max_count = int(match.group("max"))
        return {
            "target": "any_card",
            "count": max_count,
            "target_controller": "any",
            "single_graveyard": True,
            "up_to_count": min_count == 0,
            "target_count_from_x": "XTargetsCountAdjuster" in text,
        }
    if "TargetCardInGraveyard" in text:
        return {
            "target": "any_card",
            "count": 1,
            "target_controller": "any",
            "single_graveyard": False,
            "up_to_count": False,
            "target_count_from_x": False,
        }
    return "graveyard_exile_source_target_not_supported"


def graveyard_to_library_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^put target card from your graveyard on top of your library\.?$",
            {"target": "any_card", "count": 1, "destination": "library_top", "up_to_count": False},
        ),
        (
            r"^put target card from your graveyard on the bottom of your library\.?$",
            {
                "target": "any_card",
                "count": 1,
                "destination": "library_bottom",
                "up_to_count": False,
                "target_graveyard_controller": "self",
                "library_controller": "self",
            },
        ),
        (
            r"^put target card from a graveyard on the bottom of its owner's library\.?$",
            {
                "target": "any_card",
                "count": 1,
                "destination": "library_bottom",
                "up_to_count": False,
                "target_graveyard_controller": "any",
                "library_controller": "owner",
            },
        ),
        (
            r"^put up to one target card from a graveyard on the bottom of its owner's library\.?$",
            {
                "target": "any_card",
                "count": 1,
                "destination": "library_bottom",
                "up_to_count": True,
                "target_graveyard_controller": "any",
                "library_controller": "owner",
            },
        ),
        (
            r"^put target creature card from your graveyard on top of your library\.?$",
            {"target": "creature", "count": 1, "destination": "library_top", "up_to_count": False},
        ),
        (
            r"^put target creature card from your graveyard on the bottom of your library\.?$",
            {"target": "creature", "count": 1, "destination": "library_bottom", "up_to_count": False},
        ),
        (
            r"^put up to three target creature cards from your graveyard on top of your library\.?$",
            {"target": "creature", "count": 3, "destination": "library_top", "up_to_count": True},
        ),
        (
            r"^put up to three target creature cards from your graveyard on the bottom of your library\.?$",
            {"target": "creature", "count": 3, "destination": "library_bottom", "up_to_count": True},
        ),
    ]
    for pattern, result in patterns:
        if re.match(pattern, text):
            parsed = dict(result)
            parsed.setdefault("target_graveyard_controller", "self")
            parsed.setdefault("library_controller", "self")
            return parsed

    generic_patterns: list[tuple[str, str]] = [
        (
            r"^put target (?P<phrase>.+?) card from your graveyard on top of your library\.?$",
            "library_top",
        ),
        (
            r"^put target (?P<phrase>.+?) card from your graveyard on the bottom of your library\.?$",
            "library_bottom",
        ),
        (
            r"^put up to (?P<count>one|two|three|\d+) target (?P<phrase>.+?) cards? "
            r"from your graveyard on top of your library\.?$",
            "library_top",
        ),
        (
            r"^put up to (?P<count>one|two|three|\d+) target (?P<phrase>.+?) cards? "
            r"from your graveyard on the bottom of your library\.?$",
            "library_bottom",
        ),
    ]
    count_words = {"one": 1, "two": 2, "three": 3}
    for pattern, destination in generic_patterns:
        match = re.match(pattern, text)
        if not match:
            continue
        target = etb_recursion_target_from_phrase(match.group("phrase"))
        if target is None:
            continue
        raw_count = match.groupdict().get("count")
        count = count_words.get(raw_count or "", int(raw_count) if raw_count and raw_count.isdigit() else 1)
        return {
            "target": target,
            "count": count,
            "destination": destination,
            "up_to_count": bool(raw_count),
            "target_graveyard_controller": "self",
            "library_controller": "self",
        }
    return None


def graveyard_shuffle_to_library_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = oracle_text(metadata)
    match = re.match(
        r"^target player shuffles up to (?P<count>one|two|three|four|\d+) "
        r"target cards? from their graveyard into their library\.(?: .*)?$",
        text,
    )
    if not match:
        return "graveyard_shuffle_to_library_oracle_not_simple"
    count_words = {"one": 1, "two": 2, "three": 3, "four": 4}
    raw_count = match.group("count")
    count = count_words.get(raw_count, int(raw_count) if raw_count.isdigit() else 0)
    if count <= 0:
        return "graveyard_shuffle_to_library_oracle_count_not_supported"
    return {
        "target": "any_card",
        "count": count,
        "destination": "library_shuffle",
        "up_to_count": True,
        "target_graveyard_controller": "target_player",
        "target_controller": "target_player",
        "library_controller": "target_player",
    }


def graveyard_to_library_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    effect_matches = re.findall(r"new\s+PutOnLibraryTargetEffect\s*\(\s*(true|false)\s*\)", text)
    if len(effect_matches) != 1:
        return "graveyard_to_library_source_not_single_effect"
    destination = "library_top" if effect_matches[0] == "true" else "library_bottom"
    if "EachTargetPointer" in text or ".setTargetPointer" in text:
        return "graveyard_to_library_source_target_not_supported"
    target_graveyard_controller = "self"
    library_controller = "self"
    if "TargetCardInGraveyard" in text and "TargetCardInYourGraveyard" not in text:
        if not re.search(r"TargetCardInGraveyard\s*\(\s*(?:\)|0\s*,\s*\d+\s*\))", text):
            return "graveyard_to_library_source_target_not_supported"
        target = "any_card"
        target_graveyard_controller = "any"
        library_controller = "owner"
    elif "FILTER_CARD_ARTIFACT_OR_CREATURE" in text:
        target = "artifact_or_creature"
    elif "FILTER_CARD_INSTANT_OR_SORCERY_FROM_YOUR_GRAVEYARD" in text or "FilterInstantOrSorceryCard" in text:
        target = "instant_or_sorcery"
    elif (
        "FilterNonlandCard" in text
        and "Predicates.not" in text
        and "CardType.CREATURE.getPredicate()" in text
    ):
        target = "noncreature_nonland"
    elif "FILTER_CARD_CREATURES_YOUR_GRAVEYARD" in text or "FILTER_CARD_CREATURE_YOUR_GRAVEYARD" in text:
        target = "creature"
    elif re.search(r"TargetCardInYourGraveyard\s*\(\s*\)", text):
        target = "any_card"
    else:
        return "graveyard_to_library_source_target_not_supported"
    count = 1
    up_to = False
    count_match = re.search(r"TargetCardIn(?:Your)?Graveyard\s*\(\s*0\s*,\s*(\d+)", text, re.S)
    if count_match:
        count = int(count_match.group(1))
        up_to = True
    return {
        "target": target,
        "count": count,
        "destination": destination,
        "up_to_count": up_to,
        "target_graveyard_controller": target_graveyard_controller,
        "library_controller": library_controller,
    }


def graveyard_shuffle_to_library_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    if len(re.findall(r"TargetPlayerShufflesTargetCardsEffect\s*\(", text)) != 1:
        return "graveyard_shuffle_to_library_source_not_single_effect"
    if len(re.findall(r"new\s+TargetPlayer\s*\(", text)) != 1:
        return "graveyard_shuffle_to_library_source_target_player_not_supported"
    target_match = re.search(r"TargetCardInTargetPlayersGraveyard\s*\(\s*(\d+)\s*\)", text)
    if not target_match:
        return "graveyard_shuffle_to_library_source_target_cards_not_supported"
    count = int(target_match.group(1))
    if count <= 0 or count > 20:
        return "graveyard_shuffle_to_library_source_count_not_supported"
    return {
        "target": "any_card",
        "count": count,
        "destination": "library_shuffle",
        "up_to_count": True,
        "target_graveyard_controller": "target_player",
        "target_controller": "target_player",
        "library_controller": "target_player",
    }


def activated_graveyard_to_library_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_graveyard_to_library_oracle_not_simple"
    effect_text = text.rsplit(":", 1)[1].strip()
    parsed = graveyard_to_library_from_oracle({"oracle_text": effect_text})
    if parsed is None:
        return "activated_graveyard_to_library_oracle_not_simple"
    return parsed


def activated_graveyard_to_library_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_graveyard_to_library_source_cost_not_supported"
    if "Zone.GRAVEYARD" in text:
        return "activated_graveyard_to_library_source_not_battlefield"
    effect_matches = re.findall(r"PutOnLibraryTargetEffect\s*\(", text)
    if len(effect_matches) != 1:
        return "activated_graveyard_to_library_source_not_single_effect"
    if len(re.findall(r"SimpleActivatedAbility\s*\(", text)) != 1:
        return "activated_graveyard_to_library_source_multiple_abilities_not_supported"
    effect_index = text.find("PutOnLibraryTargetEffect")
    window = text[max(0, effect_index - 500) : effect_index + 1800]
    if "SimpleActivatedAbility" not in window:
        return "activated_graveyard_to_library_source_not_simple_activated"
    parsed_target = graveyard_to_library_from_source(text)
    if isinstance(parsed_target, str):
        return "activated_graveyard_to_library_" + parsed_target.removeprefix("graveyard_to_library_")
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    colored_match = re.search(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    elif colored_match:
        cost_text = "{" + colored_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_graveyard_to_library_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        **parsed_target,
        "activation_cost_mana": canonical_mana_cost_text(cost_text),
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


def etb_graveyard_to_library_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = oracle_text_after_leading_static_keywords(metadata)
    trigger_prefix = r"^when (?:this creature|[^,]+?) enters(?: the battlefield)?, (?:you may )?"
    match = re.match(
        trigger_prefix
        + r"(?P<effect>put .+? from (?:your|a) graveyard .+? (?:your|its owner's) library\.?)$",
        text,
    )
    if not match:
        return "etb_graveyard_to_library_oracle_not_simple"
    parsed = graveyard_to_library_from_oracle({"oracle_text": match.group("effect")})
    if parsed is None:
        return "etb_graveyard_to_library_oracle_not_simple"
    return parsed


def etb_graveyard_to_library_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if "EntersBattlefieldTriggeredAbility" not in text:
        return "etb_graveyard_to_library_source_not_etb_trigger"
    if "SimpleActivatedAbility" in text:
        return "etb_graveyard_to_library_source_not_etb_trigger"
    if len(re.findall(r"PutOnLibraryTargetEffect\s*\(", text)) != 1:
        return "etb_graveyard_to_library_source_not_single_effect"
    parsed_target = graveyard_to_library_from_source(text)
    if isinstance(parsed_target, str):
        return "etb_" + parsed_target
    return parsed_target


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


def etb_counter_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, int] | None:
    text = strip_leading_parenthetical_reminders(
        re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip()
    )
    match = re.match(
        r"^(?:when|whenever) (?:this creature|.+) enters(?: the battlefield)?, put "
        r"(a|an|one|two|three|four|five|six|seven|eight|nine|ten|\d+) "
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


def fixed_boost_draw_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, int] | None:
    text = strip_leading_parenthetical_reminders(oracle_text(metadata))
    match = re.match(
        r"^target creature gets ([+-]?\d+)/([+-]?\d+) until end of turn\. draw a card\.?$",
        text,
    )
    if not match:
        return None
    power = signed_int_from_oracle(match.group(1))
    toughness = signed_int_from_oracle(match.group(2))
    if power is None or toughness is None:
        return None
    return power, toughness, 1


def fixed_boost_draw_from_source(source: str) -> tuple[int, int, int] | None:
    text = source or ""
    boost = fixed_boost_target_from_source(text)
    if boost is None:
        return None
    draw_matches = re.findall(r"new\s+DrawCardSourceControllerEffect\s*\(\s*(\d+)\s*\)", text)
    if len(draw_matches) != 1:
        return None
    boost_match = re.search(r"new\s+BoostTargetEffect\s*\(", text)
    draw_match = re.search(r"new\s+DrawCardSourceControllerEffect\s*\(", text)
    if not boost_match or not draw_match or boost_match.start() > draw_match.start():
        return None
    return boost[0], boost[1], int(draw_matches[0])


def fixed_boost_keyword_target_from_source(
    source: str,
    keyword_ability_class: str,
) -> tuple[int, int, str] | None:
    text = source or ""
    boost_matches = re.findall(
        r"new\s+BoostTargetEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*,\s*Duration\.EndOfTurn\s*\)",
        text,
        re.S,
    )
    if len(boost_matches) != 1:
        return None
    gain_matches = re.findall(r"new\s+GainAbilityTargetEffect\s*\(", text)
    if len(gain_matches) != 1:
        return None
    ability_expr = (
        rf"(?:{re.escape(keyword_ability_class)}\.getInstance\s*\(\s*\)"
        rf"|new\s+{re.escape(keyword_ability_class)}\s*\([^)]*\))"
    )
    if not re.search(
        rf"new\s+GainAbilityTargetEffect\s*\(\s*{ability_expr}\s*,\s*Duration\.EndOfTurn",
        text,
        re.S,
    ):
        return None
    any_target = re.findall(r"new\s+TargetCreaturePermanent\s*\(", text)
    controlled_target = re.findall(r"new\s+TargetControlledCreaturePermanent\s*\(", text)
    if len(any_target) + len(controlled_target) != 1:
        return None
    if controlled_target:
        if not re.search(r"new\s+TargetControlledCreaturePermanent\s*\(\s*\)", text):
            return None
        target_controller = "self"
    else:
        if not re.search(r"new\s+TargetCreaturePermanent\s*\(\s*\)", text):
            return None
        target_controller = "any"
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    return int(boost_matches[0][0]), int(boost_matches[0][1]), target_controller


STATIC_CONTROLLED_PT_BLOCKED_ORACLE_WORDS = {
    "attacking",
    "blocking",
    "blocked",
    "enchanted",
    "equipped",
    "modified",
    "tapped",
    "untapped",
    "white",
    "blue",
    "black",
    "red",
    "green",
}

STATIC_CONTROLLED_PT_BLOCKED_SOURCE_MARKERS = (
    "ColorPredicate",
    "TappedPredicate",
    "Predicates.or",
    "Predicates.and",
    "EnchantedPredicate",
    "EquippedPredicate",
    "AttackingPredicate",
    "BlockingPredicate",
    "ControlledByControllerPredicate",
)

STATIC_CONTROLLED_PT_IRREGULAR_SUBTYPES = {
    "elves": "elf",
    "dwarves": "dwarf",
    "thallids": "thallid",
    "zombies": "zombie",
    "kithkin": "kithkin",
}


def canonical_static_subtype(value: str) -> str:
    token = re.sub(r"[^a-z0-9]+", " ", str(value or "").strip().lower()).strip()
    if not token:
        return ""
    if token in STATIC_CONTROLLED_PT_IRREGULAR_SUBTYPES:
        return STATIC_CONTROLLED_PT_IRREGULAR_SUBTYPES[token]
    if token.endswith("ies") and len(token) > 3:
        return f"{token[:-3]}y"
    if token.endswith("ves") and len(token) > 3:
        return f"{token[:-3]}f"
    if token.endswith("s") and not token.endswith("ss"):
        return token[:-1]
    return token


def static_controlled_pt_constraints_from_subject(subject: str) -> dict[str, Any] | str:
    phrase = re.sub(r"\s+", " ", str(subject or "").strip().lower())
    if not phrase or phrase == "creatures":
        return {}
    if phrase.endswith(" creatures"):
        phrase = phrase[: -len(" creatures")].strip()
    if not phrase:
        return {}
    words = phrase.split()
    if any(word in STATIC_CONTROLLED_PT_BLOCKED_ORACLE_WORDS for word in words):
        return "static_controlled_pt_oracle_filter_not_supported"
    constraints: dict[str, Any] = {}
    subtypes: list[str] = []
    for word in words:
        if word == "artifact":
            constraints["static_artifact_creature"] = True
            continue
        if word == "legendary":
            constraints["static_required_supertypes"] = ["legendary"]
            continue
        subtype = canonical_static_subtype(word)
        if subtype:
            subtypes.append(subtype)
    if subtypes:
        constraints["static_required_subtypes"] = sorted(set(subtypes))
    return constraints


def static_controlled_pt_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str | None:
    text = strip_leading_parenthetical_reminders(oracle_text(metadata))
    match = re.match(
        r"^(?:each )?(?P<other>other )?(?P<subject>[a-z0-9' -]+?) "
        r"you control get (?P<power>[+-]?\d+)/(?P<toughness>[+-]?\d+)\.?$",
        text,
    )
    if not match:
        return None
    subject = match.group("subject").strip()
    constraints = static_controlled_pt_constraints_from_subject(subject)
    if isinstance(constraints, str):
        return constraints
    power = signed_int_from_oracle(match.group("power"))
    toughness = signed_int_from_oracle(match.group("toughness"))
    if power is None or toughness is None:
        return None
    return {
        "static_power_bonus": power,
        "static_toughness_bonus": toughness,
        "static_exclude_source": bool(match.group("other")),
        **constraints,
    }


def static_controlled_pt_filter_constraints_from_source(source: str, filter_name: str | None) -> dict[str, Any] | str:
    text = source or ""
    if any(marker in text for marker in STATIC_CONTROLLED_PT_BLOCKED_SOURCE_MARKERS):
        return "static_controlled_pt_source_filter_not_supported"
    if not filter_name:
        return {}
    if filter_name == "StaticFilters.FILTER_PERMANENT_CREATURES":
        return {}
    if filter_name == "StaticFilters.FILTER_PERMANENT_SLIVERS":
        return {"static_required_subtypes": ["sliver"]}
    if filter_name == "StaticFilters.FILTER_PERMANENTS_ARTIFACT_CREATURE":
        return {"static_artifact_creature": True}
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", filter_name):
        return "static_controlled_pt_source_filter_not_supported"
    constraints: dict[str, Any] = {}
    subtype_tokens = re.findall(
        rf"{re.escape(filter_name)}\s*=\s*new\s+Filter(?:Creature)?Permanent\s*\(\s*SubType\.([A-Z0-9_]+)",
        text,
    )
    subtype_tokens += re.findall(rf"{re.escape(filter_name)}\.add\s*\(\s*SubType\.([A-Z0-9_]+)\.getPredicate\s*\(\s*\)\s*\)", text)
    if subtype_tokens:
        constraints["static_required_subtypes"] = sorted(
            {canonical_static_subtype(token.replace("_", " ")) for token in subtype_tokens}
        )
    if re.search(rf"{re.escape(filter_name)}\.add\s*\(\s*CardType\.ARTIFACT\.getPredicate\s*\(\s*\)\s*\)", text):
        constraints["static_artifact_creature"] = True
    if re.search(rf"{re.escape(filter_name)}\.add\s*\(\s*SuperType\.LEGENDARY\.getPredicate\s*\(\s*\)\s*\)", text):
        constraints["static_required_supertypes"] = ["legendary"]
    safe_get_predicates = re.findall(rf"{re.escape(filter_name)}\.add\s*\(\s*([A-Za-z]+)\.([A-Z0-9_]+)\.getPredicate", text)
    for owner, value in safe_get_predicates:
        if owner == "SubType":
            continue
        if owner == "CardType" and value == "ARTIFACT":
            continue
        if owner == "SuperType" and value == "LEGENDARY":
            continue
        return "static_controlled_pt_source_filter_not_supported"
    if not constraints and filter_name != "filter":
        return "static_controlled_pt_source_filter_not_supported"
    return constraints


def static_controlled_pt_from_source(source: str) -> dict[str, Any] | str | None:
    text = source or ""
    matches = re.findall(
        r"new\s+BoostControlledEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*,\s*"
        r"Duration\.WhileOnBattlefield(?P<rest>[^)]*)\)",
        text,
        re.S,
    )
    if len(matches) != 1:
        return None
    power_raw, toughness_raw, rest = matches[0]
    rest_text = str(rest or "")
    bool_args = re.findall(r"\b(true|false)\b", rest_text)
    exclude_source = bool_args[-1] == "true" if bool_args else False
    filter_name: str | None = None
    static_filter_match = re.search(r"(StaticFilters\.FILTER_[A-Z0-9_]+)", rest_text)
    if static_filter_match:
        filter_name = static_filter_match.group(1)
    else:
        filter_match = re.search(r",\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:,\s*(?:true|false))?\s*$", rest_text.strip())
        if filter_match:
            candidate = filter_match.group(1)
            if candidate not in {"true", "false"}:
                filter_name = candidate
    constraints = static_controlled_pt_filter_constraints_from_source(text, filter_name)
    if isinstance(constraints, str):
        return constraints
    return {
        "static_power_bonus": int(power_raw),
        "static_toughness_bonus": int(toughness_raw),
        "static_exclude_source": exclude_source,
        **constraints,
    }


STATIC_GRAVEYARD_COUNT_PT_FILTERS = {
    "StaticFilters.FILTER_CARD_ARTIFACTS": ["artifact"],
    "StaticFilters.FILTER_CARD_CREATURES": ["creature"],
    "StaticFilters.FILTER_CARD_ENCHANTMENTS": ["enchantment"],
    "StaticFilters.FILTER_CARD_INSTANTS": ["instant"],
    "StaticFilters.FILTER_CARD_LANDS": ["land"],
    "StaticFilters.FILTER_CARD_SORCERIES": ["sorcery"],
}


def static_graveyard_count_pt_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_after_leading_static_keywords(metadata)
    match = re.match(
        r"^[a-z0-9' ,./-]+ power and toughness are each equal to the number of "
        r"(?P<card_type>artifact|creature|enchantment|instant|land|sorcery) cards in "
        r"(?P<scope>your graveyard|all graveyards)\.?$",
        text,
    )
    if match:
        return {
            "graveyard_count_scope": (
                "controller_graveyard"
                if match.group("scope") == "your graveyard"
                else "all_graveyards"
            ),
            "graveyard_count_card_types": [match.group("card_type")],
        }
    if re.match(
        r"^[a-z0-9' ,./-]+ power and toughness are each equal to the number of cards in all graveyards\.?$",
        text,
    ):
        return {
            "graveyard_count_scope": "all_graveyards",
            "graveyard_count_card_types": ["card"],
        }
    return None


def static_graveyard_count_filter_types_from_source(source: str, filter_name: str | None) -> list[str] | str:
    text = source or ""
    if not filter_name:
        return ["card"]
    if filter_name in STATIC_GRAVEYARD_COUNT_PT_FILTERS:
        return list(STATIC_GRAVEYARD_COUNT_PT_FILTERS[filter_name])
    if filter_name == "new FilterLandCard":
        return ["land"]
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", filter_name):
        return "static_graveyard_count_pt_source_filter_not_supported"
    type_tokens = re.findall(
        rf"{re.escape(filter_name)}\.add\s*\(\s*CardType\.([A-Z0-9_]+)\.getPredicate\s*\(\s*\)\s*\)",
        text,
    )
    if len(type_tokens) == 1:
        return [type_tokens[0].lower().replace("_", " ")]
    return "static_graveyard_count_pt_source_filter_not_supported"


def static_graveyard_count_pt_from_source(source: str) -> dict[str, Any] | str | None:
    text = source or ""
    if (
        "AdditiveDynamicValue" in text
        or "PermanentsOnBattlefieldCount" in text
        or "game.getBattlefield().count" in text
    ):
        return "static_graveyard_count_pt_source_not_direct_graveyard_count"
    if len(re.findall(r"new\s+SetBasePowerToughnessSourceEffect\s*\(", text)) != 1:
        return None
    if "CardsInControllerGraveyardCount" in text:
        scope = "controller_graveyard"
        match = re.search(r"new\s+CardsInControllerGraveyardCount\s*\(\s*([^)]+?)\s*\)", text, re.S)
        filter_name = match.group(1).strip() if match else None
    elif "CardsInAllGraveyardsCount" in text:
        scope = "all_graveyards"
        match = re.search(r"new\s+CardsInAllGraveyardsCount\s*\(\s*(?:new\s+)?([^)]+?)\s*\)", text, re.S)
        filter_name = match.group(1).strip() if match else None
        if filter_name and filter_name.startswith("FilterLandCard"):
            filter_name = "new FilterLandCard"
    elif re.search(r"getMessage\s*\(\s*\).*?cards in all graveyards", text, re.S):
        scope = "all_graveyards"
        filter_name = None
    else:
        return None
    card_types = static_graveyard_count_filter_types_from_source(text, filter_name)
    if isinstance(card_types, str):
        return card_types
    return {
        "graveyard_count_scope": scope,
        "graveyard_count_card_types": card_types or ["card"],
    }


STATIC_GRAVEYARD_THRESHOLD_WORDS = {
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


def static_graveyard_threshold_int(value: str) -> int | None:
    token = str(value or "").strip().lower()
    if token.isdigit():
        return int(token)
    return STATIC_GRAVEYARD_THRESHOLD_WORDS.get(token)


def static_graveyard_threshold_boost_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_after_leading_static_keywords(metadata)
    text = re.sub(r"^(?:threshold|descend\s+\d+)\s*[—-]\s*", "", text).strip()
    match = re.match(
        r"^this creature gets (?P<power>[+-]\d+)/(?P<toughness>[+-]\d+) as long as "
        r"(?:there are (?P<threshold_a>\d+|one|two|three|four|five|six|seven|eight|nine|ten) "
        r"or more (?P<permanent_a>permanent )?cards in your graveyard|"
        r"(?P<threshold_b>\d+|one|two|three|four|five|six|seven|eight|nine|ten) "
        r"or more (?P<permanent_b>permanent )?cards are in your graveyard)\.?$",
        text,
    )
    if not match:
        return None
    threshold = static_graveyard_threshold_int(match.group("threshold_a") or match.group("threshold_b"))
    power_bonus = signed_int_from_oracle(match.group("power"))
    toughness_bonus = signed_int_from_oracle(match.group("toughness"))
    if threshold is None or power_bonus is None or toughness_bonus is None:
        return None
    return {
        "graveyard_count_scope": "controller_graveyard",
        "graveyard_count_card_types": [
            "permanent" if (match.group("permanent_a") or match.group("permanent_b")) else "card"
        ],
        "graveyard_count_threshold": threshold,
        "static_power_bonus": power_bonus,
        "static_toughness_bonus": toughness_bonus,
    }


def static_graveyard_threshold_boost_from_source(source: str) -> dict[str, Any] | str | None:
    text = source or ""
    if len(re.findall(r"new\s+ConditionalContinuousEffect\s*\(", text)) != 1:
        return None
    boost_match = re.search(
        r"new\s+BoostSourceEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*,\s*Duration\.WhileOnBattlefield\s*\)",
        text,
        re.S,
    )
    if not boost_match:
        return "static_graveyard_threshold_boost_source_not_fixed_boost"
    if "ThresholdCondition.instance" in text:
        threshold = 7
        card_types = ["card"]
    elif "DescendCondition.FOUR" in text:
        threshold = 4
        card_types = ["permanent"]
    elif "DeliriumCondition" in text:
        return "static_graveyard_threshold_boost_source_condition_not_supported"
    elif (
        "LessonsInGraveCondition" in text
        or "CardsInOpponentGraveyardCondition" in text
        or "DifferentManaValuesInGraveCondition" in text
    ):
        return "static_graveyard_threshold_boost_source_condition_not_supported"
    else:
        return "static_graveyard_threshold_boost_source_condition_not_supported"
    return {
        "graveyard_count_scope": "controller_graveyard",
        "graveyard_count_card_types": card_types,
        "graveyard_count_threshold": threshold,
        "static_power_bonus": int(boost_match.group(1)),
        "static_toughness_bonus": int(boost_match.group(2)),
    }


def static_graveyard_count_boost_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_after_leading_static_keywords(metadata)
    match = re.match(
        r"^(?:this creature|[a-z0-9' ,./-]+) gets (?P<power>[+-]\d+)/(?P<toughness>[+-]\d+) for each "
        r"(?P<card_type>artifact|creature|artifact and/or enchantment|noncreature, nonland) card in "
        r"(?P<scope>your graveyard|your opponents' graveyards)\.?$",
        text,
    )
    if not match:
        return None
    power_bonus = signed_int_from_oracle(match.group("power"))
    toughness_bonus = signed_int_from_oracle(match.group("toughness"))
    if power_bonus is None or toughness_bonus is None:
        return None
    return {
        "graveyard_count_scope": (
            "controller_graveyard"
            if match.group("scope") == "your graveyard"
            else "opponents_graveyards"
        ),
        "graveyard_count_card_types": {
            "artifact and/or enchantment": ["artifact", "enchantment"],
            "noncreature, nonland": ["noncreature_nonland"],
        }.get(match.group("card_type"), [match.group("card_type")]),
        "static_power_bonus_per_graveyard_count": power_bonus,
        "static_toughness_bonus_per_graveyard_count": toughness_bonus,
    }


def static_graveyard_count_boost_source_filter_types(source: str, expr: str) -> list[str] | str:
    text = source or ""
    value = str(expr or "").strip()
    if "FilterArtifactCard" in value:
        return ["artifact"]
    if "FilterArtifactOrEnchantmentCard" in value:
        return ["artifact", "enchantment"]
    if "FILTER_CARD_CREATURE" in value or "FilterCreatureCard" in value:
        return ["creature"]
    if (
        "noncreature, nonland card" in value
        and re.search(
            r"\.add\s*\(\s*Predicates\.not\s*\(\s*CardType\.CREATURE\.getPredicate\s*\(\s*\)\s*\)\s*\)",
            text,
        )
        and re.search(
            r"\.add\s*\(\s*Predicates\.not\s*\(\s*CardType\.LAND\.getPredicate\s*\(\s*\)\s*\)\s*\)",
            text,
        )
    ):
        return ["noncreature_nonland"]
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
        assignment = re.search(
            rf"(?:FilterCard|FilterCreatureCard|FilterArtifactCard)\s+{re.escape(value)}\s*=([^;]+);",
            text,
            re.S,
        )
        if assignment:
            return static_graveyard_count_boost_source_filter_types(text, assignment.group(1))
    return "static_graveyard_count_boost_source_filter_not_supported"


def static_graveyard_count_boost_source_dynamic_spec(source: str, expr: str) -> dict[str, Any] | str | None:
    text = source or ""
    value = str(expr or "").strip()
    if value == "StaticValue.get(0)":
        return {"static_value": 0}
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value):
        assignment = re.search(
            rf"(?:private\s+static\s+final\s+)?(?:DynamicValue\s+)?{re.escape(value)}\s*=\s*new\s+"
            r"(CardsInControllerGraveyardCount|CardsInOpponentGraveyardsCount)\s*\((.*?)\)\s*;",
            text,
            re.S,
        )
        if assignment:
            scope = (
                "controller_graveyard"
                if assignment.group(1) == "CardsInControllerGraveyardCount"
                else "opponents_graveyards"
            )
            card_types = static_graveyard_count_boost_source_filter_types(text, assignment.group(2))
            if isinstance(card_types, str):
                return card_types
            return {
                "graveyard_count_scope": scope,
                "graveyard_count_card_types": card_types,
            }
    direct = re.match(r"^new\s+CardsInControllerGraveyardCount\s*\((.*)\)$", value, re.S)
    if direct:
        card_types = static_graveyard_count_boost_source_filter_types(text, direct.group(1))
        if isinstance(card_types, str):
            return card_types
        return {
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": card_types,
        }
    return "static_graveyard_count_boost_source_dynamic_not_supported"


def split_top_level_args(arg_text: str) -> list[str]:
    args: list[str] = []
    current: list[str] = []
    depth = 0
    for char in str(arg_text or ""):
        if char == "," and depth == 0:
            args.append("".join(current).strip())
            current = []
            continue
        current.append(char)
        if char == "(":
            depth += 1
        elif char == ")" and depth > 0:
            depth -= 1
    if current:
        args.append("".join(current).strip())
    return args


def extract_constructor_args(source: str, constructor: str) -> str | None:
    needle = f"new {constructor}"
    start = str(source or "").find(needle)
    if start < 0:
        return None
    open_index = str(source or "").find("(", start + len(needle))
    if open_index < 0:
        return None
    depth = 0
    for index in range(open_index, len(source)):
        char = source[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return source[open_index + 1 : index]
    return None


def static_graveyard_count_boost_from_source(source: str) -> dict[str, Any] | str | None:
    text = source or ""
    constructor_args = extract_constructor_args(text, "BoostSourceEffect")
    if constructor_args is None:
        return None
    args = split_top_level_args(constructor_args)
    if len(args) < 3 or args[2] != "Duration.WhileOnBattlefield":
        return "static_graveyard_count_boost_source_not_while_on_battlefield"
    power_spec = static_graveyard_count_boost_source_dynamic_spec(text, args[0])
    toughness_spec = static_graveyard_count_boost_source_dynamic_spec(text, args[1])
    if isinstance(power_spec, str):
        return power_spec
    if isinstance(toughness_spec, str):
        return toughness_spec
    if power_spec is None or toughness_spec is None:
        return "static_graveyard_count_boost_source_dynamic_not_supported"
    count_spec = power_spec if power_spec.get("static_value") is None else toughness_spec
    if count_spec.get("static_value") is not None:
        return "static_graveyard_count_boost_source_dynamic_not_supported"
    for spec in (power_spec, toughness_spec):
        if spec.get("static_value") is None and (
            spec.get("graveyard_count_scope") != count_spec.get("graveyard_count_scope")
            or spec.get("graveyard_count_card_types") != count_spec.get("graveyard_count_card_types")
        ):
            return "static_graveyard_count_boost_source_mixed_counts_not_supported"
    return {
        "graveyard_count_scope": count_spec["graveyard_count_scope"],
        "graveyard_count_card_types": count_spec["graveyard_count_card_types"],
        "static_power_bonus_per_graveyard_count": 0 if power_spec.get("static_value") == 0 else 1,
        "static_toughness_bonus_per_graveyard_count": 0 if toughness_spec.get("static_value") == 0 else 1,
    }


def strip_leading_parenthetical_reminders(text: str) -> str:
    cleaned = str(text or "").strip()
    while True:
        match = re.match(r"^\([^)]*\)\s*", cleaned)
        if not match:
            return cleaned
        cleaned = cleaned[match.end() :].strip()


def strip_parenthetical_reminders(text: str) -> str:
    cleaned = strip_leading_parenthetical_reminders(text)
    return re.sub(r"\s*\([^)]*\)", "", cleaned).strip()


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


def fixed_boost_controlled_from_oracle(metadata: dict[str, Any]) -> tuple[int, int] | str | None:
    text = strip_leading_parenthetical_reminders(oracle_text(metadata))
    if "choose one" in text.lower() or "+x/" in text.lower() or "/+x" in text.lower():
        return "boost_controlled_oracle_not_simple"
    match = re.match(
        r"^creatures you control get ([+-]?\d+)/([+-]?\d+) until end of turn\.?$",
        text,
        re.I,
    )
    if not match:
        return None
    power = signed_int_from_oracle(match.group(1))
    toughness = signed_int_from_oracle(match.group(2))
    if power is None or toughness is None:
        return None
    return power, toughness


def fixed_boost_controlled_from_source(source: str) -> tuple[int, int] | str | None:
    text = source or ""
    matches = re.findall(
        r"new\s+BoostControlledEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*,\s*"
        r"Duration\.EndOfTurn(?P<rest>[^)]*)\)",
        text,
        re.S,
    )
    if len(matches) != 1:
        return None
    power_raw, toughness_raw, rest = matches[0]
    rest_text = str(rest or "")
    if rest_text.strip():
        if "StaticFilters.FILTER_PERMANENT_CREATURES" not in rest_text:
            return "boost_controlled_source_filter_not_supported"
        if any(marker in text for marker in STATIC_CONTROLLED_PT_BLOCKED_SOURCE_MARKERS):
            return "boost_controlled_source_filter_not_supported"
    return int(power_raw), int(toughness_raw)


def fixed_boost_keyword_target_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, str, str] | None:
    text = strip_parenthetical_reminders(oracle_text(metadata))
    keyword_words = "|".join(re.escape(word) for word in sorted(TARGET_GRANT_KEYWORD_ORACLE_WORDS, key=len, reverse=True))
    match = re.match(
        rf"^target creature( you control)? gets ([+-]?\d+)/([+-]?\d+) and gains ({keyword_words}) until end of turn\.?$",
        text,
    )
    if not match:
        return None
    power = signed_int_from_oracle(match.group(2))
    toughness = signed_int_from_oracle(match.group(3))
    if power is None or toughness is None:
        return None
    target_controller = "self" if match.group(1) else "any"
    keyword = TARGET_GRANT_KEYWORD_ORACLE_WORDS[match.group(4)]
    return power, toughness, keyword, target_controller


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


def is_permanent_activated_life_gain_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != LIFE_UNIT:
        return False
    return (
        effect_classes(row) == {"GainLifeEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_creature_etb_draw_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DRAW_ENGINE_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"DrawCardSourceControllerEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []).issubset({"draw", "triggered_ability"})
    )


def is_permanent_activated_draw_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DRAW_ENGINE_UNIT:
        return False
    return (
        effect_classes(row) == {"DrawCardSourceControllerEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_draw_discard_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DRAW_ENGINE_UNIT:
        return False
    return (
        effect_classes(row) == {"DrawDiscardControllerEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_damage_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DAMAGE_UNIT:
        return False
    return (
        effect_classes(row) == {"DamageTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_destroy_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DESTROY_UNIT:
        return False
    return (
        effect_classes(row) == {"DestroyTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_self_boost_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != SELF_BOOST_ACTIVATED_UNIT:
        return False
    return (
        effect_classes(row) == {"BoostSourceEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_target_boost_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != TARGET_BOOST_ACTIVATED_UNIT:
        return False
    return (
        effect_classes(row) == {"BoostTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and set(row.get("xmage_signals") or []) == {"targeting", "activated_ability"}
    )


def is_static_controlled_pt_unit(row: dict[str, Any]) -> bool:
    return (
        str(row.get("adapter_work_unit") or "") == STATIC_CONTROLLED_PT_UNIT
        and effect_classes(row) == {"BoostControlledEffect"}
        and ability_classes(row) == {"SimpleStaticAbility"}
        and set(row.get("xmage_signals") or []) == {"static_ability"}
    )


def is_static_graveyard_count_pt_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    remaining = abilities - {"SimpleStaticAbility"}
    return (
        effect_classes(row) == {"SetBasePowerToughnessSourceEffect"}
        and "SimpleStaticAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"static_ability"}
    )


def is_static_graveyard_threshold_boost_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    remaining = abilities - {"SimpleStaticAbility"}
    return (
        str(row.get("adapter_work_unit") or "") == RECURSION_UNIT
        and effect_classes(row) == {"BoostSourceEffect", "ConditionalContinuousEffect"}
        and "SimpleStaticAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"condition", "static_ability"}
    )


def is_static_graveyard_count_boost_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    remaining = abilities - {"SimpleStaticAbility"}
    return (
        str(row.get("adapter_work_unit") or "") == RECURSION_UNIT
        and effect_classes(row) == {"BoostSourceEffect"}
        and "SimpleStaticAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"static_ability"}
    )


def is_permanent_activated_recursion_to_hand_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    return (
        effect_classes(row) == {"ReturnFromGraveyardToHandTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_recursion_to_battlefield_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    return (
        effect_classes(row) == {"ReturnFromGraveyardToBattlefieldTargetEffect"}
        and abilities in (
            {"SimpleActivatedAbility"},
            {"ActivateAsSorceryActivatedAbility"},
        )
        and "activated_ability" in set(row.get("xmage_signals") or [])
    )


def is_permanent_activated_graveyard_exile_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    return (
        effect_classes(row) == {"ExileTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and set(row.get("xmage_signals") or []) == {"targeting", "activated_ability"}
    )


def is_permanent_activated_graveyard_to_library_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"SimpleActivatedAbility"}
    return (
        effect_classes(row) == {"PutOnLibraryTargetEffect"}
        and "SimpleActivatedAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"targeting", "activated_ability"}
    )


def is_creature_dies_draw_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DRAW_ENGINE_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"DiesSourceTriggeredAbility"}
    return (
        effect_classes(row) == {"DrawCardSourceControllerEffect"}
        and "DiesSourceTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []).issubset({"draw", "triggered_ability"})
    )


def is_spell_cast_draw_engine_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DRAW_ENGINE_UNIT:
        return False
    return (
        effect_classes(row) == {"DrawCardSourceControllerEffect"}
        and ability_classes(row) == {"SpellCastControllerTriggeredAbility"}
        and set(row.get("xmage_signals") or []) == {"draw", "triggered_ability"}
    )


def is_creature_dies_recursion_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"DiesSourceTriggeredAbility"}
    return (
        effect_classes(row) == {"ReturnFromGraveyardToHandTargetEffect"}
        and "DiesSourceTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"targeting", "triggered_ability"}
    )


def is_creature_etb_damage_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DAMAGE_UNIT:
        return False
    return (
        effect_classes(row) == {"DamageTargetEffect"}
        and ability_classes(row) == {"EntersBattlefieldTriggeredAbility"}
        and set(row.get("xmage_signals") or []) == {"targeting", "triggered_ability"}
    )


def is_creature_etb_destroy_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DESTROY_UNIT:
        return False
    return (
        effect_classes(row) == {"DestroyTargetEffect"}
        and ability_classes(row) == {"EntersBattlefieldTriggeredAbility"}
        and set(row.get("xmage_signals") or []) == {"targeting", "triggered_ability"}
    )


def is_creature_etb_recursion_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"ReturnFromGraveyardToHandTargetEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"targeting", "triggered_ability"}
    )


def is_creature_etb_mill_then_return_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"triggered_ability"}
    )


def is_creature_etb_graveyard_to_library_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"PutOnLibraryTargetEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"targeting", "triggered_ability"}
    )


def is_creature_etb_library_pick_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"LookLibraryAndPickControllerEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"triggered_ability"}
    )


def is_creature_etb_token_unit(row: dict[str, Any]) -> bool:
    return (
        str(row.get("adapter_work_unit") or "") == ETB_TOKEN_CREATURE_UNIT
        and effect_classes(row) == {"CreateTokenEffect"}
        and ability_classes(row) == {"EntersBattlefieldTriggeredAbility"}
        and set(row.get("xmage_signals") or []) == {"token", "triggered_ability"}
    )


def is_creature_etb_add_counters_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != ADD_COUNTERS_TARGET_UNIT:
        return False
    abilities = ability_classes(row)
    remaining = abilities - {"EntersBattlefieldTriggeredAbility"}
    return (
        effect_classes(row) == {"AddCountersTargetEffect"}
        and "EntersBattlefieldTriggeredAbility" in abilities
        and remaining.issubset(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        and set(row.get("xmage_signals") or []) == {"targeting", "counter", "triggered_ability"}
    )


def is_creature_tap_damage_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != DAMAGE_UNIT:
        return False
    return (
        effect_classes(row) == {"DamageTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
        and set(row.get("xmage_signals") or []) == {"targeting", "activated_ability"}
    )


def is_boost_keyword_spell_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    return (
        str(row.get("adapter_work_unit") or "") == BOOST_KEYWORD_UNIT
        and effect_classes(row) == {"BoostTargetEffect", "GainAbilityTargetEffect"}
        and set(row.get("xmage_signals") or []) == {"targeting"}
        and len(abilities) == 1
        and next(iter(abilities)) in TARGET_GRANT_KEYWORD_ABILITY_CLASSES
    )


def is_permanent_activated_target_keyword_unit(row: dict[str, Any]) -> bool:
    abilities = ability_classes(row)
    keyword_abilities = abilities.intersection(TARGET_GRANT_KEYWORD_ABILITY_CLASSES)
    return (
        str(row.get("adapter_work_unit") or "") == BOOST_KEYWORD_UNIT
        and effect_classes(row) == {"GainAbilityTargetEffect"}
        and set(row.get("xmage_signals") or []) == {"targeting", "activated_ability"}
        and "SimpleActivatedAbility" in abilities
        and len(keyword_abilities) == 1
        and len(abilities - {"SimpleActivatedAbility"} - keyword_abilities) == 0
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


def oracle_text_after_leading_static_keywords(metadata: dict[str, Any]) -> str:
    raw = str(metadata.get("oracle_text") or "").strip()
    if not raw:
        return ""
    allowed = set(STATIC_SELF_KEYWORD_ABILITY_CLASSES.values())
    kept: list[str] = []
    skipping_keywords = True
    for line in raw.splitlines():
        cleaned = re.sub(r"\([^)]*\)", "", line).strip().rstrip(".")
        parts = [
            normalize_keyword_phrase(part)
            for part in re.split(r"[,;]", cleaned)
            if str(part or "").strip()
        ]
        if skipping_keywords and parts and all(part in allowed for part in parts):
            continue
        skipping_keywords = False
        kept.append(line)
    return re.sub(r"\s+", " ", "\n".join(kept).strip()).lower()


def damage_target_from_oracle(metadata: dict[str, Any]) -> str | None:
    text = oracle_text(metadata)
    restricted = restricted_battlefield_target_from_oracle(metadata, "damage")
    if restricted is not None:
        return restricted
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


def restricted_target_base(target: str) -> str:
    if target in {
        "attacking_creature",
        "blocking_creature",
        "attacking_or_blocking_creature",
        "tapped_creature",
        "untapped_creature",
        "flying_creature",
        "nonblack_creature",
        "black_creature",
        "green_or_white_creature",
        "nonartifact_creature",
        "nonartifact_nonblack_creature",
        "legendary_creature",
        "monocolored_creature",
        "blue_or_black_flying_creature",
        "creature_power_3_or_greater",
        "creature_power_4_or_greater",
        "creature_mana_value_3_or_greater",
    }:
        return "creature"
    if target in {"black_or_red_permanent", "nonwhite_permanent", "noncreature_permanent"}:
        return "permanent"
    if target == "noncreature_artifact":
        return "artifact"
    return target


def restricted_battlefield_target_from_oracle(metadata: dict[str, Any], action: str) -> str | None:
    text = oracle_text(metadata)
    if action == "damage":
        prefix = r"^.+ deals \d+ damage to "
        suffix = r"(?:\.|$)"
    elif action == "destroy":
        prefix = r"^destroy "
        suffix = r"\.?$"
    elif action == "exile":
        prefix = r"^exile "
        suffix = r"\.?$"
    else:
        return None
    patterns: list[tuple[str, str]] = [
        (r"target attacking or blocking creature", "attacking_or_blocking_creature"),
        (r"target attacking creature", "attacking_creature"),
        (r"target blocking creature", "blocking_creature"),
        (r"target tapped creature", "tapped_creature"),
        (r"target untapped creature", "untapped_creature"),
        (r"target creature with flying", "flying_creature"),
        (r"target nonartifact, nonblack creature(?:\. it can't be regenerated)?", "nonartifact_nonblack_creature"),
        (r"target nonartifact creature", "nonartifact_creature"),
        (r"target nonblack creature(?:\. it can't be regenerated)?", "nonblack_creature"),
        (r"target black creature", "black_creature"),
        (r"target green or white creature", "green_or_white_creature"),
        (r"target legendary creature", "legendary_creature"),
        (r"target monocolored creature", "monocolored_creature"),
        (r"target noncreature permanent", "noncreature_permanent"),
        (r"target noncreature artifact", "noncreature_artifact"),
        (r"target blue or black creature with flying", "blue_or_black_flying_creature"),
        (r"target black or red permanent", "black_or_red_permanent"),
        (r"target nonwhite permanent", "nonwhite_permanent"),
        (r"target creature with power 3 or greater", "creature_power_3_or_greater"),
        (r"target creature with power 4 or greater", "creature_power_4_or_greater"),
        (r"target creature with (?:mana value|converted mana cost) 3 or greater", "creature_mana_value_3_or_greater"),
    ]
    for target_pattern, target in patterns:
        if re.match(prefix + target_pattern + suffix, text):
            return target
    return None


def restricted_battlefield_target_from_source(source: str) -> str | None:
    text = source or ""
    if re.search(r"new\s+TargetAttackingOrBlockingCreature\s*\(", text) or "FilterAttackingOrBlockingCreature" in text:
        return "attacking_or_blocking_creature"
    if re.search(r"new\s+TargetAttackingCreature\s*\(", text) or "FilterAttackingCreature" in text:
        return "attacking_creature"
    if re.search(r"new\s+TargetBlockingCreature\s*\(", text) or "FilterBlockingCreature" in text:
        return "blocking_creature"
    if "TappedPredicate.TAPPED" in text:
        return "tapped_creature"
    if "TappedPredicate.UNTAPPED" in text:
        return "untapped_creature"
    if (
        "FilterCreaturePermanent(\"nonartifact, nonblack creature\")" in text
        or "nonartifact, nonblack creature" in text
    ):
        return "nonartifact_nonblack_creature"
    if (
        "FilterCreaturePermanent(\"nonartifact creature\")" in text
        or "nonartifact creature" in text
    ):
        return "nonartifact_creature"
    if (
        "FILTER_PERMANENT_CREATURE_NON_BLACK" in text
        or "FILTER_CREATURE_NON_BLACK" in text
        or 'FilterCreaturePermanent("nonblack creature")' in text
        or "nonblack creature" in text
    ):
        return "nonblack_creature"
    if 'FilterCreaturePermanent("black creature")' in text or "black creature" in text:
        return "black_creature"
    if 'FilterCreaturePermanent("green or white creature")' in text or "green or white creature" in text:
        return "green_or_white_creature"
    if 'FilterCreaturePermanent("legendary creature")' in text or "legendary creature" in text:
        return "legendary_creature"
    if 'FilterCreaturePermanent("monocolored creature")' in text or "monocolored creature" in text:
        return "monocolored_creature"
    if "FILTER_PERMANENT_NON_CREATURE" in text or "noncreature permanent" in text:
        return "noncreature_permanent"
    if 'FilterArtifactPermanent("noncreature artifact")' in text or "noncreature artifact" in text:
        return "noncreature_artifact"
    if (
        "ObjectColor.BLUE" in text
        and "ObjectColor.BLACK" in text
        and "AbilityPredicate(FlyingAbility.class)" in text
    ):
        return "blue_or_black_flying_creature"
    if "FILTER_CREATURE_FLYING" in text or "AbilityPredicate(FlyingAbility.class)" in text:
        return "flying_creature"
    if "ObjectColor.BLACK" in text and "ObjectColor.RED" in text and "FilterPermanent(\"black or red permanent\")" in text:
        return "black_or_red_permanent"
    if 'FilterPermanent("nonwhite permanent")' in text or "nonwhite permanent" in text:
        return "nonwhite_permanent"
    if "PowerPredicate(ComparisonType.MORE_THAN, 2)" in text:
        return "creature_power_3_or_greater"
    if "PowerPredicate(ComparisonType.MORE_THAN, 3)" in text:
        return "creature_power_4_or_greater"
    if "ManaValuePredicate(ComparisonType.MORE_THAN, 2)" in text:
        return "creature_mana_value_3_or_greater"
    return None


def source_matches_target_constraint(source: str, target: str) -> bool:
    base = restricted_target_base(target)
    if base == target:
        return True
    return restricted_battlefield_target_from_source(source) == target


def fixed_damage_gain_life_from_source(source: str) -> tuple[int, int, str] | None:
    text = source or ""
    if has_additional_cost(text):
        return None
    damage_matches = re.findall(r"new\s+DamageTargetEffect\s*\(\s*(\d+)\s*\)", text, re.S)
    life_matches = re.findall(r"new\s+GainLifeEffect\s*\(\s*(\d+)\s*\)", text, re.S)
    if len(damage_matches) != 1 or len(life_matches) != 1:
        return None
    if "TargetPointer" in text or ".setTargetPointer" in text:
        return None
    target_classes = re.findall(r"new\s+(Target\w+)\s*\(", text)
    supported_targets = [
        target_class
        for target_class in target_classes
        if target_class
        in {
            "TargetAnyTarget",
            "TargetCreaturePermanent",
            "TargetCreatureOrPlaneswalker",
        }
    ]
    if len(target_classes) != 1 or len(supported_targets) != 1:
        return None
    target_map = {
        "TargetAnyTarget": "any_target",
        "TargetCreaturePermanent": "creature",
        "TargetCreatureOrPlaneswalker": "creature_or_planeswalker",
    }
    return int(damage_matches[0]), int(life_matches[0]), target_map[supported_targets[0]]


def fixed_damage_gain_life_from_oracle(metadata: dict[str, Any]) -> tuple[int, int, str] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^.+ deals (\d+) damage to "
        r"(any target|target creature|target creature or planeswalker)"
        r"(?: and you gain|\. you gain) (\d+) life\.?$",
        text,
    )
    if not match:
        return None
    target_map = {
        "any target": "any_target",
        "target creature": "creature",
        "target creature or planeswalker": "creature_or_planeswalker",
    }
    return int(match.group(1)), int(match.group(3)), target_map[match.group(2)]


def activated_tap_damage_from_oracle(metadata: dict[str, Any]) -> tuple[int, str] | None:
    text = oracle_text(metadata)
    match = re.match(
        r"^\{t\}: [^.]+ deals (\d+) damage to (any target|target opponent|target player|target creature or planeswalker|target creature)\.?$",
        text,
    )
    if not match:
        return None
    target_phrase = match.group(2)
    target_map = {
        "any target": "any_target",
        "target opponent": "opponent",
        "target player": "player",
        "target creature or planeswalker": "creature_or_planeswalker",
        "target creature": "creature",
    }
    return int(match.group(1)), target_map[target_phrase]


def activated_tap_damage_amount_from_source(source: str) -> int | None:
    if has_additional_cost(source):
        return None
    if re.search(r"\b(ManaCostsImpl|GenericManaCost|ColoredManaCost|Sacrifice)", source or ""):
        return None
    match = re.search(
        r"new\s+SimpleActivatedAbility\s*\(\s*new\s+DamageTargetEffect\s*\(\s*(\d+)\s*(?:,\s*\"[^\"]*\")?\s*\)\s*,\s*new\s+TapSourceCost\s*\(\s*\)\s*\)",
        source or "",
        re.S,
    )
    if not match:
        return None
    return int(match.group(1))


def activated_draw_count_from_oracle(metadata: dict[str, Any]) -> int | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if ":" not in text:
        return None
    effect_text = text.rsplit(":", 1)[1].strip()
    match = re.match(r"^draw (a|one|two|three|four|five|\d+) cards?\.?$", effect_text)
    if not match:
        return None
    value = match.group(1)
    words = {"a": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    if value in words:
        return words[value]
    return int(value)


def activation_sacrifice_target_from_phrase(phrase: str) -> str | None:
    normalized = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    normalized = normalized.removeprefix("a ").removeprefix("an ")
    normalized = normalized.removeprefix("another ")
    mapping = {
        "artifact or creature": "artifact_or_creature",
        "artifact or land": "artifact_or_land",
        "creature or enchantment": "creature_or_enchantment",
        "creature or land": "creature_or_land",
        "creature or planeswalker": "creature_or_planeswalker",
        "nontoken permanent": "nontoken_permanent",
        "non-token permanent": "nontoken_permanent",
        "token": "token",
        "creature": "creature",
        "artifact": "artifact",
        "enchantment": "enchantment",
        "land": "land",
        "swamp": "swamp",
        "permanent": "permanent",
    }
    return mapping.get(normalized)


def activated_draw_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_draw_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    match = re.fullmatch(r"draw (a|one|two|three|four|five|\d+) cards?\.?", effect_text)
    if not match:
        return "activated_draw_oracle_not_simple"
    value = match.group(1)
    words = {"a": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    count = words.get(value, int(value) if value.isdigit() else 0)
    if count <= 0:
        return "activated_draw_oracle_not_simple"

    normalized_cost = cost_text
    life_cost = 0
    life_pattern = r"(?:^|,\s*)pay (?P<life>\d+) life(?:\s*,?|$)"
    life_matches = list(re.finditer(life_pattern, normalized_cost))
    if len(life_matches) > 1:
        return "activated_draw_oracle_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0].group("life"))
        normalized_cost = re.sub(life_pattern, ",", normalized_cost).strip(" ,")

    sacrifice_target = None
    sacrifice_pattern = (
        r"(?:^|,\s*)sacrifice (?P<phrase>"
        r"(?:an?|another) (?:artifact or creature|artifact or land|creature or land|"
        r"nontoken permanent|non-token permanent|token|creature|artifact|enchantment|land|permanent)"
        r")(?:\s*,?|$)"
    )
    sacrifice_matches = list(re.finditer(sacrifice_pattern, normalized_cost))
    if len(sacrifice_matches) > 1:
        return "activated_draw_oracle_cost_not_supported"
    if sacrifice_matches:
        sacrifice_target = activation_sacrifice_target_from_phrase(sacrifice_matches[0].group("phrase"))
        if sacrifice_target is None:
            return "activated_draw_oracle_cost_not_supported"
        normalized_cost = re.sub(sacrifice_pattern, ",", normalized_cost).strip(" ,")

    activation = activation_cost_from_oracle_prefix(normalized_cost, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_draw")
    if activation.get("activation_requires_sacrifice") and sacrifice_target:
        return "activated_draw_oracle_cost_not_supported"
    activation["count"] = count
    if life_cost:
        activation["activation_life_cost"] = life_cost
    if sacrifice_target:
        activation["activation_sacrifice_target"] = sacrifice_target
        activation["activation_requires_sacrifice_target"] = True
    return activation


def number_word_to_int(value: str) -> int:
    normalized = str(value or "").strip().lower()
    words = {"a": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    return words.get(normalized, int(normalized) if normalized.isdigit() else 0)


def activated_draw_discard_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_draw_discard_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    match = re.fullmatch(
        r"draw (a|one|two|three|four|five|\d+) cards?, then discard "
        r"(a|one|two|three|four|five|\d+) cards?\.?",
        effect_text,
    )
    if not match:
        return "activated_draw_discard_oracle_not_simple"
    draw_count = number_word_to_int(match.group(1))
    discard_count = number_word_to_int(match.group(2))
    if draw_count <= 0 or discard_count <= 0:
        return "activated_draw_discard_oracle_not_simple"

    normalized_cost = cost_text
    life_cost = 0
    life_pattern = r"(?:^|,\s*)pay (?P<life>\d+) life(?:\s*,?|$)"
    life_matches = list(re.finditer(life_pattern, normalized_cost))
    if len(life_matches) > 1:
        return "activated_draw_discard_oracle_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0].group("life"))
        normalized_cost = re.sub(life_pattern, ",", normalized_cost).strip(" ,")

    sacrifice_target = None
    sacrifice_pattern = (
        r"(?:^|,\s*)sacrifice (?P<phrase>"
        r"(?:an?|another) (?:artifact or creature|artifact or land|creature or land|"
        r"nontoken permanent|non-token permanent|token|creature|artifact|enchantment|land|permanent)"
        r")(?:\s*,?|$)"
    )
    sacrifice_matches = list(re.finditer(sacrifice_pattern, normalized_cost))
    if len(sacrifice_matches) > 1:
        return "activated_draw_discard_oracle_cost_not_supported"
    if sacrifice_matches:
        sacrifice_target = activation_sacrifice_target_from_phrase(sacrifice_matches[0].group("phrase"))
        if sacrifice_target is None:
            return "activated_draw_discard_oracle_cost_not_supported"
        normalized_cost = re.sub(sacrifice_pattern, ",", normalized_cost).strip(" ,")

    source_name = str(metadata.get("name") or "").split("//", 1)[0].strip().lower()
    if source_name:
        source_name_pattern = re.escape(source_name)
        if re.fullmatch(rf"sacrifice {source_name_pattern}", normalized_cost):
            normalized_cost = "sacrifice this permanent"

    activation = activation_cost_from_oracle_prefix(normalized_cost, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_draw_discard")
    if activation.get("activation_requires_sacrifice") and sacrifice_target:
        return "activated_draw_discard_oracle_cost_not_supported"
    activation["draw_count"] = draw_count
    activation["discard_count"] = discard_count
    if life_cost:
        activation["activation_life_cost"] = life_cost
    if sacrifice_target:
        activation["activation_sacrifice_target"] = sacrifice_target
        activation["activation_requires_sacrifice_target"] = True
    return activation


def activated_recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> tuple[str, int, bool] | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return None
    return recursion_to_hand_from_text(text.rsplit(":", 1)[1].strip())


def activated_recursion_to_hand_activation_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_recursion_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    target = recursion_to_hand_from_text(effect_text)
    if target is None:
        return "activated_recursion_oracle_not_simple"
    normalized_cost = cost_text
    life_cost = 0
    life_pattern = r"(?:^|,\s*)pay (?P<life>\d+) life(?:\s*,?|$)"
    life_matches = list(re.finditer(life_pattern, normalized_cost))
    if len(life_matches) > 1:
        return "activated_recursion_oracle_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0].group("life"))
        normalized_cost = re.sub(life_pattern, ",", normalized_cost).strip(" ,")

    sacrifice_target = None
    sacrifice_pattern = (
        r"(?:^|,\s*)sacrifice (?P<phrase>"
        r"(?:an?|another) (?:artifact or creature|artifact or land|creature or land|"
        r"nontoken permanent|non-token permanent|token|creature|artifact|enchantment|land|swamp|permanent)"
        r")(?:\s*,?|$)"
    )
    sacrifice_matches = list(re.finditer(sacrifice_pattern, normalized_cost))
    if len(sacrifice_matches) > 1:
        return "activated_recursion_oracle_cost_not_supported"
    if sacrifice_matches:
        sacrifice_target = activation_sacrifice_target_from_phrase(sacrifice_matches[0].group("phrase"))
        if sacrifice_target is None:
            return "activated_recursion_oracle_cost_not_supported"
        normalized_cost = re.sub(sacrifice_pattern, ",", normalized_cost).strip(" ,")

    discard_count = 0
    discard_target = None
    discard_patterns = [
        (r"(?:^|,\s*)discard a creature card(?:\s*,?|$)", "creature_card"),
        (r"(?:^|,\s*)discard a card(?:\s*,?|$)", "any_card"),
    ]
    for pattern, target_type in discard_patterns:
        matches = re.findall(pattern, normalized_cost)
        if matches:
            if len(matches) != 1 or discard_count:
                return "activated_recursion_oracle_cost_not_supported"
            normalized_cost = re.sub(pattern, ",", normalized_cost).strip(" ,")
            discard_count = 1
            discard_target = target_type
            break
    if "discard" in normalized_cost:
        return "activated_recursion_oracle_cost_not_supported"
    activation = activation_cost_from_oracle_prefix(normalized_cost, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_recursion")
    if activation.get("activation_requires_sacrifice") and sacrifice_target:
        return "activated_recursion_oracle_cost_not_supported"
    target_type, count, up_to = target
    result = {
        "target": target_type,
        "count": count,
        "up_to": up_to,
        **activation,
        "activation_discard_count": discard_count,
        "activation_discard_target": discard_target,
    }
    if life_cost:
        result["activation_life_cost"] = life_cost
    if sacrifice_target:
        result["activation_sacrifice_target"] = sacrifice_target
        result["activation_requires_sacrifice_target"] = True
    return result


def parse_mana_cost_text(cost_text: str) -> tuple[int, list[str]] | None:
    generic = 0
    colors: list[str] = []
    for symbol in re.findall(r"\{([^}]+)\}", cost_text or ""):
        normalized = str(symbol or "").strip().upper()
        if normalized.isdigit():
            generic += int(normalized)
        elif normalized in {"W", "U", "B", "R", "G"}:
            colors.append(normalized)
        else:
            return None
    return generic, colors


def canonical_mana_cost_text(cost_text: str) -> str:
    return re.sub(
        r"\{([^}]+)\}",
        lambda match: "{" + match.group(1).strip().upper() + "}",
        str(cost_text or "").strip(),
    )


def graveyard_self_return_to_hand_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip().lower()
    enters_tapped = False
    if text.startswith("this creature enters tapped. "):
        enters_tapped = True
        text = text.removeprefix("this creature enters tapped. ").strip()
    match = re.fullmatch(
        r"(?P<cost>(?:\{[0-9wubrg]\})+)(?:,\s*discard (?P<discard_target>a creature card))?: return this card from your graveyard to your hand(?:\.?\s*activate (?:this ability )?only (?P<timing>as a sorcery|any time you could cast a sorcery))?\.?",
        text,
    )
    if not match:
        return "graveyard_self_return_oracle_not_simple"
    cost_text = canonical_mana_cost_text(match.group("cost"))
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "graveyard_self_return_oracle_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "enters_tapped": enters_tapped,
        "activation_timing": "sorcery" if match.group("timing") else None,
        "activation_discard_count": 1 if match.group("discard_target") else 0,
        "activation_discard_target": "creature_card" if match.group("discard_target") else None,
    }


def graveyard_self_return_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip().lower()
    static_cant_block = False
    card_name = re.sub(r"\s+", " ", str(metadata.get("name") or "").strip().lower())
    cant_block_prefixes = [
        f"{card_name} can't block. " if card_name else "",
        "this creature can't block. ",
        "this card can't block. ",
    ]
    for prefix in cant_block_prefixes:
        if prefix and text.startswith(prefix):
            static_cant_block = True
            text = text.removeprefix(prefix).strip()
            break
    match = re.fullmatch(
        r"(?P<cost>(?:\{[0-9wubrg]\})+)(?:,\s*(?P<additional>(?:discard (?P<discard_count>two) cards?)|(?:exile (?:(?P<exile_count_word>seven|two) (?P<exile_other>other )?(?P<exile_target>creature cards|cards)|(?P<exile_another>another) (?P<exile_another_target>creature card)) from your graveyard)))?: return this card from your graveyard to the battlefield(?P<tapped> tapped)?\.?",
        text,
    )
    if not match:
        return "graveyard_self_return_battlefield_oracle_not_simple"
    cost_text = canonical_mana_cost_text(match.group("cost"))
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "graveyard_self_return_battlefield_oracle_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    result = {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "enters_tapped": bool(match.group("tapped")),
        "static_cant_block": static_cant_block,
    }
    if match.group("discard_count"):
        result["activation_discard_count"] = 2
        result["activation_discard_target"] = "any_card"
    else:
        result["activation_discard_count"] = 0
        result["activation_discard_target"] = None
    result["activation_exile_from_graveyard_count"] = 0
    result["activation_exile_from_graveyard_target"] = None
    result["activation_exile_from_graveyard_other"] = False
    if match.group("exile_count_word") or match.group("exile_another"):
        if match.group("exile_another"):
            exile_count = 1
            exile_target_text = match.group("exile_another_target")
            exile_other = True
        else:
            exile_count = {"two": 2, "seven": 7}[match.group("exile_count_word")]
            exile_target_text = match.group("exile_target")
            exile_other = bool(match.group("exile_other"))
        result["activation_exile_from_graveyard_count"] = exile_count
        result["activation_exile_from_graveyard_target"] = (
            "creature_card" if "creature" in str(exile_target_text or "") else "any_card"
        )
        result["activation_exile_from_graveyard_other"] = exile_other
    return result


def graveyard_self_return_to_hand_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    effect_matches = list(re.finditer(r"new\s+ReturnSourceFromGraveyardToHandEffect\s*\(", text))
    if len(effect_matches) != 1:
        return "graveyard_self_return_source_not_single_effect"
    effect_index = effect_matches[0].start()
    ability_matches = list(
        re.finditer(r"new\s+(SimpleActivatedAbility|ActivateAsSorceryActivatedAbility)\b", text[:effect_index])
    )
    ability_index = ability_matches[-1].start() if ability_matches else -1
    if ability_index < 0:
        return "graveyard_self_return_source_not_simple_activated"
    ability_class = ability_matches[-1].group(1)
    window = text[ability_index : effect_index + 1400]
    if "Zone.GRAVEYARD" not in window:
        return "graveyard_self_return_source_not_graveyard_zone"
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "ReturnToHandTargetCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapSourceCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = []
    for cost in risky_cost_classes:
        if cost == "ExileFrom":
            if re.search(r"\bExileFrom\s*\(", window):
                present_risky.append(cost)
            continue
        if cost in window:
            present_risky.append(cost)
    present_risky = sorted(present_risky)
    if present_risky:
        return "graveyard_self_return_source_cost_not_supported"
    discard_count = 0
    discard_target = None
    if "DiscardTargetCost" in window:
        discard_matches = re.findall(
            r"new\s+DiscardTargetCost\s*\(\s*new\s+TargetCardInHand\s*\(\s*StaticFilters\.FILTER_CARD_CREATURE_A\s*\)\s*\)",
            window,
        )
        if len(discard_matches) != 1:
            return "graveyard_self_return_source_cost_not_supported"
        discard_count = 1
        discard_target = "creature_card"
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if len(mana_matches) + len(generic_matches) != 1:
        return "graveyard_self_return_source_cost_not_supported"
    cost_text = canonical_mana_cost_text(
        mana_matches[0] if mana_matches else "{" + generic_matches[0] + "}"
    )
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "graveyard_self_return_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_timing": "sorcery" if ability_class == "ActivateAsSorceryActivatedAbility" else None,
        "activation_discard_count": discard_count,
        "activation_discard_target": discard_target,
    }


def graveyard_self_return_to_battlefield_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    effect_matches = list(re.finditer(r"new\s+ReturnSourceFromGraveyardToBattlefieldEffect\s*\(", text))
    if len(effect_matches) != 1:
        return "graveyard_self_return_battlefield_source_not_single_effect"
    effect_index = effect_matches[0].start()
    ability_index = text.rfind("new SimpleActivatedAbility", 0, effect_index)
    if ability_index < 0:
        return "graveyard_self_return_battlefield_source_not_simple_activated"
    window = text[ability_index : effect_index + 1400]
    if "Zone.GRAVEYARD" not in window:
        return "graveyard_self_return_battlefield_source_not_graveyard_zone"
    tapped_match = re.search(
        r"ReturnSourceFromGraveyardToBattlefieldEffect\s*\(\s*(true|false)\b",
        window,
    )
    if not tapped_match:
        return "graveyard_self_return_battlefield_source_tapped_mismatch"
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "ExileFrom",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "ReturnToHandTargetCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapSourceCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = []
    for cost in risky_cost_classes:
        if cost == "ExileFrom":
            if re.search(r"\bExileFrom\s*\(", window):
                present_risky.append(cost)
            continue
        if cost in window:
            present_risky.append(cost)
    present_risky = sorted(present_risky)
    if present_risky:
        return "graveyard_self_return_battlefield_source_cost_not_supported"
    discard_count = 0
    discard_target = None
    exile_count = 0
    exile_target = None
    exile_other = False
    if "DiscardTargetCost" in window:
        discard_matches = re.findall(
            r"new\s+DiscardTargetCost\s*\(\s*new\s+TargetCardInHand\s*\(\s*(\d+)\s*,\s*StaticFilters\.FILTER_CARD_CARDS\s*\)\s*\)",
            window,
        )
        if len(discard_matches) != 1:
            return "graveyard_self_return_battlefield_source_cost_not_supported"
        discard_count = int(discard_matches[0])
        if discard_count != 2:
            return "graveyard_self_return_battlefield_source_cost_not_supported"
        discard_target = "any_card"
    if "ExileFromGraveCost" in window:
        if discard_count:
            return "graveyard_self_return_battlefield_source_cost_not_supported"
        if "AnotherPredicate.instance" not in text:
            return "graveyard_self_return_battlefield_source_cost_not_supported"
        explicit_count_matches = re.findall(
            r"new\s+ExileFromGraveCost\s*\(\s*new\s+TargetCardInYourGraveyard\s*\(\s*(\d+)\s*,\s*filter\s*\)\s*\)",
            window,
        )
        implicit_count_matches = re.findall(
            r"new\s+ExileFromGraveCost\s*\(\s*new\s+TargetCardInYourGraveyard\s*\(\s*filter\s*\)\s*\)",
            window,
        )
        if len(explicit_count_matches) + len(implicit_count_matches) != 1:
            return "graveyard_self_return_battlefield_source_cost_not_supported"
        exile_count = int(explicit_count_matches[0]) if explicit_count_matches else 1
        exile_target = "creature_card" if "FilterCreatureCard" in text else "any_card"
        exile_other = True
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if len(mana_matches) + len(generic_matches) != 1:
        return "graveyard_self_return_battlefield_source_cost_not_supported"
    cost_text = canonical_mana_cost_text(
        mana_matches[0] if mana_matches else "{" + generic_matches[0] + "}"
    )
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "graveyard_self_return_battlefield_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "enters_tapped": tapped_match.group(1) == "true",
        "activation_discard_count": discard_count,
        "activation_discard_target": discard_target,
        "activation_exile_from_graveyard_count": exile_count,
        "activation_exile_from_graveyard_target": exile_target,
        "activation_exile_from_graveyard_other": exile_other,
    }


def activation_cost_from_oracle_prefix(
    cost_text: str,
    *,
    allow_source_sacrifice: bool = False,
) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", str(cost_text or "").strip().lower())
    requires_sacrifice = False
    if allow_source_sacrifice and "sacrifice" in text:
        sacrifice_pattern = r"(?:^|,\s*)sacrifice this (?:artifact|creature|enchantment|permanent)(?:\s*,?|$)"
        sacrifice_matches = re.findall(sacrifice_pattern, text)
        if len(sacrifice_matches) != 1:
            return "activated_self_boost_oracle_cost_not_supported"
        text = re.sub(sacrifice_pattern, ",", text).strip(" ,")
        requires_sacrifice = True
    risky_tokens = [
        "/",
        "{q}",
        "discard",
        "pay ",
        "tap an untapped",
        "remove ",
        "exile ",
        "return ",
    ]
    if "sacrifice" in text:
        return "activated_self_boost_oracle_cost_not_supported"
    if any(token in text for token in risky_tokens):
        return "activated_self_boost_oracle_cost_not_supported"
    requires_tap = "{t}" in text
    mana_text = re.sub(r"\s*,?\s*\{t\}\s*,?\s*", "", text).strip()
    if mana_text in {"", ","}:
        mana_text = "{0}"
    if not re.fullmatch(r"(?:\{[0-9wubrg]\})+", mana_text):
        return "activated_self_boost_oracle_cost_not_supported"
    canonical = re.sub(
        r"\{([^}]+)\}",
        lambda match: "{" + match.group(1).upper() + "}",
        mana_text,
    )
    parsed = parse_mana_cost_text(canonical)
    if parsed is None:
        return "activated_self_boost_oracle_mana_cost_not_supported"
    generic, colors = parsed
    return {
        "activation_cost_mana": canonical,
        "activation_cost_generic": generic,
        "activation_cost_colors": colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
    }


def activated_life_gain_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_life_gain_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    match = re.fullmatch(r"you gain (?P<amount>\d+) life\.?", effect_text)
    if not match:
        return "activated_life_gain_oracle_not_simple"
    activation = activation_cost_from_oracle_prefix(cost_text, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_life_gain")
    return {
        "life_gain_amount": int(match.group("amount")),
        **activation,
    }


def activated_life_gain_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileFromTopOfLibraryCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_life_gain_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_life_gain_source_cost_not_supported"
    gain_matches = re.findall(r"new\s+GainLifeEffect\s*\(\s*(\d+)\s*\)", text, re.S)
    if len(gain_matches) != 1:
        return "activated_life_gain_source_amount_not_fixed"
    amount = int(gain_matches[0])
    if amount <= 0:
        return "activated_life_gain_source_amount_not_fixed"
    gain_index = text.find("GainLifeEffect")
    window = text[max(0, gain_index - 500) : gain_index + 1600]
    if "SimpleActivatedAbility" not in window:
        return "activated_life_gain_source_not_simple_activated"
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window, re.S)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window, re.S)
    colored_matches = re.findall(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window, re.S)
    cost_kinds = sum(1 for matches in (mana_matches, generic_matches, colored_matches) if matches)
    if cost_kinds > 1:
        return "activated_life_gain_source_cost_not_supported"
    if len(mana_matches) > 1 or len(generic_matches) > 1 or len(colored_matches) > 1:
        return "activated_life_gain_source_cost_not_supported"
    if mana_matches:
        cost_text = mana_matches[0]
    elif generic_matches:
        cost_text = "{" + generic_matches[0] + "}"
    elif colored_matches:
        cost_text = "{" + colored_matches[0] + "}"
    else:
        cost_text = "{0}"
    parsed = parse_mana_cost_text(cost_text)
    if parsed is None:
        return "activated_life_gain_source_mana_cost_not_supported"
    generic, colors = parsed
    return {
        "life_gain_amount": amount,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": generic,
        "activation_cost_colors": colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


def activated_self_boost_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_self_boost_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    card_name = normalize_name(str(metadata.get("name") or ""))
    source_pattern = r"(?:this creature"
    if card_name:
        source_pattern += rf"|{re.escape(card_name)}"
    source_pattern += r")"
    match = re.match(
        rf"^{source_pattern} gets ([+-]?\d+)/([+-]?\d+) until end of turn\.?$",
        effect_text,
    )
    if not match:
        return "activated_self_boost_oracle_not_simple"
    activation = activation_cost_from_oracle_prefix(cost_text)
    if isinstance(activation, str):
        return activation
    return {
        "power_delta": int(match.group(1)),
        "toughness_delta": int(match.group(2)),
        **activation,
    }


def activated_self_boost_cost_from_source(window: str) -> dict[str, Any] | str:
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window, re.S)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window, re.S)
    colored_matches = re.findall(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window, re.S)
    cost_kinds = sum(1 for matches in (mana_matches, generic_matches, colored_matches) if matches)
    if cost_kinds > 1:
        return "activated_self_boost_source_cost_not_supported"
    if len(mana_matches) > 1 or len(generic_matches) > 1 or len(colored_matches) > 1:
        return "activated_self_boost_source_cost_not_supported"
    if mana_matches:
        cost_text = mana_matches[0]
    elif generic_matches:
        cost_text = "{" + generic_matches[0] + "}"
    elif colored_matches:
        cost_text = "{" + colored_matches[0] + "}"
    else:
        cost_text = "{0}"
    parsed = parse_mana_cost_text(cost_text)
    if parsed is None:
        return "activated_self_boost_source_mana_cost_not_supported"
    generic, colors = parsed
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": generic,
        "activation_cost_colors": colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": False,
    }


def activated_self_boost_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "SacrificeSourceCost",
        "SacrificeTargetCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_self_boost_source_cost_not_supported"
    boost_matches = re.findall(
        r"new\s+BoostSourceEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*"
        r"(?:,\s*Duration\.EndOfTurn\s*)?\)",
        text,
        re.S,
    )
    if len(boost_matches) != 1:
        return "activated_self_boost_source_not_single_fixed"
    boost_index = text.find("BoostSourceEffect")
    window = text[max(0, boost_index - 500) : boost_index + 2000]
    if "SimpleActivatedAbility" not in window:
        return "activated_self_boost_source_not_simple_activated"
    activation = activated_self_boost_cost_from_source(window)
    if isinstance(activation, str):
        return activation
    return {
        "power_delta": int(boost_matches[0][0]),
        "toughness_delta": int(boost_matches[0][1]),
        **activation,
    }


def activated_target_boost_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_target_boost_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    match = re.match(
        r"^target creature gets ([+-]?\d+)/([+-]?\d+) until end of turn\.?$",
        effect_text,
    )
    if not match:
        return "activated_target_boost_oracle_not_simple"
    activation = activation_cost_from_oracle_prefix(cost_text, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_target_boost")
    return {
        "power_delta": int(match.group(1)),
        "toughness_delta": int(match.group(2)),
        "target": "creature",
        "target_controller": "any",
        **activation,
    }


def activated_target_boost_cost_from_source(window: str) -> dict[str, Any] | str:
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "SacrificeTargetCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "activated_target_boost_source_cost_not_supported"
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window, re.S)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window, re.S)
    colored_matches = re.findall(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window, re.S)
    cost_kinds = sum(1 for matches in (mana_matches, generic_matches, colored_matches) if matches)
    if cost_kinds > 1:
        return "activated_target_boost_source_cost_not_supported"
    if len(mana_matches) > 1 or len(generic_matches) > 1 or len(colored_matches) > 1:
        return "activated_target_boost_source_cost_not_supported"
    if mana_matches:
        cost_text = mana_matches[0]
    elif generic_matches:
        cost_text = "{" + generic_matches[0] + "}"
    elif colored_matches:
        cost_text = "{" + colored_matches[0] + "}"
    else:
        cost_text = "{0}"
    parsed = parse_mana_cost_text(cost_text)
    if parsed is None:
        return "activated_target_boost_source_mana_cost_not_supported"
    generic, colors = parsed
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": generic,
        "activation_cost_colors": colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


def activated_target_boost_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if "Zone.GRAVEYARD" in text:
        return "activated_target_boost_source_not_battlefield"
    if "TargetPointer" in text or ".setTargetPointer" in text or "EachTargetPointer" in text:
        return "activated_target_boost_source_target_not_supported"
    target_constructors = re.findall(r"new\s+(Target\w+)\s*\(", text)
    if len(target_constructors) != 1:
        return "activated_target_boost_source_target_not_supported"
    if not re.search(r"new\s+TargetCreaturePermanent\s*\(\s*\)", text, re.S):
        return "activated_target_boost_source_target_not_supported"
    boost_matches = re.findall(
        r"new\s+BoostTargetEffect\s*\(\s*([+-]?\d+)\s*,\s*([+-]?\d+)\s*"
        r"(?:,\s*Duration\.EndOfTurn\s*)?\)",
        text,
        re.S,
    )
    if len(boost_matches) != 1:
        return "activated_target_boost_source_not_single_fixed"
    boost_index = text.find("BoostTargetEffect")
    window = text[max(0, boost_index - 500) : boost_index + 2000]
    if "SimpleActivatedAbility" not in window:
        return "activated_target_boost_source_not_simple_activated"
    activation = activated_target_boost_cost_from_source(window)
    if isinstance(activation, str):
        return activation
    return {
        "power_delta": int(boost_matches[0][0]),
        "toughness_delta": int(boost_matches[0][1]),
        "target": "creature",
        "target_controller": "any",
        **activation,
    }


def activated_target_keyword_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = strip_parenthetical_reminders(
        oracle_text_after_leading_static_keywords(metadata)
    )
    text = re.sub(r"\s+", " ", text).strip().lower()
    if text.count(":") != 1:
        return "activated_target_keyword_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    keyword_words = "|".join(
        re.escape(word)
        for word in sorted(TARGET_GRANT_KEYWORD_ORACLE_WORDS, key=len, reverse=True)
    )
    match = re.match(
        rf"^(another\s+)?target\s+(.+?)\s+gains\s+({keyword_words}) until end of turn\.?$",
        effect_text,
    )
    if not match:
        return "activated_target_keyword_oracle_not_simple"
    target_data = activated_target_keyword_target_phrase_data(match.group(2))
    if isinstance(target_data, str):
        return target_data.replace("source", "oracle")
    if match.group(1):
        target_data["exclude_source"] = True
        target_data.setdefault("target_constraints", {})["exclude_source"] = True
    activation = activation_cost_from_oracle_prefix(cost_text)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_target_keyword")
    return {
        "keyword": TARGET_GRANT_KEYWORD_ORACLE_WORDS[match.group(3)],
        **target_data,
        **activation,
    }


TARGET_KEYWORD_TARGET_COLOR_WORDS = {
    "white": "W",
    "blue": "U",
    "black": "B",
    "red": "R",
    "green": "G",
}


def ordered_color_symbols(colors: list[str]) -> list[str]:
    order = {"W": 0, "U": 1, "B": 2, "R": 3, "G": 4}
    unique = list(dict.fromkeys(colors))
    return sorted(unique, key=lambda color: order.get(color, 99))


def target_keyword_subtypes_from_phrase(phrase: str) -> list[str]:
    return [
        token.lower()
        for token in re.split(r"[^A-Za-z0-9']+", str(phrase or ""))
        if token
    ]


def activated_target_keyword_target_phrase_data(phrase: str) -> dict[str, Any] | str:
    target_phrase = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    target_controller = "any"
    if target_phrase.endswith(" you control"):
        target_controller = "self"
        target_phrase = target_phrase[: -len(" you control")].strip()
    combat_state = None
    for prefix, state in (
        ("attacking or blocking ", "attacking_or_blocking"),
        ("attacking ", "attacking"),
        ("blocking ", "blocking"),
    ):
        if target_phrase.startswith(prefix):
            combat_state = state
            target_phrase = target_phrase[len(prefix) :].strip()
            break
    constraints: dict[str, Any] = {"card_types": ["creature"]}
    if combat_state:
        constraints["combat_state"] = combat_state
    power_match = re.fullmatch(r"creature with power (\d+) or greater", target_phrase)
    if power_match:
        constraints["power_min"] = int(power_match.group(1))
        return {
            "target": "creature",
            "target_controller": target_controller,
            "exclude_source": False,
            "target_constraints": constraints,
        }
    power_match = re.fullmatch(r"creature with power (\d+) or less", target_phrase)
    if power_match:
        constraints["power_max"] = int(power_match.group(1))
        return {
            "target": "creature",
            "target_controller": target_controller,
            "exclude_source": False,
            "target_constraints": constraints,
        }
    if target_phrase == "creature":
        return {
            "target": "creature",
            "target_controller": target_controller,
            "exclude_source": False,
            "target_constraints": constraints,
        }
    if target_phrase.endswith(" creature"):
        modifier = target_phrase[: -len(" creature")].strip()
        if not modifier:
            return "activated_target_keyword_source_target_not_supported"
        color_parts = [part.strip() for part in re.split(r"\s+or\s+", modifier) if part.strip()]
        color_symbols = [TARGET_KEYWORD_TARGET_COLOR_WORDS.get(part) for part in color_parts]
        if color_symbols and all(color_symbols):
            constraints["target_colors"] = ordered_color_symbols([str(symbol) for symbol in color_symbols])
        elif modifier == "snow":
            constraints["required_supertypes"] = ["snow"]
        else:
            subtypes = target_keyword_subtypes_from_phrase(modifier)
            if not subtypes:
                return "activated_target_keyword_source_target_not_supported"
            constraints["target_subtypes"] = subtypes
        return {
            "target": "creature",
            "target_controller": target_controller,
            "exclude_source": False,
            "target_constraints": constraints,
        }
    subtypes = target_keyword_subtypes_from_phrase(target_phrase)
    if not subtypes:
        return "activated_target_keyword_source_target_not_supported"
    if combat_state:
        constraints["target_subtypes"] = subtypes
        return {
            "target": "creature",
            "target_controller": target_controller,
            "exclude_source": False,
            "target_constraints": constraints,
        }
    return {
        "target": "permanent",
        "target_controller": target_controller,
        "exclude_source": False,
        "target_constraints": {"card_types": ["permanent"], "target_subtypes": subtypes},
    }


def activated_target_keyword_cost_from_source(window: str) -> dict[str, Any] | str:
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "SacrificeSourceCost",
        "SacrificeTargetCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "activated_target_keyword_source_cost_not_supported"
    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window, re.S)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window, re.S)
    colored_matches = re.findall(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window, re.S)
    cost_kinds = sum(1 for matches in (mana_matches, generic_matches, colored_matches) if matches)
    if cost_kinds > 1:
        return "activated_target_keyword_source_cost_not_supported"
    if len(mana_matches) > 1 or len(generic_matches) > 1 or len(colored_matches) > 1:
        return "activated_target_keyword_source_cost_not_supported"
    if mana_matches:
        cost_text = mana_matches[0]
    elif generic_matches:
        cost_text = "{" + generic_matches[0] + "}"
    elif colored_matches:
        cost_text = "{" + colored_matches[0] + "}"
    else:
        cost_text = "{0}"
    parsed = parse_mana_cost_text(cost_text)
    if parsed is None:
        return "activated_target_keyword_source_mana_cost_not_supported"
    generic, colors = parsed
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": generic,
        "activation_cost_colors": colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": False,
    }


def activated_target_keyword_target_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if "TargetPointer" in text or ".setTargetPointer" in text or "EachTargetPointer" in text:
        return "activated_target_keyword_source_target_not_supported"
    target_constructors = re.findall(r"new\s+(Target\w+)\s*\(", text)
    if len(target_constructors) != 1:
        return "activated_target_keyword_source_target_not_supported"
    if re.search(r"new\s+TargetCreaturePermanent\s*\(\s*\)", text, re.S):
        return {
            "target": "creature",
            "target_controller": "any",
            "exclude_source": False,
            "target_constraints": {"card_types": ["creature"]},
        }
    if re.search(r"new\s+TargetControlledCreaturePermanent\s*\(\s*\)", text, re.S):
        return {
            "target": "creature",
            "target_controller": "self",
            "exclude_source": False,
            "target_constraints": {"card_types": ["creature"]},
        }
    if "FILTER_ANOTHER_TARGET_CREATURE_YOU_CONTROL" in text:
        return {
            "target": "creature",
            "target_controller": "self",
            "exclude_source": True,
            "target_constraints": {"card_types": ["creature"], "exclude_source": True},
        }
    if "FILTER_ANOTHER_TARGET_CREATURE" in text:
        return {
            "target": "creature",
            "target_controller": "any",
            "exclude_source": True,
            "target_constraints": {"card_types": ["creature"], "exclude_source": True},
        }
    if re.search(r"FILTER_CONTROLLED_CREATURE|FILTER_TARGET_CREATURE_YOU_CONTROL", text, re.S):
        return {
            "target": "creature",
            "target_controller": "self",
            "exclude_source": False,
            "target_constraints": {"card_types": ["creature"]},
        }
    phrase_match = re.search(
        r"new\s+Filter(?:Attacking)?Creature(?:Permanent)?\s*\(\s*\"([^\"]+)\"\s*\)",
        text,
        re.S,
    )
    if phrase_match and re.search(r"new\s+TargetPermanent\s*\(", text, re.S):
        return activated_target_keyword_target_phrase_data(phrase_match.group(1))
    subtype_match = re.search(
        r"new\s+Filter(Creature)?Permanent\s*\(\s*SubType\.([A-Z0-9_]+)\s*,\s*\"([^\"]+)\"\s*\)",
        text,
        re.S,
    )
    if subtype_match and re.search(r"new\s+TargetPermanent\s*\(", text, re.S):
        return activated_target_keyword_target_phrase_data(subtype_match.group(3))
    return "activated_target_keyword_source_target_not_supported"


def activated_target_keyword_from_source(source: str, keyword_ability_class: str) -> dict[str, Any] | str:
    text = source or ""
    if "Zone.GRAVEYARD" in text:
        return "activated_target_keyword_source_not_battlefield"
    gain_matches = re.findall(r"new\s+GainAbilityTargetEffect\s*\(", text)
    if len(gain_matches) != 1:
        return "activated_target_keyword_source_not_single_effect"
    ability_expr = (
        rf"(?:{re.escape(keyword_ability_class)}\.getInstance\s*\(\s*\)"
        rf"|new\s+{re.escape(keyword_ability_class)}\s*\([^)]*\))"
    )
    if not re.search(
        rf"new\s+GainAbilityTargetEffect\s*\(\s*{ability_expr}"
        rf"(?:\s*,\s*Duration\.EndOfTurn\s*)?\)",
        text,
        re.S,
    ):
        return "activated_target_keyword_source_keyword_not_supported"
    gain_index = text.find("GainAbilityTargetEffect")
    window = text[max(0, gain_index - 500) : gain_index + 2000]
    if "SimpleActivatedAbility" not in window:
        return "activated_target_keyword_source_not_simple_activated"
    activation = activated_target_keyword_cost_from_source(window)
    if isinstance(activation, str):
        return activation
    target_data = activated_target_keyword_target_from_source(text)
    if isinstance(target_data, str):
        return target_data
    return {
        "keyword": TARGET_GRANT_KEYWORD_ABILITY_CLASSES[keyword_ability_class],
        **target_data,
        **activation,
    }


def activated_damage_from_oracle(metadata: dict[str, Any]) -> tuple[int, str] | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return None
    effect_text = text.rsplit(":", 1)[1].strip()
    restricted = restricted_battlefield_target_from_oracle({"oracle_text": effect_text}, "damage")
    if restricted is not None:
        match = re.match(
            r"^(?:it|this (?:artifact|creature|enchantment)|[^.]+?) deals (\d+) damage to ",
            effect_text,
        )
        return (int(match.group(1)), restricted) if match else None
    match = re.match(
        r"^(?:it|this (?:artifact|creature|enchantment)|[^.]+?) deals (\d+) damage to "
        r"(any target|target creature|target player or planeswalker)\.?$",
        effect_text,
    )
    if not match:
        return None
    target_map = {
        "any target": "any_target",
        "target creature": "creature",
        "target player or planeswalker": "player_or_planeswalker",
    }
    return int(match.group(1)), target_map[match.group(2)]


def activated_damage_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromTopOfLibraryCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapTargetCost",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_damage_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_damage_source_cost_not_supported"
    damage_matches = re.findall(r"DamageTargetEffect\s*\(\s*(\d*)\s*(?:,|\))", text)
    if len(damage_matches) != 1:
        return "activated_damage_source_count_not_fixed"
    count = int(damage_matches[0] or "0")
    if count <= 0:
        return "activated_damage_source_count_not_fixed"
    restricted = restricted_battlefield_target_from_source(text)
    if restricted is not None:
        target = restricted
    elif "new TargetAnyTarget(" in text:
        target = "any_target"
    elif "new TargetPlayerOrPlaneswalker(" in text:
        target = "player_or_planeswalker"
    elif "new TargetCreaturePermanent(" in text:
        target = "creature"
    else:
        return "activated_damage_source_target_not_supported"
    damage_index = text.find("DamageTargetEffect")
    window = text[max(0, damage_index - 300) : damage_index + 1600]
    if "SimpleActivatedAbility" not in window:
        return "activated_damage_source_not_simple_activated"
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_damage_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    requires_tap = "TapSourceCost" in window
    requires_sacrifice = "SacrificeSourceCost" in window
    return {
        "amount": count,
        "damage": count,
        "target": target,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
    }


def activated_destroy_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return None
    effect_text = text.rsplit(":", 1)[1].strip()
    effect_metadata = dict(metadata)
    effect_metadata["oracle_text"] = effect_text
    return destroy_target_from_oracle(effect_metadata)


def activated_destroy_target_from_source(text: str) -> str | None:
    if "TargetPointer" in text or ".setTargetPointer" in text or "EachTargetPointer" in text:
        return None
    target_classes = re.findall(r"new\s+(Target\w+)\s*\(", text)
    if len(target_classes) != 1:
        return None
    restricted = restricted_battlefield_target_from_source(text)
    if restricted is not None:
        return restricted
    target_patterns = [
        (
            "artifact_or_enchantment",
            r"TargetPermanent\s*\(\s*StaticFilters\.FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT\s*\)",
        ),
        (
            "artifact_or_enchantment",
            r"FILTER_PERMANENT_ARTIFACT_OR_ENCHANTMENT",
        ),
        (
            "creature_enchantment_or_planeswalker",
            r"FILTER_PERMANENT_CREATURE_ENCHANTMENT_OR_PLANESWALKER",
        ),
        (
            "nonland_permanent",
            r"FILTER_PERMANENT_NON_LAND|FilterNonlandPermanent",
        ),
        ("creature_or_planeswalker", r"TargetCreatureOrPlaneswalker\s*\("),
        ("artifact", r"TargetArtifactPermanent\s*\("),
        ("enchantment", r"TargetEnchantmentPermanent\s*\("),
        ("land", r"TargetLandPermanent\s*\("),
        ("creature", r"TargetCreaturePermanent\s*\("),
        ("permanent", r"TargetPermanent\s*\(\s*\)"),
    ]
    matched = [
        target
        for target, pattern in target_patterns
        if re.search(pattern, text, re.S)
    ]
    matched = list(dict.fromkeys(matched))
    if len(matched) != 1:
        return None
    return matched[0]


def activated_destroy_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapTargetCost",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_destroy_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_destroy_source_cost_not_supported"
    if len(re.findall(r"new\s+DestroyTargetEffect\s*\(\s*\)", text, re.S)) != 1:
        return "activated_destroy_source_not_simple_destroy_effect"
    destroy_index = text.find("DestroyTargetEffect")
    window = text[max(0, destroy_index - 500) : destroy_index + 2000]
    if "SimpleActivatedAbility" not in window:
        return "activated_destroy_source_not_simple_activated"
    target = activated_destroy_target_from_source(text)
    if target is None:
        return "activated_destroy_source_target_not_supported"
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_destroy_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        "target": target,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


def activated_draw_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if "Zone.GRAVEYARD" in text:
        return "activated_draw_source_not_battlefield"
    draw_matches = re.findall(r"DrawCardSourceControllerEffect\s*\(\s*(\d*)\s*\)", text)
    if len(draw_matches) != 1:
        return "activated_draw_source_count_not_fixed"
    count = int(draw_matches[0] or "1")
    if count <= 0:
        return "activated_draw_source_count_not_fixed"
    draw_index = text.find("DrawCardSourceControllerEffect")
    window = text[max(0, draw_index - 500) : draw_index + 1800]
    risky_cost_classes = {
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "activated_draw_source_cost_not_supported"
    if "SimpleActivatedAbility" not in window:
        return "activated_draw_source_not_simple_activated"
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_draw_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    requires_tap = "TapSourceCost" in window
    requires_sacrifice = "SacrificeSourceCost" in window
    life_cost = None
    life_matches = re.findall(r"PayLifeCost\s*\(\s*(\d+)\s*\)", window)
    if len(life_matches) > 1:
        return "activated_draw_source_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0])
    sacrifice_target = None
    if "SacrificeTargetCost" in window:
        sacrifice_cost_constructors = re.findall(r"new\s+SacrificeTargetCost\s*\(", window)
        if len(sacrifice_cost_constructors) > 1:
            return "activated_draw_source_cost_not_supported"
        sacrifice_target = activation_sacrifice_target_from_source(text, window)
        if sacrifice_target is None:
            return "activated_draw_source_cost_not_supported"
    if requires_sacrifice and sacrifice_target:
        return "activated_draw_source_cost_not_supported"
    return {
        "count": count,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
        **({"activation_life_cost": life_cost} if life_cost else {}),
        **(
            {
                "activation_sacrifice_target": sacrifice_target,
                "activation_requires_sacrifice_target": True,
            }
            if sacrifice_target
            else {}
        ),
    }


def draw_discard_counts_from_source(source: str) -> tuple[int, int] | str:
    matches = re.findall(r"DrawDiscardControllerEffect\s*\(([^)]*)\)", source or "")
    if len(matches) != 1:
        return "activated_draw_discard_source_count_not_fixed"
    raw_args = [part.strip() for part in matches[0].split(",") if part.strip()]
    if not raw_args:
        return 1, 1
    if len(raw_args) == 1:
        if raw_args[0].lower() == "false":
            return 1, 1
        return "activated_draw_discard_source_optional_not_supported"
    if len(raw_args) == 2 and all(arg.isdigit() for arg in raw_args):
        draw_count = int(raw_args[0])
        discard_count = int(raw_args[1])
    elif (
        len(raw_args) == 3
        and raw_args[0].isdigit()
        and raw_args[1].isdigit()
        and raw_args[2].lower() in {"true", "false"}
    ):
        if raw_args[2].lower() == "true":
            return "activated_draw_discard_source_optional_not_supported"
        draw_count = int(raw_args[0])
        discard_count = int(raw_args[1])
    else:
        return "activated_draw_discard_source_count_not_fixed"
    if draw_count <= 0 or discard_count <= 0:
        return "activated_draw_discard_source_count_not_fixed"
    return draw_count, discard_count


def activated_draw_discard_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if "Zone.GRAVEYARD" in text:
        return "activated_draw_discard_source_not_battlefield"
    counts = draw_discard_counts_from_source(text)
    if isinstance(counts, str):
        return counts
    draw_count, discard_count = counts
    effect_index = text.find("DrawDiscardControllerEffect")
    window = text[max(0, effect_index - 500) : effect_index + 1800]
    risky_cost_classes = {
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "activated_draw_discard_source_cost_not_supported"
    if "SimpleActivatedAbility" not in window:
        return "activated_draw_discard_source_not_simple_activated"
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_draw_discard_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    requires_tap = "TapSourceCost" in window
    requires_sacrifice = "SacrificeSourceCost" in window
    life_cost = None
    life_matches = re.findall(r"PayLifeCost\s*\(\s*(\d+)\s*\)", window)
    if len(life_matches) > 1:
        return "activated_draw_discard_source_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0])
    sacrifice_target = None
    if "SacrificeTargetCost" in window:
        sacrifice_cost_constructors = re.findall(r"new\s+SacrificeTargetCost\s*\(", window)
        if len(sacrifice_cost_constructors) > 1:
            return "activated_draw_discard_source_cost_not_supported"
        sacrifice_target = activation_sacrifice_target_from_source(text, window)
        if sacrifice_target is None:
            return "activated_draw_discard_source_cost_not_supported"
    if requires_sacrifice and sacrifice_target:
        return "activated_draw_discard_source_cost_not_supported"
    return {
        "draw_count": draw_count,
        "discard_count": discard_count,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
        **({"activation_life_cost": life_cost} if life_cost else {}),
        **(
            {
                "activation_sacrifice_target": sacrifice_target,
                "activation_requires_sacrifice_target": True,
            }
            if sacrifice_target
            else {}
        ),
    }


def activation_sacrifice_target_from_source(source: str, window: str) -> str | None:
    text = source or ""
    relevant = (window or "") + "\n" + text
    if "FILTER_PERMANENT_CREATURE_OR_ENCHANTMENT" in relevant:
        return "creature_or_enchantment"
    if (
        "CardType.CREATURE.getPredicate()" in relevant
        and "CardType.PLANESWALKER.getPredicate()" in relevant
    ):
        return "creature_or_planeswalker"
    if "FILTER_PERMANENT_ARTIFACT_OR_CREATURE" in relevant:
        return "artifact_or_creature"
    if "FilterControlledEnchantmentPermanent" in relevant:
        return "enchantment"
    if "SubType.SWAMP.getPredicate" in relevant:
        return "swamp"
    if "FILTER_PERMANENT_CREATURE" in relevant or "TargetControlledCreaturePermanent" in relevant:
        return "creature"
    if "FILTER_PERMANENT_ARTIFACT" in relevant:
        return "artifact"
    if "FILTER_CONTROLLED_LAND" in relevant or "FILTER_LANDS" in relevant or "FILTER_LAND" in relevant:
        return "land"
    if "TokenPredicate.TRUE" in relevant:
        return "token"
    if "TokenPredicate.FALSE" in relevant:
        return "nontoken_permanent"
    if "CardType.ARTIFACT.getPredicate()" in relevant and "CardType.LAND.getPredicate()" in relevant:
        return "artifact_or_land"
    if "CardType.CREATURE.getPredicate()" in relevant and "CardType.LAND.getPredicate()" in relevant:
        return "creature_or_land"
    filter_match = re.search(r'new\s+FilterControlledPermanent\s*\(\s*"([^"]+)"\s*\)', relevant)
    if filter_match:
        return activation_sacrifice_target_from_phrase(filter_match.group(1))
    filter_match = re.search(r'new\s+FilterPermanent\s*\(\s*"([^"]+)"\s*\)', relevant)
    if filter_match:
        return activation_sacrifice_target_from_phrase(filter_match.group(1))
    return None


def fixed_damage_spell_additional_cost_fields_from_source(
    source: str,
    metadata: dict[str, Any],
) -> tuple[dict[str, Any] | None, str | None]:
    text = source or ""
    has_cost = has_additional_cost(text) or "additional cost" in oracle_text(metadata).lower()
    if not has_cost:
        return {}, None
    cost_count = len(re.findall(r"\.addCost\s*\(", text))
    if cost_count != 1:
        return None, "damage_additional_cost_not_supported"
    if "SacrificeTargetCost" not in text:
        return None, "damage_additional_cost_not_supported"
    sacrifice_target = activation_sacrifice_target_from_source(text, text)
    if sacrifice_target == "creature":
        return {
            "additional_cost": "sacrifice_creature",
            "requires_sacrifice_creature": True,
            "xmage_additional_cost_class": "SacrificeTargetCost",
            "xmage_additional_cost_target": "creature",
        }, None
    if sacrifice_target == "land":
        return {
            "additional_cost": "sacrifice_land",
            "requires_sacrifice_land": True,
            "xmage_additional_cost_class": "SacrificeTargetCost",
            "xmage_additional_cost_target": "land",
        }, None
    return None, "damage_additional_cost_not_supported"


def fixed_draw_spell_additional_cost_fields_from_source(
    source: str,
    metadata: dict[str, Any],
) -> tuple[dict[str, Any] | None, str | None]:
    text = source or ""
    has_cost = has_additional_cost(text) or "additional cost" in oracle_text(metadata).lower()
    if not has_cost:
        return {}, None
    cost_count = len(re.findall(r"\.addCost\s*\(", text))
    if cost_count != 1:
        return None, "draw_additional_cost_not_supported"
    lowered_oracle = oracle_text(metadata).lower()
    if "DiscardCardCost" in text and re.search(r"additional cost.*discard a card", lowered_oracle):
        return {
            "additional_cost": "discard_card",
            "requires_discard_card": True,
            "xmage_additional_cost_class": "DiscardCardCost",
            "xmage_additional_cost_target": "card",
        }, None
    if (
        "DiscardTargetCost" in text
        and "FilterLandCard" in text
        and re.search(r"additional cost.*discard a land card", lowered_oracle)
    ):
        return {
            "additional_cost": "discard_land",
            "requires_discard_land": True,
            "xmage_additional_cost_class": "DiscardTargetCost",
            "xmage_additional_cost_target": "land",
        }, None
    if "SacrificeTargetCost" in text and re.search(
        r"additional cost.*sacrifice a creature", lowered_oracle
    ):
        if re.search(r"SacrificeTargetCost\s*\(\s*2\b", text):
            return None, "draw_additional_cost_not_supported"
        if "FILTER_PERMANENT_CREATURE" in text and "FILTER_PERMANENT_CREATURES" not in text:
            return {
                "additional_cost": "sacrifice_creature",
                "requires_sacrifice_creature": True,
                "xmage_additional_cost_class": "SacrificeTargetCost",
                "xmage_additional_cost_target": "creature",
            }, None
    return None, "draw_additional_cost_not_supported"


def spell_cast_draw_filter_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    text = re.sub(r"\s*\([^)]*historic[^)]*\)\s*", " ", text).strip()
    match = re.search(
        r"whenever you cast (?P<filter>.+?), (?:you )?(?P<may>may )?draw (?P<count>a|one|two|three|\d+) cards?\.?",
        text,
    )
    if not match:
        return "spell_cast_draw_oracle_not_simple"
    value = match.group("count")
    words = {"a": 1, "one": 1, "two": 2, "three": 3}
    count = words.get(value, int(value) if value.isdigit() else 0)
    if count <= 0:
        return "spell_cast_draw_oracle_count_not_supported"
    filter_text = re.sub(r"\s+", " ", match.group("filter").strip())
    if filter_text.endswith(" spell"):
        filter_text = filter_text[: -len(" spell")].strip()
    result: dict[str, Any] = {
        "spell_cast_draw_count": count,
        "spell_cast_draw_optional": bool(match.group("may")),
        "trigger": "spell_cast",
    }
    filter_specs: list[tuple[str, dict[str, Any]]] = [
        ("a creature", {"spell_cast_draw_card_types": ["creature"]}),
        ("an enchantment", {"spell_cast_draw_card_types": ["enchantment"]}),
        ("an artifact", {"spell_cast_draw_card_types": ["artifact"]}),
        ("a noncreature", {"trigger": "noncreature_spell_cast"}),
        ("a legendary", {"spell_cast_draw_required_supertypes": ["legendary"]}),
        ("a historic", {"spell_cast_draw_requires_historic": True}),
        (
            "an aura, equipment, or vehicle",
            {"spell_cast_draw_required_subtypes": ["aura", "equipment", "vehicle"]},
        ),
        ("a spell from your graveyard", {"spell_cast_draw_source_zone": "graveyard"}),
    ]
    for prefix, spec in filter_specs:
        if filter_text == prefix:
            result.update(spec)
            return result
    match_mv = re.fullmatch(r"a spell with mana value (?P<mv>\d+) or greater", filter_text)
    if match_mv:
        result["spell_cast_draw_mana_value_min"] = int(match_mv.group("mv"))
        return result
    match_eldrazi = re.fullmatch(
        r"an eldrazi creature spell with mana value (?P<mv>\d+) or greater",
        filter_text,
    )
    if match_eldrazi:
        result["spell_cast_draw_card_types"] = ["creature"]
        result["spell_cast_draw_required_subtypes"] = ["eldrazi"]
        result["spell_cast_draw_mana_value_min"] = int(match_eldrazi.group("mv"))
        return result
    return "spell_cast_draw_oracle_filter_not_supported"


def spell_cast_draw_filter_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    if len(re.findall(r"new\s+SpellCastControllerTriggeredAbility\s*\(", text)) != 1:
        return "spell_cast_draw_source_not_single_trigger"
    if "DoIfCostPaid" in text or "SacrificeSourceCost" in text or "PayLifeCost" in text:
        return "spell_cast_draw_source_optional_cost_not_supported"
    if "AdventurePredicate" in text:
        return "spell_cast_draw_source_filter_not_supported"
    draw_count = java_constructor_int(text, "DrawCardSourceControllerEffect")
    if draw_count is None or draw_count <= 0:
        return "spell_cast_draw_source_count_not_fixed"
    result: dict[str, Any] = {
        "spell_cast_draw_count": draw_count,
        "trigger": "spell_cast",
    }
    if "FILTER_SPELL_A_NON_CREATURE" in text:
        result["trigger"] = "noncreature_spell_cast"
        return result
    if "FILTER_SPELL_A_CREATURE" in text:
        result["spell_cast_draw_card_types"] = ["creature"]
        return result
    if "FILTER_SPELL_AN_ENCHANTMENT" in text:
        result["spell_cast_draw_card_types"] = ["enchantment"]
        return result
    if "FILTER_SPELL_AN_ARTIFACT" in text:
        result["spell_cast_draw_card_types"] = ["artifact"]
        return result
    if "FILTER_SPELL_HISTORIC" in text:
        result["spell_cast_draw_requires_historic"] = True
        return result
    if "FILTER_SPELL_MV_4_OR_GREATER" in text:
        result["spell_cast_draw_mana_value_min"] = 4
        return result
    if "SpellZonePredicate(Zone.GRAVEYARD)" in text:
        result["spell_cast_draw_source_zone"] = "graveyard"
        return result
    subtype_matches = [
        value.lower()
        for value in re.findall(r"SubType\.([A-Z_]+)\.getPredicate\s*\(\s*\)", text)
    ]
    if subtype_matches:
        result["spell_cast_draw_required_subtypes"] = subtype_matches
    if "SuperType.LEGENDARY.getPredicate()" in text:
        result["spell_cast_draw_required_supertypes"] = ["legendary"]
    mv_match = re.search(
        r"ManaValuePredicate\s*\(\s*ComparisonType\.MORE_THAN\s*,\s*(\d+)\s*\)",
        text,
    )
    if mv_match:
        result["spell_cast_draw_mana_value_min"] = int(mv_match.group(1)) + 1
    if "Predicates.or" in text:
        subtype_matches = [
            value.lower()
            for value in re.findall(r"SubType\.([A-Z_]+)\.getPredicate\s*\(\s*\)", text)
        ]
        if subtype_matches:
            result["spell_cast_draw_required_subtypes"] = subtype_matches
    supported_filter = any(
        key in result
        for key in (
            "spell_cast_draw_card_types",
            "spell_cast_draw_required_subtypes",
            "spell_cast_draw_required_supertypes",
            "spell_cast_draw_requires_historic",
            "spell_cast_draw_source_zone",
            "spell_cast_draw_mana_value_min",
        )
    )
    if not supported_filter:
        return "spell_cast_draw_source_filter_not_supported"
    return result


def spell_cast_draw_specs_match(oracle_spec: dict[str, Any], source_spec: dict[str, Any]) -> bool:
    comparable_keys = {
        "trigger",
        "spell_cast_draw_count",
        "spell_cast_draw_card_types",
        "spell_cast_draw_required_subtypes",
        "spell_cast_draw_required_supertypes",
        "spell_cast_draw_requires_historic",
        "spell_cast_draw_source_zone",
        "spell_cast_draw_mana_value_min",
    }
    for key in comparable_keys:
        oracle_value = oracle_spec.get(key)
        source_value = source_spec.get(key)
        if isinstance(oracle_value, list):
            oracle_value = sorted(str(value) for value in oracle_value)
        if isinstance(source_value, list):
            source_value = sorted(str(value) for value in source_value)
        if oracle_value != source_value:
            return False
    return True


def activated_recursion_to_hand_target_from_source(text: str) -> tuple[str, int, bool] | str:
    lowered = str(text or "").lower()
    if "arcan" in lowered:
        return "activated_recursion_source_target_not_supported"
    if "basic land card" in lowered or "FILTER_CARD_BASIC_LAND" in text:
        target = "basic_land"
    elif "instant or sorcery card" in lowered or "FilterInstantOrSorceryCard" in text:
        target = "instant_or_sorcery"
    elif (
        "artifact or enchantment card" in lowered
        or "FILTER_CARD_ARTIFACT_OR_ENCHANTMENT" in text
    ):
        target = "artifact_or_enchantment"
    elif "artifact creature card" in lowered:
        target = "artifact_creature"
    elif "creature card" in lowered or "FILTER_CARD_CREATURE_YOUR_GRAVEYARD" in text or "FILTER_CARD_CREATURES_YOUR_GRAVEYARD" in text:
        target = "creature"
    elif "artifact card" in lowered or "FILTER_CARD_ARTIFACT_FROM_YOUR_GRAVEYARD" in text:
        target = "artifact"
    elif "enchantment card" in lowered or "FilterEnchantmentCard" in text:
        target = "enchantment"
    elif "permanent card" in lowered or "FilterPermanentCard" in text:
        target = "permanent"
    else:
        return "activated_recursion_source_target_not_supported"

    count = 1
    up_to = False
    count_match = re.search(r"TargetCardInYourGraveyard\s*\(\s*0\s*,\s*(\d+)\s*,", text, re.S)
    if count_match:
        count = int(count_match.group(1))
        up_to = True
    return target, count, up_to


def activated_recursion_to_hand_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_recursion_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_recursion_source_cost_not_supported"
    if len(re.findall(r"TargetCardInYourGraveyard\s*\(", text)) != 1:
        return "activated_recursion_source_target_not_supported"
    if "EachTargetPointer" in text:
        return "activated_recursion_source_target_not_supported"
    if "put there from the battlefield this turn" in text.lower() or "that was put there" in text.lower():
        return "activated_recursion_source_target_not_supported"
    effect_matches = re.findall(r"ReturnFromGraveyardToHandTargetEffect\s*\(", text)
    if len(effect_matches) != 1:
        return "activated_recursion_source_count_not_fixed"
    effect_index = text.find("ReturnFromGraveyardToHandTargetEffect")
    window = text[max(0, effect_index - 500) : effect_index + 1800]
    if "SimpleActivatedAbility" not in window:
        return "activated_recursion_source_not_simple_activated"
    parsed_target = activated_recursion_to_hand_target_from_source(text)
    if isinstance(parsed_target, str):
        return parsed_target
    target, count, up_to = parsed_target
    discard_count = 0
    discard_target = None
    discard_matches = re.findall(r"new\s+DiscardCardCost\s*\(([^)]*)\)", window, re.S)
    if discard_matches:
        if len(discard_matches) != 1:
            return "activated_recursion_source_cost_not_supported"
        discard_arg = re.sub(r"\s+", " ", discard_matches[0]).strip()
        discard_count = 1
        if not discard_arg:
            discard_target = "any_card"
        elif "FILTER_CARD_CREATURE_A" in discard_arg:
            discard_target = "creature_card"
        else:
            return "activated_recursion_source_cost_not_supported"
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_match = re.search(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_match:
        cost_text = "{" + generic_match.group(1) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_recursion_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    requires_tap = "TapSourceCost" in window
    requires_sacrifice = "SacrificeSourceCost" in window
    life_cost = None
    life_matches = re.findall(r"PayLifeCost\s*\(\s*(\d+)\s*\)", window)
    if len(life_matches) > 1:
        return "activated_recursion_source_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0])
    sacrifice_target = None
    if "SacrificeTargetCost" in window:
        if re.search(r"new\s+SacrificeTargetCost\s*\(\s*\d+\s*,", window):
            return "activated_recursion_source_cost_not_supported"
        sacrifice_cost_constructors = re.findall(r"new\s+SacrificeTargetCost\s*\(", window)
        if len(sacrifice_cost_constructors) > 1:
            return "activated_recursion_source_cost_not_supported"
        sacrifice_target = activation_sacrifice_target_from_source(text, window)
        if sacrifice_target is None:
            return "activated_recursion_source_cost_not_supported"
    if requires_sacrifice and sacrifice_target:
        return "activated_recursion_source_cost_not_supported"
    return {
        "target": target,
        "count": count,
        "up_to": up_to,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
        "activation_discard_count": discard_count,
        "activation_discard_target": discard_target,
        **({"activation_life_cost": life_cost} if life_cost else {}),
        **(
            {
                "activation_sacrifice_target": sacrifice_target,
                "activation_requires_sacrifice_target": True,
            }
            if sacrifice_target
            else {}
        ),
    }


def activated_recursion_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_recursion_battlefield_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    effect_text = re.split(r"\s+partner[—-]", effect_text, maxsplit=1)[0].strip()
    activation_timing = None
    timing_suffix = re.search(
        r"\s*activate (?:only )?as a sorcery\.?$",
        effect_text,
    )
    if timing_suffix:
        activation_timing = "sorcery"
        effect_text = effect_text[: timing_suffix.start()].strip()
        if not effect_text.endswith("."):
            effect_text += "."
    normalized_cost = cost_text
    life_cost = 0
    life_pattern = r"(?:^|,\s*)pay (?P<life>\d+) life(?:\s*,?|$)"
    life_matches = list(re.finditer(life_pattern, normalized_cost))
    if len(life_matches) > 1:
        return "activated_recursion_battlefield_oracle_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0].group("life"))
        normalized_cost = re.sub(life_pattern, ",", normalized_cost).strip(" ,")

    sacrifice_target = None
    sacrifice_pattern = (
        r"(?:^|,\s*)sacrifice (?P<phrase>"
        r"(?:an?|another) (?:artifact or creature|artifact or land|creature or land|"
        r"nontoken permanent|non-token permanent|token|creature|artifact|enchantment|land|swamp|permanent)"
        r")(?:\s*,?|$)"
    )
    sacrifice_matches = list(re.finditer(sacrifice_pattern, normalized_cost))
    if len(sacrifice_matches) > 1:
        return "activated_recursion_battlefield_oracle_cost_not_supported"
    if sacrifice_matches:
        sacrifice_target = activation_sacrifice_target_from_phrase(sacrifice_matches[0].group("phrase"))
        if sacrifice_target is None:
            return "activated_recursion_battlefield_oracle_cost_not_supported"
        normalized_cost = re.sub(sacrifice_pattern, ",", normalized_cost).strip(" ,")

    activation = activation_cost_from_oracle_prefix(normalized_cost, allow_source_sacrifice=True)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_recursion_battlefield")
    if activation.get("activation_requires_sacrifice") and sacrifice_target:
        return "activated_recursion_battlefield_oracle_cost_not_supported"
    target = recursion_to_battlefield_from_oracle({**metadata, "oracle_text": effect_text})
    if target is None:
        return "activated_recursion_battlefield_target_not_supported"
    result = {**target, **activation}
    if activation_timing:
        result["activation_timing"] = activation_timing
    if life_cost:
        result["activation_life_cost"] = life_cost
    if sacrifice_target:
        result["activation_sacrifice_target"] = sacrifice_target
        result["activation_requires_sacrifice_target"] = True
    return result


def activated_recursion_to_battlefield_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_recursion_battlefield_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_recursion_battlefield_source_cost_not_supported"
    if len(re.findall(r"TargetCardInYourGraveyard\s*\(", text)) != 1:
        return "activated_recursion_battlefield_source_target_not_supported"
    if "EachTargetPointer" in text:
        return "activated_recursion_battlefield_source_target_not_supported"
    effect_matches = re.findall(r"ReturnFromGraveyardToBattlefieldTargetEffect\s*\(", text)
    if len(effect_matches) != 1:
        return "activated_recursion_battlefield_source_count_not_fixed"
    effect_index = text.find("ReturnFromGraveyardToBattlefieldTargetEffect")
    window = text[max(0, effect_index - 500) : effect_index + 1800]
    ability_match = re.search(r"\b(SimpleActivatedAbility|ActivateAsSorceryActivatedAbility)\b", window)
    if not ability_match:
        return "activated_recursion_battlefield_source_not_simple_activated"
    activation_timing = "sorcery" if ability_match.group(1) == "ActivateAsSorceryActivatedAbility" else None

    if "FilterPermanentCard" in text and "SubType.REBEL.getPredicate" in text:
        target = "rebel_permanent"
    elif "FILTER_CARD_CREATURE" in text or "FilterCreatureCard" in text or "creature card" in text.lower():
        target = "creature"
    elif "FILTER_CARD_ARTIFACT_FROM_YOUR_GRAVEYARD" in text or "FilterArtifactCard" in text or "artifact card" in text.lower():
        target = "artifact"
    elif "FilterEnchantmentCard" in text or "enchantment card" in text.lower():
        target = "enchantment"
    elif "FilterPermanentCard" in text or "permanent card" in text.lower():
        target = "permanent"
    else:
        return "activated_recursion_battlefield_source_target_not_supported"

    mana_matches = re.findall(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    colored_matches = re.findall(r"ColoredManaCost\s*\(\s*ColoredManaSymbol\.([WUBRG])\s*\)", window)
    cost_kinds = sum(1 for matches in (mana_matches, generic_matches, colored_matches) if matches)
    if cost_kinds > 1:
        return "activated_recursion_battlefield_source_cost_not_supported"
    if len(mana_matches) > 1 or len(generic_matches) > 1 or len(colored_matches) > 1:
        return "activated_recursion_battlefield_source_cost_not_supported"
    if mana_matches:
        cost_text = mana_matches[0]
    elif generic_matches:
        cost_text = "{" + generic_matches[0] + "}"
    elif colored_matches:
        cost_text = "{" + colored_matches[0] + "}"
    else:
        cost_text = "{0}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_recursion_battlefield_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    requires_tap = "TapSourceCost" in window
    requires_sacrifice = "SacrificeSourceCost" in window
    life_cost = None
    life_matches = re.findall(r"PayLifeCost\s*\(\s*(\d+)\s*\)", window)
    if len(life_matches) > 1:
        return "activated_recursion_battlefield_source_cost_not_supported"
    if life_matches:
        life_cost = int(life_matches[0])
    sacrifice_target = None
    if "SacrificeTargetCost" in window:
        if re.search(r"new\s+SacrificeTargetCost\s*\(\s*\d+\s*,", window):
            return "activated_recursion_battlefield_source_cost_not_supported"
        sacrifice_cost_constructors = re.findall(r"new\s+SacrificeTargetCost\s*\(", window)
        if len(sacrifice_cost_constructors) > 1:
            return "activated_recursion_battlefield_source_cost_not_supported"
        sacrifice_target = activation_sacrifice_target_from_source(text, window)
        if sacrifice_target is None:
            return "activated_recursion_battlefield_source_cost_not_supported"
    if requires_sacrifice and sacrifice_target:
        return "activated_recursion_battlefield_source_cost_not_supported"
    result = {
        "target": target,
        "count": 1,
        "target_graveyard_controller": "self",
        "battlefield_controller": "self",
        "enters_tapped": bool(
            re.search(r"ReturnFromGraveyardToBattlefieldTargetEffect\s*\(\s*true\b", text)
        ),
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
    }
    if activation_timing:
        result["activation_timing"] = activation_timing
    if life_cost:
        result["activation_life_cost"] = life_cost
    if sacrifice_target:
        result["activation_sacrifice_target"] = sacrifice_target
        result["activation_requires_sacrifice_target"] = True
    if "PutIntoGraveFromBattlefieldThisTurnPredicate" in text:
        result["graveyard_from_battlefield_this_turn"] = True
    mana_value_match = re.search(
        r"ManaValuePredicate\s*\(\s*ComparisonType\.FEWER_THAN\s*,\s*(\d+)\s*\)",
        text,
    )
    if mana_value_match:
        result["mana_value_max"] = int(mana_value_match.group(1)) - 1
    return result


def activated_graveyard_exile_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_graveyard_exile_oracle_not_simple"
    effect_text = text.rsplit(":", 1)[1].strip()
    patterns: list[tuple[str, str, bool, bool]] = [
        (r"^exile target card from a graveyard\.?$", "any_card", False, False),
        (r"^exile target creature card from a graveyard\.?$", "creature", False, False),
        (
            r"^exile up to (one|two|three|\d+) target cards from a single graveyard\.?$",
            "any_card",
            True,
            True,
        ),
        (
            r"^exile up to (one|two|three|\d+) target creature cards from a single graveyard\.?$",
            "creature",
            True,
            True,
        ),
    ]
    words = {"one": 1, "two": 2, "three": 3}
    for pattern, target, up_to, single_graveyard in patterns:
        match = re.match(pattern, effect_text)
        if not match:
            continue
        count = 1
        if match.groups():
            value = match.group(1)
            count = words.get(value, int(value) if value.isdigit() else 0)
        if count <= 0:
            return "activated_graveyard_exile_oracle_count_not_supported"
        return {
            "target": target,
            "count": count,
            "up_to": up_to,
            "single_graveyard": single_graveyard,
        }
    return "activated_graveyard_exile_oracle_not_simple"


def activated_graveyard_exile_target_from_source(text: str) -> dict[str, Any] | str:
    target_card_count = len(re.findall(r"\bTargetCardInGraveyard\s*\(", text))
    target_single_count = len(re.findall(r"\bTargetCardInASingleGraveyard\s*\(", text))
    if target_card_count + target_single_count != 1:
        return "activated_graveyard_exile_source_target_not_supported"
    if target_card_count:
        target = (
            "creature"
            if (
                "FILTER_CARD_CREATURE_A_GRAVEYARD" in text
                or "FilterCreatureCard" in text
            )
            else "any_card"
        )
        return {
            "target": target,
            "count": 1,
            "up_to": False,
            "single_graveyard": False,
        }
    match = re.search(r"TargetCardInASingleGraveyard\s*\(\s*0\s*,\s*(\d+)\s*,", text, re.S)
    if not match:
        return "activated_graveyard_exile_source_target_not_supported"
    target = (
        "creature"
        if (
            "FILTER_CARD_CREATURE_A_GRAVEYARD" in text
            or "FilterCreatureCard" in text
        )
        else "any_card"
    )
    return {
        "target": target,
        "count": int(match.group(1)),
        "up_to": True,
        "single_graveyard": True,
    }


def activated_graveyard_exile_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    risky_cost_classes = {
        "CompositeCost",
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
        "ExileFromGraveCost",
        "ExileSourceFromGraveCost",
        "MillCardsCost",
        "OrCost",
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "RevealVariableBlackCardsFromHandCost",
        "SacrificeTargetCost",
        "TapTargetCost",
        "VariableCost",
        "XTargetsCountAdjuster",
    }
    if "Zone.GRAVEYARD" in text:
        return "activated_graveyard_exile_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_graveyard_exile_source_cost_not_supported"
    effect_matches = re.findall(r"ExileTargetEffect\s*\(", text)
    if len(effect_matches) != 1:
        return "activated_graveyard_exile_source_multiple_abilities_not_supported"
    effect_index = text.find("ExileTargetEffect")
    window = text[max(0, effect_index - 500) : effect_index + 1800]
    if "SimpleActivatedAbility" not in window:
        return "activated_graveyard_exile_source_not_simple_activated"
    parsed_target = activated_graveyard_exile_target_from_source(text)
    if isinstance(parsed_target, str):
        return parsed_target
    cost_text = "{0}"
    mana_match = re.search(r'ManaCostsImpl<[^>]*>\s*\(\s*"([^"]+)"\s*\)', window)
    generic_matches = re.findall(r"GenericManaCost\s*\(\s*(\d+)\s*\)", window)
    if mana_match:
        cost_text = mana_match.group(1)
    elif generic_matches:
        cost_text = "{" + str(sum(int(value) for value in generic_matches)) + "}"
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "activated_graveyard_exile_source_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        **parsed_target,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


def graveyard_exile_target_constraints_for(target: str, *, controller: str = "any") -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "graveyard", "controller": controller}
    if target == "creature":
        constraints["card_types"] = ["creature"]
    elif target in {"any_card", "card"}:
        constraints["card_types"] = ["card"]
    else:
        constraints["target"] = target
    return constraints


def life_gain_amount_from_oracle(metadata: dict[str, Any]) -> int | None:
    match = re.match(r"^you gain (\d+) life\.?$", oracle_text(metadata))
    if not match:
        return None
    return int(match.group(1))


def fixed_life_gain_draw_from_oracle(metadata: dict[str, Any]) -> tuple[int, int] | None:
    match = re.match(r"^you gain (\d+) life\. draw a card\.?$", oracle_text(metadata))
    if not match:
        return None
    return int(match.group(1)), 1


def fixed_life_gain_draw_from_source(source_text: str) -> tuple[int, int] | None:
    text = str(source_text or "")
    gain_matches = list(re.finditer(r"new\s+GainLifeEffect\s*\(", text))
    if len(gain_matches) != 1:
        return None
    draw_matches = list(re.finditer(r"new\s+DrawCardSourceControllerEffect\s*\(", text))
    if len(draw_matches) != 1:
        return None
    life_gain = java_constructor_int(text, "GainLifeEffect")
    draw_count = java_constructor_int_or_noarg_default(
        text,
        "DrawCardSourceControllerEffect",
        noarg_default=1,
    )
    if life_gain is None or life_gain <= 0 or draw_count != 1:
        return None
    if gain_matches[0].start() > draw_matches[0].start():
        return None
    return life_gain, draw_count


def etb_life_gain_amount_from_oracle(metadata: dict[str, Any]) -> int | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip()
    match = re.search(
        r"(?:when|whenever) [^.]* enters(?: the battlefield)?[, ]+you gain (\d+) life(?:\.|$)",
        text,
    )
    if not match:
        return None
    return int(match.group(1))


def etb_draw_count_from_oracle(metadata: dict[str, Any]) -> int | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip()
    match = re.search(
        r"(?:when|whenever) [^.]* enters(?: the battlefield)?[, ]+draw (a|one|two|three|four|five|\d+) cards?(?:\.|$)",
        text,
    )
    if not match:
        return None
    value = match.group(1)
    words = {"a": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    if value in words:
        return words[value]
    return int(value)


def dies_draw_from_oracle(metadata: dict[str, Any]) -> tuple[int, bool] | None:
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip()
    match = re.match(
        r"^(?:when|whenever) this creature dies, (you may )?draw "
        r"(a|one|two|three|four|five|\d+) cards?\.?$",
        text,
    )
    if not match:
        return None
    value = match.group(2)
    words = {"a": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5}
    count = words.get(value)
    if count is None and value.isdigit():
        count = int(value)
    if count is None:
        count = 0
    if count <= 0:
        return None
    return count, bool(match.group(1))


def etb_damage_target_from_oracle(metadata: dict[str, Any]) -> tuple[int, str] | None:
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip()
    patterns: list[tuple[str, str]] = [
        (
            r"^when this creature enters(?: the battlefield)?, "
            r"(?:it|this creature) deals (\d+) damage to any target\.?$",
            "any_target",
        ),
        (
            r"^when this creature enters(?: the battlefield)?, "
            r"(?:it|this creature) deals (\d+) damage to target creature or planeswalker\.?$",
            "creature_or_planeswalker",
        ),
        (
            r"^when this creature enters(?: the battlefield)?, "
            r"(?:it|this creature) deals (\d+) damage to target creature an opponent controls\.?$",
            "creature",
        ),
        (
            r"^when this creature enters(?: the battlefield)?, "
            r"(?:it|this creature) deals (\d+) damage to target creature\.?$",
            "creature",
        ),
    ]
    for pattern, target in patterns:
        match = re.match(pattern, text)
        if match:
            amount = int(match.group(1))
            if amount > 0:
                return amount, target
    return None


def etb_destroy_target_from_oracle(metadata: dict[str, Any]) -> tuple[str, str] | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip()
    patterns: list[tuple[str, tuple[str, str]]] = [
        (
            r"^when this creature enters, (?:you may )?destroy target artifact\.?$",
            ("remove_permanent", "artifact"),
        ),
        (
            r"^when this creature enters, (?:you may )?destroy target enchantment\.?$",
            ("remove_permanent", "enchantment"),
        ),
        (
            r"^when this creature enters, (?:you may )?destroy target artifact or enchantment(?: an opponent controls)?\.?$",
            ("remove_permanent", "artifact_or_enchantment"),
        ),
        (
            r"^when this creature enters, (?:you may )?destroy target land\.?$",
            ("remove_permanent", "land"),
        ),
        (
            r"^when this creature enters, (?:you may )?destroy target nonland permanent an opponent controls\.?$",
            ("remove_permanent", "nonland_permanent"),
        ),
        (
            r"^when this creature enters, (?:you may )?destroy target creature an opponent controls\.?$",
            ("remove_creature", "creature"),
        ),
    ]
    for pattern, result in patterns:
        if re.match(pattern, text):
            return result
    return None


def etb_recursion_target_from_phrase(phrase: str) -> str | None:
    normalized = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    target_patterns: list[tuple[str, str]] = [
        ("spirit_instant_or_sorcery", r"spirit, instant, or sorcery"),
        ("instant_or_sorcery", r"instant (?:or|and/or) sorcery"),
        ("artifact_or_enchantment", r"artifact or enchantment"),
        ("artifact_or_creature", r"artifact or creature"),
        ("creature_or_enchantment", r"creature or enchantment"),
        ("creature_or_food", r"creature or food"),
        ("artifact_creature", r"artifact creature"),
        ("noncreature_nonland", r"noncreature, nonland"),
        ("knight_card", r"knight"),
        ("mercenary_card", r"mercenary"),
        ("elf_card", r"elf"),
        ("permanent", r"permanent"),
        ("creature", r"creature"),
        ("artifact", r"artifact"),
        ("enchantment", r"enchantment"),
        ("instant", r"instant"),
        ("sorcery", r"sorcery"),
        ("land", r"land"),
        ("any_card", r"card"),
    ]
    for target_type, pattern in target_patterns:
        if re.fullmatch(pattern, normalized):
            return target_type
    return None


def word_count_value(value: str) -> int | None:
    normalized = str(value or "").strip().lower()
    words = {
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
    if normalized in words:
        return words[normalized]
    if normalized.isdigit():
        return int(normalized)
    return None


def library_pick_target_from_phrase(phrase: str) -> str | None:
    normalized = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    normalized = normalized.removeprefix("a ").removeprefix("an ")
    normalized = normalized.removesuffix(".")
    normalized = normalized.removesuffix(" cards").removesuffix(" card")
    mapping = {
        "creature or enchantment": "creature_or_enchantment",
        "creature or land": "creature_or_land",
        "instant and/or sorcery": "instant_or_sorcery",
        "instant or sorcery": "instant_or_sorcery",
        "snow permanent": "snow_permanent",
        "enchantment": "enchantment",
        "creature": "creature",
        "land": "land",
        "artifact": "artifact",
        "card": "any_card",
    }
    return mapping.get(normalized)


def library_pick_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = oracle_text(metadata)
    prefix = r"^reveal the top (?P<look>\w+) cards of your library\. "
    up_to_match = re.match(
        prefix
        + r"put up to (?P<count>\w+) (?P<phrase>.+?) cards? from among them into your hand "
        + r"and (?:the )?rest(?: of the revealed cards)? into your graveyard\.?$",
        text,
    )
    may_match = re.match(
        prefix
        + r"you may put (?P<count>a|an|one|two|three|any number of) (?P<phrase>.+?) cards? "
        + r"from among them into your hand\. put the rest into your graveyard\.?$",
        text,
    )
    match = up_to_match or may_match
    if not match:
        return "library_pick_oracle_not_simple"
    look_count = word_count_value(match.group("look"))
    if look_count is None or look_count <= 0:
        return "library_pick_oracle_look_count_not_supported"
    count_token = str(match.group("count") or "").strip().lower()
    pick_all_matching = count_token == "any number of"
    if pick_all_matching:
        pick_count = look_count
    elif count_token in {"a", "an"}:
        pick_count = 1
    else:
        pick_count = word_count_value(count_token)
    if pick_count is None or pick_count <= 0:
        return "library_pick_oracle_pick_count_not_supported"
    target = library_pick_target_from_phrase(match.group("phrase"))
    if target is None:
        return "library_pick_oracle_target_not_supported"
    return {
        "look_count": look_count,
        "pick_count": pick_count,
        "pick_target": target,
        "pick_up_to_count": True,
        "pick_all_matching": pick_all_matching,
        "rest_destination": "graveyard",
    }


def library_pick_target_from_source(source: str, filter_arg: str) -> str | None:
    text = source or ""
    filter_ref = str(filter_arg or "").strip()
    if "FILTER_CARD_CREATURE_OR_LAND" in filter_ref or "FILTER_CARD_CREATURE_OR_LAND" in text:
        return "creature_or_land"
    if "FILTER_CARD_ENCHANTMENTS" in filter_ref or "FILTER_CARD_ENCHANTMENTS" in text:
        return "enchantment"
    if "SuperType.SNOW.getPredicate" in text and "FilterPermanentCard" in text:
        return "snow_permanent"
    filter_match = re.search(r'new\s+Filter(?:Permanent)?Card\s*\(\s*"([^"]+)"\s*\)', text)
    if filter_match:
        target = library_pick_target_from_phrase(filter_match.group(1))
        if target is not None:
            return target
    if "CardType.CREATURE.getPredicate()" in text and "CardType.ENCHANTMENT.getPredicate()" in text:
        return "creature_or_enchantment"
    if "CardType.INSTANT.getPredicate()" in text and "CardType.SORCERY.getPredicate()" in text:
        return "instant_or_sorcery"
    return None


def library_pick_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    match = re.search(
        r"RevealLibraryPickControllerEffect\s*\(\s*(?P<look>\d+)\s*,\s*"
        r"(?P<pick>\d+|Integer\.MAX_VALUE)\s*,\s*(?P<filter>[^,]+)\s*,\s*"
        r"PutCards\.HAND\s*,\s*PutCards\.GRAVEYARD",
        text,
        re.S,
    )
    if not match:
        return "library_pick_source_effect_not_found"
    look_count = int(match.group("look"))
    pick_raw = match.group("pick")
    pick_all_matching = pick_raw == "Integer.MAX_VALUE"
    pick_count = look_count if pick_all_matching else int(pick_raw)
    target = library_pick_target_from_source(text, match.group("filter"))
    if target is None:
        return "library_pick_source_target_not_supported"
    return {
        "look_count": look_count,
        "pick_count": pick_count,
        "pick_target": target,
        "pick_all_matching": pick_all_matching,
        "rest_destination": "graveyard",
    }


def etb_recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_after_leading_static_keywords(metadata)
    trigger_prefix = r"^when (?:this creature|[^,]+?) enters(?: the battlefield)?, (?:you may )?"
    mana_value_match = re.match(
        trigger_prefix
        + r"return target (?P<phrase>.+?) card with (?:mana value|converted mana cost) "
        r"(?P<mana_value_max>\d+) or less from your graveyard to your hand\.?$",
        text,
    )
    if mana_value_match:
        target_type = etb_recursion_target_from_phrase(mana_value_match.group("phrase"))
        if target_type is None:
            return None
        return {
            "target": target_type,
            "count": 1,
            "up_to_count": False,
            "mana_value_max": int(mana_value_match.group("mana_value_max")),
        }
    single_match = re.match(
        trigger_prefix
        + r"return target (?P<phrase>.+?) card from your graveyard to your hand\.?$",
        text,
    )
    if single_match:
        target_type = etb_recursion_target_from_phrase(single_match.group("phrase"))
        if target_type is not None:
            return {"target": target_type, "count": 1, "up_to_count": False}
    up_to_match = re.match(
        trigger_prefix
        + r"return up to (?P<count>one|two|\d+) target (?P<phrase>.+?) cards? "
        r"from your graveyard to your hand\.?$",
        text,
    )
    if up_to_match:
        target_type = etb_recursion_target_from_phrase(up_to_match.group("phrase"))
        count = word_count_value(up_to_match.group("count"))
        if target_type is not None and count is not None:
            return {"target": target_type, "count": count, "up_to_count": True}
    return None


def etb_library_pick_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = oracle_text_after_leading_static_keywords(metadata)
    trigger_prefix = r"^when (?:this creature|[^,]+?) enters(?: the battlefield)?, "
    match = re.match(
        trigger_prefix
        + r"look at the top (?P<look>\w+) cards of your library(?:, then|\.) "
        + r"put one of (?:them|those cards) into your hand and "
        + r"(?:the other|the rest) into your graveyard\.?$",
        text,
    )
    if not match:
        return "etb_library_pick_oracle_not_simple"
    look_count = word_count_value(match.group("look"))
    if look_count is None or look_count <= 0:
        return "etb_library_pick_oracle_look_count_not_supported"
    return {
        "look_count": look_count,
        "pick_count": 1,
        "pick_target": "any_card",
        "rest_destination": "graveyard",
    }


def etb_library_pick_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    match = re.search(
        r"LookLibraryAndPickControllerEffect\s*\(\s*(?P<look>\d+)\s*,\s*"
        r"(?P<pick>\d+)\s*,\s*PutCards\.HAND\s*,\s*PutCards\.GRAVEYARD",
        text,
        re.S,
    )
    if not match:
        return "etb_library_pick_source_effect_not_found"
    return {
        "look_count": int(match.group("look")),
        "pick_count": int(match.group("pick")),
        "pick_target": "any_card",
        "rest_destination": "graveyard",
    }


def dies_recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text_after_leading_static_keywords(metadata)
    match = re.match(
        r"^when [^,]+ dies, return (?P<another>another )?target (?P<phrase>.+?) "
        r"cards? from your graveyard to your hand\.?$",
        text,
    )
    if not match:
        return None
    target_type = etb_recursion_target_from_phrase(match.group("phrase"))
    if target_type is None:
        return None
    return {
        "target": target_type,
        "count": 1,
        "exclude_self": bool(match.group("another")),
    }


UNSUPPORTED_SIMPLE_MANA_ORACLE_TOKENS = {
    "sacrifice",
    "discard",
    "pay ",
    "instead",
    "if ",
    "for each",
    "spend this mana only",
    "tap an untapped",
}


def _unique_mana_symbols(symbols: list[str]) -> str:
    return "".join(dict.fromkeys(symbols))


def _brace_mana_symbols(text: str) -> list[str]:
    return [symbol.upper() for symbol in re.findall(r"\{([wubrgc])\}", text)]


def simple_mana_source_detail_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    if any(token in text for token in UNSUPPORTED_SIMPLE_MANA_ORACLE_TOKENS):
        return None
    if text == "{t}: add one mana of any color.":
        return {"produces": "WUBRG", "mana_produced": 1}
    match = re.match(r"^\{t\}: add \{([wubrgc])\}\.?$", text)
    if match:
        symbol = match.group(1).upper()
        return {"produces": symbol, "mana_produced": 1, "produced_mana_symbols": [symbol]}
    match = re.match(r"^\{t\}: add ((?:\{[wubrgc]\}){2,})\.?$", text)
    if match:
        symbols = _brace_mana_symbols(match.group(1))
        if len(symbols) >= 2:
            return {
                "produces": _unique_mana_symbols(symbols),
                "mana_produced": len(symbols),
                "produced_mana_symbols": symbols,
            }
    match = re.match(r"^(?P<cost>(?:\{[0-9wubrgc]+\})+), \{t\}: add (?P<mana>(?:\{[wubrgc]\})+)\.?$", text)
    if match:
        symbols = _brace_mana_symbols(match.group("mana"))
        if symbols:
            return {
                "produces": _unique_mana_symbols(symbols),
                "mana_produced": len(symbols),
                "produced_mana_symbols": symbols,
                "activation_mana_cost": match.group("cost").upper(),
            }
    match = re.match(r"^\{t\}: add \{([wubrgc])\} or \{([wubrgc])\}\.?$", text)
    if match:
        produced = "".join(dict.fromkeys([match.group(1).upper(), match.group(2).upper()]))
        return {"produces": produced, "mana_produced": 1}
    return None


def simple_mana_source_from_oracle(metadata: dict[str, Any]) -> tuple[str, int] | None:
    detail = simple_mana_source_detail_from_oracle(metadata)
    if detail is None:
        return None
    return str(detail["produces"]), int(detail["mana_produced"])


def simple_mana_source_source_blocker(source_text: str, ability_class_values: set[str]) -> str | None:
    text = source_text or ""
    unsupported_markers = {
        "SacrificeSourceCost": "mana_source_source_sacrifice_cost_not_supported",
        "SacrificeTargetCost": "mana_source_source_sacrifice_target_cost_not_supported",
        "Discard": "mana_source_source_discard_cost_not_supported",
        "PayLifeCost": "mana_source_source_pay_life_cost_not_supported",
        "ExileSourceCost": "mana_source_source_exile_cost_not_supported",
        "ConditionalMana": "mana_source_source_conditional_mana_not_supported",
        "spend this mana only": "mana_source_source_restricted_spend_not_supported",
    }
    for marker, reason in unsupported_markers.items():
        if marker in text:
            return reason
    if "SimpleManaAbility" in ability_class_values and "TapSourceCost" not in text:
        return "mana_source_simple_source_missing_tap_cost"
    return None


COUNT_WORDS = {
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


def library_tutor_target_from_phrase(phrase: str) -> str | None:
    normalized = re.sub(r"\s+", " ", str(phrase or "").strip().lower())
    normalized = normalized.removesuffix(".")
    mapping = {
        "basic land card": "basic_land",
        "basic land cards": "basic_land",
        "basic lands": "basic_land",
        "basic land cards and/or gate cards": "basic_land_or_gate",
        "basic lands and/or gates": "basic_land_or_gate",
        "basic land cards and/or town cards with different names": "basic_land_or_town",
        "forest card": "forest",
        "forest cards": "forest",
        "land cards": "land",
        "snow land card": "snow_land",
        "plains, island, swamp, or mountain card": "plains_island_swamp_or_mountain",
        "plains, island, swamp, mountain, or forest card": "basic_land_type",
        "sorcery card": "sorcery",
    }
    return mapping.get(normalized)


def parse_library_tutor_query(query: str) -> dict[str, Any] | None:
    text = re.sub(r"\s+", " ", str(query or "").strip().lower())
    up_to = False
    count = 1
    phrase = text
    match = re.match(r"^up to (?P<count>\w+) (?P<phrase>.+)$", text)
    if match:
        count_text = match.group("count")
        count = COUNT_WORDS.get(count_text) or (int(count_text) if count_text.isdigit() else 0)
        up_to = True
        phrase = match.group("phrase")
    else:
        for prefix in ("a ", "an "):
            if phrase.startswith(prefix):
                phrase = phrase[len(prefix) :]
                break
    target = library_tutor_target_from_phrase(phrase)
    if target is None or count <= 0:
        return None
    return {"target": target, "count": count, "up_to_count": up_to}


def library_tutor_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = oracle_text(metadata)
    if "additional cost" in text:
        return "library_tutor_oracle_additional_cost_not_supported"
    top_match = re.match(
        r"^search your library for (?P<query>.+?), reveal it, then shuffle and put that card on top\.?$",
        text,
    )
    if top_match:
        parsed = parse_library_tutor_query(top_match.group("query"))
        if parsed is None:
            return "library_tutor_oracle_target_not_supported"
        parsed["destination"] = "library_top"
        parsed["enters_tapped"] = False
        return parsed

    battle_match = re.match(
        r"^search your library for (?P<query>.+?)(?:,| and) put "
        r"(?:it|that card|them|those cards) onto the battlefield(?P<tapped> tapped)?"
        r"(?:, then shuffle|\. then shuffle)\.?$",
        text,
    )
    if battle_match:
        parsed = parse_library_tutor_query(battle_match.group("query"))
        if parsed is None:
            return "library_tutor_oracle_target_not_supported"
        parsed["destination"] = "battlefield"
        parsed["enters_tapped"] = bool(battle_match.group("tapped"))
        return parsed
    return "library_tutor_oracle_not_simple"


def library_tutor_target_from_source(source: str) -> str | None:
    text = source or ""
    if "FILTER_CARD_BASIC_LAND" in text:
        return "basic_land"
    if "FILTER_CARD_LANDS" in text:
        return "land"
    filter_match = re.search(r'new\s+Filter(?:Land)?Card\s*\(\s*"([^"]+)"\s*\)', text)
    if filter_match:
        return library_tutor_target_from_phrase(filter_match.group(1))
    return None


def library_tutor_count_from_source(source: str) -> tuple[int, bool]:
    match = re.search(
        r"TargetCard(?:WithDifferentName)?InLibrary\s*\(\s*0\s*,\s*(\d+)\s*,",
        source or "",
        re.S,
    )
    if match:
        return int(match.group(1)), True
    return 1, False


def library_tutor_from_source(source: str, effect_class: str) -> dict[str, Any] | str:
    text = source or ""
    if has_additional_cost(text):
        return "library_tutor_source_additional_cost_not_supported"
    if "TargetCardWithDifferentNameInLibrary" in text:
        return "library_tutor_source_distinct_names_not_supported"
    target = library_tutor_target_from_source(text)
    if target is None:
        return "library_tutor_source_target_not_supported"
    count, up_to = library_tutor_count_from_source(text)
    if effect_class == "SearchLibraryPutInPlayEffect":
        if "SearchLibraryPutInPlayEffect" not in text:
            return "library_tutor_source_effect_not_found"
        tapped_match = re.search(
            r"SearchLibraryPutInPlayEffect\s*\(\s*(?:new\s+TargetCardInLibrary\s*\([^)]*\)|\w+)\s*,\s*(true|false)",
            text,
            re.S,
        )
        return {
            "target": target,
            "count": count,
            "up_to_count": up_to,
            "destination": "battlefield",
            "enters_tapped": bool(tapped_match and tapped_match.group(1) == "true"),
        }
    if effect_class == "SearchLibraryPutOnLibraryEffect":
        if "SearchLibraryPutOnLibraryEffect" not in text:
            return "library_tutor_source_effect_not_found"
        return {
            "target": target,
            "count": count,
            "up_to_count": up_to,
            "destination": "library_top",
            "enters_tapped": False,
        }
    return "library_tutor_source_effect_not_supported"


def target_constraints_for(target: str) -> dict[str, Any]:
    if target == "any_target":
        return {"scope": "any_target"}
    if target == "attacking_creature":
        return {"card_types": ["creature"], "combat_state": "attacking"}
    if target == "blocking_creature":
        return {"card_types": ["creature"], "combat_state": "blocking"}
    if target == "attacking_or_blocking_creature":
        return {"card_types": ["creature"], "combat_state": "attacking_or_blocking"}
    if target == "tapped_creature":
        return {"card_types": ["creature"], "tapped_state": "tapped"}
    if target == "untapped_creature":
        return {"card_types": ["creature"], "tapped_state": "untapped"}
    if target == "flying_creature":
        return {"card_types": ["creature"], "required_keywords": ["flying"]}
    if target == "nonblack_creature":
        return {"card_types": ["creature"], "exclude_colors": ["B"]}
    if target == "black_creature":
        return {"card_types": ["creature"], "target_colors": ["B"]}
    if target == "green_or_white_creature":
        return {"card_types": ["creature"], "target_colors": ["G", "W"]}
    if target == "nonartifact_creature":
        return {"card_types": ["creature"], "exclude_card_types": ["artifact"]}
    if target == "nonartifact_nonblack_creature":
        return {"card_types": ["creature"], "exclude_card_types": ["artifact"], "exclude_colors": ["B"]}
    if target == "legendary_creature":
        return {"card_types": ["creature"], "required_supertypes": ["legendary"]}
    if target == "monocolored_creature":
        return {"card_types": ["creature"], "color_count_exact": 1}
    if target == "blue_or_black_flying_creature":
        return {"card_types": ["creature"], "target_colors": ["U", "B"], "required_keywords": ["flying"]}
    if target == "black_or_red_permanent":
        return {"card_types": ["permanent"], "target_colors": ["B", "R"]}
    if target == "nonwhite_permanent":
        return {"card_types": ["permanent"], "exclude_colors": ["W"]}
    if target == "noncreature_permanent":
        return {"card_types": ["permanent"], "exclude_card_types": ["creature"]}
    if target == "noncreature_artifact":
        return {"card_types": ["artifact"], "exclude_card_types": ["creature"]}
    if target == "creature_power_4_or_greater":
        return {"card_types": ["creature"], "power_min": 4}
    if target == "creature_power_3_or_greater":
        return {"card_types": ["creature"], "power_min": 3}
    if target == "creature_mana_value_3_or_greater":
        return {"card_types": ["creature"], "mana_value_min": 3}
    if target == "creature":
        return {"card_types": ["creature"]}
    if target == "creature_or_planeswalker":
        return {"card_types": ["creature", "planeswalker"]}
    if target == "player":
        return {"scope": "player"}
    if target == "player_or_planeswalker":
        return {"scope": "player_or_planeswalker"}
    if target == "opponent":
        return {"scope": "opponent"}
    if target in {"artifact", "enchantment", "land", "permanent", "nonland_permanent"}:
        return {"card_types": [target]}
    if target == "artifact_or_enchantment":
        return {"card_types": ["artifact", "enchantment"]}
    if target == "artifact_or_creature":
        return {"card_types": ["artifact", "creature"]}
    if target == "creature_or_enchantment":
        return {"card_types": ["creature", "enchantment"]}
    if target == "creature_enchantment_or_planeswalker":
        return {"card_types": ["creature", "enchantment", "planeswalker"]}
    return {"target": target}


def proposal_notes(row: dict[str, Any], scope: str) -> str:
    scope_kind = "runtime-backed exact-scope adapter"
    if str(row.get("adapter_work_unit") or "") in RAMP_UNITS:
        scope_kind = "activated mana-source permanent"
    elif scope == TOKEN_SPELL_SCOPE:
        scope_kind = "fixed spell-resolution creature-token maker"
    elif scope == DAMAGE_GAIN_LIFE_SCOPE:
        scope_kind = "fixed damage plus controller life-gain spell"
    elif scope == DESTROY_GAIN_LIFE_SCOPE:
        scope_kind = "fixed destroy-target plus controller life-gain spell"
    elif scope == LIFE_GAIN_DRAW_SCOPE:
        scope_kind = "fixed controller life-gain plus draw-card spell"
    elif scope == BOOST_DRAW_SCOPE:
        scope_kind = "fixed target-creature boost plus draw-card spell"
    elif scope == DESTROY_DRAW_SCOPE:
        scope_kind = "fixed destroy-target plus draw-card spell"
    elif scope == BOUNCE_DRAW_SCOPE:
        scope_kind = "fixed return-target-to-hand plus draw-card spell"
    elif scope == BOOST_KEYWORD_SCOPE:
        scope_kind = "fixed target-creature boost plus until-end-of-turn keyword spell"
    elif scope == BOOST_CONTROLLED_SPELL_SCOPE:
        scope_kind = "fixed controlled-creature boost until end of turn spell"
    elif scope == TARGET_BOOST_ACTIVATED_SCOPE:
        scope_kind = "permanent simple activated target-creature boost until end of turn"
    elif scope == TARGET_KEYWORD_ACTIVATED_SCOPE:
        scope_kind = "permanent simple activated target-creature keyword until end of turn"
    elif scope == STATIC_CONTROLLED_PT_SCOPE:
        scope_kind = "permanent static controlled-creature power/toughness boost"
    elif scope == STATIC_GRAVEYARD_COUNT_PT_SCOPE:
        scope_kind = "creature static source power/toughness equal to graveyard card count"
    elif scope == STATIC_GRAVEYARD_THRESHOLD_BOOST_SCOPE:
        scope_kind = "creature static source power/toughness boost gated by graveyard card count"
    elif scope == STATIC_GRAVEYARD_COUNT_BOOST_SCOPE:
        scope_kind = "creature static source power/toughness boost equal to graveyard card count"
    elif scope in {
        ETB_LIFE_GAIN_CREATURE_SCOPE,
        ETB_DRAW_CREATURE_SCOPE,
        ETB_DAMAGE_CREATURE_SCOPE,
        ETB_DESTROY_CREATURE_SCOPE,
        ETB_RECURSION_CREATURE_SCOPE,
        ETB_MILL_RECURSION_CREATURE_SCOPE,
        ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE,
        ETB_LIBRARY_PICK_CREATURE_SCOPE,
        ETB_TOKEN_CREATURE_SCOPE,
        ETB_ADD_COUNTERS_CREATURE_SCOPE,
    }:
        scope_kind = "creature enter-the-battlefield triggered ability"
    elif scope == DIES_RECURSION_CREATURE_SCOPE:
        scope_kind = "creature dies triggered graveyard-to-hand ability"
    elif scope == CREATURE_TAP_DAMAGE_SCOPE:
        scope_kind = "creature with tap-only activated damage ability"
    elif scope == PERMANENT_ACTIVATED_DAMAGE_SCOPE:
        scope_kind = "permanent with a simple activated damage ability"
    elif scope == PERMANENT_ACTIVATED_DESTROY_SCOPE:
        scope_kind = "permanent with a simple activated destroy-target ability"
    elif scope == PERMANENT_ACTIVATED_DRAW_SCOPE:
        scope_kind = "permanent with a simple activated draw ability"
    elif scope == PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE:
        scope_kind = "permanent with a simple activated draw-then-discard ability"
    elif scope == SPELL_CAST_DRAW_ENGINE_SCOPE:
        scope_kind = "permanent with a triggered draw ability on casting matching spells"
    elif scope == RECURSION_BATTLEFIELD_ALL_SCOPE:
        scope_kind = "return-all matching graveyard cards to battlefield spell"
    elif scope == GRAVEYARD_EXILE_SPELL_SCOPE:
        scope_kind = "exile target graveyard card spell"
    elif scope == PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE:
        scope_kind = "permanent with a simple activated fixed life-gain ability"
    elif scope == PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE:
        scope_kind = "permanent with a simple activated graveyard-exile ability"
    elif scope == PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE:
        scope_kind = "permanent with a simple activated graveyard-to-library ability"
    elif scope == PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE:
        scope_kind = "permanent with a simple activated graveyard-to-hand ability"
    elif scope == PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE:
        scope_kind = "permanent with a simple activated graveyard-to-battlefield ability"
    elif scope == LIBRARY_PICK_SPELL_SCOPE:
        scope_kind = "fixed reveal-top-library pick-to-hand spell"
    elif scope == GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE:
        scope_kind = "graveyard simple activated self-return-to-hand ability"
    elif scope == GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE:
        scope_kind = "graveyard simple activated self-return-to-battlefield ability"
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
    etb_draw_creature_unit = is_creature_etb_draw_unit(row)
    dies_draw_creature_unit = is_creature_dies_draw_unit(row)
    spell_cast_draw_engine_unit = is_spell_cast_draw_engine_unit(row)
    permanent_activated_draw_discard_unit = is_permanent_activated_draw_discard_unit(row)
    dies_recursion_creature_unit = is_creature_dies_recursion_unit(row)
    etb_damage_creature_unit = is_creature_etb_damage_unit(row)
    etb_destroy_creature_unit = is_creature_etb_destroy_unit(row)
    etb_recursion_creature_unit = is_creature_etb_recursion_unit(row)
    etb_mill_recursion_creature_unit = is_creature_etb_mill_then_return_unit(row)
    etb_graveyard_to_library_creature_unit = is_creature_etb_graveyard_to_library_unit(row)
    etb_library_pick_creature_unit = is_creature_etb_library_pick_unit(row)
    etb_token_creature_unit = is_creature_etb_token_unit(row)
    etb_add_counters_creature_unit = is_creature_etb_add_counters_unit(row)
    creature_tap_damage_unit = is_creature_tap_damage_unit(row)
    permanent_activated_draw_unit = is_permanent_activated_draw_unit(row)
    permanent_activated_damage_unit = is_permanent_activated_damage_unit(row)
    permanent_activated_destroy_unit = is_permanent_activated_destroy_unit(row)
    permanent_activated_life_gain_unit = is_permanent_activated_life_gain_unit(row)
    permanent_activated_self_boost_unit = is_permanent_activated_self_boost_unit(row)
    permanent_activated_target_boost_unit = is_permanent_activated_target_boost_unit(row)
    permanent_activated_target_keyword_unit = is_permanent_activated_target_keyword_unit(row)
    static_controlled_pt_unit = is_static_controlled_pt_unit(row)
    static_graveyard_count_pt_unit = is_static_graveyard_count_pt_unit(row)
    static_graveyard_threshold_boost_unit = is_static_graveyard_threshold_boost_unit(row)
    static_graveyard_count_boost_unit = is_static_graveyard_count_boost_unit(row)
    permanent_activated_recursion_to_hand_unit = is_permanent_activated_recursion_to_hand_unit(row)
    permanent_activated_recursion_to_battlefield_unit = is_permanent_activated_recursion_to_battlefield_unit(row)
    permanent_activated_graveyard_exile_unit = is_permanent_activated_graveyard_exile_unit(row)
    permanent_activated_graveyard_to_library_unit = is_permanent_activated_graveyard_to_library_unit(row)
    graveyard_self_return_to_hand_unit = (
        unit == RECURSION_UNIT
        and effect_classes(row) == {"ReturnSourceFromGraveyardToHandEffect"}
        and bool({"SimpleActivatedAbility", "ActivateAsSorceryActivatedAbility"} & ability_classes(row))
    )
    graveyard_self_return_to_battlefield_unit = (
        unit == RECURSION_UNIT
        and effect_classes(row) == {"ReturnSourceFromGraveyardToBattlefieldEffect"}
        and "SimpleActivatedAbility" in ability_classes(row)
    )
    graveyard_self_return_unit = (
        graveyard_self_return_to_hand_unit or graveyard_self_return_to_battlefield_unit
    )
    boost_keyword_spell_unit = is_boost_keyword_spell_unit(row)
    fixed_token_spell_unit = unit == TOKEN_SPELL_UNIT
    if (
        unit not in SUPPORTED_UNITS
        and not keyword_creature_unit
        and not etb_life_gain_creature_unit
        and not etb_draw_creature_unit
        and not dies_draw_creature_unit
        and not spell_cast_draw_engine_unit
        and not permanent_activated_draw_discard_unit
        and not dies_recursion_creature_unit
        and not etb_damage_creature_unit
        and not etb_destroy_creature_unit
        and not etb_recursion_creature_unit
        and not etb_mill_recursion_creature_unit
        and not etb_graveyard_to_library_creature_unit
        and not etb_library_pick_creature_unit
        and not etb_token_creature_unit
        and not etb_add_counters_creature_unit
        and not creature_tap_damage_unit
        and not permanent_activated_draw_unit
        and not permanent_activated_damage_unit
        and not permanent_activated_destroy_unit
        and not permanent_activated_life_gain_unit
        and not permanent_activated_self_boost_unit
        and not permanent_activated_target_boost_unit
        and not permanent_activated_target_keyword_unit
        and not static_controlled_pt_unit
        and not static_graveyard_count_pt_unit
        and not static_graveyard_threshold_boost_unit
        and not static_graveyard_count_boost_unit
        and not permanent_activated_recursion_to_hand_unit
        and not permanent_activated_recursion_to_battlefield_unit
        and not permanent_activated_graveyard_exile_unit
        and not permanent_activated_graveyard_to_library_unit
        and not boost_keyword_spell_unit
        and not fixed_token_spell_unit
    ):
        return None, "unsupported_adapter_work_unit"
    if not metadata:
        return None, "postgres_card_metadata_missing"
    if not str(metadata.get("oracle_text") or "").strip():
        return None, "oracle_text_missing"

    if (
        (unit in SPELL_UNITS or boost_keyword_spell_unit)
        and not etb_life_gain_creature_unit
        and not etb_draw_creature_unit
        and not dies_draw_creature_unit
        and not spell_cast_draw_engine_unit
        and not permanent_activated_draw_discard_unit
        and not dies_recursion_creature_unit
        and not etb_damage_creature_unit
        and not etb_destroy_creature_unit
        and not etb_recursion_creature_unit
        and not etb_mill_recursion_creature_unit
        and not etb_graveyard_to_library_creature_unit
        and not etb_library_pick_creature_unit
        and not etb_token_creature_unit
        and not etb_add_counters_creature_unit
        and not creature_tap_damage_unit
        and not permanent_activated_draw_unit
        and not permanent_activated_damage_unit
        and not permanent_activated_destroy_unit
        and not permanent_activated_life_gain_unit
        and not permanent_activated_self_boost_unit
        and not permanent_activated_target_keyword_unit
        and not static_controlled_pt_unit
        and not static_graveyard_count_pt_unit
        and not static_graveyard_threshold_boost_unit
        and not static_graveyard_count_boost_unit
        and not permanent_activated_recursion_to_hand_unit
        and not permanent_activated_recursion_to_battlefield_unit
        and not permanent_activated_graveyard_exile_unit
        and not permanent_activated_graveyard_to_library_unit
        and not graveyard_self_return_unit
    ):
        if not is_spell(metadata):
            return None, "not_instant_or_sorcery_spell"
        if ability_kind(row) != "one_shot":
            return None, "not_one_shot_spell_ability"
        if has_additional_cost(source_text) or "additional cost" in oracle_text(metadata):
            if unit == DAMAGE_UNIT and effect_classes(row) == {"DamageTargetEffect"}:
                pass
            elif unit == DRAW_UNIT and effect_classes(row) == {"DrawCardSourceControllerEffect"}:
                pass
            else:
                return None, "additional_cost_detected"

    flags = spell_flags(metadata)
    classes = effect_classes(row)

    if permanent_activated_draw_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_draw_not_permanent"
        oracle_activation = activated_draw_from_oracle(metadata)
        if isinstance(oracle_activation, str):
            return None, oracle_activation
        parsed_activation = activated_draw_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in (
            "count",
            "activation_cost_mana",
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_requires_tap",
            "activation_requires_sacrifice",
            "activation_life_cost",
            "activation_sacrifice_target",
        ):
            if parsed_activation.get(key) != oracle_activation.get(key):
                return None, "activated_draw_source_oracle_mismatch"
        oracle_count = int(oracle_activation["count"])
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_type = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        effect_json = {
            "effect": "draw_engine",
            "battle_model_scope": PERMANENT_ACTIVATED_DRAW_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "draw_cards",
            "activated_draw": True,
            "activated_draw_count": oracle_count,
            "count": oracle_count,
            "permanent_type": permanent_type,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **parsed_activation,
        }
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_draw"] = True
            effect_json["activated_draw_on_self_sacrifice"] = True
            effect_json["draw_on_self_sacrifice"] = oracle_count
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_draw",
        ), "selected_exact_scope"

    if permanent_activated_draw_discard_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_draw_discard_not_permanent"
        oracle_activation = activated_draw_discard_from_oracle(metadata)
        if isinstance(oracle_activation, str):
            return None, oracle_activation
        parsed_activation = activated_draw_discard_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in (
            "draw_count",
            "discard_count",
            "activation_cost_mana",
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_requires_tap",
            "activation_requires_sacrifice",
            "activation_life_cost",
            "activation_sacrifice_target",
        ):
            if parsed_activation.get(key) != oracle_activation.get(key):
                return None, "activated_draw_discard_source_oracle_mismatch"
        draw_count = int(oracle_activation["draw_count"])
        discard_count = int(oracle_activation["discard_count"])
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_type = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        effect_json = {
            "effect": "draw_engine",
            "battle_model_scope": PERMANENT_ACTIVATED_DRAW_DISCARD_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "draw_discard",
            "activated_draw_discard": True,
            "activated_draw_count": draw_count,
            "activated_discard_count": discard_count,
            "draw_count": draw_count,
            "discard_count": discard_count,
            "count": draw_count,
            "permanent_type": permanent_type,
            "xmage_effect_class": "DrawDiscardControllerEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **parsed_activation,
        }
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_draw_discard"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_draw_discard",
        ), "selected_exact_scope"

    if spell_cast_draw_engine_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "spell_cast_draw_not_permanent"
        oracle_spec = spell_cast_draw_filter_from_oracle(metadata)
        if isinstance(oracle_spec, str):
            return None, oracle_spec
        source_spec = spell_cast_draw_filter_from_source(source_text)
        if isinstance(source_spec, str):
            return None, source_spec
        if not spell_cast_draw_specs_match(oracle_spec, source_spec):
            return None, "spell_cast_draw_source_oracle_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        effect_json = {
            "effect": permanent_effect if permanent_effect == "creature" else "draw_engine",
            "battle_model_scope": SPELL_CAST_DRAW_ENGINE_SCOPE,
            "ability_kind": "triggered",
            "trigger_effect": "draw_cards",
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "SpellCastControllerTriggeredAbility",
            **oracle_spec,
        }
        if permanent_effect == "creature":
            effect_json["is_creature_permanent"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_spell_cast_draw_engine",
        ), "selected_exact_scope"

    if permanent_activated_destroy_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_destroy_not_permanent"
        oracle_destroy = activated_destroy_from_oracle(metadata)
        if oracle_destroy is None:
            return None, "activated_destroy_oracle_not_simple"
        parsed_activation = activated_destroy_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        oracle_effect, oracle_target_type = oracle_destroy
        if str(parsed_activation["target"]) != str(oracle_target_type):
            return None, "activated_destroy_source_oracle_target_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        target_base = restricted_target_base(oracle_target_type)
        activated_effect = {
            "effect": oracle_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_DESTROY_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "destroy_target",
            "activated_remove_effect": oracle_effect,
            "activated_remove_target": oracle_target_type,
            "target": target_base,
            "target_constraints": target_constraints_for(oracle_target_type),
            "destination": "graveyard",
            "xmage_effect_class": "DestroyTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_DESTROY_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_DESTROY_SCOPE,
            "activated_remove_effect": oracle_effect,
            "activated_remove_target": oracle_target_type,
            "target": target_base,
            "target_constraints": target_constraints_for(oracle_target_type),
            "destination": "graveyard",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "DestroyTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
        }
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_destroy"] = True
            activated_effect["activated_self_sacrifice_destroy"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_destroy_target",
        ), "selected_exact_scope"

    if permanent_activated_life_gain_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_life_gain_not_permanent"
        oracle_life_gain = activated_life_gain_from_oracle(metadata)
        if isinstance(oracle_life_gain, str):
            return None, oracle_life_gain
        parsed_activation = activated_life_gain_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in (
            "life_gain_amount",
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_requires_tap",
            "activation_requires_sacrifice",
        ):
            if parsed_activation.get(key) != oracle_life_gain.get(key):
                return None, f"activated_life_gain_source_oracle_{key}_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        activated_effect = {
            "effect": "life_gain",
            "battle_model_scope": PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "controller_gain_life",
            "target": "self",
            "target_controller": "self",
            "life_gain_amount": oracle_life_gain["life_gain_amount"],
            "activated_life_gain_amount": oracle_life_gain["life_gain_amount"],
            "xmage_effect_class": "GainLifeEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "controller_gain_life",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE,
            "target": "self",
            "target_controller": "self",
            "life_gain_amount": oracle_life_gain["life_gain_amount"],
            "activated_life_gain_amount": oracle_life_gain["life_gain_amount"],
            "permanent_type": permanent_effect,
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "GainLifeEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_life_gain"] = True
            activated_effect["activated_self_sacrifice_life_gain"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_life_gain",
        ), "selected_exact_scope"

    if permanent_activated_self_boost_unit:
        if not is_creature_metadata(metadata):
            return None, "activated_self_boost_not_creature"
        oracle_boost = activated_self_boost_from_oracle(metadata)
        if isinstance(oracle_boost, str):
            return None, oracle_boost
        parsed_activation = activated_self_boost_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        if (
            int(parsed_activation["power_delta"]) != int(oracle_boost["power_delta"])
            or int(parsed_activation["toughness_delta"]) != int(oracle_boost["toughness_delta"])
        ):
            return None, "activated_self_boost_source_oracle_boost_mismatch"
        source_cost = (
            int(parsed_activation["activation_cost_generic"]),
            list(parsed_activation["activation_cost_colors"]),
            bool(parsed_activation["activation_requires_tap"]),
        )
        oracle_cost = (
            int(oracle_boost["activation_cost_generic"]),
            list(oracle_boost["activation_cost_colors"]),
            bool(oracle_boost["activation_requires_tap"]),
        )
        if source_cost != oracle_cost:
            return None, "activated_self_boost_source_oracle_cost_mismatch"
        activated_effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": SELF_BOOST_ACTIVATED_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "self_stat_modifier_until_eot",
            "target": "self",
            "target_controller": "self",
            "target_constraints": {"source": "self", "card_types": ["creature"]},
            "power_delta": int(oracle_boost["power_delta"]),
            "toughness_delta": int(oracle_boost["toughness_delta"]),
            "power_boost": int(oracle_boost["power_delta"]),
            "toughness_boost": int(oracle_boost["toughness_delta"]),
            "duration": "until_end_of_turn",
            "xmage_effect_class": "BoostSourceEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": False,
        }
        effect_json = {
            "effect": "creature",
            "battle_model_scope": SELF_BOOST_ACTIVATED_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": SELF_BOOST_ACTIVATED_SCOPE,
            "target": "self",
            "target_controller": "self",
            "target_constraints": {"source": "self", "card_types": ["creature"]},
            "power_delta": int(oracle_boost["power_delta"]),
            "toughness_delta": int(oracle_boost["toughness_delta"]),
            "power_boost": int(oracle_boost["power_delta"]),
            "toughness_boost": int(oracle_boost["toughness_delta"]),
            "duration": "until_end_of_turn",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "BoostSourceEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": False,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_self_boost_until_eot",
        ), "selected_exact_scope"

    if permanent_activated_target_boost_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_target_boost_not_permanent"
        oracle_boost = activated_target_boost_from_oracle(metadata)
        if isinstance(oracle_boost, str):
            return None, oracle_boost
        parsed_activation = activated_target_boost_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in ("power_delta", "toughness_delta", "target", "target_controller"):
            if parsed_activation.get(key) != oracle_boost.get(key):
                return None, f"activated_target_boost_source_oracle_{key}_mismatch"
        source_cost = (
            int(parsed_activation["activation_cost_generic"]),
            list(parsed_activation["activation_cost_colors"]),
            bool(parsed_activation["activation_requires_tap"]),
            bool(parsed_activation["activation_requires_sacrifice"]),
        )
        oracle_cost = (
            int(oracle_boost["activation_cost_generic"]),
            list(oracle_boost["activation_cost_colors"]),
            bool(oracle_boost["activation_requires_tap"]),
            bool(oracle_boost["activation_requires_sacrifice"]),
        )
        if source_cost != oracle_cost:
            return None, "activated_target_boost_source_oracle_cost_mismatch"
        target_constraints = {"card_types": ["creature"]}
        if bool(parsed_activation["activation_requires_sacrifice"]):
            target_constraints["exclude_source"] = True
        activated_effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": TARGET_BOOST_ACTIVATED_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "target_stat_modifier_until_eot",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": target_constraints,
            "power_delta": int(oracle_boost["power_delta"]),
            "toughness_delta": int(oracle_boost["toughness_delta"]),
            "power_boost": int(oracle_boost["power_delta"]),
            "toughness_boost": int(oracle_boost["toughness_delta"]),
            "duration": "until_end_of_turn",
            "xmage_effect_class": "BoostTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": TARGET_BOOST_ACTIVATED_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "target_stat_modifier_until_eot",
            "activated_battle_model_scope": TARGET_BOOST_ACTIVATED_SCOPE,
            "target": "creature",
            "target_controller": "any",
            "target_constraints": target_constraints,
            "power_delta": int(oracle_boost["power_delta"]),
            "toughness_delta": int(oracle_boost["toughness_delta"]),
            "power_boost": int(oracle_boost["power_delta"]),
            "toughness_boost": int(oracle_boost["toughness_delta"]),
            "duration": "until_end_of_turn",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "BoostTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_target_boost_until_eot",
        ), "selected_exact_scope"

    if permanent_activated_target_keyword_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_target_keyword_not_permanent"
        keyword_abilities = ability_classes(row).intersection(TARGET_GRANT_KEYWORD_ABILITY_CLASSES)
        if len(keyword_abilities) != 1:
            return None, "activated_target_keyword_ability_not_supported"
        keyword_ability_class = next(iter(keyword_abilities))
        oracle_keyword = activated_target_keyword_from_oracle(metadata)
        if isinstance(oracle_keyword, str):
            return None, oracle_keyword
        parsed_activation = activated_target_keyword_from_source(source_text, keyword_ability_class)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in ("keyword", "target", "target_controller", "exclude_source", "target_constraints"):
            if parsed_activation.get(key) != oracle_keyword.get(key):
                return None, f"activated_target_keyword_source_oracle_{key}_mismatch"
        source_cost = (
            int(parsed_activation["activation_cost_generic"]),
            list(parsed_activation["activation_cost_colors"]),
            bool(parsed_activation["activation_requires_tap"]),
        )
        oracle_cost = (
            int(oracle_keyword["activation_cost_generic"]),
            list(oracle_keyword["activation_cost_colors"]),
            bool(oracle_keyword["activation_requires_tap"]),
        )
        if source_cost != oracle_cost:
            return None, "activated_target_keyword_source_oracle_cost_mismatch"
        target_constraints = dict(oracle_keyword.get("target_constraints") or {"card_types": ["creature"]})
        self_keywords = static_keywords_from_oracle(metadata)
        self_keyword_list: list[str] = []
        if self_keywords:
            ability_keywords = keywords_from_ability_classes(row)
            if not self_keywords.issubset(ability_keywords):
                return None, "activated_target_keyword_static_keyword_mismatch"
            self_keyword_list = ordered_keywords(self_keywords)
        activated_effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": TARGET_KEYWORD_ACTIVATED_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "target_keyword_until_eot",
            "target": oracle_keyword["target"],
            "target_controller": oracle_keyword["target_controller"],
            "target_constraints": target_constraints,
            "power_delta": 0,
            "toughness_delta": 0,
            "granted_keywords_until_eot": [oracle_keyword["keyword"]],
            "duration": "until_end_of_turn",
            "xmage_effect_class": "GainAbilityTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_keyword_ability_class": keyword_ability_class,
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": False,
        }
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": TARGET_KEYWORD_ACTIVATED_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": TARGET_KEYWORD_ACTIVATED_SCOPE,
            "target": oracle_keyword["target"],
            "target_controller": oracle_keyword["target_controller"],
            "target_constraints": target_constraints,
            "power_delta": 0,
            "toughness_delta": 0,
            "granted_keywords_until_eot": [oracle_keyword["keyword"]],
            "duration": "until_end_of_turn",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "GainAbilityTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_keyword_ability_class": keyword_ability_class,
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": False,
        }
        if self_keyword_list:
            effect_json["keywords"] = self_keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in self_keyword_list:
                effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_target_keyword_until_eot",
        ), "selected_exact_scope"

    if permanent_activated_recursion_to_hand_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_recursion_not_permanent"
        oracle_target = activated_recursion_to_hand_activation_from_oracle(metadata)
        if isinstance(oracle_target, str):
            return None, oracle_target
        parsed_activation = activated_recursion_to_hand_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        oracle_target_type = str(oracle_target["target"])
        oracle_count = int(oracle_target["count"])
        oracle_up_to = bool(oracle_target["up_to"])
        if str(parsed_activation["target"]) != str(oracle_target_type):
            return None, "activated_recursion_source_oracle_target_mismatch"
        if int(parsed_activation["count"]) != int(oracle_count):
            return None, "activated_recursion_source_oracle_count_mismatch"
        if bool(parsed_activation["up_to"]) != bool(oracle_up_to):
            return None, "activated_recursion_source_oracle_count_mismatch"
        for key in (
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_requires_tap",
            "activation_requires_sacrifice",
            "activation_discard_count",
            "activation_discard_target",
            "activation_life_cost",
            "activation_sacrifice_target",
            "activation_requires_sacrifice_target",
        ):
            if parsed_activation.get(key) != oracle_target.get(key):
                return None, f"activated_recursion_source_oracle_{key}_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        activated_effect = {
            "effect": "recursion",
            "battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "recursion",
            "target": oracle_target_type,
            "target_constraints": recursion_target_constraints_for(oracle_target_type),
            "count": oracle_count,
            "destination": "hand",
            "target_controller": "self",
            "graveyard_to_hand_target": oracle_target_type,
            "graveyard_to_hand_target_count": oracle_count,
            "graveyard_to_hand_destination": "hand",
            "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                    "activation_discard_count",
                    "activation_discard_target",
                    "activation_life_cost",
                    "activation_sacrifice_target",
                    "activation_requires_sacrifice_target",
                )
                if key in parsed_activation
            },
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "recursion",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_HAND_SCOPE,
            "target": oracle_target_type,
            "target_constraints": recursion_target_constraints_for(oracle_target_type),
            "graveyard_to_hand_target": oracle_target_type,
            "graveyard_to_hand_target_count": oracle_count,
            "graveyard_to_hand_destination": "hand",
            "target_controller": "self",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                    "activation_discard_count",
                    "activation_discard_target",
                    "activation_life_cost",
                    "activation_sacrifice_target",
                    "activation_requires_sacrifice_target",
                )
                if key in parsed_activation
            },
            "graveyard_to_hand_activation_cost_mana": parsed_activation["activation_cost_mana"],
            "graveyard_to_hand_activation_cost_generic": parsed_activation["activation_cost_generic"],
            "graveyard_to_hand_activation_cost_colors": parsed_activation["activation_cost_colors"],
            "graveyard_to_hand_activation_requires_tap": parsed_activation["activation_requires_tap"],
            "graveyard_to_hand_activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
            "graveyard_to_hand_activation_discard_count": parsed_activation["activation_discard_count"],
            "graveyard_to_hand_activation_discard_target": parsed_activation["activation_discard_target"],
        }
        if parsed_activation.get("activation_life_cost"):
            activated_effect["activation_life_cost"] = parsed_activation["activation_life_cost"]
            effect_json["activation_life_cost"] = parsed_activation["activation_life_cost"]
            effect_json["graveyard_to_hand_activation_life_cost"] = parsed_activation["activation_life_cost"]
        if parsed_activation.get("activation_sacrifice_target"):
            activated_effect["activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            activated_effect["activation_requires_sacrifice_target"] = True
            effect_json["activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            effect_json["activation_requires_sacrifice_target"] = True
            effect_json["graveyard_to_hand_activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            effect_json["graveyard_to_hand_activation_requires_sacrifice_target"] = True
        if oracle_up_to:
            activated_effect["up_to_count"] = True
            activated_effect["graveyard_to_hand_up_to_count"] = True
            effect_json["up_to_count"] = True
            effect_json["graveyard_to_hand_up_to_count"] = True
        if parsed_activation.get("activation_discard_count"):
            activated_effect["activation_additional_cost"] = "discard_cards"
            effect_json["activation_additional_cost"] = "discard_cards"
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_recursion"] = True
            activated_effect["activated_self_sacrifice_recursion"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_graveyard_to_hand",
        ), "selected_exact_scope"

    if permanent_activated_recursion_to_battlefield_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_recursion_battlefield_not_permanent"
        oracle_target = activated_recursion_to_battlefield_from_oracle(metadata)
        if isinstance(oracle_target, str):
            return None, oracle_target
        parsed_activation = activated_recursion_to_battlefield_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in (
            "target",
            "count",
            "target_graveyard_controller",
            "battlefield_controller",
            "enters_tapped",
            "mana_value_max",
            "graveyard_from_battlefield_this_turn",
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_requires_tap",
            "activation_requires_sacrifice",
            "activation_life_cost",
            "activation_sacrifice_target",
            "activation_requires_sacrifice_target",
            "activation_timing",
        ):
            if parsed_activation.get(key) != oracle_target.get(key):
                return None, f"activated_recursion_battlefield_source_oracle_{key}_mismatch"
        if not source_supports_battlefield_recursion_target(
            source_text,
            str(oracle_target.get("target_graveyard_controller") or "self"),
        ):
            return None, "activated_recursion_battlefield_source_target_not_supported"
        if not source_supports_battlefield_recursion_target_type(
            source_text,
            str(oracle_target["target"]),
        ):
            return None, "activated_recursion_battlefield_source_target_not_supported"
        if not source_supports_battlefield_recursion_mana_value(
            source_text,
            oracle_target.get("mana_value_max"),
        ):
            return None, "activated_recursion_battlefield_source_mana_value_not_supported"
        if not source_supports_battlefield_recursion_this_turn(
            source_text,
            bool(oracle_target.get("graveyard_from_battlefield_this_turn")),
        ):
            return None, "activated_recursion_battlefield_source_this_turn_not_supported"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        target_type = str(oracle_target["target"])
        target_graveyard_controller = str(oracle_target.get("target_graveyard_controller") or "self")
        battlefield_controller = str(oracle_target.get("battlefield_controller") or "self")
        mana_value_max = oracle_target.get("mana_value_max")
        graveyard_from_battlefield_this_turn = bool(oracle_target.get("graveyard_from_battlefield_this_turn"))
        target_constraints = recursion_target_constraints_for(
            target_type,
            controller=target_graveyard_controller,
            mana_value_max=mana_value_max,
            graveyard_from_battlefield_this_turn=graveyard_from_battlefield_this_turn,
        )
        activated_effect = {
            "effect": "recursion",
            "battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "recursion",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints,
            "count": int(oracle_target["count"]),
            "destination": "battlefield",
            "target_controller": target_graveyard_controller,
            "target_graveyard_controller": target_graveyard_controller,
            "battlefield_controller": battlefield_controller,
            "graveyard_to_hand_target": target_type,
            "graveyard_to_hand_target_count": int(oracle_target["count"]),
            "graveyard_to_hand_destination": "battlefield",
            "xmage_effect_class": "ReturnFromGraveyardToBattlefieldTargetEffect",
            "xmage_ability_class": (
                "ActivateAsSorceryActivatedAbility"
                if parsed_activation.get("activation_timing") == "sorcery"
                else "SimpleActivatedAbility"
            ),
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        if parsed_activation.get("activation_life_cost"):
            activated_effect["activation_life_cost"] = parsed_activation["activation_life_cost"]
        if parsed_activation.get("activation_sacrifice_target"):
            activated_effect["activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            activated_effect["activation_requires_sacrifice_target"] = True
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "recursion",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_RECURSION_TO_BATTLEFIELD_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints,
            "count": int(oracle_target["count"]),
            "destination": "battlefield",
            "target_controller": target_graveyard_controller,
            "target_graveyard_controller": target_graveyard_controller,
            "battlefield_controller": battlefield_controller,
            "graveyard_to_hand_target": target_type,
            "graveyard_to_hand_target_count": int(oracle_target["count"]),
            "graveyard_to_hand_destination": "battlefield",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "ReturnFromGraveyardToBattlefieldTargetEffect",
            "xmage_ability_class": (
                "ActivateAsSorceryActivatedAbility"
                if parsed_activation.get("activation_timing") == "sorcery"
                else "SimpleActivatedAbility"
            ),
            "activation_cost_mana": parsed_activation["activation_cost_mana"],
            "activation_cost_generic": parsed_activation["activation_cost_generic"],
            "activation_cost_colors": parsed_activation["activation_cost_colors"],
            "activation_requires_tap": parsed_activation["activation_requires_tap"],
            "activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
            "graveyard_to_hand_activation_cost_mana": parsed_activation["activation_cost_mana"],
            "graveyard_to_hand_activation_cost_generic": parsed_activation["activation_cost_generic"],
            "graveyard_to_hand_activation_cost_colors": parsed_activation["activation_cost_colors"],
            "graveyard_to_hand_activation_requires_tap": parsed_activation["activation_requires_tap"],
            "graveyard_to_hand_activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
            "activated_self_sacrifice_recursion": bool(parsed_activation["activation_requires_sacrifice"]),
        }
        if parsed_activation.get("activation_life_cost"):
            effect_json["activation_life_cost"] = parsed_activation["activation_life_cost"]
            effect_json["graveyard_to_hand_activation_life_cost"] = parsed_activation["activation_life_cost"]
        if parsed_activation.get("activation_timing"):
            effect_json["activation_timing"] = parsed_activation["activation_timing"]
            activated_effect["activation_timing"] = parsed_activation["activation_timing"]
        if parsed_activation.get("activation_sacrifice_target"):
            effect_json["activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            effect_json["activation_requires_sacrifice_target"] = True
            effect_json["graveyard_to_hand_activation_sacrifice_target"] = parsed_activation["activation_sacrifice_target"]
            effect_json["graveyard_to_hand_activation_requires_sacrifice_target"] = True
        if bool(oracle_target.get("enters_tapped")):
            effect_json["enters_tapped"] = True
            activated_effect["enters_tapped"] = True
        if mana_value_max is not None:
            effect_json["recursion_mana_value_max"] = mana_value_max
            effect_json["graveyard_to_hand_mana_value_max"] = mana_value_max
            activated_effect["recursion_mana_value_max"] = mana_value_max
            activated_effect["graveyard_to_hand_mana_value_max"] = mana_value_max
        if graveyard_from_battlefield_this_turn:
            effect_json["graveyard_from_battlefield_this_turn"] = True
            activated_effect["graveyard_from_battlefield_this_turn"] = True
        if bool(parsed_activation["activation_requires_sacrifice"]):
            activated_effect["activated_self_sacrifice_recursion"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_graveyard_to_battlefield",
        ), "selected_exact_scope"

    if permanent_activated_graveyard_to_library_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_graveyard_to_library_not_permanent"
        oracle_target = activated_graveyard_to_library_from_oracle(metadata)
        if isinstance(oracle_target, str):
            return None, oracle_target
        parsed_activation = activated_graveyard_to_library_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in ("target", "count", "destination", "up_to_count", "target_graveyard_controller", "library_controller"):
            if parsed_activation.get(key) != oracle_target.get(key):
                return None, f"activated_graveyard_to_library_source_oracle_{key}_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        target_type = str(oracle_target["target"])
        target_count = int(oracle_target["count"])
        destination = str(oracle_target["destination"])
        target_graveyard_controller = str(oracle_target.get("target_graveyard_controller") or "self")
        library_controller = str(oracle_target.get("library_controller") or "self")
        target_constraints = recursion_target_constraints_for(
            target_type,
            controller=target_graveyard_controller,
        )
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        activated_effect = {
            "effect": "recursion",
            "battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "graveyard_to_library",
            "target": target_type,
            "target_constraints": target_constraints,
            "count": target_count,
            "destination": destination,
            "target_controller": target_graveyard_controller,
            "target_graveyard_controller": target_graveyard_controller,
            "library_controller": library_controller,
            "graveyard_to_library_target": target_type,
            "graveyard_to_library_target_count": target_count,
            "graveyard_to_library_destination": destination,
            "xmage_effect_class": "PutOnLibraryTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_TO_LIBRARY_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints,
            "graveyard_to_library_target": target_type,
            "graveyard_to_library_target_count": target_count,
            "graveyard_to_library_destination": destination,
            "target_controller": target_graveyard_controller,
            "target_graveyard_controller": target_graveyard_controller,
            "library_controller": library_controller,
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "PutOnLibraryTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
            "graveyard_to_library_activation_cost_mana": parsed_activation["activation_cost_mana"],
            "graveyard_to_library_activation_cost_generic": parsed_activation["activation_cost_generic"],
            "graveyard_to_library_activation_cost_colors": parsed_activation["activation_cost_colors"],
            "graveyard_to_library_activation_requires_tap": parsed_activation["activation_requires_tap"],
            "graveyard_to_library_activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        if oracle_target.get("up_to_count"):
            activated_effect["up_to_count"] = True
            activated_effect["graveyard_to_library_up_to_count"] = True
            effect_json["up_to_count"] = True
            effect_json["graveyard_to_library_up_to_count"] = True
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_graveyard_to_library"] = True
            activated_effect["activated_self_sacrifice_graveyard_to_library"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_graveyard_to_library",
        ), "selected_exact_scope"

    if permanent_activated_graveyard_exile_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_graveyard_exile_not_permanent"
        oracle_exile = activated_graveyard_exile_from_oracle(metadata)
        if isinstance(oracle_exile, str):
            return None, oracle_exile
        parsed_activation = activated_graveyard_exile_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        for key in ("target", "count", "up_to", "single_graveyard"):
            if parsed_activation.get(key) != oracle_exile.get(key):
                return None, "activated_graveyard_exile_source_oracle_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        target_type = str(oracle_exile["target"])
        target_count = int(oracle_exile["count"])
        target_constraints = graveyard_exile_target_constraints_for(target_type)
        activated_effect = {
            "effect": "graveyard_exile",
            "battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "graveyard_exile",
            "target": target_type,
            "target_constraints": target_constraints,
            "count": target_count,
            "destination": "exile",
            "target_controller": "any",
            "graveyard_exile_target": target_type,
            "graveyard_exile_target_count": target_count,
            "graveyard_exile_destination": "exile",
            "xmage_effect_class": "ExileTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "graveyard_exile",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE,
            "target": target_type,
            "target_constraints": target_constraints,
            "graveyard_exile_target": target_type,
            "graveyard_exile_target_count": target_count,
            "graveyard_exile_destination": "exile",
            "target_controller": "any",
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "ExileTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
            "graveyard_exile_activation_cost_mana": parsed_activation["activation_cost_mana"],
            "graveyard_exile_activation_cost_generic": parsed_activation["activation_cost_generic"],
            "graveyard_exile_activation_cost_colors": parsed_activation["activation_cost_colors"],
            "graveyard_exile_activation_requires_tap": parsed_activation["activation_requires_tap"],
            "graveyard_exile_activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        if oracle_exile.get("up_to"):
            activated_effect["up_to_count"] = True
            activated_effect["graveyard_exile_up_to_count"] = True
            effect_json["up_to_count"] = True
            effect_json["graveyard_exile_up_to_count"] = True
        if oracle_exile.get("single_graveyard"):
            activated_effect["single_graveyard"] = True
            activated_effect["graveyard_exile_single_graveyard"] = True
            effect_json["single_graveyard"] = True
            effect_json["graveyard_exile_single_graveyard"] = True
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_graveyard_exile"] = True
            activated_effect["activated_self_sacrifice_graveyard_exile"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_graveyard_exile",
        ), "selected_exact_scope"

    if unit == RECURSION_UNIT and classes == {"ReturnSourceFromGraveyardToBattlefieldEffect"}:
        abilities = ability_classes(row)
        allowed_abilities = {"SimpleActivatedAbility", "CantBlockAbility"} | set(
            STATIC_SELF_KEYWORD_ABILITY_CLASSES
        )
        if "SimpleActivatedAbility" not in abilities or abilities - allowed_abilities:
            return None, "graveyard_self_return_battlefield_ability_class_not_simple"
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "graveyard_self_return_battlefield_not_permanent"
        oracle_activation = graveyard_self_return_to_battlefield_from_oracle(metadata)
        if isinstance(oracle_activation, str):
            return None, oracle_activation
        source_activation = graveyard_self_return_to_battlefield_from_source(source_text)
        if isinstance(source_activation, str):
            return None, source_activation
        for key in (
            "activation_cost_mana",
            "activation_cost_generic",
            "activation_cost_colors",
            "enters_tapped",
            "activation_discard_count",
            "activation_discard_target",
            "activation_exile_from_graveyard_count",
            "activation_exile_from_graveyard_target",
            "activation_exile_from_graveyard_other",
        ):
            if source_activation[key] != oracle_activation[key]:
                return None, "graveyard_self_return_battlefield_source_oracle_mismatch"
        if ("CantBlockAbility" in abilities) != bool(oracle_activation["static_cant_block"]):
            return None, "graveyard_self_return_battlefield_source_oracle_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        keywords = keywords_from_ability_classes(row)
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE,
            "ability_kind": "graveyard_activated",
            "activated_effect": "recursion",
            "activated_battle_model_scope": GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE,
            "target": "self",
            "target_controller": "self",
            "source_zone": "graveyard",
            "destination": "battlefield",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": oracle_activation["activation_cost_mana"],
            "graveyard_self_return_activation_cost_generic": oracle_activation["activation_cost_generic"],
            "graveyard_self_return_activation_cost_colors": oracle_activation["activation_cost_colors"],
            "activation_cost_mana": oracle_activation["activation_cost_mana"],
            "activation_cost_generic": oracle_activation["activation_cost_generic"],
            "activation_cost_colors": oracle_activation["activation_cost_colors"],
            "enters_tapped": oracle_activation["enters_tapped"],
            "xmage_effect_class": "ReturnSourceFromGraveyardToBattlefieldEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
        }
        if oracle_activation["activation_discard_count"]:
            effect_json["graveyard_self_return_activation_discard_count"] = oracle_activation[
                "activation_discard_count"
            ]
            effect_json["activation_discard_count"] = oracle_activation["activation_discard_count"]
            effect_json["activation_discard_target"] = oracle_activation["activation_discard_target"]
            effect_json["activation_additional_cost"] = "discard_cards"
        if oracle_activation["activation_exile_from_graveyard_count"]:
            effect_json["graveyard_self_return_activation_exile_from_graveyard_count"] = oracle_activation[
                "activation_exile_from_graveyard_count"
            ]
            effect_json["graveyard_self_return_activation_exile_from_graveyard_target"] = oracle_activation[
                "activation_exile_from_graveyard_target"
            ]
            effect_json["graveyard_self_return_activation_exile_from_graveyard_other"] = oracle_activation[
                "activation_exile_from_graveyard_other"
            ]
            effect_json["activation_exile_from_graveyard_count"] = oracle_activation[
                "activation_exile_from_graveyard_count"
            ]
            effect_json["activation_exile_from_graveyard_target"] = oracle_activation[
                "activation_exile_from_graveyard_target"
            ]
            effect_json["activation_exile_from_graveyard_other"] = oracle_activation[
                "activation_exile_from_graveyard_other"
            ]
            effect_json["activation_additional_cost"] = "exile_from_graveyard"
        if oracle_activation["static_cant_block"]:
            effect_json["cant_block"] = True
            effect_json["static_cant_block"] = True
        if keywords:
            effect_json["keywords"] = ordered_keywords(keywords)
            effect_json["_keywords_are_self"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_graveyard_simple_activated_self_return_to_battlefield",
        ), "selected_exact_scope"

    if unit == RECURSION_UNIT and classes == {"ReturnSourceFromGraveyardToHandEffect"}:
        abilities = ability_classes(row)
        allowed_abilities = (
            {"SimpleActivatedAbility", "ActivateAsSorceryActivatedAbility", "EntersBattlefieldTappedAbility"}
            | set(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        )
        if not ({"SimpleActivatedAbility", "ActivateAsSorceryActivatedAbility"} & abilities) or abilities - allowed_abilities:
            return None, "graveyard_self_return_ability_class_not_simple"
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "graveyard_self_return_not_permanent"
        oracle_activation = graveyard_self_return_to_hand_from_oracle(metadata)
        if isinstance(oracle_activation, str):
            return None, oracle_activation
        source_activation = graveyard_self_return_to_hand_from_source(source_text)
        if isinstance(source_activation, str):
            return None, source_activation
        for key in (
            "activation_cost_mana",
            "activation_cost_generic",
            "activation_cost_colors",
            "activation_timing",
            "activation_discard_count",
            "activation_discard_target",
        ):
            if source_activation[key] != oracle_activation[key]:
                return None, "graveyard_self_return_source_oracle_cost_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        keywords = keywords_from_ability_classes(row)
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE,
            "ability_kind": "graveyard_activated",
            "activated_effect": "recursion",
            "activated_battle_model_scope": GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE,
            "target": "self",
            "target_controller": "self",
            "source_zone": "graveyard",
            "destination": "hand",
            "graveyard_self_return_to_hand": True,
            "graveyard_self_return_destination": "hand",
            "graveyard_self_return_activation_cost_mana": oracle_activation["activation_cost_mana"],
            "graveyard_self_return_activation_cost_generic": oracle_activation["activation_cost_generic"],
            "graveyard_self_return_activation_cost_colors": oracle_activation["activation_cost_colors"],
            "activation_cost_mana": oracle_activation["activation_cost_mana"],
            "activation_cost_generic": oracle_activation["activation_cost_generic"],
            "activation_cost_colors": oracle_activation["activation_cost_colors"],
            "xmage_effect_class": "ReturnSourceFromGraveyardToHandEffect",
            "xmage_ability_class": (
                "ActivateAsSorceryActivatedAbility"
                if oracle_activation["activation_timing"] == "sorcery"
                else "SimpleActivatedAbility"
            ),
        }
        if oracle_activation["activation_timing"]:
            effect_json["activation_timing"] = oracle_activation["activation_timing"]
        if oracle_activation["activation_discard_count"]:
            effect_json["graveyard_self_return_activation_discard_count"] = oracle_activation[
                "activation_discard_count"
            ]
            effect_json["graveyard_self_return_activation_discard_target"] = oracle_activation[
                "activation_discard_target"
            ]
            effect_json["activation_discard_count"] = oracle_activation["activation_discard_count"]
            effect_json["activation_discard_target"] = oracle_activation["activation_discard_target"]
            effect_json["activation_additional_cost"] = "discard_cards"
        if keywords:
            effect_json["keywords"] = ordered_keywords(keywords)
            effect_json["_keywords_are_self"] = True
        if oracle_activation.get("enters_tapped") or "EntersBattlefieldTappedAbility" in abilities:
            effect_json["enters_tapped"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_graveyard_simple_activated_self_return_to_hand",
        ), "selected_exact_scope"

    if fixed_token_spell_unit:
        parsed_effect = fixed_create_token_effect_from_source(source_text)
        if isinstance(parsed_effect, str):
            return None, parsed_effect
        token_class, token_count = parsed_effect
        token_data, token_reason = parse_simple_token_class(
            token_class_source(row, source_text, token_class),
            token_class,
        )
        if token_reason:
            return None, token_reason
        effect_json = {
            "effect": "token_maker",
            "battle_model_scope": TOKEN_SPELL_SCOPE,
            "ability_kind": "one_shot",
            "token_count": token_count,
            "xmage_effect_class": "CreateTokenEffect",
            **token_data,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_fixed_create_creature_tokens_spell",
        ), "selected_exact_scope"

    if etb_token_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_token_not_creature"
        parsed_effect = fixed_create_token_effect_from_source(source_text)
        if isinstance(parsed_effect, str):
            return None, parsed_effect
        token_class, token_count = parsed_effect
        token_data, token_reason = parse_simple_token_class(
            token_class_source(row, source_text, token_class),
            token_class,
        )
        if token_reason:
            return None, token_reason
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_TOKEN_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_token_count": token_count,
            "xmage_effect_class": "CreateTokenEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
            "xmage_token_class": token_data["xmage_token_class"],
            "token_description": token_data["token_description"],
            "etb_token_name": token_data["token_name"],
            "etb_token_power": token_data["token_power"],
            "etb_token_toughness": token_data["token_toughness"],
        }
        optional_token_fields = {
            "token_subtype": "etb_token_subtype",
            "token_colors": "etb_token_colors",
            "token_keywords": "etb_token_keywords",
            "token_flying": "etb_token_flying",
            "token_haste": "etb_token_haste",
            "artifact_tokens": "etb_artifact_tokens",
        }
        for source_key, target_key in optional_token_fields.items():
            if source_key in token_data:
                effect_json[target_key] = token_data[source_key]
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_create_tokens",
        ), "selected_exact_scope"

    if etb_add_counters_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_add_counters_not_creature"
        source_counter = fixed_counter_target_from_source(source_text)
        if source_counter is None:
            return None, "etb_add_counters_counter_not_fixed"
        oracle_counter = etb_counter_target_from_oracle(metadata)
        if oracle_counter is None:
            return None, "etb_add_counters_target_not_supported"
        if source_counter != oracle_counter:
            return None, "etb_add_counters_source_oracle_mismatch"
        counter_type, count = oracle_counter
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_ADD_COUNTERS_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_add_counters_target": "creature",
            "etb_add_counters_counter_type": counter_type,
            "etb_add_counters_count": count,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": counter_type,
            "counter_count": count,
            "xmage_effect_class": "AddCountersTargetEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
            **flags,
        }
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_add_counters_target_creature",
        ), "selected_exact_scope"

    if static_controlled_pt_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "static_controlled_pt_not_permanent"
        oracle_static = static_controlled_pt_from_oracle(metadata)
        if isinstance(oracle_static, str):
            return None, oracle_static
        if oracle_static is None:
            return None, "static_controlled_pt_oracle_not_exact"
        source_static = static_controlled_pt_from_source(source_text)
        if isinstance(source_static, str):
            return None, source_static
        if source_static is None:
            return None, "static_controlled_pt_source_not_exact"
        if source_static != oracle_static:
            return None, "static_controlled_pt_source_oracle_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_type = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        permanent_effect = "creature" if permanent_type == "creature" else "passive"
        target_constraints: dict[str, Any] = {
            "controller": "self",
            "card_types": ["creature"],
        }
        if source_static.get("static_required_subtypes"):
            target_constraints["subtypes"] = source_static["static_required_subtypes"]
        if source_static.get("static_required_supertypes"):
            target_constraints["supertypes"] = source_static["static_required_supertypes"]
        if source_static.get("static_artifact_creature"):
            target_constraints["card_types"] = ["artifact", "creature"]
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": STATIC_CONTROLLED_PT_SCOPE,
            "ability_kind": "static",
            "static_effect": "controlled_power_toughness_boost",
            "static_applies_to": "creatures_you_control",
            "target": "controlled_creatures",
            "target_controller": "self",
            "target_constraints": target_constraints,
            "xmage_effect_class": "BoostControlledEffect",
            "xmage_ability_class": "SimpleStaticAbility",
            **source_static,
        }
        effect_json["permanent_type"] = permanent_type
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_static_controlled_power_toughness_boost",
        ), "selected_exact_scope"

    if static_graveyard_count_pt_unit:
        if not is_creature_metadata(metadata):
            return None, "static_graveyard_count_pt_not_creature"
        oracle_static = static_graveyard_count_pt_from_oracle(metadata)
        if oracle_static is None:
            return None, "static_graveyard_count_pt_oracle_not_exact"
        source_static = static_graveyard_count_pt_from_source(source_text)
        if isinstance(source_static, str):
            return None, source_static
        if source_static is None:
            return None, "static_graveyard_count_pt_source_not_exact"
        if source_static != oracle_static:
            return None, "static_graveyard_count_pt_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": STATIC_GRAVEYARD_COUNT_PT_SCOPE,
            "ability_kind": "static",
            "static_effect": "source_power_toughness_equal_graveyard_count",
            "static_power_toughness_source": "graveyard_count",
            "target": "self",
            "target_controller": "self",
            "dynamic_power_equals_graveyard_count": True,
            "dynamic_toughness_equals_graveyard_count": True,
            "xmage_effect_class": "SetBasePowerToughnessSourceEffect",
            "xmage_ability_class": "SimpleStaticAbility",
            **source_static,
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
            family_id="xmage_static_source_power_toughness_equal_graveyard_count",
        ), "selected_exact_scope"

    if static_graveyard_threshold_boost_unit:
        if not is_creature_metadata(metadata):
            return None, "static_graveyard_threshold_boost_not_creature"
        oracle_static = static_graveyard_threshold_boost_from_oracle(metadata)
        if oracle_static is None:
            return None, "static_graveyard_threshold_boost_oracle_not_exact"
        source_static = static_graveyard_threshold_boost_from_source(source_text)
        if isinstance(source_static, str):
            return None, source_static
        if source_static is None:
            return None, "static_graveyard_threshold_boost_source_not_exact"
        if source_static != oracle_static:
            return None, "static_graveyard_threshold_boost_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": STATIC_GRAVEYARD_THRESHOLD_BOOST_SCOPE,
            "ability_kind": "static",
            "static_effect": "source_power_toughness_boost_if_graveyard_count",
            "target": "self",
            "target_controller": "self",
            "xmage_effect_class": "BoostSourceEffect",
            "xmage_ability_class": "SimpleStaticAbility",
            **source_static,
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
            family_id="xmage_static_source_boost_if_graveyard_threshold",
        ), "selected_exact_scope"

    if static_graveyard_count_boost_unit:
        if not is_creature_metadata(metadata):
            return None, "static_graveyard_count_boost_not_creature"
        oracle_static = static_graveyard_count_boost_from_oracle(metadata)
        if oracle_static is None:
            return None, "static_graveyard_count_boost_oracle_not_exact"
        source_static = static_graveyard_count_boost_from_source(source_text)
        if isinstance(source_static, str):
            return None, source_static
        if source_static is None:
            return None, "static_graveyard_count_boost_source_not_exact"
        if source_static != oracle_static:
            return None, "static_graveyard_count_boost_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": STATIC_GRAVEYARD_COUNT_BOOST_SCOPE,
            "ability_kind": "static",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "target": "self",
            "target_controller": "self",
            "xmage_effect_class": "BoostSourceEffect",
            "xmage_ability_class": "SimpleStaticAbility",
            **source_static,
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
            family_id="xmage_static_source_boost_equal_graveyard_count",
        ), "selected_exact_scope"

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

    if etb_draw_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_draw_not_creature"
        count = etb_draw_count_from_oracle(metadata)
        constructor_count = java_constructor_int_or_noarg_default(
            source_text,
            "DrawCardSourceControllerEffect",
            noarg_default=1,
        )
        if count is None or count <= 0:
            return None, "etb_draw_count_not_fixed"
        if constructor_count is None:
            return None, "etb_draw_count_source_not_fixed"
        if constructor_count != count:
            return None, "etb_draw_count_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_DRAW_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_draw_count": count,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
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
            family_id="xmage_creature_etb_draw_cards",
        ), "selected_exact_scope"

    if dies_draw_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "dies_draw_not_creature"
        parsed = dies_draw_from_oracle(metadata)
        constructor_count = java_constructor_int_or_noarg_default(
            source_text,
            "DrawCardSourceControllerEffect",
            noarg_default=1,
        )
        if parsed is None:
            return None, "dies_draw_count_not_fixed"
        count, optional = parsed
        if constructor_count is None:
            return None, "dies_draw_count_source_not_fixed"
        if constructor_count != count:
            return None, "dies_draw_count_source_oracle_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": DIES_DRAW_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "dies",
            "draw_cards_when_this_dies": count,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "DiesSourceTriggeredAbility",
        }
        if optional:
            effect_json["dies_draw_optional"] = True
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_dies_draw_cards",
        ), "selected_exact_scope"

    if dies_recursion_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "dies_recursion_not_creature"
        if "DoIfCostPaid" in source_text or "GenericManaCost" in source_text:
            return None, "dies_recursion_optional_cost_not_supported"
        target = dies_recursion_to_hand_from_oracle(metadata)
        if target is None:
            return None, "dies_recursion_target_not_supported"
        target_type = str(target["target"])
        count = int(target["count"])
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": DIES_RECURSION_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "dies",
            "dies_recursion_target": target_type,
            "dies_recursion_count": count,
            "dies_recursion_destination": "hand",
            "target_constraints": recursion_target_constraints_for(target_type),
            "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
            "xmage_ability_class": "DiesSourceTriggeredAbility",
        }
        if target.get("exclude_self"):
            effect_json["dies_recursion_exclude_self"] = True
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_dies_graveyard_to_hand",
        ), "selected_exact_scope"

    if etb_damage_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_damage_not_creature"
        parsed = etb_damage_target_from_oracle(metadata)
        if parsed is None:
            return None, "etb_damage_target_not_supported"
        amount, target = parsed
        constructor_amount = java_constructor_int(source_text, "DamageTargetEffect")
        if constructor_amount is None or constructor_amount <= 0:
            return None, "etb_damage_amount_source_not_fixed"
        if constructor_amount != amount:
            return None, "etb_damage_source_oracle_mismatch"
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_DAMAGE_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_damage_amount": amount,
            "etb_damage_target": target,
            "target": target,
            "target_constraints": target_constraints_for(target),
            "xmage_effect_class": "DamageTargetEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_fixed_damage_target",
        ), "selected_exact_scope"

    if etb_destroy_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_destroy_not_creature"
        target = etb_destroy_target_from_oracle(metadata)
        if target is None:
            return None, "etb_destroy_target_not_supported"
        effect, target_type = target
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_DESTROY_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_remove_effect": effect,
            "etb_remove_target": target_type,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "xmage_effect_class": "DestroyTargetEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_destroy_target",
        ), "selected_exact_scope"

    if etb_recursion_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_recursion_not_creature"
        target = etb_recursion_to_hand_from_oracle(metadata)
        if target is None:
            return None, "etb_recursion_target_not_supported"
        target_type = str(target["target"])
        count = int(target["count"])
        mana_value_max = target.get("mana_value_max")
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_RECURSION_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": target_type,
            "etb_recursion_count": count,
            "etb_recursion_destination": "hand",
            "target_constraints": recursion_target_constraints_for(
                target_type,
                mana_value_max=mana_value_max,
            ),
            "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        if mana_value_max is not None:
            effect_json["etb_recursion_mana_value_max"] = mana_value_max
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        if target.get("up_to_count"):
            effect_json["etb_recursion_up_to_count"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_graveyard_to_hand",
        ), "selected_exact_scope"

    if etb_mill_recursion_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_mill_recursion_not_creature"
        oracle_target = mill_then_return_from_oracle(metadata)
        if oracle_target is None:
            return None, "etb_mill_recursion_oracle_not_supported"
        source_target = mill_then_return_from_source(source_text)
        if isinstance(source_target, str):
            return None, source_target
        for key in ("mill_count", "target", "count", "up_to_count"):
            if source_target.get(key) != oracle_target.get(key):
                return None, f"etb_mill_recursion_source_oracle_{key}_mismatch"
        target_type = str(oracle_target["target"])
        mill_count = int(oracle_target["mill_count"])
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_MILL_RECURSION_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_mill_count": mill_count,
            "etb_recursion_target": target_type,
            "etb_recursion_count": int(oracle_target["count"]),
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": True,
            "target_constraints": recursion_target_constraints_for(target_type),
            "xmage_effect_classes": ["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_mill_then_return_graveyard_to_hand",
        ), "selected_exact_scope"

    if etb_graveyard_to_library_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_graveyard_to_library_not_creature"
        oracle_target = etb_graveyard_to_library_from_oracle(metadata)
        if isinstance(oracle_target, str):
            return None, oracle_target
        source_target = etb_graveyard_to_library_from_source(source_text)
        if isinstance(source_target, str):
            return None, source_target
        for key in (
            "target",
            "count",
            "destination",
            "up_to_count",
            "target_graveyard_controller",
            "library_controller",
        ):
            if source_target.get(key) != oracle_target.get(key):
                return None, f"etb_graveyard_to_library_source_oracle_{key}_mismatch"
        target_type = str(oracle_target["target"])
        count = int(oracle_target["count"])
        destination = str(oracle_target["destination"])
        target_graveyard_controller = str(oracle_target.get("target_graveyard_controller") or "self")
        library_controller = str(oracle_target.get("library_controller") or "self")
        target_constraints = recursion_target_constraints_for(target_type)
        target_constraints["controller"] = target_graveyard_controller
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_GRAVEYARD_TO_LIBRARY_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": target_type,
            "etb_recursion_count": count,
            "etb_recursion_destination": destination,
            "target_constraints": target_constraints,
            "target_controller": target_graveyard_controller,
            "target_graveyard_controller": target_graveyard_controller,
            "library_controller": library_controller,
            "xmage_effect_class": "PutOnLibraryTargetEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        }
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        if keyword_list:
            effect_json["keywords"] = keyword_list
            effect_json["_keywords_are_self"] = True
            for keyword in keyword_list:
                effect_json[keyword] = True
        if oracle_target.get("up_to_count"):
            effect_json["etb_recursion_up_to_count"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_creature_etb_graveyard_to_library",
        ), "selected_exact_scope"

    if etb_library_pick_creature_unit:
        if not is_creature_metadata(metadata):
            return None, "etb_library_pick_not_creature"
        oracle_pick = etb_library_pick_from_oracle(metadata)
        if isinstance(oracle_pick, str):
            return None, oracle_pick
        source_pick = etb_library_pick_from_source(source_text)
        if isinstance(source_pick, str):
            return None, source_pick
        for key in ("look_count", "pick_count", "pick_target", "rest_destination"):
            if source_pick.get(key) != oracle_pick.get(key):
                return None, f"etb_library_pick_source_oracle_{key}_mismatch"
        keyword_list = ordered_keywords(keywords_from_ability_classes(row))
        effect_json = {
            "effect": "creature",
            "battle_model_scope": ETB_LIBRARY_PICK_CREATURE_SCOPE,
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_library_look_count": int(oracle_pick["look_count"]),
            "etb_library_pick_count": int(oracle_pick["pick_count"]),
            "etb_library_pick_target": str(oracle_pick["pick_target"]),
            "etb_library_rest_destination": str(oracle_pick["rest_destination"]),
            "target": str(oracle_pick["pick_target"]),
            "target_constraints": library_pick_target_constraints_for(str(oracle_pick["pick_target"])),
            "destination": "hand",
            "rest_destination": str(oracle_pick["rest_destination"]),
            "xmage_effect_class": "LookLibraryAndPickControllerEffect",
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
            family_id="xmage_creature_etb_look_library_pick_to_hand_rest_graveyard",
        ), "selected_exact_scope"

    if creature_tap_damage_unit and is_creature_metadata(metadata):
        oracle_damage = activated_tap_damage_from_oracle(metadata)
        source_amount = activated_tap_damage_amount_from_source(source_text)
        if oracle_damage is not None and source_amount is not None:
            amount, target = oracle_damage
            if source_amount != amount:
                return None, "activated_tap_damage_source_oracle_mismatch"
            activated_effect = {
                "effect": "direct_damage",
                "battle_model_scope": TAP_DAMAGE_ACTIVATED_SCOPE,
                "ability_kind": "activated",
                "activation_requires_tap": True,
                "activated_effect": "direct_damage",
                "amount": amount,
                "damage": amount,
                "target": target,
                "target_constraints": target_constraints_for(target),
                "xmage_effect_class": "DamageTargetEffect",
                "xmage_ability_class": "SimpleActivatedAbility",
                "xmage_activation_cost": "tap",
            }
            effect_json = {
                "effect": "creature",
                "battle_model_scope": CREATURE_TAP_DAMAGE_SCOPE,
                "ability_kind": "static_and_activated",
                "activated_effect": "direct_damage",
                "activated_battle_model_scope": TAP_DAMAGE_ACTIVATED_SCOPE,
                "activated_damage_amount": amount,
                "activation_requires_tap": True,
                "_activated_rule_effects": [activated_effect],
                "xmage_effect_class": "DamageTargetEffect",
                "xmage_ability_class": "SimpleActivatedAbility",
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_creature_tap_fixed_damage",
            ), "selected_exact_scope"

    if permanent_activated_damage_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_damage_not_permanent"
        oracle_damage = activated_damage_from_oracle(metadata)
        if oracle_damage is None:
            return None, "activated_damage_oracle_not_simple"
        parsed_activation = activated_damage_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        oracle_amount, oracle_target = oracle_damage
        if int(parsed_activation["amount"]) != int(oracle_amount):
            return None, "activated_damage_source_oracle_amount_mismatch"
        if str(parsed_activation["target"]) != str(oracle_target):
            return None, "activated_damage_source_oracle_target_mismatch"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_effect = (
            "creature"
            if "creature" in type_line
            else "artifact"
            if "artifact" in type_line
            else "enchantment"
            if "enchantment" in type_line
            else "permanent"
        )
        activated_effect = {
            "effect": "direct_damage",
            "battle_model_scope": PERMANENT_ACTIVATED_DAMAGE_SCOPE,
            "ability_kind": "activated",
            "activated_effect": "direct_damage",
            "target_constraints": target_constraints_for(oracle_target),
            "xmage_effect_class": "DamageTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **parsed_activation,
        }
        effect_json = {
            "effect": permanent_effect,
            "battle_model_scope": PERMANENT_ACTIVATED_DAMAGE_SCOPE,
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": PERMANENT_ACTIVATED_DAMAGE_SCOPE,
            "activated_damage_amount": oracle_amount,
            "target": oracle_target,
            "target_constraints": target_constraints_for(oracle_target),
            "_activated_rule_effects": [activated_effect],
            "xmage_effect_class": "DamageTargetEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
            **{
                key: parsed_activation[key]
                for key in (
                    "activation_cost_mana",
                    "activation_cost_generic",
                    "activation_cost_colors",
                    "activation_requires_tap",
                    "activation_requires_sacrifice",
                )
            },
        }
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_damage"] = True
            activated_effect["activated_self_sacrifice_damage"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_damage",
        ), "selected_exact_scope"

    if unit == DAMAGE_UNIT and classes == {"DamageTargetEffect", "ScryEffect"}:
        unsupported_abilities = ability_classes(row) - ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES
        if unsupported_abilities:
            return None, "damage_scry_ability_class_not_simple"
        oracle_damage_scry = fixed_damage_scry_from_oracle(metadata)
        if oracle_damage_scry is None:
            return None, "damage_scry_oracle_not_exact_fixed"
        source_damage_scry = fixed_damage_scry_from_source(source_text)
        if source_damage_scry is None:
            return None, "damage_scry_source_not_fixed"
        amount, scry_count, target = oracle_damage_scry
        if source_damage_scry != (amount, scry_count):
            return None, "damage_scry_source_oracle_mismatch"
        if not source_matches_target_constraint(source_text, target):
            return None, "damage_scry_target_source_mismatch"
        target_base = restricted_target_base(target)
        damage_component = {
            "effect": "direct_damage",
            "battle_model_scope": DAMAGE_SCOPE,
            "amount": amount,
            "damage": amount,
            "target": target_base,
            "target_constraints": target_constraints_for(target),
            "compose_on_resolution": True,
            "xmage_effect_class": "DamageTargetEffect",
        }
        scry_component = {
            "effect": "scry",
            "battle_model_scope": SCRY_SCOPE,
            "count": scry_count,
            "scry_count": scry_count,
            "compose_on_resolution": True,
            "xmage_effect_class": "ScryEffect",
        }
        effect_json = {
            "effect": "composite_resolution",
            "battle_model_scope": DAMAGE_SCRY_SCOPE,
            "amount": amount,
            "damage": amount,
            "target": target_base,
            "target_constraints": target_constraints_for(target),
            "scry_count": scry_count,
            "resolution_order": "damage_then_scry",
            "_composite_rule_components": [damage_component, scry_component],
            "xmage_effect_classes": ["DamageTargetEffect", "ScryEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_fixed_damage_scry_spell",
        ), "selected_exact_scope"

    if unit == DESTROY_UNIT and classes == {"DestroyTargetEffect", "ScryEffect"}:
        unsupported_abilities = ability_classes(row) - ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES
        if unsupported_abilities:
            return None, "destroy_scry_ability_class_not_simple"
        oracle_destroy_scry = fixed_destroy_scry_from_oracle(metadata)
        if oracle_destroy_scry is None:
            return None, "destroy_scry_oracle_not_exact_fixed"
        source_scry_count = fixed_destroy_scry_from_source(source_text)
        if source_scry_count is None:
            return None, "destroy_scry_source_not_fixed"
        effect, target_type, scry_count = oracle_destroy_scry
        if source_scry_count != scry_count:
            return None, "destroy_scry_source_oracle_mismatch"
        if not source_matches_target_constraint(source_text, target_type):
            return None, "destroy_scry_target_source_mismatch"
        target_base = restricted_target_base(target_type)
        destroy_component = {
            "effect": effect,
            "battle_model_scope": DESTROY_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "compose_on_resolution": True,
            "xmage_effect_class": "DestroyTargetEffect",
        }
        scry_component = {
            "effect": "scry",
            "battle_model_scope": SCRY_SCOPE,
            "count": scry_count,
            "scry_count": scry_count,
            "compose_on_resolution": True,
            "xmage_effect_class": "ScryEffect",
        }
        effect_json = {
            "effect": "composite_resolution",
            "battle_model_scope": DESTROY_SCRY_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "scry_count": scry_count,
            "resolution_order": "destroy_then_scry",
            "_composite_rule_components": [destroy_component, scry_component],
            "xmage_effect_classes": ["DestroyTargetEffect", "ScryEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_destroy_target_scry_spell",
        ), "selected_exact_scope"

    if unit == EXILE_UNIT and classes == {"ExileTargetEffect", "ScryEffect"}:
        unsupported_abilities = ability_classes(row) - ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES
        if unsupported_abilities:
            return None, "exile_scry_ability_class_not_simple"
        oracle_exile_scry = fixed_exile_scry_from_oracle(metadata)
        if oracle_exile_scry is None:
            return None, "exile_scry_oracle_not_exact_fixed"
        source_scry_count = fixed_exile_scry_from_source(source_text)
        if source_scry_count is None:
            return None, "exile_scry_source_not_fixed"
        effect, target_type, scry_count = oracle_exile_scry
        if source_scry_count != scry_count:
            return None, "exile_scry_source_oracle_mismatch"
        if not source_matches_target_constraint(source_text, target_type):
            return None, "exile_scry_target_source_mismatch"
        target_base = restricted_target_base(target_type)
        exile_component = {
            "effect": effect,
            "battle_model_scope": EXILE_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "exile",
            "compose_on_resolution": True,
            "xmage_effect_class": "ExileTargetEffect",
        }
        scry_component = {
            "effect": "scry",
            "battle_model_scope": SCRY_SCOPE,
            "count": scry_count,
            "scry_count": scry_count,
            "compose_on_resolution": True,
            "xmage_effect_class": "ScryEffect",
        }
        effect_json = {
            "effect": "composite_resolution",
            "battle_model_scope": EXILE_SCRY_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "exile",
            "scry_count": scry_count,
            "resolution_order": "exile_then_scry",
            "_composite_rule_components": [exile_component, scry_component],
            "xmage_effect_classes": ["ExileTargetEffect", "ScryEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_exile_target_scry_spell",
        ), "selected_exact_scope"

    if unit == BOUNCE_UNIT and classes == {"ReturnToHandTargetEffect", "ScryEffect"}:
        unsupported_abilities = ability_classes(row) - ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES
        if unsupported_abilities:
            return None, "bounce_scry_ability_class_not_simple"
        oracle_bounce_scry = fixed_bounce_scry_from_oracle(metadata)
        if oracle_bounce_scry is None:
            return None, "bounce_scry_oracle_not_exact_fixed"
        source_scry_count = fixed_bounce_scry_from_source(source_text)
        if source_scry_count is None:
            return None, "bounce_scry_source_not_fixed"
        effect, target_type, scry_count = oracle_bounce_scry
        if source_scry_count != scry_count:
            return None, "bounce_scry_source_oracle_mismatch"
        if not source_matches_bounce_target(source_text, target_type):
            return None, "bounce_scry_target_source_mismatch"
        target_base = restricted_target_base(target_type)
        bounce_component = {
            "effect": effect,
            "battle_model_scope": BOUNCE_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "hand",
            "compose_on_resolution": True,
            "xmage_effect_class": "ReturnToHandTargetEffect",
        }
        scry_component = {
            "effect": "scry",
            "battle_model_scope": SCRY_SCOPE,
            "count": scry_count,
            "scry_count": scry_count,
            "compose_on_resolution": True,
            "xmage_effect_class": "ScryEffect",
        }
        effect_json = {
            "effect": "composite_resolution",
            "battle_model_scope": BOUNCE_SCRY_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "hand",
            "scry_count": scry_count,
            "resolution_order": "bounce_then_scry",
            "_composite_rule_components": [bounce_component, scry_component],
            "xmage_effect_classes": ["ReturnToHandTargetEffect", "ScryEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_bounce_scry_spell",
        ), "selected_exact_scope"

    if unit == DRAW_UNIT:
        if classes == {"ScryEffect", "DrawCardSourceControllerEffect"}:
            unsupported_abilities = ability_classes(row) - ALLOWED_AUXILIARY_RESOLUTION_ABILITY_CLASSES
            if unsupported_abilities:
                return None, "scry_draw_ability_class_not_simple"
            oracle_scry_draw = fixed_scry_draw_from_oracle(metadata)
            if oracle_scry_draw is None:
                return None, "scry_draw_oracle_not_exact_fixed"
            source_scry_draw = fixed_scry_draw_from_source(source_text)
            if source_scry_draw is None:
                return None, "scry_draw_source_not_fixed"
            if source_scry_draw != oracle_scry_draw:
                return None, "scry_draw_source_oracle_mismatch"
            scry_count, draw_count, order = oracle_scry_draw
            scry_component = {
                "effect": "scry",
                "battle_model_scope": SCRY_SCOPE,
                "count": scry_count,
                "scry_count": scry_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "ScryEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            components = (
                [scry_component, draw_component]
                if order == "scry_then_draw"
                else [draw_component, scry_component]
            )
            effect_json = {
                "effect": "composite_resolution",
                "battle_model_scope": SCRY_DRAW_SCOPE,
                "scry_count": scry_count,
                "draw_count": draw_count,
                "count": draw_count,
                "resolution_order": order,
                "_composite_rule_components": components,
                "xmage_effect_classes": ["ScryEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_fixed_scry_draw_card_spell",
            ), "selected_exact_scope"

        if classes == {"DamageTargetEffect", "DrawCardSourceControllerEffect"}:
            if ability_classes(row):
                return None, "damage_draw_ability_class_not_simple"
            oracle_damage_draw = fixed_damage_draw_from_oracle(metadata)
            if oracle_damage_draw is None:
                return None, "damage_draw_oracle_not_exact_fixed"
            source_damage_draw = fixed_damage_draw_from_source(source_text)
            if source_damage_draw is None:
                return None, "damage_draw_source_not_fixed"
            amount, draw_count, target = oracle_damage_draw
            if source_damage_draw != (amount, draw_count):
                return None, "damage_draw_source_oracle_mismatch"
            if not source_matches_target_constraint(source_text, target):
                return None, "damage_draw_target_source_mismatch"
            target_base = restricted_target_base(target)
            damage_component = {
                "effect": "direct_damage",
                "battle_model_scope": DAMAGE_SCOPE,
                "amount": amount,
                "damage": amount,
                "target": target_base,
                "target_constraints": target_constraints_for(target),
                "compose_on_resolution": True,
                "xmage_effect_class": "DamageTargetEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            effect_json = {
                "effect": "composite_resolution",
                "battle_model_scope": DAMAGE_DRAW_SCOPE,
                "amount": amount,
                "damage": amount,
                "target": target_base,
                "target_constraints": target_constraints_for(target),
                "draw_count": draw_count,
                "count": draw_count,
                "_composite_rule_components": [damage_component, draw_component],
                "xmage_effect_classes": ["DamageTargetEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_fixed_damage_draw_card_spell",
            ), "selected_exact_scope"

        if classes == {"BoostTargetEffect", "DrawCardSourceControllerEffect"}:
            if ability_classes(row):
                return None, "boost_draw_ability_class_not_simple"
            oracle_boost = fixed_boost_draw_from_oracle(metadata)
            if oracle_boost is None:
                return None, "boost_draw_oracle_not_exact_fixed"
            source_boost = fixed_boost_draw_from_source(source_text)
            if source_boost is None:
                return None, "boost_draw_source_not_fixed"
            if source_boost != oracle_boost:
                return None, "boost_draw_source_oracle_mismatch"
            power_delta, toughness_delta, draw_count = oracle_boost
            boost_component = {
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
                "compose_on_resolution": True,
                "xmage_effect_class": "BoostTargetEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            effect_json = {
                "effect": "composite_resolution",
                "battle_model_scope": BOOST_DRAW_SCOPE,
                "power_delta": power_delta,
                "toughness_delta": toughness_delta,
                "power_boost": power_delta,
                "toughness_boost": toughness_delta,
                "draw_count": draw_count,
                "count": draw_count,
                "_composite_rule_components": [boost_component, draw_component],
                "xmage_effect_classes": ["BoostTargetEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_fixed_boost_draw_card_spell",
            ), "selected_exact_scope"

        if classes == {"DestroyTargetEffect", "DrawCardSourceControllerEffect"}:
            if ability_classes(row):
                return None, "destroy_draw_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "destroy_draw_oracle_not_simple"
            oracle_destroy = fixed_destroy_draw_from_oracle(metadata)
            if oracle_destroy is None:
                return None, "destroy_draw_oracle_not_exact_fixed"
            source_draw_count = fixed_destroy_draw_from_source(source_text)
            if source_draw_count is None:
                return None, "destroy_draw_source_not_fixed"
            effect, target_type, draw_count = oracle_destroy
            if source_draw_count != draw_count:
                return None, "destroy_draw_source_oracle_mismatch"
            if not source_matches_target_constraint(source_text, target_type):
                return None, "destroy_draw_target_source_mismatch"
            target_base = restricted_target_base(target_type)
            destroy_component = {
                "effect": effect,
                "battle_model_scope": DESTROY_SCOPE,
                "target": target_base,
                "target_constraints": target_constraints_for(target_type),
                "destination": "graveyard",
                "compose_on_resolution": True,
                "xmage_effect_class": "DestroyTargetEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            effect_json = {
                "effect": "composite_resolution",
                "battle_model_scope": DESTROY_DRAW_SCOPE,
                "target": target_base,
                "target_constraints": target_constraints_for(target_type),
                "destination": "graveyard",
                "draw_count": draw_count,
                "count": draw_count,
                "_composite_rule_components": [destroy_component, draw_component],
                "xmage_effect_classes": ["DestroyTargetEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_destroy_target_draw_card_spell",
            ), "selected_exact_scope"

        if classes == {"ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"}:
            if ability_classes(row):
                return None, "bounce_draw_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "bounce_draw_oracle_not_simple"
            oracle_bounce = fixed_bounce_draw_from_oracle(metadata)
            if oracle_bounce is None:
                return None, "bounce_draw_oracle_not_exact_fixed"
            source_draw_count = fixed_bounce_draw_from_source(source_text)
            if source_draw_count is None:
                return None, "bounce_draw_source_not_fixed"
            effect, target_type, draw_count = oracle_bounce
            if source_draw_count != draw_count:
                return None, "bounce_draw_source_oracle_mismatch"
            if not source_matches_bounce_target(source_text, target_type):
                return None, "bounce_draw_target_source_mismatch"
            target_base = restricted_target_base(target_type)
            bounce_component = {
                "effect": effect,
                "battle_model_scope": BOUNCE_SCOPE,
                "target": target_base,
                "target_constraints": target_constraints_for(target_type),
                "destination": "hand",
                "compose_on_resolution": True,
                "xmage_effect_class": "ReturnToHandTargetEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            effect_json = {
                "effect": "composite_resolution",
                "battle_model_scope": BOUNCE_DRAW_SCOPE,
                "target": target_base,
                "target_constraints": target_constraints_for(target_type),
                "destination": "hand",
                "draw_count": draw_count,
                "count": draw_count,
                "_composite_rule_components": [bounce_component, draw_component],
                "xmage_effect_classes": ["ReturnToHandTargetEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_bounce_draw_card_spell",
            ), "selected_exact_scope"

        if classes == {"CounterTargetEffect", "DrawCardSourceControllerEffect"}:
            if ability_classes(row):
                return None, "counter_draw_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "counter_draw_oracle_not_simple"
            target = counter_draw_target_from_oracle(metadata)
            if target is None:
                return None, "counter_draw_target_not_supported"
            draw_count = java_constructor_int(source_text, "DrawCardSourceControllerEffect", default=1)
            if draw_count != 1:
                return None, "counter_draw_count_not_fixed"
            counter_component = {
                "effect": "counter",
                "battle_model_scope": COUNTER_SCOPE,
                "target": target,
                "target_constraints": counter_target_constraints_for(target),
                "xmage_effect_class": "CounterTargetEffect",
            }
            draw_component = {
                "effect": "draw_cards",
                "battle_model_scope": DRAW_SCOPE,
                "count": draw_count,
                "compose_on_resolution": True,
                "xmage_effect_class": "DrawCardSourceControllerEffect",
            }
            effect_json = {
                "effect": "counter",
                "battle_model_scope": COUNTER_DRAW_SCOPE,
                "target": target,
                "target_constraints": counter_target_constraints_for(target),
                "draw_on_counter": draw_count,
                "draw_count": draw_count,
                "count": draw_count,
                "_composite_rule_components": [counter_component, draw_component],
                "xmage_effect_classes": ["CounterTargetEffect", "DrawCardSourceControllerEffect"],
                **flags,
            }
            if target == "blue_spell":
                effect_json["requires_blue_target"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_counter_target_draw_card_spell",
            ), "selected_exact_scope"

        if classes != {"DrawCardSourceControllerEffect"}:
            return None, "draw_effect_class_not_pure"
        additional_cost_fields, additional_cost_reason = fixed_draw_spell_additional_cost_fields_from_source(
            source_text,
            metadata,
        )
        if additional_cost_reason is not None:
            return None, additional_cost_reason
        count = java_constructor_int(source_text, "DrawCardSourceControllerEffect", default=1)
        if count is None or count <= 0:
            return None, "draw_count_missing"
        effect_json = {
            "effect": "draw_cards",
            "battle_model_scope": DRAW_SCOPE,
            "count": count,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            **flags,
            **(additional_cost_fields or {}),
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_draw_spell"), "selected_exact_scope"

    if unit == DAMAGE_UNIT:
        if classes != {"DamageTargetEffect"}:
            return None, "damage_effect_class_not_pure"
        additional_cost_fields, additional_cost_reason = fixed_damage_spell_additional_cost_fields_from_source(
            source_text,
            metadata,
        )
        if additional_cost_reason is not None:
            return None, additional_cost_reason
        amount = java_constructor_int(source_text, "DamageTargetEffect")
        if amount is None or amount <= 0:
            return None, "damage_amount_not_fixed"
        target = damage_target_from_oracle(metadata)
        if target is None:
            return None, "damage_target_not_supported"
        if not source_matches_target_constraint(source_text, target):
            return None, "damage_target_source_mismatch"
        target_base = restricted_target_base(target)
        effect_json = {
            "effect": "direct_damage",
            "battle_model_scope": DAMAGE_SCOPE,
            "amount": amount,
            "damage": amount,
            "target": target_base,
            "target_constraints": target_constraints_for(target),
            "xmage_effect_class": "DamageTargetEffect",
            **flags,
            **(additional_cost_fields or {}),
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_fixed_damage_spell"), "selected_exact_scope"

    if unit == DESTROY_UNIT:
        if classes != {"DestroyTargetEffect"}:
            return None, "destroy_effect_class_not_pure"
        target = destroy_target_from_oracle(metadata)
        if target is None:
            return None, "destroy_target_not_supported"
        effect, target_type = target
        if not source_matches_target_constraint(source_text, target_type):
            return None, "destroy_target_source_mismatch"
        target_base = restricted_target_base(target_type)
        effect_json = {
            "effect": effect,
            "battle_model_scope": DESTROY_SCOPE,
            "target": target_base,
            "target_constraints": target_constraints_for(target_type),
            "destination": "graveyard",
            "xmage_effect_class": "DestroyTargetEffect",
            **flags,
        }
        return build_proposal(row, metadata, effect_json, family_id="xmage_destroy_target_spell"), "selected_exact_scope"

    if unit == LIFE_UNIT and classes == {"DamageTargetEffect", "GainLifeEffect"}:
        if has_oracle_complexity(metadata):
            return None, "damage_life_gain_oracle_not_simple"
        source_damage = fixed_damage_gain_life_from_source(source_text)
        if source_damage is None:
            return None, "damage_life_gain_source_not_fixed"
        oracle_damage = fixed_damage_gain_life_from_oracle(metadata)
        if oracle_damage is None:
            return None, "damage_life_gain_oracle_not_exact_fixed"
        if source_damage != oracle_damage:
            return None, "damage_life_gain_source_oracle_mismatch"
        amount, life_gain, target = oracle_damage
        effect_json = {
            "effect": "direct_damage",
            "battle_model_scope": DAMAGE_GAIN_LIFE_SCOPE,
            "amount": amount,
            "damage": amount,
            "gain_life": life_gain,
            "controller_gain_life": life_gain,
            "target": target,
            "target_constraints": target_constraints_for(target),
            "xmage_effect_classes": ["DamageTargetEffect", "GainLifeEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_fixed_damage_gain_life_spell",
        ), "selected_exact_scope"

    if unit == LIFE_UNIT and classes == {"DestroyTargetEffect", "GainLifeEffect"}:
        if ability_classes(row):
            return None, "destroy_life_gain_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "destroy_life_gain_oracle_not_simple"
        source_destroy = simple_destroy_gain_life_from_source(source_text)
        if source_destroy is None:
            return None, "destroy_life_gain_source_not_fixed"
        oracle_destroy = simple_destroy_gain_life_from_oracle(metadata)
        if oracle_destroy is None:
            return None, "destroy_life_gain_oracle_not_exact_fixed"
        if source_destroy != oracle_destroy:
            return None, "destroy_life_gain_source_oracle_mismatch"
        target, life_gain = oracle_destroy
        effect = "remove_creature" if target == "creature" else "remove_permanent"
        effect_json = {
            "effect": effect,
            "battle_model_scope": DESTROY_GAIN_LIFE_SCOPE,
            "target": target,
            "target_constraints": target_constraints_for(target),
            "destination": "graveyard",
            "controller_gains_life": life_gain,
            "xmage_effect_classes": ["DestroyTargetEffect", "GainLifeEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_destroy_target_gain_life_spell",
        ), "selected_exact_scope"

    if unit == LIFE_UNIT and classes == {"DrawCardSourceControllerEffect", "GainLifeEffect"}:
        if ability_classes(row):
            return None, "life_gain_draw_ability_class_not_simple"
        if has_oracle_complexity(metadata):
            return None, "life_gain_draw_oracle_not_simple"
        oracle_pair = fixed_life_gain_draw_from_oracle(metadata)
        if oracle_pair is None:
            return None, "life_gain_draw_oracle_not_exact_fixed"
        source_pair = fixed_life_gain_draw_from_source(source_text)
        if source_pair is None:
            return None, "life_gain_draw_source_not_fixed"
        if source_pair != oracle_pair:
            return None, "life_gain_draw_source_oracle_mismatch"
        life_gain, draw_count = oracle_pair
        life_component = {
            "effect": "life_total_change",
            "battle_model_scope": LIFE_SCOPE,
            "life_gain_amount": life_gain,
            "target": "self",
            "compose_on_resolution": True,
            "xmage_effect_class": "GainLifeEffect",
        }
        draw_component = {
            "effect": "draw_cards",
            "battle_model_scope": DRAW_SCOPE,
            "count": draw_count,
            "compose_on_resolution": True,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
        }
        effect_json = {
            "effect": "composite_resolution",
            "battle_model_scope": LIFE_GAIN_DRAW_SCOPE,
            "life_gain_amount": life_gain,
            "draw_count": draw_count,
            "count": draw_count,
            "_composite_rule_components": [life_component, draw_component],
            "xmage_effect_classes": ["GainLifeEffect", "DrawCardSourceControllerEffect"],
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_fixed_life_gain_draw_card_spell",
        ), "selected_exact_scope"

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
        if not source_matches_target_constraint(source_text, target_type):
            return None, "exile_target_source_mismatch"
        target_base = restricted_target_base(target_type)
        effect_json = {
            "effect": effect,
            "battle_model_scope": EXILE_SCOPE,
            "target": target_base,
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
        if classes == {"RevealLibraryPickControllerEffect"}:
            if ability_classes(row):
                return None, "library_pick_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "library_pick_oracle_not_simple"
            oracle_pick = library_pick_from_oracle(metadata)
            if isinstance(oracle_pick, str):
                return None, oracle_pick
            source_pick = library_pick_from_source(source_text)
            if isinstance(source_pick, str):
                return None, source_pick
            for key in ("look_count", "pick_count", "pick_target", "pick_all_matching", "rest_destination"):
                if source_pick.get(key) != oracle_pick.get(key):
                    return None, f"library_pick_source_oracle_{key}_mismatch"
            pick_target = str(oracle_pick["pick_target"])
            effect_json = {
                "effect": "dig_to_hand",
                "battle_model_scope": LIBRARY_PICK_SPELL_SCOPE,
                "look_count": int(oracle_pick["look_count"]),
                "pick_count": int(oracle_pick["pick_count"]),
                "count": int(oracle_pick["pick_count"]),
                "max_count": int(oracle_pick["pick_count"]),
                "pick_target": pick_target,
                "target": pick_target,
                "target_constraints": library_pick_target_constraints_for(pick_target),
                "destination": "hand",
                "rest_destination": "graveyard",
                "reveal": True,
                "pick_up_to_count": True,
                "pick_all_matching": bool(oracle_pick.get("pick_all_matching")),
                "xmage_effect_class": "RevealLibraryPickControllerEffect",
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell",
            ), "selected_exact_scope"
        if classes == {"PutOnLibraryTargetEffect"}:
            if ability_classes(row):
                return None, "graveyard_to_library_ability_class_not_simple"
            oracle_target = graveyard_to_library_from_oracle(metadata)
            if oracle_target is None:
                return None, "graveyard_to_library_oracle_not_simple"
            source_target = graveyard_to_library_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            for key in ("target", "count", "destination", "up_to_count"):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"graveyard_to_library_source_oracle_{key}_mismatch"
            target_type = str(oracle_target["target"])
            count = int(oracle_target["count"])
            destination = str(oracle_target["destination"])
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": GRAVEYARD_TO_LIBRARY_SPELL_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(target_type),
                "count": count,
                "destination": destination,
                "target_controller": "self",
                "target_graveyard_controller": "self",
                "library_controller": "self",
                "xmage_effect_class": "PutOnLibraryTargetEffect",
                **flags,
            }
            if oracle_target.get("up_to_count"):
                effect_json["up_to_count"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_library_spell",
            ), "selected_exact_scope"
        if classes == {"TargetPlayerShufflesTargetCardsEffect"}:
            abilities = ability_classes(row)
            if abilities - {"FlashbackAbility"}:
                return None, "graveyard_shuffle_to_library_ability_class_not_supported"
            oracle_target = graveyard_shuffle_to_library_from_oracle(metadata)
            if isinstance(oracle_target, str):
                return None, oracle_target
            source_target = graveyard_shuffle_to_library_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            for key in (
                "target",
                "count",
                "destination",
                "up_to_count",
                "target_graveyard_controller",
                "target_controller",
                "library_controller",
            ):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"graveyard_shuffle_to_library_source_oracle_{key}_mismatch"
            aux_fields = auxiliary_recursion_spell_fields_from_source(metadata, source_text, abilities)
            if isinstance(aux_fields, str):
                return None, aux_fields
            count = int(oracle_target["count"])
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": GRAVEYARD_TO_LIBRARY_SPELL_SCOPE,
                "target": "any_card",
                "target_constraints": recursion_target_constraints_for(
                    "any_card",
                    controller="target_player",
                ),
                "count": count,
                "destination": "library_shuffle",
                "up_to_count": True,
                "target_controller": "target_player",
                "target_graveyard_controller": "target_player",
                "library_controller": "target_player",
                "xmage_effect_class": "TargetPlayerShufflesTargetCardsEffect",
                **aux_fields,
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_target_player_shuffle_graveyard_cards_to_library_spell",
            ), "selected_exact_scope"
        if classes == {"ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"}:
            if ability_classes(row):
                return None, "recursion_battlefield_counter_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "recursion_battlefield_counter_oracle_not_simple"
            oracle_target = recursion_to_battlefield_with_counter_from_oracle(metadata)
            if oracle_target is None:
                return None, "recursion_battlefield_counter_target_not_supported"
            source_target = recursion_battlefield_counter_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            for key in (
                "target",
                "count",
                "target_graveyard_controller",
                "battlefield_controller",
                "counter_type",
                "counter_amount",
            ):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"recursion_battlefield_counter_source_oracle_{key}_mismatch"
            target_type = str(oracle_target["target"])
            count = int(oracle_target["count"])
            target_graveyard_controller = str(oracle_target.get("target_graveyard_controller") or "self")
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_BATTLEFIELD_COUNTER_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(
                    target_type,
                    controller=target_graveyard_controller,
                ),
                "count": count,
                "destination": "battlefield",
                "target_controller": target_graveyard_controller,
                "target_graveyard_controller": target_graveyard_controller,
                "battlefield_controller": str(oracle_target.get("battlefield_controller") or "self"),
                "counter_type": str(oracle_target["counter_type"]),
                "counter_amount": int(oracle_target["counter_amount"]),
                "xmage_effect_class": "ReturnFromGraveyardToBattlefieldWithCounterTargetEffect",
                **flags,
            }
            if oracle_target.get("target_count_min") is not None:
                effect_json["target_count_min"] = int(oracle_target["target_count_min"])
            if oracle_target.get("additional_counter"):
                effect_json["additional_counter"] = True
            if oracle_target.get("keywords"):
                effect_json["keywords"] = list(oracle_target["keywords"])
                effect_json["counter_grants_keywords"] = list(oracle_target["keywords"])
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_battlefield_with_counter_spell",
            ), "selected_exact_scope"
        if classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}:
            if ability_classes(row):
                return None, "recursion_battlefield_all_ability_class_not_simple"
            oracle_target = recursion_all_to_battlefield_from_oracle(metadata)
            if oracle_target is None:
                return None, "recursion_battlefield_all_oracle_not_supported"
            if oracle_target.get("mana_value_exact_from_x"):
                return None, "recursion_battlefield_all_exact_x_mana_value_not_supported"
            source_target = recursion_all_to_battlefield_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            if source_target.get("mana_value_exact_from_x"):
                return None, "recursion_battlefield_all_exact_x_mana_value_not_supported"
            for key in (
                "target",
                "target_graveyard_controller",
                "battlefield_controller",
                "mana_value_max",
                "enters_tapped",
            ):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"recursion_battlefield_all_source_oracle_{key}_mismatch"
            target_type = str(oracle_target["target"])
            mana_value_max = oracle_target.get("mana_value_max")
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_BATTLEFIELD_ALL_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(
                    target_type,
                    controller="self",
                    mana_value_max=mana_value_max,
                ),
                "return_all_matching": True,
                "destination": "battlefield",
                "target_controller": "self",
                "target_graveyard_controller": "self",
                "battlefield_controller": "self",
                "xmage_effect_class": "ReturnFromYourGraveyardToBattlefieldAllEffect",
                **flags,
            }
            if mana_value_max is not None:
                effect_json["recursion_mana_value_max"] = mana_value_max
            if oracle_target.get("enters_tapped"):
                effect_json["enters_tapped"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_return_all_graveyard_cards_to_battlefield_spell",
            ), "selected_exact_scope"
        if classes == {"ExileTargetEffect"}:
            abilities = ability_classes(row)
            if abilities - AUXILIARY_RECURSION_SPELL_ABILITY_CLASSES:
                return None, "graveyard_exile_ability_class_not_supported"
            oracle_target = graveyard_exile_from_oracle(metadata)
            if isinstance(oracle_target, str):
                return None, oracle_target
            source_target = graveyard_exile_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            for key in (
                "target",
                "count",
                "target_controller",
                "single_graveyard",
                "up_to_count",
                "target_count_from_x",
            ):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"graveyard_exile_source_oracle_{key}_mismatch"
            aux_fields = auxiliary_recursion_spell_fields_from_source(metadata, source_text, abilities)
            if isinstance(aux_fields, str):
                return None, aux_fields
            effect_json = {
                "effect": "graveyard_exile",
                "battle_model_scope": GRAVEYARD_EXILE_SPELL_SCOPE,
                "target": str(oracle_target["target"]),
                "target_constraints": recursion_target_constraints_for(
                    str(oracle_target["target"]),
                    controller=str(oracle_target["target_controller"]),
                ),
                "count": int(oracle_target["count"]),
                "destination": "exile",
                "target_controller": str(oracle_target["target_controller"]),
                "graveyard_exile_target": str(oracle_target["target"]),
                "graveyard_exile_target_count": int(oracle_target["count"]),
                "graveyard_exile_destination": "exile",
                "graveyard_exile_single_graveyard": bool(oracle_target["single_graveyard"]),
                "xmage_effect_class": "ExileTargetEffect",
                **aux_fields,
                **flags,
            }
            if oracle_target["up_to_count"]:
                effect_json["up_to_count"] = True
                effect_json["graveyard_exile_up_to_count"] = True
            if oracle_target["target_count_from_x"]:
                effect_json["target_count_from_x"] = True
                effect_json["graveyard_exile_target_count_from_x"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_exile_spell",
            ), "selected_exact_scope"
        if classes == {"MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"}:
            if ability_classes(row):
                return None, "mill_return_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "mill_return_oracle_not_simple"
            oracle_target = mill_then_return_from_oracle(metadata)
            if oracle_target is None:
                return None, "mill_return_oracle_not_supported"
            source_target = mill_then_return_from_source(source_text)
            if isinstance(source_target, str):
                return None, source_target
            for key in ("mill_count", "target", "count", "up_to_count"):
                if source_target.get(key) != oracle_target.get(key):
                    return None, f"mill_return_source_oracle_{key}_mismatch"
            target_type = str(oracle_target["target"])
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_MILL_RETURN_SCOPE,
                "pre_recursion_mill_count": int(oracle_target["mill_count"]),
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(target_type),
                "count": int(oracle_target["count"]),
                "destination": "hand",
                "target_controller": "self",
                "up_to_count": True,
                "xmage_effect_classes": ["MillCardsControllerEffect", "ReturnCardChosenFromGraveyardEffect"],
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_mill_then_return_graveyard_to_hand_spell",
            ), "selected_exact_scope"
        auxiliary_recursion_abilities = ability_classes(row)
        auxiliary_recursion_spell = bool(auxiliary_recursion_abilities) and (
            auxiliary_recursion_abilities <= AUXILIARY_RECURSION_SPELL_ABILITY_CLASSES
        )
        if classes == {"ReturnFromGraveyardToBattlefieldTargetEffect"} and auxiliary_recursion_spell:
            effect_text = recursion_effect_text_from_oracle(metadata)
            if effect_text is None:
                return None, "recursion_auxiliary_primary_oracle_not_simple"
            target = recursion_to_battlefield_from_oracle({**metadata, "oracle_text": effect_text})
            if target is None:
                return None, "recursion_auxiliary_battlefield_target_not_supported"
            aux_fields = auxiliary_recursion_spell_fields_from_source(
                metadata,
                source_text,
                auxiliary_recursion_abilities,
            )
            if isinstance(aux_fields, str):
                return None, aux_fields
            target_type = str(target["target"])
            count = int(target["count"])
            target_graveyard_controller = str(target.get("target_graveyard_controller") or "self")
            if not source_supports_battlefield_recursion_target(source_text, target_graveyard_controller):
                return None, "recursion_auxiliary_battlefield_source_target_not_supported"
            if not source_supports_battlefield_recursion_target_type(source_text, target_type):
                return None, "recursion_auxiliary_battlefield_source_target_not_supported"
            mana_value_max = target.get("mana_value_max")
            if not source_supports_battlefield_recursion_mana_value(source_text, mana_value_max):
                return None, "recursion_auxiliary_battlefield_source_mana_value_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_BATTLEFIELD_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(
                    target_type,
                    controller=target_graveyard_controller,
                    mana_value_max=mana_value_max,
                ),
                "count": count,
                "destination": "battlefield",
                "target_controller": target_graveyard_controller,
                "target_graveyard_controller": target_graveyard_controller,
                "battlefield_controller": str(target.get("battlefield_controller") or "self"),
                "xmage_effect_class": "ReturnFromGraveyardToBattlefieldTargetEffect",
                **aux_fields,
                **flags,
            }
            if mana_value_max is not None:
                effect_json["recursion_mana_value_max"] = mana_value_max
            if target.get("enters_tapped"):
                effect_json["enters_tapped"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_battlefield_auxiliary_spell",
            ), "selected_exact_scope"
        if classes == {"ReturnFromGraveyardToBattlefieldTargetEffect"}:
            if ability_classes(row):
                return None, "recursion_battlefield_ability_class_not_simple"
            choose_components = recursion_battlefield_choose_one_or_both_from_text(oracle_text(metadata))
            if choose_components is not None:
                if not source_supports_battlefield_choose_one_or_both_recursion(source_text):
                    return None, "recursion_battlefield_choose_one_or_both_source_not_supported"
                effect_json = {
                    "effect": "recursion",
                    "battle_model_scope": "xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1",
                    "mode_selection": "one_or_both",
                    "recursion_components": choose_components,
                    "destination": "battlefield",
                    "target_controller": "self",
                    "target_graveyard_controller": "self",
                    "battlefield_controller": "self",
                    "xmage_effect_class": "ReturnFromGraveyardToBattlefieldTargetEffect",
                    **flags,
                }
                return build_proposal(
                    row,
                    metadata,
                    effect_json,
                    family_id="xmage_graveyard_to_battlefield_choose_one_or_both_spell",
                ), "selected_exact_scope"
            target = recursion_to_battlefield_from_oracle(metadata)
            if target is None:
                if has_oracle_complexity(metadata):
                    return None, "recursion_battlefield_oracle_not_simple"
                return None, "recursion_battlefield_target_not_supported"
            if has_oracle_complexity(metadata) and not target.get("oracle_complexity_supported"):
                return None, "recursion_battlefield_oracle_not_simple"
            target_type = str(target["target"])
            count = int(target["count"])
            target_graveyard_controller = str(target.get("target_graveyard_controller") or "self")
            if not source_supports_battlefield_recursion_target(source_text, target_graveyard_controller):
                return None, "recursion_battlefield_source_target_not_supported"
            mana_value_max = target.get("mana_value_max")
            mana_value_max_from_x = bool(target.get("mana_value_max_from_x"))
            mana_value_max_from_graveyard_permanent_count = bool(
                target.get("mana_value_max_from_graveyard_permanent_count")
            )
            total_mana_value_max = target.get("recursion_total_mana_value_max")
            requires_different_names = bool(target.get("requires_different_names"))
            graveyard_from_battlefield_this_turn = bool(target.get("graveyard_from_battlefield_this_turn"))
            count_from_x = bool(target.get("count_from_x"))
            requires_source_target_type_confirmation = bool(
                total_mana_value_max is not None
                or requires_different_names
                or graveyard_from_battlefield_this_turn
                or target_type in {"ally_creature", "outlaw_creature"}
                or mana_value_max_from_graveyard_permanent_count
                or target_type in {"nonland_permanent", "rebel_permanent", "aura_card"}
            )
            if requires_source_target_type_confirmation and not source_supports_battlefield_recursion_target_type(
                source_text,
                target_type,
            ):
                return None, "recursion_battlefield_source_target_not_supported"
            if not source_supports_battlefield_recursion_mana_value(source_text, mana_value_max):
                return None, "recursion_battlefield_source_mana_value_not_supported"
            if mana_value_max_from_x and not source_supports_battlefield_recursion_x_mana_value(source_text):
                return None, "recursion_battlefield_source_x_mana_value_not_supported"
            if (
                mana_value_max_from_graveyard_permanent_count
                and not source_supports_battlefield_recursion_graveyard_permanent_count_mana_value(source_text)
            ):
                return None, "recursion_battlefield_source_graveyard_permanent_count_mana_value_not_supported"
            if count_from_x and not source_supports_recursion_x_target_count(source_text):
                return None, "recursion_battlefield_source_x_count_not_supported"
            if not source_supports_battlefield_recursion_total_mana_value(source_text, total_mana_value_max):
                return None, "recursion_battlefield_source_total_mana_value_not_supported"
            if not source_supports_battlefield_recursion_different_names(source_text, requires_different_names):
                return None, "recursion_battlefield_source_different_names_not_supported"
            if not source_supports_battlefield_recursion_this_turn(source_text, graveyard_from_battlefield_this_turn):
                return None, "recursion_battlefield_source_this_turn_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_BATTLEFIELD_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(
                    target_type,
                    controller=target_graveyard_controller,
                    mana_value_max=mana_value_max,
                    mana_value_max_from_x=mana_value_max_from_x,
                    total_mana_value_max=total_mana_value_max,
                    requires_different_names=requires_different_names,
                    graveyard_from_battlefield_this_turn=graveyard_from_battlefield_this_turn,
                ),
                "count": count,
                "destination": "battlefield",
                "target_controller": target_graveyard_controller,
                "target_graveyard_controller": target_graveyard_controller,
                "battlefield_controller": str(target.get("battlefield_controller") or "self"),
                "xmage_effect_class": "ReturnFromGraveyardToBattlefieldTargetEffect",
                **flags,
            }
            if mana_value_max is not None:
                effect_json["recursion_mana_value_max"] = mana_value_max
            if mana_value_max_from_x:
                effect_json["target_mana_value_max_from_x"] = True
            if mana_value_max_from_graveyard_permanent_count:
                effect_json["target_mana_value_max_from_graveyard_permanent_count"] = True
                effect_json["target_constraints"] = with_graveyard_permanent_count_mana_value_constraint(
                    effect_json["target_constraints"]
                )
            if total_mana_value_max is not None:
                effect_json["recursion_total_mana_value_max"] = int(total_mana_value_max)
            if target.get("up_to_count"):
                effect_json["up_to_count"] = True
            if count_from_x:
                effect_json["count_from_x"] = True
            if requires_different_names:
                effect_json["requires_different_names"] = True
            if graveyard_from_battlefield_this_turn:
                effect_json["graveyard_from_battlefield_this_turn"] = True
            if target.get("enters_tapped"):
                effect_json["enters_tapped"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_battlefield_spell",
            ), "selected_exact_scope"
        exile_self_recursion_classes = {
            "ExileSpellEffect",
            "ReturnFromGraveyardToHandTargetEffect",
        }
        if classes == exile_self_recursion_classes:
            if ability_classes(row):
                return None, "recursion_exile_self_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "recursion_exile_self_oracle_not_simple"
            x_target = recursion_to_hand_exile_self_x_from_oracle(metadata)
            if x_target is not None:
                target_type = str(x_target["target"])
                if not source_supports_recursion_x_target_count(source_text):
                    return None, "recursion_exile_self_source_x_count_not_supported"
                if not source_supports_exile_self_recursion_target(source_text, target_type):
                    return None, "recursion_exile_self_source_target_not_supported"
                effect_json = {
                    "effect": "recursion",
                    "battle_model_scope": RECURSION_SCOPE,
                    "target": target_type,
                    "target_constraints": recursion_target_constraints_for(target_type),
                    "count": int(x_target["count"]),
                    "count_from_x": True,
                    "destination": "hand",
                    "target_controller": "self",
                    "exiles_self": True,
                    "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                    "xmage_additional_effect_class": "ExileSpellEffect",
                    **flags,
                }
                if x_target.get("up_to_count"):
                    effect_json["up_to_count"] = True
                return build_proposal(
                    row,
                    metadata,
                    effect_json,
                    family_id="xmage_graveyard_to_hand_x_count_exile_self_spell",
                ), "selected_exact_scope"
            components = recursion_to_hand_exile_self_components_from_oracle(metadata)
            if components is not None:
                if not source_supports_exile_self_recursion_components(source_text, components):
                    return None, "recursion_exile_self_source_components_not_supported"
                effect_json = {
                    "effect": "recursion",
                    "battle_model_scope": "xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1",
                    "mode_selection": "all_components",
                    "recursion_components": components,
                    "destination": "hand",
                    "target_controller": "self",
                    "exiles_self": True,
                    "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                    "xmage_additional_effect_class": "ExileSpellEffect",
                    **flags,
                }
                return build_proposal(
                    row,
                    metadata,
                    effect_json,
                    family_id="xmage_graveyard_to_hand_multi_component_exile_self_spell",
                ), "selected_exact_scope"
            target = recursion_to_hand_exile_self_from_oracle(metadata)
            if target is None:
                return None, "recursion_exile_self_target_not_supported"
            target_type, count, up_to = target
            if not source_supports_exile_self_recursion_target(source_text, target_type):
                return None, "recursion_exile_self_source_target_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(target_type),
                "count": count,
                "destination": "hand",
                "target_controller": "self",
                "exiles_self": True,
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                "xmage_additional_effect_class": "ExileSpellEffect",
                **flags,
            }
            if up_to:
                effect_json["up_to_count"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_exile_self_spell",
            ), "selected_exact_scope"
        if classes != {"ReturnFromGraveyardToHandTargetEffect"}:
            return None, "recursion_effect_class_not_pure"
        if auxiliary_recursion_spell:
            effect_text = recursion_effect_text_from_oracle(metadata)
            if effect_text is None:
                return None, "recursion_auxiliary_primary_oracle_not_simple"
            target = recursion_to_hand_from_text(effect_text)
            if target is None:
                return None, "recursion_auxiliary_target_not_supported"
            source_target = activated_recursion_to_hand_target_from_source(source_text)
            if isinstance(source_target, str):
                return None, "recursion_auxiliary_source_target_not_supported"
            target_type, count, up_to = target
            source_target_type, source_count, source_up_to = source_target
            if source_target_type != target_type:
                return None, "recursion_auxiliary_source_oracle_target_mismatch"
            if int(source_count) != int(count):
                return None, "recursion_auxiliary_source_oracle_count_mismatch"
            if bool(source_up_to) != bool(up_to):
                return None, "recursion_auxiliary_source_oracle_count_mismatch"
            if len(re.findall(r"ReturnFromGraveyardToHandTargetEffect\s*\(", source_text or "")) != 1:
                return None, "recursion_auxiliary_source_effect_count_not_supported"
            aux_fields = auxiliary_recursion_spell_fields_from_source(
                metadata,
                source_text,
                auxiliary_recursion_abilities,
            )
            if isinstance(aux_fields, str):
                return None, aux_fields
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(target_type),
                "count": count,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **aux_fields,
                **flags,
            }
            if up_to:
                effect_json["up_to_count"] = True
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_auxiliary_spell",
            ), "selected_exact_scope"
        if ability_classes(row):
            return None, "recursion_ability_class_not_simple"
        choose_components = recursion_choose_one_or_both_from_text(oracle_text(metadata))
        if choose_components is not None:
            if not source_supports_choose_one_or_both_recursion(source_text):
                return None, "recursion_choose_one_or_both_source_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": "xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1",
                "mode_selection": "one_or_both",
                "recursion_components": choose_components,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_choose_one_or_both_spell",
            ), "selected_exact_scope"
        choose_one_components = recursion_choose_one_from_text(oracle_text(metadata))
        if choose_one_components is not None:
            if not source_supports_choose_one_recursion(source_text):
                return None, "recursion_choose_one_source_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": "xmage_return_choose_one_graveyard_cards_to_hand_spell_v1",
                "mode_selection": "choose_one",
                "recursion_components": choose_one_components,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_choose_one_spell",
            ), "selected_exact_scope"
        for_each_color_components = recursion_for_each_color_creature_components_from_oracle(metadata)
        if for_each_color_components is not None:
            if not source_supports_for_each_color_creature_recursion(source_text):
                return None, "recursion_for_each_color_source_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": "xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1",
                "mode_selection": "all_components",
                "recursion_components": for_each_color_components,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_for_each_color_spell",
            ), "selected_exact_scope"
        multi_target_components = recursion_up_to_one_multi_target_components_from_oracle(metadata)
        if multi_target_components is not None:
            if not source_supports_up_to_one_multi_target_recursion(source_text, multi_target_components):
                return None, "recursion_multi_target_source_not_supported"
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": "xmage_return_multiple_graveyard_cards_to_hand_spell_v1",
                "mode_selection": "all_components",
                "recursion_components": multi_target_components,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **flags,
            }
            return build_proposal(
                row,
                metadata,
                effect_json,
                family_id="xmage_graveyard_to_hand_multi_target_spell",
            ), "selected_exact_scope"
        if has_oracle_complexity(metadata):
            return None, "recursion_oracle_not_simple"
        x_target = recursion_to_hand_x_from_oracle(metadata)
        if x_target is not None:
            if not source_supports_recursion_x_target_count(source_text):
                return None, "recursion_source_x_count_not_supported"
            target_type = str(x_target["target"])
            effect_json = {
                "effect": "recursion",
                "battle_model_scope": RECURSION_SCOPE,
                "target": target_type,
                "target_constraints": recursion_target_constraints_for(target_type),
                "count": int(x_target["count"]),
                "count_from_x": True,
                "destination": "hand",
                "target_controller": "self",
                "xmage_effect_class": "ReturnFromGraveyardToHandTargetEffect",
                **flags,
            }
            return build_proposal(row, metadata, effect_json, family_id="xmage_graveyard_to_hand_x_count_spell"), "selected_exact_scope"
        target = recursion_to_hand_from_oracle(metadata)
        if target is None:
            return None, "recursion_target_not_supported"
        target_type, count, up_to = target
        if target_type == "shared_creature_type" and not (
            "ChoiceCreatureType" in source_text
            and "FilterCreatureCard" in source_text
            and re.search(r"TargetCardInYourGraveyard\s*\(\s*0\s*,\s*3\s*,", source_text, re.S)
        ):
            return None, "recursion_source_target_not_supported"
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

    if unit == TUTOR_UNIT:
        if not is_spell(metadata):
            return None, "not_instant_or_sorcery_spell"
        if ability_classes(row):
            return None, "tutor_ability_class_not_simple"
        if has_additional_cost(source_text) or "additional cost" in oracle_text(metadata):
            return None, "additional_cost_detected"
        if classes not in ({"SearchLibraryPutInPlayEffect"}, {"SearchLibraryPutOnLibraryEffect"}):
            return None, "tutor_effect_class_not_supported"
        effect_class = next(iter(classes))
        oracle_tutor = library_tutor_from_oracle(metadata)
        if isinstance(oracle_tutor, str):
            return None, oracle_tutor
        source_tutor = library_tutor_from_source(source_text, effect_class)
        if isinstance(source_tutor, str):
            return None, source_tutor
        for key in ("target", "count", "up_to_count", "destination", "enters_tapped"):
            if source_tutor.get(key) != oracle_tutor.get(key):
                return None, f"library_tutor_source_oracle_{key}_mismatch"
        destination = oracle_tutor["destination"]
        target = f"{oracle_tutor['target']}_to_battlefield" if destination == "battlefield" else f"{oracle_tutor['target']}_to_top"
        count = int(oracle_tutor["count"])
        scope = TUTOR_BATTLEFIELD_SCOPE if destination == "battlefield" else TUTOR_TOP_SCOPE
        effect_json = {
            "effect": "tutor",
            "battle_model_scope": scope,
            "target": target,
            "count": count,
            "max_count": count,
            "xmage_effect_class": effect_class,
            **flags,
        }
        if oracle_tutor.get("up_to_count"):
            effect_json["up_to_count"] = True
        if destination == "battlefield":
            effect_json["tutor_enters_tapped"] = bool(oracle_tutor.get("enters_tapped"))
        return build_proposal(row, metadata, effect_json, family_id="xmage_library_search_spell"), "selected_exact_scope"

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

    if unit == BOOST_CONTROLLED_SPELL_UNIT:
        if classes != {"BoostControlledEffect"}:
            return None, "boost_controlled_effect_class_not_pure"
        if ability_classes(row):
            return None, "boost_controlled_ability_class_not_simple"
        source_boost = fixed_boost_controlled_from_source(source_text)
        if isinstance(source_boost, str):
            return None, source_boost
        if source_boost is None:
            return None, "boost_controlled_source_not_single_fixed"
        oracle_boost = fixed_boost_controlled_from_oracle(metadata)
        if isinstance(oracle_boost, str):
            return None, oracle_boost
        if oracle_boost is None:
            return None, "boost_controlled_oracle_not_simple"
        if source_boost != oracle_boost:
            return None, "boost_controlled_source_oracle_mismatch"
        power, toughness = oracle_boost
        effect_json = {
            "effect": "controlled_stat_modifier_until_eot",
            "battle_model_scope": BOOST_CONTROLLED_SPELL_SCOPE,
            "target": "controlled_creatures",
            "target_controller": "self",
            "target_constraints": {"controller": "self", "card_types": ["creature"]},
            "power_delta": power,
            "toughness_delta": toughness,
            "xmage_effect_class": "BoostControlledEffect",
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_boost_controlled_creatures_until_eot_spell",
        ), "selected_exact_scope"

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

    if boost_keyword_spell_unit:
        if classes != {"BoostTargetEffect", "GainAbilityTargetEffect"}:
            return None, "boost_keyword_effect_class_not_pure"
        abilities = ability_classes(row)
        if len(abilities) != 1:
            return None, "boost_keyword_ability_not_single"
        ability_class = next(iter(abilities))
        keyword = TARGET_GRANT_KEYWORD_ABILITY_CLASSES.get(ability_class)
        if not keyword:
            return None, "boost_keyword_ability_not_supported"
        if has_oracle_complexity(metadata):
            return None, "boost_keyword_oracle_not_simple"
        source_boost = fixed_boost_keyword_target_from_source(source_text, ability_class)
        if source_boost is None:
            return None, "boost_keyword_source_not_single_fixed"
        oracle_boost = fixed_boost_keyword_target_from_oracle(metadata)
        if oracle_boost is None:
            return None, "boost_keyword_oracle_not_exact_fixed"
        source_power, source_toughness, source_target_controller = source_boost
        oracle_power, oracle_toughness, oracle_keyword, oracle_target_controller = oracle_boost
        if (source_power, source_toughness) != (oracle_power, oracle_toughness):
            return None, "boost_keyword_source_oracle_boost_mismatch"
        if keyword != oracle_keyword:
            return None, "boost_keyword_source_oracle_keyword_mismatch"
        if source_target_controller != oracle_target_controller:
            return None, "boost_keyword_source_oracle_target_mismatch"
        effect_json = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": BOOST_KEYWORD_SCOPE,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": oracle_target_controller,
            "power_delta": oracle_power,
            "toughness_delta": oracle_toughness,
            "power_boost": oracle_power,
            "toughness_boost": oracle_toughness,
            "duration": "until_end_of_turn",
            "granted_keywords_until_eot": [keyword],
            "xmage_effect_classes": ["BoostTargetEffect", "GainAbilityTargetEffect"],
            "xmage_ability_class": ability_class,
            **flags,
        }
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_boost_keyword_target_creature_until_eot_spell",
        ), "selected_exact_scope"

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
        source_blocker = simple_mana_source_source_blocker(source_text, mana_ability_classes)
        if source_blocker:
            return None, source_blocker
        mana_source_detail = simple_mana_source_detail_from_oracle(metadata)
        if mana_source_detail is None:
            return None, "mana_source_oracle_not_simple"
        type_line = str(metadata.get("type_line") or "").lower()
        permanent_type = "creature" if "creature" in type_line else "artifact" if "artifact" in type_line else "permanent"
        effect_json = {
            "effect": "ramp_permanent",
            "battle_model_scope": MANA_SCOPE,
            "is_mana_source": True,
            "mana_produced": int(mana_source_detail["mana_produced"]),
            "produces": str(mana_source_detail["produces"]),
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": permanent_type,
            "xmage_mana_ability_classes": sorted(mana_ability_classes),
            "xmage_effect_classes": sorted(classes),
        }
        if mana_source_detail.get("produced_mana_symbols"):
            effect_json["produced_mana_symbols"] = list(mana_source_detail["produced_mana_symbols"])
        if mana_source_detail.get("activation_mana_cost"):
            effect_json["activation_mana_cost"] = mana_source_detail["activation_mana_cost"]
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
        if (
            str(row.get("adapter_work_unit") or "") not in SUPPORTED_UNITS
            and not is_static_keyword_creature_unit(row)
            and not is_creature_etb_life_gain_unit(row)
            and not is_creature_etb_draw_unit(row)
            and not is_creature_dies_draw_unit(row)
            and not is_spell_cast_draw_engine_unit(row)
            and not is_permanent_activated_draw_discard_unit(row)
            and not is_creature_etb_damage_unit(row)
            and not is_creature_etb_graveyard_to_library_unit(row)
            and not is_creature_etb_library_pick_unit(row)
            and not is_creature_tap_damage_unit(row)
            and not is_creature_etb_token_unit(row)
            and not is_creature_etb_add_counters_unit(row)
            and not is_permanent_activated_draw_unit(row)
            and not is_permanent_activated_damage_unit(row)
            and not is_permanent_activated_destroy_unit(row)
            and not is_permanent_activated_life_gain_unit(row)
            and not is_permanent_activated_self_boost_unit(row)
            and not is_permanent_activated_target_boost_unit(row)
            and not is_permanent_activated_target_keyword_unit(row)
            and not is_static_controlled_pt_unit(row)
            and not is_static_graveyard_count_pt_unit(row)
            and not is_static_graveyard_threshold_boost_unit(row)
            and not is_static_graveyard_count_boost_unit(row)
            and not is_permanent_activated_recursion_to_hand_unit(row)
            and not is_permanent_activated_recursion_to_battlefield_unit(row)
            and not is_permanent_activated_graveyard_exile_unit(row)
            and not is_boost_keyword_spell_unit(row)
            and not (
                str(row.get("adapter_work_unit") or "") == RECURSION_UNIT
                and effect_classes(row) == {"PutOnLibraryTargetEffect"}
                and not ability_classes(row)
            )
        ):
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
                "draw_engine::xmage_draw_card_variant_review_v1 rows with DrawCardSourceControllerEffect and EntersBattlefieldTriggeredAbility plus only static self keywords",
                "draw_engine::xmage_draw_card_variant_review_v1 rows with DrawCardSourceControllerEffect and DiesSourceTriggeredAbility plus only static self keywords",
                "draw_engine::xmage_draw_card_variant_review_v1 rows with DrawCardSourceControllerEffect and SpellCastControllerTriggeredAbility, exact draw count, and supported spell filters",
                "draw_engine::xmage_draw_card_variant_review_v1 rows with DrawDiscardControllerEffect and SimpleActivatedAbility, exact draw-then-discard counts, and mana/tap/life/source self-sacrifice costs only",
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, EntersBattlefieldTriggeredAbility, and exact fixed ETB damage Oracle text",
                "removal_destroy::targeted_destroy_variant_v1 rows with DestroyTargetEffect, EntersBattlefieldTriggeredAbility, and exact unrestricted ETB destroy Oracle text",
                "add_counters::targeted_add_counters_variant_v1 rows with AddCountersTargetEffect, EntersBattlefieldTriggeredAbility, exact one target creature Oracle text, and only static self keywords",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with PutOnLibraryTargetEffect, EntersBattlefieldTriggeredAbility, exact self-graveyard top/bottom library Oracle text, and only static self keywords",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with LookLibraryAndPickControllerEffect, EntersBattlefieldTriggeredAbility, exact ETB look-library pick-one-to-hand Oracle/source agreement, and only static self keywords",
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, SimpleActivatedAbility, exact creature Oracle tap damage, and TapSourceCost only",
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, SimpleActivatedAbility, fixed activated damage, mana/tap/self-sacrifice source costs only, and simple any-target or creature targets",
                "removal_destroy::targeted_destroy_variant_v1 rows with DestroyTargetEffect, SimpleActivatedAbility, exact activated destroy-target Oracle text, and mana/tap/self-sacrifice source costs only",
                "life_gain::xmage_life_gain_variant_review_v1 rows with GainLifeEffect, SimpleActivatedAbility, exact fixed activated life-gain Oracle text, and mana/tap/source self-sacrifice costs only",
                "xmage_signature BoostControlledEffect one-shot spell rows with exact fixed controlled-creature boost until EOT and no color/modal/dynamic filters",
                "xmage_signature BoostSourceEffect + SimpleActivatedAbility rows with exact activated self boost until EOT and mana/tap source costs only",
                "xmage_signature BoostTargetEffect + SimpleActivatedAbility + TargetCreaturePermanent rows with exact activated target-creature boost until EOT and mana/tap source costs only",
                "xmage_signature BoostControlledEffect + SimpleStaticAbility rows with exact static controlled-creature power/toughness boosts and simple creature/artifact/subtype/legendary filters",
                "SetBasePowerToughnessSourceEffect + SimpleStaticAbility creature rows whose source and Oracle both set source power/toughness to a direct controller/all-graveyards card-type count",
                "grant_protection_from_chosen_color rows with GainAbilityTargetEffect + SimpleActivatedAbility, exact activated target-creature keyword until EOT, and simple mana/tap source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, SimpleActivatedAbility, exact activated graveyard-to-hand Oracle text, and mana/tap/self-sacrifice/discard-a-card source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToBattlefieldTargetEffect, SimpleActivatedAbility, exact activated graveyard-to-battlefield Oracle text, and mana/tap/source self-sacrifice costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with MillCardsControllerEffect + ReturnCardChosenFromGraveyardEffect, exact mill-then-return Oracle/source agreement, and no additional ability class",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with MillCardsControllerEffect + ReturnCardChosenFromGraveyardEffect, EntersBattlefieldTriggeredAbility, exact ETB mill-then-return Oracle/source agreement, and only static self keywords",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ExileTargetEffect, SimpleActivatedAbility, exact activated graveyard-exile Oracle text, and mana/tap/self-sacrifice source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect + ExileSpellEffect, no extra ability class, exact fixed graveyard-to-hand Oracle text, and trailing self-exile text",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, no extra ability class, exact choose-one-or-both Oracle text, and two fixed graveyard-to-hand components",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, no extra ability class, exact choose-one Oracle text, and two fixed alternative graveyard-to-hand components",
                "draw_cards::xmage_draw_card_variant_review_v1 rows with CounterTargetEffect + DrawCardSourceControllerEffect, exact supported counter-target spell Oracle text, and draw-on-counter runtime metadata",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with PutOnLibraryTargetEffect, no extra ability class, exact graveyard-to-library top/bottom Oracle text, and self-graveyard targets only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with RevealLibraryPickControllerEffect, no extra ability class, exact reveal-top-library pick-to-hand Oracle/source agreement, and graveyard rest destination",
                "life_gain::xmage_life_gain_variant_review_v1 rows with DamageTargetEffect + GainLifeEffect and exact fixed damage/life-gain Oracle text",
                "token_maker CreateTokenEffect rows with EntersBattlefieldTriggeredAbility, a fixed token count, and a literal safe creature token class",
                "grant_protection_from_chosen_color rows with BoostTargetEffect + GainAbilityTargetEffect, one fixed target creature, and exact until-EOT keyword Oracle text",
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
