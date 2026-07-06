# Global Commander Profile Repair Cut Pair Reorderer

- generated_at: `2026-07-06T07:11:22.595102+00:00`
- status: `profile_repair_cut_pair_reorder_ready_for_land_curve_review`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- pair_count: `5`
- ready_pair_count: `3`
- protected_anchor_ready_pair_count: `3`
- land_pair_review_count: `2`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `2`
- next_gate: `review_land_floor_cut_role_loss_before_candidate_copy`

## Reordered Pairs

| # | Add | Cut | Status | Shared Roles | Blockers |
| ---: | --- | --- | --- | --- | --- |
| 1 | `Bant Panorama` | `Storm-Kiln Artist` | `reordered_land_floor_pair_needs_curve_review` | `-` | `land_floor_pair_needs_curve_and_role_loss_review` |
| 2 | `Brokers Hideout` | `Jeska's Will` | `reordered_land_floor_pair_needs_curve_review` | `-` | `land_floor_pair_needs_curve_and_role_loss_review` |
| 3 | `Pyromancer's Goggles` | `Artist's Talent` | `reordered_protected_anchor_same_lane_pair` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `-` |
| 4 | `Call Forth the Tempest` | `Starfall Invocation` | `reordered_protected_anchor_same_lane_pair` | `board_wipes_resets, miracle_haymakers` | `-` |
| 5 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Brass's Bounty` | `reordered_protected_anchor_same_lane_pair` | `mana_acceleration, mana_rocks_treasure_ramp` | `-` |

## Candidate-Copy Blockers

- `land_floor_pair_needs_curve_and_role_loss_review`

## Policy

- reorder_boundary: This gate reorders review rows only; it does not copy or mutate a deck.
- protected_anchor_boundary: Protected anchors must consume same-lane cuts before land repairs consume any remaining cut pool.
- land_floor_boundary: Land-floor pairs stay closed until curve and role-loss review accepts the nonland cuts.
- battle_boundary: No battle or promotion opens from pair reordering.
