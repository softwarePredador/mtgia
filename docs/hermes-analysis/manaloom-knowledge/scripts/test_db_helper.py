#!/usr/bin/env python3
"""Tests for PostgreSQL environment resolution.

O helper só aceita configuração explícita, nunca carrega um .env achado
subindo diretórios, exige confirmação para host fora do loopback e falha
fechado sem mostrar a URL, o host nem a senha.
"""

from __future__ import annotations

import importlib.util
import os
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
DB_HELPER_PATH = SCRIPT_DIR / "db_helper.py"

APPROVAL = "I_HAVE_EXPLICIT_APPROVAL"
SECRET = "senha-que-nao-pode-vazar"
DB_KEYS = (
    "DATABASE_URL",
    "DB_HOST",
    "DB_PORT",
    "DB_NAME",
    "DB_USER",
    "DB_PASS",
    "PGHOST",
    "PGPORT",
    "PGDATABASE",
    "PGUSER",
    "PGPASSWORD",
    "PGHOSTADDR",
    "PGSERVICE",
    "MANALOOM_POSTGRES_ENV",
    "MANALOOM_CONFIRM_POSTGRES_READS",
    "MANALOOM_CONFIRM_POSTGRES_WRITES",
)


def load_db_helper(path: Path = DB_HELPER_PATH):
    spec = importlib.util.spec_from_file_location("db_helper_under_test", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DbHelperTest(unittest.TestCase):
    def setUp(self) -> None:
        # Cada teste começa sem nenhuma configuração de banco no ambiente.
        self._saved = {key: os.environ.pop(key) for key in DB_KEYS if key in os.environ}
        self._cwd = Path.cwd()
        self.db_helper = load_db_helper()

    def tearDown(self) -> None:
        os.chdir(self._cwd)
        for key in DB_KEYS:
            os.environ.pop(key, None)
        os.environ.update(self._saved)

    def set_env(self, **values: str) -> None:
        os.environ.update(values)

    def assert_refused_without_leak(self, *, access: str = "read") -> str:
        with self.assertRaises(self.db_helper.DatabaseConfigError) as err:
            self.db_helper.get_database_url(access=access)
        message = str(err.exception)
        self.assertNotIn(SECRET, message)
        self.assertNotIn("postgres://", message)
        self.assertNotIn("db.example.com", message)
        self.assertNotIn("10.0.0.5", message)
        return message

    # --- nenhum .env achado subindo diretórios --------------------------------

    def test_never_loads_a_dotenv_found_by_climbing(self) -> None:
        # O arquivo aponta para loopback: se fosse carregado, seria aceito sem
        # confirmação, e o teste pegaria a volta da busca.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            leaked = f"DATABASE_URL=postgres://prod:{SECRET}@127.0.0.1:5432/halder\n"
            for folder in (root, root / "server", root / "a", root / "a" / "server"):
                folder.mkdir(parents=True, exist_ok=True)
                (folder / ".env").write_text(leaked, encoding="utf-8")
            nested = root / "a" / "b" / "c"
            nested.mkdir(parents=True)
            os.chdir(nested)

            message = self.assert_refused_without_leak()

        self.assertIn("Nenhum .env é procurado", message)
        self.assertNotIn("DATABASE_URL", {k for k in os.environ if os.environ[k]})

    def test_never_loads_a_dotenv_above_the_script_itself(self) -> None:
        # O helper rodando de um worktree achava o server/.env do checkout
        # principal pelos diretórios acima do próprio script.
        with tempfile.TemporaryDirectory() as tmp:
            checkout = Path(tmp) / "checkout"
            (checkout / "server").mkdir(parents=True)
            (checkout / "server" / ".env").write_text(
                f"DB_HOST=127.0.0.1\nDB_NAME=halder\nDB_USER=postgres\nDB_PASS={SECRET}\n",
                encoding="utf-8",
            )
            scripts = checkout / "worktree" / "docs" / "scripts"
            scripts.mkdir(parents=True)
            shutil.copy(DB_HELPER_PATH, scripts / "db_helper.py")
            self.db_helper = load_db_helper(scripts / "db_helper.py")
            os.chdir(scripts)

            message = self.assert_refused_without_leak()
            self.assertIn("Nenhum .env é procurado", message)

        for key in ("DB_HOST", "DB_NAME", "DB_USER", "DB_PASS"):
            self.assertNotIn(key, os.environ, key)

    def test_explicit_db_parts_win_and_the_local_dotenv_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = Path(tmpdir)
            (temp_root / "server").mkdir()
            (temp_root / "server" / ".env").write_text(
                f"DATABASE_URL=postgres://old_user:{SECRET}@db.example.com:5433/old_db\n",
                encoding="utf-8",
            )
            os.chdir(temp_root)
            self.set_env(
                DB_HOST="127.0.0.1",
                DB_PORT="15432",
                DB_NAME="halder",
                DB_USER="postgres",
                DB_PASS="secret",
            )
            self.assertEqual(
                self.db_helper.sanitized_database_target(),
                "127.0.0.1:15432/halder",
            )

    # --- arquivo só quando nomeado ---------------------------------------------

    def test_env_file_is_read_only_when_named(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / "banco-local.env"
            env_file.write_text(
                "DATABASE_URL=postgres://postgres@127.0.0.1:55451/brewtact\n",
                encoding="utf-8",
            )
            os.chdir(tmp)
            self.assert_refused_without_leak()

            self.set_env(MANALOOM_POSTGRES_ENV=str(env_file))
            self.assertEqual(
                self.db_helper.get_database_url(),
                "postgres://postgres@127.0.0.1:55451/brewtact",
            )
        self.assertNotIn("DATABASE_URL", os.environ)

    def test_named_env_file_that_does_not_exist_fails_closed(self) -> None:
        self.set_env(MANALOOM_POSTGRES_ENV="/caminho/que/nao/existe.env")
        message = self.assert_refused_without_leak()
        self.assertIn("MANALOOM_POSTGRES_ENV", message)

    def test_named_env_file_with_remote_parts_still_needs_approval(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / "producao.env"
            env_file.write_text(
                f"DB_HOST=db.example.com\nDB_NAME=halder\nDB_USER=postgres\nDB_PASS={SECRET}\n",
                encoding="utf-8",
            )
            self.set_env(MANALOOM_POSTGRES_ENV=str(env_file))
            self.assert_refused_without_leak()
            self.set_env(MANALOOM_CONFIRM_POSTGRES_READS=APPROVAL)
            self.assertIn("db.example.com", self.db_helper.get_database_url())

    # --- loopback e confirmação ------------------------------------------------

    def test_loopback_needs_no_approval(self) -> None:
        for url in (
            f"postgres://postgres:{SECRET}@127.0.0.1:5432/db",
            "postgresql://postgres@localhost:5432/db",
            "postgresql://postgres@LOCALHOST/db",
            "postgresql://postgres@[::1]:5432/db",
            "postgresql://postgres@127.1.2.3:5432/db",
            "postgresql://postgres@127.0.0.1:5432,localhost:5433/db",
        ):
            self.set_env(DATABASE_URL=url)
            self.assertEqual(self.db_helper.get_database_url(), url, url)
            self.assertEqual(
                self.db_helper.get_database_url(access="write"), url, url
            )

    def test_parts_without_password_work_on_loopback(self) -> None:
        self.set_env(DB_HOST="127.0.0.1", DB_PORT="55451", DB_NAME="db", DB_USER="postgres")
        self.assertEqual(
            self.db_helper.get_database_url(),
            "postgres://postgres@127.0.0.1:55451/db",
        )

    def test_remote_host_requires_explicit_approval(self) -> None:
        self.set_env(DATABASE_URL=f"postgres://prod:{SECRET}@db.example.com:5432/halder")
        message = self.assert_refused_without_leak()
        self.assertIn("MANALOOM_CONFIRM_POSTGRES_READS", message)

        for wrong in ("1", "yes", "true", "I_HAVE_EXPLICIT_APPROVAL ", "i_have_explicit_approval"):
            self.set_env(MANALOOM_CONFIRM_POSTGRES_READS=wrong)
            self.assert_refused_without_leak()

        self.set_env(MANALOOM_CONFIRM_POSTGRES_READS=APPROVAL)
        self.assertIn("db.example.com", self.db_helper.get_database_url())
        # Leitura não autoriza escrita.
        message = self.assert_refused_without_leak(access="write")
        self.assertIn("MANALOOM_CONFIRM_POSTGRES_WRITES", message)

        os.environ.pop("MANALOOM_CONFIRM_POSTGRES_READS")
        self.set_env(MANALOOM_CONFIRM_POSTGRES_WRITES=APPROVAL)
        self.assertIn("db.example.com", self.db_helper.get_database_url())
        self.assertIn("db.example.com", self.db_helper.get_database_url(access="write"))

    def test_lookalike_hosts_are_not_loopback(self) -> None:
        for host in (
            "localhost.example.com",
            "127.0.0.1.example.com",
            "0.0.0.0",
            "10.0.0.5",
            "192.168.0.10",
            "evolution_manaloom-postgres",
            "::ffff:10.0.0.5",
        ):
            with self.subTest(host=host):
                self.assertFalse(self.db_helper.is_loopback_host(host), host)
                display = f"[{host}]" if ":" in host else host
                self.set_env(DATABASE_URL=f"postgres://u:{SECRET}@{display}:5432/db")
                self.assert_refused_without_leak()

    def test_libpq_overrides_cannot_disguise_a_remote_host(self) -> None:
        for url in (
            "postgresql://u@127.0.0.1:5432/db?host=db.example.com",
            "postgresql://u@localhost/db?hostaddr=10.0.0.5",
            "postgresql://u@127.0.0.1/db?service=producao",
            "postgresql://u@127.0.0.1:5432,db.example.com:5432/db",
            "postgresql:///db",
            "postgresql://u@%2Fvar%2Frun%2Fpostgresql/db",
            "mysql://u@127.0.0.1/db",
        ):
            with self.subTest(url=url):
                self.set_env(DATABASE_URL=url)
                self.assert_refused_without_leak()

    def test_environment_hostaddr_and_service_count_too(self) -> None:
        self.set_env(DATABASE_URL="postgresql://u@127.0.0.1:5432/db", PGHOSTADDR="10.0.0.5")
        self.assert_refused_without_leak()
        os.environ.pop("PGHOSTADDR")
        self.set_env(PGSERVICE="producao")
        self.assert_refused_without_leak()
        os.environ.pop("PGSERVICE")
        self.assertEqual(
            self.db_helper.get_database_url(), "postgresql://u@127.0.0.1:5432/db"
        )

    # --- run_sql ---------------------------------------------------------------

    def test_run_sql_write_on_a_remote_host_needs_the_write_approval(self) -> None:
        self.set_env(
            DATABASE_URL=f"postgres://prod:{SECRET}@db.example.com:5432/halder",
            MANALOOM_CONFIRM_POSTGRES_READS=APPROVAL,
        )

        class FakeCursor:
            rowcount = 1

            def execute(self, sql):
                self.sql = sql

            def fetchone(self):
                return (7,)

            def close(self):
                pass

        class FakeConnection:
            autocommit = False

            def cursor(self):
                return FakeCursor()

            def close(self):
                pass

        with mock.patch.object(
            self.db_helper.psycopg2, "connect", return_value=FakeConnection()
        ) as fake_connect:
            self.assertEqual(self.db_helper.run_sql("SELECT count(*) FROM cards"), "7")
            self.assertEqual(fake_connect.call_count, 1)
            for write in (
                "INSERT INTO cards (name) VALUES ('x')",
                "SELECT 1; DELETE FROM cards",
                "WITH x AS (DELETE FROM cards RETURNING 1) SELECT 1",
            ):
                with self.subTest(sql=write):
                    with self.assertRaises(self.db_helper.DatabaseConfigError):
                        self.db_helper.run_sql(write)
            self.assertEqual(fake_connect.call_count, 1, "nenhuma conexão para escrita")

            self.set_env(MANALOOM_CONFIRM_POSTGRES_WRITES=APPROVAL)
            self.assertEqual(
                self.db_helper.run_sql("INSERT INTO cards (name) VALUES ('x')"), "1"
            )

    def test_run_sql_without_config_raises_instead_of_returning_empty(self) -> None:
        with mock.patch.object(self.db_helper.psycopg2, "connect") as fake_connect:
            with self.assertRaises(self.db_helper.DatabaseConfigError):
                self.db_helper.run_sql("SELECT 1")
        fake_connect.assert_not_called()


if __name__ == "__main__":
    unittest.main()
