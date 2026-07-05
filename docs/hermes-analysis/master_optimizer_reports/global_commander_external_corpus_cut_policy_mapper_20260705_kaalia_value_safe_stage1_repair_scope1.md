# Global Commander External Corpus Cut Policy Mapper

- generated_at: `2026-07-05T22:56:36.933360+00:00`
- status: `external_corpus_cut_policy_blocks_current_hypotheses`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- policy_row_count: `8`
- excluded_from_rerun_miner_count: `6`
- held_for_negative_review_count: `2`
- rerun_miner_allowed_card_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `rerun_value_safe_cut_source_miner_with_external_policy_exclusions`

## Cut Policy Rows

| Cut | Trace | Corpus Status | Cut Policy |
| --- | --- | --- | --- |
| `Biotransference` | `usage_blocked` | `external_absence_cannot_override_target_usage` | `exclude_from_rerun_miner_until_new_internal_evidence` |
| `Maskwood Nexus` | `usage_blocked` | `external_absence_cannot_override_target_usage` | `exclude_from_rerun_miner_until_new_internal_evidence` |
| `Necromancy` | `usage_blocked` | `external_corpus_supports_preserve_or_strict_same_lane_proof` | `protect_from_rerun_miner_until_same_lane_or_equal_gate` |
| `Necropotence` | `usage_blocked` | `external_corpus_supports_preserve_or_strict_same_lane_proof` | `protect_from_rerun_miner_until_same_lane_or_equal_gate` |
| `Puresteel Paladin` | `seen_without_usage` | `external_absence_plus_seen_without_usage_requires_negative_review` | `hold_for_negative_or_force_access_review_before_rerun_miner` |
| `Sigarda's Aid` | `usage_blocked` | `external_absence_cannot_override_target_usage` | `exclude_from_rerun_miner_until_new_internal_evidence` |
| `Sram, Senior Edificer` | `usage_blocked` | `external_absence_cannot_override_target_usage` | `exclude_from_rerun_miner_until_new_internal_evidence` |
| `Trouble in Pairs` | `seen_without_usage` | `external_presence_requires_negative_trace_before_cut` | `hold_for_negative_trace_review_before_rerun_miner` |

## Excluded From Rerun Miner

- `Biotransference`
- `Maskwood Nexus`
- `Necromancy`
- `Necropotence`
- `Sigarda's Aid`
- `Sram, Senior Edificer`

## Held For Negative Review

- `Puresteel Paladin`
- `Trouble in Pairs`

## Blockers

- `all_current_external_corpus_hypotheses_blocked_or_held`
- `candidate_copy_closed_until_fresh_value_safe_cut_pair_exists`
- `miner_must_consume_policy_exclusions_before_reusing_current_hypotheses`
