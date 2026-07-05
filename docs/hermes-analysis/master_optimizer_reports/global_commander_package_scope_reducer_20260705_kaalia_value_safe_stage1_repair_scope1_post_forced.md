# Global Commander Package Scope Reducer

- generated_at: `2026-07-05T22:10:45.741121+00:00`
- status: `commander_package_scope_reduction_blocks_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- original_add_count: `6`
- value_safe_cut_count: `0`
- scoped_pair_count: `0`
- dropped_add_count: `6`
- reduced_scope_candidate_copy_allowed_now: `false`
- full_package_candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- forced_usage_blocked_count: `3`
- next_gate: `synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block`

## Requirements

| Axis | Initial | Remaining |
| --- | ---: | ---: |
| `angels_demons_dragons_payoffs` | 6 | 6 |
| `commander_attack_window` | 0 | 0 |
| `lands` | 0 | 0 |
| `reanimation_plan_b` | 0 | 0 |
| `spot_interaction` | 0 | 0 |

## Scoped Pairs

| Step | Add | Cut | Covers |
| ---: | --- | --- | --- |

## Blockers

- `insufficient_reviewable_cuts_for_full_profile_package:required_6_ready_5`
- `value_safe_cut_shortfall:required_6_ready_0`
- `forced_cut_access_blocks_unresolved_cut_reclassification:3`
- `reduced_scope_dropped_adds:6`
- `no_value_safe_reduced_scope_pair_ready`

## Dropped Adds

- `Dragon Mage`
- `Bonehoard Dracosaur`
- `Drakuseth, Maw of Flames`
- `The Balrog of Moria`
- `Wrathful Red Dragon`
- `Akroma, Angel of Wrath`

## Policy

- scope_boundary: Only the reduced paired scope may move to copied-DB materialization.
- full_package_boundary: The original package remains blocked until every add has a value-safe cut.
- selection_policy: Prefer closing a whole blocker axis when scarce cuts cannot support the full package.
- battle_boundary: Battle and promotion remain closed until candidate copy, strategy matrix, and replay gates pass.
