import sqlite3
import json
import tempfile
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
        self.addCleanup(conn.close)
        conn.row_factory = sqlite3.Row

        payload = matrix.build_matrix(conn, deck_ids=[6, 606], candidate_path=None)

        self.assertEqual(payload["status"], "ready")
        self.assertEqual([deck["deck_key"] for deck in payload["decks"]], ["deck_6", "deck_606"])
        self.assertTrue(payload["ranked_deck_keys"])
        for deck in payload["decks"]:
            self.assertIn("objective", deck)
            self.assertIn("strategy_package_health", deck)
            self.assertIn("next_validation_steps", deck)

    def test_candidate_metadata_uses_payload_key_when_present(self):
        payload = {
            "candidate_key": "candidate_custom",
            "candidate_name": "Custom Candidate",
            "candidate_archetype": "custom-archetype",
            "candidate_hash": "abc",
            "strategy_version": "test",
            "final_deck": [
                {
                    "card_name": "Lorehold, the Historian",
                    "quantity": 1,
                    "roles": ["engine"],
                    "is_commander": True,
                    "type_line": "Legendary Creature",
                }
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "candidate.json"
            path.write_text(json.dumps(payload), encoding="utf-8")
            metadata, cards = matrix.load_candidate_cards(path)

        self.assertEqual(metadata["deck_key"], "candidate_custom")
        self.assertEqual(metadata["deck_name"], "Custom Candidate")
        self.assertEqual(metadata["archetype"], "custom-archetype")
        self.assertEqual(cards[0]["card_name"], "Lorehold, the Historian")


if __name__ == "__main__":
    unittest.main()
