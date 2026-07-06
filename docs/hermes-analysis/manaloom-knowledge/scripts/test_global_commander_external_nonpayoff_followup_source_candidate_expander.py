#!/usr/bin/env python3
"""Tests for cumulative follow-up external nonpayoff source expansion."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_followup_source_candidate_expander as expander


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
              ('blacksmith''s skill', 'Blacksmith''s Skill', 'Instant', 'Target permanent gains hexproof and indestructible until end of turn.', 1, '["W"]', '[]', 's1', 'c1'),
              ('mana vault', 'Mana Vault', 'Artifact', '{T}: Add {C}{C}{C}.', 1, '[]', '[]', 's2', 'c2'),
              ('diabolic tutor', 'Diabolic Tutor', 'Sorcery', 'Search your library for a card, put that card into your hand, then shuffle.', 4, '["B"]', '[]', 's3', 'c3'),
              ('wayfarer''s bauble', 'Wayfarer''s Bauble', 'Artifact', '{2}, {T}, Sacrifice this artifact: Search your library for a basic land card, put that card onto the battlefield tapped, then shuffle.', 1, '[]', '[]', 's4', 'c4');
            insert into card_legalities values
              ('Blacksmith''s Skill', 'commander', 'legal'),
              ('Mana Vault', 'commander', 'legal'),
              ('Diabolic Tutor', 'commander', 'legal'),
              ('Wayfarer''s Bauble', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


def negative_payload() -> dict[str, object]:
    return {
        "status": "external_current_deck_negative_review_blocks_used_candidates",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "review_rows": [
            {
                "card_name": "Mana Vault",
                "target_cut_role": "mana_acceleration",
                "status": "external_current_deck_candidate_used_by_target_blocks_negative_review",
            }
        ],
    }


class GlobalCommanderExternalNonpayoffFollowupSourceCandidateExpanderTests(unittest.TestCase):
    def test_new_candidate_is_ready_but_still_seed_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reports=[write_json(root, "previous.json", {"review_rows": []})],
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Blacksmith's Skill",
                    "candidate_signal": "fresh protection source",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(
            report["status"],
            "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
        )
        self.assertEqual(report["summary"]["followup_ready_for_review_count"], 1)
        self.assertIn("hexproof", report["ready_expanded_source_candidate_rows"][0]["local_role_evidence_terms"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])

    def test_previous_report_candidate_is_recycled_and_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reports=[
                write_json(
                    root,
                    "previous.json",
                    {"miner_source_seed_rows": [{"card_name": "Diabolic Tutor"}]},
                )
            ],
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "tutors_access",
                    "card_name": "Diabolic Tutor",
                    "candidate_signal": "already seen tutor",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["followup_ready_for_review_count"], 0)
        self.assertEqual(
            report["expanded_source_candidate_rows"][0]["status"],
            "expanded_source_candidate_recycled_from_prior_seed_blocked",
        )

    def test_current_deck_candidate_stays_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reports=[write_json(root, "previous.json", {"review_rows": []})],
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Mana Vault",
                    "candidate_signal": "current deck card",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["followup_ready_for_review_count"], 0)
        self.assertEqual(
            report["expanded_source_candidate_rows"][0]["status"],
            "expanded_source_candidate_already_in_current_deck_blocked",
        )

    def test_land_ramp_artifact_can_seed_mana_research(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            negative_review_report=write_json(root, "negative.json", negative_payload()),
            previous_reports=[write_json(root, "previous.json", {"review_rows": []})],
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Wayfarer's Bauble",
                    "candidate_signal": "basic land ramp artifact",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["followup_ready_for_review_count"], 1)
        self.assertIn("basic land card", report["ready_expanded_source_candidate_rows"][0]["local_role_evidence_terms"])
        self.assertEqual(
            report["ready_expanded_source_candidate_rows"][0]["seed_scope"],
            "land_ramp_artifact_seed_mana_base_context_required",
        )


if __name__ == "__main__":
    unittest.main()
