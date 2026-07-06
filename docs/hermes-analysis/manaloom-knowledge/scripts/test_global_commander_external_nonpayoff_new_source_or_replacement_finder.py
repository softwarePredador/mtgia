#!/usr/bin/env python3
"""Tests for new external nonpayoff source/replacement finder."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_new_source_or_replacement_finder as finder


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def make_db(path: Path) -> None:
    con = sqlite3.connect(path)
    try:
        con.executescript(
            """
            create table deck_cards(deck_id text, card_name text);
            create table card_oracle_cache(
              normalized_name text primary key,
              name text not null,
              type_line text,
              oracle_text text,
              cmc real,
              color_identity_json text,
              keywords_json text,
              scryfall_id text,
              card_id text
            );
            create table card_legalities(card_name text, format text, status text);
            insert into deck_cards values ('619', 'Arcane Signet');
            insert into card_oracle_cache values
              ('arcane signet', 'Arcane Signet', 'Artifact', '{T}: Add one mana of any color in your commander identity.', 2, '[]', '[]', 's1', 'c1'),
              ('loran''s escape', 'Loran''s Escape', 'Instant', 'Target artifact or creature gains hexproof and indestructible until end of turn. Scry 1.', 1, '["W"]', '[]', 's2', 'c2'),
              ('hall of the bandit lord', 'Hall of the Bandit Lord', 'Legendary Land', '{T}: Add {C}. If that mana is spent on a creature spell, it gains haste.', 0, '[]', '[]', 's3', 'c3');
            insert into card_legalities values
              ('Arcane Signet', 'commander', 'legal'),
              ('Loran''s Escape', 'commander', 'legal'),
              ('Hall of the Bandit Lord', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


def negative_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "review_rows": [
            {
                "card_name": "Arcane Signet",
                "target_cut_role": "mana_acceleration",
                "status": "external_current_deck_candidate_used_by_target_blocks_negative_review",
                "usage_event_count": 3,
                "decision_trace_count": 5,
            }
        ],
    }


class GlobalCommanderExternalNonpayoffNewSourceOrReplacementFinderTests(unittest.TestCase):
    def test_current_deck_usage_blocks_replacement_proof(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = finder.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reviewer_report=write_json(root, "previous.json", {"review_rows": []}),
            package_source_report=write_json(root, "package.json", {"selected_add_package": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Arcane Signet",
                    "candidate_signal": "current card should stay blocked",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["explicit_same_lane_replacement_proof_count"], 0)
        self.assertEqual(
            report["current_deck_replacement_review_rows"][0]["replacement_status"],
            "current_deck_candidate_used_by_target_blocks_replacement_proof",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_new_legal_outside_deck_candidate_is_ready_for_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = finder.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reviewer_report=write_json(root, "previous.json", {"review_rows": []}),
            package_source_report=write_json(root, "package.json", {"selected_add_package": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Loran's Escape",
                    "candidate_signal": "fresh protection source",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["new_external_ready_for_review_count"], 1)
        self.assertEqual(
            report["ready_new_external_source_rows"][0]["status"],
            "new_external_source_candidate_ready_for_local_miner_review",
        )
        self.assertIn("hexproof", report["ready_new_external_source_rows"][0]["local_role_evidence_terms"])

    def test_land_candidate_routes_to_mana_base_lane(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = finder.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reviewer_report=write_json(root, "previous.json", {"review_rows": []}),
            package_source_report=write_json(root, "package.json", {"selected_add_package": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Hall of the Bandit Lord",
                    "candidate_signal": "land haste source",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["new_external_ready_for_review_count"], 0)
        self.assertEqual(
            report["new_external_source_rows"][0]["status"],
            "new_source_candidate_land_lane_requires_mana_base_model",
        )


if __name__ == "__main__":
    unittest.main()
