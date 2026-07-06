# Global Commander Profile Repair Land Cut Reviewer

- generated_at: `2026-07-06T12:28:43.758682+00:00`
- status: `profile_repair_land_cut_review_ready_for_candidate_copy`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- pair_count: `5`
- land_pair_review_count: `2`
- ready_land_pair_count: `2`
- hard_floor_blocker_count: `0`
- candidate_copy_allowed_now: `true`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `0`
- next_gate: `materialize_profile_repair_candidate_copy`

## Land Pair Reviews

| Add | Cut | Status | Projected Cut Roles | Warnings | Blockers |
| --- | --- | --- | --- | --- | --- |
| `Bant Panorama` | `Storm-Kiln Artist` | `land_floor_cut_role_loss_review_ready_for_candidate_copy` | `mana_rocks_treasure_ramp=19, spell_payoffs_copy_engines=12` | `land_cut_removes_high_function_nonland_roles:mana_acceleration,mana_rocks_treasure_ramp,spell_payoffs_copy_engines` | `-` |
| `Brokers Hideout` | `Jeska's Will` | `land_floor_cut_role_loss_review_ready_for_candidate_copy` | `draw_rummage_opponent_turn_draw=11, mana_rocks_treasure_ramp=19` | `land_cut_removes_high_function_nonland_roles:draw_rummage_opponent_turn_draw,mana_acceleration,mana_rocks_treasure_ramp, low_curve_ramp_cut_requires_strategy_matrix_and_replay_after_copy` | `-` |

## Target Results

| Role | Candidate | Projected | Min | Max | Status | Blockers |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `board_wipes_resets` | `8` | `8` | `3` | `5` | `above_target_review` | `-` |
| `dedicated_win_conditions` | `14` | `12` | `4` | `7` | `above_target_review` | `-` |
| `draw_rummage_opponent_turn_draw` | `14` | `11` | `8` | `12` | `in_range` | `-` |
| `graveyard_recursion` | `8` | `8` | `2` | `5` | `above_target_review` | `-` |
| `lands` | `34` | `36` | `36` | `38` | `in_range` | `-` |
| `mana_rocks_treasure_ramp` | `21` | `19` | `10` | `13` | `above_target_review` | `-` |
| `miracle_haymakers` | `12` | `11` | `10` | `16` | `in_range` | `-` |
| `spell_payoffs_copy_engines` | `13` | `12` | `5` | `8` | `above_target_review` | `-` |
| `spot_interaction` | `6` | `6` | `4` | `6` | `in_range` | `-` |
| `topdeck_miracle_setup` | `7` | `7` | `6` | `9` | `in_range` | `-` |

## Candidate-Copy Blockers

- none

## Policy

- land_cut_review_boundary: This gate evaluates role loss only; it does not copy or mutate a deck.
- profile_package_boundary: Projected counts use the whole reordered repair package, not isolated land pairs.
- battle_boundary: Candidate copy can open for structure and strategy rerun only; battle and promotion remain closed.
