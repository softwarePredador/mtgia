from pathlib import Path

import lorehold_miracle_next_route_planner as planner


def _post_identity(*, include_brain=True, include_entreat=True, include_haze=True):
    rows = []
    if include_brain:
        rows.append(
            {
                "card_name": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "priority_rank": 1,
                "route_class": "runtime_or_manual_review",
                "required_contract": "single_card_runtime_contract_then_cut_safety",
                "deckbuilding_value": "charge counter and free-cast timing lesson",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    if include_entreat:
        rows.append(
            {
                "card_name": "Entreat the Angels",
                "lane": "miracle_finisher",
                "priority_rank": 1,
                "route_class": "runtime_or_manual_review",
                "required_contract": "miracle_token_runtime_contract_then_cut_safety",
                "deckbuilding_value": "miracle token finisher",
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    if include_haze:
        rows.append(
            {
                "card_name": "Haze of Rage",
                "lane": "storm_combo_pressure",
                "priority_rank": 2,
                "route_class": "combo_runtime_contract",
                "required_contract": "combo_runtime_contract_with_storm_kiln_artist",
                "deckbuilding_value": "storm combo pressure package",
                "blockers": [
                    "verified_battle_rule_missing",
                    "combo_runtime_required",
                    "named_safe_cut_missing",
                ],
                "battle_ready_now": False,
                "in_607": False,
            }
        )
    rows.append(
        {
            "card_name": "Burning Prophet",
            "lane": "spell_scry_pressure",
            "priority_rank": 3,
            "route_class": "runtime_or_manual_review",
            "required_contract": "spell_trigger_runtime_review_then_diagnostic_cut_check",
            "deckbuilding_value": "cheap spell velocity",
            "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            "battle_ready_now": False,
            "in_607": False,
        }
    )
    return {"summary": {"queue_card_count": len(rows)}, "cards": rows}


def _runtime_contract():
    return {
        "summary": {"runtime_contract_count": 3},
        "contracts": [
            {
                "card_name": "Entreat the Angels",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "best_first_runtime_contract_candidate",
                "required_runtime_slices": ["miracle", "tokens"],
            },
            {
                "card_name": "Brain in a Jar",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "blocked_requires_new_runtime_family",
                "required_runtime_slices": [
                    "charge_counter",
                    "exact_mana_value",
                    "free_cast",
                    "scry",
                ],
            },
            {
                "card_name": "Haze of Rage",
                "active_rule_count": 0,
                "xmage_class_found": True,
                "readiness": "blocked_complex_combo_runtime",
                "required_runtime_slices": ["storm", "buyback", "boost", "magecraft"],
            },
        ],
    }


def _candidate_queue():
    return {
        "summary": {"blocked_candidate_row_count": 3},
        "blocked_candidate_rows": [
            {
                "add_card": "Brain in a Jar",
                "lane": "topdeck_miracle_access",
                "matrix_cells": ["topdeck_miracle_access", "turn_cycle_miracle_mana"],
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            },
            {
                "add_card": "Entreat the Angels",
                "lane": "miracle_finisher",
                "matrix_cells": ["approach_finisher_conversion", "topdeck_miracle_access"],
                "blockers": ["verified_battle_rule_missing", "named_safe_cut_missing"],
            },
            {
                "add_card": "Haze of Rage",
                "lane": "storm_combo_pressure",
                "matrix_cells": ["pressure_survival_floor"],
                "blockers": [
                    "verified_battle_rule_missing",
                    "named_safe_cut_missing",
                    "combo_runtime_required",
                ],
            },
        ],
    }


def _entreat_scout(*, safe_cuts=0, active_rules=0, pg_writes=False):
    return {
        "summary": {
            "safe_cut_count": safe_cuts,
            "entreat_active_rule_count": active_rules,
            "runtime_primitive_ready": True,
            "postgres_writes_executed": pg_writes,
        }
    }


def _cut_miner(*, named_cuts=0):
    return {"summary": {"named_seed_safe_cut_count": named_cuts}}


def _paths():
    return {"post_identity": Path("/tmp/post_identity.json")}


def _build(**overrides):
    return planner.build_report(
        post_identity=overrides.get("post_identity", _post_identity()),
        runtime_contract=overrides.get("runtime_contract", _runtime_contract()),
        candidate_queue=overrides.get("candidate_queue", _candidate_queue()),
        entreat_scout=overrides.get("entreat_scout", _entreat_scout()),
        cut_miner=overrides.get("cut_miner", _cut_miner()),
        paths=_paths(),
    )


def test_current_like_state_selects_brain_without_deck_action() -> None:
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_brain_runtime_learning_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Brain in a Jar"
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["decision"]["deck_action_allowed"] is False
    assert payload["decision"]["postgres_writes_allowed"] is False


def test_entreat_ready_route_beats_brain_but_still_no_battle() -> None:
    payload = _build(
        entreat_scout=_entreat_scout(safe_cuts=1, active_rules=1, pg_writes=True),
        cut_miner=_cut_miner(named_cuts=1),
    )

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_entreat_refresh_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Entreat the Angels"
    assert payload["selected_route"]["route_state"] == "resume_entreat_matrix_refresh"
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_haze_becomes_fallback_when_brain_missing_and_entreat_blocked() -> None:
    payload = _build(post_identity=_post_identity(include_brain=False))

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_selected_haze_combo_learning_keep_607"
    )
    assert payload["summary"]["selected_card"] == "Haze of Rage"
    assert payload["selected_route"]["route_state"] == "combo_package_runtime_lesson"
    assert "commander_spellbook" in payload["selected_route"]["external_evidence"]["links"]


def test_no_candidates_blocks_route_planner() -> None:
    payload = _build(post_identity={"summary": {}, "cards": []})

    assert payload["summary"]["decision_status"] == (
        "miracle_next_route_planner_blocked_no_candidates_keep_607"
    )
    assert payload["summary"]["selected_card"] == ""
    assert payload["decision"]["deck_action_allowed"] is False


def test_markdown_surfaces_selected_route_and_closed_gates() -> None:
    markdown = planner.render_markdown(_build())

    assert "Selected card: `Brain in a Jar`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "draft Brain in a Jar runtime contract and cut miner" in markdown
    assert "https://scryfall.com/card/soi/252/brain-in-a-jar" in markdown
