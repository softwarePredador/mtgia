from pathlib import Path

import lorehold_gap_floor_trace_miner as miner


def _scout(include_hit=True):
    rows = [
        {
            "card_name": "Call Forth the Tempest",
            "gap_status": "unprobed_low_exposure_floor_sensitive_trace_gap",
            "role": "miracle_conversion_finisher",
            "unique_exposure_count": 8,
            "direct_event_count": 4,
        }
    ]
    if include_hit:
        rows.append(
            {
                "card_name": "Hit the Mother Lode",
                "gap_status": "unprobed_low_exposure_floor_sensitive_trace_gap",
                "role": "miracle_conversion_finisher",
                "unique_exposure_count": 11,
                "direct_event_count": 7,
            }
        )
    rows.append(
        {
            "card_name": "Reforge the Soul",
            "gap_status": "already_probed_blocked",
            "role": "draw_filter_value",
            "unique_exposure_count": 23,
            "direct_event_count": 15,
        }
    )
    return {
        "summary": {"unprobed_topdeck_gap_count": 2 if include_hit else 1},
        "trace_gap_rows": rows,
    }


def _gate():
    return (
        Path("/tmp/gate.json"),
        {
            "simulation_seed": 999,
            "opponent_seed": 20260629,
            "results": [
                {
                    "deck_key": "deck_607",
                    "game_results": [
                        {
                            "game_id": "deck_607:Winota:0",
                            "game_index": 0,
                            "opponent": "Winota",
                            "opponent_archetype": "aggro",
                            "reason": "elimination",
                            "result": "win",
                            "turns": 12,
                            "strategic_event_counts": {
                                "miracle_cast": 2,
                                "topdeck_manipulation_activated": 1,
                                "lorehold_spell_cast": 5,
                            },
                            "card_event_counts": {
                                "miracle_cast:Hit the Mother Lode": 1,
                                "spell_resolved:Hit the Mother Lode": 1,
                                "spell_resolved:Call Forth the Tempest": 1,
                            },
                        }
                    ],
                },
                {
                    "deck_key": "candidate_test",
                    "game_results": [
                        {
                            "game_id": "candidate_test:Winota:0",
                            "game_index": 0,
                            "opponent": "Winota",
                            "opponent_archetype": "aggro",
                            "reason": "life_zero",
                            "result": "loss",
                            "turns": 7,
                            "strategic_event_counts": {
                                "miracle_cast": 0,
                                "topdeck_manipulation_activated": 0,
                                "lorehold_spell_cast": 1,
                            },
                            "card_event_counts": {
                                "spell_resolved:Call Forth the Tempest": 1,
                            },
                        }
                    ],
                },
            ],
        },
    )


def _build(**overrides):
    return miner.build_report(
        trace_gap_scout=overrides.get("trace_gap_scout", _scout()),
        gate_reports=overrides.get("gate_reports", [_gate()]),
        scout_path=Path("/tmp/scout.json"),
    )


def test_floor_trace_miner_finds_positive_delta_and_keeps_gates_closed():
    payload = _build()

    assert payload["status"] == "gap_floor_trace_miner_found_floor_evidence_keep_607"
    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["target_card_count"] == 2
    assert payload["summary"]["target_with_floor_trace_count"] == 1
    assert payload["summary"]["same_slot_607_win_candidate_loss_trace_count"] == 2
    assert payload["summary"]["positive_target_delta_trace_count"] == 1
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    hit = next(row for row in payload["target_floor_summaries"] if row["card_name"] == "Hit the Mother Lode")
    assert hit["floor_trace_status"] == "floor_trace_found_cut_blocked"
    assert hit["positive_target_delta_trace_count"] == 1
    assert hit["cut_decision"] == "protect_cut_slot_until_same_lane_replacement_preserves_floor"


def test_baseline_use_without_positive_delta_is_not_strong_floor_trace():
    payload = _build()
    call = next(row for row in payload["target_floor_summaries"] if row["card_name"] == "Call Forth the Tempest")

    assert call["same_slot_607_win_candidate_loss_trace_count"] == 1
    assert call["positive_target_delta_trace_count"] == 0
    assert call["floor_trace_status"] == "baseline_win_trace_found_but_no_positive_delta"
    assert call["cut_decision"] == "still_not_safe_cut_requires_stronger_delta_trace"


def test_already_probed_rows_are_not_targeted():
    payload = _build()

    assert {row["card_name"] for row in payload["target_floor_summaries"]} == {
        "Call Forth the Tempest",
        "Hit the Mother Lode",
    }


def test_missing_inputs_keep_607_closed():
    payload = _build(trace_gap_scout={})

    assert payload["status"] == "gap_floor_trace_miner_inputs_missing_keep_607"
    assert payload["summary"]["missing_inputs"] == ["trace_gap_scout"]
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False


def test_markdown_surfaces_floor_trace_and_no_deck_action():
    markdown = miner.render_markdown(_build())

    assert "Hit the Mother Lode" in markdown
    assert "floor_trace_found_cut_blocked" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
