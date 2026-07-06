# Global Commander External Exact Artifact Engine Candidate Reviewer

- generated_at: `2026-07-06T04:54:22.353977+00:00`
- status: `external_exact_artifact_engine_candidate_review_ready_for_add_cut_model`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- external_candidate_count: `8`
- external_ready_input_count: `5`
- local_review_ready_count: `5`
- missing_local_oracle_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `model_external_exact_artifact_engine_add_cut_pairs_before_candidate_copy`

## Reviewed Candidates

| Card | Status | Local Oracle | Local Status | Legality | Blockers |
| --- | --- | --- | --- | --- | --- |
| `Digsite Engineer` | `local_external_exact_engine_candidate_ready_for_add_cut_review` | `true` | `exact_artifact_spell_payoff_candidate` | `legal` | - |
| `Golem Foundry` | `local_external_exact_engine_candidate_ready_for_add_cut_review` | `true` | `exact_artifact_spell_payoff_candidate` | `legal` | - |
| `Myrsmith` | `local_external_exact_engine_candidate_ready_for_add_cut_review` | `true` | `exact_artifact_spell_payoff_candidate` | `legal` | - |
| `Poetic Ingenuity` | `local_external_exact_engine_candidate_ready_for_add_cut_review` | `true` | `exact_artifact_spell_payoff_candidate` | `legal` | - |
| `Ravenous Robots` | `local_external_exact_engine_candidate_ready_for_add_cut_review` | `true` | `exact_artifact_spell_payoff_candidate` | `legal` | - |
| `Biotransference` | `external_exact_engine_candidate_local_review_blocked` | `true` | `exact_type_conversion_engine_candidate` | `legal` | external_status_not_ready_for_local_review:exact_type_conversion_engine_candidate, already_in_current_deck |
| `Foundry Inspector` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement, missing_local_oracle_cache |
| `Voyager Quickwelder` | `external_exact_engine_candidate_local_review_blocked` | `false` | `missing_local_oracle_cache` | `legal` | external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement, missing_local_oracle_cache |

## Blocker Counts

- `already_in_current_deck`: `1`
- `external_status_not_ready_for_local_review:artifact_spell_support_not_biotransference_replacement`: `2`
- `external_status_not_ready_for_local_review:exact_type_conversion_engine_candidate`: `1`
- `missing_local_oracle_cache`: `2`

## Policy

- external_boundary: External source rows are learning seeds until local Oracle and legality agree.
- candidate_copy_boundary: Candidate copy remains closed until local review produces exact add/cut pairs.
- missing_local_oracle_boundary: Missing local Oracle rows require a cache backfill gate, not manual deck insertion.
