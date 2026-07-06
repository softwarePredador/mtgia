#!/usr/bin/env python3
"""Tests for exact artifact type-conversion source lane expander."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_exact_artifact_type_conversion_source_lane_expander as expander


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def create_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
            """
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY,
              deck_id INTEGER,
              card_name TEXT NOT NULL
            );
            """
        )
        conn.execute("INSERT INTO deck_cards(deck_id, card_name) VALUES (619, 'Biotransference')")


def fake_fetcher(query: str) -> dict[str, object]:
    return {
        "query": query,
        "url": expander.scryfall_url(query),
        "status": "fetched",
        "total_cards": 2,
        "cards": [
            {
                "name": "Biotransference",
                "color_identity": ["B"],
                "legalities": {"commander": "legal"},
                "oracle_text": "Creatures you control are artifacts in addition to their other types.",
                "type_line": "Enchantment",
                "scryfall_uri": "https://scryfall.com/card/test/1",
                "oracle_id": "bio",
            },
            {
                "name": "Mardu Converter",
                "color_identity": ["R", "W"],
                "legalities": {"commander": "legal"},
                "oracle_text": "Creatures you control are artifacts in addition to their other types.",
                "type_line": "Enchantment",
                "scryfall_uri": "https://scryfall.com/card/test/2",
                "oracle_id": "mardu",
            },
        ],
    }


class GlobalCommanderExactArtifactTypeConversionSourceLaneExpanderTests(unittest.TestCase):
    def test_type_conversion_lane_blocks_current_deck_and_surfaces_ready_outside_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            pair = write_json(root, "pair.json", {"input_artifacts": {"source_db": str(db_path)}})
            reviewer = write_json(root, "reviewer.json", {"summary": {"deck_id": "619"}})
            report = expander.build_report(
                pair_model_report=pair,
                candidate_reviewer_report=reviewer,
                fetcher=fake_fetcher,
            )

        by_name = {row["card_name"]: row for row in report["source_candidate_rows"]}
        self.assertIn("already_in_current_deck", by_name["Biotransference"]["blockers"])
        self.assertEqual(
            by_name["Mardu Converter"]["status"],
            "exact_artifact_type_conversion_source_ready_for_add_cut_model",
        )
        self.assertEqual(report["summary"]["ready_type_conversion_candidate_count"], 1)
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
