# Global Commander Ramp Alternative Cut Trace Generator

- generated_at: `2026-07-06T06:06:26.093205+00:00`
- status: `ramp_alternative_cut_trace_needs_force_access_or_more_trace`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- focus_card_count: `2`
- focus_cards: `Ornithopter of Paradise, Pyretic Ritual`
- seed_count: `3`
- generated_replay_count: `3`
- usage_blocked_count: `0`
- manual_review_count: `0`
- no_exposure_count: `2`
- candidate_copy_allowed_now: `false`
- battle_replay_performed: `true`
- battle_gate_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `force_access_or_expand_trace_for_alternative_ramp_cut`

## Review Rows

| Card | Status | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | --- |
| `Ornithopter of Paradise` | `alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace` | 0 | 0 | 0 | `force_access_or_expand_trace_for_alternative_ramp_cut` |
| `Pyretic Ritual` | `alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace` | 0 | 0 | 0 | `force_access_or_expand_trace_for_alternative_ramp_cut` |

## Seed Reports

- seed `110`: `alternative_ramp_cut_replay_generated`, events `1599`, decisions `169`
- seed `111`: `alternative_ramp_cut_replay_generated`, events `896`, decisions `123`
- seed `112`: `alternative_ramp_cut_replay_generated`, events `1093`, decisions `142`

## Blockers

- `alternative_ramp_cut_no_exposure_requires_force_or_more_trace:Ornithopter of Paradise,Pyretic Ritual`
- `candidate_copy_closed_after_alternative_ramp_cut_trace`

## Policy

- natural_trace_boundary: Natural trace is evidence collection only, not a battle gate.
- alternative_cut_boundary: Alternative ramp cuts need card-level use or negative review before any cut claim.
- promotion_boundary: No candidate copy, deck mutation, battle gate, or promotion is opened by this report.
