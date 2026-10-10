#!/usr/bin/env python3
"""BT-GATE-003: o produtor do receipt de release, testado só em loopback.

O produtor (`manaloom_deck_ai_learning_release_receipt.sh`) lê o PostgreSQL de
produção em modo somente leitura. Este teste nunca toca produção nem procura
credencial: ele sobe um PostgreSQL descartável em 127.0.0.1, num diretório
temporário, e troca o túnel SSH (`with_new_server_pg.sh`) por um dublê que só
fala com esse loopback e só em transação somente leitura. O resto do produtor é
o código real: o SQL de migrations gerado a partir da política e do manifesto, o
preflight, a montagem do receipt v2 e a validação pelo validador.

Sem `initdb`/`pg_ctl` o teste FALHA, não pula: skip não recebe crédito (D-17).
"""

from __future__ import annotations

import glob
import json
import os
import shutil
import socket
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PRODUCER = "scripts/manaloom_deck_ai_learning_release_receipt.sh"
VALIDATOR = "scripts/manaloom_deck_ai_learning_receipt_validator.py"
POLICY = "server/config/deck_ai_learning_gate_policy.json"
KNOWLEDGE_DB = "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
HOST_KEY = "SHA256:" + ("A" * 43)

WRAPPER_DOUBLE = """#!/usr/bin/env bash
# Dublê do túnel: só loopback descartável, só leitura, só psql.
set -euo pipefail
[[ "${1:-}" == "--read-only" ]] || { echo "dublê: só --read-only" >&2; exit 2; }
shift
[[ "$(basename -- "$1")" == "psql" ]] || { echo "dublê: só psql" >&2; exit 2; }
shift
export PGOPTIONS="-c default_transaction_read_only=on"
exec psql -h 127.0.0.1 -p "$MANALOOM_TEST_LOOPBACK_PORT" -U postgres -d halder "$@"
"""

AUDIT_DOUBLE = """#!/usr/bin/env bash
set -euo pipefail
python3 - "$MANALOOM_TEST_AUDIT_FIXTURE" "${MANALOOM_PG_HERMES_SQLITE_CONTRACT_AUDIT_OUT_PREFIX}.json" <<'PY'
import json
import sys
from datetime import datetime, timezone

payload = json.load(open(sys.argv[1], encoding="utf-8"))
payload["generated_at"] = datetime.now(timezone.utc).isoformat()
json.dump(payload, open(sys.argv[2], "w", encoding="utf-8"), sort_keys=True)
PY
echo "auditoria canônica simulada sobre o loopback descartável"
"""


def _pg_bin(name: str) -> str:
    found = shutil.which(name)
    if found:
        return found
    candidates = sorted(glob.glob(f"/usr/lib/postgresql/*/bin/{name}"), reverse=True)
    if candidates:
        return candidates[0]
    raise AssertionError(
        f"{name} ausente: o produtor só é testado contra PostgreSQL descartável em loopback"
    )


def _free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


class DisposablePostgres:
    """PostgreSQL em 127.0.0.1, num diretório temporário, removido no fim."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.data = root / "data"
        self.socket_dir = root / "sock"
        self.port = _free_port()
        self.as_root = os.geteuid() == 0

    def _run(self, *argv: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        command = list(argv)
        if self.as_root:
            command = ["runuser", "-u", "postgres", "--", *command]
        return subprocess.run(command, text=True, capture_output=True, check=check)

    def start(self) -> None:
        self.socket_dir.mkdir()
        self.root.chmod(0o755)
        if self.as_root:
            shutil.chown(self.root, "postgres")
            shutil.chown(self.socket_dir, "postgres")
        self._run(
            _pg_bin("initdb"), "-D", str(self.data), "-U", "postgres",
            "--auth=trust", "--encoding=UTF8",
        )
        self._run(
            _pg_bin("pg_ctl"), "-D", str(self.data), "-l", str(self.root / "pg.log"),
            "-o", f"-p {self.port} -c listen_addresses=127.0.0.1 -k {self.socket_dir}",
            "-w", "start",
        )
        self.psql("-d", "postgres", "-c", "CREATE DATABASE halder")

    def stop(self) -> None:
        self._run(_pg_bin("pg_ctl"), "-D", str(self.data), "-m", "fast", "stop", check=False)

    def psql(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [_pg_bin("psql"), "-h", "127.0.0.1", "-p", str(self.port), "-U", "postgres",
             "-X", "-qAt", "-v", "ON_ERROR_STOP=1", *args],
            text=True, capture_output=True, check=True,
        )

    def set_applied(self, versions: list[str]) -> None:
        values = ",".join(f"('{version}')" for version in versions)
        self.psql(
            "-d", "halder", "-c",
            "DROP TABLE IF EXISTS public.schema_migrations; "
            "CREATE TABLE public.schema_migrations (version text PRIMARY KEY); "
            f"INSERT INTO public.schema_migrations VALUES {values};",
        )


class ReleaseProducerLoopbackTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._pg_dir = tempfile.TemporaryDirectory(prefix="manaloom-loopback-pg.")
        cls.pg = DisposablePostgres(Path(cls._pg_dir.name))
        cls.pg.start()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.pg.stop()
        cls._pg_dir.cleanup()

    def setUp(self) -> None:
        repo_dir = tempfile.TemporaryDirectory(prefix="manaloom-producer-repo.")
        self.addCleanup(repo_dir.cleanup)
        self.repo = Path(repo_dir.name)
        durable_parent = Path.home() / ".cache"
        durable_parent.mkdir(parents=True, exist_ok=True)
        evidence = tempfile.TemporaryDirectory(prefix="manaloom-producer-evidence.", dir=durable_parent)
        self.addCleanup(evidence.cleanup)
        self.evidence_root = Path(evidence.name)
        self.latest = "076"
        self._build_repo(self.latest)
        self.credential_file = self.repo.parent / f"{self.repo.name}.server.env"
        self.credential_file.write_text(
            "EASYPANEL_SERVER_IP=203.0.113.10\nDB_NAME=halder\nDB_USER=postgres\nDB_PASS=nao-usado\n",
            encoding="utf-8",
        )
        self.addCleanup(self.credential_file.unlink, missing_ok=True)
        self.audit_fixture = self.repo.parent / f"{self.repo.name}.audit.json"
        self.addCleanup(self.audit_fixture.unlink, missing_ok=True)
        self.pg.set_applied([f"{n:03d}" for n in range(1, int(self.latest) + 1)])

    # --- fixtures ----------------------------------------------------------

    def git(self, *args: str) -> str:
        return subprocess.run(
            ["git", "-C", str(self.repo), *args], check=True, text=True, capture_output=True
        ).stdout.strip()

    def write(self, relative: str, text: str, mode: int | None = None) -> None:
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        if mode is not None:
            path.chmod(mode)

    def _build_repo(self, latest: str) -> None:
        self.git("init", "-q")
        self.git("config", "user.name", "ManaLoom Test")
        self.git("config", "user.email", "manaloom-test@example.invalid")
        for relative in (PRODUCER, VALIDATOR, POLICY):
            self.write(relative, (REPO_ROOT / relative).read_text(encoding="utf-8"), 0o755)
        self.write(".gitignore", f"{KNOWLEDGE_DB}\n__pycache__/\n")
        self.write(KNOWLEDGE_DB, "cache hermes descartável\n")
        self.write("server/bin/with_new_server_pg.sh", WRAPPER_DOUBLE, 0o755)
        self.write("scripts/manaloom_pg_hermes_sqlite_contract_audit.sh", AUDIT_DOUBLE, 0o755)
        self.set_latest(latest)

    def set_latest(self, latest: str) -> None:
        self.latest = latest
        self.write(
            "project_logic_manifest.json",
            json.dumps({"source_digest_sha256": "a" * 64, "database": {"latest_migration": latest}}) + "\n",
        )
        versions = ",\n".join(f"  Migration(version: '{n:03d}')" for n in range(1, int(latest) + 1))
        self.write("server/bin/migrate.dart", f"final migrations = [\n{versions}\n];\n")
        self.git("add", "--all")
        self.git("commit", "-q", "--allow-empty", "--no-gpg-sign", "-m", f"latest {latest}")

    def write_audit_fixture(self) -> None:
        policy = json.loads((self.repo / POLICY).read_text(encoding="utf-8"))
        names = [item for item in policy["release_check_ids"] if item != "pg_schema_migrations.range"]
        self.audit_fixture.write_text(
            json.dumps(
                {
                    "generated_at": "2026-10-10T12:00:00+00:00",
                    "status": "pass",
                    "postgres_target": f"127.0.0.1:{self.pg.port}/halder",
                    "sqlite_db": str((self.repo / KNOWLEDGE_DB).resolve()),
                    "mutations_performed": [],
                    "summary": {"check_count": len(names), "status_counts": {"pass": len(names)}},
                    "checks": [{"name": n, "status": "pass", "detail": "ok"} for n in names],
                },
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )

    def environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(
            {
                "MANALOOM_NEW_SERVER_ENV": str(self.credential_file),
                "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256": HOST_KEY,
                "MANALOOM_TEST_LOOPBACK_PORT": str(self.pg.port),
                "MANALOOM_TEST_AUDIT_FIXTURE": str(self.audit_fixture),
                "PYTHONDONTWRITEBYTECODE": "1",
            }
        )
        for key in ("MANALOOM_CONFIRM_LIVE_MUTATIONS", "MANALOOM_CONFIRM_POSTGRES_WRITES"):
            environment.pop(key, None)
        return environment

    def produce(self) -> subprocess.CompletedProcess[str]:
        self.write_audit_fixture()
        return subprocess.run(
            ["bash", str(self.repo / PRODUCER), "--evidence-root", str(self.evidence_root)],
            cwd=self.repo, env=self.environment(), text=True, capture_output=True,
        )

    def receipts(self) -> list[Path]:
        return sorted(self.evidence_root.glob("*/deck-ai-learning-release-receipt-v2.json"))

    def validate(self, receipt: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(self.repo / VALIDATOR), "validate-release", "--receipt", str(receipt),
             "--policy", str(self.repo / POLICY), "--repo", str(self.repo),
             "--credential-file", str(self.credential_file), "--max-age-hours", "1"],
            env=self.environment(), text=True, capture_output=True,
        )

    # --- testes ------------------------------------------------------------

    def test_producer_emits_a_receipt_the_validator_accepts_up_to_the_manifest_migration(self) -> None:
        result = self.produce()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        receipts = self.receipts()
        self.assertEqual(len(receipts), 1)
        payload = json.loads(receipts[0].read_text(encoding="utf-8"))
        self.assertEqual(payload["status"], "PASS")
        schema = payload["target"]["schema"]
        self.assertEqual(schema["required_range"], "038-076")
        self.assertEqual(schema["latest_applied"], "076")
        self.assertEqual(schema["pending_versions"], [])
        self.assertTrue(payload["safety"]["transaction_read_only"])
        self.assertEqual(payload["safety"]["mutations_performed"], [])
        accepted = self.validate(receipts[0])
        self.assertEqual(accepted.returncode, 0, accepted.stdout + accepted.stderr)

    def test_unapplied_manifest_migration_blocks_the_receipt(self) -> None:
        self.pg.set_applied([f"{n:03d}" for n in range(1, 76)])  # falta a 076
        result = self.produce()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.receipts(), [])

    def test_a_planned_077_needs_no_policy_edit_and_is_enforced(self) -> None:
        self.set_latest("077")
        blocked = self.produce()
        self.assertNotEqual(blocked.returncode, 0, "DB na 076 não prova um release da 077")
        self.assertEqual(self.receipts(), [])
        self.pg.set_applied([f"{n:03d}" for n in range(1, 78)])
        result = self.produce()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        payload = json.loads(self.receipts()[0].read_text(encoding="utf-8"))
        self.assertEqual(payload["target"]["schema"]["required_range"], "038-077")
        self.assertEqual(payload["target"]["schema"]["latest_applied"], "077")

    def test_manifest_and_migrate_dart_must_agree(self) -> None:
        self.set_latest("076")
        manifest = self.repo / "project_logic_manifest.json"
        manifest.write_text(
            json.dumps({"source_digest_sha256": "a" * 64, "database": {"latest_migration": "075"}}) + "\n",
            encoding="utf-8",
        )
        self.git("add", "--all")
        self.git("commit", "-q", "--no-gpg-sign", "-m", "drift")
        result = self.produce()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.receipts(), [])

    def test_validator_rejects_a_receipt_when_the_manifest_moves_on(self) -> None:
        result = self.produce()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        receipt = self.receipts()[0]
        self.set_latest("077")
        rejected = self.validate(receipt)
        self.assertNotEqual(rejected.returncode, 0)

    def test_loopback_double_is_read_only(self) -> None:
        wrapper = self.repo / "server/bin/with_new_server_pg.sh"
        attempt = subprocess.run(
            ["bash", str(wrapper), "--read-only", "psql", "-X", "-qAt", "-c", "CREATE TABLE public.escrita()"],
            env=self.environment(), text=True, capture_output=True,
        )
        self.assertNotEqual(attempt.returncode, 0)
        self.assertIn("read-only", attempt.stderr)

    def test_producer_source_never_requests_write_access_or_ddl(self) -> None:
        text = (REPO_ROOT / PRODUCER).read_text(encoding="utf-8")
        self.assertNotIn("--write-approved", text)
        self.assertEqual(text.count("with_new_server_pg.sh\" --read-only"), text.count("with_new_server_pg.sh\""))
        generated = subprocess.run(
            ["python3", str(REPO_ROOT / VALIDATOR), "migration-status-sql",
             "--policy", str(REPO_ROOT / POLICY), "--repo", str(REPO_ROOT)],
            text=True, capture_output=True, check=True,
        ).stdout.upper()
        for forbidden in ("INSERT ", "UPDATE ", "DELETE ", "CREATE ", "ALTER ", "DROP ", "TRUNCATE "):
            self.assertNotIn(forbidden, generated)
        for relative in (PRODUCER, POLICY):
            self.assertNotIn("058", (REPO_ROOT / relative).read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
