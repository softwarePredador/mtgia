#!/usr/bin/env python3
"""Tests for Hermes lab cron bootstrap reconciliation."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP = REPO_ROOT / "bin" / "hermes_lab_cron_bootstrap.py"


def _load_module():
    spec = importlib.util.spec_from_file_location("hermes_lab_cron_bootstrap", BOOTSTRAP)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _write_fake_hermes(path: Path, log_path: Path) -> None:
    path.write_text(
        """#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

log = Path(os.environ["FAKE_HERMES_LOG"])
payload = {"argv": sys.argv[1:]}
with log.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(payload) + "\\n")
"""
    )
    path.chmod(0o755)


def _make_repo(root: Path) -> Path:
    repo = root / "repo"
    docs_sync = repo / "server" / "bin" / "hermes_docs_branch_sync.sh"
    docs_sync.parent.mkdir(parents=True, exist_ok=True)
    docs_sync.write_text("#!/usr/bin/env bash\nexit 0\n")
    docs_sync.chmod(0o755)
    return repo


def _run_bootstrap(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(BOOTSTRAP)],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


class HermesLabCronBootstrapTest(unittest.TestCase):
    def test_bootstrap_installs_scripts_and_reconciles_jobs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = _make_repo(root)
            home = root / "home"
            jobs_json = home / ".hermes" / "cron" / "jobs.json"
            jobs_json.parent.mkdir(parents=True, exist_ok=True)
            jobs_json.write_text(
                json.dumps(
                    [
                        {
                            "id": "legacy-1",
                            "name": "lorehold-deck-validator",
                            "enabled": True,
                            "state": "active",
                        },
                        {
                            "id": "pause-1",
                            "name": "manaloom-logic-coherence-auditor",
                            "enabled": True,
                            "state": "active",
                        },
                        {
                            "id": "rules-old",
                            "name": "mtg-rules-auditor",
                            "enabled": True,
                            "state": "active",
                            "deliver": "local",
                            "workdir": str(repo),
                            "script": "mtg-rules-auditor-gate.py",
                            "prompt": "old prompt",
                            "schedule": {"expr": "0 */6 * * *", "display": "0 */6 * * *"},
                        },
                    ],
                    indent=2,
                )
            )

            fake_log = root / "fake-hermes.log"
            fake_hermes = root / "fake-hermes.py"
            _write_fake_hermes(fake_hermes, fake_log)

            env = {
                **os.environ,
                "MANALOOM_REPO": str(repo),
                "MANALOOM_WORKSPACE": str(repo),
                "HERMES_HOME": str(home),
                "HERMES_STATE_ROOT": str(home / ".hermes"),
                "HERMES_CLI": str(fake_hermes),
                "HERMES_CRON_JOBS_JSON": str(jobs_json),
                "HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR": str(root / "artifacts"),
                "FAKE_HERMES_LOG": str(fake_log),
            }

            result = _run_bootstrap(env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)

            scripts_dir = home / ".hermes" / "scripts"
            self.assertTrue((scripts_dir / "manaloom-docs-branch-sync.sh").exists())
            self.assertTrue((scripts_dir / "manaloom-commander-knowledge-deep-gate.py").exists())
            self.assertTrue((scripts_dir / "mtg-rules-auditor-gate.py").exists())

            commands = [json.loads(line)["argv"] for line in fake_log.read_text().splitlines()]
            self.assertIn(["cron", "remove", "legacy-1"], commands)
            self.assertIn(["cron", "pause", "pause-1"], commands)
            self.assertIn(["cron", "remove", "rules-old"], commands)
            create_names = []
            for argv in commands:
                if argv[:2] == ["cron", "create"]:
                    name_index = argv.index("--name")
                    create_names.append(argv[name_index + 1])
            self.assertEqual(
                sorted(create_names),
                sorted(
                    [
                        "manaloom-docs-branch-sync",
                        "manaloom-commander-knowledge-deep",
                        "manaloom-gamechanger-research",
                        "manaloom-knowledge-synthesis",
                        "mtg-rules-auditor",
                    ]
                ),
            )

            report = root / "artifacts" / "latest_bootstrap_report.json"
            self.assertTrue(report.exists())

    def test_bootstrap_is_idempotent_for_matching_jobs(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = _make_repo(root)
            home = root / "home"
            jobs_json = home / ".hermes" / "cron" / "jobs.json"
            jobs_json.parent.mkdir(parents=True, exist_ok=True)

            jobs = []
            for index, spec in enumerate(module.DESIRED_JOBS, start=1):
                jobs.append(
                    {
                        "id": f"job-{index}",
                        "name": spec.name,
                        "enabled": True,
                        "state": "active",
                        "deliver": spec.deliver,
                        "workdir": None if spec.workdir is None else str(repo),
                        "script": spec.script,
                        "prompt": spec.prompt,
                        "no_agent": spec.no_agent,
                        "schedule": {"expr": spec.schedule, "display": spec.schedule},
                    }
                )
            jobs_json.write_text(json.dumps(jobs, indent=2))

            fake_log = root / "fake-hermes.log"
            fake_hermes = root / "fake-hermes.py"
            _write_fake_hermes(fake_hermes, fake_log)

            env = {
                **os.environ,
                "MANALOOM_REPO": str(repo),
                "MANALOOM_WORKSPACE": str(repo),
                "HERMES_HOME": str(home),
                "HERMES_STATE_ROOT": str(home / ".hermes"),
                "HERMES_CLI": str(fake_hermes),
                "HERMES_CRON_JOBS_JSON": str(jobs_json),
                "HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR": str(root / "artifacts"),
                "FAKE_HERMES_LOG": str(fake_log),
            }

            result = _run_bootstrap(env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            logged = fake_log.read_text().strip() if fake_log.exists() else ""
            self.assertEqual(logged, "")


if __name__ == "__main__":
    unittest.main()
