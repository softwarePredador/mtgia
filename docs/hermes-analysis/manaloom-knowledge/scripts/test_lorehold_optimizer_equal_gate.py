import sqlite3
import tempfile
import unittest
from pathlib import Path

import lorehold_optimizer_equal_gate as gate


class LoreholdOptimizerEqualGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "knowledge.db"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute(
            """
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                card_id TEXT,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                tag_confidence REAL,
                is_commander INTEGER,
                is_partner INTEGER,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT,
                functional_tags_json TEXT,
                battle_rules_json TEXT,
                semantic_tags_json TEXT
            )
            """
        )
        self.conn.execute(
            """
            CREATE TABLE card_oracle_cache (
                normalized_name TEXT PRIMARY KEY,
                card_name TEXT,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT
            )
            """
        )
        self.conn.execute(
            """
            CREATE TABLE swap_benchmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                baseline_id INTEGER,
                card_added TEXT,
                card_removed TEXT,
                add_tag TEXT,
                phase TEXT
            )
            """
        )
        self.conn.execute(
            """
            INSERT INTO card_oracle_cache (normalized_name, card_name, cmc, type_line, oracle_text)
            VALUES ('flashback', 'Flashback', 3, 'Sorcery', 'Draw two cards, then discard two cards.')
            """
        )
        self.conn.execute(
            """
            INSERT INTO swap_benchmarks (deck_id, baseline_id, card_added, card_removed, add_tag, phase)
            VALUES (607, 11, 'Flashback', 'Emeria''s Call // Emeria, Shattered Skyclave', 'engine', 'confirmation')
            """
        )
        self.conn.execute(
            """
            INSERT INTO deck_cards
            (deck_id, card_id, card_name, quantity, functional_tag, is_commander, is_partner, cmc, type_line, oracle_text, functional_tags_json, battle_rules_json, semantic_tags_json)
            VALUES
            (607, 'cmd', 'Lorehold, the Historian', 1, 'commander', 1, 0, 4, 'Legendary Creature', '', '[\"commander\"]', '[]', '[]'),
            (607, 'e', 'Emeria''s Call // Emeria, Shattered Skyclave', 1, 'draw', 0, 0, 7, 'Sorcery', '', '[\"draw\"]', '[]', '[]'),
            (607, 'm', 'Mountain // Mountain', 4, 'land', 0, 0, 0, 'Basic Land', '', '[\"land\"]', '[]', '[]'),
            (607, 'p', 'Plains // Plains', 4, 'land', 0, 0, 0, 'Basic Land', '', '[\"land\"]', '[]', '[]')
            """
        )
        for idx in range(90):
            self.conn.execute(
                """
                INSERT INTO deck_cards
                (deck_id, card_id, card_name, quantity, functional_tag, is_commander, is_partner, cmc, type_line, oracle_text, functional_tags_json, battle_rules_json, semantic_tags_json)
                VALUES (?, ?, ?, 1, 'filler', 0, 0, 2, 'Sorcery', '', '[\"draw\"]', '[]', '[]')
                """,
                (607, f"f{idx}", f"Filler {idx}"),
            )
        self.conn.commit()

    def tearDown(self) -> None:
        self.conn.close()
        self.tmpdir.cleanup()

    def test_replace_candidate_deck_copies_source_and_applies_swap(self) -> None:
        meta = gate.replace_candidate_deck(
            self.conn,
            source_deck_id=607,
            candidate_deck_id=6,
            card_added="Flashback",
            card_removed="Emeria's Call // Emeria, Shattered Skyclave",
            add_tag="engine",
        )

        self.assertEqual(meta["total_cards"], 100)
        rows = self.conn.execute(
            "SELECT card_name, quantity FROM deck_cards WHERE deck_id=6 ORDER BY card_name"
        ).fetchall()
        names = {row["card_name"] for row in rows}
        self.assertIn("Flashback", names)
        self.assertNotIn("Emeria's Call // Emeria, Shattered Skyclave", names)
        self.assertEqual(sum(int(row["quantity"] or 1) for row in rows), 100)

    def test_load_swap_row_filters_by_deck_phase_and_card(self) -> None:
        row = gate.load_swap_row(
            self.conn,
            deck_id=607,
            baseline_id=11,
            phase="confirmation",
            only_added="Flashback",
        )

        self.assertEqual(row["card_added"], "Flashback")
        self.assertEqual(row["card_removed"], "Emeria's Call // Emeria, Shattered Skyclave")


if __name__ == "__main__":
    unittest.main()
