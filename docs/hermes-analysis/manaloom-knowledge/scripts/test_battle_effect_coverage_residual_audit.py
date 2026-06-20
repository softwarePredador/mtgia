#!/usr/bin/env python3
"""Tests for battle effect coverage residual waiver audit."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import battle_effect_coverage_residual_audit as audit_module


def write_coverage(tmp: Path, payload: dict) -> Path:
    path = tmp / "coverage.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_known_residual_flags_are_accepted_when_sources_match_policy():
    with tempfile.TemporaryDirectory() as tmp_name:
        coverage = write_coverage(
            Path(tmp_name),
            {
                "flag_totals": {
                    "heuristic_effect": 2,
                    "land_utility_ability_not_modeled": 1,
                    "needs_review_rule": 1,
                    "trigger_not_explicit": 1,
                },
                "flagged_cards": [
                    {
                        "name": "Effect Map Creature",
                        "effect": "creature",
                        "source": "effect_map",
                        "flags": ["heuristic_effect", "trigger_not_explicit"],
                        "decks": ["Fixture"],
                    },
                    {
                        "name": "Utility Land",
                        "effect": "land",
                        "source": "type_land",
                        "flags": ["land_utility_ability_not_modeled"],
                        "decks": ["Fixture"],
                    },
                    {
                        "name": "Review Rule",
                        "effect": "draw_cards",
                        "source": "battle_rule_needs_review_generated",
                        "flags": ["needs_review_rule"],
                        "decks": ["Fixture"],
                    },
                ],
                "unknown_cards": [],
                "focused_template_cards": [],
            },
        )

        audit = audit_module.build_audit(coverage)

    summary = audit["summary"]
    assert summary["status"] == "effect_coverage_residual_accepted"
    assert summary["unaccepted_card_flag_rows"] == 0
    assert summary["raw_unaccepted_flags"] == []


def test_unknown_effect_remains_unaccepted():
    with tempfile.TemporaryDirectory() as tmp_name:
        coverage = write_coverage(
            Path(tmp_name),
            {
                "flag_totals": {"unknown_effect": 1},
                "flagged_cards": [
                    {
                        "name": "Unknown Card",
                        "effect": "unknown",
                        "source": "unknown",
                        "flags": ["unknown_effect"],
                        "decks": ["Fixture"],
                    }
                ],
                "unknown_cards": [{"name": "Unknown Card"}],
                "focused_template_cards": [],
            },
        )

        audit = audit_module.build_audit(coverage)

    summary = audit["summary"]
    assert summary["status"] == "review_required"
    assert summary["unaccepted_card_flag_rows"] == 1
    assert summary["raw_unaccepted_flags"] == ["unknown_effect"]


def test_source_limited_policy_rejects_mismatched_source():
    with tempfile.TemporaryDirectory() as tmp_name:
        coverage = write_coverage(
            Path(tmp_name),
            {
                "flag_totals": {"land_utility_ability_not_modeled": 1},
                "flagged_cards": [
                    {
                        "name": "Not Land",
                        "effect": "creature",
                        "source": "effect_map",
                        "flags": ["land_utility_ability_not_modeled"],
                        "decks": ["Fixture"],
                    }
                ],
                "unknown_cards": [],
                "focused_template_cards": [],
            },
        )

        audit = audit_module.build_audit(coverage)

    assert audit["summary"]["status"] == "review_required"
    assert audit["unaccepted"][0]["flag"] == "land_utility_ability_not_modeled"


if __name__ == "__main__":
    tests = [
        test_known_residual_flags_are_accepted_when_sources_match_policy,
        test_unknown_effect_remains_unaccepted,
        test_source_limited_policy_rejects_mismatched_source,
    ]
    for test in tests:
        test()
    print(f"{len(tests)} tests passed")
