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
PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE = "xmage_permanent_simple_activated_exile_graveyard_card_v1"
PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE = "xmage_permanent_simple_activated_life_gain_v1"
GRAVEYARD_SELF_RETURN_TO_HAND_SCOPE = "xmage_graveyard_simple_activated_self_return_to_hand_v1"
GRAVEYARD_SELF_RETURN_TO_BATTLEFIELD_SCOPE = (
    "xmage_graveyard_simple_activated_self_return_to_battlefield_v1"
)
DESTROY_SCOPE = "xmage_destroy_target_spell_v1"
LIFE_SCOPE = "xmage_fixed_controller_gain_life_spell_v1"
EXILE_SCOPE = "xmage_exile_target_spell_v1"
MANA_SCOPE = "xmage_simple_tap_mana_source_permanent_v1"
COUNTER_SCOPE = "xmage_counter_target_spell_v1"
BOUNCE_SCOPE = "xmage_return_target_to_hand_spell_v1"
RECURSION_SCOPE = "xmage_return_target_graveyard_card_to_hand_spell_v1"
RECURSION_BATTLEFIELD_SCOPE = "xmage_return_target_graveyard_card_to_battlefield_spell_v1"
GRAVEYARD_TO_LIBRARY_SPELL_SCOPE = "xmage_put_target_graveyard_card_on_library_spell_v1"
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
PERMANENT_ACTIVATED_DRAW_SCOPE = "xmage_permanent_simple_activated_draw_v1"
ETB_LIFE_GAIN_CREATURE_SCOPE = "xmage_creature_etb_gain_life_v1"
ETB_DRAW_CREATURE_SCOPE = "xmage_creature_etb_draw_cards_v1"
ETB_DAMAGE_CREATURE_SCOPE = "xmage_creature_etb_fixed_damage_target_v1"
ETB_DESTROY_CREATURE_SCOPE = "xmage_creature_etb_destroy_target_v1"
ETB_RECURSION_CREATURE_SCOPE = "xmage_creature_etb_return_graveyard_card_to_hand_v1"
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
    "FlyingAbility": "flying",
    "HasteAbility": "haste",
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
    "lifelink",
    "vigilance",
    "trample",
    "menace",
    "prowess",
    "reach",
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
    if " with " in lower_description and not (
        lower_description.endswith(" with flying")
        or lower_description.endswith(" with haste")
    ):
        return {}, "token_description_keyword_not_supported"
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


def recursion_target_constraints_for(
    target: str,
    *,
    controller: str = "self",
    mana_value_max: int | None = None,
) -> dict[str, Any]:
    constraints: dict[str, Any] = {"zone": "graveyard", "controller": controller}
    if target == "any_card":
        constraints["scope"] = "any_card"
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
    elif target == "shared_creature_type":
        constraints["card_types"] = ["creature"]
        constraints["shared_subtype_group"] = "creature_type"
    elif target in {"creature", "artifact", "enchantment", "sorcery", "instant", "land"}:
        constraints["card_types"] = [target]
    elif target == "planeswalker":
        constraints["card_types"] = ["planeswalker"]
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
    elif target == "artifact_or_enchantment":
        constraints["card_types"] = ["artifact", "enchantment"]
    elif target == "artifact_or_creature":
        constraints["card_types"] = ["artifact", "creature"]
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


def recursion_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^return target permanent card from your graveyard to the battlefield\.?$",
            {"target": "permanent", "count": 1},
        ),
        (
            r"^return target artifact card from your graveyard to the battlefield\.?$",
            {"target": "artifact", "count": 1},
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
            "enters_tapped": bool(match.groupdict().get("tapped")),
        }
        if match.groupdict().get("mana_value_max"):
            result["mana_value_max"] = int(match.group("mana_value_max"))
        return result
    return None


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


def graveyard_to_library_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
    patterns: list[tuple[str, dict[str, Any]]] = [
        (
            r"^put target card from your graveyard on top of your library\.?$",
            {"target": "any_card", "count": 1, "destination": "library_top", "up_to_count": False},
        ),
        (
            r"^put target card from your graveyard on the bottom of your library\.?$",
            {"target": "any_card", "count": 1, "destination": "library_bottom", "up_to_count": False},
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
            return dict(result)
    return None


def graveyard_to_library_from_source(source_text: str) -> dict[str, Any] | str:
    text = str(source_text or "")
    effect_matches = re.findall(r"new\s+PutOnLibraryTargetEffect\s*\(\s*(true|false)\s*\)", text)
    if len(effect_matches) != 1:
        return "graveyard_to_library_source_not_single_effect"
    destination = "library_top" if effect_matches[0] == "true" else "library_bottom"
    if "TargetCardInYourGraveyard" not in text:
        return "graveyard_to_library_source_target_not_supported"
    if "TargetCardInGraveyard" in text and "TargetCardInYourGraveyard" not in text:
        return "graveyard_to_library_source_target_not_supported"
    if "EachTargetPointer" in text or ".setTargetPointer" in text:
        return "graveyard_to_library_source_target_not_supported"
    if "FILTER_CARD_CREATURES_YOUR_GRAVEYARD" in text or "FILTER_CARD_CREATURE_YOUR_GRAVEYARD" in text:
        target = "creature"
    elif re.search(r"TargetCardInYourGraveyard\s*\(\s*\)", text):
        target = "any_card"
    else:
        return "graveyard_to_library_source_target_not_supported"
    count = 1
    up_to = False
    count_match = re.search(r"TargetCardInYourGraveyard\s*\(\s*0\s*,\s*(\d+)\s*,", text, re.S)
    if count_match:
        count = int(count_match.group(1))
        up_to = True
    return {
        "target": target,
        "count": count,
        "destination": destination,
        "up_to_count": up_to,
    }


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
    text = strip_leading_parenthetical_reminders(oracle_text(metadata))
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


def is_permanent_activated_recursion_to_hand_unit(row: dict[str, Any]) -> bool:
    if str(row.get("adapter_work_unit") or "") != RECURSION_UNIT:
        return False
    return (
        effect_classes(row) == {"ReturnFromGraveyardToHandTargetEffect"}
        and ability_classes(row) == {"SimpleActivatedAbility"}
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
        "blue_or_black_flying_creature",
        "creature_power_4_or_greater",
        "creature_mana_value_3_or_greater",
    }:
        return "creature"
    if target == "black_or_red_permanent":
        return "permanent"
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
        (r"target nonblack creature", "nonblack_creature"),
        (r"target blue or black creature with flying", "blue_or_black_flying_creature"),
        (r"target black or red permanent", "black_or_red_permanent"),
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
        "FILTER_PERMANENT_CREATURE_NON_BLACK" in text
        or "FILTER_CREATURE_NON_BLACK" in text
        or 'FilterCreaturePermanent("nonblack creature")' in text
    ):
        return "nonblack_creature"
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


def activated_recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> tuple[str, int, bool] | None:
    text = re.sub(r"\s+", " ", oracle_text(metadata)).strip().lower()
    if text.count(":") != 1:
        return None
    return recursion_to_hand_from_text(text.rsplit(":", 1)[1].strip())


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
        r"(?P<cost>(?:\{[0-9wubrg]\})+): return this card from your graveyard to your hand\.?",
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
    }


def graveyard_self_return_to_battlefield_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | str:
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip().lower()
    match = re.fullmatch(
        r"(?P<cost>(?:\{[0-9wubrg]\})+): return this card from your graveyard to the battlefield(?P<tapped> tapped)?\.?",
        text,
    )
    if not match:
        return "graveyard_self_return_battlefield_oracle_not_simple"
    cost_text = canonical_mana_cost_text(match.group("cost"))
    parsed_cost = parse_mana_cost_text(cost_text)
    if parsed_cost is None:
        return "graveyard_self_return_battlefield_oracle_mana_cost_not_supported"
    activation_cost_generic, activation_cost_colors = parsed_cost
    return {
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "enters_tapped": bool(match.group("tapped")),
    }


def graveyard_self_return_to_hand_from_source(source: str) -> dict[str, Any] | str:
    text = source or ""
    effect_matches = list(re.finditer(r"new\s+ReturnSourceFromGraveyardToHandEffect\s*\(", text))
    if len(effect_matches) != 1:
        return "graveyard_self_return_source_not_single_effect"
    effect_index = effect_matches[0].start()
    ability_index = text.rfind("new SimpleActivatedAbility", 0, effect_index)
    if ability_index < 0:
        return "graveyard_self_return_source_not_simple_activated"
    window = text[ability_index : effect_index + 1400]
    if "Zone.GRAVEYARD" not in window:
        return "graveyard_self_return_source_not_graveyard_zone"
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
        "ReturnToHandTargetCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapSourceCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "graveyard_self_return_source_cost_not_supported"
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
    if not re.search(r"ReturnSourceFromGraveyardToBattlefieldEffect\s*\(\s*true\b", window):
        return "graveyard_self_return_battlefield_source_tapped_mismatch"
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
        "ReturnToHandTargetCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
        "TapSourceCost",
        "TapTargetCost",
        "UntapSourceCost",
    }
    present_risky = sorted(cost for cost in risky_cost_classes if cost in window)
    if present_risky:
        return "graveyard_self_return_battlefield_source_cost_not_supported"
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
        "enters_tapped": True,
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
        "PayLifeCost",
        "RemoveCounterCost",
        "ReturnToHandSourceCost",
        "RevealTargetFromHandCost",
        "SacrificeTargetCost",
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
    text = re.sub(r"\s+", " ", oracle_text_after_leading_static_keywords(metadata)).strip().lower()
    if text.count(":") != 1:
        return "activated_target_keyword_oracle_not_simple"
    cost_text, effect_text = [part.strip() for part in text.split(":", 1)]
    keyword_words = "|".join(
        re.escape(word)
        for word in sorted(TARGET_GRANT_KEYWORD_ORACLE_WORDS, key=len, reverse=True)
    )
    match = re.match(
        rf"^(another )?target creature( you control)? gains ({keyword_words}) until end of turn\.?$",
        effect_text,
    )
    if not match:
        return "activated_target_keyword_oracle_not_simple"
    if match.group(1) and not match.group(2):
        return "activated_target_keyword_oracle_not_simple"
    activation = activation_cost_from_oracle_prefix(cost_text)
    if isinstance(activation, str):
        return str(activation).replace("activated_self_boost", "activated_target_keyword")
    return {
        "keyword": TARGET_GRANT_KEYWORD_ORACLE_WORDS[match.group(3)],
        "target": "creature",
        "target_controller": "self" if match.group(2) else "any",
        "exclude_source": bool(match.group(1)),
        **activation,
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
        return {"target": "creature", "target_controller": "any", "exclude_source": False}
    if re.search(r"new\s+TargetControlledCreaturePermanent\s*\(\s*\)", text, re.S):
        return {"target": "creature", "target_controller": "self", "exclude_source": False}
    if "FILTER_ANOTHER_TARGET_CREATURE_YOU_CONTROL" in text:
        return {"target": "creature", "target_controller": "self", "exclude_source": True}
    if re.search(r"FILTER_CONTROLLED_CREATURE|FILTER_TARGET_CREATURE_YOU_CONTROL", text, re.S):
        return {"target": "creature", "target_controller": "self", "exclude_source": False}
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
    match = re.match(
        r"^(?:it|this (?:artifact|creature|enchantment)|[^.]+?) deals (\d+) damage to "
        r"(any target|target creature)\.?$",
        effect_text,
    )
    if not match:
        return None
    target_map = {
        "any target": "any_target",
        "target creature": "creature",
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
    if "new TargetAnyTarget(" in text:
        target = "any_target"
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
    risky_cost_classes = {
        "DiscardCardCost",
        "DiscardTargetCost",
        "ExileFrom",
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
        return "activated_draw_source_not_battlefield"
    present_risky = sorted(cost for cost in risky_cost_classes if cost in text)
    if present_risky:
        return "activated_draw_source_cost_not_supported"
    draw_matches = re.findall(r"DrawCardSourceControllerEffect\s*\(\s*(\d*)\s*\)", text)
    if len(draw_matches) != 1:
        return "activated_draw_source_count_not_fixed"
    count = int(draw_matches[0] or "1")
    if count <= 0:
        return "activated_draw_source_count_not_fixed"
    draw_index = text.find("DrawCardSourceControllerEffect")
    window = text[max(0, draw_index - 300) : draw_index + 1400]
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
    return {
        "count": count,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": requires_tap,
        "activation_requires_sacrifice": requires_sacrifice,
    }


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
    return {
        "target": target,
        "count": count,
        "up_to": up_to,
        "activation_cost_mana": cost_text,
        "activation_cost_generic": activation_cost_generic,
        "activation_cost_colors": activation_cost_colors,
        "activation_requires_tap": "TapSourceCost" in window,
        "activation_requires_sacrifice": "SacrificeSourceCost" in window,
    }


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
    if normalized == "one":
        return 1
    if normalized == "two":
        return 2
    if normalized.isdigit():
        return int(normalized)
    return None


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


def dies_recursion_to_hand_from_oracle(metadata: dict[str, Any]) -> dict[str, Any] | None:
    text = oracle_text(metadata)
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
    if target == "blue_or_black_flying_creature":
        return {"card_types": ["creature"], "target_colors": ["U", "B"], "required_keywords": ["flying"]}
    if target == "black_or_red_permanent":
        return {"card_types": ["permanent"], "target_colors": ["B", "R"]}
    if target == "creature_power_4_or_greater":
        return {"card_types": ["creature"], "power_min": 4}
    if target == "creature_mana_value_3_or_greater":
        return {"card_types": ["creature"], "mana_value_min": 3}
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
    if target == "artifact_or_creature":
        return {"card_types": ["artifact", "creature"]}
    if target == "creature_or_enchantment":
        return {"card_types": ["creature", "enchantment"]}
    if target == "creature_enchantment_or_planeswalker":
        return {"card_types": ["creature", "enchantment", "planeswalker"]}
    return {"target": target}


def proposal_notes(row: dict[str, Any], scope: str) -> str:
    scope_kind = "instant/sorcery spell"
    if str(row.get("adapter_work_unit") or "") in RAMP_UNITS:
        scope_kind = "activated mana-source permanent"
    elif scope == TOKEN_SPELL_SCOPE:
        scope_kind = "fixed spell-resolution creature-token maker"
    elif scope == DAMAGE_GAIN_LIFE_SCOPE:
        scope_kind = "fixed damage plus controller life-gain spell"
    elif scope == DESTROY_GAIN_LIFE_SCOPE:
        scope_kind = "fixed destroy-target plus controller life-gain spell"
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
    elif scope in {
        ETB_LIFE_GAIN_CREATURE_SCOPE,
        ETB_DRAW_CREATURE_SCOPE,
        ETB_DAMAGE_CREATURE_SCOPE,
        ETB_DESTROY_CREATURE_SCOPE,
        ETB_RECURSION_CREATURE_SCOPE,
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
    elif scope == PERMANENT_ACTIVATED_LIFE_GAIN_SCOPE:
        scope_kind = "permanent with a simple activated fixed life-gain ability"
    elif scope == PERMANENT_ACTIVATED_GRAVEYARD_EXILE_SCOPE:
        scope_kind = "permanent with a simple activated graveyard-exile ability"
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
    dies_recursion_creature_unit = is_creature_dies_recursion_unit(row)
    etb_damage_creature_unit = is_creature_etb_damage_unit(row)
    etb_destroy_creature_unit = is_creature_etb_destroy_unit(row)
    etb_recursion_creature_unit = is_creature_etb_recursion_unit(row)
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
    permanent_activated_recursion_to_hand_unit = is_permanent_activated_recursion_to_hand_unit(row)
    permanent_activated_graveyard_exile_unit = is_permanent_activated_graveyard_exile_unit(row)
    graveyard_self_return_to_hand_unit = (
        unit == RECURSION_UNIT
        and effect_classes(row) == {"ReturnSourceFromGraveyardToHandEffect"}
        and "SimpleActivatedAbility" in ability_classes(row)
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
        and not dies_recursion_creature_unit
        and not etb_damage_creature_unit
        and not etb_destroy_creature_unit
        and not etb_recursion_creature_unit
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
        and not permanent_activated_recursion_to_hand_unit
        and not permanent_activated_graveyard_exile_unit
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
        and not dies_recursion_creature_unit
        and not etb_damage_creature_unit
        and not etb_destroy_creature_unit
        and not etb_recursion_creature_unit
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
        and not permanent_activated_recursion_to_hand_unit
        and not permanent_activated_graveyard_exile_unit
        and not graveyard_self_return_unit
    ):
        if not is_spell(metadata):
            return None, "not_instant_or_sorcery_spell"
        if ability_kind(row) != "one_shot":
            return None, "not_one_shot_spell_ability"
        if has_additional_cost(source_text) or "additional cost" in oracle_text(metadata):
            return None, "additional_cost_detected"

    flags = spell_flags(metadata)
    classes = effect_classes(row)

    if permanent_activated_draw_unit:
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "activated_draw_not_permanent"
        oracle_count = activated_draw_count_from_oracle(metadata)
        if oracle_count is None:
            return None, "activated_draw_oracle_not_simple"
        parsed_activation = activated_draw_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        if int(parsed_activation["count"]) != int(oracle_count):
            return None, "activated_draw_source_oracle_mismatch"
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
        for key in ("keyword", "target", "target_controller", "exclude_source"):
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
        target_constraints = {"card_types": ["creature"]}
        if bool(oracle_keyword.get("exclude_source")):
            target_constraints["exclude_source"] = True
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
            "target": "creature",
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
            "target": "creature",
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
        oracle_target = activated_recursion_to_hand_from_oracle(metadata)
        if oracle_target is None:
            return None, "activated_recursion_oracle_not_simple"
        parsed_activation = activated_recursion_to_hand_from_source(source_text)
        if isinstance(parsed_activation, str):
            return None, parsed_activation
        oracle_target_type, oracle_count, oracle_up_to = oracle_target
        if str(parsed_activation["target"]) != str(oracle_target_type):
            return None, "activated_recursion_source_oracle_target_mismatch"
        if int(parsed_activation["count"]) != int(oracle_count):
            return None, "activated_recursion_source_oracle_count_mismatch"
        if bool(parsed_activation["up_to"]) != bool(oracle_up_to):
            return None, "activated_recursion_source_oracle_count_mismatch"
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
                )
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
                )
            },
            "graveyard_to_hand_activation_cost_mana": parsed_activation["activation_cost_mana"],
            "graveyard_to_hand_activation_cost_generic": parsed_activation["activation_cost_generic"],
            "graveyard_to_hand_activation_cost_colors": parsed_activation["activation_cost_colors"],
            "graveyard_to_hand_activation_requires_tap": parsed_activation["activation_requires_tap"],
            "graveyard_to_hand_activation_requires_sacrifice": parsed_activation["activation_requires_sacrifice"],
        }
        if oracle_up_to:
            activated_effect["up_to_count"] = True
            activated_effect["graveyard_to_hand_up_to_count"] = True
            effect_json["up_to_count"] = True
            effect_json["graveyard_to_hand_up_to_count"] = True
        if parsed_activation.get("activation_requires_sacrifice"):
            effect_json["activated_self_sacrifice_recursion"] = True
            activated_effect["activated_self_sacrifice_recursion"] = True
        return build_proposal(
            row,
            metadata,
            effect_json,
            family_id="xmage_permanent_simple_activated_graveyard_to_hand",
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
        allowed_abilities = {"SimpleActivatedAbility"} | set(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
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
        ):
            if source_activation[key] != oracle_activation[key]:
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
            "enters_tapped": True,
            "xmage_effect_class": "ReturnSourceFromGraveyardToBattlefieldEffect",
            "xmage_ability_class": "SimpleActivatedAbility",
        }
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
            {"SimpleActivatedAbility", "EntersBattlefieldTappedAbility"}
            | set(STATIC_SELF_KEYWORD_ABILITY_CLASSES)
        )
        if "SimpleActivatedAbility" not in abilities or abilities - allowed_abilities:
            return None, "graveyard_self_return_ability_class_not_simple"
        if not is_permanent_metadata(metadata) or is_spell(metadata):
            return None, "graveyard_self_return_not_permanent"
        oracle_activation = graveyard_self_return_to_hand_from_oracle(metadata)
        if isinstance(oracle_activation, str):
            return None, oracle_activation
        source_activation = graveyard_self_return_to_hand_from_source(source_text)
        if isinstance(source_activation, str):
            return None, source_activation
        for key in ("activation_cost_mana", "activation_cost_generic", "activation_cost_colors"):
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
            "xmage_ability_class": "SimpleActivatedAbility",
        }
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
        if classes == {"ReturnFromGraveyardToBattlefieldTargetEffect"}:
            if ability_classes(row):
                return None, "recursion_battlefield_ability_class_not_simple"
            if has_oracle_complexity(metadata):
                return None, "recursion_battlefield_oracle_not_simple"
            target = recursion_to_battlefield_from_oracle(metadata)
            if target is None:
                return None, "recursion_battlefield_target_not_supported"
            target_type = str(target["target"])
            count = int(target["count"])
            target_graveyard_controller = str(target.get("target_graveyard_controller") or "self")
            if not source_supports_battlefield_recursion_target(source_text, target_graveyard_controller):
                return None, "recursion_battlefield_source_target_not_supported"
            mana_value_max = target.get("mana_value_max")
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
            target = recursion_to_hand_exile_self_from_oracle(metadata)
            if target is None:
                return None, "recursion_exile_self_target_not_supported"
            target_type, count, up_to = target
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
            and not is_creature_etb_damage_unit(row)
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
            and not is_permanent_activated_recursion_to_hand_unit(row)
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
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, EntersBattlefieldTriggeredAbility, and exact fixed ETB damage Oracle text",
                "removal_destroy::targeted_destroy_variant_v1 rows with DestroyTargetEffect, EntersBattlefieldTriggeredAbility, and exact unrestricted ETB destroy Oracle text",
                "add_counters::targeted_add_counters_variant_v1 rows with AddCountersTargetEffect, EntersBattlefieldTriggeredAbility, exact one target creature Oracle text, and only static self keywords",
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, SimpleActivatedAbility, exact creature Oracle tap damage, and TapSourceCost only",
                "direct_damage::targeted_damage_variant_v1 rows with DamageTargetEffect, SimpleActivatedAbility, fixed activated damage, mana/tap/self-sacrifice source costs only, and simple any-target or creature targets",
                "removal_destroy::targeted_destroy_variant_v1 rows with DestroyTargetEffect, SimpleActivatedAbility, exact activated destroy-target Oracle text, and mana/tap/self-sacrifice source costs only",
                "life_gain::xmage_life_gain_variant_review_v1 rows with GainLifeEffect, SimpleActivatedAbility, exact fixed activated life-gain Oracle text, and mana/tap/source self-sacrifice costs only",
                "xmage_signature BoostControlledEffect one-shot spell rows with exact fixed controlled-creature boost until EOT and no color/modal/dynamic filters",
                "xmage_signature BoostSourceEffect + SimpleActivatedAbility rows with exact activated self boost until EOT and mana/tap source costs only",
                "xmage_signature BoostTargetEffect + SimpleActivatedAbility + TargetCreaturePermanent rows with exact activated target-creature boost until EOT and mana/tap source costs only",
                "xmage_signature BoostControlledEffect + SimpleStaticAbility rows with exact static controlled-creature power/toughness boosts and simple creature/artifact/subtype/legendary filters",
                "grant_protection_from_chosen_color rows with GainAbilityTargetEffect + SimpleActivatedAbility, exact activated target-creature keyword until EOT, and simple mana/tap source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, SimpleActivatedAbility, exact activated graveyard-to-hand Oracle text, and mana/tap/self-sacrifice source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ExileTargetEffect, SimpleActivatedAbility, exact activated graveyard-exile Oracle text, and mana/tap/self-sacrifice source costs only",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect + ExileSpellEffect, no extra ability class, exact fixed graveyard-to-hand Oracle text, and trailing self-exile text",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, no extra ability class, exact choose-one-or-both Oracle text, and two fixed graveyard-to-hand components",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with ReturnFromGraveyardToHandTargetEffect, no extra ability class, exact choose-one Oracle text, and two fixed alternative graveyard-to-hand components",
                "recursion::xmage_graveyard_return_variant_review_v1 rows with PutOnLibraryTargetEffect, no extra ability class, exact graveyard-to-library top/bottom Oracle text, and self-graveyard targets only",
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
