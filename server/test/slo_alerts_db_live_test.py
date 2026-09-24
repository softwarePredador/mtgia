#!/usr/bin/env python3
"""BT-OBS-001: a leitura do PostgreSQL do avaliador de SLO, num banco descartável.

Requer RUN_SCHEMA_DB_TESTS=1 e as variáveis DB_* de um PostgreSQL descartável
em loopback, já migrado. Confere que a leitura roda em transação READ ONLY e
devolve conexões e o frescor do catálogo pelo sync_log.
"""

from __future__ import annotations

import datetime as dt
import importlib.util
import os
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "server" / "bin" / "manaloom_slo_alerts.py"
ENABLED = os.environ.get("RUN_SCHEMA_DB_TESTS") == "1"


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_obs_001_slo_db", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@unittest.skipUnless(ENABLED, "Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.")
class PostgresReadTest(unittest.TestCase):
    def setUp(self) -> None:
        if os.environ.get("DB_HOST", "127.0.0.1") not in {"127.0.0.1", "localhost", "::1"}:
            self.fail("RUN_SCHEMA_DB_TESTS só roda em banco loopback")
        import psycopg2

        self.slo = _load_module()
        self.env = dict(os.environ)
        self.connection = psycopg2.connect(
            host=self.env.get("DB_HOST", "127.0.0.1"),
            port=int(self.env.get("DB_PORT", "5432")),
            dbname=self.env["DB_NAME"],
            user=self.env["DB_USER"],
            password=self.env.get("DB_PASS", ""),
        )
        self.connection.autocommit = True
        with self.connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO sync_log (sync_type, status, started_at, finished_at) "
                "VALUES ('cards', 'success', now() - interval '2 days 1 minute', "
                "now() - interval '2 days') RETURNING id"
            )
            self.row = cursor.fetchone()[0]

    def tearDown(self) -> None:
        with self.connection.cursor() as cursor:
            cursor.execute("DELETE FROM sync_log WHERE id = %s", (self.row,))
        self.connection.close()

    def test_reads_connections_and_catalog_in_read_only(self) -> None:
        result = self.slo.read_postgres(self.env)
        self.assertEqual(result["transaction_read_only"], "on")
        self.assertGreaterEqual(result["connections_total"], 1)
        self.assertGreater(result["max_connections"], result["connections_total"])
        cards = dt.datetime.strptime(
            result["catalog_last_success"]["cards"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=dt.timezone.utc)
        # O máximo do sync_log é no mínimo tão recente quanto a linha do teste.
        age = dt.datetime.now(dt.timezone.utc) - cards
        self.assertLessEqual(age.total_seconds(), 2 * 86400 + 60)


if __name__ == "__main__":
    unittest.main()
