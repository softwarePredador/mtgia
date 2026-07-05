import lorehold_hypothesis_queue_from_value_model as queue


def card(name, status="watchlist_unproven_do_not_auto_include", tag="draw", variants=3):
    return {
        "card_name": name,
        "candidate_status": status,
        "example_functional_tag": tag,
        "runtime_ready": True,
        "staple_tier": "not_format_staple",
        "variant_deck_count": variants,
        "variant_deck_ids": [608, 609, 610],
        "reason": "sample",
    }


def test_prior_rejects_are_blocked_even_when_runtime_ready():
    value_model = {"variant_watchlist": [card("Mana Vault", tag="ramp")]}

    hypotheses = queue.classify_hypotheses(value_model, gate_ready_now_count=0)

    assert hypotheses[0]["readiness_status"] == "blocked_prior_reject"
    assert hypotheses[0]["allowed_next_test"] == "do_not_retest_without_new_cut_or_new_trace_hypothesis"


def test_unproven_high_variant_land_requires_safe_cut_model():
    value_model = {"variant_watchlist": [card("Plateau", tag="land", variants=7)]}

    hypotheses = queue.classify_hypotheses(value_model, gate_ready_now_count=0)

    assert hypotheses[0]["readiness_status"] == "needs_safe_cut_model"
    assert hypotheses[0]["priority"] == "P1_safe_cut_model"
    assert hypotheses[0]["allowed_next_test"] == "build_safe_cut_mana_source_model_before_any_battle_gate"
    assert "mana_base_review" in hypotheses[0]["hypothesis_lanes"]


def test_no_natural_gate_ready_when_preflight_count_is_zero():
    value_model = {"variant_watchlist": [card("Penance", tag="draw", variants=4)]}

    hypotheses = queue.classify_hypotheses(value_model, gate_ready_now_count=0)

    assert all(row["readiness_status"] != "natural_gate_ready" for row in hypotheses)
    assert hypotheses[0]["allowed_next_test"] == "forced_access_diagnostic_only_until_miracle_access_floors_pass"
    assert "topdeck_miracle_setup" in hypotheses[0]["hypothesis_lanes"]


def test_current_priority_map_names_same_lane_607_anchors_before_gate():
    value_model = {"variant_watchlist": [card("Penance", tag="draw", variants=4)]}
    priority_by_lane = queue.current_priority_lanes(
        {
            "current_card_priorities": [
                {
                    "card_name": "Sensei's Divining Top",
                    "primary_value_lane": "topdeck_miracle_setup",
                    "value_lanes": ["topdeck_miracle_setup"],
                    "priority_class": "protected_topdeck_access_anchor",
                    "cut_policy": "protected_anchor_no_cut_without_explicit_package_and_equal_gate",
                    "value_priority_index": 100,
                },
                {
                    "card_name": "Land Tax",
                    "primary_value_lane": "topdeck_miracle_setup",
                    "value_lanes": ["topdeck_miracle_setup", "tutors_access"],
                    "priority_class": "protected_topdeck_access_anchor",
                    "cut_policy": "protected_anchor_no_cut_without_explicit_package_and_equal_gate",
                    "value_priority_index": 99,
                },
            ]
        }
    )

    hypotheses = queue.classify_hypotheses(
        value_model,
        gate_ready_now_count=0,
        priority_by_lane=priority_by_lane,
    )

    assert hypotheses[0]["same_lane_cut_contract"] == "named_current_607_slot_and_equal_gate_required"
    assert [row["card_name"] for row in hypotheses[0]["same_lane_current_607_anchors"]] == [
        "Sensei's Divining Top",
        "Land Tax",
    ]


def test_real_payload_keeps_607_protected_and_has_no_natural_gate():
    payload = queue.build_payload()

    assert payload["status"] == "lorehold_hypothesis_queue_ready_no_natural_gate"
    assert payload["summary"]["protected_baseline"] == "deck_607"
    assert payload["summary"]["natural_gate_ready_count"] == 0
    assert payload["summary"]["gate_ready_now_count_from_preflight"] == 0
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["decision"]["current_best_baseline"] == "deck_607"
    assert payload["decision"]["natural_gate_ready_now"] is False
    assert payload["summary"]["blocked_prior_reject_count"] >= len(queue.PRIOR_REJECT_BLOCKLIST)
    assert payload["summary"]["card_value_priority_status"] == "card_value_priority_no_direct_cut_ready_current_607"
    assert payload["summary"]["card_value_ready_replacement_count"] == 0
    assert payload["summary"]["game_changer_metadata_rows_considered"] == 12
    assert payload["summary"]["hypotheses_with_same_lane_anchor_count"] > 0


def test_lane_queue_exposes_protection_and_spell_chain_work():
    payload = queue.build_payload()

    assert "protection_window" in payload["lane_queue"]
    assert "spell_chain_conversion" in payload["lane_queue"]
    assert any(row["card_name"] == "Boros Charm" for row in payload["lane_queue"]["protection_window"])
    assert any(row["card_name"] == "Apex of Power" for row in payload["lane_queue"]["spell_chain_conversion"])
    assert all(
        "same_lane_current_607_anchors" in row
        for row in payload["lane_queue"]["spell_chain_conversion"]
    )
