#!/usr/bin/env python3
"""Unit coverage for the read-only oracle text backfill planner helpers."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "server/bin/plan_oracle_text_backfill.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "plan_oracle_text_backfill",
        SCRIPT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


planner = load_module()


class OracleTextBackfillPlanTest(unittest.TestCase):
    def test_scryfall_oracle_text_prefers_top_level_text(self) -> None:
        self.assertEqual(
            planner.scryfall_oracle_text({"oracle_text": "{T}: Add {C}."}),
            "{T}: Add {C}.",
        )

    def test_scryfall_oracle_text_combines_card_faces(self) -> None:
        text = planner.scryfall_oracle_text(
            {
                "card_faces": [
                    {"name": "Front", "oracle_text": "Draw a card."},
                    {"name": "Back", "oracle_text": "Create a token."},
                ]
            }
        )

        self.assertEqual(text, "Front: Draw a card.\n//\nBack: Create a token.")

    def test_scryfall_candidate_reports_backfill_fields(self) -> None:
        candidate = planner.scryfall_candidate(
            {
                "id": "print-id",
                "oracle_id": "oracle-id",
                "name": "Memnite",
                "type_line": "Artifact Creature - Construct",
                "layout": "normal",
                "oracle_text": "This card has no rules text.",
                "color_identity": [],
            }
        )

        self.assertTrue(candidate["found"])
        self.assertTrue(candidate["oracle_text_present"])
        self.assertEqual(candidate["oracle_text_length"], 28)
        self.assertEqual(candidate["oracle_id"], "oracle-id")


if __name__ == "__main__":
    unittest.main()
