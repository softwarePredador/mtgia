import sqlite3
import unittest
from pathlib import Path

import lorehold_variant_strategy_matrix as matrix


class LoreholdVariantStrategyMatrixTest(unittest.TestCase):
    def test_infers_known_spell_copy_objective(self):
        result = matrix.infer_objective(
            {"archetype": "spell-copy-combo-variant"},
            {"spell_chain_conversion": 20, "topdeck_miracle_setup": 7},
            {"wincon": 8},
            ["Reiterate", "Twinflame"],
        )

        self.assertIn("Spell-copy combo", result["objective"])
        self.assertIn("spell_chain_conversion=20", result["evidence"])

    def test_strategy_score_penalizes_package_shortfalls(self):
        healthy = {
            "strategy_package_health": {
                key: {"ratio": 1.0}
                for key in matrix.PACKAGE_MINIMUMS
            },
            "role_health": {
                key: {"actual": minimum, "minimum": minimum}
                for key, minimum in matrix.FUNCTION_ROLE_MINIMUMS.items()
            },
            "battle_rule_ready_ratio": 1.0,
            "land_count": 33,
            "strategy_package_shortfalls": [],
        }
        weak = {
            **healthy,
            "strategy_package_shortfalls": ["pressure_absorber", "topdeck_miracle_setup"],
            "land_count": 29,
            "battle_rule_ready_ratio": 0.7,
        }

        self.assertGreater(matrix.strategy_score(healthy), matrix.strategy_score(weak))

    def test_build_matrix_loads_local_lorehold_decks_when_db_available(self):
        db = Path("knowledge.db")
        if not db.exists():
            self.skipTest("knowledge.db fixture is not available")
        conn = sqlite3.connect(db)
        conn.row_factory = sqlite3.Row

        payload = matrix.build_matrix(conn, deck_ids=[6, 606], candidate_path=None)

        self.assertEqual(payload["status"], "ready")
        self.assertEqual([deck["deck_key"] for deck in payload["decks"]], ["deck_6", "deck_606"])
        self.assertTrue(payload["ranked_deck_keys"])
        for deck in payload["decks"]:
            self.assertIn("objective", deck)
            self.assertIn("strategy_package_health", deck)
            self.assertIn("next_validation_steps", deck)


if __name__ == "__main__":
    unittest.main()
