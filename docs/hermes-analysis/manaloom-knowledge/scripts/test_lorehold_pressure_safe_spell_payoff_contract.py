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
            }
        ]
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
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
    )

    assert payload["summary"]["decision_status"] == "preflight_pass_cut_pool_required"
    assert payload["summary"]["ready_for_cut_pool_resolver"] is True
    assert payload["summary"]["legal_variant_generation_allowed_now"] is False
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
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
        diagnostic_planner_path=Path("/tmp/planner.json"),
        knowledge_db_path=Path("/tmp/knowledge.db"),
        cut_plan=["Avatar's Wrath", "High Noon", "Prismari Pianist", "Thor, God of Thunder"],
    )

    assert payload["summary"]["decision_status"] == "legal_variant_ready_for_structure_matrix"
    assert payload["summary"]["legal_variant_generation_allowed_now"] is True
    assert payload["summary"]["natural_battle_gate_allowed_now"] is False
