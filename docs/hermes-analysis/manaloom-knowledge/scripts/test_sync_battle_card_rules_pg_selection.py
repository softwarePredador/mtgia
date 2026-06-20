#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import json
import tempfile
import unittest
from unittest import mock
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules_pg.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sync_battle_card_rules_pg_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_pg = load_module()


class SyncBattleCardRulesPgSelectionTests(unittest.TestCase):
    def test_resolve_selected_card_names_from_summary_filters_hotfixes(self) -> None:
        payload = {
            "entries": [
                {
                    "card_name": "Lightning Greaves",
                    "classification": "temporary_hotfix",
                    "recommended_action": "reconcile_pg_rule",
                },
                {
                    "card_name": "Arcane Signet",
                    "classification": "card_rule_promotable",
                    "recommended_action": "already_canonicalized",
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            summary_path = Path(tmpdir) / "summary.json"
            summary_path.write_text(json.dumps(payload), encoding="utf-8")
            args = argparse.Namespace(
                only_card=[],
                only_summary_json=str(summary_path),
                only_classification=["temporary_hotfix"],
                only_recommended_action=["reconcile_pg_rule"],
            )
            selected = sync_pg.resolve_selected_card_names(args)
        self.assertEqual(selected, ["Lightning Greaves"])

    def test_filter_rows_by_card_names_uses_normalized_names(self) -> None:
        rows = [
            {"card_name": "Lightning Greaves"},
            {"card_name": "Arcane Signet"},
        ]
        filtered = sync_pg.filter_rows_by_card_names(rows, ["lightning greaves"])
        self.assertEqual(filtered, [{"card_name": "Lightning Greaves"}])

    def test_export_canonical_snapshot_writes_metadata_rich_payload(self) -> None:
        rows = [
            {
                "card_name": "Lightning Greaves",
                "effect_json": {"effect": "equipment_haste_shroud"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 3,
                "oracle_hash": "abc123",
                "logical_rule_key": "battle_rule_v1:deadbeef",
            }
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_path = Path(tmpdir) / "knowledge.db"
            sqlite_path.touch()
            snapshot_path = Path(tmpdir) / "known_cards_canonical_snapshot.json"
            exported = sync_pg.export_canonical_snapshot(
                rows,
                sqlite_db=str(sqlite_path),
                output_path=snapshot_path,
            )
            payload = json.loads(snapshot_path.read_text(encoding="utf-8"))

        self.assertEqual(exported, 1)
        self.assertEqual(payload["Lightning Greaves"]["effect"], "equipment_haste_shroud")
        self.assertEqual(payload["Lightning Greaves"]["battle_rule_source"], "manual")
        self.assertEqual(payload["Lightning Greaves"]["battle_rule_review_status"], "verified")
        self.assertEqual(payload["Lightning Greaves"]["battle_rule_execution_status"], "auto")
        self.assertEqual(payload["Lightning Greaves"]["battle_rule_logical_key"], "battle_rule_v1:deadbeef")

    def test_filter_rows_for_current_reviewed_curated_drops_superseded_pg_curated_row(self) -> None:
        rows = [
            {
                "card_name": "Scroll Rack",
                "logical_rule_key": "old",
                "effect_json": {
                    "effect": "topdeck_manipulation",
                    "activation_cost_generic": 1,
                    "hand_to_top_exchange": True,
                    "battle_model_scope": "scroll_rack_exchange_unexecuted_v1",
                },
                "deck_role_json": {"category": "draw", "effect": "topdeck_manipulation"},
                "source": "curated",
            },
            {
                "card_name": "Scroll Rack",
                "logical_rule_key": "new",
                "effect_json": {
                    "effect": "topdeck_manipulation",
                    "activation_cost_generic": 1,
                    "hand_to_top_exchange": True,
                    "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                },
                "deck_role_json": {"category": "draw", "effect": "topdeck_manipulation"},
                "source": "curated",
            },
            {
                "card_name": "Scroll Rack",
                "logical_rule_key": "generated",
                "effect_json": {"effect": "ramp_permanent", "mana_produced": 1},
                "deck_role_json": {"category": "ramp", "effect": "ramp_permanent"},
                "source": "generated",
            },
        ]
        reviewed_rows = [
            {
                "card_name": "Scroll Rack",
                "logical_rule_key": "new",
                "effect_json": {
                    "effect": "topdeck_manipulation",
                    "activation_cost_generic": 1,
                    "hand_to_top_exchange": True,
                    "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                },
                "deck_role_json": {"category": "draw", "effect": "topdeck_manipulation"},
                "source": "curated",
            }
        ]

        filtered = sync_pg.filter_rows_for_current_reviewed_curated(rows, reviewed_rows)

        self.assertEqual(len(filtered), 2)
        self.assertEqual(
            [row["logical_rule_key"] for row in filtered if row["source"] == "curated"],
            ["new"],
        )
        self.assertEqual(
            [row["logical_rule_key"] for row in filtered if row["source"] == "generated"],
            ["generated"],
        )

    def test_upsert_pg_rules_preserves_execution_status_in_batch_values(self) -> None:
        captured: dict[str, object] = {}

        def fake_execute_values(cur, sql, values, template, page_size):
            captured["sql"] = sql
            captured["values"] = values
            captured["template"] = template

        row = {
            "card_name": "Aven Mindcensor",
            "logical_rule_key": "battle_rule_v1:static",
            "effect_json": {
                "effect": "passive",
                "ability_kind": "static",
                "opponent_library_search_limited_to_top_cards": 4,
            },
            "deck_role_json": {
                "category": "stax",
                "effect": "library_search_limiter",
            },
            "source": "curated",
            "confidence": 0.93,
            "review_status": "active",
            "execution_status": "annotation_only",
            "notes": "static annotation",
        }

        with (
            mock.patch.object(sync_pg, "load_current_sources", return_value={}),
            mock.patch.object(sync_pg, "load_card_id_lookup", return_value={}),
            mock.patch("psycopg2.extras.execute_values", side_effect=fake_execute_values),
        ):
            changed, skipped = sync_pg.upsert_pg_rules(mock.Mock(), [row])

        self.assertEqual(changed, 1)
        self.assertEqual(skipped, 0)
        self.assertIn("execution_status", str(captured["sql"]))
        self.assertIn("annotation_only", captured["values"][0])
        self.assertIn("%s, %s, 1", str(captured["template"]))


if __name__ == "__main__":
    unittest.main()
