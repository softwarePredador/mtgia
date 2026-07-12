#!/usr/bin/env python3
"""Unit tests for the global all-card Oracle/battle readiness router."""

from __future__ import annotations

import inspect
import unittest

import global_card_oracle_battle_readiness as audit


def base_card(**overrides):
    card = {
        "oracle_id_present": True,
        "oracle_text_present": True,
        "type_line_present": True,
        "legality_format_count": 1,
        "oracle_identity_legality_format_count": 0,
        "commander_legality_status": "legal",
        "trusted_rule_count": 0,
        "unverified_executable_rule_count": 0,
        "runtime_requirement": "card_specific_rule_required",
        "oracle_identity_trusted_rule_count": 0,
        "trusted_missing_hash_count": 0,
    }
    card.update(overrides)
    return card


class GlobalCardOracleBattleReadinessTest(unittest.TestCase):
    def test_scope_query_starts_from_cards_not_deck_cards(self) -> None:
        source = inspect.getsource(audit.fetch_all_card_rows)
        self.assertIn("FROM cards c", source)
        self.assertIn("LEFT JOIN deck_usage du", source)

    def test_oracle_identity_rule_copy_precedes_new_mapper_work(self) -> None:
        lanes = audit.lane_for_card(
            base_card(oracle_identity_trusted_rule_count=2)
        )
        self.assertIn("oracle_identity_rule_link_or_copy", lanes)
        self.assertNotIn("battle_family_mapper_required", lanes)

    def test_active_auto_without_verified_rule_requires_verification_not_mapper(self) -> None:
        lanes = audit.lane_for_card(
            base_card(unverified_executable_rule_count=1)
        )
        self.assertEqual(lanes, ["battle_rule_verification_required"])
        self.assertNotIn("battle_family_mapper_required", lanes)
        self.assertNotIn("battle_and_oracle_ready", lanes)

    def test_oracle_identity_legality_copy_is_separate_candidate_lane(self) -> None:
        lanes = audit.lane_for_card(
            base_card(legality_format_count=0, oracle_identity_legality_format_count=22)
        )
        self.assertIn("oracle_identity_legalities_copy_candidate", lanes)
        self.assertNotIn("legalities_sync", lanes)

    def test_generic_runtime_gap_is_not_card_specific_mapper(self) -> None:
        lanes = audit.lane_for_card(
            base_card(runtime_requirement="generic_or_data_gate")
        )
        self.assertEqual(lanes, ["generic_runtime_or_no_card_rule"])

    def test_empty_oracle_text_generic_candidate_is_not_data_sync(self) -> None:
        lanes = audit.lane_for_card(
            base_card(oracle_text_present=False, runtime_requirement="generic_or_data_gate")
        )
        self.assertNotIn("oracle_data_sync", lanes)
        self.assertEqual(lanes, ["generic_runtime_or_no_card_rule"])

    def test_empty_oracle_text_non_generic_still_requires_data_sync(self) -> None:
        lanes = audit.lane_for_card(
            base_card(oracle_text_present=False, runtime_requirement="card_specific_rule_required")
        )
        self.assertIn("oracle_data_sync", lanes)

    def test_known_digital_oracle_identity_exception_is_not_oracle_sync(self) -> None:
        lanes = audit.lane_for_card(
            base_card(
                name="A-Unholy Heat",
                oracle_id_present=False,
                commander_legality_status="not_legal",
                legality_format_count=3,
            )
        )
        self.assertIn("official_oracle_identity_unavailable", lanes)
        self.assertIn("digital_non_commander_rule_exception", lanes)
        self.assertNotIn("oracle_data_sync", lanes)
        self.assertNotIn("battle_family_mapper_required", lanes)

    def test_face_derived_field_uses_single_oracle_identity(self) -> None:
        faces = [
            {
                "oracle_id": "d3a0b660-358c-41bd-9cd2-41fbf3491b1a",
                "oracle_text": "Flying\n{T}: Add one mana of any color.",
            },
            {
                "oracle_id": "d3a0b660-358c-41bd-9cd2-41fbf3491b1a",
                "oracle_text": "Flying\n{T}: Add one mana of any color.",
            },
        ]
        self.assertEqual(
            audit.face_derived_field(faces, "oracle_id"),
            "d3a0b660-358c-41bd-9cd2-41fbf3491b1a",
        )
        self.assertEqual(
            audit.face_derived_field(faces, "oracle_text"),
            "Flying\n{T}: Add one mana of any color.",
        )

    def test_card_family_uses_effect_text_semantics(self) -> None:
        self.assertEqual(
            audit.card_family("Sorcery", "Create two 1/1 red Goblin creature tokens."),
            "token_creation",
        )
        self.assertEqual(
            audit.card_family("Instant", "Counter target spell."),
            "counterspell_or_stack_interaction",
        )

    def test_priority_score_ignores_registered_deck_usage(self) -> None:
        base = {
            "lanes": ["battle_family_mapper_required"],
            "commander_legality_status": "legal",
            "ready_product_deck_count": 0,
            "commander_slot_count": 0,
            "deck_count": 0,
            "total_quantity": 0,
        }
        registered_deck_heavy = {
            **base,
            "ready_product_deck_count": 12,
            "commander_slot_count": 4,
            "deck_count": 99,
            "total_quantity": 999,
        }
        self.assertEqual(audit.priority_score(base), audit.priority_score(registered_deck_heavy))

    def test_verification_lane_sorts_above_new_mapper_work(self) -> None:
        mapper = {
            "lanes": ["battle_family_mapper_required"],
            "commander_legality_status": "legal",
        }
        verification = {
            "lanes": ["battle_rule_verification_required"],
            "commander_legality_status": "legal",
        }
        self.assertGreater(audit.priority_score(verification), audit.priority_score(mapper))


if __name__ == "__main__":
    unittest.main()
