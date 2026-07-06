#!/usr/bin/env python3
"""Tests for external exact artifact engine source expander."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_exact_artifact_engine_source_expander as expander


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


def engine_policy_payload(db_path: Path) -> dict[str, object]:
    return {
        "source_db": str(db_path),
        "pool_policy_rows": [{"deck_id": "619", "commander": "Kaalia of the Vast"}],
    }


def fake_fetcher(query: str) -> dict[str, object]:
    return {
        "query": query,
        "url": expander.scryfall_url(query),
        "status": "fetched",
        "total_cards": 3,
        "cards": [
            {
                "name": "Digsite Engineer",
                "color_identity": ["W"],
                "legalities": {"commander": "legal"},
                "oracle_text": "Whenever you cast an artifact spell, you may pay {2}. If you do, create a 0/0 colorless Construct artifact creature token.",
                "type_line": "Creature — Dwarf Artificer",
                "scryfall_uri": "https://scryfall.com/card/test/1",
                "oracle_id": "digsite",
            },
            {
                "name": "Sai, Master Thopterist",
                "color_identity": ["U"],
                "legalities": {"commander": "legal"},
                "oracle_text": "Whenever you cast an artifact spell, create a 1/1 colorless Thopter artifact creature token with flying.",
                "type_line": "Legendary Creature — Human Artificer",
                "scryfall_uri": "https://scryfall.com/card/test/2",
                "oracle_id": "sai",
            },
            {
                "name": "Biotransference",
                "color_identity": ["B"],
                "legalities": {"commander": "legal"},
                "oracle_text": "Creatures you control are artifacts in addition to their other types. Whenever you cast an artifact spell, create a token.",
                "type_line": "Enchantment",
                "scryfall_uri": "https://scryfall.com/card/test/3",
                "oracle_id": "bio",
            },
            {
                "name": "Conspiracy",
                "color_identity": ["B"],
                "legalities": {"commander": "legal"},
                "oracle_text": "As this enters, choose a creature type. Creature spells you control are the chosen type.",
                "type_line": "Enchantment",
                "scryfall_uri": "https://scryfall.com/card/test/4",
                "oracle_id": "conspiracy",
            },
        ],
    }


class GlobalCommanderExternalExactArtifactEngineSourceExpanderTests(unittest.TestCase):
    def test_external_candidates_filter_color_and_current_deck(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            finder = write_json(root, "finder.json", {"status": "local_exhausted"})
            policy = write_json(root, "policy.json", engine_policy_payload(db_path))
            report = expander.build_report(finder_report=finder, engine_policy_report=policy, fetcher=fake_fetcher)

        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["ready_for_local_review_count"], 1)
        by_name = {row["card_name"]: row for row in report["external_candidate_rows"]}
        self.assertEqual(
            by_name["Digsite Engineer"]["status"],
            "external_exact_engine_candidate_ready_for_local_review",
        )
        self.assertIn("outside_commander_color_identity", by_name["Sai, Master Thopterist"]["blockers"])
        self.assertIn("already_in_current_deck", by_name["Biotransference"]["blockers"])
        self.assertNotIn("Conspiracy", by_name)


if __name__ == "__main__":
    unittest.main()
