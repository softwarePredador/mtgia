import unittest
import json
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

    def test_runtime_rule_priority_prefers_land_scaled_treasure_model(self):
        generic = {
            "logical_rule_key": "battle_rule_v1:generic",
            "effect_json": json.dumps(
                {
                    "effect": "treasure_maker",
                    "battle_model_scope": "single_treasure_creation_v1",
                }
            ),
            "review_status": "verified",
            "execution_status": "auto",
        }
        scaled = {
            "logical_rule_key": "battle_rule_v1:scaled",
            "effect_json": json.dumps(
                {
                    "effect": "treasure_maker",
                    "battle_model_scope": "lands_controlled_treasure_count_v1",
                }
            ),
            "review_status": "verified",
            "execution_status": "auto",
        }

        self.assertEqual(
            sorted([generic, scaled], key=gate.battle_rule_runtime_priority)[0],
            scaled,
        )

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
            gate.PACKAGE_DEFINITIONS["boseiju_spell_protection_land"]["family"],
            "spell_protection_land",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["boseiju_spell_protection_land"]["adds"],
            ["Boseiju, Who Shelters All"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["boseiju_spell_protection_land"]["cuts"],
            ["Reliquary Tower"],
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
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_fated"]["family"],
            "pressure_absorber",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_fated"]["adds"],
            ["Boros Charm"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_fated"]["cuts"],
            ["Fated Clash"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_fated"]["allow_miracle_core_cuts"],
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
            gate.PACKAGE_DEFINITIONS["birgi_spellchain_cut_jeskas_will"]["cuts"],
            ["Jeska's Will"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["seething_song_cut_fellwar_stone"]["adds"],
            ["Seething Song"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["storm_kiln_artist_cut_arcane_signet"]["cuts"],
            ["Arcane Signet"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["brass_bounty_cut_boros_signet"]["adds"],
            ["Brass's Bounty"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["brass_bounty_cut_boros_signet"]["cuts"],
            ["Boros Signet"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["runaway_steamkin_cut_talisman"]["cuts"],
            ["Talisman of Conviction"],
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
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_avatar_wrath"]["cuts"],
            ["Avatar's Wrath"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_avatar_wrath"]["allow_miracle_core_cuts"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["overmaster_protect_draw_cut_tibalts_trickery"]["cuts"],
            ["Tibalt's Trickery"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["ghostly_prison_pressure_cut_promise"]["cuts"],
            ["Promise of Loyalty"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["austere_command_wipe_over_emeria_tradeoff"]["family"],
            "pressure_reset_tradeoff",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["austere_command_wipe_over_emeria_tradeoff"]["adds"],
            ["Austere Command"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["austere_command_wipe_over_emeria_tradeoff"]["cuts"],
            ["Emeria's Call // Emeria, Shattered Skyclave"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["austere_command_wipe_over_emeria_tradeoff"][
                "allow_miracle_core_cuts"
            ],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["ghostly_prison_pressure_cut_promise"]["allow_miracle_core_cuts"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["guttersnipe_spell_payoff_cut_prismari"]["family"],
            "spellcast_payoff",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["guttersnipe_spell_payoff_cut_prismari"]["adds"],
            ["Guttersnipe"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["guttersnipe_spell_payoff_cut_prismari"]["cuts"],
            ["Prismari Pianist"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["guttersnipe_spell_payoff_cut_prismari"]["allow_miracle_core_cuts"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["monastery_mentor_spell_tokens_cut_prismari"]["adds"],
            ["Monastery Mentor"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["young_pyromancer_spell_tokens_cut_prismari"]["adds"],
            ["Young Pyromancer"],
        )

    def test_new_cut_safety_aware_packages_do_not_touch_protected_slots(self):
        protected_cut_safety = {
            "enabled": True,
            "cuts_by_name": {
                name: {
                    "card_name": name,
                    "status": "locked_do_not_cut",
                    "current_lane": "protected",
                    "effective_role": "protected",
                    "worst_strong_seed_delta_pp": -55.56,
                    "best_delta_pp": -3.7,
                    "reason": "known strong seed collapsed",
                }
                for name in [
                    "Bender's Waterskin",
                    "Dawn's Truce",
                    "Fated Clash",
                    "Hexing Squelcher",
                    "Pearl Medallion",
                    "Reliquary Tower",
                    "Ruby Medallion",
                    "Storm Herd",
                    "Thor, God of Thunder",
                    "Victory Chimes",
                ]
            },
        }

        new_package_keys = [
            "birgi_spellchain_cut_jeskas_will",
            "seething_song_cut_fellwar_stone",
            "storm_kiln_artist_cut_arcane_signet",
            "brass_bounty_cut_boros_signet",
            "runaway_steamkin_cut_talisman",
            "boros_charm_pressure_cut_avatar_wrath",
            "overmaster_protect_draw_cut_tibalts_trickery",
            "ghostly_prison_pressure_cut_promise",
        ]

        for package_key in new_package_keys:
            with self.subTest(package_key=package_key):
                classification = gate.classify_package_cut_safety(
                    gate.PACKAGE_DEFINITIONS[package_key],
                    protected_cut_safety,
                )
                self.assertEqual(classification["status"], "clear")

    def test_cut_safety_preflight_blocks_previous_failed_cut(self):
        cut_safety = {
            "enabled": True,
            "cuts_by_name": {
                "Fated Clash": {
                    "card_name": "Fated Clash",
                    "status": "locked_do_not_cut",
                    "current_lane": "pressure_absorber_or_protection",
                    "effective_role": "removal",
                    "worst_strong_seed_delta_pp": -88.89,
                    "best_delta_pp": -88.89,
                    "reason": "one or more packages collapsed the known strong seed",
                }
            },
        }

        classification = gate.classify_package_cut_safety(
            gate.PACKAGE_DEFINITIONS["boros_charm_pressure_cut_fated"],
            cut_safety,
        )

        self.assertEqual(classification["status"], "blocked_cut_safety")
        self.assertIn("Fated Clash", classification["reason"])
        self.assertEqual(classification["cuts"][0]["status"], "locked_do_not_cut")

    def test_cut_safety_preflight_allows_explicit_risky_cut_override(self):
        cut_safety = {
            "enabled": True,
            "cuts_by_name": {
                "Bender's Waterskin": {
                    "card_name": "Bender's Waterskin",
                    "status": "risky_cut_only_same_lane",
                    "current_lane": "early_mana",
                    "effective_role": "ramp",
                    "worst_strong_seed_delta_pp": -44.45,
                    "best_delta_pp": 3.7,
                    "reason": "aggregate upside exists, but it broke the known strong seed",
                }
            },
        }
        definition = {
            "adds": ["Three-Mana Ramp Benchmark"],
            "cuts": ["Bender's Waterskin"],
            "cut_safety_override_reason": "same-lane early-mana benchmark preserves the protected ramp job",
        }

        classification = gate.classify_package_cut_safety(definition, cut_safety)

        self.assertEqual(classification["status"], "override_risky_cut_safety")
        self.assertEqual(
            classification["reason"],
            "same-lane early-mana benchmark preserves the protected ramp job",
        )

    def test_prior_evidence_blocks_exact_rejected_package(self):
        prior_results = {
            "enabled": True,
            "by_package_key": {
                "core_challenge_past_over_tragic": [
                    {
                        "package_key": "core_challenge_past_over_tragic",
                        "adds": ["Past in Flames"],
                        "cuts": ["Tragic Arrogance"],
                        "decision": "reject_or_rework",
                        "delta_pp": -50.0,
                        "source_report": "/tmp/prior.json",
                    }
                ]
            },
        }

        classification = gate.classify_package_prior_evidence(
            "core_challenge_past_over_tragic",
            gate.PACKAGE_DEFINITIONS["core_challenge_past_over_tragic"],
            prior_results,
        )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertIn("reject_or_rework", classification["reason"])

    def test_prior_evidence_does_not_block_same_key_with_different_signature(self):
        prior_results = {
            "enabled": True,
            "by_package_key": {
                "one_ring_burden_reset": [
                    {
                        "package_key": "one_ring_burden_reset",
                        "adds": ["The One Ring"],
                        "cuts": ["Artist's Talent"],
                        "decision": "reject_or_rework",
                        "delta_pp": -100.0,
                        "source_report": "/tmp/prior.json",
                    }
                ]
            },
        }

        classification = gate.classify_package_prior_evidence(
            "one_ring_burden_reset",
            gate.PACKAGE_DEFINITIONS["one_ring_burden_reset"],
            prior_results,
        )

        self.assertEqual(classification["status"], "same_key_different_signature")
        self.assertIn("different add/cut signature", classification["reason"])

    def test_render_markdown_handles_preflight_only_rows_without_gate(self):
        markdown = gate.render_markdown(
            {
                "generated_at": "2026-06-27T00:00:00Z",
                "source_db": "/tmp/source.db",
                "games_per_opponent": 1,
                "opponent_limit": 1,
                "opponent_seed": 1,
                "simulation_seed": 42,
                "preflight_only": True,
                "cut_safety_report": "/tmp/cut.json",
                "prior_package_reports": ["/tmp/prior.json"],
                "packages": [
                    {
                        "package_key": "core_challenge_past_over_tragic",
                        "family": "payoff_challenge",
                        "hypothesis": "test",
                        "adds": ["Past in Flames"],
                        "cuts": ["Tragic Arrogance"],
                        "status": "skipped_prior_evidence",
                        "cut_safety": {"status": "clear"},
                        "prior_evidence": {"status": "blocked_prior_reject"},
                        "candidate_meta": {},
                    }
                ],
            }
        )

        self.assertIn("skipped_prior_evidence", markdown)
        self.assertIn("blocked_prior_reject", markdown)

    def test_render_markdown_handles_apply_error_rows_without_gate(self):
        markdown = gate.render_markdown(
            {
                "generated_at": "2026-06-27T00:00:00Z",
                "source_db": "/tmp/source.db",
                "games_per_opponent": 1,
                "opponent_limit": 1,
                "opponent_seed": 1,
                "simulation_seed": 42,
                "preflight_only": False,
                "cut_safety_report": "/tmp/cut.json",
                "prior_package_reports": ["/tmp/prior.json"],
                "packages": [
                    {
                        "package_key": "bad_package",
                        "family": "pressure_absorber",
                        "hypothesis": "test",
                        "adds": ["Boros Charm"],
                        "cuts": ["Avatar's Wrath"],
                        "status": "skipped_candidate_apply_error",
                        "cut_safety": {"status": "clear"},
                        "prior_evidence": {"status": "clear"},
                        "candidate_meta": {},
                    }
                ],
            }
        )

        self.assertIn("skipped_candidate_apply_error", markdown)

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
