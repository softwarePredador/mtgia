#!/usr/bin/env python3
from __future__ import annotations

import json
import sqlite3
import unittest

import lorehold_ideal_deck_candidate_matrix as matrix


class LoreholdIdealDeckCandidateMatrixTests(unittest.TestCase):
    def setUp(self) -> None:
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        self.addCleanup(self.conn.close)
        self.conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                functional_tags_json TEXT,
                is_commander INTEGER,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT,
                battle_rules_json TEXT
            )
            """
        )
        self.conn.execute(
            """
            CREATE TABLE battle_card_rules (
                normalized_name TEXT,
                logical_rule_key TEXT,
                card_name TEXT,
                effect_json TEXT,
                deck_role_json TEXT,
                source TEXT,
                confidence REAL,
                review_status TEXT,
                execution_status TEXT,
                created_at TEXT,
                updated_at TEXT
            )
            """
        )

    def add_card(
        self,
        deck_id: int,
        name: str,
        *,
        tag: str,
        tags: list[str] | None = None,
        cmc: float = 2,
        type_line: str = "Instant",
        oracle_text: str = "",
    ) -> None:
        self.conn.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, functional_tag,
                functional_tags_json, is_commander, cmc, type_line,
                oracle_text, battle_rules_json
            )
            VALUES (?,?,?,?,?,?,?,?,?,?)
            """,
            (
                deck_id,
                name,
                1,
                tag,
                json.dumps(tags if tags is not None else [tag]),
                0,
                cmc,
                type_line,
                oracle_text,
                "[]",
            ),
        )

    def add_rule(self, name: str, *, effect: str, category: str) -> None:
        self.add_rule_with_alias(name, name, effect=effect, category=category)

    def add_rule_with_alias(self, normalized_name: str, card_name: str, *, effect: str, category: str) -> None:
        self.conn.execute(
            """
            INSERT INTO battle_card_rules (
                normalized_name, logical_rule_key, card_name, effect_json,
                deck_role_json, source, confidence, review_status,
                execution_status, created_at, updated_at
            )
            VALUES (?,?,?,?,?,?,?,?,?,?,?)
            """,
            (
                matrix.normalize_name(normalized_name),
                f"{matrix.normalize_name(card_name)}__rule",
                card_name,
                json.dumps({"effect": effect, "battle_model_scope": f"{effect}_v1"}),
                json.dumps({"category": category}),
                "test",
                1.0,
                "verified",
                "auto",
                "now",
                "now",
            ),
        )

    def test_verified_active_variant_card_becomes_core_keep(self) -> None:
        for deck_id in (6, 608, 609):
            self.add_card(
                deck_id,
                "Reliable Protection",
                tag="protection",
                oracle_text="Counter target spell. Draw a card.",
            )
        self.add_rule("Reliable Protection", effect="counter", category="protection")

        report = matrix.build_candidate_matrix(
            self.conn,
            active_deck_id=6,
            deck_ids=[6, 608, 609],
            proposals={},
        )

        row = next(item for item in report["rows"] if item["card_name"] == "Reliable Protection")
        self.assertEqual(row["rule_status"], "battle_ready")
        self.assertEqual(row["recommendation_lane"], "core_keep")
        self.assertGreater(row["score"], 45)

    def test_manual_mapper_candidate_stays_rule_first(self) -> None:
        self.add_card(
            608,
            "Unmapped Tutor",
            tag="tutor",
            oracle_text="Search your library for a card, reveal it, and put it into your hand.",
        )
        proposals = {
            "unmapped tutor": {
                "card_name": "Unmapped Tutor",
                "proposal_status": "mapper_metadata_or_test_scenario_required",
                "effect": "tutor",
                "battle_model_scope": "xmage_reference_requires_manual_model_review_v1",
            }
        }

        report = matrix.build_candidate_matrix(
            self.conn,
            active_deck_id=6,
            deck_ids=[6, 608],
            proposals=proposals,
        )

        row = next(item for item in report["rows"] if item["card_name"] == "Unmapped Tutor")
        self.assertEqual(row["rule_status"], "mapper_manual")
        self.assertEqual(row["recommendation_lane"], "needs_rule_before_strategy")
        self.assertEqual(row["next_action"], "map_or_verify_rule_before_strategy_scoring")

    def test_premium_mox_is_policy_blocked_even_with_good_rule(self) -> None:
        self.add_card(608, "Chrome Mox", tag="ramp", type_line="Artifact", oracle_text="Add one mana.")
        self.add_rule("Chrome Mox", effect="ramp_permanent", category="ramp")

        report = matrix.build_candidate_matrix(
            self.conn,
            active_deck_id=6,
            deck_ids=[6, 608],
            proposals={},
        )

        row = next(item for item in report["rows"] if item["card_name"] == "Chrome Mox")
        self.assertEqual(row["recommendation_lane"], "policy_blocked")
        self.assertEqual(row["score"], -1000.0)
        self.assertEqual(row["next_action"], "exclude_from_lorehold_no_premium_mox_policy")

    def test_basic_lands_do_not_block_strategy_for_missing_rules(self) -> None:
        self.add_card(
            608,
            "Mountain // Mountain",
            tag="land",
            cmc=0,
            type_line="Basic Land — Mountain",
            oracle_text="",
        )

        report = matrix.build_candidate_matrix(
            self.conn,
            active_deck_id=6,
            deck_ids=[6, 608],
            proposals={},
        )

        row = next(item for item in report["rows"] if item["card_name"] == "Mountain // Mountain")
        self.assertEqual(row["rule_status"], "battle_ready")
        self.assertNotEqual(row["recommendation_lane"], "needs_rule_before_strategy")

    def test_battle_rules_match_card_name_alias_when_normalized_face_differs(self) -> None:
        full_name = "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
        self.add_card(
            608,
            full_name,
            tag="ramp",
            tags=["engine", "ramp"],
            cmc=3,
            type_line="Legendary Creature — God",
            oracle_text="Whenever you cast a spell, add R.",
        )
        self.add_rule_with_alias(
            "Birgi, God of Storytelling",
            full_name,
            effect="ramp_engine",
            category="ramp",
        )

        report = matrix.build_candidate_matrix(
            self.conn,
            active_deck_id=6,
            deck_ids=[6, 608],
            proposals={},
        )

        row = next(item for item in report["rows"] if item["card_name"] == full_name)
        self.assertEqual(row["rule_status"], "battle_ready")
        self.assertNotEqual(row["recommendation_lane"], "needs_rule_before_strategy")


if __name__ == "__main__":
    unittest.main()
