#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


def _load_module():
    path = Path(__file__).resolve().parents[1] / "bin" / "native_battle_worker.py"
    spec = importlib.util.spec_from_file_location("native_battle_worker_tested", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class NativeBattleWorkerTest(unittest.TestCase):
    def test_runtime_max_turns_reads_worker_environment(self) -> None:
        module = _load_module()
        with mock.patch.dict(os.environ, {"MANALOOM_BATTLE_MAX_TURNS": "9"}):
            self.assertEqual(module.battle.battle_runtime_max_turns(), 9)

    def test_simulation_opens_knowledge_db_with_named_rows(self) -> None:
        module = _load_module()
        commander = {"name": "Commander", "color_identity": []}
        report = {"is_valid": True, "issues": []}
        calls = 0

        def build_deck(connection, payload, deck_key):
            nonlocal calls
            self.assertIs(connection.row_factory, sqlite3.Row)
            calls += 1
            return (
                {"id": deck_key, "name": deck_key},
                dict(commander),
                [{"name": f"Card {deck_key}", "type_line": "Creature"}],
                report,
            )

        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "knowledge.db"
            sqlite3.connect(db).close()
            with (
                mock.patch.dict(os.environ, {"MANALOOM_KNOWLEDGE_DB": str(db)}),
                mock.patch.object(module, "_build_deck", side_effect=build_deck),
                mock.patch.object(
                    module.battle,
                    "target_player_name_for_commander",
                    return_value="Deck A",
                ),
                mock.patch.object(
                    module.battle,
                    "simulate_game_v8",
                    return_value=("win", 3, "test"),
                ),
            ):
                result = module.simulate(
                    {
                        "deck_a": {},
                        "deck_b": {},
                        "seed": 7,
                        "max_turns": 7,
                        "force_focus_access_mode": "opening_hand",
                    }
                )

        self.assertEqual(calls, 2)
        self.assertEqual(result["status"], "completed")
        self.assertEqual(result["engine_contract"], "native_reviewed_rules_execution")
        self.assertEqual(result["forced_access_mode"], "none")
        self.assertEqual(result["max_turns"], 7)
        self.assertFalse(result["learning_contract"]["forced_access_diagnostic"])


if __name__ == "__main__":
    unittest.main()
