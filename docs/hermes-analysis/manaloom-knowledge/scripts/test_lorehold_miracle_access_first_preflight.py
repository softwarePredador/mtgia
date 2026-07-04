from pathlib import Path

import lorehold_miracle_access_first_preflight as preflight


def sample_candidate(
    *,
    key="challenger_lorehold_spell_pressure_v1",
    wins=0,
    losses=1,
    h2h_wins=0,
    h2h_losses=1,
    miracle=4,
    topdeck=5,
    spell_cast=22,
    cost_paid=27,
    upkeep=5,
    anchor_delta_total=0,
    pressure_total=0,
    pressure_conversion_total=0,
    fast_pressure_wins=0,
    fast_pressure_losses=0,
):
    focus = {}
    for card, floor in {
        "Land Tax": 1,
        "Library of Leng": 0,
        "Lorehold, the Historian": 4,
        "Scroll Rack": 1,
        "Sensei's Divining Top": 2,
        "The Mind Stone": 2,
        "Urza's Saga": 1,
    }.items():
        focus[card] = {
            "candidate_accessed_games": floor,
            "baseline_accessed_games": floor,
            "delta_accessed_games": 0,
        }
    return {
        "candidate_key": key,
        "source_gate": "/tmp/gate.json",
        "candidate_record": {"wins": wins, "losses": losses, "stalls": 0, "games": wins + losses},
        "head_to_head_vs_607": {"wins": h2h_wins, "losses": h2h_losses, "stalls": 0, "games": h2h_wins + h2h_losses},
        "fast_pressure_slice": {
            "wins": fast_pressure_wins,
            "losses": fast_pressure_losses,
            "stalls": 0,
            "games": fast_pressure_wins + fast_pressure_losses,
        },
        "strategic_counts": {
            "miracle_cast": miracle,
            "topdeck_manipulation_activated": topdeck,
            "lorehold_spell_cast": spell_cast,
            "lorehold_cost_paid": cost_paid,
            "lorehold_upkeep_rummage": upkeep,
        },
        "baseline_strategic_counts": {
            "miracle_cast": 4,
            "topdeck_manipulation_activated": 5,
            "lorehold_spell_cast": 22,
            "lorehold_cost_paid": 27,
            "lorehold_upkeep_rummage": 5,
        },
        "focus_access_delta": focus,
        "topdeck_anchor_access_delta_total": anchor_delta_total,
        "pressure_card_event_total": pressure_total,
        "pressure_conversion_event_total": pressure_conversion_total,
        "failure_flags": [],
    }


def sample_trace_payload(candidates):
    return {
        "source_reports": ["docs/hermes-analysis/master_optimizer_reports/sample_gate.json"],
        "candidate_summaries": candidates,
    }


def test_derive_floors_from_607_baseline_counts():
    candidates = [
        sample_candidate(),
        sample_candidate(miracle=7, topdeck=8),
    ]

    floors = preflight.derive_strategic_floors(candidates)
    anchor_floors = preflight.derive_anchor_access_floors(candidates)

    assert floors["miracle_cast"] == 4
    assert floors["topdeck_manipulation_activated"] == 5
    assert anchor_floors["Lorehold, the Historian"] == 4
    assert anchor_floors["Sensei's Divining Top"] == 2


def test_blocks_candidate_that_loses_head_to_head_and_lacks_pressure_conversion():
    candidate = sample_candidate(pressure_total=2, pressure_conversion_total=0, h2h_wins=0, h2h_losses=1)
    floors = preflight.derive_strategic_floors([candidate])
    anchor_floors = preflight.derive_anchor_access_floors([candidate])

    assessed = preflight.assess_candidate(candidate, floors, anchor_floors)

    assert assessed["ready_for_next_gate"] is False
    assert "head_to_head_vs_607_not_won_or_tied" in assessed["blockers"]
    assert "pressure_conversion_not_proven" in assessed["blockers"]


def test_blocks_candidate_below_miracle_or_anchor_floor():
    candidate = sample_candidate(
        miracle=0,
        topdeck=0,
        anchor_delta_total=-2,
        pressure_total=0,
        pressure_conversion_total=0,
    )
    candidate["focus_access_delta"]["Scroll Rack"]["candidate_accessed_games"] = 0
    floors = preflight.derive_strategic_floors([candidate])
    anchor_floors = preflight.derive_anchor_access_floors([candidate])

    assessed = preflight.assess_candidate(candidate, floors, anchor_floors)

    assert "miracle_cast_below_607_floor" in assessed["blockers"]
    assert "topdeck_manipulation_activated_below_607_floor" in assessed["blockers"]
    assert "scroll_rack_access_below_607_floor" in assessed["blockers"]
    assert "aggregate_topdeck_anchor_access_regressed" in assessed["blockers"]


def test_allows_only_candidate_that_preserves_engine_and_ties_607():
    candidate = sample_candidate(
        wins=1,
        losses=0,
        h2h_wins=1,
        h2h_losses=0,
        pressure_total=2,
        pressure_conversion_total=1,
        fast_pressure_wins=1,
        fast_pressure_losses=0,
    )
    payload = preflight.build_payload(sample_trace_payload([candidate]), Path("/tmp/trace.json"))

    assert payload["status"] == "candidate_ready_for_miracle_access_first_gate"
    assert payload["summary"]["gate_ready_now_count"] == 1
    assert payload["decision"]["allow_new_natural_gate_now"] is True


def test_current_failed_candidates_keep_607_protected():
    blocked = sample_candidate(
        key="challenger_lorehold_spell_volume_access_depressure_v1",
        miracle=0,
        topdeck=0,
        spell_cast=13,
        cost_paid=19,
        upkeep=4,
        h2h_wins=0,
        h2h_losses=1,
        anchor_delta_total=-4,
    )
    blocked["failure_flags"] = ["miracle_trace_missing", "topdeck_activation_missing"]
    payload = preflight.build_payload(sample_trace_payload([blocked]), Path("/tmp/trace.json"))
    markdown = preflight.render_markdown(payload)

    assert payload["status"] == "no_current_candidate_passes_miracle_access_first_preflight"
    assert payload["summary"]["gate_ready_now_count"] == 0
    assert payload["decision"]["allow_new_natural_gate_now"] is False
    assert "miracle_access_first_shell_v1" in markdown
    assert "EDHREC optimized Topdeck Lorehold page" in markdown
