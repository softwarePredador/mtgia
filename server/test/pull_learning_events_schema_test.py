#!/usr/bin/env python3
"""Unit checks for the Hermes deck learning event puller schema guards."""

from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "pull_learning_events.py"
    spec = importlib.util.spec_from_file_location("pull_learning_events", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class PullLearningEventsSchemaTest(unittest.TestCase):
    def test_existing_sqlite_schema_is_extended_for_training_classification(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            conn = sqlite3.connect(Path(tmp) / "knowledge.db")
            try:
                conn.execute(
                    """
                    CREATE TABLE user_learning_events (
                        event_id TEXT PRIMARY KEY,
                        deck_id TEXT,
                        commander TEXT,
                        format TEXT,
                        card_count INTEGER DEFAULT 0,
                        source TEXT DEFAULT 'user_created',
                        event_data TEXT DEFAULT '{}',
                        created_at TEXT,
                        imported_at TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    INSERT INTO user_learning_events (
                        event_id, deck_id, commander, format, card_count
                    )
                    VALUES
                        ('event-full', 'deck-1', 'Talrand, Sky Summoner', 'commander', 100),
                        ('event-partial', 'deck-2', 'Atraxa, Praetors'' Voice', 'commander', 1)
                    """
                )

                module._ensure_tables(conn)

                columns = {
                    row[1]
                    for row in conn.execute(
                        "PRAGMA table_info(user_learning_events)"
                    ).fetchall()
                }
                self.assertIn("training_eligible", columns)
                self.assertIn("learning_status", columns)
                self.assertIn("learning_reason", columns)

                trainable = module._classify_learning_event(
                    "commander",
                    100,
                    "Talrand, Sky Summoner",
                )
                partial = module._classify_learning_event(
                    "commander",
                    1,
                    "Atraxa, Praetors' Voice",
                )
                non_commander = module._classify_learning_event("standard", 60, "")

                self.assertTrue(trainable["training_eligible"])
                self.assertEqual(
                    trainable["learning_status"],
                    "trainable_commander_deck",
                )
                self.assertFalse(partial["training_eligible"])
                self.assertEqual(partial["learning_status"], "partial_telemetry")
                self.assertFalse(non_commander["training_eligible"])
                self.assertEqual(
                    non_commander["learning_status"],
                    "non_commander_telemetry",
                )

                module._import_commander(conn, "Talrand, Sky Summoner")
                self.assertEqual(
                    conn.execute("SELECT count(*) FROM commanders").fetchone()[0],
                    1,
                )
                statuses = {
                    row[0]: (row[1], row[2])
                    for row in conn.execute(
                        """
                        SELECT event_id, learning_status, training_eligible
                        FROM user_learning_events
                        """
                    ).fetchall()
                }
                self.assertEqual(
                    statuses["event-full"],
                    ("trainable_commander_deck", 1),
                )
                self.assertEqual(
                    statuses["event-partial"],
                    ("partial_telemetry", 0),
                )
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
