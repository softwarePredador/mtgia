#!/usr/bin/env python3
from __future__ import annotations

import csv
import tempfile
from pathlib import Path

import seventeenlands_replay_profile as profile


FIELDNAMES = [
    "expansion",
    "event_type",
    "draft_id",
    "match_number",
    "game_number",
    "main_colors",
    "opp_colors",
    "on_play",
    "num_turns",
    "won",
    "opening_hand",
    "user_turn_1_cards_drawn",
    "user_turn_1_lands_played",
    "user_turn_1_creatures_cast",
    "user_turn_1_user_mana_spent",
    "user_turn_1_eot_user_life",
    "oppo_turn_1_oppo_combat_damage_taken",
    "oppo_turn_1_eot_oppo_life",
    "user_turn_2_cards_drawn_or_tutored",
    "user_turn_2_non_creatures_cast",
    "user_turn_2_user_instants_sorceries_cast",
    "user_turn_2_user_abilities",
    "user_turn_2_creatures_attacked",
    "user_turn_2_oppo_combat_damage_taken",
    "user_turn_2_user_mana_spent",
    "user_turn_2_eot_user_cards_in_hand",
]


def fixture_row() -> dict[str, str]:
    return {
        "expansion": "LCI",
        "event_type": "PremierDraft",
        "draft_id": "draft-a",
        "match_number": "1",
        "game_number": "1",
        "main_colors": "RW",
        "opp_colors": "UG",
        "on_play": "True",
        "num_turns": "2",
        "won": "True",
        "opening_hand": "100|101|102|103|104|105|106",
        "user_turn_1_cards_drawn": "107",
        "user_turn_1_lands_played": "100",
        "user_turn_1_creatures_cast": "101",
        "user_turn_1_user_mana_spent": "1.0",
        "user_turn_1_eot_user_life": "20.0",
        "oppo_turn_1_oppo_combat_damage_taken": "0.0",
        "oppo_turn_1_eot_oppo_life": "20.0",
        "user_turn_2_cards_drawn_or_tutored": "108",
        "user_turn_2_non_creatures_cast": "109|110",
        "user_turn_2_user_instants_sorceries_cast": "111",
        "user_turn_2_user_abilities": "112",
        "user_turn_2_creatures_attacked": "101",
        "user_turn_2_oppo_combat_damage_taken": "2.0",
        "user_turn_2_user_mana_spent": "3.0",
        "user_turn_2_eot_user_cards_in_hand": "4.0",
    }


def test_classify_header_detects_17lands_turn_columns() -> None:
    header = profile.classify_header(FIELDNAMES)
    assert header["field_count"] == len(FIELDNAMES)
    assert header["max_turn_column"] == 2
    assert header["turn_side_counts"] == {"oppo": 2, "user": 13}
    assert "cards_drawn_or_tutored" in header["turn_suffixes"]


def test_split_id_list_filters_zero_and_pipe_values() -> None:
    assert profile.split_id_list("100|0|101") == ["100", "101"]
    assert profile.split_id_list("0") == []
    assert profile.split_id_list("100, 101;102") == ["100", "101", "102"]


def test_normalize_turn_events_emits_behavior_events() -> None:
    events = profile.normalize_turn_events(fixture_row(), FIELDNAMES)
    event_types = {event["event_type"] for event in events}
    assert "draw_card" in event_types
    assert "play_land" in event_types
    assert "cast_creature" in event_types
    assert "cast_noncreature" in event_types
    assert "combat_damage" in event_types
    assert "end_turn_state" in event_types
    cast = next(event for event in events if event["event_type"] == "cast_creature")
    assert cast["arena_id"] == "101"
    assert cast["owner_side"] == "user"


def test_profile_report_is_read_only_and_documents_limits() -> None:
    report = profile.profile_rows(
        source="fixture.csv",
        source_label="fixture",
        fieldnames=FIELDNAMES,
        rows=[fixture_row()],
    )
    assert report["postgres_writes"] is False
    assert report["source_db_mutated"] is False
    assert report["rows_sampled"] == 1
    assert report["sample_summary"]["top_arena_ids"]["101"] == 3
    assert any("Do not promote card battle rules" in item for item in report["not_recommended_use"])
    assert "turn_behavior_metrics" in report["sample_summary"]


def test_run_reads_local_csv_fixture() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        source = Path(tmp_name) / "replay.csv"
        with source.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
            writer.writeheader()
            writer.writerow(fixture_row())
        report = profile.run(
            source=str(source),
            source_label="fixture",
            sample_rows=10,
        )
        assert report["header"]["turn_column_count"] == 15
        assert report["sample_game_identity"]["draft_id"] == "draft-a"


if __name__ == "__main__":
    test_classify_header_detects_17lands_turn_columns()
    test_split_id_list_filters_zero_and_pipe_values()
    test_normalize_turn_events_emits_behavior_events()
    test_profile_report_is_read_only_and_documents_limits()
    test_run_reads_local_csv_fixture()
    print("5 tests passed")
