#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lorehold_paired_battle_statistical_gate as gate


class HistoricalPairedBattleGateRejectionTest(unittest.TestCase):
    def test_retired_design_can_never_promote_or_mutate(self):
        report = gate.build_rejection(generated_at="2026-07-22T00:00:00Z")

        self.assertEqual(report["status"], "blocked")
        self.assertFalse(report["seed_pairing_claim"])
        self.assertFalse(report["superiority_proven"])
        self.assertFalse(report["promotion_allowed"])
        self.assertFalse(report["automatic_mutation_performed"])
        self.assertTrue(report["baseline_protected"])
        self.assertIn("paired_seed_design_invalid", report["historical_blockers"])

    def test_legacy_cli_exits_blocked_and_points_to_independent_replacement(self):
        with tempfile.TemporaryDirectory() as temporary:
            prefix = Path(temporary) / "historical"
            result = subprocess.run(
                [
                    sys.executable,
                    str(Path(gate.__file__)),
                    "--gate",
                    "old-batch.json",
                    "--candidate-key",
                    "old-candidate",
                    "--out-prefix",
                    str(prefix),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 1)
            self.assertTrue(prefix.with_suffix(".json").is_file())
            self.assertIn(gate.REPLACEMENT, result.stdout)


if __name__ == "__main__":
    unittest.main()
