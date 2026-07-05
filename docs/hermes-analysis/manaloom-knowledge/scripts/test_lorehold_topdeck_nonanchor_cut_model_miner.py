from pathlib import Path

import lorehold_topdeck_nonanchor_cut_model_miner as miner


def _trace_evidence():
    return {
        "summary": {"target_card_count": 2},
        "target_evidence_rows": [
            {
                "card_name": "Dragon's Rage Channeler",
                "learning_priority_rank": 3,
                "trace_evidence_status": "trace_design_ready_but_cut_safety_blocked",
                "prior_reject_count": 0,
            },
            {
                "card_name": "Penance",
                "learning_priority_rank": 1,
                "trace_evidence_status": "prior_reject_requires_new_same_lane_cut_model",
                "prior_reject_count": 2,
            },
        ],
    }


def _safe_cut():
    return {
        "target_cut_assessments": [
            {
                "card_name": "Dragon's Rage Channeler",
                "target_lanes": ["spell_velocity", "contextual"],
            },
            {
                "card_name": "Penance",
                "target_lanes": ["draw", "protection", "contextual"],
            },
        ]
    }


def _trace_expander(*, include_reviewable=False, include_seed_safe=False):
    slots = [
        {
            "card_name": "Call Forth the Tempest",
            "lane": "spell_velocity",
            "actionability": "hard_blocked",
            "score": 102,
            "all_blockers": ["cut_is_miracle_core_big_spell", "structural_dependency"],
            "unique_exposure_count": 12,
        },
        {
            "card_name": "Hexing Squelcher",
            "lane": "contextual",
            "actionability": "hard_blocked",
            "score": 7,
            "all_blockers": ["prior_rejected_cut", "protected_cut"],
        },
        {
            "card_name": "Quiet Draw",
            "lane": "draw",
            "actionability": "hard_blocked",
            "score": 10,
            "all_blockers": ["measured_high_cut_exposure"],
        },
    ]
    if include_reviewable:
        slots.append(
            {
                "card_name": "Reviewable Velocity",
                "lane": "spell_velocity",
                "actionability": "reviewable_evidence_gap",
                "score": 50,
                "all_blockers": ["missing_cut_safety_row"],
            }
        )
    if include_seed_safe:
        slots.append(
            {
                "card_name": "Quiet Velocity",
                "lane": "spell_velocity",
                "actionability": "seed_safe_ready",
                "score": 70,
                "all_blockers": [],
            }
        )
    return {"summary": {"cut_slot_count": len(slots)}, "all_cut_slots": slots}


def _paths():
    return {
        "trace_evidence": Path("/tmp/trace.json"),
        "safe_cut_miner": Path("/tmp/safe.json"),
        "trace_cut_expander": Path("/tmp/expander.json"),
    }


def _build(**overrides):
    return miner.build_report(
        trace_evidence=overrides.get("trace_evidence", _trace_evidence()),
        safe_cut_miner=overrides.get("safe_cut_miner", _safe_cut()),
        trace_cut_expander=overrides.get("trace_cut_expander", _trace_expander()),
        paths=_paths(),
    )


def test_clean_prior_drc_is_primary_but_blocked_without_nonanchor_cut():
    payload = _build()

    assert payload["status"] == "topdeck_nonanchor_cut_model_none_found_keep_607"
    assert payload["summary"]["primary_target"] == "Dragon's Rage Channeler"
    assert payload["summary"]["primary_target_model_status"] == (
        "clean_prior_target_blocked_no_nonanchor_cut"
    )
    assert payload["summary"]["seed_safe_nonanchor_count"] == 0
    assert payload["decision"]["allow_forced_access_now"] is False


def test_reviewable_nonanchor_gap_is_reported_but_not_executable():
    payload = _build(trace_cut_expander=_trace_expander(include_reviewable=True))
    rows = {row["card_name"]: row for row in payload["target_cut_models"]}

    assert payload["status"] == "topdeck_nonanchor_cut_model_reviewable_gap_found_keep_607"
    assert rows["Dragon's Rage Channeler"]["reviewable_nonanchor_gap_count"] == 1
    assert payload["summary"]["forced_access_allowed_now"] is False


def test_seed_safe_nonanchor_candidate_still_requires_review():
    payload = _build(trace_cut_expander=_trace_expander(include_seed_safe=True))
    rows = {row["card_name"]: row for row in payload["target_cut_models"]}

    assert payload["status"] == "topdeck_nonanchor_cut_model_seed_safe_found_keep_607"
    assert rows["Dragon's Rage Channeler"]["seed_safe_nonanchor_count"] == 1
    assert rows["Dragon's Rage Channeler"]["deck_action_allowed_now"] is False


def test_missing_input_blocks_model():
    payload = _build(trace_cut_expander={})

    assert payload["status"] == "topdeck_nonanchor_cut_model_inputs_missing_keep_607"
    assert "trace_cut_expander" in payload["summary"]["missing_inputs"]


def test_markdown_surfaces_primary_blocked_slots_and_no_mutation():
    markdown = miner.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Dragon's Rage Channeler" in markdown
    assert "Call Forth the Tempest" in markdown
    assert "allow_forced_access_now: `false`" in markdown
