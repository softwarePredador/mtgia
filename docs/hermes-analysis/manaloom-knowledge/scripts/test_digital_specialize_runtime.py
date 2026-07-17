#!/usr/bin/env python3
"""End-to-end runtime contract for all HBG Specialize cards."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import random
import sqlite3
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REGISTRY_PATH = SCRIPT_DIR / "specialize_card_registry.json"
RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_specialize_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


BATTLE = load_battle()
REGISTRY = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
RULES = json.loads(RULES_PATH.read_text(encoding="utf-8"))
LAND_TYPE = {"W": "Plains", "U": "Island", "B": "Swamp", "R": "Mountain", "G": "Forest"}


def player(name):
    return BATTLE.Player(name, None, [], strategy="midrange")


def creature(name, power=2, toughness=2, **extra):
    payload = {
        "name": name,
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": power,
        "toughness": toughness,
        "cmc": extra.pop("cmc", 2),
    }
    payload.update(extra)
    return payload


def specialize_source(family, color):
    definition = REGISTRY["families"][family]
    metadata = json.loads(json.dumps(definition["face_metadata_by_color"][color]))
    metadata.update(
        {
            "name": definition["face_by_color"][color],
            "_perpetual_specialized_face": True,
            "_specialize_family": family,
            "_specialize_color": color,
            "_specialize_base_name": definition["base_name"],
            "_specialize_on_battlefield": True,
        }
    )
    metadata.update(BATTLE.specialize_face_runtime_fields(family, color))
    return metadata


def activate_family(family, color, *, zone="battlefield"):
    definition = REGISTRY["families"][family]
    controller = player(f"Controller-{family}-{color}")
    opponent = player(f"Opponent-{family}-{color}")
    base_effect = RULES[definition["base_name"]]["effect_json"]
    card = {
        **json.loads(json.dumps(base_effect)),
        "name": definition["base_name"],
        "effect": "creature",
        "type_line": base_effect.get("type_line") or "Legendary Creature - Test",
        "power": int(float(base_effect.get("power") or 3)),
        "toughness": int(float(base_effect.get("toughness") or 3)),
    }
    getattr(controller, zone).append(card)
    discard = {
        "name": f"{LAND_TYPE[color]} Discard",
        "type_line": f"Basic Land - {LAND_TYPE[color]}",
        "effect": "land",
        "colors": [],
    }
    controller.hand = [discard]
    controller.mana_pool.add_generic(20)
    if family == "lukamina":
        controller.battlefield.extend(
            {
                "name": f"Land {index}",
                "type_line": "Basic Land - Forest",
                "effect": "land",
            }
            for index in range(6)
        )
    if family == "shadowheart":
        opponent.life = 13
    BATTLE.bind_table_context([controller, opponent])
    activated = BATTLE.activate_specialize(
        controller,
        card,
        [opponent],
        [controller, opponent],
        turn=3,
        phase="precombat_main",
        rng=random.Random(300 + ord(color)),
        preferred_color=color,
    )
    return controller, opponent, card, discard, activated


def test_registry_and_reviewed_rules_cover_19_bases_and_95_faces_exactly():
    assert REGISTRY["family_count"] == 19
    assert REGISTRY["base_card_count"] == 19
    assert REGISTRY["derived_face_count"] == 95
    assert REGISTRY["rule_card_count"] == 114
    specialize_rules = {
        name: rule
        for name, rule in RULES.items()
        if (rule.get("effect_json") or {}).get("specialize_base_card")
        or (rule.get("effect_json") or {}).get("specialize_derived_face")
    }
    assert len(specialize_rules) == 114
    assert sum(bool(rule["effect_json"].get("specialize_base_card")) for rule in specialize_rules.values()) == 19
    assert sum(bool(rule["effect_json"].get("specialize_derived_face")) for rule in specialize_rules.values()) == 95
    logical_keys = {rule["logical_rule_key"] for rule in specialize_rules.values()}
    assert len(logical_keys) == 114
    for name, rule in specialize_rules.items():
        normalized_name = " ".join(name.strip().lower().split())
        identity = f"specialize_card_runtime_v1:{normalized_name}"
        assert rule["logical_rule_key"] == (
            "battle_rule_v1:" + hashlib.md5(identity.encode("utf-8")).hexdigest()
        )

    names = sorted(specialize_rules)
    connection = sqlite3.connect(KNOWLEDGE_DB)
    try:
        rows = connection.execute(
            f"SELECT name, oracle_text FROM card_oracle_cache WHERE name IN ({','.join('?' for _ in names)})",
            names,
        ).fetchall()
    finally:
        connection.close()
    oracle_by_name = {name: oracle_text for name, oracle_text in rows}
    assert len(oracle_by_name) == 114
    for name, oracle_text in oracle_by_name.items():
        rule = specialize_rules[name]
        assert rule["review_status"] == "verified"
        assert rule["execution_status"] == "auto"
        assert rule["oracle_hash"] == hashlib.md5((oracle_text or "").encode("utf-8")).hexdigest()
        resolved = BATTLE.get_card_effect(
            {
                "name": name,
                "type_line": rule["effect_json"].get("type_line") or "Creature - Test",
            }
        )
        assert resolved["battle_model_scope"] == rule["effect_json"]["battle_model_scope"]
        assert resolved["_rule_review_status"] == "verified"
        assert resolved["_rule_execution_status"] == "auto"

    twilight = RULES["Shadowheart, Cleric of Twilight"]["effect_json"]
    assert not twilight.get("unblockable")
    assert twilight["cant_be_blocked_by_filters"] == [
        {"kind": "power", "operator": "lte", "value": 2}
    ]
    radiant = RULES["Rasaad, Radiant Monk"]["effect_json"]
    assert radiant["specialize_color"] == "W"


def test_every_family_and_color_activates_to_the_exact_95_faces():
    activated_faces = set()
    for family, definition in REGISTRY["families"].items():
        assert set(definition["face_by_color"]) == set(BATTLE.SPECIALIZE_COLOR_ORDER)
        for color in BATTLE.SPECIALIZE_COLOR_ORDER:
            controller, _opponent, card, discard, activated = activate_family(family, color)
            assert activated is True, (family, color)
            assert card["name"] == definition["face_by_color"][color]
            assert card["_specialize_family"] == family
            assert card["_specialize_color"] == color
            assert card["_perpetual_specialized_face"] is True
            assert discard not in controller.hand
            assert discard in controller.graveyard
            activated_faces.add(card["name"])
    assert len(activated_faces) == 95


def test_specialize_conditions_and_karlach_graveyard_zone_are_enforced():
    definition = REGISTRY["families"]["imoen"]
    controller = player("Imoen")
    card = {"name": definition["base_name"], "type_line": "Legendary Creature - Human", "power": 3, "toughness": 2}
    controller.battlefield = [card]
    controller.graveyard = [
        {"name": "Spell A", "type_line": "Instant"},
        {"name": "Spell B", "type_line": "Sorcery"},
    ]
    controller.hand = [{"name": "Island", "type_line": "Basic Land - Island"}]
    controller.mana_pool.add_generic(2)
    assert BATTLE.specialize_activation_locked_cost(controller, definition)["generic"] == 2
    assert BATTLE.activate_specialize(
        controller,
        card,
        [],
        [controller],
        turn=4,
        phase="precombat_main",
        rng=random.Random(4),
        preferred_color="U",
    )

    controller, _opponent, karlach, _discard, activated = activate_family(
        "karlach", "R", zone="graveyard"
    )
    assert activated is True
    assert karlach in controller.battlefield
    assert karlach not in controller.graveyard
    assert karlach["cant_block"] is True


def test_base_etbs_execute_before_specialization_and_preserve_linked_cards():
    controller = player("Base Controller")
    opponent = player("Base Opponent")
    BATTLE.bind_table_context([controller, opponent])

    gale_effect = RULES["Gale, Conduit of the Arcane"]["effect_json"]
    gale = {**gale_effect, "name": "Gale, Conduit of the Arcane", "was_cast": True}
    spell = {"name": "Recovered Spell", "type_line": "Instant", "cmc": 4}
    controller.battlefield = [gale]
    controller.graveyard = [spell]
    BATTLE.resolve_specialize_base_etb(
        controller, [opponent], gale, gale_effect, 5, random.Random(5), all_players=[controller, opponent]
    )
    assert spell in controller.hand and spell not in controller.graveyard

    klement_effect = RULES["Klement, Novice Acolyte"]["effect_json"]
    klement = {**klement_effect, "name": "Klement, Novice Acolyte", "was_cast": True}
    hand_creature = creature("Hand Creature", 2, 2)
    controller.battlefield = [klement]
    controller.hand = [hand_creature]
    BATTLE.resolve_specialize_base_etb(
        controller, [opponent], klement, klement_effect, 5, random.Random(5), all_players=[controller, opponent]
    )
    assert (hand_creature["power"], hand_creature["toughness"]) == (3, 3)

    rasaad_effect = RULES["Rasaad, Monk of Selûne"]["effect_json"]
    rasaad = {**rasaad_effect, "name": "Rasaad, Monk of Selûne", "was_cast": True}
    exiled_target = creature("Exiled Target", 5, 5)
    controller.battlefield = [rasaad]
    opponent.battlefield = [exiled_target]
    BATTLE.resolve_specialize_base_etb(
        controller, [opponent], rasaad, rasaad_effect, 5, random.Random(5), all_players=[controller, opponent]
    )
    assert exiled_target in opponent.exile and exiled_target not in opponent.battlefield
    BATTLE.move_creature_from_battlefield(
        controller, rasaad, reason="unit_test", all_players=[controller, opponent]
    )
    assert exiled_target in opponent.battlefield and exiled_target not in opponent.exile


def test_laezel_cast_granted_blink_invalidates_opponent_target_and_expires():
    controller = player("Laezel Controller")
    opponent = player("Laezel Opponent")
    BATTLE.bind_table_context([controller, opponent])
    effect = RULES["Lae'zel, Githyanki Warrior"]["effect_json"]
    laezel = {
        **effect,
        "name": "Lae'zel, Githyanki Warrior",
        "type_line": "Legendary Creature - Gith Warrior",
        "power": 2,
        "toughness": 4,
        "was_cast": True,
        "_cast_context": {"source_zone": "hand"},
        "_zone_id": 7,
    }
    controller.battlefield = [laezel]
    BATTLE.resolve_specialize_base_etb(
        controller,
        [opponent],
        laezel,
        effect,
        5,
        random.Random(5),
        all_players=[controller, opponent],
    )
    assert laezel["_opponent_target_blink_active"] is True

    removal = {"name": "Hostile Removal", "type_line": "Instant"}
    removal_effect = {
        "effect": "remove_creature",
        "target": "creature",
        "declared_targets": [
            {
                "target": laezel,
                "controller": controller,
                "target_type": "creature",
                "declared_by": opponent,
            }
        ],
    }
    assert BATTLE.resolve_declared_single_removal(
        opponent,
        [controller],
        removal,
        removal_effect,
        5,
        random.Random(5),
    )
    returned = next(card for card in controller.battlefield if card.get("name") == laezel["name"])
    assert returned is not laezel
    # A blink is two distinct zone changes.  The old battlefield object moves
    # to exile first (7 -> 8), then the returning permanent gets a fresh zone
    # identity when it enters the battlefield (8 -> 9).
    assert laezel["_zone_id"] == 8
    assert returned["_zone_id"] == 9
    assert not returned.get("_opponent_target_blink_active")
    assert not returned.get("was_cast")
    assert "_cast_context" not in returned
    assert laezel not in controller.graveyard

    second_effect = {
        **removal_effect,
        "declared_targets": [
            {
                "target": returned,
                "controller": controller,
                "target_type": "creature",
                "declared_by": opponent,
            }
        ],
    }
    assert BATTLE.resolve_declared_single_removal(
        opponent,
        [controller],
        removal,
        second_effect,
        6,
        random.Random(6),
    )
    assert returned in controller.graveyard
    assert returned not in controller.battlefield


def test_laezel_derived_faces_repeat_transition_on_battlefield_entry():
    for color, face_name in REGISTRY["families"]["laezel"]["face_by_color"].items():
        effect = RULES[face_name]["effect_json"]
        assert effect["specialize_transition_on_enter"] is True

    controller = player("Laezel Face Controller")
    opponent = player("Laezel Face Opponent")
    face_name = REGISTRY["families"]["laezel"]["face_by_color"]["R"]
    face_effect = RULES[face_name]["effect_json"]
    face = {**face_effect, "name": face_name, "power": 3, "toughness": 6}
    controller.battlefield = [face]
    BATTLE.resolve_generic_permanent_etb(
        controller,
        [opponent],
        face,
        face_effect,
        7,
        random.Random(7),
        all_players=[controller, opponent],
    )
    soldiers = [card for card in controller.battlefield if card.get("name") == "Soldier Token"]
    assert len(soldiers) == 2


def test_cast_attack_combat_damage_and_end_step_family_events_execute():
    controller = player("Events")
    opponent = player("Events Opponent")
    BATTLE.bind_table_context([controller, opponent])

    gale = specialize_source("gale", "R")
    teammate = creature("Teammate", 2, 2)
    controller.battlefield = [gale, teammate]
    for index in range(2):
        BATTLE.resolve_specialize_spell_cast_triggers(
            controller,
            [controller, opponent],
            {"name": f"Spell {index}", "type_line": "Instant"},
            6,
            "precombat_main",
        )
    assert teammate["power"] == 4

    alora = specialize_source("alora", "W")
    attacker = creature("Returned Attacker", 6, 6, flying=True, keywords=["flying"])
    controller.battlefield = [alora, attacker]
    BATTLE.resolve_specialize_attack_triggers(
        controller,
        [attacker],
        [opponent],
        [controller, opponent],
        6,
        random.Random(6),
    )
    assert attacker["unblockable"] is True
    BATTLE.process_specialize_end_step(controller, [controller, opponent], 6, random.Random(6))
    assert attacker in controller.hand
    assert any(card.get("name") == "Soldier Token" for card in controller.battlefield)

    imoen = specialize_source("imoen", "G")
    grave_spell = {"name": "Flashback Fuel", "type_line": "Sorcery", "cmc": 3}
    draw_card = {"name": "Combat Draw"}
    controller.battlefield = [imoen]
    controller.graveyard = [grave_spell]
    controller.library = [draw_card]
    controller.max_lands_per_turn = 1
    BATTLE.resolve_specialize_combat_damage_triggers(
        controller,
        [imoen],
        opponent,
        [controller, opponent],
        6,
        random.Random(6),
    )
    assert grave_spell in controller.exile
    assert draw_card in controller.hand
    assert controller.max_lands_per_turn == 2


def test_death_life_loss_and_graveyard_activated_families_execute():
    controller = player("Triggers")
    opponent = player("Triggers Opponent")
    BATTLE.bind_table_context([controller, opponent])
    BATTLE.CURRENT_REPLAY_TURN = 7
    controller._active_turn_marker = 7
    try:
        shadowheart = specialize_source("shadowheart", "U")
        controller.battlefield = [shadowheart]
        drawn = {"name": "Life Loss Draw"}
        controller.library = [drawn]
        BATTLE.change_life(controller, -3)
        assert drawn in controller.hand

        klement = specialize_source("klement", "G")
        controller.battlefield = [klement]
        BATTLE.move_creature_from_battlefield(
            controller, klement, reason="unit_test", all_players=[controller, opponent]
        )
        assert any(card.get("name") == "Ox Token" for card in controller.battlefield)

        rasaad = specialize_source("rasaad", "B")
        controller.battlefield = [rasaad]
        BATTLE.move_creature_from_battlefield(
            controller, rasaad, reason="unit_test", all_players=[controller, opponent]
        )
        assert any(card.get("name") == "Skeleton Token" for card in controller.battlefield)
    finally:
        BATTLE.CURRENT_REPLAY_TURN = None

    controller, opponent, lukamina, _discard, activated = activate_family("lukamina", "R")
    assert activated is True
    BATTLE.CURRENT_REPLAY_TURN = 8
    try:
        BATTLE.move_creature_from_battlefield(
            controller, lukamina, reason="unit_test", all_players=[controller, opponent]
        )
    finally:
        BATTLE.CURRENT_REPLAY_TURN = None
    assert lukamina in controller.battlefield
    assert lukamina["name"] == "Lukamina, Moon Druid"
    assert lukamina["tapped"] is True
    assert not lukamina.get("_perpetual_specialized_face")

    controller = player("Wilson")
    opponent = player("Wilson Opponent")
    target = creature("Wilson Target", 2, 2)
    wilson = specialize_source("wilson", "G")
    wilson["_specialize_on_battlefield"] = False
    controller.battlefield = [target]
    controller.graveyard = [wilson]
    controller.mana_pool.add("wildcard", 10)
    BATTLE.bind_table_context([controller, opponent])
    assert BATTLE.activate_specialize_graveyard_abilities(
        controller, [opponent], [controller, opponent], 9, "precombat_main"
    )
    assert wilson in controller.exile
    assert (target["power"], target["toughness"]) == (3, 3)
    assert target["reach"] and target["trample"]
    assert target["ward_mana_cost"] == "{2}"


if __name__ == "__main__":
    test_registry_and_reviewed_rules_cover_19_bases_and_95_faces_exactly()
    test_every_family_and_color_activates_to_the_exact_95_faces()
    test_specialize_conditions_and_karlach_graveyard_zone_are_enforced()
    test_base_etbs_execute_before_specialization_and_preserve_linked_cards()
    test_laezel_cast_granted_blink_invalidates_opponent_target_and_expires()
    test_laezel_derived_faces_repeat_transition_on_battlefield_entry()
    test_cast_attack_combat_damage_and_end_step_family_events_execute()
    test_death_life_loss_and_graveyard_activated_families_execute()
    print("PASS test_digital_specialize_runtime")
