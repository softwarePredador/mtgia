#!/usr/bin/env python3
"""Regression tests for battle_decision_research_review."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("battle_decision_research_review.py")
spec = importlib.util.spec_from_file_location("battle_decision_research_review_under_test", MODULE_PATH)
review = importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)


def write_jsonl(path: Path, rows: list[dict]):
    path.write_text("\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n")


def test_research_review_classifies_categories_from_replay_artifacts():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        seed = root / "seed_1"
        seed.mkdir()
        seed_high = root / "seed_2"
        seed_high.mkdir()
        (root / "summary.json").write_text("{}", encoding="utf-8")
        write_jsonl(seed / "replay.decision_trace.jsonl", [
            {"decision_type": "mulligan_decision", "decision_id": "d1", "chosen_option": {"action": "keep"}},
            {"decision_type": "cast_spell", "decision_id": "d2", "chosen_option": {"card": "Lotus Petal"}},
            {"decision_type": "combat_attack", "decision_id": "d3", "chosen_option": {"target": "B"}},
            {"decision_type": "tutor", "decision_id": "d4", "chosen_option": {"card": "Interaction"}},
            {"decision_type": "board_wipe", "decision_id": "d5", "chosen_option": {"card": "Wrath"}},
        ])
        (seed / "strategy_audit.json").write_text(json.dumps({
            "summary": {
                "learning_confidence": "low_confidence_replay",
                "high_confidence_learning_eligible": False,
                "high_confidence_learning_weight": 0.0,
            },
            "findings": [
                {"severity": "high", "code": "ramp_ritual_without_unlock_signal"},
                {"severity": "medium", "code": "board_wipe_without_clear_asymmetry"},
                {
                    "severity": "high",
                    "code": "spending_last_land",
                    "detail": "sacrifice_land consumed the player's last available land.",
                },
            ],
        }), encoding="utf-8")
        write_jsonl(seed_high / "replay.decision_trace.jsonl", [
            {"decision_type": "pass_no_action", "decision_id": "d6", "chosen_option": {"action": "pass"}},
        ])
        (seed_high / "strategy_audit.json").write_text(json.dumps({
            "summary": {
                "learning_confidence": "high_confidence_replay",
                "high_confidence_learning_eligible": True,
                "high_confidence_learning_weight": 1.0,
            },
            "findings": [],
        }), encoding="utf-8")

        result = review.aggregate(root)

    assert result["seeds"] == 2
    assert result["strategy_learning_confidence_counts"] == {
        "high_confidence_replay": 1,
        "low_confidence_replay": 1,
    }
    assert result["strategy_low_confidence_seeds"] == ["1"]
    assert result["strategy_high_confidence_learning_seeds"] == ["2"]
    assert result["categories"]["mulligan"]["status"] == "coherent_in_sample"
    assert result["categories"]["fast_mana_one_shot"]["status"] == "blocked_or_needs_review"
    assert result["categories"]["mox_land_discard"]["status"] == "coherent_in_sample"
    assert result["categories"]["sacrifice_land"]["status"] == "blocked_or_needs_review"
    assert result["categories"]["tutor"]["status"] == "coherent_in_sample"
    assert result["categories"]["board_wipe_wheel"]["status"] == "blocked_or_needs_review"


def test_research_review_renders_sources():
    result = {
        "input_dir": "/tmp/x",
        "seeds": 0,
        "decision_counts": {},
        "finding_counts": {},
        "strategy_learning_confidence_counts": {"high_confidence_replay": 1},
        "strategy_high_confidence_learning_seeds": ["1"],
        "strategy_low_confidence_seeds": [],
        "strategy_not_learning_eligible_seeds": [],
        "categories": {
            "mulligan": {
                "status": "not_observed",
                "observed_decisions": 0,
                "finding_count": 0,
                "finding_codes": {},
                "official_sources": ["https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03"],
                "strategy_sources": ["https://draftsim.com/mtg-mulligan-rules/"],
                "expected_trace": "lands",
                "current_guardrail": "no land-only keep",
            }
        },
    }

    markdown = review.render_markdown(result)

    assert "# Battle Decision Research Review" in markdown
    assert "london-mulligan" in markdown
    assert "draftsim" in markdown
    assert "Strategy learning confidence counts" in markdown


if __name__ == "__main__":
    tests = [
        test_research_review_classifies_categories_from_replay_artifacts,
        test_research_review_renders_sources,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
