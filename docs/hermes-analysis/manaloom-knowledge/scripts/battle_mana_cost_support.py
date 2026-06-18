#!/usr/bin/env python3
"""Pure mana-cost helpers shared by the Hermes battle analyst."""

import re
from collections import defaultdict


MANA_SYMBOL_TO_POOL = {
    "W": "white",
    "U": "blue",
    "B": "black",
    "R": "red",
    "G": "green",
    "C": "colorless",
}


def parse_mana_cost(cost, fallback_cmc=0):
    """Parse a mana cost into generic, colored, and flexible hybrid symbols."""
    if isinstance(cost, (int, float)):
        return {
            "generic": int(cost),
            "colored": defaultdict(int),
            "hybrid": [],
            "phyrexian": [],
        }
    if not cost:
        return {
            "generic": int(float(fallback_cmc or 0)),
            "colored": defaultdict(int),
            "hybrid": [],
            "phyrexian": [],
        }

    parsed = {
        "generic": 0,
        "colored": defaultdict(int),
        "hybrid": [],
        "monocolored_hybrid": [],
        "phyrexian": [],
        "phyrexian_hybrid": [],
    }
    for raw_symbol in re.findall(r"\{([^}]+)\}", str(cost).upper()):
        symbol = raw_symbol.strip()
        if symbol.isdigit():
            parsed["generic"] += int(symbol)
        elif symbol in ("X", "Y", "Z"):
            continue
        elif symbol in MANA_SYMBOL_TO_POOL:
            parsed["colored"][MANA_SYMBOL_TO_POOL[symbol]] += 1
        elif "/" in symbol:
            parts = symbol.split("/")
            options = [MANA_SYMBOL_TO_POOL[part] for part in parts if part in MANA_SYMBOL_TO_POOL]
            if "P" in parts and len(options) > 1:
                parsed["phyrexian_hybrid"].append(options)
            elif "P" in parts and options:
                parsed["phyrexian"].append(options[0])
            elif any(part.isdigit() for part in parts) and options:
                parsed["monocolored_hybrid"].append(
                    {
                        "color": options[0],
                        "generic": max(
                            int(part) for part in parts if part.isdigit()
                        ),
                    }
                )
            elif options:
                parsed["hybrid"].append(options)
            elif any(part.isdigit() for part in parts):
                parsed["generic"] += 1
        else:
            parsed["generic"] += 1
    return parsed


def merge_mana_costs(base, addition):
    base["generic"] += int(addition.get("generic", 0) or 0)
    for color, amount in addition.get("colored", {}).items():
        base["colored"][color] += amount
    base["hybrid"].extend(addition.get("hybrid", []))
    base.setdefault("monocolored_hybrid", []).extend(
        addition.get("monocolored_hybrid", [])
    )
    base.setdefault("phyrexian", []).extend(addition.get("phyrexian", []))
    base.setdefault("phyrexian_hybrid", []).extend(
        addition.get("phyrexian_hybrid", [])
    )
    return base


def variable_mana_symbol_count(cost):
    return sum(
        1
        for raw_symbol in re.findall(r"\{([^}]+)\}", str(cost or "").upper())
        if raw_symbol.strip() in ("X", "Y", "Z")
    )


def card_spend_tags(card):
    """Return coarse tags used by restricted mana checks.

    This intentionally models only spell-category restrictions, not arbitrary
    card text. Card-specific restrictions still need explicit handlers.
    """
    type_line = str(card.get("type_line") or card.get("type") or "").lower()
    effect = str(card.get("effect") or "").lower()
    tag = str(card.get("tag") or "").lower()
    tags = set()

    is_creature = (
        "creature" in type_line
        or effect == "creature"
        or tag == "creature"
        or bool(card.get("is_creature_permanent"))
    )
    is_artifact = "artifact" in type_line or effect in ("artifact", "ramp_permanent")
    is_instant = "instant" in type_line or bool(card.get("instant"))
    is_sorcery = "sorcery" in type_line or tag == "sorcery"

    if is_creature:
        tags.add("creature_spell")
    else:
        tags.add("noncreature_spell")
    if is_artifact:
        tags.add("artifact_spell")
    if is_instant or is_sorcery:
        tags.add("instant_or_sorcery_spell")
    return sorted(tags)


def card_mana_cost(
    card,
    additional_generic=0,
    *,
    alternative_cost=None,
    x_value=0,
    additional_costs=None,
):
    cost_source = card.get("mana_cost") if alternative_cost is None else alternative_cost
    fallback_cmc = card.get("cmc", 0) if alternative_cost is None else 0
    parsed = parse_mana_cost(cost_source, fallback_cmc)
    parsed["spend_tags"] = card_spend_tags(card)
    parsed["generic"] += max(0, int(x_value or 0)) * variable_mana_symbol_count(cost_source)
    parsed["generic"] += additional_generic
    for extra_cost in additional_costs or []:
        merge_mana_costs(parsed, parse_mana_cost(extra_cost, 0))
    return parsed


def replay_cost_snapshot(cost):
    if not isinstance(cost, dict):
        return cost
    return {
        "generic": cost.get("generic", 0),
        "colored": dict(cost.get("colored", {})),
        "hybrid": [list(options) for options in cost.get("hybrid", [])],
        "monocolored_hybrid": [
            dict(option) for option in cost.get("monocolored_hybrid", [])
        ],
        "phyrexian": list(cost.get("phyrexian", [])),
        "phyrexian_hybrid": [
            list(options) for options in cost.get("phyrexian_hybrid", [])
        ],
        "spend_tags": list(cost.get("spend_tags", [])),
    }
