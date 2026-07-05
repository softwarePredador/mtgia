#!/usr/bin/env python3
"""Tests for contextual Commander stage-cut evidence collection."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_contextual_stage_cut_evidence_collector as collector


def contextual_cut(name: str, roles: list[str]) -> dict[str, object]:
    return {
        "card_name": name,
        "score": 60,
        "matching_over_target_roles": roles,
        "profile_roles": roles,
        "stage_reasons": ["contextual_staple_requires_stage_review"],
        "evidence_lanes": ["contextual_staple_same_lane_usage_review"],
        "status": "stage_only_cut_needs_evidence_before_value_safe",
    }


def stage_plan(rows: list[dict[str, object]]) -> dict[str, object]:
    return {
        "status": "stage_only_cut_evidence_plan_ready",
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "required_cut_count": 6,
        },
        "input_artifacts": {"cut_source_lane_report": "missing_cut_source_lane.json"},
        "evidence_plan_rows": rows,
    }


class GlobalCommanderContextualStageCutEvidenceCollectorTests(unittest.TestCase):
    def _write_json(self, root: Path, payload: dict[str, object]) -> Path:
        path = root / "stage_plan.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def _db(self, root: Path) -> Path:
        db = root / "knowledge_candidate.db"
        with sqlite3.connect(db) as conn:
            conn.execute(
                """
                CREATE TABLE deck_cards (
                    deck_id INTEGER,
                    card_name TEXT NOT NULL,
                    quantity INTEGER DEFAULT 1,
                    functional_tag TEXT,
                    functional_tags_json TEXT DEFAULT '[]',
                    cmc REAL,
                    type_line TEXT,
                    oracle_text TEXT,
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
                    edhrec_rank INTEGER,
                    is_banned INTEGER DEFAULT 0
                )
                """
            )
            conn.executemany(
                """
                INSERT INTO deck_cards (
                    deck_id, card_name, quantity, functional_tags_json, cmc,
                    type_line, oracle_text, is_commander
                ) VALUES (619, ?, 1, '[]', ?, ?, ?, 0)
                """,
                [
                    (
                        "Professional Face-Breaker",
                        3.0,
                        "Creature - Human Warrior",
                        "Whenever one or more creatures you control deal combat damage to a player, create a Treasure token.",
                    ),
                    (
                        "Diabolic Intent",
                        2.0,
                        "Sorcery",
                        "As an additional cost to cast this spell, sacrifice a creature. Search your library for a card.",
                    ),
                    (
                        "Ornithopter of Paradise",
                        2.0,
                        "Artifact Creature - Thopter",
                        "Flying. Tap: Add one mana of any color.",
                    ),
                ],
            )
            conn.executemany(
                """
                INSERT INTO format_staples (
                    card_name, format, archetype, category, edhrec_rank, is_banned
                ) VALUES (?, 'commander', ?, '', ?, 0)
                """,
                [
                    ("Professional Face-Breaker", "red", 223),
                    ("Diabolic Intent", "black", 265),
                    ("Ornithopter of Paradise", "ramp", 227),
                ],
            )
        return db

    def test_collects_context_without_reclassifying_missing_usage_or_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._write_json(
            root,
            stage_plan(
                [
                    contextual_cut("Professional Face-Breaker", ["mana_acceleration"]),
                    contextual_cut("Diabolic Intent", ["tutors_access"]),
                    contextual_cut("Ornithopter of Paradise", ["mana_acceleration"]),
                    {
                        "card_name": "Dark Ritual",
                        "evidence_lanes": ["structural_staple_same_lane_or_equal_gate_proof"],
                    },
                ]
            ),
        )
        db = self._db(root)

        payload = collector.build_report(stage_only_plan_report=report, sqlite_db=db)

        self.assertEqual(
            payload["status"],
            "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
        )
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["contextual_row_count"], 3)
        self.assertEqual(payload["summary"]["reclassification_ready_count"], 0)
        self.assertEqual(payload["summary"]["missing_usage_or_trace_count"], 3)
        first = payload["contextual_evidence_rows"][0]
        self.assertEqual(first["card_name"], "Professional Face-Breaker")
        self.assertIn("usage_or_same_lane_or_replay_proof", first["missing_evidence"])
        self.assertEqual(first["format_staple_context"]["edhrec_rank"], 223)

    def test_blocks_when_no_contextual_stage_rows_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._write_json(
            root,
            stage_plan(
                [
                    {
                        "card_name": "Dark Ritual",
                        "evidence_lanes": ["structural_staple_same_lane_or_equal_gate_proof"],
                    }
                ]
            ),
        )

        payload = collector.build_report(stage_only_plan_report=report, sqlite_db=root / "missing.db")

        self.assertEqual(payload["status"], "contextual_stage_cut_evidence_blocks_no_contextual_rows")
        self.assertEqual(payload["summary"]["next_gate"], "find_new_stage_only_cut_evidence_lane")
        self.assertIn("no_contextual_stage_only_cut_rows_to_collect", payload["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
