#!/usr/bin/env python3
"""Tests for Hermes lab healthcheck behavior."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
HEALTHCHECK = REPO_ROOT / "bin" / "hermes_lab_healthcheck.sh"


def _run_healthcheck(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(HEALTHCHECK)],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


class HermesLabHealthcheckTest(unittest.TestCase):
    def test_passes_when_startup_succeeded_and_report_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "bootstrap",
                        "status": "succeeded",
                        "message": "ok",
                    }
                )
            )
            report_path = home / "artifacts" / "hermes_cron_bootstrap" / "latest_bootstrap_report.json"
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text("{}")
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
            }
            result = _run_healthcheck(env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertIn('"status": "succeeded"', result.stdout)

    def test_fails_when_startup_status_is_failed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "bootstrap",
                        "status": "failed",
                        "message": "boom",
                    }
                )
            )
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
            }
            result = _run_healthcheck(env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("startup failed", result.stderr)

    def test_fails_when_bootstrap_report_is_missing_but_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "gateway",
                        "status": "starting",
                        "message": "gateway up",
                    }
                )
            )
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
                "HERMES_CRON_BOOTSTRAP": "1",
                "HERMES_CRON_BOOTSTRAP_REQUIRED": "1",
            }
            result = _run_healthcheck(env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("bootstrap report missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
