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

    def test_target_player_name_is_commander_specific(self) -> None:
        completed = subprocess.run(
            [
                sys.executable,
                "-c",
                (
                    "import sys; "
                    f"sys.path.insert(0, {str(SCRIPT_DIR)!r}); "
                    "import battle_analyst_v9 as b; "
                    "print(b.target_player_name_for_commander({'name':'Kaalia of the Vast'})); "
                    "print(b.target_player_name_for_commander({'name':'Lorehold, the Historian'})); "
                    "print(b.commander_log_slug({'name':'Kaalia of the Vast'})); "
                    "print(b.commander_log_slug({'name':'Lorehold, the Historian'})); "
                    "path=b.battle_log_path_for_commander({'name':'Kaalia of the Vast'}); "
                    "print(path.endswith('/decks/kaalia-of-the-vast/BATTLE_LOG.md')); "
                    "import tempfile; "
                    "print(path.startswith(tempfile.gettempdir()))"
                ),
            ],
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, msg=completed.stderr)
        self.assertEqual(
            completed.stdout.splitlines(),
            [
                "Kaalia of the Vast",
                "Lorehold",
                "kaalia-of-the-vast",
                "lorehold-the-historian",
                "True",
                "True",
            ],
        )


if __name__ == "__main__":
    unittest.main()
