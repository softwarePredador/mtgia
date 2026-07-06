# Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner

- generated_at: `2026-07-06T03:15:21.166998+00:00`
- status: `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- reviewed_seed_count: `7`
- seeded_role_count: `2`
- target_role_count: `3`
- unseeded_target_role_count: `1`
- scanned_seeded_same_lane_source_count: `31`
- fresh_seeded_same_lane_cut_source_count: `0`
- blocked_recycled_seeded_cut_source_count: `31`
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
| `haste_protection_silence` | 3 | 16 | 0 | 16 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |
| `mana_acceleration` | 4 | 15 | 0 | 15 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |
| `tutors_access` | 0 | 16 | 0 | 16 | `reviewed_external_seed_missing_for_target_role` |

## Miner Seeds

- `Unbreakable Formation` -> `haste_protection_silence`
- `Orim's Chant` -> `haste_protection_silence`
- `Sword of the Animist` -> `mana_acceleration`
- `Simian Spirit Guide` -> `mana_acceleration`
- `Dihada, Binder of Wills` -> `haste_protection_silence`
- `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` -> `mana_acceleration`
- `Collector's Vault` -> `mana_acceleration`

## Fresh Seeded Same-Lane Cut Sources

- none

## Blockers

- `reviewed_external_seeds_do_not_create_cut_permission`
- `candidate_copy_closed_until_seeded_fresh_cut_sources_have_trace`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`
- `reviewed_external_seeds_found_no_fresh_current_deck_cut_source`
- `unseeded_target_roles_remain_blocked:tutors_access`

## Policy

- seed_boundary: Reviewed external nonpayoff cards are miner seeds only; they are not add approval or cut permission.
- cut_source_boundary: A seeded role still needs a fresh same-lane current-deck cut source plus trace before candidate copy.
- recycling_boundary: Current-deck sources already used, seen, stage-only, blocked, or traced remain unavailable.
- battle_boundary: No battle gate opens before candidate copy and card-level usage evidence.
