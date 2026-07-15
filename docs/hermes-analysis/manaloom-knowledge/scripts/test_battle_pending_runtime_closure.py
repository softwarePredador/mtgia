#!/usr/bin/env python3
"""Focused regressions for the live battle-audit closure queue."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPT_DIR / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_module("battle_pending_runtime_closure", "battle_analyst_v9.py")
forensic = load_module("battle_pending_forensic_closure", "battle_forensic_audit.py")
critic = load_module("battle_pending_action_critic_closure", "battle_action_critic.py")
replay_auditor = load_module("battle_pending_replay_auditor_closure", "replay_decision_auditor.py")


def capture_events():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append({"event": event, **data})
    battle.DECISION_TRACE_HANDLER = None
    return events


def card(name, type_line, **fields):
    return {"name": name, "type_line": type_line, "cmc": fields.pop("cmc", 1), **fields}


def test_noxious_revival_moves_any_graveyard_target_to_its_owners_library_top():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [card("Existing Top", "Land", cmc=0)])
    target = card("Graveyard Bomb", "Sorcery", cmc=8, owner="Opponent")
    opponent.graveyard.append(target)
    effect = {
        "effect": "graveyard_to_library_top",
        "target": "card",
        "target_controller": "any_player",
        "destination": "owners_library_top",
        "owner_library_destination": True,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:noxious_fixture",
    }

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Noxious Revival", "Instant"),
        turn=3,
        rng=random.Random(1),
        effect_data_override=effect,
        phase="precombat_main",
    )

    assert target not in opponent.graveyard
    assert opponent.library[0] is target
    assert active.library == []
    assert any(
        event["event"] == "graveyard_to_library_top_resolved"
        and event.get("target_owners") == ["Opponent"]
        and event.get("destination") == "owners_library_top"
        for event in events
    )


def test_touch_the_spirit_realm_temporarily_exiles_then_returns_under_owner_control():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [])
    active.battlefield.append(
        card("Own High Value Artifact", "Legendary Artifact", cmc=9, effect="draw_engine")
    )
    target = card(
        "Threat",
        "Creature - Giant",
        cmc=7,
        power=7,
        toughness=7,
        owner="Opponent",
        controller="Opponent",
    )
    opponent.battlefield.append(target)
    effect = {
        "effect": "temporary_exile_return_next_end_step",
        "target": "artifact_or_creature",
        "return_trigger": "next_end_step",
        "return_destination": "battlefield_under_owners_control",
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:touch_fixture",
    }

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Touch the Spirit Realm", "Enchantment"),
        turn=4,
        rng=random.Random(2),
        effect_data_override=effect,
        phase="precombat_main",
    )

    assert target in opponent.exile
    assert target not in opponent.battlefield
    assert any(card_["name"] == "Touch the Spirit Realm" for card_ in active.graveyard)
    battle.process_temporary_exile_returns(
        active,
        [active, opponent],
        turn=4,
        rng=random.Random(3),
    )
    assert target not in opponent.exile
    assert any(permanent["name"] == "Threat" for permanent in opponent.battlefield)
    assert not any(permanent["name"] == "Threat" for permanent in active.battlefield)
    assert any(
        event["event"] == "temporary_exile_returned"
        and event.get("owner") == "Opponent"
        and event.get("result") == "returned_under_owners_control"
        for event in events
    )


def test_wishclaw_enters_with_counters_then_tutors_and_transfers_control():
    events = capture_events()
    active = battle.Player("Active", None, [card("Best Card", "Sorcery", cmc=9)])
    opponent = battle.Player("Opponent", None, [])
    effect = {
        "effect": "tutor_artifact",
        "artifact": True,
        "enters_with_wish_counters": 3,
        "activated_wish_counter_tutor_to_hand": True,
        "activated_tutor_target": "any",
        "activation_cost_generic": 1,
        "activation_requires_tap": True,
        "activation_requires_remove_counter_count": 1,
        "opponent_gains_control_after_activation": True,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:wishclaw_fixture",
    }

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Wishclaw Talisman", "Artifact", cmc=2),
        turn=2,
        rng=random.Random(4),
        effect_data_override=effect,
        phase="precombat_main",
    )
    talisman = next(permanent for permanent in active.battlefield if permanent["name"] == "Wishclaw Talisman")
    assert talisman["wish_counters"] == 3
    active.mana_pool.generic = 1

    assert battle.activate_wish_counter_tutor_artifact(
        active,
        [opponent],
        talisman,
        turn=2,
        rng=random.Random(5),
        phase="precombat_main",
    )

    assert [item["name"] for item in active.hand] == ["Best Card"]
    assert talisman not in active.battlefield
    assert talisman in opponent.battlefield
    assert talisman["wish_counters"] == 2
    assert talisman["tapped"] is True
    assert talisman["controller"] == "Opponent"
    assert talisman not in active.graveyard
    assert any(
        event["event"] == "utility_artifact_activated"
        and event.get("activation_kind") == "wish_counter_tutor_to_hand_control_transfer"
        and event.get("result") == "tutored_and_control_transferred"
        for event in events
    )


def test_wishclaw_scanner_ignores_legacy_non_mapping_battlefield_entries():
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [])
    active.battlefield.append("legacy_fixture_permanent")

    assert not battle.activate_wish_counter_tutor_artifact(
        active,
        [opponent],
        active.battlefield[0],
        turn=1,
        rng=random.Random(5),
    )


def test_forensic_registry_accepts_only_now_executable_pending_effects():
    for effect in {
        "additional_land_play_static",
        "ad_nauseam",
        "aura_static_attachment",
        "blink_multiple",
        "exile_each_opponent_nonland_until_source_leaves",
        "graveyard_to_library_top",
        "opponent_graveyard_betrayal",
        "temporary_exile_return_next_end_step",
        "tutor_artifact",
        "untap_lands",
        "untap_tapped_permanent_etb_engine",
    }:
        assert effect in forensic.SUPPORTED_EFFECTS


def test_ad_nauseam_reveals_until_the_verified_life_floor_choice():
    events = capture_events()
    active = battle.Player(
        "Active",
        None,
        [
            card("Free Spell", "Instant", cmc=0),
            card("Three Drop", "Creature", cmc=3),
            card("Unsafe Five Drop", "Sorcery", cmc=5),
        ],
    )
    active.life = 7
    effect = {
        "effect": "ad_nauseam",
        "ad_nauseam_life_floor": 1,
        "stop_before_life_below_floor": True,
        "exiles_self": False,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:ad_nauseam_fixture",
    }
    source = card("Ad Nauseam", "Instant", cmc=5)

    battle.apply_effect_immediate(
        active,
        [],
        source,
        turn=5,
        rng=random.Random(10),
        effect_data_override=effect,
        phase="end_step",
    )

    assert [item["name"] for item in active.hand] == ["Free Spell", "Three Drop"]
    assert [item["name"] for item in active.library] == ["Unsafe Five Drop"]
    assert active.life == 4
    assert source in active.graveyard
    resolved = next(event for event in events if event["event"] == "ad_nauseam_resolved")
    assert resolved["revealed_count"] == 2
    assert resolved["life_lost"] == 3
    assert resolved["stop_reason"] == "life_floor_choice"


def test_mnemonic_betrayal_exiles_opponent_graveyards_then_returns_remaining_cards():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent_a = battle.Player("Opponent A", None, [])
    opponent_b = battle.Player("Opponent B", None, [])
    card_a = card("A Spell", "Instant", cmc=1)
    card_b = card("A Land", "Land", cmc=0)
    card_c = card("B Creature", "Creature", cmc=2)
    opponent_a.graveyard.extend([card_a, card_b])
    opponent_b.graveyard.append(card_c)
    source = card("Mnemonic Betrayal", "Sorcery", cmc=3)
    effect = {
        "effect": "opponent_graveyard_betrayal",
        "cast_permission_duration": "until_end_of_turn",
        "cast_permission_status": "tracked_not_selected_by_ai",
        "mana_any_type_for_casting": True,
        "return_trigger": "next_end_step",
        "exiles_self": True,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:betrayal_fixture",
    }

    battle.apply_effect_immediate(
        active,
        [opponent_a, opponent_b],
        source,
        turn=6,
        rng=random.Random(11),
        effect_data_override=effect,
        phase="precombat_main",
    )

    assert opponent_a.graveyard == []
    assert opponent_b.graveyard == []
    assert opponent_a.exile == [card_a, card_b]
    assert opponent_b.exile == [card_c]
    assert source in active.exile
    assert card_a["_betrayal_permission_controller"] == "Active"

    returned = battle.process_opponent_graveyard_betrayal_returns(
        active,
        [active, opponent_a, opponent_b],
        turn=6,
    )
    assert returned == [card_a, card_b, card_c]
    assert opponent_a.exile == []
    assert opponent_b.exile == []
    assert opponent_a.graveyard == [card_a, card_b]
    assert opponent_b.graveyard == [card_c]
    assert "_betrayal_permission_controller" not in card_a
    assert any(
        event["event"] == "opponent_graveyard_betrayal_resolved"
        and event.get("exiled_count") == 3
        for event in events
    )
    assert any(
        event["event"] == "opponent_graveyard_betrayal_returned"
        and event.get("returned_count") == 3
        for event in events
    )


def test_hidden_zone_tutor_miss_with_exhausted_candidates_is_not_a_turn_finding():
    findings = replay_auditor.audit_turn_events(
        [
            {
                "event": "tutor_resolved",
                "replay_id": "seed_fixture",
                "turn": 4,
                "player": "Active",
                "card": "Spellseeker",
                "found": None,
                "candidate_count": 0,
                "no_target_reason": "library_has_no_legal_candidate",
                "search_zone_hidden": True,
                "search_may_fail_to_find": True,
            }
        ]
    )
    assert findings == []


def test_action_critic_accepts_paid_counter_tax_as_legal_result():
    report = critic.criticize_actions(
        [
            {
                "event": "spell_countered",
                "turn": 5,
                "phase": "precombat_main",
                "player": "Counter Pilot",
                "counter": "Mana Leak",
                "target": "Threat",
                "stack_object": "Threat",
                "priority_window": "stack_response",
                "result": "not_countered_tax_paid",
            }
        ]
    )
    findings = [
        finding
        for action in report["actions"]
        for finding in action.get("findings", [])
    ]
    assert not any(finding["code"] == "counter_without_result" for finding in findings)


def test_response_effect_copy_keeps_resolution_provenance():
    events = capture_events()
    active = battle.Player("Active", None, [])
    effect = {
        "effect": "indestructible",
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:protection_fixture",
    }
    response_effect = dict(effect)
    source = card("Protection Fixture", "Instant")
    battle.attach_direct_resolution_context(
        response_effect,
        source,
        "precombat_main",
        priority_window="response_direct_resolution",
        locked_cost={"generic": 1},
    )

    battle.apply_effect_immediate(
        active,
        [],
        source,
        turn=6,
        rng=random.Random(6),
        effect_data_override=response_effect,
        phase="precombat_main",
    )

    resolved = next(event for event in events if event["event"] == "spell_resolved")
    for field in (
        "phase",
        "priority_window",
        "stack_depth",
        "source_zone",
        "from_zone",
        "cast_pipeline",
        "locked_cost",
        "resolved_from_stack",
    ):
        assert field in resolved


def test_activated_ability_cost_is_not_paid_while_casting_its_permanent():
    events = capture_events()
    active = battle.Player("Active", None, [])
    only_land = card("Forest", "Basic Land - Forest", cmc=0, effect="land")
    active.battlefield.append(only_land)
    effect = {
        "effect": "creature",
        "ability_kind": "activated",
        "requires_sacrifice_land": True,
        "activation_cost_generic": 2,
    }

    assert battle.additional_card_costs_are_payable_for_spell_cast(
        active,
        card("Elvish Reclaimer", "Creature - Elf Warrior"),
        effect,
    )
    assert battle.pay_additional_card_costs(
        active,
        card("Elvish Reclaimer", "Creature - Elf Warrior"),
        effect,
        turn=1,
        cost_purpose="spell_cast",
    )
    assert active.battlefield == [only_land]
    assert active.graveyard == []
    assert not any(event["event"] == "additional_cost_paid" for event in events)


def test_land_ramp_does_not_pay_a_cast_sacrifice_again_on_resolution():
    events = capture_events()
    active = battle.Player(
        "Active",
        None,
        [card("Gaea's Cradle", "Legendary Land", cmc=0)],
    )
    surviving_land = card("Forest", "Basic Land - Forest", cmc=0, effect="land")
    active.battlefield.append(surviving_land)
    effect = {
        "effect": "land_ramp",
        "requires_sacrifice_land": True,
        "_additional_card_costs_paid": True,
        "land_count": 1,
        "land_enters_tapped": False,
    }

    found = battle.put_lands_from_library(
        active,
        card("Crop Rotation", "Instant"),
        effect,
        turn=1,
        opponents=[],
    )

    assert [land["name"] for land in found] == ["Gaea's Cradle"]
    assert surviving_land in active.battlefield
    assert active.graveyard == []
    assert not any(
        event["event"] == "additional_cost_paid" and event.get("cost") == "sacrifice_land"
        for event in events
    )


def test_amulet_family_untaps_a_permanent_that_enters_tapped():
    events = capture_events()
    active = battle.Player("Active", None, [])
    active.battlefield.append(
        card(
            "Amulet Fixture",
            "Artifact",
            effect="untap_tapped_permanent_etb_engine",
            untap_tapped_permanent_on_entry=True,
        )
    )

    entered = battle.prepare_entering_permanent(
        card("Tapped Land", "Land", cmc=0, enters_tapped=True),
        controller=active,
        all_players=[active],
        turn=2,
    )

    assert entered["tapped"] is False
    assert any(
        event["event"] == "tapped_permanent_entry_untapped"
        and event.get("card") == "Tapped Land"
        and event.get("source_count") == 1
        for event in events
    )


def test_exploration_family_allows_exactly_one_additional_land_play():
    capture_events()
    active = battle.Player("Active", None, [])
    active.hand = [
        card("Forest A", "Basic Land - Forest", cmc=0, effect="land"),
        card("Forest B", "Basic Land - Forest", cmc=0, effect="land"),
        card("Forest C", "Basic Land - Forest", cmc=0, effect="land"),
    ]
    effect = {
        "effect": "additional_land_play_static",
        "additional_land_plays_each_turn": 1,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
    }
    battle.apply_effect_immediate(
        active,
        [],
        card("Exploration Fixture", "Enchantment", cmc=1),
        turn=1,
        rng=random.Random(20),
        effect_data_override=effect,
        phase="precombat_main",
    )

    stack = battle.Stack()
    for _ in range(2):
        candidate = battle.choose_land_play_candidate(active, [])
        assert candidate is not None
        assert battle.play_land_candidate(active, [], [active], 1, stack, candidate)

    assert active.lands_played_this_turn == 2
    assert active.max_lands_per_turn == 2
    assert battle.choose_land_play_candidate(active, []) is None


def test_ghostly_flicker_family_requires_and_returns_two_controlled_targets():
    events = capture_events()
    active = battle.Player("Active", None, [card("Drawn", "Instant", cmc=1)])
    artifact = card("Value Rock", "Artifact", cmc=2, tapped=True)
    creature = card(
        "Value Creature",
        "Creature - Wizard",
        cmc=3,
        power=2,
        toughness=2,
        etb_draw_count=1,
    )
    active.battlefield.extend([artifact, creature])
    effect = {
        "effect": "blink_multiple",
        "blink_target_scope": "artifact_creature_or_land_you_control",
        "target_count_min": 2,
        "target_count_max": 2,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
    }

    battle.apply_effect_immediate(
        active,
        [],
        card("Ghostly Flicker Fixture", "Instant", cmc=3),
        turn=3,
        rng=random.Random(21),
        effect_data_override=effect,
        phase="precombat_main",
    )

    assert sorted(permanent["name"] for permanent in active.battlefield) == [
        "Value Creature",
        "Value Rock",
    ]
    assert [item["name"] for item in active.hand] == ["Drawn"]
    resolved = next(event for event in events if event["event"] == "blink_multiple_resolved")
    assert resolved["target_count"] == 2
    assert sorted(resolved["targets"]) == ["Value Creature", "Value Rock"]


def test_grasp_family_exiles_one_nonland_per_opponent_until_source_leaves():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent_a = battle.Player("Opponent A", None, [])
    opponent_b = battle.Player("Opponent B", None, [])
    threat_a = card("Threat A", "Creature - Giant", cmc=7, power=7, toughness=7)
    spare_a = card("Spare A", "Artifact", cmc=1)
    threat_b = card("Threat B", "Planeswalker", cmc=6)
    land_b = card("Land B", "Land", cmc=0)
    opponent_a.battlefield.extend([threat_a, spare_a])
    opponent_b.battlefield.extend([threat_b, land_b])
    effect = {
        "effect": "exile_each_opponent_nonland_until_source_leaves",
        "target": "up_to_one_nonland_permanent_each_opponent_controls",
        "_rule_source": "curated",
        "_rule_review_status": "verified",
    }

    battle.apply_effect_immediate(
        active,
        [opponent_a, opponent_b],
        card("Grasp Fixture", "Enchantment", cmc=3),
        turn=4,
        rng=random.Random(22),
        effect_data_override=effect,
        phase="precombat_main",
    )

    grasp = next(permanent for permanent in active.battlefield if permanent["name"] == "Grasp Fixture")
    assert threat_a in opponent_a.exile
    assert threat_b in opponent_b.exile
    assert spare_a in opponent_a.battlefield
    assert land_b in opponent_b.battlefield
    exiled_event = next(
        event for event in events if event["event"] == "exile_each_opponent_nonland_resolved"
    )
    assert [entry["link_id"] for entry in exiled_event["exiled"]] == [
        "grasp fixture:4:1:0",
        "grasp fixture:4:1:1",
    ]

    battle.move_permanent_from_battlefield(
        active,
        grasp,
        reason="destroy",
        all_players=[active, opponent_a, opponent_b],
    )

    assert any(permanent["name"] == "Threat A" for permanent in opponent_a.battlefield)
    assert any(permanent["name"] == "Threat B" for permanent in opponent_b.battlefield)
    assert opponent_a.exile == []
    assert opponent_b.exile == []
    assert any(
        event["event"] == "linked_exile_cards_returned"
        and event.get("returned_count") == 2
        for event in events
    )


def test_cast_scanner_does_not_announce_a_known_illegal_spell():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [])
    active.hand = [card("The One Ring", "Legendary Artifact", cmc=4, mana_cost="{4}")]
    active.mana_pool.generic = 10
    active.spells_cast_this_turn = 1
    active.static_spell_limit_restrictions = [
        {
            "source": "Limit Fixture",
            "spell_limit_per_turn": 1,
            "restricted_spell_scope": "spells",
        }
    ]
    original_get_card_effect = battle.get_card_effect
    battle.get_card_effect = lambda candidate: (
        {"effect": "passive", "artifact": True}
        if candidate.get("name") == "The One Ring"
        else original_get_card_effect(candidate)
    )
    try:
        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(23),
            max_actions=1,
        )
    finally:
        battle.get_card_effect = original_get_card_effect

    assert acted is False
    assert not any(
        event["event"] in {"cast_announced", "cast_illegal"}
        and event.get("card") == "The One Ring"
        for event in events
    )


def test_copy_token_preserves_intrinsic_haste_and_is_combat_legal():
    events = capture_events()
    active = battle.Player("Active", None, [])
    opponent = battle.Player("Opponent", None, [])
    lorehold = card(
        "Lorehold, the Historian",
        "Legendary Creature - Elder Dragon",
        cmc=5,
        power=5,
        toughness=5,
        oracle_text="Flying, haste",
        keywords=["flying", "haste"],
    )
    opponent.battlefield.append(lorehold)
    clone_legion = card("Clone Legion", "Sorcery", cmc=9)
    effect = {
        "effect": "copy_creature_token",
        "copy_target_types": ["creature"],
        "target_controller": "opponent",
        "copy_all_matching_targets": True,
        "_rule_source": "curated",
        "_rule_review_status": "verified",
        "_rule_logical_key": "battle_rule_v1:clone_legion_fixture",
    }

    created = battle.resolve_copy_creature_token(
        active,
        clone_legion,
        effect,
        turn=10,
        opponents=[opponent],
        finish_spell=False,
    )

    assert created and len(created) == 1
    token = created[0]
    assert token["copy_of"] == "Lorehold, the Historian"
    assert token["haste"] is True
    assert token["summoning_sick"] is False
    assert battle.can_attack_this_combat(token) is True
    assert any(
        event["event"] == "copy_creature_token_created"
        and event.get("target") == "Lorehold, the Historian"
        and event.get("haste") is True
        for event in events
    )


if __name__ == "__main__":
    tests = [
        test_noxious_revival_moves_any_graveyard_target_to_its_owners_library_top,
        test_touch_the_spirit_realm_temporarily_exiles_then_returns_under_owner_control,
        test_wishclaw_enters_with_counters_then_tutors_and_transfers_control,
        test_wishclaw_scanner_ignores_legacy_non_mapping_battlefield_entries,
        test_forensic_registry_accepts_only_now_executable_pending_effects,
        test_action_critic_accepts_paid_counter_tax_as_legal_result,
        test_response_effect_copy_keeps_resolution_provenance,
        test_activated_ability_cost_is_not_paid_while_casting_its_permanent,
        test_land_ramp_does_not_pay_a_cast_sacrifice_again_on_resolution,
        test_ad_nauseam_reveals_until_the_verified_life_floor_choice,
        test_mnemonic_betrayal_exiles_opponent_graveyards_then_returns_remaining_cards,
        test_hidden_zone_tutor_miss_with_exhausted_candidates_is_not_a_turn_finding,
        test_amulet_family_untaps_a_permanent_that_enters_tapped,
        test_exploration_family_allows_exactly_one_additional_land_play,
        test_ghostly_flicker_family_requires_and_returns_two_controlled_targets,
        test_grasp_family_exiles_one_nonland_per_opponent_until_source_leaves,
        test_cast_scanner_does_not_announce_a_known_illegal_spell,
        test_copy_token_preserves_intrinsic_haste_and_is_combat_legal,
    ]
    for test in tests:
        test()
    print(f"{len(tests)} tests passed")
