from pathlib import Path

import lorehold_topdeck_sidecar_cut_model_planner as planner


def _queue():
    return {
        "candidate_queue": [
            {
                "add_card": "Penance",
                "sidecar_tag": "topdeck_access_sidecar_primary",
                "priority": "P1_forced_access_diagnostic",
                "readiness_status": "needs_safe_cut_model",
                "allowed_next_test": "forced_access_diagnostic_only_until_miracle_access_floors_pass",
            },
            {
                "add_card": "Plateau",
                "sidecar_tag": "mana_base_safe_cut_model",
                "priority": "P1_safe_cut_model",
                "readiness_status": "needs_safe_cut_model",
                "allowed_next_test": "build_safe_cut_mana_source_model_before_any_battle_gate",
            },
            {
                "add_card": "Mana Vault",
                "sidecar_tag": "generic_staple_learning_only",
                "priority": "P3_learning_only",
                "readiness_status": "blocked_prior_reject",
            },
        ],
        "summary": {"queue_row_count": 3},
    }


def _value_model():
    return {
        "summary": {"mana_foundation": {"land_quantity": 34, "ramp_quantity": 15}},
        "all_card_values": [
            {
                "card_name": "Artist's Talent",
                "functional_tag": "draw",
                "lanes": ["draw"],
                "value_score": 10,
                "value_tier": "tier_3_role_filler_with_battle_context",
                "cut_policy": "review_with_exposure_trace_before_cut",
                "protected_anchor": False,
            },
            {
                "card_name": "Sensei's Divining Top",
                "functional_tag": "draw",
                "lanes": ["artifact", "draw", "topdeck_miracle_engine"],
                "value_score": 150,
                "value_tier": "tier_0_protected_engine_or_anchor",
                "cut_policy": "no_generic_cut_same_lane_battle_proof_required",
                "protected_anchor": True,
            },
            {
                "card_name": "Mountain // Mountain",
                "functional_tag": "land",
                "lanes": ["basic_floor", "land", "mana_base"],
                "value_score": 18,
                "value_tier": "tier_1_structural_floor",
                "cut_policy": "protect_floor_same_role_upgrade_and_gate_required",
                "protected_anchor": False,
            },
            {
                "card_name": "Command Tower",
                "functional_tag": "land",
                "lanes": ["land", "mana_base", "untapped_or_multiplayer_fixing"],
                "value_score": 28,
                "value_tier": "tier_1_structural_floor",
                "cut_policy": "protect_floor_same_role_upgrade_and_gate_required",
                "protected_anchor": False,
            },
        ],
    }


def _safe_cut(*, attempted=None):
    attempted = attempted or []
    return {
        "summary": {"seed_safe_cut_candidate_count": 0},
        "target_cut_assessments": [
            {"attempted_package_cuts": [{"cut": card} for card in attempted]},
        ],
    }


def _gap_floor_trace(*, blocked=None):
    blocked = blocked or []
    return {
        "summary": {
            "target_card_count": len(blocked),
            "target_with_floor_trace_count": len(blocked),
        },
        "target_floor_summaries": [
            {
                "card_name": card,
                "floor_trace_status": "floor_trace_found_cut_blocked",
                "cut_decision": "protect_cut_slot_until_same_lane_replacement_preserves_floor",
                "same_slot_607_win_candidate_loss_trace_count": 3,
                "positive_target_delta_trace_count": 2,
                "baseline_target_event_total": 11,
            }
            for card in blocked
        ],
    }


def _paths():
    return {
        "sidecar_queue": Path("/tmp/queue.json"),
        "value_model": Path("/tmp/value.json"),
        "safe_cut_miner": Path("/tmp/safe.json"),
        "gap_floor_trace_miner": Path("/tmp/gap_floor.json"),
    }


def _build(**overrides):
    return planner.build_report(
        sidecar_queue=overrides.get("sidecar_queue", _queue()),
        value_model=overrides.get("value_model", _value_model()),
        safe_cut_miner=overrides.get("safe_cut_miner", _safe_cut()),
        gap_floor_trace_miner=overrides.get("gap_floor_trace_miner", _gap_floor_trace()),
        paths=_paths(),
        probes_per_target=2,
    )


def test_current_like_planner_creates_review_probes_but_zero_safe_cuts():
    payload = _build()

    assert payload["status"] == (
        "topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607"
    )
    assert payload["summary"]["target_row_count"] == 2
    assert payload["summary"]["named_cut_probe_count"] == 3
    assert payload["summary"]["safe_cut_ready_count"] == 0
    assert payload["summary"]["floor_trace_cut_blocker_count"] == 0
    assert payload["decision"]["deck_action_allowed"] is False


def test_topdeck_probe_uses_draw_cut_and_keeps_protected_anchor_as_near_miss():
    payload = _build()
    penance = {row["add_card"]: row for row in payload["cut_model_targets"]}["Penance"]

    assert penance["candidate_cut_probes"][0]["cut_card"] == "Artist's Talent"
    assert penance["candidate_cut_probes"][0]["cut_usable_now"] is False
    assert penance["protected_near_misses"][0]["card_name"] == "Sensei's Divining Top"


def test_mana_probe_requires_land_floor_equivalence():
    payload = _build()
    plateau = {row["add_card"]: row for row in payload["cut_model_targets"]}["Plateau"]
    blockers = plateau["candidate_cut_probes"][0]["blockers"]

    assert plateau["candidate_cut_probes"][0]["cut_card"] == "Mountain // Mountain"
    assert "mana_source_floor_equivalence_required" in blockers
    assert "structural_floor_equivalence_required" in blockers


def test_prior_attempted_cut_gets_blocker_and_sorted_after_new_probe():
    payload = _build(safe_cut_miner=_safe_cut(attempted=["Artist's Talent"]))
    penance = {row["add_card"]: row for row in payload["cut_model_targets"]}["Penance"]

    assert "prior_attempt_or_blocked_package_cut" in penance["candidate_cut_probes"][0]["blockers"]
    assert penance["candidate_cut_probes"][0]["cut_usable_now"] is False


def test_floor_trace_blocked_cut_gets_explicit_blocker_and_evidence_summary():
    payload = _build(gap_floor_trace_miner=_gap_floor_trace(blocked=["Artist's Talent"]))
    penance = {row["add_card"]: row for row in payload["cut_model_targets"]}["Penance"]
    probe = penance["candidate_cut_probes"][0]

    assert payload["summary"]["floor_trace_cut_blocker_count"] == 1
    assert payload["summary"]["floor_trace_blocked_probe_count"] == 1
    assert probe["cut_card"] == "Artist's Talent"
    assert probe["floor_trace_blocked"] is True
    assert probe["floor_trace_summary"]["same_slot_607_win_candidate_loss_trace_count"] == 3
    assert "floor_trace_cut_blocked" in probe["blockers"]
    assert "requires_same_lane_replacement_floor_preservation" in probe["blockers"]
    assert probe["cut_usable_now"] is False


def test_markdown_surfaces_no_materialization_and_probe_names():
    markdown = planner.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Candidate deck materialization allowed now: `false`" in markdown
    assert "Floor trace cut blockers: `0`" in markdown
    assert "Artist's Talent" in markdown
    assert "Mountain // Mountain" in markdown
