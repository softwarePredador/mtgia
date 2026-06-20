"""Card-specific Commander regression tests for battle_analyst_v9."""

import random
import sqlite3
import tempfile
from pathlib import Path


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
        opponent.hand = [_card(f"Opp Keep {index}") for index in range(7)]

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

    def test_lorehold_miracle_skips_bad_wheel_refill():
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
                *[_card(f"Filler {index}") for index in range(4)],
            ],
        )
        active.is_human = True
        active.battlefield = [
            {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            "land",
            "land",
        ]
        opponent = player("Opponent", [])

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(191),
            stack=battle.Stack(),
        )

        assert not any(event == "miracle_cast" for event, _ in events)
        assert any(c.get("name") == "Reforge the Soul" for c in active.hand)

    def test_lorehold_miracle_does_not_cast_counter_without_stack_target():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            py = {
                "name": "Pyroblast",
                "cmc": 1,
                "type_line": "Instant",
                "effect": "counter",
                "tag": "counter",
            }
            active = player("Lorehold", [py])
            active.hand = [py]
            active.is_human = True
            active.battlefield = [
                {"name": "Lorehold, the Historian", "effect": "creature", "power": 3},
            ]
            active.mana_pool.add_generic(2)
            stack = battle.Stack()

            cast = battle.try_lorehold_miracle_cast(
                active,
                [py],
                turn=2,
                phase="upkeep",
                all_players=[active],
                rng=random.Random(192),
                stack=stack,
                source="test_topdeck",
                miracle_candidate=py,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert cast is False
        assert py in active.hand
        assert stack.empty()
        assert not any(event == "miracle_cast" for event, _ in events)

    def test_landfall_does_not_enqueue_without_real_landfall_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            land = {"name": "Sunbillow Verge", "effect": "land", "type_line": "Land"}
            active.battlefield = [land]
            stack = battle.Stack()

            triggered = battle.trigger_landfall(
                active,
                land,
                turn=2,
                source_event="land_played",
                stack=stack,
                active_player=active,
                all_players=[active],
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert triggered is False
        assert stack.empty()
        assert not any(event == "trigger_put_on_stack" for event, _ in events)

    def test_landfall_enqueue_with_real_landfall_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        try:
            active = player("Active")
            source = {
                "name": "Landfall Source",
                "effect": "token_maker",
                "landfall_token_maker": True,
                "token_power": 1,
                "token_toughness": 1,
            }
            land = {"name": "Sunbillow Verge", "effect": "land", "type_line": "Land"}
            active.battlefield = [source, land]
            stack = battle.Stack()

            triggered = battle.trigger_landfall(
                active,
                land,
                turn=2,
                source_event="land_played",
                stack=stack,
                active_player=active,
                all_players=[active],
            )
            pushed = battle.flush_triggers_in_apnap(active, [active], stack)
        finally:
            battle.REPLAY_EVENT_HANDLER = None

        assert triggered is True
        assert pushed == 1
        assert not stack.empty()
        assert any(
            event == "trigger_put_on_stack"
            and data.get("card") == "Landfall Source"
            and data.get("trigger") == "landfall"
            and data.get("trigger_land") == "Sunbillow Verge"
            for event, data in events
        )

    def test_reforge_resolution_draws_seven_when_count_missing():
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [
            {"name": "Big Spell", "cmc": 8, "type_line": "Sorcery"},
            {"name": "Cheap Spell", "cmc": 1, "type_line": "Instant"},
        ]
        opponent.hand = [{"name": f"Opp Card {index}", "cmc": 1, "type_line": "Instant"} for index in range(3)]
        active.library = [_card(f"Draw {index}", cmc=1) for index in range(8)]
        opponent.library = [_card(f"Opponent Draw {index}", cmc=1) for index in range(8)]

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Reforge the Soul", "cmc": 5, "type_line": "Sorcery"},
            turn=3,
            rng=random.Random(8018),
        )

        assert len(active.hand) == 7
        assert len(opponent.hand) == 7

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

    def test_mox_amber_only_counts_mana_with_live_legend():
        active = player("Lorehold")
        active.battlefield = [
            {
                "name": "Mox Amber",
                "effect": "ramp_permanent",
                "mana_produced": 1,
                "produces": "WUBRGC",
                "type_line": "Legendary Artifact",
                "requires_legendary_creature_or_planeswalker_for_mana": True,
            },
            {
                "name": "Command Tower",
                "effect": "land",
                "type_line": "Land",
                "produces": "WUBRGC",
            },
        ]

        active.refresh_mana_sources(turn=1)
        assert active.available_mana() == 1

        active.battlefield.append(
            {
                "name": "Lorehold, the Historian",
                "effect": "creature",
                "type_line": "Legendary Creature - Elder Dragon",
                "power": 5,
                "toughness": 5,
            }
        )
        active.refresh_mana_sources(turn=2)
        assert active.available_mana() == 2

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

    def test_samis_curiosity_creates_lander_token_not_tutor():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Korvold")
        active.life = 20
        card = {"name": "Sami's Curiosity", "cmc": 1, "type_line": "Sorcery"}

        effect = battle.get_card_effect(card)
        battle.apply_effect_immediate(active, [], card, 4, random.Random(93))
        battle.REPLAY_EVENT_HANDLER = None

        assert effect["effect"] == "lander_token_maker"
        assert effect["effect"] != "tutor"
        assert active.life == 22
        assert any(
            permanent.get("name") == "Lander Token"
            and permanent.get("lander_token") is True
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(event == "lander_token_created" for event, _ in events)

    def test_audit_promoted_cards_keep_conservative_semantics():
        miscast = battle.get_card_effect({"name": "Miscast", "type_line": "Instant"})
        steamkin = battle.get_card_effect(
            {"name": "Runaway Steam-Kin", "type_line": "Creature — Elemental"}
        )
        broodscale = battle.get_card_effect(
            {"name": "Basking Broodscale", "type_line": "Creature — Eldrazi Insect"}
        )
        ooze = battle.get_card_effect(
            {"name": "Scavenging Ooze", "type_line": "Creature — Ooze"}
        )

        assert miscast["effect"] == "counter"
        assert miscast["instant"] is True
        assert miscast["target"] == "instant_or_sorcery"
        assert steamkin["effect"] == "creature"
        assert steamkin["effect"] != "ramp_ritual"
        assert steamkin["is_creature_permanent"] is True
        assert broodscale["effect"] == "creature"
        assert broodscale["effect"] != "token_maker"
        assert broodscale["is_creature_permanent"] is True
        assert ooze["effect"] == "creature"
        assert ooze["effect"] != "remove_permanent"
        assert ooze["is_creature_permanent"] is True

    def test_snapback_return_target_creature_stays_creature_removal():
        snapback = battle.get_card_effect(
            {
                "name": "Snapback",
                "cmc": 2,
                "type_line": "Instant",
                "oracle_text": (
                    "You may exile a blue card from your hand rather than pay this "
                    "spell's mana cost. Return target creature to its owner's hand."
                ),
                "functional_tags_json": '["removal"]',
            }
        )
        rule_selection = snapback.get("_rule_runtime_selection") or {}

        assert snapback["effect"] == "remove_creature"
        assert snapback["target"] == "creature"
        assert rule_selection.get("selected_effect") == "remove_creature"

    def test_functional_tag_gate_cards_resolve_from_manual_waivers():
        mardu = battle.get_card_effect(
            {
                "name": "Mardu Devotee",
                "type_line": "Creature — Human Scout",
                "functional_tags_json": '["ramp"]',
            }
        )
        lumberjack = battle.get_card_effect(
            {
                "name": "Orcish Lumberjack",
                "type_line": "Creature — Orc",
                "functional_tags_json": '["ramp"]',
            }
        )
        mardu_fields = battle.replay_rule_fields(mardu)
        lumberjack_fields = battle.replay_rule_fields(lumberjack)

        assert mardu["effect"] == "creature"
        assert mardu["etb_scry_count"] == 2
        assert mardu["mana_filter_once_per_turn"] is True
        assert mardu_fields["rule_source"] == "manual_runtime_waiver"
        assert mardu_fields["rule_review_status"] == "verified"
        assert mardu_fields["rule_logical_key"]

        assert lumberjack["effect"] == "creature"
        assert lumberjack["is_mana_source"] is True
        assert lumberjack["mana_produced"] == 3
        assert lumberjack["requires_sacrifice_forest_for_mana"] is True
        assert lumberjack_fields["rule_source"] == "manual_runtime_waiver"
        assert lumberjack_fields["rule_review_status"] == "verified"
        assert lumberjack_fields["rule_logical_key"]

    def test_basking_broodscale_enters_as_creature_not_immediate_token_maker():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Falco")
        card = {
            "name": "Basking Broodscale",
            "cmc": 2,
            "type_line": "Creature — Eldrazi Insect",
        }

        battle.apply_effect_immediate(active, [], card, 3, random.Random(109))
        battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Basking Broodscale"
            and permanent.get("effect") == "creature"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert not any(
            permanent.get("token_created_by") == "Basking Broodscale"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "creature_to_battlefield"
            and data.get("card") == "Basking Broodscale"
            for event, data in events
        )
        assert not any(
            event == "token_created" and data.get("card") == "Basking Broodscale"
            for event, data in events
        )

    def test_scavenging_ooze_enters_as_creature_not_immediate_removal():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Falco")
        opponent = player("Opponent")
        target = {
            "name": "Value Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
        }
        opponent.battlefield = [target]
        opponent.graveyard = [
            {"name": "Dead Card", "effect": "creature", "type_line": "Creature"}
        ]
        card = {
            "name": "Scavenging Ooze",
            "cmc": 2,
            "type_line": "Creature — Ooze",
        }

        battle.apply_effect_immediate(active, [opponent], card, 4, random.Random(110))
        battle.REPLAY_EVENT_HANDLER = None

        assert any(
            permanent.get("name") == "Scavenging Ooze"
            and permanent.get("effect") == "creature"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target in opponent.battlefield
        assert opponent.graveyard[0]["name"] == "Dead Card"
        assert any(
            event == "creature_to_battlefield"
            and data.get("card") == "Scavenging Ooze"
            for event, data in events
        )
        assert not any(
            event == "removal_resolved" and data.get("card") == "Scavenging Ooze"
            for event, data in events
        )

    def test_mox_diamond_discards_land_when_it_unlocks_commander():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        previous_trace_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Savannah", "effect": "land", "type_line": "Land"}
        active.hand = [mox, land]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        try:
            acted = battle.cast_spells_v8(
                active,
                [opponent],
                [active, opponent],
                turn=1,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(39),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = previous_trace_handler

        assert acted is True
        assert mox not in active.hand
        assert land not in active.hand
        assert any(
            permanent.get("name") == "Mox Diamond"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Savannah" for card in active.graveyard)
        assert any(
            event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            and data.get("cost") == "discard_land"
            and data.get("discarded") == "Savannah"
            for event, data in events
        )
        trace = next(
            trace
            for trace in decisions
            if trace["decision_type"] == "cast_spell"
            and trace["chosen_option"].get("card") == "Mox Diamond"
        )
        assert trace["expected_payoff_reason"] == "same_turn_commander_cast"
        assert "spending_last_land" in trace["risk_flags"]
        assert trace["resource_delta"]["resource_land"] == "Savannah"
        assert trace["resource_delta"]["unlock_card"] == "Cheap Commander"
        assert trace["resource_delta"]["unlock_role"] == "commander"

    def test_mox_diamond_does_not_spend_last_land_without_payoff():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Savannah", "effect": "land", "type_line": "Land"}
        expensive = {
            "name": "Nine Mana Filler",
            "cmc": 9,
            "type_line": "Sorcery",
            "effect": "draw_cards",
        }
        active.hand = [mox, land, expensive]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(40),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert land in active.hand
        assert active.graveyard == []
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            for event, data in events
        )

    def test_mox_diamond_does_not_claim_unaffordable_commander_payoff():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Command Tower", "effect": "land", "type_line": "Land"}
        active.hand = [mox, land]
        active.battlefield = [
            {
                "name": "Wastes",
                "effect": "land",
                "type_line": "Land",
                "mana_produced": 1,
                "color_identity": ["C"],
            }
        ]
        active.command_zone = [
            {
                "name": "Four Mana Commander",
                "cmc": 0,
                "mana_cost": "{2}",
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]
        active.commander_tax = 2
        active.refresh_mana_sources(turn=1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(41),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert land in active.hand
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Mox Diamond"
            for event, data in events
        )

    def test_chrome_mox_imprints_colored_nonartifact_nonland_card():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Chrome Mox", "cmc": 0, "type_line": "Artifact"}
        imprint_card = {
            "name": "Red Filler",
            "cmc": 5,
            "type_line": "Sorcery",
            "effect": "draw_cards",
            "color_identity": ["R"],
        }
        active.hand = [mox, imprint_card]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(42),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert mox not in active.hand
        assert imprint_card not in active.hand
        assert any(card.get("name") == "Red Filler" for card in active.exile)
        assert any(
            permanent.get("name") == "Chrome Mox"
            and permanent.get("imprinted_card") == "Red Filler"
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "imprint_resolved"
            and data.get("card") == "Chrome Mox"
            and data.get("imprinted") == "Red Filler"
            for event, data in events
        )

    def test_chrome_mox_does_not_cast_without_valid_imprint():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        mox = {"name": "Chrome Mox", "cmc": 0, "type_line": "Artifact"}
        artifact = {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact"}
        land = {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"}
        active.hand = [mox, artifact, land]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(43),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert mox in active.hand
        assert not any(event == "imprint_resolved" for event, _ in events)
        assert not any(
            permanent.get("name") == "Chrome Mox"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_everflowing_chalice_pays_multikicker_before_becoming_mana_source():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        chalice = {"name": "Everflowing Chalice", "cmc": 0, "type_line": "Artifact"}
        active.hand = [chalice]
        active.battlefield = ["land", "land"]
        active.refresh_mana_sources(turn=1)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(44),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert chalice not in active.hand
        assert any(
            permanent.get("name") == "Everflowing Chalice"
            and permanent.get("charge_counters") == 1
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "multikicker_paid"
            and data.get("card") == "Everflowing Chalice"
            and data.get("kicker_count") == 1
            for event, data in events
        )
        assert any(
            event == "cast_announced"
            and data.get("card") == "Everflowing Chalice"
            and data.get("additional_costs") == ["{2}"]
            for event, data in events
        )

    def test_everflowing_chalice_does_not_cast_as_zero_mana_ramp():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        chalice = {"name": "Everflowing Chalice", "cmc": 0, "type_line": "Artifact"}
        active.hand = [chalice]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(45),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert chalice in active.hand
        assert not any(event == "multikicker_paid" for event, _ in events)
        assert not any(
            permanent.get("name") == "Everflowing Chalice"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )

    def test_lightning_greaves_grants_haste_and_shroud_without_indestructible():
        active = player("Active")
        target = {
            "name": "Target Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
            "summoning_sick": True,
        }
        active.battlefield = [target]

        battle.apply_effect_immediate(
            active,
            [],
            {"name": "Lightning Greaves", "cmc": 2, "type_line": "Artifact — Equipment"},
            3,
            random.Random(46),
        )

        assert any(
            permanent.get("name") == "Lightning Greaves"
            and permanent.get("effect") == "equipment_haste_shroud"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert target.get("haste") is True
        assert target.get("shroud") is True
        assert target.get("summoning_sick") is False
        assert target.get("indestructible") is not True

    def test_birgi_adds_red_mana_when_controller_casts_spell():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        birgi_card = {
            "name": "Birgi, God of Storytelling",
            "cmc": 3,
            "type_line": "Legendary Creature — God",
        }
        birgi = battle.prepare_entering_permanent(
            battle.enrich_card({**birgi_card, **battle.get_card_effect(birgi_card)})
        )
        active.battlefield = [birgi]
        spell = {
            "name": "Generic Creature Spell",
            "cmc": 2,
            "type_line": "Creature — Soldier",
            "effect": "creature",
        }

        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            spell,
            turn=3,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.mana_pool.red == 1
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Birgi, God of Storytelling"
            and data.get("trigger") == "spell_cast"
            and data.get("effect") == "add_mana"
            and data.get("mana_color") == "red"
            for event, data in events
        )

    def test_electroduplicate_creates_hasty_copy_and_sacrifices_at_end_step():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        target = {
            "name": "Value Creature",
            "effect": "creature",
            "type_line": "Creature",
            "power": 4,
            "toughness": 4,
        }
        active.battlefield = [target]
        card = {"name": "Electroduplicate", "cmc": 3, "type_line": "Sorcery"}

        battle.apply_effect_immediate(active, [], card, 4, random.Random(47))

        tokens = [
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("copy_of") == "Value Creature"
        ]
        assert len(tokens) == 1
        token = tokens[0]
        assert token.get("haste") is True
        assert token.get("sacrifice_at_end_step") is True

        battle.process_end_step_token_sacrifices(active, 4)
        battle.REPLAY_EVENT_HANDLER = None

        assert token not in active.battlefield
        assert any(card.get("name") == token.get("name") for card in active.graveyard)
        assert any(
            event == "copy_creature_token_created"
            and data.get("card") == "Electroduplicate"
            and data.get("target") == "Value Creature"
            for event, data in events
        )
        assert any(event == "end_step_token_sacrificed" for event, _ in events)

    def test_valakut_awakening_filters_hand_and_draws_plus_one():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        high_a = {"name": "Eight Drop A", "cmc": 8, "type_line": "Sorcery", "effect": "draw_cards"}
        high_b = {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery", "effect": "draw_cards"}
        keep = {"name": "Cheap Removal", "cmc": 1, "type_line": "Instant", "effect": "remove_creature"}
        card = {"name": "Valakut Awakening", "cmc": 3, "type_line": "Instant"}
        active.hand = [card, high_a, high_b, keep]
        active.library = [
            {"name": "Draw One", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Two", "cmc": 2, "type_line": "Sorcery"},
            {"name": "Draw Three", "cmc": 2, "type_line": "Sorcery"},
        ]

        battle.apply_effect_immediate(active, [], card, 4, random.Random(48))
        battle.REPLAY_EVENT_HANDLER = None

        hand_names = [entry.get("name") for entry in active.hand if isinstance(entry, dict)]
        assert "Cheap Removal" in hand_names
        assert "Draw One" in hand_names
        assert "Draw Two" in hand_names
        assert "Draw Three" in hand_names
        assert "Eight Drop A" not in hand_names
        assert "Nine Drop B" not in hand_names
        assert any(
            event == "hand_filter_resolved"
            and data.get("card") == "Valakut Awakening"
            and set(data.get("bottomed", [])) == {"Eight Drop A", "Nine Drop B"}
            and data.get("draw_count") == 3
            for event, data in events
        )

    def test_mulligan_trace_scores_keep_vs_mulligan_for_heavy_dead_hand():
        decisions = []
        previous_trace_handler = battle.DECISION_TRACE_HANDLER
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            battle.DECISION_TRACE_HANDLER = lambda payload: decisions.append(payload)
            active = player("Lorehold")
            active.hand = [
                {"name": "Plains", "cmc": 0, "type_line": "Land"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land"},
                {"name": "Sacred Foundry", "cmc": 0, "type_line": "Land"},
                {"name": "Eight Drop A", "cmc": 8, "type_line": "Sorcery"},
                {"name": "Eight Drop B", "cmc": 8, "type_line": "Sorcery"},
                {"name": "Nine Drop A", "cmc": 9, "type_line": "Sorcery"},
                {"name": "Nine Drop B", "cmc": 9, "type_line": "Sorcery"},
            ]

            evaluation = battle.mulligan_evaluation(active.hand)
            assert evaluation["keep"] is False
            assert evaluation["reason"] == "expensive_cluster_without_setup"
            battle._emit_mulligan_decision_trace(
                active,
                evaluation,
                mulligan_count=0,
                chosen_action="mulligan",
                bottomed_cards=[],
            )
        finally:
            battle.DECISION_TRACE_HANDLER = previous_trace_handler

        assert len(decisions) == 1
        trace = decisions[0]
        assert trace["decision_type"] == "mulligan_decision"
        assert trace["chosen_option"]["action"] == "mulligan"
        assert trace["chosen_option_score"] > trace["best_rejected_option_score"]
        assert trace["score_gap_vs_best_rejected"] > 0
        assert any(item["option"] == "mulligan" for item in trace["available_option_scores"])
        assert any(item["option"] == "keep" for item in trace["rejected_option_scores"])
        assert "expensive_dead_hand" in trace["risk_flags"]

    def test_special_lands_are_modelled_as_lands_not_spell_heuristics():
        ancient_tomb_effect = battle.get_card_effect({"name": "Ancient Tomb", "type_line": "Land"})
        assert ancient_tomb_effect["effect"] == "land"
        assert ancient_tomb_effect["mana_produced"] == 1
        assert ancient_tomb_effect["ancient_tomb_bonus_mana"] == 1
        assert ancient_tomb_effect["ancient_tomb_bonus_life_cost"] == 2

        active = player("Active", [{"name": "Too Expensive", "cmc": 9, "type_line": "Sorcery"}])
        active.hand = [{"name": "Ancient Tomb", "cmc": 0, "type_line": "Land"}]
        opponent = player("Opponent")
        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(49),
            stack=battle.Stack(),
        )

        assert any(
            permanent.get("name") == "Ancient Tomb"
            and permanent.get("effect") == "land"
            and permanent.get("mana_produced") == 1
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert active.mana_pool.colorless >= 1

        expected_land_models = {
            "Ancient Den": ("W", 1),
            "Gemstone Caverns": ("WUBRGC", 1),
            "Great Furnace": ("R", 1),
            "Hall of Heliod's Generosity": ("C", 1),
            "Inventors' Fair": ("C", 1),
            "Sunbaked Canyon": ("WR", 1),
            "Urza's Saga": ("C", 1),
            "War Room": ("C", 1),
            "Valakut Awakening // Valakut Stoneforge": (None, None),
        }
        for name, expected in expected_land_models.items():
            effect = battle.get_card_effect(
                {"name": name, "type_line": "Instant // Land"}
                if name == "Valakut Awakening // Valakut Stoneforge"
                else {"name": name, "type_line": "Land"}
            )
            if name == "Valakut Awakening // Valakut Stoneforge":
                assert effect["effect"] == "hand_filter"
                assert effect["mdfc_land_face"]["effect"] == "land"
                assert effect["mdfc_land_face"]["produces"] == "R"
                continue
            produces, mana_produced = expected
            assert effect["effect"] == "land"
            assert effect["produces"] == produces
            assert effect["mana_produced"] == mana_produced

    def test_war_room_activates_when_hand_is_low_and_life_is_safe():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
        }
        active.commander = commander
        active.command_zone = [commander]
        active.life = 12
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "War Room", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(90))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.life == 10
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(card.get("name") == "War Room" for card in active.battlefield)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "War Room"
            and data.get("activation_kind") == "draw_card"
            and data.get("life_paid") == 2
            for event, data in events
        )

    def test_war_room_skips_when_life_is_too_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
        }
        active.commander = commander
        active.command_zone = [commander]
        active.life = 6
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "War Room", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(91))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 6
        assert not any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "War Room"
            and data.get("strategic_guardrail_reason") == "life_too_low_for_war_room_activation"
            for event, data in events
        )

    def test_sunbaked_canyon_turns_expendable_land_into_card():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(92))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Sunbaked Canyon" for card in active.graveyard)
        assert not any(card.get("name") == "Sunbaked Canyon" for card in active.battlefield)
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("activation_kind") == "sacrifice_draw"
            for event, data in events
        )

    def test_sunbaked_canyon_requires_extra_mana_beyond_its_own_tap_proxy():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(96))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("strategic_guardrail_reason") == "too_few_lands_to_sacrifice_draw_land"
            or data.get("strategic_guardrail_reason") == "insufficient_mana_for_sacrifice_draw_land"
            for event, data in events
        )

    def test_sunbaked_canyon_skips_when_it_would_cut_too_deep_on_lands():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {"name": "Sunbaked Canyon", "effect": "land", "type_line": "Land", "produces": "WR", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(93))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert not any(card.get("name") == "Sunbaked Canyon" for card in active.graveyard)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Sunbaked Canyon"
            and data.get("strategic_guardrail_reason") == "too_few_lands_to_sacrifice_draw_land"
            for event, data in events
        )

    def test_inventors_fair_gains_life_on_upkeep_with_three_artifacts():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}])
        active.life = 30
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Arcane Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WUBRGC"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
        ]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(94),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert active.life == 31
        assert any(
            event == "utility_land_triggered"
            and data.get("card") == "Inventors' Fair"
            and data.get("trigger_kind") == "upkeep_life_gain"
            and data.get("artifact_count") >= 3
            for event, data in events
        )

    def test_inventors_fair_tutors_artifact_when_threshold_and_mana_exist():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [
            {"name": "Aetherflux Reservoir", "cmc": 4, "type_line": "Artifact", "effect": "finisher"},
            {"name": "Drawn Card", "cmc": 2, "type_line": "Instant"},
        ]
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Arcane Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WUBRGC"},
            {"name": "Ancient Den", "effect": "land", "type_line": "Artifact Land", "produces": "W", "mana_produced": 1},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(95))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Inventors' Fair" for card in active.graveyard)
        assert any(card.get("name") == "Aetherflux Reservoir" for card in active.hand)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Inventors' Fair"
            and data.get("activation_kind") == "artifact_tutor"
            and data.get("found") == "Aetherflux Reservoir"
            for event, data in events
        )

    def test_inventors_fair_skips_without_artifact_threshold():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [{"name": "Aetherflux Reservoir", "cmc": 4, "type_line": "Artifact", "effect": "finisher"}]
        active.battlefield = [
            {
                "name": "Inventors' Fair",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Command Tower", "effect": "land", "type_line": "Land", "produces": "WUBRGC", "mana_produced": 1},
            {"name": "Boros Signet", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 1, "produces": "WR"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(97))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert not any(card.get("name") == "Inventors' Fair" for card in active.graveyard)
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Inventors' Fair"
            and data.get("strategic_guardrail_reason") == "artifact_threshold_not_met_for_inventors_fair"
            for event, data in events
        )

    def test_hall_of_heliods_generosity_recovers_best_enchantment_to_top():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.graveyard = [
            {"name": "Smothering Tithe", "cmc": 4, "type_line": "Enchantment", "effect": "ramp_engine"},
            {"name": "Fiery Emancipation", "cmc": 6, "type_line": "Enchantment", "effect": "passive"},
        ]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {
                "name": "Hall of Heliod's Generosity",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(98))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.library[0]["name"] == "Smothering Tithe"
        assert not any(card.get("name") == "Smothering Tithe" for card in active.graveyard)
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Hall of Heliod's Generosity"
            and data.get("activation_kind") == "graveyard_enchantment_to_top"
            and data.get("found") == "Smothering Tithe"
            for event, data in events
        )

    def test_hall_of_heliods_generosity_skips_without_white_mana():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.graveyard = [
            {"name": "Smothering Tithe", "cmc": 4, "type_line": "Enchantment", "effect": "ramp_engine"},
        ]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        active.battlefield = [
            {
                "name": "Hall of Heliod's Generosity",
                "effect": "land",
                "type_line": "Legendary Land",
                "produces": "C",
                "mana_produced": 1,
            },
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 2},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(99))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.library[0]["name"] == "Drawn Card"
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Hall of Heliod's Generosity"
            and data.get("strategic_guardrail_reason") == "missing_white_mana_for_hall_recursion"
            for event, data in events
        )

    def test_ancient_tomb_pays_life_only_when_it_unlocks_contextual_play():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        commander = {
            "name": "Lorehold, the Historian",
            "cmc": 4,
            "type_line": "Legendary Creature — Elder Dragon",
            "color_identity": ["W", "R"],
            "is_commander": True,
        }
        active.command_zone = [commander]
        active.life = 40
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=3)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert active.life == 38
        assert active.available_mana() == 4
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Ancient Tomb"
            and data.get("activation_kind") == "contextual_fast_mana"
            and data.get("unlock_target") == "Lorehold, the Historian"
            for event, data in events
        )

    def test_ancient_tomb_skips_when_no_relevant_unlock_exists():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.life = 40
        active.hand = [{"name": "Eight Drop", "cmc": 8, "type_line": "Sorcery", "effect": "draw_cards"}]
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=2)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 40
        assert active.available_mana() == 2
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Ancient Tomb"
            and data.get("strategic_guardrail_reason") == "no_contextual_unlock_for_ancient_tomb"
            for event, data in events
        )

    def test_ancient_tomb_skips_when_life_is_too_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.life = 8
        active.hand = [{"name": "Arcane Signet", "cmc": 2, "type_line": "Artifact"}]
        active.battlefield = [
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land", "produces": "C", "mana_produced": 1},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
        ]
        active.refresh_mana_sources(turn=2)
        opponent = player("Opponent")

        activations = battle.activate_precombat_utility_mana_lands(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert active.life == 8
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Ancient Tomb"
            and data.get("strategic_guardrail_reason") == "life_too_low_for_ancient_tomb_acceleration"
            for event, data in events
        )

    def test_chromatic_star_precombat_unlocks_off_color_spell():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.hand = [
            {
                "name": "Lightning Bolt",
                "cmc": 1,
                "mana_cost": "{R}",
                "type_line": "Instant",
                "oracle_text": "Lightning Bolt deals 3 damage to any target.",
            }
        ]
        active.battlefield = [
            {
                "name": "Chromatic Star",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "cantrip_mana_filter_artifact",
                "activation_cost_generic": 1,
                "activation_add_colors": ["white", "blue", "black", "red", "green"],
                "draw_on_self_sacrifice": 1,
                "battle_model_scope": "sacrifice_mana_filter_cantrip_v2",
            },
            {"name": "Wastes", "effect": "land", "type_line": "Basic Land", "produces": "C", "mana_produced": 1},
        ]
        active.library = [_card("Drawn Card", cmc=2, effect="draw_cards")]
        active.refresh_mana_sources(turn=2)

        activations = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=2,
            rng=random.Random(104),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert not any(
            permanent.get("name") == "Chromatic Star"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(card.get("name") == "Chromatic Star" for card in active.graveyard)
        assert active.mana_pool.red == 1
        assert any(card.get("name") == "Drawn Card" for card in active.hand)
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Chromatic Star"
            and data.get("activation_kind") == "filter_draw_unlock"
            and data.get("chosen_color") == "red"
            and data.get("unlock_target") == "Lightning Bolt"
            for event, data in events
        )

    def test_chromatic_star_postcombat_cash_in_when_hand_is_low():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        active.hand = []
        active.library = [_card("Refill Card", cmc=2, effect="draw_cards")]
        active.battlefield = [
            {
                "name": "Chromatic Star",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "cantrip_mana_filter_artifact",
                "activation_cost_generic": 1,
                "activation_add_colors": ["white", "blue", "black", "red", "green"],
                "draw_on_self_sacrifice": 1,
                "battle_model_scope": "sacrifice_mana_filter_cantrip_v2",
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=3)

        activations = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(105),
            phase="postcombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        assert any(card.get("name") == "Refill Card" for card in active.hand)
        assert any(card.get("name") == "Chromatic Star" for card in active.graveyard)
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Chromatic Star"
            and data.get("activation_kind") == "cash_in_draw"
            and data.get("cards_drawn") == 1
            for event, data in events
        )

    def test_urzas_saga_enters_with_initial_chapter_state():
        active = player("Active")
        active.hand = [{"name": "Urza's Saga", "cmc": 0, "type_line": "Enchantment Land — Urza's Saga"}]
        active.library = [{"name": "Drawn Card", "cmc": 2, "type_line": "Instant"}]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(101),
            stack=battle.Stack(),
        )

        saga = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("name") == "Urza's Saga"
        )
        assert saga["effect"] == "land"
        assert saga["lore_counters"] == 1
        assert saga["current_chapter"] == 1
        assert saga["final_chapter"] == 3
        assert saga["saga_last_lore_turn"] == 1

    def test_urzas_saga_creates_construct_on_chapter_two():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.battlefield = [
            {
                "name": "Urza's Saga",
                "effect": "land",
                "type_line": "Enchantment Land — Urza's Saga",
                "produces": "C",
                "mana_produced": 1,
                "lore_counters": 2,
                "current_chapter": 2,
                "final_chapter": 3,
            },
            {"name": "Sol Ring", "effect": "ramp_permanent", "type_line": "Artifact", "mana_produced": 2, "produces": "C"},
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_utility_lands(active, 4, random.Random(102))
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 1
        construct = next(
            permanent
            for permanent in active.battlefield
            if isinstance(permanent, dict) and permanent.get("urzas_saga_construct")
        )
        assert construct["name"] == "Construct Token"
        assert construct["type_line"] == "Artifact Creature Token — Construct"
        assert construct["power"] == 2
        assert construct["toughness"] == 2
        assert any(
            event == "utility_land_activated"
            and data.get("card") == "Urza's Saga"
            and data.get("activation_kind") == "construct_token"
            and data.get("artifact_count_after") == 2
            for event, data in events
        )

    def test_urzas_saga_tutors_safe_artifact_then_sacrifices():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        active.hand = [{"name": "Keep Spell", "cmc": 2, "type_line": "Sorcery"}]
        active.library = [
            {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent"},
            {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact", "oracle_text": "If Mox Diamond would enter the battlefield, discard a land card instead. If you do, put Mox Diamond onto the battlefield. If you don't, put it into its owner's graveyard."},
            {"name": "Drawn Card", "cmc": 2, "type_line": "Instant"},
        ]
        active.battlefield = [
            {
                "name": "Urza's Saga",
                "effect": "land",
                "type_line": "Enchantment Land — Urza's Saga",
                "produces": "C",
                "mana_produced": 1,
                "lore_counters": 2,
                "current_chapter": 2,
                "final_chapter": 3,
                "saga_last_lore_turn": 2,
            },
            {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
        ]
        opponent = player("Opponent")

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(103),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert any(card.get("name") == "Sol Ring" for card in active.battlefield if isinstance(card, dict))
        assert not any(card.get("name") == "Mox Diamond" for card in active.battlefield if isinstance(card, dict))
        assert any(card.get("name") == "Urza's Saga" for card in active.graveyard if isinstance(card, dict))
        assert any(
            event == "saga_chapter_progressed"
            and data.get("card") == "Urza's Saga"
            and data.get("chapter") == 3
            for event, data in events
        )
        assert any(
            event == "saga_chapter_resolved"
            and data.get("card") == "Urza's Saga"
            and data.get("found") == "Sol Ring"
            for event, data in events
        )
        assert any(
            event == "saga_sacrificed_by_sba"
            and data.get("card") == "Urza's Saga"
            and data.get("final_chapter") == 3
            for event, data in events
        )

    def test_angels_grace_prevents_lethal_damage_and_life_zero_loss_this_turn():
        active = player("Protected")
        active.life = 3
        grace = {"name": "Angel's Grace", "cmc": 1, "type_line": "Instant"}
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.apply_effect_immediate(active, [], grace, 2, random.Random(104))
                dealt = battle.deal_damage(active, 10)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        assert dealt is True
        assert active.life == 1
        battle.check_sbas([active])
        assert active.eliminated is False
        assert active.is_alive() is True

    def test_angels_grace_blocks_opponent_approach_win_this_turn():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        protected = player("Protected")
        protected.life = 5
        opponent = player("Approach Player")
        opponent.approach_count = 1
        grace = {"name": "Angel's Grace", "cmc": 1, "type_line": "Instant"}
        approach = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        }
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with sqlite3.connect(db_path) as conn:
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Angel's Grace",
                    {
                        "effect": "cannot_lose_turn",
                        "instant": True,
                        "life_floor_on_damage": 1,
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.apply_effect_immediate(protected, [opponent], grace, 2, random.Random(105))
                battle.apply_effect_immediate(opponent, [protected], approach, 2, random.Random(105))
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.REPLAY_EVENT_HANDLER = None

        assert opponent.has_won() is False
        assert any(event == "game_win_prevented" for event, _ in events)

    def test_senseis_top_sets_up_lorehold_approach_second_cast():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            top_card = {
                "name": "Sensei's Divining Top",
                "cmc": 1,
                "type_line": "Artifact",
            }
            top_permanent = {
                **top_card,
                **battle.get_card_effect(top_card),
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                top_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                }
            ]
            lorehold.library = [
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(123),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 1
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert [card.get("name") for card in lorehold.graveyard] == [
            "Nine Mana Spell",
            "Approach of the Second Sun",
        ]
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Sensei's Divining Top"
            and data.get("top_before") == "Small Creature"
            and data.get("top_after") == "Approach of the Second Sun"
            for event, data in events
        )
        assert any(
            event == "lorehold_upkeep_rummage"
            and data.get("drawn") == "Approach of the Second Sun"
            and data.get("discarded") == "Nine Mana Spell"
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "lorehold_opponent_upkeep_rummage"
            and data.get("rule_review_status") == "verified"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("actual_outcome") == "topdeck_reordered_for_first_draw"
            and "topdeck_reorder" in decision.get("risk_flags", [])
            for decision in decisions
        )
        assert any(
            decision.get("decision_type") == "lorehold_upkeep_rummage"
            and decision.get("chosen_option", {}).get("card") == "Nine Mana Spell"
            and decision.get("actual_outcome") == "discard_then_draw"
            for decision in decisions
        )

    def test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            rack_card = {
                "name": "Scroll Rack",
                "cmc": 2,
                "type_line": "Artifact",
            }
            rack_permanent = {
                **rack_card,
                **battle.get_card_effect(rack_card),
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                rack_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                },
            ]
            lorehold.library = [
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(124),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 1
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Scroll Rack"
            and data.get("activation_kind") == "scroll_rack_single_exchange_for_lorehold"
            and data.get("top_before") == "Small Creature"
            and data.get("top_after") == "Approach of the Second Sun"
            and data.get("phase") == "opponent_upkeep"
            for event, data in events
        )
        assert any(
            event == "lorehold_upkeep_rummage"
            and data.get("drawn") == "Approach of the Second Sun"
            and data.get("discarded") == "Nine Mana Spell"
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "lorehold_opponent_upkeep_rummage"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("chosen_option", {}).get("action") == "activate_scroll_rack_exchange"
            and decision.get("actual_outcome") == "hand_spell_moved_to_top_for_next_draw"
            for decision in decisions
        )

    def test_brainstone_first_draw_approach_wins_before_rummage_resolution():
        events = []
        decisions = []
        previous_event_handler = battle.REPLAY_EVENT_HANDLER
        previous_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            lorehold = player("Lorehold")
            lorehold.is_human = True
            lorehold.approach_count = 1
            brainstone_card = {
                "name": "Brainstone",
                "cmc": 1,
                "type_line": "Artifact",
            }
            brainstone_permanent = {
                **brainstone_card,
                **battle.get_card_effect(brainstone_card),
            }
            lorehold.battlefield = [
                {
                    "name": "Lorehold, the Historian",
                    "effect": "creature",
                    "type_line": "Legendary Creature",
                    "haste": True,
                },
                brainstone_permanent,
                {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                {"name": "Sacred Foundry", "effect": "land", "type_line": "Land"},
                {"name": "Clifftop Retreat", "effect": "land", "type_line": "Land"},
            ]
            lorehold.hand = [
                {
                    "name": "Nine Mana Spell",
                    "cmc": 9,
                    "type_line": "Sorcery",
                    "effect": "draw_cards",
                },
                {"name": "Small Creature", "cmc": 2, "type_line": "Creature", "effect": "creature"},
            ]
            lorehold.library = [
                {
                    "name": "Approach of the Second Sun",
                    "cmc": 7,
                    "type_line": "Sorcery",
                },
                {"name": "Filler Draw A", "cmc": 3, "type_line": "Creature", "effect": "creature"},
                {"name": "Filler Draw B", "cmc": 4, "type_line": "Sorcery", "effect": "draw_cards"},
                {"name": "Mountain", "cmc": 0, "type_line": "Land", "effect": "land"},
            ]
            opponent = player("Opponent")
            opponent.library = [_card("Opponent Draw", cmc=1)]
            lorehold.refresh_mana_sources(turn=6)

            triggered = battle.process_lorehold_opponent_upkeep_rummage(
                opponent,
                [lorehold, opponent],
                6,
                random.Random(125),
                battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_event_handler
            battle.DECISION_TRACE_HANDLER = previous_decision_handler

        assert triggered == 0
        assert lorehold.has_won() is True
        assert lorehold.win_reason == "approach"
        assert any(card.get("name") == "Brainstone" for card in lorehold.graveyard)
        assert any(card.get("name") == "Approach of the Second Sun" for card in lorehold.graveyard)
        assert any(
            event == "topdeck_manipulation_activated"
            and data.get("card") == "Brainstone"
            and data.get("activation_kind") == "brainstone_draw_three_put_two_back_for_miracle"
            and data.get("first_draw") == "Approach of the Second Sun"
            and len(data.get("putback") or []) == 2
            for event, data in events
        )
        assert any(
            event == "miracle_cast"
            and data.get("card") == "Approach of the Second Sun"
            and data.get("source") == "brainstone_first_draw"
            for event, data in events
        )
        assert any(
            event == "game_won"
            and data.get("player") == "Lorehold"
            and data.get("reason") == "approach"
            for event, data in events
        )
        assert not any(event == "lorehold_upkeep_rummage" for event, _ in events)
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and decision.get("chosen_option", {}).get("action") == "activate_brainstone_for_first_draw_miracle"
            and decision.get("actual_outcome") == "brainstone_first_draw_miracle_window"
            and "sacrifice_artifact" in decision.get("risk_flags", [])
            for decision in decisions
        )

    def test_natural_order_sacrifices_green_creature_for_green_battlefield_tutor():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        natural_order = {
            "name": "Natural Order",
            "cmc": 4,
            "type_line": "Sorcery",
        }
        active.hand = [natural_order]
        active.battlefield = [
            {
                "name": "Llanowar Elves",
                "effect": "creature",
                "type_line": "Creature — Elf Druid",
                "power": 1,
                "toughness": 1,
                "color_identity": ["G"],
            },
            {
                "name": "Esper Sentinel",
                "effect": "creature",
                "type_line": "Artifact Creature — Human Soldier",
                "power": 1,
                "toughness": 1,
                "color_identity": ["W"],
            },
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
        ]
        active.library = [
            {
                "name": "Craterhoof Behemoth",
                "cmc": 8,
                "type_line": "Creature — Beast",
                "power": 5,
                "toughness": 5,
                "color_identity": ["G"],
            }
        ]
        active.refresh_mana_sources(turn=4)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(106),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is True
        assert any(card.get("name") == "Llanowar Elves" for card in active.graveyard)
        assert any(
            permanent.get("name") == "Craterhoof Behemoth"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            and data.get("cost") == "sacrifice_green_creature"
            and data.get("sacrificed") == "Llanowar Elves"
            for event, data in events
        )
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            and data.get("sacrificed") == "Esper Sentinel"
            for event, data in events
        )

    def test_natural_order_does_not_cast_without_green_creature_to_sacrifice():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        natural_order = {
            "name": "Natural Order",
            "cmc": 4,
            "type_line": "Sorcery",
        }
        active.hand = [natural_order]
        active.battlefield = [
            {
                "name": "Esper Sentinel",
                "effect": "creature",
                "type_line": "Artifact Creature — Human Soldier",
                "power": 1,
                "toughness": 1,
                "color_identity": ["W"],
            },
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
            {"name": "Forest", "effect": "land", "type_line": "Land", "produces": "G"},
        ]
        active.library = [
            {
                "name": "Craterhoof Behemoth",
                "cmc": 8,
                "type_line": "Creature — Beast",
                "power": 5,
                "toughness": 5,
                "color_identity": ["G"],
            }
        ]
        active.refresh_mana_sources(turn=4)

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(107),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert acted is False
        assert natural_order in active.hand
        assert any(
            permanent.get("name") == "Esper Sentinel"
            for permanent in active.battlefield
            if isinstance(permanent, dict)
        )
        assert not any(
            event == "additional_cost_paid"
            and data.get("card") == "Natural Order"
            for event, data in events
        )

    def test_dismember_applies_stat_modifier_and_kills_indestructible_zero_toughness():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        target = {
            "name": "Indestructible Threat",
            "effect": "creature",
            "type_line": "Creature",
            "power": 5,
            "toughness": 5,
            "indestructible": True,
        }
        opponent.battlefield = [target]
        dismember = {
            "name": "Dismember",
            "cmc": 3,
            "type_line": "Instant",
            "mana_cost": "{1}{B/P}{B/P}",
            "effect": "remove_creature",
            "target": "creature",
            "instant": True,
            "power_boost": -5,
            "toughness_boost": -5,
            "uses_stat_modifier_removal": True,
            "_rule_source": "curated",
            "_rule_review_status": "verified",
        }

        battle.apply_effect_immediate(
            active,
            [opponent],
            dismember,
            turn=3,
            rng=random.Random(108),
        )
        battle.check_sbas_until_stable([active, opponent])
        battle.REPLAY_EVENT_HANDLER = None

        assert target not in opponent.battlefield
        assert target in opponent.graveyard
        assert any(
            event == "removal_resolved"
            and data.get("card") == "Dismember"
            and data.get("result") == "stat_modifier_until_eot_applied"
            and data.get("toughness_delta") == -5
            for event, data in events
        )

    def test_ashnods_altar_sacrifices_token_only_for_contextual_mana_unlock():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        token = battle.create_creature_token(
            active,
            name="Servo Token",
            power=1,
            toughness=1,
        )
        altar = {
            "name": "Ashnod's Altar",
            "cmc": 3,
            "type_line": "Artifact",
            "effect": "sacrifice_mana_outlet",
            "activated_mana_ability": True,
            "activation_cost": "sacrifice_creature",
            "mana_produced": 2,
            "produces": "C",
            "_rule_source": "focused_test",
            "_rule_review_status": "verified",
        }
        active.battlefield.extend(
            [
                altar,
                {"name": "Wastes", "effect": "land", "type_line": "Basic Land", "produces": "C", "mana_produced": 1},
            ]
        )
        active.hand = [
            {
                "name": "Approach of the Second Sun",
                "cmc": 7,
                "mana_cost": "{3}",
                "type_line": "Sorcery",
            }
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_sacrifice_mana_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None
        battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert active.available_mana() == 3
        assert token not in active.battlefield
        assert altar in active.battlefield
        assert any(
            event == "utility_artifact_activated"
            and data.get("card") == "Ashnod's Altar"
            and data.get("activation_kind") == "sacrifice_creature_for_mana_unlock"
            and data.get("sacrificed") == "Servo Token"
            and data.get("unlock_target") == "Approach of the Second Sun"
            and data.get("mana_added") == 2
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "utility_artifact_activation"
            and decision.get("chosen_option", {}).get("action") == "activate_sacrifice_mana_artifact"
            and decision.get("chosen_option", {}).get("card") == "Approach of the Second Sun"
            and "sacrifice_creature" in decision.get("risk_flags", [])
            for decision in decisions
        )

    def test_goblin_bombardment_sacrifices_expendable_token_for_damage():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        active = player("Active")
        opponent = player("Opponent")
        opponent.life = 3
        token = battle.create_creature_token(
            active,
            name="Goblin Token",
            power=1,
            toughness=1,
        )
        outlet = {
            "name": "Goblin Bombardment",
            "cmc": 2,
            "type_line": "Enchantment",
            "effect": "sacrifice_damage_outlet",
            "activated_sacrifice_creature_damage": True,
            "damage": 1,
            "_rule_source": "focused_test",
            "_rule_review_status": "needs_review",
        }
        active.battlefield.append(outlet)

        activations = battle.activate_sacrifice_damage_outlets(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(109),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None
        battle.DECISION_TRACE_HANDLER = None

        assert activations == 1
        assert opponent.life == 2
        assert token not in active.battlefield
        assert token not in active.graveyard
        assert outlet in active.battlefield
        assert any(
            event == "activated_ability"
            and data.get("card") == "Goblin Bombardment"
            and data.get("activation_kind") == "sacrifice_creature_damage"
            and data.get("sacrificed") == "Goblin Token"
            and data.get("target") == "Opponent"
            and data.get("damage_dealt") == 1
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "activated_sacrifice_damage"
            and decision.get("chosen_option", {}).get("card") == "Goblin Token"
            for decision in decisions
        )

    def test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast():
        events = []
        fixture_name = "Review-Only Bombardment Fixture"
        previous_handler = battle.REPLAY_EVENT_HANDLER
        previous_entry = battle.KNOWN_CARDS.get(fixture_name)
        had_fallback = fixture_name in battle.CANONICAL_FALLBACK_KNOWN_CARDS
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.KNOWN_CARDS[fixture_name] = {
            "effect": "remove_creature",
            "cmc": 2,
            "battle_rule_source": "generated",
            "battle_rule_review_status": "needs_review",
            "battle_rule_execution_status": "review_only",
            "battle_rule_confidence": 0.55,
            "battle_rule_logical_key": "battle_rule_v1:test_review_only_bombardment",
            "battle_rule_version": 1,
        }
        battle.CANONICAL_FALLBACK_KNOWN_CARDS.add(fixture_name)
        try:
            active = player("Active")
            opponent = player("Lorehold")
            lorehold = {
                "name": "Lorehold, the Historian",
                "cmc": 5,
                "type_line": "Legendary Creature — Elder Dragon",
                "effect": "creature",
                "power": 5,
                "toughness": 5,
            }
            opponent.battlefield = [lorehold]
            card = {
                "name": fixture_name,
                "cmc": 2,
                "type_line": "Enchantment",
                "oracle_text": "Sacrifice a creature: this enchantment deals 1 damage to any target.",
            }

            effect = battle.get_card_effect(card)
            assert effect["effect"] == "passive"
            assert effect["suppressed_effect"] == "remove_creature"
            assert effect["_rule_review_status"] == "review_only"
            assert effect["_rule_execution_status"] == "review_only"

            battle.apply_effect_immediate(
                active,
                [opponent],
                card,
                turn=9,
                rng=random.Random(112),
                effect_data_override=effect,
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = previous_handler
            if previous_entry is None:
                battle.KNOWN_CARDS.pop(fixture_name, None)
            else:
                battle.KNOWN_CARDS[fixture_name] = previous_entry
            if not had_fallback:
                battle.CANONICAL_FALLBACK_KNOWN_CARDS.discard(fixture_name)

        assert lorehold in opponent.battlefield
        assert any(card.get("name") == fixture_name for card in active.battlefield)
        assert not any(event == "removal_resolved" for event, _ in events)
        assert any(
            event == "spell_resolved"
            and data.get("card") == fixture_name
            and data.get("effect") == "passive"
            and data.get("rule_review_status") == "review_only"
            for event, data in events
        )

    def test_goblin_bombardment_skips_without_expendable_creature():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active")
        opponent = player("Opponent")
        commander = {
            "name": "Lorehold, the Historian",
            "cmc": 5,
            "type_line": "Legendary Creature — Elder Dragon",
            "effect": "creature",
            "power": 5,
            "toughness": 5,
            "is_commander": True,
        }
        outlet = {
            "name": "Goblin Bombardment",
            "cmc": 2,
            "type_line": "Enchantment",
            "effect": "sacrifice_damage_outlet",
            "activated_sacrifice_creature_damage": True,
            "damage": 1,
        }
        active.battlefield = [outlet, commander]

        activations = battle.activate_sacrifice_damage_outlets(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(110),
            phase="precombat_main",
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert activations == 0
        assert commander in active.battlefield
        assert any(
            event == "activated_ability_skipped"
            and data.get("card") == "Goblin Bombardment"
            and data.get("strategic_guardrail_reason") == "no_expendable_creature_to_sacrifice"
            for event, data in events
        )

    def test_iron_man_attack_trigger_sacrifices_treasure_for_artifact_tutor():
        events = []
        decisions = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        battle.DECISION_TRACE_HANDLER = decisions.append
        try:
            active = player("Active")
            opponent = player("Opponent")
            iron_man = {
                "name": "Iron Man, Titan of Innovation",
                "cmc": 4,
                "type_line": "Legendary Artifact Creature — Human Hero",
                "oracle_text": "Flying, haste\nGenius Industrialist — Whenever Iron Man attacks, create a Treasure token, then you may sacrifice a noncreature artifact. If you do, search your library for an artifact card with mana value equal to 1 plus the sacrificed artifact's mana value, put it onto the battlefield tapped, then shuffle.",
                "effect": "attack_artifact_tutor",
                "artifact_attack_tutor": True,
                "artifact_tutor_cmc_mode": "sacrificed_mana_value_plus",
                "artifact_tutor_sacrifice_noncreature": True,
                "artifact_tutor_enters_tapped": True,
                "attack_trigger": True,
                "power": 4,
                "toughness": 4,
                "summoning_sick": False,
                "tapped": False,
                "_rule_source": "focused_battle_rule_evidence",
                "_rule_review_status": "needs_review",
            }
            active.battlefield = [
                iron_man,
            ]
            active.library = [
                {"name": "Sol Ring", "cmc": 1, "type_line": "Artifact", "effect": "ramp_permanent", "mana_produced": 2},
                {"name": "High Cost Artifact", "cmc": 5, "type_line": "Artifact", "effect": "finisher"},
            ]

            battle.combat_phase_v8(
                active,
                [opponent],
                [active, opponent],
                turn=4,
                rng=random.Random(111),
                stack=battle.Stack(),
            )
        finally:
            battle.REPLAY_EVENT_HANDLER = None
            battle.DECISION_TRACE_HANDLER = None

        assert active.treasures == 0
        assert any(card.get("name") == "Sol Ring" and card.get("tapped") is True for card in active.battlefield)
        assert not any(card.get("name") == "Sol Ring" for card in active.library)
        assert any(
            event == "trigger_resolved"
            and data.get("card") == "Iron Man, Titan of Innovation"
            and data.get("activation_kind") == "artifact_attack_tutor"
            and data.get("artifact_sacrificed") == "Treasure token"
            and data.get("found") == "Sol Ring"
            and data.get("target_cmc") == 1
            and data.get("cmc_match") == "exact"
            and data.get("enters_tapped") is True
            for event, data in events
        )
        assert any(
            decision.get("decision_type") == "attack_trigger_artifact_tutor"
            and decision.get("chosen_option", {}).get("target") == "Sol Ring"
            and decision.get("rule_status") == "needs_review"
            for decision in decisions
        )

    return [
        test_lorehold_miracle_requires_lorehold_on_battlefield,
        test_lorehold_miracle_casts_first_draw_only_with_lorehold,
        test_lorehold_miracle_does_not_use_second_draw_of_turn,
        test_lorehold_miracle_skips_bad_wheel_refill,
        test_lorehold_miracle_does_not_cast_counter_without_stack_target,
        test_landfall_does_not_enqueue_without_real_landfall_source,
        test_landfall_enqueue_with_real_landfall_source,
        test_reforge_resolution_draws_seven_when_count_missing,
        test_boros_charm_protects_creatures_until_cleanup,
        test_akromas_will_keywords_are_until_end_of_turn_without_power_boost,
        test_mox_amber_only_counts_mana_with_live_legend,
        test_silence_effect_blocks_counterspell_responses,
        test_lorehold_miracle_ignores_lands_and_creatures,
        test_lorehold_miracle_rejects_flash_creatures,
        test_silence_spell_blocks_responses_until_cleanup_only,
        test_samis_curiosity_creates_lander_token_not_tutor,
        test_audit_promoted_cards_keep_conservative_semantics,
        test_snapback_return_target_creature_stays_creature_removal,
        test_functional_tag_gate_cards_resolve_from_manual_waivers,
        test_basking_broodscale_enters_as_creature_not_immediate_token_maker,
        test_scavenging_ooze_enters_as_creature_not_immediate_removal,
        test_mox_diamond_discards_land_when_it_unlocks_commander,
        test_mox_diamond_does_not_spend_last_land_without_payoff,
        test_mox_diamond_does_not_claim_unaffordable_commander_payoff,
        test_chrome_mox_imprints_colored_nonartifact_nonland_card,
        test_chrome_mox_does_not_cast_without_valid_imprint,
        test_everflowing_chalice_pays_multikicker_before_becoming_mana_source,
        test_everflowing_chalice_does_not_cast_as_zero_mana_ramp,
        test_lightning_greaves_grants_haste_and_shroud_without_indestructible,
        test_birgi_adds_red_mana_when_controller_casts_spell,
        test_electroduplicate_creates_hasty_copy_and_sacrifices_at_end_step,
        test_valakut_awakening_filters_hand_and_draws_plus_one,
        test_mulligan_trace_scores_keep_vs_mulligan_for_heavy_dead_hand,
        test_special_lands_are_modelled_as_lands_not_spell_heuristics,
        test_war_room_activates_when_hand_is_low_and_life_is_safe,
        test_war_room_skips_when_life_is_too_low,
        test_sunbaked_canyon_turns_expendable_land_into_card,
        test_sunbaked_canyon_requires_extra_mana_beyond_its_own_tap_proxy,
        test_sunbaked_canyon_skips_when_it_would_cut_too_deep_on_lands,
        test_inventors_fair_gains_life_on_upkeep_with_three_artifacts,
        test_inventors_fair_tutors_artifact_when_threshold_and_mana_exist,
        test_inventors_fair_skips_without_artifact_threshold,
        test_hall_of_heliods_generosity_recovers_best_enchantment_to_top,
        test_hall_of_heliods_generosity_skips_without_white_mana,
        test_ancient_tomb_pays_life_only_when_it_unlocks_contextual_play,
        test_ancient_tomb_skips_when_no_relevant_unlock_exists,
        test_ancient_tomb_skips_when_life_is_too_low,
        test_chromatic_star_precombat_unlocks_off_color_spell,
        test_chromatic_star_postcombat_cash_in_when_hand_is_low,
        test_urzas_saga_enters_with_initial_chapter_state,
        test_urzas_saga_creates_construct_on_chapter_two,
        test_urzas_saga_tutors_safe_artifact_then_sacrifices,
        test_angels_grace_prevents_lethal_damage_and_life_zero_loss_this_turn,
        test_angels_grace_blocks_opponent_approach_win_this_turn,
        test_senseis_top_sets_up_lorehold_approach_second_cast,
        test_scroll_rack_sets_up_lorehold_approach_second_cast_on_opponent_upkeep,
        test_brainstone_first_draw_approach_wins_before_rummage_resolution,
        test_natural_order_sacrifices_green_creature_for_green_battlefield_tutor,
        test_natural_order_does_not_cast_without_green_creature_to_sacrifice,
        test_dismember_applies_stat_modifier_and_kills_indestructible_zero_toughness,
        test_ashnods_altar_sacrifices_token_only_for_contextual_mana_unlock,
        test_goblin_bombardment_sacrifices_expendable_token_for_damage,
        test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast,
        test_goblin_bombardment_skips_without_expendable_creature,
        test_iron_man_attack_trigger_sacrifices_treasure_for_artifact_tutor,
    ]
