#!/usr/bin/env python3
"""Build reviewed rules for the Commander-legal Unfinity sticker family."""

from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_REGISTRY = SCRIPT_DIR / "unfinity_sticker_card_registry.json"
DEFAULT_RULES = SCRIPT_DIR / "reviewed_battle_card_rules.json"

CARD_NAMES = (
    "Aerialephant",
    "A Good Day to Pie",
    "Ambassador Blorpityblorpboop",
    "Baaallerina",
    "_____ Balls of Fire",
    "Big Winner",
    "Bioluminary",
    "_____ Bird Gets the Worm",
    "Carnival Carnivore",
    "Chicken Troupe",
    "Clandestine Chameleon",
    "Command Performance",
    "Croakid Amphibonaut",
    "Done for the Day",
    "Fight the _____ Fight",
    "Finishing Move",
    "Glitterflitter",
    "________ Goblin",
    "Goblin Airbrusher",
    "Grabby Tabby",
    "Last Voyage of the _____",
    "Lineprancers",
    "Make a _____ Splash",
    "Minotaur de Force",
    "_____-o-saurus",
    "Park Bleater",
    "Pin Collection",
    "Prize Wall",
    "Proficient Pyrodancer",
    "Robo-Piñata",
    "_____ _____ Rocketship",
    "Roxi, Publicist to the Stars",
    "Sanguine Sipper",
    "Scampire",
    "Scared Stiff",
    "Stiltstrider",
    "Sword-Swallowing Seraph",
    "Ticketomaton",
    "_____ _____ _____ Trespasser",
    "Tusk and Whiskers",
    "Unlawful Entry",
    "Wee Champion",
    "Wicker Picker",
    "Wizards of the _____",
    "Wolf in _____ Clothing",
)

ETB_TICKET_STICKER = {
    "Aerialephant": 1,
    "Ambassador Blorpityblorpboop": 3,
    "Carnival Carnivore": 1,
    "Chicken Troupe": 1,
    "Clandestine Chameleon": 2,
    "Glitterflitter": 1,
    "Minotaur de Force": 1,
    "Stiltstrider": 2,
    "Ticketomaton": 1,
}

ETB_NAME_STICKER = {
    "Baaallerina": {"target": "nonland_permanent"},
    "_____ Balls of Fire": {"target": "self", "metric": "letter_o"},
    "_____ Bird Gets the Worm": {
        "target": "self",
        "metric": "unique_vowels",
        "after": "gain_life_metric",
    },
    "Fight the _____ Fight": {
        "target": "self",
        "metric": "length_at_least_8",
        "fight": True,
    },
    "________ Goblin": {
        "target": "self",
        "metric": "unique_vowels",
        "after": "add_red_mana_metric",
    },
    "Last Voyage of the _____": {
        "target": "self",
        "metric": "length_at_most_7",
        "reanimate": True,
    },
    "Make a _____ Splash": {"target": "self", "metric": "letter_u"},
    "_____-o-saurus": {
        "target": "self",
        "metric": "unique_vowels",
        "after": "add_plus_one_counters_metric",
    },
    "_____ _____ Rocketship": {"target": "self", "count": 2},
    "_____ _____ _____ Trespasser": {"target": "self"},
    "Wizards of the _____": {
        "target": "self",
        "metric": "unique_vowels",
        "after": "draw_one_if_metric",
    },
    "Wolf in _____ Clothing": {
        "target": "self",
        "metric": "unique_vowels",
        "after": "opponent_creatures_minus_one_metric",
    },
}

CONDITIONAL_STICKERED_KEYWORDS = {
    "Big Winner": "trample",
    "Croakid Amphibonaut": "flying",
    "Grabby Tabby": "vigilance",
    "Sanguine Sipper": "lifelink",
    "Scared Stiff": "menace",
}

ACTIVATED_ABILITIES = {
    "Baaallerina": [
        {
            "effect": "grant_keyword_to_stickered",
            "mana_cost": "{2}{U}",
            "required_sticker_kind": "name",
            "keyword": "flying",
            "priority": 4,
        }
    ],
    "Lineprancers": [
        {"effect": "force_block_pt_stickered", "mana_cost": "{3}{G}", "priority": 3}
    ],
    "Park Bleater": [
        {
            "effect": "place_sticker",
            "mana_cost": "{W}",
            "requires_tap": True,
            "target": "creature_entered_this_turn",
            "target_kind": "creature",
            "priority": 5,
        }
    ],
    "Prize Wall": [
        {
            "effect": "place_sticker",
            "mana_cost": "{4}{U}",
            "requires_tap": True,
            "target_kind": "nonland_permanent",
            "priority": 8,
        },
        {
            "effect": "gain_ticket",
            "mana_cost": "{U}",
            "requires_tap": True,
            "count": 1,
            "priority": 2,
        },
    ],
    "Proficient Pyrodancer": [
        {
            "effect": "pump_art_stickered",
            "mana_cost": "{2}{R}",
            "power_bonus": 2,
            "keyword": "menace",
            "priority": 5,
        }
    ],
    "Scampire": [
        {
            "effect": "reanimate_stickered_graveyard",
            "mana_cost": "{3}{B}",
            "priority": 9,
        }
    ],
    "Sword-Swallowing Seraph": [
        {
            "effect": "add_counter_to_name_stickered",
            "mana_cost": "{1}{W}",
            "requires_tap": True,
            "count": 1,
            "priority": 5,
        }
    ],
    "_____ _____ _____ Trespasser": [
        {
            "effect": "self_name_sticker_pump_unblockable",
            "mana_cost": "{3}{U}",
            "priority": 6,
        }
    ],
    "Tusk and Whiskers": [
        {
            "effect": "place_sticker",
            "mana_cost": "{2}{G}{W}",
            "requires_tap": True,
            "ticket_count": 1,
            "target_kind": "nonland_permanent",
            "priority": 8,
        }
    ],
}

SPECIAL_FIELDS: dict[str, dict[str, Any]] = {
    "A Good Day to Pie": {
        "return_from_graveyard_on_sticker_kind": "name",
        "unfinity_spell_modes": [{"effect": "tap_opponent_creatures", "count": 2}],
    },
    "Ambassador Blorpityblorpboop": {"base_pt_from_controlled_pt_stickers": True},
    "_____ Balls of Fire": {
        "sticker_placement_trigger_kind": "any",
        "sticker_placement_trigger_source_only": True,
        "sticker_placement_trigger_effect": "damage_any_target_from_name_metric",
        "sticker_trigger_metric": "letter_o",
    },
    "Bioluminary": {"combat_damage_ticket_count": 2, "combat_damage_place_sticker": True},
    "Clandestine Chameleon": {"inherits_owned_ability_sticker_keywords": True},
    "Command Performance": {
        "unfinity_mode_count": 2,
        "choose_distinct_modes": True,
        "unfinity_spell_modes": [
            {"effect": "open_attraction"},
            {"effect": "visit_attractions"},
            {"effect": "get_tickets", "count": 2},
            {"effect": "place_sticker", "target": "nonland_permanent"},
        ],
    },
    "Done for the Day": {"end_step_employee_performer_robot": True},
    "Fight the _____ Fight": {
        "attached_name_sticker_toughness_per_match": 2,
        "attached_name_sticker_metric": "length_at_least_8",
    },
    "Finishing Move": {
        "unfinity_spell_modes": [
            {"effect": "get_tickets", "count": 2},
            {"effect": "place_sticker", "target": "nonland_permanent"},
            {"effect": "own_creature_damage_opponent_creature"},
        ]
    },
    "Goblin Airbrusher": {
        "sticker_placement_trigger_kind": "any",
        "sticker_placement_trigger_effect": "create_treasure",
        "sticker_treasure_count": 1,
        "art_sticker_treasure_count": 2,
    },
    "Last Voyage of the _____": {
        "attached_name_sticker_power_per_match": 2,
        "attached_name_sticker_metric": "length_at_most_7",
        "sacrifice_attached_creature_when_source_leaves": True,
    },
    "Lineprancers": {
        "etb_ticket_count": 2,
        "etb_sticker_count": 1,
        "etb_sticker_kind": "power_toughness",
        "etb_sticker_target": "creature",
    },
    "Make a _____ Splash": {
        "sticker_placement_trigger_kind": "any",
        "sticker_placement_trigger_source_only": True,
        "sticker_placement_trigger_effect": "tap_opponent_creatures_from_name_metric",
        "sticker_trigger_metric": "letter_u",
    },
    "Park Bleater": {"other_creature_enters_ticket_count": 1},
    "Pin Collection": {
        "effect": "equipment_static_attachment",
        "ability_kind": "static_equipment",
        "equipment": True,
        "etb_sticker_kind": "ability",
        "etb_sticker_target": "self",
        "etb_sticker_count": 1,
        "etb_sticker_without_paying": True,
        "etb_sticker_max_ticket_cost_source": "x_value",
        "power_boost": 1,
        "toughness_boost": 1,
        "equipment_inherits_ability_stickers": True,
        "equip_cost": "{2}",
    },
    "Proficient Pyrodancer": {
        "etb_sticker_kind": "art",
        "etb_sticker_target": "nonland_permanent",
        "etb_sticker_count": 1,
    },
    "Robo-Piñata": {"dies_choose_ticket_or_sticker": True, "dies_ticket_count": 2},
    "_____ _____ Rocketship": {"attack_name_sticker_letter_pump": True},
    "Roxi, Publicist to the Stars": {
        "etb_sticker_kind": "art",
        "etb_sticker_target": "nonland_permanent",
        "etb_sticker_count": 2,
        "power_from_art_stickered_public_cards": True,
    },
    "Scampire": {
        "etb_ticket_count": 1,
        "etb_sticker_kind": "any",
        "etb_sticker_target": "graveyard_creature",
        "etb_sticker_count": 1,
    },
    "Sword-Swallowing Seraph": {
        "etb_sticker_kind": "name",
        "etb_sticker_target": "nonland_permanent",
        "etb_sticker_count": 1,
    },
    "Tusk and Whiskers": {
        "sticker_placement_trigger_kind": "ability",
        "sticker_placement_trigger_effect": "add_counter_to_stickered_creature",
    },
    "Unlawful Entry": {
        "return_from_graveyard_on_sticker_kind": "art",
        "unfinity_spell_modes": [
            {"effect": "pump_flying", "power": 1, "keyword": "flying"}
        ],
    },
    "Wee Champion": {
        "sticker_placement_trigger_kind": "any",
        "sticker_placement_trigger_effect": "source_pump_or_counter",
    },
    "Wicker Picker": {
        "creature_spells_have_sticker_kicker": True,
        "sticker_kicker_cost": "{1}",
        "sticker_kicker_ticket_count": 1,
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--reviewed-rules", type=Path, default=DEFAULT_RULES)
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def normalize_name(value: str) -> str:
    return " ".join(str(value or "").strip().lower().split())


def logical_rule_key(card_name: str) -> str:
    identity = f"unfinity_sticker_card_runtime_v1:{normalize_name(card_name)}"
    return f"battle_rule_v1:{hashlib.md5(identity.encode('utf-8')).hexdigest()}"


def json_list(value: str | None) -> list[str]:
    try:
        decoded = json.loads(value or "[]")
    except json.JSONDecodeError:
        return []
    return [str(item) for item in decoded] if isinstance(decoded, list) else []


def load_cards(db_path: Path) -> dict[str, dict[str, Any]]:
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    try:
        rows = connection.execute(
            """
            SELECT normalized_name, name, mana_cost, type_line, oracle_text, cmc,
                   power, toughness, keywords_json, colors_json, card_id, scryfall_id
            FROM card_oracle_cache
            WHERE lower(name) IN ({})
            ORDER BY name, normalized_name
            """.format(",".join("?" for _ in CARD_NAMES)),
            [name.lower() for name in CARD_NAMES],
        ).fetchall()
    finally:
        connection.close()
    cards: dict[str, dict[str, Any]] = {}
    for row in rows:
        card = dict(row)
        card["keywords"] = json_list(card.pop("keywords_json"))
        card["colors"] = json_list(card.pop("colors_json"))
        cards[str(card["name"])] = card
    missing = sorted(set(CARD_NAMES) - set(cards))
    if missing:
        raise ValueError(f"missing Unfinity card metadata in Hermes: {missing}")
    return cards


def base_effect(card: dict[str, Any]) -> dict[str, Any]:
    type_line = str(card.get("type_line") or "")
    if "Creature" in type_line:
        effect = "creature"
    elif "Instant" in type_line or "Sorcery" in type_line:
        effect = "sticker_action"
    else:
        effect = "passive"
    payload = {
        "effect": effect,
        "ability_kind": "spell" if effect == "sticker_action" else "permanent",
        "unfinity_sticker_runtime": True,
        "battle_model_scope": "unfinity_ticket_sticker_family_runtime_v1",
        "oracle_runtime_scope": "card_oracle_clauses_mapped_with_executable_supplemental_selection_v1",
        "mana_cost": card.get("mana_cost") or "",
        "cmc": float(card.get("cmc") or 0),
        "type_line": type_line,
        "oracle_text": card.get("oracle_text") or "",
        "power": card.get("power"),
        "toughness": card.get("toughness"),
        "keywords": list(card.get("keywords") or []),
        "colors": list(card.get("colors") or []),
    }
    if effect == "sticker_action":
        payload["unfinity_sticker_spell"] = True
        payload["instant"] = "Instant" in type_line
        payload["sorcery"] = "Sorcery" in type_line
    return payload


def build_effect(card_name: str, card: dict[str, Any]) -> tuple[dict[str, Any], list[str]]:
    effect = base_effect(card)
    families = ["unfinity_ticket_sticker_core"]
    if card_name in ETB_TICKET_STICKER:
        effect.update(
            {
                "etb_ticket_count": ETB_TICKET_STICKER[card_name],
                "etb_sticker_count": 1,
                "etb_sticker_kind": "any",
                "etb_sticker_target": "nonland_permanent",
            }
        )
        families.append("ticket_then_sticker_etb")
    if card_name in ETB_NAME_STICKER:
        descriptor = ETB_NAME_STICKER[card_name]
        effect.update(
            {
                "etb_sticker_count": int(descriptor.get("count") or 1),
                "etb_sticker_kind": "name",
                "etb_sticker_target": descriptor.get("target") or "self",
                "etb_sticker_metric": descriptor.get("metric"),
            }
        )
        if descriptor.get("after"):
            effect["etb_after_sticker_effect"] = descriptor["after"]
            effect["etb_after_sticker_metric"] = descriptor.get("metric")
        if descriptor.get("fight"):
            effect["etb_name_sticker_fight"] = True
        if descriptor.get("reanimate"):
            effect["etb_reanimate_creature_attach_self"] = True
        families.append("name_sticker_etb_and_metric")
    if card_name in CONDITIONAL_STICKERED_KEYWORDS:
        effect["conditional_keyword_if_control_stickered"] = CONDITIONAL_STICKERED_KEYWORDS[card_name]
        families.append("stickered_permanent_static_keyword")
    if card_name in ACTIVATED_ABILITIES:
        effect["unfinity_activated_abilities"] = ACTIVATED_ABILITIES[card_name]
        families.append("sticker_activated_ability")
    if card_name in SPECIAL_FIELDS:
        effect.update(SPECIAL_FIELDS[card_name])
        families.append("sticker_card_specialized_descriptor")
    return effect, sorted(set(families))


def build(cards: dict[str, dict[str, Any]]) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    rules = {}
    family_counts: Counter[str] = Counter()
    registry_cards = {}
    for card_name in CARD_NAMES:
        card = cards[card_name]
        effect, families = build_effect(card_name, card)
        for family in families:
            family_counts[family] += 1
        oracle_text = str(card.get("oracle_text") or "")
        rules[card_name] = {
            "logical_rule_key": logical_rule_key(card_name),
            "effect_json": effect,
            "deck_role_json": {
                "category": "engine" if effect["effect"] != "sticker_action" else "interaction",
                "effect": effect["effect"],
                "subtype": "unfinity_ticket_sticker",
                "semantic_families": families,
            },
            "source": "curated",
            "confidence": 0.99,
            "review_status": "verified",
            "execution_status": "auto",
            "notes": "Oracle-reviewed Commander-legal Unfinity card executed by shared ticket/sticker family runtime.",
            "oracle_hash": hashlib.md5(oracle_text.encode("utf-8")).hexdigest(),
        }
        registry_cards[card_name] = {
            "card_id": card.get("card_id"),
            "scryfall_id": card.get("scryfall_id"),
            "logical_rule_key": rules[card_name]["logical_rule_key"],
            "oracle_hash": rules[card_name]["oracle_hash"],
            "families": families,
        }
    registry = {
        "schema_version": 1,
        "source": "PostgreSQL cards mirrored through Hermes card_oracle_cache",
        "mechanic_contract": "CR 123 stickers, CR 717 Attractions, and Unfinity ticket costs executed by shared family descriptors.",
        "card_count": len(registry_cards),
        "family_counts": dict(sorted(family_counts.items())),
        "cards": registry_cards,
    }
    return registry, rules


def canonical_text(payload: dict[str, Any]) -> str:
    return json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n"


def main() -> int:
    args = parse_args()
    registry, generated_rules = build(load_cards(args.sqlite_db))
    reviewed_rules = json.loads(args.reviewed_rules.read_text(encoding="utf-8"))
    stale = [
        name
        for name, rule in reviewed_rules.items()
        if isinstance(rule, dict)
        and (rule.get("effect_json") or {}).get("unfinity_sticker_runtime")
        and name not in generated_rules
    ]
    for name in stale:
        reviewed_rules.pop(name, None)
    reviewed_rules.update(generated_rules)
    registry_text = canonical_text(registry)
    rules_text = canonical_text(reviewed_rules)
    if args.check:
        current_registry = args.registry.read_text(encoding="utf-8") if args.registry.exists() else ""
        current_rules = args.reviewed_rules.read_text(encoding="utf-8")
        if current_registry != registry_text or current_rules != rules_text:
            raise SystemExit("Unfinity sticker registry or reviewed rules are out of date")
        return 0
    args.registry.write_text(registry_text, encoding="utf-8")
    args.reviewed_rules.write_text(rules_text, encoding="utf-8")
    print(
        json.dumps(
            {
                "status": "pass",
                "card_count": registry["card_count"],
                "family_counts": registry["family_counts"],
                "registry": str(args.registry),
                "reviewed_rules": str(args.reviewed_rules),
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
