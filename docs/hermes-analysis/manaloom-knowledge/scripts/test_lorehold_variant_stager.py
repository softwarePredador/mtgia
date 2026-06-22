#!/usr/bin/env python3
from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import lorehold_variant_stager as stager


def seed_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
                normalized_name TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                mana_cost TEXT,
                colors_json TEXT,
                color_identity_json TEXT,
                type_line TEXT,
                oracle_text TEXT,
                cmc REAL,
                power TEXT,
                toughness TEXT,
                keywords_json TEXT,
                scryfall_id TEXT,
                source TEXT NOT NULL DEFAULT 'test',
                updated_at TEXT NOT NULL
            )
            """
        )
        rows = [
            ("lorehold, the historian", "Lorehold, the Historian", "{3}{R}{W}", '["R","W"]', '["R","W"]', "Legendary Creature", "Flying", 5.0),
            ("plains", "Plains // Plains", "", '["W"]', '["W"]', "Basic Land — Plains", "", 0.0),
            ("sol ring", "Sol Ring", "{1}", "[]", "[]", "Artifact", "{T}: Add {C}{C}.", 1.0),
            ("approach of the second sun", "Approach of the Second Sun", "{6}{W}", '["W"]', '["W"]', "Sorcery", "If this spell was cast from your hand and you've cast another spell named Approach of the Second Sun this game, you win the game.", 7.0),
            ("counterspell", "Counterspell", "{U}{U}", '["U"]', '["U"]', "Instant", "Counter target spell.", 2.0),
        ]
        conn.executemany(
            """
            INSERT INTO card_oracle_cache (
                normalized_name, name, mana_cost, colors_json, color_identity_json,
                type_line, oracle_text, cmc, power, toughness, keywords_json,
                scryfall_id, source, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, '', '', '[]', '', 'test', '2026-06-22T00:00:00Z')
            """,
            rows,
        )
        conn.execute(
            """
            CREATE TABLE battle_card_rules (
                normalized_name TEXT NOT NULL,
                logical_rule_key TEXT NOT NULL,
                card_name TEXT NOT NULL,
                effect_json TEXT NOT NULL DEFAULT '{}',
                deck_role_json TEXT NOT NULL DEFAULT '{}',
                source TEXT NOT NULL DEFAULT 'curated',
                confidence REAL NOT NULL DEFAULT 1.0,
                review_status TEXT NOT NULL DEFAULT 'verified',
                execution_status TEXT NOT NULL DEFAULT 'auto',
                rule_version INTEGER NOT NULL DEFAULT 1,
                oracle_hash TEXT,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                last_seen_at TEXT,
                PRIMARY KEY (normalized_name, logical_rule_key)
            )
            """
        )
        conn.execute(
            """
            INSERT INTO battle_card_rules (
                normalized_name, logical_rule_key, card_name, effect_json,
                deck_role_json, created_at, updated_at
            )
            VALUES ('approach of the second sun', 'rule-approach', 'Approach of the Second Sun',
                    '{"effect":"approach"}', '{"category":"wincon"}',
                    '2026-06-22T00:00:00Z', '2026-06-22T00:00:00Z')
            """
        )
        conn.execute(
            """
            CREATE TABLE decks (
                id INTEGER PRIMARY KEY,
                deck_name TEXT,
                archetype TEXT,
                total_cards INTEGER DEFAULT 100,
                notes TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                card_name TEXT NOT NULL,
                quantity INTEGER DEFAULT 1,
                functional_tag TEXT,
                tag_confidence REAL,
                is_commander INTEGER DEFAULT 0,
                is_partner INTEGER DEFAULT 0,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT,
                card_id TEXT,
                functional_tags_json TEXT DEFAULT '[]',
                semantic_tags_v2_json TEXT DEFAULT '[]',
                battle_rules_json TEXT DEFAULT '[]',
                deck_hash TEXT,
                semantics_hash TEXT,
                sync_run_id TEXT,
                ruleset_hash TEXT,
                UNIQUE(deck_id, card_name)
            )
            """
        )
        conn.commit()


class LoreholdVariantStagerTest(unittest.TestCase):
    def test_parse_multiple_blocks(self) -> None:
        text = """
=== Variant A ===
Source: manual
Archetype: stax
Commander
1 Lorehold, the Historian
1 Sol Ring

=== Variant B ===
1 Approach of the Second Sun
"""
        decks = stager.parse_deck_blocks(text)
        self.assertEqual([deck.name for deck in decks], ["Variant A", "Variant B"])
        self.assertEqual(decks[0].source, "manual")
        self.assertEqual(decks[0].archetype, "stax")
        self.assertEqual(sum(card.quantity for card in decks[0].cards), 2)

    def test_validate_full_deck_and_materialize(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            seed_db(db)
            cards = ["1 Lorehold, the Historian", "1 Sol Ring", "1 Approach of the Second Sun", "97 Plains"]
            deck = stager.parse_deck_blocks("\n".join(cards))[0]
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                stager.ensure_tables(conn)
                report = stager.validate_deck(conn, deck, "input-sha")
                self.assertEqual(report["validation_status"], "valid")
                self.assertEqual(report["total_quantity"], 100)
                backup_id = stager.materialize_variant(conn, report, 606)
                self.assertTrue(backup_id.startswith("variant_target_606_"))
                rows = conn.execute(
                    "SELECT card_name, quantity, is_commander FROM deck_cards WHERE deck_id=606 ORDER BY is_commander DESC, card_name"
                ).fetchall()
                self.assertEqual(rows[0]["card_name"], "Lorehold, the Historian")
                self.assertEqual(sum(int(row["quantity"]) for row in rows), 100)

    def test_validate_blocks_missing_oracle_and_off_color(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            seed_db(db)
            deck = stager.parse_deck_blocks(
                "\n".join(
                    [
                        "1 Lorehold, the Historian",
                        "1 Sol Ring",
                        "1 Counterspell",
                        "1 Unknown Card",
                        "96 Plains",
                    ]
                )
            )[0]
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                stager.ensure_tables(conn)
                report = stager.validate_deck(conn, deck, "input-sha")
                self.assertEqual(report["validation_status"], "invalid")
                joined = "\n".join(report["issues"])
                self.assertIn("off_color_identity:U", joined)
                self.assertIn("oracle_missing", joined)


if __name__ == "__main__":
    unittest.main()
