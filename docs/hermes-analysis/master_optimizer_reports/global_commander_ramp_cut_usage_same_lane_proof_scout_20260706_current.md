# Global Commander Ramp Cut Usage Same-Lane Proof Scout

- generated_at: `2026-07-06T05:34:40.026529+00:00`
- status: `ramp_cut_usage_same_lane_proof_blocks_candidate_copy`
- cut_card_count: `9`
- pair_count: `9`
- usage_blocked_cut_count: `3`
- missing_trace_cut_count: `5`
- explicit_same_lane_route_count: `0`
- pair_ready_count: `0`
- candidate_copy_allowed_now: `false`
- battle_run_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `generate_current_scope_trace_or_find_explicit_same_lane_ramp_replacement_before_candidate_copy`

## Cut Evidence

| Cut | Status | Trace Group | Structured Evidence | Same-Lane Routes | Next Evidence |
| --- | --- | --- | ---: | ---: | --- |
| `Arcane Signet` | `ramp_cut_usage_observed_blocks_candidate_copy` | `usage_blocked` | 4 | 0 | `find_different_cut_or_explicit_same_lane_replacement` |
| `Basalt Monolith` | `ramp_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 2 | 0 | `generate_or_import_current_scope_usage_trace_for_ramp_cut` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_cut_usage_observed_blocks_candidate_copy` | `usage_blocked` | 2 | 0 | `find_different_cut_or_explicit_same_lane_replacement` |
| `Burnt Offering` | `ramp_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 2 | 0 | `generate_or_import_current_scope_usage_trace_for_ramp_cut` |
| `Cabal Ritual` | `ramp_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 2 | 0 | `generate_or_import_current_scope_usage_trace_for_ramp_cut` |
| `Culling the Weak` | `ramp_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 3 | 0 | `generate_or_import_current_scope_usage_trace_for_ramp_cut` |
| `Dark Ritual` | `ramp_cut_usage_observed_blocks_candidate_copy` | `usage_blocked` | 3 | 0 | `find_different_cut_or_explicit_same_lane_replacement` |
| `Desperate Ritual` | `ramp_cut_missing_current_scope_usage_trace` | `not_seen_or_no_trace` | 2 | 0 | `generate_or_import_current_scope_usage_trace_for_ramp_cut` |
| `Grim Monolith` | `ramp_cut_text_trace_candidate_needs_structured_review` | `not_seen_or_no_trace` | 2 | 0 | `review_text_trace_candidate_before_candidate_copy` |

## Pair Review

| Pair | Status | Same-Lane Roles | Blockers |
| --- | --- | --- | --- |
| `+Feed the Swarm / -Arcane Signet` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Basalt Monolith` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Arcane Signet` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Basalt Monolith` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Arcane Signet` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Basalt Monolith` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `ramp_cut_pair_blocks_candidate_copy` | `-` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |

## Blockers

- `usage_observed_blocks_ramp_cuts:Arcane Signet,Birgi, God of Storytelling // Harnfel, Horn of Bounty,Dark Ritual`
- `missing_current_scope_usage_trace_for_ramp_cuts:Basalt Monolith,Burnt Offering,Cabal Ritual,Culling the Weak,Desperate Ritual`
- `no_explicit_same_lane_replacement_route_for_ramp_cut_pairs`

## Text Occurrence Sample

- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1/replay_seed_43.events.jsonl` line `89`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1/replay_seed_45.events.jsonl` line `41`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1/replay_seed_45.events.jsonl` line `43`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1/replay_seed_46.events.jsonl` line `940`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1/replay_seed_46.events.jsonl` line `942`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `9`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `29`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `37`
- `Arcane Signet`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `362`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json` line `9`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `33`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: `current_scope_text_usage_reference_candidate` in `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md` line `37`

## Policy

- usage_boundary: Observed use by the target deck blocks treating a ramp cut as safe.
- same_lane_boundary: A removal add does not replace a ramp cut unless an explicit same-lane route is proven.
- trace_boundary: Textual trace references are scout evidence only; structured trace/proof rows drive this decision.
- mutation_boundary: This scout does not copy decks, run battles, mutate DBs, or promote packages.
