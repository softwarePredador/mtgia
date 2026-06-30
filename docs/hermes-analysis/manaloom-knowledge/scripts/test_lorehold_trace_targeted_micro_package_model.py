from pathlib import Path

import lorehold_trace_targeted_micro_package_model as model


def test_trace_targeted_micro_package_model_blocks_without_seed_safe_cut():
    closing_trace = {
        "summary": {
            "gap_counts": {"miracle_cast_deficit": 3},
            "top_anchor_card_deficits": [{"card_name": "Sensei's Divining Top"}],
            "top_strategic_deficits": [{"event": "miracle_cast", "delta": 7}],
        },
        "hypothesis_queue": [
            {
                "hypothesis_key": "preserve_topdeck_miracle_floor_micro_package",
                "requirements": ["do not cut Sensei's Divining Top"],
                "target_gap_tags": ["miracle_cast_deficit"],
            }
        ],
    }
    seed_safe = {
        "summary": {
            "seed_safe_cut_ready_count": 0,
            "same_lane_only_count": 2,
            "same_lane_only_cut_cards": ["Creative Technique", "Bender's Waterskin"],
        },
        "seed_safe_cut_candidates": [],
        "same_lane_only_cut_slots": [
            {"card_name": "Creative Technique"},
            {"card_name": "Bender's Waterskin"},
        ],
    }

    payload = model.build_model(
        closing_window_trace=closing_trace,
        seed_safe_cut=seed_safe,
        closing_window_path=Path("/tmp/closing.json"),
        seed_safe_cut_path=Path("/tmp/seed.json"),
    )

    assert payload["postgres_writes"] is False
    assert payload["summary"]["ready_micro_package_count"] == 0
    assert payload["summary"]["blocked_hypothesis_count"] == 1
    assert payload["summary"]["recommended_next_action"] == (
        "freeze_607_current_champion_snapshot_until_new_cut_evidence"
    )
    assert payload["blocked_hypotheses"][0]["status"] == "blocked_no_seed_safe_cut"
    assert payload["blocked_hypotheses"][0]["same_lane_only_cut_cards"] == [
        "Creative Technique",
        "Bender's Waterskin",
    ]
    assert "miracle_cast_deficit" in payload["protected_anchor_evidence"]["gap_counts"]
