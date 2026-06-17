#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

import battle_rule_registry
from reviewed_battle_card_rules import (
    DEFAULT_REVIEWED_RULES_PATH,
    load_reviewed_rule_rows,
)


SCRIPT_DIR = Path(__file__).resolve().parent
SYNC_MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules.py"
BATTLE_MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def _load_module(module_path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_rules = _load_module(SYNC_MODULE_PATH, "sync_battle_rules_reviewed_test")
battle = _load_module(BATTLE_MODULE_PATH, "battle_reviewed_rule_runtime_test")


class ReviewedBattleCardRulesTests(unittest.TestCase):
    def test_reviewed_rule_payload_contains_expected_cards(self) -> None:
        rows = load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH)
        by_name = {row["card_name"]: row for row in rows}

        self.assertIn("Angel's Grace", by_name)
        self.assertIn("Chromatic Star", by_name)
        self.assertIn("Dismember", by_name)
        self.assertIn("Natural Order", by_name)
        self.assertEqual(by_name["Angel's Grace"]["source"], "curated")
        self.assertEqual(by_name["Angel's Grace"]["review_status"], "verified")
        self.assertEqual(by_name["Angel's Grace"]["effect_json"]["effect"], "cannot_lose_turn")
        self.assertEqual(by_name["Chromatic Star"]["review_status"], "active")
        self.assertEqual(
            by_name["Chromatic Star"]["effect_json"]["effect"],
            "cantrip_mana_filter_artifact",
        )
        self.assertEqual(by_name["Dismember"]["source"], "curated")
        self.assertEqual(by_name["Dismember"]["review_status"], "verified")
        self.assertEqual(by_name["Dismember"]["effect_json"]["effect"], "remove_creature")
        self.assertEqual(by_name["Dismember"]["effect_json"]["target"], "creature")
        self.assertEqual(by_name["Dismember"]["effect_json"]["toughness_boost"], -5)
        self.assertTrue(by_name["Dismember"]["effect_json"]["uses_stat_modifier_removal"])
        self.assertEqual(by_name["Natural Order"]["source"], "curated")
        self.assertEqual(by_name["Natural Order"]["review_status"], "verified")
        self.assertEqual(by_name["Natural Order"]["effect_json"]["effect"], "tutor")
        self.assertEqual(
            by_name["Natural Order"]["effect_json"]["target"],
            "green_creature_to_battlefield",
        )
        self.assertTrue(
            by_name["Natural Order"]["effect_json"]["requires_sacrifice_green_creature"]
        )

    def test_sync_build_rows_includes_reviewed_rules_without_generated_layer(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
            reviewed_rules_path=DEFAULT_REVIEWED_RULES_PATH,
        )
        by_name = {row["card_name"]: row for row in rows}

        self.assertEqual(by_name["Angel's Grace"]["source"], "curated")
        self.assertEqual(by_name["Angel's Grace"]["effect_json"]["effect"], "cannot_lose_turn")
        self.assertEqual(by_name["Chromatic Star"]["source"], "curated")
        self.assertEqual(
            by_name["Chromatic Star"]["effect_json"]["effect"],
            "cantrip_mana_filter_artifact",
        )
        self.assertEqual(by_name["Dismember"]["source"], "curated")
        self.assertEqual(by_name["Dismember"]["effect_json"]["effect"], "remove_creature")
        self.assertTrue(by_name["Dismember"]["effect_json"]["uses_stat_modifier_removal"])
        self.assertEqual(by_name["Natural Order"]["source"], "curated")
        self.assertEqual(by_name["Natural Order"]["effect_json"]["effect"], "tutor")
        self.assertEqual(
            by_name["Natural Order"]["effect_json"]["target"],
            "green_creature_to_battlefield",
        )

    def test_runtime_prefers_reviewed_curated_rule_after_sync(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in sync_rules.build_rows(
                    include_generated=True,
                    sqlite_db=str(db_path),
                    reviewed_rules_path=DEFAULT_REVIEWED_RULES_PATH,
                ):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                grace = battle.get_card_effect({"name": "Angel's Grace", "type_line": "Instant"})
                star = battle.get_card_effect({"name": "Chromatic Star", "type_line": "Artifact"})
                natural_order = battle.get_card_effect(
                    {"name": "Natural Order", "type_line": "Sorcery"}
                )
                dismember = battle.get_card_effect(
                    {"name": "Dismember", "type_line": "Instant", "mana_cost": "{1}{B/P}{B/P}"}
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(grace["_rule_source"], "curated")
        self.assertEqual(grace["_rule_review_status"], "verified")
        self.assertEqual(grace["effect"], "cannot_lose_turn")
        self.assertEqual(star["_rule_source"], "curated")
        self.assertEqual(star["_rule_review_status"], "active")
        self.assertEqual(star["effect"], "cantrip_mana_filter_artifact")
        self.assertEqual(star["battle_model_scope"], "sacrifice_mana_filter_cantrip_v2")
        self.assertEqual(natural_order["_rule_source"], "curated")
        self.assertEqual(natural_order["_rule_review_status"], "verified")
        self.assertEqual(natural_order["effect"], "tutor")
        self.assertEqual(natural_order["target"], "green_creature_to_battlefield")
        self.assertTrue(natural_order["requires_sacrifice_green_creature"])
        self.assertEqual(dismember["_rule_source"], "curated")
        self.assertEqual(dismember["_rule_review_status"], "verified")
        self.assertEqual(dismember["effect"], "remove_creature")
        self.assertEqual(dismember["toughness_boost"], -5)
        self.assertTrue(dismember["uses_stat_modifier_removal"])


if __name__ == "__main__":
    unittest.main()
