from pathlib import Path

import lorehold_topdeck_mana_trace_gap_scout as scout


def _value_model(include_hit=True):
    rows = [
        {
            "card_name": "Reforge the Soul",
            "quantity": 1,
            "functional_tag": "draw",
            "lanes": ["draw", "instant_sorcery_spell"],
            "value_tier": "tier_2_commander_contextual_synergy",
            "value_score": 13,
            "cut_policy": "same_lane_or_package_proof_required",
            "protected_anchor": False,
        },
        {
            "card_name": "Urza's Saga",
            "quantity": 1,
            "functional_tag": "land",
            "lanes": ["land", "topdeck_miracle_engine"],
            "value_tier": "tier_1_structural_floor",
            "value_score": 74,
            "cut_policy": "protect_floor_same_role_upgrade_and_gate_required",
            "protected_anchor": False,
        },
    ]
    if include_hit:
        rows.append(
            {
                "card_name": "Hit the Mother Lode",
                "quantity": 1,
                "functional_tag": "draw",
                "lanes": ["draw", "instant_sorcery_spell", "miracle_conversion_finisher"],
                "value_tier": "tier_2_commander_contextual_synergy",
                "value_score": 38,
                "cut_policy": "same_lane_or_package_proof_required",
                "protected_anchor": False,
            }
        )
    return {
        "summary": {"deck_id": 607, "card_rows": len(rows)},
        "external_research": [
            {
                "source": "EDHREC Optimized Topdeck Lorehold",
                "url": "https://edhrec.com/commanders/lorehold-the-historian/optimized/topdeck",
                "learning": "Topdeck plus spellslinger is the external context.",
            }
        ],
        "all_card_values": rows,
    }


def _exposure_profile():
    return {
        "summary": {"target_count": 3},
        "card_profiles": [
            {"card_name": "Hit the Mother Lode", "unique_exposure_count": 11, "direct_event_count": 7},
            {"card_name": "Reforge the Soul", "unique_exposure_count": 23, "direct_event_count": 15},
            {"card_name": "Urza's Saga", "unique_exposure_count": 2656, "direct_event_count": 2656},
        ],
    }


def _frontier():
    return {
        "summary": {
            "decision_status": "named_same_lane_cut_frontier_closed_no_safe_cut_keep_607",
            "topdeck_matrix_ready_probe_count": 0,
        },
        "topdeck_frontier": [
            {
                "add_card": "Dragon's Rage Channeler",
                "lowest_exposure_probe_cuts": [
                    {
                        "cut_card": "Reforge the Soul",
                        "evidence_status": "blocked_exposed_topdeck_role_probe",
                        "unique_exposure_count": 23,
                        "inferred_role": "draw_filter_value",
                        "blockers": [
                            "miracle_topdeck_floor_equivalence_required",
                            "probe_cut_has_material_exposure",
                        ],
                    }
                ],
            }
        ],
    }


def _probe_evidence():
    return {
        "summary": {
            "probe_row_count": 1,
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
        },
        "probe_evidence_rows": [
            {
                "add_card": "Dragon's Rage Channeler",
                "target_tag": "topdeck_access_sidecar_primary",
                "cut_card": "Reforge the Soul",
                "evidence_status": "blocked_exposed_topdeck_role_probe",
                "safe_cut_ready_now": False,
                "matrix_candidate_row_eligible_now": False,
                "exposure": {
                    "unique_exposure_count": 23,
                    "direct_event_count": 15,
                    "inferred_role": "draw_filter_value",
                },
                "blockers": ["probe_cut_has_material_exposure"],
            }
        ],
    }


def _mana_safe_model():
    return {
        "summary": {
            "model_ready_pair_count": 1,
            "diagnostic_pair_count": 1,
        },
        "top_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "status": "model_ready_for_candidate_materialization",
            }
        ],
        "top_diagnostic_pairs": [
            {
                "add": "Plateau",
                "cut": "Battlefield Forge",
                "status": "diagnostic_only",
            }
        ],
    }


def _mana_integrator():
    return {
        "summary": {
            "eligible_model_ready_pair_count": 0,
            "exact_rejected_pair_count": 1,
        },
        "annotated_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "learning_status": "blocked_exact_tested_decision",
                "decision_status": "reject_promotion_keep_607_current_baseline",
                "decision_blockers": ["natural_smoke_lost_to_607"],
            }
        ],
    }


def _paths():
    return {
        "frontier": Path("/tmp/frontier.json"),
        "value_model": Path("/tmp/value.json"),
        "exposure_profile": Path("/tmp/exposure.json"),
        "probe_evidence": Path("/tmp/probe.json"),
        "mana_safe_model": Path("/tmp/mana_safe.json"),
        "mana_decision_integrator": Path("/tmp/mana_integrator.json"),
    }


def _build(**overrides):
    return scout.build_report(
        frontier=overrides.get("frontier", _frontier()),
        value_model=overrides.get("value_model", _value_model()),
        exposure_profile=overrides.get("exposure_profile", _exposure_profile()),
        probe_evidence=overrides.get("probe_evidence", _probe_evidence()),
        mana_safe_model=overrides.get("mana_safe_model", _mana_safe_model()),
        mana_decision_integrator=overrides.get("mana_decision_integrator", _mana_integrator()),
        paths=_paths(),
    )


def test_unprobed_floor_sensitive_gap_keeps_607_closed():
    payload = _build()

    assert payload["status"] == "topdeck_mana_trace_gap_scout_found_unprobed_floor_sensitive_gaps_keep_607"
    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["unprobed_topdeck_gap_count"] == 1
    assert payload["summary"]["already_probed_topdeck_count"] == 1
    assert payload["summary"]["mana_exact_rejected_pair_count"] == 1
    assert payload["summary"]["mana_eligible_pair_count"] == 0
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    hit = next(row for row in payload["trace_gap_rows"] if row["card_name"] == "Hit the Mother Lode")
    assert hit["gap_status"] == "unprobed_low_exposure_floor_sensitive_trace_gap"
    assert "miracle_conversion_finisher_floor_unknown" in hit["blockers"]


def test_existing_probe_and_exact_reject_do_not_open_any_gate():
    payload = _build()
    reforge = next(row for row in payload["trace_gap_rows"] if row["card_name"] == "Reforge the Soul")

    assert reforge["gap_status"] == "already_probed_blocked"
    assert payload["mana_trace_gap"]["frontier_status"] == "mana_route_closed_by_exact_decisions"
    assert payload["mana_trace_gap"]["remaining_ready_pair_count_after_exact_reject_filter"] == 0
    assert payload["decision"]["structure_matrix_allowed_now"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_no_unprobed_gap_status_when_current_inputs_only_have_probed_rows():
    payload = _build(value_model=_value_model(include_hit=False))

    assert payload["status"] == "topdeck_mana_trace_gap_scout_no_new_gap_keep_607"
    assert payload["summary"]["unprobed_topdeck_gap_count"] == 0
    assert payload["summary"]["already_probed_topdeck_count"] == 1


def test_missing_input_blocks_scout():
    payload = _build(value_model={})

    assert payload["status"] == "topdeck_mana_trace_gap_scout_inputs_missing_keep_607"
    assert payload["summary"]["missing_inputs"] == ["value_model"]
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False


def test_markdown_surfaces_hit_mother_lode_and_plateau_reject():
    markdown = scout.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Hit the Mother Lode" in markdown
    assert "unprobed_low_exposure_floor_sensitive_trace_gap" in markdown
    assert "Plateau" in markdown
    assert "Radiant Summit" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
