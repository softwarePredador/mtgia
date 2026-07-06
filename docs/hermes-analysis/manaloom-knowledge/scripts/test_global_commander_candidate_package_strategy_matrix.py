#!/usr/bin/env python3
"""Tests for Commander candidate package strategy matrix."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import global_commander_candidate_package_strategy_matrix as matrix


def package_chain_payload(
    *,
    adds: list[str],
    cuts: list[str],
    commander: str = "Kaalia of the Vast",
    deck_id: str = "619",
) -> dict[str, object]:
    return {
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "materializer_chain_pass": True,
            "core_floor_repaired": True,
            "strategy_ready": True,
            "package_adds": adds,
            "package_cuts": cuts,
            "final_candidate_db": "candidate.db",
        }
    }


class GlobalCommanderCandidatePackageStrategyMatrixTests(unittest.TestCase):
    def _db(self, root: Path, name: str, rows: list[tuple[str, int, str, str, float, str, str]]) -> Path:
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
              cmc REAL,
              type_line TEXT,
              oracle_text TEXT,
              is_commander INTEGER
            )
            """
        )
        conn.executemany(
            "INSERT INTO deck_cards VALUES ('619', ?, ?, ?, ?, ?, ?, ?, 0)",
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
            ("Land", 34, "land", '["land"]', 0, "Land", ""),
            ("Genji Glove", 1, "", "[]", 3, "Artifact - Equipment", "Equipped creature has double strike. Whenever equipped creature attacks, untap it. After this phase, there is an additional combat phase."),
            ("Grim Tutor", 1, "", "[]", 3, "Sorcery", "Search your library for a card, put that card into your hand, then shuffle."),
        ]
        candidate_rows = [
            ("Land", 34, "land", '["land"]', 0, "Land", ""),
            ("Path to Exile", 1, "removal", '["removal"]', 1, "Instant", "Exile target creature."),
            ("Swords to Plowshares", 1, "removal", '["removal"]', 1, "Instant", "Exile target creature."),
            ("Terminate", 1, "removal", '["removal"]', 2, "Instant", "Destroy target creature."),
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
        rows.append(("Land", 35, "land", '["land"]', 0, "Land", ""))
        rows.append(("Ramp", 10, "ramp", '["ramp"]', 2, "Artifact", "{T}: Add one mana."))
        rows.append(("Protection", 8, "protection", '["protection"]', 1, "Instant", "Target creature gains indestructible and hexproof."))
        rows.append(("Angel Payoff", 22, "wincon", '["wincon"]', 6, "Creature - Angel", "Flying. Deals damage to each opponent."))
        rows.append(("Removal", 8, "removal", '["removal"]', 1, "Instant", "Destroy target creature."))
        rows.append(("Wipe", 2, "board_wipe", '["board_wipe"]', 4, "Sorcery", "Destroy all creatures."))
        rows.append(("Draw", 7, "draw", '["draw"]', 2, "Sorcery", "Draw two cards."))
        rows.append(("Tutor", 4, "tutor", '["tutor"]', 3, "Sorcery", "Search your library for a card."))
        rows.append(("Reanimate", 3, "recursion", '["recursion"]', 2, "Sorcery", "Return target creature card from your graveyard to the battlefield."))
        rows.append(("Win", 3, "wincon", '["wincon"]', 6, "Creature - Demon", "Each opponent loses 3 life."))
        base = self._db(root, "base.db", rows)
        candidate = self._db(root, "candidate.db", rows + [("Bedevil", 1, "removal", '["removal"]', 3, "Instant", "Destroy target artifact, creature, or planeswalker.")])
        chain = self._chain(
            root,
            package_chain_payload(adds=["Bedevil"], cuts=[]),
        )

        report = matrix.build_report(package_chain_report=chain, base_db=base, candidate_db=candidate)

        self.assertEqual(report["status"], "package_strategy_ready_for_battle_probe")
        self.assertTrue(report["battle_gate_allowed_now"])
        self.assertFalse(report["promotion_allowed"])
        self.assertEqual(report["blocker_reasons"], [])

    def test_battle_feedback_blocks_exact_failed_package_before_new_battle(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        base_rows = []
        base_rows.append(("Land", 35, "land", '["land"]', 0, "Land", ""))
        base_rows.append(("Ramp", 10, "ramp", '["ramp"]', 2, "Artifact", "{T}: Add one mana."))
        base_rows.append(("Protection", 8, "protection", '["protection"]', 1, "Instant", "Target creature gains indestructible and hexproof."))
        base_rows.append(("Angel Payoff", 22, "wincon", '["wincon"]', 6, "Creature - Angel", "Flying. Deals damage to each opponent."))
        base_rows.append(("Removal", 8, "removal", '["removal"]', 1, "Instant", "Destroy target creature."))
        base_rows.append(("Wipe", 2, "board_wipe", '["board_wipe"]', 4, "Sorcery", "Destroy all creatures."))
        base_rows.append(("Draw", 7, "draw", '["draw"]', 2, "Sorcery", "Draw two cards."))
        base_rows.append(("Tutor", 4, "tutor", '["tutor"]', 3, "Sorcery", "Search your library for a card."))
        base_rows.append(("Reanimate", 3, "recursion", '["recursion"]', 2, "Sorcery", "Return target creature card from your graveyard to the battlefield."))
        base_rows.append(("Win", 3, "wincon", '["wincon"]', 6, "Creature - Demon", "Each opponent loses 3 life."))
        candidate_rows = [row for row in base_rows if row[0] != "Removal"]
        candidate_rows.append(("Bedevil", 8, "removal", '["removal"]', 3, "Instant", "Destroy target artifact, creature, or planeswalker."))
        base = self._db(root, "base.db", base_rows)
        candidate = self._db(root, "candidate.db", candidate_rows)
        chain = self._chain(root, package_chain_payload(adds=["Bedevil"], cuts=["Removal"]))
        feedback_payload = {
            "package_feedback": [
                {
                    "deck_id": "619",
                    "commander": "Kaalia of the Vast",
                    "added_cards": ["Bedevil"],
                    "cut_cards": ["Removal"],
                    "package_status": "package_blocked_by_protected_baseline_gate",
                    "recommendation": "block_package_until_new_source_lane_cut_or_strategy",
                    "unexercised_added_cards": ["Bedevil"],
                    "worst_candidate_vs_protected_win_delta": -3,
                    "primary_evidence": {"artifact_path": "larger_gate.json"},
                }
            ]
        }

        report = matrix.build_report(
            package_chain_report=chain,
            base_db=base,
            candidate_db=candidate,
            battle_feedback_payload=feedback_payload,
        )

        self.assertEqual(report["status"], "package_strategy_blocks_battle")
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["battle_feedback_blocker_count"], 3)
        self.assertIn("battle_feedback_failed_exact_package", report["blocker_reasons"])
        self.assertIn("battle_feedback_failed_protected_baseline_package", report["blocker_reasons"])
        self.assertIn("battle_feedback_larger_gate_unexercised_added_cards", report["blocker_reasons"])
        self.assertEqual(report["summary"]["next_gate"], "replace_failed_package_source_lane_or_cut_set_before_battle")

    def test_lorehold_profile_blocks_land_floor_package_that_cuts_protected_anchor(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        base_rows = [
            ("Land", 34, "land", '["land"]', 0, "Land", ""),
            (
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                1,
                "engine",
                '["engine","ramp","creature"]',
                3,
                "Legendary Creature - God",
                "Whenever you cast a spell, add {R}. Until end of turn, you don't lose this mana as steps and phases end.",
            ),
            (
                "Pyromancer's Goggles",
                1,
                "ramp",
                '["ramp"]',
                5,
                "Legendary Artifact",
                "{T}: Add {R}. When that mana is spent to cast a red instant or sorcery spell, copy that spell.",
            ),
        ]
        candidate_rows = [
            ("Land", 34, "land", '["land"]', 0, "Land", ""),
            ("Ash Barrens", 1, "land", '["land"]', 0, "Land", "{T}: Add {C}. Basic landcycling {1}."),
        ]
        base = self._db(root, "base.db", base_rows)
        candidate = self._db(root, "candidate.db", candidate_rows)
        chain = self._chain(
            root,
            package_chain_payload(
                commander="Lorehold, the Historian",
                adds=["Ash Barrens"],
                cuts=["Birgi, God of Storytelling // Harnfel, Horn of Bounty", "Pyromancer's Goggles"],
            ),
        )

        report = matrix.build_report(package_chain_report=chain, base_db=base, candidate_db=candidate)

        self.assertEqual(report["status"], "package_strategy_blocks_battle")
        self.assertEqual(report["summary"]["profile_version"], "lorehold_reference_profile_v1_2026-05-11")
        self.assertIn("profile_lands_below_target", report["blocker_reasons"])
        self.assertIn(
            "protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            report["blocker_reasons"],
        )
        self.assertIn(
            "protected_profile_anchor_cut:Pyromancer's Goggles",
            report["blocker_reasons"],
        )
        self.assertFalse(report["battle_gate_allowed_now"])

    def test_profile_role_classifier_handles_path_and_modal_removal(self) -> None:
        path_roles = matrix.profile_roles_for_card(
            {
                "card_name": "Path to Exile",
                "functional_tag": "removal",
                "functional_tags_json": '["removal"]',
                "cmc": 1,
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
                "cmc": 2,
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

    def test_profile_role_classifier_handles_lorehold_setup_and_copy_engine(self) -> None:
        top_roles = matrix.profile_roles_for_card(
            {
                "card_name": "Sensei's Divining Top",
                "functional_tag": "engine",
                "functional_tags_json": '["engine","draw"]',
                "cmc": 1,
                "type_line": "Artifact",
                "oracle_text": "Look at the top three cards of your library, then put them back in any order.",
                "quantity": 1,
            }
        )
        goggles_roles = matrix.profile_roles_for_card(
            {
                "card_name": "Pyromancer's Goggles",
                "functional_tag": "ramp",
                "functional_tags_json": '["ramp"]',
                "cmc": 5,
                "type_line": "Legendary Artifact",
                "oracle_text": "{T}: Add {R}. When that mana is spent to cast a red instant or sorcery spell, copy that spell.",
                "quantity": 1,
            }
        )

        self.assertIn("topdeck_miracle_setup", top_roles)
        self.assertIn("spell_payoffs_copy_engines", goggles_roles)
        self.assertIn("mana_rocks_treasure_ramp", goggles_roles)


if __name__ == "__main__":
    unittest.main()
