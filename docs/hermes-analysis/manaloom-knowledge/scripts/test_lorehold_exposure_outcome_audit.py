import json
import tempfile
import unittest
from pathlib import Path

import lorehold_exposure_outcome_audit as audit


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def used_record(games: int, wins: int, losses: int) -> dict:
    return {
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": 0,
        "win_rate": round(wins / max(1, games) * 100, 2) if games else 0.0,
    }


def package_report(
    *,
    package_key: str = "mana_vault_fast_mana_cut_arcane_signet",
    add: str = "Mana Vault",
    cut: str = "Arcane Signet",
    baseline_wins: int = 3,
    baseline_losses: int = 0,
    candidate_wins: int = 1,
    candidate_losses: int = 2,
    delta_pp: float = -66.67,
    added_used: dict | None = None,
    cut_used: dict | None = None,
    low_candidate_use: bool = False,
) -> dict:
    added_used = added_used if added_used is not None else used_record(2, 1, 1)
    cut_used = cut_used if cut_used is not None else used_record(2, 2, 0)
    return {
        "generated_at": "2026-06-28T00:00:00Z",
        "packages": [
            {
                "package_key": package_key,
                "family": "fast_mana",
                "adds": [add],
                "cuts": [cut],
                "decision": "reject_or_rework",
                "gate_summary": {
                    "baseline": {
                        "wins": baseline_wins,
                        "losses": baseline_losses,
                        "stalls": 0,
                        "win_rate": round(100 * baseline_wins / max(1, baseline_wins + baseline_losses), 2),
                    },
                    "candidate": {
                        "wins": candidate_wins,
                        "losses": candidate_losses,
                        "stalls": 0,
                        "win_rate": round(100 * candidate_wins / max(1, candidate_wins + candidate_losses), 2),
                    },
                    "delta_pp": delta_pp,
                },
                "exposure_summary": {
                    "status": "candidate_added_cards_used"
                    if not low_candidate_use
                    else "candidate_added_card_low_access",
                    "low_candidate_added_card_use": low_candidate_use,
                    "candidate_added_cards": {
                        "all_cards_used": not low_candidate_use,
                        "cards": [
                            {
                                "card_name": add,
                                "status": "used" if not low_candidate_use else "library_only_not_used",
                                "recorded_use_count": 2 if not low_candidate_use else 0,
                                "outcome_summary": {
                                    "used_games": added_used,
                                    "sample_quality": "card_used_sample"
                                    if added_used["games"]
                                    else "no_card_exposure_sample",
                                    "status_counts": {"used": added_used["games"]},
                                },
                            }
                        ],
                    },
                    "baseline_cut_cards": {
                        "all_cards_used": True,
                        "cards": [
                            {
                                "card_name": cut,
                                "status": "used",
                                "recorded_use_count": 2,
                                "outcome_summary": {
                                    "used_games": cut_used,
                                    "sample_quality": "card_used_sample",
                                    "status_counts": {"used": cut_used["games"]},
                                },
                            }
                        ],
                    },
                },
            }
        ],
    }


class LoreholdExposureOutcomeAuditTest(unittest.TestCase):
    def test_negative_used_record_rejects_current_pair(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(path, package_report())

            payload = audit.build_report([path])

            row = payload["packages"][0]
            self.assertEqual(
                row["outcome_decision"]["decision"],
                "card_outcome_rejects_current_pair",
            )
            self.assertEqual(row["outcome_decision"]["used_delta_pp"], -50.0)
            self.assertFalse(row["outcome_decision"]["promotion_allowed"])
            self.assertEqual(payload["summary"]["rejected_current_pair_count"], 1)

    def test_positive_aggregate_without_used_sample_is_inconclusive(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(
                path,
                package_report(
                    baseline_wins=0,
                    baseline_losses=3,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=100.0,
                    added_used=used_record(0, 0, 0),
                    low_candidate_use=True,
                ),
            )

            payload = audit.build_report([path])

            row = payload["packages"][0]
            self.assertEqual(
                row["outcome_decision"]["decision"],
                "inconclusive_no_candidate_used_sample",
            )
            self.assertFalse(row["outcome_decision"]["promotion_allowed"])
            self.assertEqual(payload["summary"]["inconclusive_no_used_sample_count"], 1)

    def test_positive_aggregate_and_used_record_supports_deeper_gate(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(
                path,
                package_report(
                    baseline_wins=1,
                    baseline_losses=2,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=66.67,
                    added_used=used_record(2, 2, 0),
                    cut_used=used_record(2, 1, 1),
                ),
            )

            payload = audit.build_report([path])

            row = payload["packages"][0]
            self.assertEqual(
                row["outcome_decision"]["decision"],
                "card_outcome_supports_deeper_gate",
            )
            self.assertTrue(row["outcome_decision"]["promotion_allowed"])
            self.assertEqual(payload["summary"]["deeper_gate_candidate_count"], 1)

    def test_missing_card_rows_are_not_labeled_multi_card_review(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            payload = package_report()
            payload["packages"][0]["exposure_summary"] = {}
            payload["packages"][0]["gate_summary"] = {
                "baseline": {"wins": 1, "losses": 0, "stalls": 0, "win_rate": 100.0},
                "candidate": {"wins": 0, "losses": 1, "stalls": 0, "win_rate": 0.0},
                "delta_pp": -100.0,
            }
            write_json(path, payload)

            report = audit.build_report([path])

            self.assertEqual(
                report["packages"][0]["outcome_decision"]["decision"],
                "missing_per_card_outcome_data",
            )

    def test_markdown_reports_used_delta(self):
        payload = audit.build_report([])
        markdown = audit.render_markdown(payload)

        self.assertIn("Lorehold Exposure Outcome Audit", markdown)
        self.assertIn("Decision Rules", markdown)


if __name__ == "__main__":
    unittest.main()
