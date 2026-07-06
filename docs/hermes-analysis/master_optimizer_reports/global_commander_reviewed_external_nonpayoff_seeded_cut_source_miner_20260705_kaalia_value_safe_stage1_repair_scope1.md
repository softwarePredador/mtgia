# Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner

- generated_at: `2026-07-06T01:14:16.655351+00:00`
- status: `reviewed_external_seeded_cut_source_hypotheses_ready_for_trace`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- reviewed_seed_count: `5`
- seeded_role_count: `2`
- target_role_count: `3`
- unseeded_target_role_count: `1`
- scanned_seeded_same_lane_source_count: `34`
- fresh_seeded_same_lane_cut_source_count: `10`
- blocked_recycled_seeded_cut_source_count: `21`
- blocked_new_seeded_cut_source_count: `3`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_trace_for_reviewed_external_seeded_cut_source_hypotheses`

## Role Diagnostics

| Role | Seeds | Scanned | Fresh | Recycled | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| `haste_protection_silence` | 2 | 10 | 0 | 10 | `reviewed_external_seeded_role_exhausted_current_deck_sources` |
| `mana_acceleration` | 3 | 24 | 10 | 11 | `reviewed_external_seeded_role_has_fresh_cut_source_needs_trace` |
| `tutors_access` | 0 | 20 | 4 | 13 | `reviewed_external_seed_missing_for_target_role` |

## Miner Seeds

- `Dragon Tempest` -> `haste_protection_silence`
- `Dihada, Binder of Wills` -> `haste_protection_silence`
- `Sword of the Animist` -> `mana_acceleration`
- `Dihada, Binder of Wills` -> `mana_acceleration`
- `Simian Spirit Guide` -> `mana_acceleration`

## Fresh Seeded Same-Lane Cut Sources

- `Basalt Monolith` -> `mana_acceleration`
- `Monologue Tax` -> `mana_acceleration`
- `Burnt Offering` -> `mana_acceleration`
- `Culling the Weak` -> `mana_acceleration`
- `Desperate Ritual` -> `mana_acceleration`
- `Grim Monolith` -> `mana_acceleration`
- `Infernal Plunge` -> `mana_acceleration`
- `Pyretic Ritual` -> `mana_acceleration`
- `Cabal Ritual` -> `mana_acceleration`
- `Strike It Rich` -> `mana_acceleration`

## Blockers

- `reviewed_external_seeds_do_not_create_cut_permission`
- `candidate_copy_closed_until_seeded_fresh_cut_sources_have_trace`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`
- `unseeded_target_roles_remain_blocked:tutors_access`

## Policy

- seed_boundary: Reviewed external nonpayoff cards are miner seeds only; they are not add approval or cut permission.
- cut_source_boundary: A seeded role still needs a fresh same-lane current-deck cut source plus trace before candidate copy.
- recycling_boundary: Current-deck sources already used, seen, stage-only, blocked, or traced remain unavailable.
- battle_boundary: No battle gate opens before candidate copy and card-level usage evidence.
