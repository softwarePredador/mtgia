#!/usr/bin/env python3
"""Tests for Commander profile repair candidate modeling."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_repair_candidate_model as model


def strategy_payload(*, blockers: list[str]) -> dict[str, object]:
    return {
        "status": "package_strategy_blocks_battle" if blockers else "package_strategy_ready_for_battle_probe",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "input_artifacts": {"candidate_db": "candidate.db"},
        "blocker_reasons": blockers,
        "candidate_expected_package_presence": {
            "angels_demons_dragons_payoffs": {
                "missing_cards": ["Ancient Copper Dragon"],
            },
            "interaction_and_resets": {
                "missing_cards": ["Despark"],
            },
            "commander_attack_enablers": {
                "missing_cards": ["Arena of Glory"],
            },
        },
        "package_delta": [
            {
                "action": "cut",
                "card": "Genji Glove",
                "risk_flags": ["attack_window_or_extra_combat_cut"],
            }
        ],
    }


def repair_payload(*, add_payoff_shortfall: int = 18, axes: list[str] | None = None) -> dict[str, object]:
    axes = axes or ["lands", "angels_demons_dragons_payoffs", "spot_interaction", "commander_attack_window"]
    action_by_axis = {
        "lands": {
            "blocker": "profile_lands_below_target",
            "repair_axis": "lands",
            "candidate_count": 34,
            "target_min": 35,
            "target_max": 37,
            "shortfall_to_min": 1,
        },
        "angels_demons_dragons_payoffs": {
            "blocker": "profile_angels_demons_dragons_payoffs_below_target",
            "repair_axis": "angels_demons_dragons_payoffs",
            "candidate_count": 4,
            "target_min": 22,
            "target_max": 30,
            "shortfall_to_min": add_payoff_shortfall,
        },
        "spot_interaction": {
            "blocker": "profile_spot_interaction_below_target",
            "repair_axis": "spot_interaction",
            "candidate_count": 6,
            "target_min": 8,
            "target_max": 12,
            "shortfall_to_min": 1,
        },
        "commander_attack_window": {
            "blocker": "attack_window_cut_without_replacement",
            "repair_axis": "commander_attack_window",
            "shortfall_to_min": 0,
        },
    }
    return {
        "status": "profile_blocker_repair_plan_ready",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "repair_actions": [action_by_axis[axis] for axis in axes],
        "over_target_review_roles": [{"role": "tutors_access", "candidate_count": 12, "max": 8}],
    }


class GlobalCommanderProfileRepairCandidateModelTests(unittest.TestCase):
    def _db(self, root: Path) -> Path:
        path = root / "candidate.db"
        conn = sqlite3.connect(path)
        conn.execute(
            """
            CREATE TABLE deck_cards (
              deck_id TEXT,
              card_name TEXT,
              quantity INTEGER,
              functional_tag TEXT,
              functional_tags_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              cmc REAL,
              is_commander INTEGER,
              card_id TEXT
            )
            """
        )
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
        deck_rows = [
            (
                "619",
                "Kaalia of the Vast",
                1,
                "",
                "[]",
                "Legendary Creature - Human Cleric",
                "Flying. Whenever Kaalia attacks, put an Angel, Demon, or Dragon from your hand onto the battlefield.",
                4,
                1,
                "kaalia",
            ),
            ("619", "Land", 34, "land", '["land"]', "Basic Land - Plains", "{T}: Add {W}.", 0, 0, "land"),
            (
                "619",
                "Vampiric Tutor",
                1,
                "",
                "[]",
                "Instant",
                "Search your library for a card, then shuffle and put that card on top.",
                1,
                0,
                "vamp",
            ),
        ]
        conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
        oracle_rows = [
            (
                "Kaalia of the Vast",
                "kaalia of the vast",
                "{1}{R}{W}{B}",
                '["B","R","W"]',
                '["B","R","W"]',
                "Legendary Creature - Human Cleric",
                "Flying. Whenever Kaalia attacks, put an Angel, Demon, or Dragon from your hand onto the battlefield.",
                4,
                "",
                "kaalia",
            ),
            ("City of Brass", "city of brass", "", "[]", "[]", "Land", "{T}: Add one mana of any color.", 0, "", "city"),
            (
                "Arena of Glory",
                "arena of glory",
                "",
                '["R"]',
                '["R"]',
                "Land",
                "{T}: Add {R}. Target legendary creature gains haste until end of turn.",
                0,
                "",
                "arena",
            ),
            (
                "Ancient Copper Dragon",
                "ancient copper dragon",
                "{4}{R}{R}",
                '["R"]',
                '["R"]',
                "Creature - Elder Dragon",
                "Flying. Whenever this creature deals combat damage to a player, roll a d20 and create Treasure tokens.",
                6,
                "",
                "copper",
            ),
            (
                "Despark",
                "despark",
                "{W}{B}",
                '["B","W"]',
                '["B","W"]',
                "Instant",
                "Exile target permanent with mana value 4 or greater.",
                2,
                "",
                "despark",
            ),
            (
                "Vampiric Tutor",
                "vampiric tutor",
                "{B}",
                '["B"]',
                '["B"]',
                "Instant",
                "Search your library for a card, then shuffle and put that card on top.",
                1,
                "",
                "vamp",
            ),
        ]
        conn.executemany("INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", oracle_rows)
        for name in ["City of Brass", "Arena of Glory", "Ancient Copper Dragon", "Despark", "Vampiric Tutor"]:
            conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal')", (name,))
        conn.commit()
        conn.close()
        return path

    def _json(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_blocks_materialization_when_payoff_shortfall_exceeds_ready_candidates(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root)
        strategy = self._json(
            root,
            "strategy.json",
            strategy_payload(
                blockers=[
                    "profile_lands_below_target",
                    "profile_angels_demons_dragons_payoffs_below_target",
                    "profile_spot_interaction_below_target",
                    "attack_window_cut_without_replacement",
                ]
            ),
        )
        repair = self._json(root, "repair.json", repair_payload())

        report = model.build_report(repair_plan_report=repair, strategy_report=strategy, sqlite_db=db)

        self.assertEqual(report["status"], "profile_repair_candidate_model_blocks_materialization")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertIn(
            "angels_demons_dragons_payoffs:needs_broader_commander_payoff_source_lane_before_materialization",
            report["candidate_copy_blockers"],
        )
        attack_pool = next(pool for pool in report["repair_axis_pools"] if pool["repair_axis"] == "commander_attack_window")
        self.assertEqual(attack_pool["top_add_candidates"][0]["card_name"], "Arena of Glory")
        self.assertIn("lands", attack_pool["top_add_candidates"][0]["profile_roles"])
        cut_names = {row["card_name"] for row in report["global_cut_review_pool"]}
        self.assertIn("Vampiric Tutor", cut_names)

    def test_all_axes_ready_can_open_candidate_copy_gate_without_battle(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        db = self._db(root)
        strategy = self._json(
            root,
            "strategy.json",
            strategy_payload(blockers=["profile_spot_interaction_below_target"]),
        )
        repair = self._json(
            root,
            "repair.json",
            repair_payload(axes=["spot_interaction"]),
        )

        report = model.build_report(repair_plan_report=repair, strategy_report=strategy, sqlite_db=db)

        self.assertEqual(report["status"], "profile_repair_candidate_model_ready_for_candidate_copy")
        self.assertTrue(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        spot_pool = report["repair_axis_pools"][0]
        self.assertEqual(spot_pool["top_add_candidates"][0]["card_name"], "Despark")


if __name__ == "__main__":
    unittest.main()
