#!/usr/bin/env python3
from __future__ import annotations

import unittest

import xmage_batch_validity_audit as audit


def coherence_card(name: str, type_line: str = "Artifact") -> dict:
    return {
        "card_name": name,
        "severity": "high",
        "type_line": type_line,
        "findings": [{"code": "no_active_battle_rule"}],
    }


def xmage_card(
    name: str,
    *,
    status: str = "found",
    mana_cost: str = "{3}",
    types: list[str] | None = None,
    effect: str = "structured_effect",
    include_test_scenarios: bool = True,
) -> dict:
    if status != "found":
        return {"card_name": name, "status": status, "candidate_class_names": ["MissingCard"]}
    card = {
        "card_name": name,
        "status": "found",
        "xmage_class_name": "TestCard",
        "target_classes": ["TargetOpponent"],
        "constructor_metadata": {
            "mana_cost": mana_cost,
            "card_types": types or ["ARTIFACT"],
            "subtypes": [],
        },
        "candidate_effect_hints": {
            "primary_candidate": {
                "effect_json": {
                    "effect": effect,
                    "battle_model_scope": "structured_scope_v1",
                }
            }
        },
    }
    if include_test_scenarios:
        card["suggested_test_scenarios"] = [
            {
                "id": "ready_card_1",
                "title": "structured effect resolves",
                "setup": "legal deterministic board",
                "actions": "cast or activate the card",
                "assertions": "final state matches expected model",
            }
        ]
    return card


def external_card(name: str, *, mana_cost: str = "{3}", type_line: str = "Artifact") -> dict:
    return {
        "card_name": name,
        "external_references": {
            "scryfall": {
                "status": "found",
                "mana_cost": mana_cost,
                "type_line": type_line,
            }
        },
    }


class XMageBatchValidityAuditTests(unittest.TestCase):
    def test_actionable_coherence_card_skips_trusted_rule_with_only_oracle_hash_gap(self) -> None:
        card = {
            "card_name": "Covered Card",
            "severity": "medium",
            "findings": [{"code": "trusted_rule_without_oracle_hash"}],
            "trusted_executable_rule_count": 1,
            "review_only_rule_count": 0,
            "active_rule_count": 1,
        }

        self.assertFalse(audit.actionable_coherence_card(card))

    def test_high_medium_cards_keeps_real_rule_gap_and_drops_metadata_only_gap(self) -> None:
        report = {
            "cards": [
                {
                    "card_name": "Covered Card",
                    "severity": "medium",
                    "findings": [{"code": "trusted_rule_without_oracle_hash"}],
                    "trusted_executable_rule_count": 1,
                    "review_only_rule_count": 0,
                    "active_rule_count": 1,
                },
                coherence_card("Needs Work"),
            ]
        }

        actionable = audit.high_medium_cards(report)

        self.assertEqual([card["card_name"] for card in actionable], ["Needs Work"])

    def test_expected_types_from_split_type_line(self) -> None:
        self.assertEqual(
            audit.expected_types_from_type_line("Sorcery // Land"),
            ["LAND", "SORCERY"],
        )
        self.assertEqual(
            audit.expected_types_from_type_line("Legendary Artifact — Infinity Stone"),
            ["ARTIFACT"],
        )

    def test_structured_effect_with_matching_metadata_is_ready_for_pull(self) -> None:
        result = audit.classify_card(
            coherence_card("Ready Card"),
            xmage_card=xmage_card("Ready Card"),
            external_card=external_card("Ready Card"),
        )

        self.assertEqual(result["status"], "ready_for_structured_xmage_pull_review_required")
        self.assertTrue(result["valid_xmage_source"])
        self.assertTrue(result["ready_for_structured_pull"])
        self.assertTrue(result["checks"]["focused_test_scenarios_present"])
        self.assertEqual(result["xmage"]["target_classes"], ["TargetOpponent"])

    def test_generic_manual_effect_requires_mapper(self) -> None:
        result = audit.classify_card(
            coherence_card("Manual Card"),
            xmage_card=xmage_card("Manual Card", effect=audit.MANUAL_EFFECT),
            external_card=external_card("Manual Card"),
        )

        self.assertEqual(result["status"], "xmage_source_valid_mapper_required")
        self.assertTrue(result["valid_xmage_source"])
        self.assertFalse(result["ready_for_structured_pull"])

    def test_structured_effect_without_test_scenario_is_not_ready(self) -> None:
        result = audit.classify_card(
            coherence_card("Needs Test Card"),
            xmage_card=xmage_card("Needs Test Card", include_test_scenarios=False),
            external_card=external_card("Needs Test Card"),
        )

        self.assertEqual(result["status"], "xmage_source_valid_test_scenarios_required")
        self.assertTrue(result["valid_xmage_source"])
        self.assertFalse(result["ready_for_structured_pull"])
        self.assertFalse(result["checks"]["focused_test_scenarios_present"])

    def test_metadata_mismatch_blocks_direct_pull(self) -> None:
        result = audit.classify_card(
            coherence_card("Wrong Card", type_line="Creature"),
            xmage_card=xmage_card("Wrong Card", types=["ARTIFACT"]),
            external_card=external_card("Wrong Card", type_line="Creature"),
        )

        self.assertEqual(result["status"], "xmage_source_found_metadata_mismatch")
        self.assertFalse(result["valid_xmage_source"])
        self.assertFalse(result["ready_for_structured_pull"])

    def test_missing_xmage_class_blocks_direct_pull(self) -> None:
        result = audit.classify_card(
            coherence_card("Missing Card"),
            xmage_card=xmage_card("Missing Card", status="not_found"),
            external_card=external_card("Missing Card"),
        )

        self.assertEqual(result["status"], "blocked_missing_xmage_class")
        self.assertFalse(result["valid_xmage_source"])
        self.assertFalse(result["ready_for_structured_pull"])


if __name__ == "__main__":
    unittest.main()
