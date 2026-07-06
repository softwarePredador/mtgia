#!/usr/bin/env python3
"""Tests for fresh external nonpayoff source candidate review."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_new_source_candidate_reviewer as reviewer


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
              ('open the armory', 'Open the Armory', 'Sorcery', 'Search your library for an Aura or Equipment card, reveal it, put it into your hand, then shuffle.', 2, '["W"]', '[]', 's3', 'c3');
            insert into card_legalities values
              ('Arcane Signet', 'commander', 'legal'),
              ('Loran''s Escape', 'commander', 'legal'),
              ('Open the Armory', 'commander', 'legal');
            """
        )
        con.commit()
    finally:
        con.close()


def finder_payload(rows: list[dict[str, object]]) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "new_external_ready_for_review_count": len(rows),
        },
        "input_artifacts": {},
        "ready_new_external_source_rows": rows,
    }


class GlobalCommanderExternalNonpayoffNewSourceCandidateReviewerTests(unittest.TestCase):
    def test_ready_candidate_becomes_miner_seed_only(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            finder_report=write_json(
                root,
                "finder.json",
                finder_payload(
                    [
                        {
                            "target_cut_role": "haste_protection_silence",
                            "card_name": "Loran's Escape",
                            "status": "new_external_source_candidate_ready_for_local_miner_review",
                        }
                    ]
                ),
            ),
            selected_db=db,
        )

        self.assertEqual(report["status"], "new_external_source_candidates_reviewed_seed_ready_no_deck_action")
        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 1)
        self.assertEqual(report["miner_source_seed_rows"][0]["seed_scope"], "protection_spell_or_haste_seed")
        self.assertIn("hexproof", report["miner_source_seed_rows"][0]["local_role_evidence_terms"])
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertFalse(report["value_safe_reclassification_allowed_now"])

    def test_current_deck_candidate_is_blocked_even_if_finder_ready(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            finder_report=write_json(
                root,
                "finder.json",
                finder_payload(
                    [
                        {
                            "target_cut_role": "mana_acceleration",
                            "card_name": "Arcane Signet",
                            "status": "new_external_source_candidate_ready_for_local_miner_review",
                        }
                    ]
                ),
            ),
            selected_db=db,
        )

        self.assertEqual(report["summary"]["miner_source_seed_allowed_count"], 0)
        self.assertEqual(
            report["review_rows"][0]["review_status"],
            "new_external_source_local_review_blocks_current_deck",
        )
        self.assertFalse(report["review_rows"][0]["candidate_copy_allowed"])

    def test_equipment_tutor_seed_is_package_limited(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = reviewer.build_report(
            finder_report=write_json(
                root,
                "finder.json",
                finder_payload(
                    [
                        {
                            "target_cut_role": "tutors_access",
                            "card_name": "Open the Armory",
                            "status": "new_external_source_candidate_ready_for_local_miner_review",
                        }
                    ]
                ),
            ),
            selected_db=db,
        )

        seed = report["miner_source_seed_rows"][0]
        self.assertEqual(seed["seed_scope"], "package_access_limited_seed")
        self.assertIn("equipment_or_aura_access_must_map_to_real_package_target", seed["seed_cautions"])
        self.assertEqual(
            report["summary"]["next_gate"],
            "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
        )


if __name__ == "__main__":
    unittest.main()
