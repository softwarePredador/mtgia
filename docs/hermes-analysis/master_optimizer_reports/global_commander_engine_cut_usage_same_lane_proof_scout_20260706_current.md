# Global Commander Engine Cut Usage Same-Lane Proof Scout

- generated_at: `2026-07-06T04:07:10.263548+00:00`
- status: `engine_cut_usage_same_lane_proof_blocks_candidate_copy`
- cut_card_count: `2`
- pair_count: `6`
- usage_blocked_cut_count: `1`
- missing_trace_cut_count: `1`
- explicit_same_lane_route_count: `0`
- pair_ready_count: `0`
- candidate_copy_allowed_now: `false`
- battle_run_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `generate_current_scope_trace_or_find_explicit_same_lane_engine_replacement_before_candidate_copy`

## Cut Evidence

| Cut | Status | Trace Group | Structured Evidence | Same-Lane Routes | Next Evidence |
| --- | --- | --- | ---: | ---: | --- |
| `Archaeomancer's Map` | `engine_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 0 | 0 | `generate_or_import_current_scope_usage_trace_for_engine_cut` |
| `Biotransference` | `engine_cut_usage_observed_blocks_candidate_copy` | `usage_blocked` | 2 | 0 | `find_different_cut_or_explicit_same_lane_replacement` |

## Pair Review

| Pair | Status | Same-Lane Roles | Blockers |
| --- | --- | --- | --- |
| `+Feed the Swarm / -Archaeomancer's Map` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Biotransference` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Archaeomancer's Map` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Biotransference` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Archaeomancer's Map` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Biotransference` | `engine_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |

## Blockers

- `usage_observed_blocks_engine_cuts:Biotransference`
- `missing_current_scope_usage_trace_for_engine_cuts:Archaeomancer's Map`
- `no_explicit_same_lane_replacement_route_for_engine_cut_pairs`

## Text Occurrence Sample

- `Biotransference`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `9`
- `Biotransference`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `22`
- `Biotransference`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `33`
- `Archaeomancer's Map`: `historical_or_cross_scope_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md` line `1`
- `Archaeomancer's Map`: `historical_or_cross_scope_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md` line `6`
- `Archaeomancer's Map`: `historical_or_cross_scope_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_replay_summary_20260623_001244.md` line `13`
- `Archaeomancer's Map`: `current_scope_non_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deck619_battle_rule_coherence_pg200_trouble_in_pairs_postsync_v1.json` line `1787`
- `Archaeomancer's Map`: `current_scope_non_trace_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deck619_battle_rule_coherence_pg200_trouble_in_pairs_postsync_v1.json` line `1810`
- `Archaeomancer's Map`: `planning_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_contextual_trace_generation_review_current.json` line `551`
- `Archaeomancer's Map`: `planning_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_contextual_trace_generation_review_current.json` line `634`
- `Archaeomancer's Map`: `planning_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_contextual_trace_generation_review_current.md` line `107`
- `Archaeomancer's Map`: `planning_reference_not_proof` in `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_contextual_usage_trace_current.json` line `515`

## Policy

- usage_boundary: Observed use by the target deck blocks treating an engine cut as safe.
- same_lane_boundary: A removal add does not replace an engine or tutor cut unless an explicit same-lane route is proven.
- trace_boundary: Textual trace references are scout evidence only; structured trace/proof rows drive this decision.
- mutation_boundary: This scout does not copy decks, run battles, mutate DBs, or promote packages.
