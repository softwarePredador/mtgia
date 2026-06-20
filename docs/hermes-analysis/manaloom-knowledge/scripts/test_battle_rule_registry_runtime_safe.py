#!/usr/bin/env python3
"""Regression tests for battle_rule_registry runtime-safe filtering."""

from __future__ import annotations

import sqlite3
import tempfile
from contextlib import closing
from pathlib import Path

import battle_rule_registry as registry


def test_runtime_safe_filter_separates_review_only_rules():
    with tempfile.TemporaryDirectory() as tmpdir:
        sqlite_db = Path(tmpdir) / "knowledge.db"
        with closing(sqlite3.connect(sqlite_db)) as conn:
            registry.ensure_battle_card_rules(conn)
            registry.upsert_battle_card_rule(
                conn,
                "Safe Spell",
                {"effect": "draw_cards", "count": 1},
                source="curated",
                confidence=0.95,
                review_status="verified",
                execution_status="auto",
            )
            registry.upsert_battle_card_rule(
                conn,
                "Needs Review Spell",
                {"effect": "draw_cards", "count": 1},
                source="generated",
                confidence=0.4,
                review_status="needs_review",
                execution_status="auto",
            )
            registry.upsert_battle_card_rule(
                conn,
                "Review Only Spell",
                {"effect": "draw_cards", "count": 1},
                source="curated",
                confidence=0.8,
                review_status="verified",
                execution_status="review_only",
            )
            registry.upsert_battle_card_rule(
                conn,
                "Annotation Only Spell",
                {"effect": "passive", "battle_model_scope": "metadata_only"},
                source="curated",
                confidence=0.8,
                review_status="active",
                execution_status="annotation_only",
            )
            conn.commit()

        all_rules = registry.load_active_battle_card_rules(sqlite_db)
        runtime_rules = registry.load_active_battle_card_rules(
            sqlite_db,
            runtime_safe_only=True,
        )

    assert set(all_rules) == {
        "annotation only spell",
        "needs review spell",
        "review only spell",
        "safe spell",
    }
    assert set(runtime_rules) == {"safe spell"}


if __name__ == "__main__":
    test_runtime_safe_filter_separates_review_only_rules()
    print("PASS test_runtime_safe_filter_separates_review_only_rules")
