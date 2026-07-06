# Global Commander Ramp Axis Exhaustion Router

- generated_at: `2026-07-06T06:12:53.626313+00:00`
- status: `ramp_axis_exhausted_requires_global_role_axis_pivot`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- exhausted_role_axis: `ramp`
- blocked_ramp_cut_count: `9`
- replacement_exact_ready_count: `0`
- alternative_focus_card_count: `2`
- alternative_forced_usage_blocked_count: `2`
- current_ramp_lane_exhausted: `true`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `return_to_global_role_axis_learning_priority_after_ramp_axis_exhaustion`

## Blocked Current Ramp Cuts

- `Arcane Signet`
- `Basalt Monolith`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`
- `Burnt Offering`
- `Cabal Ritual`
- `Culling the Weak`
- `Dark Ritual`
- `Desperate Ritual`
- `Grim Monolith`

## Blocked Alternative Ramp Cuts

- `Ornithopter of Paradise`
- `Pyretic Ritual`

## Blockers

- `candidate_copy_closed_after_ramp_axis_exhaustion_router`
- `battle_gate_closed_after_ramp_axis_exhaustion_router`
- `ramp_axis_current_cut_lane_exhausted`

## Policy

- axis_boundary: An exhausted ramp axis is a learning route signal, not permission to cut cards.
- pivot_boundary: The next step must return to global role-axis learning before more same-deck ramp source search.
- mutation_boundary: No deck mutation, candidate copy, battle gate, or promotion is opened by this router.
