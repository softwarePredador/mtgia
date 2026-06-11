#!/usr/bin/env python3
"""Regression tests for operational EngineMetrics wiring.

These tests intentionally avoid running the long optimizer cycle. They guard the
cron/preflight contract that makes battle-engine telemetry visible outside the
unit test suite.
"""

from __future__ import annotations

import ast
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent


class EngineMetricsOperationalWiringTests(unittest.TestCase):
    def test_auto_cycle_exports_metrics_dir_and_writes_aggregate_report(self) -> None:
        script = (SCRIPT_DIR / "master_optimizer_auto_cycle_cron.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn("ENGINE_METRICS_DIR=", script)
        self.assertIn("export MANALOOM_ENGINE_METRICS_DIR", script)
        self.assertIn("engine_metrics_report.py", script)
        self.assertIn("--input-dir \"$MANALOOM_ENGINE_METRICS_DIR\"", script)
        self.assertIn("latest_engine_metrics_report.json", script)

    def test_preflight_requires_engine_metrics_report_script(self) -> None:
        source_path = SCRIPT_DIR / "master_optimizer_loop.py"
        tree = ast.parse(source_path.read_text(encoding="utf-8"))
        source = source_path.read_text(encoding="utf-8")

        self.assertIn("DEFAULT_ENGINE_METRICS_REPORT", source)
        self.assertIn("engine_metrics_report", source)
        self.assertIn("--engine-metrics-report", source)

        constants = {
            node.value
            for node in ast.walk(tree)
            if isinstance(node, ast.Constant) and isinstance(node.value, str)
        }
        self.assertIn("engine_metrics_report", constants)


if __name__ == "__main__":
    unittest.main()
