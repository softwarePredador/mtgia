#!/usr/bin/env python3
from __future__ import annotations

import csv
import tempfile
from pathlib import Path

import seventeenlands_history_learning as learning


FIELDNAMES = [
    "expansion",
    "event_type",
    "draft_id",
    "match_number",
    "game_number",
    "main_colors",
    "opp_colors",
    "num_turns",
    "won",
    "opening_hand",
    "user_turn_1_cards_drawn",
    "user_turn_1_lands_played",
    "user_turn_1_user_mana_spent",
    "user_turn_2_creatures_cast",
    "user_turn_2_oppo_combat_damage_taken",
    "user_turn_2_user_mana_spent",
    "oppo_turn_2_non_creatures_cast",
    "oppo_turn_2_oppo_mana_spent",
]


def fixture_rows() -> list[dict[str, str]]:
    return [
        {
            "expansion": "LCI",
            "event_type": "PremierDraft",
            "draft_id": "draft-a",
            "match_number": "1",
            "game_number": "1",
            "main_colors": "RW",
            "opp_colors": "UG",
            "num_turns": "2",
            "won": "True",
            "opening_hand": "1100|1102",
            "user_turn_1_cards_drawn": "1101",
            "user_turn_1_lands_played": "1100",
            "user_turn_1_user_mana_spent": "1",
            "user_turn_2_creatures_cast": "1101",
            "user_turn_2_oppo_combat_damage_taken": "2",
            "user_turn_2_user_mana_spent": "2",
            "oppo_turn_2_non_creatures_cast": "2100",
            "oppo_turn_2_oppo_mana_spent": "2",
        },
        {
            "expansion": "LCI",
            "event_type": "PremierDraft",
            "draft_id": "draft-b",
            "match_number": "1",
            "game_number": "1",
            "main_colors": "UB",
            "opp_colors": "WR",
            "num_turns": "2",
            "won": "False",
            "opening_hand": "1200",
            "user_turn_1_cards_drawn": "1201",
            "user_turn_1_lands_played": "1200",
            "user_turn_1_user_mana_spent": "1",
            "user_turn_2_creatures_cast": "",
            "user_turn_2_oppo_combat_damage_taken": "0",
            "user_turn_2_user_mana_spent": "",
            "oppo_turn_2_non_creatures_cast": "2200",
            "oppo_turn_2_oppo_mana_spent": "2",
        },
    ]


def write_fixture(path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(fixture_rows())


def test_learn_rows_extracts_sequence_and_lifecycle_history() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        source = Path(tmp_name) / "replay.csv"
        write_fixture(source)
        report = learning.learn_rows(
            source=str(source),
            source_label="fixture",
            max_rows=0,
            top_card_limit=10,
            top_sequence_limit=10,
            turn_prefix_limit=3,
        )
    assert report["rows_processed"] == 2
    assert report["postgres_writes"] is False
    assert report["outcomes"] == {"False": 1, "True": 1}
    assert report["turn_behavior_by_history"]["1"]["land_play_entries"] == 2
    assert report["turn_behavior_by_history"]["2"]["spell_action_entries"] == 3
    patterns = {row["pattern"] for row in report["sequence_learning"]["common_turn_patterns"]}
    assert "T1:land+mana_spent" in patterns
    by_used = {
        row["arena_id"]: row for row in report["card_lifecycle"]["top_by_used_games"]
    }
    assert "top_by_use_after_access_rate" in report["card_lifecycle"]
    assert by_used["1101"]["access_games"] == 1
    assert by_used["1101"]["used_games"] == 1
    assert by_used["1101"]["access_to_use_lag_avg_turns"] == 1.0
    assert by_used["1101"]["use_after_access_rate"] == 1.0
    assert by_used["1101"]["win_rate_when_used"] == 1.0


if __name__ == "__main__":
    test_learn_rows_extracts_sequence_and_lifecycle_history()
    print("1 tests passed")
