#!/usr/bin/env python3
"""Tests for global Commander nonland core candidate model."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_nonland_core_candidate_model as audit


def removal_hypothesis() -> dict:
    return {
        "deck_id": "619",
        "deck_name": "Kaalia Variant",
        "commander": "Kaalia of the Vast",
        "scope": "hermes_registered_variant",
        "role": "removal",
        "missing": 5,
        "current_count": 1,
        "target_min": 6,
        "review_candidates": [
            {"card_name": "Swords to Plowshares", "source": "format_staples", "color_identity": "W", "edhrec_rank": 11},
            {"card_name": "Path to Exile", "source": "format_staples", "color_identity": "W", "edhrec_rank": 15},
            {"card_name": "Bojuka Bog", "source": "format_staples", "color_identity": "B", "edhrec_rank": 27},
            {"card_name": "Pongify", "source": "format_staples", "color_identity": "U", "edhrec_rank": 160},
        ],
    }


def wincon_hypothesis() -> dict:
    return {
        "deck_id": "620",
        "deck_name": "Sauron Variant",
        "commander": "Sauron, the Dark Lord",
        "scope": "hermes_registered_variant",
        "role": "wincon",
        "missing": 3,
        "current_count": 0,
        "target_min": 3,
        "review_candidates": [],
    }


def core_role_payload() -> dict:
    return {
        "decks": [
            {
                "deck_id": "619",
                "core_repair_plan": {
                    "missing_role_slots": [{"role": "removal", "missing": 5, "severity": "critical"}],
                    "excess_role_slots": [{"role": "engine", "count": 30, "target_max": 24, "excess": 6, "severity": "support"}],
                },
            },
            {
                "deck_id": "620",
                "core_repair_plan": {
                    "missing_role_slots": [{"role": "wincon", "missing": 3, "severity": "critical"}],
                    "excess_role_slots": [{"role": "engine", "count": 31, "target_max": 24, "excess": 7, "severity": "support"}],
                },
            },
        ]
    }


class GlobalCommanderNonlandCoreCandidateModelTests(unittest.TestCase):
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
        conn.execute(
            """
            CREATE TABLE learned_decks (
              id INTEGER,
              source TEXT,
              commander TEXT,
              deck_name TEXT,
              archetype TEXT,
              card_count INTEGER,
              wincon_primary TEXT,
              wincon_backup TEXT
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
                ("619", "Kaalia of the Vast", 1, "engine", "[]", 1, 4, "Legendary Creature", "Flying", "kaalia"),
                ("619", "Path to Exile", 1, "removal", '["removal"]', 0, 1, "Instant", "Exile target creature.", "path"),
                ("619", "Excess Engine", 1, "engine", '["engine"]', 0, 5, "Artifact", "Whenever you cast a spell, draw a card.", "engine"),
                ("620", "Sauron, the Dark Lord", 1, "engine", "[]", 1, 6, "Legendary Creature", "Whenever the Ring tempts you, draw cards.", "sauron"),
            ],
        )
        conn.executemany(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                ("Kaalia of the Vast", "kaalia of the vast", "{1}{R}{W}{B}", '["B","R","W"]', '["B","R","W"]', "Legendary Creature", "", 4, "", "kaalia"),
                ("Sauron, the Dark Lord", "sauron the dark lord", "{3}{U}{B}{R}", '["B","R","U"]', '["B","R","U"]', "Legendary Creature", "", 6, "", "sauron"),
                ("Swords to Plowshares", "swords to plowshares", "{W}", '["W"]', '["W"]', "Instant", "Exile target creature. Its controller gains life.", 1, "", "swords"),
                ("Path to Exile", "path to exile", "{W}", '["W"]', '["W"]', "Instant", "Exile target creature.", 1, "", "path"),
                ("Bojuka Bog", "bojuka bog", "", "[]", '["B"]', "Land", "When this land enters, exile target player's graveyard.", 0, "", "bog"),
                ("Pongify", "pongify", "{U}", '["U"]', '["U"]', "Instant", "Destroy target creature.", 1, "", "pongify"),
                ("Anguished Unmaking", "anguished unmaking", "{1}{W}{B}", '["B","W"]', '["B","W"]', "Instant", "Exile target nonland permanent. You lose 3 life.", 3, "", "anguished"),
                ("Terminate", "terminate", "{B}{R}", '["B","R"]', '["B","R"]', "Instant", "Destroy target creature. It can't be regenerated.", 2, "", "terminate"),
                ("Cloudshift", "cloudshift", "{W}", '["W"]', '["W"]', "Instant", "Exile target creature you control, then return that card to the battlefield under your control.", 1, "", "cloudshift"),
            ],
        )
        conn.executemany(
            "INSERT INTO card_legalities VALUES (?, 'commander', ?, '', '')",
            [
                ("Swords to Plowshares", "legal"),
                ("Path to Exile", "legal"),
                ("Bojuka Bog", "legal"),
                ("Pongify", "legal"),
                ("Anguished Unmaking", "legal"),
                ("Terminate", "legal"),
                ("Cloudshift", "legal"),
            ],
        )
        conn.executemany(
            "INSERT INTO format_staples VALUES (?, 'commander', ?, ?, ?, ?, 0)",
            [
                ("Anguished Unmaking", "removal", "", "B,W", 156),
                ("Terminate", "removal", "", "B,R", 222),
                ("Cloudshift", "removal", "", "W", 819),
            ],
        )
        conn.execute(
            "INSERT INTO learned_decks VALUES (45, 'pg_meta_decks', 'Sauron, Lord of the Rings', 'Sauron', 'tribal', 100, NULL, NULL)"
        )
        conn.commit()
        conn.close()
        return tmp, path

    def test_removal_pool_expands_staples_and_filters_invalid_candidates(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            repair_payload={"hypotheses": [removal_hypothesis()]},
            core_role_payload=core_role_payload(),
            sqlite_db=path,
            limit=5,
        )

        [pool] = payload["nonland_pools"]
        candidate_names = [row["card_name"] for row in pool["top_candidates"]]
        self.assertFalse(payload["mutation_allowed"])
        self.assertEqual(pool["status"], "review_nonland_add_cut_pool_ready")
        self.assertEqual(candidate_names[0], "Swords to Plowshares")
        self.assertIn("Anguished Unmaking", candidate_names)
        self.assertIn("Terminate", candidate_names)
        self.assertNotIn("Path to Exile", candidate_names)
        self.assertNotIn("Bojuka Bog", candidate_names)
        self.assertNotIn("Pongify", candidate_names)
        self.assertNotIn("Cloudshift", candidate_names)
        self.assertEqual(pool["top_cut_candidates"][0]["card_name"], "Excess Engine")
        self.assertTrue(pool["pair_hypotheses"])

    def test_wincon_remains_source_lane_only_with_related_source(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            repair_payload={"hypotheses": [wincon_hypothesis()]},
            core_role_payload=core_role_payload(),
            sqlite_db=path,
            limit=5,
        )

        [pool] = payload["nonland_pools"]
        self.assertEqual(pool["status"], "needs_commander_specific_source_lane")
        self.assertEqual(pool["candidate_count"], 0)
        self.assertEqual(pool["pair_hypotheses"], [])
        self.assertEqual(pool["related_source_lanes"][0]["commander"], "Sauron, Lord of the Rings")


if __name__ == "__main__":
    unittest.main()
