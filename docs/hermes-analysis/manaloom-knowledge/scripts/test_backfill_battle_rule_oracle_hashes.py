#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import backfill_battle_rule_oracle_hashes as backfill


def create_fixture_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.execute(
            """
            CREATE TABLE battle_card_rules (
              normalized_name TEXT NOT NULL,
              logical_rule_key TEXT NOT NULL,
              card_name TEXT NOT NULL,
              effect_json TEXT NOT NULL DEFAULT '{}',
              deck_role_json TEXT NOT NULL DEFAULT '{}',
              source TEXT NOT NULL DEFAULT 'curated',
              confidence REAL NOT NULL DEFAULT 1.0,
              review_status TEXT NOT NULL DEFAULT 'verified',
              execution_status TEXT NOT NULL DEFAULT 'auto',
              rule_version INTEGER NOT NULL DEFAULT 1,
              oracle_hash TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              last_seen_at TEXT,
              PRIMARY KEY (normalized_name, logical_rule_key)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              oracle_text TEXT,
              source TEXT NOT NULL DEFAULT 'postgres_cards',
              updated_at TEXT NOT NULL
            )
            """
        )
        conn.executemany(
            """
            INSERT INTO card_oracle_cache (
              normalized_name, name, oracle_text, updated_at
            ) VALUES (?, ?, ?, 'now')
            """,
            [
                ("trusted card", "Trusted Card", " Draw a card. "),
                ("active card", "Active Card", "Destroy target creature."),
                ("generated card", "Generated Card", "Create a token."),
                ("missing oracle", "Missing Oracle", ""),
            ],
        )
        conn.executemany(
            """
            INSERT INTO battle_card_rules (
              normalized_name, logical_rule_key, card_name, source,
              review_status, execution_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 'now', 'now')
            """,
            [
                (
                    "trusted card",
                    "battle_rule_v1:trusted",
                    "Trusted Card",
                    "curated",
                    "verified",
                    "auto",
                ),
                (
                    "active card",
                    "battle_rule_v1:active",
                    "Active Card",
                    "curated",
                    "active",
                    "auto",
                ),
                (
                    "generated card",
                    "battle_rule_v1:generated",
                    "Generated Card",
                    "generated",
                    "needs_review",
                    "review_only",
                ),
                (
                    "missing oracle",
                    "battle_rule_v1:missing",
                    "Missing Oracle",
                    "curated",
                    "verified",
                    "auto",
                ),
            ],
        )
        conn.commit()


class BattleRuleOracleHashBackfillTests(unittest.TestCase):
    def test_build_plan_targets_only_trusted_executable_missing_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            create_fixture_db(sqlite_db)

            plan = backfill.build_backfill_plan(sqlite_db)

        self.assertEqual(plan["candidate_count"], 3)
        self.assertEqual(plan["update_count"], 2)
        self.assertEqual(plan["skipped_missing_oracle_text_count"], 1)
        self.assertEqual(
            {item["normalized_name"] for item in plan["updates"]},
            {"trusted card", "active card"},
        )
        hashes_by_name = {
            item["normalized_name"]: item["oracle_hash"] for item in plan["updates"]
        }
        self.assertEqual(
            hashes_by_name["trusted card"],
            hashlib.md5("Draw a card.".encode("utf-8")).hexdigest(),
        )

    def test_apply_backfill_updates_only_planned_rows(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            create_fixture_db(sqlite_db)
            plan = backfill.build_backfill_plan(sqlite_db)

            changed = backfill.apply_backfill(sqlite_db, plan)

            with sqlite3.connect(sqlite_db) as conn:
                rows = dict(
                    conn.execute(
                        """
                        SELECT normalized_name, COALESCE(oracle_hash, '')
                        FROM battle_card_rules
                        ORDER BY normalized_name
                        """
                    ).fetchall()
                )

        self.assertEqual(changed, 2)
        self.assertNotEqual(rows["trusted card"], "")
        self.assertNotEqual(rows["active card"], "")
        self.assertEqual(rows["generated card"], "")
        self.assertEqual(rows["missing oracle"], "")


if __name__ == "__main__":
    unittest.main()
