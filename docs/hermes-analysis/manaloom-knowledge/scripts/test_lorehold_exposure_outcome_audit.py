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
    added_accessed: dict | None = None,
    added_near_access: dict | None = None,
    low_candidate_use: bool = False,
    forced_access_mode: str = "none",
    exposure_status: str | None = None,
    added_status: str | None = None,
    added_status_counts: dict | None = None,
) -> dict:
    added_used = added_used if added_used is not None else used_record(2, 1, 1)
    cut_used = cut_used if cut_used is not None else used_record(2, 2, 0)
    added_accessed = added_accessed if added_accessed is not None else added_used
    added_near_access = added_near_access if added_near_access is not None else added_accessed
    exposure_status = exposure_status or (
        "candidate_added_cards_used"
        if not low_candidate_use
        else "candidate_added_card_low_access"
    )
    added_status = added_status or ("used" if not low_candidate_use else "library_only_not_used")
    added_status_counts = added_status_counts or {
        "used": added_used["games"],
    }
    return {
        "generated_at": "2026-06-28T00:00:00Z",
        "packages": [
            {
                "package_key": package_key,
                "family": "fast_mana",
                "adds": [add],
                "cuts": [cut],
                "forced_access_mode": forced_access_mode,
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
                    "status": exposure_status,
                    "low_candidate_added_card_use": low_candidate_use,
                    "candidate_added_cards": {
                        "all_cards_used": not low_candidate_use,
                        "cards": [
                            {
                                "card_name": add,
                                "status": added_status,
                                "recorded_use_count": 2 if not low_candidate_use else 0,
                                "outcome_summary": {
                                    "used_games": added_used,
                                    "accessed_or_used_games": added_accessed,
                                    "near_access_or_better_games": added_near_access,
                                    "sample_quality": "card_used_sample"
                                    if added_used["games"]
                                    else "card_accessed_not_used_sample"
                                    if added_accessed["games"]
                                    else "card_near_access_only_sample"
                                    if added_near_access["games"]
                                    else "no_card_exposure_sample",
                                    "status_counts": added_status_counts,
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
                                    "accessed_or_used_games": cut_used,
                                    "near_access_or_better_games": cut_used,
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


def variant_gate_report_for_mana_vault() -> dict:
    return {
        "generated_at": "2026-06-28T00:00:00Z",
        "forced_access_mode": "none",
        "results": [
            {
                "deck_key": "deck_607",
                "status": "pass",
                "wins": 1,
                "losses": 1,
                "stalls": 0,
                "win_rate": 50.0,
                "game_results": [
                    {"game_id": "base-1", "result": "win", "turns": 5},
                    {"game_id": "base-2", "result": "loss", "turns": 6},
                ],
                "telemetry": {
                    "card_event_counts": {"cost_paid:Arcane Signet": 2},
                    "card_event_counts_by_game": {
                        "base-1": {"cost_paid:Arcane Signet": 1},
                        "base-2": {"cost_paid:Arcane Signet": 1},
                    }
                },
            },
            {
                "deck_key": "synergy_mana_vault_fast_mana_cut_arcane_signet",
                "status": "pass",
                "forced_access_mode": "none",
                "wins": 2,
                "losses": 0,
                "stalls": 0,
                "win_rate": 100.0,
                "game_results": [
                    {"game_id": "cand-1", "result": "win", "turns": 4},
                    {"game_id": "cand-2", "result": "win", "turns": 5},
                ],
                "telemetry": {
                    "card_event_counts": {"cost_paid:Mana Vault": 2},
                    "card_event_counts_by_game": {
                        "cand-1": {"cost_paid:Mana Vault": 1},
                        "cand-2": {"cost_paid:Mana Vault": 1},
                    }
                },
            },
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

    def test_positive_aggregate_accessed_without_use_routes_to_conversion_review(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(
                path,
                package_report(
                    package_key="silence_cut_avatar_wrath",
                    add="Silence",
                    cut="Avatar's Wrath",
                    baseline_wins=0,
                    baseline_losses=3,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=100.0,
                    added_used=used_record(0, 0, 0),
                    added_accessed=used_record(2, 2, 0),
                    added_near_access=used_record(2, 2, 0),
                    low_candidate_use=True,
                    exposure_status="candidate_added_cards_accessed_not_used",
                    added_status="accessed_not_used",
                    added_status_counts={"accessed_not_used": 2},
                ),
            )

            payload = audit.build_report([path])

            row = payload["packages"][0]
            decision = row["outcome_decision"]
            self.assertEqual(
                decision["decision"],
                "candidate_accessed_without_used_sample",
            )
            self.assertFalse(decision["promotion_allowed"])
            self.assertEqual(decision["candidate_accessed_games"], 2)
            self.assertEqual(
                decision["next_action"],
                "inspect_play_heuristic_or_runtime_for_accessed_card",
            )
            self.assertEqual(payload["summary"]["accessed_without_used_sample_count"], 1)
            self.assertEqual(
                payload["package_rollups"][0]["status"],
                "accessed_without_use_conversion_review",
            )

    def test_positive_aggregate_near_access_without_use_routes_to_access_window(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(
                path,
                package_report(
                    package_key="wheel_hand_filter_cut_big_score",
                    add="Wheel of Fortune",
                    cut="Big Score",
                    baseline_wins=0,
                    baseline_losses=3,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=100.0,
                    added_used=used_record(0, 0, 0),
                    added_accessed=used_record(0, 0, 0),
                    added_near_access=used_record(2, 1, 1),
                    low_candidate_use=True,
                    exposure_status="candidate_added_cards_near_access_low_use",
                    added_status="near_access_not_used",
                    added_status_counts={"near_access_not_used": 2},
                ),
            )

            payload = audit.build_report([path])

            decision = payload["packages"][0]["outcome_decision"]
            self.assertEqual(
                decision["decision"],
                "candidate_near_access_without_used_sample",
            )
            self.assertFalse(decision["promotion_allowed"])
            self.assertEqual(decision["candidate_near_access_games"], 2)
            self.assertEqual(
                payload["package_rollups"][0]["status"],
                "near_access_without_use_access_window_review",
            )

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

    def test_single_used_game_sample_is_not_card_outcome_decision(self):
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
                    added_used=used_record(1, 1, 0),
                    cut_used=used_record(1, 0, 1),
                ),
            )

            payload = audit.build_report([path])

            decision = payload["packages"][0]["outcome_decision"]
            self.assertEqual(
                decision["decision"],
                "insufficient_card_outcome_used_sample",
            )
            self.assertFalse(decision["promotion_allowed"])
            self.assertEqual(decision["minimum_used_games"], 2)
            self.assertEqual(payload["summary"]["deeper_gate_candidate_count"], 0)
            self.assertEqual(payload["summary"]["insufficient_card_outcome_sample_count"], 1)

    def test_forced_access_positive_sample_requires_natural_confirmation(self):
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
                    forced_access_mode="opening_hand",
                ),
            )

            payload = audit.build_report([path])

            decision = payload["packages"][0]["outcome_decision"]
            self.assertEqual(
                decision["decision"],
                "forced_access_card_outcome_signal_requires_natural_confirmation",
            )
            self.assertFalse(decision["promotion_allowed"])
            self.assertEqual(payload["summary"]["deeper_gate_candidate_count"], 0)
            self.assertEqual(payload["summary"]["forced_access_signal_count"], 1)
            self.assertEqual(
                payload["summary"]["recommended_next_action"],
                "run_natural_confirmation_for_forced_access_signal",
            )

    def test_forced_access_negative_sample_is_no_lift_reject_or_rework(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "gate.json"
            write_json(
                path,
                package_report(
                    baseline_wins=1,
                    baseline_losses=2,
                    candidate_wins=0,
                    candidate_losses=3,
                    delta_pp=-33.33,
                    added_used=used_record(2, 0, 2),
                    cut_used=used_record(2, 1, 1),
                    forced_access_mode="opening_hand",
                ),
            )

            payload = audit.build_report([path])

            decision = payload["packages"][0]["outcome_decision"]
            self.assertEqual(
                decision["decision"],
                "forced_access_card_outcome_no_lift_reject_or_rework",
            )
            rollup = payload["package_rollups"][0]
            self.assertEqual(rollup["status"], "forced_access_no_lift_reject_or_rework")
            self.assertEqual(rollup["next_action"], "do_not_promote_from_forced_access_probe")

    def test_rollup_prefers_natural_reject_over_forced_access_signal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            natural = Path(tmpdir) / "natural.json"
            forced = Path(tmpdir) / "forced.json"
            write_json(natural, package_report())
            write_json(
                forced,
                package_report(
                    baseline_wins=1,
                    baseline_losses=2,
                    candidate_wins=3,
                    candidate_losses=0,
                    delta_pp=66.67,
                    added_used=used_record(2, 2, 0),
                    cut_used=used_record(2, 1, 1),
                    forced_access_mode="opening_hand",
                ),
            )

            payload = audit.build_report([natural, forced])

            rollup = payload["package_rollups"][0]
            self.assertEqual(rollup["package_key"], "mana_vault_fast_mana_cut_arcane_signet")
            self.assertEqual(rollup["status"], "natural_reject_current_pair")
            self.assertEqual(rollup["observation_count"], 2)
            self.assertEqual(rollup["natural_observation_count"], 1)
            self.assertEqual(rollup["forced_access_observation_count"], 1)
            self.assertEqual(
                payload["summary"]["rollup_status_counts"],
                {"natural_reject_current_pair": 1},
            )

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

    def test_variant_gate_results_are_synthesized_as_package_observations(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "variant_gate.json"
            write_json(path, variant_gate_report_for_mana_vault())

            report = audit.build_report([path])

            self.assertEqual(report["summary"]["loaded_package_observation_count"], 1)
            row = report["packages"][0]
            self.assertEqual(row["package_key"], "mana_vault_fast_mana_cut_arcane_signet")
            self.assertEqual(row["adds"], ["Mana Vault"])
            self.assertEqual(row["cuts"], ["Arcane Signet"])
            self.assertEqual(
                row["outcome_decision"]["decision"],
                "card_outcome_supports_deeper_gate",
            )
            self.assertEqual(row["outcome_decision"]["used_delta_pp"], 50.0)

    def test_markdown_reports_used_delta(self):
        payload = audit.build_report([])
        markdown = audit.render_markdown(payload)

        self.assertIn("Lorehold Exposure Outcome Audit", markdown)
        self.assertIn("Decision Rules", markdown)


if __name__ == "__main__":
    unittest.main()
