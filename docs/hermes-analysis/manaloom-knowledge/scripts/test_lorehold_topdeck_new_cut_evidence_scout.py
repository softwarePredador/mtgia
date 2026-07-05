from pathlib import Path

import lorehold_topdeck_new_cut_evidence_scout as scout


def _router():
    return {
        "status": "post_named_frontier_next_evidence_router_learning_only_keep_607",
        "summary": {
            "selected_next_route": "topdeck_new_cut_evidence_scout",
            "recommended_next_action": "find_new_nonanchor_same_lane_cut_evidence_not_in_current_hard_blocked_slots",
        },
    }


def _nonanchor():
    return {
        "status": "topdeck_nonanchor_cut_model_none_found_keep_607",
        "summary": {
            "primary_target": "Dragon's Rage Channeler",
            "primary_target_model_status": "clean_prior_target_blocked_no_nonanchor_cut",
        },
        "target_cut_models": [
            {
                "card_name": "Dragon's Rage Channeler",
                "clean_prior_target": True,
                "model_status": "clean_prior_target_blocked_no_nonanchor_cut",
                "target_lanes": [
                    "contextual",
                    "spell_velocity",
                    "topdeck_miracle_setup",
                    "topdeck_setup",
                ],
                "top_blocked_same_lane_slots": [
                    {
                        "card_name": "Call Forth the Tempest",
                        "lane": "spell_velocity",
                        "unique_exposure_count": 8,
                        "hard_stop_blockers": [
                            "cut_is_miracle_core_big_spell",
                            "miracle_or_finisher_core",
                        ],
                    }
                ],
            }
        ],
    }


def _trace_cut_expander(*, reviewable_target=False):
    rows = [
        {
            "card_name": "Call Forth the Tempest",
            "lane": "spell_velocity",
            "actionability": "hard_blocked",
            "status": "blocked",
            "unique_exposure_count": 8,
            "all_blockers": [
                "cut_is_miracle_core_big_spell",
                "miracle_or_finisher_core",
            ],
            "recommended_action": "do_not_use_as_cut_under_current_contract",
        }
    ]
    if reviewable_target:
        rows.append(
            {
                "card_name": "Low Value Filter",
                "lane": "topdeck_setup",
                "actionability": "review_needed",
                "status": "unblocked_review",
                "unique_exposure_count": 4,
                "all_blockers": [],
                "recommended_action": "collect_new_trace_evidence",
            }
        )
    return {
        "summary": {
            "cut_slot_count": len(rows),
            "seed_safe_ready_count": 0,
            "reviewable_evidence_gap_count": 0,
        },
        "all_cut_slots": rows,
    }


def _value_model(*, reviewable_target=False):
    rows = [
        {
            "card_name": "Call Forth the Tempest",
            "value_score": 102,
            "functional_tag": "wincon",
            "lanes": ["instant_sorcery_spell", "miracle_conversion_finisher"],
            "cut_policy": "same_lane_or_package_proof_required",
            "protected_anchor": False,
            "runtime_ready": True,
        }
    ]
    if reviewable_target:
        rows.append(
            {
                "card_name": "Low Value Filter",
                "value_score": 9,
                "value_tier": "tier_3_role_filler_with_battle_context",
                "functional_tag": "draw",
                "lanes": ["topdeck_setup", "draw"],
                "cut_policy": "review_with_exposure_trace_before_cut",
                "protected_anchor": False,
                "runtime_ready": True,
            }
        )
    return {
        "summary": {
            "mana_foundation": {
                "land_quantity": 34,
                "ramp_quantity": 15,
                "mana_sources_land_plus_ramp": 49,
            },
            "role_profile": {
                "draw": 9,
                "land": 34,
                "protection": 12,
                "ramp": 15,
            },
        },
        "all_card_values": rows,
    }


def _exposure_profile(*, reviewable_target=False):
    rows = [
        {
            "card_name": "Call Forth the Tempest",
            "unique_exposure_count": 8,
            "direct_event_count": 4,
            "inferred_role": "ramp_engine",
        }
    ]
    if reviewable_target:
        rows.append(
            {
                "card_name": "Low Value Filter",
                "unique_exposure_count": 4,
                "direct_event_count": 1,
                "inferred_role": "draw_filter_value",
            }
        )
    return {"scan_summary": {"json_files_scanned": 2}, "card_profiles": rows}


def _paths():
    return {
        "post_named_router": Path("/tmp/router.json"),
        "nonanchor_model": Path("/tmp/nonanchor.json"),
        "trace_cut_expander": Path("/tmp/trace.json"),
        "value_model": Path("/tmp/value.json"),
        "exposure_profile": Path("/tmp/exposure.json"),
    }


def _build(**overrides):
    return scout.build_report(
        post_named_router=overrides.get("post_named_router", _router()),
        nonanchor_model=overrides.get("nonanchor_model", _nonanchor()),
        trace_cut_expander=overrides.get("trace_cut_expander", _trace_cut_expander()),
        value_model=overrides.get("value_model", _value_model()),
        exposure_profile=overrides.get("exposure_profile", _exposure_profile()),
        paths=_paths(),
    )


def test_current_closed_inputs_create_learning_only_drc_request():
    payload = _build()

    assert payload["status"] == "topdeck_new_cut_evidence_scout_learning_targets_only_keep_607"
    assert payload["summary"]["selected_next_route_from_router"] == "topdeck_new_cut_evidence_scout"
    assert payload["summary"]["primary_target"] == "Dragon's Rage Channeler"
    assert payload["summary"]["hard_blocked_same_lane_slot_count"] == 1
    assert payload["summary"]["internal_candidate_count"] == 0
    assert payload["summary"]["safe_cut_ready_count"] == 0
    assert payload["summary"]["matrix_candidate_row_eligible_count"] == 0
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["allow_deck_mutation_now"] is False
    assert payload["evidence_requests"][0]["request_key"] == (
        "dragon_rage_channeler_new_nonanchor_same_lane_cut_evidence"
    )


def test_missing_inputs_blocks_scout_without_execution():
    payload = _build(post_named_router={})

    assert payload["status"] == "topdeck_new_cut_evidence_scout_inputs_missing_keep_607"
    assert "post_named_router" in payload["summary"]["missing_inputs"]
    assert payload["summary"]["safe_cut_ready_count"] == 0
    assert payload["decision"]["allow_natural_battle_gate_now"] is False


def test_low_nonprotected_same_lane_target_is_review_only_not_safe_cut():
    payload = _build(
        trace_cut_expander=_trace_cut_expander(reviewable_target=True),
        value_model=_value_model(reviewable_target=True),
        exposure_profile=_exposure_profile(reviewable_target=True),
    )

    assert payload["status"] == "topdeck_new_cut_evidence_scout_review_only_targets_keep_607"
    assert payload["summary"]["internal_candidate_count"] == 1
    assert payload["summary"]["safe_cut_ready_count"] == 0
    target = payload["internal_evidence_targets"][0]
    assert target["card_name"] == "Low Value Filter"
    assert target["evidence_status"] == "review_only_same_lane_evidence_target"
    assert target["safe_cut_ready"] is False
    assert target["matrix_candidate_allowed_now"] is False
    assert target["natural_battle_gate_allowed_now"] is False


def test_markdown_surfaces_current_gates_and_external_context():
    markdown = scout.render_markdown(_build())

    assert "Dragon's Rage Channeler" in markdown
    assert "Hard-blocked same-lane slots: `1`" in markdown
    assert "Natural battle gate allowed: `false`" in markdown
    assert "collect_external_or_new_trace_evidence_for_drc_nonanchor_cut" in markdown
    assert "Scryfall Mana Vault" in markdown
    assert "EDHREC Lorehold, the Historian upgraded spellslinger" in markdown
