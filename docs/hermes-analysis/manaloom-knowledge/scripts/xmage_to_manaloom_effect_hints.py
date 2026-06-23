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
