#!/usr/bin/env python3
"""Tests for Hermes lab runtime probe behavior."""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PROBE = REPO_ROOT / "bin" / "hermes_lab_runtime_probe.py"


class HermesLabRuntimeProbeTest(unittest.TestCase):
    def test_runtime_probe_writes_expected_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            repo = root / "workspace" / "mtgia"
            repo.mkdir(parents=True, exist_ok=True)
            subprocess.run(["git", "init"], cwd=repo, check=True, capture_output=True)
            subprocess.run(
                ["git", "config", "user.email", "probe@example.invalid"],
                cwd=repo,
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["git", "config", "user.name", "Probe"],
                cwd=repo,
                check=True,
                capture_output=True,
            )
            (repo / "README.md").write_text("probe\n", encoding="utf-8")
            subprocess.run(["git", "add", "README.md"], cwd=repo, check=True, capture_output=True)
            subprocess.run(
                ["git", "commit", "-m", "init"],
                cwd=repo,
                check=True,
                capture_output=True,
            )

            jobs_json = home / "cron" / "jobs.json"
            jobs_json.parent.mkdir(parents=True, exist_ok=True)
            jobs_json.write_text(
                json.dumps(
                    {
                        "jobs": [
                            {"name": "manaloom-docs-branch-sync", "enabled": True},
                            {"name": "manaloom-commander-knowledge-deep", "enabled": True},
                            {"name": "manaloom-gamechanger-research", "enabled": True},
                            {"name": "manaloom-knowledge-synthesis", "enabled": True},
                            {"name": "mtg-rules-auditor", "enabled": True},
                        ]
                    }
                ),
                encoding="utf-8",
            )

            fake_hermes = root / "fake-hermes.sh"
            fake_hermes.write_text(
                "#!/usr/bin/env bash\n"
                "if [[ \"$1 $2 $3\" == \"config get model.provider\" ]]; then echo openai-api; exit 0; fi\n"
                "if [[ \"$1 $2 $3\" == \"config get model.default\" ]]; then echo gpt-4o-mini; exit 0; fi\n"
                "exit 1\n",
                encoding="utf-8",
            )
            fake_hermes.chmod(0o755)

            env = {
                **os.environ,
                "HERMES_HOME": str(home),
                "MANALOOM_WORKSPACE": str(repo),
                "HERMES_CRON_JOBS_JSON": str(jobs_json),
                "HERMES_PROVIDER": "openai-api",
                "HERMES_MODEL": "gpt-4o-mini",
                "HERMES_CLI": str(fake_hermes),
                "OPENAI_API_KEY": "sk-proj-test",
                "API_SERVER_KEY": "probe-key",
            }
            result = subprocess.run(
                ["python3", str(PROBE)],
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr)

            payload = json.loads(
                (home / "artifacts" / "hermes_lab_runtime" / "runtime_probe.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(payload["jobs_count"], 5)
            self.assertTrue(payload["expected_jobs_present"])
            self.assertEqual(payload["resolved_provider"], "openai-api")
            self.assertEqual(payload["resolved_model"], "gpt-4o-mini")
            self.assertTrue(payload["provider_matches_expected"])
            self.assertTrue(payload["model_matches_expected"])


if __name__ == "__main__":
    unittest.main()
