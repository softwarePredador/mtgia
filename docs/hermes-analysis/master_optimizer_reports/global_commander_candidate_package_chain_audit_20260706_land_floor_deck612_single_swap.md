# Global Commander Candidate Package Chain Audit

- generated_at: `2026-07-06T06:33:28.748363+00:00`
- status: `blocked`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- swap_count: `1`
- materializer_chain_pass: `true`
- core_floor_repaired: `false`
- strategy_ready: `true`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_commander_specific_strategy_matrix_for_package_before_battle`

## Package Swaps

| Step | Add | Cut | Source Clean |
| ---: | --- | --- | --- |
| 1 | `Ash Barrens` | `Longshot, Rebel Bowman` | `true` |

## Final Role Counts

- final_core_status: `core_role_gap`
- final_role_counts: `{"board_wipe": 11, "draw": 10, "engine": 46, "land": 28, "protection": 10, "ramp": 23, "recursion": 8, "removal": 9, "tutor": 2, "wincon": 17}`
- final_role_statuses: `{"board_wipe": "above_range_review", "draw": "in_range", "engine": "above_range_review", "land": "below_floor", "protection": "in_range", "ramp": "above_range_review", "recursion": "in_range", "removal": "in_range", "tutor": "in_range", "wincon": "above_range_review"}`

## Blockers

- `final_core_floor_not_repaired`
- `commander_specific_strategy_matrix_not_run_for_package`
- `package_battle_probe_not_run`

## Policy

- package_scope: This is an isolated copied-DB package candidate, not a real deck change.
- battle_boundary: Core floor repair and global readiness do not authorize battle until a commander-specific package strategy matrix exists.
- promotion_boundary: Promotion remains closed until strategy matrix, equal battle gate, and replay trace pass.
