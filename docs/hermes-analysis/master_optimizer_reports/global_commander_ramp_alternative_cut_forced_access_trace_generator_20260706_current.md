# Global Commander Ramp Alternative Cut Forced Access Trace Generator

- generated_at: `2026-07-06T06:09:57.587908+00:00`
- status: `ramp_alternative_cut_forced_access_blocks_used_targets`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- focus_card_count: `2`
- focus_cards: `Ornithopter of Paradise, Pyretic Ritual`
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
- next_gate: `expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access`

## Review Rows

| Card | Status | Forced Present | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Ornithopter of Paradise` | `alternative_ramp_cut_forced_access_usage_observed_blocks_cut` | 3 | 9 | 28 | 21 | `expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access` |
| `Pyretic Ritual` | `alternative_ramp_cut_forced_access_usage_observed_blocks_cut` | 3 | 9 | 21 | 22 | `expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access` |

## Seed Reports

- seed `120`: `alternative_ramp_cut_forced_replay_generated`, events `1033`, decisions `165`
- seed `121`: `alternative_ramp_cut_forced_replay_generated`, events `844`, decisions `130`
- seed `122`: `alternative_ramp_cut_forced_replay_generated`, events `820`, decisions `115`

## Blockers

- `alternative_ramp_cut_forced_usage_observed_blocks_cut:Ornithopter of Paradise,Pyretic Ritual`
- `candidate_copy_closed_after_alternative_ramp_cut_forced_access`

## Policy

- forced_access_boundary: Forced access is diagnostic evidence only; it is not a natural battle gate.
- alternative_cut_boundary: Alternative ramp cuts used under forced access are blocked as cuts.
- promotion_boundary: No candidate copy, deck mutation, battle gate, or promotion is opened by this report.
