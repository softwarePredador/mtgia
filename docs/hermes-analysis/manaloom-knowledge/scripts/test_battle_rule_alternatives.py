#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle_module():
    spec = importlib.util.spec_from_file_location(
        "battle_for_rule_alternatives_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module()


class BattleRuleAlternativesTests(unittest.TestCase):
    def test_runtime_effect_exposes_alternative_rules_for_multi_rule_card(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                battle.battle_rule_registry.ensure_battle_card_rules(conn)
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "draw_cards", "amount": 2},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "remove_creature", "target": "creature"},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                conn.commit()
            old_db = battle.DB
            try:
                battle.DB = str(sqlite_db)
                resolved = battle.get_card_effect(
                    {
                        "name": "Modal Test Card",
                        "type_line": "Instant",
                        "oracle_text": "",
                    }
                )
            finally:
                battle.DB = old_db

        alternatives = resolved.get("_rule_alternatives")
        self.assertEqual(resolved.get("_rule_source"), "curated")
        self.assertIsInstance(alternatives, list)
        self.assertEqual(len(alternatives), 2)
        self.assertEqual(
            {item["effect"] for item in alternatives},
            {"draw_cards", "remove_creature"},
        )
        self.assertEqual(
            battle.replay_rule_fields(resolved).get("rule_alternative_count"),
            2,
        )


if __name__ == "__main__":
    unittest.main()
