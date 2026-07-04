from pathlib import Path

import lorehold_spell_pressure_trace_miner as miner


def sample_gate():
    return {
        "results": [
            {
                "deck_key": miner.BASELINE_KEY,
                "wins": 0,
                "losses": 2,
                "stalls": 0,
                "games": 2,
                "game_results": [],
            },
            {
                "deck_key": miner.CANDIDATE_KEY,
                "wins": 1,
                "losses": 1,
                "stalls": 0,
                "games": 2,
                "game_results": [
                    {
                        "game_id": f"{miner.CANDIDATE_KEY}:Sisay, Weatherlight Captain #61 (real):0",
                        "opponent": "Sisay, Weatherlight Captain #61 (real)",
                        "result": "win",
                        "turns": 17,
                        "reason": "elimination",
                        "strategic_event_counts": {
                            "discard_to_top_replacement": 12,
                            "lorehold_spell_cast": 20,
                            "lorehold_upkeep_rummage": 12,
                            "miracle_cast": 5,
                            "topdeck_manipulation_activated": 8,
                        },
                        "card_event_counts": {
                            "spell_cast:Scroll Rack": 1,
                            "spell_cast:Sensei's Divining Top": 2,
                            "spell_resolved:Mizzix's Mastery": 1,
                            "topdeck_manipulation_activated:Scroll Rack": 7,
                        },
                    },
                    {
                        "game_id": f"{miner.CANDIDATE_KEY}:Vivi Ornitier #99 (real):0",
                        "opponent": "Vivi Ornitier #99 (real)",
                        "result": "loss",
                        "turns": 6,
                        "reason": "life_zero",
                        "strategic_event_counts": {"lorehold_spell_cast": 3},
                        "card_event_counts": {
                            "cost_paid:Young Pyromancer": 1,
                            "spell_cast:Young Pyromancer": 1,
                            "spell_resolved:Young Pyromancer": 1,
                        },
                    },
                ],
            },
        ]
    }


def sample_decision():
    return {
        "summary": {
            "baseline_rank": 1,
            "candidate_rank": 2,
            "confirmation_allowed": False,
        }
    }


def sample_matrix(candidate_key=miner.CANDIDATE_KEY):
    return {"ranked_deck_keys": [miner.BASELINE_KEY, candidate_key]}


def build_payload():
    return miner.build_payload(
        gate=sample_gate(),
        decision=sample_decision(),
        matrix=sample_matrix(),
        gate_path=Path("/tmp/gate.json"),
        decision_path=Path("/tmp/decision.json"),
        matrix_path=Path("/tmp/matrix.json"),
    )


def test_miner_refutes_pressure_causality_when_only_win_has_no_pressure_events():
    payload = build_payload()

    assert payload["status"] == "pressure_trace_refutes_pressure_causality"
    assert payload["summary"]["wins_with_pressure_card_events"] == 0
    assert payload["summary"]["losses_with_pressure_card_events"] == 1
    assert payload["summary"]["pressure_cards_by_result"] == {"loss": ["Young Pyromancer"]}
    assert "winning_game_has_no_pressure_card_events" in payload["summary"]["failure_modes"]
    assert "pressure_seen_only_in_losses" in payload["summary"]["failure_modes"]
    assert "sisay_win_carried_by_core_topdeck_miracle_engine" in payload["summary"]["failure_modes"]


def test_sisay_win_trace_surfaces_core_engine_events_without_pressure_events():
    payload = build_payload()
    sisay = payload["sisay_win_trace"]

    assert sisay["opponent"].startswith("Sisay")
    assert sisay["pressure_card_event_counts"] == {}
    assert sisay["core_strategic_event_counts"]["miracle_cast"] == 5
    assert sisay["core_card_event_counts"]["topdeck_manipulation_activated:Scroll Rack"] == 7
    assert sisay["core_event_total"] > 0


def test_priority_update_demotes_token_pressure_and_prefers_storm_kiln_probe():
    payload = build_payload()
    update = payload["deckbuilding_priority_update"]

    assert update["protect_607_baseline"] is True
    assert "Young Pyromancer" in update["demote_until_proven"]
    assert "Monastery Mentor" in update["demote_until_proven"]
    assert update["next_pressure_priority"] == ["Guttersnipe", "Storm-Kiln Artist"]
    assert payload["decision"]["promotion_allowed"] is False


def test_markdown_surfaces_external_learning_and_decision():
    markdown = miner.render_markdown(build_payload())

    assert "Lorehold Spell Pressure Trace Miner" in markdown
    assert "EDHREC average optimized spellslinger" in markdown
    assert "Storm-Kiln Artist" in markdown
    assert "do_not_confirm_current_spell_pressure_topdeck_shell" in markdown


def test_cost_paid_only_storm_kiln_win_is_presence_not_conversion_proof():
    candidate_key = "challenger_lorehold_spell_pressure_mana_conversion_v1"
    gate = {
        "results": [
            {
                "deck_key": miner.BASELINE_KEY,
                "wins": 0,
                "losses": 1,
                "stalls": 0,
                "games": 1,
                "game_results": [],
            },
            {
                "deck_key": candidate_key,
                "wins": 1,
                "losses": 0,
                "stalls": 0,
                "games": 1,
                "game_results": [
                    {
                        "game_id": f"{candidate_key}:Vivi Ornitier #99 (real):0",
                        "opponent": "Vivi Ornitier #99 (real)",
                        "result": "win",
                        "turns": 13,
                        "reason": "elimination",
                        "strategic_event_counts": {"miracle_cast": 4, "lorehold_spell_cast": 11},
                        "card_event_counts": {"cost_paid:Storm-Kiln Artist": 1},
                    }
                ],
            },
        ]
    }

    payload = miner.build_payload(
        gate=gate,
        decision={},
        matrix=sample_matrix(candidate_key),
        gate_path=Path("/tmp/gate.json"),
        decision_path=Path("/tmp/decision.json"),
        matrix_path=Path("/tmp/matrix.json"),
        candidate_key=candidate_key,
        tested_pressure_cards=("Guttersnipe", "Storm-Kiln Artist"),
        next_pressure_priority_cards=("Guttersnipe", "Storm-Kiln Artist"),
    )

    assert payload["status"] == "pressure_trace_partial_presence_not_conversion_proof"
    assert payload["summary"]["wins_with_pressure_card_events"] == 1
    assert payload["summary"]["wins_with_pressure_conversion_events"] == 0
    assert payload["summary"]["pressure_cards_by_result"] == {"win": ["Storm-Kiln Artist"]}
    assert "pressure_seen_without_conversion_events" in payload["summary"]["failure_modes"]
