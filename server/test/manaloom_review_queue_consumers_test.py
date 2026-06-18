#!/usr/bin/env python3
"""Unit tests for report-only consumers of new-card review queues."""

from __future__ import annotations

import importlib.util
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module(name: str, relative_path: str):
    root = Path(__file__).resolve().parents[1]
    path = root / relative_path
    spec = importlib.util.spec_from_file_location(name, path)
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
                "existing_cards": [],
                "role_counts": {
                    "ramp": 5,
                    "draw": 4,
                    "removal": 4,
                    "protection": 1,
                    "board_wipe": 0,
                },
            }
        ],
        "cards": [
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
                "battle_rule_count": 0,
                "verified_battle_rule_count": 0,
            },
        ],
    }
    path = tmp / "fixture.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")
    return path


class ManaloomReviewQueueConsumersTest(unittest.TestCase):
    def test_consumers_do_not_fail_before_candidate_review_runs(self) -> None:
        data_gap = _load_module(
            "manaloom_card_data_gap_review_empty",
            "bin/manaloom_card_data_gap_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue_empty",
            "bin/manaloom_battle_rule_review_queue.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            knowledge_db = tmp / "empty_knowledge.db"
            data_summary = data_gap.run(
                data_gap.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "data_gap"),
                    ]
                )
            )
            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "battle"),
                    ]
                )
            )
            self.assertEqual(data_summary["unique_cards"], 0)
            self.assertEqual(battle_summary["draft_count"], 0)
            self.assertEqual(data_summary.get("blocked_reason"), "knowledge_db_missing")
            self.assertEqual(battle_summary.get("blocked_reason"), "knowledge_db_missing")

    def test_consumers_classify_data_gaps_and_generate_rule_drafts(self) -> None:
        candidate = _load_module(
            "manaloom_new_card_candidate_review_for_consumers",
            "bin/manaloom_new_card_candidate_review.py",
        )
        data_gap = _load_module(
            "manaloom_card_data_gap_review",
            "bin/manaloom_card_data_gap_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue",
            "bin/manaloom_battle_rule_review_queue.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            fixture = _write_fixture(tmp)
            knowledge_db = tmp / "knowledge.db"
            candidate_dir = tmp / "candidate"
            data_gap_dir = tmp / "data_gap"
            battle_dir = tmp / "battle"

            candidate_summary = candidate.run(
                candidate.parse_args(
                    [
                        "--fixture",
                        str(fixture),
                        "--output-dir",
                        str(candidate_dir),
                        "--knowledge-db",
                        str(knowledge_db),
                        "--no-lorehold-control",
                    ]
                )
            )
            self.assertGreaterEqual(candidate_summary["decisions"].get("needs_data", 0), 1)
            self.assertGreaterEqual(candidate_summary["decisions"].get("needs_rule_review", 0), 1)

            data_summary = data_gap.run(
                data_gap.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(data_gap_dir),
                    ]
                )
            )
            self.assertEqual(data_summary["gap_rows"], 1)
            self.assertEqual(data_summary["unique_cards"], 1)
            self.assertIn("needs_oracle_sync", data_summary["decisions"])
            data_items = json.loads(
                (data_gap_dir / "card_data_gap_review/latest_items.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertIn("refresh_oracle_text", data_items[0]["actions"])
            self.assertIn("refresh_commander_legality", data_items[0]["actions"])

            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(battle_dir),
                    ]
                )
            )
            self.assertEqual(battle_summary["queue_rows"], 1)
            self.assertEqual(battle_summary["draft_count"], 1)
            drafts = json.loads(
                (battle_dir / "battle_rule_review_queue/latest_drafts.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(drafts[0]["proposed_status"], "needs_review")
            self.assertIn("no_verified_promotion", drafts[0]["safety"])
            self.assertIn("mass_removal_or_modal_wipe", drafts[0]["effect_families"])
            self.assertIn("targeted_interaction", drafts[0]["effect_families"])

            conn = sqlite3.connect(knowledge_db)
            try:
                data_runs = conn.execute(
                    "SELECT COUNT(*) FROM new_card_data_gap_review_runs"
                ).fetchone()[0]
                battle_runs = conn.execute(
                    "SELECT COUNT(*) FROM new_card_battle_rule_review_runs"
                ).fetchone()[0]
                self.assertEqual(data_runs, 1)
                self.assertEqual(battle_runs, 1)
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
