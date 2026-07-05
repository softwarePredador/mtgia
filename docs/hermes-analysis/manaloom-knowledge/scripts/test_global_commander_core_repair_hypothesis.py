#!/usr/bin/env python3
"""Tests for global Commander core repair hypotheses."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_core_repair_hypothesis as audit


def core_row(
    *,
    deck_id: str = "619",
    commander: str = "Kaalia of the Vast",
    role: str = "removal",
    missing: int = 2,
) -> dict:
    return {
        "deck_id": deck_id,
        "deck_name": f"Deck {deck_id}",
        "commander": commander,
        "scope": "hermes_registered_variant",
        "core_repair_plan": {
            "missing_role_slots": [
                {
                    "role": role,
                    "count": 4,
                    "target_min": 6,
                    "missing": missing,
                    "severity": "critical",
                }
            ],
            "excess_role_slots": [
                {
                    "role": "engine",
                    "count": 30,
                    "target_max": 24,
                    "excess": 6,
                    "severity": "support",
                }
            ],
        },
    }


class GlobalCommanderCoreRepairHypothesisTests(unittest.TestCase):
    def _db(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        tmp = tempfile.TemporaryDirectory()
        path = Path(tmp.name) / "knowledge.db"
        conn = sqlite3.connect(path)
        conn.execute("CREATE TABLE deck_cards (deck_id TEXT, card_name TEXT)")
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
        conn.executemany(
            "INSERT INTO format_staples VALUES (?, 'commander', ?, '', ?, ?, 0)",
            [
                ("Swords to Plowshares", "removal", "W", 11),
                ("Path to Exile", "removal", "W", 15),
                ("Sol Ring", "ramp", "", 1),
                ("Thassa's Oracle", "combo", "U", 50),
            ],
        )
        conn.commit()
        conn.close()
        return tmp, path

    def test_removal_gap_gets_review_candidates_not_mutation_permission(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)
        conn = sqlite3.connect(path)
        conn.execute("INSERT INTO deck_cards VALUES ('619', 'Path to Exile')")
        conn.commit()
        conn.close()

        payload = audit.build_report(
            core_payload={"artifact_type": "global_commander_core_role_audit", "decks": [core_row()]},
            sqlite_db=path,
            staple_limit=5,
        )

        [hypothesis] = payload["hypotheses"]
        self.assertFalse(payload["mutation_allowed"])
        self.assertEqual(hypothesis["status"], "review_candidate_pool_ready_color_identity_required")
        self.assertEqual([row["card_name"] for row in hypothesis["review_candidates"]], ["Swords to Plowshares"])
        self.assertEqual(hypothesis["cut_pressure"][0]["role"], "engine")
        self.assertIn("commander_color_identity_check", hypothesis["required_gates"])

    def test_land_gap_requires_mana_profile_before_named_cards(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            core_payload={
                "artifact_type": "global_commander_core_role_audit",
                "decks": [core_row(deck_id="621", commander="Y'shtola", role="land", missing=2)],
            },
            sqlite_db=path,
            staple_limit=5,
        )

        [hypothesis] = payload["hypotheses"]
        self.assertEqual(hypothesis["status"], "needs_mana_base_profile_before_named_cards")
        self.assertEqual(hypothesis["review_candidates"], [])
        self.assertIn("mana_source_and_untapped_land_profile", hypothesis["required_gates"])

    def test_wincon_gap_requires_commander_source_lane_without_generic_staples(self) -> None:
        tmp, path = self._db()
        self.addCleanup(tmp.cleanup)

        payload = audit.build_report(
            core_payload={
                "artifact_type": "global_commander_core_role_audit",
                "decks": [core_row(deck_id="620", commander="Sauron, the Dark Lord", role="wincon", missing=3)],
            },
            sqlite_db=path,
            staple_limit=5,
        )

        [hypothesis] = payload["hypotheses"]
        self.assertEqual(hypothesis["status"], "needs_commander_win_plan_source_lane")
        self.assertEqual(hypothesis["review_candidates"], [])
        self.assertIn("commander_win_plan_or_spellbook_source_lane", hypothesis["required_gates"])


if __name__ == "__main__":
    unittest.main()
