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
import time
import unittest
import uuid
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
        self.marker = uuid.uuid4().hex[:12]
        with self.connection.cursor() as cursor:
            cursor.execute(
                "SELECT key, value FROM sync_state WHERE key = ANY(%s)",
                (list(self.slo.CATALOG_FRESHNESS_KEYS),),
            )
            self.saved_state = cursor.fetchall()
            cursor.execute(
                "INSERT INTO sync_state (key, value) VALUES "
                "('catalog_reference_source_updated_at', %s) "
                "ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
                ((dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=2)).isoformat(),),
            )
            cursor.execute(
                "INSERT INTO sync_log (sync_type, status, started_at, finished_at) "
                "VALUES ('catalog_reference', 'skipped', now() - interval '1 minute', now()) "
                "RETURNING id"
            )
            self.row = cursor.fetchone()[0]

    def tearDown(self) -> None:
        with self.connection.cursor() as cursor:
            cursor.execute("DELETE FROM sync_log WHERE id = %s", (self.row,))
            cursor.execute("DELETE FROM cards WHERE name = %s", (f"BT-CAT-03 {self.marker}",))
            cursor.execute(
                "DELETE FROM sync_state WHERE key = ANY(%s)",
                (list(self.slo.CATALOG_FRESHNESS_KEYS),),
            )
            for key, value in self.saved_state:
                cursor.execute(
                    "INSERT INTO sync_state (key, value) VALUES (%s, %s)", (key, value)
                )
        self.connection.close()

    def test_reads_connections_and_catalog_in_read_only(self) -> None:
        result = self.slo.read_postgres(self.env)
        self.assertEqual(result["transaction_read_only"], "on")
        self.assertGreaterEqual(result["connections_total"], 1)
        self.assertGreater(result["max_connections"], result["connections_total"])
        # BT-CAT-03: o frescor vem do sync_state do job de catálogo.
        freshness = result["catalog_freshness"]
        self.assertEqual(freshness["key"], "catalog_reference_source_updated_at")
        updated = dt.datetime.strptime(freshness["updated_at"], "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=dt.timezone.utc
        )
        age = dt.datetime.now(dt.timezone.utc) - updated
        self.assertAlmostEqual(age.total_seconds(), 2 * 86400, delta=120)
        finished = dt.datetime.strptime(
            result["catalog_job_last_finished_at"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=dt.timezone.utc)
        self.assertLessEqual(dt.datetime.now(dt.timezone.utc) - finished, dt.timedelta(minutes=2))

    def test_counts_rows_written_to_the_catalog_tables(self) -> None:
        import psycopg2

        before = self.slo.read_postgres(self.env)["catalog_writes_total"]
        # Conexão própria e fechada logo: a sessão manda as estatísticas ao sair
        # (uma sessão parada manda só a cada 10 s).
        writer = psycopg2.connect(
            host=self.env.get("DB_HOST", "127.0.0.1"),
            port=int(self.env.get("DB_PORT", "5432")),
            dbname=self.env["DB_NAME"],
            user=self.env["DB_USER"],
            password=self.env.get("DB_PASS", ""),
        )
        writer.autocommit = True
        with writer.cursor() as cursor:
            cursor.execute(
                "INSERT INTO cards (scryfall_id, name) VALUES (gen_random_uuid(), %s)",
                (f"BT-CAT-03 {self.marker}",),
            )
            cursor.execute(
                "UPDATE cards SET name = name WHERE name = %s", (f"BT-CAT-03 {self.marker}",)
            )
        writer.close()
        # Inserção e atualização contam as duas.
        deadline = time.monotonic() + 20
        total = before
        while time.monotonic() < deadline and total < before + 2:
            time.sleep(0.5)
            total = self.slo.read_postgres(self.env)["catalog_writes_total"]
        self.assertGreaterEqual(total, before + 2)


if __name__ == "__main__":
    unittest.main()
