from pathlib import Path

import lorehold_staple_accessibility_freshness_audit as audit


def _accessibility():
    return {
        "cards": [
            {
                "card_name": "Mana Vault",
                "rules_layer": {
                    "commander_legal": True,
                    "commander_status": "legal",
                    "color_identity_allowed": True,
                    "type_line": "Artifact",
                    "mana_cost": "{1}",
                },
                "collection_layer": {"owned": False, "owned_quantity": 0},
                "discovery_layer": {
                    "format_staple_present": True,
                    "format_staples_gap": False,
                    "official_game_changer": True,
                    "battle_rule_active_count": 1,
                },
                "bracket_layer": {
                    "target_bracket": 4,
                    "allowed_by_bracket": True,
                    "reason": "game_changer_budget_available",
                },
                "promotion_layer": {
                    "decision": "blocked_prior_gate_rejected",
                    "current_shell_decision": {"decision": "reject_current_pair"},
                },
                "current_607_accessibility": "legal_not_owned_and_promotion_blocked_current_607",
            },
            {
                "card_name": "The One Ring",
                "rules_layer": {
                    "commander_legal": True,
                    "commander_status": "legal",
                    "color_identity_allowed": True,
                    "type_line": "Legendary Artifact",
                    "mana_cost": "{4}",
                },
                "collection_layer": {"owned": True, "owned_quantity": 1},
                "discovery_layer": {
                    "format_staple_present": False,
                    "format_staples_gap": True,
                    "official_game_changer": True,
                    "battle_rule_active_count": 1,
                },
                "bracket_layer": {
                    "target_bracket": 4,
                    "allowed_by_bracket": True,
                    "reason": "game_changer_budget_available",
                },
                "promotion_layer": {
                    "decision": "blocked_existing_package_rejected",
                    "current_shell_decision": {"decision": "reject_current_shell"},
                },
                "current_607_accessibility": "legal_owned_but_promotion_blocked_current_607",
            },
        ]
    }


def _hypothesis_queue(*, ready=False):
    rows = [
        {
            "card_name": "Mana Vault",
            "readiness_status": "blocked_prior_reject",
            "priority": "P3_learning_only",
            "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
            "hypothesis_lanes": ["spell_chain_conversion"],
            "same_lane_cut_contract": "blocked_prior_reject_requires_material_new_hypothesis",
            "same_lane_current_607_anchors": [
                {"card_name": "Molecule Man"},
                {"card_name": "Reforge the Soul"},
            ],
            "reason": "one-card Bender's Waterskin replacement lost",
        },
        {
            "card_name": "The One Ring",
            "readiness_status": "blocked_prior_reject",
            "priority": "P3_learning_only",
            "allowed_next_test": "do_not_retest_without_new_cut_or_new_trace_hypothesis",
            "hypothesis_lanes": ["unclassified_variant_watchlist"],
            "same_lane_cut_contract": "blocked_prior_reject_requires_material_new_hypothesis",
            "same_lane_current_607_anchors": [],
            "reason": "existing draw/value package rejected",
        },
    ]
    if ready:
        rows.append(
            {
                "card_name": "Ready Staple",
                "readiness_status": "natural_gate_ready",
                "priority": "P1",
                "allowed_next_test": "run_equal_gate",
                "hypothesis_lanes": ["ramp"],
                "same_lane_cut_contract": "named_current_607_slot_and_equal_gate_required",
                "same_lane_current_607_anchors": [{"card_name": "Arcane Signet"}],
            }
        )
    return {
        "status": "lorehold_hypothesis_queue_ready_no_natural_gate",
        "summary": {"natural_gate_ready_count": int(ready)},
        "hypotheses": rows,
    }


def _game_changer_audit():
    return {
        "status": "game_changer_discovery_gap_found_report_only",
        "rows": [
            {"card_name": "mana vault", "status": "discovery_ready_in_format_staples"},
            {"card_name": "the one ring", "status": "discovery_gap_missing_format_staples"},
        ],
    }


def _value_priority():
    return {
        "summary": {"ready_replacement_candidate_count": 0},
        "candidate_replacement_pressure": [],
    }


def _paths():
    return {
        "accessibility": Path("/tmp/accessibility.json"),
        "hypothesis_queue": Path("/tmp/hypothesis.json"),
        "game_changer_audit": Path("/tmp/game_changers.json"),
        "value_priority": Path("/tmp/value_priority.json"),
    }


def _build(**overrides):
    return audit.build_report(
        accessibility=overrides.get("accessibility", _accessibility()),
        hypothesis_queue=overrides.get("hypothesis_queue", _hypothesis_queue()),
        game_changer_audit=overrides.get("game_changer_audit", _game_changer_audit()),
        value_priority=overrides.get("value_priority", _value_priority()),
        cards=overrides.get("cards", ("Mana Vault", "The One Ring")),
        paths=_paths(),
    )


def test_mana_vault_is_rules_accessible_but_collection_and_promotion_blocked() -> None:
    payload = _build()
    by_card = {row["card_name"]: row for row in payload["cards"]}
    mana_vault = by_card["Mana Vault"]

    assert mana_vault["external"]["commander_legal"] is True
    assert mana_vault["external"]["game_changer"] is True
    assert mana_vault["collection"]["owned"] is False
    assert mana_vault["hypothesis"]["readiness_status"] == "blocked_prior_reject"
    assert mana_vault["app_accessibility_label"] == (
        "rules_accessible_collection_missing_promotion_blocked"
    )
    assert mana_vault["deck_action_allowed_now"] is False


def test_one_ring_is_owned_but_promotion_blocked_and_discovery_gap_visible() -> None:
    payload = _build()
    by_card = {row["card_name"]: row for row in payload["cards"]}
    one_ring = by_card["The One Ring"]

    assert one_ring["external"]["commander_legal"] is True
    assert one_ring["collection"]["owned"] is True
    assert one_ring["discovery"]["format_staples_gap"] is True
    assert one_ring["app_accessibility_label"] == "rules_collection_accessible_promotion_blocked"
    assert one_ring["next_action"] == (
        "show_owned_but_blocked_prior_reject_and_require_new_same_lane_trace"
    )


def test_natural_gate_ready_still_does_not_auto_promote() -> None:
    accessibility = _accessibility()
    accessibility["cards"].append(
        {
            "card_name": "Ready Staple",
            "rules_layer": {"commander_legal": True, "color_identity_allowed": True},
            "collection_layer": {"owned": True, "owned_quantity": 1},
            "discovery_layer": {
                "format_staple_present": True,
                "format_staples_gap": False,
                "official_game_changer": False,
                "battle_rule_active_count": 1,
            },
            "bracket_layer": {"target_bracket": 4, "allowed_by_bracket": True},
            "promotion_layer": {"decision": ""},
            "current_607_accessibility": "legal_owned_requires_named_cut_and_gate",
        }
    )
    external = {
        **audit.EXTERNAL_RULES_SNAPSHOT,
        "cards": {
            **audit.EXTERNAL_RULES_SNAPSHOT["cards"],
            "Ready Staple": {
                "external_commander_legal": True,
                "external_color_identity_allowed_for_lorehold": True,
                "external_game_changer": False,
                "external_role": "test",
                "external_reason": "test",
            },
        },
    }

    payload = audit.build_report(
        accessibility=accessibility,
        hypothesis_queue=_hypothesis_queue(ready=True),
        game_changer_audit=_game_changer_audit(),
        value_priority=_value_priority(),
        cards=("Ready Staple",),
        external_snapshot=external,
        paths=_paths(),
    )

    row = payload["cards"][0]
    assert row["app_accessibility_label"] == "candidate_ready_for_equal_gate_not_auto_promoted"
    assert row["deck_action_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_markdown_surfaces_official_snapshot_and_layer_labels() -> None:
    markdown = audit.render_markdown(_build())

    assert "Commander banned list" in markdown
    assert "https://mtgcommander.net/index.php/banned-list/" in markdown
    assert "Mana Vault" in markdown
    assert "The One Ring" in markdown
    assert "rules_accessible_collection_missing_promotion_blocked" in markdown
    assert "rules_collection_accessible_promotion_blocked" in markdown
