#!/usr/bin/env python3
"""BT-DR-001 (D-12, D-81): cadência do backup local e do ensaio isolado.

A política tem o RPO e o RTO da D-12 e o primeiro ciclo ligado ao receipt da
BT-REL-000; a cadência só passa com backup dentro do RPO e ensaio isolado
recente, aprovado, dentro do RTO e do mesmo dump; e o ciclo roda os scripts
de backup e de ensaio (aqui, shims) e grava o receipt. Nada sai da máquina.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import importlib.util
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "scripts" / "manaloom_backup_cadence.py"
CYCLE = REPO_ROOT / "scripts" / "manaloom_backup_cycle.sh"
POLICY_PATH = REPO_ROOT / "server" / "config" / "backup_policy.json"
FAKE_GIT_SHA = "fedcba9876543210fedcba9876543210fedcba98"
NOW = dt.datetime(2026, 9, 24, 12, 0, tzinfo=dt.timezone.utc)


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_dr_001_cadence", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


cadence = _load_module()


def _policy() -> dict:
    return json.loads(POLICY_PATH.read_text(encoding="utf-8"))


def _durable_root() -> Path:
    # O teste não pode usar /tmp: a própria política recusa diretório temporário.
    base = Path.home() / ".cache" / "manaloom-backup-cadence-test"
    base.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(dir=base))


def _stamp(moment: dt.datetime) -> str:
    return moment.strftime("%Y%m%dT%H%M%SZ")


def _iso(moment: dt.datetime) -> str:
    return moment.strftime("%Y-%m-%dT%H:%M:%SZ")


def _write_backup(backup_dir: Path, moment: dt.datetime, content: bytes = b"x" * 4096) -> Path:
    backup_dir.mkdir(parents=True, exist_ok=True)
    path = backup_dir / f"manaloom-postgres-{_stamp(moment)}.dump"
    path.write_bytes(content)
    return path


def _write_drill(
    backup_dir: Path,
    backup: Path,
    completed: dt.datetime,
    *,
    seconds: int = 51,
    status: str = "passed",
    table_count: int = 99,
    sha256: str | None = None,
) -> Path:
    evidence = backup_dir / "drills" / _stamp(completed) / "restore-result.json"
    evidence.parent.mkdir(parents=True, exist_ok=True)
    evidence.write_text(
        json.dumps(
            {
                "status": status,
                "mode": "full",
                "runner": "isolated_local_docker",
                "backup": {
                    "file": backup.name,
                    "sha256": sha256 or hashlib.sha256(backup.read_bytes()).hexdigest(),
                    "bytes": backup.stat().st_size,
                    "encrypted": False,
                },
                "started_at": _iso(completed - dt.timedelta(seconds=seconds)),
                "completed_at": _iso(completed),
                "table_count": table_count,
                "remote_writes": False,
            }
        ),
        encoding="utf-8",
    )
    return evidence


class PolicyTest(unittest.TestCase):
    def test_versioned_policy_follows_d12_and_d81(self) -> None:
        policy = _policy()
        self.assertEqual(cadence.policy_problems(policy), [])
        self.assertEqual(policy["objectives"]["rpo_hours"], 24)
        self.assertEqual(policy["objectives"]["rto_hours"], 4)
        self.assertIs(policy["backup"]["offsite_copy"], False)
        self.assertEqual(policy["backup"]["destination"], "backups/manaloom-postgres/")
        self.assertIsNone(policy["backup"]["retention_days"])
        self.assertEqual(policy["drill"]["network"], "none")
        self.assertEqual(policy["cadence"]["backup_max_interval_hours"], 24)

    def test_refuses_objectives_or_first_cycle_without_evidence(self) -> None:
        cases = []
        policy = _policy()
        policy["objectives"]["rpo_hours"] = 48
        cases.append((policy, "divergem da evidência"))
        policy = _policy()
        policy["objectives"]["evidence"] = "RPO de 12 h e RTO de 2 h"
        cases.append((policy, "não está na fonte"))
        policy = _policy()
        policy["first_cycle"]["backup_bytes"]["value"] = 1024
        cases.append((policy, "1024 não aparece"))
        policy = _policy()
        policy["first_cycle"]["backup_sha256"]["value"] = "0" * 64
        cases.append((policy, "não aparece na evidence"))
        policy = _policy()
        policy["backup"]["offsite_copy"] = True
        cases.append((policy, "D-81"))
        policy = _policy()
        policy["drill"]["network"] = "bridge"
        cases.append((policy, "isolado"))
        policy = _policy()
        policy["cadence"]["backup_max_interval_hours"] = 36
        cases.append((policy, "RPO"))
        policy = _policy()
        policy["backup"]["retention_note"] = ""
        cases.append((policy, "retention_note"))
        policy = _policy()
        policy["runbook"] = "docs/runbooks/NAO_EXISTE.md"
        cases.append((policy, "runbook não encontrado"))
        policy = _policy()
        policy["first_cycle"]["drill_seconds"]["evidence"] = "**passed**, 99 s"
        cases.append((policy, "evidence não está no receipt"))
        for policy, expected in cases:
            with self.subTest(expected=expected):
                problems = cadence.policy_problems(policy)
                self.assertTrue(any(expected in p for p in problems), problems)


class CheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _durable_root()
        self.backup_dir = self.root / "backups" / "manaloom-postgres"
        self.policy = _policy()

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _check(self) -> dict:
        return cadence.check(self.backup_dir, self.policy, NOW)

    def test_passes_with_fresh_backup_and_recent_drill(self) -> None:
        backup = _write_backup(self.backup_dir, NOW - dt.timedelta(hours=3))
        _write_drill(self.backup_dir, backup, NOW - dt.timedelta(hours=2))
        result = self._check()
        self.assertEqual(result["status"], "PASS", result)
        self.assertEqual(result["latest_drill"]["duration_seconds"], 51)
        self.assertIs(result["latest_drill"]["backup_checksum_matches"], True)

    def test_blocks_backup_older_than_the_rpo(self) -> None:
        backup = _write_backup(self.backup_dir, NOW - dt.timedelta(hours=25))
        _write_drill(self.backup_dir, backup, NOW - dt.timedelta(hours=24))
        result = self._check()
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any("RPO" in r for r in result["reasons"]), result)

    def test_blocks_without_backup(self) -> None:
        result = self._check()
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any("nenhum backup" in r for r in result["reasons"]))

    def test_blocks_old_failed_slow_or_mismatched_drill(self) -> None:
        cases = (
            ({"completed": NOW - dt.timedelta(days=8)}, "último ensaio"),
            ({"status": "failed"}, "nenhum ensaio"),
            ({"seconds": 5 * 3600}, "RTO"),
            ({"sha256": "0" * 64}, "SHA-256"),
            ({"table_count": 12}, "tabelas"),
        )
        for changes, expected in cases:
            with self.subTest(expected=expected):
                shutil.rmtree(self.backup_dir, ignore_errors=True)
                backup = _write_backup(self.backup_dir, NOW - dt.timedelta(hours=3))
                completed = changes.pop("completed", NOW - dt.timedelta(hours=2))
                _write_drill(self.backup_dir, backup, completed, **changes)
                result = self._check()
                self.assertEqual(result["status"], "BLOCKED", result)
                self.assertTrue(any(expected in r for r in result["reasons"]), result)

    def test_ignores_drills_that_were_not_isolated_or_wrote_remotely(self) -> None:
        backup = _write_backup(self.backup_dir, NOW - dt.timedelta(hours=3))
        evidence = _write_drill(self.backup_dir, backup, NOW - dt.timedelta(hours=2))
        data = json.loads(evidence.read_text(encoding="utf-8"))
        data["remote_writes"] = True
        evidence.write_text(json.dumps(data), encoding="utf-8")
        result = self._check()
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any("nenhum ensaio" in r for r in result["reasons"]))

    def test_refuses_temporary_backup_directories(self) -> None:
        for path in (
            Path("/tmp/manaloom-backups"),
            Path.home() / "x" / ".claude" / "worktrees" / "agent" / "backups",
        ):
            with self.subTest(path=str(path)):
                with self.assertRaises(cadence.InvalidInput):
                    cadence.check(path, self.policy, NOW)


class ScriptInterfaceTest(unittest.TestCase):
    """Os shims do ciclo seguem a interface dos scripts reais de backup e de ensaio."""

    def setUp(self) -> None:
        self.backup = (REPO_ROOT / "scripts" / "manaloom_easypanel_backup.sh").read_text(
            encoding="utf-8"
        )
        self.drill = (REPO_ROOT / "scripts" / "manaloom_full_restore_drill.sh").read_text(
            encoding="utf-8"
        )

    def test_backup_script_names_and_reports_the_dump_the_cycle_reads(self) -> None:
        self.assertIn('BACKUP_DIR="${MANALOOM_BACKUP_DIR:-', self.backup)
        self.assertIn('STAMP="$(date -u +%Y%m%dT%H%M%SZ)"', self.backup)
        self.assertIn('OUT_FILE="$BACKUP_DIR/manaloom-postgres-$STAMP.dump"', self.backup)
        self.assertIn('echo "[backup] ok file=$OUT_FILE bytes=$BYTES"', self.backup)
        self.assertIn('require_live_mutation_approval "backup do PostgreSQL', self.backup)
        # O nome que o backup grava é o que a cadência reconhece.
        self.assertTrue(cadence.BACKUP_NAME.match("manaloom-postgres-20260928T120000Z.dump"))
        # A linha que o backup imprime é a que o ciclo lê.
        cycle = CYCLE.read_text(encoding="utf-8")
        pattern = re.search(r"sed -n '(s/.*?/p)'", cycle)
        self.assertIsNotNone(pattern, "o ciclo não lê a linha [backup] ok")
        parsed = subprocess.run(
            ["sed", "-n", pattern.group(1)],
            input="[backup] host=h service=s db=d\n[backup] ok file=/d/x.dump bytes=4096\n",
            capture_output=True, text=True, check=True,
        ).stdout
        self.assertEqual(parsed, "/d/x.dump\n")

    def test_drill_script_takes_the_cycle_flags_and_writes_what_the_check_reads(self) -> None:
        for flag in ("--backup)", "--evidence-dir)", "--execute)"):
            self.assertIn(flag, self.drill)
        self.assertIn('"${MANALOOM_RESTORE_DRILL_EXECUTE:-0}" != "1"', self.drill)
        self.assertIn("--network none", self.drill)
        self.assertIn("--arg runner isolated_local_docker", self.drill)
        self.assertIn('tee "$EVIDENCE_DIR/restore-result.json"', self.drill)
        for field in (
            "status: $status",
            "mode: $mode",
            "runner: $runner",
            "file: $backup_file",
            "sha256: $archive_sha256",
            "started_at: $started_at",
            "completed_at: $completed_at",
            "table_count: $table_count",
            "remote_writes: false",
        ):
            self.assertIn(field, self.drill)
        default = re.search(r'MIN_TABLES="\$\{MANALOOM_RESTORE_MIN_TABLES:-(\d+)\}"', self.drill)
        self.assertIsNotNone(default)
        self.assertEqual(_policy()["drill"]["min_tables"], int(default.group(1)))
        self.assertEqual(_policy()["drill"]["runner"], "isolated_local_docker")


class CycleTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = _durable_root()
        self.repo = self.root / "repo"
        for relative in (
            "scripts/manaloom_backup_cycle.sh",
            "scripts/manaloom_backup_cadence.py",
            "server/config/backup_policy.json",
            "docs/qa/execution/2026-09-23/BT-REL-000-linha-de-base-contida.md",
            "docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md",
            "docs/runbooks/BACKUP_E_RESTAURACAO.md",
        ):
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        self.log = self.root / "calls.jsonl"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        record = (
            f'"{sys.executable}" -c \'import json,os,sys; '
            f'open(sys.argv[1],"a").write(json.dumps([sys.argv[2], *sys.argv[3:], '
            f'os.environ.get("MANALOOM_BACKUP_DIR","")])+"\\n")\' '
            f'"{self.log}" "$(basename "$0")" "$@"\n'
        )
        self._shim(
            self.repo / "scripts/manaloom_easypanel_backup.sh",
            record
            + 'out="$MANALOOM_BACKUP_DIR/manaloom-postgres-$(date -u +%Y%m%dT%H%M%SZ).dump"\n'
            + 'head -c 4096 /dev/zero > "$out"\n'
            + 'echo "[backup] host=teste service=evolution_manaloom-postgres db=halder"\n'
            + 'echo "[backup] ok file=$out bytes=4096"\n',
        )
        self._shim(
            self.repo / "scripts/manaloom_full_restore_drill.sh",
            record
            + f'"{sys.executable}" - "$@" <<\'PY\'\n'
            + "import datetime, hashlib, json, os, sys\n"
            + "args = sys.argv[1:]\n"
            + "backup = args[args.index('--backup') + 1]\n"
            + "evidence = args[args.index('--evidence-dir') + 1]\n"
            + "os.makedirs(evidence, exist_ok=True)\n"
            + "now = datetime.datetime.now(datetime.timezone.utc)\n"
            + "fmt = '%Y-%m-%dT%H:%M:%SZ'\n"
            + "json.dump({'status': 'passed', 'mode': 'full', 'runner': 'isolated_local_docker',\n"
            + "  'backup': {'file': os.path.basename(backup),\n"
            + "    'sha256': hashlib.sha256(open(backup, 'rb').read()).hexdigest()},\n"
            + "  'started_at': (now - datetime.timedelta(seconds=60)).strftime(fmt),\n"
            + "  'completed_at': now.strftime(fmt), 'table_count': 99,\n"
            + "  'remote_writes': False}, open(os.path.join(evidence, 'restore-result.json'), 'w'))\n"
            + "PY\n",
        )
        self._shim(self.bin / "git", record + f"echo {FAKE_GIT_SHA}\n")
        (self.bin / "python3").symlink_to(sys.executable)
        self.backup_dir = self.root / "operacao" / "backups" / "manaloom-postgres"
        self.env = {
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "HOME": str(self.root),
            "MANALOOM_BACKUP_DIR": str(self.backup_dir),
        }

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def _shim(self, path: Path, body: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
        path.chmod(0o755)

    def _run(self, *args: str, env: dict | None = None) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/manaloom_backup_cycle.sh"), *args],
            capture_output=True, text=True, env=env or self.env, check=False,
        )

    def _calls(self) -> list[list[str]]:
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]

    def test_without_execute_it_only_describes_the_cycle(self) -> None:
        result = self._run("--drill")
        self.assertEqual(result.returncode, 0, result.stderr)
        described = json.loads(result.stdout)
        self.assertEqual(described["status"], "dry_run")
        self.assertEqual(len(described["steps"]), 3)
        self.assertEqual(self._calls(), [])
        self.assertFalse(self.backup_dir.exists())

    def test_cycle_with_drill_writes_a_passing_receipt(self) -> None:
        result = self._run("--execute", "--drill")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self._calls()
        programs = [call[0] for call in calls]
        self.assertEqual(programs.count("manaloom_easypanel_backup.sh"), 1, calls)
        self.assertEqual(programs.count("manaloom_full_restore_drill.sh"), 1, calls)
        backup_call = calls[programs.index("manaloom_easypanel_backup.sh")]
        self.assertEqual(backup_call[-1], str(self.backup_dir))
        drill_call = calls[programs.index("manaloom_full_restore_drill.sh")]
        self.assertIn("--execute", drill_call)
        evidence_dir = drill_call[drill_call.index("--evidence-dir") + 1]
        self.assertTrue(evidence_dir.startswith(str(self.backup_dir / "drills")))
        receipts = sorted((self.backup_dir / "receipts").glob("*.json"))
        self.assertEqual(len(receipts), 1)
        receipt = json.loads(receipts[0].read_text(encoding="utf-8"))
        self.assertEqual(receipt["cadence"]["status"], "PASS", receipt)
        self.assertEqual(receipt["tool_git_sha"], FAKE_GIT_SHA)
        self.assertEqual(receipt["drill"]["status"], "passed")
        self.assertEqual(receipt["backup"]["bytes"], 4096)
        self.assertEqual(oct(receipts[0].stat().st_mode & 0o777), "0o600")

    def test_cycle_without_drill_is_blocked_until_a_drill_exists(self) -> None:
        result = self._run("--execute")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertNotIn("manaloom_full_restore_drill.sh", [c[0] for c in self._calls()])
        receipt = json.loads(next((self.backup_dir / "receipts").glob("*.json")).read_text())
        self.assertIsNone(receipt["drill"])
        self.assertTrue(any("nenhum ensaio" in r for r in receipt["cadence"]["reasons"]))

    def test_cycle_requires_an_explicit_backup_directory(self) -> None:
        env = dict(self.env)
        del env["MANALOOM_BACKUP_DIR"]
        result = self._run("--execute", "--drill", env=env)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("MANALOOM_BACKUP_DIR", result.stderr)
        self.assertEqual(self._calls(), [])
        self.assertFalse((self.repo / "backups").exists())

    def test_cycle_refuses_a_temporary_backup_directory(self) -> None:
        env = dict(self.env)
        env["MANALOOM_BACKUP_DIR"] = "/tmp/manaloom-backup-cycle-test"
        result = self._run("--execute", "--drill", env=env)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(self._calls(), [])


if __name__ == "__main__":
    unittest.main()
