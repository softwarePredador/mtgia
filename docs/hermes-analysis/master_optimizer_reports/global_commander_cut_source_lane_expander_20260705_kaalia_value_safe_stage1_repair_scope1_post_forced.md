# Global Commander Cut Source Lane Expander

- generated_at: `2026-07-05T22:09:55.061455+00:00`
- status: `commander_cut_source_lane_still_blocks_full_package`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- required_cut_count: `6`
- value_safe_cut_count: `0`
- stage_only_cut_count: `15`
- blocked_cut_count: `73`
- forced_cut_access_status: `forced_cut_access_trace_blocks_used_unresolved_cuts`
- forced_usage_blocked_count: `3`
- package_size_limit: `8`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `2`
- next_gate: `backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block`

## Cut Budgets

| Role | Initial Budget | Remaining |
| --- | ---: | ---: |
| `mana_acceleration` | 1 | 1 |
| `haste_protection_silence` | 4 | 4 |
| `tutors_access` | 8 | 8 |

## Blockers

- `value_safe_cut_shortfall:required_6_ready_0`
- `forced_cut_access_blocks_unresolved_cut_reclassification:3`

## Selected Value-Safe Cuts

| Cut | Primary Role | Score | Matching Roles | Reasons |
| --- | --- | ---: | --- | --- |

## Stage-Only Cuts

- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: `global_battle_feedback_requires_new_same_lane_or_gate`
- `Jeska's Will`: `structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Professional Face-Breaker`: `contextual_staple_requires_stage_review`
- `Smothering Tithe`: `structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Sunforger`: `attack_window_cut_requires_same_lane_stage_proof`
- `Demonic Tutor`: `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Diabolic Intent`: `contextual_staple_requires_stage_review`
- `Enlightened Tutor`: `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Vampiric Tutor`: `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Alicia Masters, Skilled Sculptor`: `attack_window_cut_requires_same_lane_stage_proof`
- `Arcane Signet`: `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Dark Ritual`: `structural_foundation_staple_requires_same_lane_or_battle_proof`

## Blocked Cut Sample

- `Ancient Copper Dragon`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Ancient Tomb`: `protected_profile_role_lands, no_above_target_role_budget`
- `Angel of the Ruins`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Anguished Unmaking`: `protected_profile_role_spot_interaction, no_above_target_role_budget`
- `Ardenn, Intrepid Archaeologist`: `no_above_target_role_budget`
- `Arena of Glory`: `protected_profile_role_haste_protection_silence,lands`
- `Arid Mesa`: `protected_profile_role_lands`
- `Aurelia, the Law Above`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Avacyn, Angel of Hope`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Balefire Dragon`: `protected_profile_role_angels_demons_dragons_payoffs, no_above_target_role_budget`
- `Biotransference`: `no_above_target_role_budget`
- `Blightsteel Colossus // Blightsteel Colossus`: `protected_profile_role_haste_protection_silence`

## Policy

- cut_boundary: Expanded cuts are source-lane evidence, not deck changes.
- staple_boundary: Structural staples require same-lane replacement or battle proof before cutting.
- protected_role_boundary: Lands, commander payoffs, spot interaction, and attack-window protection stay protected while below target or strategically required.
- forced_access_boundary: Forced access can block reclassification; it cannot create value-safe cut proof.
- battle_boundary: No battle or promotion opens from cut source-lane expansion alone.
