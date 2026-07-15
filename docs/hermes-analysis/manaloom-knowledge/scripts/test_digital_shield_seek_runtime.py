#!/usr/bin/env python3
"""Focused runtime coverage for shield counters and seek triggers."""

from __future__ import annotations

import importlib.util
import json
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location(
        "battle_digital_shield_seek_under_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def cloudsculpt_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Cloudsculpt Armorer"]


def player(battle, name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def cloudsculpt_permanent(controller_name):
    return {
        "name": "Cloudsculpt Armorer",
        "owner": controller_name,
        "controller": controller_name,
        **cloudsculpt_rule()["effect_json"],
    }


def test_cloudsculpt_reviewed_rule_has_runtime_and_oracle_contract():
    rule = cloudsculpt_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "57c5d193cf4da6c667e45324d5a9d304"
    assert effect["etb_add_counters_counter_type"] == "shield"
    assert effect["etb_add_counters_target"] == "artifact_or_creature"
    assert effect[
        "trigger_on_one_or_more_counters_removed_from_controlled_permanent"
    ] is True
    assert effect["trigger_effect"] == "seek_card"
    assert effect["trigger_seek_filter"] == "nonland"


def test_cloudsculpt_etb_supports_noncreature_artifact_targets():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    cloudsculpt = cloudsculpt_permanent(controller.name)
    relic = {
        "name": "Priority Relic",
        "owner": controller.name,
        "controller": controller.name,
        "type_line": "Artifact",
        "effect": "wincon",
        "cmc": 10,
    }
    controller.battlefield = [cloudsculpt, relic]
    battle.bind_table_context([controller, opponent])

    candidates = battle.add_counters_candidate_targets(
        controller,
        [opponent],
        cloudsculpt,
        {
            **cloudsculpt_rule()["effect_json"],
            "effect": "add_counters",
            "target": "artifact_or_creature",
            "counter_type": "shield",
            "counter_count": 1,
        },
    )
    assert relic in [target for _owner, target in candidates]

    battle.resolve_generic_permanent_etb(
        controller,
        [opponent],
        cloudsculpt,
        cloudsculpt_rule()["effect_json"],
        turn=2,
        rng=random.Random(2),
        all_players=[controller, opponent],
    )

    assert sum(
        battle.get_named_counter_count(permanent, "shield")
        for permanent in controller.battlefield
    ) == 1


def test_shield_counter_prevents_damage_and_seek_moves_only_nonland_without_shuffle():
    battle = load_battle()
    nonland = {"name": "Sought Spell", "type_line": "Instant"}
    land = {"name": "Island", "type_line": "Basic Land - Island"}
    controller = player(battle, "Controller", deck=[land, nonland])
    opponent = player(battle, "Opponent")
    cloudsculpt = cloudsculpt_permanent(controller.name)
    shielded = {
        "name": "Shielded Creature",
        "owner": controller.name,
        "controller": controller.name,
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
    }
    battle.add_named_counters(shielded, "shield", 1)
    controller.battlefield = [cloudsculpt, shielded]
    battle.bind_table_context([controller, opponent])

    final_damage = battle.apply_static_damage_replacements(
        opponent,
        controller,
        shielded,
        {"name": "Lethal Bolt", "type_line": "Instant"},
        20,
        damage_event_type="permanent",
        turn=3,
        phase="resolution",
    )

    assert final_damage == 0
    assert battle.get_named_counter_count(shielded, "shield") == 0
    assert shielded in controller.battlefield
    assert [card.get("name") for card in controller.hand] == ["Sought Spell"]
    assert [card.get("name") for card in controller.library] == ["Island"]


def test_shield_counter_replaces_destroy_then_next_destroy_succeeds():
    battle = load_battle()
    controller = player(
        battle,
        "Controller",
        deck=[{"name": "Sought Creature", "type_line": "Creature - Test"}],
    )
    opponent = player(battle, "Opponent")
    cloudsculpt = cloudsculpt_permanent(controller.name)
    shielded = {
        "name": "Shielded Artifact",
        "owner": controller.name,
        "controller": controller.name,
        "type_line": "Artifact",
        "effect": "artifact",
    }
    battle.add_named_counters(shielded, "shield", 1)
    controller.battlefield = [cloudsculpt, shielded]
    battle.bind_table_context([controller, opponent])
    battle.CURRENT_REPLAY_TURN = 4
    try:
        first_destination = battle.move_permanent_from_battlefield(
            controller,
            shielded,
            reason="destroy",
            source={"name": "Destroy Spell"},
            all_players=[controller, opponent],
        )
        assert first_destination == "battlefield"
        assert shielded in controller.battlefield
        assert battle.get_named_counter_count(shielded, "shield") == 0
        assert [card.get("name") for card in controller.hand] == ["Sought Creature"]

        second_destination = battle.move_permanent_from_battlefield(
            controller,
            shielded,
            reason="destroy",
            source={"name": "Second Destroy Spell"},
            all_players=[controller, opponent],
        )
    finally:
        battle.CURRENT_REPLAY_TURN = None

    assert second_destination == "graveyard"
    assert shielded not in controller.battlefield
    assert shielded in controller.graveyard


def test_removing_multiple_counters_is_one_seek_event_and_sacrifice_is_not_replaced():
    battle = load_battle()
    controller = player(
        battle,
        "Controller",
        deck=[
            {"name": "First Nonland", "type_line": "Sorcery"},
            {"name": "Second Nonland", "type_line": "Creature"},
        ],
    )
    opponent = player(battle, "Opponent")
    cloudsculpt = cloudsculpt_permanent(controller.name)
    creature = {
        "name": "Countered Creature",
        "owner": controller.name,
        "controller": controller.name,
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": 5,
        "toughness": 5,
    }
    battle.add_plus_one_counters(creature, 3)
    battle.add_named_counters(creature, "shield", 1)
    controller.battlefield = [cloudsculpt, creature]
    battle.bind_table_context([controller, opponent])

    assert battle.remove_plus_one_counters(
        creature,
        2,
        controller=controller,
        reason="activation_cost",
        turn=5,
        all_players=[controller, opponent],
    ) == 2
    assert len(controller.hand) == 1

    destination = battle.move_creature_from_battlefield(
        controller,
        creature,
        reason="sacrifice",
        source=creature,
        all_players=[controller, opponent],
    )
    assert destination == "graveyard"
    assert len(controller.hand) == 1


if __name__ == "__main__":
    test_cloudsculpt_reviewed_rule_has_runtime_and_oracle_contract()
    test_cloudsculpt_etb_supports_noncreature_artifact_targets()
    test_shield_counter_prevents_damage_and_seek_moves_only_nonland_without_shuffle()
    test_shield_counter_replaces_destroy_then_next_destroy_succeeds()
    test_removing_multiple_counters_is_one_seek_event_and_sacrifice_is_not_replaced()
    print("PASS test_digital_shield_seek_runtime")
