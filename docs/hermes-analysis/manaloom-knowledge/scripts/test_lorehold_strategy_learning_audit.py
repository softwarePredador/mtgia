import json
import tempfile
import unittest
from pathlib import Path

import lorehold_strategy_learning_audit as audit


def package_payload(seed, package_key, baseline_wins, baseline_losses, candidate_wins, candidate_losses, delta_pp):
    return {
        "simulation_seed": seed,
        "packages": [
            {
                "package_key": package_key,
                "family": "topdeck_freecast",
                "adds": ["Galvanoth"],
                "cuts": ["Bender's Waterskin"],
                "gate_summary": {
                    "baseline": {
                        "wins": baseline_wins,
                        "losses": baseline_losses,
                        "telemetry": {
                            "event_counts": {
                                "ritual_mana_added": 1,
                            },
                            "strategic_event_counts": {
                                "miracle_cast": 10,
                                "topdeck_manipulation_activated": 5,
                                "spell_cast_mana_trigger": 0,
                                "birgi_spell_cast_mana": 0,
                                "hand_to_topdeck_activation": 0,
                                "squee_to_graveyard": 2,
                                "squee_upkeep_return": 1,
                            }
                        },
                    },
                    "candidate": {
                        "wins": candidate_wins,
                        "losses": candidate_losses,
                        "telemetry": {
                            "event_counts": {
                                "ritual_mana_added": 4,
                            },
                            "strategic_event_counts": {
                                "miracle_cast": 14,
                                "topdeck_manipulation_activated": 9,
                                "spell_cast_mana_trigger": 3,
                                "birgi_spell_cast_mana": 3,
                                "hand_to_topdeck_activation": 1,
                                "squee_to_graveyard": 2,
                                "squee_upkeep_return": 1,
                            }
                        },
                    },
                    "delta_pp": delta_pp,
                },
            }
        ],
    }


class LoreholdStrategyLearningAuditTest(unittest.TestCase):
    def test_card_status_separates_materialization_gap_from_missing_model(self):
        card = {
            "card_name": "Molecule Man",
            "primary_role": "draw",
            "battle_rule_keys": [],
        }

        self.assertEqual(
            audit.card_status(card, {"decision": "deck_rule_materialization_gap"}),
            "materialization_gap_ready_rule",
        )
        self.assertEqual(
            audit.card_status(card, {"decision": "missing_battle_rule_model"}),
            "missing_battle_rule_model",
        )
        self.assertEqual(
            audit.card_status(
                {"card_name": "Thor, God of Thunder", "primary_role": "removal", "battle_rule_keys": []},
                {"decision": "missing_battle_rule_model"},
                {"card": "Thor, God of Thunder", "decision": "local_reviewed_runtime_rule_added_pending_durable_pg_sync"},
            ),
            "local_runtime_rule_added_pending_sync",
        )

    def test_card_decision_manifest_marks_core_flex_and_probation_slots(self):
        deck = {
            "cards": [
                {
                    "card_name": "Lorehold, the Historian",
                    "primary_role": "engine",
                    "battle_rule_keys": ["rule"],
                    "tags": ["topdeck_miracle_setup"],
                    "quantity": 1,
                    "cmc": 5,
                    "type_line": "Legendary Creature",
                },
                {
                    "card_name": "Squee, Goblin Nabob",
                    "primary_role": "wincon",
                    "battle_rule_keys": [],
                    "tags": ["graveyard_recursion", "wincon"],
                    "quantity": 1,
                    "cmc": 3,
                    "type_line": "Legendary Creature",
                },
                {
                    "card_name": "Victory Chimes",
                    "primary_role": "ramp",
                    "battle_rule_keys": ["rule"],
                    "tags": ["ramp"],
                    "quantity": 1,
                    "cmc": 3,
                    "type_line": "Artifact",
                },
                {
                    "card_name": "Command Tower",
                    "primary_role": "land",
                    "battle_rule_keys": [],
                    "tags": ["land"],
                    "quantity": 1,
                    "cmc": 0,
                    "type_line": "Land",
                },
            ]
        }

        manifest = audit.build_card_decision_manifest(
            deck,
            {},
            {},
            {
                "rows": [
                    {
                        "materialized_squee": {
                            "card_name": "Squee, Goblin Nabob",
                            "battle_rule_count": 1,
                        }
                    }
                ]
            },
        )
        by_name = {row["card_name"]: row for row in manifest["cards"]}

        self.assertEqual(by_name["Lorehold, the Historian"]["decision"], "locked_core")
        self.assertEqual(by_name["Squee, Goblin Nabob"]["decision"], "probation_engine")
        self.assertEqual(by_name["Squee, Goblin Nabob"]["status"], "materialized_rule_in_equal_gate_candidate")
        self.assertEqual(by_name["Victory Chimes"]["decision"], "flex_cut_tested_negative")
        self.assertEqual(by_name["Command Tower"]["decision"], "mana_base_core")
        self.assertEqual(manifest["summary"]["decision_counts"]["probation_engine"], 1)

    def test_post_squee_gate_keeps_positive_aggregate_on_probation_when_seed_42_breaks(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            paths = []
            for index, payload in enumerate(
                [
                    package_payload(42, "galvanoth_topdeck_freecast", 8, 1, 4, 5, -44.45),
                    package_payload(7, "galvanoth_topdeck_freecast", 0, 9, 1, 8, 11.11),
                    package_payload(20260625, "galvanoth_topdeck_freecast", 0, 9, 4, 5, 44.44),
                ]
            ):
                path = tmp_path / f"gate_{index}.json"
                path.write_text(json.dumps(payload), encoding="utf-8")
                paths.append(path)

            result = audit.aggregate_post_squee_package_gates(paths)

        rows = result["rows"]
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(row["candidate_wins"], 9)
        self.assertEqual(row["baseline_wins"], 8)
        self.assertEqual(row["strong_seed_delta_pp"], -44.45)
        self.assertEqual(row["decision"], "probation_deeper_gate_only")
        self.assertEqual(row["strategic_delta"]["miracle_cast"], 12)
        self.assertEqual(row["strategic_delta"]["spell_cast_mana_trigger"], 9)
        self.assertEqual(row["strategic_delta"]["birgi_spell_cast_mana"], 9)
        self.assertEqual(row["strategic_delta"]["ritual_mana_added"], 9)
        self.assertEqual(row["strategic_delta"]["hand_to_topdeck_activation"], 3)

    def test_cut_safety_manifest_blocks_collapsed_seed_and_flags_risky_cut(self):
        manifest = audit.build_cut_safety_manifest(
            {
                "rows": [
                    {
                        "package_key": "boros_charm_pressure_cut_fated",
                        "family": "pressure_absorption",
                        "adds": ["Boros Charm"],
                        "cuts": ["Fated Clash"],
                        "baseline_wins": 8,
                        "baseline_losses": 1,
                        "candidate_wins": 0,
                        "candidate_losses": 9,
                        "delta_pp": -88.89,
                        "strong_seed_delta_pp": -88.89,
                        "decision": "reject_or_rework",
                    },
                    {
                        "package_key": "primal_amulet_spell_engine",
                        "family": "topdeck_freecast",
                        "adds": ["Primal Amulet"],
                        "cuts": ["Bender's Waterskin"],
                        "baseline_wins": 8,
                        "baseline_losses": 19,
                        "candidate_wins": 9,
                        "candidate_losses": 18,
                        "delta_pp": 3.7,
                        "strong_seed_delta_pp": -44.45,
                        "decision": "probation_deeper_gate_only",
                    },
                ]
            },
            {
                "cards": [
                    {
                        "card_name": "Fated Clash",
                        "decision": "core_support",
                        "package_lane": "interaction",
                        "effective_role": "removal",
                        "status": "ready",
                    },
                    {
                        "card_name": "Bender's Waterskin",
                        "decision": "engine_flex",
                        "package_lane": "topdeck_setup",
                        "effective_role": "topdeck_setup",
                        "status": "ready",
                    },
                    {
                        "card_name": "Manual Flex",
                        "decision": "manual_review",
                        "package_lane": "support",
                        "effective_role": "support",
                        "status": "ready",
                    },
                ]
            },
        )

        by_name = {row["card_name"]: row for row in manifest["cuts"]}
        self.assertEqual(by_name["Fated Clash"]["status"], "locked_do_not_cut")
        self.assertEqual(by_name["Bender's Waterskin"]["status"], "risky_cut_only_same_lane")
        self.assertEqual(manifest["summary"]["status_counts"]["locked_do_not_cut"], 1)
        self.assertEqual(manifest["summary"]["status_counts"]["risky_cut_only_same_lane"], 1)
        self.assertEqual(manifest["summary"]["blocked_cut_count"], 2)
        self.assertEqual(
            [row["card_name"] for row in manifest["untested_flex_pool"]],
            ["Manual Flex"],
        )


if __name__ == "__main__":
    unittest.main()
