#!/usr/bin/env python3
"""Tests for external exact artifact Oracle backfill."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_exact_artifact_oracle_backfill as backfill


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def create_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
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
              source TEXT NOT NULL DEFAULT 'postgres_cards',
              updated_at TEXT NOT NULL,
              card_id TEXT
            );
            CREATE TABLE card_legalities (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              status TEXT NOT NULL,
              scryfall_id TEXT,
              synced_at TEXT DEFAULT '',
              PRIMARY KEY(card_name, format)
            );
            """
        )


def reviewer_payload(db_path: Path) -> dict[str, object]:
    return {
        "status": "external_exact_artifact_engine_candidate_review_blocks_candidate_copy",
        "input_artifacts": {"source_db": str(db_path)},
        "reviewed_candidate_rows": [
            {
                "card_name": "Digsite Engineer",
                "external_status": "external_exact_engine_candidate_ready_for_local_review",
                "blockers": ["missing_local_oracle_cache"],
            },
            {
                "card_name": "Biotransference",
                "external_status": "exact_type_conversion_engine_candidate",
                "blockers": ["already_in_current_deck"],
            },
        ],
    }


def fake_fetcher(name: str) -> dict[str, object]:
    return {
        "name": name,
        "id": "digsite-id",
        "fetch_status": "fetched",
        "fetch_url": backfill.scryfall_named_url(name),
        "scryfall_uri": "https://scryfall.com/card/test/1",
        "mana_cost": "{2}{W}",
        "colors": ["W"],
        "color_identity": ["W"],
        "type_line": "Creature — Dwarf Artificer",
        "oracle_text": "Whenever you cast an artifact spell, you may pay {2}. If you do, create a 0/0 colorless Construct artifact creature token.",
        "cmc": 3,
        "power": "3",
        "toughness": "3",
        "keywords": [],
        "legalities": {"commander": "legal"},
    }


class GlobalCommanderExternalExactArtifactOracleBackfillTests(unittest.TestCase):
    def test_plan_and_apply_backfill_only_for_missing_reviewed_external_seed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            reviewer = write_json(root, "reviewer.json", reviewer_payload(db_path))
            plan = backfill.build_report(reviewer_report=reviewer, apply=False, fetcher=fake_fetcher)
            applied = backfill.build_report(reviewer_report=reviewer, apply=True, fetcher=fake_fetcher)
            with sqlite3.connect(db_path) as conn:
                count = conn.execute(
                    "SELECT count(*) FROM card_oracle_cache WHERE name = 'Digsite Engineer'"
                ).fetchone()[0]

        self.assertEqual(plan["status"], "external_exact_artifact_oracle_backfill_plan_ready")
        self.assertFalse(plan["source_db_mutated"])
        self.assertEqual(plan["summary"]["backfill_ready_count"], 1)
        self.assertEqual(applied["status"], "external_exact_artifact_oracle_backfill_applied_review_rerun_required")
        self.assertTrue(applied["source_db_mutated"])
        self.assertEqual(applied["summary"]["backfill_applied_count"], 1)
        self.assertEqual(count, 1)
        self.assertFalse(applied["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
