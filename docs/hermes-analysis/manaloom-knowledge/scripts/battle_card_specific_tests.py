"""Card-specific Commander regression tests for battle_analyst_v9."""

import random


def _card(name, cmc=99, effect="unknown", power=0):
    return {
        "name": name,
        "cmc": cmc,
        "tag": effect,
        "effect": effect,
        "type_line": "Creature" if effect == "creature" else "Sorcery",
        "power": power,
    }


def register_tests(battle, player):
    def test_lorehold_miracle_requires_lorehold_on_battlefield():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                _card("Filler"),
            ],
        )
        active.is_human = True
        active.battlefield = ["land", "land"]
        opponent = player("Opponent", [_card("Opp Filler")])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(17),
            stack=battle.Stack(),
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_lorehold_miracle_casts_first_draw_only_with_lorehold():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                *[_card(f"Filler {index}") for index in range(10)],
            ],
        )
        active.is_human = True
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            "land",
            "land",
        ]
        opponent = player("Opponent", [_card("Opp Filler")])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(18),
            stack=battle.Stack(),
        )

        assert any(event == "miracle_cast" for event, _ in events)
        assert active.graveyard[0]["name"] == "Reforge the Soul"

    def test_lorehold_miracle_does_not_use_second_draw_of_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player(
            "Lorehold",
            [
                _card("Upkeep Draw"),
                {
                    "name": "Reforge the Soul",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                _card("Filler"),
            ],
        )
        active.is_human = True
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            {"name": "The One Ring", "effect": "draw_engine", "burden": True},
            "land",
            "land",
        ]
        opponent = player("Opponent", [_card("Opp Filler")])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(19),
            stack=battle.Stack(),
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_boros_charm_protects_creatures_until_cleanup():
        active = player("Lorehold")
        active.is_human = True
        active.hand = [{"name": "Boros Charm", "cmc": 2, "type_line": "Instant"}]
        creature = {
            "name": "Protected Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": False,
        }
        active.battlefield = [creature, "land", "land"]
        active.refresh_mana_sources(turn=2)
        caster = player("Caster")
        wipe = {"name": "Blasphemous Act", "cmc": 9, "type_line": "Sorcery"}
        stack = battle.Stack()
        stack.push(wipe, caster, battle.get_card_effect(wipe))

        assert battle.priority_round(caster, [caster, active], stack, 2, random.Random(20))
        while not stack.empty():
            battle.priority_round(caster, [caster, active], stack, 2, random.Random(20))

        assert creature in active.battlefield
        assert creature["indestructible"] is True
        battle.clear_until_eot(active)
        assert "indestructible" not in creature

    def test_akromas_will_keywords_are_until_end_of_turn_without_power_boost():
        active = player("Lorehold")
        creature = {
            "name": "Combat Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
        }
        active.battlefield = [creature]
        akroma = {"name": "Akroma's Will", "cmc": 4, "type_line": "Instant"}

        battle.apply_effect_immediate(active, [], akroma, 2, random.Random(21))

        assert creature["power"] == 3
        assert creature["flying"] is True
        assert creature["double_strike"] is True
        assert creature["lifelink"] is True
        assert creature["indestructible"] is True
        battle.clear_until_eot(active)
        assert creature["power"] == 3
        assert "flying" not in creature
        assert "double_strike" not in creature
        assert "lifelink" not in creature
        assert "indestructible" not in creature

    def test_silence_effect_blocks_counterspell_responses():
        active = player("Active")
        active.silenced_opponents = True
        active.approach_count = 1
        responder = player("Responder")
        responder.hand = [
            {
                "name": "Real Counter",
                "cmc": 2,
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        responder.battlefield = ["land", "land"]
        responder.refresh_mana_sources(turn=3)
        spell = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        stack = battle.Stack()
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active, responder], stack, 3, random.Random(22))

        assert active.has_won() is True
        assert responder.hand[0]["name"] == "Real Counter"

    def test_lorehold_miracle_ignores_lands_and_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = battle.Player(
            "Lorehold",
            None,
            [
                {
                    "name": "Mana Confluence",
                    "cmc": 0,
                    "type_line": "Land",
                    "oracle_text": "{T}: Add one mana of any color.",
                    "effect": "land",
                    "tag": "land",
                },
                {
                    "name": "Drannith Magistrate",
                    "cmc": 2,
                    "type_line": "Creature",
                    "oracle_text": "Your opponents can't cast spells from anywhere other than their hands.",
                },
            ],
            is_human=True,
        )
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "haste": True},
            {"name": "Plains", "effect": "land", "type_line": "Land"},
            {"name": "Mountain", "effect": "land", "type_line": "Land"},
        ]
        defender = player("Defender", [_card("Draw")])

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=3,
            rng=random.Random(31),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert not [event for event, _ in events if event == "miracle_cast"]

    def test_lorehold_miracle_rejects_flash_creatures():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = battle.Player(
            "Lorehold",
            None,
            [
                {
                    "name": "Dualcaster Mage",
                    "cmc": 3,
                    "type_line": "Creature — Human Wizard",
                    "oracle_text": "Flash",
                    "keywords": ["Flash"],
                },
            ],
            is_human=True,
        )
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "haste": True},
            {"name": "Plains", "effect": "land", "type_line": "Land"},
            {"name": "Mountain", "effect": "land", "type_line": "Land"},
        ]
        defender = player("Defender", [_card("Draw")])

        battle.play_turn_v8(
            active,
            [defender],
            [active, defender],
            turn=3,
            rng=random.Random(39),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        dualcaster = {
            "name": "Dualcaster Mage",
            "type_line": "Creature — Human Wizard",
            "keywords": ["Flash"],
        }
        assert battle.is_instant(dualcaster)
        assert not battle.is_instant_or_sorcery_spell(dualcaster)
        assert not [event for event, _ in events if event == "miracle_cast"]

    def test_silence_spell_blocks_responses_until_cleanup_only():
        active = player("Active")
        responder = player("Responder")
        responder.hand = [
            {
                "name": "Real Counter",
                "cmc": 2,
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        responder.battlefield = ["land", "land"]
        responder.refresh_mana_sources(turn=3)

        battle.apply_effect_immediate(
            active,
            [responder],
            {"name": "Silence", "cmc": 1, "type_line": "Instant"},
            3,
            random.Random(78),
        )
        stack = battle.Stack()
        spell = {"name": "Approach of the Second Sun", "cmc": 7, "type_line": "Sorcery"}
        stack.push(spell, active, battle.get_card_effect(spell))

        battle.priority_round(active, [active, responder], stack, 3, random.Random(78))

        assert active.silenced_opponents_until_eot is True
        assert responder.hand[0]["name"] == "Real Counter"
        battle.clear_until_eot(active)
        assert active.silenced_opponents_until_eot is False

    return [
        test_lorehold_miracle_requires_lorehold_on_battlefield,
        test_lorehold_miracle_casts_first_draw_only_with_lorehold,
        test_lorehold_miracle_does_not_use_second_draw_of_turn,
        test_boros_charm_protects_creatures_until_cleanup,
        test_akromas_will_keywords_are_until_end_of_turn_without_power_boost,
        test_silence_effect_blocks_counterspell_responses,
        test_lorehold_miracle_ignores_lands_and_creatures,
        test_lorehold_miracle_rejects_flash_creatures,
        test_silence_spell_blocks_responses_until_cleanup_only,
    ]
