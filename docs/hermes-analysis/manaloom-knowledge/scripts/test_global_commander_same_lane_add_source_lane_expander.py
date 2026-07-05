#!/usr/bin/env python3
"""Tests for Commander same-lane add source-lane expansion."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_add_source_lane_expander as expander


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def same_lane_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "same_lane_axis_requirements": [
            {
                "cut_role": "haste_protection_silence",
                "target_cut_count": 4,
                "required_add_axis": "commander_attack_window",
            },
            {
                "cut_role": "mana_acceleration",
                "target_cut_count": 1,
                "required_add_axis": "mana_acceleration_replacement",
            },
            {
                "cut_role": "tutors_access",
                "target_cut_count": 8,
                "required_add_axis": "tutors_access_replacement",
            },
        ],
    }


def profile_payload(db: Path) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "commander_color_identity": ["W", "B", "R"],
        },
        "input_artifacts": {"candidate_db": str(db)},
    }


def create_db(root: Path, *, include_tutor: bool = True) -> Path:
    db = root / "knowledge_candidate.db"
    conn = sqlite3.connect(db)
    conn.execute("CREATE TABLE deck_cards (deck_id TEXT, card_name TEXT)")
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
          name TEXT,
          normalized_name TEXT,
          mana_cost TEXT,
          colors_json TEXT,
          color_identity_json TEXT,
          type_line TEXT,
          oracle_text TEXT,
          cmc REAL,
          scryfall_id TEXT,
          card_id TEXT
        )
        """
    )
    conn.execute("CREATE TABLE card_legalities (card_name TEXT, format TEXT, status TEXT)")
    conn.execute(
        """
        CREATE TABLE format_staples (
          card_name TEXT,
          format TEXT,
          archetype TEXT,
          category TEXT,
          color_identity TEXT,
          edhrec_rank INTEGER,
          is_banned INTEGER
        )
        """
    )
    for name in ["Kaalia of the Vast", "Lightning Greaves", "Demonic Tutor"]:
        conn.execute("INSERT INTO deck_cards VALUES ('619', ?)", (name,))
    oracle_rows = [
        (
            "Kaalia of the Vast",
            "kaalia of the vast",
            "Legendary Creature - Human Cleric",
            "Flying, vigilance, haste. Whenever Kaalia attacks...",
            4,
            ["W", "B", "R"],
        ),
        (
            "Lightning Greaves",
            "lightning greaves",
            "Artifact - Equipment",
            "Equipped creature has haste and shroud.",
            2,
            [],
        ),
        (
            "Grand Abolisher",
            "grand abolisher",
            "Creature - Human Cleric",
            "During your turn, your opponents can't cast spells or activate abilities.",
            2,
            ["W"],
        ),
        (
            "Arcane Signet",
            "arcane signet",
            "Artifact",
            "{T}: Add one mana of any color in your commander's color identity.",
            2,
            [],
        ),
        (
            "Green Sun's Zenith",
            "green sun s zenith",
            "Sorcery",
            "Search your library for a green creature card, reveal it, put it into your hand, then shuffle.",
            1,
            ["G"],
        ),
        (
            "Dragon Mage",
            "dragon mage",
            "Creature - Dragon Wizard",
            "Flying. Whenever this creature deals combat damage to a player, each player discards their hand, then draws seven cards.",
            7,
            ["R"],
        ),
        (
            "Demonic Tutor",
            "demonic tutor",
            "Sorcery",
            "Search your library for a card, put that card into your hand, then shuffle.",
            2,
            ["B"],
        ),
    ]
    if include_tutor:
        oracle_rows.append(
            (
                "Gamble",
                "gamble",
                "Sorcery",
                "Search your library for a card, put that card into your hand, discard a card at random, then shuffle.",
                1,
                ["R"],
            )
        )
    for name, normalized, type_line, oracle, cmc, colors in oracle_rows:
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES (?, ?, '', '[]', ?, ?, ?, ?, '', '')",
            (name, normalized, json.dumps(colors), type_line, oracle, cmc),
        )
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal')", (name,))
    conn.execute(
        "INSERT INTO format_staples VALUES ('Arcane Signet', 'commander', 'ramp', '', '[]', 2, 0)"
    )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Demonic Tutor', 'commander', 'black', '', '[\"B\"]', 3, 0)"
    )
    conn.commit()
    conn.close()
    return db


class GlobalCommanderSameLaneAddSourceLaneExpanderTests(unittest.TestCase):
    def test_expands_ready_source_lanes_for_all_required_axes(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = create_db(root, include_tutor=True)

        report = expander.build_report(
            same_lane_resynthesis_report=write_json(root, "same_lane.json", same_lane_payload()),
            profile_repair_report=write_json(root, "profile.json", profile_payload(db)),
            limit=10,
        )

        self.assertEqual(report["status"], "same_lane_add_source_lanes_expanded_no_deck_action")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertFalse(report["value_safe_reclassification_allowed_now"])
        self.assertEqual(report["summary"]["ready_axis_count"], 3)
        self.assertEqual(
            report["summary"]["next_gate"],
            "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
        )
        by_axis = {
            lane["required_add_axis"]: {row["card_name"] for row in lane["top_candidates"]}
            for lane in report["source_lanes"]
        }
        self.assertIn("Grand Abolisher", by_axis["commander_attack_window"])
        self.assertIn("Arcane Signet", by_axis["mana_acceleration_replacement"])
        self.assertIn("Gamble", by_axis["tutors_access_replacement"])

    def test_missing_same_lane_axis_routes_to_external_research(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = create_db(root, include_tutor=False)

        report = expander.build_report(
            same_lane_resynthesis_report=write_json(root, "same_lane.json", same_lane_payload()),
            profile_repair_report=write_json(root, "profile.json", profile_payload(db)),
            limit=10,
        )

        self.assertEqual(report["status"], "same_lane_add_source_lanes_need_external_research")
        self.assertEqual(report["summary"]["missing_axes"], ["tutors_access_replacement"])
        self.assertIn(
            "missing_same_lane_add_source_axes:tutors_access_replacement",
            report["candidate_copy_blockers"],
        )

    def test_existing_and_color_incompatible_candidates_are_blocked(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = create_db(root, include_tutor=False)

        report = expander.build_report(
            same_lane_resynthesis_report=write_json(root, "same_lane.json", same_lane_payload()),
            profile_repair_report=write_json(root, "profile.json", profile_payload(db)),
            limit=30,
        )

        serialized = json.dumps(report)
        self.assertIn("already_in_current_evaluation_deck", serialized)
        self.assertIn("not_commander_color_identity_compatible", serialized)
        self.assertIn("does_not_match_required_same_lane_add_axis", serialized)


if __name__ == "__main__":
    unittest.main()
