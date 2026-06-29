#!/usr/bin/env python3
"""Focused runtime tests for Treasonous Ogre life-payment mana."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_treasonous_ogre_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def treasonous_ogre_rule(battle):
    rule = battle.HANDCRAFTED_KNOWN_CARD_RULES["Treasonous Ogre"]
    return battle.with_rule_metadata(
        rule,
        source="manual_runtime_waiver",
        review_status="verified",
        execution_status="auto",
        confidence=1.0,
        logical_rule_key=rule.get("_rule_logical_key"),
        oracle_hash=rule.get("_rule_oracle_hash"),
    )


def test_treasonous_ogre_rule_resolves_from_curated_sqlite_after_pg256():
    battle = load_battle()
    effect = battle.get_card_effect(
        {"name": "Treasonous Ogre", "type_line": "Creature - Ogre Shaman"}
    )

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "creature_pay_three_life_add_one_red_mana_dethrone_v1"
    assert effect["_rule_logical_key"] == "battle_rule_v1:7470f49a9a616bd658adeee6c6d2f1d8"
    assert effect["_rule_oracle_hash"] == "741590c7114b82776c38a21056cfed58"
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert effect["mana_source_no_tap_activation"] is True
    assert effect["mana_produced_from_life_payment_divisor"] == 3


def test_treasonous_ogre_can_pay_life_multiple_times_for_red_mana():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Active", None, [])
        active.life = 11
        effect = treasonous_ogre_rule(battle)
        ogre = {
            "name": "Treasonous Ogre",
            "type_line": "Creature - Ogre Shaman",
            "summoning_sick": True,
            **effect,
        }
        active.battlefield = [ogre]
        active.refresh_mana_sources(turn=3)

        assert active.can_pay("{R}{R}") is True
        assert active.spend_mana("{R}{R}") is True
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert active.life == 5
    assert active.conditional_mana_sources[0]["remaining"] == 1
    assert any(
        event == "conditional_mana_life_cost_paid"
        and data.get("source") == "Treasonous Ogre"
        and data.get("amount_paid") == 2
        and data.get("life_loss") == 6
        and data.get("life_loss_kind") == "pay_life_activation"
        and data.get("rule_logical_key") == "battle_rule_v1:7470f49a9a616bd658adeee6c6d2f1d8"
        for event, data in events
    )


def test_treasonous_ogre_cannot_pay_more_life_than_available():
    battle = load_battle()
    active = battle.Player("Active", None, [])
    active.life = 5
    effect = treasonous_ogre_rule(battle)
    ogre = {
        "name": "Treasonous Ogre",
        "type_line": "Creature - Ogre Shaman",
        "summoning_sick": True,
        **effect,
    }
    active.battlefield = [ogre]
    active.refresh_mana_sources(turn=4)

    assert active.can_pay("{R}{R}") is False
    assert active.can_pay("{R}") is True
    assert active.spend_mana("{R}") is True
    assert active.life == 2
    assert active.conditional_mana_sources == []
