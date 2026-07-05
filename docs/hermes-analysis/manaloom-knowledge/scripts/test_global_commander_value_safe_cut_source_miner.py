#!/usr/bin/env python3
"""Tests for Commander fresh value-safe cut-source mining."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_value_safe_cut_source_miner as miner


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def build_db(root: Path, *, include_fresh: bool) -> Path:
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
        ("Kaalia of the Vast", "Legendary Creature - Human Cleric", "Flying.", 4, 1),
        ("Ancient Tomb", "Land", "", 0, 0),
        ("Sol Ring", "Artifact", "{T}: Add two mana.", 1, 0),
        ("Dark Ritual", "Instant", "Add three black mana.", 1, 0),
    ]
    if include_fresh:
        rows.append(("Off Profile Relic", "Artifact", "A narrow table effect.", 5, 0))
    for name, type_line, oracle, cmc, commander in rows:
        conn.execute(
            "INSERT INTO deck_cards VALUES ('619', ?, 1, '', '[]', ?, ?, ?, ?)",
            (name, type_line, oracle, cmc, commander),
        )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Sol Ring', 'commander', 'ramp', '', '[]', 1, '', 0, 'now')"
    )
    conn.commit()
    conn.close()
    return path


def recovery_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "target_cut_roles": {"mana_acceleration": 1, "tutors_access": 1},
        }
    }


def cut_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "forced_focus_cards": ["Dark Ritual"],
        },
        "stage_only_cut_candidates": [
            {"card_name": "Dark Ritual", "stage_reasons": ["structural_foundation_staple_requires_same_lane_or_battle_proof"]}
        ],
    }


def external_policy_payload() -> dict[str, object]:
    return {
        "cut_policy_rows": [
            {
                "cut_card": "Off Profile Relic",
                "rerun_miner_allowed_for_card": False,
                "cut_policy": "exclude_from_rerun_miner_until_new_internal_evidence",
            }
        ],
        "excluded_from_rerun_miner": ["Off Profile Relic"],
        "held_for_negative_review": [],
    }


class GlobalCommanderValueSafeCutSourceMinerTests(unittest.TestCase):
    def test_mines_fresh_nonprotected_hypothesis_for_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = build_db(root, include_fresh=True)

        report = miner.build_report(
            recovery_report=write_json(root, "recovery.json", recovery_payload()),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            sqlite_db=db,
        )

        self.assertEqual(report["status"], "value_safe_cut_source_hypotheses_ready_for_trace")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["value_safe_reclassification_allowed_now"])
        self.assertGreaterEqual(report["summary"]["hypothesis_count"], 1)
        names = {row["card_name"] for row in report["fresh_cut_source_hypotheses"]}
        self.assertIn("Off Profile Relic", names)
        self.assertEqual(report["summary"]["next_gate"], "collect_usage_trace_for_new_cut_source_hypotheses")

    def test_blocks_when_only_protected_or_stage_only_sources_exist(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = build_db(root, include_fresh=False)

        report = miner.build_report(
            recovery_report=write_json(root, "recovery.json", recovery_payload()),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            sqlite_db=db,
        )

        self.assertEqual(report["status"], "value_safe_cut_source_mining_blocks_package_resynthesis")
        self.assertEqual(report["summary"]["hypothesis_count"], 0)
        self.assertEqual(report["summary"]["next_gate"], "broaden_commander_package_axis_or_external_cut_research")
        blocked = {row["card_name"]: row["block_reasons"] for row in report["blocked_hypothesis_sample"]}
        self.assertIn("protected_profile_role_lands", blocked["Ancient Tomb"])
        self.assertIn("structural_foundation_staple_requires_same_lane_or_battle_proof", blocked["Sol Ring"])

    def test_external_policy_exclusion_blocks_reusing_fresh_hypothesis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = build_db(root, include_fresh=True)

        report = miner.build_report(
            recovery_report=write_json(root, "recovery.json", recovery_payload()),
            cut_source_report=write_json(root, "cut.json", cut_payload()),
            sqlite_db=db,
            external_cut_policy_report=write_json(root, "policy.json", external_policy_payload()),
        )

        self.assertEqual(report["status"], "value_safe_cut_source_mining_blocks_package_resynthesis")
        self.assertEqual(report["summary"]["hypothesis_count"], 0)
        self.assertEqual(report["summary"]["external_policy_exclusion_count"], 1)
        blocked = {row["card_name"]: row["block_reasons"] for row in report["blocked_hypothesis_sample"]}
        self.assertIn(
            "external_corpus_policy:exclude_from_rerun_miner_until_new_internal_evidence",
            blocked["Off Profile Relic"],
        )


if __name__ == "__main__":
    unittest.main()
