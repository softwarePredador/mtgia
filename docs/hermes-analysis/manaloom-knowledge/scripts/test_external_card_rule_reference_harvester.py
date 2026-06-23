#!/usr/bin/env python3
import unittest
from unittest import mock

import external_card_rule_reference_harvester as harvester


class ExternalCardRuleReferenceHarvesterTests(unittest.TestCase):
    def test_xmage_candidates_use_first_face_and_strip_punctuation(self) -> None:
        candidates = harvester.xmage_class_candidates(
            "Emeria's Call // Emeria, Shattered Skyclave"
        )

        self.assertIn("EmeriasCall", candidates)
        self.assertNotIn("EmeriaShatteredSkyclave", candidates)
        self.assertIn("PromiseOfLoyalty", harvester.xmage_class_candidates("Promise of Loyalty"))

    def test_forge_candidates_include_leading_the_fallback(self) -> None:
        candidates = harvester.forge_slug_candidates("The Mind Stone")

        self.assertEqual(candidates[:2], ["the_mind_stone", "mind_stone"])

    def test_oracle_hash_matches_postgres_raw_md5_convention(self) -> None:
        self.assertEqual(
            harvester.oracle_hash("Draw a card."),
            "3bfb7f30f7e9beaf850032862f2996fc",
        )

    def test_gap_bucket_uses_external_reference_for_review_promotions(self) -> None:
        card = {
            "findings": [
                {"code": "no_trusted_executable_rule"},
                {"code": "review_only_or_needs_review_rule"},
            ]
        }

        self.assertEqual(
            harvester.classify_gap(
                card,
                {"status": "found"},
                {"status": "not_found"},
            ),
            "review_promotion_gap_with_external_reference",
        )

    def test_build_packet_for_card_is_read_only_and_generates_candidate(self) -> None:
        card = {
            "card_name": "Promise of Loyalty",
            "normalized_name": "promise of loyalty",
            "severity": "high",
            "impact_tier": "battle_critical",
            "priority_score": 7051,
            "findings": [
                {"severity": "high", "code": "no_trusted_executable_rule"},
                {"severity": "high", "code": "review_only_or_needs_review_rule"},
            ],
            "effects": ["draw_cards"],
            "active_rule_count": 2,
            "trusted_executable_rule_count": 0,
            "review_only_rule_count": 2,
            "logical_rule_keys": ["old-key"],
            "oracle_cache_present": True,
            "oracle_text_present": True,
            "type_line": "Sorcery",
        }

        def fake_scryfall(name: str, offline: bool) -> dict:
            self.assertEqual(name, "Promise of Loyalty")
            return {
                "status": "found",
                "oracle_text": (
                    "Each player puts a vow counter on a creature they control "
                    "and sacrifices the rest."
                ),
                "oracle_hash_md5_raw": "unit-oracle-hash",
            }

        with mock.patch.object(
            harvester,
            "first_found_text",
            return_value={
                "status": "found",
                "url": "https://example.test/reference",
                "text_excerpt": "Promise of Loyalty reference",
                "signals": ["sacrifice", "counter"],
            },
        ):
            packet = harvester.build_packet_for_card(
                card,
                scryfall_fetcher=fake_scryfall,
            )

        self.assertEqual(
            packet["gap_bucket"],
            "review_promotion_gap_with_external_reference",
        )
        self.assertEqual(
            packet["candidate_rule"]["effect_json"]["effect"],
            "vow_counter_each_player_sacrifice_rest",
        )
        self.assertEqual(packet["candidate_rule"]["review_status"], "needs_review")
        self.assertEqual(packet["candidate_rule"]["execution_status"], "review_only")
        self.assertEqual(packet["candidate_rule"]["oracle_hash"], "unit-oracle-hash")
        self.assertEqual(packet["external_references"]["scryfall"]["status"], "found")


if __name__ == "__main__":
    unittest.main()
