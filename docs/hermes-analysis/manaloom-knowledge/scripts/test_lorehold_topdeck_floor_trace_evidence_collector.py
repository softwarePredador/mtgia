from pathlib import Path

import lorehold_topdeck_floor_trace_evidence_collector as collector


def _trace_contract():
    return {
        "summary": {
            "trace_contract_ready": True,
            "target_card_count": 2,
        },
        "contract": {
            "target_cards": [
                {
                    "add_card": "Penance",
                    "trace_collection_allowed_now": True,
                    "blocked_before_matrix": ["missing_named_same_lane_cut"],
                    "baseline_floor_metrics": [{"metric": "miracle_cast"}],
                    "trace_requirements": ["candidate_card_drawn_or_accessed"],
                },
                {
                    "add_card": "Dragon's Rage Channeler",
                    "trace_collection_allowed_now": True,
                    "blocked_before_matrix": ["missing_named_same_lane_cut"],
                    "baseline_floor_metrics": [{"metric": "miracle_cast"}],
                    "trace_requirements": ["candidate_card_drawn_or_accessed"],
                },
            ]
        },
    }


def _forced_access():
    return {
        "summary": {"diagnostic_ready_count": 2},
        "candidates": [
            {
                "card_name": "Penance",
                "diagnostic_allowed_now": True,
                "learning_priority_rank": 1,
                "blockers_before_deck_action": ["needs_named_same_lane_safe_cut_model"],
                "external_evidence": {
                    "source": "Card Kingdom Lorehold synergy review",
                    "url": "https://example.test/penance",
                    "signal": "direct_hand_to_top_setup",
                    "role": "turns cards in hand into known top-library cards",
                    "risk": "card disadvantage unless setup converts",
                },
                "hypothesis": {
                    "runtime_ready": True,
                    "variant_deck_count": 4,
                    "variant_deck_ids": [609, 611, 613, 614],
                    "staple_tier": "not_format_staple",
                },
            },
            {
                "card_name": "Dragon's Rage Channeler",
                "diagnostic_allowed_now": True,
                "learning_priority_rank": 3,
                "blockers_before_deck_action": ["needs_named_same_lane_safe_cut_model"],
                "external_evidence": {"source": "EDHREC", "url": "https://example.test/drc"},
                "hypothesis": {"runtime_ready": True, "variant_deck_count": 5},
            },
        ],
    }


def _microbenchmark():
    return {
        "summary": {"runnable_now_count": 0},
        "microbenchmarks": [
            {
                "card_name": "Penance",
                "package_execution_status": "blocked_prior_reject_and_cut_safety",
                "prior_package_count": 2,
                "prior_reject_count": 2,
                "runnable_now": False,
                "primary_forced_access_mode": "opening_hand",
                "blockers": ["cut_safety_blocked"],
                "required_trace_signals": ["candidate_card_drawn_or_accessed", "miracle_cast"],
                "existing_packages": [
                    {
                        "package_key": "penance_topdeck_protection_cut_squelcher",
                        "cuts": ["Hexing Squelcher"],
                        "prior_delta_pp": -7.41,
                        "prior_evidence_status": "blocked_prior_reject",
                        "cut_safety_status": "blocked_cut_safety",
                        "status": "skipped_cut_safety",
                    }
                ],
            },
            {
                "card_name": "Dragon's Rage Channeler",
                "package_execution_status": "blocked_cut_safety_new_cut_required",
                "prior_package_count": 1,
                "prior_reject_count": 0,
                "runnable_now": False,
                "primary_forced_access_mode": "opening_hand",
                "blockers": ["cut_safety_blocked"],
            },
        ],
    }


def _safe_cut():
    return {
        "summary": {"seed_safe_cut_candidate_count": 0},
        "target_cut_assessments": [
            {
                "card_name": "Penance",
                "safe_cut_status": "no_current_safe_cut_for_target",
                "attempted_package_cut_count": 2,
                "seed_safe_same_lane_count": 0,
                "reviewable_same_lane_gap_count": 0,
                "attempted_package_cuts": [
                    {
                        "cut": "Hexing Squelcher",
                        "package_key": "penance_topdeck_protection_cut_squelcher",
                        "package_decision": "not_run_cut_safety_blocked",
                        "prior_delta_pp": -7.41,
                        "prior_evidence_status": "blocked_prior_reject",
                        "cut_safety_status": "blocked_cut_safety",
                    }
                ],
            },
            {
                "card_name": "Dragon's Rage Channeler",
                "safe_cut_status": "no_current_safe_cut_for_target",
                "attempted_package_cut_count": 1,
                "seed_safe_same_lane_count": 0,
                "reviewable_same_lane_gap_count": 0,
            },
        ],
    }


def _paths():
    return {
        "trace_contract": Path("/tmp/contract.json"),
        "forced_access_audit": Path("/tmp/audit.json"),
        "microbenchmark_plan": Path("/tmp/plan.json"),
        "safe_cut_miner": Path("/tmp/safe.json"),
    }


def _build(**overrides):
    return collector.build_report(
        trace_contract=overrides.get("trace_contract", _trace_contract()),
        forced_access_audit=overrides.get("forced_access_audit", _forced_access()),
        microbenchmark_plan=overrides.get("microbenchmark_plan", _microbenchmark()),
        safe_cut_miner=overrides.get("safe_cut_miner", _safe_cut()),
        paths=_paths(),
    )


def test_collects_trace_designs_but_blocks_execution():
    payload = _build()

    assert payload["status"] == "topdeck_floor_trace_evidence_collected_no_execution_keep_607"
    assert payload["summary"]["target_card_count"] == 2
    assert payload["summary"]["trace_collection_allowed_count"] == 2
    assert payload["summary"]["microbenchmark_runnable_count"] == 0
    assert payload["summary"]["seed_safe_same_lane_count"] == 0
    assert payload["summary"]["forced_access_allowed_now"] is False
    assert payload["decision"]["allow_deck_mutation_now"] is False


def test_prior_reject_and_cut_safety_are_classified_separately():
    payload = _build()
    rows = {row["card_name"]: row for row in payload["target_evidence_rows"]}

    assert rows["Penance"]["trace_evidence_status"] == (
        "prior_reject_requires_new_same_lane_cut_model"
    )
    assert rows["Penance"]["prior_reject_count"] == 2
    assert rows["Dragon's Rage Channeler"]["trace_evidence_status"] == (
        "trace_design_ready_but_cut_safety_blocked"
    )


def test_missing_input_blocks_collector():
    payload = _build(safe_cut_miner={})

    assert payload["status"] == "topdeck_floor_trace_evidence_inputs_missing_keep_607"
    assert "safe_cut_miner" in payload["summary"]["missing_inputs"]
    assert payload["summary"]["target_card_count"] == 0


def test_markdown_surfaces_no_execution_and_sources():
    markdown = collector.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Penance" in markdown
    assert "Dragon's Rage Channeler" in markdown
    assert "Forced access allowed now: `false`" in markdown
    assert "Scryfall" in markdown
