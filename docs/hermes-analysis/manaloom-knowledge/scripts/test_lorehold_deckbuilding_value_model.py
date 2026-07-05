import lorehold_deckbuilding_value_model as model


def sample_row(name, tag, type_line="Artifact", quantity=1, commander=False, cmc=1):
    return {
        "card_name": name,
        "functional_tag": tag,
        "type_line": type_line,
        "quantity": quantity,
        "is_commander": 1 if commander else 0,
        "cmc": cmc,
    }


def test_land_group_classifies_607_land_roles():
    assert model.land_group("Arid Mesa") == "fetch_or_search_fixing"
    assert model.land_group("Sacred Foundry") == "typed_dual_or_fetch_target"
    assert model.land_group("Command Tower") == "untapped_or_multiplayer_fixing"
    assert model.land_group("Urza's Saga") == "utility_engine_land"


def test_library_of_leng_is_protected_topdeck_engine():
    card = model.classify_card(sample_row("Library of Leng", "engine"), None, True)

    assert card["protected_anchor"] is True
    assert card["value_tier"] == "tier_0_protected_engine_or_anchor"
    assert "topdeck_miracle_engine" in card["lanes"]
    assert card["cut_policy"] == "no_generic_cut_same_lane_battle_proof_required"


def test_sol_ring_is_structural_ramp_floor_not_commander_engine():
    staple = {"best_edhrec_rank": 1}
    card = model.classify_card(sample_row("Sol Ring", "ramp"), staple, True)

    assert card["value_tier"] == "tier_1_structural_floor"
    assert "structural_ramp_floor" in card["lanes"]
    assert card["staple_tier"] == "global_top_100"
    assert card["protected_anchor"] is False


def test_the_one_ring_watchlist_is_not_auto_include_after_prior_reject():
    row = {
        "card_name": "The One Ring",
        "variant_deck_count": 4,
        "variant_deck_ids": "608,613,615,619",
        "example_functional_tag": "draw",
        "cmc": 4,
        "type_line": "Legendary Artifact",
    }
    card = model.classify_watchlist_card(row, {"best_edhrec_rank": 90}, True)

    assert card["candidate_status"] == "prior_tested_reject_or_caveat_do_not_auto_include"
    assert card["runtime_ready"] is True
    assert "tested value/draw cuts lost" in card["reason"]


def test_mana_foundation_counts_land_and_ramp_shape():
    cards = [
        model.classify_card(sample_row("Arid Mesa", "land", "Land"), None, False),
        model.classify_card(sample_row("Plains // Plains", "land", "Basic Land - Plains", quantity=4), None, False),
        model.classify_card(sample_row("Sol Ring", "ramp", "Artifact"), {"best_edhrec_rank": 1}, True),
        model.classify_card(sample_row("Big Score", "ramp", "Instant", cmc=4), None, True),
        model.classify_card(sample_row("Smothering Tithe", "ramp", "Enchantment", cmc=4), None, True),
    ]

    mana = model.mana_foundation(cards)

    assert mana["land_quantity"] == 5
    assert mana["ramp_quantity"] == 3
    assert mana["artifact_ramp_quantity"] == 1
    assert mana["instant_sorcery_ramp_quantity"] == 1
    assert mana["enchantment_ramp_quantity"] == 1


def test_real_payload_keeps_607_as_current_best_baseline():
    payload = model.build_payload()

    assert payload["status"] == "lorehold_value_model_ready_607_remains_protected"
    assert payload["summary"]["deck_id"] == 607
    assert payload["summary"]["quantity_total"] == 100
    assert payload["summary"]["mana_foundation"]["land_quantity"] == 34
    assert payload["summary"]["mana_foundation"]["ramp_quantity"] == 15
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["decision"]["current_best_baseline"] == "deck_607"
    assert any(card["card_name"] == "The One Ring" for card in payload["variant_watchlist"])
