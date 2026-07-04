import tempfile
import unittest
from pathlib import Path

import lorehold_from_scratch_challenger_builder as builder


class LoreholdFromScratchChallengerBuilderTest(unittest.TestCase):
    def test_challenger_plans_are_from_scratch_not_607_swap_plans(self):
        self.assertEqual(
            set(builder.CHALLENGER_PLANS),
            {
                "access_density_control",
                "miracle_pressure_conversion",
                "miracle_topdeck_control",
                "spellchain_big_sorcery",
                "spell_pressure_topdeck",
                "recursion_discard_engine",
                "recursion_discard_pressure_repair",
            },
        )
        for plan in builder.CHALLENGER_PLANS.values():
            self.assertEqual(plan["mode"], "from_scratch")
            self.assertNotIn("removed", plan)
            self.assertNotIn("base_deck_id", plan)

    def test_parse_plans_supports_all_and_subset(self):
        self.assertEqual(builder.parse_plans("spellchain_big_sorcery"), ["spellchain_big_sorcery"])
        self.assertEqual(builder.parse_plans("all"), list(builder.CHALLENGER_PLANS))

    def test_build_single_challenger_outputs_isolated_candidate_with_fixed_607_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            report = builder.build_all(
                source_db=builder.DEFAULT_SOURCE_DB,
                plan_keys=["miracle_topdeck_control"],
                corpus_deck_ids=list(builder.DEFAULT_CORPUS_DECK_IDS),
                out_dir=Path(tmp),
                stem="unit_from_scratch",
                opponent_limit=3,
                games=1,
                game_timeout_seconds=5.0,
            )
            candidate_db_exists = Path(report["candidates"][0]["candidate_db"]).exists()

        self.assertEqual(report["status"], "ready")
        self.assertEqual(len(report["candidates"]), 1)
        candidate = report["candidates"][0]
        self.assertEqual(candidate["mode"], "from_scratch")
        self.assertEqual(candidate["quantity_total"], 100)
        self.assertEqual(candidate["protected_baseline_deck_id"], 607)
        self.assertEqual(candidate["fixed_opponent_deck_id_for_gate"], 607)
        self.assertEqual(candidate["missing_required_cards"], [])
        self.assertTrue(candidate_db_exists)
        self.assertIn("--fixed-opponent-deck-ids", candidate["battle_gate_command"])
        self.assertIn("607", candidate["battle_gate_command"])
        self.assertIn("--deck-ids", candidate["battle_gate_command"])
        self.assertIn("--matrix", candidate["battle_gate_command"])

    def test_miracle_pressure_conversion_preserves_607_land_floor(self):
        with tempfile.TemporaryDirectory() as tmp:
            report = builder.build_all(
                source_db=builder.DEFAULT_SOURCE_DB,
                plan_keys=["miracle_pressure_conversion"],
                corpus_deck_ids=list(builder.DEFAULT_CORPUS_DECK_IDS),
                out_dir=Path(tmp),
                stem="unit_from_scratch_pressure_conversion",
                opponent_limit=3,
                games=1,
                game_timeout_seconds=5.0,
            )

        candidate = report["candidates"][0]
        lands = {
            card["card_name"]: int(card.get("quantity") or 1)
            for card in candidate["final_deck"]
            if card.get("is_land")
        }
        for land_name in builder.CHALLENGER_PLANS["miracle_pressure_conversion"]["land_priority"]:
            self.assertIn(land_name, lands)
        self.assertEqual(lands["Mountain // Mountain"], 4)
        self.assertEqual(lands["Plains // Plains"], 4)
        self.assertEqual(candidate["quantity_total"], 100)
        self.assertEqual(candidate["missing_required_cards"], [])

    def test_spell_pressure_topdeck_forces_pressure_pair_and_preserves_anchors(self):
        with tempfile.TemporaryDirectory() as tmp:
            report = builder.build_all(
                source_db=builder.DEFAULT_SOURCE_DB,
                plan_keys=["spell_pressure_topdeck"],
                corpus_deck_ids=list(builder.DEFAULT_CORPUS_DECK_IDS),
                out_dir=Path(tmp),
                stem="unit_from_scratch_spell_pressure",
                opponent_limit=3,
                games=1,
                game_timeout_seconds=5.0,
            )

        candidate = report["candidates"][0]
        names = {card["card_name"] for card in candidate["final_deck"]}
        for card_name in (
            "Guttersnipe",
            "Young Pyromancer",
            "Sensei's Divining Top",
            "Scroll Rack",
            "Library of Leng",
            "Bender's Waterskin",
            "Victory Chimes",
            "Molecule Man",
            "The Scarlet Witch",
        ):
            self.assertIn(card_name, names)
        self.assertEqual(candidate["quantity_total"], 100)
        self.assertEqual(candidate["land_quantity"], 34)
        self.assertEqual(candidate["missing_required_cards"], [])


if __name__ == "__main__":
    unittest.main()
