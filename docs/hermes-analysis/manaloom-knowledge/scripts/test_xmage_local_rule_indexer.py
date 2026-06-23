#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import xmage_local_rule_indexer as indexer


PEARL_MEDALLION_JAVA = """
package mage.cards.p;

import mage.abilities.common.SimpleStaticAbility;
import mage.abilities.effects.common.cost.SpellsCostReductionControllerEffect;
import mage.cards.CardImpl;
import mage.constants.CardType;
import mage.constants.Rarity;
import mage.filter.FilterCard;
import mage.filter.predicate.mageobject.ColorPredicate;

public final class PearlMedallion extends CardImpl {

    private static final FilterCard filter = new FilterCard("white spells");

    static {
        filter.add(new ColorPredicate(ObjectColor.WHITE));
    }

    public PearlMedallion(UUID ownerId, CardSetInfo setInfo) {
        super(ownerId, setInfo, new CardType[]{CardType.ARTIFACT}, "{2}");
        this.addAbility(new SimpleStaticAbility(new SpellsCostReductionControllerEffect(filter, 1)));
    }
}
"""


PROMISE_OF_LOYALTY_JAVA = """
package mage.cards.p;

import mage.abilities.effects.common.SacrificeAllEffect;
import mage.abilities.effects.common.counter.AddCountersTargetEffect;
import mage.cards.CardImpl;
import mage.constants.CardType;
import mage.constants.CounterType;
import mage.constants.Rarity;
import mage.target.common.TargetControlledCreaturePermanent;

public final class PromiseOfLoyalty extends CardImpl {

    public PromiseOfLoyalty(UUID ownerId, CardSetInfo setInfo) {
        super(ownerId, setInfo, new CardType[]{CardType.SORCERY}, "{4}{W}");
        this.getSpellAbility().addEffect(new AddCountersTargetEffect(CounterType.VOW.createInstance()));
        this.getSpellAbility().addEffect(new SacrificeAllEffect());
        this.getSpellAbility().addTarget(new TargetControlledCreaturePermanent());
    }
}
"""

EMERIAS_CALL_JAVA = """
package mage.cards.e;

import mage.abilities.effects.common.CreateTokenEffect;
import mage.cards.ModalDoubleFacedCard;
import mage.constants.CardType;
import mage.constants.SubType;

public final class EmeriasCall extends ModalDoubleFacedCard {

    public EmeriasCall(UUID ownerId, CardSetInfo setInfo) {
        super(ownerId, setInfo,
                new CardType[]{CardType.SORCERY}, new SubType[]{}, "{4}{W}{W}{W}",
                "Emeria, Shattered Skyclave", new CardType[]{CardType.LAND}, new SubType[]{}, ""
        );
        this.getLeftHalfCard().getSpellAbility().addEffect(new CreateTokenEffect(new AngelWarriorToken(), 2));
    }
}
"""

THE_MIND_STONE_JAVA = """
package mage.cards.t;

import mage.cards.CardImpl;
import mage.constants.CardType;
import mage.constants.SubType;
import mage.filter.common.FilterControlledPermanent;
import mage.filter.predicate.Predicates;

public final class TheMindStone extends CardImpl {

    private static final FilterControlledPermanent filter = new FilterControlledPermanent("other target nonland permanent you control");

    static {
        filter.add(Predicates.not(CardType.LAND.getPredicate()));
    }

    public TheMindStone(UUID ownerId, CardSetInfo setInfo) {
        super(ownerId, setInfo, new CardType[]{CardType.ARTIFACT}, "{1}{W}");
        this.subtype.add(SubType.INFINITY);
        this.subtype.add(SubType.STONE);
    }
}
"""


class XMageLocalRuleIndexerTests(unittest.TestCase):
    def _fixture_root(self) -> Path:
        tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        root = Path(tmpdir.name)
        bucket = root / "Mage.Sets" / "src" / "mage" / "cards" / "p"
        bucket.mkdir(parents=True)
        (bucket / "PearlMedallion.java").write_text(PEARL_MEDALLION_JAVA, encoding="utf-8")
        (bucket / "PromiseOfLoyalty.java").write_text(PROMISE_OF_LOYALTY_JAVA, encoding="utf-8")
        e_bucket = root / "Mage.Sets" / "src" / "mage" / "cards" / "e"
        e_bucket.mkdir(parents=True)
        (e_bucket / "EmeriasCall.java").write_text(EMERIAS_CALL_JAVA, encoding="utf-8")
        t_bucket = root / "Mage.Sets" / "src" / "mage" / "cards" / "t"
        t_bucket.mkdir(parents=True)
        (t_bucket / "TheMindStone.java").write_text(THE_MIND_STONE_JAVA, encoding="utf-8")
        return root

    def test_class_candidates_strip_punctuation_and_use_first_face(self) -> None:
        self.assertEqual(
            indexer.xmage_class_candidates("Emeria's Call // Emeria, Shattered Skyclave")[0],
            "EmeriasCall",
        )

    def test_parse_local_cost_reducer_reference(self) -> None:
        root = self._fixture_root()
        entry = indexer.build_index_for_card("Pearl Medallion", xmage_root=root)

        self.assertEqual(entry["status"], "found")
        self.assertEqual(entry["xmage_class_name"], "PearlMedallion")
        self.assertIn("SpellsCostReductionControllerEffect", entry["effect_classes"])
        self.assertIn("SimpleStaticAbility", entry["ability_classes"])
        self.assertIn("cost_reduction", entry["signals"])
        self.assertEqual(entry["constructor_metadata"]["xmage_card_name"], "Pearl Medallion")
        self.assertEqual(entry["constructor_metadata"]["mana_cost"], "{2}")
        self.assertNotEqual(entry["constructor_metadata"]["xmage_card_name"], "{2}")
        self.assertEqual(
            entry["candidate_effect_hints"]["primary_candidate"]["effect_json"]["effect"],
            "static_cost_reduction",
        )

    def test_parse_modal_double_faced_constructor_metadata(self) -> None:
        root = self._fixture_root()
        entry = indexer.build_index_for_card("Emeria's Call // Emeria, Shattered Skyclave", xmage_root=root)

        metadata = entry["constructor_metadata"]

        self.assertEqual(metadata["xmage_card_name"], "Emeria's Call")
        self.assertEqual(metadata["mana_cost"], "{4}{W}{W}{W}")
        self.assertEqual(metadata["front_mana_cost"], "{4}{W}{W}{W}")
        self.assertEqual(metadata["back_face_name"], "Emeria, Shattered Skyclave")
        self.assertEqual(metadata["back_mana_cost"], "")
        self.assertEqual(metadata["card_types"], ["LAND", "SORCERY"])
        self.assertEqual(metadata["subtypes"], [])

    def test_constructor_types_do_not_include_filter_predicate_types(self) -> None:
        root = self._fixture_root()
        entry = indexer.build_index_for_card("The Mind Stone", xmage_root=root)

        metadata = entry["constructor_metadata"]

        self.assertEqual(metadata["card_types"], ["ARTIFACT"])
        self.assertEqual(metadata["subtypes"], ["INFINITY", "STONE"])

    def test_parse_vow_counter_and_suggest_scenario(self) -> None:
        root = self._fixture_root()
        entry = indexer.build_index_for_card("Promise of Loyalty", xmage_root=root)

        self.assertEqual(entry["status"], "found")
        self.assertIn("VOW", entry["counter_types"])
        self.assertIn("TargetControlledCreaturePermanent", entry["target_classes"])
        self.assertEqual(
            entry["candidate_effect_hints"]["primary_candidate"]["effect_json"]["effect"],
            "vow_counter_each_player_sacrifice_rest",
        )
        self.assertTrue(entry["suggested_test_scenarios"])

    def test_report_is_read_only_and_counts_not_found(self) -> None:
        root = self._fixture_root()
        report = indexer.build_index_report(
            ["Pearl Medallion", "Missing Card"],
            xmage_root=root,
            source={"kind": "unit"},
        )

        self.assertEqual(report["mutations_performed"], [])
        self.assertEqual(report["summary"]["requested_card_count"], 2)
        self.assertEqual(report["summary"]["resolved_count"], 1)
        self.assertEqual(report["summary"]["not_found_count"], 1)

    def test_not_found_keeps_nearby_candidates_as_untrusted_hints(self) -> None:
        root = self._fixture_root()
        bucket = root / "Mage.Sets" / "src" / "mage" / "cards" / "t"
        bucket.mkdir(parents=True, exist_ok=True)
        (bucket / "ThorOdinson.java").write_text(
            "package mage.cards.t; public final class ThorOdinson extends CardImpl {}",
            encoding="utf-8",
        )
        class_index = indexer.build_card_class_index(root)

        entry = indexer.build_index_for_card(
            "Thor, God of Thunder",
            xmage_root=root,
            class_index=class_index,
        )

        self.assertEqual(entry["status"], "not_found")
        self.assertIn(
            "ThorOdinson",
            {candidate["class_name"] for candidate in entry["nearby_xmage_class_candidates"]},
        )


if __name__ == "__main__":
    unittest.main()
