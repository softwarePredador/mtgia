# Global Commander Ramp Cut Follow-Up Router

- generated_at: `2026-07-06T05:40:38.175585+00:00`
- status: `ramp_cut_followup_router_blocks_candidate_copy`
- cut_count: `9`
- usage_blocked_cut_count: `3`
- missing_trace_cut_count: `5`
- structured_trace_review_required_count: `1`
- replacement_required_count: `3`
- trace_plan_count: `5`
- structured_review_count: `1`
- pair_count: `9`
- pair_ready_count: `0`
- no_explicit_same_lane_pair_count: `9`
- candidate_copy_allowed_now: `false`
- battle_run_performed: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_trace_plan_structured_review_and_replacement_search_before_candidate_copy`

## Cut Follow-Ups

| Cut | Route | Required Evidence | Next Gate |
| --- | --- | --- | --- |
| `Arcane Signet` | `replacement_required` | `different_cut_source_or_explicit_same_lane_replacement_proof` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `replacement_required` | `different_cut_source_or_explicit_same_lane_replacement_proof` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` |
| `Dark Ritual` | `replacement_required` | `different_cut_source_or_explicit_same_lane_replacement_proof` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` |
| `Grim Monolith` | `structured_trace_review_required` | `structured_trace_or_replay_reference` | `review_text_trace_candidate_for_ramp_cut_before_pair_review` |
| `Basalt Monolith` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` |
| `Burnt Offering` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` |
| `Cabal Ritual` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` |
| `Culling the Weak` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` |
| `Desperate Ritual` | `trace_required` | `current_scope_usage_or_negative_trace` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` |

## Pair Follow-Ups

| Pair | Pair Gate | Cut Gate | Blockers |
| --- | --- | --- | --- |
| `+Feed the Swarm / -Arcane Signet` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Arcane Signet` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Arcane Signet` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Basalt Monolith` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Basalt Monolith` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Basalt Monolith` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review` | cut_card_missing_current_scope_usage_trace, no_explicit_same_lane_replacement_route |
| `+Feed the Swarm / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Path to Exile / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |
| `+Swords to Plowshares / -Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy` | `find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy` | cut_card_used_by_target_trace, no_explicit_same_lane_replacement_route |

## Trace Plan

- `Basalt Monolith`: `generate_or_import_current_scope_usage_trace_for_ramp_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`
- `Burnt Offering`: `generate_or_import_current_scope_usage_trace_for_ramp_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`
- `Cabal Ritual`: `generate_or_import_current_scope_usage_trace_for_ramp_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`
- `Culling the Weak`: `generate_or_import_current_scope_usage_trace_for_ramp_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`
- `Desperate Ritual`: `generate_or_import_current_scope_usage_trace_for_ramp_cut`; fallback `force_access_trace_only_after_current_scope_trace_gap_is_confirmed`

## Structured Review

- `Grim Monolith`: `review_text_trace_candidate_for_ramp_cut`; fallback `generate_current_scope_trace_if_text_reference_is_not_structured_proof`

## Replacement Search

- `Arcane Signet`: same-lane roles required `ramp`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: same-lane roles required `engine,ramp`
- `Dark Ritual`: same-lane roles required `ramp`

## Blockers

- `usage_observed_blocks_ramp_cuts:Arcane Signet,Birgi, God of Storytelling // Harnfel, Horn of Bounty,Dark Ritual`
- `missing_current_scope_usage_trace_for_ramp_cuts:Basalt Monolith,Burnt Offering,Cabal Ritual,Culling the Weak,Desperate Ritual`
- `no_explicit_same_lane_replacement_route_for_ramp_cut_pairs`
- `trace_required_for_ramp_cuts:Basalt Monolith,Burnt Offering,Cabal Ritual,Culling the Weak,Desperate Ritual`
- `structured_trace_review_required_for_ramp_cuts:Grim Monolith`
- `replacement_required_for_used_ramp_cuts:Arcane Signet,Birgi, God of Storytelling // Harnfel, Horn of Bounty,Dark Ritual`

## Policy

- usage_boundary: A cut with current-scope target usage routes to a different cut or explicit same-lane replacement proof.
- trace_boundary: A cut without current-scope usage or negative trace routes to trace generation/import before pair review.
- structured_trace_boundary: A text trace candidate is scout evidence only until reviewed as structured proof.
- same_lane_boundary: Cross-lane removal additions cannot replace ramp cuts without explicit same-lane route evidence.
- mutation_boundary: This router does not copy decks, run battles, mutate DBs, force traces, or promote packages.
