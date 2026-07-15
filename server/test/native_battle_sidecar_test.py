#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from contextlib import closing
from pathlib import Path
from unittest import mock


def _load_module():
    path = Path(__file__).resolve().parents[1] / "bin" / "native_battle_sidecar.py"
    spec = importlib.util.spec_from_file_location("native_battle_sidecar_tested", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _create_db(path: Path) -> None:
    with closing(sqlite3.connect(path)) as connection:
        connection.execute(
            """
            CREATE TABLE battle_card_rules (
              normalized_name TEXT NOT NULL,
              logical_rule_key TEXT NOT NULL,
              card_name TEXT NOT NULL,
              review_status TEXT NOT NULL,
              execution_status TEXT NOT NULL,
              oracle_hash TEXT,
              effect_json TEXT
            )
            """
        )
        connection.execute(
            """
            INSERT INTO battle_card_rules VALUES (
              'aerialephant', 'battle_rule_v1:test', 'Aerialephant',
              'verified', 'auto', 'oracle-hash', '{"effect":"creature"}'
            )
            """
        )
        connection.execute(
            """
            INSERT INTO battle_card_rules VALUES (
              'birgi, god of storytelling', 'battle_rule_v1:birgi',
              'Birgi, God of Storytelling', 'verified', 'auto', 'birgi-hash',
              '{"effect":"triggered_mana"}'
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE card_oracle_cache (
              normalized_name TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              type_line TEXT
            )
            """
        )
        connection.execute(
            """
            INSERT INTO card_oracle_cache VALUES (
              'plains // plains', 'Plains // Plains', 'Basic Land - Plains'
            )
            """
        )
        connection.commit()


class NativeBattleSidecarTest(unittest.TestCase):
    def test_coverage_requires_verified_executable_rule_and_hash(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            _create_db(db)
            report = module.card_coverage(
                {"cards": [{"name": "Aerialephant"}, {"name": "Missing"}]},
                db_path=db,
            )
        self.assertEqual(report["supported"], 1)
        self.assertEqual(report["unsupported"], 1)
        self.assertEqual(
            report["unsupported_cards"][0]["reason"],
            "verified_native_rule_missing",
        )

    def test_coverage_rejects_empty_or_invalid_effect_payloads(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            _create_db(db)
            with closing(sqlite3.connect(db)) as connection:
                connection.executemany(
                    "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?, ?, ?)",
                    [
                        (
                            "empty rule",
                            "battle_rule_v1:empty",
                            "Empty Rule",
                            "verified",
                            "auto",
                            "hash-empty",
                            "{}",
                        ),
                        (
                            "invalid rule",
                            "battle_rule_v1:invalid",
                            "Invalid Rule",
                            "verified",
                            "auto",
                            "hash-invalid",
                            "not-json",
                        ),
                    ],
                )
                connection.commit()
            report = module.card_coverage(
                {"cards": [{"name": "Empty Rule"}, {"name": "Invalid Rule"}]},
                db_path=db,
            )
        self.assertEqual(report["supported"], 0)
        self.assertEqual(report["unsupported"], 2)

    def test_coverage_accepts_front_face_rule_and_intrinsic_basic_land(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            _create_db(db)
            report = module.card_coverage(
                {
                    "cards": [
                        {"name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty"},
                        {"name": "Plains // Plains"},
                    ]
                },
                db_path=db,
            )
        self.assertEqual(report["supported"], 2)
        self.assertEqual(report["unsupported"], 0)
        by_name = {row["name"]: row for row in report["supported_rules"]}
        self.assertEqual(
            by_name["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]["matched_normalized_name"],
            "birgi, god of storytelling",
        )
        self.assertEqual(
            by_name["Plains // Plains"]["support_kind"],
            "intrinsic_basic_land",
        )

    def test_simulation_refuses_uncovered_required_rules_before_worker(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            _create_db(db)
            with mock.patch.object(module.subprocess, "run") as run:
                status, body = module._run_simulation(
                    {"required_rule_cards": [{"name": "Missing"}]},
                    db_path=db,
                )
        self.assertEqual(status, 422)
        self.assertEqual(body["error"], "native_coverage_incomplete")
        run.assert_not_called()

    def test_simulation_attaches_exact_native_rule_provenance(self) -> None:
        module = _load_module()
        worker_result = {
            "status": "completed",
            "engine": "manaloom_native_reviewed",
            "engine_contract": "native_reviewed_rules_execution",
            "winner": "Deck A",
        }
        completed = subprocess.CompletedProcess(
            args=["python"],
            returncode=0,
            stdout=json.dumps(worker_result),
            stderr="",
        )
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            _create_db(db)
            with mock.patch.object(module.subprocess, "run", return_value=completed):
                status, body = module._run_simulation(
                    {
                        "required_rule_cards": [{"name": "Aerialephant"}],
                        "timeout_ms": 1000,
                    },
                    db_path=db,
                )
        self.assertEqual(status, 200)
        self.assertEqual(body["native_rule_coverage"]["supported"], 1)
        self.assertEqual(
            body["native_rule_coverage"]["supported_rules"][0]["logical_rule_keys"],
            ["battle_rule_v1:test"],
        )


if __name__ == "__main__":
    unittest.main()
