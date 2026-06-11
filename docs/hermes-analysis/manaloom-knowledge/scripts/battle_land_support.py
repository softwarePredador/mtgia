#!/usr/bin/env python3
"""Land and mana-source helpers for the Hermes battle analyst."""

import re

from battle_mana_cost_support import MANA_SYMBOL_TO_POOL


BASIC_LAND_COLORS = {
    "Plains": "white",
    "Island": "blue",
    "Swamp": "black",
    "Mountain": "red",
    "Forest": "green",
    "Wastes": "colorless",
    "Ancient Den": "white",
    "Seat of the Synod": "blue",
    "Vault of Whispers": "black",
    "Great Furnace": "red",
    "Tree of Tales": "green",
}


KNOWN_LAND_NAMES = {
    name
    for name in (
        "plains",
        "island",
        "swamp",
        "mountain",
        "forest",
        "wastes",
        "high market",
        "tropical island",
        "tundra",
        "otawara, soaring city",
        "dryad arbor",
        "gaea's cradle",
        "havenwood battleground",
        "mishra's factory",
        "ancient tomb",
        "command tower",
        "exotic orchard",
        "fabled passage",
        "field of the dead",
        "reflecting pool",
        "reliquary tower",
        "strip mine",
        "wasteland",
        "wooded foothills",
        "windswept heath",
        "arid mesa",
        "scalding tarn",
        "misty rainforest",
        "verdant catacombs",
        "marsh flats",
        "polluted delta",
        "bloodstained mire",
        "flooded strand",
        "prismatic vista",
    )
}


def normalize_card_name(name):
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def source_colors(source):
    """Return pool colors a source can produce; unknown legacy sources are generic."""
    if source == "land":
        return ["generic"]
    if not isinstance(source, dict):
        return ["generic"]
    explicit = (
        source.get("produces")
        or source.get("produced_mana")
        or source.get("color_identity")
    )
    if isinstance(explicit, str):
        explicit = re.findall(r"[WUBRGC]", explicit.upper())
    if explicit:
        colors = [
            MANA_SYMBOL_TO_POOL.get(str(color).upper(), str(color).lower())
            for color in explicit
        ]
        valid = [color for color in colors if color in set(MANA_SYMBOL_TO_POOL.values())]
        return ["wildcard"] if len(valid) > 1 else (valid or ["generic"])
    basic_color = BASIC_LAND_COLORS.get(source.get("name", ""))
    return [basic_color] if basic_color else ["generic"]


def is_land(card):
    """Reliable land detection for PG-imported cards."""
    if not isinstance(card, dict):
        return card == "land" or str(card) == "land"
    if card.get("effect") == "land":
        return True
    if card.get("tag") == "land":
        return True
    if card.get("role") == "land":
        return True
    if "Land" in card.get("type_line", ""):
        return True
    name = card.get("name", "")
    if name in ("Plains", "Island", "Swamp", "Mountain", "Forest", "Wastes"):
        return True
    if normalize_card_name(name) in KNOWN_LAND_NAMES:
        return True
    return False
