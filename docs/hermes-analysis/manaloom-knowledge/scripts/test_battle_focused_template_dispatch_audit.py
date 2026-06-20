#!/usr/bin/env python3
"""Tests for focused template dispatch readiness audit."""

from __future__ import annotations

import tempfile
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import battle_focused_template_dispatch_audit as audit_module


@dataclass
class FakeDraftRecord:
    run_id: str
    card_name: str
    oracle_id: str | None
    set_code: str
    draft_rule_key: str
    proposed_status: str
    confidence: str
    roles: list[str]
    effect_families: list[str]
    risk_flags: list[str]
    draft: dict[str, Any]


@dataclass
class FakeEvidenceResult:
    status: str
    reason: str
    artifacts: list[str]


def supports_ready_template(draft: FakeDraftRecord) -> bool:
    return "ready_family" in draft.effect_families


def supports_nondispatched_template(draft: FakeDraftRecord) -> bool:
    return "nondispatched_family" in draft.effect_families


def evaluate_draft(draft: FakeDraftRecord, output_dir: Path) -> FakeEvidenceResult:
    if supports_ready_template(draft):
        return FakeEvidenceResult("evidence_ready", "ready_family_supported", [str(output_dir / "focused_test.json")])
    return FakeEvidenceResult("unsupported", "no_focused_evidence_template_for_effect_family", [])


def build_ready_evidence(_draft: FakeDraftRecord, _output_dir: Path) -> FakeEvidenceResult:
    return FakeEvidenceResult("evidence_ready", "ready_family_supported", [])


FOCUSED_MODULE = SimpleNamespace(
    DraftRecord=FakeDraftRecord,
    build_ready_evidence=build_ready_evidence,
    evaluate_draft=evaluate_draft,
    supports_nondispatched_template=supports_nondispatched_template,
    supports_ready_template=supports_ready_template,
)


def review_module_for(*families: str):
    return SimpleNamespace(infer_effect_families_from_text=lambda _text: list(families))


def backlog_module(plan: dict[str, dict[str, Any]] | None = None):
    return SimpleNamespace(BACKLOG_PLAN=plan or {})


def build(coverage: dict[str, Any], review_module=None, backlog=None) -> dict[str, Any]:
    with tempfile.TemporaryDirectory() as tmp_name:
        return audit_module.build_audit_from_modules(
            coverage,
            review_module or review_module_for(),
            FOCUSED_MODULE,
            backlog or backlog_module(),
            Path(tmp_name),
        )


def test_dispatch_ready_card_passes():
    audit = build(
        {
            "focused_template_cards": [
                {"name": "Ready Card", "oracle_sample": "ready", "flags": []},
            ]
        },
        review_module=review_module_for("ready_family"),
    )

    summary = audit["summary"]
    assert summary["status"] == "focused_template_dispatch_ready"
    assert summary["template_predicate_match"] == 1
    assert summary["evidence_dispatch_ready"] == 1
    assert summary["focused_evidence_ready"] == 1


def test_predicate_without_dispatch_blocks():
    audit = build(
        {
            "focused_template_cards": [
                {"name": "Blocked Card", "oracle_sample": "blocked", "flags": []},
            ]
        },
        review_module=review_module_for("nondispatched_family"),
    )

    summary = audit["summary"]
    assert summary["status"] == "review_required"
    assert summary["template_predicate_match"] == 1
    assert summary["evidence_dispatch_ready"] == 0
    assert summary["focused_evidence_not_ready_unwaived"] == 1
    assert summary["evidence_runner_status_counts"] == {"unsupported": 1}


def test_accepted_waiver_allows_nondispatched_card():
    audit = build(
        {
            "focused_template_cards": [
                {"name": "Waived Card", "oracle_sample": "waived", "flags": []},
            ]
        },
        review_module=review_module_for("nondispatched_family"),
        backlog=backlog_module(
            {
                "Waived Card": {
                    "families": ["nondispatched_family"],
                    "dispatch_waiver_status": "accepted",
                    "dispatch_waiver_reason": "fixture not required for this family",
                }
            }
        ),
    )

    summary = audit["summary"]
    assert summary["status"] == "focused_template_dispatch_ready"
    assert summary["accepted_waivers"] == 1
    assert summary["focused_evidence_not_ready_unwaived"] == 0


def test_real_priority_template_builders_emit_ready_artifacts():
    focused_module = audit_module.load_module(
        "focused_evidence_real_priority_builders_test",
        audit_module.SERVER_BIN / "manaloom_battle_rule_focused_evidence.py",
    )
    coverage = {
        "focused_template_cards": [
            {
                "name": "Cryptic Coat",
                "oracle_sample": (
                    "When Cryptic Coat enters the battlefield, cloak the top card of your library, "
                    "then attach Cryptic Coat to it."
                ),
                "flags": [],
            },
            {
                "name": "Cursed Windbreaker",
                "oracle_sample": (
                    "When Cursed Windbreaker enters the battlefield, manifest dread, "
                    "then attach Cursed Windbreaker to it."
                ),
                "flags": [],
            },
            {
                "name": "Dissection Tools",
                "oracle_sample": (
                    "When Dissection Tools enters the battlefield, manifest dread, "
                    "then attach Dissection Tools to it."
                ),
                "flags": [],
            },
            {
                "name": "Heroes' Hangout",
                "oracle_sample": (
                    "Exile the top two cards of your library. Until the end of your next turn, "
                    "you may play those cards."
                ),
                "flags": [],
            },
            {
                "name": "Opera Love Song",
                "oracle_sample": (
                    "Exile the top card of your library. Until the end of your next turn, "
                    "you may play that card."
                ),
                "flags": [],
            },
        ]
    }
    plan = {
        "Cryptic Coat": {"families": ["manifest_cloak_equipment"]},
        "Cursed Windbreaker": {"families": ["manifest_cloak_equipment"]},
        "Dissection Tools": {"families": ["manifest_cloak_equipment"]},
        "Heroes' Hangout": {"families": ["impulse_topdeck_or_library_zone"]},
        "Opera Love Song": {"families": ["impulse_topdeck_or_library_zone"]},
    }
    with tempfile.TemporaryDirectory() as tmp_name:
        audit = audit_module.build_audit_from_modules(
            coverage,
            review_module_for(),
            focused_module,
            backlog_module(plan),
            Path(tmp_name),
        )

    summary = audit["summary"]
    assert summary["status"] == "focused_template_dispatch_ready"
    assert summary["focused_template_cards"] == 5
    assert summary["evidence_dispatch_ready"] == 5
    assert summary["focused_evidence_ready"] == 5
    assert summary["focused_evidence_not_ready_unwaived"] == 0
    assert summary["evidence_runner_status_counts"] == {"evidence_ready": 5}
    assert {
        item["name"]
        for item in audit["items"]
        if item["evidence_artifacts"]
    } == {
        "Cryptic Coat",
        "Cursed Windbreaker",
        "Dissection Tools",
        "Heroes' Hangout",
        "Opera Love Song",
    }


def test_real_backlog_template_builders_emit_ready_artifacts():
    focused_module = audit_module.load_module(
        "focused_evidence_real_backlog_builders_test",
        audit_module.SERVER_BIN / "manaloom_battle_rule_focused_evidence.py",
    )
    coverage = {
        "focused_template_cards": [
            {
                "name": "Ashnod's Transmogrant",
                "oracle_sample": (
                    "{T}, Sacrifice this artifact: Put a +1/+1 counter on target nonartifact creature. "
                    "That creature becomes an artifact in addition to its other types."
                ),
                "flags": [],
            },
            {
                "name": "Banishing Knack",
                "oracle_sample": (
                    "Until end of turn, target creature gains \"{T}: Return target nonland permanent "
                    "to its owner's hand.\""
                ),
                "flags": [],
            },
            {
                "name": "Candelabra of Tawnos",
                "oracle_sample": "{X}, {T}: Untap X target lands.",
                "flags": [],
            },
            {
                "name": "Clown Car",
                "oracle_sample": (
                    "When this Vehicle enters, roll X six-sided dice. For each odd result, create a "
                    "1/1 white Clown Robot artifact creature token. For each even result, put a +1/+1 "
                    "counter on this Vehicle."
                ),
                "flags": [],
            },
            {
                "name": "Codex Shredder",
                "oracle_sample": (
                    "{T}: Target player mills a card. {5}, {T}, Sacrifice this artifact: Return target "
                    "card from your graveyard to your hand."
                ),
                "flags": [],
            },
            {
                "name": "Copy Artifact",
                "oracle_sample": (
                    "You may have this enchantment enter as a copy of any artifact on the battlefield, "
                    "except it's an enchantment in addition to its other types."
                ),
                "flags": [],
            },
            {
                "name": "Firestorm",
                "oracle_sample": (
                    "As an additional cost to cast this spell, discard X cards. Firestorm deals X "
                    "damage to each of X targets."
                ),
                "flags": [],
            },
            {
                "name": "Flash Photography",
                "oracle_sample": (
                    "You may cast this spell as though it had flash if it targets a permanent you control. "
                    "Create a token that's a copy of target permanent. Flashback {4}{U}{U}."
                ),
                "flags": [],
            },
            {
                "name": "God-Pharaoh's Statue",
                "oracle_sample": (
                    "Spells your opponents cast cost {2} more to cast. At the beginning of your end step, "
                    "each opponent loses 1 life."
                ),
                "flags": [],
            },
            {
                "name": "Hidden Strings",
                "oracle_sample": (
                    "You may tap or untap target permanent, then you may tap or untap another target "
                    "permanent. Cipher."
                ),
                "flags": [],
            },
            {
                "name": "Kindle the Inner Flame",
                "oracle_sample": (
                    "Create a token that's a copy of target creature you control, except it has haste and "
                    "\"At the beginning of the end step, sacrifice this token.\" Flashback-{1}{R}."
                ),
                "flags": [],
            },
            {
                "name": "Liquimetal Coating",
                "oracle_sample": (
                    "{T}: Target permanent becomes an artifact in addition to its other types until end of turn."
                ),
                "flags": [],
            },
            {
                "name": "Mine Collapse",
                "oracle_sample": (
                    "If it's your turn, you may sacrifice a Mountain rather than pay this spell's mana cost. "
                    "Mine Collapse deals 5 damage to target creature or planeswalker."
                ),
                "flags": [],
            },
            {
                "name": "Nevermore",
                "oracle_sample": (
                    "As this enchantment enters, choose a nonland card name. Spells with the chosen name "
                    "can't be cast."
                ),
                "flags": [],
            },
            {
                "name": "Out of Time",
                "oracle_sample": (
                    "When this enchantment enters, untap all creatures, then those creatures phase out "
                    "until this enchantment leaves the battlefield. Put a time counter on this enchantment."
                ),
                "flags": [],
            },
            {
                "name": "Power Artifact",
                "oracle_sample": (
                    "Enchant artifact. Enchanted artifact's activated abilities cost {2} less to activate. "
                    "This effect can't reduce the mana in that cost to less than one mana."
                ),
                "flags": [],
            },
            {
                "name": "Reality Acid",
                "oracle_sample": (
                    "Enchant permanent. Vanishing 3. When the last time counter is removed from this Aura, "
                    "sacrifice it and that permanent's controller sacrifices it."
                ),
                "flags": [],
            },
            {
                "name": "Scroll of Fate",
                "oracle_sample": "{T}: Manifest a card from your hand.",
                "flags": [],
            },
            {
                "name": "Stoke the Flames",
                "oracle_sample": "Convoke. Stoke the Flames deals 4 damage to any target.",
                "flags": [],
            },
            {
                "name": "Submerge",
                "oracle_sample": (
                    "If an opponent controls a Forest and you control an Island, you may cast this spell "
                    "without paying its mana cost. Put target creature on top of its owner's library."
                ),
                "flags": [],
            },
            {
                "name": "Sudden Shock",
                "oracle_sample": "Split second. Sudden Shock deals 2 damage to any target.",
                "flags": [],
            },
            {
                "name": "Thorn of Amethyst",
                "oracle_sample": "Noncreature spells cost {1} more to cast.",
                "flags": [],
            },
            {
                "name": "Tragic Arrogance",
                "oracle_sample": (
                    "For each player, you choose from among the permanents that player controls an artifact, "
                    "a creature, an enchantment, and a planeswalker. Then each player sacrifices all other "
                    "nonland permanents they control."
                ),
                "flags": [],
            },
            {
                "name": "Tyvar, Jubilant Brawler",
                "oracle_sample": (
                    "You may activate abilities of creatures you control as though those creatures had haste. "
                    "[+1]: Untap up to one target creature. [-2]: Mill three cards, then you may return a "
                    "creature card from your graveyard to the battlefield."
                ),
                "flags": [],
            },
        ]
    }
    plan = {
        "Ashnod's Transmogrant": {"families": ["counter_manipulation_and_type_change"]},
        "Banishing Knack": {"families": ["tap_untap_bounce_granted_ability"]},
        "Candelabra of Tawnos": {"families": ["utility_artifact_untap_x_lands"]},
        "Clown Car": {"families": ["x_cost_counters_vehicle_token"]},
        "Codex Shredder": {"families": ["mill_and_graveyard_return"]},
        "Copy Artifact": {"families": ["copy_artifact_static_as_enters"]},
        "Firestorm": {"families": ["additional_cost_discard_multi_target_damage"]},
        "Flash Photography": {"families": ["copy_permanent_with_flash_or_flashback"]},
        "God-Pharaoh's Statue": {"families": ["static_tax_and_opponent_life_loss"]},
        "Hidden Strings": {"families": ["tap_untap_cipher_trigger"]},
        "Kindle the Inner Flame": {"families": ["copy_token_with_delayed_sacrifice"]},
        "Liquimetal Coating": {"families": ["type_change_continuous_effect"]},
        "Mine Collapse": {"families": ["alternative_cost_sacrifice_mountain_damage"]},
        "Nevermore": {"families": ["static_named_card_cast_restriction"]},
        "Out of Time": {"families": ["phase_out_mass_removal_counters"]},
        "Power Artifact": {"families": ["cost_reduction_static_aura"]},
        "Reality Acid": {"families": ["vanishing_sacrifice_trigger_removal"]},
        "Scroll of Fate": {"families": ["manifest_from_hand_activated_ability"]},
        "Stoke the Flames": {"families": ["convoke_damage"]},
        "Submerge": {"families": ["alternative_cost_library_bounce"]},
        "Sudden Shock": {"families": ["split_second_damage"]},
        "Thorn of Amethyst": {"families": ["static_noncreature_tax"]},
        "Tragic Arrogance": {"families": ["modal_mass_sacrifice_selection"]},
        "Tyvar, Jubilant Brawler": {
            "families": ["planeswalker_static_and_activated_graveyard_ability"]
        },
    }
    with tempfile.TemporaryDirectory() as tmp_name:
        audit = audit_module.build_audit_from_modules(
            coverage,
            review_module_for(),
            focused_module,
            backlog_module(plan),
            Path(tmp_name),
        )

    summary = audit["summary"]
    assert summary["status"] == "focused_template_dispatch_ready"
    assert summary["focused_template_cards"] == 24
    assert summary["evidence_dispatch_ready"] == 24
    assert summary["focused_evidence_ready"] == 24
    assert summary["focused_evidence_not_ready_unwaived"] == 0
    assert summary["evidence_runner_status_counts"] == {"evidence_ready": 24}
    assert {
        item["name"]
        for item in audit["items"]
        if item["evidence_artifacts"]
    } == {item["name"] for item in coverage["focused_template_cards"]}


if __name__ == "__main__":
    tests = [
        test_dispatch_ready_card_passes,
        test_predicate_without_dispatch_blocks,
        test_accepted_waiver_allows_nondispatched_card,
        test_real_priority_template_builders_emit_ready_artifacts,
        test_real_backlog_template_builders_emit_ready_artifacts,
    ]
    for test in tests:
        test()
    print(f"{len(tests)} tests passed")
