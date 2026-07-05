from pathlib import Path

import lorehold_pressure_safe_cut_expansion_model as model


def seed_safe_report():
    return {
        "summary": {
            "seed_safe_cut_ready_count": 0,
            "same_lane_only_count": 2,
            "same_lane_only_cut_cards": ["Creative Technique", "Bender's Waterskin"],
        },
        "seed_safe_cut_candidates": [],
        "same_lane_only_cut_slots": [
            {
                "card_name": "Creative Technique",
                "lane": "big_spell_value",
                "manual_status": "same_lane_only",
                "status": "same_lane_only_not_seed_safe",
                "unique_exposure_count": 58,
                "direct_event_count": 54,
                "blockers": ["same_lane_only_requires_concrete_same_lane_add", "protected_cut"],
            },
            {
                "card_name": "Bender's Waterskin",
                "lane": "early_mana",
                "manual_status": "same_lane_only",
                "status": "same_lane_only_not_seed_safe",
                "unique_exposure_count": 268,
                "direct_event_count": 216,
                "blockers": ["same_lane_only_requires_concrete_same_lane_add", "measured_high_cut_exposure"],
            },
        ],
    }


def trace_expander():
    return {
        "summary": {
            "hard_blocked_count": 92,
            "reviewable_evidence_gap_count": 0,
            "top_near_miss_cut_cards": [
                "Creative Technique",
                "Bender's Waterskin",
                "Generous Gift",
            ],
        },
        "hard_blocked_queue": [
            {
                "card_name": "Generous Gift",
                "lane": "removal",
                "manual_status": "measured_high_cut_exposure",
                "status": "blocked",
                "unique_exposure_count": 52,
                "direct_event_count": 16,
                "blockers": ["measured_high_cut_exposure", "prior_rejected_cut"],
            }
        ],
    }


def pressure_micro():
    return {
        "summary": {"gate_ready_package_count": 0, "natural_trigger_cards": ["Guttersnipe", "Young Pyromancer"]},
        "micro_package_queue": [
            {
                "package_key": "pressure_natural_trigger_pair_guttersnipe_young_pyromancer",
                "adds": ["Guttersnipe", "Young Pyromancer"],
                "required_cut_count": 2,
                "natural_trigger_count": 13,
                "status": "blocked_no_seed_safe_cut",
                "gate_ready": False,
            }
        ],
    }


def pressure_contract():
    return {
        "summary": {"primary_package_size": 4},
        "primary_package_preflight": [
            {
                "card_name": "Monastery Mentor",
                "role": "token_pressure_spell_payoff",
                "preflight_status": "pass",
                "commander_legal_status": "legal",
                "verified_auto_battle_rule_count": 1,
                "value_test": "pressure payoff",
            },
            {
                "card_name": "Young Pyromancer",
                "role": "low_curve_token_pressure_payoff",
                "preflight_status": "pass",
                "commander_legal_status": "legal",
                "verified_auto_battle_rule_count": 1,
                "value_test": "low curve pressure",
            },
            {
                "card_name": "Guttersnipe",
                "role": "noncombat_spell_pressure_payoff",
                "preflight_status": "pass",
                "commander_legal_status": "legal",
                "verified_auto_battle_rule_count": 1,
                "value_test": "direct pressure",
            },
            {
                "card_name": "Storm-Kiln Artist",
                "role": "spell_payoff_mana_extension",
                "preflight_status": "pass",
                "commander_legal_status": "legal",
                "verified_auto_battle_rule_count": 1,
                "value_test": "mana extension",
            },
        ],
    }


def build_payload():
    return model.build_model(
        router={"status": "post_mana_base_route_cut_safety_expansion_required"},
        value_model={
            "summary": {
                "mana_foundation": {"land_quantity": 34, "ramp_quantity": 15},
                "lane_profile": {"land": 34, "ramp": 15, "draw": 9},
            }
        },
        seed_safe_report=seed_safe_report(),
        trace_expander=trace_expander(),
        pressure_micro=pressure_micro(),
        pressure_resolver={"summary": {"gate_ready_cut_count": 0, "primary_add_count": 4}},
        pressure_contract=pressure_contract(),
        paths={"router": Path("/tmp/router.json")},
    )


def test_blocks_pressure_without_seed_safe_cuts():
    payload = build_payload()

    assert payload["status"] == "pressure_cut_expansion_no_seed_safe_cut_keep_607"
    assert payload["summary"]["seed_safe_cut_ready_count"] == 0
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_pressure_package_is_research_until_named_cuts_exist():
    payload = build_payload()
    routes = {row["route_key"]: row for row in payload["pressure_package_routes"]}

    assert routes["primary_four_card_pressure_package"]["status"] == "blocked_no_seed_safe_cut_plan"
    assert routes["pressure_natural_trigger_pair_guttersnipe_young_pyromancer"]["gate_ready"] is False
    assert routes["storm_kiln_artist_haze_of_rage_combo_research"]["status"] == "research_only_runtime_and_cut_safety_required"


def test_same_lane_and_high_exposure_cuts_are_not_generic_flex():
    payload = build_payload()
    targets = {row["card_name"]: row for row in payload["cut_expansion_targets"]}

    assert targets["Creative Technique"]["investigation_status"] == "same_lane_microbenchmark_only"
    assert targets["Bender's Waterskin"]["investigation_status"] == "same_lane_microbenchmark_only"
    assert targets["Generous Gift"]["investigation_status"] == "blocked_high_exposure_anchor"


def test_staples_are_classified_as_hypotheses_not_auto_adds():
    payload = build_payload()
    policy = {
        row["card_name"]: row
        for row in payload["deckbuilding_priority_model"]["staple_artifact_land_learning"]
    }

    assert policy["Mana Vault"]["current_learning_status"] == "blocked_not_auto_include"
    assert policy["The One Ring"]["current_learning_status"] == "blocked_not_auto_include"
    assert policy["Storm-Kiln Artist"]["current_learning_status"] == "research_package_only"


def test_markdown_surfaces_core_learning_sections():
    markdown = model.render_markdown(build_payload())

    assert "Lorehold Pressure Safe-Cut Expansion Model" in markdown
    assert "Staple, Artifact, And Land Learning" in markdown
    assert "Pressure Package Routes" in markdown
    assert "Cut Expansion Targets" in markdown
