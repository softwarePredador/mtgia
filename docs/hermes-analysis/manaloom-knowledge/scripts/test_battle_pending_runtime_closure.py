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
        "aura_static_attachment",
        "graveyard_to_library_top",
        "temporary_exile_return_next_end_step",
        "tutor_artifact",
        "untap_lands",
    }:
        assert effect in forensic.SUPPORTED_EFFECTS


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
