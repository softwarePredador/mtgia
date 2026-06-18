#!/usr/bin/env python3
"""Unit checks for Hermes learned deck auto-sync selection guards."""

from __future__ import annotations

import importlib.util
import os
import sqlite3
import tempfile
import unittest
from pathlib import Path


def _load_module(tmp: str):
    os.environ["HERMES_ARTIFACT_DIR"] = str(Path(tmp) / "artifacts")
    os.environ["HERMES_KNOWLEDGE_DB"] = str(Path(tmp) / "knowledge.db")
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "auto_sync_learned_decks.py"
    spec = importlib.util.spec_from_file_location("auto_sync_learned_decks", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class AutoSyncLearnedDecksTest(unittest.TestCase):
    def test_promoted_rows_only_include_exact_commander_100_decks(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            module = _load_module(tmp)
            conn = sqlite3.connect(":memory:")
            try:
                conn.execute(
                    """
                    CREATE TABLE learned_decks (
                        id INTEGER PRIMARY KEY,
                        commander TEXT,
                        deck_name TEXT,
                        card_count INTEGER
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE deck_promotions (
                        id INTEGER PRIMARY KEY,
                        learned_deck_id INTEGER,
                        promoted_at TEXT
                    )
                    """
                )
                conn.executemany(
                    """
                    INSERT INTO learned_decks (
                        id, commander, deck_name, card_count
                    ) VALUES (?, ?, ?, ?)
                    """,
                    [
                        (1, "Korvold, Fae-Cursed King", "Partial Korvold", 90),
                        (2, "Talrand, Sky Summoner", "Full Talrand", 100),
                        (3, "", "No Commander", 100),
                    ],
                )
                conn.executemany(
                    """
                    INSERT INTO deck_promotions (learned_deck_id, promoted_at)
                    VALUES (?, ?)
                    """,
                    [
                        (1, "2026-06-01T00:00:00Z"),
                        (2, "2026-06-02T00:00:00Z"),
                        (3, "2026-06-03T00:00:00Z"),
                    ],
                )

                rows = module._find_promoted_rows(conn)

                self.assertEqual(len(rows), 1)
                self.assertEqual(rows[0][0], 2)
                self.assertEqual(module._count_invalid_promoted_rows(conn), 2)
            finally:
                conn.close()

    def test_missing_promotion_tables_are_safe_noops(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            module = _load_module(tmp)
            conn = sqlite3.connect(":memory:")
            try:
                self.assertEqual(module._find_promoted_rows(conn), [])
                self.assertEqual(module._count_invalid_promoted_rows(conn), 0)
            finally:
                conn.close()

    def test_unverified_promotions_are_not_synced_when_column_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            module = _load_module(tmp)
            conn = sqlite3.connect(":memory:")
            try:
                conn.execute(
                    """
                    CREATE TABLE learned_decks (
                        id INTEGER PRIMARY KEY,
                        commander TEXT,
                        deck_name TEXT,
                        card_count INTEGER
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE deck_promotions (
                        id INTEGER PRIMARY KEY,
                        learned_deck_id INTEGER,
                        promoted_at TEXT,
                        migration_verified INTEGER DEFAULT 0
                    )
                    """
                )
                conn.executemany(
                    """
                    INSERT INTO learned_decks (
                        id, commander, deck_name, card_count
                    ) VALUES (?, ?, ?, ?)
                    """,
                    [
                        (1, "Talrand, Sky Summoner", "Verified", 100),
                        (2, "Krenko, Mob Boss", "Unverified", 100),
                    ],
                )
                conn.executemany(
                    """
                    INSERT INTO deck_promotions (
                        learned_deck_id, promoted_at, migration_verified
                    ) VALUES (?, ?, ?)
                    """,
                    [
                        (1, "2026-06-01T00:00:00Z", 1),
                        (2, "2026-06-02T00:00:00Z", 0),
                    ],
                )

                rows = module._find_promoted_rows(conn)

                self.assertEqual(len(rows), 1)
                self.assertEqual(rows[0][0], 1)
                self.assertEqual(module._count_invalid_promoted_rows(conn), 1)
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
