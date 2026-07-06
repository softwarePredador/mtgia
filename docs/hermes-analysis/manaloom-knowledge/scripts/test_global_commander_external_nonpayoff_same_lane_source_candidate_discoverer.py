#!/usr/bin/env python3
"""Tests for external nonpayoff same-lane source candidate discovery."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_same_lane_source_candidate_discoverer as discoverer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def policy_payload(cut_policy: str = "require_external_nonpayoff_source_discovery_before_miner") -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "role_policy_rows": [
            {"target_cut_role": "haste_protection_silence", "cut_policy": cut_policy},
            {"target_cut_role": "mana_acceleration", "cut_policy": cut_policy},
            {"target_cut_role": "tutors_access", "cut_policy": cut_policy},
        ],
    }


def create_db(path: Path) -> None:
    con = sqlite3.connect(path)
    try:
        con.execute("create table deck_cards (deck_id integer, card_name text)")
        con.execute(
            """
            create table card_oracle_cache (
                normalized_name text primary key,
                name text,
                type_line text,
                cmc real,
                scryfall_id text
            )
            """
        )
        for name in [
            "Lightning Greaves",
            "Arcane Signet",
            "Demonic Tutor",
            "Enlightened Tutor",
            "Vampiric Tutor",
            "Diabolic Intent",
        ]:
            con.execute("insert into deck_cards (deck_id, card_name) values (?, ?)", (619, name))
        for name in [
            "Lightning Greaves",
            "Swiftfoot Boots",
            "Boros Charm",
            "Dragon Tempest",
            "Dihada, Binder of Wills",
            "Arcane Signet",
            "Sword of the Animist",
            "Simian Spirit Guide",
            "Fellwar Stone",
            "Demonic Tutor",
            "Enlightened Tutor",
            "Vampiric Tutor",
            "Diabolic Intent",
            "Gamble",
        ]:
            con.execute(
                """
                insert into card_oracle_cache
                (normalized_name, name, type_line, cmc, scryfall_id)
                values (?, ?, ?, ?, ?)
                """,
                (discoverer.normalize_name(name), name, "Artifact", 2.0, f"id-{discoverer.normalize_name(name)}"),
            )
        con.commit()
    finally:
        con.close()


class GlobalCommanderExternalNonpayoffSameLaneSourceCandidateDiscovererTests(unittest.TestCase):
    def test_discovers_named_candidates_without_cut_permission(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = root / "knowledge_candidate.db"
        create_db(db_path)
        package_report = write_json(
            root,
            "package.json",
            {
                "selected_add_package": [
                    {"card_name": "Swiftfoot Boots"},
                    {"card_name": "Boros Charm"},
                    {"card_name": "Fellwar Stone"},
                    {"card_name": "Gamble"},
                ]
            },
        )

        report = discoverer.build_report(
            policy_report=write_json(root, "policy.json", policy_payload()),
            corpus_report=write_json(root, "corpus.json", {"summary": {"deck_id": "619", "commander": "Kaalia"}}),
            package_source_report=package_report,
            selected_db=db_path,
        )

        self.assertEqual(
            report["status"],
            "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
        )
        self.assertEqual(report["summary"]["source_candidate_count"], 16)
        self.assertEqual(report["summary"]["role_count"], 3)
        self.assertEqual(report["summary"]["current_deck_present_count"], 6)
        self.assertEqual(report["summary"]["outside_current_deck_count"], 10)
        self.assertEqual(report["summary"]["selected_as_package_add_count"], 4)
        self.assertEqual(report["summary"]["local_identity_found_count"], 15)
        self.assertEqual(report["summary"]["card_level_cut_permission_count"], 0)
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        statuses = report["summary"]["status_counts"]
        self.assertEqual(statuses["external_source_candidate_already_in_current_deck_needs_trace_policy"], 6)
        self.assertEqual(statuses["external_source_candidate_ready_for_local_source_lane_review"], 5)

    def test_non_discovery_policy_roles_are_skipped(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db_path = root / "knowledge_candidate.db"
        create_db(db_path)

        report = discoverer.build_report(
            policy_report=write_json(root, "policy.json", policy_payload("block_source_discovery_until_fresh_trace_resolves")),
            corpus_report=write_json(root, "corpus.json", {"summary": {"deck_id": "619", "commander": "Kaalia"}}),
            package_source_report=write_json(root, "package.json", {"selected_add_package": []}),
            selected_db=db_path,
        )

        self.assertEqual(report["summary"]["source_candidate_count"], 0)
        self.assertEqual(report["summary"]["role_count"], 0)
        self.assertEqual(report["summary"]["card_level_cut_permission_count"], 0)
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(
            report["summary"]["next_gate"],
            "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
        )


if __name__ == "__main__":
    unittest.main()
