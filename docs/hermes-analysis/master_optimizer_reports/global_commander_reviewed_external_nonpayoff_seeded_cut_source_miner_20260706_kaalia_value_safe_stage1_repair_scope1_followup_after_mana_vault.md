# Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner

- generated_at: `2026-07-06T02:49:55.698955+00:00`
- status: `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- reviewed_seed_count: `34`
- seeded_role_count: `3`
- target_role_count: `3`
- unseeded_target_role_count: `0`
- scanned_seeded_same_lane_source_count: `47`
- fresh_seeded_same_lane_cut_source_count: `0`
- blocked_recycled_seeded_cut_source_count: `47`
- blocked_new_seeded_cut_source_count: `0`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy`

## Role Diagnostics

| Role | Seeds | Scanned | Fresh | Recycled | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| `haste_protection_silence` | 12 | 16 | 0 | 16 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |
| `mana_acceleration` | 10 | 15 | 0 | 15 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |
| `tutors_access` | 12 | 16 | 0 | 16 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |

## Miner Seeds

- `Darksteel Plate` -> `haste_protection_silence`
- `Brotherhood Regalia` -> `haste_protection_silence`
- `Dragon Tempest` -> `haste_protection_silence`
- `Reconnaissance` -> `haste_protection_silence`
- `Giver of Runes` -> `haste_protection_silence`
- `Akroma's Will` -> `haste_protection_silence`
- `Deflecting Swat` -> `haste_protection_silence`
- `Dawn's Truce` -> `haste_protection_silence`
- `Flare of Fortitude` -> `haste_protection_silence`
- `Sejiri Shelter // Sejiri Glacier` -> `haste_protection_silence`
- `Blacksmith's Skill` -> `haste_protection_silence`
- `Commander's Plate` -> `haste_protection_silence`
- `Commander's Sphere` -> `mana_acceleration`
- `Wayfarer's Bauble` -> `mana_acceleration`
- `Mardu Banner` -> `mana_acceleration`
- `Darksteel Ingot` -> `mana_acceleration`
- `Prismatic Lens` -> `mana_acceleration`
- `Marble Diamond` -> `mana_acceleration`
- `Charcoal Diamond` -> `mana_acceleration`
- `Fire Diamond` -> `mana_acceleration`
- `Worn Powerstone` -> `mana_acceleration`
- `Everflowing Chalice` -> `mana_acceleration`
- `Entomb` -> `tutors_access`
- `Diabolic Tutor` -> `tutors_access`
- `Final Parting` -> `tutors_access`
- `Buried Alive` -> `tutors_access`
- `Unmarked Grave` -> `tutors_access`
- `Profane Tutor` -> `tutors_access`
- `Beseech the Queen` -> `tutors_access`
- `Idyllic Tutor` -> `tutors_access`
- `Fighter Class` -> `tutors_access`
- `Oswald Fiddlebender` -> `tutors_access`
- `Magda, Brazen Outlaw` -> `tutors_access`
- `Weathered Wayfarer` -> `tutors_access`

## Fresh Seeded Same-Lane Cut Sources

- none

## Blockers

- `reviewed_external_seeds_do_not_create_cut_permission`
- `candidate_copy_closed_until_seeded_fresh_cut_sources_have_trace`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`
- `reviewed_external_seeds_found_no_fresh_current_deck_cut_source`

## Policy

- seed_boundary: Reviewed external nonpayoff cards are miner seeds only; they are not add approval or cut permission.
- cut_source_boundary: A seeded role still needs a fresh same-lane current-deck cut source plus trace before candidate copy.
- recycling_boundary: Current-deck sources already used, seen, stage-only, blocked, or traced remain unavailable.
- battle_boundary: No battle gate opens before candidate copy and card-level usage evidence.
