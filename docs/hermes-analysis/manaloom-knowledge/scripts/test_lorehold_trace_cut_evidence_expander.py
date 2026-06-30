from pathlib import Path

import lorehold_trace_cut_evidence_expander as expander


def test_trace_cut_evidence_expander_separates_reviewable_from_hard_blocked():
    seed_safe = {
        "cut_slots": [
            {
                "card_name": "Quiet Study",
                "lane": "draw",
                "status": "blocked",
                "score": 80,
                "blockers": ["missing_cut_safety_row", "manual_status_not_seed_safe"],
            },
            {
                "card_name": "Mana Stone",
                "lane": "early_mana",
                "status": "blocked",
                "score": 75,
                "blockers": ["early_mana_floor_support", "missing_cut_safety_row"],
            },
            {
                "card_name": "Flex Spell",
                "lane": "spell_velocity",
                "status": "seed_safe_cut_ready",
                "score": 90,
                "blockers": [],
            },
        ]
    }
    payload = expander.build_report(
        seed_safe_cut=seed_safe,
        champion_snapshot={"status": "current_champion_snapshot"},
        micro_package_model={"summary": {"ready_micro_package_count": 0}},
        seed_safe_cut_path=Path("/tmp/seed.json"),
        champion_snapshot_path=Path("/tmp/champion.json"),
        micro_package_model_path=Path("/tmp/micro.json"),
    )

    assert payload["summary"]["recommended_next_action"] == "build_package_from_seed_safe_cut"
    assert payload["summary"]["seed_safe_ready_count"] == 1
    assert payload["summary"]["reviewable_evidence_gap_count"] == 1
    assert payload["summary"]["hard_blocked_count"] == 1
    assert payload["seed_safe_cut_queue"][0]["card_name"] == "Flex Spell"
    assert payload["reviewable_evidence_gap_queue"][0]["card_name"] == "Quiet Study"
    assert payload["hard_blocked_queue"][0]["card_name"] == "Mana Stone"


def test_trace_cut_evidence_expander_reports_exhausted_when_no_reviewable_slots():
    seed_safe = {
        "cut_slots": [
            {
                "card_name": "Core Ramp",
                "lane": "early_mana",
                "status": "blocked",
                "score": 40,
                "blockers": ["early_mana_floor_support", "missing_cut_safety_row"],
            },
            {
                "card_name": "Big Finish",
                "lane": "wincon",
                "status": "blocked",
                "score": 40,
                "blockers": ["miracle_or_finisher_core"],
            },
        ]
    }

    payload = expander.build_report(
        seed_safe_cut=seed_safe,
        champion_snapshot={"status": "current_champion_snapshot"},
        micro_package_model={"summary": {"ready_micro_package_count": 0}},
        seed_safe_cut_path=Path("/tmp/seed.json"),
        champion_snapshot_path=Path("/tmp/champion.json"),
        micro_package_model_path=Path("/tmp/micro.json"),
    )

    assert payload["summary"]["recommended_next_action"] == (
        "no_cut_slot_to_expand_under_current_607_contract"
    )
    assert payload["summary"]["reviewable_evidence_gap_count"] == 0
    assert payload["summary"]["hard_blocked_count"] == 2
