# Global Commander Forced Cut Access Trace Generator

- generated_at: `2026-07-05T22:00:37.416084+00:00`
- status: `forced_cut_access_trace_blocks_used_unresolved_cuts`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- focus_card_count: `3`
- focus_cards: `Alicia Masters, Skilled Sculptor, Vampiric Tutor, Dark Ritual`
- seed_count: `3`
- forced_access_mode: `opening_hand`
- usage_blocked_count: `3`
- manual_review_count: `0`
- force_failure_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts`

## Review Rows

| Card | Status | Forced Present | Usage | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Alicia Masters, Skilled Sculptor` | `forced_access_usage_observed_blocks_value_safe` | 3 | 3 | 52 | 48 | `find_different_cut_or_same_lane_replacement_proof` |
| `Vampiric Tutor` | `forced_access_usage_observed_blocks_value_safe` | 3 | 8 | 38 | 38 | `find_different_cut_or_same_lane_replacement_proof` |
| `Dark Ritual` | `forced_access_usage_observed_blocks_value_safe` | 3 | 4 | 39 | 39 | `find_different_cut_or_same_lane_replacement_proof` |

## Blockers

- `forced_access_usage_observed:Alicia Masters, Skilled Sculptor,Vampiric Tutor,Dark Ritual`
- `candidate_copy_closed_after_forced_access_trace`

## Policy

- forced_access_boundary: Forced access is diagnostic evidence only; it is not a natural battle gate.
- target_boundary: Forced access applies only to the current evaluation target player.
- promotion_boundary: No candidate copy, deck mutation, battle gate, or promotion is opened by this report.
