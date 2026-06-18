#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "audit_commander_generator_source_mix.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "audit_commander_generator_source_mix_under_test",
        MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


audit = load_module()


class AuditCommanderGeneratorSourceMixTests(unittest.TestCase):
    def test_build_summary_classifies_expected_buckets(self) -> None:
        payload = {
            "commander_name": "Lorehold, the Historian",
            "artifact_dir": "artifact-dir",
            "deterministic_deck": {
                "built": True,
                "main_count": 99,
                "distinct_card_count": 99,
                "runtime_build_diagnostics": {
                    "source_mix_counts": {"x": 1},
                    "source_usage_counts": {"deterministic_fallback": 4},
                    "built_in_fallback_used_count": 4,
                    "built_in_fallback_only_count": 1,
                },
                "cards": [
                    {"card_name": "Fallback Only", "sources": ["deterministic_fallback"]},
                    {
                        "card_name": "Learned Fallback",
                        "sources": ["active_learned_deck", "deterministic_fallback"],
                    },
                    {
                        "card_name": "Fallback No Stats",
                        "sources": ["deterministic_fallback", "usage_hot_cards"],
                    },
                    {
                        "card_name": "Fallback Profile Stats Only",
                        "sources": [
                            "deterministic_fallback",
                            "profile_expected_packages",
                            "reference_card_stats",
                        ],
                    },
                    {
                        "card_name": "Supported No Fallback",
                        "sources": ["active_learned_deck"],
                    },
                ],
            },
        }

        summary = audit.build_summary(payload)

        self.assertEqual(summary["fallback_touched_count"], 4)
        self.assertEqual(summary["fallback_only_count"], 1)
        self.assertEqual(summary["fallback_only_cards"], ["Fallback Only"])
        self.assertEqual(summary["learned_plus_fallback_only_count"], 1)
        self.assertEqual(
            summary["learned_plus_fallback_only_cards"],
            ["Learned Fallback"],
        )
        self.assertEqual(summary["fallback_without_profile_or_stats_count"], 3)
        self.assertEqual(
            summary["fallback_without_profile_or_stats_cards"],
            ["Fallback No Stats", "Fallback Only", "Learned Fallback"],
        )
        self.assertEqual(summary["fallback_profile_stats_only_count"], 1)
        self.assertEqual(
            summary["fallback_profile_stats_no_empirical_support_count"],
            1,
        )
        self.assertFalse(summary["all_fallback_have_non_fallback_source"])
        self.assertEqual(
            [entry["code"] for entry in summary["priorities"]],
            [
                "fallback_only_slots",
                "learned_plus_fallback_only",
                "fallback_without_profile_or_stats",
                "fallback_profile_stats_no_empirical_support",
            ],
        )


if __name__ == "__main__":
    unittest.main()
