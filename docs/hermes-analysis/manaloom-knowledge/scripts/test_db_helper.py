#!/usr/bin/env python3
"""Tests for PostgreSQL environment resolution."""

from __future__ import annotations

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
DB_HELPER_PATH = SCRIPT_DIR / "db_helper.py"


def load_db_helper():
    spec = importlib.util.spec_from_file_location("db_helper_under_test", DB_HELPER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DbHelperTest(unittest.TestCase):
    def test_explicit_db_parts_win_over_loaded_dotenv_database_url(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = Path(tmpdir)
            server_dir = temp_root / "server"
            server_dir.mkdir()
            (server_dir / ".env").write_text(
                "DATABASE_URL=postgres://old_user:old_pass@old.example:5433/old_db\n",
                encoding="utf-8",
            )
            env = {
                "DB_HOST": "127.0.0.1",
                "DB_PORT": "15432",
                "DB_NAME": "halder",
                "DB_USER": "postgres",
                "DB_PASS": "secret",
            }
            clear_keys = [
                "DATABASE_URL",
                "PGHOST",
                "PGPORT",
                "PGDATABASE",
                "PGUSER",
                "PGPASSWORD",
            ]
            with mock.patch.dict(os.environ, env, clear=False):
                for key in clear_keys:
                    os.environ.pop(key, None)
                cwd = Path.cwd()
                try:
                    os.chdir(temp_root)
                    db_helper = load_db_helper()
                    self.assertEqual(
                        db_helper.sanitized_database_target(),
                        "127.0.0.1:15432/halder",
                    )
                finally:
                    os.chdir(cwd)


if __name__ == "__main__":
    unittest.main()
