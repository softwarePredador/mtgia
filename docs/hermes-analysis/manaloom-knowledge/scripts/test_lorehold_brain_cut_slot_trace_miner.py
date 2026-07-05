from pathlib import Path

import lorehold_brain_cut_slot_trace_miner as miner


def _safe_cut_gap():
    return {
        "summary": {
            "decision_status": "brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607",
        },
        "same_lane_cut_rows": [
            {
                "card_name": "Molecule Man",
                "gap_category": "prior_rejected_protected_slot",
                "cut_lane": "draw",
                "functional_tag": "draw",
                "lanes": ["draw", "topdeck_miracle_engine"],
                "unique_exposure_count": 102,
                "direct_event_count": 101,
                "value_tier": "tier_0_protected_engine_or_anchor",
            },
            {
                "card_name": "The Mind Stone",
                "gap_category": "protected_structural_floor",
                "cut_lane": "early_mana",
                "functional_tag": "ramp",
                "lanes": ["artifact", "ramp", "topdeck_miracle_engine"],
                "unique_exposure_count": 2312,
                "direct_event_count": 2266,
                "value_tier": "tier_0_protected_engine_or_anchor",
            },
            {
                "card_name": "Scroll Rack",
                "gap_category": "protected_core_topdeck_engine",
                "cut_lane": "draw",
                "functional_tag": "draw",
                "lanes": ["artifact", "draw", "topdeck_miracle_engine"],
                "unique_exposure_count": 2957,
                "direct_event_count": 2745,
                "value_tier": "tier_0_protected_engine_or_anchor",
            },
        ],
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
                                "topdeck_manipulation_activated": 3,
                                "lorehold_spell_cast": 5,
                            },
                            "card_event_counts": {
                                "spell_cast:Molecule Man": 1,
                                "trigger_resolved:Molecule Man": 2,
                                "activated:The Mind Stone": 1,
                            },
                        }
                    ],
                },
                {
                    "deck_key": "candidate_brain_probe",
                    "game_results": [
                        {
                            "game_id": "candidate_brain_probe:Winota:0",
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
                                "activated:The Mind Stone": 1,
                            },
                        }
                    ],
                },
            ],
        },
    )


def _build(**overrides):
    return miner.build_report(
        safe_cut_gap=overrides.get("safe_cut_gap", _safe_cut_gap()),
        gate_reports=overrides.get("gate_reports", [_gate()]),
        safe_cut_gap_path=Path("/tmp/brain_safe_cut_gap.json"),
    )


def test_brain_cut_slot_trace_miner_finds_positive_floor_trace_and_keeps_gates_closed():
    payload = _build()

    assert payload["status"] == "brain_cut_slot_trace_miner_found_floor_evidence_keep_607"
    assert payload["postgres_writes"] is False
    assert payload["source_db_mutated"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["target_card_count"] == 3
    assert payload["summary"]["target_with_floor_trace_count"] == 1
    assert payload["summary"]["same_slot_607_win_candidate_loss_trace_count"] == 2
    assert payload["summary"]["positive_target_delta_trace_count"] == 1
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False

    molecule = next(row for row in payload["target_floor_summaries"] if row["card_name"] == "Molecule Man")
    assert molecule["floor_trace_status"] == "brain_cut_slot_floor_trace_found_cut_blocked"
    assert molecule["positive_target_delta_trace_count"] == 1
    assert molecule["cut_decision"] == (
        "protect_brain_cut_slot_until_same_lane_replacement_preserves_floor"
    )


def test_baseline_use_without_positive_delta_is_not_unlocked_cut():
    payload = _build()
    mind_stone = next(row for row in payload["target_floor_summaries"] if row["card_name"] == "The Mind Stone")

    assert mind_stone["same_slot_607_win_candidate_loss_trace_count"] == 1
    assert mind_stone["positive_target_delta_trace_count"] == 0
    assert mind_stone["floor_trace_status"] == "brain_cut_slot_baseline_use_without_positive_delta"
    assert mind_stone["cut_decision"] == (
        "still_not_safe_cut_requires_stronger_same_slot_delta_trace"
    )


def test_no_trace_slot_remains_missing():
    payload = _build()
    scroll = next(row for row in payload["target_floor_summaries"] if row["card_name"] == "Scroll Rack")

    assert scroll["same_slot_607_win_candidate_loss_trace_count"] == 0
    assert scroll["floor_trace_status"] == "brain_cut_slot_no_same_slot_trace_found"
    assert scroll["cut_decision"] == "still_not_safe_cut_collect_targeted_brain_cut_slot_trace"


def test_missing_inputs_keep_607_closed():
    payload = _build(safe_cut_gap={})

    assert payload["status"] == "brain_cut_slot_trace_miner_inputs_missing_keep_607"
    assert payload["summary"]["missing_inputs"] == ["brain_safe_cut_gap"]
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False


def test_markdown_surfaces_brain_cut_trace_and_no_deck_action():
    markdown = miner.render_markdown(_build())

    assert "Molecule Man" in markdown
    assert "brain_cut_slot_floor_trace_found_cut_blocked" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
    assert "postgres_writes_allowed: `false`" in markdown
