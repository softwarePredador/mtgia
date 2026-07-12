#!/usr/bin/env python3
"""Conservative XMage-to-ManaLoom battle-rule hint mapping.

This module intentionally produces review candidates only. It does not promote
rules, trust an external implementation, or decide PostgreSQL writes.
"""

from __future__ import annotations

import re
from typing import Any


def _as_set(value: Any) -> set[str]:
    if isinstance(value, list):
        return {str(item) for item in value if item}
    if isinstance(value, set):
        return {str(item) for item in value if item}
    return set()


def _oracle_has(oracle_text: str, *needles: str) -> bool:
    text = str(oracle_text or "").lower()
    return all(needle.lower() in text for needle in needles)


def _first_int(pattern: str, text: str) -> int | None:
    match = re.search(pattern, str(text or ""))
    return int(match.group(1)) if match else None


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def _normalized_rules_text(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").replace('"', " ").replace("+", " ").lower()).strip()


def _ability_kind(ability_classes: set[str]) -> str:
    if any("Replacement" in cls for cls in ability_classes):
        return "replacement"
    if any("TriggeredAbility" in cls for cls in ability_classes):
        return "triggered"
    if any("ActivatedAbility" in cls or cls == "SimpleActivatedAbility" for cls in ability_classes):
        return "activated"
    if any("StaticAbility" in cls or cls == "SimpleStaticAbility" for cls in ability_classes):
        return "static"
    return "one_shot"


def _target_constraints(target_classes: set[str], filter_classes: set[str]) -> dict[str, Any]:
    constraints: dict[str, Any] = {}
    joined = " ".join(sorted(target_classes | filter_classes)).lower()
    if "opponent" in joined:
        constraints["controller_scope"] = "opponent"
    elif "controlled" in joined or "controller" in joined:
        constraints["controller_scope"] = "source_controller"
    if "creature" in joined:
        constraints["card_types"] = ["creature"]
    elif "artifact" in joined:
        constraints["card_types"] = ["artifact"]
    elif "enchantment" in joined:
        constraints["card_types"] = ["enchantment"]
    elif "permanent" in joined:
        constraints["card_types"] = ["permanent"]
    if "graveyard" in joined:
        constraints["zone"] = "graveyard"
    if "spell" in joined or "stack" in joined:
        constraints["zone"] = "stack"
    if "attackingorblocking" in joined or "attacking or blocking" in joined:
        constraints["combat_state"] = "attacking_or_blocking"
    if "anytarget" in joined:
        constraints["scope"] = "any_target"
    return constraints


def _artifact_or_enchantment_source_text(rules_text: str) -> bool:
    text = _normalized_rules_text(rules_text)
    return (
        "artifact or enchantment" in text
        or "artifact and enchantment" in text
        or "filter_permanent_artifact_or_enchantment" in text
    )


def static_cost_reduction_fields_from_oracle(oracle_text: str) -> dict[str, Any]:
    text = _normalized_rules_text(oracle_text)
    fields: dict[str, Any] = {
        "cost_reduction_generic": 1,
        "cost_reduction_applies_to": "spells_you_cast",
        "applies_to_controller": "source_controller",
    }
    graveyard_instant_sorcery_count = (
        "for each instant and sorcery card in your graveyard" in text
        or "for each instant or sorcery card in your graveyard" in text
    )
    if "activated abilities of creatures you control" in text:
        fields["cost_reduction_applies_to"] = "activated_abilities_of_creatures_you_control"
    elif "activated abilities of artifacts you control" in text:
        fields["cost_reduction_applies_to"] = "activated_abilities_of_artifacts_you_control"
    elif "activated abilities you activate" in text:
        fields["cost_reduction_applies_to"] = "activated_abilities_you_activate"
    elif "this spell costs" in text:
        fields["cost_reduction_applies_to"] = "this_spell"
    if "where x is" in text and "power" in text:
        fields.pop("cost_reduction_generic", None)
        fields["cost_reduction_amount_source"] = "source_power"
    if (
        "for each artifact or creature you've sacrificed this turn" in text
        or "for each other artifact or creature you've sacrificed this turn" in text
    ):
        fields.pop("cost_reduction_generic", None)
        fields["cost_reduction_amount_source"] = "sacrificed_artifact_or_creature_count_this_turn"
    if "for each permanent sacrificed this way" in text:
        fields["cost_reduction_counts_additional_sacrifices_paid_while_casting"] = True
    if graveyard_instant_sorcery_count:
        fields["graveyard_count_card_types"] = ["instant", "sorcery"]
        fields["cost_reduction_amount_source"] = "instant_sorcery_cards_in_your_graveyard_count"
    elif "instant and sorcery" in text or "instant or sorcery" in text:
        fields["applies_to_card_types"] = ["instant", "sorcery"]
        fields["cost_reduction_applies_to"] = "instant_sorcery_spells_you_cast"
    mana_value_match = re.search(r"mana\s+value\s+(\d+)\s+or\s+greater", text)
    if mana_value_match:
        fields["minimum_mana_value"] = int(mana_value_match.group(1))
    if "can't reduce the mana in that cost to less than one mana" in text:
        fields["cost_reduction_minimum_total_mana"] = 1
    if "if you control a wizard" in text:
        fields["cost_reduction_condition"] = "control_wizard"
    color_map = {
        "white": "W",
        "blue": "U",
        "black": "B",
        "red": "R",
        "green": "G",
    }
    for color_name, symbol in color_map.items():
        if f"{color_name} spells you cast" in text:
            fields["applies_to_spell_colors"] = [symbol]
            break
    amount_match = re.search(r"cost\s+\{(\d+)\}\s+less", text)
    if amount_match:
        fields["cost_reduction_generic"] = int(amount_match.group(1))
    return fields


def static_cost_reduction_scope_from_fields(fields: dict[str, Any]) -> str:
    applies_to = str(fields.get("cost_reduction_applies_to") or "")
    if applies_to.startswith("activated_abilities_"):
        return "static_activated_ability_cost_reduction_variant_v1"
    if applies_to == "this_spell":
        if (
            fields.get("cost_reduction_amount_source") == "sacrificed_artifact_or_creature_count_this_turn"
            or fields.get("cost_reduction_counts_additional_sacrifices_paid_while_casting")
        ):
            return "static_variable_self_spell_cost_reduction_variant_v1"
        if fields.get("cost_reduction_condition"):
            return "static_conditional_self_spell_cost_reduction_variant_v1"
        return "static_self_spell_cost_reduction_variant_v1"
    if (
        fields.get("cost_reduction_amount_source") == "source_power"
        and fields.get("applies_to_card_types") == ["instant", "sorcery"]
        and fields.get("minimum_mana_value") == 4
    ):
        return "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1"
    return "static_cost_reduction_for_matching_spells_v1"


def oracle_supports_cost_reduction_mapping(oracle_text: str) -> bool:
    text = _normalized_rules_text(oracle_text)
    if "cost" not in text:
        return False
    if "more to cast" in text or "cost more to cast" in text:
        return False
    return "less to cast" in text or "less to activate" in text


def _scenario_names(effect: str, scope: str = "") -> list[str]:
    if scope == "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1":
        return [
            "cast mana-value-4 instant or sorcery with generic cost reduced by source power",
            "cast mana-value-3 or non-instant/sorcery spell without reduction",
        ]
    if scope == "colorless_land_tap_or_tap_sacrifice_two_colorless_mode_v1":
        return [
            "tap land for one colorless mana without sacrificing it",
            "tap and sacrifice land for two colorless mana when the extra mana unlocks a cast",
        ]
    mapping = {
        "static_cost_reduction": [
            "cast matching spell with one less generic cost",
            "cast non-matching spell without reduction",
        ],
        "vow_counter_each_player_sacrifice_rest": [
            "each player chooses exactly one controlled creature",
            "chosen creatures receive vow counters and other creatures are sacrificed",
            "vow-counter creatures cannot attack the protected player",
        ],
        "gift_destroy_all_creatures_return_own_destroyed_creature": [
            "destroy all creatures without gift and return none",
            "gift promised returns one own creature put into graveyard this way",
        ],
        "token_maker": [
            "create expected token count and stats",
            "apply duration-limited protection or indestructible effect",
        ],
        "selective_nonland_sacrifice": [
            "controller chooses one permanent per requested type and player",
            "all other nonland permanents are sacrificed",
        ],
        "mana_rock_with_sacrifice_draw": [
            "tap for colorless mana",
            "pay, tap, sacrifice to draw one card",
        ],
        "extra_turn": [
            "schedule one extra turn for the controller",
            "controller loses the game after taking that extra turn when the rule says so",
        ],
        "dig_to_hand": [
            "look at the requested number of top library cards and put the best subset into hand",
            "move the remaining looked-at cards to the expected graveyard destination",
        ],
        "pile_selection_draw": [
            "reveal the requested top cards and split them into two piles according to the card role",
            "choose the resulting hand pile and move the remaining cards to the graveyard",
        ],
    }
    return mapping.get(effect, [f"focused behavior scenario for {effect}"])


def _candidate(
    *,
    effect: str,
    scope: str,
    reason: str,
    ability_kind: str,
    requires_runtime_executor: bool,
    target_constraints: dict[str, Any] | None = None,
    extra_effect_fields: dict[str, Any] | None = None,
    matched_signals: list[str] | None = None,
) -> dict[str, Any]:
    effect_json = {"effect": effect, "battle_model_scope": scope, "ability_kind": ability_kind}
    if target_constraints:
        effect_json["target_constraints"] = target_constraints
    if extra_effect_fields:
        effect_json.update(extra_effect_fields)
    return {
        "status": "review_candidate",
        "effect_json": effect_json,
        "suggested_battle_model_scope": scope,
        "confidence_reason": reason,
        "requires_runtime_executor": requires_runtime_executor,
        "requires_manual_review": True,
        "matched_signals": matched_signals or [],
        "suggested_tests": _scenario_names(effect, scope),
    }


def _combined_rules_text(index_entry: dict[str, Any], oracle_text: str) -> str:
    parts = [
        str(oracle_text or ""),
        str(index_entry.get("oracle_text") or ""),
        str(index_entry.get("raw_excerpt") or ""),
    ]
    metadata = index_entry.get("constructor_metadata")
    if isinstance(metadata, dict):
        parts.append(str(metadata.get("super_call") or ""))
    return "\n".join(part for part in parts if part)


def _inner_extends(index_entry: dict[str, Any]) -> set[str]:
    classes = index_entry.get("custom_inner_classes")
    if not isinstance(classes, list):
        return set()
    return {
        str(item.get("extends"))
        for item in classes
        if isinstance(item, dict) and item.get("extends")
    }


def _constructor_card_types(index_entry: dict[str, Any]) -> set[str]:
    metadata = index_entry.get("constructor_metadata")
    if not isinstance(metadata, dict):
        return set()
    return {
        str(value or "").upper()
        for value in (metadata.get("card_types") or [])
        if value
    }


def _constructor_power_toughness_fields(index_entry: dict[str, Any], rules_text: str) -> dict[str, Any]:
    fields: dict[str, Any] = {}
    power = _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text)
    toughness = _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text)
    if power is not None:
        fields["power"] = power
    if toughness is not None:
        fields["toughness"] = toughness
    return fields


def _build_controlled_creature_enters_damage_each_opponent_fields(
    *,
    index_entry: dict[str, Any],
    rules_text: str,
    effect_classes: set[str],
    ability_classes: set[str],
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if "DamagePlayersEffect" not in effect_classes:
        return None
    if "EntersBattlefieldControlledTriggeredAbility" not in ability_classes:
        return None
    if "targetcontroller.opponent" not in _normalized_rules_text(rules_text) and "each opponent" not in _normalized_rules_text(rules_text):
        return None
    if not card_types.intersection({"CREATURE", "ENCHANTMENT", "ARTIFACT"}):
        return None

    amount = _first_int(r"damageplayerseffect\((\d+)", _normalized_rules_text(rules_text))
    if amount is None:
        amount = _first_int(r"staticvalue\.get\((\d+)\)", _normalized_rules_text(rules_text))
    if amount is None:
        amount = _first_int(r"deals\s+(\d+)\s+damage\s+to\s+each\s+opponent", _normalized_rules_text(rules_text))
    if amount is None:
        return None

    normalized = _normalized_rules_text(rules_text)
    another_only = (
        "filter_another_creature" in normalized
        or "anotherpredicate.instance" in normalized
        or 'filterpermanent("another creature")' in normalized
        or "filterpermanent( another creature )" in normalized
        or "another creature you control enters" in normalized
    )
    effect = "creature" if "CREATURE" in card_types else "passive"
    fields: dict[str, Any] = {
        "trigger": "creature_you_control_enters",
        "trigger_effect": "damage_each_opponent",
        "trigger_damage_each_opponent": amount,
        "damage": amount,
        "target_controller": "opponents",
        "trigger_creature_you_control_enters": True,
        "trigger_another_creature_you_control_enters": bool(another_only),
        "is_creature_permanent": "CREATURE" in card_types,
    }
    if effect == "creature":
        fields.update(_constructor_power_toughness_fields(index_entry, rules_text))
    return {
        "effect": effect,
        "scope": "controlled_creature_enters_damage_each_opponent_v1",
        "fields": fields,
        "reason": (
            "XMage uses EntersBattlefieldControlledTriggeredAbility with DamagePlayersEffect "
            "targeting opponents; ManaLoom can model this as a battlefield trigger when a "
            "creature controlled by the source controller enters."
        ),
        "signals": [
            "EntersBattlefieldControlledTriggeredAbility",
            "DamagePlayersEffect",
            "TargetController.OPPONENT",
        ],
    }


def _build_spell_cast_damage_each_opponent_fields(
    *,
    index_entry: dict[str, Any],
    rules_text: str,
    effect_classes: set[str],
    ability_classes: set[str],
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if "DamagePlayersEffect" not in effect_classes:
        return None
    if "SpellCastControllerTriggeredAbility" not in ability_classes:
        return None

    normalized = _normalized_rules_text(rules_text)
    if "targetcontroller.opponent" not in normalized and "each opponent" not in normalized:
        return None
    if not card_types.intersection({"CREATURE", "ENCHANTMENT", "ARTIFACT"}):
        return None

    amount = _first_int(r"damageplayerseffect\((\d+)", normalized)
    if amount is None:
        amount = _first_int(r"deals\s+(\d+)\s+damage\s+to\s+each\s+opponent", normalized)
    if amount is None:
        return None

    trigger = "spell_cast"
    scope = "spell_cast_damage_each_opponent_v1"
    trigger_signal = "SpellCastControllerTriggeredAbility"
    if (
        "filter_spell_a_non_creature" in normalized
        or _oracle_has(rules_text, "whenever you cast a noncreature spell")
    ):
        trigger = "noncreature_spell_cast"
        scope = "noncreature_spell_cast_damage_each_opponent_v1"
        trigger_signal = "FILTER_SPELL_A_NON_CREATURE"
    elif (
        "filter_spell_an_instant_or_sorcery" in normalized
        or _oracle_has(rules_text, "whenever you cast an instant or sorcery spell")
        or _oracle_has(rules_text, "whenever you cast an instant or sorcery")
    ):
        trigger = "instant_sorcery_cast"
        scope = "instant_sorcery_cast_damage_each_opponent_v1"
        trigger_signal = "FILTER_SPELL_AN_INSTANT_OR_SORCERY"

    effect = "creature" if "CREATURE" in card_types else "passive"
    fields: dict[str, Any] = {
        "trigger": trigger,
        "trigger_effect": "damage_each_opponent",
        "trigger_damage_each_opponent": amount,
        "damage": amount,
        "target_controller": "opponents",
    }
    if effect == "creature":
        fields.update(_constructor_power_toughness_fields(index_entry, rules_text))
    return {
        "effect": effect,
        "scope": scope,
        "fields": fields,
        "reason": (
            "XMage uses SpellCastControllerTriggeredAbility with DamagePlayersEffect "
            "targeting opponents; ManaLoom can model this as a battlefield trigger "
            "that damages each live opponent when the matching spell class is cast."
        ),
        "signals": [
            "SpellCastControllerTriggeredAbility",
            "DamagePlayersEffect",
            "TargetController.OPPONENT",
            trigger_signal,
        ],
    }


def _build_single_target_stack_redirect_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    target_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if "ChooseNewTargetsTargetEffect" not in effect_classes:
        return None
    if "TargetStackObject" not in target_classes:
        return None
    if "INSTANT" not in card_types:
        return None

    normalized = _normalized_rules_text(rules_text)
    if "spell or ability with a single target" not in normalized and "numberoftargetspredicate(1)" not in normalized:
        return None

    if "CopyTargetStackObjectEffect" in effect_classes:
        fields: dict[str, Any] = {
            "instant": True,
            "target": "stack_object",
            "copy_stack_object_types": [
                "instant_spell",
                "sorcery_spell",
                "activated_ability",
                "triggered_ability",
            ],
            "modes": ["copy_instant_or_sorcery_spell", "change_single_target"],
            "may_choose_new_targets": True,
            "choose_new_targets_status": "may_choose_new_targets",
            "change_target_mode_status": "runtime_executor_v1",
            "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1",
            "oracle_runtime_scope": "copy_stack_object_or_change_single_target_spree_selected_mode_runtime_v1",
        }
        if "spree" in normalized or "spreeability" in normalized:
            fields["spree"] = True
            fields["spree_additional_cost_status"] = "runtime_executor_v1"
            fields["spree_selected_mode_cost_status"] = "runtime_executor_v1"
            fields["spree_mode_costs"] = {
                "copy_instant_or_sorcery_spell": "{1}",
                "change_single_target": "{1}",
            }
        if "activated ability" in normalized or "triggered ability" in normalized:
            fields["copy_activated_triggered_ability_status"] = "runtime_executor_v1"
        return {
            "effect": "copy_spell",
            "scope": "spree_copy_stack_object_change_target_selected_mode_runtime_v1",
            "fields": fields,
            "reason": (
                "XMage structure matches a modal spree spell that can copy a stack object or change "
                "the target of a single-target spell or ability; ManaLoom executes each selected "
                "response mode with its additional spree cost."
            ),
            "signals": [
                "CopyTargetStackObjectEffect",
                "ChooseNewTargetsTargetEffect",
                "TargetStackObject",
                "SpreeAbility",
                "NumberOfTargetsPredicate(1)",
            ],
        }

    if "DestroyTargetEffect" in effect_classes and (
        "artifact" in normalized or "filterartifactpermanent" in normalized
    ):
        fields = {
            "instant": True,
            "target": "artifact",
            "modes": ["destroy_artifact", "redirect_target", "cant_block"],
            "destroy_artifact_mode": True,
            "redirect_target_mode_status": "runtime_executor_v1",
            "cant_block_mode_status": "runtime_executor_v1",
            "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1",
            "oracle_runtime_scope": "destroy_target_artifact_redirect_target_cant_block_runtime_v1",
        }
        return {
            "effect": "remove_permanent",
            "scope": "modal_destroy_artifact_redirect_target_cant_block_runtime_v1",
            "fields": fields,
            "reason": (
                "XMage structure matches a modal instant with destroy-artifact and single-target "
                "redirect modes; ManaLoom executes destroy-artifact, redirect-target, and target "
                "creature can't-block modes."
            ),
            "signals": [
                "DestroyTargetEffect",
                "ChooseNewTargetsTargetEffect",
                "TargetStackObject",
                "NumberOfTargetsPredicate(1)",
            ],
        }

    if "SpellCostReductionSourceEffect" in effect_classes and (
        "ferociouscondition.instance" in normalized
        or _oracle_has(rules_text, "if you control a creature with power 4 or greater")
    ):
        return {
            "effect": "redirect_removal",
            "scope": "single_target_spell_or_ability_redirect_costs_three_less_if_control_power_four_v1",
            "fields": {
                "instant": True,
                "target": "single_target_spell_or_ability",
                "target_scope": "target_spell_or_ability",
                "chooses_new_targets": True,
                "oracle_runtime_scope": "redirect_single_target_stack_object_compact_v1",
                "cost_reduction_applies_to": "this_spell",
                "cost_reduction_generic": 3,
                "cost_reduction_condition": "control_creature_power_4_or_greater",
            },
            "reason": (
                "XMage structure matches Bolt Bend changing the target of a single-target spell or ability, "
                "with a ferocious self-cost reduction when you control a creature with power 4 or greater."
            ),
            "signals": [
                "ChooseNewTargetsTargetEffect",
                "TargetStackObject",
                "NumberOfTargetsPredicate(1)",
                "SpellCostReductionSourceEffect",
                "FerociousCondition",
            ],
        }

    return None


def _build_copy_permanent_etb_fields(
    *,
    index_entry: dict[str, Any],
    rules_text: str,
    effect_classes: set[str],
    ability_classes: set[str],
) -> dict[str, Any] | None:
    if "CopyPermanentEffect" not in effect_classes or "EntersBattlefieldAbility" not in ability_classes:
        return None
    text = _normalized_rules_text(rules_text)
    if "until end of turn" in text:
        return None
    target_types: list[str] | None = None
    target_controller = "any"
    if "filter_permanent_enchantment" in text or _oracle_has(rules_text, "copy of an enchantment"):
        target_types = ["enchantment"]
    elif "filter_permanent_artifact_or_enchantment" in text or _oracle_has(
        rules_text, "copy of any artifact or enchantment"
    ):
        target_types = ["artifact", "enchantment"]
    elif "filter_permanent_artifact_or_creature" in text or _oracle_has(
        rules_text, "copy of any artifact or creature"
    ):
        target_types = ["artifact", "creature"]
    elif "filternonlandpermanent" in text or _oracle_has(rules_text, "copy of any nonland permanent"):
        target_types = ["nonland_permanent"]
    elif (
        "filter_opponents_permanent_a_creature" in text
        or _oracle_has(rules_text, "copy of a creature an opponent controls")
    ):
        target_types = ["creature"]
        target_controller = "opponent"
    elif "filter_permanent_creature" in text or _oracle_has(rules_text, "copy of any creature on the battlefield"):
        target_types = ["creature"]
    elif "filterartifactpermanent" in text or _oracle_has(rules_text, "copy of any artifact"):
        target_types = ["artifact"]
    if not target_types:
        return None
    extra_types: list[str] = []
    if "artifact in addition to its other types" in text:
        extra_types.append("artifact")
    if "enchantment in addition to its other types" in text:
        extra_types.append("enchantment")
    extra_subtypes: list[str] = []
    if "bird in addition to its other types" in text:
        extra_subtypes.append("Bird")
    if "illusion in addition to its other types" in text:
        extra_subtypes.append("Illusion")
    extra_keywords: list[str] = []
    if "has flying" in text:
        extra_keywords.append("flying")
    if "has haste" in text:
        extra_keywords.append("haste")
    overwrite_types: list[str] = []
    overwrite_subtypes: list[str] = []
    crew_value: int | None = None
    if "vehicle artifact with crew 3" in text and "loses all other card types" in text:
        overwrite_types = ["artifact"]
        overwrite_subtypes = ["Vehicle"]
        crew_value = 3
    modifier_fields: dict[str, Any] = {}
    if extra_subtypes:
        modifier_fields["copy_additional_subtypes"] = extra_subtypes
    if extra_keywords:
        modifier_fields["copy_granted_keywords"] = extra_keywords
    if overwrite_types:
        modifier_fields["copy_overwrite_types"] = overwrite_types
    if overwrite_subtypes:
        modifier_fields["copy_overwrite_subtypes"] = overwrite_subtypes
    if crew_value is not None:
        modifier_fields["copy_vehicle_crew_value"] = crew_value
    if "mana value less than or equal to the amount of mana spent to cast" in text:
        modifier_fields["copy_target_mana_value_lte_source_mana_value"] = True
    if "vanishing 3 if that creature doesn't have vanishing" in text:
        modifier_fields["copy_grant_vanishing_if_missing"] = 3
    if "becomes the target of a spell or ability, sacrifice it" in text:
        modifier_fields["copy_sacrifice_when_targeted"] = True
    if modifier_fields:
        if extra_types:
            modifier_fields["copy_additional_types"] = extra_types
        return {
            "effect": "copy_permanent_etb",
            "scope": "etb_copy_target_creature_with_copy_applier_modifiers_v1",
            "reason": (
                "XMage structure matches a permanent entering as a copy of a creature, "
                "with explicit CopyApplier modifier text preserved in structured fields."
            ),
            "fields": {
                "copy_target_types": target_types,
                "target_controller": target_controller,
                **modifier_fields,
            },
            "signals": ["CopyPermanentEffect", "EntersBattlefieldAbility", "CopyApplier"],
        }
    return {
        "effect": "copy_permanent_etb",
        "scope": "etb_copy_target_permanent_with_optional_extra_type_v1",
        "reason": (
            "XMage structure matches a permanent entering as a copy of another permanent, "
            "with optional extra card types from the source text."
        ),
        "fields": {
            "copy_target_types": target_types,
            "target_controller": target_controller,
            **({"copy_additional_types": extra_types} if extra_types else {}),
        },
        "signals": ["CopyPermanentEffect", "EntersBattlefieldAbility"],
    }


def _build_modal_mana_rock_fields(
    *,
    index_entry: dict[str, Any],
    rules_text: str,
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if "ARTIFACT" not in card_types:
        return None
    if "DrawCardSourceControllerEffect" not in effect_classes:
        return None
    if not any("Mana" in cls for cls in ability_classes):
        return None
    if "TapSourceCost" not in cost_classes or "SacrificeSourceCost" not in cost_classes:
        return None

    mana_produced = _first_int(r"ColorlessMana\((\d+)\)", rules_text)
    if mana_produced is None and "ColorlessManaAbility" in ability_classes:
        mana_produced = 1
    if mana_produced is None:
        return None

    activation_cost_generic = _first_int(r"GenericManaCost\((\d+)\)", rules_text)
    draw_on_self_sacrifice = _first_int(r"DrawCardSourceControllerEffect\((\d+)\)", rules_text) or 1
    exile_target_player_graveyards = "ExileGraveyardAllTargetPlayerEffect" in effect_classes

    if exile_target_player_graveyards and mana_produced == 2 and draw_on_self_sacrifice == 1:
        scope = "two_mana_rock_graveyard_hate_cantrip_v1"
    elif mana_produced == 2 and draw_on_self_sacrifice == 2:
        scope = "two_mana_rock_self_sacrifice_draw_two_v1"
    elif mana_produced == 1 and draw_on_self_sacrifice == 1:
        scope = "mana_rock_self_sacrifice_draw_v1"
    else:
        scope = "artifact_colorless_mana_self_sacrifice_draw_variant_v1"

    fields: dict[str, Any] = {
        "mana_produced": mana_produced,
        "produces": "C",
        "activation_requires_tap": True,
        "activated_self_sacrifice_draw": True,
    }
    if activation_cost_generic is not None:
        fields["activation_cost_generic"] = activation_cost_generic
    if draw_on_self_sacrifice > 1:
        fields["draw_on_self_sacrifice"] = draw_on_self_sacrifice
    if exile_target_player_graveyards:
        fields["activated_exile_target_player_graveyards"] = True
    return {
        "scope": scope,
        "fields": fields,
    }


def _build_veil_of_summer_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"INSTANT"}:
        return None
    required = {"DrawCardSourceControllerEffect", "CantBeCounteredControlledEffect"}
    if not required.issubset(effect_classes):
        return None
    if not (
        _oracle_has(
            rules_text,
            "draw a card if an opponent has cast a blue or black spell this turn",
            "spells you control can't be countered this turn",
            "gain hexproof from blue and from black until end of turn",
        )
        or (
            "veilofsummerwatcher" in _normalized_rules_text(rules_text)
            and {
                "GainAbilityControlledEffect",
                "GainAbilityControllerEffect",
            }.issubset(effect_classes)
            and {
                "HexproofFromBlueAbility",
                "HexproofFromBlackAbility",
            }.issubset(ability_classes)
        )
    ):
        return None
    return {
        "effect": "draw_cards",
        "scope": "veil_of_summer_draw_and_protection_waiver_v1",
        "fields": {
            "count": 1,
            "instant": True,
            "conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn": True,
            "spells_you_control_cant_be_countered_this_turn": True,
            "controller_and_permanents_hexproof_from_colors_until_eot": ["U", "B"],
        },
        "reason": (
            "XMage structure matches Veil of Summer conditional draw plus anti-counter and "
            "controller/permanents hexproof-from-blue-and-black protection."
        ),
        "signals": [
            "DrawCardSourceControllerEffect",
            "CantBeCounteredControlledEffect",
            "hexproof_from_blue_black",
        ],
    }


def _build_counter_variant_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"INSTANT"}:
        return None

    normalized = _normalized_rules_text(rules_text)

    if (
        "CounterUnlessPaysEffect" in effect_classes
        and "StormAbility" in ability_classes
        and "counterunlesspayseffect(new manacostsimpl<>" in normalized
        and "{1}" in normalized
    ):
        return {
            "effect": "counter_spell",
            "scope": "storm_counter_instant_or_sorcery_unless_controller_pays_one_v1",
            "fields": {
                "target": "instant_or_sorcery_spell",
                "instant": True,
                "unless_controller_pays_generic": 1,
                "storm": True,
            },
            "reason": (
                "XMage structure matches a storm soft counter against an instant or sorcery unless its controller pays 1."
            ),
            "signals": [
                "CounterUnlessPaysEffect",
                "ManaCostsImpl({1})",
                "StormAbility",
                "FILTER_SPELL_INSTANT_OR_SORCERY",
            ],
        }

    if "CounterUnlessPaysEffect" in effect_classes:
        if "counterunlesspayseffect(new genericmanacost(3))" in normalized:
            if "filter_spell_instant_or_sorcery" in normalized:
                return {
                    "effect": "counter_spell",
                    "scope": "counter_instant_or_sorcery_unless_controller_pays_three_v1",
                    "fields": {
                        "target": "instant_or_sorcery_spell",
                        "instant": True,
                        "unless_controller_pays_generic": 3,
                    },
                    "reason": (
                        "XMage structure matches a soft counter against an instant or sorcery unless its controller pays 3."
                    ),
                    "signals": [
                        "CounterUnlessPaysEffect",
                        "GenericManaCost(3)",
                        "FILTER_SPELL_INSTANT_OR_SORCERY",
                    ],
                }
            return {
                "effect": "counter_spell",
                "scope": "counter_spell_unless_controller_pays_three_v1",
                "fields": {
                    "target": "spell",
                    "instant": True,
                    "unless_controller_pays_generic": 3,
                },
                "reason": (
                    "XMage structure matches a soft counter against any spell unless its controller pays 3."
                ),
                "signals": [
                    "CounterUnlessPaysEffect",
                    "GenericManaCost(3)",
                ],
            }
        if (
            "counterunlesspayseffect(new genericmanacost(2))" in normalized
            and "filter_spell_non_creature" in normalized
        ):
            return {
                "effect": "counter_spell",
                "scope": "counter_noncreature_spell_unless_controller_pays_two_v1",
                "fields": {
                    "target": "noncreature_spell",
                    "instant": True,
                    "unless_controller_pays_generic": 2,
                },
                "reason": (
                    "XMage structure matches a soft counter against a noncreature spell unless its controller pays 2."
                ),
                "signals": [
                    "CounterUnlessPaysEffect",
                    "GenericManaCost(2)",
                    "FILTER_SPELL_NON_CREATURE",
                ],
            }

    if "CounterTargetEffect" not in effect_classes:
        return None

    if "CreateDelayedTriggeredAbilityEffect" in effect_classes and "PactDelayedTriggeredAbility" in ability_classes:
        return {
            "effect": "counter_spell",
            "scope": "pact_of_negation_delayed_upkeep_counter_v1",
            "fields": {
                "target": "spell",
                "instant": True,
                "delayed_upkeep_mana_payment": "{3}{U}{U}",
                "lose_game_if_unpaid": True,
            },
            "reason": (
                "XMage structure matches Pact of Negation counterspell plus delayed upkeep payment-or-lose trigger."
            ),
            "signals": [
                "CounterTargetEffect",
                "CreateDelayedTriggeredAbilityEffect",
                "PactDelayedTriggeredAbility",
            ],
        }

    if "CreateTokenControllerTargetEffect" in effect_classes:
        if "treasuretoken" in normalized and "filter_spell_non_creature" in normalized:
            return {
                "effect": "counter_spell",
                "scope": "counter_noncreature_spell_target_controller_treasure_two_v1",
                "fields": {
                    "target": "noncreature_spell",
                    "instant": True,
                    "target_controller_creates_treasure": 2,
                },
                "reason": (
                    "XMage structure matches An Offer You Can't Refuse countering a noncreature spell and creating two Treasures for its controller."
                ),
                "signals": [
                    "CounterTargetEffect",
                    "CreateTokenControllerTargetEffect",
                    "TreasureToken",
                ],
            }
        if (
            "swansongbirdtoken" in normalized
            and "cardtype.enchantment.getpredicate" in normalized
            and "cardtype.instant.getpredicate" in normalized
            and "cardtype.sorcery.getpredicate" in normalized
        ):
            return {
                "effect": "counter_spell",
                "scope": "counter_enchantment_instant_sorcery_spell_target_controller_bird_v1",
                "fields": {
                    "target": "enchantment_instant_or_sorcery_spell",
                    "instant": True,
                    "target_controller_creates_token": {
                        "name": "Bird",
                        "count": 1,
                        "power": 2,
                        "toughness": 2,
                        "colors": ["U"],
                        "keywords": ["flying"],
                    },
                },
                "reason": (
                    "XMage structure matches Swan Song countering enchantment/instant/sorcery and creating a 2/2 blue Bird with flying for that spell's controller."
                ),
                "signals": [
                    "CounterTargetEffect",
                    "CreateTokenControllerTargetEffect",
                    "SwanSongBirdToken",
                ],
            }

    if "DrawDiscardControllerEffect" in effect_classes and "drawdiscardcontrollereffect(1, 1)" in normalized:
        return {
            "effect": "counter_spell",
            "scope": "counter_spell_draw_then_discard_v1",
            "fields": {
                "target": "spell",
                "instant": True,
                "draw_then_discard": 1,
            },
            "reason": "XMage structure matches Refute countering a spell and then drawing and discarding one card.",
            "signals": [
                "CounterTargetEffect",
                "DrawDiscardControllerEffect",
            ],
        }

    if (
        "SpellCostReductionSourceEffect" in effect_classes
        and "SimpleStaticAbility" in ability_classes
        and ("control a wizard" in normalized or "subtype.wizard.getpredicate" in normalized)
    ):
        return {
            "effect": "counter_spell",
            "scope": "counter_spell_costs_one_less_if_control_wizard_v1",
            "fields": {
                "target": "spell",
                "instant": True,
                "cost_reduction_generic_if_control_wizard": 1,
            },
            "reason": "XMage structure matches Wizard's Retort countering a spell with a cost reduction while you control a Wizard.",
            "signals": [
                "CounterTargetEffect",
                "SpellCostReductionSourceEffect",
                "control_wizard",
            ],
        }

    return None


def _build_mill_spell_fields(
    *,
    xmage_class_name: str,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if "MillCardsTargetEffect" not in effect_classes:
        return None
    normalized = _normalized_rules_text(rules_text)
    mill_count = _first_int(r"MillCardsTargetEffect\((\d+)\)", rules_text) or 0

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"MillCardsTargetEffect"}
        and ability_classes == {"StormAbility"}
        and not cost_classes
        and mill_count > 0
    ):
        return {
            "effect": "brain_freeze" if xmage_class_name == "BrainFreeze" else "mill_cards",
            "scope": "storm_target_player_mill_fixed_count_v1",
            "fields": {
                "instant": True,
                "target": "player",
                "mill_count": mill_count,
                "storm": True,
            },
            "reason": "XMage structure matches a storm instant that mills a fixed number of cards per copy.",
            "signals": ["MillCardsTargetEffect", "StormAbility", "TargetPlayer"],
        }

    if card_types in ({"INSTANT"}, {"SORCERY"}) and mill_count > 0:
        return {
            "effect": "mill_cards",
            "scope": "target_player_mill_fixed_or_x_variant_v1",
            "fields": {
                "instant": card_types == {"INSTANT"},
                "target": "player",
                "mill_count": mill_count,
            },
            "reason": "XMage structure includes a target-player mill effect; exact count/scaling still requires scope review.",
            "signals": ["MillCardsTargetEffect", "TargetPlayer"],
        }

    if (
        card_types & {"ARTIFACT", "CREATURE", "ENCHANTMENT"}
        and effect_classes == {"MillCardsTargetEffect"}
        and ability_classes == {"SimpleActivatedAbility"}
        and mill_count > 0
        and cost_classes.issubset(
            {
                "GenericManaCost",
                "ColoredManaCost",
                "ManaCostsImpl",
                "TapSourceCost",
                "TapTargetCost",
            }
        )
    ):
        permanent_type = (
            "artifact"
            if "ARTIFACT" in card_types
            else "creature"
            if "CREATURE" in card_types
            else "enchantment"
        )
        return {
            "effect": "passive",
            "scope": "permanent_simple_activated_target_player_mill_variant_v1",
            "fields": {
                "ability_kind": "activated",
                "activated_effect": "target_player_mill",
                "activated_target_player_mill_count": mill_count,
                "target": "player",
                "target_player_mill": True,
                "permanent_type": permanent_type,
            },
            "reason": "XMage structure matches a permanent with a simple activated fixed target-player mill ability.",
            "signals": ["MillCardsTargetEffect", "SimpleActivatedAbility", "TargetPlayer"],
        }

    if (
        card_types == {"ARTIFACT"}
        and "SimpleActivatedAbility" in ability_classes
        and {"TapSourceCost", "SacrificeTargetCost"}.issubset(cost_classes)
        and mill_count > 0
    ):
        return {
            "effect": "mill_engine",
            "scope": "artifact_tap_sacrifice_permanent_target_player_mill_v1",
            "fields": {
                "activation_requires_tap": True,
                "activation_requires_sacrifice_permanent": True,
                "activation_sacrifice_target_type": "artifact",
                "target": "player",
                "mill_count": mill_count,
                "artifact_enters_untap_source": True,
                "artifact_enters_untap_source_status": "annotation_only",
            },
            "reason": "XMage structure matches an activated artifact that taps and sacrifices a permanent to mill a target player.",
            "signals": ["MillCardsTargetEffect", "SimpleActivatedAbility", "TapSourceCost", "SacrificeTargetCost"],
        }

    return None


def _build_chain_of_vapor_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"INSTANT"} or "ChainOfVaporEffect" not in effect_classes:
        return None
    if not _oracle_has(
        rules_text,
        "return target nonland permanent",
        "sacrifice a land",
        "copy this spell",
    ):
        return None
    return {
        "effect": "bounce",
        "scope": "return_target_nonland_permanent_controller_may_sacrifice_land_copy_v1",
        "fields": {
            "instant": True,
            "target": "nonland_permanent",
            "target_controller_may_sacrifice_land_to_copy": True,
            "copy_may_choose_new_target": True,
        },
        "reason": "XMage custom ChainOfVaporEffect contains the target nonland permanent bounce plus land-sacrifice copy rider.",
        "signals": ["ChainOfVaporEffect", "TargetNonlandPermanent", "TargetSacrifice"],
    }


def _build_life_drain_trigger_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if not {"LoseLifeTargetEffect", "GainLifeEffect"}.issubset(effect_classes):
        return None
    if "DiesThisOrAnotherTriggeredAbility" not in ability_classes:
        return None
    life_loss = _first_int(r"LoseLifeTargetEffect\((\d+)\)", rules_text) or 1
    life_gain = _first_int(r"GainLifeEffect\((\d+)\)", rules_text) or life_loss
    if card_types == {"CREATURE"}:
        return {
            "effect": "creature",
            "scope": "another_creature_dies_target_player_loses_life_you_gain_life_v1",
            "fields": {
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text),
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text),
                "trigger": "creature_dies",
                "dies_this_or_another": True,
                "target_player_loses_life": life_loss,
                "controller_gains_life": life_gain,
            },
            "reason": "XMage structure matches a Blood Artist style death trigger that drains a target player and gains life.",
            "signals": ["DiesThisOrAnotherTriggeredAbility", "LoseLifeTargetEffect", "GainLifeEffect"],
        }
    return {
        "effect": "life_drain_engine",
        "scope": "permanent_death_trigger_target_player_loses_life_you_gain_life_v1",
        "fields": {
            "trigger": "creature_dies",
            "dies_this_or_another": True,
            "target_player_loses_life": life_loss,
            "controller_gains_life": life_gain,
        },
        "reason": "XMage structure matches a permanent death-trigger drain engine.",
        "signals": ["DiesThisOrAnotherTriggeredAbility", "LoseLifeTargetEffect", "GainLifeEffect"],
    }


def _build_copy_stack_spell_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if "CopyTargetStackObjectEffect" not in effect_classes:
        return None
    normalized = _normalized_rules_text(rules_text)
    if "TargetSpell" not in rules_text and "targetspell" not in normalized:
        return None
    buyback_match = re.search(r"BuybackAbility\(\"([^\"]+)\"\)", str(rules_text or ""))
    has_mana_buyback = "BuybackAbility" in ability_classes and buyback_match is not None
    fields: dict[str, Any] = {
        "instant": "INSTANT" in card_types,
        "target": "instant_or_sorcery_on_stack",
        "may_choose_new_targets": True,
        "choose_new_targets_status": "runtime_executor_v1",
        "copy_target_selection_status": "runtime_executor_v1",
        "copy_target_selection_pipeline": "copy_spell_runtime_choose_new_targets_v1",
        "oracle_runtime_scope": (
            "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_buyback_runtime_v1"
            if has_mana_buyback
            else "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1"
        ),
    }
    scope = "copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1"
    signals = ["CopyTargetStackObjectEffect", "TargetSpell"]
    reason = "XMage structure matches copying a target instant or sorcery spell on the stack."
    if has_mana_buyback:
        fields["buyback_status"] = "runtime_executor_v1"
        fields["buyback_cost"] = buyback_match.group(1)
        scope = "copy_stack_instant_or_sorcery_new_targets_runtime_buyback_runtime_v1"
        signals.append("BuybackAbility")
        reason = (
            "XMage structure matches copying a target instant or sorcery spell on the stack "
            "with a mana buyback optional additional cost."
        )
    if "CommanderStormAbility" in ability_classes:
        fields["commander_storm"] = True
    return {
        "effect": "copy_spell",
        "scope": scope,
        "fields": fields,
        "reason": reason,
        "signals": signals,
    }


def _build_source_add_counters_creature_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"CREATURE"} or "AddCountersSourceEffect" not in effect_classes:
        return None

    normalized = _normalized_rules_text(rules_text)

    if (
        "addcounterssourceeffect(countertype.p1p1.createinstance())" in normalized
        and "sacrificetargetcost(staticfilters.filter_controlled_another_creature_or_artifact)" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1",
            "fields": {
                "power": 2,
                "toughness": 1,
                "activation_cost": "sacrifice_creature_or_artifact",
                "self_add_plus_one_counter": 1,
            },
            "reason": "XMage structure matches Bartolome del Presidio sacrificing another creature or artifact to put a +1/+1 counter on itself.",
            "signals": [
                "AddCountersSourceEffect",
                "SacrificeTargetCost",
                "FILTER_CONTROLLED_ANOTHER_CREATURE_OR_ARTIFACT",
            ],
        }

    if "cantblockability" in normalized and "sacrificetargetcost" in normalized:
        return {
            "effect": "creature",
            "scope": "sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "cant_block": True,
                "activation_cost": "sacrifice_creature",
                "self_add_plus_one_counter": 1,
            },
            "reason": "XMage structure matches Carrion Feeder sacrifice-a-creature to put a +1/+1 counter on itself plus can't block.",
            "signals": [
                "CantBlockAbility",
                "SacrificeTargetCost",
                "AddCountersSourceEffect",
            ],
        }

    if (
        "credit.createinstance(3)" in normalized
        and "damagecontrollereffect(3" in normalized
        and "beginningofupkeeptriggeredability" in normalized
        and "sacrificesourcecost" in normalized
        and "gainlifeeffect(new counterssourcecount(countertype.credit))" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "credit_counter_upkeep_growth_sacrifice_for_life_v1",
            "fields": {
                "power": 0,
                "toughness": 2,
                "enters_with_credit_counters": 3,
                "etb_damage_controller": 3,
                "upkeep_add_credit_counter": 1,
                "activation_cost": "sacrifice_self",
                "gain_life_per_credit_counter": True,
                "activation_only_your_upkeep": True,
            },
            "reason": "XMage structure matches Icatian Moneychanger credit-counter lifecycle and upkeep-only sacrifice-for-life activation.",
            "signals": [
                "AddCountersSourceEffect",
                "DamageControllerEffect",
                "GainLifeEffect",
                "credit_counter",
            ],
        }

    if (
        "beginningofendsteptriggeredability" in normalized
        and "wardenofthegroveeffect" in normalized
        and "endures x" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "end_step_add_plus_one_counter": 1,
                "other_nontoken_creature_endures_equal_to_source_counters": True,
            },
            "reason": "XMage structure matches Warden of the Grove end-step growth and the endure-X trigger for another nontoken creature you control.",
            "signals": [
                "BeginningOfEndStepTriggeredAbility",
                "WardenOfTheGroveEffect",
                "EndureSourceEffect",
            ],
        }

    if (
        "wildbornpreservercreatereflexivetriggereffect" in normalized
        and "another non-human creature" in normalized
        and {"FlashAbility", "ReachAbility", "EntersBattlefieldControlledTriggeredAbility", "ReflexiveTriggeredAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "flash": True,
                "reach": True,
                "another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self": True,
            },
            "reason": "XMage structure matches Wildborn Preserver flash/reach body and the optional pay-X reflexive trigger to add X +1/+1 counters to itself.",
            "signals": [
                "FlashAbility",
                "ReachAbility",
                "ReflexiveTriggeredAbility",
                "AddCountersSourceEffect",
            ],
        }

    return None


def _build_creature_variant_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types == {"CREATURE", "ENCHANTMENT"} and {
        "ReturnFromGraveyardToHandTargetEffect",
        "ReturnToHandTargetEffect",
    }.issubset(effect_classes) and "ChannelAbility" in ability_classes:
        return {
            "effect": "creature",
            "scope": "flying_ward_channel_regrowth_or_bounce_creature_v1",
            "fields": {
                "power": 6,
                "toughness": 5,
                "flying": True,
                "ward_cost": "{2}",
                "channel_return_graveyard_card_to_hand": "{2}{G}",
                "channel_return_target_creature_to_hand": "{1}{U}",
            },
            "reason": "XMage structure matches Colossal Skyturtle body plus two channel modes for regrowth and creature bounce.",
            "signals": [
                "ChannelAbility",
                "ReturnFromGraveyardToHandTargetEffect",
                "ReturnToHandTargetEffect",
            ],
        }

    normalized = _normalized_rules_text(rules_text)
    if (
        card_types == {"CREATURE"}
        and "LoseAllAbilitiesTargetEffect" in effect_classes
        and "AddCountersTargetEffect" in effect_classes
        and "EntersBattlefieldTriggeredAbility" in ability_classes
        and "flying counter" in normalized
        and "first strike counter" in normalized
        and "lifelink counter" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "etb_strip_other_creature_abilities_and_grant_keyword_counters_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "flying": True,
                "first_strike": True,
                "lifelink": True,
                "etb_other_target_creature_loses_all_abilities": True,
                "etb_grants_keyword_counters": ["flying", "first_strike", "lifelink"],
            },
            "reason": "XMage structure matches Abigale ETB removing another creature's abilities and placing flying, first strike, and lifelink counters on it.",
            "signals": [
                "LoseAllAbilitiesTargetEffect",
                "AddCountersTargetEffect",
                "keyword_counters",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"CreateTokenCopyTargetEffect"}
        and "EntersBattlefieldTriggeredAbility" in ability_classes
        and _oracle_has(
            rules_text,
            "create two tokens that are copies of target noncreature permanent",
            "they're 3/3 dragon creatures",
            "they have flying",
        )
    ):
        return {
            "effect": "creature",
            "scope": "etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "flying": True,
                "etb_copy_target_types": ["noncreature_permanent"],
                "etb_copy_token_count": 2,
                "etb_copy_force_creature": True,
                "etb_copy_token_power": 3,
                "etb_copy_token_toughness": 3,
                "etb_copy_token_flying": True,
                "etb_copy_token_subtype": "Dragon",
            },
            "reason": "XMage structure matches Astral Dragon ETB creating two 3/3 flying Dragon copies of a target noncreature permanent.",
            "signals": [
                "CreateTokenCopyTargetEffect",
                "EntersBattlefieldTriggeredAbility",
                "copy_noncreature_permanent_twice",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and "CounterTargetEffect" in effect_classes
        and "SimpleActivatedAbility" in ability_classes
        and "SacrificeSourceCost" in cost_classes
        and "PersistAbility" in ability_classes
        and "FlyingAbility" in ability_classes
    ):
        return {
            "effect": "creature",
            "scope": "flying_persist_sacrifice_self_counter_noncreature_spell_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "flying": True,
                "persist": True,
                "activated_counter_noncreature_spell_cost": "{U}",
                "activation_cost": "sacrifice_self",
            },
            "reason": "XMage structure matches Glen Elendra Archmage flying/persist body with a blue plus sacrifice activated counter for noncreature spells.",
            "signals": [
                "CounterTargetEffect",
                "SacrificeSourceCost",
                "PersistAbility",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"DrawCardSourceControllerEffect"}
        and "FlyingAbility" in ability_classes
        and "ConsecratedSphinxTriggeredAbility" in ability_classes
    ):
        return {
            "effect": "creature",
            "scope": "flying_may_draw_two_when_opponent_draws_card_v1",
            "fields": {
                "power": 4,
                "toughness": 6,
                "flying": True,
                "opponent_draws_card_may_draw": 2,
            },
            "reason": "XMage structure matches Consecrated Sphinx flying body with a may trigger to draw two whenever an opponent draws a card.",
            "signals": [
                "ConsecratedSphinxTriggeredAbility",
                "DrawCardSourceControllerEffect",
                "FlyingAbility",
            ],
        }

    if (
        "DamageTargetEffect" in effect_classes
        and "DrawCardOpponentTriggeredAbility" in ability_classes
        and card_types in ({"ENCHANTMENT"}, {"ENCHANTMENT", "CREATURE"})
        and _oracle_has(
            rules_text,
            "whenever an opponent draws a card",
            "deals 1 damage to that player",
        )
    ):
        damage_per_card = _first_int(r"DamageTargetEffect\((\d+)\)", rules_text) or 1
        base_fields: dict[str, Any] = {
            "trigger": "opponent_draw",
            "opponent_draw_damage_per_card": damage_per_card,
        }
        if "CREATURE" in card_types:
            return {
                "effect": "creature",
                "scope": "opponent_draws_card_damage_that_player_v1",
                "fields": {
                    **base_fields,
                    "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 0,
                    "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 0,
                },
                "reason": "XMage structure matches a creature that damages the drawing opponent whenever that opponent draws a card.",
                "signals": [
                    "DrawCardOpponentTriggeredAbility",
                    "DamageTargetEffect",
                    "opponent_draw_damage",
                ],
            }
        return {
            "effect": "passive",
            "scope": "opponent_draws_card_damage_that_player_v1",
            "fields": base_fields,
            "reason": "XMage structure matches an enchantment that damages the drawing opponent whenever that opponent draws a card.",
            "signals": [
                "DrawCardOpponentTriggeredAbility",
                "DamageTargetEffect",
                "opponent_draw_damage",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"DrawCardSourceControllerEffect", "DrawCardAllEffect"}.issubset(effect_classes)
        and {"DrawNthCardTriggeredAbility", "FlashAbility", "FlyingAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1",
            "fields": {
                "power": 2,
                "toughness": 1,
                "flash": True,
                "flying": True,
                "opponent_second_card_each_turn_draw": 1,
                "activated_each_player_draw_cost": "{3}{U}",
                "activated_each_player_draw_count": 1,
            },
            "reason": "XMage structure matches Faerie Mastermind flash/flying body, second-opponent-draw trigger, and activated each-player-draw mode.",
            "signals": [
                "DrawNthCardTriggeredAbility",
                "DrawCardSourceControllerEffect",
                "DrawCardAllEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"AddCountersSourceEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "FlashAbility", "FlyingAbility", "VigilanceAbility", "WanShiTongLibrarianTriggeredAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "flash": True,
                "flying": True,
                "vigilance": True,
                "etb_add_x_plus_one_counters": True,
                "etb_draw_half_x_rounded_down": True,
                "opponent_search_library_add_counter_and_draw": True,
            },
            "reason": "XMage structure matches Wan Shi Tong flash/flying/vigilance body, ETB X-counter plus half-X draw, and opponent-library-search growth trigger.",
            "signals": [
                "WanShiTongLibrarianTriggeredAbility",
                "AddCountersSourceEffect",
                "DrawCardSourceControllerEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"DamageTargetEffect", "AmassEffect"}.issubset(effect_classes)
        and {"FlashAbility", "OrTriggeredAbility", "EntersBattlefieldTriggeredAbility", "OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "flash": True,
                "etb_or_opponent_extra_draw_damage_any_target": 1,
                "amass_orcs": 1,
            },
            "reason": "XMage structure matches Orcish Bowmasters flashing in and triggering on ETB or opponents' extra draws to deal 1 damage to any target and amass Orcs 1.",
            "signals": [
                "OrTriggeredAbility",
                "OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility",
                "DamageTargetEffect",
                "AmassEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"ReturnToHandTargetEffect"}
        and {"CantBeCounteredSourceAbility", "FlashAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1",
            "fields": {
                "power": 7,
                "toughness": 8,
                "flash": True,
                "cant_be_countered": True,
                "cast_spell_trigger_bounce_spell_you_dont_control": True,
                "cast_spell_trigger_bounce_nonland_permanent": True,
            },
            "reason": "XMage structure matches Hullbreaker Horror flash body, anti-counter static, and cast-a-spell trigger bouncing a spell you do not control or a nonland permanent.",
            "signals": [
                "SpellCastControllerTriggeredAbility",
                "ReturnToHandTargetEffect",
                "CantBeCounteredSourceAbility",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"ExileTargetEffect", "AddManaOfAnyColorEffect", "LoseLifeOpponentsEffect", "GainLifeEffect"}.issubset(effect_classes)
        and ability_classes == {"SimpleActivatedAbility"}
        and "TapSourceCost" in cost_classes
    ):
        return {
            "effect": "creature",
            "scope": "graveyard_exile_mana_or_life_shaman_v1",
            "fields": {
                "power": 1,
                "toughness": 2,
                "tap_exile_land_from_graveyard_add_one_mana_any_color": True,
                "black_tap_exile_instant_or_sorcery_from_graveyard_each_opponent_loses_life": 2,
                "green_tap_exile_creature_from_graveyard_gain_life": 2,
            },
            "reason": "XMage structure matches Deathrite Shaman's three graveyard-exile activated abilities for mana, opponent life loss, and life gain.",
            "signals": [
                "ExileTargetEffect",
                "AddManaOfAnyColorEffect",
                "LoseLifeOpponentsEffect",
                "GainLifeEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"DrawCardSourceControllerEffect", "ExileReturnBattlefieldOwnerNextEndStepSourceEffect", "MaximumHandSizeControllerEffect"}.issubset(effect_classes)
        and {"CantBeCounteredSourceAbility", "SimpleActivatedAbility", "SimpleStaticAbility", "SpellCastOpponentTriggeredAbility"}.issubset(ability_classes)
        and "DiscardTargetCost" in cost_classes
    ):
        return {
            "effect": "creature",
            "scope": "cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1",
            "fields": {
                "power": 7,
                "toughness": 7,
                "cant_be_countered": True,
                "no_maximum_hand_size": True,
                "opponent_casts_noncreature_draw": 1,
                "activated_discard_cards_to_exile_and_return_tapped_count": 3,
            },
            "reason": "XMage structure matches Nezahal static protections, opponent noncreature draw trigger, and discard-three self-blink activation.",
            "signals": [
                "CantBeCounteredSourceAbility",
                "MaximumHandSizeControllerEffect",
                "SpellCastOpponentTriggeredAbility",
                "DiscardTargetCost",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"DamageTargetEffect", "GainLifeEffect", "SearchLibraryPutInHandEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "EvokeAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "evoke_etb_red_damage_or_green_land_tutor_lifegain_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "evoke_cost": "{R/G}{R/G}",
                "etb_if_red_red_spent_damage_any_target": 3,
                "etb_if_green_green_spent_search_land_to_hand": True,
                "etb_if_green_green_spent_gain_life": 2,
            },
            "reason": "XMage structure matches Vibrance's 4/4 body, evoke cost, red-spent ETB damage mode, and green-spent ETB land-tutor plus lifegain mode.",
            "signals": [
                "EvokeAbility",
                "DamageTargetEffect",
                "SearchLibraryPutInHandEffect",
                "GainLifeEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"DamageTargetEffect"}
        and {"DefenderAbility", "SimpleActivatedAbility", "SimpleManaAbility"}.issubset(ability_classes)
        and "SacrificeSourceCost" in cost_classes
    ):
        return {
            "effect": "creature",
            "scope": "defender_sacrifice_for_rr_or_blocking_damage_v1",
            "fields": {
                "power": 0,
                "toughness": 3,
                "defender": True,
                "sacrifice_for_red_mana": 2,
                "red_sacrifice_damage_blocking_creature": 2,
            },
            "reason": "XMage structure matches Tinder Wall's defender body, sacrifice-for-{R}{R} mana ability, and red plus sacrifice damage mode against a creature it is blocking.",
            "signals": [
                "DefenderAbility",
                "SimpleManaAbility",
                "DamageTargetEffect",
                "BlockingOrBlockedBySourcePredicate",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"OneShotEffect", "ReturnFromGraveyardToBattlefieldTargetEffect", "RuthlessTechnomancerEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and "SacrificeXTargetCost" in cost_classes
    ):
        return {
            "effect": "creature",
            "scope": "etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1",
            "fields": {
                "power": 2,
                "toughness": 4,
                "etb_may_sacrifice_another_creature_create_treasures_equal_power": True,
                "activated_cost": "{2}{B}",
                "activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less": True,
            },
            "reason": "XMage structure matches Ruthless Technomancer's ETB sacrifice-for-Treasures mode and the activated X-artifact recursion ability.",
            "signals": [
                "RuthlessTechnomancerEffect",
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "SacrificeXTargetCost",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {"EmperorOfBonesEffect", "ExileTargetEffect", "GainAbilityTargetEffect", "SacrificeTargetEffect"}.issubset(effect_classes)
        and {"AdaptAbility", "BeginningOfCombatTriggeredAbility", "OneOrMoreCountersAddedTriggeredAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "combat_exile_adapt_finality_reanimate_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "beginning_of_combat_exile_up_to_one_card_from_graveyard": True,
                "adapt_cost": "{1}{B}",
                "adapt_counters": 2,
                "counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot": True,
            },
            "reason": "XMage structure matches Emperor of Bones exiling a graveyard card at combat, adapting for two counters, and reanimating an exiled creature with finality, haste, and an end-step sacrifice trigger.",
            "signals": [
                "BeginningOfCombatTriggeredAbility",
                "AdaptAbility",
                "OneOrMoreCountersAddedTriggeredAbility",
                "EmperorOfBonesEffect",
            ],
        }

    if (
        card_types == {"CREATURE", "LAND"}
        and {"DiscipleOfFreyaliseEffect", "DrawCardSourceControllerEffect", "GainLifeEffect", "OneShotEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
        and {"AsEntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "GreenManaAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "creature",
            "scope": "etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power": True,
                "land_side_pay_three_life_else_tapped": True,
                "land_side_add_mana": "G",
            },
            "reason": "XMage structure matches Disciple of Freyalise's ETB sacrifice-for-life-and-cards mode plus the green land back face that can enter tapped unless you pay 3 life.",
            "signals": [
                "DiscipleOfFreyaliseEffect",
                "DrawCardSourceControllerEffect",
                "GainLifeEffect",
                "GreenManaAbility",
            ],
        }

    if (
        card_types == {"ARTIFACT", "CREATURE"}
        and {"AddCountersSourceEffect", "DamageTargetEffect", "EntersBattlefieldWithXCountersEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and {"GenericManaCost", "RemoveCountersSourceCost"}.issubset(cost_classes)
    ):
        return {
            "effect": "creature",
            "scope": "x_etb_counters_add_counter_or_remove_counter_ping_v1",
            "fields": {
                "power": 0,
                "toughness": 0,
                "enters_with_x_plus_one_counters": True,
                "activated_generic_four_add_plus_one_counter": 1,
                "activated_remove_plus_one_counter_damage_any_target": 1,
            },
            "reason": "XMage structure matches Walking Ballista entering with X +1/+1 counters, adding counters for {4}, and removing a counter to ping any target.",
            "signals": [
                "EntersBattlefieldWithXCountersEffect",
                "AddCountersSourceEffect",
                "RemoveCountersSourceCost",
                "DamageTargetEffect",
            ],
        }

    return None


def _build_exact_runtime_variant_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    target_classes: set[str],
    filter_classes: set[str],
    cost_classes: set[str],
    xmage_class_name: str,
    rules_text: str,
) -> dict[str, Any] | None:
    normalized = _normalized_rules_text(rules_text)

    if (
        xmage_class_name == "CloudKey"
        and card_types == {"ARTIFACT"}
        and ability_classes == {"AsEntersBattlefieldAbility", "SimpleStaticAbility"}
        and effect_classes == {"ChooseCardTypeEffect", "SpellsCostReductionAllOfChosenCardTypeEffect"}
        and not target_classes
        and not cost_classes
    ):
        return {
            "effect": "static_cost_reduction",
            "scope": "chosen_card_type_cost_reduction_v1",
            "fields": {
                "permanent_type": "artifact",
                "choose_card_type_on_enter": True,
                "chosen_card_type_options": ["artifact", "creature", "enchantment", "instant", "sorcery"],
                "preferred_card_type_order": ["instant", "sorcery", "artifact", "creature", "enchantment"],
                "cost_reduction_applies_to": "spells_you_cast_of_chosen_card_type",
                "cost_reduction_uses_chosen_card_type": True,
                "cost_reduction_generic": 1,
                "applies_to_controller": "source_controller",
            },
            "reason": (
                "XMage structure matches Cloud Key's as-enters card-type choice plus a static "
                "cost reduction for spells of the chosen type."
            ),
            "signals": [
                "CloudKey",
                "ChooseCardTypeEffect",
                "SpellsCostReductionAllOfChosenCardTypeEffect",
            ],
        }

    if (
        xmage_class_name == "AlhammarretsArchive"
        and card_types == {"ARTIFACT"}
        and ability_classes == {"SimpleStaticAbility"}
        and effect_classes == {
            "AlhammarretsArchiveReplacementEffect",
            "GainDoubleLifeReplacementEffect",
        }
        and not target_classes
        and not cost_classes
    ):
        return {
            "effect": "draw_engine",
            "scope": "static_double_life_gain_and_draw_except_first_draw_step_v1",
            "fields": {
                "permanent_type": "artifact",
                "legendary": True,
                "draw_on_enter": False,
                "life_gain_replacement_double": True,
                "life_gain_multiplier": 2,
                "draw_replacement_double_except_first_draw_step": True,
                "draw_replacement_amount_multiplier": 2,
                "draw_replacement_controller_only": True,
                "draw_replacement_first_draw_step_exception": True,
            },
            "reason": (
                "XMage structure matches Alhammarret's Archive static replacement effects: "
                "double life gain and replace eligible controller card draws with two draws."
            ),
            "signals": [
                "AlhammarretsArchive",
                "GainDoubleLifeReplacementEffect",
                "AlhammarretsArchiveReplacementEffect",
                "CardsDrawnDuringDrawStepWatcher",
            ],
        }

    if (
        xmage_class_name == "CurrencyConverter"
        and card_types == {"ARTIFACT"}
        and {"DiscardCardControllerTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and {
            "CurrencyConverterExileEffect",
            "CurrencyConverterTokenEffect",
            "DrawDiscardControllerEffect",
            "OneShotEffect",
        }.issubset(effect_classes)
        and {"GenericManaCost", "TapSourceCost"}.issubset(cost_classes)
        and {"TargetCard", "TargetCardInExile"}.issubset(target_classes)
    ):
        return {
            "effect": "draw_engine",
            "scope": "currency_converter_discard_exile_draw_discard_token_v1",
            "fields": {
                "permanent_type": "artifact",
                "trigger": "controller_discard",
                "controller_discard_may_exile_discarded_card_from_graveyard": True,
                "activated_draw_discard": True,
                "draw_discard_activation_cost_generic": 2,
                "draw_discard_activation_requires_tap": True,
                "activated_draw_count": 1,
                "activated_discard_count": 1,
                "activated_put_exiled_card_into_graveyard_create_token": True,
                "token_activation_requires_tap": True,
                "token_from_exiled_land": "treasure",
                "token_from_exiled_nonland": "rogue",
                "treasure_count": 1,
                "token_count": 1,
                "token_name": "Rogue Token",
                "token_subtype": "Rogue",
                "token_colors": ["B"],
                "token_power": 2,
                "token_toughness": 2,
            },
            "reason": (
                "XMage structure matches Currency Converter: controller discard may exile the discarded card "
                "from graveyard, {2}{T} draws then discards, and {T} moves a card exiled with it to graveyard "
                "to create Treasure for a land or a 2/2 black Rogue for a nonland."
            ),
            "signals": [
                "CurrencyConverter",
                "DiscardCardControllerTriggeredAbility",
                "CurrencyConverterExileEffect",
                "DrawDiscardControllerEffect(1,1)",
                "CurrencyConverterTokenEffect",
                "TreasureToken",
                "RogueToken",
            ],
        }

    if (
        xmage_class_name == "DevotedDruid"
        and card_types == {"CREATURE"}
        and ability_classes == {"GreenManaAbility", "SimpleActivatedAbility"}
        and effect_classes == {"UntapSourceEffect"}
        and "PutCountersSourceCost" in cost_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "green_mana_dork_minus_counter_self_untap_v1",
            "fields": {
                "permanent_type": "creature",
                "is_creature_permanent": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "G",
                "power": 0,
                "toughness": 2,
                "activation_requires_tap": True,
                "activated_put_minus_one_counter_untap_self": True,
                "activated_put_minus_one_counter_untap_self_status": "annotation_only",
            },
            "reason": "XMage structure matches Devoted Druid's green mana ability plus its -1/-1 counter self-untap activated ability.",
            "signals": ["DevotedDruid", "GreenManaAbility", "PutCountersSourceCost", "UntapSourceEffect"],
        }

    if (
        xmage_class_name == "DelightedHalfling"
        and card_types == {"CREATURE"}
        and {"ColorlessManaAbility", "ConditionalAnyColorManaAbility", "SimpleStaticAbility"}.issubset(ability_classes)
        and "DelightedHalflingCantCounterEffect" in effect_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "colorless_or_legendary_any_color_uncounterable_mana_dork_v1",
            "fields": {
                "permanent_type": "creature",
                "is_creature_permanent": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "C",
                "power": 1,
                "toughness": 2,
                "activation_requires_tap": True,
                "conditional_mana_modes_status": "runtime_executor_v1",
                "conditional_mana_modes": [
                    {
                        "color": "C",
                        "mode": "colorless",
                        "restriction": "any_spell",
                        "status": "runtime_executor_v1",
                    },
                    *[
                        {
                            "color": color,
                            "mode": "legendary_spell_uncounterable",
                            "restriction": "legendary_spell",
                            "status": "runtime_executor_v1",
                        }
                        for color in "WUBRG"
                    ],
                ],
                "legendary_mana_spent_spell_cant_be_countered": True,
                "legendary_mana_uncounterable_status": "annotation_only",
            },
            "reason": "XMage structure matches Delighted Halfling's colorless mana mode, legendary-only any-color mana mode, and uncounterable rider on that mana.",
            "signals": [
                "DelightedHalfling",
                "ColorlessManaAbility",
                "ConditionalAnyColorManaAbility",
                "DelightedHalflingCantCounterEffect",
            ],
        }

    if (
        xmage_class_name == "IncubationDruid"
        and card_types == {"CREATURE"}
        and "SimpleManaAbility" in ability_classes
        and "AdaptAbility" in ability_classes
        and {"AnyColorLandsProduceManaEffect", "ManaEffect"}.issubset(effect_classes)
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "land_type_mana_dork_plus_counter_triples_adapt_v1",
            "fields": {
                "permanent_type": "creature",
                "is_creature_permanent": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "mana_produced_if_plus_one_counter": 3,
                "mana_colors_from_controlled_lands": True,
                "produces": "WUBRGC",
                "power": 0,
                "toughness": 2,
                "activation_requires_tap": True,
                "adapt_cost": "{3}{G}{G}",
                "adapt_counters": 3,
                "adapt_status": "annotation_only",
            },
            "reason": "XMage structure matches Incubation Druid's land-type mana ability, +1/+1 counter triple-mana replacement, and Adapt 3 activated ability.",
            "signals": ["IncubationDruid", "SimpleManaAbility", "AnyColorLandsProduceManaEffect", "AdaptAbility"],
        }

    if (
        xmage_class_name == "SelvalaHeartOfTheWilds"
        and card_types == {"CREATURE"}
        and {"EntersBattlefieldAllTriggeredAbility", "SimpleManaAbility"}.issubset(ability_classes)
        and {"AddManaInAnyCombinationEffect", "SelvalaHeartOfTheWildsEffect"}.issubset(effect_classes)
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "greatest_power_any_color_mana_dork_etb_draw_annotation_v1",
            "fields": {
                "permanent_type": "creature",
                "is_creature_permanent": True,
                "is_mana_source": True,
                "mana_produced_from_greatest_power_controlled_creatures": True,
                "produces": "WUBRG",
                "power": 2,
                "toughness": 3,
                "activation_requires_tap": True,
                "activation_mana_cost": "{G}",
                "another_creature_enters_greatest_power_controller_may_draw": True,
                "another_creature_enters_greatest_power_draw_status": "annotation_only",
            },
            "reason": "XMage structure matches Selvala's greatest-power mana ability plus its another-creature ETB draw trigger.",
            "signals": [
                "SelvalaHeartOfTheWilds",
                "AddManaInAnyCombinationEffect",
                "GreatestAmongPermanentsValue.POWER_CONTROLLED_CREATURES",
                "SelvalaHeartOfTheWildsEffect",
            ],
        }

    if (
        xmage_class_name == "BirgiGodOfStorytelling"
        and card_types == {"ARTIFACT", "CREATURE"}
        and "SpellCastControllerTriggeredAbility" in ability_classes
        and "UntilEndOfTurnManaEffect" in effect_classes
    ):
        return {
            "effect": "ramp_engine",
            "scope": "spell_cast_red_mana_trigger_boast_harnfel_annotation_v1",
            "fields": {
                "is_creature_permanent": True,
                "power": 3,
                "toughness": 3,
                "trigger": "spell_cast",
                "spell_cast_add_mana": 1,
                "spell_cast_mana_color": "R",
                "produces": "R",
                "mana_persists_steps": True,
                "boast_twice_each_turn": True,
                "boast_twice_status": "annotation_only",
                "back_face_harnfel_discard_exile_two_play_this_turn": True,
                "back_face_status": "annotation_only",
            },
            "reason": "XMage structure matches Birgi's spell-cast red mana trigger; boast and Harnfel backside are tracked as non-executed annotations.",
            "signals": ["BirgiGodOfStorytelling", "SpellCastControllerTriggeredAbility", "UntilEndOfTurnManaEffect", "BoastAbility"],
        }

    if (
        xmage_class_name == "ElectroAssaultingBattery"
        and card_types == {"CREATURE"}
        and {"FlyingAbility", "LeavesBattlefieldTriggeredAbility", "SimpleStaticAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
        and {"AddManaToManaPoolSourceControllerEffect", "ElectroAssaultingBatteryEffect", "YouDontLoseManaEffect"}.issubset(effect_classes)
        and "TargetPlayer" in target_classes
    ):
        return {
            "effect": "ramp_engine",
            "scope": "instant_sorcery_cast_red_mana_trigger_persistent_red_leaves_x_damage_annotation_v1",
            "fields": {
                "is_creature_permanent": True,
                "power": 2,
                "toughness": 3,
                "flying": True,
                "trigger": "instant_sorcery_cast",
                "instant_sorcery_cast_add_mana": 1,
                "instant_sorcery_cast_mana_color": "R",
                "produces": "R",
                "mana_persists_steps": True,
                "leaves_battlefield_pay_x_damage_target_player": True,
                "leaves_battlefield_pay_x_damage_status": "annotation_only",
            },
            "reason": "XMage structure matches Electro's instant/sorcery-cast red mana trigger and red mana persistence; its leaves-battlefield X damage rider is tracked as annotation.",
            "signals": [
                "ElectroAssaultingBattery",
                "SpellCastControllerTriggeredAbility(FILTER_SPELL_AN_INSTANT_OR_SORCERY)",
                "AddManaToManaPoolSourceControllerEffect",
                "YouDontLoseManaEffect(ManaType.RED)",
                "ElectroAssaultingBatteryEffect",
            ],
        }

    if (
        xmage_class_name == "FracturedPowerstone"
        and card_types == {"ARTIFACT"}
        and "ColorlessManaAbility" in ability_classes
        and "FracturedPowerstoneEffect" in effect_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "colorless_mana_rock_planar_die_annotation_v1",
            "fields": {
                "permanent_type": "artifact",
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "C",
                "activation_requires_tap": True,
                "activated_roll_planar_die": True,
                "activated_roll_planar_die_status": "annotation_only",
            },
            "reason": "XMage structure matches Fractured Powerstone's colorless mana rock mode plus a planar die activated ability outside ManaLoom battle scope.",
            "signals": ["FracturedPowerstone", "ColorlessManaAbility", "FracturedPowerstoneEffect"],
        }

    if (
        xmage_class_name == "CursedMirror"
        and card_types == {"ARTIFACT"}
        and {"EntersBattlefieldAbility", "RedManaAbility"}.issubset(ability_classes)
        and "CopyPermanentEffect" in effect_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "red_mana_rock_etb_copy_creature_haste_annotation_v1",
            "fields": {
                "permanent_type": "artifact",
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "R",
                "activation_requires_tap": True,
                "etb_may_copy_any_creature_until_eot": True,
                "etb_copy_grants_haste": True,
                "etb_copy_status": "annotation_only",
                "nonmana_abilities_require_separate_scope": True,
                "nonmana_abilities_status": "etb_copy_creature_haste_annotation_only",
            },
            "reason": "XMage structure matches Cursed Mirror's red mana rock ability; the ETB temporary creature-copy-with-haste choice is retained as annotation.",
            "signals": ["CursedMirror", "RedManaAbility", "EntersBattlefieldAbility", "CopyPermanentEffect", "HasteAbility"],
        }

    if (
        xmage_class_name == "BridgeworksBattle"
        and card_types == {"LAND", "SORCERY"}
        and {"BoostTargetEffect", "FightTargetsEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
        and {"AsEntersBattlefieldAbility", "GreenManaAbility"}.issubset(ability_classes)
        and "PayLifeCost" in cost_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "mdfc_green_land_pay_three_life_spell_fight_annotation_v1",
            "fields": {
                "mdfc_land_face": {
                    "name": "Tanglespan Bridgeworks",
                    "type_line": "Land",
                    "effect": "land",
                    "mana_produced": 1,
                    "produces": "G",
                    "may_pay_life_to_enter_untapped": 3,
                },
                "spell_face_effect": "target_creature_you_control_plus_two_fight_up_to_one_opponent_creature",
                "spell_face_status": "annotation_only",
                "land_side_pay_three_life_else_tapped": True,
                "land_side_add_mana": "G",
                "nonmana_abilities_require_separate_scope": True,
                "nonmana_abilities_status": "spell_face_annotation_only",
            },
            "reason": "XMage structure matches Bridgeworks Battle's green MDFC land face; the front-face pump/fight spell is retained as annotation.",
            "signals": ["BridgeworksBattle", "GreenManaAbility", "TapSourceUnlessPaysEffect", "BoostTargetEffect", "FightTargetsEffect"],
        }

    if (
        xmage_class_name == "HydroelectricSpecimen"
        and card_types == {"CREATURE", "LAND"}
        and {"ChangeATargetOfTargetSpellAbilityToSourceEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
        and {"AsEntersBattlefieldAbility", "BlueManaAbility", "EntersBattlefieldTriggeredAbility", "FlashAbility"}.issubset(ability_classes)
        and "PayLifeCost" in cost_classes
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "mdfc_blue_land_pay_three_life_flash_redirect_creature_annotation_v1",
            "fields": {
                "mdfc_land_face": {
                    "name": "Hydroelectric Laboratory",
                    "type_line": "Land",
                    "effect": "land",
                    "mana_produced": 1,
                    "produces": "U",
                    "may_pay_life_to_enter_untapped": 3,
                },
                "creature_face_power": 1,
                "creature_face_toughness": 4,
                "flash": True,
                "etb_change_single_target_instant_or_sorcery_to_self": True,
                "creature_face_status": "annotation_only",
                "land_side_pay_three_life_else_tapped": True,
                "land_side_add_mana": "U",
                "nonmana_abilities_require_separate_scope": True,
                "nonmana_abilities_status": "creature_face_annotation_only",
            },
            "reason": "XMage structure matches Hydroelectric Specimen's blue MDFC land face; the flash creature ETB redirect mode is retained as annotation.",
            "signals": [
                "HydroelectricSpecimen",
                "BlueManaAbility",
                "TapSourceUnlessPaysEffect",
                "FlashAbility",
                "ChangeATargetOfTargetSpellAbilityToSourceEffect",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "BloodSun"
        and {"BloodSunEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "passive",
            "scope": "etb_draw_all_lands_lose_nonmana_abilities_v1",
            "fields": {
                "etb_draw_count": 1,
                "suppresses_land_nonmana_abilities": True,
            },
            "reason": "XMage structure matches Blood Sun's enters-the-battlefield draw plus its static effect that strips all nonmana abilities from lands.",
            "signals": [
                "BloodSun",
                "BloodSunEffect",
                "DrawCardSourceControllerEffect",
                "EntersBattlefieldTriggeredAbility",
                "SimpleStaticAbility",
            ],
        }

    if (
        "INSTANT" in card_types
        and "GainProtectionFromColorTargetEffect" in effect_classes
        and "TargetControlledCreaturePermanent" in target_classes
    ):
        return {
            "effect": "grant_protection_from_chosen_color",
            "scope": "target_creature_you_control_protection_from_chosen_color_until_eot_v1",
            "fields": {
                "instant": True,
                "target": "creature_you_control",
                "target_controller": "own",
                "protection_from_chosen_color_until_eot": True,
                "protection_color_choice": "contextual_best_source_color",
            },
            "reason": "XMage structure matches a white instant giving target creature you control protection from the color of your choice until end of turn.",
            "signals": [
                "GainProtectionFromColorTargetEffect",
                "TargetControlledCreaturePermanent",
            ],
        }

    if (
        xmage_class_name == "EightAndAHalfTails"
        and card_types == {"CREATURE"}
        and {"GainAbilityTargetEffect", "BecomesColorTargetEffect"}.issubset(effect_classes)
        and "SimpleActivatedAbility" in ability_classes
        and {"TargetControlledPermanent", "TargetSpellOrPermanent"}.issubset(target_classes)
    ):
        return {
            "effect": "creature",
            "scope": "creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1",
            "fields": {
                "is_creature_permanent": True,
                "power": 2,
                "toughness": 2,
                "runtime_modeled_effect": "creature_body_plus_targeted_protection_response",
                "activated_protection_status": "runtime_executor_v1",
                "oracle_runtime_scope": "targeted_stack_removal_response_protection_activation_runtime_v1",
                "protection_activation_timing": "targeted_stack_response",
                "protection_target": "target_permanent_you_control",
                "protection_choices": ["white"],
                "can_make_source_white_for_protection": True,
                "source_color_change_target": "target_spell_or_permanent",
                "source_color_change_to": "white",
                "targeted_protection_activation_mana_cost": "{2}{W}",
                "activation_cost": "{1} plus {1}{W}",
                "activation_requires_tap": False,
                "tap_activation": False,
                "source_must_be_untapped": False,
                "summoning_sickness_applies_to_activation": False,
                "duration": "until_end_of_turn",
                "xmage_effect": (
                    "SimpleActivatedAbility + GainAbilityTargetEffect(Protection from white) "
                    "+ BecomesColorTargetEffect(white)"
                ),
            },
            "reason": (
                "XMage structure matches Eight-and-a-Half-Tails: a creature with activated abilities "
                "that can make a spell or permanent white and give a controlled permanent protection "
                "from white until end of turn."
            ),
            "signals": [
                "GainAbilityTargetEffect",
                "BecomesColorTargetEffect",
                "TargetControlledPermanent",
                "TargetSpellOrPermanent",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and xmage_class_name == "DeflectingPalm"
        and "PreventNextDamageFromChosenSourceEffect" in effect_classes
        and "DeflectingPalmPreventionApplier" in rules_text
        and (
            "deals that much damage to that source's controller" in normalized
            or "objectController.damage(prevented" in rules_text
        )
    ):
        return {
            "effect": "damage_prevention_reflect",
            "scope": "prevent_next_damage_from_chosen_source_to_you_reflect_to_controller_v1",
            "fields": {
                "instant": True,
                "prevent_next_damage_from_chosen_source": True,
                "prevent_damage_to": "you",
                "prevent_damage_duration": "until_end_of_turn",
                "reflect_prevented_damage": True,
                "reflect_target": "chosen_source_controller",
                "source_choice_required": True,
                "prevent_damage_amount": 999,
            },
            "reason": "XMage structure matches Deflecting Palm: PreventNextDamageFromChosenSourceEffect until end of turn with a prevention applier that deals the prevented damage to the chosen source's controller.",
            "signals": [
                "PreventNextDamageFromChosenSourceEffect(Duration.EndOfTurn, true)",
                "DeflectingPalmPreventionApplier",
                "objectController.damage(prevented, source.getSourceId(), source, game)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "Penance"
        and effect_classes == {"PreventNextDamageFromChosenSourceEffect"}
        and ability_classes == {"SimpleActivatedAbility"}
        and cost_classes == {"PutCardFromHandOnTopOfLibraryCost"}
        and (
            "black or red source" in normalized
            or "colorpredicate(objectcolor.black)" in normalized
            or "colorpredicate(objectcolor.red)" in normalized
        )
    ):
        return {
            "effect": "damage_prevention_shield",
            "scope": "activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1",
            "fields": {
                "activated_prevent_next_damage_from_chosen_source": True,
                "activation_cost": "put_card_from_hand_on_top_of_library",
                "activation_cost_generic": 0,
                "activation_requires_put_card_from_hand_on_top_library": True,
                "prevent_next_damage_from_chosen_source": True,
                "prevent_damage_to": "you",
                "prevent_damage_duration": "until_end_of_turn",
                "prevent_damage_amount": 999,
                "source_choice_required": True,
                "source_color_filter": ["black", "red"],
            },
            "reason": (
                "XMage structure matches Penance: a SimpleActivatedAbility with "
                "PutCardFromHandOnTopOfLibraryCost that creates a chosen-source "
                "damage prevention shield restricted to black or red sources."
            ),
            "signals": [
                "SimpleActivatedAbility",
                "PutCardFromHandOnTopOfLibraryCost",
                "PreventNextDamageFromChosenSourceEffect(Duration.EndOfTurn, false, filter)",
                "FilterSource(\"black or red source\")",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "HiddenRetreat"
        and effect_classes == {"HiddenRetreatEffect"}
        and ability_classes == {"SimpleActivatedAbility"}
        and cost_classes == {"PutCardFromHandOnTopOfLibraryCost"}
        and "TargetSpell" in target_classes
        and (
            "target instant or sorcery spell" in normalized
            or "filter_spell_instant_or_sorcery" in normalized
            or "isinstantorsorcery" in normalized
        )
    ):
        return {
            "effect": "damage_prevention_shield",
            "scope": "activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1",
            "fields": {
                "activated_prevent_damage_from_target_spell": True,
                "activation_cost": "put_card_from_hand_on_top_of_library",
                "activation_cost_generic": 0,
                "activation_requires_put_card_from_hand_on_top_library": True,
                "can_setup_lorehold_miracle_draw": True,
                "prevent_damage_from_target_spell": True,
                "prevent_damage_target_type": "instant_or_sorcery_spell",
                "prevent_damage_duration": "until_end_of_turn",
                "prevent_damage_amount": 999,
                "spell_target_required": True,
                "target_spell_card_types": ["instant", "sorcery"],
            },
            "reason": (
                "XMage structure matches Hidden Retreat: a SimpleActivatedAbility with "
                "PutCardFromHandOnTopOfLibraryCost, TargetSpell filtered to instant or "
                "sorcery spells, and a prevention effect that blanks damage from that "
                "target spell this turn."
            ),
            "signals": [
                "SimpleActivatedAbility",
                "PutCardFromHandOnTopOfLibraryCost",
                "TargetSpell(StaticFilters.FILTER_SPELL_INSTANT_OR_SORCERY)",
                "HiddenRetreatEffect extends PreventionEffectImpl(Duration.EndOfTurn, Integer.MAX_VALUE, false, false)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "AuthorityOfTheConsuls"
        and {"GainLifeEffect", "PermanentsEnterBattlefieldTappedEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldOpponentTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "passive",
            "scope": "opponent_creature_enter_tapped_gain_life_v1",
            "fields": {
                "opponents_creatures_enter_tapped": True,
                "trigger": "creature_enters_under_opponent_control",
                "trigger_effect": "gain_life",
                "trigger_gain_life": 1,
            },
            "reason": "XMage structure matches Authority of the Consuls: opponents' creatures enter tapped and each creature entering under an opponent's control gains the source controller 1 life.",
            "signals": [
                "PermanentsEnterBattlefieldTappedEffect",
                "EntersBattlefieldOpponentTriggeredAbility",
                "GainLifeEffect(1)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "MagusOfTheWheel"
        and {"DiscardHandAllEffect", "DrawCardAllEffect"}.issubset(effect_classes)
        and "SimpleActivatedAbility" in ability_classes
        and {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
    ):
        return {
            "effect": "creature",
            "scope": "activated_tap_sacrifice_self_each_player_discards_hand_draws_seven_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "activation_cost_generic": 1,
                "activation_cost_colors": ["R"],
                "activation_requires_tap": True,
                "activation_requires_sacrifice": True,
                "activation_cost": "sacrifice_self",
                "activated_multiplayer_discard_draw_count": 7,
                "wheel_like": True,
            },
            "reason": "XMage structure matches Magus of the Wheel: a 3/3 creature with {1}{R}, tap, sacrifice to make each player discard their hand and draw seven cards.",
            "signals": [
                "DiscardHandAllEffect",
                "DrawCardAllEffect(7)",
                "SimpleActivatedAbility",
                "TapSourceCost",
                "SacrificeSourceCost",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "SunTitan"
        and "ReturnFromGraveyardToBattlefieldTargetEffect" in effect_classes
        and "EntersBattlefieldOrAttacksSourceTriggeredAbility" in ability_classes
        and "TargetCardInYourGraveyard" in target_classes
        and (
            "FilterPermanentCard" in rules_text
            or "permanent card with mana value 3 or less" in normalized
            or "manavaluepredicate(comparisontype.fewer_than, 4)" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "sun_titan_etb_attack_return_permanent_mv_lte_3_v1",
            "fields": {
                "power": 6,
                "toughness": 6,
                "vigilance": True,
                "etb_recursion_count": 1,
                "etb_recursion_target": "permanent",
                "etb_recursion_destination": "battlefield",
                "etb_recursion_mana_value_max": 3,
                "attack_trigger_graveyard_recursion": True,
                "attack_recursion_count": 1,
                "attack_recursion_target": "permanent",
                "attack_recursion_destination": "battlefield",
                "attack_recursion_mana_value_max": 3,
            },
            "reason": "XMage structure matches Sun Titan: a 6/6 vigilance creature whose ETB-or-attack trigger returns one target permanent card with mana value 3 or less from your graveyard to the battlefield.",
            "signals": [
                "EntersBattlefieldOrAttacksSourceTriggeredAbility",
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "TargetCardInYourGraveyard",
                "FilterPermanentCard",
                "ManaValuePredicate(<4)",
                "VigilanceAbility",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "GoldspanDragon"
        and "CreateTokenEffect" in effect_classes
        and "GainAbilityControlledEffect" in effect_classes
        and {"AttacksTriggeredAbility", "BecomesTargetSourceTriggeredAbility", "OrTriggeredAbility"}.issubset(ability_classes)
        and {"FlyingAbility", "HasteAbility", "SimpleStaticAbility", "SimpleManaAbility"}.issubset(ability_classes)
        and "TreasureToken" in rules_text
        and "AddManaOfAnyColorEffect(2)" in rules_text
    ):
        return {
            "effect": "creature",
            "scope": "goldspan_dragon_attack_or_target_treasure_double_mana_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "flying": True,
                "haste": True,
                "attack_or_becomes_target_create_treasure": True,
                "attack_trigger_create_treasure": True,
                "becomes_spell_target_create_treasure": True,
                "treasure_count": 1,
                "treasure_mana_value": 2,
                "controlled_treasures_add_two_mana": True,
            },
            "reason": "XMage structure matches Goldspan Dragon: a 4/4 flying haste creature whose attack-or-spell-target trigger creates one Treasure and whose static ability makes controlled Treasures add two mana.",
            "signals": [
                "FlyingAbility",
                "HasteAbility",
                "OrTriggeredAbility",
                "AttacksTriggeredAbility",
                "BecomesTargetSourceTriggeredAbility",
                "CreateTokenEffect(TreasureToken)",
                "GainAbilityControlledEffect(SimpleManaAbility(AddManaOfAnyColorEffect(2)))",
            ],
        }

    if (
        xmage_class_name == "PrimalAmulet"
        and card_types == {"ARTIFACT", "LAND"}
        and {
            "AddCountersSourceEffect",
            "CopyTargetStackObjectEffect",
            "CreateDelayedTriggeredAbilityEffect",
            "OneShotEffect",
            "SpellsCostReductionControllerEffect",
        }.issubset(effect_classes)
        and {
            "AnyColorManaAbility",
            "DelayedTriggeredAbility",
            "SimpleStaticAbility",
            "SpellCastControllerTriggeredAbility",
        }.issubset(ability_classes)
    ):
        return {
            "effect": "static_cost_reduction",
            "scope": "artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1",
            "fields": {
                "cost_reduction_applies_to": "instant_sorcery_spells_you_cast",
                "cost_reduction_generic": 1,
                "applies_to_card_types": ["instant", "sorcery"],
                "ability_kind": "static",
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "add_named_counter_then_transform",
                "trigger_counter_type": "charge",
                "trigger_counter_count": 1,
                "transform_counter_threshold": 4,
                "transform_remove_all_named_counters": True,
                "transform_optional": True,
                "transform_to": {
                    "name": "Primal Wellspring",
                    "type_line": "Land",
                    "effect": "land",
                    "battle_model_scope": "artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1",
                    "is_mana_source": True,
                    "mana_produced": 1,
                    "produces": "WUBRG",
                    "trigger": "instant_sorcery_cast",
                    "trigger_effect": "copy_when_mana_spent",
                    "target": "own_instant_or_sorcery_on_stack",
                    "copy_when_mana_spent_to_cast_matching_spell": True,
                    "copy_when_mana_spent_card_types": ["instant", "sorcery"],
                    "may_choose_new_targets": True,
                    "choose_new_targets_status": "may",
                },
            },
            "reason": "XMage structure matches Primal Amulet front-side instant/sorcery cost reduction plus charge counters that transform into Primal Wellspring, whose mana copies the instant or sorcery spell it helps cast.",
            "signals": [
                "SpellsCostReductionControllerEffect",
                "SpellCastControllerTriggeredAbility",
                "AddCountersSourceEffect",
                "AnyColorManaAbility",
                "CopyTargetStackObjectEffect",
                "transform_threshold_4_charge",
            ],
        }

    if (
        xmage_class_name == "PyromancersGoggles"
        and card_types == {"ARTIFACT"}
        and effect_classes == {"CopyTargetStackObjectEffect"}
        and ability_classes == {"PyromancersGogglesTriggeredAbility", "RedManaAbility"}
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "red_mana_rock_red_instant_sorcery_mana_spent_copy_spell_v1",
            "fields": {
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "R",
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "copy_when_mana_spent",
                "target": "own_instant_or_sorcery_on_stack",
                "copy_when_mana_spent_to_cast_matching_spell": True,
                "copy_when_mana_spent_card_types": ["instant", "sorcery"],
                "copy_when_mana_spent_spell_colors": ["R"],
                "may_choose_new_targets": True,
                "choose_new_targets_status": "may",
            },
            "reason": "XMage structure matches Pyromancer's Goggles: a legendary red mana rock whose mana copies a red instant or sorcery spell it helps cast.",
            "signals": [
                "RedManaAbility",
                "PyromancersGogglesTriggeredAbility",
                "CopyTargetStackObjectEffect",
                "red_instant_sorcery_mana_copy",
            ],
        }

    if (
        xmage_class_name == "PalantirOfOrthanc"
        and card_types == {"ARTIFACT"}
        and {
            "AddCountersSourceEffect",
            "OneShotEffect",
            "ScryEffect",
        }.issubset(effect_classes)
        and "BeginningOfEndStepTriggeredAbility" in ability_classes
        and "TargetOpponent" in target_classes
    ):
        return {
            "effect": "draw_engine",
            "scope": "controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1",
            "fields": {
                "trigger": "controller_end_step",
                "trigger_effect": "add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss",
                "trigger_counter_type": "influence",
                "trigger_counter_count": 1,
                "trigger_scry_count": 2,
                "target": "opponent",
                "target_opponent_may_have_you_draw_count": 1,
                "decline_mill_count_source": "source_named_counter_count",
                "decline_mill_counter_type": "influence",
                "decline_opponent_life_loss_equals_milled_cards_total_mana_value": True,
            },
            "reason": "XMage structure matches Palantir of Orthanc: controller end step adds an influence counter, scries 2, then target opponent chooses between letting you draw or taking life loss from a mill equal to influence counters.",
            "signals": [
                "BeginningOfEndStepTriggeredAbility",
                "AddCountersSourceEffect",
                "ScryEffect",
                "TargetOpponent",
                "OneShotEffect",
            ],
        }

    if (
        xmage_class_name == "Galvanoth"
        and card_types == {"CREATURE"}
        and "OneShotEffect" in effect_classes
        and "BeginningOfUpkeepTriggeredAbility" in ability_classes
        and "MayCastTargetCardEffect" in rules_text
        and "look at the top card of your library" in normalized
        and "cast it without paying its mana cost" in normalized
        and "instant or sorcery" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "trigger": "controller_upkeep",
                "trigger_effect": "look_top_card_may_cast_if_instant_or_sorcery",
                "upkeep_look_top_card": True,
                "upkeep_may_cast_top_instant_or_sorcery_without_paying_mana": True,
                "upkeep_top_library_cast_types": ["instant", "sorcery"],
            },
            "reason": "XMage structure matches Galvanoth: a 3/3 creature with a beginning-of-upkeep trigger that looks at the top card of your library and may cast it without paying its mana cost if it is an instant or sorcery.",
            "signals": [
                "BeginningOfUpkeepTriggeredAbility",
                "OneShotEffect",
                "MayCastTargetCardEffect(WITHOUT_PAYING_MANA_COST)",
                "look at the top card of your library",
                "instant or sorcery",
            ],
        }

    if (
        xmage_class_name == "VelomachusLorehold"
        and card_types == {"CREATURE"}
        and "OneShotEffect" in effect_classes
        and "AttacksTriggeredAbility" in ability_classes
        and "look at the top seven cards of your library" in normalized
        and "cast an instant or sorcery spell" in normalized
        and "without paying its mana cost" in normalized
        and "mana value less than or equal to" in normalized
        and "put the rest on the bottom of your library in a random order" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1",
            "fields": {
                "power": 5,
                "toughness": 5,
                "flying": True,
                "vigilance": True,
                "haste": True,
                "trigger": "attack",
                "trigger_effect": "look_top_seven_may_cast_instant_or_sorcery_lte_power",
                "attack_look_top_count": 7,
                "attack_top_library_cast_types": ["instant", "sorcery"],
                "attack_may_cast_from_looked_cards_without_paying_mana": True,
                "attack_cast_mana_value_max_source": "source_power",
                "attack_put_rest_bottom_random": True,
            },
            "reason": "XMage structure matches Velomachus Lorehold: a 5/5 flying vigilance haste creature whose attack trigger looks at the top seven cards, may cast one instant or sorcery with mana value less than or equal to its power without paying mana, then puts the rest on the bottom randomly.",
            "signals": [
                "AttacksTriggeredAbility",
                "OneShotEffect",
                "look at the top seven cards of your library",
                "instant or sorcery",
                "mana value less than or equal to source power",
                "without paying its mana cost",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "SurlyBadgersaur"
        and {"AddCountersSourceEffect", "CreateTokenEffect", "FightTargetSourceEffect"}.issubset(effect_classes)
        and "DiscardCardControllerTriggeredAbility" in ability_classes
        and "TargetPermanent" in target_classes
        and "TreasureToken" in rules_text
        and (
            "FILTER_CARD_CREATURE_A" in rules_text
            or "filter_card_creature_a" in normalized
        )
        and (
            "FILTER_CARD_LAND_A" in rules_text
            or "filter_card_land_a" in normalized
        )
        and (
            "FilterNonlandCard" in rules_text
            or "noncreature, nonland card" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "surly_badgersaur_discard_card_type_triggers_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "trigger": "controller_discard",
                "controller_discard_creature_add_plus_one_counter": True,
                "controller_discard_counter_type": "+1/+1",
                "controller_discard_counter_count": 1,
                "controller_discard_land_create_treasure": True,
                "controller_discard_treasure_count": 1,
                "controller_discard_noncreature_nonland_fight": True,
                "controller_discard_fight_target": "up_to_one_creature_you_dont_control",
                "controller_discard_fight_optional": True,
            },
            "reason": "XMage structure matches Surly Badgersaur: a 3/3 creature with controller-discard triggers split by discarded card type for +1/+1 counter, Treasure, or optional fight.",
            "signals": [
                "DiscardCardControllerTriggeredAbility(creature card)",
                "AddCountersSourceEffect(+1/+1)",
                "DiscardCardControllerTriggeredAbility(land card)",
                "CreateTokenEffect(TreasureToken)",
                "DiscardCardControllerTriggeredAbility(noncreature nonland card)",
                "FightTargetSourceEffect",
                "TargetPermanent(up to one creature you don't control)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "BoneMiser"
        and {"BasicManaEffect", "CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and ability_classes == {"DiscardCardControllerTriggeredAbility"}
        and "ZombieToken" in rules_text
        and "Mana.BlackMana(2)" in rules_text
        and (
            "FILTER_CARD_CREATURE_A" in rules_text
            or "filter_card_creature_a" in normalized
        )
        and (
            "FILTER_CARD_LAND_A" in rules_text
            or "filter_card_land_a" in normalized
        )
        and (
            "FilterNonlandCard" in rules_text
            or "noncreature, nonland card" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "controller_discards_card_type_token_mana_draw_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "trigger": "controller_discard",
                "controller_discard_creature_create_token": True,
                "token_count": 1,
                "token_name": "Zombie Token",
                "token_subtype": "Zombie",
                "token_colors": ["B"],
                "token_power": 2,
                "token_toughness": 2,
                "controller_discard_land_add_mana_color": "black",
                "controller_discard_land_add_mana_amount": 2,
                "controller_discard_noncreature_nonland_draw_cards": 1,
            },
            "reason": "XMage structure matches Bone Miser: a 4/4 creature with controller-discard triggers split by discarded card type for Zombie token, {B}{B}, or card draw.",
            "signals": [
                "DiscardCardControllerTriggeredAbility(creature card)",
                "CreateTokenEffect(ZombieToken)",
                "DiscardCardControllerTriggeredAbility(land card)",
                "BasicManaEffect(Mana.BlackMana(2))",
                "DiscardCardControllerTriggeredAbility(noncreature nonland card)",
                "DrawCardSourceControllerEffect(1)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "WasteNot"
        and {"BasicManaEffect", "CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and {
            "WasteNotCreatureTriggeredAbility",
            "WasteNotLandTriggeredAbility",
            "WasteNotOtherTriggeredAbility",
        }.issubset(ability_classes)
        and (
            "ZombieToken" in rules_text
            or "CreateTokenEffect" in effect_classes
        )
    ):
        return {
            "effect": "token_maker",
            "scope": "opponent_discards_card_type_token_mana_draw_v1",
            "fields": {
                "trigger": "opponent_discard",
                "opponent_discard_creature_create_token": True,
                "token_count": 1,
                "token_name": "Zombie Token",
                "token_subtype": "Zombie",
                "token_colors": ["B"],
                "token_power": 2,
                "token_toughness": 2,
                "opponent_discard_land_add_mana_color": "black",
                "opponent_discard_land_add_mana_amount": 2,
                "opponent_discard_noncreature_nonland_draw_cards": 1,
            },
            "reason": "XMage structure matches Waste Not: opponent-discard triggers split by discarded card type for Zombie token, {B}{B}, or card draw.",
            "signals": [
                "WasteNotCreatureTriggeredAbility",
                "CreateTokenEffect(ZombieToken)",
                "WasteNotLandTriggeredAbility",
                "BasicManaEffect(Mana.BlackMana(2))",
                "WasteNotOtherTriggeredAbility",
                "DrawCardSourceControllerEffect(1)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "GreenGoblinNemesis"
        and {"AddCountersTargetEffect", "CreateTokenEffect"}.issubset(effect_classes)
        and "DiscardCardControllerTriggeredAbility" in ability_classes
        and "TargetPermanent" in target_classes
        and "TreasureToken" in rules_text
        and (
            "FILTER_CARD_A_NON_LAND" in rules_text
            or "discard a nonland card" in normalized
        )
        and (
            "FILTER_CARD_LAND_A" in rules_text
            or "discard a land card" in normalized
        )
        and (
            "FilterControlledPermanent(SubType.GOBLIN)" in rules_text
            or "target Goblin you control" in rules_text
        )
    ):
        return {
            "effect": "creature",
            "scope": "controller_discards_nonland_counter_land_treasure_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "flying": True,
                "trigger": "controller_discard",
                "controller_discard_nonland_add_plus_one_counter_to_controlled_subtype": True,
                "controller_discard_counter_target_subtype": "Goblin",
                "controller_discard_counter_type": "+1/+1",
                "controller_discard_counter_count": 1,
                "controller_discard_land_create_treasure": True,
                "controller_discard_treasure_count": 1,
                "controller_discard_treasure_tapped": True,
            },
            "reason": "XMage structure matches Green Goblin, Nemesis: a 3/3 flying Goblin with controller-discard triggers for nonland +1/+1 counters on a controlled Goblin and land-to-tapped-Treasure.",
            "signals": [
                "DiscardCardControllerTriggeredAbility(nonland card)",
                "AddCountersTargetEffect(+1/+1)",
                "TargetPermanent(controlled Goblin)",
                "DiscardCardControllerTriggeredAbility(land card)",
                "CreateTokenEffect(TreasureToken tapped)",
            ],
        }

    if (
        "CREATURE" in card_types
        and xmage_class_name == "AclazotzDeepestBetrayal"
        and "AclazotzDeepestBetrayalTriggeredAbility" in ability_classes
        and "CreateTokenEffect" in effect_classes
        and ("LifelinkAbility" in ability_classes or "LifelinkAbility.getInstance" in rules_text)
    ):
        return {
            "effect": "creature",
            "scope": "opponent_discards_land_create_bat_token_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "flying": True,
                "lifelink": True,
                "trigger": "opponent_discard",
                "opponent_discard_land_create_token": True,
                "token_count": 1,
                "token_name": "Bat Token",
                "token_subtype": "Bat",
                "token_colors": ["B"],
                "token_power": 1,
                "token_toughness": 1,
                "token_flying": True,
            },
            "reason": "XMage structure matches Aclazotz's land-discard token trigger: whenever an opponent discards a land card, create a 1/1 black Bat creature token with flying.",
            "signals": [
                "AclazotzDeepestBetrayalTriggeredAbility",
                "GameEvent.EventType.DISCARDED_CARD",
                "game.getOpponents(controller).contains(event.player)",
                "discarded.isLand(game)",
                "CreateTokenEffect(BatToken)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "BlackMarketConnections"
        and "BeginningOfFirstMainTriggeredAbility" in ability_classes
        and {"CreateTokenEffect", "DrawCardSourceControllerEffect", "LoseLifeSourceControllerEffect"}.issubset(effect_classes)
        and "TreasureToken" in rules_text
        and "Shapeshifter32Token" in rules_text
    ):
        return {
            "effect": "token_maker",
            "scope": "precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1",
            "fields": {
                "trigger": "beginning_precombat_main",
                "precombat_main_choose_modes_treasure_draw_token_life_loss": True,
                "mode_selection_model": "all_modes_if_life_after_loss_at_least_floor",
                "mode_selection_life_floor": 4,
                "precombat_main_modes": [
                    {"name": "Sell Contraband", "effect": "create_treasure", "treasure_count": 1, "life_loss": 1},
                    {"name": "Buy Information", "effect": "draw_cards", "draw_cards": 1, "life_loss": 2},
                    {
                        "name": "Hire a Mercenary",
                        "effect": "token_maker",
                        "token_count": 1,
                        "life_loss": 3,
                        "token": {
                            "token_name": "Shapeshifter Token",
                            "token_subtype": "Shapeshifter",
                            "token_power": 3,
                            "token_toughness": 2,
                            "token_colors": [],
                            "token_keywords": ["changeling"],
                        },
                    },
                ],
            },
            "reason": "XMage structure matches Black Market Connections: beginning of precombat main modal resource trigger creating Treasure, drawing, and creating a 3/2 colorless Shapeshifter with life-loss mode costs.",
            "signals": [
                "BeginningOfFirstMainTriggeredAbility",
                "CreateTokenEffect(TreasureToken)",
                "DrawCardSourceControllerEffect(1)",
                "CreateTokenEffect(Shapeshifter32Token)",
                "LoseLifeSourceControllerEffect(1/2/3)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "SmugglersShare"
        and "BeginningOfEndStepTriggeredAbility" in ability_classes
        and {"CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and "CardsAmountDrawnThisTurnWatcher" in rules_text
        and "PermanentsEnteredBattlefieldWatcher" in rules_text
        and "TreasureToken" in rules_text
    ):
        return {
            "effect": "token_maker",
            "scope": "each_end_step_opponent_extra_draw_landfall_draw_treasure_v1",
            "fields": {
                "trigger": "each_end_step",
                "each_end_step_opponent_extra_draw_land_treasure": True,
                "opponent_cards_drawn_threshold": 2,
                "draw_cards_per_qualified_opponent": 1,
                "opponent_lands_entered_threshold": 2,
                "treasure_count_per_qualified_opponent": 1,
                "land_entry_runtime_proxy": "lands_played_this_turn",
            },
            "reason": "XMage structure matches Smuggler's Share: each end step draw for opponents with two or more cards drawn this turn and create Treasure for opponents with two or more lands entering this turn.",
            "signals": [
                "BeginningOfEndStepTriggeredAbility(TargetController.EACH_PLAYER)",
                "CardsAmountDrawnThisTurnWatcher",
                "PermanentsEnteredBattlefieldWatcher",
                "DrawCardSourceControllerEffect(dynamic)",
                "CreateTokenEffect(TreasureToken dynamic)",
            ],
        }

    if (
        card_types == {"ARTIFACT", "CREATURE"}
        and xmage_class_name == "DavrosDalekCreator"
        and "BeginningOfEndStepTriggeredAbility" in ability_classes
        and {"CreateTokenEffect", "DavrosDalekCreatorEffect"}.issubset(effect_classes)
        and "PlayerLostLifeWatcher" in rules_text
        and "DalekToken" in rules_text
    ):
        return {
            "effect": "creature",
            "scope": "controller_end_step_opponent_lost_life_dalek_villainous_choice_v1",
            "fields": {
                "power": 3,
                "toughness": 4,
                "menace": True,
                "artifact_creature": True,
                "trigger": "controller_end_step",
                "controller_end_step_opponent_lost_life_dalek_villainous_choice": True,
                "opponent_life_lost_threshold": 3,
                "token_count": 1,
                "token_name": "Dalek Token",
                "token_subtype": "Dalek",
                "token_colors": ["B"],
                "token_power": 3,
                "token_toughness": 3,
                "artifact_tokens": True,
                "token_keywords": ["menace"],
                "villainous_choice_model": "opponent_discards_if_possible_else_controller_draws",
            },
            "reason": "XMage structure matches Davros, Dalek Creator: controller end-step trigger checks opponents that lost 3 or more life, creates a Dalek token, then applies villainous choice.",
            "signals": [
                "BeginningOfEndStepTriggeredAbility",
                "OpponentLostLifeCondition(>=3)",
                "PlayerLostLifeWatcher",
                "CreateTokenEffect(DalekToken)",
                "DavrosDalekCreatorEffect",
                "FaceVillainousChoice",
            ],
        }

    if (
        "ENCHANTMENT" in card_types
        and xmage_class_name == "FableOfTheMirrorBreaker"
        and {"SagaAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and {"CreateTokenEffect", "DiscardAndDrawThatManyEffect", "ExileSagaAndReturnTransformedEffect", "CreateTokenCopyTargetEffect"}.issubset(effect_classes)
        and "FableOfTheMirrorBreakerToken" in rules_text
        and "ReflectionOfKikiJikiEffect" in rules_text
    ):
        return {
            "effect": "token_maker",
            "scope": "saga_goblin_rummage_transform_reflection_copy_v1",
            "fields": {
                "saga_chapter_effects": {
                    "1": {
                        "effect": "token_maker",
                        "token_count": 1,
                        "token_name": "Goblin Shaman Token",
                        "token_subtype": "Goblin Shaman",
                        "token_colors": ["R"],
                        "token_power": 2,
                        "token_toughness": 2,
                        "token_attack_create_treasure": True,
                    },
                    "2": {"effect": "discard_draw", "max_discard": 2, "draw_equal_to_discarded": True},
                    "3": {"effect": "transform"},
                },
                "saga_final_chapter": 3,
                "transform_to": {
                    "name": "Reflection of Kiki-Jiki",
                    "effect": "creature",
                    "type_line": "Enchantment Creature - Goblin Shaman",
                    "power": 2,
                    "toughness": 2,
                    "activated_copy_target_another_nonlegendary_creature_you_control": True,
                    "activation_cost_generic": 1,
                    "activation_requires_tap": True,
                    "copy_target_types": ["creature"],
                    "target_controller": "own",
                    "exclude_source_from_copy_targets": True,
                    "exclude_legendary_copy_targets": True,
                    "token_haste": True,
                    "sacrifice_token_at_end_step": True,
                },
            },
            "reason": "XMage structure matches Fable of the Mirror-Breaker: Saga chapter I creates the Goblin Shaman token, chapter II discards up to two and draws that many, chapter III transforms into Reflection of Kiki-Jiki, whose activated ability copies another nonlegendary creature with haste and end-step sacrifice.",
            "signals": [
                "SagaAbility",
                "FableOfTheMirrorBreakerToken",
                "DiscardAndDrawThatManyEffect(2)",
                "ExileSagaAndReturnTransformedEffect",
                "ReflectionOfKikiJikiEffect",
                "CreateTokenCopyTargetEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "TheLocustGod"
        and "DrawCardControllerTriggeredAbility" in ability_classes
        and {"CreateTokenEffect", "DrawDiscardControllerEffect", "CreateDelayedTriggeredAbilityEffect"}.issubset(effect_classes)
        and "TheLocustGodInsectToken" in rules_text
    ):
        return {
            "effect": "creature",
            "scope": "controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1",
            "fields": {
                "power": 4,
                "toughness": 4,
                "flying": True,
                "controller_draw_create_token": True,
                "token_count_per_card_drawn": 1,
                "token_name": "Insect Token",
                "token_subtype": "Insect",
                "token_colors": ["U", "R"],
                "token_power": 1,
                "token_toughness": 1,
                "token_flying": True,
                "token_haste": True,
                "activated_loot": True,
                "activation_cost": "{2}{U}{R}",
                "dies_return_to_owner_hand_next_end_step": True,
            },
            "reason": "XMage structure matches The Locust God: controller draw trigger creates 1/1 blue-red Insect tokens with flying and haste, activated loot, and delayed death return to hand.",
            "signals": [
                "DrawCardControllerTriggeredAbility",
                "CreateTokenEffect(TheLocustGodInsectToken)",
                "SimpleActivatedAbility(DrawDiscardControllerEffect)",
                "DiesSourceTriggeredAbility",
                "AtTheBeginOfNextEndStepDelayedTriggeredAbility(ReturnToHandTargetEffect)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "Biotransference"
        and {"SimpleStaticAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
        and {"ModifyObjectAllMultiZoneEffect", "LoseLifeSourceControllerEffect", "CreateTokenEffect"}.issubset(effect_classes)
        and "NecronWarriorToken" in rules_text
    ):
        return {
            "effect": "token_maker",
            "scope": "controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1",
            "fields": {
                "trigger": "spell_cast",
                "trigger_effect": "token_maker",
                "trigger_artifact_spell": True,
                "controlled_creatures_and_creature_spells_are_artifacts": True,
                "controlled_creature_cards_owned_are_artifacts": True,
                "controller_loses_life_on_trigger": 1,
                "token_count": 1,
                "token_name": "Necron Warrior Token",
                "token_subtype": "Necron Warrior",
                "token_colors": ["B"],
                "token_power": 2,
                "token_toughness": 2,
                "artifact_tokens": True,
            },
            "reason": "XMage structure matches Biotransference: controlled creatures, creature spells, and owned creature cards become artifacts; whenever controller casts an artifact spell, they lose 1 life and create a 2/2 black Necron Warrior artifact creature token.",
            "signals": [
                "SimpleStaticAbility(BiotransferenceEffect)",
                "ModifyObjectAllMultiZoneEffect(add CardType.ARTIFACT)",
                "SpellCastControllerTriggeredAbility(FILTER_SPELL_AN_ARTIFACT)",
                "LoseLifeSourceControllerEffect(1)",
                "CreateTokenEffect(NecronWarriorToken)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "TaiiWakeenPerfectShot"
        and "DrawCardSourceControllerEffect" in effect_classes
        and "TaiiWakeenPerfectShotEffect" in effect_classes
        and {"TaiiWakeenPerfectShotTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and "TapSourceCost" in cost_classes
        and (
            "DAMAGED_PERMANENT" in rules_text
            or "deals noncombat damage to a creature equal to that creature's toughness" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1",
            "fields": {
                "power": 2,
                "toughness": 3,
                "trigger": "source_you_control_noncombat_damage_to_creature_equal_toughness",
                "noncombat_damage_to_creature_equal_toughness_draw": True,
                "noncombat_damage_equal_toughness_draw_count": 1,
                "activated_noncombat_damage_plus_x_until_eot": True,
                "activation_cost_x_generic": True,
                "activation_requires_tap": True,
                "damage_modifier_applies_to": "sources_you_control_noncombat_damage",
                "damage_modifier_duration": "until_end_of_turn",
            },
            "reason": "XMage structure matches Taii Wakeen, Perfect Shot: a 2/3 creature with a noncombat-damage-equals-toughness draw trigger and an X tap replacement effect that increases noncombat damage from sources you control until end of turn.",
            "signals": [
                "TriggeredAbilityImpl(DAMAGED_PERMANENT)",
                "DrawCardSourceControllerEffect(1)",
                "ReplacementEffectImpl(DAMAGE_PERMANENT/DAMAGE_PLAYER)",
                "SimpleActivatedAbility(ManaCostsImpl({X}))",
                "TapSourceCost",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "SqueeGoblinNabob"
        and "ReturnSourceFromGraveyardToHandEffect" in effect_classes
        and "BeginningOfUpkeepTriggeredAbility" in ability_classes
        and (
            "Zone.GRAVEYARD" in rules_text
            or "zone.graveyard" in normalized
            or _oracle_has(rules_text, "beginning of your upkeep", "graveyard", "return", "hand")
        )
    ):
        return {
            "effect": "creature",
            "scope": "graveyard_upkeep_return_self_to_hand_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "legendary": True,
                "graveyard_upkeep_return_self_to_hand": True,
                "graveyard_upkeep_optional": True,
                "graveyard_upkeep_trigger_zone": "graveyard",
                "graveyard_upkeep_trigger_controller": "source_controller",
            },
            "reason": "XMage structure matches Squee, Goblin Nabob: a 1/1 legendary creature with an optional beginning-of-your-upkeep trigger from graveyard returning itself to hand.",
            "signals": [
                "BeginningOfUpkeepTriggeredAbility(Zone.GRAVEYARD)",
                "TargetController.YOU",
                "ReturnSourceFromGraveyardToHandEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "GlintHornBuccaneer"
        and {"DamagePlayersEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and "ActivateIfConditionActivatedAbility" in ability_classes
        and "DiscardCardCost" in cost_classes
        and (
            "SourceAttackingCondition" in rules_text
            or "sourceattackingcondition" in normalized
            or _oracle_has(rules_text, "activate only if", "attacking")
        )
        and (
            _oracle_has(rules_text, "whenever you discard a card", "deals 1 damage to each opponent")
            or (
                re.search(r"damageplayerseffect\(1,\s*targetcontroller\.opponent\)", normalized)
                and "gameevent.eventtype.discarded_card" in normalized
            )
        )
    ):
        return {
            "effect": "creature",
            "scope": "glint_horn_buccaneer_discard_damage_attack_loot_v1",
            "fields": {
                "power": 2,
                "toughness": 4,
                "haste": True,
                "trigger": "controller_discard",
                "controller_discard_damage_each_opponent": 1,
                "attacking_activated_discard_draw": True,
                "attacking_activated_discard_draw_cost": "{1}{R}",
                "attacking_activated_discard_count": 1,
                "attacking_activated_draw_count": 1,
            },
            "reason": "XMage structure matches Glint-Horn Buccaneer: a 2/4 haste creature with a controller-discard damage trigger and an attack-only {1}{R}, discard-a-card draw activation.",
            "signals": [
                "HasteAbility",
                "DamagePlayersEffect(TargetController.OPPONENT)",
                "DISCARDED_CARD controller trigger",
                "ActivateIfConditionActivatedAbility",
                "SourceAttackingCondition",
                "DiscardCardCost",
                "DrawCardSourceControllerEffect(1)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "MagmakinArtillerist"
        and "DamagePlayersEffect" in effect_classes
        and {"DiscardOneOrMoreCardsTriggeredAbility", "CycleTriggeredAbility", "CyclingAbility"}.issubset(
            ability_classes
        )
        and (
            _oracle_has(rules_text, "whenever you discard one or more cards", "deals that much damage to each opponent")
            or (
                re.search(r"damageplayerseffect\(saveddiscardvalue\.much,\s*targetcontroller\.opponent\)", normalized)
                and "discardoneormorecardstriggeredability" in normalized
            )
        )
        and (
            _oracle_has(rules_text, "when you cycle this card", "deals 1 damage to each opponent")
            or "cycletriggeredability" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "controller_discards_one_or_more_damage_each_opponent_cycling_ping_annotation_v1",
            "fields": {
                "power": 1,
                "toughness": 4,
                "trigger": "controller_discard",
                "controller_discard_damage_each_opponent": 1,
                "controller_discard_count_mode": "discarded_cards",
                "cycling_cost": "{1}{R}",
                "cycling_status": "annotation_only",
                "cycle_trigger_damage_each_opponent": 1,
                "cycle_trigger_status": "annotation_only",
            },
            "reason": "XMage structure matches Magmakin Artillerist: a 1/4 creature that deals damage to each opponent equal to the number of cards you discarded, plus cycling and a cycling-trigger ping rider that ManaLoom preserves as annotation for now.",
            "signals": [
                "DiscardOneOrMoreCardsTriggeredAbility",
                "DamagePlayersEffect(SavedDiscardValue.MUCH, TargetController.OPPONENT)",
                "CyclingAbility({1}{R})",
                "CycleTriggeredAbility",
                "DamagePlayersEffect(1, TargetController.OPPONENT, it)",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "YoungPyromancer"
        and "CreateTokenEffect" in effect_classes
        and "SpellCastControllerTriggeredAbility" in ability_classes
        and (
            "RedElementalToken" in rules_text
            or "redelementaltoken" in normalized
            or _oracle_has(rules_text, "instant or sorcery", "1/1 red elemental")
        )
    ):
        return {
            "effect": "token_maker",
            "scope": "instant_sorcery_cast_create_1_1_red_elemental_v1",
            "fields": {
                "power": 2,
                "toughness": 1,
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "token_maker",
                "trigger_token_count": 1,
                "token_count": 1,
                "token_name": "Elemental Token",
                "token_subtype": "Elemental",
                "token_colors": ["R"],
                "token_power": 1,
                "token_toughness": 1,
            },
            "reason": "XMage structure matches Young Pyromancer: a 2/1 creature whose controller's instant-or-sorcery casts create one 1/1 red Elemental creature token.",
            "signals": [
                "SpellCastControllerTriggeredAbility",
                "CreateTokenEffect",
                "RedElementalToken",
                "FILTER_SPELL_AN_INSTANT_OR_SORCERY",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "MonasteryMentor"
        and "CreateTokenEffect" in effect_classes
        and "SpellCastControllerTriggeredAbility" in ability_classes
        and (
            "MonasteryMentorToken" in rules_text
            or "monasterymentortoken" in normalized
            or _oracle_has(rules_text, "noncreature spell", "1/1 white monk", "prowess")
        )
    ):
        return {
            "effect": "token_maker",
            "scope": "noncreature_spell_cast_create_1_1_white_monk_prowess_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "prowess": True,
                "trigger": "noncreature_spell_cast",
                "trigger_effect": "token_maker",
                "trigger_token_count": 1,
                "token_count": 1,
                "token_name": "Monk Token",
                "token_subtype": "Monk",
                "token_colors": ["W"],
                "token_power": 1,
                "token_toughness": 1,
                "token_keywords": ["prowess"],
                "token_prowess": True,
            },
            "reason": "XMage structure matches Monastery Mentor: a 2/2 prowess creature whose controller's noncreature spells create one 1/1 white Monk creature token with prowess.",
            "signals": [
                "SpellCastControllerTriggeredAbility",
                "CreateTokenEffect",
                "MonasteryMentorToken",
                "FILTER_SPELL_A_NON_CREATURE",
                "ProwessAbility",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "UtvaraHellkite"
        and "CreateTokenEffect" in effect_classes
        and "AttacksCreatureYouControlTriggeredAbility" in ability_classes
        and (
            "UtvaraHellkiteDragonToken" in rules_text
            or "utvarahellkitedragontoken" in normalized
            or _oracle_has(rules_text, "dragon you control attacks", "6/6 red dragon", "flying")
        )
    ):
        return {
            "effect": "token_maker",
            "scope": "dragon_you_control_attacks_create_6_6_red_flying_dragon_v1",
            "fields": {
                "power": 6,
                "toughness": 6,
                "flying": True,
                "trigger": "dragon_you_control_attacks",
                "trigger_effect": "token_maker",
                "trigger_token_count": 1,
                "trigger_attacking_creature_subtype": "Dragon",
                "token_count": 1,
                "token_name": "Dragon Token",
                "token_subtype": "Dragon",
                "token_colors": ["R"],
                "token_power": 6,
                "token_toughness": 6,
                "token_flying": True,
                "token_keywords": ["flying"],
            },
            "reason": "XMage structure matches Utvara Hellkite: a 6/6 flying Dragon whose controller creates one 6/6 red flying Dragon token whenever a Dragon they control attacks.",
            "signals": [
                "AttacksCreatureYouControlTriggeredAbility",
                "CreateTokenEffect",
                "UtvaraHellkiteDragonToken",
                "FilterControlledCreaturePermanent(SubType.DRAGON)",
                "FlyingAbility",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and xmage_class_name == "BlazeCommando"
        and "CreateTokenEffect" in effect_classes
        and "SpellControlledDealsDamageTriggeredAbility" in ability_classes
        and (
            "SoldierHasteToken" in rules_text
            or "soldierhastetoken" in normalized
            or _oracle_has(rules_text, "instant or sorcery spell you control deals damage", "two 1/1", "red and white soldier", "haste")
        )
    ):
        return {
            "effect": "token_maker",
            "scope": "instant_sorcery_spell_damage_create_two_1_1_red_white_soldier_haste_v1",
            "fields": {
                "power": 5,
                "toughness": 3,
                "trigger": "instant_sorcery_spell_you_control_deals_damage",
                "trigger_effect": "token_maker",
                "trigger_token_count": 2,
                "token_count": 2,
                "token_name": "Soldier Token",
                "token_subtype": "Soldier",
                "token_colors": ["R", "W"],
                "token_power": 1,
                "token_toughness": 1,
                "token_haste": True,
                "token_keywords": ["haste"],
            },
            "reason": "XMage structure matches Blaze Commando: a 5/3 creature whose controller creates two 1/1 red and white hasty Soldier tokens whenever an instant or sorcery spell they control deals damage.",
            "signals": [
                "SpellControlledDealsDamageTriggeredAbility",
                "CreateTokenEffect",
                "SoldierHasteToken",
                "FILTER_SPELL_INSTANT_OR_SORCERY",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and xmage_class_name == "InvokeCalamity"
        and {
            "ExileSpellEffect",
            "InvokeCalamityEffect",
            "InvokeCalamityReplacementEffect",
            "OneShotEffect",
        }.issubset(effect_classes)
        and not ability_classes
        and not target_classes
        and not cost_classes
        and "castmultiplewithattributeforfree" in normalized
        and "filter_card_instant_or_sorcery" in normalized
        and "up to two instant and/or sorcery spells" in normalized
        and "total mana value 6 or less" in normalized
        and "from your graveyard and/or hand" in normalized
        and "without paying their mana costs" in normalized
        and "exile them instead" in normalized
        and "new exilespelleffect" in normalized
    ):
        return {
            "effect": "free_cast",
            "scope": "cast_up_to_two_instant_sorcery_hand_graveyard_total_mv_lte_6_exile_replacement_v1",
            "fields": {
                "instant": True,
                "free_cast_from_zones": ["hand", "graveyard"],
                "free_cast_card_types": ["instant", "sorcery"],
                "free_cast_max_count": 2,
                "free_cast_total_mana_value_max": 6,
                "cast_without_paying_mana_cost": True,
                "selected_spells_exile_instead_of_graveyard": True,
                "exiles_self": True,
            },
            "reason": "XMage structure matches Invoke Calamity: cast up to two instant/sorcery cards from hand and/or graveyard for free with combined mana value 6 or less, then exile those spells instead of returning them to graveyard.",
            "signals": [
                "InvokeCalamityEffect",
                "InvokeCalamityTracker",
                "castMultipleWithAttributeForFree",
                "FILTER_CARD_INSTANT_OR_SORCERY",
                "totalManaValue <= 6",
                "InvokeCalamityReplacementEffect",
                "ExileSpellEffect",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and xmage_class_name == "CoolButRude"
        and {
            "DamagePlayersEffect",
            "DiscardControllerEffect",
            "DrawCardSourceControllerEffect",
            "GainClassAbilitySourceEffect",
            "SearchLibraryPutInHandEffect",
        }.issubset(effect_classes)
        and "doifcostpaid" in normalized
        and {
            "AttacksWithCreaturesTriggeredAbility",
            "BecomesClassLevelTriggeredAbility",
            "ClassLevelAbility",
            "ClassReminderAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and "DiscardCardCost" in cost_classes
    ):
        return {
            "effect": "draw_engine",
            "scope": "cool_but_rude_class_attack_rummage_level_damage_tutor_v1",
            "fields": {
                "draw_on_enter": False,
                "class_level_start": 1,
                "class_level_costs": {"2": "{1}{R}", "3": "{1}{R}"},
                "attack_trigger_optional_discard_draw": True,
                "trigger": "controller_discard",
                "controller_discard_damage_each_opponent": 2,
                "controller_discard_damage_each_opponent_level_min": 2,
                "class_level3_tutor_any_to_hand_random_discard": True,
            },
            "reason": "XMage structure matches Cool but Rude as a Class with attack rummage, a level-2 controller-discard damage trigger, and a level-3 tutor followed by random discard.",
            "signals": [
                "AttacksWithCreaturesTriggeredAbility",
                "DoIfCostPaid",
                "DiscardCardCost",
                "ClassLevelAbility",
                "GainClassAbilitySourceEffect",
                "DamagePlayersEffect",
                "BecomesClassLevelTriggeredAbility",
                "SearchLibraryPutInHandEffect",
                "DiscardControllerEffect(random)",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and effect_classes == {"OneShotEffect", "RhysticStudyDrawEffect"}
        and ability_classes == {"SpellCastOpponentTriggeredAbility"}
        and (
            xmage_class_name == "RhysticStudy"
            or _oracle_has(rules_text, "unless that player pays {1}")
        )
    ):
        return {
            "effect": "draw_engine",
            "scope": "opponent_spell_pay_one_or_draw_engine_v1",
            "fields": {
                "trigger": "opponent_spell",
                "tax": 1,
                "draw_on_enter": False,
            },
            "reason": "XMage structure matches Rhystic Study triggering on each opponent spell and drawing unless that player pays {1}.",
            "signals": [
                "SpellCastOpponentTriggeredAbility",
                "RhysticStudyDrawEffect",
                "unless_that_player_pays_1",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and effect_classes == {"MysticRemoraEffect", "OneShotEffect"}
        and {"CumulativeUpkeepAbility", "MysticRemoraTriggeredAbility"}.issubset(ability_classes)
        and (
            xmage_class_name == "MysticRemora"
            or (
                "!spell.iscreature(game)" in normalized
                and _oracle_has(rules_text, "pay {4}", "cumulativeupkeepability")
            )
        )
    ):
        return {
            "effect": "draw_engine",
            "scope": "opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1",
            "fields": {
                "trigger": "opponent_noncreature_spell",
                "tax": 4,
                "draw_on_enter": False,
                "cumulative_upkeep_generic": 1,
            },
            "reason": "XMage structure matches Mystic Remora's cumulative upkeep and the opponent noncreature-spell draw trigger unless that player pays {4}.",
            "signals": [
                "MysticRemoraTriggeredAbility",
                "CumulativeUpkeepAbility",
                "noncreature_spell_tax_draw",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and not ability_classes
        and cost_classes == {"SacrificeTargetCost"}
        and (
            xmage_class_name == "CropRotation"
            or ("filterlandcard" in normalized and "sacrificetargetcost(staticfilters.filter_land)" in normalized)
        )
    ):
        return {
            "effect": "land_ramp",
            "scope": "sacrifice_land_for_any_land_to_battlefield_untapped_v1",
            "fields": {
                "instant": True,
                "requires_sacrifice_land": True,
                "land_count": 1,
                "lands_to_battlefield": 1,
                "land_enters_tapped": False,
                "tutor_target": "land",
            },
            "reason": "XMage structure matches Crop Rotation sacrificing a land to tutor any land directly onto the battlefield untapped.",
            "signals": [
                "SearchLibraryPutInPlayEffect",
                "SacrificeTargetCost",
                "FilterLandCard",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and {
            "BoostSourceEffect",
            "ConditionalContinuousEffect",
            "SearchLibraryPutInPlayEffect",
        }.issubset(effect_classes)
        and {"SimpleActivatedAbility", "SimpleStaticAbility"}.issubset(ability_classes)
        and {"GenericManaCost", "SacrificeTargetCost", "TapSourceCost"}.issubset(cost_classes)
        and (
            xmage_class_name == "ElvishReclaimer"
            or (
                "cardsincontrollergraveyardcondition(3" in normalized
                and "searchlibraryputinplayeffect" in normalized
                and "staticfilters.filter_card_land_a" in normalized
            )
        )
    ):
        return {
            "effect": "creature",
            "scope": "activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1",
            "fields": {
                "power": 1,
                "toughness": 2,
                "land_tutor_activated": True,
                "activation_cost_generic": 2,
                "activation_requires_tap": True,
                "requires_sacrifice_land": True,
                "land_count": 1,
                "lands_to_battlefield": 1,
                "land_enters_tapped": True,
                "tutor_target": "land",
                "plus_two_two_if_three_lands_in_your_graveyard": True,
            },
            "reason": "XMage structure matches Elvish Reclaimer's static +2/+2 growth with three lands in graveyard and the activated land-sacrifice tutor that puts a land onto the battlefield tapped.",
            "signals": [
                "ConditionalContinuousEffect",
                "BoostSourceEffect",
                "SearchLibraryPutInPlayEffect",
                "CardsInControllerGraveyardCondition(3)",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and {"CastAsThoughItHadFlashAllEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
    ):
        return {
            "effect": "draw_cards",
            "scope": "draw_one_and_source_controller_spells_gain_flash_until_eot_v1",
            "fields": {
                "count": 1,
                "instant": True,
                "source_controller_spells_have_flash_until_eot": True,
            },
            "reason": "XMage structure matches Borne Upon a Wind drawing one card and allowing the controller to cast spells as though they had flash this turn.",
            "signals": [
                "CastAsThoughItHadFlashAllEffect",
                "DrawCardSourceControllerEffect",
            ],
        }

    if (
        "DamageTargetEffect" in effect_classes
        and "DrawCardOpponentTriggeredAbility" in ability_classes
        and card_types in ({"ENCHANTMENT"}, {"ENCHANTMENT", "CREATURE"})
        and (
            xmage_class_name in {"FateUnraveler", "UnderworldDreams"}
            or _oracle_has(
                rules_text,
                "whenever an opponent draws a card",
                "deals 1 damage to that player",
            )
        )
    ):
        damage_per_card = _first_int(r"DamageTargetEffect\((\d+)\)", rules_text) or 1
        if "CREATURE" in card_types:
            return {
                "effect": "creature",
                "scope": "opponent_draws_card_damage_that_player_v1",
                "fields": {
                    "trigger": "opponent_draw",
                    "opponent_draw_damage_per_card": damage_per_card,
                    "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 3,
                    "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 4,
                },
                "reason": "XMage structure matches a creature that damages the drawing opponent whenever that opponent draws a card.",
                "signals": [
                    "DrawCardOpponentTriggeredAbility",
                    "DamageTargetEffect",
                    "opponent_draw_damage",
                ],
            }
        return {
            "effect": "passive",
            "scope": "opponent_draws_card_damage_that_player_v1",
            "fields": {
                "trigger": "opponent_draw",
                "opponent_draw_damage_per_card": damage_per_card,
            },
            "reason": "XMage structure matches an enchantment that damages the drawing opponent whenever that opponent draws a card.",
            "signals": [
                "DrawCardOpponentTriggeredAbility",
                "DamageTargetEffect",
                "opponent_draw_damage",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"AddCountersSourceEffect", "DamageTargetEffect"}
        and {"FlyingAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
        and "TargetOpponent" in target_classes
        and (
            xmage_class_name == "CalderaPyremaw"
            or _oracle_has(
                rules_text,
                "whenever you cast an instant or sorcery spell",
                "put a +1/+1 counter on this creature",
                "deals damage equal to its power to target opponent",
            )
        )
    ):
        return {
            "effect": "creature",
            "scope": "instant_sorcery_cast_add_counter_then_power_damage_target_opponent_v1",
            "fields": {
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 3,
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 3,
                "flying": True,
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "source_counter_then_power_damage",
                "trigger_add_plus_one_counter": 1,
                "trigger_damage_amount_source": "source_power_after_counter",
                "target": "opponent",
            },
            "reason": "XMage structure matches a flying creature that gets a +1/+1 counter whenever its controller casts an instant or sorcery, then deals damage equal to its post-counter power to target opponent.",
            "signals": [
                "SpellCastControllerTriggeredAbility",
                "AddCountersSourceEffect",
                "DamageTargetEffect",
                "TargetOpponent",
            ],
        }

    if (
        card_types == {"ARTIFACT"}
        and effect_classes == {"DrawCardSourceControllerEffect"}
        and ability_classes == {"DiscardsACardOpponentTriggeredAbility"}
        and (
            xmage_class_name == "GethsGrimoire"
            or _oracle_has(rules_text, "whenever an opponent discards a card", "you may draw a card")
        )
    ):
        return {
            "effect": "draw_engine",
            "scope": "opponent_discards_card_may_draw_v1",
            "fields": {
                "draw_on_enter": False,
                "trigger": "opponent_discard",
                "opponent_discard_draw_per_card": 1,
            },
            "reason": "XMage structure matches an artifact that lets you draw whenever an opponent discards a card.",
            "signals": [
                "DiscardsACardOpponentTriggeredAbility",
                "DrawCardSourceControllerEffect",
                "opponent_discard_draw",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and effect_classes == {"DamageTargetEffect"}
        and ability_classes == {"DiscardsACardOpponentTriggeredAbility"}
        and (
            xmage_class_name == "Megrim"
            or _oracle_has(rules_text, "whenever an opponent discards a card", "deals 2 damage to that player")
        )
    ):
        return {
            "effect": "passive",
            "scope": "opponent_discards_card_damage_that_player_v1",
            "fields": {
                "trigger": "opponent_discard",
                "opponent_discard_damage_per_card": 2,
            },
            "reason": "XMage structure matches an enchantment that damages the discarding opponent whenever that opponent discards a card.",
            "signals": [
                "DiscardsACardOpponentTriggeredAbility",
                "DamageTargetEffect",
                "opponent_discard_damage",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and {"DamageTargetEffect", "GainLifeEffect"}.issubset(effect_classes)
        and ability_classes == {"DiscardCardControllerTriggeredAbility"}
        and (
            xmage_class_name == "FeastOfSanity"
            or _oracle_has(
                rules_text,
                "whenever you discard a card",
                "deals 1 damage to any target",
                "gain 1 life",
            )
        )
    ):
        return {
            "effect": "passive",
            "scope": "controller_discards_card_damage_any_target_and_gain_life_v1",
            "fields": {
                "trigger": "controller_discard",
                "controller_discard_damage_any_target": 1,
                "controller_discard_gain_life": 1,
            },
            "reason": "XMage structure matches an enchantment that pings any target and gains life whenever you discard a card.",
            "signals": [
                "DiscardCardControllerTriggeredAbility",
                "DamageTargetEffect",
                "GainLifeEffect",
                "controller_discard_damage_and_life",
            ],
        }

    if (
        card_types.issubset({"INSTANT", "SORCERY"})
        and card_types
        and effect_classes == {"DamageTargetEffect", "GainLifeEffect"}
        and not ability_classes
        and "TargetAnyTarget" in target_classes
        and (
            xmage_class_name == "LightningHelix"
            or _oracle_has(rules_text, "deals 3 damage to any target", "gain 3 life")
        )
    ):
        damage = _first_int(r"DamageTargetEffect\((\d+)\)", rules_text) or 3
        life_gain = _first_int(r"GainLifeEffect\((\d+)\)", rules_text) or damage
        return {
            "effect": "direct_damage",
            "scope": "damage_any_target_and_gain_life_v1",
            "fields": {
                "damage": damage,
                "gain_life": life_gain,
                "target": "any_target",
                "instant": "INSTANT" in card_types,
            },
            "reason": "XMage structure matches an instant or sorcery that deals damage to any target and gains life for its controller.",
            "signals": [
                "DamageTargetEffect",
                "GainLifeEffect",
                "TargetAnyTarget",
            ],
        }

    if (
        xmage_class_name == "TerrorOfThePeaks"
        and card_types == {"CREATURE"}
        and {"DamageTargetEffect", "TerrorOfThePeaksCostIncreaseEffect"}.issubset(effect_classes)
        and {
            "EntersBattlefieldControlledTriggeredAbility",
            "FlyingAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and "TargetAnyTarget" in target_classes
        and (
            "terrorofthepeaksvalue" in _normalized_rules_text(rules_text)
            or _oracle_has(
                rules_text,
                "whenever another creature you control enters",
                "deals damage equal to that creature's power to any target",
            )
        )
    ):
        return {
            "effect": "creature",
            "scope": "controlled_other_creature_enters_power_damage_any_target_v1",
            "fields": {
                "trigger": "creature_you_control_enters",
                "trigger_effect": "damage_any_target",
                "trigger_damage_amount_source": "entering_creature_power",
                "trigger_another_creature_you_control_enters": True,
                "target": "any_target",
                "target_constraints": {"scope": "any_target"},
                "opponent_spells_targeting_this_additional_life_cost": 3,
                "flying": True,
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 5,
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 4,
            },
            "reason": (
                "XMage structure matches Terror of the Peaks: another controlled creature entering "
                "triggers damage equal to that creature's power to any target."
            ),
            "signals": [
                "EntersBattlefieldControlledTriggeredAbility",
                "DamageTargetEffect",
                "TerrorOfThePeaksValue",
                "TargetAnyTarget",
            ],
        }

    if (
        xmage_class_name == "FiresongAndSunspeaker"
        and card_types == {"CREATURE"}
        and {"DamageTargetEffect", "GainAbilityControlledSpellsEffect"}.issubset(effect_classes)
        and {
            "FiresongAndSunspeakerTriggeredAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and "TargetCreatureOrPlayer" in target_classes
    ):
        return {
            "effect": "creature",
            "scope": "red_instant_sorcery_lifelink_white_lifegain_damage_v1",
            "fields": {
                "instant_sorcery_spells_you_control_have_lifelink": True,
                "instant_sorcery_lifelink_colors": ["R"],
                "trigger": "white_instant_sorcery_lifegain",
                "trigger_effect": "damage_any_target",
                "white_instant_sorcery_lifegain_trigger_damage": 3,
                "target": "any_target",
                "target_constraints": {"scope": "any_target"},
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 4,
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 6,
            },
            "reason": (
                "XMage structure matches Firesong and Sunspeaker: red instant/sorcery spells "
                "you control gain lifelink and white instant/sorcery lifegain triggers 3 damage."
            ),
            "signals": [
                "GainAbilityControlledSpellsEffect",
                "LifelinkAbility",
                "FiresongAndSunspeakerTriggeredAbility",
                "DamageTargetEffect",
                "TargetCreatureOrPlayer",
            ],
        }

    if (
        xmage_class_name == "BalefireLiege"
        and card_types == {"CREATURE"}
        and {"BoostControlledEffect", "DamageTargetEffect", "GainLifeEffect"}.issubset(effect_classes)
        and {"SimpleStaticAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
        and "TargetPlayerOrPlaneswalker" in target_classes
    ):
        return {
            "effect": "creature",
            "scope": "red_spell_damage_white_spell_lifegain_static_creature_boost_v1",
            "fields": {
                "trigger": "spell_cast",
                "trigger_effect": "spell_color_damage_life",
                "red_spell_trigger_damage": 3,
                "red_spell_trigger_damage_target": "player_or_planeswalker",
                "white_spell_trigger_gain_life": 3,
                "static_boost_other_red_creatures_you_control": {"power": 1, "toughness": 1},
                "static_boost_other_white_creatures_you_control": {"power": 1, "toughness": 1},
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 2,
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 4,
            },
            "reason": (
                "XMage structure matches Balefire Liege: red spells trigger 3 damage to "
                "a player or planeswalker, white spells trigger 3 life, and static boosts "
                "annotate other red/white creatures you control."
            ),
            "signals": [
                "BoostControlledEffect",
                "SpellCastControllerTriggeredAbility",
                "DamageTargetEffect",
                "GainLifeEffect",
                "TargetPlayerOrPlaneswalker",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and effect_classes == {"DamageTargetEffect"}
        and ability_classes == {"SimpleActivatedAbility"}
        and "SacrificeTargetCost" in cost_classes
    ):
        return {
            "effect": "direct_damage",
            "scope": "activated_sacrifice_creature_deal_one_any_target_v1",
            "fields": {
                "activation_cost": "sacrifice_creature",
                "damage": 1,
                "target": "any_target",
            },
            "reason": "XMage structure matches Goblin Bombardment sacrificing a creature to deal 1 damage to any target.",
            "signals": [
                "DamageTargetEffect",
                "SacrificeTargetCost",
                "TargetAnyTarget",
            ],
        }

    if (
        card_types == {"ARTIFACT"}
        and {
            "AddCountersTargetEffect",
            "AgathasSoulCauldronAbilityEffect",
            "AgathasSoulCauldronExileEffect",
            "AgathasSoulCauldronManaEffect",
            "AsThoughManaEffect",
            "OneShotEffect",
        }.issubset(effect_classes)
        and {"SimpleActivatedAbility", "SimpleStaticAbility", "ReflexiveTriggeredAbility"}.issubset(ability_classes)
        and "TapSourceCost" in cost_classes
    ):
        return {
            "effect": "passive",
            "scope": "graveyard_exile_counter_and_ability_grant_artifact_v1",
            "fields": {
                "mana_as_any_color_for_creature_activations": True,
                "plus_one_counter_creatures_gain_activated_abilities_of_exiled_creatures": True,
                "activated_tap_exile_target_card_from_graveyard": True,
                "creature_exile_reflexive_plus_one_counter": True,
            },
            "reason": "XMage structure matches Agatha's Soul Cauldron mana-as-any-color activation support, the static activated-ability grant from exiled creatures, and the tap exile plus +1/+1 counter reflexive mode.",
            "signals": [
                "AgathasSoulCauldronManaEffect",
                "AgathasSoulCauldronAbilityEffect",
                "AgathasSoulCauldronExileEffect",
                "AddCountersTargetEffect",
            ],
        }

    if (
        card_types == {"ENCHANTMENT"}
        and {
            "ExileTargetEffect",
            "NecropotenceEffect",
            "OneShotEffect",
            "ReturnToHandTargetEffect",
            "SkipDrawStepEffect",
        }.issubset(effect_classes)
        and {
            "AtTheBeginOfNextEndStepDelayedTriggeredAbility",
            "NecropotenceTriggeredAbility",
            "SimpleActivatedAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and "PayLifeCost" in cost_classes
    ):
        return {
            "effect": "draw_engine",
            "scope": "skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1",
            "fields": {
                "skip_draw_step": True,
                "discard_trigger_exiles_discarded_card_from_graveyard": True,
                "activated_pay_life": 1,
                "activated_exile_top_card_face_down": True,
                "activated_put_exiled_card_into_hand_next_end_step": True,
            },
            "reason": "XMage structure matches Necropotence's skipped draw step, discard-to-exile trigger, and the pay-1-life face-down exile line that returns the card at the next end step.",
            "signals": [
                "SkipDrawStepEffect",
                "NecropotenceTriggeredAbility",
                "NecropotenceEffect",
                "ReturnToHandTargetEffect",
            ],
        }

    if (
        card_types == {"ARTIFACT"}
        and {"ExileTargetEffect", "DrawCardSourceControllerEffect", "OneShotEffect"}.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
        and "GenericManaCost" in cost_classes
    ):
        return {
            "effect": "artifact",
            "scope": "etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1",
            "fields": {
                "etb_exile_target_card_from_graveyard": True,
                "activated_tap_sacrifice_exile_each_opponents_graveyard": True,
                "activated_generic_one_tap_sacrifice_draw": 1,
            },
            "reason": "XMage structure matches Soul-Guide Lantern ETB graveyard pickoff plus sacrifice modes for mass graveyard exile or card draw.",
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "ExileTargetEffect",
                "DrawCardSourceControllerEffect",
                "SoulGuideLanternEffect",
            ],
        }

    if (
        card_types == {"ARTIFACT"}
        and {"CounterTargetEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and {"SpellCastAllTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
        and {"GenericManaCost", "TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
    ):
        return {
            "effect": "artifact",
            "scope": "counter_no_mana_spent_spells_and_cantrip_sacrifice_v1",
            "fields": {
                "trigger_counter_spell_if_no_mana_was_spent": True,
                "activated_generic_one_tap_sacrifice_draw": 1,
            },
            "reason": "XMage structure matches Vexing Bauble countering spells cast without mana spent plus the one-mana tap-sacrifice cantrip mode.",
            "signals": [
                "SpellCastAllTriggeredAbility",
                "CounterTargetEffect",
                "DrawCardSourceControllerEffect",
            ],
        }

    untap_cost = None
    untap_match = re.search(
        r"new\s+simpleactivatedability\s*\(\s*new\s+untapsourceeffect\s*\(\s*\)\s*,\s*new\s+genericmanacost\s*\(\s*(\d+)\s*\)\s*\)",
        normalized,
    )
    if untap_match:
        untap_cost = int(untap_match.group(1))
    else:
        untap_match = re.search(
            r"new\s+simpleactivatedability\s*\(\s*new\s+untapsourceeffect\s*\(\s*\)\s*,\s*new\s+manacostsimpl\s*<>\s*\(\s*\{(\d+)\}\s*\)\s*\)",
            normalized,
        )
        if untap_match:
            untap_cost = int(untap_match.group(1))

    if (
        card_types == {"ARTIFACT"}
        and {"DontUntapInControllersUntapStepSourceEffect", "UntapSourceEffect"}.issubset(effect_classes)
        and {"SimpleActivatedAbility", "SimpleManaAbility", "SimpleStaticAbility"}.issubset(ability_classes)
        and untap_cost in {3, 4}
        and "mana.colorlessmana(3)" in normalized
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "three_colorless_monolith_mana_rock_v1",
            "fields": {
                "mana_produced": 3,
                "produces": "C",
                "does_not_untap_in_untap_step": True,
                "activated_untap_cost_generic": untap_cost,
            },
            "reason": "XMage structure matches a Monolith-style mana rock that taps for {C}{C}{C}, does not untap during its controller's untap step, and has a paid untap activation.",
            "signals": [
                "SimpleManaAbility",
                "DontUntapInControllersUntapStepSourceEffect",
                "UntapSourceEffect",
                f"untap_cost_{untap_cost}",
            ],
        }

    if (
        xmage_class_name == "PyromancerAscension"
        or (
            card_types == {"ENCHANTMENT"}
            and {"AddCountersSourceEffect", "CopyTargetStackObjectEffect"}.issubset(effect_classes)
            and {
                "PyromancerAscensionQuestTriggeredAbility",
                "PyromancerAscensionCopyTriggeredAbility",
            }.issubset(ability_classes)
            and "two or more quest counters" in normalized
            and "you may copy that spell" in normalized
        )
    ):
        return {
            "effect": "copy_spell",
            "scope": "pyromancer_ascension_quest_counter_copy_spell_v1",
            "fields": {
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "pyromancer_ascension",
                "target": "own_instant_or_sorcery_on_stack",
                "may_choose_new_targets": True,
                "choose_new_targets_status": "may",
                "quest_counter_on_same_name_in_graveyard": True,
                "quest_counter_name_match_zone": "graveyard",
                "quest_counter_threshold_to_copy": 2,
            },
            "reason": "XMage structure matches Pyromancer Ascension adding quest counters for same-name graveyard spells and copying instant or sorcery spells only while it already has at least two quest counters.",
            "signals": [
                "PyromancerAscensionQuestTriggeredAbility",
                "PyromancerAscensionCopyTriggeredAbility",
                "AddCountersSourceEffect",
                "CopyTargetStackObjectEffect",
                "quest_counter_threshold_2",
            ],
        }

    if (
        xmage_class_name == "ProfoundJourney"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"ReturnFromGraveyardToBattlefieldTargetEffect"}
            and ability_classes == {"ReboundAbility"}
            and "TargetCardInYourGraveyard" in target_classes
            and (
                "filterpermanentcard" in normalized
                or "permanent card from your graveyard" in normalized
            )
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_target_permanent_from_graveyard_to_battlefield_rebound_v1",
            "fields": {
                "target": "permanent",
                "target_zone": "graveyard",
                "target_controller": "self",
                "destination": "battlefield",
                "count": 1,
                "rebound": True,
            },
            "reason": "XMage structure matches Profound Journey returning one target permanent card from your graveyard to the battlefield and exiling itself for rebound.",
            "signals": [
                "ReturnFromGraveyardToBattlefieldTargetEffect",
                "TargetCardInYourGraveyard",
                "FilterPermanentCard",
                "ReboundAbility",
            ],
        }

    if (
        xmage_class_name == "RedressFate"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}
            and ability_classes == {"MiracleAbility"}
            and "FilterArtifactOrEnchantmentCard" in filter_classes
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1",
            "fields": {
                "target": "artifact_or_enchantment",
                "target_zone": "graveyard",
                "target_controller": "self",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact", "enchantment"],
                "miracle": True,
                "miracle_cost": "{3}{W}",
            },
            "reason": "XMage structure matches Redress Fate returning all artifact and enchantment cards from your graveyard to the battlefield with miracle {3}{W}.",
            "signals": [
                "ReturnFromYourGraveyardToBattlefieldAllEffect",
                "FilterArtifactOrEnchantmentCard",
                "MiracleAbility",
            ],
        }

    if (
        xmage_class_name == "BrilliantRestoration"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}
            and not ability_classes
            and "FilterArtifactOrEnchantmentCard" in filter_classes
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1",
            "fields": {
                "target": "artifact_or_enchantment",
                "target_zone": "graveyard",
                "target_controller": "self",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact", "enchantment"],
            },
            "reason": "XMage structure matches Brilliant Restoration returning all artifact and enchantment cards from your graveyard to the battlefield.",
            "signals": [
                "ReturnFromYourGraveyardToBattlefieldAllEffect",
                "FilterArtifactOrEnchantmentCard",
            ],
        }

    if xmage_class_name == "WakeThePast":
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1",
            "fields": {
                "target": "artifact",
                "target_zone": "graveyard",
                "target_controller": "self",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact"],
                "grants_haste_until_eot": True,
            },
            "reason": "XMage structure matches Wake the Past returning all artifact cards from your graveyard to the battlefield and granting them haste until end of turn.",
            "signals": [
                "WakeThePastEffect",
                "StaticFilters.FILTER_CARD_ARTIFACT",
                "GainAbilityTargetEffect",
                "HasteAbility",
            ],
        }

    if (
        xmage_class_name == "OpenTheVaults"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"OneShotEffect", "OpenTheVaultsEffect"}
            and not ability_classes
            and _oracle_has(
                rules_text,
                "return all artifact and enchantment cards from all graveyards to the battlefield",
            )
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_enchantment_cards_from_all_graveyards_to_battlefield_v1",
            "fields": {
                "target": "artifact_or_enchantment",
                "target_zone": "graveyard",
                "target_controller": "each_player",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact", "enchantment"],
            },
            "reason": "XMage structure matches Open the Vaults returning all artifact and enchantment cards from each player's graveyard to the battlefield under their owners' control.",
            "signals": [
                "OpenTheVaultsEffect",
                "OneShotEffect",
            ],
        }

    if (
        xmage_class_name == "RoarOfReclamation"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"OneShotEffect", "RoarOfReclamationEffect"}
            and not ability_classes
            and _oracle_has(
                rules_text,
                "each player returns all artifact cards from their graveyard to the battlefield",
            )
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_cards_from_all_graveyards_to_battlefield_v1",
            "fields": {
                "target": "artifact",
                "target_zone": "graveyard",
                "target_controller": "each_player",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact"],
            },
            "reason": "XMage structure matches Roar of Reclamation returning all artifact cards from each player's graveyard to the battlefield.",
            "signals": [
                "RoarOfReclamationEffect",
                "OneShotEffect",
            ],
        }

    if (
        xmage_class_name == "TriumphantReckoning"
        or (
            card_types == {"SORCERY"}
            and effect_classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}
            and not ability_classes
            and _oracle_has(
                rules_text,
                "return all artifact, enchantment, and planeswalker cards from your graveyard to the battlefield",
            )
        )
    ):
        return {
            "effect": "recursion",
            "scope": "return_all_artifact_enchantment_planeswalker_cards_from_graveyard_to_battlefield_v1",
            "fields": {
                "target": "artifact_or_enchantment_or_planeswalker",
                "target_zone": "graveyard",
                "target_controller": "self",
                "destination": "battlefield",
                "return_all_matching": True,
                "target_card_types": ["artifact", "enchantment", "planeswalker"],
            },
            "reason": "XMage structure matches Triumphant Reckoning returning all artifact, enchantment, and planeswalker cards from your graveyard to the battlefield.",
            "signals": [
                "ReturnFromYourGraveyardToBattlefieldAllEffect",
                "artifact_enchantment_planeswalker_graveyard_mass_recursion",
            ],
        }

    if (
        xmage_class_name == "DoubleVision"
        or (
            card_types == {"ENCHANTMENT"}
            and effect_classes == {"CopyTargetStackObjectEffect"}
            and {"DoubleVisionCopyTriggeredAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
            and "isfirstinstantorsorcerycastbyplayeronturn" in normalized
        )
    ):
        return {
            "effect": "copy_spell",
            "scope": "first_instant_sorcery_cast_each_turn_copy_own_spell_v1",
            "fields": {
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "copy_spell",
                "target": "own_instant_or_sorcery_on_stack",
                "may_choose_new_targets": True,
                "choose_new_targets_status": "may",
                "trigger_first_instant_or_sorcery_each_turn": True,
            },
            "reason": "XMage structure matches Double Vision copying the first instant or sorcery spell its controller casts each turn, with optional new targets for the copy.",
            "signals": [
                "CopyTargetStackObjectEffect",
                "SpellCastControllerTriggeredAbility",
                "first_instant_or_sorcery_each_turn",
            ],
        }

    if (
        xmage_class_name == "SwarmIntelligence"
        or (
            card_types == {"ENCHANTMENT"}
            and effect_classes == {"CopyTargetStackObjectEffect"}
            and ability_classes == {"SpellCastControllerTriggeredAbility"}
            and "an instant or sorcery spell" in normalized
            and "you may copy that spell" in normalized
        )
    ):
        return {
            "effect": "copy_spell",
            "scope": "instant_sorcery_cast_copy_own_spell_v1",
            "fields": {
                "trigger": "instant_sorcery_cast",
                "trigger_effect": "copy_spell",
                "target": "own_instant_or_sorcery_on_stack",
                "may_choose_new_targets": True,
                "choose_new_targets_status": "may",
            },
            "reason": "XMage structure matches Swarm Intelligence copying an instant or sorcery spell its controller casts, with optional new targets for the copy.",
            "signals": [
                "CopyTargetStackObjectEffect",
                "SpellCastControllerTriggeredAbility",
                "instant_sorcery_cast_copy",
            ],
        }

    if (
        xmage_class_name == "CandelabraOfTawnos"
        or (
            card_types == {"ARTIFACT"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapSourceCost"}
            and "effect.settext( untap x target lands )" in normalized
            and "xtargetscountadjuster" in normalized
            and "manacostsimpl<>( {x} )" in normalized
        )
    ):
        return {
            "effect": "untap_land_engine",
            "scope": "x_tap_untap_x_lands_v1",
            "fields": {
                "activated_untap_lands_for_mana_unlock": True,
                "activation_requires_tap": True,
                "activation_cost_generic_from_x": True,
                "untap_target_land_count_from_x": True,
                "untap_target_land_restriction": "land",
            },
            "reason": "XMage structure matches Candelabra of Tawnos paying X and tapping to untap X target lands, modeled as a contextual land-untap mana engine.",
            "signals": [
                "UntapTargetEffect",
                "TapSourceCost",
                "XTargetsCountAdjuster",
                "ManaCostsImpl({X})",
            ],
        }

    if (
        xmage_class_name == "Earthcraft"
        or (
            card_types == {"ENCHANTMENT"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapTargetCost"}
            and "basic land" in normalized
            and "filter_controlled_untapped_creature" in normalized
        )
    ):
        return {
            "effect": "untap_land_engine",
            "scope": "tap_untapped_creature_untap_target_basic_land_v1",
            "fields": {
                "activated_untap_lands_for_mana_unlock": True,
                "activation_taps_untapped_creature_you_control": True,
                "untap_target_land_count": 1,
                "untap_target_land_restriction": "land",
                "untap_target_land_basic_only": True,
            },
            "reason": "XMage structure matches Earthcraft tapping an untapped creature you control to untap target basic land, modeled as a contextual land-untap mana engine.",
            "signals": [
                "UntapTargetEffect",
                "TapTargetCost",
                "basic_land_target",
                "untapped_creature_you_control",
            ],
        }

    if (
        xmage_class_name == "MagusOfTheCandelabra"
        or (
            card_types == {"CREATURE"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapSourceCost"}
            and "effect.settext( untap x target lands )" in normalized
            and "xtargetscountadjuster" in normalized
            and "manacostsimpl<>( {x} )" in normalized
            and "this.power = new mageint(1)" in normalized
            and "this.toughness = new mageint(2)" in normalized
        )
    ):
        return {
            "effect": "untap_land_engine",
            "scope": "creature_x_tap_untap_x_lands_v1",
            "fields": {
                "power": 1,
                "toughness": 2,
                "activated_untap_lands_for_mana_unlock": True,
                "activation_requires_tap": True,
                "activation_cost_generic_from_x": True,
                "untap_target_land_count_from_x": True,
                "untap_target_land_restriction": "land",
            },
            "reason": "XMage structure matches Magus of the Candelabra paying X and tapping to untap X target lands, modeled as a creature-based contextual land-untap mana engine.",
            "signals": [
                "UntapTargetEffect",
                "TapSourceCost",
                "XTargetsCountAdjuster",
                "ManaCostsImpl({X})",
                "power_1_toughness_2",
            ],
        }

    if (
        xmage_class_name == "OboroBreezecaller"
        or (
            card_types == {"CREATURE"}
            and effect_classes == {"UntapTargetEffect"}
            and {"FlyingAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"GenericManaCost", "ReturnToHandChosenControlledPermanentCost"}.issubset(cost_classes)
            and "targetlandpermanent" in normalized
        )
    ):
        return {
            "effect": "untap_land_engine",
            "scope": "pay_two_return_land_untap_target_land_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "flying": True,
                "activated_untap_lands_for_mana_unlock": True,
                "activation_cost_generic": 2,
                "activation_returns_land_to_hand": True,
                "untap_target_land_count": 1,
                "untap_target_land_restriction": "land",
            },
            "reason": "XMage structure matches Oboro Breezecaller paying {2} and returning a land you control to untap target land, modeled as a contextual land-untap mana engine.",
            "signals": [
                "UntapTargetEffect",
                "ReturnToHandChosenControlledPermanentCost",
                "GenericManaCost(2)",
                "FlyingAbility",
                "TargetLandPermanent",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and {"AddCountersTargetEffect", "DamageWithPowerFromOneToAnotherTargetEffect", "ExileTargetEffect", "SearchEffect", "SearchLibraryPutInHandOrOnBattlefieldEffect"}.issubset(effect_classes)
        and not ability_classes
    ):
        return {
            "effect": "modal_spell",
            "scope": "search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1",
            "fields": {
                "instant": True,
                "mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand": True,
                "mode_put_plus_one_counter_on_controlled_creature_then_fight": True,
                "mode_exile_target_artifact_or_enchantment": True,
            },
            "reason": "XMage structure matches Archdruid's Charm choosing between creature-or-land search, a +1/+1 counter plus fight mode, or exiling an artifact or enchantment.",
            "signals": [
                "SearchLibraryPutInHandOrOnBattlefieldEffect",
                "DamageWithPowerFromOneToAnotherTargetEffect",
                "ExileTargetEffect",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes
        == {"DestroyTargetEffect", "SearchLibraryPutInPlayTargetControllerEffect"}
        and not ability_classes
        and "TargetCreatureOrPlaneswalker" in target_classes
    ):
        return {
            "effect": "remove_permanent",
            "scope": "destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1",
            "fields": {
                "instant": True,
                "target": "creature_or_planeswalker",
                "target_controller_basic_land_tapped": True,
                "basic_land_compensation_status": "annotation_only",
            },
            "reason": (
                "XMage structure matches Erode destroying target creature or planeswalker, "
                "with that permanent's controller optionally searching for a basic land and "
                "putting it onto the battlefield tapped."
            ),
            "signals": [
                "DestroyTargetEffect",
                "SearchLibraryPutInPlayTargetControllerEffect",
                "TargetCreatureOrPlaneswalker",
            ],
        }

    if (
        card_types == {"LAND", "SORCERY"}
        and {
            "CantBlockAllEffect",
            "DestroyTargetEffect",
            "SearchLibraryPutInPlayTargetControllerEffect",
            "TapSourceUnlessPaysEffect",
        }.issubset(effect_classes)
        and {"AsEntersBattlefieldAbility", "RedManaAbility"}.issubset(ability_classes)
        and "TargetLandPermanent" in target_classes
    ):
        return {
            "effect": "remove_permanent",
            "scope": "destroy_target_land_target_controller_basic_land_tapped_runtime_nonfliers_cant_block_runtime_v1",
            "fields": {
                "sorcery": True,
                "target": "land",
                "target_controller_basic_land_tapped": True,
                "basic_land_compensation_status": "runtime_executor_v1",
                "cant_block_mode_status": "runtime_executor_v1",
                "cant_block_target_restriction": "creatures_without_flying",
                "land_side_pay_three_life_else_tapped": True,
                "land_side_add_mana": "R",
                "oracle_runtime_scope": "target_controller_basic_land_search_to_battlefield_tapped_nonfliers_cant_block_runtime_v1",
            },
            "reason": (
                "XMage structure matches Sundering Eruption destroying target land, "
                "letting that land's controller search for a basic land tapped, applying a "
                "can't-block rider to creatures without flying, and carrying a tapped-red-land back face."
            ),
            "signals": [
                "DestroyTargetEffect",
                "SearchLibraryPutInPlayTargetControllerEffect",
                "CantBlockAllEffect",
                "TargetLandPermanent",
                "RedManaAbility",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and effect_classes == {"DamageAllEffect", "DestroyTargetEffect"}
        and not ability_classes
        and "FilterCreatureOrPlaneswalkerPermanent" in filter_classes
        and "TargetLandPermanent" in target_classes
    ):
        return {
            "effect": "destroy_target_land_then_damage_all_creatures_and_planeswalkers",
            "scope": "destroy_target_land_then_deal_20_to_each_creature_and_planeswalker_v1",
            "fields": {
                "sorcery": True,
                "target": "land",
                "damage": 20,
                "damage_scope": "each_creature_and_planeswalker",
            },
            "reason": (
                "XMage structure matches Star of Extinction destroying target land "
                "and then dealing 20 damage to each creature and each planeswalker."
            ),
            "signals": [
                "DestroyTargetEffect",
                "DamageAllEffect",
                "FilterCreatureOrPlaneswalkerPermanent",
                "TargetLandPermanent",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and effect_classes == {"DestroyTargetEffect"}
        and ability_classes == {"OverloadAbility"}
        and "TargetPermanent" in target_classes
        and "targetcontroller.not_you" in normalized
    ):
        return {
            "effect": "remove_permanent",
            "scope": "destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1",
            "fields": {
                "sorcery": True,
                "target": "artifact",
                "target_controller": "opponent",
                "overload_cost": "{4}{R}",
                "overload_status": "annotation_only",
                "overload_target_rewrite": "target_to_each",
            },
            "reason": (
                "XMage structure matches Vandalblast destroying target artifact you don't control, "
                "with overload to hit each artifact you don't control."
            ),
            "signals": [
                "DestroyTargetEffect",
                "OverloadAbility",
                "TargetController.NOT_YOU",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"ReturnToHandTargetEffect"}
        and ability_classes == {"OverloadAbility"}
        and "targetcontroller.not_you" in normalized
    ):
        return {
            "effect": "bounce",
            "scope": "return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1",
            "fields": {
                "instant": True,
                "target": "nonland_permanent_you_dont_control",
                "overload_cost": "{6}{U}",
                "overload_bounces_each_nonland_permanent_you_dont_control": True,
            },
            "reason": "XMage structure matches Cyclonic Rift single-target bounce with overload for each nonland permanent you do not control.",
            "signals": [
                "ReturnToHandTargetEffect",
                "OverloadAbility",
                "TargetController.NOT_YOU",
            ],
        }

    if (
        card_types == {"INSTANT", "LAND"}
        and {"ReturnToHandTargetEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
        and {"AsEntersBattlefieldAbility", "BlueManaAbility"}.issubset(ability_classes)
        and "PayLifeCost" in cost_classes
    ):
        return {
            "effect": "bounce",
            "scope": "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1",
            "fields": {
                "instant": True,
                "target": "spell_or_opponent_nonland_permanent",
                "land_side_pay_three_life_else_tapped": True,
                "land_side_add_mana": "U",
            },
            "reason": "XMage structure matches Sink into Stupor returning a target spell or opposing nonland permanent and the blue land back face that can enter tapped unless you pay 3 life.",
            "signals": [
                "ReturnToHandTargetEffect",
                "TapSourceUnlessPaysEffect",
                "BlueManaAbility",
                "PayLifeCost",
            ],
        }

    if (
        card_types == {"INSTANT", "LAND"}
        and "DamageTargetEffect" in effect_classes
        and {"AsEntersBattlefieldAbility", "WhiteManaAbility"}.issubset(ability_classes)
        and "PayLifeCost" in cost_classes
        and "TargetAttackingOrBlockingCreature" in target_classes
    ):
        damage = _first_int(r"damagetargeteffect\((\d+)", normalized)
        if damage is None:
            damage = _first_int(r"deals\s+(\d+)\s+damage\s+to\s+target\s+attacking\s+or\s+blocking\s+creature", normalized)
        if damage is not None:
            return {
                "effect": "direct_damage",
                "scope": "damage_target_attacking_or_blocking_creature_or_tapped_white_land_v1",
                "fields": {
                    "instant": True,
                    "target": "creature",
                    "damage": damage,
                    "land_side_pay_three_life_else_tapped": True,
                    "land_side_add_mana": "W",
                },
                "reason": "XMage structure matches Razorgrass Ambush fixed damage to target attacking or blocking creature plus the white land MDFC back face.",
                "signals": [
                    "DamageTargetEffect",
                    "TargetAttackingOrBlockingCreature",
                    "TapSourceUnlessPaysEffect",
                    "WhiteManaAbility",
                    "PayLifeCost",
                ],
                "target_constraints": {
                    "card_types": ["creature"],
                    "combat_state": "attacking_or_blocking",
                },
            }

    if (
        card_types == {"INSTANT"}
        and {"CounterTargetEffect", "DestroyTargetEffect"}.issubset(effect_classes)
        and "blue spell" in normalized
        and "blue permanent" in normalized
    ):
        return {
            "effect": "modal_spell",
            "scope": "counter_target_blue_spell_or_destroy_target_blue_permanent_v1",
            "fields": {
                "counter_target_blue_spell": True,
                "destroy_target_blue_permanent": True,
                "instant": True,
            },
            "reason": "XMage structure matches Red Elemental Blast choosing between countering a blue spell and destroying a blue permanent.",
            "signals": [
                "CounterTargetEffect",
                "DestroyTargetEffect",
                "blue_spell_or_permanent",
            ],
        }

    if (
        xmage_class_name == "EldraziConfluence"
        or (
            card_types == {"INSTANT"}
            and {"BoostTargetEffect", "CreateTokenEffect", "ExileThenReturnTargetEffect"}.issubset(effect_classes)
            and "targetcreaturepermanent" in normalized
            and "targetnonlandpermanent" in normalized
            and "setminmodes(3)" in normalized
            and "setmaxmodes(3)" in normalized
            and "setmaychoosesamemodemorethanonce(true)" in normalized
            and "eldrazisciontoken" in normalized
        )
    ):
        return {
            "effect": "modal_spell",
            "scope": "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1",
            "fields": {
                "instant": True,
                "modal_choose_count": 3,
                "modal_may_repeat_modes": True,
                "mode_target_creature_plus_three_minus_three": True,
                "mode_blink_target_nonland_permanent_tapped": True,
                "mode_create_eldrazi_scion": True,
                "token_name": "Eldrazi Scion Token",
                "token_subtype": "Eldrazi Scion",
                "token_power": 1,
                "token_toughness": 1,
                "token_colors": [],
                "token_sacrifice_for_colorless_mana": True,
            },
            "reason": "XMage structure matches Eldrazi Confluence choosing three repeatable modes between +3/-3, blinking a nonland permanent tapped, and creating a 1/1 colorless Eldrazi Scion token.",
            "signals": [
                "BoostTargetEffect",
                "ExileThenReturnTargetEffect",
                "CreateTokenEffect",
                "EldraziScionToken",
                "repeatable_three_mode_spell",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"ReturnToHandTargetEffect"}
        and ability_classes == {"GiftAbility"}
    ):
        return {
            "effect": "bounce",
            "scope": "gift_bounce_opponent_creature_or_nonland_v1",
            "fields": {
                "instant": True,
                "gift_tapped_fish": True,
                "target": "opponent_creature",
                "gift_promised_target": "opponent_nonland_permanent",
            },
            "reason": "XMage structure matches Into the Flood Maw bouncing an opposing creature by default or an opposing nonland permanent if the tapped Fish gift was promised.",
            "signals": [
                "GiftAbility",
                "ReturnToHandTargetEffect",
                "TargetOpponentsCreaturePermanent",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and "GiftAbility" in ability_classes
        and {
            "CreateTokenEffect",
            "ExileSpellEffect",
            "LifeTotalCantChangeControllerEffect",
            "GainAbilityControllerEffect",
        }.issubset(effect_classes)
        and "swansongbirdtoken" in normalized
        and (
            "ProtectionFromEverythingAbility" in ability_classes
            or "protectionfromeverythingability" in normalized
        )
    ):
        return {
            "effect": "composite_resolution",
            "scope": "create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1",
            "fields": {
                "instant": True,
                "gift_extra_turn": True,
                "gift_default_promised": True,
                "exiles_self": True,
                "_composite_rule_components": [
                    {
                        "effect": "token_maker",
                        "token_count": 4,
                        "token_name": "Bird Token",
                        "token_subtype": "Bird",
                        "token_colors": ["U"],
                        "token_power": 2,
                        "token_toughness": 2,
                        "token_flying": True,
                        "battle_model_scope": "create_four_2_2_blue_flying_bird_tokens_component_v1",
                    },
                    {
                        "effect": "phase_out",
                        "gift_required": True,
                        "phase_out_all_permanents_you_control": True,
                        "phase_out_includes_lands": True,
                        "life_total_cant_change": True,
                        "protection_from_everything": True,
                        "battle_model_scope": "gift_promised_phase_all_permanents_life_lock_protection_component_v1",
                    },
                ],
            },
            "reason": "XMage structure matches Perch Protection creating four Swan Song Bird tokens, then applying gift-gated phase-out, life lock, protection from everything, and self-exile.",
            "signals": [
                "GiftAbility",
                "CreateTokenEffect",
                "SwanSongBirdToken",
                "LifeTotalCantChangeControllerEffect",
                "ProtectionFromEverythingAbility",
                "ExileSpellEffect",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and "EntersBattlefieldTriggeredAbility" in ability_classes
        and "PutCardIntoGraveFromAnywhereAllTriggeredAbility" in ability_classes
        and {"SearchLibraryPutInPlayEffect", "CreateTokenEffect"}.issubset(effect_classes)
        and "sandwarriortoken" in normalized
        and "subtype.desert.getpredicate" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1",
            "fields": {
                "power": 2,
                "toughness": 2,
                "etb_land_ramp_count": 1,
                "etb_land_ramp_condition": "opponent_controls_more_lands",
                "land_subtypes_any": ["desert"],
                "land_enters_tapped": True,
                "land_cards_to_your_graveyard_create_token": True,
                "land_graveyard_trigger_once_each_turn": True,
                "land_graveyard_token_name": "Sand Warrior Token",
                "land_graveyard_token_subtype": "Sand Warrior",
                "land_graveyard_token_colors": ["R", "G", "W"],
                "land_graveyard_token_power": 1,
                "land_graveyard_token_toughness": 1,
            },
            "reason": "XMage structure matches Sand Scout entering as a 2/2, tutoring a tapped Desert when an opponent controls more lands, and creating a 1/1 red-green-white Sand Warrior once each turn when land cards go to your graveyard.",
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "OpponentControlsMoreCondition",
                "SearchLibraryPutInPlayEffect",
                "PutCardIntoGraveFromAnywhereAllTriggeredAbility",
                "SandWarriorToken",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"ReturnToHandTargetEffect", "UntapLandsEffect"}
        and not ability_classes
    ):
        return {
            "effect": "bounce",
            "scope": "return_target_creature_then_untap_up_to_two_lands_v1",
            "fields": {
                "instant": True,
                "target": "creature",
                "untap_lands_count": 2,
            },
            "reason": "XMage structure matches Snap returning a target creature and untapping up to two lands.",
            "signals": [
                "ReturnToHandTargetEffect",
                "UntapLandsEffect",
                "TargetCreaturePermanent",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and {"AddManaInAnyCombinationEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
        and not ability_classes
    ):
        return {
            "effect": "draw_cards",
            "scope": "add_two_mana_any_combination_then_draw_v1",
            "fields": {
                "count": 1,
                "instant": True,
                "add_mana_any_combination": 2,
            },
            "reason": "XMage structure matches Manamorphose adding two mana in any combination of colors and then drawing a card.",
            "signals": [
                "AddManaInAnyCombinationEffect",
                "DrawCardSourceControllerEffect",
            ],
        }

    if (
        card_types == {"ARTIFACT"}
        and effect_classes == {"AddCountersSourceEffect"}
        and {"DynamicManaAbility", "EntersBattlefieldAbility", "MultikickerAbility"}.issubset(ability_classes)
    ):
        return {
            "effect": "artifact",
            "scope": "multikicker_charge_counter_mana_rock_v1",
            "fields": {
                "multikicker_cost": "{2}",
                "etb_charge_counters_per_kick": True,
                "tap_add_colorless_per_charge_counter": True,
            },
            "reason": "XMage structure matches Everflowing Chalice multikicker, charge counters per kick, and tap-for-colorless-per-charge-counter mana production.",
            "signals": [
                "MultikickerAbility",
                "EntersBattlefieldAbility",
                "DynamicManaAbility",
                "AddCountersSourceEffect",
            ],
        }

    if (
        card_types == {"PLANESWALKER"}
        and {"DrawCardSourceControllerEffect", "ReturnToHandTargetEffect", "CastAsThoughItHadFlashAllEffect", "TeferiTimeRavelerReplacementEffect"}.issubset(effect_classes)
        and {"LoyaltyAbility", "SimpleStaticAbility"}.issubset(ability_classes)
        and "sorcery spells" in normalized
        and "artifact, creature, or enchantment" in normalized
    ):
        return {
            "effect": "planeswalker",
            "scope": "opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1",
            "fields": {
                "starting_loyalty": 4,
                "opponents_can_cast_only_as_sorcery": True,
                "plus_one_sorceries_have_flash_until_your_next_turn": True,
                "minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw": 1,
            },
            "reason": "XMage structure matches Teferi, Time Raveler static timing lock, plus-one sorcery flash permission, and minus-three bounce-plus-draw mode.",
            "signals": [
                "ContinuousRuleModifyingEffectImpl",
                "CastAsThoughItHadFlashAllEffect",
                "ReturnToHandTargetEffect",
            ],
        }

    return None


def _build_simple_creature_mana_source_fields(
    *,
    card_types: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"CREATURE"}:
        return None

    normalized = _normalized_rules_text(rules_text)

    if (
        ability_classes == {"SimpleManaAbility"}
        and 'this.power = new mageint(1)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
        and "mana.blackmana(1)" in normalized
        and "damagecontrollereffect(1)" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_one_one_black_pain_mana_dork_runtime_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "B",
                "damage_on_tap": 1,
                "tap_damage_status": "runtime_executor_v1",
                "conditional_mana_modes_status": "runtime_executor_v1",
                "conditional_mana_modes": [
                    {
                        "color": "B",
                        "mode": "damage_on_tap",
                        "restriction": "any_spell",
                        "status": "runtime_executor_v1",
                        "life_loss_on_spend": 1,
                        "life_loss_kind": "damage_on_tap",
                        "life_loss_status": "tap_damage_status",
                    }
                ],
                "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1",
            },
            "reason": "XMage structure matches a 1/1 creature that taps for black mana and deals 1 damage to its controller; ManaLoom now executes that damage as a conditional mana spend cost.",
            "signals": ["SimpleManaAbility", "DamageControllerEffect", "BlackMana(1)", "MageInt(1)", "mana_source"],
        }

    if (
        ability_classes == {"GreenManaAbility"}
        and 'this.power = new mageint(1)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_one_one_green_mana_dork_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "G",
            },
            "reason": "XMage structure matches a 1/1 creature with a single green tap-for-mana ability.",
            "signals": ["GreenManaAbility", "MageInt(1)", "mana_source"],
        }

    if (
        ability_classes == {"WhiteManaAbility"}
        and 'this.power = new mageint(1)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_one_one_white_mana_dork_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "W",
            },
            "reason": "XMage structure matches a 1/1 creature with a single white tap-for-mana ability.",
            "signals": ["WhiteManaAbility", "MageInt(1)", "mana_source"],
        }

    if (
        ability_classes == {"AnyColorManaAbility", "FlyingAbility"}
        and 'this.power = new mageint(0)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_zero_one_flying_any_color_mana_dork_v1",
            "fields": {
                "power": 0,
                "toughness": 1,
                "flying": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "WUBRG",
            },
            "reason": "XMage structure matches a 0/1 flyer with a single any-color tap-for-mana ability.",
            "signals": ["AnyColorManaAbility", "FlyingAbility", "MageInt(0)", "MageInt(1)", "mana_source"],
        }

    if (
        ability_classes == {"BlueManaAbility", "ExaltedAbility", "GreenManaAbility", "WhiteManaAbility"}
        and 'this.power = new mageint(0)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_zero_one_exalted_tricolor_mana_dork_v1",
            "fields": {
                "power": 0,
                "toughness": 1,
                "exalted": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "GWU",
            },
            "reason": "XMage structure matches a 0/1 exalted creature that taps for one Bant-colored mana.",
            "signals": [
                "ExaltedAbility",
                "GreenManaAbility",
                "WhiteManaAbility",
                "BlueManaAbility",
                "MageInt(0)",
                "MageInt(1)",
                "mana_source",
            ],
        }

    if (
        ability_classes == {"BlackManaAbility", "ExaltedAbility", "GreenManaAbility", "RedManaAbility"}
        and 'this.power = new mageint(0)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_mana_zero_one_exalted_tricolor_mana_dork_v1",
            "fields": {
                "power": 0,
                "toughness": 1,
                "exalted": True,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "BRG",
            },
            "reason": "XMage structure matches a 0/1 exalted creature that taps for one Jund-colored mana.",
            "signals": [
                "ExaltedAbility",
                "BlackManaAbility",
                "RedManaAbility",
                "GreenManaAbility",
                "MageInt(0)",
                "MageInt(1)",
                "mana_source",
            ],
        }

    if (
        ability_classes == {"AddEachControlledColorManaAbility"}
        and 'this.power = new mageint(1)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
    ):
        return {
            "effect": "creature",
            "scope": "one_one_color_diversity_mana_dork_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced_from_colors_among_permanents": True,
                "mana_colors_from_controlled_permanents": True,
                "produces": "WUBRG",
            },
            "reason": "XMage structure matches a 1/1 creature that adds one mana of each color among permanents you control.",
            "signals": [
                "AddEachControlledColorManaAbility",
                "MageInt(1)",
                "MageInt(1)",
                "controlled_colors",
                "mana_source",
            ],
        }

    if (
        ability_classes == {"DynamicManaAbility"}
        and 'this.power = new mageint(2)' in normalized
        and 'this.toughness = new mageint(1)' in normalized
        and (
            "permanentsonbattlefieldcount(staticfilters.filter_controlled_creature)" in normalized
            or "add {g} for each creature you control" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "two_one_green_per_creature_mana_dork_v1",
            "fields": {
                "power": 2,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced_from_controlled_creatures": True,
                "produces": "G",
            },
            "reason": "XMage structure matches a 2/1 creature that adds one green mana for each creature you control.",
            "signals": [
                "DynamicManaAbility",
                "FILTER_CONTROLLED_CREATURE",
                "MageInt(2)",
                "MageInt(1)",
                "mana_source",
            ],
        }

    return None


def _build_basic_land_fields(
    *,
    index_entry: dict[str, Any],
    effect_classes: set[str],
    ability_classes: set[str],
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if card_types != {"LAND"} or effect_classes:
        return None

    if ability_classes == {"WhiteManaAbility"}:
        return {
            "effect": "land",
            "scope": "basic_one_color_land_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "W",
                "basic_land_types": ["Plains"],
            },
            "reason": "XMage structure matches a basic Plains that taps for one white mana.",
            "signals": ["LAND", "WhiteManaAbility", "BasicLand"],
        }

    if ability_classes == {"RedManaAbility"}:
        return {
            "effect": "land",
            "scope": "basic_one_color_land_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "R",
                "basic_land_types": ["Mountain"],
            },
            "reason": "XMage structure matches a basic Mountain that taps for one red mana.",
            "signals": ["LAND", "RedManaAbility", "BasicLand"],
        }

    return None


def _build_dynamic_any_color_land_fields(
    *,
    index_entry: dict[str, Any],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if card_types != {"LAND"} or effect_classes:
        return None
    raw_excerpt = _normalized_rules_text(str(index_entry.get("raw_excerpt") or ""))
    if ability_classes == {"AnyColorLandsProduceManaAbility"} and (
        "anycolorlandsproducemanaability(targetcontroller.opponent)" in raw_excerpt
        or str(index_entry.get("xmage_class_name") or index_entry.get("class_name") or "").strip() == "ExoticOrchard"
        or _oracle_has(rules_text, "add one mana of any color that a land an opponent controls could produce")
    ):
        return {
            "effect": "land",
            "scope": "any_color_from_opponent_land_production_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "WUBRG",
                "opponent_land_color_dependency": True,
            },
            "reason": "XMage structure matches a land that adds one mana of any color an opponent's land could produce.",
            "signals": ["LAND", "AnyColorLandsProduceManaAbility", "opponent_land_colors"],
        }
    return None


def _build_colorless_land_sacrifice_mana_mode_fields(
    *,
    index_entry: dict[str, Any],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if card_types != {"LAND"} or effect_classes:
        return None

    raw_excerpt = _normalized_rules_text(str(index_entry.get("raw_excerpt") or ""))
    normalized = _normalized_rules_text(rules_text)
    has_base_colorless = "ColorlessManaAbility" in ability_classes
    has_sacrifice_mode = (
        "SimpleManaAbility" in ability_classes
        and {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
        and (
            "mana.colorlessmana(2)" in raw_excerpt
            or "mana.colorlessmana(2)" in normalized
            or "add {c}{c}" in normalized
        )
    )
    if not (has_base_colorless and has_sacrifice_mode):
        return None

    return {
        "effect": "ramp_permanent",
        "scope": "colorless_land_tap_or_tap_sacrifice_two_colorless_mode_v1",
        "fields": {
            "is_mana_source": True,
            "permanent_type": "land",
            "mana_produced": 1,
            "produces": "C",
            "activation_requires_tap": True,
            "has_default_colorless_mana_ability": True,
            "default_mana_produced": 1,
            "has_sacrifice_mana_mode": True,
            "sacrifice_mana_produced": 2,
            "sacrifice_mana_mode_status": "runtime_required",
            "alternate_mana_modes": [
                {
                    "mode": "tap_sacrifice_for_two_colorless",
                    "produces": "C",
                    "mana_produced": 2,
                    "activation_requires_tap": True,
                    "activation_requires_sacrifice": True,
                    "status": "runtime_required",
                }
            ],
            "oracle_runtime_scope": "land_alternate_sacrifice_mana_mode_runtime_required_v1",
        },
        "reason": (
            "XMage structure matches a land with the normal ColorlessManaAbility plus a SimpleManaAbility "
            "that taps and sacrifices the source for two colorless mana. ManaLoom must keep the default "
            "one-mana land mode separate from the sacrificial two-mana burst before this can be promoted."
        ),
        "signals": [
            "LAND",
            "ColorlessManaAbility",
            "SimpleManaAbility",
            "TapSourceCost",
            "SacrificeSourceCost",
            "ColorlessMana(2)",
        ],
    }


def _build_pain_land_fields(
    *,
    index_entry: dict[str, Any],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    if card_types != {"LAND"}:
        return None

    raw_excerpt = _normalized_rules_text(str(index_entry.get("raw_excerpt") or ""))
    xmage_class_name = str(index_entry.get("xmage_class_name") or index_entry.get("class_name") or "").strip()
    if (
        effect_classes == {"DamageControllerEffect"}
        and ability_classes == {"AnyColorManaAbility", "SimpleManaAbility"}
        and cost_classes == {"TapSourceCost"}
        and (
            "mana.colorlessmana(1)" in raw_excerpt
            and "damagecontrollereffect(3)" in raw_excerpt
            and "anycolormanaability" in raw_excerpt
            or xmage_class_name == "TarnishedCitadel"
        )
    ):
        return {
            "effect": "land",
            "scope": "colorless_or_any_color_pain_land_runtime_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "CWUBRG",
                "life_for_colored_mana": 3,
                "life_loss_on_colored_mana_status": "runtime_executor_v1",
                "conditional_mana_modes_status": "runtime_executor_v1",
                "conditional_mana_modes": [
                    {
                        "color": "C",
                        "mode": "colorless_no_life_loss",
                        "restriction": "any_spell",
                        "status": "runtime_executor_v1",
                        "life_loss_on_spend": 0,
                        "life_loss_kind": "none",
                        "life_loss_status": "runtime_executor_v1",
                    },
                    *[
                        {
                            "color": color,
                            "mode": "damage_on_colored_mana",
                            "restriction": "any_spell",
                            "status": "runtime_executor_v1",
                            "life_loss_on_spend": 3,
                            "life_loss_kind": "damage_on_colored_mana",
                            "life_loss_status": "life_loss_on_colored_mana_status",
                        }
                        for color in "WUBRG"
                    ],
                ],
                "oracle_runtime_scope": "pain_mana_source_life_cost_runtime_v1",
            },
            "reason": "XMage structure matches a land that adds colorless freely or any color while dealing 3 damage to its controller; ManaLoom now executes the colored damage as a conditional mana spend cost.",
            "signals": ["LAND", "SimpleManaAbility", "AnyColorManaAbility", "DamageControllerEffect", "ColorlessMana(1)"],
        }
    return None


def _build_simple_artifact_mana_source_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"ARTIFACT"}:
        return None

    normalized = _normalized_rules_text(rules_text)
    colored_abilities = [
        ability
        for ability in ability_classes
        if ability in {
            "WhiteManaAbility",
            "BlueManaAbility",
            "BlackManaAbility",
            "RedManaAbility",
            "GreenManaAbility",
        }
    ]
    mana_ability_to_symbol = {
        "WhiteManaAbility": "W",
        "BlueManaAbility": "U",
        "BlackManaAbility": "B",
        "RedManaAbility": "R",
        "GreenManaAbility": "G",
    }
    pair_order = "WUBRG"

    if (
        effect_classes == {"DamageControllerEffect"}
        and "ColorlessManaAbility" in ability_classes
        and len(colored_abilities) == 2
    ):
        colored_symbols = sorted(
            (mana_ability_to_symbol[ability] for ability in colored_abilities),
            key=pair_order.index,
        )
        return {
            "effect": "ramp_permanent",
            "scope": "pain_talisman_color_pair_partial_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "C" + "".join(colored_symbols),
                "life_for_colored_mana": 1,
            },
            "reason": "XMage structure matches a Talisman-style artifact that adds colorless freely or one of two colors while dealing 1 damage to its controller.",
            "signals": ["ColorlessManaAbility", *colored_abilities, "DamageControllerEffect", "pain_talisman"],
        }

    if (
        ability_classes == {"AnyColorManaAbility"}
        and (
            "untapped creature you control" in normalized
            or "filter_controlled_untapped_creature" in normalized
            or "staticfilters.filter_controlled_untapped_creature" in normalized
        )
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "creature_support_any_color_mana_rock_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "WUBRG",
                "mana_source_requires_untapped_creature": True,
            },
            "reason": "XMage structure matches an artifact that needs an untapped creature you control to generate one mana of any color.",
            "signals": ["AnyColorManaAbility", "TapTargetCost", "untapped_creature_support"],
        }

    if (
        ability_classes == {"AnyColorManaAbility"}
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "one_any_color_mana_rock_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "WUBRG",
            },
            "reason": "XMage structure matches a simple artifact mana source that adds one mana of any color.",
            "signals": ["AnyColorManaAbility", "any_color_mana_rock"],
        }

    if (
        "ColorlessManaAbility" in ability_classes
        and "TapTargetCost" in cost_classes
        and (
            "artifact or creature you control" in normalized
            or "untapped artifact or creature you control" in normalized
            or (
                "targetcontrolledpermanent(filter)" in normalized
                and "cardtype.artifact.getpredicate()" in normalized
                and "cardtype.creature.getpredicate()" in normalized
            )
        )
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "artifact_or_creature_support_colorless_mana_rock_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "C",
                "mana_source_requires_untapped_artifact_or_creature": True,
            },
            "reason": "XMage structure matches an artifact that needs an untapped artifact or creature you control to generate one colorless mana.",
            "signals": ["SimpleManaAbility", "TapTargetCost", "artifact_or_creature_support", "ColorlessMana(1)"],
        }

    if (
        ability_classes == {"SimpleManaAbility"}
        and cost_classes == {"TapSourceCost"}
        and "mana.colorlessmana(2)" in normalized
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "two_colorless_mana_rock_v1",
            "fields": {
                "mana_produced": 2,
                "produces": "C",
            },
            "reason": "XMage structure matches a simple artifact tap ability that adds two colorless mana.",
            "signals": ["SimpleManaAbility", "TapSourceCost", "ColorlessMana(2)"],
        }

    if (
        ability_classes == {"SimpleManaAbility"}
        and cost_classes == {"GenericManaCost", "TapSourceCost"}
        and "new mana(0, 1, 0, 1, 0, 0, 0, 0)" in normalized
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "signet_filter_mana_rock_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "UR",
                "activation_cost_generic": 1,
            },
            "reason": "XMage structure matches a Signet-style artifact filter that pays 1 and taps to add {U}{R}.",
            "signals": ["SimpleManaAbility", "GenericManaCost(1)", "TapSourceCost", "Mana(UR)"],
        }

    if (
        ability_classes == {"SimpleManaAbility"}
        and cost_classes == {"GenericManaCost", "TapSourceCost"}
        and "new mana(0, 1, 0, 0, 1, 0, 0, 0)" in normalized
    ):
        return {
            "effect": "ramp_permanent",
            "scope": "signet_filter_mana_rock_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "GU",
                "activation_cost_generic": 1,
            },
            "reason": "XMage structure matches a Signet-style artifact filter that pays 1 and taps to add {G}{U}.",
            "signals": ["SimpleManaAbility", "GenericManaCost(1)", "TapSourceCost", "Mana(GU)"],
        }

    return None


def _build_hand_exile_mana_ritual_fields(
    *,
    index_entry: dict[str, Any],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    card_types = _constructor_card_types(index_entry)
    normalized = _normalized_rules_text(rules_text)
    if (
        card_types == {"CREATURE"}
        and not effect_classes
        and ability_classes == {"SimpleManaAbility"}
        and cost_classes == {"ExileSourceFromHandCost"}
        and "mana.greenmana(1)" in normalized
    ):
        return {
            "effect": "ramp_ritual",
            "scope": "hand_exile_add_one_green_mana_ritual_v1",
            "fields": {
                "hand_exile_mana_ability": True,
                "mana_produced": 1,
                "produces": "G",
            },
            "reason": "XMage structure matches a hand-zone exile activation that adds one green mana.",
            "signals": ["SimpleManaAbility", "ExileSourceFromHandCost", "GreenMana(1)", "Zone.HAND"],
        }
    return None


def _fetch_land_subtypes_from_rules_text(rules_text: str) -> list[str]:
    normalized = _normalized_rules_text(rules_text)
    match = re.search(
        r"fetchlandactivatedability\s*\(\s*subtype\.([a-z]+)\s*,\s*subtype\.([a-z]+)\s*\)",
        normalized,
    )
    if not match:
        return []
    return [match.group(1).capitalize(), match.group(2).capitalize()]


def _build_fetch_land_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"LAND"}:
        return None
    if effect_classes or cost_classes:
        return None
    if ability_classes != {"FetchLandActivatedAbility"}:
        return None

    land_subtypes_any = _fetch_land_subtypes_from_rules_text(rules_text)
    if len(land_subtypes_any) != 2:
        return None

    return {
        "effect": "ramp_permanent",
        "scope": "self_sacrifice_fetch_land_two_land_subtypes_v1",
        "fields": {
            "activated_self_sacrifice_land_tutor": True,
            "activation_cost_generic": 0,
            "activation_requires_tap": True,
            "activated_pay_life": 1,
            "land_count": 1,
            "lands_to_battlefield": 1,
            "land_enters_tapped": False,
            "land_subtypes_any": land_subtypes_any,
        },
        "reason": "XMage structure matches a fetchland that taps, pays 1 life, sacrifices itself, and finds a land with either of two listed basic land subtypes.",
        "signals": ["FetchLandActivatedAbility", *[f"SubType.{subtype.upper()}" for subtype in land_subtypes_any]],
    }


def _build_creature_sacrifice_ritual_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types not in ({"INSTANT"}, {"SORCERY"}):
        return None
    if ability_classes or cost_classes != {"SacrificeTargetCost"}:
        return None

    normalized = _normalized_rules_text(rules_text)
    is_instant = card_types == {"INSTANT"}

    if (
        effect_classes == {"AddManaInAnyCombinationEffect"}
        and "SacrificeCostManaValue" in rules_text
        and "ColoredManaSymbol.B" in rules_text
        and "ColoredManaSymbol.R" in rules_text
    ):
        return {
            "effect": "ramp_ritual",
            "scope": "sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1",
            "fields": {
                "instant": is_instant,
                "requires_sacrifice_creature": True,
                "mana_produced_from_sacrificed_cmc": True,
                "produces": "BR",
                "mana_color_choice": ["B", "R"],
                "mana_color_status": "abstracted_to_generic_pool_runtime",
            },
            "reason": "XMage structure matches Burnt Offering sacrificing a creature as an additional cost and adding black and/or red mana equal to that creature's mana value.",
            "signals": [
                "SacrificeTargetCost",
                "SacrificeCostManaValue.CREATURE",
                "AddManaInAnyCombinationEffect",
                "ColoredManaSymbol.B",
                "ColoredManaSymbol.R",
            ],
        }

    if effect_classes != {"BasicManaEffect"}:
        return None

    if "mana.blackmana(4)" in normalized:
        return {
            "effect": "ramp_ritual",
            "scope": "sacrifice_creature_add_four_black_mana_ritual_v1",
            "fields": {
                "instant": is_instant,
                "requires_sacrifice_creature": True,
                "mana_produced": 4,
                "produces": "B",
            },
            "reason": "XMage structure matches a ritual that sacrifices a creature as an additional cost to add four black mana.",
            "signals": ["SacrificeTargetCost", "BasicManaEffect", "BlackMana(4)"],
        }

    if "mana.redmana(3)" in normalized:
        return {
            "effect": "ramp_ritual",
            "scope": "sacrifice_creature_add_three_red_mana_ritual_v1",
            "fields": {
                "instant": is_instant,
                "requires_sacrifice_creature": True,
                "mana_produced": 3,
                "produces": "R",
            },
            "reason": "XMage structure matches a ritual that sacrifices a creature as an additional cost to add three red mana.",
            "signals": ["SacrificeTargetCost", "BasicManaEffect", "RedMana(3)"],
        }

    return None


def _build_dynamic_mana_ritual_fields(
    *,
    xmage_class_name: str,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    target_classes: set[str],
    filter_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    normalized = _normalized_rules_text(rules_text)
    if (
        xmage_class_name == "ManaGeyser"
        and card_types == {"SORCERY"}
        and effect_classes == {"DynamicManaEffect"}
        and not ability_classes
        and not cost_classes
        and "TargetController" in target_classes
        and "FilterLandPermanent" in filter_classes
        and "tapped land your opponents control" in normalized
    ):
        return {
            "effect": "ramp_ritual",
            "scope": "add_red_for_each_tapped_land_opponents_control_v1",
            "fields": {
                "sorcery": True,
                "produces": "R",
                "dynamic_mana_amount": True,
                "mana_produced_from_opponents_tapped_lands": True,
                "mana_per_tapped_land": 1,
                "mana_color_status": "abstracted_to_generic_pool_runtime",
            },
            "reason": "XMage structure matches Mana Geyser adding one red mana for each tapped land controlled by opponents.",
            "signals": [
                "ManaGeyser",
                "DynamicManaEffect",
                "PermanentsOnBattlefieldCount(FilterLandPermanent)",
                "TappedPredicate.TAPPED",
                "TargetController.OPPONENT",
            ],
        }
    return None


def _build_topdeck_tutor_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types not in ({"INSTANT"}, {"SORCERY"}):
        return None
    if ability_classes or cost_classes:
        return None
    if "SearchLibraryPutOnLibraryEffect" not in effect_classes:
        return None

    normalized = _normalized_rules_text(rules_text)
    is_instant = card_types == {"INSTANT"}

    if effect_classes == {"SearchLibraryPutOnLibraryEffect"}:
        if (
            "cardtype.instant.getpredicate()" in normalized
            and "cardtype.sorcery.getpredicate()" in normalized
        ) or "instant or sorcery card" in normalized:
            return {
                "effect": "tutor",
                "scope": "instant_or_sorcery_tutor_to_top_v1",
                "fields": {
                    "instant": is_instant,
                    "target": "instant_or_sorcery_to_top",
                },
                "reason": "XMage structure matches a tutor that finds an instant or sorcery and places it on top of the library.",
                "signals": [
                    "SearchLibraryPutOnLibraryEffect",
                    "CardType.INSTANT",
                    "CardType.SORCERY",
                ],
            }

        if "filter_card_creature" in normalized or "staticfilters.filter_card_creature" in normalized:
            return {
                "effect": "tutor",
                "scope": "creature_tutor_to_top_v1",
                "fields": {
                    "instant": is_instant,
                    "target": "creature_to_top",
                },
                "reason": "XMage structure matches a tutor that finds a creature card and places it on top of the library.",
                "signals": [
                    "SearchLibraryPutOnLibraryEffect",
                    "FILTER_CARD_CREATURE",
                ],
            }

    if effect_classes == {"LoseLifeSourceControllerEffect", "SearchLibraryPutOnLibraryEffect"}:
        life_loss = None
        if "loselifesourcecontrollereffect(2)" in normalized:
            life_loss = 2
        if life_loss is None and "lose 2 life" in normalized:
            life_loss = 2
        if life_loss == 2:
            return {
                "effect": "tutor",
                "scope": "any_tutor_to_top_lose_two_life_v1",
                "fields": {
                    "instant": is_instant,
                    "target": "any_to_top",
                    "controller_loses_life_after_tutor": 2,
                },
                "reason": "XMage structure matches a tutor that places any card on top of the library and then causes its controller to lose 2 life.",
                "signals": [
                    "SearchLibraryPutOnLibraryEffect",
                    "LoseLifeSourceControllerEffect(2)",
                ],
            }

    return None


def _build_tutor_to_hand_fields(
    *,
    xmage_class_name: str,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    condition_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    normalized = _normalized_rules_text(rules_text)

    if "SearchLibraryPutInHandEffect" not in effect_classes:
        return None

    def tutor_target() -> str:
        if "filter_card_artifact" in normalized or "filter_card_artifact_an" in normalized or "artifact card" in normalized:
            return "artifact_to_hand"
        if "subtype.equipment" in normalized or "equipment card" in normalized:
            return "equipment_to_hand"
        if "filtercreaturecard( green creature card" in normalized or (
            "filtercreaturecard" in normalized and "objectcolor.green" in normalized
        ):
            return "green_creature_to_hand"
        if "legendary creature card" in normalized:
            return "legendary_creature_to_hand"
        if "filter_card_creature" in normalized or "creature card" in normalized:
            return "creature_to_hand"
        if "filterlandcard" in normalized or "land card" in normalized:
            return "land_to_hand"
        if "demon card" in normalized or "subtype.demon" in normalized:
            return "demon_to_hand"
        return "any_to_hand"

    if card_types in ({"INSTANT"}, {"SORCERY"}):
        is_instant = card_types == {"INSTANT"}
        target = tutor_target()
        if "ConditionalOneShotEffect" in effect_classes and "DeliriumCondition" in condition_classes:
            return {
                "effect": "tutor",
                "scope": "conditional_delirium_restricted_or_any_tutor_to_hand_v1",
                "ability_kind": "one_shot",
                "fields": {
                    "instant": is_instant,
                    "target": target,
                    "delirium_target": "any_to_hand",
                    "delirium_graveyard_card_type_count": 4,
                    "tutor_destination": "hand",
                },
                "reason": "XMage structure matches a conditional tutor that upgrades to any-card-to-hand under delirium.",
                "signals": ["SearchLibraryPutInHandEffect", "ConditionalOneShotEffect", "DeliriumCondition"],
            }
        if "CreateDelayedTriggeredAbilityEffect" in effect_classes and "PactDelayedTriggeredAbility" in ability_classes:
            return {
                "effect": "tutor",
                "scope": "pact_green_creature_tutor_to_hand_delayed_payment_v1",
                "ability_kind": "one_shot",
                "fields": {
                    "instant": is_instant,
                    "target": target,
                    "tutor_destination": "hand",
                    "delayed_upkeep_mana_payment": "{2}{G}{G}",
                    "delayed_upkeep_payment_status": "annotation_only",
                    "lose_game_if_unpaid": True,
                },
                "reason": "XMage structure matches a pact tutor with delayed upkeep payment-or-lose trigger.",
                "signals": ["SearchLibraryPutInHandEffect", "CreateDelayedTriggeredAbilityEffect", "PactDelayedTriggeredAbility"],
            }
        if "RecklessHandlingEffect" in effect_classes:
            return {
                "effect": "tutor",
                "scope": "artifact_tutor_to_hand_random_discard_damage_if_artifact_discarded_v1",
                "ability_kind": "one_shot",
                "fields": {
                    "instant": is_instant,
                    "target": target,
                    "tutor_destination": "hand",
                    "random_discard_after_tutor": 1,
                    "discard_after_tutor_random": 1,
                    "damage_each_opponent_if_artifact_discarded": 2,
                },
                "reason": "XMage structure matches artifact tutor to hand plus random discard and artifact-discard damage rider.",
                "signals": ["SearchLibraryPutInHandEffect", "RecklessHandlingEffect"],
            }
        if "ReturnFromGraveyardToHandTargetEffect" in effect_classes:
            return {
                "effect": "modal_spell",
                "scope": "modal_artifact_tutor_or_artifact_graveyard_to_hand_v1",
                "ability_kind": "one_shot",
                "fields": {
                    "instant": is_instant,
                    "mode_min": 1,
                    "mode_max": 2,
                    "mode_one_target": target,
                    "mode_two_target": "artifact_from_graveyard_to_hand",
                },
                "reason": "XMage structure matches a modal spell that can tutor an artifact to hand or return an artifact from graveyard to hand.",
                "signals": ["SearchLibraryPutInHandEffect", "ReturnFromGraveyardToHandTargetEffect"],
            }
        if "LoseLifeSourceControllerEffect" in effect_classes:
            return {
                "effect": "tutor",
                "scope": "any_tutor_to_hand_controller_loses_life_v1",
                "ability_kind": "one_shot",
                "fields": {
                    "instant": is_instant,
                    "target": target,
                    "tutor_destination": "hand",
                    "controller_loses_life_after_tutor": _first_int(r"LoseLifeSourceControllerEffect\((\d+)\)", rules_text) or 3,
                },
                "reason": "XMage structure matches any-card tutor to hand with controller life-loss rider.",
                "signals": ["SearchLibraryPutInHandEffect", "LoseLifeSourceControllerEffect"],
            }

    if (
        card_types == {"ARTIFACT"}
        and "SearchLibraryPutInHandEffect" in effect_classes
        and "TapSourceCost" in cost_classes
        and "SimpleActivatedAbility" in ability_classes
    ):
        if "RemoveCountersSourceCost" in cost_classes and "GainControlTargetEffect" in effect_classes:
            return {
                "effect": "tutor",
                "scope": "artifact_wish_counter_any_tutor_to_hand_then_opponent_gains_control_v1",
                "ability_kind": "activated",
                "fields": {
                    "activated_tutor_to_hand": True,
                    "activation_cost_generic": _first_int(r"GenericManaCost\((\d+)\)", rules_text) or 1,
                    "activation_requires_tap": True,
                    "activation_removes_counter": "wish",
                    "activation_condition": "your_turn",
                    "enters_with_counters": {"wish": 3},
                    "tutor_target": "any_to_hand",
                    "tutor_destination": "hand",
                    "opponent_gains_control_after_activation": True,
                },
                "reason": "XMage structure matches Wishclaw-style activated any-card tutor with wish counters and opponent-control rider.",
                "signals": ["SearchLibraryPutInHandEffect", "RemoveCountersSourceCost", "GainControlTargetEffect"],
            }

        if "SacrificeSourceCost" not in cost_classes:
            return None

        activation_cost_generic = _first_int(r"GenericManaCost\((\d+)\)", rules_text)
        if (
            xmage_class_name == "MoonsilverKey"
            or "artifact card with a mana ability or a basic land card" in normalized
            or ("input.island(game)" in normalized and "input.isbasic(game)" in normalized)
            or "anymatch(manaability.class::isinstance)" in normalized
        ):
            return {
                "effect": "ramp_permanent",
                "scope": "activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1",
                "ability_kind": "activated",
                "fields": {
                    "activated_self_sacrifice_tutor_to_hand": True,
                    "activation_cost_generic": activation_cost_generic if activation_cost_generic is not None else 1,
                    "activation_requires_tap": True,
                    "tutor_target": "artifact_mana_ability_or_basic_land",
                    "tutor_destination": "hand",
                },
                "reason": "XMage structure matches an activated artifact that pays mana, taps, sacrifices itself, and tutors either a mana-ability artifact or a basic land into hand.",
                "signals": [
                    "SimpleActivatedAbility",
                    "SearchLibraryPutInHandEffect",
                    "TapSourceCost",
                    "SacrificeSourceCost",
                    "ManaAbility",
                    "basic_land_or_mana_artifact_filter",
                ],
            }

        if (
            xmage_class_name == "ExpeditionMap"
            or "filterlandcard" in normalized
            or "land card" in normalized
        ):
            return {
                "effect": "ramp_permanent",
                "scope": "activated_self_sacrifice_land_tutor_to_hand_artifact_v1",
                "ability_kind": "activated",
                "fields": {
                    "activated_self_sacrifice_tutor_to_hand": True,
                    "activation_cost_generic": activation_cost_generic if activation_cost_generic is not None else 2,
                    "activation_requires_tap": True,
                    "tutor_target": "land",
                    "tutor_destination": "hand",
                },
                "reason": "XMage structure matches an activated artifact that pays mana, taps, sacrifices itself, and tutors a land card into hand.",
                "signals": [
                    "SimpleActivatedAbility",
                    "SearchLibraryPutInHandEffect",
                    "TapSourceCost",
                    "SacrificeSourceCost",
                    "FilterLandCard",
                ],
            }

    if card_types in ({"INSTANT"}, {"SORCERY"}):
        is_instant = card_types == {"INSTANT"}

        if effect_classes == {"SearchLibraryPutInHandEffect"} and not ability_classes:
            if not cost_classes:
                if "filterlandcard" in normalized or "land card" in normalized:
                    return {
                        "effect": "tutor",
                        "scope": "land_tutor_to_hand_v1",
                        "ability_kind": "one_shot",
                        "fields": {
                            "instant": is_instant,
                            "target": "land_to_hand",
                        },
                        "reason": "XMage structure matches a spell that finds a land card and puts it into its controller's hand.",
                        "signals": [
                            "SearchLibraryPutInHandEffect",
                            "FilterLandCard",
                        ],
                    }

                return {
                    "effect": "tutor",
                    "scope": "any_tutor_to_hand_v1",
                    "ability_kind": "one_shot",
                    "fields": {
                        "instant": is_instant,
                        "target": "any_to_hand",
                    },
                    "reason": "XMage structure matches a spell that finds any card and puts it into its controller's hand.",
                    "signals": ["SearchLibraryPutInHandEffect"],
                }

            if cost_classes == {"SacrificeTargetCost"}:
                return {
                    "effect": "tutor",
                    "scope": "sacrifice_creature_any_tutor_to_hand_v1",
                    "ability_kind": "one_shot",
                    "fields": {
                        "instant": is_instant,
                        "target": "any_to_hand",
                        "requires_sacrifice_creature": True,
                    },
                    "reason": "XMage structure matches a spell that sacrifices a creature as an additional cost to tutor any card into hand.",
                    "signals": [
                        "SearchLibraryPutInHandEffect",
                        "SacrificeTargetCost",
                    ],
                }

        return None

    if card_types != {"CREATURE"}:
        return None

    if (
        xmage_class_name == "ScholarOfNewHorizons"
        and "SimpleActivatedAbility" in ability_classes
        and {"OneShotEffect", "ScholarOfNewHorizonsEffect"}.issubset(effect_classes)
        and {"TapSourceCost", "RemoveCounterCost"}.issubset(cost_classes)
        and "entersbattlefieldwithcountersability(countertype.p1p1.createinstance(1))" in normalized
        and "new filterlandcard(" in normalized
        and "plains card" in normalized
        and "subtype.plains.getpredicate()" in normalized
        and "opponentcontrolsmorecondition(staticfilters.filter_land)" in normalized
        and "onto the battlefield tapped" in normalized
        and "put it into your hand" in normalized
    ):
        return {
            "effect": "creature",
            "scope": "activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1",
            "ability_kind": "activated",
            "fields": {
                "power": 1,
                "toughness": 1,
                "enters_with_plus_one_counter_count": 1,
                "land_tutor_to_hand_activated": True,
                "activation_cost_generic": 0,
                "activation_requires_tap": True,
                "activation_requires_remove_plus_one_counter_from_controlled_permanent": True,
                "activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands": True,
                "tutor_target": "plains",
                "tutor_destination": "hand",
            },
            "reason": "XMage structure matches Scholar of New Horizons: ETB +1/+1 counter, tap and remove a counter from a controlled permanent, then tutor a Plains card to hand or directly onto the battlefield tapped when behind on lands.",
            "signals": [
                "ScholarOfNewHorizonsEffect",
                "EntersBattlefieldWithCountersAbility(+1/+1)",
                "RemoveCounterCost",
                "FilterLandCard(Plains)",
                "OpponentControlsMoreCondition",
                "Zone.BATTLEFIELD",
                "Zone.HAND",
            ],
        }

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and "EntersBattlefieldTriggeredAbility" in ability_classes
        and not cost_classes
        and "opponentcontrolsmorecondition(staticfilters.filter_lands)" in normalized
        and "searchlibraryputinplayeffect" in normalized
        and (
            xmage_class_name == "KnightOfTheWhiteOrchid"
            or xmage_class_name == "LoyalWarhound"
        )
    ):
        tutor_target = "basic_plains" if xmage_class_name == "LoyalWarhound" else "plains"
        power = 3 if xmage_class_name == "LoyalWarhound" else 2
        toughness = 1 if xmage_class_name == "LoyalWarhound" else 2
        keywords = ["vigilance"] if xmage_class_name == "LoyalWarhound" else ["first_strike"]
        return {
            "effect": "creature",
            "scope": "etb_opponent_more_lands_plains_to_battlefield_tapped_v1",
            "ability_kind": "triggered",
            "fields": {
                "power": power,
                "toughness": toughness,
                "etb_land_ramp_count": 1,
                "etb_land_ramp_condition": "opponent_controls_more_lands",
                "land_enters_tapped": True,
                "tutor_target": tutor_target,
                "keywords": keywords,
            },
            "reason": (
                "XMage structure matches a white creature with an ETB trigger that checks whether an opponent "
                "controls more lands and then tutors a Plains card onto the battlefield tapped."
            ),
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "OpponentControlsMoreCondition",
                "SearchLibraryPutInPlayEffect",
                "Zone.BATTLEFIELD",
                "tapped",
            ],
        }

    if "SearchLibraryPutInHandEffect" not in effect_classes:
        return None

    if (
        "SimpleActivatedAbility" in ability_classes
        and {"PayLifeCost", "SacrificeTargetCost"}.issubset(cost_classes)
    ):
        return {
            "effect": "creature",
            "scope": "activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1",
            "ability_kind": "activated",
            "fields": {
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text),
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text),
                "activated_tutor_to_hand": True,
                "activation_pay_life": _first_int(r"PayLifeCost\((\d+)\)", rules_text) or 2,
                "activation_requires_sacrifice_creature": True,
                "tutor_target": "any_to_hand",
                "tutor_destination": "hand",
            },
            "reason": "XMage structure matches an activated creature that pays life and sacrifices another creature to tutor any card to hand.",
            "signals": ["SearchLibraryPutInHandEffect", "PayLifeCost", "SacrificeTargetCost"],
        }

    if (
        "ActivateIfConditionActivatedAbility" in ability_classes
        and "TapSourceCost" in cost_classes
        and (
            xmage_class_name == "WeatheredWayfarer"
            or (
                "opponentcontrolsmorecondition" in normalized
                and "filter_card_land_a" in normalized
            )
        )
    ):
        return {
            "effect": "creature",
            "scope": "activated_opponent_more_lands_land_tutor_to_hand_creature_v1",
            "ability_kind": "activated",
            "fields": {
                "power": 1,
                "toughness": 1,
                "land_tutor_to_hand_activated": True,
                "activation_cost_generic": 0,
                "activation_cost_colors": ["W"],
                "activation_requires_tap": True,
                "activation_condition": "opponent_controls_more_lands",
                "tutor_target": "land",
                "tutor_destination": "hand",
            },
            "reason": "XMage structure matches Weathered Wayfarer's activated land tutor to hand that requires an opponent to control more lands.",
            "signals": [
                "ActivateIfConditionActivatedAbility",
                "OpponentControlsMoreCondition",
                "SearchLibraryPutInHandEffect",
                "FILTER_CARD_LAND_A",
                "TapSourceCost",
                "ManaCostsImpl({W})",
            ],
        }

    if "EntersBattlefieldTriggeredAbility" not in ability_classes or cost_classes:
        return None

    if (
        xmage_class_name == "Spellseeker"
        or (
            "filterinstantorsorcerycard" in normalized
            and "manavaluepredicate(comparisontype.fewer_than,3)" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1",
            "ability_kind": "triggered",
            "fields": {
                "power": 1,
                "toughness": 1,
                "etb_tutor_target": "cheap_instant_or_sorcery",
                "etb_tutor_status": "runtime_library_to_hand",
                "oracle_runtime_scope": "creature_etb_instant_or_sorcery_mana_value_lte_2_to_hand_runtime",
            },
            "reason": "XMage structure matches Spellseeker's ETB tutor for an instant or sorcery card with mana value 2 or less into hand.",
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "SearchLibraryPutInHandEffect",
                "FilterInstantOrSorceryCard",
                "ManaValuePredicate(<3)",
            ],
        }

    if (
        xmage_class_name == "TrophyMage"
        or (
            "cardtype.artifact.getpredicate()" in normalized
            and "manavaluepredicate(comparisontype.equal_to,3)" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "trophy_mage_etb_artifact_mana_value_3_to_hand_v1",
            "ability_kind": "triggered",
            "fields": {
                "power": 2,
                "toughness": 2,
                "etb_tutor_target": "artifact_mana_value_3",
                "etb_tutor_status": "runtime_library_to_hand",
                "oracle_runtime_scope": "creature_etb_artifact_mana_value_3_to_hand_runtime",
            },
            "reason": "XMage structure matches Trophy Mage's ETB tutor for an artifact card with mana value 3 into hand.",
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "SearchLibraryPutInHandEffect",
                "CardType.ARTIFACT",
                "ManaValuePredicate(=3)",
            ],
        }

    if (
        xmage_class_name == "StarfieldShepherd"
        or (
            "supertype.basic.getpredicate()" in normalized
            and "subtype.plains.getpredicate()" in normalized
            and "cardtype.creature.getpredicate()" in normalized
            and "manavaluepredicate(comparisontype.fewer_than,2)" in normalized
            and "warpability" in normalized
        )
    ):
        return {
            "effect": "creature",
            "scope": "starfield_shepherd_etb_basic_plains_or_creature_mana_value_1_or_less_to_hand_v1",
            "ability_kind": "triggered",
            "fields": {
                "power": 3,
                "toughness": 2,
                "etb_tutor_target": "basic_plains_or_creature_mana_value_1_or_less",
                "etb_tutor_status": "runtime_library_to_hand",
                "oracle_runtime_scope": (
                    "creature_etb_basic_plains_or_creature_mana_value_1_or_less_to_hand_runtime"
                ),
            },
            "reason": (
                "XMage structure matches Starfield Shepherd's ETB tutor for a basic Plains card "
                "or a creature card with mana value 1 or less into hand while preserving its "
                "Flying and Warp static abilities."
            ),
            "signals": [
                "EntersBattlefieldTriggeredAbility",
                "SearchLibraryPutInHandEffect",
                "SuperType.BASIC",
                "SubType.PLAINS",
                "CardType.CREATURE",
                "ManaValuePredicate(<2)",
                "WarpAbility",
            ],
        }

    if (
        "EntersBattlefieldTriggeredAbility" in ability_classes
        and effect_classes == {"SearchLibraryPutInHandEffect"}
        and not cost_classes
    ):
        target = tutor_target()
        return {
            "effect": "creature",
            "scope": "etb_tutor_to_hand_creature_variant_v1",
            "ability_kind": "triggered",
            "fields": {
                "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text),
                "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text),
                "etb_tutor_target": target,
                "tutor_destination": "hand",
            },
            "reason": "XMage structure matches a creature ETB tutor-to-hand variant with target constraints preserved after exact ETB tutor scopes are excluded.",
            "signals": ["SearchLibraryPutInHandEffect", "EntersBattlefieldTriggeredAbility", target],
        }

    return None


def _build_tutor_to_battlefield_fields(
    *,
    xmage_class_name: str,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    normalized = _normalized_rules_text(rules_text)
    is_instant = card_types == {"INSTANT"}

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"SearchLibraryWithLessCMCPutInPlayEffect"}
        and "ConvokeAbility" in ability_classes
        and (
            xmage_class_name == "ChordOfCalling"
            or "filter_card_creature" in normalized
        )
    ):
        return {
            "effect": "tutor",
            "scope": "convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": True,
                "target": "creature_to_battlefield",
                "target_mana_value_max_from_x": True,
                "convoke": True,
            },
            "reason": "XMage structure matches Chord of Calling tutoring a creature with mana value X or less directly onto the battlefield, with convoke as an additional cost mechanic.",
            "signals": [
                "SearchLibraryWithLessCMCPutInPlayEffect",
                "ConvokeAbility",
                "FILTER_CARD_CREATURE",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and {"SearchLibraryWithLessCMCPutInPlayEffect", "ShuffleSpellEffect"}.issubset(effect_classes)
        and not ability_classes
        and (
            xmage_class_name == "GreenSunsZenith"
            or (
                "green creature card" in normalized
                and "colorpredicate(objectcolor.green)" in normalized
            )
        )
    ):
        return {
            "effect": "tutor",
            "scope": "green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": False,
                "target": "green_creature_to_battlefield",
                "target_mana_value_max_from_x": True,
                "shuffle_self_into_library_on_resolution": True,
            },
            "reason": "XMage structure matches Green Sun's Zenith finding a green creature card with mana value X or less onto the battlefield and then shuffling itself into its owner's library.",
            "signals": [
                "SearchLibraryWithLessCMCPutInPlayEffect",
                "ShuffleSpellEffect",
                "green_creature_filter",
            ],
        }

    if (
        card_types == {"INSTANT"}
        and effect_classes == {"SearchLibraryWithLessCMCPutInPlayEffect"}
        and "ImproviseAbility" in ability_classes
        and (
            xmage_class_name == "WhirOfInvention"
            or "filter_card_artifact" in normalized
        )
    ):
        return {
            "effect": "tutor",
            "scope": "improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": True,
                "target": "artifact_to_battlefield",
                "target_mana_value_max_from_x": True,
                "improvise": True,
            },
            "reason": "XMage structure matches Whir of Invention tutoring an artifact with mana value X or less directly onto the battlefield, with improvise as an additional cost mechanic.",
            "signals": [
                "SearchLibraryWithLessCMCPutInPlayEffect",
                "ImproviseAbility",
                "FILTER_CARD_ARTIFACT",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and not ability_classes
        and xmage_class_name == "DeathbellowWarCry"
        and (
            "targetcardwithdifferentnameinlibrary(0, 4" in normalized
            or "minotaur creature cards with different names" in normalized
        )
    ):
        return {
            "effect": "tutor",
            "scope": "up_to_four_different_name_minotaur_creatures_to_battlefield_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": False,
                "target": "minotaur_creatures_to_battlefield",
                "target_subtypes": ["minotaur"],
                "target_card_types": ["creature"],
                "tutor_destination": "battlefield",
                "max_targets": 4,
                "min_targets": 0,
                "requires_different_names": True,
            },
            "reason": "XMage structure matches Deathbellow War Cry tutoring up to four Minotaur creature cards with different names directly onto the battlefield.",
            "signals": [
                "SearchLibraryPutInPlayEffect",
                "TargetCardWithDifferentNameInLibrary",
                "FilterCreatureCard",
                "SubType.MINOTAUR",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and "HarmonizeAbility" in ability_classes
        and (
            xmage_class_name == "NaturesRhythm"
            or (
                "creature card with mana value x or less" in normalized
                and "getxvalue.instance.calculate" in normalized
            )
        )
    ):
        return {
            "effect": "tutor",
            "scope": "creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": False,
                "target": "creature_to_battlefield",
                "target_mana_value_max_from_x": True,
                "harmonize": True,
            },
            "reason": "XMage structure matches Nature's Rhythm tutoring a creature card with mana value X or less directly onto the battlefield, plus its harmonize ability annotation.",
            "signals": [
                "SearchLibraryPutInPlayEffect",
                "HarmonizeAbility",
                "GetXValue",
                "creature_card_mana_value_x_or_less",
            ],
        }

    if (
        card_types == {"SORCERY"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and not ability_classes
        and xmage_class_name == "DeathbellowWarCry"
        and (
            "targetcardwithdifferentnameinlibrary(0, 4" in normalized
            or "minotaur creature cards with different names" in normalized
        )
    ):
        return {
            "effect": "tutor",
            "scope": "up_to_four_different_name_minotaur_creatures_to_battlefield_v1",
            "ability_kind": "one_shot",
            "fields": {
                "instant": False,
                "target": "minotaur_creatures_to_battlefield",
                "target_subtypes": ["minotaur"],
                "target_card_types": ["creature"],
                "tutor_destination": "battlefield",
                "max_targets": 4,
                "min_targets": 0,
                "requires_different_names": True,
            },
            "reason": "XMage structure matches Deathbellow War Cry tutoring up to four Minotaur creature cards with different names directly onto the battlefield.",
            "signals": [
                "SearchLibraryPutInPlayEffect",
                "TargetCardWithDifferentNameInLibrary",
                "FilterCreatureCard",
                "SubType.MINOTAUR",
            ],
        }

    return None


def _build_extra_turn_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types not in ({"INSTANT"}, {"SORCERY"}):
        return None
    if effect_classes != {"AddExtraTurnControllerEffect"} or ability_classes or cost_classes:
        return None
    normalized = _normalized_rules_text(rules_text)
    if not (
        "addextraturncontrollereffect(true)" in normalized
        or (
            "lose the game" in normalized
            and (
                "extra turn after this one" in normalized
                or "take an extra turn after this one" in normalized
            )
        )
    ):
        return None
    return {
        "effect": "extra_turn",
        "scope": "single_extra_turn_then_lose_game_v1",
        "fields": {
            "instant": card_types == {"INSTANT"},
            "turns": 1,
            "lose_after_extra_turn": True,
        },
        "reason": "XMage structure matches a spell that grants one extra turn and causes its controller to lose the game at that turn's end step.",
        "signals": [
            "AddExtraTurnControllerEffect",
            "lose_the_game_after_extra_turn",
        ],
    }


def _build_dig_to_hand_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    raw_excerpt: str,
) -> dict[str, Any] | None:
    if card_types not in ({"INSTANT"}, {"SORCERY"}):
        return None
    if effect_classes != {"LookLibraryAndPickControllerEffect"} or ability_classes or cost_classes:
        return None

    match = re.search(
        r"LookLibraryAndPickControllerEffect\(\s*(\d+)\s*,\s*(\d+)\s*,\s*PutCards\.HAND\s*,\s*PutCards\.GRAVEYARD\s*\)",
        str(raw_excerpt or ""),
    )
    if not match:
        return None

    look_count = int(match.group(1))
    pick_count = int(match.group(2))
    if look_count <= 0 or pick_count <= 0 or pick_count > look_count:
        return None

    return {
        "effect": "dig_to_hand",
        "scope": "look_top_n_pick_m_to_hand_rest_graveyard_v1",
        "fields": {
            "instant": card_types == {"INSTANT"},
            "look_count": look_count,
            "pick_count": pick_count,
            "selection_destination": "hand",
            "remainder_destination": "graveyard",
        },
        "reason": "XMage structure matches a top-of-library dig spell that puts a chosen subset into hand and sends the rest to the graveyard.",
        "signals": [
            "LookLibraryAndPickControllerEffect",
            f"look_{look_count}",
            f"pick_{pick_count}",
            "hand_then_graveyard",
        ],
    }


def _build_pile_selection_draw_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    raw_excerpt: str,
) -> dict[str, Any] | None:
    if card_types not in ({"INSTANT"}, {"SORCERY"}):
        return None
    if effect_classes != {"RevealAndSeparatePilesEffect"} or ability_classes or cost_classes:
        return None

    match = re.search(
        r"RevealAndSeparatePilesEffect\(\s*(\d+)\s*,\s*TargetController\.(\w+)\s*,\s*TargetController\.(\w+)\s*,\s*Zone\.(\w+)\s*\)",
        str(raw_excerpt or ""),
        re.S,
    )
    if not match:
        return None

    look_count = int(match.group(1))
    splitter_raw = str(match.group(2) or "").upper()
    chooser_raw = str(match.group(3) or "").upper()
    remainder_zone_raw = str(match.group(4) or "").upper()

    role_map = {
        "YOU": "controller",
        "OPPONENT": "opponent",
    }
    splitter = role_map.get(splitter_raw)
    chooser = role_map.get(chooser_raw)
    if look_count <= 0 or splitter is None or chooser is None or remainder_zone_raw != "GRAVEYARD":
        return None

    return {
        "effect": "pile_selection_draw",
        "scope": "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1",
        "fields": {
            "instant": card_types == {"INSTANT"},
            "look_count": look_count,
            "splitter": splitter,
            "chooser": chooser,
            "selection_destination": "hand",
            "remainder_destination": "graveyard",
            "pile_count": 2,
        },
        "reason": "XMage structure matches a reveal-top-cards spell that separates them into two piles and moves the chosen pile to hand with the rest to the graveyard.",
        "signals": [
            "RevealAndSeparatePilesEffect",
            f"look_{look_count}",
            f"splitter_{splitter}",
            f"chooser_{chooser}",
            "hand_rest_graveyard",
        ],
    }


def _build_basic_ritual_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    condition_classes: set[str],
    card_subtypes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"INSTANT"} or "BasicManaEffect" not in effect_classes:
        return None

    normalized = _normalized_rules_text(rules_text)

    if (
        effect_classes == {"BasicManaEffect", "ConditionalManaEffect"}
        and "ThresholdCondition" in condition_classes
        and "mana.blackmana(5)" in normalized
        and "mana.blackmana(3)" in normalized
    ):
        return {
            "effect": "ramp_ritual",
            "scope": "threshold_three_or_five_black_mana_ritual_v1",
            "fields": {
                "instant": True,
                "mana_produced": 3,
                "produces": "B",
                "threshold_graveyard_count": 7,
                "threshold_mana_produced": 5,
            },
            "reason": "XMage structure matches Cabal Ritual adding three black mana, or five black mana with threshold.",
            "signals": ["ConditionalManaEffect", "BasicManaEffect", "ThresholdCondition", "BlackMana(3)", "BlackMana(5)"],
        }

    if effect_classes != {"BasicManaEffect"}:
        return None

    if "mana.blackmana(3)" in normalized:
        return {
            "effect": "ramp_ritual",
            "scope": "three_black_mana_ritual_v1",
            "fields": {
                "instant": True,
                "mana_produced": 3,
                "produces": "B",
            },
            "reason": "XMage structure matches a one-shot ritual that adds three black mana.",
            "signals": ["BasicManaEffect", "BlackMana(3)"],
        }

    if (
        "mana.redmana(3)" in normalized
        and ability_classes == {"SpliceAbility"}
        and "ARCANE" in card_subtypes
        and "spliceability" in normalized
        and "arcane" in normalized
        and "{1}{r}" in normalized
    ):
        return {
            "effect": "ramp_ritual",
            "scope": "three_red_mana_arcane_splice_ritual_v1",
            "fields": {
                "instant": True,
                "mana_produced": 3,
                "produces": "R",
                "subtype_arcane": True,
                "splice_arcane_cost": "{1}{R}",
            },
            "reason": "XMage structure matches an Arcane ritual that adds three red mana and carries splice onto Arcane for {1}{R}.",
            "signals": ["BasicManaEffect", "RedMana(3)", "SpliceAbility", "SubType.ARCANE"],
        }

    if "mana.redmana(3)" in normalized:
        return {
            "effect": "ramp_ritual",
            "scope": "three_red_mana_ritual_v1",
            "fields": {
                "instant": True,
                "mana_produced": 3,
                "produces": "R",
            },
            "reason": "XMage structure matches a one-shot ritual that adds three red mana.",
            "signals": ["BasicManaEffect", "RedMana(3)"],
        }

    return None


def _build_rishkar_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"CREATURE"}:
        return None
    if "AddCountersTargetEffect" not in effect_classes or "GainAbilityControlledEffect" not in effect_classes:
        return None
    if not {"EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes):
        return None
    if not (
        _oracle_has(
            rules_text,
            "put a +1/+1 counter on each of up to two target creatures",
            'each creature you control with a counter on it has "{t}: add {g}."',
        )
        or (
            "counteranypredicate" in _normalized_rules_text(rules_text)
            and "greenmanaability" in _normalized_rules_text(rules_text)
        )
    ):
        return None
    return {
        "effect": "creature",
        "scope": "rishkar_counter_mana_creature_waiver_v1",
        "fields": {
            "power": 2,
            "toughness": 2,
            "etb_plus_one_counter_targets": 2,
            "countered_creatures_tap_for_mana": True,
            "produces": "G",
        },
        "reason": (
            "XMage structure matches Rishkar ETB +1/+1 counters on up to two targets plus the "
            "static mana ability for your creatures with counters."
        ),
        "signals": [
            "AddCountersTargetEffect",
            "GainAbilityControlledEffect",
            "GreenManaAbility",
        ],
    }


def _build_creatures_tap_any_color_static_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if "GainAbilityControlledEffect" not in effect_classes:
        return None
    normalized_text = _normalized_rules_text(rules_text)

    shared_match = (
        _oracle_has(rules_text, 'each creature you control has "{t}: add one mana of any color."')
        or (
            "gainabilitycontrolledeffect" in normalized_text
            and "anycolormanaability" in normalized_text
            and "filter_permanent_creatures" in normalized_text
        )
    )
    if not shared_match:
        return None

    if card_types == {"ENCHANTMENT"} and ability_classes == {"AnyColorManaAbility", "SimpleStaticAbility"}:
        return {
            "effect": "passive",
            "scope": "creatures_tap_any_color_static_enchantment_v1",
            "fields": {
                "creatures_tap_for_any_color": True,
            },
            "reason": "XMage structure matches a static enchantment that gives each creature you control a tap-for-any-color mana ability.",
            "signals": ["GainAbilityControlledEffect", "AnyColorManaAbility", "SimpleStaticAbility", "FILTER_PERMANENT_CREATURES"],
        }

    if (
        card_types == {"CREATURE", "ENCHANTMENT"}
        and {"AnyColorManaAbility", "SimpleStaticAbility", "VigilanceAbility"}.issubset(ability_classes)
        and 'this.power = new mageint(3)' in normalized_text
        and 'this.toughness = new mageint(3)' in normalized_text
    ):
        return {
            "effect": "creature",
            "scope": "vigilance_three_three_creatures_tap_any_color_v1",
            "fields": {
                "power": 3,
                "toughness": 3,
                "vigilance": True,
                "creatures_tap_for_any_color": True,
                "death_return_status": "annotation_only",
            },
            "reason": "XMage structure matches a 3/3 vigilance enchantment creature that gives each creature you control a tap-for-any-color mana ability while keeping its extra death-return clause annotation-only.",
            "signals": ["GainAbilityControlledEffect", "AnyColorManaAbility", "SimpleStaticAbility", "VigilanceAbility", "MageInt(3)"],
        }

    return None


def _build_magda_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    cost_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"CREATURE"}:
        return None
    if not {
        "BoostControlledEffect",
        "CreateTokenEffect",
        "SearchLibraryPutInPlayEffect",
    }.issubset(effect_classes):
        return None
    if not {
        "BecomesTappedTriggeredAbility",
        "SimpleActivatedAbility",
        "SimpleStaticAbility",
    }.issubset(ability_classes):
        return None
    if "SacrificeTargetCost" not in cost_classes:
        return None
    normalized_text = _normalized_rules_text(rules_text)
    if not (
        _oracle_has(
            rules_text,
            "other dwarves you control get +1/+0",
            "whenever a dwarf you control becomes tapped, create a treasure token",
            "sacrifice five treasures",
            "search your library for an artifact or dragon card",
            "put that card onto the battlefield",
        )
        or (
            "becomestappedtriggeredability" in normalized_text
            and "treasuretoken" in normalized_text
            and "searchlibraryputinplayeffect" in normalized_text
            and "subtype.dwarf" in normalized_text
            and "subtype.treasure" in normalized_text
            and "subtype.dragon" in normalized_text
        )
    ):
        return None
    return {
        "effect": "creature",
        "scope": "magda_dwarf_tap_treasure_and_five_treasure_tutor_v1",
        "fields": {
            "power": 2,
            "toughness": 1,
            "other_dwarves_you_control_get_plus_one_power": True,
            "controlled_dwarf_becomes_tapped_creates_treasure": True,
            "activated_sacrifice_five_treasures_tutor_artifact_or_dragon": True,
            "activated_treasure_tutor_cost": 5,
            "activated_treasure_tutor_destination": "battlefield",
        },
        "reason": (
            "XMage structure matches Magda's Dwarf lord text, the tapped-Dwarf Treasure trigger, "
            "and the five-Treasures activated tutor for an artifact or Dragon onto the battlefield."
        ),
        "signals": [
            "BoostControlledEffect",
            "BecomesTappedTriggeredAbility",
            "CreateTokenEffect",
            "SearchLibraryPutInPlayEffect",
            "SacrificeTargetCost",
        ],
    }


def _build_insidious_roots_fields(
    *,
    card_types: set[str],
    effect_classes: set[str],
    ability_classes: set[str],
    rules_text: str,
) -> dict[str, Any] | None:
    if card_types != {"ENCHANTMENT"}:
        return None
    if not {
        "AddCountersAllEffect",
        "CreateTokenEffect",
        "GainAbilityControlledEffect",
    }.issubset(effect_classes):
        return None
    if not {"CardsLeaveGraveyardTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes):
        return None
    normalized_text = _normalized_rules_text(rules_text)
    if not (
        _oracle_has(
            rules_text,
            'creature tokens you control have "{t}: add one mana of any color."',
            "whenever one or more creature cards leave your graveyard, create a 0/1 green plant creature token, then put a +1/+1 counter on each plant you control.",
        )
        or (
            "anycolormanaability" in normalized_text
            and "planttoken" in normalized_text
            and "cardsleavegraveyardtriggeredability" in normalized_text
        )
    ):
        return None
    return {
        "effect": "passive",
        "scope": "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1",
        "fields": {
            "creature_tokens_tap_for_any_color": True,
            "creature_cards_leave_your_graveyard_create_plant_token": True,
            "plant_tokens_get_plus_one_counter_on_creature_graveyard_exit": True,
            "trigger_once_each_graveyard_exit_event": True,
            "token_name": "Plant Token",
            "token_subtype": "Plant",
            "token_power": 0,
            "token_toughness": 1,
            "token_colors": ["G"],
        },
        "reason": (
            "XMage structure matches Insidious Roots granting creature tokens an any-color mana tap ability "
            "plus the one-or-more creature cards leave your graveyard trigger that creates a Plant and grows all Plants."
        ),
        "signals": [
            "AnyColorManaAbility",
            "CardsLeaveGraveyardTriggeredAbility",
            "PlantToken",
        ],
    }


def build_effect_hints(index_entry: dict[str, Any], oracle_text: str = "") -> dict[str, Any]:
    """Return conservative ManaLoom hints for one parsed XMage card entry."""

    rules_text = _combined_rules_text(index_entry, oracle_text)
    effect_classes = _as_set(index_entry.get("effect_classes"))
    ability_classes = _as_set(index_entry.get("ability_classes"))
    target_classes = _as_set(index_entry.get("target_classes"))
    filter_classes = _as_set(index_entry.get("filter_classes"))
    condition_classes = _as_set(index_entry.get("condition_classes"))
    counter_types = _as_set(index_entry.get("counter_types"))
    cost_classes = _as_set(index_entry.get("cost_classes"))
    dynamic_value_classes = _as_set(index_entry.get("dynamic_value_classes"))
    inner_extends = _inner_extends(index_entry)
    ability_kind = _ability_kind(ability_classes)
    target_constraints = _target_constraints(target_classes, filter_classes)
    card_types = _constructor_card_types(index_entry)
    xmage_class_name = str(
        index_entry.get("xmage_class_name") or index_entry.get("class_name") or ""
    ).strip()
    normalized_text = _normalized_rules_text(rules_text)
    normalized_imports = _normalized_rules_text(" ".join(str(value or "") for value in index_entry.get("imports") or []))
    candidates: list[dict[str, Any]] = []

    if (
        xmage_class_name == "GoliathDaydreamer"
        and card_types == {"CREATURE"}
        and {
            "GoliathDaydreamerCastEffect",
            "GoliathDaydreamerExileEffect",
            "OneShotEffect",
        }.issubset(effect_classes)
        and {
            "AttacksTriggeredAbility",
            "SpellCastControllerTriggeredAbility",
        }.issubset(ability_classes)
        and ("DREAM" in counter_types or "countertype.dream" in normalized_text)
    ):
        candidates.append(
            _candidate(
                effect="free_cast",
                scope="instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1",
                reason=(
                    "XMage structure matches Goliath Daydreamer: instant/sorcery spells cast from hand are "
                    "exiled with dream counters instead of going to graveyard, then its attack trigger may "
                    "cast a spell from owned exiled dream-counter cards without paying mana."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 4,
                    "toughness": 4,
                    "trigger": "instant_sorcery_cast_from_hand_and_attack",
                    "spell_cast_from_hand_card_types": ["instant", "sorcery"],
                    "spell_cast_from_hand_exile_instead_of_graveyard": True,
                    "exiled_counter_type": "dream",
                    "attack_may_cast_owned_exiled_card_with_counter_without_paying_mana": True,
                    "attack_free_cast_counter_type": "dream",
                },
                matched_signals=[
                    "SpellCastControllerTriggeredAbility",
                    "AttacksTriggeredAbility",
                    "GoliathDaydreamerExileEffect",
                    "GoliathDaydreamerCastEffect",
                    "CounterType.DREAM",
                ],
            )
        )

    if (
        xmage_class_name == "TwinflameTyrant"
        and card_types == {"CREATURE"}
        and "TwinflameTyrantEffect" in effect_classes
        and "SimpleStaticAbility" in ability_classes
        and "damage_player" in normalized_text
        and "damage_permanent" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="damage_modifier",
                scope="controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1",
                reason=(
                    "XMage structure matches Twinflame Tyrant: a static replacement effect doubles damage "
                    "from sources you control to opponents and permanents opponents control."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 3,
                    "toughness": 5,
                    "flying": True,
                    "damage_multiplier": 2,
                    "damage_modifier_applies_to": "sources_you_control",
                    "damage_modifier_targets": ["opponents", "opponent_permanents"],
                    "damage_modifier_duration": "while_on_battlefield",
                },
                matched_signals=[
                    "SimpleStaticAbility",
                    "TwinflameTyrantEffect",
                    "GameEvent.EventType.DAMAGE_PLAYER",
                    "GameEvent.EventType.DAMAGE_PERMANENT",
                ],
            )
        )

    if (
        xmage_class_name == "GiselaBladeOfGoldnight"
        and card_types == {"CREATURE"}
        and {
            "GiselaBladeOfGoldnightDoubleDamageEffect",
            "GiselaBladeOfGoldnightPreventionEffect",
        }.issubset(effect_classes)
        and "SimpleStaticAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="damage_modifier",
                scope="opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1",
                reason=(
                    "XMage structure matches Gisela, Blade of Goldnight: static replacement effects "
                    "double damage dealt to opponents or permanents opponents control and prevent half, "
                    "rounded up, of damage dealt to you or permanents you control."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 5,
                    "toughness": 5,
                    "flying": True,
                    "first_strike": True,
                    "damage_multiplier": 2,
                    "damage_modifier_applies_to": "any_source",
                    "damage_modifier_targets": ["opponents", "opponent_permanents"],
                    "damage_modifier_duration": "while_on_battlefield",
                    "prevent_half_damage_to_you_and_permanents_you_control": True,
                    "prevent_half_rounding": "rounded_up",
                },
                matched_signals=[
                    "SimpleStaticAbility",
                    "GiselaBladeOfGoldnightDoubleDamageEffect",
                    "GiselaBladeOfGoldnightPreventionEffect",
                    "GameEvent.EventType.DAMAGE_PLAYER",
                    "GameEvent.EventType.DAMAGE_PERMANENT",
                ],
            )
        )

    if (
        xmage_class_name == "VergeRangers"
        and card_types == {"CREATURE"}
        and {
            "LookAtTopCardOfLibraryAnyTimeEffect",
            "PlayFromTopOfLibraryEffect",
            "VergeRangersEffect",
        }.issubset(effect_classes)
        and "SimpleStaticAbility" in ability_classes
        and "opponent controls more lands" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="topdeck_play",
                scope="look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
                reason=(
                    "XMage structure matches Verge Rangers: controller may look at the top card any time and "
                    "may play lands from the top while an opponent controls more lands."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 3,
                    "toughness": 3,
                    "keywords": ["first_strike"],
                    "look_top_library_any_time": True,
                    "play_lands_from_top_library": True,
                    "play_from_top_condition": "opponent_controls_more_lands",
                },
                matched_signals=[
                    "LookAtTopCardOfLibraryAnyTimeEffect",
                    "PlayFromTopOfLibraryEffect",
                    "VergeRangersEffect",
                    "SimpleStaticAbility",
                    "OpponentControlsMoreLands",
                ],
            )
        )

    if (
        xmage_class_name == "LensOfClarity"
        and card_types == {"ARTIFACT"}
        and {
            "LookAtTopCardOfLibraryAnyTimeEffect",
            "LookAtOpponentFaceDownCreaturesAnyTimeEffect",
        }.issubset(effect_classes)
        and "SimpleStaticAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="topdeck_play",
                scope="look_top_library_any_time_and_opponent_face_down_creatures_v1",
                reason=(
                    "XMage structure matches Lens of Clarity: controller may look at the top card of "
                    "their library and opponent face-down creatures, without gaining cast or play permission."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "look_top_library_any_time": True,
                    "look_opponent_face_down_creatures_any_time": True,
                    "play_lands_from_top_library": False,
                    "alternate_zone_permission": False,
                    "may_cast_without_paying_mana_cost": False,
                },
                matched_signals=[
                    "LookAtTopCardOfLibraryAnyTimeEffect",
                    "LookAtOpponentFaceDownCreaturesAnyTimeEffect",
                    "SimpleStaticAbility",
                ],
            )
        )

    if (
        xmage_class_name == "AncientGoldDragon"
        and card_types == {"CREATURE"}
        and "AncientGoldDragonEffect" in effect_classes
        and "DealsCombatDamageToAPlayerTriggeredAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="token_maker",
                scope="source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1",
                reason=(
                    "XMage structure matches Ancient Gold Dragon: combat damage to a player rolls a d20 "
                    "and creates that many 1/1 blue Faerie Dragon creature tokens with flying."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 7,
                    "toughness": 10,
                    "flying": True,
                    "trigger": "combat_damage_to_player",
                    "trigger_effect": "roll_d20_create_tokens",
                    "die_sides": 20,
                    "token_count_source": "d20_result",
                    "token_name": "Faerie Dragon Token",
                    "token_subtype": "Faerie Dragon",
                    "token_colors": ["U"],
                    "token_power": 1,
                    "token_toughness": 1,
                    "token_flying": True,
                },
                matched_signals=[
                    "DealsCombatDamageToAPlayerTriggeredAbility",
                    "AncientGoldDragonEffect",
                    "FaerieDragonToken",
                    "rollDice(20)",
                ],
            )
        )

    if (
        xmage_class_name == "BloodMoon"
        and card_types == {"ENCHANTMENT"}
        and "NonbasicLandsAreMountainsEffect" in effect_classes
        and "SimpleStaticAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="passive",
                scope="nonbasic_lands_are_mountains_static_v1",
                reason=(
                    "XMage structure matches Blood Moon: a static battlefield effect makes nonbasic "
                    "lands Mountains. This is a passive land-type replacement family, not a manual model."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "static_rule_restriction": True,
                    "land_type_replacement": "nonbasic_lands_are_mountains",
                    "affected_lands": "nonbasic",
                    "resulting_basic_land_type": "mountain",
                    "suppresses_non_mountain_land_abilities": True,
                },
                matched_signals=[
                    "SimpleStaticAbility",
                    "NonbasicLandsAreMountainsEffect",
                ],
            )
        )

    if (
        xmage_class_name == "ChandrasIgnition"
        and card_types == {"SORCERY"}
        and "ChandrasIgnitionEffect" in effect_classes
        and "TargetControlledCreaturePermanent" in target_classes
    ):
        candidates.append(
            _candidate(
                effect="sweeper_damage",
                scope="target_controlled_creature_power_damage_each_other_creature_each_opponent_v1",
                reason=(
                    "XMage structure matches Chandra's Ignition: target creature you control deals "
                    "damage equal to its power to each other creature and each opponent."
                ),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                target_constraints={"controller_scope": "source_controller", "card_types": ["creature"]},
                extra_effect_fields={
                    "sorcery": True,
                    "target": "controlled_creature",
                    "damage_amount_source": "target_creature_power",
                    "damage_each_other_creature": True,
                    "damage_each_opponent": True,
                    "damage_source": "target_creature",
                },
                matched_signals=[
                    "ChandrasIgnitionEffect",
                    "TargetControlledCreaturePermanent",
                    "targetCreature.getPower()",
                ],
            )
        )

    if (
        xmage_class_name == "GhoulcallersBell"
        and card_types == {"ARTIFACT"}
        and "MillCardsEachPlayerEffect" in effect_classes
        and "SimpleActivatedAbility" in ability_classes
        and "TapSourceCost" in cost_classes
    ):
        candidates.append(
            _candidate(
                effect="mill_engine",
                scope="artifact_tap_each_player_mill_one_v1",
                reason=(
                    "XMage structure matches Ghoulcaller's Bell: activated tap ability mills one "
                    "card from each player's library."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "artifact": True,
                    "activation_requires_tap": True,
                    "mill_count": 1,
                    "mill_scope": "each_player",
                    "target": "each_player",
                },
                matched_signals=[
                    "SimpleActivatedAbility",
                    "MillCardsEachPlayerEffect",
                    "TapSourceCost",
                ],
            )
        )

    if (
        xmage_class_name == "KarnTheGreatCreator"
        and card_types == {"PLANESWALKER"}
        and {
            "KarnTheGreatCreatorAnimateEffect",
            "KarnTheGreatCreatorCantActivateEffect",
            "WishEffect",
        }.issubset(effect_classes)
        and {"LoyaltyAbility", "SimpleStaticAbility"}.issubset(ability_classes)
    ):
        candidates.append(
            _candidate(
                effect="passive",
                scope="opponent_artifact_activation_lock_planeswalker_wish_v1",
                reason=(
                    "XMage structure matches Karn, the Great Creator: static artifact activation lock "
                    "for opponents plus loyalty animation and artifact wish modes."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                target_constraints={"card_types": ["artifact"]},
                extra_effect_fields={
                    "permanent_type": "planeswalker",
                    "starting_loyalty": 5,
                    "opponent_artifact_activated_abilities_cant_be_activated": True,
                    "plus_one_animates_noncreature_artifact_until_next_turn": True,
                    "minus_two_artifact_wish_or_exile_to_hand": True,
                },
                matched_signals=[
                    "KarnTheGreatCreatorCantActivateEffect",
                    "KarnTheGreatCreatorAnimateEffect",
                    "WishEffect",
                    "LoyaltyAbility",
                ],
            )
        )

    if (
        xmage_class_name == "KaylasMusicBox"
        and card_types == {"ARTIFACT"}
        and {
            "KaylasMusicBoxExileEffect",
            "KaylasMusicBoxLookEffect",
            "KaylasMusicBoxPlayFromExileEffect",
        }.issubset(effect_classes)
        and "SimpleActivatedAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="free_cast",
                scope="artifact_w_tap_exile_top_face_down_tap_play_owned_exiled_until_eot_v1",
                reason=(
                    "XMage structure matches Kayla's Music Box: an activated ability looks at and exiles "
                    "the top library card face down, and a second tap ability allows playing owned cards "
                    "exiled with it until end of turn by paying normal costs."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "legendary": True,
                    "activated_exile_top_card_face_down": True,
                    "activation_cost_mana": "{W}",
                    "activation_requires_tap": True,
                    "exiled_card_look_permission_controller_only": True,
                    "activated_play_owned_cards_exiled_with_source_until_eot": True,
                    "play_from_exile_requires_tap": True,
                    "play_from_exile_duration": "until_end_of_turn",
                    "play_from_exile_owner_scope": "controller_owned_cards_exiled_with_source",
                    "play_lands_from_exile": True,
                    "alternate_zone_permission": True,
                    "may_cast_without_paying_mana_cost": False,
                },
                matched_signals=[
                    "KaylasMusicBoxExileEffect",
                    "KaylasMusicBoxLookEffect",
                    "KaylasMusicBoxPlayFromExileEffect",
                    "PLAY_FROM_NOT_OWN_HAND_ZONE",
                ],
            )
        )

    if (
        xmage_class_name == "LanternOfInsight"
        and card_types == {"ARTIFACT"}
        and {
            "PlayWithTheTopCardRevealedEffect",
            "ShuffleLibraryTargetEffect",
        }.issubset(effect_classes)
        and {"SimpleActivatedAbility", "SimpleStaticAbility"}.issubset(ability_classes)
    ):
        candidates.append(
            _candidate(
                effect="topdeck_play",
                scope="each_player_top_library_revealed_tap_sacrifice_target_player_shuffle_v1",
                reason=(
                    "XMage structure matches Lantern of Insight: static top-library reveal for each "
                    "player plus tap-sacrifice target-player shuffle."
                ),
                ability_kind="static_and_activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "each_player_top_library_revealed": True,
                    "activated_target_player_shuffle_library": True,
                    "activation_requires_tap": True,
                    "activation_requires_sacrifice": True,
                    "target": "player",
                    "play_lands_from_top_library": False,
                    "alternate_zone_permission": False,
                    "may_cast_without_paying_mana_cost": False,
                },
                matched_signals=[
                    "PlayWithTheTopCardRevealedEffect",
                    "ShuffleLibraryTargetEffect",
                    "SimpleStaticAbility",
                    "SimpleActivatedAbility",
                ],
            )
        )

    if (
        xmage_class_name == "LeylineDowser"
        and card_types == {"ARTIFACT"}
        and {"MillThenPutInHandEffect", "UntapSourceEffect"}.issubset(effect_classes)
        and "SimpleActivatedAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="recursion",
                scope="pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1",
                reason=(
                    "XMage structure matches Leyline Dowser: pay and tap to mill one card and optionally "
                    "put an instant or sorcery milled this way into hand, plus tap a legendary creature "
                    "to untap the artifact."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                target_constraints={"controller_scope": "source_controller", "card_types": ["creature"]},
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "activation_cost_generic": 1,
                    "activation_requires_tap": True,
                    "activated_self_mill_count": 1,
                    "mill_count": 1,
                    "milled_card_types_to_hand": ["instant", "sorcery"],
                    "secondary_untap_source_by_tapping_legendary_creature": True,
                },
                matched_signals=[
                    "MillThenPutInHandEffect",
                    "UntapSourceEffect",
                    "TapTargetCost",
                    "FilterControlledCreaturePermanent",
                ],
            )
        )

    if (
        xmage_class_name == "OrcishSpy"
        and card_types == {"CREATURE"}
        and "LookLibraryTopCardTargetPlayerEffect" in effect_classes
        and "SimpleActivatedAbility" in ability_classes
        and "TargetPlayer" in target_classes
    ):
        candidates.append(
            _candidate(
                effect="topdeck_play",
                scope="tap_look_top_three_target_player_library_v1",
                reason=(
                    "XMage structure matches Orcish Spy: activated tap ability looks at the top three "
                    "cards of target player's library."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                target_constraints={"target": "player"},
                extra_effect_fields={
                    "power": 1,
                    "toughness": 1,
                    "activation_requires_tap": True,
                    "look_target_player_library_top_count": 3,
                    "play_lands_from_top_library": False,
                    "alternate_zone_permission": False,
                    "may_cast_without_paying_mana_cost": False,
                },
                matched_signals=[
                    "LookLibraryTopCardTargetPlayerEffect",
                    "TargetPlayer",
                    "TapSourceCost",
                ],
            )
        )

    if (
        xmage_class_name == "PossibilityStorm"
        and card_types == {"ENCHANTMENT"}
        and "PossibilityStormTriggeredAbility" in ability_classes
        and "PossibilityStormEffect" in effect_classes
    ):
        candidates.append(
            _candidate(
                effect="free_cast",
                scope="spell_from_hand_exile_until_shared_type_free_cast_bottom_rest_random_v1",
                reason=(
                    "XMage structure matches Possibility Storm: spell cast from hand is exiled, then "
                    "library cards are exiled until a nonland sharing a card type may be cast for free, "
                    "with the rest bottomed randomly."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "trigger": "spell_cast_from_hand",
                    "trigger_scope": "any_player",
                    "possibility_storm_replacement": True,
                    "exile_original_spell": True,
                    "exile_from_top_until_shares_card_type": True,
                    "hit_card_may_cast_without_paying_mana_cost": True,
                    "bottom_exiled_with_source_random": True,
                    "source_zone_required": "hand",
                    "alternate_zone_permission": True,
                    "may_cast_without_paying_mana_cost": True,
                },
                matched_signals=[
                    "PossibilityStormTriggeredAbility",
                    "PossibilityStormEffect",
                    "GameEvent.EventType.SPELL_CAST",
                    "Zone.HAND",
                ],
            )
        )

    if (
        xmage_class_name == "PrototypePortal"
        and card_types == {"ARTIFACT"}
        and {
            "PrototypePortalEffect",
            "PrototypePortalCreateTokenEffect",
        }.issubset(effect_classes)
        and {"EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
    ):
        candidates.append(
            _candidate(
                effect="token_maker",
                scope="imprint_artifact_from_hand_create_token_copy_x_mana_value_v1",
                reason=(
                    "XMage structure matches Prototype Portal: imprint an artifact card from hand on ETB, "
                    "then pay X and tap to create a token copy where X is the imprinted card's mana value."
                ),
                ability_kind="triggered_and_activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "imprint_artifact_card_from_hand_on_enter": True,
                    "activated_create_token_copy_of_imprinted_card": True,
                    "activation_requires_tap": True,
                    "activation_x_cost_source": "imprinted_card_mana_value",
                    "token_copy_source": "imprinted_card",
                },
                matched_signals=[
                    "PrototypePortalEffect",
                    "PrototypePortalCreateTokenEffect",
                    "ImprintedManaValueXCostAdjuster",
                ],
            )
        )

    if (
        xmage_class_name == "PyxisOfPandemonium"
        and card_types == {"ARTIFACT"}
        and {
            "PyxisOfPandemoniumExileEffect",
            "PyxisOfPandemoniumPutOntoBattlefieldEffect",
        }.issubset(effect_classes)
        and "SimpleActivatedAbility" in ability_classes
    ):
        candidates.append(
            _candidate(
                effect="free_cast",
                scope="tap_each_player_exile_top_face_down_seven_tap_sacrifice_put_exiled_permanents_onto_battlefield_v1",
                reason=(
                    "XMage structure matches Pyxis of Pandemonium: tap to exile each player's top card "
                    "face down, then pay seven, tap, and sacrifice to reveal those cards and put all "
                    "permanent cards among them onto the battlefield."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "activated_each_player_exile_top_face_down": True,
                    "activated_put_exiled_permanents_onto_battlefield": True,
                    "activation_requires_tap": True,
                    "final_activation_requires_sacrifice": True,
                    "final_activation_cost_generic": 7,
                    "alternate_zone_permission": True,
                    "may_cast_without_paying_mana_cost": False,
                    "put_permanent_cards_from_exile_onto_battlefield": True,
                },
                matched_signals=[
                    "PyxisOfPandemoniumExileEffect",
                    "PyxisOfPandemoniumPutOntoBattlefieldEffect",
                    "SacrificeSourceCost",
                    "GenericManaCost(7)",
                ],
            )
        )

    if (
        card_types == {"ENCHANTMENT"}
        and effect_classes == {"DamageTargetEffect"}
        and "DealtDamageAnyTriggeredAbility" in ability_classes
        and (
            xmage_class_name == "Repercussion"
            or (
                "saveddamagevalue.much" in normalized_text
                and "settargetpointer.player" in normalized_text
            )
            or _oracle_has(
                rules_text,
                "whenever a creature is dealt damage",
                "deals that much damage to that creature's controller",
            )
        )
    ):
        candidates.append(
            _candidate(
                effect="passive",
                scope="creature_damage_controller_reflect_global_v1",
                reason=(
                    "XMage structure matches Repercussion: whenever any creature is dealt damage, "
                    "the source enchantment deals that much damage to that creature's controller."
                ),
                ability_kind="triggered_static_enchantment",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "trigger": "creature_dealt_damage",
                    "trigger_effect": "damage_creature_controller",
                    "damage_amount_source": "damage_dealt_to_creature",
                    "global_creature_damage_reflect_to_controller": True,
                },
                matched_signals=[
                    "DealtDamageAnyTriggeredAbility",
                    "DamageTargetEffect",
                    "SavedDamageValue.MUCH",
                    "SetTargetPointer.PLAYER",
                ],
            )
        )

    if (
        xmage_class_name == "BorosReckoner"
        and card_types == {"CREATURE"}
        and {"DamageTargetEffect", "GainAbilitySourceEffect"}.issubset(effect_classes)
        and {
            "DealtDamageToSourceTriggeredAbility",
            "FirstStrikeAbility",
            "SimpleActivatedAbility",
        }.issubset(ability_classes)
        and "SavedDamageValue" in dynamic_value_classes
        and "TargetAnyTarget" in target_classes
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="source_dealt_damage_reflect_to_any_target_v1",
                reason=(
                    "XMage structure matches Boros Reckoner: whenever this source is dealt damage, "
                    "it deals that much damage to any target, with an activated first strike annotation."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": _first_int(r"power\s*=\s*new MageInt\((\d+)\)", rules_text) or 3,
                    "toughness": _first_int(r"toughness\s*=\s*new MageInt\((\d+)\)", rules_text) or 3,
                    "trigger": "source_dealt_damage",
                    "trigger_effect": "damage_any_target",
                    "damage_amount_source": "damage_dealt_to_source",
                    "source_damage_reflect_to_any_target": True,
                    "target": "any_target",
                    "target_constraints": {"scope": "any_target"},
                    "activated_gain_first_strike_until_eot": True,
                    "first_strike_activation_cost": "{R/W}",
                },
                matched_signals=[
                    "DealtDamageToSourceTriggeredAbility",
                    "DamageTargetEffect",
                    "SavedDamageValue.MUCH",
                    "TargetAnyTarget",
                    "GainAbilitySourceEffect",
                    "FirstStrikeAbility",
                ],
            )
        )

    if (
        xmage_class_name == "TroubleInPairs"
        and card_types == {"ENCHANTMENT"}
        and effect_classes == {"DrawCardSourceControllerEffect"}
        and {"SkipExtraTurnsAbility", "TroubleInPairsTriggeredAbility"}.issubset(ability_classes)
        and (
            "cardsdrawnthisturnwatcher" in normalized_text
            or "cardsdrawnthisturnwatcher" in normalized_imports
        )
        and (
            "castspelllastturnwatcher" in normalized_text
            or "castspelllastturnwatcher" in normalized_imports
        )
        and "declared_attackers" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="draw_engine",
                scope="opponent_second_draw_second_spell_two_attackers_draw_v1",
                reason=(
                    "XMage structure matches Trouble in Pairs: skip opponent extra turns and draw when an opponent "
                    "attacks you with two or more creatures, draws their second card, or casts their second spell."
                ),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "draw_count": 1,
                    "skip_opponent_extra_turns": True,
                    "opponent_attacks_you_with_two_or_more_creatures_draw": True,
                    "opponent_second_card_draw_each_turn": True,
                    "opponent_second_spell_each_turn": True,
                    "trigger": "opponent_second_spell",
                    "tax": 0,
                    "tax_payment_status": "not_applicable",
                },
                matched_signals=[
                    "SkipExtraTurnsAbility",
                    "TroubleInPairsTriggeredAbility",
                    "CardsDrawnThisTurnWatcher",
                    "CastSpellLastTurnWatcher",
                    "DrawCardSourceControllerEffect",
                ],
            )
        )

    if (
        xmage_class_name == "ScholarOfNewHorizons"
        and card_types == {"CREATURE"}
        and "SimpleActivatedAbility" in ability_classes
        and {"OneShotEffect", "ScholarOfNewHorizonsEffect"}.issubset(effect_classes)
        and {"TapSourceCost", "RemoveCounterCost"}.issubset(cost_classes)
        and "entersbattlefieldwithcountersability(countertype.p1p1.createinstance(1))" in normalized_text
        and "plains card" in normalized_text
        and "subtype.plains.getpredicate()" in normalized_text
        and "opponentcontrolsmorecondition(staticfilters.filter_land)" in normalized_text
        and "onto the battlefield tapped" in normalized_text
        and "put it into your hand" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1",
                reason=(
                    "XMage structure matches Scholar of New Horizons: ETB +1/+1 counter, tap and remove a "
                    "counter from a controlled permanent, then tutor a Plains card to hand or directly onto "
                    "the battlefield tapped when behind on lands."
                ),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 1,
                    "toughness": 1,
                    "enters_with_plus_one_counter_count": 1,
                    "land_tutor_to_hand_activated": True,
                    "activation_cost_generic": 0,
                    "activation_requires_tap": True,
                    "activation_requires_remove_plus_one_counter_from_controlled_permanent": True,
                    "activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands": True,
                    "tutor_target": "plains",
                    "tutor_destination": "hand",
                },
                matched_signals=[
                    "ScholarOfNewHorizonsEffect",
                    "EntersBattlefieldWithCountersAbility(+1/+1)",
                    "RemoveCounterCost",
                    "FilterLandCard(Plains)",
                    "OpponentControlsMoreCondition",
                ],
            )
        )

    if (
        card_types == {"CREATURE"}
        and effect_classes == {"SearchLibraryPutInPlayEffect"}
        and "EntersBattlefieldTriggeredAbility" in ability_classes
        and not cost_classes
        and "opponentcontrolsmorecondition(staticfilters.filter_lands)" in normalized_text
        and "searchlibraryputinplayeffect" in normalized_text
        and (
            xmage_class_name == "KnightOfTheWhiteOrchid"
            or xmage_class_name == "LoyalWarhound"
        )
    ):
        tutor_target = "basic_plains" if xmage_class_name == "LoyalWarhound" else "plains"
        power = 3 if xmage_class_name == "LoyalWarhound" else 2
        toughness = 1 if xmage_class_name == "LoyalWarhound" else 2
        keywords = ["vigilance"] if xmage_class_name == "LoyalWarhound" else ["first_strike"]
        candidates.append(
            _candidate(
                effect="creature",
                scope="etb_opponent_more_lands_plains_to_battlefield_tapped_v1",
                reason=(
                    "XMage structure matches a white catch-up ramp creature whose ETB trigger checks whether an "
                    "opponent controls more lands and then tutors a tapped Plains onto the battlefield."
                ),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "power": power,
                    "toughness": toughness,
                    "etb_land_ramp_count": 1,
                    "etb_land_ramp_condition": "opponent_controls_more_lands",
                    "land_enters_tapped": True,
                    "tutor_target": tutor_target,
                    "keywords": keywords,
                },
                matched_signals=[
                    "EntersBattlefieldTriggeredAbility",
                    "OpponentControlsMoreCondition",
                    "SearchLibraryPutInPlayEffect",
                    "Zone.BATTLEFIELD",
                    "tapped",
                ],
            )
        )

    if (
        xmage_class_name == "Millikin"
        and card_types == {"ARTIFACT", "CREATURE"}
        and effect_classes == set()
        and ability_classes == {"ColorlessManaAbility"}
        and cost_classes == {"MillCardsCost"}
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="zero_one_colorless_mana_dork_mill_one_v1",
                reason=(
                    "XMage structure matches Millikin: a 0/1 artifact creature that taps for {C} "
                    "with a self-mill rider that ManaLoom preserves as annotation."
                ),
                ability_kind="activated",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "power": 0,
                    "toughness": 1,
                    "is_mana_source": True,
                    "mana_produced": 1,
                    "produces": "C",
                    "mana_source_mill_count": 1,
                    "mana_source_mill_status": "annotation_only",
                },
                matched_signals=[
                    "ColorlessManaAbility",
                    "MillCardsCost",
                    "mana_source",
                    "self_mill_annotation",
                ],
            )
        )

    if (
        xmage_class_name == "TabletOfDiscovery"
        and card_types == {"ARTIFACT"}
        and {"OneShotEffect", "TabletOfDiscoveryEffect"}.issubset(effect_classes)
        and {
            "ConditionalColoredManaAbility",
            "EntersBattlefieldTriggeredAbility",
            "RedManaAbility",
        }.issubset(ability_classes)
        and not cost_classes
    ):
        candidates.append(
            _candidate(
                effect="ramp_permanent",
                scope="artifact_etb_mill_one_play_milled_card_this_turn_red_spell_mana_v1",
                reason=(
                    "XMage structure matches Tablet of Discovery: an artifact that mills one on ETB, "
                    "lets you play that card this turn, taps for {R}, and has a spell-only {R}{R} "
                    "mana mode that ManaLoom preserves as annotation for now."
                ),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "is_mana_source": True,
                    "mana_produced": 1,
                    "produces": "R",
                    "etb_mill_count": 1,
                    "etb_milled_card_playable_this_turn": True,
                    "etb_milled_card_play_status": "annotation_only",
                    "conditional_instant_sorcery_mana_produced": 2,
                    "conditional_instant_sorcery_mana_color": "R",
                    "conditional_instant_sorcery_mana_status": "annotation_only",
                },
                matched_signals=[
                    "EntersBattlefieldTriggeredAbility",
                    "TabletOfDiscoveryEffect",
                    "RedManaAbility",
                    "ConditionalColoredManaAbility",
                    "mana_source",
                    "etb_mill_annotation",
                ],
            )
        )

    if _oracle_has(rules_text, "vow counter", "sacrifices the rest") or (
        "VOW" in counter_types and ("SacrificeAllEffect" in effect_classes or "OneShotEffect" in inner_extends)
    ):
        candidates.append(
            _candidate(
                effect="vow_counter_each_player_sacrifice_rest",
                scope="each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1",
                reason="XMage structure/oracle text indicates vow counters plus sacrifice-rest and attack restriction.",
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                matched_signals=["vow_counter", "sacrifice_rest"],
            )
        )

    if _oracle_has(rules_text, "gift", "destroy all creatures", "return a creature card") or (
        "GiftWasPromisedCondition" in condition_classes and "DestroyAllEffect" in effect_classes
    ):
        candidates.append(
            _candidate(
                effect="gift_destroy_all_creatures_return_own_destroyed_creature",
                scope="gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1",
                reason="XMage/oracle text indicates gift condition, destroy-all, and return destroyed-this-way creature.",
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                matched_signals=["gift", "destroy_all", "return_destroyed_this_way"],
            )
        )

    if (
        xmage_class_name == "VanquishTheHorde"
        and card_types == {"SORCERY"}
        and "DestroyAllEffect" in effect_classes
        and "SpellCostReductionSourceEffect" in effect_classes
        and "SimpleStaticAbility" in ability_classes
        and (
            "PermanentsOnBattlefieldCount" in dynamic_value_classes
            or "creatures on the battlefield" in normalized_text
            or "filter_permanent_creature" in normalized_text
        )
    ):
        candidates.append(
            _candidate(
                effect="board_wipe",
                scope="destroy_all_creatures_cost_reduced_by_creatures_on_battlefield_v1",
                reason=(
                    "XMage structure matches Vanquish the Horde destroying all creatures while carrying "
                    "a self-only cost reduction based on creatures on the battlefield."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "destroy_card_types": ["creature"],
                    "destroy_all_creatures": True,
                    "destination": "graveyard",
                    "sorcery": True,
                    "cost_reduction_applies_to": "this_spell",
                    "cost_reduction_generic": 1,
                    "cost_reduction_amount_source": "creature_count_on_battlefield",
                },
                matched_signals=[
                    "DestroyAllEffect",
                    "SpellCostReductionSourceEffect",
                ],
            )
        )

    if (
        xmage_class_name == "ExplosiveSingularity"
        and card_types == {"SORCERY"}
        and "DamageTargetEffect" in effect_classes
        and "TapVariableTargetCost" in cost_classes
        and any(ext == "CostModificationEffectImpl" for ext in inner_extends)
        and "SimpleStaticAbility" in ability_classes
        and (
            "TargetAnyTarget" in target_classes
            or _oracle_has(
                rules_text,
                "deals 10 damage to any target",
                "you may tap any number of untapped creatures you control",
                "costs {1} less to cast for each creature tapped this way",
            )
        )
    ):
        candidates.append(
            _candidate(
                effect="direct_damage",
                scope="damage_any_target_cost_reduced_by_tapped_controlled_creatures_v1",
                reason=(
                    "XMage structure matches Explosive Singularity dealing 10 damage to any target while "
                    "using an additional tap-creatures cost that reduces only this spell's generic cost."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "target": "any_target",
                    "damage": 10,
                    "sorcery": True,
                    "cost_reduction_applies_to": "this_spell",
                    "cost_reduction_generic": 1,
                    "cost_reduction_amount_source": "creatures_tapped_as_additional_cost_while_casting",
                    "additional_cost_kind": "tap_any_number_untapped_creatures_you_control",
                    "cost_reduction_counts_additional_tapped_creatures_while_casting": True,
                },
                matched_signals=[
                    "DamageTargetEffect",
                    "TapVariableTargetCost",
                    "CostModificationEffectImpl",
                ],
            )
        )

    if (
        xmage_class_name == "BedlamReveler"
        and card_types == {"CREATURE"}
        and {
            "DiscardHandControllerEffect",
            "DrawCardSourceControllerEffect",
            "SpellCostReductionForEachSourceEffect",
        }.issubset(effect_classes)
        and {
            "EntersBattlefieldTriggeredAbility",
            "ProwessAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and (
            _oracle_has(rules_text, "discard your hand", "draw three cards")
            or (
                "discardhandcontrollereffect" in normalized_text
                and "drawcardsourcecontrollereffect(3)" in normalized_text
                and "cardsincontrollergraveyardcount(staticfilters.filter_card_instant_and_sorcery)" in normalized_text
            )
        )
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1",
                reason=(
                    "XMage Bedlam Reveler is a creature spell with prowess, an ETB that discards your hand "
                    "then draws three cards, and a self-only graveyard-count cost reduction."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=False,
                extra_effect_fields={
                    "is_creature_permanent": True,
                    "power": 3,
                    "toughness": 4,
                    "keywords": ["prowess"],
                    "etb_discard_hand_then_draw_count": 3,
                    "cost_reduction_applies_to": "this_spell",
                    "cost_reduction_generic": 1,
                    "cost_reduction_amount_source": "instant_sorcery_cards_in_your_graveyard_count",
                    "graveyard_count_card_types": ["instant", "sorcery"],
                },
                matched_signals=[
                    "SpellCostReductionForEachSourceEffect",
                    "DiscardHandControllerEffect",
                    "DrawCardSourceControllerEffect",
                    "ProwessAbility",
                    "EntersBattlefieldTriggeredAbility",
                ],
            )
        )

    if (
        "SpellsCostReductionControllerEffect" in effect_classes
        or "SpellCostReductionSourceEffect" in effect_classes
        or "SpellCostReductionForEachSourceEffect" in effect_classes
    ):
        cost_fields = static_cost_reduction_fields_from_oracle(rules_text)
        if oracle_supports_cost_reduction_mapping(rules_text):
            candidates.append(
                _candidate(
                    effect="static_cost_reduction",
                    scope=static_cost_reduction_scope_from_fields(cost_fields),
                    reason="XMage uses a spell-cost-reduction effect; this is support/cost shaping, not mana production.",
                    ability_kind="static",
                    requires_runtime_executor=True,
                    extra_effect_fields=cost_fields,
                    matched_signals=["cost_reduction"],
                )
            )

    if "CostModificationEffectImpl" in inner_extends and oracle_supports_cost_reduction_mapping(rules_text):
        cost_fields = static_cost_reduction_fields_from_oracle(rules_text)
        scope = static_cost_reduction_scope_from_fields(cost_fields)
        candidates.append(
            _candidate(
                effect="static_cost_reduction",
                scope=scope,
                reason="XMage custom inner effect extends CostModificationEffectImpl and reduces spell costs.",
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields=cost_fields,
                matched_signals=["custom_cost_modification", "reduce_cost"],
            )
        )

    mana_rock_fields = _build_modal_mana_rock_fields(
        index_entry=index_entry,
        rules_text=rules_text,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
    )
    if mana_rock_fields is not None:
        candidates.append(
            _candidate(
                effect="mana_rock_with_sacrifice_draw",
                scope=str(mana_rock_fields["scope"]),
                reason="XMage structure indicates an artifact that taps for colorless mana and has a tap-plus-sacrifice card-draw mode.",
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(mana_rock_fields["fields"]),
                matched_signals=["mana", "draw", "sacrifice_cost"],
            )
        )

    counter_variant_fields = _build_counter_variant_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if counter_variant_fields is not None:
        candidates.append(
            _candidate(
                effect=str(counter_variant_fields["effect"]),
                scope=str(counter_variant_fields["scope"]),
                reason=str(counter_variant_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(counter_variant_fields["fields"]),
                matched_signals=list(counter_variant_fields["signals"]),
            )
        )

    mill_spell_fields = _build_mill_spell_fields(
        xmage_class_name=xmage_class_name,
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if mill_spell_fields is not None:
        candidates.append(
            _candidate(
                effect=str(mill_spell_fields["effect"]),
                scope=str(mill_spell_fields["scope"]),
                reason=str(mill_spell_fields["reason"]),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields=dict(mill_spell_fields["fields"]),
                matched_signals=list(mill_spell_fields["signals"]),
            )
        )

    chain_of_vapor_fields = _build_chain_of_vapor_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        rules_text=rules_text,
    )
    if chain_of_vapor_fields is not None:
        candidates.append(
            _candidate(
                effect=str(chain_of_vapor_fields["effect"]),
                scope=str(chain_of_vapor_fields["scope"]),
                reason=str(chain_of_vapor_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(chain_of_vapor_fields["fields"]),
                matched_signals=list(chain_of_vapor_fields["signals"]),
            )
        )

    life_drain_trigger_fields = _build_life_drain_trigger_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if life_drain_trigger_fields is not None:
        candidates.append(
            _candidate(
                effect=str(life_drain_trigger_fields["effect"]),
                scope=str(life_drain_trigger_fields["scope"]),
                reason=str(life_drain_trigger_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    key: value
                    for key, value in dict(life_drain_trigger_fields["fields"]).items()
                    if value is not None
                },
                matched_signals=list(life_drain_trigger_fields["signals"]),
            )
        )

    copy_stack_spell_fields = _build_copy_stack_spell_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if copy_stack_spell_fields is not None:
        candidates.append(
            _candidate(
                effect=str(copy_stack_spell_fields["effect"]),
                scope=str(copy_stack_spell_fields["scope"]),
                reason=str(copy_stack_spell_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields=dict(copy_stack_spell_fields["fields"]),
                matched_signals=list(copy_stack_spell_fields["signals"]),
            )
        )

    source_add_counters_creature_fields = _build_source_add_counters_creature_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if source_add_counters_creature_fields is not None:
        candidates.append(
            _candidate(
                effect=str(source_add_counters_creature_fields["effect"]),
                scope=str(source_add_counters_creature_fields["scope"]),
                reason=str(source_add_counters_creature_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields=dict(source_add_counters_creature_fields["fields"]),
                matched_signals=list(source_add_counters_creature_fields["signals"]),
            )
        )

    simple_creature_mana_source_fields = _build_simple_creature_mana_source_fields(
        card_types=card_types,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if simple_creature_mana_source_fields is not None:
        candidates.append(
            _candidate(
                effect=str(simple_creature_mana_source_fields["effect"]),
                scope=str(simple_creature_mana_source_fields["scope"]),
                reason=str(simple_creature_mana_source_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(simple_creature_mana_source_fields["fields"]),
                matched_signals=list(simple_creature_mana_source_fields["signals"]),
            )
        )

    basic_land_fields = _build_basic_land_fields(
        index_entry=index_entry,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
    )
    if basic_land_fields is not None:
        candidates.append(
            _candidate(
                effect=str(basic_land_fields["effect"]),
                scope=str(basic_land_fields["scope"]),
                reason=str(basic_land_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=False,
                extra_effect_fields=dict(basic_land_fields["fields"]),
                matched_signals=list(basic_land_fields["signals"]),
            )
        )

    dynamic_any_color_land_fields = _build_dynamic_any_color_land_fields(
        index_entry=index_entry,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if dynamic_any_color_land_fields is not None:
        candidates.append(
            _candidate(
                effect=str(dynamic_any_color_land_fields["effect"]),
                scope=str(dynamic_any_color_land_fields["scope"]),
                reason=str(dynamic_any_color_land_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=False,
                extra_effect_fields=dict(dynamic_any_color_land_fields["fields"]),
                matched_signals=list(dynamic_any_color_land_fields["signals"]),
            )
        )

    colorless_land_sacrifice_mana_mode_fields = _build_colorless_land_sacrifice_mana_mode_fields(
        index_entry=index_entry,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if colorless_land_sacrifice_mana_mode_fields is not None:
        candidates.append(
            _candidate(
                effect=str(colorless_land_sacrifice_mana_mode_fields["effect"]),
                scope=str(colorless_land_sacrifice_mana_mode_fields["scope"]),
                reason=str(colorless_land_sacrifice_mana_mode_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(colorless_land_sacrifice_mana_mode_fields["fields"]),
                matched_signals=list(colorless_land_sacrifice_mana_mode_fields["signals"]),
            )
        )

    pain_land_fields = _build_pain_land_fields(
        index_entry=index_entry,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if pain_land_fields is not None:
        candidates.append(
            _candidate(
                effect=str(pain_land_fields["effect"]),
                scope=str(pain_land_fields["scope"]),
                reason=str(pain_land_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=False,
                extra_effect_fields=dict(pain_land_fields["fields"]),
                matched_signals=list(pain_land_fields["signals"]),
            )
        )

    simple_artifact_mana_source_fields = _build_simple_artifact_mana_source_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if simple_artifact_mana_source_fields is not None:
        candidates.append(
            _candidate(
                effect=str(simple_artifact_mana_source_fields["effect"]),
                scope=str(simple_artifact_mana_source_fields["scope"]),
                reason=str(simple_artifact_mana_source_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(simple_artifact_mana_source_fields["fields"]),
                matched_signals=list(simple_artifact_mana_source_fields["signals"]),
            )
        )

    hand_exile_mana_ritual_fields = _build_hand_exile_mana_ritual_fields(
        index_entry=index_entry,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if hand_exile_mana_ritual_fields is not None:
        candidates.append(
            _candidate(
                effect=str(hand_exile_mana_ritual_fields["effect"]),
                scope=str(hand_exile_mana_ritual_fields["scope"]),
                reason=str(hand_exile_mana_ritual_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(hand_exile_mana_ritual_fields["fields"]),
                matched_signals=list(hand_exile_mana_ritual_fields["signals"]),
            )
        )

    copy_permanent_etb_fields = _build_copy_permanent_etb_fields(
        index_entry=index_entry,
        rules_text=rules_text,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
    )
    if copy_permanent_etb_fields is not None:
        candidates.append(
            _candidate(
                effect=str(copy_permanent_etb_fields["effect"]),
                scope=str(copy_permanent_etb_fields["scope"]),
                reason=str(copy_permanent_etb_fields["reason"]),
                ability_kind="replacement",
                requires_runtime_executor=True,
                extra_effect_fields=dict(copy_permanent_etb_fields["fields"]),
                matched_signals=list(copy_permanent_etb_fields["signals"]),
            )
        )

    fetch_land_fields = _build_fetch_land_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if fetch_land_fields is not None:
        candidates.append(
            _candidate(
                effect=str(fetch_land_fields["effect"]),
                scope=str(fetch_land_fields["scope"]),
                reason=str(fetch_land_fields["reason"]),
                ability_kind="activated",
                requires_runtime_executor=True,
                extra_effect_fields=dict(fetch_land_fields["fields"]),
                matched_signals=list(fetch_land_fields["signals"]),
            )
        )

    creature_sacrifice_ritual_fields = _build_creature_sacrifice_ritual_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if creature_sacrifice_ritual_fields is not None:
        candidates.append(
            _candidate(
                effect=str(creature_sacrifice_ritual_fields["effect"]),
                scope=str(creature_sacrifice_ritual_fields["scope"]),
                reason=str(creature_sacrifice_ritual_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(creature_sacrifice_ritual_fields["fields"]),
                matched_signals=list(creature_sacrifice_ritual_fields["signals"]),
            )
        )

    dynamic_mana_ritual_fields = _build_dynamic_mana_ritual_fields(
        xmage_class_name=xmage_class_name,
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        target_classes=target_classes,
        filter_classes=filter_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if dynamic_mana_ritual_fields is not None:
        candidates.append(
            _candidate(
                effect=str(dynamic_mana_ritual_fields["effect"]),
                scope=str(dynamic_mana_ritual_fields["scope"]),
                reason=str(dynamic_mana_ritual_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(dynamic_mana_ritual_fields["fields"]),
                matched_signals=list(dynamic_mana_ritual_fields["signals"]),
            )
        )

    tutor_to_hand_fields = _build_tutor_to_hand_fields(
        xmage_class_name=xmage_class_name,
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        condition_classes=condition_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if tutor_to_hand_fields is not None:
        candidates.append(
            _candidate(
                effect=str(tutor_to_hand_fields["effect"]),
                scope=str(tutor_to_hand_fields["scope"]),
                reason=str(tutor_to_hand_fields["reason"]),
                ability_kind=str(tutor_to_hand_fields["ability_kind"]),
                requires_runtime_executor=True,
                extra_effect_fields=dict(tutor_to_hand_fields["fields"]),
                matched_signals=list(tutor_to_hand_fields["signals"]),
            )
        )

    tutor_to_battlefield_fields = _build_tutor_to_battlefield_fields(
        xmage_class_name=xmage_class_name,
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if tutor_to_battlefield_fields is not None:
        candidates.append(
            _candidate(
                effect=str(tutor_to_battlefield_fields["effect"]),
                scope=str(tutor_to_battlefield_fields["scope"]),
                reason=str(tutor_to_battlefield_fields["reason"]),
                ability_kind=str(tutor_to_battlefield_fields["ability_kind"]),
                requires_runtime_executor=True,
                extra_effect_fields=dict(tutor_to_battlefield_fields["fields"]),
                matched_signals=list(tutor_to_battlefield_fields["signals"]),
            )
        )

    topdeck_tutor_fields = _build_topdeck_tutor_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if topdeck_tutor_fields is not None:
        candidates.append(
            _candidate(
                effect=str(topdeck_tutor_fields["effect"]),
                scope=str(topdeck_tutor_fields["scope"]),
                reason=str(topdeck_tutor_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(topdeck_tutor_fields["fields"]),
                matched_signals=list(topdeck_tutor_fields["signals"]),
            )
        )

    extra_turn_fields = _build_extra_turn_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if extra_turn_fields is not None:
        candidates.append(
            _candidate(
                effect=str(extra_turn_fields["effect"]),
                scope=str(extra_turn_fields["scope"]),
                reason=str(extra_turn_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields=dict(extra_turn_fields["fields"]),
                matched_signals=list(extra_turn_fields["signals"]),
            )
        )

    dig_to_hand_fields = _build_dig_to_hand_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        raw_excerpt=str(index_entry.get("raw_excerpt") or ""),
    )
    if dig_to_hand_fields is not None:
        candidates.append(
            _candidate(
                effect=str(dig_to_hand_fields["effect"]),
                scope=str(dig_to_hand_fields["scope"]),
                reason=str(dig_to_hand_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(dig_to_hand_fields["fields"]),
                matched_signals=list(dig_to_hand_fields["signals"]),
            )
        )

    pile_selection_draw_fields = _build_pile_selection_draw_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        raw_excerpt=str(index_entry.get("raw_excerpt") or ""),
    )
    if pile_selection_draw_fields is not None:
        candidates.append(
            _candidate(
                effect=str(pile_selection_draw_fields["effect"]),
                scope=str(pile_selection_draw_fields["scope"]),
                reason=str(pile_selection_draw_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(pile_selection_draw_fields["fields"]),
                matched_signals=list(pile_selection_draw_fields["signals"]),
            )
        )

    basic_ritual_fields = _build_basic_ritual_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        condition_classes=condition_classes,
        card_subtypes={
            str(value or "").upper()
            for value in ((index_entry.get("constructor_metadata") or {}).get("subtypes") or [])
            if value
        },
        rules_text=rules_text,
    )
    if basic_ritual_fields is not None:
        candidates.append(
            _candidate(
                effect=str(basic_ritual_fields["effect"]),
                scope=str(basic_ritual_fields["scope"]),
                reason=str(basic_ritual_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(basic_ritual_fields["fields"]),
                matched_signals=list(basic_ritual_fields["signals"]),
            )
        )

    creature_variant_fields = _build_creature_variant_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if creature_variant_fields is not None:
        candidates.append(
            _candidate(
                effect=str(creature_variant_fields["effect"]),
                scope=str(creature_variant_fields["scope"]),
                reason=str(creature_variant_fields["reason"]),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields=dict(creature_variant_fields["fields"]),
                matched_signals=list(creature_variant_fields["signals"]),
            )
        )

    exact_runtime_variant_fields = _build_exact_runtime_variant_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        target_classes=target_classes,
        filter_classes=filter_classes,
        cost_classes=cost_classes,
        xmage_class_name=xmage_class_name,
        rules_text=rules_text,
    )
    if exact_runtime_variant_fields is not None:
        candidates.insert(
            0,
            _candidate(
                effect=str(exact_runtime_variant_fields["effect"]),
                scope=str(exact_runtime_variant_fields["scope"]),
                reason=str(exact_runtime_variant_fields["reason"]),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=dict(exact_runtime_variant_fields.get("target_constraints") or {}),
                extra_effect_fields=dict(exact_runtime_variant_fields["fields"]),
                matched_signals=list(exact_runtime_variant_fields["signals"]),
            )
        )

    veil_fields = _build_veil_of_summer_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if veil_fields is not None:
        candidates.append(
            _candidate(
                effect=str(veil_fields["effect"]),
                scope=str(veil_fields["scope"]),
                reason=str(veil_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=True,
                extra_effect_fields=dict(veil_fields["fields"]),
                matched_signals=list(veil_fields["signals"]),
            )
        )

    rishkar_fields = _build_rishkar_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if rishkar_fields is not None:
        candidates.append(
            _candidate(
                effect=str(rishkar_fields["effect"]),
                scope=str(rishkar_fields["scope"]),
                reason=str(rishkar_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields=dict(rishkar_fields["fields"]),
                matched_signals=list(rishkar_fields["signals"]),
            )
        )

    creatures_tap_any_color_fields = _build_creatures_tap_any_color_static_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if creatures_tap_any_color_fields is not None:
        candidates.append(
            _candidate(
                effect=str(creatures_tap_any_color_fields["effect"]),
                scope=str(creatures_tap_any_color_fields["scope"]),
                reason=str(creatures_tap_any_color_fields["reason"]),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields=dict(creatures_tap_any_color_fields["fields"]),
                matched_signals=list(creatures_tap_any_color_fields["signals"]),
            )
        )

    magda_fields = _build_magda_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        cost_classes=cost_classes,
        rules_text=rules_text,
    )
    if magda_fields is not None:
        candidates.append(
            _candidate(
                effect=str(magda_fields["effect"]),
                scope=str(magda_fields["scope"]),
                reason=str(magda_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields=dict(magda_fields["fields"]),
                matched_signals=list(magda_fields["signals"]),
            )
        )

    insidious_roots_fields = _build_insidious_roots_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
        rules_text=rules_text,
    )
    if insidious_roots_fields is not None:
        candidates.append(
            _candidate(
                effect=str(insidious_roots_fields["effect"]),
                scope=str(insidious_roots_fields["scope"]),
                reason=str(insidious_roots_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields=dict(insidious_roots_fields["fields"]),
                matched_signals=list(insidious_roots_fields["signals"]),
            )
        )

    if "UntapSourceDuringEachOtherPlayersUntapStepEffect" in effect_classes and "AnyColorManaAbility" in ability_classes:
        candidates.append(
            _candidate(
                effect="other_turn_untapping_any_color_mana_rock",
                scope="artifact_untaps_each_other_player_untap_step_tap_any_color_v1",
                reason="XMage uses the shared other-player untap static effect plus AnyColorManaAbility.",
                ability_kind="activated",
                requires_runtime_executor=True,
                matched_signals=["untap_each_other_player", "any_color_mana"],
            )
        )

    if "UntapSourceDuringEachOtherPlayersUntapStepEffect" in effect_classes and (
        "VictoryChimesManaEffect" in effect_classes or "TargetPlayer" in target_classes
    ):
        candidates.append(
            _candidate(
                effect="other_turn_untapping_target_player_colorless_mana_rock",
                scope="artifact_untaps_each_other_player_untap_step_tap_target_player_add_colorless_v1",
                reason="XMage uses the shared other-player untap static effect and a custom ManaEffect that chooses a player for {C}.",
                ability_kind="activated",
                requires_runtime_executor=True,
                target_constraints={"target": "player", "mana_pool_owner": "chosen_player"},
                matched_signals=["untap_each_other_player", "target_player", "colorless_mana"],
            )
        )

    if any("ManaAbility" in ability for ability in ability_classes) and "ExileThenReturnTargetEffect" in effect_classes:
        candidates.append(
            _candidate(
                effect="mana_rock_with_harnessed_blink",
                scope="legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1",
                reason="XMage structure indicates mana ability plus harnessed delayed blink support.",
                ability_kind="activated",
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                matched_signals=["mana", "harness", "blink"],
            )
        )

    if _oracle_has(rules_text, "choose from among the permanents", "sacrifices all other nonland permanents"):
        candidates.append(
            _candidate(
                effect="selective_nonland_sacrifice",
                scope="controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1",
                reason="Oracle text indicates Tragic Arrogance-style per-type/per-player selection and sacrifice.",
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                matched_signals=["controller_choice", "nonland_sacrifice"],
            )
        )

    if (
        "DiscardCardControllerTriggeredAbility" in ability_classes
        and "DrawCardSourceControllerEffect" in effect_classes
        and "CreateTokenEffect" in effect_classes
        and "LoseLifeOpponentsEffect" in effect_classes
    ):
        candidates.append(
            _candidate(
                effect="discard_trigger_modal_draw_treasure_opponent_life_loss",
                scope="discard_trigger_choose_unchosen_mode_draw_or_treasure_or_each_opponent_loses_3_v1",
                reason="XMage models the discard trigger with once-per-turn mode limiting, draw, Treasure creation, and opponent life loss modes.",
                ability_kind="triggered",
                requires_runtime_executor=True,
                matched_signals=["discard_trigger", "modal_once_each", "draw", "treasure", "opponent_life_loss"],
            )
        )

    if _oracle_has(rules_text, "exile target instant or sorcery", "combat damage to a player", "copy the exiled card") or (
        "SurgeToVictoryExileEffect" in effect_classes
        and "SurgeToVictoryTriggeredAbility" in ability_classes
        and "SurgeToVictoryCastEffect" in effect_classes
    ):
        candidates.append(
            _candidate(
                effect="exile_instant_sorcery_boost_combat_damage_copy_cast",
                scope="exile_target_instant_sorcery_boost_team_and_combat_damage_copy_cast_free_v1",
                reason="XMage custom effects exile a targeted instant/sorcery, boost controlled creatures by mana value, and add delayed combat-damage copy/cast behavior.",
                ability_kind="triggered",
                requires_runtime_executor=True,
                target_constraints={"zone": "graveyard", "card_types": ["instant", "sorcery"]},
                matched_signals=["graveyard_target", "team_boost", "combat_damage_trigger", "copy_cast_free"],
            )
        )

    normalized_text = _normalized_rules_text(rules_text)

    if (
        xmage_class_name == "HazelsBrewmaster"
        or (
            "EntersBattlefieldOrAttacksSourceTriggeredAbility" in ability_classes
            and "CreateTokenEffect" in effect_classes
            and "ExileTargetEffect" in effect_classes
            and "FoodToken" in _combined_rules_text(index_entry, rules_text)
            and _oracle_has(
                rules_text,
                "foods you control have all activated abilities",
                "creature cards exiled with",
            )
        )
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="etb_or_attack_exile_graveyard_card_create_food_share_exiled_creature_activated_abilities_v1",
                reason=(
                    "XMage models Hazel's Brewmaster as an ETB/attack trigger that exiles up to one "
                    "graveyard card, creates a Food token, and a static effect granting Foods activated "
                    "abilities from creature cards exiled with the source."
                ),
                ability_kind="triggered_static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 3,
                    "toughness": 4,
                    "keywords": ["menace"],
                    "menace": True,
                    "trigger": "enters_battlefield_or_attacks",
                    "trigger_effect": "exile_graveyard_card_create_food",
                    "hazel_brewmaster_etb_or_attack_exile_graveyard_card_create_food": True,
                    "target_zone": "graveyard",
                    "target_count_max": 1,
                    "target_optional": True,
                    "create_food_token": True,
                    "foods_gain_activated_abilities_from_exiled_creatures": True,
                },
                matched_signals=[
                    "EntersBattlefieldOrAttacksSourceTriggeredAbility",
                    "ExileTargetEffect",
                    "CreateTokenEffect",
                    "FoodToken",
                    "HazelsBrewmasterAbilityEffect",
                ],
            )
        )

    if "CreateTokenCopyTargetEffect" in effect_classes:
        if (
            xmage_class_name == "SpringheartNantuko"
            or (
                "LandfallAbility" in ability_classes
                and "CreateTokenEffect" in effect_classes
                and "BoostEnchantedEffect" in effect_classes
                and {
                    str(value or "").upper()
                    for value in ((index_entry.get("constructor_metadata") or {}).get("card_types") or [])
                    if value
                }
                == {"CREATURE", "ENCHANTMENT"}
                and _oracle_has(
                    rules_text,
                    "whenever a land you control enters",
                    "create a token that's a copy of that creature",
                    "create a 1/1 green insect creature token",
                )
            )
        ):
            candidates.append(
                _candidate(
                    effect="creature",
                    scope="landfall_optional_pay_copy_attached_creature_else_insect_v1",
                    reason="XMage models a Bestow creature with enchanted-creature +1/+1 and a landfall trigger that either pays {1}{G} to copy the attached creature or creates a 1/1 green Insect token.",
                    ability_kind="triggered",
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "is_creature_permanent": True,
                        "power": 1,
                        "toughness": 1,
                        "landfall_optional_pay_copy_attached_creature_else_insect": True,
                        "landfall_copy_cost": "{1}{G}",
                        "bestow_cost": "{1}{G}",
                        "bestow_attached_creature_power_bonus": 1,
                        "bestow_attached_creature_toughness_bonus": 1,
                        "token_name": "Insect Token",
                        "token_subtype": "Insect",
                        "token_colors": ["G"],
                        "token_power": 1,
                        "token_toughness": 1,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "CreateTokenEffect",
                        "LandfallAbility",
                        "BestowAbility",
                        "BoostEnchantedEffect",
                        "springheart_landfall_copy_or_insect",
                    ],
                )
            )
        elif (
            xmage_class_name == "JaxisTheTroublemaker"
            or (
                _oracle_has(
                    rules_text,
                    "create a token that's a copy of another target creature you control",
                    "when this creature dies, draw a card",
                    "sacrifice it at the beginning of the next end step",
                )
                and "DrawCardSourceControllerEffect" in effect_classes
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1",
                    reason="XMage structure matches another-creature copy token with haste, dies-draw rider, and end-step sacrifice.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "copy_target_types": ["creature"],
                        "target_controller": "own",
                        "exclude_source_from_copy_targets": True,
                        "token_haste": True,
                        "token_draw_cards_when_this_dies": 1,
                        "sacrifice_token_at_end_step": True,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "copy_another_creature_you_control",
                        "dies_draw",
                        "sacrifice_end_step",
                    ],
                )
            )
        elif (
            xmage_class_name == "RionyaFireDancer"
            or _oracle_has(
                rules_text,
                "create x tokens that are copies of another target creature you control",
                "one plus the number of instant and sorcery spells you've cast this turn",
                "exile them at the beginning of the next end step",
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1",
                    reason="XMage structure matches another-creature copy tokens counted from instant/sorcery spells cast this turn plus one, with haste and end-step exile.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "copy_target_types": ["creature"],
                        "target_controller": "own",
                        "exclude_source_from_copy_targets": True,
                        "token_count_source": "instant_or_sorcery_spells_cast_this_turn_plus_one",
                        "token_haste": True,
                        "exile_token_at_end_step": True,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "copy_another_creature_you_control",
                        "instant_sorcery_count_plus_one",
                        "exile_end_step",
                    ],
                )
            )
        elif (
            xmage_class_name == "TheJollyBalloonMan"
            or _oracle_has(
                rules_text,
                "create a token that's a copy of another target creature you control",
                "it's a 1/1 red balloon creature in addition to its other colors and types",
                "it has flying and haste",
                "sacrifice it at the beginning of the next end step",
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1",
                    reason="XMage structure matches another-creature copy token with 1/1 Balloon override, added red color, flying, haste, and end-step sacrifice.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "copy_target_types": ["creature"],
                        "target_controller": "own",
                        "exclude_source_from_copy_targets": True,
                        "force_token_creature": True,
                        "token_power": 1,
                        "token_toughness": 1,
                        "token_extra_colors": ["R"],
                        "token_subtype": "Balloon",
                        "token_flying": True,
                        "token_haste": True,
                        "sacrifice_token_at_end_step": True,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "copy_another_creature_you_control",
                        "balloon_1_1_red",
                        "flying_haste",
                        "sacrifice_end_step",
                    ],
                )
            )
        elif _oracle_has(
            rules_text,
            "create a token that's a copy of target creature you control",
            "sacrifice this token",
        ):
            extra_fields = {
                "copy_target_types": ["creature"],
                "target_controller": "own",
                "token_haste": "has haste" in normalized_text,
                "sacrifice_token_at_end_step": "sacrifice it at the beginning of the next end step" in normalized_text
                or "sacrifice this token" in normalized_text,
            }
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_target_creature_you_control_haste_sacrifice_end_step_v1",
                    reason="Oracle and XMage structure match a temporary token copy of a creature you control with haste and end-step sacrifice.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=True,
                    extra_effect_fields=extra_fields,
                    matched_signals=["CreateTokenCopyTargetEffect", "copy_creature_you_control", "sacrifice_end_step"],
                )
            )
        elif (
            card_types == {"SORCERY"}
            and (
                _oracle_has(rules_text, "create a token that's a copy of target permanent")
                or (
                    "TargetPermanent" in target_classes
                    and "SourceTargetsPermanentCondition" in condition_classes
                    and "CastAsThoughItHadFlashIfConditionAbility" in ability_classes
                    and "FlashbackAbility" in ability_classes
                )
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_target_permanent_v1",
                    reason="Oracle and XMage structure match a one-shot permanent copy token without temporary cleanup clauses.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "copy_target_types": ["permanent"],
                        "target_controller": "any",
                        "token_haste": False,
                    },
                    matched_signals=["CreateTokenCopyTargetEffect", "copy_target_permanent"],
                )
            )
        elif (
            xmage_class_name == "AdagiaWindsweptBastion"
            or (
                _oracle_has(
                    rules_text,
                    "create a token that's a copy of target artifact or enchantment you control",
                    "except it's legendary",
                )
                and "TargetPermanent" in target_classes
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
                    reason=(
                        "XMage exposes CreateTokenCopyTargetEffect over controlled artifact/enchantment "
                        "targets with a legendary token modifier; ManaLoom already has copy-token "
                        "target selection and now tracks the legendary token modifier explicitly."
                    ),
                    ability_kind="activated",
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "copy_target_types": ["artifact", "enchantment"],
                        "target_controller": "own",
                        "token_legendary": True,
                        "activate_only_as_sorcery": True,
                        "activation_cost_mana": "{3}{W}",
                        "activation_requires_tap": True,
                        "station_level_required": 12,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "TargetPermanent",
                        "FILTER_PERMANENT_CONTROLLED_ARTIFACT_OR_ENCHANTMENT",
                        "StationLevelAbility",
                    ],
                )
            )
        elif (
            card_types == {"SORCERY"}
            and _oracle_has(
                rules_text,
                "for each creature target player controls",
                "create a token that's a copy of that creature",
            )
        ):
            candidates.append(
                _candidate(
                    effect="copy_creature_token",
                    scope="copy_each_creature_target_player_controls_v1",
                    reason="Oracle and XMage structure match creating one copy for each creature a targeted player controls.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "copy_target_types": ["creature"],
                        "target_controller": "opponent",
                        "copy_all_matching_targets": True,
                    },
                    matched_signals=[
                        "CreateTokenCopyTargetEffect",
                        "copy_all_creatures_target_player_controls",
                    ],
                )
            )

    card_types = {
        str(value or "").upper()
        for value in ((index_entry.get("constructor_metadata") or {}).get("card_types") or [])
        if value
    }

    if "CreateTokenEffect" in effect_classes:
        if (
            card_types == {"ARTIFACT"}
            and "EntersBattlefieldOrDiesSourceTriggeredAbility" in ability_classes
        ):
            candidates.append(
                _candidate(
                    effect="ramp_permanent",
                    scope="artifact_etb_or_dies_create_treasure_v1",
                    reason="Oracle and XMage structure match an artifact that creates a Treasure when it enters and when it dies.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "treasure_count": 1,
                        "enters_treasure": 1,
                        "dies_or_graveyard_from_battlefield_treasure": True,
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "EntersBattlefieldOrDiesSourceTriggeredAbility",
                        "etb_or_dies_treasure",
                    ],
                )
            )
        elif (
            card_types == {"CREATURE"}
            and effect_classes == {"CreateTokenEffect"}
            and {"DiesSourceTriggeredAbility", "EncoreAbility"}.issubset(ability_classes)
        ):
            candidates.append(
                _candidate(
                    effect="creature",
                    scope="dies_create_treasure_encore_v1",
                    reason="Oracle and XMage structure match a 1/1 creature that creates a Treasure when it dies and carries encore.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "power": 1,
                        "toughness": 1,
                        "dies_or_graveyard_from_battlefield_treasure": True,
                        "treasure_count": 1,
                        "encore_cost": "{3}{R}",
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "DiesSourceTriggeredAbility",
                        "EncoreAbility",
                        "dies_treasure",
                    ],
                )
            )
        elif (
            card_types == {"CREATURE"}
            and {"CreateTokenEffect", "LoseLifeSourceControllerEffect"}.issubset(effect_classes)
            and "CastSecondSpellTriggeredAbility" in ability_classes
        ):
            candidates.append(
                _candidate(
                    effect="ramp_engine",
                    scope="opponent_second_spell_each_turn_create_treasure_life_loss_v1",
                    reason="Oracle and XMage structure match a creature that loses 1 life and creates a Treasure whenever a player casts their second spell each turn.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "is_creature_permanent": True,
                        "power": 2,
                        "toughness": 1,
                        "trigger": "opponent_spell",
                        "opponent_second_spell_each_turn": True,
                        "treasure_count": 1,
                        "controller_loses_life_on_trigger": 1,
                        "draw_on_enter": False,
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "LoseLifeSourceControllerEffect",
                        "CastSecondSpellTriggeredAbility",
                        "second_spell_treasure",
                    ],
                )
            )
        elif (
            card_types == {"CREATURE"}
            and {"CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and {"DrawCardOpponentTriggeredAbility", "EntersBattlefieldTriggeredAbility"}.issubset(ability_classes)
            and "TargetOpponent" in target_classes
            and (
                _oracle_has(
                    rules_text,
                    "target opponent may draw a card",
                    "if it isn't that player's turn",
                    "create a tapped treasure token",
                )
                or (
                    "tatarutarucondition.instance" in normalized_text
                    and "settriggerslimiteachturn(1)" in normalized_text
                    and "treasuretoken" in normalized_text
                )
            )
        ):
            candidates.append(
                _candidate(
                    effect="ramp_engine",
                    scope="etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1",
                    reason="Oracle and XMage structure match Tataru Taru ETB self-draw plus target-opponent may-draw and an off-turn once-each-turn tapped-Treasure trigger.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "is_creature_permanent": True,
                        "power": 0,
                        "toughness": 3,
                        "trigger": "opponent_draw",
                        "treasure_count": 1,
                        "treasure_tokens_tapped": True,
                        "trigger_only_off_turn_opponent_draw": True,
                        "trigger_limit_each_turn": 1,
                        "etb_draw_count": 1,
                        "etb_target_opponent_may_draw_count": 1,
                        "etb_target_opponent_may_draw_choice_model": "compact_assume_yes_single_card_v1",
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "DrawCardSourceControllerEffect",
                        "DrawCardOpponentTriggeredAbility",
                        "EntersBattlefieldTriggeredAbility",
                        "TargetOpponent",
                        "tataru_taru_treasure",
                    ],
                )
            )
        elif (
            card_types == {"CREATURE"}
            and "CreateTokenEffect" in effect_classes
            and effect_classes.issubset({"CreateTokenEffect", "WinGameSourceControllerEffect"})
            and "OneOrMoreCombatDamagePlayerTriggeredAbility" in ability_classes
            and (
                _oracle_has(
                    rules_text,
                    "whenever one or more creatures you control deal combat damage to a player",
                    "create a treasure token",
                )
                or "oneormorecombatdamageplayertriggeredability" in normalized_text
            )
        ):
            candidates.append(
                _candidate(
                    effect="ramp_engine",
                    scope="one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
                    reason="Oracle and XMage structure match a creature that creates a Treasure whenever one or more creatures you control deal combat damage to a player.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "is_creature_permanent": True,
                        "power": 2,
                        "toughness": 4,
                        "double_strike": True,
                        "trample": True,
                        "haste": True,
                        "trigger": "combat_damage_to_player",
                        "trigger_creatures_you_control": True,
                        "treasure_count": 1,
                        "upkeep_win_if_control_artifacts_at_least": 30,
                        "upkeep_win_status": "annotation_only",
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "OneOrMoreCombatDamagePlayerTriggeredAbility",
                        "combat_damage_treasure",
                    ],
                )
            )
        elif (
            "treasuretoken" in normalized_text
            and "drawcardsourcecontrollereffect(2)" in normalized_text
            and "discardcardcost" in normalized_text
            and card_types == {"SORCERY"}
        ) or _oracle_has(rules_text, "draw two cards", "create two treasure tokens"):
            candidates.append(
                _candidate(
                    effect="treasure_maker",
                    scope="discard_draw_two_create_two_treasures_v1",
                    reason="Oracle and XMage structure match a discard-to-draw-two plus create-two-Treasures sorcery.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "draw_count": 2,
                        "treasure_count": 2,
                        "requires_discard_card": True,
                    },
                    matched_signals=["CreateTokenEffect", "DrawCardSourceControllerEffect", "two_treasures"],
                )
            )
        elif (
            card_types == {"ARTIFACT", "LAND"}
            and "CreateTokenEffect" in effect_classes
            and {"ColorlessManaAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
            and (
                ("create x treasure tokens" in normalized_text and "{x}{x}" in str(rules_text or "").lower())
                or ("getxvalue.instance" in normalized_text and "manacostsimpl" in normalized_text)
            )
        ):
            candidates.append(
                _candidate(
                    effect="treasure_maker",
                    scope="activated_xx_tap_sacrifice_create_x_treasures_v1",
                    reason="Oracle and XMage structure match an activated artifact land that pays {X}{X}, taps, and sacrifices itself to create X Treasures.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "produces": "C",
                        "mana_produced": 1,
                        "activation_requires_tap": True,
                        "activation_requires_sacrifice": True,
                        "activation_cost_generic_is_x_twice": True,
                        "treasure_count_source": "x_value",
                        "treasure_count_per_x": 1,
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "SimpleActivatedAbility",
                        "TapSourceCost",
                        "SacrificeSourceCost",
                        "x_treasure_land",
                    ],
                )
            )
        elif (
            card_types == {"CREATURE"}
            and effect_classes == {"CreateTokenEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and "UntapSourceCost" in cost_classes
            and (
                xmage_class_name == "PatrolSignaler"
                or (
                    "kithkinsoldiertoken" in normalized_text
                    and "untapsourcecost" in normalized_text
                    and "{1}{w}" in normalized_text
                )
                or (
                    set(((index_entry.get("constructor_metadata") or {}).get("subtypes") or []))
                    == {"KITHKIN", "SOLDIER"}
                    and "kithkinsoldiertoken" in normalized_text
                )
                or (
                    card_types == {"CREATURE"}
                    and "kithkinsoldiertoken" in normalized_text
                    and "untapsourcecost" in normalized_text
                )
            )
        ):
            candidates.append(
                _candidate(
                    effect="creature",
                    scope="activated_untap_self_create_1_1_white_kithkin_soldier_token_v1",
                    reason="Oracle and XMage structure match a creature that pays {1}{W} and untaps itself to create a 1/1 white Kithkin Soldier token.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "is_creature_permanent": True,
                        "power": 1,
                        "toughness": 1,
                        "activated_create_token": True,
                        "activation_requires_source_tapped": True,
                        "activation_uses_untap_symbol": True,
                        "activation_cost_generic": 1,
                        "activation_cost_colors": ["W"],
                        "token_count": 1,
                        "token_name": "Kithkin Soldier Token",
                        "token_subtype": "Kithkin Soldier",
                        "token_colors": ["W"],
                        "token_power": 1,
                        "token_toughness": 1,
                    },
                    matched_signals=[
                        "CreateTokenEffect",
                        "SimpleActivatedAbility",
                        "UntapSourceCost",
                        "kithkin_token_activation",
                    ],
                )
            )
        elif (
            "treasuretoken" in normalized_text
            and "drawcardsourcecontrollereffect" not in normalized_text
            and card_types == {"SORCERY"}
        ) or (_oracle_has(rules_text, "create a treasure token") and "draw two cards" not in normalized_text):
            candidates.append(
                _candidate(
                    effect="treasure_maker",
                    scope="single_treasure_creation_v1",
                    reason="Oracle and XMage structure match a one-shot Treasure creation effect.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={"treasure_count": 1},
                    matched_signals=["CreateTokenEffect", "single_treasure"],
                )
            )

    if "CreateTokenEffect" in effect_classes or "CreateTokenCopyTargetEffect" in effect_classes:
        candidates.append(
            _candidate(
                effect="token_maker",
                scope="xmage_create_token_variant_" + _slug(str(index_entry.get("xmage_class_name") or "card")) + "_v1",
                reason="XMage uses token creation classes.",
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                matched_signals=["token"],
            )
        )

    controlled_creature_enters_damage_fields = _build_controlled_creature_enters_damage_each_opponent_fields(
        index_entry=index_entry,
        rules_text=rules_text,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
    )
    if controlled_creature_enters_damage_fields is not None:
        candidates.append(
            _candidate(
                effect=str(controlled_creature_enters_damage_fields["effect"]),
                scope=str(controlled_creature_enters_damage_fields["scope"]),
                reason=str(controlled_creature_enters_damage_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields=dict(controlled_creature_enters_damage_fields["fields"]),
                matched_signals=list(controlled_creature_enters_damage_fields["signals"]),
            )
        )

    spell_cast_damage_fields = _build_spell_cast_damage_each_opponent_fields(
        index_entry=index_entry,
        rules_text=rules_text,
        effect_classes=effect_classes,
        ability_classes=ability_classes,
    )
    if spell_cast_damage_fields is not None:
        candidates.append(
            _candidate(
                effect=str(spell_cast_damage_fields["effect"]),
                scope=str(spell_cast_damage_fields["scope"]),
                reason=str(spell_cast_damage_fields["reason"]),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields=dict(spell_cast_damage_fields["fields"]),
                matched_signals=list(spell_cast_damage_fields["signals"]),
            )
        )

    single_target_stack_redirect_fields = _build_single_target_stack_redirect_fields(
        card_types=card_types,
        effect_classes=effect_classes,
        target_classes=target_classes,
        rules_text=rules_text,
    )
    if single_target_stack_redirect_fields is not None:
        candidates.append(
            _candidate(
                effect=str(single_target_stack_redirect_fields["effect"]),
                scope=str(single_target_stack_redirect_fields["scope"]),
                reason=str(single_target_stack_redirect_fields["reason"]),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields=dict(single_target_stack_redirect_fields["fields"]),
                matched_signals=list(single_target_stack_redirect_fields["signals"]),
            )
        )

    if "DestroyTargetEffect" in effect_classes and _artifact_or_enchantment_source_text(rules_text):
        if "GainLifeTargetControllerEffect" in effect_classes and (
            "gainlifetargetcontrollereffect(4)" in _normalized_rules_text(rules_text)
            or _oracle_has(rules_text, "controller gains 4 life")
        ):
            candidates.append(
                _candidate(
                    effect="remove_permanent",
                    scope="artifact_or_enchantment_removal_lifegain_v1",
                    reason="XMage structure shows destroy target artifact or enchantment plus gain-4-to-target-controller rider.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "target": "artifact_or_enchantment",
                        "target_controller_gains_life": 4,
                        "instant": "INSTANT" in card_types,
                    },
                    matched_signals=["DestroyTargetEffect", "GainLifeTargetControllerEffect", "artifact_or_enchantment"],
                )
            )
        elif (
            "SpellsCostIncreasingAllEffect" in effect_classes
            and "SacrificeSourceCost" in cost_classes
            and (
                _oracle_has(
                    rules_text,
                    "artifact and enchantment spells your opponents cast cost {2} more to cast",
                )
                or "spellscostincreasingalleffect(2" in _normalized_rules_text(rules_text)
            )
        ):
            candidates.append(
                _candidate(
                    effect="remove_permanent",
                    scope="aura_of_silence_tax_and_sacrifice_removal_waiver_v1",
                    reason="XMage structure matches Aura of Silence tax static ability plus sacrifice-self artifact/enchantment removal activation.",
                    ability_kind="activated",
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "target": "artifact_or_enchantment",
                        "activation_cost": "sacrifice_self",
                        "taxes_opponent_artifact_enchantment_spells": 2,
                    },
                    matched_signals=[
                        "DestroyTargetEffect",
                        "SpellsCostIncreasingAllEffect",
                        "SacrificeSourceCost",
                        "artifact_or_enchantment",
                    ],
                )
            )
        elif "SacrificeSourceCost" in cost_classes:
            candidates.append(
                _candidate(
                    effect="remove_permanent",
                    scope="activated_sacrifice_self_destroy_artifact_or_enchantment_v1",
                    reason="XMage structure shows a sacrifice-self activated ability that destroys target artifact or enchantment.",
                    ability_kind="activated",
                    requires_runtime_executor=True,
                    extra_effect_fields={
                        "target": "artifact_or_enchantment",
                        "activation_cost": "sacrifice_self",
                    },
                    matched_signals=["DestroyTargetEffect", "SacrificeSourceCost", "artifact_or_enchantment"],
                )
            )

    if (
        "PhaseOutTargetEffect" in effect_classes
        and "TargetPermanent" in target_classes
        and (
            "FilterControlledPermanent" in filter_classes
            or "nonland permanents you control" in normalized_text
        )
        and ("nonland" in normalized_text or "cardtype.land.getpredicate" in normalized_text)
    ):
        candidates.append(
            _candidate(
                effect="phase_out",
                scope="target_nonland_permanents_you_control_phase_out_v1",
                reason=(
                    "XMage uses PhaseOutTargetEffect with a controlled nonland permanent filter; "
                    "ManaLoom can model this as phasing out all controlled nonland permanents."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=False,
                target_constraints={
                    "controller_scope": "source_controller",
                    "card_types": ["permanent"],
                    "exclude_card_types": ["land"],
                    "target_count": "any_number",
                },
                extra_effect_fields={
                    "instant": "INSTANT" in card_types,
                    "convoke": "ConvokeAbility" in ability_classes,
                    "target": "nonland_permanents_you_control",
                    "phase_out_all_permanents_you_control": True,
                    "phase_out_includes_lands": False,
                    "choice_model": "phase_out_all_legal_nonland_permanents_you_control",
                },
                matched_signals=[
                    "PhaseOutTargetEffect",
                    "TargetPermanent",
                    "FilterControlledPermanent",
                    "nonland",
                ],
            )
        )

    if (
        "DamagePlayersEffect" in effect_classes
        and "DamageAllEffect" in effect_classes
        and "BlightCost" in cost_classes
        and xmage_class_name == "SoulImmolation"
        and card_types == {"SORCERY"}
        and not ability_classes
        and (
            "filter_opponents_permanent_creatures" in normalized_text
            or "filter_opponents_permanent_a_creature" in normalized_text
            or "each creature they control" in normalized_text
        )
        and (
            "greatestamongpermanentsvalue.toughness_controlled_creatures" in normalized_text
            or "greatest toughness among creatures you control" in normalized_text
        )
    ):
        candidates.append(
            _candidate(
                effect="damage_each_opponent_and_opponent_creatures",
                scope="blight_x_damage_each_opponent_and_opponent_creatures_v1",
                reason=(
                    "XMage Soul Immolation uses variable BlightCost X bounded by controlled-creature toughness, "
                    "then DamagePlayersEffect and DamageAllEffect over opponents' creatures."
                ),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "requires_blight_x": True,
                    "x_value_source": "blight_greatest_toughness_controlled_creature",
                    "additional_cost_kind": "blight_x",
                    "target_controller": "opponents",
                    "damage_scope": "each_opponent_and_creatures_they_control",
                    "damage_amount_source": "x_value",
                    "sorcery": True,
                },
                matched_signals=[
                    "BlightCost",
                    "GetXValue",
                    "GreatestAmongPermanentsValue.TOUGHNESS_CONTROLLED_CREATURES",
                    "DamagePlayersEffect",
                    "DamageAllEffect",
                    "FILTER_OPPONENTS_PERMANENT_CREATURES",
                ],
            )
        )

    if (
        "DamagePlayersEffect" in effect_classes
        and not ability_classes
        and card_types <= {"INSTANT", "SORCERY"}
        and (
            "targetcontroller.opponent" in normalized_text
            or "each opponent" in normalized_text
        )
    ):
        amount = _first_int(r"damageplayerseffect\((\d+)", normalized_text)
        if amount is None:
            amount = _first_int(r"deals\s+(\d+)\s+damage\s+to\s+each\s+opponent", normalized_text)
        if amount is not None:
            candidates.append(
                _candidate(
                    effect="damage_each_opponent",
                    scope="spell_damage_each_opponent_v1",
                    reason=(
                        "XMage uses one-shot DamagePlayersEffect targeting opponents; "
                        "ManaLoom can resolve this as damage to each live opponent."
                    ),
                    ability_kind=ability_kind,
                    requires_runtime_executor=False,
                    extra_effect_fields={
                        "amount": amount,
                        "damage": amount,
                        "target_controller": "opponents",
                        "instant": "INSTANT" in card_types,
                        "sorcery": "SORCERY" in card_types,
                    },
                    matched_signals=[
                        "DamagePlayersEffect",
                        "TargetController.OPPONENT",
                        "one_shot",
                ],
            )
        )

    if (
        xmage_class_name == "BedlamReveler"
        and card_types == {"CREATURE"}
        and {
            "DiscardHandControllerEffect",
            "DrawCardSourceControllerEffect",
            "SpellCostReductionForEachSourceEffect",
        }.issubset(effect_classes)
        and {
            "EntersBattlefieldTriggeredAbility",
            "ProwessAbility",
            "SimpleStaticAbility",
        }.issubset(ability_classes)
        and (
            _oracle_has(rules_text, "discard your hand", "draw three cards")
            or (
                "discardhandcontrollereffect" in normalized_text
                and "drawcardsourcecontrollereffect(3)" in normalized_text
                and "cardsincontrollergraveyardcount(staticfilters.filter_card_instant_and_sorcery)" in normalized_text
            )
        )
    ):
        candidates.append(
            _candidate(
                effect="creature",
                scope="front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1",
                reason=(
                    "XMage Bedlam Reveler is a creature spell with prowess, an ETB that discards your hand "
                    "then draws three cards, and a self-only graveyard-count cost reduction."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=False,
                extra_effect_fields={
                    "is_creature_permanent": True,
                    "power": 3,
                    "toughness": 4,
                    "keywords": ["prowess"],
                    "etb_discard_hand_then_draw_count": 3,
                    "cost_reduction_applies_to": "this_spell",
                    "cost_reduction_generic": 1,
                    "cost_reduction_amount_source": "instant_sorcery_cards_in_your_graveyard_count",
                    "graveyard_count_card_types": ["instant", "sorcery"],
                },
                matched_signals=[
                    "SpellCostReductionForEachSourceEffect",
                    "DiscardHandControllerEffect",
                    "DrawCardSourceControllerEffect",
                    "ProwessAbility",
                    "EntersBattlefieldTriggeredAbility",
                ],
            )
        )

    if (
        "DestroyAllEffect" in effect_classes
        and card_types == {"SORCERY"}
        and not ability_classes
        and xmage_class_name == "Ultima"
        and "EndTurnEffect" in effect_classes
        and (
            "cardtype.artifact.getpredicate" in normalized_text
            or "artifacts and creatures" in normalized_text
        )
        and (
            "cardtype.creature.getpredicate" in normalized_text
            or "artifacts and creatures" in normalized_text
        )
    ):
        candidates.append(
            _candidate(
                effect="board_wipe",
                scope="destroy_all_artifacts_and_creatures_end_turn_v1",
                reason=(
                    "XMage Ultima resolves DestroyAllEffect over artifacts and creatures, then EndTurnEffect; "
                    "ManaLoom can model this as an artifact/creature board wipe that requests current-turn termination."
                ),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "destroy_card_types": ["artifact", "creature"],
                    "destroy_all_artifacts": True,
                    "destroy_all_creatures": True,
                    "destination": "graveyard",
                    "end_the_turn": True,
                    "turn_end_scope": "current_turn_after_resolution",
                    "sorcery": True,
                },
                matched_signals=[
                    "DestroyAllEffect",
                    "EndTurnEffect",
                    "CardType.ARTIFACT",
                    "CardType.CREATURE",
                ],
            )
        )

    if (
        "DestroyAllEffect" in effect_classes
        and card_types == {"SORCERY"}
        and not ability_classes
        and (
            "staticfilters.filter_lands" in normalized_text
            or "destroy all lands" in normalized_text
        )
    ):
        candidates.append(
            _candidate(
                effect="board_wipe",
                scope="destroy_all_lands_v1",
                reason=(
                    "XMage uses DestroyAllEffect with the lands filter; "
                    "ManaLoom can model this as destroying all land permanents."
                ),
                ability_kind="one_shot",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "destroy_card_types": ["land"],
                    "destroy_all_lands": True,
                    "destination": "graveyard",
                    "sorcery": True,
                },
                matched_signals=[
                    "DestroyAllEffect",
                    "FILTER_LANDS",
                ],
            )
        )

    has_mana_ability = any("ManaAbility" in cls or cls == "SimpleManaAbility" for cls in ability_classes)
    has_mana_effect = any(
        "ManaEffect" in cls
        or cls.startswith("AddMana")
        or cls in {"BasicManaEffect", "DynamicManaEffect"}
        for cls in effect_classes
    )
    if not candidates and card_types and card_types <= {"INSTANT", "SORCERY"} and has_mana_effect:
        produces = "WUBRG"
        if "redmana" in normalized_text or "red mana" in normalized_text or "{r}" in normalized_text:
            produces = "R"
        elif "blackmana" in normalized_text or "black mana" in normalized_text or "{b}" in normalized_text:
            produces = "B"
        elif "greenmana" in normalized_text or "green mana" in normalized_text or "{g}" in normalized_text:
            produces = "G"
        elif "whitemana" in normalized_text or "white mana" in normalized_text or "{w}" in normalized_text:
            produces = "W"
        elif "bluemana" in normalized_text or "blue mana" in normalized_text or "{u}" in normalized_text:
            produces = "U"
        candidates.append(
            _candidate(
                effect="ramp_ritual",
                scope="xmage_spell_mana_ritual_variant_review_v1",
                reason=(
                    "XMage exposes a one-shot spell mana effect; ManaLoom can batch it as a ritual "
                    "family item and split exact dynamic/counting behavior during focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                    "produces": produces,
                    "dynamic_mana_amount": "DynamicManaEffect" in effect_classes,
                    "mana_effect_classes": sorted(effect_classes & {"BasicManaEffect", "DynamicManaEffect"}),
                },
                matched_signals=["spell_mana_effect"],
            )
        )
    if not candidates and "LAND" in card_types and (has_mana_ability or has_mana_effect):
        mana_produced = _first_int(r"ColorlessMana\((\d+)\)", rules_text)
        if mana_produced is None:
            mana_produced = 1
        produces = "WUBRG" if any("AnyColor" in cls or "DynamicMana" in cls for cls in ability_classes) else "C"
        if "WhiteManaAbility" in ability_classes:
            produces = "W"
        elif "BlueManaAbility" in ability_classes:
            produces = "U"
        elif "BlackManaAbility" in ability_classes:
            produces = "B"
        elif "RedManaAbility" in ability_classes:
            produces = "R"
        elif "GreenManaAbility" in ability_classes:
            produces = "G"
        activation_requires_tap = "TapSourceCost" in cost_classes
        activation_requires_sacrifice = "SacrificeSourceCost" in cost_classes
        mana_effect_classes = {
            cls
            for cls in effect_classes
            if "ManaEffect" in cls or cls.startswith("AddMana") or cls in {"BasicManaEffect", "DynamicManaEffect"}
        }
        nonmana_effect_classes = sorted(effect_classes - mana_effect_classes)
        exact_single_color_tap_mode = (
            mana_produced == 1
            and produces in {"W", "U", "B", "R", "G"}
            and activation_requires_tap
            and not activation_requires_sacrifice
        )
        color_name_by_symbol = {
            "W": "white",
            "U": "blue",
            "B": "black",
            "R": "red",
            "G": "green",
        }
        scope = "xmage_land_mana_source_variant_review_v1"
        if exact_single_color_tap_mode:
            color_name = color_name_by_symbol[produces]
            suffix = "_nonmana_ability_pending" if nonmana_effect_classes else "_source"
            scope = f"land_tap_one_{color_name}_mana{suffix}_v1"
        extra_fields = {
            "is_mana_source": True,
            "permanent_type": "land",
            "mana_produced": mana_produced,
            "produces": produces,
            "activation_requires_tap": activation_requires_tap,
            "activation_requires_sacrifice": activation_requires_sacrifice,
            "conditional_any_color_mana": any("ConditionalAnyColorManaAbility" in cls for cls in ability_classes),
        }
        if nonmana_effect_classes:
            extra_fields.update(
                {
                    "nonmana_abilities_require_separate_scope": True,
                    "nonmana_effect_classes": nonmana_effect_classes,
                    "nonmana_abilities_status": "separate_scope_required_before_full_card_promotion",
                }
            )
        candidates.append(
            _candidate(
                effect="ramp_permanent",
                scope=scope,
                reason=(
                    "XMage marks this land as a mana source; ManaLoom can route it to the "
                    "land/ramp family for focused review instead of manual card-by-card modeling."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=not exact_single_color_tap_mode,
                extra_effect_fields=extra_fields,
                matched_signals=["LAND", "mana_source", *sorted(ability_classes & {"SimpleManaAbility", "ColorlessManaAbility", "ConditionalAnyColorManaAbility"})],
            )
        )

    if not candidates and "ARTIFACT" in card_types and (has_mana_ability or has_mana_effect):
        mana_produced = _first_int(r"ColorlessMana\((\d+)\)", rules_text) or 1
        candidates.append(
            _candidate(
                effect="ramp_permanent",
                scope="xmage_artifact_mana_source_variant_review_v1",
                reason=(
                    "XMage exposes artifact mana-source behavior; ManaLoom can batch it as a ramp "
                    "permanent review item while preserving any non-mana rider for focused tests."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    "is_mana_source": True,
                    "permanent_type": "artifact",
                    "mana_produced": mana_produced,
                    "produces": "WUBRG" if any("AnyColor" in cls for cls in ability_classes | effect_classes) else "C",
                    "activation_requires_tap": "TapSourceCost" in cost_classes,
                    "activation_requires_sacrifice": "SacrificeSourceCost" in cost_classes,
                },
                matched_signals=["ARTIFACT", "mana_source"],
            )
        )

    if (
        not candidates
        and xmage_class_name == "NehebTheEternal"
        and card_types == {"CREATURE"}
        and effect_classes == {"DynamicManaEffect"}
        and {"AfflictAbility", "BeginningOfPostcombatMainTriggeredAbility"}.issubset(ability_classes)
        and not cost_classes
        and "opponents have lost this turn" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="ramp_engine",
                scope="postcombat_main_add_red_for_opponents_life_lost_this_turn_v1",
                reason=(
                    "XMage exposes Neheb's postcombat-main trigger using "
                    "OpponentsLostLifeCount and DynamicManaEffect; ManaLoom can "
                    "model the exact red mana burst from opponents' life lost this turn."
                ),
                ability_kind="triggered",
                requires_runtime_executor=False,
                extra_effect_fields={
                    "is_creature_permanent": True,
                    "permanent_type": "creature",
                    "power": 4,
                    "toughness": 6,
                    "afflict": 3,
                    "trigger": "beginning_postcombat_main",
                    "postcombat_main_add_red_for_opponents_life_lost_this_turn": True,
                    "opponents_lost_life_this_turn": True,
                    "mana_added_per_opponent_life_lost": 1,
                    "produces": "R",
                    "mana_color": "red",
                    "dynamic_mana_amount": True,
                    "mana_amount_source": "opponents_lost_life_count_this_turn",
                },
                matched_signals=[
                    "NehebTheEternal",
                    "BeginningOfPostcombatMainTriggeredAbility",
                    "DynamicManaEffect",
                    "OpponentsLostLifeCount",
                    "AfflictAbility",
                ],
            )
        )

    if not candidates and ("CREATURE" in card_types) and (has_mana_ability or has_mana_effect):
        candidates.append(
            _candidate(
                effect="ramp_permanent",
                scope="xmage_creature_mana_source_variant_review_v1",
                reason=(
                    "XMage exposes creature mana-source behavior; ManaLoom can batch it with ramp "
                    "creature review instead of leaving it as an untyped manual model."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    "is_mana_source": True,
                    "permanent_type": "creature",
                    "activation_requires_tap": "TapSourceCost" in cost_classes,
                },
                matched_signals=["CREATURE", "mana_source"],
            )
        )

    if not candidates and "ExileThenReturnTargetEffect" in effect_classes:
        tapped = "tapped" in normalized_text
        delayed = (
            "next end step" in normalized_text
            or "delayedtriggeredability" in normalized_text
            or "return at the beginning" in normalized_text
        )
        candidates.append(
            _candidate(
                effect="blink",
                scope="xmage_exile_then_return_target_variant_review_v1",
                reason=(
                    "XMage exposes ExileThenReturnTargetEffect; ManaLoom can batch it as a blink/zone "
                    "transition family and split immediate, tapped, and delayed-return variants by Oracle text."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields={
                    "zone_transition": "exile_then_return",
                    "destination": "battlefield",
                    "return_tapped": tapped,
                    "return_timing": "delayed_end_step" if delayed else "immediate_or_same_resolution",
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                },
                matched_signals=["ExileThenReturnTargetEffect"],
            )
        )

    if not candidates and (
        "CantCastMoreThanOneSpellEffect" in effect_classes
        or "EtherswornCanonistReplacementEffect" in effect_classes
    ):
        restricted_spell_scope = "nonartifact_spells" if "nonartifact" in normalized_text else "spells"
        if "noncreature" in normalized_text:
            restricted_spell_scope = "noncreature_spells"
        candidates.append(
            _candidate(
                effect="passive",
                scope="static_one_spell_per_turn_restriction_variant_review_v1",
                reason=(
                    "XMage exposes a one-spell-per-turn static restriction; ManaLoom should keep it "
                    "as a passive rule family until exact player scope and exceptions are reviewed."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "static_rule_restriction": True,
                    "spell_limit_per_turn": 1,
                    "restricted_spell_scope": restricted_spell_scope,
                    "restriction_controller_scope": "each_player",
                },
                matched_signals=[
                    signal
                    for signal in ["CantCastMoreThanOneSpellEffect", "EtherswornCanonistReplacementEffect"]
                    if signal in effect_classes
                ],
            )
        )

    if not candidates and "CastAsThoughItHadFlashAllEffect" in effect_classes:
        applies_to_card_types: list[str] = []
        if "sorcery" in normalized_text:
            applies_to_card_types.append("sorcery")
        if "instant" in normalized_text:
            applies_to_card_types.append("instant")
        if "creature" in normalized_text:
            applies_to_card_types.append("creature")
        candidates.append(
            _candidate(
                effect="passive",
                scope="static_cast_as_flash_permission_variant_review_v1",
                reason=(
                    "XMage exposes CastAsThoughItHadFlashAllEffect; ManaLoom can batch it as a "
                    "static timing-permission family instead of treating it as an untyped manual model."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "grants_cast_as_flash": True,
                    "applies_to_card_types": applies_to_card_types or ["spells"],
                    "timing_permission_scope": "source_controller",
                },
                matched_signals=["CastAsThoughItHadFlashAllEffect"],
            )
        )

    if not candidates and "ChooseNewTargetsTargetEffect" in effect_classes:
        candidates.append(
            _candidate(
                effect="redirect_target",
                scope="xmage_choose_new_targets_variant_review_v1",
                reason=(
                    "XMage exposes ChooseNewTargetsTargetEffect; ManaLoom can batch it as a stack "
                    "target-redirection family and split copy-vs-retarget behavior during focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints or {"zone": "stack"},
                extra_effect_fields={
                    "chooses_new_targets": True,
                    "target_scope": "spell_or_ability",
                },
                matched_signals=["ChooseNewTargetsTargetEffect"],
            )
        )

    if not candidates and "CopyTargetStackObjectEffect" in effect_classes:
        candidates.append(
            _candidate(
                effect="copy_spell",
                scope="xmage_copy_stack_object_variant_review_v1",
                reason=(
                    "XMage exposes CopyTargetStackObjectEffect; ManaLoom can route it to the copy-spell "
                    "family and split trigger/cost/target modes before PG promotion."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints or {"zone": "stack"},
                extra_effect_fields={
                    "copy_stack_object": True,
                    "may_choose_new_targets": "choose new target" in normalized_text
                    or "choose new targets" in normalized_text,
                },
                matched_signals=["CopyTargetStackObjectEffect"],
            )
        )

    if not candidates and "DamageMultiEffect" in effect_classes:
        candidates.append(
            _candidate(
                effect="multi_target_damage",
                scope="xmage_multi_target_damage_variant_review_v1",
                reason=(
                    "XMage exposes DamageMultiEffect; ManaLoom can batch it with targeted interaction "
                    "and split exact target count, division, and prevention rules during focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields={
                    "multi_target_damage": True,
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                },
                matched_signals=["DamageMultiEffect"],
            )
        )

    if not candidates and "UntapTargetEffect" in effect_classes:
        target_card_types: list[str] = []
        if "artifact" in normalized_text or any("Artifact" in cls for cls in target_classes | filter_classes):
            target_card_types.append("artifact")
        if "creature" in normalized_text or any("Creature" in cls for cls in target_classes | filter_classes):
            target_card_types.append("creature")
        candidates.append(
            _candidate(
                effect="untap_target",
                scope="xmage_targeted_untap_variant_review_v1",
                reason=(
                    "XMage exposes UntapTargetEffect outside the land-untap family; ManaLoom can batch "
                    "it as targeted untap utility and split artifact/creature/activation-cost behavior."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields={
                    "untap_target": True,
                    "untap_target_card_types": target_card_types or ["permanent"],
                    "activation_requires_tap": "TapSourceCost" in cost_classes,
                },
                matched_signals=["UntapTargetEffect"],
            )
        )

    if not candidates and "GainLifeEffect" in effect_classes and not any("LoseLife" in cls for cls in effect_classes):
        amount = _first_int(r"gainlifeeffect\((\d+)\)", normalized_text)
        scope = "xmage_life_gain_variant_review_v1"
        fields: dict[str, Any] = {
            "gain_life": amount,
            "instant": "INSTANT" in card_types,
            "sorcery": "SORCERY" in card_types,
        }
        if "double" in normalized_text and "life total" in normalized_text:
            scope = "double_target_player_life_total_variant_review_v1"
            fields = {
                "life_total_change": "double_target_player_life_total",
                "target": "player",
                "sorcery": "SORCERY" in card_types,
            }
        candidates.append(
            _candidate(
                effect="life_total_set" if "life_total_change" in fields else "life_gain",
                scope=scope,
                reason=(
                    "XMage exposes GainLifeEffect; ManaLoom can batch life-total changes separately "
                    "from battle-damage behavior and require exact Oracle review before promotion."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields=fields,
                matched_signals=["GainLifeEffect"],
            )
        )

    if not candidates and (
        any("Search" in cls for cls in effect_classes)
        or "search your library" in normalized_text
        or "searchlibrary" in normalized_text
    ):
        destination = "hand"
        if "graveyard" in normalized_text or any("Graveyard" in cls for cls in effect_classes):
            destination = "graveyard"
        if "battlefield" in normalized_text or any("Battlefield" in cls or "PutInPlay" in cls for cls in effect_classes):
            destination = "battlefield"
        if "exile" in normalized_text or any("Exile" in cls for cls in effect_classes):
            destination = "exile"
        candidates.append(
            _candidate(
                effect="tutor",
                scope="xmage_library_search_variant_review_v1",
                reason=(
                    "XMage exposes library-search behavior; ManaLoom can batch this as a tutor/search "
                    "family and derive exact target/destination constraints during focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields={
                    "tutor_destination": destination,
                    "target": "library_card",
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                },
                matched_signals=["Search", "library"],
            )
        )

    if not candidates and xmage_class_name == "KarnsSylex":
        candidates.append(
            _candidate(
                effect="passive",
                scope="legendary_artifact_tapped_life_payment_lock_x_tap_exile_destroy_nonland_mv_lte_x_v1",
                reason=(
                    "XMage structure matches Karn's Sylex: legendary artifact enters tapped, prevents "
                    "life payments for spells/nonmana abilities, and has an X, tap, exile activated "
                    "ability that destroys nonland permanents with mana value X or less."
                ),
                ability_kind="static_and_activated",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "permanent_type": "artifact",
                    "legendary": True,
                    "enters_battlefield_tapped": True,
                    "players_cant_pay_life_to_cast_spells_or_nonmana_abilities": True,
                    "activation_requires_tap": True,
                    "activation_exiles_source": True,
                    "activation_only_as_sorcery": True,
                    "activated_destroy_nonland_permanents_mana_value_x_or_less": True,
                },
                matched_signals=[
                    "EntersBattlefieldTappedAbility",
                    "CantPayLifeOrSacrificeAbility",
                    "ActivateAsSorceryActivatedAbility",
                    "KarnsSylexDestroyEffect",
                    "ExileSourceCost",
                    "TapSourceCost",
                ],
            )
        )

    if not candidates and xmage_class_name == "NaktamunLorespinner":
        candidates.append(
            _candidate(
                effect="creature",
                scope="prepare_upkeep_any_player_one_or_fewer_hand_wheel_face_v1",
                reason=(
                    "XMage structure matches Naktamun Lorespinner: a 3/3 creature becomes prepared "
                    "at upkeep if any player has one or fewer cards in hand, and its prepared spell "
                    "face is Wheel of Fortune."
                ),
                ability_kind="prepare_spell",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 3,
                    "toughness": 3,
                    "subtypes": ["Jackal", "Wizard"],
                    "upkeep_prepare_if_any_player_hand_size_lte": 1,
                    "prepared_spell_face": {
                        "name": "Wheel of Fortune",
                        "effect": "draw_cards",
                        "sorcery": True,
                        "mana_cost": "{2}{R}",
                        "draw_count": 7,
                        "wheel_like": True,
                        "discard_draw_model": "each_player_discard_hand_draw_seven_v1",
                    },
                },
                matched_signals=[
                    "PrepareCard",
                    "BecomePreparedSourceEffect",
                    "DiscardHandAllEffect",
                    "DrawCardAllEffect",
                ],
            )
        )

    if not candidates and xmage_class_name == "CharmbreakerDevils":
        candidates.append(
            _candidate(
                effect="creature",
                scope="upkeep_random_instant_sorcery_graveyard_to_hand_instant_sorcery_cast_plus4_v1",
                reason=(
                    "XMage structure matches Charmbreaker Devils: beginning-of-upkeep random instant "
                    "or sorcery recursion plus +4/+0 until end of turn when controller casts an "
                    "instant or sorcery."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "power": 4,
                    "toughness": 4,
                    "subtypes": ["Devil"],
                    "upkeep_return_random_instant_sorcery_from_graveyard_to_hand": True,
                    "trigger": "instant_sorcery_cast",
                    "trigger_effect": "boost_source_until_eot",
                    "trigger_power_bonus_until_eot": 4,
                    "trigger_toughness_bonus_until_eot": 0,
                },
                matched_signals=[
                    "BeginningOfUpkeepTriggeredAbility",
                    "ReturnFromGraveyardAtRandomEffect",
                    "SpellCastControllerTriggeredAbility",
                    "BoostSourceEffect",
                ],
            )
        )

    if not candidates and (
        any("DrawCard" in cls or "Draw" in cls for cls in effect_classes)
        or re.search(r"\bdraw(?:s)?\s+(?:x|\d+|a|that many|three|two|one)\s+card", normalized_text)
    ):
        draw_count = _first_int(r"drawcardsourcecontrollereffect\((\d+)\)", normalized_text)
        if draw_count is None:
            draw_count = _first_int(r"draw\s+(\d+)\s+cards?", normalized_text)
        candidates.append(
            _candidate(
                effect="draw_cards" if card_types <= {"INSTANT", "SORCERY"} else "draw_engine",
                scope="xmage_draw_card_variant_review_v1",
                reason=(
                    "XMage exposes card-draw behavior in effect classes or static text; ManaLoom can "
                    "classify it as draw for focused runtime tests instead of manual review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    **({"draw_count": draw_count} if draw_count is not None else {}),
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                },
                matched_signals=["draw"],
            )
        )

    if not candidates and (
        "LookAtTopCardOfLibraryAnyTimeEffect" in effect_classes
        or "PlayFromTopOfLibraryEffect" in effect_classes
        or "may cast" in normalized_text
        or "without paying" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="free_cast" if ("may cast" in normalized_text or "without paying" in normalized_text) else "topdeck_play",
                scope="xmage_cast_or_play_from_alternate_zone_variant_review_v1",
                reason=(
                    "XMage exposes cast/play permission from a non-hand zone or without paying mana; "
                    "ManaLoom should route this through the free-cast/topdeck family with focused tests."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    "alternate_zone_permission": True,
                    "may_cast_without_paying_mana_cost": "without paying" in normalized_text,
                },
                matched_signals=["alternate_cast_or_play_permission"],
            )
        )

    if not candidates and (
        any(cls in effect_classes for cls in {"DestroyAllEffect", "SacrificeAllEffect", "DamageAllEffect"})
        or "destroy each" in normalized_text
        or "destroy all" in normalized_text
        or "sacrifices the rest" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="board_wipe",
                scope="xmage_mass_removal_or_sacrifice_variant_review_v1",
                reason=(
                    "XMage exposes mass destroy/sacrifice/damage behavior; ManaLoom can batch this "
                    "into the board-wipe family for exact-scope runtime review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                extra_effect_fields={
                    "mass_effect": True,
                    "instant": "INSTANT" in card_types,
                    "sorcery": "SORCERY" in card_types,
                },
                matched_signals=["mass_removal"],
            )
        )

    if not candidates and (
        xmage_class_name == "CloudOfFaeries"
        or (
            "UntapLandsEffect" in effect_classes
            and "EntersBattlefieldTriggeredAbility" in ability_classes
            and "CyclingAbility" in ability_classes
            and "CREATURE" in card_types
        )
    ):
        candidates.append(
            _candidate(
                effect="untap_land_engine",
                scope="etb_untap_up_to_two_lands_cycling_two_v1",
                reason=(
                    "XMage exposes Cloud of Faeries ETB UntapLandsEffect(2) plus Cycling {2}; "
                    "ManaLoom can execute the ETB land untap and keeps cycling as annotation."
                ),
                ability_kind="triggered",
                requires_runtime_executor=True,
                extra_effect_fields={
                    "etb_untap_lands_count": 2,
                    "etb_untap_lands_optional": True,
                    "cycling_cost": "{2}",
                    "cycling_status": "annotation_only",
                },
                matched_signals=[
                    "UntapLandsEffect",
                    "EntersBattlefieldTriggeredAbility",
                    "CyclingAbility",
                ],
            )
        )

    if not candidates and (
        "UntapLandsEffect" in effect_classes
        or ("UntapTargetEffect" in effect_classes and "land" in normalized_text)
    ):
        candidates.append(
            _candidate(
                effect="untap_land_engine",
                scope="xmage_land_untap_variant_review_v1",
                reason=(
                    "XMage exposes land untap behavior; ManaLoom can route this into the land-untap "
                    "engine family for focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                matched_signals=["UntapLandsEffect", "land"],
            )
        )

    if not candidates and (
        "SpellsCostIncreasingAllEffect" in effect_classes
        or "cost more to cast" in normalized_text
        or "can't cast" in normalized_text
        or "can cast no more than" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="passive",
                scope="xmage_static_rule_restriction_or_tax_variant_review_v1",
                reason=(
                    "XMage exposes a static rule restriction or tax; ManaLoom can group it as a "
                    "passive battlefield rule for exact-scope review."
                ),
                ability_kind="static",
                requires_runtime_executor=True,
                extra_effect_fields={"static_rule_restriction": True},
                matched_signals=["static_tax_or_restriction"],
            )
        )

    if not candidates and (
        "GainAbilityTargetEffect" in effect_classes
        or "GainProtectionFromColorTargetEffect" in effect_classes
        or "hexproof" in normalized_text
        or "shroud" in normalized_text
        or "protection from" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="grant_protection_from_chosen_color",
                scope="xmage_targeted_protection_variant_review_v1",
                reason=(
                    "XMage exposes targeted ability/protection granting; ManaLoom can group it with "
                    "targeted protection for exact ability and duration review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                extra_effect_fields={"targeted_protection_variant": True},
                matched_signals=["GainAbilityTargetEffect", "protection"],
            )
        )

    if not candidates and (
        "ReturnFromGraveyardToHandTargetEffect" in effect_classes
        or "ReturnFromGraveyardToBattlefieldTargetEffect" in effect_classes
        or "return" in normalized_text and "graveyard" in normalized_text
    ):
        candidates.append(
            _candidate(
                effect="recursion",
                scope="xmage_graveyard_return_variant_review_v1",
                reason=(
                    "XMage exposes graveyard return behavior; ManaLoom can group it as recursion for "
                    "zone/destination focused review."
                ),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
                target_constraints=target_constraints,
                matched_signals=["graveyard_return"],
            )
        )

    class_to_effect = [
        ("DestroyAllEffect", "board_wipe", "destroy_all_permanents_or_creatures_variant_v1", True),
        ("DestroyTargetEffect", "removal_destroy", "targeted_destroy_variant_v1", True),
        ("ExileTargetEffect", "removal_exile", "targeted_exile_variant_v1", True),
        ("ReturnToHandTargetEffect", "bounce", "targeted_return_to_hand_variant_v1", True),
        ("ReturnFromGraveyardToBattlefieldTargetEffect", "recursion", "graveyard_to_battlefield_variant_v1", True),
        ("DamageTargetEffect", "direct_damage", "targeted_damage_variant_v1", True),
        ("DamageAllEffect", "sweeper_damage", "damage_all_variant_v1", True),
        ("DrawCardSourceControllerEffect", "draw_cards", "source_controller_draw_variant_v1", False),
        ("CounterTargetEffect", "counter_spell", "counter_target_stack_object_variant_v1", True),
        ("AddCountersTargetEffect", "add_counters", "targeted_add_counters_variant_v1", True),
        ("AddCountersSourceEffect", "add_counters", "source_add_counters_variant_v1", True),
    ]
    for class_name, effect, scope, requires_runtime in class_to_effect:
        if class_name in effect_classes:
            candidates.append(
                _candidate(
                    effect=effect,
                    scope=scope,
                    reason=f"XMage uses {class_name}.",
                    ability_kind=ability_kind,
                    requires_runtime_executor=requires_runtime,
                    target_constraints=target_constraints,
                    matched_signals=[class_name],
                )
            )

    deduped: list[dict[str, Any]] = []
    seen: set[str] = set()
    for candidate in candidates:
        key = str(candidate["effect_json"].get("effect")) + "|" + str(candidate["effect_json"].get("battle_model_scope"))
        if key not in seen:
            seen.add(key)
            deduped.append(candidate)

    primary = deduped[0] if deduped else _candidate(
        effect="external_reference_required_manual_model",
        scope="xmage_reference_requires_manual_model_review_v1",
        reason="No conservative mapping matched; use XMage source as a manual review reference only.",
        ability_kind=ability_kind,
        requires_runtime_executor=True,
        target_constraints=target_constraints,
        matched_signals=[],
    )
    return {
        "status": "ready",
        "review_policy": "candidate_only_never_promote_without_oracle_and_tests",
        "primary_candidate": primary,
        "candidates": deduped or [primary],
    }
