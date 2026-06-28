#!/usr/bin/env python3
"""Unit tests for syncing real ManaLoom target decks into Hermes SQLite."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

import sync_pg_target_deck_to_hermes as sync


class SyncPgTargetDeckToHermesTests(unittest.TestCase):
    def test_write_sqlite_persists_card_id_arrays_and_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"

            stats = sync.write_sqlite(
                str(db_path),
                6,
                {
                    "name": "Runtime Lorehold Learned",
                    "archetype": "midrange",
                    "total_qty": 3,
                    "pg_deck_id": "pg-deck-1",
                },
                [
                    {
                        "card_id": "00000000-0000-0000-0000-000000000001",
                        "name": "Lorehold, the Historian",
                        "quantity": 1,
                        "is_commander": True,
                        "functional_tag": "engine",
                        "functional_tags_json": ["engine", "wincon"],
                        "semantic_tags_v2_json": [
                            {
                                "schema_version": "semantic_v2",
                                "tags": ["engine", "wincon"],
                            }
                        ],
                        "battle_rules_json": [
                            {
                                "rule_version": 1,
                                "source": "curated",
                                "review_status": "verified",
                                "effect": {"effect": "cost_reduction"},
                                "deck_role": {"category": "engine"},
                            }
                        ],
                        "tag_confidence": 0.9,
                        "rule_review_status": "verified",
                        "cmc": 5,
                        "type_line": "Legendary Creature",
                        "oracle_text": "Fixture commander.",
                    },
                    {
                        "card_id": "00000000-0000-0000-0000-000000000002",
                        "name": "Sol Ring",
                        "quantity": 1,
                        "is_commander": False,
                        "functional_tag": "ramp",
                        "functional_tags_json": ["ramp", "artifact"],
                        "semantic_tags_v2_json": [],
                        "battle_rules_json": [
                            {
                                "rule_version": 2,
                                "source": "manual",
                                "review_status": "verified",
                                "effect": {"effect": "ramp_permanent"},
                                "deck_role": {"category": "ramp"},
                            },
                            {
                                "rule_version": 3,
                                "source": "generated",
                                "review_status": "needs_review",
                                "confidence": 0.2,
                                "effect": {"effect": "ramp_permanent"},
                                "deck_role": {"category": "ramp"},
                            },
                            {
                                "rule_version": 1,
                                "source": "manual",
                                "review_status": "needs_review",
                                "effect": {"effect": "artifact_synergy"},
                                "deck_role": {"category": "engine"},
                            },
                        ],
                        "tag_confidence": 0.8,
                        "rule_review_status": "verified",
                        "cmc": 1,
                        "type_line": "Artifact",
                        "oracle_text": "{T}: Add {C}{C}.",
                    },
                    {
                        "card_id": "00000000-0000-0000-0000-000000000003",
                        "name": "Swords to Plowshares",
                        "quantity": 1,
                        "is_commander": False,
                        "functional_tag": "removal",
                        "functional_tags_json": ["removal"],
                        "semantic_tags_v2_json": [],
                        "battle_rules_json": [],
                        "tag_confidence": 0.7,
                        "rule_review_status": None,
                        "cmc": 1,
                        "type_line": "Instant",
                        "oracle_text": "Exile target creature.",
                    },
                ],
                apply=True,
            )

            self.assertEqual(stats["cards_seen"], 3)
            self.assertEqual(stats["cards_written"], 3)
            self.assertEqual(stats["duplicate_rows_collapsed"], 0)
            self.assertEqual(stats["quantity_written"], 3)
            self.assertEqual(stats["commanders"], 1)
            self.assertEqual(stats["battle_rules_seen"], 4)
            self.assertEqual(stats["battle_rules_written"], 3)
            self.assertEqual(stats["battle_rules_deduped"], 1)
            self.assertEqual(len(stats["deck_hash"]), 64)
            self.assertEqual(len(stats["semantics_hash"]), 64)
            self.assertEqual(len(stats["ruleset_hash"]), 64)

            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            try:
                rows = conn.execute(
                    """
                    SELECT
                      card_id,
                      card_name,
                      quantity,
                      functional_tag,
                      functional_tags_json,
                      battle_rules_json,
                      deck_hash,
                      semantics_hash,
                      ruleset_hash,
                      sync_run_id,
                      is_commander
                    FROM deck_cards
                    ORDER BY is_commander DESC, card_name
                    """
                ).fetchall()
            finally:
                conn.close()

            self.assertEqual(len(rows), 3)
            self.assertEqual(rows[0]["card_name"], "Lorehold, the Historian")
            self.assertEqual(
                rows[0]["card_id"],
                "00000000-0000-0000-0000-000000000001",
            )
            self.assertEqual(rows[0]["is_commander"], 1)
            self.assertEqual(rows[1]["card_name"], "Sol Ring")
            self.assertEqual(rows[1]["quantity"], 1)
            self.assertEqual(rows[1]["functional_tag"], "ramp")
            self.assertEqual(sync.parse_json_value(rows[1]["functional_tags_json"], []), ["ramp", "artifact"])
            sol_ring_rules = sync.parse_json_value(rows[1]["battle_rules_json"], [])
            self.assertEqual(len(sol_ring_rules), 2)
            self.assertEqual(sol_ring_rules[0]["source"], "manual")
            self.assertEqual(sol_ring_rules[0]["review_status"], "verified")
            self.assertTrue(sol_ring_rules[0]["logical_rule_key"].startswith("battle_rule_v1:"))
            self.assertEqual(rows[1]["deck_hash"], stats["deck_hash"])
            self.assertEqual(rows[1]["semantics_hash"], stats["semantics_hash"])
            self.assertEqual(rows[1]["ruleset_hash"], stats["ruleset_hash"])
            self.assertTrue(rows[1]["sync_run_id"])

    def test_write_sqlite_rejects_duplicate_card_id_rows(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"

            with self.assertRaises(RuntimeError) as err:
                sync.write_sqlite(
                    str(db_path),
                    6,
                    {
                        "name": "Runtime Lorehold Learned",
                        "archetype": "midrange",
                        "total_qty": 1,
                        "pg_deck_id": "pg-deck-1",
                    },
                    [
                        {
                            "card_id": "00000000-0000-0000-0000-000000000002",
                            "name": "Sol Ring",
                            "quantity": 1,
                            "is_commander": False,
                            "functional_tag": "ramp",
                            "functional_tags_json": ["ramp"],
                            "semantic_tags_v2_json": [],
                            "battle_rules_json": [],
                            "rule_review_status": "active",
                            "cmc": 1,
                            "type_line": "Artifact",
                            "oracle_text": "{T}: Add {C}{C}.",
                        },
                        {
                            "card_id": "00000000-0000-0000-0000-000000000002",
                            "name": "Sol Ring",
                            "quantity": 1,
                            "is_commander": False,
                            "functional_tag": "ramp",
                            "functional_tags_json": ["ramp"],
                            "semantic_tags_v2_json": [],
                            "battle_rules_json": [],
                            "rule_review_status": "active",
                            "cmc": 1,
                            "type_line": "Artifact",
                            "oracle_text": "{T}: Add {C}{C}.",
                        },
                    ],
                    apply=True,
                )

            self.assertIn("duplicate card_id rows", str(err.exception))

    def test_write_sqlite_rejects_missing_card_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"

            with self.assertRaises(RuntimeError) as err:
                sync.write_sqlite(
                    str(db_path),
                    6,
                    {
                        "name": "Runtime Lorehold Learned",
                        "archetype": "midrange",
                        "total_qty": 1,
                        "pg_deck_id": "pg-deck-1",
                    },
                    [
                        {
                            "name": "Sol Ring",
                            "quantity": 1,
                            "is_commander": False,
                            "functional_tag": "ramp",
                            "functional_tags_json": ["ramp"],
                            "semantic_tags_v2_json": [],
                            "battle_rules_json": [],
                            "cmc": 1,
                            "type_line": "Artifact",
                            "oracle_text": "{T}: Add {C}{C}.",
                        },
                    ],
                    apply=True,
                )

            self.assertIn("missing card_id", str(err.exception))

    def test_semantic_deck_cards_sql_aggregates_without_limit_one(self) -> None:
        sql = sync.semantic_deck_cards_sql().lower()

        self.assertIn("function_tags_agg", sql)
        self.assertIn("semantic_tags_v2_agg", sql)
        self.assertIn("battle_rules_agg", sql)
        self.assertIn("jsonb_agg", sql)
        self.assertIn("group by cbr.card_id", sql)
        self.assertNotIn("left join lateral", sql)
        self.assertNotIn("limit 1", sql)

    def test_selected_deck_sql_requires_explicit_commander_fallback(self) -> None:
        args = Namespace(
            pg_deck_id="",
            deck_name_like="%Runtime Lorehold Learned%",
            include_commander_fallback=False,
        )

        where_sql, params = sync.selected_deck_sql(args)

        self.assertEqual(where_sql, "WHERE d.name ILIKE %s")
        self.assertEqual(params, ("%Runtime Lorehold Learned%",))

    def test_selected_deck_sql_can_opt_into_commander_fallback(self) -> None:
        args = Namespace(
            pg_deck_id="",
            deck_name_like="%Runtime Lorehold Learned%",
            include_commander_fallback=True,
        )

        where_sql, params = sync.selected_deck_sql(args)

        self.assertIn("d.name ILIKE %s", where_sql)
        self.assertIn("c2.name ILIKE '%%Lorehold%%'", where_sql)
        self.assertEqual(params, ("%Runtime Lorehold Learned%",))

    def test_normalize_battle_rules_dedupes_equivalent_rules_by_logical_key(self) -> None:
        rules = sync.normalize_battle_rules(
            [
                {
                    "rule_version": 1,
                    "source": "generated",
                    "review_status": "needs_review",
                    "confidence": 0.3,
                    "effect": {"effect": "draw_cards", "amount": 1},
                    "deck_role": {"category": "draw"},
                },
                {
                    "rule_version": 1,
                    "source": "manual",
                    "review_status": "verified",
                    "confidence": 0.9,
                    "effect": {"effect": "draw_cards", "amount": 1},
                    "deck_role": {"category": "draw"},
                },
                {
                    "rule_version": 1,
                    "source": "manual",
                    "review_status": "verified",
                    "confidence": 0.9,
                    "effect": {"effect": "draw_cards", "amount": 2},
                    "deck_role": {"category": "draw"},
                },
            ]
        )

        self.assertEqual(len(rules), 2)
        amount_one = next(rule for rule in rules if rule["effect"]["amount"] == 1)
        self.assertEqual(amount_one["source"], "manual")
        self.assertEqual(amount_one["review_status"], "verified")
        self.assertNotEqual(rules[0]["logical_rule_key"], rules[1]["logical_rule_key"])


if __name__ == "__main__":
    unittest.main()
