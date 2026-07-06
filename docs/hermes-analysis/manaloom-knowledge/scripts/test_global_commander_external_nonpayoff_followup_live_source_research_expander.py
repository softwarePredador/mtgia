#!/usr/bin/env python3
"""Tests for follow-up live external nonpayoff source research."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_followup_live_source_research_expander as followup


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
            insert into deck_cards values ('619', 'The One Ring');
            insert into card_oracle_cache values
              ('deflecting swat', 'Deflecting Swat', 'Instant', 'If you control a commander, you may cast this spell without paying its mana cost. You may choose new targets for target spell or ability.', 3, '["R"]', '[]', 's1', 'c1'),
              ('dolmen gate', 'Dolmen Gate', 'Artifact', 'Prevent all combat damage that would be dealt to attacking creatures you control.', 2, '[]', '[]', 's2', 'c2'),
              ('black market connections', 'Black Market Connections', 'Enchantment', 'At the beginning of your first main phase, choose one or more - Create a Treasure token. Draw a card.', 3, '["B"]', '[]', 's3', 'c3'),
              ('the one ring', 'The One Ring', 'Legendary Artifact', 'Indestructible. When The One Ring enters, you gain protection from everything until your next turn.', 4, '[]', '[]', 's4', 'c4');
            insert into card_legalities values
              ('Deflecting Swat', 'commander', 'legal'),
              ('Dolmen Gate', 'commander', 'legal'),
              ('Black Market Connections', 'commander', 'legal'),
              ('The One Ring', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


class GlobalCommanderExternalNonpayoffFollowupLiveSourceResearchExpanderTests(unittest.TestCase):
    def test_followup_blocks_recycled_and_emits_only_new_review_seeds(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)
        prior = write_json(
            root,
            "prior.json",
            {"expanded_source_candidate_rows": [{"card_name": "Deflecting Swat"}]},
        )
        exhausted = write_json(
            root,
            "exhausted.json",
            {
                "status": "external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates",
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "input_artifacts": {"selected_db": str(db), "previous_reports": [str(prior)]},
            },
        )
        manual = write_json(
            root,
            "manual.json",
            {
                "status": "external_nonpayoff_manual_negative_trace_review_blocks_current_deck_cuts",
                "summary": {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "manual_negative_review_cleared_count": 0,
                },
                "review_rows": [{"card_name": "Grand Abolisher"}],
            },
        )

        report = followup.build_report(
            exhausted_expander_report=exhausted,
            manual_negative_trace_reviewer_report=manual,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Deflecting Swat",
                    "candidate_signal": "recycled",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Dolmen Gate",
                    "candidate_signal": "fresh protection",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Black Market Connections",
                    "candidate_signal": "fresh treasure draw",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "The One Ring",
                    "candidate_signal": "already in deck",
                    "source_ids": ["test"],
                },
            ],
        )

        self.assertEqual(
            report["status"],
            "external_nonpayoff_followup_live_source_research_expanded_ready_for_local_review",
        )
        self.assertEqual(report["summary"]["manual_negative_review_cleared_count"], 0)
        self.assertEqual(report["summary"]["followup_ready_for_review_count"], 2)
        statuses = {row["card_name"]: row["status"] for row in report["expanded_source_candidate_rows"]}
        self.assertEqual(statuses["Deflecting Swat"], "expanded_source_candidate_recycled_from_prior_seed_blocked")
        self.assertEqual(statuses["Dolmen Gate"], "expanded_external_source_candidate_ready_for_local_review")
        self.assertEqual(
            statuses["Black Market Connections"],
            "expanded_external_source_candidate_ready_for_local_review",
        )
        self.assertEqual(statuses["The One Ring"], "expanded_source_candidate_already_in_current_deck_blocked")
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
