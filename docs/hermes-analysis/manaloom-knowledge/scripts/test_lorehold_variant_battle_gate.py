import os
import unittest
from tempfile import TemporaryDirectory
from pathlib import Path

import lorehold_variant_battle_gate as gate


class LoreholdVariantBattleGateTest(unittest.TestCase):
    def test_gate_defaults_follow_deckbuilding_contract_matrix(self):
        self.assertEqual(
            gate.DEFAULT_MATRIX.name,
            "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json",
        )
        focus = gate.focus_trace_cards()
        self.assertIn("Birgi, God of Storytelling // Harnfel, Horn of Bounty", focus)
        self.assertIn("Mana Vault", focus)
        self.assertIn("Aetherflux Reservoir", focus)
        self.assertIn("Molecule Man", focus)

    def test_gate_telemetry_counts_lorehold_strategy_events(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-1")
        telemetry.record("miracle_cast", {"player": "Lorehold", "card": "Austere Command"})
        telemetry.record("cost_paid", {"player": "Lorehold", "card": "Sol Ring"})
        telemetry.record(
            "cost_paid",
            {
                "player": "Lorehold",
                "card": "Rise of the Eldrazi",
                "locked_cost": {
                    "generic": 8,
                    "static_cost_reduction_total": 2,
                    "static_cost_reductions": [
                        {
                            "source": "The Scarlet Witch",
                            "applied_amount": 2,
                            "scope": "power_based_instant_sorcery_cost_reduction_v1",
                        }
                    ],
                },
            },
        )
        telemetry.record("cost_paid", {"player": "Lorehold", "card": "Thor, God of Thunder"})
        telemetry.record("spell_cast", {"player": "Opponent", "card": "Counterspell"})
        telemetry.record("spell_cast", {"player": "Lorehold", "card": "Thor, God of Thunder"})
        telemetry.record("treasure_created", {"player": "Lorehold", "card": "Brass's Bounty"})
        telemetry.record("topdeck_manipulation_activated", {"player": "Lorehold", "card": "Scroll Rack"})
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "trigger": "spell_cast",
                "effect": "add_mana",
                "mana_added": 1,
            },
        )
        telemetry.record(
            "activated_ability",
            {
                "player": "Lorehold",
                "card": "Penance",
                "activation_kind": "put_card_from_hand_on_top_library_prevent_chosen_source_damage",
                "topdecked_card": "Rise of the Eldrazi",
            },
        )
        telemetry.record(
            "combat_step",
            {
                "step": "declare_attackers",
                "attacker": "Opponent",
                "target": "Lorehold",
                "attack_restrictions": [
                    {
                        "attack_restriction_sources": ["Ghostly Prison"],
                        "attackers_before": 3,
                        "attackers_after": 1,
                        "attackers_restricted": 2,
                        "tax_paid": 2,
                    },
                    {
                        "attack_tax_sources": [{"card": "Sphere of Safety"}],
                        "attackers_before": 2,
                        "attackers_after": 2,
                        "attackers_restricted": 0,
                        "tax_paid": 6,
                    },
                ],
            },
        )
        telemetry.record(
            "lorehold_upkeep_rummage",
            {
                "player": "Lorehold",
                "discarded": "Squee, Goblin Nabob",
                "discard_destination": "graveyard",
            },
        )
        telemetry.record(
            "lorehold_upkeep_rummage",
            {
                "player": "Lorehold",
                "discarded": "Storm Herd",
                "discard_destination": "top_of_library",
                "replacement_used": True,
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Monument to Endurance",
                "effect": "rummage",
                "discarded": "Squee, Goblin Nabob",
                "discarded_to_graveyard": ["Squee, Goblin Nabob"],
                "discarded_to_top": ["Rise of the Eldrazi"],
            },
        )
        telemetry.record(
            "permanent_moved_from_battlefield",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "from_zone": "battlefield",
                "to_zone": "graveyard",
                "destination": "graveyard",
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )
        telemetry.begin("game-2")
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(2)

        self.assertEqual(payload["strategic_event_counts"]["miracle_cast"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_cast"], 1)
        self.assertEqual(payload["strategic_event_counts"]["thor_cost_paid"], 1)
        self.assertEqual(payload["strategic_event_counts"]["thor_spell_cast"], 1)
        self.assertEqual(payload["strategic_event_counts"]["spell_cast_mana_trigger"], 1)
        self.assertEqual(payload["strategic_event_counts"]["birgi_spell_cast_mana"], 1)
        self.assertEqual(payload["strategic_event_counts"]["static_cost_reduction_casts"], 1)
        self.assertEqual(payload["strategic_event_counts"]["static_cost_reduction_total"], 2)
        self.assertEqual(payload["strategic_event_counts"]["scarlet_static_cost_reduction_casts"], 1)
        self.assertEqual(payload["strategic_event_counts"]["scarlet_static_cost_reduction_total"], 2)
        self.assertEqual(payload["strategic_event_counts"]["hand_to_topdeck_activation"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_upkeep_rummage"], 2)
        self.assertEqual(payload["strategic_event_counts"]["discard_to_top_replacement"], 2)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_rummage_discard_to_top"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_rummage_discards_squee"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_rummage"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_rummage_discard_to_top"], 1)
        self.assertEqual(payload["strategic_event_counts"]["lorehold_spell_rummage_discards_squee"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_to_graveyard"], 3)
        self.assertEqual(payload["strategic_event_counts"]["squee_upkeep_return"], 2)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_after_known_graveyard_entry"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_without_known_graveyard_entry"], 1)
        self.assertEqual(payload["event_counts_by_game"]["game-1"]["miracle_cast"], 1)
        self.assertEqual(payload["card_event_counts"]["cost_paid:Sol Ring"], 1)
        self.assertEqual(payload["card_event_counts"]["cost_paid:Rise of the Eldrazi"], 1)
        self.assertEqual(payload["card_event_counts"]["spell_cast:Thor, God of Thunder"], 1)
        self.assertEqual(payload["card_event_counts"]["treasure_created:Brass's Bounty"], 1)
        self.assertEqual(payload["card_strategy_counts"]["static_cost_reduction_on:Rise of the Eldrazi"], 2)
        self.assertEqual(payload["card_strategy_counts"]["static_cost_reduction_saved:The Scarlet Witch"], 2)
        self.assertEqual(payload["card_strategy_counts"]["static_cost_reduction_source_cast:The Scarlet Witch"], 1)
        self.assertEqual(payload["card_strategy_counts"]["topdeck:Scroll Rack"], 1)
        self.assertEqual(payload["card_strategy_counts"]["discard_to_top:Storm Herd"], 1)
        self.assertEqual(payload["card_strategy_counts"]["spell_rummage_to_top:Rise of the Eldrazi"], 1)
        self.assertEqual(payload["lorehold_attack_restrictions"]["events"], 2)
        self.assertEqual(payload["lorehold_attack_restrictions"]["attackers_before"], 5)
        self.assertEqual(payload["lorehold_attack_restrictions"]["attackers_after"], 3)
        self.assertEqual(payload["lorehold_attack_restrictions"]["attackers_restricted"], 2)
        self.assertEqual(payload["lorehold_attack_restrictions"]["tax_paid"], 8)
        self.assertEqual(payload["lorehold_attack_restriction_source_events"]["Ghostly Prison"], 1)
        self.assertEqual(payload["lorehold_attack_restriction_source_events"]["Sphere of Safety"], 1)
        self.assertEqual(
            payload["lorehold_attack_restriction_source_attackers_restricted"]["Ghostly Prison"],
            2,
        )
        self.assertEqual(
            payload["lorehold_attack_restriction_source_tax_paid"]["Sphere of Safety"],
            6,
        )
        self.assertEqual(
            payload["lorehold_attack_restrictions_by_game"]["game-1"]["attackers_restricted"],
            2,
        )
        self.assertEqual(
            payload["card_event_counts_by_game"]["game-1"]["treasure_created:Brass's Bounty"],
            1,
        )
        self.assertEqual(
            telemetry.game_summary("game-1")["card_event_counts"]["treasure_created:Brass's Bounty"],
            1,
        )
        self.assertEqual(payload["strategic_event_counts_by_game"]["game-1"]["squee_to_graveyard"], 3)
        self.assertEqual(payload["strategic_event_counts_by_game"]["game-1"]["squee_upkeep_return"], 1)
        self.assertEqual(
            telemetry.game_summary("game-1")["lorehold_attack_restrictions"]["tax_paid"],
            8,
        )
        self.assertEqual(
            telemetry.game_summary("game-1")["lorehold_attack_restriction_source_events"]["Ghostly Prison"],
            1,
        )
        self.assertEqual(
            payload["strategic_event_counts_by_game"]["game-2"]["squee_return_without_known_graveyard_entry"],
            1,
        )
        self.assertEqual(telemetry.game_summary("game-1")["strategic_event_counts"]["squee_to_graveyard"], 3)
        self.assertEqual(telemetry.game_summary("game-2")["squee_anomaly_count"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["miracle_cast"]["rate"], 0.5)
        self.assertEqual(payload["strategic_games"]["lorehold_spell_cast"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["birgi_spell_cast_mana"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["scarlet_static_cost_reduction_casts"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["scarlet_static_cost_reduction_total"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["hand_to_topdeck_activation"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["discard_to_top_replacement"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["lorehold_rummage_discard_to_top"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["lorehold_spell_rummage_discard_to_top"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["thor_cost_paid"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["thor_spell_cast"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["squee_upkeep_return"]["games"], 2)
        self.assertEqual(payload["strategic_games"]["squee_to_graveyard"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["squee_return_after_known_graveyard_entry"]["games"], 1)
        self.assertEqual(payload["strategic_games"]["squee_return_without_known_graveyard_entry"]["games"], 1)
        self.assertEqual(payload["squee_known_graveyard_balance_by_game"]["game-1"], 2)
        self.assertEqual(payload["squee_anomalies"][0]["kind"], "squee_return_without_known_graveyard_entry")
        self.assertEqual(payload["squee_anomalies"][0]["game_id"], "game-2")
        self.assertIn("game-1", payload["squee_game_traces"])
        self.assertIn("game-2", payload["squee_game_traces"])

    def test_merge_structural_context_assigns_battle_rank(self):
        results = [
            {"deck_key": "deck_6", "win_rate": 10, "losses": 3, "stalls": 0},
            {"deck_key": "candidate_v7", "win_rate": 30, "losses": 2, "stalls": 1},
        ]
        merged = gate.merge_structural_context(
            results,
            {
                "deck_6": {"structural_rank": 2, "strategy_score": 138.2},
                "candidate_v7": {"structural_rank": 1, "strategy_score": 141.7},
            },
        )

        by_key = {row["deck_key"]: row for row in merged}
        self.assertEqual(by_key["candidate_v7"]["battle_rank"], 1)
        self.assertEqual(by_key["candidate_v7"]["structural_rank"], 1)
        self.assertEqual(by_key["deck_6"]["battle_rank"], 2)

    def test_gate_telemetry_treats_milled_squee_as_graveyard_entry(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-mill")
        telemetry.record(
            "mill_resolved",
            {
                "player": "Opponent",
                "card": "Brain Freeze",
                "target_player": "Lorehold",
                "milled": ["Squee, Goblin Nabob", "Mountain"],
                "cards_milled": 2,
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(1)

        self.assertEqual(payload["strategic_event_counts"]["squee_to_graveyard"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_upkeep_return"], 1)
        self.assertEqual(payload["strategic_event_counts"]["squee_return_after_known_graveyard_entry"], 1)
        self.assertEqual(payload["strategic_event_counts_by_game"]["game-mill"]["squee_to_graveyard"], 1)
        self.assertEqual(payload["strategic_event_counts_by_game"]["game-mill"]["squee_upkeep_return"], 1)
        self.assertEqual(telemetry.game_summary("game-mill")["squee_trace_count"], 2)
        self.assertNotIn(
            "squee_return_without_known_graveyard_entry",
            payload["strategic_event_counts"],
        )
        self.assertEqual(payload["squee_known_graveyard_balance_by_game"]["game-mill"], 0)
        self.assertEqual(payload["squee_anomalies"], [])

    def test_gate_telemetry_records_focus_card_trace_payload(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-focus")
        telemetry.record(
            "saga_chapter_resolved",
            {
                "player": "Lorehold",
                "card": "Urza's Saga",
                "chapter": 3,
                "target_type": "artifact_cmc_1_or_less",
                "found": "Sol Ring",
                "candidate_names": ["Sol Ring", "Sensei's Divining Top"],
                "legal_target_names": ["Sol Ring", "Sensei's Divining Top"],
                "selected_reason": "mana_priority",
                "turn": 4,
            },
        )
        telemetry.record(
            "topdeck_manipulation_activated",
            {
                "player": "Lorehold",
                "card": "Sensei's Divining Top",
                "activation_kind": "peek_reorder_for_lorehold",
                "top_before": "Mountain",
                "top_after": "Approach of the Second Sun",
                "turn": 5,
            },
        )
        telemetry.record(
            "utility_artifact_activated",
            {
                "player": "Lorehold",
                "card": "The Mind Stone",
                "activation_kind": "harness",
                "blink_target": "Esper Sentinel",
                "blink_target_score": 18,
                "turn": 6,
            },
        )
        telemetry.record(
            "land_tax_trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Land Tax",
                "found_cards": ["Plains", "Mountain"],
                "condition_met": True,
                "turn": 7,
            },
        )

        payload = telemetry.as_json(1)

        traces = payload["focus_card_game_traces"]["game-focus"]
        self.assertEqual(len(traces), 4)
        self.assertEqual(
            payload["focus_card_trace_card_counts_by_game"]["game-focus"]["Urza's Saga"],
            1,
        )
        self.assertEqual(
            payload["focus_card_trace_card_counts_by_game"]["game-focus"]["The Mind Stone"],
            1,
        )
        saga_trace = next(row for row in traces if row["event"] == "saga_chapter_resolved")
        self.assertEqual(saga_trace["data"]["candidate_names"], ["Sol Ring", "Sensei's Divining Top"])
        self.assertIn("Urza's Saga", saga_trace["cards"])
        self.assertEqual(telemetry.game_summary("game-focus")["focus_card_trace_count"], 4)
        self.assertEqual(
            telemetry.game_summary("game-focus")["focus_card_trace_card_counts"]["Land Tax"],
            1,
        )

    def test_gate_telemetry_records_focus_card_access_snapshot(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-access")
        telemetry.record(
            "focus_card_access_snapshot",
            {
                "player": "Lorehold",
                "phase": "opening_keep",
                "turn": 0,
                "hand_size": 7,
                "library_size": 92,
                "focus_card_zones": {
                    "Squee, Goblin Nabob": {
                        "zone": "library",
                        "library_position": 18,
                    },
                    "Sensei's Divining Top": {"zone": "hand"},
                    "Library of Leng": {"zone": "absent"},
                },
                "focus_cards_seen": ["Squee, Goblin Nabob", "Sensei's Divining Top"],
                "hand_focus": ["Sensei's Divining Top"],
                "library_focus": ["Squee, Goblin Nabob"],
                "library_top_focus": [],
                "top_library": [{"name": "Mountain"}],
                "opening_reason": "early_card_flow:Sensei's Divining Top:1",
            },
        )

        payload = telemetry.as_json(1)
        trace = payload["focus_card_game_traces"]["game-access"][0]
        self.assertEqual(trace["event"], "focus_card_access_snapshot")
        self.assertIn("Squee, Goblin Nabob", trace["cards"])
        self.assertEqual(
            trace["data"]["focus_card_zones"]["Squee, Goblin Nabob"]["library_position"],
            18,
        )
        self.assertEqual(
            payload["focus_card_trace_card_counts_by_game"]["game-access"]["Sensei's Divining Top"],
            1,
        )
        top_access = payload["focus_card_access_summary"]["Sensei's Divining Top"]
        self.assertEqual(top_access["accessed_games"], 1)
        self.assertEqual(top_access["opening_hand_games"], 1)
        self.assertEqual(top_access["dominant_zone"], "hand")
        squee_access = payload["focus_card_access_by_game"]["Squee, Goblin Nabob"]["game-access"]
        self.assertFalse(squee_access["accessed"])
        self.assertTrue(squee_access["library_only"])

    def test_gate_telemetry_summarizes_dynamic_focus_card_access(self):
        previous = os.environ.get("MANALOOM_FOCUS_ACCESS_CARDS")
        os.environ["MANALOOM_FOCUS_ACCESS_CARDS"] = '["Mana Vault"]'
        try:
            telemetry = gate.GateTelemetry()
            telemetry.begin("game-mana-vault")
            telemetry.record(
                "focus_card_access_snapshot",
                {
                    "player": "Lorehold",
                    "phase": "opening_keep",
                    "turn": 0,
                    "focus_card_zones": {"Mana Vault": {"zone": "hand"}},
                    "focus_cards_seen": ["Mana Vault"],
                    "hand_focus": ["Mana Vault"],
                    "library_focus": [],
                    "library_top_focus": [],
                },
            )

            payload = telemetry.as_json(1)
        finally:
            if previous is None:
                os.environ.pop("MANALOOM_FOCUS_ACCESS_CARDS", None)
            else:
                os.environ["MANALOOM_FOCUS_ACCESS_CARDS"] = previous

        access = payload["focus_card_access_summary"]["Mana Vault"]
        self.assertEqual(access["accessed_games"], 1)
        self.assertEqual(access["opening_hand_games"], 1)
        self.assertEqual(access["dominant_zone"], "hand")
        self.assertTrue(
            payload["focus_card_access_by_game"]["Mana Vault"]["game-mana-vault"]["accessed"]
        )

    def test_gate_telemetry_does_not_count_spell_target_as_squee_graveyard_entry(self):
        telemetry = gate.GateTelemetry()
        telemetry.begin("game-target")
        telemetry.record(
            "spell_resolved",
            {
                "player": "Lorehold",
                "card": "Fated Clash",
                "target": "Squee, Goblin Nabob",
                "from_zone": "hand",
                "to_zone": "graveyard",
                "destination": "graveyard",
            },
        )
        telemetry.record(
            "trigger_resolved",
            {
                "player": "Lorehold",
                "card": "Squee, Goblin Nabob",
                "effect": "graveyard_upkeep_return_self_to_hand",
            },
        )

        payload = telemetry.as_json(1)

        self.assertNotIn("squee_to_graveyard", payload["strategic_event_counts"])
        self.assertEqual(payload["strategic_event_counts"]["squee_return_without_known_graveyard_entry"], 1)
        self.assertEqual(payload["squee_anomalies"][0]["game_id"], "game-target")

    def test_write_game_checkpoint_persists_latest_progress(self):
        with TemporaryDirectory() as tmpdir:
            payload = {
                "generated_at": "2026-06-26T00:00:00Z",
                "status": "running",
                "stem": "checkpoint_test",
                "completed_games": 1,
                "total_games": 3,
                "game_timeout_seconds": 30.0,
                "latest": {
                    "deck_key": "deck_607",
                    "opponent": "Winota",
                    "last_result": "stall",
                    "last_turns": 8,
                    "last_reason": "game_timeout_30.0s",
                },
                "events": [
                    {
                        "completed_games": 1,
                        "deck_key": "deck_607",
                        "opponent": "Winota",
                        "last_result": "stall",
                        "last_turns": 8,
                        "last_reason": "game_timeout_30.0s",
                    }
                ],
            }
            json_path, md_path = gate.write_game_checkpoint(
                payload,
                "checkpoint_test",
                report_dir=Path(tmpdir),
            )

            self.assertTrue(json_path.exists())
            self.assertTrue(md_path.exists())
            self.assertIn("game_timeout_30.0s", md_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
