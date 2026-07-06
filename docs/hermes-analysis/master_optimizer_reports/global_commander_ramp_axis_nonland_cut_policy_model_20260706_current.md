# Global Commander Ramp Axis Nonland Cut Policy Model

- generated_at: `2026-07-06T05:29:20.652579+00:00`
- status: `ramp_axis_nonland_cut_policy_applied_review_only`
- source_cycle_deck_count: `1`
- evaluated_pool_count: `1`
- evaluated_cut_count: `24`
- ramp_cut_pressure_ready_count: `9`
- protected_ramp_cut_count: `0`
- candidate_pair_count: `9`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure`

## Pool Policy Rows

### Deck 619 - Kaalia of the Vast - removal

- missing_roles: `removal`
- excess_roles: `engine,ramp,tutor`
- ramp_cut_pressure_ready_count: `9`
- protected_ramp_cut_count: `0`

| Card | Status | Bucket | Roles | Signals/Blockers |
| --- | --- | --- | --- | --- |
| `Arcane Signet` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Basalt Monolith` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_overlap_excess_cut_pressure` | `engine,ramp` | - |
| `Burnt Offering` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Cabal Ritual` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Culling the Weak` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Dark Ritual` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Desperate Ritual` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Grim Monolith` | `ramp_axis_policy_review_cut_pressure_ready` | `ramp_only_excess_cut_pressure` | `ramp` | - |
| `Archaeomancer's Map` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine,tutor` | cut_does_not_carry_ramp_role |
| `Genji Glove` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_attack_window_or_extra_combat, kaalia_equipment_support_package, ramp_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat,kaalia_equipment_support_package, cut_does_not_carry_ramp_role |
| `Karlach, Fury of Avernus` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_attack_window_or_extra_combat, ramp_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat, cut_does_not_carry_ramp_role |
| `Ardenn, Intrepid Archaeologist` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_equipment_support_package, ramp_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_ramp_role |
| `Biotransference` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | cut_does_not_carry_ramp_role |
| `Delney, Streetwise Lookout` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_trigger_or_type_enabler, ramp_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler, cut_does_not_carry_ramp_role |
| `Maskwood Nexus` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_trigger_or_type_enabler, ramp_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler, cut_does_not_carry_ramp_role |
| `Sigarda's Aid` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_equipment_support_package, ramp_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_ramp_role |
| `Grim Tutor` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `tutor` | cut_does_not_carry_ramp_role |
| `Oswald Fiddlebender` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `tutor` | cut_does_not_carry_ramp_role |
| `Steelshaper's Gift` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `tutor` | kaalia_equipment_support_package, ramp_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_ramp_role |
| `Stoneforge Mystic` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `tutor` | kaalia_equipment_support_package, ramp_card_has_commander_plan_signal:kaalia_equipment_support_package, cut_does_not_carry_ramp_role |
| `Alicia Masters, Skilled Sculptor` | `ramp_axis_policy_blocks_non_excess_overlap` | `ramp_overlap_non_excess_requires_review` | `board_wipe,engine,ramp` | ramp_card_also_carries_non_excess_roles:board_wipe |
| `Bloodthirster` | `ramp_axis_policy_not_applicable_to_cut` | `non_ramp_cut_outside_ramp_axis_policy` | `engine` | kaalia_angel_demon_dragon_payoff, kaalia_attack_window_or_extra_combat, ramp_card_has_commander_plan_signal:kaalia_angel_demon_dragon_payoff,kaalia_attack_window_or_extra_combat, cut_does_not_carry_ramp_role |
| `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | `ramp_axis_policy_blocks_non_excess_overlap` | `ramp_overlap_non_excess_requires_review` | `draw,engine,ramp,recursion` | ramp_card_also_carries_non_excess_roles:draw,recursion |

| Pair | Status | Required Gate |
| --- | --- | --- |
| `+Feed the Swarm / -Arcane Signet` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Feed the Swarm / -Basalt Monolith` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Feed the Swarm / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Path to Exile / -Arcane Signet` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Path to Exile / -Basalt Monolith` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Path to Exile / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Swords to Plowshares / -Arcane Signet` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Swords to Plowshares / -Basalt Monolith` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |
| `+Swords to Plowshares / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_policy_pair_needs_card_level_usage_and_same_lane_proof` | `collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure` |

## Blockers

- `ramp_policy_cut_pressure_is_not_card_level_cut_permission`
- `candidate_copy_closed_until_usage_same_lane_and_battle_feedback_memory_exist`
- `battle_gate_closed_until_candidate_copy_strategy_matrix_and_replay_trace`

## Policy

- ramp_boundary: Ramp is capacity pressure when above range; it is not an add lane.
- cut_boundary: Only ramp-only or excess-overlap cards become review cut pressure, and still need card-level proof.
- protection_boundary: Ramp cards with missing-floor overlap or commander-plan signals are protected until source-lane review.
- mutation_boundary: This model does not choose cards, copy decks, run battle, mutate DBs, or promote packages.
