from pathlib import Path

import lorehold_topdeck_safe_cut_miner as miner


def _micro_row(card, status="blocked_cut_safety_new_cut_required"):
    return {
        "card_name": card,
        "design_allowed_now": True,
        "package_execution_status": status,
        "existing_packages": [
            {
                "package_key": "pkg",
                "adds": [card],
                "cuts": ["Blocked Slot"],
                "decision": "not_run_cut_safety_blocked",
                "prior_evidence_status": "clear",
                "cut_safety_status": "blocked_cut_safety",
            }
        ],
    }


def _micro_plan():
    return {
        "microbenchmarks": [
            _micro_row("Penance", "blocked_prior_reject_and_cut_safety"),
            _micro_row("Dragon's Rage Channeler", "blocked_cut_safety_new_cut_required"),
            _micro_row(
                "Valakut Awakening // Valakut Stoneforge",
                "blocked_prior_reject_new_cut_required",
            ),
        ]
    }


def _trace_cut_expander(*, include_ready=False, include_reviewable=False):
    rows = [
        {
            "card_name": "Core Ramp",
            "lane": "early_mana",
            "actionability": "hard_blocked",
            "score": 30,
            "all_blockers": ["early_mana_floor_support"],
        }
    ]
    if include_ready:
        rows.append(
            {
                "card_name": "Quiet Filter",
                "lane": "hand_filter",
                "actionability": "seed_safe_ready",
                "status": "seed_safe_cut_ready",
                "score": 80,
                "all_blockers": [],
            }
        )
    if include_reviewable:
        rows.append(
            {
                "card_name": "Quiet Draw",
                "lane": "draw",
                "actionability": "reviewable_evidence_gap",
                "score": 60,
                "all_blockers": ["missing_cut_safety_row"],
            }
        )
    return {"summary": {"seed_safe_ready_count": int(include_ready)}, "all_cut_slots": rows}


def _paths():
    return {
        "microbenchmark_plan": Path("/tmp/micro.json"),
        "trace_cut_expander": Path("/tmp/cuts.json"),
    }


def _build(**overrides):
    return miner.build_report(
        microbenchmark_plan=overrides.get("microbenchmark_plan", _micro_plan()),
        trace_cut_expander=overrides.get("trace_cut_expander", _trace_cut_expander()),
        paths=_paths(),
    )


def test_current_like_no_safe_cut_keeps_607_and_blocks_execution():
    payload = _build()

    assert payload["status"] == "topdeck_safe_cut_miner_no_current_safe_cut_keep_607"
    assert payload["summary"]["seed_safe_cut_candidate_count"] == 0
    assert payload["summary"]["reviewable_same_lane_gap_count"] == 0
    assert payload["decision"]["allow_forced_access_execution_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_seed_safe_hand_filter_cut_is_assigned_to_valakut_lane():
    payload = _build(trace_cut_expander=_trace_cut_expander(include_ready=True))
    rows = {row["card_name"]: row for row in payload["target_cut_assessments"]}

    assert payload["status"] == "topdeck_safe_cut_miner_found_seed_safe_cut_review_required"
    assert rows["Valakut Awakening // Valakut Stoneforge"]["seed_safe_same_lane_count"] == 1
    assert rows["Valakut Awakening // Valakut Stoneforge"]["safe_cut_status"] == (
        "seed_safe_cut_available_for_microbenchmark"
    )


def test_reviewable_draw_gap_is_not_runnable_but_gets_reported():
    payload = _build(trace_cut_expander=_trace_cut_expander(include_reviewable=True))
    rows = {row["card_name"]: row for row in payload["target_cut_assessments"]}

    assert payload["status"] == "topdeck_safe_cut_miner_reviewable_gaps_keep_607"
    assert rows["Penance"]["reviewable_same_lane_gap_count"] == 1
    assert rows["Penance"]["safe_cut_status"] == "reviewable_same_lane_cut_gap"
    assert rows["Penance"]["microbenchmark_runnable_now"] is False


def test_prior_reject_status_overrides_generic_safe_cut_next_action():
    payload = _build(trace_cut_expander=_trace_cut_expander(include_ready=True))
    valakut = {
        row["card_name"]: row for row in payload["target_cut_assessments"]
    }["Valakut Awakening // Valakut Stoneforge"]

    assert valakut["next_action"] == (
        "do_not_retest_prior_pair; mine_new_cut_and_failure_hypothesis"
    )


def test_markdown_surfaces_attempted_cuts_and_no_mutation_boundary():
    markdown = miner.render_markdown(_build())

    assert "Lorehold Topdeck Safe Cut Miner" in markdown
    assert "- deck_607_mutated: `false`" in markdown
    assert "Blocked Slot" in markdown
    assert "allow_forced_access_execution_now: `false`" in markdown
