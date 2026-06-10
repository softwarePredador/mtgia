"""Formal targeting regression tests for battle_analyst_v9."""

import random


def register_tests(battle, player):
    def test_formal_targeting_rejects_opponent_hexproof_creature():
        caster = player("Caster")
        opponent = player("Opponent")
        protected = {
            "name": "Hexproof Creature",
            "type_line": "Creature",
            "effect": "creature",
            "hexproof": True,
        }
        exposed = {
            "name": "Exposed Creature",
            "type_line": "Creature",
            "effect": "creature",
        }
        opponent.battlefield = [protected, exposed]
        spell = {"name": "Targeted Removal", "type_line": "Instant", "colors": ["black"]}

        targets = battle.removal_target_candidates(
            opponent,
            {"effect": "remove_creature", "target": "creature"},
            controller=caster,
            source=spell,
        )

        assert [target["name"] for target in targets] == ["Exposed Creature"]

    def test_formal_targeting_respects_protection_from_source_color():
        caster = player("Caster")
        opponent = player("Opponent")
        protected = {
            "name": "White Protected Creature",
            "type_line": "Creature",
            "effect": "creature",
            "protection_from": ["white"],
        }
        opponent.battlefield = [protected]
        white_spell = {"name": "White Removal", "type_line": "Instant", "colors": ["W"]}
        black_spell = {"name": "Black Removal", "type_line": "Instant", "colors": ["B"]}

        assert battle.is_legal_target(
            white_spell,
            protected,
            caster,
            target_type="creature",
            target_controller=opponent,
        ) is False
        assert battle.is_legal_target(
            black_spell,
            protected,
            caster,
            target_type="creature",
            target_controller=opponent,
        ) is True

    def test_formal_targeting_keeps_ward_as_legal_target():
        caster = player("Caster")
        opponent = player("Opponent")
        ward_creature = {
            "name": "Ward Creature",
            "type_line": "Creature",
            "effect": "creature",
            "ward": 2,
        }
        spell = {"name": "Removal", "type_line": "Instant", "colors": ["black"]}

        assert battle.is_legal_target(
            spell,
            ward_creature,
            caster,
            target_type="creature",
            target_controller=opponent,
        ) is True

    def test_removal_replay_includes_formal_targeting_metadata():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            opponent = player("Opponent")
            opponent.battlefield = [
                {
                    "name": "Target Creature",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                }
            ]
            spell = {
                "name": "Swords to Plowshares",
                "type_line": "Instant",
                "colors": ["W"],
            }

            battle.apply_effect_immediate(caster, [opponent], spell, turn=4, rng=random.Random(121))

            removal_event = next(data for event, data in events if event == "removal_resolved")
            assert removal_event["targeting_pipeline"] == "targeting_formal_minimal"
            assert removal_event["target_name"] == "Target Creature"
            assert removal_event["target_legal"] is True
            assert removal_event["target_type"] == "creature"
            assert removal_event["target_controller"] == "Opponent"
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_multi_target_removal_partially_resolves_legal_targets():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_known = battle.KNOWN_CARDS.get("Forked Removal")
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            opponent = player("Opponent")
            legal_target = {
                "name": "Legal Target",
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
            }
            illegal_target = {
                "name": "Illegal Target",
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "shroud": True,
            }
            opponent.battlefield = [legal_target, illegal_target]
            battle.KNOWN_CARDS["Forked Removal"] = {
                "effect": "remove_creature",
                "target": "creature",
                "declared_targets": [
                    {"target": legal_target, "controller": opponent},
                    {"target": illegal_target, "controller": opponent},
                ],
            }
            spell = {
                "name": "Forked Removal",
                "type_line": "Instant",
                "colors": ["B"],
            }

            battle.apply_effect_immediate(caster, [opponent], spell, turn=6, rng=random.Random(140))

            assert legal_target not in opponent.battlefield
            assert illegal_target in opponent.battlefield
            assert spell in caster.graveyard
            multi_event = next(data for event, data in events if event == "multi_target_resolution")
            assert multi_event["resolved"] == ["Legal Target"]
            assert multi_event["illegal"] == ["Illegal Target"]
        finally:
            if previous_known is None:
                battle.KNOWN_CARDS.pop("Forked Removal", None)
            else:
                battle.KNOWN_CARDS["Forked Removal"] = previous_known
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_ward_counters_targeted_removal_when_unpaid():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            opponent = player("Opponent")
            ward_creature = {
                "name": "Ward Creature",
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "ward": 2,
            }
            opponent.battlefield = [ward_creature]
            spell = {
                "name": "Swords to Plowshares",
                "type_line": "Instant",
                "colors": ["W"],
            }

            battle.apply_effect_immediate(caster, [opponent], spell, turn=5, rng=random.Random(130))

            event_names = [event for event, _ in events]
            assert "ward_countered" in event_names
            assert "removal_countered_by_ward" in event_names
            assert "removal_resolved" not in event_names
            assert ward_creature in opponent.battlefield
            assert spell in caster.graveyard
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    def test_ward_paid_allows_targeted_removal_to_resolve():
        events = []
        previous_handler = battle.REPLAY_EVENT_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            caster = player("Caster")
            caster.is_human = True
            caster.mana_pool.add_generic(2)
            opponent = player("Opponent")
            ward_creature = {
                "name": "Ward Creature",
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "ward": 2,
            }
            opponent.battlefield = [ward_creature]
            spell = {
                "name": "Swords to Plowshares",
                "type_line": "Instant",
                "colors": ["W"],
            }

            battle.apply_effect_immediate(caster, [opponent], spell, turn=5, rng=random.Random(131))

            event_names = [event for event, _ in events]
            assert "ward_paid" in event_names
            assert "removal_resolved" in event_names
            assert ward_creature not in opponent.battlefield
            assert caster.available_mana() == 0
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler

    return [
        test_formal_targeting_rejects_opponent_hexproof_creature,
        test_formal_targeting_respects_protection_from_source_color,
        test_formal_targeting_keeps_ward_as_legal_target,
        test_removal_replay_includes_formal_targeting_metadata,
        test_multi_target_removal_partially_resolves_legal_targets,
        test_ward_counters_targeted_removal_when_unpaid,
        test_ward_paid_allows_targeted_removal_to_resolve,
    ]
