#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle_module(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RuntimeCanonicalSnapshotFallbackTests(unittest.TestCase):
    def test_canonical_snapshot_is_only_runtime_json_fallback_when_registry_unavailable(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            canonical_path = tmp_path / "known_cards_canonical_snapshot.json"
            db_path = tmp_path / "missing_knowledge.db"

            canonical_path.write_text(
                json.dumps(
                    {
                        "Alpha Card": {
                            "effect": "counter",
                            "battle_rule_source": "manual",
                            "battle_rule_review_status": "verified",
                            "battle_rule_confidence": 1.0,
                            "battle_rule_version": 2,
                            "battle_rule_logical_key": "battle_rule_v1:alpha",
                        }
                    }
                ),
                encoding="utf-8",
            )
            old_env = {
                key: os.environ.get(key)
                for key in (
                    "MANALOOM_CANONICAL_KNOWN_CARDS_JSON",
                    "MANALOOM_KNOWLEDGE_DB",
                )
            }
            try:
                os.environ["MANALOOM_CANONICAL_KNOWN_CARDS_JSON"] = str(canonical_path)
                os.environ["MANALOOM_KNOWLEDGE_DB"] = str(db_path)
                battle = load_battle_module(
                    MODULE_PATH,
                    "battle_under_test_canonical_snapshot_fallback",
                )
            finally:
                for key, value in old_env.items():
                    if value is None:
                        os.environ.pop(key, None)
                    else:
                        os.environ[key] = value

            alpha = battle.get_card_effect({"name": "Alpha Card"})
            beta = battle.get_card_effect({"name": "Beta Card"})

            self.assertEqual(alpha["effect"], "counter")
            self.assertEqual(alpha["_rule_source"], "known_cards_canonical_snapshot")
            self.assertEqual(alpha["_rule_review_status"], "verified")
            self.assertEqual(alpha["_rule_logical_key"], "battle_rule_v1:alpha")
            self.assertEqual(beta["effect"], "unknown")
            self.assertEqual(beta["_rule_source"], "unknown")


if __name__ == "__main__":
    unittest.main()
