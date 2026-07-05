#!/usr/bin/env python3
"""Tests for global Commander named land candidate pools."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_named_land_candidate_pool as audit


def ready_profile() -> dict:
    return {
        "deck_id": "900",
        "deck_name": "Deck 900",
        "commander": "Test Commander",
        "status": "mana_profile_ready_for_named_land_candidate_pool",
        "commander_color_identity": ["W", "R"],
        "recommended_land_classes": [
            "add_land_quantity_before_spell_slots",
            "add_W_source_or_fetchable_access",
            "add_R_source_or_fetchable_access",
            "prioritize_untapped_fixing_lands",
            "limit_colorless_utility_until_color_floor",
            "review_fetchable_dual_or_basic_mix",
        ],
    }


class GlobalCommanderNamedLandCandidatePoolTests(unittest.TestCase):
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
        conn.execute(
            """
            CREATE TABLE card_legalities (
              card_name TEXT,
              format TEXT,
              status TEXT,
              scryfall_id TEXT,
              synced_at TEXT
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                ("900", "Test Commander", 1, "engine", 1, 4, "Legendary Creature", "", "cmd"),
                ("900", "Command Tower", 1, "land", 0, 0, "Land", "", "tower"),
            ],
        )
        conn.executemany(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                (
                    "Command Tower",
                    "command tower",
                    "",
                    "[]",
                    "[]",
                    "Land",
                    "Add one mana of any color in your commander's color identity.",
                    0,
                    "tower-sf",
                    "tower",
                ),
                (
                    "Battlefield Forge",
                    "battlefield forge",
                    "",
                    "[]",
                    '["R","W"]',
                    "Land",
                    "{T}: Add {C}.\n{T}: Add {R} or {W}. This land deals 1 damage to you.",
                    0,
                    "forge-sf",
                    "forge",
                ),
                (
                    "Boros Garrison",
                    "boros garrison",
                    "",
                    "[]",
                    '["R","W"]',
                    "Land",
                    "This land enters tapped.\nWhen this land enters, return a land you control to its owner's hand.\n{T}: Add {R}{W}.",
                    0,
                    "garrison-sf",
                    "garrison",
                ),
                (
                    "Ancient Tomb",
                    "ancient tomb",
                    "",
                    "[]",
                    "[]",
                    "Land",
                    "{T}: Add {C}{C}.",
                    0,
                    "tomb-sf",
                    "tomb",
                ),
                (
                    "Breeding Pool",
                    "breeding pool",
                    "",
                    "[]",
                    '["G","U"]',
                    "Land - Forest Island",
                    "({T}: Add {G} or {U}.)",
                    0,
                    "pool-sf",
                    "pool",
                ),
            ],
        )
        conn.executemany(
            "INSERT INTO card_legalities VALUES (?, 'commander', ?, '', '')",
            [
                ("Command Tower", "legal"),
                ("Battlefield Forge", "legal"),
                ("Boros Garrison", "legal"),
                ("Ancient Tomb", "legal"),
                ("Breeding Pool", "legal"),
            ],
        )
        conn.commit()
        conn.close()
        return tmp, path

    def test_candidate_pool_filters_current_cards_and_off_color_lands(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            mana_payload={"profiles": [ready_profile()]},
            sqlite_db=path,
            limit=10,
        )

        [pool] = payload["candidate_pools"]
        names = [row["card_name"] for row in pool["top_candidates"]]
        self.assertFalse(payload["mutation_allowed"])
        self.assertIn("Battlefield Forge", names)
        self.assertIn("Boros Garrison", names)
        self.assertNotIn("Command Tower", names)
        self.assertNotIn("Breeding Pool", names)
        self.assertGreater(names.index("Boros Garrison"), names.index("Battlefield Forge"))

    def test_missing_legality_is_kept_as_review_required(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)
        conn = sqlite3.connect(path)
        conn.execute("DELETE FROM card_legalities WHERE card_name = 'Battlefield Forge'")
        conn.commit()
        conn.close()

        payload = audit.build_report(
            mana_payload={"profiles": [ready_profile()]},
            sqlite_db=path,
            limit=10,
        )

        [pool] = payload["candidate_pools"]
        forge = next(row for row in pool["top_candidates"] if row["card_name"] == "Battlefield Forge")
        self.assertEqual(forge["status"], "review_only_requires_commander_legality_check")
        self.assertEqual(forge["commander_legality"], "missing")

    def test_non_ready_profiles_are_not_pooled(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)
        profile = ready_profile()
        profile["status"] = "blocked_missing_commander_color_identity"

        payload = audit.build_report(
            mana_payload={"profiles": [profile]},
            sqlite_db=path,
        )

        self.assertEqual(payload["summary"]["pool_count"], 0)
        self.assertEqual(payload["candidate_pools"], [])


if __name__ == "__main__":
    unittest.main()
