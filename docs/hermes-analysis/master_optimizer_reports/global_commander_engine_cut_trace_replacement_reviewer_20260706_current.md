# Global Commander Engine Cut Trace Replacement Reviewer

- generated_at: `2026-07-06T04:28:57.251030+00:00`
- status: `engine_cut_trace_replacement_review_blocks_candidate_copy`
- trace_review_count: `1`
- trace_blocked_count: `1`
- exact_artifact_engine_candidate_count: `0`
- downgraded_strong_candidate_count: `2`
- adjacent_candidate_count: `10`
- explicit_same_lane_replacement_proof_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy`

## Trace Review

| Card | Status | Chosen | Candidate Score | Gap | Next Gate |
| --- | --- | --- | ---: | ---: | --- |
| `Archaeomancer's Map` | `trace_review_blocks_negative_clearance_equal_score_tutor_candidate` | `The One Ring` | 85 | 0.0 | `find_different_engine_cut_or_exact_same_lane_replacement` |

## Replacement Review

- status: `replacement_review_downgrades_to_adjacent_engine_candidates`
- exact_artifact_engine_candidate_count: `0`
- downgraded_strong_candidate_count: `2`
- adjacent_candidate_count: `10`
- next_gate: `find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy`

## Downgraded Strong Candidate Sample

- `Storm-Kiln Artist`: `artifact_engine_overlap,treasure_engine`
- `Pitiless Plunderer`: `artifact_engine_overlap,treasure_engine`

## Blockers

- `trace_review_blocks_negative_clearance:Archaeomancer's Map`
- `no_exact_artifact_spell_engine_replacement_proof`
- `candidate_copy_closed_after_trace_replacement_review`

## Policy

- negative_trace_boundary: Rejected or considered tutor candidates do not clear a cut just because they were not cast.
- same_lane_boundary: Artifact/treasure adjacency is not exact Biotransference replacement proof without artifact-spell or type-conversion engine overlap.
- mutation_boundary: This reviewer reads report artifacts only and keeps candidate copy, battle, and promotion closed.
