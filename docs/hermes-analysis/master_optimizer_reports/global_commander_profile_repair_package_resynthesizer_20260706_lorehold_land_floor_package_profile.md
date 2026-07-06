# Global Commander Profile Repair Package Resynthesizer

- generated_at: `2026-07-06T06:58:02.788016+00:00`
- status: `profile_repair_package_resynthesis_ready_for_cut_pair_review`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- selected_add_count: `5`
- selected_cut_count: `5`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `1`
- next_gate: `review_resynthesized_profile_repair_cut_pairs_before_candidate_copy`

## Selected Adds

| Axis | Card | Status | Roles |
| --- | --- | --- | --- |
| `lands` | `Bant Panorama` | `review_only_resynthesized_profile_repair_add` | `lands` |
| `lands` | `Brokers Hideout` | `review_only_resynthesized_profile_repair_add` | `lands` |
| `protected_profile_anchor` | `Pyromancer's Goggles` | `review_only_resynthesized_profile_repair_add` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` |
| `protected_profile_anchor` | `Call Forth the Tempest` | `review_only_resynthesized_profile_repair_add` | `board_wipes_resets, miracle_haymakers` |
| `protected_profile_anchor` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `review_only_resynthesized_profile_repair_add` | `mana_acceleration, mana_rocks_treasure_ramp` |

## Selected Cuts

| Card | Status | Roles | Reasons |
| --- | --- | --- | --- |
| `Artist's Talent` | `review_only_resynthesized_profile_repair_cut` | `card_draw_selection, dedicated_win_conditions, draw_rummage_opponent_turn_draw, mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `over_target_dedicated_win_conditions, over_target_draw_rummage_opponent_turn_draw, over_target_mana_rocks_treasure_ramp, over_target_spell_payoffs_copy_engines` |
| `Brass's Bounty` | `review_only_resynthesized_profile_repair_cut` | `dedicated_win_conditions, mana_acceleration, mana_rocks_treasure_ramp, miracle_haymakers` | `over_target_dedicated_win_conditions, over_target_mana_rocks_treasure_ramp` |
| `Starfall Invocation` | `review_only_resynthesized_profile_repair_cut` | `board_wipes_resets, card_draw_selection, draw_rummage_opponent_turn_draw, miracle_haymakers` | `over_target_board_wipes_resets, over_target_draw_rummage_opponent_turn_draw` |
| `Storm-Kiln Artist` | `review_only_resynthesized_profile_repair_cut` | `mana_acceleration, mana_rocks_treasure_ramp, spell_payoffs_copy_engines` | `over_target_mana_rocks_treasure_ramp, over_target_spell_payoffs_copy_engines` |
| `Jeska's Will` | `review_only_resynthesized_profile_repair_cut` | `draw_rummage_opponent_turn_draw, mana_acceleration, mana_rocks_treasure_ramp` | `over_target_draw_rummage_opponent_turn_draw, over_target_mana_rocks_treasure_ramp` |

## Candidate-Copy Blockers

- `cut_pair_review_required_before_candidate_copy`

## Policy

- resynthesis_boundary: This gate only resynthesizes review rows; it does not create a deck copy.
- protected_anchor_boundary: Protected anchors may be restored as adds, but every replacement cut still needs pair review.
- battle_boundary: No battle, promotion, or deck action opens from package resynthesis alone.
