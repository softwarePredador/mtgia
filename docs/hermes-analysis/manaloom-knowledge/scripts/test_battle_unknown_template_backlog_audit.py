#!/usr/bin/env python3
"""Tests for battle unknown template backlog audit."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import battle_unknown_template_backlog_audit as audit_module


def write_coverage(tmp: Path, unknown_cards: list[dict]) -> Path:
    path = tmp / "coverage.json"
    path.write_text(json.dumps({"unknown_cards": unknown_cards}), encoding="utf-8")
    return path


def test_known_unknown_cards_have_reviewed_families_and_plans():
    with tempfile.TemporaryDirectory() as raw_tmp:
        coverage = write_coverage(
            Path(raw_tmp),
            [
                {
                    "name": "Hidden Strings",
                    "type_line": "Sorcery",
                    "effect": "unknown",
                    "oracle_sample": (
                        "You may tap or untap target permanent, then you may tap "
                        "or untap another target permanent. Cipher"
                    ),
                    "flags": ["trigger_not_explicit", "unknown_effect"],
                    "decks": ["Akiri, Line-Slinger #30 (real)"],
                },
                {
                    "name": "God-Pharaoh's Statue",
                    "type_line": "Legendary Artifact",
                    "effect": "unknown",
                    "oracle_sample": (
                        "Spells your opponents cast cost {2} more to cast. At the "
                        "beginning of your end step, each opponent loses 1 life."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Magda, Brazen Outlaw #71 (real)"],
                },
            ],
        )

        audit = audit_module.build_audit(coverage)

    summary = audit["summary"]
    assert summary["unknown_cards"] == 2
    assert summary["without_current_inferred_family"] == 0
    assert summary["without_reviewed_family"] == 0
    assert summary["without_plan_or_waiver"] == 0
    assert summary["without_focused_template_match"] == 0
    assert summary["status"] == "focused_template_backlog_ready"
    by_name = {item["name"]: item for item in audit["items"]}
    assert "tap_untap_cipher_trigger" in by_name["Hidden Strings"]["current_inferred_families"]
    assert (
        "static_tax_and_opponent_life_loss"
        in by_name["God-Pharaoh's Statue"]["current_inferred_families"]
    )
    assert by_name["Hidden Strings"]["plan_status"] == "focused_template_ready"
    assert by_name["Hidden Strings"]["focused_template_matches"]


def test_backlog_separates_source_unknown_from_effect_unknown_denominator():
    with tempfile.TemporaryDirectory() as raw_tmp:
        path = Path(raw_tmp) / "coverage.json"
        path.write_text(
            json.dumps(
                {
                    "unknown_cards": [],
                    "unknown_effect_cards": [
                        {
                            "name": "Hidden Strings",
                            "effect": "unknown",
                            "source": "focused_template_ready",
                            "status": "focused_template_ready",
                        },
                        {
                            "name": "Blood Moon",
                            "effect": "unknown",
                            "source": "battle_rule_needs_review_generated",
                            "status": "needs_review",
                        },
                    ],
                }
            ),
            encoding="utf-8",
        )

        audit = audit_module.build_audit(path)

    summary = audit["summary"]
    assert summary["unknown_cards"] == 0
    assert summary["source_unknown_cards"] == 0
    assert summary["effect_unknown_cards"] == 2
    assert summary["effect_unknown_status_counts"] == {
        "focused_template_ready": 1,
        "needs_review": 1,
    }
    assert summary["effect_unknown_source_counts"] == {
        "battle_rule_needs_review_generated": 1,
        "focused_template_ready": 1,
    }


def test_current_backlog_representatives_have_focused_template_matches():
    with tempfile.TemporaryDirectory() as raw_tmp:
        coverage = write_coverage(
            Path(raw_tmp),
            [
                {
                    "name": "Hidden Strings",
                    "type_line": "Sorcery",
                    "effect": "unknown",
                    "oracle_sample": (
                        "You may tap or untap target permanent, then you may tap "
                        "or untap another target permanent. Cipher"
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Submerge",
                    "type_line": "Instant",
                    "effect": "unknown",
                    "oracle_sample": (
                        "If an opponent controls a Forest and you control an Island, "
                        "you may cast this spell without paying its mana cost. "
                        "Put target creature on top of its owner's library."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Stoke the Flames",
                    "type_line": "Instant",
                    "effect": "unknown",
                    "oracle_sample": (
                        "Convoke. Stoke the Flames deals 4 damage to any target."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Sudden Shock",
                    "type_line": "Instant",
                    "effect": "unknown",
                    "oracle_sample": (
                        "Split second. Sudden Shock deals 2 damage to any target."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Tragic Arrogance",
                    "type_line": "Sorcery",
                    "effect": "unknown",
                    "oracle_sample": (
                        "For each player, you choose from among the permanents that "
                        "player controls an artifact, a creature, an enchantment, "
                        "and a planeswalker. Then each player sacrifices all other "
                        "nonland permanents they control."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Cryptic Coat",
                    "type_line": "Artifact - Equipment",
                    "effect": "unknown",
                    "oracle_sample": (
                        "When this Equipment enters, cloak the top card of your "
                        "library, then attach this Equipment to it."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Candelabra of Tawnos",
                    "type_line": "Artifact",
                    "effect": "unknown",
                    "oracle_sample": "{X}, {T}: Untap X target lands.",
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
                {
                    "name": "Firestorm",
                    "type_line": "Instant",
                    "effect": "unknown",
                    "oracle_sample": (
                        "As an additional cost to cast this spell, discard X cards. "
                        "Firestorm deals X damage to each of X targets."
                    ),
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                },
            ],
        )

        audit = audit_module.build_audit(coverage)

    summary = audit["summary"]
    assert summary["unknown_cards"] == 8
    assert summary["without_focused_template_match"] == 0
    assert summary["plan_status_counts"] == {"focused_template_ready": 8}
    for item in audit["items"]:
        assert item["focused_template_matches"], item["name"]


def test_unplanned_unknown_card_is_reported():
    with tempfile.TemporaryDirectory() as raw_tmp:
        coverage = write_coverage(
            Path(raw_tmp),
            [
                {
                    "name": "Unplanned Mystery",
                    "type_line": "Sorcery",
                    "effect": "unknown",
                    "oracle_sample": "Do a very specific thing not present in the backlog.",
                    "flags": ["unknown_effect"],
                    "decks": ["Fixture"],
                }
            ],
        )

        audit = audit_module.build_audit(coverage)

    summary = audit["summary"]
    assert summary["status"] == "review_required"
    assert summary["without_reviewed_family"] == 1
    assert summary["without_plan_or_waiver"] == 1
    assert summary["unknowns_without_plan_or_waiver"] == ["Unplanned Mystery"]


if __name__ == "__main__":
    tests = [
        test_known_unknown_cards_have_reviewed_families_and_plans,
        test_backlog_separates_source_unknown_from_effect_unknown_denominator,
        test_current_backlog_representatives_have_focused_template_matches,
        test_unplanned_unknown_card_is_reported,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
