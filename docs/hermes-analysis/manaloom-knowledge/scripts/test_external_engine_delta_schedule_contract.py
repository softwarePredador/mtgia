#!/usr/bin/env python3
import json
import os
import plistlib
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[4]
RUNNER = REPO_ROOT / "scripts/manaloom_external_engine_delta_weekly.sh"
INSTALLER = (
    REPO_ROOT / "scripts/manaloom_install_external_engine_delta_schedule.sh"
)


class ExternalEngineDeltaScheduleContractTests(unittest.TestCase):
    def test_clean_checkout_runs_local_audit_and_retains_only_owned_reports(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            checkout = root / "checkout"
            report_dir = root / "reports" / "external-engine-delta"
            self._write_minimal_pin_contract(checkout)
            self._commit_all(checkout)

            report_dir.mkdir(parents=True)
            expired = report_dir / "external-engine-delta-20200101T000000Z-9.json"
            expired.write_text("{}\n", encoding="utf-8")
            unrelated = report_dir / "keep.json"
            unrelated.write_text("{}\n", encoding="utf-8")
            old = time.time() - 9 * 86400
            os.utime(expired, (old, old))
            os.utime(unrelated, (old, old))

            result = subprocess.run(
                [
                    str(RUNNER),
                    "--local-only",
                    "--repo-root",
                    str(checkout),
                    "--report-dir",
                    str(report_dir),
                    "--retention-days",
                    "7",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            latest = json.loads(
                (report_dir / "latest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(latest["status"], "pass", latest.get("errors"))
            self.assertEqual(latest["mode"], "local_pin_contract")
            self.assertTrue(latest["safety"]["read_only"])
            self.assertFalse(expired.exists())
            self.assertTrue(unrelated.exists())

    def test_dirty_checkout_is_explicit_skip_without_audit_or_pin_change(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            checkout = root / "checkout"
            report_dir = root / "reports" / "external-engine-delta"
            self._write_minimal_pin_contract(checkout)
            self._commit_all(checkout)
            pin_path = checkout / "services/xmage-sidecar/XMAGE_COMMIT"
            original_pin = pin_path.read_text(encoding="utf-8")
            pin_path.write_text("f" * 40 + "\n", encoding="utf-8")

            result = subprocess.run(
                [
                    str(RUNNER),
                    "--local-only",
                    "--repo-root",
                    str(checkout),
                    "--report-dir",
                    str(report_dir),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            latest = json.loads(
                (report_dir / "latest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(latest["status"], "skipped")
            self.assertEqual(latest["reason"], "dirty_worktree")
            self.assertEqual(pin_path.read_text(encoding="utf-8"), "f" * 40 + "\n")
            self.assertNotEqual(pin_path.read_text(encoding="utf-8"), original_pin)
            self.assertFalse(latest["safety"]["pin_updates_performed"])

    def test_untracked_checkout_is_also_an_explicit_skip(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            checkout = root / "checkout"
            report_dir = root / "reports" / "external-engine-delta"
            self._write_minimal_pin_contract(checkout)
            self._commit_all(checkout)
            untracked = checkout / "intermediate-review.txt"
            untracked.write_text("not committed\n", encoding="utf-8")

            result = subprocess.run(
                [
                    str(RUNNER),
                    "--local-only",
                    "--repo-root",
                    str(checkout),
                    "--report-dir",
                    str(report_dir),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            latest = json.loads(
                (report_dir / "latest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(latest["status"], "skipped")
            self.assertEqual(latest["reason"], "dirty_worktree")
            self.assertEqual(untracked.read_text(encoding="utf-8"), "not committed\n")

    def test_report_symlink_resolving_inside_checkout_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            checkout = root / "checkout"
            self._write_minimal_pin_contract(checkout)
            self._commit_all(checkout)
            internal_report_dir = (
                checkout / "evidence" / "external-engine-delta"
            )
            internal_report_dir.mkdir(parents=True)
            external_parent = root / "reports"
            external_parent.mkdir()
            report_link = external_parent / "external-engine-delta"
            report_link.symlink_to(internal_report_dir, target_is_directory=True)

            result = subprocess.run(
                [
                    str(RUNNER),
                    "--local-only",
                    "--repo-root",
                    str(checkout),
                    "--report-dir",
                    str(report_link),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 2, result.stdout)
            self.assertIn("interno ao checkout", result.stderr)
            self.assertFalse((internal_report_dir / "latest.json").exists())

    def test_installer_lifecycle_uses_weekly_launchagent_and_preserves_reports(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            launch_agents = root / "Library" / "LaunchAgents"
            report_dir = (
                root
                / "Library"
                / "Application Support"
                / "ManaLoom"
                / "external-engine-delta"
            )
            tool_dir = root / "bin"
            tool_dir.mkdir()
            launchctl_log = root / "launchctl.log"
            launchctl = tool_dir / "launchctl"
            launchctl.write_text(
                "#!/usr/bin/env bash\n"
                'printf "%s\\n" "$*" >> "$FAKE_LAUNCHCTL_LOG"\n'
                "exit 0\n",
                encoding="utf-8",
            )
            plutil = tool_dir / "plutil"
            plutil.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            launchctl.chmod(0o755)
            plutil.chmod(0o755)
            env = {
                **os.environ,
                "HOME": str(root),
                "MANALOOM_LAUNCH_AGENTS_DIR": str(launch_agents),
                "MANALOOM_ENGINE_DELTA_REPORT_DIR": str(report_dir),
                "MANALOOM_LAUNCHCTL_BIN": str(launchctl),
                "MANALOOM_PLUTIL_BIN": str(plutil),
                "FAKE_LAUNCHCTL_LOG": str(launchctl_log),
            }

            self._run_installer("--install", env)
            plist_path = (
                launch_agents
                / "com.manaloom.external-engine-delta-weekly.plist"
            )
            with plist_path.open("rb") as handle:
                plist = plistlib.load(handle)
            self.assertEqual(
                plist["StartCalendarInterval"],
                {"Weekday": 0, "Hour": 9, "Minute": 17},
            )
            self.assertEqual(plist["ProgramArguments"][0], "/bin/bash")
            self.assertEqual(
                Path(plist["ProgramArguments"][1]).resolve(), RUNNER.resolve()
            )
            self.assertIn(str(report_dir), plist["ProgramArguments"])
            self.assertNotIn("RunAtLoad", plist)

            (report_dir / "keep.json").write_text("{}\n", encoding="utf-8")
            (report_dir / "latest.json").write_text(
                json.dumps({"status": "pass", "review_required": False}) + "\n",
                encoding="utf-8",
            )
            self._run_installer("--check", env)
            self._run_installer("--run-now", env)
            self._run_installer("--uninstall", env)
            self.assertFalse(plist_path.exists())
            self.assertTrue((report_dir / "keep.json").exists())
            calls = launchctl_log.read_text(encoding="utf-8")
            self.assertIn(
                "enable gui/",
                calls,
                "install must reverse a persisted launchd disabled override",
            )
            self.assertIn("bootstrap", calls)
            self.assertIn("kickstart gui/", calls)
            self.assertIn("bootout", calls)
            self.assertIn("disable", calls)

    def test_installer_rejects_a_tcc_protected_checkout_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            home = root / "home"
            scripts = home / "Documents" / "project" / "scripts"
            scripts.mkdir(parents=True)
            installer = scripts / INSTALLER.name
            runner = scripts / RUNNER.name
            shutil.copy2(INSTALLER, installer)
            runner.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            runner.chmod(0o755)
            tool_dir = root / "bin"
            tool_dir.mkdir()
            launchctl = tool_dir / "launchctl"
            launchctl.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            plutil = tool_dir / "plutil"
            plutil.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            launchctl.chmod(0o755)
            plutil.chmod(0o755)
            env = {
                **os.environ,
                "HOME": str(home),
                "MANALOOM_LAUNCH_AGENTS_DIR": str(root / "LaunchAgents"),
                "MANALOOM_ENGINE_DELTA_REPORT_DIR": str(
                    root / "reports" / "external-engine-delta"
                ),
                "MANALOOM_LAUNCHCTL_BIN": str(launchctl),
                "MANALOOM_PLUTIL_BIN": str(plutil),
            }

            result = subprocess.run(
                [str(installer), "--install"],
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 2, result.stdout)
            self.assertIn("pasta protegida", result.stderr)
            self.assertFalse((root / "LaunchAgents").exists())

    def test_check_status_and_freshness_matrix(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            launch_agents = root / "Library" / "LaunchAgents"
            report_dir = (
                root
                / "Library"
                / "Application Support"
                / "ManaLoom"
                / "external-engine-delta"
            )
            tool_dir = root / "bin"
            tool_dir.mkdir()
            launchctl = tool_dir / "launchctl"
            launchctl.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            plutil = tool_dir / "plutil"
            plutil.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            launchctl.chmod(0o755)
            plutil.chmod(0o755)
            env = {
                **os.environ,
                "HOME": str(root),
                "MANALOOM_LAUNCH_AGENTS_DIR": str(launch_agents),
                "MANALOOM_ENGINE_DELTA_REPORT_DIR": str(report_dir),
                "MANALOOM_LAUNCHCTL_BIN": str(launchctl),
                "MANALOOM_PLUTIL_BIN": str(plutil),
            }
            self._run_installer("--install", env)
            latest = report_dir / "latest.json"

            self.assertNotEqual(self._installer_result("--check", env).returncode, 0)

            latest.write_text(
                json.dumps(
                    {"status": "review_required", "review_required": True}
                )
                + "\n",
                encoding="utf-8",
            )
            self.assertEqual(self._installer_result("--check", env).returncode, 0)

            for unhealthy_status in ("skipped", "fail"):
                latest.write_text(
                    json.dumps({"status": unhealthy_status}) + "\n",
                    encoding="utf-8",
                )
                self.assertNotEqual(
                    self._installer_result("--check", env).returncode,
                    0,
                    unhealthy_status,
                )

            latest.write_text("{not-json\n", encoding="utf-8")
            self.assertNotEqual(self._installer_result("--check", env).returncode, 0)

            latest.write_text(
                json.dumps({"status": "pass", "review_required": False}) + "\n",
                encoding="utf-8",
            )
            stale = time.time() - 9 * 86400
            os.utime(latest, (stale, stale))
            self.assertNotEqual(self._installer_result("--check", env).returncode, 0)

    def _run_installer(self, mode: str, env: dict[str, str]) -> None:
        result = self._installer_result(mode, env)
        self.assertEqual(result.returncode, 0, result.stderr)

    @staticmethod
    def _installer_result(
        mode: str, env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(INSTALLER), mode],
            env=env,
            check=False,
            capture_output=True,
            text=True,
        )

    @staticmethod
    def _commit_all(checkout: Path) -> None:
        subprocess.run(["git", "init", "-q", str(checkout)], check=True)
        subprocess.run(["git", "-C", str(checkout), "add", "."], check=True)
        subprocess.run(
            [
                "git",
                "-C",
                str(checkout),
                "-c",
                "user.name=ManaLoom Test",
                "-c",
                "user.email=test@localhost",
                "commit",
                "-qm",
                "fixture",
            ],
            check=True,
        )

    @staticmethod
    def _write_minimal_pin_contract(repo_root: Path) -> None:
        xmage_pin = "a" * 40
        forge_pin = "b" * 40
        files = {
            "services/xmage-sidecar/XMAGE_COMMIT": xmage_pin + "\n",
            "services/forge-sidecar/FORGE_COMMIT": forge_pin + "\n",
            "services/xmage-sidecar/Dockerfile": (
                f"ARG XMAGE_COMMIT={xmage_pin}\n"
            ),
            "services/forge-sidecar/Dockerfile": (
                f"ARG FORGE_COMMIT={forge_pin}\n"
            ),
            "services/xmage-sidecar/src/main/java/com/manaloom/xmage/SidecarMain.java": (
                f'static final String XMAGE_COMMIT = "{xmage_pin}";\n'
            ),
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py": (
                f'XMAGE_PIN = "{xmage_pin}"\nFORGE_PIN = "{forge_pin}"\n'
            ),
            "server/lib/ai/battle_engine_config.dart": (
                f"const pinnedXmageCommit = '{xmage_pin}';\n"
            ),
            "docs/hermes-analysis/manaloom-knowledge/scripts/external_battle_async_runner.py": (
                'ENGINE_SPECS = {\n'
                '    "xmage": {\n'
                f'        "engine_commit": "{xmage_pin}",\n'
                f'        "sidecar_build_identity": "xmage-sidecar-v2@{xmage_pin}",\n'
                "    },\n"
                "}\n"
            ),
            "docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py": (
                'XMAGE_PIN = canonical_engine_pin("services/xmage-sidecar/XMAGE_COMMIT")\n'
                'FORGE_PIN = canonical_engine_pin("services/forge-sidecar/FORGE_COMMIT")\n'
                "local_root_pin_contract = validate_xmage_local_root_pin(xmage_root)\n"
                'STATE = {"xmage_local_root_pin_contract": local_root_pin_contract}\n'
                'POLICY = {"upstream_head_allowed": False}\n'
            ),
        }
        for relative_path, content in files.items():
            path = repo_root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
