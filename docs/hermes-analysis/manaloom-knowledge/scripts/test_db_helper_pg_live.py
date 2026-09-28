#!/usr/bin/env python3
"""db_helper contra um PostgreSQL descartável de verdade.

Com DATABASE_URL em loopback, o helper conecta e lê sem confirmação. Com um
alvo fora do loopback e sem confirmação, recusa antes de abrir qualquer
conexão, e a mensagem não mostra a URL nem a senha.

Requer RUN_HERMES_DB_HELPER_PG_TESTS=1 e DATABASE_URL de um PostgreSQL
descartável em loopback; o teste recusa qualquer outro alvo antes de tocar no
banco.
"""

from __future__ import annotations

import os
import unittest
from unittest import mock

import db_helper

SECRET = "senha-que-nao-pode-vazar"


class DbHelperPgLiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if os.environ.get("RUN_HERMES_DB_HELPER_PG_TESTS") != "1":
            raise unittest.SkipTest(
                "Requer RUN_HERMES_DB_HELPER_PG_TESTS=1 e DATABASE_URL local."
            )
        url = os.environ.get("DATABASE_URL", "")
        if not url or not db_helper.targets_loopback_only(url):
            raise AssertionError("o teste só roda contra um banco em loopback")

    def test_loopback_database_connects_and_reads(self) -> None:
        self.assertEqual(db_helper.run_sql("SELECT 1"), "1")
        with db_helper.connect() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT current_database()")
                self.assertTrue(cur.fetchone()[0])
        target = db_helper.sanitized_database_target()
        self.assertTrue(target.startswith("127.0.0.1:"), target)

    def test_remote_target_is_refused_before_any_connection(self) -> None:
        loopback_url = os.environ["DATABASE_URL"]
        real_connect = db_helper.psycopg2.connect
        with mock.patch.dict(
            os.environ,
            {"DATABASE_URL": f"postgres://prod:{SECRET}@10.255.255.1:5432/halder"},
        ), mock.patch.object(
            db_helper.psycopg2, "connect", side_effect=real_connect
        ) as spy:
            for call in (
                lambda: db_helper.connect(),
                lambda: db_helper.run_sql("SELECT 1"),
                lambda: db_helper.sanitized_database_target(),
            ):
                with self.assertRaises(db_helper.DatabaseConfigError) as err:
                    call()
                self.assertNotIn(SECRET, str(err.exception))
                self.assertNotIn("10.255.255.1", str(err.exception))
            spy.assert_not_called()
        self.assertEqual(os.environ["DATABASE_URL"], loopback_url)


if __name__ == "__main__":
    unittest.main()
