import json
import tempfile
import unittest
from pathlib import Path

import lorehold_learning_evidence_ledger as ledger


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


class LoreholdLearningEvidenceLedgerTest(unittest.TestCase):
    def test_build_ledger_preserves_registry_champion_and_latest_rejection(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            registry = tmp / "registry.json"
            write_json(
                registry,
                {
                    "protected_baseline": "deck_607",
                    "current_leader": "candidate_607_squee_v1",
                    "acceptance_rule": ["candidate must beat current leader"],
                    "untested_queue": [],
                    "tested": [
                        {
                            "key": "candidate_607_squee_v1",
                            "status": "promoted_current_champion",
                            "result": "7W/1L/1S",
                            "learning": "champion",
                        }
                    ],
                    "protected_cards_until_same_function_replacement_wins": ["Storm Herd"],
                },
            )
            write_json(
                tmp / "lorehold_squee_gate_20260627_v1.json",
                {
                    "results": [
                        {"deck_key": "deck_6", "status": "pass", "games": 9, "wins": 5, "losses": 4, "stalls": 0, "win_rate": 55.56},
                        {
                            "deck_key": "candidate_607_squee_hashseed0_isolated_cached_timeout_v3",
                            "archetype": "strategy-first-squee",
                            "status": "pass",
                            "games": 9,
                            "wins": 7,
                            "losses": 1,
                            "stalls": 1,
                            "win_rate": 77.78,
                        },
                    ],
                    "games_per_opponent": 3,
                    "opponents": ["a", "b", "c"],
                    "opponent_seed": 42,
                    "simulation_seed": 42,
                },
            )
            write_json(
                tmp / "lorehold_hidden_retreat_gate_20260628_v1.json",
                {
                    "source_db": "/tmp/squee.db",
                    "games_per_opponent": 1,
                    "opponent_limit": 3,
                    "opponent_seed": 20260626,
                    "simulation_seed": 42,
                    "packages": [
                        {
                            "package_key": "hidden_retreat_stack_damage_topdeck_cut_promise",
                            "family": "topdeck_protection",
                            "adds": ["Hidden Retreat"],
                            "cuts": ["Promise of Loyalty"],
                            "status": "gated",
                            "gate_summary": {
                                "baseline": {"status": "pass", "games": 3, "wins": 3, "losses": 0, "stalls": 0, "win_rate": 100.0},
                                "candidate": {
                                    "status": "pass",
                                    "games": 3,
                                    "wins": 1,
                                    "losses": 2,
                                    "stalls": 0,
                                    "win_rate": 33.33,
                                    "telemetry": {"event_counts": {"damage_prevention_shield_created": 0}},
                                },
                                "delta_pp": -66.67,
                            },
                        }
                    ],
                },
            )

            payload = ledger.build_ledger(tmp, registry)

            self.assertEqual(payload["summary"]["current_leader"], "candidate_607_squee_v1")
            champion = next(row for row in payload["package_groups"] if row["package_key"] == "candidate_607_squee_v1")
            hidden = payload["hidden_retreat"]
            self.assertEqual(champion["classification"], "current_champion")
            self.assertIn("lorehold_squee_gate_20260627_v1.json", champion["sources"])
            self.assertEqual(hidden["classification"], "latest_rejected")
            self.assertEqual(hidden["latest_candidate"]["damage_prevention_shield_created"], 0)

    def test_conflicting_positive_and_negative_requires_confirmation(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            registry = tmp / "registry.json"
            write_json(registry, {"current_leader": "candidate_607_squee_v1"})
            for idx, delta in enumerate((33.33, -22.22), start=1):
                write_json(
                    tmp / f"lorehold_package_gate_20260627_v{idx}.json",
                    {
                        "packages": [
                            {
                                "package_key": "galvanoth_topdeck_freecast_cut_chimes",
                                "family": "topdeck_freecast",
                                "adds": ["Galvanoth"],
                                "cuts": ["Victory Chimes"],
                                "status": "gated",
                                "gate_summary": {
                                    "baseline": {"games": 9, "wins": 3, "losses": 6, "stalls": 0, "win_rate": 33.33},
                                    "candidate": {
                                        "games": 9,
                                        "wins": 6 if delta > 0 else 1,
                                        "losses": 3 if delta > 0 else 8,
                                        "stalls": 0,
                                        "win_rate": 66.66 if delta > 0 else 11.11,
                                    },
                                    "delta_pp": delta,
                                },
                            }
                        ]
                    },
                )

            payload = ledger.build_ledger(tmp, registry)

            group = next(row for row in payload["package_groups"] if row["package_key"] == "galvanoth_topdeck_freecast_cut_chimes")
            self.assertEqual(group["classification"], "latest_rejected")
            self.assertEqual(group["positive_count"], 1)
            self.assertEqual(group["negative_count"], 1)
            markdown = ledger.render_markdown(payload)
            self.assertIn("galvanoth_topdeck_freecast_cut_chimes", markdown)

    def test_latest_cut_safety_block_overrides_older_positive_signal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            registry = tmp / "registry.json"
            write_json(registry, {"current_leader": "candidate_607_squee_v1"})
            write_json(
                tmp / "lorehold_brainstone_gate_old.json",
                {
                    "generated_at": "2026-06-27T00:00:00+00:00",
                    "packages": [
                        {
                            "package_key": "brainstone_topdeck_miracle_cut_squelcher",
                            "family": "topdeck_setup",
                            "adds": ["Brainstone"],
                            "cuts": ["Hexing Squelcher"],
                            "status": "gated",
                            "gate_summary": {
                                "baseline": {"games": 9, "wins": 0, "losses": 9, "stalls": 0, "win_rate": 0.0},
                                "candidate": {"games": 9, "wins": 5, "losses": 4, "stalls": 0, "win_rate": 55.56},
                                "delta_pp": 55.56,
                            },
                        }
                    ],
                },
            )
            write_json(
                tmp / "lorehold_brainstone_preflight_new.json",
                {
                    "generated_at": "2026-06-28T00:00:00+00:00",
                    "packages": [
                        {
                            "package_key": "brainstone_topdeck_miracle_cut_squelcher",
                            "family": "topdeck_setup",
                            "adds": ["Brainstone"],
                            "cuts": ["Hexing Squelcher"],
                            "status": "skipped_cut_safety",
                            "cut_safety": {
                                "status": "blocked_cut_safety",
                                "reason": "proposed cuts already have blocker evidence: Hexing Squelcher",
                            },
                        }
                    ],
                },
            )

            payload = ledger.build_ledger(tmp, registry)

            group = next(row for row in payload["package_groups"] if row["package_key"] == "brainstone_topdeck_miracle_cut_squelcher")
            self.assertEqual(group["classification"], "preflight_blocked_protected_cut")
            self.assertEqual(group["best_delta_pp"], 55.56)
            self.assertIsNone(group["latest_delta_pp"])
            self.assertEqual(group["latest_decision"], "preflight_blocked_protected_cut")
            self.assertNotIn(group, payload["actionable_confirmation_queue"])

    def test_critical_matchup_regression_blocks_positive_aggregate_signal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            registry = tmp / "registry.json"
            write_json(registry, {"current_leader": "candidate_607_squee_v1"})
            write_json(
                tmp / "lorehold_ghostly_package_gate.json",
                {
                    "packages": [
                        {
                            "package_key": "ghostly_prison_pressure_cut_promise",
                            "family": "combat_tax",
                            "adds": ["Ghostly Prison"],
                            "cuts": ["Promise of Loyalty"],
                            "status": "gated",
                            "gate_summary": {
                                "baseline": {"games": 4, "wins": 1, "losses": 3, "stalls": 0, "win_rate": 25.0},
                                "candidate": {"games": 4, "wins": 2, "losses": 2, "stalls": 0, "win_rate": 50.0},
                                "delta_pp": 25.0,
                            },
                        }
                    ],
                },
            )
            write_json(
                tmp / "lorehold_ghostly_package_gate_detail.json",
                {
                    "results": [
                        {
                            "deck_key": "deck_6",
                            "wins": 1,
                            "losses": 3,
                            "stalls": 0,
                            "win_rate": 25.0,
                            "opponents": [
                                {"opponent": "Winota, Joiner of Forces #39 (real)", "wins": 1, "losses": 1, "stalls": 0, "win_rate": 50.0},
                                {"opponent": "Vivi Ornitier #99 (real)", "wins": 0, "losses": 2, "stalls": 0, "win_rate": 0.0},
                            ],
                        },
                        {
                            "deck_key": "synergy_ghostly_prison_pressure_cut_promise",
                            "wins": 2,
                            "losses": 2,
                            "stalls": 0,
                            "win_rate": 50.0,
                            "opponents": [
                                {"opponent": "Winota, Joiner of Forces #39 (real)", "wins": 0, "losses": 2, "stalls": 0, "win_rate": 0.0},
                                {"opponent": "Vivi Ornitier #99 (real)", "wins": 1, "losses": 1, "stalls": 0, "win_rate": 50.0},
                            ],
                        },
                    ]
                },
            )

            payload = ledger.build_ledger(tmp, registry)

            group = next(row for row in payload["package_groups"] if row["package_key"] == "ghostly_prison_pressure_cut_promise")
            self.assertEqual(group["classification"], "critical_matchup_regression_needs_rework")
            self.assertEqual(group["critical_improvement_count"], 1)
            self.assertEqual(group["critical_regression_count"], 1)
            self.assertEqual(group["winota_coverage_count"], 1)
            self.assertEqual(group["winota_regression_count"], 1)
            self.assertNotIn(group, payload["actionable_confirmation_queue"])


if __name__ == "__main__":
    unittest.main()
