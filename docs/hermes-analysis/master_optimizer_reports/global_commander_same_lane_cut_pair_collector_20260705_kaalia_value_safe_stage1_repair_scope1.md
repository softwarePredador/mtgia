# Global Commander Same-Lane Cut Pair Collector

- generated_at: `2026-07-05T23:46:08.685835+00:00`
- status: `same_lane_cut_pair_collection_blocks_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- selected_add_count: `8`
- required_pair_count: `8`
- ready_pair_count: `0`
- unpaired_add_count: `8`
- ready_cut_candidate_count: `0`
- stage_only_cut_candidate_count: `28`
- blocked_cut_candidate_count: `19`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes`

## Pair Counts By Role

| Role | Required | Ready | Source Target |
| --- | ---: | ---: | ---: |
| `mana_acceleration` | 1 | 0 | 1 |
| `haste_protection_silence` | 2 | 0 | 4 |
| `tutors_access` | 5 | 0 | 8 |

## Review-Only Same-Lane Pairs

| Step | Add | Cut | Role | Pair Score |
| ---: | --- | --- | --- | ---: |
| 0 | none | none | `-` | 0 |

## Unpaired Adds

- `Fellwar Stone` needs `mana_acceleration` cut evidence
- `Boros Charm` needs `haste_protection_silence` cut evidence
- `Gamble` needs `tutors_access` cut evidence
- `Swiftfoot Boots` needs `haste_protection_silence` cut evidence
- `Wishclaw Talisman` needs `tutors_access` cut evidence
- `Entomb` needs `tutors_access` cut evidence
- `Imperial Seal` needs `tutors_access` cut evidence
- `Diabolic Tutor` needs `tutors_access` cut evidence

## Stage-Only Cut Sample

- `Smothering Tithe` (mana_acceleration): `structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty` (mana_acceleration): `global_battle_feedback_requires_new_same_lane_or_gate`
- `Jeska's Will` (mana_acceleration): `structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Hammer of Nazahn` (haste_protection_silence): `target_role_is_protected_profile_lane_requires_trace_or_equal_gate`
- `Arcane Signet` (mana_acceleration): `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Dark Ritual` (mana_acceleration): `structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Demonic Tutor` (tutors_access): `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Diabolic Intent` (tutors_access): `contextual_staple_requires_stage_review`
- `Enlightened Tutor` (tutors_access): `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Grand Abolisher` (haste_protection_silence): `target_role_is_protected_profile_lane_requires_trace_or_equal_gate, commander_expected_package_anchor_requires_stage_proof, contextual_staple_requires_stage_review`
- `Lightning Greaves` (haste_protection_silence): `target_role_is_protected_profile_lane_requires_trace_or_equal_gate, commander_expected_package_anchor_requires_stage_proof`
- `Mana Vault` (mana_acceleration): `structural_foundation_staple_requires_same_lane_or_battle_proof`

## Blockers

- `candidate_copy_closed_until_same_lane_scope_reducer_runs`
- `same_lane_value_safe_pair_shortfall:required_8_ready_0`
- `no_review_only_value_safe_same_lane_pairs`
- `stage_only_same_lane_cuts_need_evidence:28`
- `strategy_matrix_and_replay_gate_not_run_for_same_lane_package`

## Policy

- same_lane_boundary: An add can pair only with a cut whose profile role matches the add's explicit replaces_cut_role.
- stage_only_boundary: Protected lanes, expected package anchors, structural staples, and non-target risk remain stage-only or blocked.
- scope_boundary: This collector only creates review-only pairs; a later scope reducer must choose any copied-DB scope.
- battle_boundary: No battle or promotion opens before copied candidate structure, strategy matrix, and replay evidence.
