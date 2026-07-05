from pathlib import Path

import lorehold_entreat_same_lane_cut_scout as scout


def _candidate_queue(*, include_entreat=True, matrix_blockers=28):
    rows = []
    if include_entreat:
        rows.append(
            {
                "add_card": "Entreat the Angels",
                "lane": "miracle_finisher",
                "blockers": [
                    "verified_battle_rule_missing",
                    "named_safe_cut_missing",
                    "matrix_contract_blockers_not_cleared",
                ],
            }
        )
    return {
        "summary": {
            "matrix_contract_blocker_count": matrix_blockers,
            "decision_status": "miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607",
        },
        "blocked_candidate_rows": rows,
    }


def _package(*, generated=True, applied=False):
    if not generated:
        return {}
    return {
        "postgres_writes_executed": applied,
        "proposal": {
            "card_name": "Entreat the Angels",
            "review_status": "verified",
            "execution_status": "auto",
            "mana_cost": "{X}{X}{W}{W}{W}",
            "logical_rule_key": "battle_rule_v1:unit",
            "effect_json": {
                "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1",
                "native_miracle_cost": "{X}{W}{W}",
            },
        },
    }


def _preflight(*, runtime_ready=True, active_rules=0):
    return {
        "status": (
            "entreat_x_token_runtime_and_rule_ready_cut_still_blocked_keep_607"
            if active_rules
            else "entreat_x_token_runtime_primitive_ready_rule_still_blocked_keep_607"
        ),
        "summary": {
            "runtime_primitive_ready": runtime_ready,
            "entreat_active_rule_count": active_rules,
            "entreat_active_rule_ready": active_rules > 0,
            "battle_ready_now_count": active_rules,
        },
    }


def _value_model(*, names=None):
    if names is None:
        names = ["Storm Herd", "Creative Technique"]
    return {
        "summary": {"quantity_total": 100},
        "all_card_values": [
            {
                "card_name": name,
                "functional_tag": "wincon",
                "lanes": ["instant_sorcery_spell", "miracle_conversion_finisher", "wincon"],
                "value_tier": "tier_0_protected_engine_or_anchor",
                "value_score": 138,
                "cut_policy": "no_generic_cut_same_lane_battle_proof_required",
                "protected_anchor": True,
                "runtime_ready": True,
            }
            for name in names
        ],
    }


def _cut_miner(*, safe=False):
    if safe:
        rows = [
            {
                "card_name": "Storm Herd",
                "lane": "wincon",
                "status": "ready",
                "classification": "seed_safe_cut_ready",
                "unique_exposure_count": 1,
                "direct_event_count": 0,
                "hard_stop_blockers": [],
                "soft_evidence_blockers": [],
                "other_blockers": [],
            }
        ]
    else:
        rows = [
            {
                "card_name": "Storm Herd",
                "lane": "big_spell_value",
                "status": "blocked",
                "classification": "closed_hard_stop_current_607",
                "unique_exposure_count": 25,
                "direct_event_count": 20,
                "hard_stop_blockers": ["cut_is_miracle_core_big_spell", "protected_cut"],
                "soft_evidence_blockers": ["manual_status_not_seed_safe"],
                "other_blockers": [],
            },
            {
                "card_name": "Creative Technique",
                "lane": "big_spell_value",
                "status": "same_lane_only_not_seed_safe",
                "classification": "closed_hard_stop_current_607",
                "unique_exposure_count": 58,
                "direct_event_count": 54,
                "hard_stop_blockers": ["prior_rejected_cut", "protected_cut"],
                "soft_evidence_blockers": ["same_lane_only_requires_concrete_same_lane_add"],
                "other_blockers": [],
            },
        ]
    return {"summary": {"named_seed_safe_cut_count": int(safe)}, "all_cut_rows": rows}


def _paths():
    return {"candidate_queue": Path("/tmp/candidate_queue.json")}


def _build(**overrides):
    return scout.build_report(
        candidate_queue=overrides.get("candidate_queue", _candidate_queue()),
        entreat_package=overrides.get("entreat_package", _package()),
        entreat_preflight=overrides.get("entreat_preflight", _preflight()),
        cut_miner=overrides.get("cut_miner", _cut_miner()),
        value_model=overrides.get("value_model", _value_model()),
        paths=_paths(),
    )


def test_current_like_state_blocks_entreat_without_safe_cut() -> None:
    payload = _build()

    assert payload["postgres_writes"] is False
    assert payload["deck_607_mutated"] is False
    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_scout_blocked_no_safe_cut_keep_607"
    )
    assert payload["summary"]["safe_cut_count"] == 0
    assert payload["summary"]["blocked_same_lane_cut_count"] == 2
    assert payload["summary"]["recommended_next_action"] == "do_not_score_entreat_until_pg_apply_and_safe_cut_evidence"
    assert payload["decision"]["named_safe_cut_required_before_scoring"] is True
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_active_rule_without_safe_cut_mines_cut_not_pg_apply() -> None:
    payload = _build(entreat_preflight=_preflight(active_rules=1))

    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_scout_blocked_no_safe_cut_keep_607"
    )
    assert payload["summary"]["postgres_writes_executed"] is True
    assert payload["summary"]["entreat_active_rule_ready"] is True
    assert payload["summary"]["recommended_next_action"] == "mine_entreat_named_same_lane_safe_cut_before_matrix_or_battle"
    assert payload["decision"]["pg_apply_required_before_battle"] is False


def test_synthetic_safe_cut_and_active_rule_can_only_feed_matrix_scoring() -> None:
    payload = _build(
        candidate_queue=_candidate_queue(matrix_blockers=0),
        entreat_package=_package(applied=True),
        entreat_preflight=_preflight(active_rules=1),
        cut_miner=_cut_miner(safe=True),
        value_model=_value_model(names=["Storm Herd"]),
    )

    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_candidate_ready_for_matrix_scoring_no_battle"
    )
    assert payload["summary"]["safe_cut_count"] == 1
    assert payload["summary"]["matrix_scoring_allowed_now"] is True
    assert payload["summary"]["candidate_deck_materialization_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_safe_cut_without_applied_rule_remains_blocked() -> None:
    payload = _build(
        candidate_queue=_candidate_queue(matrix_blockers=0),
        cut_miner=_cut_miner(safe=True),
        value_model=_value_model(names=["Storm Herd"]),
    )

    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_scout_blocked_rule_not_applied_no_battle"
    )
    assert payload["decision"]["pg_apply_required_before_battle"] is True


def test_missing_entreat_package_blocks_runtime_route() -> None:
    payload = _build(entreat_package=_package(generated=False))

    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_scout_blocked_runtime_package_missing"
    )
    assert payload["summary"]["package_generated"] is False


def test_missing_entreat_candidate_row_blocks_scout() -> None:
    payload = _build(candidate_queue=_candidate_queue(include_entreat=False))

    assert payload["summary"]["decision_status"] == (
        "entreat_same_lane_cut_scout_blocked_missing_entreat_candidate_row"
    )
    assert payload["summary"]["entreat_candidate_row_found"] is False


def test_markdown_surfaces_no_mutation_no_battle_and_blocked_rows() -> None:
    markdown = scout.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Natural battle gate allowed now: `false`" in markdown
    assert "Storm Herd" in markdown
    assert "Creative Technique" in markdown
