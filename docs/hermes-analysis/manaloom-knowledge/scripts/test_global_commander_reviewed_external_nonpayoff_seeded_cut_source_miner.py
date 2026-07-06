#!/usr/bin/env python3
"""Tests for reviewed external nonpayoff seeded cut-source mining."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner as miner


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def make_db(root: Path, rows: list[dict[str, object]]) -> Path:
    db = root / "knowledge.db"
    conn = sqlite3.connect(db)
    try:
        conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id TEXT,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                functional_tags_json TEXT,
                type_line TEXT,
                oracle_text TEXT,
                cmc REAL,
                is_commander INTEGER
            )
            """
        )
        for row in rows:
            conn.execute(
                """
                INSERT INTO deck_cards (
                    deck_id, card_name, quantity, functional_tag,
                    functional_tags_json, type_line, oracle_text, cmc,
                    is_commander
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "619",
                    row["card_name"],
                    row.get("quantity", 1),
                    row.get("functional_tag"),
                    row.get("functional_tags_json"),
                    row.get("type_line", ""),
                    row.get("oracle_text", ""),
                    row.get("cmc", 0),
                    row.get("is_commander", 0),
                ),
            )
        conn.commit()
    finally:
        conn.close()
    return db


def reviewer_report(root: Path, roles: list[str] | None = None) -> Path:
    return write_json(
        root,
        "reviewer.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "miner_source_seed_rows": [
                {
                    "card_name": f"Seed for {role}",
                    "target_cut_role": role,
                    "miner_source_seed_allowed": True,
                }
                for role in (roles or ["mana_acceleration"])
            ],
        },
    )


def recovery_report(root: Path, roles: dict[str, int] | None = None) -> Path:
    return write_json(
        root,
        "recovery.json",
        {
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "target_role_counts": roles or {"mana_acceleration": 1},
            },
            "used_cut_recovery_rows": [],
        },
    )


def trace_report(root: Path, rows: list[dict[str, object]] | None = None) -> Path:
    return write_json(
        root,
        "trace.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "review_rows": rows or [],
        },
    )


def cut_pair_report(root: Path, roles: dict[str, int] | None = None, rows: list[dict[str, object]] | None = None) -> Path:
    return write_json(
        root,
        "cut_pair.json",
        {
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "required_pair_count_by_role": roles or {"mana_acceleration": 1},
            },
            "input_artifacts": {},
            "stage_only_cut_candidates": rows or [],
            "blocked_cut_candidates": [],
            "ready_cut_candidates": [],
        },
    )


def package_report(root: Path, roles: list[str] | None = None) -> Path:
    return write_json(
        root,
        "package.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "selected_add_package": [
                {"card_name": f"Add for {role}", "replaces_cut_role": role}
                for role in (roles or ["mana_acceleration"])
            ],
        },
    )


class GlobalCommanderReviewedExternalNonpayoffSeededCutSourceMinerTests(unittest.TestCase):
    def test_seeded_fresh_source_routes_to_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = make_db(
            root,
            [
                {
                    "card_name": "Fresh Mana Rock",
                    "functional_tag": "ramp",
                    "type_line": "Artifact",
                    "oracle_text": "{T}: Add one mana of any color.",
                    "cmc": 3,
                }
            ],
        )

        report = miner.build_report(
            reviewer_report=reviewer_report(root),
            recovery_report=recovery_report(root),
            trace_collector_report=trace_report(root),
            cut_pair_report=cut_pair_report(root),
            package_source_report=package_report(root),
            sqlite_db=db,
        )

        self.assertEqual(report["status"], "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace")
        self.assertEqual(report["summary"]["reviewed_seed_count"], 1)
        self.assertEqual(report["summary"]["fresh_seeded_same_lane_cut_source_count"], 1)
        self.assertEqual(report["role_diagnostics"][0]["status"], "reviewed_external_seeded_role_has_fresh_cut_source_needs_trace")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_recycled_source_stays_blocked_despite_seed(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = make_db(
            root,
            [
                {
                    "card_name": "Used Mana Rock",
                    "functional_tag": "ramp",
                    "type_line": "Artifact",
                    "oracle_text": "{T}: Add one mana of any color.",
                    "cmc": 3,
                }
            ],
        )
        consumed = {
            "card_name": "Used Mana Rock",
            "target_cut_role": "mana_acceleration",
            "status": "same_lane_stage_cut_usage_trace_blocks_value_safe",
        }

        report = miner.build_report(
            reviewer_report=reviewer_report(root),
            recovery_report=recovery_report(root),
            trace_collector_report=trace_report(root, [consumed]),
            cut_pair_report=cut_pair_report(root, rows=[consumed]),
            package_source_report=package_report(root),
            sqlite_db=db,
        )

        self.assertEqual(
            report["status"],
            "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
        )
        self.assertEqual(report["summary"]["fresh_seeded_same_lane_cut_source_count"], 0)
        self.assertEqual(report["summary"]["blocked_recycled_seeded_cut_source_count"], 1)
        self.assertIn("reviewed_external_seeds_found_no_fresh_current_deck_cut_source", report["candidate_copy_blockers"])
        self.assertFalse(report["battle_gate_allowed_now"])

    def test_unseeded_target_role_remains_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = make_db(root, [])

        report = miner.build_report(
            reviewer_report=reviewer_report(root, ["mana_acceleration"]),
            recovery_report=recovery_report(root, {"mana_acceleration": 1, "tutors_access": 1}),
            trace_collector_report=trace_report(root),
            cut_pair_report=cut_pair_report(root, {"mana_acceleration": 1, "tutors_access": 1}),
            package_source_report=package_report(root, ["mana_acceleration", "tutors_access"]),
            sqlite_db=db,
        )

        self.assertEqual(report["summary"]["unseeded_target_role_count"], 1)
        self.assertIn("unseeded_target_roles_remain_blocked:tutors_access", report["candidate_copy_blockers"])
        statuses = {row["target_cut_role"]: row["status"] for row in report["role_diagnostics"]}
        self.assertEqual(statuses["tutors_access"], "reviewed_external_seed_missing_for_target_role")
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
