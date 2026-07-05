# Global Commander Profile Repair Candidate Model

- generated_at: `2026-07-05T21:07:32.675019+00:00`
- status: `profile_repair_candidate_model_blocks_materialization`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- colors: `WBR`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `1`
- next_gate: `expand_commander_payoff_source_lane_before_candidate_copy`

## Axis Pools

### `angels_demons_dragons_payoffs`

- blocker: `profile_angels_demons_dragons_payoffs_below_target`
- status: `needs_broader_commander_payoff_source_lane_before_materialization`
- candidate_count: `0`
- shortfall_to_min: `6`

| Score | Add Candidate | Status | Roles | Reasons |
| ---: | --- | --- | --- | --- |
| 80 | `Angel of Serenity` | `blocked_not_commander_payoff_role` | `-` | commander_reference_profile_expected_package, profile_expected_package |
| 80 | `Aurelia, the Warleader` | `blocked_not_commander_payoff_role` | `-` | commander_reference_profile_expected_package, profile_expected_package |

| Score | Cut Candidate | Roles | Reasons |
| ---: | --- | --- | --- |
| 50 | `Diabolic Intent` | `tutors_access` | over_target_tutors_access, tutor_role_above_target_review |
| 43 | `Jeska's Will` | `mana_acceleration` | over_target_mana_acceleration |
| 43 | `Professional Face-Breaker` | `card_draw_selection, mana_acceleration` | over_target_mana_acceleration |
| 42 | `Ornithopter of Paradise` | `mana_acceleration` | over_target_mana_acceleration |
| 41 | `Dark Ritual` | `mana_acceleration` | over_target_mana_acceleration |

## Candidate-Copy Blockers

- `angels_demons_dragons_payoffs:needs_broader_commander_payoff_source_lane_before_materialization`

## Policy

- repair_boundary: Candidates are review-only source-lane rows, not deck changes.
- materialization_boundary: Candidate copy opens only when every blocker axis has enough legal candidates and reviewable cuts.
- payoff_boundary: Large commander payoff shortfalls require a broader commander source lane, not a narrow interaction-style swap.
