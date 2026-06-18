#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


class BattleAnalystCliHelpTests(unittest.TestCase):
    def test_help_exits_without_running_simulation(self) -> None:
        completed = subprocess.run(
            [sys.executable, str(BATTLE_PATH), "--help"],
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, msg=completed.stderr)
        self.assertIn("usage:", completed.stdout.lower())
        self.assertIn("--games", completed.stdout)
        self.assertIn("--seed", completed.stdout)
        self.assertNotIn("BATTLE ANALYST v8", completed.stdout)
        self.assertNotIn("Using", completed.stdout)


if __name__ == "__main__":
    unittest.main()
