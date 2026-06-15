#!/usr/bin/env python3
"""Focused regression checks for the active battle_analyst_v9 engine.

The filename preserves the historical v10.3 replay-suite label, but
MODULE_PATH defaults to battle_analyst_v9.py unless BATTLE_ANALYST_PATH is set.

Run from this directory with:
    python3 test_battle_analyst_v10_3.py
"""

import importlib.util
import os
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

EVENT_TRIGGER_TESTS_PATH = MODULE_PATH.with_name("battle_event_trigger_tests.py")
event_trigger_spec = importlib.util.spec_from_file_location(
    "battle_event_trigger_tests_under_test",
    EVENT_TRIGGER_TESTS_PATH,
)
battle_event_trigger_tests = importlib.util.module_from_spec(event_trigger_spec)
event_trigger_spec.loader.exec_module(battle_event_trigger_tests)

MISC_REGRESSION_TESTS_PATH = MODULE_PATH.with_name("battle_misc_regression_tests.py")
misc_regression_spec = importlib.util.spec_from_file_location(
    "battle_misc_regression_tests_under_test",
    MISC_REGRESSION_TESTS_PATH,
)
battle_misc_regression_tests = importlib.util.module_from_spec(misc_regression_spec)
misc_regression_spec.loader.exec_module(battle_misc_regression_tests)

DECISION_TRACE_TESTS_PATH = MODULE_PATH.with_name("battle_decision_trace_tests.py")
decision_trace_spec = importlib.util.spec_from_file_location(
    "battle_decision_trace_tests_under_test",
    DECISION_TRACE_TESTS_PATH,
)
battle_decision_trace_tests = importlib.util.module_from_spec(decision_trace_spec)
decision_trace_spec.loader.exec_module(battle_decision_trace_tests)


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


if __name__ == "__main__":
    tests = [
        *battle_sba_zone_tests.register_tests(battle, player, card),
        *battle_event_trigger_tests.register_tests(battle, player, card),
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
        *battle_misc_regression_tests.register_tests(battle, player, replay_auditor),
        *battle_decision_trace_tests.register_tests(battle, replay_auditor),
    ]
    for test in tests:
        if hasattr(battle, "clear_pending_triggers"):
            battle.clear_pending_triggers()
        test()
        print(f"PASS {test.__name__}")
