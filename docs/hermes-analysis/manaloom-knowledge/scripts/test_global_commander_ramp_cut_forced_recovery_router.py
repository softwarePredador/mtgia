#!/usr/bin/env python3
"""Tests for ramp cut forced recovery routing."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_cut_forced_recovery_router as router


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
              card_name TEXT NOT NULL,
              is_commander INTEGER DEFAULT 0,
              type_line TEXT,
              oracle_text TEXT
            );
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL
            );
            CREATE TABLE format_staples (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              edhrec_rank INTEGER
            );
            """
        )
        oracle_rows = [
            (
                "arcane signet",
                "Arcane Signet",
                "Artifact",
                "{T}: Add one mana of any color in your commander's color identity.",
                2,
            ),
            (
                "fellwar stone",
                "Fellwar Stone",
                "Artifact",
                "{T}: Add one mana of any color that a land an opponent controls could produce.",
                2,
            ),
            (
                "ornithopter of paradise",
                "Ornithopter of Paradise",
                "Artifact Creature — Thopter",
                "Flying {T}: Add one mana of any color.",
                2,
            ),
            (
                "sol ring",
                "Sol Ring",
                "Artifact",
                "{T}: Add {C}{C}.",
                1,
            ),
        ]
        conn.executemany(
            "INSERT INTO card_oracle_cache(normalized_name, name, type_line, oracle_text, cmc) VALUES (?, ?, ?, ?, ?)",
            oracle_rows,
        )
        conn.executemany(
            "INSERT INTO deck_cards(deck_id, card_name, is_commander) VALUES (619, ?, 0)",
            [("Arcane Signet",), ("Ornithopter of Paradise",), ("Sol Ring",)],
        )
        conn.executemany(
            "INSERT INTO format_staples(card_name, format, edhrec_rank) VALUES (?, 'commander', ?)",
            [("Arcane Signet", 3), ("Fellwar Stone", 18), ("Ornithopter of Paradise", 227), ("Sol Ring", 1)],
        )


def ramp_trace_payload(db_path: Path) -> dict[str, object]:
    return {
        "deck_id": "619",
        "commander": "Kaalia of the Vast",
        "input_artifacts": {"source_db": str(db_path)},
        "trace_review_rows": [
            {
                "card_name": "Arcane Signet",
                "status": "ramp_cut_natural_trace_usage_observed_blocks_cut",
                "usage_event_count": 3,
            }
        ],
        "structured_review_rows": [],
        "replacement_candidate_rows": [
            {
                "card_name": "Fellwar Stone",
                "status": "same_lane_ramp_candidate_needs_source_trace_review",
                "edhrec_rank": 18,
            }
        ],
        "replacement_reviews": [
            {
                "cut_card": "Arcane Signet",
                "status": "ramp_replacement_candidates_found_needs_source_trace_review",
            }
        ],
        "seed_rows": [],
    }


def forced_payload() -> dict[str, object]:
    return {
        "deck_id": "619",
        "commander": "Kaalia of the Vast",
        "review_rows": [],
    }


class GlobalCommanderRampCutForcedRecoveryRouterTests(unittest.TestCase):
    def test_routes_to_alternative_trace_when_replacement_downgrades_used_staple(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            ramp_trace = write_json(root, "ramp_trace.json", ramp_trace_payload(db_path))
            forced = write_json(root, "forced.json", forced_payload())

            report = router.build_report(
                ramp_trace_report=ramp_trace,
                forced_access_report=forced,
            )

        self.assertEqual(report["status"], "ramp_cut_forced_recovery_routes_alternative_cut_trace")
        self.assertEqual(report["summary"]["replacement_exact_ready_count"], 0)
        self.assertEqual(report["summary"]["alternative_trace_required_count"], 1)
        exact_statuses = {row["status"] for row in report["replacement_exactness_rows"]}
        self.assertIn("replacement_blocked_lower_staple_rank_than_used_cut", exact_statuses)
        alt_names = [
            row["card_name"]
            for row in report["alternative_cut_rows"]
            if row["status"] == "alternative_cut_needs_current_scope_trace"
        ]
        self.assertEqual(alt_names, ["Ornithopter of Paradise"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn("candidate_copy_closed_after_ramp_forced_recovery_router", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
