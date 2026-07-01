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

    def test_card_family_uses_effect_text_semantics(self) -> None:
        self.assertEqual(
            audit.card_family("Sorcery", "Create two 1/1 red Goblin creature tokens."),
            "token_creation",
        )
        self.assertEqual(
            audit.card_family("Instant", "Counter target spell."),
            "counterspell_or_stack_interaction",
        )


if __name__ == "__main__":
    unittest.main()
