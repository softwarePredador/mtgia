#!/usr/bin/env python3
"""Tests for expanded external nonpayoff source candidate review."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_expanded_source_candidate_reviewer as reviewer


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
            insert into deck_cards values ('619', 'Mana Vault');
            insert into card_oracle_cache values
              ('boros charm', 'Boros Charm', 'Instant', 'Choose one - Permanents you control gain indestructible until end of turn.', 2, '["R","W"]', '[]', 's1', 'c1'),
              ('mana vault', 'Mana Vault', 'Artifact', '{T}: Add {C}{C}{C}.', 1, '[]', '[]', 's2', 'c2'),
              ('mana crypt', 'Mana Crypt', 'Artifact', '{T}: Add {C}{C}.', 0, '[]', '[]', 's3', 'c3'),
              ('off role card', 'Off Role Card', 'Creature', 'Flying', 3, '["W"]', '[]', 's4', 'c4');
            insert into card_legalities values
              ('Boros Charm', 'commander', 'legal'),
              ('Mana Vault', 'commander', 'legal'),
              ('Mana Crypt', 'commander', 'banned'),
              ('Off Role Card', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


def expander_payload(rows: list[dict[str, object]]) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "expanded_ready_for_review_count": len(
                [row for row in rows if row["status"] == "expanded_external_source_candidate_ready_for_local_review"]
            ),
        },
        "input_artifacts": {},
        "expanded_source_candidate_rows": rows,
    }


class GlobalCommanderExternalNonpayoffExpandedSourceCandidateReviewerTests(unittest.TestCase):
    def test_ready_expanded_candidate_becomes_miner_seed_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            expander_report=write_json(
                root,
                "expander.json",
                expander_payload(
                    [
                        {
                            "target_cut_role": "haste_protection_silence",
                            "card_name": "Boros Charm",
                            "status": "expanded_external_source_candidate_ready_for_local_review",
                        }
                    ]
                ),
            ),
            selected_db=db,
        )

        self.assertEqual(report["status"], "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action")
        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 1)
        self.assertIn("indestructible", report["miner_source_seed_rows"][0]["local_role_evidence_terms"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])

    def test_current_deck_and_banned_candidates_are_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            expander_report=write_json(
                root,
                "expander.json",
                expander_payload(
                    [
                        {
                            "target_cut_role": "mana_acceleration",
                            "card_name": "Mana Vault",
                            "status": "expanded_source_candidate_already_in_current_deck_blocked",
                            "current_deck_present": True,
                        },
                        {
                            "target_cut_role": "mana_acceleration",
                            "card_name": "Mana Crypt",
                            "status": "expanded_source_candidate_blocks_commander_banned",
                        },
                    ]
                ),
            ),
            selected_db=db,
        )

        statuses = {row["card_name"]: row["review_status"] for row in report["review_rows"]}
        self.assertEqual(statuses["Mana Vault"], "expanded_source_candidate_local_review_blocks_current_deck")
        self.assertEqual(statuses["Mana Crypt"], "expanded_source_candidate_local_review_blocks_commander_banned")
        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 0)

    def test_role_mismatch_blocks_ready_expander_row(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            expander_report=write_json(
                root,
                "expander.json",
                expander_payload(
                    [
                        {
                            "target_cut_role": "mana_acceleration",
                            "card_name": "Off Role Card",
                            "status": "expanded_external_source_candidate_ready_for_local_review",
                        }
                    ]
                ),
            ),
            selected_db=db,
        )

        self.assertEqual(
            report["review_rows"][0]["review_status"],
            "expanded_source_candidate_local_review_blocks_role_mismatch",
        )
        self.assertFalse(report["review_rows"][0]["candidate_copy_allowed"])


if __name__ == "__main__":
    unittest.main()
