#!/usr/bin/env python3
"""Tests for knowledge_db multi-tag snapshot helpers."""

from __future__ import annotations

import json
import io
import os
import sys
import tempfile
import unittest

import knowledge_db


class KnowledgeDbMultiTagsTests(unittest.TestCase):
    def test_functional_tags_json_prefers_explicit_array(self) -> None:
        payload = knowledge_db.functional_tags_json_for_card(
            {
                "functional_tag": "draw",
                "functional_tags_json": ["engine", "draw", "engine"],
            }
        )

        self.assertEqual(json.loads(payload), ["draw", "engine"])

    def test_functional_tags_json_uses_card_tags_then_legacy_fallback(self) -> None:
        from_card_tags = knowledge_db.functional_tags_json_for_card(
            {
                "functional_tag": "unknown",
                "tags": [
                    {"tag": "ramp", "confidence": 0.9},
                    {"tag": "engine", "confidence": 0.7},
                ],
            }
        )
        legacy = knowledge_db.functional_tags_json_for_card(
            {"functional_tag": "removal"}
        )
        unknown = knowledge_db.functional_tags_json_for_card(
            {"functional_tag": "unknown"}
        )

        self.assertEqual(json.loads(from_card_tags), ["engine", "ramp"])
        self.assertEqual(json.loads(legacy), ["removal"])
        self.assertEqual(json.loads(unknown), [])

    def test_insert_deck_migrates_legacy_database_before_multi_tag_write(self) -> None:
        legacy_schema = knowledge_db.SCHEMA.replace(
            "    functional_tags_json TEXT DEFAULT '[]',\n",
            "",
        )
        payload = {
            "commander": "Lorehold, the Historian",
            "deck_name": "Legacy SQLite compatibility",
            "source_name": "unit-test",
            "cards": [
                {
                    "name": "Archivist of Oghma",
                    "quantity": 1,
                    "functional_tag": "draw",
                    "tags": [
                        {"tag": "draw", "confidence": 0.9},
                        {"tag": "engine", "confidence": 0.7},
                    ],
                }
            ],
        }

        old_db_path = knowledge_db.DB_PATH
        old_stdin = sys.stdin
        old_stdout = sys.stdout
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = os.path.join(tmpdir, "knowledge.db")
            conn = knowledge_db.sqlite3.connect(db_path)
            conn.executescript(legacy_schema)
            conn.commit()
            conn.close()

            try:
                knowledge_db.DB_PATH = db_path
                sys.stdin = io.StringIO(json.dumps(payload))
                sys.stdout = io.StringIO()

                knowledge_db.cmd_insert_deck()

                conn = knowledge_db.sqlite3.connect(db_path)
                columns = {
                    row[1]
                    for row in conn.execute("PRAGMA table_info(deck_cards)").fetchall()
                }
                row = conn.execute(
                    "SELECT functional_tags_json FROM deck_cards WHERE card_name = ?",
                    ("Archivist of Oghma",),
                ).fetchone()
                conn.close()
            finally:
                knowledge_db.DB_PATH = old_db_path
                sys.stdin = old_stdin
                sys.stdout = old_stdout

        self.assertIn("functional_tags_json", columns)
        self.assertIsNotNone(row)
        self.assertEqual(json.loads(row[0]), ["draw", "engine"])


if __name__ == "__main__":
    unittest.main()
