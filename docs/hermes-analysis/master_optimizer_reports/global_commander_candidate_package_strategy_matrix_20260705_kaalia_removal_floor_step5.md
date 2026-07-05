# Global Commander Candidate Package Strategy Matrix

- generated_at: `2026-07-05T19:30:16.661955+00:00`
- status: `package_strategy_blocks_battle`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- profile_version: `kaalia_of_the_vast_reference_profile_v1_2026-07-05`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `4`
- next_gate: `repair_commander_profile_blockers_before_battle`

## Target Evaluation

| Role | Base | Candidate | Delta | Target | Candidate Status |
| --- | ---: | ---: | ---: | --- | --- |
| `lands` | 34 | 34 | 0 | `35-37` | `below_target` |
| `mana_acceleration` | 24 | 23 | -1 | `10-14` | `above_target_review` |
| `haste_protection_silence` | 10 | 10 | 0 | `8-12` | `in_range` |
| `angels_demons_dragons_payoffs` | 4 | 4 | 0 | `22-30` | `below_target` |
| `spot_interaction` | 1 | 6 | 5 | `8-12` | `below_target` |
| `board_wipes_resets` | 2 | 3 | 1 | `2-4` | `in_range` |
| `card_draw_selection` | 13 | 13 | 0 | `7-11` | `above_target_review` |
| `tutors_access` | 20 | 18 | -2 | `4-8` | `above_target_review` |
| `reanimation_plan_b` | 3 | 3 | 0 | `3-6` | `in_range` |
| `dedicated_win_conditions` | 6 | 6 | 0 | `3-6` | `in_range` |

## Package Delta

| Action | Card | Profile Roles | Risk Flags |
| --- | --- | --- | --- |
| `add` | `Path to Exile` | `spot_interaction` | `-` |
| `add` | `Feed the Swarm` | `spot_interaction` | `-` |
| `add` | `Swords to Plowshares` | `spot_interaction` | `-` |
| `add` | `Rakdos Charm` | `board_wipes_resets, spot_interaction` | `-` |
| `add` | `Terminate` | `spot_interaction` | `-` |
| `cut` | `Archaeomancer's Map` | `mana_acceleration, tutors_access` | `mana_acceleration_cut, tutor_access_cut` |
| `cut` | `Genji Glove` | `-` | `attack_window_or_extra_combat_cut` |
| `cut` | `Karlach, Fury of Avernus` | `-` | `attack_window_or_extra_combat_cut` |
| `cut` | `Ardenn, Intrepid Archaeologist` | `-` | `attack_window_or_extra_combat_cut` |
| `cut` | `Grim Tutor` | `tutors_access` | `tutor_access_cut` |

## Blockers

- `profile_lands_below_target`
- `profile_angels_demons_dragons_payoffs_below_target`
- `profile_spot_interaction_below_target`
- `attack_window_cut_without_replacement`

## Policy

- profile_gate: Commander-specific role targets and package risks are checked after generic core floors.
- battle_boundary: Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.
- cut_boundary: Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.
