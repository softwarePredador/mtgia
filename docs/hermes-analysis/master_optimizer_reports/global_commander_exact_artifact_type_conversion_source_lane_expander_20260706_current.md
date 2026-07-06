# Global Commander Exact Artifact Type Conversion Source Lane Expander

- generated_at: `2026-07-06T05:04:06.911070+00:00`
- status: `exact_artifact_type_conversion_source_lane_exhausted_keep_biotransference_protected`
- deck_id: `619`
- source_query_count: `5`
- fetched_query_count: `5`
- type_conversion_candidate_count: `1`
- ready_type_conversion_candidate_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `protect_biotransference_and_pivot_to_non_biotransference_engine_cut_or_global_axis`

## Source Candidates

| Card | Status | Signals | Color | Blockers |
| --- | --- | --- | --- | --- |
| `Biotransference` | `exact_artifact_type_conversion_source_blocked` | `artifact_spell_token_payoff,artifact_type_conversion_engine` | `B` | already_in_current_deck |

## Policy

- type_conversion_boundary: Biotransference cannot be cut unless another legal outside-deck card covers artifact type conversion.
- candidate_copy_boundary: Source expansion never opens candidate copy directly.
- battle_boundary: No battle probe is useful while no add/cut pair can preserve exact same-lane signals.
