#!/usr/bin/env python3
"""Tests for slot_optimizer real role aggregation."""

from __future__ import annotations

import json
import os
import sqlite3
import tempfile
import unittest
from contextlib import nullcontext
from pathlib import Path
from unittest import mock

import slot_optimizer


class SlotOptimizerRealRolesTests(unittest.TestCase):
    def _conn(self, *, include_pg_roles: bool = True) -> sqlite3.Connection:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        self.addCleanup(conn.close)
        pg_roles_column = ", pg_roles TEXT" if include_pg_roles else ""
        conn.execute(
            f"""
            CREATE TABLE card_deck_analysis (
                deck_id INTEGER,
                card_name TEXT,
                role_in_deck TEXT{pg_roles_column}
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_name TEXT,
                functional_tag TEXT,
                functional_tags_json TEXT,
                type_line TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE slot_benchmarks (
                deck_id INTEGER,
                baseline_id INTEGER,
                baseline_hash TEXT,
                category TEXT,
                card_added TEXT,
                card_removed TEXT,
                wr REAL,
                delta_pp REAL,
                phase TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE swap_benchmarks (
                deck_id INTEGER,
                baseline_id INTEGER,
                baseline_hash TEXT,
                card_added TEXT,
                card_removed TEXT,
                phase TEXT
            )
            """
        )
        return conn

    def test_load_real_roles_aggregates_pg_roles_with_stable_priority(self) -> None:
        conn = self._conn()
        conn.executemany(
            """
            INSERT INTO card_deck_analysis
                (deck_id, card_name, role_in_deck, pg_roles)
            VALUES (?,?,?,?)
            """,
            [
                (6, "Flexible Charm", "draw", '["draw","removal"]'),
                (6, "Flexible Charm", "engine", '["engine"]'),
            ],
        )
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, functional_tag, functional_tags_json, type_line)
            VALUES (?,?,?,?,?)
            """,
            (6, "Flexible Charm", "draw", '["draw"]', "Instant"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["flexible charm"], "removal")

    def test_load_real_roles_falls_back_without_pg_roles_column(self) -> None:
        conn = self._conn(include_pg_roles=False)
        conn.execute(
            """
            INSERT INTO card_deck_analysis (deck_id, card_name, role_in_deck)
            VALUES (?,?,?)
            """,
            (6, "Old Analysis", "protection"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["old analysis"], "protection")

    def test_load_real_roles_uses_deck_cards_when_analysis_is_missing(self) -> None:
        conn = self._conn()
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, functional_tag, functional_tags_json, type_line)
            VALUES (?,?,?,?,?)
            """,
            (6, "Snapshot Only", "draw", '["draw","engine"]', "Enchantment"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["snapshot only"], "draw")

    def test_load_known_cards_ignores_legacy_generated_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            generated_path = Path(tmpdir) / "known_cards_generated.json"
            canonical_path = Path(tmpdir) / "known_cards_canonical_snapshot.json"
            generated_path.write_text(
                json.dumps(
                    {
                        "Alpha Card": {"effect": "remove_creature"},
                        "Beta Card": {"effect": "tutor"},
                    }
                ),
                encoding="utf-8",
            )
            canonical_path.write_text(
                json.dumps(
                    {
                        "Alpha Card": {
                            "effect": "counter",
                            "battle_rule_source": "manual",
                            "battle_rule_review_status": "verified",
                            "battle_rule_confidence": 1.0,
                        }
                    }
                ),
                encoding="utf-8",
            )

            with (
                mock.patch.dict(
                    os.environ,
                    {
                        "MANALOOM_CANONICAL_KNOWN_CARDS_JSON": str(canonical_path),
                        "MANALOOM_KNOWN_CARDS_JSON": str(generated_path),
                    },
                    clear=False,
                ),
                mock.patch.object(
                    slot_optimizer.battle_rule_registry,
                    "load_active_battle_card_rules",
                    return_value={},
                ),
            ):
                known_cards = slot_optimizer.load_known_cards()

        self.assertEqual(known_cards["Alpha Card"]["effect"], "counter")
        self.assertEqual(known_cards["Alpha Card"]["battle_rule_source"], "manual")
        self.assertNotIn("Beta Card", known_cards)

    def test_load_candidate_allowlist_keeps_only_battle_ready_lane_rows(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            matrix_path = Path(tmpdir) / "matrix.json"
            matrix_path.write_text(
                json.dumps(
                    {
                        "rows": [
                            {
                                "card_name": "Library of Leng",
                                "recommendation_lane": "priority_benchmark_candidate",
                                "rule_status": "battle_ready",
                            },
                            {
                                "card_name": "Manual Card",
                                "recommendation_lane": "priority_benchmark_candidate",
                                "rule_status": "mapper_manual",
                            },
                            {
                                "card_name": "Watch Card",
                                "recommendation_lane": "watchlist_candidate",
                                "rule_status": "battle_ready",
                            },
                            {
                                "card_name": "Pinnacle Monk // Mystic Peak",
                                "recommendation_lane": "priority_benchmark_candidate",
                                "rule_status": "battle_ready",
                            },
                        ]
                    }
                ),
                encoding="utf-8",
            )

            allowed = slot_optimizer.load_candidate_allowlist(str(matrix_path))

        self.assertIn("library of leng", allowed)
        self.assertIn("pinnacle monk // mystic peak", allowed)
        self.assertIn("pinnacle monk", allowed)
        self.assertIn("mystic peak", allowed)
        self.assertNotIn("manual card", allowed)
        self.assertNotIn("watch card", allowed)

    def test_normalize_optimizer_category_maps_noncanonical_aliases(self) -> None:
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("board_presence", "creature"),
            "wincon",
        )
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("combo_value", "copy_spell"),
            "engine",
        )
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("recursion", "recursion"),
            "engine",
        )

    def test_normalize_optimizer_category_prefers_effect_for_placeholder_buckets(self) -> None:
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("manual_review", "copy_spell"),
            "engine",
        )
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("manual_review", "tutor"),
            "tutor",
        )
        self.assertEqual(
            slot_optimizer.normalize_optimizer_category("interaction", "counter"),
            "protection",
        )

    def test_existing_benchmark_pairs_include_slot_and_swap_history(self) -> None:
        conn = self._conn()
        conn.execute(
            """
            INSERT INTO slot_benchmarks
                (deck_id, baseline_id, baseline_hash, card_added, card_removed, phase)
            VALUES (?,?,?,?,?,?)
            """,
            (607, 11, "hash-1", "Ashling, Flame Dancer", "Storm Herd", "phase1"),
        )
        conn.execute(
            """
            INSERT INTO swap_benchmarks
                (deck_id, baseline_id, baseline_hash, card_added, card_removed, phase)
            VALUES (?,?,?,?,?,?)
            """,
            (607, 11, "hash-1", "Flashback", "Reforge the Soul", "confirmation"),
        )

        pairs = slot_optimizer.existing_benchmark_pairs(
            conn,
            deck_id=607,
            baseline_id=11,
            baseline_hash="hash-1",
        )

        self.assertIn(("Ashling, Flame Dancer", "Storm Herd"), pairs)
        self.assertIn(("Flashback", "Reforge the Soul"), pairs)

    def test_main_blocks_battle_timeout_without_crashing_batch(self) -> None:
        conn = self._conn()
        slot_optimizer.ensure_optimizer_tables(conn)
        baseline = {
            "id": 11,
            "deck_hash": "hash-1",
            "semantics_hash": "sem-1",
            "ruleset_hash": "rules-1",
            "wr": 33.3,
        }

        with tempfile.TemporaryDirectory() as tmpdir:
            lock_path = Path(tmpdir) / "slot.lock"
            argv = [
                "slot_optimizer.py",
                "--deck-id",
                "607",
                "--games",
                "1",
                "--battle-timeout-seconds",
                "7",
            ]
            with (
                mock.patch.object(slot_optimizer, "LOCK_FILE", lock_path),
                mock.patch.object(slot_optimizer, "require_battle_gate_for_optimizer"),
                mock.patch.object(slot_optimizer, "connect", return_value=nullcontext(conn)),
                mock.patch.object(slot_optimizer, "latest_baseline", return_value=baseline),
                mock.patch.object(slot_optimizer, "assert_current_deck_matches_baseline"),
                mock.patch.object(slot_optimizer, "load_known_cards", return_value={}),
                mock.patch.object(slot_optimizer, "load_candidate_allowlist", return_value=set()),
                mock.patch.object(slot_optimizer, "deck_rows", return_value=[]),
                mock.patch.object(slot_optimizer, "load_real_roles", return_value={}),
                mock.patch.object(
                    slot_optimizer,
                    "build_deck_categories",
                    return_value={"draw": [("Artist's Talent", 3.0)]},
                ),
                mock.patch.object(
                    slot_optimizer,
                    "legal_candidates",
                    return_value=({"draw": [("Wheel of Fate", 0.0, "draw_cards", {})]}, {}),
                ),
                mock.patch.object(
                    slot_optimizer,
                    "choose_swap_targets",
                    return_value={"draw": "Artist's Talent"},
                ),
                mock.patch.object(slot_optimizer, "existing_benchmark_pairs", return_value=set()),
                mock.patch.object(
                    slot_optimizer,
                    "quality_gate_candidate",
                    return_value={"status": "passed", "reasons": [], "warnings": []},
                ),
                mock.patch.object(slot_optimizer, "temporary_swap", return_value=nullcontext()),
                mock.patch.object(
                    slot_optimizer,
                    "run_battle",
                    side_effect=slot_optimizer.BattleRunTimeout(7),
                ),
                mock.patch("sys.argv", argv),
            ):
                exit_code = slot_optimizer.main()

        rows = conn.execute("SELECT COUNT(*) FROM slot_benchmarks").fetchone()[0]
        review = conn.execute(
            """
            SELECT status, reasons_json
            FROM optimizer_quality_reviews
            WHERE deck_id=? AND card_added=? AND card_removed=?
            ORDER BY id DESC
            LIMIT 1
            """,
            (607, "Wheel of Fate", "Artist's Talent"),
        ).fetchone()
        self.assertEqual(exit_code, 0)
        self.assertEqual(rows, 0)
        self.assertIsNotNone(review)
        self.assertEqual(review["status"], "blocked")
        self.assertEqual(json.loads(review["reasons_json"]), ["battle_timeout_7s"])

    def test_main_refuses_to_scan_without_trusted_battle_gate(self) -> None:
        with (
            mock.patch.object(
                slot_optimizer,
                "require_battle_gate_for_optimizer",
                side_effect=RuntimeError(
                    "Optimizer battle gate blocked: "
                    "battle_gate_not_trusted_for_strategy_learning:missing_summary"
                ),
            ),
            mock.patch("sys.argv", ["slot_optimizer.py"]),
        ):
            with self.assertRaisesRegex(SystemExit, "missing_summary"):
                slot_optimizer.main()


if __name__ == "__main__":
    unittest.main()
