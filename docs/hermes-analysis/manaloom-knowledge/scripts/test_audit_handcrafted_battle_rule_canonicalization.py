#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "audit_handcrafted_battle_rule_canonicalization.py"


def load_module():
    spec = importlib.util.spec_from_file_location("audit_handcrafted_canon", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


audit = load_module()


class AuditHandcraftedBattleRuleCanonicalizationTests(unittest.TestCase):
    def test_compare_manual_to_store_exact_match(self) -> None:
        effect = {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"}
        card_name = "Arcane Signet"
        store_rule = {
            "card_name": card_name,
            "effect_json": dict(effect),
            "deck_role_json": audit.deck_role_from_effect(effect),
        }
        store_rule["logical_rule_key"] = audit.logical_rule_key(store_rule)
        self.assertEqual(
            audit.compare_manual_to_store(card_name, effect, store_rule),
            "exact_match",
        )

    def test_classify_temporary_hotfix_when_pg_missing(self) -> None:
        self.assertEqual(
            audit.classify_override(
                "Lightning Greaves",
                {"effect": "equipment_haste_shroud"},
                "missing",
                None,
            ),
            "temporary_hotfix",
        )

    def test_recommended_action_prefers_pg_creation_for_promotable_missing_rule(self) -> None:
        self.assertEqual(
            audit.recommended_action(
                "card_rule_promotable",
                "missing",
                "missing",
                None,
                True,
            ),
            "create_pg_rule",
        )


if __name__ == "__main__":
    unittest.main()
