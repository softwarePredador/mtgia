#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import random
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def _load_battle_module():
    spec = importlib.util.spec_from_file_location(
        "battle_priority_lorehold_card_runtime_test",
        BATTLE_MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = _load_battle_module()


def card(name, type_line, **extra):
    payload = {"name": name, "type_line": type_line}
    payload.update(extra)
    return payload


class PriorityLoreholdCardRuntimeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.events = []
        self.decisions = []
        self.old_event_handler = battle.REPLAY_EVENT_HANDLER
        self.old_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: self.events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda data: self.decisions.append(data)

    def tearDown(self) -> None:
        battle.REPLAY_EVENT_HANDLER = self.old_event_handler
        battle.DECISION_TRACE_HANDLER = self.old_decision_handler

    def test_mana_family_sources_produce_expected_runtime_mana(self) -> None:
        commander = card(
            "Lorehold, the Historian",
            "Legendary Creature — Elder Dragon",
            color_identity=["R", "W"],
        )
        player = battle.Player("Lorehold", commander, [], is_human=True)
        opponent = battle.Player(
            "Opponent",
            card(
                "Dimir Commander",
                "Legendary Creature",
                color_identity=["U", "B"],
            ),
            [],
        )
        opponent.battlefield = [
            card("Island", "Basic Land — Island", effect="land"),
            card("Blood Crypt", "Land — Swamp Mountain", effect="land", produces="BR"),
            card(
                "Command Tower",
                "Land",
                effect="land",
                commander_identity_mana_source=True,
            ),
        ]
        battle.bind_table_context([player, opponent])
        player.battlefield = [
            card(
                "Command Tower",
                "Land",
                effect="land",
                mana_produced=1,
                produces="WUBRGC",
                commander_identity_mana_source=True,
                battle_model_scope="commander_identity_land_mana_source_v1",
            ),
            card(
                "Sol Ring",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=2,
                produces="C",
                battle_model_scope="two_colorless_mana_rock_v1",
            ),
            card(
                "Fellwar Stone",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=1,
                produces="WUBRGC",
                battle_model_scope="conditional_opponent_color_mana_rock_v1",
                conditionally_produces_opponent_land_colors=True,
            ),
            card(
                "Talisman of Conviction",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=1,
                produces="CRW",
                life_for_colored_mana=1,
                battle_model_scope="pain_talisman_color_pair_partial_v1",
            ),
        ]

        player.refresh_mana_sources(turn=1)

        self.assertEqual(player.available_mana(), 5)
        self.assertEqual(player.mana_pool.snapshot().get("colorless"), 2)
        conditional_sources = {source["source"]: source for source in player.conditional_mana_sources}
        self.assertEqual(
            sorted(mode["color"] for mode in conditional_sources["Command Tower"]["modes"]),
            ["red", "white"],
        )
        self.assertEqual(
            sorted(mode["color"] for mode in conditional_sources["Fellwar Stone"]["modes"]),
            ["black", "blue", "red"],
        )
        self.assertEqual(
            sorted(mode["color"] for mode in conditional_sources["Talisman of Conviction"]["modes"]),
            ["colorless", "red", "white"],
        )
        self.assertIn("Fellwar Stone", conditional_sources)
        talisman_modes = {
            mode["color"]: mode
            for mode in conditional_sources["Talisman of Conviction"]["modes"]
        }
        self.assertEqual(talisman_modes["colorless"]["life_loss_on_spend"], 0)
        self.assertEqual(talisman_modes["red"]["life_loss_on_spend"], 1)
        self.assertEqual(talisman_modes["white"]["life_loss_on_spend"], 1)

    @staticmethod
    def _birgi_harnfel_runtime_effect():
        return {
            "effect": "ramp_engine",
            "trigger": "spell_cast",
            "spell_cast_add_mana": 1,
            "spell_cast_mana_color": "R",
            "back_face_harnfel_discard_exile_two_play_this_turn": True,
            "back_face_status": "runtime_executor_v1",
            "battle_model_scope": "birgi_harnfel_modal_faces_exact_v1",
            "back_face": {
                "name": "Harnfel, Horn of Bounty",
                "mana_cost": "{4}{R}",
                "cmc": 5,
                "type_line": "Legendary Artifact",
                "oracle_text": (
                    "Discard a card: Exile the top two cards of your library. "
                    "You may play those cards this turn."
                ),
                "activated_discard_count": 1,
                "activated_discard_exile_top_count": 2,
                "play_exiled_until": "end_of_turn",
                "runtime_status": "runtime_executor_v1",
            },
            "_rule_source": "curated",
            "_rule_review_status": "verified",
            "_rule_execution_status": "auto",
            "_rule_logical_key": "battle_rule_v1:test_birgi_harnfel_exact",
            "_rule_oracle_hash": "test-birgi-harnfel-two-face-hash",
        }

    @staticmethod
    def _underworld_breach_runtime_permanent():
        return card(
            "Underworld Breach",
            "Enchantment",
            effect="passive",
            grants_escape_to_nonland_cards_in_graveyard=True,
            escape_additional_cost_exile_other_graveyard_cards=3,
            escape_grant_status="runtime_executor_v1",
            end_step_sacrifice_status="runtime_executor_v1",
            sacrifice_at_beginning_of_end_step=True,
            battle_model_scope="underworld_breach_escape_and_end_step_sacrifice_exact_v1",
            _rule_source="curated",
            _rule_review_status="verified",
            _rule_execution_status="auto",
            _rule_logical_key="battle_rule_v1:test_underworld_breach_exact",
            _rule_oracle_hash="test-underworld-breach-oracle-hash",
        )

    @staticmethod
    def _mana_vault_runtime_permanent(**extra):
        payload = card(
            "Mana Vault",
            "Artifact",
            cmc=1,
            mana_cost="{1}",
            effect="ramp_permanent",
            mana_produced=3,
            produces="C",
            does_not_untap_normally=True,
            mana_vault_runtime_status="runtime_executor_v1",
            upkeep_optional_untap_cost_generic=4,
            upkeep_optional_untap_status="runtime_executor_v1",
            tapped_draw_step_damage=1,
            draw_step_damage_status="runtime_executor_v1",
            battle_model_scope="mana_vault_exact_untap_draw_damage_mana_v1",
            oracle_runtime_scope=(
                "no_normal_untap_optional_upkeep_pay_four_draw_step_tapped_"
                "damage_one_tap_add_three_colorless_exact_v1"
            ),
            _rule_source="curated",
            _rule_review_status="verified",
            _rule_execution_status="auto",
            _rule_logical_key="battle_rule_v1:test_mana_vault_exact",
            _rule_oracle_hash="test-mana-vault-oracle-hash",
        )
        payload.update(extra)
        return payload

    def test_harnfel_back_face_casts_for_five_and_resolves_as_artifact(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        birgi = card(
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Legendary Creature — God",
            cmc=3,
            mana_cost="{2}{R}",
            power=3,
            toughness=3,
        )
        discard_fuel = card("Spare Card", "Sorcery", cmc=2, mana_cost="{1}{R}", effect="draw")
        player.hand = [birgi, discard_fuel]
        player.library = [card("Top One", "Sorcery"), card("Top Two", "Land")]
        player.mana_pool.add_generic(4)
        player.mana_pool.add("red", 1)
        stack = battle.Stack()

        casted = battle.cast_harnfel_back_face_from_hand(
            player,
            [opponent],
            [player, opponent],
            turn=4,
            phase="precombat_main",
            stack=stack,
            rng=random.Random(401),
            card=birgi,
            effect_data_override=self._birgi_harnfel_runtime_effect(),
        )

        self.assertTrue(casted)
        self.assertNotIn(birgi, player.hand)
        self.assertEqual(player.available_mana(), 0)
        self.assertEqual(stack.items[-1].card["name"], "Harnfel, Horn of Bounty")
        item = stack.resolve_top()
        battle.apply_effect_immediate(
            player,
            [opponent],
            item.card,
            4,
            random.Random(402),
            effect_data_override=item.effect_data,
            stack=stack,
            phase="precombat_main",
        )
        harnfel = player.battlefield[-1]
        self.assertEqual(harnfel["name"], "Harnfel, Horn of Bounty")
        self.assertIn("Artifact", harnfel["type_line"])
        self.assertNotIn("Creature", harnfel["type_line"])
        self.assertTrue(harnfel["harnfel_discard_exile_play_runtime"])
        self.assertFalse(harnfel.get("spell_cast_add_mana"))
        self.assertTrue(any(event == "modal_dfc_back_face_cast" for event, _ in self.events))

    def test_harnfel_back_face_requires_mana_discard_fuel_and_library(self) -> None:
        effect = self._birgi_harnfel_runtime_effect()
        for generic_mana, include_fuel, include_library in (
            (3, True, True),
            (4, False, True),
            (4, True, False),
        ):
            with self.subTest(
                generic_mana=generic_mana,
                include_fuel=include_fuel,
                include_library=include_library,
            ):
                player = battle.Player("Lorehold", None, [], is_human=True)
                birgi = card(
                    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                    "Legendary Creature — God",
                    cmc=3,
                    mana_cost="{2}{R}",
                )
                player.hand = [birgi]
                if include_fuel:
                    player.hand.append(card("Fuel", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"))
                player.library = [card("Top", "Sorcery")] if include_library else []
                player.mana_pool.add_generic(generic_mana)
                player.mana_pool.add("red", 1)
                self.assertFalse(
                    battle.cast_harnfel_back_face_from_hand(
                        player,
                        [],
                        [player],
                        turn=4,
                        phase="precombat_main",
                        stack=battle.Stack(),
                        rng=random.Random(403),
                        card=birgi,
                        effect_data_override=effect,
                    )
                )
                self.assertIn(birgi, player.hand)

    def test_harnfel_discard_replacement_then_exiles_two_with_normal_cost_permission(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        lorehold = card(
            "Lorehold, the Historian",
            "Legendary Creature — Elder Dragon",
            effect="creature",
            discard_effect_to_top_replacement=True,
            grants_miracle_cost=2,
        )
        harnfel = card(
            "Harnfel, Horn of Bounty",
            "Legendary Artifact",
            effect="passive",
            harnfel_discard_exile_play_runtime=True,
            harnfel_activation_status="runtime_executor_v1",
            harnfel_exile_top_count=2,
            _rule_source="curated",
            _rule_review_status="verified",
        )
        approach = card(
            "Approach of the Second Sun",
            "Sorcery",
            cmc=7,
            mana_cost="{6}{W}",
        )
        playable = card("Playable Draw", "Sorcery", cmc=1, mana_cost="{R}", effect="draw")
        player.battlefield = [lorehold, harnfel]
        player.hand = [approach]
        player.library = [playable, card("Next Card", "Sorcery", cmc=3, mana_cost="{2}{R}")]

        activated = battle.activate_harnfel_horn_of_bounty(
            player,
            harnfel,
            [opponent],
            [player, opponent],
            turn=5,
            rng=random.Random(404),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(any(exiled["name"] == "Approach of the Second Sun" for exiled in player.exile))
        self.assertTrue(any(exiled["name"] == "Playable Draw" for exiled in player.exile))
        self.assertFalse(player.hand)
        self.assertTrue(
            any(
                event == "harnfel_discard_cost_paid" and data["discard_replacement_used"]
                for event, data in self.events
            )
        )

        player.mana_pool.add("red", 1)
        stack = battle.Stack()
        self.assertTrue(
            battle.cast_harnfel_permission_card_from_exile(
                player,
                playable,
                [opponent],
                [player, opponent],
                turn=5,
                phase="precombat_main",
                stack=stack,
                rng=random.Random(405),
            )
        )
        self.assertNotIn(playable, player.exile)
        self.assertEqual(player.available_mana(), 0)
        self.assertEqual(stack.items[-1].card["name"], "Playable Draw")
        play_events = [data for event, data in self.events if event == "harnfel_exiled_card_played"]
        self.assertFalse(play_events[-1]["cast_without_paying_mana_cost"])

    def test_harnfel_is_repeatable_at_priority_and_unused_permission_expires_in_exile(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        harnfel = card(
            "Harnfel, Horn of Bounty",
            "Legendary Artifact",
            effect="passive",
            harnfel_discard_exile_play_runtime=True,
            harnfel_activation_status="runtime_executor_v1",
            harnfel_exile_top_count=2,
        )
        player.battlefield = [harnfel]
        player.hand = [
            card("Fuel One", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"),
            card("Fuel Two", "Sorcery", cmc=2, mana_cost="{1}{R}", effect="draw"),
        ]
        player.library = [
            card("Exile One", "Sorcery"),
            card("Exile Two", "Sorcery"),
            card("Exile Three", "Sorcery"),
            card("Exile Four", "Sorcery"),
        ]
        self.assertTrue(
            battle.activate_harnfel_horn_of_bounty(
                player, harnfel, [], [player], 6, random.Random(406), phase="end_step"
            )
        )
        self.assertTrue(
            battle.activate_harnfel_horn_of_bounty(
                player, harnfel, [], [player], 6, random.Random(407), phase="end_step"
            )
        )
        self.assertEqual(len(player.exile), 4)
        expired = battle.expire_harnfel_exile_permissions(player, 6)
        self.assertEqual(len(expired), 4)
        self.assertEqual(len(player.exile), 4)
        self.assertTrue(all("_harnfel_play_permission_turn" not in exiled for exiled in player.exile))

    def test_harnfel_restores_front_face_after_leaving_battlefield(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        front = card(
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Legendary Creature — God",
            cmc=3,
            mana_cost="{2}{R}",
            power=3,
            toughness=3,
        )
        harnfel = card(
            "Harnfel, Horn of Bounty",
            "Legendary Artifact",
            cmc=5,
            mana_cost="{4}{R}",
            effect="passive",
            _modal_dfc_front_face=front,
        )
        player.battlefield = [harnfel]

        destination = battle.move_permanent_from_battlefield(
            player,
            harnfel,
            reason="destroyed",
            all_players=[player],
        )

        self.assertEqual(destination, "graveyard")
        self.assertEqual(player.graveyard[-1]["name"], front["name"])
        self.assertEqual(player.graveyard[-1]["cmc"], 3)
        self.assertIn("Creature", player.graveyard[-1]["type_line"])

    def test_harnfel_activation_rejects_opponents_permanent_and_invalid_phase(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        harnfel = card(
            "Harnfel, Horn of Bounty",
            "Legendary Artifact",
            effect="passive",
            harnfel_discard_exile_play_runtime=True,
            harnfel_activation_status="runtime_executor_v1",
            harnfel_exile_top_count=2,
            controller=opponent.name,
        )
        opponent.battlefield = [harnfel]
        player.hand = [card("Fuel", "Sorcery", mana_cost="{R}", effect="draw")]
        player.library = [card("One", "Sorcery"), card("Two", "Sorcery")]

        self.assertFalse(
            battle.activate_harnfel_horn_of_bounty(
                player, harnfel, [opponent], [player, opponent], 6, random.Random(408), phase="end_step"
            )
        )
        player.battlefield = [harnfel]
        opponent.battlefield = []
        harnfel["controller"] = player.name
        self.assertFalse(
            battle.activate_harnfel_horn_of_bounty(
                player, harnfel, [opponent], [player, opponent], 6, random.Random(409), phase="not_a_phase"
            )
        )
        self.assertEqual(len(player.hand), 1)
        self.assertEqual(len(player.library), 2)

    def test_harnfel_face_choice_can_prefer_birgi_with_real_spell_chain(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        birgi = card(
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Legendary Creature — God",
            cmc=3,
            mana_cost="{2}{R}",
        )
        player.hand = [
            birgi,
            card("Chain One", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"),
            card("Chain Two", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"),
            card("Chain Three", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"),
        ]
        player.library = [card(f"Top {index}", "Sorcery") for index in range(4)]
        player.mana_pool.add_generic(4)
        player.mana_pool.add("red", 1)

        self.assertIsNone(
            battle.harnfel_back_face_cast_option(
                player,
                birgi,
                "precombat_main",
                effect_data_override=self._birgi_harnfel_runtime_effect(),
            )
        )

    def test_harnfel_restores_front_on_targeted_exile_chaos_warp_and_blink(self) -> None:
        def front_card():
            return card(
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "Legendary Creature — God",
                cmc=3,
                mana_cost="{2}{R}",
                power=3,
                toughness=3,
            )

        def back_card():
            return card(
                "Harnfel, Horn of Bounty",
                "Legendary Artifact",
                cmc=5,
                mana_cost="{4}{R}",
                effect="passive",
                _modal_dfc_front_face=front_card(),
            )

        with self.subTest(route="targeted_exile"):
            player = battle.Player("Lorehold", None, [], is_human=True)
            harnfel = back_card()
            player.battlefield = [harnfel]
            destination = battle.move_removed_permanent_to_destination(
                player,
                harnfel,
                card("Exile Spell", "Instant"),
                {"effect": "removal_exile", "destination": "exile"},
                8,
                random.Random(410),
                all_players=[player],
            )
            self.assertEqual(destination, "exile")
            self.assertEqual(player.exile[-1]["name"], front_card()["name"])
            self.assertEqual(player.exile[-1]["cmc"], 3)

        with self.subTest(route="chaos_warp"):
            player = battle.Player("Lorehold", None, [], is_human=True)
            harnfel = back_card()
            player.battlefield = [harnfel]
            battle.move_permanent_to_library_then_reveal(
                player,
                harnfel,
                card("Chaos Warp", "Instant"),
                {"effect": "remove_permanent", "destination": "library"},
                8,
                random.Random(411),
                all_players=[player],
            )
            self.assertEqual(player.battlefield[-1]["name"], front_card()["name"])
            self.assertIn("Creature", player.battlefield[-1]["type_line"])

        with self.subTest(route="blink"):
            player = battle.Player("Lorehold", None, [], is_human=True)
            harnfel = back_card()
            player.battlefield = [harnfel]
            returned = battle.resolve_blink_permanent(
                player,
                [],
                card("Blink", "Instant"),
                {"effect": "blink", "blink_target_scope": "permanent_you_control"},
                harnfel,
                8,
                random.Random(412),
                all_players=[player],
            )
            self.assertEqual(returned["name"], front_card()["name"])
            self.assertIn("Creature", returned["type_line"])

    def test_harnfel_restores_front_when_sacrificed_for_activation(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        front = card(
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Legendary Creature — God",
            cmc=3,
            mana_cost="{2}{R}",
        )
        harnfel = card(
            "Harnfel, Horn of Bounty",
            "Legendary Artifact",
            cmc=5,
            mana_cost="{4}{R}",
            effect="passive",
            _modal_dfc_front_face=front,
        )
        player.battlefield = [harnfel]

        self.assertTrue(battle.sacrifice_permanent_for_activation(player, harnfel, 8))
        self.assertEqual(player.graveyard[-1]["name"], front["name"])
        self.assertEqual(player.graveyard[-1]["cmc"], 3)

    def test_harnfel_exiled_counter_uses_real_priority_target(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        opponent.approach_count = 1
        counter = card(
            "Exiled Reprieve",
            "Instant",
            cmc=1,
            mana_cost="{1}",
            effect="counter",
            _harnfel_play_permission_turn=9,
            _harnfel_play_permission_controller=player.name,
            _harnfel_play_permission_source="Harnfel, Horn of Bounty",
            _harnfel_play_permission_rule_fields={
                "rule_logical_key": "battle_rule_v1:test_birgi_harnfel_exact",
                "rule_oracle_hash": "test-birgi-harnfel-two-face-hash",
            },
        )
        threat = card(
            "Approach of the Second Sun",
            "Sorcery",
            cmc=7,
            mana_cost="{6}{W}",
            effect="approach",
        )
        player.exile = [counter]
        player.mana_pool.add_generic(1)
        stack = battle.Stack()
        stack.push(threat, opponent, battle.get_card_effect(threat))
        target_item = stack.items[-1]

        self.assertTrue(
            battle.priority_round(
                opponent,
                [opponent, player],
                stack,
                turn=9,
                rng=random.Random(416),
                phase="end_step",
            )
        )
        self.assertTrue(target_item.countered)
        self.assertIn(counter, player.graveyard)
        self.assertNotIn(counter, player.exile)
        self.assertTrue(
            any(
                name == "spell_cast" and data.get("cast_via_harnfel_permission")
                for name, data in self.events
            )
        )

    def test_harnfel_exiled_instant_uses_empty_end_step_priority_before_expiry(self) -> None:
        active_player = battle.Player("Active Opponent", None, [])
        player = battle.Player("Lorehold", None, [], is_human=True)
        impulse = card(
            "Exiled Insight",
            "Instant",
            cmc=1,
            mana_cost="{R}",
            effect="draw",
            count=1,
            _harnfel_play_permission_turn=9,
            _harnfel_play_permission_controller=player.name,
            _harnfel_play_permission_source="Harnfel, Horn of Bounty",
            _harnfel_play_permission_rule_fields={
                "rule_logical_key": "battle_rule_v1:test_birgi_harnfel_exact",
                "rule_oracle_hash": "test-birgi-harnfel-two-face-hash",
            },
        )
        player.exile = [impulse]
        player.library = [card("Drawn Card", "Land", effect="land")]
        player.mana_pool.add("red", 1)
        stack = battle.Stack()

        self.assertTrue(
            battle.priority_round(
                active_player,
                [active_player, player],
                stack,
                turn=9,
                rng=random.Random(417),
                phase="end_step",
            )
        )
        self.assertEqual(stack.items[-1].card["name"], "Exiled Insight")
        self.assertNotIn(impulse, player.exile)
        self.assertTrue(stack.items[-1].effect_data.get("_cast_context"))

    def test_underworld_breach_escape_pays_mana_and_exiles_exactly_three_other_cards(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        escaped = card("Escaped Draw", "Sorcery", cmc=1, mana_cost="{R}", effect="draw")
        fodder = [
            card(f"Fodder {index}", "Land", cmc=0, mana_cost="")
            for index in range(3)
        ]
        player.battlefield = [breach]
        player.graveyard = [escaped, *fodder]
        player.library = [card("Draw One", "Land"), card("Draw Two", "Land")]
        player.mana_pool.add("red", 1)
        stack = battle.Stack()

        self.assertTrue(
            battle.cast_escape_spell_from_graveyard(
                player,
                escaped,
                [opponent],
                [player, opponent],
                turn=5,
                phase="precombat_main",
                stack=stack,
                rng=random.Random(408),
            )
        )
        self.assertEqual(player.available_mana(), 0)
        self.assertEqual({entry["name"] for entry in player.exile}, {entry["name"] for entry in fodder})
        self.assertFalse(player.graveyard)
        item = stack.resolve_top()
        battle.apply_effect_immediate(
            player,
            [opponent],
            item.card,
            5,
            random.Random(409),
            effect_data_override=item.effect_data,
            stack=stack,
            phase="precombat_main",
        )
        self.assertTrue(any(card_in_grave["name"] == "Escaped Draw" for card_in_grave in player.graveyard))
        self.assertFalse(any(card_in_grave.get("_exile_on_resolution") for card_in_grave in player.graveyard))
        self.assertTrue(any(event == "escape_cast" for event, _ in self.events))

    def test_underworld_breach_rejects_lands_missing_mana_cost_and_insufficient_fodder(self) -> None:
        for escaped, fodder_count in (
            (card("Land Escape", "Land", cmc=0, mana_cost=""), 3),
            (card("No Mana Cost", "Sorcery", cmc=4, effect="draw"), 3),
            (card("Too Little Fodder", "Sorcery", cmc=1, mana_cost="{R}", effect="draw"), 2),
        ):
            with self.subTest(card=escaped["name"]):
                player = battle.Player("Lorehold", None, [], is_human=True)
                player.battlefield = [self._underworld_breach_runtime_permanent()]
                player.graveyard = [
                    escaped,
                    *[
                        card(f"Fodder {index}", "Land", cmc=0, mana_cost="")
                        for index in range(fodder_count)
                    ],
                ]
                player.mana_pool.add("red", 5)
                before_graveyard = list(player.graveyard)
                before_mana = player.available_mana()
                self.assertFalse(
                    battle.cast_escape_spell_from_graveyard(
                        player,
                        escaped,
                        [],
                        [player],
                        turn=5,
                        phase="precombat_main",
                        stack=battle.Stack(),
                        rng=random.Random(410),
                    )
                )
                self.assertEqual(player.graveyard, before_graveyard)
                self.assertEqual(player.available_mana(), before_mana)
                self.assertFalse(player.exile)

    def test_underworld_breach_sacrifice_uses_trigger_stack_on_any_players_end_step(self) -> None:
        controller = battle.Player("Breach Controller", None, [], is_human=True)
        active_player = battle.Player("Active Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        controller.battlefield = [breach]
        stack = battle.Stack()

        queued = battle.process_underworld_breach_end_step_sacrifices(
            active_player,
            [active_player, controller],
            turn=7,
            stack=stack,
        )

        self.assertFalse(queued)
        self.assertIn(breach, controller.battlefield)
        battle.flush_triggers_in_apnap(active_player, [active_player, controller], stack)
        self.assertEqual(len(stack.items), 1)
        item = stack.resolve_top()
        self.assertEqual(item.effect_data["effect"], "triggered_ability")
        item.effect_data["resolver"]()
        self.assertNotIn(breach, controller.battlefield)
        self.assertIn(breach, controller.graveyard)
        self.assertTrue(
            any(event == "underworld_breach_end_step_sacrificed" for event, _ in self.events)
        )

    def test_underworld_breach_zero_cost_escape_survives_zero_mana_router(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        escaped = card("Free Escape", "Sorcery", cmc=0, mana_cost="{0}", effect="draw", count=1)
        player.battlefield = [self._underworld_breach_runtime_permanent()]
        player.graveyard = [
            escaped,
            *[card(f"Fodder {index}", "Land", cmc=0, mana_cost="") for index in range(3)],
        ]
        player.library = [card("Drawn", "Land", effect="land")]
        stack = battle.Stack()

        self.assertTrue(
            battle.cast_spells_v8(
                player,
                [opponent],
                [player, opponent],
                turn=6,
                phase="precombat_main",
                stack=stack,
                rng=random.Random(412),
                max_actions=1,
            )
        )
        self.assertTrue(any(name == "escape_cast" for name, _ in self.events))

    def test_underworld_breach_escapes_instant_before_own_sacrifice_trigger(self) -> None:
        controller = battle.Player("Breach Controller", None, [], is_human=True)
        active_player = battle.Player("Active Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        instant = card("Last-Chance Insight", "Instant", cmc=1, mana_cost="{R}", effect="draw", count=1)
        controller.battlefield = [breach]
        controller.graveyard = [
            instant,
            *[card(f"Fodder {index}", "Land", cmc=0, mana_cost="") for index in range(3)],
        ]
        controller.library = [card("Drawn", "Land", effect="land")]
        controller.mana_pool.add("red", 1)
        stack = battle.Stack()

        battle.process_underworld_breach_end_step_sacrifices(
            active_player,
            [active_player, controller],
            turn=7,
            stack=stack,
        )
        battle.flush_triggers_in_apnap(active_player, [active_player, controller], stack)

        self.assertTrue(
            battle.priority_round(
                active_player,
                [active_player, controller],
                stack,
                turn=7,
                rng=random.Random(413),
                phase="end_step",
            )
        )
        self.assertEqual(stack.items[-1].card["name"], "Last-Chance Insight")
        self.assertIn(breach, controller.battlefield)
        self.assertTrue(any(name == "escape_cast" for name, _ in self.events))

    def test_underworld_breach_escaped_counter_uses_real_stack_target(self) -> None:
        player = battle.Player("Breach Controller", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        counter = card("Escaped Counter", "Instant", cmc=1, mana_cost="{1}", effect="counter")
        target = card("Opponent Threat", "Sorcery", cmc=5, mana_cost="{5}", effect="board_wipe")
        player.battlefield = [breach]
        player.graveyard = [
            counter,
            *[card(f"Fodder {index}", "Land", cmc=0, mana_cost="") for index in range(3)],
        ]
        player.mana_pool.add_generic(1)
        stack = battle.Stack()
        stack.push(target, opponent, battle.get_card_effect(target))
        target_item = stack.items[-1]

        self.assertTrue(
            battle.cast_best_escape_priority_response(
                player,
                [opponent, player],
                turn=7,
                phase="end_step",
                stack=stack,
                rng=random.Random(414),
                stack_item=target_item,
            )
        )
        self.assertTrue(target_item.countered)
        self.assertIn(counter, player.graveyard)
        self.assertEqual(len(player.exile), 3)
        self.assertTrue(any(name == "escape_cast" for name, _ in self.events))

    def test_countered_breach_trigger_does_not_create_phantom_card(self) -> None:
        controller = battle.Player("Breach Controller", None, [], is_human=True)
        active_player = battle.Player("Active Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        controller.battlefield = [breach]
        stack = battle.Stack()

        battle.process_underworld_breach_end_step_sacrifices(
            active_player,
            [active_player, controller],
            turn=7,
            stack=stack,
        )
        battle.flush_triggers_in_apnap(active_player, [active_player, controller], stack)
        stack.items[-1].countered = True
        self.assertIsNone(stack.resolve_top())

        self.assertEqual(controller.graveyard, [])
        self.assertIn(breach, controller.battlefield)
        self.assertTrue(any(name == "trigger_countered" for name, _ in self.events))

    def test_breach_trigger_tracks_zone_identity_and_deduplicates_same_event(self) -> None:
        controller = battle.Player("Breach Controller", None, [], is_human=True)
        active_player = battle.Player("Active Opponent", None, [])
        breach = self._underworld_breach_runtime_permanent()
        controller.battlefield = [breach]
        stack = battle.Stack()

        for _ in range(2):
            battle.process_underworld_breach_end_step_sacrifices(
                active_player,
                [active_player, controller],
                turn=7,
                stack=stack,
            )
        battle.flush_triggers_in_apnap(active_player, [active_player, controller], stack)
        self.assertEqual(len(stack.items), 1)

        battle.move_permanent_from_battlefield(
            controller,
            breach,
            reason="test_leave_reenter",
            source="test",
            all_players=[active_player, controller],
        )
        controller.graveyard.remove(breach)
        controller.battlefield.append(breach)
        stack.resolve_top().effect_data["resolver"]()

        self.assertIn(breach, controller.battlefield)
        self.assertTrue(
            any(name == "underworld_breach_end_step_sacrifice_skipped" for name, _ in self.events)
        )

    def test_stale_escape_option_is_revalidated_before_any_payment(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        escaped = card("Escaped Draw", "Sorcery", cmc=1, mana_cost="{R}", effect="draw")
        fodder = [card(f"Fodder {index}", "Land", cmc=0, mana_cost="") for index in range(3)]
        player.battlefield = [self._underworld_breach_runtime_permanent()]
        player.graveyard = [escaped, *fodder]
        player.mana_pool.add("red", 1)
        option = battle.escape_spell_option(player, escaped, [opponent], turn=5, phase="precombat_main")
        player.graveyard.remove(fodder[-1])
        player.exile.append(fodder[-1])
        mana_before = player.available_mana()
        casts_before = player.spells_cast_this_turn

        self.assertFalse(
            battle.cast_escape_spell_from_graveyard(
                player,
                escaped,
                [opponent],
                [player, opponent],
                turn=5,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(415),
                option=option,
            )
        )
        self.assertEqual(player.available_mana(), mana_before)
        self.assertEqual(player.spells_cast_this_turn, casts_before)
        self.assertIn(escaped, player.graveyard)

    def test_escape_commander_fodder_moves_to_command_zone(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        escaped = card("Escaped Draw", "Sorcery", cmc=1, mana_cost="{R}", effect="draw")
        commander = card(
            "Graveyard Commander",
            "Legendary Creature",
            cmc=4,
            mana_cost="{4}",
            is_commander=True,
        )
        other_fodder = [card(f"Fodder {index}", "Land", cmc=0, mana_cost="") for index in range(2)]
        player.battlefield = [self._underworld_breach_runtime_permanent()]
        player.graveyard = [escaped, commander, *other_fodder]
        player.mana_pool.add("red", 1)

        self.assertTrue(
            battle.cast_escape_spell_from_graveyard(
                player,
                escaped,
                [opponent],
                [player, opponent],
                turn=5,
                phase="precombat_main",
                stack=battle.Stack(),
                rng=random.Random(416),
            )
        )
        self.assertIn(commander, player.command_zone)
        self.assertNotIn(commander, player.exile)
        event = next(data for name, data in self.events if name == "escape_additional_cost_paid")
        self.assertIn("command_zone", event["cost_destinations"])

    def test_mana_vault_upkeep_trigger_pays_four_and_untaps_at_low_life(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.life = 8
        vault = self._mana_vault_runtime_permanent(tapped=True)
        player.battlefield = [vault]
        player.mana_pool.add_generic(4)
        stack = battle.Stack()

        self.assertEqual(
            battle.process_mana_vault_upkeep_optional_untap(
                player,
                [player],
                turn=8,
                stack=stack,
            ),
            1,
        )
        self.assertTrue(vault["tapped"])
        battle.flush_triggers_in_apnap(player, [player], stack)
        item = stack.resolve_top()
        item.effect_data["resolver"]()

        self.assertFalse(vault["tapped"])
        self.assertEqual(player.available_mana(), 0)
        self.assertEqual(vault["_mana_vault_upkeep_untapped_turn"], 8)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertTrue(event["paid"])

    def test_mana_vault_initial_refresh_emits_one_provenanced_activation_event(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(tapped=False)
        player.battlefield = [vault]

        player.refresh_mana_sources(turn=7)

        self.assertTrue(vault["tapped"])
        self.assertEqual(player.mana_pool.colorless, 3)
        events = [
            data
            for name, data in self.events
            if name == "mana_vault_mana_activated"
        ]
        self.assertEqual(len(events), 1)
        event = events[0]
        self.assertEqual(event["activation_kind"], "mana_refresh_auto_activation")
        self.assertFalse(event["activation_after_upkeep_untap"])
        self.assertEqual(event["mana_added"], 3)
        self.assertEqual(event["phase"], "mana_refresh")
        self.assertEqual(
            event["rule_logical_key"],
            "battle_rule_v1:test_mana_vault_exact",
        )
        self.assertEqual(event["rule_oracle_hash"], "test-mana-vault-oracle-hash")
        self.assertEqual(
            event["battle_model_scope"],
            "mana_vault_exact_untap_draw_damage_mana_v1",
        )
        self.assertEqual(
            event["oracle_runtime_scope"],
            "no_normal_untap_optional_upkeep_pay_four_draw_step_tapped_"
            "damage_one_tap_add_three_colorless_exact_v1",
        )

    def test_mana_vault_optional_untap_declines_without_surplus_or_low_life(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.life = 30
        vault = self._mana_vault_runtime_permanent(tapped=True)
        player.battlefield = [vault]
        player.mana_pool.add_generic(4)

        battle.process_mana_vault_upkeep_optional_untap(
            player,
            [player],
            turn=8,
            stack=None,
        )

        self.assertTrue(vault["tapped"])
        self.assertEqual(player.available_mana(), 4)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertFalse(event["paid"])

    def test_mana_vault_declines_upkeep_untap_with_high_mana_and_payoff(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.life = 30
        vault = self._mana_vault_runtime_permanent(tapped=True)
        player.battlefield = [vault]
        player.hand = [
            card("Expensive Payoff", "Sorcery", cmc=7, mana_cost="{7}", effect="draw")
        ]
        player.mana_pool.add_generic(9)

        battle.process_mana_vault_upkeep_optional_untap(
            player,
            [player],
            turn=8,
            stack=None,
        )

        self.assertTrue(vault["tapped"])
        self.assertEqual(player.available_mana(), 9)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertFalse(event["paid"])
        self.assertEqual(event["reason"], "preserve_four_mana_over_optional_untap")

    def test_mana_vault_explicit_future_value_override_pays_upkeep_untap(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.life = 30
        vault = self._mana_vault_runtime_permanent(
            tapped=True,
            mana_vault_upkeep_untap_future_value_override=True,
        )
        player.battlefield = [vault]
        player.mana_pool.add_generic(4)

        battle.process_mana_vault_upkeep_optional_untap(
            player,
            [player],
            turn=8,
            stack=None,
        )

        self.assertFalse(vault["tapped"])
        self.assertEqual(player.available_mana(), 0)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertTrue(event["paid"])
        self.assertEqual(event["reason"], "explicit_future_value_override")

    def test_mana_vault_upkeep_trigger_exists_while_untapped_and_declines(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(tapped=False)
        player.battlefield = [vault]
        player.mana_pool.add_generic(9)
        stack = battle.Stack()

        self.assertEqual(
            battle.process_mana_vault_upkeep_optional_untap(
                player,
                [player],
                turn=8,
                stack=stack,
            ),
            1,
        )
        battle.flush_triggers_in_apnap(player, [player], stack)
        item = stack.resolve_top()
        item.effect_data["resolver"]()

        self.assertFalse(vault["tapped"])
        self.assertEqual(player.available_mana(), 9)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertFalse(event["paid"])
        self.assertEqual(event["reason"], "not_tapped_or_cannot_pay")

    def test_mana_vault_upkeep_cannot_pay_four_and_normal_untap_is_locked(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(tapped=True)
        player.battlefield = [vault]
        player.mana_pool.add_generic(3)

        self.assertTrue(battle.does_not_untap_in_untap_step(vault))
        battle.process_mana_vault_upkeep_optional_untap(
            player,
            [player],
            turn=8,
            stack=None,
        )

        self.assertTrue(vault["tapped"])
        self.assertEqual(player.available_mana(), 3)
        event = next(data for name, data in self.events if name == "mana_vault_upkeep_untap")
        self.assertFalse(event["paid"])

    def test_mana_vault_draw_trigger_waits_until_after_draw_and_rechecks_tapped(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(tapped=True)
        drawn_card = card("Drawn Card", "Sorcery")
        player.battlefield = [vault]
        player.library = [drawn_card]
        stack = battle.Stack()

        battle.process_mana_vault_draw_step_damage(
            player,
            [player],
            turn=9,
            stack=stack,
        )
        player.draw(1, random.Random(411), phase="draw_step")
        self.assertEqual(player.hand, [drawn_card])
        self.assertEqual(player.life, 40)
        battle.flush_triggers_in_apnap(player, [player], stack)
        item = stack.resolve_top()
        item.effect_data["resolver"]()
        self.assertEqual(player.life, 39)

        player.life = 40
        vault["tapped"] = True
        battle.process_mana_vault_draw_step_damage(
            player,
            [player],
            turn=10,
            stack=stack,
        )
        battle.flush_triggers_in_apnap(player, [player], stack)
        vault["tapped"] = False
        item = stack.resolve_top()
        item.effect_data["resolver"]()
        self.assertEqual(player.life, 40)
        self.assertTrue(
            any(name == "mana_vault_draw_step_damage_skipped" for name, _ in self.events)
        )

    def test_mana_vault_draw_damage_uses_static_damage_replacements(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(tapped=True)
        gisela = card(
            "Gisela, Blade of Goldnight",
            "Legendary Creature — Angel",
            effect="static_damage_modifier",
            battle_model_scope="opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1",
            damage_modifier_applies_to="any_source",
            damage_modifier_targets=["opponents", "opponent_permanents"],
            damage_multiplier=2,
            prevent_half_damage_to_you_and_permanents_you_control=True,
            prevent_half_rounding="rounded_up",
        )
        player.battlefield = [vault, gisela]

        battle.process_mana_vault_draw_step_damage(
            player,
            [player],
            turn=9,
            stack=None,
        )

        self.assertEqual(player.life, 40)
        event = next(data for name, data in self.events if name == "mana_vault_draw_step_damage")
        self.assertEqual(event["damage"], 1)
        self.assertEqual(event["final_damage"], 0)
        self.assertEqual(event["damage_dealt"], 0)
        self.assertEqual(event["result"], "damage_prevented")

    def test_multiple_mana_vaults_create_independent_draw_triggers(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        first = self._mana_vault_runtime_permanent(tapped=True)
        second = self._mana_vault_runtime_permanent(tapped=True)
        player.battlefield = [first, second]
        stack = battle.Stack()

        self.assertEqual(
            battle.process_mana_vault_draw_step_damage(
                player,
                [player],
                turn=9,
                stack=stack,
            ),
            2,
        )
        battle.flush_triggers_in_apnap(player, [player], stack)
        self.assertEqual(len(stack.items), 2)
        while stack.items:
            stack.resolve_top().effect_data["resolver"]()

        self.assertEqual(player.life, 38)

    def test_mana_vault_can_activate_after_upkeep_untap_only_when_it_unlocks_spell(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        vault = self._mana_vault_runtime_permanent(
            tapped=False,
            _mana_vault_upkeep_untapped_turn=11,
        )
        payoff = card("Three Mana Payoff", "Sorcery", cmc=3, mana_cost="{3}", effect="draw")
        player.battlefield = [vault]
        player.hand = [payoff]
        battle.CURRENT_REPLAY_TURN = 11

        self.assertTrue(
            battle.activate_mana_vault_after_upkeep_untap(
                player,
                11,
                phase="precombat_main",
            )
        )
        self.assertTrue(vault["tapped"])
        self.assertEqual(player.mana_pool.colorless, 3)
        activation_events = [
            data
            for name, data in self.events
            if name == "mana_vault_mana_activated"
        ]
        self.assertEqual(len(activation_events), 1)
        self.assertEqual(activation_events[0]["activation_kind"], "after_upkeep_untap")
        self.assertTrue(activation_events[0]["activation_after_upkeep_untap"])
        self.assertEqual(
            activation_events[0]["rule_logical_key"],
            "battle_rule_v1:test_mana_vault_exact",
        )
        self.assertEqual(
            activation_events[0]["rule_oracle_hash"],
            "test-mana-vault-oracle-hash",
        )
        self.assertFalse(
            battle.activate_mana_vault_after_upkeep_untap(
                player,
                11,
                phase="precombat_main",
            )
        )
        self.assertEqual(player.mana_pool.colorless, 3)

    def test_turbulent_steppe_enters_untapped_only_when_opponents_control_eight_lands(self) -> None:
        def basic_lands(prefix: str, count: int):
            return [
                card(f"{prefix} Land {index}", "Basic Land — Mountain", effect="land")
                for index in range(count)
            ]

        def play_with_opponent_land_count(opponent_land_count: int):
            player = battle.Player("Lorehold", None, [], is_human=True)
            opponent = battle.Player("Opponent", None, [])
            opponent.battlefield = basic_lands("Opponent", opponent_land_count)
            steppe = card("Turbulent Steppe", "Land — Mountain Plains", cmc=0)
            player.hand = [steppe]

            played = battle.play_land_candidate(
                player,
                [opponent],
                [player, opponent],
                turn=4,
                stack=battle.Stack(),
                candidate={"card": steppe, "source_zone": "hand"},
            )

            self.assertTrue(played)
            return player.battlefield[-1], player

        tapped_steppe, tapped_player = play_with_opponent_land_count(7)
        self.assertTrue(tapped_steppe["tapped"])
        self.assertTrue(tapped_steppe["enters_tapped"])
        self.assertEqual(
            tapped_steppe["conditional_enters_tapped_reason"],
            "opponents_below_required_land_count",
        )
        self.assertEqual(tapped_player.available_mana(), 0)

        untapped_steppe, untapped_player = play_with_opponent_land_count(8)
        self.assertFalse(untapped_steppe.get("tapped", False))
        self.assertFalse(untapped_steppe.get("enters_tapped", False))
        self.assertEqual(
            untapped_steppe["conditional_enters_tapped_reason"],
            "opponents_control_required_land_count",
        )
        self.assertEqual(untapped_steppe["conditional_enters_tapped_land_count"], 8)
        self.assertEqual(untapped_player.available_mana(), 1)
        self.assertEqual(untapped_player.mana_pool.snapshot().get("wildcard"), 1)

    def test_farewell_modal_exile_wipe_exiles_selected_types_and_graveyards(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.battlefield = [
            card("Sol Ring", "Artifact", effect="ramp_permanent"),
            card("Lorehold Apprentice", "Creature — Human Cleric", effect="creature", power=2, toughness=2),
            card("Ghostly Prison", "Enchantment", effect="passive"),
            card("Plains", "Basic Land — Plains", effect="land"),
        ]
        opponent.battlefield = [
            card("Darksteel Myr", "Artifact Creature — Myr", effect="creature", indestructible=True),
            card("Command Tower", "Land", effect="land"),
        ]
        player.graveyard = [card("Faithless Looting", "Sorcery")]
        opponent.graveyard = [card("Counterspell", "Instant")]
        effect = {
            "effect": "board_wipe",
            "exile_modes": ["artifacts", "creatures", "enchantments", "graveyards"],
            "battle_model_scope": "modal_exile_wipe_creature_runtime_baseline_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Farewell", "Sorcery", cmc=6),
            turn=3,
            rng=random.Random(3),
            effect_data_override=effect,
        )

        self.assertEqual([permanent["name"] for permanent in player.battlefield], ["Plains"])
        self.assertEqual([permanent["name"] for permanent in opponent.battlefield], ["Command Tower"])
        exile_names = {exiled["name"] for exiled in player.exile + opponent.exile}
        self.assertTrue({"Sol Ring", "Lorehold Apprentice", "Ghostly Prison", "Darksteel Myr"} <= exile_names)
        self.assertEqual([grave_card["name"] for grave_card in player.graveyard], ["Farewell"])
        self.assertFalse(opponent.graveyard)
        event_payloads = [
            data for event, data in self.events if event == "modal_exile_board_wipe_resolved"
        ]
        self.assertEqual(event_payloads[0]["battlefield_exiled"], 4)
        self.assertEqual(event_payloads[0]["graveyard_exiled"], 2)

    def test_swords_to_plowshares_exiles_creature_and_grants_life_equal_power(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        opponent.life = 10
        target = card("Questing Beast", "Creature — Beast", effect="creature", power=4, toughness=4)
        opponent.battlefield = [target]
        effect = {
            "effect": "remove_creature",
            "target": "creature",
            "destination": "exile",
            "exile_target": True,
            "target_controller_life_gain_equal_target_power": True,
            "battle_model_scope": "swords_to_plowshares_creature_exile_life_equal_power_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Swords to Plowshares", "Instant", cmc=1),
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertFalse(opponent.battlefield)
        self.assertEqual([exiled["name"] for exiled in opponent.exile], ["Questing Beast"])
        self.assertEqual(opponent.life, 14)

    def test_teferis_protection_phases_all_permanents_and_locks_life(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.battlefield = [
            card("Lorehold, the Historian", "Legendary Creature — Elder Dragon", effect="creature"),
            card("Plains", "Basic Land — Plains", effect="land"),
        ]
        effect = {
            "effect": "phase_out",
            "duration": "until_your_next_turn",
            "exiles_self": True,
            "life_total_cant_change": True,
            "protection_from_everything": True,
            "phase_out_all_permanents_you_control": True,
            "phase_out_includes_lands": True,
            "battle_model_scope": "teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1",
        }

        battle.apply_effect_immediate(
            player,
            [],
            card("Teferi's Protection", "Instant", cmc=3),
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertFalse(player.battlefield)
        self.assertEqual({permanent["name"] for permanent in player.phased_out}, {"Lorehold, the Historian", "Plains"})
        self.assertTrue(player.life_cant_change)
        self.assertTrue(player.protection_from_everything)

    def test_flawless_maneuver_grants_controlled_creatures_indestructible(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.battlefield = [
            card("Lorehold, the Historian", "Legendary Creature — Elder Dragon", effect="creature"),
            card("Storm-Kiln Artist", "Creature — Dwarf Shaman", effect="creature"),
            card("Sol Ring", "Artifact", effect="ramp_permanent"),
        ]
        effect = {
            "effect": "indestructible",
            "target_scope": "creatures_you_control",
            "free_if_control_commander": True,
            "battle_model_scope": "flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1",
        }

        battle.apply_effect_immediate(
            player,
            [],
            card("Flawless Maneuver", "Instant", cmc=3),
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertTrue(player.battlefield[0]["indestructible"])
        self.assertTrue(player.battlefield[1]["indestructible"])
        self.assertFalse(player.battlefield[2].get("indestructible", False))

    def test_land_tax_tutors_three_basic_lands_when_opponent_has_more_lands(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        land_tax = card(
            "Land Tax",
            "Enchantment",
            effect="land_tax",
            max_count=3,
            tutor_target="basic_land",
            reveals=True,
            shuffle_after=True,
            battle_model_scope="land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1",
        )
        player.battlefield = [
            land_tax,
            card("Plains", "Basic Land — Plains", effect="land", basic=True),
        ]
        opponent.battlefield = [
            card("Island", "Basic Land — Island", effect="land", basic=True),
            card("Mountain", "Basic Land — Mountain", effect="land", basic=True),
        ]
        player.library = [
            card("Plains", "Basic Land — Plains", basic=True),
            card("Mountain", "Basic Land — Mountain", basic=True),
            card("Sacred Foundry", "Land — Mountain Plains"),
            card("Island", "Basic Land — Island", basic=True),
        ]

        moved = battle.resolve_land_tax_upkeep_trigger(
            player,
            land_tax,
            turn=1,
            all_players=[player, opponent],
        )

        self.assertEqual(moved, 3)
        self.assertEqual({hand_card["name"] for hand_card in player.hand}, {"Plains", "Mountain", "Island"})
        self.assertEqual([library_card["name"] for library_card in player.library], ["Sacred Foundry"])

    def test_library_of_leng_replaces_discard_to_top_for_lorehold_draw(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        discarded = card("Comet Storm", "Instant", cmc=3)
        player.battlefield = [
            card(
                "Library of Leng",
                "Artifact",
                effect="passive",
                no_max_hand_size=True,
                discard_effect_to_top_replacement=True,
                battle_model_scope="discard_replacement_to_top_v1",
            )
        ]
        player.hand = [discarded]

        result = battle.resolve_effect_discard_cards(
            player,
            [discarded],
            top_limit=1,
            opponents=[],
            turn=1,
            phase="opponent_upkeep",
        )

        self.assertTrue(result["used_replacement"])
        self.assertEqual([card_["name"] for card_ in result["to_top"]], ["Comet Storm"])
        self.assertEqual(player.library[0]["name"], "Comet Storm")
        self.assertFalse(player.graveyard)

    def test_thor_noncreature_spell_trigger_deals_spell_mana_value_damage(self) -> None:
        player = battle.Player("Thor Player", None, [])
        opponent = battle.Player("Opponent", None, [])
        opponent.life = 4
        thor_effect = {
            "effect": "creature",
            "is_creature_permanent": True,
            "power": 5,
            "toughness": 5,
            "flying": True,
            "trigger": "noncreature_spell_cast",
            "trigger_effect": "damage_any_target",
            "trigger_damage_amount_source": "trigger_spell_mana_value",
            "battle_model_scope": "etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Thor, God of Thunder", "Legendary Creature — God Warrior Hero", cmc=5),
            turn=3,
            rng=random.Random(17),
            effect_data_override=thor_effect,
        )
        battle.trigger_spell_cast_engines(
            player,
            [player, opponent],
            card("Big Score", "Instant", cmc=4),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )
        battle.trigger_spell_cast_engines(
            player,
            [player, opponent],
            card("Creature Followup", "Creature", cmc=4),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )

        thor_triggers = [
            data
            for event, data in self.events
            if event == "trigger_resolved"
            and data.get("card") == "Thor, God of Thunder"
            and data.get("effect") == "damage_any_target"
        ]
        self.assertEqual(len(thor_triggers), 1)
        self.assertEqual(thor_triggers[0]["amount"], 4)
        self.assertEqual(thor_triggers[0]["result"], "player_damage")
        self.assertEqual(opponent.life, 0)

    def test_hit_the_mother_lode_discovers_and_creates_treasure_difference(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.library = [
            card("Mountain", "Basic Land — Mountain", effect="land", cmc=0),
            card("Expensive Miss", "Sorcery", effect="draw_cards", count=0, cmc=11),
            card("Free Hit", "Sorcery", effect="draw_cards", count=0, cmc=4),
        ]
        effect = {
            "effect": "draw_cards",
            "count": 1,
            "discover_value": 10,
            "discover_treasure_difference": True,
            "battle_model_scope": "discover_10_as_one_card_value_component_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Hit the Mother Lode", "Sorcery", cmc=7),
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual(player.treasures, 6)
        self.assertEqual([grave_card["name"] for grave_card in player.graveyard], ["Free Hit", "Hit the Mother Lode"])
        self.assertEqual({library_card["name"] for library_card in player.library}, {"Mountain", "Expensive Miss"})
        events = [data for event, data in self.events if event == "discover_resolved"]
        self.assertEqual(events[0]["hit"], "Free Hit")
        self.assertEqual(events[0]["hit_mana_value"], 4)
        self.assertEqual(events[0]["treasures_created"], 6)
        self.assertTrue(events[0]["cast_success"])
        free_cast_decisions = [
            decision
            for decision in self.decisions
            if decision.get("reason") == "optional_exiled_free_cast_selected"
        ]
        self.assertEqual(
            [decision["chosen_option"]["card"] for decision in free_cast_decisions],
            ["Free Hit"],
        )
        self.assertEqual(
            free_cast_decisions[0]["rejected_options"][0]["action"],
            "decline_optional_exiled_free_cast",
        )

    def test_improvisation_capstone_exiles_until_total_mana_value_and_free_casts(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.library = [
            card("Plains", "Basic Land — Plains", effect="land", cmc=0),
            card("Small Spell", "Instant", effect="draw_cards", count=0, cmc=2),
            card("Second Spell", "Sorcery", effect="draw_cards", count=0, cmc=3),
        ]
        effect = {
            "effect": "exile_value",
            "exile_until_total_mana_value_at_least": 4,
            "may_cast_exiled_spells_without_paying": True,
            "paradigm": True,
            "battle_model_scope": "exile_value_free_casts_paradigm_annotation_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Improvisation Capstone", "Sorcery", cmc=7),
            turn=6,
            rng=random.Random(6),
            effect_data_override=effect,
        )

        self.assertEqual(
            [grave_card["name"] for grave_card in player.graveyard],
            ["Small Spell", "Second Spell", "Improvisation Capstone"],
        )
        self.assertEqual([exiled["name"] for exiled in player.exile], ["Plains"])
        events = [data for event, data in self.events if event == "exile_value_free_casts_resolved"]
        self.assertEqual(events[0]["exiled_total_mana_value"], 5)
        self.assertEqual(events[0]["free_cast_count"], 2)
        self.assertTrue(events[0]["paradigm"])
        free_cast_decisions = [
            decision
            for decision in self.decisions
            if decision.get("reason") == "optional_exiled_free_cast_selected"
        ]
        self.assertEqual(
            [decision["chosen_option"]["card"] for decision in free_cast_decisions],
            ["Small Spell", "Second Spell"],
        )

    def test_tibalts_trickery_counters_then_resolves_random_replacement(self) -> None:
        counter_player = battle.Player("Lorehold", None, [], is_human=True)
        spell_player = battle.Player("Opponent", None, [])
        tibalt = card(
            "Tibalt's Trickery",
            "Instant",
            effect="counter",
            target="spell",
            instant=True,
            cmc=2,
            random_mill_then_free_replacement_spell=True,
            battle_model_scope="counterspell_with_random_replacement_annotation_v1",
        )
        target_spell = card("Original Bomb", "Sorcery", effect="draw_cards", count=0, cmc=7)
        counter_player.hand = [tibalt]
        counter_player.mana_pool.add_generic(2)
        spell_player.library = [
            card("Island", "Basic Land — Island", effect="land", cmc=0),
            card("Mountain", "Basic Land — Mountain", effect="land", cmc=0),
            card("Forest", "Basic Land — Forest", effect="land", cmc=0),
            card("Replacement Spell", "Sorcery", effect="draw_cards", count=0, cmc=5),
        ]
        stack_item = battle.StackItem(target_spell, spell_player, {"effect": "draw_cards", "count": 0})

        used_counter = counter_player.use_counterspell(
            turn=7,
            target_card=target_spell,
            stack_item=stack_item,
            phase="stack_response",
            all_players=[counter_player, spell_player],
        )

        self.assertIs(used_counter, tibalt)
        self.assertTrue(tibalt["_countered_target"])
        self.assertIn(tibalt, counter_player.graveyard)
        self.assertIn("Replacement Spell", [grave_card["name"] for grave_card in spell_player.graveyard])
        events = [data for event, data in self.events if event == "tibalts_trickery_replacement_resolved"]
        self.assertEqual(events[0]["replacement_hit"], "Replacement Spell")
        self.assertTrue(events[0]["replacement_cast_success"])
        self.assertGreaterEqual(events[0]["cards_milled"], 1)
        free_cast_decisions = [
            decision
            for decision in self.decisions
            if decision.get("reason") == "optional_exiled_free_cast_selected"
        ]
        self.assertEqual(
            [decision["chosen_option"]["card"] for decision in free_cast_decisions],
            ["Replacement Spell"],
        )

    def test_audit_050500_optional_free_casts_all_emit_matching_decisions(self) -> None:
        audited_cards = [
            "Dawn's Truce",
            "Land Tax",
            "Flawless Maneuver",
            "Rise of the Eldrazi",
            "Ragavan, Nimble Pilferer",
            "Scroll Rack",
            "Creative Technique",
            "Deflecting Swat",
            "Mana Vault",
            "Fellwar Stone",
            "Avatar's Wrath",
            "Blasphemous Act",
        ]
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        source = card("Audit Optional Cast Source", "Sorcery", effect="exile_value")
        original_get_card_effect = battle.get_card_effect
        battle.get_card_effect = lambda candidate: {
            "effect": "draw_cards",
            "count": 0,
            "_rule_source": "audit_050500_fixture",
            "_rule_review_status": "verified",
        }
        try:
            for audited_name in audited_cards:
                exiled_card = card(
                    audited_name,
                    "Sorcery",
                    effect="draw_cards",
                    count=0,
                    cmc=3,
                )
                player.exile.append(exiled_card)
                success, result = battle.cast_exiled_card_without_paying_mana(
                    player,
                    [opponent],
                    [player, opponent],
                    source,
                    exiled_card,
                    turn=8,
                    rng=random.Random(80500),
                    source_effect_data={
                        "effect": "exile_value",
                        "_rule_source": "audit_050500_fixture",
                        "_rule_review_status": "verified",
                    },
                    phase="resolution",
                    resolution_label="audit_050500_fixture",
                    optional_cast=True,
                )
                self.assertTrue(success)
                self.assertEqual(result, "cast_without_paying_mana")
        finally:
            battle.get_card_effect = original_get_card_effect

        spell_casts = [
            data
            for event, data in self.events
            if event == "spell_cast" and data.get("card") in audited_cards
        ]
        decisions = [
            decision
            for decision in self.decisions
            if decision.get("reason") == "optional_exiled_free_cast_selected"
            and decision.get("chosen_option", {}).get("card") in audited_cards
        ]
        self.assertEqual([event["card"] for event in spell_casts], audited_cards)
        self.assertTrue(all(event["cast_choice_optional"] is True for event in spell_casts))
        self.assertEqual(
            [decision["chosen_option"]["card"] for decision in decisions],
            audited_cards,
        )
        decision_keys = {
            (
                decision.get("turn"),
                decision.get("player"),
                decision.get("phase"),
                decision.get("chosen_option", {}).get("card"),
            )
            for decision in decisions
        }
        self.assertEqual(
            {
                (event.get("turn"), event.get("player"), event.get("phase"), event.get("card"))
                for event in spell_casts
            },
            decision_keys,
        )

    def test_optional_free_cast_declines_reactive_spell_without_stack_target(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        reactive_spell = card(
            "Optional Counter Without Target",
            "Instant",
            effect="counter",
            target="spell",
            instant=True,
            cmc=2,
        )
        player.exile = [reactive_spell]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            reactive_spell,
            turn=8,
            rng=random.Random(81),
            source_effect_data={"effect": "exile_value"},
            phase="resolution",
            resolution_label="reactive_without_target",
            optional_cast=True,
        )

        self.assertFalse(success)
        self.assertEqual(
            result,
            "declined_optional_free_cast_reactive_spell_has_no_valid_stack_target",
        )
        self.assertIn(reactive_spell, player.exile)
        decision = self.decisions[-1]
        self.assertEqual(decision["reason"], "optional_exiled_free_cast_declined")
        self.assertEqual(
            decision["chosen_option"]["action"],
            "decline_optional_exiled_free_cast",
        )
        self.assertEqual(
            decision["chosen_option"]["decline_reason"],
            "reactive_spell_has_no_valid_stack_target",
        )
        self.assertEqual(
            decision["rejected_options"][0]["action"],
            "cast_optional_exiled_card_without_paying_mana",
        )
        self.assertFalse(
            any(
                event in {"cast_announced", "spell_cast"}
                and data.get("card") == reactive_spell["name"]
                for event, data in self.events
            )
        )

    def test_optional_free_cast_declines_valid_counter_target_until_direct_runtime_exists(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        reactive_spell = card(
            "Optional Counter With Pending Target",
            "Instant",
            effect="counter",
            target="spell",
            instant=True,
            cmc=2,
        )
        pending_spell = card(
            "Pending Opponent Spell",
            "Sorcery",
            effect="draw_cards",
            count=2,
            cmc=4,
        )
        player.exile = [reactive_spell]
        pending_stack = battle.Stack()
        pending_stack.push(
            pending_spell,
            opponent,
            {"effect": "draw_cards", "count": 2},
        )

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            reactive_spell,
            turn=8,
            rng=random.Random(810),
            source_effect_data={"effect": "exile_value"},
            stack=pending_stack,
            phase="resolution",
            resolution_label="counter_with_pending_target",
            optional_cast=True,
        )

        self.assertFalse(success)
        self.assertEqual(
            result,
            "declined_optional_free_cast_counter_stack_target_runtime_unsupported_for_direct_free_cast",
        )
        self.assertIn(reactive_spell, player.exile)
        self.assertFalse(pending_stack.items[-1].countered)
        decision = self.decisions[-1]
        self.assertEqual(decision["score_components"]["valid_stack_target_detected"], 1)
        self.assertIn("stack_target_runtime_unsupported", decision["risk_flags"])
        self.assertEqual(
            decision["chosen_option"]["action"],
            "decline_optional_exiled_free_cast",
        )

    def test_top_nonland_decline_bottoms_uncast_reactive_hit_with_revealed_lands(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        revealed_land = card(
            "Revealed Mountain",
            "Basic Land — Mountain",
            effect="land",
            cmc=0,
        )
        reactive_hit = card(
            "Reactive Hit Without Target",
            "Instant",
            effect="counter",
            target="spell",
            instant=True,
            cmc=2,
        )
        library_tail = card(
            "Library Tail",
            "Creature",
            effect="creature",
            cmc=3,
            power=3,
            toughness=3,
        )
        player.library = [revealed_land, reactive_hit, library_tail]
        source = card("Creative Technique Fixture", "Sorcery", cmc=5)
        source_effect = {
            "effect": "exile_top_nonland_free_cast",
            "shuffle_before_reveal": False,
        }

        summary = battle.resolve_top_nonland_free_cast(
            player,
            [opponent],
            [player, opponent],
            source,
            source_effect,
            turn=8,
            rng=random.Random(811),
            phase="resolution",
            resolution_label="declined_reactive_hit",
        )

        self.assertFalse(summary["cast_success"])
        self.assertEqual(
            summary["cast_result"],
            "declined_optional_free_cast_reactive_spell_has_no_valid_stack_target",
        )
        self.assertTrue(summary["uncast_card_bottomed"])
        self.assertEqual(
            set(summary["bottomed_cards"]),
            {"Revealed Mountain", "Reactive Hit Without Target"},
        )
        self.assertEqual(player.library[0]["name"], "Library Tail")
        self.assertEqual(
            {candidate["name"] for candidate in player.library[-2:]},
            {"Revealed Mountain", "Reactive Hit Without Target"},
        )
        self.assertNotIn(reactive_hit, player.exile)
        self.assertNotIn(reactive_hit, player.graveyard)
        decision = self.decisions[-1]
        self.assertEqual(decision["reason"], "optional_exiled_free_cast_declined")
        resolved = next(
            data
            for event, data in self.events
            if event == "top_nonland_free_cast_resolved"
            and data.get("source_resolution") == "declined_reactive_hit"
        )
        self.assertTrue(resolved["uncast_card_bottomed"])
        self.assertEqual(set(resolved["bottomed_cards"]), set(summary["bottomed_cards"]))

    def test_optional_free_cast_declines_protection_without_pending_threat(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.battlefield = [
            card(
                "Creature Worth Protecting",
                "Creature",
                effect="creature",
                power=5,
                toughness=5,
            )
        ]
        protection = card(
            "Flawless Maneuver",
            "Instant",
            effect="indestructible",
            instant=True,
            cmc=3,
        )
        player.exile = [protection]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            protection,
            turn=8,
            rng=random.Random(82),
            source_effect_data={"effect": "exile_value"},
            phase="resolution",
            resolution_label="protection_without_threat",
            optional_cast=True,
        )

        self.assertFalse(success)
        self.assertEqual(
            result,
            "declined_optional_free_cast_reactive_protection_has_no_pending_threat",
        )
        self.assertIn(protection, player.exile)
        self.assertFalse(player.indestructible)
        decision = self.decisions[-1]
        self.assertEqual(
            decision["score_components"]["reactive_context_available"],
            0,
        )
        self.assertEqual(
            decision["rejected_reason"],
            "reactive_protection_has_no_pending_threat",
        )

    def test_optional_free_cast_selects_protection_for_pending_stack_threat(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        protected_creature = card(
            "Creature Facing Pending Wipe",
            "Creature",
            effect="creature",
            power=5,
            toughness=5,
        )
        player.battlefield = [protected_creature]
        protection = card(
            "Flawless Maneuver",
            "Instant",
            effect="indestructible",
            instant=True,
            cmc=3,
        )
        player.exile = [protection]
        pending_stack = battle.Stack()
        pending_stack.push(
            card("Pending Board Wipe", "Sorcery", effect="board_wipe", cmc=4),
            opponent,
            {"effect": "board_wipe"},
        )

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            protection,
            turn=8,
            rng=random.Random(821),
            source_effect_data={"effect": "exile_value"},
            stack=pending_stack,
            phase="resolution",
            resolution_label="protection_with_pending_threat",
            optional_cast=True,
        )

        self.assertTrue(success)
        self.assertEqual(result, "cast_without_paying_mana")
        self.assertTrue(player.indestructible)
        self.assertTrue(protected_creature["indestructible"])
        decision = self.decisions[-1]
        self.assertEqual(decision["reason"], "optional_exiled_free_cast_selected")
        self.assertEqual(
            decision["score_components"]["pending_stack_effect"],
            "board_wipe",
        )
        self.assertGreaterEqual(
            decision["score_components"]["pending_stack_threat_score"],
            40,
        )
        self.assertEqual(
            decision["score_components"]["reactive_context_available"],
            1,
        )

    def test_optional_free_cast_declines_targeted_removal_without_legal_target(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        removal = card(
            "Optional Removal Without Target",
            "Instant",
            effect="remove_creature",
            target="creature",
            instant=True,
            cmc=2,
        )
        player.exile = [removal]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            removal,
            turn=8,
            rng=random.Random(83),
            source_effect_data={"effect": "exile_value"},
            phase="resolution",
            resolution_label="removal_without_target",
            optional_cast=True,
        )

        self.assertFalse(success)
        self.assertEqual(
            result,
            "declined_optional_free_cast_required_battlefield_target_unavailable",
        )
        self.assertIn(removal, player.exile)
        decision = self.decisions[-1]
        self.assertEqual(decision["score_components"]["declared_target_count"], 0)
        self.assertIn("required_target_unavailable", decision["risk_flags"])

    def test_optional_free_cast_selects_targeted_removal_with_legal_target(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        target = card(
            "Legal Removal Target",
            "Creature",
            effect="creature",
            power=6,
            toughness=6,
            cmc=6,
        )
        opponent.battlefield = [target]
        removal = card(
            "Optional Removal With Target",
            "Instant",
            effect="remove_creature",
            target="creature",
            instant=True,
            cmc=2,
        )
        player.exile = [removal]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            removal,
            turn=8,
            rng=random.Random(84),
            source_effect_data={"effect": "exile_value"},
            phase="resolution",
            resolution_label="removal_with_target",
            optional_cast=True,
        )

        self.assertTrue(success)
        self.assertEqual(result, "cast_without_paying_mana")
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        decision = self.decisions[-1]
        self.assertEqual(decision["reason"], "optional_exiled_free_cast_selected")
        self.assertEqual(decision["score_components"]["declared_target_count"], 1)
        self.assertEqual(
            decision["score_components"]["declared_targets"],
            ["Legal Removal Target"],
        )
        spell_cast = next(
            data
            for event, data in self.events
            if event == "spell_cast" and data.get("card") == removal["name"]
        )
        self.assertEqual(spell_cast["target"], "Legal Removal Target")
        self.assertTrue(spell_cast["cast_choice_optional"])

    def test_optional_free_cast_declines_unprofitable_board_wipe(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        own_creature = card(
            "Only Creature on the Table",
            "Creature",
            effect="creature",
            power=7,
            toughness=7,
        )
        player.battlefield = [own_creature]
        wipe = card(
            "Optional Unprofitable Wipe",
            "Sorcery",
            effect="damage_wipe",
            damage=13,
            cmc=9,
        )
        player.exile = [wipe]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Optional Cast Source", "Sorcery", effect="exile_value"),
            wipe,
            turn=8,
            rng=random.Random(85),
            source_effect_data={"effect": "exile_value"},
            phase="resolution",
            resolution_label="unprofitable_board_wipe",
            optional_cast=True,
        )

        self.assertFalse(success)
        self.assertEqual(
            result,
            "declined_optional_free_cast_board_wipe_has_negative_or_zero_board_value",
        )
        self.assertIn(own_creature, player.battlefield)
        self.assertIn(wipe, player.exile)
        decision = self.decisions[-1]
        self.assertFalse(decision["score_components"]["board_wipe_timing_justified"])
        self.assertEqual(
            decision["chosen_option"]["action"],
            "decline_optional_exiled_free_cast",
        )

    def test_mandatory_exile_cast_does_not_emit_optional_choice_trace(self) -> None:
        player = battle.Player("Caster", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        mandatory_card = card(
            "Mandatory Free Cast",
            "Sorcery",
            effect="draw_cards",
            count=0,
            cmc=2,
        )
        player.exile = [mandatory_card]

        success, result = battle.cast_exiled_card_without_paying_mana(
            player,
            [opponent],
            [player, opponent],
            card("Mandatory Source", "Sorcery", effect="mandatory_free_cast"),
            mandatory_card,
            turn=9,
            rng=random.Random(9),
            source_effect_data={"effect": "mandatory_free_cast"},
            phase="resolution",
            resolution_label="mandatory_fixture",
        )

        self.assertTrue(success)
        self.assertEqual(result, "cast_without_paying_mana")
        self.assertTrue(
            any(
                event == "spell_cast"
                and data.get("card") == "Mandatory Free Cast"
                and data.get("cast_choice_optional") is False
                for event, data in self.events
            )
        )
        self.assertFalse(
            any(
                decision.get("chosen_option", {}).get("card") == "Mandatory Free Cast"
                for decision in self.decisions
            )
        )

    def test_lorehold_and_scroll_rack_set_hand_spell_as_next_miracle_draw(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True, strategy="spellslinger")
        player.battlefield = [
            card("Plains", "Basic Land — Plains", effect="land", mana_produced=1),
            card(
                "Lorehold, the Historian",
                "Legendary Creature — Elder Dragon",
                effect="passive",
                grants_miracle_cost=2,
                opponent_upkeep_rummage=True,
                battle_model_scope="lorehold_opponent_upkeep_miracle_v1",
            ),
            card(
                "Scroll Rack",
                "Artifact",
                effect="topdeck_manipulation",
                hand_to_top_exchange=True,
                activation_cost_generic=1,
                battle_model_scope="scroll_rack_upkeep_single_exchange_v1",
            ),
        ]
        player.hand = [
            card("Call Forth the Tempest", "Sorcery", cmc=8, mana_cost="{6}{R}{R}"),
        ]
        player.library = [card("Mountain", "Basic Land — Mountain", effect="land", cmc=0)]
        player.refresh_mana_sources(turn=2)

        activated = battle.activate_lorehold_topdeck_artifacts(
            player,
            turn=2,
            rng=random.Random(22),
            phase="opponent_upkeep",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(player.library[0]["name"], "Call Forth the Tempest")
        self.assertEqual([hand_card["name"] for hand_card in player.hand], ["Mountain"])
        events = [data for event, data in self.events if event == "topdeck_manipulation_activated"]
        self.assertEqual(events[0]["card"], "Scroll Rack")
        self.assertEqual(events[0]["activation_kind"], "scroll_rack_single_exchange_for_lorehold")
        self.assertEqual(events[0]["top_after"], "Call Forth the Tempest")

    def test_molecule_man_grants_zero_miracle_to_nonland_hand_cards(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        molecule = card(
            "Molecule Man",
            "Legendary Creature — Human Hero",
            effect="passive",
            grants_miracle_cost=0,
            grants_miracle_nonland=True,
            grants_miracle_card_scope="nonland",
            battle_model_scope="nonland_hand_miracle_zero_static_v1",
        )
        player.battlefield = [molecule]
        player.mana_pool.add_generic(0)
        nonland = card("Blasphemous Act", "Sorcery", cmc=9, mana_cost="{8}{R}")
        artifact = card("The One Ring", "Legendary Artifact", cmc=4, mana_cost="{4}")
        land = card("Plains", "Basic Land — Plains", cmc=0)

        self.assertEqual(battle.lorehold_miracle_cost(player), 0)
        self.assertTrue(battle.miracle_card_scope_allows(player, nonland))
        self.assertTrue(battle.miracle_card_scope_allows(player, artifact))
        self.assertFalse(battle.miracle_card_scope_allows(player, land))
        plan = battle.miracle_cast_plan_for_card(
            player,
            artifact,
            {"effect": "ramp_permanent"},
        )
        self.assertIsNotNone(plan)
        self.assertEqual(plan["miracle_cost"], 0)
        self.assertEqual(plan["locked_cost"]["generic"], 0)

    def test_pearl_medallion_and_scarlet_witch_apply_static_cost_reductions(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.battlefield = [
            card(
                "Pearl Medallion",
                "Artifact",
                effect="static_cost_reduction",
                cost_reduction_generic=1,
                applies_to_spell_colors=["W"],
                cost_reduction_applies_to="spells_you_cast",
                battle_model_scope="static_cost_reduction_for_matching_spells_v1",
            ),
            card(
                "The Scarlet Witch",
                "Legendary Creature — Human Warlock Hero",
                effect="static_cost_reduction",
                power=4,
                applies_to_card_types=["instant", "sorcery"],
                minimum_mana_value=4,
                cost_reduction_amount_source="source_power",
                cost_reduction_applies_to="instant_sorcery_spells_you_cast",
                battle_model_scope="static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1",
            ),
        ]

        white_big_spell = card("Farewell", "Sorcery", cmc=6, mana_cost="{4}{W}{W}")
        red_small_spell = card("Lightning Bolt", "Instant", cmc=1, mana_cost="{R}")
        artifact_spell = card("Sol Ring", "Artifact", cmc=1, mana_cost="{1}")
        white_cost = battle.card_cost_for_player_state(player, white_big_spell)
        red_cost = battle.card_cost_for_player_state(player, red_small_spell)
        artifact_cost = battle.card_cost_for_player_state(player, artifact_spell)

        self.assertEqual(white_cost["generic"], 0)
        self.assertEqual(white_cost["static_cost_reduction_total"], 4)
        self.assertEqual(
            {row["source"] for row in white_cost["static_cost_reductions"]},
            {"Pearl Medallion", "The Scarlet Witch"},
        )
        self.assertEqual(red_cost["generic"], 0)
        self.assertNotIn("static_cost_reduction_total", red_cost)
        self.assertEqual(artifact_cost["generic"], 1)
        self.assertNotIn("static_cost_reduction_total", artifact_cost)

    def test_prismari_pianist_creates_more_tokens_for_large_instant_or_sorcery(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        pianist = card(
            "Prismari Pianist",
            "Creature — Orc Wizard",
            effect="token_maker",
            trigger="instant_sorcery_cast",
            trigger_effect="token_maker",
            trigger_token_count=1,
            trigger_token_count_if_spell_cmc_at_least=5,
            trigger_token_count_at_or_above_threshold=3,
            token_name="Elemental Token",
            token_power=1,
            token_toughness=1,
            token_subtype="Elemental",
            token_colors=["U", "R"],
            battle_model_scope="instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1",
        )
        player.battlefield = [pianist]

        battle.trigger_spell_cast_engines(
            player,
            [player],
            card("Big Score", "Instant", cmc=4),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )
        battle.trigger_spell_cast_engines(
            player,
            [player],
            card("Rise of the Eldrazi", "Sorcery", cmc=12),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )

        tokens = [permanent for permanent in player.battlefield if permanent.get("name") == "Elemental Token"]
        self.assertEqual(len(tokens), 4)
        self.assertTrue(all(token.get("power") == 1 and token.get("toughness") == 1 for token in tokens))
        events = [data for event, data in self.events if event == "trigger_resolved" and data.get("card") == "Prismari Pianist"]
        self.assertEqual([event["tokens_created"] for event in events], [1, 3])

    def test_furygale_flocking_reduces_cost_from_graveyard_and_assigns_tokens(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponents = [battle.Player("Opponent A", None, []), battle.Player("Opponent B", None, [])]
        player.graveyard = [
            card("Faithless Looting", "Sorcery", cmc=1),
            card("Big Score", "Instant", cmc=4),
            card("Sol Ring", "Artifact", cmc=1),
        ]
        furygale_effect = {
            "effect": "token_maker",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "instant_sorcery_cards_in_your_graveyard_count",
            "graveyard_count_card_types": ["instant", "sorcery"],
            "token_name": "Elemental Token",
            "token_power": 3,
            "token_toughness": 3,
            "token_subtype": "Elemental",
            "token_colors": ["U", "R"],
            "token_flying": True,
            "token_haste": True,
            "token_count_per_opponent": 2,
            "attack_each_opponent_this_turn_status": "runtime_executor_v1",
            "battle_model_scope": "per_opponent_two_3_3_flying_hasty_elementals_graveyard_cost_reduction_runtime_attack_requirement_v1",
        }
        furygale = card("Furygale Flocking", "Sorcery", cmc=10, mana_cost="{8}{U}{R}", **furygale_effect)

        reduced_cost = battle.card_cost_for_player_state(player, furygale)
        created = battle.create_creature_tokens_from_effect(
            player,
            {**furygale_effect, "_source_card_name": "Furygale Flocking"},
            opponents=opponents,
            turn=6,
        )

        self.assertEqual(reduced_cost["generic"], 6)
        self.assertEqual(reduced_cost["static_cost_reduction_total"], 2)
        self.assertEqual(created, 4)
        tokens = [permanent for permanent in player.battlefield if permanent.get("name") == "Elemental Token"]
        self.assertEqual(len(tokens), 4)
        self.assertEqual(
            sorted(token.get("must_attack_defender") for token in tokens),
            ["Opponent A", "Opponent A", "Opponent B", "Opponent B"],
        )
        self.assertTrue(all(token.get("flying") and token.get("haste") for token in tokens))

    def test_redirect_lightning_changes_single_target_stack_object(self) -> None:
        redirector = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        original_target = card("Lorehold, the Historian", "Legendary Creature — Elder Dragon", effect="creature", power=2, toughness=5)
        new_target = card("Opponent Creature", "Creature — Zombie", effect="creature", power=3, toughness=3)
        redirector.battlefield = [original_target]
        opponent.battlefield = [new_target]
        stack_item = battle.StackItem(
            card("Murder", "Instant", effect="remove_creature"),
            opponent,
            {
                "effect": "remove_creature",
                "target": "creature",
                "declared_targets": [
                    {
                        "target": original_target,
                        "controller": redirector,
                        "target_type": "creature",
                    }
                ],
            },
        )
        effect = {
            "effect": "redirect_removal",
            "target": "single_target_spell_or_ability",
            "battle_model_scope": "single_target_spell_or_ability_redirect_additional_cost_annotation_v1",
            "redirect_target_mode_status": "runtime_executor_v1",
        }

        context = battle.redirectable_stack_context(redirector, [redirector, opponent], stack_item)
        resolved = battle.resolve_redirect_removal(
            redirector,
            [redirector, opponent],
            card("Redirect Lightning", "Instant", cmc=1),
            {**effect, "_redirect_context": context},
            turn=4,
            phase="stack_response",
        )

        self.assertTrue(resolved)
        self.assertIs(stack_item.effect_data["declared_targets"][0]["target"], new_target)
        events = [data for event, data in self.events if event == "redirect_removal_resolved"]
        self.assertEqual(events[0]["card"], "Redirect Lightning")
        self.assertEqual(events[0]["old_target"], "Lorehold, the Historian")
        self.assertEqual(events[0]["new_target"], "Opponent Creature")
        self.assertTrue(events[0]["target_change_applied"])

    def test_mind_stone_harnesses_and_blinks_best_nonland_permanent(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        mind_stone = card(
            "The Mind Stone",
            "Legendary Artifact",
            effect="ramp_permanent",
            mana_produced=1,
            produces="W",
            harness_activation_cost="{5}{W}",
            harness_activation_requires_tap=True,
            harnessed_end_step_blink=True,
            battle_model_scope="legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1",
        )
        target = card(
            "Solemn Simulacrum",
            "Artifact Creature — Golem",
            effect="creature",
            power=2,
            toughness=2,
            etb_draw_count=1,
        )
        player.battlefield = [
            mind_stone,
            target,
            card("Plains", "Basic Land — Plains", effect="land"),
        ]
        player.library = [card("Blink Draw", "Sorcery", cmc=2)]
        player.mana_pool.add_generic(5)
        player.mana_pool.add("white", 1)

        activated = battle.activate_utility_artifacts(
            player,
            [opponent],
            [player, opponent],
            turn=5,
            rng=random.Random(5),
            phase="postcombat_main",
        )
        battle.process_harnessed_end_step_blink(
            player,
            [opponent],
            [player, opponent],
            turn=5,
            rng=random.Random(6),
        )

        self.assertEqual(activated, 1)
        self.assertTrue(mind_stone["harnessed"])
        self.assertTrue(mind_stone["tapped"])
        self.assertEqual(
            [permanent["name"] for permanent in player.battlefield],
            ["The Mind Stone", "Plains", "Solemn Simulacrum"],
        )
        events = [data for event, data in self.events if event == "trigger_resolved" and data.get("card") == "The Mind Stone"]
        self.assertEqual(events[0]["effect"], "harnessed_blink")
        self.assertEqual(events[0]["blinked"], "Solemn Simulacrum")


if __name__ == "__main__":
    unittest.main()
