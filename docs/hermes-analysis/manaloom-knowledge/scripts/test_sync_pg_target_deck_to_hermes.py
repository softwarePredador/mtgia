#!/usr/bin/env python3
"""Unit tests for syncing real ManaLoom target decks into Hermes SQLite."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch

import sync_pg_target_deck_to_hermes as sync


class SyncPgTargetDeckToHermesTests(unittest.TestCase):
    def test_cli_defaults_to_exact_canonical_postgres_deck(self) -> None:
        with patch.dict(
            "os.environ",
            {
                "MANALOOM_TARGET_PG_DECK_ID": "",
                "MANALOOM_CANONICAL_PG_DECK_ID": "",
            },
            clear=False,
        ), patch("sys.argv", ["sync_pg_target_deck_to_hermes.py"]):
            args = sync.parse_args()

        self.assertEqual(args.pg_deck_id, sync.DEFAULT_CANONICAL_PG_DECK_ID)
        self.assertEqual(args.protected_pg_deck_id, sync.DEFAULT_CANONICAL_PG_DECK_ID)

    def test_protected_target_binding_accepts_only_canonical_by_default(self) -> None:
        args = Namespace(
            target_deck_id=6,
            protected_pg_deck_id=sync.DEFAULT_CANONICAL_PG_DECK_ID,
            allow_protected_target_override=False,
        )

        accepted = sync.validate_protected_target_binding(
            args,
            {"pg_deck_id": sync.DEFAULT_CANONICAL_PG_DECK_ID},
        )
        self.assertTrue(accepted["matched"])

        with self.assertRaises(RuntimeError) as err:
            sync.validate_protected_target_binding(
                args,
                {"pg_deck_id": "528c877f-f829-4207-95e6-73981776c323"},
            )
        self.assertIn("Refusing to replace protected Hermes deck_id=6", str(err.exception))

    def test_protected_target_binding_allows_explicit_override_or_other_slot(self) -> None:
        runtime_deck = {"pg_deck_id": "528c877f-f829-4207-95e6-73981776c323"}
        override = Namespace(
            target_deck_id=6,
            protected_pg_deck_id=sync.DEFAULT_CANONICAL_PG_DECK_ID,
            allow_protected_target_override=True,
        )
        other_slot = Namespace(
            target_deck_id=608,
            protected_pg_deck_id=sync.DEFAULT_CANONICAL_PG_DECK_ID,
            allow_protected_target_override=False,
        )

        self.assertTrue(
            sync.validate_protected_target_binding(override, runtime_deck)["override"]
        )
        self.assertFalse(
            sync.validate_protected_target_binding(other_slot, runtime_deck)[
                "protected_target"
            ]
        )

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
                deck_exists=lambda _pg_deck_id: True,
            )

            self.assertEqual(stats["cards_seen"], 3)
            self.assertEqual(stats["cards_written"], 3)
            self.assertEqual(stats["card_ids_canonicalized"], 0)
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

    def test_write_sqlite_uses_canonical_card_id_from_oracle_cache(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            printing_id = "00000000-0000-0000-0000-000000000002"
            canonical_id = "10000000-0000-0000-0000-000000000002"
            conn = sqlite3.connect(db_path)
            try:
                conn.execute(
                    """
                    CREATE TABLE card_oracle_cache (
                        normalized_name TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        card_id TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    INSERT INTO card_oracle_cache (normalized_name, name, card_id)
                    VALUES ('sol ring', 'Sol Ring', ?)
                    """,
                    (canonical_id,),
                )
                conn.commit()
            finally:
                conn.close()

            stats = sync.write_sqlite(
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
                        "card_id": printing_id,
                        "name": " Sol Ring ",
                        "quantity": 1,
                        "is_commander": False,
                        "functional_tag": "ramp",
                        "functional_tags_json": ["ramp"],
                        "semantic_tags_v2_json": [],
                        "battle_rules_json": [],
                        "cmc": 1,
                        "type_line": "Artifact",
                        "oracle_text": "{T}: Add {C}{C}.",
                    }
                ],
                apply=True,
                deck_exists=lambda _pg_deck_id: True,
            )

            conn = sqlite3.connect(db_path)
            try:
                stored_card_id = conn.execute(
                    "SELECT card_id FROM deck_cards WHERE deck_id = 6"
                ).fetchone()[0]
            finally:
                conn.close()

            self.assertEqual(stats["card_ids_canonicalized"], 1)
            self.assertEqual(stored_card_id, canonical_id)

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
                    deck_exists=lambda _pg_deck_id: True,
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
                    deck_exists=lambda _pg_deck_id: True,
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

    def test_snapshot_hash_ignores_rejected_and_deprecated_rule_history(self) -> None:
        base_card = {
            "card_id": "00000000-0000-0000-0000-000000000001",
            "name": "Plains // Plains",
            "quantity": 4,
            "is_commander": False,
            "functional_tag": "land",
            "functional_tags_json": ["land"],
            "semantic_tags_v2_json": [],
            "cmc": 0,
            "type_line": "Basic Land - Plains",
            "oracle_text": "{T}: Add {W}.",
        }
        active_rule = {
            "logical_rule_key": "battle_rule_v1:active",
            "rule_version": 2,
            "source": "curated",
            "review_status": "verified",
            "execution_status": "auto",
            "effect": {"effect": "land", "produces": "W"},
            "deck_role": {"category": "ramp"},
        }

        hashes = []
        for stale_status, stale_note in (
            ("deprecated", "old bulk rule"),
            ("rejected", "different historical row"),
        ):
            card = dict(base_card)
            card["battle_rules_json"] = [
                active_rule,
                {
                    "logical_rule_key": "battle_rule_v1:stale",
                    "rule_version": 1,
                    "source": "curated",
                    "review_status": stale_status,
                    "execution_status": "disabled",
                    "effect": {"effect": "land"},
                    "deck_role": {"category": "land"},
                    "notes": stale_note,
                },
            ]
            normalized = sync.normalize_snapshot_cards([card])
            self.assertEqual(len(normalized[0]["battle_rules"]), 1)
            hashes.append(sync.snapshot_hashes(normalized)[2])

        self.assertEqual(hashes[0], hashes[1])


    # BT-AI-030: a conferência no PostgreSQL acontece com o lock de escrita do
    # SQLite já tomado, como no alimentador.
    _LOCK_DECK = {
        "name": "Runtime Lorehold Learned",
        "archetype": "midrange",
        "total_qty": 1,
        "pg_deck_id": "8938B746-1A9E-46CE-B0D9-C2EC932DDDDD",
    }
    _LOCK_CARDS = [
        {
            "card_id": "00000000-0000-0000-0000-000000000003",
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
        }
    ]

    @staticmethod
    def _write_lock_is_held(db_path: Path) -> bool:
        probe = sqlite3.connect(db_path, timeout=0)
        try:
            probe.execute("BEGIN IMMEDIATE")
        except sqlite3.OperationalError as error:
            return "locked" in str(error)
        else:
            probe.rollback()
            return False
        finally:
            probe.close()

    @staticmethod
    def _target_rows(db_path: Path) -> tuple[int, int]:
        conn = sqlite3.connect(db_path)
        try:
            decks = conn.execute("SELECT count(*) FROM decks WHERE id = 6").fetchone()[0]
            cards = conn.execute(
                "SELECT count(*) FROM deck_cards WHERE deck_id = 6"
            ).fetchone()[0]
            return decks, cards
        finally:
            conn.close()

    def test_apply_confirms_the_pg_deck_under_the_sqlite_write_lock(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            seen: list[tuple[str, bool]] = []

            def deck_exists(pg_deck_id: str) -> bool:
                seen.append((pg_deck_id, self._write_lock_is_held(db_path)))
                return True

            stats = sync.write_sqlite(
                str(db_path),
                6,
                self._LOCK_DECK,
                self._LOCK_CARDS,
                apply=True,
                deck_exists=deck_exists,
            )

            self.assertEqual(
                seen, [("8938B746-1A9E-46CE-B0D9-C2EC932DDDDD", True)]
            )
            self.assertTrue(stats["pg_deck_confirmed_under_sqlite_lock"])
            self.assertEqual(self._target_rows(db_path), (1, 1))
            self.assertFalse(self._write_lock_is_held(db_path))

    def test_apply_refuses_a_deck_deleted_after_the_read(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            # Uma cópia anterior do alvo fica como estava: quem apaga cópia de
            # deck excluído é o expurgo, não este script.
            sync.write_sqlite(
                str(db_path),
                6,
                self._LOCK_DECK,
                self._LOCK_CARDS,
                apply=True,
                deck_exists=lambda _pg_deck_id: True,
            )
            before = self._target_rows(db_path)

            with self.assertRaises(sync.DeckGoneError) as err:
                sync.write_sqlite(
                    str(db_path),
                    6,
                    {**self._LOCK_DECK, "name": "Nova cópia"},
                    self._LOCK_CARDS,
                    apply=True,
                    deck_exists=lambda _pg_deck_id: False,
                )

            self.assertNotIn(
                self._LOCK_DECK["pg_deck_id"].lower(), str(err.exception).lower()
            )
            self.assertEqual(self._target_rows(db_path), before)
            conn = sqlite3.connect(db_path)
            try:
                name = conn.execute("SELECT deck_name FROM decks WHERE id = 6").fetchone()[0]
            finally:
                conn.close()
            self.assertEqual(name, "Runtime Lorehold Learned")
            self.assertFalse(self._write_lock_is_held(db_path))

    def test_apply_without_a_callback_uses_the_postgres_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            calls: list[str] = []

            def fake_pg_check(pg_deck_id: str) -> bool:
                calls.append(pg_deck_id)
                return False

            with patch.object(sync, "pg_deck_still_exists", fake_pg_check):
                with self.assertRaises(sync.DeckGoneError):
                    sync.write_sqlite(
                        str(db_path),
                        6,
                        self._LOCK_DECK,
                        self._LOCK_CARDS,
                        apply=True,
                    )

            self.assertEqual(calls, ["8938B746-1A9E-46CE-B0D9-C2EC932DDDDD"])
            self.assertEqual(self._target_rows(db_path), (0, 0))

    def test_dry_run_takes_no_lock_and_asks_nothing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"

            def deck_exists(_pg_deck_id: str) -> bool:
                raise AssertionError("dry run must not ask PostgreSQL")

            stats = sync.write_sqlite(
                str(db_path),
                6,
                self._LOCK_DECK,
                self._LOCK_CARDS,
                apply=False,
                deck_exists=deck_exists,
            )

            self.assertNotIn("pg_deck_confirmed_under_sqlite_lock", stats)
            self.assertEqual(self._target_rows(db_path), (0, 0))

    def test_deck_still_in_postgres_ignores_the_trash(self) -> None:
        class FakeCursor:
            def __init__(self, row):
                self.row = row
                self.executed: list[tuple[str, tuple]] = []

            def execute(self, sql, params):
                self.executed.append((sql, params))

            def fetchone(self):
                return self.row

        alive = FakeCursor((1,))
        self.assertTrue(
            sync.deck_still_in_postgres(alive, " 8938B746-1A9E-46CE-B0D9-C2EC932DDDDD ")
        )
        sql, params = alive.executed[0]
        self.assertIn("FROM decks", sql)
        self.assertIn("deleted_at IS NULL", sql)
        self.assertEqual(params, ("8938b746-1a9e-46ce-b0d9-c2ec932ddddd",))

        gone = FakeCursor(None)
        self.assertFalse(sync.deck_still_in_postgres(gone, "qualquer"))


if __name__ == "__main__":
    unittest.main()
