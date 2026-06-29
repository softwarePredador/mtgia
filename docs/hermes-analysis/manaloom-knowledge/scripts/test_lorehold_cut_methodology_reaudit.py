import lorehold_cut_methodology_reaudit as audit


def build_payload():
    return audit.build_report()


def pair_by_key(payload):
    return {row["pair_key"]: row for row in payload["pairs"]}


def test_one_ring_over_molecule_is_blocked_cross_lane_cut():
    payload = build_payload()
    pairs = pair_by_key(payload)
    row = pairs["the_one_ring_over_molecule_man"]

    assert row["lane_gate"]["status"] == "blocked_cross_lane_cut"
    assert row["classification"]["decision"] == "do_not_use_this_cut_as_deck-quality_proof"
    assert "direct miracle-zero engine" in row["cut_profile"]["protected_reasons"]
    assert "the_one_ring_over_molecule_man" in payload["decision"]["blocked_pairs"]
    assert payload["decision"]["ready_for_real_deck_change"] is False


def test_mana_vault_over_bender_is_same_lane_with_external_caveat():
    payload = build_payload()
    pairs = pair_by_key(payload)
    row = pairs["mana_vault_over_benders_waterskin"]

    assert row["lane_gate"]["status"] == "strict_same_lane"
    assert row["classification"]["status"] == "valid_same_lane_with_external_caveat"
    assert row["external_evidence"]["cut_synergy_pct"] > row["external_evidence"]["add_synergy_pct"]
    assert row["battle_evidence"]["promoted_candidate_add"]["spell_cast"] >= 1


def test_birgi_over_scarlet_is_same_macro_confirmation_required():
    payload = build_payload()
    pairs = pair_by_key(payload)
    row = pairs["birgi_god_of_storytelling_harnfel_horn_of_bounty_over_the_scarlet_witch"]

    assert row["lane_gate"]["status"] == "same_macro_lane_needs_confirmation"
    assert row["classification"]["status"] == "confirmation_required"
    assert (
        "birgi_god_of_storytelling_harnfel_horn_of_bounty_over_the_scarlet_witch"
        in payload["decision"]["confirmation_pairs"]
    )
    assert row["battle_evidence"]["paired_restore_cut_card"]["spell_cast"] >= 1


def test_external_snapshot_records_lorehold_specific_evidence():
    payload = build_payload()
    cards = payload["external_stats_snapshot"]["cards"]

    assert cards["Molecule Man"]["synergy_pct"] > cards["The One Ring"]["synergy_pct"]
    assert cards["Bender's Waterskin"]["inclusion_pct"] > cards["Mana Vault"]["inclusion_pct"]
    assert cards["The Scarlet Witch"]["synergy_pct"] >= cards[
        "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
    ]["synergy_pct"]
