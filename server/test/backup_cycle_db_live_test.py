#!/usr/bin/env python3
"""BT-DR-001: o ciclo de backup com o ensaio real, num PostgreSQL descartável.

Requer RUN_SCHEMA_DB_TESTS=1 e as variáveis DB_* de um PostgreSQL descartável
em loopback, já migrado, e os binários do PostgreSQL do mesmo major do
servidor (MANALOOM_PG_BIN ou o PATH).

O ciclo (`scripts/manaloom_backup_cycle.sh --execute --drill`) roda com:
- no lugar do backup da produção, um `pg_dump -Fc` do banco descartável, com a
  mesma saída de `scripts/manaloom_easypanel_backup.sh`;
- o script de ensaio real (`scripts/manaloom_full_restore_drill.sh`), com um
  `docker` de teste que sobe um PostgreSQL local, só em loopback e sem socket,
  no lugar do container, e recusa `docker run` sem `--network none`.

Confere que o dump restaura por inteiro (tabelas, chaves, restrições e as
contagens de users, cards, decks e deck_cards) e que o receipt sai PASS.
Nada sai da máquina.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ENABLED = os.environ.get("RUN_SCHEMA_DB_TESTS") == "1"
APPROVED_IMAGE = (
    "postgres:17.10-alpine3.23@sha256:"
    "8189a1f6e40904781fc9e2612687877791d21679866db58b1de996b31fc312e4"
)
REPO_FILES = (
    "scripts/manaloom_backup_cycle.sh",
    "scripts/manaloom_backup_cadence.py",
    "scripts/manaloom_full_restore_drill.sh",
    "server/config/backup_policy.json",
    "docs/qa/execution/2026-09-23/BT-REL-000-linha-de-base-contida.md",
    "docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md",
    "docs/runbooks/BACKUP_E_RESTAURACAO.md",
)

# docker de teste: `run` sobe um cluster local (initdb + pg_ctl), `exec` roda o
# binário do PostgreSQL contra ele com o volume traduzido e `rm -f` derruba.
FAKE_DOCKER = r'''
import json, os, secrets, shutil, socket, subprocess, sys

STATE = os.environ["FAKE_DOCKER_STATE"]
PG_BIN = os.environ["FAKE_DOCKER_PG_BIN"]


def log(argv):
    with open(os.path.join(STATE, "calls.jsonl"), "a", encoding="utf-8") as handle:
        handle.write(json.dumps(argv) + "\n")


def quiet(argv):
    subprocess.run(argv, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run(args):
    name = network = image = None
    mounts, detach, index = {}, False, 0
    while index < len(args):
        arg = args[index]
        if arg == "-d":
            detach, index = True, index + 1
        elif arg in ("--name", "--network", "-e", "-v"):
            value = args[index + 1]
            if arg == "--name":
                name = value
            elif arg == "--network":
                network = value
            elif arg == "-v":
                source, target = value.split(":")[:2]
                mounts[target] = source
            index += 2
        elif arg.startswith("-"):
            print("docker de teste: opção não suportada: " + arg, file=sys.stderr)
            return 2
        else:
            image, rest = arg, args[index + 1:]
            break
    if network != "none":
        print("docker de teste: o ensaio tem de rodar sem rede", file=sys.stderr)
        return 3
    if not detach or not name or image is None or rest:
        print("docker de teste: docker run inesperado", file=sys.stderr)
        return 2
    base = os.path.join(STATE, name)
    data = os.path.join(base, "data")
    os.makedirs(base)
    quiet([os.path.join(PG_BIN, "initdb"), "-D", data, "-U", "postgres", "--auth=trust",
           "--no-locale", "--encoding=UTF8"])
    probe = socket.socket()
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
    probe.close()
    quiet([os.path.join(PG_BIN, "pg_ctl"), "-D", data, "-l", os.path.join(base, "postgres.log"),
           "-o", f"-F -p {port} -h 127.0.0.1 -c unix_socket_directories=''", "-w", "start"])
    with open(os.path.join(base, "container.json"), "w", encoding="utf-8") as handle:
        json.dump({"port": port, "mounts": mounts, "image": image}, handle)
    print(secrets.token_hex(32))
    return 0


def exec_(args):
    name, program, rest = args[0], args[1], args[2:]
    if program not in ("pg_isready", "createdb", "pg_restore", "psql"):
        print("docker de teste: exec não suportado: " + program, file=sys.stderr)
        return 2
    with open(os.path.join(STATE, name, "container.json"), encoding="utf-8") as handle:
        meta = json.load(handle)
    rest = [meta["mounts"].get(arg, arg) for arg in rest]
    argv = [os.path.join(PG_BIN, program), "-h", "127.0.0.1", "-p", str(meta["port"])]
    if program == "psql":
        argv.append("-X")
    return subprocess.call(argv + rest)


def rm(args):
    for name in (arg for arg in args if not arg.startswith("-")):
        base = os.path.join(STATE, name)
        if os.path.isdir(base):
            subprocess.run([os.path.join(PG_BIN, "pg_ctl"), "-D", os.path.join(base, "data"),
                            "-m", "immediate", "stop"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            shutil.rmtree(base)
    return 0


def main(argv):
    log(argv)
    if argv[:1] == ["info"]:
        return 0
    handlers = {"run": run, "exec": exec_, "rm": rm}
    if not argv or argv[0] not in handlers:
        print("docker de teste: comando não suportado", file=sys.stderr)
        return 2
    return handlers[argv[0]](argv[1:])


sys.exit(main(sys.argv[1:]))
'''

# Backup de teste: a mesma saída do backup real, mas lendo o banco descartável.
FAKE_BACKUP = r'''#!/bin/bash
set -euo pipefail
BACKUP_DIR="${MANALOOM_BACKUP_DIR:?}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$BACKUP_DIR/manaloom-postgres-$STAMP.dump"
mkdir -p "$BACKUP_DIR"
echo "[backup] host=descartavel service=local db=$DB_NAME"
PGPASSWORD="${DB_PASS:-}" "$FAKE_DOCKER_PG_BIN/pg_dump" -Fc -h "$DB_HOST" -p "$DB_PORT" \
  -U "$DB_USER" "$DB_NAME" > "$OUT_FILE"
chmod 600 "$OUT_FILE"
BYTES="$(wc -c < "$OUT_FILE" | tr -d ' ')"
"$FAKE_DOCKER_PG_BIN/pg_restore" --list "$OUT_FILE" >/dev/null
echo "[backup] ok file=$OUT_FILE bytes=$BYTES"
'''


def _pg_bin(server_major: int) -> Path:
    candidates = []
    if os.environ.get("MANALOOM_PG_BIN"):
        candidates.append(Path(os.environ["MANALOOM_PG_BIN"]))
    found = shutil.which("pg_dump")
    if found:
        candidates.append(Path(found).parent)
    candidates.append(Path(f"/opt/homebrew/opt/postgresql@{server_major}/bin"))
    for candidate in candidates:
        pg_dump = candidate / "pg_dump"
        if not pg_dump.exists():
            continue
        version = subprocess.run([str(pg_dump), "--version"], capture_output=True, text=True)
        match = re.search(r"(\d+)\.\d+", version.stdout)
        if match and int(match.group(1)) == server_major:
            return candidate
    raise AssertionError(f"binários do PostgreSQL {server_major} não encontrados")


@unittest.skipUnless(ENABLED, "Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.")
class BackupCycleOnDisposablePostgresTest(unittest.TestCase):
    def setUp(self) -> None:
        if os.environ.get("DB_HOST", "127.0.0.1") not in {"127.0.0.1", "localhost", "::1"}:
            self.fail("RUN_SCHEMA_DB_TESTS só roda em banco loopback")
        self.db = {key: os.environ.get(key, "") for key in
                   ("DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME")}
        self.db["DB_HOST"] = self.db["DB_HOST"] or "127.0.0.1"
        self.db["DB_PORT"] = self.db["DB_PORT"] or "5432"
        which_psql = shutil.which("psql")
        assert which_psql, "psql ausente"
        major = int(self._psql("SHOW server_version_num", psql=which_psql)) // 10000
        self.pg_bin = _pg_bin(major)
        # O ciclo recusa /tmp e worktree: a raiz do teste fica em ~/.cache.
        base = Path.home() / ".cache" / "manaloom-backup-cycle-db-test"
        base.mkdir(parents=True, exist_ok=True)
        self.root = Path(tempfile.mkdtemp(dir=base))
        self.repo = self.root / "repo"
        for relative in REPO_FILES:
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        backup = self.repo / "scripts" / "manaloom_easypanel_backup.sh"
        backup.write_text(FAKE_BACKUP, encoding="utf-8")
        backup.chmod(0o755)
        self.state = self.root / "docker"
        self.state.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        docker = self.bin / "docker"
        docker.write_text(f"#!{sys.executable}\n" + FAKE_DOCKER, encoding="utf-8")
        docker.chmod(0o755)
        git = self.bin / "git"
        git.write_text("#!/bin/bash\necho " + "c" * 40 + "\n", encoding="utf-8")
        git.chmod(0o755)
        (self.bin / "python3").symlink_to(sys.executable)
        self.backup_dir = self.root / "operacao" / "backups" / "manaloom-postgres"
        self.env = {
            **self.db,
            "PATH": f"{self.bin}:{self.pg_bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": str(self.root),
            "LC_ALL": "C",
            "LANG": "C",
            "MANALOOM_BACKUP_DIR": str(self.backup_dir),
            "MANALOOM_RESTORE_DRILL_EXECUTE": "1",
            "FAKE_DOCKER_STATE": str(self.state),
            "FAKE_DOCKER_PG_BIN": str(self.pg_bin),
        }
        self.marker = uuid.uuid4().hex[:12]
        self._psql(
            "WITH u AS (INSERT INTO users (username, email, password_hash) "
            f"VALUES ('bt_dr_{self.marker}', 'bt_dr_{self.marker}@example.invalid', 'x') "
            "RETURNING id), c AS (INSERT INTO cards (scryfall_id, name) "
            f"VALUES (gen_random_uuid(), 'BT-DR {self.marker}') RETURNING id), "
            "d AS (INSERT INTO decks (user_id, name, format) "
            f"SELECT id, 'BT-DR {self.marker}', 'commander' FROM u RETURNING id) "
            "INSERT INTO deck_cards (deck_id, card_id) SELECT d.id, c.id FROM d, c"
        )

    def tearDown(self) -> None:
        self._psql(f"DELETE FROM users WHERE username = 'bt_dr_{self.marker}'")
        self._psql(f"DELETE FROM cards WHERE name = 'BT-DR {self.marker}'")
        subprocess.run(["/bin/bash", "-c", 'for d in "$0"/*/; do [ -d "$d/data" ] && '
                        '"$1/pg_ctl" -D "$d/data" -m immediate stop; done',
                        str(self.state), str(self.pg_bin)],
                       capture_output=True, check=False)
        shutil.rmtree(self.root, ignore_errors=True)

    def _psql(self, sql: str, psql: str | None = None) -> str:
        program = psql or str(self.pg_bin / "psql")
        result = subprocess.run(
            [program, "-X", "-qAt", "-v", "ON_ERROR_STOP=1", "-h", self.db["DB_HOST"],
             "-p", self.db["DB_PORT"], "-U", self.db["DB_USER"], "-d", self.db["DB_NAME"],
             "-c", sql],
            capture_output=True, text=True, check=False,
            env={**os.environ, "PGPASSWORD": self.db["DB_PASS"]},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def _calls(self) -> list[list[str]]:
        path = self.state / "calls.jsonl"
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]

    def test_cycle_restores_the_dump_in_full_and_records_a_passing_receipt(self) -> None:
        expected_tables = int(self._psql(
            "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema = 'public' AND table_type = 'BASE TABLE'"))
        expected_fks = int(self._psql("SELECT COUNT(*) FROM pg_constraint WHERE contype = 'f'"))
        expected_rows = {
            table: int(self._psql(f"SELECT COUNT(*) FROM public.{table}"))
            for table in ("users", "cards", "decks", "deck_cards")
        }
        self.assertTrue(all(count >= 1 for count in expected_rows.values()), expected_rows)

        result = subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/manaloom_backup_cycle.sh"),
             "--execute", "--drill"],
            capture_output=True, text=True, env=self.env, check=False, timeout=600,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-4000:] + result.stderr[-4000:])

        receipts = sorted((self.backup_dir / "receipts").glob("*.json"))
        self.assertEqual(len(receipts), 1)
        receipt = json.loads(receipts[0].read_text(encoding="utf-8"))
        self.assertEqual(receipt["cadence"]["status"], "PASS", receipt)
        dumps = sorted(self.backup_dir.glob("manaloom-postgres-*.dump"))
        self.assertEqual(len(dumps), 1)
        self.assertEqual(receipt["backup"]["file"], dumps[0].name)
        self.assertEqual(receipt["backup"]["sha256"],
                         hashlib.sha256(dumps[0].read_bytes()).hexdigest())

        evidence = json.loads((self.backup_dir / receipt["drill"]["evidence"])
                              .read_text(encoding="utf-8"))
        self.assertEqual(evidence["status"], "passed")
        self.assertEqual(evidence["runner"], "isolated_local_docker")
        self.assertIs(evidence["remote_writes"], False)
        self.assertIs(evidence["constraints_immediate"], True)
        self.assertEqual(evidence["backup"]["sha256"], receipt["backup"]["sha256"])
        self.assertEqual(evidence["table_count"], expected_tables)
        self.assertEqual(evidence["foreign_key_count"], expected_fks)
        self.assertEqual(evidence["critical_row_counts"], expected_rows)
        started = dt.datetime.strptime(evidence["started_at"], "%Y-%m-%dT%H:%M:%SZ")
        completed = dt.datetime.strptime(evidence["completed_at"], "%Y-%m-%dT%H:%M:%SZ")
        self.assertEqual(receipt["cadence"]["latest_drill"]["duration_seconds"],
                         int((completed - started).total_seconds()))
        self.assertIs(receipt["cadence"]["latest_drill"]["backup_checksum_matches"], True)

        runs = [call for call in self._calls() if call[:1] == ["run"]]
        self.assertEqual(len(runs), 1)
        self.assertIn("--network", runs[0])
        self.assertEqual(runs[0][runs[0].index("--network") + 1], "none")
        self.assertEqual(runs[0][-1], APPROVED_IMAGE)
        self.assertTrue(any(call[:2] == ["rm", "-f"] for call in self._calls()))
        # O ensaio derrubou o PostgreSQL dele: nada sobra no estado do docker de teste.
        self.assertEqual([p.name for p in self.state.iterdir() if p.is_dir()], [])


if __name__ == "__main__":
    unittest.main()
