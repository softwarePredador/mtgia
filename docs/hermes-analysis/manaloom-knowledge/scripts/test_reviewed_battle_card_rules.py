#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

import battle_rule_registry
from reviewed_battle_card_rules import (
    DEFAULT_REVIEWED_RULES_PATH,
    load_reviewed_rule_rows,
)
from known_cards_fallback_snapshot import build_snapshot_payload


SCRIPT_DIR = Path(__file__).resolve().parent
SYNC_MODULE_PATH = SCRIPT_DIR / "sync_battle_card_rules.py"
BATTLE_MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def _load_module(module_path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


sync_rules = _load_module(SYNC_MODULE_PATH, "sync_battle_rules_reviewed_test")
battle = _load_module(BATTLE_MODULE_PATH, "battle_reviewed_rule_runtime_test")


class ReviewedBattleCardRulesTests(unittest.TestCase):
    def _seed_reviewed_rules_db(self, db_path: Path) -> None:
        with closing(sqlite3.connect(db_path)) as conn:
            battle_rule_registry.ensure_battle_card_rules(conn)
            for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    row["card_name"],
                    row["effect_json"],
                    source=row["source"],
                    confidence=row["confidence"],
                    review_status=row["review_status"],
                    execution_status=row.get("execution_status", "auto"),
                    deck_role_json=row.get("deck_role_json"),
                    notes=row.get("notes", ""),
                    oracle_hash=row.get("oracle_hash"),
                    logical_rule_key_value=row.get("logical_rule_key"),
                )
            conn.commit()

    def test_colorless_land_sacrifice_mana_mode_does_not_overproduce_before_runtime_executor(self) -> None:
        player = battle.Player("Pilot", None, [])
        crystal_vein = {
            "name": "Crystal Vein",
            "type_line": "Land",
            "effect": "ramp_permanent",
            "battle_model_scope": "colorless_land_tap_or_tap_sacrifice_two_colorless_mode_v1",
            "is_mana_source": True,
            "permanent_type": "land",
            "mana_produced": 1,
            "produces": "C",
            "has_default_colorless_mana_ability": True,
            "default_mana_produced": 1,
            "has_sacrifice_mana_mode": True,
            "sacrifice_mana_produced": 2,
            "sacrifice_mana_mode_status": "runtime_required",
            "alternate_mana_modes": [
                {
                    "mode": "tap_sacrifice_for_two_colorless",
                    "produces": "C",
                    "mana_produced": 2,
                    "activation_requires_tap": True,
                    "activation_requires_sacrifice": True,
                    "status": "runtime_required",
                }
            ],
            "oracle_runtime_scope": "land_alternate_sacrifice_mana_mode_runtime_required_v1",
        }
        player.battlefield = [crystal_vein]

        self.assertEqual(battle.mana_source_production_for_state(player, crystal_vein), 1)

        player.refresh_mana_sources(turn=1)

        self.assertEqual(player.available_mana(), 1)
        self.assertEqual(len(player.battlefield), 1)
        self.assertEqual(player.battlefield[0]["name"], "Crystal Vein")

    def test_snapshot_payload_uses_registry_priority_instead_of_last_row_wins(self) -> None:
        payload = build_snapshot_payload(
            [
                {
                    "card_name": "Library of Leng",
                    "effect_json": {"effect": "ramp_permanent", "mana_produced": 1},
                    "source": "generated",
                    "confidence": 0.55,
                    "review_status": "needs_review",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "generated-ramp",
                },
                {
                    "card_name": "Library of Leng",
                    "effect_json": {
                        "effect": "passive",
                        "no_max_hand_size": True,
                        "discard_effect_to_top_replacement": True,
                    },
                    "source": "curated",
                    "confidence": 0.93,
                    "review_status": "active",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "curated-passive",
                },
                {
                    "card_name": "Sensei's Divining Top",
                    "effect_json": {"effect": "topdeck_manipulation"},
                    "source": "manual",
                    "confidence": 1.0,
                    "review_status": "verified",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "manual-topdeck",
                },
                {
                    "card_name": "Sensei's Divining Top",
                    "effect_json": {"effect": "draw_cards"},
                    "source": "generated",
                    "confidence": 0.55,
                    "review_status": "needs_review",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "generated-draw",
                },
            ]
        )

        self.assertEqual(payload["Library of Leng"]["effect"], "passive")
        self.assertTrue(payload["Library of Leng"]["discard_effect_to_top_replacement"])
        self.assertEqual(payload["Library of Leng"]["battle_rule_source"], "curated")
        self.assertEqual(payload["Sensei's Divining Top"]["effect"], "topdeck_manipulation")
        self.assertEqual(payload["Sensei's Divining Top"]["battle_rule_source"], "manual")

    def test_snapshot_payload_breaks_curated_ties_by_recent_update(self) -> None:
        payload = build_snapshot_payload(
            [
                {
                    "card_name": "Scroll Rack",
                    "effect_json": {
                        "effect": "topdeck_manipulation",
                        "activation_cost_generic": 1,
                        "hand_to_top_exchange": True,
                        "battle_model_scope": "scroll_rack_exchange_unexecuted_v1",
                    },
                    "source": "curated",
                    "confidence": 0.8,
                    "review_status": "active",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "curated-old",
                    "updated_at": "2026-06-17T10:00:00+00:00",
                },
                {
                    "card_name": "Scroll Rack",
                    "effect_json": {
                        "effect": "topdeck_manipulation",
                        "activation_cost_generic": 1,
                        "hand_to_top_exchange": True,
                        "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
                    },
                    "source": "curated",
                    "confidence": 0.8,
                    "review_status": "active",
                    "execution_status": "auto",
                    "rule_version": 1,
                    "logical_rule_key": "curated-new",
                    "updated_at": "2026-06-17T12:00:00+00:00",
                },
            ]
        )

        self.assertEqual(
            payload["Scroll Rack"]["battle_model_scope"],
            "scroll_rack_upkeep_single_exchange_v1",
        )

    def test_reviewed_rule_payload_contains_expected_cards(self) -> None:
        rows = load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH)
        by_name = {row["card_name"]: row for row in rows}

        self.assertEqual(by_name["Abandon Attachments"]["source"], "curated")
        self.assertEqual(by_name["Abandon Attachments"]["review_status"], "verified")
        self.assertEqual(by_name["Abandon Attachments"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Abandon Attachments"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Aether Channeler"]["source"], "curated")
        self.assertEqual(by_name["Aether Channeler"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Aether Channeler"]["effect_json"]["etb_draw_count"], 1)
        self.assertEqual(by_name["Aetherflux Reservoir"]["source"], "curated")
        self.assertEqual(by_name["Aetherflux Reservoir"]["review_status"], "active")
        self.assertEqual(by_name["Aetherflux Reservoir"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Aetherflux Reservoir"]["oracle_hash"],
            "ea5327899fb66a2d583e80e8ca12d9b2",
        )
        self.assertEqual(
            by_name["Aetherflux Reservoir"]["effect_json"]["effect"],
            "aetherflux_reservoir",
        )
        self.assertTrue(by_name["Aetherflux Reservoir"]["effect_json"]["spell_cast_lifegain"])
        self.assertTrue(
            by_name["Aetherflux Reservoir"]["effect_json"][
                "life_gain_equal_spells_cast_this_turn"
            ]
        )
        self.assertEqual(
            by_name["Aetherflux Reservoir"]["effect_json"]["activation_execution_status"],
            "annotation_only",
        )
        self.assertEqual(
            by_name["Aetherflux Reservoir"]["effect_json"]["battle_model_scope"],
            "spell_cast_lifegain_pay_50_damage_annotation_v1",
        )
        self.assertEqual(by_name["Assemble the Players"]["source"], "curated")
        self.assertEqual(by_name["Assemble the Players"]["review_status"], "verified")
        self.assertEqual(by_name["Assemble the Players"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Assemble the Players"]["logical_rule_key"],
            "battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882",
        )
        self.assertEqual(
            by_name["Assemble the Players"]["oracle_hash"],
            "ffdf411200b723c016fe9df0d85dd8e4",
        )
        self.assertEqual(
            by_name["Assemble the Players"]["effect_json"]["battle_model_scope"],
            "top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1",
        )
        self.assertTrue(
            by_name["Assemble the Players"]["effect_json"]["top_library_cast_once_each_turn"]
        )
        self.assertEqual(
            by_name["Assemble the Players"]["effect_json"]["top_library_cast_power_max"],
            2,
        )
        self.assertEqual(by_name["Molecule Man"]["source"], "curated")
        self.assertEqual(by_name["Molecule Man"]["review_status"], "verified")
        self.assertEqual(by_name["Molecule Man"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Molecule Man"]["logical_rule_key"],
            "battle_rule_v1:752f8cfd0a44d1889ffdb40610847374",
        )
        self.assertEqual(
            by_name["Molecule Man"]["effect_json"]["battle_model_scope"],
            "nonland_hand_miracle_zero_static_v1",
        )
        self.assertEqual(by_name["Thor, God of Thunder"]["source"], "curated")
        self.assertEqual(by_name["Thor, God of Thunder"]["review_status"], "active")
        self.assertEqual(by_name["Thor, God of Thunder"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Thor, God of Thunder"]["logical_rule_key"],
            "battle_rule_v1:280e17ec34ac105baeb6989491c6ff25",
        )
        self.assertEqual(
            by_name["Thor, God of Thunder"]["effect_json"]["battle_model_scope"],
            "etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1",
        )
        self.assertEqual(
            by_name["Thor, God of Thunder"]["effect_json"]["trigger_effect"],
            "damage_any_target",
        )
        self.assertIn("Ashnod's Altar", by_name)
        self.assertIn("Akroma's Will", by_name)
        self.assertIn("Ancient Den", by_name)
        self.assertIn("Angel's Grace", by_name)
        self.assertIn("Apex of Power", by_name)
        self.assertIn("Approach of the Second Sun", by_name)
        self.assertIn("Archaeomancer's Map", by_name)
        self.assertIn("Ancient Tomb", by_name)
        self.assertIn("Arcane Endeavor", by_name)
        self.assertIn("Aven Mindcensor", by_name)
        self.assertIn("Basking Broodscale", by_name)
        self.assertIn("Big Score", by_name)
        self.assertIn("Birgi, God of Storytelling", by_name)
        self.assertIn("Blind Obedience", by_name)
        self.assertIn("Breena, the Demagogue", by_name)
        self.assertIn("Chrome Mox", by_name)
        self.assertIn("Chromatic Star", by_name)
        self.assertIn("Crop Rotation", by_name)
        self.assertIn("Curator's Ward", by_name)
        self.assertIn("Decaying Time Loop", by_name)
        self.assertIn("Dismember", by_name)
        self.assertIn("Electric Revelation", by_name)
        self.assertIn("Electroduplicate", by_name)
        self.assertIn("Entomb", by_name)
        self.assertIn("Empowered Autogenerator", by_name)
        self.assertIn("Ether", by_name)
        self.assertIn("Everflowing Chalice", by_name)
        self.assertIn("Fateful Showdown", by_name)
        self.assertIn("Fellwar Stone", by_name)
        self.assertIn("Formidable Speaker", by_name)
        self.assertIn("Gemstone Caverns", by_name)
        self.assertIn("Goblin Bombardment", by_name)
        self.assertIn("Great Furnace", by_name)
        self.assertIn("Hall of Heliod's Generosity", by_name)
        self.assertIn("Incubation Druid", by_name)
        self.assertIn("Inventors' Fair", by_name)
        self.assertIn("Izzet Signet", by_name)
        self.assertIn("Kraum, Ludevic's Opus", by_name)
        self.assertIn("Lapse of Certainty", by_name)
        self.assertIn("Library of Leng", by_name)
        self.assertIn("Lightning Greaves", by_name)
        self.assertIn("Lorehold, the Historian", by_name)
        self.assertIn("Lumra, Bellow of the Woods", by_name)
        self.assertIn("Magma Opus", by_name)
        self.assertIn("Mana Vault", by_name)
        self.assertIn("Miscast", by_name)
        self.assertIn("Mystical Tutor", by_name)
        self.assertIn("Mox Amber", by_name)
        self.assertIn("Mox Diamond", by_name)
        self.assertIn("Mind Stone", by_name)
        self.assertIn("Nature's Claim", by_name)
        self.assertIn("Natural Order", by_name)
        self.assertIn("Path to Exile", by_name)
        self.assertIn("Pirate's Pillage", by_name)
        self.assertIn("Prismatic Lens", by_name)
        self.assertIn("Practical Research", by_name)
        self.assertIn("Radiant Scrollwielder", by_name)
        self.assertIn("Rampant Growth", by_name)
        self.assertIn("Rakdos, the Muscle", by_name)
        self.assertIn("Reanimate", by_name)
        self.assertIn("Runaway Steam-Kin", by_name)
        self.assertIn("Ring of the Lucii", by_name)
        self.assertIn("Sami's Curiosity", by_name)
        self.assertIn("Sazacap's Brew", by_name)
        self.assertIn("Scavenging Ooze", by_name)
        self.assertIn("Scroll Rack", by_name)
        self.assertIn("Seething Song", by_name)
        self.assertIn("Skullclamp", by_name)
        self.assertIn("Sensei's Divining Top", by_name)
        self.assertIn("Soul-Guide Lantern", by_name)
        self.assertIn("Splendid Reclamation", by_name)
        self.assertIn("Spelltwine", by_name)
        self.assertIn("Staff of Compleation", by_name)
        self.assertIn("Talisman of Conviction", by_name)
        self.assertIn("Teferi's Protection", by_name)
        self.assertIn("Tellah, Great Sage", by_name)
        self.assertIn("The Unagi of Kyoshi Island", by_name)
        self.assertIn("Silence", by_name)
        self.assertIn("Shantotto, Tactician Magician", by_name)
        self.assertIn("Sisay's Ring", by_name)
        self.assertIn("Sisay, Weatherlight Captain", by_name)
        self.assertIn("Sunbaked Canyon", by_name)
        self.assertIn("Unexpected Windfall", by_name)
        self.assertIn("Ur-Golem's Eye", by_name)
        self.assertIn("Urza's Saga", by_name)
        self.assertIn("Valakut Awakening", by_name)
        self.assertIn("Valakut Awakening // Valakut Stoneforge", by_name)
        self.assertIn("Vexing Bauble", by_name)
        self.assertIn("Volcanic Vision", by_name)
        self.assertIn("Wall of Omens", by_name)
        self.assertIn("War Room", by_name)
        self.assertIn("Wayfarer's Bauble", by_name)
        self.assertIn("Wheel of Fortune", by_name)
        self.assertIn("Woodland Bellower", by_name)
        self.assertIn("Worldfire", by_name)
        self.assertIn("Zuran Orb", by_name)
        self.assertEqual(by_name["Ashnod's Altar"]["source"], "curated")
        self.assertEqual(by_name["Ashnod's Altar"]["review_status"], "active")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Ashnod's Altar"]["effect_json"]["activated_mana_ability"])
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["activation_cost"], "sacrifice_creature")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Akroma's Will"]["source"], "curated")
        self.assertEqual(by_name["Akroma's Will"]["review_status"], "verified")
        self.assertEqual(by_name["Akroma's Will"]["effect_json"]["effect"], "pump_all")
        self.assertEqual(
            by_name["Akroma's Will"]["effect_json"]["keywords"],
            ["flying", "double_strike", "lifelink", "indestructible"],
        )
        self.assertEqual(by_name["Ancient Den"]["effect_json"]["effect"], "land")
        self.assertEqual(by_name["Ancient Den"]["effect_json"]["produces"], "W")
        self.assertEqual(by_name["Angel's Grace"]["source"], "curated")
        self.assertEqual(by_name["Angel's Grace"]["review_status"], "verified")
        self.assertEqual(by_name["Angel's Grace"]["effect_json"]["effect"], "cannot_lose_turn")
        self.assertEqual(by_name["Apex of Power"]["source"], "curated")
        self.assertEqual(by_name["Apex of Power"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Apex of Power"]["effect_json"]["impulse_top_seven_until_eot"])
        self.assertEqual(by_name["Approach of the Second Sun"]["source"], "curated")
        self.assertEqual(by_name["Approach of the Second Sun"]["review_status"], "active")
        self.assertEqual(by_name["Approach of the Second Sun"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Approach of the Second Sun"]["oracle_hash"],
            "0838960b80a282fb4508532f7bae8c2b",
        )
        self.assertEqual(
            by_name["Approach of the Second Sun"]["effect_json"]["effect"],
            "approach",
        )
        self.assertEqual(
            by_name["Approach of the Second Sun"]["effect_json"]["battle_model_scope"],
            "approach_second_cast_win_v2",
        )
        self.assertTrue(
            by_name["Approach of the Second Sun"]["effect_json"]["countered_first_cast_counts"]
        )
        self.assertTrue(
            by_name["Approach of the Second Sun"]["effect_json"]["copy_spell_does_not_count"]
        )
        self.assertEqual(by_name["Archaeomancer's Map"]["source"], "curated")
        self.assertEqual(by_name["Archaeomancer's Map"]["review_status"], "active")
        self.assertEqual(by_name["Archaeomancer's Map"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Archaeomancer's Map"]["oracle_hash"],
            "22b82ca6bbef42371227bc38a9a546b5",
        )
        self.assertEqual(by_name["Archaeomancer's Map"]["effect_json"]["effect"], "ramp_engine")
        self.assertEqual(
            by_name["Archaeomancer's Map"]["effect_json"]["battle_model_scope"],
            "basic_plains_etb_plus_opponent_land_catchup_v2",
        )
        self.assertEqual(
            by_name["Archaeomancer's Map"]["effect_json"]["trigger_condition"],
            "opponent_controls_more_lands_than_you",
        )
        self.assertTrue(
            by_name["Archaeomancer's Map"]["effect_json"]["trigger_rechecks_on_resolution"]
        )
        self.assertEqual(by_name["Blind Obedience"]["source"], "curated")
        self.assertEqual(by_name["Blind Obedience"]["review_status"], "active")
        self.assertEqual(by_name["Blind Obedience"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Blind Obedience"]["oracle_hash"],
            "4e62bff316f784c1b468b9e53146d2aa",
        )
        self.assertEqual(by_name["Blind Obedience"]["effect_json"]["effect"], "passive")
        self.assertTrue(
            by_name["Blind Obedience"]["effect_json"][
                "opponents_artifacts_creatures_enter_tapped"
            ]
        )
        self.assertEqual(
            by_name["Blind Obedience"]["effect_json"]["extort_execution_status"],
            "annotation_only",
        )
        self.assertEqual(
            by_name["Blind Obedience"]["effect_json"]["battle_model_scope"],
            "opponent_artifact_creature_enter_tapped_extort_annotation_v1",
        )
        self.assertEqual(by_name["Arcane Endeavor"]["source"], "curated")
        self.assertEqual(by_name["Arcane Endeavor"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Arcane Endeavor"]["effect_json"]["roll_two_d8_choose_draw_count"])
        self.assertEqual(by_name["Brainstone"]["source"], "curated")
        self.assertEqual(by_name["Brainstone"]["review_status"], "verified")
        self.assertEqual(by_name["Brainstone"]["execution_status"], "auto")
        self.assertEqual(by_name["Brainstone"]["effect_json"]["effect"], "topdeck_manipulation")
        self.assertEqual(by_name["Brainstone"]["effect_json"]["activation_cost_generic"], 2)
        self.assertEqual(by_name["Brainstone"]["effect_json"]["draw_count"], 3)
        self.assertTrue(by_name["Brainstone"]["effect_json"]["hand_to_top_exchange"])
        self.assertTrue(by_name["Brainstone"]["effect_json"]["requires_sacrifice_artifact"])
        self.assertTrue(by_name["Brainstone"]["effect_json"]["activation_requires_tap"])
        self.assertTrue(by_name["Brainstone"]["effect_json"]["activation_requires_sacrifice"])
        self.assertTrue(by_name["Brainstone"]["effect_json"]["can_setup_lorehold_miracle_draw"])
        self.assertEqual(
            by_name["Brainstone"]["effect_json"]["battle_model_scope"],
            "brainstone_draw_three_put_two_back_for_first_draw_miracle_v1",
        )
        self.assertNotIn(
            "unexecuted",
            by_name["Brainstone"]["effect_json"]["battle_model_scope"],
        )
        self.assertEqual(by_name["Codex Shredder"]["source"], "curated")
        self.assertEqual(by_name["Codex Shredder"]["review_status"], "verified")
        self.assertEqual(by_name["Codex Shredder"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Codex Shredder"]["logical_rule_key"],
            "battle_rule_v1:3417000adca740f0c5036e7232221df4",
        )
        self.assertEqual(by_name["Codex Shredder"]["effect_json"]["effect"], "passive")
        self.assertEqual(
            by_name["Codex Shredder"]["effect_json"]["activated_target_player_mill_count"],
            1,
        )
        self.assertEqual(
            by_name["Codex Shredder"]["effect_json"]["graveyard_to_hand_activation_cost_generic"],
            5,
        )
        self.assertTrue(
            by_name["Codex Shredder"]["effect_json"]["graveyard_to_hand_activation_requires_tap"]
        )
        self.assertTrue(
            by_name["Codex Shredder"]["effect_json"][
                "graveyard_to_hand_activation_requires_sacrifice"
            ]
        )
        self.assertEqual(by_name["Codex Shredder"]["effect_json"]["graveyard_to_hand_target"], "any_card")
        self.assertEqual(
            by_name["Codex Shredder"]["effect_json"]["battle_model_scope"],
            "tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1",
        )
        self.assertNotIn(
            "xmage_graveyard_return_variant_review_v1",
            by_name["Codex Shredder"]["effect_json"]["battle_model_scope"],
        )
        self.assertEqual(by_name["Chaos Wand"]["source"], "curated")
        self.assertEqual(by_name["Chaos Wand"]["review_status"], "verified")
        self.assertEqual(by_name["Chaos Wand"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Chaos Wand"]["logical_rule_key"],
            "battle_rule_v1:cb5acba44191c9c6711c017b4c3590d0",
        )
        self.assertEqual(by_name["Chaos Wand"]["effect_json"]["effect"], "passive")
        self.assertEqual(
            by_name["Chaos Wand"]["effect_json"]["activated_effect"],
            "opponent_library_free_cast",
        )
        self.assertEqual(by_name["Chaos Wand"]["effect_json"]["activation_cost_generic"], 4)
        self.assertTrue(by_name["Chaos Wand"]["effect_json"]["activation_requires_tap"])
        self.assertEqual(by_name["Chaos Wand"]["effect_json"]["target"], "opponent")
        self.assertEqual(
            by_name["Chaos Wand"]["effect_json"][
                "activated_opponent_library_exile_until_card_types"
            ],
            ["instant", "sorcery"],
        )
        self.assertTrue(
            by_name["Chaos Wand"]["effect_json"][
                "opponent_library_exile_until_cast_without_paying_mana"
            ]
        )
        self.assertEqual(
            by_name["Chaos Wand"]["effect_json"]["battle_model_scope"],
            "pay_four_tap_target_opponent_exile_until_instant_sorcery_may_cast_free_bottom_rest_v1",
        )
        self.assertEqual(by_name["Perpetual Timepiece"]["source"], "curated")
        self.assertEqual(by_name["Perpetual Timepiece"]["review_status"], "verified")
        self.assertEqual(by_name["Perpetual Timepiece"]["execution_status"], "auto")
        self.assertEqual(
            by_name["Perpetual Timepiece"]["logical_rule_key"],
            "battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d",
        )
        self.assertEqual(by_name["Perpetual Timepiece"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Perpetual Timepiece"]["effect_json"]["activated_self_mill_count"], 2)
        self.assertEqual(
            by_name["Perpetual Timepiece"]["effect_json"]["graveyard_shuffle_activation_cost_generic"],
            2,
        )
        self.assertFalse(
            by_name["Perpetual Timepiece"]["effect_json"]["graveyard_shuffle_activation_requires_tap"]
        )
        self.assertTrue(by_name["Perpetual Timepiece"]["effect_json"]["graveyard_shuffle_exiles_self"])
        self.assertEqual(
            by_name["Perpetual Timepiece"]["effect_json"]["battle_model_scope"],
            "tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1",
        )
        self.assertNotIn(
            "xmage_graveyard_return_variant_review_v1",
            by_name["Perpetual Timepiece"]["effect_json"]["battle_model_scope"],
        )
        self.assertEqual(by_name["Breena, the Demagogue"]["source"], "curated")
        self.assertEqual(by_name["Breena, the Demagogue"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Breena, the Demagogue"]["effect_json"]["political_attack_draw_trigger"])
        self.assertEqual(by_name["Ancient Tomb"]["source"], "curated")
        self.assertEqual(by_name["Ancient Tomb"]["review_status"], "verified")
        self.assertEqual(by_name["Ancient Tomb"]["effect_json"]["effect"], "land")
        self.assertEqual(by_name["Ancient Tomb"]["effect_json"]["ancient_tomb_bonus_mana"], 1)
        self.assertEqual(by_name["Ancient Tomb"]["effect_json"]["ancient_tomb_bonus_life_cost"], 2)
        aven_rows = [
            row for row in rows if row["card_name"] == "Aven Mindcensor"
        ]
        self.assertEqual(len(aven_rows), 2)
        self.assertEqual(by_name["Aven Mindcensor"]["source"], "curated")
        self.assertEqual(by_name["Aven Mindcensor"]["review_status"], "verified")
        self.assertEqual(by_name["Aven Mindcensor"]["execution_status"], "auto")
        self.assertEqual(by_name["Aven Mindcensor"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Aven Mindcensor"]["effect_json"]["power"], 2)
        self.assertEqual(by_name["Aven Mindcensor"]["effect_json"]["toughness"], 1)
        self.assertTrue(
            any(
                row["effect_json"].get("opponent_library_search_limited_to_top_cards") == 4
                and row["execution_status"] == "annotation_only"
                for row in aven_rows
            )
        )
        self.assertEqual(by_name["Basking Broodscale"]["source"], "curated")
        self.assertEqual(by_name["Basking Broodscale"]["review_status"], "active")
        self.assertEqual(by_name["Basking Broodscale"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Basking Broodscale"]["effect_json"]["is_creature_permanent"])
        self.assertEqual(by_name["Birgi, God of Storytelling"]["source"], "curated")
        self.assertEqual(
            by_name["Birgi, God of Storytelling"]["effect_json"]["spell_cast_add_mana"],
            1,
        )
        self.assertEqual(by_name["Big Score"]["source"], "curated")
        self.assertEqual(by_name["Big Score"]["review_status"], "verified")
        self.assertEqual(by_name["Big Score"]["effect_json"]["effect"], "treasure_maker")
        self.assertEqual(by_name["Big Score"]["effect_json"]["draw_count"], 2)
        self.assertEqual(by_name["Big Score"]["effect_json"]["treasure_count"], 2)
        self.assertTrue(by_name["Big Score"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Channeled Force"]["source"], "curated")
        self.assertEqual(by_name["Channeled Force"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Channeled Force"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Chrome Mox"]["source"], "curated")
        self.assertEqual(by_name["Chrome Mox"]["review_status"], "verified")
        self.assertTrue(
            by_name["Chrome Mox"]["effect_json"]["requires_imprint_nonartifact_nonland"]
        )
        self.assertEqual(by_name["Chromatic Star"]["review_status"], "active")
        self.assertEqual(
            by_name["Chromatic Star"]["effect_json"]["effect"],
            "cantrip_mana_filter_artifact",
        )
        self.assertEqual(by_name["Crop Rotation"]["effect_json"]["effect"], "land_ramp")
        self.assertTrue(by_name["Crop Rotation"]["effect_json"]["requires_sacrifice_land"])
        self.assertFalse(by_name["Crop Rotation"]["effect_json"]["land_enters_tapped"])
        self.assertEqual(by_name["Curator's Ward"]["source"], "curated")
        self.assertEqual(by_name["Curator's Ward"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Curator's Ward"]["effect_json"]["enchanted_permanent_has_hexproof"])
        self.assertEqual(by_name["Dismember"]["source"], "curated")
        self.assertEqual(by_name["Dismember"]["review_status"], "verified")
        self.assertEqual(by_name["Dismember"]["effect_json"]["effect"], "remove_creature")
        self.assertEqual(by_name["Dismember"]["effect_json"]["target"], "creature")
        self.assertEqual(by_name["Dismember"]["effect_json"]["toughness_boost"], -5)
        self.assertTrue(by_name["Dismember"]["effect_json"]["uses_stat_modifier_removal"])
        self.assertEqual(by_name["Decaying Time Loop"]["source"], "curated")
        self.assertEqual(by_name["Decaying Time Loop"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Decaying Time Loop"]["effect_json"]["draw_equal_to_discarded_hand"])
        self.assertEqual(by_name["Drown in Dreams"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Drown in Dreams"]["effect_json"]["x_spell"])
        self.assertTrue(by_name["Drown in Dreams"]["effect_json"]["modal_draw_x"])
        self.assertEqual(by_name["Electric Revelation"]["source"], "curated")
        self.assertEqual(by_name["Electric Revelation"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Electric Revelation"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Entomb"]["effect_json"]["effect"], "tutor")
        self.assertEqual(by_name["Entomb"]["effect_json"]["target"], "graveyard")
        self.assertEqual(by_name["Empowered Autogenerator"]["source"], "curated")
        self.assertEqual(by_name["Empowered Autogenerator"]["effect_json"]["effect"], "ramp_permanent")
        self.assertTrue(by_name["Empowered Autogenerator"]["effect_json"]["enters_tapped"])
        self.assertTrue(by_name["Empowered Autogenerator"]["effect_json"]["charge_counter_scaling_mana"])
        self.assertEqual(by_name["Ether"]["source"], "curated")
        self.assertEqual(by_name["Ether"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Ether"]["effect_json"]["activated_exile_self_for_mana"])
        self.assertTrue(by_name["Ether"]["effect_json"]["copy_next_instant_or_sorcery_this_turn"])
        self.assertEqual(by_name["Fellwar Stone"]["source"], "curated")
        self.assertEqual(by_name["Fellwar Stone"]["review_status"], "active")
        self.assertEqual(by_name["Fellwar Stone"]["effect_json"]["effect"], "ramp_permanent")
        self.assertTrue(by_name["Fellwar Stone"]["effect_json"]["conditionally_produces_opponent_land_colors"])
        self.assertEqual(by_name["Electroduplicate"]["source"], "curated")
        self.assertEqual(
            by_name["Electroduplicate"]["effect_json"]["effect"],
            "copy_creature_token",
        )
        self.assertEqual(by_name["Firemind Vessel"]["source"], "curated")
        self.assertEqual(by_name["Firemind Vessel"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Firemind Vessel"]["effect_json"]["mana_produced"], 2)
        self.assertTrue(by_name["Firemind Vessel"]["effect_json"]["enters_tapped"])
        self.assertEqual(by_name["Everflowing Chalice"]["source"], "curated")
        self.assertEqual(by_name["Everflowing Chalice"]["review_status"], "verified")
        self.assertEqual(
            by_name["Everflowing Chalice"]["effect_json"]["multikicker_generic_cost"],
            2,
        )
        self.assertEqual(by_name["Fateful Showdown"]["source"], "curated")
        self.assertTrue(by_name["Fateful Showdown"]["effect_json"]["draw_equal_to_discarded_hand"])
        self.assertEqual(by_name["Formidable Speaker"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Gemstone Caverns"]["effect_json"]["produces"], "WUBRGC")
        self.assertEqual(by_name["Goblin Bombardment"]["source"], "curated")
        self.assertEqual(by_name["Goblin Bombardment"]["review_status"], "verified")
        self.assertEqual(by_name["Goblin Bombardment"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Goblin Bombardment"]["effect_json"]["activated_sacrifice_creature_damage"])
        self.assertEqual(by_name["Goblin Bombardment"]["effect_json"]["damage"], 1)
        self.assertEqual(by_name["Great Furnace"]["effect_json"]["produces"], "R")
        self.assertEqual(
            by_name["Hall of Heliod's Generosity"]["effect_json"]["utility_land_profile"],
            "hall_of_heliods_generosity_v1",
        )
        self.assertEqual(by_name["Hypothesizzle"]["source"], "curated")
        self.assertEqual(by_name["Hypothesizzle"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Hypothesizzle"]["effect_json"]["count"], 2)
        self.assertEqual(by_name["Ichor Elixir"]["source"], "curated")
        self.assertEqual(by_name["Ichor Elixir"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Ichor Elixir"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Izzet Signet"]["source"], "curated")
        self.assertEqual(by_name["Izzet Signet"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Izzet Signet"]["effect_json"]["produces"], "UR")
        self.assertEqual(by_name["Kraum, Ludevic's Opus"]["source"], "curated")
        self.assertEqual(by_name["Kraum, Ludevic's Opus"]["effect_json"]["effect"], "draw_engine")
        self.assertTrue(by_name["Kraum, Ludevic's Opus"]["effect_json"]["opponent_second_spell_each_turn"])
        self.assertFalse(by_name["Kraum, Ludevic's Opus"]["effect_json"]["draw_on_enter"])
        self.assertEqual(by_name["Incubation Druid"]["source"], "curated")
        self.assertEqual(by_name["Incubation Druid"]["review_status"], "active")
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Incubation Druid"]["effect_json"]["is_mana_source"])
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["mana_produced"], 1)
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["battle_model_scope"], "mana_dork_without_adapt_v1")
        self.assertEqual(
            by_name["Inventors' Fair"]["effect_json"]["utility_land_profile"],
            "inventors_fair_v1",
        )
        self.assertEqual(by_name["Lapse of Certainty"]["source"], "curated")
        self.assertEqual(by_name["Lapse of Certainty"]["review_status"], "active")
        self.assertEqual(by_name["Lapse of Certainty"]["execution_status"], "auto")
        self.assertTrue(
            by_name["Lapse of Certainty"]["effect_json"]["countered_spell_to_top_library"]
        )
        self.assertTrue(
            by_name["Lapse of Certainty"]["effect_json"]["counter_own_approach_to_top"]
        )
        self.assertEqual(by_name["Library of Leng"]["source"], "curated")
        self.assertEqual(by_name["Library of Leng"]["review_status"], "active")
        self.assertTrue(by_name["Library of Leng"]["effect_json"]["no_max_hand_size"])
        self.assertTrue(
            by_name["Library of Leng"]["effect_json"]["discard_effect_to_top_replacement"]
        )
        self.assertEqual(by_name["Lightning Greaves"]["source"], "curated")
        self.assertEqual(
            by_name["Lightning Greaves"]["effect_json"]["effect"],
            "equipment_haste_shroud",
        )
        self.assertEqual(by_name["Laughing Mad"]["source"], "curated")
        self.assertEqual(by_name["Laughing Mad"]["effect_json"]["effect"], "draw_cards")
        self.assertTrue(by_name["Laughing Mad"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Lorehold, the Historian"]["source"], "curated")
        self.assertEqual(by_name["Lorehold, the Historian"]["review_status"], "active")
        self.assertEqual(by_name["Lorehold, the Historian"]["effect_json"]["effect"], "passive")
        self.assertEqual(
            by_name["Lorehold, the Historian"]["effect_json"]["grants_miracle_cost"],
            2,
        )
        self.assertTrue(
            by_name["Lorehold, the Historian"]["effect_json"]["opponent_upkeep_rummage"]
        )
        self.assertEqual(by_name["Lumra, Bellow of the Woods"]["effect_json"]["effect"], "land_recursion_creature")
        self.assertEqual(by_name["Lumra, Bellow of the Woods"]["effect_json"]["mill_count"], 4)
        self.assertEqual(by_name["Magma Opus"]["source"], "curated")
        self.assertEqual(by_name["Magma Opus"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Magma Opus"]["effect_json"]["count"], 2)
        self.assertTrue(by_name["Magma Opus"]["effect_json"]["discard_for_treasure"])
        self.assertEqual(by_name["Mana Vault"]["source"], "curated")
        self.assertEqual(by_name["Mana Vault"]["review_status"], "active")
        self.assertEqual(by_name["Mana Vault"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Mana Vault"]["effect_json"]["mana_produced"], 3)
        self.assertTrue(by_name["Mana Vault"]["effect_json"]["does_not_untap_normally"])
        self.assertEqual(by_name["Miscast"]["source"], "curated")
        self.assertEqual(by_name["Miscast"]["review_status"], "verified")
        self.assertEqual(by_name["Miscast"]["effect_json"]["effect"], "counter")
        self.assertEqual(by_name["Miscast"]["effect_json"]["target"], "instant_or_sorcery")
        self.assertEqual(by_name["Mystical Tutor"]["effect_json"]["effect"], "tutor")
        self.assertEqual(by_name["Mystical Tutor"]["effect_json"]["target"], "instant_or_sorcery")
        self.assertEqual(by_name["Mox Amber"]["source"], "curated")
        self.assertEqual(by_name["Mox Amber"]["review_status"], "verified")
        self.assertEqual(by_name["Mox Amber"]["effect_json"]["effect"], "ramp_permanent")
        self.assertTrue(
            by_name["Mox Amber"]["effect_json"][
                "requires_legendary_creature_or_planeswalker_for_mana"
            ]
        )
        self.assertEqual(by_name["Mox Diamond"]["source"], "curated")
        self.assertEqual(by_name["Mox Diamond"]["review_status"], "verified")
        self.assertTrue(by_name["Mox Diamond"]["effect_json"]["requires_discard_land"])
        self.assertEqual(by_name["Mind Stone"]["source"], "curated")
        self.assertEqual(by_name["Mind Stone"]["review_status"], "active")
        self.assertEqual(by_name["Mind Stone"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Mind Stone"]["effect_json"]["mana_produced"], 1)
        self.assertTrue(by_name["Mind Stone"]["effect_json"]["activated_self_sacrifice_draw"])
        self.assertEqual(by_name["Victory Chimes"]["source"], "curated")
        self.assertEqual(by_name["Victory Chimes"]["review_status"], "verified")
        self.assertEqual(by_name["Victory Chimes"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Victory Chimes"]["effect_json"]["mana_produced"], 1)
        self.assertTrue(
            by_name["Victory Chimes"]["effect_json"]["untaps_each_opponent_untap"]
        )
        self.assertEqual(by_name["Nature's Claim"]["effect_json"]["target"], "artifact_or_enchantment")
        self.assertEqual(by_name["Natural Order"]["source"], "curated")
        self.assertEqual(by_name["Natural Order"]["review_status"], "verified")
        self.assertEqual(by_name["Natural Order"]["effect_json"]["effect"], "tutor")
        self.assertEqual(
            by_name["Natural Order"]["effect_json"]["target"],
            "green_creature_to_battlefield",
        )
        self.assertTrue(
            by_name["Natural Order"]["effect_json"]["requires_sacrifice_green_creature"]
        )
        self.assertEqual(by_name["One with the Multiverse"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["One with the Multiverse"]["effect_json"]["play_from_top_of_library"])
        self.assertEqual(by_name["Path to Exile"]["source"], "curated")
        self.assertEqual(by_name["Path to Exile"]["review_status"], "active")
        self.assertEqual(by_name["Path to Exile"]["effect_json"]["effect"], "remove_creature")
        self.assertTrue(by_name["Path to Exile"]["effect_json"]["exile_target"])
        self.assertTrue(by_name["Path to Exile"]["effect_json"]["target_controller_basic_land_tapped"])
        self.assertEqual(by_name["Pirate's Pillage"]["source"], "curated")
        self.assertEqual(by_name["Pirate's Pillage"]["effect_json"]["effect"], "treasure_maker")
        self.assertEqual(by_name["Pirate's Pillage"]["effect_json"]["treasure_count"], 2)
        self.assertEqual(by_name["Prismatic Lens"]["source"], "curated")
        self.assertEqual(by_name["Prismatic Lens"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Prismatic Lens"]["effect_json"]["mana_produced"], 1)
        self.assertEqual(by_name["Practical Research"]["source"], "curated")
        self.assertEqual(by_name["Practical Research"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Practical Research"]["effect_json"]["count"], 4)
        self.assertEqual(by_name["Practical Research"]["effect_json"]["discard_count"], 2)
        self.assertEqual(by_name["Radiant Scrollwielder"]["source"], "curated")
        self.assertEqual(by_name["Radiant Scrollwielder"]["review_status"], "active")
        self.assertEqual(by_name["Radiant Scrollwielder"]["execution_status"], "auto")
        self.assertTrue(
            by_name["Radiant Scrollwielder"]["effect_json"][
                "instant_sorcery_spells_you_control_have_lifelink"
            ]
        )
        self.assertTrue(
            by_name["Radiant Scrollwielder"]["effect_json"][
                "upkeep_exile_random_instant_sorcery_from_graveyard"
            ]
        )
        self.assertEqual(by_name["Rampant Growth"]["effect_json"]["effect"], "land_ramp")
        self.assertTrue(by_name["Rampant Growth"]["effect_json"]["basic_only"])
        self.assertTrue(by_name["Rampant Growth"]["effect_json"]["land_enters_tapped"])
        self.assertEqual(by_name["Rakdos, the Muscle"]["source"], "curated")
        self.assertEqual(by_name["Rakdos, the Muscle"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Rakdos, the Muscle"]["effect_json"]["sacrifice_creature_grants_indestructible"])
        self.assertEqual(by_name["Reanimate"]["effect_json"]["effect"], "recursion")
        self.assertEqual(by_name["Reanimate"]["effect_json"]["destination"], "battlefield")
        self.assertEqual(by_name["Ring of the Lucii"]["source"], "curated")
        self.assertEqual(by_name["Ring of the Lucii"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Ring of the Lucii"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Runaway Steam-Kin"]["source"], "curated")
        self.assertEqual(by_name["Runaway Steam-Kin"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Runaway Steam-Kin"]["effect_json"]["is_creature_permanent"])
        self.assertEqual(by_name["Sami's Curiosity"]["source"], "curated")
        self.assertEqual(by_name["Sami's Curiosity"]["effect_json"]["effect"], "lander_token_maker")
        self.assertEqual(by_name["Sami's Curiosity"]["effect_json"]["life_gain"], 2)
        self.assertEqual(by_name["Sazacap's Brew"]["source"], "curated")
        self.assertEqual(by_name["Sazacap's Brew"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Sazacap's Brew"]["effect_json"]["count"], 2)
        self.assertTrue(by_name["Sazacap's Brew"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Scavenging Ooze"]["source"], "curated")
        self.assertEqual(by_name["Scavenging Ooze"]["review_status"], "active")
        self.assertEqual(by_name["Scavenging Ooze"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Scavenging Ooze"]["effect_json"]["activated_graveyard_exile"])
        self.assertEqual(by_name["Shark Typhoon"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Shark Typhoon"]["effect_json"]["trigger"], "noncreature_spell_cast")
        self.assertTrue(
            by_name["Shark Typhoon"]["effect_json"]["spell_cast_token_power_from_spell_cmc"]
        )
        self.assertEqual(by_name["Shantotto, Tactician Magician"]["source"], "curated")
        self.assertEqual(by_name["Shantotto, Tactician Magician"]["effect_json"]["effect"], "creature")
        self.assertEqual(
            by_name["Shantotto, Tactician Magician"]["effect_json"]["spell_cast_draw_if_cmc_at_least"],
            4,
        )
        self.assertEqual(by_name["Sisay, Weatherlight Captain"]["source"], "curated")
        self.assertEqual(by_name["Sisay, Weatherlight Captain"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Sisay, Weatherlight Captain"]["effect_json"]["activated_legendary_tutor"])
        self.assertEqual(by_name["Sisay's Ring"]["source"], "curated")
        self.assertEqual(by_name["Sisay's Ring"]["review_status"], "verified")
        self.assertEqual(by_name["Sisay's Ring"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Sisay's Ring"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Seething Song"]["source"], "curated")
        self.assertEqual(by_name["Seething Song"]["review_status"], "verified")
        self.assertEqual(by_name["Seething Song"]["effect_json"]["effect"], "ramp_ritual")
        self.assertEqual(by_name["Seething Song"]["effect_json"]["mana_produced"], 5)
        self.assertEqual(by_name["Spelltwine"]["source"], "curated")
        self.assertEqual(by_name["Spelltwine"]["review_status"], "active")
        self.assertEqual(by_name["Spelltwine"]["effect_json"]["effect"], "copy_spell")
        self.assertEqual(
            by_name["Spelltwine"]["effect_json"]["target"],
            "instant_or_sorcery_graveyards",
        )
        self.assertTrue(by_name["Spelltwine"]["effect_json"]["casts_copies_without_paying_mana"])
        self.assertTrue(by_name["Spelltwine"]["effect_json"]["exiles_self"])
        self.assertEqual(by_name["Sunbaked Canyon"]["effect_json"]["produces"], "WR")
        self.assertEqual(by_name["Talisman of Conviction"]["source"], "curated")
        self.assertEqual(by_name["Talisman of Conviction"]["review_status"], "active")
        self.assertEqual(by_name["Talisman of Conviction"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Talisman of Conviction"]["effect_json"]["mana_produced"], 1)
        self.assertEqual(by_name["Talisman of Conviction"]["effect_json"]["life_for_colored_mana"], 1)
        self.assertEqual(by_name["Teferi's Protection"]["source"], "curated")
        self.assertEqual(by_name["Teferi's Protection"]["review_status"], "active")
        self.assertEqual(by_name["Teferi's Protection"]["execution_status"], "auto")
        self.assertEqual(by_name["Teferi's Protection"]["oracle_hash"], "bdc0faecf4420dc6162c7e72e98cc0eb")
        self.assertEqual(by_name["Teferi's Protection"]["effect_json"]["effect"], "phase_out")
        self.assertTrue(by_name["Teferi's Protection"]["effect_json"]["life_total_cant_change"])
        self.assertTrue(by_name["Teferi's Protection"]["effect_json"]["protection_from_everything"])
        self.assertTrue(by_name["Teferi's Protection"]["effect_json"]["phase_out_all_permanents_you_control"])
        self.assertTrue(by_name["Teferi's Protection"]["effect_json"]["phase_out_includes_lands"])
        self.assertTrue(by_name["Teferi's Protection"]["effect_json"]["exiles_self"])
        self.assertEqual(by_name["Ur-Golem's Eye"]["source"], "curated")
        self.assertEqual(by_name["Ur-Golem's Eye"]["review_status"], "verified")
        self.assertEqual(by_name["Ur-Golem's Eye"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Valakut Awakening"]["source"], "curated")
        self.assertEqual(by_name["Valakut Awakening"]["review_status"], "active")
        self.assertEqual(by_name["Valakut Awakening"]["execution_status"], "auto")
        self.assertEqual(by_name["Valakut Awakening"]["oracle_hash"], "22b42fcc181b7aed71f78b2e1e51e887")
        self.assertEqual(by_name["Valakut Awakening"]["effect_json"]["effect"], "hand_filter")
        self.assertEqual(by_name["Valakut Awakening"]["effect_json"]["draw_extra"], 1)
        self.assertEqual(by_name["Urza's Saga"]["effect_json"]["produces"], "C")
        self.assertEqual(
            by_name["Valakut Awakening // Valakut Stoneforge"]["review_status"],
            "active",
        )
        self.assertEqual(
            by_name["Valakut Awakening // Valakut Stoneforge"]["execution_status"],
            "auto",
        )
        self.assertEqual(
            by_name["Valakut Awakening // Valakut Stoneforge"]["oracle_hash"],
            "22b42fcc181b7aed71f78b2e1e51e887",
        )
        self.assertEqual(
            by_name["Valakut Awakening // Valakut Stoneforge"]["effect_json"]["mdfc_land_face"]["produces"],
            "R",
        )
        self.assertEqual(by_name["Volcanic Vision"]["source"], "curated")
        self.assertEqual(by_name["Volcanic Vision"]["effect_json"]["effect"], "recursion")
        self.assertEqual(by_name["Volcanic Vision"]["effect_json"]["target"], "instant_or_sorcery")
        self.assertTrue(by_name["Volcanic Vision"]["effect_json"]["exiles_self"])
        self.assertEqual(by_name["Wheel of Fortune"]["source"], "curated")
        self.assertEqual(by_name["Wheel of Fortune"]["review_status"], "active")
        self.assertEqual(by_name["Wheel of Fortune"]["execution_status"], "auto")
        self.assertEqual(by_name["Wheel of Fortune"]["oracle_hash"], "c37cd579d8132efac0c2118608f6f001")
        self.assertEqual(by_name["Wheel of Fortune"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Wheel of Fortune"]["effect_json"]["count"], 7)
        self.assertTrue(by_name["Wheel of Fortune"]["effect_json"]["wheel_like"])
        self.assertTrue(by_name["Wheel of Fortune"]["effect_json"]["discard_hand_each_player"])
        self.assertEqual(
            by_name["Wheel of Fortune"]["effect_json"]["battle_model_scope"],
            "multiplayer_discard_draw_v1",
        )
        self.assertEqual(by_name["Scroll Rack"]["source"], "curated")
        self.assertEqual(by_name["Scroll Rack"]["review_status"], "active")
        self.assertTrue(by_name["Scroll Rack"]["effect_json"]["hand_to_top_exchange"])
        self.assertEqual(
            by_name["Scroll Rack"]["effect_json"]["battle_model_scope"],
            "scroll_rack_upkeep_single_exchange_v1",
        )
        self.assertEqual(by_name["Skullclamp"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Skullclamp"]["effect_json"]["draw_on_equipped_death"], 2)
        self.assertEqual(
            by_name["Sensei's Divining Top"]["source"],
            "curated",
        )
        self.assertEqual(
            by_name["Sensei's Divining Top"]["review_status"],
            "active",
        )
        self.assertEqual(
            by_name["Sensei's Divining Top"]["effect_json"]["peek_top_count"],
            3,
        )
        self.assertTrue(
            by_name["Sensei's Divining Top"]["effect_json"]["reorder_top"]
        )
        self.assertEqual(by_name["Soul-Guide Lantern"]["effect_json"]["effect"], "hate_artifact")
        self.assertEqual(by_name["Stonespeaker Crystal"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Stonespeaker Crystal"]["effect_json"]["mana_produced"], 2)
        self.assertTrue(by_name["Stonespeaker Crystal"]["effect_json"]["activated_self_sacrifice_draw"])
        self.assertEqual(by_name["Splendid Reclamation"]["effect_json"]["effect"], "land_recursion")
        self.assertEqual(by_name["Staff of Compleation"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Silence"]["source"], "curated")
        self.assertEqual(by_name["Silence"]["review_status"], "verified")
        self.assertEqual(by_name["Silence"]["effect_json"]["effect"], "silence_spell")
        self.assertEqual(by_name["The Emperor of Palamecia"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["The Emperor of Palamecia"]["effect_json"]["is_mana_source"])
        self.assertEqual(by_name["The Emperor of Palamecia"]["effect_json"]["produces"], "UR")
        self.assertEqual(by_name["Tellah, Great Sage"]["source"], "curated")
        self.assertEqual(by_name["Tellah, Great Sage"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Tellah, Great Sage"]["effect_json"]["spell_cast_draw_if_cmc_at_least"], 4)
        self.assertEqual(by_name["The Unagi of Kyoshi Island"]["source"], "curated")
        self.assertEqual(by_name["The Unagi of Kyoshi Island"]["effect_json"]["effect"], "creature")
        self.assertEqual(
            by_name["The Unagi of Kyoshi Island"]["effect_json"]["opponent_second_draw_each_turn_draw_count"],
            2,
        )
        self.assertEqual(by_name["Unexpected Windfall"]["source"], "curated")
        self.assertEqual(by_name["Unexpected Windfall"]["review_status"], "verified")
        self.assertEqual(
            by_name["Unexpected Windfall"]["effect_json"]["effect"],
            "treasure_maker",
        )
        self.assertEqual(by_name["Unexpected Windfall"]["effect_json"]["draw_count"], 2)
        self.assertEqual(by_name["Unexpected Windfall"]["effect_json"]["treasure_count"], 2)
        self.assertEqual(by_name["Vexing Bauble"]["source"], "curated")
        self.assertEqual(by_name["Vexing Bauble"]["review_status"], "verified")
        self.assertEqual(by_name["Vexing Bauble"]["effect_json"]["effect"], "hate_artifact")
        self.assertTrue(
            by_name["Vexing Bauble"]["effect_json"]["counters_free_spells"]
        )
        self.assertEqual(by_name["Wall of Omens"]["source"], "curated")
        self.assertEqual(by_name["Wall of Omens"]["review_status"], "verified")
        self.assertEqual(by_name["Wall of Omens"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Wall of Omens"]["effect_json"]["etb_draw_count"], 1)
        self.assertEqual(by_name["War Room"]["effect_json"]["produces"], "C")
        self.assertEqual(by_name["Wayfarer's Bauble"]["source"], "curated")
        self.assertEqual(by_name["Wayfarer's Bauble"]["review_status"], "active")
        self.assertEqual(by_name["Wayfarer's Bauble"]["effect_json"]["effect"], "ramp_permanent")
        self.assertTrue(by_name["Wayfarer's Bauble"]["effect_json"]["activated_self_sacrifice_land_tutor"])
        self.assertTrue(by_name["Wayfarer's Bauble"]["effect_json"]["basic_only"])
        self.assertEqual(by_name["Woodland Bellower"]["source"], "curated")
        self.assertEqual(by_name["Woodland Bellower"]["review_status"], "verified")
        self.assertEqual(by_name["Woodland Bellower"]["effect_json"]["effect"], "creature")
        self.assertEqual(
            by_name["Woodland Bellower"]["effect_json"]["etb_tutor_nonlegendary_green_creature_mv_lte"],
            3,
        )
        self.assertEqual(by_name["Worldfire"]["source"], "curated")
        self.assertEqual(by_name["Worldfire"]["review_status"], "verified")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["effect"], "worldfire_reset")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["set_life_total"], 1)
        self.assertEqual(by_name["Zuran Orb"]["source"], "curated")
        self.assertEqual(by_name["Zuran Orb"]["review_status"], "verified")
        self.assertEqual(by_name["Zuran Orb"]["effect_json"]["effect"], "life_artifact")
        self.assertEqual(
            by_name["Zuran Orb"]["effect_json"]["sacrifice_land_gain_life"],
            2,
        )

    def test_sync_build_rows_includes_reviewed_rules_without_generated_layer(self) -> None:
        rows = sync_rules.build_rows(
            include_generated=False,
            sqlite_db=str(sync_rules.DEFAULT_DB),
            reviewed_rules_path=DEFAULT_REVIEWED_RULES_PATH,
        )
        by_name = {row["card_name"]: row for row in rows}

        self.assertEqual(by_name["Ashnod's Altar"]["source"], "curated")
        self.assertEqual(by_name["Ashnod's Altar"]["review_status"], "active")
        self.assertEqual(by_name["Ashnod's Altar"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Ashnod's Altar"]["effect_json"]["activated_mana_ability"])
        self.assertEqual(by_name["Akroma's Will"]["source"], "curated")
        self.assertEqual(by_name["Akroma's Will"]["effect_json"]["effect"], "pump_all")
        self.assertEqual(by_name["Angel's Grace"]["source"], "curated")
        self.assertEqual(by_name["Angel's Grace"]["effect_json"]["effect"], "cannot_lose_turn")
        self.assertEqual(by_name["Apex of Power"]["source"], "curated")
        self.assertEqual(by_name["Apex of Power"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Approach of the Second Sun"]["source"], "curated")
        self.assertEqual(
            by_name["Approach of the Second Sun"]["effect_json"]["effect"],
            "approach",
        )
        self.assertEqual(
            by_name["Approach of the Second Sun"]["effect_json"]["battle_model_scope"],
            "approach_second_cast_win_v2",
        )
        self.assertEqual(by_name["Archaeomancer's Map"]["source"], "curated")
        self.assertEqual(
            by_name["Archaeomancer's Map"]["effect_json"]["battle_model_scope"],
            "basic_plains_etb_plus_opponent_land_catchup_v2",
        )
        self.assertEqual(
            by_name["Archaeomancer's Map"]["oracle_hash"],
            "22b82ca6bbef42371227bc38a9a546b5",
        )
        self.assertEqual(by_name["Arcane Endeavor"]["source"], "curated")
        self.assertEqual(by_name["Arcane Endeavor"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Birgi, God of Storytelling"]["source"], "curated")
        self.assertEqual(
            by_name["Birgi, God of Storytelling"]["effect_json"]["spell_cast_add_mana"],
            1,
        )
        self.assertEqual(by_name["Big Score"]["source"], "curated")
        self.assertEqual(by_name["Big Score"]["effect_json"]["effect"], "treasure_maker")
        self.assertEqual(by_name["Big Score"]["effect_json"]["treasure_count"], 2)
        self.assertEqual(by_name["Breena, the Demagogue"]["source"], "curated")
        self.assertEqual(by_name["Breena, the Demagogue"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Chrome Mox"]["source"], "curated")
        self.assertTrue(
            by_name["Chrome Mox"]["effect_json"]["requires_imprint_nonartifact_nonland"]
        )
        self.assertEqual(by_name["Chromatic Star"]["source"], "curated")
        self.assertEqual(
            by_name["Chromatic Star"]["effect_json"]["effect"],
            "cantrip_mana_filter_artifact",
        )
        self.assertEqual(by_name["Crop Rotation"]["source"], "curated")
        self.assertEqual(by_name["Crop Rotation"]["effect_json"]["effect"], "land_ramp")
        self.assertTrue(by_name["Crop Rotation"]["effect_json"]["requires_sacrifice_land"])
        self.assertEqual(by_name["Curator's Ward"]["source"], "curated")
        self.assertEqual(by_name["Curator's Ward"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Dismember"]["source"], "curated")
        self.assertEqual(by_name["Dismember"]["effect_json"]["effect"], "remove_creature")
        self.assertTrue(by_name["Dismember"]["effect_json"]["uses_stat_modifier_removal"])
        self.assertEqual(by_name["Decaying Time Loop"]["source"], "curated")
        self.assertTrue(by_name["Decaying Time Loop"]["effect_json"]["draw_equal_to_discarded_hand"])
        self.assertEqual(by_name["Electric Revelation"]["source"], "curated")
        self.assertTrue(by_name["Electric Revelation"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Entomb"]["source"], "curated")
        self.assertEqual(by_name["Entomb"]["effect_json"]["target"], "graveyard")
        self.assertEqual(by_name["Empowered Autogenerator"]["source"], "curated")
        self.assertTrue(by_name["Empowered Autogenerator"]["effect_json"]["enters_tapped"])
        self.assertEqual(by_name["Ether"]["source"], "curated")
        self.assertEqual(by_name["Ether"]["effect_json"]["effect"], "passive")
        self.assertEqual(by_name["Electroduplicate"]["source"], "curated")
        self.assertEqual(
            by_name["Electroduplicate"]["effect_json"]["effect"],
            "copy_creature_token",
        )
        self.assertEqual(by_name["Everflowing Chalice"]["source"], "curated")
        self.assertEqual(
            by_name["Everflowing Chalice"]["effect_json"]["multikicker_generic_cost"],
            2,
        )
        self.assertEqual(by_name["Fateful Showdown"]["source"], "curated")
        self.assertTrue(by_name["Fateful Showdown"]["effect_json"]["draw_equal_to_discarded_hand"])
        self.assertEqual(by_name["Goblin Bombardment"]["source"], "curated")
        self.assertEqual(by_name["Goblin Bombardment"]["effect_json"]["effect"], "passive")
        self.assertTrue(by_name["Goblin Bombardment"]["effect_json"]["sacrifice_creature_damage"])
        self.assertEqual(by_name["Incubation Druid"]["source"], "curated")
        self.assertEqual(by_name["Incubation Druid"]["review_status"], "active")
        self.assertEqual(by_name["Incubation Druid"]["effect_json"]["effect"], "creature")
        self.assertTrue(by_name["Incubation Druid"]["effect_json"]["is_mana_source"])
        self.assertEqual(by_name["Izzet Signet"]["source"], "curated")
        self.assertEqual(by_name["Izzet Signet"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Kraum, Ludevic's Opus"]["source"], "curated")
        self.assertEqual(by_name["Kraum, Ludevic's Opus"]["effect_json"]["effect"], "draw_engine")
        self.assertEqual(by_name["Library of Leng"]["source"], "curated")
        self.assertTrue(by_name["Library of Leng"]["effect_json"]["no_max_hand_size"])
        self.assertEqual(by_name["Lightning Greaves"]["source"], "curated")
        self.assertEqual(
            by_name["Lightning Greaves"]["effect_json"]["effect"],
            "equipment_haste_shroud",
        )
        self.assertEqual(by_name["Lorehold, the Historian"]["source"], "curated")
        self.assertEqual(by_name["Lorehold, the Historian"]["effect_json"]["grants_miracle_cost"], 2)
        self.assertEqual(by_name["Lumra, Bellow of the Woods"]["source"], "curated")
        self.assertEqual(by_name["Lumra, Bellow of the Woods"]["effect_json"]["effect"], "land_recursion_creature")
        self.assertEqual(by_name["Magma Opus"]["source"], "curated")
        self.assertEqual(by_name["Magma Opus"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Miscast"]["source"], "curated")
        self.assertEqual(by_name["Miscast"]["effect_json"]["effect"], "counter")
        self.assertEqual(by_name["Mystical Tutor"]["source"], "curated")
        self.assertEqual(by_name["Mystical Tutor"]["effect_json"]["target"], "instant_or_sorcery")
        self.assertEqual(by_name["Mox Amber"]["source"], "curated")
        self.assertTrue(
            by_name["Mox Amber"]["effect_json"][
                "requires_legendary_creature_or_planeswalker_for_mana"
            ]
        )
        self.assertEqual(by_name["Mox Diamond"]["source"], "curated")
        self.assertTrue(by_name["Mox Diamond"]["effect_json"]["requires_discard_land"])
        self.assertEqual(by_name["Victory Chimes"]["source"], "curated")
        self.assertEqual(by_name["Victory Chimes"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Victory Chimes"]["effect_json"]["mana_produced"], 1)
        self.assertEqual(by_name["Natural Order"]["source"], "curated")
        self.assertEqual(by_name["Natural Order"]["effect_json"]["effect"], "tutor")
        self.assertEqual(
            by_name["Natural Order"]["effect_json"]["target"],
            "green_creature_to_battlefield",
        )
        self.assertEqual(by_name["Pirate's Pillage"]["source"], "curated")
        self.assertEqual(by_name["Pirate's Pillage"]["effect_json"]["effect"], "treasure_maker")
        self.assertEqual(by_name["Prismatic Lens"]["source"], "curated")
        self.assertEqual(by_name["Prismatic Lens"]["effect_json"]["effect"], "ramp_permanent")
        self.assertEqual(by_name["Practical Research"]["source"], "curated")
        self.assertEqual(by_name["Practical Research"]["effect_json"]["effect"], "draw_cards")
        self.assertEqual(by_name["Rampant Growth"]["source"], "curated")
        self.assertEqual(by_name["Rampant Growth"]["effect_json"]["effect"], "land_ramp")
        self.assertTrue(by_name["Rampant Growth"]["effect_json"]["land_enters_tapped"])
        self.assertEqual(by_name["Rakdos, the Muscle"]["source"], "curated")
        self.assertEqual(by_name["Rakdos, the Muscle"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Reanimate"]["source"], "curated")
        self.assertEqual(by_name["Reanimate"]["effect_json"]["destination"], "battlefield")
        self.assertEqual(by_name["Ring of the Lucii"]["source"], "curated")
        self.assertEqual(by_name["Ring of the Lucii"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Runaway Steam-Kin"]["source"], "curated")
        self.assertEqual(by_name["Runaway Steam-Kin"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Sami's Curiosity"]["source"], "curated")
        self.assertEqual(by_name["Sami's Curiosity"]["effect_json"]["effect"], "lander_token_maker")
        self.assertEqual(by_name["Sazacap's Brew"]["source"], "curated")
        self.assertTrue(by_name["Sazacap's Brew"]["effect_json"]["requires_discard_card"])
        self.assertEqual(by_name["Shantotto, Tactician Magician"]["source"], "curated")
        self.assertEqual(by_name["Shantotto, Tactician Magician"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Sisay, Weatherlight Captain"]["source"], "curated")
        self.assertTrue(by_name["Sisay, Weatherlight Captain"]["effect_json"]["activated_legendary_tutor"])
        self.assertEqual(by_name["Sisay's Ring"]["source"], "curated")
        self.assertEqual(by_name["Sisay's Ring"]["effect_json"]["mana_produced"], 2)
        self.assertEqual(by_name["Spelltwine"]["source"], "curated")
        self.assertEqual(by_name["Spelltwine"]["effect_json"]["effect"], "copy_spell")
        self.assertTrue(by_name["Spelltwine"]["effect_json"]["copy_own_and_opponent_graveyard_spell"])
        self.assertEqual(by_name["Tellah, Great Sage"]["source"], "curated")
        self.assertEqual(by_name["Tellah, Great Sage"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["The Unagi of Kyoshi Island"]["source"], "curated")
        self.assertEqual(by_name["The Unagi of Kyoshi Island"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Valakut Awakening"]["source"], "curated")
        self.assertEqual(by_name["Valakut Awakening"]["effect_json"]["effect"], "hand_filter")
        self.assertEqual(by_name["Volcanic Vision"]["source"], "curated")
        self.assertEqual(by_name["Volcanic Vision"]["effect_json"]["target"], "instant_or_sorcery")
        self.assertEqual(by_name["Scroll Rack"]["source"], "curated")
        self.assertEqual(by_name["Skullclamp"]["source"], "curated")
        self.assertEqual(by_name["Skullclamp"]["effect_json"]["effect"], "passive")
        self.assertEqual(
            by_name["Sensei's Divining Top"]["effect_json"]["effect"],
            "topdeck_manipulation",
        )
        self.assertEqual(by_name["Splendid Reclamation"]["source"], "curated")
        self.assertEqual(by_name["Splendid Reclamation"]["effect_json"]["effect"], "land_recursion")
        self.assertEqual(by_name["Silence"]["source"], "curated")
        self.assertEqual(by_name["Silence"]["effect_json"]["effect"], "silence_spell")
        self.assertEqual(by_name["Unexpected Windfall"]["source"], "curated")
        self.assertEqual(
            by_name["Unexpected Windfall"]["effect_json"]["effect"],
            "treasure_maker",
        )
        self.assertEqual(by_name["Ur-Golem's Eye"]["source"], "curated")
        self.assertEqual(by_name["Ur-Golem's Eye"]["effect_json"]["mana_produced"], 2)
        self.assertTrue(
            by_name["Unexpected Windfall"]["effect_json"]["requires_discard_card"]
        )
        self.assertEqual(by_name["Vexing Bauble"]["source"], "curated")
        self.assertEqual(
            by_name["Vexing Bauble"]["effect_json"]["effect"],
            "hate_artifact",
        )
        self.assertEqual(by_name["Woodland Bellower"]["source"], "curated")
        self.assertEqual(by_name["Woodland Bellower"]["effect_json"]["effect"], "creature")
        self.assertEqual(by_name["Worldfire"]["source"], "curated")
        self.assertEqual(by_name["Worldfire"]["effect_json"]["effect"], "worldfire_reset")
        self.assertEqual(by_name["Zuran Orb"]["source"], "curated")
        self.assertEqual(
            by_name["Zuran Orb"]["effect_json"]["effect"],
            "life_artifact",
        )

    def test_runtime_prefers_reviewed_curated_rule_after_sync(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in sync_rules.build_rows(
                    include_generated=True,
                    sqlite_db=str(db_path),
                    reviewed_rules_path=DEFAULT_REVIEWED_RULES_PATH,
                ):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                grace = battle.get_card_effect({"name": "Angel's Grace", "type_line": "Instant"})
                star = battle.get_card_effect({"name": "Chromatic Star", "type_line": "Artifact"})
                natural_order = battle.get_card_effect(
                    {"name": "Natural Order", "type_line": "Sorcery"}
                )
                crop_rotation = battle.get_card_effect(
                    {"name": "Crop Rotation", "type_line": "Instant"}
                )
                entomb = battle.get_card_effect(
                    {"name": "Entomb", "type_line": "Instant"}
                )
                empowered_autogenerator = battle.get_card_effect(
                    {"name": "Empowered Autogenerator", "type_line": "Artifact"}
                )
                ether = battle.get_card_effect({"name": "Ether", "type_line": "Artifact"})
                electric_revelation = battle.get_card_effect({"name": "Electric Revelation", "type_line": "Instant"})
                fateful_showdown = battle.get_card_effect({"name": "Fateful Showdown", "type_line": "Instant"})
                rampant_growth = battle.get_card_effect(
                    {"name": "Rampant Growth", "type_line": "Sorcery"}
                )
                reanimate = battle.get_card_effect(
                    {"name": "Reanimate", "type_line": "Sorcery"}
                )
                ashnod = battle.get_card_effect({"name": "Ashnod's Altar", "type_line": "Artifact"})
                incubation = battle.get_card_effect(
                    {"name": "Incubation Druid", "type_line": "Creature — Elf Druid"}
                )
                library_of_leng = battle.get_card_effect(
                    {"name": "Library of Leng", "type_line": "Artifact"}
                )
                lorehold = battle.get_card_effect(
                    {
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    }
                )
                aetherflux_reservoir = battle.get_card_effect(
                    {"name": "Aetherflux Reservoir", "type_line": "Artifact"}
                )
                blind_obedience = battle.get_card_effect(
                    {"name": "Blind Obedience", "type_line": "Enchantment"}
                )
                ancient_tomb = battle.get_card_effect({"name": "Ancient Tomb", "type_line": "Land"})
                fellwar_stone = battle.get_card_effect({"name": "Fellwar Stone", "type_line": "Artifact"})
                lumra = battle.get_card_effect(
                    {
                        "name": "Lumra, Bellow of the Woods",
                        "type_line": "Legendary Creature — Elemental Bear",
                    }
                )
                mana_vault = battle.get_card_effect({"name": "Mana Vault", "type_line": "Artifact"})
                mind_stone = battle.get_card_effect({"name": "Mind Stone", "type_line": "Artifact"})
                dismember = battle.get_card_effect(
                    {"name": "Dismember", "type_line": "Instant", "mana_cost": "{1}{B/P}{B/P}"}
                )
                path_to_exile = battle.get_card_effect(
                    {"name": "Path to Exile", "type_line": "Instant"}
                )
                swords_to_plowshares = battle.get_card_effect(
                    {"name": "Swords to Plowshares", "type_line": "Instant"}
                )
                teferis_protection = battle.get_card_effect(
                    {"name": "Teferi's Protection", "type_line": "Instant"}
                )
                pirates_pillage = battle.get_card_effect({"name": "Pirate's Pillage", "type_line": "Sorcery"})
                prismatic_lens = battle.get_card_effect({"name": "Prismatic Lens", "type_line": "Artifact"})
                decaying_time_loop = battle.get_card_effect({"name": "Decaying Time Loop", "type_line": "Instant"})
                izzet_signet = battle.get_card_effect({"name": "Izzet Signet", "type_line": "Artifact"})
                kraum = battle.get_card_effect({"name": "Kraum, Ludevic's Opus", "type_line": "Legendary Creature — Zombie Horror"})
                rakdos = battle.get_card_effect({"name": "Rakdos, the Muscle", "type_line": "Legendary Creature — Demon Mercenary"})
                ring = battle.get_card_effect({"name": "Ring of the Lucii", "type_line": "Legendary Artifact"})
                sazacaps_brew = battle.get_card_effect({"name": "Sazacap's Brew", "type_line": "Instant"})
                scroll_rack = battle.get_card_effect({"name": "Scroll Rack", "type_line": "Artifact"})
                seething_song = battle.get_card_effect({"name": "Seething Song", "type_line": "Instant"})
                shantotto = battle.get_card_effect({"name": "Shantotto, Tactician Magician", "type_line": "Legendary Creature — Dwarf Wizard"})
                sisay = battle.get_card_effect({"name": "Sisay, Weatherlight Captain", "type_line": "Legendary Creature — Human Soldier"})
                sisays_ring = battle.get_card_effect({"name": "Sisay's Ring", "type_line": "Artifact"})
                skullclamp = battle.get_card_effect({"name": "Skullclamp", "type_line": "Artifact — Equipment"})
                talisman = battle.get_card_effect(
                    {"name": "Talisman of Conviction", "type_line": "Artifact"}
                )
                ur_golems_eye = battle.get_card_effect({"name": "Ur-Golem's Eye", "type_line": "Artifact"})
                top = battle.get_card_effect({"name": "Sensei's Divining Top", "type_line": "Artifact"})
                mystical_tutor = battle.get_card_effect({"name": "Mystical Tutor", "type_line": "Instant"})
                volcanic_vision = battle.get_card_effect({"name": "Volcanic Vision", "type_line": "Sorcery"})
                wall_of_omens = battle.get_card_effect(
                    {"name": "Wall of Omens", "type_line": "Creature — Wall"}
                )
                wayfarers_bauble = battle.get_card_effect(
                    {"name": "Wayfarer's Bauble", "type_line": "Artifact"}
                )
                woodland_bellower = battle.get_card_effect({"name": "Woodland Bellower", "type_line": "Creature — Beast"})
                worldfire = battle.get_card_effect({"name": "Worldfire", "type_line": "Sorcery"})
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(grace["_rule_source"], "curated")
        self.assertEqual(grace["_rule_review_status"], "verified")
        self.assertEqual(grace["effect"], "cannot_lose_turn")
        self.assertEqual(star["_rule_source"], "curated")
        self.assertEqual(star["_rule_review_status"], "active")
        self.assertEqual(star["effect"], "cantrip_mana_filter_artifact")
        self.assertEqual(star["battle_model_scope"], "sacrifice_mana_filter_cantrip_v2")
        self.assertEqual(ashnod["_rule_source"], "curated")
        self.assertEqual(ashnod["_rule_review_status"], "active")
        self.assertEqual(ashnod["effect"], "passive")
        self.assertTrue(ashnod["activated_mana_ability"])
        self.assertEqual(ashnod["activation_cost"], "sacrifice_creature")
        self.assertEqual(ashnod["mana_produced"], 2)
        self.assertEqual(incubation["_rule_source"], "curated")
        self.assertEqual(incubation["_rule_review_status"], "active")
        self.assertEqual(incubation["effect"], "creature")
        self.assertTrue(incubation["is_mana_source"])
        self.assertEqual(incubation["mana_produced"], 1)
        self.assertEqual(library_of_leng["_rule_source"], "curated")
        self.assertTrue(library_of_leng["no_max_hand_size"])
        self.assertTrue(library_of_leng["discard_effect_to_top_replacement"])
        self.assertEqual(lorehold["_rule_source"], "curated")
        self.assertEqual(lorehold["effect"], "passive")
        self.assertEqual(lorehold["grants_miracle_cost"], 2)
        self.assertTrue(lorehold["opponent_upkeep_rummage"])
        self.assertEqual(ancient_tomb["_rule_source"], "curated")
        self.assertEqual(ancient_tomb["_rule_review_status"], "verified")
        self.assertEqual(ancient_tomb["effect"], "land")
        self.assertEqual(ancient_tomb["mana_produced"], 1)
        self.assertEqual(ancient_tomb["ancient_tomb_bonus_mana"], 1)
        self.assertEqual(ancient_tomb["ancient_tomb_bonus_life_cost"], 2)
        self.assertEqual(aetherflux_reservoir["_rule_source"], "curated")
        self.assertEqual(aetherflux_reservoir["_rule_review_status"], "active")
        self.assertEqual(
            aetherflux_reservoir["_rule_logical_key"],
            "battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5",
        )
        self.assertEqual(
            aetherflux_reservoir["_rule_oracle_hash"],
            "ea5327899fb66a2d583e80e8ca12d9b2",
        )
        self.assertEqual(aetherflux_reservoir["effect"], "aetherflux_reservoir")
        self.assertTrue(aetherflux_reservoir["spell_cast_lifegain"])
        self.assertEqual(
            aetherflux_reservoir["activation_execution_status"],
            "annotation_only",
        )
        self.assertEqual(
            aetherflux_reservoir["battle_model_scope"],
            "spell_cast_lifegain_pay_50_damage_annotation_v1",
        )
        self.assertEqual(blind_obedience["_rule_source"], "curated")
        self.assertEqual(blind_obedience["_rule_review_status"], "active")
        self.assertEqual(blind_obedience["_rule_execution_status"], "auto")
        self.assertEqual(
            blind_obedience["_rule_oracle_hash"],
            "4e62bff316f784c1b468b9e53146d2aa",
        )
        self.assertEqual(blind_obedience["effect"], "passive")
        self.assertTrue(blind_obedience["opponents_artifacts_creatures_enter_tapped"])
        self.assertEqual(
            blind_obedience["extort_execution_status"],
            "annotation_only",
        )
        self.assertEqual(
            blind_obedience["battle_model_scope"],
            "opponent_artifact_creature_enter_tapped_extort_annotation_v1",
        )
        self.assertEqual(fellwar_stone["_rule_source"], "curated")
        self.assertEqual(fellwar_stone["_rule_review_status"], "active")
        self.assertEqual(fellwar_stone["effect"], "ramp_permanent")
        self.assertEqual(fellwar_stone["mana_produced"], 1)
        self.assertTrue(fellwar_stone["conditionally_produces_opponent_land_colors"])
        self.assertEqual(lumra["_rule_source"], "curated")
        self.assertEqual(lumra["_rule_review_status"], "verified")
        self.assertEqual(lumra["effect"], "land_recursion_creature")
        self.assertEqual(lumra["mill_count"], 4)
        self.assertEqual(mana_vault["_rule_source"], "curated")
        self.assertEqual(mana_vault["_rule_review_status"], "active")
        self.assertEqual(mana_vault["effect"], "ramp_permanent")
        self.assertEqual(mana_vault["mana_produced"], 3)
        self.assertTrue(mana_vault["does_not_untap_normally"])
        self.assertEqual(mana_vault["upkeep_optional_untap_cost_generic"], 4)
        self.assertEqual(mana_vault["tapped_upkeep_damage"], 1)
        self.assertEqual(mind_stone["_rule_source"], "curated")
        self.assertEqual(mind_stone["effect"], "ramp_permanent")
        self.assertEqual(mind_stone["mana_produced"], 1)
        self.assertTrue(mind_stone["activated_self_sacrifice_draw"])
        self.assertEqual(natural_order["_rule_source"], "curated")
        self.assertEqual(natural_order["_rule_review_status"], "verified")
        self.assertEqual(natural_order["effect"], "tutor")
        self.assertEqual(natural_order["target"], "green_creature_to_battlefield")
        self.assertTrue(natural_order["requires_sacrifice_green_creature"])
        self.assertEqual(crop_rotation["_rule_source"], "curated")
        self.assertEqual(crop_rotation["effect"], "land_ramp")
        self.assertTrue(crop_rotation["requires_sacrifice_land"])
        self.assertFalse(crop_rotation["land_enters_tapped"])
        self.assertEqual(entomb["_rule_source"], "curated")
        self.assertEqual(entomb["effect"], "tutor")
        self.assertEqual(entomb["target"], "graveyard")
        self.assertEqual(empowered_autogenerator["_rule_source"], "curated")
        self.assertEqual(empowered_autogenerator["effect"], "ramp_permanent")
        self.assertTrue(empowered_autogenerator["enters_tapped"])
        self.assertEqual(ether["_rule_source"], "curated")
        self.assertEqual(ether["effect"], "passive")
        self.assertTrue(ether["activated_exile_self_for_mana"])
        self.assertEqual(electric_revelation["_rule_source"], "curated")
        self.assertEqual(electric_revelation["effect"], "draw_cards")
        self.assertTrue(electric_revelation["requires_discard_card"])
        self.assertEqual(fateful_showdown["_rule_source"], "curated")
        self.assertTrue(fateful_showdown["draw_equal_to_discarded_hand"])
        self.assertEqual(rampant_growth["_rule_source"], "curated")
        self.assertEqual(rampant_growth["effect"], "land_ramp")
        self.assertTrue(rampant_growth["basic_only"])
        self.assertTrue(rampant_growth["land_enters_tapped"])
        self.assertEqual(reanimate["_rule_source"], "curated")
        self.assertEqual(reanimate["effect"], "recursion")
        self.assertEqual(reanimate["destination"], "battlefield")
        self.assertEqual(dismember["_rule_source"], "curated")
        self.assertEqual(dismember["_rule_review_status"], "verified")
        self.assertEqual(dismember["effect"], "remove_creature")
        self.assertEqual(dismember["toughness_boost"], -5)
        self.assertTrue(dismember["uses_stat_modifier_removal"])
        self.assertEqual(decaying_time_loop["_rule_source"], "curated")
        self.assertEqual(decaying_time_loop["effect"], "draw_cards")
        self.assertTrue(decaying_time_loop["draw_equal_to_discarded_hand"])
        self.assertEqual(izzet_signet["_rule_source"], "curated")
        self.assertEqual(izzet_signet["effect"], "ramp_permanent")
        self.assertEqual(izzet_signet["produces"], "UR")
        self.assertEqual(kraum["_rule_source"], "curated")
        self.assertEqual(kraum["effect"], "draw_engine")
        self.assertTrue(kraum["opponent_second_spell_each_turn"])
        self.assertFalse(kraum["draw_on_enter"])
        self.assertEqual(path_to_exile["_rule_source"], "curated")
        self.assertEqual(path_to_exile["_rule_review_status"], "active")
        self.assertEqual(path_to_exile["effect"], "remove_creature")
        self.assertEqual(path_to_exile["target"], "creature")
        self.assertTrue(path_to_exile["exile_target"])
        self.assertTrue(path_to_exile["target_controller_basic_land_tapped"])
        self.assertEqual(swords_to_plowshares["_rule_source"], "curated")
        self.assertEqual(swords_to_plowshares["_rule_review_status"], "active")
        self.assertEqual(swords_to_plowshares["effect"], "remove_creature")
        self.assertEqual(swords_to_plowshares["target"], "creature")
        self.assertEqual(swords_to_plowshares["destination"], "exile")
        self.assertTrue(swords_to_plowshares["exile_target"])
        self.assertTrue(
            swords_to_plowshares["target_controller_life_gain_equal_target_power"]
        )
        self.assertEqual(
            swords_to_plowshares["life_gain_status"],
            "dynamic_target_power_executor",
        )
        self.assertEqual(teferis_protection["_rule_source"], "curated")
        self.assertEqual(teferis_protection["_rule_review_status"], "active")
        self.assertEqual(
            teferis_protection["_rule_logical_key"],
            "battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a",
        )
        self.assertEqual(
            teferis_protection["_rule_oracle_hash"],
            "bdc0faecf4420dc6162c7e72e98cc0eb",
        )
        self.assertEqual(teferis_protection["effect"], "phase_out")
        self.assertTrue(teferis_protection["life_total_cant_change"])
        self.assertTrue(teferis_protection["protection_from_everything"])
        self.assertTrue(teferis_protection["phase_out_all_permanents_you_control"])
        self.assertTrue(teferis_protection["phase_out_includes_lands"])
        self.assertTrue(teferis_protection["exiles_self"])
        self.assertEqual(pirates_pillage["_rule_source"], "curated")
        self.assertEqual(pirates_pillage["effect"], "treasure_maker")
        self.assertEqual(pirates_pillage["treasure_count"], 2)
        self.assertEqual(prismatic_lens["_rule_source"], "curated")
        self.assertEqual(prismatic_lens["effect"], "ramp_permanent")
        self.assertEqual(prismatic_lens["mana_produced"], 1)
        self.assertEqual(scroll_rack["_rule_source"], "curated")
        self.assertEqual(scroll_rack["effect"], "topdeck_manipulation")
        self.assertTrue(scroll_rack["hand_to_top_exchange"])
        self.assertEqual(
            scroll_rack["battle_model_scope"],
            "scroll_rack_upkeep_single_exchange_v1",
        )
        self.assertEqual(seething_song["_rule_source"], "curated")
        self.assertEqual(seething_song["_rule_review_status"], "verified")
        self.assertEqual(seething_song["effect"], "ramp_ritual")
        self.assertEqual(seething_song["mana_produced"], 5)
        self.assertTrue(seething_song["instant"])
        self.assertEqual(rakdos["_rule_source"], "curated")
        self.assertEqual(rakdos["effect"], "creature")
        self.assertTrue(rakdos["sacrifice_creature_grants_indestructible"])
        self.assertEqual(ring["_rule_source"], "curated")
        self.assertEqual(ring["effect"], "ramp_permanent")
        self.assertEqual(ring["mana_produced"], 2)
        self.assertEqual(sazacaps_brew["_rule_source"], "curated")
        self.assertEqual(sazacaps_brew["effect"], "draw_cards")
        self.assertTrue(sazacaps_brew["requires_discard_card"])
        self.assertEqual(shantotto["_rule_source"], "curated")
        self.assertEqual(shantotto["effect"], "creature")
        self.assertEqual(shantotto["spell_cast_draw_if_cmc_at_least"], 4)
        self.assertEqual(sisay["_rule_source"], "curated")
        self.assertEqual(sisay["effect"], "creature")
        self.assertTrue(sisay["activated_legendary_tutor"])
        self.assertEqual(sisays_ring["_rule_source"], "curated")
        self.assertEqual(sisays_ring["_rule_review_status"], "verified")
        self.assertEqual(sisays_ring["mana_produced"], 2)
        self.assertEqual(skullclamp["_rule_source"], "curated")
        self.assertEqual(skullclamp["effect"], "passive")
        self.assertEqual(skullclamp["draw_on_equipped_death"], 2)
        self.assertEqual(talisman["_rule_source"], "curated")
        self.assertEqual(talisman["_rule_review_status"], "active")
        self.assertEqual(talisman["effect"], "ramp_permanent")
        self.assertEqual(talisman["mana_produced"], 1)
        self.assertEqual(talisman["produces"], "CRW")
        self.assertEqual(talisman["life_for_colored_mana"], 1)
        self.assertEqual(ur_golems_eye["_rule_source"], "curated")
        self.assertEqual(ur_golems_eye["_rule_review_status"], "verified")
        self.assertEqual(ur_golems_eye["mana_produced"], 2)
        self.assertEqual(top["_rule_source"], "curated")
        self.assertEqual(top["effect"], "topdeck_manipulation")
        self.assertEqual(top["peek_top_count"], 3)
        self.assertTrue(top["reorder_top"])
        self.assertEqual(mystical_tutor["_rule_source"], "curated")
        self.assertEqual(mystical_tutor["effect"], "tutor")
        self.assertEqual(mystical_tutor["target"], "instant_or_sorcery")
        self.assertEqual(volcanic_vision["_rule_source"], "curated")
        self.assertEqual(volcanic_vision["effect"], "recursion")
        self.assertEqual(volcanic_vision["target"], "instant_or_sorcery")
        self.assertEqual(wall_of_omens["_rule_source"], "curated")
        self.assertEqual(wall_of_omens["effect"], "creature")
        self.assertEqual(wall_of_omens["etb_draw_count"], 1)
        self.assertEqual(wayfarers_bauble["_rule_source"], "curated")
        self.assertEqual(wayfarers_bauble["effect"], "ramp_permanent")
        self.assertTrue(wayfarers_bauble["activated_self_sacrifice_land_tutor"])
        self.assertTrue(wayfarers_bauble["basic_only"])
        self.assertEqual(woodland_bellower["_rule_source"], "curated")
        self.assertEqual(woodland_bellower["_rule_review_status"], "verified")
        self.assertEqual(woodland_bellower["effect"], "creature")
        self.assertEqual(woodland_bellower["etb_tutor_nonlegendary_green_creature_mv_lte"], 3)
        self.assertEqual(worldfire["_rule_source"], "curated")
        self.assertEqual(worldfire["_rule_review_status"], "verified")
        self.assertEqual(worldfire["effect"], "worldfire_reset")
        self.assertEqual(worldfire["battle_model_scope"], "worldfire_total_reset_v1")

    def test_kraum_draws_only_on_second_opponent_spell(self) -> None:
        old_db = battle.DB
        old_turn = battle.CURRENT_REPLAY_TURN
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.CURRENT_REPLAY_TURN = 7
                battle.battle_rule_registry._RULE_CACHE.clear()
                kraum = battle.get_card_effect(
                    {
                        "name": "Kraum, Ludevic's Opus",
                        "type_line": "Legendary Creature — Zombie Horror",
                    }
                )
                controller = battle.Player("Kraum Player", None, [])
                controller.library = [
                    {"name": "Draw A", "type_line": "Instant"},
                    {"name": "Draw B", "type_line": "Instant"},
                ]
                controller.battlefield = [
                    {
                        **kraum,
                        "name": "Kraum, Ludevic's Opus",
                        "type_line": "Legendary Creature — Zombie Horror",
                    }
                ]
                caster = battle.Player("Caster", None, [])
                spell = {"name": "Ponder", "type_line": "Sorcery", "cmc": 1}

                caster.record_spell_cast(7)
                battle.trigger_opponent_spell_draw_engines(
                    caster,
                    [controller],
                    spell,
                    7,
                    "precombat_main",
                    __import__("random").Random(1),
                )
                self.assertEqual(len(controller.hand), 0)

                caster.record_spell_cast(7)
                battle.trigger_opponent_spell_draw_engines(
                    caster,
                    [controller],
                    spell,
                    7,
                    "precombat_main",
                    __import__("random").Random(1),
                )
                self.assertEqual([card["name"] for card in controller.hand], ["Draw A"])
            finally:
                battle.DB = old_db
                battle.CURRENT_REPLAY_TURN = old_turn
                battle.battle_rule_registry._RULE_CACHE.clear()

    def test_shantotto_draws_on_large_noncreature_spell(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                shantotto = battle.get_card_effect(
                    {
                        "name": "Shantotto, Tactician Magician",
                        "type_line": "Legendary Creature — Dwarf Wizard",
                    }
                )
                controller = battle.Player("Shantotto Player", None, [])
                controller.library = [{"name": "Triggered Draw", "type_line": "Instant"}]
                controller.battlefield = [
                    {
                        **shantotto,
                        "name": "Shantotto, Tactician Magician",
                        "type_line": "Legendary Creature — Dwarf Wizard",
                    }
                ]
                battle.trigger_spell_cast_engines(
                    controller,
                    [controller],
                    {"name": "Fact or Fiction", "type_line": "Instant", "cmc": 4},
                    3,
                    "precombat_main",
                )
                self.assertEqual([card["name"] for card in controller.hand], ["Triggered Draw"])
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

    def test_thor_noncreature_spell_trigger_deals_spell_mana_value_damage(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()
                player = battle.Player("Thor Player", None, [])
                opponent = battle.Player("Opponent", None, [])
                opponent.life = 4
                thor = {
                    "name": "Thor, God of Thunder",
                    "type_line": "Legendary Creature — God Warrior Hero",
                    "cmc": 5,
                }
                thor_effect = battle.get_card_effect(thor)
                self.assertEqual(
                    thor_effect["_rule_logical_key"],
                    "battle_rule_v1:280e17ec34ac105baeb6989491c6ff25",
                )
                battle.apply_effect_immediate(
                    player,
                    [opponent],
                    thor,
                    turn=3,
                    rng=__import__("random").Random(17),
                    effect_data_override=thor_effect,
                )
                self.assertTrue(
                    any(
                        card.get("name") == "Thor, God of Thunder"
                        and card.get("trigger") == "noncreature_spell_cast"
                        for card in player.battlefield
                    )
                )
                battle.trigger_spell_cast_engines(
                    player,
                    [player, opponent],
                    {"name": "Big Score", "type_line": "Instant", "cmc": 4},
                    turn=3,
                    phase="precombat_main",
                    active_player=player,
                )
                battle.trigger_spell_cast_engines(
                    player,
                    [player, opponent],
                    {"name": "Creature Followup", "type_line": "Creature", "cmc": 4},
                    turn=3,
                    phase="precombat_main",
                    active_player=player,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()

        thor_triggers = [
            data
            for event, data in events
            if event == "trigger_resolved"
            and data.get("card") == "Thor, God of Thunder"
            and data.get("effect") == "damage_any_target"
        ]
        self.assertEqual(len(thor_triggers), 1)
        self.assertEqual(thor_triggers[0]["amount"], 4)
        self.assertEqual(thor_triggers[0]["target_player"], "Opponent")
        self.assertEqual(thor_triggers[0]["result"], "player_damage")
        self.assertEqual(opponent.life, 0)

    def test_decaying_time_loop_discards_own_hand_and_draws_same_count(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                player.hand = [
                    {"name": "Old A", "type_line": "Instant"},
                    {"name": "Old B", "type_line": "Sorcery"},
                ]
                player.library = [
                    {"name": "New A", "type_line": "Instant"},
                    {"name": "New B", "type_line": "Sorcery"},
                    {"name": "New C", "type_line": "Creature"},
                ]
                card = {"name": "Decaying Time Loop", "type_line": "Instant", "cmc": 4}
                effect = battle.get_card_effect(card)
                battle.apply_effect_immediate(
                    player,
                    [],
                    card,
                    4,
                    __import__("random").Random(1),
                    effect_data_override=effect,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        resolved = [
            data
            for event, data in events
            if event == "draw_equal_to_discarded_hand_resolved"
        ]
        self.assertEqual(len(resolved), 1)
        self.assertEqual(resolved[0]["discarded"], 2)
        self.assertEqual(resolved[0]["cards_drawn"], 2)
        self.assertEqual([card["name"] for card in player.hand], ["New A", "New B"])

    def test_wheel_of_fortune_uses_oracle_hashed_multiplayer_wheel_rule(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                opponent = battle.Player("Opponent", None, [])
                player.hand = [
                    {"name": "Old A", "type_line": "Instant"},
                    {"name": "Old B", "type_line": "Sorcery"},
                ]
                opponent.hand = [
                    {"name": "Opp Old", "type_line": "Creature"},
                ]
                player.library = [
                    {"name": f"New {index}", "type_line": "Instant"}
                    for index in range(8)
                ]
                opponent.library = [
                    {"name": f"Opp New {index}", "type_line": "Creature"}
                    for index in range(8)
                ]
                card = {"name": "Wheel of Fortune", "type_line": "Sorcery", "cmc": 3}
                effect = battle.get_card_effect(card)
                self.assertEqual(
                    effect["_rule_logical_key"],
                    "battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3",
                )
                self.assertEqual(effect["_rule_oracle_hash"], "c37cd579d8132efac0c2118608f6f001")
                battle.apply_effect_immediate(
                    player,
                    [opponent],
                    card,
                    4,
                    __import__("random").Random(1),
                    effect_data_override=effect,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        resolved = [
            data
            for event, data in events
            if event == "wheel_resolved"
        ]
        self.assertEqual(len(resolved), 1)
        self.assertEqual(resolved[0]["draw_count"], 7)
        self.assertEqual(resolved[0]["opponent_cards_drawn"], 7)
        self.assertEqual(
            resolved[0]["rule_logical_key"],
            "battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3",
        )
        self.assertEqual(resolved[0]["rule_oracle_hash"], "c37cd579d8132efac0c2118608f6f001")
        participants = {entry["player"]: entry for entry in resolved[0]["participants"]}
        self.assertEqual(participants["Caster"]["discarded"], 2)
        self.assertEqual(participants["Caster"]["drawn"], 7)
        self.assertEqual(participants["Opponent"]["discarded"], 1)
        self.assertEqual(participants["Opponent"]["drawn"], 7)

    def test_approach_of_the_second_sun_counts_countered_first_cast_and_second_cast_wins(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        old_turn = battle.CURRENT_REPLAY_TURN
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.CURRENT_REPLAY_TURN = 4
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                card = {"name": "Approach of the Second Sun", "type_line": "Sorcery", "cmc": 7}
                first_effect = battle.get_card_effect(card)
                self.assertEqual(
                    first_effect["_rule_logical_key"],
                    "battle_rule_v1:ed74fb069b6c1d635392d907804a1d98",
                )
                self.assertEqual(
                    first_effect["_rule_oracle_hash"],
                    "0838960b80a282fb4508532f7bae8c2b",
                )
                player.mana_pool.add("white", 1)
                player.mana_pool.add_generic(6)
                first_context = battle.begin_cast_context(
                    player,
                    card,
                    "precombat_main",
                    effect_data=first_effect,
                    role="test_first_countered",
                )
                self.assertTrue(battle.commit_cast_payment(first_context))
                stack = battle.Stack()
                stack.push(card, player, first_effect)
                stack.items[-1].countered = True
                self.assertIsNone(stack.resolve_top())
                self.assertEqual(player.approach_count, 1)
                self.assertEqual(player.life, 40)

                second_card = {"name": "Approach of the Second Sun", "type_line": "Sorcery", "cmc": 7}
                second_effect = battle.get_card_effect(second_card)
                player.mana_pool.add("white", 1)
                player.mana_pool.add_generic(6)
                second_context = battle.begin_cast_context(
                    player,
                    second_card,
                    "precombat_main",
                    effect_data=second_effect,
                    role="test_second_win",
                )
                self.assertTrue(battle.commit_cast_payment(second_context))
                battle.apply_effect_immediate(
                    player,
                    [],
                    second_card,
                    4,
                    __import__("random").Random(46),
                    effect_data_override=second_effect,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.CURRENT_REPLAY_TURN = old_turn
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(player.approach_count, 2)
        self.assertTrue(player.has_won())
        self.assertEqual(player.win_reason, "approach")
        self.assertEqual(player.life, 40)
        self.assertEqual(
            [
                data.get("approach_count")
                for event, data in events
                if event == "approach_cast_tracked"
                and data.get("card") == "Approach of the Second Sun"
            ],
            [1, 2],
        )
        self.assertFalse(
            [
                data
                for event, data in events
                if event == "approach_first_resolution"
                and data.get("approach_count") == 2
            ]
        )
        second_resolution = [
            data
            for event, data in events
            if event == "spell_resolved"
            and data.get("card") == "Approach of the Second Sun"
        ]
        self.assertEqual(len(second_resolution), 1)
        self.assertEqual(second_resolution[0]["destination"], "graveyard")
        self.assertTrue(
            any(
                event == "game_won"
                and data.get("reason") == "approach"
                for event, data in events
            )
        )

    def test_aetherflux_reservoir_uses_oracle_hashed_spell_cast_lifegain_rule(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                card = {"name": "Aetherflux Reservoir", "type_line": "Artifact", "cmc": 4}
                effect = battle.get_card_effect(card)
                self.assertEqual(
                    effect["_rule_logical_key"],
                    "battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5",
                )
                self.assertEqual(
                    effect["_rule_oracle_hash"],
                    "ea5327899fb66a2d583e80e8ca12d9b2",
                )
                battle.apply_effect_immediate(
                    player,
                    [],
                    card,
                    4,
                    __import__("random").Random(113),
                    effect_data_override=effect,
                )
                player.record_spell_cast(turn_marker=4)
                battle.trigger_spell_cast_engines(
                    player,
                    [player],
                    {"name": "Lightning Bolt", "cmc": 1, "type_line": "Instant"},
                    turn=4,
                    phase="precombat_main",
                )
                player.record_spell_cast(turn_marker=4)
                battle.trigger_spell_cast_engines(
                    player,
                    [player],
                    {"name": "Faithless Looting", "cmc": 1, "type_line": "Sorcery"},
                    turn=4,
                    phase="precombat_main",
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        resolved = [
            data
            for event, data in events
            if event == "aetherflux_reservoir_resolved"
        ]
        lifegain = [
            data
            for event, data in events
            if event == "trigger_resolved" and data.get("card") == "Aetherflux Reservoir"
        ]
        self.assertEqual(len(resolved), 1)
        self.assertEqual(
            resolved[0]["rule_logical_key"],
            "battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5",
        )
        self.assertEqual(resolved[0]["rule_oracle_hash"], "ea5327899fb66a2d583e80e8ca12d9b2")
        self.assertEqual([data["life_gained"] for data in lifegain], [1, 2])
        self.assertEqual(
            {data["rule_logical_key"] for data in lifegain},
            {"battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5"},
        )
        self.assertEqual(
            {data["rule_oracle_hash"] for data in lifegain},
            {"ea5327899fb66a2d583e80e8ca12d9b2"},
        )
        self.assertFalse(
            [
                data
                for event, data in events
                if event == "damage_resolved" and data.get("card") == "Aetherflux Reservoir"
            ]
        )

    def test_woodland_bellower_etb_tutors_nonlegendary_green_creature_to_battlefield(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                player.library = [
                    {
                        "name": "Legendary Green",
                        "type_line": "Legendary Creature — Elf",
                        "colors": ["G"],
                        "cmc": 2,
                        "power": 2,
                        "toughness": 2,
                    },
                    {
                        "name": "Elvish Mystic",
                        "type_line": "Creature — Elf Druid",
                        "colors": ["G"],
                        "cmc": 1,
                        "power": 1,
                        "toughness": 1,
                    },
                    {
                        "name": "Blue Creature",
                        "type_line": "Creature — Merfolk",
                        "colors": ["U"],
                        "cmc": 1,
                        "power": 1,
                        "toughness": 1,
                    },
                ]
                card = {
                    "name": "Woodland Bellower",
                    "type_line": "Creature — Beast",
                    "cmc": 6,
                    "power": 6,
                    "toughness": 5,
                }
                effect = battle.get_card_effect(card)
                battle.apply_effect_immediate(
                    player,
                    [],
                    card,
                    6,
                    __import__("random").Random(1),
                    effect_data_override=effect,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertIn("Elvish Mystic", [card.get("name") for card in player.battlefield])
        resolved = [data for event, data in events if event == "etb_tutor_resolved"]
        self.assertEqual(len(resolved), 1)
        self.assertEqual(resolved[0]["found"], "Elvish Mystic")

    def test_volcanic_vision_recovers_spell_and_exiles_itself(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            self._seed_reviewed_rules_db(db_path)
            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Caster", None, [])
                recovered = {"name": "Lightning Bolt", "type_line": "Instant", "cmc": 1}
                card = {"name": "Volcanic Vision", "type_line": "Sorcery", "cmc": 7}
                player.graveyard = [recovered, card]
                effect = battle.get_card_effect(card)
                battle.apply_effect_immediate(
                    player,
                    [],
                    card,
                    6,
                    __import__("random").Random(1),
                    effect_data_override=effect,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertIn(recovered, player.hand)
        self.assertIn(card, player.exile)
        resolved = [data for event, data in events if event == "recursion_resolved"]
        self.assertEqual(len(resolved), 1)
        self.assertEqual(resolved[0]["recovered"], ["Lightning Bolt"])
        spell_resolved = [data for event, data in events if event == "spell_resolved"]
        self.assertEqual(spell_resolved[0]["destination"], "exile")

    def test_draw_counter_resets_on_global_turn_change(self) -> None:
        player = battle.Player("Tester", None, [])
        player.library = [
            {"name": "Card A", "type_line": "Sorcery"},
            {"name": "Card B", "type_line": "Sorcery"},
            {"name": "Card C", "type_line": "Sorcery"},
        ]
        old_turn = battle.CURRENT_REPLAY_TURN
        try:
            battle.CURRENT_REPLAY_TURN = 1
            player.draw(1)
            player.draw(1)
            self.assertEqual(player.cards_drawn_this_turn, 2)
            battle.CURRENT_REPLAY_TURN = 2
            player.draw(1)
            self.assertEqual(player.cards_drawn_this_turn, 1)
        finally:
            battle.CURRENT_REPLAY_TURN = old_turn

    def test_lorehold_upkeep_rummage_uses_library_replacement_and_casts_miracle(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        old_trace_handler = battle.DECISION_TRACE_HANDLER
        events = []
        decisions = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.DECISION_TRACE_HANDLER = lambda data: decisions.append(data)
                battle.battle_rule_registry._RULE_CACHE.clear()

                controller = battle.Player("Lorehold", None, [], is_human=True, strategy="spellslinger")
                lorehold = battle.get_card_effect(
                    {
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    }
                )
                library = battle.get_card_effect({"name": "Library of Leng", "type_line": "Artifact"})
                controller.battlefield = [
                    {"name": "Plains", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {"name": "Mountain", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {**lorehold, "name": "Lorehold, the Historian", "type_line": "Legendary Creature — Elder Dragon"},
                    {**library, "name": "Library of Leng", "type_line": "Artifact"},
                ]
                controller.hand = [
                    {"name": "Comet Storm", "type_line": "Instant", "cmc": 3, "mana_cost": "{X}{R}{R}"},
                ]
                controller.library = [
                    {"name": "Mountain", "type_line": "Land", "cmc": 0},
                ]
                controller.refresh_mana_sources(turn=1)

                active = battle.Player("Opponent", None, [])
                stack = battle.Stack()
                battle.process_lorehold_opponent_upkeep_rummage(
                    active,
                    [controller, active],
                    turn=1,
                    rng=__import__("random").Random(7),
                    stack=stack,
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.DECISION_TRACE_HANDLER = old_trace_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        rummage_events = [data for event, data in events if event == "lorehold_upkeep_rummage"]
        miracle_events = [data for event, data in events if event == "miracle_cast"]
        self.assertEqual(len(decisions), 1)
        self.assertEqual(len(rummage_events), 1)
        self.assertEqual(rummage_events[0]["discarded"], "Comet Storm")
        self.assertEqual(rummage_events[0]["discard_destination"], "top_of_library")
        self.assertTrue(rummage_events[0]["replacement_used"])
        self.assertEqual(rummage_events[0]["drawn"], "Comet Storm")
        self.assertEqual(len(miracle_events), 1)
        self.assertEqual(miracle_events[0]["card"], "Comet Storm")
        self.assertEqual(miracle_events[0]["source"], "lorehold_opponent_upkeep_rummage")
        self.assertEqual(decisions[0]["decision_type"], "lorehold_upkeep_rummage")
        self.assertEqual(len(decisions[0]["available_options"]), 1)

    def test_lorehold_topdeck_support_reorders_for_first_draw(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()

                player = battle.Player("Lorehold", None, [], is_human=True, strategy="spellslinger")
                lorehold = battle.get_card_effect(
                    {
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    }
                )
                top = battle.get_card_effect({"name": "Sensei's Divining Top", "type_line": "Artifact"})
                player.battlefield = [
                    {"name": "Plains", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {"name": "Mountain", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {**lorehold, "name": "Lorehold, the Historian", "type_line": "Legendary Creature — Elder Dragon"},
                    {**top, "name": "Sensei's Divining Top", "type_line": "Artifact"},
                ]
                player.library = [
                    {"name": "Mountain", "type_line": "Land", "cmc": 0},
                    {"name": "Rune-Scarred Demon", "type_line": "Creature", "cmc": 7},
                    {"name": "Boros Charm", "type_line": "Instant", "cmc": 2, "mana_cost": "{R}{W}"},
                ]
                player.refresh_mana_sources(turn=1)

                activated = battle.activate_lorehold_topdeck_artifacts(
                    player,
                    turn=1,
                    rng=__import__("random").Random(11),
                    phase="opponent_upkeep",
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertEqual(player.library[0]["name"], "Boros Charm")
        top_events = [data for event, data in events if event == "topdeck_manipulation_activated"]
        self.assertEqual(len(top_events), 1)
        self.assertEqual(top_events[0]["top_before"], "Mountain")
        self.assertEqual(top_events[0]["top_after"], "Boros Charm")

    def test_lorehold_top_draw_mode_consumes_top_for_immediate_miracle(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()

                player = battle.Player("Lorehold", None, [], is_human=True, strategy="spellslinger")
                opponent = battle.Player("Opponent", None, [], strategy="midrange")
                lorehold = battle.get_card_effect(
                    {
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    }
                )
                top = battle.get_card_effect({"name": "Sensei's Divining Top", "type_line": "Artifact"})
                player.battlefield = [
                    {"name": "Plains", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {"name": "Mountain", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {
                        **lorehold,
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    },
                    {**top, "name": "Sensei's Divining Top", "type_line": "Artifact"},
                ]
                player.library = [
                    {"name": "Boros Charm", "type_line": "Instant", "cmc": 2, "mana_cost": "{R}{W}"},
                    {"name": "Mountain", "type_line": "Land", "cmc": 0},
                    {"name": "Rune-Scarred Demon", "type_line": "Creature", "cmc": 7},
                ]
                player.refresh_mana_sources(turn=1)

                activated = battle.activate_lorehold_topdeck_artifacts(
                    player,
                    turn=1,
                    rng=__import__("random").Random(12),
                    phase="opponent_upkeep",
                    all_players=[player, opponent],
                    stack=battle.Stack(),
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertFalse(
            any(
                isinstance(permanent, dict)
                and permanent.get("name") == "Sensei's Divining Top"
                for permanent in player.battlefield
            )
        )
        self.assertEqual(player.library[0]["name"], "Sensei's Divining Top")
        self.assertTrue(any(card.get("name") == "Boros Charm" for card in player.graveyard))
        top_events = [data for event, data in events if event == "topdeck_manipulation_activated"]
        self.assertEqual(len(top_events), 1)
        self.assertEqual(top_events[0]["activation_kind"], "draw_put_self_on_top_for_miracle")
        self.assertEqual(top_events[0]["drawn"], "Boros Charm")
        self.assertTrue(
            any(
                event == "miracle_cast" and data.get("card") == "Boros Charm"
                for event, data in events
            )
        )

    def test_lorehold_scroll_rack_sets_hand_spell_as_next_draw(self) -> None:
        old_db = battle.DB
        old_handler = battle.REPLAY_EVENT_HANDLER
        events = []
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                        oracle_hash=row.get("oracle_hash"),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                battle.battle_rule_registry._RULE_CACHE.clear()

                player = battle.Player("Lorehold", None, [], is_human=True, strategy="spellslinger")
                opponent = battle.Player("Opponent", None, [], strategy="midrange")
                lorehold = battle.get_card_effect(
                    {
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    }
                )
                scroll_rack = battle.get_card_effect({"name": "Scroll Rack", "type_line": "Artifact"})
                player.battlefield = [
                    {"name": "Plains", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {"name": "Mountain", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {"name": "Command Tower", "type_line": "Land", "effect": "land", "mana_produced": 1},
                    {
                        **lorehold,
                        "name": "Lorehold, the Historian",
                        "type_line": "Legendary Creature — Elder Dragon",
                    },
                    {**scroll_rack, "name": "Scroll Rack", "type_line": "Artifact"},
                ]
                player.hand = [
                    {"name": "Boros Charm", "type_line": "Instant", "cmc": 2, "mana_cost": "{R}{W}"},
                    {"name": "Mountain", "type_line": "Land", "cmc": 0},
                ]
                player.library = [
                    {"name": "Plains", "type_line": "Land", "cmc": 0},
                    {"name": "Rune-Scarred Demon", "type_line": "Creature", "cmc": 7},
                ]
                player.refresh_mana_sources(turn=1)

                activated = battle.activate_lorehold_topdeck_artifacts(
                    player,
                    turn=1,
                    rng=__import__("random").Random(13),
                    phase="upkeep",
                    all_players=[player, opponent],
                    stack=battle.Stack(),
                )
                drawn = player.draw(1, __import__("random").Random(13))
                battle.try_lorehold_miracle_cast(
                    player,
                    drawn,
                    turn=1,
                    phase="draw_step",
                    all_players=[player, opponent],
                    rng=__import__("random").Random(13),
                    stack=battle.Stack(),
                    source="draw_step",
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertEqual(player.library[0]["name"], "Rune-Scarred Demon")
        self.assertTrue(any(card.get("name") == "Plains" for card in player.hand))
        self.assertFalse(any(card.get("name") == "Boros Charm" for card in player.hand))
        top_events = [data for event, data in events if event == "topdeck_manipulation_activated"]
        self.assertEqual(len(top_events), 1)
        self.assertEqual(top_events[0]["activation_kind"], "scroll_rack_single_exchange_for_lorehold")
        self.assertEqual(top_events[0]["hand_to_top"], "Boros Charm")
        self.assertEqual(top_events[0]["hand_gained"], "Plains")
        self.assertTrue(
            any(
                event == "miracle_cast" and data.get("card") == "Boros Charm"
                for event, data in events
            )
        )

    def test_ashnods_altar_resolves_without_free_mana_until_activation_executor_exists(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                spell = {"name": "Ashnod's Altar", "type_line": "Artifact", "cmc": 3}
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(1))
                player.refresh_mana_sources(turn=1)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        self.assertEqual(player.battlefield[0]["name"], "Ashnod's Altar")
        self.assertEqual(player.battlefield[0]["effect"], "passive")
        self.assertEqual(player.available_mana(), 0)

    def test_ashnods_altar_sacrifices_low_value_creature_for_contextual_unlock(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [], strategy="midrange")
                altar_spell = {"name": "Ashnod's Altar", "type_line": "Artifact", "cmc": 3}
                battle.apply_effect_immediate(player, [], altar_spell, turn=1, rng=__import__("random").Random(1))
                player.battlefield.append(
                    {
                        "name": "Servo Token",
                        "type_line": "Artifact Creature — Servo Token",
                        "effect": "creature",
                        "power": 1,
                        "toughness": 1,
                        "tag": "token",
                        "summoning_sick": False,
                        "tapped": False,
                    }
                )
                player.battlefield.append(
                    {
                        "name": "Forest",
                        "type_line": "Basic Land — Forest",
                        "effect": "land",
                        "produces": "G",
                        "mana_produced": 1,
                    }
                )
                player.hand = [
                    {"name": "Rampant Growth", "type_line": "Sorcery", "cmc": 2, "mana_cost": "{1}{G}"}
                ]
                player.library = [
                    {"name": "Plains", "type_line": "Basic Land — Plains", "effect": "land"}
                ]
                player.refresh_mana_sources(turn=2)

                activated = battle.activate_sacrifice_mana_artifacts(
                    player,
                    [],
                    [player],
                    turn=2,
                    phase="precombat_main",
                )
                battle.run_priority_loop(
                    player,
                    [player],
                    battle.Stack(),
                    turn=2,
                    phase="precombat_main",
                    rng=__import__("random").Random(2),
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertFalse(
            any(card.get("name") == "Servo Token" for card in player.battlefield if isinstance(card, dict))
        )
        self.assertFalse(
            any(card.get("name") == "Servo Token" for card in player.graveyard if isinstance(card, dict))
        )
        self.assertTrue(
            any(card.get("name") == "Rampant Growth" for card in player.graveyard if isinstance(card, dict))
        )
        self.assertTrue(
            any(
                card.get("name") == "Plains" and card.get("tapped") is True
                for card in player.battlefield
                if isinstance(card, dict)
            )
        )

    def test_ashnods_altar_does_not_sacrifice_commander_for_generic_unlock(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [], strategy="midrange")
                altar_spell = {"name": "Ashnod's Altar", "type_line": "Artifact", "cmc": 3}
                battle.apply_effect_immediate(player, [], altar_spell, turn=1, rng=__import__("random").Random(1))
                player.battlefield.append(
                    {
                        "name": "Commander Creature",
                        "type_line": "Legendary Creature — Human",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "cmc": 3,
                        "is_commander": True,
                        "summoning_sick": False,
                        "tapped": False,
                    }
                )
                player.battlefield.append(
                    {
                        "name": "Forest",
                        "type_line": "Basic Land — Forest",
                        "effect": "land",
                        "produces": "G",
                        "mana_produced": 1,
                    }
                )
                player.hand = [
                    {"name": "Rampant Growth", "type_line": "Sorcery", "cmc": 2, "mana_cost": "{1}{G}"}
                ]
                player.refresh_mana_sources(turn=2)

                activated = battle.activate_sacrifice_mana_artifacts(
                    player,
                    [],
                    [player],
                    turn=2,
                    phase="precombat_main",
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 0)
        self.assertTrue(
            any(card.get("name") == "Commander Creature" for card in player.battlefield if isinstance(card, dict))
        )
        self.assertFalse(
            any(card.get("name") == "Commander Creature" for card in player.graveyard if isinstance(card, dict))
        )

    def test_incubation_druid_is_active_mana_dork_with_summoning_sickness(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                spell = {
                    "name": "Incubation Druid",
                    "type_line": "Creature — Elf Druid",
                    "cmc": 2,
                }
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(1))
                player.refresh_mana_sources(turn=1)
                same_turn_mana = player.available_mana()
                permanent = player.battlefield[0]
                permanent["summoning_sick"] = False
                player.refresh_mana_sources(turn=2)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        self.assertTrue(player.battlefield[0]["is_mana_source"])
        self.assertTrue(player.battlefield[0]["mana_produced"], 1)
        self.assertEqual(same_turn_mana, 0)
        self.assertEqual(player.available_mana(), 1)

    def test_wall_of_omens_draws_on_etb_without_becoming_draw_spell(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                player.library = [{"name": "Drawn Card", "type_line": "Sorcery", "cmc": 2}]
                spell = {"name": "Wall of Omens", "type_line": "Creature — Wall", "cmc": 2}
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(2))
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        self.assertEqual(player.battlefield[0]["name"], "Wall of Omens")
        self.assertTrue(any(card.get("name") == "Drawn Card" for card in player.hand))
        self.assertEqual(player.graveyard, [])

    def test_firemind_vessel_enters_tapped_as_mana_rock(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        execution_status=row.get("execution_status") or "auto",
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()
                player = battle.Player("Tester", None, [])
                spell = {"name": "Firemind Vessel", "type_line": "Artifact", "cmc": 4}
                battle.apply_effect_immediate(player, [], spell, turn=1, rng=__import__("random").Random(2))
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()

        self.assertEqual(len(player.battlefield), 1)
        vessel = player.battlefield[0]
        self.assertEqual(vessel["name"], "Firemind Vessel")
        self.assertEqual(vessel["effect"], "ramp_permanent")
        self.assertEqual(vessel["mana_produced"], 2)
        self.assertTrue(vessel["tapped"])

    def test_shark_typhoon_creates_token_on_noncreature_spell_cast(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        execution_status=row.get("execution_status") or "auto",
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()
                player = battle.Player("Tester", None, [])
                typhoon = {"name": "Shark Typhoon", "type_line": "Enchantment", "cmc": 6}
                typhoon_effect = battle.get_card_effect(typhoon)
                battle.apply_effect_immediate(
                    player,
                    [],
                    typhoon,
                    turn=1,
                    rng=__import__("random").Random(3),
                    effect_data_override=typhoon_effect,
                )
                battle.trigger_spell_cast_engines(
                    player,
                    [player],
                    {"name": "Ponder", "type_line": "Sorcery", "cmc": 1},
                    turn=1,
                    phase="precombat_main",
                    stack=None,
                    active_player=player,
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()
                battle.battle_rule_registry._RULE_LIST_CACHE.clear()

        tokens = [card for card in player.battlefield if card.get("name") == "Shark Token"]
        self.assertEqual(len(tokens), 1)
        self.assertEqual(tokens[0]["power"], 1)
        self.assertEqual(tokens[0]["toughness"], 1)
        self.assertTrue(tokens[0]["flying"])

    def test_mind_stone_resolves_as_mana_rock_and_can_cash_in_for_draw(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                opponent = battle.Player("Opponent", None, [])
                player.library = [{"name": "Refill Card", "type_line": "Sorcery", "cmc": 2}]
                player.battlefield = [
                    {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                ]
                spell = {"name": "Mind Stone", "type_line": "Artifact", "cmc": 2}
                battle.apply_effect_immediate(player, [], spell, turn=2, rng=__import__("random").Random(3))
                self.assertEqual(player.hand, [])
                self.assertTrue(
                    any(card.get("name") == "Mind Stone" for card in player.battlefield if isinstance(card, dict))
                )
                player.refresh_mana_sources(turn=3)
                activated = battle.activate_utility_artifacts(
                    player,
                    [opponent],
                    [player, opponent],
                    turn=3,
                    rng=__import__("random").Random(4),
                    phase="postcombat_main",
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertTrue(any(card.get("name") == "Mind Stone" for card in player.graveyard if isinstance(card, dict)))
        self.assertTrue(any(card.get("name") == "Refill Card" for card in player.hand))

    def test_hedron_archive_cash_in_draws_two_cards(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Hedron Archive",
                    {
                        "effect": "ramp_permanent",
                        "cmc": 4.0,
                        "produces": "C",
                        "mana_produced": 2,
                        "activation_cost_generic": 2,
                        "activation_requires_tap": True,
                        "activated_self_sacrifice_draw": True,
                        "draw_on_self_sacrifice": 2,
                        "battle_model_scope": "two_mana_rock_self_sacrifice_draw_two_v1",
                    },
                    source="curated",
                    confidence=0.94,
                    review_status="verified",
                    notes="runtime support for draw-two self-sacrifice mana rock",
                )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                opponent = battle.Player("Opponent", None, [])
                player.library = [
                    {"name": "Refill Card A", "type_line": "Sorcery", "cmc": 2},
                    {"name": "Refill Card B", "type_line": "Instant", "cmc": 3},
                ]
                player.battlefield = [
                    {"name": "Plains", "effect": "land", "type_line": "Basic Land — Plains"},
                    {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                    {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                    {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                    {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                ]
                spell = {"name": "Hedron Archive", "type_line": "Artifact", "cmc": 4}
                battle.apply_effect_immediate(player, [], spell, turn=4, rng=__import__("random").Random(7))
                self.assertTrue(
                    any(card.get("name") == "Hedron Archive" for card in player.battlefield if isinstance(card, dict))
                )
                player.refresh_mana_sources(turn=5)
                activated = battle.activate_utility_artifacts(
                    player,
                    [opponent],
                    [player, opponent],
                    turn=5,
                    rng=__import__("random").Random(8),
                    phase="postcombat_main",
                )
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(activated, 1)
        self.assertTrue(any(card.get("name") == "Hedron Archive" for card in player.graveyard if isinstance(card, dict)))
        self.assertTrue(any(card.get("name") == "Refill Card A" for card in player.hand))
        self.assertTrue(any(card.get("name") == "Refill Card B" for card in player.hand))

    def test_wayfarers_bauble_waits_on_battlefield_then_fetches_basic_tapped(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                player = battle.Player("Tester", None, [])
                player.library = [
                    {"name": "Plains Fetched", "effect": "land", "type_line": "Basic Land — Plains"}
                ]
                player.battlefield = [
                    {"name": "Plains A", "effect": "land", "type_line": "Basic Land — Plains"},
                    {"name": "Mountain", "effect": "land", "type_line": "Basic Land — Mountain"},
                    {"name": "Plains B", "effect": "land", "type_line": "Basic Land — Plains"},
                ]
                spell = {"name": "Wayfarer's Bauble", "type_line": "Artifact", "cmc": 1}
                battle.apply_effect_immediate(player, [], spell, turn=2, rng=__import__("random").Random(5))
                self.assertEqual(len(player.library), 1)
                self.assertTrue(
                    any(card.get("name") == "Wayfarer's Bauble" for card in player.battlefield if isinstance(card, dict))
                )
                player.refresh_mana_sources(turn=2)
                battle.activate_land_tutor_creatures(player, turn=2)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(player.library, [])
        self.assertTrue(
            any(card.get("name") == "Wayfarer's Bauble" for card in player.graveyard if isinstance(card, dict))
        )
        self.assertTrue(
            any(
                card.get("name") == "Plains Fetched" and card.get("tapped") is True
                for card in player.battlefield
                if isinstance(card, dict)
            )
        )

    def test_worldfire_uses_reset_rule_and_preserves_commander_replacement(self) -> None:
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "rules.db"
            with closing(sqlite3.connect(db_path)) as conn:
                battle_rule_registry.ensure_battle_card_rules(conn)
                for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
                    battle_rule_registry.upsert_battle_card_rule(
                        conn,
                        row["card_name"],
                        row["effect_json"],
                        source=row["source"],
                        confidence=row["confidence"],
                        review_status=row["review_status"],
                        deck_role_json=row.get("deck_role_json"),
                        notes=row.get("notes", ""),
                    )
                conn.commit()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                rng = __import__("random").Random(7)
                commander = {
                    "name": "Lorehold, the Historian",
                    "type_line": "Legendary Creature — Elder Dragon",
                    "cmc": 4,
                    "power": 2,
                    "toughness": 5,
                    "is_commander": True,
                    "commander_replacement_choice": "command_zone",
                }
                player = battle.Player("Caster", commander, [])
                player.command_zone = []
                player.battlefield = [
                    commander,
                    {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1, "effect": "ramp_permanent"},
                    {"name": "Treasure Token", "type_line": "Artifact Token", "tag": "token", "effect": "creature", "power": 0, "toughness": 0},
                ]
                player.hand = [{"name": "Boros Charm", "type_line": "Instant", "cmc": 2}]
                player.graveyard = [{"name": "Faithless Looting", "type_line": "Sorcery", "cmc": 1}]
                player.treasures = 2
                player.life = 23

                opponent = battle.Player("Opponent", None, [])
                opponent.battlefield = [
                    {"name": "Bear", "type_line": "Creature", "effect": "creature", "power": 2, "toughness": 2},
                ]
                opponent.hand = [{"name": "Counterspell", "type_line": "Instant", "cmc": 2}]
                opponent.graveyard = [{"name": "Ponder", "type_line": "Sorcery", "cmc": 1}]
                opponent.life = 11

                spell = {"name": "Worldfire", "type_line": "Sorcery", "cmc": 9}
                battle.apply_effect_immediate(player, [opponent], spell, turn=5, rng=rng)
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

        self.assertEqual(player.life, 1)
        self.assertEqual(opponent.life, 1)
        self.assertEqual(player.battlefield, [])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual(player.hand, [])
        self.assertEqual(opponent.hand, [])
        self.assertEqual(player.treasures, 0)
        self.assertEqual(player.command_zone[0]["name"], "Lorehold, the Historian")
        self.assertTrue(any(card.get("name") == "Sol Ring" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Boros Charm" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Faithless Looting" for card in player.exile))
        self.assertTrue(any(card.get("name") == "Worldfire" for card in player.graveyard))


if __name__ == "__main__":
    unittest.main()
