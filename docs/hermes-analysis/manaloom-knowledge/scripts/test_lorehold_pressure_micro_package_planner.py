from pathlib import Path

import lorehold_pressure_micro_package_planner as planner


def pressure_decision():
    return {
        "natural_smoke_gate": {"miracle_regressed": True},
        "candidate_cards": [
            {
                "card_name": "Guttersnipe",
                "natural_accessed_games": 2,
                "natural_near_access_games": 1,
                "natural_event_counts": {
                    "cost_paid:Guttersnipe": 2,
                    "trigger_resolved:Guttersnipe": 7,
                },
                "natural_trigger_count": 7,
            },
            {
                "card_name": "Young Pyromancer",
                "natural_accessed_games": 1,
                "natural_near_access_games": 1,
                "natural_event_counts": {
                    "cost_paid:Young Pyromancer": 2,
                    "spell_cast:Young Pyromancer": 1,
                    "trigger_resolved:Young Pyromancer": 6,
                },
                "natural_trigger_count": 6,
            },
            {
                "card_name": "Monastery Mentor",
                "natural_accessed_games": 0,
                "natural_near_access_games": 1,
                "natural_event_counts": {},
                "natural_trigger_count": 0,
            },
        ],
    }


def seed_safe_report():
    return {
        "seed_safe_cut_candidates": [],
        "same_lane_only_cut_slots": [{"card_name": "Creative Technique"}],
        "summary": {
            "same_lane_only_cut_cards": ["Creative Technique", "Bender's Waterskin"],
            "seed_safe_cut_ready_count": 0,
        },
    }


def build_payload():
    return planner.build_plan(
        pressure_decision=pressure_decision(),
        seed_safe_report=seed_safe_report(),
        pressure_path=Path("/tmp/pressure.json"),
        seed_safe_path=Path("/tmp/seed.json"),
    )


def test_micro_package_blocks_without_seed_safe_cuts():
    payload = build_payload()

    assert payload["status"] == "pressure_micro_package_no_gate_ready_keep_607"
    assert payload["summary"]["gate_ready_package_count"] == 0
    assert payload["summary"]["seed_safe_cut_ready_count"] == 0
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["summary"]["natural_trigger_cards"] == ["Guttersnipe", "Young Pyromancer"]


def test_trigger_pair_is_top_hypothesis_but_not_gate_ready():
    payload = build_payload()
    top = payload["micro_package_queue"][0]

    assert top["package_key"] == "pressure_natural_trigger_pair_guttersnipe_young_pyromancer"
    assert top["adds"] == ["Guttersnipe", "Young Pyromancer"]
    assert top["natural_trigger_count"] == 13
    assert top["required_cut_count"] == 2
    assert top["status"] == "blocked_no_seed_safe_cut"
    assert top["gate_ready"] is False


def test_candidate_card_rows_classify_natural_and_near_access():
    payload = build_payload()
    rows = {row["card_name"]: row for row in payload["candidate_cards"]}

    assert rows["Guttersnipe"]["decision"] == "hypothesis_natural_trigger_signal_no_seed_safe_cut"
    assert rows["Young Pyromancer"]["natural_event_count"] == 9
    assert rows["Monastery Mentor"]["decision"] == "blocked_near_access_only_no_seed_safe_cut"


def test_markdown_surfaces_external_support_and_cut_context():
    markdown = planner.render_markdown(build_payload())

    assert "Lorehold Pressure Micro-Package Planner" in markdown
    assert "GameTyrant Lorehold deck tech" in markdown
    assert "Creative Technique" in markdown
