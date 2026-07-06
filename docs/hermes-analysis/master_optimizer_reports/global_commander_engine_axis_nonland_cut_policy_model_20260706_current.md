# Global Commander Engine Axis Nonland Cut Policy Model

- generated_at: `2026-07-06T03:59:16.449521+00:00`
- status: `engine_axis_nonland_cut_policy_applied_review_only`
- source_cycle_deck_count: `1`
- evaluated_pool_count: `1`
- evaluated_cut_count: `12`
- engine_cut_pressure_ready_count: `2`
- protected_engine_cut_count: `6`
- candidate_pair_count: `6`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure`

## Pool Policy Rows

### Deck 619 - Kaalia of the Vast - removal

- missing_roles: `removal`
- excess_roles: `engine,ramp,tutor`
- engine_cut_pressure_ready_count: `2`
- protected_engine_cut_count: `6`

| Card | Status | Bucket | Roles | Signals/Blockers |
| --- | --- | --- | --- | --- |
| `Archaeomancer's Map` | `engine_axis_policy_review_cut_pressure_ready` | `engine_overlap_excess_cut_pressure` | `engine,tutor` | - |
| `Biotransference` | `engine_axis_policy_review_cut_pressure_ready` | `engine_only_excess_cut_pressure` | `engine` | - |
| `Genji Glove` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_attack_window_or_extra_combat, kaalia_equipment_support_package, engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat,kaalia_equipment_support_package |
| `Karlach, Fury of Avernus` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_attack_window_or_extra_combat, engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat |
| `Ardenn, Intrepid Archaeologist` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_equipment_support_package, engine_card_has_commander_plan_signal:kaalia_equipment_support_package |
| `Delney, Streetwise Lookout` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_trigger_or_type_enabler, engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Maskwood Nexus` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_trigger_or_type_enabler, engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Sigarda's Aid` | `engine_axis_policy_blocks_cut_until_source_lane_review` | `protected_engine_cut_pressure` | `engine` | kaalia_equipment_support_package, engine_card_has_commander_plan_signal:kaalia_equipment_support_package |
| `Grim Tutor` | `engine_axis_policy_not_applicable_to_cut` | `non_engine_cut_outside_engine_axis_policy` | `tutor` | cut_does_not_carry_engine_role |
| `Oswald Fiddlebender` | `engine_axis_policy_not_applicable_to_cut` | `non_engine_cut_outside_engine_axis_policy` | `tutor` | cut_does_not_carry_engine_role |
| `Steelshaper's Gift` | `engine_axis_policy_not_applicable_to_cut` | `non_engine_cut_outside_engine_axis_policy` | `tutor` | kaalia_equipment_support_package, engine_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_engine_role |
| `Stoneforge Mystic` | `engine_axis_policy_not_applicable_to_cut` | `non_engine_cut_outside_engine_axis_policy` | `tutor` | kaalia_equipment_support_package, engine_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_engine_role |

| Pair | Status | Required Gate |
| --- | --- | --- |
| `+Feed the Swarm / -Archaeomancer's Map` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |
| `+Feed the Swarm / -Biotransference` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |
| `+Path to Exile / -Archaeomancer's Map` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |
| `+Path to Exile / -Biotransference` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |
| `+Swords to Plowshares / -Archaeomancer's Map` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |
| `+Swords to Plowshares / -Biotransference` | `engine_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure` |

## Blockers

- `engine_policy_cut_pressure_is_not_card_level_cut_permission`
- `candidate_copy_closed_until_usage_same_lane_and_battle_feedback_memory_exist`
- `battle_gate_closed_until_candidate_copy_strategy_matrix_and_replay_trace`

## Policy

- engine_boundary: Engine is capacity pressure when above range; it is not an add lane.
- cut_boundary: Only engine-only or excess-overlap cards become review cut pressure, and still need card-level proof.
- protection_boundary: Engine cards with missing-floor overlap or commander-plan signals are protected until source-lane review.
- mutation_boundary: This model does not choose cards, copy decks, run battle, mutate DBs, or promote packages.
