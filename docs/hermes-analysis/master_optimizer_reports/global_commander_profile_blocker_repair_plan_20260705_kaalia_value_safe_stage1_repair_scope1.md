# Global Commander Profile Blocker Repair Plan

- generated_at: `2026-07-05T21:07:11.566723+00:00`
- status: `profile_blocker_repair_plan_ready`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- source_strategy_status: `package_strategy_blocks_battle`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `1`
- repair_action_count: `1`
- next_gate: `materialize_profile_repair_candidate_copy`

## Repair Actions

| Blocker | Axis | Count | Target | Shortfall | Source Lanes |
| --- | --- | ---: | --- | ---: | --- |
| `profile_angels_demons_dragons_payoffs_below_target` | `angels_demons_dragons_payoffs` | 16 | `22-30` | 6 | `commander_reference_profile_expected_packages, oracle_type_identity_legal_filter, source_lane_payoff_density_review` |

## Repair Sequence

1. `repair_commander_payoff_density_with_legal_source_lanes`
2. `rerun_global_commander_candidate_package_strategy_matrix`

## Over-Target Review Roles

- `mana_acceleration` candidate `15` max `14` overage `1`
- `haste_protection_silence` candidate `16` max `12` overage `4`
- `tutors_access` candidate `16` max `8` overage `8`

## Policy

- repair_boundary: This plan names repair lanes only; it never mutates decks or opens promotion.
- battle_boundary: Any blocker keeps equal battle probes closed until the strategy matrix is rerun clean.
- cut_boundary: Above-target roles are candidate review pressure, not automatic cut authorization.
