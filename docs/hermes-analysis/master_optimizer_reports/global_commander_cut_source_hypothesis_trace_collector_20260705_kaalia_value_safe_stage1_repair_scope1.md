# Global Commander Cut-Source Hypothesis Trace Collector

- generated_at: `2026-07-05T22:29:57.486745+00:00`
- status: `cut_source_hypothesis_trace_blocks_used_hypotheses`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `8`
- usage_blocked_hypothesis_count: `6`
- seen_without_usage_count: `2`
- not_seen_count: `0`
- seed_report_count: `8`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `mine_more_hypotheses_or_build_same_lane_proof`

## Review Rows

| Cut | Status | Usage | Exposure | Decisions | Next Evidence |
| --- | --- | ---: | ---: | ---: | --- |
| `Biotransference` | `hypothesis_used_by_target_trace_blocks_value_safe` | 1 | 11 | 15 | `find_different_cut_or_same_lane_replacement_proof` |
| `Maskwood Nexus` | `hypothesis_used_by_target_trace_blocks_value_safe` | 4 | 0 | 3 | `find_different_cut_or_same_lane_replacement_proof` |
| `Sigarda's Aid` | `hypothesis_used_by_target_trace_blocks_value_safe` | 16 | 27 | 13 | `find_different_cut_or_same_lane_replacement_proof` |
| `Necromancy` | `hypothesis_used_by_target_trace_blocks_value_safe` | 8 | 21 | 30 | `find_different_cut_or_same_lane_replacement_proof` |
| `Necropotence` | `hypothesis_used_by_target_trace_blocks_value_safe` | 4 | 0 | 3 | `find_different_cut_or_same_lane_replacement_proof` |
| `Trouble in Pairs` | `hypothesis_seen_without_usage_needs_negative_review` | 0 | 0 | 3 | `explain_nonuse_or_force_access_before_reclassification` |
| `Puresteel Paladin` | `hypothesis_seen_without_usage_needs_negative_review` | 0 | 0 | 1 | `explain_nonuse_or_force_access_before_reclassification` |
| `Sram, Senior Edificer` | `hypothesis_used_by_target_trace_blocks_value_safe` | 6 | 22 | 14 | `find_different_cut_or_same_lane_replacement_proof` |

## Blockers

- `hypothesis_cards_used_by_target_deck:Biotransference,Maskwood Nexus,Sigarda's Aid,Necromancy,Necropotence,Sram, Senior Edificer`
- `hypothesis_cards_seen_without_usage:Trouble in Pairs,Puresteel Paladin`
- `candidate_copy_closed_until_hypothesis_has_negative_or_same_lane_proof`

## Policy

- reuse_boundary: This collector reuses existing replay artifacts and does not run a new battle.
- usage_boundary: A hypothesis used by the target deck is not value-safe from this trace.
- unseen_boundary: No exposure in existing traces is insufficient proof; force-access or broader replay is required.
