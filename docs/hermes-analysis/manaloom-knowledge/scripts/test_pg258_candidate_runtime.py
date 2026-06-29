#!/usr/bin/env python3
"""Focused runtime tests for PG258 candidate-template promotions."""

from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


class FixedRng:
    def randrange(self, stop):
        return 0

    def randint(self, _start, _stop):
        return 0

    def choice(self, seq):
        return seq[0]

    def shuffle(self, _seq):
        return None


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_pg258_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name, type_line, **extra):
    return {"name": name, "type_line": type_line, **extra}


def apply_with_events(battle, player, opponents, source, effect, *, turn=4):
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            player,
            opponents,
            source,
            turn,
            FixedRng(),
            effect_data_override=effect,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None
    return events


def test_reckless_handling_tutors_artifact_discards_artifact_and_damages_opponents():
    battle = load_battle()
    player = battle.Player("Pilot", None, [])
    opponent_a = battle.Player("Opponent A", None, [])
    opponent_b = battle.Player("Opponent B", None, [])
    player.library = [card("Sol Ring", "Artifact", cmc=1)]
    player.hand = [card("Ornithopter", "Artifact Creature - Thopter", cmc=0)]
    effect = {
        "effect": "tutor",
        "battle_model_scope": "artifact_tutor_to_hand_random_discard_damage_if_artifact_discarded_v1",
        "target": "artifact_to_hand",
        "tutor_destination": "hand",
        "discard_after_tutor_random": 1,
        "random_discard_after_tutor": 1,
        "damage_each_opponent_if_artifact_discarded": 2,
    }

    events = apply_with_events(
        battle,
        player,
        [opponent_a, opponent_b],
        card("Reckless Handling", "Sorcery"),
        effect,
    )

    assert any(hand_card["name"] == "Sol Ring" for hand_card in player.hand)
    assert any(grave_card["name"] == "Ornithopter" for grave_card in player.graveyard)
    assert opponent_a.life == 38
    assert opponent_b.life == 38
    assert any(event == "random_discard_artifact_damage_resolved" for event, _data in events)


def test_demonic_counsel_needs_delirium_to_upgrade_from_demon_to_any_card():
    battle = load_battle()
    effect = {
        "effect": "tutor",
        "battle_model_scope": "conditional_delirium_restricted_or_any_tutor_to_hand_v1",
        "target": "demon_to_hand",
        "delirium_target": "any_to_hand",
        "delirium_graveyard_card_type_count": 4,
        "tutor_destination": "hand",
    }

    no_delirium = battle.Player("No Delirium", None, [])
    no_delirium.library = [card("Sol Ring", "Artifact", cmc=1)]
    events_without = apply_with_events(
        battle,
        no_delirium,
        [],
        card("Demonic Counsel", "Sorcery"),
        effect,
    )
    assert not any(hand_card["name"] == "Sol Ring" for hand_card in no_delirium.hand)
    assert any(
        event == "tutor_resolved" and data.get("delirium_active") is False and data.get("found") is None
        for event, data in events_without
    )

    with_delirium = battle.Player("With Delirium", None, [])
    with_delirium.library = [card("Sol Ring", "Artifact", cmc=1)]
    with_delirium.graveyard = [
        card("Memnite", "Artifact Creature", cmc=0),
        card("Mountain", "Basic Land - Mountain", cmc=0),
        card("Lightning Bolt", "Instant", cmc=1),
        card("Reanimate", "Sorcery", cmc=1),
    ]
    events_with = apply_with_events(
        battle,
        with_delirium,
        [],
        card("Demonic Counsel", "Sorcery"),
        effect,
    )
    assert any(hand_card["name"] == "Sol Ring" for hand_card in with_delirium.hand)
    assert any(
        event == "tutor_resolved"
        and data.get("delirium_active") is True
        and data.get("target_type") == "any_to_hand"
        for event, data in events_with
    )


def test_summoners_pact_tutors_green_creature_and_records_delayed_payment_annotation():
    battle = load_battle()
    player = battle.Player("Pilot", None, [])
    player.library = [
        card("Birds of Paradise", "Creature - Bird", colors=["G"], cmc=1),
        card("Snapcaster Mage", "Creature - Human Wizard", colors=["U"], cmc=2),
    ]
    effect = {
        "effect": "tutor",
        "battle_model_scope": "pact_green_creature_tutor_to_hand_delayed_payment_v1",
        "target": "green_creature_to_hand",
        "tutor_destination": "hand",
        "delayed_upkeep_mana_payment": "{2}{G}{G}",
        "delayed_upkeep_payment_status": "annotation_only",
        "lose_game_if_unpaid": True,
    }

    events = apply_with_events(
        battle,
        player,
        [],
        card("Summoner's Pact", "Instant"),
        effect,
    )

    assert any(hand_card["name"] == "Birds of Paradise" for hand_card in player.hand)
    assert not any(hand_card["name"] == "Snapcaster Mage" for hand_card in player.hand)
    assert any(
        event == "delayed_upkeep_payment_created"
        and data.get("delayed_upkeep_mana_payment") == "{2}{G}{G}"
        and data.get("delayed_upkeep_payment_status") == "annotation_only"
        for event, data in events
    )


def test_scour_for_scrap_resolves_artifact_library_and_graveyard_modes():
    battle = load_battle()
    player = battle.Player("Pilot", None, [])
    player.library = [card("Sol Ring", "Artifact", cmc=1)]
    player.graveyard = [card("Mana Vault", "Artifact", cmc=1)]
    effect = {
        "effect": "modal_spell",
        "battle_model_scope": "modal_artifact_tutor_or_artifact_graveyard_to_hand_v1",
        "instant": True,
        "mode_min": 1,
        "mode_max": 2,
        "mode_one_target": "artifact_to_hand",
        "mode_two_target": "artifact_from_graveyard_to_hand",
    }

    events = apply_with_events(
        battle,
        player,
        [],
        card("Scour for Scrap", "Instant"),
        effect,
    )

    assert {hand_card["name"] for hand_card in player.hand} >= {"Sol Ring", "Mana Vault"}
    assert not any(grave_card["name"] == "Mana Vault" for grave_card in player.graveyard)
    assert any(
        event == "modal_spell_resolved" and data.get("mode_count") == 2
        for event, data in events
    )


def test_cloud_of_faeries_enters_and_untaps_up_to_two_lands():
    battle = load_battle()
    player = battle.Player("Pilot", None, [])
    island = card("Island", "Basic Land - Island", effect="land", tapped=True)
    plains = card("Plains", "Basic Land - Plains", effect="land", tapped=True)
    mountain = card("Mountain", "Basic Land - Mountain", effect="land", tapped=True)
    player.battlefield = [island, plains, mountain]
    effect = {
        "effect": "untap_land_engine",
        "battle_model_scope": "etb_untap_up_to_two_lands_cycling_two_v1",
        "etb_untap_lands_count": 2,
        "etb_untap_lands_optional": True,
        "cycling_cost": "{2}",
        "cycling_status": "annotation_only",
    }

    events = apply_with_events(
        battle,
        player,
        [],
        card("Cloud of Faeries", "Creature - Faerie", power=1, toughness=1),
        effect,
    )

    assert island["tapped"] is False
    assert plains["tapped"] is False
    assert mountain["tapped"] is True
    assert any(perm["name"] == "Cloud of Faeries" and perm["effect"] == "creature" for perm in player.battlefield)
    assert any(
        event == "trigger_resolved"
        and data.get("effect") == "untap_lands"
        and data.get("untapped_count") == 2
        for event, data in events
    )


def test_grinding_station_sacrifices_artifact_to_mill_target_player():
    battle = load_battle()
    player = battle.Player("Pilot", None, [])
    opponent = battle.Player("Opponent", None, [])
    opponent.library = [card(f"Card {idx}", "Sorcery", cmc=1) for idx in range(5)]
    station_effect = {
        "effect": "mill_engine",
        "battle_model_scope": "artifact_tap_sacrifice_permanent_target_player_mill_v1",
        "activation_requires_tap": True,
        "activation_requires_sacrifice_permanent": True,
        "activation_sacrifice_target_type": "artifact",
        "target": "player",
        "mill_count": 3,
        "artifact_enters_untap_source": True,
        "artifact_enters_untap_source_status": "annotation_only",
    }
    station = battle.prepare_entering_permanent(
        card("Grinding Station", "Artifact", **station_effect)
    )
    treasure = card("Treasure Token", "Artifact Token", is_token=True)
    player.battlefield = [station, treasure]

    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_mill_engines(
            player,
            [opponent],
            [player, opponent],
            5,
            FixedRng(),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert station["tapped"] is True
    assert treasure not in player.battlefield
    assert len(opponent.library) == 2
    assert len(opponent.graveyard) == 3
    assert any(
        event == "mill_engine_activated"
        and data.get("sacrificed") == "Treasure Token"
        and data.get("cards_milled") == 3
        for event, data in events
    )
