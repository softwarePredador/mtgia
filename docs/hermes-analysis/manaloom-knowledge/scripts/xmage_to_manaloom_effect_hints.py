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
    parts = [str(oracle_text or ""), str(index_entry.get("raw_excerpt") or "")]
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
    if card_types != {"INSTANT"} or "CounterTargetEffect" not in effect_classes:
        return None

    normalized = _normalized_rules_text(rules_text)

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
