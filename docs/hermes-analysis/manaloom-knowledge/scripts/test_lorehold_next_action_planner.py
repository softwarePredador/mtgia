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
