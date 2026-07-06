#!/usr/bin/env python3
"""Tests for external exact artifact engine candidate reviewer."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_exact_artifact_engine_candidate_reviewer as reviewer


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
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              scryfall_id TEXT
            );
            CREATE TABLE card_legalities (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              status TEXT NOT NULL
            );
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY,
              deck_id INTEGER,
              card_name TEXT NOT NULL
            );
            """
        )
        conn.executemany(
            "INSERT INTO card_oracle_cache(normalized_name, name, color_identity_json, type_line, oracle_text, scryfall_id) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            [
                (
                    "digsite engineer",
                    "Digsite Engineer",
                    '["W"]',
                    "Creature — Dwarf Artificer",
                    "Whenever you cast an artifact spell, you may pay {2}. If you do, create a 0/0 colorless Construct artifact creature token.",
                    "digsite-scryfall",
                ),
                (
                    "biotransference",
                    "Biotransference",
                    '["B"]',
                    "Enchantment",
                    "Creatures you control are artifacts in addition to their other types.",
                    "bio-scryfall",
                ),
            ],
        )
        conn.executemany(
            "INSERT INTO card_legalities(card_name, format, status) VALUES (?, 'commander', 'legal')",
            [("Digsite Engineer",), ("Golem Foundry",), ("Biotransference",)],
        )
        conn.execute("INSERT INTO deck_cards(deck_id, card_name) VALUES (619, 'Biotransference')")


def expander_payload(db_path: Path) -> dict[str, object]:
    return {
        "status": "external_exact_artifact_engine_source_lanes_expanded_no_deck_action",
        "input_artifacts": {"source_db": str(db_path)},
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "external_candidate_rows": [
            {
                "card_name": "Digsite Engineer",
                "status": "external_exact_engine_candidate_ready_for_local_review",
                "raw_exact_status": "exact_artifact_spell_payoff_candidate",
                "signals": ["artifact_spell_token_payoff"],
                "color_identity": ["W"],
                "commander_legality": "legal",
                "oracle_id": "digsite",
                "scryfall_uri": "https://scryfall.com/card/test/1",
                "oracle_excerpt": "Whenever you cast an artifact spell, create a token.",
            },
            {
                "card_name": "Golem Foundry",
                "status": "external_exact_engine_candidate_ready_for_local_review",
                "raw_exact_status": "exact_artifact_spell_payoff_candidate",
                "signals": ["artifact_spell_token_payoff"],
                "color_identity": [],
                "commander_legality": "legal",
                "oracle_id": "golem",
                "scryfall_uri": "https://scryfall.com/card/test/2",
                "oracle_excerpt": "Whenever you cast an artifact spell, put a charge counter on this artifact.",
            },
            {
                "card_name": "Biotransference",
                "status": "exact_type_conversion_engine_candidate",
                "raw_exact_status": "exact_type_conversion_engine_candidate",
                "signals": ["artifact_type_conversion_engine"],
                "color_identity": ["B"],
                "commander_legality": "legal",
                "oracle_id": "bio",
                "scryfall_uri": "https://scryfall.com/card/test/3",
                "oracle_excerpt": "Creatures you control are artifacts.",
            },
        ],
    }


class GlobalCommanderExternalExactArtifactEngineCandidateReviewerTests(unittest.TestCase):
    def test_review_requires_local_oracle_and_current_deck_absence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            expander = write_json(root, "expander.json", expander_payload(db_path))
            report = reviewer.build_report(expander_report=expander)

        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["local_review_ready_count"], 1)
        self.assertEqual(report["summary"]["missing_local_oracle_count"], 1)
        by_name = {row["card_name"]: row for row in report["reviewed_candidate_rows"]}
        self.assertEqual(
            by_name["Digsite Engineer"]["status"],
            "local_external_exact_engine_candidate_ready_for_add_cut_review",
        )
        self.assertIn("missing_local_oracle_cache", by_name["Golem Foundry"]["blockers"])
        self.assertIn("already_in_current_deck", by_name["Biotransference"]["blockers"])
        self.assertIn(
            "external_status_not_ready_for_local_review:exact_type_conversion_engine_candidate",
            by_name["Biotransference"]["blockers"],
        )


if __name__ == "__main__":
    unittest.main()
