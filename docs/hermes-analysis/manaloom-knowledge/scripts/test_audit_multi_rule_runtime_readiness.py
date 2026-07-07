#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from decimal import Decimal
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "audit_multi_rule_runtime_readiness.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "audit_multi_rule_runtime_readiness_under_test",
        MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


audit = load_module()


class AuditMultiRuleRuntimeReadinessTests(unittest.TestCase):
    def test_composite_resolution_bucket(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                audit.registry.ensure_battle_card_rules(conn)
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Composite Audit Spell",
                    {"effect": "draw_cards", "count": 1, "compose_on_resolution": True},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Composite Audit Spell",
                    {
                        "effect": "remove_creature",
                        "target": "creature",
                        "compose_on_resolution": True,
                    },
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                conn.commit()

            summary = audit.build_summary(sqlite_db)

        self.assertEqual(summary["multi_rule_card_count"], 1)
        detail = summary["details"][0]
        self.assertEqual(detail["selection_mode"], "composite_resolution")
        self.assertEqual(detail["overall_status"], "composite_resolution_ready")
        self.assertEqual(detail["gap_categories"], [])

    def test_safe_annotation_merge_bucket(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                audit.registry.ensure_battle_card_rules(conn)
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Annotation Audit Spell",
                    {"effect": "tutor", "target": "basic_land"},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                    execution_status="executable",
                )
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Annotation Audit Spell",
                    {
                        "effect": "tutor",
                        "target": "basic_land",
                        "requires_sacrifice_land": True,
                    },
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                    execution_status="annotation_only",
                )
                conn.commit()

            summary = audit.build_summary(sqlite_db)

        detail = summary["details"][0]
        self.assertEqual(
            detail["overall_status"],
            "safe_annotation_merge_ready",
        )
        self.assertEqual(detail["safe_annotation_rule_count"], 1)
        self.assertEqual(detail["gap_categories"], [])

    def test_activated_executor_gap_bucket(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                audit.registry.ensure_battle_card_rules(conn)
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Activated Gap Card",
                    {"effect": "passive"},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                    execution_status="executable",
                )
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "Activated Gap Card",
                    {
                        "effect": "passive",
                        "activated_mana_ability": True,
                        "activation_cost": "sacrifice_creature",
                        "mana_produced": 2,
                    },
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                    execution_status="auto",
                )
                conn.commit()

            summary = audit.build_summary(sqlite_db)

        detail = summary["details"][0]
        self.assertEqual(
            detail["overall_status"],
            "single_primary_with_blocked_alternatives",
        )
        self.assertIn("activated_executor_gap", detail["gap_categories"])
        self.assertEqual(
            detail["blocked_reason_counts"].get("activated_ability_requires_executor"),
            1,
        )

    def test_no_runtime_safe_primary_bucket(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                audit.registry.ensure_battle_card_rules(conn)
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "No Primary Audit Card",
                    {"effect": "passive", "trigger": "on_cast"},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                    execution_status="review_only",
                )
                audit.registry.upsert_battle_card_rule(
                    conn,
                    "No Primary Audit Card",
                    {"effect": "passive", "battle_model_scope": "metadata_only"},
                    source="curated",
                    confidence=0.95,
                    review_status="needs_review",
                    execution_status="annotation_only",
                )
                conn.commit()

            summary = audit.build_summary(sqlite_db)

        detail = summary["details"][0]
        self.assertEqual(detail["selection_mode"], "no_runtime_safe_primary")
        self.assertEqual(detail["overall_status"], "no_runtime_safe_primary")
        self.assertIn("review_only_gap", detail["gap_categories"])
        self.assertIn("annotation_only_gap", detail["gap_categories"])

    def test_json_default_serializes_postgres_decimal_values(self) -> None:
        payload = {"integer": Decimal("2"), "fractional": Decimal("0.95")}

        rendered = json.loads(json.dumps(payload, default=audit._json_default))

        self.assertEqual(rendered, {"integer": 2, "fractional": 0.95})


if __name__ == "__main__":
    unittest.main()
