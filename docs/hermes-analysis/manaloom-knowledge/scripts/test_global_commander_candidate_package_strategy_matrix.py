#!/usr/bin/env python3
"""Tests for Commander candidate package strategy matrix."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_package_strategy_matrix as matrix


def package_chain_payload(*, adds: list[str], cuts: list[str]) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "materializer_chain_pass": True,
            "core_floor_repaired": True,
            "strategy_ready": True,
            "package_adds": adds,
            "package_cuts": cuts,
            "final_candidate_db": "candidate.db",
        }
    }


class GlobalCommanderCandidatePackageStrategyMatrixTests(unittest.TestCase):
    def _db(self, root: Path, name: str, rows: list[tuple[str, int, str, str, str]]) -> Path:
        path = root / name
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
              is_commander INTEGER
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES ('619', ?, ?, ?, ?, ?, ?, 0)",
            rows,
        )
        conn.commit()
        conn.close()
        return path

    def _chain(self, root: Path, payload: dict[str, object]) -> Path:
        path = root / "package.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_blocks_battle_when_profile_targets_and_attack_window_regress(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        base_rows = [
            ("Land", 34, "land", '["land"]', "Land", ""),
            ("Genji Glove", 1, "", "[]", "Artifact - Equipment", "Equipped creature has double strike. Whenever equipped creature attacks, untap it. After this phase, there is an additional combat phase."),
            ("Grim Tutor", 1, "", "[]", "Sorcery", "Search your library for a card, put that card into your hand, then shuffle."),
        ]
        candidate_rows = [
            ("Land", 34, "land", '["land"]', "Land", ""),
            ("Path to Exile", 1, "removal", '["removal"]', "Instant", "Exile target creature."),
            ("Swords to Plowshares", 1, "removal", '["removal"]', "Instant", "Exile target creature."),
            ("Terminate", 1, "removal", '["removal"]', "Instant", "Destroy target creature."),
        ]
        base = self._db(root, "base.db", base_rows)
        candidate = self._db(root, "candidate.db", candidate_rows)
        chain = self._chain(
            root,
            package_chain_payload(
                adds=["Path to Exile", "Swords to Plowshares", "Terminate"],
                cuts=["Genji Glove", "Grim Tutor"],
            ),
        )

        report = matrix.build_report(package_chain_report=chain, base_db=base, candidate_db=candidate)

        self.assertEqual(report["status"], "package_strategy_blocks_battle")
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertIn("profile_lands_below_target", report["blocker_reasons"])
        self.assertIn("profile_spot_interaction_below_target", report["blocker_reasons"])
        self.assertIn("attack_window_cut_without_replacement", report["blocker_reasons"])

    def test_ready_package_can_open_equal_battle_probe_without_promotion(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        rows = []
        rows.append(("Land", 35, "land", '["land"]', "Land", ""))
        rows.append(("Ramp", 10, "ramp", '["ramp"]', "Artifact", "{T}: Add one mana."))
        rows.append(("Protection", 8, "protection", '["protection"]', "Instant", "Target creature gains indestructible and hexproof."))
        rows.append(("Angel Payoff", 22, "wincon", '["wincon"]', "Creature - Angel", "Flying. Deals damage to each opponent."))
        rows.append(("Removal", 8, "removal", '["removal"]', "Instant", "Destroy target creature."))
        rows.append(("Wipe", 2, "board_wipe", '["board_wipe"]', "Sorcery", "Destroy all creatures."))
        rows.append(("Draw", 7, "draw", '["draw"]', "Sorcery", "Draw two cards."))
        rows.append(("Tutor", 4, "tutor", '["tutor"]', "Sorcery", "Search your library for a card."))
        rows.append(("Reanimate", 3, "recursion", '["recursion"]', "Sorcery", "Return target creature card from your graveyard to the battlefield."))
        rows.append(("Win", 3, "wincon", '["wincon"]', "Creature - Demon", "Each opponent loses 3 life."))
        base = self._db(root, "base.db", rows)
        candidate = self._db(root, "candidate.db", rows + [("Bedevil", 1, "removal", '["removal"]', "Instant", "Destroy target artifact, creature, or planeswalker.")])
        chain = self._chain(
            root,
            package_chain_payload(adds=["Bedevil"], cuts=[]),
        )

        report = matrix.build_report(package_chain_report=chain, base_db=base, candidate_db=candidate)

        self.assertEqual(report["status"], "package_strategy_ready_for_battle_probe")
        self.assertTrue(report["battle_gate_allowed_now"])
        self.assertFalse(report["promotion_allowed"])
        self.assertEqual(report["blocker_reasons"], [])

    def test_profile_role_classifier_handles_path_and_modal_removal(self) -> None:
        path_roles = matrix.profile_roles_for_card(
            {
                "card_name": "Path to Exile",
                "functional_tag": "removal",
                "functional_tags_json": '["removal"]',
                "type_line": "Instant",
                "oracle_text": (
                    "Exile target creature. Its controller may search their library "
                    "for a basic land card, put that card onto the battlefield tapped, then shuffle."
                ),
                "quantity": 1,
            }
        )
        rakdos_roles = matrix.profile_roles_for_card(
            {
                "card_name": "Rakdos Charm",
                "functional_tag": "removal",
                "functional_tags_json": '["removal"]',
                "type_line": "Instant",
                "oracle_text": (
                    "Choose one - Exile all graveyards; or destroy target artifact; "
                    "or each creature deals 1 damage to its controller."
                ),
                "quantity": 1,
            }
        )

        self.assertEqual(path_roles, {"spot_interaction"})
        self.assertIn("spot_interaction", rakdos_roles)
        self.assertIn("board_wipes_resets", rakdos_roles)


if __name__ == "__main__":
    unittest.main()
