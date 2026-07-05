#!/usr/bin/env python3
"""Tests for global Commander land cut candidate model."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_land_cut_candidate_model as audit


def named_land_pool() -> dict:
    return {
        "candidate_pools": [
            {
                "deck_id": "900",
                "deck_name": "Deck 900",
                "commander": "Test Commander",
                "candidate_count": 2,
                "top_candidates": [
                    {"card_name": "Battlefield Forge", "score": 94},
                    {"card_name": "Sunbaked Canyon", "score": 90},
                ],
            }
        ]
    }


def core_role_report(*, missing_roles: list[str] | None = None, excess_roles: list[str] | None = None) -> dict:
    missing_roles = ["land"] if missing_roles is None else missing_roles
    excess_roles = ["engine"] if excess_roles is None else excess_roles
    return {
        "decks": [
            {
                "deck_id": "900",
                "core_repair_plan": {
                    "missing_role_slots": [
                        {"role": role, "missing": 1, "severity": "critical"}
                        for role in missing_roles
                    ],
                    "excess_role_slots": [
                        {"role": role, "count": 30, "target_max": 24, "excess": 6, "severity": "support"}
                        for role in excess_roles
                    ],
                },
            }
        ]
    }


class GlobalCommanderLandCutCandidateModelTests(unittest.TestCase):
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
              functional_tags_json TEXT,
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
            CREATE TABLE format_staples (
              card_name TEXT,
              format TEXT,
              archetype TEXT,
              category TEXT,
              color_identity TEXT,
              edhrec_rank INTEGER,
              is_banned INTEGER
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                ("900", "Test Commander", 1, "engine", '["engine"]', 1, 4, "Legendary Creature", "Whenever you draw, copy target spell.", "cmd"),
                ("900", "Ancient Tomb", 1, "land", '["land"]', 0, 0, "Land", "{T}: Add {C}{C}.", "land"),
                ("900", "Expensive Engine", 1, "engine", '["engine"]', 0, 6, "Artifact", "Whenever you cast a spell, copy target spell.", "engine"),
                ("900", "Package Exception", 8, "engine", '["engine"]', 0, 2, "Sorcery", "A deck can have any number of cards named Package Exception. Whenever you cast it, copy target spell.", "package"),
                ("900", "Topdeck Engine", 1, "engine", '["engine"]', 0, 1, "Artifact", "Look at the top card of your library. You may cast spells from the top of your library.", "topdeck"),
                ("900", "Removal Engine", 1, "engine", '["engine","removal"]', 0, 5, "Instant", "Destroy target creature. Whenever a creature dies, draw a card.", "mixed"),
                ("900", "Pure Draw", 1, "draw", '["draw"]', 0, 3, "Sorcery", "Draw two cards.", "draw"),
            ],
        )
        conn.execute(
            "INSERT INTO format_staples VALUES ('Expensive Engine', 'commander', 'engine', '', '', 50, 0)"
        )
        conn.commit()
        conn.close()
        return tmp, path

    def test_cut_pool_prioritizes_excess_role_nonland_noncommander_cards(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            named_land_pool_payload=named_land_pool(),
            core_role_payload=core_role_report(),
            sqlite_db=path,
            limit=5,
        )

        [pool] = payload["deck_cut_pools"]
        names = [row["card_name"] for row in pool["top_cut_candidates"]]
        self.assertFalse(payload["mutation_allowed"])
        self.assertIn("Expensive Engine", names)
        self.assertNotIn("Test Commander", names)
        self.assertNotIn("Ancient Tomb", names)
        self.assertNotIn("Pure Draw", names)
        package = next(row for row in pool["top_cut_candidates"] if row["card_name"] == "Package Exception")
        self.assertIn("printed_deck_construction_exception_requires_source_lane", package["cut_reasons"])
        self.assertLess(package["score"], next(row for row in pool["top_cut_candidates"] if row["card_name"] == "Expensive Engine")["score"])
        topdeck = next(row for row in pool["top_cut_candidates"] if row["card_name"] == "Topdeck Engine")
        self.assertIn("potential_topdeck_engine_anchor_requires_commander_source_lane", topdeck["cut_reasons"])
        self.assertEqual(pool["status"], "review_cut_pool_ready")
        self.assertTrue(pool["pair_hypotheses"])

    def test_cards_carrying_missing_core_roles_are_blocked(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            named_land_pool_payload=named_land_pool(),
            core_role_payload=core_role_report(missing_roles=["land", "removal"], excess_roles=["engine"]),
            sqlite_db=path,
            limit=5,
        )

        [pool] = payload["deck_cut_pools"]
        names = [row["card_name"] for row in pool["top_cut_candidates"]]
        blocked = [row["card_name"] for row in pool["blocked_cut_examples"]]
        self.assertNotIn("Removal Engine", names)
        self.assertIn("Removal Engine", blocked)

    def test_no_excess_roles_routes_to_source_lane(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            named_land_pool_payload=named_land_pool(),
            core_role_payload=core_role_report(excess_roles=[]),
            sqlite_db=path,
            limit=5,
        )

        [pool] = payload["deck_cut_pools"]
        self.assertEqual(pool["cut_candidate_count"], 0)
        self.assertEqual(pool["status"], "needs_commander_specific_cut_source_lane")
        self.assertEqual(pool["pair_hypotheses"], [])


if __name__ == "__main__":
    unittest.main()
