# Global Commander Candidate Package Strategy Matrix

- generated_at: `2026-07-06T12:12:17.527237+00:00`
- status: `package_strategy_blocks_battle`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- profile_version: `lorehold_reference_profile_v1_2026-05-11`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `3`
- battle_feedback_blocker_count: `3`
- next_gate: `replace_failed_package_source_lane_or_cut_set_before_battle`

## Target Evaluation

| Role | Base | Candidate | Delta | Target | Candidate Status |
| --- | ---: | ---: | ---: | --- | --- |
| `lands` | 34 | 36 | 2 | `36-38` | `in_range` |
| `mana_rocks_treasure_ramp` | 21 | 19 | -2 | `10-13` | `above_target_review` |
| `topdeck_miracle_setup` | 7 | 7 | 0 | `6-9` | `in_range` |
| `draw_rummage_opponent_turn_draw` | 14 | 11 | -3 | `8-12` | `in_range` |
| `miracle_haymakers` | 12 | 11 | -1 | `10-16` | `in_range` |
| `spot_interaction` | 6 | 6 | 0 | `4-6` | `in_range` |
| `board_wipes_resets` | 8 | 8 | 0 | `3-5` | `above_target_review` |
| `spell_payoffs_copy_engines` | 13 | 12 | -1 | `5-8` | `above_target_review` |
| `graveyard_recursion` | 8 | 8 | 0 | `2-5` | `above_target_review` |
| `dedicated_win_conditions` | 14 | 12 | -2 | `4-7` | `above_target_review` |

## Package Delta

| Action | Card | Profile Roles | Risk Flags |
| --- | --- | --- | --- |
| `add` | `Bant Panorama` | `lands, tutors_access` | `-` |
| `add` | `Brokers Hideout` | `lands, tutors_access` | `-` |
| `add` | `Pyromancer's Goggles` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `-` |
| `add` | `Call Forth the Tempest` | `board_wipes_resets, miracle_haymakers` | `-` |
| `add` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration, mana_rocks_treasure_ramp` | `-` |
| `cut` | `Storm-Kiln Artist` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `mana_acceleration_cut` |
| `cut` | `Jeska's Will` | `draw_rummage_opponent_turn_draw, mana_acceleration, mana_rocks_treasure_ramp` | `mana_acceleration_cut` |
| `cut` | `Artist's Talent` | `card_draw_selection, dedicated_win_conditions, draw_rummage_opponent_turn_draw, mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `mana_acceleration_cut, card_flow_cut` |
| `cut` | `Starfall Invocation` | `board_wipes_resets, card_draw_selection, draw_rummage_opponent_turn_draw, miracle_haymakers` | `card_flow_cut` |
| `cut` | `Brass's Bounty` | `dedicated_win_conditions, mana_acceleration, mana_rocks_treasure_ramp, miracle_haymakers` | `mana_acceleration_cut` |

## Blockers

- `battle_feedback_failed_exact_package`
- `battle_feedback_failed_protected_baseline_package`
- `battle_feedback_larger_gate_unexercised_added_cards`

## Battle Feedback Evidence

- `package_blocked_by_protected_baseline_gate` from `docs/hermes-analysis/master_optimizer_reports/global_commander_larger_battle_gate_audit_20260706_lorehold_profile_repair_vs607.json`; protected_delta `-3`; recommendation `block_package_until_new_source_lane_cut_or_strategy`

## Policy

- profile_gate: Commander-specific role targets and package risks are checked after generic core floors.
- battle_boundary: Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.
- cut_boundary: Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.
- protected_anchor_boundary: Commander expected-package anchors require same-lane proof before a package can cut them.
- battle_feedback_boundary: A package rejected by protected-baseline larger gate feedback cannot reopen battle without a changed source lane, cut set, or strategy hypothesis.
