#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules_pg.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sync_battle_card_rules_pg_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_pg = load_module()


class SyncBattleCardRulesPgSelectionTests(unittest.TestCase):
    def test_resolve_selected_card_names_from_summary_filters_hotfixes(self) -> None:
        payload = {
            "entries": [
                {
                    "card_name": "Lightning Greaves",
                    "classification": "temporary_hotfix",
                    "recommended_action": "reconcile_pg_rule",
                },
                {
                    "card_name": "Arcane Signet",
                    "classification": "card_rule_promotable",
                    "recommended_action": "already_canonicalized",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            summary_path = Path(tmpdir) / "summary.json"
            summary_path.write_text(json.dumps(payload), encoding="utf-8")
            args = argparse.Namespace(
                only_card=[],
                only_summary_json=str(summary_path),
                only_classification=["temporary_hotfix"],
                only_recommended_action=["reconcile_pg_rule"],
            )
            selected = sync_pg.resolve_selected_card_names(args)
        self.assertEqual(selected, ["Lightning Greaves"])

    def test_filter_rows_by_card_names_uses_normalized_names(self) -> None:
        rows = [
            {"card_name": "Lightning Greaves"},
            {"card_name": "Arcane Signet"},
        ]
        filtered = sync_pg.filter_rows_by_card_names(rows, ["lightning greaves"])
        self.assertEqual(filtered, [{"card_name": "Lightning Greaves"}])


if __name__ == "__main__":
    unittest.main()
