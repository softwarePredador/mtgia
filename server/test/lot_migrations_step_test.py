#!/usr/bin/env python3
"""S-05: o passo de migrations do lote de deploy (scripts/manaloom_lot_apply_migrations.sh).

Sem banco, sempre: o lote versionado (server/config/lot_migrations.json) contra o código
deste SHA, as recusas de lacuna e de lote (a 074 vai com a 067 e a 069, pela BT-DB-007),
as provas do L-01 e do L-02, as conferências do ledger de antes e de depois (no mesmo
banco), a evidência que nunca é sobrescrita (O_EXCL e nome com carimbo e PID, inclusive
em duas execuções no mesmo segundo) e as recusas antes de qualquer conexão, num
repositório descartável fora de /tmp.

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
# Um banco qualquer para os testes sem banco (o com banco usa o do cluster descartável).
DATABASE = {"name": "halder", "system_identifier": "7400000000000000001"}
OTHER_DATABASE = {"name": "halder", "system_identifier": "7400000000000000002"}
DURABLE_BASE = Path.home() / ".cache" / "manaloom-lot-migrations-test"
# Os arquivos que o script usa num repositório descartável (mais o server/lib).
REPO_FILES = (
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


def _raw(entries: list[tuple[str, str]], database: dict[str, str] = DATABASE) -> str:
    """Uma leitura do banco como o script grava: a identidade e o ledger."""
    return (f"database|{database['name']}|{database['system_identifier']}\n"
            + "".join(f"{version}|{name}\n" for version, name in entries))


def _stamp(when: dt.datetime) -> str:
    return when.strftime("%Y-%m-%dT%H:%M:%SZ")


def _proof_documents(now: dt.datetime | None = None, **changes: Any) -> tuple[dict, dict]:
    """O receipt do L-01 (backup com ensaio) e o rehearsal.json do L-02, aprovados."""
    now = now or dt.datetime.now(dt.timezone.utc)
    dump_sha = "d" * 64
    backup = {
        "schema_version": 1, "kind": "brewtact-backup-cycle",
        "recorded_at": _stamp(now - dt.timedelta(hours=2)),
        "tool_git_sha": "0" * 40,
        "backup": {"file": "manaloom-postgres-20261010T090000Z.dump", "bytes": 4096,
                   "sha256": dump_sha},
        "drill": {"evidence": "drills/20261010T090000Z/restore-result.json",
                  "status": "passed", "table_count": 90},
        "cadence": {"status": "PASS", "reasons": []},
    }
    rehearsal = {
        "schema_version": 1, "kind": "brewtact-migration-rehearsal", "task": "BT-DB-003",
        "iniciado_em": _stamp(now - dt.timedelta(hours=1, minutes=30)),
        "concluido_em": _stamp(now - dt.timedelta(hours=1)),
        "dump": {"arquivo": "manaloom-postgres-20261010T090000Z.dump", "bytes": 4096,
                 "sha256": dump_sha},
        "restauracao": "completo", "resultado": "PASS",
    }
    for key, value in changes.items():
        target, field = key.split("__", 1)
        (backup if target == "backup" else rehearsal)[field] = value
    return backup, rehearsal


def write_proofs(directory: Path, **changes: Any) -> tuple[Path, Path]:
    backup, rehearsal = _proof_documents(**changes)
    directory.mkdir(parents=True, exist_ok=True)
    backup_path = directory / "l01-backup.json"
    rehearsal_path = directory / "l02-rehearsal.json"
    backup_path.write_text(json.dumps(backup), encoding="utf-8")
    rehearsal_path.write_text(json.dumps(rehearsal), encoding="utf-8")
    return backup_path, rehearsal_path


def build_repo(work: Path, *, dart_tool: bool = False) -> tuple[Path, str]:
    """O repositório descartável no origin/master (um bare ao lado), com o código deste SHA."""
    repo = work / "repo"
    for relative in REPO_FILES:
        target = repo / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_ROOT / relative, target)
    shutil.copytree(REPO_ROOT / "server" / "lib", repo / "server" / "lib")
    if dart_tool:
        # As dependências já resolvidas (fora do git, como no checkout de verdade).
        shutil.copytree(REPO_ROOT / "server" / ".dart_tool", repo / "server" / ".dart_tool",
                        ignore=shutil.ignore_patterns("pub", "build", "hooks_runner"))
    (repo / ".gitignore").write_text(".dart_tool/\n__pycache__/\n", encoding="utf-8")
    origin = work / "origin.git"
    env = {"PATH": "/usr/bin:/bin", "HOME": str(work), "GIT_CONFIG_NOSYSTEM": "1"}
    subprocess.run(["git", "init", "--bare", "--quiet", str(origin)], check=True, env=env)

    def git(*args: str) -> str:
        return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True,
                              check=True, env=env).stdout.strip()

    git("init", "--quiet")
    git("config", "user.name", "contract-test")
    git("config", "user.email", "contract-test@localhost")
    git("add", "-A")
    git("commit", "--quiet", "-m", "candidato")
    git("branch", "-M", "master")
    git("remote", "add", "origin", str(origin))
    git("push", "--quiet", "-u", "origin", "master")
    return repo, git("rev-parse", "HEAD")


def _shim(directory: Path, name: str, body: str) -> None:
    path = directory / name
    path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
    path.chmod(0o755)


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
        passed = lot.check_before(planned, at_058, DATABASE)
        self.assertEqual(passed["status"], "PASS")
        self.assertEqual(passed["ledger"]["database"], DATABASE)
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
                result = lot.check_before(planned, entries, DATABASE)
                self.assertEqual(result["status"], "BLOCKED")
                self.assertTrue(any(expected in problem for problem in result["problems"]),
                                result["problems"])

    def test_the_ledger_after_is_the_one_before_plus_the_lot(self) -> None:
        planned = _plan(_policy())
        code = _code()
        before = [item for item in code if item[0] <= "058"]
        after = [item for item in code if item[0] <= planned["to"]]
        result = lot.check_after(planned, before, after, DATABASE, DATABASE)
        self.assertEqual((result["status"], result["problems"]), ("PASS", []))
        self.assertEqual(result["applied"], [item["version"] for item in planned["migrations"]])
        self.assertEqual(result["ledger"]["database"], DATABASE)
        # Parou no meio: cada migration é atômica, e o receipt diz onde.
        stopped = [item for item in after if item[0] < "074"]
        result = lot.check_after(planned, before, stopped, DATABASE, DATABASE)
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("074", result["missing"])
        self.assertTrue(any("o banco ficou na 073" in problem for problem in result["problems"]))
        extra = lot.check_after(planned, before, after + [("999", "de_outra_linha")],
                                DATABASE, DATABASE)
        self.assertEqual(extra["unexpected"], ["999"])
        # O ledger de depois de outro banco (outro cluster) não é o lote aplicado neste.
        other = lot.check_after(planned, before, after, DATABASE, OTHER_DATABASE)
        self.assertEqual(other["status"], "FAIL")
        self.assertTrue(any("o ledger de depois é do halder do cluster 7400000000000000002"
                            in problem for problem in other["problems"]), other["problems"])

    def test_the_ledger_snapshot_is_what_the_promotion_accepts(self) -> None:
        code = _code()
        database, entries = lot.parse_read(_raw(code))
        self.assertEqual((database, entries), (DATABASE, code))
        data = lot.snapshot(entries, database)
        now = dt.datetime.now(dt.timezone.utc)
        accepted = promote.load_schema_snapshot(json.dumps(data), now)
        self.assertEqual(accepted["latest_migration"], code[-1][0])
        # O snapshot diz de qual banco veio, e a promoção recusa o que não diz.
        self.assertEqual(accepted["database"], DATABASE)
        anonymous = {key: value for key, value in data.items() if key != "database"}
        with self.assertRaises(promote.InvalidInput):
            promote.load_schema_snapshot(json.dumps(anonymous), now)
        with self.assertRaises(lot.InvalidInput):
            lot.parse_ledger("058|snapshot_trade_item_identity\nlixo\n")
        with self.assertRaises(lot.InvalidInput):
            lot.parse_ledger("059|a\n058|b\n")
        # A leitura começa pela identidade: sem ela, ou com uma ilegível, recusa.
        for raw in (_raw(code)[_raw(code).index("\n") + 1:], "database|halder|abc\n058|x\n",
                    "database||1\n", ""):
            with self.subTest(raw=raw[:24]):
                with self.assertRaises(lot.InvalidInput):
                    lot.parse_read(raw)

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
            existing = work / "ja-existe.json"
            existing.write_text("evidência anterior\n", encoding="utf-8")
            DURABLE_BASE.mkdir(parents=True, exist_ok=True)
            durable = Path(tempfile.mkdtemp(prefix="receipts-", dir=DURABLE_BASE))
            self.addCleanup(shutil.rmtree, durable, True)
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
                (["--execute", "--apply", "--receipt-dir", str(durable)], approved,
                 "--apply exige as provas do lote: --backup-receipt (L-01"),
                (["--execute", "--apply", "--receipt-dir", str(durable),
                  "--backup-receipt", str(existing)], approved, "--upgrade-rehearsal (L-02"),
                (["--execute", "--read-ledger", "--out", str(existing)], base,
                 "--out já existe; recuso sobrescrever"),
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
            self.assertEqual(list(durable.iterdir()), [])
            self.assertEqual(existing.read_text(encoding="utf-8"), "evidência anterior\n")

    def test_the_proofs_of_l01_and_l02_must_pass_be_recent_and_match(self) -> None:
        now = dt.datetime.now(dt.timezone.utc)
        backup, rehearsal = _proof_documents(now)
        passed = lot.proofs(backup, rehearsal, now)
        self.assertEqual((passed["status"], passed["problems"]), ("PASS", []))
        self.assertEqual(passed["backup"]["dump_sha256"], "d" * 64)
        old = _stamp(now - dt.timedelta(hours=25))
        cases = {
            "o L-01 (backup) é de": {"backup__recorded_at": old},
            "o L-01 (backup) diz ter sido feito no futuro": {
                "backup__recorded_at": _stamp(now + dt.timedelta(hours=1))},
            "o L-01 não tem o ensaio de restauração aprovado": {"backup__drill": None},
            "a cadência do L-01 não fechou": {"backup__cadence": {"status": "BLOCKED"}},
            "o L-01 não é um receipt brewtact-backup-cycle v1": {"backup__kind": "outro"},
            "o L-02 (ensaio do upgrade) é de": {"rehearsal__concluido_em": old},
            "o L-02 (ensaio do upgrade) não passou: FAIL": {"rehearsal__resultado": "FAIL"},
            "o L-02 tem de ser o ensaio completo": {"rehearsal__restauracao": "estrutura"},
            "o L-02 não ensaiou o dump do L-01": {
                "rehearsal__dump": {"arquivo": "outro.dump", "sha256": "e" * 64}},
            "o L-02 não é um brewtact-migration-rehearsal v1": {"rehearsal__schema_version": 2},
        }
        for expected, changes in cases.items():
            with self.subTest(case=expected):
                result = lot.proofs(*_proof_documents(now, **changes), now)
                self.assertEqual(result["status"], "BLOCKED")
                self.assertTrue(any(expected in problem for problem in result["problems"]),
                                result["problems"])
        # O subcomando: arquivo regular (não link) e JSON; o SHA-256 de cada prova vai junto.
        with tempfile.TemporaryDirectory() as tmp:
            backup_path, rehearsal_path = write_proofs(Path(tmp) / "provas")
            ok = self._module("proofs", "--backup-receipt", str(backup_path),
                              "--upgrade-rehearsal", str(rehearsal_path))
            self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
            self.assertEqual(json.loads(ok.stdout)["backup"]["receipt_sha256"],
                             hashlib.sha256(backup_path.read_bytes()).hexdigest())
            link = Path(tmp) / "link.json"
            link.symlink_to(backup_path)
            refused = self._module("proofs", "--backup-receipt", str(link),
                                   "--upgrade-rehearsal", str(rehearsal_path))
            self.assertEqual(refused.returncode, 2, refused.stdout)
            self.assertIn("não é um arquivo regular", refused.stdout)

    def _module(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run([sys.executable, str(REPO_ROOT / "scripts" /
                                                   "manaloom_lot_migrations.py"), *args],
                              capture_output=True, text=True, check=False,
                              env={"PATH": "/usr/bin:/bin", "PYTHONDONTWRITEBYTECODE": "1"})

    def test_a_second_write_to_the_same_name_never_truncates_the_evidence(self) -> None:
        # Duas execuções no mesmo segundo davam o mesmo nome e a segunda truncava a
        # primeira (O_TRUNC). Agora cada arquivo nasce com O_EXCL: a segunda é recusada
        # e a primeira fica byte a byte.
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            plan_path = work / "plano.json"
            plan_path.write_text(json.dumps(_plan(_policy())), encoding="utf-8")
            raw = work / "ledger.txt"
            raw.write_text(_raw([item for item in _code() if item[0] <= "058"]),
                           encoding="utf-8")
            receipt = work / "lote-migrations-abc-20261010T120000Z.json"
            snapshot_path = work / "ledger-abc-20261010T120000Z.json"
            log = work / "lote-migrations-abc-20261010T120000Z.log"
            writes = {
                receipt: ("receipt", "--out", str(receipt), "--status", "blocked", "--sha",
                          "a" * 40, "--started-at", "2026-10-10T12:00:00Z",
                          "--plan", str(plan_path)),
                snapshot_path: ("snapshot", "--raw", str(raw), "--out", str(snapshot_path)),
                log: ("create", "--out", str(log)),
            }
            for path, args in writes.items():
                with self.subTest(path=path.name):
                    first = self._module(*args)
                    self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
                    self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                    before = path.read_bytes()
                    if path == log:
                        path.write_text("saída do migrate.dart\n", encoding="utf-8")
                        before = path.read_bytes()
                    second = self._module(*args)
                    self.assertEqual(second.returncode, 2, second.stdout + second.stderr)
                    self.assertIn("recuso sobrescrever", second.stdout)
                    self.assertEqual(path.read_bytes(), before)


class ScriptWithoutDatabaseTest(unittest.TestCase):
    """O script de verdade num repositório descartável durável (fora de /tmp), sem banco.

    O ssh é um shim que anota a chamada e falha: nenhum destes casos pode conectar.
    """

    # Um instante fixo: as execuções caem no mesmo segundo.
    FIXED_EPOCH = "1791633600"

    @classmethod
    def setUpClass(cls) -> None:
        DURABLE_BASE.mkdir(parents=True, exist_ok=True)
        cls.work = Path(tempfile.mkdtemp(prefix="sem-banco-", dir=DURABLE_BASE))
        try:
            cls.repo, cls.sha = build_repo(cls.work)
            cls.bin = cls.work / "bin"
            cls.bin.mkdir()
            cls.ssh_log = cls.work / "ssh.log"
            _shim(cls.bin, "ssh", f'echo "$@" >>"{cls.ssh_log}"\nexit 97\n')
            _shim(cls.bin, "dart", 'echo "Dart SDK version: 3.12.2 (stable) (shim de teste)"\n')
            _shim(cls.bin, "date",
                  f'if /bin/date -r 0 >/dev/null 2>&1; then exec /bin/date -r {cls.FIXED_EPOCH} "$@"; '
                  f'fi\nexec /bin/date -d @{cls.FIXED_EPOCH} "$@"\n')
            (cls.bin / "python3").symlink_to(sys.executable)
            tmp = cls.work / "tmp"
            tmp.mkdir()
            cls.env = {
                "PATH": f"{cls.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
                "HOME": str(cls.work),
                "TMPDIR": str(tmp),
                "LC_ALL": "C",
                "PYTHONDONTWRITEBYTECODE": "1",
                "GIT_CONFIG_NOSYSTEM": "1",
                "MANALOOM_DART_BIN": str(cls.bin / "dart"),
                "MANALOOM_NEW_SERVER_ENV": str(cls.work / "nao_existe.env"),
                "MANALOOM_CONFIRM_LIVE_MUTATIONS": APPROVAL,
                "MANALOOM_CONFIRM_POSTGRES_WRITES": APPROVAL,
            }
        except BaseException:
            shutil.rmtree(cls.work, ignore_errors=True)
            raise

    @classmethod
    def tearDownClass(cls) -> None:
        shutil.rmtree(cls.work, ignore_errors=True)

    def setUp(self) -> None:
        self.receipts = Path(tempfile.mkdtemp(prefix="receipts-", dir=DURABLE_BASE))
        self.addCleanup(shutil.rmtree, self.receipts, True)
        self.proofs_dir = Path(tempfile.mkdtemp(prefix="provas-", dir=DURABLE_BASE))
        self.addCleanup(shutil.rmtree, self.proofs_dir, True)

    def run_tool(self, *args: str, repo: Path | None = None) -> subprocess.CompletedProcess:
        script = (repo or self.repo) / "scripts" / "manaloom_lot_apply_migrations.sh"
        return subprocess.run(["/bin/bash", str(script), *args], capture_output=True,
                              text=True, check=False, env=self.env, timeout=120)

    def apply(self, *extra: str, receipts: Path | None = None, **proof_changes: Any
              ) -> subprocess.CompletedProcess:
        backup, rehearsal = write_proofs(self.proofs_dir, **proof_changes)
        return self.run_tool("--execute", "--apply", "--receipt-dir", str(receipts or self.receipts),
                             "--backup-receipt", str(backup), "--upgrade-rehearsal",
                             str(rehearsal), *extra)

    def test_two_runs_in_the_same_second_keep_both_receipts(self) -> None:
        # O lote sem a 074 é recusado antes de conectar e grava um receipt blocked. Duas
        # execuções no mesmo segundo (o relógio está parado) dão dois receipts, com o
        # mesmo carimbo e PIDs diferentes; nenhum sobrescreve o outro.
        gap = self.work / "lote-sem-074.json"
        gap.write_text(json.dumps(_without(_policy(), "074")), encoding="utf-8")
        for _ in range(2):
            result = self.apply("--policy", str(gap))
            self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
            self.assertIn("a 074 tem de ir no mesmo lote", result.stderr)
        receipts = sorted(self.receipts.glob("lote-migrations-*.json"))
        self.assertEqual(len(receipts), 2, receipts)
        stamps = {path.name.rsplit("-", 2)[1] for path in receipts}
        pids = {path.stem.rsplit("-", 1)[1] for path in receipts}
        self.assertEqual((len(stamps), len(pids)), (1, 2), receipts)
        started = set()
        for path in receipts:
            self.assertTrue(path.name.startswith(f"lote-migrations-{self.sha[:12]}-"), path)
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600, path)
            data = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "blocked")
            started.add(data["started_at"])
        self.assertEqual(len(started), 1)
        self.assertFalse(self.ssh_log.exists())

    def test_the_apply_without_fresh_proofs_is_blocked_before_connecting(self) -> None:
        old = _stamp(dt.datetime.now(dt.timezone.utc) - dt.timedelta(hours=25))
        cases = {
            "o L-01 (backup) é de": {"backup__recorded_at": old},
            "o L-02 não ensaiou o dump do L-01": {
                "rehearsal__dump": {"arquivo": "outro.dump", "sha256": "e" * 64}},
        }
        for expected, changes in cases.items():
            with self.subTest(case=expected):
                result = self.apply(**changes)
                self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
                self.assertIn(expected, result.stderr)
                self.assertIn("BLOCKED: sem as provas do L-01 e do L-02", result.stderr)
        blocked = [json.loads(path.read_text(encoding="utf-8"))
                   for path in sorted(self.receipts.glob("lote-migrations-*.json"))]
        self.assertEqual([data["status"] for data in blocked], ["blocked", "blocked"])
        self.assertTrue(all(data["proofs"]["status"] == "BLOCKED" for data in blocked))
        self.assertFalse(self.ssh_log.exists())
        # Com as provas em dia, o passo segue para o ledger (e o shim do ssh recusa).
        result = self.apply()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("não li o ledger do banco antes", result.stderr)

    def test_a_receipt_dir_inside_the_repository_is_refused(self) -> None:
        # O repositório descartável é durável (fora de /tmp): só a regra nova recusa.
        inside = self.repo / "evidencia"
        inside.mkdir()
        self.addCleanup(shutil.rmtree, inside, True)
        other = self.work / "outro-checkout"
        subprocess.run(["git", "-C", str(self.repo), "worktree", "add", "--quiet", "--detach",
                        str(other)], check=True, capture_output=True,
                       env={"PATH": "/usr/bin:/bin", "HOME": str(self.work),
                            "GIT_CONFIG_NOSYSTEM": "1"})
        self.addCleanup(subprocess.run, ["git", "-C", str(self.repo), "worktree", "remove",
                                         "--force", str(other)], capture_output=True)
        (other / "evidencia").mkdir()
        for receipts in (inside, other / "evidencia"):
            with self.subTest(receipts=str(receipts.relative_to(self.work))):
                result = self.apply(receipts=receipts)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertIn("o receipt não pode ficar dentro do repositório", result.stderr)
                self.assertEqual(list(receipts.iterdir()), [])
        self.assertFalse(self.ssh_log.exists())


# ------------------------------------------------------------------ banco descartável


rehearsal = _load("s05_rehearsal", REPO_ROOT / "scripts" / "manaloom_migration_rehearsal.py")


@unittest.skipUnless(ENABLED, "Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.")
class DisposablePostgresTest(unittest.TestCase):
    """O script de verdade, do banco na 058 até a última migration do lote."""

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
        cls.proofs_dir = Path(tempfile.mkdtemp(prefix="provas-", dir=base))
        cls.cluster = rehearsal.Cluster(cls.pg_bin, cls.dart, cls.work)
        try:
            cls.cluster.start()
            cls.cluster.createdb("halder")
            cls.cluster.psql_file("halder", SETUP_058)
            result = cls.cluster.migrate("halder", "--target", "058")
            assert result.returncode == 0, result.stdout[-2000:] + result.stderr[-2000:]
            cls.cluster.execute("halder", SEED)
            name, system = cls.cluster.psql(
                "halder", "SELECT current_database() || '|' || system_identifier "
                          "FROM pg_control_system()").strip().split("|")
            cls.database = {"name": name, "system_identifier": system}
            cls._build_repo()
        except BaseException:
            cls.tearDownClass()
            raise

    @classmethod
    def tearDownClass(cls) -> None:
        cls.cluster.stop()
        shutil.rmtree(cls.work, ignore_errors=True)
        shutil.rmtree(cls.receipts, ignore_errors=True)
        shutil.rmtree(cls.proofs_dir, ignore_errors=True)

    @classmethod
    def _build_repo(cls) -> None:
        cls.repo, cls.sha = build_repo(cls.work, dart_tool=True)
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

    def apply(self, *args: str) -> subprocess.CompletedProcess:
        """O --apply com as provas do L-01 e do L-02 em dia."""
        backup, rehearsal = write_proofs(self.proofs_dir)
        return self.run_tool("--execute", "--apply", "--receipt-dir", str(self.receipts),
                             "--backup-receipt", str(backup), "--upgrade-rehearsal",
                             str(rehearsal), *args)

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
        # O banco de onde o ledger veio: o nome e o system_identifier do cluster. A leitura
        # não pede superusuário: o PostgreSQL 17 dá o pg_control_system() a PUBLIC.
        self.assertEqual(snapshot["database"], self.database)
        self.assertEqual(self.cluster.psql("halder", "SELECT has_function_privilege("
                                           "'public', 'pg_control_system()', 'EXECUTE')"
                                           ).strip(), "t")
        self.assertEqual(stat.S_IMODE(ledger_058.stat().st_mode), 0o600)
        self.assertEqual(self.tunnels(), 1)
        # O mesmo --out de novo: recusa sem conectar e sem tocar no arquivo.
        kept = ledger_058.read_bytes()
        result = self.run_tool("--execute", "--read-ledger", "--out", str(ledger_058))
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual((ledger_058.read_bytes(), self.tunnels()), (kept, 1))

        # 2. Checkout sujo: recusa antes de ler o banco.
        dirty = self.repo / "sujo.txt"
        dirty.write_text("x", encoding="utf-8")
        result = self.apply()
        dirty.unlink()
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("checkout sujo", result.stderr)
        self.assertEqual(self.tunnels(), 1)

        # 3. Lacuna no lote (sem a 074): recusa sem conectar, e o banco fica na 058.
        gap = self.work / "lote-sem-074.json"
        gap.write_text(json.dumps(_without(policy, "074")), encoding="utf-8")
        result = self.apply("--policy", str(gap))
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
        result = self.apply()
        self.cluster.execute("halder", "INSERT INTO schema_migrations SELECT * FROM guarda_057; "
                                       "DROP TABLE guarda_057;")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("lacuna no ledger: falta a 057", result.stderr)
        self.assertEqual(self.ledger()[-1], "058")
        # Os dois receipts blocked ficam, mesmo no mesmo segundo (nome com o PID).
        blocked = self.receipts_with("blocked")
        self.assertEqual(len(blocked), 2)
        read = [data for data in blocked if data["before"]]
        self.assertEqual(len(read), 1)
        self.assertEqual(read[0]["before"]["database"], self.database)
        self.assertEqual(list(self.receipts.glob("*.log")), [])

        # 5. O lote: da 058 à última, em ordem, com o receipt de antes e de depois.
        tunnels_before = self.tunnels()
        result = self.apply()
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
        # O mesmo banco antes e depois, e as provas do L-01 e do L-02 no receipt.
        self.assertEqual((receipt["database"], receipt["before"]["database"],
                          receipt["after"]["database"], summary["database"]),
                         (self.database,) * 4)
        self.assertEqual(receipt["proofs"]["status"], "PASS")
        self.assertEqual(receipt["proofs"]["backup"]["dump_sha256"], "d" * 64)
        log = self.receipts / receipt["migrate_log"]
        self.assertEqual(stat.S_IMODE(log.stat().st_mode), 0o600)
        log_text = log.read_text(encoding="utf-8")
        for version in policy["migrations"]:
            self.assertIn(f"Executando {version}_", log_text)
        # O ledger de depois serve à promoção (S-02): com ele, o backend não volta para
        # uma imagem que exige a 058.
        after = Path(summary["schema_snapshot"])
        self.assertEqual(json.loads(after.read_text(encoding="utf-8"))["database"],
                         self.database)
        guard = promote.schema_guard(
            after.read_text(encoding="utf-8"), READINESS.read_text(encoding="utf-8"),
            "4" * 40, READINESS.read_text(encoding="utf-8").replace(
                f"= '{last}' AS latest_migration_ready", "= '058' AS latest_migration_ready"
            ).replace(f"'latest_migration': '{last}'", "'latest_migration': '058'"),
            dt.datetime.now(dt.timezone.utc))
        self.assertEqual((guard["status"], guard["database_latest"], guard["backend_rollback"]),
                         ("PASS", last, "refused"))
        self.assertEqual(guard["database"], self.database)

        # 6. De novo: o banco já está na última; recusa e não escreve.
        result = self.apply()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("este lote já foi aplicado", result.stderr)
        self.assertEqual(self.ledger()[-1], last)


if __name__ == "__main__":
    unittest.main()
