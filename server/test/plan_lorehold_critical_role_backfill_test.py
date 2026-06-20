#!/usr/bin/env python3
"""Tests for the focused Lorehold critical role backfill planner."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "server/bin/plan_lorehold_critical_role_backfill.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "plan_lorehold_critical_role_backfill",
        SCRIPT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


planner = load_module()


class LoreholdCriticalRoleBackfillPlannerTest(unittest.TestCase):
    def test_build_plan_uses_expected_source_and_row_counts(self) -> None:
        resolved = [
            {
                "input_name": card.name,
                "card_id": f"00000000-0000-0000-0000-{index:012d}",
                "canonical_name": card.name,
                "oracle_id": f"oracle-{index}",
                "type_line": "Artifact",
                "oracle_text_present": True,
            }
            for index, card in enumerate(planner.CRITICAL_CARDS, start=1)
        ]

        plan = planner.build_plan(resolved)

        self.assertEqual(len(plan["function_tag_rows"]), 11)
        self.assertEqual(len(plan["semantic_v2_rows"]), 4)
        self.assertEqual(len(plan["commander_synergy_rows"]), 5)
        self.assertEqual(
            {row["source"] for rows in plan.values() for row in rows},
            {planner.SOURCE},
        )
        self.assertEqual(
            {
                row["card_name"]
                for row in plan["commander_synergy_rows"]
            },
            {card.name for card in planner.CRITICAL_CARDS},
        )

    def test_rollback_sql_is_scoped_to_source_commander_and_card_ids(self) -> None:
        sql = planner.rollback_sql(
            [
                "00000000-0000-0000-0000-000000000001",
                "00000000-0000-0000-0000-000000000002",
            ]
        )

        self.assertIn("BEGIN;", sql)
        self.assertIn("COMMIT;", sql)
        self.assertIn(f"source = '{planner.SOURCE}'", sql)
        self.assertIn(
            f"commander_name_normalized = '{planner.COMMANDER_NORMALIZED}'",
            sql,
        )
        self.assertIn("card_function_tags", sql)
        self.assertIn("card_semantic_tags_v2", sql)
        self.assertIn("commander_card_synergy", sql)


if __name__ == "__main__":
    unittest.main()
