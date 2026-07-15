#!/usr/bin/env python3

from __future__ import annotations

import json
import random
import sys
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import battle_analyst_v9 as battle
import battle_unfinity_sticker_support as stickers


RULES = json.loads((SCRIPT_DIR / "reviewed_battle_card_rules.json").read_text(encoding="utf-8"))
REGISTRY = json.loads((SCRIPT_DIR / "unfinity_sticker_card_registry.json").read_text(encoding="utf-8"))


def rule(name: str) -> dict:
    return json.loads(json.dumps(RULES[name]["effect_json"]))


def permanent_from_rule(name: str, controller, opponents, turn=3) -> dict:
    effect = rule(name)
    permanent = battle.prepare_entering_permanent(
        battle.enrich_card({"name": name, **effect}),
        controller=controller,
        all_players=[controller, *opponents],
        turn=turn,
    )
    controller.battlefield.append(permanent)
    return permanent


class UnfinityStickerRuntimeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.events: list[tuple[str, dict]] = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: self.events.append((event, data))
        self.player = battle.Player("Player", None, [])
        self.opponent = battle.Player("Opponent", None, [])
        battle.bind_table_context([self.player, self.opponent])

    def tearDown(self) -> None:
        battle.REPLAY_EVENT_HANDLER = None

    def test_registry_closes_exact_45_card_scope_with_stable_keys(self) -> None:
        self.assertEqual(REGISTRY["card_count"], 45)
        self.assertEqual(len(REGISTRY["cards"]), 45)
        self.assertEqual(REGISTRY["card_count"], len(REGISTRY["cards"]))
        for name, entry in REGISTRY["cards"].items():
            self.assertGreater(len(entry["families"]), 1, name)
            self.assertTrue(entry["logical_rule_key"].startswith("battle_rule_v1:"), name)
            self.assertEqual(len(entry["oracle_hash"]), 32, name)
            self.assertTrue(rule(name)["unfinity_sticker_runtime"], name)

    def test_constructed_state_selects_three_unique_sheets_and_pays_ticket_cost(self) -> None:
        state = stickers.ensure_sticker_state(self.player, random.Random(7))
        self.assertEqual(state, {"sheet_count": 10, "active_sheet_count": 3})
        self.assertEqual(len({sheet["name"] for sheet in self.player.active_sticker_sheets}), 3)
        target = {"name": "Target", "type_line": "Creature", "power": 1, "toughness": 1}
        self.player.tickets = 5
        placed = stickers.place_sticker(self.player, target, kind="power_toughness")
        self.assertIsNotNone(placed)
        self.assertEqual(self.player.tickets, 5 - placed["ticket_cost"])
        self.assertEqual(target["power"], placed["power"])
        self.assertEqual(target["toughness"], placed["toughness"])

    def test_ability_sticker_selection_never_promotes_annotation_only_text(self) -> None:
        for seed in range(20):
            player = battle.Player(f"Sticker Player {seed}", None, [])
            stickers.ensure_sticker_state(player, random.Random(seed))
            selected = stickers.choose_sticker(
                player,
                kind="ability",
                max_ticket_cost=5,
                without_paying=True,
            )
            if selected is None:
                continue
            self.assertTrue(selected.get("runtime_supported"), seed)
            self.assertTrue(selected.get("keywords"), seed)

    def test_aerialephant_etb_gets_ticket_and_places_free_sticker(self) -> None:
        permanent = permanent_from_rule("Aerialephant", self.player, [self.opponent])
        battle.resolve_generic_permanent_etb(
            self.player,
            [self.opponent],
            permanent,
            rule("Aerialephant"),
            turn=3,
            rng=random.Random(3),
            all_players=[self.player, self.opponent],
        )
        self.assertEqual(self.player.tickets, 1)
        self.assertTrue(any(stickers.is_stickered(card) for card in self.player.battlefield))
        self.assertTrue(any(event == "ticket_counters_changed" for event, _ in self.events))
        self.assertTrue(any(event == "sticker_placed" for event, _ in self.events))

    def test_art_sticker_dispatches_airbrusher_and_wee_champion_payoffs(self) -> None:
        airbrusher = permanent_from_rule("Goblin Airbrusher", self.player, [self.opponent])
        champion = permanent_from_rule("Wee Champion", self.player, [self.opponent])
        target = {"name": "Sticker Target", "type_line": "Creature", "power": 2, "toughness": 2}
        self.player.battlefield.append(target)
        placement = battle.place_unfinity_sticker(
            self.player,
            [self.opponent],
            airbrusher,
            target=target,
            kind="art",
            turn=4,
            rng=random.Random(4),
        )
        self.assertIsNotNone(placement)
        self.assertEqual(self.player.treasures, 2)
        self.assertEqual(champion.get("plus_one_counters"), 1)

    def test_stickered_permanent_enables_all_conditional_keyword_family_members(self) -> None:
        names_and_keywords = {
            "Big Winner": "trample",
            "Croakid Amphibonaut": "flying",
            "Grabby Tabby": "vigilance",
            "Sanguine Sipper": "lifelink",
            "Scared Stiff": "menace",
        }
        permanents = {
            name: permanent_from_rule(name, self.player, [self.opponent])
            for name in names_and_keywords
        }
        target = {"name": "Sticker Target", "type_line": "Artifact"}
        self.player.battlefield.append(target)
        battle.place_unfinity_sticker(
            self.player,
            [self.opponent],
            target,
            target=target,
            kind="art",
            turn=5,
            rng=random.Random(5),
        )
        for name, keyword in names_and_keywords.items():
            self.assertTrue(permanents[name].get(keyword), name)

    def test_name_sticker_metric_etb_applies_mana_life_and_counters(self) -> None:
        for name, field in (
            ("________ Goblin", "red"),
            ("_____ Bird Gets the Worm", "life"),
            ("_____-o-saurus", "plus_one_counters"),
        ):
            player = battle.Player(name, None, [])
            opponent = battle.Player(f"{name} opponent", None, [])
            battle.bind_table_context([player, opponent])
            permanent = permanent_from_rule(name, player, [opponent])
            before_life = player.life
            battle.resolve_generic_permanent_etb(
                player,
                [opponent],
                permanent,
                rule(name),
                turn=3,
                rng=random.Random(11),
                all_players=[player, opponent],
            )
            if field == "red":
                self.assertGreater(player.mana_pool.red, 0)
            elif field == "life":
                self.assertGreater(player.life, before_life)
            else:
                self.assertGreater(permanent.get("plus_one_counters", 0), 0)

    def test_command_performance_selects_ticket_and_sticker_modes(self) -> None:
        target = {"name": "Command Target", "type_line": "Artifact"}
        self.player.battlefield.append(target)
        card = {"name": "Command Performance", **rule("Command Performance")}
        battle.apply_effect_immediate(
            self.player,
            [self.opponent],
            card,
            turn=4,
            rng=random.Random(4),
            effect_data_override=rule("Command Performance"),
            phase="precombat_main",
        )
        self.assertEqual(self.player.tickets, 2)
        self.assertTrue(stickers.is_stickered(target))
        self.assertIn(card, self.player.graveyard)

    def test_bioluminary_combat_damage_gets_tickets_and_stickers(self) -> None:
        source = permanent_from_rule("Bioluminary", self.player, [self.opponent])
        battle.process_unfinity_combat_damage_triggers(
            self.player,
            [self.opponent],
            [source],
            turn=5,
            rng=random.Random(5),
        )
        self.assertEqual(self.player.tickets, 2)
        self.assertTrue(
            any(
                event == "ticket_counters_changed" and payload.get("ticket_delta") == 2
                for event, payload in self.events
            )
        )
        self.assertTrue(any(stickers.is_stickered(card) for card in self.player.battlefield))

    def test_prize_wall_activated_family_places_sticker_when_mana_is_available(self) -> None:
        wall = permanent_from_rule("Prize Wall", self.player, [self.opponent])
        wall["summoning_sick"] = False
        self.player.mana_pool.wildcard = 5
        activated = battle.activate_unfinity_sticker_abilities(
            self.player,
            [self.opponent],
            [self.player, self.opponent],
            turn=6,
            rng=random.Random(6),
        )
        self.assertEqual(activated, 1)
        self.assertTrue(wall["tapped"])
        self.assertTrue(any(stickers.is_stickered(card) for card in self.player.battlefield))

    def test_lineprancers_etb_and_activation_force_the_selected_block(self) -> None:
        attacker = {
            "name": "Stickered Attacker",
            "type_line": "Creature",
            "power": 4,
            "toughness": 4,
        }
        blocker = {
            "name": "Forced Blocker",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        self.player.battlefield.append(attacker)
        self.opponent.battlefield.append(blocker)
        lineprancers = permanent_from_rule("Lineprancers", self.player, [self.opponent])
        battle.resolve_generic_permanent_etb(
            self.player,
            [self.opponent],
            lineprancers,
            rule("Lineprancers"),
            turn=5,
            rng=random.Random(5),
            all_players=[self.player, self.opponent],
        )
        self.assertEqual(self.player.tickets, 0)
        self.assertTrue(
            any(
                event == "ticket_counters_changed" and payload.get("ticket_delta") == 2
                for event, payload in self.events
            )
        )
        self.assertTrue(stickers.has_sticker_kind(attacker, "power_toughness"))
        self.player.mana_pool.wildcard = 4
        self.assertEqual(
            battle.activate_unfinity_sticker_abilities(
                self.player,
                [self.opponent],
                [self.player, self.opponent],
                turn=5,
                rng=random.Random(5),
            ),
            1,
        )
        assignments = battle.declare_blockers_step(
            self.opponent,
            [attacker],
            turn=5,
            rng=random.Random(99),
        )
        self.assertEqual(assignments, [(attacker, [blocker])])

    def test_pin_collection_applies_and_removes_equipment_and_ability_sticker_state(self) -> None:
        target = {
            "name": "Equipped Target",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        self.player.battlefield.append(target)
        effect = rule("Pin Collection")
        battle.apply_equipment_static_attachment(
            self.player,
            {"name": "Pin Collection", "x_value": 3},
            effect,
            turn=4,
            opponents=[self.opponent],
            rng=random.Random(4),
        )
        equipment = next(
            card for card in self.player.battlefield if card.get("name") == "Pin Collection"
        )
        self.assertTrue(stickers.has_sticker_kind(equipment, "ability"))
        self.assertEqual((target["power"], target["toughness"]), (3, 3))
        self.assertTrue(target.get("inherited_ability_sticker_texts"))
        inherited_sticker = stickers.stickers_on(equipment, "ability")[0]
        self.assertTrue(
            all(target.get(keyword) for keyword in inherited_sticker.get("keywords") or [])
        )
        destination = battle.move_permanent_from_battlefield(
            self.player,
            equipment,
            reason="destroy",
            all_players=[self.player, self.opponent],
        )
        self.assertEqual(destination, "graveyard")
        self.assertEqual((target["power"], target["toughness"]), (2, 2))
        self.assertFalse(target.get("inherited_ability_sticker_texts"))

    def test_last_voyage_static_bonus_and_leave_trigger_sacrifice_returned_creature(self) -> None:
        returned_card = {
            "name": "Return Target",
            "type_line": "Creature",
            "power": 2,
            "toughness": 2,
        }
        self.player.graveyard.append(returned_card)
        aura = permanent_from_rule("Last Voyage of the _____", self.player, [self.opponent])
        battle.resolve_generic_permanent_etb(
            self.player,
            [self.opponent],
            aura,
            rule("Last Voyage of the _____"),
            turn=4,
            rng=random.Random(4),
            all_players=[self.player, self.opponent],
        )
        returned = aura["attached_to_object"]
        self.assertIn(returned, self.player.battlefield)
        self.assertGreater(returned["power"], 2)
        destination = battle.move_permanent_from_battlefield(
            self.player,
            aura,
            reason="destroy",
            all_players=[self.player, self.opponent],
        )
        self.assertEqual(destination, "graveyard")
        self.assertNotIn(returned, self.player.battlefield)
        self.assertIn(returned, self.player.graveyard)

    def test_scampire_reanimated_stickered_creature_is_exiled_at_end_step(self) -> None:
        graveyard_creature = {
            "name": "Scampire Target",
            "type_line": "Creature",
            "power": 3,
            "toughness": 3,
        }
        self.player.graveyard.append(graveyard_creature)
        scampire = permanent_from_rule("Scampire", self.player, [self.opponent])
        battle.resolve_generic_permanent_etb(
            self.player,
            [self.opponent],
            scampire,
            rule("Scampire"),
            turn=6,
            rng=random.Random(6),
            all_players=[self.player, self.opponent],
        )
        self.assertTrue(stickers.is_stickered(graveyard_creature))
        self.player.mana_pool.wildcard = 4
        battle.activate_unfinity_sticker_abilities(
            self.player,
            [self.opponent],
            [self.player, self.opponent],
            turn=6,
            rng=random.Random(6),
        )
        returned = next(
            card for card in self.player.battlefield if card.get("name") == "Scampire Target"
        )
        self.assertTrue(returned.get("exile_at_end_step"))
        battle.process_end_step_token_sacrifices(self.player, turn=6)
        self.assertNotIn(returned, self.player.battlefield)
        self.assertIn(returned, self.player.exile)

    def test_robo_pinata_dies_uses_sticker_choice_and_hidden_zone_clears_stickers(self) -> None:
        target = {"name": "Persistent Target", "type_line": "Creature", "power": 2, "toughness": 2}
        robo = permanent_from_rule("Robo-Piñata", self.player, [self.opponent])
        self.player.battlefield.append(target)
        destination = battle.move_creature_from_battlefield(
            self.player,
            robo,
            reason="destroy",
            all_players=[self.player, self.opponent],
        )
        self.assertEqual(destination, "graveyard")
        self.assertTrue(stickers.is_stickered(target))
        hidden_destination = battle.move_permanent_from_battlefield_to_hand(
            self.player,
            target,
            reason="bounce",
            turn=7,
        )
        self.assertEqual(hidden_destination, "hand")
        self.assertFalse(stickers.is_stickered(target))
        self.assertTrue(
            any(event == "stickers_removed_in_hidden_zone" for event, _ in self.events)
        )

    def test_done_for_the_day_end_step_gets_resource_and_sticker_with_all_subtypes(self) -> None:
        source = permanent_from_rule("Done for the Day", self.player, [self.opponent])
        self.player.battlefield.extend(
            [
                {"name": "Employee", "type_line": "Creature - Employee", "power": 1, "toughness": 1},
                {"name": "Performer", "type_line": "Creature - Performer", "power": 1, "toughness": 1},
                {"name": "Robot", "type_line": "Artifact Creature - Robot", "power": 1, "toughness": 1},
            ]
        )
        resolved = battle.process_unfinity_end_step(
            self.player,
            [self.opponent],
            [self.player, self.opponent],
            turn=8,
            rng=random.Random(8),
        )
        self.assertEqual(resolved, 1)
        self.assertEqual(self.player.tickets, 1)
        self.assertTrue(any(stickers.is_stickered(card) for card in self.player.battlefield))
        self.assertIn(source, self.player.battlefield)


if __name__ == "__main__":
    unittest.main()
