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
    if "instant and sorcery" in text or "instant or sorcery" in text:
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
                "target": "player",
                "mill_count": mill_count,
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
    if "TargetSpell" not in rules_text and "targetspell" not in _normalized_rules_text(rules_text):
        return None
    fields: dict[str, Any] = {
        "instant": "INSTANT" in card_types,
        "target": "instant_or_sorcery_spell",
        "may_choose_new_targets": True,
        "choose_new_targets_status": "may",
    }
    if "CommanderStormAbility" in ability_classes:
        fields["commander_storm"] = True
    return {
        "effect": "copy_spell",
        "scope": "copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1",
        "fields": fields,
        "reason": "XMage structure matches copying a target instant or sorcery spell on the stack.",
        "signals": ["CopyTargetStackObjectEffect", "TargetSpell"],
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
    cost_classes: set[str],
    xmage_class_name: str,
    rules_text: str,
) -> dict[str, Any] | None:
    normalized = _normalized_rules_text(rules_text)

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
            "scope": "one_mana_one_one_black_pain_mana_dork_v1",
            "fields": {
                "power": 1,
                "toughness": 1,
                "is_mana_source": True,
                "mana_produced": 1,
                "produces": "B",
                "damage_on_tap": 1,
                "tap_damage_status": "annotation_only",
            },
            "reason": "XMage structure matches a 1/1 creature that taps for black mana and deals 1 damage to its controller.",
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
            "scope": "colorless_or_any_color_pain_land_v1",
            "fields": {
                "mana_produced": 1,
                "produces": "CWUBRG",
                "life_for_colored_mana": 3,
                "life_loss_on_colored_mana_status": "annotation_only",
            },
            "reason": "XMage structure matches a land that adds colorless freely or any color while dealing 3 damage to its controller.",
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
    if effect_classes != {"BasicManaEffect"}:
        return None
    if ability_classes or cost_classes != {"SacrificeTargetCost"}:
        return None

    normalized = _normalized_rules_text(rules_text)
    is_instant = card_types == {"INSTANT"}

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

    if card_types != {"CREATURE"} or "SearchLibraryPutInHandEffect" not in effect_classes:
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
    inner_extends = _inner_extends(index_entry)
    ability_kind = _ability_kind(ability_classes)
    target_constraints = _target_constraints(target_classes, filter_classes)
    card_types = _constructor_card_types(index_entry)
    xmage_class_name = str(index_entry.get("xmage_class_name") or "").strip()
    candidates: list[dict[str, Any]] = []

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

    if "SpellsCostReductionControllerEffect" in effect_classes or "SpellCostReductionSourceEffect" in effect_classes:
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
                requires_runtime_executor=True,
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
        cost_classes=cost_classes,
        xmage_class_name=xmage_class_name,
        rules_text=rules_text,
    )
    if exact_runtime_variant_fields is not None:
        candidates.append(
            _candidate(
                effect=str(exact_runtime_variant_fields["effect"]),
                scope=str(exact_runtime_variant_fields["scope"]),
                reason=str(exact_runtime_variant_fields["reason"]),
                ability_kind=ability_kind,
                requires_runtime_executor=True,
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
