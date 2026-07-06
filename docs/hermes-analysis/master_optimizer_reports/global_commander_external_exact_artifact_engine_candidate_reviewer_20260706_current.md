# Global Commander External Exact Artifact Engine Candidate Reviewer

- generated_at: `2026-07-06T04:49:26.195796+00:00`
- status: `external_exact_artifact_engine_candidate_review_blocks_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- external_candidate_count: `8`
- external_ready_input_count: `5`
- local_review_ready_count: `0`
- missing_local_oracle_count: `5`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `backfill_local_oracle_cache_for_external_exact_engine_seeds_before_add_cut_review`

## Reviewed Candidates

| Card | Status | Local Oracle | Local Status | Legality | Blockers |
| --- | --- | --- | --- | --- | --- |
| `Digsite Engineer` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | missing_local_oracle_cache |
| `Golem Foundry` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | missing_local_oracle_cache |
| `Myrsmith` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | missing_local_oracle_cache |
| `Poetic Ingenuity` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | missing_local_oracle_cache |
| `Ravenous Robots` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | missing_local_oracle_cache |
| `Biotransference` | `external_exact_engine_candidate_local_review_blocked` | `true` | `exact_type_conversion_engine_candidate` | `legal` | external_status_not_ready_for_local_review:exact_type_conversion_engine_candidate, already_in_current_deck |
| `Foundry Inspector` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement, missing_local_oracle_cache |
| `Voyager Quickwelder` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement, missing_local_oracle_cache |

## Blocker Counts

- `already_in_current_deck`: `1`
- `external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement`: `2`
- `external_status_not_ready_for_local_review:exact_type_conversion_engine_candidate`: `1`
- `missing_local_oracle_cache`: `7`

## Policy

- external_boundary: External source rows are learning seeds until local Oracle and legality agree.
- candidate_copy_boundary: Candidate copy remains closed until local review produces exact add/cut pairs.
- missing_local_oracle_boundary: Missing local Oracle rows require a cache backfill gate, not manual deck insertion.
