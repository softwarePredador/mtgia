#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
import json
import sqlite3
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

    def test_filter_rows_for_current_reviewed_curated_keeps_active_pg_curated_row_even_if_reviewed_json_is_older(self) -> None:
        rows = [
            {
                "card_name": "Laughing Mad",
                "logical_rule_key": "old-reviewed",
                "effect_json": {
                    "effect": "draw_cards",
                    "count": 2,
                    "battle_model_scope": "discard_draw_two_flashback_v1",
                },
                "deck_role_json": {"category": "interaction", "effect": "targeted_interaction"},
                "source": "curated",
                "review_status": "deprecated",
                "execution_status": "disabled",
            },
            {
                "card_name": "Laughing Mad",
                "logical_rule_key": "new-pg",
                "effect_json": {
                    "effect": "draw_cards",
                    "ability_kind": "one_shot",
                    "battle_model_scope": "source_controller_draw_variant_v1",
                },
                "deck_role_json": {"category": "interaction", "effect": "targeted_interaction"},
                "source": "curated",
                "review_status": "verified",
                "execution_status": "auto",
            },
        ]
        reviewed_rows = [
            {
                "card_name": "Laughing Mad",
                "logical_rule_key": "old-reviewed",
                "effect_json": {
                    "effect": "draw_cards",
                    "count": 2,
                    "battle_model_scope": "discard_draw_two_flashback_v1",
                },
                "deck_role_json": {"category": "interaction", "effect": "targeted_interaction"},
                "source": "curated",
            }
        ]

        filtered = sync_pg.filter_rows_for_current_reviewed_curated(rows, reviewed_rows)

        self.assertEqual(
            [row["logical_rule_key"] for row in filtered if row["source"] == "curated"],
            ["new-pg"],
        )

    def test_merge_pg_rows_does_not_reappend_stale_reviewed_curated_row_when_pg_has_active_curated_card(self) -> None:
        rows = [
            {
                "card_name": "Mind Stone",
                "normalized_name": "mind stone",
                "logical_rule_key": "pg-new",
                "effect_json": {
                    "effect": "ramp_permanent",
                    "mana_produced": 1,
                    "produces": "C",
                    "activated_self_sacrifice_draw": True,
                    "battle_model_scope": "mana_rock_self_sacrifice_draw_v1",
                },
                "deck_role_json": {"category": "ramp", "effect": "ramp_permanent"},
                "source": "curated",
                "review_status": "verified",
                "execution_status": "auto",
                "oracle_hash": "abc123",
            }
        ]
        reviewed_rows = [
            {
                "card_name": "Mind Stone",
                "logical_rule_key": "reviewed-old",
                "effect_json": {
                    "effect": "ramp_permanent",
                    "mana_produced": 1,
                    "produces": "C",
                    "activated_self_sacrifice_draw": True,
                    "battle_model_scope": "mana_rock_self_sacrifice_draw_v1",
                },
                "deck_role_json": {"category": "ramp", "effect": "ramp_permanent"},
                "source": "curated",
            }
        ]

        merged = sync_pg.merge_pg_rows_with_reviewed_runtime_rows(rows, reviewed_rows)

        self.assertEqual(len(merged), 1)
        self.assertEqual(merged[0]["logical_rule_key"], "pg-new")

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

    def test_upsert_pg_rules_does_not_blank_existing_oracle_hash_or_curated_metadata(self) -> None:
        captured: dict[str, object] = {}

        def fake_execute_values(cur, sql, values, template, page_size):
            captured["sql"] = sql
            captured["values"] = values

        row = {
            "card_name": "Seething Song",
            "logical_rule_key": "battle_rule_v1:ritual",
            "effect_json": {
                "effect": "ramp_ritual",
                "mana_produced": 5,
                "produces": "R",
                "battle_model_scope": "single_shot_red_ritual_v1",
            },
            "deck_role_json": {
                "category": "ramp",
                "effect": "ramp_ritual",
            },
            "source": "curated",
            "confidence": 0.97,
            "review_status": "verified",
            "execution_status": "auto",
            "notes": "reviewed runtime row without hash in source JSON",
        }

        with (
            mock.patch.object(
                sync_pg,
                "load_current_sources",
                return_value={("seething song", "battle_rule_v1:ritual"): "curated"},
            ),
            mock.patch.object(sync_pg, "load_card_id_lookup", return_value={}),
            mock.patch("psycopg2.extras.execute_values", side_effect=fake_execute_values),
        ):
            changed, skipped = sync_pg.upsert_pg_rules(mock.Mock(), [row])

        self.assertEqual(changed, 1)
        self.assertEqual(skipped, 0)
        self.assertIn(
            "card_battle_rules.effect_json || EXCLUDED.effect_json",
            str(captured["sql"]),
        )
        self.assertIn(
            "COALESCE(NULLIF(EXCLUDED.oracle_hash, ''), card_battle_rules.oracle_hash)",
            str(captured["sql"]),
        )
        self.assertIsNone(captured["values"][0][10])

    def test_pg_mirror_preserves_pg_logical_key_and_removes_shadow_rows(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(sqlite_db) as conn:
                sync_pg.battle_rule_registry.ensure_battle_card_rules(conn)
                sync_pg.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Flame Wave",
                    {"effect": "damage_player_and_creatures"},
                    source="curated",
                    confidence=1.0,
                    review_status="verified",
                    logical_rule_key_value="local-shadow-key",
                )
                sync_pg.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Flame Wave",
                    {"effect": "manual"},
                    source="manual",
                    confidence=1.0,
                    review_status="verified",
                    logical_rule_key_value="manual-key",
                )
                conn.commit()

            changed = sync_pg.mirror_pg_rules_to_sqlite(
                str(sqlite_db),
                [
                    {
                        "normalized_name": "flame wave",
                        "card_name": "Flame Wave",
                        "logical_rule_key": "pg-key",
                        "effect_json": {"effect": "damage_player_and_creatures"},
                        "deck_role_json": {"category": "removal"},
                        "source": "curated",
                        "confidence": 1.0,
                        "review_status": "verified",
                        "execution_status": "auto",
                        "rule_version": 4,
                        "notes": "test",
                        "oracle_hash": "hash",
                    }
                ],
            )

            self.assertGreaterEqual(changed, 1)
            with sqlite3.connect(sqlite_db) as conn:
                rows = conn.execute(
                    """
                    SELECT logical_rule_key, source, rule_version
                    FROM battle_card_rules
                    WHERE normalized_name = 'flame wave'
                    ORDER BY logical_rule_key
                    """
                ).fetchall()

        self.assertIn(("pg-key", "curated", 4), rows)
        self.assertNotIn(("local-shadow-key", "curated", 1), rows)

    def test_pg_mirror_keeps_reviewed_runtime_row_over_pg_review_only_snapshot(self) -> None:
        reviewed_rows = [
            {
                "card_name": "Brainstone",
                "effect_json": {
                    "effect": "topdeck_manipulation",
                    "activation_cost_generic": 2,
                    "requires_sacrifice_artifact": True,
                    "draw_count": 3,
                    "put_from_hand_on_top_count": 2,
                    "battle_model_scope": "brainstone_draw_three_put_two_back_unexecuted_v1",
                },
                "deck_role_json": {
                    "category": "draw",
                    "effect": "topdeck_manipulation",
                },
                "source": "curated",
                "confidence": 0.88,
                "review_status": "active",
                "execution_status": "auto",
                "notes": "reviewed runtime row",
            }
        ]
        pg_rows = [
            {
                "normalized_name": "brainstone",
                "card_name": "Brainstone",
                "logical_rule_key": "pg-generated-review-only",
                "effect_json": {"effect": "draw_cards", "count": 3},
                "deck_role_json": {"category": "draw"},
                "source": "generated",
                "confidence": 0.55,
                "review_status": "needs_review",
                "execution_status": "review_only",
                "notes": "broad generated approximation",
                "oracle_hash": "hash",
            }
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            snapshot_path = Path(tmpdir) / "known_cards_canonical_snapshot.json"

            changed = sync_pg.mirror_pg_rules_to_sqlite(
                str(sqlite_db),
                pg_rows,
                reviewed_rows=reviewed_rows,
            )
            exported = sync_pg.export_canonical_snapshot(
                sync_pg.load_active_snapshot_rows(sqlite_db),
                sqlite_db=str(sqlite_db),
                output_path=snapshot_path,
            )
            payload = json.loads(snapshot_path.read_text(encoding="utf-8"))

            with sqlite3.connect(sqlite_db) as conn:
                rows = conn.execute(
                    """
                    SELECT source, review_status, execution_status, effect_json
                    FROM battle_card_rules
                    WHERE normalized_name = 'brainstone'
                    ORDER BY source, review_status, execution_status
                    """
                ).fetchall()

        self.assertGreaterEqual(changed, 2)
        self.assertEqual(exported, 1)
        self.assertIn(("curated", "active", "auto", json.dumps(reviewed_rows[0]["effect_json"], sort_keys=True)), rows)
        self.assertEqual(payload["Brainstone"]["effect"], "topdeck_manipulation")
        self.assertEqual(payload["Brainstone"]["battle_rule_source"], "curated")
        self.assertEqual(payload["Brainstone"]["battle_rule_review_status"], "active")
        self.assertEqual(payload["Brainstone"]["battle_rule_execution_status"], "auto")

    def test_merge_pg_rows_restores_reviewed_hash_for_same_runtime_key(self) -> None:
        pg_rows = [
            {
                "normalized_name": "valakut awakening",
                "card_name": "Valakut Awakening",
                "logical_rule_key": "battle_rule_v1:valakut-simple",
                "effect_json": {
                    "effect": "hand_filter",
                    "draw_extra": 1,
                    "max_bottom": 99,
                },
                "deck_role_json": {"category": "draw"},
                "source": "curated",
                "confidence": 0.9,
                "review_status": "verified",
                "execution_status": "auto",
                "rule_version": 2,
                "notes": "PG row missing provenance",
                "oracle_hash": None,
            }
        ]
        reviewed_rows = [
            {
                "card_name": "Valakut Awakening",
                "logical_rule_key": "battle_rule_v1:valakut-simple",
                "effect_json": {
                    "effect": "hand_filter",
                    "draw_extra": 1,
                    "max_bottom": 99,
                    "battle_model_scope": "bottom_then_draw_plus_one_v1",
                },
                "deck_role_json": {"category": "draw"},
                "source": "curated",
                "confidence": 0.9,
                "review_status": "active",
                "execution_status": "auto",
                "oracle_hash": "22b42fcc181b7aed71f78b2e1e51e887",
            }
        ]

        merged = sync_pg.merge_pg_rows_with_reviewed_runtime_rows(
            pg_rows,
            reviewed_rows,
        )

        self.assertEqual(len(merged), 1)
        self.assertEqual(
            merged[0]["oracle_hash"],
            "22b42fcc181b7aed71f78b2e1e51e887",
        )
        self.assertEqual(
            merged[0]["effect_json"]["battle_model_scope"],
            "bottom_then_draw_plus_one_v1",
        )

    def test_pg_mirror_preserves_existing_sqlite_hash_when_pg_hash_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(sqlite_db) as conn:
                sync_pg.battle_rule_registry.ensure_battle_card_rules(conn)
                sync_pg.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Valakut Awakening",
                    {
                        "effect": "hand_filter",
                        "draw_extra": 1,
                        "max_bottom": 99,
                        "battle_model_scope": "bottom_then_draw_plus_one_v1",
                    },
                    source="curated",
                    confidence=0.9,
                    review_status="verified",
                    execution_status="auto",
                    oracle_hash="22b42fcc181b7aed71f78b2e1e51e887",
                    logical_rule_key_value="battle_rule_v1:valakut-simple",
                    rule_version=2,
                )
                conn.commit()

            sync_pg.mirror_pg_rules_to_sqlite(
                str(sqlite_db),
                [
                    {
                        "normalized_name": "valakut awakening",
                        "card_name": "Valakut Awakening",
                        "logical_rule_key": "battle_rule_v1:valakut-simple",
                        "effect_json": {
                            "effect": "hand_filter",
                            "draw_extra": 1,
                            "max_bottom": 99,
                            "battle_model_scope": "bottom_then_draw_plus_one_v1",
                        },
                        "deck_role_json": {"category": "draw"},
                        "source": "curated",
                        "confidence": 0.9,
                        "review_status": "verified",
                        "execution_status": "auto",
                        "rule_version": 2,
                        "notes": "PG row missing hash",
                        "oracle_hash": None,
                    }
                ],
            )

            with sqlite3.connect(sqlite_db) as conn:
                row = conn.execute(
                    """
                    SELECT oracle_hash
                    FROM battle_card_rules
                    WHERE normalized_name = 'valakut awakening'
                      AND logical_rule_key = 'battle_rule_v1:valakut-simple'
                    """
                ).fetchone()

        self.assertEqual(row[0], "22b42fcc181b7aed71f78b2e1e51e887")


if __name__ == "__main__":
    unittest.main()
