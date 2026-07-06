#!/usr/bin/env python3
"""Tests for expanded external nonpayoff source candidate pools."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_source_candidate_pool_expander as expander


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
              ('boros charm', 'Boros Charm', 'Instant', 'Choose one — Permanents you control gain indestructible until end of turn.', 2, '["R","W"]', '[]', 's1', 'c1'),
              ('swiftfoot boots', 'Swiftfoot Boots', 'Artifact — Equipment', 'Equipped creature has hexproof and haste.', 2, '[]', '[]', 's2', 'c2'),
              ('mana vault', 'Mana Vault', 'Artifact', '{T}: Add {C}{C}{C}.', 1, '[]', '[]', 's3', 'c3'),
              ('mana crypt', 'Mana Crypt', 'Artifact', '{T}: Add {C}{C}.', 0, '[]', '[]', 's4', 'c4');
            insert into card_legalities values
              ('Boros Charm', 'commander', 'legal'),
              ('Swiftfoot Boots', 'commander', 'legal'),
              ('Mana Vault', 'commander', 'legal'),
              ('Mana Crypt', 'commander', 'banned');
            """
        )
        con.commit()
    finally:
        con.close()


def router_payload() -> dict[str, object]:
    return {
        "status": "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
    }


class GlobalCommanderExternalNonpayoffSourceCandidatePoolExpanderTests(unittest.TestCase):
    def test_legal_outside_deck_candidate_is_ready_for_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            previous_reviewer_report=write_json(root, "reviewer.json", {"review_rows": []}),
            previous_finder_report=write_json(root, "finder.json", {"new_external_source_rows": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Boros Charm",
                    "candidate_signal": "protection",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["status"], "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review")
        self.assertEqual(report["summary"]["expanded_ready_for_review_count"], 1)
        self.assertIn("indestructible", report["ready_expanded_source_candidate_rows"][0]["local_role_evidence_terms"])
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_previous_seed_is_blocked_as_recycled(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            previous_reviewer_report=write_json(
                root,
                "reviewer.json",
                {"miner_source_seed_rows": [{"card_name": "Swiftfoot Boots"}]},
            ),
            previous_finder_report=write_json(root, "finder.json", {"new_external_source_rows": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "haste_protection_silence",
                    "card_name": "Swiftfoot Boots",
                    "candidate_signal": "prior seed",
                    "source_ids": ["test"],
                }
            ],
        )

        self.assertEqual(report["summary"]["expanded_ready_for_review_count"], 0)
        self.assertEqual(
            report["expanded_source_candidate_rows"][0]["status"],
            "expanded_source_candidate_recycled_from_prior_seed_blocked",
        )

    def test_current_deck_and_banned_candidates_stay_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = root / "knowledge.db"
        make_db(db)

        report = expander.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            previous_reviewer_report=write_json(root, "reviewer.json", {"review_rows": []}),
            previous_finder_report=write_json(root, "finder.json", {"new_external_source_rows": []}),
            selected_db=db,
            candidate_rows=[
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Mana Vault",
                    "candidate_signal": "already in deck",
                    "source_ids": ["test"],
                },
                {
                    "target_cut_role": "mana_acceleration",
                    "card_name": "Mana Crypt",
                    "candidate_signal": "banned",
                    "source_ids": ["test"],
                },
            ],
        )

        statuses = {row["card_name"]: row["status"] for row in report["expanded_source_candidate_rows"]}
        self.assertEqual(statuses["Mana Vault"], "expanded_source_candidate_already_in_current_deck_blocked")
        self.assertEqual(statuses["Mana Crypt"], "expanded_source_candidate_blocks_commander_banned")
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
