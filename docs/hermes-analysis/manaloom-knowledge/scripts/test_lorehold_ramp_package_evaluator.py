import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import lorehold_ramp_package_evaluator as evaluator


class LoreholdRampPackageEvaluatorTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmp.name) / "ramp.db"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.executescript(
            """
            CREATE TABLE card_oracle_cache (
                normalized_name TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                mana_cost TEXT,
                colors_json TEXT,
                color_identity_json TEXT,
                type_line TEXT,
                oracle_text TEXT,
                cmc REAL,
                power TEXT,
                toughness TEXT,
                keywords_json TEXT,
                scryfall_id TEXT,
                source TEXT NOT NULL DEFAULT 'test',
                updated_at TEXT NOT NULL DEFAULT 'now'
            );
            CREATE TABLE battle_card_rules (
                normalized_name TEXT NOT NULL,
                logical_rule_key TEXT NOT NULL,
                card_name TEXT NOT NULL,
                effect_json TEXT NOT NULL DEFAULT '{}',
                deck_role_json TEXT NOT NULL DEFAULT '{}',
                source TEXT NOT NULL DEFAULT 'curated',
                confidence REAL NOT NULL DEFAULT 1.0,
                review_status TEXT NOT NULL DEFAULT 'active',
                execution_status TEXT NOT NULL DEFAULT 'auto',
                rule_version INTEGER NOT NULL DEFAULT 1,
                oracle_hash TEXT,
                notes TEXT,
                created_at TEXT NOT NULL DEFAULT 'now',
                updated_at TEXT NOT NULL DEFAULT 'now',
                last_seen_at TEXT,
                PRIMARY KEY (normalized_name, logical_rule_key)
            );
            """
        )
        self.insert_card(
            "Mana Vault",
            cmc=1,
            effect={
                "effect": "ramp_permanent",
                "mana_produced": 3,
                "produces": "C",
                "does_not_untap_normally": True,
                "upkeep_optional_untap_cost_generic": 4,
                "tapped_draw_step_damage": 1,
                "battle_model_scope": "fast_mana_artifact_partial_v1",
            },
        )
        self.insert_card(
            "Arcane Signet",
            cmc=2,
            effect={
                "effect": "ramp_permanent",
                "mana_produced": 1,
                "produces": "RW",
                "battle_model_scope": "commander_identity_mana_rock_deck_scoped_v1",
            },
        )
        self.conn.commit()

    def tearDown(self):
        self.conn.close()
        self.tmp.cleanup()

    def insert_card(self, name, *, cmc, effect):
        normalized = name.lower()
        self.conn.execute(
            """
            INSERT INTO card_oracle_cache (
                normalized_name, name, type_line, oracle_text, cmc, colors_json,
                color_identity_json, keywords_json
            )
            VALUES (?, ?, 'Artifact', '', ?, '[]', '[]', '[]')
            """,
            (normalized, name, cmc),
        )
        self.conn.execute(
            """
            INSERT INTO battle_card_rules (
                normalized_name, logical_rule_key, card_name, effect_json, deck_role_json
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                normalized,
                f"test:{normalized}",
                name,
                json.dumps(effect),
                json.dumps({"category": "ramp", "effect": effect["effect"]}),
            ),
        )

    def test_mana_vault_profile_captures_burst_and_risks(self):
        profile = evaluator.ramp_profile(self.conn, "Mana Vault")

        self.assertEqual(profile["mana_produced"], 3)
        self.assertEqual(profile["same_turn_net_mana"], 2)
        self.assertTrue(profile["fast_mana"])
        self.assertFalse(profile["recurring_source"])
        self.assertTrue(profile["colorless_only"])
        self.assertIn("nonstandard_untap", profile["risk_flags"])
        self.assertIn("untap_tax", profile["risk_flags"])
        self.assertIn("draw_step_damage", profile["risk_flags"])
        self.assertNotIn("upkeep_damage", profile["risk_flags"])

    def test_legacy_upkeep_damage_field_is_a_draw_step_compatibility_alias(self):
        effect = {
            "effect": "ramp_permanent",
            "mana_produced": 3,
            "produces": "C",
            "does_not_untap_normally": True,
            "tapped_upkeep_damage": 1,
        }
        self.conn.execute(
            "UPDATE battle_card_rules SET effect_json=? WHERE normalized_name='mana vault'",
            (json.dumps(effect),),
        )
        self.conn.commit()

        profile = evaluator.ramp_profile(self.conn, "Mana Vault")

        self.assertIn("draw_step_damage", profile["risk_flags"])
        self.assertNotIn("upkeep_damage", profile["risk_flags"])

    def test_mana_vault_over_arcane_is_burst_vs_fixing_tradeoff(self):
        result = evaluator.evaluate_package(
            self.conn,
            "mana_vault_fast_mana_cut_arcane_signet",
            {
                "family": "fast_mana",
                "hypothesis": "test",
                "adds": ["Mana Vault"],
                "cuts": ["Arcane Signet"],
            },
        )

        self.assertEqual(result["delta"]["same_turn_net_mana"], 3)
        self.assertEqual(result["delta"]["lorehold_colored_fixing"], -2)
        self.assertEqual(result["delta"]["recurring_source_count"], -1)
        self.assertEqual(
            result["ramp_static_classification"],
            "burst_vs_fixing_or_recurring_tradeoff",
        )


if __name__ == "__main__":
    unittest.main()
