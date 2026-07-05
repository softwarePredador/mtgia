from pathlib import Path

import lorehold_pressure_safe_spell_payoff_contract as contract


def _planner_report():
    return {
        "ranked_diagnostics": [
            {
                "diagnostic_key": "pressure_safe_spell_payoff_micro_shell",
                "readiness": "design_next",
                "priority_score": 12,
                "why": "Targets pressure without generic one-for-one cuts.",
                "predeclared_requirements": [
                    "Preserve the 607 mana, topdeck, miracle, protection, and pressure anchors."
                ],
                "hypothesis_queue_alignment": {
                    "matched_cards": ["Storm-Kiln Artist"],
                    "natural_gate_allowed_by_queue": False,
                },
            }
        ]
    }


def _current_hypothesis_queue():
    return {
        "summary": {
            "natural_gate_ready_count": 0,
            "promotion_allowed": False,
        },
        "hypotheses": [
            {
                "card_name": "Storm-Kiln Artist",
                "readiness_status": "blocked_prior_reject",
                "priority": "P3_learning_only",
                "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
                "runtime_ready": True,
                "hypothesis_lanes": ["spell_chain_conversion"],
                "same_lane_current_607_anchors": [
                    {
                        "card_name": "Molecule Man",
                        "primary_value_lane": "topdeck_miracle_setup",
                        "priority_class": "protected_payoff_finisher_anchor",
                        "cut_policy": "protected_anchor_no_cut_without_explicit_package_and_equal_gate",
                    },
                    {
                        "card_name": "Reforge the Soul",
                        "primary_value_lane": "topdeck_miracle_setup",
                        "priority_class": "protected_payoff_finisher_anchor",
                        "cut_policy": "protected_anchor_no_cut_without_explicit_package_and_equal_gate",
                    },
                ],
            }
        ],
    }


def _ready_snapshot():
    names = [
        row["card_name"]
        for row in contract.PRIMARY_PACKAGE + contract.SECONDARY_RESEARCH_QUEUE
    ]
    return {
        "oracle": [
            {
                "normalized_name": contract.normalize_name(name),
                "name": name,
                "type_line": "Creature",
                "cmc": 3,
                "color_identity_json": '["R"]',
            }
            for name in names
        ],
        "legalities": [
            {"card_name": name, "format": "commander", "status": "legal"}
            for name in names
        ],
        "battle_rules": [
            {
                "normalized_name": contract.normalize_name(name),
                "card_name": name,
                "logical_rule_key": f"battle_rule_v1:{contract.normalize_name(name)}",
                "review_status": "verified",
                "execution_status": "auto",
            }
            for name in names
        ],
        "deck_cards": [
            {"card_name": "Ancient Tomb", "quantity": 1, "functional_tag": "land"},
            {"card_name": "Mountain // Mountain", "quantity": 4, "functional_tag": "land"},
            {"card_name": "Arcane Signet", "quantity": 1, "functional_tag": "ramp"},
            {"card_name": "Bender's Waterskin", "quantity": 1, "functional_tag": "ramp"},
            {"card_name": "Sensei's Divining Top", "quantity": 1, "functional_tag": "draw"},
            {"card_name": "Approach of the Second Sun", "quantity": 1, "functional_tag": "wincon"},
        ],
    }


def test_ready_preflight_still_does_not_allow_natural_battle_gate():
    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=_ready_snapshot(),
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
        hypothesis_queue_path=Path("/tmp/hypothesis.json"),
    )

    assert payload["summary"]["decision_status"] == "preflight_pass_cut_pool_required"
    assert payload["summary"]["diagnostic_contract_status"] == (
        "pressure_safe_diagnostic_contract_ready_no_battle"
    )
    assert payload["summary"]["diagnostic_only"] is True
    assert payload["summary"]["ready_for_cut_pool_resolver"] is True
    assert payload["summary"]["legal_variant_generation_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
    assert payload["summary"]["natural_gate_ready_from_hypothesis_queue"] == 0
    assert payload["summary"]["natural_gate_blocked_by_hypothesis_queue"] is True
    assert payload["summary"]["ready_deck_change_count"] == 0


def test_missing_verified_rule_blocks_cut_pool_resolver():
    snapshot = _ready_snapshot()
    snapshot["battle_rules"] = [
        row
        for row in snapshot["battle_rules"]
        if row["card_name"] != "Monastery Mentor"
    ]

    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=snapshot,
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
    )
    mentor = next(
        row
        for row in payload["primary_package_preflight"]
        if row["card_name"] == "Monastery Mentor"
    )

    assert payload["summary"]["decision_status"] == "blocked_by_local_preflight"
    assert payload["summary"]["ready_for_cut_pool_resolver"] is False
    assert mentor["preflight_status"] == "blocked"
    assert "missing_verified_auto_battle_rule" in mentor["blockers"]


def test_protected_anchor_cut_is_rejected_even_with_matching_cut_count():
    cut_plan = [
        "Bender's Waterskin",
        "Avatar's Wrath",
        "High Noon",
        "Prismari Pianist",
    ]

    validation = contract.validate_cut_plan(cut_plan, add_count=4)

    assert validation["safe"] is False
    assert validation["named_cut_count"] == 4
    assert validation["required_cut_count"] == 4
    assert validation["violations"][0]["violation"] == "protected_607_anchor_cut_forbidden"


def test_four_nonprotected_named_cuts_allow_variant_generation_but_not_battle_gate():
    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=_ready_snapshot(),
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
        cut_plan=["Avatar's Wrath", "High Noon", "Prismari Pianist", "Thor, God of Thunder"],
    )

    assert payload["summary"]["decision_status"] == "legal_variant_ready_for_structure_matrix"
    assert payload["summary"]["legal_variant_generation_allowed_now"] is True
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False


def test_current_queue_keeps_storm_kiln_as_prior_reject_not_gate_ready():
    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=_ready_snapshot(),
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
    )
    storm = next(
        row
        for row in payload["primary_package_preflight"]
        if row["card_name"] == "Storm-Kiln Artist"
    )
    overlay = storm["hypothesis_queue_overlay"]

    assert overlay["hypothesis_queue_status"] == "present"
    assert overlay["readiness_status"] == "blocked_prior_reject"
    assert overlay["natural_gate_ready"] is False
    assert overlay["same_lane_current_607_anchors"][0]["card_name"] == "Molecule Man"


def test_missing_pressure_cards_are_reported_as_queue_preflight_gaps():
    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=_ready_snapshot(),
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
    )

    assert payload["primary_package_hypothesis_alignment"]["matched_cards"] == [
        "Storm-Kiln Artist"
    ]
    assert payload["primary_package_hypothesis_alignment"]["missing_cards"] == [
        "Monastery Mentor",
        "Young Pyromancer",
        "Guttersnipe",
    ]
    assert payload["summary"]["primary_package_missing_from_hypothesis_queue"] == 3


def test_hard_stop_rules_include_winota_and_generic_cut_blockers():
    payload = contract.build_report(
        planner_report=_planner_report(),
        db_snapshot=_ready_snapshot(),
        hypothesis_queue=_current_hypothesis_queue(),
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
    )
    rules = {row["rule"]: row for row in payload["hard_stop_rules"]}

    assert "winota_fast_pressure_floor_required" in rules
    assert "protected_anchor_generic_cuts_forbidden" in rules
    assert "do_not_repeat_storm_kiln_generic_mana_swap" in rules
    assert "Molecule Man" in rules["protected_anchor_generic_cuts_forbidden"]["condition"]
