#!/usr/bin/env python3
"""Tests for live external nonpayoff source research expansion."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_live_source_research_expander as live


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
            insert into deck_cards values ('619', 'Grand Abolisher');
            insert into card_oracle_cache values
              ('orim''s chant', 'Orim''s Chant', 'Instant', 'Kicker {W}. Target player can''t cast spells this turn. If kicked, creatures can''t attack this turn.', 1, '["W"]', '[]', 's1', 'c1'),
              ('loran''s escape', 'Loran''s Escape', 'Instant', 'Target artifact or creature gains hexproof and indestructible until end of turn. Scry 1.', 1, '["W"]', '[]', 's2', 'c2'),
              ('grand abolisher', 'Grand Abolisher', 'Creature - Human Cleric', 'During your turn, your opponents can''t cast spells or activate abilities.', 2, '["W"]', '[]', 's3', 'c3'),
              ('hall of the bandit lord', 'Hall of the Bandit Lord', 'Legendary Land', '{T}, Pay 3 life: Add {C}. If that mana is spent on a creature spell, it gains haste.', 0, '[]', '[]', 's4', 'c4'),
              ('boros charm', 'Boros Charm', 'Instant', 'Choose one - Permanents you control gain indestructible until end of turn.', 2, '["R","W"]', '[]', 's5', 'c5');
            insert into card_legalities values
              ('Orim''s Chant', 'commander', 'legal'),
              ('Loran''s Escape', 'commander', 'legal'),
              ('Grand Abolisher', 'commander', 'legal'),
              ('Hall of the Bandit Lord', 'commander', 'legal'),
              ('Boros Charm', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


class GlobalCommanderExternalNonpayoffLiveSourceResearchExpanderTests(unittest.TestCase):
    def test_live_candidates_are_review_seeds_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)
        prior = write_json(root, "prior.json", {"expanded_source_candidate_rows": [{"card_name": "Boros Charm"}]})
        exhausted = write_json(
            root,
            "exhausted.json",
            {
                "status": "external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates",
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "input_artifacts": {"selected_db": str(db), "previous_reports": [str(prior)]},
            },
        )

        report = live.build_report(
            exhausted_expander_report=exhausted,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Orim's Chant",
                    "candidate_signal": "silence effect",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Grand Abolisher",
                    "candidate_signal": "already in deck",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Hall of the Bandit Lord",
                    "candidate_signal": "land lane",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Boros Charm",
                    "candidate_signal": "recycled",
                    "source_ids": ["test"],
                },
            ],
        )

        self.assertEqual(report["status"], "external_nonpayoff_live_source_research_expanded_ready_for_local_review")
        self.assertEqual(report["summary"]["live_ready_for_review_count"], 1)
        self.assertEqual(report["ready_expanded_source_candidate_rows"][0]["card_name"], "Orim's Chant")
        self.assertFalse(report["candidate_copy_allowed_now"])
        statuses = {row["card_name"]: row["status"] for row in report["expanded_source_candidate_rows"]}
        self.assertEqual(statuses["Grand Abolisher"], "expanded_source_candidate_already_in_current_deck_blocked")
        self.assertEqual(statuses["Hall of the Bandit Lord"], "expanded_source_candidate_land_lane_requires_mana_base_model")
        self.assertEqual(statuses["Boros Charm"], "expanded_source_candidate_recycled_from_prior_seed_blocked")


if __name__ == "__main__":
    unittest.main()
