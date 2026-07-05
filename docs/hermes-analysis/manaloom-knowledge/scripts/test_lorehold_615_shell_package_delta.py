import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import lorehold_615_shell_package_delta as delta


class Lorehold615ShellPackageDeltaTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmp.name) / "knowledge.db"
        self.battle_path = Path(self.tmp.name) / "battle.json"
        conn = sqlite3.connect(self.db_path)
        conn.executescript(
            """
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                deck_id INTEGER,
                card_name TEXT NOT NULL,
                quantity INTEGER DEFAULT 1,
                functional_tag TEXT,
                tag_confidence REAL,
                is_commander INTEGER DEFAULT 0,
                is_partner INTEGER DEFAULT 0,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT,
                card_id TEXT,
                functional_tags_json TEXT DEFAULT '[]',
                semantic_tags_v2_json TEXT DEFAULT '[]',
                battle_rules_json TEXT DEFAULT '[]',
                deck_hash TEXT,
                semantics_hash TEXT,
                sync_run_id TEXT,
                ruleset_hash TEXT,
                UNIQUE(deck_id, card_name)
            );
            """
        )
        self.insert_card(conn, 607, "Lorehold, the Historian", 1, "commander")
        self.insert_card(conn, 607, "Plains", 4, "land", type_line="Basic Land - Plains")
        self.insert_card(conn, 607, "Scroll Rack", 1, "draw", type_line="Artifact")
        self.insert_card(conn, 607, "Bender's Waterskin", 1, "ramp", type_line="Artifact")
        self.insert_card(conn, 615, "Lorehold, the Historian", 1, "commander")
        self.insert_card(conn, 615, "Plains", 8, "land", type_line="Basic Land - Plains")
        self.insert_card(conn, 615, "Mana Vault", 1, "ramp", type_line="Artifact")
        self.insert_card(conn, 615, "The One Ring", 1, "draw", type_line="Legendary Artifact")
        self.insert_card(conn, 615, "Underworld Breach", 1, "engine", type_line="Enchantment")
        conn.commit()
        conn.close()
        self.battle_path.write_text(
            json.dumps(
                {
                    "status": "pass",
                    "generated_at": "2026-07-05T00:00:00+00:00",
                    "opponent_seed": 123,
                    "simulation_seed": 456,
                    "games_per_opponent": 4,
                    "opponents": [{"deck_id": 1, "deck_key": "opp"}],
                    "results": [
                        {
                            "deck_key": "deck_607",
                            "deck_id": 607,
                            "wins": 1,
                            "losses": 3,
                            "win_rate": 25.0,
                            "avg_win_turn": 18.0,
                            "strategy_score": 139.0,
                            "primary_risks": ["draw_role"],
                            "telemetry": {
                                "card_event_counts": {
                                    "topdeck_manipulation_activated:Scroll Rack": 5,
                                    "cost_paid:Bender's Waterskin": 2,
                                },
                                "strategic_event_counts": {"miracle_cast": 2},
                            },
                        },
                        {
                            "deck_key": "deck_615",
                            "deck_id": 615,
                            "wins": 3,
                            "losses": 1,
                            "win_rate": 75.0,
                            "avg_win_turn": 12.0,
                            "strategy_score": 134.0,
                            "primary_risks": ["removal_role"],
                            "telemetry": {
                                "card_event_counts": {
                                    "cost_paid:Mana Vault": 2,
                                    "spell_cast:Mana Vault": 2,
                                    "cost_paid:The One Ring": 1,
                                    "utility_artifact_activated:The One Ring": 3,
                                    "spell_cast:Underworld Breach": 4,
                                },
                                "strategic_event_counts": {"miracle_cast": 7},
                            },
                        },
                    ],
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self):
        self.tmp.cleanup()

    def insert_card(
        self,
        conn: sqlite3.Connection,
        deck_id: int,
        name: str,
        quantity: int,
        tag: str,
        *,
        type_line: str = "",
    ):
        conn.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, functional_tag, type_line, functional_tags_json
            )
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (deck_id, name, quantity, tag, type_line, json.dumps([tag])),
        )

    def test_quantity_delta_counts_basic_land_quantity_shift(self):
        with delta.connect_readonly(self.db_path) as conn:
            baseline = delta.load_deck_cards(conn, 607)
            challenger = delta.load_deck_cards(conn, 615)

        additions, removals, shared = delta.quantity_delta(baseline, challenger)

        self.assertEqual(sum(row["delta_quantity"] for row in additions), 7)
        self.assertEqual(sum(row["delta_quantity"] for row in removals), 2)
        plains = next(row for row in additions if row["card_name"] == "Plains")
        self.assertEqual(plains["delta_quantity"], 4)
        self.assertEqual(plains["package_group"], "mana_base_quantity_shift")
        self.assertEqual([row["card_name"] for row in shared], ["Lorehold, the Historian"])

    def test_build_payload_keeps_positive_shell_signal_non_promotional(self):
        payload = delta.build_payload(
            source_db=self.db_path,
            battle_report=self.battle_path,
            baseline_deck_id=607,
            challenger_deck_id=615,
        )

        self.assertEqual(payload["deck_delta_summary"]["added_quantity"], 7)
        self.assertEqual(payload["deck_delta_summary"]["removed_quantity"], 2)
        self.assertEqual(payload["deck_delta_summary"]["official_power_watch_added_count"], 3)
        self.assertEqual(
            payload["decision"]["status"],
            "615_positive_battle_signal_requires_power_bracket_review_and_repeat_gate",
        )
        self.assertFalse(payload["decision"]["promotion_ready_from_this_report"])
        self.assertFalse(payload["mutation_flags"]["baseline_607_modified"])
        self.assertFalse(payload["mutation_flags"]["postgres_writes_performed"])

    def test_added_card_events_group_by_real_card_names(self):
        payload = delta.build_payload(
            source_db=self.db_path,
            battle_report=self.battle_path,
            baseline_deck_id=607,
            challenger_deck_id=615,
        )

        observed = {
            row["card_name"]: row["event_total"]
            for row in payload["added_card_events"]["cards"]
        }
        self.assertEqual(observed["The One Ring"], 4)
        self.assertEqual(observed["Underworld Breach"], 4)
        self.assertEqual(observed["Mana Vault"], 4)
        fast_mana = next(
            row
            for row in payload["added_package_groups"]
            if row["package_group"] == "fast_mana_burst"
        )
        self.assertIn("Mana Vault", fast_mana["observed_cards"])


if __name__ == "__main__":
    unittest.main()
