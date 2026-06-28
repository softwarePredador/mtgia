from pathlib import Path

import lorehold_next_action_planner as planner


def test_defaults_use_current_cut_models():
    assert planner.DEFAULT_TUTOR_CUT_MODEL_REPORTS[0].name == "lorehold_tutor_cut_model_20260628_v2_current_miner.json"
    assert planner.DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS[0].name == "lorehold_hand_filter_cut_model_20260628_v4_current_miner.json"


def miner_report():
    return {
        "summary": {
            "blocked_runtime_rule_gap_count": 2,
            "candidate_status_counts": {
                "blocked_runtime_rule_gap": 2,
                "high_frequency_runtime_ready_unexplored": 4,
            },
            "pairing_status_counts": {
                "blocked_no_safe_cut_in_lane": 2,
                "manual_cut_review_required": 1,
                "needs_lane_model_before_gate": 2,
            },
        },
        "top_variant_candidates": [
            {
                "card_name": "Apex of Power",
                "status": "high_frequency_runtime_ready_unexplored",
                "score": 92,
                "lane": "hand_filter",
            },
            {
                "card_name": "Gamble",
                "status": "high_frequency_runtime_ready_unexplored",
                "score": 74,
                "lane": "contextual",
            },
            {
                "card_name": "Needs Runtime",
                "status": "blocked_runtime_rule_gap",
                "score": 40,
                "lane": "finisher_or_big_spell",
            },
        ],
        "pairing_hypotheses": [
            {
                "candidate": "Enlightened Tutor",
                "status": "needs_lane_model_before_gate",
                "lane": "contextual",
                "candidate_score": 84,
                "cut_options": [],
            },
            {
                "candidate": "Gamble",
                "status": "needs_lane_model_before_gate",
                "lane": "contextual",
                "candidate_score": 74,
                "cut_options": [],
            },
            {
                "candidate": "Apex of Power",
                "status": "blocked_no_safe_cut_in_lane",
                "lane": "hand_filter",
                "candidate_score": 92,
                "cut_options": [
                    {
                        "card_name": "Artist's Talent",
                        "gate_readiness": "protected_same_lane_benchmark_required",
                        "status": "requires_same_lane_gate",
                        "lane": "hand_filter",
                    }
                ],
            },
            {
                "candidate": "Volcanic Vision",
                "status": "manual_cut_review_required",
                "lane": "graveyard_recursion",
                "candidate_score": 72,
                "cut_options": [
                    {
                        "card_name": "Squee, Goblin Nabob",
                        "gate_readiness": "manual_cut_review_required",
                        "status": "manual_review_needed",
                        "lane": "graveyard_recursion",
                    }
                ],
            },
            {
                "candidate": "Plateau",
                "status": "blocked_no_safe_cut_in_lane",
                "lane": "mana_base",
                "candidate_score": 94,
                "cut_options": [
                    {
                        "card_name": "Ancient Tomb",
                        "gate_readiness": "blocked_cut_contract",
                        "status": "blocked_core_cut",
                        "lane": "mana_base",
                    }
                ],
            },
        ],
        "negative_exact_packages": [
            {
                "package_key": "austere_command_wipe_over_emeria_tradeoff",
                "adds": ["Austere Command"],
                "cuts": ["Emeria's Call // Emeria, Shattered Skyclave"],
            }
        ],
    }


def manual_review():
    return {
        "summary": {"automatic_gate_ready_count": 0},
        "contextual_lane_reviews": [
            {
                "candidate": "Gamble",
                "decision": "tutor_lane_probation_needs_seed_safe_cut",
                "recommended_cut_search": "Do not use Thor.",
                "prior_evidence": [{"package_key": "gamble_access_cut_thor"}],
            },
            {
                "candidate": "Enlightened Tutor",
                "decision": "tutor_lane_probation_needs_seed_safe_cut",
                "recommended_cut_search": "Search artifact/enchantment access cuts.",
                "prior_evidence": [{"package_key": "enlightened_engine_access_cut_thor"}],
            },
        ],
        "manual_cut_reviews": [
            {
                "candidate": "Volcanic Vision",
                "cut": "Squee, Goblin Nabob",
                "decision": "do_not_cut_current_champion_engine",
                "gate_action": "blocked",
                "reasons": ["Squee is the current champion's probation recursion engine."],
            }
        ],
    }


def manual_review_with_cut_evidence():
    payload = manual_review()
    payload["cut_evidence_expansion"] = {
        "summary": {
            "model_cut_exposure_count": 2,
            "status_counts": {"needs_exposure_before_cut": 2},
            "recommended_action_counts": {"model_cut_exposure": 2},
        },
        "top_exposure_candidates": [
            {
                "card_name": "Winds of Abandon",
                "status": "needs_exposure_before_cut",
                "recommended_action": "model_cut_exposure",
                "lorehold_variant_presence": {"deck_count": 1, "deck_ids": [607]},
                "reasons": ["No explicit cut-safety row exists yet."],
            },
            {
                "card_name": "Stroke of Midnight",
                "status": "needs_exposure_before_cut",
                "recommended_action": "model_cut_exposure",
                "lorehold_variant_presence": {"deck_count": 3, "deck_ids": [607, 608, 609]},
                "reasons": ["No explicit cut-safety row exists yet."],
            },
        ],
    }
    return payload


def manual_review_with_profiled_cut_evidence():
    payload = manual_review()
    payload["cut_evidence_expansion"] = {
        "summary": {
            "model_cut_exposure_count": 0,
            "manual_same_lane_only_count": 2,
            "status_counts": {
                "measured_cut_exposure_needs_same_lane_benchmark": 2,
                "measured_high_cut_exposure": 1,
            },
            "recommended_action_counts": {
                "blocked": 1,
                "manual_same_lane_only": 2,
            },
        },
        "top_exposure_candidates": [],
        "top_same_lane_candidates": [
            {
                "card_name": "Winds of Abandon",
                "status": "measured_cut_exposure_needs_same_lane_benchmark",
                "recommended_action": "manual_same_lane_only",
                "cut_exposure": {
                    "unique_exposure_count": 59,
                    "inferred_role": "removal",
                },
                "reasons": ["Replay profile measured 59 deduplicated exposures."],
            },
            {
                "card_name": "Stroke of Midnight",
                "status": "measured_cut_exposure_needs_same_lane_benchmark",
                "recommended_action": "manual_same_lane_only",
                "cut_exposure": {
                    "unique_exposure_count": 57,
                    "inferred_role": "removal",
                },
                "reasons": ["Replay profile measured 57 deduplicated exposures."],
            },
        ],
        "top_protected_exposure_slots": [
            {
                "card_name": "Sensei's Divining Top",
                "status": "measured_high_cut_exposure",
                "recommended_action": "blocked",
                "cut_exposure": {
                    "unique_exposure_count": 1605,
                    "inferred_role": "draw_filter_value",
                },
            }
        ],
    }
    return payload


def trace_audit_report():
    return {
        "candidate_key": "candidate_607_squee_hashseed0_isolated_cached_timeout_v3",
        "summary": {
            "recommended_next_action": "review_focus_access_trace_then_define_next_deck_or_runtime_package",
            "trace_status_counts": {
                "focus_access_trace_available_review_sequence": 1,
                "focus_access_trace_available_review_conversion": 1,
                "runtime_trace_payload_available_review_model_scope": 1,
                "trace_evidence_supports_sequencing_gap": 1,
            },
        },
        "hypothesis_assessments": [
            {
                "hypothesis_key": "trace_seed7_engine_access_sequence",
                "trace_status": "focus_access_trace_available_review_sequence",
                "target_seeds": ["7"],
                "focus_cards": ["Squee, Goblin Nabob", "Sensei's Divining Top"],
                "next_action": "review weak-seed access sequence",
                "current_limitations": ["Squee stayed in library in seed 7"],
            },
            {
                "hypothesis_key": "trace_seed20260625_conversion_window",
                "trace_status": "focus_access_trace_available_review_conversion",
                "target_seeds": ["20260625"],
                "focus_cards": ["The Mind Stone", "Land Tax"],
                "next_action": "review conversion-window access trace",
                "current_limitations": ["Land Tax stayed in library in seed 20260625"],
            },
        ],
    }


def exposure_profile():
    return (
        planner.DEFAULT_EXPOSURE_PROFILES[0],
        {
            "card_profiles": [
                {
                    "card_name": "Gamble",
                    "unique_exposure_count": 228,
                    "inferred_role": "tutor_access",
                    "decision": {"status": "runtime_ready_cut_sensitive"},
                },
                {
                    "card_name": "Enlightened Tutor",
                    "unique_exposure_count": 202,
                    "inferred_role": "tutor_access",
                    "decision": {"status": "runtime_ready_cut_sensitive"},
                },
                {
                    "card_name": "Squee, Goblin Nabob",
                    "unique_exposure_count": 6660,
                    "inferred_role": "recursion_engine",
                    "decision": {"status": "protect_current_engine"},
                },
            ]
        },
    )


def tutor_cut_model_report():
    return (
        planner.DEFAULT_TUTOR_CUT_MODEL_REPORTS[0],
        {
            "summary": {
                "direct_gate_ready_count": 0,
                "recommended_next_action": (
                    "do_not_gate_direct_tutor_swap; benchmark same-access cuts or build additive package"
                ),
            },
            "top_manual_benchmarks": [
                {
                    "candidate": "Enlightened Tutor",
                    "cut": "Land Tax",
                    "status": "protected_benchmark_required",
                },
                {
                    "candidate": "Gamble",
                    "cut": "Land Tax",
                    "status": "protected_benchmark_required",
                },
            ],
        },
    )


def prior_tutor_land_tax_report():
    def package(key, add):
        return {
            "package_key": key,
            "adds": [add],
            "cuts": ["Land Tax"],
            "gate_summary": {
                "delta_pp": -66.67,
                "baseline": {"wins": 3, "losses": 0, "stalls": 0, "win_rate": 100.0},
                "candidate": {"wins": 1, "losses": 2, "stalls": 0, "win_rate": 33.33},
            },
        }

    return (
        planner.DEFAULT_PRIOR_PACKAGE_REPORTS[0],
        {
            "packages": [
                package("gamble_access_benchmark_cut_land_tax", "Gamble"),
                package("enlightened_access_benchmark_cut_land_tax", "Enlightened Tutor"),
            ]
        },
    )


def prior_brass_seed_matrix_report():
    return (
        planner.REPORT_DIR / "lorehold_brass_bounty_recurring_seed_window_20260628_v1_run.json",
        {
            "packages": [
                {
                    "package_key": "brass_bounty_cut_boros_signet",
                    "adds": ["Brass's Bounty"],
                    "cuts": ["Boros Signet"],
                    "aggregate": {
                        "decision": "reject_regresses_strong_seed",
                        "delta_pp_total": -4.17,
                        "baseline_record": "14-34",
                        "candidate_record": "12-36",
                    },
                }
            ]
        },
    )


def prior_profiled_family_seed_matrix_report():
    def package(key, add, cut):
        return {
            "package_key": key,
            "adds": [add],
            "cuts": [cut],
            "aggregate": {
                "decision": "reject_regresses_strong_seed",
                "delta_pp_total": -22.22,
                "baseline_record": "4-5",
                "candidate_record": "2-7",
                "strong_seed_regressions": [42],
            },
        }

    return (
        planner.REPORT_DIR
        / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json",
        {
            "packages": [
                package(
                    "seething_song_same_lane_benchmark_cut_bender_s_waterskin",
                    "Seething Song",
                    "Bender's Waterskin",
                ),
                package(
                    "mana_vault_same_lane_benchmark_cut_bender_s_waterskin",
                    "Mana Vault",
                    "Bender's Waterskin",
                ),
                package(
                    "invoke_calamity_same_lane_benchmark_cut_creative_technique",
                    "Invoke Calamity",
                    "Creative Technique",
                ),
                package(
                    "velomachus_lorehold_same_lane_benchmark_cut_creative_technique",
                    "Velomachus Lorehold",
                    "Creative Technique",
                ),
            ]
        },
    )


def profiled_cut_benchmark_exhausted_report():
    return (
        planner.REPORT_DIR
        / "lorehold_profiled_cut_family_benchmark_generator_20260628_v7_exhausted.json",
        {
            "summary": {
                "recommended_next_action": "no_profiled_cut_benchmark_package_ready",
                "profiled_cut_count": 4,
                "preflight_ready_pair_count": 0,
                "selected_package_count": 0,
                "status_counts": {"blocked": 1080},
            }
        },
    )


def prior_strategy_audit_report():
    return (
        planner.DEFAULT_STRATEGY_AUDIT,
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
                            }
                        ],
                    }
                ]
            },
            "post_squee_package_gates": {
                "rows": [
                    {
                        "package_key": "brainstone_topdeck_miracle_cut_squelcher",
                        "family": "topdeck_setup",
                        "adds": ["Brainstone"],
                        "cuts": ["Hexing Squelcher"],
                        "baseline_wins": 8,
                        "baseline_losses": 19,
                        "candidate_wins": 8,
                        "candidate_losses": 19,
                        "decision": "reject_or_rework",
                        "delta_pp": 0.0,
                    }
                ]
            },
        },
    )


def prior_low_exposure_report(*, with_strategy_scope=False):
    return (
        planner.REPORT_DIR / "low_exposure_package_report.json",
        {
            "cut_safety_report": "/tmp/cut.json" if with_strategy_scope else None,
            "prior_package_reports": ["/tmp/prior.json"] if with_strategy_scope else [],
            "packages": [
                {
                    "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                    "adds": ["Mana Vault"],
                    "cuts": ["Arcane Signet"],
                    "decision": "reject_or_rework",
                    "gate_summary": {
                        "baseline": {"wins": 1, "losses": 0, "win_rate": 100.0},
                        "candidate": {"wins": 1, "losses": 0, "win_rate": 100.0},
                        "delta_pp": 0.0,
                    },
                    "exposure_summary": {
                        "low_candidate_added_card_use": True,
                        "status": "candidate_added_card_low_access",
                        "next_step": "increase_sample_or_run_forced_access_gate",
                        "candidate_added_cards": {
                            "cards": [
                                {
                                    "card_name": "Mana Vault",
                                    "status": "library_only_not_used",
                                    "recorded_use_count": 0,
                                    "access_profile": {
                                        "accessed_games": 0,
                                        "near_access_games": 0,
                                        "library_only_games": 1,
                                    },
                                }
                            ]
                        },
                    },
                }
            ],
        },
    )


def prior_insufficient_used_sample_report(*, with_strategy_scope=False):
    return (
        planner.REPORT_DIR / "insufficient_used_sample_package_report.json",
        {
            "cut_safety_report": "/tmp/cut.json" if with_strategy_scope else None,
            "prior_package_reports": ["/tmp/prior.json"] if with_strategy_scope else [],
            "packages": [
                {
                    "package_key": "birgi_spellchain_cut_jeskas_will",
                    "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                    "cuts": ["Jeska's Will"],
                    "decision": "insufficient_card_outcome_used_sample",
                    "gate_summary": {
                        "baseline": {"wins": 0, "losses": 1, "win_rate": 0.0},
                        "candidate": {"wins": 1, "losses": 0, "win_rate": 100.0},
                        "delta_pp": 100.0,
                    },
                    "exposure_summary": {
                        "low_candidate_added_card_use": False,
                        "status": "candidate_added_cards_used",
                        "candidate_added_cards": {
                            "cards": [
                                {
                                    "card_name": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                                    "status": "used",
                                    "recorded_use_count": 1,
                                    "outcome_summary": {
                                        "used_games": {"games": 1, "wins": 1, "losses": 0}
                                    },
                                }
                            ]
                        },
                    },
                }
            ],
        },
    )


def prior_birgi_reject_report():
    return (
        planner.REPORT_DIR / "birgi_old_reject_report.json",
        {
            "packages": [
                {
                    "package_key": "birgi_spellchain_cut_jeskas_will",
                    "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
                    "cuts": ["Jeska's Will"],
                    "decision": "reject_or_rework",
                    "gate_summary": {
                        "baseline": {"wins": 1, "losses": 0, "win_rate": 100.0},
                        "candidate": {"wins": 0, "losses": 1, "win_rate": 0.0},
                        "delta_pp": -100.0,
                    },
                }
            ]
        },
    )


def prior_mana_vault_reject_rollup_report():
    return (
        planner.REPORT_DIR / "mana_vault_rollup_reject_report.json",
        {
            "package_rollups": [
                {
                    "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                    "status": "natural_reject_current_pair",
                    "adds": ["Mana Vault"],
                    "cuts": ["Arcane Signet"],
                    "worst_aggregate_delta_pp": -66.67,
                }
            ]
        },
    )


def hand_filter_cut_model_report():
    return (
        planner.DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS[0],
        {
            "summary": {
                "preflight_benchmark_ready_count": 1,
                "prior_rejected_pair_count": 1,
                "recommended_next_action": "preflight_Wheel of Fortune_over_Big Score",
            },
            "preflight_benchmark_candidates": [
                {
                    "candidate": "Wheel of Fortune",
                    "cut": "Big Score",
                    "status": "preflight_benchmark_ready",
                    "score": 118,
                    "blockers": ["cut_removes_ramp_or_treasure_role"],
                }
            ],
            "pair_evaluations": [
                {
                    "candidate": "Valakut Awakening // Valakut Stoneforge",
                    "cut": "Big Score",
                    "status": "blocked_prior_reject",
                }
            ],
        },
    )


def hand_filter_blocked_model_report():
    return (
        planner.DEFAULT_HAND_FILTER_CUT_MODEL_REPORTS[0],
        {
            "summary": {
                "preflight_benchmark_ready_count": 0,
                "recommended_next_action": (
                    "do_not_gate_hand_filter_without_new_cut_or_runtime_evidence"
                ),
            },
            "preflight_benchmark_candidates": [],
            "pair_evaluations": [
                {
                    "candidate": "Valakut Awakening // Valakut Stoneforge",
                    "cut": "Big Score",
                    "status": "blocked_prior_reject",
                }
            ],
        },
    )


def recursion_cut_model_report():
    return (
        planner.DEFAULT_RECURSION_CUT_MODEL_REPORTS[0],
        {
            "summary": {
                "preflight_benchmark_ready_count": 1,
                "recommended_next_action": (
                    "preflight_Volcanic Vision_over_Pinnacle Monk // Mystic Peak"
                ),
            },
            "preflight_benchmark_candidates": [
                {
                    "candidate": "Volcanic Vision",
                    "cut": "Pinnacle Monk // Mystic Peak",
                    "status": "preflight_benchmark_ready",
                    "score": 112,
                    "blockers": ["candidate_low_natural_exposure"],
                }
            ],
            "pair_evaluations": [
                {
                    "candidate": "Volcanic Vision",
                    "cut": "Squee, Goblin Nabob",
                    "status": "blocked_core_or_current_engine_cut",
                }
            ],
        },
    )


def recursion_blocked_model_report():
    return (
        planner.DEFAULT_RECURSION_CUT_MODEL_REPORTS[0],
        {
            "summary": {
                "preflight_benchmark_ready_count": 0,
                "recommended_next_action": (
                    "do_not_gate_recursion_without_non_squee_cut_or_multi_card_package"
                ),
            },
            "preflight_benchmark_candidates": [],
            "pair_evaluations": [
                {
                    "candidate": "Volcanic Vision",
                    "cut": "Pinnacle Monk // Mystic Peak",
                    "status": "blocked_prior_reject",
                },
                {
                    "candidate": "Restoration Seminar",
                    "cut": "Pinnacle Monk // Mystic Peak",
                    "status": "blocked_cut_prior_reject",
                },
            ],
        },
    )


def mana_base_validator_report():
    return (
        planner.REPORT_DIR / "mana_base_validator_test.json",
        {
            "summary": {
                "ready_swap_count": 1,
                "recommended_next_action": "run_mana_base_validated_preflight",
            },
            "ready_swaps": [
                {
                    "candidate": "Plateau",
                    "cut": "Turbulent Steppe",
                    "score": 44,
                    "deltas": {
                        "red_source_delta": 0,
                        "white_source_delta": 0,
                        "boros_source_delta": 0,
                        "etb_score_delta": 2,
                    },
                    "gained_roles": ["fetchable_boros_dual"],
                    "lost_roles": [],
                }
            ],
        },
    )


def strategy_audit():
    return {
        "current_champion_key": "candidate_607_squee_hashseed0_isolated_cached_timeout_v3",
        "deck_summaries": {
            "607": {
                "cards": [
                    {"card_name": "Urza's Saga"},
                    {"card_name": "Library of Leng"},
                    {"card_name": "Sensei's Divining Top"},
                    {"card_name": "Scroll Rack"},
                    {"card_name": "Squee, Goblin Nabob"},
                    {"card_name": "The Mind Stone"},
                    {"card_name": "Land Tax"},
                ]
            }
        },
        "external_method_sources": [
            {
                "name": "EDHREC Lorehold commander page",
                "url": "https://edhrec.com/commanders/lorehold-the-historian",
                "use": "commander-specific package comparison lane",
            }
        ],
        "runtime_package_readiness": {
            "summary": {
                "card_count": 2,
                "readiness_counts": {"runtime_ready_pg_precheck_blocked": 2},
            }
        },
        "strategy_dependency_map": {
            "current_benchmark": {
                "champion": {
                    "record": "24-66-0",
                    "games": 90,
                    "win_rate": 26.67,
                    "wins": 24,
                    "losses": 66,
                }
            },
            "next_hypothesis_contract": {
                "must_target": [
                    "seed 7: missing early topdeck/Library/Squee engine",
                    "seed 20260625: engine appears but fails to convert",
                ],
                "required_telemetry": [
                    "miracle_cast and topdeck_manipulation_activated must not fall",
                ],
            },
            "dependency_pillars": [
                {
                    "pillar": "topdeck_miracle_setup",
                    "risk": "seed 7 shows the deck can miss the engine entirely",
                    "next_requirement": "improve early access or topdeck quality",
                    "depends_on": ["Library of Leng", "Scroll Rack", "Sensei's Divining Top"],
                }
            ],
        },
    }


def exhausted_hypothesis_queue():
    return {
        "summary": {
            "gate_ready_count": 0,
            "tested_negative_count": 13,
            "status_counts": {"tested_negative_do_not_promote": 13},
        }
    }


def test_next_action_planner_prioritizes_cut_models_before_gates():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
    )

    assert payload["postgres_writes"] is False
    assert payload["summary"]["gate_ready_now_count"] == 0
    assert payload["summary"]["recommended_next_action"] == "build_tutor_seed_safe_cut_model"

    actions = {row["action_key"]: row for row in payload["action_queue"]}
    assert actions["build_tutor_seed_safe_cut_model"]["priority"] == 1
    assert actions["build_tutor_seed_safe_cut_model"]["candidate_exposure"]["Gamble"][
        "unique_exposure_count"
    ] == 228
    assert actions["profile_hand_filter_cut_benchmarks"]["missing_exposure_cards"] == [
        "Apex of Power",
        "Artist's Talent",
    ]
    assert actions["preserve_squee_build_recursion_package"]["manual_blocked_candidates"][0][
        "decision"
    ] == "do_not_cut_current_champion_engine"
    assert actions["use_mana_base_validator_not_battle_gate"]["status"] == (
        "mana_model_required_before_gate"
    )
    assert actions["batch_xmage_runtime_rule_gaps"]["candidate_cards"] == ["Needs Runtime"]
    assert actions["batch_xmage_runtime_rule_gaps"]["candidate_count"] == 2
    guardrails = {row["guardrail_key"] for row in payload["guardrails"]}
    assert "austere_emeria_tradeoff_rejected" in guardrails


def test_next_action_planner_prioritizes_cut_exposure_when_safe_cut_queue_is_empty():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review_with_cut_evidence(),
        exposure_profiles=[exposure_profile()],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "model_low_exposure_cut_slots_before_gate"
    )
    action = payload["action_queue"][0]
    assert action["priority"] == -3
    assert action["status"] == "cut_safety_expansion_required"
    assert action["cut_cards"] == ["Winds of Abandon", "Stroke of Midnight"]


def test_next_action_planner_moves_to_same_lane_benchmarks_after_cut_exposure():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review_with_profiled_cut_evidence(),
        exposure_profiles=[exposure_profile()],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "build_same_lane_benchmarks_from_profiled_cut_slots"
    )
    action = payload["action_queue"][0]
    assert action["status"] == "cut_exposure_profiled_requires_same_lane_package"
    assert action["cut_cards"] == ["Winds of Abandon", "Stroke of Midnight"]
    assert action["protected_high_exposure_cut_slots"][0]["card_name"] == (
        "Sensei's Divining Top"
    )


def test_next_action_planner_moves_past_exhausted_profiled_same_lane_benchmarks():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review_with_profiled_cut_evidence(),
        exposure_profiles=[exposure_profile()],
        trace_audit=trace_audit_report(),
        profiled_cut_benchmark_reports=[profiled_cut_benchmark_exhausted_report()],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "review_focus_access_trace_then_define_next_deck_or_runtime_package"
    )
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    exhausted = actions["record_profiled_same_lane_benchmarks_exhausted"]
    assert exhausted["priority"] == 3
    assert exhausted["status"] == "profiled_same_lane_benchmark_queue_exhausted"
    assert exhausted["profiled_cut_benchmark_summary"]["preflight_ready_pair_count"] == 0
    guardrails = {row["guardrail_key"]: row for row in payload["guardrails"]}
    assert "profiled_same_lane_benchmark_queue_exhausted" in guardrails


def test_next_action_planner_moves_past_rejected_land_tax_tutor_benchmarks():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        tutor_cut_model_reports=[tutor_cut_model_report()],
        prior_package_reports=[prior_tutor_land_tax_report()],
    )

    assert payload["summary"]["recommended_next_action"] == "profile_hand_filter_cut_benchmarks"
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    tutor_action = actions["avoid_rejected_tutor_land_tax_swaps"]
    assert tutor_action["status"] == "tutor_land_tax_benchmarks_rejected"
    assert tutor_action["priority"] == 90
    assert tutor_action["cut_cards"] == ["Land Tax"]
    assert set(tutor_action["land_tax_benchmark_rejections"]) == {
        "gamble_access_benchmark_cut_land_tax",
        "enlightened_access_benchmark_cut_land_tax",
    }


def test_next_action_planner_imports_seed_matrix_aggregate_rejections():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_brass_seed_matrix_report()],
    )

    assert payload["summary"]["prior_rejected_package_count"] == 1
    assert payload["summary"]["prior_rejected_package_keys"] == [
        "brass_bounty_cut_boros_signet"
    ]
    guardrails = {row["guardrail_key"]: row for row in payload["guardrails"]}
    assert "prior_package_reports_have_rejections" in guardrails
    assert guardrails["prior_package_reports_have_rejections"]["rejected_package_keys"] == [
        "brass_bounty_cut_boros_signet"
    ]


def test_next_action_planner_imports_profiled_family_seed_matrix_rejections():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_profiled_family_seed_matrix_report()],
    )

    assert payload["summary"]["prior_rejected_package_count"] == 4
    assert payload["summary"]["prior_rejected_package_keys"] == [
        "invoke_calamity_same_lane_benchmark_cut_creative_technique",
        "mana_vault_same_lane_benchmark_cut_bender_s_waterskin",
        "seething_song_same_lane_benchmark_cut_bender_s_waterskin",
        "velomachus_lorehold_same_lane_benchmark_cut_creative_technique",
    ]
    guardrails = {row["guardrail_key"]: row for row in payload["guardrails"]}
    assert guardrails["prior_package_reports_have_rejections"]["rejected_package_count"] == 4
    assert guardrails["prior_package_reports_have_rejections"]["rejected_package_keys"][0] == (
        "invoke_calamity_same_lane_benchmark_cut_creative_technique"
    )


def test_next_action_planner_imports_strategy_audit_rejections():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_strategy_audit_report()],
    )

    assert payload["summary"]["prior_rejected_package_count"] == 2
    assert payload["summary"]["prior_rejected_package_keys"] == [
        "brainstone_topdeck_miracle_cut_squelcher",
        "faithless_looting_squee_enabler",
    ]
    prior = planner.rejected_package_evidence([prior_strategy_audit_report()])
    assert prior["faithless_looting_squee_enabler"]["cuts"] == ["Hexing Squelcher"]
    assert prior["faithless_looting_squee_enabler"]["source_section"] == (
        "cut_safety_manifest"
    )
    assert prior["faithless_looting_squee_enabler"]["baseline"]["wins"] == 8
    assert prior["brainstone_topdeck_miracle_cut_squelcher"]["source_section"] == (
        "post_squee_package_gates"
    )
    assert prior["brainstone_topdeck_miracle_cut_squelcher"]["candidate"]["losses"] == 19


def test_next_action_planner_default_prior_reports_include_strategy_audit():
    assert planner.DEFAULT_STRATEGY_AUDIT in planner.DEFAULT_PRIOR_PACKAGE_REPORTS


def test_next_action_planner_defaults_include_exposure_contract_report():
    default_names = {path.name for path in planner.DEFAULT_PRIOR_PACKAGE_REPORTS}

    assert "lorehold_exposure_decision_contract_20260628_v1_20260628_190000.json" in default_names
    assert "lorehold_exposure_outcome_audit_20260628_actionability_v1.json" in default_names


def test_next_action_planner_default_prior_reports_include_profiled_history():
    expected = {
        "lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_20260628_091321.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_witch_confirm_20260628_091458.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v5_20260628_092712.json",
        "lorehold_profiled_cut_family_benchmark_matrix_20260628_v6_20260628_093001.json",
    }
    default_names = {path.name for path in planner.DEFAULT_PRIOR_PACKAGE_REPORTS}
    assert expected.issubset(default_names)


def test_next_action_planner_downgrades_low_exposure_rejects_to_inconclusive():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_low_exposure_report(with_strategy_scope=True)],
    )

    assert payload["summary"]["prior_rejected_package_count"] == 0
    assert payload["summary"]["prior_inconclusive_low_exposure_count"] == 1
    assert payload["summary"]["prior_inconclusive_low_exposure_keys"] == [
        "mana_vault_fast_mana_cut_arcane_signet"
    ]
    assert payload["summary"]["recommended_next_action"] == (
        "resolve_inconclusive_package_exposures"
    )
    action = payload["action_queue"][0]
    assert action["status"] == "resolve_strategy_gate_low_exposure_before_next_swap"
    assert action["strategy_gate_inconclusive_count"] == 1
    assert action["packages"][0]["candidate_added_card_statuses"][0]["status"] == (
        "library_only_not_used"
    )
    guardrails = {row["guardrail_key"]: row for row in payload["guardrails"]}
    assert "inconclusive_low_exposure_is_not_card_proof" in guardrails


def test_next_action_planner_infers_low_exposure_from_status_without_boolean():
    result = {
        "package_key": "silence_cut_avatar_wrath",
        "decision": "reject_or_rework",
        "exposure_summary": {
            "status": "candidate_added_cards_accessed_not_used",
            "candidate_added_cards": {"all_cards_used": False},
        },
    }

    assert planner.infer_package_decision(result) == "inconclusive_low_exposure"


def test_next_action_planner_downgrades_insufficient_used_sample_to_inconclusive():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_insufficient_used_sample_report(with_strategy_scope=True)],
    )

    assert payload["summary"]["prior_rejected_package_count"] == 0
    assert payload["summary"]["prior_inconclusive_low_exposure_count"] == 1
    assert payload["summary"]["prior_inconclusive_low_exposure_keys"] == [
        "birgi_spellchain_cut_jeskas_will"
    ]
    assert payload["summary"]["recommended_next_action"] == (
        "resolve_inconclusive_package_exposures"
    )
    action = payload["action_queue"][0]
    assert action["status"] == "resolve_strategy_gate_low_exposure_before_next_swap"
    assert action["packages"][0]["decision"] == "insufficient_card_outcome_used_sample"
    assert action["packages"][0]["candidate_added_card_statuses"][0]["used_games"] == 1


def test_next_action_planner_routes_accessed_without_use_rollup_to_inconclusive_queue():
    payload = {
        "package_rollups": [
            {
                "package_key": "silence_cut_avatar_wrath",
                "status": "accessed_without_use_conversion_review",
                "adds": ["Silence"],
                "cuts": ["Avatar's Wrath"],
                "worst_aggregate_delta_pp": 100.0,
            }
        ],
    }
    reports = [(Path("outcome.json"), payload)]

    rejected = planner.rejected_package_evidence(reports)
    inconclusive = planner.inconclusive_package_evidence(reports)

    assert "silence_cut_avatar_wrath" not in rejected
    assert inconclusive["silence_cut_avatar_wrath"]["decision"] == (
        "candidate_accessed_without_used_sample"
    )


def test_next_action_planner_routes_near_access_without_use_rollup_to_inconclusive_queue():
    payload = {
        "package_rollups": [
            {
                "package_key": "wheel_hand_filter_cut_big_score",
                "status": "near_access_without_use_access_window_review",
                "adds": ["Wheel of Fortune"],
                "cuts": ["Big Score"],
                "worst_aggregate_delta_pp": 100.0,
            }
        ],
    }
    reports = [(Path("outcome.json"), payload)]

    rejected = planner.rejected_package_evidence(reports)
    inconclusive = planner.inconclusive_package_evidence(reports)

    assert "wheel_hand_filter_cut_big_score" not in rejected
    assert inconclusive["wheel_hand_filter_cut_big_score"]["decision"] == (
        "candidate_near_access_without_used_sample"
    )


def test_next_action_planner_prefers_package_rollups_over_raw_observations():
    payload = {
        "package_rollups": [
            {
                "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                "status": "natural_reject_current_pair",
                "adds": ["Mana Vault"],
                "cuts": ["Arcane Signet"],
                "worst_aggregate_delta_pp": -66.67,
            }
        ],
        "packages": [
            {
                "package_key": "mana_vault_fast_mana_cut_arcane_signet",
                "decision": "insufficient_card_outcome_used_sample",
            }
        ],
    }

    rows = planner.package_rows_from_prior_payload(payload)

    assert len(rows) == 1
    assert rows[0]["source_section"] == "package_rollups"
    assert rows[0]["decision"] == "reject_or_rework"


def test_next_action_planner_later_insufficient_sample_overrides_old_reject():
    reports = [
        prior_birgi_reject_report(),
        prior_insufficient_used_sample_report(with_strategy_scope=True),
    ]

    rejected = planner.rejected_package_evidence(reports)
    inconclusive = planner.inconclusive_package_evidence(reports)

    assert "birgi_spellchain_cut_jeskas_will" not in rejected
    assert "birgi_spellchain_cut_jeskas_will" in inconclusive


def test_next_action_planner_later_rollup_reject_overrides_old_inconclusive():
    reports = [
        prior_low_exposure_report(with_strategy_scope=True),
        prior_mana_vault_reject_rollup_report(),
    ]

    rejected = planner.rejected_package_evidence(reports)
    inconclusive = planner.inconclusive_package_evidence(reports)

    assert "mana_vault_fast_mana_cut_arcane_signet" in rejected
    assert "mana_vault_fast_mana_cut_arcane_signet" not in inconclusive


def test_next_action_planner_keeps_diagnostic_low_exposure_below_strategy_actions():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review_with_profiled_cut_evidence(),
        exposure_profiles=[exposure_profile()],
        prior_package_reports=[prior_low_exposure_report(with_strategy_scope=False)],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "build_same_lane_benchmarks_from_profiled_cut_slots"
    )
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    action = actions["resolve_inconclusive_package_exposures"]
    assert action["priority"] == 6
    assert action["status"] == "diagnostic_low_exposure_recorded_no_strategy_block"
    assert action["diagnostic_or_contract_inconclusive_count"] == 1


def test_next_action_planner_prioritizes_focus_access_trace_review():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        trace_audit=trace_audit_report(),
    )

    assert payload["summary"]["recommended_next_action"] == (
        "review_focus_access_trace_then_define_next_deck_or_runtime_package"
    )
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    action = actions["review_focus_access_trace_then_define_next_deck_or_runtime_package"]
    assert action["status"] == "focus_access_trace_ready_for_package_design"
    assert "Squee, Goblin Nabob" in action["candidate_cards"]
    assert "The Mind Stone" in action["candidate_cards"]


def test_next_action_planner_uses_hand_filter_model_after_prior_rejects():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        tutor_cut_model_reports=[tutor_cut_model_report()],
        hand_filter_cut_model_reports=[hand_filter_cut_model_report()],
        prior_package_reports=[prior_tutor_land_tax_report()],
    )

    assert payload["summary"]["recommended_next_action"] == "run_hand_filter_benchmark_gate"
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    hand_filter_action = actions["run_hand_filter_benchmark_gate"]
    assert hand_filter_action["status"] == "same_lane_benchmark_ready"
    assert hand_filter_action["candidate_cards"] == ["Wheel of Fortune"]
    assert hand_filter_action["cut_cards"] == ["Big Score"]
    assert hand_filter_action["blocked_prior_rejections"][0]["candidate"] == (
        "Valakut Awakening // Valakut Stoneforge"
    )


def test_next_action_planner_uses_recursion_model_when_hand_filter_blocked():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        tutor_cut_model_reports=[tutor_cut_model_report()],
        hand_filter_cut_model_reports=[hand_filter_blocked_model_report()],
        recursion_cut_model_reports=[recursion_cut_model_report()],
        prior_package_reports=[prior_tutor_land_tax_report()],
    )

    assert payload["summary"]["recommended_next_action"] == "run_recursion_benchmark_gate"
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    recursion_action = actions["run_recursion_benchmark_gate"]
    assert recursion_action["status"] == "same_lane_benchmark_ready"
    assert recursion_action["candidate_cards"] == ["Volcanic Vision"]
    assert recursion_action["cut_cards"] == ["Pinnacle Monk // Mystic Peak"]


def test_next_action_planner_moves_to_mana_after_recursion_rejects():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        tutor_cut_model_reports=[tutor_cut_model_report()],
        hand_filter_cut_model_reports=[hand_filter_blocked_model_report()],
        recursion_cut_model_reports=[recursion_blocked_model_report()],
        prior_package_reports=[prior_tutor_land_tax_report()],
    )

    assert payload["summary"]["recommended_next_action"] == "use_mana_base_validator_not_battle_gate"
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    recursion_action = actions["avoid_recursion_without_non_squee_cut"]
    assert recursion_action["status"] == "no_recursion_benchmark_ready"
    assert recursion_action["priority"] == 90
    assert recursion_action["blocked_prior_rejections"][0]["status"] == "blocked_prior_reject"


def test_next_action_planner_uses_validated_mana_preflight_report():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        tutor_cut_model_reports=[tutor_cut_model_report()],
        hand_filter_cut_model_reports=[hand_filter_blocked_model_report()],
        recursion_cut_model_reports=[recursion_blocked_model_report()],
        mana_base_validator_reports=[mana_base_validator_report()],
        prior_package_reports=[prior_tutor_land_tax_report()],
    )

    assert payload["summary"]["recommended_next_action"] == "run_mana_base_validated_preflight"
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    mana_action = actions["run_mana_base_validated_preflight"]
    assert mana_action["status"] == "mana_base_preflight_ready"
    assert mana_action["candidate_cards"] == ["Plateau"]
    assert mana_action["cut_cards"] == ["Turbulent Steppe"]
    assert mana_action["top_ready_swaps"][0]["deltas"]["etb_score_delta"] == 2


def test_next_action_planner_routes_exhausted_queue_to_strategy_synthesis():
    payload = planner.build_plan(
        miner_report=miner_report(),
        manual_review=manual_review(),
        exposure_profiles=[exposure_profile()],
        strategy_audit=strategy_audit(),
        hypothesis_queue=exhausted_hypothesis_queue(),
    )

    assert payload["summary"]["recommended_next_action"] == (
        "build_failure_targeted_synergy_hypotheses"
    )
    actions = {row["action_key"]: row for row in payload["action_queue"]}
    action = actions["build_failure_targeted_synergy_hypotheses"]
    assert action["priority"] == -1
    assert action["status"] == "hypothesis_queue_exhausted_requires_new_synthesis"
    assert "Urza's Saga" in action["candidate_cards"]
    assert action["evidence"]["queue_summary"]["tested_negative_count"] == 13
    assert action["evidence"]["must_target"][0].startswith("seed 7")
    guardrails = {row["guardrail_key"] for row in payload["guardrails"]}
    assert "current_hypothesis_queue_exhausted" in guardrails
