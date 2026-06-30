#!/usr/bin/env python3
"""Batch-safety tests for Lorehold Agent 3 XMage-derived scopes."""

from __future__ import annotations

import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import xmage_semantic_family_classifier as classifier  # noqa: E402
import xmage_to_manaloom_effect_hints as hints  # noqa: E402


def classifier_card(card_name, class_name, entry, primary):
    return {
        "card_name": card_name,
        "ready_for_structured_pull": True,
        "status": "xmage_source_valid_mapper_required",
        "xmage": {
            "class_name": class_name,
            "types": entry.get("constructor_metadata", {}).get("card_types", []),
            "ability_classes": entry.get("ability_classes", []),
            "effect_classes": entry.get("effect_classes", []),
            "cost_classes": entry.get("cost_classes", []),
            "target_classes": entry.get("target_classes", []),
            "condition_classes": entry.get("condition_classes", []),
            "primary_effect": primary,
        },
    }


def test_agent3_xmage_scopes_are_family_routed_and_batch_safe():
    cases = [
        (
            "Ancient Gold Dragon",
            "AncientGoldDragon",
            {
                "effect_classes": ["AncientGoldDragonEffect", "OneShotEffect"],
                "ability_classes": ["DealsCombatDamageToAPlayerTriggeredAbility", "FlyingAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "token_maker",
            "source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1",
        ),
        (
            "Chandra's Ignition",
            "ChandrasIgnition",
            {
                "effect_classes": ["ChandrasIgnitionEffect", "OneShotEffect"],
                "ability_classes": [],
                "target_classes": ["TargetControlledCreaturePermanent"],
                "constructor_metadata": {"card_types": ["SORCERY"]},
            },
            "board_wipe_choice",
            "controlled_creature_power_damage_each_other_creature_each_opponent_v1",
        ),
        (
            "Charmbreaker Devils",
            "CharmbreakerDevils",
            {
                "effect_classes": ["BoostSourceEffect", "ReturnFromGraveyardAtRandomEffect"],
                "ability_classes": [
                    "BeginningOfUpkeepTriggeredAbility",
                    "SpellCastControllerTriggeredAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            "recursion",
            "upkeep_return_random_instant_sorcery_graveyard_to_hand_spell_cast_plus_4_0_v1",
        ),
        (
            "Naktamun Lorespinner // Wheel of Fortune",
            "NaktamunLorespinner",
            {
                "effect_classes": [
                    "BecomePreparedSourceEffect",
                    "DiscardHandAllEffect",
                    "DrawCardAllEffect",
                ],
                "ability_classes": ["BeginningOfUpkeepTriggeredAbility"],
                "condition_classes": ["NaktamunLorespinnerCondition"],
                "constructor_metadata": {"card_types": ["CREATURE", "SORCERY"]},
            },
            "draw_engine",
            "upkeep_prepare_if_player_hand_size_lte_one_prepared_wheel_discard_draw_seven_v1",
        ),
    ]

    for card_name, class_name, entry, expected_family, expected_scope in cases:
        result = hints.build_effect_hints({"xmage_class_name": class_name, **entry})
        primary = result["primary_candidate"]["effect_json"]
        card = classifier_card(card_name, class_name, entry, primary)
        assert primary["battle_model_scope"] == expected_scope
        assert classifier.family_for_effect_json(primary) == expected_family
        assert classifier.exact_scope_batch_safe(card)
