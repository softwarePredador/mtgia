#!/usr/bin/env python3
"""Tests for exact engine replacement or new cut finder."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_engine_exact_replacement_or_new_cut_finder as finder


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
              status TEXT NOT NULL,
              scryfall_id TEXT,
              synced_at TEXT DEFAULT ''
            );
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY,
              deck_id INTEGER,
              card_name TEXT NOT NULL
            );
            CREATE TABLE format_staples (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              archetype TEXT DEFAULT '',
              category TEXT DEFAULT '',
              color_identity TEXT,
              edhrec_rank INTEGER,
              scryfall_id TEXT,
              is_banned INTEGER DEFAULT 0
            );
            """
        )
        oracle_rows = [
            (
                "exact engine",
                "Exact Engine",
                '["B"]',
                "Enchantment",
                "Whenever you cast an artifact spell, create a 1/1 artifact creature token.",
            ),
            (
                "blue engine",
                "Blue Engine",
                '["U"]',
                "Creature",
                "Whenever you cast an artifact spell, draw a card.",
            ),
            (
                "support reducer",
                "Support Reducer",
                '[]',
                "Artifact Creature",
                "Artifact spells you cast cost {1} less to cast.",
            ),
            (
                "current exact",
                "Current Exact",
                '["B"]',
                "Enchantment",
                "Creatures you control are artifacts in addition to their other types.",
            ),
            (
                "not artifact conversion",
                "Not Artifact Conversion",
                '["B"]',
                "Enchantment",
                "As this enters, choose a creature type. Creature spells you control are the chosen type.",
            ),
        ]
        conn.executemany(
            "INSERT INTO card_oracle_cache(normalized_name, name, color_identity_json, type_line, oracle_text) VALUES (?, ?, ?, ?, ?)",
            oracle_rows,
        )
        conn.executemany(
            "INSERT INTO card_legalities(card_name, format, status) VALUES (?, 'commander', 'legal')",
            [("Exact Engine",), ("Blue Engine",), ("Support Reducer",), ("Current Exact",)],
        )
        conn.executemany(
            "INSERT INTO format_staples(card_name, format, edhrec_rank) VALUES (?, 'commander', ?)",
            [
                ("Exact Engine", 10),
                ("Blue Engine", 20),
                ("Support Reducer", 30),
                ("Current Exact", 40),
                ("Not Artifact Conversion", 50),
            ],
        )
        conn.execute("INSERT INTO deck_cards(deck_id, card_name) VALUES (619, 'Current Exact')")


def engine_policy_payload(db_path: Path) -> dict[str, object]:
    return {
        "source_db": str(db_path),
        "pool_policy_rows": [
            {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "policy_cut_rows": [
                    {
                        "card_name": "Biotransference",
                        "roles": ["engine"],
                        "cut_pressure_ready": True,
                        "policy_status": "engine_axis_policy_review_cut_pressure_ready",
                        "policy_bucket": "engine_only_excess_cut_pressure",
                    },
                    {
                        "card_name": "Maskwood Nexus",
                        "roles": ["engine"],
                        "cut_pressure_ready": False,
                        "policy_status": "engine_axis_policy_blocks_cut_until_source_lane_review",
                        "policy_bucket": "protected_engine_cut_pressure",
                        "commander_plan_signals": ["kaalia_trigger_or_type_enabler"],
                        "policy_blockers": ["engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler"],
                    },
                ],
            }
        ],
    }


class GlobalCommanderEngineExactReplacementOrNewCutFinderTests(unittest.TestCase):
    def test_finds_only_legal_color_allowed_not_in_deck_exact_replacements(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            rows = finder.replacement_rows(db_path, "619", limit=10)

        by_name = {row["card_name"]: row for row in rows}
        self.assertEqual(
            by_name["Exact Engine"]["status"],
            "exact_replacement_candidate_ready_for_source_trace",
        )
        self.assertIn("outside_commander_color_identity", by_name["Blue Engine"]["blockers"])
        self.assertIn("support_only_no_token_or_draw_payoff", by_name["Support Reducer"]["blockers"])
        self.assertIn("already_in_current_deck", by_name["Current Exact"]["blockers"])
        self.assertNotIn("Not Artifact Conversion", by_name)

    def test_report_keeps_candidate_copy_closed_and_surfaces_cut_blockers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            reviewer = write_json(root, "reviewer.json", {"status": "review_blocks"})
            policy = write_json(root, "policy.json", engine_policy_payload(db_path))
            report = finder.build_report(reviewer_report=reviewer, engine_policy_report=policy)

        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["exact_replacement_ready_count"], 1)
        cut_rows = {row["card_name"]: row for row in report["new_engine_cut_rows"]}
        self.assertEqual(
            cut_rows["Maskwood Nexus"]["status"],
            "new_engine_cut_blocked_by_commander_plan_signal",
        )


if __name__ == "__main__":
    unittest.main()
