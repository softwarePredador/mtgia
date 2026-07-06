# Global Commander Engine Cut Follow-Up Router

- generated_at: `2026-07-06T04:16:20.499871+00:00`
- status: `engine_cut_followup_router_blocks_candidate_copy`
- cut_count: `2`
- usage_blocked_cut_count: `1`
- missing_trace_cut_count: `1`
- replacement_required_count: `1`
- trace_plan_count: `1`
- pair_count: `6`
- pair_ready_count: `0`
- no_explicit_same_lane_pair_count: `6`
- candidate_copy_allowed_now: `false`
- battle_run_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_trace_plan_and_replacement_search_before_candidate_copy`

## Cut Follow-Ups

| Cut | Route | Required Evidence | Next Gate |
| --- | --- | --- | --- |
| `Biotransference` | `replacement_required` | `different_cut_source_or_explicit_same_lane_replacement_proof` | `find_different_engine_cut_or_explicit_same_lane_replacement_before_candidate_copy` |
| `Archaeomancer's Map` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_engine_cut_before_pair_review` |

## Pair Follow-Ups

| Pair | Pair Gate | Cut Gate | Blockers |
| --- | --- | --- | --- |
| `+Feed the Swarm / -Archaeomancer's Map` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_engine_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Archaeomancer's Map` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_engine_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Archaeomancer's Map` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_engine_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Biotransference` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_engine_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Biotransference` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_engine_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Biotransference` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_engine_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |

## Trace Plan

- `Archaeomancer's Map`: `generate_or_import_current_scope_usage_trace_for_engine_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`

## Replacement Search

- `Biotransference`: same-lane roles required `engine`

## Blockers

- `usage_observed_blocks_engine_cuts:Biotransference`
- `missing_current_scope_usage_trace_for_engine_cuts:Archaeomancer's Map`
- `no_explicit_same_lane_replacement_route_for_engine_cut_pairs`
- `trace_required_for_engine_cuts:Archaeomancer's Map`
- `replacement_required_for_used_engine_cuts:Biotransference`

## Policy

- usage_boundary: A cut with current-scope target usage routes to a different cut or explicit same-lane replacement proof.
- trace_boundary: A cut without current-scope usage or negative trace routes to trace generation/import before pair review.
- same_lane_boundary: Cross-lane removal additions cannot replace engine or tutor cuts without explicit same-lane route evidence.
- mutation_boundary: This router does not copy decks, run battles, mutate DBs, force traces, or promote packages.
