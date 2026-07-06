#!/usr/bin/env python3
"""Tests for same-lane new cut source mining."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_new_cut_source_miner as miner


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


def cut_pair_report(root: Path, rows: list[dict[str, object]] | None = None) -> Path:
    return write_json(
        root,
        "cut_pair.json",
        {
            "summary": {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "required_pair_count_by_role": {"mana_acceleration": 1},
            },
            "input_artifacts": {},
            "stage_only_cut_candidates": rows or [],
            "blocked_cut_candidates": [],
            "ready_cut_candidates": [],
        },
    )


def package_report(root: Path, roles: list[str] | None = None) -> Path:
    selected = []
    for role in roles or ["mana_acceleration"]:
        selected.append(
            {
                "card_name": f"Add for {role}",
                "replaces_cut_role": role,
                "score": 100,
            }
        )
    return write_json(
        root,
        "package.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "selected_add_package": selected,
        },
    )


class GlobalCommanderSameLaneNewCutSourceMinerTests(unittest.TestCase):
    def test_fresh_same_lane_source_routes_to_trace_collection(self) -> None:
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
            recovery_report=recovery_report(root),
            trace_collector_report=trace_report(root),
            cut_pair_report=cut_pair_report(root),
            package_source_report=package_report(root),
            sqlite_db=db,
        )

        self.assertEqual(report["status"], "same_lane_new_cut_source_hypotheses_ready_for_trace")
        self.assertEqual(report["summary"]["fresh_same_lane_cut_source_count"], 1)
        self.assertEqual(
            report["fresh_same_lane_cut_sources"][0]["status"],
            "fresh_same_lane_cut_source_needs_trace",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_consumed_stage_cut_is_not_recycled_as_fresh(self) -> None:
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
            "stage_reasons": ["contextual_staple_requires_stage_review"],
        }

        report = miner.build_report(
            recovery_report=recovery_report(root),
            trace_collector_report=trace_report(root, [consumed]),
            cut_pair_report=cut_pair_report(root, [consumed]),
            package_source_report=package_report(root),
            sqlite_db=db,
        )

        self.assertEqual(report["summary"]["fresh_same_lane_cut_source_count"], 0)
        self.assertEqual(report["summary"]["blocked_recycled_cut_source_count"], 1)
        self.assertIn(
            "used_stage_cut_source",
            report["blocked_recycled_cut_sources"][0]["exclusion_categories"],
        )
        self.assertEqual(report["status"], "same_lane_new_cut_source_mining_exhausted_current_deck")

    def test_payoff_overlap_is_blocked_and_routes_to_broaden_axis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = make_db(
            root,
            [
                {
                    "card_name": "Treasure Dragon",
                    "functional_tag": "ramp",
                    "type_line": "Creature - Dragon",
                    "oracle_text": "Whenever this creature attacks, create a Treasure token.",
                    "cmc": 6,
                }
            ],
        )

        report = miner.build_report(
            recovery_report=recovery_report(root),
            trace_collector_report=trace_report(root),
            cut_pair_report=cut_pair_report(root),
            package_source_report=package_report(root),
            sqlite_db=db,
        )

        self.assertEqual(report["status"], "same_lane_new_cut_source_mining_exhausted_current_deck")
        self.assertEqual(report["summary"]["fresh_same_lane_cut_source_count"], 0)
        self.assertEqual(report["summary"]["blocked_new_cut_source_count"], 1)
        self.assertIn(
            "commander_payoff_slot_protected",
            report["blocked_new_cut_sources"][0]["block_reasons"],
        )
        self.assertEqual(
            report["summary"]["next_gate"],
            "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
        )


if __name__ == "__main__":
    unittest.main()
