import unittest
import json
import sqlite3
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import lorehold_synergy_package_gate as gate


class LoreholdSynergyPackageGateTest(unittest.TestCase):
    def test_run_gate_uses_decisive_reproducibility_flags(self):
        with patch("lorehold_synergy_package_gate.subprocess.Popen") as popen:
            process = MagicMock()
            process.pid = 123
            process.returncode = 0
            process.communicate.return_value = ("", "")
            popen.return_value = process
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

        args, kwargs = popen.call_args
        cmd = args[0]
        self.assertIn("--isolate-deck-process", cmd)
        self.assertNotIn("--no-game-checkpoint", cmd)
        self.assertEqual(kwargs["env"]["PYTHONHASHSEED"], "0")
        self.assertEqual(kwargs["cwd"], str(gate.SCRIPT_DIR))

    def test_run_gate_can_disable_checkpoint_explicitly_for_smoke_runs(self):
        with patch("lorehold_synergy_package_gate.subprocess.Popen") as popen:
            process = MagicMock()
            process.pid = 123
            process.returncode = 0
            process.communicate.return_value = ("", "")
            popen.return_value = process
            gate.run_gate(
                source_db=Path("/tmp/source.db"),
                candidate_db=Path("/tmp/candidate.db"),
                package_key="brainstone_topdeck_miracle",
                games=1,
                opponent_limit=1,
                opponent_seed=20260626,
                simulation_seed=42,
                game_timeout_seconds=20.0,
                stem="test_stem",
                no_game_checkpoint=True,
            )

        cmd = popen.call_args.args[0]
        self.assertIn("--no-game-checkpoint", cmd)

    def test_run_gate_can_force_focus_access_for_targeted_exposure_runs(self):
        with patch("lorehold_synergy_package_gate.subprocess.Popen") as popen:
            process = MagicMock()
            process.pid = 123
            process.returncode = 0
            process.communicate.return_value = ("", "")
            popen.return_value = process
            gate.run_gate(
                source_db=Path("/tmp/source.db"),
                candidate_db=Path("/tmp/candidate.db"),
                package_key="mana_vault_fast_mana_cut_arcane_signet",
                games=1,
                opponent_limit=1,
                opponent_seed=20260626,
                simulation_seed=42,
                game_timeout_seconds=20.0,
                stem="test_stem",
                forced_access_mode="opening_hand",
            )

        cmd = popen.call_args.args[0]
        self.assertIn("--force-focus-access", cmd)
        self.assertIn("opening_hand", cmd)

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
            gate.PACKAGE_DEFINITIONS["pg245_verge_rangers_topdeck_land_cut_waterskin"]["family"],
            "topdeck_play",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["pg245_verge_rangers_topdeck_land_cut_waterskin"]["adds"],
            ["Verge Rangers"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["pg245_verge_rangers_topdeck_land_cut_waterskin"]["cuts"],
            ["Bender's Waterskin"],
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
            gate.PACKAGE_DEFINITIONS["hidden_retreat_stack_damage_topdeck_cut_promise"]["family"],
            "topdeck_protection",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["hidden_retreat_stack_damage_topdeck_cut_promise"]["adds"],
            ["Hidden Retreat"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["hidden_retreat_stack_damage_topdeck_cut_promise"]["cuts"],
            ["Promise of Loyalty"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["hidden_retreat_stack_damage_topdeck_cut_promise"][
                "allow_miracle_core_cuts"
            ],
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
            gate.PACKAGE_DEFINITIONS["gamble_access_benchmark_cut_land_tax"]["family"],
            "tutor_access_benchmark",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_access_benchmark_cut_land_tax"]["adds"],
            ["Gamble"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["gamble_access_benchmark_cut_land_tax"]["cuts"],
            ["Land Tax"],
        )
        self.assertIn(
            "lorehold_tutor_cut_model_20260627_v1",
            gate.PACKAGE_DEFINITIONS["gamble_access_benchmark_cut_land_tax"][
                "cut_safety_override_reason"
            ],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_access_benchmark_cut_land_tax"]["family"],
            "tutor_access_benchmark",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_access_benchmark_cut_land_tax"]["adds"],
            ["Enlightened Tutor"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["enlightened_access_benchmark_cut_land_tax"]["cuts"],
            ["Land Tax"],
        )
        self.assertIn(
            "lorehold_tutor_cut_model_20260627_v1",
            gate.PACKAGE_DEFINITIONS["enlightened_access_benchmark_cut_land_tax"][
                "cut_safety_override_reason"
            ],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["valakut_hand_filter_cut_big_score"]["family"],
            "hand_filter_benchmark",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["valakut_hand_filter_cut_big_score"]["adds"],
            ["Valakut Awakening // Valakut Stoneforge"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["valakut_hand_filter_cut_big_score"]["cuts"],
            ["Big Score"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["valakut_hand_filter_cut_big_score"][
                "allow_miracle_core_cuts"
            ],
        )
        self.assertIn(
            "lorehold_hand_filter_cut_model_20260627_v1",
            gate.PACKAGE_DEFINITIONS["valakut_hand_filter_cut_big_score"][
                "cut_safety_override_reason"
            ],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["wheel_hand_filter_cut_big_score"]["family"],
            "hand_filter_benchmark",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["wheel_hand_filter_cut_big_score"]["adds"],
            ["Wheel of Fortune"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["wheel_hand_filter_cut_big_score"]["cuts"],
            ["Big Score"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["wheel_hand_filter_cut_big_score"][
                "allow_miracle_core_cuts"
            ],
        )
        self.assertIn(
            "lorehold_hand_filter_cut_model_20260627_v2_prior_aware",
            gate.PACKAGE_DEFINITIONS["wheel_hand_filter_cut_big_score"][
                "cut_safety_override_reason"
            ],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["volcanic_recursion_cut_pinnacle"]["family"],
            "graveyard_recursion_benchmark",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["volcanic_recursion_cut_pinnacle"]["adds"],
            ["Volcanic Vision"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["volcanic_recursion_cut_pinnacle"]["cuts"],
            ["Pinnacle Monk // Mystic Peak"],
        )
        self.assertTrue(
            gate.PACKAGE_DEFINITIONS["volcanic_recursion_cut_pinnacle"][
                "allow_miracle_core_cuts"
            ],
        )
        self.assertIn(
            "lorehold_recursion_cut_model_20260627_v1",
            gate.PACKAGE_DEFINITIONS["volcanic_recursion_cut_pinnacle"][
                "cut_safety_override_reason"
            ],
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
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["pg245_twinflame_damage_payoff_cut_thor"]["family"],
            "static_damage_modifier",
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["pg245_twinflame_damage_payoff_cut_thor"]["adds"],
            ["Twinflame Tyrant"],
        )
        self.assertEqual(
            gate.PACKAGE_DEFINITIONS["pg245_twinflame_damage_payoff_cut_thor"]["cuts"],
            ["Thor, God of Thunder"],
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

    def test_registry_protected_cut_blocks_even_without_cut_safety_row(self):
        with tempfile.TemporaryDirectory() as tmp:
            registry = Path(tmp) / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "protected_cards_until_same_function_replacement_wins": [
                            "Promise of Loyalty",
                        ]
                    }
                ),
                encoding="utf-8",
            )

            cut_safety = gate.merge_registry_cut_guard(
                {"enabled": True, "path": "/tmp/cut.json", "summary": {}, "cuts_by_name": {}},
                gate.load_registry_cut_guard(registry),
            )
            classification = gate.classify_package_cut_safety(
                {
                    "adds": ["Penance"],
                    "cuts": ["Promise of Loyalty"],
                    "cut_safety_override_reason": "generic override is not enough",
                },
                cut_safety,
            )

        self.assertEqual(classification["status"], "blocked_cut_safety")
        self.assertIn("registry-protected", classification["reason"])
        self.assertEqual(
            classification["cuts"][0]["status"],
            "protected_until_same_function_replacement_wins",
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

    def test_forced_access_diagnostic_does_not_require_prior_ignore_flag(self):
        prior_results = {
            "enabled": True,
            "by_package_key": {
                "mana_vault_fast_mana_cut_arcane_signet": [
                    {
                        "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                        "adds": ["Mana Vault"],
                        "cuts": ["Arcane Signet"],
                        "decision": "reject_or_rework",
                        "delta_pp": -66.67,
                        "source_report": "/tmp/prior.json",
                    }
                ]
            },
        }

        classification = gate.classify_package_prior_evidence(
            "mana_vault_fast_mana_cut_arcane_signet",
            gate.PACKAGE_DEFINITIONS["mana_vault_fast_mana_cut_arcane_signet"],
            prior_results,
            forced_access_mode="opening_hand",
        )

        self.assertEqual(
            classification["status"],
            "forced_access_diagnostic_despite_prior_reject",
        )
        self.assertIn("diagnostic", classification["reason"])

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

    def test_prior_evidence_blocks_rejected_add_cut_signature_under_different_key(self):
        with tempfile.TemporaryDirectory() as tmp:
            prior = Path(tmp) / "prior.json"
            prior.write_text(
                json.dumps(
                    {
                        "packages": [
                            {
                                "package_key": "old_mana_vault_probe",
                                "adds": ["Mana Vault"],
                                "cuts": ["Arcane Signet"],
                                "decision": "reject_or_rework",
                                "gate_summary": {"delta_pp": -66.67},
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.load_prior_package_results([prior])
            classification = gate.classify_package_prior_evidence(
                "mana_vault_fast_mana_cut_arcane_signet",
                gate.PACKAGE_DEFINITIONS["mana_vault_fast_mana_cut_arcane_signet"],
                prior_results,
            )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertEqual(classification["matches"][0]["package_key"], "old_mana_vault_probe")

    def test_prior_evidence_loads_cut_safety_observation_rejects(self):
        with tempfile.TemporaryDirectory() as tmp:
            prior = Path(tmp) / "strategy_audit.json"
            prior.write_text(
                json.dumps(
                    {
                        "cut_safety_manifest": {
                            "cuts": [
                                {
                                    "card_name": "Hexing Squelcher",
                                    "observations": [
                                        {
                                            "package_key": "faithless_looting_squee_enabler",
                                            "family": "discard_rummage_recursion",
                                            "adds": ["Faithless Looting"],
                                            "baseline": "8-19",
                                            "candidate": "4-23",
                                            "decision": "reject_or_rework",
                                            "delta_pp": -14.82,
                                            "strong_seed_delta_pp": -66.67,
                                        }
                                    ],
                                }
                            ]
                        }
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.load_prior_package_results([prior])
            classification = gate.classify_package_prior_evidence(
                "faithless_looting_squee_enabler",
                gate.PACKAGE_DEFINITIONS["faithless_looting_squee_enabler"],
                prior_results,
            )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertEqual(classification["matches"][0]["cuts"], ["Hexing Squelcher"])
        self.assertEqual(classification["matches"][0]["source_section"], "cut_safety_manifest")
        self.assertEqual(classification["matches"][0]["delta_pp"], -14.82)
        self.assertEqual(classification["matches"][0]["baseline"]["wins"], 8)
        self.assertEqual(classification["matches"][0]["candidate"]["losses"], 23)

    def test_prior_evidence_loads_strategy_audit_package_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            prior = Path(tmp) / "strategy_audit.json"
            prior.write_text(
                json.dumps(
                    {
                        "post_squee_package_gates": {
                            "rows": [
                                {
                                    "package_key": "faithless_looting_squee_enabler",
                                    "family": "discard_rummage_recursion",
                                    "adds": ["Faithless Looting"],
                                    "cuts": ["Hexing Squelcher"],
                                    "baseline_wins": 8,
                                    "baseline_losses": 19,
                                    "candidate_wins": 4,
                                    "candidate_losses": 23,
                                    "decision": "reject_or_rework",
                                    "delta_pp": -14.82,
                                }
                            ]
                        }
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.load_prior_package_results([prior])
            classification = gate.classify_package_prior_evidence(
                "faithless_looting_squee_enabler",
                gate.PACKAGE_DEFINITIONS["faithless_looting_squee_enabler"],
                prior_results,
            )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertEqual(classification["matches"][0]["source_section"], "post_squee_package_gates")
        self.assertEqual(classification["matches"][0]["baseline"]["wins"], 8)
        self.assertEqual(classification["matches"][0]["candidate"]["wins"], 4)

    def test_external_package_definition_file_loads_new_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            package_file = Path(tmp) / "packages.json"
            package_file.write_text(
                json.dumps(
                    {
                        "packages": [
                            {
                                "package_key": "gods_willing_commander_shield_cut_avatar_wrath",
                                "family": "targeted_commander_protection",
                                "hypothesis": "Test cheap commander protection over a slower protected-slot benchmark.",
                                "adds": ["Gods Willing"],
                                "cuts": ["Avatar's Wrath"],
                                "allow_miracle_core_cuts": True,
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            definitions, loaded = gate.merge_package_definitions([package_file])

        definition = definitions["gods_willing_commander_shield_cut_avatar_wrath"]
        self.assertEqual(loaded, [str(package_file)])
        self.assertEqual(definition["adds"], ["Gods Willing"])
        self.assertEqual(definition["cuts"], ["Avatar's Wrath"])
        self.assertTrue(definition["allow_miracle_core_cuts"])

    def test_external_package_definition_file_rejects_static_key_collision(self):
        with tempfile.TemporaryDirectory() as tmp:
            package_file = Path(tmp) / "packages.json"
            package_file.write_text(
                json.dumps(
                    {
                        "packages": [
                            {
                                "package_key": "reprieve_cut_avatar_wrath",
                                "hypothesis": "Collision should fail.",
                                "adds": ["Gods Willing"],
                                "cuts": ["Avatar's Wrath"],
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            with self.assertRaises(ValueError):
                gate.merge_package_definitions([package_file])

    def test_parse_registry_swap_scope_preserves_mdfc_slashes(self):
        adds, cuts = gate.parse_registry_swap_scope(
            "+Birgi, God of Storytelling // Harnfel, Horn of Bounty / +Seething Song; "
            "-Pinnacle Monk // Mystic Peak / -Arcane Signet"
        )

        self.assertEqual(
            adds,
            [
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "Seething Song",
            ],
        )
        self.assertEqual(cuts, ["Pinnacle Monk // Mystic Peak", "Arcane Signet"])

    def test_registry_prior_reject_blocks_same_add_cut_signature(self):
        with tempfile.TemporaryDirectory() as tmp:
            registry = Path(tmp) / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "leader_follow_up_probes": [
                            {
                                "swap_or_scope": "+Reprieve; -Avatar's Wrath",
                                "status": "rejected_current_leader_gate",
                                "result": "candidate lost prior gate",
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.merge_registry_prior_results(
                {
                    "enabled": True,
                    "loaded_paths": [],
                    "missing_paths": [],
                    "by_package_key": {},
                    "by_signature": {},
                    "summary": {},
                },
                gate.load_registry_prior_results(registry),
            )
            classification = gate.classify_package_prior_evidence(
                "reprieve_cut_avatar_wrath",
                {"adds": ["Reprieve"], "cuts": ["Avatar's Wrath"]},
                prior_results,
            )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertEqual(classification["matches"][0]["family"], "registry_rejected")

    def test_default_prior_reports_include_rejected_benchmark_gates(self):
        default_names = {path.name for path in gate.DEFAULT_PRIOR_PACKAGE_REPORTS}

        self.assertIn(
            "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json",
            default_names,
        )
        self.assertIn(
            "lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json",
            default_names,
        )
        self.assertIn(
            "lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json",
            default_names,
        )
        self.assertIn(
            "lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json",
            default_names,
        )
        self.assertIn(
            "lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json",
            default_names,
        )
        self.assertIn(
            "lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json",
            default_names,
        )
        self.assertIn(
            "lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json",
            default_names,
        )
        self.assertIn(
            "lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_mana_vault_gate_20260628_v1_20260628_092000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json",
            default_names,
        )
        self.assertIn(
            "lorehold_protection_ready_gate_20260628_v1_20260628_095000.json",
            default_names,
        )
        expected_profiled_history = {
            "lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_20260628_091321.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_witch_confirm_20260628_091458.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v5_20260628_092712.json",
            "lorehold_profiled_cut_family_benchmark_matrix_20260628_v6_20260628_093001.json",
        }
        self.assertTrue(expected_profiled_history.issubset(default_names))

    def test_prior_evidence_blocks_aggregate_matrix_reject(self):
        with tempfile.TemporaryDirectory() as tmp:
            prior = Path(tmp) / "matrix.json"
            prior.write_text(
                json.dumps(
                    {
                        "packages": [
                            {
                                "package_key": "brass_bounty_cut_boros_signet",
                                "family": "spellchain_mana",
                                "adds": ["Brass's Bounty"],
                                "cuts": ["Boros Signet"],
                                "aggregate": {
                                    "decision": "reject_or_rework",
                                    "delta_pp_total": -2.22,
                                },
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.load_prior_package_results([prior])
            classification = gate.classify_package_prior_evidence(
                "brass_bounty_cut_boros_signet",
                gate.PACKAGE_DEFINITIONS["brass_bounty_cut_boros_signet"],
                prior_results,
            )

        self.assertEqual(classification["status"], "blocked_prior_reject")
        self.assertIn("reject_or_rework", classification["reason"])
        self.assertEqual(classification["matches"][0]["delta_pp"], -2.22)

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
                "package_decision_counts": {"not_run_prior_reject_blocked": 1},
                "packages": [
                    {
                        "package_key": "core_challenge_past_over_tragic",
                        "family": "payoff_challenge",
                        "hypothesis": "test",
                        "adds": ["Past in Flames"],
                        "cuts": ["Tragic Arrogance"],
                        "status": "skipped_prior_evidence",
                        "decision": "not_run_prior_reject_blocked",
                        "cut_safety": {"status": "clear"},
                        "prior_evidence": {"status": "blocked_prior_reject"},
                        "candidate_meta": {},
                    }
                ],
            }
        )

        self.assertIn("skipped_prior_evidence", markdown)
        self.assertIn("blocked_prior_reject", markdown)
        self.assertIn("package_decision_counts", markdown)
        self.assertIn("not_run_prior_reject_blocked", markdown)

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
                        "damage_prevention_shield_created": 0,
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
                        "damage_prevention_shield_created": 2,
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
        self.assertEqual(delta["damage_prevention_shield_created"], 2)
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
        self.assertIn("shield +2", gate.strategic_delta_text(payload))
        self.assertIn("ritual +3", gate.strategic_delta_text(payload))
        self.assertIn("tutor +3", gate.strategic_delta_text(payload))
        self.assertIn("random discard +2", gate.strategic_delta_text(payload))
        self.assertIn("hand to top +3", gate.strategic_delta_text(payload))
        self.assertIn("discard-to-top +4", gate.strategic_delta_text(payload))
        self.assertIn("rummage-to-top +3", gate.strategic_delta_text(payload))
        self.assertIn("spell-rummage-to-top +3", gate.strategic_delta_text(payload))

    def test_package_exposure_summary_marks_added_card_used(self):
        payload = {
            "baseline": {
                "games": 3,
                "telemetry": {
                    "card_event_counts": {
                        "spell_cast:Arcane Signet": 2,
                        "cost_paid:Arcane Signet": 2,
                    },
                },
            },
            "candidate": {
                "games": 3,
                "telemetry": {
                    "card_event_counts": {
                        "spell_cast:Mana Vault": 2,
                        "cost_paid:Mana Vault": 2,
                    },
                    "card_strategy_counts": {
                        "cost_paid:Mana Vault": 2,
                    },
                },
            },
        }

        exposure = gate.package_exposure_summary(
            payload,
            adds=["Mana Vault"],
            cuts=["Arcane Signet"],
        )

        self.assertEqual(exposure["status"], "candidate_added_cards_used")
        self.assertFalse(exposure["low_candidate_added_card_use"])
        self.assertEqual(
            exposure["candidate_added_cards"]["cards"][0]["recorded_use_count"],
            4,
        )
        self.assertEqual(
            exposure["baseline_cut_cards"]["cards"][0]["recorded_use_count"],
            4,
        )

    def test_gate_decision_is_inconclusive_when_added_card_never_used(self):
        gate_summary = {
            "baseline": {"wins": 0, "losses": 3, "win_rate": 0.0, "telemetry": {}},
            "candidate": {"wins": 3, "losses": 0, "win_rate": 100.0, "telemetry": {}},
            "delta_pp": 100.0,
        }
        exposure = gate.package_exposure_summary(
            gate_summary,
            adds=["Mana Vault"],
            cuts=["Arcane Signet"],
        )

        self.assertEqual(gate.gate_decision(gate_summary, exposure), "inconclusive_low_exposure")

    def test_package_decision_counts_are_exposure_aware(self):
        package = {
            "package_key": "mana_vault_fast_mana_cut_arcane_signet",
            "status": "gated",
            "gate_summary": {
                "baseline": {"wins": 0, "losses": 3, "win_rate": 0.0, "telemetry": {}},
                "candidate": {"wins": 3, "losses": 0, "win_rate": 100.0, "telemetry": {}},
                "delta_pp": 100.0,
            },
            "exposure_summary": {
                "low_candidate_added_card_use": True,
                "status": "candidate_added_card_low_access",
            },
        }

        counts = gate.package_decision_counts([package])

        self.assertEqual(counts, {"inconclusive_low_exposure": 1})

    def test_gate_decision_marks_forced_access_positive_as_confirmation_signal(self):
        gate_summary = {
            "baseline": {"wins": 0, "losses": 3, "win_rate": 0.0, "telemetry": {}},
            "candidate": {"wins": 1, "losses": 2, "win_rate": 33.33, "telemetry": {}},
            "delta_pp": 33.33,
        }
        exposure = {"low_candidate_added_card_use": False}

        self.assertEqual(
            gate.gate_decision(
                gate_summary,
                exposure,
                forced_access_mode="opening_hand",
            ),
            "forced_access_signal_requires_natural_confirmation",
        )

    def test_forced_access_signal_adds_natural_confirmation_queue_item(self):
        payload = {
            "games_per_opponent": 1,
            "opponent_limit": 3,
            "opponent_seed": 20260626,
            "simulation_seed": 42,
            "forced_access_mode": "opening_hand",
            "packages": [
                {
                    "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                    "family": "fast_mana",
                    "adds": ["Mana Vault"],
                    "cuts": ["Arcane Signet"],
                    "forced_access_mode": "opening_hand",
                    "gate_summary": {
                        "baseline": {"wins": 0, "losses": 3},
                        "candidate": {"wins": 1, "losses": 2},
                        "delta_pp": 33.33,
                    },
                    "exposure_summary": {"low_candidate_added_card_use": False},
                }
            ],
        }

        queue = gate.forced_access_confirmation_queue(payload)

        self.assertEqual(len(queue), 1)
        self.assertEqual(
            queue[0]["decision"],
            "forced_access_signal_requires_natural_confirmation",
        )
        self.assertIn("--forced-access-mode none", queue[0]["suggested_command"])
        self.assertIn("--ignore-prior-results", queue[0]["suggested_command"])

    def test_side_card_exposure_distinguishes_library_only_low_access(self):
        row = {
            "telemetry": {
                "focus_card_game_traces": {
                    "game-1": [
                        {
                            "event": "focus_card_access_snapshot",
                            "data": {
                                "focus_card_zones": {
                                    "Wheel of Fortune": {
                                        "zone": "library",
                                        "library_position": 68,
                                        "library_top_7": False,
                                    }
                                }
                            },
                        }
                    ],
                    "game-2": [
                        {
                            "event": "focus_card_access_snapshot",
                            "data": {
                                "focus_card_zones": {
                                    "Wheel of Fortune": {
                                        "zone": "library",
                                        "library_position": 41,
                                        "library_top_7": False,
                                    }
                                }
                            },
                        }
                    ],
                }
            }
        }

        exposure = gate.side_card_exposure(row, ["Wheel of Fortune"])
        card = exposure["cards"][0]

        self.assertEqual(card["status"], "library_only_not_used")
        self.assertEqual(card["access_profile"]["library_only_games"], 2)
        self.assertEqual(card["access_profile"]["accessed_games"], 0)
        self.assertFalse(exposure["all_cards_accessed"])

    def test_side_card_exposure_flags_accessed_but_not_used(self):
        row = {
            "telemetry": {
                "focus_card_game_traces": {
                    "game-1": [
                        {
                            "event": "focus_card_access_snapshot",
                            "data": {
                                "phase": "opening_keep",
                                "focus_card_zones": {
                                    "Silence": {
                                        "zone": "hand",
                                    }
                                },
                                "hand_focus": ["Silence"],
                            },
                        }
                    ]
                }
            }
        }

        exposure = gate.side_card_exposure(row, ["Silence"])
        package = gate.package_exposure_summary(
            {"candidate": row, "baseline": {"telemetry": {}}},
            adds=["Silence"],
            cuts=["Avatar's Wrath"],
        )

        self.assertEqual(exposure["cards"][0]["status"], "accessed_not_used")
        self.assertEqual(exposure["cards"][0]["access_profile"]["accessed_games"], 1)
        self.assertTrue(exposure["all_cards_accessed"])
        self.assertEqual(package["status"], "candidate_added_cards_accessed_not_used")
        self.assertEqual(package["next_step"], "inspect_play_heuristic_or_runtime_for_accessed_card")

    def test_compact_gate_telemetry_preserves_access_summary_without_full_traces(self):
        telemetry = {
            "focus_card_game_traces": {
                "game-1": [
                    {
                        "event": "focus_card_access_snapshot",
                        "data": {
                            "focus_card_zones": {
                                "Valakut Awakening // Valakut Stoneforge": {
                                    "zone": "library",
                                    "library_position": 5,
                                    "library_top_7": True,
                                }
                            }
                        },
                    }
                ]
            }
        }

        compact = gate.compact_gate_telemetry(telemetry)
        profile = gate.focus_card_access_profile(
            compact,
            "Valakut Awakening // Valakut Stoneforge",
        )

        self.assertNotIn("focus_card_game_traces", compact)
        self.assertEqual(profile["near_access_games"], 1)
        self.assertEqual(profile["dominant_zone"], "library")

    def test_prior_evidence_reject_is_downgraded_when_exposure_shows_no_use(self):
        with tempfile.TemporaryDirectory() as tmp:
            prior = Path(tmp) / "prior.json"
            prior.write_text(
                json.dumps(
                    {
                        "packages": [
                            {
                                "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                                "adds": ["Mana Vault"],
                                "cuts": ["Arcane Signet"],
                                "decision": "reject_or_rework",
                                "gate_summary": {
                                    "baseline": {"wins": 3, "losses": 0, "win_rate": 100.0},
                                    "candidate": {"wins": 0, "losses": 3, "win_rate": 0.0},
                                    "delta_pp": -100.0,
                                },
                                "exposure_summary": {
                                    "low_candidate_added_card_use": True,
                                    "status": "candidate_added_card_low_exposure",
                                    "candidate_added_cards": {
                                        "cards": [
                                            {
                                                "card_name": "Mana Vault",
                                                "recorded_use_count": 0,
                                            }
                                        ]
                                    },
                                },
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            prior_results = gate.load_prior_package_results([prior])
            classification = gate.classify_package_prior_evidence(
                "mana_vault_fast_mana_cut_arcane_signet",
                gate.PACKAGE_DEFINITIONS["mana_vault_fast_mana_cut_arcane_signet"],
                prior_results,
            )

        self.assertEqual(classification["status"], "seen_no_blocker")
        self.assertEqual(
            classification["matches"][0]["decision"],
            "inconclusive_low_exposure",
        )

    def test_runtime_package_rules_deprecate_review_only_shadows(self):
        with tempfile.TemporaryDirectory() as tmp:
            proposals = Path(tmp) / "proposals.json"
            proposals.write_text(
                json.dumps(
                    {
                        "proposals": [
                            {
                                "card_name": "Twinflame Tyrant",
                                "effect_json": {
                                    "effect": "damage_modifier",
                                    "battle_model_scope": (
                                        "controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1"
                                    ),
                                    "damage_modifier_applies_to": "sources_you_control",
                                    "damage_modifier_targets": ["opponents", "opponent_permanents"],
                                    "damage_modifier_duration": "while_on_battlefield",
                                    "damage_multiplier": 2,
                                },
                                "deck_role_json": {
                                    "category": "wincon",
                                    "effect": "damage_modifier",
                                },
                                "logical_rule_key": "battle_rule_v1:pg245_twinflame",
                                "source": "curated",
                                "confidence": 0.94,
                                "review_status": "verified",
                                "execution_status": "auto",
                                "oracle_hash": "e4ca0585f743b1c34c36649bfbb1fff6",
                                "shadow_handling": "deprecate_nonmatching_rows",
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            conn = sqlite3.connect(":memory:")
            conn.row_factory = sqlite3.Row
            gate.battle_rule_registry.ensure_battle_card_rules(conn)
            gate.battle_rule_registry.upsert_battle_card_rule(
                conn,
                "Twinflame Tyrant",
                {"effect": "finisher", "cmc": 5},
                source="generated",
                confidence=0.3,
                review_status="needs_review",
                execution_status="review_only",
                deck_role_json={"category": "wincon", "effect": "finisher"},
                logical_rule_key_value="battle_rule_v1:old_generated",
            )

            counts = gate.upsert_runtime_package_rules_for_cards(
                conn,
                ["Twinflame Tyrant"],
                proposals_path=proposals,
            )

            self.assertEqual(counts["Twinflame Tyrant"]["upserted"], 1)
            self.assertEqual(counts["Twinflame Tyrant"]["shadow_deprecated"], 1)
            rows = conn.execute(
                """
                SELECT logical_rule_key, review_status, execution_status, oracle_hash
                FROM battle_card_rules
                WHERE normalized_name='twinflame tyrant'
                ORDER BY logical_rule_key
                """
            ).fetchall()
            by_key = {row["logical_rule_key"]: dict(row) for row in rows}
            self.assertEqual(by_key["battle_rule_v1:old_generated"]["review_status"], "deprecated")
            self.assertEqual(by_key["battle_rule_v1:old_generated"]["execution_status"], "disabled")
            self.assertEqual(by_key["battle_rule_v1:pg245_twinflame"]["review_status"], "verified")
            self.assertEqual(by_key["battle_rule_v1:pg245_twinflame"]["execution_status"], "auto")
            self.assertEqual(
                by_key["battle_rule_v1:pg245_twinflame"]["oracle_hash"],
                "e4ca0585f743b1c34c36649bfbb1fff6",
            )
            active_rules = gate.active_rules_for_card(conn, "Twinflame Tyrant")
            self.assertEqual([rule["logical_rule_key"] for rule in active_rules], ["battle_rule_v1:pg245_twinflame"])

    def test_runtime_package_upsert_accepts_multiple_proposal_reports(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            unrelated = tmp / "unrelated.json"
            hidden = tmp / "hidden.json"
            unrelated.write_text(
                json.dumps(
                    {
                        "proposals": [
                            {
                                "card_name": "Brainstone",
                                "effect_json": {"effect": "topdeck_manipulation"},
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            hidden.write_text(
                json.dumps(
                    {
                        "proposals": [
                            {
                                "card_name": "Hidden Retreat",
                                "effect_json": {
                                    "effect": "damage_prevention_shield",
                                    "battle_model_scope": (
                                        "activated_put_card_from_hand_on_top_library_"
                                        "prevent_damage_from_target_instant_or_sorcery_spell_v1"
                                    ),
                                },
                                "deck_role_json": {
                                    "category": "protection",
                                    "effect": "damage_prevention_shield",
                                },
                                "logical_rule_key": "battle_rule_v1:hidden_retreat_test",
                                "source": "curated",
                                "confidence": 0.94,
                                "review_status": "verified",
                                "execution_status": "auto",
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            conn = sqlite3.connect(":memory:")
            conn.row_factory = sqlite3.Row

            counts = gate.upsert_runtime_package_rules_for_cards(
                conn,
                ["Hidden Retreat"],
                proposals_path=[unrelated, hidden],
            )

            self.assertEqual(counts["Hidden Retreat"]["upserted"], 1)
            active_rules = gate.active_rules_for_card(conn, "Hidden Retreat")
            self.assertEqual(
                [rule["logical_rule_key"] for rule in active_rules],
                ["battle_rule_v1:hidden_retreat_test"],
            )


if __name__ == "__main__":
    unittest.main()
