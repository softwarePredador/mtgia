#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "manaloom_ops_daemon.py"
    spec = importlib.util.spec_from_file_location("manaloom_ops_daemon", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ManaLoomOpsDaemonTest(unittest.TestCase):
    def test_base_env_loads_database_values_from_env_file(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            env_file.write_text("DB_HOST=db.example\nDB_NAME=mana\n", encoding="utf-8")
            original_env_file = module.ENV_FILE
            try:
                module.ENV_FILE = env_file
                env = module._base_env()
            finally:
                module.ENV_FILE = original_env_file
        self.assertEqual(env["DB_HOST"], "db.example")
        self.assertEqual(env["DB_NAME"], "mana")

    def test_collect_boot_jobs_runs_pull_for_pending_events(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            planned = module._collect_boot_jobs(
                {"DB_HOST": "example"},
                knowledge_db_path=Path(tmp) / "knowledge.db",
                knowledge_db_has_validator_tables=lambda _: True,
                pending_learning_events_count=lambda _: 2,
            )
        self.assertIn(("pull_learning_events", "pending_learning_events=2"), planned)

    def test_collect_boot_jobs_runs_preflight_for_missing_tables(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            planned = module._collect_boot_jobs(
                {},
                knowledge_db_path=Path(tmp) / "knowledge.db",
                knowledge_db_has_validator_tables=lambda _: False,
                pending_learning_events_count=lambda _: 0,
            )
        self.assertIn(("master_optimizer_preflight", "knowledge_db_missing_validator_tables"), planned)

    def test_knowledge_db_has_validator_tables_checks_required_tables(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            with sqlite3.connect(db_path) as conn:
                conn.execute("CREATE TABLE decks (id INTEGER PRIMARY KEY)")
                self.assertFalse(module._knowledge_db_has_validator_tables(db_path))
                conn.execute("CREATE TABLE deck_cards (id INTEGER PRIMARY KEY)")
            self.assertTrue(module._knowledge_db_has_validator_tables(db_path))


if __name__ == "__main__":
    unittest.main()
