#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import random
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle_module():
    spec = importlib.util.spec_from_file_location(
        "battle_radiant_scrollwielder_runtime_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module()


class RadiantScrollwielderRuntimeTests(unittest.TestCase):
    def test_xmage_bolt_case_recasts_from_exile_lifelinks_and_exiles_again(self) -> None:
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                battle.battle_rule_registry.ensure_battle_card_rules(conn)
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Lightning Bolt",
                    {
                        "effect": "direct_damage",
                        "damage": 3,
                        "target": "player",
                        "instant": True,
                        "battle_model_scope": "test_lightning_bolt_direct_damage_v1",
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                    execution_status="auto",
                    deck_role_json={"category": "removal", "effect": "direct_damage"},
                )
                conn.commit()

            old_db = battle.DB
            old_handler = battle.REPLAY_EVENT_HANDLER
            old_turn = battle.CURRENT_REPLAY_TURN
            try:
                battle.DB = str(sqlite_db)
                battle.CURRENT_REPLAY_TURN = 1
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))

                rng = random.Random(7)
                active = battle.Player("playerA", None, [])
                opponent = battle.Player("playerB", None, [])
                active.life = 20
                opponent.life = 20
                radiant = {
                    "name": "Radiant Scrollwielder",
                    "type_line": "Creature - Dwarf Cleric",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 4,
                    "instant_sorcery_spells_you_control_have_lifelink": True,
                    "upkeep_exile_random_instant_sorcery_from_graveyard": True,
                    "battle_model_scope": (
                        "radiant_scrollwielder_spell_lifelink_random_graveyard_recast_v1"
                    ),
                    "_rule_logical_key": "curated:radiant_scrollwielder_test",
                }
                bolt = {
                    "name": "Lightning Bolt",
                    "type_line": "Instant",
                    "mana_cost": "{R}",
                    "cmc": 1,
                }
                active.battlefield.append(radiant)
                active.graveyard.append(bolt)

                exiled_count = battle.process_radiant_scrollwielder_upkeep_graveyard_recast(
                    active,
                    1,
                    rng,
                )
                self.assertEqual(exiled_count, 1)
                self.assertEqual(active.graveyard, [])
                self.assertEqual([card["name"] for card in active.exile], ["Lightning Bolt"])
                self.assertEqual(active.exile[0]["_radiant_scrollwielder_cast_available_until_turn"], 1)

                active.mana_pool.add("red", 1)
                stack = battle.Stack()
                self.assertTrue(
                    battle.cast_radiant_scrollwielder_card_from_exile(
                        active,
                        active.exile[0],
                        [opponent],
                        [active, opponent],
                        1,
                        "precombat_main",
                        stack,
                        rng,
                    )
                )
                self.assertTrue(active.exile == [])

                while not stack.empty():
                    battle.priority_round(active, [active, opponent], stack, 1, rng, phase="precombat_main")

                self.assertEqual(active.life, 23)
                self.assertEqual(opponent.life, 17)
                self.assertEqual([card["name"] for card in active.exile], ["Lightning Bolt"])
                self.assertEqual(active.graveyard, [])

                damage_events = [data for event, data in events if event == "damage_resolved"]
                self.assertEqual(len(damage_events), 1)
                self.assertEqual(damage_events[0]["life_gained"], 3)
                self.assertEqual(damage_events[0]["spell_lifelink_life_gained"], 3)
                self.assertEqual(
                    damage_events[0]["spell_lifelink_sources"][0]["card"],
                    "Radiant Scrollwielder",
                )
                self.assertTrue(
                    any(event == "replacement_exiled_on_resolution" for event, _data in events)
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.CURRENT_REPLAY_TURN = old_turn


if __name__ == "__main__":
    unittest.main()
