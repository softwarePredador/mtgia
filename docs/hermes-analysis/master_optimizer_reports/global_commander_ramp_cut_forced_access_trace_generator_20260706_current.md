# Global Commander Ramp Cut Forced Access Trace Generator

- generated_at: `2026-07-06T05:55:11.639467+00:00`
- status: `ramp_cut_forced_access_trace_blocks_used_unexposed_cuts`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- focus_card_count: `2`
- focus_cards: `Culling the Weak, Desperate Ritual`
- seed_count: `3`
- generated_replay_count: `3`
- forced_access_mode: `opening_hand`
- usage_blocked_count: `2`
- manual_review_count: `0`
- force_failure_count: `0`
- candidate_copy_allowed_now: `false`
- battle_replay_performed: `true`
- battle_gate_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access`

## Review Rows

| Card | Status | Forced Present | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Culling the Weak` | `ramp_cut_forced_access_usage_observed_blocks_cut` | 3 | 9 | 3 | 3 | `find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access` |
| `Desperate Ritual` | `ramp_cut_forced_access_usage_observed_blocks_cut` | 3 | 6 | 30 | 29 | `find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access` |

## Seed Reports

- seed `100`: `ramp_cut_forced_replay_generated`, events `984`, decisions `120`
- seed `101`: `ramp_cut_forced_replay_generated`, events `675`, decisions `105`
- seed `102`: `ramp_cut_forced_replay_generated`, events `972`, decisions `139`

## Blockers

- `forced_access_usage_observed_blocks_ramp_cut:Culling the Weak,Desperate Ritual`
- `candidate_copy_closed_after_ramp_forced_access_trace`

## Policy

- forced_access_boundary: Forced access is diagnostic evidence only; it is not a natural battle gate.
- target_boundary: Forced access applies only to the current evaluation target player.
- ramp_cut_boundary: A ramp cut used under forced access is blocked until a different cut or exact same-lane replacement is proven.
- promotion_boundary: No candidate copy, deck mutation, battle gate, or promotion is opened by this report.
