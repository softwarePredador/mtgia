#!/usr/bin/env python3
"""BT-PRIV-002: expurgo do SQLite do Hermes (server/bin/hermes_learning_purge.py)."""
from __future__ import annotations

import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "hermes_learning_purge.py"

DELETED_A = "0f1e2d3c-4b5a-4968-8778-695a4b3c2d1e"
DELETED_B = "1a2b3c4d-5e6f-4a0b-9c8d-7e6f5a4b3c2d"
KEPT = "9e8d7c6b-5a49-4838-a271-605f4e3d2c1b"


def _run(command: str, db: Path, stdin: str = "", *extra: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT), command, "--db", str(db), *extra],
        input=stdin,
        capture_output=True,
        text=True,
        timeout=60,
    )


def _seed(db: Path) -> None:
    conn = sqlite3.connect(db)
    try:
        conn.executescript(
            """
            CREATE TABLE user_learning_events (
                event_id TEXT PRIMARY KEY,
                deck_id TEXT,
                commander TEXT,
                event_data TEXT DEFAULT '{}'
            );
            CREATE TABLE decks (
                id INTEGER PRIMARY KEY,
                deck_name TEXT,
                notes TEXT
            );
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                card_name TEXT NOT NULL
            );
            """
        )
        conn.executemany(
            "INSERT INTO user_learning_events (event_id, deck_id, commander) VALUES (?, ?, ?)",
            [
                ("e1", DELETED_A, "Talrand"),
                ("e2", DELETED_A, "Talrand"),
                ("e3", DELETED_B, "Atraxa"),
                ("e4", KEPT, "Lorehold"),
            ],
        )
        conn.executemany(
            "INSERT INTO decks (id, deck_name, notes) VALUES (?, ?, ?)",
            [
                (6, "Cópia do deck apagado", f"sync_pg_target_deck_to_hermes.py pg_deck_id={DELETED_A} deck_hash=x"),
                (7, "Cópia do deck que fica", f"sync_pg_target_deck_to_hermes.py pg_deck_id={KEPT} deck_hash=y"),
                (8, "Deck do laboratório", "sem origem no PostgreSQL"),
            ],
        )
        conn.executemany(
            "INSERT INTO deck_cards (deck_id, card_name) VALUES (?, ?)",
            [(6, "Island"), (6, "Counterspell"), (7, "Mountain"), (8, "Forest")],
        )
        conn.commit()
    finally:
        conn.close()


class HermesLearningPurgeTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.db = Path(self._tmp.name) / "knowledge.db"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_list_reads_event_decks_and_copies_without_writing(self) -> None:
        _seed(self.db)
        before = self.db.stat().st_mtime_ns
        result = _run("list", self.db)
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["schema"], "hermes_learning_purge_v1")
        self.assertEqual(payload["deck_ids"], sorted([DELETED_A, DELETED_B, KEPT]))
        self.assertEqual(payload["event_decks"], 3)
        self.assertEqual(payload["copied_decks"], 2)
        self.assertEqual(self.db.stat().st_mtime_ns, before)

    def test_absent_database_is_reported_and_never_created(self) -> None:
        for command in ("list", "purge"):
            result = _run(command, self.db, json.dumps({"deck_ids": [DELETED_A]}))
            self.assertEqual(result.returncode, 3, command)
            self.assertEqual(json.loads(result.stdout)["status"], "absent")
            self.assertFalse(self.db.exists(), command)

    def test_purge_removes_events_and_copies_of_the_given_decks_only(self) -> None:
        _seed(self.db)
        result = _run("purge", self.db, json.dumps({"deck_ids": [DELETED_A, DELETED_B]}))
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["events_deleted"], 3)
        self.assertEqual(payload["decks_deleted"], 1)
        self.assertEqual(payload["deck_cards_deleted"], 2)
        self.assertEqual(payload["remaining_deck_ids"], [KEPT])

        conn = sqlite3.connect(self.db)
        try:
            self.assertEqual(
                conn.execute("SELECT event_id FROM user_learning_events").fetchall(),
                [("e4",)],
            )
            self.assertEqual(
                sorted(row[0] for row in conn.execute("SELECT id FROM decks")),
                [7, 8],
            )
            self.assertEqual(
                sorted(row[0] for row in conn.execute("SELECT deck_id FROM deck_cards")),
                [7, 8],
            )
        finally:
            conn.close()

    def test_purge_is_idempotent(self) -> None:
        _seed(self.db)
        request = json.dumps({"deck_ids": [DELETED_A]})
        first = json.loads(_run("purge", self.db, request).stdout)
        second = _run("purge", self.db, request)
        self.assertEqual(second.returncode, 0, second.stderr)
        payload = json.loads(second.stdout)
        self.assertEqual(first["events_deleted"], 2)
        self.assertEqual(payload["events_deleted"], 0)
        self.assertEqual(payload["decks_deleted"], 0)
        self.assertEqual(payload["remaining_deck_ids"], sorted([DELETED_B, KEPT]))

    def test_purge_waits_for_the_write_lock_and_reports_busy(self) -> None:
        _seed(self.db)
        holder = sqlite3.connect(self.db, isolation_level=None)
        try:
            holder.execute("BEGIN IMMEDIATE")
            result = _run(
                "purge",
                self.db,
                json.dumps({"deck_ids": [DELETED_A]}),
                "--busy-timeout-ms",
                "200",
            )
            self.assertEqual(result.returncode, 4, result.stderr)
            self.assertEqual(json.loads(result.stdout)["status"], "busy")
        finally:
            holder.execute("ROLLBACK")
            holder.close()
        conn = sqlite3.connect(self.db)
        try:
            self.assertEqual(
                conn.execute("SELECT COUNT(*) FROM user_learning_events").fetchone()[0],
                4,
            )
        finally:
            conn.close()

    def test_database_without_hermes_tables_has_no_candidates(self) -> None:
        sqlite3.connect(self.db).close()
        listed = json.loads(_run("list", self.db).stdout)
        self.assertEqual(listed["deck_ids"], [])
        purged = _run("purge", self.db, json.dumps({"deck_ids": [DELETED_A]}))
        self.assertEqual(purged.returncode, 0, purged.stderr)
        self.assertEqual(json.loads(purged.stdout)["remaining_deck_ids"], [])

    def test_stderr_never_carries_an_identifier(self) -> None:
        _seed(self.db)
        bad = _run("purge", self.db, json.dumps({"deck_ids": DELETED_A}))
        self.assertEqual(bad.returncode, 1)
        for result in (bad, _run("list", self.db)):
            self.assertNotIn(DELETED_A, result.stderr)
            self.assertNotIn(KEPT, result.stderr)


if __name__ == "__main__":
    unittest.main()
