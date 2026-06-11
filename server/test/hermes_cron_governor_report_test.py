#!/usr/bin/env python3
"""Tests for deterministic Hermes cron governor report."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "hermes_cron_governor_report.py"
    spec = importlib.util.spec_from_file_location("hermes_cron_governor_report", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class HermesCronGovernorReportTest(unittest.TestCase):
    def test_report_flags_enabled_provider_and_429_outputs(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scripts = root / "scripts"
            outputs = root / "output"
            scripts.mkdir()
            outputs.mkdir()
            script = scripts / "ok.sh"
            script.write_text("#!/usr/bin/env bash\nexit 0\n")
            script.chmod(0o755)

            failed_dir = outputs / "agent-job"
            failed_dir.mkdir()
            (failed_dir / "latest.md").write_text(
                "# Cron Job: agent job (FAILED)\n\n## Error\nRuntimeError: HTTP 429: limit\n"
            )

            jobs = [
                {
                    "id": "script-job",
                    "name": "script job",
                    "enabled": True,
                    "script": "ok.sh",
                    "schedule_display": "every 30m",
                    "last_status": "ok",
                },
                {
                    "id": "agent-job",
                    "name": "agent job",
                    "enabled": True,
                    "provider": "opencode-go",
                    "model": "deepseek-v4-flash",
                    "schedule_display": "every 720m",
                    "last_status": "error",
                },
            ]

            report = module.build_report(jobs, outputs, scripts)

            self.assertIn("jobs_total: 2", report)
            self.assertIn("enabled_provider_dependent: 1", report)
            self.assertIn("P1 `agent job`", report)
            self.assertIn("HTTP 429", report)

    def test_python_scripts_are_valid_script_targets(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scripts = root / "scripts"
            scripts.mkdir()
            script = scripts / "job.py"
            script.write_text("#!/usr/bin/env python3\nprint('ok')\n")

            self.assertEqual(module._script_state(scripts, "job.py"), "ok")

    def test_load_jobs_accepts_object_or_list_shape(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            object_file = root / "object.json"
            list_file = root / "list.json"
            object_file.write_text(json.dumps({"jobs": [{"name": "a"}]}))
            list_file.write_text(json.dumps([{"name": "b"}]))

            self.assertEqual(module._load_jobs(object_file)[0]["name"], "a")
            self.assertEqual(module._load_jobs(list_file)[0]["name"], "b")


if __name__ == "__main__":
    unittest.main()
