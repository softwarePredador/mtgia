#!/usr/bin/env python3
"""Focused runtime tests for static one-spell-per-turn restrictions."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_static_spell_limit_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def focused_rule(battle, name):
    return battle.with_rule_metadata(
        battle.HANDCRAFTED_KNOWN_CARD_RULES[name],
        source="manual_runtime_waiver",
        review_status="verified",
        execution_status="auto",
        confidence=1.0,
        logical_rule_key=battle.HANDCRAFTED_KNOWN_CARD_RULES[name].get("_rule_logical_key"),
        oracle_hash=battle.HANDCRAFTED_KNOWN_CARD_RULES[name].get("_rule_oracle_hash"),
    )


def test_deafening_silence_blocks_second_noncreature_but_allows_creature():
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    effect = focused_rule(battle, "Deafening Silence")

    battle.apply_effect_immediate(
        active,
        [opponent],
        {"name": "Deafening Silence", "type_line": "Enchantment"},
        turn=1,
        rng=random.Random(1),
        effect_data_override=effect,
    )
    active.record_spell_cast(turn_marker=1, card={"name": "Ponder", "type_line": "Sorcery"})
    active.record_noncreature_spell_cast(turn_marker=1)

    assert battle.can_cast_in_phase(
        {"name": "Lightning Bolt", "type_line": "Instant"},
        {"effect": "direct_damage"},
        "precombat_main",
        controller=active,
    ) is False
    assert battle.can_cast_in_phase(
        {"name": "Esper Sentinel", "type_line": "Creature - Human Soldier"},
        {"effect": "creature"},
        "precombat_main",
        controller=active,
    ) is True


def test_eidolon_blocks_second_spell_of_any_type_for_each_player():
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    effect = focused_rule(battle, "Eidolon of Rhetoric")

    battle.apply_effect_immediate(
        active,
        [opponent],
        {"name": "Eidolon of Rhetoric", "type_line": "Enchantment Creature - Spirit"},
        turn=2,
        rng=random.Random(2),
        effect_data_override=effect,
    )
    opponent.record_spell_cast(turn_marker=2, card={"name": "Sol Ring", "type_line": "Artifact"})

    assert battle.can_cast_in_phase(
        {"name": "Memnite", "type_line": "Artifact Creature - Construct"},
        {"effect": "creature"},
        "precombat_main",
        controller=opponent,
    ) is False


def test_ethersworn_canonist_allows_artifact_after_nonartifact_but_blocks_nonartifact():
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    effect = focused_rule(battle, "Ethersworn Canonist")

    battle.apply_effect_immediate(
        active,
        [opponent],
        {"name": "Ethersworn Canonist", "type_line": "Artifact Creature - Human Cleric"},
        turn=3,
        rng=random.Random(3),
        effect_data_override=effect,
    )
    opponent.record_spell_cast(turn_marker=3, card={"name": "Brainstorm", "type_line": "Instant"})

    assert battle.can_cast_in_phase(
        {"name": "Dark Ritual", "type_line": "Instant"},
        {"effect": "ramp_ritual"},
        "precombat_main",
        controller=opponent,
    ) is False
    assert battle.can_cast_in_phase(
        {"name": "Mox Opal", "type_line": "Artifact"},
        {"effect": "ramp_permanent"},
        "precombat_main",
        controller=opponent,
    ) is True


def test_archon_registers_spell_limit_and_taps_opponent_nonbasic_lands():
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    effect = focused_rule(battle, "Archon of Emeria")

    battle.apply_effect_immediate(
        active,
        [opponent],
        {"name": "Archon of Emeria", "type_line": "Creature - Archon"},
        turn=4,
        rng=random.Random(4),
        effect_data_override=effect,
    )
    opponent.record_spell_cast(turn_marker=4, card={"name": "Llanowar Elves", "type_line": "Creature - Elf"})
    assert battle.can_cast_in_phase(
        {"name": "Forest Bear", "type_line": "Creature - Bear"},
        {"effect": "creature"},
        "precombat_main",
        controller=opponent,
    ) is False

    land = battle.prepare_entering_permanent(
        {"name": "Command Tower", "type_line": "Land"},
        controller=opponent,
        all_players=[active, opponent],
        turn=4,
    )
    assert land["tapped"] is True
    assert land["entered_tapped_by_static"] == "Archon of Emeria"
