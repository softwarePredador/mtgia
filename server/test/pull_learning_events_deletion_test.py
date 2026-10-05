#!/usr/bin/env python3
"""BT-PRIV-002: o alimentador do Hermes não recria evento de conta excluída.

`pull_learning_events.py` lê os eventos do PostgreSQL e grava no SQLite. Se a
conta for excluída entre o SELECT e a gravação, o evento não pode entrar: a
gravação só leva o que ainda existe no PostgreSQL, conferido sob o lock de
escrita do SQLite, o mesmo que o expurgo do outbox pega.
"""
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "pull_learning_events.py"
    spec = importlib.util.spec_from_file_location("pull_learning_events_deletion", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _event(event_id: str, deck_id: str) -> dict:
    return {
        "id": event_id,
        "deck_id": deck_id,
        "commander_name": "Talrand, Sky Summoner",
        "format": "commander",
        "card_count": 100,
        "source": "user_created",
        "event_data": {"cards": ["Island"]},
        "created_at": datetime(2026, 9, 28, tzinfo=timezone.utc),
    }


class _FakeCursor:
    """Cursor do PostgreSQL de mentira: só a conferência de existência."""

    def __init__(self, live_ids: set[str], on_check=None) -> None:
        self.live_ids = live_ids
        self.on_check = on_check
        self.queries: list[str] = []
        self._rows: list[dict] = []

    def execute(self, query: str, params=None) -> None:
        self.queries.append(query)
        if "FROM deck_learning_events" in query and "ANY(" in query:
            if self.on_check is not None:
                self.on_check()
            asked = set(params[0])
            self._rows = [{"id": event_id} for event_id in sorted(asked & self.live_ids)]
        else:
            self._rows = []

    def fetchall(self) -> list[dict]:
        return self._rows


class PullLearningEventsDeletionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = _load_module()
        self._tmp = tempfile.TemporaryDirectory()
        self.db = Path(self._tmp.name) / "knowledge.db"
        self.sqlite = sqlite3.connect(self.db, timeout=0.2)
        self.module._ensure_tables(self.sqlite)

    def tearDown(self) -> None:
        self.sqlite.close()
        self._tmp.cleanup()

    def _stored(self) -> list[tuple[str, str]]:
        return self.sqlite.execute(
            "SELECT event_id, deck_id FROM user_learning_events ORDER BY event_id"
        ).fetchall()

    def test_event_deleted_after_the_select_is_not_written(self) -> None:
        events = [
            _event("ev-kept", "deck-kept"),
            _event("ev-deleted", "deck-deleted"),
        ]
        cursor = _FakeCursor(live_ids={"ev-kept"})
        imported, skipped, live = self.module._import_events(self.sqlite, cursor, events)
        self.assertEqual((imported, skipped), (1, 1))
        self.assertEqual(live, {"ev-kept"})
        self.assertEqual(self._stored(), [("ev-kept", "deck-kept")])

    def test_existence_check_runs_under_the_sqlite_write_lock(self) -> None:
        seen = {}

        def try_to_take_the_lock() -> None:
            other = sqlite3.connect(self.db, timeout=0, isolation_level=None)
            try:
                other.execute("BEGIN IMMEDIATE")
                seen["locked"] = False
                other.execute("ROLLBACK")
            except sqlite3.OperationalError as error:
                seen["locked"] = "locked" in str(error).lower()
            finally:
                other.close()

        cursor = _FakeCursor(live_ids={"ev-1"}, on_check=try_to_take_the_lock)
        self.module._import_events(self.sqlite, cursor, [_event("ev-1", "deck-1")])
        self.assertTrue(
            seen.get("locked"),
            "a conferência no PostgreSQL precisa rodar com o lock do SQLite tomado",
        )

    def test_nothing_is_written_when_the_check_fails(self) -> None:
        def boom() -> None:
            raise RuntimeError("PostgreSQL fora")

        cursor = _FakeCursor(live_ids={"ev-1"}, on_check=boom)
        with self.assertRaises(RuntimeError):
            self.module._import_events(self.sqlite, cursor, [_event("ev-1", "deck-1")])
        self.assertEqual(self._stored(), [])
        # O lock foi solto: outra conexão consegue escrever.
        other = sqlite3.connect(self.db, timeout=0, isolation_level=None)
        try:
            other.execute("BEGIN IMMEDIATE")
            other.execute("ROLLBACK")
        finally:
            other.close()


if __name__ == "__main__":
    unittest.main()
