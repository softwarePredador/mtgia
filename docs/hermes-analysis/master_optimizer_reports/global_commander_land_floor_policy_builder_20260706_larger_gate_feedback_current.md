# Global Commander Land Floor Policy Builder

- generated_at: `2026-07-06T13:27:39.286563+00:00`
- status: `land_floor_policy_ready_no_deck_action`
- deck_policy_count: `9`
- ready_pair_preflight_deck_count: `7`
- battle_feedback_blocked_land_preflight_count: `2`
- blocked_deck_count: `2`
- top_deck_id: `609`
- top_commander: `Lorehold, the Historian`
- top_land_gap: `4`
- top_pair_add: `Sunbaked Canyon`
- top_pair_cut: `Tibalt's Trickery`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane`

## Deck Policy Queue

| Deck | Commander | Status | Land Gap | Current/Floor | Candidates | Pairs | Top Add | Top Cut | Next Gate |
| --- | --- | --- | ---: | --- | ---: | ---: | --- | --- | --- |
| `VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (609)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 4 | `30/34` | 510 | 9 | `Sunbaked Canyon` | `Tibalt's Trickery` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (610)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 4 | `30/34` | 508 | 9 | `Ash Barrens` | `Brilliant Restoration` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (608)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 3 | `31/34` | 516 | 9 | `Ash Barrens` | `Cool but Rude` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (613)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 2 | `32/34` | 510 | 9 | `Ash Barrens` | `Glint-Horn Buccaneer` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Y'shtola Variant 01 - Rafael Paste 2026-06-24 (621)` | `Y'shtola, Night's Blessed` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 2 | `32/34` | 674 | 9 | `Ash Barrens` | `Farewell` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (614)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 1 | `33/34` | 509 | 9 | `Ash Barrens` | `Monument to Endurance` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `Runtime Lorehold Learned 19e93de3cca (6)` | `Lorehold, the Historian` | `land_floor_policy_ready_for_pair_preflight_no_deck_action` | 1 | `33/34` | 499 | 9 | `Ash Barrens` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane` |
| `VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (612)` | `Lorehold, the Historian` | `blocked_by_protected_baseline_package_feedback` | 7 | `27/34` | 507 | 9 | `Ash Barrens` | `Longshot, Rebel Bowman` | `replace_failed_package_source_lane_or_cut_set_before_land_floor_preflight` |
| `VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (616)` | `Lorehold, the Historian` | `blocked_by_protected_baseline_package_feedback` | 5 | `29/34` | 519 | 9 | `Ash Barrens` | `Rise of the Eldrazi` | `replace_failed_package_source_lane_or_cut_set_before_land_floor_preflight` |

## Blockers

- `land_floor_policy_is_not_materialization_permission`
- `candidate_copy_requires_isolated_db_materializer_and_commander_source_lane`
- `structure_and_legality_recheck_required_after_any_copy`
- `strategy_matrix_battle_gate_and_replay_trace_remain_closed`
- `deck_607_is_benchmark_evidence_only_not_global_template`
- `battle_feedback_blocked_land_preflight_requires_new_source_lane_or_cut_set`

## Policy

- land_floor_boundary: This report calibrates land floor priority and pair preflight only; it does not copy, mutate, battle, or promote decks.
- source_boundary: Named land candidates and cuts are inherited from prior review-only reports and remain hypotheses.
- floor_boundary: Land additions must repair actual land quantity or color access gaps and must cut nonland spell slots.
- battle_boundary: Battle gates stay closed until an isolated candidate copy is structurally rechecked and the added land/cut decision has trace evidence.
- feedback_boundary: A land-floor add/cut pair that belongs to a package blocked by protected-baseline battle feedback must change source lane, cut set, or strategy before re-entering preflight.
