# Global Commander Profile Blocker Repair Plan

- generated_at: `2026-07-05T19:35:01.628012+00:00`
- status: `profile_blocker_repair_plan_ready`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- source_strategy_status: `package_strategy_blocks_battle`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `4`
- repair_action_count: `4`
- next_gate: `materialize_profile_repair_candidate_copy`

## Repair Actions

| Blocker | Axis | Count | Target | Shortfall | Source Lanes |
| --- | --- | ---: | --- | ---: | --- |
| `profile_lands_below_target` | `lands` | 34 | `35-37` | 1 | `global_commander_mana_base_profile, global_commander_named_land_candidate_pool, same_lane_land_cut_review` |
| `profile_angels_demons_dragons_payoffs_below_target` | `angels_demons_dragons_payoffs` | 4 | `22-30` | 18 | `commander_reference_profile_expected_packages, oracle_type_identity_legal_filter, source_lane_payoff_density_review` |
| `profile_spot_interaction_below_target` | `spot_interaction` | 6 | `8-12` | 2 | `commander_reference_profile_interaction_package, oracle_targeted_interaction_filter, same_lane_nonprotected_cut_review` |
| `attack_window_cut_without_replacement` | `commander_attack_window` | - | `-` | - | `commander_attack_enabler_package, protection_silence_source_lane_review, same_lane_attack_window_cut_review` |

## Repair Sequence

1. `repair_or_restore_commander_attack_window_before_more_interaction`
2. `repair_mana_base_to_commander_land_floor`
3. `repair_commander_payoff_density_with_legal_source_lanes`
4. `finish_spot_interaction_floor_with_same_lane_cut`
5. `rerun_global_commander_candidate_package_strategy_matrix`

## Over-Target Review Roles

- `mana_acceleration` candidate `23` max `14` overage `9`
- `card_draw_selection` candidate `13` max `11` overage `2`
- `tutors_access` candidate `18` max `8` overage `10`

## Policy

- repair_boundary: This plan names repair lanes only; it never mutates decks or opens promotion.
- battle_boundary: Any blocker keeps equal battle probes closed until the strategy matrix is rerun clean.
- cut_boundary: Above-target roles are candidate review pressure, not automatic cut authorization.
