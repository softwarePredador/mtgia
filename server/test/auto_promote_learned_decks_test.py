#!/usr/bin/env python3
"""Unit checks for Hermes learned deck auto-promotion guards."""

from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import tempfile
import unittest
from pathlib import Path


def _load_module(tmp: str):
    os.environ["HERMES_KNOWLEDGE_DB"] = str(Path(tmp) / "knowledge.db")
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "auto_promote_learned_decks.py"
    spec = importlib.util.spec_from_file_location("auto_promote_learned_decks", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _commander_card_list(commander: str) -> str:
    cards = [{"name": commander, "quantity": 1}]
    cards.extend({"name": f"Spell {i}", "quantity": 1} for i in range(1, 100))
    return json.dumps(cards)


def _create_reduced_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE learned_decks (
            id INTEGER PRIMARY KEY,
            source TEXT,
            commander TEXT,
            deck_name TEXT,
            archetype TEXT,
            card_list TEXT,
            card_count INTEGER,
            wincon_primary TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE decks (
            id INTEGER PRIMARY KEY,
            deck_name TEXT,
            archetype TEXT,
            total_cards INTEGER
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE deck_cards (
            id INTEGER PRIMARY KEY,
            deck_id INTEGER,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            is_commander INTEGER DEFAULT 0
        )
        """
    )


class AutoPromoteLearnedDecksTest(unittest.TestCase):
    def test_reduced_schema_promotes_only_verified_target_deck(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            module = _load_module(tmp)
            db_path = os.environ["HERMES_KNOWLEDGE_DB"]
            conn = sqlite3.connect(db_path)
            try:
                _create_reduced_schema(conn)
                commander = "Talrand, Sky Summoner"
                conn.execute(
                    """
                    INSERT INTO learned_decks (
                        id, source, commander, deck_name, archetype, card_list,
                        card_count, wincon_primary
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        1,
                        "test",
                        commander,
                        commander,
                        "control",
                        _commander_card_list(commander),
                        100,
                        "draw-go",
                    ),
                )
                conn.execute(
                    """
                    INSERT INTO decks (id, deck_name, archetype, total_cards)
                    VALUES (?, ?, ?, ?)
                    """,
                    (10, commander, "control", 100),
                )
                conn.execute(
                    """
                    INSERT INTO deck_cards (
                        deck_id, card_name, quantity, is_commander
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (10, commander, 1, 1),
                )
                conn.executemany(
                    """
                    INSERT INTO deck_cards (
                        deck_id, card_name, quantity, is_commander
                    ) VALUES (?, ?, ?, ?)
                    """,
                    [(10, f"Spell {i}", 1, 0) for i in range(1, 100)],
                )
                conn.commit()
            finally:
                conn.close()

            self.assertEqual(module.main([]), 0)

            conn = sqlite3.connect(db_path)
            try:
                row = conn.execute(
                    """
                    SELECT learned_deck_id, target_deck_id, new_card_count,
                           actual_card_count, migration_verified
                    FROM deck_promotions
                    """
                ).fetchone()
                self.assertEqual(row, (1, 10, 100, 100, 1))
            finally:
                conn.close()

    def test_incomplete_target_deck_is_not_promoted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            module = _load_module(tmp)
            db_path = os.environ["HERMES_KNOWLEDGE_DB"]
            conn = sqlite3.connect(db_path)
            try:
                _create_reduced_schema(conn)
                commander = "Krenko, Mob Boss"
                conn.execute(
                    """
                    INSERT INTO learned_decks (
                        id, source, commander, deck_name, archetype, card_list,
                        card_count, wincon_primary
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        1,
                        "test",
                        commander,
                        commander,
                        "aggro",
                        _commander_card_list(commander),
                        100,
                        "tokens",
                    ),
                )
                conn.execute(
                    """
                    INSERT INTO decks (id, deck_name, archetype, total_cards)
                    VALUES (?, ?, ?, ?)
                    """,
                    (10, commander, "aggro", 13),
                )
                conn.execute(
                    """
                    INSERT INTO deck_cards (
                        deck_id, card_name, quantity, is_commander
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (10, commander, 1, 1),
                )
                conn.commit()
            finally:
                conn.close()

            self.assertEqual(module.main([]), 0)

            conn = sqlite3.connect(db_path)
            try:
                count = conn.execute("SELECT COUNT(*) FROM deck_promotions").fetchone()[0]
                self.assertEqual(count, 0)
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
