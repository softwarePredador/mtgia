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


def fixture_gate_report(*, accessed: bool, used: bool = False) -> dict[str, object]:
    card_name = "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
    focus_summary = {
        card_name: {
            "accessed_games": 1 if accessed else 0,
            "dominant_zone": "hand" if accessed else "library",
            "drawn_games": 1 if accessed else 0,
            "library_only_games": 0 if accessed else 2,
            "near_access_games": 0,
            "opening_hand_games": 0,
            "trace_count": 4,
            "trace_games": 2,
            "zone_counts": {"hand": 2} if accessed else {"library": 4},
        }
    }
    event_counts = {
        "combat_damage": 2,
        "creature_cast": 3,
        "land_played": 4,
        "spell_cast": 1,
    }
    return {
        "results": [
            {"deck_key": "current_607", "games": 2, "telemetry": {}},
            {
                "deck_key": "candidate_607_birgi_v1",
                "games": 2,
                "telemetry": {
                    "card_event_counts": {f"{card_name}|cast": 1} if used else {},
                    "card_strategy_counts": {},
                    "event_counts": event_counts,
                    "focus_card_access_summary": focus_summary,
                },
            },
        ]
    }


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


def test_run_gate_report_marks_accessed_candidate_without_use_as_inconclusive() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        prior = tmp / "prior.json"
        gate = tmp / "gate.json"
        prior.write_text(json.dumps(fixture_prior()) + "\n", encoding="utf-8")
        gate.write_text(json.dumps(fixture_gate_report(accessed=True)) + "\n", encoding="utf-8")
        report = compare.run_gate_report(
            prior_path=prior,
            gate_report_path=gate,
            candidate_key="candidate_607_birgi_v1",
            candidate_cards=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
            player_slots=2,
        )
        observations = report["observed_summary"]["candidate_observations"]
        assert observations["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]["observed"] is True
        assert report["candidate_scoreability"]["status"] == "candidate_not_used"
        assert report["candidate_scoreability"]["scoring_allowed"] is False
        assert report["candidate_scoreability"]["thresholds"]["min_used_events"] == 1
        assert report["status"] == "inconclusive_candidate_not_used"


def test_run_gate_report_allows_used_candidate_for_scoring() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        prior = tmp / "prior.json"
        gate = tmp / "gate.json"
        prior.write_text(json.dumps(fixture_prior()) + "\n", encoding="utf-8")
        gate.write_text(json.dumps(fixture_gate_report(accessed=True, used=True)) + "\n", encoding="utf-8")
        report = compare.run_gate_report(
            prior_path=prior,
            gate_report_path=gate,
            candidate_key="candidate_607_birgi_v1",
            candidate_cards=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
            player_slots=2,
        )

        assert report["candidate_scoreability"]["status"] == "candidate_used"
        assert report["candidate_scoreability"]["scoring_allowed"] is True
        assert report["status"] == "battle_prior_passed"
        assert report["postgres_writes"] is False


def test_run_gate_report_blocks_used_candidate_with_insufficient_sample() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        prior = tmp / "prior.json"
        gate = tmp / "gate.json"
        prior.write_text(json.dumps(fixture_prior()) + "\n", encoding="utf-8")
        gate.write_text(json.dumps(fixture_gate_report(accessed=True, used=True)) + "\n", encoding="utf-8")
        report = compare.run_gate_report(
            prior_path=prior,
            gate_report_path=gate,
            candidate_key="candidate_607_birgi_v1",
            candidate_cards=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
            player_slots=2,
            min_used_events=2,
        )

        scoreability = report["candidate_scoreability"]
        assert scoreability["status"] == "candidate_insufficient_sample"
        assert scoreability["scoring_allowed"] is False
        assert scoreability["candidate_insufficient_sample_cards"] == [
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty"
        ]
        card = scoreability["cards"]["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]
        assert card["evidence_status"] == "used_insufficient_sample"
        assert report["status"] == "inconclusive_candidate_insufficient_sample"


def test_run_gate_report_marks_library_only_candidate_inconclusive() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        prior = tmp / "prior.json"
        gate = tmp / "gate.json"
        prior.write_text(json.dumps(fixture_prior()) + "\n", encoding="utf-8")
        gate.write_text(json.dumps(fixture_gate_report(accessed=False)) + "\n", encoding="utf-8")
        report = compare.run_gate_report(
            prior_path=prior,
            gate_report_path=gate,
            candidate_key="candidate_607_birgi_v1",
            candidate_cards=["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
            player_slots=2,
        )
        observations = report["observed_summary"]["candidate_observations"]
        observed = observations["Birgi, God of Storytelling // Harnfel, Horn of Bounty"]
        assert observed["observed"] is False
        assert observed["evidence_level"] == "library_only"
        assert report["status"] == "inconclusive_candidate_unobserved"


if __name__ == "__main__":
    test_summarize_events_counts_turn_metrics_and_candidate_observations()
    test_compare_to_prior_flags_missing_candidate()
    test_run_reads_json_and_jsonl()
    test_run_gate_report_marks_accessed_candidate_without_use_as_inconclusive()
    test_run_gate_report_allows_used_candidate_for_scoring()
    test_run_gate_report_blocks_used_candidate_with_insufficient_sample()
    test_run_gate_report_marks_library_only_candidate_inconclusive()
    print("7 tests passed")
