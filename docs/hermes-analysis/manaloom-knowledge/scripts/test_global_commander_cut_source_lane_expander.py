#!/usr/bin/env python3
"""Tests for Commander cut source-lane expansion."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_cut_source_lane_expander as expander


class GlobalCommanderCutSourceLaneExpanderTests(unittest.TestCase):
    def _db(self, root: Path) -> Path:
        path = root / "knowledge.db"
        conn = sqlite3.connect(path)
        conn.execute(
            """
            CREATE TABLE deck_cards (
              deck_id TEXT,
              card_name TEXT,
              quantity INTEGER,
              functional_tag TEXT,
              functional_tags_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              is_commander INTEGER
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE format_staples (
              card_name TEXT,
              format TEXT,
              archetype TEXT,
              category TEXT,
              color_identity TEXT,
              edhrec_rank INTEGER,
              scryfall_id TEXT,
              is_banned INTEGER,
              synced_at TEXT,
              PRIMARY KEY (card_name, format, archetype, category)
            )
            """
        )
        rows = [
            ("Kaalia of the Vast", "Legendary Creature - Human Cleric", "Flying. Whenever Kaalia attacks.", 4, 1),
            ("Sol Ring", "Artifact", "{T}: Add two mana.", 1, 0),
            ("Arcane Signet", "Artifact", "{T}: Add one mana of any color.", 2, 0),
            ("Slow Rock", "Artifact", "{T}: Add one mana.", 3, 0),
            ("Ritual Spell", "Instant", "Add two mana.", 1, 0),
            ("Draw Spell", "Sorcery", "Draw two cards.", 3, 0),
            ("Tutor A", "Sorcery", "Search your library for a card.", 2, 0),
            ("Tutor B", "Instant", "Search your library for a card.", 1, 0),
            ("Protected Dragon", "Creature - Dragon", "Flying.", 6, 0),
            ("Protected Removal", "Instant", "Destroy target creature.", 2, 0),
            ("Protected Haste", "Artifact", "Equipped creature has haste.", 2, 0),
        ]
        for name, type_line, text, cmc, commander in rows:
            conn.execute(
                "INSERT INTO deck_cards VALUES ('619', ?, 1, '', '[]', ?, ?, ?, ?)",
                (name, type_line, text, cmc, commander),
            )
        conn.execute(
            "INSERT INTO format_staples VALUES ('Sol Ring', 'commander', 'ramp', '', '[]', 1, '', 0, 'now')"
        )
        conn.execute(
            "INSERT INTO format_staples VALUES ('Arcane Signet', 'commander', 'ramp', '', '[]', 3, '', 0, 'now')"
        )
        conn.commit()
        conn.close()
        return path

    def _json(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def _reports(self, root: Path, db: Path, *, selected_add_count: int, package_size_limit: int) -> Path:
        strategy = self._json(
            root,
            "strategy.json",
            {
                "input_artifacts": {"base_db": str(db)},
                "target_evaluations": [
                    {
                        "role": "mana_acceleration",
                        "candidate_count": 13,
                        "max": 10,
                        "candidate_status": "above_target_review",
                    },
                    {
                        "role": "card_draw_selection",
                        "candidate_count": 7,
                        "max": 6,
                        "candidate_status": "above_target_review",
                    },
                    {
                        "role": "tutors_access",
                        "candidate_count": 6,
                        "max": 4,
                        "candidate_status": "above_target_review",
                    },
                ],
            },
        )
        profile = self._json(
            root,
            "profile.json",
            {
                "input_artifacts": {
                    "candidate_db": str(root / "missing_candidate.db"),
                    "strategy_matrix_report": str(strategy),
                }
            },
        )
        return self._json(
            root,
            "package.json",
            {
                "summary": {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "selected_add_count": selected_add_count,
                    "package_size_limit": package_size_limit,
                },
                "input_artifacts": {"repair_candidate_model_report": str(profile)},
            },
        )

    def test_expands_value_safe_cuts_but_keeps_staple_anchors_stage_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root)
        package = self._reports(root, db, selected_add_count=6, package_size_limit=4)

        report = expander.build_report(package_synthesis_report=package)

        self.assertEqual(report["status"], "commander_cut_source_lane_expanded_stage_split_required")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn("value_safe_cut_shortfall:required_6_ready_5", report["candidate_copy_blockers"])
        self.assertIn("full_package_size_exceeds_stage_limit:required_6_limit_4", report["candidate_copy_blockers"])
        selected_names = {row["card_name"] for row in report["selected_value_safe_cuts"]}
        self.assertEqual(selected_names, {"Slow Rock", "Ritual Spell", "Draw Spell", "Tutor A", "Tutor B"})
        stage_names = {row["card_name"] for row in report["stage_only_cut_candidates"]}
        self.assertIn("Sol Ring", stage_names)
        self.assertIn("Arcane Signet", stage_names)
        blocked = {row["card_name"]: row["block_reasons"] for row in report["blocked_cut_candidates"]}
        self.assertIn("protected_profile_role_angels_demons_dragons_payoffs", blocked["Protected Dragon"])
        self.assertIn("protected_profile_role_spot_interaction", blocked["Protected Removal"])

    def test_small_value_safe_cut_lane_can_open_candidate_copy_without_battle(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root)
        package = self._reports(root, db, selected_add_count=2, package_size_limit=4)

        report = expander.build_report(package_synthesis_report=package)

        self.assertEqual(report["status"], "commander_cut_source_lane_ready_for_candidate_copy")
        self.assertTrue(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["value_safe_cut_count"], 2)
        self.assertEqual(report["summary"]["next_gate"], "materialize_value_safe_commander_package_copy")

    def test_forced_access_usage_blocks_unresolved_cut_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root)
        package = self._reports(root, db, selected_add_count=6, package_size_limit=8)
        forced = self._json(
            root,
            "forced.json",
            {
                "status": "forced_cut_access_trace_blocks_used_unresolved_cuts",
                "summary": {
                    "usage_blocked_count": 3,
                    "manual_review_count": 0,
                    "force_failure_count": 0,
                    "focus_cards": ["Alicia Masters", "Vampiric Tutor", "Dark Ritual"],
                },
            },
        )

        report = expander.build_report(
            package_synthesis_report=package,
            forced_cut_access_report=forced,
        )

        self.assertEqual(report["status"], "commander_cut_source_lane_still_blocks_full_package")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["forced_usage_blocked_count"], 3)
        self.assertEqual(
            report["summary"]["next_gate"],
            "backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block",
        )
        self.assertIn(
            "forced_cut_access_blocks_unresolved_cut_reclassification:3",
            report["candidate_copy_blockers"],
        )


if __name__ == "__main__":
    unittest.main()
