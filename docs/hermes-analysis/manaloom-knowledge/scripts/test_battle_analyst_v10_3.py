#!/usr/bin/env python3
"""Focused regression checks for the active battle_analyst_v9 engine.

The filename preserves the historical v10.3 replay-suite label, but
MODULE_PATH defaults to battle_analyst_v9.py unless BATTLE_ANALYST_PATH is set.

Run from this directory with:
    python3 test_battle_analyst_v10_3.py
"""

import importlib.util
import os
import random
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

TARGETING_TESTS_PATH = MODULE_PATH.with_name("battle_targeting_tests.py")
targeting_spec = importlib.util.spec_from_file_location(
    "battle_targeting_tests_under_test",
    TARGETING_TESTS_PATH,
)
battle_targeting_tests = importlib.util.module_from_spec(targeting_spec)
targeting_spec.loader.exec_module(battle_targeting_tests)

SUMMONING_SICKNESS_TESTS_PATH = MODULE_PATH.with_name("battle_summoning_sickness_tests.py")
summoning_sickness_spec = importlib.util.spec_from_file_location(
    "battle_summoning_sickness_tests_under_test",
    SUMMONING_SICKNESS_TESTS_PATH,
)
battle_summoning_sickness_tests = importlib.util.module_from_spec(summoning_sickness_spec)
summoning_sickness_spec.loader.exec_module(battle_summoning_sickness_tests)

ZONE_TRANSITION_TESTS_PATH = MODULE_PATH.with_name("battle_zone_transition_tests.py")
zone_transition_spec = importlib.util.spec_from_file_location(
    "battle_zone_transition_tests_under_test",
    ZONE_TRANSITION_TESTS_PATH,
)
battle_zone_transition_tests = importlib.util.module_from_spec(zone_transition_spec)
zone_transition_spec.loader.exec_module(battle_zone_transition_tests)

CARD_IMPORT_TESTS_PATH = MODULE_PATH.with_name("battle_card_import_tests.py")
card_import_spec = importlib.util.spec_from_file_location(
    "battle_card_import_tests_under_test",
    CARD_IMPORT_TESTS_PATH,
)
battle_card_import_tests = importlib.util.module_from_spec(card_import_spec)
card_import_spec.loader.exec_module(battle_card_import_tests)

TURN_FLOW_TESTS_PATH = MODULE_PATH.with_name("battle_turn_flow_tests.py")
turn_flow_spec = importlib.util.spec_from_file_location(
    "battle_turn_flow_tests_under_test",
    TURN_FLOW_TESTS_PATH,
)
battle_turn_flow_tests = importlib.util.module_from_spec(turn_flow_spec)
turn_flow_spec.loader.exec_module(battle_turn_flow_tests)

SBA_ZONE_TESTS_PATH = MODULE_PATH.with_name("battle_sba_zone_tests.py")
sba_zone_spec = importlib.util.spec_from_file_location(
    "battle_sba_zone_tests_under_test",
    SBA_ZONE_TESTS_PATH,
)
battle_sba_zone_tests = importlib.util.module_from_spec(sba_zone_spec)
sba_zone_spec.loader.exec_module(battle_sba_zone_tests)

PERMANENTS_COMPLEX_TESTS_PATH = MODULE_PATH.with_name("battle_permanents_complex_tests.py")
permanents_complex_spec = importlib.util.spec_from_file_location(
    "battle_permanents_complex_tests_under_test",
    PERMANENTS_COMPLEX_TESTS_PATH,
)
battle_permanents_complex_tests = importlib.util.module_from_spec(permanents_complex_spec)
permanents_complex_spec.loader.exec_module(battle_permanents_complex_tests)

CONTINUOUS_EFFECTS_TESTS_PATH = MODULE_PATH.with_name("battle_continuous_effects_tests.py")
continuous_effects_spec = importlib.util.spec_from_file_location(
    "battle_continuous_effects_tests_under_test",
    CONTINUOUS_EFFECTS_TESTS_PATH,
)
battle_continuous_effects_tests = importlib.util.module_from_spec(continuous_effects_spec)
continuous_effects_spec.loader.exec_module(battle_continuous_effects_tests)

ENGINE_METRICS_TESTS_PATH = MODULE_PATH.with_name("battle_engine_metrics_tests.py")
engine_metrics_spec = importlib.util.spec_from_file_location(
    "battle_engine_metrics_tests_under_test",
    ENGINE_METRICS_TESTS_PATH,
)
battle_engine_metrics_tests = importlib.util.module_from_spec(engine_metrics_spec)
engine_metrics_spec.loader.exec_module(battle_engine_metrics_tests)

CONFORMANCE_TESTS_PATH = MODULE_PATH.with_name("battle_conformance_tests.py")
conformance_spec = importlib.util.spec_from_file_location(
    "battle_conformance_tests_under_test",
    CONFORMANCE_TESTS_PATH,
)
battle_conformance_tests = importlib.util.module_from_spec(conformance_spec)
conformance_spec.loader.exec_module(battle_conformance_tests)


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


CONFORMANCE_SCENARIOS = battle_conformance_tests.build_conformance_scenarios(
    battle_rules_2026_tests.CONFORMANCE_SCENARIOS_2026,
)


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


def test_classify_loss_covers_poison_effect_and_concede_tags():
    loser = player("Loser")
    loser.poison = 10
    loser.lost_by_effect = True
    loser.conceded = True

    tags = battle.classify_loss(loser, [], turn=5, result="loss", reason="test")

    assert tags[:3] == ["concede", "effect_says_lose", "poison"]
    assert battle.classify_loss(loser, [], turn=5, result="win", reason="test") == []


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
        *battle_sba_zone_tests.register_tests(battle, player, card),
        test_combat_emits_structured_event,
        test_end_of_combat_triggers_use_stack_and_apnap_order,
        *battle_turn_flow_tests.register_tests(battle, player, card),
        *battle_mana_tests.register_tests(battle, player),
        *battle_stack_casting_tests.register_tests(battle, player),
        *battle_continuous_effects_tests.register_tests(battle),
        *battle_permanents_complex_tests.register_tests(battle, player),
        *battle_engine_metrics_tests.register_tests(battle, player, engine_metrics_report),
        *battle_rules_2026_tests.register_tests(battle, player),
        *battle_conformance_tests.register_tests(battle, player, CONFORMANCE_SCENARIOS),
        *battle_commander_tests.register_tests(battle, player),
        *battle_targeting_tests.register_tests(battle, player),
        *battle_combat_tests.register_tests(battle, player),
        *battle_card_import_tests.register_tests(battle, player, card, MODULE_PATH),
        *battle_card_specific_tests.register_tests(battle, player),
        *battle_replacement_tests.register_tests(battle, player),
        *battle_summoning_sickness_tests.register_tests(battle, player, card),
        *battle_zone_transition_tests.register_tests(battle, player, card),
        test_classify_loss_covers_poison_effect_and_concede_tags,
        test_token_maker_counts_dict_lands_for_land_based_tokens,
        test_lumra_returns_milled_and_graveyard_lands_tapped,
        test_protected_player_prevents_combat_damage_without_audit_finding,
        test_auditor_flags_noncreature_land_attacker,
        test_zero_power_creature_without_attack_trigger_does_not_attack,
        test_apnap_trigger_order_puts_nonactive_trigger_on_top,
        test_same_controller_triggers_keep_timestamp_stack_order,
        test_spell_cast_trigger_resolves_from_stack_before_spell,
    ]
    for test in tests:
        if hasattr(battle, "clear_pending_triggers"):
            battle.clear_pending_triggers()
        test()
        print(f"PASS {test.__name__}")
