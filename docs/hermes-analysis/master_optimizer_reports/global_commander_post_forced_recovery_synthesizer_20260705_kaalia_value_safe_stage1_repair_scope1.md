# Global Commander Post-Forced Recovery Synthesizer

- generated_at: `2026-07-05T22:19:53.328694+00:00`
- status: `post_forced_recovery_blocks_candidate_copy_needs_new_cut_source`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- selected_add_count: `6`
- required_cut_count: `6`
- value_safe_cut_count: `0`
- stage_only_cut_count: `15`
- forced_usage_blocked_count: `3`
- scoped_pair_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `mine_new_value_safe_cut_source_before_package_resynthesis`

## Recovery Actions

| Priority | Action | Status | Reason |
| --- | --- | --- | --- |
| `P0` | `mine_new_value_safe_cut_source_before_package_resynthesis` | `required_now` | No value-safe cuts remain after forced-access review. |
| `P1` | `build_same_lane_or_equal_gate_proof_for_stage_only_cuts` | `diagnostic_only` | Used, structural, contextual, or attack-window cuts cannot become value-safe without explicit proof. |
| `P2` | `resynthesize_smaller_package_only_after_fresh_cut_proof` | `blocked_until_new_cut_source` | A smaller package still needs at least one value-safe cut pair. |
| `P3` | `keep_current_package_closed` | `closed_no_deck_action` | Current evidence does not authorize copy, natural battle, promotion, or deck mutation. |

## Target Cut Roles

- `haste_protection_silence`: `4`
- `mana_acceleration`: `1`
- `tutors_access`: `8`

## Selected Adds

- `Dragon Mage`: axis `angels_demons_dragons_payoffs`, score `98`
- `Bonehoard Dracosaur`: axis `angels_demons_dragons_payoffs`, score `97`
- `Drakuseth, Maw of Flames`: axis `angels_demons_dragons_payoffs`, score `96`
- `The Balrog of Moria`: axis `angels_demons_dragons_payoffs`, score `96`
- `Wrathful Red Dragon`: axis `angels_demons_dragons_payoffs`, score `96`
- `Akroma, Angel of Wrath`: axis `angels_demons_dragons_payoffs`, score `95`

## Stage-Only Cut Reason Counts

- `structural_foundation_staple_requires_same_lane_or_battle_proof`: `9`
- `commander_expected_package_anchor_requires_stage_proof`: `5`
- `contextual_staple_requires_stage_review`: `3`
- `attack_window_cut_requires_same_lane_stage_proof`: `2`
- `global_battle_feedback_requires_new_same_lane_or_gate`: `1`

## Blockers

- `no_value_safe_cut_source_after_forced_access`
- `no_reduced_scope_pair_after_forced_access`
- `forced_access_usage_blocks_reclassification`
- `current_package_closed_no_deck_action`

## Policy

- recovery_boundary: This report chooses the next evidence lane; it is not a deck action.
- cut_boundary: A smaller package cannot advance without at least one value-safe cut pair.
- forced_access_boundary: Forced access can block a cut; it cannot prove a cut is safe.
- battle_boundary: Battle and promotion remain closed until copy/materializer and strategy gates pass.
