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
        test_continuous_effects_apply_layers_and_sublayers_in_order,
        test_continuous_effects_apply_type_color_text_and_ability_layers,
        test_continuous_effect_dependencies_override_timestamp_within_layer,
        *battle_permanents_complex_tests.register_tests(battle, player),
        test_engine_metrics_collects_core_health_signals,
        test_engine_metrics_snapshot_writes_sanitized_json,
        test_engine_metrics_report_aggregates_sanitized_snapshots,
        *battle_rules_2026_tests.register_tests(battle, player),
        test_conformance_registry_has_executable_coverage,
        *battle_commander_tests.register_tests(battle, player),
        test_conformance_blocked_attacker_stays_blocked_after_blocker_leaves,
        test_conformance_apnap_trigger_order_is_lifo_after_stack_placement,
        test_conformance_prevention_applies_before_damage_life_change,
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
