import lorehold_focus_access_package_generator as gen


def test_default_planner_uses_current_rejection_integrated_report():
    assert gen.DEFAULT_PLANNER.name == "lorehold_next_action_planner_20260628_v16_current_default_chain.json"


def test_default_access_model_uses_runtime_overlay_report():
    assert gen.DEFAULT_ACCESS_MODEL.name == "lorehold_access_cut_model_20260628_v3_runtime_overlay.json"


def test_default_runtime_gap_queue_uses_current_miner_report():
    assert gen.DEFAULT_RUNTIME_GAP_QUEUE.name == "lorehold_runtime_gap_family_queue_20260628_v6_current_miner.json"


def planner_payload(prior_keys=None):
    return {
        "summary": {
            "prior_rejected_package_count": len(prior_keys or []),
            "prior_rejected_package_keys": prior_keys or [],
        },
        "action_queue": [
            {
                "action_key": "batch_xmage_runtime_rule_gaps",
                "why_now": "runtime gaps remain",
            }
        ],
    }


def trace_audit():
    return {
        "primary_seed_records": {"42": {}, "7": {}, "20260625": {}},
        "hypothesis_assessments": [
            {
                "hypothesis_key": "trace_seed7_engine_access_sequence",
                "trace_status": "focus_access_trace_available_review_sequence",
                "target_seeds": ["7"],
                "focus_cards": ["Sensei's Divining Top"],
                "next_action": "review weak-seed access sequence",
            },
            {
                "hypothesis_key": "trace_seed20260625_conversion_window",
                "trace_status": "focus_access_trace_available_review_conversion",
                "target_seeds": ["20260625"],
                "focus_cards": ["The Mind Stone"],
                "next_action": "review conversion window",
            },
            {
                "hypothesis_key": "audit_squee_graveyard_entry_route",
                "trace_status": "trace_evidence_supports_sequencing_gap",
                "target_seeds": ["7", "20260625", "42"],
                "focus_cards": ["Squee, Goblin Nabob"],
                "next_action": "add Squee sequencing probe",
            },
        ],
    }


def miner_with_pairing(pairing, negative_exact_packages=None):
    return {
        "pairing_hypotheses": [pairing],
        "negative_exact_packages": negative_exact_packages or [],
    }


def ready_cut(card_name):
    return {
        "card_name": card_name,
        "status": "untested_flex_candidate",
        "gate_readiness": "preflight_benchmark_ready",
        "readiness_reason": "synthetic test cut is ready",
    }


def test_prior_negative_exact_package_is_blocked_before_retesting():
    pairing = {
        "candidate": "Brass's Bounty",
        "candidate_status": "high_frequency_runtime_ready_unexplored",
        "candidate_score": 80,
        "lane": "contextual",
        "cut_options": [ready_cut("Boros Signet")],
    }
    miner = miner_with_pairing(
        pairing,
        [
            {
                "package_key": "brass_bounty_cut_boros_signet",
                "adds": ["Brass's Bounty"],
                "cuts": ["Boros Signet"],
                "delta_pp": -4.17,
            }
        ],
    )

    rows = gen.evaluate_pairings(
        miner_report=miner,
        trace_audit=trace_audit(),
        planner_payload=planner_payload(["brass_bounty_cut_boros_signet"]),
    )

    assert rows[0]["prior_negative_exact_match"] is True
    assert rows[0]["status"] == "blocked_prior_negative_exact"


def test_protected_cut_is_blocked_even_when_runtime_and_failure_mode_are_ready():
    pairing = {
        "candidate": "Enlightened Tutor",
        "candidate_status": "high_frequency_runtime_ready_unexplored",
        "candidate_score": 84,
        "lane": "contextual",
        "cut_options": [ready_cut("Land Tax")],
    }

    rows = gen.evaluate_pairings(
        miner_report=miner_with_pairing(pairing),
        trace_audit=trace_audit(),
        planner_payload=planner_payload(),
    )

    assert rows[0]["target_failure_mode"] == "seed7_missing_engine_access"
    assert rows[0]["protected_cards_avoided"] is False
    assert rows[0]["status"] == "blocked_protected_cut"


def test_clean_pair_is_gate_ready_with_required_guardrail_metadata():
    pairing = {
        "candidate": "Access Helper",
        "candidate_status": "runtime_ready_unexplored",
        "candidate_score": 55,
        "lane": "hand_filter",
        "cut_options": [ready_cut("Loose Spell")],
    }

    rows = gen.evaluate_pairings(
        miner_report=miner_with_pairing(pairing),
        trace_audit=trace_audit(),
        planner_payload=planner_payload(),
    )

    row = rows[0]
    assert row["status"] == "gate_ready_focus_access_package"
    assert row["target_failure_mode"] == "seed20260625_conversion_under_pressure"
    assert row["protected_cards_avoided"] is True
    assert row["prior_negative_exact_match"] is False
    assert row["runtime_status"] == "active_or_materialized"
    assert row["seed_42_anchor_requirement"]["available"] is True


def test_no_valid_package_routes_to_trace_runtime_or_cut_model_work():
    pairing = {
        "candidate": "Gamble",
        "candidate_status": "high_frequency_runtime_ready_unexplored",
        "candidate_score": 74,
        "lane": "contextual",
        "cut_options": [],
        "recommended_action": "define contextual lane and candidate-specific cut model before gate",
    }

    report = gen.build_report(
        planner_payload=planner_payload(),
        trace_audit=trace_audit(),
        miner_report=miner_with_pairing(pairing),
    )

    assert report["summary"]["gate_ready_package_count"] == 0
    assert report["summary"]["recommended_next_action"].startswith("do_not_create_blind_swap")
    assert report["instrumentation_route"]["status"] == "trace_or_runtime_probe_required"
    assert report["package_candidates"][0]["status"] == "trace_or_runtime_probe_required"


def test_completed_squee_probe_routes_to_access_density_model():
    pairing = {
        "candidate": "Gamble",
        "candidate_status": "high_frequency_runtime_ready_unexplored",
        "candidate_score": 74,
        "lane": "contextual",
        "cut_options": [],
        "recommended_action": "define contextual lane and candidate-specific cut model before gate",
    }
    squee_probe = {
        "summary": {
            "status": "squee_route_modeled_but_access_gap_remains",
            "modeled_when_accessed": True,
            "weak_material_missing_squee_seeds": ["7", "20260625"],
        }
    }

    report = gen.build_report(
        planner_payload=planner_payload(),
        trace_audit=trace_audit(),
        miner_report=miner_with_pairing(pairing),
        squee_probe=squee_probe,
        access_model={
            "summary": {
                "access_density_status": "squee_route_modeled_access_density_needed",
                "preflight_access_candidate_ready_count": 0,
                "hidden_retreat_runtime_model_status": "runtime_proposal_overlay_active",
                "hidden_retreat_package_status": "prepared_read_only_pending_apply_approval",
            }
        },
    )

    required = report["instrumentation_route"]["required_work"]
    assert required[0]["work_key"] == "squee_access_density_model"
    assert required[0]["target_seeds"] == ["7", "20260625"]
    assert report["summary"]["squee_probe_status"] == "squee_route_modeled_but_access_gap_remains"
    assert report["summary"]["access_model_status"] == "squee_route_modeled_access_density_needed"
    assert required[0]["preflight_access_candidate_ready_count"] == 0
    assert "read-only runtime proposal" in required[0]["reason"]
    assert "approved PG apply/sync" in required[0]["reason"]
    assert "squee_graveyard_entry_probe" not in {row["work_key"] for row in required}


def test_operational_work_queue_counts_blockers_and_prioritizes_runtime_gap_batch():
    miner = {
        "pairing_hypotheses": [
            {
                "candidate": "Apex of Power",
                "candidate_status": "high_frequency_runtime_ready_unexplored",
                "candidate_score": 92,
                "lane": "hand_filter",
                "cut_options": [
                    {
                        "card_name": "Loose Spell",
                        "status": "manual_review_needed",
                        "gate_readiness": "manual_review_needed",
                    }
                ],
            },
            {
                "candidate": "Gamble",
                "candidate_status": "high_frequency_runtime_ready_unexplored",
                "candidate_score": 74,
                "lane": "contextual",
                "cut_options": [],
            },
        ],
    }
    runtime_gap_queue = {
        "summary": {
            "blocked_runtime_rule_gap_count": 61,
            "family_count": 2,
            "validity_summary": {
                "ready_for_structured_pull_count": 9,
                "exact_xmage_found_count": 61,
            },
            "promotion_lane_counts": {"mapper_metadata_or_test_scenario_required": 52},
        },
        "family_queue": [
            {
                "family_id": "manual_model",
                "card_count": 52,
                "support_status": "manual_model_required",
                "batch_strategy": "not_batch_safe",
                "candidate_lane_counts": {"contextual": 30},
                "promotion_lane_counts": {"mapper_metadata_or_test_scenario_required": 52},
                "cards": [{"card_name": "Ancient Copper Dragon"}],
            }
        ],
    }

    report = gen.build_report(
        planner_payload=planner_payload(),
        trace_audit=trace_audit(),
        miner_report=miner,
        squee_probe={
            "summary": {
                "status": "squee_route_modeled_but_access_gap_remains",
                "modeled_when_accessed": True,
                "weak_material_missing_squee_seeds": ["7", "20260625"],
            }
        },
        access_model={
            "summary": {
                "access_density_status": "squee_route_modeled_access_density_needed",
                "preflight_access_candidate_ready_count": 0,
                "hidden_retreat_runtime_model_status": "runtime_proposal_overlay_active",
                "hidden_retreat_package_status": "prepared_read_only_pending_apply_approval",
            }
        },
        runtime_gap_queue=runtime_gap_queue,
    )

    queue = report["operational_work_queue"]
    assert report["summary"]["operational_work_count"] == 4
    assert report["summary"]["top_operational_work_key"] == "runtime_rule_gap_batch"
    assert queue[0]["work_key"] == "runtime_rule_gap_batch"
    assert queue[0]["blocked_runtime_rule_gap_count"] == 61
    assert queue[0]["runtime_ready_for_structured_pull_count"] == 9
    assert queue[0]["runtime_gap_context"]["top_families"][0]["family_id"] == "manual_model"
    assert "lorehold_runtime_gap_family_queue.py" in queue[0]["next_command"]

    by_work = {row["work_key"]: row for row in queue}
    assert by_work["hand_filter_non_core_cut_search"]["blocked_package_count"] == 1
    assert by_work["contextual_tutor_cut_model"]["blocked_package_count"] == 1
    assert by_work["squee_access_density_model"]["postgres_write_required_to_run"] is False
