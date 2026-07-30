#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import subprocess
import unittest
from unittest import mock

import xmage_transition_nominal_review as review


OLD_METALLIC = """
package mage.cards.m;
import mage.cards.CardImpl;
public final class MetallicMimic {
  // Old Oracle wording.
  staticText = "Each other creature you control of the chosen type enters the battlefield with an additional +1/+1 counter on it";
  boolean applies() { return true; }
}
"""

NEW_METALLIC = """
package mage.cards.m;
import mage.cards.CardImpl;
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
            "MetallicMimic.java": b"canonical metallic full-index diff",
            "KrarkTheThumbless.java": b"canonical krark full-index diff",
            "MjolnirHammerOfThor.java": b"canonical mjolnir full-index diff",
        }
        self.blobs = {
            (self.from_pin, "MetallicMimic.java"): "a" * 40,
            (self.to_pin, "MetallicMimic.java"): "b" * 40,
            (self.from_pin, "KrarkTheThumbless.java"): "c" * 40,
            (self.to_pin, "KrarkTheThumbless.java"): "d" * 40,
            (self.from_pin, "MjolnirHammerOfThor.java"): "e" * 40,
            (self.to_pin, "MjolnirHammerOfThor.java"): "f" * 40,
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
                    "disposition": review.CLEARANCE_DISPOSITION,
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
        literal_changes = [
            {
                "old": (
                    '"Each other creature you control of the chosen type enters '
                    'the battlefield with an additional +1/+1 counter on it"'
                ),
                "new": (
                    '"Each other creature you control of the chosen type enters '
                    'with an additional +1/+1 counter on it"'
                ),
                "occurrences": 1,
            }
        ]
        equivalent, failures, token_digest = (
            review.sources_match_after_exact_non_executable_changes(
                OLD_METALLIC,
                NEW_METALLIC,
                literal_changes=literal_changes,
                allowed_import_delta={"removed": [], "added": []},
                allow_import_reordering=False,
            )
        )
        assert equivalent and not failures and token_digest
        self.policy = {
            "schema_version": review.POLICY_SCHEMA_VERSION,
            "transition_id": "fixture-transition",
            "from_pin": self.from_pin,
            "to_pin": self.to_pin,
            "catalog_resolution_is_semantic_proof": False,
            "canonical_diff_hash_mode": (
                "git_diff_no_ext_diff_no_textconv_unified0_full_index"
            ),
            "requires_full_blob_oids": True,
            "requires_source_sha256": True,
            "unlisted_token_changes_allowed": False,
            "filter_predicate_normalization_allowed": False,
            "string_literal_changes_require_explicit_map": True,
            "import_changes_require_exact_delta": True,
            "automatic_clearance_does_not_activate_runtime_card": True,
            "automatic_transition_clearance_rules": [
                {
                    "id": "metallic",
                    "card_name": "Metallic Mimic",
                    "class": "MetallicMimic",
                    "source_path": "MetallicMimic.java",
                    "change_kind": "modified",
                    "required_change_scope": "presentation_or_metadata",
                    "diff_hash_mode": (
                        "git_diff_no_ext_diff_no_textconv_unified0_full_index"
                    ),
                    "canonical_diff_sha256": hashlib.sha256(
                        self.diffs["MetallicMimic.java"]
                    ).hexdigest(),
                    "from_blob_oid_sha1": self.blobs[
                        (self.from_pin, "MetallicMimic.java")
                    ],
                    "to_blob_oid_sha1": self.blobs[
                        (self.to_pin, "MetallicMimic.java")
                    ],
                    "from_source_sha256": hashlib.sha256(
                        OLD_METALLIC.encode("utf-8")
                    ).hexdigest(),
                    "to_source_sha256": hashlib.sha256(
                        NEW_METALLIC.encode("utf-8")
                    ).hexdigest(),
                    "normalized_token_sha256": token_digest,
                    "allowed_import_delta": {"removed": [], "added": []},
                    "allow_import_reordering": False,
                    "required_direct_test_references": [
                        "MetallicMimicTest.java"
                    ],
                    "required_focused_test_case_count": 3,
                    "require_no_source_warning_markers": True,
                    "require_no_card_data_actionable_finding": True,
                    "allowed_presentation_literal_changes": literal_changes,
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

    def _blob_lookup(self, commit: str, source_path: str) -> str | None:
        return self.blobs.get((commit, source_path))

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
            blob_lookup=self._blob_lookup,
        )

    def _rule_failures(self, report: dict) -> set[str]:
        result = report["clearance_rule_results"][0]
        return set(result["failures"])

    def test_exact_non_executable_tokens_can_reduce_one_review(self) -> None:
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
        result = report["clearance_rule_results"][0]
        self.assertTrue(result["non_executable_tokens_equivalent"])
        self.assertEqual(
            result["diff_hash_mode"],
            "git_diff_no_ext_diff_no_textconv_unified0_full_index",
        )
        self.assertFalse(result["runtime_activation_promoted"])

    def test_exact_semantic_clearance_does_not_activate_blocked_runtime(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["cards"][0]["runtime_catalog_status"] = "unsupported"

        report = self._report(evidence=evidence)

        self.assertEqual(report["status"], "pass", report["failures"])
        result = report["clearance_rule_results"][0]
        self.assertEqual(result["runtime_catalog_status"], "unsupported")
        self.assertFalse(result["runtime_activation_promoted"])

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

    def test_wrong_canonical_diff_hash_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "canonical_diff_sha256"
        ] = "0" * 64

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["exact_clearance_cards"], [])
        self.assertIn(
            "canonical_diff_sha256_mismatch",
            self._rule_failures(report),
        )

    def test_wrong_full_blob_oid_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "from_blob_oid_sha1"
        ] = "0" * 40

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn("from_blob_oid_mismatch", self._rule_failures(report))

    def test_wrong_source_path_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "source_path"
        ] = "WrongMetallicMimic.java"

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn("source_path_mismatch", self._rule_failures(report))

    def test_wrong_policy_pin_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["from_pin"] = "3" * 40

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn(
            "policy_identity",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertEqual(report["exact_clearance_cards"], [])
        self.assertIn("policy_identity_invalid", self._rule_failures(report))

    def test_wrong_source_hash_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "to_source_sha256"
        ] = "0" * 64

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn("to_source_sha256_mismatch", self._rule_failures(report))

    def test_wrong_normalized_token_hash_fails_closed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "normalized_token_sha256"
        ] = "0" * 64

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn(
            "normalized_token_sha256_mismatch",
            self._rule_failures(report),
        )

    def test_unlisted_executable_token_change_fails_closed(self) -> None:
        sources = dict(self.sources)
        sources[(self.to_pin, "MetallicMimic.java")] = NEW_METALLIC.replace(
            "return true",
            "return false",
        )
        original_lookup = self._source_lookup

        def changed_lookup(commit: str, source_path: str) -> str | None:
            return sources.get((commit, source_path)) or original_lookup(
                commit,
                source_path,
            )

        report = review.build_report(
            self.evidence,
            self.policy,
            source_lookup=changed_lookup,
            diff_lookup=self._diff_lookup,
            blob_lookup=self._blob_lookup,
        )

        self.assertEqual(report["status"], "fail")
        self.assertIn(
            "non_executable_tokens_changed",
            self._rule_failures(report),
        )

    def test_actionable_card_data_finding_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["card_data_diagnostics"]["actionable_findings"] = [
            {"card_name": "Metallic Mimic"}
        ]

        report = self._report(evidence=evidence)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["exact_clearance_cards"], [])
        self.assertIn(
            "card_data_actionable_finding_present",
            self._rule_failures(report),
        )

    def test_import_delta_or_reordering_must_match_exact_policy(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["automatic_transition_clearance_rules"][0][
            "allowed_import_delta"
        ] = {
            "removed": ["import mage.fake.Old;"],
            "added": ["import mage.fake.New;"],
        }

        report = self._report(policy=policy)

        self.assertEqual(report["status"], "fail")
        self.assertIn("removed_imports_mismatch", self._rule_failures(report))
        self.assertIn("added_imports_mismatch", self._rule_failures(report))

    @mock.patch.object(review.subprocess, "run")
    def test_git_diff_lookup_always_uses_full_index(
        self,
        run_mock: mock.Mock,
    ) -> None:
        run_mock.return_value = subprocess.CompletedProcess(
            args=[],
            returncode=0,
            stdout=b"diff",
            stderr=b"",
        )

        result = review._git_diff_lookup(review.REPO_ROOT)(
            self.from_pin,
            self.to_pin,
            "MetallicMimic.java",
        )

        self.assertEqual(result, b"diff")
        command = run_mock.call_args.args[0]
        self.assertIn("--full-index", command)
        self.assertNotIn("--abbrev=8", command)


if __name__ == "__main__":
    unittest.main()
