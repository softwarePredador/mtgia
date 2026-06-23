#!/usr/bin/env python3
import unittest
import tempfile
from pathlib import Path
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

    def test_build_packet_prefers_local_xmage_reference_when_available(self) -> None:
        card = {
            "card_name": "Pearl Medallion",
            "normalized_name": "pearl medallion",
            "severity": "high",
            "impact_tier": "battle_critical",
            "priority_score": 6000,
            "findings": [{"severity": "high", "code": "no_trusted_executable_rule"}],
            "effects": ["ramp_permanent"],
        }

        java = """
package mage.cards.p;
import mage.abilities.common.SimpleStaticAbility;
import mage.abilities.effects.common.cost.SpellsCostReductionControllerEffect;
import mage.cards.CardImpl;
import mage.constants.CardType;
public final class PearlMedallion extends CardImpl {
  public PearlMedallion(UUID ownerId, CardSetInfo setInfo) {
    super(ownerId, setInfo, new CardType[]{CardType.ARTIFACT}, "{2}");
    this.addAbility(new SimpleStaticAbility(new SpellsCostReductionControllerEffect(null, 1)));
  }
}
"""

        def fake_scryfall(name: str, offline: bool) -> dict:
            return {
                "status": "found",
                "oracle_text": "White spells you cast cost {1} less to cast.",
                "oracle_hash_md5_raw": "hash",
            }

        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            bucket = root / "Mage.Sets" / "src" / "mage" / "cards" / "p"
            bucket.mkdir(parents=True)
            (bucket / "PearlMedallion.java").write_text(java, encoding="utf-8")
            with mock.patch.object(
                harvester,
                "first_found_text",
                return_value={"status": "skipped_for_test"},
            ):
                packet = harvester.build_packet_for_card(
                    card,
                    scryfall_fetcher=fake_scryfall,
                    xmage_root=root,
                )

        self.assertEqual(packet["external_references"]["xmage"]["status"], "found")
        self.assertEqual(packet["external_references"]["xmage_local"]["status"], "found")
        self.assertEqual(
            packet["candidate_rule"]["effect_json"]["effect"],
            "static_cost_reduction",
        )
        self.assertEqual(
            packet["candidate_rule"]["effect_json"]["cost_reduction_generic"],
            1,
        )
        self.assertEqual(
            packet["candidate_rule"]["effect_json"]["applies_to_spell_colors"],
            ["W"],
        )
        self.assertEqual(
            packet["candidate_rule"]["effect_json"]["xmage_hint_policy"],
            "review_candidate_only",
        )

    def test_oracle_cost_reduction_fallback_is_not_labeled_as_mana_ramp(self) -> None:
        card = {
            "card_name": "Pearl Medallion",
            "normalized_name": "pearl medallion",
            "severity": "high",
            "impact_tier": "battle_critical",
            "priority_score": 6000,
            "findings": [{"severity": "high", "code": "no_trusted_executable_rule"}],
            "effects": ["ramp_permanent"],
        }

        def fake_scryfall(name: str, offline: bool) -> dict:
            return {
                "status": "found",
                "oracle_text": "White spells you cast cost {1} less to cast.",
                "oracle_hash_md5_raw": "hash",
            }

        with mock.patch.object(
            harvester,
            "first_found_text",
            return_value={"status": "skipped_for_test", "signals": []},
        ):
            packet = harvester.build_packet_for_card(
                card,
                scryfall_fetcher=fake_scryfall,
            )

        effect_json = packet["candidate_rule"]["effect_json"]
        self.assertEqual(effect_json["effect"], "static_cost_reduction")
        self.assertNotEqual(effect_json["effect"], "ramp_permanent")
        self.assertEqual(effect_json["cost_reduction_generic"], 1)
        self.assertEqual(effect_json["applies_to_spell_colors"], ["W"])


if __name__ == "__main__":
    unittest.main()
