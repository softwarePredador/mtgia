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

PG_RULE_FALLBACK_TESTS_PATH = MODULE_PATH.with_name(
    "test_runtime_pg_rule_fallback_for_promoted_hotfixes.py"
)
pg_rule_fallback_spec = importlib.util.spec_from_file_location(
    "pg_rule_fallback_tests_under_test",
    PG_RULE_FALLBACK_TESTS_PATH,
)
pg_rule_fallback_tests = importlib.util.module_from_spec(pg_rule_fallback_spec)
pg_rule_fallback_spec.loader.exec_module(pg_rule_fallback_tests)


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


def test_promoted_hotfixes_resolve_from_sqlite_without_manual_override():
    case = pg_rule_fallback_tests.RuntimePgRuleFallbackForPromotedHotfixesTests(
        "test_canonicalized_overrides_resolve_from_sqlite_without_manual_override"
    )
    case.setUp()
    try:
        case.test_canonicalized_overrides_resolve_from_sqlite_without_manual_override()
    finally:
        case.tearDown()


def test_pg078_deck606_l2_hash_scope_rules_resolve_from_sqlite():
    expected = {
        "Borrowed Knowledge": (
            "draw_cards",
            "modal_discard_hand_draw_equal_discarded_hand_v1",
            "battle_rule_v1:ab8c8e79988c1b44ccf6f4cd8324aa78",
            "8027b5b33d6dda44ff12265baabb8407",
        ),
        "Increasing Vengeance": (
            "copy_spell",
            "instant_copy_spell_requires_stack_target_v1",
            "battle_rule_v1:30ea39d59aa1ffc3158a49675b767c30",
            "112a3720da30692b859f8a9bedc90a2f",
        ),
        "Reckless Endeavor": (
            "damage_wipe_treasure",
            "d12_damage_wipe_treasure_average_v1",
            "battle_rule_v1:58cf44e1552692ff62aeaf4ae3c7eaee",
            "a9360407a1ca872b72f52acfed795194",
        ),
        "Wear // Tear": (
            "remove_permanent",
            "split_artifact_or_enchantment_removal_v1",
                "battle_rule_v1:04938744ea1c609cc9d77c851ee8bd08",
            "bccbbc9c0ebfc638e73f0ee82a7d72d3",
        ),
        "Thought Vessel": (
            "ramp_permanent",
            "colorless_mana_rock_no_max_hand_size_v1",
            "battle_rule_v1:93ac5946d2f83cec409a2892520f26d0",
            "ff80b35ee08bb1b68ec7c0be24d6eaaa",
        ),
        "Swiftfoot Boots": (
            "equipment_static_attachment",
            "equipment_auto_attach_haste_hexproof_v1",
            "battle_rule_v1:86b568648669ceb1eef6d7f6b95d4f1c",
            "5f4fa8fe20c8a6c55a2aee48c34c6b25",
        ),
    }
    type_lines = {
        "Borrowed Knowledge": "Sorcery",
        "Increasing Vengeance": "Instant",
        "Reckless Endeavor": "Sorcery",
        "Wear // Tear": "Instant",
        "Thought Vessel": "Artifact",
        "Swiftfoot Boots": "Artifact - Equipment",
    }

    for name, (
        expected_effect,
        expected_scope,
        expected_key,
        expected_hash,
    ) in expected.items():
        effect = battle.get_card_effect(
            {
                "name": name,
                "cmc": 2,
                "type_line": type_lines[name],
            }
        )
        assert effect.get("effect") == expected_effect
        assert effect.get("battle_model_scope") == expected_scope
        assert effect.get("_rule_logical_key") == expected_key
        assert effect.get("_rule_oracle_hash") == expected_hash
        assert effect.get("_rule_source") == "curated"
        assert effect.get("_rule_execution_status") == "auto"


def test_attack_restriction_details_include_limit_sources():
    lorehold = player("Lorehold")
    opponent = player("Opponent")
    lorehold.battlefield.append(
        {
            "name": "Crawlspace",
            "effect": "attack_limit",
            "max_attackers_against_you": 2,
        }
    )
    lorehold.battlefield.append(
        {
            "name": "Silent Arbiter",
            "effect": "attack_limit",
            "max_attackers": 1,
        }
    )
    attackers = [
        {"name": "Attacker A", "power": 2, "toughness": 2},
        {"name": "Attacker B", "power": 2, "toughness": 2},
        {"name": "Attacker C", "power": 2, "toughness": 2},
    ]

    _groups, details = battle.apply_attack_restrictions(
        opponent,
        [(lorehold, attackers)],
        [lorehold, opponent],
    )

    sources = {
        source
        for detail in details
        for source in detail.get("attack_restriction_sources", [])
    }
    assert "Silent Arbiter" in sources
    assert "Crawlspace" in sources
    assert "unattributed" not in sources


def test_attack_restriction_details_include_vow_sources():
    lorehold = player("Lorehold")
    opponent = player("Opponent")
    vowed_attacker = {
        "name": "Vowed Creature",
        "power": 4,
        "toughness": 4,
        "vow_counter": True,
        "vow_cannot_attack_players": ["Lorehold"],
        "vow_counter_source": "Promise of Loyalty",
    }

    _groups, details = battle.apply_attack_restrictions(
        opponent,
        [(lorehold, [vowed_attacker])],
        [lorehold, opponent],
    )

    sources = {
        source
        for detail in details
        for source in detail.get("attack_restriction_sources", [])
    }
    assert "Promise of Loyalty" in sources
    assert "unattributed" not in sources


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
        test_promoted_hotfixes_resolve_from_sqlite_without_manual_override,
        test_pg078_deck606_l2_hash_scope_rules_resolve_from_sqlite,
        test_attack_restriction_details_include_limit_sources,
        test_attack_restriction_details_include_vow_sources,
    ]
    for test in tests:
        if hasattr(battle, "clear_pending_triggers"):
            battle.clear_pending_triggers()
        test()
        print(f"PASS {test.__name__}")
