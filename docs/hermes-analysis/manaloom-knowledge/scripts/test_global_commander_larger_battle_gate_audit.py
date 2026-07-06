#!/usr/bin/env python3
"""Tests for larger global Commander battle gate auditing."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_larger_battle_gate_audit as audit


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class GlobalCommanderLargerBattleGateAuditTests(unittest.TestCase):
    def test_candidate_can_improve_base_but_still_block_against_protected_607(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        added = ["Bant Panorama", "Call Forth the Tempest"]
        gate = write_json(
            root / "gate.json",
            {
                "status": "ready",
                "games_per_opponent": 3,
                "opponents": [f"opponent-{idx}" for idx in range(8)],
                "forced_access_mode": "none",
                "results": [
                    {
                        "deck_key": "deck_607",
                        "deck_name": "Protected 607",
                        "games": 24,
                        "wins": 7,
                        "losses": 17,
                        "stalls": 0,
                        "win_rate": 29.17,
                        "construction_valid": True,
                    },
                    {
                        "deck_key": "deck_612",
                        "deck_name": "Immediate Base",
                        "games": 24,
                        "wins": 2,
                        "losses": 22,
                        "stalls": 0,
                        "win_rate": 8.33,
                        "construction_valid": True,
                    },
                    {
                        "deck_key": "candidate_profile_repair_package",
                        "deck_name": "Candidate",
                        "games": 24,
                        "wins": 4,
                        "losses": 20,
                        "stalls": 0,
                        "win_rate": 16.67,
                        "construction_valid": True,
                        "telemetry": {
                            "card_event_counts": {
                                "land_played:Bant Panorama": 3,
                            },
                            "focus_card_access_summary": {
                                "Bant Panorama": {"accessed_games": 4, "drawn_games": 2},
                                "Call Forth the Tempest": {"accessed_games": 2, "drawn_games": 0},
                            },
                        },
                    },
                ],
            },
        )
        strategy = write_json(
            root / "strategy.json",
            {
                "summary": {
                    "commander": "Lorehold, the Historian",
                    "deck_id": "612",
                    "package_adds": added,
                }
            },
        )
        natural = write_json(
            root / "natural.json",
            {
                "status": "candidate_added_card_natural_replay_all_exercised_ready_for_larger_gate",
                "larger_battle_gate_allowed_next": True,
            },
        )

        payload = audit.build_report(
            gate_report=gate,
            strategy_report=strategy,
            natural_replay_report=natural,
            candidate_key="candidate_profile_repair_package",
            protected_baseline_key="deck_607",
            immediate_base_key="deck_612",
        )

        self.assertEqual(payload["status"], "larger_battle_gate_blocks_promotion")
        self.assertFalse(payload["promotion_allowed"])
        self.assertEqual(payload["summary"]["candidate_vs_protected"]["win_delta"], -3)
        self.assertEqual(payload["summary"]["candidate_vs_immediate_base"]["win_delta"], 2)
        self.assertIn("candidate_did_not_beat_protected_baseline", payload["blockers"])
        self.assertIn(
            "larger_gate_unexercised_added_cards:Call Forth the Tempest",
            payload["blockers"],
        )
        rows = {row["card_name"]: row for row in payload["added_card_review_rows"]}
        self.assertEqual(rows["Bant Panorama"]["status"], "larger_gate_added_card_exercised")
        self.assertEqual(
            rows["Call Forth the Tempest"]["status"],
            "larger_gate_added_card_accessed_without_exercise",
        )

    def test_wrong_forced_access_or_small_sample_blocks(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        gate = write_json(
            root / "gate.json",
            {
                "games_per_opponent": 1,
                "opponents": ["one"],
                "forced_access_mode": "opening_hand",
                "results": [
                    {"deck_key": "deck_607", "wins": 0, "losses": 1, "win_rate": 0},
                    {"deck_key": "deck_612", "wins": 0, "losses": 1, "win_rate": 0},
                    {"deck_key": "candidate_profile_repair_package", "wins": 1, "losses": 0, "win_rate": 100},
                ],
            },
        )
        strategy = write_json(root / "strategy.json", {"summary": {"package_adds": []}})
        natural = write_json(root / "natural.json", {})

        payload = audit.build_report(
            gate_report=gate,
            strategy_report=strategy,
            natural_replay_report=natural,
            candidate_key="candidate_profile_repair_package",
            protected_baseline_key="deck_607",
            immediate_base_key="deck_612",
        )

        self.assertIn("forced_access_mode_not_none:opening_hand", payload["blockers"])
        self.assertIn("larger_gate_sample_too_small", payload["blockers"])
        self.assertFalse(payload["promotion_allowed"])

    def test_explicit_invalid_construction_blocks_even_when_candidate_wins(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        gate = write_json(
            root / "gate.json",
            {
                "games_per_opponent": 3,
                "opponents": [f"opponent-{idx}" for idx in range(8)],
                "forced_access_mode": "none",
                "results": [
                    {"deck_key": "deck_607", "wins": 1, "losses": 23, "win_rate": 4.17},
                    {"deck_key": "deck_612", "wins": 1, "losses": 23, "win_rate": 4.17},
                    {
                        "deck_key": "candidate_profile_repair_package",
                        "wins": 24,
                        "losses": 0,
                        "win_rate": 100,
                        "construction_report": {"is_valid": False},
                        "telemetry": {
                            "card_event_counts": {
                                "spell_cast:Call Forth the Tempest": 1,
                            },
                            "focus_card_access_summary": {
                                "Call Forth the Tempest": {"accessed_games": 1},
                            },
                        },
                    },
                ],
            },
        )
        strategy = write_json(
            root / "strategy.json",
            {"summary": {"package_adds": ["Call Forth the Tempest"]}},
        )
        natural = write_json(root / "natural.json", {})

        payload = audit.build_report(
            gate_report=gate,
            strategy_report=strategy,
            natural_replay_report=natural,
            candidate_key="candidate_profile_repair_package",
            protected_baseline_key="deck_607",
            immediate_base_key="deck_612",
        )

        self.assertIn("candidate_construction_invalid", payload["blockers"])
        self.assertFalse(payload["promotion_allowed"])


if __name__ == "__main__":
    unittest.main()
