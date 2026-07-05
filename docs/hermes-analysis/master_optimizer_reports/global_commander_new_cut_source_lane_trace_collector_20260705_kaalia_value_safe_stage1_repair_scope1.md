# Global Commander New Cut Source Lane Trace Collector

- generated_at: `2026-07-05T21:52:53.102057+00:00`
- status: `new_cut_source_lane_trace_blocks_used_remaining_cuts`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- remaining_cut_source_count: `12`
- usage_blocked_remaining_cut_count: `9`
- seen_without_usage_count: `2`
- not_seen_count: `1`
- seed_report_count: `8`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts`

## Review Rows

| Cut | Status | Usage | Exposure | Decisions | Next Evidence |
| --- | --- | ---: | ---: | ---: | --- |
| `Sunforger` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 8 | 24 | 19 | `find_different_cut_or_same_lane_replacement_proof` |
| `Alicia Masters, Skilled Sculptor` | `remaining_cut_seen_without_usage_needs_negative_review` | 0 | 0 | 1 | `explain_nonuse_or_force_access_before_reclassification` |
| `Jeska's Will` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 9 | 6 | 11 | `find_different_cut_or_same_lane_replacement_proof` |
| `Smothering Tithe` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 163 | 46 | 25 | `find_different_cut_or_same_lane_replacement_proof` |
| `Demonic Tutor` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 9 | 14 | 18 | `find_different_cut_or_same_lane_replacement_proof` |
| `Enlightened Tutor` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 2 | 10 | 14 | `find_different_cut_or_same_lane_replacement_proof` |
| `Vampiric Tutor` | `remaining_cut_seen_without_usage_needs_negative_review` | 0 | 0 | 1 | `explain_nonuse_or_force_access_before_reclassification` |
| `Arcane Signet` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 3 | 11 | 5 | `find_different_cut_or_same_lane_replacement_proof` |
| `Dark Ritual` | `remaining_cut_not_seen_needs_forced_access_or_more_trace` | 0 | 0 | 0 | `force_access_or_expand_replay_window_before_reclassification` |
| `Mana Vault` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 9 | 17 | 4 | `find_different_cut_or_same_lane_replacement_proof` |
| `Sol Ring` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 7 | 14 | 5 | `find_different_cut_or_same_lane_replacement_proof` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `remaining_cut_used_by_target_trace_blocks_value_safe` | 21 | 13 | 7 | `find_different_cut_or_same_lane_replacement_proof` |

## Blockers

- `remaining_cut_cards_used_by_target_deck:Sunforger,Jeska's Will,Smothering Tithe,Demonic Tutor,Enlightened Tutor,Arcane Signet,Mana Vault,Sol Ring,Birgi, God of Storytelling // Harnfel, Horn of Bounty`
- `remaining_cut_cards_seen_without_usage:Alicia Masters, Skilled Sculptor,Vampiric Tutor`
- `remaining_cut_cards_not_seen:Dark Ritual`
- `candidate_copy_closed_until_cut_source_lane_has_value_safe_or_proven_same_lane_cut`

## Policy

- reuse_boundary: This collector reuses existing replay artifacts and does not run a new battle.
- usage_boundary: A remaining cut used by the target deck is not value-safe from this trace.
- unseen_boundary: No exposure in existing traces is insufficient proof; force-access or broader replay is required.
