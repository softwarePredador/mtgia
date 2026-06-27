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
        self.assertEqual(row["strategic_delta"]["hand_to_topdeck_activation"], 3)


if __name__ == "__main__":
    unittest.main()
