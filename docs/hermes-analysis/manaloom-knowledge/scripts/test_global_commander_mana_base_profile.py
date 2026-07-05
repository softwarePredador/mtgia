#!/usr/bin/env python3
"""Tests for global Commander mana-base profiles."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_mana_base_profile as audit


def land_gap_row(deck_id: str = "900", commander: str = "Test Commander") -> dict:
    return {
        "deck_id": deck_id,
        "deck_name": f"Deck {deck_id}",
        "commander": commander,
        "scope": "hermes_registered_variant",
        "role": "land",
        "missing": 2,
        "current_count": 32,
        "target_min": 34,
    }


class GlobalCommanderManaBaseProfileTests(unittest.TestCase):
    def _db(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        tmp = tempfile.TemporaryDirectory()
        path = Path(tmp.name) / "knowledge.db"
        conn = sqlite3.connect(path)
        conn.execute(
            """
            CREATE TABLE deck_cards (
              deck_id TEXT,
              card_name TEXT,
              quantity INTEGER,
              functional_tag TEXT,
              is_commander INTEGER,
              cmc REAL,
              type_line TEXT,
              oracle_text TEXT,
              card_id TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
              name TEXT,
              normalized_name TEXT,
              mana_cost TEXT,
              colors_json TEXT,
              color_identity_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              scryfall_id TEXT,
              card_id TEXT
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                (
                    "900",
                    "Test Commander",
                    1,
                    "engine",
                    1,
                    4,
                    "Legendary Creature",
                    "",
                    "cmd",
                ),
                (
                    "900",
                    "Command Tower",
                    1,
                    "land",
                    0,
                    0,
                    "Land",
                    "Add one mana of any color in your commander's color identity.",
                    "tower",
                ),
                (
                    "900",
                    "Clifftop Retreat",
                    1,
                    "land",
                    0,
                    0,
                    "Land",
                    "This land enters tapped unless you control a Mountain or a Plains.\n{T}: Add {R} or {W}.",
                    "retreat",
                ),
                (
                    "900",
                    "Ancient Tomb",
                    1,
                    "land",
                    0,
                    0,
                    "Land",
                    "{T}: Add {C}{C}.",
                    "tomb",
                ),
                (
                    "900",
                    "Arid Mesa",
                    1,
                    "land",
                    0,
                    0,
                    "Land",
                    "Search your library for a Mountain or Plains card, put it onto the battlefield, then shuffle.",
                    "mesa",
                ),
            ],
        )
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (
                "Test Commander",
                "test commander",
                "{2}{R}{W}",
                '["R","W"]',
                '["R","W"]',
                "Legendary Creature",
                "",
                4,
                "",
                "cmd",
            ),
        )
        conn.commit()
        conn.close()
        return tmp, path

    def test_land_gap_profile_uses_commander_identity_and_counts_sources(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            repair_payload={"hypotheses": [land_gap_row()]},
            sqlite_db=path,
        )

        [profile] = payload["profiles"]
        self.assertFalse(payload["mutation_allowed"])
        self.assertEqual(profile["status"], "mana_profile_ready_for_named_land_candidate_pool")
        self.assertEqual(profile["commander_color_identity"], ["W", "R"])
        self.assertEqual(profile["direct_or_fetch_access_by_color"], {"W": 3, "R": 3})
        self.assertEqual(profile["mana_base_counts"]["colorless_only_quantity"], 1)
        self.assertEqual(profile["mana_base_counts"]["conditional_tapped_quantity"], 1)
        self.assertIn("add_land_quantity_before_spell_slots", profile["recommended_land_classes"])

    def test_missing_commander_identity_blocks_named_land_candidates(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)
        conn = sqlite3.connect(path)
        conn.execute("DELETE FROM card_oracle_cache")
        conn.commit()
        conn.close()

        payload = audit.build_report(
            repair_payload={"hypotheses": [land_gap_row(commander="Unknown Commander")]},
            sqlite_db=path,
        )

        [profile] = payload["profiles"]
        self.assertEqual(profile["status"], "blocked_missing_commander_color_identity")
        self.assertEqual(profile["commander_color_identity"], [])
        self.assertIn("named_land_candidate_pool_by_commander_color_identity", profile["required_next_gates"])

    def test_non_land_hypotheses_are_ignored(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            repair_payload={"hypotheses": [{**land_gap_row(), "role": "removal"}]},
            sqlite_db=path,
        )

        self.assertEqual(payload["summary"]["profile_count"], 0)
        self.assertEqual(payload["profiles"], [])


if __name__ == "__main__":
    unittest.main()
