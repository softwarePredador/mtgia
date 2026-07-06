# Global Commander External Nonpayoff Manual Negative Trace Reviewer

- generated_at: `2026-07-06T03:25:16.412110+00:00`
- status: `external_nonpayoff_manual_negative_trace_review_blocks_current_deck_cuts`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- manual_review_candidate_count: `3`
- manual_negative_review_cleared_count: `0`
- used_blocked_count: `1`
- static_silence_blocked_count: `1`
- land_lane_blocked_count: `1`
- candidate_copy_allowed_count: `0`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `find_new_external_source_or_explicit_same_lane_replacement_proof`

## Manual Review Rows

| Card | Role | Manual Status | Usage | Exposure | Decisions | Reason |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `Grand Abolisher` | `haste_protection_silence` | `manual_negative_trace_review_blocks_static_silence_without_activation` | 0 | 1 | 2 | Static silence effects do not require an activation/cast event after they are on board. |
| `Silence` | `haste_protection_silence` | `manual_negative_trace_review_blocks_used_current_deck_card` | 12 | 1 | 18 | Target-deck usage was observed, so negative review cannot clear this card. |
| `Arena of Glory` | `mana_acceleration` | `manual_negative_trace_review_blocks_land_lane_seen_without_usage` | 0 | 19 | 1 | A land or land-lane card can carry mana/color/haste value without an explicit usage event. |

## Blockers

- `manual_negative_review_cleared_no_current_deck_cards`
- `static_or_land_seen_without_usage_is_not_cut_permission`
- `candidate_copy_closed_until_fresh_cut_source_or_explicit_same_lane_replacement_exists`

## Policy

- manual_review_boundary: Manual negative trace review can block weak cut evidence but does not create add/cut permission.
- static_effect_boundary: Passive or static effects require stronger negative evidence than lack of activation logs.
- land_lane_boundary: Land play and mana-base context must route through mana-base review, not generic nonuse.
- mutation_boundary: This reviewer does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.
