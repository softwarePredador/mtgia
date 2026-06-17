#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from unittest import mock
from pathlib import Path

import battle_rule_registry

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sync_battle_card_rules_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_rules = load_module()


class SyncBattleCardRulesManualPreserveTests(unittest.TestCase):
    def test_manual_rows_are_empty_after_canonicalization(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
        )
        self.assertEqual(sum(1 for row in rows if row["source"] == "manual"), 0)
        self.assertGreaterEqual(sum(1 for row in rows if row["source"] == "curated"), 1)

    def test_runtime_waiver_is_promoted_into_manual_rows_when_injected(self) -> None:
        injected_rule = {
            "effect": "ramp_permanent",
            "mana_produced": 1,
            "produces": "WUBRGC",
            "requires_legendary_creature_or_planeswalker_for_mana": True,
        }
        with mock.patch.object(sync_rules.battle, "MANUAL_RULE_RUNTIME_WAIVERS", {"Mox Amber"}):
            with mock.patch.object(
                sync_rules.battle,
                "HANDCRAFTED_KNOWN_CARD_RULES",
                {"Mox Amber": injected_rule},
            ):
                rows = sync_rules.build_rows(
                    include_generated=False,
                    sqlite_db=str(sync_rules.DEFAULT_DB),
                )
        manual_rows = [row for row in rows if row["source"] == "manual"]
        self.assertEqual(len(manual_rows), 1)
        self.assertEqual(manual_rows[0]["card_name"], "Mox Amber")
        self.assertEqual(manual_rows[0]["review_status"], "verified")
        self.assertEqual(manual_rows[0]["effect_json"], injected_rule)

    def test_sqlite_registry_preserves_multiple_logical_rules_for_same_name(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                first_changed = sync_rules.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "draw_cards", "amount": 2},
                    source="curated",
                    confidence=0.9,
                    review_status="verified",
                )
                second_changed = sync_rules.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "remove_creature", "target": "creature"},
                    source="curated",
                    confidence=0.9,
                    review_status="verified",
                )
                rows = conn.execute(
                    """
                    SELECT normalized_name, logical_rule_key, effect_json
                    FROM battle_card_rules
                    WHERE normalized_name = 'modal test card'
                    ORDER BY logical_rule_key
                    """
                ).fetchall()

            rules = battle_rule_registry.load_active_battle_card_rules(sqlite_db)

        self.assertTrue(first_changed)
        self.assertTrue(second_changed)
        self.assertEqual(len(rows), 2)
        self.assertEqual(len({row[1] for row in rows}), 2)
        self.assertIn("modal test card", rules)
        self.assertIn(
            rules["modal test card"]["effect_json"]["effect"],
            {"draw_cards", "remove_creature"},
        )


if __name__ == "__main__":
    unittest.main()
