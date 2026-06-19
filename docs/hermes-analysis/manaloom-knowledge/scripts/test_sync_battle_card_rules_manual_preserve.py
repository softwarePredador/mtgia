#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from unittest import mock
from pathlib import Path

import battle_rule_registry

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sync_battle_card_rules_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_rules = load_module()


class SyncBattleCardRulesManualPreserveTests(unittest.TestCase):
    def test_manual_rows_are_empty_after_canonicalization(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
        )
        self.assertEqual(sum(1 for row in rows if row["source"] == "manual"), 0)
        self.assertGreaterEqual(sum(1 for row in rows if row["source"] == "curated"), 1)

    def test_runtime_waiver_is_promoted_into_manual_rows_when_injected(self) -> None:
        injected_rule = {
            "effect": "ramp_permanent",
            "mana_produced": 1,
            "produces": "WUBRGC",
            "requires_legendary_creature_or_planeswalker_for_mana": True,
        }
        with mock.patch.object(sync_rules.battle, "MANUAL_RULE_RUNTIME_WAIVERS", {"Mox Amber"}):
            with mock.patch.object(
                sync_rules.battle,
                "HANDCRAFTED_KNOWN_CARD_RULES",
                {"Mox Amber": injected_rule},
            ):
                rows = sync_rules.build_rows(
                    include_generated=False,
                    sqlite_db=str(sync_rules.DEFAULT_DB),
                )
        manual_rows = [row for row in rows if row["source"] == "manual"]
        self.assertEqual(len(manual_rows), 1)
        self.assertEqual(manual_rows[0]["card_name"], "Mox Amber")
        self.assertEqual(manual_rows[0]["review_status"], "verified")
        self.assertEqual(manual_rows[0]["effect_json"], injected_rule)

    def test_sqlite_registry_preserves_multiple_logical_rules_for_same_name(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                first_changed = sync_rules.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "draw_cards", "amount": 2},
                    source="curated",
                    confidence=0.9,
                    review_status="verified",
                )
                second_changed = sync_rules.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "remove_creature", "target": "creature"},
                    source="curated",
                    confidence=0.9,
                    review_status="verified",
                )
                conn.commit()
                rows = conn.execute(
                    """
                    SELECT normalized_name, logical_rule_key, effect_json
                    FROM battle_card_rules
                    WHERE normalized_name = 'modal test card'
                    ORDER BY logical_rule_key
                    """
                ).fetchall()

            rules = battle_rule_registry.load_active_battle_card_rules(sqlite_db)
            rule_lists = battle_rule_registry.load_active_battle_card_rule_lists(sqlite_db)
            lookup_rules = battle_rule_registry.lookup_battle_card_rule_list(
                sqlite_db,
                "Modal Test Card",
            )

        self.assertTrue(first_changed)
        self.assertTrue(second_changed)
        self.assertEqual(len(rows), 2)
        self.assertEqual(len({row[1] for row in rows}), 2)
        self.assertIn("modal test card", rules)
        self.assertEqual(len(rule_lists["modal test card"]), 2)
        self.assertEqual(len(lookup_rules), 2)
        self.assertEqual(
            {rule["effect_json"]["effect"] for rule in lookup_rules},
            {"draw_cards", "remove_creature"},
        )
        self.assertIn(
            rules["modal test card"]["effect_json"]["effect"],
            {"draw_cards", "remove_creature"},
        )

    def test_legacy_snapshot_export_preserves_rule_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                sync_rules.ensure_battle_card_rules(conn)
                sync_rules.upsert_battle_card_rule(
                    conn,
                    "Traceable Test Card",
                    {"effect": "draw_cards", "amount": 2},
                    source="curated",
                    confidence=0.91,
                    review_status="active",
                    execution_status="annotation_only",
                    oracle_hash="oracle-hash-test",
                )
                conn.commit()

            rows = sync_rules.load_active_snapshot_rows(sqlite_db)
            payload = sync_rules.build_snapshot_payload(rows)

        entry = payload["Traceable Test Card"]
        self.assertEqual(entry["effect"], "draw_cards")
        self.assertEqual(entry["battle_rule_source"], "curated")
        self.assertEqual(entry["battle_rule_review_status"], "active")
        self.assertEqual(entry["battle_rule_execution_status"], "annotation_only")
        self.assertEqual(entry["battle_rule_confidence"], 0.91)
        self.assertEqual(entry["battle_rule_oracle_hash"], "oracle-hash-test")
        self.assertTrue(entry["battle_rule_logical_key"].startswith("battle_rule_v1:"))

    def test_legacy_apply_preserves_deck_role_in_logical_key(self) -> None:
        effect = {
            "effect": "topdeck_manipulation",
            "activation_cost_generic": 2,
        }
        deck_role = {
            "category": "draw",
            "effect": "topdeck_manipulation",
            "subtype": "activated_draw_topdeck_filter",
        }
        expected_key = battle_rule_registry.logical_rule_key(
            {
                "effect_json": effect,
                "deck_role_json": deck_role,
            }
        )
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            sync_rules.apply_rows_to_sqlite_cache(
                sqlite_db,
                [
                    {
                        "card_name": "Traceable Role Card",
                        "effect_json": effect,
                        "deck_role_json": deck_role,
                        "source": "curated",
                        "confidence": 0.88,
                        "review_status": "active",
                        "execution_status": "annotation_only",
                        "notes": "test",
                        "oracle_hash": "oracle-hash-test",
                    }
                ],
            )
            rows = sync_rules.load_active_snapshot_rows(sqlite_db)
            payload = sync_rules.build_snapshot_payload(rows)

        entry = payload["Traceable Role Card"]
        self.assertEqual(entry["battle_rule_logical_key"], expected_key)
        self.assertEqual(entry["battle_rule_execution_status"], "annotation_only")

    def test_cleanup_obsolete_manual_rows_removes_stale_shadowing_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                sync_rules.ensure_battle_card_rules(conn)
                sync_rules.upsert_battle_card_rule(
                    conn,
                    "Scroll Rack",
                    {"effect": "topdeck_manipulation"},
                    source="manual",
                    confidence=1.0,
                    review_status="verified",
                )
                sync_rules.upsert_battle_card_rule(
                    conn,
                    "Scroll Rack",
                    {
                        "effect": "topdeck_manipulation",
                        "activation_cost_generic": 1,
                        "hand_to_top_exchange": True,
                    },
                    source="curated",
                    confidence=0.8,
                    review_status="active",
                )
                conn.commit()

                deleted = sync_rules.cleanup_obsolete_manual_rows(conn)
                conn.commit()
                remaining = conn.execute(
                    """
                    SELECT source, effect_json
                    FROM battle_card_rules
                    WHERE normalized_name = 'scroll rack'
                    ORDER BY source
                    """
                ).fetchall()

            rules = battle_rule_registry.load_active_battle_card_rules(sqlite_db)

        self.assertEqual(deleted, 1)
        self.assertEqual(len(remaining), 1)
        self.assertEqual(remaining[0][0], "curated")
        self.assertEqual(
            rules["scroll rack"]["effect_json"]["activation_cost_generic"],
            1,
        )
        self.assertTrue(rules["scroll rack"]["effect_json"]["hand_to_top_exchange"])

    def test_cleanup_stale_reviewed_rows_replaces_old_curated_shape(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                sync_rules.ensure_battle_card_rules(conn)
                sync_rules.upsert_battle_card_rule(
                    conn,
                    "Scroll Rack",
                    {
                        "effect": "topdeck_manipulation",
                        "activation_cost_generic": 1,
                        "hand_to_top_exchange": True,
                        "battle_model_scope": "scroll_rack_exchange_unexecuted_v1",
                    },
                    source="curated",
                    confidence=0.8,
                    review_status="active",
                )
                conn.commit()

                deleted = sync_rules.cleanup_stale_reviewed_rows(
                    conn,
                    [
                        {
                            "card_name": "Scroll Rack",
                            "effect_json": {
                                "effect": "topdeck_manipulation",
                                "activation_cost_generic": 1,
                                "hand_to_top_exchange": True,
                                "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                            },
                            "deck_role_json": {
                                "category": "draw",
                                "effect": "topdeck_manipulation",
                            },
                            "source": "curated",
                        }
                    ],
                )
                sync_rules.upsert_battle_card_rule(
                    conn,
                    "Scroll Rack",
                    {
                        "effect": "topdeck_manipulation",
                        "activation_cost_generic": 1,
                        "hand_to_top_exchange": True,
                        "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                    },
                    source="curated",
                    confidence=0.8,
                    review_status="active",
                )
                conn.commit()

                remaining = conn.execute(
                    """
                    SELECT source, effect_json
                    FROM battle_card_rules
                    WHERE normalized_name = 'scroll rack'
                    ORDER BY source
                    """
                ).fetchall()

            rules = battle_rule_registry.load_active_battle_card_rules(sqlite_db)

        self.assertEqual(deleted, 1)
        self.assertEqual(len(remaining), 1)
        self.assertEqual(remaining[0][0], "curated")
        self.assertEqual(
            rules["scroll rack"]["effect_json"]["battle_model_scope"],
            "scroll_rack_upkeep_single_exchange_v1",
        )


if __name__ == "__main__":
    unittest.main()
