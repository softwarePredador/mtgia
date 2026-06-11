#!/usr/bin/env python3
"""Pure card-characteristics helpers for the Hermes battle analyst."""

import copy
import json
import re

from battle_mana_cost_support import MANA_SYMBOL_TO_POOL


def read_json_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(value)
    except Exception:
        return []
    if isinstance(decoded, list):
        return decoded
    return []


def get_card_characteristics(card, zone, cast_mode=None):
    """Return characteristics for zone-specific complex card modes."""
    if not isinstance(card, dict):
        return card
    if card.get("is_dfc") or card.get("front_face") or card.get("back_face"):
        front = copy.deepcopy(card.get("front_face") or card)
        back = copy.deepcopy(card.get("back_face") or {})
        if zone in ("stack", "battlefield") and card.get("is_transformed") and back:
            return back
        return front
    if cast_mode == "adventure" and card.get("adventure"):
        result = copy.deepcopy(card["adventure"])
        result.setdefault("parent_name", card.get("name"))
        result["cast_mode"] = "adventure"
        return result
    if cast_mode == "omen" and card.get("omen"):
        result = copy.deepcopy(card["omen"])
        result.setdefault("parent_name", card.get("name"))
        result["cast_mode"] = "omen"
        return result
    if cast_mode == "prepare" and card.get("prepare"):
        result = copy.deepcopy(card["prepare"])
        result.setdefault("parent_name", card.get("name"))
        result["cast_mode"] = "prepare"
        return result
    if cast_mode == "prototype" and card.get("prototype"):
        result = copy.deepcopy(card["prototype"])
        result.setdefault("parent_name", card.get("name"))
        result["cast_mode"] = "prototype"
        return result
    if card.get("is_split") or (card.get("half_a") and card.get("half_b")):
        if zone == "stack":
            chosen_half = card.get("chosen_half", "half_a")
            result = copy.deepcopy(card.get(chosen_half) or card.get("half_a") or {})
            result["cast_mode"] = chosen_half
            return result
        half_a = card.get("half_a") or {}
        half_b = card.get("half_b") or {}
        colors = list(dict.fromkeys(list(half_a.get("colors") or []) + list(half_b.get("colors") or [])))
        return {
            "name": card.get("name", f"{half_a.get('name', '')} // {half_b.get('name', '')}".strip()),
            "cmc": int(half_a.get("cmc", 0) or 0) + int(half_b.get("cmc", 0) or 0),
            "colors": colors,
            "type_line": card.get("type_line", ""),
        }
    return copy.deepcopy(card)


def is_adventure_card(card):
    return isinstance(card, dict) and isinstance(card.get("adventure"), dict)


def adventure_spell_card(card):
    """Return the Adventure spell face while keeping a reference to the parent card."""
    spell = get_card_characteristics(card, "stack", cast_mode="adventure")
    spell["_adventure_parent"] = copy.deepcopy(card)
    spell["_adventure_cast"] = True
    return spell


def _color_identity_values_from_part(part):
    colors = []
    for key in ("color_identity", "colors"):
        raw = part.get(key) if isinstance(part, dict) else None
        if isinstance(raw, str):
            raw = re.findall(r"[WUBRGC]", raw.upper()) or [raw]
        for color in raw or []:
            mapped = MANA_SYMBOL_TO_POOL.get(str(color).upper(), str(color).lower())
            if mapped in ("white", "blue", "black", "red", "green"):
                colors.append(mapped)
    mana_cost = str(part.get("mana_cost", "") if isinstance(part, dict) else "").upper()
    for raw_symbol in re.findall(r"\{([^}]+)\}", mana_cost):
        for symbol_part in raw_symbol.split("/"):
            mapped = MANA_SYMBOL_TO_POOL.get(symbol_part.strip())
            if mapped in ("white", "blue", "black", "red", "green"):
                colors.append(mapped)
    return colors


def compute_color_identity(card):
    """Color identity includes all faces/parts relevant to Commander legality."""
    if not isinstance(card, dict):
        return []
    parts = [card]
    for key in (
        "front_face",
        "back_face",
        "adventure",
        "omen",
        "prepare",
        "prototype",
        "half_a",
        "half_b",
    ):
        if isinstance(card.get(key), dict):
            parts.append(card[key])
    ordered = ["white", "blue", "black", "red", "green"]
    seen = set()
    for part in parts:
        seen.update(_color_identity_values_from_part(part))
    return [color for color in ordered if color in seen]


def card_has_color(card, symbol):
    values = card.get("color_identity") or card.get("colors") or []
    if isinstance(values, str):
        decoded = read_json_list(values)
        values = decoded or re.findall(r"[WUBRGC]", values.upper())
    return str(symbol).upper() in {str(value).upper() for value in values}


def is_creature_card(card):
    if not isinstance(card, dict):
        return False
    return "creature" in str(card.get("type_line") or "").lower()


def has_power_toughness_box(card):
    """Return true when a card has printed power/toughness boxes."""
    if not isinstance(card, dict):
        return False
    for key in ("power", "toughness"):
        value = card.get(key)
        if value is None:
            return False
        if isinstance(value, str) and not value.strip():
            return False
    return True


def is_vehicle_or_spacecraft_card(card):
    type_line = str(card.get("type_line", "") if isinstance(card, dict) else "").lower()
    return "vehicle" in type_line or "spacecraft" in type_line


def is_commander_eligible_card(card):
    """Small 2026 Commander eligibility helper for the battle engine."""
    if not isinstance(card, dict):
        return False
    type_line = str(card.get("type_line", "")).lower()
    oracle = str(card.get("oracle_text", "") or "").lower()
    is_legendary = "legendary" in type_line
    if is_legendary and "creature" in type_line:
        return True
    if "can be your commander" in oracle:
        return True
    if is_legendary and is_vehicle_or_spacecraft_card(card) and has_power_toughness_box(card):
        return True
    return False
