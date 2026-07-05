# Lorehold Brain in a Jar Runtime/Cut Preflight

- Generated at: `2026-07-05T09:13:35Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607`
- Route planner status: `miracle_next_route_planner_selected_brain_runtime_learning_keep_607`
- Route planner selected Brain: `true`
- Route planner candidate queue governed: `true`
- Route gate valid: `true`
- Brain candidate row found: `true`
- Brain contract found: `true`
- XMage class found: `true`
- XMage signal hits: `5`
- Required runtime slices: `5`
- Exact runtime contract drafted: `true`
- Exact runtime effect scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- Brain exact adapter present: `true`
- Active Brain rule count: `0`
- Same-lane candidates reviewed: `9`
- Safe same-lane cuts: `0`
- Blocked same-lane cuts: `9`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `prepare_brain_in_a_jar_pg_package_precheck_and_mine_seed_safe_cut_no_deck_action`

## Source Reports

- `candidate_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json`
- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `exact_runtime_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_current.json`
- `route_planner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_current.json`
- `runtime_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_entreat_haze_runtime_contract_20260705_current.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Runtime State

- readiness: `blocked_requires_new_runtime_family`
- manaloom_foundation: `generic_charge_counter_and_casting_primitives_exist_but_no_card_contract`
- xmage_path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BrainInAJar.java`
- required slices: `activated_add_charge_counter_then_tap_cost, select_hand_instant_or_sorcery_by_exact_mana_value, cast_selected_spell_without_paying_mana_cost, activated_remove_x_charge_counters_scry_x, replay_charge_counter_and_free_cast_decision_fields`
- exact_contract_status: `brain_exact_runtime_contract_adapter_detected_preflight_required_keep_607`
- exact_contract_scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- exact_adapter_present: `true`

## Safe Same-Lane Cut Candidates

- None.

## Blocked Same-Lane Rows

| Cut | Value Lanes | Cut Lane | Classification | Exposure | Blockers |
| --- | --- | --- | --- | ---: | --- |
| Scroll Rack | `artifact, draw, topdeck_miracle_engine` | `early_mana` | `blocked_current_607_hard_stop` | 2957 | cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, protected_cut, structural_dependency |
| Sensei's Divining Top | `artifact, draw, topdeck_miracle_engine` | `draw` | `blocked_current_607_hard_stop` | 3816 | cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, protected_cut |
| Library of Leng | `artifact, engine, topdeck_miracle_engine` | `early_mana` | `blocked_current_607_hard_stop` | 855 | cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, structural_dependency |
| Molecule Man | `draw, topdeck_miracle_engine` | `draw` | `blocked_current_607_hard_stop` | 102 | cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protected_cut |
| The Scarlet Witch | `creature, topdeck_miracle_engine` | `misc` | `blocked_current_607_hard_stop` | 362 | cut_is_early_mana_floor_support, cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protected_cut |
| The Mind Stone | `artifact, ramp, topdeck_miracle_engine` | `early_mana` | `blocked_current_607_hard_stop` | 2312 | cut_is_early_mana_floor_support, cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, structural_dependency |
| Land Tax | `global_top_500, topdeck_miracle_engine, tutor` | `misc` | `blocked_current_607_hard_stop` | 3449 | cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot |
| Urza's Saga | `global_top_500, land, mana_base, topdeck_miracle_engine, utility_engine_land` | `mana_base` | `blocked_current_607_hard_stop` | 2656 | cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base |
| Lorehold, the Historian | `commander_center, engine, topdeck_miracle_engine` | `commander` | `blocked_current_607_hard_stop` | 5768 | commander_never_cut, cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base |

## External Confirmation

- source_lane: `official_card_text_and_rulings`
- oracle_id: `321dbd10-1d48-49fc-ba6a-1df241a53338`
- commander_legality: `legal`
- learning_signal: Brain is not generic ramp; its value depends on modeling charge counters, exact mana-value spell selection from hand, free casting, and X-counter scry.
- oracle_key_points: `artifact_mana_cost_2, first_ability_cost_1_tap, first_ability_adds_charge_counter_before_selection, free_cast_from_hand_instant_or_sorcery_by_exact_mana_value, second_ability_cost_3_tap_remove_x_charge_counters, second_ability_scry_x`
- ruling_key_points: `newly_placed_charge_counter_counts_for_spell_selection, no_priority_between_counter_addition_and_spell_choice, uses_last_known_counters_if_brain_leaves_before_resolution, alternative_costs_not_payable_when_cast_without_mana_cost, additional_costs_remain_payable_or_mandatory, x_in_mana_cost_must_be_zero`
- gatherer: https://gatherer.wizards.com/SOI/en-us/252/brain-in-a-jar
- scryfall: https://scryfall.com/card/soi/252/brain-in-a-jar
- scryfall_api: https://api.scryfall.com/cards/named?exact=Brain%20in%20a%20Jar
- scryfall_rulings_api: https://api.scryfall.com/cards/88ecfcbe-e8db-4f08-aa8b-5b7b3e6c6ce7/rulings

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- matrix_scoring_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- postgres_writes_allowed: `false`
- runtime_family_required_before_battle: `false`
- runtime_adapter_required_before_battle: `false`
- active_rule_required_before_battle: `true`
- named_safe_cut_required_before_scoring: `true`
- reason: Brain in a Jar now has an exact runtime-family contract and a ManaLoom adapter, but it still has no active card rule and no seed-safe same-lane cut in protected 607. Brain therefore remains a runtime implementation route, not a deck card.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_brain_candidate_deck
  - do_not_run_natural_battle_for_brain_from_this_preflight
  - prepare_brain_in_a_jar_pg_package_precheck_and_mine_seed_safe_cut_no_deck_action
  - after_active_rule_and_safe_cut_exist_rerun_this_preflight_before_candidate_queue_refresh
