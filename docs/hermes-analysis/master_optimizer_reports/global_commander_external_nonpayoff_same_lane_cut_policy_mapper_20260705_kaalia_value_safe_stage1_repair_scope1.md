# Global Commander External Nonpayoff Same-Lane Cut Policy Mapper

- generated_at: `2026-07-06T00:34:42.055980+00:00`
- status: `external_nonpayoff_same_lane_policy_ready_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- role_policy_count: `3`
- source_discovery_required_role_count: `3`
- rerun_miner_allowed_role_count: `0`
- card_level_cut_permission_count: `0`
- card_level_cut_permission_now: `false`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `discover_external_nonpayoff_same_lane_source_candidates_before_miner`

## Role Policy Rows

| Role | Sources | Cut Policy | Next Evidence |
| --- | ---: | --- | --- |
| `haste_protection_silence` | 6 | `require_external_nonpayoff_source_discovery_before_miner` | `discover_external_nonpayoff_same_lane_source_candidates` |
| `mana_acceleration` | 6 | `require_external_nonpayoff_source_discovery_before_miner` | `discover_external_nonpayoff_same_lane_source_candidates` |
| `tutors_access` | 5 | `require_external_nonpayoff_source_discovery_before_miner` | `discover_external_nonpayoff_same_lane_source_candidates` |

## Source Discovery Required Roles

- `haste_protection_silence`
- `mana_acceleration`
- `tutors_access`

## Blockers

- `external_policy_is_role_level_not_card_cut_permission`
- `named_source_candidates_required_before_miner_rerun`
- `candidate_copy_closed_until_value_safe_same_lane_pair_exists`
- `battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist`

## Policy

- role_boundary: This mapper creates role-level source-discovery policy, not card-level cut permission.
- source_boundary: Named external source candidates must be collected and checked locally before any miner rerun.
- trace_boundary: Target-deck trace and same-lane value-safe pairing remain required before candidate copy.
- mutation_boundary: This mapper does not mutate DBs, copy decks, run battles, or promote anything.
