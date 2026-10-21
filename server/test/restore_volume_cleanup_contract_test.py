#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CID = "a" * 64
TARGETS = ("validate", "full", "remote_template")

# Every Docker call is intercepted. The remote heredoc is tested directly,
# never by running its SSH/cron installer.
TOOL_STUB = r'''
import json
import os
import signal
import sys
from pathlib import Path

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
scenario = os.environ["RESTORE_TEST_SCENARIO"]
cid = "a" * 64
state = Path(os.environ["RESTORE_TEST_STATE"])
if tool == "docker":
    with open(os.environ["RESTORE_TEST_LOG"], "a") as stream:
        stream.write(json.dumps(args) + "\n")
    if args == ["info"]:
        sys.exit(0)
    if args[0] == "run":
        if "-d" not in args:
            sys.exit(0)
        if scenario == "name_collision":
            sys.exit(125)
        if "--cidfile" not in args:
            sys.exit("missing private cidfile")
        cidfile = Path(args[args.index("--cidfile") + 1])
        cidfile.write_text("halder" if scenario == "invalid_id" else cid)
        state.write_text(cid)
        if scenario == "start_failure":
            sys.exit(125)
        print(cid)
        sys.exit(0)
    if args[0] == "exec":
        if "pg_restore" in args:
            if scenario in ("restore_failure", "restore_and_cleanup_failure"):
                sys.exit(37)
            if scenario in ("interrupt", "terminate"):
                sig = signal.SIGINT if scenario == "interrupt" else signal.SIGTERM
                os.kill(os.getppid(), sig)
            sys.exit(0)
        if "psql" in args:
            query = args[args.index("-c") + 1]
            if "information_schema.tables" in query:
                print("80")
            elif "pg_database_size" in query:
                print("4096")
            elif "to_regclass" in query:
                print("t")
            else:
                print("1")
        sys.exit(0)
    if args[0] == "cp":
        sys.exit(0)
    if args[0] == "rm":
        if args != ["rm", "-f", "-v", cid]:
            sys.exit("unsafe removal target or missing volume cleanup")
        if scenario in ("cleanup_failure", "restore_and_cleanup_failure", "daemon_unavailable"):
            sys.exit(9)
        state.unlink(missing_ok=True)
        sys.exit(1 if scenario == "already_removed" else 0)
    if args[0] == "ps":
        if args != ["ps", "-aq", "--no-trunc", "--filter", "id=" + cid]:
            sys.exit("unscoped container lookup")
        if scenario == "daemon_unavailable":
            sys.exit(9)
        if state.exists():
            print(cid)
        sys.exit(0)
    sys.exit("unexpected Docker operation: " + repr(args))
if tool in ("pg_restore", "flock", "sleep", "sha256sum"):
    sys.exit(0)
if tool == "readlink" and args[0] == "-f":
    print(Path(args[1]).resolve())
    sys.exit(0)
sys.exit("unexpected tool: " + tool)
'''


class RestoreVolumeCleanupTest(unittest.TestCase):
    def run_case(self, target: str, scenario: str) -> tuple[subprocess.CompletedProcess, list[list[str]]]:
        with tempfile.TemporaryDirectory(prefix="manaloom-restore-contract-") as tmp:
            root = Path(tmp)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            scratch = root / "temporary directories"
            scratch.mkdir()
            log = root / "docker.jsonl"
            state = root / "mock-container"
            payload = b"test fixture; not a PostgreSQL backup\n"
            backup = root / "backup fixture.dump"
            backup.write_bytes(payload)
            evidence = root / "evidence"
            for tool in ("docker", "pg_restore", "flock", "sleep", "sha256sum", "readlink"):
                stub = bin_dir / tool
                stub.write_text(f"#!{sys.executable}\n" + textwrap.dedent(TOOL_STUB))
                stub.chmod(0o700)
            env = {
                k: v for k, v in os.environ.items()
                if not k.startswith("MANALOOM_") and k not in ("BASH_ENV", "ENV", "EVIDENCE_DIR")
            }
            env.update(
                PATH=str(bin_dir) + os.pathsep + os.environ["PATH"],
                TMPDIR=str(scratch),
                RESTORE_TEST_SCENARIO=scenario,
                RESTORE_TEST_LOG=str(log),
                RESTORE_TEST_STATE=str(state),
            )
            if target == "validate":
                args = [str(ROOT / "scripts/manaloom_validate_restore.sh"), str(backup)]
            elif target == "full":
                env["MANALOOM_RESTORE_DRILL_EXECUTE"] = "1"
                args = [str(ROOT / "scripts/manaloom_full_restore_drill.sh"),
                        "--backup", str(backup), "--evidence-dir", str(evidence), "--execute"]
                if scenario == "dry_run":
                    args.remove("--execute")
            else:
                source = (ROOT / "scripts/manaloom_install_remote_backup_cron.sh").read_text()
                source = source.split("<<'REMOTE_RESTORE_SCRIPT'\n", 1)[1]
                source = source.split("\nREMOTE_RESTORE_SCRIPT\n", 1)[0]
                script = root / "remote-restore.sh"
                script.write_text(source)
                backups = root / "backups"
                backups.mkdir()
                latest = backups / "latest.dump"
                latest.write_bytes(payload)
                latest.with_suffix(".dump.sha256").write_text(
                    hashlib.sha256(payload).hexdigest() + "  latest.dump\n"
                )
                env["MANALOOM_BACKUP_DIR"] = str(backups)
                env["MANALOOM_RESTORE_LOCK_FILE"] = str(root / "restore.lock")
                args = [str(script)]

            result = subprocess.run(
                ["/bin/bash", *args], env=env, cwd=root, text=True,
                capture_output=True, timeout=25,
            )
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            self.assertEqual(backup.read_bytes(), payload, result.stderr)
            self.assertEqual(list(scratch.iterdir()), [], result.stderr)
            removals = [call for call in calls if call[0] == "rm"]
            self.assertTrue(all(call == ["rm", "-f", "-v", CID] for call in removals), calls)
            self.assertFalse(any("prune" in call or call[0] == "volume" for call in calls), calls)
            if scenario not in ("dry_run", "name_collision", "invalid_id"):
                self.assertEqual(removals, [["rm", "-f", "-v", CID]], calls)
            else:
                self.assertEqual(removals, [], calls)
            if scenario in ("success", "restore_failure", "start_failure", "interrupt", "terminate", "already_removed"):
                self.assertFalse(state.exists(), result.stderr)
            if target == "full" and scenario == "success":
                self.assertEqual((evidence / "container-id.txt").read_text().strip(), CID)
                self.assertEqual(json.loads((evidence / "restore-result.json").read_text())["status"], "passed")
            for call in calls:
                if call[0] == "run" and "-d" in call:
                    self.assertIn("--rm", call)
                    self.assertIn("--cidfile", call)
                    self.assertEqual(call[call.index("--network") + 1], "none")
                    self.assertNotIn("--volumes-from", call)
                    self.assertTrue(call[call.index("--name") + 1].rsplit("-", 1)[-1].isdigit())
                    for index, arg in enumerate(call):
                        if arg in ("-v", "--volume"):
                            self.assertTrue(call[index + 1].endswith(":ro"), call)
            return result, calls

    def test_success_removes_only_owned_container_and_anonymous_volumes(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "success")
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_restore_failure_keeps_exit_status_and_cleans_volumes(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "restore_failure")
                self.assertEqual(result.returncode, 37, result.stderr)

    def test_creation_failure_never_removes_an_existing_name(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "name_collision")
                self.assertEqual(result.returncode, 125, result.stderr)

    def test_failure_after_creation_uses_cidfile_for_cleanup(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "start_failure")
                self.assertEqual(result.returncode, 125, result.stderr)

    def test_interruptions_clean_up_and_preserve_signal_exit_status(self):
        for target in TARGETS:
            for scenario, code in (("interrupt", 130), ("terminate", 143)):
                with self.subTest(target=target, scenario=scenario):
                    result, _ = self.run_case(target, scenario)
                    self.assertEqual(result.returncode, code, result.stderr)

    def test_cleanup_failure_is_reported_without_masking_restore_failure(self):
        for target in TARGETS:
            for scenario, code in (("cleanup_failure", 1), ("daemon_unavailable", 1),
                                   ("restore_and_cleanup_failure", 37)):
                with self.subTest(target=target, scenario=scenario):
                    result, _ = self.run_case(target, scenario)
                    self.assertEqual(result.returncode, code, result.stderr)
                    self.assertIn("falha ao limpar container temporario e volumes", result.stderr)

    def test_automatic_removal_is_not_reported_as_a_failure(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "already_removed")
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_invalid_id_never_falls_back_to_container_name(self):
        for target in TARGETS:
            with self.subTest(target=target):
                result, _ = self.run_case(target, "invalid_id")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("ID temporario invalido", result.stderr)

    def test_full_restore_dry_run_does_not_call_docker(self):
        result, calls = self.run_case("full", "dry_run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])
        self.assertFalse(json.loads(result.stdout)["writes_performed"])


if __name__ == "__main__":
    if shutil.which("jq") is None:
        raise SystemExit("jq is required for the full-restore contract tests")
    unittest.main()
