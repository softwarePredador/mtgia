#!/usr/bin/env python3
"""Focused runtime tests for Phyrexian Censor static restrictions."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_phyrexian_censor_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def focused_rule(battle):
    rule = battle.HANDCRAFTED_KNOWN_CARD_RULES["Phyrexian Censor"]
    return battle.with_rule_metadata(
        rule,
        source="manual_runtime_waiver",
        review_status="verified",
        execution_status="auto",
        confidence=1.0,
        logical_rule_key=rule.get("_rule_logical_key"),
        oracle_hash=rule.get("_rule_oracle_hash"),
    )


def test_phyrexian_censor_rule_resolves_from_curated_sqlite_after_pg257():
    battle = load_battle()
    effect = battle.get_card_effect(
        {"name": "Phyrexian Censor", "type_line": "Creature - Phyrexian Wizard"}
    )

    assert effect["effect"] == "creature"
    assert (
        effect["battle_model_scope"]
        == "each_player_one_nonphyrexian_spell_per_turn_nonphyrexian_creatures_enter_tapped_v1"
    )
    assert effect["_rule_logical_key"] == "battle_rule_v1:166240c94a4f8ba33fc80549c236deb7"
    assert effect["_rule_oracle_hash"] == "deafed84b14f2008e85145ee17c162a7"
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert effect["restricted_spell_scope"] == "nonphyrexian_spells"
    assert effect["nonphyrexian_creatures_enter_tapped"] is True


def test_phyrexian_censor_blocks_second_nonphyrexian_spell_but_not_phyrexian():
    battle = load_battle()
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [])
    effect = focused_rule(battle)

    battle.apply_effect_immediate(
        active,
        [opponent],
        {"name": "Phyrexian Censor", "type_line": "Creature - Phyrexian Wizard"},
        turn=2,
        rng=random.Random(257),
        effect_data_override=effect,
    )
    opponent.record_spell_cast(turn_marker=2, card={"name": "Brainstorm", "type_line": "Instant"})

    assert battle.can_cast_in_phase(
        {"name": "Lightning Bolt", "type_line": "Instant"},
        {"effect": "direct_damage"},
        "precombat_main",
        controller=opponent,
    ) is False
    assert battle.can_cast_in_phase(
        {"name": "Phyrexian Walker", "type_line": "Artifact Creature - Phyrexian Construct"},
        {"effect": "creature"},
        "precombat_main",
        controller=opponent,
    ) is True


def test_phyrexian_censor_makes_nonphyrexian_creatures_enter_tapped_for_all_players():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Active", None, [])
        opponent = battle.Player("Opponent", None, [])
        effect = focused_rule(battle)
        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Phyrexian Censor", "type_line": "Creature - Phyrexian Wizard"},
            turn=3,
            rng=random.Random(257),
            effect_data_override=effect,
        )

        bear = battle.prepare_entering_permanent(
            {"name": "Runeclaw Bear", "type_line": "Creature - Bear"},
            controller=opponent,
            all_players=[active, opponent],
            turn=3,
        )
        phyrexian = battle.prepare_entering_permanent(
            {"name": "Phyrexian Walker", "type_line": "Artifact Creature - Phyrexian Construct"},
            controller=opponent,
            all_players=[active, opponent],
            turn=3,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert bear["tapped"] is True
    assert bear["entered_tapped_by_static"] == "Phyrexian Censor"
    assert phyrexian.get("tapped") is not True
    assert any(
        event == "static_enter_tapped_applied"
        and data.get("source_card") == "Phyrexian Censor"
        and data.get("applies_to") == "nonphyrexian_creature"
        and data.get("card") == "Runeclaw Bear"
        for event, data in events
    )
