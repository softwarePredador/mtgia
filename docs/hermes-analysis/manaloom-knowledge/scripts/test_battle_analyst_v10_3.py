#!/usr/bin/env python3
"""Focused regression checks for the active battle_analyst_v9 engine.

The filename preserves the historical v10.3 replay-suite label, but
MODULE_PATH defaults to battle_analyst_v9.py unless BATTLE_ANALYST_PATH is set.

Run from this directory with:
    python3 test_battle_analyst_v10_3.py
"""

import importlib.util
import json
import os
import random
import sqlite3
import tempfile
from pathlib import Path


MODULE_PATH = Path(
    os.environ.get(
        "BATTLE_ANALYST_PATH",
        Path(__file__).with_name("battle_analyst_v9.py"),
    )
)
spec = importlib.util.spec_from_file_location("battle_under_test", MODULE_PATH)
battle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(battle)

METRICS_REPORT_PATH = MODULE_PATH.with_name("engine_metrics_report.py")
metrics_report_spec = importlib.util.spec_from_file_location(
    "engine_metrics_report_under_test",
    METRICS_REPORT_PATH,
)
engine_metrics_report = importlib.util.module_from_spec(metrics_report_spec)
metrics_report_spec.loader.exec_module(engine_metrics_report)

AUDITOR_PATH = MODULE_PATH.with_name("replay_decision_auditor.py")
auditor_spec = importlib.util.spec_from_file_location("replay_auditor_under_test", AUDITOR_PATH)
replay_auditor = importlib.util.module_from_spec(auditor_spec)
auditor_spec.loader.exec_module(replay_auditor)

RULES_2026_TESTS_PATH = MODULE_PATH.with_name("battle_rules_2026_tests.py")
rules_2026_spec = importlib.util.spec_from_file_location(
    "battle_rules_2026_tests_under_test",
    RULES_2026_TESTS_PATH,
)
battle_rules_2026_tests = importlib.util.module_from_spec(rules_2026_spec)
rules_2026_spec.loader.exec_module(battle_rules_2026_tests)

COMBAT_TESTS_PATH = MODULE_PATH.with_name("battle_combat_tests.py")
combat_spec = importlib.util.spec_from_file_location(
    "battle_combat_tests_under_test",
    COMBAT_TESTS_PATH,
)
battle_combat_tests = importlib.util.module_from_spec(combat_spec)
combat_spec.loader.exec_module(battle_combat_tests)

REPLACEMENT_TESTS_PATH = MODULE_PATH.with_name("battle_replacement_tests.py")
replacement_spec = importlib.util.spec_from_file_location(
    "battle_replacement_tests_under_test",
    REPLACEMENT_TESTS_PATH,
)
battle_replacement_tests = importlib.util.module_from_spec(replacement_spec)
replacement_spec.loader.exec_module(battle_replacement_tests)

COMMANDER_TESTS_PATH = MODULE_PATH.with_name("battle_commander_tests.py")
commander_spec = importlib.util.spec_from_file_location(
    "battle_commander_tests_under_test",
    COMMANDER_TESTS_PATH,
)
battle_commander_tests = importlib.util.module_from_spec(commander_spec)
commander_spec.loader.exec_module(battle_commander_tests)

MANA_TESTS_PATH = MODULE_PATH.with_name("battle_mana_tests.py")
mana_spec = importlib.util.spec_from_file_location(
    "battle_mana_tests_under_test",
    MANA_TESTS_PATH,
)
battle_mana_tests = importlib.util.module_from_spec(mana_spec)
mana_spec.loader.exec_module(battle_mana_tests)

STACK_CASTING_TESTS_PATH = MODULE_PATH.with_name("battle_stack_casting_tests.py")
stack_casting_spec = importlib.util.spec_from_file_location(
    "battle_stack_casting_tests_under_test",
    STACK_CASTING_TESTS_PATH,
)
battle_stack_casting_tests = importlib.util.module_from_spec(stack_casting_spec)
stack_casting_spec.loader.exec_module(battle_stack_casting_tests)

CARD_SPECIFIC_TESTS_PATH = MODULE_PATH.with_name("battle_card_specific_tests.py")
card_specific_spec = importlib.util.spec_from_file_location(
    "battle_card_specific_tests_under_test",
    CARD_SPECIFIC_TESTS_PATH,
)
battle_card_specific_tests = importlib.util.module_from_spec(card_specific_spec)
card_specific_spec.loader.exec_module(battle_card_specific_tests)


def card(name, cmc=99, effect="unknown", power=0):
    return {
        "name": name,
        "cmc": cmc,
        "tag": effect,
        "effect": effect,
        "type_line": "Creature" if effect == "creature" else "Sorcery",
        "power": power,
    }


def player(name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


CONFORMANCE_SCENARIOS = [
    {
        "id": "stack_lifo_405",
        "rule": "CR 405, 608",
        "purpose": "Stack resolves last-in-first-out.",
    },
    {
        "id": "commander_damage_ledger_903_10a",
        "rule": "CR 903.10a",
        "purpose": "Commander damage ledger persists across commander zone changes.",
    },
    {
        "id": "commander_damage_per_origin_903_10a",
        "rule": "CR 903.10a",
        "purpose": "Multiple commanders track lethal 21 damage per commander origin.",
    },
    {
        "id": "empty_library_draw_104_3c",
        "rule": "CR 104.3c",
        "purpose": "A failed draw from an empty library loses even with cards in hand.",
    },
    {
        "id": "token_ceases_outside_battlefield_110_5f",
        "rule": "CR 110.5f",
        "purpose": "Tokens in non-battlefield zones cease to exist through the SBA loop.",
    },
    {
        "id": "plus_minus_counter_cancel_704_5q",
        "rule": "CR 704.5q",
        "purpose": "+1/+1 and -1/-1 counters cancel as a state-based action.",
    },
    {
        "id": "illegal_attachment_sba_704_5m_n",
        "rule": "CR 704.5m-n",
        "purpose": "Illegal Auras go to graveyard and illegal Equipment becomes unattached.",
    },
    {
        "id": "saga_final_chapter_sba_704_5s",
        "rule": "CR 704.5s",
        "purpose": "A Saga with final chapter reached is sacrificed after its chapter ability is done.",
    },
    {
        "id": "zone_change_lki_identity_400_7",
        "rule": "CR 400.7, 608.2g",
        "purpose": "Zone changes preserve LKI and advance logical object identity.",
    },
    {
        "id": "exile_visibility_406_3",
        "rule": "CR 406.3",
        "purpose": "Cards moved to exile preserve basic face-up or face-down visibility metadata.",
    },
    {
        "id": "blocked_stays_blocked_509_1h",
        "rule": "CR 509.1h",
        "purpose": "A creature remains blocked after all blockers leave combat.",
    },
    {
        "id": "end_of_combat_trigger_511_3",
        "rule": "CR 511.3, 603.3b",
        "purpose": "End of combat triggered abilities are put on the stack in APNAP order.",
    },
    {
        "id": "apnap_trigger_order_603_3b",
        "rule": "CR 603.3b",
        "purpose": "Triggers are placed on the stack in APNAP order.",
    },
    {
        "id": "prevention_before_damage_615",
        "rule": "CR 615",
        "purpose": "Prevention replacement applies before damage mutates life.",
    },
    {
        "id": "hybrid_phyrexian_payment_601_2h",
        "rule": "CR 601.2h, 107.4e, 107.4f",
        "purpose": "Basic hybrid and colored Phyrexian mana are payable through legal alternatives.",
    },
]
CONFORMANCE_SCENARIOS.extend(battle_rules_2026_tests.CONFORMANCE_SCENARIOS_2026)


def test_sba_only_reports_new_elimination():
    dead = player("Dead")
    alive = player("Alive", [card("Library card")])
    dead.life = 0

    assert battle.check_sbas([alive, dead]) is True
    assert dead.eliminated is True
    assert battle.check_sbas([alive, dead]) is False


def test_cleanup_runs_with_previously_eliminated_player():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.hand = [card(f"Expensive {index}") for index in range(10)]
    dead = player("Dead")
    dead.life = 0
    dead.eliminated = True

    battle.play_turn_v8(
        active,
        [dead],
        [active, dead],
        turn=3,
        rng=random.Random(1),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 7


def test_plus_minus_counters_cancel_as_sba():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    creature = {
        "name": "Countered Creature",
        "effect": "creature",
        "type_line": "Creature",
        "power": 2,
        "toughness": 2,
        "plus_one_counters": 2,
        "minus_one_counters": 1,
    }
    active.battlefield = [creature]

    battle.check_sbas_until_stable([active])

    assert creature in active.battlefield
    assert creature["plus_one_counters"] == 1
    assert creature["minus_one_counters"] == 0
    assert any(event == "counters_cancelled" for event, _ in events)


def test_illegal_aura_goes_to_graveyard_and_equipment_detaches():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    creature = {
        "name": "Bearer",
        "effect": "creature",
        "type_line": "Creature",
        "power": 2,
        "toughness": 2,
    }
    land = {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"}
    aura = {
        "name": "Creature Aura",
        "type_line": "Enchantment — Aura",
        "oracle_text": "Enchant creature",
        "attached_to": "Missing Creature",
    }
    equipment = {
        "name": "Illegal Sword",
        "type_line": "Artifact — Equipment",
        "equipped_to": "Plains",
    }
    active.battlefield = [creature, land, aura, equipment]

    battle.check_sbas_until_stable([active])

    assert aura not in active.battlefield
    assert aura in active.graveyard
    assert equipment in active.battlefield
    assert "equipped_to" not in equipment
    assert [data["action"] for event, data in events if event == "attachment_sba"] == [
        "moved_to_graveyard",
        "detached",
    ]


def test_saga_final_chapter_sacrifices_after_pending_ability_resolves():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    saga = {
        "name": "Test Saga",
        "type_line": "Enchantment — Saga",
        "lore_counters": 3,
        "final_chapter": 3,
        "chapter_ability_pending": True,
    }
    active.battlefield = [saga]

    battle.check_sbas_until_stable([active])
    assert saga in active.battlefield

    saga["chapter_ability_pending"] = False
    battle.check_sbas_until_stable([active])

    assert saga not in active.battlefield
    assert saga in active.graveyard
    assert any(event == "saga_sacrificed_by_sba" for event, _ in events)


def test_zone_change_records_lki_and_advances_zone_identity():
    active = player("Active")
    creature = {
        "name": "Tracked Creature",
        "effect": "creature",
        "type_line": "Creature",
        "power": 4,
        "toughness": 5,
        "cmc": 3,
        "_zone_id": 7,
    }
    active.battlefield = [creature]

    destination = battle.move_creature_from_battlefield(active, creature, reason="destroyed")

    assert destination == "graveyard"
    assert creature not in active.battlefield
    assert creature in active.graveyard
    assert creature["_zone_id"] == 8
    assert creature["_last_zone"] == "battlefield"
    assert battle.get_lki(creature)["power"] == 4
    assert battle.move_creature_from_battlefield(active, "not a permanent") == "none"


def test_exile_records_face_up_and_face_down_visibility():
    active = player("Active")
    public_card = {"name": "Public Exile"}
    hidden_card = {"name": "Hidden Exile"}

    battle.move_to_exile(active, public_card, reason="test_public", turn=3)
    battle.move_to_exile(
        active,
        hidden_card,
        face_down=True,
        public=False,
        reason="test_hidden",
        turn=3,
    )

    assert active.exile == [public_card, hidden_card]
    assert public_card["_exile_face_down"] is False
    assert public_card["_exile_public"] is True
    assert public_card["_exile_reason"] == "test_public"
    assert public_card["_exile_turn"] == 3
    assert hidden_card["_exile_face_down"] is True
    assert hidden_card["_exile_public"] is False
    assert hidden_card["_exile_reason"] == "test_hidden"
    assert hidden_card["_exile_turn"] == 3


def test_draw_step_runs_once_with_multiple_permanents():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.battlefield = [
        {"name": "Permanent A", "effect": "unknown"},
        {"name": "Permanent B", "effect": "unknown"},
    ]
    opponent = player("Opponent", [card("Opp Draw") for _ in range(5)])

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=1,
        rng=random.Random(2),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 1


def test_approach_sets_explicit_win_state():
    active = player("Active")
    opponent = player("Opponent")
    approach = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }

    battle.apply_effect_immediate(active, [opponent], approach, 5, random.Random(3))
    assert active.has_won() is False
    battle.apply_effect_immediate(active, [opponent], approach, 6, random.Random(3))

    assert active.has_won() is True
    assert active.win_reason == "approach"


def test_combat_emits_structured_event():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    attacker.battlefield = [
        {
            "name": "Attacker Creature",
            "effect": "creature",
            "power": 3,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(4),
        stack=battle.Stack(),
    )

    combat_events = [data for event, data in events if event == "combat"]
    assert len(combat_events) == 1
    assert combat_events[0]["attacker"] == "Attacker"
    assert combat_events[0]["target"] == "Defender"
    assert combat_events[0]["attackers"] == 1
    combat_steps = [data["step"] for event, data in events if event == "combat_step"]
    assert combat_steps == [
        "beginning_of_combat",
        "declare_attackers",
        "declare_blockers",
        "combat_damage",
        "end_of_combat",
    ]


def test_end_of_combat_triggers_use_stack_and_apnap_order():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player("Active", [{"name": "Active Draw"}])
        nonactive = player("Nonactive", [{"name": "Nonactive Draw"}])
        active.battlefield = [
            {
                "name": "Active End Engine",
                "trigger": "end_of_combat",
                "trigger_effect": "draw",
                "trigger_draw_count": 1,
            }
        ]
        nonactive.battlefield = [
            {
                "name": "Nonactive End Engine",
                "trigger": "end_of_combat",
                "trigger_effect": "draw",
                "trigger_draw_count": 1,
            }
        ]
        stack = battle.Stack()

        battle.end_of_combat_step(
            active,
            [active, nonactive],
            turn=4,
            rng=random.Random(4),
            stack=stack,
        )

        assert stack.empty()
        assert [card["name"] for card in active.hand] == ["Active Draw"]
        assert [card["name"] for card in nonactive.hand] == ["Nonactive Draw"]
        put_on_stack = [
            data["player"]
            for event, data in events
            if event == "trigger_put_on_stack" and data.get("trigger") == "end_of_combat"
        ]
        assert put_on_stack == ["Active", "Nonactive"]
        resolved = [
            data["player"]
            for event, data in events
            if event == "trigger_resolved" and data.get("trigger") == "end_of_combat"
        ]
        assert resolved == ["Nonactive", "Active"]
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_turn_stops_immediately_after_approach_win():
    active = player("Active", [card("Library card") for _ in range(10)])
    opponent = player("Opponent", [card("Opp Library") for _ in range(10)])
    active.approach_count = 1
    active.hand = [
        {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        },
        {
            "name": "Must Stay In Hand",
            "cmc": 1,
            "tag": "draw",
            "type_line": "Sorcery",
        },
    ]
    active.battlefield = ["land" for _ in range(10)]

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=5,
        rng=random.Random(5),
        stack=battle.Stack(),
    )

    assert active.has_won() is True
    assert any(card["name"] == "Must Stay In Hand" for card in active.hand)


def test_continuous_effects_apply_layers_and_sublayers_in_order():
    creature = {
        "name": "Layer Test",
        "type_line": "Creature",
        "colors": ["red"],
        "abilities": ["trample"],
        "power": 2,
        "toughness": 2,
    }
    result = battle.apply_continuous_effects(
        creature,
        [
            {"effect_id": "switch", "layer": 7, "sublayer": "7e", "effect_type": "switch_pt", "timestamp": 1},
            {
                "effect_id": "set-pt",
                "layer": 7,
                "sublayer": "7b",
                "effect_type": "set_pt",
                "value": {"power": 1, "toughness": 4},
                "timestamp": 5,
            },
            {
                "effect_id": "modify",
                "layer": 7,
                "sublayer": "7c",
                "effect_type": "modify_pt",
                "value": {"power": 2, "toughness": 0},
                "timestamp": 2,
            },
            {
                "effect_id": "counter",
                "layer": 7,
                "sublayer": "7d",
                "effect_type": "counter_pt",
                "value": {"power": 0, "toughness": 1},
                "timestamp": 3,
            },
        ],
    )

    assert result["power"] == 5
    assert result["toughness"] == 3
    assert result["_continuous_effects_applied"] == ["set-pt", "modify", "counter", "switch"]


def test_continuous_effects_apply_type_color_text_and_ability_layers():
    card_state = {
        "name": "Layer Utility",
        "type_line": "Creature",
        "oracle_text": "Target creature gains flying.",
        "colors": ["white"],
        "abilities": ["flying", "vigilance"],
    }

    result = battle.apply_continuous_effects(
        card_state,
        [
            {
                "effect_id": "text",
                "layer": 3,
                "effect_type": "replace_text",
                "value": {"from": "flying", "to": "trample"},
                "timestamp": 4,
            },
            {"effect_id": "type", "layer": 4, "effect_type": "add_type", "value": ["Artifact"], "timestamp": 3},
            {"effect_id": "color", "layer": 5, "effect_type": "set_color", "value": ["blue"], "timestamp": 2},
            {"effect_id": "add", "layer": 6, "effect_type": "add_ability", "value": ["hexproof"], "timestamp": 1},
            {"effect_id": "remove", "layer": 6, "effect_type": "remove_ability", "value": ["flying"], "timestamp": 5},
        ],
    )

    assert result["oracle_text"] == "Target creature gains trample."
    assert result["type_line"] == "Creature Artifact"
    assert result["colors"] == ["blue"]
    assert "hexproof" in result["abilities"]
    assert "flying" not in result["abilities"]
    assert "vigilance" in result["abilities"]


def test_continuous_effect_dependencies_override_timestamp_within_layer():
    card_state = {"name": "Dependency Test", "type_line": "Creature", "abilities": []}

    result = battle.apply_continuous_effects(
        card_state,
        [
            {
                "effect_id": "remove-flying",
                "layer": 6,
                "effect_type": "remove_ability",
                "value": ["flying"],
                "timestamp": 1,
                "depends_on": ["add-flying"],
            },
            {
                "effect_id": "add-flying",
                "layer": 6,
                "effect_type": "add_ability",
                "value": ["flying"],
                "timestamp": 9,
            },
        ],
    )

    assert result["abilities"] == []
    assert result["_continuous_effects_applied"] == ["add-flying", "remove-flying"]


def test_planeswalker_loyalty_activation_damage_and_sba():
    active = player("Active")
    walker = {
        "name": "Test Walker",
        "type_line": "Legendary Planeswalker",
        "starting_loyalty": 3,
    }
    battle.handle_planeswalker_etb(walker, active)
    active.battlefield = [walker]

    assert walker["loyalty"] == 3
    assert battle.activate_loyalty_ability(
        active,
        walker,
        -2,
        "precombat_main",
        battle.Stack(),
    ) is True
    assert walker["loyalty"] == 1
    assert battle.activate_loyalty_ability(
        active,
        walker,
        1,
        "precombat_main",
        battle.Stack(),
    ) is False
    assert battle.damage_to_planeswalker({"name": "Shock"}, walker, 1) is True
    assert walker["loyalty"] == 0

    assert battle.check_sbas([active]) is True
    assert walker in active.graveyard
    assert walker not in active.battlefield


def test_battle_defense_damage_and_sba():
    active = player("Active")
    protector = player("Protector")
    siege = {
        "name": "Test Siege",
        "type_line": "Battle - Siege",
        "starting_defense": 3,
    }
    battle.handle_siege_etb(siege, active, [protector])
    active.battlefield = [siege]

    assert siege["defense"] == 3
    assert siege["protector"] == "Protector"
    assert battle.battle_takes_damage(siege, 3) is True
    assert siege["defense"] == 0

    assert battle.check_sbas([active, protector]) is True
    assert siege in active.exile
    assert siege not in active.battlefield
    assert siege["battle_defeated"] is True


def test_battle_defeated_casts_back_face():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player("Active")
        protector = player("Protector")
        siege = {
            "name": "Test Siege // Reward Creature",
            "type_line": "Battle - Siege",
            "starting_defense": 2,
            "back_face": {
                "name": "Reward Creature",
                "type_line": "Creature",
                "power": 3,
                "toughness": 3,
            },
        }
        battle.handle_siege_etb(siege, active, [protector])
        active.battlefield = [siege]

        assert battle.battle_takes_damage(siege, 2) is True
        assert battle.check_sbas([active, protector]) is True

        assert siege in active.exile
        assert siege["battle_defeated"] is True
        assert len(active.battlefield) == 1
        assert active.battlefield[0]["name"] == "Reward Creature"
        assert active.battlefield[0]["effect"] == "creature"
        assert active.battlefield[0]["cast_from_battle_back_face"] is True
        assert "battle_back_face_cast" in [event for event, _ in events]
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_dfc_characteristics_and_color_identity_use_all_faces():
    dfc = {
        "name": "Front Face // Back Face",
        "is_dfc": True,
        "front_face": {
            "name": "Front Face",
            "mana_cost": "{W}",
            "colors": ["white"],
            "type_line": "Creature",
        },
        "back_face": {
            "name": "Back Face",
            "mana_cost": "{B}",
            "colors": ["black"],
            "type_line": "Creature",
        },
    }

    assert battle.get_card_characteristics(dfc, "hand")["name"] == "Front Face"
    dfc["is_transformed"] = True
    assert battle.get_card_characteristics(dfc, "battlefield")["name"] == "Back Face"
    assert battle.compute_color_identity(dfc) == ["white", "black"]


def test_adventure_prototype_and_split_characteristics_by_cast_mode():
    adventure = {
        "name": "Questing Example",
        "mana_cost": "{2}{G}",
        "colors": ["green"],
        "type_line": "Creature",
        "adventure": {
            "name": "Example Adventure",
            "mana_cost": "{U}",
            "colors": ["blue"],
            "type_line": "Instant - Adventure",
        },
    }
    prototype = {
        "name": "Prototype Example",
        "mana_cost": "{7}",
        "colors": [],
        "type_line": "Artifact Creature",
        "prototype": {
            "name": "Prototype Example",
            "mana_cost": "{1}{R}",
            "colors": ["red"],
            "type_line": "Artifact Creature",
            "power": 2,
            "toughness": 2,
        },
    }
    split = {
        "name": "Left // Right",
        "is_split": True,
        "chosen_half": "half_b",
        "type_line": "Instant // Sorcery",
        "half_a": {"name": "Left", "cmc": 2, "colors": ["white"]},
        "half_b": {"name": "Right", "cmc": 3, "colors": ["red"]},
    }

    assert battle.get_card_characteristics(adventure, "stack", cast_mode="adventure")["name"] == "Example Adventure"
    assert battle.get_card_characteristics(adventure, "battlefield")["name"] == "Questing Example"
    assert battle.compute_color_identity(adventure) == ["blue", "green"]
    assert battle.get_card_characteristics(prototype, "stack", cast_mode="prototype")["mana_cost"] == "{1}{R}"
    assert battle.compute_color_identity(prototype) == ["red"]
    assert battle.get_card_characteristics(split, "stack")["name"] == "Right"
    outside_stack = battle.get_card_characteristics(split, "graveyard")
    assert outside_stack["cmc"] == 5
    assert outside_stack["colors"] == ["white", "red"]


def test_adventure_resolves_to_exile_then_casts_creature_from_exile():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(
            "Active",
            deck=[
                {"name": "Drawn 1", "cmc": 1, "type_line": "Creature"},
                {"name": "Drawn 2", "cmc": 1, "type_line": "Creature"},
            ],
        )
        opponent = player("Opponent")
        adventure_card = {
            "name": "Questing Example",
            "mana_cost": "{2}",
            "cmc": 2,
            "colors": ["green"],
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
            "adventure": {
                "name": "Example Adventure",
                "mana_cost": "{1}",
                "cmc": 1,
                "colors": ["blue"],
                "type_line": "Instant - Adventure",
                "tag": "draw",
            },
        }
        active.hand = [adventure_card]
        active.mana_pool.add_generic(1)
        stack = battle.Stack()

        assert battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            phase="precombat_main",
            stack=stack,
            rng=random.Random(600),
            max_actions=1,
        ) is True

        assert active.hand and [card["name"] for card in active.hand] == ["Drawn 1", "Drawn 2"]
        assert len(active.exile) == 1
        assert active.exile[0]["name"] == "Questing Example"
        assert active.exile[0]["_adventure_available"] is True
        assert active.graveyard == []
        assert [event for event, _ in events if event.startswith("adventure")] == [
            "adventure_cast",
            "adventure_exiled",
        ]

        active.mana_pool.add_generic(2)
        assert battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            phase="postcombat_main",
            stack=stack,
            rng=random.Random(601),
            max_actions=1,
        ) is True

        assert active.exile == []
        assert len(active.battlefield) == 1
        assert active.battlefield[0]["name"] == "Questing Example"
        assert active.battlefield[0]["effect"] == "creature"
        assert "adventure_creature_cast_from_exile" in [event for event, _ in events]
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_engine_metrics_collects_core_health_signals():
    metrics = battle.set_engine_metrics(battle.EngineMetrics())
    try:
        stack = battle.Stack()
        stack.push({"name": "Metric Spell", "type_line": "Instant"})
        stack.resolve_top()

        active = player("Active")
        active.life = 5
        active.life_cant_change = True
        assert battle.deal_damage(active, 3) is False

        walker = {
            "name": "Metric Walker",
            "type_line": "Planeswalker",
            "loyalty": 0,
        }
        active.battlefield = [walker]
        battle.check_sbas_until_stable([active])
        battle.priority_round(active, [active], battle.Stack(), 1, random.Random(110), phase="upkeep")

        snapshot = metrics.snapshot()
        assert snapshot["counters"]["stack_pushes"] == 1
        assert snapshot["counters"]["stack_resolutions"] == 1
        assert snapshot["counters"]["replacement_events"] == 1
        assert snapshot["counters"]["sba_iterations"] == 1
        assert snapshot["counters"]["sba_permanent_moves"] == 1
        assert snapshot["counters"]["priority_rounds"] == 1
        assert snapshot["max_stack_depth"] == 1
        assert snapshot["event_counts"]["replacement_applied"] == 1
    finally:
        battle.clear_engine_metrics()


def test_engine_metrics_snapshot_writes_sanitized_json():
    metrics = battle.set_engine_metrics(battle.EngineMetrics())
    try:
        metrics.increment("priority_rounds", 2)
        metrics.record_stack_depth(3)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "metrics.json"
            payload = battle.write_engine_metrics_snapshot(
                str(path),
                {"deck_id": "redacted", "games": 4},
            )
            saved = json.loads(path.read_text(encoding="utf-8"))

        assert payload["schema_version"] == "battle_engine_metrics_v1"
        assert saved["metadata"] == {"deck_id": "redacted", "games": 4}
        assert saved["counters"]["priority_rounds"] == 2
        assert saved["max_stack_depth"] == 3
        assert "created_at" in saved
    finally:
        battle.clear_engine_metrics()


def test_engine_metrics_report_aggregates_sanitized_snapshots():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "one.json").write_text(
            json.dumps(
                {
                    "schema_version": "battle_engine_metrics_v1",
                    "counters": {
                        "stack_pushes": 2,
                        "priority_rounds": 3,
                        "sba_permanent_moves": 1,
                    },
                    "event_counts": {"spell_cast": 2},
                    "max_stack_depth": 4,
                    "warnings": ["short warning"],
                }
            ),
            encoding="utf-8",
        )
        (root / "two.json").write_text(
            json.dumps(
                {
                    "schema_version": "battle_engine_metrics_v1",
                    "counters": {
                        "stack_pushes": 5,
                        "replacement_events": 2,
                    },
                    "event_counts": {"spell_cast": 1, "replacement_applied": 2},
                    "max_stack_depth": 2,
                    "warnings": ["x" * 220],
                }
            ),
            encoding="utf-8",
        )
        (root / "ignore.json").write_text('{"schema_version":"other"}', encoding="utf-8")

        report = engine_metrics_report.aggregate_snapshots(root)

    assert report["schema_version"] == "battle_engine_metrics_report_v1"
    assert report["files_processed"] == 2
    assert report["files_skipped"] == 1
    assert report["totals"]["stack_pushes"] == 7
    assert report["totals"]["priority_rounds"] == 3
    assert report["totals"]["replacement_events"] == 2
    assert report["totals"]["sba_permanent_moves"] == 1
    assert report["event_counts"] == {"replacement_applied": 2, "spell_cast": 3}
    assert report["max_stack_depth"] == 4
    assert len(report["warning_samples"][1]) == 160


def test_conformance_registry_has_executable_coverage():
    covered = {
        "stack_lifo_405",
        "commander_damage_ledger_903_10a",
        "commander_damage_per_origin_903_10a",
        "empty_library_draw_104_3c",
        "token_ceases_outside_battlefield_110_5f",
        "plus_minus_counter_cancel_704_5q",
        "illegal_attachment_sba_704_5m_n",
        "saga_final_chapter_sba_704_5s",
        "zone_change_lki_identity_400_7",
        "exile_visibility_406_3",
        "blocked_stays_blocked_509_1h",
        "end_of_combat_trigger_511_3",
        "apnap_trigger_order_603_3b",
        "prevention_before_damage_615",
        "hybrid_phyrexian_payment_601_2h",
        "commander_vehicle_spacecraft_903_3",
        "hybrid_identity_strict_903",
        "warp_exile_recast_702_185",
        "station_charge_unlock_702_184_721",
        "prepare_copy_from_exile_722",
        "omen_cast_characteristics_720",
        "flashback_exile_replacement_702",
        "multi_defender_attack_commander",
        "modern_ability_words_telemetry",
    }

    scenario_ids = {scenario["id"] for scenario in CONFORMANCE_SCENARIOS}

    assert scenario_ids == covered
    assert all(scenario.get("rule") for scenario in CONFORMANCE_SCENARIOS)
    assert all(scenario.get("purpose") for scenario in CONFORMANCE_SCENARIOS)


def test_conformance_failed_draw_from_empty_library_loses():
    active = player("Active")
    active.hand = [card("Still in hand")]

    assert active.draw(1, random.Random(120)) == []
    assert battle.check_sbas_until_stable([active]) is None

    assert active.eliminated is True
    assert active.life == 0


def test_conformance_blocked_attacker_stays_blocked_after_blocker_leaves():
    attacker = player("Attacker")
    defender = player("Defender")
    attacking_creature = {
        "name": "Blocked Creature",
        "type_line": "Creature",
        "effect": "creature",
        "power": 7,
        "toughness": 7,
    }
    removed_blocker = {
        "name": "Removed Blocker",
        "type_line": "Creature",
        "effect": "creature",
        "power": 1,
        "toughness": 1,
    }
    attacker.battlefield = [attacking_creature]
    defender.battlefield = []

    battle.combat_damage_steps(
        attacker,
        [defender],
        defender,
        [attacking_creature],
        [(attacking_creature, [removed_blocker])],
        turn=3,
    )

    assert defender.life == 40


def test_conformance_apnap_trigger_order_is_lifo_after_stack_placement():
    battle.clear_pending_triggers()
    active = player("Active")
    nonactive = player("Nonactive")
    stack = battle.Stack()

    battle.resolve_or_enqueue_trigger(
        active,
        {"name": "Active Trigger"},
        "test_trigger",
        lambda: None,
        stack=stack,
        active_player=active,
        all_players=[active, nonactive],
    )
    battle.resolve_or_enqueue_trigger(
        nonactive,
        {"name": "Nonactive Trigger"},
        "test_trigger",
        lambda: None,
        stack=stack,
        active_player=active,
        all_players=[active, nonactive],
    )
    battle.flush_triggers_in_apnap(active, [active, nonactive], stack)

    assert [item.card["name"] for item in stack.items] == [
        "Active Trigger",
        "Nonactive Trigger",
    ]
    assert stack.resolve_top().card["name"] == "Nonactive Trigger"
    battle.clear_pending_triggers()


def test_conformance_prevention_applies_before_damage_life_change():
    active = player("Active")
    active.life = 20
    battle.add_damage_prevention_shield(active, 3, source="Conformance Shield")

    assert battle.deal_damage(active, 5) is True

    assert active.life == 18
    assert active.damage_prevention_shields == []


def test_formal_targeting_rejects_opponent_hexproof_creature():
    caster = player("Caster")
    opponent = player("Opponent")
    protected = {
        "name": "Hexproof Creature",
        "type_line": "Creature",
        "effect": "creature",
        "hexproof": True,
    }
    exposed = {
        "name": "Exposed Creature",
        "type_line": "Creature",
        "effect": "creature",
    }
    opponent.battlefield = [protected, exposed]
    spell = {"name": "Targeted Removal", "type_line": "Instant", "colors": ["black"]}

    targets = battle.removal_target_candidates(
        opponent,
        {"effect": "remove_creature", "target": "creature"},
        controller=caster,
        source=spell,
    )

    assert [target["name"] for target in targets] == ["Exposed Creature"]


def test_formal_targeting_respects_protection_from_source_color():
    caster = player("Caster")
    opponent = player("Opponent")
    protected = {
        "name": "White Protected Creature",
        "type_line": "Creature",
        "effect": "creature",
        "protection_from": ["white"],
    }
    opponent.battlefield = [protected]
    white_spell = {"name": "White Removal", "type_line": "Instant", "colors": ["W"]}
    black_spell = {"name": "Black Removal", "type_line": "Instant", "colors": ["B"]}

    assert battle.is_legal_target(
        white_spell,
        protected,
        caster,
        target_type="creature",
        target_controller=opponent,
    ) is False
    assert battle.is_legal_target(
        black_spell,
        protected,
        caster,
        target_type="creature",
        target_controller=opponent,
    ) is True


def test_formal_targeting_keeps_ward_as_legal_target():
    caster = player("Caster")
    opponent = player("Opponent")
    ward_creature = {
        "name": "Ward Creature",
        "type_line": "Creature",
        "effect": "creature",
        "ward": 2,
    }
    spell = {"name": "Removal", "type_line": "Instant", "colors": ["black"]}

    assert battle.is_legal_target(
        spell,
        ward_creature,
        caster,
        target_type="creature",
        target_controller=opponent,
    ) is True


def test_removal_replay_includes_formal_targeting_metadata():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        caster = player("Caster")
        opponent = player("Opponent")
        opponent.battlefield = [
            {
                "name": "Target Creature",
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
        ]
        spell = {
            "name": "Swords to Plowshares",
            "type_line": "Instant",
            "colors": ["W"],
        }

        battle.apply_effect_immediate(caster, [opponent], spell, turn=4, rng=random.Random(121))

        removal_event = next(data for event, data in events if event == "removal_resolved")
        assert removal_event["targeting_pipeline"] == "targeting_formal_minimal"
        assert removal_event["target_name"] == "Target Creature"
        assert removal_event["target_legal"] is True
        assert removal_event["target_type"] == "creature"
        assert removal_event["target_controller"] == "Opponent"
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_multi_target_removal_partially_resolves_legal_targets():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_known = battle.KNOWN_CARDS.get("Forked Removal")
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        caster = player("Caster")
        opponent = player("Opponent")
        legal_target = {
            "name": "Legal Target",
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
        }
        illegal_target = {
            "name": "Illegal Target",
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "shroud": True,
        }
        opponent.battlefield = [legal_target, illegal_target]
        battle.KNOWN_CARDS["Forked Removal"] = {
            "effect": "remove_creature",
            "target": "creature",
            "declared_targets": [
                {"target": legal_target, "controller": opponent},
                {"target": illegal_target, "controller": opponent},
            ],
        }
        spell = {
            "name": "Forked Removal",
            "type_line": "Instant",
            "colors": ["B"],
        }

        battle.apply_effect_immediate(caster, [opponent], spell, turn=6, rng=random.Random(140))

        assert legal_target not in opponent.battlefield
        assert illegal_target in opponent.battlefield
        assert spell in caster.graveyard
        multi_event = next(data for event, data in events if event == "multi_target_resolution")
        assert multi_event["resolved"] == ["Legal Target"]
        assert multi_event["illegal"] == ["Illegal Target"]
    finally:
        if previous_known is None:
            battle.KNOWN_CARDS.pop("Forked Removal", None)
        else:
            battle.KNOWN_CARDS["Forked Removal"] = previous_known
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_ward_counters_targeted_removal_when_unpaid():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        caster = player("Caster")
        opponent = player("Opponent")
        ward_creature = {
            "name": "Ward Creature",
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "ward": 2,
        }
        opponent.battlefield = [ward_creature]
        spell = {
            "name": "Swords to Plowshares",
            "type_line": "Instant",
            "colors": ["W"],
        }

        battle.apply_effect_immediate(caster, [opponent], spell, turn=5, rng=random.Random(130))

        event_names = [event for event, _ in events]
        assert "ward_countered" in event_names
        assert "removal_countered_by_ward" in event_names
        assert "removal_resolved" not in event_names
        assert ward_creature in opponent.battlefield
        assert spell in caster.graveyard
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_ward_paid_allows_targeted_removal_to_resolve():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        caster = player("Caster")
        caster.is_human = True
        caster.mana_pool.add_generic(2)
        opponent = player("Opponent")
        ward_creature = {
            "name": "Ward Creature",
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "ward": 2,
        }
        opponent.battlefield = [ward_creature]
        spell = {
            "name": "Swords to Plowshares",
            "type_line": "Instant",
            "colors": ["W"],
        }

        battle.apply_effect_immediate(caster, [opponent], spell, turn=5, rng=random.Random(131))

        event_names = [event for event, _ in events]
        assert "ward_paid" in event_names
        assert "removal_resolved" in event_names
        assert ward_creature not in opponent.battlefield
        assert caster.available_mana() == 0
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


def test_card_oracle_cache_enriches_battle_cards():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            mana_cost TEXT,
            colors_json TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            power TEXT,
            toughness TEXT,
            keywords_json TEXT,
            scryfall_id TEXT
        )
        """
    )
    conn.execute(
        """
        INSERT INTO card_oracle_cache (
            normalized_name, name, mana_cost, colors_json, color_identity_json,
            type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "test trampler",
            "Test Trampler",
            "{3}{G}",
            json.dumps(["G"]),
            json.dumps(["G"]),
            "Creature - Beast",
            "Trample",
            4,
            "4",
            "4",
            json.dumps(["trample"]),
            "00000000-0000-0000-0000-000000000000",
        ),
    )

    cache = battle.load_card_oracle_cache(conn, ["Test Trampler"])
    enriched = battle.enrich_card(
        battle.merge_oracle_metadata(
            {"name": "Test Trampler", "cmc": 0, "tag": "creature"},
            cache,
        )
    )

    assert enriched["mana_cost"] == "{3}{G}"
    assert enriched["cmc"] == 4
    assert enriched["power"] == 4
    assert enriched["toughness"] == 4
    assert enriched["trample"] is True
    conn.close()


def test_battle_card_rules_table_overrides_fallbacks():
    if battle.battle_rule_registry is None:
        raise AssertionError("battle_rule_registry failed to import")
    old_db = battle.DB
    with tempfile.TemporaryDirectory() as tmp:
        db_path = Path(tmp) / "rules.db"
        conn = sqlite3.connect(db_path)
        battle.battle_rule_registry.upsert_battle_card_rule(
            conn,
            "Registry Counter",
            {"effect": "counter", "instant": True},
            source="manual",
            confidence=1.0,
            review_status="verified",
            notes="Unit test rule.",
        )
        conn.commit()
        conn.close()

        try:
            battle.DB = str(db_path)
            battle.battle_rule_registry._RULE_CACHE.clear()
            effect = battle.get_card_effect(
                {
                    "name": "Registry Counter",
                    "type_line": "Instant",
                    "oracle_text": "A deliberately weird test card.",
                }
            )

            assert effect["effect"] == "counter"
            assert effect["_rule_source"] == "manual"
            assert battle.is_instant({"name": "Registry Counter", "type_line": "Instant"})
        finally:
            battle.DB = old_db
            battle.battle_rule_registry._RULE_CACHE.clear()


def test_lands_are_not_instant_or_sorcery_even_with_generated_metadata():
    land = {
        "name": "Mana Confluence",
        "cmc": 0,
        "type_line": "Land",
        "oracle_text": "{T}: Add one mana of any color.",
        "effect": "land",
        "tag": "land",
    }

    assert battle.is_effective_land(land)
    assert battle.is_instant(land) is False
    assert battle.is_sorcery(land) is False
    assert battle.get_card_effect(land).get("instant") is None


def test_end_step_window_does_not_cast_lands():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active", [card("Draw")])
    opponent = player("Opponent", [card("Opp Draw")])
    opponent.hand = [
        {
            "name": "Mana Confluence",
            "cmc": 0,
            "type_line": "Land",
            "oracle_text": "{T}: Add one mana of any color.",
            "effect": "land",
            "tag": "land",
        }
    ]
    opponent.battlefield = [
        {"name": "Island", "effect": "land", "type_line": "Land"},
        {"name": "Island", "effect": "land", "type_line": "Land"},
    ]

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=3,
        rng=random.Random(32),
        stack=battle.Stack(),
    )
    battle.REPLAY_EVENT_HANDLER = None

    assert not [
        data
        for event, data in events
        if event == "end_step_instant" and data.get("effect") == "land"
    ]


def test_summoning_sick_creature_cannot_attack_until_next_turn():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    creature = {
        "name": "Fresh Creature",
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "summoning_sick": True,
        "tapped": False,
    }
    attacker.battlefield = [creature]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(33),
        stack=battle.Stack(),
    )
    battle.REPLAY_EVENT_HANDLER = None

    assert creature["tapped"] is False
    assert defender.life == 40
    assert not [event for event, _ in events if event == "combat"]


def test_creature_loses_summoning_sickness_at_start_of_controller_turn_and_taps_to_attack():
    active = player("Active", [card("Draw")])
    defender = player("Defender", [card("Opp Draw")])
    creature = {
        "name": "Ready Next Turn",
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "summoning_sick": True,
        "tapped": False,
    }
    active.battlefield = [creature]

    battle.play_turn_v8(
        active,
        [defender],
        [active, defender],
        turn=3,
        rng=random.Random(34),
        stack=battle.Stack(),
    )

    assert creature["summoning_sick"] is False
    assert creature["tapped"] is True
    assert defender.life == 37


def test_haste_creature_can_attack_while_summoning_sick_and_taps():
    attacker = player("Attacker")
    defender = player("Defender")
    creature = battle.enrich_card({
        "name": "Hasty Creature",
        "effect": "creature",
        "type_line": "Creature",
        "oracle_text": "Haste",
        "power": 4,
        "toughness": 4,
        "summoning_sick": True,
        "tapped": False,
    })
    attacker.battlefield = [creature]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(35),
        stack=battle.Stack(),
    )

    assert attacker.battlefield[0]["tapped"] is True
    assert defender.life == 36


def test_vigilance_creature_attacks_without_tapping():
    attacker = player("Attacker")
    defender = player("Defender")
    creature = battle.enrich_card({
        "name": "Vigilant Creature",
        "effect": "creature",
        "type_line": "Creature",
        "oracle_text": "Vigilance",
        "power": 3,
        "toughness": 3,
        "summoning_sick": False,
        "tapped": False,
    })
    attacker.battlefield = [creature]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(44),
        stack=battle.Stack(),
    )

    assert attacker.battlefield[0]["tapped"] is False
    assert defender.life == 37


def test_engine_creature_enters_with_summoning_sickness():
    active = player("Active")
    defender = player("Defender")
    battle.apply_effect_immediate(
        active,
        [defender],
        {
            "name": "Jin-Gitaxias, Progress Tyrant",
            "cmc": 7,
            "type_line": "Legendary Creature — Phyrexian Praetor",
            "oracle_text": "Whenever you cast an artifact, instant, or sorcery spell, copy that spell.",
            "power": 5,
            "toughness": 5,
        },
        turn=2,
        rng=random.Random(67),
    )

    permanent = active.battlefield[0]
    assert battle.is_battlefield_creature(permanent) is True
    assert permanent["effect"] == "copy_spell"
    assert permanent["summoning_sick"] is True
    assert permanent["tapped"] is False

    battle.combat_phase_v8(active, [defender], [active, defender], 2, random.Random(68), battle.Stack())

    assert permanent["tapped"] is False
    assert defender.life == 40


def test_permanent_activated_removal_text_does_not_become_free_removal():
    staff = {
        "name": "Staff of Compleation",
        "type_line": "Artifact",
        "oracle_text": "{T}, Pay 3 life: Destroy target permanent you own.",
    }
    lantern = {
        "name": "Soul-Guide Lantern",
        "type_line": "Artifact",
        "oracle_text": "When this artifact enters, exile target card from a graveyard.",
    }
    speaker = {
        "name": "Formidable Speaker",
        "type_line": "Creature — Elf Druid",
        "oracle_text": "When this creature enters, you may discard a card. If you do, search your library for a creature card.",
        "power": 2,
        "toughness": 4,
    }

    assert battle.get_card_effect(staff)["effect"] == "ramp_permanent"
    assert battle.get_card_effect(lantern)["effect"] == "hate_artifact"
    assert battle.get_card_effect(speaker)["effect"] == "creature"


def test_contextual_haste_text_does_not_grant_self_haste():
    rionya = battle.enrich_card({
        "name": "Rionya, Fire Dancer",
        "type_line": "Legendary Creature — Human Wizard",
        "oracle_text": "At the beginning of combat on your turn, create X tokens. They gain haste.",
        "keywords": ["haste"],
    })
    spider_punk = battle.enrich_card({
        "name": "Spider-Punk",
        "type_line": "Creature",
        "oracle_text": "Haste",
        "keywords": ["haste"],
    })

    assert battle.has_haste(rionya) is False
    assert battle.has_haste(spider_punk) is True


def test_token_destroyed_by_board_wipe_does_not_remain_in_graveyard():
    active = player("Active")
    token = battle.create_creature_token(active, name="Soldier Token", power=1, toughness=1)
    previous = battle.KNOWN_CARDS.get("Wrath")
    was_handcrafted = "Wrath" in battle.HANDCRAFTED_KNOWN_CARDS
    try:
        battle.KNOWN_CARDS["Wrath"] = {"effect": "board_wipe"}
        battle.HANDCRAFTED_KNOWN_CARDS.add("Wrath")
        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Wrath", "cmc": 4, "type_line": "Sorcery"},
            turn=6,
            rng=random.Random(70),
        )
    finally:
        if previous is None:
            battle.KNOWN_CARDS.pop("Wrath", None)
        else:
            battle.KNOWN_CARDS["Wrath"] = previous
        if not was_handcrafted:
            battle.HANDCRAFTED_KNOWN_CARDS.discard("Wrath")

    assert token not in active.battlefield
    assert token not in active.graveyard


def test_token_sba_removes_tokens_from_non_battlefield_zones():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    token_in_hand = {
        "name": "Hand Token",
        "is_token": True,
        "effect": "creature",
        "type_line": "Creature Token",
    }
    token_in_exile = {
        "name": "Exile Token",
        "tag": "token",
        "effect": "creature",
        "type_line": "Creature Token",
    }
    active.hand = [token_in_hand]
    active.exile = [token_in_exile]

    battle.check_sbas_until_stable([active])

    assert token_in_hand not in active.hand
    assert token_in_exile not in active.exile
    assert [event for event, _ in events].count("token_ceased_to_exist") == 2


def test_artifact_removal_does_not_destroy_creature_target_by_mistake():
    caster = player("Caster")
    opponent = player("Opponent")
    creature = battle.enrich_card({
        "name": "Real Creature",
        "effect": "creature",
        "type_line": "Creature",
        "power": 6,
        "toughness": 6,
    })
    artifact = battle.enrich_card({
        "name": "Mana Rock",
        "effect": "ramp_permanent",
        "type_line": "Artifact",
        "mana_produced": 1,
    })
    opponent.battlefield = [creature, artifact]
    opponent.life = 35

    battle.apply_effect_immediate(
        caster,
        [opponent],
        {"name": "Nature's Claim", "cmc": 1, "type_line": "Instant"},
        turn=7,
        rng=random.Random(71),
    )

    assert creature in opponent.battlefield
    assert artifact not in opponent.battlefield
    assert artifact in opponent.graveyard
    assert opponent.life == 39


def test_land_ramp_puts_library_land_tapped_and_spell_goes_to_graveyard():
    active = player("Active")
    forest = {"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}
    spell = {"name": "Rampant Growth", "cmc": 2, "type_line": "Sorcery"}
    active.library = [forest]

    battle.apply_effect_immediate(active, [], spell, turn=8, rng=random.Random(72))

    assert spell in active.graveyard
    assert forest not in active.library
    assert any(
        card.get("name") == "Forest" and card.get("tapped") is True
        for card in active.battlefield
        if isinstance(card, dict)
    )
    assert not any(card.get("name") == "Rampant Growth" for card in active.battlefield if isinstance(card, dict))


def test_land_recursion_returns_graveyard_lands_tapped():
    active = player("Active")
    plains = {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"}
    spell = {"name": "Splendid Reclamation", "cmc": 4, "type_line": "Sorcery"}
    active.graveyard = [plains]

    battle.apply_effect_immediate(active, [], spell, turn=9, rng=random.Random(73))

    assert plains not in active.graveyard
    assert spell in active.graveyard
    assert any(
        card.get("name") == "Plains" and card.get("tapped") is True
        for card in active.battlefield
        if isinstance(card, dict)
    )


def test_passive_permanent_does_not_draw_or_make_mana_on_resolution():
    active = player("Active")
    active.library = [card("Future Draw", cmc=1)]
    skullclamp = {"name": "Skullclamp", "cmc": 1, "type_line": "Artifact — Equipment"}

    battle.apply_effect_immediate(active, [], skullclamp, turn=10, rng=random.Random(74))

    assert len(active.library) == 1
    assert active.available_mana() == 0
    assert any(
        permanent.get("name") == "Skullclamp" and permanent.get("effect") == "passive"
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )


def test_tutor_to_graveyard_moves_library_card_without_drawing():
    active = player("Active")
    target = {"name": "Graveyard Target", "cmc": 7, "type_line": "Creature", "effect": "creature"}
    active.library = [target, card("Small Card", cmc=1)]
    entomb = {"name": "Entomb", "cmc": 1, "type_line": "Instant"}

    battle.apply_effect_immediate(active, [], entomb, turn=10, rng=random.Random(75))

    assert target not in active.library
    assert target in active.graveyard
    assert entomb in active.graveyard
    assert active.hand == []


def test_mystical_tutor_finds_instant_or_sorcery_only():
    active = player("Active")
    creature = {"name": "Large Creature", "cmc": 9, "type_line": "Creature", "effect": "creature"}
    instant = {"name": "Target Instant", "cmc": 2, "type_line": "Instant", "effect": "counter"}
    sorcery = {"name": "Target Sorcery", "cmc": 4, "type_line": "Sorcery", "effect": "draw_cards"}
    active.library = [creature, instant, sorcery]
    mystical = {"name": "Mystical Tutor", "cmc": 1, "type_line": "Instant"}

    battle.apply_effect_immediate(active, [], mystical, turn=10, rng=random.Random(77))

    assert creature in active.library
    assert sorcery not in active.library
    assert sorcery in active.hand
    assert mystical in active.graveyard


def test_reanimation_recursion_returns_creature_to_battlefield():
    active = player("Active")
    target = {
        "name": "Reanimated Creature",
        "cmc": 4,
        "type_line": "Creature",
        "effect": "creature",
        "power": 4,
        "toughness": 4,
    }
    reanimate = {"name": "Reanimate", "cmc": 1, "type_line": "Sorcery"}
    active.graveyard = [target]

    battle.apply_effect_immediate(active, [], reanimate, turn=10, rng=random.Random(76))

    assert target not in active.graveyard
    assert reanimate in active.graveyard
    assert any(
        permanent.get("name") == "Reanimated Creature"
        and permanent.get("effect") == "creature"
        and permanent.get("summoning_sick") is True
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )


def test_failed_draw_from_empty_library_loses_even_with_cards_in_hand():
    active = player("Active")
    active.hand = [card("Still in hand")]

    drawn = active.draw(1, random.Random(45))
    eliminated = battle.check_sbas([active])

    assert drawn == []
    assert eliminated is True
    assert active.eliminated is True
    assert active.life == 0


def test_classify_loss_covers_poison_effect_and_concede_tags():
    loser = player("Loser")
    loser.poison = 10
    loser.lost_by_effect = True
    loser.conceded = True

    tags = battle.classify_loss(loser, [], turn=5, result="loss", reason="test")

    assert tags[:3] == ["concede", "effect_says_lose", "poison"]
    assert battle.classify_loss(loser, [], turn=5, result="win", reason="test") == []


def test_extra_turns_are_taken_before_next_player():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active", [card("Draw 1"), card("Draw 2"), card("Draw 3")])
    defender = player("Defender", [card("Opp Draw")])
    active.extra_turns = 1

    battle.play_turn_sequence_v8(
        active,
        [defender],
        [active, defender],
        turn=4,
        rng=random.Random(46),
        stack=battle.Stack(),
    )
    battle.REPLAY_EVENT_HANDLER = None

    assert active.extra_turns == 0
    assert [event for event, _ in events].count("turn_start") == 2
    assert any(event == "extra_turn_taken" for event, _ in events)


def test_token_maker_tokens_are_sick_unless_rule_grants_haste():
    active = player("Active")
    defender = player("Defender")
    token_spell = {"name": "Token Maker", "cmc": 4, "type_line": "Sorcery"}

    previous_normal = battle.KNOWN_CARDS.get("Token Maker")
    previous_hasty = battle.KNOWN_CARDS.get("Hasty Token Maker")
    normal_was_handcrafted = "Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
    hasty_was_handcrafted = "Hasty Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
    try:
        battle.KNOWN_CARDS["Token Maker"] = {
            "effect": "token_maker",
            "token_count": 1,
            "token_power": 2,
        }
        battle.KNOWN_CARDS["Hasty Token Maker"] = {
            "effect": "token_maker",
            "token_count": 1,
            "token_power": 2,
            "token_haste": True,
        }
        battle.HANDCRAFTED_KNOWN_CARDS.update({"Token Maker", "Hasty Token Maker"})

        battle.apply_effect_immediate(active, [defender], token_spell, 2, random.Random(36))
        token = active.battlefield[0]
        assert token["summoning_sick"] is True
        battle.combat_phase_v8(active, [defender], [active, defender], 2, random.Random(36), battle.Stack())
        assert token["tapped"] is False
        assert defender.life == 40

        hasty = player("Hasty")
        hasty_spell = {**token_spell, "name": "Hasty Token Maker"}
        battle.apply_effect_immediate(hasty, [defender], hasty_spell, 2, random.Random(37))
        assert hasty.battlefield[0]["summoning_sick"] is False
        assert hasty.battlefield[0]["haste"] is True
        battle.combat_phase_v8(hasty, [defender], [hasty, defender], 2, random.Random(37), battle.Stack())
        assert hasty.battlefield[0]["tapped"] is True
    finally:
        if previous_normal is None:
            battle.KNOWN_CARDS.pop("Token Maker", None)
        else:
            battle.KNOWN_CARDS["Token Maker"] = previous_normal
        if previous_hasty is None:
            battle.KNOWN_CARDS.pop("Hasty Token Maker", None)
        else:
            battle.KNOWN_CARDS["Hasty Token Maker"] = previous_hasty
        if not normal_was_handcrafted:
            battle.HANDCRAFTED_KNOWN_CARDS.discard("Token Maker")
        if not hasty_was_handcrafted:
            battle.HANDCRAFTED_KNOWN_CARDS.discard("Hasty Token Maker")


def test_token_maker_counts_dict_lands_for_land_based_tokens():
    active = player("Active")
    active.battlefield = [
        {"name": "Plains", "type_line": "Basic Land — Plains", "effect": "land"},
        {"name": "Mountain", "type_line": "Basic Land — Mountain", "effect": "land"},
        {"name": "Arcane Signet", "type_line": "Artifact", "effect": "ramp_permanent"},
    ]
    previous = battle.KNOWN_CARDS.get("Land Count Token Maker")
    was_handcrafted = "Land Count Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
    try:
        battle.KNOWN_CARDS["Land Count Token Maker"] = {
            "effect": "token_maker",
            "token_count": "lands",
            "token_power": 1,
        }
        battle.HANDCRAFTED_KNOWN_CARDS.add("Land Count Token Maker")
        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Land Count Token Maker", "cmc": 4, "type_line": "Sorcery"},
            6,
            random.Random(43),
        )
        tokens = [c for c in active.battlefield if isinstance(c, dict) and c.get("name") == "Token"]
        assert len(tokens) == 2
    finally:
        if previous is None:
            battle.KNOWN_CARDS.pop("Land Count Token Maker", None)
        else:
            battle.KNOWN_CARDS["Land Count Token Maker"] = previous
        if not was_handcrafted:
            battle.HANDCRAFTED_KNOWN_CARDS.discard("Land Count Token Maker")


def test_lumra_returns_milled_and_graveyard_lands_tapped():
    active = player("Lumra")
    active.battlefield = [
        {"name": "Forest", "type_line": "Basic Land — Forest", "effect": "land"},
        {"name": "Mosswort Bridge", "type_line": "Land", "effect": "land"},
    ]
    active.graveyard = [
        {"name": "Fabled Passage", "type_line": "Land", "effect": "land"},
        {"name": "Cultivate", "type_line": "Sorcery", "effect": "ramp_permanent"},
    ]
    active.library = [
        {"name": "Boseiju, Who Endures", "type_line": "Legendary Land", "effect": "land"},
        {"name": "Rampant Growth", "type_line": "Sorcery", "effect": "ramp_permanent"},
        {"name": "Yavimaya, Cradle of Growth", "type_line": "Legendary Land", "effect": "land"},
        {"name": "Explore", "type_line": "Sorcery", "effect": "draw_cards"},
    ]
    lumra = {
        "name": "Lumra, Bellow of the Woods",
        "cmc": 6,
        "type_line": "Legendary Creature — Elemental Bear",
        "oracle_text": "Vigilance, reach\nLumra's power and toughness are each equal to the number of lands you control.\nWhen Lumra enters, mill four cards. Then return all land cards from your graveyard to the battlefield tapped.",
    }

    battle.apply_effect_immediate(active, [], lumra, 4, random.Random(40))

    permanent = next(c for c in active.battlefield if isinstance(c, dict) and c.get("name") == "Lumra, Bellow of the Woods")
    returned_names = {c.get("name") for c in active.battlefield if isinstance(c, dict) and c.get("tapped")}
    assert {"Fabled Passage", "Boseiju, Who Endures", "Yavimaya, Cradle of Growth"} <= returned_names
    assert permanent["power"] == 5
    assert permanent["toughness"] == 5
    assert permanent["summoning_sick"] is True


def test_zuran_orb_is_life_artifact_not_mana_rock():
    active = player("Active")
    zuran = {
        "name": "Zuran Orb",
        "cmc": 0,
        "type_line": "Artifact",
        "oracle_text": "Sacrifice a land: You gain 2 life.",
    }

    effect = battle.get_card_effect(zuran)
    assert effect["effect"] == "life_artifact"
    assert effect["_rule_review_status"] == "verified"
    battle.apply_effect_immediate(active, [], zuran, 5, random.Random(41))

    permanent = active.battlefield[0]
    assert permanent["effect"] == "life_artifact"
    assert "mana_produced" not in permanent
    assert active.available_mana() == 0


def test_vexing_bauble_is_hate_artifact_not_immediate_draw():
    active = player("Active", [card("Top card")])
    bauble = {
        "name": "Vexing Bauble",
        "cmc": 1,
        "type_line": "Artifact",
        "oracle_text": "Whenever a player casts a spell, if no mana was spent to cast it, counter that spell.\n{1}, {T}, Sacrifice Vexing Bauble: Draw a card.",
    }

    effect = battle.get_card_effect(bauble)
    assert effect["effect"] == "hate_artifact"
    assert effect["_rule_review_status"] == "verified"
    before_hand = len(active.hand)
    battle.apply_effect_immediate(active, [], bauble, 6, random.Random(42))

    permanent = active.battlefield[0]
    assert permanent["effect"] == "hate_artifact"
    assert permanent["counters_free_spells"] is True
    assert len(active.hand) == before_hand


def test_protected_player_prevents_combat_damage_without_audit_finding():
    events = []
    battle.REPLAY_EVENT_HANDLER = (
        lambda event, data: events.append({"event": event, "replay_id": "protected", **data})
    )
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 1
    defender.life_cant_change = True
    defender.protection_from_everything = True
    attacker.battlefield = [
        {
            "name": "Unblocked Attacker",
            "effect": "creature",
            "power": 5,
            "toughness": 5,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=4,
        rng=random.Random(43),
        stack=battle.Stack(),
    )

    combat_result = next(event for event in events if event["event"] == "combat_result")
    assert defender.life == 1
    assert combat_result["damage_to_player"] == 0
    assert combat_result["target_protection_from_everything"] is True
    findings = replay_auditor.audit_turn_events(events)
    assert not [
        finding
        for finding in findings
        if "Unblocked combat dealt 0" in finding["finding"]
        or "Unblocked lethal-looking combat" in finding["finding"]
    ]


def test_springheart_landfall_creates_sick_insect_token():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    nantuko = battle.enrich_card(
        {
            "name": "Springheart Nantuko",
            "effect": "creature",
            "type_line": "Enchantment Creature — Insect Monk",
            "power": 1,
            "toughness": 1,
            "landfall_token_maker": True,
            "token_power": 1,
            "token_toughness": 1,
        }
    )
    land = {"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}
    active.battlefield = [nantuko, land]

    battle.trigger_landfall(active, land, turn=3, source_event="test_land_played")

    tokens = [card for card in active.battlefield if card.get("name") == "Insect Token"]
    assert len(tokens) == 1
    assert tokens[0]["power"] == 1
    assert tokens[0]["summoning_sick"] is True
    trigger = next(data for event, data in events if event == "trigger_resolved")
    assert trigger["trigger"] == "landfall"
    assert trigger["tokens_created"] == 1


def test_creature_mana_source_has_summoning_sickness_then_refreshes_mana():
    active = player("Active")
    plague_myr = {
        "name": "Plague Myr",
        "effect": "creature",
        "type_line": "Artifact Creature — Phyrexian Myr",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
    }
    active.hand = [plague_myr]
    active.battlefield = [{"name": "Wastes", "effect": "land", "type_line": "Basic Land"} for _ in range(2)]
    active.refresh_mana_sources(turn=1)
    active.spend_card_mana(plague_myr)
    active.hand.remove(plague_myr)
    permanent = battle.enrich_card({**plague_myr, **battle.get_card_effect(plague_myr)})
    permanent["effect"] = "creature"
    permanent["summoning_sick"] = True
    permanent["tapped"] = False
    active.battlefield.append(permanent)

    assert active.untapped_creatures() == []
    active.refresh_mana_sources(turn=1)
    assert active.available_mana() == 2
    permanent["summoning_sick"] = False
    active.refresh_mana_sources(turn=2)
    assert active.available_mana() == 3


def test_elvish_reclaimer_cannot_activate_while_summoning_sick():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    active.library = [{"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}]
    active.battlefield = [
        {"name": "Forest A", "effect": "land", "type_line": "Basic Land — Forest"},
        {"name": "Forest B", "effect": "land", "type_line": "Basic Land — Forest"},
        {
            "name": "Elvish Reclaimer",
            "effect": "creature",
            "type_line": "Creature — Elf Warrior",
            "power": 1,
            "toughness": 2,
            "land_tutor_activated": True,
            "summoning_sick": True,
            "tapped": False,
        },
    ]
    active.refresh_mana_sources(turn=1)

    battle.activate_land_tutor_creatures(active, turn=1)

    assert len(active.library) == 1
    assert not [event for event, _ in events if event == "activated_ability"]


def test_elvish_reclaimer_activates_after_sickness_clears():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    active.library = [{"name": "Forest", "effect": "land", "type_line": "Basic Land — Forest"}]
    reclaimer = {
        "name": "Elvish Reclaimer",
        "effect": "creature",
        "type_line": "Creature — Elf Warrior",
        "power": 1,
        "toughness": 2,
        "land_tutor_activated": True,
        "summoning_sick": False,
        "tapped": False,
    }
    active.battlefield = [
        {"name": "Forest A", "effect": "land", "type_line": "Basic Land — Forest"},
        {"name": "Forest B", "effect": "land", "type_line": "Basic Land — Forest"},
        reclaimer,
    ]
    active.refresh_mana_sources(turn=2)

    battle.activate_land_tutor_creatures(active, turn=2)

    assert active.library == []
    assert reclaimer["tapped"] is True
    assert any(event == "activated_ability" for event, _ in events)


def test_known_land_name_without_oracle_imports_as_land_not_creature():
    imported = battle.build_learned_battle_card({"name": "High Market"}, oracle_cache={})

    assert imported["effect"] == "land"
    assert imported["type_line"] == "Land"
    assert battle.is_battlefield_creature(imported) is False


def test_unknown_card_without_oracle_does_not_default_to_creature():
    imported = battle.build_learned_battle_card({"name": "Mystery Card"}, oracle_cache={})

    assert imported["effect"] == "unknown"
    assert imported["type_line"] == ""
    assert battle.is_battlefield_creature(imported) is False


def test_auditor_flags_noncreature_land_attacker():
    events = [
        {
            "event": "combat",
            "replay_id": "land_bug",
            "turn": 2,
            "attacker": "Player A",
            "target": "Player B",
            "attackers_detail": [
                {
                    "name": "Forest",
                    "type_line": "Land",
                    "tapped": True,
                    "summoning_sick": False,
                    "keywords": [],
                }
            ],
        }
    ]

    findings = replay_auditor.audit_turn_events(events)

    assert any("Non-creature land attacked" in finding["finding"] for finding in findings)


def test_zero_power_creature_without_attack_trigger_does_not_attack():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    attacker.battlefield = [
        {
            "name": "Birds of Paradise",
            "effect": "creature",
            "type_line": "Creature — Bird",
            "power": 0,
            "toughness": 1,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=3,
        rng=random.Random(44),
        stack=battle.Stack(),
    )

    assert not [event for event, _ in events if event == "combat"]
    assert attacker.battlefield[0]["tapped"] is False
    assert defender.life == 40


def test_treasure_maker_can_discard_draw_and_create_treasures():
    active = player("Caster")
    active.hand = [{"name": "Discard Me", "cmc": 1, "type_line": "Sorcery"}]
    active.library = [
        {"name": "Drawn A", "cmc": 1, "type_line": "Instant"},
        {"name": "Drawn B", "cmc": 2, "type_line": "Sorcery"},
    ]

    battle.apply_effect_immediate(
        active,
        [],
        {"name": "Unexpected Windfall", "cmc": 4, "type_line": "Instant"},
        turn=4,
        rng=random.Random(9),
    )

    assert active.treasures == 2
    assert [card["name"] for card in active.hand] == ["Drawn A", "Drawn B"]
    assert [card["name"] for card in active.graveyard] == [
        "Discard Me",
        "Unexpected Windfall",
    ]


def test_rule_sync_oracle_normalizes_generated_land_rules():
    sync_path = MODULE_PATH.with_name("sync_battle_card_rules.py")
    sync_spec = importlib.util.spec_from_file_location("sync_rules_under_test", sync_path)
    sync_rules = importlib.util.module_from_spec(sync_spec)
    sync_spec.loader.exec_module(sync_rules)

    with tempfile.TemporaryDirectory() as tmp_dir:
        db_path = str(Path(tmp_dir) / "rules.db")
        conn = sqlite3.connect(db_path)
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              power TEXT,
              toughness TEXT,
              keywords_json TEXT,
              scryfall_id TEXT
            )
            """
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache (
              normalized_name, name, type_line, oracle_text, cmc,
              colors_json, color_identity_json, keywords_json
            )
            VALUES ('mystery land', 'Mystery Land', 'Land', '', 0, '[]', '[]', '[]')
            """
        )
        conn.commit()
        conn.close()

        rows = sync_rules._oracle_normalized_rows(
            db_path,
            [
                {
                    "card_name": "Mystery Land",
                    "effect_json": {"effect": "ramp_permanent"},
                    "source": "generated",
                    "confidence": 0.55,
                    "review_status": "needs_review",
                    "notes": "",
                }
            ],
        )

    assert rows[0]["effect_json"]["effect"] == "land"
    assert rows[0]["_oracle_normalized"] is True


def test_apnap_trigger_order_puts_nonactive_trigger_on_top():
    if not hasattr(battle, "clear_pending_triggers"):
        return

    battle.clear_pending_triggers()
    events = []
    active = player("Active")
    opponent = player("Opponent")
    stack = battle.Stack()

    battle.resolve_or_enqueue_trigger(
        active,
        {"name": "Active Trigger Source"},
        "active_test_trigger",
        lambda: events.append("active"),
        stack=stack,
        active_player=active,
        all_players=[active, opponent],
    )
    battle.resolve_or_enqueue_trigger(
        opponent,
        {"name": "Opponent Trigger Source"},
        "opponent_test_trigger",
        lambda: events.append("opponent"),
        stack=stack,
        active_player=active,
        all_players=[active, opponent],
    )

    assert battle.flush_triggers_in_apnap(active, [active, opponent], stack) == 2
    assert [item.effect_data["trigger"] for item in stack.items] == [
        "active_test_trigger",
        "opponent_test_trigger",
    ]

    battle.priority_round(active, [active, opponent], stack, 1, random.Random(100))
    assert events == ["opponent"]
    battle.priority_round(active, [active, opponent], stack, 1, random.Random(101))
    assert events == ["opponent", "active"]


def test_same_controller_triggers_keep_timestamp_stack_order():
    if not hasattr(battle, "clear_pending_triggers"):
        return

    battle.clear_pending_triggers()
    active = player("Active")
    stack = battle.Stack()

    battle.resolve_or_enqueue_trigger(
        active,
        {"name": "First"},
        "first_trigger",
        lambda: None,
        stack=stack,
        active_player=active,
        all_players=[active],
    )
    battle.resolve_or_enqueue_trigger(
        active,
        {"name": "Second"},
        "second_trigger",
        lambda: None,
        stack=stack,
        active_player=active,
        all_players=[active],
    )

    battle.flush_triggers_in_apnap(active, [active], stack)

    assert [item.card["name"] for item in stack.items] == ["First", "Second"]


def test_spell_cast_trigger_resolves_from_stack_before_spell():
    if not hasattr(battle, "clear_pending_triggers"):
        return

    battle.clear_pending_triggers()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player("Active", [card("Drawn")])
        opponent = player("Opponent", [card("Opp Drawn")])
        active.battlefield = [
            {
                "name": "Guttersnipe",
                "effect": "creature",
                "type_line": "Creature",
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "damage_each_opponent",
                "damage": 2,
            }
        ]
        spell = {
            "name": "Test Sorcery",
            "cmc": 2,
            "effect": "draw",
            "type_line": "Sorcery",
        }
        stack = battle.Stack()

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell,
            turn=1,
            phase="precombat_main",
            stack=stack,
            active_player=active,
        )
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active, opponent], stack, 1, random.Random(102))
        assert opponent.life == 38
        assert stack.items[-1].card["name"] == "Test Sorcery"
        battle.priority_round(active, [active, opponent], stack, 1, random.Random(103))
        assert stack.empty()

        event_names = [event for event, _ in events]
        assert event_names.index("trigger_resolved") < event_names.index("spell_resolved")
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler


if __name__ == "__main__":
    tests = [
        test_sba_only_reports_new_elimination,
        test_cleanup_runs_with_previously_eliminated_player,
        test_plus_minus_counters_cancel_as_sba,
        test_illegal_aura_goes_to_graveyard_and_equipment_detaches,
        test_saga_final_chapter_sacrifices_after_pending_ability_resolves,
        test_zone_change_records_lki_and_advances_zone_identity,
        test_exile_records_face_up_and_face_down_visibility,
        test_draw_step_runs_once_with_multiple_permanents,
        test_approach_sets_explicit_win_state,
        test_combat_emits_structured_event,
        test_end_of_combat_triggers_use_stack_and_apnap_order,
        test_turn_stops_immediately_after_approach_win,
        *battle_mana_tests.register_tests(battle, player),
        *battle_stack_casting_tests.register_tests(battle, player),
        test_continuous_effects_apply_layers_and_sublayers_in_order,
        test_continuous_effects_apply_type_color_text_and_ability_layers,
        test_continuous_effect_dependencies_override_timestamp_within_layer,
        test_planeswalker_loyalty_activation_damage_and_sba,
        test_battle_defense_damage_and_sba,
        test_battle_defeated_casts_back_face,
        test_dfc_characteristics_and_color_identity_use_all_faces,
        test_adventure_prototype_and_split_characteristics_by_cast_mode,
        test_adventure_resolves_to_exile_then_casts_creature_from_exile,
        test_engine_metrics_collects_core_health_signals,
        test_engine_metrics_snapshot_writes_sanitized_json,
        test_engine_metrics_report_aggregates_sanitized_snapshots,
        *battle_rules_2026_tests.register_tests(battle, player),
        test_conformance_registry_has_executable_coverage,
        *battle_commander_tests.register_tests(battle, player),
        test_conformance_failed_draw_from_empty_library_loses,
        test_conformance_blocked_attacker_stays_blocked_after_blocker_leaves,
        test_conformance_apnap_trigger_order_is_lifo_after_stack_placement,
        test_conformance_prevention_applies_before_damage_life_change,
        test_formal_targeting_rejects_opponent_hexproof_creature,
        test_formal_targeting_respects_protection_from_source_color,
        test_formal_targeting_keeps_ward_as_legal_target,
        test_removal_replay_includes_formal_targeting_metadata,
        test_multi_target_removal_partially_resolves_legal_targets,
        test_ward_counters_targeted_removal_when_unpaid,
        test_ward_paid_allows_targeted_removal_to_resolve,
        *battle_combat_tests.register_tests(battle, player),
        test_card_oracle_cache_enriches_battle_cards,
        test_battle_card_rules_table_overrides_fallbacks,
        *battle_card_specific_tests.register_tests(battle, player),
        *battle_replacement_tests.register_tests(battle, player),
        test_lands_are_not_instant_or_sorcery_even_with_generated_metadata,
        test_end_step_window_does_not_cast_lands,
        test_summoning_sick_creature_cannot_attack_until_next_turn,
        test_creature_loses_summoning_sickness_at_start_of_controller_turn_and_taps_to_attack,
        test_haste_creature_can_attack_while_summoning_sick_and_taps,
        test_vigilance_creature_attacks_without_tapping,
        test_engine_creature_enters_with_summoning_sickness,
        test_permanent_activated_removal_text_does_not_become_free_removal,
        test_contextual_haste_text_does_not_grant_self_haste,
        test_token_destroyed_by_board_wipe_does_not_remain_in_graveyard,
        test_token_sba_removes_tokens_from_non_battlefield_zones,
        test_artifact_removal_does_not_destroy_creature_target_by_mistake,
        test_land_ramp_puts_library_land_tapped_and_spell_goes_to_graveyard,
        test_land_recursion_returns_graveyard_lands_tapped,
        test_passive_permanent_does_not_draw_or_make_mana_on_resolution,
        test_tutor_to_graveyard_moves_library_card_without_drawing,
        test_mystical_tutor_finds_instant_or_sorcery_only,
        test_reanimation_recursion_returns_creature_to_battlefield,
        test_failed_draw_from_empty_library_loses_even_with_cards_in_hand,
        test_classify_loss_covers_poison_effect_and_concede_tags,
        test_extra_turns_are_taken_before_next_player,
        test_token_maker_tokens_are_sick_unless_rule_grants_haste,
        test_token_maker_counts_dict_lands_for_land_based_tokens,
        test_lumra_returns_milled_and_graveyard_lands_tapped,
        test_zuran_orb_is_life_artifact_not_mana_rock,
        test_vexing_bauble_is_hate_artifact_not_immediate_draw,
        test_protected_player_prevents_combat_damage_without_audit_finding,
        test_springheart_landfall_creates_sick_insect_token,
        test_creature_mana_source_has_summoning_sickness_then_refreshes_mana,
        test_elvish_reclaimer_cannot_activate_while_summoning_sick,
        test_elvish_reclaimer_activates_after_sickness_clears,
        test_known_land_name_without_oracle_imports_as_land_not_creature,
        test_unknown_card_without_oracle_does_not_default_to_creature,
        test_auditor_flags_noncreature_land_attacker,
        test_zero_power_creature_without_attack_trigger_does_not_attack,
        test_treasure_maker_can_discard_draw_and_create_treasures,
        test_rule_sync_oracle_normalizes_generated_land_rules,
        test_apnap_trigger_order_puts_nonactive_trigger_on_top,
        test_same_controller_triggers_keep_timestamp_stack_order,
        test_spell_cast_trigger_resolves_from_stack_before_spell,
    ]
    for test in tests:
        if hasattr(battle, "clear_pending_triggers"):
            battle.clear_pending_triggers()
        test()
        print(f"PASS {test.__name__}")
