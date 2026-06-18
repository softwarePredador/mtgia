#!/usr/bin/env python3
from __future__ import annotations

import unittest

from audit_known_cards_runtime_environment import build_summary


class AuditKnownCardsRuntimeEnvironmentTests(unittest.TestCase):
    def test_pass_when_runtime_is_canonical_and_clean(self) -> None:
        summary = build_summary(
            git_branch="master",
            git_sha="abc1234",
            handcrafted_count=0,
            manual_waiver_count=0,
            manual_waiver_names=[],
            canonical_fallback_count=10,
            known_cards_count=100,
            canonical_snapshot_exists=True,
            generated_exists=True,
        )
        self.assertEqual(summary["status"], "PASS")
        self.assertEqual(summary["findings"], [])

    def test_flags_docs_branch_legacy_inventory_and_missing_snapshot(self) -> None:
        summary = build_summary(
            git_branch="codex/hermes-analysis-docs",
            git_sha="deadbee",
            handcrafted_count=468,
            manual_waiver_count=0,
            manual_waiver_names=[],
            canonical_fallback_count=0,
            known_cards_count=2069,
            canonical_snapshot_exists=False,
            generated_exists=True,
        )
        self.assertEqual(summary["status"], "PASS_WITH_RISKS")
        self.assertIn("legacy_handcrafted_inventory_active", summary["findings"])
        self.assertIn("canonical_snapshot_missing", summary["findings"])
        self.assertIn(
            "docs_branch_runtime_requires_triage_against_master",
            summary["findings"],
        )

    def test_flags_unapproved_runtime_waiver(self) -> None:
        summary = build_summary(
            git_branch="master",
            git_sha="abc1234",
            handcrafted_count=0,
            manual_waiver_count=1,
            manual_waiver_names=["Mox Amber"],
            canonical_fallback_count=10,
            known_cards_count=100,
            canonical_snapshot_exists=True,
            generated_exists=True,
        )
        self.assertEqual(summary["status"], "PASS_WITH_RISKS")
        self.assertIn("manual_runtime_waiver_unapproved", summary["findings"])


if __name__ == "__main__":
    unittest.main()
