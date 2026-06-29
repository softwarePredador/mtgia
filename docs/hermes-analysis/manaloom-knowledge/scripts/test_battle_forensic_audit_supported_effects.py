#!/usr/bin/env python3
"""Regression coverage for forensic audit effect support drift."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("battle_forensic_audit.py")
SCRIPT_DIR = MODULE_PATH.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

spec = importlib.util.spec_from_file_location(
    "battle_forensic_audit_under_test",
    MODULE_PATH,
)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)

BATTLE_MODULE_PATH = Path(__file__).with_name("battle_analyst_v9.py")
battle_spec = importlib.util.spec_from_file_location(
    "battle_analyst_v9_under_test",
    BATTLE_MODULE_PATH,
)
battle = importlib.util.module_from_spec(battle_spec)
battle_spec.loader.exec_module(battle)


def test_supported_effects_cover_live_engine_handlers():
    assert "add_mana" in audit.SUPPORTED_EFFECTS
    assert "aetherflux_lifegain" in audit.SUPPORTED_EFFECTS
    assert "aetherflux_reservoir" in audit.SUPPORTED_EFFECTS
    assert "attack_limit" in audit.SUPPORTED_EFFECTS
    assert "attack_tax" in audit.SUPPORTED_EFFECTS
    assert "airbend_other_creatures" in audit.SUPPORTED_EFFECTS
    assert "blink" in audit.SUPPORTED_EFFECTS
    assert "brain_freeze" in audit.SUPPORTED_EFFECTS
    assert "cannot_lose_turn" in audit.SUPPORTED_EFFECTS
    assert "composite_resolution" in audit.SUPPORTED_EFFECTS
    assert "damage_any_target" in audit.SUPPORTED_EFFECTS
    assert "damage_player_and_creatures" in audit.SUPPORTED_EFFECTS
    assert "damage_wipe_treasure" in audit.SUPPORTED_EFFECTS
    assert "graveyard_flashback_grant" in audit.SUPPORTED_EFFECTS
    assert "hand_filter" in audit.SUPPORTED_EFFECTS
    assert "copy_creature_token" in audit.SUPPORTED_EFFECTS
    assert "copy_attached_creature_or_insect" in audit.SUPPORTED_EFFECTS
    assert "copy_permanent_etb" in audit.SUPPORTED_EFFECTS
    assert "create_plant_token_plus_counters" in audit.SUPPORTED_EFFECTS
    assert "create_treasure" in audit.SUPPORTED_EFFECTS
    assert "dig_to_hand" in audit.SUPPORTED_EFFECTS
    assert "direct_damage" in audit.SUPPORTED_EFFECTS
    assert "land_tax" in audit.SUPPORTED_EFFECTS
    assert "equipment_static_attachment" in audit.SUPPORTED_EFFECTS
    assert "exile_top_nonland_free_cast" in audit.SUPPORTED_EFFECTS
    assert "planeswalker" in audit.SUPPORTED_EFFECTS
    assert "redistribute_life_totals" in audit.SUPPORTED_EFFECTS
    assert "removal_exile" in audit.SUPPORTED_EFFECTS
    assert "pile_selection_draw" in audit.SUPPORTED_EFFECTS
    assert "static_cost_reduction" in audit.SUPPORTED_EFFECTS
    assert "thassa_oracle" in audit.SUPPORTED_EFFECTS
    assert "untap_land_engine" in audit.SUPPORTED_EFFECTS


def test_rise_of_the_eldrazi_uses_composite_oracle_runtime():
    rise = battle.get_card_effect(
        {
            "name": "Rise of the Eldrazi",
            "type_line": "Sorcery",
            "oracle_text": (
                "This spell can't be countered.\n"
                "Destroy target permanent. Target player draws four cards. "
                "Take an extra turn after this one.\n"
                "Exile Rise of the Eldrazi."
            ),
            "functional_tags_json": '["removal","big_spell"]',
        }
    )

    assert rise["effect"] == "composite_resolution"
    assert rise["uncounterable"] is True
    assert rise["exiles_self"] is True
    component_effects = [
        component["effect"]
        for component in rise.get("_composite_rule_components", [])
    ]
    assert component_effects == ["remove_permanent", "draw_cards", "extra_turn"]
    assert battle.replay_rule_fields(rise)["composite_rule_component_count"] == 3


def test_runtime_rule_cards_do_not_use_functional_tags():
    barbarian = battle.get_card_effect(
        {
            "name": "Reckless Barbarian",
            "type_line": "Creature - Dragon Barbarian",
            "oracle_text": "Sacrifice Reckless Barbarian: Add RR.",
            "functional_tags_json": '["ramp"]',
        }
    )
    assert barbarian["effect"] == "creature"
    assert barbarian["is_mana_source"] is True
    assert barbarian["mana_produced"] == 2
    assert barbarian["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert barbarian["_rule_review_status"] == "verified"
    assert barbarian["_rule_logical_key"].startswith("battle_rule_v1:")

    ephemerate = battle.get_card_effect(
        {
            "name": "Ephemerate",
            "type_line": "Instant",
            "oracle_text": (
                "Exile target creature you control, then return it to the "
                "battlefield under its owner's control. Rebound."
            ),
            "functional_tags_json": '["removal"]',
        }
    )
    assert ephemerate["effect"] == "blink"
    assert ephemerate["zone_transition"] == "exile_then_return"
    assert ephemerate["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert ephemerate["_rule_review_status"] == "verified"
    assert ephemerate["_rule_logical_key"].startswith("battle_rule_v1:")

    moonsnare = battle.get_card_effect(
        {
            "name": "Moonsnare Prototype",
            "type_line": "Artifact",
            "oracle_text": "Tap an untapped artifact or creature you control: Add C.",
            "functional_tags_json": '["ramp"]',
        }
    )
    assert moonsnare["effect"] == "ramp_permanent"
    assert (
        moonsnare.get("is_mana_source") is True
        or moonsnare.get("mana_source_requires_untapped_artifact_or_creature") is True
    )
    assert moonsnare["mana_produced"] == 1
    assert moonsnare["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert moonsnare["_rule_review_status"] == "verified"
    assert moonsnare["_rule_logical_key"].startswith("battle_rule_v1:")

    sacrifice = battle.get_card_effect(
        {
            "name": "Sacrifice",
            "type_line": "Instant",
            "oracle_text": (
                "As an additional cost to cast this spell, sacrifice a creature. "
                "Add an amount of black mana equal to the sacrificed creature's mana value."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert sacrifice["effect"] == "ramp_ritual"
    assert sacrifice["requires_sacrifice_creature"] is True
    assert sacrifice["mana_produced_from_sacrificed_cmc"] is True
    assert sacrifice["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert sacrifice["_rule_review_status"] == "verified"
    assert sacrifice["_rule_logical_key"].startswith("battle_rule_v1:")

    geosurge = battle.get_card_effect(
        {
            "name": "Geosurge",
            "type_line": "Sorcery",
            "oracle_text": (
                "Add RRRRRRR. Spend this mana only to cast artifact or "
                "creature spells."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert geosurge["effect"] == "ramp_ritual"
    assert geosurge["mana_produced"] == 7
    assert geosurge["restricted_to_spell_categories"] == [
        "artifact_spell",
        "creature_spell",
    ]
    assert geosurge["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert geosurge["_rule_review_status"] == "verified"
    assert geosurge["_rule_logical_key"].startswith("battle_rule_v1:")

    prized_statue = battle.get_card_effect(
        {
            "name": "Prized Statue",
            "type_line": "Artifact",
            "oracle_text": (
                "When this artifact enters or is put into a graveyard from the "
                "battlefield, create a Treasure token."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert prized_statue["effect"] == "ramp_permanent"
    assert prized_statue["treasure_count"] == 1
    assert prized_statue["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert prized_statue["_rule_review_status"] == "verified"
    assert prized_statue["_rule_logical_key"].startswith("battle_rule_v1:")

    jeweled_amulet = battle.get_card_effect(
        {
            "name": "Jeweled Amulet",
            "type_line": "Artifact",
            "oracle_text": (
                "{1}, {T}: Put a charge counter on this artifact. "
                "{T}, Remove a charge counter from this artifact: Add one mana."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert jeweled_amulet["effect"] == "ramp_permanent"
    assert jeweled_amulet["requires_charge_counter_before_mana"] is True
    assert jeweled_amulet["_rule_source"] == "manual_runtime_waiver"
    assert jeweled_amulet["_rule_review_status"] == "verified"

    ponder = battle.get_card_effect(
        {
            "name": "Ponder",
            "type_line": "Sorcery",
            "oracle_text": (
                "Look at the top three cards of your library, then put them "
                "back in any order. You may shuffle. Draw a card."
            ),
            "functional_tags_json": '["draw"]',
        }
    )
    assert ponder["effect"] == "draw_cards"
    assert ponder["count"] == 1
    assert ponder["topdeck_look_count"] == 3
    assert ponder["_rule_source"] == "manual_runtime_waiver"

    vivi = battle.get_card_effect(
        {
            "name": "Vivi Ornitier",
            "type_line": "Legendary Creature - Wizard",
            "oracle_text": (
                "{0}: Add X mana in any combination of {U} and/or {R}, where X "
                "is Vivi Ornitier's power. Whenever you cast a noncreature spell, "
                "put a +1/+1 counter on Vivi Ornitier and it deals 1 damage to "
                "each opponent."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert vivi["effect"] == "creature"
    if vivi["_rule_source"] == "manual_runtime_waiver":
        assert vivi["mana_produced_from_power"] is True
        assert vivi["noncreature_spell_counter_and_ping"] is True
    else:
        assert vivi["trigger"] == "noncreature_spell_cast"
        assert vivi["trigger_effect"] == "damage_each_opponent"
    assert vivi["_rule_source"] in {"manual_runtime_waiver", "curated"}

    faeburrow = battle.get_card_effect(
        {
            "name": "Faeburrow Elder",
            "type_line": "Creature - Treefolk Druid",
            "oracle_text": (
                "Vigilance. Faeburrow Elder gets +1/+1 for each color among "
                "permanents you control. Tap: For each color among permanents "
                "you control, add one mana of that color."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert faeburrow["effect"] == "creature"
    assert faeburrow["is_mana_source"] is True
    assert faeburrow["mana_produced_from_colors_among_permanents"] is True
    assert faeburrow["_rule_source"] in {"manual_runtime_waiver", "curated"}
    assert faeburrow["_rule_review_status"] == "verified"
    assert faeburrow["_rule_logical_key"].startswith("battle_rule_v1:")

    neoform = battle.get_card_effect(
        {
            "name": "Neoform",
            "type_line": "Sorcery",
            "oracle_text": (
                "As an additional cost to cast this spell, sacrifice a creature. "
                "Search your library for a creature card with mana value equal "
                "to 1 plus the sacrificed creature's mana value, put that card "
                "onto the battlefield with an additional +1/+1 counter on it, "
                "then shuffle."
            ),
            "functional_tags_json": '["tutor"]',
        }
    )
    assert neoform["effect"] == "tutor"
    assert neoform["requires_sacrifice_creature"] is True
    assert neoform["destination"] == "battlefield"
    assert neoform["_rule_source"] in {"manual_runtime_waiver", "curated"}


def test_promoted_infernal_plunge_uses_curated_pg_rule_not_functional_tags():
    infernal_plunge = battle.get_card_effect(
        {
            "name": "Infernal Plunge",
            "type_line": "Sorcery",
            "oracle_text": (
                "As an additional cost to cast this spell, sacrifice a creature. "
                "Add RRR."
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert infernal_plunge["effect"] == "ramp_ritual"
    assert infernal_plunge["requires_sacrifice_creature"] is True
    assert infernal_plunge["mana_produced"] == 3
    assert infernal_plunge["battle_model_scope"] == "sacrifice_creature_add_three_red_mana_ritual_v1"
    assert infernal_plunge["_rule_source"] == "curated"
    assert infernal_plunge["_rule_review_status"] == "verified"
    assert infernal_plunge["_rule_execution_status"] == "auto"
    assert (
        infernal_plunge["_rule_logical_key"]
        == "battle_rule_v1:6c79ee0d7eda6f8a02666036cad990fa"
    )
    assert infernal_plunge["_rule_oracle_hash"] == "ffe4781c7469d289573ea15e0e5adbd1"


def test_sacrifice_waiver_uses_sacrificed_creature_mana_value():
    player = battle.Player("Tester", None, [])
    player.battlefield.append(
        {
            "name": "Four Mana Creature",
            "type_line": "Creature",
            "effect": "creature",
            "cmc": 4,
            "power": 3,
            "toughness": 3,
        }
    )
    effect = battle.get_card_effect(
        {
            "name": "Sacrifice",
            "type_line": "Instant",
            "oracle_text": "As an additional cost to cast this spell, sacrifice a creature.",
        }
    )

    assert battle.pay_additional_card_costs(
        player,
        {"name": "Sacrifice"},
        effect,
        turn=1,
    ) is True
    assert effect["_last_sacrificed_cmc"] == 4
    assert battle.ritual_mana_produced(player, effect) == 4


def test_brain_freeze_runtime_resolves_storm_mill_event():
    player = battle.Player("Lorehold", None, [])
    opponent = battle.Player(
        "Opponent",
        None,
        [
            {"name": f"Library Card {index}", "type_line": "Creature"}
            for index in range(1, 11)
        ],
    )
    player.spells_cast_this_turn = 3
    spell = {
        "name": "Brain Freeze",
        "type_line": "Instant",
    }
    effect = {
        "effect": "brain_freeze",
        "mill_count": 3,
        "storm": True,
        "target": "player",
        "card_id": 999001,
        "semantic_hash": "sha256:brain-freeze-runtime-test",
        "_rule_source": "postgres",
        "_rule_review_status": "verified",
        "_rule_execution_status": "verified_auto",
        "_rule_confidence": 1.0,
        "_rule_version": "xmage_mapper_runtime_batch_v1",
        "_rule_logical_key": (
            "battle_rule_v1:brain-freeze:"
            "storm-target-player-mill-fixed-count-v1"
        ),
    }
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            player,
            [opponent],
            spell,
            turn=4,
            rng=random.Random(17),
            effect_data_override=effect,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    mill_events = [data for event, data in events if event == "mill_resolved"]
    assert len(mill_events) == 1
    resolved = mill_events[0]
    assert resolved["card"] == "Brain Freeze"
    assert resolved["target_player"] == "Opponent"
    assert resolved["copies"] == 3
    assert resolved["storm_copies"] == 2
    assert resolved["requested_mill"] == 9
    assert resolved["cards_milled"] == 9
    assert resolved["target_library_before"] == 10
    assert resolved["target_library_after"] == 1
    assert len(opponent.graveyard) == 9
    assert len(opponent.library) == 1
    assert spell in player.graveyard
    assert resolved["rule_source"] == "postgres"
    assert resolved["rule_execution_status"] == "verified_auto"
    assert resolved["rule_logical_key"].endswith("storm-target-player-mill-fixed-count-v1")


def test_forensic_accepts_manual_runtime_waiver_over_stale_registry_rule():
    events = [
        {
            "event": "spell_cast",
            "card": "Reckless Barbarian",
            "effect": "creature",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-2",
            "turn": 2,
        },
        {
            "event": "spell_resolved",
            "card": "Ephemerate",
            "effect": "protect_creature",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-3",
            "turn": 4,
        },
        {
            "event": "spell_cast",
            "card": "Moonsnare Prototype",
            "effect": "ramp_permanent",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-4",
            "turn": 9,
        },
        {
            "event": "spell_cast",
            "card": "Sacrifice",
            "effect": "ramp_ritual",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-5",
            "turn": 4,
        },
        {
            "event": "spell_cast",
            "card": "Prized Statue",
            "effect": "ramp_permanent",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-6",
            "turn": 5,
        },
        {
            "event": "spell_cast",
            "card": "Jeweled Amulet",
            "effect": "ramp_permanent",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-7",
            "turn": 1,
        },
        {
            "event": "spell_resolved",
            "card": "Ponder",
            "effect": "draw_cards",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-8",
            "turn": 2,
        },
        {
            "event": "commander_cast",
            "card": "Vivi Ornitier",
            "effect": "creature",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-9",
            "turn": 4,
        },
        {
            "event": "spell_resolved",
            "card": "Neoform",
            "effect": "tutor",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-10",
            "turn": 9,
        },
        {
            "event": "spell_cast",
            "card": "Geosurge",
            "effect": "ramp_ritual",
            "rule_source": "manual_runtime_waiver",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:manual-waiver-test-11",
            "turn": 9,
        },
    ]
    stale_rules = {
        "ephemerate": {
            "effect_json": {"effect": "remove_creature"},
            "source": "generated",
            "review_status": "needs_review",
        }
    }

    findings, summary = audit.audit_rule_provenance(events, stale_rules)

    assert findings == []
    assert summary["by_source"]["manual_runtime_waiver"] == 10
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing"] == 10
    assert summary["card_id_missing_accepted"] == 10
    assert summary["card_id_missing_unaccepted"] == 0
    assert summary["semantic_hash_missing"] == 10
    assert summary["semantic_hash_missing_accepted"] == 10
    assert summary["semantic_hash_missing_unaccepted"] == 0
    assert summary["lineage_missing_waiver_reasons"] == {
        "manual_runtime_waiver_without_pg_identity": 20
    }


def test_veil_of_summer_promoted_rule_has_identity_for_forensic():
    effect = battle.get_card_effect(
        {
            "name": "Veil of Summer",
            "type_line": "Instant",
            "oracle_text": (
                "Draw a card if an opponent has cast a blue or black spell this turn. "
                "Spells you control can't be countered this turn. You and permanents you control "
                "gain hexproof from blue and from black until end of turn."
            ),
            "functional_tags_json": '["draw"]',
        }
    )
    assert effect["effect"] == "draw_cards"
    assert effect["count"] == 1
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_review_status"] == "verified"
    fields = battle.replay_rule_fields(effect)
    events = [
        {
            "event": "spell_cast",
            "card": "Veil of Summer",
            "effect": "draw_cards",
            "turn": 4,
            **fields,
        },
        {
            "event": "spell_resolved",
            "card": "Veil of Summer",
            "effect": "draw_cards",
            "turn": 4,
            **fields,
        },
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["by_source"]["curated"] == 2
    assert summary["by_status"]["verified"] == 2
    assert summary["by_effect"]["draw_cards"] == 2
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing_unaccepted"] == 2
    assert summary["semantic_hash_missing_unaccepted"] == 2


def test_rishkar_promoted_rule_has_identity_for_forensic():
    effect = battle.get_card_effect(
        {
            "name": "Rishkar, Peema Renegade",
            "type_line": "Legendary Creature - Elf Druid",
            "oracle_text": (
                "When Rishkar enters, put a +1/+1 counter on each of up to two target creatures. "
                "Each creature you control with a counter on it has \"{T}: Add {G}.\""
            ),
            "functional_tags_json": '["ramp"]',
        }
    )
    assert effect["effect"] == "creature"
    assert effect["etb_plus_one_counter_targets"] == 2
    assert effect["countered_creatures_tap_for_mana"] is True
    assert effect["_rule_source"] == "curated"
    assert effect["_rule_review_status"] == "verified"
    fields = battle.replay_rule_fields(effect)
    events = [
        {
            "event": "spell_cast",
            "card": "Rishkar, Peema Renegade",
            "effect": "creature",
            "turn": 7,
            **fields,
        },
        {
            "event": "spell_resolved",
            "card": "Rishkar, Peema Renegade",
            "effect": "creature",
            "turn": 7,
            **fields,
        },
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["by_source"]["curated"] == 2
    assert summary["by_status"]["verified"] == 2
    assert summary["by_effect"]["creature"] == 2
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing_unaccepted"] == 2
    assert summary["semantic_hash_missing_unaccepted"] == 2


def test_aura_of_silence_promoted_rule_has_identity_for_forensic():
    effect = battle.get_card_effect(
        {
            "name": "Aura of Silence",
            "type_line": "Enchantment",
            "oracle_text": (
                "Artifact and enchantment spells your opponents cast cost {2} more to cast.\n"
                "Sacrifice this enchantment: Destroy target artifact or enchantment."
            ),
            "functional_tags_json": '["removal"]',
        }
    )
    fields = battle.replay_rule_fields(effect)
    events = [
        {
            "event": "spell_cast",
            "card": "Aura of Silence",
            "effect": "remove_permanent",
            "turn": 10,
            **fields,
        },
        {
            "event": "spell_resolved",
            "card": "Aura of Silence",
            "effect": "remove_permanent",
            "turn": 10,
            **fields,
        },
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["by_source"]["curated"] == 2
    assert summary["by_status"]["verified"] == 2
    assert summary["by_effect"]["remove_permanent"] == 2
    assert summary["card_id_missing"] == 2
    assert summary["semantic_hash_missing"] == 2
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing_unaccepted"] == 2
    assert summary["semantic_hash_missing_unaccepted"] == 2


def test_forensic_accepts_type_line_creature_fact_without_rule_identity():
    events = [
        {
            "event": "creature_cast",
            "card": "Young Wolf",
            "effect": "creature",
            "rule_source": "type_line_creature",
            "rule_review_status": "verified",
            "turn": 2,
        }
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["rule_logical_key_missing"] == 1
    assert summary["rule_logical_key_missing_accepted"] == 1
    assert summary["rule_logical_key_missing_unaccepted"] == 0
    assert summary["card_id_missing"] == 1
    assert summary["card_id_missing_accepted"] == 1
    assert summary["card_id_missing_unaccepted"] == 0
    assert summary["semantic_hash_missing"] == 1
    assert summary["semantic_hash_missing_accepted"] == 1
    assert summary["semantic_hash_missing_unaccepted"] == 0
    assert summary["lineage_missing_waiver_reasons"] == {
        "type_line_creature_fact_no_rule_identity": 3
    }


def test_forensic_accepts_curated_land_played_runtime_rule_without_pg_card_identity():
    events = [
        {
            "event": "land_played",
            "card": "Blood Crypt",
            "effect": "land",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:bulk-land-rule",
            "turn": 1,
        }
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing"] == 1
    assert summary["card_id_missing_accepted"] == 1
    assert summary["card_id_missing_unaccepted"] == 0
    assert summary["semantic_hash_missing"] == 1
    assert summary["semantic_hash_missing_accepted"] == 1
    assert summary["semantic_hash_missing_unaccepted"] == 0
    assert summary["lineage_missing_waiver_reasons"] == {
        "land_played_curated_runtime_rule_without_pg_card_identity": 2
    }


def test_forensic_accepts_composite_runtime_over_primary_registry_effect():
    events = [
        {
            "event": "spell_resolved",
            "card": "Rise of the Eldrazi",
            "effect": "composite_resolution",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:rise-primary-extra-turn",
            "turn": 7,
        }
    ]
    rules = {
        "rise of the eldrazi": {
            "effect_json": {"effect": "extra_turn"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:rise-primary-extra-turn",
        }
    }

    findings, summary = audit.audit_rule_provenance(events, rules)

    assert findings == []
    assert summary["by_effect"]["composite_resolution"] == 1
    assert summary["rule_logical_key_missing"] == 0
    assert summary["card_id_missing"] == 1
    assert summary["card_id_missing_accepted"] == 1
    assert summary["card_id_missing_unaccepted"] == 0
    assert summary["semantic_hash_missing"] == 1
    assert summary["semantic_hash_missing_accepted"] == 1
    assert summary["semantic_hash_missing_unaccepted"] == 0
    assert summary["lineage_missing_waiver_reasons"] == {
        "battle_rule_registry_without_card_identity_columns": 2
    }


def test_oracle_normalized_creature_bounce_marks_effect_override():
    flood_maw = battle.get_card_effect(
        {
            "name": "Into the Flood Maw",
            "cmc": 1,
            "type_line": "Instant",
            "oracle_text": "Return target creature to its owner's hand. Gift a tapped Fish.",
        }
    )
    fields = battle.replay_rule_fields(flood_maw)

    assert flood_maw["effect"] == "remove_creature"
    assert flood_maw["target"] == "creature"
    assert flood_maw["_rule_runtime_selection"]["selected_effect"] == "remove_creature"
    assert fields["rule_oracle_normalized_effect_from"] == "bounce"
    assert fields["rule_oracle_normalized_effect_to"] == "remove_creature"
    assert fields["rule_oracle_normalized_target_from"] == "opponent_creature"
    assert fields["rule_oracle_normalized_target_to"] == "creature"


def test_forensic_accepts_explicit_oracle_effect_normalization():
    events = [
        {
            "event": "spell_cast",
            "card": "Into the Flood Maw",
            "effect": "remove_creature",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:flood-maw-runtime",
            "rule_oracle_normalized_effect_from": "bounce",
            "rule_oracle_normalized_effect_to": "remove_creature",
            "turn": 7,
        }
    ]
    rules = {
        "into the flood maw": {
            "effect_json": {"effect": "bounce"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:flood-maw-runtime",
        }
    }

    findings, summary = audit.audit_rule_provenance(events, rules)

    assert findings == []
    assert summary["by_effect"]["remove_creature"] == 1


def test_forensic_accepts_compact_runtime_effect_normalizations():
    events = [
        {
            "event": "land_played",
            "card": "Polluted Delta",
            "effect": "land",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:fetchland",
            "turn": 1,
        },
        {
            "event": "spell_resolved",
            "card": "Eldrazi Confluence",
            "effect": "remove_permanent",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:eldrazi-confluence",
            "turn": 4,
        },
        {
            "event": "spell_resolved",
            "card": "Deadly Rollick",
            "effect": "remove_creature",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:deadly-rollick",
            "turn": 5,
        },
    ]
    rules = {
        "polluted delta": {
            "effect_json": {"effect": "ramp_permanent"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:fetchland",
        },
        "eldrazi confluence": {
            "effect_json": {"effect": "modal_spell"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:eldrazi-confluence",
        },
        "deadly rollick": {
            "effect_json": {"effect": "removal_exile"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:deadly-rollick",
        },
    }

    findings, summary = audit.audit_rule_provenance(events, rules)

    assert findings == []
    assert summary["by_effect"]["land"] == 1
    assert summary["by_effect"]["remove_permanent"] == 1
    assert summary["by_effect"]["remove_creature"] == 1


def test_forensic_reconciles_front_face_event_by_logical_rule_key():
    events = [
        {
            "event": "spell_cast",
            "card": "Bridgeworks Battle",
            "effect": "draw_cards",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:bridgeworks-draw",
            "turn": 14,
        }
    ]
    rules = {
        "bridgeworks battle // tanglespan bridgeworks": {
            "effect_json": {"effect": "draw_cards"},
            "source": "curated",
            "review_status": "verified",
            "logical_rule_key": "battle_rule_v1:bridgeworks-draw",
        }
    }

    findings, summary = audit.audit_rule_provenance(events, rules)

    assert findings == []
    assert summary["card_id_missing"] == 1
    assert summary["card_id_missing_accepted"] == 1
    assert summary["card_id_missing_unaccepted"] == 0
    assert summary["semantic_hash_missing"] == 1
    assert summary["semantic_hash_missing_accepted"] == 1
    assert summary["semantic_hash_missing_unaccepted"] == 0


def test_forensic_accepts_brainstone_first_draw_miracle_candidate():
    events = [
        {
            "event": "miracle_cast",
            "card": "Approach of the Second Sun",
            "effect": "approach",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:approach-test",
            "lorehold_on_board": True,
            "cards_drawn_this_turn": 3,
            "source": "brainstone_first_draw",
            "first_draw_miracle_candidate": True,
            "turn": 8,
        }
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["by_effect"]["approach"] == 1


def test_forensic_blocks_non_first_draw_miracle_without_brainstone_marker():
    events = [
        {
            "event": "miracle_cast",
            "card": "Faithless Looting",
            "effect": "draw_cards",
            "rule_source": "curated",
            "rule_review_status": "verified",
            "rule_logical_key": "battle_rule_v1:looting-test",
            "lorehold_on_board": True,
            "cards_drawn_this_turn": 3,
            "source": "lorehold_opponent_upkeep_rummage",
            "turn": 8,
        }
    ]

    findings, _summary = audit.audit_rule_provenance(events, {})

    assert any(
        finding.get("severity") == "critical"
        and "first real draw" in finding.get("finding", "")
        for finding in findings
    )


def test_forensic_keeps_unaccepted_lineage_missing_visible():
    events = [
        {
            "event": "spell_cast",
            "card": "Ambiguous Spell",
            "effect": "draw_cards",
            "rule_source": "missing",
            "rule_review_status": "missing",
            "turn": 3,
        }
    ]

    findings, summary = audit.audit_rule_provenance(events, {})

    assert findings == []
    assert summary["rule_logical_key_missing_unaccepted"] == 1
    assert summary["card_id_missing_unaccepted"] == 1
    assert summary["semantic_hash_missing_unaccepted"] == 1
    assert summary["lineage_unaccepted_missing_samples"] == [
        {
            "event": "spell_cast",
            "card": "Ambiguous Spell",
            "effect": "draw_cards",
            "source": "missing",
            "missing_field": "rule_logical_key",
        },
        {
            "event": "spell_cast",
            "card": "Ambiguous Spell",
            "effect": "draw_cards",
            "source": "missing",
            "missing_field": "card_id",
        },
        {
            "event": "spell_cast",
            "card": "Ambiguous Spell",
            "effect": "draw_cards",
            "source": "missing",
            "missing_field": "semantic_hash",
        },
    ]


if __name__ == "__main__":
    tests = [
        test_supported_effects_cover_live_engine_handlers,
        test_rise_of_the_eldrazi_uses_composite_oracle_runtime,
        test_manual_runtime_waiver_cards_do_not_use_functional_tags,
        test_promoted_infernal_plunge_uses_curated_pg_rule_not_functional_tags,
        test_sacrifice_waiver_uses_sacrificed_creature_mana_value,
        test_brain_freeze_runtime_resolves_storm_mill_event,
        test_forensic_accepts_manual_runtime_waiver_over_stale_registry_rule,
        test_aura_of_silence_promoted_rule_has_identity_for_forensic,
        test_forensic_accepts_type_line_creature_fact_without_rule_identity,
        test_forensic_accepts_curated_land_played_runtime_rule_without_pg_card_identity,
        test_forensic_accepts_composite_runtime_over_primary_registry_effect,
        test_oracle_normalized_creature_bounce_marks_effect_override,
        test_forensic_accepts_explicit_oracle_effect_normalization,
        test_forensic_accepts_compact_runtime_effect_normalizations,
        test_forensic_reconciles_front_face_event_by_logical_rule_key,
        test_forensic_accepts_brainstone_first_draw_miracle_candidate,
        test_forensic_blocks_non_first_draw_miracle_without_brainstone_marker,
        test_forensic_keeps_unaccepted_lineage_missing_visible,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
