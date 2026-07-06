# Global Commander Profile Repair Cut Pair Reviewer

- generated_at: `2026-07-06T07:01:54.356051+00:00`
- status: `profile_repair_cut_pair_review_blocks_candidate_copy`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- pair_count: `5`
- ready_pair_count: `1`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `4`
- next_gate: `reorder_or_expand_profile_repair_cut_pairs_before_candidate_copy`

## Reviewed Pairs

| # | Add | Cut | Status | Shared Roles | Blockers |
| ---: | --- | --- | --- | --- | --- |
| 1 | `Bant Panorama` | `Artist's Talent` | `pair_needs_manual_land_curve_review` | `-` | `land_floor_pair_needs_curve_and_role_loss_review` |
| 2 | `Brokers Hideout` | `Brass's Bounty` | `pair_needs_manual_land_curve_review` | `-` | `land_floor_pair_needs_curve_and_role_loss_review` |
| 3 | `Pyromancer's Goggles` | `Starfall Invocation` | `pair_blocked_cross_lane_protected_anchor_cut` | `-` | `protected_anchor_pair_lacks_same_lane_overlap` |
| 4 | `Call Forth the Tempest` | `Storm-Kiln Artist` | `pair_blocked_cross_lane_protected_anchor_cut` | `-` | `protected_anchor_pair_lacks_same_lane_overlap` |
| 5 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Jeska's Will` | `review_only_protected_anchor_same_lane_pair` | `mana_acceleration, mana_rocks_treasure_ramp` | `-` |

## Candidate-Copy Blockers

- `land_floor_pair_needs_curve_and_role_loss_review`
- `protected_anchor_pair_lacks_same_lane_overlap`

## Policy

- pair_review_boundary: Pair review never mutates decks; it only decides whether a later candidate copy may open.
- land_floor_boundary: Land repairs need explicit curve and role-loss review before consuming high-function nonlands.
- protected_anchor_boundary: Protected-anchor restores require same-lane cut overlap or a separate proof lane.
- battle_boundary: No battle or promotion opens from pair review.
