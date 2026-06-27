import unittest
from pathlib import Path
from unittest.mock import patch

import lorehold_synergy_package_gate as gate


class LoreholdSynergyPackageGateTest(unittest.TestCase):
    def test_run_gate_uses_decisive_reproducibility_flags(self):
        with patch("lorehold_synergy_package_gate.subprocess.run") as run:
            run.return_value.returncode = 0
            gate.run_gate(
                source_db=Path("/tmp/source.db"),
                candidate_db=Path("/tmp/candidate.db"),
                package_key="brainstone_topdeck_miracle",
                games=3,
                opponent_limit=3,
                opponent_seed=20260626,
                simulation_seed=42,
                game_timeout_seconds=20.0,
                stem="test_stem",
            )

        args, kwargs = run.call_args
        cmd = args[0]
        self.assertIn("--isolate-deck-process", cmd)
        self.assertIn("--no-game-checkpoint", cmd)
        self.assertEqual(kwargs["env"]["PYTHONHASHSEED"], "0")
        self.assertEqual(kwargs["cwd"], str(gate.SCRIPT_DIR))

    def test_package_definitions_include_topdeck_and_squee_enabler_lanes(self):
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["brainstone_topdeck_miracle"]["family"],
            "topdeck_setup",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["faithless_looting_squee_enabler"]["family"],
            "discard_rummage_recursion",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["faithless_looting_squee_enabler"]["adds"],
            ["Faithless Looting"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_squelcher"]["cuts"],
            ["Hexing Squelcher"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_chimes"]["cuts"],
            ["Victory Chimes"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_thor"]["family"],
            "topdeck_freecast",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_thor"]["adds"],
            ["Galvanoth"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_thor"]["cuts"],
            ["Thor, God of Thunder"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["galvanoth_topdeck_freecast_cut_thor"]["allow_miracle_core_cuts"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["penance_topdeck_protection_cut_squelcher"]["family"],
            "topdeck_protection",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["brainstone_topdeck_miracle_cut_squelcher"]["cuts"],
            ["Hexing Squelcher"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["one_ring_protection_draw_cut_squelcher"]["family"],
            "draw_protection",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["ghostly_prison_pressure_cut_squelcher"]["family"],
            "pressure_absorber",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["angel_grace_life_floor_cut_dawn"]["cuts"],
            ["Dawn's Truce"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["angel_grace_life_floor_cut_dawn"]["family"],
            "life_floor_protection",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["birgi_seething_chain_cut_medallions"]["family"],
            "spellchain_mana",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["birgi_seething_chain_cut_medallions"]["adds"],
            ["Birgi, God of Storytelling // Harnfel, Horn of Bounty", "Seething Song"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["birgi_seething_chain_cut_medallions"]["cuts"],
            ["Pearl Medallion", "Ruby Medallion"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_approach_access_cut_creative"]["family"],
            "tutor_access",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_approach_access_cut_creative"]["adds"],
            ["Gamble"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_approach_access_cut_creative"]["cuts"],
            ["Creative Technique"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["gamble_approach_access_cut_creative"]["allow_miracle_core_cuts"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_access_cut_thor"]["adds"],
            ["Gamble"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_access_cut_thor"]["cuts"],
            ["Thor, God of Thunder"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_engine_access_cut_thor"]["family"],
            "tutor_access",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_engine_access_cut_thor"]["adds"],
            ["Enlightened Tutor"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_engine_access_cut_thor"]["cuts"],
            ["Thor, God of Thunder"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["core_challenge_aetherflux_over_storm"]["cuts"],
            ["Storm Herd"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["core_challenge_aetherflux_over_storm"]["allow_miracle_core_cuts"],
        )

    def test_strategic_delta_includes_squee_metrics(self):
        payload = {
            "baseline": {
                "telemetry": {
                    "event_counts": {
                        "ritual_mana_added": 1,
                    },
                    "strategic_event_counts": {
                        "topdeck_manipulation_activated": 2,
                        "hand_to_topdeck_activation": 1,
                        "birgi_spell_cast_mana": 0,
                        "tutor_resolved": 1,
                        "random_discard_after_tutor": 1,
                        "discard_to_top_replacement": 1,
                        "lorehold_rummage_discard_to_top": 2,
                        "lorehold_spell_rummage_discard_to_top": 0,
                        "squee_to_graveyard": 1,
                        "squee_upkeep_return": 0,
                    }
                }
            },
            "candidate": {
                "telemetry": {
                    "event_counts": {
                        "ritual_mana_added": 4,
                    },
                    "strategic_event_counts": {
                        "topdeck_manipulation_activated": 5,
                        "hand_to_topdeck_activation": 4,
                        "birgi_spell_cast_mana": 2,
                        "tutor_resolved": 4,
                        "random_discard_after_tutor": 3,
                        "discard_to_top_replacement": 5,
                        "lorehold_rummage_discard_to_top": 5,
                        "lorehold_spell_rummage_discard_to_top": 3,
                        "squee_to_graveyard": 4,
                        "squee_upkeep_return": 3,
                    }
                }
            },
        }
        delta = gate.strategic_delta(payload)

        self.assertEqual(delta["topdeck_manipulation_activated"], 3)
        self.assertEqual(delta["hand_to_topdeck_activation"], 3)
        self.assertEqual(delta["birgi_spell_cast_mana"], 2)
        self.assertEqual(delta["ritual_mana_added"], 3)
        self.assertEqual(delta["tutor_resolved"], 3)
        self.assertEqual(delta["random_discard_after_tutor"], 2)
        self.assertEqual(delta["discard_to_top_replacement"], 4)
        self.assertEqual(delta["lorehold_rummage_discard_to_top"], 3)
        self.assertEqual(delta["lorehold_spell_rummage_discard_to_top"], 3)
        self.assertEqual(delta["squee_to_graveyard"], 3)
        self.assertEqual(delta["squee_upkeep_return"], 3)
        self.assertIn("squee gy +3", gate.strategic_delta_text(payload))
        self.assertIn("ritual +3", gate.strategic_delta_text(payload))
        self.assertIn("tutor +3", gate.strategic_delta_text(payload))
        self.assertIn("random discard +2", gate.strategic_delta_text(payload))
        self.assertIn("hand to top +3", gate.strategic_delta_text(payload))
        self.assertIn("discard-to-top +4", gate.strategic_delta_text(payload))
        self.assertIn("rummage-to-top +3", gate.strategic_delta_text(payload))
        self.assertIn("spell-rummage-to-top +3", gate.strategic_delta_text(payload))


if __name__ == "__main__":
    unittest.main()
