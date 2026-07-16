#!/usr/bin/env python3
"""Focused runtime tests for Hazel's Brewmaster."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_hazels_brewmaster_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def hazel_effect() -> dict:
    return {
        "effect": "creature",
        "ability_kind": "triggered_static",
        "battle_model_scope": (
            "etb_or_attack_exile_graveyard_card_create_food_share_exiled_creature_activated_abilities_v1"
        ),
        "power": 3,
        "toughness": 4,
        "keywords": ["menace"],
        "menace": True,
        "trigger": "enters_battlefield_or_attacks",
        "trigger_effect": "exile_graveyard_card_create_food",
        "hazel_brewmaster_etb_or_attack_exile_graveyard_card_create_food": True,
        "target_zone": "graveyard",
        "target_count_max": 1,
        "target_optional": True,
        "create_food_token": True,
        "foods_gain_activated_abilities_from_exiled_creatures": True,
    }


def hazel_card() -> dict:
    return {
        "name": "Hazel's Brewmaster",
        "type_line": "Creature — Squirrel Warlock",
        "mana_cost": "{3}{B}",
        "colors": ["B"],
        "color_identity": ["B"],
        "cmc": 4,
        **hazel_effect(),
    }


def canonical_runtime_card(battle, card: dict, *, logical_rule_key: str) -> dict:
    effect = battle.get_card_effect(card)
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert effect["_rule_logical_key"] == logical_rule_key
    return {**card, **effect}


def devoted_druid(battle) -> dict:
    return canonical_runtime_card(
        battle,
        {
            "name": "Devoted Druid",
            "type_line": "Creature — Elf Druid",
            "mana_cost": "{1}{G}",
            "colors": ["G"],
            "color_identity": ["G"],
            "oracle_text": (
                "{T}: Add {G}.\n"
                "Put a -1/-1 counter on this creature: Untap this creature."
            ),
            "power": 0,
            "toughness": 2,
        },
        logical_rule_key="battle_rule_v1:67f97b25cf58b747257151dada64b9e4",
    )


def faeburrow_elder(battle) -> dict:
    return canonical_runtime_card(
        battle,
        {
            "name": "Faeburrow Elder",
            "type_line": "Creature — Treefolk Druid",
            "mana_cost": "{1}{G}{W}",
            "colors": ["G", "W"],
            "color_identity": ["G", "W"],
            "oracle_text": (
                "Vigilance\n"
                "This creature gets +1/+1 for each color among permanents you control.\n"
                "{T}: For each color among permanents you control, add one mana of that color."
            ),
            "power": 0,
            "toughness": 0,
        },
        logical_rule_key="battle_rule_v1:ba732f55ab31865df49e463277d20469",
    )


def test_hazel_etb_exiles_graveyard_creature_and_food_gains_activated_ability() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.graveyard = [devoted_druid(battle)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            hazel_card(),
            turn=4,
            rng=random.Random(607),
            effect_data_override=hazel_effect(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    hazel = next(card for card in active.battlefield if card.get("name") == "Hazel's Brewmaster")
    food = next(card for card in active.battlefield if card.get("name") == "Food Token")
    assert active.graveyard == []
    assert any(card.get("name") == "Devoted Druid" for card in active.exile)
    assert food["type_line"] == "Artifact Token — Food"
    assert food["is_mana_source"] is True
    assert food["produces"] == "G"
    assert food["activated_put_minus_one_counter_untap_self"] is True
    copied = food["hazel_brewmaster_copied_activated_abilities"]
    assert [ability["effect"] for ability in copied] == ["add_mana", "untap_self"]
    assert [ability["hazel_exiled_card_name"] for ability in copied] == [
        "Devoted Druid",
        "Devoted Druid",
    ]
    assert len({ability["hazel_copied_ability_id"] for ability in copied}) == 2
    assert food["_activated_rule_effects"] == copied
    assert hazel["hazel_shared_activated_abilities"] == copied
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Hazel's Brewmaster"
        and data.get("source_event") == "enters_battlefield"
        and data.get("exiled_card") == "Devoted Druid"
        and data.get("food_token") == "Food Token"
        for event, data in events
    )


def test_hazel_repeated_exiles_preserve_faeburrow_and_devoted_abilities_on_every_food() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Hazel", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.battlefield = [
            {
                "name": "White Test Permanent",
                "type_line": "Enchantment",
                "colors": ["W"],
                "color_identity": ["W"],
                "effect": "enchantment",
            }
        ]
        active.graveyard = [faeburrow_elder(battle)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            hazel_card(),
            turn=4,
            rng=random.Random(607),
            effect_data_override=hazel_effect(),
        )

        hazel = next(
            card for card in active.battlefield if card.get("name") == "Hazel's Brewmaster"
        )
        first_food = next(
            card for card in active.battlefield if card.get("name") == "Food Token"
        )
        assert [
            ability["hazel_exiled_card_name"]
            for ability in first_food["hazel_brewmaster_copied_activated_abilities"]
        ] == ["Faeburrow Elder"]
        assert first_food["mana_produced_from_colors_among_permanents"] is True

        active.graveyard.append(devoted_druid(battle))
        assert battle.resolve_hazels_brewmaster_attack_triggers(
            active,
            [hazel],
            [opponent],
            turn=5,
        ) == 1
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    foods = [card for card in active.battlefield if card.get("name") == "Food Token"]
    assert len(foods) == 2
    assert first_food in foods
    assert [card["name"] for card in hazel["hazel_exiled_creature_cards"]] == [
        "Faeburrow Elder",
        "Devoted Druid",
    ]

    for food in foods:
        copied = food["hazel_brewmaster_copied_activated_abilities"]
        assert [ability["effect"] for ability in copied] == [
            "add_mana",
            "add_mana",
            "untap_self",
        ]
        assert [ability["hazel_exiled_card_name"] for ability in copied] == [
            "Faeburrow Elder",
            "Devoted Druid",
            "Devoted Druid",
        ]
        assert len({ability["hazel_copied_ability_id"] for ability in copied}) == 3
        assert food["_activated_rule_effects"] == copied

        faeburrow_mana, devoted_mana, devoted_untap = copied
        assert faeburrow_mana["mana_produced_from_colors_among_permanents"] is True
        assert faeburrow_mana["produces"] == "WUBRG"
        assert devoted_mana["mana_produced"] == 1
        assert devoted_mana["produces"] == "G"
        assert devoted_untap["activated_put_minus_one_counter_untap_self"] is True
        assert devoted_untap["activated_put_minus_one_counter_untap_self_status"] == "annotation_only"

        # The compatibility projection must select the currently stronger
        # Faeburrow mana profile without deleting Devoted Druid's two abilities.
        assert food["mana_produced_from_colors_among_permanents"] is True
        assert battle.mana_source_production_for_state(active, food) >= 2
        assert food["activated_put_minus_one_counter_untap_self"] is True

    assert any(
        event == "trigger_resolved"
        and data.get("source_event") == "attacks"
        and data.get("exiled_card") == "Devoted Druid"
        and data.get("copied_activated_ability_count") == 3
        for event, data in events
    )


def test_hazel_attack_trigger_creates_food_even_without_graveyard_target() -> None:
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    hazel = battle.prepare_entering_permanent(hazel_card(), controller=active, all_players=[active, opponent], turn=5)
    active.battlefield = [hazel]

    resolved = battle.resolve_hazels_brewmaster_attack_triggers(
        active,
        [hazel],
        [opponent],
        turn=5,
    )

    assert resolved == 1
    assert any(card.get("name") == "Food Token" for card in active.battlefield)
