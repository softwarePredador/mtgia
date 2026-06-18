#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().with_name("auto_promote_battle_rules.py")


def _load_module():
    spec = importlib.util.spec_from_file_location("auto_promote_battle_rules_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


auto_promote = _load_module()


class AutoPromoteBattleRulesTests(unittest.TestCase):
    def test_decide_card_promotion_skips_multi_rule_name(self) -> None:
        decision = auto_promote.decide_card_promotion(
            [
                {
                    "logical_rule_key": "rule-a",
                    "review_status": "needs_review",
                    "source": "generated",
                    "execution_status": "auto",
                    "age_hours": 48,
                },
                {
                    "logical_rule_key": "rule-b",
                    "review_status": "verified",
                    "source": "curated",
                    "execution_status": "executable",
                    "age_hours": 48,
                },
            ],
            {"severities": {"medium"}, "count": 2, "has_needs_review": True},
            12,
        )

        self.assertEqual(decision["decision"], "skip_multi_rule")
        self.assertEqual(
            decision["logical_rule_keys"],
            ["rule-a", "rule-b"],
        )

    def test_decide_card_promotion_promotes_single_needs_review_rule(self) -> None:
        decision = auto_promote.decide_card_promotion(
            [
                {
                    "logical_rule_key": "rule-a",
                    "review_status": "needs_review",
                    "source": "generated",
                    "execution_status": "auto",
                    "age_hours": 24,
                }
            ],
            {"severities": {"medium"}, "count": 1, "has_needs_review": True},
            12,
        )

        self.assertEqual(decision["decision"], "promote_needs_review")
        self.assertEqual(decision["row"]["logical_rule_key"], "rule-a")


if __name__ == "__main__":
    unittest.main()
