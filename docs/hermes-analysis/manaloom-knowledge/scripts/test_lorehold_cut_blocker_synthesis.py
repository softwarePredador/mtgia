from pathlib import Path

import lorehold_cut_blocker_synthesis as synth


def seed_safe_report():
    return {
        "cut_slots": [
            {
                "card_name": "Esper Sentinel",
                "lane": "draw",
                "status": "blocked",
                "score": 70,
                "unique_exposure_count": 30,
                "blockers": ["missing_cut_safety_row", "manual_status_not_seed_safe"],
            },
            {
                "card_name": "Creative Technique",
                "lane": "big_spell_value",
                "status": "same_lane_only_not_seed_safe",
                "score": 42,
                "unique_exposure_count": 58,
                "blockers": ["same_lane_only_requires_concrete_same_lane_add", "protected_cut"],
            },
            {
                "card_name": "Bender's Waterskin",
                "lane": "early_mana",
                "status": "blocked",
                "score": 0,
                "unique_exposure_count": 268,
                "blockers": ["early_mana_floor_support", "protected_cut"],
            },
        ]
    }


def pressure_report():
    return {
        "summary": {
            "natural_trigger_cards": ["Guttersnipe", "Young Pyromancer"],
        },
        "micro_package_queue": [
            {
                "package_key": "pressure_single_guttersnipe",
                "gate_ready": False,
            }
        ],
    }


def build_payload():
    return synth.build_payload(
        seed_safe_report=seed_safe_report(),
        pressure_report=pressure_report(),
        seed_safe_path=Path("/tmp/seed.json"),
        pressure_path=Path("/tmp/pressure.json"),
    )


def test_classifies_cut_blocker_groups():
    payload = build_payload()

    assert payload["summary"]["evidence_gap_only_count"] == 1
    assert payload["summary"]["same_lane_only_count"] == 0
    assert payload["summary"]["same_lane_constraint_count"] == 1
    assert payload["summary"]["hard_blocked_count"] == 2
    assert payload["evidence_gap_queue"][0]["card_name"] == "Esper Sentinel"
    assert payload["same_lane_only_queue"][0]["card_name"] == "Creative Technique"
    assert {row["card_name"] for row in payload["hard_blocked_top"]} == {
        "Bender's Waterskin",
        "Creative Technique",
    }


def test_pressure_signal_stays_blocked_without_cut_plan():
    payload = build_payload()

    assert payload["pressure_findings"]["status"] == "pressure_signal_blocked_by_cut_model"
    assert payload["pressure_findings"]["natural_trigger_cards"] == ["Guttersnipe", "Young Pyromancer"]
    assert payload["decision"]["promotion_allowed"] is False
    assert "model_pressure_as_full_shell_or_find_true_pressure_lane_cut" in payload["decision"]["next_actions"]


def test_markdown_surfaces_external_learning_and_queues():
    markdown = synth.render_markdown(build_payload())

    assert "Lorehold Cut Blocker Synthesis" in markdown
    assert "GameTyrant Lorehold deck tech" in markdown
    assert "Esper Sentinel" in markdown
    assert "Creative Technique" in markdown
