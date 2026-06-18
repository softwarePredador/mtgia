#!/usr/bin/env python3
"""Tests for report-only battle-rule to functional-tag derivation."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

import derive_functional_tags_from_battle_rules as derive


class DeriveFunctionalTagsFromBattleRulesTests(unittest.TestCase):
    def test_versioned_low_risk_allowlist_is_dry_run_only(self) -> None:
        allowlist_path = (
            Path(__file__).resolve().parents[2]
            / "BATTLE_RULE_DERIVED_TAG_LOW_RISK_ALLOWLIST_2026-06-12.json"
        )
        data = json.loads(allowlist_path.read_text(encoding="utf-8"))
        loaded = derive.load_allowlist(str(allowlist_path))

        self.assertFalse(data["apply_approved"])
        self.assertEqual(len(data["approved"]), 27)
        self.assertGreaterEqual(len(loaded), 27)
        self.assertTrue(
            all(entry["logical_rule_key"] in loaded for entry in data["approved"])
        )
        self.assertTrue(
            all(
                entry["review_status"] == "dry_run_low_risk_review_only"
                for entry in data["approved"]
            )
        )
        allowlist_data = derive.load_allowlist_data(str(allowlist_path))
        self.assertEqual(allowlist_data["entry_count"], 27)
        self.assertFalse(allowlist_data["apply_approved"])

    def test_allowlist_data_requires_apply_approved_true_for_apply(self) -> None:
        entries, apply_approved = derive.allowlist_entries_from_data(
            {"apply_approved": True, "approved": ["rule-1"]}
        )

        self.assertEqual(entries, ["rule-1"])
        self.assertTrue(apply_approved)

        entries, apply_approved = derive.allowlist_entries_from_data(["rule-2"])

        self.assertEqual(entries, ["rule-2"])
        self.assertFalse(apply_approved)

    def test_build_candidate_accepts_trusted_rule_and_maps_wipe_alias(self) -> None:
        candidate = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Wrath Fixture",
                "effect_json": {"effect": "damage_wipe"},
                "deck_role_json": {"category": "wipe"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 2,
            },
            min_confidence=0.75,
        )

        self.assertEqual(candidate["tag"], "board_wipe")
        self.assertEqual(candidate["source"], derive.DERIVED_SOURCE)
        self.assertEqual(candidate["rejection_reason"], "")
        self.assertEqual(candidate["review_bucket"], "low_risk_review")
        self.assertTrue(candidate["logical_rule_key"].startswith("battle_rule_v1:"))
        self.assertIn("logical_rule_key", candidate["evidence"])

    def test_build_candidate_prefers_specific_effect_tag_over_broad_role(self) -> None:
        candidate = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Recursion Fixture",
                "effect_json": {"effect": "recursion"},
                "deck_role_json": {"category": "engine"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )

        self.assertEqual(candidate["tag"], "recursion")
        self.assertEqual(candidate["review_flags"], ["effect_overrode_broad_role"])
        self.assertEqual(candidate["review_bucket"], "manual_review")

    def test_build_candidate_marks_scope_sensitive_candidates_for_review(self) -> None:
        candidate = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Topdeck Fixture // Land Fixture",
                "effect_json": {"effect": "topdeck_manipulation"},
                "deck_role_json": {"category": "draw"},
                "source": "curated",
                "confidence": 0.82,
                "review_status": "active",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )

        self.assertEqual(candidate["tag"], "draw")
        self.assertEqual(
            candidate["review_flags"],
            [
                "lower_confidence_review",
                "multi_face_review",
                "topdeck_not_direct_draw_review",
            ],
        )
        self.assertEqual(candidate["review_bucket"], "manual_review")

    def test_build_candidate_flags_conditional_ramp_effects(self) -> None:
        candidate = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Ramp Engine Fixture",
                "effect_json": {"effect": "ramp_engine"},
                "deck_role_json": {"category": "ramp"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )

        self.assertEqual(candidate["tag"], "ramp")
        self.assertEqual(candidate["review_flags"], ["conditional_ramp_review"])
        self.assertEqual(candidate["review_bucket"], "manual_review")

    def test_build_candidate_flags_card_specific_scope_overrides(self) -> None:
        cases = [
            (
                {
                    "card_id": "card-1",
                    "card_name": "Dramatic Reversal",
                    "effect_json": {"effect": "ramp_ritual"},
                    "deck_role_json": {"category": "ramp"},
                    "source": "manual",
                    "confidence": 1.0,
                    "review_status": "verified",
                    "rule_version": 1,
                },
                "combo_ramp_scope_review",
            ),
            (
                {
                    "card_id": "card-2",
                    "card_name": "Manamorphose",
                    "effect_json": {"effect": "treasure_maker"},
                    "deck_role_json": {"category": "ramp"},
                    "source": "manual",
                    "confidence": 1.0,
                    "review_status": "verified",
                    "rule_version": 1,
                },
                "mana_filter_not_treasure_review",
            ),
            (
                {
                    "card_id": "card-3",
                    "card_name": "Victory Chimes",
                    "effect_json": {"effect": "draw_engine"},
                    "deck_role_json": {"category": "draw"},
                    "source": "manual",
                    "confidence": 1.0,
                    "review_status": "verified",
                    "rule_version": 1,
                },
                "mana_engine_not_draw_review",
            ),
        ]

        for row, expected_flag in cases:
            with self.subTest(card_name=row["card_name"]):
                candidate = derive.build_candidate(row, min_confidence=0.75)
                self.assertIn(expected_flag, candidate["review_flags"])
                self.assertEqual(candidate["review_bucket"], "manual_review")

    def test_build_candidate_rejects_untrusted_inputs(self) -> None:
        base = {
            "card_id": "card-1",
            "card_name": "Draw Fixture",
            "effect_json": {"effect": "draw_cards"},
            "deck_role_json": {"category": "draw"},
            "source": "manual",
            "confidence": 0.9,
            "review_status": "verified",
            "rule_version": 1,
        }

        cases = [
            ({**base, "card_id": None}, "missing_card_id"),
            ({**base, "review_status": "needs_review"}, "untrusted_review_status"),
            ({**base, "source": "generated"}, "untrusted_source"),
            ({**base, "confidence": 0.5}, "low_confidence"),
            (
                {
                    **base,
                    "effect_json": {"effect": "passive"},
                    "deck_role_json": {"category": "unknown"},
                },
                "non_derivable_tag",
            ),
        ]

        for row, expected_reason in cases:
            with self.subTest(expected_reason=expected_reason):
                candidate = derive.build_candidate(row, min_confidence=0.75)
                self.assertEqual(candidate["rejection_reason"], expected_reason)

    def test_report_classification_dedupes_candidates_and_existing_tags(self) -> None:
        rules = [
            {
                "card_id": "card-1",
                "card_name": "Draw Fixture",
                "effect_json": {"effect": "draw_cards", "amount": 1},
                "deck_role_json": {"category": "draw"},
                "source": "manual",
                "confidence": 0.9,
                "review_status": "verified",
                "rule_version": 1,
            },
            {
                "card_id": "card-1",
                "card_name": "Draw Fixture",
                "effect_json": {"effect": "draw_cards", "amount": 1},
                "deck_role_json": {"category": "draw"},
                "source": "manual",
                "confidence": 0.9,
                "review_status": "verified",
                "rule_version": 1,
            },
            {
                "card_id": "card-2",
                "card_name": "Ramp Fixture",
                "effect_json": {"effect": "ramp_permanent"},
                "deck_role_json": {"category": "ramp"},
                "source": "curated",
                "confidence": 0.8,
                "review_status": "active",
                "rule_version": 1,
            },
        ]
        existing = {("card-2", "ramp")}

        new_candidates = []
        already_present = []
        seen = set()
        for row in rules:
            candidate = derive.build_candidate(row, min_confidence=0.75)
            key = (
                str(candidate["card_id"]),
                str(candidate["tag"]),
                str(candidate["logical_rule_key"]),
            )
            if key in seen:
                continue
            seen.add(key)
            if (str(candidate["card_id"]), str(candidate["tag"])) in existing:
                already_present.append(candidate)
            else:
                new_candidates.append(candidate)

        self.assertEqual(len(new_candidates), 1)
        self.assertEqual(new_candidates[0]["tag"], "draw")
        self.assertEqual(len(already_present), 1)
        self.assertEqual(already_present[0]["tag"], "ramp")

    def test_allowlist_selects_low_risk_and_blocks_manual_review_by_default(self) -> None:
        low_risk = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Removal Fixture",
                "effect_json": {"effect": "remove_permanent"},
                "deck_role_json": {"category": "removal"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )
        manual = derive.build_candidate(
            {
                "card_id": "card-2",
                "card_name": "Tutor Fixture",
                "effect_json": {"effect": "tutor"},
                "deck_role_json": {"category": "tutor"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )
        allowlist = {
            f"{low_risk['card_name']}|{low_risk['tag']}",
            str(manual["logical_rule_key"]),
            "missing-key",
        }

        report = derive.apply_allowlist(
            [low_risk, manual],
            allowlist_keys=allowlist,
            allow_manual_review=False,
        )

        self.assertEqual(report["allowlisted_candidates_count"], 1)
        self.assertEqual(report["allowlisted_candidates"][0]["card_name"], "Removal Fixture")
        self.assertEqual(report["allowlist_blocked_manual_review_count"], 1)
        self.assertEqual(report["allowlist_blocked_manual_review"][0]["card_name"], "Tutor Fixture")
        self.assertEqual(report["allowlist_unmatched"], ["missing-key"])

    def test_allowlist_can_explicitly_include_manual_review(self) -> None:
        manual = derive.build_candidate(
            {
                "card_id": "card-1",
                "card_name": "Tutor Fixture",
                "effect_json": {"effect": "tutor"},
                "deck_role_json": {"category": "tutor"},
                "source": "manual",
                "confidence": 1.0,
                "review_status": "verified",
                "rule_version": 1,
            },
            min_confidence=0.75,
        )

        report = derive.apply_allowlist(
            [manual],
            allowlist_keys={str(manual["logical_rule_key"])},
            allow_manual_review=True,
        )

        self.assertEqual(report["allowlisted_candidates_count"], 1)
        self.assertEqual(report["allowlist_blocked_manual_review_count"], 0)

    def test_evidence_logical_rule_key_accepts_json_dict_and_rejects_invalid(self) -> None:
        self.assertEqual(
            derive.evidence_logical_rule_key({"logical_rule_key": "rule-1"}),
            "rule-1",
        )
        self.assertEqual(
            derive.evidence_logical_rule_key('{"logical_rule_key":"rule-2"}'),
            "rule-2",
        )
        self.assertEqual(derive.evidence_logical_rule_key("not-json"), "")
        self.assertEqual(derive.evidence_logical_rule_key(["rule-3"]), "")

    def test_stale_cleanup_candidates_only_flags_derived_tags_without_active_rule(self) -> None:
        valid = [
            {
                "card_id": "card-1",
                "card_name": "Valid Fixture",
                "tag": "draw",
                "logical_rule_key": "rule-valid",
                "rejection_reason": "",
            }
        ]
        existing = [
            {
                "card_id": "card-1",
                "card_name": "Valid Fixture",
                "tag": "draw",
                "logical_rule_key": "rule-valid",
            },
            {
                "card_id": "card-2",
                "card_name": "Missing Rule Fixture",
                "tag": "ramp",
                "logical_rule_key": "rule-stale",
            },
            {
                "card_id": "card-3",
                "card_name": "Legacy Evidence Fixture",
                "tag": "removal",
                "logical_rule_key": "",
            },
        ]

        stale = derive.stale_cleanup_candidates(existing, valid)

        self.assertEqual(
            [(entry["card_name"], entry["reason"]) for entry in stale],
            [
                ("Missing Rule Fixture", "logical_rule_no_longer_derivable"),
                ("Legacy Evidence Fixture", "missing_logical_rule_key"),
            ],
        )

    def test_apply_preconditions_block_unapproved_or_unsafe_reports(self) -> None:
        report = {
            "apply": False,
            "allowlisted_candidates_count": 1,
            "allowlist_blocked_manual_review_count": 0,
            "allowlist_unmatched_count": 0,
        }

        self.assertEqual(
            derive.validate_apply_preconditions(
                report,
                allowlist_apply_approved=True,
                confirm_apply=True,
                allow_manual_review=False,
            ),
            [],
        )

        errors = derive.validate_apply_preconditions(
            report,
            allowlist_apply_approved=False,
            confirm_apply=False,
            allow_manual_review=True,
        )

        self.assertIn("allowlist_apply_approved_required", errors)
        self.assertIn("operator_confirmation_required", errors)
        self.assertIn("manual_review_apply_not_allowed", errors)

    def test_run_pg_apply_returns_blocked_without_touching_database_when_unsafe(self) -> None:
        report = {
            "apply": False,
            "allowlisted_candidates_count": 27,
            "allowlist_blocked_manual_review_count": 0,
            "allowlist_unmatched_count": 0,
        }

        result = derive.run_pg_apply(
            report,
            allowlist_apply_approved=False,
            confirm_apply=True,
            allow_manual_review=False,
        )

        self.assertTrue(result["blocked"])
        self.assertFalse(result["applied"])
        self.assertEqual(result["reasons"], ["allowlist_apply_approved_required"])


if __name__ == "__main__":
    unittest.main()
