import unittest

import lorehold_spell_pressure_topdeck_decision as decision


def sample_payload_inputs():
    builder = {
        "candidates": [
            {
                "candidate_key": decision.CANDIDATE_KEY,
                "final_deck": [
                    {"card_name": "Guttersnipe"},
                    {"card_name": "Young Pyromancer"},
                    {"card_name": "Monastery Mentor"},
                    {"card_name": "Sensei's Divining Top"},
                    {"card_name": "Scroll Rack"},
                ],
            }
        ]
    }
    matrix = {
        "ranked_deck_keys": [decision.BASELINE_KEY, decision.CANDIDATE_KEY],
        "decks": [
            {
                "deck_key": decision.BASELINE_KEY,
                "commander_intent_alignment": {"score": 99.5, "risks": []},
            },
            {
                "deck_key": decision.CANDIDATE_KEY,
                "commander_intent_alignment": {
                    "score": 98.2,
                    "risks": ["package_topdeck_miracle_setup_overfilled"],
                },
            },
        ],
    }
    gate = {
        "results": [
            {
                "deck_key": decision.BASELINE_KEY,
                "wins": 0,
                "losses": 4,
                "stalls": 0,
                "games": 4,
                "win_rate": 0.0,
                "game_results": [
                    {"opponent": "Fixed Lorehold deck 607", "result": "loss"},
                    {"opponent": "Vivi Ornitier #30 (real)", "result": "loss"},
                    {"opponent": "Sisay, Weatherlight Captain #20 (real)", "result": "loss"},
                    {"opponent": "Winota, Joiner of Forces #39 (real)", "result": "loss"},
                ],
                "telemetry": {
                    "strategic_games": {
                        "miracle_cast": {"games": 2},
                        "topdeck_manipulation_activated": {"games": 1},
                        "lorehold_upkeep_rummage": {"games": 2},
                        "lorehold_spell_cast": {"games": 4},
                    }
                },
            },
            {
                "deck_key": decision.CANDIDATE_KEY,
                "wins": 1,
                "losses": 3,
                "stalls": 0,
                "games": 4,
                "win_rate": 0.25,
                "game_results": [
                    {"opponent": "Fixed Lorehold deck 607", "result": "loss"},
                    {"opponent": "Vivi Ornitier #30 (real)", "result": "loss"},
                    {"opponent": "Sisay, Weatherlight Captain #20 (real)", "result": "win"},
                    {"opponent": "Winota, Joiner of Forces #39 (real)", "result": "loss"},
                ],
                "telemetry": {
                    "strategic_games": {
                        "miracle_cast": {"games": 1},
                        "topdeck_manipulation_activated": {"games": 1},
                        "lorehold_upkeep_rummage": {"games": 1},
                        "lorehold_spell_cast": {"games": 4},
                    },
                    "card_event_counts": {
                        "spell_cast:Young Pyromancer": 1,
                        "cost_paid:Young Pyromancer": 1,
                    },
                },
            },
        ]
    }
    pressure_micro = {
        "summary": {
            "natural_trigger_cards": ["Guttersnipe", "Young Pyromancer"],
        }
    }
    cut_blockers = {"summary": {"seed_safe_ready_count": 0}}
    return builder, matrix, gate, pressure_micro, cut_blockers


class LoreholdSpellPressureTopdeckDecisionTest(unittest.TestCase):
    def test_smoke_positive_is_not_confirmable_when_607_and_pressure_proof_fail(self):
        builder, matrix, gate, pressure_micro, cut_blockers = sample_payload_inputs()

        payload = decision.build_payload(
            builder=builder,
            matrix=matrix,
            gate=gate,
            pressure_micro=pressure_micro,
            cut_blockers=cut_blockers,
            builder_path=decision.DEFAULT_BUILDER,
            matrix_path=decision.DEFAULT_MATRIX,
            gate_path=decision.DEFAULT_GATE,
            pressure_micro_path=decision.DEFAULT_PRESSURE_MICRO,
            cut_blockers_path=decision.DEFAULT_CUT_BLOCKERS,
        )

        self.assertEqual(payload["status"], "spell_pressure_smoke_positive_but_not_confirmable")
        self.assertEqual(payload["summary"]["aggregate_delta_wins"], 1)
        self.assertEqual(payload["summary"]["covered_pressure_cards"], list(decision.PRESSURE_CARDS))
        self.assertEqual(payload["summary"]["observed_pressure_cards"], ["Young Pyromancer"])
        self.assertFalse(payload["summary"]["promotion_allowed"])
        self.assertFalse(payload["summary"]["confirmation_allowed"])
        self.assertTrue(payload["decision"]["keep_607_as_protected_baseline"])
        for failure_mode in (
            "structural_rank_below_607",
            "head_to_head_lost_to_607",
            "no_fast_pressure_lift",
            "pressure_pair_underexercised",
            "miracle_topdeck_or_lorehold_floor_regressed",
            "package_density_not_clean",
            "no_seed_safe_cut_fallback",
        ):
            self.assertIn(failure_mode, payload["summary"]["failure_modes"])

    def test_markdown_surfaces_decision_and_external_sources(self):
        builder, matrix, gate, pressure_micro, cut_blockers = sample_payload_inputs()
        payload = decision.build_payload(
            builder=builder,
            matrix=matrix,
            gate=gate,
            pressure_micro=pressure_micro,
            cut_blockers=cut_blockers,
            builder_path=decision.DEFAULT_BUILDER,
            matrix_path=decision.DEFAULT_MATRIX,
            gate_path=decision.DEFAULT_GATE,
            pressure_micro_path=decision.DEFAULT_PRESSURE_MICRO,
            cut_blockers_path=decision.DEFAULT_CUT_BLOCKERS,
        )

        markdown = decision.render_markdown(payload)

        self.assertIn("# Lorehold Spell Pressure Topdeck Decision", markdown)
        self.assertIn("GameTyrant Lorehold deck tech", markdown)
        self.assertIn("EDHREC optimized spellslinger page", markdown)
        self.assertIn("- confirmation_allowed: `false`", markdown)
        self.assertIn("keep_607_as_protected_baseline", markdown)


if __name__ == "__main__":
    unittest.main()
