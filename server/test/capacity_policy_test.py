#!/usr/bin/env python3
"""BT-CAP-001 (D-14): política de capacidade, snapshot só de leitura e preflight.

A política versionada tem de apontar cada número para o receipt da leitura; o
snapshot só vale com a procedência do host de produção; o preflight bloqueia
sem folga; e a ferramenta de leitura não conecta sem --execute nem roda nada
que mude o host. A ferramenta roda aqui contra shims de ssh, git e do wrapper
do PostgreSQL: nenhuma conexão sai da máquina.
"""

from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "manaloom_capacity_snapshot.sh"
MODULE_PATH = REPO_ROOT / "scripts" / "manaloom_capacity_policy.py"
POLICY_PATH = REPO_ROOT / "server" / "config" / "capacity_policy.json"
FAKE_HOST_KEY = "SHA256:" + "A" * 43
FAKE_GIT_SHA = "0123456789abcdef0123456789abcdef01234567"


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_cap_001_policy", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


capacity = _load_module()

HOST_RAW = """### date
2026-09-24T12:00:00Z
### nproc
4
### meminfo
MemTotal:        8131796 kB
MemFree:          812000 kB
MemAvailable:    6639616 kB
SwapTotal:             0 kB
SwapFree:              0 kB
### loadavg
0.42 0.38 0.35 2/412 123456
### uptime
8640000.00 30000000.00
### kernel
6.8.0-139-generic
### df
Filesystem     1-blocks         Used    Available Capacity Mounted on
/dev/sda1  171798691840 115964116992 51539607552      70% /
### docker_stats
{"BlockIO":"0B / 0B","CPUPerc":"0.52%","Container":"a1","ID":"a1","MemPerc":"2.67%","MemUsage":"212.3MiB / 7.755GiB","Name":"evolution_manaloom-postgres.1.k3j4h5g6f7d8s9a0p1o2i3u4y","NetIO":"0B / 0B","PIDs":"12"}
{"BlockIO":"0B / 0B","CPUPerc":"0.10%","Container":"a2","ID":"a2","MemPerc":"0.57%","MemUsage":"45.1MiB / 7.755GiB","Name":"evolution_cartinhas.1.abcdefghijklmnopqrstuvwxy","NetIO":"0B / 0B","PIDs":"9"}
{"BlockIO":"0B / 0B","CPUPerc":"0.00%","Container":"a3","ID":"a3","MemPerc":"0.10%","MemUsage":"8.2MiB / 7.755GiB","Name":"manaloom-pg-local-proxy","NetIO":"0B / 0B","PIDs":"2"}
{"BlockIO":"0B / 0B","CPUPerc":"1.20%","Container":"a4","ID":"a4","MemPerc":"3.78%","MemUsage":"300MiB / 7.755GiB","Name":"carmatch_worker.1.zyxwvutsrqponmlkjihgfedcb","NetIO":"0B / 0B","PIDs":"20"}
### docker_services
{"ID":"s1","Image":"postgres:17.10-alpine","Mode":"replicated","Name":"evolution_manaloom-postgres","Ports":"","Replicas":"1/1"}
{"ID":"s2","Image":"localhost:5000/manaloom/cartinhas@sha256:abc","Mode":"replicated","Name":"evolution_cartinhas","Ports":"","Replicas":"1/1"}
{"ID":"s3","Image":"localhost:5000/manaloom/xmage-sidecar@sha256:def","Mode":"replicated","Name":"evolution_xmage-interactive","Ports":"","Replicas":"0/0"}
{"ID":"s4","Image":"carmatch/worker:latest","Mode":"replicated","Name":"carmatch_worker","Ports":"","Replicas":"1/1"}
### docker_resources
evolution_manaloom-postgres\t{"Limits":{},"Reservations":{}}
evolution_cartinhas\t{"Limits":{},"Reservations":{}}
evolution_xmage-interactive\t{"Limits":{"MemoryBytes":4294967296},"Reservations":{"MemoryBytes":536870912}}
carmatch_worker\t{}
### end
""".replace("\\t", "\t")

POSTGRES_RAW = "\n".join(
    [
        "transaction_read_only\ton",
        "server_version\t17.10",
        "max_connections\t100",
        "shared_buffers\t128MB",
        "effective_cache_size\t4GB",
        "work_mem\t4MB",
        "database_size_bytes\t734003200",
        "connections_total\t7",
        "connections_state:active\t1",
        "connections_state:idle\t6",
        "schema_bytes:manaloom_deploy_audit\t104857600",
        "schema_bytes:public\t629145600",
        "relation_bytes:public.cards\t314572800",
        "relation_bytes:public.card_legalities\t104857600",
    ]
)


def _policy() -> dict:
    return json.loads(POLICY_PATH.read_text(encoding="utf-8"))


def _snapshot(policy: dict) -> dict:
    return capacity.build_snapshot(
        host_raw=HOST_RAW,
        postgres_raw=POSTGRES_RAW,
        ssh_target=policy["production"]["ssh_target"],
        host_key=FAKE_HOST_KEY,
        git_sha=FAKE_GIT_SHA,
        tree_clean=True,
        collected_at="2026-09-24T12:00:05Z",
    )


def _remote_script() -> str:
    source = SCRIPT.read_text(encoding="utf-8")
    start = source.index("<<'REMOTE'\n") + len("<<'REMOTE'\n")
    return source[start : source.index("\nREMOTE\n", start)]


class PolicyTest(unittest.TestCase):
    def test_versioned_policy_is_valid_and_traceable_to_the_receipt(self) -> None:
        policy = _policy()
        self.assertEqual(capacity.policy_problems(policy), [])
        host = policy["baseline"]["host"]
        self.assertEqual(host["cpu_count"]["value"], 4)
        self.assertEqual(host["memory_total_mb"]["value"], 7941)
        self.assertEqual(host["disk_root_used_percent"]["value"], 70)
        self.assertEqual(
            policy["baseline"]["provenance"]["receipt"],
            "docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md",
        )
        self.assertEqual(policy["thresholds"]["status"], "proposta_pendente_do_dono")

    def test_refuses_baseline_without_provenance(self) -> None:
        policy = _policy()
        del policy["baseline"]["provenance"]
        self.assertIn("baseline.provenance ausente", capacity.policy_problems(policy))

    def test_refuses_receipt_from_temporary_copy_or_outside_the_receipts(self) -> None:
        for receipt, expected in (
            ("/tmp/host.md", "caminho relativo"),
            ("tmp/host.md", "cópia temporária"),
            (".claude/worktrees/agent/docs/qa/execution/x.md", "cópia temporária"),
            ("docs/qa/execution/../../../tmp/x.md", "caminho relativo"),
            ("server/doc/CAPACITY_PLAN_10K_MAU.md", "docs/qa/execution/"),
            ("docs/qa/execution/2026-09-23/nao-existe.md", "não encontrado"),
        ):
            with self.subTest(receipt=receipt):
                policy = _policy()
                policy["baseline"]["provenance"]["receipt"] = receipt
                problems = capacity.policy_problems(policy)
                self.assertTrue(
                    any(expected in problem for problem in problems), problems
                )

    def test_refuses_numbers_that_the_receipt_does_not_show(self) -> None:
        policy = _policy()
        policy["baseline"]["host"]["memory_total_mb"]["value"] = 8192
        self.assertTrue(
            any("8192 não aparece" in p for p in capacity.policy_problems(policy))
        )
        policy = _policy()
        policy["baseline"]["host"]["cpu_count"]["evidence"] = "8 vCPU"
        self.assertTrue(
            any("não está no receipt" in p for p in capacity.policy_problems(policy))
        )
        policy = _policy()
        policy["baseline"]["services"]["evolution_manaloom-postgres"]["memory_mib"][
            "value"
        ] = 512
        self.assertTrue(
            any("512 não aparece" in p for p in capacity.policy_problems(policy))
        )

    def test_refuses_invalid_schema(self) -> None:
        cases = []
        policy = _policy()
        policy["schema_version"] = 2
        cases.append((policy, "schema_version"))
        policy = _policy()
        del policy["thresholds"]["memory_available_min_mb"]
        cases.append((policy, "thresholds.memory_available_min_mb"))
        policy = _policy()
        policy["thresholds"]["disk_root_used_max_percent"] = 120
        cases.append((policy, "fora de 0-100"))
        policy = _policy()
        del policy["thresholds"]["rationale"]["load1_per_cpu_max"]
        cases.append((policy, "rationale"))
        policy = _policy()
        policy["baseline"]["measured_at"] = "2026-09-23 09:13"
        cases.append((policy, "measured_at"))
        policy = _policy()
        policy["production"]["host_key_sha256"] = "md5:abc"
        cases.append((policy, "host_key_sha256"))
        for policy, expected in cases:
            with self.subTest(expected=expected):
                problems = capacity.policy_problems(policy)
                self.assertTrue(any(expected in p for p in problems), problems)


class SnapshotTest(unittest.TestCase):
    def test_parses_the_host_reading(self) -> None:
        measured_at, host, services = capacity.parse_host(HOST_RAW)
        self.assertEqual(measured_at, "2026-09-24T12:00:00Z")
        self.assertEqual(host["cpu_count"], 4)
        self.assertEqual(host["memory_total_mb"], 7941)
        self.assertEqual(host["memory_available_mb"], 6484)
        self.assertEqual(host["swap_total_mb"], 0)
        self.assertEqual(host["load1"], 0.42)
        self.assertEqual(host["uptime_days"], 100)
        self.assertEqual(host["disk_root_free_gib"], 48.0)
        self.assertEqual(host["disk_root_used_percent"], 69.2)
        by_name = {service["name"]: service for service in services}
        self.assertEqual(by_name["evolution_manaloom-postgres"]["memory_used_mib"], 212.3)
        self.assertEqual(by_name["evolution_manaloom-postgres"]["replicas"], "1/1")
        self.assertEqual(by_name["evolution_manaloom-postgres"]["project"], "evolution")
        self.assertEqual(by_name["carmatch_worker"]["project"], "outro")
        self.assertEqual(by_name["manaloom-pg-local-proxy"]["containers"], 1)
        self.assertEqual(
            by_name["evolution_xmage-interactive"]["resources"]["Limits"]["MemoryBytes"],
            4294967296,
        )
        self.assertEqual(by_name["evolution_xmage-interactive"]["containers"], 0)

    def test_container_without_stats_does_not_break_the_reading(self) -> None:
        starting = (
            '{"BlockIO":"--","CPUPerc":"--","Container":"a5","ID":"a5","MemPerc":"--",'
            '"MemUsage":"-- / --","Name":"evolution_manaloom-ops.1.qwertyuiopasdfghjklzxcvbn",'
            '"NetIO":"--","PIDs":"--"}\n'
        )
        raw = HOST_RAW.replace("### docker_services\n", starting + "### docker_services\n")
        _measured_at, _host, services = capacity.parse_host(raw)
        ops = {service["name"]: service for service in services}["evolution_manaloom-ops"]
        self.assertEqual(ops["containers_without_stats"], 1)
        self.assertNotIn("memory_used_mib", ops)

    def test_incomplete_host_reading_is_refused(self) -> None:
        with self.assertRaises(capacity.InvalidInput):
            capacity.parse_host(HOST_RAW.replace("### df\n", "### disco\n"))

    def test_postgres_reading_must_be_read_only(self) -> None:
        self.assertEqual(capacity.parse_postgres(POSTGRES_RAW)["connections_total"], 7)
        with self.assertRaises(capacity.InvalidInput):
            capacity.parse_postgres(
                POSTGRES_RAW.replace("transaction_read_only\ton", "transaction_read_only\toff")
            )

    def test_snapshot_needs_the_production_provenance(self) -> None:
        policy = _policy()
        snapshot = _snapshot(policy)
        self.assertEqual(capacity.snapshot_problems(snapshot, policy), [])
        for field, value, expected in (
            ("ssh_target", "root@127.0.0.1", "host de produção"),
            ("ssh_target", "dev@localhost", "host de produção"),
            ("host_key_sha256", "", "host_key_sha256"),
            ("tool", "/tmp/copia/scripts/manaloom_capacity_snapshot.sh", "provenance.tool"),
            (
                "tool",
                "/x/.claude/worktrees/agent/scripts/manaloom_capacity_snapshot.sh",
                "provenance.tool",
            ),
            ("tool_git_sha", "HEAD", "tool_git_sha"),
            ("kind", "local_docker", "provenance.kind"),
        ):
            with self.subTest(field=field, value=value):
                changed = copy.deepcopy(snapshot)
                changed["provenance"][field] = value
                problems = capacity.snapshot_problems(changed, policy)
                self.assertTrue(any(expected in p for p in problems), problems)

    def test_pinned_host_key_must_match(self) -> None:
        policy = _policy()
        policy["production"]["host_key_sha256"] = "SHA256:" + "B" * 43
        problems = capacity.snapshot_problems(_snapshot(policy), policy)
        self.assertTrue(any("âncora fixada" in p for p in problems), problems)


class PreflightTest(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = _policy()
        self.snapshot = _snapshot(self.policy)
        self.now = dt.datetime(2026, 9, 24, 12, 10, tzinfo=dt.timezone.utc)

    def test_passes_with_headroom(self) -> None:
        result = capacity.preflight(self.snapshot, self.policy, self.now)
        self.assertEqual(result["status"], "PASS", result)
        self.assertEqual(result["checks"]["swap_used_percent"], "sem swap no host")

    def test_blocks_without_memory_disk_or_connections(self) -> None:
        for path, value, expected in (
            (("host", "memory_available_mb"), 1500, "memory_available_mb"),
            (("host", "disk_root_used_percent"), 91.0, "disk_root_used_percent"),
            (("host", "disk_root_free_gib"), 12.0, "disk_root_free_gib"),
            (("host", "load1"), 8.0, "load1_per_cpu"),
            (("postgres", "connections_total"), 95, "postgres_connections"),
        ):
            with self.subTest(metric=path[1]):
                snapshot = copy.deepcopy(self.snapshot)
                snapshot[path[0]][path[1]] = value
                result = capacity.preflight(snapshot, self.policy, self.now)
                self.assertEqual(result["status"], "BLOCKED")
                self.assertTrue(any(expected in r for r in result["reasons"]), result)

    def test_blocks_swap_pressure_when_the_host_has_swap(self) -> None:
        snapshot = copy.deepcopy(self.snapshot)
        snapshot["host"].update(swap_total_mb=2048, swap_used_mb=1536, swap_used_percent=75.0)
        result = capacity.preflight(snapshot, self.policy, self.now)
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any("swap_used_percent" in r for r in result["reasons"]))

    def test_blocks_old_snapshot_or_bad_provenance(self) -> None:
        late = self.now + dt.timedelta(minutes=25)
        result = capacity.preflight(self.snapshot, self.policy, late)
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any("snapshot com" in r for r in result["reasons"]))
        snapshot = copy.deepcopy(self.snapshot)
        snapshot["provenance"]["ssh_target"] = "root@127.0.0.1"
        result = capacity.preflight(snapshot, self.policy, self.now)
        self.assertEqual(result["status"], "BLOCKED")

    def test_cli_exit_codes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "snapshot.json"
            path.write_text(json.dumps(self.snapshot), encoding="utf-8")
            ok = subprocess.run(
                [sys.executable, str(MODULE_PATH), "preflight", "--snapshot", str(path),
                 "--now", "2026-09-24T12:10:00Z"],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
            blocked = subprocess.run(
                [sys.executable, str(MODULE_PATH), "preflight", "--snapshot", str(path),
                 "--now", "2026-09-25T12:10:00Z"],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(blocked.returncode, 3, blocked.stdout)
            self.assertEqual(json.loads(blocked.stdout)["status"], "BLOCKED")
            valid = subprocess.run(
                [sys.executable, str(MODULE_PATH), "validate-policy"],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(valid.returncode, 0, valid.stdout + valid.stderr)


class SnapshotToolTest(unittest.TestCase):
    ALLOWED = (
        r"echo '### [a-z_]+'",
        r"date -u \+%Y-%m-%dT%H:%M:%SZ",
        r"nproc",
        r"cat /proc/(meminfo|loadavg|uptime)",
        r"uname -r",
        r"df -P -B1 /",
        r"docker stats --no-stream --format '\{\{json \.\}\}'",
        r"docker service ls --format '\{\{json \.\}\}'",
        r"docker service inspect --format '\{\{\.Spec\.Name\}\}\{\{\"\\t\"\}\}"
        r"\{\{json \.Spec\.TaskTemplate\.Resources\}\}' \$\(docker service ls -q\)",
    )
    FORBIDDEN = re.compile(
        r"[;&|>]|\b(rm|scale|update|create|kill|stop|start|restart|exec|run|pull|push"
        r"|prune|sudo|apt|apt-get|systemctl|reboot|tee|mv|cp|chmod|curl|wget)\b"
    )

    def test_remote_commands_are_read_only(self) -> None:
        remote = _remote_script()
        lines = remote.splitlines()
        self.assertGreater(len(lines), 10)
        for line in lines:
            with self.subTest(line=line):
                self.assertTrue(
                    any(re.fullmatch(pattern, line) for pattern in self.ALLOWED), line
                )
                self.assertIsNone(self.FORBIDDEN.search(line.replace("{{\"\\t\"}}", "")))

    def _fake_repo(self, tmp: Path) -> tuple[Path, dict[str, str], Path]:
        repo = tmp / "repo"
        for relative in (
            "scripts/manaloom_capacity_snapshot.sh",
            "scripts/manaloom_capacity_policy.py",
            "scripts/lib/manaloom_release_runtime_contract.sh",
            "server/sql/readonly/capacity_postgres.sql",
            "server/config/capacity_policy.json",
            "docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md",
        ):
            target = repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        log = tmp / "calls.jsonl"
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        (tmp / "host.txt").write_text(HOST_RAW, encoding="utf-8")
        (tmp / "postgres.tsv").write_text(POSTGRES_RAW + "\n", encoding="utf-8")

        def shim(path: Path, body: str) -> None:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
            path.chmod(0o755)

        record = (
            f'"{sys.executable}" -c \'import json,sys; '
            f'open(sys.argv[1],"a").write(json.dumps(sys.argv[2:])+"\\n")\' '
            f'"{log}" "$(basename "$0")" "$@"\n'
        )
        shim(bin_dir / "ssh", record + f'cat "{tmp}/host.txt"\n')
        shim(bin_dir / "ssh-keyscan", record +
             'echo "evolution-cartinhas.2ta7qx.easypanel.host ssh-ed25519 AAAAC3Nza"\n')
        shim(bin_dir / "ssh-keygen", record + "cat >/dev/null\n"
             f'echo "256 {FAKE_HOST_KEY} host (ED25519)"\n')
        shim(bin_dir / "git", record +
             'if [[ "$3" == "rev-parse" ]]; then echo ' + FAKE_GIT_SHA + "; fi\n")
        shim(repo / "server/bin/with_new_server_pg.sh", record + f'cat "{tmp}/postgres.tsv"\n')
        (bin_dir / "python3").symlink_to(sys.executable)
        key = tmp / "deploy_key"
        key.write_text("chave de teste\n", encoding="utf-8")
        env = {
            "PATH": f"{bin_dir}:/usr/bin:/bin",
            "HOME": str(tmp),
            "TMPDIR": str(tmp),
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256": FAKE_HOST_KEY,
            "MANALOOM_EASYPANEL_SSH_KEY": str(key),
        }
        return repo, env, log

    def _calls(self, log: Path) -> list[list[str]]:
        if not log.exists():
            return []
        return [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]

    def test_without_execute_it_only_describes_the_reading(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_text:
            repo, env, log = self._fake_repo(Path(tmp_text))
            result = subprocess.run(
                ["/bin/bash", str(repo / "scripts/manaloom_capacity_snapshot.sh")],
                capture_output=True, text=True, env=env, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            described = json.loads(result.stdout)
            self.assertEqual(described["status"], "dry_run")
            self.assertEqual(described["remote_read_only"], _remote_script().splitlines())
            self.assertEqual(self._calls(log), [])

    def test_execute_reads_only_and_writes_a_valid_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_text:
            tmp = Path(tmp_text)
            repo, env, log = self._fake_repo(tmp)
            out = tmp / "snapshot.json"
            result = subprocess.run(
                ["/bin/bash", str(repo / "scripts/manaloom_capacity_snapshot.sh"),
                 "--execute", "--out", str(out)],
                capture_output=True, text=True, env=env, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            snapshot = json.loads(out.read_text(encoding="utf-8"))
            self.assertEqual(snapshot["provenance"]["host_key_sha256"], FAKE_HOST_KEY)
            self.assertEqual(snapshot["provenance"]["tool_git_sha"], FAKE_GIT_SHA)
            self.assertEqual(snapshot["host"]["memory_available_mb"], 6484)
            self.assertEqual(snapshot["postgres"]["transaction_read_only"], "on")

            calls = self._calls(log)
            programs = [call[0] for call in calls]
            self.assertEqual(programs.count("ssh"), 1, calls)
            self.assertEqual(programs.count("with_new_server_pg.sh"), 1, calls)
            self.assertEqual(set(programs) - {"ssh", "ssh-keyscan", "ssh-keygen", "git",
                                              "with_new_server_pg.sh"}, set())
            ssh_call = calls[programs.index("ssh")]
            self.assertIn("StrictHostKeyChecking=yes", ssh_call)
            self.assertEqual(ssh_call[-2], "root@evolution-cartinhas.2ta7qx.easypanel.host")
            self.assertEqual(ssh_call[-1], _remote_script())
            pg_call = calls[programs.index("with_new_server_pg.sh")]
            self.assertEqual(pg_call[1:3], ["--read-only", "psql"])
            self.assertTrue(pg_call[-1].endswith("server/sql/readonly/capacity_postgres.sql"))
            git_calls = [call for call in calls if call[0] == "git"]
            for call in git_calls:
                self.assertIn(call[3], {"status", "rev-parse"}, call)

    def test_execute_requires_out_and_the_host_anchor(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_text:
            tmp = Path(tmp_text)
            repo, env, log = self._fake_repo(tmp)
            script = str(repo / "scripts/manaloom_capacity_snapshot.sh")
            without_out = subprocess.run(
                ["/bin/bash", script, "--execute"],
                capture_output=True, text=True, env=env, check=False,
            )
            self.assertEqual(without_out.returncode, 2)
            env_without_anchor = dict(env)
            del env_without_anchor["MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256"]
            without_anchor = subprocess.run(
                ["/bin/bash", script, "--execute", "--out", str(tmp / "s.json")],
                capture_output=True, text=True, env=env_without_anchor, check=False,
            )
            self.assertNotEqual(without_anchor.returncode, 0)
            self.assertNotIn("ssh", [call[0] for call in self._calls(log)])

    def test_postgres_query_is_read_only(self) -> None:
        sql = (REPO_ROOT / "server/sql/readonly/capacity_postgres.sql").read_text(
            encoding="utf-8"
        )
        statements = [
            "\n".join(line for line in part.splitlines() if not line.startswith("--")).strip()
            for part in sql.split(";")
        ]
        statements = [statement for statement in statements if statement]
        self.assertEqual(statements[0], "BEGIN TRANSACTION READ ONLY")
        self.assertEqual(statements[-1], "ROLLBACK")
        for statement in statements[1:-1]:
            self.assertTrue(statement.startswith("SELECT "), statement)
            self.assertIsNone(
                re.search(r"\b(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|GRANT|COPY"
                          r"|SET|query|usename|client_addr)\b", statement),
                statement,
            )


if __name__ == "__main__":
    unittest.main()
