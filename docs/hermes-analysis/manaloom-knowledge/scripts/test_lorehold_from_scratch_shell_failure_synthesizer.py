from pathlib import Path

import lorehold_from_scratch_shell_failure_synthesizer as synth


def challenger_reports():
    return [
        (
            Path("/tmp/from_scratch.json"),
            {
                "candidates": [
                    {
                        "candidate_key": "challenger_lorehold_access_density_control_v1",
                        "candidate_name": "Access Density",
                        "plan_key": "access_density_control",
                        "required_cards": ["Enlightened Tutor", "Gamble"],
                        "missing_required_cards": [],
                        "commander_intent_alignment": {
                            "package_ranges": {
                                "hand_filter": {"status": "overfilled"},
                                "graveyard_recursion": {"status": "overfilled"},
                            }
                        },
                    }
                ]
            },
        )
    ]


def gate_report(*, forced_mode="none", candidate_wins=0, candidate_games=4):
    return (
        Path("/tmp/gate.json"),
        {
            "forced_access_mode": forced_mode,
            "results": [
                {
                    "deck_key": "deck_607",
                    "wins": 1,
                    "losses": 3,
                    "stalls": 0,
                    "games": candidate_games,
                    "win_rate": 25.0,
                    "telemetry": {
                        "strategic_games": {
                            "miracle_cast": {"games": 4},
                            "topdeck_manipulation_activated": {"games": 1},
                            "lorehold_spell_cast": {"games": 4},
                            "lorehold_upkeep_rummage": {"games": 4},
                        }
                    },
                },
                {
                    "deck_key": "challenger_lorehold_access_density_control_v1",
                    "wins": candidate_wins,
                    "losses": candidate_games - candidate_wins,
                    "stalls": 0,
                    "games": candidate_games,
                    "win_rate": 0.0,
                    "telemetry": {
                        "strategic_games": {
                            "miracle_cast": {"games": 2},
                            "topdeck_manipulation_activated": {"games": 1},
                            "lorehold_spell_cast": {"games": 3},
                            "lorehold_upkeep_rummage": {"games": 2},
                        },
                        "card_event_counts": {
                            "cost_paid:Enlightened Tutor": 3,
                            "spell_cast:Enlightened Tutor": 3,
                            "spell_resolved:Enlightened Tutor": 4,
                            "cost_paid:Gamble": 3,
                            "spell_cast:Gamble": 3,
                        },
                    },
                },
            ],
        },
    )


def test_synthesizer_blocks_rejected_forced_access_shells():
    payload = synth.synthesize(
        challenger_reports=challenger_reports(),
        gate_reports=[gate_report(forced_mode="opening_hand")],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "mine_closing_window_trace_before_next_shell"
    )
    assert payload["summary"]["can_run_next_battle_gate"] is False
    row = payload["shell_gate_rows"][0]
    assert row["status"] == "forced_access_rejected"
    assert "forced_access_no_conversion" in row["failure_modes"]
    assert "package_lanes_overfilled" in row["failure_modes"]
    assert row["package_card_events"]["Enlightened Tutor"]["cost_paid"] == 3


def test_synthesizer_routes_non_negative_natural_signal_to_confirmation():
    payload = synth.synthesize(
        challenger_reports=challenger_reports(),
        gate_reports=[gate_report(candidate_wins=2, candidate_games=24)],
    )

    assert payload["summary"]["recommended_next_action"] == (
        "confirm_non_negative_from_scratch_shell_signal"
    )
    assert payload["summary"]["can_run_next_battle_gate"] is True
    assert payload["shell_gate_rows"][0]["can_promote_from_gate"] is True
