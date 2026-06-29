#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

import battle_card_acceleration_source_audit as audit


REPO_ROOT = Path(__file__).resolve().parents[4]


def test_source_matrix_separates_authority_by_need() -> None:
    by_id = {source.id: source for source in audit.SOURCE_CAPABILITIES}

    assert "oracle_identity_faces" in by_id["scryfall_bulk_oracle"].best_for
    assert "turn_rules" in by_id["wotc_comprehensive_rules"].best_for
    assert "battle_family_mapping" in by_id["xmage_local_source"].best_for
    assert "combo_detection" in by_id["commander_spellbook"].best_for
    assert "commander_roles" in by_id["edhrec_json"].best_for
    assert "oracle_text" in by_id["seventeenlands_public_data"].not_for
    assert "oracle_rules" in by_id["mtgtop8_edh_cedh"].not_for
    assert by_id["moxfield_public_decks"].access_model == "public_site_with_bot_protection"


def test_source_scores_prioritize_correct_sources() -> None:
    needs = {need.id: need for need in audit.PROJECT_NEEDS}

    oracle_scores = audit.source_scores_for_need(needs["oracle_identity_faces"])
    assert [row["source_id"] for row in oracle_scores[:2]] == [
        "mtgjson_v5",
        "scryfall_bulk_oracle",
    ]

    runtime_scores = audit.source_scores_for_need(needs["battle_runtime_family_mapping"])
    assert {row["source_id"] for row in runtime_scores[:2]} == {
        "wotc_comprehensive_rules",
        "xmage_local_source",
    }

    deck_scores = audit.source_scores_for_need(needs["deckbuilding_combo_and_meta"])
    assert {row["source_id"] for row in deck_scores[:2]} == {
        "commander_spellbook",
        "edhrec_json",
    }


def test_real_repo_acceleration_surfaces_are_covered() -> None:
    report = audit.build_audit(REPO_ROOT)
    needs = {item["id"]: item for item in report["needs"]}

    assert report["postgres_writes"] is False
    assert report["summary"]["gate_status"] == "pass"
    assert report["summary"]["gap_count"] == 0
    assert needs["oracle_identity_faces"]["status"] == "covered"
    assert needs["battle_runtime_family_mapping"]["status"] == "covered"
    assert needs["deckbuilding_combo_and_meta"]["status"] == "covered"
    assert needs["reference_deck_corpus_sanitization"]["status"] == "covered"
    assert report["implementation_queue"] == []


if __name__ == "__main__":
    test_source_matrix_separates_authority_by_need()
    test_source_scores_prioritize_correct_sources()
    test_real_repo_acceleration_surfaces_are_covered()
    print("3 tests passed")
