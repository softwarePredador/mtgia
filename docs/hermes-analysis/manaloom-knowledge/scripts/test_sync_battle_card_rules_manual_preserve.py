#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sync_battle_card_rules_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_rules = load_module()


class SyncBattleCardRulesManualPreserveTests(unittest.TestCase):
    def test_manual_rows_are_empty_after_canonicalization(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
        )
        self.assertEqual(rows, [])


if __name__ == "__main__":
    unittest.main()
