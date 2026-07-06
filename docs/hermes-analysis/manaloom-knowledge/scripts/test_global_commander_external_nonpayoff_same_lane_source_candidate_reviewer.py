#!/usr/bin/env python3
"""Tests for local review of external nonpayoff source candidates."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_same_lane_source_candidate_reviewer as reviewer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def create_db(path: Path, *, mismatch_text: bool = False) -> None:
    con = sqlite3.connect(path)
    try:
        con.execute(
            """
            create table card_oracle_cache (
                normalized_name text primary key,
                name text,
                type_line text,
                oracle_text text,
                cmc real,
                color_identity_json text,
                keywords_json text,
                scryfall_id text
            )
            """
        )
        rows = [
            ("dragon tempest", "Dragon Tempest", "Enchantment", "Creatures you control gain haste.", 2, '["R"]', '["haste"]'),
            ("swiftfoot boots", "Swiftfoot Boots", "Artifact", "Equipped creature has hexproof and haste.", 2, "[]", '["haste"]'),
            ("arcane signet", "Arcane Signet", "Artifact", "{T}: Add one mana of any color.", 2, "[]", "[]"),
        ]
        if mismatch_text:
            rows[0] = ("dragon tempest", "Dragon Tempest", "Enchantment", "Dragons you control get +1/+0.", 2, '["R"]', "[]")
        for key, name, type_line, oracle_text, cmc, identity, keywords in rows:
            con.execute(
                """
                insert into card_oracle_cache
                (normalized_name, name, type_line, oracle_text, cmc, color_identity_json, keywords_json, scryfall_id)
                values (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (key, name, type_line, oracle_text, cmc, identity, keywords, f"id-{key}"),
            )
        con.commit()
    finally:
        con.close()


def source_payload(db_path: Path) -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "input_artifacts": {"selected_db": str(db_path)},
        "source_candidate_rows": [
            {
                "target_cut_role": "haste_protection_silence",
                "card_name": "Dragon Tempest",
                "status": "external_source_candidate_ready_for_local_source_lane_review",
            },
            {
                "target_cut_role": "haste_protection_silence",
                "card_name": "Swiftfoot Boots",
                "status": "external_source_candidate_already_selected_as_add_needs_pair_policy",
            },
            {
                "target_cut_role": "mana_acceleration",
                "card_name": "Arcane Signet",
                "status": "external_source_candidate_already_in_current_deck_needs_trace_policy",
            },
            {
                "target_cut_role": "haste_protection_silence",
                "card_name": "Bitter Reunion",
                "status": "external_source_candidate_needs_local_identity_resolution",
            },
        ],
    }


class GlobalCommanderExternalNonpayoffSameLaneSourceCandidateReviewerTests(unittest.TestCase):
    def test_reviews_local_source_candidates_without_deck_action(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = root / "knowledge.db"
        create_db(db_path)

        report = reviewer.build_report(
            source_candidate_report=write_json(root, "source_candidates.json", source_payload(db_path))
        )

        self.assertEqual(
            report["status"],
            "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
        )
        self.assertEqual(report["summary"]["reviewed_candidate_count"], 4)
        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 1)
        self.assertEqual(report["summary"]["current_deck_trace_required_count"], 1)
        self.assertEqual(report["summary"]["held_package_pair_required_count"], 1)
        self.assertEqual(report["summary"]["identity_resolution_required_count"], 1)
        self.assertEqual(report["summary"]["card_level_cut_permission_count"], 0)
        self.assertEqual(report["summary"]["candidate_copy_allowed_count"], 0)
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["miner_source_seed_rows"][0]["card_name"], "Dragon Tempest")

    def test_role_mismatch_blocks_miner_seed(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = root / "knowledge.db"
        create_db(db_path, mismatch_text=True)

        report = reviewer.build_report(
            source_candidate_report=write_json(root, "source_candidates.json", source_payload(db_path))
        )

        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 0)
        self.assertEqual(report["summary"]["role_mismatch_blocked_count"], 1)
        self.assertIn(
            "external_source_candidate_local_review_blocks_role_mismatch",
            report["summary"]["review_status_counts"],
        )
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
