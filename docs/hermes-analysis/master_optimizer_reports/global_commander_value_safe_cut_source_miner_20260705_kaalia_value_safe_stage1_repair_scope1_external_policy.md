# Global Commander Value-Safe Cut Source Miner

- generated_at: `2026-07-05T23:00:07.665342+00:00`
- status: `value_safe_cut_source_mining_blocks_package_resynthesis`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `0`
- blocked_hypothesis_count: `88`
- external_policy_exclusion_count: `8`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `broaden_commander_package_axis_or_external_cut_research`

## Target Cut Roles

- `haste_protection_silence`: `4`
- `mana_acceleration`: `1`
- `tutors_access`: `8`

## Fresh Cut-Source Hypotheses

| Card | Score | Roles | Reasons | Next Gate |
| --- | ---: | --- | --- | --- |

## Blockers

- `hypotheses_require_trace_before_value_safe_reclassification`
- `candidate_copy_closed_until_value_safe_cut_pair_exists`
- `external_policy_exclusions_consumed:8`

## Blocked Hypothesis Sample

- `Alicia Masters, Skilled Sculptor`: `already_stage_only_cut_source_requires_proof, forced_access_used_cut_blocks_reclassification, attack_window_cut_requires_same_lane_stage_proof`
- `Ancient Copper Dragon`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Ancient Tomb`: `protected_profile_role_lands`
- `Angel of the Ruins`: `protected_profile_role_angels_demons_dragons_payoffs`
- `Anguished Unmaking`: `protected_profile_role_spot_interaction, contextual_staple_requires_stage_review`
- `Arcane Signet`: `already_stage_only_cut_source_requires_proof, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Ardenn, Intrepid Archaeologist`: `attack_window_cut_requires_same_lane_stage_proof`
- `Arena of Glory`: `protected_profile_role_haste_protection_silence,lands`
- `Arid Mesa`: `protected_profile_role_lands, structural_foundation_staple_requires_same_lane_or_battle_proof`
- `Aurelia, the Law Above`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Avacyn, Angel of Hope`: `protected_profile_role_angels_demons_dragons_payoffs,haste_protection_silence`
- `Balefire Dragon`: `protected_profile_role_angels_demons_dragons_payoffs`

## Policy

- miner_boundary: Fresh hypotheses are not value-safe cuts until trace or same-lane proof is collected.
- protected_role_boundary: Protected commander lanes, lands, structural staples, contextual staples, and stage-only cuts remain blocked.
- external_policy_boundary: When provided, external corpus policy exclusions block reusing current cards as fresh hypotheses.
- battle_boundary: This miner does not run battle or open promotion.
