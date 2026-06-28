from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import manaloom_log_learning_audit as audit


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


class ManaLoomLogLearningScoreabilityTest(unittest.TestCase):
    def test_runtime_waiver_source_parser_reads_set_literal(self) -> None:
        cards = audit.runtime_waiver_cards_from_source_text(
            """
MANUAL_RULE_RUNTIME_WAIVERS = {
    "Wand of Vertebrae",
    'Vedalken Orrery',
}
""",
            source="unit",
        )

        self.assertEqual(cards["wand of vertebrae"]["card"], "Wand of Vertebrae")
        self.assertEqual(cards["vedalken orrery"]["source"], "unit")

    def test_runtime_waiver_drift_names_find_committed_not_worktree(self) -> None:
        worktree = {
            "vedalken orrery": {"card": "Vedalken Orrery"},
        }
        committed = {
            "vedalken orrery": {"card": "Vedalken Orrery"},
            "wand of vertebrae": {"card": "Wand of Vertebrae"},
        }

        self.assertEqual(
            audit.runtime_waiver_drift_names(worktree, committed),
            ["Wand of Vertebrae"],
        )

    def test_build_audit_finds_accessed_but_unused_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            write_json(
                tmp / "prior_compare_accessed_not_used.json",
                {
                    "candidate_scoreability": {
                        "candidate_accessed_not_used_cards": [
                            "Birgi, God of Storytelling"
                        ],
                        "candidate_near_access_only_cards": [],
                        "cards": {
                            "Birgi, God of Storytelling": {
                                "accessed_games": 1,
                                "direct_card_events": 0,
                                "evidence_status": "accessed_not_used",
                                "near_access_games": 0,
                            }
                        },
                        "scoring_allowed": False,
                        "status": "candidate_not_used",
                    },
                    "comparison": {"flags": []},
                    "observed_summary": {
                        "candidate_observations": {
                            "Birgi, God of Storytelling": {
                                "accessed_games": 1,
                                "direct_card_events": 0,
                                "observed": True,
                            }
                        }
                    },
                    "status": "inconclusive_candidate_not_used",
                },
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            issues = report["action_queue"]
            issue_types = {row["issue_type"] for row in issues}
            self.assertIn("candidate_not_used", issue_types)
            self.assertIn("top_level_status", issue_types)
            not_used = next(
                row for row in issues if row["issue_type"] == "candidate_not_used"
            )
            self.assertEqual(not_used["severity"], "high")
            self.assertEqual(
                not_used["examples"][0]["evidence"]["direct_card_events"],
                0,
            )
            self.assertFalse(report["postgres_writes"])


if __name__ == "__main__":
    unittest.main()
