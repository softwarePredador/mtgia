# Global Commander Candidate Package Strategy Matrix

- generated_at: `2026-07-06T12:20:59.046057+00:00`
- status: `package_strategy_blocks_battle`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- profile_version: `lorehold_reference_profile_v1_2026-05-11`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `4`
- battle_feedback_blocker_count: `0`
- next_gate: `repair_commander_profile_blockers_before_battle`

## Target Evaluation

| Role | Base | Candidate | Delta | Target | Candidate Status |
| --- | ---: | ---: | ---: | --- | --- |
| `lands` | 27 | 34 | 7 | `36-38` | `below_target` |
| `mana_rocks_treasure_ramp` | 24 | 21 | -3 | `10-13` | `above_target_review` |
| `topdeck_miracle_setup` | 7 | 7 | 0 | `6-9` | `in_range` |
| `draw_rummage_opponent_turn_draw` | 13 | 14 | 1 | `8-12` | `above_target_review` |
| `miracle_haymakers` | 13 | 12 | -1 | `10-16` | `in_range` |
| `spot_interaction` | 5 | 6 | 1 | `4-6` | `in_range` |
| `board_wipes_resets` | 12 | 8 | -4 | `3-5` | `above_target_review` |
| `spell_payoffs_copy_engines` | 16 | 13 | -3 | `5-8` | `above_target_review` |
| `graveyard_recursion` | 8 | 8 | 0 | `2-5` | `above_target_review` |
| `dedicated_win_conditions` | 18 | 14 | -4 | `4-7` | `above_target_review` |

## Package Delta

| Action | Card | Profile Roles | Risk Flags |
| --- | --- | --- | --- |
| `add` | `Ash Barrens` | `lands, tutors_access` | `-` |
| `add` | `Sunbaked Canyon` | `card_draw_selection, draw_rummage_opponent_turn_draw, lands` | `-` |
| `add` | `Battlefield Forge` | `lands` | `-` |
| `add` | `Cabaretti Courtyard` | `lands, tutors_access` | `-` |
| `add` | `Demolition Field` | `lands, spot_interaction, tutors_access` | `-` |
| `add` | `Escape Tunnel` | `lands, tutors_access` | `-` |
| `add` | `Evolving Wilds` | `lands, tutors_access` | `-` |
| `cut` | `Longshot, Rebel Bowman` | `board_wipes_resets, dedicated_win_conditions, mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `mana_acceleration_cut` |
| `cut` | `Agate Instigator` | `board_wipes_resets, dedicated_win_conditions, spell_payoffs_copy_engines` | `-` |
| `cut` | `Warleader's Call` | `board_wipes_resets, dedicated_win_conditions` | `-` |
| `cut` | `Pyromancer's Goggles` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `protected_profile_anchor_cut, mana_acceleration_cut` |
| `cut` | `Call Forth the Tempest` | `board_wipes_resets, miracle_haymakers` | `protected_profile_anchor_cut` |
| `cut` | `Ancient Gold Dragon` | `angels_demons_dragons_payoffs, dedicated_win_conditions` | `angel_demon_dragon_payoff_cut` |
| `cut` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration, mana_rocks_treasure_ramp` | `protected_profile_anchor_cut, mana_acceleration_cut` |

## Blockers

- `profile_lands_below_target`
- `protected_profile_anchor_cut:Pyromancer's Goggles`
- `protected_profile_anchor_cut:Call Forth the Tempest`
- `protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty`

## Battle Feedback Evidence

- none

## Policy

- profile_gate: Commander-specific role targets and package risks are checked after generic core floors.
- battle_boundary: Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.
- cut_boundary: Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.
- protected_anchor_boundary: Commander expected-package anchors require same-lane proof before a package can cut them.
- battle_feedback_boundary: A package rejected by protected-baseline larger gate feedback cannot reopen battle without a changed source lane, cut set, or strategy hypothesis.
