# Global Commander Cross-Commander Role Axis Learning Pivot

- generated_at: `2026-07-06T05:22:21.745441+00:00`
- status: `cross_commander_role_axis_learning_pivot_ready_after_engine_axis_exhaustion_no_deck_action`
- axis_count: `10`
- top_axis_role: `ramp`
- top_axis_status: `cross_commander_role_axis_blocks_same_deck_source_cycle`
- top_axis_priority_score: `321`
- source_cycle_axis_count: `4`
- engine_axis_exhausted_axis_count: `1`
- engine_axis_suppressed_axis_count: `1`
- benchmark_only_excluded_from_action_count: `5`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion`

## Axis Queue

| Role | Status | Score | Decks | Commanders | Below | Above | Cycle Decks | Engine Exhausted Decks | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| `ramp` | `cross_commander_role_axis_blocks_same_deck_source_cycle` | 321 | 10 | 3 | 0 | 10 | `619` | `-` | `build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion` |
| `land` | `cross_commander_role_axis_ready_no_deck_action` | 294 | 9 | 2 | 9 | 0 | `-` | `-` | `calibrate_role_floor_before_candidate_copy` |
| `removal` | `cross_commander_role_axis_blocks_same_deck_source_cycle` | 289 | 3 | 2 | 1 | 2 | `619` | `-` | `build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion` |
| `tutor` | `cross_commander_role_axis_blocks_same_deck_source_cycle` | 254 | 4 | 2 | 0 | 4 | `619` | `-` | `build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion` |
| `board_wipe` | `cross_commander_role_axis_ready_no_deck_action` | 165 | 13 | 5 | 0 | 13 | `-` | `-` | `calibrate_role_ceiling_before_strategy_matrix` |
| `draw` | `cross_commander_role_axis_ready_no_deck_action` | 114 | 10 | 2 | 0 | 10 | `-` | `-` | `calibrate_role_ceiling_before_strategy_matrix` |
| `wincon` | `cross_commander_role_axis_ready_no_deck_action` | 109 | 5 | 2 | 1 | 4 | `-` | `-` | `calibrate_role_floor_and_ceiling_before_candidate_copy` |
| `protection` | `cross_commander_role_axis_ready_no_deck_action` | 77 | 7 | 1 | 0 | 7 | `-` | `-` | `calibrate_role_ceiling_before_strategy_matrix` |
| `recursion` | `cross_commander_role_axis_ready_no_deck_action` | 54 | 4 | 2 | 0 | 4 | `-` | `-` | `calibrate_role_ceiling_before_strategy_matrix` |
| `engine` | `cross_commander_role_axis_suppressed_engine_axis_exhausted` | -98 | 16 | 6 | 0 | 16 | `619` | `619` | `choose_next_non_exhausted_role_axis_after_engine_axis_exhaustion` |

## Top Axis Evidence

| Deck | Commander | Direction | Count | Target | Source Cycle | Engine Axis Exhausted |
| --- | --- | --- | ---: | --- | ---: | ---: |
| `VARIANT Kaalia Variant 01 - Rafael Paste 2026-06-24 (619)` | `Kaalia of the Vast` | `above_range` | 23 | `8-16` | true | true |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `above_range` | 51 | `8-16` | false | false |
| `VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (608)` | `Lorehold, the Historian` | `above_range` | 21 | `8-16` | false | false |
| `VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (610)` | `Lorehold, the Historian` | `above_range` | 22 | `8-16` | false | false |
| `VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (612)` | `Lorehold, the Historian` | `above_range` | 24 | `8-16` | false | false |
| `VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (613)` | `Lorehold, the Historian` | `above_range` | 20 | `8-16` | false | false |
| `VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (614)` | `Lorehold, the Historian` | `above_range` | 22 | `8-16` | false | false |
| `VARIANT Sauron Variant 01 - Rafael Paste 2026-06-24 (620)` | `Sauron, the Dark Lord` | `above_range` | 19 | `8-16` | false | false |
| `VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (606)` | `Lorehold, the Historian` | `above_range` | 20 | `8-16` | false | false |
| `VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (611)` | `Lorehold, the Historian` | `above_range` | 22 | `8-16` | false | false |

## Blockers

- `cross_commander_role_axis_learning_is_not_cut_permission`
- `source_cycle_decks_need_role_axis_policy_before_more_same_deck_source_expansion`
- `engine_axis_exhaustion_suppresses_engine_reentry_until_new_card_level_evidence`
- `deck_607_is_benchmark_evidence_only_not_action_source`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`

## Policy

- pivot_boundary: This report chooses a learning axis only; it does not add, cut, copy, battle, or promote decks.
- cycle_boundary: High recycled cut-source counts with all seeded roles exhausted require role-axis learning before more same-deck source search.
- engine_axis_boundary: An exhausted engine axis remains evidence, but it is suppressed as the next action until new card-level evidence exists.
- benchmark_boundary: Deck 607 evidence is retained as benchmark context but excluded from actionable axis counts.
- global_boundary: Axis evidence groups multiple commanders and variants so one deck cannot become the global objective function.
