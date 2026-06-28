#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
from pathlib import Path

import seventeenlands_battle_prior_compare as compare


def fixture_prior() -> dict[str, object]:
    return {
        "rows_sampled": 2,
        "sample_summary": {
            "turn_behavior_metrics": {
                "1": {
                    "active_mana_spent_avg_positive": 1.0,
                    "creature_cast_entries": 2,
                    "land_play_entries": 4,
                    "noncreature_cast_entries": 0,
                    "spell_action_entries": 2,
                    "total_combat_damage": 0.0,
                },
                "2": {
                    "active_mana_spent_avg_positive": 2.0,
                    "creature_cast_entries": 1,
                    "land_play_entries": 3,
                    "noncreature_cast_entries": 1,
                    "spell_action_entries": 2,
                    "total_combat_damage": 2.0,
                },
            }
        },
    }


def fixture_events() -> list[dict[str, object]]:
    return [
        {"game_id": "g1", "turn": 1, "event_type": "play_land", "card_name": "Mountain"},
        {"game_id": "g1", "turn": 1, "event_type": "cast_creature", "card_name": "Goblin"},
        {"game_id": "g1", "turn": 1, "event_type": "cost_paid", "mana_before": 1, "mana_after": 0},
        {"game_id": "g1", "turn": 2, "event_type": "cast_noncreature", "card_name": "Big Score"},
        {"game_id": "g1", "turn": 2, "event_type": "combat_damage", "value": 3},
        {"game_id": "g2", "turn": 1, "event_type": "play_land", "card_name": "Plains"},
        {"game_id": "g2", "turn": 2, "event_type": "mana_spent", "value": 4},
    ]


def test_summarize_events_counts_turn_metrics_and_candidate_observations() -> None:
    observed = compare.summarize_events(
        fixture_events(),
        candidate_cards=["Big Score", "Missing Card"],
        game_count=2,
        player_slots=1,
    )
    assert observed["game_count"] == 2
    assert observed["player_slots"] == 1
    assert observed["turn_behavior_metrics"]["1"]["land_play_entries"] == 2
    assert observed["turn_behavior_metrics"]["1"]["spell_action_entries"] == 1
    assert observed["turn_behavior_metrics"]["1"]["active_mana_spent_avg_positive"] == 1.0
    assert observed["turn_behavior_metrics"]["2"]["total_combat_damage"] == 3.0
    assert observed["candidate_observations"]["Big Score"]["observed"] is True
    assert observed["candidate_observations"]["Missing Card"]["observed"] is False


def test_compare_to_prior_flags_missing_candidate() -> None:
    observed = compare.summarize_events(
        fixture_events(),
        candidate_cards=["Missing Card"],
        game_count=2,
        player_slots=1,
    )
    report = compare.compare_to_prior(fixture_prior(), observed)
    assert report["observed_game_count"] == 2
    assert any(flag.get("card") == "Missing Card" for flag in report["flags"])
    assert report["comparison_by_turn"]["1"]["land_play_entries"]["ratio"] == 1.0


def test_run_reads_json_and_jsonl() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        prior = tmp / "prior.json"
        events = tmp / "events.jsonl"
        prior.write_text(json.dumps(fixture_prior()) + "\n", encoding="utf-8")
        events.write_text(
            "\n".join(json.dumps(event) for event in fixture_events()) + "\n",
            encoding="utf-8",
        )
        report = compare.run(
            prior_path=prior,
            events_path=events,
            candidate_cards=["Big Score"],
            game_count=None,
            player_slots=None,
        )
        assert report["postgres_writes"] is False
        assert report["source_db_mutated"] is False
        assert report["observed_summary"]["game_count"] == 2


if __name__ == "__main__":
    test_summarize_events_counts_turn_metrics_and_candidate_observations()
    test_compare_to_prior_flags_missing_candidate()
    test_run_reads_json_and_jsonl()
    print("3 tests passed")
