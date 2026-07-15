#!/usr/bin/env python3
"""Focused runtime coverage for the final Lorehold runtime-gap cards."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_final_eight_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def card(name, type_line, cmc, mana_cost="", **extra):
    payload = {
        "name": name,
        "type_line": type_line,
        "cmc": cmc,
        "mana_cost": mana_cost,
    }
    payload.update(extra)
    return payload


def test_final_eight_get_card_effects_use_exact_runtime_scopes():
    battle = load_battle()
    expected = {
        "Blood Moon": ("passive", "nonbasic_lands_are_mountains_static_v1"),
        "Karn, the Great Creator": ("planeswalker", "opponent_artifact_activation_lock_planeswalker_wish_v1"),
        "Chandra's Ignition": ("sweeper_damage", "target_controlled_creature_power_damage_each_other_creature_each_opponent_v1"),
        "Karn's Sylex": ("passive", "legendary_artifact_tapped_life_payment_lock_x_tap_exile_destroy_nonland_mv_lte_x_v1"),
        "Naktamun Lorespinner // Wheel of Fortune": ("creature", "prepare_upkeep_any_player_one_or_fewer_hand_wheel_face_v1"),
        "Charmbreaker Devils": ("creature", "upkeep_random_instant_sorcery_graveyard_to_hand_instant_sorcery_cast_plus4_v1"),
        "Ancient Gold Dragon": ("token_maker", "source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1"),
        "Deathbellow War Cry": ("tutor", "up_to_four_different_name_minotaur_creatures_to_battlefield_v1"),
    }
    for name, (effect, scope) in expected.items():
        resolved = battle.get_card_effect(card(name, "Sorcery", 3))
        assert resolved["effect"] == effect
        assert resolved["battle_model_scope"] == scope
        assert not scope.startswith("xmage_")
        assert resolved["_rule_review_status"] == "verified"
        assert resolved["_rule_execution_status"] == "auto"
        assert resolved.get("_rule_oracle_hash")


def test_blood_moon_makes_nonbasic_lands_produce_red_only():
    battle = load_battle()
    active = player(battle, "Moon Controller")
    opponent = player(battle, "Opponent")

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Blood Moon", "Enchantment", 3, "{2}{R}"),
        turn=1,
        rng=random.Random(1),
        stack=battle.Stack(),
        phase="precombat_main",
    )
    opponent.battlefield = [
        card("Command Tower", "Land", 0, effect="land", produces="WUBRG", mana_produced=1),
        card("Island", "Basic Land - Island", 0, effect="land", produces="U", mana_produced=1),
    ]
    battle.bind_table_context([active, opponent])
    opponent.refresh_mana_sources(turn=2)

    assert opponent.mana_pool.red == 1
    assert opponent.mana_pool.blue == 1
    assert opponent.mana_pool.wildcard == 0


def test_karn_great_creator_locks_opponent_artifact_mana_abilities():
    battle = load_battle()
    controller = player(battle, "Karn Controller")
    opponent = player(battle, "Artifact Player")

    battle.apply_effect_immediate(
        controller,
        [opponent],
        card("Karn, the Great Creator", "Legendary Planeswalker - Karn", 4, "{4}"),
        turn=1,
        rng=random.Random(2),
        stack=battle.Stack(),
        phase="precombat_main",
    )
    sol_ring = card(
        "Sol Ring",
        "Artifact",
        1,
        "{1}",
        effect="ramp_permanent",
        is_mana_source=True,
        mana_produced=1,
        produces="C",
    )
    opponent.battlefield = [sol_ring]
    battle.bind_table_context([controller, opponent])

    assert battle.mana_source_production_for_state(opponent, sol_ring) == 0


def test_chandras_ignition_uses_target_creature_power_and_spares_source():
    battle = load_battle()
    events = []
    old_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Ignition")
        opponent = player(battle, "Opponent")
        source = card("Inferno Titan", "Creature - Giant", 6, power=6, toughness=6, effect="creature")
        own_small = card("Token", "Creature Token", 0, power=2, toughness=2, effect="creature")
        opp_creature = card("Siege Rhino", "Creature - Rhino", 4, power=4, toughness=5, effect="creature")
        active.battlefield = [source, own_small]
        opponent.battlefield = [opp_creature]

        battle.apply_effect_immediate(
            active,
            [opponent],
            card("Chandra's Ignition", "Sorcery", 5, "{3}{R}{R}"),
            turn=3,
            rng=random.Random(3),
            stack=battle.Stack(),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = old_handler

    assert source in active.battlefield
    assert own_small not in active.battlefield
    assert any(card.get("name") == "Siege Rhino" for card in opponent.graveyard)
    assert opponent.life == 34
    resolved = next(
        data
        for event, data in events
        if event == "sweeper_damage_resolved" and data.get("card") == "Chandra's Ignition"
    )
    assert resolved["source_creature"] == "Inferno Titan"
    assert resolved["own_creatures_destroyed"] == 1
    assert resolved["opponent_creatures_destroyed"] == 1


def test_karns_sylex_activates_x_wipe_and_exiles_source():
    battle = load_battle()
    active = player(battle, "Sylex")
    opponent = player(battle, "Opponent")
    sylex_effect = battle.get_card_effect(card("Karn's Sylex", "Legendary Artifact", 3, "{3}"))
    sylex = {**card("Karn's Sylex", "Legendary Artifact", 3, "{3}"), **sylex_effect, "tapped": False}
    own_rock = card("Mind Stone", "Artifact", 2, effect="ramp_permanent")
    opp_creature = card("Goblin Rabblemaster", "Creature - Goblin", 3, effect="creature", power=2, toughness=2)
    opp_artifact = card("Isochron Scepter", "Artifact", 2, effect="passive")
    opp_land = card("Mountain", "Basic Land - Mountain", 0, effect="land")
    active.battlefield = [sylex, own_rock]
    opponent.battlefield = [opp_creature, opp_artifact, opp_land]
    active.mana_pool.add_generic(3)

    activated = battle.activate_utility_artifacts(
        active,
        [opponent],
        [active, opponent],
        turn=4,
        rng=random.Random(4),
        phase="precombat_main",
    )

    assert activated == 1
    assert sylex in active.exile
    assert own_rock in active.graveyard
    assert opp_creature in opponent.graveyard
    assert opp_artifact in opponent.graveyard
    assert opp_land in opponent.battlefield


def test_naktamun_prepares_on_upkeep_and_casts_wheel_face():
    battle = load_battle()
    active = player(battle, "Naktamun")
    opponent = player(battle, "Opponent")
    naktamun_effect = battle.get_card_effect(
        card("Naktamun Lorespinner // Wheel of Fortune", "Creature - Jackal Wizard", 3, "{2}{R}")
    )
    naktamun = {
        **card("Naktamun Lorespinner // Wheel of Fortune", "Creature - Jackal Wizard", 3, "{2}{R}"),
        **naktamun_effect,
    }
    active.battlefield = [naktamun]
    opponent.hand = []
    active.library = [card(f"Active Draw {i}", "Instant", 1) for i in range(7)]
    opponent.library = [card(f"Opponent Draw {i}", "Creature", 1) for i in range(7)]
    active.mana_pool.add_generic(2)
    active.mana_pool.add("red", 1)

    prepared_count = battle.process_prepare_upkeep_triggers(active, [active, opponent], turn=5)
    cast = battle.cast_prepared_spell_faces(
        active,
        [opponent],
        [active, opponent],
        turn=5,
        phase="precombat_main",
        stack=battle.Stack(),
        rng=random.Random(5),
    )

    assert prepared_count == 1
    assert cast is True
    assert naktamun in active.battlefield
    assert naktamun not in active.graveyard
    assert naktamun["prepared"] is False
    assert len(active.hand) == 7
    assert len(opponent.hand) == 7

    opponent.hand = []
    assert battle.process_prepare_upkeep_triggers(active, [active, opponent], turn=6) == 1
    assert naktamun["prepared"] is True


def test_charmbreaker_devils_returns_random_spell_and_gets_plus_four():
    battle = load_battle()
    active = player(battle, "Charmbreaker")
    charm_effect = battle.get_card_effect(card("Charmbreaker Devils", "Creature - Devil", 6, "{5}{R}"))
    charm = {**card("Charmbreaker Devils", "Creature - Devil", 6, "{5}{R}"), **charm_effect}
    spell = card("Lightning Bolt", "Instant", 1)
    creature = card("Goblin Guide", "Creature - Goblin", 1)
    active.battlefield = [charm]
    active.graveyard = [spell, creature]

    returned = battle.process_random_instant_sorcery_upkeep_return(active, turn=6, rng=random.Random(6))
    stack = battle.Stack()
    battle.trigger_spell_cast_engines(
        active,
        [active],
        card("Faithless Looting", "Sorcery", 1),
        turn=6,
        phase="precombat_main",
        stack=stack,
        active_player=active,
    )
    while not stack.empty() or battle._pending_triggers:
        battle.priority_round(active, [active], stack, turn=6, rng=random.Random(6), phase="precombat_main")

    assert returned == 1
    assert spell in active.hand
    assert charm["power"] == 8
    assert charm["toughness"] == 4


def test_deathbellow_war_cry_tutors_four_different_name_minotaurs_to_battlefield():
    battle = load_battle()
    active = player(battle, "Deathbellow")
    opponent = player(battle, "Opponent")
    active.library = [
        card("Neheb, the Eternal", "Legendary Creature - Zombie Minotaur Warrior", 5, power=4, toughness=6),
        card("Ahn-Crop Crasher", "Creature - Minotaur Warrior", 3, power=3, toughness=2),
        card("Ahn-Crop Crasher", "Creature - Minotaur Warrior", 3, power=3, toughness=2),
        card("Rageblood Shaman", "Creature - Minotaur Shaman", 3, power=2, toughness=3),
        card("Seasoned Pyromancer", "Creature - Human Shaman", 3, power=2, toughness=2),
    ]

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Deathbellow War Cry", "Sorcery", 8, "{5}{R}{R}{R}"),
        turn=7,
        rng=random.Random(7),
        stack=battle.Stack(),
        phase="precombat_main",
    )

    battlefield_names = [permanent.get("name") for permanent in active.battlefield]
    assert "Neheb, the Eternal" in battlefield_names
    assert "Ahn-Crop Crasher" in battlefield_names
    assert "Rageblood Shaman" in battlefield_names
    assert battlefield_names.count("Ahn-Crop Crasher") == 1
    assert "Seasoned Pyromancer" not in battlefield_names


if __name__ == "__main__":
    test_final_eight_get_card_effects_use_exact_runtime_scopes()
    test_blood_moon_makes_nonbasic_lands_produce_red_only()
    test_karn_great_creator_locks_opponent_artifact_mana_abilities()
    test_chandras_ignition_uses_target_creature_power_and_spares_source()
    test_karns_sylex_activates_x_wipe_and_exiles_source()
    test_naktamun_prepares_on_upkeep_and_casts_wheel_face()
    test_charmbreaker_devils_returns_random_spell_and_gets_plus_four()
    test_deathbellow_war_cry_tutors_four_different_name_minotaurs_to_battlefield()
    print("PASS test_lorehold_runtime_gap_final_eight")
