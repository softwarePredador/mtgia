#!/usr/bin/env python3
"""Tests for battle_effect_coverage_audit known-cards source classification."""

from __future__ import annotations

import unittest

import battle_effect_coverage_audit as audit


class BattleEffectCoverageKnownCardsTests(unittest.TestCase):
    def test_effect_source_prefers_canonical_snapshot_over_generated(self) -> None:
        source = audit.effect_source(
            {"name": "Alpha Card", "type_line": "Instant"},
            {"Alpha Card"},
            {},
        )

        self.assertEqual(source, "known_cards_canonical_snapshot")

    def test_effect_source_rejects_legacy_only_generated_fallback_as_runtime_truth(self) -> None:
        source = audit.effect_source(
            {"name": "Beta Card", "type_line": "Instant"},
            set(),
            {},
        )

        self.assertEqual(source, "unknown")

    def test_effect_source_reports_needs_review_rules_separately(self) -> None:
        source = audit.effect_source(
            {"name": "Gamma Card", "type_line": "Instant"},
            set(),
            {},
            {
                "gamma card": {
                    "source": "generated",
                    "review_status": "needs_review",
                    "execution_status": "review_only",
                }
            },
        )

        self.assertEqual(source, "battle_rule_needs_review_generated")

    def test_effect_source_reports_review_only_rules_separately(self) -> None:
        source = audit.effect_source(
            {"name": "Delta Card", "type_line": "Instant"},
            set(),
            {},
            {
                "delta card": {
                    "source": "manual",
                    "review_status": "verified",
                    "execution_status": "review_only",
                }
            },
        )

        self.assertEqual(source, "battle_rule_review_only_manual")

    def test_rule_status_summary_splits_non_runtime_denominators(self) -> None:
        summary = audit.rule_status_summary(
            {
                "safe spell": {
                    "review_status": "verified",
                    "execution_status": "auto",
                }
            },
            {
                "safe spell": {
                    "review_status": "verified",
                    "execution_status": "auto",
                },
                "needs review spell": {
                    "review_status": "needs_review",
                    "execution_status": "auto",
                },
                "review only spell": {
                    "review_status": "verified",
                    "execution_status": "review_only",
                },
                "annotation only spell": {
                    "review_status": "active",
                    "execution_status": "annotation_only",
                },
            },
        )

        self.assertEqual(summary["runtime_safe_rule_names"], 1)
        self.assertEqual(summary["active_or_review_rule_names"], 4)
        self.assertEqual(summary["non_runtime_safe_rule_names"], 3)
        self.assertEqual(summary["needs_review_rule_names"], 1)
        self.assertEqual(summary["review_only_rule_names"], 1)
        self.assertEqual(summary["annotation_only_rule_names"], 1)
        self.assertEqual(summary["non_runtime_other_rule_names"], 0)

    def test_focused_template_matches_publish_effect_scopes(self) -> None:
        scopes = audit.focused_template_effect_scopes(
            [
                "supports_tap_untap_cipher_trigger_template",
                "supports_phase_out_mass_removal_counters_template",
                "not_a_template",
                "supports_tap_untap_cipher_trigger_template",
            ]
        )

        self.assertEqual(
            scopes,
            [
                "phase_out_mass_removal_counters",
                "tap_untap_cipher_trigger",
            ],
        )

    def test_unknown_effect_entries_publish_status_owner_and_scope(self) -> None:
        focused = audit.unknown_effect_card_entry(
            {
                "name": "Hidden Strings",
                "effect": "unknown",
                "source": "focused_template_ready",
                "flags": [],
                "decks": {"Fixture"},
                "focused_template_matches": {
                    "supports_tap_untap_cipher_trigger_template",
                },
                "focused_template_effect_scopes": {"tap_untap_cipher_trigger"},
            }
        )
        needs_review = audit.unknown_effect_card_entry(
            {
                "name": "Blood Moon",
                "effect": "unknown",
                "source": "battle_rule_needs_review_generated",
                "flags": {"needs_review_rule"},
                "decks": {"Fixture"},
            }
        )
        waived = audit.unknown_effect_card_entry(
            {
                "name": "Mirrormade",
                "effect": "unknown",
                "source": "battle_rule_curated",
                "flags": set(),
                "decks": {"Fixture"},
            }
        )

        self.assertEqual(focused["status"], "focused_template_ready")
        self.assertEqual(focused["owner"], "battle-focused-template-contract")
        self.assertEqual(focused["focused_template_effect_scopes"], ["tap_untap_cipher_trigger"])
        self.assertEqual(needs_review["status"], "needs_review")
        self.assertEqual(needs_review["owner"], "battle-rule-review-queue")
        self.assertEqual(waived["status"], "waived_curated_unknown_effect")
        self.assertEqual(waived["owner"], "battle-effect-contract")
        self.assertTrue(waived["waiver_reason"])

    def test_deck_coverage_markdown_uses_current_source_keys(self) -> None:
        markdown = audit.render_markdown(
            {
                "generated_at": "2026-06-19T00:00:00Z",
                "deck_id": 6,
                "opponents_loaded": 1,
                "total_card_instances": 3,
                "unique_cards": 3,
                "source_totals": {
                    "battle_rule_curated": 2,
                    "battle_rule_needs_review_generated": 1,
                    "type_land": 1,
                },
                "effect_totals": {},
                "flag_totals": {},
                "deck_totals": {
                    "Fixture Deck": {
                        "cards": 3,
                        "battle_rule_curated": 2,
                        "battle_rule_needs_review_generated": 1,
                        "type_land": 1,
                        "flagged": 1,
                    }
                },
                "flagged_cards": [],
                "unknown_cards": [],
                "unknown_effect_cards": [],
                "focused_template_cards": [],
            }
        )

        assert "Battle Rule Curated" in markdown
        assert "Battle Rule Needs Review Generated" in markdown
        assert "| Fixture Deck | 3 | 2 | 1 | 1 | 1 |" in markdown
        assert "Battle Manual" not in markdown
        assert "Battle Generated" not in markdown


if __name__ == "__main__":
    unittest.main()
