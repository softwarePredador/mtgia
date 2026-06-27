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
        "battle_lapse_lorehold_runtime_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module()


class LapseOfCertaintyLoreholdRuntimeTests(unittest.TestCase):
    def test_lapse_counters_first_approach_to_top_for_lorehold_miracle_window(self) -> None:
        events = []
        decisions = []
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                battle.battle_rule_registry.ensure_battle_card_rules(conn)
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Lapse of Certainty",
                    {
                        "effect": "counter",
                        "instant": True,
                        "target": "spell",
                        "countered_spell_to_top_library": True,
                        "counter_own_approach_to_top": True,
                        "battle_model_scope": "counter_spell_to_top_library_approach_combo_v1",
                    },
                    source="curated",
                    confidence=1.0,
                    review_status="active",
                    execution_status="auto",
                    deck_role_json={"category": "protection", "effect": "counter"},
                )
                conn.commit()

            old_db = battle.DB
            old_handler = battle.REPLAY_EVENT_HANDLER
            old_decision_handler = battle.DECISION_TRACE_HANDLER
            old_turn = battle.CURRENT_REPLAY_TURN
            try:
                battle.DB = str(sqlite_db)
                battle.CURRENT_REPLAY_TURN = 3
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.DECISION_TRACE_HANDLER = lambda data: decisions.append(data)

                rng = random.Random(11)
                active = battle.Player("Lorehold", None, [])
                opponent = battle.Player("Opponent", None, [])
                active.approach_count = 1
                active.mana_pool.add_generic(2)
                active.mana_pool.add("white", 1)
                lapse = {
                    "name": "Lapse of Certainty",
                    "type_line": "Instant",
                    "mana_cost": "{2}{W}",
                    "cmc": 3,
                }
                approach = {
                    "name": "Approach of the Second Sun",
                    "type_line": "Sorcery",
                    "mana_cost": "{6}{W}",
                    "cmc": 7,
                }
                approach_effect = {
                    "effect": "approach",
                    "_approach_cast_count_recorded": True,
                    "_approach_cast_count_after_recorded": 1,
                    "_cast_context": {"source_zone": "hand", "phase": "precombat_main"},
                }
                active.hand.append(lapse)
                stack = battle.Stack()
                stack.push(approach, active, approach_effect)

                self.assertTrue(
                    battle.priority_round(
                        active,
                        [active, opponent],
                        stack,
                        3,
                        rng,
                        phase="precombat_main",
                    )
                )
                self.assertTrue(stack.items[-1].countered)
                self.assertEqual(active.hand, [])
                self.assertEqual([card["name"] for card in active.graveyard], ["Lapse of Certainty"])

                battle.priority_round(
                    active,
                    [active, opponent],
                    stack,
                    3,
                    rng,
                    phase="precombat_main",
                )

                self.assertTrue(stack.empty())
                self.assertEqual(active.library[0]["name"], "Approach of the Second Sun")
                self.assertNotIn(approach, active.graveyard)
                self.assertTrue(
                    any(event == "countered_spell_moved_to_library_top" for event, _data in events)
                )
                self.assertTrue(
                    any(
                        data.get("actual_outcome") == "own_approach_countered_to_top"
                        for data in decisions
                    )
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.DECISION_TRACE_HANDLER = old_decision_handler
                battle.CURRENT_REPLAY_TURN = old_turn


if __name__ == "__main__":
    unittest.main()
