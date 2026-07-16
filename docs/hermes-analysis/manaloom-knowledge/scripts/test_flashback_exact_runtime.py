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
        "battle_flashback_exact_runtime_test",
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


class FlashbackExactRuntimeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.events = []
        self.old_handler = battle.REPLAY_EVENT_HANDLER
        self.old_turn = battle.CURRENT_REPLAY_TURN
        battle.REPLAY_EVENT_HANDLER = lambda event, data: self.events.append((event, data))
        battle.CURRENT_REPLAY_TURN = 7

    def tearDown(self) -> None:
        battle.REPLAY_EVENT_HANDLER = self.old_handler
        battle.CURRENT_REPLAY_TURN = self.old_turn

    @staticmethod
    def flashback_card():
        return card(
            "Flashback",
            "Instant",
            cmc=1,
            mana_cost="{R}",
            oracle_text=(
                "Target instant or sorcery card in your graveyard gains flashback "
                "until end of turn. The flashback cost is equal to its mana cost. "
                "(You may cast that card from your graveyard for its flashback cost. "
                "Then exile it.)"
            ),
        )

    @classmethod
    def flashback_effect(cls):
        return battle.normalize_effect_by_oracle(
            cls.flashback_card(),
            {
                "effect": "recursion",
                "count": 1,
                "target": "instant_or_sorcery",
                "_rule_source": "curated",
                "_rule_review_status": "verified",
                "_rule_execution_status": "auto",
                "_rule_confidence": 1.0,
                "_rule_version": 1,
                "_rule_logical_key": "battle_rule_v1:test_flashback_exact",
                "_rule_oracle_hash": "test-flashback-oracle-hash",
            },
        )

    @staticmethod
    def graveyard_draw(name="Graveyard Insight", *, type_line="Sorcery", mana_cost="{2}{W}"):
        return card(
            name,
            type_line,
            cmc=3,
            mana_cost=mana_cost,
            effect="draw",
            count=1,
        )

    def _resolve_flashback_source(self, player, target, *, turn=7):
        source = self.flashback_card()
        effect, declared = battle.prepare_declared_removal_targets(
            player,
            [],
            source,
            self.flashback_effect(),
        )
        self.assertEqual(len(declared), 1)
        self.assertEqual(declared[0]["target"], target["name"])
        self.assertEqual(declared[0]["target_zone"], "graveyard")
        battle.apply_effect_immediate(
            player,
            [],
            source,
            turn,
            random.Random(701),
            effect_data_override=effect,
            phase="precombat_main",
        )
        return source, effect

    def test_oracle_normalization_routes_named_card_away_from_generic_recursion(self) -> None:
        effect = self.flashback_effect()

        self.assertEqual(effect["effect"], "graveyard_flashback_grant")
        self.assertEqual(
            effect["battle_model_scope"],
            battle.FLASHBACK_TARGET_GRANT_EXACT_SCOPE,
        )
        self.assertEqual(effect["target_count"], 1)
        self.assertEqual(effect["target_zone"], "graveyard")
        self.assertEqual(effect["flashback_cost_source"], "target_printed_mana_cost")
        self.assertTrue(effect["targeted_flashback_grant"])

    def test_resolution_grants_only_declared_legal_target_at_printed_cost(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        target = self.graveyard_draw()
        creature = card(
            "Graveyard Creature",
            "Creature — Spirit",
            cmc=5,
            mana_cost="{4}{W}",
            effect="creature",
        )
        player.graveyard = [target, creature]

        source, _effect = self._resolve_flashback_source(player, target)

        self.assertEqual(target["flashback_cost"], "{2}{W}")
        self.assertEqual(target["_flashback_permission_kind"], "target_grant_exact")
        self.assertEqual(target["_flashback_permission_turn"], 7)
        self.assertNotIn("flashback_cost", creature)
        self.assertIn(target, player.graveyard)
        self.assertIn(source, player.graveyard)
        self.assertEqual(player.hand, [])
        grant = next(
            data
            for event, data in self.events
            if event == "flashback_target_permission_granted"
        )
        self.assertEqual(grant["target"], target["name"])
        self.assertEqual(grant["flashback_cost"], "{2}{W}")
        self.assertTrue(grant["target_legal"])
        self.assertEqual(grant["rule_logical_key"], "battle_rule_v1:test_flashback_exact")
        self.assertEqual(grant["rule_oracle_hash"], "test-flashback-oracle-hash")

    def test_target_moved_before_resolution_is_illegal_and_gets_no_permission(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        target = self.graveyard_draw()
        player.graveyard = [target]
        source = self.flashback_card()
        effect, declared = battle.prepare_declared_removal_targets(
            player,
            [],
            source,
            self.flashback_effect(),
        )
        self.assertEqual(len(declared), 1)
        player.graveyard.remove(target)
        player.hand.append(target)

        battle.apply_effect_immediate(
            player,
            [],
            source,
            7,
            random.Random(702),
            effect_data_override=effect,
            phase="precombat_main",
        )

        self.assertNotIn("flashback_cost", target)
        denied = next(
            data
            for event, data in self.events
            if event == "flashback_target_permission_not_granted"
        )
        self.assertFalse(denied["target_legal"])
        self.assertEqual(denied["result"], "target_illegal_on_resolution")
        self.assertEqual(denied["rule_logical_key"], "battle_rule_v1:test_flashback_exact")

    def test_granted_cast_uses_normal_payment_pipeline_and_exiles_after_resolution(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        target = self.graveyard_draw()
        player.graveyard = [target]
        player.library = [card("Drawn Card", "Sorcery")]
        self._resolve_flashback_source(player, target)
        player.mana_pool.add_generic(2)
        player.mana_pool.add("white", 1)
        stack = battle.Stack()

        casted = battle.cast_flashback_spell_from_graveyard(
            player,
            target,
            [],
            [player],
            7,
            "precombat_main",
            stack,
            random.Random(703),
        )

        self.assertTrue(casted)
        self.assertEqual(player.available_mana(), 0)
        self.assertNotIn(target, player.graveyard)
        cast_event = next(data for event, data in self.events if event == "flashback_cast")
        self.assertEqual(cast_event["flashback_cost"], "{2}{W}")
        self.assertEqual(cast_event["source_zone"], "graveyard")
        self.assertEqual(cast_event["alternative_cost_kind"], "flashback")
        self.assertEqual(cast_event["flashback_permission_kind"], "target_grant_exact")
        self.assertEqual(cast_event["rule_logical_key"], "battle_rule_v1:test_flashback_exact")

        item = stack.resolve_top()
        self.assertIsNotNone(item)
        battle.apply_effect_immediate(
            player,
            [],
            item.card,
            7,
            random.Random(704),
            effect_data_override=item.effect_data,
            stack=stack,
            phase="precombat_main",
        )

        self.assertEqual([entry["name"] for entry in player.exile], [target["name"]])
        exile_event = next(data for event, data in self.events if event == "flashback_exiled")
        self.assertEqual(exile_event["stack_outcome"], "resolved")
        self.assertEqual(exile_event["destination"], "exile")
        self.assertEqual(exile_event["rule_logical_key"], "battle_rule_v1:test_flashback_exact")
        self.assertTrue(
            any(
                event == "spell_cast" and data.get("cast_via_flashback") is True
                for event, data in self.events
            )
        )

    def test_granted_instant_exiles_when_countered_with_permission_provenance(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        target = self.graveyard_draw(
            "Graveyard Instant",
            type_line="Instant",
            mana_cost="{R}",
        )
        player.graveyard = [target]
        self._resolve_flashback_source(player, target)
        player.mana_pool.add("red", 1)
        stack = battle.Stack()

        self.assertTrue(
            battle.cast_flashback_spell_from_graveyard(
                player,
                target,
                [],
                [player],
                7,
                "end_step",
                stack,
                random.Random(705),
            )
        )
        stack.items[-1].countered = True
        self.assertIsNone(stack.resolve_top())

        self.assertEqual([entry["name"] for entry in player.exile], [target["name"]])
        exile_event = next(
            data
            for event, data in self.events
            if event == "flashback_exiled" and data.get("stack_outcome") == "countered"
        )
        self.assertEqual(exile_event["replacement_reason"], "flashback_countered")
        self.assertEqual(exile_event["rule_logical_key"], "battle_rule_v1:test_flashback_exact")
        self.assertTrue(
            any(event == "countered_spell_moved_to_exile" for event, _ in self.events)
        )

    def test_sorcery_timing_and_unused_permission_expiration_are_enforced(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        target = self.graveyard_draw()
        player.graveyard = [target]
        self._resolve_flashback_source(player, target)
        player.mana_pool.add_generic(2)
        player.mana_pool.add("white", 1)

        self.assertFalse(
            battle.cast_flashback_spell_from_graveyard(
                player,
                target,
                [],
                [player],
                7,
                "end_step",
                battle.Stack(),
                random.Random(706),
            )
        )
        battle.clear_until_eot(player)

        self.assertNotIn("flashback_cost", target)
        self.assertNotIn("_flashback_permission_kind", target)
        expired = next(
            data
            for event, data in self.events
            if event == "flashback_permission_expired"
        )
        self.assertEqual(expired["target"], target["name"])
        self.assertEqual(expired["flashback_cost"], "{2}{W}")
        self.assertEqual(expired["result"], "expired_at_end_of_turn")
        self.assertEqual(expired["rule_logical_key"], "battle_rule_v1:test_flashback_exact")
        self.assertFalse(
            battle.cast_flashback_spell_from_graveyard(
                player,
                target,
                [],
                [player],
                8,
                "precombat_main",
                battle.Stack(),
                random.Random(707),
            )
        )

    def test_past_in_flames_global_grant_remains_separate(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        instant = self.graveyard_draw("Instant One", type_line="Instant", mana_cost="{1}")
        sorcery = self.graveyard_draw("Sorcery Two", mana_cost="{3}{R}")
        player.graveyard = [instant, sorcery]
        source = card("Past in Flames", "Sorcery")
        effect = {
            "effect": "graveyard_flashback_grant",
            "battle_model_scope": "past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1",
            "_rule_source": "curated",
            "_rule_review_status": "verified",
            "_rule_execution_status": "auto",
            "_rule_logical_key": "battle_rule_v1:test_past_in_flames",
        }

        battle.grant_graveyard_flashback_until_eot(player, source, effect, 7)

        self.assertEqual(instant["flashback_cost"], "{1}")
        self.assertEqual(sorcery["flashback_cost"], "{3}{R}")
        self.assertEqual(instant["_flashback_permission_kind"], "global_until_eot")
        self.assertTrue(
            any(event == "graveyard_flashback_granted" for event, _ in self.events)
        )


if __name__ == "__main__":
    unittest.main()
