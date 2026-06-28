import json
import tempfile
import unittest
from pathlib import Path

import lorehold_strategy_learning_audit as audit


def package_payload(seed, package_key, baseline_wins, baseline_losses, candidate_wins, candidate_losses, delta_pp):
    return {
        "simulation_seed": seed,
        "packages": [
            {
                "package_key": package_key,
                "family": "topdeck_freecast",
                "adds": ["Galvanoth"],
                "cuts": ["Bender's Waterskin"],
                "gate_summary": {
                    "baseline": {
                        "wins": baseline_wins,
                        "losses": baseline_losses,
                        "telemetry": {
                            "event_counts": {
                                "ritual_mana_added": 1,
                            },
                            "strategic_event_counts": {
                                "miracle_cast": 10,
                                "topdeck_manipulation_activated": 5,
                                "spell_cast_mana_trigger": 0,
                                "birgi_spell_cast_mana": 0,
                                "hand_to_topdeck_activation": 0,
                                "squee_to_graveyard": 2,
                                "squee_upkeep_return": 1,
                            }
                        },
                    },
                    "candidate": {
                        "wins": candidate_wins,
                        "losses": candidate_losses,
                        "telemetry": {
                            "event_counts": {
                                "ritual_mana_added": 4,
                            },
                            "strategic_event_counts": {
                                "miracle_cast": 14,
                                "topdeck_manipulation_activated": 9,
                                "spell_cast_mana_trigger": 3,
                                "birgi_spell_cast_mana": 3,
                                "hand_to_topdeck_activation": 1,
                                "squee_to_graveyard": 2,
                                "squee_upkeep_return": 1,
                            }
                        },
                    },
                    "delta_pp": delta_pp,
                },
            }
        ],
    }


def safe_queue_payload():
    return {
        "packages": [
            {
                "package_key": "overmaster_protect_draw_cut_tibalts_trickery",
                "family": "spell_protection",
                "adds": ["Overmaster"],
                "cuts": ["Tibalt's Trickery"],
                "status": "gated",
                "cut_safety": {"status": "clear"},
                "prior_evidence": {"status": "clear"},
                "candidate_meta": {
                    "added_rule_counts": {"Overmaster": 1},
                    "miracle_core_cuts": [],
                },
                "gate_summary": {
                    "baseline": {
                        "wins": 3,
                        "losses": 0,
                        "stalls": 0,
                        "win_rate": 100.0,
                        "telemetry": {
                            "strategic_event_counts": {
                                "lorehold_spell_cast": 51,
                                "miracle_cast": 14,
                            }
                        },
                    },
                    "candidate": {
                        "wins": 2,
                        "losses": 1,
                        "stalls": 0,
                        "win_rate": 66.67,
                        "telemetry": {
                            "event_counts": {
                                "ritual_mana_added": 3,
                            },
                            "strategic_event_counts": {
                                "lorehold_spell_cast": 29,
                                "miracle_cast": 7,
                            }
                        },
                    },
                    "delta_pp": -33.33,
                },
            },
            {
                "package_key": "birgi_spellchain_cut_jeskas_will",
                "family": "spellchain_mana",
                "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                "cuts": ["Jeska's Will"],
                "status": "gated",
                "cut_safety": {"status": "clear"},
                "prior_evidence": {"status": "clear"},
                "candidate_meta": {
                    "added_rule_counts": {"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1},
                    "miracle_core_cuts": [],
                },
                "gate_summary": {
                    "baseline": {
                        "wins": 3,
                        "losses": 0,
                        "stalls": 0,
                        "win_rate": 100.0,
                        "telemetry": {
                            "strategic_event_counts": {
                                "birgi_spell_cast_mana": 0,
                                "lorehold_spell_cast": 51,
                                "miracle_cast": 14,
                            }
                        },
                    },
                    "candidate": {
                        "wins": 0,
                        "losses": 3,
                        "stalls": 0,
                        "win_rate": 0.0,
                        "telemetry": {
                            "strategic_event_counts": {
                                "birgi_spell_cast_mana": 1,
                                "lorehold_spell_cast": 13,
                                "miracle_cast": 1,
                            }
                        },
                    },
                    "delta_pp": -100.0,
                },
            },
        ]
    }


class LoreholdStrategyLearningAuditTest(unittest.TestCase):
    def test_card_status_separates_materialization_gap_from_missing_model(self):
        card = {
            "card_name": "Molecule Man",
            "primary_role": "draw",
            "battle_rule_keys": [],
        }

        self.assertEqual(
            audit.card_status(card, {"decision": "deck_rule_materialization_gap"}),
            "materialization_gap_ready_rule",
        )
        self.assertEqual(
            audit.card_status(card, {"decision": "missing_battle_rule_model"}),
            "missing_battle_rule_model",
        )
        self.assertEqual(
            audit.card_status(
                {"card_name": "Thor, God of Thunder", "primary_role": "removal", "battle_rule_keys": []},
                {"decision": "missing_battle_rule_model"},
                {"card": "Thor, God of Thunder", "decision": "local_reviewed_runtime_rule_added_pending_durable_pg_sync"},
            ),
            "local_runtime_rule_added_pending_sync",
        )

    def test_card_decision_manifest_marks_core_flex_and_probation_slots(self):
        deck = {
            "cards": [
                {
                    "card_name": "Lorehold, the Historian",
                    "primary_role": "engine",
                    "battle_rule_keys": ["rule"],
                    "tags": ["topdeck_miracle_setup"],
                    "quantity": 1,
                    "cmc": 5,
                    "type_line": "Legendary Creature",
                },
                {
                    "card_name": "Squee, Goblin Nabob",
                    "primary_role": "wincon",
                    "battle_rule_keys": [],
                    "tags": ["graveyard_recursion", "wincon"],
                    "quantity": 1,
                    "cmc": 3,
                    "type_line": "Legendary Creature",
                },
                {
                    "card_name": "Victory Chimes",
                    "primary_role": "ramp",
                    "battle_rule_keys": ["rule"],
                    "tags": ["ramp"],
                    "quantity": 1,
                    "cmc": 3,
                    "type_line": "Artifact",
                },
                {
                    "card_name": "Command Tower",
                    "primary_role": "land",
                    "battle_rule_keys": [],
                    "tags": ["land"],
                    "quantity": 1,
                    "cmc": 0,
                    "type_line": "Land",
                },
            ]
        }

        manifest = audit.build_card_decision_manifest(
            deck,
            {},
            {},
            {
                "rows": [
                    {
                        "materialized_squee": {
                            "card_name": "Squee, Goblin Nabob",
                            "battle_rule_count": 1,
                        }
                    }
                ]
            },
        )
        by_name = {row["card_name"]: row for row in manifest["cards"]}

        self.assertEqual(by_name["Lorehold, the Historian"]["decision"], "locked_core")
        self.assertEqual(by_name["Squee, Goblin Nabob"]["decision"], "probation_engine")
        self.assertEqual(by_name["Squee, Goblin Nabob"]["status"], "materialized_rule_in_equal_gate_candidate")
        self.assertEqual(by_name["Victory Chimes"]["decision"], "flex_cut_tested_negative")
        self.assertEqual(by_name["Command Tower"]["decision"], "mana_base_core")
        self.assertEqual(manifest["summary"]["decision_counts"]["probation_engine"], 1)

    def test_post_squee_gate_keeps_positive_aggregate_on_probation_when_seed_42_breaks(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            paths = []
            for index, payload in enumerate(
                [
                    package_payload(42, "galvanoth_topdeck_freecast", 8, 1, 4, 5, -44.45),
                    package_payload(7, "galvanoth_topdeck_freecast", 0, 9, 1, 8, 11.11),
                    package_payload(20260625, "galvanoth_topdeck_freecast", 0, 9, 4, 5, 44.44),
                ]
            ):
                path = tmp_path / f"gate_{index}.json"
                path.write_text(json.dumps(payload), encoding="utf-8")
                paths.append(path)

            result = audit.aggregate_post_squee_package_gates(paths)

        rows = result["rows"]
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(row["candidate_wins"], 9)
        self.assertEqual(row["baseline_wins"], 8)
        self.assertEqual(row["strong_seed_delta_pp"], -44.45)
        self.assertEqual(row["decision"], "probation_deeper_gate_only")
        self.assertEqual(row["strategic_delta"]["miracle_cast"], 12)
        self.assertEqual(row["strategic_delta"]["spell_cast_mana_trigger"], 9)
        self.assertEqual(row["strategic_delta"]["birgi_spell_cast_mana"], 9)
        self.assertEqual(row["strategic_delta"]["ritual_mana_added"], 9)
        self.assertEqual(row["strategic_delta"]["hand_to_topdeck_activation"], 3)

    def test_cut_safety_manifest_blocks_collapsed_seed_and_flags_risky_cut(self):
        manifest = audit.build_cut_safety_manifest(
            {
                "rows": [
                    {
                        "package_key": "boros_charm_pressure_cut_fated",
                        "family": "pressure_absorption",
                        "adds": ["Boros Charm"],
                        "cuts": ["Fated Clash"],
                        "baseline_wins": 8,
                        "baseline_losses": 1,
                        "candidate_wins": 0,
                        "candidate_losses": 9,
                        "delta_pp": -88.89,
                        "strong_seed_delta_pp": -88.89,
                        "decision": "reject_or_rework",
                    },
                    {
                        "package_key": "primal_amulet_spell_engine",
                        "family": "topdeck_freecast",
                        "adds": ["Primal Amulet"],
                        "cuts": ["Bender's Waterskin"],
                        "baseline_wins": 8,
                        "baseline_losses": 19,
                        "candidate_wins": 9,
                        "candidate_losses": 18,
                        "delta_pp": 3.7,
                        "strong_seed_delta_pp": -44.45,
                        "decision": "probation_deeper_gate_only",
                    },
                ]
            },
            {
                "cards": [
                    {
                        "card_name": "Fated Clash",
                        "decision": "core_support",
                        "package_lane": "interaction",
                        "effective_role": "removal",
                        "status": "ready",
                    },
                    {
                        "card_name": "Bender's Waterskin",
                        "decision": "engine_flex",
                        "package_lane": "topdeck_setup",
                        "effective_role": "topdeck_setup",
                        "status": "ready",
                    },
                    {
                        "card_name": "Manual Flex",
                        "decision": "manual_review",
                        "package_lane": "support",
                        "effective_role": "support",
                        "status": "ready",
                    },
                ]
            },
        )

        by_name = {row["card_name"]: row for row in manifest["cuts"]}
        self.assertEqual(by_name["Fated Clash"]["status"], "locked_do_not_cut")
        self.assertEqual(by_name["Bender's Waterskin"]["status"], "risky_cut_only_same_lane")
        self.assertEqual(manifest["summary"]["status_counts"]["locked_do_not_cut"], 1)
        self.assertEqual(manifest["summary"]["status_counts"]["risky_cut_only_same_lane"], 1)
        self.assertEqual(manifest["summary"]["blocked_cut_count"], 2)
        self.assertEqual(
            [row["card_name"] for row in manifest["untested_flex_pool"]],
            ["Manual Flex"],
        )

    def test_safe_package_gate_classifies_negative_smoke_without_promotion(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "safe_queue.json"
            path.write_text(json.dumps(safe_queue_payload()), encoding="utf-8")

            result = audit.aggregate_safe_package_gates([path])

        self.assertEqual(result["summary"]["package_count"], 2)
        self.assertEqual(
            result["summary"]["decision_counts"]["watch_only_needs_stronger_justification"],
            1,
        )
        self.assertEqual(
            result["summary"]["decision_counts"]["smoke_negative_do_not_promote"],
            1,
        )
        self.assertEqual(
            result["summary"]["best_package_key"],
            "overmaster_protect_draw_cut_tibalts_trickery",
        )
        by_key = {row["package_key"]: row for row in result["rows"]}
        self.assertEqual(
            by_key["overmaster_protect_draw_cut_tibalts_trickery"]["decision"],
            "watch_only_needs_stronger_justification",
        )
        self.assertEqual(
            by_key["birgi_spellchain_cut_jeskas_will"]["strategic_delta"]["birgi_spell_cast_mana"],
            1,
        )
        self.assertEqual(
            by_key["birgi_spellchain_cut_jeskas_will"]["strategic_delta"]["miracle_cast"],
            -13,
        )

    def test_runtime_package_readiness_keeps_pg_blocked_cards_in_hypothesis_pool(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            proposal_path = tmp_path / "proposals.json"
            manifest_path = tmp_path / "manifest.json"
            blocker_path = tmp_path / "blocked.json"
            readiness_path = tmp_path / "runtime_candidate_readiness.json"
            proposal_path.write_text(
                json.dumps(
                    {
                        "proposals": [
                            {
                                "card_name": "Twinflame Tyrant",
                                "family_id": "static_damage_modifier",
                                "effect": "damage_modifier",
                                "battle_model_scope": "controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1",
                                "proposal_status": "batch_pg_candidate_after_precheck",
                                "safe_for_batch_pg_package": True,
                                "oracle_hash": "hash",
                                "logical_rule_key": "battle_rule_v1:hash",
                                "deck_role_json": {"category": "wincon"},
                                "effect_json": {"effect": "damage_modifier"},
                            },
                            {
                                "card_name": "Manual Card",
                                "family_id": "manual_model",
                                "safe_for_batch_pg_package": False,
                            },
                        ]
                    }
                ),
                encoding="utf-8",
            )
            manifest_path.write_text(
                json.dumps(
                    {
                        "deploy_id": "PG245",
                        "slug": "lorehold_topdeck_damage_runtime",
                        "status": "prepared_read_only_pending_apply_approval",
                        "selected_count": 1,
                        "selected_card_names": ["Twinflame Tyrant"],
                        "family_counts": {"static_damage_modifier": 1},
                    }
                ),
                encoding="utf-8",
            )
            blocker_path.write_text(
                json.dumps(
                    {
                        "deploy_id": "PG245",
                        "slug": "lorehold_topdeck_damage_runtime",
                        "status": "postgres_precheck_blocked_connection_closed",
                        "blocked_step": "precheck",
                        "sanitized_error": "server closed the connection unexpectedly before precheck execution",
                        "selected_cards": ["Twinflame Tyrant"],
                    }
                ),
                encoding="utf-8",
            )
            readiness_path.write_text(
                json.dumps(
                    {
                        "summary": {
                            "card_count": 4,
                            "status_counts": {
                                "pg_precheck_blocked": 1,
                                "pg_package_prepared_pending_apply_approval": 1,
                                "split_scope_review_required": 1,
                                "manual_mapper_required": 1,
                            },
                            "promotion_lane_counts": {
                                "batch_metadata_candidate_requires_pg_precheck": 1,
                                "access_density_candidate": 1,
                                "split_family_scope_review_required": 1,
                                "mapper_metadata_or_test_scenario_required": 1,
                            },
                            "pg_precheck_blocked_count": 1,
                            "pg_package_prepared_pending_apply_approval_count": 1,
                            "split_scope_review_required_count": 1,
                            "manual_mapper_required_count": 1,
                            "cut_specific_negative_count": 1,
                            "recommended_next_action": "rerun_pg245_precheck_then_sync_or_split_scope_runtime_families",
                        },
                        "cards": [
                            {
                                "card_name": "Twinflame Tyrant",
                                "status": "pg_precheck_blocked",
                                "family_id": "static_damage_modifier",
                                "promotion_lane": "batch_metadata_candidate_requires_pg_precheck",
                                "effect": "damage_modifier",
                                "battle_model_scope": "damage_doubled_v1",
                                "cut_specific_negative_count": 1,
                                "card_global_reject": False,
                                "next_action": "Rerun PostgreSQL precheck.",
                                "pg_packages": [{}],
                                "pg_precheck_blockers": [{}],
                            },
                            {
                                "card_name": "Hidden Retreat",
                                "status": "pg_package_prepared_pending_apply_approval",
                                "family_id": "access_density",
                                "promotion_lane": "access_density_candidate",
                                "cut_specific_negative_count": 0,
                                "card_global_reject": False,
                                "next_action": "Apply after approval.",
                                "pg_packages": [{}],
                            },
                            {
                                "card_name": "Boros Reckoner",
                                "status": "split_scope_review_required",
                                "family_id": "targeted_interaction",
                                "promotion_lane": "split_family_scope_review_required",
                                "cut_specific_negative_count": 0,
                                "card_global_reject": False,
                                "next_action": "Split the family scope.",
                            },
                            {
                                "card_name": "Manual Card",
                                "status": "manual_mapper_required",
                                "family_id": "manual_model",
                                "promotion_lane": "mapper_metadata_or_test_scenario_required",
                                "cut_specific_negative_count": 0,
                                "card_global_reject": False,
                                "next_action": "Add mapper metadata.",
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )

            result = audit.aggregate_runtime_package_readiness(
                proposal_paths=[proposal_path],
                manifest_paths=[manifest_path],
                blocker_paths=[blocker_path],
                candidate_readiness_path=readiness_path,
            )

        self.assertEqual(result["summary"]["card_count"], 1)
        self.assertEqual(result["summary"]["blocked_card_count"], 1)
        self.assertEqual(result["summary"]["readiness_counts"]["runtime_ready_pg_precheck_blocked"], 1)
        self.assertEqual(result["summary"]["candidate_readiness_card_count"], 4)
        self.assertEqual(result["summary"]["candidate_readiness_status_counts"]["pg_precheck_blocked"], 1)
        self.assertEqual(result["summary"]["pg_package_prepared_pending_apply_approval_count"], 1)
        self.assertEqual(result["summary"]["split_scope_review_required_count"], 1)
        self.assertEqual(result["summary"]["manual_mapper_required_count"], 1)
        self.assertEqual(result["summary"]["cut_specific_negative_count"], 1)
        card = result["cards"][0]
        self.assertEqual(card["card_name"], "Twinflame Tyrant")
        self.assertEqual(card["family_id"], "static_damage_modifier")
        self.assertEqual(card["readiness"], "runtime_ready_pg_precheck_blocked")
        self.assertEqual(card["package_manifests"][0]["deploy_id"], "PG245")
        self.assertEqual(card["blockers"][0]["blocked_step"], "precheck")
        by_name = {row["card_name"]: row for row in result["candidate_readiness_cards"]}
        self.assertEqual(by_name["Hidden Retreat"]["status"], "pg_package_prepared_pending_apply_approval")
        self.assertFalse(by_name["Twinflame Tyrant"]["card_global_reject"])

    def test_strategy_dependency_map_turns_gates_into_next_hypothesis_contract(self):
        result = audit.build_strategy_dependency_map(
            squee_gates={
                "summary": {
                    "candidate_607_squee": {
                        "games": 90,
                        "wins": 24,
                        "losses": 66,
                        "stalls": 0,
                        "win_rate": 26.67,
                        "strategic_events": {"squee_upkeep_return": 12},
                    },
                    "deck_607": {
                        "games": 90,
                        "wins": 21,
                        "losses": 69,
                        "stalls": 0,
                        "win_rate": 23.33,
                    },
                    "deck_6": {
                        "games": 90,
                        "wins": 16,
                        "losses": 74,
                        "stalls": 0,
                        "win_rate": 17.78,
                    },
                },
                "rows": [
                    {
                        "seed": 42,
                        "deck_key": "candidate_607_squee",
                        "wins": 8,
                        "losses": 1,
                        "strategic_events": {"miracle_cast": 33, "topdeck_manipulation_activated": 30},
                    },
                    {
                        "seed": 7,
                        "deck_key": "candidate_607_squee",
                        "wins": 0,
                        "losses": 9,
                        "strategic_events": {"miracle_cast": 4, "topdeck_manipulation_activated": 2},
                    },
                ],
            },
            matrix_ranked=[
                {"rank": 1, "deck_key": "deck_607", "deck_name": "607", "land_count": 34},
                {"rank": 2, "deck_key": "deck_615", "deck_name": "615", "land_count": 34},
                {"rank": 3, "deck_key": "deck_614", "deck_name": "614", "land_count": 33},
                {"rank": 4, "deck_key": "deck_612", "deck_name": "612", "land_count": 27},
            ],
            post_squee_package_gates={
                "rows": [
                    {
                        "package_key": "galvanoth_topdeck_freecast",
                        "family": "topdeck_freecast",
                        "adds": ["Galvanoth"],
                        "cuts": ["Bender's Waterskin"],
                        "delta_pp": 3.7,
                        "strong_seed_delta_pp": -44.45,
                        "decision": "probation_deeper_gate_only",
                    },
                    {
                        "package_key": "birgi_spellchain_cut_squelcher",
                        "family": "spellchain_mana",
                        "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                        "cuts": ["Hexing Squelcher"],
                        "delta_pp": -3.7,
                        "strong_seed_delta_pp": -55.56,
                        "decision": "reject_or_rework",
                    },
                ]
            },
            safe_package_gates={
                "rows": [
                    {
                        "package_key": "overmaster_protect_draw_cut_tibalts_trickery",
                        "family": "spell_protection",
                        "adds": ["Overmaster"],
                        "cuts": ["Tibalt's Trickery"],
                        "delta_pp": -33.33,
                        "decision": "watch_only_needs_stronger_justification",
                    },
                    {
                        "package_key": "seething_song_ritual_cut_victory_chimes",
                        "family": "spellchain_mana",
                        "adds": ["Seething Song"],
                        "cuts": ["Victory Chimes"],
                        "delta_pp": -100.0,
                        "decision": "smoke_negative_do_not_promote",
                    },
                ]
            },
            library_leng_telemetry_gates={
                "rows": [
                    {
                        "seed": 42,
                        "discard_to_top_replacement": 30,
                        "topdeck_manipulation_activated": 30,
                        "miracle_cast": 33,
                    },
                    {
                        "seed": 7,
                        "discard_to_top_replacement": 0,
                        "topdeck_manipulation_activated": 2,
                        "miracle_cast": 4,
                    },
                ]
            },
            loss_failure_classifier={
                "summary_rows": [
                    {
                        "package_key": "baseline_squee_champion",
                        "seed": 7,
                        "flag_counts": {"combat_pressure_death": 9},
                    }
                ]
            },
            cut_safety_manifest={
                "cuts": [
                    {
                        "card_name": "Fated Clash",
                        "status": "locked_do_not_cut",
                        "current_lane": "interaction",
                        "worst_strong_seed_delta_pp": -88.89,
                        "reason": "collapsed strong seed",
                    },
                    {
                        "card_name": "Bender's Waterskin",
                        "status": "risky_cut_only_same_lane",
                        "current_lane": "topdeck_miracle_setup",
                        "best_delta_pp": 3.7,
                        "worst_strong_seed_delta_pp": -44.45,
                        "reason": "aggregate upside but strong seed risk",
                    },
                ],
                "untested_flex_pool": [{"card_name": "Manual Flex"}],
            },
        )

        self.assertEqual(result["current_benchmark"]["champion"]["deck_key"], "candidate_607_squee")
        self.assertEqual(result["current_benchmark"]["champion"]["record"], "24-66-0")
        locked_names = [row["card_name"] for row in result["cut_guardrails"]["locked_or_protected"]]
        risky_names = [row["card_name"] for row in result["cut_guardrails"]["risky_same_lane_only"]]
        self.assertEqual(locked_names, ["Fated Clash"])
        self.assertEqual(risky_names, ["Bender's Waterskin"])
        probation_keys = [
            row["package_key"]
            for row in result["package_learning"]["post_squee"]["probation_or_watch"]
        ]
        self.assertEqual(probation_keys, ["galvanoth_topdeck_freecast"])
        self.assertEqual(
            result["package_learning"]["safe_queue_watch"][0]["package_key"],
            "overmaster_protect_draw_cut_tibalts_trickery",
        )
        actions = {row["deck_key"]: row["action"] for row in result["variant_import_contract"]}
        self.assertEqual(actions["deck_607"], "baseline_shell")
        self.assertEqual(actions["deck_615"], "extract_controlled_packages_only")
        self.assertEqual(actions["deck_614"], "extract_controlled_packages_only")
        self.assertEqual(actions["deck_612"], "do_not_import_full_list")
        self.assertIn(
            "candidate cuts a locked/protected card without same-lane proof",
            result["next_hypothesis_contract"]["hard_reject_if"],
        )


if __name__ == "__main__":
    unittest.main()
