# Global Commander Same-Lane New Cut Source Miner

- generated_at: `2026-07-06T00:14:43.032397+00:00`
- status: `same_lane_new_cut_source_mining_exhausted_current_deck`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- target_role_count: `3`
- exhausted_source_card_count: `42`
- scanned_same_lane_source_count: `47`
- fresh_same_lane_cut_source_count: `0`
- blocked_recycled_cut_source_count: `47`
- blocked_new_cut_source_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `broaden_same_lane_cut_research_or_package_axis_before_candidate_copy`

## Fresh Same-Lane Cut Sources

| Card | Role | Score | Next Evidence |
| --- | --- | ---: | --- |
| none | `-` | 0 | `broaden_same_lane_cut_research_or_package_axis_before_candidate_copy` |

## Blocked Recycled Cut Source Sample

| Card | Role | Categories |
| --- | --- | --- |
| `Smothering Tithe` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Hammer of Nazahn` | `haste_protection_silence` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Jeska's Will` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Ancient Copper Dragon` | `mana_acceleration` | `prior_blocked_cut_source` |
| `Cavern-Hoard Dragon` | `mana_acceleration` | `prior_blocked_cut_source` |
| `Goldlust Triad` | `mana_acceleration` | `prior_blocked_cut_source` |
| `Goldspan Dragon` | `mana_acceleration` | `prior_blocked_cut_source` |
| `Angel of the Ruins` | `tutors_access` | `prior_blocked_cut_source` |
| `Hoarding Broodlord` | `tutors_access` | `prior_blocked_cut_source` |
| `Razaketh, the Foulblooded` | `tutors_access` | `prior_blocked_cut_source` |
| `Rune-Scarred Demon` | `tutors_access` | `prior_blocked_cut_source` |
| `Starfield Shepherd` | `tutors_access` | `prior_blocked_cut_source` |
| `Arcane Signet` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Dark Ritual` | `mana_acceleration` | `external_reference_stage_cut_source, prior_stage_only_cut_source` |
| `Demonic Tutor` | `tutors_access` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Enlightened Tutor` | `tutors_access` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Lightning Greaves` | `haste_protection_silence` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Mana Vault` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |
| `Sol Ring` | `mana_acceleration` | `prior_stage_only_cut_source, used_cut_recovery_source, used_stage_cut_source` |

## Blocked New Cut Source Sample

- none

## Blockers

- `candidate_copy_closed_until_fresh_same_lane_cut_sources_have_trace`
- `used_or_seen_stage_cuts_cannot_be_recycled_as_fresh_sources`
- `no_fresh_same_lane_cut_source_found_in_current_deck`

## Policy

- freshness_boundary: A card already used, seen, stage-only, blocked, or traced in the current evidence chain is not fresh.
- same_lane_boundary: Only cards with a profile role matching the recovery target role are considered.
- hard_block_boundary: Commanders, lands, payoff slots, expected anchors, structural staples, and cross-role-risk sources are not fresh clean cuts.
- candidate_copy_boundary: This miner never opens candidate copy, battle, promotion, or value-safe reclassification.
