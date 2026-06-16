#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from unittest import mock
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

    def test_runtime_waiver_is_promoted_into_manual_rows_when_injected(self) -> None:
        injected_rule = {
            "effect": "ramp_permanent",
            "mana_produced": 1,
            "produces": "WUBRGC",
            "requires_legendary_creature_or_planeswalker_for_mana": True,
        }
        with mock.patch.object(sync_rules.battle, "MANUAL_RULE_RUNTIME_WAIVERS", {"Mox Amber"}):
            with mock.patch.object(
                sync_rules.battle,
                "HANDCRAFTED_KNOWN_CARD_RULES",
                {"Mox Amber": injected_rule},
            ):
                rows = sync_rules.build_rows(
                    include_generated=False,
                    sqlite_db=str(sync_rules.DEFAULT_DB),
                )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["card_name"], "Mox Amber")
        self.assertEqual(rows[0]["source"], "manual")
        self.assertEqual(rows[0]["review_status"], "verified")
        self.assertEqual(rows[0]["effect_json"], injected_rule)


if __name__ == "__main__":
    unittest.main()
