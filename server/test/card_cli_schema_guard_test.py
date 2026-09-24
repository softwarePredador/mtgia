#!/usr/bin/env python3
"""BT-DB-004: os CLIs Python de cartas não alteram schema; conferem e param.

`sync_cards_full_fast.py` e `backfill_card_combat_metadata.py` faziam
`ALTER TABLE cards ADD COLUMN` e `CREATE INDEX` a cada execução. Agora só leem o
catálogo e saem com erro, sem escrever, se faltar coluna ou índice.
"""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / "bin"


def _load(name: str):
    path = BIN / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"bt_db_004_{name}", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class FakeCursor:
    def __init__(self, connection: "FakeConnection") -> None:
        self.connection = connection
        self.rows: list[tuple[str]] = []

    def __enter__(self) -> "FakeCursor":
        return self

    def __exit__(self, *_exc) -> None:
        return None

    def execute(self, sql: str, params=None) -> None:
        self.connection.statements.append(" ".join(sql.split()))
        wanted = set(params[0]) if params else set()
        if "information_schema.columns" in sql:
            self.rows = [(c,) for c in wanted & self.connection.columns]
        elif "pg_indexes" in sql:
            self.rows = [(i,) for i in wanted & self.connection.indexes]
        else:
            self.rows = []

    def fetchall(self) -> list[tuple[str]]:
        return self.rows


class FakeConnection:
    def __init__(self, columns: set[str], indexes: set[str]) -> None:
        self.columns = columns
        self.indexes = indexes
        self.statements: list[str] = []
        self.commits = 0
        self.rollbacks = 0

    def cursor(self) -> FakeCursor:
        return FakeCursor(self)

    def commit(self) -> None:
        self.commits += 1

    def rollback(self) -> None:
        self.rollbacks += 1


class CardCliSchemaGuardTest(unittest.TestCase):
    MODULES = ("sync_cards_full_fast", "backfill_card_combat_metadata")

    def assert_read_only(self, connection: FakeConnection) -> None:
        for statement in connection.statements:
            self.assertTrue(statement.upper().startswith("SELECT"), statement)
        self.assertEqual(connection.commits, 0)

    def test_complete_schema_passes_without_writing(self) -> None:
        for name in self.MODULES:
            module = _load(name)
            connection = FakeConnection(
                set(module.REQUIRED_CARD_COLUMNS), set(module.REQUIRED_CARD_INDEXES)
            )
            module.require_schema(connection)
            self.assertEqual(module.missing_schema_objects(connection), [])
            self.assert_read_only(connection)

    def test_missing_column_or_index_stops_before_any_write(self) -> None:
        for name in self.MODULES:
            module = _load(name)
            columns = set(module.REQUIRED_CARD_COLUMNS) - {"keywords"}
            indexes = set(module.REQUIRED_CARD_INDEXES) - {"idx_cards_keywords"}
            connection = FakeConnection(columns, indexes)
            with self.assertRaises(SystemExit) as stopped:
                module.require_schema(connection)
            message = str(stopped.exception)
            self.assertIn("coluna cards.keywords", message, name)
            self.assertIn("índice idx_cards_keywords", message, name)
            self.assertIn("bin/migrate.dart", message, name)
            self.assert_read_only(connection)

    def test_sources_have_no_schema_ddl(self) -> None:
        for name in self.MODULES:
            source = (BIN / f"{name}.py").read_text(encoding="utf-8").upper()
            for ddl in ("ALTER TABLE", "CREATE INDEX", "CREATE TABLE", "DROP "):
                self.assertNotIn(ddl, source, f"{name}: {ddl}")

    def test_fast_sync_requires_what_its_upsert_writes(self) -> None:
        module = _load("sync_cards_full_fast")
        self.assertEqual(
            set(module.REQUIRED_CARD_COLUMNS),
            {"color_identity", "power", "toughness", "keywords", "is_reserved", "oracle_id", "cmc"},
        )


if __name__ == "__main__":
    unittest.main()
