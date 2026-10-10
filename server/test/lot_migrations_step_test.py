#!/usr/bin/env python3
"""S-05: o passo de migrations do lote de deploy (scripts/manaloom_lot_apply_migrations.sh).

Sem banco, sempre: o lote versionado (server/config/lot_migrations.json) contra o código
deste SHA, as recusas de lacuna e de lote (a 074 vai com a 067 e a 069, pela BT-DB-007),
as conferências do ledger de antes e de depois e as recusas antes de qualquer conexão.

Com RUN_SCHEMA_DB_TESTS=1 e a aprovação do PostgreSQL descartável
(MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES ou git config
manaloom.localGates.disposablePostgres=true): um PostgreSQL 17 descartável em loopback,
num diretório temporário e parado no fim, monta o banco da produção na 058 (o bootstrap
de 41bab49c9 do fixture e o migrate.dart até a 058). O script de verdade roda num
repositório descartável no origin/master, com o server/bin/with_new_server_pg.sh de
verdade: o ssh é trocado por um túnel falso que só repassa a porta para o banco
descartável, e o processo inteiro roda sob o sandbox do ensaio (rede só em localhost).
Nenhuma conexão sai da máquina. Este arquivo também é o túnel falso (`--fake-ssh`).
"""

from __future__ import annotations

import json
import os
import socket
import sys
import threading
from pathlib import Path


def _fake_ssh(argv: list[str]) -> int:
    """O `ssh -N -L 127.0.0.1:P:127.0.0.1:15432 alvo` do wrapper, para o banco descartável."""
    log = os.environ.get("FAKE_SSH_LOG")
    if log:
        with open(log, "a", encoding="utf-8") as handle:
            handle.write(json.dumps({"argv": argv}) + "\n")
    if "-N" not in argv or "-L" not in argv or "StrictHostKeyChecking=yes" not in argv:
        return 97
    local_host, local_port, remote_host, remote_port = argv[argv.index("-L") + 1].split(":")
    if (local_host, remote_host, remote_port) != ("127.0.0.1", "127.0.0.1", "15432"):
        return 97
    target = ("127.0.0.1", int(os.environ["FAKE_PG_PORT"]))
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((local_host, int(local_port)))
    server.listen(16)

    def pipe(source: socket.socket, sink: socket.socket) -> None:
        try:
            while True:
                data = source.recv(65536)
                if not data:
                    break
                sink.sendall(data)
        except OSError:
            pass
        finally:
            for side in (source, sink):
                try:
                    side.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass

    while True:
        client, _ = server.accept()
        try:
            upstream = socket.create_connection(target)
        except OSError:
            client.close()
            continue
        threading.Thread(target=pipe, args=(client, upstream), daemon=True).start()
        threading.Thread(target=pipe, args=(upstream, client), daemon=True).start()


if __name__ == "__main__" and sys.argv[1:2] == ["--fake-ssh"]:
    sys.exit(_fake_ssh(sys.argv[2:]))

import datetime as dt  # noqa: E402
import hashlib  # noqa: E402
import importlib.util  # noqa: E402
import shutil  # noqa: E402
import stat  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import unittest  # noqa: E402
from typing import Any  # noqa: E402

THIS_FILE = Path(__file__).resolve()
REPO_ROOT = THIS_FILE.parents[2]
SCRIPT = REPO_ROOT / "scripts" / "manaloom_lot_apply_migrations.sh"
POLICY = REPO_ROOT / "server" / "config" / "lot_migrations.json"
MIGRATE = REPO_ROOT / "server" / "bin" / "migrate.dart"
READINESS = REPO_ROOT / "server" / "lib" / "health_readiness_support.dart"
SETUP_058 = REPO_ROOT / "server" / "test" / "fixtures" / "schema_profiles" / "database_setup_058.sql"
SETUP_058_SHA256 = "857c56423da0519ef12326f8686a37bd8e0c58746338efa5e6c8538f7ab057a9"
ENABLED = os.environ.get("RUN_SCHEMA_DB_TESTS") == "1"
APPROVAL = "I_HAVE_EXPLICIT_APPROVAL"
FAKE_HOST_KEY = "SHA256:" + "A" * 43
# TEST-NET-1 (RFC 5737): não roteável; o túnel é falso de qualquer jeito.
FAKE_SERVER_IP = "192.0.2.10"
SEED = """
INSERT INTO users (id, username, email, password_hash) VALUES
  ('00000000-0000-4000-8000-000000000001', 'lote_ana', 'ana@example.invalid', 'x'),
  ('00000000-0000-4000-8000-000000000002', 'lote_beto', 'beto@example.invalid', 'x');
INSERT INTO cards (id, scryfall_id, name) VALUES
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000201', 'Carta A');
INSERT INTO decks (id, user_id, name, format) VALUES
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000001',
   'Deck do lote', 'commander');
INSERT INTO deck_cards (deck_id, card_id) VALUES
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000101');
INSERT INTO conversations (id, user_a_id, user_b_id) VALUES
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001',
   '00000000-0000-4000-8000-000000000002');
INSERT INTO direct_messages (conversation_id, sender_id, message) VALUES
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001', 'oi');
INSERT INTO trade_offers (id, sender_id, receiver_id) VALUES
  ('00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000001',
   '00000000-0000-4000-8000-000000000002');
"""


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


lot = _load("s05_lot_migrations", REPO_ROOT / "scripts" / "manaloom_lot_migrations.py")
promote = lot.promote


def _policy() -> dict[str, Any]:
    return json.loads(POLICY.read_text(encoding="utf-8"))


def _code() -> list[tuple[str, str]]:
    return lot.code_migrations(MIGRATE.read_text(encoding="utf-8"))


def _plan(policy: dict[str, Any]) -> dict[str, Any]:
    return lot.plan(policy, MIGRATE.read_text(encoding="utf-8"),
                    READINESS.read_text(encoding="utf-8"))


def _raw(entries: list[tuple[str, str]]) -> str:
    return "".join(f"{version}|{name}\n" for version, name in entries)


def _without(policy: dict[str, Any], version: str) -> dict[str, Any]:
    changed = json.loads(json.dumps(policy))
    changed["migrations"] = [item for item in changed["migrations"] if item != version]
    return changed


# ------------------------------------------------------------------ sem banco


class PlanTest(unittest.TestCase):
    def test_the_versioned_lot_is_this_code_from_058_to_the_last_migration(self) -> None:
        policy = _policy()
        planned = _plan(policy)
        self.assertEqual((planned["status"], planned["problems"]), ("PASS", []))
        code = _code()
        self.assertEqual(planned["from"], "058")
        self.assertEqual(planned["to"], code[-1][0])
        self.assertEqual([item["version"] for item in planned["migrations"]],
                         [version for version, _ in code if version > "058"])
        self.assertEqual(planned["readiness_requires"], planned["to"])
        # A 070 e a 071 não existem no código; a 074 vai com a 067 e a 069 (BT-DB-007).
        self.assertNotIn("070", policy["migrations"])
        self.assertEqual(policy["same_lot"][0]["version"], "074")
        self.assertEqual(policy["same_lot"][0]["with"], ["067", "069"])
        self.assertIn("BT-DB-007", policy["same_lot"][0]["rationale"])

    def test_a_gap_or_a_split_lot_is_refused(self) -> None:
        policy = _policy()
        last = policy["migrations"][-1]
        cases = {
            # Sem a 074, a 067 e a 069 deixariam chaves para users sem a trava de conta ativa.
            "sem a 074": (_without(policy, "074"), [
                f"lacuna: o migrate.dart tem a 074 entre a 058 e a {last}",
                "a 074 tem de ir no mesmo lote da 067 e da 069"]),
            "com a 070, que não existe": (
                dict(policy, migrations=sorted(policy["migrations"] + ["070"])),
                ["lacuna: a 070 está no lote e não existe no migrate.dart"]),
            "sem a última": (dict(policy, migrations=policy["migrations"][:-1]), [
                f"o migrate.dart tem a {last} depois da",
                f"o readiness deste SHA exige a {last}"]),
            "partindo da 057": (dict(policy, **{"from": "057"}),
                                [f"lacuna: o migrate.dart tem a 058 entre a 057 e a {last}"]),
        }
        for label, (changed, expected) in cases.items():
            with self.subTest(case=label):
                planned = _plan(changed)
                self.assertEqual(planned["status"], "BLOCKED")
                for text in expected:
                    self.assertTrue(any(text in problem for problem in planned["problems"]),
                                    (text, planned["problems"]))

    def test_the_tool_refuses_a_gap_before_any_connection(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            changed = Path(tmp) / "lote.json"
            changed.write_text(json.dumps(_without(_policy(), "074")), encoding="utf-8")
            result = subprocess.run(
                ["/bin/bash", str(SCRIPT), "--policy", str(changed)],
                capture_output=True, text=True, check=False,
                env={"PATH": "/usr/bin:/bin", "PYTHONDONTWRITEBYTECODE": "1",
                     "MANALOOM_NEW_SERVER_ENV": str(Path(tmp) / "nao_existe.env")})
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("a 074 tem de ir no mesmo lote", result.stdout)
        clean = subprocess.run(["/bin/bash", str(SCRIPT)], capture_output=True, text=True,
                               check=False, env={"PATH": "/usr/bin:/bin",
                                                 "PYTHONDONTWRITEBYTECODE": "1"})
        self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)
        self.assertEqual(json.loads(clean.stdout)["status"], "PASS")

    def test_an_invalid_policy_is_refused(self) -> None:
        policy = _policy()
        cases = {
            "ordem numérica": dict(policy, migrations=list(reversed(policy["migrations"]))),
            "começar depois da 058": dict(policy, migrations=["058"] + policy["migrations"]),
            "same_lot[0] inválido": dict(policy, same_lot=[{"version": "074", "with": []}]),
            "rollback ausente": {key: value for key, value in policy.items() if key != "rollback"},
            "v1": dict(policy, schema_version=2),
        }
        for expected, changed in cases.items():
            with self.subTest(case=expected):
                self.assertTrue(any(expected in problem
                                    for problem in lot.policy_problems(changed)),
                                lot.policy_problems(changed))

    def test_the_ledger_before_must_be_exactly_at_the_start(self) -> None:
        planned = _plan(_policy())
        code = _code()
        at_058 = [item for item in code if item[0] <= "058"]
        self.assertEqual(lot.check_before(planned, at_058)["status"], "PASS")
        cases = {
            "lacuna no ledger: falta a 057": [item for item in at_058 if item[0] != "057"],
            "(de_outra_linha), que este código não conhece": at_058 + [("999", "de_outra_linha")],
            "tem a 058 como outra_058": [item if item[0] != "058" else ("058", "outra_058")
                                         for item in at_058],
            "este lote já foi aplicado": [item for item in code if item[0] <= planned["to"]],
            "o banco está na nenhuma": [],
        }
        for expected, entries in cases.items():
            with self.subTest(case=expected):
                result = lot.check_before(planned, entries)
                self.assertEqual(result["status"], "BLOCKED")
                self.assertTrue(any(expected in problem for problem in result["problems"]),
                                result["problems"])

    def test_the_ledger_after_is_the_one_before_plus_the_lot(self) -> None:
        planned = _plan(_policy())
        code = _code()
        before = [item for item in code if item[0] <= "058"]
        after = [item for item in code if item[0] <= planned["to"]]
        result = lot.check_after(planned, before, after)
        self.assertEqual((result["status"], result["problems"]), ("PASS", []))
        self.assertEqual(result["applied"], [item["version"] for item in planned["migrations"]])
        # Parou no meio: cada migration é atômica, e o receipt diz onde.
        stopped = [item for item in after if item[0] < "074"]
        result = lot.check_after(planned, before, stopped)
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("074", result["missing"])
        self.assertTrue(any("o banco ficou na 073" in problem for problem in result["problems"]))
        extra = lot.check_after(planned, before, after + [("999", "de_outra_linha")])
        self.assertEqual(extra["unexpected"], ["999"])

    def test_the_ledger_snapshot_is_what_the_promotion_accepts(self) -> None:
        code = _code()
        data = lot.snapshot(code)
        now = dt.datetime.now(dt.timezone.utc)
        accepted = promote.load_schema_snapshot(json.dumps(data), now)
        self.assertEqual(accepted["latest_migration"], code[-1][0])
        with self.assertRaises(lot.InvalidInput):
            lot.parse_ledger("058|snapshot_trade_item_identity\nlixo\n")
        with self.assertRaises(lot.InvalidInput):
            lot.parse_ledger("059|a\n058|b\n")

    def test_refusals_before_anything_touches_the_database(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            calls = work / "ssh.log"
            bin_dir = work / "bin"
            bin_dir.mkdir()
            shim = bin_dir / "ssh"
            shim.write_text(f'#!/bin/bash\necho "$@" >>"{calls}"\nexit 97\n', encoding="utf-8")
            shim.chmod(0o755)
            base = {"PATH": f"{bin_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
                    "PYTHONDONTWRITEBYTECODE": "1",
                    "MANALOOM_NEW_SERVER_ENV": str(work / "nao_existe.env")}
            approved = dict(base, MANALOOM_CONFIRM_LIVE_MUTATIONS=APPROVAL,
                            MANALOOM_CONFIRM_POSTGRES_WRITES=APPROVAL)
            receipts = work / "receipts"
            receipts.mkdir()
            cases = (
                (["--apply"], base, "exigem --execute"),
                (["--execute"], base, "--execute exige --apply ou --read-ledger"),
                (["--execute", "--read-ledger"], base, "--read-ledger exige --out"),
                (["--execute", "--apply", "--receipt-dir", str(receipts)], base,
                 "MANALOOM_CONFIRM_LIVE_MUTATIONS"),
                (["--execute", "--apply", "--receipt-dir", str(receipts)],
                 dict(base, MANALOOM_CONFIRM_LIVE_MUTATIONS=APPROVAL),
                 "MANALOOM_CONFIRM_POSTGRES_WRITES"),
                (["--execute", "--apply", "--receipt-dir", str(receipts)], approved,
                 "diretório durável"),
                (["--execute", "--apply"], approved, "exige um --receipt-dir"),
            )
            for args, env, expected in cases:
                with self.subTest(args=args, expected=expected):
                    result = subprocess.run(["/bin/bash", str(SCRIPT), *args],
                                            capture_output=True, text=True, check=False,
                                            env=env)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                    self.assertIn(expected, result.stderr)
            self.assertFalse(calls.exists())
            self.assertEqual(list(receipts.iterdir()), [])


# ------------------------------------------------------------------ banco descartável


rehearsal = _load("s05_rehearsal", REPO_ROOT / "scripts" / "manaloom_migration_rehearsal.py")


@unittest.skipUnless(ENABLED, "Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.")
class DisposablePostgresTest(unittest.TestCase):
    """O script de verdade, do banco na 058 até a última migration do lote."""

    FILES = (
        "scripts/manaloom_lot_apply_migrations.sh",
        "scripts/manaloom_lot_migrations.py",
        "scripts/manaloom_promote_release.py",
        "scripts/manaloom_capacity_resources.py",
        "scripts/manaloom_capacity_policy.py",
        "scripts/manaloom_release_identity_gate.py",
        "scripts/manaloom_read_env.py",
        "scripts/lib/manaloom_mutation_guard.sh",
        "scripts/lib/manaloom_safe_env.sh",
        "scripts/lib/manaloom_release_runtime_contract.sh",
        "scripts/lib/manaloom_dart_toolchain.sh",
        "server/bin/with_new_server_pg.sh",
        "server/bin/migrate.dart",
        "server/config/lot_migrations.json",
        "server/config/capacity_policy.json",
        "server/pubspec.yaml",
        "server/pubspec.lock",
    )

    @classmethod
    def setUpClass(cls) -> None:
        if not rehearsal._approved():
            raise AssertionError("aprove o PostgreSQL descartável (MANALOOM_APPROVE_DISPOSABLE_POSTGRES)")
        digest = hashlib.sha256(SETUP_058.read_bytes()).hexdigest()
        assert digest == SETUP_058_SHA256, "o bootstrap da 058 do fixture mudou"
        cls.pg_bin, cls.dart = rehearsal._tools()
        cls.work = Path(tempfile.mkdtemp(prefix="manaloom-lot-migrations."))
        base = Path.home() / ".cache" / "manaloom-lot-migrations-test"
        base.mkdir(parents=True, exist_ok=True)
        cls.receipts = Path(tempfile.mkdtemp(prefix="receipts-", dir=base))
        cls.cluster = rehearsal.Cluster(cls.pg_bin, cls.dart, cls.work)
        try:
            cls.cluster.start()
            cls.cluster.createdb("halder")
            cls.cluster.psql_file("halder", SETUP_058)
            result = cls.cluster.migrate("halder", "--target", "058")
            assert result.returncode == 0, result.stdout[-2000:] + result.stderr[-2000:]
            cls.cluster.execute("halder", SEED)
            cls._build_repo()
        except BaseException:
            cls.tearDownClass()
            raise

    @classmethod
    def tearDownClass(cls) -> None:
        cls.cluster.stop()
        shutil.rmtree(cls.work, ignore_errors=True)
        shutil.rmtree(cls.receipts, ignore_errors=True)

    @classmethod
    def _git(cls, *args: str) -> str:
        return subprocess.run(["git", "-C", str(cls.repo), *args], capture_output=True,
                              text=True, check=True,
                              env={"PATH": "/usr/bin:/bin", "HOME": str(cls.work),
                                   "GIT_CONFIG_NOSYSTEM": "1"}).stdout.strip()

    @classmethod
    def _build_repo(cls) -> None:
        cls.repo = cls.work / "repo"
        for relative in cls.FILES:
            target = cls.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        shutil.copytree(REPO_ROOT / "server" / "lib", cls.repo / "server" / "lib")
        # As dependências já resolvidas (fora do git, como no checkout de verdade).
        shutil.copytree(REPO_ROOT / "server" / ".dart_tool", cls.repo / "server" / ".dart_tool",
                        ignore=shutil.ignore_patterns("pub", "build", "hooks_runner"))
        (cls.repo / ".gitignore").write_text(".dart_tool/\n__pycache__/\n", encoding="utf-8")
        origin = cls.work / "origin.git"
        subprocess.run(["git", "init", "--bare", "--quiet", str(origin)], check=True,
                       env={"PATH": "/usr/bin:/bin", "HOME": str(cls.work)})
        cls._git("init", "--quiet")
        cls._git("config", "user.name", "contract-test")
        cls._git("config", "user.email", "contract-test@localhost")
        cls._git("add", "-A")
        cls._git("commit", "--quiet", "-m", "candidato")
        cls._git("branch", "-M", "master")
        cls._git("remote", "add", "origin", str(origin))
        cls._git("push", "--quiet", "-u", "origin", "master")
        cls.sha = cls._git("rev-parse", "HEAD")
        bin_dir = cls.work / "bin"
        bin_dir.mkdir()

        def shim(name: str, body: str) -> None:
            path = bin_dir / name
            path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
            path.chmod(0o755)

        shim("ssh", f'exec "{sys.executable}" "{THIS_FILE}" --fake-ssh "$@"\n')
        shim("ssh-keyscan", f'echo "{FAKE_SERVER_IP} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5"\n')
        shim("ssh-keygen", f'cat >/dev/null\necho "256 {FAKE_HOST_KEY} host (ED25519)"\n')
        (bin_dir / "python3").symlink_to(sys.executable)
        key = cls.work / "deploy_key"
        key.write_text("chave de teste\n", encoding="utf-8")
        cls.env_file = cls.work / "server.env"
        cls.env_file.write_text(
            f"EASYPANEL_SERVER_IP={FAKE_SERVER_IP}\nEASYPANEL_SSH_USER=root\n"
            f"EASYPANEL_SSH_KEY={key}\nDB_NAME=halder\nDB_USER=postgres\n"
            "DB_PASS=senha-de-teste-nao-e-segredo\n", encoding="utf-8")
        cls.ssh_log = cls.work / "ssh.jsonl"
        tmp = cls.work / "tmp"
        tmp.mkdir()
        cls.env = {
            "PATH": f"{bin_dir}:{cls.pg_bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": str(Path.home()),
            "TMPDIR": str(tmp),
            "LC_ALL": "C",
            "PYTHONUTF8": "1",
            "PYTHONDONTWRITEBYTECODE": "1",
            "GIT_CONFIG_NOSYSTEM": "1",
            "MANALOOM_DART_BIN": str(cls.dart),
            "MANALOOM_NEW_SERVER_ENV": str(cls.env_file),
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256": FAKE_HOST_KEY,
            "MANALOOM_CONFIRM_LIVE_MUTATIONS": APPROVAL,
            "MANALOOM_CONFIRM_POSTGRES_WRITES": APPROVAL,
            "FAKE_PG_PORT": str(cls.cluster.port),
            "FAKE_SSH_LOG": str(cls.ssh_log),
        }

    # -- utilitários

    def run_tool(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
        # O sandbox do ensaio: rede só em localhost, para o script, o wrapper e o Dart.
        return subprocess.run(
            [*self.cluster.sandbox, "/bin/bash", str(self.repo / "scripts" /
                                                     "manaloom_lot_apply_migrations.sh"), *args],
            capture_output=True, text=True, env=env or self.env, check=False, timeout=900)

    def ledger(self) -> list[str]:
        output = self.cluster.psql("halder", "SELECT version FROM schema_migrations ORDER BY version")
        return [line for line in output.splitlines() if line.strip()]

    def tunnels(self) -> int:
        if not self.ssh_log.exists():
            return 0
        return len(self.ssh_log.read_text(encoding="utf-8").splitlines())

    def receipts_with(self, status: str) -> list[dict[str, Any]]:
        found = []
        for path in sorted(self.receipts.glob("lote-migrations-*.json")):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600, path)
            data = json.loads(path.read_text(encoding="utf-8"))
            if data["status"] == status:
                found.append(data)
        return found

    # -- o caminho do lote, em ordem (o banco é um só)

    def test_from_058_the_lot_reaches_the_last_migration_and_refuses_gaps(self) -> None:
        policy = _policy()
        last = policy["migrations"][-1]
        self.assertEqual(self.ledger()[-1], "058")

        # 1. O ledger só para leitura, no formato que a promoção pede.
        ledger_058 = self.work / "ledger-058.json"
        result = self.run_tool("--execute", "--read-ledger", "--out", str(ledger_058))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        snapshot = promote.load_schema_snapshot(ledger_058.read_text(encoding="utf-8"),
                                                dt.datetime.now(dt.timezone.utc))
        self.assertEqual(snapshot["latest_migration"], "058")
        self.assertEqual(stat.S_IMODE(ledger_058.stat().st_mode), 0o600)
        self.assertEqual(self.tunnels(), 1)

        # 2. Checkout sujo: recusa antes de ler o banco.
        dirty = self.repo / "sujo.txt"
        dirty.write_text("x", encoding="utf-8")
        result = self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts))
        dirty.unlink()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("checkout sujo", result.stderr)
        self.assertEqual(self.tunnels(), 1)

        # 3. Lacuna no lote (sem a 074): recusa sem conectar, e o banco fica na 058.
        gap = self.work / "lote-sem-074.json"
        gap.write_text(json.dumps(_without(policy, "074")), encoding="utf-8")
        result = self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts),
                               "--policy", str(gap))
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("a 074 tem de ir no mesmo lote da 067 e da 069", result.stderr)
        self.assertEqual(self.ledger()[-1], "058")
        self.assertEqual(self.tunnels(), 1)
        blocked = self.receipts_with("blocked")
        self.assertEqual(len(blocked), 1)
        self.assertTrue(any("lacuna" in problem for problem in blocked[0]["problems"]))
        self.assertIsNone(blocked[0]["before"])

        # 4. Lacuna no ledger (sem a 057): lê o banco, recusa e não escreve.
        self.cluster.execute("halder", "CREATE TABLE guarda_057 AS SELECT * FROM schema_migrations "
                                       "WHERE version = '057'; DELETE FROM schema_migrations "
                                       "WHERE version = '057';")
        result = self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts))
        self.cluster.execute("halder", "INSERT INTO schema_migrations SELECT * FROM guarda_057; "
                                       "DROP TABLE guarda_057;")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("lacuna no ledger: falta a 057", result.stderr)
        self.assertEqual(self.ledger()[-1], "058")
        self.assertEqual(len(self.receipts_with("blocked")), 2)
        self.assertEqual(list(self.receipts.glob("*.log")), [])

        # 5. O lote: da 058 à última, em ordem, com o receipt de antes e de depois.
        tunnels_before = self.tunnels()
        result = self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        summary = json.loads(result.stdout.splitlines()[-1])
        self.assertEqual((summary["status"], summary["from"], summary["to"]),
                         ("applied", "058", last))
        self.assertEqual(self.ledger(), [version for version, _ in _code()
                                         if version <= last])
        # Três túneis: o ledger antes (só leitura), o migrate.dart e o ledger depois.
        self.assertEqual(self.tunnels() - tunnels_before, 3)
        applied = self.receipts_with("applied")
        self.assertEqual(len(applied), 1)
        receipt = applied[0]
        self.assertEqual((receipt["sha"], receipt["from"], receipt["to"]), (self.sha, "058", last))
        self.assertEqual((receipt["before"]["latest"], receipt["after"]["latest"]), ("058", last))
        self.assertEqual(receipt["applied"], policy["migrations"])
        self.assertEqual(receipt["lot"], policy["migrations"])
        self.assertEqual(receipt["migrate_exit"], 0)
        self.assertEqual(receipt["after"]["count"], receipt["before"]["count"]
                         + len(policy["migrations"]))
        log = self.receipts / receipt["migrate_log"]
        self.assertEqual(stat.S_IMODE(log.stat().st_mode), 0o600)
        log_text = log.read_text(encoding="utf-8")
        for version in policy["migrations"]:
            self.assertIn(f"Executando {version}_", log_text)
        # O ledger de depois serve à promoção (S-02): com ele, o backend não volta para
        # uma imagem que exige a 058.
        after = Path(summary["schema_snapshot"])
        guard = promote.schema_guard(
            after.read_text(encoding="utf-8"), READINESS.read_text(encoding="utf-8"),
            "4" * 40, READINESS.read_text(encoding="utf-8").replace(
                f"= '{last}' AS latest_migration_ready", "= '058' AS latest_migration_ready"
            ).replace(f"'latest_migration': '{last}'", "'latest_migration': '058'"),
            dt.datetime.now(dt.timezone.utc))
        self.assertEqual((guard["status"], guard["database_latest"], guard["backend_rollback"]),
                         ("PASS", last, "refused"))

        # 6. De novo: o banco já está na última; recusa e não escreve.
        result = self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts))
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("este lote já foi aplicado", result.stderr)
        self.assertEqual(self.ledger()[-1], last)


if __name__ == "__main__":
    unittest.main()
