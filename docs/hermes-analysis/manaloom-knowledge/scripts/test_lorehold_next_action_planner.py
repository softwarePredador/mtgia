import lorehold_next_action_planner as planner


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
