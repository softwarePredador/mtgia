#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import unittest

import xmage_transition_nominal_review as review


OLD_METALLIC = """
public final class MetallicMimic {
  // Old Oracle wording.
  staticText = "Each other creature you control of the chosen type enters the battlefield with an additional +1/+1 counter on it";
  boolean applies() { return true; }
}
"""

NEW_METALLIC = """
public final class MetallicMimic {
  // New Oracle wording.
  staticText = "Each other creature you control of the chosen type enters with an additional +1/+1 counter on it";
  boolean applies() { return true; }
}
"""

OLD_KRARK = """
class KrarkTheThumbless {
  boolean apply() { return true; }
}
"""

NEW_KRARK = """
class KrarkTheThumbless {
  // TODO: need copy tests, see #12911
  boolean apply() { return true; }
}
"""

OLD_MJOLNIR = """
class MjolnirHammerOfThor {
  Ability channel = new ChannelAbility("cost", effect);
}
"""

NEW_MJOLNIR = """
class MjolnirHammerOfThor {
  Ability channel = new ChannelAbility("cost", effect, TimingRule.INSTANT, false);
}
"""


class XMageTransitionNominalReviewTests(unittest.TestCase):
    def setUp(self) -> None:
        self.from_pin = "1" * 40
        self.to_pin = "2" * 40
        self.sources = {
            (self.from_pin, "MetallicMimic.java"): OLD_METALLIC,
            (self.to_pin, "MetallicMimic.java"): NEW_METALLIC,
            (self.from_pin, "KrarkTheThumbless.java"): OLD_KRARK,
            (self.to_pin, "KrarkTheThumbless.java"): NEW_KRARK,
            (self.from_pin, "MjolnirHammerOfThor.java"): OLD_MJOLNIR,
            (self.to_pin, "MjolnirHammerOfThor.java"): NEW_MJOLNIR,
        }
        self.diffs = {
            "MetallicMimic.java": b"metallic exact diff",
            "KrarkTheThumbless.java": b"krark exact diff",
            "MjolnirHammerOfThor.java": b"mjolnir exact diff",
        }
        self.evidence = {
            "transition_id": "fixture-transition",
            "from_pin": self.from_pin,
            "to_pin": self.to_pin,
            "modified_change_scope": {
                "executable_or_mixed_classes": ["MjolnirHammerOfThor"],
                "comment_only_classes": ["KrarkTheThumbless"],
            },
            "card_data_diagnostics": {"actionable_findings": []},
            "cards": [
                {
                    "card_name": "Metallic Mimic",
                    "class": "MetallicMimic",
                    "source_path": "MetallicMimic.java",
                    "change_kind": "modified",
                    "runtime_catalog_status": "supported",
                    "direct_test_references": ["MetallicMimicTest.java"],
                    "focused_test_case_count": 3,
                    "source_warning_markers": [],
                    "disposition": (
                        "catalog_supported_nominal_test_passed_"
                        "semantic_review_required"
                    ),
                },
                {
                    "card_name": "Krark, the Thumbless",
                    "class": "KrarkTheThumbless",
                    "source_path": "KrarkTheThumbless.java",
                    "change_kind": "modified",
                    "runtime_catalog_status": "supported",
                    "direct_test_references": ["KrarkTest.java"],
                    "focused_test_case_count": 1,
                    "source_warning_markers": [{"marker": "TODO"}],
                    "disposition": (
                        "catalog_supported_nominal_test_passed_"
                        "semantic_review_required"
                    ),
                },
                {
                    "card_name": "Mjolnir, Hammer of Thor",
                    "class": "MjolnirHammerOfThor",
                    "source_path": "MjolnirHammerOfThor.java",
                    "change_kind": "modified",
                    "runtime_catalog_status": "supported",
                    "direct_test_references": ["MjolnirTest.java"],
                    "focused_test_case_count": 2,
                    "source_warning_markers": [],
                    "disposition": (
                        "catalog_supported_nominal_test_passed_"
                        "semantic_review_required"
                    ),
                },
                {
                    "card_name": "Catalog Only",
                    "class": "CatalogOnly",
                    "source_path": "CatalogOnly.java",
                    "change_kind": "added",
                    "runtime_catalog_status": "supported",
                    "direct_test_references": [],
                    "focused_test_case_count": 0,
                    "source_warning_markers": [],
                    "disposition": "catalog_supported_semantic_review_required",
                },
            ],
        }
        self.policy = {
            "schema_version": review.POLICY_SCHEMA_VERSION,
            "transition_id": "fixture-transition",
            "from_pin": self.from_pin,
            "to_pin": self.to_pin,
            "catalog_resolution_is_semantic_proof": False,
            "automatic_transition_clearance_rules": [
                {
                    "id": "metallic",
                    "card_name": "Metallic Mimic",
                    "class": "MetallicMimic",
                    "source_path": "MetallicMimic.java",
                    "change_kind": "modified",
                    "required_change_scope": "presentation_or_metadata",
                    "exact_diff_sha256": hashlib.sha256(
                        self.diffs["MetallicMimic.java"]
                    ).hexdigest(),
                    "required_direct_test_references": [
                        "MetallicMimicTest.java"
                    ],
                    "required_focused_test_case_count": 3,
                    "require_no_source_warning_markers": True,
                    "require_no_card_data_actionable_finding": True,
                    "allowed_presentation_literal_changes": [
                        {
                            "old": (
                                '"Each other creature you control of the chosen '
                                "type enters the battlefield with an additional "
                                '+1/+1 counter on it"'
                            ),
                            "new": (
                                '"Each other creature you control of the chosen '
                                "type enters with an additional +1/+1 counter "
                                'on it"'
                            ),
                            "occurrences": 1,
                        }
                    ],
                }
            ],
        }

    def _source_lookup(self, commit: str, source_path: str) -> str | None:
        return self.sources.get((commit, source_path))

    def _diff_lookup(
        self,
        _from_pin: str,
        _to_pin: str,
        source_path: str,
    ) -> bytes:
        return self.diffs.get(source_path, b"")

    def _report(
        self,
        *,
        evidence: dict | None = None,
        policy: dict | None = None,
    ) -> dict:
        return review.build_report(
            evidence or self.evidence,
            policy or self.policy,
            source_lookup=self._source_lookup,
            diff_lookup=self._diff_lookup,
        )

    def test_exact_presentation_hunk_can_reduce_one_review(self) -> None:
        report = self._report()

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertEqual(report["exact_clearance_cards"], ["Metallic Mimic"])
        self.assertEqual(
            report["summary"]["review_required_before_exact_clearance"],
            4,
        )
        self.assertEqual(
            report["summary"]["review_required_after_exact_clearance"],
            3,
        )
        metallic = next(
            row
            for row in report["existing_nominal_cards"]
            if row["card_name"] == "Metallic Mimic"
        )
        self.assertEqual(
            metallic["lane"],
            "exact_presentation_hunk_and_nominal_tests_clearance",
        )

    def test_comment_only_known_risk_stays_pending(self) -> None:
        report = self._report()
        krark = next(
            row
            for row in report["existing_nominal_cards"]
            if row["card_name"] == "Krark, the Thumbless"
        )

        self.assertTrue(krark["comment_only_proven"])
        self.assertEqual(
            krark["lane"],
            "no_executable_card_delta_known_upstream_risk",
        )
        self.assertIsNone(krark["clearance_rule_id"])

    def test_executable_hunk_stays_pending_when_nominal_test_misses_it(self) -> None:
        report = self._report()
        mjolnir = next(
            row
            for row in report["existing_nominal_cards"]
            if row["card_name"] == "Mjolnir, Hammer of Thor"
        )

        self.assertEqual(
            mjolnir["lane"],
            "nominal_tests_do_not_cover_executable_hunk",
        )
        self.assertIsNone(mjolnir["clearance_rule_id"])

    def test_catalog_support_without_test_never_clears(self) -> None:
        report = self._report()

        self.assertNotIn("Catalog Only", report["exact_clearance_cards"])
        self.assertFalse(
            report["safety"]["catalog_resolution_used_as_semantic_proof"]
        )

    def test_wrong_diff_hash_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "exact_diff_sha256"
        ] = "0" * 64

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["exact_clearance_cards"], [])
        failure_ids = {row["id"] for row in report["failures"]}
        self.assertIn("clearance_rule:metallic", failure_ids)

    def test_actionable_card_data_finding_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["card_data_diagnostics"]["actionable_findings"] = [
            {"card_name": "Metallic Mimic"}
        ]

        report = self._report(evidence=evidence)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["exact_clearance_cards"], [])


if __name__ == "__main__":
    unittest.main()
