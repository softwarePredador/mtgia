"""Replacement and prevention conformance tests for battle_analyst_v9."""

import random


def register_tests(battle, player):
    def test_life_cant_change_prevents_damage_and_life_gain():
        active = player("Active")
        active.life = 20
        teferi = {"name": "Teferi's Protection", "cmc": 3, "type_line": "Instant"}

        battle.apply_effect_immediate(active, [], teferi, 2, random.Random(23))

        assert battle.deal_damage(active, 5) is False
        assert battle.gain_life(active, 7) is False
        assert active.life == 20

    def test_replacement_registry_prevents_damage_before_life_mutation():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append({"event": event, **data})
        active = player("Active")
        active.life = 3
        active.life_cant_change = True

        assert battle.deal_damage(active, 5) is False

        assert active.life == 3
        replacement = next(event for event in events if event["event"] == "replacement_applied")
        assert replacement["replacement_pipeline"] == "replacement_prevention_minimal"
        assert replacement["event_type"] == "damage"
        assert replacement["prevented"] is True
        assert replacement["replacements"] == ["life_total_cant_change"]
        assert replacement["replacement_order"] == ["life_total_cant_change"]
        assert replacement["original_amount"] == 5
        assert replacement["final_amount"] == 0
        assert replacement["original_delta"] == -5
        assert replacement["final_delta"] == 0
        assert replacement["replacement_rule_source"] == "life_total_cant_change"
        assert replacement["causal_event"]["replacement_rule_sources"] == ["life_total_cant_change"]

    def test_replacement_registry_moves_commander_to_command_zone():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append({"event": event, **data})
        active = player("Active")
        commander = {
            "name": "Test Commander",
            "type_line": "Legendary Creature",
            "is_commander": True,
            "owner": "Active",
        }
        active.battlefield = [commander]

        destination = battle.move_creature_from_battlefield(
            active,
            commander,
            reason="destroy",
            source="test",
            all_players=[active],
        )

        assert destination == "command_zone"
        assert commander in active.command_zone
        assert commander not in active.graveyard
        replacement = next(event for event in events if event["event"] == "replacement_applied")
        assert replacement["event_type"] == "zone_change"
        assert replacement["original_to_zone"] == "graveyard"
        assert replacement["final_to_zone"] == "command_zone"
        assert replacement["to_zone"] == "command_zone"
        assert replacement["source"] == "test"
        assert replacement["reason"] == "destroy"
        assert replacement["causal_event"]["source"] == "test"
        assert replacement["causal_event"]["reason"] == "destroy"
        assert replacement["replacements"] == ["commander_to_command_zone"]
        assert replacement["replacement_order"] == ["commander_to_command_zone"]
        assert replacement["replacement_rule_source"] == "commander_replacement_rule"

    def test_replacement_registry_uses_deterministic_priority_order():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append({"event": event, **data})
        active = player("Active")
        active.life = 20
        active.life_cant_change = True
        active.protection_from_everything = True
        battle.add_damage_prevention_shield(active, 5, source="Lower Priority Shield")

        assert battle.deal_damage(active, 4) is False

        assert active.life == 20
        assert active.damage_prevention_shields == [
            {"amount": 5, "source": "Lower Priority Shield"}
        ]
        replacement = next(event for event in events if event["event"] == "replacement_applied")
        assert replacement["replacement_order"] == ["life_total_cant_change"]
        assert replacement["replacements"] == ["life_total_cant_change"]
        assert replacement["original_amount"] == 4
        assert replacement["final_amount"] == 0

    def test_commander_zone_replacement_covers_exile_hand_and_library():
        active = player("Active")
        commander = {"name": "Zone Commander", "is_commander": True}

        for zone in ("exile", "hand", "library"):
            event = battle.ReplacementRegistry.process_event(
                battle.ReplacementEvent(
                    "zone_change",
                    affected_player=active,
                    card=commander,
                    from_zone="battlefield",
                    to_zone=zone,
                )
            )
            assert event.to_zone == "command_zone"
            assert event.replacements == ["commander_to_command_zone"]
            assert event.replacement_order == ["commander_to_command_zone"]

        commander["commander_replacement_choice"] = "exile"
        event = battle.ReplacementRegistry.process_event(
            battle.ReplacementEvent(
                "zone_change",
                affected_player=active,
                card=commander,
                from_zone="battlefield",
                to_zone="exile",
            )
        )
        assert event.to_zone == "exile"
        assert event.replacements == []
        assert event.replacement_order == []

    def test_damage_prevention_shield_partially_reduces_damage():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append({"event": event, **data})
        active = player("Active")
        active.life = 20
        assert battle.add_damage_prevention_shield(active, 3, source="Test Shield") is True

        assert battle.deal_damage(active, 5) is True

        assert active.life == 18
        assert active.damage_prevention_shields == []
        replacement = next(event for event in events if event["event"] == "replacement_applied")
        assert replacement["event_type"] == "damage"
        assert replacement["amount"] == 2
        assert replacement["replacements"] == ["damage_prevention_shield:Test Shield:3"]

    def test_damage_prevention_shield_fully_prevents_damage_and_clears_at_eot():
        active = player("Active")
        active.life = 20
        assert battle.add_damage_prevention_shield(active, 7, source="Full Shield") is True

        assert battle.deal_damage(active, 5) is False

        assert active.life == 20
        assert active.damage_prevention_shields == [{"amount": 2, "source": "Full Shield"}]
        battle.clear_until_eot(active)
        assert active.damage_prevention_shields == []

    return [
        test_life_cant_change_prevents_damage_and_life_gain,
        test_replacement_registry_prevents_damage_before_life_mutation,
        test_replacement_registry_moves_commander_to_command_zone,
        test_replacement_registry_uses_deterministic_priority_order,
        test_commander_zone_replacement_covers_exile_hand_and_library,
        test_damage_prevention_shield_partially_reduces_damage,
        test_damage_prevention_shield_fully_prevents_damage_and_clears_at_eot,
    ]
