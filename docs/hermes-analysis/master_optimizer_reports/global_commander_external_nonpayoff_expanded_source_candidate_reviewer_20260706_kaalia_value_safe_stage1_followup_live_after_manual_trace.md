# Global Commander External Nonpayoff Expanded Source Candidate Reviewer

- generated_at: `2026-07-06T03:31:48.023774+00:00`
- status: `expanded_external_source_candidates_reviewed_seed_ready_no_deck_action`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- expander_ready_candidate_count: `0`
- reviewed_candidate_count: `13`
- miner_source_seed_allowed_count: `11`
- blocked_current_deck_count: `0`
- blocked_commander_banned_count: `0`
- blocked_recycled_prior_seed_count: `2`
- blocked_role_mismatch_count: `0`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_count: `0`
- battle_gate_allowed_count: `0`
- value_safe_reclassification_allowed_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources`

## Miner Source Seeds

| Role | Card | Scope | Evidence Terms | Cautions |
| --- | --- | --- | --- | --- |
| `haste_protection_silence` | `Dolmen Gate` | `protection_spell_or_haste_seed` | `prevent all combat damage, prevent all combat damage that would be dealt, attacking creatures you control` | `protection_seed_requires_target_role_cut_source_evidence_later, does_not_make_current_protection_card_cuttable` |
| `haste_protection_silence` | `Alseid of Life's Bounty` | `repeatable_creature_protection_seed` | `protection from, protection from the color` | `creature_protection_seed_requires_removal_pressure_context, does_not_make_current_protection_card_cuttable` |
| `haste_protection_silence` | `Benevolent Bodyguard` | `repeatable_creature_protection_seed` | `protection from, protection from the color` | `creature_protection_seed_requires_removal_pressure_context, does_not_make_current_protection_card_cuttable` |
| `haste_protection_silence` | `Gods Willing` | `protection_spell_or_haste_seed` | `protection from, protection from the color, can't be blocked` | `protection_seed_requires_target_role_cut_source_evidence_later, does_not_make_current_protection_card_cuttable` |
| `mana_acceleration` | `Black Market Connections` | `mana_rock_seed_curve_pressure_review` | `treasure, draw a card, create a treasure` | `mana_rock_seed_requires_curve_and_source_pressure_review, does_not_make_existing_ramp_cuttable` |
| `mana_acceleration` | `Curse of Opulence` | `mana_rock_seed_curve_pressure_review` | `add one mana, mana of any color, add one mana of any color` | `mana_rock_seed_requires_curve_and_source_pressure_review, does_not_make_existing_ramp_cuttable` |
| `mana_acceleration` | `Culling the Weak` | `mana_rock_seed_curve_pressure_review` | `add {, add {b}` | `mana_rock_seed_requires_curve_and_source_pressure_review, does_not_make_existing_ramp_cuttable` |
| `tutors_access` | `Insatiable Avarice` | `conditional_tutor_seed_context_required` | `search your library, search your library for a card` | `conditional_tutor_seed_requires_threshold_context, cannot_override_same_lane_cut_proof` |
| `tutors_access` | `Tainted Pact` | `conditional_tutor_seed_context_required` | `put that card into your hand` | `conditional_tutor_seed_requires_threshold_context, cannot_override_same_lane_cut_proof` |
| `tutors_access` | `Demonic Consultation` | `conditional_tutor_seed_context_required` | `put that card into your hand` | `conditional_tutor_seed_requires_threshold_context, cannot_override_same_lane_cut_proof` |
| `tutors_access` | `Moonsilver Key` | `conditional_tutor_seed_context_required` | `search your library, reveal it, put it into your hand` | `conditional_tutor_seed_requires_threshold_context, cannot_override_same_lane_cut_proof` |

## Review Rows

| Role | Card | In Deck | Legal | Miner Seed | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `haste_protection_silence` | `Deflecting Swat` | false | `legal` | false | `expanded_source_candidate_local_review_blocks_recycled_prior_seed` |
| `haste_protection_silence` | `Akroma's Will` | false | `legal` | false | `expanded_source_candidate_local_review_blocks_recycled_prior_seed` |
| `haste_protection_silence` | `Dolmen Gate` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `haste_protection_silence` | `Alseid of Life's Bounty` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `haste_protection_silence` | `Benevolent Bodyguard` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `haste_protection_silence` | `Gods Willing` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `mana_acceleration` | `Black Market Connections` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `mana_acceleration` | `Curse of Opulence` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `mana_acceleration` | `Culling the Weak` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `tutors_access` | `Insatiable Avarice` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `tutors_access` | `Tainted Pact` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `tutors_access` | `Demonic Consultation` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |
| `tutors_access` | `Moonsilver Key` | false | `legal` | true | `expanded_source_candidate_local_review_ready_for_seeded_miner` |

## Blockers

- `reviewed_expanded_external_candidates_are_miner_seeds_not_cut_permission`
- `current_deck_cards_remain_blocked_until_trace_or_negative_review`
- `banned_cards_are_discarded_before_strategy_review`
- `candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source`
- `value_safe_reclassification_closed_until_same_lane_or_equal_gate_proof_exists`

## Policy

- review_boundary: Only locally legal outside-deck expanded source candidates can seed the miner.
- seed_boundary: Reviewed expanded external nonpayoff candidates may seed miner research only; they are not add approvals.
- scope_boundary: Fast mana, high-power tutors, narrow tutors, protection, and mana rocks retain separate seed scopes and cautions.
- legality_boundary: Banned candidates stay blocked even if they appeared in historical high-power context.
- mutation_boundary: This reviewer does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.
