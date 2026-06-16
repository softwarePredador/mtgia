#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from battle_rule_registry import ensure_battle_card_rules, upsert_battle_card_rule


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "universal_optimizer.py"


def load_prefix_namespace() -> dict[str, object]:
    source = MODULE_PATH.read_text(encoding="utf-8")
    prefix = source.split("# ── Concurrency lock ──", 1)[0]
    namespace: dict[str, object] = {}
    exec(prefix, namespace)
    return namespace


optimizer_ns = load_prefix_namespace()
load_known_cards = optimizer_ns["load_known_cards"]


class UniversalOptimizerKnownCardsTests(unittest.TestCase):
    def build_sqlite(self, rows: list[dict[str, object]]) -> str:
        handle = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
        handle.close()
        conn = sqlite3.connect(handle.name)
        ensure_battle_card_rules(conn)
        for row in rows:
            upsert_battle_card_rule(
                conn,
                str(row["card_name"]),
                dict(row["effect_json"]),
                source=str(row["source"]),
                confidence=float(row.get("confidence", 1.0)),
                review_status=str(row.get("review_status", "verified")),
            )
        conn.commit()
        conn.close()
        return handle.name

    def build_generated_json(self, payload: dict[str, dict[str, object]]) -> str:
        handle = tempfile.NamedTemporaryFile(suffix=".json", delete=False)
        Path(handle.name).write_text(json.dumps(payload), encoding="utf-8")
        return handle.name

    def test_sqlite_rules_override_legacy_json(self) -> None:
        sqlite_db = self.build_sqlite(
            [
                {
                    "card_name": "Alpha Card",
                    "effect_json": {"effect": "counter"},
                    "source": "manual",
                }
            ]
        )
        generated_json = self.build_generated_json(
            {
                "Alpha Card": {"effect": "remove_creature"},
                "Beta Card": {"effect": "tutor"},
            }
        )

        known_cards = load_known_cards(generated_json, sqlite_db)

        self.assertEqual(known_cards["Alpha Card"]["effect"], "counter")
        self.assertEqual(known_cards["Alpha Card"]["battle_rule_source"], "manual")
        self.assertEqual(known_cards["Alpha Card"]["battle_rule_review_status"], "verified")
        self.assertEqual(known_cards["Beta Card"]["effect"], "tutor")

    def test_canonical_snapshot_overrides_legacy_json_before_sqlite_overlay(self) -> None:
        sqlite_db = self.build_sqlite([])
        generated_json = self.build_generated_json(
            {
                "Alpha Card": {"effect": "remove_creature"},
                "Beta Card": {"effect": "tutor"},
            }
        )
        canonical_json = self.build_generated_json(
            {
                "Alpha Card": {
                    "effect": "counter",
                    "battle_rule_source": "manual",
                    "battle_rule_review_status": "verified",
                    "battle_rule_confidence": 1.0,
                }
            }
        )

        with mock.patch.dict(
            os.environ,
            {"MANALOOM_CANONICAL_KNOWN_CARDS_JSON": canonical_json},
            clear=False,
        ):
            known_cards = load_known_cards(generated_json, sqlite_db)

        self.assertEqual(known_cards["Alpha Card"]["effect"], "counter")
        self.assertEqual(known_cards["Alpha Card"]["battle_rule_source"], "manual")
        self.assertEqual(known_cards["Beta Card"]["effect"], "tutor")


if __name__ == "__main__":
    unittest.main()
