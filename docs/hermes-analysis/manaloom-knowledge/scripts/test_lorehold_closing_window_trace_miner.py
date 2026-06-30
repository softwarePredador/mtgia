from pathlib import Path

import lorehold_closing_window_trace_miner as miner


def gate_payload():
    return (
        Path("/tmp/gate.json"),
        {
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
                            "turns": 15,
                            "strategic_event_counts": {
                                "miracle_cast": 4,
                                "topdeck_manipulation_activated": 3,
                                "lorehold_spell_cast": 8,
                            },
                            "card_event_counts": {
                                "topdeck_manipulation_activated:Scroll Rack": 3,
                                "cost_paid:Bender's Waterskin": 1,
                                "spell_cast:Approach of the Second Sun": 1,
                            },
                        }
                    ],
                },
                {
                    "deck_key": "challenger_shell",
                    "game_results": [
                        {
                            "game_id": "challenger_shell:Winota:0",
                            "game_index": 0,
                            "opponent": "Winota",
                            "opponent_archetype": "aggro",
                            "reason": "life_zero|found=False|countered=0",
                            "result": "loss",
                            "turns": 8,
                            "strategic_event_counts": {
                                "miracle_cast": 1,
                                "topdeck_manipulation_activated": 0,
                                "lorehold_spell_cast": 2,
                            },
                            "card_event_counts": {},
                        }
                    ],
                },
            ]
        },
    )


def test_closing_window_trace_miner_compares_607_wins_to_candidate_losses():
    payload = miner.mine([gate_payload()])

    assert payload["summary"]["recommended_next_action"] == (
        "build_trace_targeted_micro_package_from_closing_window"
    )
    assert payload["summary"]["comparison_count"] == 1
    row = payload["closing_window_comparisons"][0]
    assert row["candidate_key"] == "challenger_shell"
    assert "candidate_died_before_closing_window" in row["gap_tags"]
    assert "topdeck_engine_card_deficit" in row["gap_tags"]
    assert row["positive_strategic_deltas"]["miracle_cast"] == 3
    assert payload["hypothesis_queue"][0]["status"] == "ready_for_micro_package_model"
