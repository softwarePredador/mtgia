#!/usr/bin/env python3
"""Tests for external exact artifact engine add/cut pair model."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_exact_artifact_engine_add_cut_pair_model as model


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
              type_line TEXT,
              oracle_text TEXT
            );
            """
        )
        conn.execute(
            "INSERT INTO card_oracle_cache(normalized_name, name, type_line, oracle_text) VALUES (?, ?, ?, ?)",
            (
                "biotransference",
                "Biotransference",
                "Enchantment",
                "Creatures you control are artifacts in addition to their other types. Whenever you cast an artifact spell, create a token.",
            ),
        )


def candidate_reviewer_payload(db_path: Path) -> dict[str, object]:
    return {
        "input_artifacts": {"source_db": str(db_path)},
        "reviewed_candidate_rows": [
            {
                "card_name": "Digsite Engineer",
                "status": "local_external_exact_engine_candidate_ready_for_add_cut_review",
                "local_signals": ["artifact_spell_token_payoff"],
                "local_exact_status": "exact_artifact_spell_payoff_candidate",
            },
            {
                "card_name": "Exact Clone",
                "status": "local_external_exact_engine_candidate_ready_for_add_cut_review",
                "local_signals": ["artifact_spell_token_payoff", "artifact_type_conversion_engine"],
                "local_exact_status": "exact_type_conversion_engine_candidate",
            },
        ],
    }


def finder_payload(db_path: Path) -> dict[str, object]:
    return {
        "input_artifacts": {"source_db": str(db_path)},
        "new_engine_cut_rows": [
            {
                "card_name": "Biotransference",
                "status": "already_reviewed_engine_cut_not_new_source",
                "policy_bucket": "engine_only_excess_cut_pressure",
            }
        ],
    }


class GlobalCommanderExternalExactArtifactEngineAddCutPairModelTests(unittest.TestCase):
    def test_requires_type_conversion_signal_to_replace_biotransference(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            candidate_report = write_json(root, "candidate.json", candidate_reviewer_payload(db_path))
            finder_report = write_json(root, "finder.json", finder_payload(db_path))
            report = model.build_report(
                candidate_reviewer_report=candidate_report,
                finder_report=finder_report,
            )

        by_add = {row["add_card"]: row for row in report["pair_rows"]}
        self.assertEqual(
            by_add["Digsite Engineer"]["status"],
            "add_cut_pair_blocked_by_same_lane_signal_gap",
        )
        self.assertIn("artifact_type_conversion_engine", by_add["Digsite Engineer"]["missing_signals"])
        self.assertEqual(by_add["Exact Clone"]["status"], "add_cut_pair_ready_for_source_trace")
        self.assertEqual(report["summary"]["ready_for_source_trace_pair_count"], 1)
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
