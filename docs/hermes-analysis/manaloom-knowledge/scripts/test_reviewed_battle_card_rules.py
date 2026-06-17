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

        self.assertIn("Ashnod's Altar", by_name)
        self.assertIn("Angel's Grace", by_name)
        self.assertIn("Chromatic Star", by_name)
        self.assertIn("Dismember", by_name)
        self.assertIn("Incubation Druid", by_name)
        self.assertIn("Natural Order", by_name)
        self.assertIn("Worldfire", by_name)
        self.assertEqual(by_name["Ashnod's Altar"]["source"], "curated")
        self.assertEqual(by_name["Ashnod's Altar"]["review_status"], "active")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Ashnod's Altar"]["effect_json"]["activated_mana_ability"])
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["activation_cost"], "sacrifice_creature")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["mana_produced"], 2)
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
        self.assertEqual(by_name["Incubation Druid"]["source"], "curated")
        self.assertEqual(by_name["Incubation Druid"]["review_status"], "active")
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Incubation Druid"]["effect_json"]["is_mana_source"])
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["mana_produced"], 1)
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["battle_model_scope"], "mana_dork_without_adapt_v1")
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
        self.assertEqual(by_name["Worldfire"]["source"], "curated")
        self.assertEqual(by_name["Worldfire"]["review_status"], "verified")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["effect"], "worldfire_reset")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["set_life_total"], 1)

    def test_sync_build_rows_includes_reviewed_rules_without_generated_layer(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
            reviewed_rules_path=DEFAULT_REVIEWED_RULES_PATH,
        )
        by_name = {row["card_name"]: row for row in rows}

        self.assertEqual(by_name["Ashnod's Altar"]["source"], "curated")
        self.assertEqual(by_name["Ashnod's Altar"]["review_status"], "active")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Ashnod's Altar"]["effect_json"]["activated_mana_ability"])
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
        self.assertEqual(by_name["Incubation Druid"]["source"], "curated")
        self.assertEqual(by_name["Incubation Druid"]["review_status"], "active")
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Incubation Druid"]["effect_json"]["is_mana_source"])
        self.assertEqual(by_name["Natural Order"]["source"], "curated")
        self.assertEqual(by_name["Natural Order"]["effect_json"]["effect"], "tutor")
        self.assertEqual(
            by_name["Natural Order"]["effect_json"]["target"],
            "green_creature_to_battlefield",
        )
        self.assertEqual(by_name["Worldfire"]["source"], "curated")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["effect"], "worldfire_reset")

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
                ashnod = battle.get_card_effect({"name": "Ashnod's Altar", "type_line": "Artifact"})
                incubation = battle.get_card_effect(
                    {"name": "Incubation Druid", "type_line": "Creature — Elf Druid"}
                )
                dismember = battle.get_card_effect(
                    {"name": "Dismember", "type_line": "Instant", "mana_cost": "{1}{B/P}{B/P}"}
                )
                worldfire = battle.get_card_effect({"name": "Worldfire", "type_line": "Sorcery"})
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
        self.assertEqual(ashnod["_rule_source"], "curated")
        self.assertEqual(ashnod["_rule_review_status"], "active")
        self.assertEqual(ashnod["effect"], "passive")
        self.assertTrue(ashnod["activated_mana_ability"])
        self.assertEqual(ashnod["activation_cost"], "sacrifice_creature")
        self.assertEqual(ashnod["mana_produced"], 2)
        self.assertEqual(incubation["_rule_source"], "curated")
        self.assertEqual(incubation["_rule_review_status"], "active")
        self.assertEqual(incubation["effect"], "creature")
        self.assertTrue(incubation["is_mana_source"])
        self.assertEqual(incubation["mana_produced"], 1)
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
        self.assertEqual(worldfire["_rule_source"], "curated")
        self.assertEqual(worldfire["_rule_review_status"], "verified")
        self.assertEqual(worldfire["effect"], "worldfire_reset")
        self.assertEqual(worldfire["battle_model_scope"], "worldfire_total_reset_v1")

    def test_ashnods_altar_resolves_without_free_mana_until_activation_executor_exists(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                spell = {"name": "Ashnod's Altar", "type_line": "Artifact", "cmc": 3}
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(1))
                player.refresh_mana_sources(turn=1)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        self.assertEqual(player.battlefield[0]["name"], "Ashnod's Altar")
        self.assertEqual(player.battlefield[0]["effect"], "passive")
        self.assertEqual(player.available_mana(), 0)

    def test_incubation_druid_is_active_mana_dork_with_summoning_sickness(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                spell = {
                    "name": "Incubation Druid",
                    "type_line": "Creature — Elf Druid",
                    "cmc": 2,
                }
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(1))
                player.refresh_mana_sources(turn=1)
                same_turn_mana = player.available_mana()
                permanent = player.battlefield[0]
                permanent["summoning_sick"] = False
                player.refresh_mana_sources(turn=2)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        self.assertTrue(player.battlefield[0]["is_mana_source"])
        self.assertTrue(player.battlefield[0]["mana_produced"], 1)
        self.assertEqual(same_turn_mana, 0)
        self.assertEqual(player.available_mana(), 1)

    def test_worldfire_uses_reset_rule_and_preserves_commander_replacement(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                rng = __import__("random").Random(7)
                commander = {
                    "name": "Lorehold, the Historian",
                    "type_line": "Legendary Creature — Elder Dragon",
                    "cmc": 4,
                    "power": 2,
                    "toughness": 5,
                    "is_commander": True,
                    "commander_replacement_choice": "command_zone",
                }
                player = battle.Player("Caster", commander, [])
                player.command_zone = []
                player.battlefield = [
                    commander,
                    {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1, "effect": "ramp_permanent"},
                    {"name": "Treasure Token", "type_line": "Artifact Token", "tag": "token", "effect": "creature", "power": 0, "toughness": 0},
                ]
                player.hand = [{"name": "Boros Charm", "type_line": "Instant", "cmc": 2}]
                player.graveyard = [{"name": "Faithless Looting", "type_line": "Sorcery", "cmc": 1}]
                player.treasures = 2
                player.life = 23

                opponent = battle.Player("Opponent", None, [])
                opponent.battlefield = [
                    {"name": "Bear", "type_line": "Creature", "effect": "creature", "power": 2, "toughness": 2},
                ]
                opponent.hand = [{"name": "Counterspell", "type_line": "Instant", "cmc": 2}]
                opponent.graveyard = [{"name": "Ponder", "type_line": "Sorcery", "cmc": 1}]
                opponent.life = 11

                spell = {"name": "Worldfire", "type_line": "Sorcery", "cmc": 9}
                battle.apply_effect_immediate(player, [opponent], spell, turn=5, rng=rng)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(player.life, 1)
        self.assertEqual(opponent.life, 1)
        self.assertEqual(player.battlefield, [])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual(player.hand, [])
        self.assertEqual(opponent.hand, [])
        self.assertEqual(player.treasures, 0)
        self.assertEqual(player.command_zone[0]["name"], "Lorehold, the Historian")
        self.assertTrue(any(card.get("name") == "Sol Ring" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Boros Charm" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Faithless Looting" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Worldfire" for card in player.graveyard))


if __name__ == "__main__":
    unittest.main()
