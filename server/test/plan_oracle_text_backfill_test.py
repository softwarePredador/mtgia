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
        self.assertFalse(candidate["card_faces_present"])

    def test_scryfall_candidate_reports_faces_for_identity_backfill(self) -> None:
        candidate = planner.scryfall_candidate(
            {
                "id": "print-id",
                "oracle_id": "oracle-id",
                "name": "Emeria's Call // Emeria, Shattered Skyclave",
                "type_line": "Sorcery // Land",
                "layout": "modal_dfc",
                "card_faces": [
                    {"name": "Emeria's Call", "oracle_text": "Create tokens."},
                    {"name": "Emeria, Shattered Skyclave", "oracle_text": "{T}: Add {W}."},
                ],
                "color_identity": ["W"],
            }
        )

        self.assertTrue(candidate["oracle_text_present"])
        self.assertTrue(candidate["card_faces_present"])
        self.assertEqual(candidate["card_face_count"], 2)

    def test_scryfall_lookup_attempts_try_safe_multiface_names_before_fuzzy(self) -> None:
        attempts = planner.scryfall_lookup_attempts(
            "1 Emeria's Call // Emeria, Shattered Skyclave (ZNR)"
        )

        strategies = [attempt["strategy"] for attempt in attempts]
        self.assertEqual(strategies[0], "exact_original")
        self.assertIn("exact_without_quantity", strategies)
        self.assertIn("exact_without_set_suffix", strategies)
        self.assertIn("exact_front_face", strategies)
        self.assertEqual(strategies[-1], "fuzzy_original")

        front_face = next(
            attempt for attempt in attempts if attempt["strategy"] == "exact_front_face"
        )
        self.assertEqual(front_face["mode"], "exact")
        self.assertEqual(front_face["query"], "Emeria's Call")


if __name__ == "__main__":
    unittest.main()
