from pathlib import Path

import lorehold_young_pyromancer_pressure_window_trace_synthesis as synthesis


def _young_model(eligible=0):
    return {
        "status": "young_pyromancer_singleton_no_cut_keep_607",
        "summary": {
            "eligible_cut_count": eligible,
            "seed_safe_cut_ready_count": eligible,
            "package_status": "blocked_no_cut_or_hypothesis_capacity",
        },
    }


def _spell_trace(*, wins=0, losses=1, cards_by_result=None, status="pressure_trace_refutes_pressure_causality"):
    return {
        "status": status,
        "summary": {
            "tested_pressure_cards": ["Guttersnipe", "Young Pyromancer", "Monastery Mentor"],
            "wins_with_pressure_card_events": wins,
            "losses_with_pressure_card_events": losses,
            "pressure_cards_by_result": cards_by_result or {"loss": ["Young Pyromancer"]},
            "candidate_record": {"wins": 1, "losses": 3, "stalls": 0, "games": 4},
            "baseline_record": {"wins": 0, "losses": 4, "stalls": 0, "games": 4},
            "failure_modes": ["pressure_seen_only_in_losses"],
        },
        "decision": {"promotion_allowed": False},
    }


def _closing_trace(gaps=None):
    return {
        "summary": {
            "comparison_count": 13,
            "avg_607_turn_advantage": 10.15,
            "ready_micro_package_hypothesis_count": 3,
            "gap_counts": gaps
            or {
                "candidate_died_before_closing_window": 13,
                "miracle_cast_deficit": 13,
                "topdeck_activation_deficit": 9,
            },
            "top_strategic_deficits": [{"event": "miracle_cast", "delta_total": 71}],
            "top_anchor_card_deficits": [
                {"event": "topdeck_manipulation_activated:Sensei's Divining Top", "delta_total": 29}
            ],
        }
    }


def _miracle_trace(flags=None):
    return {
        "summary": {
            "blocking_failure_flags": flags
            if flags is not None
            else ["pressure_causality_unproven", "pressure_conversion_unproven"],
        }
    }


def _build(young=None, spell=None, closing=None, miracle=None):
    return synthesis.build_model(
        young_model=young or _young_model(),
        spell_pressure_trace=spell or _spell_trace(),
        closing_trace=closing or _closing_trace(),
        miracle_trace=miracle or _miracle_trace(),
        paths={"young_model": Path("/tmp/young.json")},
    )


def test_loss_only_young_pyromancer_trace_refutes_deck_action():
    payload = _build()

    assert payload["status"] == "young_pyromancer_pressure_window_refuted_no_deck_action"
    assert payload["summary"]["young_pyromancer_seen_only_in_losses"] is True
    assert payload["summary"]["promotion_allowed_now"] is False
    assert payload["diagnostic_contract"]["allowed_now"] is False


def test_gap_alignment_marks_engine_gaps_as_not_repaired_by_young_pyromancer():
    payload = _build()
    rows = {row["gap"]: row for row in payload["closing_window_gap_alignment"]}

    assert rows["candidate_died_before_closing_window"]["young_pyromancer_repair_status"] == (
        "partial_theoretical_pressure_body"
    )
    assert rows["miracle_cast_deficit"]["young_pyromancer_repair_status"] == "does_not_repair"
    assert rows["topdeck_activation_deficit"]["actionability"] == (
        "do_not_use_young_pyromancer_for_this_gap"
    )


def test_synthetic_positive_trace_with_cut_routes_to_structure_matrix():
    payload = _build(
        young=_young_model(eligible=1),
        spell=_spell_trace(
            wins=2,
            losses=0,
            cards_by_result={"win": ["Young Pyromancer"]},
            status="pressure_trace_supports_causality",
        ),
        miracle=_miracle_trace(flags=[]),
    )

    assert payload["status"] == (
        "young_pyromancer_pressure_window_gate_candidate_requires_structure_matrix"
    )
    assert payload["summary"]["recommended_next_action"] == (
        "run_structure_matrix_then_equal_gate_with_direct_card_use_requirements"
    )


def test_diagnostic_only_when_pressure_gap_exists_but_not_loss_only():
    payload = _build(
        spell=_spell_trace(
            wins=1,
            losses=0,
            cards_by_result={"win": ["Guttersnipe"]},
            status="pressure_trace_incomplete",
        ),
        miracle=_miracle_trace(flags=["pressure_causality_unproven"]),
    )

    assert payload["status"] == "young_pyromancer_pressure_window_diagnostic_only"
    assert payload["diagnostic_contract"]["allowed_now"] is True
    assert payload["diagnostic_contract"]["promotion_allowed"] is False


def test_markdown_surfaces_no_mutation_and_decision():
    markdown = synthesis.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "loss_only_pressure_trace_is_not_card_proof" in markdown
    assert "do_not_run_a_natural_young_pyromancer_gate_now" in markdown
