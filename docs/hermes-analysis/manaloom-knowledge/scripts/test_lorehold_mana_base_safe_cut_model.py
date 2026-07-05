import lorehold_mana_base_safe_cut_model as model


def land(name, type_line, oracle_text):
    return model.land_features(
        {
            "card_name": name,
            "quantity": 1,
            "type_line": type_line,
            "oracle_text": oracle_text,
        },
        in_deck_607=False,
    )


def test_plateau_is_untapped_typed_rw_source():
    plateau = land("Plateau", "Land - Mountain Plains", "({T}: Add {R} or {W}.)")

    assert plateau["red_source"] is True
    assert plateau["white_source"] is True
    assert plateau["typed_mountain_plains"] is True
    assert plateau["enters_tapped_profile"] == "reliably_untapped"
    assert model.source_quality_score(plateau) > 100


def test_boros_garrison_carries_bounce_tempo_risk():
    garrison = land(
        "Boros Garrison",
        "Land",
        "This land enters tapped.\nWhen this land enters, return a land you control to its owner's hand.\n{T}: Add {R}{W}.",
    )

    assert garrison["enters_tapped_profile"] == "always_tapped"
    assert "bounce_land_tempo_risk" in garrison["utility_roles"]
    assert model.source_quality_score(garrison) < model.source_quality_score(
        land("Clifftop Retreat", "Land", "This land enters tapped unless you control a Mountain or a Plains.\n{T}: Add {R} or {W}.")
    )


def test_colorless_candidate_blocked_when_cutting_colored_source():
    boseiju = land(
        "Boseiju, Who Shelters All",
        "Legendary Land",
        "Boseiju enters tapped.\n{T}, Pay 2 life: Add {C}. If that mana is spent on an instant or sorcery spell, that spell can't be countered.",
    )
    turbulent = land(
        "Turbulent Steppe",
        "Land - Mountain Plains",
        "({T}: Add {R} or {W}.)\nThis land enters tapped unless your opponents control eight or more lands.",
    )

    status, reasons = model.classify_pair(boseiju, turbulent)

    assert status == "blocked_color_source_regression"
    assert "candidate_loses_colored_source" in reasons


def test_plateau_over_turbulent_steppe_is_model_ready_not_promotion():
    plateau = land("Plateau", "Land - Mountain Plains", "({T}: Add {R} or {W}.)")
    turbulent = land(
        "Turbulent Steppe",
        "Land - Mountain Plains",
        "({T}: Add {R} or {W}.)\nThis land enters tapped unless your opponents control eight or more lands.",
    )

    status, reasons = model.classify_pair(plateau, turbulent)

    assert status == "model_ready_for_candidate_materialization"
    assert reasons == ["tempo_upgrade_preserves_color_and_fetch_target_type"]


def test_real_payload_keeps_battle_gate_closed():
    payload = model.build_payload()

    assert payload["status"] == "lorehold_mana_base_safe_cut_model_ready"
    assert payload["summary"]["deck_id"] == 607
    assert payload["summary"]["current_land_quantity"] == 34
    assert payload["summary"]["candidate_count"] == 7
    assert payload["summary"]["model_ready_pair_count"] >= 1
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["allow_battle_gate_now"] is False
    assert payload["decision"]["current_best_baseline"] == "deck_607"
    assert payload["decision"]["best_structural_learning_pair"]["add"] == "Plateau"
