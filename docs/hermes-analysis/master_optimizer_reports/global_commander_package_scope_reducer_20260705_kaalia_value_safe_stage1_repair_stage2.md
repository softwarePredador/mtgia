# Global Commander Package Scope Reducer

- generated_at: `2026-07-05T20:59:52.471331+00:00`
- status: `commander_package_scope_reduced_ready_for_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- original_add_count: `7`
- value_safe_cut_count: `1`
- scoped_pair_count: `1`
- dropped_add_count: `6`
- reduced_scope_candidate_copy_allowed_now: `true`
- full_package_candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `materialize_reduced_scope_candidate_copy`

## Requirements

| Axis | Initial | Remaining |
| --- | ---: | ---: |
| `angels_demons_dragons_payoffs` | 6 | 6 |
| `commander_attack_window` | 0 | 0 |
| `lands` | 0 | 0 |
| `reanimation_plan_b` | 1 | 0 |
| `spot_interaction` | 0 | 0 |

## Scoped Pairs

| Step | Add | Cut | Covers |
| ---: | --- | --- | --- |
| 1 | `Necromancy` | `Cabal Ritual` | `reanimation_plan_b` |

## Blockers

- `insufficient_reviewable_cuts_for_full_profile_package:required_7_ready_6`
- `value_safe_cut_shortfall:required_7_ready_1`
- `reduced_scope_dropped_adds:6`

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
