#!/usr/bin/env python3
"""Tests for Commander payoff source-lane expansion."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_payoff_source_lane_expander as expander


class GlobalCommanderPayoffSourceLaneExpanderTests(unittest.TestCase):
    def _db(self, root: Path, payoff_names: list[str]) -> Path:
        path = root / "knowledge.db"
        conn = sqlite3.connect(path)
        conn.execute("CREATE TABLE deck_cards (deck_id TEXT, card_name TEXT)")
        conn.execute("INSERT INTO deck_cards VALUES ('619', 'Rune-Scarred Demon')")
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              name TEXT,
              normalized_name TEXT,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              scryfall_id TEXT,
              card_id TEXT
            )
            """
        )
        conn.execute("CREATE TABLE card_legalities (card_name TEXT, format TEXT, status TEXT)")
        text_by_name = {
            "Balefire Dragon": "Flying. Whenever this creature deals combat damage to a player, it deals that much damage to each creature.",
            "Ancient Copper Dragon": "Flying. Whenever this creature deals combat damage to a player, create Treasure tokens.",
            "Old Gnawbone": "Flying. Whenever a creature deals combat damage to a player, create Treasure tokens.",
        }
        colors_by_name = {"Old Gnawbone": '["G"]'}
        for name in payoff_names:
            colors = colors_by_name.get(name, '["R"]')
            conn.execute(
                "INSERT INTO card_oracle_cache VALUES (?, ?, '', ?, ?, 'Creature - Dragon', ?, 6, '', ?)",
                (name, name.lower(), colors, colors, text_by_name[name], name.lower()),
            )
            conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal')", (name,))
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES ('Banned Demon', 'banned demon', '', '[\"B\"]', '[\"B\"]', 'Creature - Demon', 'Flying.', 6, '', 'banned')"
        )
        conn.execute("INSERT INTO card_legalities VALUES ('Banned Demon', 'commander', 'banned')")
        conn.commit()
        conn.close()
        return path

    def _repair_report(self, root: Path, db: Path, shortfall: int) -> Path:
        strategy = root / "strategy.json"
        strategy.write_text(json.dumps({"input_artifacts": {"base_db": str(db)}}), encoding="utf-8")
        repair = root / "repair.json"
        repair.write_text(
            json.dumps(
                {
                    "summary": {
                        "deck_id": "619",
                        "commander": "Kaalia of the Vast",
                        "commander_color_identity": ["W", "B", "R"],
                    },
                    "input_artifacts": {
                        "candidate_db": str(root / "missing_candidate.db"),
                        "strategy_matrix_report": str(strategy),
                    },
                    "repair_axis_pools": [
                        {
                            "repair_axis": "angels_demons_dragons_payoffs",
                            "shortfall_to_min": shortfall,
                            "top_add_candidates": [{"card_name": "Balefire Dragon"}],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return repair

    def _lorehold_db(self, root: Path) -> Path:
        path = root / "lorehold.db"
        conn = sqlite3.connect(path)
        conn.execute("CREATE TABLE deck_cards (deck_id TEXT, card_name TEXT)")
        conn.execute("INSERT INTO deck_cards VALUES ('609', 'Storm-Kiln Artist')")
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              name TEXT,
              normalized_name TEXT,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              scryfall_id TEXT,
              card_id TEXT
            )
            """
        )
        conn.execute("CREATE TABLE card_legalities (card_name TEXT, format TEXT, status TEXT)")
        rows = [
            (
                "Young Pyromancer",
                '["R"]',
                "Creature - Human Shaman",
                "Whenever you cast an instant or sorcery spell, create a 1/1 red Elemental creature token.",
                2,
            ),
            (
                "Double Vision",
                '["R"]',
                "Enchantment",
                "Whenever you cast your first instant or sorcery spell each turn, copy that spell. You may choose new targets for the copy.",
                5,
            ),
            (
                "Archmage Emeritus",
                '["U"]',
                "Creature - Human Wizard",
                "Magecraft - Whenever you cast or copy an instant or sorcery spell, draw a card.",
                4,
            ),
            (
                "Storm-Kiln Artist",
                '["R"]',
                "Creature - Dwarf Shaman",
                "Magecraft - Whenever you cast or copy an instant or sorcery spell, create a Treasure token.",
                4,
            ),
        ]
        for name, colors, type_line, oracle_text, cmc in rows:
            conn.execute(
                "INSERT INTO card_oracle_cache VALUES (?, ?, '', ?, ?, ?, ?, ?, '', ?)",
                (name, name.lower(), colors, colors, type_line, oracle_text, cmc, name.lower()),
            )
            conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal')", (name,))
        conn.commit()
        conn.close()
        return path

    def _lorehold_repair_report(self, root: Path, db: Path) -> Path:
        strategy = root / "lorehold_strategy.json"
        strategy.write_text(json.dumps({"input_artifacts": {"base_db": str(db)}}), encoding="utf-8")
        repair = root / "lorehold_repair.json"
        repair.write_text(
            json.dumps(
                {
                    "summary": {
                        "deck_id": "609",
                        "commander": "Lorehold, the Historian",
                        "commander_color_identity": ["W", "R"],
                    },
                    "input_artifacts": {
                        "candidate_db": str(root / "missing_lorehold_candidate.db"),
                        "strategy_matrix_report": str(strategy),
                    },
                    "repair_axis_pools": [
                        {
                            "repair_axis": "spell_payoffs_copy_engines",
                            "shortfall_to_min": 1,
                            "status": "needs_add_candidate_source_lane",
                            "top_add_candidates": [],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return repair

    def test_expands_payoff_lane_and_uses_base_db_fallback(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root, ["Balefire Dragon", "Ancient Copper Dragon", "Old Gnawbone"])
        repair = self._repair_report(root, db, shortfall=2)

        report = expander.build_report(repair_candidate_model_report=repair)

        self.assertEqual(report["status"], "commander_payoff_source_lane_expanded")
        self.assertTrue(report["db_resolution"]["fallback_used"])
        self.assertEqual(report["summary"]["ready_candidate_count"], 2)
        self.assertTrue(report["summary"]["ready_candidates_cover_shortfall"])
        names = {row["card_name"] for row in report["top_payoff_candidates"]}
        self.assertEqual(names, {"Balefire Dragon", "Ancient Copper Dragon"})
        blocked = {row["card_name"]: row["block_reasons"] for row in report["blocked_payoff_candidate_sample"]}
        self.assertIn("not_commander_color_identity_compatible", blocked["Old Gnawbone"])
        self.assertIn("commander_legality_banned", blocked["Banned Demon"])

    def test_marks_lane_insufficient_when_shortfall_not_covered(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root, ["Balefire Dragon"])
        repair = self._repair_report(root, db, shortfall=3)

        report = expander.build_report(repair_candidate_model_report=repair)

        self.assertEqual(report["status"], "commander_payoff_source_lane_needs_external_or_oracle_backfill")
        self.assertFalse(report["summary"]["ready_candidates_cover_shortfall"])
        self.assertEqual(report["summary"]["next_gate"], "external_reference_or_oracle_backfill_for_payoffs")

    def test_expands_lorehold_spell_payoff_lane(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._lorehold_db(root)
        repair = self._lorehold_repair_report(root, db)

        report = expander.build_report(repair_candidate_model_report=repair)

        self.assertEqual(report["status"], "commander_payoff_source_lane_expanded")
        self.assertEqual(report["summary"]["repair_axis"], "spell_payoffs_copy_engines")
        self.assertTrue(report["summary"]["ready_candidates_cover_shortfall"])
        names = {row["card_name"] for row in report["top_payoff_candidates"]}
        self.assertIn("Young Pyromancer", names)
        self.assertIn("Double Vision", names)
        self.assertNotIn("Storm-Kiln Artist", names)
        blocked = {row["card_name"]: row["block_reasons"] for row in report["blocked_payoff_candidate_sample"]}
        self.assertIn("already_in_candidate_deck", blocked["Storm-Kiln Artist"])
        self.assertIn("not_commander_color_identity_compatible", blocked["Archmage Emeritus"])
        reasons = {reason for row in report["top_payoff_candidates"] for reason in row["fit_reasons"]}
        self.assertTrue({"spell_copy_payoff", "token_spell_payoff"} & reasons)


if __name__ == "__main__":
    unittest.main()
