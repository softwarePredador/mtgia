# Global Commander External Nonpayoff New Source Or Replacement Finder

- generated_at: `2026-07-06T02:04:41.219784+00:00`
- status: `new_external_source_candidates_ready_for_local_review`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- current_deck_negative_review_candidate_count: `6`
- current_deck_usage_blocked_count: `5`
- manual_negative_review_required_count: `1`
- explicit_same_lane_replacement_proof_count: `0`
- new_external_candidate_count: `22`
- new_external_ready_for_review_count: `19`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner`

## Ready New External Sources

| Card | Role | Status | Evidence Terms | Sources |
| --- | --- | --- | --- | --- |
| `Lavaspur Boots` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | haste, ward | draftsim_kaalia_deck_guide_2026_02_12 |
| `Flawless Maneuver` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | indestructible | draftsim_kaalia_deck_guide_2026_02_12 |
| `Loran's Escape` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | hexproof, indestructible | draftsim_kaalia_deck_guide_2026_02_12 |
| `Malakir Rebirth // Malakir Mire` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | return it to the battlefield | draftsim_kaalia_deck_guide_2026_02_12 |
| `Rebuff the Wicked` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | counter target spell that targets | draftsim_kaalia_deck_guide_2026_02_12 |
| `Clever Concealment` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | phase out | draftsim_kaalia_deck_guide_2026_02_12 |
| `Galadriel's Dismissal` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | phases out | draftsim_kaalia_deck_guide_2026_02_12 |
| `Redirect Lightning` | `haste_protection_silence` | `new_external_source_candidate_ready_for_local_miner_review` | change the target | edhrec_kaalia_hidden_gems_2026_03_26 |
| `Boros Signet` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Orzhov Signet` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Rakdos Signet` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Mind Stone` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add {, draw a card | draftsim_kaalia_deck_guide_2026_02_12 |
| `Talisman of Conviction` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Talisman of Hierarchy` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Talisman of Indulgence` | `mana_acceleration` | `new_external_source_candidate_ready_for_local_miner_review` | add { | draftsim_kaalia_deck_guide_2026_02_12 |
| `Grim Tutor` | `tutors_access` | `new_external_source_candidate_ready_for_local_miner_review` | search your library | edhrec_game_changer_alternatives_2026_07_06 |
| `Open the Armory` | `tutors_access` | `new_external_source_candidate_ready_for_local_miner_review` | search your library, reveal it, put it into your hand | draftsim_equipment_tutors_2025_11_06 |
| `Steelshaper's Gift` | `tutors_access` | `new_external_source_candidate_ready_for_local_miner_review` | search your library, put it into your hand | draftsim_equipment_tutors_2025_11_06 |
| `Stoneforge Mystic` | `tutors_access` | `new_external_source_candidate_ready_for_local_miner_review` | search your library, reveal it, put it into your hand | draftsim_equipment_tutors_2025_11_06 |

## Replacement Review

| Card | Role | Status | Usage | Decisions |
| --- | --- | --- | ---: | ---: |
| `Lightning Greaves` | `haste_protection_silence` | `current_deck_candidate_used_by_target_blocks_replacement_proof` | 8 | 11 |
| `Arcane Signet` | `mana_acceleration` | `current_deck_candidate_used_by_target_blocks_replacement_proof` | 3 | 5 |
| `Demonic Tutor` | `tutors_access` | `current_deck_candidate_used_by_target_blocks_replacement_proof` | 9 | 18 |
| `Diabolic Intent` | `tutors_access` | `current_deck_candidate_used_by_target_blocks_replacement_proof` | 5 | 1 |
| `Enlightened Tutor` | `tutors_access` | `current_deck_candidate_used_by_target_blocks_replacement_proof` | 2 | 14 |
| `Vampiric Tutor` | `tutors_access` | `current_deck_candidate_seen_without_usage_needs_manual_review` | 0 | 1 |

## Blockers

- `current_deck_usage_blocks_replacement_proof`
- `fresh_external_source_candidates_are_miner_seeds_not_cut_permission`
- `held_package_adds_still_need_value_safe_pairs`
- `partial_role_coverage_cannot_open_candidate_copy_or_battle`

## Policy

- replacement_boundary: A current-deck card used by the target is not cuttable without explicit same-lane replacement proof or equal-gate evidence.
- source_boundary: New external candidates can seed later mining/review only; they are not deck actions.
- land_boundary: Land candidates route to mana-base modeling, not nonland same-lane replacement.
- legality_boundary: Official/current Commander legality blocks banned or color-identity-invalid candidates before strategy review.
- mutation_boundary: This finder does not copy decks, mutate DBs, run battles, or promote a package.
