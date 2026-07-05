from pathlib import Path

import lorehold_topdeck_sidecar_candidate_queue as queue


def _post_route():
    return {
        "summary": {
            "selected_route": "topdeck_access_first_sidecar_shell",
            "one_for_one_cut_ready_count": 0,
        }
    }


def _hypotheses(*, include_ready=False):
    rows = [
        {
            "priority": "P1_forced_access_diagnostic",
            "card_name": "Penance",
            "example_functional_tag": "draw",
            "hypothesis_lanes": ["topdeck_miracle_setup"],
            "readiness_status": "needs_safe_cut_model",
            "allowed_next_test": "forced_access_diagnostic_only_until_miracle_access_floors_pass",
        },
        {
            "priority": "P1_safe_cut_model",
            "card_name": "Plateau",
            "example_functional_tag": "land",
            "hypothesis_lanes": ["mana_base_review"],
            "readiness_status": "needs_safe_cut_model",
            "allowed_next_test": "build_safe_cut_mana_source_model_before_any_battle_gate",
        },
        {
            "priority": "P3_learning_only",
            "card_name": "Mana Vault",
            "example_functional_tag": "ramp",
            "hypothesis_lanes": ["spell_chain_conversion"],
            "readiness_status": "blocked_prior_reject",
            "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
        },
        {
            "priority": "P3_learning_only",
            "card_name": "The One Ring",
            "example_functional_tag": "draw",
            "hypothesis_lanes": ["unclassified_variant_watchlist"],
            "readiness_status": "blocked_prior_reject",
            "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
        },
    ]
    if include_ready:
        rows.append(
            {
                "priority": "P1_forced_access_diagnostic",
                "card_name": "Unit Topdeck Tool",
                "example_functional_tag": "draw",
                "hypothesis_lanes": ["topdeck_miracle_setup"],
                "readiness_status": "candidate_row_ready",
                "proposed_cut_card": "Unit Same Lane Flex",
                "allowed_next_test": "feed_to_structure_matrix",
            }
        )
    return {"summary": {"hypothesis_count": len(rows)}, "hypotheses": rows}


def _matrix():
    return {
        "summary": {
            "matrix_scoring_allowed_now": False,
            "candidate_row_count": 0,
        }
    }


def _safe_cut():
    return {"summary": {"seed_safe_cut_candidate_count": 0, "reviewable_same_lane_gap_count": 0}}


def _nonanchor_cut():
    return {
        "summary": {
            "primary_target": "Dragon's Rage Channeler",
            "primary_target_model_status": "clean_prior_target_blocked_no_nonanchor_cut",
            "seed_safe_nonanchor_count": 0,
            "reviewable_nonanchor_gap_count": 0,
            "clean_prior_blocked_target_count": 1,
        },
        "target_cut_models": [
            {
                "card_name": "Dragon's Rage Channeler",
                "model_status": "clean_prior_target_blocked_no_nonanchor_cut",
                "same_lane_slot_count": 6,
                "seed_safe_nonanchor_count": 0,
                "reviewable_nonanchor_gap_count": 0,
                "prior_reject_count": 0,
            },
            {
                "card_name": "Penance",
                "model_status": "prior_reject_target_blocked_no_nonanchor_cut",
                "same_lane_slot_count": 1,
                "seed_safe_nonanchor_count": 0,
                "reviewable_nonanchor_gap_count": 0,
                "prior_reject_count": 2,
            },
        ],
    }


def _value_model():
    return {
        "summary": {
            "mana_foundation": {"land_quantity": 34, "ramp_quantity": 15},
            "lane_profile": {"topdeck_miracle_engine": 9},
        }
    }


def _paths():
    return {
        "post_safe_cut_route": Path("/tmp/route.json"),
        "hypothesis_queue": Path("/tmp/hypotheses.json"),
        "structure_matrix": Path("/tmp/matrix.json"),
        "safe_cut_miner": Path("/tmp/safe.json"),
        "nonanchor_cut_model": Path("/tmp/nonanchor.json"),
        "value_model": Path("/tmp/value.json"),
    }


def _build(**overrides):
    return queue.build_report(
        post_safe_cut_route=overrides.get("post_safe_cut_route", _post_route()),
        hypothesis_queue=overrides.get("hypothesis_queue", _hypotheses()),
        structure_matrix=overrides.get("structure_matrix", _matrix()),
        safe_cut_miner=overrides.get("safe_cut_miner", _safe_cut()),
        nonanchor_cut_model=overrides.get("nonanchor_cut_model", _nonanchor_cut()),
        value_model=overrides.get("value_model", _value_model()),
        paths=_paths(),
    )


def test_current_like_queue_has_learning_rows_but_zero_matrix_rows():
    payload = _build()

    assert payload["status"] == "topdeck_sidecar_candidate_queue_blocked_no_matrix_rows_keep_607"
    assert payload["summary"]["queue_row_count"] == 4
    assert payload["summary"]["matrix_candidate_row_eligible_count"] == 0
    assert payload["summary"]["nonanchor_primary_target"] == "Dragon's Rage Channeler"
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False


def test_topdeck_target_and_land_are_tagged_separately():
    payload = _build()
    rows = {row["add_card"]: row for row in payload["candidate_queue"]}

    assert rows["Penance"]["sidecar_tag"] == "topdeck_access_sidecar_primary"
    assert rows["Penance"]["nonanchor_model_status"] == "prior_reject_target_blocked_no_nonanchor_cut"
    assert "nonanchor_model_has_no_seed_safe_cut" in rows["Penance"]["blockers"]
    assert "prior_reject_requires_new_trace_hypothesis" in rows["Penance"]["blockers"]
    assert rows["Penance"]["expected_metric_lift"] == (
        "miracle_cast_and_topdeck_manipulation_floor_lift"
    )
    assert rows["Plateau"]["sidecar_tag"] == "mana_base_safe_cut_model"


def test_generic_staples_stay_learning_only_after_prior_reject():
    payload = _build()
    rows = {row["add_card"]: row for row in payload["candidate_queue"]}

    assert rows["Mana Vault"]["sidecar_tag"] == "generic_staple_learning_only"
    assert "prior_reject_requires_new_trace_hypothesis" in rows["Mana Vault"]["blockers"]
    assert rows["The One Ring"]["matrix_candidate_row_eligible_now"] is False
    assert rows["The One Ring"]["generic_staple_policy"]["lane"] == "draw_and_resource_density"


def test_ready_synthetic_row_exports_matrix_candidate_row_but_not_deck():
    payload = _build(hypothesis_queue=_hypotheses(include_ready=True))

    assert payload["status"] == "topdeck_sidecar_candidate_queue_has_matrix_rows_no_deck_materialization"
    assert payload["summary"]["matrix_candidate_row_eligible_count"] == 1
    assert payload["matrix_candidate_rows"][0]["add_card"] == "Unit Topdeck Tool"
    assert payload["matrix_candidate_rows"][0]["cut_card"] == "Unit Same Lane Flex"
    assert payload["decision"]["candidate_deck_materialization_allowed_now"] is False


def test_markdown_surfaces_blocked_materialization_and_staples():
    markdown = queue.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "Dragon's Rage Channeler" in markdown
    assert "Matrix candidate rows eligible: `0`" in markdown
