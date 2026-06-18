#!/usr/bin/env python3
"""Regression tests for battle analyst multi-functional deck rows."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import battle_analyst_v9 as battle


class BattleFunctionalTagsJsonTest(unittest.TestCase):
    def test_load_deck_uses_functional_tags_json_without_row_fanout(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE deck_cards (
                    deck_id INTEGER,
                    card_name TEXT,
                    quantity INTEGER,
                    functional_tag TEXT,
                    functional_tags_json TEXT,
                    cmc REAL,
                    type_line TEXT,
                    oracle_text TEXT,
                    is_commander INTEGER
                )
                """
            )
            conn.executemany(
                """
                INSERT INTO deck_cards
                    (deck_id, card_name, quantity, functional_tag,
                     functional_tags_json, cmc, type_line, oracle_text,
                     is_commander)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                [
                    (
                        6,
                        "Lorehold, the Historian",
                        1,
                        "commander",
                        json.dumps(["commander"]),
                        5,
                        "Legendary Creature",
                        "",
                        1,
                    ),
                    (
                        6,
                        "Arcane Archive",
                        1,
                        "engine",
                        json.dumps(["draw", "engine"]),
                        2,
                        "Artifact",
                        "",
                        0,
                    ),
                    (
                        6,
                        "Boros Answer",
                        1,
                        "utility",
                        json.dumps(["removal", "protection"]),
                        2,
                        "Instant",
                        "",
                        0,
                    ),
                ],
            )
            conn.commit()
            conn.close()

            original_db = battle.DB
            try:
                battle.DB = str(db_path)
                commander, deck = battle.load_deck(6)
            finally:
                battle.DB = original_db

        self.assertEqual(commander["name"], "Lorehold, the Historian")
        self.assertEqual(len(deck), 2)

        archive = next(card for card in deck if card["name"] == "Arcane Archive")
        answer = next(card for card in deck if card["name"] == "Boros Answer")

        self.assertEqual(archive["functional_tags"], ["draw", "engine"])
        self.assertEqual(answer["functional_tags"], ["removal", "protection", "utility"])
        self.assertEqual(battle.get_card_effect(archive)["effect"], "draw_cards")
        self.assertEqual(battle.get_card_effect(answer)["effect"], "remove_creature")
        self.assertTrue(battle.card_has_functional_tag(answer, "protection"))


if __name__ == "__main__":
    unittest.main()
