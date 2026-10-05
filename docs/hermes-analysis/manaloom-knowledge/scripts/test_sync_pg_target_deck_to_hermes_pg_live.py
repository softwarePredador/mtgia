#!/usr/bin/env python3
"""BT-AI-030 contra um PostgreSQL descartável de verdade.

A conferência que o sync faz sob o lock do SQLite roda no banco: o deck vivo
passa, o da lixeira e o apagado não passam, e a gravação com a conferência
padrão (sem dublê) grava ou recusa conforme o banco.

Requer RUN_HERMES_TARGET_DECK_PG_TESTS=1 e DATABASE_URL de um PostgreSQL
descartável em loopback. O teste recusa qualquer alvo fora do loopback antes de
tocar no banco: sem DATABASE_URL explícita, o db_helper procuraria um .env nos
diretórios acima, e esse .env pode apontar para outro banco.
"""

from __future__ import annotations

import os
import sqlite3
import tempfile
import unittest
import uuid
from pathlib import Path

import sync_pg_target_deck_to_hermes as sync

_CARDS = [
    {
        "card_id": "00000000-0000-0000-0000-000000000004",
        "name": "Sol Ring",
        "quantity": 1,
        "is_commander": False,
        "functional_tag": "ramp",
        "functional_tags_json": ["ramp"],
        "semantic_tags_v2_json": [],
        "battle_rules_json": [],
        "cmc": 1,
        "type_line": "Artifact",
        "oracle_text": "{T}: Add {C}{C}.",
    }
]


class SyncPgTargetDeckPgLiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if os.environ.get("RUN_HERMES_TARGET_DECK_PG_TESTS") != "1":
            raise unittest.SkipTest(
                "Requer RUN_HERMES_TARGET_DECK_PG_TESTS=1 e DATABASE_URL local."
            )
        if not os.environ.get("DATABASE_URL"):
            raise unittest.SkipTest("Requer DATABASE_URL explícita e local.")
        target = sync.sanitized_database_target()
        host = target.split(":", 1)[0]
        if host not in {"127.0.0.1", "localhost", "::1"}:
            raise AssertionError(f"alvo fora do loopback recusado: {host}")

    def setUp(self) -> None:
        self.conn = sync.connect()
        self.conn.autocommit = True
        suffix = uuid.uuid4().hex[:12]
        with self.conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (username, email, password_hash) "
                "VALUES (%s, %s, %s) RETURNING id::text",
                (f"bt_ai_030_{suffix}", f"bt-ai-030-{suffix}@example.invalid", "x"),
            )
            self.user_id = cur.fetchone()[0]
            cur.execute(
                "INSERT INTO decks (user_id, name, format) "
                "VALUES (%s, %s, 'commander') RETURNING id::text",
                (self.user_id, f"BT-AI-030 {suffix}"),
            )
            self.deck_id = cur.fetchone()[0]

    def tearDown(self) -> None:
        with self.conn.cursor() as cur:
            cur.execute("DELETE FROM users WHERE id = %s", (self.user_id,))
        self.conn.close()

    def _write(self, db_path: Path) -> dict:
        return sync.write_sqlite(
            str(db_path),
            608,
            {
                "name": "Alvo BT-AI-030",
                "archetype": "midrange",
                "total_qty": 1,
                "pg_deck_id": self.deck_id,
            },
            _CARDS,
            apply=True,
        )

    @staticmethod
    def _rows(db_path: Path) -> int:
        conn = sqlite3.connect(db_path)
        try:
            return conn.execute(
                "SELECT count(*) FROM deck_cards WHERE deck_id = 608"
            ).fetchone()[0]
        finally:
            conn.close()

    def test_the_check_runs_in_postgres(self) -> None:
        self.assertTrue(sync.pg_deck_still_exists(self.deck_id))
        self.assertTrue(sync.pg_deck_still_exists(self.deck_id.upper()))
        with self.conn.cursor() as cur:
            cur.execute("UPDATE decks SET deleted_at = NOW() WHERE id = %s", (self.deck_id,))
        self.assertFalse(sync.pg_deck_still_exists(self.deck_id), "lixeira")
        with self.conn.cursor() as cur:
            cur.execute("DELETE FROM decks WHERE id = %s", (self.deck_id,))
        self.assertFalse(sync.pg_deck_still_exists(self.deck_id), "apagado")

    def test_the_default_check_writes_a_live_deck_and_refuses_a_deleted_one(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            stats = self._write(db_path)
            self.assertTrue(stats["pg_deck_confirmed_under_sqlite_lock"])
            self.assertEqual(self._rows(db_path), 1)

            with self.conn.cursor() as cur:
                cur.execute("DELETE FROM decks WHERE id = %s", (self.deck_id,))
            with self.assertRaises(sync.DeckGoneError):
                self._write(db_path)
            # A cópia anterior fica como estava; quem a apaga é o expurgo.
            self.assertEqual(self._rows(db_path), 1)


if __name__ == "__main__":
    unittest.main()
