#!/usr/bin/env python3
import sqlite3
import tempfile
import unittest
from pathlib import Path

import master_optimizer_common as optimizer


class MasterOptimizerHashTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "knowledge.db"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_id TEXT,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                functional_tags_json TEXT,
                battle_rules_json TEXT,
                tag_confidence REAL,
                is_commander INTEGER,
                is_partner INTEGER,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT
            )
            """
        )
        self.conn.executemany(
            """
            INSERT INTO deck_cards (
                deck_id, card_id, card_name, quantity, functional_tag,
                functional_tags_json, battle_rules_json, tag_confidence,
                is_commander, is_partner, cmc, type_line, oracle_text
            )
            VALUES (6, ?, ?, 1, ?, ?, ?, 0.9, ?, 0, ?, ?, ?)
            """,
            [
                (
                    "cmd-1",
                    "Lorehold, the Historian",
                    "commander",
                    '["commander"]',
                    "[]",
                    1,
                    4,
                    "Legendary Creature",
                    "Commander text",
                ),
                (
                    "draw-1",
                    "Archive Trap",
                    "draw",
                    '["draw"]',
                    "[]",
                    0,
                    2,
                    "Instant",
                    "Draw a card.",
                ),
            ],
        )
        self.conn.commit()
        optimizer.ensure_optimizer_tables(self.conn)

    def tearDown(self) -> None:
        self.conn.close()
        self.tmpdir.cleanup()

    def _insert_baseline(self) -> sqlite3.Row:
        summary = optimizer.get_deck_summary(self.conn, 6)
        self.conn.execute(
            """
            INSERT INTO optimizer_baseline_runs (
                deck_id, deck_hash, semantics_hash, ruleset_hash,
                games_per_opponent, opponents, total_games, wr, wins, losses,
                stalls, status, result_json, created_at
            )
            VALUES (6, ?, ?, ?, 1, 1, 1, 100.0, 1, 0, 0, 'approved', '{}', ?)
            """,
            (
                summary["hash"],
                summary["semantics_hash"],
                summary["ruleset_hash"],
                optimizer.utc_now(),
            ),
        )
        self.conn.commit()
        baseline = optimizer.latest_baseline(self.conn, 6)
        assert baseline is not None
        return baseline

    def test_optimizer_tables_expose_semantic_hash_columns(self) -> None:
        baseline_columns = {
            row[1]
            for row in self.conn.execute("PRAGMA table_info(optimizer_baseline_runs)")
        }
        slot_columns = {
            row[1] for row in self.conn.execute("PRAGMA table_info(slot_benchmarks)")
        }
        self.assertIn("semantics_hash", baseline_columns)
        self.assertIn("ruleset_hash", baseline_columns)
        self.assertIn("baseline_semantics_hash", slot_columns)
        self.assertIn("baseline_ruleset_hash", slot_columns)

    def test_semantic_only_change_invalidates_semantic_baseline_not_deck_hash(self) -> None:
        baseline = self._insert_baseline()
        before_deck_hash = optimizer.deck_hash(self.conn, 6)
        self.conn.execute(
            """
            UPDATE deck_cards
            SET functional_tags_json='["draw","removal"]'
            WHERE card_id='draw-1'
            """
        )
        self.conn.commit()
        self.assertEqual(optimizer.deck_hash(self.conn, 6), before_deck_hash)
        with self.assertRaisesRegex(RuntimeError, "semantics hash"):
            optimizer.assert_current_deck_matches_baseline(self.conn, 6, baseline)

    def test_rules_only_change_invalidates_ruleset_baseline_not_deck_hash(self) -> None:
        baseline = self._insert_baseline()
        before_deck_hash = optimizer.deck_hash(self.conn, 6)
        self.conn.execute(
            """
            UPDATE deck_cards
            SET battle_rules_json='[{"effect":{"effect":"draw_cards"},"source":"test"}]'
            WHERE card_id='draw-1'
            """
        )
        self.conn.commit()
        self.assertEqual(optimizer.deck_hash(self.conn, 6), before_deck_hash)
        with self.assertRaisesRegex(RuntimeError, "ruleset hash"):
            optimizer.assert_current_deck_matches_baseline(self.conn, 6, baseline)

    def test_battle_rule_deck_categories_preserve_multiple_roles_same_name(self) -> None:
        optimizer.battle_rule_registry.ensure_battle_card_rules(self.conn)
        optimizer.battle_rule_registry.upsert_battle_card_rule(
            self.conn,
            "Modal Test Card",
            {"effect": "draw_cards", "amount": 2},
            source="curated",
            confidence=0.95,
            review_status="verified",
        )
        optimizer.battle_rule_registry.upsert_battle_card_rule(
            self.conn,
            "Modal Test Card",
            {"effect": "remove_creature", "target": "creature"},
            source="curated",
            confidence=0.95,
            review_status="verified",
        )
        self.conn.commit()

        categories = optimizer.battle_rule_deck_categories(self.conn, "Modal Test Card")

        self.assertEqual(categories, {"draw", "removal"})
        self.assertEqual(
            optimizer.battle_rule_deck_category(self.conn, "Modal Test Card"),
            "removal",
        )


if __name__ == "__main__":
    unittest.main()
