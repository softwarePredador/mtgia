#!/usr/bin/env python3
"""Tests for same-lane cut pair collection."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_cut_pair_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def create_db(root: Path, rows: list[tuple[str, str, str, float]]) -> Path:
    db_path = root / "knowledge.db"
    with sqlite3.connect(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              deck_id INTEGER,
              card_name TEXT NOT NULL,
              quantity INTEGER DEFAULT 1,
              functional_tag TEXT,
              functional_tags_json TEXT DEFAULT '[]',
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              is_commander INTEGER DEFAULT 0
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE format_staples (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              archetype TEXT NOT NULL DEFAULT '',
              category TEXT NOT NULL DEFAULT '',
              color_identity TEXT,
              edhrec_rank INTEGER,
              is_banned INTEGER DEFAULT 0
            )
            """
        )
        for name, type_line, oracle_text, cmc in rows:
            conn.execute(
                """
                INSERT INTO deck_cards(deck_id, card_name, type_line, oracle_text, cmc)
                VALUES(619, ?, ?, ?, ?)
                """,
                (name, type_line, oracle_text, cmc),
            )
    return db_path


def source_lane_report(root: Path, db_path: Path) -> Path:
    strategy = write_json(root, "strategy.json", {})
    profile = write_json(root, "profile.json", {"input_artifacts": {"strategy_matrix_report": str(strategy)}})
    return write_json(
        root,
        "source_lane.json",
        {
            "input_artifacts": {
                "selected_db": str(db_path),
                "profile_repair_report": str(profile),
            }
        },
    )


def package_report(root: Path, source_lane: Path, adds: list[dict[str, object]]) -> Path:
    return write_json(
        root,
        "package.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "input_artifacts": {"source_lane_report": str(source_lane)},
            "selected_add_package": adds,
            "source_lane_diagnostics": [
                {"cut_role": "mana_acceleration", "target_cut_count": 1},
                {"cut_role": "tutors_access", "target_cut_count": 1},
                {"cut_role": "haste_protection_silence", "target_cut_count": 1},
            ],
        },
    )


def add(name: str, role: str, score: int = 100) -> dict[str, object]:
    return {
        "card_name": name,
        "selected_for_axis": role + "_replacement",
        "replaces_cut_role": role,
        "score": score,
        "profile_roles": [role],
    }


class GlobalCommanderSameLaneCutPairCollectorTests(unittest.TestCase):
    def test_collects_exact_same_lane_pairs_without_opening_candidate_copy(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = create_db(
            root,
            [
                ("Slow Mana Rock", "Artifact", "{T}: Add one mana of any color.", 4),
                ("Expensive Tutor", "Sorcery", "Search your library for a card, put it into your hand.", 5),
                ("Decorative Creature", "Creature", "Vanilla text.", 2),
            ],
        )
        source = source_lane_report(root, db_path)
        package = package_report(
            root,
            source,
            [add("Fellwar Stone", "mana_acceleration", 120), add("Gamble", "tutors_access", 110)],
        )

        report = collector.build_report(package_source_report=package)

        self.assertEqual(report["status"], "same_lane_cut_pairs_ready_for_scope_reducer")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["ready_pair_count"], 2)
        self.assertEqual(report["summary"]["unpaired_add_count"], 0)
        pairs = {(row["add"], row["cut"], row["same_lane_role"]) for row in report["review_only_same_lane_pairs"]}
        self.assertIn(("Fellwar Stone", "Slow Mana Rock", "mana_acceleration"), pairs)
        self.assertIn(("Gamble", "Expensive Tutor", "tutors_access"), pairs)

    def test_protected_haste_lane_stays_stage_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = create_db(
            root,
            [
                ("Lightning Greaves", "Artifact - Equipment", "Equipped creature has haste and shroud.", 2),
            ],
        )
        with sqlite3.connect(db_path) as conn:
            conn.execute(
                """
                INSERT INTO format_staples(card_name, format, category, edhrec_rank)
                VALUES('Lightning Greaves', 'commander', 'protection', 25)
                """
            )
        source = source_lane_report(root, db_path)
        package = package_report(root, source, [add("Boros Charm", "haste_protection_silence", 130)])

        report = collector.build_report(package_source_report=package)

        self.assertEqual(report["status"], "same_lane_cut_pair_collection_blocks_candidate_copy")
        self.assertEqual(report["summary"]["ready_pair_count"], 0)
        self.assertEqual(report["summary"]["stage_only_cut_candidate_count"], 1)
        self.assertEqual(report["unpaired_adds"][0]["card_name"], "Boros Charm")
        reasons = report["stage_only_cut_candidates"][0]["stage_reasons"]
        self.assertIn("target_role_is_protected_profile_lane_requires_trace_or_equal_gate", reasons)
        self.assertIn("structural_foundation_staple_requires_same_lane_or_battle_proof", reasons)

    def test_blocks_when_no_same_lane_cut_exists(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = create_db(root, [("Decorative Creature", "Creature", "Vanilla text.", 2)])
        source = source_lane_report(root, db_path)
        package = package_report(root, source, [add("Gamble", "tutors_access", 110)])

        report = collector.build_report(package_source_report=package)

        self.assertEqual(report["status"], "same_lane_cut_pair_collection_blocks_candidate_copy")
        self.assertEqual(report["summary"]["ready_pair_count"], 0)
        self.assertEqual(report["summary"]["blocked_cut_candidate_count"], 0)
        self.assertEqual(report["summary"]["unpaired_add_count"], 1)
        self.assertIn("no_review_only_value_safe_same_lane_pairs", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
