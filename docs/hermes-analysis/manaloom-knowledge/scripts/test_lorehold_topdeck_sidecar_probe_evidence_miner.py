from pathlib import Path

import lorehold_topdeck_sidecar_probe_evidence_miner as miner


def _planner():
    return {
        "summary": {"named_cut_probe_count": 3},
        "cut_model_targets": [
            {
                "add_card": "Penance",
                "sidecar_tag": "topdeck_access_sidecar_primary",
                "candidate_cut_probes": [
                    {
                        "cut_card": "Artist's Talent",
                        "cut_value_tier": "tier_3_role_filler_with_battle_context",
                        "cut_value_score": 10,
                        "blockers": ["requires_exposure_trace_before_safe_cut"],
                    }
                ],
            },
            {
                "add_card": "Plateau",
                "sidecar_tag": "mana_base_safe_cut_model",
                "candidate_cut_probes": [
                    {
                        "cut_card": "Mountain // Mountain",
                        "cut_value_tier": "tier_1_structural_floor",
                        "cut_value_score": 18,
                        "blockers": ["mana_source_floor_equivalence_required"],
                    }
                ],
            },
        ],
    }


def _exposure():
    return {
        "card_profiles": [
            {
                "card_name": "Artist's Talent",
                "unique_exposure_count": 535,
                "direct_event_count": 500,
                "summary_metric_count": 35,
                "inferred_role": "draw_filter_value",
                "role_confidence": "direct_event_or_rule",
                "decision": {"status": "review_required"},
                "role_signals": ["draw_filter_value"],
            },
            {
                "card_name": "Mountain // Mountain",
                "unique_exposure_count": 402,
                "direct_event_count": 402,
                "summary_metric_count": 0,
                "inferred_role": "runtime_ready_unexposed",
                "role_confidence": "rule_only",
                "decision": {"status": "review_required"},
                "role_signals": [],
            },
        ]
    }


def _mana_model():
    return {
        "summary": {"model_ready_pair_count": 1},
        "top_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "pair_score": 52,
                "status": "model_ready_for_candidate_materialization",
                "reasons": ["tempo_upgrade_preserves_color_and_fetch_target_type"],
            }
        ],
    }


def _integrator():
    return {
        "summary": {
            "exact_rejected_pair_count": 1,
            "eligible_model_ready_pair_count": 0,
        },
        "annotated_model_ready_pairs": [
            {
                "add": "Plateau",
                "cut": "Radiant Summit",
                "pair_score": 52,
                "learning_status": "blocked_exact_tested_decision",
                "decision_status": "reject_promotion_keep_607_current_baseline",
                "next_action": "do_not_retest_exact_pair_without_new_mana_trace_evidence",
            }
        ],
    }


def _paths():
    return {
        "cut_model_planner": Path("/tmp/planner.json"),
        "exposure_profile": Path("/tmp/exposure.json"),
        "mana_base_model": Path("/tmp/mana.json"),
        "mana_decision_integrator": Path("/tmp/integrator.json"),
    }


def _build(**overrides):
    return miner.build_report(
        cut_model_planner=overrides.get("cut_model_planner", _planner()),
        exposure_profile=overrides.get("exposure_profile", _exposure()),
        mana_base_model=overrides.get("mana_base_model", _mana_model()),
        mana_decision_integrator=overrides.get("mana_decision_integrator", _integrator()),
        paths=_paths(),
    )


def test_exposed_topdeck_probe_does_not_become_safe_cut():
    payload = _build()
    penance = {row["cut_card"]: row for row in payload["probe_evidence_rows"]}["Artist's Talent"]

    assert payload["status"] == "topdeck_sidecar_probe_evidence_no_safe_cut_keep_607"
    assert penance["evidence_status"] == "blocked_exposed_topdeck_role_probe"
    assert "probe_cut_has_material_exposure" in penance["blockers"]
    assert penance["safe_cut_ready_now"] is False


def test_generic_basic_land_probe_is_blocked_but_mana_model_ready_pair_is_reported():
    payload = _build()
    mountain = {row["cut_card"]: row for row in payload["probe_evidence_rows"]}["Mountain // Mountain"]

    assert mountain["evidence_status"] == "blocked_generic_mana_probe_not_pair_safe"
    assert "basic_land_floor_not_safe_from_probe" in mountain["blockers"]
    assert payload["summary"]["mana_model_ready_pair_count"] == 1
    assert payload["summary"]["mana_model_exact_rejected_pair_count"] == 1
    assert payload["summary"]["mana_model_eligible_pair_count"] == 0
    assert payload["dedicated_mana_model_ready_pairs"][0]["cut"] == "Radiant Summit"
    assert payload["dedicated_mana_decision_integrator_pairs"][0]["learning_status"] == (
        "blocked_exact_tested_decision"
    )
    assert payload["decision"]["candidate_deck_materialization_allowed_now"] is False


def test_missing_exposure_blocks_probe():
    exposure = {"card_profiles": []}
    payload = _build(
        exposure_profile=exposure,
        mana_base_model={"top_model_ready_pairs": []},
        mana_decision_integrator={"annotated_model_ready_pairs": []},
    )
    rows = {row["cut_card"]: row for row in payload["probe_evidence_rows"]}

    assert rows["Artist's Talent"]["evidence_status"] == "blocked_missing_exposure_evidence"
    assert "missing_current_exposure_profile_row" in rows["Artist's Talent"]["blockers"]


def test_markdown_surfaces_no_promotion_and_plateau_pair():
    markdown = miner.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "Safe-cut ready: `0`" in markdown
    assert "Plateau" in markdown
    assert "Radiant Summit" in markdown
    assert "Mana route status: `mana_route_closed_by_exact_decisions`" in markdown
