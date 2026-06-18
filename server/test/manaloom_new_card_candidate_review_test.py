#!/usr/bin/env python3
"""Unit tests for the deterministic new-card candidate review cron."""

from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "manaloom_new_card_candidate_review.py"
    spec = importlib.util.spec_from_file_location("manaloom_new_card_candidate_review", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _write_fixture(tmp: Path) -> Path:
    fixture = {
        "commanders": [
            {
                "name": "Lorehold, the Historian",
                "source": "fixture_control",
                "color_identity": ["R", "W"],
                "existing_cards": [
                    {
                        "name": "Sol Ring",
                        "oracle_id": "oracle-sol-ring",
                    }
                ],
                "role_counts": {
                    "ramp": 7,
                    "draw": 4,
                    "removal": 4,
                    "protection": 2,
                    "board_wipe": 1,
                },
            },
            {
                "name": "Atraxa, Praetors' Voice",
                "source": "fixture_profile",
                "color_identity": ["W", "U", "B", "G"],
                "existing_cards": [],
                "role_counts": {
                    "ramp": 5,
                    "draw": 6,
                    "removal": 5,
                },
            },
        ],
        "cards": [
            {
                "card_id": "card-green-ramp",
                "oracle_id": "oracle-green-ramp",
                "name": "Marvel Green Ramp",
                "mana_cost": "{1}{G}",
                "type_line": "Sorcery",
                "oracle_text": "Search your library for a land card, put it onto the battlefield tapped, then shuffle.",
                "color_identity": ["G"],
                "cmc": 2,
                "set_code": "msh",
                "legalities": {"commander": "legal"},
                "function_tags": ["ramp"],
                "battle_rule_count": 1,
                "verified_battle_rule_count": 1,
            },
            {
                "card_id": "card-sol-ring",
                "oracle_id": "oracle-sol-ring",
                "name": "Sol Ring",
                "mana_cost": "{1}",
                "type_line": "Artifact",
                "oracle_text": "{T}: Add {C}{C}.",
                "color_identity": [],
                "cmc": 1,
                "set_code": "msh",
                "legalities": {"commander": "legal"},
                "function_tags": ["ramp"],
                "battle_rule_count": 1,
                "verified_battle_rule_count": 1,
            },
            {
                "card_id": "card-missing-data",
                "name": "Marvel Unknown Preview",
                "mana_cost": "{1}{W}",
                "type_line": "Creature",
                "oracle_text": "",
                "color_identity": ["W"],
                "cmc": 2,
                "set_code": "msh",
                "function_tags": ["protection"],
            },
            {
                "card_id": "card-rule-review",
                "oracle_id": "oracle-rule-review",
                "name": "Marvel Tactical Reset",
                "mana_cost": "{2}{R}{W}",
                "type_line": "Sorcery",
                "oracle_text": "Destroy all creatures. Draw a card for each creature destroyed this way.",
                "color_identity": ["R", "W"],
                "cmc": 4,
                "set_code": "msh",
                "legalities": {"commander": "legal"},
                "function_tags": ["board_wipe", "removal", "draw"],
                "semantic_tags_v2": [
                    {
                        "engine": True,
                        "tags": ["payoff"],
                    }
                ],
                "battle_rule_count": 0,
                "verified_battle_rule_count": 0,
            },
        ],
    }
    path = tmp / "fixture.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")
    return path


class ManaloomNewCardCandidateReviewTest(unittest.TestCase):
    def test_fixture_run_classifies_candidates_and_persists_operational_cache(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            fixture_path = _write_fixture(tmp)
            output_dir = tmp / "artifacts"
            knowledge_db = tmp / "knowledge.db"

            summary = module.run(
                module.parse_args(
                    [
                        "--fixture",
                        str(fixture_path),
                        "--output-dir",
                        str(output_dir),
                        "--knowledge-db",
                        str(knowledge_db),
                        "--no-lorehold-control",
                    ]
                )
            )

            self.assertEqual(summary["cards_scanned"], 4)
            self.assertEqual(summary["commanders_scanned"], 2)
            self.assertGreaterEqual(summary["decisions"].get("ignore", 0), 1)
            self.assertGreaterEqual(summary["decisions"].get("already_present", 0), 1)
            self.assertGreaterEqual(summary["decisions"].get("needs_data", 0), 1)
            self.assertGreaterEqual(summary["decisions"].get("needs_rule_review", 0), 1)

            lorehold = summary["by_commander"]["Lorehold, the Historian"]
            self.assertEqual(lorehold["color_identity"], ["R", "W"])
            green = [
                row
                for row in lorehold["top_candidates"]
                if row["card_name"] == "Marvel Green Ramp"
            ]
            self.assertEqual(green, [])

            atraxa = summary["by_commander"]["Atraxa, Praetors' Voice"]
            self.assertTrue(
                any(row["card_name"] == "Marvel Green Ramp" for row in atraxa["top_candidates"]),
                "green ramp should be considered for a commander whose identity allows it",
            )

            latest_reviews = json.loads(
                (output_dir / "new_card_candidate_review/latest_reviews.json").read_text(
                    encoding="utf-8"
                )
            )
            reset_rows = [
                row
                for row in latest_reviews
                if row["card_name"] == "Marvel Tactical Reset"
                and row["commander_name"] == "Lorehold, the Historian"
            ]
            self.assertEqual(len(reset_rows), 1)
            self.assertEqual(reset_rows[0]["decision"], "needs_rule_review")
            self.assertIn("draw", reset_rows[0]["roles"])
            self.assertIn("removal", reset_rows[0]["roles"])
            self.assertIn("board_wipe", reset_rows[0]["roles"])
            self.assertIn("engine", reset_rows[0]["roles"])
            self.assertIn("payoff", reset_rows[0]["roles"])

            conn = sqlite3.connect(knowledge_db)
            try:
                persisted = conn.execute(
                    """
                    SELECT decision, COUNT(*)
                    FROM new_card_candidate_reviews
                    GROUP BY decision
                    """
                ).fetchall()
                persisted_counts = {row[0]: row[1] for row in persisted}
                self.assertGreaterEqual(persisted_counts.get("needs_rule_review", 0), 1)
                queued = conn.execute(
                    "SELECT COUNT(*) FROM new_card_battle_rule_review_queue"
                ).fetchone()[0]
                self.assertGreaterEqual(queued, 1)
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
