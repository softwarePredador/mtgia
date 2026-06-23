#!/usr/bin/env python3
"""Build review-only ManaLoom focused test scenario drafts from XMage hints."""

from __future__ import annotations

from typing import Any


def build_suggested_test_scenarios(
    index_entry: dict[str, Any],
    effect_hint: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    primary = (effect_hint or {}).get("primary_candidate") or {}
    effect_json = primary.get("effect_json") or {}
    effect = str(effect_json.get("effect") or "external_reference_required_manual_model")
    card_name = str(index_entry.get("card_name") or index_entry.get("xmage_card_name") or "Card")

    scenarios: list[dict[str, Any]] = []
    for idx, title in enumerate(primary.get("suggested_tests") or [f"focused behavior scenario for {effect}"], start=1):
        scenarios.append(
            {
                "id": f"{_safe_id(card_name)}_{idx}",
                "title": title,
                "card_name": card_name,
                "effect": effect,
                "setup": _setup_for_effect(effect),
                "actions": _actions_for_effect(effect, card_name),
                "assertions": _assertions_for_effect(effect),
                "status": "draft_requires_manual_review",
            }
        )
    return scenarios


def markdown_scenarios(index_entry: dict[str, Any], effect_hint: dict[str, Any] | None = None) -> str:
    lines = [f"### Suggested focused tests for {index_entry.get('card_name')}", ""]
    for scenario in build_suggested_test_scenarios(index_entry, effect_hint):
        lines.extend(
            [
                f"- `{scenario['id']}`: {scenario['title']}",
                f"  - setup: {scenario['setup']}",
                f"  - actions: {scenario['actions']}",
                f"  - assertions: {scenario['assertions']}",
            ]
        )
    return "\n".join(lines).rstrip()


def _safe_id(value: str) -> str:
    out = []
    for char in value.lower():
        out.append(char if char.isalnum() else "_")
    return "_".join(part for part in "".join(out).split("_") if part)[:48] or "card"


def _setup_for_effect(effect: str) -> str:
    mapping = {
        "static_cost_reduction": "source controller controls the permanent; hand contains a matching and non-matching spell",
        "vow_counter_each_player_sacrifice_rest": "each player controls at least two creatures and the source controller can cast the spell",
        "gift_destroy_all_creatures_return_own_destroyed_creature": "both players control creatures; source controller has a creature that can die this way",
        "token_maker": "source controller can cast the card; battlefield has representative affected/non-affected creatures if needed",
        "selective_nonland_sacrifice": "each player controls artifact, creature, enchantment, planeswalker and extra nonland permanents",
        "mana_rock_with_sacrifice_draw": "source controller controls the artifact untapped and has enough mana to activate draw mode",
        "other_turn_untapping_any_color_mana_rock": "source controller controls the artifact tapped; at least one opponent turn can advance to untap",
        "other_turn_untapping_target_player_colorless_mana_rock": "source controller controls the artifact untapped; a chosen player target is available",
        "discard_trigger_modal_draw_treasure_opponent_life_loss": "source controller controls the artifact and can discard multiple cards across the turn",
        "exile_instant_sorcery_boost_combat_damage_copy_cast": "source controller has a target instant or sorcery in graveyard and at least one creature able to deal combat damage",
    }
    return mapping.get(effect, "minimal deterministic board state with legal targets and enough mana")


def _actions_for_effect(effect: str, card_name: str) -> str:
    mapping = {
        "static_cost_reduction": f"cast a matching spell and a non-matching spell while {card_name} is active",
        "vow_counter_each_player_sacrifice_rest": f"cast {card_name}; provide deterministic creature choices for each player; attempt protected attack",
        "gift_destroy_all_creatures_return_own_destroyed_creature": f"cast {card_name} with and without gift promised",
        "token_maker": f"cast or resolve {card_name}",
        "selective_nonland_sacrifice": f"cast {card_name}; choose retained permanents by type/player",
        "mana_rock_with_sacrifice_draw": f"activate mana ability, then activate sacrifice draw ability for {card_name}",
        "other_turn_untapping_any_color_mana_rock": f"tap {card_name} for mana, advance to another player's untap step, then tap it again",
        "other_turn_untapping_target_player_colorless_mana_rock": f"tap {card_name}, choose a player for the mana, advance through another player's untap step",
        "discard_trigger_modal_draw_treasure_opponent_life_loss": f"resolve discard triggers for {card_name}, choosing each available mode no more than once that turn",
        "exile_instant_sorcery_boost_combat_damage_copy_cast": f"cast {card_name}, exile the graveyard spell, deal combat damage with a controlled creature, and cast the copy",
    }
    return mapping.get(effect, f"cast or activate {card_name} through the relevant supported phase")


def _assertions_for_effect(effect: str) -> str:
    mapping = {
        "static_cost_reduction": "matching spell cost is reduced exactly as modeled; non-matching spell is unchanged",
        "vow_counter_each_player_sacrifice_rest": "one chosen creature per player remains with vow counter; other creatures are sacrificed; protected attack is illegal",
        "gift_destroy_all_creatures_return_own_destroyed_creature": "all creatures are destroyed; gift path returns only a valid own creature put into graveyard this way",
        "token_maker": "expected tokens, stats, abilities and duration-limited effects match the model",
        "selective_nonland_sacrifice": "selected permanents remain and all other nonland permanents are sacrificed",
        "mana_rock_with_sacrifice_draw": "mana pool increases on mana mode; draw mode sacrifices artifact and draws one card",
        "other_turn_untapping_any_color_mana_rock": "artifact untaps during each other player's untap step and produces one mana of the chosen color",
        "other_turn_untapping_target_player_colorless_mana_rock": "chosen player receives one colorless mana and artifact untaps during each other player's untap step",
        "discard_trigger_modal_draw_treasure_opponent_life_loss": "each chosen mode resolves once that turn: draw, Treasure creation, and each opponent loses 3 life",
        "exile_instant_sorcery_boost_combat_damage_copy_cast": "target card is exiled, creatures get +X/+0, combat damage creates a castable free copy",
    }
    return mapping.get(effect, "final zones, counters, life totals, targets and event log match Oracle-backed expectation")
