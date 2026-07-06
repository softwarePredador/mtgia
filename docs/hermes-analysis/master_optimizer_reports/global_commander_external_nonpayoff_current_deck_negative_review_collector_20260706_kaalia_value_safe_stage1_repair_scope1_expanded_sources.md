# Global Commander External Nonpayoff Current Deck Negative Review Collector

- generated_at: `2026-07-06T02:34:59.769022+00:00`
- status: `external_current_deck_negative_review_blocks_used_candidates`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- current_deck_candidate_count: `1`
- usage_blocked_candidate_count: `1`
- seen_without_usage_count: `0`
- not_seen_count: `0`
- seed_report_count: `8`
- card_level_cut_permission_count: `0`
- negative_review_cleared_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `find_new_external_source_or_explicit_same_lane_replacement_proof`

## Review Rows

| Card | Role | Status | Usage | Exposure | Decisions | Next Evidence |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `Mana Vault` | `mana_acceleration` | `external_current_deck_candidate_used_by_target_blocks_negative_review` | 9 | 17 | 4 | `find_new_external_source_or_explicit_same_lane_replacement_proof` |

## Blockers

- `external_current_deck_candidates_used_by_target:Mana Vault`
- `candidate_copy_closed_until_negative_review_or_fresh_cut_source_exists`

## Policy

- negative_review_boundary: A current-deck external candidate must not be treated as cuttable when target-deck use is observed.
- trace_boundary: This collector reuses existing current-scope replay artifacts and does not run a battle gate.
- promotion_boundary: No candidate copy, deck mutation, battle gate, value-safe reclassification, or promotion is opened by this report.
