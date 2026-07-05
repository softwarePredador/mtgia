# Global Commander Contextual Usage Trace Reviewer

- generated_at: `2026-07-05T21:36:50.696909+00:00`
- status: `contextual_usage_trace_review_blocks_value_safe_reclassification`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- reviewed_card_count: `3`
- usage_blocked_card_count: `3`
- not_seen_card_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy`

## Review Rows

| Card | Status | Usage | Exposure | Decisions | Decision |
| --- | --- | ---: | ---: | ---: | --- |
| `Diabolic Intent` | `usage_observed_blocks_value_safe_reclassification` | 5 | 0 | 1 | `not_value_safe_from_current_trace` |
| `Ornithopter of Paradise` | `usage_observed_blocks_value_safe_reclassification` | 12 | 26 | 15 | `not_value_safe_from_current_trace` |
| `Professional Face-Breaker` | `usage_observed_blocks_value_safe_reclassification` | 6 | 12 | 14 | `not_value_safe_from_current_trace` |

## Blockers

- `contextual_cards_used_by_target_deck:Diabolic Intent,Ornithopter of Paradise,Professional Face-Breaker`

## Policy

- usage_boundary: Observed use by the target deck is evidence against automatic value-safe cutting.
- replacement_boundary: A used contextual staple needs same-lane replacement proof before any reclassification.
- battle_boundary: This reviewer does not open battle or promotion gates.
