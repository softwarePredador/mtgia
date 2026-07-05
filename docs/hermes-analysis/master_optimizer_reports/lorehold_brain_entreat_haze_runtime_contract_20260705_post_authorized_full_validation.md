# Lorehold Brain/Entreat/Haze Runtime Contract

- Generated at: `2026-07-05T11:38:23Z`
- Status: `runtime_contracts_drafted_no_battle_ready_keep_607`
- Current baseline: `deck_607`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Source DB mutated: `False`
- Deck 607 mutated: `False`

## Summary

| Metric | Value |
| --- | ---: |
| `runtime_contract_count` | `3` |
| `xmage_class_found_count` | `3` |
| `cards_with_active_rule_count` | `1` |
| `battle_ready_now_count` | `0` |
| `best_first_runtime_contract` | `Entreat the Angels` |

## Contracts

| Card | Readiness | XMage Signals | Active Rules | Required Runtime |
| --- | --- | --- | ---: | --- |
| Entreat the Angels | `best_first_runtime_contract_candidate` | CreateTokenEffect, AngelToken, GetXValue, MiracleAbility | `0` | x_spell_cost_planning_for_normal_and_miracle_cast; lorehold_first_draw_miracle_selection_for_x_spell; create_x_4_4_flying_angel_tokens; closing_window_pressure_scoring_for_token_board; replay_x_value_miracle_cost_and_tokens_created |
| Brain in a Jar | `blocked_requires_new_runtime_family` | AddCountersSourceEffect, BrainInAJarCastEffect, RemoveVariableCountersSourceCost, ScryEffect, ManaValuePredicate | `1` | activated_add_charge_counter_then_tap_cost; select_hand_instant_or_sorcery_by_exact_mana_value; cast_selected_spell_without_paying_mana_cost; activated_remove_x_charge_counters_scry_x; replay_charge_counter_and_free_cast_decision_fields |
| Haze of Rage | `blocked_complex_combo_runtime` | BuybackAbility, BoostControlledEffect, StormAbility | `0` | storm_copy_count_for_non_damage_boost_spell; buyback_optional_additional_cost_and_return_to_hand; global_creature_plus_power_until_end_of_turn_per_copy; storm_kiln_artist_magecraft_treasure_on_cast_and_copy; combo_loop_guard_and_cut_safety_preflight |

## Storm-Kiln Dependency

- XMage class found: `True`
- Active rule count: `2`
- Annotation only: `True`
- Note: Storm-Kiln Artist exists locally, but the current rule scope is annotation-only; the Haze combo needs executable magecraft treasure on cast and copied spells.

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: XMage confirms the three card implementations, but ManaLoom still lacks card-level runtime contracts and safe-cut evidence. Entreat is the best first runtime candidate because it reuses the Lorehold miracle thesis and token board pressure.
