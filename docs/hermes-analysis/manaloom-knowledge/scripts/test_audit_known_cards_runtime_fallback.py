#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from battle_rule_registry import ensure_battle_card_rules, upsert_battle_card_rule


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "audit_known_cards_runtime_fallback.py"


def load_module():
    spec = importlib.util.spec_from_file_location("audit_known_cards_runtime_fallback_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


audit = load_module()


class AuditKnownCardsRuntimeFallbackTests(unittest.TestCase):
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

    def test_canonical_snapshot_prefers_sqlite_and_backfills_generated_only(self) -> None:
        sqlite_db = self.build_sqlite(
            [
                {
                    "card_name": "Alpha Card",
                    "effect_json": {"effect": "counter"},
                    "source": "manual",
                },
                {
                    "card_name": "Beta Card",
                    "effect_json": {"effect": "draw_cards", "count": 2},
                    "source": "curated",
                },
            ]
        )
        generated = {
            "Alpha Card": {"effect": "remove_creature"},
            "Gamma Card": {"effect": "tutor", "target": "any"},
        }
        oracle_cache = audit.build_oracle_cache(
            sqlite_db,
            ["Alpha Card", "Beta Card", "Gamma Card"],
        )

        snapshot = audit.build_canonical_snapshot(
            audit.load_sqlite_rules(sqlite_db),
            generated,
            oracle_cache,
        )

        self.assertEqual(snapshot["Alpha Card"]["effect"], "counter")
        self.assertEqual(snapshot["Alpha Card"]["battle_rule_source"], "manual")
        self.assertEqual(snapshot["Alpha Card"]["battle_rule_review_status"], "verified")
        self.assertEqual(snapshot["Beta Card"]["effect"], "draw_cards")
        self.assertEqual(snapshot["Gamma Card"]["effect"], "tutor")

    def test_summary_detects_overlap_generated_only_and_sqlite_only(self) -> None:
        sqlite_db = self.build_sqlite(
            [
                {
                    "card_name": "Alpha Card",
                    "effect_json": {"effect": "counter"},
                    "source": "manual",
                },
                {
                    "card_name": "Beta Card",
                    "effect_json": {"effect": "draw_cards", "count": 2},
                    "source": "curated",
                },
            ]
        )
        generated = {
            "Alpha Card": {"effect": "remove_creature"},
            "Gamma Card": {"effect": "tutor", "target": "any"},
        }
        oracle_cache = audit.build_oracle_cache(
            sqlite_db,
            ["Alpha Card", "Beta Card", "Gamma Card"],
        )
        summary = audit.build_summary(
            audit.load_sqlite_rules(sqlite_db),
            generated,
            oracle_cache,
            sample_limit=5,
        )

        self.assertEqual(summary["overlap_names"], 1)
        self.assertEqual(summary["generated_only_names"], 1)
        self.assertEqual(summary["sqlite_only_names"], 1)
        self.assertEqual(summary["runtime_effect_different"], 1)
        self.assertEqual(summary["runtime_effect_different_samples"][0]["card_name"], "Alpha Card")

    def test_strip_private_rule_metadata_removes_runtime_fields(self) -> None:
        stripped = audit.strip_private_rule_metadata(
            {
                "effect": "counter",
                "_rule_source": "manual",
                "_rule_review_status": "verified",
            }
        )
        self.assertEqual(stripped, {"effect": "counter"})


if __name__ == "__main__":
    unittest.main()
