# Global Commander Role Axis Policy Builder

- generated_at: `2026-07-06T03:50:42.064979+00:00`
- status: `role_axis_policy_ready_blocks_same_deck_source_cycle`
- policy_axis_count: `10`
- top_policy_role: `engine`
- top_policy_status: `role_axis_policy_blocks_same_deck_source_cycle`
- top_pressure_class: `ceiling_saturation_axis`
- source_cycle_deck_count: `1`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion`

## Axis Policy Queue

| Role | Status | Class | Decks | Commanders | Below | Above | Cycle Decks | Next Gate |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| `engine` | `role_axis_policy_blocks_same_deck_source_cycle` | `ceiling_saturation_axis` | 16 | 6 | 0 | 16 | `619` | `apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion` |
| `ramp` | `role_axis_policy_blocks_same_deck_source_cycle` | `ceiling_saturation_axis` | 10 | 3 | 0 | 10 | `619` | `apply_ramp_axis_policy_before_more_same_deck_source_expansion` |
| `land` | `role_axis_policy_ready_for_floor_calibration` | `floor_repair_axis` | 9 | 2 | 9 | 0 | `-` | `calibrate_land_floor_policy_before_candidate_copy` |
| `removal` | `role_axis_policy_blocks_same_deck_source_cycle` | `mixed_floor_and_ceiling_axis` | 3 | 2 | 1 | 2 | `619` | `apply_removal_axis_policy_before_more_same_deck_source_expansion` |
| `tutor` | `role_axis_policy_blocks_same_deck_source_cycle` | `ceiling_saturation_axis` | 4 | 2 | 0 | 4 | `619` | `apply_tutor_axis_policy_before_more_same_deck_source_expansion` |
| `board_wipe` | `role_axis_policy_ready_for_ceiling_calibration` | `ceiling_saturation_axis` | 13 | 5 | 0 | 13 | `-` | `calibrate_board_wipe_ceiling_policy_before_strategy_matrix` |
| `draw` | `role_axis_policy_ready_for_ceiling_calibration` | `ceiling_saturation_axis` | 10 | 2 | 0 | 10 | `-` | `calibrate_draw_ceiling_policy_before_strategy_matrix` |
| `wincon` | `role_axis_policy_ready_for_mixed_calibration` | `mixed_floor_and_ceiling_axis` | 5 | 2 | 1 | 4 | `-` | `calibrate_wincon_mixed_axis_policy_before_candidate_copy` |
| `protection` | `role_axis_policy_ready_for_ceiling_calibration` | `ceiling_saturation_axis` | 7 | 1 | 0 | 7 | `-` | `calibrate_protection_ceiling_policy_before_strategy_matrix` |
| `recursion` | `role_axis_policy_ready_for_ceiling_calibration` | `ceiling_saturation_axis` | 4 | 2 | 0 | 4 | `-` | `calibrate_recursion_ceiling_policy_before_strategy_matrix` |

## Top Policy Actions

- `treat_engine_as_capacity_ceiling_not_missing_role`
- `split_engine_cards_by_primary_function_before_cut_selection`
- `protect_engine_cards_that_also_cover_missing_floor_roles_or_commander_plan`
- `prefer_engine_only_or_overlapping_excess_role_cards_as_cut_pressure`
- `block_more_same_deck_source_expansion_until_axis_policy_is_applied`

## Source-Cycle Deck Role Pressure

### Deck `619`

| Role | Direction | Count | Target | Commander |
| --- | --- | ---: | --- | --- |
| `removal` | `below_floor` | 1 | `6-14` | `Kaalia of the Vast` |
| `engine` | `above_range` | 35 | `4-24` | `Kaalia of the Vast` |
| `ramp` | `above_range` | 23 | `8-16` | `Kaalia of the Vast` |
| `tutor` | `above_range` | 16 | `0-8` | `Kaalia of the Vast` |

## Blockers

- `role_axis_policy_is_not_card_level_cut_permission`
- `engine_saturation_policy_must_be_applied_before_more_same_deck_source_expansion`
- `source_cycle_decks_need_axis_policy_applied_to_cut_model`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`

## Policy

- engine_boundary: Engine is a capacity/ceiling role when globally above range; it is not a missing-role add lane by itself.
- cut_boundary: Cut pressure may target engine-only or excess-overlap cards only after protecting cards that cover missing floors or commander plan.
- cycle_boundary: A source-cycle deck cannot repeat same-deck source expansion until the axis policy is applied to its cut model.
- mutation_boundary: This builder does not choose cards, copy decks, run battles, mutate DBs, or promote packages.
