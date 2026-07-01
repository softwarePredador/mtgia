from pathlib import Path

import lorehold_deckbuilding_final_closure as closure


def test_final_closure_passes_only_when_607_contract_is_exhausted():
    payload = closure.build_closure(
        champion_snapshot={
            "status": "current_champion_snapshot",
            "summary": {
                "deck_id": 607,
                "total_cards": 100,
                "commander_count": 1,
                "land_count": 34,
                "protected_anchor_count": 9,
                "validation_error_count": 0,
            },
        },
        cut_evidence_expander={
            "summary": {
                "recommended_next_action": "no_cut_slot_to_expand_under_current_607_contract",
                "seed_safe_ready_count": 0,
                "reviewable_evidence_gap_count": 0,
                "hard_blocked_count": 92,
                "same_lane_hard_blocked_count": 2,
            }
        },
        micro_package_model={"summary": {"ready_micro_package_count": 0}},
        planner={
            "summary": {
                "recommended_next_action": "no_cut_slot_to_expand_under_current_607_contract"
            }
        },
        champion_snapshot_path=Path("/tmp/champion.json"),
        cut_evidence_expander_path=Path("/tmp/cuts.json"),
        micro_package_model_path=Path("/tmp/micro.json"),
        planner_path=Path("/tmp/planner.json"),
    )

    assert payload["status"] == "closed_current_607_champion"
    assert payload["validation"]["status"] == "pass"
    assert payload["summary"]["recommended_next_action"] == (
        "keep_607_closed_until_reopen_condition"
    )
    assert payload["final_decision"]["decision"] == (
        "keep_607_as_current_lorehold_champion_under_active_contract"
    )
    assert "do not run another one-for-one swap gate against 607" in payload[
        "final_decision"
    ]["forbidden_next_steps"]


def test_final_closure_blocks_when_cut_expander_has_reviewable_gap():
    payload = closure.build_closure(
        champion_snapshot={
            "status": "current_champion_snapshot",
            "summary": {
                "deck_id": 607,
                "total_cards": 100,
                "commander_count": 1,
                "validation_error_count": 0,
            },
        },
        cut_evidence_expander={
            "summary": {
                "recommended_next_action": "review_cut_safety_rows_for_evidence_gap_slots",
                "seed_safe_ready_count": 0,
                "reviewable_evidence_gap_count": 1,
            }
        },
        micro_package_model={"summary": {"ready_micro_package_count": 0}},
        planner={
            "summary": {
                "recommended_next_action": "review_cut_safety_rows_for_evidence_gap_slots"
            }
        },
        champion_snapshot_path=Path("/tmp/champion.json"),
        cut_evidence_expander_path=Path("/tmp/cuts.json"),
        micro_package_model_path=Path("/tmp/micro.json"),
        planner_path=Path("/tmp/planner.json"),
    )

    assert payload["status"] == "blocked"
    assert payload["validation"]["status"] == "fail"
    assert "cut evidence expander is not exhausted" in payload["validation"]["errors"]
