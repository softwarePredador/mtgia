# Global Commander Profile Blocker Repair Plan

- generated_at: `2026-07-06T06:50:41.208804+00:00`
- status: `profile_blocker_repair_plan_ready`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- source_strategy_status: `package_strategy_blocks_battle`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `4`
- repair_action_count: `4`
- next_gate: `materialize_profile_repair_candidate_copy`

## Repair Actions

| Blocker | Axis | Count | Target | Shortfall | Source Lanes |
| --- | --- | ---: | --- | ---: | --- |
| `profile_lands_below_target` | `lands` | 34 | `36-38` | 2 | `global_commander_mana_base_profile, global_commander_named_land_candidate_pool, same_lane_land_cut_review` |
| `protected_profile_anchor_cut:Pyromancer's Goggles` | `protected_profile_anchor` | - | `-` | - | `restore_protected_anchor_to_candidate_package, same_lane_replacement_proof_for_protected_anchor, commander_expected_package_anchor_review` |
| `protected_profile_anchor_cut:Call Forth the Tempest` | `protected_profile_anchor` | - | `-` | - | `restore_protected_anchor_to_candidate_package, same_lane_replacement_proof_for_protected_anchor, commander_expected_package_anchor_review` |
| `protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `protected_profile_anchor` | - | `-` | - | `restore_protected_anchor_to_candidate_package, same_lane_replacement_proof_for_protected_anchor, commander_expected_package_anchor_review` |

## Repair Sequence

1. `repair_mana_base_to_commander_land_floor`
2. `restore_or_same_lane_replace_protected_anchor:Pyromancer's Goggles`
3. `restore_or_same_lane_replace_protected_anchor:Call Forth the Tempest`
4. `restore_or_same_lane_replace_protected_anchor:Birgi, God of Storytelling // Harnfel, Horn of Bounty`
5. `rerun_global_commander_candidate_package_strategy_matrix`

## Over-Target Review Roles

- `mana_rocks_treasure_ramp` candidate `21` max `13` overage `8`
- `draw_rummage_opponent_turn_draw` candidate `14` max `12` overage `2`
- `board_wipes_resets` candidate `8` max `5` overage `3`
- `spell_payoffs_copy_engines` candidate `13` max `8` overage `5`
- `graveyard_recursion` candidate `8` max `5` overage `3`
- `dedicated_win_conditions` candidate `14` max `7` overage `7`

## Policy

- repair_boundary: This plan names repair lanes only; it never mutates decks or opens promotion.
- battle_boundary: Any blocker keeps equal battle probes closed until the strategy matrix is rerun clean.
- cut_boundary: Above-target roles are candidate review pressure, not automatic cut authorization.
